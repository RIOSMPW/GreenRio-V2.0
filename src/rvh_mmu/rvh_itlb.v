`ifndef VCS
`include "../params.vh"
`endif // VCS

module rvh_itlb #(
    parameter TRANSLATE_WIDTH   = ITLB_TRANSLATE_WIDTH,
    parameter ENTRY_COUNT       = ITLB_ENTRY_COUNT,
    parameter MSHR_COUNT        = ITLB_MSHR_COUNT,
    parameter TRANS_ID_WIDTH    = ITLB_TRANS_ID_WIDTH
) (
    input [1:0] priv_lvl_i,
    // mstatus
    input mstatus_mxr,
    input mstatus_sum,
    // Satp
    input [MODE_WIDTH-1:0] satp_mode_i,
    input [ASID_WIDTH-1:0] satp_asid_i,
    // Translate Port -> Request
    input [TRANSLATE_WIDTH-1:0] translate_req_vld_i,
    input [TRANSLATE_WIDTH-1:0][VPN_WIDTH-1:0] translate_req_vpn_i,
    output [TRANSLATE_WIDTH-1:0] translate_req_rdy_o,
    // Translate Port -> Response
    output [TRANSLATE_WIDTH-1:0] translate_resp_vld_o,
    output [TRANSLATE_WIDTH-1:0][PPN_WIDTH-1:0] translate_resp_ppn_o,
    output [TRANSLATE_WIDTH-1:0] translate_resp_excp_vld_o,
    output [TRANSLATE_WIDTH-1:0][EXCP_CAUSE_WIDTH-1:0] translate_resp_excp_cause_o,
    output [TRANSLATE_WIDTH-1:0] translate_resp_miss_o,
    output [TRANSLATE_WIDTH-1:0] translate_resp_hit_o,
    // TLB Miss -> To Next Level Request
    output next_lvl_req_vld_o,
    output [TRANS_ID_WIDTH-1:0] next_lvl_req_trans_id_o,
    output [ASID_WIDTH-1:0] next_lvl_req_asid_o,
    output [VPN_WIDTH-1:0] next_lvl_req_vpn_o,
    output [1:0] next_lvl_req_access_type_o,
    input next_lvl_req_rdy_i,
    // TLB Miss -> From Next Level Response
    input next_lvl_resp_vld_i,
    input [TRANS_ID_WIDTH-1:0] next_lvl_resp_trans_id_i,
    input [ASID_WIDTH-1:0] next_lvl_resp_asid_i,
    input [PTE_WIDTH-1:0] next_lvl_resp_pte_i,
    input [PAGE_LVL_WIDTH-1:0] next_lvl_resp_page_lvl_i,
    input [VPN_WIDTH-1:0] next_lvl_resp_vpn_i,
    input [1:0] next_lvl_resp_access_type_i,
    input next_lvl_resp_access_fault_i,
    input next_lvl_resp_page_fault_i,
    // // TLB Entry Evict
    // output tlb_evict_vld_o,
    // output [PTE_WIDTH-1:0] tlb_evict_pte_o,
    // output [PAGE_LVL_WIDTH-1:0] tlb_evict_page_lvl_o,
    // output [VPN_WIDTH-1:0] tlb_evict_vpn_o,
    // output [ASID_WIDTH-1:0] tlb_evict_asid_o,
    // TLB Flush
    input tlb_flush_vld_i,
    input tlb_flush_use_asid_i,
    input tlb_flush_use_vpn_i,
    input [VPN_WIDTH-1:0] tlb_flush_vpn_i,
    input [ASID_WIDTH-1:0] tlb_flush_asid_i,
    output reg tlb_flush_grant_o,

    input clk,
    input rstn
);

  genvar lane;
  genvar macro;

  localparam HIGHEST_PAGE_LVL = VPN_WIDTH / 9;
  // Mode
  localparam MODE_BARE = 0;
  localparam MODE_SV39 = 8;
  localparam MODE_SV48 = 9;
  localparam MODE_SV57 = 10;
  localparam SV39_LEVELS = 3;
  localparam SV48_LEVELS = 4;
  localparam SV57_LEVELS = 5;
  localparam SV39_LEVELS_DIFF = HIGHEST_PAGE_LVL - SV39_LEVELS;
  localparam SV48_LEVELS_DIFF = HIGHEST_PAGE_LVL >= SV48_LEVELS ? HIGHEST_PAGE_LVL - SV48_LEVELS : 0;
  localparam SV57_LEVELS_DIFF = HIGHEST_PAGE_LVL >= SV57_LEVELS ? HIGHEST_PAGE_LVL - SV48_LEVELS : 0;
  // Priviledge Level
  localparam PRIV_LVL_M = 3;
  localparam PRIV_LVL_S = 1;
  localparam PRIV_LVL_U = 0;
  // Exception Cause 
  localparam INSTR_ACCESS_FAULT = 1;  // Illegal access as governed by PMPs and PMAs
  localparam INSTR_PAGE_FAULT = 12;  // Instruction page fault
  // Access type
  localparam PMP_ACCESS_TYPE_R = 0;
  localparam PMP_ACCESS_TYPE_W = 1;
  localparam PMP_ACCESS_TYPE_X = 2;

  function automatic [VPN_WIDTH-1:0] gen_page_vpn_mask;
    input [MODE_WIDTH-1:0] satp_mode_i;
    input [PAGE_LVL_WIDTH-1:0] page_lvl_i;
    integer i;
    reg [HIGHEST_PAGE_LVL-1:0] satp_mode_mask;
    reg [HIGHEST_PAGE_LVL-1:0] vpn_segment_en_mask;
    begin
      case (satp_mode_i)
        MODE_SV39: satp_mode_mask = {{SV39_LEVELS_DIFF{1'b0}}, {SV39_LEVELS{1'b1}}};
        MODE_SV48: satp_mode_mask = {{SV48_LEVELS_DIFF{1'b0}}, {SV48_LEVELS{1'b1}}};
        MODE_SV57: satp_mode_mask = {{SV57_LEVELS_DIFF{1'b0}}, {SV57_LEVELS{1'b1}}};
        default:   satp_mode_mask = {HIGHEST_PAGE_LVL{1'b0}};
      endcase
      vpn_segment_en_mask = (~(({{HIGHEST_PAGE_LVL-1{1'b0}},1'b1} << page_lvl_i) - 1'b1)) & satp_mode_mask;
      for (i = 0; i < HIGHEST_PAGE_LVL; i++) begin
        gen_page_vpn_mask[i*9+:9] = {9{vpn_segment_en_mask[i]}};
      end
    end
  endfunction

  function automatic [PPN_WIDTH-1:0] gen_page_alignment_mask;
    input [PAGE_LVL_WIDTH-1:0] page_lvl_i;
    reg [HIGHEST_PAGE_LVL-1:0] ppn_segment_en_mask;
    reg [PPN_WIDTH-1:0] mask;
    integer i;
    begin
      mask = {PPN_WIDTH{1'b0}};
      ppn_segment_en_mask = (({{HIGHEST_PAGE_LVL-1{1'b0}},1'b1} << page_lvl_i) - 1'b1);
      for (i = 0; i < HIGHEST_PAGE_LVL; i++) begin
        mask[i*9+:9] = {9{ppn_segment_en_mask[i]}};
      end
      gen_page_alignment_mask = mask;
    end
  endfunction


  wire skip_translation;
  wire exist_inflight_req;

  // Translate Request Setup
  wire [TRANSLATE_WIDTH-1:0] translate_req_fire;
  wire [TRANSLATE_WIDTH-1:0] translate_req_payload_clk_en;
  wire [TRANSLATE_WIDTH-1:0] translate_req_vld_d;
  wire [TRANSLATE_WIDTH-1:0][VPN_WIDTH-1:0] translate_req_vpn_d;
  wire [TRANSLATE_WIDTH-1:0][ASID_WIDTH-1:0] translate_req_asid_d;
  reg [TRANSLATE_WIDTH-1:0] translate_req_vld_q;
  reg [TRANSLATE_WIDTH-1:0][VPN_WIDTH-1:0] translate_req_vpn_q;
  reg [TRANSLATE_WIDTH-1:0][ASID_WIDTH-1:0] translate_req_asid_q;

  // ITLB Exception Entry Management
  wire refill_exception_entry;
  wire itlb_excp_entry_vld_set;
  wire itlb_excp_entry_vld_clean;
  wire itlb_excp_entry_vld_clk_en;
  wire itlb_excp_entry_payload_clk_en;
  // ITLB Exception Entry
  wire [VPN_WIDTH-1:0] itlb_excp_entry_vpn_d;
  wire [ASID_WIDTH-1:0] itlb_excp_entry_asid_d;
  wire [PAGE_LVL_WIDTH-1:0] itlb_excp_entry_page_lvl_d;
  wire itlb_excp_entry_access_fault_d;
  wire itlb_excp_entry_page_fault_d;
  wire itlb_excp_entry_V_d;
  reg [VPN_WIDTH-1:0] itlb_excp_entry_vpn_q;
  reg [ASID_WIDTH-1:0] itlb_excp_entry_asid_q;
  reg [PAGE_LVL_WIDTH-1:0] itlb_excp_entry_page_lvl_q;
  reg itlb_excp_entry_access_fault_q;
  reg itlb_excp_entry_page_fault_q;
  reg itlb_excp_entry_V_q;

  // ITLB Entry Management
  wire refill_entry;
  wire exist_invld_entry;
  wire [ENTRY_COUNT-1:0] refill_invld_oh_mask;
  wire [ENTRY_COUNT-1:0] refill_evict_oh_mask;
  wire [ENTRY_COUNT-1:0] itlb_entry_vld_clk_en;
  wire [ENTRY_COUNT-1:0] itlb_entry_vld_set;
  wire [ENTRY_COUNT-1:0] itlb_entry_vld_clean;
  wire [ENTRY_COUNT-1:0] itlb_entry_payload_clk_en;
  // ITLB Entry
  wire [ENTRY_COUNT-1:0][ASID_WIDTH-1:0] itlb_entry_asid_d;
  wire [ENTRY_COUNT-1:0][VPN_WIDTH-1:0] itlb_entry_vpn_d;
  wire [ENTRY_COUNT-1:0][PAGE_LVL_WIDTH-1:0] itlb_entry_page_lvl_d;
  reg [ENTRY_COUNT-1:0][ASID_WIDTH-1:0] itlb_entry_asid_q;
  reg [ENTRY_COUNT-1:0][VPN_WIDTH-1:0] itlb_entry_vpn_q;
  reg [ENTRY_COUNT-1:0][PAGE_LVL_WIDTH-1:0] itlb_entry_page_lvl_q;
  // PTE
  wire [ENTRY_COUNT-1:0][PPN_WIDTH-1:0] itlb_entry_PPN_d;
  wire [ENTRY_COUNT-1:0] itlb_entry_D_d;
  wire [ENTRY_COUNT-1:0] itlb_entry_A_d;
  wire [ENTRY_COUNT-1:0] itlb_entry_G_d;
  wire [ENTRY_COUNT-1:0] itlb_entry_U_d;
  wire [ENTRY_COUNT-1:0] itlb_entry_X_d;
  wire [ENTRY_COUNT-1:0] itlb_entry_W_d;
  wire [ENTRY_COUNT-1:0] itlb_entry_R_d;
  wire [ENTRY_COUNT-1:0] itlb_entry_V_d;
  reg [ENTRY_COUNT-1:0][PPN_WIDTH-1:0] itlb_entry_PPN_q;
  reg [ENTRY_COUNT-1:0] itlb_entry_D_q;
  reg [ENTRY_COUNT-1:0] itlb_entry_A_q;
  reg [ENTRY_COUNT-1:0] itlb_entry_G_q;
  reg [ENTRY_COUNT-1:0] itlb_entry_U_q;
  reg [ENTRY_COUNT-1:0] itlb_entry_X_q;
  reg [ENTRY_COUNT-1:0] itlb_entry_W_q;
  reg [ENTRY_COUNT-1:0] itlb_entry_R_q;
  reg [ENTRY_COUNT-1:0] itlb_entry_V_q;

  // ITLB Search
  wire [VPN_WIDTH-1:0] itlb_excp_entry_vpn_mask;
  wire [TRANSLATE_WIDTH-1:0][VPN_WIDTH-1:0] itlb_excp_entry_vpn_equal_bit;
  wire [TRANSLATE_WIDTH-1:0] itlb_excp_entry_hit;

  wire [ENTRY_COUNT-1:0][VPN_WIDTH-1:0] itlb_entry_vpn_mask;
  wire [TRANSLATE_WIDTH-1:0][ENTRY_COUNT-1:0][VPN_WIDTH-1:0] itlb_entry_vpn_equal_bit;
  wire [TRANSLATE_WIDTH-1:0][ENTRY_COUNT-1:0] itlb_entry_hit;
  wire [TRANSLATE_WIDTH-1:0] itlb_hit;
  wire [ENTRY_COUNT-1:0][PPN_WIDTH+PAGE_LVL_WIDTH+7-1:0] itlb_hit_entry_mux_in;
  wire [TRANSLATE_WIDTH-1:0][PAGE_LVL_WIDTH-1:0] itlb_hit_entry_mux_out_page_lvl;
  wire [TRANSLATE_WIDTH-1:0][PPN_WIDTH-1:0] itlb_hit_entry_mux_out_PPN;
  wire [TRANSLATE_WIDTH-1:0] itlb_hit_entry_mux_out_D;
  wire [TRANSLATE_WIDTH-1:0] itlb_hit_entry_mux_out_A;
  wire [TRANSLATE_WIDTH-1:0] itlb_hit_entry_mux_out_G;
  wire [TRANSLATE_WIDTH-1:0] itlb_hit_entry_mux_out_U;
  wire [TRANSLATE_WIDTH-1:0] itlb_hit_entry_mux_out_X;
  wire [TRANSLATE_WIDTH-1:0] itlb_hit_entry_mux_out_W;
  wire [TRANSLATE_WIDTH-1:0] itlb_hit_entry_mux_out_R;

  // Update PLRU
  wire [ENTRY_COUNT-1:0][TRANSLATE_WIDTH-1:0] itlb_lane_hit_mask_trans;
  wire [ENTRY_COUNT-1:0] itlb_plru_access_mask;

  // PTE Check
  wire [TRANSLATE_WIDTH-1:0][PPN_WIDTH-1:0] pte_superpage_alignment_mask;
  wire [TRANSLATE_WIDTH-1:0] pte_superpage_alignment_check_fail;
  wire [TRANSLATE_WIDTH-1:0] pte_access_permission_check_fail;
  wire [TRANSLATE_WIDTH-1:0] pte_superpage_alignment_check_pass;
  wire [TRANSLATE_WIDTH-1:0] pte_access_permission_check_pass;
  wire [TRANSLATE_WIDTH-1:0] pte_check_pass;
  wire [TRANSLATE_WIDTH-1:0] pte_check_fail;

  // Miss Handler
  wire [TRANSLATE_WIDTH-1:0] tlb_miss_req_vld;
  wire [TRANSLATE_WIDTH-1:0][ASID_WIDTH-1:0] tlb_miss_req_asid;
  wire [TRANSLATE_WIDTH-1:0][1:0] tlb_miss_req_access_type;
  wire [TRANSLATE_WIDTH-1:0][VPN_WIDTH-1:0] tlb_miss_req_vpn;

  // tlb refill response sync
  wire next_lvl_resp_payload_clk_en;
  wire next_lvl_resp_vld_d;
  wire [TRANS_ID_WIDTH-1:0] next_lvl_resp_trans_id_d;
  wire [ASID_WIDTH-1:0] next_lvl_resp_asid_d;
  wire [PTE_WIDTH-1:0] next_lvl_resp_pte_d;
  wire [PAGE_LVL_WIDTH-1:0] next_lvl_resp_page_lvl_d;
  wire [VPN_WIDTH-1:0] next_lvl_resp_vpn_d;
  wire next_lvl_resp_excp_vld_d;
  wire tlb_refill_entry_is_evicted_d;
  wire [ENTRY_COUNT-1:0] tlb_refill_entry_mask_d;
  reg next_lvl_resp_vld_q;
  reg [TRANS_ID_WIDTH-1:0] next_lvl_resp_trans_id_q;
  reg [ASID_WIDTH-1:0] next_lvl_resp_asid_q;
  reg [PTE_WIDTH-1:0] next_lvl_resp_pte_q;
  reg [PAGE_LVL_WIDTH-1:0] next_lvl_resp_page_lvl_q;
  reg [VPN_WIDTH-1:0] next_lvl_resp_vpn_q;
  reg next_lvl_resp_excp_vld_q;
  reg tlb_refill_entry_is_evicted_q;
  reg [ENTRY_COUNT-1:0] tlb_refill_entry_mask_q;

  // Evict Entry
  wire [ENTRY_COUNT-1:0][ASID_WIDTH+VPN_WIDTH+PAGE_LVL_WIDTH+PPN_WIDTH+8-1:0] evict_itlb_entry_mux_in;
  wire [ASID_WIDTH-1:0] evict_itlb_entry_asid;
  wire [VPN_WIDTH-1:0] evict_itlb_entry_vpn;
  wire [PAGE_LVL_WIDTH-1:0] evict_itlb_entry_page_lvl;
  wire [PPN_WIDTH-1:0] evict_itlb_entry_PPN;
  wire evict_itlb_entry_D;
  wire evict_itlb_entry_A;
  wire evict_itlb_entry_G;
  wire evict_itlb_entry_U;
  wire evict_itlb_entry_X;
  wire evict_itlb_entry_W;
  wire evict_itlb_entry_R;

  // MMU Status
  assign skip_translation = (priv_lvl_i == PRIV_LVL_M) | (satp_mode_i == MODE_BARE);
  generate
    assign itlb_excp_entry_vpn_mask = gen_page_vpn_mask(satp_mode_i, itlb_excp_entry_page_lvl_q);
    for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_itlb_entry_vpn_mask
      assign itlb_entry_vpn_mask[macro] = gen_page_vpn_mask(
          satp_mode_i, itlb_entry_page_lvl_q[macro]
      );
    end
    for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_itlb_hit_entry_mux_in
      assign itlb_hit_entry_mux_in[macro] = {
        itlb_entry_page_lvl_q[macro],
        itlb_entry_PPN_q[macro],
        itlb_entry_D_q[macro],
        itlb_entry_A_q[macro],
        itlb_entry_G_q[macro],
        itlb_entry_U_q[macro],
        itlb_entry_X_q[macro],
        itlb_entry_W_q[macro],
        itlb_entry_R_q[macro]
      };
    end
    for (lane = 0; lane < TRANSLATE_WIDTH; lane = lane + 1) begin : gen_lane
      // Translate Input Register
      assign translate_req_rdy_o[lane] = ~exist_inflight_req;
      assign translate_req_fire[lane] = translate_req_rdy_o[lane] & translate_req_vld_i[lane];
      assign translate_req_payload_clk_en[lane] = translate_req_fire[lane];
      assign translate_req_vld_d[lane] = translate_req_fire[lane];
      assign translate_req_vpn_d[lane] = translate_req_vpn_i[lane];
      assign translate_req_asid_d[lane] = satp_asid_i;

      // Exception Entry Match Logic
      assign itlb_excp_entry_vpn_equal_bit[lane] = ~(translate_req_vpn_q[lane] ^ itlb_excp_entry_vpn_q);
      assign itlb_excp_entry_hit[lane] = translate_req_vld_q[lane] &  // Request Valid
          itlb_excp_entry_V_q &  // Entry Valid
          (translate_req_asid_q[lane] == itlb_excp_entry_asid_q) &  // Same ASID
          (&(itlb_excp_entry_vpn_equal_bit[lane] | (~itlb_excp_entry_vpn_mask)));  // VPN Equal

      // Common Entry Match Logic
      for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_itlb_entry_hit_logic
        assign itlb_entry_vpn_equal_bit[lane][macro] = ~(translate_req_vpn_q[lane] ^ itlb_entry_vpn_q[macro]);
        assign itlb_entry_hit[lane][macro] = translate_req_vld_q[lane] &  // Request Valid
            itlb_entry_V_q[macro] &  // Entry Valid
            ((translate_req_asid_q[lane] == itlb_entry_asid_q[macro]) | itlb_entry_G_q[macro]) &  // Same ASID or Global Page
            (&(itlb_entry_vpn_equal_bit[lane][macro] | (~itlb_entry_vpn_mask[macro])));  // VPN Equal
      end
      assign itlb_hit[lane] = |itlb_entry_hit[lane];

      // Update PLRU
      for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_plru_access_mask
        assign itlb_lane_hit_mask_trans[macro][lane] = itlb_entry_hit[lane][macro];
        assign itlb_plru_access_mask[macro] = |itlb_lane_hit_mask_trans[macro];
      end

      // Permission Check
      assign pte_superpage_alignment_mask[lane] = gen_page_alignment_mask(
          itlb_hit_entry_mux_out_page_lvl[lane]
      );
      assign pte_superpage_alignment_check_pass[lane] =
        (itlb_hit_entry_mux_out_PPN[lane] & pte_superpage_alignment_mask[lane]) == 0;
      assign pte_superpage_alignment_check_fail[lane] = ~pte_superpage_alignment_check_pass[lane];
      assign pte_access_permission_check_fail[lane] =
          ~itlb_hit_entry_mux_out_A[lane] | // Page have not been accessed
          ~itlb_hit_entry_mux_out_X[lane] |  // Without Execution Permission
          (itlb_hit_entry_mux_out_U[lane] &
          (~(priv_lvl_i == PRIV_LVL_U)) & (~((priv_lvl_i == PRIV_LVL_S) & mstatus_sum))); // Without User Page Access Permission
      assign pte_access_permission_check_pass[lane] = ~pte_access_permission_check_fail[lane];

      assign pte_check_pass[lane] = pte_superpage_alignment_check_pass[lane] & pte_access_permission_check_pass[lane];
      assign pte_check_fail[lane] = pte_superpage_alignment_check_fail[lane] | pte_access_permission_check_fail[lane];

      // Translate Response
      assign translate_resp_vld_o[lane] = translate_req_vld_q[lane];

      assign translate_resp_ppn_o[lane] = skip_translation ? 
        {{PPN_WIDTH-VPN_WIDTH{1'b0}},translate_req_vpn_q[lane]} : 
        (itlb_hit[lane] ? 
          ( (itlb_hit_entry_mux_out_PPN[lane] & (~pte_superpage_alignment_mask[lane])) | 
            ({{PPN_WIDTH-VPN_WIDTH{1'b0}},translate_req_vpn_q[lane]} & {pte_superpage_alignment_mask[lane]})  ) :
          {PPN_WIDTH{1'b0}});
      assign translate_resp_excp_vld_o[lane] = ~skip_translation & (itlb_excp_entry_hit[lane] | (itlb_hit[lane] & pte_check_fail[lane]));
      assign translate_resp_excp_cause_o[lane] = {EXCP_CAUSE_WIDTH{~skip_translation}} & ({EXCP_CAUSE_WIDTH{(
          itlb_excp_entry_hit[lane] & itlb_excp_entry_access_fault_q
      )}} & EXCP_CAUSE_WIDTH'(INSTR_ACCESS_FAULT)) | ({EXCP_CAUSE_WIDTH{(
          (itlb_excp_entry_hit[lane] & itlb_excp_entry_page_fault_q) | (itlb_hit[lane] & pte_check_fail[lane])
      )}} & EXCP_CAUSE_WIDTH'(INSTR_PAGE_FAULT));
      assign translate_resp_miss_o[lane] = ~translate_resp_hit_o[lane];
      assign translate_resp_hit_o[lane] = itlb_excp_entry_hit[lane] | itlb_hit[lane] | skip_translation;

      // Miss Handler
      assign tlb_miss_req_vld[lane] = translate_resp_vld_o[lane] & translate_resp_miss_o[lane];
      assign tlb_miss_req_asid[lane] = translate_req_asid_q[lane];
      assign tlb_miss_req_access_type[lane] = PMP_ACCESS_TYPE_X;
      assign tlb_miss_req_vpn[lane] = translate_req_vpn_q[lane];

      MuxOH #(
          .InputWidth(ENTRY_COUNT),
          .DataWidth (PPN_WIDTH + PAGE_LVL_WIDTH + 7)
      ) u_itlb_hit_entry_MuxOH (
          .sel_i(itlb_entry_hit[lane]),
          .data_i(itlb_hit_entry_mux_in),
          .data_o({
            itlb_hit_entry_mux_out_page_lvl[lane],
            itlb_hit_entry_mux_out_PPN[lane],
            itlb_hit_entry_mux_out_D[lane],
            itlb_hit_entry_mux_out_A[lane],
            itlb_hit_entry_mux_out_G[lane],
            itlb_hit_entry_mux_out_U[lane],
            itlb_hit_entry_mux_out_X[lane],
            itlb_hit_entry_mux_out_W[lane],
            itlb_hit_entry_mux_out_R[lane]
          })
      );

      DFFR #(
          .Width(1)
      ) u_translate_req_vld_DFFR (
          .CLK(clk),
          .RSTN(rstn),
          .DRST(1'b0),
          .D(translate_req_vld_d[lane]),
          .Q(translate_req_vld_q[lane])
      );

      DFFE #(
          .Width(VPN_WIDTH + ASID_WIDTH)
      ) u_translate_req_payload_DFFR (
          .CLK(clk),
          .EN (translate_req_payload_clk_en[lane]),
          .D  ({translate_req_vpn_d[lane], translate_req_asid_d[lane]}),
          .Q  ({translate_req_vpn_q[lane], translate_req_asid_q[lane]})
      );

    end
  endgenerate

  // ITLB Exception Entry Management
  assign refill_exception_entry = next_lvl_resp_vld_i & (next_lvl_resp_access_fault_i | next_lvl_resp_page_fault_i);
  assign itlb_excp_entry_vld_set = refill_exception_entry;
  assign itlb_excp_entry_vld_clean = tlb_flush_vld_i;  // Flush Exception Anyway
  assign itlb_excp_entry_vld_clk_en = itlb_excp_entry_vld_set | itlb_excp_entry_vld_clean;
  assign itlb_excp_entry_payload_clk_en = refill_exception_entry;

  assign itlb_excp_entry_V_d = itlb_excp_entry_vld_set & ~itlb_excp_entry_vld_clean;
  assign itlb_excp_entry_vpn_d = next_lvl_resp_vpn_i;
  assign itlb_excp_entry_asid_d = next_lvl_resp_asid_i;
  assign itlb_excp_entry_page_lvl_d = next_lvl_resp_page_lvl_i;
  assign itlb_excp_entry_access_fault_d = next_lvl_resp_access_fault_i;
  assign itlb_excp_entry_page_fault_d = next_lvl_resp_page_fault_i;

  // Refill Setup
  assign refill_entry = next_lvl_resp_vld_q & ~next_lvl_resp_excp_vld_q;
  assign next_lvl_resp_payload_clk_en = next_lvl_resp_vld_i;
  assign next_lvl_resp_excp_vld_d = refill_exception_entry;
  assign next_lvl_resp_vld_d = next_lvl_resp_vld_i;
  assign next_lvl_resp_trans_id_d = next_lvl_resp_trans_id_i;
  assign next_lvl_resp_asid_d = next_lvl_resp_asid_i;
  assign next_lvl_resp_pte_d = next_lvl_resp_pte_i;
  assign next_lvl_resp_page_lvl_d = next_lvl_resp_page_lvl_i;
  assign next_lvl_resp_vpn_d = next_lvl_resp_vpn_i;

  // ITLB Entry Management
  assign exist_invld_entry = |(~itlb_entry_V_q);
  assign refill_invld_oh_mask = (~itlb_entry_V_q) & ~((~itlb_entry_V_q) - 1'b1);
  assign tlb_refill_entry_is_evicted_d = ~exist_invld_entry;
  assign tlb_refill_entry_mask_d = exist_invld_entry ? refill_invld_oh_mask : refill_evict_oh_mask;

  generate
    for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_itlb_entry_update_logic
      // Update Valid
      assign itlb_entry_payload_clk_en[macro] = itlb_entry_vld_set[macro];
      assign itlb_entry_vld_set[macro] = refill_entry & tlb_refill_entry_mask_q[macro];
      assign itlb_entry_vld_clean[macro] = tlb_flush_vld_i & 
      ((~itlb_entry_G_q[macro] & (((tlb_flush_use_asid_i & tlb_flush_use_vpn_i) & 
      ((itlb_entry_asid_q[macro] == tlb_flush_asid_i) & (&(~(itlb_entry_vpn_q[macro] ^ tlb_flush_vpn_i) | (~itlb_entry_vpn_mask[macro]))))) | 
      ((tlb_flush_use_asid_i & ~tlb_flush_use_vpn_i) & (itlb_entry_asid_q[macro] == tlb_flush_asid_i)) | 
      ((~tlb_flush_use_asid_i & tlb_flush_use_vpn_i) & (&(~(itlb_entry_vpn_q[macro] ^ tlb_flush_vpn_i) | (~itlb_entry_vpn_mask[macro])))))) |
      ((~tlb_flush_use_asid_i & ~tlb_flush_use_vpn_i) & 1'b1));

      assign itlb_entry_V_d[macro] = itlb_entry_vld_set[macro] & (~itlb_entry_vld_clean[macro]);
      assign itlb_entry_vld_clk_en[macro] = itlb_entry_vld_set[macro] | itlb_entry_vld_clean[macro];
      // Update Payload
      assign itlb_entry_asid_d[macro] = next_lvl_resp_asid_q;
      assign itlb_entry_vpn_d[macro] = next_lvl_resp_vpn_q;
      assign itlb_entry_page_lvl_d[macro] = next_lvl_resp_page_lvl_q;
      assign itlb_entry_PPN_d[macro] = next_lvl_resp_pte_q[53:10];
      assign itlb_entry_D_d[macro] = next_lvl_resp_pte_q[7];
      assign itlb_entry_A_d[macro] = next_lvl_resp_pte_q[6];
      assign itlb_entry_G_d[macro] = next_lvl_resp_pte_q[5];
      assign itlb_entry_U_d[macro] = next_lvl_resp_pte_q[4];
      assign itlb_entry_X_d[macro] = next_lvl_resp_pte_q[3];
      assign itlb_entry_W_d[macro] = next_lvl_resp_pte_q[2];
      assign itlb_entry_R_d[macro] = next_lvl_resp_pte_q[1];

    end
  endgenerate

  generate
    for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_evict_entry
      assign evict_itlb_entry_mux_in[macro] = {
        itlb_entry_asid_q[macro],
        itlb_entry_vpn_q[macro],
        itlb_entry_page_lvl_q[macro],
        itlb_entry_PPN_q[macro],
        itlb_entry_D_q[macro],
        itlb_entry_A_q[macro],
        itlb_entry_G_q[macro],
        itlb_entry_U_q[macro],
        itlb_entry_X_q[macro],
        itlb_entry_W_q[macro],
        itlb_entry_R_q[macro],
        itlb_entry_V_q[macro]
      };
    end
  endgenerate

  // assign tlb_evict_vld_o = refill_entry & tlb_refill_entry_is_evicted_q;
  // assign tlb_evict_pte_o = {
  //   1'b0,
  //   2'b0,
  //   7'b0,
  //   evict_itlb_entry_PPN,
  //   2'b0,
  //   evict_itlb_entry_D,
  //   evict_itlb_entry_A,
  //   evict_itlb_entry_G,
  //   evict_itlb_entry_U,
  //   evict_itlb_entry_X,
  //   evict_itlb_entry_W,
  //   evict_itlb_entry_R
  // };
  // assign tlb_evict_page_lvl_o = evict_itlb_entry_page_lvl;
  // assign tlb_evict_vpn_o = evict_itlb_entry_vpn;
  // assign tlb_evict_asid_o = evict_itlb_entry_asid;


  // MuxOH #(
  //     .InputWidth(ENTRY_COUNT),
  //     .DataWidth (ASID_WIDTH + VPN_WIDTH + PAGE_LVL_WIDTH + PPN_WIDTH + 8)
  // ) u_itlb_evict_entry_MuxOH (
  //     .sel_i(tlb_refill_entry_mask_q),
  //     .data_i(evict_itlb_entry_mux_in),
  //     .data_o({
  //       evict_itlb_entry_asid,
  //       evict_itlb_entry_vpn,
  //       evict_itlb_entry_page_lvl,
  //       evict_itlb_entry_PPN,
  //       evict_itlb_entry_D,
  //       evict_itlb_entry_A,
  //       evict_itlb_entry_G,
  //       evict_itlb_entry_U,
  //       evict_itlb_entry_X,
  //       evict_itlb_entry_W,
  //       evict_itlb_entry_R
  //     })
  // );

  DFFR #(
      .Width(1)
  ) u_next_lvl_resp_vld_DFFR (
      .CLK(clk),
      .RSTN(rstn),
      .DRST(1'b0),
      .D(next_lvl_resp_vld_d),
      .Q(next_lvl_resp_vld_q)
  );

  DFFE #(
      .Width($bits(
          next_lvl_resp_trans_id_q
      ) + $bits(
          next_lvl_resp_asid_q
      ) + $bits(
          next_lvl_resp_pte_q
      ) + $bits(
          next_lvl_resp_page_lvl_q
      ) + $bits(
          next_lvl_resp_vpn_q
      ) + $bits(
          tlb_refill_entry_is_evicted_q
      ) + $bits(
          next_lvl_resp_excp_vld_q
      ) + $bits(
          tlb_refill_entry_mask_q
      ))
  ) u_next_lvl_resp_payload_DFFE (
      .CLK(clk),
      .EN(next_lvl_resp_payload_clk_en),
      .D({
        next_lvl_resp_trans_id_d,
        next_lvl_resp_asid_d,
        next_lvl_resp_pte_d,
        next_lvl_resp_page_lvl_d,
        next_lvl_resp_vpn_d,
        next_lvl_resp_excp_vld_d,
        tlb_refill_entry_is_evicted_d,
        tlb_refill_entry_mask_d
      }),
      .Q({
        next_lvl_resp_trans_id_q,
        next_lvl_resp_asid_q,
        next_lvl_resp_pte_q,
        next_lvl_resp_page_lvl_q,
        next_lvl_resp_vpn_q,
        next_lvl_resp_excp_vld_q,
        tlb_refill_entry_is_evicted_q,
        tlb_refill_entry_mask_q
      })
  );

  PLRU #(
      .ENTRY_COUNT(ENTRY_COUNT)
  ) u_PLRU (
      .access_mask_i(itlb_plru_access_mask),
      .least_used_mask_o(refill_evict_oh_mask),
      .clk(clk),
      .rstn(rstn)
  );

  rvh_mmu_mshr #(
      .ALLOC_WIDTH(TRANSLATE_WIDTH),
      .ENTRY_COUNT(MSHR_COUNT)
  ) u_rvh_mmu_mshr (
      .tlb_miss_req_vld_i(tlb_miss_req_vld),
      .tlb_miss_req_asid_i(tlb_miss_req_asid),
      .tlb_miss_req_access_type_i(tlb_miss_req_access_type),
      .tlb_miss_req_vpn_i(tlb_miss_req_vpn),
      .tlb_miss_req_grant_vld_o(next_lvl_req_vld_o),
      .tlb_miss_req_grant_trans_id_o(next_lvl_req_trans_id_o),
      .tlb_miss_req_grant_asid_o(next_lvl_req_asid_o),
      .tlb_miss_req_grant_vpn_o(next_lvl_req_vpn_o),
      .tlb_miss_req_grant_access_type_o(next_lvl_req_access_type_o),
      .tlb_miss_req_grant_rdy_i(next_lvl_req_rdy_i),
      .tlb_miss_response_vld_i(next_lvl_resp_vld_q),
      .tlb_miss_respone_trans_id_i(next_lvl_resp_trans_id_q),
      .exist_inflight_req_o(exist_inflight_req),
      .clk(clk),
      .rstn(rstn)
  );

  DFFR #(
      .Width(1)
  ) u_itlb_flush_grant_DFFR (
      .CLK(clk),
      .RSTN(rstn),
      .DRST(1'b0),
      .D(tlb_flush_vld_i),
      .Q(tlb_flush_grant_o)
  );

  DFFRE #(
      .Width(1)
  ) u_itlb_excp_entry_vld_DFFRE (
      .CLK(clk),
      .RSTN(rstn),
      .DRST(1'b0),
      .EN(itlb_excp_entry_vld_clk_en),
      .D(itlb_excp_entry_V_d),
      .Q(itlb_excp_entry_V_q)
  );

  DFFE #(
      .Width($bits(
          itlb_excp_entry_vpn_q
      ) + $bits(
          itlb_excp_entry_asid_q
      ) + $bits(
          itlb_excp_entry_page_lvl_q
      ) + $bits(
          itlb_excp_entry_access_fault_q
      ) + $bits(
          itlb_excp_entry_page_fault_q
      ))
  ) u_itlb_excp_entry_payload_DFFR (
      .CLK(clk),
      .EN(itlb_excp_entry_payload_clk_en),
      .D({
        itlb_excp_entry_vpn_d,
        itlb_excp_entry_asid_d,
        itlb_excp_entry_page_lvl_d,
        itlb_excp_entry_access_fault_d,
        itlb_excp_entry_page_fault_d
      }),
      .Q({
        itlb_excp_entry_vpn_q,
        itlb_excp_entry_asid_q,
        itlb_excp_entry_page_lvl_q,
        itlb_excp_entry_access_fault_q,
        itlb_excp_entry_page_fault_q
      })
  );

  generate
    for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_itlb_entry
      DFFRE #(
          .Width(1)
      ) u_itlb_entry_vld_DFFR (
          .CLK(clk),
          .RSTN(rstn),
          .DRST(1'b0),
          .EN(itlb_entry_vld_clk_en[macro]),
          .D(itlb_entry_V_d[macro]),
          .Q(itlb_entry_V_q[macro])
      );
      DFFE #(
          .Width($bits(
              itlb_entry_asid_q[macro]
          ) + $bits(
              itlb_entry_vpn_q[macro]
          ) + $bits(
              itlb_entry_page_lvl_q[macro]
          ) + $bits(
              itlb_entry_PPN_q[macro]
          ) + 7)
      ) u_itlb_entry_payload_DFFE (
          .CLK(clk),
          .EN(itlb_entry_payload_clk_en[macro]),
          .D({
            {
              itlb_entry_asid_d[macro],
              itlb_entry_vpn_d[macro],
              itlb_entry_page_lvl_d[macro],
              itlb_entry_PPN_d[macro],
              itlb_entry_D_d[macro],
              itlb_entry_A_d[macro],
              itlb_entry_G_d[macro],
              itlb_entry_U_d[macro],
              itlb_entry_X_d[macro],
              itlb_entry_W_d[macro],
              itlb_entry_R_d[macro]
            }
          }),
          .Q({
            {
              itlb_entry_asid_q[macro],
              itlb_entry_vpn_q[macro],
              itlb_entry_page_lvl_q[macro],
              itlb_entry_PPN_q[macro],
              itlb_entry_D_q[macro],
              itlb_entry_A_q[macro],
              itlb_entry_G_q[macro],
              itlb_entry_U_q[macro],
              itlb_entry_X_q[macro],
              itlb_entry_W_q[macro],
              itlb_entry_R_q[macro]
            }
          })
      );
    end
  endgenerate

endmodule
