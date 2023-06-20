#include "Vfake_lsu_dcache.h"

#include "../perfect_mem.hpp"
#include <iostream>
#include <string> 
#include <verilated.h>
#include "verilated_vcd_c.h"
#include <queue> 
#include <stdio.h>


// const uint64_t MAX_TIME = 1000;
const uint64_t MAX_TIME = 548000;
const uint64_t RANDOM_TEST_NUM = 3;
// const uint64_t RANDOM_TEST_NUM = 1000;
const uint32_t RST_TIME = 600;


uint64_t main_time = 0;
Vfake_lsu_dcache* fake_lsu_dcache;

double sc_time_stamp(){
    return main_time;
}

void reset(){
   
    fake_lsu_dcache->valid_i = 0;
    fake_lsu_dcache->rob_index_i = 1;
    fake_lsu_dcache->rd_addr_i = 1;
    fake_lsu_dcache->rs1_data_i = 0;
    fake_lsu_dcache->rs2_data_i = 0;
    fake_lsu_dcache->imm_i = 0;
    fake_lsu_dcache->opcode_i = 0;
    fake_lsu_dcache->size_i = 0;
    fake_lsu_dcache->load_sign_i = 0;
    return;
}

int main(int argc, char ** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC();

    fake_lsu_dcache = new Vfake_lsu_dcache("fake_lsu_dcache");
    fake_lsu_dcache->trace(tfp, 0);
    tfp->open("wave.vcd");

    fake_lsu_dcache->clk = 0;
    fake_lsu_dcache->rstn = 1;
    fake_lsu_dcache->stall = 0;
    fake_lsu_dcache->flush = 0;

    reset();
    std::queue<request> req_que;
    std::queue<request> wait_que;
    std::queue<request> flush_que;

    PerfectMem* correct_mem = new PerfectMem(0);
    for(int i = 0; i < RANDOM_TEST_NUM; i ++){
        int size = 0;
        // int size = rand() % 4;
        // bool opcode = rand() % 2;
        bool opcode = 1;
        req_que.push(request(uint64_t(rand()), uint16_t(rand() << size)  , size , 0, opcode)); // size sign opcode
    }
    for(int i = 0; i < PERFECT_MEM_MAX_SIZE; i ++){ // flush with load
        flush_que.push(request(0,  (1 << 16) + uint16_t(i << 2) , 2, 0, 0)); // load 
    }
    uint32_t test_cnt = 0;

    try {
        while(main_time < MAX_TIME && (!req_que.empty() || !wait_que.empty())){
            if(main_time % 2){
                fake_lsu_dcache->clk = 1;
            }
            else{
                fake_lsu_dcache->clk = 0;
            }
            if(main_time == RST_TIME){
                fake_lsu_dcache->rstn = 0;
            }
            if((RST_TIME + 100) <= main_time){
                // assign 
                fake_lsu_dcache->valid_i = !req_que.empty();
                fake_lsu_dcache->rs1_data_i = req_que.front().address;
                fake_lsu_dcache->opcode_i = req_que.front().opcode;
                fake_lsu_dcache->rs2_data_i = req_que.front().data;
                fake_lsu_dcache->size_i = req_que.front().size; //dw 64bits
                fake_lsu_dcache->load_sign_i = req_que.front().sign; // signed

                if(main_time % 2){
                    // req done
                    if(fake_lsu_dcache->ls_done_o){
                        // printf("\tdeque opcode:%x address:%x\n", wait_que.front().opcode, wait_que.front().address);
                        if(wait_que.front().opcode){// store
                            
                            if(wait_que.front().size == 0){
                                if(wait_que.front().address  == 0x9868){
                                    printf("correcet mem write %d @ %x : %lx\n", 1 << wait_que.front().size, 
                                        wait_que.front().address, wait_que.front().data);
                                }
                                correct_mem->write8(wait_que.front().address, uint8_t(wait_que.front().data));
                            }
                            else if(wait_que.front().size == 1){
                                correct_mem->write16(wait_que.front().address & 0xfffe, uint16_t(wait_que.front().data));
                            }
                            else if(wait_que.front().size == 2){
                                if(wait_que.front().address  == 0x4 || wait_que.front().address == 0x0){
                                    printf("correcet mem write %d @ %x : %lx\n", (8 << wait_que.front().size), 
                                        wait_que.front().address, wait_que.front().data);
                                }
                                correct_mem->write32(wait_que.front().address & 0xfffc, uint32_t(wait_que.front().data));
                            }
                            else {
                                correct_mem->write64(wait_que.front().address & 0xfff8, wait_que.front().data);
                            }
                        }
                        else{// load
                            //FIXME: 没有查unsigned
                            if(!fake_lsu_dcache->load_data_valid_o){
                                throw "fake_lsu_dcache->load_data_valid_o should be zero";
                            }
                                
                            printf("data @ %lx: %lx\n", wait_que.front().address, fake_lsu_dcache->load_data_o);
                            if(wait_que.front().size == 0 && 
                                uint8_t(fake_lsu_dcache->load_data_o) != correct_mem->peek8(wait_que.front().address))
                            {// byte
                                throw "\nload byte (8) wrong";
                            }
                            else if (wait_que.front().size == 1 &&
                                uint16_t(fake_lsu_dcache->load_data_o) != correct_mem->peek16(wait_que.front().address)
                            ){// hw
                                printf("read 16 data:%x\n", correct_mem->peek16(wait_que.front().address));
                                throw "\nload half word (16) wrong";
                            }
                            else if ((wait_que.front().size == 2) &&
                                uint32_t(fake_lsu_dcache->load_data_o) != correct_mem->peek32(wait_que.front().address))
                            {// w
                                throw "\nload word (32) wrong";
                            }
                            else if(wait_que.front().size == 3 &&
                                fake_lsu_dcache->load_data_o != correct_mem->peek64(wait_que.front().address))
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
            

            fake_lsu_dcache->eval();
            if(main_time % 2) {
                correct_mem->eval();
            }
            // req in 
            if(main_time % 2 && ((RST_TIME + 100) <= main_time)){
                if(!req_que.empty() && fake_lsu_dcache->lsu_ready_o){
                    // if(req_que.front().address  == 0x9868){
                        printf("test:%d\n", test_cnt);
                        printf("\tenque write @ %x: %lx\n", req_que.front().address, req_que.front().data);
                    // }
                        
                    // printf("\tenque opcode:%x address:%x\n", req_que.front().opcode, req_que.front().address);
                    wait_que.push(req_que.front());
                    req_que.pop();
                }
            }
            

            tfp->dump(main_time);

            main_time ++;
        }

        // wait
        uint32_t time = main_time;
        while(main_time < time + 100){

            if(main_time % 2){
                fake_lsu_dcache->clk = 1;
            }
            else{
                fake_lsu_dcache->clk = 0;
            }

            fake_lsu_dcache->valid_i = !req_que.empty();
            fake_lsu_dcache->rs1_data_i = req_que.front().address;
            fake_lsu_dcache->opcode_i = req_que.front().opcode;
            fake_lsu_dcache->rs2_data_i = req_que.front().data;
            fake_lsu_dcache->size_i = req_que.front().size; //dw 64bits
            fake_lsu_dcache->load_sign_i = req_que.front().sign; // signed

            if(main_time % 2){
                
                // req done
                if(fake_lsu_dcache->ls_done_o){
                    // printf("\tdeque opcode:%x address:%x\n", wait_que.front().opcode, wait_que.front().address);
                    if(wait_que.front().opcode){// store
                        
                        if(wait_que.front().size == 0){
                            if(wait_que.front().address  == 0x9868){
                                printf("correcet mem write %d @ %x : %lx\n", 1 << wait_que.front().size, 
                                    wait_que.front().address, wait_que.front().data);
                            }
                            correct_mem->write8(wait_que.front().address, uint8_t(wait_que.front().data));
                        }
                        else if(wait_que.front().size == 1){
                            correct_mem->write16(wait_que.front().address & 0xfffe, uint16_t(wait_que.front().data));
                        }
                        else if(wait_que.front().size == 2){
                            if(wait_que.front().address  == 0x4 || wait_que.front().address == 0x0){
                                printf("correcet mem write %d @ %x : %lx\n", (8 << wait_que.front().size), 
                                    wait_que.front().address, wait_que.front().data);
                            }
                            correct_mem->write32(wait_que.front().address & 0xfffc, uint32_t(wait_que.front().data));
                        }
                        else {
                            correct_mem->write64(wait_que.front().address & 0xfff8, wait_que.front().data);
                        }
                    }
                    else{// load
                        //FIXME: 没有查unsigned
                        if(!fake_lsu_dcache->load_data_valid_o){
                            throw "fake_lsu_dcache->load_data_valid_o should be zero";
                        }
                            
                        printf("data @ %lx: %lx\n", wait_que.front().address, fake_lsu_dcache->load_data_o);
                        if(wait_que.front().size == 0 && 
                            uint8_t(fake_lsu_dcache->load_data_o) != correct_mem->peek8(wait_que.front().address))
                        {// byte
                            throw "\nload byte (8) wrong";
                        }
                        else if (wait_que.front().size == 1 &&
                            uint16_t(fake_lsu_dcache->load_data_o) != correct_mem->peek16(wait_que.front().address)
                        ){// hw
                            printf("read 16 data:%x\n", correct_mem->peek16(wait_que.front().address));
                            throw "\nload half word (16) wrong";
                        }
                        else if ((wait_que.front().size == 2) &&
                            uint32_t(fake_lsu_dcache->load_data_o) != correct_mem->peek32(wait_que.front().address))
                        {// w
                            throw "\nload word (32) wrong";
                        }
                        else if(wait_que.front().size == 3 &&
                            fake_lsu_dcache->load_data_o != correct_mem->peek64(wait_que.front().address))
                        {// dw
                            throw "\nload double word (64) wrong";
                        }
                    }

                    // printf("test %d done\n", test_cnt);
                    test_cnt ++;
                    wait_que.pop();
                }
            }
            
            tfp->dump(main_time);

            main_time ++;
        }
        
    }
    catch(const char* msg){
        fake_lsu_dcache->final();
        tfp->close();
        delete fake_lsu_dcache;
        delete correct_mem;
        delete tfp;
        // printf("\n fake_lsu_dcache test done\n\n");
        std::cerr << msg << std::endl;
    }

    fake_lsu_dcache->final();
    tfp->close();
    delete fake_lsu_dcache;
    delete correct_mem;
    delete tfp;
    assert(main_time != MAX_TIME);
    assert(mem_same);
    printf("\n fake_lsu_dcache test done\n\n");
    exit(0);
}