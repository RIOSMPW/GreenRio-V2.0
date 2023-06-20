#include <verilated.h>

#include <iostream>

#include "Vbtb.h"

const uint64_t MAX_TIME = 100;
uint64_t main_time = 0;
Vbtb *tb;

int main(int argc, char **argv, char **env) {
  Verilated::debug(0);
  Verilated::randReset(0);
  Verilated::traceEverOn(true);
  Verilated::commandArgs(argc, argv);
  tb = new Vbtb;
  // initialize input
  tb->clk = 0;
  tb->reset = 1;
  tb->pc_in = 0x80000000;

  while (main_time < MAX_TIME) {
    if (main_time % 2 == 1) {
      tb->clk = 1;
    } else {
      tb->clk = 0;
      tb->is_req_pc = 0;
      tb->pc_in = tb->pc_in + 4;
      printf("main_time: %d, write pc: %x\n", main_time, tb->pc_in);
    }

    if (main_time == 2) {
      tb->reset = 0;
    }

    switch (main_time) {
      // 测试1：先写入4个req_pc和4个对应的predict_target
      // 然后写入4个pc_in，数值是刚才写入的req_pc；读next_pc_out是否等于刚才的predict_target
      case 4: {
        tb->is_req_pc = 1;
        tb->req_pc = 0x80000030;
        tb->predict_target = 0x70000000;
        break;
      }
      case 6: {
        tb->is_req_pc=1;
        tb->req_pc = 0x80000034;
        tb->predict_target = 0x70000004;
        break;
      }
      case 8: {
        tb->is_req_pc = 1;
        tb->req_pc = 0x80000038;
        tb->predict_target = 0x70000008;
        break;
      }
      case 10: {
        tb->is_req_pc = 1;
        tb->req_pc = 0x8000003c;
        tb->predict_target = 0x7000000c;
        break;
      }
      case 12: {
        tb->pc_in = 0x80000030;  // When case4, pc = 0x8000000c
        tb->predict_target = 0;
        tb->req_pc = 0;
        printf("main_time: %d, write pc: %x\n", main_time, tb->pc_in);
        break;
        // 预期 next_pc_out=0x70000000
      }
      case 14: {
        // 预期 next_pc_out=0x70000004
        break;
      }
      case 16: {
        // 预期 next_pc_out=0x70000008
        break;
      }
      case 18: {
        // 预期 next_pc_out=0x7000000c
        break;
      }

      // 测试2：先写2个现有的req_pc[1]和req_pc[3]，但与测试1不同的predict_target
      // 然后写入2个pc_in，数值是req_pc[1]和req_pc[3]；读next_pc_out是否等于新的predict_target
      case 20: {
        tb->is_req_pc = 1;
        tb->req_pc = 0x80000030;
        tb->predict_target = 0x70000030;
        break;
      }
      case 22: {
        tb->is_req_pc = 1;
        tb->req_pc = 0x80000038;
        tb->predict_target = 0x70000038;
        break;
      }
      case 24: {
        tb->pc_in = 0x80000030;  // When case4, pc = 0x8000000c
        tb->predict_target = 0;
        tb->req_pc = 0;
        printf("main_time: %d, write pc: %x\n", main_time, tb->pc_in);
        break;
        // 预期 next_pc_out=0x70000000
      }
      case 26: {
        break;
      }
      case 28: {
        break;
      }
      case 30: {
        break;
      }


        // 测试3：先写2个不在现有BTB的新的req_pc，和2个对应的predict_target
        // 然后写入4个BTB现有的pc_in，读next_pc_out是否等于BTB现有predict_target
      case 32: {
        tb->is_req_pc=1;
        tb->req_pc = 0x80000050;
        tb->predict_target = 0x70000050;
        break;
      }
      case 34: {
        tb->is_req_pc=1;
        tb->req_pc = 0x80000058;
        tb->predict_target = 0x70000058;
        break;
      }
      case 36: {
        tb->pc_in = 0x80000050;  // When case36, pc = 0x8000000c
        tb->predict_target = 0;
        tb->req_pc = 0;
        printf("main_time: %d, write pc: %x\n", main_time, tb->pc_in);
        break;
        // 预期 next_pc_out=0x70000050
      }
      case 38: {
        break;// 预期 next_pc_out=0x70000058
      }
    }
    tb->eval();
    printf( 
        "main_time: %d, pc_in: %x, next_pc_out: %x, req_pc: %x, "
        "predict_target: %x, token: %d, gotten: %d, counter: "
        "%d\n",
        main_time, tb->pc_in, tb->next_pc_out, tb->req_pc, tb->predict_target,
        tb->token, tb->gotten, tb->counter);
    main_time++;
  }

  tb->final();

  delete tb;
  tb = nullptr;
  return 0;
}
