module rvh_itlb (
	priv_lvl_i,
	mstatus_mxr,
	mstatus_sum,
	satp_mode_i,
	satp_asid_i,
	translate_req_vld_i,
	translate_req_vpn_i,
	translate_req_rdy_o,
	translate_resp_vld_o,
	translate_resp_ppn_o,
	translate_resp_excp_vld_o,
	translate_resp_excp_cause_o,
	translate_resp_miss_o,
	translate_resp_hit_o,
	next_lvl_req_vld_o,
	next_lvl_req_trans_id_o,
	next_lvl_req_asid_o,
	next_lvl_req_vpn_o,
	next_lvl_req_access_type_o,
	next_lvl_req_rdy_i,
	next_lvl_resp_vld_i,
	next_lvl_resp_trans_id_i,
	next_lvl_resp_asid_i,
	next_lvl_resp_pte_i,
	next_lvl_resp_page_lvl_i,
	next_lvl_resp_vpn_i,
	next_lvl_resp_access_type_i,
	next_lvl_resp_access_fault_i,
	next_lvl_resp_page_fault_i,
	tlb_flush_vld_i,
	tlb_flush_use_asid_i,
	tlb_flush_use_vpn_i,
	tlb_flush_vpn_i,
	tlb_flush_asid_i,
	tlb_flush_grant_o,
	clk,
	rstn
);
	localparam ITLB_TRANSLATE_WIDTH = 1;
	parameter TRANSLATE_WIDTH = ITLB_TRANSLATE_WIDTH;
	localparam ITLB_ENTRY_COUNT = 32;
	parameter ENTRY_COUNT = ITLB_ENTRY_COUNT;
	localparam ITLB_MSHR_COUNT = 1;
	parameter MSHR_COUNT = ITLB_MSHR_COUNT;
	localparam ITLB_TRANS_ID_WIDTH = 3;
	parameter TRANS_ID_WIDTH = ITLB_TRANS_ID_WIDTH;
	input [1:0] priv_lvl_i;
	input mstatus_mxr;
	input mstatus_sum;
	localparam MODE_WIDTH = 4;
	input [3:0] satp_mode_i;
	localparam ASID_WIDTH = 16;
	input [15:0] satp_asid_i;
	input [TRANSLATE_WIDTH - 1:0] translate_req_vld_i;
	localparam ADDR_INDEX_LEN = 6;
	localparam ADDR_OFFSET_LEN = 6;
	localparam VIRTUAL_ADDR_LEN = 39;
	localparam VPN_WIDTH = 27;
	input [(TRANSLATE_WIDTH * 27) - 1:0] translate_req_vpn_i;
	output wire [TRANSLATE_WIDTH - 1:0] translate_req_rdy_o;
	output wire [TRANSLATE_WIDTH - 1:0] translate_resp_vld_o;
	localparam PHYSICAL_ADDR_LEN = 56;
	localparam PPN_WIDTH = 44;
	output wire [(TRANSLATE_WIDTH * 44) - 1:0] translate_resp_ppn_o;
	output wire [TRANSLATE_WIDTH - 1:0] translate_resp_excp_vld_o;
	localparam EXCEPTION_CAUSE_WIDTH = 5;
	localparam EXCP_CAUSE_WIDTH = EXCEPTION_CAUSE_WIDTH;
	output wire [(TRANSLATE_WIDTH * 5) - 1:0] translate_resp_excp_cause_o;
	output wire [TRANSLATE_WIDTH - 1:0] translate_resp_miss_o;
	output wire [TRANSLATE_WIDTH - 1:0] translate_resp_hit_o;
	output wire next_lvl_req_vld_o;
	output wire [TRANS_ID_WIDTH - 1:0] next_lvl_req_trans_id_o;
	output wire [15:0] next_lvl_req_asid_o;
	output wire [26:0] next_lvl_req_vpn_o;
	output wire [1:0] next_lvl_req_access_type_o;
	input next_lvl_req_rdy_i;
	input next_lvl_resp_vld_i;
	input [TRANS_ID_WIDTH - 1:0] next_lvl_resp_trans_id_i;
	input [15:0] next_lvl_resp_asid_i;
	localparam PTE_WIDTH = 64;
	input [63:0] next_lvl_resp_pte_i;
	localparam PAGE_LVL_WIDTH = 2;
	input [1:0] next_lvl_resp_page_lvl_i;
	input [26:0] next_lvl_resp_vpn_i;
	input [1:0] next_lvl_resp_access_type_i;
	input next_lvl_resp_access_fault_i;
	input next_lvl_resp_page_fault_i;
	input tlb_flush_vld_i;
	input tlb_flush_use_asid_i;
	input tlb_flush_use_vpn_i;
	input [26:0] tlb_flush_vpn_i;
	input [15:0] tlb_flush_asid_i;
	output reg tlb_flush_grant_o;
	input clk;
	input rstn;
	genvar lane;
	genvar macro;
	localparam HIGHEST_PAGE_LVL = 3;
	localparam MODE_BARE = 0;
	localparam MODE_SV39 = 8;
	localparam MODE_SV48 = 9;
	localparam MODE_SV57 = 10;
	localparam SV39_LEVELS = 3;
	localparam SV48_LEVELS = 4;
	localparam SV57_LEVELS = 5;
	localparam SV39_LEVELS_DIFF = 0;
	localparam SV48_LEVELS_DIFF = 0;
	localparam SV57_LEVELS_DIFF = 0;
	localparam PRIV_LVL_M = 3;
	localparam PRIV_LVL_S = 1;
	localparam PRIV_LVL_U = 0;
	localparam INSTR_ACCESS_FAULT = 1;
	localparam INSTR_PAGE_FAULT = 12;
	localparam PMP_ACCESS_TYPE_R = 0;
	localparam PMP_ACCESS_TYPE_W = 1;
	localparam PMP_ACCESS_TYPE_X = 2;
	function automatic [26:0] gen_page_vpn_mask;
		input [3:0] satp_mode_i;
		input [1:0] page_lvl_i;
		integer i;
		reg [2:0] satp_mode_mask;
		reg [2:0] vpn_segment_en_mask;
		begin
			case (satp_mode_i)
				MODE_SV39: satp_mode_mask = {{SV39_LEVELS_DIFF {1'b0}}, {SV39_LEVELS {1'b1}}};
				MODE_SV48: satp_mode_mask = {{SV48_LEVELS_DIFF {1'b0}}, {SV48_LEVELS {1'b1}}};
				MODE_SV57: satp_mode_mask = {{SV57_LEVELS_DIFF {1'b0}}, {SV57_LEVELS {1'b1}}};
				default: satp_mode_mask = {HIGHEST_PAGE_LVL {1'b0}};
			endcase
			vpn_segment_en_mask = ~(({{2 {1'b0}}, 1'b1} << page_lvl_i) - 1'b1) & satp_mode_mask;
			for (i = 0; i < HIGHEST_PAGE_LVL; i = i + 1)
				gen_page_vpn_mask[i * 9+:9] = {9 {vpn_segment_en_mask[i]}};
		end
	endfunction
	function automatic [43:0] gen_page_alignment_mask;
		input [1:0] page_lvl_i;
		reg [2:0] ppn_segment_en_mask;
		reg [43:0] mask;
		integer i;
		begin
			mask = {PPN_WIDTH {1'b0}};
			ppn_segment_en_mask = ({{2 {1'b0}}, 1'b1} << page_lvl_i) - 1'b1;
			for (i = 0; i < HIGHEST_PAGE_LVL; i = i + 1)
				mask[i * 9+:9] = {9 {ppn_segment_en_mask[i]}};
			gen_page_alignment_mask = mask;
		end
	endfunction
	wire skip_translation;
	wire exist_inflight_req;
	wire [TRANSLATE_WIDTH - 1:0] translate_req_fire;
	wire [TRANSLATE_WIDTH - 1:0] translate_req_payload_clk_en;
	wire [TRANSLATE_WIDTH - 1:0] translate_req_vld_d;
	wire [(TRANSLATE_WIDTH * 27) - 1:0] translate_req_vpn_d;
	wire [(TRANSLATE_WIDTH * 16) - 1:0] translate_req_asid_d;
	reg [TRANSLATE_WIDTH - 1:0] translate_req_vld_q;
	reg [(TRANSLATE_WIDTH * 27) - 1:0] translate_req_vpn_q;
	reg [(TRANSLATE_WIDTH * 16) - 1:0] translate_req_asid_q;
	wire refill_exception_entry;
	wire itlb_excp_entry_vld_set;
	wire itlb_excp_entry_vld_clean;
	wire itlb_excp_entry_vld_clk_en;
	wire itlb_excp_entry_payload_clk_en;
	wire [26:0] itlb_excp_entry_vpn_d;
	wire [15:0] itlb_excp_entry_asid_d;
	wire [1:0] itlb_excp_entry_page_lvl_d;
	wire itlb_excp_entry_access_fault_d;
	wire itlb_excp_entry_page_fault_d;
	wire itlb_excp_entry_V_d;
	reg [26:0] itlb_excp_entry_vpn_q;
	reg [15:0] itlb_excp_entry_asid_q;
	reg [1:0] itlb_excp_entry_page_lvl_q;
	reg itlb_excp_entry_access_fault_q;
	reg itlb_excp_entry_page_fault_q;
	reg itlb_excp_entry_V_q;
	wire refill_entry;
	wire exist_invld_entry;
	wire [ENTRY_COUNT - 1:0] refill_invld_oh_mask;
	wire [ENTRY_COUNT - 1:0] refill_evict_oh_mask;
	wire [ENTRY_COUNT - 1:0] itlb_entry_vld_clk_en;
	wire [ENTRY_COUNT - 1:0] itlb_entry_vld_set;
	wire [ENTRY_COUNT - 1:0] itlb_entry_vld_clean;
	wire [ENTRY_COUNT - 1:0] itlb_entry_payload_clk_en;
	wire [(ENTRY_COUNT * 16) - 1:0] itlb_entry_asid_d;
	wire [(ENTRY_COUNT * 27) - 1:0] itlb_entry_vpn_d;
	wire [(ENTRY_COUNT * 2) - 1:0] itlb_entry_page_lvl_d;
	reg [(ENTRY_COUNT * 16) - 1:0] itlb_entry_asid_q;
	reg [(ENTRY_COUNT * 27) - 1:0] itlb_entry_vpn_q;
	reg [(ENTRY_COUNT * 2) - 1:0] itlb_entry_page_lvl_q;
	wire [(ENTRY_COUNT * 44) - 1:0] itlb_entry_PPN_d;
	wire [ENTRY_COUNT - 1:0] itlb_entry_D_d;
	wire [ENTRY_COUNT - 1:0] itlb_entry_A_d;
	wire [ENTRY_COUNT - 1:0] itlb_entry_G_d;
	wire [ENTRY_COUNT - 1:0] itlb_entry_U_d;
	wire [ENTRY_COUNT - 1:0] itlb_entry_X_d;
	wire [ENTRY_COUNT - 1:0] itlb_entry_W_d;
	wire [ENTRY_COUNT - 1:0] itlb_entry_R_d;
	wire [ENTRY_COUNT - 1:0] itlb_entry_V_d;
	reg [(ENTRY_COUNT * 44) - 1:0] itlb_entry_PPN_q;
	reg [ENTRY_COUNT - 1:0] itlb_entry_D_q;
	reg [ENTRY_COUNT - 1:0] itlb_entry_A_q;
	reg [ENTRY_COUNT - 1:0] itlb_entry_G_q;
	reg [ENTRY_COUNT - 1:0] itlb_entry_U_q;
	reg [ENTRY_COUNT - 1:0] itlb_entry_X_q;
	reg [ENTRY_COUNT - 1:0] itlb_entry_W_q;
	reg [ENTRY_COUNT - 1:0] itlb_entry_R_q;
	reg [ENTRY_COUNT - 1:0] itlb_entry_V_q;
	wire [26:0] itlb_excp_entry_vpn_mask;
	wire [(TRANSLATE_WIDTH * 27) - 1:0] itlb_excp_entry_vpn_equal_bit;
	wire [TRANSLATE_WIDTH - 1:0] itlb_excp_entry_hit;
	wire [(ENTRY_COUNT * 27) - 1:0] itlb_entry_vpn_mask;
	wire [((TRANSLATE_WIDTH * ENTRY_COUNT) * 27) - 1:0] itlb_entry_vpn_equal_bit;
	wire [(TRANSLATE_WIDTH * ENTRY_COUNT) - 1:0] itlb_entry_hit;
	wire [TRANSLATE_WIDTH - 1:0] itlb_hit;
	wire [(ENTRY_COUNT * 53) - 1:0] itlb_hit_entry_mux_in;
	wire [(TRANSLATE_WIDTH * 2) - 1:0] itlb_hit_entry_mux_out_page_lvl;
	wire [(TRANSLATE_WIDTH * 44) - 1:0] itlb_hit_entry_mux_out_PPN;
	wire [TRANSLATE_WIDTH - 1:0] itlb_hit_entry_mux_out_D;
	wire [TRANSLATE_WIDTH - 1:0] itlb_hit_entry_mux_out_A;
	wire [TRANSLATE_WIDTH - 1:0] itlb_hit_entry_mux_out_G;
	wire [TRANSLATE_WIDTH - 1:0] itlb_hit_entry_mux_out_U;
	wire [TRANSLATE_WIDTH - 1:0] itlb_hit_entry_mux_out_X;
	wire [TRANSLATE_WIDTH - 1:0] itlb_hit_entry_mux_out_W;
	wire [TRANSLATE_WIDTH - 1:0] itlb_hit_entry_mux_out_R;
	wire [(ENTRY_COUNT * TRANSLATE_WIDTH) - 1:0] itlb_lane_hit_mask_trans;
	wire [ENTRY_COUNT - 1:0] itlb_plru_access_mask;
	wire [(TRANSLATE_WIDTH * 44) - 1:0] pte_superpage_alignment_mask;
	wire [TRANSLATE_WIDTH - 1:0] pte_superpage_alignment_check_fail;
	wire [TRANSLATE_WIDTH - 1:0] pte_access_permission_check_fail;
	wire [TRANSLATE_WIDTH - 1:0] pte_superpage_alignment_check_pass;
	wire [TRANSLATE_WIDTH - 1:0] pte_access_permission_check_pass;
	wire [TRANSLATE_WIDTH - 1:0] pte_check_pass;
	wire [TRANSLATE_WIDTH - 1:0] pte_check_fail;
	wire [TRANSLATE_WIDTH - 1:0] tlb_miss_req_vld;
	wire [(TRANSLATE_WIDTH * 16) - 1:0] tlb_miss_req_asid;
	wire [(TRANSLATE_WIDTH * 2) - 1:0] tlb_miss_req_access_type;
	wire [(TRANSLATE_WIDTH * 27) - 1:0] tlb_miss_req_vpn;
	wire next_lvl_resp_payload_clk_en;
	wire next_lvl_resp_vld_d;
	wire [TRANS_ID_WIDTH - 1:0] next_lvl_resp_trans_id_d;
	wire [15:0] next_lvl_resp_asid_d;
	wire [63:0] next_lvl_resp_pte_d;
	wire [1:0] next_lvl_resp_page_lvl_d;
	wire [26:0] next_lvl_resp_vpn_d;
	wire next_lvl_resp_excp_vld_d;
	wire tlb_refill_entry_is_evicted_d;
	wire [ENTRY_COUNT - 1:0] tlb_refill_entry_mask_d;
	reg next_lvl_resp_vld_q;
	reg [TRANS_ID_WIDTH - 1:0] next_lvl_resp_trans_id_q;
	reg [15:0] next_lvl_resp_asid_q;
	reg [63:0] next_lvl_resp_pte_q;
	reg [1:0] next_lvl_resp_page_lvl_q;
	reg [26:0] next_lvl_resp_vpn_q;
	reg next_lvl_resp_excp_vld_q;
	reg tlb_refill_entry_is_evicted_q;
	reg [ENTRY_COUNT - 1:0] tlb_refill_entry_mask_q;
	wire [(ENTRY_COUNT * 97) - 1:0] evict_itlb_entry_mux_in;
	wire [15:0] evict_itlb_entry_asid;
	wire [26:0] evict_itlb_entry_vpn;
	wire [1:0] evict_itlb_entry_page_lvl;
	wire [43:0] evict_itlb_entry_PPN;
	wire evict_itlb_entry_D;
	wire evict_itlb_entry_A;
	wire evict_itlb_entry_G;
	wire evict_itlb_entry_U;
	wire evict_itlb_entry_X;
	wire evict_itlb_entry_W;
	wire evict_itlb_entry_R;
	assign skip_translation = (priv_lvl_i == PRIV_LVL_M) | (satp_mode_i == MODE_BARE);
	assign itlb_excp_entry_vpn_mask = gen_page_vpn_mask(satp_mode_i, itlb_excp_entry_page_lvl_q);
	generate
		for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_itlb_entry_vpn_mask
			assign itlb_entry_vpn_mask[macro * 27+:27] = gen_page_vpn_mask(satp_mode_i, itlb_entry_page_lvl_q[macro * 2+:2]);
		end
		for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_itlb_hit_entry_mux_in
			assign itlb_hit_entry_mux_in[macro * 53+:53] = {itlb_entry_page_lvl_q[macro * 2+:2], itlb_entry_PPN_q[macro * 44+:44], itlb_entry_D_q[macro], itlb_entry_A_q[macro], itlb_entry_G_q[macro], itlb_entry_U_q[macro], itlb_entry_X_q[macro], itlb_entry_W_q[macro], itlb_entry_R_q[macro]};
		end
	endgenerate
	function automatic signed [4:0] sv2v_cast_5_signed;
		input reg signed [4:0] inp;
		sv2v_cast_5_signed = inp;
	endfunction
	generate
		for (lane = 0; lane < TRANSLATE_WIDTH; lane = lane + 1) begin : gen_lane
			assign translate_req_rdy_o[lane] = ~exist_inflight_req;
			assign translate_req_fire[lane] = translate_req_rdy_o[lane] & translate_req_vld_i[lane];
			assign translate_req_payload_clk_en[lane] = translate_req_fire[lane];
			assign translate_req_vld_d[lane] = translate_req_fire[lane];
			assign translate_req_vpn_d[lane * 27+:27] = translate_req_vpn_i[lane * 27+:27];
			assign translate_req_asid_d[lane * 16+:16] = satp_asid_i;
			assign itlb_excp_entry_vpn_equal_bit[lane * 27+:27] = ~(translate_req_vpn_q[lane * 27+:27] ^ itlb_excp_entry_vpn_q);
			assign itlb_excp_entry_hit[lane] = ((translate_req_vld_q[lane] & itlb_excp_entry_V_q) & (translate_req_asid_q[lane * 16+:16] == itlb_excp_entry_asid_q)) & &(itlb_excp_entry_vpn_equal_bit[lane * 27+:27] | ~itlb_excp_entry_vpn_mask);
			for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_itlb_entry_hit_logic
				assign itlb_entry_vpn_equal_bit[((lane * ENTRY_COUNT) + macro) * 27+:27] = ~(translate_req_vpn_q[lane * 27+:27] ^ itlb_entry_vpn_q[macro * 27+:27]);
				assign itlb_entry_hit[(lane * ENTRY_COUNT) + macro] = ((translate_req_vld_q[lane] & itlb_entry_V_q[macro]) & ((translate_req_asid_q[lane * 16+:16] == itlb_entry_asid_q[macro * 16+:16]) | itlb_entry_G_q[macro])) & &(itlb_entry_vpn_equal_bit[((lane * ENTRY_COUNT) + macro) * 27+:27] | ~itlb_entry_vpn_mask[macro * 27+:27]);
			end
			assign itlb_hit[lane] = |itlb_entry_hit[lane * ENTRY_COUNT+:ENTRY_COUNT];
			for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_plru_access_mask
				assign itlb_lane_hit_mask_trans[(macro * TRANSLATE_WIDTH) + lane] = itlb_entry_hit[(lane * ENTRY_COUNT) + macro];
				assign itlb_plru_access_mask[macro] = |itlb_lane_hit_mask_trans[macro * TRANSLATE_WIDTH+:TRANSLATE_WIDTH];
			end
			assign pte_superpage_alignment_mask[lane * 44+:44] = gen_page_alignment_mask(itlb_hit_entry_mux_out_page_lvl[lane * 2+:2]);
			assign pte_superpage_alignment_check_pass[lane] = (itlb_hit_entry_mux_out_PPN[lane * 44+:44] & pte_superpage_alignment_mask[lane * 44+:44]) == 0;
			assign pte_superpage_alignment_check_fail[lane] = ~pte_superpage_alignment_check_pass[lane];
			assign pte_access_permission_check_fail[lane] = (~itlb_hit_entry_mux_out_A[lane] | ~itlb_hit_entry_mux_out_X[lane]) | ((itlb_hit_entry_mux_out_U[lane] & ~(priv_lvl_i == PRIV_LVL_U)) & ~((priv_lvl_i == PRIV_LVL_S) & mstatus_sum));
			assign pte_access_permission_check_pass[lane] = ~pte_access_permission_check_fail[lane];
			assign pte_check_pass[lane] = pte_superpage_alignment_check_pass[lane] & pte_access_permission_check_pass[lane];
			assign pte_check_fail[lane] = pte_superpage_alignment_check_fail[lane] | pte_access_permission_check_fail[lane];
			assign translate_resp_vld_o[lane] = translate_req_vld_q[lane];
			assign translate_resp_ppn_o[lane * 44+:44] = (skip_translation ? {{17 {1'b0}}, translate_req_vpn_q[lane * 27+:27]} : (itlb_hit[lane] ? (itlb_hit_entry_mux_out_PPN[lane * 44+:44] & ~pte_superpage_alignment_mask[lane * 44+:44]) | ({{17 {1'b0}}, translate_req_vpn_q[lane * 27+:27]} & {pte_superpage_alignment_mask[lane * 44+:44]}) : {PPN_WIDTH {1'b0}}));
			assign translate_resp_excp_vld_o[lane] = ~skip_translation & (itlb_excp_entry_hit[lane] | (itlb_hit[lane] & pte_check_fail[lane]));
			assign translate_resp_excp_cause_o[lane * 5+:5] = ({EXCP_CAUSE_WIDTH {~skip_translation}} & ({EXCP_CAUSE_WIDTH {itlb_excp_entry_hit[lane] & itlb_excp_entry_access_fault_q}} & sv2v_cast_5_signed(INSTR_ACCESS_FAULT))) | ({EXCP_CAUSE_WIDTH {(itlb_excp_entry_hit[lane] & itlb_excp_entry_page_fault_q) | (itlb_hit[lane] & pte_check_fail[lane])}} & sv2v_cast_5_signed(INSTR_PAGE_FAULT));
			assign translate_resp_miss_o[lane] = ~translate_resp_hit_o[lane];
			assign translate_resp_hit_o[lane] = (itlb_excp_entry_hit[lane] | itlb_hit[lane]) | skip_translation;
			assign tlb_miss_req_vld[lane] = translate_resp_vld_o[lane] & translate_resp_miss_o[lane];
			assign tlb_miss_req_asid[lane * 16+:16] = translate_req_asid_q[lane * 16+:16];
			assign tlb_miss_req_access_type[lane * 2+:2] = PMP_ACCESS_TYPE_X;
			assign tlb_miss_req_vpn[lane * 27+:27] = translate_req_vpn_q[lane * 27+:27];
			MuxOH #(
				.InputWidth(ENTRY_COUNT),
				.DataWidth(53)
			) u_itlb_hit_entry_MuxOH(
				.sel_i(itlb_entry_hit[lane * ENTRY_COUNT+:ENTRY_COUNT]),
				.data_i(itlb_hit_entry_mux_in),
				.data_o({itlb_hit_entry_mux_out_page_lvl[lane * 2+:2], itlb_hit_entry_mux_out_PPN[lane * 44+:44], itlb_hit_entry_mux_out_D[lane], itlb_hit_entry_mux_out_A[lane], itlb_hit_entry_mux_out_G[lane], itlb_hit_entry_mux_out_U[lane], itlb_hit_entry_mux_out_X[lane], itlb_hit_entry_mux_out_W[lane], itlb_hit_entry_mux_out_R[lane]})
			);
			DFFR #(.Width(1)) u_translate_req_vld_DFFR(
				.CLK(clk),
				.RSTN(rstn),
				.DRST(1'b0),
				.D(translate_req_vld_d[lane]),
				.Q(translate_req_vld_q[lane])
			);
			DFFE #(.Width(43)) u_translate_req_payload_DFFR(
				.CLK(clk),
				.EN(translate_req_payload_clk_en[lane]),
				.D({translate_req_vpn_d[lane * 27+:27], translate_req_asid_d[lane * 16+:16]}),
				.Q({translate_req_vpn_q[lane * 27+:27], translate_req_asid_q[lane * 16+:16]})
			);
		end
	endgenerate
	assign refill_exception_entry = next_lvl_resp_vld_i & (next_lvl_resp_access_fault_i | next_lvl_resp_page_fault_i);
	assign itlb_excp_entry_vld_set = refill_exception_entry;
	assign itlb_excp_entry_vld_clean = tlb_flush_vld_i;
	assign itlb_excp_entry_vld_clk_en = itlb_excp_entry_vld_set | itlb_excp_entry_vld_clean;
	assign itlb_excp_entry_payload_clk_en = refill_exception_entry;
	assign itlb_excp_entry_V_d = itlb_excp_entry_vld_set & ~itlb_excp_entry_vld_clean;
	assign itlb_excp_entry_vpn_d = next_lvl_resp_vpn_i;
	assign itlb_excp_entry_asid_d = next_lvl_resp_asid_i;
	assign itlb_excp_entry_page_lvl_d = next_lvl_resp_page_lvl_i;
	assign itlb_excp_entry_access_fault_d = next_lvl_resp_access_fault_i;
	assign itlb_excp_entry_page_fault_d = next_lvl_resp_page_fault_i;
	assign refill_entry = next_lvl_resp_vld_q & ~next_lvl_resp_excp_vld_q;
	assign next_lvl_resp_payload_clk_en = next_lvl_resp_vld_i;
	assign next_lvl_resp_excp_vld_d = refill_exception_entry;
	assign next_lvl_resp_vld_d = next_lvl_resp_vld_i;
	assign next_lvl_resp_trans_id_d = next_lvl_resp_trans_id_i;
	assign next_lvl_resp_asid_d = next_lvl_resp_asid_i;
	assign next_lvl_resp_pte_d = next_lvl_resp_pte_i;
	assign next_lvl_resp_page_lvl_d = next_lvl_resp_page_lvl_i;
	assign next_lvl_resp_vpn_d = next_lvl_resp_vpn_i;
	assign exist_invld_entry = |(~itlb_entry_V_q);
	assign refill_invld_oh_mask = ~itlb_entry_V_q & ~(~itlb_entry_V_q - 1'b1);
	assign tlb_refill_entry_is_evicted_d = ~exist_invld_entry;
	assign tlb_refill_entry_mask_d = (exist_invld_entry ? refill_invld_oh_mask : refill_evict_oh_mask);
	generate
		for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_itlb_entry_update_logic
			assign itlb_entry_payload_clk_en[macro] = itlb_entry_vld_set[macro];
			assign itlb_entry_vld_set[macro] = refill_entry & tlb_refill_entry_mask_q[macro];
			assign itlb_entry_vld_clean[macro] = tlb_flush_vld_i & ((~itlb_entry_G_q[macro] & ((((tlb_flush_use_asid_i & tlb_flush_use_vpn_i) & ((itlb_entry_asid_q[macro * 16+:16] == tlb_flush_asid_i) & &(~(itlb_entry_vpn_q[macro * 27+:27] ^ tlb_flush_vpn_i) | ~itlb_entry_vpn_mask[macro * 27+:27]))) | ((tlb_flush_use_asid_i & ~tlb_flush_use_vpn_i) & (itlb_entry_asid_q[macro * 16+:16] == tlb_flush_asid_i))) | ((~tlb_flush_use_asid_i & tlb_flush_use_vpn_i) & &(~(itlb_entry_vpn_q[macro * 27+:27] ^ tlb_flush_vpn_i) | ~itlb_entry_vpn_mask[macro * 27+:27])))) | ((~tlb_flush_use_asid_i & ~tlb_flush_use_vpn_i) & 1'b1));
			assign itlb_entry_V_d[macro] = itlb_entry_vld_set[macro] & ~itlb_entry_vld_clean[macro];
			assign itlb_entry_vld_clk_en[macro] = itlb_entry_vld_set[macro] | itlb_entry_vld_clean[macro];
			assign itlb_entry_asid_d[macro * 16+:16] = next_lvl_resp_asid_q;
			assign itlb_entry_vpn_d[macro * 27+:27] = next_lvl_resp_vpn_q;
			assign itlb_entry_page_lvl_d[macro * 2+:2] = next_lvl_resp_page_lvl_q;
			assign itlb_entry_PPN_d[macro * 44+:44] = next_lvl_resp_pte_q[53:10];
			assign itlb_entry_D_d[macro] = next_lvl_resp_pte_q[7];
			assign itlb_entry_A_d[macro] = next_lvl_resp_pte_q[6];
			assign itlb_entry_G_d[macro] = next_lvl_resp_pte_q[5];
			assign itlb_entry_U_d[macro] = next_lvl_resp_pte_q[4];
			assign itlb_entry_X_d[macro] = next_lvl_resp_pte_q[3];
			assign itlb_entry_W_d[macro] = next_lvl_resp_pte_q[2];
			assign itlb_entry_R_d[macro] = next_lvl_resp_pte_q[1];
		end
		for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_evict_entry
			assign evict_itlb_entry_mux_in[macro * 97+:97] = {itlb_entry_asid_q[macro * 16+:16], itlb_entry_vpn_q[macro * 27+:27], itlb_entry_page_lvl_q[macro * 2+:2], itlb_entry_PPN_q[macro * 44+:44], itlb_entry_D_q[macro], itlb_entry_A_q[macro], itlb_entry_G_q[macro], itlb_entry_U_q[macro], itlb_entry_X_q[macro], itlb_entry_W_q[macro], itlb_entry_R_q[macro], itlb_entry_V_q[macro]};
		end
	endgenerate
	DFFR #(.Width(1)) u_next_lvl_resp_vld_DFFR(
		.CLK(clk),
		.RSTN(rstn),
		.DRST(1'b0),
		.D(next_lvl_resp_vld_d),
		.Q(next_lvl_resp_vld_q)
	);
	DFFE #(.Width((TRANS_ID_WIDTH + 111) + ENTRY_COUNT)) u_next_lvl_resp_payload_DFFE(
		.CLK(clk),
		.EN(next_lvl_resp_payload_clk_en),
		.D({next_lvl_resp_trans_id_d, next_lvl_resp_asid_d, next_lvl_resp_pte_d, next_lvl_resp_page_lvl_d, next_lvl_resp_vpn_d, next_lvl_resp_excp_vld_d, tlb_refill_entry_is_evicted_d, tlb_refill_entry_mask_d}),
		.Q({next_lvl_resp_trans_id_q, next_lvl_resp_asid_q, next_lvl_resp_pte_q, next_lvl_resp_page_lvl_q, next_lvl_resp_vpn_q, next_lvl_resp_excp_vld_q, tlb_refill_entry_is_evicted_q, tlb_refill_entry_mask_q})
	);
	PLRU #(.ENTRY_COUNT(ENTRY_COUNT)) u_PLRU(
		.access_mask_i(itlb_plru_access_mask),
		.least_used_mask_o(refill_evict_oh_mask),
		.clk(clk),
		.rstn(rstn)
	);
	rvh_mmu_mshr #(
		.ALLOC_WIDTH(TRANSLATE_WIDTH),
		.ENTRY_COUNT(MSHR_COUNT)
	) u_rvh_mmu_mshr(
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
	DFFR #(.Width(1)) u_itlb_flush_grant_DFFR(
		.CLK(clk),
		.RSTN(rstn),
		.DRST(1'b0),
		.D(tlb_flush_vld_i),
		.Q(tlb_flush_grant_o)
	);
	DFFRE #(.Width(1)) u_itlb_excp_entry_vld_DFFRE(
		.CLK(clk),
		.RSTN(rstn),
		.DRST(1'b0),
		.EN(itlb_excp_entry_vld_clk_en),
		.D(itlb_excp_entry_V_d),
		.Q(itlb_excp_entry_V_q)
	);
	DFFE #(.Width(47)) u_itlb_excp_entry_payload_DFFR(
		.CLK(clk),
		.EN(itlb_excp_entry_payload_clk_en),
		.D({itlb_excp_entry_vpn_d, itlb_excp_entry_asid_d, itlb_excp_entry_page_lvl_d, itlb_excp_entry_access_fault_d, itlb_excp_entry_page_fault_d}),
		.Q({itlb_excp_entry_vpn_q, itlb_excp_entry_asid_q, itlb_excp_entry_page_lvl_q, itlb_excp_entry_access_fault_q, itlb_excp_entry_page_fault_q})
	);
	generate
		for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_itlb_entry
			DFFRE #(.Width(1)) u_itlb_entry_vld_DFFR(
				.CLK(clk),
				.RSTN(rstn),
				.DRST(1'b0),
				.EN(itlb_entry_vld_clk_en[macro]),
				.D(itlb_entry_V_d[macro]),
				.Q(itlb_entry_V_q[macro])
			);
			DFFE #(.Width(96)) u_itlb_entry_payload_DFFE(
				.CLK(clk),
				.EN(itlb_entry_payload_clk_en[macro]),
				.D({itlb_entry_asid_d[macro * 16+:16], itlb_entry_vpn_d[macro * 27+:27], itlb_entry_page_lvl_d[macro * 2+:2], itlb_entry_PPN_d[macro * 44+:44], itlb_entry_D_d[macro], itlb_entry_A_d[macro], itlb_entry_G_d[macro], itlb_entry_U_d[macro], itlb_entry_X_d[macro], itlb_entry_W_d[macro], itlb_entry_R_d[macro]}),
				.Q({itlb_entry_asid_q[macro * 16+:16], itlb_entry_vpn_q[macro * 27+:27], itlb_entry_page_lvl_q[macro * 2+:2], itlb_entry_PPN_q[macro * 44+:44], itlb_entry_D_q[macro], itlb_entry_A_q[macro], itlb_entry_G_q[macro], itlb_entry_U_q[macro], itlb_entry_X_q[macro], itlb_entry_W_q[macro], itlb_entry_R_q[macro]})
			);
		end
	endgenerate
endmodule
