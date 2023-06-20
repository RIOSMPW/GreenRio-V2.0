#include "core.hpp"
#include <cstring>
#include <svdpi.h>
#include <stdio.h>
#include <stdint.h>
#include <vector>
#include <cstdlib>

extern std::vector<long long>* preg;  //在C++中维护一个物理寄存器堆来完成同步
extern "C"{

extern FILE* cosim_log;
#define coprint(...) fprintf(cosim_log, __VA_ARGS__)

uint32_t bit32_tailor(int origin, int left, int right){ // put the result at lowest position of the return value
    uint32_t mask = 1;
    uint32_t mask_width = left - right;
    for(int i = 0; i < mask_width; i++){
        mask <<= 1;
        mask++;
    }
    return (origin >> right) & mask;
}

//insert into phsical_regfile.v to sync preg in C++
extern void preg_sync(svLogic alu_valid, svLogic lsu_valid, long long alu_data_in, long long lsu_data_in, int alu_address, int lsu_address){
    if(alu_valid & (alu_address != 0)){
        // if(alu_address == 0x23){
        //     printf("!! 0x%lx\n", alu_data_in);
        // }
        preg->at(alu_address) = alu_data_in;
    }
    if(lsu_valid & (lsu_address != 0)){
        preg->at(lsu_address) = lsu_data_in;
    }
    preg->at(0) = 0;
}



bool csr_monitor_read = false;  //当发射了一条csr指令时，当它在写csr的过程中就将其打印下来，这个必然是下个commit的结果
bool csr_need_print = false; //只有特定的csr被修改时才需要打印
char const *csr_name;
long long csr_value;

// char* csr_name_translate(int address){
//     switch(address){
//         case 0x300: return "mstatus";
//         case 0x344: return "mip"; 
//         case 0x304: return "mie"; 
//         case 0x305: return "mtvec"; 
//         case 0x340: return "mscratch"; 
//         case 0x341: return "mepc"; 
//         case 0x342: return "mcause"; 
//         case 0xb00: return "mcycle"; 
//         case 0xb01: return "mtime"; 
//         case 0xb02: return "instret"; 
//         case 0xbc0: return "mtimecmp"; 
//     }
//     return "what";
// }

extern void csr_monitor(int address, svLogic csr_write_valid, long long write_data){ //将信息保存下来， 在commit时使用
    if(csr_monitor_read && csr_write_valid){
        // printf("3 %s\n", csr_name);
        csr_need_print = true;
        switch(address){
            case 0x305:  //mtvec
                csr_value = write_data & 0xfffffffffffffffc;
                break;
            case 0x340:  //mscratch
                csr_value = write_data;
                break;
            case 0x341: //mepc    note that in hehe it's 32bit
                csr_value = write_data;
                break;
            case 0x342: //mcuse
                csr_value = 0x800000000000000f & write_data; 
                break;
        }
    }
}

//embed this function in rcu, when one instruction is commited, print it in the log file  
extern void log_print(svLogic co_commit, int co_pc_in, svLogic co_store_in, svLogic co_fence, svLogic co_mret, svLogic co_wfi,  svLogic co_uses_csr, int co_rob_rd, svLogic co_csr_iss_ctrl, int co_prf_name, int co_csr_address){
    if(co_commit){
        coprint("-----\n");
        coprint("0x%08X\n", co_pc_in);
        // if(co_pc_in == 0x80000278)
        //     coprint("x%d <- 0x%016lX\n", co_rob_rd, preg->at(co_prf_name));
        if(co_uses_csr){  //Zicsr
            // printf("4 %s\n", csr_name_translate(co_csr_address));
            if(csr_need_print){
                // printf("2 %s\n", csr_name);
                coprint("CSR %s <- 0x%016lX\n", csr_name, csr_value);
                csr_need_print = false;
            }
            if(co_rob_rd && csr_monitor_read){
                coprint("x%d <- 0x%016lX\n", co_rob_rd, preg->at(co_prf_name));
            }
            csr_monitor_read = false;
        }else if(co_fence){ //fence
            // coprint("fence\n");
        }else if(co_mret){
            // coprint("mret\n");
        }else if(co_wfi){
            // coprint("wfi\n");
        }else if(co_store_in){
        }else {
            if(!co_uses_csr){
                if(co_rob_rd){
                    // if(co_pc_in == 0x80000278){
                        // printf("now rd: %lx\n", co_prf_name);
                    //     printf("??? 0x%lx\n", preg->at(co_prf_name));
                    // }
                    // printf("x%d <- 0x%016lX\n", co_rob_rd, preg->at(co_prf_name));
                    coprint("x%d <- 0x%016lX\n", co_rob_rd, preg->at(co_prf_name));
                }
                    
            }
        }
    }
    if(co_csr_iss_ctrl){
        csr_monitor_read = false;
        switch(co_csr_address){
            case 0x305:  //mtvec
                csr_name = "mtvec";
                // printf("5 pc: 0x%08X\n", co_pc_in);
                csr_monitor_read = true;
                break;
            case 0x340:  //mscratch
                csr_name = "mscratch";
                csr_monitor_read = true;
                break;
            case 0x341: //mepc    note that in hehe it's 32bit
                csr_name = "mepc";
                csr_monitor_read = true;
                break;
            case 0x342: //mcause
                csr_name = "mcause";
                csr_monitor_read = true;
                break;
        }
    }
}

}



