#ifndef _FAKE_TLB_HPP_
#define _FAKE_TLB_HPP_
#include <stdio.h>
#include <iostream>
#include <stdlib.h>
#include <set>
#include <list>

#include "./params.hpp"
#include "util.hpp"

struct DelaySlot{
    uint64_t ptag;
    uint32_t delay;
    DelaySlot(const uint64_t& pt, const uint64_t& d): ptag(pt), delay(d){}
};


class FakeTLB{
private:
    std::set<uint64_t>* _tlb_hit_set;
    std::list<DelaySlot>* _delay_list;
    bool _resp_q = 0;
    bool _resp = 0;
    bool _valid_q = 0;
    bool _valid = 0;
    uint64_t _pt_q;
    uint64_t _pt;
public:
    FakeTLB(){
        _tlb_hit_set = new std::set<uint64_t>();
        _delay_list = new  std::list<DelaySlot>();
    }
    ~FakeTLB(){
        delete _tlb_hit_set;
        delete _delay_list;
    }

    void req(const bool& valid, const uint64_t& vtag);
    bool resp_vld();
    bool resp();
    uint64_t ptag();
    void eval();
};

#endif // _FAKE_TLB_HPP_