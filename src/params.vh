`ifndef PARAMS_VH
`define PARAMS_VH
// MACROS
// `define LSU_SELFCHECK   
// `define LSU_ALU_SELFCHECK
`define CALCULATING_IPC
`define COSIM
`define EXITER
`define USE_NBLSU
// `ifndef SYNTHESIS
// `include "src/hehe_cfg.vh"
// `endif // SYNTHESIS

`define sstatus_mxr 19:19
`define sstatus_sum 18:18
`define LSU_V1

// global params 
/*verilator lint_off UNUSED */
parameter XLEN = 64;  
parameter INS_LEN = 32; 


parameter VIRTUAL_ADDR_LEN = 39;
parameter PHYSICAL_ADDR_LEN = 56;


parameter L1D_INDEX_WIDTH  = 1; // LOG(L1D_BANK_SET_NUM*L1D_BANK_ID_NUM)
parameter L1D_OFFSET_WIDTH = 6; // LOG(L1D_BANK_LINE_DATA_SIZE/8)
parameter L1D_BIT_OFFSET_WIDTH = 9; //$clog2(L1D_BANK_LINE_DATA_SIZE)
parameter L1D_TAG_WIDTH = PHYSICAL_ADDR_LEN - L1D_INDEX_WIDTH - L1D_OFFSET_WIDTH;

parameter ADDR_OFFSET_LEN = 6; // CACHE_LINE
parameter ADDR_OFFSET_LOW = 0;
parameter ADDR_OFFSET_UPP = ADDR_OFFSET_LOW + ADDR_OFFSET_LEN;

parameter ADDR_INDEX_LEN = 6;
parameter ADDR_INDEX_LOW = ADDR_OFFSET_UPP;
parameter ADDR_INDEX_UPP = ADDR_INDEX_LOW + ADDR_INDEX_LEN;

parameter PPN_WIDTH = PHYSICAL_ADDR_LEN - ADDR_INDEX_LEN - ADDR_OFFSET_LEN;
parameter VPN_WIDTH = VIRTUAL_ADDR_LEN - ADDR_INDEX_LEN - ADDR_OFFSET_LEN;

parameter PHYSICAL_ADDR_TAG_LEN = PPN_WIDTH;
parameter PHYSICAL_ADDR_TAG_LOW = ADDR_INDEX_UPP;
parameter PHYSICAL_ADDR_TAG_UPP = PHYSICAL_ADDR_LEN;

parameter VIRTUAL_ADDR_TAG_LEN = VPN_WIDTH;
parameter VIRTUAL_ADDR_TAG_LOW = ADDR_INDEX_UPP;
parameter VIRTUAL_ADDR_TAG_UPP = VIRTUAL_ADDR_LEN;

parameter L1D_BANK_LINE_DATA_SIZE = 512; // bits
parameter L1D_BANK_SET_NUM = 8; // sets
parameter L1D_BANK_WAY_NUM = 4;
parameter L1D_BANK_ID_NUM = 8;
parameter L1D_STB_ENTRY_NUM = 8;
// localparam INDEX_WIDTH = $clog2(L1D_BANK_SET_NUM);


parameter IMM_LEN = 32;
parameter AXI_ID_WIDTH = 10;
parameter DCACHE_WB_DATA_LEN = 32;
parameter RESET_VECTOR = 39'h8000_0000;
// parameter RESET_VECTOR = 32'h3000_0000;

parameter EXCEPTION_CAUSE_WIDTH = 5;
// parameter PHY_REG_ADDR_WIDTH = 6;
parameter VIR_REG_ADDR_WIDTH = 5;
parameter PC_WIDTH = VIRTUAL_ADDR_LEN;
parameter CSR_ADDR_LEN = 12;

parameter BUS_MAP_ADDR_LOW = 32'h3003_0000;
parameter BUS_MAP_ADDR_UPP = 32'h3000_FFFF;
parameter WB_DATA_LEN = 32;

parameter FAKE_MEM_ADDR_LEN = 16;
parameter FAKE_MEM_SIZE = 8192; // 2 ^ 13
parameter FAKE_MEM_DEPTH = FAKE_MEM_ADDR_LEN - 3; //
parameter FAKE_CACHE_MSHR_DEPTH = 2;
parameter FAKE_CACHE_MSHR_WIDTH = 1;
parameter FAKE_CACHE_DELAY_WIDTH = 5;
parameter FAKE_MEM_DELAY_BASE = 3;

// Memory Model
parameter U_MODE = 0;
parameter S_MODE = 1;
parameter M_MODE = 3;

parameter ACCESS_MODE_READ = 0;
parameter ACCESS_MODE_WRITE = 1;
parameter ACCESS_MODE_EXECUTE = 2;

parameter SATP_PPN_WIDTH = 44;
parameter SATP_ASID_WIDTH = 16;
parameter SATP_MODE_WIDTH = 4;

//fetch
parameter PMP_ENTRY_COUNT = 8                                           ;
parameter BTB_SIZE = 4                                                  ;
parameter BTB_WIDTH = 2                                                 ; //log2(up)
parameter GSHARE_WIDTH = 4                                              ;
parameter PHT_LEN = 16                                                  ;
parameter INS_BUFFER_DATA = 128                                         ;
parameter INS_BUFFER_SIZE = 2                                           ;     //need to set to 8
parameter INS_BUFFER_SIZE_WIDTH = 1                                     ;     //log2 (up)
parameter IFQ_DEPTH = 3                                                 ;
parameter FETCH_WIDTH = 128                                             ;
parameter L1I_OFFSET_WIDTH = 4                                          ;
parameter MODE_WIDTH = 4                                                ;
parameter ASID_WIDTH = 16                                               ;
// parameter PPN_WIDTH = 44                                                ;
parameter L1I_INDEX_WIDTH = 8 + L1I_OFFSET_WIDTH                        ;
parameter L1I_TAG_WIDTH = PC_WIDTH - L1I_INDEX_WIDTH ; 
parameter TRANS_ID_WIDTH = 3                                            ;
parameter PTE_WIDTH = 64                                                ;
// parameter VPN_WIDTH = 27                                                ;
parameter PAGE_LVL_WIDTH = $clog2(VPN_WIDTH/9)                          ;
parameter PMPCFG_ENTRY_COUNT = PMP_ENTRY_COUNT / 8                      ;

parameter PADDR_WIDTH = PHYSICAL_ADDR_LEN                                                 ;
parameter INDEX_WIDTH = 8                                                  ;
parameter SIZE_ELEMENT = 16                                                ;
parameter NUM_ELEMENTS = INS_BUFFER_SIZE * INS_BUFFER_DATA / SIZE_ELEMENT  ;
parameter PTR_WIDTH = $clog2(NUM_ELEMENTS)                                 ;
parameter NUM_ELEMENTS_PER_LINE = NUM_ELEMENTS / INS_BUFFER_SIZE           ;
// RCU
parameter ROB_SIZE = 16;
parameter ROB_SIZE_WIDTH = 4;
parameter ROB_INDEX_WIDTH = ROB_SIZE_WIDTH;
parameter PHY_REG_SIZE = 48;
parameter PHY_REG_ADDR_WIDTH = 6; 
parameter FRLIST_DATA_WIDTH = 6;
parameter FRLIST_DEPTH = PHY_REG_SIZE - 1; //p0 is not in the fifo FRLIST_DEPTH = PHY_REG_SIZE - 1
parameter FRLIST_DEPTH_WIDTH = 6; //combine with physical register later

parameter MD_QUEUE_DEPTH = 4;
parameter MD_QUEUE_DEPTH_WIDTH = 2;

parameter LSU_QUEUE_DEPTH = 4;
parameter LSU_QUEUE_DEPTH_WIDTH = 2;


// exception code
parameter EXCEPTION_INSTR_ADDR_MISALIGNED =  5'h0;
parameter EXCEPTION_INSTR_ACCESS_FAULT =  5'h1;
parameter EXCEPTION_ILLEGAL_INSTRUCTION =  5'h2;
parameter EXCEPTION_BREAKPOINT =  5'h3;
parameter EXCEPTION_LOAD_ADDR_MISALIGNED =  5'h4;
parameter EXCEPTION_LOAD_ACCESS_FAULT =  5'h5;
parameter EXCEPTION_STORE_ADDR_MISALIGNED =  5'h6;
parameter EXCEPTION_STORE_ACCESS_FAULT =  5'h7;
parameter EXCEPTION_ENV_CALL_U =  5'h8;
parameter EXCEPTION_ENV_CALL_S =  5'h9;
// parameter  =  4'ha; // NO EXCEPTION IN 10
parameter EXCEPTION_ENV_CALL_M =  5'hb;
parameter EXCEPTION_INSTR_PAGE_FAULT =  5'hc;
parameter EXCEPTION_LOAD_PAGE_FAULT =  5'hd;
// parameter EXCEPTION_ =  4'he; // NO EXCEPTION IN 14
parameter INTERRUPT_TIMER_MACHINE           = 5'h17;
parameter INTERRUPT_TIMER_SUPERVISOR        = 5'h15;
parameter INTERRUPT_SOFTWARE_MACHINE        = 5'h13;
parameter INTERRUPT_SOFTWARE_SUPERVISOR     = 5'h11;
parameter INTERRUPT_EXTERNAL                = 5'h1b;
parameter EXCEPTION_STORE_PAGE_FAULT =  5'hf;

// These are the ALU values also used in the ISA
parameter ALU_ADD_SUB = 3'b000;
parameter ALU_SLL     = 3'b001;
parameter ALU_SLT     = 3'b010;
parameter ALU_SLTU    = 3'b011;
parameter ALU_XOR     = 3'b100;
parameter ALU_SRL_SRA = 3'b101;
parameter ALU_OR      = 3'b110;
parameter ALU_AND_CLR = 3'b111;

parameter ALU_SEL_REG = 2'b00;
parameter ALU_SEL_IMM = 2'b01;
parameter ALU_SEL_PC  = 2'b10;
parameter ALU_SEL_CSR = 2'b11;

// MulDiv Operation Type
parameter MD_MUL      =  1'd0;
parameter MD_DIV      =  1'd1;

// Multiplication
parameter MUL_OP_MUL      =   3'd0;
parameter MUL_OP_MULH     =   3'd1;
parameter MUL_OP_MULHSU   =   3'd2;
parameter MUL_OP_MULHU    =   3'd3;

parameter XLEN_M_IMMLEN = XLEN - IMM_LEN;
parameter XLEN_M_PCWIDTH = XLEN - PC_WIDTH;



// MMU 
parameter PTW_ID_WIDTH = 1;
parameter EXCP_CAUSE_WIDTH = EXCEPTION_CAUSE_WIDTH;


parameter TRANSLATE_WIDTH  = 1;
parameter DTLB_TRANSLATE_WIDTH = 1;
parameter DTLB_ENTRY_COUNT = 32;
parameter DTLB_MSHR_COUNT = 4;
parameter DTLB_TRANS_ID_WIDTH = 3;
    
parameter ITLB_TRANSLATE_WIDTH = 1;
parameter ITLB_ENTRY_COUNT = 32;
parameter ITLB_MSHR_COUNT = 1;
parameter ITLB_TRANS_ID_WIDTH = 3;

parameter PMP_ACCESS_TYPE_WIDTH  = 1;
parameter PMP_ACCESS_TYPE_R = 0;
parameter PMP_ACCESS_TYPE_W = 1;
parameter PMP_ACCESS_TYPE_X = 2;

parameter PMPCFG_ID_WIDTH = 3;
parameter PMPADDR_ID_WIDTH = $clog2(64);

parameter CMP_EQ  = 3'b000;
parameter CMP_NE  = 3'b001;
parameter CMP_LT  = 3'b110;
parameter CMP_GE  = 3'b111;
parameter CMP_LTU = 3'b100;
parameter CMP_GEU = 3'b101;

parameter WRITE_SEL_ALU     = 2'b00;
parameter WRITE_SEL_CSR     = 2'b01;
parameter WRITE_SEL_LOAD    = 2'b10;
parameter WRITE_SEL_NEXT_PC = 2'b11;

parameter LDU_OP_WIDTH = 4;
parameter LDU_LB = 0;
parameter LDU_LH = 1;
parameter LDU_LW = 2;
parameter LDU_LD = 3;
parameter LDU_LBU = 4;
parameter LDU_LHU = 5;
parameter LDU_LWU = 6;


parameter STU_OP_WIDTH = 5;
parameter STU_SB = 0;
parameter STU_SH = 1;
parameter STU_SW = 2;
parameter STU_SD = 3;

parameter LS_OPCODE_WIDTH = LDU_OP_WIDTH > STU_OP_WIDTH ? LDU_OP_WIDTH : STU_OP_WIDTH;

//ebi
parameter EBI_WIDTH = 16;

// fence
// TODO: fixed FEMCE
parameter STU_FENCE = 4;
parameter STU_SFENCE_VMA = 5;
parameter STU_FENCE_I = 6;
// amo 
parameter STU_SCW = 7;
parameter STU_SCD = 8;
parameter STU_LRW = 9;
parameter STU_LRD = 10;
// parameter STU_SCD = 7;
parameter STU_AMOSWAPW = 11;
parameter STU_AMOSWAPD = 12;
parameter STU_AMOADDW = 13;
parameter STU_AMOADDD = 14;
parameter STU_AMOANDW = 15;
parameter STU_AMOANDD = 16;
parameter STU_AMOORW = 17;
parameter STU_AMOORD = 18;
parameter STU_AMOXORW = 19;
parameter STU_AMOXORD = 20;
parameter STU_AMOMAXW = 21;
parameter STU_AMOMAXD = 22;
parameter STU_AMOMAXUW = 23;
parameter STU_AMOMAXUD = 24;
parameter STU_AMOMINW = 25;
parameter STU_AMOMIND = 26;
parameter STU_AMOMINUW = 27;
parameter STU_AMOMINUD = 28;

`ifdef DPRAM64_2R1W
parameter FENCE_WE = 8'b0100_0000;
`endif // DPRAM64_2R1W


// PMA
parameter IO_ADDR_UPP = 56'h1000;
parameter IO_ADDR_LOW = 56'h1004;

// LSU 
`ifdef LSU_V1
    parameter LSQ_DEPTH = 8;
    parameter LSQ_DEPTH_WIDTH = 3;


    parameter LSU_ADDR_PIPE_COUNT = 1;
    parameter LSU_DATA_PIPE_COUNT = 1;    

    parameter LSQ_ENTRY_VLD_WIDTH = 1;
    parameter LSQ_ENTRY_VLD_WIDTH_LOW = 0;
    parameter LSQ_ENTRY_VLD_WIDTH_UPP = LSQ_ENTRY_VLD_WIDTH_LOW + LSQ_ENTRY_VLD_WIDTH;

    parameter LSQ_ENTRY_LS_WIDTH = 1;
    parameter LSQ_ENTRY_LS_WIDTH_LOW = LSQ_ENTRY_VLD_WIDTH_UPP; // 0: ld/st 1: usigned or not 2-3:width 4:sc/lr
    parameter LSQ_ENTRY_LS_WIDTH_UPP = LSQ_ENTRY_LS_WIDTH_LOW + LSQ_ENTRY_LS_WIDTH; // 0: ld/st 1: usigned or not 2-3:width 4:sc/lr

    parameter LSQ_ENTRY_OPCODE_WIDTH = LS_OPCODE_WIDTH; // 0: ld/st 1: usigned or not 2-3:width 4:sc/lr
    parameter LSQ_ENTRY_OPCODE_WIDTH_LOW = LSQ_ENTRY_LS_WIDTH_UPP; // 0: ld/st 1: usigned or not 2-3:width 4:sc/lr
    parameter LSQ_ENTRY_OPCODE_WIDTH_UPP = LSQ_ENTRY_VLD_WIDTH_UPP + LSQ_ENTRY_OPCODE_WIDTH; // 0: ld/st 1: usigned or not 2-3:width 4:sc/lr

    parameter LSQ_ENTRY_FENCED_WIDTH = 1;
    parameter LSQ_ENTRY_FENCED_WIDTH_LOW = LSQ_ENTRY_OPCODE_WIDTH_UPP;
    parameter LSQ_ENTRY_FENCED_WIDTH_UPP = LSQ_ENTRY_FENCED_WIDTH_LOW + LSQ_ENTRY_FENCED_WIDTH;

    parameter LSQ_ENTRY_TAG_WIDTH = VIRTUAL_ADDR_TAG_LEN > PHYSICAL_ADDR_TAG_LEN ? VIRTUAL_ADDR_TAG_LEN : PHYSICAL_ADDR_TAG_LEN;
    parameter LSQ_ENTRY_TAG_WIDTH_LOW = LSQ_ENTRY_FENCED_WIDTH_UPP;
    parameter LSQ_ENTRY_TAG_WIDTH_UPP = LSQ_ENTRY_TAG_WIDTH_LOW + LSQ_ENTRY_TAG_WIDTH;

    parameter LSQ_ENTRY_INDEX_WIDTH = ADDR_INDEX_LEN;
    parameter LSQ_ENTRY_INDEX_WIDTH_LOW = LSQ_ENTRY_TAG_WIDTH_UPP;
    parameter LSQ_ENTRY_INDEX_WIDTH_UPP = LSQ_ENTRY_INDEX_WIDTH_LOW + LSQ_ENTRY_INDEX_WIDTH;

    parameter LSQ_ENTRY_OFFSET_WIDTH = ADDR_OFFSET_LEN;
    parameter LSQ_ENTRY_OFFSET_WIDTH_LOW = LSQ_ENTRY_INDEX_WIDTH_UPP;
    parameter LSQ_ENTRY_OFFSET_WIDTH_UPP = LSQ_ENTRY_OFFSET_WIDTH_LOW + ADDR_OFFSET_LEN;

    parameter LSQ_ENTRY_ROB_INDEX_WIDTH = ROB_INDEX_WIDTH;
    parameter LSQ_ENTRY_ROB_INDEX_WIDTH_LOW = LSQ_ENTRY_OFFSET_WIDTH_UPP;
    parameter LSQ_ENTRY_ROB_INDEX_WIDTH_UPP = LSQ_ENTRY_ROB_INDEX_WIDTH_LOW + LSQ_ENTRY_ROB_INDEX_WIDTH;

    parameter LSQ_ENTRY_VIRT_WIDTH = 1;
    parameter LSQ_ENTRY_VIRT_WIDTH_LOW = LSQ_ENTRY_ROB_INDEX_WIDTH_UPP;
    parameter LSQ_ENTRY_VIRT_WIDTH_UPP = LSQ_ENTRY_VIRT_WIDTH_LOW + LSQ_ENTRY_VIRT_WIDTH;

    parameter LSQ_ENTRY_AWAKE_WIDTH = 1;
    parameter LSQ_ENTRY_AWAKE_WIDTH_LOW = LSQ_ENTRY_VIRT_WIDTH_UPP;
    parameter LSQ_ENTRY_AWAKE_WIDTH_UPP = LSQ_ENTRY_AWAKE_WIDTH_LOW + LSQ_ENTRY_AWAKE_WIDTH;

    parameter LSQ_ENTRY_EXEC_WIDTH = 1;
    parameter LSQ_ENTRY_EXEC_WIDTH_LOW = LSQ_ENTRY_AWAKE_WIDTH_UPP;
    parameter LSQ_ENTRY_EXEC_WIDTH_UPP = LSQ_ENTRY_EXEC_WIDTH_LOW + LSQ_ENTRY_EXEC_WIDTH;

    parameter LSQ_ENTRY_SUCC_WIDTH = 1;
    parameter LSQ_ENTRY_SUCC_WIDTH_LOW = LSQ_ENTRY_EXEC_WIDTH_UPP;
    parameter LSQ_ENTRY_SUCC_WIDTH_UPP = LSQ_ENTRY_SUCC_WIDTH_LOW + LSQ_ENTRY_SUCC_WIDTH;

    parameter LSQ_ENTRY_RD_ADDR_WIDTH =PHY_REG_ADDR_WIDTH;
    parameter LSQ_ENTRY_RD_ADDR_WIDTH_LOW =LSQ_ENTRY_SUCC_WIDTH_UPP;
    parameter LSQ_ENTRY_RD_ADDR_WIDTH_UPP =LSQ_ENTRY_RD_ADDR_WIDTH_LOW + LSQ_ENTRY_RD_ADDR_WIDTH;

    parameter LSQ_ENTRY_DATA_WIDTH = XLEN;
    parameter LSQ_ENTRY_DATA_WIDTH_LOW = LSQ_ENTRY_RD_ADDR_WIDTH_UPP;
    parameter LSQ_ENTRY_DATA_WIDTH_UPP = LSQ_ENTRY_DATA_WIDTH_LOW + LSQ_ENTRY_DATA_WIDTH;

    parameter LSQ_ENTRY_WIDTH = LSQ_ENTRY_VLD_WIDTH + LSQ_ENTRY_OPCODE_WIDTH + LSQ_ENTRY_FENCED_WIDTH + LSQ_ENTRY_TAG_WIDTH + 
                                    LSQ_ENTRY_INDEX_WIDTH + LSQ_ENTRY_OFFSET_WIDTH + LSQ_ENTRY_ROB_INDEX_WIDTH + LSQ_ENTRY_VIRT_WIDTH + 
                                    LSQ_ENTRY_AWAKE_WIDTH + LSQ_ENTRY_EXEC_WIDTH + LSQ_ENTRY_SUCC_WIDTH + LSQ_ENTRY_RD_ADDR_WIDTH + 
                                    LSQ_ENTRY_DATA_WIDTH;
`endif // LSU_V1

// FU
parameter UNITS_NUM = 5;
parameter UNITS_NUM_WIDTH = 3;

// Decode
// fence function code in decoder
parameter DEC_FENCE = 0;
parameter DEC_FENCE_I = 1;
parameter DEC_SFENCE_VMA = 2;
// decode fifo
parameter DEC_FIFO_DATA_WIDTH = 1 * 4 + PC_WIDTH * 3 + 5 * 3 + 12 + 1 * 3 + EXCEPTION_CAUSE_WIDTH + XLEN + 1 + 1 + 1 + 2 + 1 + 1 + 1 + 1 + 32 + 3 + 1 + 2 * 2 + 1 + 1 + 1 + 1 + 1 + LDU_OP_WIDTH + STU_OP_WIDTH + 1 + 1;
parameter DEC_FIFO_SIZE = 8;
parameter DEC_FIFO_SIZE_WIDTH = 3;


//RCU
parameter MD_DATA_WIDTH = ROB_INDEX_WIDTH + PHY_REG_ADDR_WIDTH + XLEN + XLEN + 3 + 1;
parameter LSU_DATA_WIDTH = ROB_INDEX_WIDTH + PHY_REG_ADDR_WIDTH + XLEN + XLEN + IMM_LEN + 1 + 1 + LDU_OP_WIDTH + STU_OP_WIDTH + 1 + 2 + 1 + 1 + 1;


parameter SYS_exit = 93;
parameter SYS_exit_group = 94;
parameter SYS_getpid = 172;
parameter SYS_kill = 129;
parameter SYS_tgkill = 131;
parameter SYS_read = 63;
parameter SYS_write = 64;
parameter SYS_openat = 56;
parameter SYS_close = 57;
parameter SYS_lseek = 62;
parameter SYS_brk = 214;
parameter SYS_linkat = 37;
parameter SYS_unlinkat = 35;
parameter SYS_mkdirat = 34;
parameter SYS_renameat = 38;
parameter SYS_chdir = 49;
parameter SYS_getcwd = 17;
parameter SYS_fstat = 80;
parameter SYS_fstatat = 79;
parameter SYS_faccessat = 48;
parameter SYS_pread = 67;
parameter SYS_pwrite = 68;
parameter SYS_uname = 160;
parameter SYS_getuid = 174;
parameter SYS_geteuid = 175;
parameter SYS_getgid = 176;
parameter SYS_getegid = 177;
parameter SYS_gettid = 178;
parameter SYS_sysinfo = 179;
parameter SYS_mmap = 222;
parameter SYS_munmap = 215;
parameter SYS_mremap = 216;
parameter SYS_mprotect = 226;
parameter SYS_prlimit64 = 261;
parameter SYS_getmainvars = 2011;
parameter SYS_rt_sigaction = 134;
parameter SYS_writev = 66;
parameter SYS_gettimeofday = 169;
parameter SYS_times = 153;
parameter SYS_fcntl = 25;
parameter SYS_ftruncate = 46;
parameter SYS_getdents = 61;
parameter SYS_dup = 23;
parameter SYS_dup3 = 24;
parameter SYS_readlinkat = 78;
parameter SYS_rt_sigprocmask = 135;
parameter SYS_ioctl = 29;
parameter SYS_getrlimit = 163;
parameter SYS_setrlimit = 164;
parameter SYS_getrusage = 165;
parameter SYS_clock_gettime = 113;
parameter SYS_set_tid_address = 96;
parameter SYS_set_robust_list = 99;
parameter SYS_madvise = 233;
parameter SYS_statx = 291;

/*verilator lint_off UNUSED */
`endif // PARAMS_VH
