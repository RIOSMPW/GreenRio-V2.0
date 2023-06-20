#include "Vnew_fu.h"

#include <iostream>
#include <verilated.h>

const uint64_t MAX_TIME = 100;
const uint64_t ALU_SEL_REG = 0;
const uint64_t ALU_SEL_IMM = 1;
const uint64_t ALU_SEL_PC  = 2;
const uint64_t ALU_SEL_CSR = 3;

uint64_t main_time = 0;
Vnew_fu* new_fu;

double sc_time_stamp(){
    return main_time;
}

void set_zero(){
    new_fu->flush = 0;
    new_fu->stall = 0;
    // <> RCU
    new_fu->rs1_data_i = 0;
    new_fu->rs2_data_i = 0;
    new_fu->rob_index_i = 0;
    new_fu->rd_addr_i = 0;
    new_fu->issue_valid_i = 0;
    // alu & cmp
    new_fu->is_alu_i = 0;
    // new_fu->is_cmp_i = 0;
    new_fu->half_i = 0;
    new_fu->pc_i = 0;
    new_fu->next_pc_i = 0;
    new_fu->alu_select_a_i = 0;
    new_fu->alu_select_b_i = 0;
    new_fu->imm_data_i = 0;
    new_fu->csr_data_i = 0;
    new_fu->alu_function_i = 0;
    new_fu->cmp_function_i = 0;
    new_fu->alu_function_modifier_i = 0;
    // branch
    new_fu->jump_i = 0;
    new_fu->branch_i = 0;
    // lsu 
    new_fu->load_i = 0;
    new_fu->store_i = 0;
    new_fu->load_store_size_i = 0;
    new_fu->load_signed_i = 0;
    new_fu->is_load_store_i = 0;
    new_fu->req_ready_i = 1;
    new_fu->resp_valid_i = 0;
    new_fu->resp_data_i = 0;
    // csr
    new_fu->is_csr_i = 0;

}

int main(int argc, char ** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    new_fu = new Vnew_fu;
    
    // global
    new_fu->clk = 0;
    new_fu->rstn = 1;
    
    set_zero();

    while(main_time < MAX_TIME){
        if(main_time % 2){
            new_fu->clk = 1;
        }
        else{
            new_fu->clk = 0;
        }
        if(main_time == 2){
            new_fu->rstn = 0;
        }
        
        // switch (main_time){
        //     // ===== alu test =====
        //     // do reg-reg only
        //     // the rest should be test in alu selfcheck 
        //     case 4 :{ 
        //         // test 1: ALU_ADD_SUB = 3'b000
        //         new_fu->rob_index_i = 1;
        //         new_fu->rd_addr_i = 1;
        //         new_fu->issue_valid_i = 1;
        //         new_fu->is_alu_i = 1;
        //         new_fu->alu_select_a_i = 0;
        //         new_fu->alu_select_b_i = 0;
        //         new_fu->rs1_data_i = 1;
        //         new_fu->rs2_data_i = 2;
        //         new_fu->alu_function_i = 0;
        //         break;
        //     }
        //     case 6 :{
        //         assert(new_fu->alu_done_o);
        //         assert(new_fu->alu_wb_rob_index_o == 1);
        //         assert(new_fu->alu_wb_valid_o);
        //         assert(new_fu->alu_wb_rd_addr_o == 1);
        //         assert(new_fu->alu_wb_data_o == 1 + 2);

        //         // test 2: ALU_SLL = 3'b001
        //         new_fu->rob_index_i = 2;
        //         new_fu->rd_addr_i = 2;
        //         new_fu->rs1_data_i = 4;
        //         new_fu->rs2_data_i = 1;
        //         new_fu->alu_function_i = 1;
        //         break;
        //     }
        //     case 8 :{
        //         assert(new_fu->alu_done_o);
        //         assert(new_fu->alu_wb_rob_index_o == 2);
        //         assert(new_fu->alu_wb_valid_o);
        //         assert(new_fu->alu_wb_rd_addr_o == 2);
        //         assert(new_fu->alu_wb_data_o == 4 << 1);

        //         // test 3: ALU_SLT = 2
        //         new_fu->rob_index_i = 3;
        //         new_fu->rd_addr_i = 3;
        //         new_fu->rs1_data_i = 1;
        //         new_fu->rs2_data_i = 2;
        //         new_fu->alu_function_i = 2;
        //         break;
        //     }
        //     case 10 :{
        //         assert(new_fu->alu_done_o);
        //         assert(new_fu->alu_wb_rob_index_o == 3);
        //         assert(new_fu->alu_wb_valid_o);
        //         assert(new_fu->alu_wb_rd_addr_o == 3);
        //         assert(new_fu->alu_wb_data_o == 1);
                
        //         // test 4: stall 
        //         new_fu->rob_index_i = 1;
        //         new_fu->rd_addr_i = 1;
        //         new_fu->issue_valid_i = 1;
        //         new_fu->is_alu_i = 1;
        //         new_fu->alu_select_a_i = 0;
        //         new_fu->alu_select_b_i = 0;
        //         new_fu->rs1_data_i = 1;
        //         new_fu->rs2_data_i = 2;
        //         new_fu->alu_function_i = 0;
        //         break;
        //     }
        //     case 12 :{
        //         // stall
        //         new_fu->stall = 1;
        //         new_fu->rob_index_i = 2;
        //         new_fu->rd_addr_i = 1;
        //         new_fu->issue_valid_i = 1;
        //         new_fu->is_alu_i = 1;
        //         new_fu->alu_select_a_i = 0;
        //         new_fu->alu_select_b_i = 0;
        //         new_fu->rs1_data_i = 1;
        //         new_fu->rs2_data_i = 2;
        //         new_fu->alu_function_i = 0;
        //         break;
        //     }
        //     case 14 :{
        //         new_fu->stall = 0;
        //         assert(new_fu->alu_done_o);
        //         assert(new_fu->alu_wb_rob_index_o == 1);
        //         assert(new_fu->alu_wb_valid_o);
        //         assert(new_fu->alu_wb_rd_addr_o == 1);
        //         assert(new_fu->alu_wb_data_o == 1 + 2);

        //         // // ===== lsu test =====
        //         // // test5: store
        //         // new_fu->is_alu_i = 0;
        //         // new_fu->is_load_store_i = 1; 
        //         // new_fu->load_i = 0;
        //         // new_fu->store_i = 1;
        //         // new_fu->rs1_data_i = 0x80000000;
        //         // new_fu->rs2_data_i = 0x114514;
        //         // new_fu->rob_index_i = 5;
        //         // new_fu->rd_addr_i = 5;
        //         // new_fu->imm_data_i = 0x10;
        //         // new_fu->load_store_size_i = 0;// sb
        //         // new_fu->load_signed_i = 0;// signed
        //         break;
        //     }
        //     // case 16 :{
        //     //     new_fu->is_load_store_i = 0; 
        //     //     assert(!new_fu->lsu_done_o);// still in s1
        //     //     break;
        //     // }
        //     // case 18 :{
        //     //     assert(new_fu->lsu_done_o);// store should commit 
        //     //     assert(new_fu->lsu_wb_rob_index_o == 5);
        //     //     assert(!new_fu->lsu_wb_valid_o);
        //     //     assert(new_fu->req_valid_o);
        //     //     assert(new_fu->req_opcode_o == 1);
        //     //     // printf("new_fu->req_addr_o:%x\n", new_fu->req_addr_o);
        //     //     assert(new_fu->req_addr_o == 0x80000000 + 0x10);

        //     //     //test6: load and stall    
        //     //     new_fu->is_load_store_i = 1; 
        //     //     new_fu->load_i = 1;
        //     //     new_fu->store_i = 0;
        //     //     new_fu->rs1_data_i = 0x80000000;
        //     //     new_fu->rs2_data_i = 0x114514;
        //     //     new_fu->rob_index_i = 6;
        //     //     new_fu->rd_addr_i = 6;
        //     //     new_fu->imm_data_i = 0x100;
        //     //     new_fu->load_store_size_i = 0;// sb
        //     //     new_fu->load_signed_i = 0;// signed
        //     //     break;
        //     // }
        //     // case 20 :{
        //     //     new_fu->is_load_store_i = 0; 
        //     //     assert(!new_fu->lsu_done_o);// still in s1
        //     //     break;
        //     // }
        //     // case 22 :{
        //     //     new_fu->resp_valid_i = 1;
        //     //     new_fu->resp_data_i = 0x114514;
        //     //     new_fu->stall = 1;
        //     //     assert(!new_fu->resp_ready_o);// when stall, resp should not be ready
        //     //     break;
        //     // }
        //     // case 24 :{
        //     //     new_fu->stall = 0;
        //     //     assert(new_fu->lsu_done_o);// store should commit 
        //     //     assert(new_fu->lsu_wb_rob_index_o == 6);
        //     //     assert(new_fu->lsu_wb_valid_o);
        //     //     assert(new_fu->lsu_wb_rd_addr_o == 6);
        //     //     assert(new_fu->lsu_wb_data_o == 0x114514);
        //     //     break;
        //     // }
        //     // case 26 :{
        //     //     //test7: load and store
        //     //     new_fu->resp_valid_i = 0;
        //     //     assert(!new_fu->lsu_done_o);
        //     //     new_fu->is_load_store_i = 1; 
        //     //     new_fu->load_i = 1;
        //     //     new_fu->store_i = 0;
        //     //     new_fu->rs1_data_i = 0x80000000;
        //     //     new_fu->rs2_data_i = 0x114514;
        //     //     new_fu->rob_index_i = 7;
        //     //     new_fu->rd_addr_i = 7;
        //     //     new_fu->imm_data_i = 0x100;
        //     //     new_fu->load_store_size_i = 0;// sb
        //     //     new_fu->load_signed_i = 0;// signed
        //     //     break;
        //     // }
        //     // case 28 :{
        //     //     assert(!new_fu->lsu_done_o); 
        //     //     new_fu->load_i = 0;
        //     //     new_fu->store_i = 1;
        //     //     new_fu->rs1_data_i = 0x80000000;
        //     //     new_fu->rs2_data_i = 0x114514;
        //     //     new_fu->rob_index_i = 8;
        //     //     new_fu->rd_addr_i = 8;
        //     //     new_fu->imm_data_i = 0x100;
        //     //     new_fu->load_store_size_i = 0;// sb
        //     //     new_fu->load_signed_i = 0;// signed
        //     //     break;
        //     // }
        //     // case 30 :{
        //     //     assert(!new_fu->lsu_done_o);
        //     //     assert(!new_fu->lsu_ready_o); // load should stuck the pipe
        //     //     new_fu->is_load_store_i = 0; 
        //     //     break;
        //     // }
        //     // case 32 :{
        //     //     assert(!new_fu->lsu_ready_o); // load should stuck the pipe
        //     //     assert(!new_fu->lsu_done_o); //load should stack the pipe
        //     //     break;
        //     // }
        //     // case 34 :{
        //     //     new_fu->resp_valid_i = 1;
        //     //     new_fu->resp_data_i = 0x114514;
        //     //     break;
        //     // }
        //     // case 35 :{
        //     //     new_fu->resp_valid_i = 0;
        //     //     assert(new_fu->lsu_ready_o); // load should stuck the pipe
        //     //     assert(new_fu->lsu_done_o);// load should commit 
        //     //     assert(new_fu->lsu_wb_rob_index_o == 7);
        //     //     assert(new_fu->lsu_wb_valid_o);
        //     //     assert(new_fu->lsu_wb_rd_addr_o == 7);
        //     //     assert(new_fu->lsu_wb_data_o == 0x114514);
        //     //     break;
        //     // }
        //     // case 36 :{
        //     //     // printf("\n=======================\n\n");
        //     //     assert(new_fu->lsu_done_o);// store should commit 
        //     //     assert(new_fu->lsu_wb_rob_index_o == 8);
        //     //     assert(!new_fu->lsu_wb_valid_o);

        //     //     break;
        //     // }
        //     case 38 :{
        //         // reset here
        //         set_zero();

        //         // ===== lui test =====
        //         new_fu->is_alu_i = 1;
        //         new_fu->rob_index_i = 1;
        //         new_fu->rd_addr_i = 1;
        //         new_fu->issue_valid_i = 0; // test the case when issue_valid_i == 0
        //         new_fu->imm_data_i = 0x80000000;
        //         new_fu->alu_function_i = 0; //add sub
        //         new_fu->alu_select_a_i = 1; //imm
        //         new_fu->alu_select_b_i = 1; //imm
        //         break;
        //     }
        //     case 40 :{
        //         assert(!new_fu->alu_done_o);// issue valid is 0
        //         new_fu->issue_valid_i = 1;
        //         break;
        //     }
        //     case 42 :{
        //         new_fu->is_alu_i = 0;
        //         assert(new_fu->alu_done_o);
        //         assert(new_fu->alu_wb_valid_o);
        //         assert(new_fu->alu_wb_rd_addr_o == 1);
        //         assert(new_fu->alu_wb_rob_index_o == 1);
        //         // printf("alu_wb_data_o: %x\n", new_fu->alu_wb_data_o);
        //         assert(unsigned(new_fu->alu_wb_data_o) == 0x80000000);
        //         // assert(new_fu->);
        //         break;
        //     }
        //     case 44 :{
        //         assert(!new_fu->alu_done_o);
        //         // ====== csr test =====
        //         // csrrw 
        //         // new_fu->is_alu_i = 1;
        //         new_fu->issue_valid_i = 1;
                
        //         new_fu->is_csr_i = 1;
        //         new_fu->csr_address_i = 1;
        //         new_fu->csr_data_i = 0x114514;
        //         new_fu->csr_read_i = 1;
        //         new_fu->csr_write_i = 1;
        //         new_fu->csr_readable_i = 1;
        //         new_fu->csr_writeable_i = 1;

        //         new_fu->rd_addr_i = 2;
        //         new_fu->rs1_data_i = 0x123456;
        //         new_fu->alu_select_a_i = 0;
        //         new_fu->alu_select_b_i = 1;
        //         new_fu->imm_data_i = 0;
        //         new_fu->alu_function_i = 0;
        //         break;
        //     }
        //     case 46 :{
        //         new_fu->issue_valid_i = 0;
        //         assert(new_fu->csr_wb_valid_o);
        //         assert(new_fu->csr_wb_addr_o == 1);
        //         assert(new_fu->csr_wb_data_o == 0x123456);
        //         assert(new_fu->alu_done_o);
        //         assert(new_fu->alu_wb_valid_o);
        //         assert(new_fu->alu_wb_rd_addr_o == 2);
        //         assert(new_fu->alu_wb_data_o == 0x114514);
        //         // assert(new_fu->);
        //         // assert(new_fu->);
        //         // assert(new_fu->);
        //         break;
        //     }
        //     case 48 :{
        //         // csrrw no read
        //         // new_fu->is_alu_i = 1;
        //         new_fu->issue_valid_i = 1;

        //         new_fu->is_csr_i = 1;
        //         new_fu->csr_address_i = 1;
        //         new_fu->csr_data_i = 0x114514;
        //         new_fu->csr_read_i = 0;
        //         new_fu->csr_write_i = 1;
        //         new_fu->csr_readable_i = 0;
        //         new_fu->csr_writeable_i = 1;

        //         new_fu->rd_addr_i = 2;
        //         new_fu->rs1_data_i = 0x123456;
        //         new_fu->alu_select_a_i = 0;
        //         new_fu->alu_select_b_i = 1;
        //         new_fu->imm_data_i = 0;
        //         new_fu->alu_function_i = 0;
        //         break;
        //     }
        //     case 49 :{
        //         // printf("\n==============\n");
        //         break;
        //     }
        //     case 50 :{
        //         new_fu->issue_valid_i = 0;
        //         assert(new_fu->csr_wb_valid_o);
        //         assert(new_fu->csr_wb_addr_o == 1);
        //         assert(new_fu->csr_wb_data_o == 0x123456);
        //         assert(new_fu->alu_done_o);
        //         assert(!new_fu->alu_wb_valid_o);
        //         break;
        //     }
        //     case 51:{
        //         // printf("\n==============\n");
        //         break;
        //     }
        //     case 52 :{
        //         // csrrs 
        //         // new_fu->is_alu_i = 1;
        //         new_fu->is_csr_i = 1;
        //         new_fu->issue_valid_i = 1;

        //         new_fu->csr_address_i = 1;
        //         new_fu->csr_data_i = 0x8;
        //         new_fu->csr_read_i = 1;
        //         new_fu->csr_write_i = 1;
        //         new_fu->csr_readable_i = 1;
        //         new_fu->csr_writeable_i = 1;

        //         new_fu->rd_addr_i = 2;
        //         new_fu->rs1_data_i = 0x87; 
        //         new_fu->alu_select_a_i = 0;
        //         new_fu->alu_select_b_i = 3;
        //         new_fu->imm_data_i = 0;
        //         new_fu->alu_function_i = 6; //or 
        //         break;
        //     }
        //     case 54 :{
        //         // printf("\n==============\n");
        //         new_fu->issue_valid_i = 0;
        //         assert(new_fu->csr_wb_valid_o);
        //         assert(new_fu->csr_wb_addr_o == 1);
        //         assert(new_fu->csr_wb_data_o == 0x87 | 0x8);
        //         assert(new_fu->alu_done_o);
        //         assert(new_fu->alu_wb_valid_o);
        //         assert(new_fu->alu_wb_rd_addr_o == 2);
        //         assert(new_fu->alu_wb_data_o == 0x8);
        //         break;

        //     }
        //     case 56 :{
        //         // csrrs
        //         // new_fu->is_alu_i = 1;
        //         new_fu->is_csr_i = 1;
        //         new_fu->issue_valid_i = 1;

        //         new_fu->csr_address_i = 1;
        //         new_fu->csr_data_i = 0x8;
        //         new_fu->csr_read_i = 1;
        //         new_fu->csr_write_i = 1;
        //         new_fu->csr_readable_i = 1;
        //         new_fu->csr_writeable_i = 1;

        //         new_fu->rd_addr_i = 2;
        //         new_fu->rs1_data_i = 0x87; 
        //         new_fu->alu_select_a_i = 0;
        //         new_fu->alu_select_b_i = 3;
        //         new_fu->imm_data_i = 0;
        //         new_fu->alu_function_i = 6; //or 
        //         break;
        //     }
        //     case 58 :{
        //         new_fu->issue_valid_i = 0;
        //         assert(new_fu->csr_wb_valid_o);
        //         assert(new_fu->alu_done_o);
        //         assert(new_fu->alu_wb_valid_o);
        //         assert(new_fu->alu_wb_rd_addr_o == 2);
        //         assert(new_fu->alu_wb_data_o == 0x8);
        //         // assert(new_fu->exception_valid_o);
        //         // assert(new_fu->ecause_o == 2);
        //         break;
        //     }
        //     case 60 :{
        //         set_zero();
        //         //
        //         new_fu->is_csr_i = 0;
        //         new_fu->csr_address_i = 1;
        //         new_fu->csr_data_i = 0x114514;
        //         new_fu->csr_read_i = 0;
        //         new_fu->csr_write_i = 0;
        //         new_fu->csr_readable_i = 0;
        //         new_fu->csr_writeable_i = 0;
        //         // branch
        //         new_fu->jump_i = 0;
        //         new_fu->branch_i = 0;
        //         // lsu 
        //         new_fu->load_i = 0;
        //         new_fu->store_i = 0;
        //         new_fu->load_store_size_i = 0;
        //         new_fu->load_signed_i = 0;
        //         new_fu->is_load_store_i = 0;
        //         new_fu->req_ready_i = 1;
        //         new_fu->resp_valid_i = 0;
        //         new_fu->resp_data_i = 0;


        //         // ====== branch test =====
        //         // beq
        //         new_fu->is_alu_i = 1;
        //         new_fu->rs1_data_i = 4;
        //         new_fu->rs2_data_i = 4;
        //         new_fu->rob_index_i = 1;
        //         new_fu->issue_valid_i = 1;
        //         new_fu->pc_i = 0x80000000;
        //         new_fu->alu_select_a_i = ALU_SEL_PC;
        //         new_fu->alu_select_b_i = ALU_SEL_IMM;
        //         new_fu->imm_data_i = 0x10;
        //         new_fu->alu_function_i = 0; // add sub
        //         new_fu->cmp_function_i = 0; // eq
        //         new_fu->jump_i = 0; // not jump
        //         new_fu->branch_i = 1; // branch
        //         break;
        //     }
        //     case 62 :{
        //         assert(new_fu->alu_done_o);
        //         assert(new_fu->btb_valid_o);
        //         // printf("btb_pc_o: %x\n", new_fu->btb_pc_o);
        //         assert(unsigned(new_fu->btb_pc_o) == 0x80000000);
        //         assert(unsigned(new_fu->btb_next_pc_o) == 0x80000000 + 0x10);
        //         assert(new_fu->gshare_pred_valid_o);
        //         assert(new_fu->gshare_pred_taken_o);
        //         assert(unsigned(new_fu->gshare_pred_pc_o) == 0x80000000 + 0x10);
        //         assert(new_fu->pc_valid_o);
        //         assert(unsigned(new_fu->pc_o) == 0x80000000 + 0x10);
        //         // assert(new_fu->instr_buff_nxt_pc_valid_o);
        //         // assert(unsigned(new_fu->instr_buff_nxt_pc_o) == 0x80000000 + 0x10);
        //         assert(~new_fu->csr_wb_valid_o);
        //         assert(~new_fu->alu_wb_valid_o);
        //         assert(new_fu->alu_wb_rob_index_o == 1);
        //         // beq fail
        //         new_fu->is_alu_i = 1;
        //         new_fu->rs1_data_i = 4;
        //         new_fu->rs2_data_i = 5;
        //         new_fu->rob_index_i = 1;
        //         new_fu->issue_valid_i = 1;
        //         new_fu->pc_i = 0x80000000;
        //         new_fu->alu_select_a_i = ALU_SEL_PC;
        //         new_fu->alu_select_b_i = ALU_SEL_IMM;
        //         new_fu->imm_data_i = 0x10;
        //         new_fu->alu_function_i = 0; // add sub
        //         new_fu->cmp_function_i = 0; // eq
        //         new_fu->jump_i = 0; // not jump
        //         new_fu->branch_i = 1; // branch
        //         // assert(new_fu->);
        //         break;
        //     }
        //     case 64 :{
        //         assert(new_fu->alu_done_o);
        //         assert(new_fu->btb_valid_o);
        //         // printf("btb_pc_o: %x\n", new_fu->btb_pc_o);
        //         assert(unsigned(new_fu->btb_pc_o) == 0x80000000);
        //         assert(unsigned(new_fu->btb_next_pc_o) == 0x80000000 + 0x10);
        //         assert(new_fu->gshare_pred_valid_o);
        //         assert(~new_fu->gshare_pred_taken_o);
        //         assert(unsigned(new_fu->gshare_pred_pc_o) == 0x80000000 + 0x10);
        //         assert(new_fu->pc_valid_o);
        //         // assert(unsigned(new_fu->pc_o) == 0x80000000 + 0x10);
        //         // assert(new_fu->instr_buff_nxt_pc_valid_o);
        //         // assert(unsigned(new_fu->instr_buff_nxt_pc_o) == 0x80000000 + 0x10);
        //         assert(~new_fu->csr_wb_valid_o);
        //         assert(~new_fu->alu_wb_valid_o);
        //         assert(new_fu->alu_wb_rob_index_o == 1);
        //         // bne succ
        //         new_fu->is_alu_i = 1;
        //         new_fu->rs1_data_i = 4;
        //         new_fu->rs2_data_i = 5;
        //         new_fu->rob_index_i = 1;
        //         new_fu->issue_valid_i = 1;
        //         new_fu->pc_i = 0x80000000;
        //         new_fu->alu_select_a_i = ALU_SEL_PC;
        //         new_fu->alu_select_b_i = ALU_SEL_IMM;
        //         new_fu->imm_data_i = 0x10;
        //         new_fu->alu_function_i = 0; // add sub
        //         new_fu->cmp_function_i = 1; // bne
        //         new_fu->jump_i = 0; // not jump
        //         new_fu->branch_i = 1; // branch
        //         break;
        //     }
        //     case 66 :{
        //         // bne
        //         assert(new_fu->alu_done_o);
        //         assert(new_fu->btb_valid_o);
        //         // printf("btb_pc_o: %x\n", new_fu->btb_pc_o);
        //         assert(unsigned(new_fu->btb_pc_o) == 0x80000000);
        //         assert(unsigned(new_fu->btb_next_pc_o) == 0x80000000 + 0x10);
        //         assert(new_fu->gshare_pred_valid_o);
        //         assert(new_fu->gshare_pred_taken_o);
        //         assert(unsigned(new_fu->gshare_pred_pc_o) == 0x80000000 + 0x10);
        //         assert(new_fu->pc_valid_o);
        //         assert(unsigned(new_fu->pc_o) == 0x80000000 + 0x10);
        //         // assert(new_fu->instr_buff_nxt_pc_valid_o);
        //         // assert(unsigned(new_fu->instr_buff_nxt_pc_o) == 0x80000000 + 0x10);
        //         assert(~new_fu->csr_wb_valid_o);
        //         assert(~new_fu->alu_wb_valid_o);
        //         assert(new_fu->alu_wb_rob_index_o == 1);

        //         // jal 
        //         new_fu->is_alu_i = 1;
        //         new_fu->rs1_data_i = 1;
        //         new_fu->rs2_data_i = 0;
        //         new_fu->rd_addr_i = 2;
        //         new_fu->rob_index_i = 1;
        //         new_fu->issue_valid_i = 1;
        //         new_fu->pc_i = 0x80000000;
        //         new_fu->next_pc_i = 0x80000000 + 0x4;
        //         new_fu->alu_select_a_i = ALU_SEL_PC;
        //         new_fu->alu_select_b_i = ALU_SEL_IMM;
        //         new_fu->imm_data_i = 0x1000;
        //         new_fu->alu_function_i = 0; // add sub
        //         new_fu->cmp_function_i = 0; // bne
        //         new_fu->jump_i = 1; // not jump
        //         new_fu->branch_i = 1; // branch
                
        //         break;
        //     }
        //     case 68 :{
        //         // jal check
        //         assert(new_fu->alu_done_o);
        //         assert(new_fu->btb_valid_o);
        //         assert(unsigned(new_fu->btb_pc_o) == 0x80000000);
        //         assert(unsigned(new_fu->btb_next_pc_o) == 0x80000000 + 0x1000);
        //         assert(new_fu->gshare_pred_valid_o);
        //         assert(new_fu->gshare_pred_taken_o);
        //         assert(unsigned(new_fu->gshare_pred_pc_o) == 0x80000000 + 0x1000);
        //         assert(new_fu->pc_valid_o);
        //         assert(unsigned(new_fu->pc_o) == 0x80000000 + 0x1000);
        //         // assert(new_fu->instr_buff_nxt_pc_valid_o);
        //         // assert(unsigned(new_fu->instr_buff_nxt_pc_o) == 0x80000000 + 0x1000);
        //         assert(~new_fu->csr_wb_valid_o);
        //         assert(new_fu->alu_wb_valid_o);
        //         assert(new_fu->alu_wb_rob_index_o == 1);
        //         assert(new_fu->alu_wb_rd_addr_o == 2);
        //         // printf("alu_wb_data_o: %x\n", new_fu->alu_wb_data_o);
        //         assert(unsigned(new_fu->alu_wb_data_o) == 0x80000000 + 0x4);
        //         // assert(new_fu->);
        //         // assert(new_fu->);
        //         // JARL
        //         new_fu->is_alu_i = 1;
        //         new_fu->rs1_data_i = 0x50000000;
        //         new_fu->rs2_data_i = 0;
        //         new_fu->rd_addr_i = 2;
        //         new_fu->rob_index_i = 1;
        //         new_fu->issue_valid_i = 1;
        //         new_fu->pc_i = 0x80000000;
        //         new_fu->next_pc_i = 0x80000000 + 0x4;
        //         new_fu->alu_select_a_i = ALU_SEL_REG;
        //         new_fu->alu_select_b_i = ALU_SEL_IMM;
        //         new_fu->imm_data_i = 0x100;
        //         new_fu->alu_function_i = 0; // add sub
        //         new_fu->cmp_function_i = 0; // bne
        //         new_fu->jump_i = 1; // not jump
        //         new_fu->branch_i = 1; // branch
        //         break;
        //     }
        //     case 70 :{
        //         assert(new_fu->alu_done_o);
        //         assert(new_fu->btb_valid_o);
        //         assert(unsigned(new_fu->btb_pc_o) == 0x50000000);
        //         assert(unsigned(new_fu->btb_next_pc_o) == 0x50000000 + 0x100);
        //         assert(new_fu->gshare_pred_valid_o);
        //         assert(new_fu->gshare_pred_taken_o);
        //         assert(unsigned(new_fu->gshare_pred_pc_o) == 0x50000000 + 0x100);
        //         assert(new_fu->pc_valid_o);
        //         assert(unsigned(new_fu->pc_o) == 0x50000000 + 0x100);
        //         // assert(new_fu->instr_buff_nxt_pc_valid_o);
        //         // assert(unsigned(new_fu->instr_buff_nxt_pc_o) == 0x50000000 + 0x100);
        //         assert(~new_fu->csr_wb_valid_o);
        //         assert(new_fu->alu_wb_valid_o);
        //         assert(new_fu->alu_wb_rob_index_o == 1);
        //         assert(new_fu->alu_wb_rd_addr_o == 2);
        //         // printf("alu_wb_data_o: %x\n", new_fu->alu_wb_data_o);
        //         assert(unsigned(new_fu->alu_wb_data_o) == 0x80000000 + 0x4);
                
        //         // reset new_fu
        //         set_zero();



        //         // ====== EXCEPTION TESTS =====
        //         // alu exception test
        //         // csrrs no write
        //         new_fu->is_csr_i = 1;
        //         new_fu->issue_valid_i = 1;

        //         new_fu->csr_address_i = 1;
        //         new_fu->csr_data_i = 0x8;
        //         new_fu->csr_read_i = 1;
        //         new_fu->csr_write_i = 1;
        //         new_fu->csr_readable_i = 1;
        //         new_fu->csr_writeable_i = 0;

        //         new_fu->rd_addr_i = 2;
        //         new_fu->rs1_data_i = 0x87; 
        //         new_fu->alu_select_a_i = 0;
        //         new_fu->alu_select_b_i = 3;
        //         new_fu->imm_data_i = 0;
        //         new_fu->alu_function_i = 6; //or 
                
        //         break;
        //     }
        //     case 72 :{
        //         // exception should raise
        //         assert(new_fu->csr_wb_valid_o);
        //         assert(new_fu->alu_done_o);
        //         assert(new_fu->alu_wb_valid_o);
        //         assert(new_fu->alu_wb_rd_addr_o == 2);
        //         assert(new_fu->alu_wb_data_o == 0x8);
        //         assert(new_fu->alu_exception_valid_o);
        //         assert(new_fu->alu_ecause_o == 2);
        //         // assert(!new_fu->alu_ready_o);
        //         break;
        //     }
        //     case 74 :{
        //         //flush
        //         new_fu->flush = 1;
            
        //         break;
        //     }
        //     case 76 :{
        //         new_fu->flush = 0;
        //         assert(new_fu->lsu_ready_o);
        //         assert(new_fu->alu_ready_o);
        //         set_zero();
        //         break;
        //     }
        //     case 78 :{
        //         // load exception, a following store should not be sent
        //         new_fu->issue_valid_i = 1;
        //         new_fu->is_load_store_i = 1; 
        //         new_fu->load_i = 1;
        //         new_fu->store_i = 0;
        //         new_fu->rs1_data_i = 0x80000001; // exception
        //         new_fu->rs2_data_i = 0x114514;
        //         new_fu->rob_index_i = 6;
        //         new_fu->rd_addr_i = 6;
        //         new_fu->imm_data_i = 0x10;
        //         new_fu->load_store_size_i = 1;// sh
        //         new_fu->load_signed_i = 0;// signed
        //         break;
        //     }
        //     case 79 : {
        //         // printf("=============\n");
        //         break;
        //     }
        //     case 80 :{
                
        //         new_fu->issue_valid_i = 0;
        //         assert(!new_fu->lsu_ready_o);
        //         // new_fu->is_load_store_i = 1; 
        //         // new_fu->load_i = 0;
        //         // new_fu->store_i = 1;
        //         // new_fu->rs1_data_i = 0x80000001; // exception
        //         // new_fu->rs2_data_i = 0x114514;
        //         // new_fu->rob_index_i = 6;
        //         // new_fu->rd_addr_i = 6;
        //         // new_fu->imm_data_i = 0x100;
        //         // new_fu->load_store_size_i = 0;// sh
        //         // new_fu->load_signed_i = 0;// signed

        //         // load s0

        //         break;
        //     }
        //     case 82 :{
        //         new_fu->flush = 1;
        //         // // load s1. should do no read and return directly
        //         assert(!new_fu->lsu_ready_o);
        //         // assert(new_fu->lsu_done_o);
        //         // assert(new_fu->lsu_exception_valid_o);
        //         // assert(new_fu->lsu_ecause_o == 4); // EXCEPTION_LOAD_ADDR_MISALIGNED
        //         // assert(!new_fu->req_valid_o);
                
        //         break;
        //     }
        //     case 84 :{

        //         new_fu->flush = 0;
        //         assert(new_fu->lsu_ready_o);
        //         // assert(!new_fu->req_valid_o);
        //         break;
        //     }
        //     default:{
        //         break;
        //     }
            
        // }
        // if(4 <= main_time & main_time % 2 == 0){
        //     std::cout << "test " << (main_time - 4) / 2  + 1<< " pass! " << std::endl;
        // }
        new_fu->eval();
        main_time ++;
    }
    std::cout << "\n========== new_fu tests pass! ==========\n" << std::endl;

    new_fu->final();
    delete new_fu;
    exit(0);
}