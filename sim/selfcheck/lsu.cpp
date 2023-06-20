#include "Vlsu.h"

#include <iostream>
#include <verilated.h>


const uint64_t MAX_TIME = 150;


uint64_t main_time = 0;
Vlsu* lsu;

double sc_time_stamp(){
    return main_time;
}

int main(int argc, char ** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    lsu = new Vlsu;
    
    // VerilatedVcdC* tfp

    lsu->clk = 0;
    lsu->rstn = 0;
    lsu->stall = 0;
    lsu->valid_i = 0;
    lsu->rob_index_i = 1;
    lsu->rd_addr_i = 1;
    lsu->rs1_data_i = 0;
    lsu->rs2_data_i = 0;
    lsu->imm_i = 0;
    lsu->opcode_i = 0;
    lsu->size_i = 0;
    lsu->load_sign_i = 0;

    lsu->req_ready_i = 1;
    
    lsu->resp_valid_i = 0;
    lsu->resp_data_i = 0;

    while(main_time < MAX_TIME){
        if(main_time > 10) {
            lsu->rstn = 1;
        }
        if((main_time % 10) == 1) {
            lsu->clk = 1;
        }
        if((main_time % 10) == 6){
            lsu->clk = 0;
        }

        if(main_time == 20){ // load from 0x80000010 to rd 1 
            lsu->valid_i = 1;
            lsu->rob_index_i = 1;
            lsu->rd_addr_i = 1;
            lsu->rs1_data_i = 0x0000000080000000; // 0x80000000
            lsu->rs2_data_i = 0x1234567812345678;
            lsu->imm_i = 0x10;
            lsu->opcode_i = 0; //load
            // lsu->size_i = 0;
            // lsu->load_sign_i = 0;

            // lsu->req_ready_i = 1;
            
            // lsu->resp_valid_i = 0;
            // lsu->resp_data_i = 0x0000000000000000;
        }

        if(main_time == 25){// load end
            lsu->valid_i = 0;
        }


        if(main_time == 30){
            lsu-> valid_i = 1;
            lsu->rob_index_i = 2;
            lsu->rd_addr_i = 2;
            lsu->rs1_data_i = 0x0000000080000000; // 0x80000000
            lsu->rs2_data_i = 0x1234567812345678;
            lsu->imm_i = 0x20;
            lsu->opcode_i = 1; //store
        }
        if(main_time == 25){// store end
            lsu->valid_i = 0;
        }

        if(main_time == 60){ // response come
            lsu->resp_valid_i = 1;
            lsu->resp_data_i = 0x114514;
        }

        if(main_time == 65) { //response end
            lsu->resp_valid_i = 0;
            lsu->resp_data_i = 0;
        }

        if(main_time == 80){ // cache req ready down, input store
            lsu-> valid_i = 1;
            lsu->rob_index_i = 3;
            lsu->rd_addr_i = 3;
            lsu->rs1_data_i = 0x0000000080000000; // 0x80000000
            lsu->rs2_data_i = 0x11451400114514;
            lsu->imm_i = 0x30;
            lsu->opcode_i = 1; //store

            lsu->req_ready_i = 0;
        }

        if(main_time == 85) { //store down
            lsu-> valid_i = 0;
        }

        if(main_time == 110) {
            lsu->req_ready_i = 1;
        }


        if(main_time == 110){// rd = x0
            lsu->valid_i = 1;
            lsu->rd_addr_i = 0; 
        }

        if(main_time == 120){// misaligned
            lsu->rd_addr_i = 4; 
            lsu->size_i = 1;
            lsu->imm_i = 0x11;
        }
        
        lsu->eval();

        if(20 <= main_time && main_time % 10 == 0){
            std::cout << "tik: "  <<  (main_time - 20) / 10 << std::endl;
            // std::cout << "clk_tmp_o: " << lsu->clk_tmp_o << std::endl;
            // std::cout << "rd_addr_o: " << lsu->rd_addr_o << std::endl;
            // std::cout << "stall_o: " << lsu->stall_o << std::endl;
        }
        main_time ++;
    }
    lsu->final();
    delete lsu;
    exit(0);
}