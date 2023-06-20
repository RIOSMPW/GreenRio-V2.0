`timescale 1ns/1ps
module top
    import rvh_pkg::*;
    import uop_encoding_pkg::*;
    import rvh_l1d_pkg::*;
    import riscv_pkg::*;
`ifdef RUBY
    import ruby_pkg::*;
`endif
();

  logic clk, rst_n;
  logic [10-1:0] counter;
  logic [64-1:0] cycle;
  genvar i;
  
  //clock generate
  initial begin
    clk = 1'b0;
    forever #0.5 clk = ~clk;
  end

  //reset generate
  initial begin
    rst_n = 1'b0;
    #20;
    rst_n = 1'b1;
  end
  
`ifndef RUBY
  initial begin
    #10000;
    $finish();
  end
`endif
  // always_ff @(posedge clk) begin
  //   if(cycle >= 50) begin
  //     $finish();
  //   end
  // end

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


  always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
      counter <= '0;
      cycle   <= '0;
    end else begin
      counter <= counter + 1;
      cycle   <= cycle + 1;
    end
  end

  // always_comb begin
  //   if(counter[6:0] == 7'b0) begin
  //     $display("counter == %d", counter);
  //   end
  // end

`ifdef RUBY
  int rseed0 = RT_CHECK_GEN_ADDR_W'(1<<(RT_CHECK_GEN_ADDR_W-1));//?
  int rseed1 = $bits(lsu_op_e)'(1<<($bits(lsu_op_e)-1));//?
  int timeout_count= 20000;
  int debug_print= 0;
  
  `ifdef RT_MODE_CLASSIC
  logic [RT_CID_DELTA_NUM_W-1:0]    _rt_cid_delta_seed = '0;
  logic [RT_CHECK_NUM_W-1:0]        _rt_cid_base_seed = '0;
  `else
  logic [RT_CHECK_GEN_ADDR_W-1:0]   _rt_info_addr_seed = RT_CHECK_GEN_ADDR_W'(1<<(RT_CHECK_GEN_ADDR_W-1));
  logic [$bits(lsu_op_e)-1:0]       _rt_info_opcode_seed = $bits(lsu_op_e)'(1<<($bits(lsu_op_e)-1));
  `endif 
  
  initial begin

    #1
    `ifdef RT_MODE_CLASSIC
        _rt_cid_delta_seed = rseed0;
        _rt_cid_base_seed  = rseed1;
    `else
        _rt_info_addr_seed = rseed0;
        _rt_info_opcode_seed = rseed1;
    `endif
    
  end
`endif


  logic              l1d_l2_arvalid;
  logic              l1d_l2_arready;
  cache_mem_if_ar_t  l1d_l2_ar;
  
  logic              l1d_l2_rvalid ;
  logic              l1d_l2_rready ; 
  cache_mem_if_r_t   l1d_l2_r;
  
  logic              l1d_l2_awvalid ;
  logic              l1d_l2_awready ;
  cache_mem_if_aw_t  l1d_l2_aw ;
  
  logic              l1d_l2_wvalid ;
  logic              l1d_l2_wready ;
  cache_mem_if_w_t   l1d_l2_w ;
  
  logic              l1d_l2_bvalid;
  logic              l1d_l2_bready;
  cache_mem_if_b_t   l1d_l2_b;
  
  // LS_PIPE -> D$ : LD Request
  logic [LSU_ADDR_PIPE_COUNT-1:0]                     ls_pipe_l1d_ld_req_vld;
  logic [LSU_ADDR_PIPE_COUNT-1:0]                     ls_pipe_l1d_ld_req_io_region;
  logic [LSU_ADDR_PIPE_COUNT-1:0][ ROB_TAG_WIDTH-1:0] ls_pipe_l1d_ld_req_rob_tag;
  logic [LSU_ADDR_PIPE_COUNT-1:0][PREG_TAG_WIDTH-1:0] ls_pipe_l1d_ld_req_prd;
  logic [LSU_ADDR_PIPE_COUNT-1:0][  LDU_OP_WIDTH-1:0] ls_pipe_l1d_ld_req_opcode;
`ifdef RUBY
  logic [LSU_ADDR_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH -1:0] ls_pipe_l1d_ld_req_lsu_tag;
`endif

  logic [LSU_ADDR_PIPE_COUNT-1:0][  L1D_INDEX_WIDTH-1:0 ] ls_pipe_l1d_ld_req_idx;
  logic [LSU_ADDR_PIPE_COUNT-1:0][  L1D_OFFSET_WIDTH-1:0] ls_pipe_l1d_ld_req_offset;
  logic [LSU_ADDR_PIPE_COUNT-1:0][  L1D_TAG_WIDTH-1:0]    ls_pipe_l1d_ld_req_vtag;

  logic [LSU_ADDR_PIPE_COUNT-1:0]                     ls_pipe_l1d_ld_req_rdy;
`ifdef RUBY
  logic [LSU_ADDR_PIPE_COUNT-1:0][  L1D_BANK_ID_INDEX_WIDTH-1:0] ls_pipe_l1d_ld_req_hit_bank_id;
  logic [LSU_DATA_PIPE_COUNT-1:0][  L1D_BANK_ID_INDEX_WIDTH-1:0] ls_pipe_l1d_st_req_hit_bank_id;
`endif
  // LS_PIPE -> D$ : ST Request
  logic [LSU_DATA_PIPE_COUNT-1:0]                         ls_pipe_l1d_st_req_vld;
  logic [LSU_DATA_PIPE_COUNT-1:0]                         ls_pipe_l1d_st_req_io_region;
  logic [LSU_DATA_PIPE_COUNT-1:0][     ROB_TAG_WIDTH-1:0] ls_pipe_l1d_st_req_rob_tag;
  logic [LSU_DATA_PIPE_COUNT-1:0][    PREG_TAG_WIDTH-1:0] ls_pipe_l1d_st_req_prd;
  logic [LSU_DATA_PIPE_COUNT-1:0][      STU_OP_WIDTH-1:0] ls_pipe_l1d_st_req_opcode;
`ifdef RUBY
  logic [LSU_DATA_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH -1:0]ls_pipe_l1d_st_req_lsu_tag;
`endif
  logic [LSU_DATA_PIPE_COUNT-1:0][       PADDR_WIDTH-1:0] ls_pipe_l1d_st_req_paddr;

`ifdef SINGLE_BANK_TEST
  logic [LSU_DATA_PIPE_COUNT-1:0][  L1D_STB_DATA_WIDTH  -1:0] ls_pipe_l1d_st_req_data; // data from stb
`else
  logic [LSU_DATA_PIPE_COUNT-1:0][            XLEN  -1:0] ls_pipe_l1d_st_req_data; // data from lsu
`endif
  logic [LSU_DATA_PIPE_COUNT-1:0][  L1D_STB_DATA_WIDTH/8-1:0] ls_pipe_l1d_st_req_data_byte_mask; // data byte mask from stb
  
  logic [LSU_DATA_PIPE_COUNT-1:0]                         ls_pipe_l1d_st_req_rdy;

  // DTLB -> D$
  logic [LSU_ADDR_PIPE_COUNT-1:0]                         dtlb_l1d_resp_vld;
  logic [LSU_ADDR_PIPE_COUNT-1:0]                         dtlb_l1d_resp_excp_vld; // s1 kill
  logic [LSU_ADDR_PIPE_COUNT-1:0]                         dtlb_l1d_resp_hit;      // s1 kill
  logic [LSU_ADDR_PIPE_COUNT-1:0][       PPN_WIDTH-1:0]   dtlb_l1d_resp_ppn;  // VIPT, get at s1 if tlb hit
  
  logic [LSU_ADDR_PIPE_COUNT-1:0]                         dtlb_l1d_resp_rdy;

  // D$ -> LSQ, mshr full replay
  logic [LSU_ADDR_PIPE_COUNT-1:0]                         l1d_ls_pipe_replay_vld;
  logic [LSU_ADDR_PIPE_COUNT-1:0]                         l1d_ls_pipe_mshr_full;
`ifdef RUBY
  logic [LSU_ADDR_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH-1:0] l1d_ls_pipe_replay_lsu_tag;
`endif

  // D$ -> ROB : Write Back
  logic [LSU_ADDR_PIPE_COUNT+LSU_DATA_PIPE_COUNT-1:0]                         l1d_rob_wb_vld;
  logic [LSU_ADDR_PIPE_COUNT+LSU_DATA_PIPE_COUNT-1:0][     ROB_TAG_WIDTH-1:0] l1d_rob_wb_rob_tag;
  // D$ -> Int PRF : Write Back
  logic [LSU_ADDR_PIPE_COUNT-1:0]                         l1d_int_prf_wb_vld;
  logic [LSU_ADDR_PIPE_COUNT-1:0][    PREG_TAG_WIDTH-1:0] l1d_int_prf_wb_tag;
  logic [LSU_ADDR_PIPE_COUNT-1:0][              XLEN-1:0] l1d_int_prf_wb_data;
`ifdef RUBY
  logic [LSU_ADDR_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH -1:0]l1d_lsu_lsu_tag;
`endif
  
  // L1D-> LSU : evict or snooped // move to lid, not in bank // TODO:
//  logic                          l1d_lsu_invld_vld;
//  logic [PADDR_WIDTH-1:0]        l1d_lsu_invld_tag; // tag+bankid
  

`ifdef RUBY
//rubytop_l1d_adaptor
parameter RUBY_TOP_L1D_PORT_NUM = 2;
`ifdef SINGLE_BANK_TEST
parameter RT_LD_ST_PAIR_NUM  = 1;
`else
parameter RT_LD_ST_PAIR_NUM  = (LSU_ADDR_PIPE_COUNT+LSU_DATA_PIPE_COUNT)/2; // 2 load + 2 store ports
`endif
logic                [RT_LD_ST_PAIR_NUM-1:0][RUBY_TOP_L1D_PORT_NUM -1:0] lsu_l1d_req_valid;
logic                [RT_LD_ST_PAIR_NUM-1:0][RUBY_TOP_L1D_PORT_NUM -1:0] lsu_l1d_req_ready;
rrv64_lsu_l1d_req_t  [RT_LD_ST_PAIR_NUM-1:0][RUBY_TOP_L1D_PORT_NUM -1:0] lsu_l1d_req;
logic                [RT_LD_ST_PAIR_NUM-1:0][RUBY_TOP_L1D_PORT_NUM -1:0] lsu_l1d_resp_valid;
logic                [RT_LD_ST_PAIR_NUM-1:0][RUBY_TOP_L1D_PORT_NUM -1:0] lsu_l1d_resp_ready;
rrv64_lsu_l1d_resp_t [RT_LD_ST_PAIR_NUM-1:0][RUBY_TOP_L1D_PORT_NUM -1:0] lsu_l1d_resp;

//l1dc
logic                [LSU_ADDR_PIPE_COUNT-1:0] lsu_l1d_ld_req_valid;
logic                [LSU_ADDR_PIPE_COUNT-1:0] lsu_l1d_ld_req_ready;
rrv64_lsu_l1d_req_t  [LSU_ADDR_PIPE_COUNT-1:0] lsu_l1d_ld_req;
logic                [LSU_ADDR_PIPE_COUNT-1:0] lsu_l1d_ld_resp_valid;
rrv64_lsu_l1d_resp_t [LSU_ADDR_PIPE_COUNT-1:0] lsu_l1d_ld_resp;

`ifdef RUBY
logic                [LSU_ADDR_PIPE_COUNT-1:0][L1D_BANK_ID_INDEX_WIDTH-1:0] lsu_l1d_ld_req_bank_id;
logic                [LSU_DATA_PIPE_COUNT-1:0][L1D_BANK_ID_INDEX_WIDTH-1:0] lsu_l1d_st_req_bank_id;
`endif

logic [LSU_ADDR_PIPE_COUNT-1:0][LDU_OP_WIDTH-1:0]         ls_pipe_l1d_ld_req_opcode_transed;
logic [LSU_DATA_PIPE_COUNT-1:0][STU_OP_WIDTH-1:0]         ls_pipe_l1d_st_req_opcode_transed;
logic [LSU_DATA_PIPE_COUNT-1:0][L1D_STB_DATA_WIDTH-1:0]       ls_pipe_l1d_st_req_data_transed; // data from stb
logic [LSU_DATA_PIPE_COUNT-1:0][L1D_STB_DATA_WIDTH/8-1:0]     ls_pipe_l1d_st_req_data_byte_mask_transed;


logic[LSU_ADDR_PIPE_COUNT-1:0]                            l1d_lsu_sleep_valid;
logic[LSU_ADDR_PIPE_COUNT-1:0][RRV64_LSU_ID_WIDTH-1:0]    l1d_lsu_sleep_ldq_id;
logic[LSU_ADDR_PIPE_COUNT-1:0]                            l1d_lsu_sleep_cache_miss;
logic[LSU_ADDR_PIPE_COUNT-1:0][RRV64_L1D_MSHR_IDX_W -1:0] l1d_lsu_sleep_mshr_id;
logic[LSU_ADDR_PIPE_COUNT-1:0]                            l1d_lsu_sleep_mshr_full;
logic[LSU_ADDR_PIPE_COUNT-1:0]                            l1d_lsu_wakeup_cache_refill_valid;
logic[LSU_ADDR_PIPE_COUNT-1:0][RRV64_L1D_MSHR_IDX_W -1:0] l1d_lsu_wakeup_mshr_id;
logic[LSU_ADDR_PIPE_COUNT-1:0]                            l1d_lsu_wakeup_mshr_avail;

logic                [LSU_DATA_PIPE_COUNT-1:0] lsu_l1d_st_req_valid;
logic                [LSU_DATA_PIPE_COUNT-1:0] lsu_l1d_st_req_ready;
rrv64_lsu_l1d_req_t  [LSU_DATA_PIPE_COUNT-1:0] lsu_l1d_st_req;
logic                [LSU_DATA_PIPE_COUNT-1:0] lsu_l1d_st_resp_valid;
rrv64_lsu_l1d_resp_t [LSU_DATA_PIPE_COUNT-1:0] lsu_l1d_st_resp;

`ifdef SINGLE_BANK_TEST
  rubytop_l1d_adaptor rubytop_l1d_adaptor_u
  (
  .clk                   (clk)
  ,.rst_n                 (rst_n)
  // ruby
  ,.top_l1d_req_valid_i   (lsu_l1d_req_valid)
  ,.top_l1d_req_i         (lsu_l1d_req)
  ,.top_l1d_req_ready_o   (lsu_l1d_req_ready)
  ,.top_l1d_resp_valid_o  (lsu_l1d_resp_valid)
  ,.top_l1d_resp_o        (lsu_l1d_resp)
  ,.top_l1d_resp_ready_i  (lsu_l1d_resp_ready)
  // l1dc
  ,.ld_l1d_req_valid_o    (lsu_l1d_ld_req_valid)
  ,.ld_l1d_req_o          (lsu_l1d_ld_req)
  ,.ld_l1d_req_ready_i    (lsu_l1d_ld_req_ready)
  ,.ld_l1d_resp_valid_i   (lsu_l1d_ld_resp_valid)
  ,.ld_l1d_resp_i         (lsu_l1d_ld_resp)

  ,.st_l1d_req_valid_o    (lsu_l1d_st_req_valid)
  ,.st_l1d_req_o          (lsu_l1d_st_req)
  ,.st_l1d_req_ready_i    (lsu_l1d_st_req_ready)
  ,.st_l1d_resp_valid_i   (lsu_l1d_st_resp_valid)
  ,.st_l1d_resp_i         (lsu_l1d_st_resp)

  ,.l1d_lsu_sleep_valid_i (l1d_lsu_sleep_valid)
  ,.l1d_lsu_sleep_ldq_id_i (l1d_lsu_sleep_ldq_id)
  ,.l1d_lsu_sleep_cache_miss_i (l1d_lsu_sleep_cache_miss)
  ,.l1d_lsu_sleep_mshr_id_i (l1d_lsu_sleep_mshr_id)
  ,.l1d_lsu_sleep_mshr_full_i (l1d_lsu_sleep_mshr_full)
  ,.l1d_lsu_wakeup_cache_refill_valid_i (l1d_lsu_wakeup_cache_refill_valid)
  ,.l1d_lsu_wakeup_mshr_id_i (l1d_lsu_wakeup_mshr_id)
  ,.l1d_lsu_wakeup_mshr_avail_i (l1d_lsu_wakeup_mshr_avail)
  );

  rubytest_top rubytest_top_u
  (
      .clk                       (clk),
      .rst_n                     (rst_n),
      .rt_l1d_req_valid_o        (lsu_l1d_req_valid),
      .rt_l1d_req_o              (lsu_l1d_req),
      .rt_l1d_req_ready_i        (lsu_l1d_req_ready),
      .rt_l1d_resp_valid_i       (lsu_l1d_resp_valid),
      .rt_l1d_resp_i             (lsu_l1d_resp),
      .rt_l1d_resp_ready_o       (lsu_l1d_resp_ready),
  `ifdef RT_MODE_CLASSIC
    .rt_cid_delta_seed_i        (_rt_cid_delta_seed),
    .rt_cid_base_seed_i         (_rt_cid_base_seed),
  `else
    .rt_info_addr_seed_i        (_rt_info_addr_seed),
    .rt_info_opcode_seed_i      (_rt_info_opcode_seed),
  `endif
    .rt_debug_info              ()
  );
`else
generate
  for(i = 0; i < RT_LD_ST_PAIR_NUM; i++) begin: gen_rubytop_l1d_adaptor
    rubytop_l1d_adaptor rubytop_l1d_adaptor_u
    (
    .clk                   (clk)
    ,.rst_n                 (rst_n)
    // ruby
    ,.top_l1d_req_valid_i   (lsu_l1d_req_valid  [i])
    ,.top_l1d_req_i         (lsu_l1d_req        [i])
    ,.top_l1d_req_ready_o   (lsu_l1d_req_ready  [i])
    ,.top_l1d_resp_valid_o  (lsu_l1d_resp_valid [i])
    ,.top_l1d_resp_o        (lsu_l1d_resp       [i])
    ,.top_l1d_resp_ready_i  (lsu_l1d_resp_ready [i])
    // l1dc
    ,.ld_l1d_req_valid_o    (lsu_l1d_ld_req_valid [i])
    ,.ld_l1d_req_o          (lsu_l1d_ld_req       [i])
    ,.ld_l1d_req_ready_i    (lsu_l1d_ld_req_ready [i])
    ,.ld_l1d_resp_valid_i   (lsu_l1d_ld_resp_valid[i])
    ,.ld_l1d_resp_i         (lsu_l1d_ld_resp      [i])

    ,.st_l1d_req_valid_o    (lsu_l1d_st_req_valid [i])
    ,.st_l1d_req_o          (lsu_l1d_st_req       [i])
    ,.st_l1d_req_ready_i    (lsu_l1d_st_req_ready [i])
    ,.st_l1d_resp_valid_i   (lsu_l1d_st_resp_valid[i])
    ,.st_l1d_resp_i         (lsu_l1d_st_resp      [i])

    ,.l1d_lsu_sleep_valid_i               (l1d_lsu_sleep_valid        [i])
    ,.l1d_lsu_sleep_ldq_id_i              (l1d_lsu_sleep_ldq_id       [i])
    ,.l1d_lsu_sleep_cache_miss_i          (l1d_lsu_sleep_cache_miss   [i])
    ,.l1d_lsu_sleep_mshr_id_i             (l1d_lsu_sleep_mshr_id      [i])
    ,.l1d_lsu_sleep_mshr_full_i           (l1d_lsu_sleep_mshr_full    [i])
    ,.l1d_lsu_wakeup_cache_refill_valid_i (l1d_lsu_wakeup_cache_refill_valid[i])
    ,.l1d_lsu_wakeup_mshr_id_i            (l1d_lsu_wakeup_mshr_id     [i])
    ,.l1d_lsu_wakeup_mshr_avail_i         (l1d_lsu_wakeup_mshr_avail  [i])
    );
  end
endgenerate

rubytest_top rubytest_top_u
(
  .clk                       (clk),
  .rst_n                     (rst_n),
  .rt_l1d_req_valid_o        (lsu_l1d_req_valid),
  .rt_l1d_req_o              (lsu_l1d_req),
  .rt_l1d_req_ready_i        (lsu_l1d_req_ready),
  .rt_l1d_resp_valid_i       (lsu_l1d_resp_valid),
  .rt_l1d_resp_i             (lsu_l1d_resp),
  .rt_l1d_resp_ready_o       (lsu_l1d_resp_ready),
`ifdef RT_MODE_CLASSIC
  .rt_cid_delta_seed_i        (_rt_cid_delta_seed),
  .rt_cid_base_seed_i         (_rt_cid_base_seed),
`else
  .rt_info_addr_seed_i        (_rt_info_addr_seed),
  .rt_info_opcode_seed_i      (_rt_info_opcode_seed),
`endif
  .rt_debug_info              ()
);
`endif

`ifdef SINGLE_BANK_TEST
rrv2rvh_ruby_reqtype_trans rrv2rvh_ruby_reqtype_trans_ld_req_u
(
  .rrv64_ruby_req_type_i      (lsu_l1d_ld_req.req_type   ),
  .rvh_ld_req_type_o          (ls_pipe_l1d_ld_req_opcode_transed),
  .rvh_st_req_type_o          (),
  .is_ld_o                    ()
);
rrv2rvh_ruby_reqtype_trans rrv2rvh_ruby_reqtype_trans_st_req_u
(
  .rrv64_ruby_req_type_i      (lsu_l1d_st_req.req_type   ),
  .rvh_ld_req_type_o          (),
  .rvh_st_req_type_o          (ls_pipe_l1d_st_req_opcode_transed),
  .is_ld_o                    ()
);
`else
generate
  for(i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
    rrv2rvh_ruby_reqtype_trans rrv2rvh_ruby_reqtype_trans_ld_req_u
    (
      .rrv64_ruby_req_type_i      (lsu_l1d_ld_req[i].req_type   ),
      .rvh_ld_req_type_o          (ls_pipe_l1d_ld_req_opcode_transed[i]),
      .rvh_st_req_type_o          (),
      .is_ld_o                    ()
    );
  end

  for(i = 0; i < LSU_DATA_PIPE_COUNT; i++) begin
    rrv2rvh_ruby_reqtype_trans rrv2rvh_ruby_reqtype_trans_st_req_u
    (
      .rrv64_ruby_req_type_i      (lsu_l1d_st_req[i].req_type   ),
      .rvh_ld_req_type_o          (),
      .rvh_st_req_type_o          (ls_pipe_l1d_st_req_opcode_transed[i]),
      .is_ld_o                    ()
    );
  end
endgenerate
`endif

`ifdef SINGLE_BANK_TEST
rrv2rvh_ruby_stmask_trans rrv2rvh_ruby_stmask_trans_st_req_u
(
  .st_dat_i                             (lsu_l1d_st_req.st_dat                    ),
  .st_offset_i                          (lsu_l1d_st_req.paddr[L1D_OFFSET_WIDTH-1:0]   ),
  .st_opcode_i                          (ls_pipe_l1d_st_req_opcode_transed        ),
  .ls_pipe_l1d_st_req_data_o            (ls_pipe_l1d_st_req_data_transed          ), // data from stb
  .ls_pipe_l1d_st_req_data_byte_mask_o  (ls_pipe_l1d_st_req_data_byte_mask_transed) // data byte mask from stb
);
`endif
`endif

`ifdef RUBY
  always_comb begin
    // LS_PIPE -> D$ : LD Request
    for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
      ls_pipe_l1d_ld_req_vld       [i] = lsu_l1d_ld_req_valid[i];
      ls_pipe_l1d_ld_req_io_region [i] = 1'b0;
      ls_pipe_l1d_ld_req_rob_tag   [i] = lsu_l1d_ld_req[i].rob_id;
      ls_pipe_l1d_ld_req_prd       [i] = lsu_l1d_ld_req[i].ld_rd_idx;
      ls_pipe_l1d_ld_req_opcode    [i] = ls_pipe_l1d_ld_req_opcode_transed[i];
  `ifdef RUBY
      ls_pipe_l1d_ld_req_lsu_tag   [i] = {i[$clog2(RT_LD_ST_PAIR_NUM)-1:0], lsu_l1d_ld_req[i].lsu_id[RRV64_LSU_ID_WIDTH-1-$clog2(RT_LD_ST_PAIR_NUM):0]};
  `endif
      ls_pipe_l1d_ld_req_idx       [i] = lsu_l1d_ld_req[i].paddr[L1D_INDEX_WIDTH+L1D_OFFSET_WIDTH-1:L1D_OFFSET_WIDTH];
      ls_pipe_l1d_ld_req_offset    [i] = lsu_l1d_ld_req[i].paddr[L1D_OFFSET_WIDTH-1:0];
      ls_pipe_l1d_ld_req_vtag      [i] = lsu_l1d_ld_req[i].paddr[PADDR_WIDTH-1:L1D_INDEX_WIDTH+L1D_OFFSET_WIDTH];
      
      lsu_l1d_ld_req_ready         [i] = ls_pipe_l1d_ld_req_rdy[i];
  `ifdef RUBY
      lsu_l1d_ld_req_bank_id       [i] = ls_pipe_l1d_ld_req_hit_bank_id[i];
  `endif  
    end

    // LS_PIPE -> D$ : ST Request
    for(int i = 0; i < LSU_DATA_PIPE_COUNT; i++) begin
      ls_pipe_l1d_st_req_vld       [i] = lsu_l1d_st_req_valid[i];
      ls_pipe_l1d_st_req_io_region [i] = 1'b0;
      ls_pipe_l1d_st_req_rob_tag   [i] = lsu_l1d_st_req[i].rob_id;
      ls_pipe_l1d_st_req_prd       [i] = lsu_l1d_st_req[i].ld_rd_idx;
      ls_pipe_l1d_st_req_opcode    [i] = ls_pipe_l1d_st_req_opcode_transed[i];
  `ifdef RUBY
      ls_pipe_l1d_st_req_lsu_tag   [i] = lsu_l1d_st_req[i].lsu_id;
  `endif
      ls_pipe_l1d_st_req_paddr     [i] = lsu_l1d_st_req[i].paddr;
  `ifdef SINGLE_BANK_TEST
      ls_pipe_l1d_st_req_data      [i] = ls_pipe_l1d_st_req_data_transed[i];
  `else
      ls_pipe_l1d_st_req_data      [i] = lsu_l1d_st_req[i].st_dat;
  `endif
      ls_pipe_l1d_st_req_data_byte_mask[i] = ls_pipe_l1d_st_req_data_byte_mask_transed[i]; // data byte mask from stb

      // lsu_l1d_st_req_ready          = (counter[5:0] == 6'b000010) & ls_pipe_l1d_st_req_rdy;
      lsu_l1d_st_req_ready         [i] = ls_pipe_l1d_st_req_rdy[i];
  `ifdef RUBY
      lsu_l1d_st_req_bank_id       [i] = ls_pipe_l1d_st_req_hit_bank_id[i];
  `endif  
    end

    // D$ -> LSQ, mshr full replay
    for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
      l1d_lsu_sleep_valid  [i]  =  l1d_ls_pipe_replay_vld[i];
  `ifdef RUBY
      l1d_lsu_sleep_ldq_id [i]  = l1d_ls_pipe_replay_lsu_tag[i];
  `endif
      l1d_ls_pipe_mshr_full[i] = l1d_ls_pipe_replay_vld[i];
      l1d_lsu_sleep_mshr_full[i] = l1d_ls_pipe_mshr_full[i];
      l1d_lsu_wakeup_mshr_avail[i] = ~l1d_ls_pipe_mshr_full[i];
    end

      // D$ -> ROB : Write Back
      // D$ -> Int PRF : Write Back


  `ifdef RUBY
    lsu_l1d_ld_resp_valid = '0;
    for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
      for(int j = 0; j < LSU_ADDR_PIPE_COUNT; j++) begin
        if((l1d_lsu_lsu_tag[j][RRV64_LSU_ID_WIDTH-1-:$clog2(RT_LD_ST_PAIR_NUM)] ==  i[$clog2(LSU_ADDR_PIPE_COUNT)-1:0])
        && l1d_int_prf_wb_vld[j]) begin
          lsu_l1d_ld_resp_valid    [i] = l1d_int_prf_wb_vld[j];
          lsu_l1d_ld_resp[i].lsu_id    = {{$clog2(RT_LD_ST_PAIR_NUM){1'b0}}, l1d_lsu_lsu_tag[j][RRV64_LSU_ID_WIDTH-1-$clog2(RT_LD_ST_PAIR_NUM):0]};
          lsu_l1d_ld_resp[i].rob_id    = l1d_rob_wb_rob_tag[j];
          lsu_l1d_ld_resp[i].req_type  = LSU_LB; // TODO: not precise
          lsu_l1d_ld_resp[i].ld_data   = l1d_int_prf_wb_data[j];
          lsu_l1d_ld_resp[i].ld_rd_idx = l1d_int_prf_wb_tag[j];
          lsu_l1d_ld_resp[i].err       = 1'b0;
        end
      end
    end
  `endif

    // for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
    //   lsu_l1d_ld_resp_valid    [i] = l1d_int_prf_wb_vld[i];
    //   lsu_l1d_ld_resp[i].lsu_id    = {{$clog2(RT_LD_ST_PAIR_NUM){1'b0}}, l1d_lsu_lsu_tag[i][RRV64_LSU_ID_WIDTH-1-$clog2(RT_LD_ST_PAIR_NUM):0]};
    //   lsu_l1d_ld_resp[i].rob_id    = l1d_rob_wb_rob_tag[i];
    //   lsu_l1d_ld_resp[i].req_type  = LSU_LB; // TODO: not precise
    //   lsu_l1d_ld_resp[i].ld_data   = l1d_int_prf_wb_data[i];
    //   lsu_l1d_ld_resp[i].ld_rd_idx = l1d_int_prf_wb_tag[i];
    //   lsu_l1d_ld_resp[i].err       = 1'b0;
    // end

    // TODO: add st resp for ruby
    for(int i = 0; i < LSU_DATA_PIPE_COUNT; i++) begin
      lsu_l1d_st_resp_valid    [i] = ls_pipe_l1d_st_req_vld[i] & ls_pipe_l1d_st_req_rdy[i];
      lsu_l1d_st_resp[i].lsu_id    = lsu_l1d_st_req[i].lsu_id;
      lsu_l1d_st_resp[i].rob_id    = lsu_l1d_st_req[i].rob_id;
      lsu_l1d_st_resp[i].req_type  = lsu_l1d_st_req[i].req_type;
      lsu_l1d_st_resp[i].ld_data   = '0;
      lsu_l1d_st_resp[i].ld_rd_idx = '0;
      lsu_l1d_st_resp[i].err       = 1'b0;
    end
  end
  
  // for load, use vipt, tlb resp valid at s1 stage
  // DTLB -> D$
  always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
      dtlb_l1d_resp_vld            <= '0;
      dtlb_l1d_resp_excp_vld       <= '0;
      dtlb_l1d_resp_hit            <= '0;
      dtlb_l1d_resp_ppn            <= '0;
    end
      dtlb_l1d_resp_vld            <= ls_pipe_l1d_ld_req_vld;
      dtlb_l1d_resp_excp_vld       <= 1'b0;
      dtlb_l1d_resp_hit            <= ls_pipe_l1d_ld_req_vld;
      for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
        dtlb_l1d_resp_ppn[i]            <= lsu_l1d_ld_req[i].paddr[PPN_WIDTH-1:12];
      end
  end

`else
  always_comb begin
    // LS_PIPE -> D$ : LD Request
    ls_pipe_l1d_ld_req_vld        = 1'b0;
    ls_pipe_l1d_ld_req_rob_tag    = 'h1;
    ls_pipe_l1d_ld_req_prd        = 'h2;
    ls_pipe_l1d_ld_req_opcode     = LDU_LB;
    ls_pipe_l1d_ld_req_idx        = '0;
    ls_pipe_l1d_ld_req_offset     = counter[L1D_OFFSET_WIDTH-1:0];
    
    // LS_PIPE -> D$ : ST Request
    ls_pipe_l1d_st_req_vld        = 1'b0;
    ls_pipe_l1d_st_req_io_region  = 1'b0;
    ls_pipe_l1d_st_req_rob_tag    = 'h10;
    ls_pipe_l1d_st_req_prd        = 'h11;
    ls_pipe_l1d_st_req_opcode     = STU_SB;
    ls_pipe_l1d_st_req_paddr      = {{(PADDR_WIDTH-$bits(counter)){1'b0}}, counter};
    ls_pipe_l1d_st_req_data       = 'h1234; // data from stb
    ls_pipe_l1d_st_req_data_byte_mask = '1; // data byte mask from stb

    // DTLB -> D$
    dtlb_l1d_resp_vld             = 1'b0;
    dtlb_l1d_resp_excp_vld        = 1'b0;
    dtlb_l1d_resp_hit             = 1'b0;
    dtlb_l1d_resp_ppn             = '0;
    
      
    // LS_PIPE -> D$ : ST Request
    if(counter[6:0] == 50) begin
      ls_pipe_l1d_st_req_vld = 1'b1;
      ls_pipe_l1d_st_req_paddr = 'h123f000;
    end

    // LS_PIPE -> D$ : LD Request
    if(counter[6:0] == 100) begin
      ls_pipe_l1d_ld_req_vld = 1'b1;
      ls_pipe_l1d_ld_req_idx = '0;
      ls_pipe_l1d_ld_req_offset = '0;
    end
    
    if(counter[6:0] == 101) begin
      dtlb_l1d_resp_vld = 1'b1; 
      dtlb_l1d_resp_hit = 1'b1;
      // dtlb_l1d_resp_ppn = {{(PPN_WIDTH-(10-7)){1'b0}}, counter[10-1:7]};
      dtlb_l1d_resp_ppn = 'h123f;
    end
  end
`endif

logic                          ptw_walk_req_rdy_o;
logic                          ptw_walk_resp_vld_o;
logic [      PTW_ID_WIDTH-1:0] ptw_walk_resp_id_o;
logic [         PTE_WIDTH-1:0] ptw_walk_resp_pte_o;



rvh_l1d
rvh_l1d_u
(
    // LS Pipe -> D$ : Load request
    .ls_pipe_l1d_ld_req_vld_i                     (ls_pipe_l1d_ld_req_vld        ),
    .ls_pipe_l1d_ld_req_io_i                      (ls_pipe_l1d_ld_req_io_region  ),
    .ls_pipe_l1d_ld_req_rob_tag_i                 (ls_pipe_l1d_ld_req_rob_tag    ), 
    .ls_pipe_l1d_ld_req_prd_i                     (ls_pipe_l1d_ld_req_prd        ), 
    .ls_pipe_l1d_ld_req_opcode_i                  (ls_pipe_l1d_ld_req_opcode     ),        
`ifdef RUBY                      
    .ls_pipe_l1d_ld_req_lsu_tag_i                 (ls_pipe_l1d_ld_req_lsu_tag    ),
`endif
    // .ls_pipe_l1d_ld_req_index_i                   ({ls_pipe_l1d_ld_req_idx, ls_pipe_l1d_ld_req_offset}),                              
    .ls_pipe_l1d_ld_req_index_i                     (ls_pipe_l1d_ld_req_idx        ),
    .ls_pipe_l1d_ld_req_offset_i                  (ls_pipe_l1d_ld_req_offset     ),
    .ls_pipe_l1d_ld_req_vtag_i                    (ls_pipe_l1d_ld_req_vtag       ),                                                            
    .ls_pipe_l1d_ld_req_rdy_o                     (ls_pipe_l1d_ld_req_rdy        ), 
`ifdef RUBY
    .ls_pipe_l1d_ld_req_hit_bank_id_o             (ls_pipe_l1d_ld_req_hit_bank_id),
    .ls_pipe_l1d_st_req_hit_bank_id_o             (ls_pipe_l1d_st_req_hit_bank_id),
`endif                                                  
    // LS Pipe -> D$ : DTLB response
    .ls_pipe_l1d_dtlb_resp_vld_i                   (dtlb_l1d_resp_vld          ),                              
    .ls_pipe_l1d_dtlb_resp_ppn_i                   (dtlb_l1d_resp_ppn          ), // VIPT, get at s1 if tlb hit                   
    .ls_pipe_l1d_dtlb_resp_excp_vld_i              (dtlb_l1d_resp_excp_vld     ), // s1 kill
    .ls_pipe_l1d_dtlb_resp_hit_i                   (dtlb_l1d_resp_hit          ),      // s1 kill 
    .ls_pipe_l1d_dtlb_resp_miss_i                  (~dtlb_l1d_resp_hit          ),                              
    // LS Pipe -> D$ : Store request
    .ls_pipe_l1d_st_req_vld_i                      (ls_pipe_l1d_st_req_vld     ),  
    .ls_pipe_l1d_st_req_io_i                       (ls_pipe_l1d_st_req_io_region),                                  
    .ls_pipe_l1d_st_req_is_fence_i                 ('0),
    .ls_pipe_l1d_st_req_rob_tag_i                  (ls_pipe_l1d_st_req_rob_tag ),                                   
    .ls_pipe_l1d_st_req_prd_i                      (ls_pipe_l1d_st_req_prd     ),                                   
    .ls_pipe_l1d_st_req_opcode_i                   (ls_pipe_l1d_st_req_opcode  ), 
`ifdef RUBY                      
    .ls_pipe_l1d_st_req_lsu_tag_i                  (ls_pipe_l1d_st_req_lsu_tag    ),
`endif                                  
    // .ls_pipe_l1d_st_req_index_i                    (ls_pipe_l1d_st_req_paddr[L1D_INDEX_WIDTH-1:0]   ),                                                                 
    // .ls_pipe_l1d_st_req_tag_i                      (ls_pipe_l1d_st_req_paddr[PADDR_WIDTH-1:L1D_INDEX_WIDTH]   ),                                    
    .ls_pipe_l1d_st_req_paddr_i                    (ls_pipe_l1d_st_req_paddr   ),
    .ls_pipe_l1d_st_req_data_i                     (ls_pipe_l1d_st_req_data    ), // data from stb                                                                  
    .ls_pipe_l1d_st_req_rdy_o                      (ls_pipe_l1d_st_req_rdy     ),    
    
    // L1D -> LS Pipe : D-Cache MSHR Full, Replay load                                     
    .l1d_ls_pipe_ld_replay_valid_o                (l1d_ls_pipe_replay_vld     ),                               
`ifdef RUBY                                                                                                                                      
    .l1d_ls_pipe_replay_lsu_tag_o                  (l1d_ls_pipe_replay_lsu_tag ),                                                                                                
`endif                                             

    // LS Pipe -> L1D : Kill D-Cache Response
    .ls_pipe_l1d_kill_resp_i                       (1'b0), // TODO:
    // D$ -> ROB : Write Back
    .l1d_rob_wb_vld_o                              (l1d_rob_wb_vld             ), // TODO:
    .l1d_rob_wb_rob_tag_o                          (l1d_rob_wb_rob_tag         ), // TODO:
    // D$ -> Int PRF : Write Back                                                
    .l1d_int_prf_wb_vld_o                          (l1d_int_prf_wb_vld         ),                              
    .l1d_int_prf_wb_tag_o                          (l1d_int_prf_wb_tag         ),
    .l1d_int_prf_wb_data_o                         (l1d_int_prf_wb_data        ),
`ifdef RUBY                                        
    .l1d_lsu_lsu_tag_o                             (l1d_lsu_lsu_tag            ),                              
`endif                                             

    // PTW -> D$ : Request
    .ptw_walk_req_vld_i ('0),
    .ptw_walk_req_id_i ('0),
    .ptw_walk_req_addr_i ('0),
    .ptw_walk_req_rdy_o (ptw_walk_req_rdy_o),

    // PTW -> D$ : Response
        // ptw walk response port
    .ptw_walk_resp_vld_o (ptw_walk_resp_vld_o),
    .ptw_walk_resp_id_o (ptw_walk_resp_id_o),
    .ptw_walk_resp_pte_o (ptw_walk_resp_pte_o),
    .ptw_walk_resp_rdy_i ('0),
    // L1D -> L2 : Request
      // mshr -> mem bus
      // AR
    .l1d_l2_req_arvalid_o             (l1d_l2_arvalid),
    .l1d_l2_req_arready_i             (l1d_l2_arready),
    .l1d_l2_req_ar_o                  (l1d_l2_ar),     
      // ewrq -> mem bus                                
      // AW                                             
    .l1d_l2_req_awvalid_o             (l1d_l2_awvalid),
    .l1d_l2_req_awready_i             (l1d_l2_awready),
    .l1d_l2_req_aw_o                  (l1d_l2_aw),     
      // W                                              
    .l1d_l2_req_wvalid_o              (l1d_l2_wvalid), 
    .l1d_l2_req_wready_i              (l1d_l2_wready), 
    .l1d_l2_req_w_o                   (l1d_l2_w),      
    // L1D -> L2 : Response                             
      // B                             
    .l2_l1d_resp_bvalid_i             (l1d_l2_bvalid),
    .l2_l1d_resp_bready_o             (l1d_l2_bready), 
    .l2_l1d_resp_b_i                  (l1d_l2_b),                       
      // mem bus -> mlfb                                
      // R                             
    .l2_l1d_resp_rvalid_i             (l1d_l2_rvalid),
    .l2_l1d_resp_rready_o             (l1d_l2_rready), 
    .l2_l1d_resp_r_i                  (l1d_l2_r),      


    .rob_flush_i                          (1'b0),

    .fencei_flush_vld_i                   (1'b0),
    .fencei_flush_grant_o                 (    ),

    .clk                              (clk                ),
    .rst                              (rst_n              ) 
);


`ifdef SINGLE_BANK_TEST
  rvh_l1d_bank
  #(
    .BANK_ID (0)
  )
  L1D_CACHE_BANK
  (
    // LS_PIPE -> D$ : LD Request
    .ls_pipe_l1d_ld_req_vld_i               (ls_pipe_l1d_ld_req_vld     ),
    .ls_pipe_l1d_ld_req_rob_tag_i           (ls_pipe_l1d_ld_req_rob_tag ),
    .ls_pipe_l1d_ld_req_prd_i               (ls_pipe_l1d_ld_req_prd     ),
    .ls_pipe_l1d_ld_req_opcode_i            (ls_pipe_l1d_ld_req_opcode  ),
`ifdef RUBY
    .ls_pipe_l1d_ld_req_lsu_tag_i           (ls_pipe_l1d_ld_req_lsu_tag ),
`endif

    .ls_pipe_l1d_ld_req_idx_i               (ls_pipe_l1d_ld_req_idx     ),
    .ls_pipe_l1d_ld_req_offset_i            (ls_pipe_l1d_ld_req_offset  ),
    
    .ls_pipe_l1d_ld_req_rdy_o               (ls_pipe_l1d_ld_req_rdy     ),
    
    // LS_PIPE -> D$ : Kill LD Response
    .ls_pipe_l1d_ld_kill_i                  (1'b0                       ),
    .ls_pipe_l1d_ld_rar_fail_i              (1'b0                       ),
    
    // LS_PIPE -> D$ : ST Request
    .ls_pipe_l1d_st_req_vld_i               (ls_pipe_l1d_st_req_vld     ),
    .ls_pipe_l1d_st_req_io_region_i         (ls_pipe_l1d_st_req_io_region),
    .ls_pipe_l1d_st_req_rob_tag_i           (ls_pipe_l1d_st_req_rob_tag ),
    .ls_pipe_l1d_st_req_prd_i               (ls_pipe_l1d_st_req_prd     ),
    .ls_pipe_l1d_st_req_opcode_i            (ls_pipe_l1d_st_req_opcode  ),
`ifdef RUBY
    .ls_pipe_l1d_st_req_lsu_tag_i           (ls_pipe_l1d_st_req_lsu_tag ),
`endif
    .ls_pipe_l1d_st_req_paddr_i             (ls_pipe_l1d_st_req_paddr   ),
    .ls_pipe_l1d_st_req_data_i              (ls_pipe_l1d_st_req_data    ), // data from stb
    .ls_pipe_l1d_st_req_data_byte_mask_i    (ls_pipe_l1d_st_req_data_byte_mask  ), // data byte mask from stb
    
    .ls_pipe_l1d_st_req_rdy_o               (ls_pipe_l1d_st_req_rdy     ),
    
    // LS_PIPE -> D$ : Kill ST Response
    .ls_pipe_l1d_ld_raw_fail_i              (1'b0                       ),
    
    // DTLB -> D$
    .dtlb_l1d_resp_vld_i                    (dtlb_l1d_resp_vld          ),
    .dtlb_l1d_resp_excp_vld_i               (dtlb_l1d_resp_excp_vld     ), // s1 kill
    .dtlb_l1d_resp_hit_i                    (dtlb_l1d_resp_hit          ),      // s1 kill
    .dtlb_l1d_resp_ppn_i                    (dtlb_l1d_resp_ppn          ), // VIPT, get at s1 if tlb hit
    .dtlb_l1d_resp_rdy_o                    (dtlb_l1d_resp_rdy          ),

    // s2 kill
    .lsu_l1d_s2_kill_valid_i                (1'b0                       ),
    // input  logic [BANK_TAG_WIDTH-1:0]     lsu_l1d_s2_kill_valid_i,

    // D$ -> LSQ, mshr full replay
    .l1d_ls_pipe_replay_vld_o               (l1d_ls_pipe_replay_vld     ),
    .l1d_ls_pipe_mshr_full_o                (l1d_ls_pipe_mshr_full      ),
`ifdef RUBY
    .l1d_ls_pipe_replay_lsu_tag_o           (l1d_ls_pipe_replay_lsu_tag        ),
`endif

    // D$ -> ROB : Write Back
    .l1d_rob_wb_vld_o                       (l1d_rob_wb_vld             ),
    .l1d_rob_wb_rob_tag_o                   (l1d_rob_wb_rob_tag         ),
    
    // D$ -> Int PRF : Write Back
    .l1d_int_prf_wb_vld_o                   (l1d_int_prf_wb_vld         ),
    .l1d_int_prf_wb_tag_o                   (l1d_int_prf_wb_tag         ),
    .l1d_int_prf_wb_data_o                  (l1d_int_prf_wb_data        ),
`ifdef RUBY
    .l1d_lsu_lsu_tag_o                      (l1d_lsu_lsu_tag            ),
`endif
    
    // PTW -> D$ : Request

    // PTW -> D$ : Response

    // L1D -> L2 : Request
      // mshr -> mem bus
      // AR
    .l2_req_if_arvalid                      (l1d_l2_arvalid),
    .l2_req_if_arready                      (l1d_l2_arready),
    .l2_req_if_ar                           (l1d_l2_ar),
      // ewrq -> mem bus
      // AW
    .l2_req_if_awvalid                      (l1d_l2_awvalid),
    .l2_req_if_awready                      (l1d_l2_awready),
    .l2_req_if_aw                           (l1d_l2_aw),
      // W
    .l2_req_if_wvalid                       (l1d_l2_wvalid),
    .l2_req_if_wready                       (l1d_l2_wready),
    .l2_req_if_w                            (l1d_l2_w),
      // B
    .l2_resp_if_bvalid                      (l1d_l2_bvalid),
    .l2_resp_if_bready                      (l1d_l2_bready),
    .l2_resp_if_b                           (l1d_l2_b),
      // mem bus -> mlfb
      // R
    .l2_resp_if_rvalid                      (l1d_l2_rvalid),
    .l2_resp_if_rready                      (l1d_l2_rready),
    .l2_resp_if_r                           (l1d_l2_r),

    // L1D -> L2 : Response

    // L1D-> LSU : evict or snooped // move to lid, not in bank
    .l1d_lsu_invld_vld_o                    (l1d_lsu_invld_vld),
    .l1d_lsu_invld_tag_o                    (l1d_lsu_invld_tag), // tag+bankid


    // L1D -> IO Queue

    .flush_i                                (1'b0               ),

    .clk                                    (clk                ),
    .rst                                    (rst_n              )
);
`endif
  

axi_mem
#(
  .ID_WIDTH($bits(mem_tid_t)),
  .MEM_SIZE(1<<29), //byte 512MB
  .mem_clear(1),
  .mem_simple_seq(0),
  .READ_DELAY_CYCLE(1<<7),
  .READ_DELAY_CYCLE_RANDOMIZE(1),
  .READ_DELAY_CYCLE_RANDOMIZE_UPDATE_CYCLE(1<<10),
  .AXI_DATA_WIDTH(MEM_DATA_WIDTH) // bit
) 
axi_mem_0(
  .clk   (clk)
 ,.rst_n (rst_n)
  //AW
 ,.i_awid (l1d_l2_aw.awid)  
 ,.i_awaddr (l1d_l2_aw.awaddr)
 ,.i_awlen (l1d_l2_aw.awlen)
 ,.i_awsize (l1d_l2_aw.awsize)
 ,.i_awburst (l1d_l2_aw.awburst) // INCR mode
 ,.i_awvalid (l1d_l2_awvalid)
 ,.o_awready (l1d_l2_awready)
  //AR
 ,.i_arid (l1d_l2_ar.arid)
 ,.i_araddr (l1d_l2_ar.araddr)
 ,.i_arlen (l1d_l2_ar.arlen)
 ,.i_arsize (l1d_l2_ar.arsize)
 ,.i_arburst (l1d_l2_ar.arburst)
 ,.i_arvalid (l1d_l2_arvalid)
 ,.o_arready (l1d_l2_arready)
  //W
 ,.i_wdata (l1d_l2_w.wdata)
 ,.i_wstrb ('1)
 ,.i_wlast (l1d_l2_w.wlast)
 ,.i_wvalid (l1d_l2_wvalid)
 ,.o_wready (l1d_l2_wready)
  //B
 ,.o_bid (l1d_l2_b.bid)
 ,.o_bresp (l1d_l2_b.bresp)
 ,.o_bvalid (l1d_l2_bvalid)
 ,.i_bready (l1d_l2_bready)
  //R
 ,.o_rid    (l1d_l2_r.rid)
 ,.o_rdata  (l1d_l2_r.dat)
 ,.o_rresp  (l1d_l2_r.rresp)
 ,.o_rlast  (l1d_l2_r.rlast)
 ,.o_rvalid (l1d_l2_rvalid)
 ,.i_rready (l1d_l2_rready)

);
assign l1d_l2_r.mesi_sta  = EXCLUSIVE;
assign l1d_l2_r.err       = 1'b0;



// debug print
logic [LSU_ADDR_PIPE_COUNT-1:0] ls_pipe_l1d_ld_req_hsk;
logic [LSU_DATA_PIPE_COUNT-1:0] ls_pipe_l1d_st_req_hsk;
logic [LSU_ADDR_PIPE_COUNT-1:0] ls_pipe_l1d_ld_resp_hsk;
logic l1d_mem_aw_req_hsk;
logic l1d_mem_w_req_hsk;
logic l1d_mem_ar_req_hsk;
logic l1d_mem_r_resp_hsk;

generate
  for(i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
    assign ls_pipe_l1d_ld_req_hsk [i] = ls_pipe_l1d_ld_req_vld[i] & lsu_l1d_ld_req_ready[i];
    assign ls_pipe_l1d_ld_resp_hsk[i] = lsu_l1d_ld_resp_valid[i];
  end
  for(i = 0; i < LSU_DATA_PIPE_COUNT; i++) begin
    assign ls_pipe_l1d_st_req_hsk[i] = ls_pipe_l1d_st_req_vld[i] & lsu_l1d_st_req_ready[i];
  end
endgenerate

`ifndef SYNTHESIS
assert property(@(posedge clk)disable iff(~rst_n)(l1d_rob_wb_vld[LSU_ADDR_PIPE_COUNT+:LSU_DATA_PIPE_COUNT] == ls_pipe_l1d_st_req_hsk)) 
        else $fatal("l1d st req hsk not right");
`endif

assign l1d_mem_aw_req_hsk = l1d_l2_awvalid & l1d_l2_awready;
assign l1d_mem_w_req_hsk  = l1d_l2_wvalid & l1d_l2_wready;
assign l1d_mem_ar_req_hsk = l1d_l2_arvalid & l1d_l2_arready;
assign l1d_mem_r_resp_hsk = l1d_l2_rvalid & l1d_l2_rready;

`ifdef RT_MODE_CLASSIC
logic [RT_CHECK_NUM-1:0]                                       rt_err_resp_data_mismatch_ent_q;
logic [RT_CHECK_NUM-1:0][RT_CHECK_DATA_W-1:0]                  check_data_q_q;
logic [RT_CHECK_NUM-1:0][RT_CHECK_DATA_W-1:0]                  check_port_update_resp_data_q;

always_ff @(posedge clk or negedge rst_n) begin
  if(~rst_n) begin
    rt_err_resp_data_mismatch_ent_q <= '0;
    check_data_q_q                  <= '0;
    check_port_update_resp_data_q   <= '0;
  end else if(top.rubytest_top_u.rubytest_check_table_u.rt_err_resp_data_mismatch_d) begin
    rt_err_resp_data_mismatch_ent_q <= top.rubytest_top_u.rubytest_check_table_u.rt_err_resp_data_mismatch_ent;
    check_data_q_q                  <= top.rubytest_top_u.rubytest_check_table_u.check_data_q;
    check_port_update_resp_data_q   <= top.rubytest_top_u.rubytest_check_table_u.check_port_update_resp_data;
  end
end
`endif

always_ff @(posedge clk) begin
  if(debug_print) begin
    for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
      if(ls_pipe_l1d_ld_req_hsk[i]) begin
        $display("\n\n====================");
        $display("@ cycle = %d, load req[port %d, l1d bank %d] handshake", cycle, i[$clog2(LSU_ADDR_PIPE_COUNT)-1:0], lsu_l1d_ld_req_bank_id[i]);
        $display("lsu_id    = 0x%x", lsu_l1d_ld_req[i].lsu_id);
        $display("rob_id    = 0x%x", lsu_l1d_ld_req[i].rob_id);
        $display("req_type  = 0x%x", lsu_l1d_ld_req[i].req_type);
        $display("paddr     = 0x%x", lsu_l1d_ld_req[i].paddr);
        $display("ld_rd_idx = 0x%x", lsu_l1d_ld_req[i].ld_rd_idx);
        $display("====================");
      end
    end

    for(int i = 0; i < LSU_DATA_PIPE_COUNT; i++) begin
      if(ls_pipe_l1d_st_req_hsk[i]) begin
        $display("\n\n====================");
        $display("@ cycle = %d, store req[port %d, l1d bank %d] handshake", cycle, i[$clog2(LSU_DATA_PIPE_COUNT)-1:0], lsu_l1d_st_req_bank_id[i]);
        $display("lsu_id    = 0x%x", lsu_l1d_st_req[i].lsu_id);
        $display("rob_id    = 0x%x", lsu_l1d_st_req[i].rob_id);
        $display("req_type  = 0x%x", lsu_l1d_st_req[i].req_type);
        $display("paddr     = 0x%x", lsu_l1d_st_req[i].paddr);
        $display("ld_rd_idx = 0x%x", lsu_l1d_st_req[i].ld_rd_idx);
        $write("st_dat    = 0x");
        for(int j = XLEN/64-1; j >=0; j--) begin
          $write("%h", lsu_l1d_st_req[i].st_dat[j*64+:64]);
        end
        $display("\n====================");
      end
    end

    for(int i = 0; i < LSU_ADDR_PIPE_COUNT; i++) begin
      if(ls_pipe_l1d_ld_resp_hsk[i]) begin
        $display("\n\n====================");
        $display("@ cycle = %d, load resp[port %d] handshake", cycle, i[$clog2(LSU_ADDR_PIPE_COUNT)-1:0]);
        $display("lsu_id    = 0x%x", lsu_l1d_ld_resp[i].lsu_id);
        $display("rob_id    = 0x%x", lsu_l1d_ld_resp[i].rob_id);
        $display("req_type  = 0x%x", lsu_l1d_ld_resp[i].req_type);
        $display("ld_rd_idx = 0x%x", lsu_l1d_ld_resp[i].ld_rd_idx);
        $write("ld_data   = 0x");
        for(int j = XLEN/64-1; j >=0; j--) begin
          $write("%h", lsu_l1d_ld_resp[i].ld_data[j*64+:64]);
        end
        $display("\n====================");
      end
    end

    if(l1d_mem_aw_req_hsk) begin
      $display("\n\n====================");
      $display("@ cycle = %d, write back aw req handshake", cycle);
      $display("awaddr    = 0x%x", l1d_l2_aw.awaddr);
      $display("awlen     = 0x%x", l1d_l2_aw.awlen);
      $display("awsize    = 0x%x", l1d_l2_aw.awsize);
      $display("awid      = 0x%x", l1d_l2_aw.awid);
      $display("awburst   = 0x%x", l1d_l2_aw.awburst);
      $display("====================");
    end
    if(l1d_mem_w_req_hsk) begin
      $display("\n\n====================");
      $display("@ cycle = %d, write back w req handshake", cycle);
      $display("wlast     = 0x%x", l1d_l2_w.wlast);
      $display("wid       = 0x%x", l1d_l2_w.wid);
      $write("wdata     = 0x");
      for(int i = MEM_DATA_WIDTH/64-1; i >=0; i--) begin
        $write("%h", l1d_l2_w.wdata[i*64+:64]);
      end
      $display("\n====================");
    end
    if(l1d_mem_ar_req_hsk) begin
      $display("\n\n====================");
      $display("@ cycle = %d, l1d miss ar req handshake", cycle);
      $display("araddr    = 0x%x", l1d_l2_ar.araddr);
      $display("arlen     = 0x%x", l1d_l2_ar.arlen);
      $display("arsize    = 0x%x", l1d_l2_ar.arsize);
      $display("arid      = 0x%x", l1d_l2_ar.arid);
      $display("arburst   = 0x%x", l1d_l2_ar.arburst);
      $display("====================");
    end
    if(l1d_mem_r_resp_hsk) begin
      $display("\n\n====================");
      $display("@ cycle = %d, l1d miss r resp handshake", cycle);
      $display("mesi_sta  = 0x%x", l1d_l2_r.mesi_sta);
      $display("rresp     = 0x%x", l1d_l2_r.rresp);
      $display("rlast     = 0x%x", l1d_l2_r.rlast);
      $display("rid       = 0x%x", l1d_l2_r.rid);
      $write("rdata     = 0x");
      for(int i = MEM_DATA_WIDTH/64-1; i >=0; i--) begin
        $write("%h", l1d_l2_r.dat[i*64+:64]);
      end
      $display("\n====================");
    end
  end

`ifdef RT_MODE_CLASSIC
  if(top.rubytest_top_u.rt_debug_info.err_resp_data_mismatch) begin
    $display("CHECK NUM: %d, cycle:%d ....", top.rubytest_top_u.rt_debug_info.stats_trans_ok_cnt[63:0], cycle);
    $display("---------- ERROR: err resp data mismatch-------");
    for(int i = 0; i < RT_CHECK_NUM; i++) begin
      if(rt_err_resp_data_mismatch_ent_q[i]) begin
        $display("right data = 0x%x", check_data_q_q[i][0+:RT_CHECK_DATA_CLASSIC_W]);
        $display("wrong data = 0x%x", check_port_update_resp_data_q[i][0+:RT_CHECK_DATA_CLASSIC_W]);
      end
    end
    $finish();
  end
`endif
  else if(top.rubytest_top_u.rt_debug_info.err_resp_timeout) begin
    $display("CHECK NUM: %d, cycle:%d ....", top.rubytest_top_u.rt_debug_info.stats_trans_ok_cnt[63:0], cycle);
    $display("---------- ERROR: err resp timeout");
    $finish();
  end
  else if(top.rubytest_top_u.rt_debug_info.err_put_by_invalid_trans_id) begin
    $display("CHECK NUM: %d, cycle:%d ....", top.rubytest_top_u.rt_debug_info.stats_trans_ok_cnt[63:0], cycle);
    $display("---------- ERROR: err put by invalid trans id----------");
    $finish();
  end
  else if(top.rubytest_top_u.rt_debug_info.err_poll_by_invalid_trans_id) begin
    $display("CHECK NUM: %d, cycle:%d ....", top.rubytest_top_u.rt_debug_info.stats_trans_ok_cnt[63:0], cycle);
    $display("---------- ERROR: err poll by invalid trans id---------");
    $finish();
  end
  else if(top.rubytest_top_u.rt_debug_info.err_resp_in_invalid_state) begin
    $display("CHECK NUM: %d, cycle:%d ....", top.rubytest_top_u.rt_debug_info.stats_trans_ok_cnt[63:0], cycle);
    $display("---------- ERROR: err resp in invalid state-----");
    $finish();
  end
  else if(top.rubytest_top_u.rt_debug_info.err_ready_in_invalid_state) begin
    $display("CHECK NUM: %d, cycle:%d ....", top.rubytest_top_u.rt_debug_info.stats_trans_ok_cnt[63:0], cycle);
    $display("---------- ERROR: err ready in invalid state-----");
    $finish();
  end
end

function banner(int is_start);
  $display("\n-----------------");
  if (is_start)
      $display("------START RUBYTEST RTL TOP SIM-----------");
  else
      $display("------EXIT RUBYTEST RTL TOP SIM--------");
  $display("--------------------\n");
  if (0 == is_start)
      $finish();
endfunction : banner

initial begin
  banner(1);
end

initial begin
  if ($value$plusargs("timeout_count=%d", timeout_count)) begin
    $display("TOP: timeout_count_in=%d", timeout_count);
  end

  if ($value$plusargs("debug_print=%d", debug_print)) begin
    $display("TOP: debug_print_in=%d", debug_print);
  end
  
  repeat(timeout_count) @(posedge clk);
  $display("TIMEOUT SIM %d times ....", timeout_count);
  $display("CHECK NUM: %d ....", top.rubytest_top_u.rt_debug_info.stats_trans_ok_cnt[63:0]);
  if(top.rubytest_top_u.rt_debug_info.err_resp_data_mismatch) begin
    $display("---------- ERROR: err resp data mismatch-------");
  end
  else if(top.rubytest_top_u.rt_debug_info.err_resp_timeout) begin
    $display("---------- ERROR: err resp timeout");
  end
  else if(top.rubytest_top_u.rt_debug_info.err_put_by_invalid_trans_id) begin
    $display("---------- ERROR: err put by invalid trans id----------");
  end
  else if(top.rubytest_top_u.rt_debug_info.err_poll_by_invalid_trans_id) begin
    $display("---------- ERROR: err poll by invalid trans id---------");
  end
  else if(top.rubytest_top_u.rt_debug_info.err_resp_in_invalid_state) begin
    $display("---------- ERROR: err resp in invalid state-----");
  end
  else if(top.rubytest_top_u.rt_debug_info.err_ready_in_invalid_state) begin
    $display("---------- ERROR: err ready in invalid state-----");
  end
  else begin
    $display("RubyTest Result [SUCCESS]");
  end
  banner(0);
end

initial begin

  if ($value$plusargs("rseed0=%d", rseed0)) begin
      $display("TOP: user set rseed0=%d",rseed0);
  end else begin
      $display("TOP: default rseed0=%d",rseed0);
  end
  if ($value$plusargs("rseed1=%d", rseed1)) begin
      $display("TOP: rseed1=%d", rseed1);
  end else begin
    $display("TOP: default rseed1=%d",rseed1);
end
end


endmodule
