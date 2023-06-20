#include "Vrvh_mmu.h"

#include <iostream>
#include <verilated.h>


const uint64_t MAX_TIME = 150;


uint64_t main_time = 0;
Vrvh_mmu* rvh_mmu;
void init_module(Vrvh_mmu* rvh_mmu);
double sc_time_stamp(){
    return main_time;
}

int main(int argc, char ** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    
    rvh_mmu = new Vrvh_mmu;
    rvh_mmu->clk                            = 0;
    rvh_mmu->rstn                           = 0;
    init_module(rvh_mmu);
    


    while(main_time < MAX_TIME){
        if(main_time > 10) {
            rvh_mmu->rstn = 1;
        }
        if((main_time % 10) == 1) {
            rvh_mmu->clk = 1;
        }
        if((main_time % 10) == 6){
            rvh_mmu->clk = 0;
        }

        // test 0

        // Get tlb req
        // Access root pte with satp_ppn
        if(main_time == 20){


            rvh_mmu->dtlb_miss_req_vld_i            = 1;
            rvh_mmu->dtlb_miss_req_trans_id_i       = 0;
            // 59:44
            rvh_mmu->dtlb_miss_req_asid_i           = 0x0001;
            rvh_mmu->dtlb_miss_req_vpn_i            = 0x0080001;
            rvh_mmu->dtlb_miss_req_access_type_i    = 0;


            rvh_mmu->ptw_walk_req_rdy_i = 1;
        }

        if(main_time == 25){
            init_module(rvh_mmu);
        }

        // root pte returns Lv1 ppn
        if(main_time == 30){
            rvh_mmu->ptw_walk_resp_vld_i            = 1;
            rvh_mmu->ptw_walk_resp_pte_i            = 0x003f00ff00ff0031;

            rvh_mmu->ptw_walk_req_rdy_i             = 1;
        }
        if(main_time == 35){
            init_module(rvh_mmu);
        }

        // Lv1 pte returns Lv0 ppn
        if(main_time == 40){
            rvh_mmu->ptw_walk_resp_vld_i            = 1;
            rvh_mmu->ptw_walk_resp_pte_i            = 0x0030000000ff0031;

            rvh_mmu->ptw_walk_req_rdy_i             = 1;
        }
        if(main_time == 45){
            init_module(rvh_mmu);
        }

        // Lv0 pte returns paddr
        if(main_time == 50){
            rvh_mmu->ptw_walk_resp_vld_i            = 1;
            rvh_mmu->ptw_walk_resp_pte_i            = 0x003ffffffffff63f;

            rvh_mmu->ptw_walk_req_rdy_i             = 1;
        }
        if(main_time == 55){
            init_module(rvh_mmu);
        }

        // test 1: invalid pte
        // V = 1

        // Get tlb req
        // Access root pte with satp_ppn
        if(main_time == 70){
            rvh_mmu->dtlb_miss_req_vld_i            = 1;
            rvh_mmu->dtlb_miss_req_asid_i           = 0x0001;
            rvh_mmu->dtlb_miss_req_vpn_i            = 0x0080001;
            rvh_mmu->ptw_walk_req_rdy_i = 1;
        }

        if(main_time == 75){
            init_module(rvh_mmu);
        }

        // root pte returns Lv1 ppn
        if(main_time == 80){
            rvh_mmu->ptw_walk_resp_vld_i            = 1;
            rvh_mmu->ptw_walk_resp_pte_i            = 0x003f00ff00ff0030;

            rvh_mmu->ptw_walk_req_rdy_i             = 1;
        }
        if(main_time == 81){
            assert(rvh_mmu->dtlb_miss_resp_vld_o == 1);
            assert(rvh_mmu->dtlb_miss_resp_page_fault_o == 1);
        }
        if(main_time == 85){
            init_module(rvh_mmu);
        }


        // test 2: invalid pte
        // R = 0 and W = 1

        // Get tlb req
        // Access root pte with satp_ppn
        if(main_time == 100){
            rvh_mmu->dtlb_miss_req_vld_i            = 1;
            rvh_mmu->dtlb_miss_req_asid_i           = 0x0001;
            rvh_mmu->dtlb_miss_req_vpn_i            = 0x0080001;
            rvh_mmu->ptw_walk_req_rdy_i = 1;
        }

        if(main_time == 105){
            init_module(rvh_mmu);
        }

        // root pte returns Lv1 ppn
        if(main_time == 110){
            rvh_mmu->ptw_walk_resp_vld_i            = 1;
            rvh_mmu->ptw_walk_resp_pte_i            = 0x003f00ff00ff0035;

            rvh_mmu->ptw_walk_req_rdy_i             = 1;
        }
        if(main_time == 111){
            // assert(rvh_mmu->dtlb_miss_resp_vld_o == 1);
            // assert(rvh_mmu->dtlb_miss_resp_page_fault_o == 1);
        }
        if(main_time == 115){
            init_module(rvh_mmu);
        }

        
        rvh_mmu->eval();

        if(20 <= main_time && main_time % 10 == 0){
            std::cout << "tik: "  <<  (main_time - 20) / 10 << std::endl;
        }
        main_time ++;
    }
    rvh_mmu->final();
    delete rvh_mmu;
    exit(0);
}

void init_module(Vrvh_mmu* rvh_mmu)
{
    // @fixme: verify
    // priv lvl
    rvh_mmu->priv_lvl_i                     = 3;
    // PMP Configuration Port
    rvh_mmu->pmp_cfg_set_vld_i              = 0;
    rvh_mmu->pmp_cfg_set_addr_i             = 0;
    rvh_mmu->pmp_cfg_set_payload_i          = 0;
    rvh_mmu->pmp_addr_set_vld_i             = 0;
    rvh_mmu->pmp_addr_set_addr_i            = 0;
    rvh_mmu->pmp_addr_set_payload_i         = 0;
    // stap
    rvh_mmu->satp_mode_i                    = 8;
    rvh_mmu->satp_ppn_i                     = 0x3fffff;
    // DTLB Miss -> To Next Level Request
    rvh_mmu->dtlb_miss_req_vld_i            = 0;
    rvh_mmu->dtlb_miss_req_trans_id_i       = 0;
    rvh_mmu->dtlb_miss_req_asid_i           = 0;
    rvh_mmu->dtlb_miss_req_vpn_i            = 0;
    rvh_mmu->dtlb_miss_req_access_type_i    = 0;
    // DTLB Miss -> From Next Level Response
    // // DTLB Entry Evict
    // rvh_mmu->dtlb_evict_vld_i               = 0;
    // rvh_mmu->dtlb_evict_pte_i               = 0;
    // rvh_mmu->dtlb_evict_page_lvl_i          = 0;
    // rvh_mmu->dtlb_evict_vpn_i               = 0;
    // rvh_mmu->dtlb_evict_asid_i              = 0;
    // ITLB Miss -> To Next Level Request
    rvh_mmu->itlb_miss_req_vld_i            = 0;
    rvh_mmu->itlb_miss_req_trans_id_i       = 0;
    rvh_mmu->itlb_miss_req_asid_i           = 0;
    rvh_mmu->itlb_miss_req_vpn_i            = 0;
    rvh_mmu->itlb_miss_req_access_type_i    = 0;
    // ITLB Miss -> From Next Level Response
    // // ITLB Entry Evict
    // rvh_mmu->itlb_evict_vld_i               = 0;
    // rvh_mmu->itlb_evict_pte_i               = 0;
    // rvh_mmu->itlb_evict_page_lvl_i          = 0;
    // rvh_mmu->itlb_evict_vpn_i               = 0;
    // rvh_mmu->itlb_evict_asid_i              = 0;
    // ptw walk request port
    rvh_mmu->ptw_walk_req_rdy_i             = 0;
    // ptw walk response port
    rvh_mmu->ptw_walk_resp_vld_i            = 0;
    // rvh_mmu->ptw_walk_resp_id_i             = 0;
    rvh_mmu->ptw_walk_resp_pte_i            = 0;
    // tlb shoot down
    rvh_mmu->tlb_flush_vld_i                = 0;
    rvh_mmu->tlb_flush_use_asid_i           = 0;
    rvh_mmu->tlb_flush_use_vpn_i            = 0;
    rvh_mmu->tlb_flush_vpn_i                = 0;
    rvh_mmu->tlb_flush_asid_i               = 0;


    /* 
    Output
    // priv lvl
    // PMP Configuration Port
    output [63:0] pmp_cfg_origin_payload_o,
    output [63:0] pmp_addr_origin_payload_o,
    // stap
    // DTLB Miss -> To Next Level Request
    output dtlb_miss_req_rdy_o,
    // DTLB Miss -> From Next Level Response
    output dtlb_miss_resp_vld_o,
    output [TRANS_ID_WIDTH-1:0] dtlb_miss_resp_trans_id_o,
    output [ASID_WIDTH-1:0] dtlb_miss_resp_asid_o,
    output [PTE_WIDTH-1:0] dtlb_miss_resp_pte_o,
    output [PAGE_LVL_WIDTH-1:0] dtlb_miss_resp_page_lvl_o,
    output [VPN_WIDTH-1:0] dtlb_miss_resp_vpn_o,
    output [1:0] dtlb_miss_resp_access_type_o,
    output dtlb_miss_resp_access_fault_o,
    output dtlb_miss_resp_page_fault_o,
    // DTLB Entry Evict
    // ITLB Miss -> To Next Level Request
    output itlb_miss_req_rdy_o,
    // ITLB Miss -> From Next Level Response
    output itlb_miss_resp_vld_o,
    output [TRANS_ID_WIDTH-1:0] itlb_miss_resp_trans_id_o,
    output [ASID_WIDTH-1:0] itlb_miss_resp_asid_o,
    output [PTE_WIDTH-1:0] itlb_miss_resp_pte_o,
    output [PAGE_LVL_WIDTH-1:0] itlb_miss_resp_page_lvl_o,
    output [VPN_WIDTH-1:0] itlb_miss_resp_vpn_o,
    output [1:0] itlb_miss_resp_access_type_o,
    output itlb_miss_resp_access_fault_o,
    output itlb_miss_resp_page_fault_o,
    // ITLB Entry Evict
    // ptw walk request port
    output ptw_walk_req_vld_o,
    output [PTW_ID_WIDTH-1:0] ptw_walk_req_id_o,
    output [PADDR_WIDTH-1:0] ptw_walk_req_addr_o,
    // ptw walk response port
    output ptw_walk_resp_rdy_o,
    // tlb shoot down
    output tlb_flush_grant_o,
    */


    
    return;

}