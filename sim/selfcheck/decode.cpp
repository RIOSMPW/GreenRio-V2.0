#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include<fstream>
#include<typeinfo>
#include<cstdint>
#include "Vdecode.h"
#define HALF_CYCLE 5

using namespace std;

int main(int argc, char **argv, char **env) {
    VerilatedContext* contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    Vdecode* top = new Vdecode{contextp};
    VerilatedVcdC* tfp =new VerilatedVcdC;  //初始化VCD对象指针
    contextp->traceEverOn(true); //打开追踪
    top->trace(tfp, 0);
    tfp->open("decode.vcd");
    uint32_t instruction_array[100] = {0};
    ifstream infile;//定义读取文件流，相对于程序来说是in
	infile.open("decode_readin.txt");//打开文件
    char c;
    for (int i = 0; i < 43; i++)//定义行循环
	{
        for (int j = 0; j < 8; j++)//定义列循环
		{
            infile >> c;
            instruction_array[i] *= 16;
            if(c>='0' && c<='9')
                instruction_array[i] += (c-'0');
            if(c>='a' && c<= 'f')
                instruction_array[i] += ((c-'a') + 10);
		}
	}
	infile.close();//读取完成之后关闭文件
    int time = 0;
    top->clk = 0;
    top->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(HALF_CYCLE);
    while(contextp->time()<440){
        top->instruction_in = instruction_array[time];
        time ++;
        top->clk = 1;
        top->eval();
        tfp->dump(contextp->time());
        contextp->timeInc(HALF_CYCLE);
        top->clk = 0;
        top->eval();
        tfp->dump(contextp->time());
        contextp->timeInc(HALF_CYCLE);
    }
    top->final();
    // delete top;
    tfp->close();
    // delete contextp;
    return 0;
}
