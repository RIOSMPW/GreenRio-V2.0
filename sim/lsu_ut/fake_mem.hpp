#ifndef _FAKE_MEM_HPP_
#define _FAKE_MEM_HPP_
#include <stdio.h>
#include <iostream>
#include <stdlib.h>
#include <set>
#include <list>
#include "util.hpp"
const uint32_t MEM_MAX_SIZE = 1 << (16 - 3);

class FakeMemory{
private:
    uint64_t* _mem = nullptr;
    uint64_t _visit_time = 0;
public:
    FakeMemory(){
        _mem = new uint64_t[MEM_MAX_SIZE];
        uint64_t d = 1;
        for(uint64_t i = 0; i < MEM_MAX_SIZE; i ++) _mem[i] = (((i << 3) + 4) << 32) +  (i << 3);
    }
    ~FakeMemory(){
        delete _mem;
    }
    uint8_t get_byte(const uint16_t&  paddr);
    void set_byte(const uint16_t&  paddr, const uint8_t& data);

    uint64_t lb(const uint16_t& paddr);
    uint64_t lh(const uint16_t& paddr);
    uint64_t lw(const uint16_t& paddr);
    uint64_t ld(const uint16_t& paddr);
    uint64_t lbu(const uint16_t& paddr);
    uint64_t lhu(const uint16_t& paddr);
    uint64_t lwu(const uint16_t& paddr);

    void sb(const uint16_t& paddr, const uint64_t& data);
    void sh(const uint16_t& paddr, const uint64_t& data);
    void sw(const uint16_t& paddr, const uint64_t& data);
    void sd(const uint16_t& paddr, const uint64_t& data);

    uint64_t check(const uint16_t& index);
    uint64_t visit_time() const;
};

#endif // _FAKE_MEM_HPP_
