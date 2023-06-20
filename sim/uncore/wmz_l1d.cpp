/////////////////////////
// Author: Peichen Guo //
//    RIOS Lab work    //
//      HeHe Core      //
/////////////////////////
#include "Vwmz_l1d.h"

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
Vwmz_l1d* wmz_l1d;

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

    wmz_l1d = new Vwmz_l1d("wmz_l1d");
    wmz_l1d->trace(tfp, 0);
    tfp->open("wmz_l1d.vcd");

    wmz_l1d->clk = 0;
    wmz_l1d->rst = 1;
    wmz_l1d->flush = 0;

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