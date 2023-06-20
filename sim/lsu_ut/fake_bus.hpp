#ifndef _FAKE_BUS_HPP_
#define _FAKE_BUS_HPP_
#include <stdio.h>
#include <iostream>
#include <exception>
#include <stdlib.h>
#include <set>
#include <list>
#include "./fake_mem.hpp"
#include "./params.hpp"
#include "./util.hpp"

class FakeBus{
private:
    bool _req_vld = 0;
    BusEntry _req;

    bool _bus_entry_vld = 0;
    BusEntry _bus_entry;

    FakeMemory* _real_mem = nullptr;


    bool _resp_vld = 0;


    bool _bus_req_vld = 0;
    bool _bus_req_is_fenced = 0;
    uint16_t _bus_req_rob_index = 0;
public: 
    FakeBus(FakeMemory* real_mem){
        _real_mem = real_mem;
    }
    void req_vld(const bool& vld);
    void req(const uint64_t& pa, const uint64_t& d, const uint8_t& ri, 
        const uint8_t& rd, const uint16_t& de, const bool& fence, const bool& ls, const uint8_t& sel);
    bool resp_vld();
    BusEntry resp();
    
    void eval();
};

#endif // _FAKE_BUS_HPP_
