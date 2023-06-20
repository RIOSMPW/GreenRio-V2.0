`ifndef LSU_DCACHE_V
`define LSU_DCACHE_V
`include "../params.vh"
module lsu_dcache_top (
    // global input 
    input clk,
    input rstn,
    input stall,
    input flush,

    // <> PRF
    input [XLEN - 1 : 0] rs1_data_i,
    input [XLEN - 1 : 0] rs2_data_i,
    output load_data_valid_o,
    output [XLEN - 1 : 0] load_data_o,
    output [PHY_REG_ADDR_WIDTH - 1 : 0] rd_addr_o,
    // lsu <> ROB
    input valid_i,
    input [ROB_INDEX_WIDTH - 1 : 0] rob_index_i, 
    input [PHY_REG_ADDR_WIDTH - 1 : 0] rd_addr_i,
    input [XLEN - 1 : 0] imm_i,
    input opcode_i,
    input [1:0] size_i,
    input load_sign_i,

    
    output [ROB_INDEX_WIDTH - 1 : 0] rob_index_o,
    output ls_done_o,
    output lsu_ready_o,
    output exception_valid_o,
    output [EXCEPTION_CODE_WIDTH - 1 : 0] ecause_o,
    //memory

    output exception_valid_forward_o
);
localparam AXI_ID_WIDTH = 10;
localparam DATA_WIDTH = 64;//bit
// S1 
wire [VIRTUAL_ADDR_LEN - 1 : 0] s1_address;
wire [EXCEPTION_CODE_WIDTH - 1 : 0] s1_ecause;
wire s1_exception_valid;

// lsu <> dcache
wire req_ready_i;
wire req_valid_o;
wire req_opcode_o; // 0 for load; 1 for store
wire req_sign_o;
wire [1:0] req_size_o; 
wire [VIRTUAL_ADDR_LEN - 1 : 0] req_addr_o;
wire [XLEN - 1 : 0] req_data_o;
wire [LSU_LSQ_SIZE_WIDTH - 1: 0] req_lsq_index_o;
wire resp_ready_o;

wire resp_valid_i;
wire [LSU_LSQ_SIZE_WIDTH - 1: 0] resp_lsq_index_i;
wire [XLEN - 1 : 0]resp_data_i;
wire resp_valid_o;
wire [63:0] ld_data_o;
wire wb_cyc;
wire wb_stb;
wire wb_we;
wire [VIRTUAL_ADDR_LEN - 1 : 0] wb_adr;
wire [XLEN-1:0] wb_dat_i;
wire [XLEN-1:0] wb_dat_o;
wire [XLEN/8-1:0] wb_sel;
wire [2:0] wb_cti;
wire [1:0] wb_bte;
wire wb_ack;
wire wb_err;
wire wb_rty;
wire [AXI_ID_WIDTH-1:0] axi_awid;
wire [VIRTUAL_ADDR_LEN-1:0] axi_awaddr;
wire [7:0] axi_awlen;
wire [2:0] axi_awsize;
wire [1:0] axi_awburst;
wire [3:0] axi_awcache;
wire [2:0] axi_awprot;
wire [3:0] axi_awqos;
wire axi_awvalid;
wire axi_awready;
wire [DATA_WIDTH-1:0] axi_wdata;
wire [DATA_WIDTH/8-1:0] axi_wstrb;
wire axi_wlast;
wire axi_wvalid;
wire axi_wready;
wire [AXI_ID_WIDTH-1:0] axi_bid;
wire [1:0] axi_bresp;
wire axi_bvalid;
wire axi_bready;
wire [AXI_ID_WIDTH-1:0] axi_arid;
wire [VIRTUAL_ADDR_LEN-1:0] axi_araddr;
wire [7:0] axi_arlen;
wire [2:0] axi_arsize;
wire [1:0] axi_arburst;
wire [3:0] axi_arcache;
wire [2:0] axi_arprot;
wire [3:0] axi_arqos;
wire axi_arvalid;
wire axi_arready;
wire [AXI_ID_WIDTH-1:0] axi_rid;
wire [DATA_WIDTH-1:0] axi_rdata;
wire [1:0] axi_rresp;
wire axi_rlast;
wire axi_rvalid;
wire axi_rready;
wire req_ready_o;
wire opcode;
wire [VIRTUAL_ADDR_LEN - 1 : 0] req_addr;
wire [2:0] type_i;
wire [XLEN -1:0] st_data;
wire req_valid_i = '0;
wire [64-1:0] cycle = '0;

assign exception_valid_forward_o = s1_exception_valid; //FIXME: need to solve this, add reg in fu

agu lsu_agu(
    .base_i(rs1_data_i),
    .offset_i(imm_i),
    .addr_o(s1_address)
);

ac lsu_ac(
    .valid_i(valid_i),
    .rd_addr_i(rd_addr_i),
    .opcode_i(opcode_i),
    .size_i(size_i),
    .addr_i(s1_address),

    .exception_valid_o(s1_exception_valid),
    .ecause_o(s1_ecause)
);
               
lsq nblsu_lsq(
    .clk(clk),
    .rstn(rstn),
    .flush(flush),
    // <> s0 
    .address_i(s1_address),
    .rob_index_i(rob_index_i),
    .rs2_data_i(rs2_data_i),
    .opcode_i(opcode_i),
    .size_i(size_i),
    .load_sign_i(load_sign_i),
    .valid_i(valid_i),
    .rd_addr_i(rd_addr_i),
    .ecause_i(s1_ecause),
    .exception_valid_i(s1_exception_valid),

    // <> rob 
    .load_data_valid_o(load_data_valid_o),
    .load_data_o(load_data_o),
    .rd_addr_o(rd_addr_o),
    .rob_index_o(rob_index_o),
    .ls_done_o(ls_done_o),
    .lsu_ready_o(lsu_ready_o),
    .exception_valid_o(exception_valid_o),
    .ecause_o(ecause_o),

    // lsu <> dcache
    .req_ready_i(req_ready_i),
    .req_valid_o(req_valid_o),
    .req_opcode_o(req_opcode_o), // 0 for load, 1 for store
    .req_sign_o(req_sign_o),
    .req_size_o(req_size_o), 
    .req_addr_o(req_addr_o),
    .req_data_o(req_data_o),
    // .req_rob_index_o(req_rob_index_o),
    .req_lsq_index_o(req_lsq_index_o),
// `ifdef LSU_SELFCHECK
//     .head_o(head_o),
//     .tail_o(tail_o),
//     .req_pt_o(req_pt_o),
// `endif // LSU_SELFCHECK
    // debug
    

    .resp_valid_i(resp_valid_i),
    .resp_lsq_index_i(resp_lsq_index_i),
    .resp_data_i(resp_data_i),
    .resp_ready_o(resp_ready_o)
);

nonblock_dcache nblsu_nbdcache(
    .clk(clk),
    .rstn(rstn),
    
    //req
    .req_valid_i(req_valid_o),
    .req_ready_o(req_ready_i),
    .opcode(req_opcode_o),//0 load ,1 store 
    .req_addr_i(req_addr_o),
    .type_i({req_sign_o, req_size_o}),
    .st_data_i(req_data_o),
    .rob_index_i(req_lsq_index_o), 

    //resp
    .resp_ready_i(resp_ready_o),//no use
    .resp_valid_o(resp_valid_i),//no use
    .ld_data_o(resp_data_i),
    .rob_index_o(resp_lsq_index_i), 

    //memory
    .wb_cyc_o (wb_cyc),
    .wb_stb_o (wb_stb),
    .wb_we_o (wb_we),
    .wb_adr_o (wb_adr),
    .wb_dat_o (wb_dat_o),
    .wb_sel_o (wb_sel),
    .wb_cti_o (wb_cti),
    .wb_bte_o (wb_bte),
    .wb_ack_i (wb_ack),
    .wb_err_i (wb_err),
    .wb_rty_i (wb_rty),
    .wb_dat_i (wb_dat_i)
);
wb2axi 
#(
  .DATA_WIDTH(DATA_WIDTH),
  .ADDR_WIDTH(VIRTUAL_ADDR_LEN),
  .AXI_ID_WIDTH(AXI_ID_WIDTH),
  .AXI_ID(0)
)
wb2axi_u
(
    .clk (clk),
    .rst (rstn),
    .wb_cyc_i (wb_cyc),
    .wb_stb_i (wb_stb),
    .wb_we_i (wb_we),
    .wb_adr_i (wb_adr),
    .wb_dat_i (wb_dat_o),
    .wb_sel_i (wb_sel),
    .wb_cti_i (wb_cti),
    .wb_bte_i (wb_bte),
    .wb_ack_o (wb_ack),
    .wb_err_o (wb_err),
    .wb_rty_o (wb_rty),
    .wb_dat_o (wb_dat_i),


    .m_axi_awid (axi_awid),
    .m_axi_awaddr (axi_awaddr),
    .m_axi_awlen (axi_awlen),
    .m_axi_awsize (axi_awsize),
    .m_axi_awburst (axi_awburst),
    .m_axi_awcache (axi_awcache),
    .m_axi_awprot (axi_awprot),
    .m_axi_awqos (axi_awqos),
    .m_axi_awvalid (axi_awvalid),
    .m_axi_awready (axi_awready),

    .m_axi_wdata (axi_wdata),
    .m_axi_wstrb (axi_wstrb),
    .m_axi_wlast (axi_wlast),
    .m_axi_wvalid (axi_wvalid),
    .m_axi_wready (axi_wready),
    
    .m_axi_bid (axi_bid),
    .m_axi_bresp (axi_bresp),
    .m_axi_bvalid (axi_bvalid),
    .m_axi_bready (axi_bready),
    
    .m_axi_arid (axi_arid),
    .m_axi_araddr (axi_araddr),
    .m_axi_arlen (axi_arlen),
    .m_axi_arsize (axi_arsize),
    .m_axi_arburst (axi_arburst),
    .m_axi_arcache (axi_arcache),
    .m_axi_arprot (axi_arprot),
    .m_axi_arqos (axi_arqos),
    .m_axi_arvalid (axi_arvalid),
    .m_axi_arready (axi_arready),
    
    .m_axi_rid (axi_rid),
    .m_axi_rdata (axi_rdata),
    .m_axi_rresp (axi_rresp),
    .m_axi_rlast (axi_rlast),
    .m_axi_rvalid (axi_rvalid),
    .m_axi_rready (axi_rready)
);

axi_mem 
#(
  .ID_WIDTH(AXI_ID_WIDTH),
  .MEM_SIZE(1<<29), //byte 512MB
  .mem_clear(1),
  .mem_simple_seq(0),
  .READ_DELAY_CYCLE(1),
  .AXI_DATA_WIDTH(DATA_WIDTH) // bit
)
axi_mem_u
(
    .clk (clk),
	.rst_n (rstn),

    .i_awid (axi_awid),
    .i_awaddr (axi_awaddr),
    .i_awlen (axi_awlen),
    .i_awsize (axi_awsize),
    .i_awburst (axi_awburst),
    .i_awvalid (axi_awvalid),
	.o_awready (axi_awready),

    .i_arid (axi_arid),
	.i_araddr (axi_araddr),
	.i_arlen (axi_arlen),
    .i_arsize (axi_arsize),
    .i_arburst (axi_arburst),
	.i_arvalid (axi_arvalid),
    .o_arready (axi_arready),

    .i_wdata (axi_wdata),
    .i_wstrb (axi_wstrb),
    .i_wlast (axi_wlast),
	.i_wvalid (axi_wvalid),
	.o_wready (axi_wready),

    .o_bid (axi_bid),
	.o_bresp (axi_bresp),
	.o_bvalid (axi_bvalid),
	.i_bready (axi_bready),

    .o_rid (axi_rid),
    .o_rdata (axi_rdata),
	.o_rresp (axi_rresp),
	.o_rlast (axi_rlast),
	.o_rvalid (axi_rvalid),
	.i_rready (axi_rready)
);

endmodule
`endif // LSU_DCACHE_V
