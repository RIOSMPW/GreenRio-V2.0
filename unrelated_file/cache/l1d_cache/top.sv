`timescale 1ns/1ps
module top
();
localparam XLEN = 64;
localparam VIRTUAL_ADDR_LEN = 32;
localparam AXI_ID_WIDTH = 10;
localparam DATA_WIDTH = 64;//bit
logic clk,rstn;
  //clock generate
  initial begin
    clk = 1'b1;
    forever #10 clk = ~clk;
  end

  


  //reset generate
  initial begin
    rstn = 1'b0;
    #1000;
    rstn = 1'b1;
  end
  
  //wave dump
  initial begin
    int dumpon = 0;
    string log;
    string wav;
    $value$plusargs("dumpon=%d",dumpon);
    if ($value$plusargs("sim_log=%s",log)) begin
        $display("!!!!!!!!!!wave_log= %s",log);
    end
    wav = {log,"/waves.fsdb"};
    $display("!!!!!!wave_log= %s",wav);
    if(dumpon > 0) begin
      $fsdbDumpfile(wav);
      $fsdbDumpvars(0,top);
      $fsdbDumpvars("+struct");
      $fsdbDumpvars("+mda");
      $fsdbDumpvars("+all");
      $fsdbDumpon;
    end
  end




logic resp_valid_o;
logic [63:0] ld_data_o;
logic wb_cyc;
logic wb_stb;
logic wb_we;
logic [VIRTUAL_ADDR_LEN - 1 : 0] wb_adr;
logic [XLEN-1:0] wb_dat_i;
logic [XLEN-1:0] wb_dat_o;
logic [XLEN/8-1:0] wb_sel;
logic [2:0] wb_cti;
logic [1:0] wb_bte;
logic wb_ack;
logic wb_err;
logic wb_rty;
logic [AXI_ID_WIDTH-1:0] axi_awid;
logic [VIRTUAL_ADDR_LEN-1:0] axi_awaddr;
logic [7:0] axi_awlen;
logic [2:0] axi_awsize;
logic [1:0] axi_awburst;
logic [3:0] axi_awcache;
logic [2:0] axi_awprot;
logic [3:0] axi_awqos;
logic axi_awvalid;
logic axi_awready;
logic [DATA_WIDTH-1:0] axi_wdata;
logic [DATA_WIDTH/8-1:0] axi_wstrb;
logic axi_wlast;
logic axi_wvalid;
logic axi_wready;
logic [AXI_ID_WIDTH-1:0] axi_bid;
logic [1:0] axi_bresp;
logic axi_bvalid;
logic axi_bready;
logic [AXI_ID_WIDTH-1:0] axi_arid;
logic [VIRTUAL_ADDR_LEN-1:0] axi_araddr;
logic [7:0] axi_arlen;
logic [2:0] axi_arsize;
logic [1:0] axi_arburst;
logic [3:0] axi_arcache;
logic [2:0] axi_arprot;
logic [3:0] axi_arqos;
logic axi_arvalid;
logic axi_arready;
logic [AXI_ID_WIDTH-1:0] axi_rid;
logic [DATA_WIDTH-1:0] axi_rdata;
logic [1:0] axi_rresp;
logic axi_rlast;
logic axi_rvalid;
logic axi_rready;
logic req_ready_o;
logic opcode;
logic [VIRTUAL_ADDR_LEN - 1 : 0] req_addr;
logic [2:0] type_i;
logic [XLEN -1:0] st_data;
logic req_valid_i = '0;
logic [1:0] rob_index_i;
logic [1:0] rob_index_o;

logic [64-1:0] cycle = '0;
always @(posedge clk) begin
  cycle <= cycle + 1;
  if(cycle == 1005) begin
        opcode <= 1'b1;
        req_addr <= 32'h12345678;
        type_i <= 3'b000;
        st_data <= 64'h0000000000000022;
        req_valid_i <= '1;
        rob_index_i <= 2'b11;
  end 


  if (cycle == 1006) begin
        opcode <= 1'b0;
        req_addr <= 32'hffffffff;
        type_i <= 3'b000;
        st_data <= 64'h0000000000000033;
        req_valid_i <= '1;
        rob_index_i <= 2'b00;
  end 
  if(cycle == 1007) begin
        opcode <= 1'b1;
        req_addr <= 32'h0fffffff;
        type_i <= 3'b000;
        st_data <= 64'h0000000000000044;
        req_valid_i <= '1;
        rob_index_i <= 2'b01;
  end 
  if(cycle == 1008) begin
        opcode <= 1'b0;
        req_addr <= 32'h0fffffff;
        type_i <= 3'b001;
        st_data <= 64'h0000000000000033;
        req_valid_i <= '1;
        rob_index_i <= 2'b10;
  end 
  if (cycle == 1009) begin
        req_valid_i <= '0;
  end


  if(cycle == 1020) begin
        rstn <= 1'b0;
  end
end

l1dcache 
#(
  .XLEN(XLEN),
  .VIRTUAL_ADDR_LEN(VIRTUAL_ADDR_LEN)
)
l1dcache_u
(
    .clk (clk),
    .rstn (rstn),
    .req_valid_i (req_valid_i),
    .req_ready_o (req_ready_o),
    .opcode (opcode),
    .req_addr_i (req_addr),
    .type_i (type_i),
    .st_data_i (st_data),
    .rob_index_i (rob_index_i),

    .resp_ready_i (1'b1),
    .resp_valid_o (resp_valid_o),
    .ld_data_o (ld_data_o),
    .rob_index_o (rob_index_o),

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