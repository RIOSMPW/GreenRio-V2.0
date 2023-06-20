#include "Vcore_empty.h"


#include <iostream>
#include <vector>
#include <fstream>
#include <string>
#include <sstream>
#include <bitset>
#include <semaphore.h>
#include <pthread.h>
#include <unistd.h>
#include <queue>
#include <set>
#include <stdlib.h>

#include <verilated.h>

using namespace std;

const uint64_t MAX_TIME = 10;
uint64_t main_time = 0;
Vcore_empty* core_empty;


int main() {
    int main_time = 0;
    std::vector<std::string> m_mem;
    string line_bit;

    Verilated::traceEverOn(true);
    core_empty = new Vcore_empty;

    ostringstream ostr;
    ifstream file;
    string line;

    // ostr << "elf2hex 4 2048 " << "../rv64ui-p-and" << " 2147483648 > elf.hex" ;
    file.open("./elf2hex/rv64ui-p-addi_elf", ios::in);
    

    
    while (getline(file, line))
    {
        // if (line.empty()) ERROR("Invalid hex file format!\n");
        // if (line.size() != 16) ERROR("The hex file is not in 64-bit format!\n");
        m_mem.emplace_back(line);
        // std::cout << "mem[" << m_mem.size() - 1 << "] = " << line << std::endl;
    }

    core_empty->clk = 0;
    core_empty->reset = 0;
    core_empty->meip = 0;
    uint64_t idx = 0;

    while(main_time < MAX_TIME){
        if(main_time % 2){
            //uint32_t x = strtoull(m_mem.at(idx).c_str(), nullptr, 16);
            unsigned int x;
            unsigned int icache_finding = 0;
            unsigned int temp_ins;
            unsigned int real_icache_pc;
            unsigned int real_dcache_pc;

            std::istringstream iss(m_mem.at(idx));
            iss >> std::hex >> x;
            core_empty->clk = 1;
            core_empty->ext_read_data = x;
            
            idx++; 
            if(core_empty->icache_resp_ready_o=1 && core_empty->icache_resp_valid_i){
                core_empty->insn_i = temp_ins;
                icache_finding=0; 
                core_empty->insn_i=temp_ins;
                core_empty->icache_req_ready_i=1;               
            }
            if (core_empty->icache_req_valid_o=1 && core_empty->icache_req_ready_i ){
                icache_finding=1;
                temp_ins=getins(core_empty->icache_req_addr) 
            }
            
            if(core_empty->dcache_req_valid_o=1){
            }
        }
        else{
            core_empty->clk = 0;
            if (core_empty->icache_req_valid_o=1 && core_empty->icache_req_ready_i ){
                core_empty->icache_req_valid_o=0;
            }
            if(core_empty->icache_resp_ready_o=1 && core_empty->icache_resp_valid_i){
                core_empty->icache_resp_valid_i=0
            }
        }
        std::cout << "idx=" << idx << std::endl;
        std::cout << "ext_address=" << core_empty->ext_address << std::endl;
        main_time ++;

    }

    core_empty->final();
    delete core_empty;
    exit(0);

}
int getins(int pc){
    int line=(pc-2147483648)/8;
    if ((pc-2147483648) % 8 == 0)
        return//第line的前8位
    else
        return//第line的后8位
}
