module tb_top;

string hex_dir, hex, payload_dir, payload, wave_dir;
string args[$];
integer args_len[$];

parameter DRAM_SIZE = 1 << 29 ; //18;
parameter DRAM_AXI_DATA_WIDTH = 128;
parameter DRAM_INDEX_NUM = DRAM_SIZE/(DRAM_AXI_DATA_WIDTH/8);
parameter DRAM_INDEX_WIDTH = $clog2(DRAM_INDEX_NUM);
parameter PERIOD = 20;
parameter SIMU_TIME = 10000;
`ifdef PK
parameter PROGRAM_TOHOST_ADDR = 56'h8000b008;
parameter PROGRAM_FROMHOST_ADDR = 56'hb000;
parameter PROGRAM_MAGICMEMORY_ADDR = 64'h8000_e078;
parameter PROGRAM_MAGICMEMORY_ADDR_0 = 64'he078;
parameter PROGRAM_MAGICMEMORY_ADDR_1 = 64'he080;
parameter PROGRAM_MAGICMEMORY_ADDR_2 = 64'he088;
parameter PROGRAM_MAGICMEMORY_ADDR_3 = 64'he090;
parameter PROGRAM_MAGICMEMORY_ADDR_4 = 64'he098;
parameter PROGRAM_MAGICMEMORY_ADDR_5 = 64'he0a0;
parameter PROGRAM_MAGICMEMORY_ADDR_6 = 64'he0a8;
parameter PROGRAM_MAGICMEMORY_ADDR_7 = 64'he0b0;
`endif
`ifndef PK
parameter PROGRAM_TOHOST_ADDR = 56'h80001000;
parameter PROGRAM_FROMHOST_ADDR = 56'h1040;
`endif
// parameter PROGRAM_TOHOST_ADDR = 56'h8001a3f8;
// parameter PROGRAM_FROMHOST_ADDR = 56'h1a3f0;

logic                                           clk;
logic                                           rst;
//fetch
logic                                           ft2l1i_if_req_rdy_i;
logic                                           l1i2ft_if_resp_vld_i;
logic [$clog2(IFQ_DEPTH)-1:0]                   l1i2ft_if_resp_if_tag_i;
logic [FETCH_WIDTH-1:0]                         l1i2ft_if_resp_data_i;
logic                                           ft2l1i_if_req_vld_o;
logic [L1I_INDEX_WIDTH-1:0]                     ft2l1i_if_req_index_o;
logic [$clog2(IFQ_DEPTH)-1:0]                   ft2l1i_if_req_if_tag_o;
logic [L1I_OFFSET_WIDTH-1:0]                    ft2l1i_if_req_offset_o;
logic [L1I_TAG_WIDTH-1:0]                       ft2l1i_if_req_vtag_o;
logic                                           itlb2ft_miss_i;
logic                                           itlb2ft_hit_i;
logic                                           ft2itlb_req_vld_o;
logic                                           itlb_fetch_resp_excp_vld_i;
logic [EXCEPTION_CAUSE_WIDTH-1:0]               itlb_fetch_resp_ecause_i;

//decode
logic                                           msip_i;
logic                                           ssip_i;
logic                                           mtip_i;
logic                                           stip_i;
logic                                           eip_i;

//fu
    //fu<->tlb
logic                          itlb2ic_if_resp_vld_o          ;
logic [         PPN_WIDTH-1:0] itlb2icache_ic_ptag_o          ;
logic                          itlb2ft_resp_excp_vld_o        ;
logic                          itlb_translate_resp_miss_o     ;
logic                          itlb_translate_resp_hit_o      ;

logic  [LSU_ADDR_PIPE_COUNT-1:0]                         dtlb2dcache_lsu_vld_o          ;
logic  [LSU_ADDR_PIPE_COUNT-1:0][         PPN_WIDTH-1:0] dtlb2dcache_lsu_ptag_o         ;
logic  [LSU_ADDR_PIPE_COUNT-1:0]                         dtlb2dcache_lsu_exception_vld_o;
logic  [LSU_ADDR_PIPE_COUNT-1:0]                         dtlb2dcache_lsu_miss_o         ;
logic  [LSU_ADDR_PIPE_COUNT-1:0]                         dtlb2dcache_lsu_hit_o          ;

logic                                               mmu2cache_ptw_walk_req_vld_o ;
logic  [PTW_ID_WIDTH-1:0]                           mmu2cache_ptw_walk_req_id_o  ;
logic  [PADDR_WIDTH-1:0]                            mmu2cache_ptw_walk_req_addr_o;
logic                                               mmu2cache_ptw_walk_req_rdy_i ;

logic                                               mmu2cache_ptw_walk_resp_vld_i;
logic [PTE_WIDTH-1:0]                               mmu2cache_ptw_walk_resp_pte_i;
logic                                               mmu2cache_ptw_walk_resp_rdy_o;

// remain for unuse
logic                                           dtlb2fu_lsu_vld_i; // should be the lsu_dtlb_iss_vld_o in last cycle
logic                                           dtlb2fu_lsu_hit_i;
logic [PHYSICAL_ADDR_TAG_LEN - 1 : 0]           dtlb2fu_lsu_ptag_i;

    //fu<->l1d cache
logic                                           l1d2fu_lsu_ld_req_rdy_i;
logic                                           fu2l1d_lsu_ld_req_vld_o;
logic  [     ROB_INDEX_WIDTH - 1 : 0]           fu2l1d_lsu_ld_req_rob_index_o;
logic  [    PHY_REG_ADDR_WIDTH - 1 : 0]         fu2l1d_lsu_ld_req_rd_addr_o; // no need
logic  [      LDU_OP_WIDTH - 1 : 0]             fu2l1d_lsu_ld_req_opcode_o;
logic  [       ADDR_INDEX_LEN - 1 : 0]          fu2l1d_lsu_ld_req_index_o; 
logic  [      ADDR_OFFSET_LEN - 1 : 0]          fu2l1d_lsu_ld_req_offset_o;
logic  [     VIRTUAL_ADDR_TAG_LEN -1 : 0]       fu2l1d_lsu_ld_req_vtag_o; 
logic                                           l1d2fu_lsu_st_req_rdy_i;
logic                                           fu2l1d_lsu_st_req_vld_o;
logic                                           fu2l1d_lsu_st_req_is_fence_o;
logic   [     ROB_INDEX_WIDTH - 1 : 0]          fu2l1d_lsu_st_req_rob_index_o;
logic   [    PHY_REG_ADDR_WIDTH - 1 : 0]        fu2l1d_lsu_st_req_rd_addr_o;
logic   [      STU_OP_WIDTH - 1 : 0]            fu2l1d_lsu_st_req_opcode_o;
logic   [       PHYSICAL_ADDR_LEN - 1 : 0]      fu2l1d_lsu_st_req_paddr_o; 
logic   [              XLEN - 1 : 0]            fu2l1d_lsu_st_req_data_o;

logic                                           l1d2fu_lsu_ld_replay_vld_i;

logic [LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT - 1 : 0]                                  l1d2fu_lsu_wb_vld_i;
logic [(LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT) * ROB_INDEX_WIDTH - 1 : 0]                l1d2fu_lsu_wb_rob_index_i;
logic                                           l1d2fu_lsu_prf_wb_vld_i;
logic [PHY_REG_ADDR_WIDTH - 1 : 0]              l1d2fu_lsu_prf_wb_rd_addr_i;
logic [XLEN - 1 : 0]                            l1d2fu_lsu_prf_wb_data_i;
logic                                           fu2l1d_lsu_kill_req_o;

`ifdef DPRAM64_2R1W
logic [XLEN/8-1:0] 		                           we,we_real;
logic [XLEN-1:0] 		                           din;
logic [PHYSICAL_ADDR_LEN-1:0]                      waddr;
logic [PHYSICAL_ADDR_LEN-1:0]                      raddr_d;
logic [1:0]                                        re_d;
logic                                              runsigned_d;  
logic  [     ROB_INDEX_WIDTH - 1 : 0]              wrob_index_d;
logic  [    PHY_REG_ADDR_WIDTH - 1 : 0]            wrd_addr_d;     
logic  [     ROB_INDEX_WIDTH - 1 : 0]              rrob_index_d;
logic  [    PHY_REG_ADDR_WIDTH - 1 : 0]            rrd_addr_d;     
`endif // DPRAM64_2R1W
    //fu <-> wb bus
logic                                           fu2wb_lsu_cyc_o;
logic                                           fu2wb_lsu_stb_o;
logic                                           fu2wb_lsu_we_o;
logic [PHYSICAL_ADDR_LEN - 1 : 0]               fu2wb_lsu_adr_o;
logic [WB_DATA_LEN-1:0]                         fu2wb_lsu_dat_o;
logic [WB_DATA_LEN/8-1:0]                       fu2wb_lsu_sel_o;
logic                                           wb2fu_lsu_ack_i;
logic [WB_DATA_LEN -1:0]                        wb2fu_lsu_dat_i;

logic st_vld_1_delay    ;
logic ld_vld_1_delay    ;
logic [ROB_INDEX_WIDTH - 1 : 0] wrob_index_1_delay;
logic [ROB_INDEX_WIDTH - 1 : 0] rrob_index_1_delay;
logic [PHY_REG_ADDR_WIDTH - 1 : 0] rrd_addr_1_delay;

logic st_vld_2_delay    ;
logic ld_vld_2_delay    ;
logic [ROB_INDEX_WIDTH - 1 : 0] wrob_index_2_delay;
logic [ROB_INDEX_WIDTH - 1 : 0] rrob_index_2_delay;
logic [PHY_REG_ADDR_WIDTH - 1 : 0] rrd_addr_2_delay;
logic [XLEN-1:0] dram_rdata_d_2_delay;

logic st_vld_3_delay    ;
logic ld_vld_3_delay    ;
logic [ROB_INDEX_WIDTH - 1 : 0] wrob_index_3_delay;
logic [ROB_INDEX_WIDTH - 1 : 0] rrob_index_3_delay;
logic [PHY_REG_ADDR_WIDTH - 1 : 0] rrd_addr_3_delay;
logic [XLEN-1:0] dram_rdata_d_3_delay;

logic ld_vld_4_delay;
logic [ROB_INDEX_WIDTH - 1 : 0] wrob_index_4_delay;
logic [ROB_INDEX_WIDTH - 1 : 0] rrob_index_4_delay;
logic [PHY_REG_ADDR_WIDTH - 1 : 0] rrd_addr_4_delay  ;

wire [XLEN-1:0] dram_wdata     ;
wire [128-1:0] dram_rdata_i     ;
wire [XLEN-1:0] dram_rdata_d     ;
wire [PHYSICAL_ADDR_LEN-1:0] dram_waddr  ;
wire [PHYSICAL_ADDR_LEN-1:0] dram_raddr_i  ;
wire [PHYSICAL_ADDR_LEN-1:0] dram_raddr_d  ;

logic [1:0] re_d_1_delay        ;
logic runsigned_d_1_delay ;
logic [PHYSICAL_ADDR_LEN-1:0] raddr_d_1_delay    ; 

logic [1:0] re_d_2_delay        ;
logic runsigned_d_2_delay ;
logic [PHYSICAL_ADDR_LEN-1:0] raddr_d_2_delay     ;

logic [1:0] re_d_3_delay        ;
logic runsigned_d_3_delay ;
logic [PHYSICAL_ADDR_LEN-1:0] raddr_d_3_delay     ;

logic st_fence_vld_1_delay;
logic st_fence_vld_2_delay;
logic st_fence_vld_3_delay;

always #(PERIOD/2) clk = ~clk; 

logic [63:0] accum;
logic [31:0] mac;

assign mac = -2;

// simulation lenth
logic mid = 0;
integer co_sim_fd;
integer run_test_fd;
integer co_sim_haha_fd;
int queue[47];
logic signal;
initial begin 
    $value$plusargs("HEX=%s",hex);
    $value$plusargs("PAYLOAD=%s",payload);
    args={hex,payload};
    args_len={hex.len()+1,payload.len()+1};
    $value$plusargs("PAYLOAD_DIR=%s",payload_dir);
   
    `ifdef PK
    co_sim_haha_fd = $fopen("../test/linux/proxy_kernel/isa.log", "w");
    `elsif HAHA
    co_sim_haha_fd = $fopen("logs/isa.log", "w");
    `endif
    co_sim_fd = $fopen("./co_sim.log", "w");
    run_test_fd = $fopen("logs/all_test.log", "a+");
    signal = 0;
    clk = 0;
    rst = 1;
    l1d2fu_lsu_wb_vld_i = 0;
    msip_i = 0;
    ssip_i = 0;
    mtip_i = 0;
    stip_i = 0;
    eip_i  = 0;
    l1d2fu_lsu_ld_replay_vld_i = 0;
    l1d2fu_lsu_st_req_rdy_i = 1;
    l1d2fu_lsu_ld_req_rdy_i = 1;
    #40
    @(negedge clk)
    rst = 0;
    `ifdef PK
    # 100000000;
    `endif
    `ifndef PK
    # 10000000000;
    `endif
    $fdisplay(run_test_fd, "%s simulation terminated", hex);    
    `ifdef HAHA
    $fclose(co_sim_haha_fd);
    `endif
    $fclose(co_sim_fd);
    $fclose(run_test_fd);
    $display ("\n%s simulation terminated",hex);
    $finish;
end

logic [PC_WIDTH-1:0] dram_waddr_3_delay, dram_waddr_2_delay, dram_waddr_1_delay;
logic [XLEN-1:0] dram_wdata_3_delay, dram_wdata_2_delay, dram_wdata_1_delay;
logic [XLEN/8-1:0] we_3_delay, we_2_delay, we_1_delay;

`ifdef PK
logic [XLEN-1:0] fromhost;
logic fromhost_we;
`endif
`ifndef PK
logic fromhost;
`endif

logic ft2l1i_if_req_vld_1_delay;
logic [L1I_INDEX_WIDTH-1:0] ft2l1i_if_req_index_1_delay;

logic                                           lsu_l1d_fencei_flush_vld;
logic                                           lsu_l1i_fencei_flush_vld;
logic                                           lsu_l1d_fencei_flush_vld_1_delay;
logic                                           lsu_l1i_fencei_flush_vld_1_delay;

logic                                           l1d_lsu_fencei_flush_grant;
logic                                           l1i_lsu_fencei_flush_grant;


always @(posedge clk) begin
    if(rst) begin 
        lsu_l1d_fencei_flush_vld_1_delay <= 0;
        lsu_l1i_fencei_flush_vld_1_delay <= 0;
    end else begin
        lsu_l1d_fencei_flush_vld_1_delay <= lsu_l1d_fencei_flush_vld;
        lsu_l1i_fencei_flush_vld_1_delay <= lsu_l1i_fencei_flush_vld;
    end

end

assign l1d_lsu_fencei_flush_grant = lsu_l1d_fencei_flush_vld_1_delay;
assign l1i_lsu_fencei_flush_grant = lsu_l1i_fencei_flush_vld_1_delay;

dpram64_3r1w #(
    .SIZE(DRAM_SIZE)         , // byte
    .AXI_DATA_WIDTH(DRAM_AXI_DATA_WIDTH)   ,
    .mem_clear(1)        ,
    .mem_simple_seq(0)   ,
    .LSU_DATA_WIDTH(XLEN),
    .LSU_ADDR_WIDTH(PHYSICAL_ADDR_LEN),
    .FROMHOST_ADDR(PROGRAM_FROMHOST_ADDR),
`ifdef PK
    .TOHOST_ADDR(PROGRAM_TOHOST_ADDR & 16'hffff),
    .PROGRAM_MAGICMEMORY_ADDR(PROGRAM_MAGICMEMORY_ADDR),
    .MAGICMEMORY_ADDR_0(PROGRAM_MAGICMEMORY_ADDR_0 & 16'hffff),
    .MAGICMEMORY_ADDR_1(PROGRAM_MAGICMEMORY_ADDR_1 & 16'hffff),
    .MAGICMEMORY_ADDR_2(PROGRAM_MAGICMEMORY_ADDR_2 & 16'hffff),
    .MAGICMEMORY_ADDR_3(PROGRAM_MAGICMEMORY_ADDR_3 & 16'hffff),
    .MAGICMEMORY_ADDR_4(PROGRAM_MAGICMEMORY_ADDR_4 & 16'hffff),
    .MAGICMEMORY_ADDR_5(PROGRAM_MAGICMEMORY_ADDR_5 & 16'hffff),
    .MAGICMEMORY_ADDR_6(PROGRAM_MAGICMEMORY_ADDR_6 & 16'hffff),
    .MAGICMEMORY_ADDR_7(PROGRAM_MAGICMEMORY_ADDR_7 & 16'hffff),
    .PAYLOAD_ARGS(1),
    .PK_ARGS(1),
    .BUILT_IN_ARGS(3),
    .TOTAL_PAYLOAD_ARGS(1+1),
    .TOTAL_ARGS(1+1+3),
`endif
    .memfile("")          
) dram_u (
    .clk(clk)           ,
`ifdef PK
    .rst(fromhost_we)       ,
    .from_host_data(fromhost)   ,
`endif
`ifndef PK
    .rst(fromhost)       ,
`endif
    .we(we_real)       ,
    .din_d((dram_wdata_3_delay))    ,
    .waddr_d(dram_waddr_3_delay-56'h8000_0000)  ,
    .rsize_d(re_d_3_delay)          ,
    .unsign_d(runsigned_d_3_delay)  ,
    .raddr_i((dram_raddr_i-56'h8000_0000))  ,
    .raddr_d((raddr_d_3_delay-56'h8000_0000))       ,
    .dout_i(dram_rdata_i)   ,
    .dout_d(dram_rdata_d)   ,
    .hex_dir(hex_dir),
    .ptw_raddr_i(mmu2cache_ptw_walk_req_addr_o-56'h8000_0000),
    .ptw_rdata_o(mmu2cache_ptw_walk_resp_pte_i)
);
assign we_real = (we_3_delay == FENCE_WE) ? 0 : (we_3_delay & {8{st_vld_3_delay}});
//RAM <-> fetch
always @(posedge clk) begin
    if (rst) begin
        ft2l1i_if_req_vld_1_delay <= 0;
        ft2l1i_if_req_index_1_delay <= 0;
    end else begin
        ft2l1i_if_req_vld_1_delay <= ft2l1i_if_req_vld_o & !tb_top.core_u.rcu_u.global_speculate_fault;
        ft2l1i_if_req_index_1_delay <= ft2l1i_if_req_index_o;
    end
end
// always @(posedge clk) begin
//     // Note: tlb_resp_vld is SET even if miss, should check resp_hit
//     // l1i2ft_if_resp_vld_i <= ft2l1i_if_req_vld_1_delay & itlb2ic_if_resp_vld_o & !tb_top.core_u.rcu_u.global_speculate_fault;
//     l1i2ft_if_resp_vld_i <= ft2l1i_if_req_vld_1_delay & itlb_translate_resp_hit_o & !tb_top.core_u.rcu_u.global_speculate_fault;
// end
assign l1i2ft_if_resp_vld_i = ft2l1i_if_req_vld_1_delay & itlb_translate_resp_hit_o & !tb_top.core_u.rcu_u.global_speculate_fault;

assign ft2l1i_if_req_rdy_i = 1;
assign dram_raddr_i = {itlb2icache_ic_ptag_o, ft2l1i_if_req_index_1_delay};
assign l1i2ft_if_resp_data_i = dram_rdata_i;
assign itlb2ft_miss_i = 0;
assign itlb_fetch_resp_excp_vld_i = 0;
assign itlb_fetch_resp_ecause_i = 0;

// dtlb
// always @(posedge clk) begin
//         dtlb2fu_lsu_vld_i <= fu2dtlb_lsu_iss_vld_o;
//         dtlb2fu_lsu_hit_i <= fu2dtlb_lsu_iss_vld_o;
//     if (fu2dtlb_lsu_iss_vld_o) begin
//         dtlb2fu_lsu_ptag_i <= {{(PHYSICAL_ADDR_LEN-VIRTUAL_ADDR_LEN){1'b0}}, fu2dtlb_lsu_iss_vtag_o};
//     end
// end

// dcache
// 1-cycle delay
always @(posedge clk) begin
    if (0) begin
        wrob_index_1_delay      <= 0;
        rrob_index_1_delay      <= 0;
        rrd_addr_1_delay        <= 0;
    end else begin
        wrob_index_1_delay      <= wrob_index_d;
        rrob_index_1_delay      <= rrob_index_d;
        rrd_addr_1_delay        <= rrd_addr_d;
    end
end

//load
always @(posedge clk) begin
    if(tb_top.core_u.rcu_u.global_speculate_fault) begin
        ld_vld_1_delay          <= 0;
        re_d_1_delay            <= 0;
        runsigned_d_1_delay     <= 0;
        raddr_d_1_delay         <= 0;
    end else begin
        ld_vld_1_delay          <= fu2l1d_lsu_ld_req_vld_o;
        re_d_1_delay            <= re_d        ;
        runsigned_d_1_delay     <= runsigned_d ;
        raddr_d_1_delay         <= raddr_d     ;
    end
end
        
//store
always @(posedge clk) begin
    st_fence_vld_1_delay <= (fu2l1d_lsu_st_req_opcode_o == STU_FENCE) & fu2l1d_lsu_st_req_vld_o;
    if (0) begin
        st_vld_1_delay          <= 0 ;
        dram_waddr_1_delay      <= 0 ;
        dram_wdata_1_delay      <= 0 ;
        we_1_delay              <= 0 ;
    end else if (fu2l1d_lsu_st_req_opcode_o != STU_FENCE) begin
        st_vld_1_delay          <= fu2l1d_lsu_st_req_vld_o;
        dram_waddr_1_delay      <= waddr;
        dram_wdata_1_delay      <= din;
        we_1_delay              <= we;
    end
end

// 2-cycle delay
always @(posedge clk) begin
    if (0) begin
        wrob_index_2_delay      <= 0 ;
        rrob_index_2_delay      <= 0 ;
        rrd_addr_2_delay        <= 0 ;
    end else begin
        wrob_index_2_delay      <= wrob_index_1_delay  ;
        rrob_index_2_delay      <= rrob_index_1_delay  ;
        rrd_addr_2_delay        <= rrd_addr_1_delay    ;
    end
end

//load
always @(posedge clk) begin
    if(tb_top.core_u.rcu_u.global_speculate_fault) begin
        ld_vld_2_delay          <= 0 ;
        re_d_2_delay            <= 0;
        runsigned_d_2_delay     <= 0;
        raddr_d_2_delay         <= 0;
    end else begin
        ld_vld_2_delay          <= ld_vld_1_delay & dtlb2dcache_lsu_vld_o & dtlb2dcache_lsu_hit_o     ;
        re_d_2_delay            <= re_d_1_delay        ;
        runsigned_d_2_delay     <= runsigned_d_1_delay ;
        raddr_d_2_delay         <= {dtlb2dcache_lsu_ptag_o, raddr_d_1_delay[PHYSICAL_ADDR_LEN-PHYSICAL_ADDR_TAG_LEN-1:0]};
    end
end

// store
always @(posedge clk) begin
    st_fence_vld_2_delay <= st_fence_vld_1_delay;
    if (0) begin
        st_vld_2_delay          <= 0 ;
        dram_waddr_2_delay      <= 0 ;
        dram_wdata_2_delay      <= 0 ;
        we_2_delay              <= 0 ;
    end else begin
        st_vld_2_delay          <= st_vld_1_delay      ;
        dram_waddr_2_delay      <= dram_waddr_1_delay  ;
        dram_wdata_2_delay      <= dram_wdata_1_delay  ;
        we_2_delay              <= we_1_delay          ;
    end
end
// 3-cycle delay
always @(posedge clk) begin
    if (0) begin
        wrob_index_3_delay      <= 0;
        rrob_index_3_delay      <= 0;
        rrd_addr_3_delay        <= 0;
    end else begin
        wrob_index_3_delay      <= wrob_index_2_delay  ;
        rrob_index_3_delay      <= rrob_index_2_delay  ;
        rrd_addr_3_delay        <= rrd_addr_2_delay    ;
    end
end

//load
always @(posedge clk) begin
    if(tb_top.core_u.rcu_u.global_speculate_fault | fu2l1d_lsu_kill_req_o) begin
        ld_vld_3_delay          <= 0;
        re_d_3_delay            <= 0;
        runsigned_d_3_delay     <= 0;
        raddr_d_3_delay         <= 0;
    end else begin
        ld_vld_3_delay          <= ld_vld_2_delay      ;
        re_d_3_delay            <= re_d_2_delay        ;
        runsigned_d_3_delay     <= runsigned_d_2_delay ;
        raddr_d_3_delay         <= raddr_d_2_delay     ;
    end
end

//store
always @(posedge clk) begin
    st_fence_vld_3_delay <= st_fence_vld_2_delay;
    if (fu2l1d_lsu_kill_req_o) begin
        st_vld_3_delay          <= 0;
        dram_waddr_3_delay      <= 0;
        dram_wdata_3_delay      <= 0;
        we_3_delay              <= 0;
    end else begin
        st_vld_3_delay          <= st_vld_2_delay;
        dram_waddr_3_delay      <= dram_waddr_2_delay;
        dram_wdata_3_delay      <= dram_wdata_2_delay;
        we_3_delay              <= we_2_delay;
    end
end

// 4-cycle delay
always @(posedge clk) begin
    if (0) begin
        wrob_index_4_delay      <= 0;
        rrob_index_4_delay      <= 0;
        rrd_addr_4_delay        <= 0;
    end else begin
        wrob_index_4_delay      <= wrob_index_3_delay  ;
        rrob_index_4_delay      <= rrob_index_3_delay  ;
        rrd_addr_4_delay        <= rrd_addr_3_delay    ;
    end
end

//load
always @(posedge clk) begin
    if(tb_top.core_u.rcu_u.global_speculate_fault) begin
        ld_vld_4_delay          <= 0;
    end else begin
        ld_vld_4_delay          <= ld_vld_3_delay      ;
    end
end

// back to lsu
always @(posedge clk) begin
    if (0) begin
        l1d2fu_lsu_wb_rob_index_i <= 0;
        l1d2fu_lsu_wb_vld_i <= 0;
        l1d2fu_lsu_prf_wb_vld_i <= 0;
        l1d2fu_lsu_prf_wb_rd_addr_i <= 0;
        l1d2fu_lsu_prf_wb_data_i <= 0;
    end else begin
        l1d2fu_lsu_wb_vld_i[1] <= st_vld_3_delay | st_fence_vld_3_delay;
        l1d2fu_lsu_wb_vld_i[0] <= ld_vld_4_delay & !tb_top.core_u.rcu_u.global_speculate_fault;
        l1d2fu_lsu_prf_wb_vld_i <= ld_vld_4_delay & !tb_top.core_u.rcu_u.global_speculate_fault;
        if (st_vld_3_delay | st_fence_vld_3_delay) begin
            l1d2fu_lsu_wb_rob_index_i[ROB_INDEX_WIDTH*2 - 1 : ROB_INDEX_WIDTH*1] <= wrob_index_3_delay;
        end else begin
            l1d2fu_lsu_wb_rob_index_i[ROB_INDEX_WIDTH*2 - 1 : ROB_INDEX_WIDTH*1] <= 0;
        end
        if (ld_vld_4_delay) begin
            l1d2fu_lsu_wb_rob_index_i[ROB_INDEX_WIDTH - 1 : 0] <= rrob_index_4_delay;
            l1d2fu_lsu_prf_wb_rd_addr_i <= rrd_addr_4_delay;
            l1d2fu_lsu_prf_wb_data_i <= dram_rdata_d;
        end else begin
            l1d2fu_lsu_wb_rob_index_i[ROB_INDEX_WIDTH - 1 : 0] <= 0;
            l1d2fu_lsu_prf_wb_rd_addr_i <= 0;
            l1d2fu_lsu_prf_wb_data_i <= 0;
        end
    end
end

//host
real inst, cycle, ipc;
logic [63:0] to_host_addr_base;
logic [55:0] to_host_addr_3, to_host_addr_2, to_host_addr_1, to_host_addr_0;
logic[63:0] to_host_data_3, to_host_data_2, to_host_data_1, to_host_data_0;

logic [55:0] base_addr;
int lenth;
logic [55:0] mid_addr, trans_addr;
logic [7:0] tmp;
logic [127:0] to_host_test_data_7;
logic [127:0] to_host_test_data_6;
logic [127:0] to_host_test_data_5;
logic [127:0] to_host_test_data_4;
logic [127:0] to_host_test_data_3;
logic [127:0] to_host_test_data_2;
logic [127:0] to_host_test_data_1;
logic [127:0] to_host_test_data_0;

assign to_host_addr_base = dram_wdata_3_delay-56'h8000_0000;
assign to_host_addr_0 = to_host_addr_base[55:0] + 0;
assign to_host_addr_1 = to_host_addr_base[55:0] + 8;
assign to_host_addr_2 = to_host_addr_base[55:0] + 16;
assign to_host_addr_3 = to_host_addr_base[55:0] + 24;

assign to_host_data_0 = {tb_top.dram_u.mem[to_host_addr_0[PHYSICAL_ADDR_LEN-1:$clog2(DRAM_AXI_DATA_WIDTH/8)]][{to_host_addr_0[$clog2(DRAM_AXI_DATA_WIDTH/8)-1:3],6'b0}+:64]};
assign to_host_data_1 = {tb_top.dram_u.mem[to_host_addr_1[PHYSICAL_ADDR_LEN-1:$clog2(DRAM_AXI_DATA_WIDTH/8)]][{to_host_addr_1[$clog2(DRAM_AXI_DATA_WIDTH/8)-1:3],6'b0}+:64]};
assign to_host_data_2 = {tb_top.dram_u.mem[to_host_addr_2[PHYSICAL_ADDR_LEN-1:$clog2(DRAM_AXI_DATA_WIDTH/8)]][{to_host_addr_2[$clog2(DRAM_AXI_DATA_WIDTH/8)-1:3],6'b0}+:64]};
assign to_host_data_3 = {tb_top.dram_u.mem[to_host_addr_3[PHYSICAL_ADDR_LEN-1:$clog2(DRAM_AXI_DATA_WIDTH/8)]][{to_host_addr_3[$clog2(DRAM_AXI_DATA_WIDTH/8)-1:3],6'b0}+:64]};

logic [63:0] magic_mem_0;
logic [63:0] magic_mem_1;
logic [63:0] magic_mem_2;
logic [63:0] magic_mem_3;
logic [63:0] magic_mem_4;
logic [63:0] magic_mem_5;
logic [63:0] magic_mem_6;
logic [63:0] magic_mem_7;
logic [63:0] magic_mem_buf_ptr;

integer payload_fd;


assign magic_mem_0 = tb_top.dram_u.mem[PROGRAM_MAGICMEMORY_ADDR_0[40:4]][PROGRAM_MAGICMEMORY_ADDR_0[3:0]*8+:64];
assign magic_mem_1 = tb_top.dram_u.mem[PROGRAM_MAGICMEMORY_ADDR_1[40:4]][PROGRAM_MAGICMEMORY_ADDR_1[3:0]*8+:64];
assign magic_mem_2 = tb_top.dram_u.mem[PROGRAM_MAGICMEMORY_ADDR_2[40:4]][PROGRAM_MAGICMEMORY_ADDR_2[3:0]*8+:64];
assign magic_mem_3 = tb_top.dram_u.mem[PROGRAM_MAGICMEMORY_ADDR_3[40:4]][PROGRAM_MAGICMEMORY_ADDR_3[3:0]*8+:64];


// to host
always @(posedge clk) begin
    inst = tb_top.core_u.csr_regfile_u.minstret;
    cycle = tb_top.core_u.csr_regfile_u.mcycle;
    ipc = inst/cycle;
    if(((dram_waddr_3_delay == PROGRAM_TOHOST_ADDR) && st_vld_3_delay)) begin //&& valid
        if (dram_wdata_3_delay == 1) begin
            $display("test pass");
            $fwrite(run_test_fd, "%s test pass", hex);
            $fdisplay(run_test_fd, "  inst = %d, cycle = %d, ipc = %f", tb_top.core_u.csr_regfile_u.minstret, tb_top.core_u.csr_regfile_u.mcycle, ipc);
            $finish;
        end else begin
`ifdef PK
            if (dram_wdata_3_delay == PROGRAM_MAGICMEMORY_ADDR) begin
                // $write("syscall = %04x\n",magic_mem_0);

                case (magic_mem_0) 
                    SYS_write: begin
                        for (int i = 0; i < magic_mem_3; i++) begin
                            magic_mem_buf_ptr = magic_mem_2 - 56'h8000_0000 + i;
                            $write("%c", tb_top.dram_u.mem[magic_mem_buf_ptr[40:4]][magic_mem_buf_ptr[3:0]*8+:8]);
                        end
                        fromhost = (0 << 56) | (0 << 48) | 1;
                        fromhost_we=1;
                    end
                    SYS_exit: begin
                        // $write("terminating\n");
                        $fdisplay(run_test_fd, "%s simulation terminated", hex);
                        `ifdef HAHA
                        $fclose(co_sim_haha_fd);
                        `endif
                        $fclose(co_sim_fd);
                        $fclose(run_test_fd);
                        $display ("\n%s simulation terminated",hex);
                        $finish;
			        end
                    default : begin
                       fromhost = (0 << 56) | (0 << 48) | 1;
                       fromhost_we = 1;
                    end
                endcase
            end else begin
                // htif putchar
                fromhost = 0;
                fromhost_we = 1;
                $write("%c", dram_wdata_3_delay[7:0]);
            end
            // $write(" tohost data is : %016x \n", dram_wdata_3_delay);

`endif
`ifndef PK
            fromhost = 1;
            if ((to_host_data_0 !== 'h40)) begin
                $display("test failed");
                $fwrite(run_test_fd, "%s test failed, ", hex);
                $fdisplay(run_test_fd, "failed parameter: %x", dram_wdata_3_delay);
                $finish;
            end
            // $display("to host addr is: %x", dram_wdata_3_delay);
            // $display("to host data which is: %x", to_host_data_0);
            // $display("to host data 1 is: %x", to_host_data_1);
            // $display("to host data 2 is: %x", to_host_data_2);
            // $display("to host data 3 is: %x", to_host_data_3);
            mid_addr = 0;
            tmp = 0;
            for (int i = 0; i < lenth; i ++) begin
                mid_addr = base_addr + i;
                tmp = {tb_top.dram_u.mem[mid_addr[PHYSICAL_ADDR_LEN-1:$clog2(DRAM_AXI_DATA_WIDTH/8)]][{mid_addr[$clog2(DRAM_AXI_DATA_WIDTH/8)-1:0],3'b0}+:8]};
                $write("%c", tmp);
            end
`endif
        end
    end else begin
        fromhost = 0;
        fromhost_we = 0;
    end
end

always @(*) begin
    lenth = to_host_data_3;
    base_addr = to_host_data_2 - 56'h8000_0000;
end

// ptw
always @(posedge clk) begin
    if (rst) begin
        mmu2cache_ptw_walk_req_rdy_i <= 1;
    end else begin
        mmu2cache_ptw_walk_resp_vld_i <= mmu2cache_ptw_walk_req_vld_o;
    end
end


always @(posedge clk) begin
    if (tb_top.core_u.rcu_u.do_rob_commit_first) begin
        $fdisplay (co_sim_fd, "-----");
        $fdisplay (co_sim_fd, "0x%0x", (tb_top.core_u.rcu_u.test_pc_first));
        // $fwrite (co_sim_fd, "p%0x, ", tb_top.core_u.rcu_u.test_prd_first);
        if (tb_top.core_u.rcu_u.test_rd_first != 0) begin
            $fwrite (co_sim_fd, "x%0d <- 0x%x\n", tb_top.core_u.rcu_u.test_rd_first, tb_top.core_u.rcu2prf_test_rdata_first);
        end
        if (tb_top.core_u.rcu_u.test_cmt_is_st_first) begin
            $fwrite (co_sim_fd, "0x%x -> 0x%x\n",tb_top.core_u.rcu_u.test_cmt_st_data_first , tb_top.core_u.rcu_u.rob_test_st_addr_first);
        end
    end
    if (tb_top.core_u.rcu_u.do_rob_commit_second) begin
        $fdisplay (co_sim_fd, "-----");
        $fdisplay (co_sim_fd, "0x%0x",(tb_top.core_u.rcu_u.test_pc_second));
        // $fwrite (co_sim_fd, "p%0x, ", tb_top.core_u.rcu_u.test_prd_second);
        if (tb_top.core_u.rcu_u.test_rd_second != 0) begin
            $fwrite (co_sim_fd, "x%0d <- 0x%x\n", tb_top.core_u.rcu_u.test_rd_second, tb_top.core_u.rcu2prf_test_rdata_second);
        end
        if (tb_top.core_u.rcu_u.test_cmt_is_st_second) begin
            $fwrite (co_sim_fd, "0x%x -> 0x%x\n", tb_top.core_u.rcu_u.test_cmt_st_data_second, tb_top.core_u.rcu_u.rob_test_st_addr_second);
        end
    end
end

`ifdef HAHA
always @(posedge clk) begin
    if (tb_top.core_u.rcu_u.do_rob_commit_first & !tb_top.core_u.rcu_u.dff_cmt_miss_delay) begin
        $fdisplay (co_sim_haha_fd, "-----");
        $fdisplay (co_sim_haha_fd, "0x%0x", (tb_top.core_u.rcu_u.test_pc_first));
        // $fwrite (co_sim_haha_fd, "p%0x, ", tb_top.core_u.rcu_u.test_prd_first);
        if (tb_top.core_u.rcu_u.test_rd_first != 0) begin
            $fwrite (co_sim_haha_fd, "x%0d <- 0x%x\n", tb_top.core_u.rcu_u.test_rd_first, tb_top.core_u.rcu2prf_test_rdata_first);
        end
        if (tb_top.core_u.rcu_u.test_cmt_is_st_first) begin
            $fwrite (co_sim_haha_fd, "0x%x -> 0x%x\n",tb_top.core_u.rcu_u.test_cmt_st_data_first , tb_top.core_u.rcu_u.rob_test_st_addr_first);
        end
    end
    if (tb_top.core_u.rcu_u.do_rob_commit_second & !tb_top.core_u.rcu_u.dff_cmt_miss_delay) begin
        $fdisplay (co_sim_haha_fd, "-----");
        $fdisplay (co_sim_haha_fd, "0x%0x",(tb_top.core_u.rcu_u.test_pc_second));
        // $fwrite (co_sim_haha_fd, "p%0x, ", tb_top.core_u.rcu_u.test_prd_second);
        if (tb_top.core_u.rcu_u.test_rd_second != 0) begin
            $fwrite (co_sim_haha_fd, "x%0d <- 0x%x\n", tb_top.core_u.rcu_u.test_rd_second, tb_top.core_u.rcu2prf_test_rdata_second);
        end
        if (tb_top.core_u.rcu_u.test_cmt_is_st_second) begin
            $fwrite (co_sim_haha_fd, "0x%x -> 0x%x\n", tb_top.core_u.rcu_u.test_cmt_st_data_second, tb_top.core_u.rcu_u.rob_test_st_addr_second);
        end
    end
end
`endif

core_top core_u(
    .clk(clk),
    .rst(rst),

    .ft2l1i_if_req_rdy_i(ft2l1i_if_req_rdy_i),
    .l1i2ft_if_resp_vld_i(l1i2ft_if_resp_vld_i),
    .l1i2ft_if_resp_if_tag_i(l1i2ft_if_resp_if_tag_i),
    .l1i2ft_if_resp_data_i(l1i2ft_if_resp_data_i),
    .ft2l1i_if_req_vld_o(ft2l1i_if_req_vld_o),
    .ft2l1i_if_req_index_o(ft2l1i_if_req_index_o),
    .ft2l1i_if_req_if_tag_o(ft2l1i_if_req_if_tag_o),
    .ft2l1i_if_req_offset_o(ft2l1i_if_req_offset_o),

    .msip_i(msip_i),
    .ssip_i(ssip_i),
    .mtip_i(mtip_i),
    .stip_i(stip_i),
    .eip_i(eip_i),
    
    .l1d2fu_lsu_ld_req_rdy_i(l1d2fu_lsu_ld_req_rdy_i),
    .fu2l1d_lsu_ld_req_vld_o(fu2l1d_lsu_ld_req_vld_o),
    .fu2l1d_lsu_ld_req_rob_index_o(fu2l1d_lsu_ld_req_rob_index_o),
    .fu2l1d_lsu_ld_req_rd_addr_o(fu2l1d_lsu_ld_req_rd_addr_o),
    .fu2l1d_lsu_ld_req_opcode_o(fu2l1d_lsu_ld_req_opcode_o),
    .fu2l1d_lsu_ld_req_index_o(fu2l1d_lsu_ld_req_index_o), 
    .fu2l1d_lsu_ld_req_offset_o(fu2l1d_lsu_ld_req_offset_o),
    .fu2l1d_lsu_ld_req_vtag_o(fu2l1d_lsu_ld_req_vtag_o), 
    .l1d2fu_lsu_st_req_rdy_i(l1d2fu_lsu_st_req_rdy_i),
    .fu2l1d_lsu_st_req_vld_o(fu2l1d_lsu_st_req_vld_o),
    .fu2l1d_lsu_st_req_is_fence_o(fu2l1d_lsu_st_req_is_fence_o),
    .fu2l1d_lsu_st_req_rob_index_o(fu2l1d_lsu_st_req_rob_index_o),
    .fu2l1d_lsu_st_req_rd_addr_o(fu2l1d_lsu_st_req_rd_addr_o),
    .fu2l1d_lsu_st_req_opcode_o(fu2l1d_lsu_st_req_opcode_o),
    .fu2l1d_lsu_st_req_paddr_o(fu2l1d_lsu_st_req_paddr_o), 
    .fu2l1d_lsu_st_req_data_o(fu2l1d_lsu_st_req_data_o),
    .l1d2fu_lsu_ld_replay_vld_i(l1d2fu_lsu_ld_replay_vld_i),

    .l1d2fu_lsu_wb_vld_i(l1d2fu_lsu_wb_vld_i),
    .l1d2fu_lsu_wb_rob_index_i(l1d2fu_lsu_wb_rob_index_i),
    .l1d2fu_lsu_prf_wb_vld_i(l1d2fu_lsu_prf_wb_vld_i),
    .l1d2fu_lsu_prf_wb_rd_addr_i(l1d2fu_lsu_prf_wb_rd_addr_i),
    .l1d2fu_lsu_prf_wb_data_i(l1d2fu_lsu_prf_wb_data_i),
    .fu2l1d_lsu_kill_req_o(fu2l1d_lsu_kill_req_o),

    .lsu_l1d_fencei_flush_vld_o(lsu_l1d_fencei_flush_vld),

    .l1d_lsu_fencei_flush_grant_i(l1d_lsu_fencei_flush_grant),
    .lsu_l1i_fencei_flush_vld_o(lsu_l1i_fencei_flush_vld),
    .l1i_lsu_fencei_flush_grant_i(l1i_lsu_fencei_flush_grant),

    `ifdef DPRAM64_2R1W
    .we(we),
    .din(din),
    .waddr(waddr),
    .raddr_d(raddr_d),
    .re_d(re_d),
    .runsigned_d(runsigned_d),  
    .wrob_index_d(wrob_index_d),
    .wrd_addr_d(wrd_addr_d),    
    .rrob_index_d(rrob_index_d),
    .rrd_addr_d(rrd_addr_d),    
    `endif // DPRAM64_2R1W

    .fu2wb_lsu_cyc_o(fu2wb_lsu_cyc_o),
    .fu2wb_lsu_stb_o(fu2wb_lsu_stb_o),
    .fu2wb_lsu_we_o(fu2wb_lsu_we_o),
    .fu2wb_lsu_adr_o(fu2wb_lsu_adr_o),
    .fu2wb_lsu_dat_o(fu2wb_lsu_dat_o),
    .fu2wb_lsu_sel_o(fu2wb_lsu_sel_o),
    .wb2fu_lsu_ack_i(wb2fu_lsu_ack_i),
    .wb2fu_lsu_dat_i(wb2fu_lsu_dat_i),

    .itlb2ic_if_resp_vld_o(itlb2ic_if_resp_vld_o),
    .itlb2icache_ic_ptag_o(itlb2icache_ic_ptag_o),
    .itlb2ft_resp_excp_vld_o(itlb2ft_resp_excp_vld_o),
    .itlb_translate_resp_miss_o(itlb_translate_resp_miss_o),
    .itlb_translate_resp_hit_o(itlb_translate_resp_hit_o),

    .dtlb2dcache_lsu_vld_o(dtlb2dcache_lsu_vld_o),
    .dtlb2dcache_lsu_ptag_o(dtlb2dcache_lsu_ptag_o),
    .dtlb2dcache_lsu_exception_vld_o(dtlb2dcache_lsu_exception_vld_o),
    .dtlb2dcache_lsu_miss_o(dtlb2dcache_lsu_miss_o),
    .dtlb2dcache_lsu_hit_o(dtlb2dcache_lsu_hit_o),
         
    .mmu2cache_ptw_walk_req_vld_o(mmu2cache_ptw_walk_req_vld_o),
    .mmu2cache_ptw_walk_req_id_o(mmu2cache_ptw_walk_req_id_o),
    .mmu2cache_ptw_walk_req_addr_o(mmu2cache_ptw_walk_req_addr_o),
    .mmu2cache_ptw_walk_req_rdy_i(mmu2cache_ptw_walk_req_rdy_i),
    .mmu2cache_ptw_walk_resp_vld_i(mmu2cache_ptw_walk_resp_vld_i),
    .mmu2cache_ptw_walk_resp_pte_i(mmu2cache_ptw_walk_resp_pte_i),
    .mmu2cache_ptw_walk_resp_rdy_o(mmu2cache_ptw_walk_resp_rdy_o)
);

// wave log
initial begin
    int dumpon = 0;
    string log;
    string wav;
    $value$plusargs("dumpon=%d",dumpon);
    if ($value$plusargs("WAVE=%s",wave_dir)) begin
        $display("WAVE== %s",wave_dir);
    end
    if(dumpon > 0) begin
      $fsdbDumpfile(wave_dir);
      $fsdbDumpvars(0,tb_top);
      $fsdbDumpvars("+struct");
      $fsdbDumpvars("+mda");
      $fsdbDumpvars("+all");
      $fsdbDumpon;
    end
end

endmodule
