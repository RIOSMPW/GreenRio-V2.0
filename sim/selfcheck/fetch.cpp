#include <verilated.h>

#include <iostream>

#include "Vfetch.h"

const uint64_t MAX_TIME =50;
uint64_t main_time = 0;
Vfetch *tb;

int main(int argc, char **argv, char **env) {
  Verilated::debug(0);
  Verilated::randReset(0);
  Verilated::traceEverOn(true);
  Verilated::commandArgs(argc, argv);
  tb = new Vfetch;
  // initialize input
  tb->clk = 0;
  tb->reset = 1;
  tb->trap = 0;
  tb->mret = 0;
  tb->trap_vector = 0x00000000;
  tb->mret_vector = 0x00000000;
  tb->invalidate = 0;
  tb->prev_pc = 0x00000000;
  tb->prev_branch_in = 0;
  tb->prev_taken = 0;
  tb->valid_real_branch = 0 ;


  while (main_time < MAX_TIME) {
    if (main_time % 2 == 1) {
      tb->clk = 1;
      
    } else {
      tb->is_req_pc = 0;
      tb->clk = 0;
      tb->icache_ready = 0;
      printf("main_time: %d, write pc: %x\n", main_time, tb->pc);
    }

    if (main_time == 2) {
      tb->reset = 0;
    }

    switch (main_time) {
      // 测试1：能否正确存入和输出instruction buffer 能否正确使用btb，输出正确的指令顺序
      // 先写入1条btb，然后在第三个周期的时候使用  //已经正确输出
      // 测试二：instruction buffer full的情况，能否正确的停止fetch
      // 测试三：能否正确的flush以及flush之后能否输出正确的指令顺序

      case 4: {
        tb->icache_ready = 1;
        tb->rd_en = 0;
        tb->is_req_pc = 1;
        tb->btb_req_pc = 0x80000008;
        tb->btb_predict_target = 0x70000000;
        break;
      }
      case 6: {
        tb->is_req_pc=1;
        tb->btb_req_pc = 0x70000004;
        tb->btb_predict_target = 0x80000024;
        break;
      }
      case 12: {
        tb->icache_ready = 1;
        break;
      }
      case 14: {

        break;
      }
      case 16: {
        tb->icache_ready = 1;        
        break;
      }
      case 18: {
        tb->icache_ready = 1;
        break;
      }
      case 20: {
        tb->icache_ready = 1;        
        break;
      }
      case 22: {
        tb->icache_ready = 1;
        break;
      }
      case 24: {
        tb->icache_ready = 1;
        break;
      }
      case 26: {
        tb->icache_ready = 1;
        break;
      }
      
      case 30: {
        tb->icache_ready = 1;
        tb->valid_real_branch = 1 ;
        tb->real_branch = 0x70000000;
        break;
      }
      case 32: {
        tb->icache_ready = 1;
        tb->valid_real_branch = 0 ;
        tb->rd_en = 1;
        break;

      }
      case 34: {
        tb->icache_ready = 1;
        break;
      }
      case 36: {
        tb->icache_ready = 1;
        break;
      }
      case 38: {
        tb->icache_ready = 1;
        break;
      }

     
    }
    tb->eval();
    printf( 
        "main_time: %d, pc: %x, fetch_data: %x, pc_out: %x, "
        "next_pc_out: %x, instruction_out: %x, real_branch: %x, ins_empty: %d,buffer_full: %d,\n "
        " ins_pc_in: %x, ins_next_pc_in, %x, instruction: %x, wrong_pred: %d, icache_ready: %d, decache read: %d\n",
        main_time, tb->pc, tb->fetch_data, tb->pc_out, tb->next_pc_out, tb->instruction_out,
        tb->real_branch, tb->ins_empty,  tb->buffer_full,tb->ins_pc_in, tb->ins_next_pc_in, 
        tb->instruction_in, tb->wrong_pred, tb->icache_ready, tb->rd_en);
    main_time++;
  }

  tb->final();

  delete tb;
  tb = nullptr;
  return 0;
}
