#include "Vbackend.h"

#include <iostream>
#include "verilated_vcd_c.h"
#include <verilated.h>

const uint64_t MAX_TIME = 1000;
const uint32_t RST_TIME = 100;
const uint64_t ALU_SEL_REG = 0;
const uint64_t ALU_SEL_IMM = 1;
const uint64_t ALU_SEL_PC  = 2;
const uint64_t ALU_SEL_CSR = 3;

uint64_t main_time = 0;
Vbackend* backend = nullptr;

double sc_time_stamp(){
    return main_time;
}

void reset(){
    if(backend != nullptr){
        backend->clk = 0;
        backend->rstn = 0;

        //related to excp.v
        backend->wfi_ctrl_in = 0;  //rcu里缺逻辑20220825
        backend->trapped = 0;
        backend->valid_i = 0;
        backend->ecause_i = 0;
        backend->exception_i = 0;
        backend->wfi_i = 0;
        backend->mret_i = 0;
            // rs valid
        backend->uses_rs1_i = 0;
        backend->uses_rs2_i = 0;
        backend->uses_csr_i = 0;
            // rd valid
        backend->uses_rd_i = 0;// remaining backend->uses_rd = 0;
            //rob op
        backend->pc_i = 0; //PC_WIDTH = 32
        backend->next_pc_i = 0;
        backend->is_alu_i = 0; //to choose which pipe of function unit
                //alu
        backend->deco_alu_select_a_i = 0;
        backend->deco_alu_select_b_i = 0;
        backend->cmp_function_i = 0;
        backend->imm_data_i = 0;
        backend->half_i = 0;
        backend->alu_function_i = 0;
        backend->alu_function_modifier_i = 0;
        backend->branch_i = 0;
        backend->jump_i = 0;
                //lsu
        backend->load_i = 0;
        backend->store_i = 0;
        backend->load_store_size_i = 0;
        backend->load_signed_i = 0;
            // rs address
        backend->rs1_address_i = 0;
        backend->rs2_address_i = 0;
        backend->rd_address_i = 0;
            // <decode> csr
        backend->is_csr_i = 0;
        backend->csr_address_i = 0;
        backend->csr_data_i = 0;
        backend->csr_read_i = 0;
        backend->csr_write_i = 0;
        backend->csr_readable_i = 0;
        backend->csr_writeable_i = 0;
    }
}

int main(int argc, char ** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC();
    backend = new Vbackend;
    backend->trace(tfp, 0);
    tfp->open("backend.vcd");

    reset();
    backend->rstn = 1;

    // global
    while(main_time < MAX_TIME){
        if(main_time % 10 == 0){
            backend->clk = 1;
        }
        else if (main_time % 10 == 5){
            backend->clk = 0;
        }

        if(main_time == RST_TIME){
            backend->rstn = 0;
        }

        if((RST_TIME + 20) < main_time){
            if(main_time == 300){// send load 
                backend->valid_i = 1;
                backend->uses_rs1_i = 1;
                backend->uses_rs2_i = 0;
                // backend->uses_csr_i = 0;
                    // rd valid
                backend->uses_rd_i = 1;
                backend->load_i = 1;
                backend->store_i = 0;
                backend->load_store_size_i = 0; // byte
                backend->load_signed_i = 0;
                    // rs address
                backend->rs1_address_i = 1;
                backend->rs2_address_i = 0;
                backend->rd_address_i = 2;
            }
            else if(main_time == 335){
                reset();
            }
        }

        // if(backend->req_valid_o){
        //     printf("req happened!\n");
        // }

        backend->eval();
        tfp->dump(main_time);
        main_time ++;
    }
    std::cout << "backend build done" << std::endl;

    backend->final();
    tfp->close();
    delete backend;
    delete tfp;
    exit(0);
}