/////////////////////////
// Author: Peichen Guo //
//    RIOS Lab work    //
//      HeHe Core      //
/////////////////////////
#include "Vuncore.h"

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
Vuncore* uncore;

double sc_time_stamp(){
    return main_time;
}

void reset(){

   
    return;
}
int main(int argc, char ** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC();

    uncore = new Vuncore("uncore");
    uncore->trace(tfp, 0);
    tfp->open("uncore.vcd");

    uncore->clk = 0;
    uncore->rst = 1;
    uncore->flush = 0;

    reset();

    
    try {
        // test code 
        
    }
    catch(const char* msg){
       
    }
    tfp->dump(main_time);
    tfp->close();
    
    exit(0);
}