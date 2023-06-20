#ifndef _FAKE_CACHE_HPP_
#define _FAKE_CACHE_HPP_
#include <stdio.h>
#include <iostream>
#include <exception>
#include <stdlib.h>
#include <set>
#include <list>
#include "./fake_mem.hpp"
#include "./params.hpp"
#include "./util.hpp"




class FakeL1DCache{
private:
    std::set<uint64_t>* _cache_hit_set;
    std::list<CacheLine>* _cache_line_list;
    std::set<uint16_t>* _cache_delay_set;
    FakeMemory* _real_mem = nullptr;
    bool _req_vld = 0; 
    bool _hsk_q = 0;
    CacheLine _req;
    bool _kill_req = 0;

    bool _ld_resp_vld = 0;
    CacheLine _ld_resp;
    bool _st_resp_vld = 0;
    CacheLine _st_resp;

    bool _l1d_req_vld = 0;
    bool _l1d_req_is_fenced = 0;
    uint16_t _l1d_req_rob_index = 0;

    bool _dtlb_resp_vld = 0;
    bool _dtlb_resp_hit = 0;
public:
    FakeL1DCache(FakeMemory* mem){
        _cache_hit_set = new std::set<uint64_t>();
        _cache_line_list = new  std::list<CacheLine>();
        _cache_delay_set = new std::set<uint16_t>();
        _real_mem = mem;
    }
    ~FakeL1DCache(){
        delete _cache_hit_set;
        delete _cache_line_list;
        delete _cache_delay_set; 
    }
    void req_vld(const bool& vld);
    void req(const uint64_t& vi, const uint64_t& vo, const uint64_t& pt, const uint64_t& pa, const uint64_t& d, const uint8_t& ri, 
        const uint8_t& rd, const uint16_t& de, const bool & fence, const bool& ls, const uint8_t& op);
    void kill_req(const bool& kil);

    bool ld_resp_vld();
    CacheLine ld_resp();
    bool st_resp_vld();
    CacheLine st_resp();

    void dtlb_resp_vld(const bool& dtlb_vld);
    void dtlb_resp(const bool& dtlb_hit);

    bool ready();

    void eval();

    bool l1d_req_vld() const;
    bool l1d_req_is_fenced() const;
    uint16_t l1d_req_rob_index() const;
};

#endif // _FAKE_CACHE_HPP_
