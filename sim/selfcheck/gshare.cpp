#include <verilated.h>

#include <iostream>

#include "Vgshare.h"

const uint64_t MAX_TIME = 170;
uint64_t main_time = 0;
Vgshare *tb;

int main(int argc, char **argv, char **env)
{
  Verilated::debug(0);
  Verilated::randReset(0);
  Verilated::traceEverOn(true);
  Verilated::commandArgs(argc, argv);
  tb = new Vgshare;
  // initialize input
  tb->clk = 0;
  tb->reset = 1;
  tb->pc = 0x80000000;

  while (main_time < MAX_TIME)
  {
    if (main_time % 2 == 1)
    {
      tb->clk = 1;
    }
    else
    {
      tb->clk = 0;
      tb->pc = tb->pc + 4;
      printf("main_time: %d\t write pc: %x\n", main_time, tb->pc);
    }

    if (main_time == 2)
    {
      tb->reset = 0;
    }

    switch (main_time)
    {
    // Test1:
    // Scenario: Test ten cycles, write 10 `pc` and `prev_pc` (each `prev_pc` = `pc` of the previous cycle)
    // `prev_branch_in` always set 1, `prev_take` always set 0 (i.e. each instruction does not jump)
    // Expectation: `cur_pred` is sometimes 0 or 1
    // There will be one entry in PHT table decrease 1 in each cycle and the last entry decreased will decrease to 0
    case 4:case 6:case 8:case 10:case 12:case 14:case 16:case 18:case 20:case 22:
    {
      tb->prev_pc = tb->pc - 4;
      tb->prev_branch_in = 1;
      tb->prev_taken = 0;
      break;
    }

    // Test2:
    // Scenario: Test ten cycles, write 10 `pc` and `prev_pc` (each `prev_pc` = `pc` of the previous cycle)
    // `prev_branch_in` always set 1, `prev_take` always set 1 (i.e. each instruction jump)
    // Expectation: `cur_pred` is sometimes 0 or 1
    // There will be one entry in PHT table increase 1 in each cycle and the last entry increased will increase to 3
    case 26:case 28:case 30:case 32:case 34:case 36:case 38:case 40:case 42:case 44:
    {
      tb->prev_pc = tb->pc - 4;
      tb->prev_branch_in = 1;
      tb->prev_taken = 1;
      break;
    }

    // Test3:
    // Scenario: Test many cycles, write 20 `pc` and `prev_pc` (each `prev_pc` = `pc` of the previous cycle)
    // `prev_branch_in` always set 1, `prev_take` always set 0 (i.e. each instruction does not jump)
    // Expectation: `cur_pred` is always 0 finally
    // There will be one entry in PHT table decrease 1 in each cycle and the finally all entries are 0
    case 48:case 50:case 52:case 54:case 56:case 58:case 60:case 62:case 64:case 66:case 68:case 70:case 72:case 74:case 76:case 78:case 80:case 82:case 84:case 86:case 88:case 90:case 92:case 94:case 96:case 98:case 100:case 102:case 104:case 106:case 108:case 110:case 112:case 114:case 116:case 118:case 120:case 122:case 124:case 126:case 128:case 130:case 132:case 134:case 136:case 138:case 140:case 142:case 144:case 146:
    {
      tb->prev_pc = tb->pc - 4;
      tb->prev_branch_in = 1;
      tb->prev_taken = 0;
      break;
    }
    case 148:case 150:case 152:case 154:case 156:case 158:case 160:case 162:case 164:case 166:{
      assert(tb->cur_pred == 0);
      break;
    }
    }
    tb->eval();

    printf(
        "main_time: %d\t pc: %x\t cur_pred: %d\n", main_time, tb->pc, tb->cur_pred);
    printf("PHT 0-15:\t");
    printf("%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d\n", tb->PHT0, tb->PHT1, tb->PHT2, tb->PHT3, tb->PHT4, tb->PHT5, tb->PHT6, tb->PHT7, tb->PHT8, tb->PHT9, tb->PHT10, tb->PHT11, tb->PHT12, tb->PHT13, tb->PHT14, tb->PHT15);

    main_time++;
  }

  tb->final();

  delete tb;
  tb = nullptr;
  return 0;
}
