#ifndef __UNCORE_PARAMS_HPP__
#define __UNCORE_PARAMS_HPP__
#include <stdlib.h>
#include <stdint.h>

#ifndef SYNTHESIS
    // #define NO_BUS
#endif // SYNTHESIS

#define LSU_V1


// #define RCU_PRESSURE
// #define RCU_AMO_REQ
// #define RCU_MISALIGN_EXCEPTION


// global params 
/*verilator lint_off UNUSED */
const uint64_t XLEN = 64;  
const uint64_t VIRTUAL_ADDR_LEN = 32;
const uint64_t PHYSICAL_ADDR_LEN = 39;


const uint64_t L1D_BANK_LINE_DATA_SIZE = 512; // bits
const uint64_t L1D_BANK_SET_NUM = 8; // sets
const uint64_t L1D_BANK_WAY_NUM = 4;
const uint64_t L1D_BANK_ID_NUM = 8;
const uint64_t L1D_STB_ENTRY_NUM = 8;
// localparam INDEX_WIDTH = $clog2(L1D_BANK_SET_NUM);
const uint64_t L1D_INDEX_WIDTH  = 6; // LOG(L1D_BANK_SET_NUM*L1D_BANK_ID_NUM)
const uint64_t L1D_OFFSET_WIDTH = 6; // LOG(L1D_BANK_LINE_DATA_SIZE/8)
const uint64_t L1D_BIT_OFFSET_WIDTH = 9; //$clog2(L1D_BANK_LINE_DATA_SIZE)
const uint64_t L1D_TAG_WIDTH = PHYSICAL_ADDR_LEN - L1D_INDEX_WIDTH - L1D_OFFSET_WIDTH;



const uint64_t ADDR_OFFSET_LEN = L1D_OFFSET_WIDTH; // CACHE_LINE
const uint64_t ADDR_OFFSET_LOW = 0;
const uint64_t ADDR_OFFSET_UPP = ADDR_OFFSET_LOW + ADDR_OFFSET_LEN;

const uint64_t ADDR_INDEX_LEN = L1D_INDEX_WIDTH;
const uint64_t ADDR_INDEX_LOW = ADDR_OFFSET_UPP;
const uint64_t ADDR_INDEX_UPP = ADDR_INDEX_LOW + ADDR_INDEX_LEN;

const uint64_t PHYSICAL_ADDR_TAG_LEN = PHYSICAL_ADDR_LEN - ADDR_INDEX_LEN - ADDR_OFFSET_LEN;
const uint64_t PHYSICAL_ADDR_TAG_LOW = ADDR_INDEX_UPP;
const uint64_t PHYSICAL_ADDR_TAG_UPP = PHYSICAL_ADDR_LEN;

const uint64_t VIRTUAL_ADDR_TAG_LEN = VIRTUAL_ADDR_LEN - ADDR_INDEX_LEN - ADDR_OFFSET_LEN;
const uint64_t VIRTUAL_ADDR_TAG_LOW = ADDR_INDEX_UPP;
const uint64_t VIRTUAL_ADDR_TAG_UPP = VIRTUAL_ADDR_LEN;

const uint64_t IMM_LEN = 32;
const uint64_t AXI_ID_WIDTH = 10;
const uint64_t DCACHE_WB_DATA_LEN = 32;
const uint64_t RESET_VECTOR = 0x80000000;
// const uint64_t RESET_VECTOR = 0x3000_0000;

const uint64_t EXCEPTION_CAUSE_WIDTH = 4;
const uint64_t VIR_REG_ADDR_WIDTH = 5;
const uint64_t PC_WIDTH = VIRTUAL_ADDR_LEN;
const uint64_t CSR_ADDR_LEN = 12;

const uint64_t BUS_MAP_ADDR_LOW = 0x30030000;
const uint64_t BUS_MAP_ADDR_UPP = 0x3000FFFF;
const uint64_t WB_DATA_LEN = 32;

const uint64_t FAKE_MEM_ADDR_LEN = 16;
const uint64_t FAKE_MEM_SIZE = 8192; // 2 ^ 13
const uint64_t FAKE_MEM_DEPTH = FAKE_MEM_ADDR_LEN - 3; //
const uint64_t FAKE_CACHE_MSHR_DEPTH = 2;
const uint64_t FAKE_CACHE_MSHR_WIDTH = 1;
const uint64_t FAKE_CACHE_DELAY_WIDTH = 5;
const uint64_t FAKE_MEM_DELAY_BASE = 3;

// Memory Model
const uint64_t U_MODE = 0;
const uint64_t S_MODE = 1;
const uint64_t M_MODE = 3;

const uint64_t ACCESS_MODE_READ = 0;
const uint64_t ACCESS_MODE_WRITE = 1;
const uint64_t ACCESS_MODE_EXECUTE = 2;

const uint64_t SATP_PPN_WIDTH = 44;
const uint64_t SATP_ASID_WIDTH = 16;
const uint64_t SATP_MODE_WIDTH = 4;

// ROB 
const uint64_t ROB_SIZE = 16;
const uint64_t ROB_SIZE_WIDTH = 4;
const uint64_t ROB_INDEX_WIDTH = ROB_SIZE_WIDTH;
const uint64_t FRLIST_DATA_WIDTH = 6;
const uint64_t FRLIST_DEPTH = 35; //p0 is not in the fifo FRLIST_DEPTH = PHY_REG_SIZE - 1
const uint64_t FRLIST_DEPTH_WIDTH = 6; //combine with physical register later
const uint64_t PHY_REG_SIZE = 36;
const uint64_t PHY_REG_ADDR_WIDTH = 6;

// exception code
const uint64_t EXCEPTION_INSTR_ADDR_MISALIGNED =  0x0;
const uint64_t EXCEPTION_INSTR_ACCESS_FAULT =  0x1;
const uint64_t EXCEPTION_ILLEGAL_INSTRUCTION =  0x2;
const uint64_t EXCEPTION_BREAKPOINT =  0x3;
const uint64_t EXCEPTION_LOAD_ADDR_MISALIGNED =  0x4;
const uint64_t EXCEPTION_LOAD_ACCESS_FAULT =  0x5;
const uint64_t EXCEPTION_STORE_ADDR_MISALIGNED =  0x6;
const uint64_t EXCEPTION_STORE_ACCESS_FAULT =  0x7;
const uint64_t EXCEPTION_ENV_CALL_U =  0x8;
const uint64_t EXCEPTION_ENV_CALL_S =  0x9;
// const uint64_t  =  0xa; // NO EXCEPTION IN 10
const uint64_t EXCEPTION_ENV_CALL_M =  0xb;
const uint64_t EXCEPTION_INSTR_PAGE_FAULT =  0xc;
const uint64_t EXCEPTION_LOAD_PAGE_FAULT =  0xd;
// const uint64_t EXCEPTION_ =  0xe; // NO EXCEPTION IN 14
const uint64_t EXCEPTION_STORE_PAGE_FAULT =  0xf;

// These are the ALU values also used in the ISA
const uint64_t ALU_ADD_SUB = 0b000;
const uint64_t ALU_SLL     = 0b001;
const uint64_t ALU_SLT     = 0b010;
const uint64_t ALU_SLTU    = 0b011;
const uint64_t ALU_XOR     = 0b100;
const uint64_t ALU_SRL_SRA = 0b101;
const uint64_t ALU_OR      = 0b110;
const uint64_t ALU_AND_CLR = 0b111;

const uint64_t ALU_SEL_REG = 0b00;
const uint64_t ALU_SEL_IMM = 0b01;
const uint64_t ALU_SEL_PC  = 0b10;
const uint64_t ALU_SEL_CSR = 0b11;

const uint64_t CMP_EQ  = 0b000;
const uint64_t CMP_NE  = 0b001;
const uint64_t CMP_LT  = 0b110;
const uint64_t CMP_GE  = 0b111;
const uint64_t CMP_LTU = 0b100;
const uint64_t CMP_GEU = 0b101;

const uint64_t WRITE_SEL_ALU     = 0b00;
const uint64_t WRITE_SEL_CSR     = 0b01;
const uint64_t WRITE_SEL_LOAD    = 0b10;
const uint64_t WRITE_SEL_NEXT_PC = 0b11;


const uint64_t LDU_OP_WIDTH = 4;
const uint64_t LDU_LB = 0;
const uint64_t LDU_LH = 1;
const uint64_t LDU_LW = 2;
const uint64_t LDU_LD = 3;
const uint64_t LDU_LBU = 4;
const uint64_t LDU_LHU = 5;
const uint64_t LDU_LWU = 6;


const uint64_t STU_OP_WIDTH = 5;
const uint64_t STU_SB = 0;
const uint64_t STU_SH = 1;
const uint64_t STU_SW = 2;
const uint64_t STU_SD = 3;
// fence
// TODO: fixed FEMCE
const uint64_t STU_FENCE = 4;
const uint64_t STU_SFENCE_VMA = 5;
const uint64_t STU_FENCE_I = 6;
// amo 
const uint64_t STU_SCW = 7;
const uint64_t STU_SCD = 8;
const uint64_t STU_LRW = 9;
const uint64_t STU_LRD = 10;
// const uint64_t STU_SCD = 7;
const uint64_t STU_AMOSWAPW = 11;
const uint64_t STU_AMOSWAPD = 12;
const uint64_t STU_AMOADDW = 13;
const uint64_t STU_AMOADDD = 14;
const uint64_t STU_AMOANDW = 15;
const uint64_t STU_AMOANDD = 16;
const uint64_t STU_AMOORW = 17;
const uint64_t STU_AMOORD = 18;
const uint64_t STU_AMOXORW = 19;
const uint64_t STU_AMOXORD = 20;
const uint64_t STU_AMOMAXW = 21;
const uint64_t STU_AMOMAXD = 22;
const uint64_t STU_AMOMAXUW = 23;
const uint64_t STU_AMOMAXUD = 24;
const uint64_t STU_AMOMINW = 25;
const uint64_t STU_AMOMIND = 26;
const uint64_t STU_AMOMINUW = 27;
const uint64_t STU_AMOMINUD = 28;

const uint64_t LS_OPCODE_WIDTH = LDU_OP_WIDTH > STU_OP_WIDTH ? LDU_OP_WIDTH : STU_OP_WIDTH;
// PMA
const uint64_t IO_ADDR_UPP = 0X1000;
const uint64_t IO_ADDR_LOW = 0X1004;

// LSU 
#ifdef LSU_V1
    const uint64_t LSQ_DEPTH = 8;

    const uint64_t LSQ_ENTRY_VLD_WIDTH = 1;
    const uint64_t LSQ_ENTRY_VLD_WIDTH_LOW = 0;
    const uint64_t LSQ_ENTRY_VLD_WIDTH_UPP = LSQ_ENTRY_VLD_WIDTH_LOW + LSQ_ENTRY_VLD_WIDTH;

    const uint64_t LSQ_ENTRY_LS_WIDTH = 1;
    const uint64_t LSQ_ENTRY_LS_WIDTH_LOW = LSQ_ENTRY_VLD_WIDTH_UPP; // 0: ld/st 1: usigned or not 2-3:width 4:sc/lr
    const uint64_t LSQ_ENTRY_LS_WIDTH_UPP = LSQ_ENTRY_LS_WIDTH_LOW + LSQ_ENTRY_LS_WIDTH; // 0: ld/st 1: usigned or not 2-3:width 4:sc/lr

    const uint64_t LSQ_ENTRY_OPCODE_WIDTH = LS_OPCODE_WIDTH; // 0: ld/st 1: usigned or not 2-3:width 4:sc/lr
    const uint64_t LSQ_ENTRY_OPCODE_WIDTH_LOW = LSQ_ENTRY_LS_WIDTH_UPP; // 0: ld/st 1: usigned or not 2-3:width 4:sc/lr
    const uint64_t LSQ_ENTRY_OPCODE_WIDTH_UPP = LSQ_ENTRY_VLD_WIDTH_UPP + LSQ_ENTRY_OPCODE_WIDTH; // 0: ld/st 1: usigned or not 2-3:width 4:sc/lr

    const uint64_t LSQ_ENTRY_FENCED_WIDTH = 1;
    const uint64_t LSQ_ENTRY_FENCED_WIDTH_LOW = LSQ_ENTRY_OPCODE_WIDTH_UPP;
    const uint64_t LSQ_ENTRY_FENCED_WIDTH_UPP = LSQ_ENTRY_FENCED_WIDTH_LOW + LSQ_ENTRY_FENCED_WIDTH;

    const uint64_t LSQ_ENTRY_TAG_WIDTH = VIRTUAL_ADDR_TAG_LEN > PHYSICAL_ADDR_TAG_LEN ? VIRTUAL_ADDR_TAG_LEN : PHYSICAL_ADDR_TAG_LEN;
    const uint64_t LSQ_ENTRY_TAG_WIDTH_LOW = LSQ_ENTRY_FENCED_WIDTH_UPP;
    const uint64_t LSQ_ENTRY_TAG_WIDTH_UPP = LSQ_ENTRY_TAG_WIDTH_LOW + LSQ_ENTRY_TAG_WIDTH;

    const uint64_t LSQ_ENTRY_INDEX_WIDTH = ADDR_INDEX_LEN;
    const uint64_t LSQ_ENTRY_INDEX_WIDTH_LOW = LSQ_ENTRY_TAG_WIDTH_UPP;
    const uint64_t LSQ_ENTRY_INDEX_WIDTH_UPP = LSQ_ENTRY_INDEX_WIDTH_LOW + LSQ_ENTRY_INDEX_WIDTH;

    const uint64_t LSQ_ENTRY_OFFSET_WIDTH = ADDR_OFFSET_LEN;
    const uint64_t LSQ_ENTRY_OFFSET_WIDTH_LOW = LSQ_ENTRY_INDEX_WIDTH_UPP;
    const uint64_t LSQ_ENTRY_OFFSET_WIDTH_UPP = LSQ_ENTRY_OFFSET_WIDTH_LOW + ADDR_OFFSET_LEN;

    const uint64_t LSQ_ENTRY_ROB_INDEX_WIDTH = ROB_INDEX_WIDTH;
    const uint64_t LSQ_ENTRY_ROB_INDEX_WIDTH_LOW = LSQ_ENTRY_OFFSET_WIDTH_UPP;
    const uint64_t LSQ_ENTRY_ROB_INDEX_WIDTH_UPP = LSQ_ENTRY_ROB_INDEX_WIDTH_LOW + LSQ_ENTRY_ROB_INDEX_WIDTH;

    const uint64_t LSQ_ENTRY_VIRT_WIDTH = 1;
    const uint64_t LSQ_ENTRY_VIRT_WIDTH_LOW = LSQ_ENTRY_ROB_INDEX_WIDTH_UPP;
    const uint64_t LSQ_ENTRY_VIRT_WIDTH_UPP = LSQ_ENTRY_VIRT_WIDTH_LOW + LSQ_ENTRY_VIRT_WIDTH;

    const uint64_t LSQ_ENTRY_AWAKE_WIDTH = 1;
    const uint64_t LSQ_ENTRY_AWAKE_WIDTH_LOW = LSQ_ENTRY_VIRT_WIDTH_UPP;
    const uint64_t LSQ_ENTRY_AWAKE_WIDTH_UPP = LSQ_ENTRY_AWAKE_WIDTH_LOW + LSQ_ENTRY_AWAKE_WIDTH;

    const uint64_t LSQ_ENTRY_EXEC_WIDTH = 1;
    const uint64_t LSQ_ENTRY_EXEC_WIDTH_LOW = LSQ_ENTRY_AWAKE_WIDTH_UPP;
    const uint64_t LSQ_ENTRY_EXEC_WIDTH_UPP = LSQ_ENTRY_EXEC_WIDTH_LOW + LSQ_ENTRY_EXEC_WIDTH;

    const uint64_t LSQ_ENTRY_SUCC_WIDTH = 1;
    const uint64_t LSQ_ENTRY_SUCC_WIDTH_LOW = LSQ_ENTRY_EXEC_WIDTH_UPP;
    const uint64_t LSQ_ENTRY_SUCC_WIDTH_UPP = LSQ_ENTRY_SUCC_WIDTH_LOW + LSQ_ENTRY_SUCC_WIDTH;

    const uint64_t LSQ_ENTRY_RD_ADDR_WIDTH =PHY_REG_ADDR_WIDTH;
    const uint64_t LSQ_ENTRY_RD_ADDR_WIDTH_LOW =LSQ_ENTRY_SUCC_WIDTH_UPP;
    const uint64_t LSQ_ENTRY_RD_ADDR_WIDTH_UPP =LSQ_ENTRY_RD_ADDR_WIDTH_LOW + LSQ_ENTRY_RD_ADDR_WIDTH;

    const uint64_t LSQ_ENTRY_DATA_WIDTH = XLEN;
    const uint64_t LSQ_ENTRY_DATA_WIDTH_LOW = LSQ_ENTRY_RD_ADDR_WIDTH_UPP;
    const uint64_t LSQ_ENTRY_DATA_WIDTH_UPP = LSQ_ENTRY_DATA_WIDTH_LOW + LSQ_ENTRY_DATA_WIDTH;

    const uint64_t LSQ_ENTRY_WIDTH = LSQ_ENTRY_VLD_WIDTH + LSQ_ENTRY_OPCODE_WIDTH + LSQ_ENTRY_FENCED_WIDTH + LSQ_ENTRY_TAG_WIDTH + 
                                    LSQ_ENTRY_INDEX_WIDTH + LSQ_ENTRY_OFFSET_WIDTH + LSQ_ENTRY_ROB_INDEX_WIDTH + LSQ_ENTRY_VIRT_WIDTH + 
                                    LSQ_ENTRY_AWAKE_WIDTH + LSQ_ENTRY_EXEC_WIDTH + LSQ_ENTRY_SUCC_WIDTH + LSQ_ENTRY_RD_ADDR_WIDTH + 
                                    LSQ_ENTRY_DATA_WIDTH;
#endif // LSU_V1
//FU
const uint64_t UNITS_NUM = 5;
const uint64_t UNITS_NUM_WIDTH = 3;

// fence function code in decoder
const uint64_t DEC_FENCE = 0;
const uint64_t DEC_FENCE_I = 1;
const uint64_t DEC_SFENCE_VMA = 2;



#endif // __UNCORE_PARAMS_HPP__

