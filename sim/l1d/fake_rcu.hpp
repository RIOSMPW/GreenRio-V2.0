#ifndef _UNCORE_FAKE_RCU_HPP_
#define _UNCORE_FAKE_RCU_HPP_
#include <stdio.h>
#include <iostream>
#include <exception>
#include <stdlib.h>
#include <set>
#include <list>
#include <vector> 
#include "./params.hpp"
#include "./util.hpp"






class FakeRCU {
private:
    std::list<Req>* _rcu;
    uint32_t issue_pt;

    bool _lsu_req_vld = 0;
    Req _lsu_req;

    bool _lsu_resp_vld = 0;
    Req _lsu_resp;

    bool _new_req_vld = 0;
    Req _new_req;

    bool _new_comm_vld = 0;
    Req _new_comm;

    bool _prf_wb_vld = 0;
    uint16_t _prf_wb_rd_addr = 0;
    uint64_t _prf_wb_data = 0;

    bool _wake_up_vld = 0;
    uint16_t _wake_up_rob_index = 0;

    bool _lsu_rdy = 0;
public:
    FakeRCU(){
        _rcu = new std::list<Req>();
    }
    ~FakeRCU(){
        delete _rcu;
    }
    // <> lsu
    bool req_vld();
    Req req();

    void lsu_rdy(const bool& rdy);
    
    void resp_vld(const bool& vld);
    void resp(const Req& cache_line);

    bool wakeup_vld();
    uint8_t wakeup_rob_index();

    // <> monitor
    bool rcu_rdy();
    void new_req_vld(const bool& vld);
    void new_req(const Req& e);
    bool commit_vld();
    Req commit();


    void eval();
};

#endif // _UNCORE_FAKE_RCU_HPP_
