/////////////////////////
// Author: Peichen Guo //
//    RIOS Lab work    //
//      HeHe Core      //
/////////////////////////
#include "Vlsu_dcache.h"

#include "../perfect_mem.hpp"
#include <iostream>
#include <string> 
#include <verilated.h>
#include "verilated_vcd_c.h"
#include <queue> 
#include <stdio.h>


// const uint64_t MAX_TIME = 3000;
const uint64_t MAX_TIME = 5548000000;
// const uint64_t MAX_TIME = 554800;
const uint64_t RANDOM_TEST_NUM = 1000000;
// const uint64_t RANDOM_TEST_NUM = 100;
const uint32_t RST_TIME = 600;


uint64_t main_time = 0;
Vlsu_dcache* lsu_dcache;

double sc_time_stamp(){
    return main_time;
}

void reset(){
   
    lsu_dcache->valid_i = 0;
    lsu_dcache->rob_index_i = 1;
    lsu_dcache->rd_addr_i = 1;
    lsu_dcache->rs1_data_i = 0;
    lsu_dcache->rs2_data_i = 0;
    lsu_dcache->imm_i = 0;
    lsu_dcache->opcode_i = 0;
    lsu_dcache->size_i = 0;
    lsu_dcache->load_sign_i = 0;
    return;
}
int main(int argc, char ** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC();

    lsu_dcache = new Vlsu_dcache("lsu_dcache");
    lsu_dcache->trace(tfp, 0);
    tfp->open("lsu_dcache.vcd");

    lsu_dcache->clk = 0;
    lsu_dcache->rstn = 1;
    lsu_dcache->stall = 0;
    lsu_dcache->flush = 0;

    reset();
    std::queue<request> req_que;
    std::queue<request> wait_que;
    std::queue<request> flush_que;
    PerfectMem* lsu_mem = new PerfectMem(0);
    PerfectMem* correct_mem = new PerfectMem(0);
    for(int i = 0; i < RANDOM_TEST_NUM; i ++){
        // uint8_t size = 3;
        int size = rand() % 4;
        bool opcode = rand() % 2;
        // bool opcode = 1;
        // bool unsign = 0;
        bool unsign = (size == 3 || opcode == 1) ? 0 : rand() % 2; // only load unsign
        req_que.push(request(uint64_t((uint64_t(rand()) << 32) + rand()), uint16_t(rand() << (3 + 8)) + ((rand() << size) & 0x7 ), size , unsign, opcode)); // size sign opcode
        // req_que.push(request(uint64_t((uint64_t(rand()) << 32) + rand()), uint16_t(rand() << size)  , size , unsign, opcode)); // size sign opcode
    }

    for(int i = 0; i < PERFECT_MEM_MAX_SIZE; i ++){ // flush with load
        flush_que.push(request(0,  (1 << 16) + uint16_t(i << 2) , 2, 1, 0)); // load 
    }
    uint32_t test_cnt = 0;

    try {
        while(main_time < MAX_TIME && (!req_que.empty() || !wait_que.empty() || !flush_que.empty())){
            if(main_time % 2){
                lsu_dcache->clk = 1;
                lsu_mem->set_clk(1);
            }
            else{
                lsu_dcache->clk = 0;
                lsu_mem->set_clk(0);

            }
            if(main_time == RST_TIME){
                lsu_dcache->rstn = 0;
            }
            if((RST_TIME + 100) <= main_time){
                if(!req_que.empty() || !wait_que.empty()){
                    lsu_dcache->valid_i = !req_que.empty();
                    lsu_dcache->rs1_data_i = req_que.front().address;
                    lsu_dcache->opcode_i = req_que.front().opcode;
                    lsu_dcache->rs2_data_i = req_que.front().data;
                    lsu_dcache->size_i = req_que.front().size; //dw 64bits
                    lsu_dcache->load_sign_i = req_que.front().sign; // signed
                }
                else {
                    lsu_dcache->valid_i = !flush_que.empty();
                    lsu_dcache->rs1_data_i = flush_que.front().address;
                    lsu_dcache->opcode_i = flush_que.front().opcode;
                    lsu_dcache->rs2_data_i = flush_que.front().data;
                    lsu_dcache->size_i = flush_que.front().size; //dw 64bits
                    lsu_dcache->load_sign_i = flush_que.front().sign; // signed
                }

                
                

                if(main_time % 2){
                    lsu_dcache->wb_ack_i = lsu_mem->resp_valid() | lsu_mem->wb_ack();
                    lsu_dcache->wb_dat_i = lsu_mem->resp32();

                    

                    if(lsu_dcache->ls_done_o){
                        // printf("\tdeque opcode:%x address:%x\n", wait_que.front().opcode, wait_que.front().address);
                        if(!req_que.empty() || !wait_que.empty()) {
                            if(wait_que.front().opcode){// store
                                // if((wait_que.front().address & 0xfff8) == (0xd001 & 0xfff8)){
                                //     printf("correcet mem write %d @ %x : %lx\n", (8 << wait_que.front().size), 
                                //         wait_que.front().address, wait_que.front().data);
                                // }
                                if(wait_que.front().size == 0){
                                    
                                    correct_mem->write8(wait_que.front().address, uint8_t(wait_que.front().data));
                                }
                                else if(wait_que.front().size == 1){
                                    correct_mem->write16(wait_que.front().address & 0xfffe, uint16_t(wait_que.front().data));
                                }
                                else if(wait_que.front().size == 2){
                                    
                                    correct_mem->write32(wait_que.front().address & 0xfffc, uint32_t(wait_que.front().data));
                                }
                                else {
                                    correct_mem->write64(wait_que.front().address & 0xfff8, wait_que.front().data);
                                }
                            }
                            else{// load
                                if(!lsu_dcache->load_data_valid_o){
                                    throw "lsu_dcache->load_data_valid_o should be zero";
                                }

                                if(wait_que.front().sign == 0){ // signed
                                    
                                    if(wait_que.front().size == 0 && 
                                        (lsu_dcache->load_data_o != 
                                                            (correct_mem->peek8(wait_que.front().address) & 0x80 ? 
                                                            (0xffffffffffffff00 +  uint64_t(correct_mem->peek8(wait_que.front().address))) :
                                                            uint64_t(correct_mem->peek8(wait_que.front().address)))
                                        )
                                    ){
                                        printf("@ %x, load:%x - correct:%x\n", wait_que.front().address,
                                            lsu_dcache->load_data_o, (correct_mem->peek8(wait_que.front().address) & 0x80 ? 
                                                            (0xffffffffffffff00 +  uint64_t(correct_mem->peek8(wait_que.front().address))) :
                                                            uint64_t(correct_mem->peek8(wait_que.front().address))));
                                        throw "\nload signed byte (8) wrong";
                                    }
                                    else if(wait_que.front().size == 1 && 
                                        (lsu_dcache->load_data_o != 
                                                            (correct_mem->peek16(wait_que.front().address) & 0x8000 ? 
                                                            (0xffffffffffff0000 +  uint64_t(correct_mem->peek16(wait_que.front().address))) :
                                                            uint64_t(correct_mem->peek16(wait_que.front().address))))
                                    ){
                                        throw "\nload signed half word (16) wrong";
                                    }
                                    else if(wait_que.front().size == 2 && 
                                        (lsu_dcache->load_data_o != 
                                                            (correct_mem->peek32(wait_que.front().address) & 0x80000000 ? 
                                                            (0xffffffff00000000 +  uint64_t(correct_mem->peek32(wait_que.front().address))) :
                                                            uint64_t(correct_mem->peek32(wait_que.front().address))))
                                    ){
                                        throw "\nload signed word (32) wrong";
                                    }
                                    else if(wait_que.front().size == 3 &&
                                        lsu_dcache->load_data_o != correct_mem->peek64(wait_que.front().address))
                                    {// dw
                                        printf("@ %x, load:%lx - correct:%lx\n", wait_que.front().address,
                                            lsu_dcache->load_data_o, correct_mem->peek64(wait_que.front().address));
                                        throw "\nload double word (64) wrong";
                                    }

                                }
                                else{
                                    // printf("data @ %lx: %lx\n", wait_que.front().address, lsu_dcache->load_data_o);
                                    if(wait_que.front().size == 0 && 
                                        (uint8_t(lsu_dcache->load_data_o) != correct_mem->peek8(wait_que.front().address)))
                                    {// byte
                                        throw "\nload byte (8) wrong";
                                    }
                                    else if (wait_que.front().size == 1 &&
                                        uint16_t(lsu_dcache->load_data_o) != correct_mem->peek16(wait_que.front().address)
                                    ){// hw
                                        printf("read 16 data:%x\n", correct_mem->peek16(wait_que.front().address));
                                        throw "\nload half word (16) wrong";
                                    }
                                    else if ((wait_que.front().size == 2) &&
                                        uint32_t(lsu_dcache->load_data_o) != correct_mem->peek32(wait_que.front().address))
                                    {// w
                                        throw "\nload word (32) wrong";
                                    }
                                    else if(wait_que.front().size == 3 &&
                                        lsu_dcache->load_data_o != correct_mem->peek64(wait_que.front().address))
                                    {// dw
                                        throw "\nload double word (64) wrong";
                                    }
                                }   
                                

                                
                            }

                            // printf("test %d done\n", test_cnt);
                            test_cnt ++;
                            wait_que.pop();
                        }
                    }
                    
                    if(lsu_dcache->wb_stb_o && lsu_dcache->wb_cyc_o && lsu_mem->ready()){
                        // printf("wb_we_o: %x\n", lsu_dcache->wb_we_o);
                        if(lsu_dcache->wb_we_o){//1
                            // if(lsu_dcache->wb_adr_o == (0xd001 & 0xfffc)){
                            //     printf("time: %d write @ %lx: %lx\n", main_time, lsu_dcache->wb_adr_o, lsu_dcache->wb_dat_o);
                            // }
                            lsu_mem->write32(uint16_t(lsu_dcache->wb_adr_o), lsu_dcache->wb_dat_o);
                        }
                        else{
                            // if(lsu_dcache->wb_adr_o == (0xd001 & 0xfffc)){
                            //     printf("read @ %x\n", lsu_dcache->wb_adr_o);
                            // }
                            lsu_mem->read32(uint16_t(lsu_dcache->wb_adr_o), 0);
                        }
                    }
                }
            }
            

            lsu_dcache->eval();
            lsu_mem->eval();
            correct_mem->eval(); 
            // if(main_time % 2) {
                
            // }
            // req in 
            if(main_time % 2 && ((RST_TIME + 100) <= main_time)){
                if(!req_que.empty() && lsu_dcache->lsu_ready_o){
                    // if(req_que.front().address  == 0xd001){
                    //     printf("time:%d\n", main_time);
                    //     printf("\tenque op: %d size:%d @ %x: %llx\n",  req_que.front().opcode,  req_que.front().size,
                    //         req_que.front().address, req_que.front().data);
                    // }
                        
                    // printf("\tenque opcode:%x address:%x\n", req_que.front().opcode, req_que.front().address);
                    wait_que.push(req_que.front());
                    req_que.pop();
                }
                if(req_que.empty() && wait_que.empty() && !flush_que.empty() && lsu_dcache->lsu_ready_o){
                    flush_que.pop();
                }
            }
            
            // if(300000 < main_time && main_time < 330000)
                tfp->dump(main_time);

            main_time ++;
        }
    }
    catch(const char* msg){
        lsu_dcache->final();
        tfp->close();
        // bool mem_same = lsu_mem->final_check(correct_mem);
        delete lsu_dcache;
        delete lsu_mem;
        delete correct_mem;
        delete tfp;
        // printf("\n lsu_dcache test done\n\n");
        std::cerr << msg << std::endl;
    }

    lsu_dcache->final();
    tfp->close();
    bool mem_same = lsu_mem->final_check(correct_mem);
    delete lsu_dcache;
    delete lsu_mem;
    delete correct_mem;
    delete tfp;
    assert(main_time != MAX_TIME);
    assert(mem_same);
    printf("\n lsu_dcache test done\n\n");
    exit(0);
}