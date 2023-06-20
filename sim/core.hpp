
// #include "Vcore.h"
// #include "Verilated.h"
#include "verilated_vcd_c.h"

#include "memory.hpp"

#define HALF_CYCLE 100

#ifdef DUMP_WAVE
struct Core { //one core consists of an Vcore(verilated model and a memeory Cmodel)
    Vhehe* core_logic;
    MagicMemory memory;
    VerilatedContext* contextp;
    VerilatedVcdC* tfp;
    double cycle_num;
    double ins_num; //these two varible are used to calculate IPC
    void reset();
    void cycle();
    void core_init(const char* vcdname);
    void close();
};

#else

struct Core { //one core consists of an Vcore(verilated model and a memeory Cmodel)
    Vhehe* core_logic;
    MagicMemory memory;
    VerilatedContext* contextp;
    double cycle_num;
    double ins_num; //these two varible are used to calculate IPC
    void reset();
    void cycle();
    void core_init(const char* vcdname);
    void close();
};
#endif

