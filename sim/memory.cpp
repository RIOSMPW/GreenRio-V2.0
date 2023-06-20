
#include <algorithm>
#include <iostream>
#include <gelf.h>
#include <fcntl.h>
#include <libelf.h>
#include <cstdlib>
#include "memory.hpp"


inline int generate_latency(){
    return ((std::rand()%1) + 0);
}

inline uint64_t concat32(uint32_t a, uint32_t b){
    uint64_t temp = a;
    temp <<= 32;
    temp |= b;
    return temp;
}

void MagicMemory::D_Request(Vhehe* core) {  // Vhehe pointer!
    static bool finish = false;  //after the request
    core->m2_wbd_ack_i = 0;
    if(d_wait){
        core->m2_wbd_ack_i = 0; //ack_i only be reised in one cycle
        d_wait--;
    }
    else if (core->m2_wbd_cyc_o) {  
        if(!finish){
            finish = true;
            uint32_t address = core->m2_wbd_adr_o;
            if(!core->m2_wbd_we_o){  //read from memory
                for (auto& handler : mapping) {
                    if (address >= handler.start && address < handler.start + handler.length) {
                        core->m2_wbd_dat_i = handler.handle_read(address - handler.start);
                        d_wait = generate_latency();  //这个完成后才能ack
                        break;
                    }
                }
            }
            else {
                for (auto& handler : mapping) {
                    if (address >= handler.start && address < handler.start + handler.length) {
                        handler.handle_write(address - handler.start, core->m2_wbd_dat_o, core->m2_wbd_sel_o);
                        d_wait = generate_latency();  //这个完成后才能ack
                        break;
                    }
                }
            }
        }
        else{  // finish = true
            core->m2_wbd_ack_i = 1;
            finish = false;
        }
    }
    else {
        core->m2_wbd_ack_i = 0;
    }
}

void MagicMemory::I_Request(Vhehe* core) { 
    static bool finish = false;  //after the request
    core->m3_wbd_ack_i = 0;
    if(i_wait){
        core->m3_wbd_ack_i = 0; //ack_i only be reised in one cycle
        i_wait--;
    }
    else if (core->m3_wbd_cyc_o) {  
        if(!finish){
            finish = true;
            uint32_t address = core->m3_wbd_adr_o;
            if(!core->m3_wbd_we_o){  //read from memory
                for (auto& handler : mapping) {
                    if (address >= handler.start && address < handler.start + handler.length) {
                        core->m3_wbd_dat_i = handler.handle_read(address - handler.start);
                        i_wait = generate_latency();  //这个完成后才能ack
                        break;
                    }
                }
            }
            else {
                std::cout<<"error: write to text section\n";
            }
        }
        else{  // finish = true
            core->m3_wbd_ack_i = 1;
            finish = false;
        }
    }
}

void MagicMemory::addHandler(MagicMappedHandler& handler) {
    mapping.push_back(handler);
}

uint32_t* MagicMemory::addRamHandler(uint32_t start, uint32_t length) {   // byte length
    uint32_t* data = (uint32_t*)(new uint8_t[length]);
    MagicMappedHandler handler = {
        .start = start,
        .length = length,
        .handle_read = [=](uint32_t address) {
            return data[address / 4];
        },
        .handle_write = [=](uint32_t address, uint32_t write_data, uint8_t strobe) {   // the defination of handle_write ??? strange grammer
            uint32_t new_data = data[address / 4];
            for (int i = 0; i < 4; i++) {
                if (strobe & (1 << i)) {   
                    new_data &= ~(0xff << (8 * i));  //set i byte of new_data to 0x00
                    new_data |= (0xff << (8 * i)) & write_data;  //intercept the i byte of write_data and pass onto new_data
                }
            }
            data[address / 4] = new_data;
        }
    };
    addHandler(handler);
    return data;
}

bool loadFromElfFile(const char* filename, uint32_t* data, uint32_t start, uint32_t length) {
    int fd = open(filename, O_RDONLY, 0);
    if (fd == -1) {
        std::cerr << "Failed to open the file '" << filename << "'" << std::endl;
        return false;
    }
    if (elf_version(EV_CURRENT) == EV_NONE) {
        std::cerr << "ELF library initialization failed" << std::endl;
        return false;
    }
    Elf* elf = elf_begin(fd, ELF_C_READ, NULL);
    if (elf == NULL) {
        std::cerr << "Failed to open ELF file '" << filename << "'" << std::endl;
        return false;
    } else if (elf_kind(elf) != ELF_K_ELF) {
        std::cerr << "The file must be an ELF object" << std::endl;
        return false;
    }
    GElf_Ehdr header;
    if (gelf_getehdr(elf, &header) != &header) {
        std::cerr << "Failed to read ELF header" << std::endl;
        return false;
    } else if (gelf_getclass(elf) != ELFCLASS64 || header.e_machine != EM_RISCV) {
        std::cerr << "ELF object architecture must be 32-bit riscv" << std::endl;
        return false;
    } else if (header.e_type != ET_EXEC) {
        std::cerr << "ELF object should be an executable" << std::endl;
        return false;
    }
    size_t program_count;
    if (elf_getphdrnum(elf, &program_count) != 0) {
        std::cerr << "Failed to get ELF program header count" << std::endl;
        return false;
    }
    for (size_t i = 0; i < program_count; i++) {
        GElf_Phdr program_header;
        if (gelf_getphdr(elf, i, &program_header) != &program_header) {
            std::cerr << "Failed to get ELF program header " << i << std::endl;
            return false;
        }
        if (program_header.p_type == PT_LOAD) {
            Elf_Data* elf_data = elf_getdata_rawchunk(elf, program_header.p_offset, program_header.p_filesz, ELF_T_WORD);
            if (program_header.p_paddr < (start + length) && (program_header.p_paddr + program_header.p_filesz) > start) {
                size_t copy_start = std::max<size_t>(program_header.p_paddr, start);
                size_t copy_end = std::min<size_t>(program_header.p_paddr + program_header.p_filesz, start + length);
                uint32_t* raw_data = (uint32_t*)elf_data->d_buf;
                for (size_t i = copy_start; i < copy_end; i += 4) {
                    data[(i - start) / 4] |= raw_data[(i - program_header.p_paddr) / 4];
                }
            }
        }
    }
    elf_end(elf);
    close(fd);
    return true;
}

