/////////////////////////
// Author: Peichen Guo //
//    RIOS Lab work    //
//      HeHe Core      //
/////////////////////////
#include "Vl1d_top.h"

#include <iostream>
#include <string> 
#include <verilated.h>
#include "verilated_vcd_c.h"
#include <queue> 
#include <stdio.h>

#include "include.hpp"

// const uint64_t MAX_TIME = 30000000;
const uint64_t MAX_TIME = 1000000000;
const uint64_t RANDOM_TEST_NUM = 100000;
const uint32_t RST_TIME = 100;


uint64_t main_time = 0;
uint64_t pass_case = 0;
Vl1d_top* l1d;

double sc_time_stamp(){
    return main_time;
}

void reset(){
    l1d->clk = 0;
    l1d->rst = 1;
    l1d->flush = 0;
    l1d->lsu_rcu_rdy_o = 0;
    l1d->rcu_lsu_vld_i = 0;
    l1d->rcu_lsu_ls_i = 0;
    l1d->rcu_lsu_ld_opcode_i = 0;
    l1d->rcu_lsu_st_opcode_i = 0;
    l1d->rcu_lsu_fenced_i = 0;
    l1d->rcu_lsu_virt_base_i = 0;
    l1d->rcu_lsu_virt_offset_i = 0;
    l1d->rcu_lsu_rob_index_i = 0;
    l1d->rcu_lsu_rd_addr_i = 0;
    l1d->rcu_lsu_data_i = 0;
    l1d->rcu_lsu_wakeup_vld_i = 0;
    l1d->rcu_lsu_wakeup_rob_index_i = 0;
    // l1d->lsu_rcu_comm_vld_o = 0;
    // l1d->lsu_rcu_comm_rob_index_o = 0;
    // l1d->lsu_rcu_comm_rd_addr_o = 0;
    // l1d->lsu_rcu_comm_data_o = 0;
    // l1d->lsu_rcu_exception_vld_o = 0;
    // l1d->lsu_rcu_ecause_o = 0;

    // l1d->l1d_l2_req_arvalid_o = 0;
    l1d->l1d_l2_req_arready_i = 0;
    // l1d->l1d_l2_req_ar_o = 0;

    // l1d->l1d_l2_req_awvalid_o = 0;
    l1d->l1d_l2_req_awready_i = 0;
    // l1d->l1d_l2_req_aw_o = 0;

    // l1d->l1d_l2_req_wvalid_o = 0;
    l1d->l1d_l2_req_wready_i = 0;
    // l1d->l1d_l2_req_w_o = 0;

    l1d->l2_l1d_resp_bvalid_i = 0;
    // l1d->l2_l1d_resp_bready_o = 0;
    l1d->l2_l1d_resp_b_i = 0;

    l1d->l2_l1d_resp_rvalid_i = 0;
    // l1d->l2_l1d_resp_rready_o = 0;
    l1d->l2_l1d_resp_r_i[0] = 0;
    l1d->l2_l1d_resp_r_i[1] = 0;
    l1d->l2_l1d_resp_r_i[2] = 0;
   
    return;
}

int main(int argc, char ** argv, char** env) {
    VerilatedContext* contextp;
    contextp = new VerilatedContext;

    l1d = new Vl1d_top(contextp);

    Verilated::commandArgs(argc, argv);
    
    VerilatedVcdC* tfp = new VerilatedVcdC;

    contextp->traceEverOn(true); 
    l1d->trace(tfp, 50);
    tfp->open(WAVE_PATH.c_str());

    reset();

    l1d->clk = 0;
    l1d->rst = 1;

    l1d->flush = 0;

    FakeMemory* real_mem = nullptr;
    FakeMemory* perfect_mem = nullptr;
    Monitor* monitor = nullptr;
    FakeRCU* rcu = nullptr;
    // printf("1\n");
    try{
        real_mem = new FakeMemory(PAGETABLE_PATH);
        perfect_mem = new FakeMemory(PAGETABLE_PATH);
        monitor = new Monitor(real_mem, perfect_mem, RANDOM_TEST_NUM);
        rcu = new FakeRCU();
        init_log();
    }
    catch (const char* msg){
        std::cout << msg << std::endl;
        delete tfp;
        if(real_mem != nullptr)
            delete real_mem;
        if(perfect_mem != nullptr)
            delete perfect_mem;
        if(monitor != nullptr)
            delete monitor;
        if(rcu != nullptr)
            delete rcu;
        LOG.close();
    }
    

    // printf("2\n");
    // printf("3\n");
    try {
        while(!monitor->ut_done() && contextp->time() < MAX_TIME){
            sync_time(contextp->time());

            if(contextp->time() % 10 == 0){
                // printf("clk = 1");
                l1d->clk = 1;
            }
            else if(contextp->time() % 10 == 5){
                // printf("clk = 0");
                l1d->clk = 0;
            }
            
            if(contextp->time() > RST_TIME){
                l1d->rst = 0;
                // monitor
                rcu->new_req_vld(monitor->req_vld());
                rcu->new_req(monitor->req());
                monitor->resp_vld(rcu->commit_vld());
                monitor->resp(rcu->commit());
                monitor->rcu_ready(rcu->rcu_rdy());

                // <> rcu
                rcu->lsu_rdy(l1d->lsu_rcu_rdy_o);

                l1d->rcu_lsu_vld_i = rcu->req_vld();
                l1d->rcu_lsu_ls_i = rcu->req().load_or_store;
                l1d->rcu_lsu_ld_opcode_i = rcu->req().opcode;
                l1d->rcu_lsu_st_opcode_i = rcu->req().opcode;
                l1d->rcu_lsu_fenced_i = 0; // * fence has not been implemented yet
                l1d->rcu_lsu_virt_base_i = rcu->req().paddr;
                l1d->rcu_lsu_virt_offset_i = 0; // ! does not check agu
                l1d->rcu_lsu_rob_index_i = rcu->req().rob_index;
                l1d->rcu_lsu_rd_addr_i = rcu->req().rd_addr;
                l1d->rcu_lsu_data_i = rcu->req().data;
                l1d->rcu_lsu_wakeup_vld_i = rcu->wakeup_vld();
                l1d->rcu_lsu_wakeup_rob_index_i = rcu->wakeup_rob_index();
                // if(l1d->lsu_prf_wb_vld_o)
                //     printf("wb!\n");

                // printf("6\n");
                rcu->resp_vld(l1d->lsu_rcu_comm_vld_o);
                // printf("6.1\n");
                rcu->resp(Req(
                    0,
                    l1d->lsu_rcu_comm_data_o,
                    l1d->lsu_rcu_comm_rob_index_o,
                    l1d->lsu_rcu_comm_rd_addr_o,
                    0,
                    0, 
                    (l1d->lsu_rcu_comm_rd_addr_o == 0) ? 1 : 0,
                    0
                ));
                /*
                typedef struct packed {
                    mem_tid_t awid;
                    logic [PADDR_WIDTH-1:0]  awaddr;
                    logic [7 : 0] awlen; // 8
                    
                    logic [2 : 0] awsize; // 3
                    logic [1 : 0] awburst; // 2
                    
                } cache_mem_if_aw_t;
                */
                real_mem->aw_vld(l1d->l1d_l2_req_awvalid_o);
                l1d->l1d_l2_req_awready_i = 1;
                axi_aw_req aw;
                aw.awaddr = uint64_t(   
                                        (uint64_t(l1d->l1d_l2_req_aw_o[2]) << (64 - 13)) + 
                                        (uint64_t(l1d->l1d_l2_req_aw_o[1]) << (32 - 13)) + 
                                        (uint64_t(l1d->l1d_l2_req_aw_o[0]) >> 13)
                                    ) & 0xffffffffffffff;// 56
                real_mem->aw_req(aw);

                /*
                typedef struct packed {
                    logic [MEM_DATA_WIDTH-1:0]  wdata;
                    logic wlast; // 1
                    mem_tid_t wid; // 8
                } cache_mem_if_w_t;
                */
                real_mem->w_vld(l1d->l1d_l2_req_wvalid_o);
                l1d->l1d_l2_req_wready_i = 1;
                axi_w_req w;
                w.wdata = uint64_t(
                            (uint64_t(l1d->l1d_l2_req_w_o[2]) << (64 - 9)) + 
                            (uint64_t(l1d->l1d_l2_req_w_o[1]) << (32 - 9)) + 
                            (uint64_t(l1d->l1d_l2_req_w_o[0]) >> 9)
                    );
                real_mem->w_req(w);

                /*
                typedef struct packed {
                    mem_tid_t arid;
                    logic [7  : 0] arlen; // 7
                    
                    logic [2 : 0] arsize; // 3
                    logic [1 : 0] arburst; // 2
                    
                    logic [PADDR_WIDTH-1:0]  araddr; // 56
                } cache_mem_if_ar_t;
                */
                real_mem->ar_vld(l1d->l1d_l2_req_arvalid_o);
                l1d->l1d_l2_req_arready_i = 1;
                axi_ar_req  ar;
                ar.araddr = (((uint64_t(l1d->l1d_l2_req_ar_o[1]) << 32) + uint64_t(l1d->l1d_l2_req_ar_o[0])) & 0xffffffffffffff); // 56
                // if(l1d->l1d_l2_req_arvalid_o){
                //     printf("ar req:%x %x %x -> %lx\n", l1d->l1d_l2_req_ar_o[2], l1d->l1d_l2_req_ar_o[1], l1d->l1d_l2_req_ar_o[0], ar.araddr);
                // }
                ar.arid = l1d->l1d_l2_req_ar_o[2] >> 5;
                real_mem->ar_req(ar);

                /*
                typedef struct packed {
                    mem_tid_t                        rid; // 
                    logic [MEM_DATA_WIDTH-1:0]       dat; // 64 
                    logic                            err; // 1
                    rrv64_mesi_type_e                mesi_sta; // 2
                    // logic [RRV64_SCU_SST_IDX_W-1:0]  sst_idx;
                    axi4_resp_t rresp; // 2
                    logic rlast;  // 1
                //    logic                            l2_hit;
                } cache_mem_if_r_t;
                */
               l1d->l2_l1d_resp_rvalid_i = real_mem->r_vld();
               real_mem->r_rdy(l1d->l2_l1d_resp_rready_o);
               axi_r_resp r = real_mem->r_resp();
               l1d->l2_l1d_resp_r_i[0] = uint32_t(((r.rdata << 6)) + r.rlast);
               l1d->l2_l1d_resp_r_i[1] = uint32_t(r.rdata >> 26); // 32 - 6
               l1d->l2_l1d_resp_r_i[2] = uint32_t((r.rid << 6) + (r.rdata >> 58)); // 32 + 26
               /*
                typedef struct packed {
                    mem_tid_t bid;
                    axi4_resp_t bresp; // 2
                } cache_mem_if_b_t;
                */
               l1d->l2_l1d_resp_bvalid_i = real_mem->b_vld();
               real_mem->b_rdy(l1d->l2_l1d_resp_bready_o);
               l1d->l2_l1d_resp_b_i = real_mem->b_resp().bid << 2;
            } 
            
            if((contextp->time() % 10 == 0) && contextp->time() > RST_TIME){
                // printf("6.3\n");
                monitor->eval();
                // printf("6.4\n");
                rcu->eval();
                // printf("6.5\n");
                real_mem->eval();
                // printf("6.6\n");
                perfect_mem->eval();
            }



            // printf("7\n");
            l1d->eval();
            tfp->dump(contextp->time());
            contextp->timeInc(1);
            // printf("8\n");
        }
    }
    catch(const char* msg){
        std::cout << msg << std::endl;
#ifdef LOG_ENABLE
        LOG << "=======================" << std::endl;
        LOG << "t " << std::dec << TIME << ": test failed" << std::endl;
        LOG << msg << std::endl;
        LOG << "=======================" << std::endl;
        LOG << std::endl;
#endif // LOG_ENABLE
        tfp->dump(contextp->time());
        tfp->close();
        delete tfp;
        if(real_mem != nullptr)
            delete real_mem;
        if(perfect_mem != nullptr)
            delete perfect_mem;
        if(monitor != nullptr)
            delete monitor;
        if(rcu != nullptr)
            delete rcu;
        LOG.close();
    }
    tfp->dump(contextp->time());
    tfp->close();

    delete tfp;
    if(real_mem != nullptr)
        delete real_mem;
    if(perfect_mem != nullptr)
        delete perfect_mem;
    if(monitor != nullptr)
        delete monitor;
    if(rcu != nullptr)
        delete rcu;
    close_log();
    if(monitor->ut_done())
        std::cout << "\n====== test done ======\n" << std::endl;
    else{
        std::cout << "\n====== test fail ======\n" << std::endl;
    }
    exit(0);
}