#ifndef PERFECT_MEM_CPP
#define PERFECT_MEM_CPP
#include "perfect_mem.hpp"

bool PerfectMem::ready(){
    return !_lock;
}
void PerfectMem::read(const uint16_t& addr, const uint32_t& lsq_id){
    // printf("read addr: 0x%x, \n", addr);
    assert(addr % 8 == 0);
    _addr = addr;
    _delay = DELAY;
    _lsq_index = lsq_id;
    _lock = 1;
}

void PerfectMem::read32(const uint16_t& addr){
    assert(addr % 4 == 0);
    _addr = addr;
    _delay = DELAY;
    _lsq_index = lsq_id;
    _lock = 1;
}

void PerfectMem::write(const uint16_t& addr, const uint64_t& data){
    // printf("write addr: 0x%x, \n", addr);
    assert(addr % 8 == 0);
    _mem[(addr >> 2) + 1] = uint32_t(data >> 32);
    _mem[(addr >> 2)] = uint32_t(data);
}

uint64_t PerfectMem::resp(){
    return (uint64_t(_mem[(_addr >> 2) + 1]) << 32) + 
                            uint64_t(_mem[(_addr >> 2)]);
}
uint32_t PerfectMem::resp_lsq_index(){
    return _lsq_index;
}
uint32_t PerfectMem::resp32(){
    if(_delay == 0) return _mem[_addr>>2];
    else return 0;
}
bool PerfectMem::resp_valid(){
    return _resp_valid;
}
void PerfectMem::eval(){
    // if(_resp_valid) _resp_valid = 0;
    
    if(_resp_valid & _lock){
        _lock = 0;
        _resp_valid = 0;
    }
    if(_delay == 0 && _lock){
        _resp_valid = 1;
    }
    if(_delay > 0) _delay --;
}

uint64_t PerfectMem::peek64(const uint16_t& addr){
    assert(addr % 8 == 0);
    // return 0;
    return (uint64_t(_mem[(addr >> 2) + 1]) << 32) + uint64_t(_mem[(addr >> 2)]);
}
uint32_t PerfectMem::peek32(const uint16_t& addr){
    assert(addr % 4 == 0);
    return uint32_t(_mem[addr >> 2]);
}
uint16_t PerfectMem::peek16(const uint16_t& addr){
    assert(addr % 2 == 0);
    if(addr % 2 == 0){
        return uint16_t(_mem[addr >> 2]);
    }
    else{
        return uint16_t(_mem[addr >> 2] >> 16);
    }
}
uint8_t PerfectMem::peek8(const uint16_t& addr){
    return uint8_t(_mem[addr >> 2] >> (8 * (addr % 4)));
}

#endif //PERFECT_MEM_HPP