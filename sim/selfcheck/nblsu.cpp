/////////////////////////
// Author: Peichen Guo //
//    RIOS Lab work    //
//      HeHe Core      //
/////////////////////////
#include "Vnblsu.h"
#include "../perfect_mem.hpp"
#include "verilated_vcd_c.h"
#include <iostream>
#include <verilated.h>
#include <queue> 
#include <stdio.h>

const uint64_t MAX_TIME = 5000;
// const uint64_t RANDOM_TEST_NUM = 1 << 10;
const uint64_t RANDOM_TEST_NUM = 10;


uint64_t main_time = 0;
Vnblsu* nblsu;

double sc_time_stamp(){
    return main_time;
}

void reset(){
    nblsu->valid_i = 0;
    nblsu->rob_index_i = 1;
    nblsu->rd_addr_i = 1;
    nblsu->rs1_data_i = 0;
    nblsu->rs2_data_i = 0;
    nblsu->imm_i = 0;
    nblsu->opcode_i = 0;
    nblsu->size_i = 0;
    nblsu->load_sign_i = 0;

    nblsu->req_ready_i = 1;
    
    nblsu->resp_valid_i = 0;
    nblsu->resp_data_i = 0;
    nblsu->resp_lsq_index_i = 0;
    nblsu->resp_ready_o = 1;

    nblsu->wb_ack_i = 0;
    nblsu->wb_dat_i = 0;
    return;
}

int main(int argc, char ** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    
    nblsu = new Vnblsu;
    nblsu->clk = 0;
    nblsu->rstn = 1;
    // nblsu->stall = 0;
    nblsu->flush = 0;

    reset();
    // // cases tests
    // while(main_time < MAX_TIME){
        
    //     if(main_time % 2){
    //         nblsu->clk = 1;
    //     }
    //     else{
    //         nblsu->clk = 0;
    //     }
    //     if(main_time == 2){
    //         nblsu->rstn = 0;
    //     }


    //     switch (main_time)
    //     {
    //     case 4 : {
            
    //         // single load
    //         // load to queue
    //         nblsu->valid_i = 1;
    //         nblsu->rob_index_i = 0;
    //         nblsu->rd_addr_i = 1;
    //         nblsu->rs1_data_i = 0x80000000;
    //         nblsu->rs2_data_i = 0;
    //         nblsu->imm_i = 0x10;
    //         nblsu->opcode_i = 0; //load
    //         nblsu->size_i = 0;
    //         nblsu->load_sign_i = 1;

    //         nblsu->req_ready_i = 1;
            
    //         nblsu->resp_valid_i = 0;
    //         nblsu->resp_data_i = 0;
    //         nblsu->resp_lsq_index_i = 0;
    //         break;
            
    //     }
    //     case 6 : {
    //         nblsu->valid_i = 0;
    //         // printf("tail_o: %x\n", nblsu->tail_o);
    //         // printf("req pt: %x\n", nblsu->req_pt_o);
    //         // assert(nblsu->head_o == 0);
    //         // assert(nblsu->tail_o == 1);
    //         // assert(nblsu->req_pt_o == 0);
    //         // req send
    //         assert(nblsu->req_valid_o);
    //         assert(nblsu->req_opcode_o == 0);
    //         assert(nblsu->req_sign_o == 0);
    //         assert(nblsu->req_size_o == 0);
    //         assert(nblsu->req_addr_o == 0x80000000 + 0x10);
    //         // assert(nblsu->req_rob_index_o == 0);
    //         assert(nblsu->req_lsq_index_o == 0);
    //         break;
    //     }
    //     case 8 : {
    //         // send
    //         // printf("tail_o: %x\n", nblsu->tail_o);
    //         // assert(nblsu->head_o == 0);
    //         // assert(nblsu->tail_o == 1);
    //         // assert(nblsu->req_pt_o == 1); 
    //         // assert(nblsu->);
    //         // assert(nblsu->);
    //         // assert(nblsu->);
    //         break;
    //     }
    //     case 9 : {
    //         nblsu->resp_valid_i = 1;
    //         nblsu->resp_lsq_index_i = 0;
    //         nblsu->resp_data_i = 0x114514;
    //         break;
    //     }
    //     case 10 : {
    //         // resp in 
            
    //         // assert(nblsu->head_o == 0);
    //         assert(nblsu->ls_done_o);
    //         assert(nblsu->load_data_valid_o);
    //         assert(nblsu->load_data_o == 0x114514);;
    //         assert(nblsu->rob_index_o == 0);
    //         assert(!nblsu->exception_valid_o);
    //         break;
    //     }
    //     case 12 : {
    //         nblsu->resp_valid_i = 0;
    //         // assert(nblsu->head_o == 1);
    //         // assert(nblsu->tail_o == 1);
    //         // assert(nblsu->req_pt_o == 1); 
    //         break;
    //     }
    //     case 14 : {
    //         reset();
    //         // assert(nblsu->head_o == 1);
    //         // assert(nblsu->tail_o == 1);
    //         // assert(nblsu->req_pt_o == 1); 

    //         // single store
    //         nblsu->valid_i = 1;
    //         nblsu->rob_index_i = 0;
    //         nblsu->rd_addr_i = 1;
    //         nblsu->rs1_data_i = 0x80000000;
    //         nblsu->rs2_data_i = 0;
    //         nblsu->imm_i = 0x10;
    //         nblsu->opcode_i = 1; // store
    //         nblsu->size_i = 0;
    //         nblsu->load_sign_i = 0;
    //         break;
    //     }
    //     case 16 : {
    //         nblsu->valid_i = 0;
    //         // assert(nblsu->head_o == 1);
    //         // assert(nblsu->tail_o == 2);
    //         // assert(nblsu->req_pt_o == 1); 
    //         break;
    //     }
    //     case 18 : {
    //         // assert(nblsu->head_o == 1);
    //         // assert(nblsu->tail_o == 2);
    //         // assert(nblsu->req_pt_o == 2); 
    //         break;
    //     }
    //     case 20 : {
    //         // assert(nblsu->head_o == 2);
    //         // assert(nblsu->tail_o == 2);
    //         // assert(nblsu->req_pt_o == 2); 
    //         break;
    //     }
    //     case 22 : {
    //         // load <- store <- load <- store
    //         // load 1
    //         nblsu->valid_i = 1;
    //         nblsu->rob_index_i = 0;
    //         nblsu->rd_addr_i = 1;
    //         nblsu->rs1_data_i = 0x80000000;
    //         nblsu->rs2_data_i = 0;
    //         nblsu->imm_i = 0x10;
    //         nblsu->opcode_i = 0; //load 0
    //         nblsu->size_i = 0;
    //         nblsu->load_sign_i = 0;
    //         // assert(nblsu->head_o == 2);
    //         // assert(nblsu->tail_o == 2);
    //         // assert(nblsu->req_pt_o == 2); 
    //         break;
    //     }
    //     case 24 : {
    //         nblsu->valid_i = 1;
    //         nblsu->rob_index_i = 0;
    //         nblsu->rd_addr_i = 1;
    //         nblsu->rs1_data_i = 0x80000000;
    //         nblsu->rs2_data_i = 0;
    //         nblsu->imm_i = 0x20;
    //         nblsu->opcode_i = 1; //store 0
    //         nblsu->size_i = 0;
    //         nblsu->load_sign_i = 0;
    //         // assert(nblsu->head_o == 2);
    //         // assert(nblsu->tail_o == 3);
    //         // assert(nblsu->req_pt_o == 2); 

    //         assert(!nblsu->ls_done_o);
    //         assert(!nblsu->exception_valid_o);

    //         // req load 0 send
    //         assert(nblsu->req_valid_o);
    //         assert(nblsu->req_opcode_o == 0);
    //         assert(nblsu->req_addr_o == 0x80000000 + 0x10);
    //         assert(nblsu->req_lsq_index_o == 2);
    //         break;
    //     }
    //     case 26 : {
    //         nblsu->valid_i = 1;
    //         nblsu->rob_index_i = 0;
    //         nblsu->rd_addr_i = 1;
    //         nblsu->rs1_data_i = 0x80000000;
    //         nblsu->rs2_data_i = 0;
    //         nblsu->imm_i = 0x30;
    //         nblsu->opcode_i = 0; //load 1
    //         nblsu->size_i = 0;
    //         nblsu->load_sign_i = 0;
    //         // assert(nblsu->head_o == 2);
    //         // assert(nblsu->tail_o == 0);
    //         // assert(nblsu->req_pt_o == 3); 

    //         assert(!nblsu->ls_done_o);
    //         assert(!nblsu->exception_valid_o);

    //         // req store 0 send
    //         assert(nblsu->req_valid_o);
    //         assert(nblsu->req_opcode_o == 1);
    //         assert(nblsu->req_addr_o == 0x80000000 + 0x20);
    //         assert(nblsu->req_lsq_index_o == 3);
    //         break;
    //     }
    //     case 27 :{
    //         // resp 1 in 
    //         nblsu->resp_valid_i = 1;
    //         nblsu->resp_lsq_index_i = 0;
    //         nblsu->resp_data_i = 0x123456;
    //         break;
    //     }
    //     case 28 : {
    //         nblsu->valid_i = 1;
    //         nblsu->rob_index_i = 0;
    //         nblsu->rd_addr_i = 1;
    //         nblsu->rs1_data_i = 0x80000000;
    //         nblsu->rs2_data_i = 0;
    //         nblsu->imm_i = 0x40;
    //         nblsu->opcode_i = 1; // store 1
    //         nblsu->size_i = 0;
    //         nblsu->load_sign_i = 0;
    //         // assert(nblsu->head_o == 2);
    //         // assert(nblsu->tail_o == 1);
    //         // assert(nblsu->req_pt_o == 0); 
    //         // req load 1 send
    //         assert(nblsu->req_valid_o);
    //         assert(nblsu->req_opcode_o == 0);
    //         assert(nblsu->req_addr_o == 0x80000000 + 0x30);
    //         assert(nblsu->req_lsq_index_o == 0);
            
    //         // load 1 get resp, should not be done
    //         assert(!nblsu->ls_done_o);
    //         assert(!nblsu->load_data_valid_o);

    //         break;
    //     }
    //     case 29 :{
    //         // load 0 get resp
    //         nblsu->resp_valid_i = 1;
    //         nblsu->resp_lsq_index_i = 2;
    //         nblsu->resp_data_i = 0x114514;
    //         break;
    //     }
    //     case 30 : {
    //         nblsu->valid_i = 0;
    //         // assert(nblsu->head_o == 2);
    //         // assert(nblsu->tail_o == 2);
    //         // assert(nblsu->req_pt_o == 1); 
    //         // lsu ready should be down
    //         assert(!nblsu->lsu_ready_o);
    //         // req store 1 send
    //         assert(nblsu->req_valid_o);
    //         assert(nblsu->req_opcode_o == 1);
    //         assert(nblsu->req_addr_o == 0x80000000 + 0x40);
    //         assert(nblsu->req_lsq_index_o == 1);
    //         // load 0 resp
    //         assert(nblsu->ls_done_o);
    //         assert(nblsu->load_data_valid_o);
    //         assert(nblsu->load_data_o == 0x114514);
    //         break;
    //     }
    //     case 32 : {
    //         nblsu->resp_valid_i = 0;
    //         assert(nblsu->lsu_ready_o);
    //         assert(nblsu->ls_done_o);
    //         assert(!nblsu->load_data_valid_o);
    //         // assert(nblsu->load_data_o == 0x114514);
    //         // assert(nblsu->head_o == 3);
    //         // assert(nblsu->tail_o == 2);
    //         // assert(nblsu->req_pt_o == 2); 
    //         break;
    //     }
    //     case 34 : {
    //         assert(nblsu->ls_done_o);
    //         assert(nblsu->load_data_valid_o);
    //         assert(nblsu->load_data_o == 0x123456);
    //         // assert(nblsu->head_o == 0);
    //         // assert(nblsu->tail_o == 2);
    //         // assert(nblsu->req_pt_o == 2); 
    //         break;
    //     }
    //     case 36 : {
    //         assert(nblsu->ls_done_o);
    //         assert(!nblsu->load_data_valid_o);
    //         // assert(nblsu->load_data_o == 0x114514);
    //         // assert(nblsu->head_o == 1);
    //         // assert(nblsu->tail_o == 2);
    //         // assert(nblsu->req_pt_o == 2); 
    //         break;
    //     }
    //     case 38 : {
    //         assert(!nblsu->ls_done_o);
    //         assert(!nblsu->load_data_valid_o);
    //         // assert(nblsu->load_data_o == 0x114514);
    //         // assert(nblsu->head_o == 2);
    //         // assert(nblsu->tail_o == 2);
    //         // assert(nblsu->req_pt_o == 2); 
    //         break;
    //     }
    //     case 40 : {
    //         // load(exception) <= store
    //         // load (exception)
    //         nblsu->valid_i = 1;
    //         nblsu->rob_index_i = 0;
    //         nblsu->rd_addr_i = 1;
    //         nblsu->rs1_data_i = 0x80000000;
    //         nblsu->rs2_data_i = 0;
    //         nblsu->imm_i = 0x11;
    //         nblsu->opcode_i = 0; //load 0
    //         nblsu->size_i = 2;
    //         nblsu->load_sign_i = 0;
    //         // assert(nblsu->head_o == 2);
    //         // assert(nblsu->tail_o == 2);
    //         // assert(nblsu->req_pt_o == 2); 
    //         break;
    //     }
    //     case 42 : {
    //         nblsu->valid_i = 1;
    //         nblsu->rob_index_i = 0;
    //         nblsu->rd_addr_i = 1;
    //         nblsu->rs1_data_i = 0x80000000;
    //         nblsu->rs2_data_i = 0;
    //         nblsu->imm_i = 0x20;
    //         nblsu->opcode_i = 1; //store
    //         nblsu->size_i = 0;
    //         nblsu->load_sign_i = 0;
    //         // req load 0 send
    //         assert(!nblsu->req_valid_o);
    //         assert(nblsu->ls_done_o);
    //         assert(nblsu->exception_valid_o);
    //         assert(nblsu->ecause_o == 4); // EXCEPTION_LOAD_ADDR_MISALIGNED
            
    //         // assert(nblsu->head_o == 2);
    //         // assert(nblsu->tail_o == 3);
    //         // assert(nblsu->req_pt_o == 2); 
    //         break;
    //     }
    //     case 44 : {
    //         // no morw send 
    //         assert(!nblsu->req_valid_o);
    //         // assert(nblsu->head_o == 3);
    //         // assert(nblsu->tail_o == 0);
    //         // assert(nblsu->req_pt_o == 2); 
    //         break;
    //     }
        
    //     default:
    //         break;
    //     }

    //     nblsu->eval();
    //     main_time ++;
    // }

    // printf("\n======= nblsu case tests done =======\n\n");

    nblsu->final();
    delete nblsu;
    
    //* random test 

    main_time = 0;
    VerilatedVcdC* tfp = new VerilatedVcdC();
    nblsu = new Vnblsu("nblsu");
    nblsu->clk = 0;
    nblsu->rstn = 1;
    // nblsu->stall = 0;
    nblsu->flush = 0;
    nblsu->trace(tfp, 0);
    tfp->open("nblsu.vcd");

    reset();
    std::queue<request> req_que;
    std::queue<request> wait_que;
    PerfectMem* lsu_mem = new PerfectMem(1);
    PerfectMem* correct_mem = new PerfectMem(0);

    for(int i = 0; i < RANDOM_TEST_NUM; i ++){
        // int size = 3;
        // uint32_t mapping = 0;
        uint32_t mapping = (rand() % 2 == 0) ? 0 : 0x10000000;
        int size = (mapping > 0) ? 2 : rand() % 4;
        bool opcode = rand() % 2;
        // bool opcode = 1;
        // printf("mapping:%x\n", mapping);
        req_que.push(request(uint64_t(rand()), mapping + uint32_t((rand() << size) & 0xffff) , size , 0, opcode)); // size sign opcode
    }
    uint32_t test_cnt = 0;

    try {
        while(main_time < MAX_TIME && (!req_que.empty() || !wait_que.empty())){
            if(main_time % 2){
                nblsu->clk = 1;
            }
            else{
                nblsu->clk = 0;
            }
            if(main_time == 10){
                nblsu->rstn = 0;
            }
            
            if(100 <= main_time){
                // assign 
                nblsu->rs1_data_i = req_que.front().address;
                nblsu->opcode_i = req_que.front().opcode;
                nblsu->rs2_data_i = req_que.front().data;
                nblsu->size_i = req_que.front().size; //dw 64bits
                nblsu->load_sign_i = req_que.front().sign; // signed
                nblsu->valid_i = !req_que.empty();
                
                

                nblsu->req_ready_i = lsu_mem->ready();

                
                

                if(main_time % 2){
                    // if(lsu_mem->resp_valid()) 
                    //     printf("resp back: %x\n", lsu_mem->resp32());
                    nblsu->wb_ack_i = lsu_mem->resp_valid();
                    nblsu->resp_valid_i = lsu_mem->resp_valid();
                    if(main_time < 150)
                        printf("resp valid %x, wb_ack: %x\n",  nblsu->resp_valid_i, nblsu->wb_ack_i);
                    nblsu->resp_data_i = lsu_mem->resp();
                    nblsu->wb_dat_i = lsu_mem->resp();
                    // printf("lsumem resp: %x\n", lsu_mem->resp());
                    nblsu->resp_lsq_index_i = lsu_mem->resp_lsq_index();
                    lsu_mem->lsu_ready(1);

                    if((nblsu->req_valid_o) && lsu_mem->ready()){
                        if(nblsu->req_opcode_o == 1){ // store
                            if(nblsu->req_size_o == 0)
                                lsu_mem->write8(uint16_t(nblsu->req_addr_o), nblsu->req_data_o);
                            else if(nblsu->req_size_o == 1)
                                lsu_mem->write16(uint16_t(nblsu->req_addr_o), nblsu->req_data_o);
                            else if(nblsu->req_size_o == 2)
                                lsu_mem->write32(uint16_t(nblsu->req_addr_o), nblsu->req_data_o);
                            else 
                                lsu_mem->write64(uint16_t(nblsu->req_addr_o), nblsu->req_data_o);
                        }
                        else{ // load
                            if(nblsu->req_size_o == 0)
                                lsu_mem->read8(uint16_t(nblsu->req_addr_o), nblsu->req_lsq_index_o);
                            else if(nblsu->req_size_o == 1)
                                lsu_mem->read16(uint16_t(nblsu->req_addr_o), nblsu->req_lsq_index_o);
                            else if(nblsu->req_size_o == 2)
                                lsu_mem->read32(uint16_t(nblsu->req_addr_o), nblsu->req_lsq_index_o);
                            else 
                                lsu_mem->read64(uint16_t(nblsu->req_addr_o), nblsu->req_lsq_index_o);
                        }
                    
                    }
                    else if(nblsu->wb_stb_o && lsu_mem->ready()){
                        if(nblsu->wb_we_o == 1){ // store
                            lsu_mem->write32(uint16_t(nblsu->wb_adr_o), nblsu->wb_dat_o);
                        }
                        else{ // load
                            lsu_mem->read32(uint16_t(nblsu->wb_adr_o), nblsu->wb_dat_o);
                        }
                    
                    }
                    // req done
                    if(nblsu->ls_done_o){
                        printf("t:%d deque opcode:%x address:%x\n",main_time, wait_que.front().opcode, wait_que.front().address);
                        if(wait_que.front().opcode){// store
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
                            //FIXME: 没有查unsigned
                            // printf("data @ %lx: %lx\n", wait_que.front().address, nblsu->load_data_o);
                            if(!nblsu->load_data_valid_o){
                                throw "nblsu->load_data_valid_o should be zero";
                            }
                                
                            if(wait_que.front().size == 0 && 
                                uint8_t(nblsu->load_data_o) != correct_mem->peek8(wait_que.front().address))
                            {// byte
                                throw "\nload byte (8) wrong";
                            }
                            else if (wait_que.front().size == 1 &&
                                uint16_t(nblsu->load_data_o) != correct_mem->peek16(wait_que.front().address)
                            ){// hw
                                printf("read 16 data:%x\n", correct_mem->peek16(wait_que.front().address));
                                throw "\nload half word (16) wrong";
                            }
                            else if ((wait_que.front().size == 2) &&
                                uint32_t(nblsu->load_data_o) != correct_mem->peek32(wait_que.front().address))
                            {// w
                                printf("%x - %x\n", nblsu->load_data_o,  correct_mem->peek32(wait_que.front().address));
                                throw "\nload word (32) wrong";
                            }
                            else if(wait_que.front().size == 3 &&
                                nblsu->load_data_o != correct_mem->peek64(wait_que.front().address))
                            {// dw
                                throw "\nload double word (64) wrong";
                            }
                        }

                        // printf("test %d done\n", test_cnt);
                        test_cnt ++;
                        wait_que.pop();
                    }
                }

            }
            

            nblsu->eval();
            if(main_time % 2) {
                lsu_mem->eval();
                correct_mem->eval();
            }
            // req in 
            if(main_time % 2 && (100 <= main_time)){
                if(!req_que.empty() && nblsu->lsu_ready_o){ 
                    printf("t:%d enque opcode:%x address:%x\n", main_time, 
                        req_que.front().opcode, req_que.front().address);
                    wait_que.push(req_que.front());
                    req_que.pop();
                }
            }

            tfp->dump(main_time);
            main_time ++;
        }
    }
    catch(const char* msg){
        nblsu->final();
        tfp->close();
        // bool mem_same = lsu_mem->final_check(correct_mem);
        delete nblsu;
        delete lsu_mem;
        delete correct_mem;
        delete tfp;
        // printf("\n nblsu test done\n\n");
        std::cerr << msg << std::endl;
        exit(0);
    }

    nblsu->final();
    tfp->close();
    bool mem_same = lsu_mem->final_check(correct_mem);
    delete nblsu;
    delete lsu_mem;
    delete correct_mem;
    delete tfp;
    assert(main_time != MAX_TIME);
    assert(mem_same);
    // assert(main_time != MAX_TIME);
    printf("\n======= nblsu random tests done =======\n\n");
    exit(0);
}