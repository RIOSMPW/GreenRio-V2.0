#include <verilated.h>

#include <iostream>

#include "Vfu.h"

const uint64_t MAX_TIME = 100;
uint64_t main_time = 0;
Vfu *tb;

int main(int argc, char **argv, char **env) {
    Verilated::debug(0);
    Verilated::randReset(0);
    Verilated::traceEverOn(true);
    Verilated::commandArgs(argc, argv);
    VerilatedVcdC* tfp = new VerilatedVcdC();
    tb = new Vfu;
    tfp->open("wave.vcd");
    tb->trace(tfp, 0);
    //initialization
    tb->clk                       = 0;
    tb->reset                     = 1;
    tb->wfi_ctrl_in               = 0;
    tb->trapped                   = 0;
/*    //from decode
    tb->valid_in                  = 0;
    tb->ecause_in                 = 0;
    tb->exception_in              = 0; 
            // rs valid
    tb->uses_rs1                  = 0;
    tb->uses_rs2                  = 0;
    tb->uses_csr                  = 0;
            // rd valid
    tb->uses_rd                   = 0;
            //rob op
    tb->pc_in                     = 0;
    tb->next_pc_in                = 0;
    tb->is_alu                    = 0;
            //alu
    tb->deco_alu_select_a_in      = 0;         
    tb->deco_alu_select_b_in      = 0;         
    tb->cmp_function_in           = 0;    
    tb->imm_data_in               = 0;
    tb->half                      = 0;
    //input [63:0] csr_data_in,
    tb->alu_function_in           = 0;    
    tb->alu_function_modifier_in  = 0;             
    tb->branch_in                 = 0;
    tb->jump_in                   = 0;
            //lsu
    tb->load_in                   = 0;
    tb->store_in                  = 0;
    tb->load_store_size_in        = 0;       
    tb->load_signed_in            = 0;   
            // rs address
    tb->rs1_address_in            = 0;
    tb->rs2_address_in            = 0;
    tb->rd_address_in             = 0;
            // from csr
    tb->csr_address_in            = 0;   
    tb->csr_data_in               = 0;
    tb->csr_read_in               = 0;
    tb->csr_write_in              = 0; 
    tb->csr_readable_in           = 0;    
    tb->csr_writeable_in          = 0;     
    tb->wfi_in                    = 0;
    tb->mret_in                   = 0;
    //from FU
    tb->func_wrb_alu_done         = 0;
    tb->func_wrb_lsu_done         = 0;     
    tb->func_wrb_valid_alu        = 0;     
    tb->func_wrb_valid_lsu        = 0;     
    tb->func_wrb_rd_data_alu      = 0;     
    tb->func_wrb_rd_data_lsu      = 0;     
    tb->func_wrb_rd_address_lsu   = 0;     
    tb->func_wrb_rd_address_alu   = 0;     
    tb->func_wrb_rob_line_alu     = 0;     
    tb->func_wrb_rob_line_lsu     = 0;     
    tb->func_wrb_rob_alu_exp      = 0;     
    tb->func_wrb_rob_lsu_exp      = 0;     
    tb->func_wrb_rob_alu_ecause   = 0;     
    tb->func_wrb_rob_lsu_ecause   = 0;     
    tb->func_load_store_ready     = 0;     
    tb->func_alu_ready            = 0;     
    tb->func_wrb_rd_address       = 0;        
    tb->func_wrb_rob_line         = 0;
    while (main_time < MAX_TIME) {
        if (main_time % 2 == 1) {
            tb->clk = 1;
        } else {
            tb->clk = 0;
        }

        switch(maintime) {
            case 4:{ //addi x1 x0 1
                tb->reset = 0;
                tb->valid_in                  = 1;
                tb->ecause_in                 = 0;
                tb->exception_in              = 0; 
                        // rs valid
                tb->uses_rs1                  = 0;
                tb->uses_rs2                  = 0;
                tb->uses_csr                  = 0;
                        // rd valid
                tb->uses_rd                   = 1;
                        // rs address
                tb->rs1_address_in            = 0;
                tb->rs2_address_in            = 0;
                tb->rd_address_in             = 1;
                        //rob op
                tb->pc_in                     = 0;
                tb->next_pc_in                = 0;
                tb->is_alu                    = 1;
                        //alu
                tb->deco_alu_select_a_in      = 0;         
                tb->deco_alu_select_b_in      = 0;         
                tb->cmp_function_in           = 0;    
                tb->imm_data_in               = 0;
                tb->half                      = 0;
                //input [63:0] csr_data_in,
                tb->alu_function_in           = 0;    
                tb->alu_function_modifier_in  = 0;             
                tb->branch_in                 = 0;
                tb->jump_in                   = 0;
                        //lsu
                tb->load_in                   = 0;
                tb->store_in                  = 0;
                tb->load_store_size_in        = 0;       
                tb->load_signed_in            = 0;   
                        // from csr
                tb->csr_address_in            = 0;   
                tb->csr_data_in               = 0;
                tb->csr_read_in               = 0;
                tb->csr_write_in              = 0; 
                tb->csr_readable_in           = 0;    
                tb->csr_writeable_in          = 0;     
                tb->wfi_in                    = 0;
                tb->mret_in                   = 0;
            }
        }
    tb->eval();
    main_time++;
    }
*/
    tb->final();
    tfp->close();   
    delete tb;
    delete tfp;
    tb = nullptr;
    return 0;
}