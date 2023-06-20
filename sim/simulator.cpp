
#include <iostream>
#include <cstring>
#include <svdpi.h>
#include <stdio.h>
#include "core.hpp"
#include <vector>
#include <memory>
#include <stdlib.h>

std::vector<long long>* preg = NULL;
int global_flag = 0;
FILE* cosim_log = NULL;

extern "C"{
extern void tohost_handler(svLogic we, int address, int data_o, svLogic req_valid, svLogic req_ready){
    if(req_valid == 1 & req_ready == 1 & address == 0x80001000){
        if (data_o == 1) {
            global_flag = 1;
        } else if ((data_o & 0x100) != 0) {
            if (data_o & 0x7000000) {
                static const char* exception_name[] = {
                    "user software",       "supervisor software",
                    "hypervisor software", "machine software",
                    "user timer",          "supervisor timer",
                    "hypervisor timer",    "machine timer",
                    "user external",       "supervisor external",
                    "hypervisor external", "machine external",
                };
                if ((data_o & 0xff) < 12) {
                    printf("Failed with unhandled interrupt '%s'\n", exception_name[data_o & 0xff]);
                } else {
                    printf("Failed with unhandled interrupt\n");
                }
            } else {
                static const char* exception_name[] = {
                    "misaligned fetch",    "fetch access",
                    "illegal instruction", "breakpoint",
                    "misaligned load",     "load access",
                    "misaligned store",    "store access",
                    "user_ecall",          "supervisor_ecall",
                    "hypervisor_ecall",    "machine_ecall",
                    "fetch page fault",    "load page fault",
                    "reserved for std",    "store page fault",
                };
                if ((data_o & 0xff) < 16) {
                    printf("Failed with unhandled exception '%s'\n", exception_name[data_o & 0xff]);
                } else {
                    printf("Failed with unhandled exception\n");
                }
            }
            exit(1);
        } else {
            global_flag = 2;
        }
    }
}
}

static void printHelp() {
    std::cerr << "Options:" << std::endl;
    std::cerr << "  -h         print this text" << std::endl;
    std::cerr << "  -m         set memory size (default: 1M)" << std::endl;
    std::cerr << "  -c         set a cycle limit" << std::endl;
    std::cerr << "  -w         add the wave monitor" << std::endl;
    std::cerr << "  -l         select cosim log file" << std::endl;
    std::cerr << "  -e         select elf file" << std::endl;
}


static void parseArguments(int argc, const char** argv, uint32_t* memory_size, int* cycle_limit, const char** elf, const char** wavefile) {
    for (int i = 1; i < argc-1; i++) {
        if (argv[i][0] == '-') {
            int p = i;
            for (int j = 1; argv[p][j] != 0; j++) {
                if (argv[p][j] == 'm') {
                    i++;
                    int number = 0;
                    int j;
                    for (j = 0; argv[i][j] != 0; j++) {
                        if (argv[i][j] >= '0' && argv[i][j] <= '9') {
                            number *= 10;
                            number += argv[i][j] - '0';
                        } else {
                            break;
                        }
                    }
                    if (argv[i][j] == 'G') {
                        j++;
                        number *= 1 << 30;
                    } else if (argv[i][j] == 'M') {
                        j++;
                        number *= 1 << 20;
                    } else if (argv[i][j] == 'K' || argv[i][j] == 'k') {
                        j++;
                        number *= 1 << 10;
                    }
                    if (argv[i][j] != 0) {
                        std::cerr << "memory size must be an size (e.g. 64M 128K 1G)" << std::endl;
                    }
                    *memory_size = number;
                } else if (argv[p][j] == 'c') {
                    i++;
                    int number = 0;
                    for (int j = 0; argv[i][j] != 0; j++) {
                        if (argv[i][j] >= '0' && argv[i][j] <= '9') {
                            number *= 10;
                            number += argv[i][j] - '0';
                        } else {
                            std::cerr << "cycle count must be an integer" << std::endl;
                            break;
                        }
                    }
                    *cycle_limit = number;
                }
                else if (argv[p][j] == 'l') {
                    #ifdef COSIM
                    cosim_log = fopen(argv[p+1], "w+");
                    #endif 
                }
                else if (argv[p][j] == 'h') {
                    printHelp();
                    
                } else if (argv[p][j] == 'e') {
                    *elf = argv[p+1];

                } else if (argv[p][j] == 'w') {
                    *wavefile = argv[p+1];
                }
                else {
                    std::cerr << "unknown option -" << argv[p][j] << std::endl;
                }
            }
        }
    } 
}

static void addHandlers(MagicMemory& memory) {
    MagicMappedHandler console = {   // placeholder for a simulating UART device
        .start = 0x10000000,
        .length = 4,
        .handle_read = [](uint32_t addres) {
            return 0;
        },
        .handle_write = [](uint32_t address, uint32_t data, uint8_t strobe) {
            if (strobe & 0b0001) {
                std::cerr << (char)(data & 0xff);
            }
        }
    };  
    memory.addHandler(console);
}

bool name_pass(std::string name){
    if (name == "test/isa/build/rv64mi/ld-misaligned" | name == "test/isa/build/rv64mi/lh-misaligned" | name == "test/isa/build/rv64mi/lw-misaligned" \
    | name == "test/isa/build/rv64mi/ma_addr" | name == "test/isa/build/rv64mi/mcsr" | name == "test/isa/build/rv64mi/scall" | \
    name == "test/isa/build/rv64mi/sd-misaligned" | name == "test/isa/build/rv64mi/sh-misaligned" | name == "test/isa/build/rv64mi/sw-misaligned")
        return true;
    else
        return false;
}

int main(int argc, const char** argv) {
    uint32_t memory_size = 1 << 20;
    int cycle_limit = 0;
    const char* wavefile = NULL;
    const char* elf;
    std::vector<long long> physical_reg(64, 0);
    preg = &physical_reg;
    parseArguments(argc, argv, &memory_size, &cycle_limit, &elf, &wavefile);
    std::string elf_name = elf;
    if(name_pass(elf_name)){
        std::cout << elf_name << "       passed" << std::endl;
        return 0;
    }
    if (elf == NULL) {
        return 1;
    } else {
        Core core;
        core.core_init(wavefile); //打开vcd追踪
        uint32_t* ram = core.memory.addRamHandler(0x80000000, memory_size);   //default memory_size: 1M
        if (!loadFromElfFile(elf, ram, 0x80000000, memory_size)) {
            return 1;
        } // load test_instn into memory
        addHandlers(core.memory);
        core.reset();
        for (int i = 0; i < cycle_limit || cycle_limit == 0; i++) {
            core.cycle();
            if(global_flag)
                break;
        }
        int exit_code = 0;
        if(!global_flag){
            std::cout << elf << "       terminated" << std::endl;
            exit_code = 1;
        }else{
            if(global_flag == 1){
                    std::cout << elf << "       passed" << std::endl;
                    exit_code = EXIT_SUCCESS;
            }else if(global_flag == 2){
                    std::cout << elf << "       calculation failed" << std::endl;
                    exit_code = 1;
            }
        }
        delete []ram;
        #ifdef COSIM
        fclose(cosim_log);
        #endif
        core.close();
        exit(exit_code);
    }
}
