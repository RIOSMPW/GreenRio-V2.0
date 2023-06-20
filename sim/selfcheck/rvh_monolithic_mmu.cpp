#include "Vrvh_monolithic_mmu.h"

#include <iostream>
#include <verilated.h>


const uint64_t MAX_TIME = 500;


uint64_t main_time = 0;
Vrvh_monolithic_mmu* rvh_monolithic_mmu;
void init_module(Vrvh_monolithic_mmu* m);

double sc_time_stamp(){
    return main_time;
}

int main(int argc, char ** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    rvh_monolithic_mmu = new Vrvh_monolithic_mmu;
    
    // VerilatedVcdC* tfp
    init_module(rvh_monolithic_mmu);
    while(main_time < MAX_TIME){
        if(main_time > 10) {
            rvh_monolithic_mmu->rstn = 1;
        }
        if((main_time % 10) == 1) {
            rvh_monolithic_mmu->clk = 1;
        }
        if((main_time % 10) == 6){
            rvh_monolithic_mmu->clk = 0;
        }

        // config PMP
        if(main_time == 20){
            rvh_monolithic_mmu->pmp_cfg_set_vld_i = 1;
            rvh_monolithic_mmu->pmp_cfg_set_addr_i = 0;
            rvh_monolithic_mmu->pmp_cfg_set_payload_i = 0b000011110000111100001111;
            rvh_monolithic_mmu->pmp_addr_set_vld_i = 1;
            rvh_monolithic_mmu->pmp_addr_set_addr_i = 0;
            rvh_monolithic_mmu->pmp_addr_set_payload_i = 0x7fff0000123000;
        }
        if(main_time == 25){
            rvh_monolithic_mmu->pmp_cfg_set_vld_i = 0;
            rvh_monolithic_mmu->pmp_cfg_set_addr_i = 0;
            rvh_monolithic_mmu->pmp_cfg_set_payload_i = 0;
        }
        if(main_time == 30){
            rvh_monolithic_mmu->pmp_addr_set_vld_i = 1;
            rvh_monolithic_mmu->pmp_addr_set_addr_i = 1;
            rvh_monolithic_mmu->pmp_addr_set_payload_i = 0x7fff0000321000;
        }

        if(main_time == 40){
            rvh_monolithic_mmu->pmp_addr_set_vld_i = 1;
            rvh_monolithic_mmu->pmp_addr_set_addr_i = 2;
            rvh_monolithic_mmu->pmp_addr_set_payload_i = 0x7fffffffffffff;
        }
        if(main_time == 45){
            rvh_monolithic_mmu->pmp_addr_set_vld_i = 0;
            rvh_monolithic_mmu->pmp_addr_set_addr_i = 0;
            rvh_monolithic_mmu->pmp_addr_set_payload_i = 0;
        }

        // // test 1: M-mode - skip
        // if(main_time == 40){
        //     rvh_monolithic_mmu->dtlb_translate_req_vld_i = 1;
        //     rvh_monolithic_mmu->dtlb_translate_req_access_type_i = 0;
        //     rvh_monolithic_mmu->dtlb_translate_req_vpn_i = 0x80001000 >> 12;
        // }
        // if(main_time == 45){
        //     rvh_monolithic_mmu->dtlb_translate_req_vld_i = 0;
        //     rvh_monolithic_mmu->dtlb_translate_req_vpn_i = 0;
        // }

        // test 2: S-mode - miss
        // Note: LSU will replay missed requests
        // 2-0: get lv2 page table through satp_ppn
        if(main_time == 50){
            rvh_monolithic_mmu->priv_lvl_i = 1;
            rvh_monolithic_mmu->dtlb_translate_req_vld_i = 1;
            rvh_monolithic_mmu->dtlb_translate_req_access_type_i = 0;
            rvh_monolithic_mmu->dtlb_translate_req_vpn_i = 0x80111000 >> 12;
            
            rvh_monolithic_mmu->ptw_walk_req_rdy_i = 1;
        }

        // // test 3: Busy 
        // if(main_time == 60){
        //     rvh_monolithic_mmu->dtlb_translate_req_vld_i = 1;
        //     rvh_monolithic_mmu->dtlb_translate_req_access_type_i = 0;
        //     rvh_monolithic_mmu->dtlb_translate_req_vpn_i = 0x80222000 >> 12;            
        // }
        // if(main_time == 70){
        //     rvh_monolithic_mmu->itlb_translate_req_vld_i = 1;
        //     rvh_monolithic_mmu->itlb_translate_req_vpn_i = 0x80333000 >> 12;            
        // }
        // if(main_time == 80){
        //     rvh_monolithic_mmu->dtlb_translate_req_vld_i = 1;
        //     rvh_monolithic_mmu->dtlb_translate_req_vpn_i = 0x80444000 >> 12;            
        // }



        // test 2: S-mode - miss
        // 2-1: get ppn of lv1 page table from lv2 pte 
        if(main_time == 90){
            rvh_monolithic_mmu->ptw_walk_resp_vld_i = 1;
            // 00DAGUXWRV
            rvh_monolithic_mmu->ptw_walk_resp_pte_i = ((0x7fff0000321000 >> 12) << 10) | 0b0000100001;
        }if(main_time == 95){
            rvh_monolithic_mmu->ptw_walk_resp_vld_i = 0;
            rvh_monolithic_mmu->ptw_walk_resp_pte_i = 0;
        }

        // test 2: S-mode - miss
        // 2-2: get ppn of lv0 page table from lv1 pte 
        if(main_time == 110){
            rvh_monolithic_mmu->ptw_walk_resp_vld_i = 1;
            rvh_monolithic_mmu->ptw_walk_resp_pte_i = ((0x7fff0000456000 >> 12) << 10) | 0b0000100001;
        }if(main_time == 115){
            rvh_monolithic_mmu->ptw_walk_resp_vld_i = 0;
            rvh_monolithic_mmu->ptw_walk_resp_pte_i = 0;
        }

        // test 2: S-mode - miss
        // 2-3: get lv0 pte 
        if(main_time == 130){
            rvh_monolithic_mmu->ptw_walk_resp_vld_i = 1;
            rvh_monolithic_mmu->ptw_walk_resp_pte_i = ((0x7fff0000654000 >> 12) << 10) | 0b0001101111;
        }if(main_time == 135){
            rvh_monolithic_mmu->ptw_walk_resp_vld_i = 0;
            rvh_monolithic_mmu->ptw_walk_resp_pte_i = 0;
        }

        // PPN returns at 140
        // LSU reset req before 150
        if(main_time == 145) {
            rvh_monolithic_mmu->dtlb_translate_req_vld_i = 0;
            rvh_monolithic_mmu->dtlb_translate_req_vpn_i = 0;
        }

        if(main_time == 190){
            rvh_monolithic_mmu->dtlb_translate_req_vld_i = 1;
            rvh_monolithic_mmu->dtlb_translate_req_access_type_i = 0;
            rvh_monolithic_mmu->dtlb_translate_req_vpn_i = 0x80111000 >> 12;
        }if(main_time == 195){
            rvh_monolithic_mmu->dtlb_translate_req_vld_i = 0;
            rvh_monolithic_mmu->dtlb_translate_req_vpn_i = 0;
        }

        if(main_time == 220){
            rvh_monolithic_mmu->dtlb_translate_req_vld_i = 1;
            rvh_monolithic_mmu->dtlb_translate_req_access_type_i = 0;
            rvh_monolithic_mmu->dtlb_translate_req_vpn_i = 0x80111000 >> 12;
        }if(main_time == 225){
            rvh_monolithic_mmu->dtlb_translate_req_vld_i = 0;
            rvh_monolithic_mmu->dtlb_translate_req_vpn_i = 0;
        }




               
        rvh_monolithic_mmu->eval();

        // if(20 <= main_time && main_time % 10 == 0){
        //     std::cout << "tik: "  <<  (main_time - 20) / 10 << std::endl;
        // }
        main_time ++;
    }
    rvh_monolithic_mmu->final();
    delete rvh_monolithic_mmu;
    exit(0);
}

void init_module(Vrvh_monolithic_mmu* m){
    
    // // priv lvl
    // input       [                 1:0] priv_lvl_i,
    m->priv_lvl_i = 3;
    // // stap
    // input       [                 3:0] satp_mode_i,
    m->satp_mode_i = 8;
    // input       [      ASID_WIDTH-1:0] satp_asid_i,
    m->satp_asid_i = 0x0001;
    // input       [       PPN_WIDTH-1:0] satp_ppn_i,
    m->satp_ppn_i = 0x7fff0000123;

    // input       [            XLEN-1:0] misc_mstatus_i,
    m->misc_mstatus_i = 0;

    // // PMP Configuration Port
    // input                              pmp_cfg_set_vld_i,
    m->pmp_cfg_set_vld_i = 0;
    // input       [ PMPCFG_ID_WIDTH-1:0] pmp_cfg_set_addr_i,
    m->pmp_cfg_set_addr_i = 0;
    // input       [                63:0] pmp_cfg_set_payload_i,
    m->pmp_cfg_set_payload_i = 0;
    // output      [                63:0] pmp_cfg_origin_payload_o,
    // input                              pmp_addr_set_vld_i,
    m->pmp_addr_set_vld_i = 0;
    // input       [PMPADDR_ID_WIDTH-1:0] pmp_addr_set_addr_i,
    m->pmp_addr_set_addr_i = 0;
    // input       [                63:0] pmp_addr_set_payload_i,
    m->pmp_addr_set_payload_i = 0;
    // output      [                63:0] pmp_addr_origin_payload_o, 




    // // DTLB Translate Port -> Request
    // input [TRANSLATE_WIDTH-1:0] dtlb_translate_req_vld_i,
    m->dtlb_translate_req_vld_i = 0;
    // input [TRANSLATE_WIDTH-1:0][1:0] dtlb_translate_req_access_type_i,
    m->dtlb_translate_req_access_type_i = 0;
    // input [TRANSLATE_WIDTH-1:0][VPN_WIDTH-1:0] dtlb_translate_req_vpn_i,
    m->dtlb_translate_req_vpn_i = 0;
    // output [TRANSLATE_WIDTH-1:0] dtlb_translate_req_rdy_o,
    // // DTLB Translate Port -> Response
    // output [TRANSLATE_WIDTH-1:0] dtlb_translate_resp_vld_o,
    // output [TRANSLATE_WIDTH-1:0][PPN_WIDTH-1:0] dtlb_translate_resp_ppn_o,
    // output [TRANSLATE_WIDTH-1:0] dtlb_translate_resp_excp_vld_o,
    // output [TRANSLATE_WIDTH-1:0][EXCP_CAUSE_WIDTH-1:0] dtlb_translate_resp_excp_cause_o,
    // output [TRANSLATE_WIDTH-1:0] dtlb_translate_resp_miss_o,
    // output [TRANSLATE_WIDTH-1:0] dtlb_translate_resp_hit_o,

    // // ITLB Translate Port -> Request
    // input [TRANSLATE_WIDTH-1:0] itlb_translate_req_vld_i,
    m->itlb_translate_req_vld_i = 0;
    // // MODE == Read(Execute)
    // // input [TRANSLATE_WIDTH-1:0][1:0] itlb_translate_req_access_type_i,
    // m->itlb_translate_req_access_type_i = 0;
    // input [TRANSLATE_WIDTH-1:0][VPN_WIDTH-1:0] itlb_translate_req_vpn_i,
    m->itlb_translate_req_vpn_i = 0;
    // output [TRANSLATE_WIDTH-1:0] itlb_translate_req_rdy_o,
    // // ITLB Translate Port -> Response
    // output [TRANSLATE_WIDTH-1:0] itlb_translate_resp_vld_o,
    // output [TRANSLATE_WIDTH-1:0][PPN_WIDTH-1:0] itlb_translate_resp_ppn_o,
    // output [TRANSLATE_WIDTH-1:0] itlb_translate_resp_excp_vld_o,
    // output [TRANSLATE_WIDTH-1:0][EXCP_CAUSE_WIDTH-1:0] itlb_translate_resp_excp_cause_o,
    // output [TRANSLATE_WIDTH-1:0] itlb_translate_resp_miss_o,
    // output [TRANSLATE_WIDTH-1:0] itlb_translate_resp_hit_o,


    // // dtlb shoot down
    // input dtlb_flush_vld_i,
    m->dtlb_flush_vld_i = 0;
    // input dtlb_flush_use_asid_i,
    m->dtlb_flush_use_asid_i = 0;
    // input dtlb_flush_use_vpn_i,
    m->dtlb_flush_use_vpn_i = 0;
    // input [VPN_WIDTH-1:0] dtlb_flush_vpn_i,
    m->dtlb_flush_vpn_i = 0;
    // input [ASID_WIDTH-1:0] dtlb_flush_asid_i,
    m->dtlb_flush_asid_i = 0;
    // output dtlb_flush_grant_o,
    // // itlb shoot down
    // input itlb_flush_vld_i,
    m->itlb_flush_vld_i = 0;
    // input itlb_flush_use_asid_i,
    m->itlb_flush_use_asid_i = 0;
    // input itlb_flush_use_vpn_i,
    m->itlb_flush_use_vpn_i = 0;
    // input [VPN_WIDTH-1:0] itlb_flush_vpn_i,
    m->itlb_flush_vpn_i = 0;
    // input [ASID_WIDTH-1:0] itlb_flush_asid_i,
    m->itlb_flush_asid_i = 0;
    // output itlb_flush_grant_o,

    // output tlb_flush_grant_o,
    
    // output ptw_walk_req_vld_o,
    // output [PTW_ID_WIDTH-1:0] ptw_walk_req_id_o,
    // output [PADDR_WIDTH-1:0] ptw_walk_req_addr_o,
    // input ptw_walk_req_rdy_i,
    m->ptw_walk_req_rdy_i = 0;
    // // ptw walk response port
    // input ptw_walk_resp_vld_i,
    m->ptw_walk_resp_vld_i = 0;
    // input [PTE_WIDTH-1:0] ptw_walk_resp_pte_i,
    m->ptw_walk_resp_pte_i = 0;
    // output ptw_walk_resp_rdy,

}
