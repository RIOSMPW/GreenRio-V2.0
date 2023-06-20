#ifndef _MONITOR_HPP_
#define _MONITOR_HPP_
#include <stdio.h>
#include <iostream>
#include <exception>
#include <stdlib.h>
#include <set>
#include <list>
#include <vector> 
#include <fstream> 
#include <string> 
#include <map> 
#include "./fake_mem.hpp"
#include "./fake_rcu.hpp"
#include "./params.hpp"
#include "./util.hpp"



class Monitor{
private:
    FakeMemory* _real_mem = nullptr;
    FakeMemory* _perfect_mem = nullptr;

    std::list<RCUEntry>* _iss_que;

    bool _rcu_ready = 0;

    bool _req_vld = 0;
    RCUEntry _req;

    bool _resp_vld = 0;
    RCUEntry _resp;

    uint32_t _req_iss_num = 0;
    uint32_t _resp_comm_num = 0;

    std::map<uint16_t, std::vector<uint64_t>> _visit_history;
    std::list<uint8_t> _rd_free_list;

    // fence 
    uint16_t _lsu_head = 0;
    uint16_t _lsu_tail = 0;

    bool _fenced_vld = 0;
    uint16_t _fenced_lsq_index = 0;

    bool _lsu_iss_vld = 0;
    bool _lsu_iss_is_fenced = 0;
    uint16_t _lsu_iss_lsq_index = 0;

    bool _l1d_req_vld = 0;
    bool _l1d_req_is_fenced = 0;
    uint16_t _l1d_req_lsq_index = 0;
    bool _bus_req_vld = 0;
    bool _bus_req_is_fenced = 0;
    uint16_t _bus_req_lsq_index = 0;

    uint64_t _testcase_max = 0;
public:
    Monitor(FakeMemory* rm, FakeMemory* pm, const uint64_t& tm){
        _real_mem = rm;
        _perfect_mem = pm;
        _testcase_max = tm;
        _iss_que = new std::list<RCUEntry>();
        for(int i = 1; i < 64; i ++){
            _rd_free_list.push_back(uint8_t(i));
        }
    }
    ~Monitor(){
        delete _iss_que;
    }
    void rcu_ready(const bool& rcu_rdy);

    bool req_vld();
    RCUEntry req();

    void resp_vld(const bool& vld);
    void resp(const RCUEntry& r);   

    bool ut_done(); 

    void eval();

    bool mem_check();


    void lsu_head(const uint16_t& h);
    void lsu_tail(const uint16_t& t);

    void lsu_iss_vld(const bool& v);
    void lsu_iss_is_fenced(const bool& f);
    void lsu_iss_lsq_index(const uint16_t& ri);

    void l1d_req_vld(const bool& v);
    void l1d_req_is_fenced(const bool& f);
    void l1d_req_rob_index(const uint16_t& ri);

    void bus_req_vld(const bool& v);
    void bus_req_is_fenced(const bool& f);
    void bus_req_rob_index(const uint16_t& ri);
};

#endif // _MONITOR_HPP_
