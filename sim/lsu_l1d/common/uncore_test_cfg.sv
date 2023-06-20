// `define PERFECT_DTLB
`define PERFECT_MEMORY

`ifndef PERFECT_MEM_FILE
`define PERFECT_MEM_FILE = "\"./sim/lsu_l1d/mem\""
`endif //PERFECT_MEM_FILE

`ifndef SIM_DIR
`define SIM_DIR = "\"./sim/lsu_l1d/\""
`endif //SIM_DIR



`ifndef RANDOM_TESTCASE_NUM
`define RANDOM_TESTCASE_NUM 50
`endif //RANDOM_TESTCASE_NUM

`ifndef MAX_TIME
`define MAX_TIME 30000
`endif //MAX_TIME

`ifdef LOG_LV2
    `define LOG_LV1
`endif // LOG_LV1

`define RVH_L1D

`define DISABLE_PMP