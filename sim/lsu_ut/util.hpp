#ifndef _UTIL_HPP_
#define _UTIL_HPP_
#include "params.hpp"
#include <stdio.h>
#include <iostream>
#include <fstream>
#include <stdlib.h>
#include <set>
#include <ctime> 
#include <list>



#define LOG_ENABLE
#define IO_ENABLE
#define RANDOM_PADDR_ENABLE
// #define DEBUG_OUTPUT

const uint32_t MEM_CHEKCPOINT = 100;

const std::string PROJ_ROOT = std::getenv("PROJ_ROOT");
const std::string LOG_PATH = PROJ_ROOT + "/sim/lsu_ut/logs/lsu_ut.log";

extern std::ofstream LOG;
extern uint64_t TIME;

const uint64_t BUS_BASE_DELAY = 10;
const uint64_t BUS_MAX_DELAY = 30;

const uint32_t TLB_HIT_BASE_DELAY = 1;
const uint32_t TLB_MISS_BASE_DELAY = 30;

const uint64_t CACHE_HIT_BASE_DELAY = 3;
const uint64_t CACHE_MISS_BASE_DELAY = 5;
const uint64_t CACHE_MISS_MAX_DELAY = 30;
const uint64_t MAX_CACHE_SIZE = 16;

const uint32_t RCU_MAX_SIZE = ROB_SIZE;
const uint32_t RCU_MAX_DELAY = 10;
const uint32_t RCU_BASE_DELAY = 1;

const uint64_t WAKEUP_BASE_DELAY = 1;
const uint64_t WAKEUP_MAX_DELAY = 5;

void init_log();
void close_log();
void sync_time(const uint64_t& t);
struct CacheLine{
    uint64_t paddr = 0;
    uint64_t data = 0;
    uint8_t rob_index = 0;
    uint8_t rd_addr = 0;
    uint16_t delay = 0;
    bool is_fenced = 0;
    bool load_or_store = 0;
    uint8_t opcode = 0;
    CacheLine(){}
    CacheLine(const uint64_t& pa, const uint64_t& d, const uint8_t& ri, 
        const uint8_t& rd, const uint16_t& de, const bool& fence, const bool& ls, const uint8_t& op): 
        paddr(pa), data(d), rob_index(ri), rd_addr(rd), delay(de), is_fenced(fence), load_or_store(ls), opcode(op){}
};

struct BusEntry{
    uint64_t paddr = 0;
    uint64_t data = 0;
    uint8_t rob_index = 0;
    uint8_t rd_addr = 0;
    bool is_fenced = 0;
    bool load_or_store = 0;
    uint8_t opcode = 0;
    uint16_t delay = 0;
    BusEntry(){}
    BusEntry(const uint64_t& pa, const uint64_t& d, const uint8_t& ri, 
        const uint8_t& rd, const uint16_t& de, const bool& fence, const bool& ls, const uint8_t& op): 
        paddr(pa), data(d), rob_index(ri), rd_addr(rd), delay(de), is_fenced(fence), load_or_store(ls), opcode(op){}
};

struct RCUEntry{
    bool issued = 0;
    bool done = 0;
    bool awake = 0;
    uint64_t paddr = 0;
    uint64_t data = 0;
    uint8_t rob_index = 0;
    uint8_t rd_addr = 0;
    bool is_fenced = 0;
    bool load_or_store = 0;
    uint8_t opcode = 0;
    uint16_t delay = 0;
    RCUEntry(){}
    RCUEntry(const uint64_t& pa, const uint64_t& d, const uint8_t& ri, 
        const uint8_t& rd, const uint16_t& de, const bool& fence, const bool& ls, const uint8_t& op): 
        paddr(pa), data(d), rob_index(ri), rd_addr(rd), delay(de), is_fenced(fence), load_or_store(ls), opcode(op){}
};

#endif // _UTIL_HPP_
