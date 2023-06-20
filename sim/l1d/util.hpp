#ifndef __UNCORE_UTIL_HPP__
#define __UNCORE_UTIL_HPP__
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
const std::string LOG_PATH = PROJ_ROOT + "/dv/l1d/logs/l1d.log";
const std::string WAVE_PATH = PROJ_ROOT + "/dv/l1d/waves/l1d.vcd";
const std::string PAGETABLE_PATH = PROJ_ROOT + "/dv/l1d/pagetable";

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


const uint32_t CACHE_LINE_SIZE = 512;
const uint32_t BURST_NUM = 8;
const uint32_t BURST_SIZE = CACHE_LINE_SIZE / BURST_NUM;
const uint32_t MEM_BASE_DELAY = 3;
const uint32_t MEM_MAX_DELAY = 50;

const uint64_t PAGETABLE_PADDR_BASE = 0x10000000;
const uint64_t PAGETABLE_PADDR_UPPER = 0x10010000;
const uint64_t DATA_PADDR_BASE = 0x80000000;
const uint64_t DATA_PADDR_UPPER = 0x80010000;

class Req{
public: 
    uint64_t paddr = 0;
    uint64_t data = 0;
    uint8_t rob_index = 0;
    uint8_t rd_addr = 0;
    uint16_t delay = 0;
    bool is_fenced = 0;
    bool load_or_store = 0;
    uint8_t opcode = 0;
    bool awake = 0;
    bool issued = 0;
    bool done = 0;
    Req(){}
    Req(const uint64_t& pa, const uint64_t& d, const uint8_t& ri, 
        const uint8_t& rd, const uint16_t& de, const bool& fence, const bool& ls, const uint8_t& op): 
        paddr(pa), data(d), rob_index(ri), rd_addr(rd), delay(de), is_fenced(fence), load_or_store(ls), opcode(op){}
    Req(const bool& io_enable, const bool& fence_enable, const bool& amo_enable){}
};


#pragma pack(1)
struct axi_aw_req{
    uint32_t awid = 0;
    uint64_t awaddr = 0;
    uint8_t awlen = 0;
};
struct axi_w_req{
    uint64_t wdata = 0;
    bool wlast = 0;
    uint32_t wid = 0;
};
struct axi_ar_req{
    uint32_t arid = 0;
    uint64_t araddr = 0;
};
struct axi_r_resp{
    uint32_t rid = 0;
    bool rlast = 0;
    uint64_t rdata = 0;
};

struct axi_b_resp{
    uint32_t bid = 0;
};

struct mem_req{
    bool aw_vld = 0;
    axi_aw_req aw;
    uint32_t w_vld_num = 0;
    axi_w_req w[BURST_NUM];
    bool ar_vld = 0;
    axi_ar_req ar;
    uint32_t delay = 0;
};
struct mem_resp{
    bool b_vld = 0;
    axi_b_resp b;
    bool r_vld = 0;
    axi_r_resp r;
};
#pragma pack()

#endif // __UNCORE_UTIL_HPP__
