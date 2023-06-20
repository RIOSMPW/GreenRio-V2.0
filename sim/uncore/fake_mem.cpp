#ifndef _FAKE_MEM_CPP_
#define _FAKE_MEM_CPP_
#include "./fake_mem.hpp"

uint8_t FakeMemory::get_byte(const uint16_t&  paddr){
    return uint8_t((_mem[paddr >> 3] >> (paddr % 8 * 8)) & 0xff);
}
void FakeMemory::set_byte(const uint16_t&  paddr, const uint8_t& data){
    // uint64_t mask = ~(uint64_t(0xff) << ((paddr % 8) * 8));
    // uint64_t data_mask = mask | (uint64_t(data) << ((paddr % 8) * 8));
    _mem[paddr >> 3] &= ~(uint64_t(0xff) << ((paddr % 8) * 8));
    _mem[paddr >> 3] |= (uint64_t(data) << ((paddr % 8) * 8));
}

uint64_t FakeMemory::lb(const uint16_t& paddr){
    uint64_t anws = uint64_t(get_byte(paddr));
    _visit_time ++;
    if(anws & (0x1 << 7)) anws |= 0xffffffffffffff00;
    return anws;
}
uint64_t FakeMemory::lh(const uint16_t& paddr){
    if(paddr % 2 != 0) throw "lh misalign";
    _visit_time ++;
    uint64_t anws = 0;
    for(int i = 0; i < 2; i ++){
        anws += uint64_t(get_byte(paddr + (1 - i)));
        if(i < 1) anws <<= 8;
    }
    if(anws & (0x1 << 15)) anws |= 0xffffffffffff0000;
    return anws;
}
uint64_t FakeMemory::lw(const uint16_t& paddr){
    if(paddr % 4 != 0) throw "lw misalign";
    _visit_time ++;
    uint64_t anws = 0;
    for(int i = 0; i < 4; i ++){
        anws += uint64_t(get_byte(paddr + (3 - i)));
        if(i < 3) anws <<= 8;
    }
    if(anws & (0x1 << 31)) anws |= 0xffffffff00000000;

    return anws;
}
uint64_t FakeMemory::ld(const uint16_t& paddr){
    if(paddr % 8 != 0) throw "ld misalign";
    _visit_time ++;
    return _mem[paddr >> 3];
}
uint64_t FakeMemory::lbu(const uint16_t& paddr){
    _visit_time ++;
    return uint64_t(get_byte(paddr));
}
uint64_t FakeMemory::lhu(const uint16_t& paddr){
    if(paddr % 2 != 0) throw "lhu misalign";
    _visit_time ++;
    uint64_t anws = 0;
    for(int i = 0; i < 2; i ++){
        anws += uint64_t(get_byte(paddr + ( 1 - i)));
        if(i < 1) anws <<= 8;
    }
    return anws;
}
uint64_t FakeMemory::lwu(const uint16_t& paddr){
    if(paddr % 4 != 0) throw "lwu misalign";
    _visit_time ++;
    uint64_t anws = 0;
    for(int i = 0; i < 4; i ++){
        anws += uint64_t(get_byte(paddr + ( 3 - i)));
        if(i < 3) anws <<= 8;
    }
    return anws;
}

void FakeMemory::sb(const uint16_t& paddr, const uint64_t& data){
    _visit_time ++;
    set_byte(paddr, uint8_t(data));
}
void FakeMemory::sh(const uint16_t& paddr, const uint64_t& data){
    if(paddr % 2 != 0) throw "sh misalign";
    _visit_time ++;
    for(int i = 0; i < 2; i ++){
        set_byte(paddr + i, uint8_t((data >> (i * 8)) & 0xff));
    }
}
void FakeMemory::sw(const uint16_t& paddr, const uint64_t& data){
    if(paddr % 4 != 0) throw "sw misalign";
    _visit_time ++;
    for(int i = 0; i < 4; i ++){
        set_byte(paddr + i, uint8_t((data >> (i * 8)) & 0xff));
    }
    // if(paddr & 0x4 == 0){
    //     _mem[paddr >> 3] = (_mem[paddr >> 3] & 0xffffffff00000000) + (data & 0x00000000ffffffff);
    // } 
    // else{
    //     _mem[paddr >> 3] = (data & 0xffffffff00000000) + (_mem[paddr >> 3] & 0x00000000ffffffff);
    // }
    
#ifdef LOG_ENABLE
    LOG << "\tt " << std::dec << TIME << ":sw\t\t"
        << " @ 0x"  << std::hex << paddr 
        << " data: "<< std::hex << data
        << std::endl;
#endif // LOG_ENABLE
}
void FakeMemory::sd(const uint16_t& paddr, const uint64_t& data){
    if(paddr % 8 != 0) throw "sd misalign";
    _visit_time ++;
    for(int i = 0; i < 8; i ++){
        set_byte(paddr + i, uint8_t((data >> (i * 8)) & 0xff));
    } 
    // _mem[paddr >> 3] = data;
// #ifdef LOG_ENABLE
//     LOG << "\tt " << std::dec << TIME << ":sd\t\t"
//         << " @ 0x"  << std::hex << paddr 
//         << " data: "<< std::hex << data
//         << std::endl;
// #endif // LOG_ENABLE
}

uint64_t FakeMemory::check(const uint16_t& index){
    return _mem[index];
}

uint64_t FakeMemory::visit_time() const{
    return _visit_time;
}
#endif // _FAKE_MEM_CPP_