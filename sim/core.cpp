
#include "core.hpp"
#include <cstdio>
#include <verilated.h>
#include <svdpi.h>


extern "C"{
bool ins_commit;
extern void commit_check_forIPC(svLogic commit_valid_o){
    if(commit_valid_o){
        ins_commit = true;
    }
    else {
        ins_commit = false;
    }
}
//use to test the capacity of bpu
float predict_total=0;
float predict_right=0;
extern void prediction_accuracy(svLogic branch_valid_i, svLogic ins_empty,int real_branch, int pc_out, int ins_pc_in){
    if(branch_valid_i & !ins_empty){
        if(real_branch == pc_out) {
            predict_total++;
            predict_right++;
        }
        if(real_branch != pc_out) {
            predict_total++;
        }
    }
    if(branch_valid_i & ins_empty){
        if(real_branch == ins_pc_in) {
            predict_total++;
            predict_right++;
        }
        if(real_branch != ins_pc_in) {
            predict_total++;
        }
    }
}

}

#ifdef DUMP_WAVE 

void Core::reset() {
    core_logic->clk = 0;
    core_logic->reset = 1;
    core_logic->eval();
    tfp->dump(contextp->time());
    int i = 0;
    while (i < 600){
        contextp->timeInc(HALF_CYCLE);
        core_logic->clk = 1;
        core_logic->eval();
        tfp->dump(contextp->time());
        i++;
        contextp->timeInc(HALF_CYCLE);
        core_logic->clk = 0;
        core_logic->eval();
        tfp->dump(contextp->time());
        i++;
    }
    //此时位于下降沿底部，且已经计算完成
    contextp->timeInc(HALF_CYCLE*0.5);
    core_logic->reset = 0;
    core_logic->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(HALF_CYCLE*0.5);
    core_logic->clk = 1;
    core_logic->eval();
    tfp->dump(contextp->time());
    //复位完成后在上升沿顶部，且已经计算完成
}

void Core::cycle() {  //在cycle()中完成一个cycle的所有模拟
    // svSetScope(svGetScopeFromName("TOP.hehe"));
    cycle_num++;
    contextp->timeInc(HALF_CYCLE);
    core_logic->clk = 0;  
    core_logic->eval();
    tfp->dump(contextp->time());
    if(ins_commit){
        ins_num++;
    }
    contextp->timeInc(HALF_CYCLE);
    // memory.tohost_handler(core_logic);
    memory.I_Request(core_logic);  
    memory.D_Request(core_logic); 
    core_logic->clk = 1;
    core_logic->eval();
    tfp->dump(contextp->time());
}

void Core::core_init(const char* vcdname) {
    contextp = new VerilatedContext;
    core_logic = new Vhehe(contextp);
    tfp = new VerilatedVcdC;
    contextp->traceEverOn(true); //打开追踪
    core_logic->trace(tfp, 0);
    tfp->open(vcdname);
    core_logic->m2_wbd_ack_i = 0;
    core_logic->m3_wbd_ack_i = 0;
    memory.d_wait = 0;
    memory.i_wait = 0;
    cycle_num = 0;
    ins_num = 0;
}

void Core::close() {
    core_logic->final();
    delete core_logic;
    tfp->close();
    delete contextp;
    printf("ins_num = %f, cycle_num = %f, IPC = %f\n", ins_num, cycle_num, (double)ins_num/cycle_num);
    printf("prediction accuracy: %f, predict_total: %f, predict_right %f\n", predict_right/predict_total, predict_total, predict_right);
}

#else

void Core::reset() {
    core_logic->clk = 0;
    core_logic->reset = 1;
    core_logic->eval();
    int i = 0;
    while (i < 600){
        contextp->timeInc(HALF_CYCLE);
        core_logic->clk = 1;
        core_logic->eval();
        i++;
        contextp->timeInc(HALF_CYCLE);
        core_logic->clk = 0;
        core_logic->eval();
        i++;
    }
    //此时位于下降沿底部，且已经计算完成
    contextp->timeInc(HALF_CYCLE*0.5);
    core_logic->reset = 0;
    core_logic->eval();
    contextp->timeInc(HALF_CYCLE*0.5);
    core_logic->clk = 1;
    core_logic->eval();
    //复位完成后在上升沿顶部，且已经计算完成
}

void Core::cycle() {  //在cycle()中完成一个cycle的所有模拟
    // svSetScope(svGetScopeFromName("TOP.hehe"));
    cycle_num++;
    contextp->timeInc(HALF_CYCLE);
    core_logic->clk = 0;  
    core_logic->eval();
    if(ins_commit)
        ins_num++;
    contextp->timeInc(HALF_CYCLE);
    // memory.tohost_handler(core_logic);
    memory.I_Request(core_logic);  
    memory.D_Request(core_logic); 
    core_logic->clk = 1;
    core_logic->eval();
}

void Core::core_init(const char* vcdname) {
    contextp = new VerilatedContext;
    core_logic = new Vhehe(contextp);
    core_logic->m2_wbd_ack_i = 0;
    core_logic->m3_wbd_ack_i = 0;
    memory.d_wait = 0;
    memory.i_wait = 0;
    cycle_num = 0;
    ins_num = 0;
}

void Core::close() {
    core_logic->final();
    delete core_logic;
    delete contextp;
    printf("ins_num = %f, cycle_num = %f, IPC = %f\n", ins_num, cycle_num, ins_num/cycle_num);
    printf("prediction accuracy: %f, predict_total: %f, predict_right %f\n", predict_right/predict_total, predict_total, predict_right);
}
#endif


