#ifndef __UNCORE_FAKE_MEM_HPP__
#define __UNCORE_FAKE_MEM_HPP__
#include <stdio.h>
#include <fstream>
#include <iostream>
#include <stdlib.h>
#include <stdint.h>
#include <set>
#include <sstream>
#include <list>
#include "./util.hpp"

const uint32_t MEM_MAX_SIZE = 1 << 16;
class FakeMemory{
private:
    uint8_t* _mem = nullptr;
    uint8_t* _pagetable = nullptr;
    uint64_t _visit_time = 0;

    std::list<mem_req>* _req_q = nullptr;
    std::list<mem_req>* _req_wait_q = nullptr;
    std::list<mem_resp>* _resp_q = nullptr;
    bool _r_resp_on_flight = 0;

    bool _ar_vld = 0;
    axi_ar_req _ar_req;
    bool _aw_vld = 0;
    axi_aw_req _aw_req;
    bool _w_vld = 0;
    axi_w_req _w_req;

    bool _r_vld = 0;
    bool _r_rdy = 0;
    axi_r_resp _r_resp;
    bool _b_vld = 0;
    bool _b_rdy = 0;
    axi_b_resp _b_resp;
public:
    FakeMemory(std::string pagetable_mem){
        _mem = new uint8_t[MEM_MAX_SIZE];
        _pagetable = new uint8_t[MEM_MAX_SIZE];
        _req_wait_q = new std::list<mem_req>();
        _req_q = new std::list<mem_req>();
        _resp_q = new std::list<mem_resp>();
        uint32_t addr = 0;
        for(int i = 0; i < MEM_MAX_SIZE / 4; i ++){
            for(int j = 0; j < 4; j ++) {
                _mem[i*4 + j] = uint8_t(addr >> (j * 8));
                _pagetable[i*4 + j] = 0;
                // if(i < 25)
                //     printf("%02x",_mem[i*4 + j]);
            }
            addr += 4;
            // if(i < 25)
            //         printf("\n");
        }
        
        std::ifstream pagetable;
        pagetable.open(pagetable_mem.c_str(), std::ios::in);
        if(!pagetable.is_open()){
            std::string msg = "wrong pagetable dir: " + pagetable_mem;
            throw msg.c_str();
        }
        int tmp;
        int i = 0;
        while(!pagetable.eof()){
            pagetable >> std::hex >> tmp;
            // if(i < 1800 && i%8 == 0){
            //     std::cout << std::endl;
            // }
            // if(i < 1800){
            //     std::cout << std::hex << tmp << " ";
            // }
            
            _pagetable[i++] = tmp;
        }


    }
    ~FakeMemory(){
        delete _req_q;
        delete _resp_q;
        delete _pagetable;
        delete _mem;
    }
    uint8_t get_byte(const uint16_t&  paddr);
    void set_byte(const uint16_t&  paddr, const uint8_t& data);
    uint8_t pagetable_get_byte(const uint16_t&  paddr);
    void pagetable_set_byte(const uint16_t&  paddr, const uint8_t& data);

    void ar_vld(const bool& vld);
    void ar_req(const axi_ar_req& ar);
    void aw_vld(const bool& vld);
    void aw_req(const axi_aw_req& aw);
    void w_vld(const bool& vld);
    void w_req(const axi_w_req& w);

    void b_rdy(const bool & rdy);
    void r_rdy(const bool & rdy);

    bool r_vld() const;
    axi_r_resp r_resp() const;
    bool b_vld() const;
    axi_b_resp b_resp() const;

    uint64_t visit_time() const;

    void eval() throw(const char* );
};

#endif // __UNCORE_FAKE_MEM_HPP__
