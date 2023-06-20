#include "verilated.h"
#include "verilated_vcd_c.h"
#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <string>
#include <cstdint>
#include "Vbackend.h"

#define HALF_CYCLE 5
#define CSV_DIR "./ut/backend_input/rv64ui-p-lw.csv"

using namespace std;

const uint64_t MAX_TIME = 10000;
uint64_t main_time = 0;
Vbackend *tb;
vector<string> m_mem;

void build_mem() {
    ostringstream ostr;
    ifstream file;
    string line;

    file.open("./ut/hex/rv64ui-p-lw.hex", ios::in);
    while (getline(file, line))
    {
        m_mem.emplace_back(line);
        // std::cout << "mem[" << m_mem.size() - 1 << "] = " << line << std::endl;
    }
}

int main(int argc, char **argv, char **env) {

    VerilatedContext* contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    tb = new Vbackend{contextp};
    VerilatedVcdC* tfp = new VerilatedVcdC;
    contextp->traceEverOn(true);
    tb->trace(tfp, 0);
    tfp->open("wave.vcd");
    
    build_mem();

    // initialize input
    tb->clk = 0;
    tb->rstn = 1;
    tb->wfi_ctrl_in = 0;
    tb->trapped = 0;
    tb->valid_i = 0;
    tb->ecause_i = 0;
    tb->exception_i = 0;
    tb->uses_rs1_i = 0;
    tb->uses_rs2_i = 0;
    tb->uses_csr_i = 0;
    tb->uses_rd_i = 0;
    tb->pc_i = 0x80000000;
    tb->next_pc_i = tb->pc_i + 4;
    tb->is_alu_i = 0;
    tb->deco_alu_select_a_i = 0;
    tb->deco_alu_select_b_i = 0;
    tb->cmp_function_i = 0;
    tb->imm_data_i = 0;
    tb->half_i = 0;
    tb->alu_function_i = 0;
    tb->alu_function_modifier_i = 0;
    tb->branch_i = 0;
    tb->jump_i = 0;
    tb->load_i = 0;
    tb->store_i = 0;
    tb->load_store_size_i = 0;
    tb->load_signed_i = 0;
    tb->rs1_address_i = 0;
    tb->rs2_address_i = 0;
    tb->rd_address_i = 0;
    tb->csr_address_i = 0;
    tb->csr_data_i = 0;
    tb->csr_read_i = 0;
    tb->csr_write_i = 0;
    tb->csr_readable_i = 0;
    tb->csr_writeable_i = 0;
    tb->wfi_i = 0;
    tb->mret_i = 0;
    tb->req_ready_i = 0;
    tb->resp_valid_i = 0;
    tb->resp_data_i = 0;
    tb->is_fence_i = 0;

    // read data from csv
    ifstream fin(CSV_DIR);
    string line;
    for (int i = 0; i < 6; i++)
        getline(fin, line); // ignore the first six lines

    // variables for memory response
    uint32_t addr = 0;
    uint32_t lsq = 0;
    uint32_t size = 0;
    bool valid = 0;

    // waiting for reset = 0
    tb->clk=0;
    tb->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(HALF_CYCLE);
    main_time++;
    tb->clk=1;
    tb->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(HALF_CYCLE);
    main_time++;

    // start simulation
    while(contextp->time() < MAX_TIME) {
        if (main_time % 2 == 1) {
            // negedge
            tb->clk = 0;
            if (tb->rob_ready_out == 1) {
                // if ready then read CSV
                if (getline(fin, line)) {
                    // parse the line
                    istringstream sin(line);
                    string info;
                    vector<string> Waypoints;
                    while (getline(sin, info, ',')) {
                        Waypoints.push_back(info);
                        // std::cout << "Waypoints[" << Waypoints.size() - 1 << "] = " << info << std::endl;
                    }
                    // set input signals
                    tb->wfi_ctrl_in = 0;
                    tb->valid_i = 1;
                    tb->uses_rs1_i = stoi(Waypoints[0], nullptr, 2);
                    tb->uses_rs2_i = stoi(Waypoints[1], nullptr, 2);
                    tb->uses_csr_i = stoi(Waypoints[2], nullptr, 2);
                    tb->uses_rd_i = stoi(Waypoints[3], nullptr, 2);
                    tb->pc_i = stoll(Waypoints[4], nullptr, 16);
                    tb->next_pc_i = stoll(Waypoints[5], nullptr, 16);
                    tb->is_alu_i = stoi(Waypoints[6], nullptr, 2);
                    Waypoints[7].erase(0,2);
                    tb->deco_alu_select_a_i = stoi(Waypoints[7], nullptr, 2);
                    Waypoints[8].erase(0,2);
                    tb->deco_alu_select_b_i = stoi(Waypoints[8], nullptr, 2);
                    Waypoints[9].erase(0,2);
                    tb->cmp_function_i = stoi(Waypoints[9], nullptr, 2);
                    if (Waypoints[10].substr(0,2) == "0x") {
                        Waypoints[10].erase(0,2);
                        tb->imm_data_i = stol(Waypoints[10], nullptr, 16);
                    }
                    else if (Waypoints[10].substr(0,2) == "0b") {
                        Waypoints[10].erase(0,2);
                        tb->imm_data_i = stol(Waypoints[10], nullptr, 2);
                    }
                    else {
                        tb->imm_data_i = stol(Waypoints[10], nullptr, 2);
                    }
                    tb->half_i = stoi(Waypoints[11], nullptr, 2);
                    Waypoints[12].erase(0,2);
                    tb->alu_function_i = stoi(Waypoints[12], nullptr, 2);
                    tb->alu_function_modifier_i = stoi(Waypoints[13], nullptr, 2);
                    tb->branch_i = stoi(Waypoints[14], nullptr, 2);
                    tb->jump_i = stoi(Waypoints[15], nullptr, 2);
                    tb->load_i = stoi(Waypoints[16], nullptr, 2);
                    tb->store_i = stoi(Waypoints[17], nullptr, 2);
                    Waypoints[18].erase(0,2);
                    tb->load_store_size_i = stoi(Waypoints[18], nullptr, 2);
                    tb->load_signed_i = stoi(Waypoints[19], nullptr, 2);
                    Waypoints[20].erase(0,2);
                    tb->rs1_address_i = stoi(Waypoints[20], nullptr, 2);
                    Waypoints[21].erase(0,2);
                    tb->rs2_address_i = stoi(Waypoints[21], nullptr, 2);
                    if (Waypoints[22] != "0")
                        Waypoints[22].erase(0,2);
                    tb->rd_address_i = stoi(Waypoints[22], nullptr, 2);
                    Waypoints[23].erase(0,2);
                    tb->csr_address_i = stoi(Waypoints[23], nullptr, 2);
                    tb->csr_data_i = 0;
                    tb->csr_read_i = stoi(Waypoints[24], nullptr, 2);
                    tb->csr_write_i = stoi(Waypoints[25], nullptr, 2);
                    if (tb->csr_read_i == 1) {
                        tb->csr_readable_i = 1;
                    } else {
                        tb->csr_readable_i = 0;
                    }
                    if (tb->csr_write_i == 1) {
                        tb->csr_writeable_i = 1;
                    } else {
                        tb->csr_writeable_i = 0;
                    }
                    if (Waypoints[26].compare("True") == 1)
                        tb->wfi_i = 1;
                    else 
                        tb->wfi_i = 0;
                    if (Waypoints[27].compare("True") == 1)
                        tb->mret_i = 1;
                    else
                        tb->mret_i = 0;
                    if (tb->mret_i == 1) {
                        tb->exception_i = 1;
                        tb->ecause_i = 2;
                    } else {
                        tb->exception_i = 0;
                        tb->ecause_i = 0;
                    }
                    tb->req_ready_i = 1;
                    tb->is_fence_i = stoi(Waypoints[28], nullptr, 2);

                    // deal with memory response
                    if (valid) {
                        int32_t idx = (int32_t)(addr - 0x80000000) / 8;
                        int32_t offset = (int32_t)(addr - 0x80000000) % 8;
                        int32_t start = 15 - (int32_t)offset * 2 - pow(2, size+1) + 1;
                        int32_t end = 15 - (int32_t)offset * 2;
                        printf("idx: %x, start: %d, end: %d\n", idx, start, end);
                        if (start >= 0) {
                            if (idx >= 0 && idx < 2048) {
                                tb->resp_data_i = strtoull(m_mem.at(idx).substr(start, end).c_str(), nullptr, 16);
                            }
                        } else {
                            tb->resp_data_i = strtoull((
                                m_mem.at(idx-1).substr(16+start, 15) + m_mem.at(idx).substr(0, end)
                            ).c_str(), nullptr, 16);
                        }
                        // printf("%x\n", tb->resp_data_i);
                        tb->resp_lsq_index_i = lsq;
                        tb->resp_valid_i = 1;
                        addr = 0;
                        lsq = 0;
                        size = 0;
                        valid = 0;
                    } else {
                        tb->resp_data_i = 0;
                        tb->resp_lsq_index_i = 0;
                        tb->resp_valid_i = 0;
                    }

                } else {
                    // no line to read
                    break;
                }
            }

        } else {
            // posedge
            tb->clk = 1;
        }

        // reset
        if (main_time == 2)
            tb->rstn = 0;

        tb->eval();
        tfp->dump(contextp->time());
        contextp->timeInc(HALF_CYCLE);

        // memory request sent
        if (tb->req_valid_o == 1) {
            valid = 1;
            addr = tb->req_addr_o;
            lsq = tb->req_lsq_index_o;
            size = tb->req_size_o;
        } else {
            valid = 0;
            addr = 0;
            lsq = 0;
            size = 0;
        }

        printf( 
            "main_time: %d, clk: %d, pc: %x, req_lsq_index_o: %x, req_addr_o: %x, req_size_o: %d\n",
            main_time, tb->clk, tb->pc_i, tb->req_lsq_index_o, tb->req_addr_o, tb->req_size_o
        );

        main_time++;
    
    }

    tb->final();
    tfp->close();  
    delete tb;
    delete tfp;

    return 0;
}
