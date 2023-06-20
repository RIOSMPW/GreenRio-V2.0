/////////////////////////
// Author: Peichen Guo //
//    RIOS Lab work    //
//      HeHe Core      //
/////////////////////////
#include "Vlsuv1.h"

#include <iostream>
#include <string> 
#include <verilated.h>
#include "verilated_vcd_c.h"
#include <queue> 
#include <stdio.h>

#include "include.hpp"

// const uint64_t MAX_TIME = 30000000;
const uint64_t MAX_TIME = 4000000000;
const uint64_t RANDOM_TEST_NUM = 10000000;
const uint32_t RST_TIME = 100;


uint64_t main_time = 0;
Vlsuv1* lsuv1;

double sc_time_stamp(){
    return main_time;
}

void reset(){

    // <> rcu
    lsuv1->rcu_lsu_vld_i = 0;
    lsuv1->rcu_lsu_ls_i = 0;
    lsuv1->rcu_lsu_ld_opcode_i = 0;
    lsuv1->rcu_lsu_st_opcode_i = 0;
    lsuv1->rcu_lsu_fenced_i = 0;
    lsuv1->rcu_agu_virt_base_i = 0;
    lsuv1->rcu_agu_virt_offset_i = 0;
    lsuv1->rcu_lsu_rob_index_i = 0;
    lsuv1->rcu_lsu_rd_addr_i = 0;
    lsuv1->rcu_lsu_data_i = 0;
    lsuv1->rcu_lsu_wakeup_i = 0;
    lsuv1->rcu_lsu_wakeup_rob_index_i = 0;

    // <> dtlb
    lsuv1->dtlb_lsu_rdy_i = 0;
    lsuv1->dtlb_lsu_vld_i = 0;
    lsuv1->dtlb_lsu_hit_i = 0;
    lsuv1->dtlb_lsu_ptag_i = 0;
    lsuv1->dtlb_lsu_exception_vld_i = 0;
    lsuv1->dtlb_lsu_ecause_i = 0;

    // <> l1d
    lsuv1->l1d_lsu_ld_req_rdy_i = 0;
    lsuv1->l1d_lsu_st_req_rdy_i = 0;

    lsuv1->l1d_lsu_ld_replay_vld_i = 0;

    lsuv1->l1d_lsu_wb_vld_i = 0;
    lsuv1->l1d_lsu_wb_rob_index_i = 0;

    lsuv1->l1d_lsu_prf_wb_vld_i = 0;
    lsuv1->l1d_lsu_prf_wb_rd_addr_i = 0;
    lsuv1->l1d_lsu_prf_wb_data_i[0] = 0;
    lsuv1->l1d_lsu_prf_wb_data_i[1] = 0;
    // <> bus
    lsuv1->wb_lsu_ack_i = 0;
    lsuv1->wb_lsu_dat_i = 0;
    return;
}
int main(int argc, char ** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC();

    lsuv1 = new Vlsuv1("lsuv1");
    lsuv1->trace(tfp, 0);
    tfp->open("lsuv1.vcd");

    lsuv1->clk = 0;
    lsuv1->rst = 1;
    lsuv1->flush = 0;

    reset();

    FakeMemory* correct_mem = new FakeMemory();
    FakeMemory* real_mem = new FakeMemory();
    FakeBus* bus = new FakeBus(real_mem);
    FakeL1DCache* cache = new FakeL1DCache(real_mem);
    FakeTLB* tlb = new FakeTLB();
    FakeRCU* rcu = new FakeRCU();
    Monitor* monitor = new Monitor(real_mem, correct_mem, RANDOM_TEST_NUM);
    init_log();
    try {
        // printf("test starts\n");
        while(!monitor->ut_done() && main_time < MAX_TIME){
            sync_time(main_time);
            if(main_time % 10 == 0){
                lsuv1->clk = 1;
            }
            else if(main_time % 10 == 5){
                lsuv1->clk = 0;
            }
            
            if(main_time > RST_TIME){
                lsuv1->rst = 0;
                // monitor
                rcu->new_req_vld(monitor->req_vld());
                rcu->new_req(monitor->req());
                monitor->resp_vld(rcu->commit_vld());
                monitor->resp(rcu->commit());
                monitor->rcu_ready(rcu->rcu_rdy());
                monitor->lsu_head(lsuv1->lsu_debug_head_o);
                monitor->lsu_tail(lsuv1->lsu_debug_tail_o);
                monitor->lsu_iss_vld(lsuv1->lsu_debug_iss_vld_o);
                monitor->lsu_iss_is_fenced(lsuv1->lsu_debug_iss_is_fenced_o);
                monitor->lsu_iss_lsq_index(lsuv1->lsu_debug_iss_lsq_index_o);

                // <> rcu
                rcu->lsu_rdy(lsuv1->lsu_rdy_o);
                // if(lsuv1->lsu_rdy_o)
                //     printf("lsu rdy: %d\n", main_time);
                lsuv1->rcu_lsu_vld_i = rcu->req_vld();
                // if(rcu->req_vld())
                //     printf("rcu req vld: %d\n", main_time);
                lsuv1->rcu_lsu_ls_i = rcu->req().load_or_store;
                lsuv1->rcu_lsu_ld_opcode_i = rcu->req().opcode;
                lsuv1->rcu_lsu_st_opcode_i = rcu->req().opcode;
                lsuv1->rcu_lsu_fenced_i = rcu->req().is_fenced; // * fence has not been implemented yet
                lsuv1->rcu_agu_virt_base_i = rcu->req().paddr;
                lsuv1->rcu_agu_virt_offset_i = 0; // ! does not check agu
                lsuv1->rcu_lsu_rob_index_i = rcu->req().rob_index;
                lsuv1->rcu_lsu_rd_addr_i = rcu->req().rd_addr;
                lsuv1->rcu_lsu_data_i = rcu->req().data;
                lsuv1->rcu_lsu_wakeup_i = rcu->wakeup_vld();
                lsuv1->rcu_lsu_wakeup_rob_index_i = rcu->wakeup_rob_index();
                // if(lsuv1->lsu_prf_wb_vld_o)
                //     printf("wb!\n");

                rcu->resp_vld(lsuv1->lsu_rcu_comm_vld_o);
                rcu->resp(CacheLine(
                    0,
                    lsuv1->lsu_rcu_comm_data_o,
                    lsuv1->lsu_rcu_comm_rob_index_o,
                    lsuv1->lsu_rcu_comm_rd_addr_o,
                    0,
                    0, 
                    (lsuv1->lsu_rcu_comm_rd_addr_o == 0) ? 1 : 0,
                    0
                ));

                // <> tlb
                lsuv1->dtlb_lsu_rdy_i = 1;
                lsuv1->dtlb_lsu_vld_i = tlb->resp_vld();
                lsuv1->dtlb_lsu_hit_i = tlb->resp();
                // cache->dtlb_resp_vld(tlb->resp_vld());
                // cache->dtlb_resp(tlb->resp());
                lsuv1->dtlb_lsu_ptag_i = tlb->ptag();
                tlb->req(lsuv1->lsu_dtlb_iss_vld_o, lsuv1->lsu_dtlb_iss_vtag_o);

                // <> l1d
                lsuv1->l1d_lsu_ld_req_rdy_i = cache->ready();      
                lsuv1->l1d_lsu_st_req_rdy_i = cache->ready();
                cache->req_vld(lsuv1->lsu_l1d_ld_req_vld_o | lsuv1->lsu_l1d_st_req_vld_o);
                if(lsuv1->lsu_l1d_st_req_vld_o){ // store
                    // if(lsuv1->lsu_l1d_ld_req_vld_o | lsuv1->lsu_l1d_st_req_vld_o)
                    //     printf("enque store\n");
                    cache->req(
                        0,
                        0,
                        0,
                        lsuv1->lsu_l1d_st_req_paddr_o,
                        lsuv1->lsu_l1d_st_req_data_o,
                        lsuv1->lsu_l1d_st_req_rob_index_o,
                        lsuv1->lsu_l1d_st_req_rd_addr_o,
                        0,
                        lsuv1->lsu_l1d_st_req_is_fence_o,
                        1,
                        lsuv1->lsu_l1d_st_req_opcode_o
                    );
                }else if(lsuv1->lsu_l1d_ld_req_vld_o){
                    // if(lsuv1->lsu_l1d_ld_req_vld_o | lsuv1->lsu_l1d_st_req_vld_o)
                    //     printf("enque load\n");
                    cache->req(
                        lsuv1->lsu_l1d_ld_req_index_o,
                        lsuv1->lsu_l1d_ld_req_offset_o,
                        lsuv1->lsu_l1d_ld_req_vtag_o,
                        0,
                        0,
                        lsuv1->lsu_l1d_ld_req_rob_index_o,
                        lsuv1->lsu_l1d_ld_req_rd_addr_o,
                        0,
                        0,
                        0,
                        lsuv1->lsu_l1d_ld_req_opcode_o
                    );
                }
                lsuv1->l1d_lsu_ld_replay_vld_i = 0; // ! do not test on replau. fix it later!
                // if(cache->resp_vld())
                //     printf("resp vld\n");
                // ld low, st high
                lsuv1->l1d_lsu_wb_vld_i = (cache->st_resp_vld() << 2) + cache->ld_resp_vld();
                lsuv1->l1d_lsu_wb_rob_index_i = ((cache->st_resp().rob_index) << (ROB_SIZE_WIDTH * 2)) + cache->ld_resp().rob_index;

                lsuv1->l1d_lsu_prf_wb_vld_i = cache->ld_resp_vld();
                lsuv1->l1d_lsu_prf_wb_rd_addr_i = cache->ld_resp().rd_addr;
                lsuv1->l1d_lsu_prf_wb_data_i[0] = cache->ld_resp().data;
                lsuv1->l1d_lsu_prf_wb_data_i[1] = cache->ld_resp().data >> 32;
                cache->kill_req((lsuv1->lsu_debug_l1d_s1_kill_o) != 0 || (lsuv1->lsu_debug_dtlb_miss_kill_o != 0));
                
                // <> BUS
                bus->req_vld(lsuv1->lsu_wb_cyc_o);
                bus->req(
                    lsuv1->lsu_wb_adr_o,
                    lsuv1->lsu_wb_dat_o,
                    0,
                    0,
                    0,
                    0,
                    lsuv1->lsu_wb_we_o,
                    lsuv1->lsu_wb_sel_o
                );
                lsuv1->wb_lsu_ack_i = bus->resp_vld();
                lsuv1->wb_lsu_dat_i = bus->resp().data;
            } 
            
            if(main_time % 10 == 0 && main_time > RST_TIME){
                monitor->eval();
                rcu->eval();
                tlb->eval();
                cache->eval();
                bus->eval();
            }
            lsuv1->eval();
            tfp->dump(main_time);
            main_time ++;
        }
    }
    catch(const char* msg){
        // tfp->dump(main_time);
        tfp->close();
        // bool mem_same = lsu_mem->final_check(correct_mem);
        delete monitor;
        delete rcu;
        delete tlb;
        delete cache;
        delete bus;
        delete lsuv1;
        delete correct_mem;
        delete real_mem;
        delete tfp;
        close_log();
        printf("\n lsu_dcache test fail\n\n");
        std::cerr << msg << std::endl;
    }
    tfp->dump(main_time);
    tfp->close();
    bool mem_correct = monitor->mem_check();
    delete monitor;
    delete rcu;
    delete tlb;
    delete cache;
    delete bus;
    delete lsuv1;
    delete correct_mem;
    delete real_mem;
    delete tfp;
    close_log();
    assert(main_time != MAX_TIME);
    assert(mem_correct);
    printf("\n lsu_dcache test done\n\n");
    exit(0);
}