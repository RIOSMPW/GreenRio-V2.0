module rvh_mmu_mshr (
	tlb_miss_req_vld_i,
	tlb_miss_req_access_type_i,
	tlb_miss_req_asid_i,
	tlb_miss_req_vpn_i,
	tlb_miss_req_grant_vld_o,
	tlb_miss_req_grant_trans_id_o,
	tlb_miss_req_grant_asid_o,
	tlb_miss_req_grant_vpn_o,
	tlb_miss_req_grant_access_type_o,
	tlb_miss_req_grant_rdy_i,
	tlb_miss_response_vld_i,
	tlb_miss_respone_trans_id_i,
	exist_inflight_req_o,
	clk,
	rstn
);
	localparam TRANSLATE_WIDTH = 1;
	parameter ALLOC_WIDTH = TRANSLATE_WIDTH;
	localparam DTLB_MSHR_COUNT = 4;
	parameter ENTRY_COUNT = DTLB_MSHR_COUNT;
	input [ALLOC_WIDTH - 1:0] tlb_miss_req_vld_i;
	input [(ALLOC_WIDTH * 2) - 1:0] tlb_miss_req_access_type_i;
	localparam ASID_WIDTH = 16;
	input [(ALLOC_WIDTH * 16) - 1:0] tlb_miss_req_asid_i;
	localparam ADDR_INDEX_LEN = 6;
	localparam ADDR_OFFSET_LEN = 6;
	localparam VIRTUAL_ADDR_LEN = 39;
	localparam VPN_WIDTH = 27;
	input [(ALLOC_WIDTH * 27) - 1:0] tlb_miss_req_vpn_i;
	output wire tlb_miss_req_grant_vld_o;
	localparam TRANS_ID_WIDTH = 3;
	output wire [2:0] tlb_miss_req_grant_trans_id_o;
	output wire [15:0] tlb_miss_req_grant_asid_o;
	output wire [26:0] tlb_miss_req_grant_vpn_o;
	output wire [1:0] tlb_miss_req_grant_access_type_o;
	input tlb_miss_req_grant_rdy_i;
	input tlb_miss_response_vld_i;
	input [2:0] tlb_miss_respone_trans_id_i;
	output wire exist_inflight_req_o;
	input clk;
	input rstn;
	localparam MSHR_ENTRY_ID_WIDTH = (ENTRY_COUNT > 1 ? $clog2(ENTRY_COUNT) : 1);
	genvar macro;
	wire mshr_entry_vld_clk_en;
	wire [ENTRY_COUNT - 1:0] mshr_entry_payload_clk_en;
	wire [ENTRY_COUNT - 1:0] mshr_entry_vld_d;
	wire [(ENTRY_COUNT * 27) - 1:0] mshr_entry_vpn_d;
	reg [ENTRY_COUNT - 1:0] mshr_entry_vld_q;
	reg [(ENTRY_COUNT * 27) - 1:0] mshr_entry_vpn_q;
	wire [(ALLOC_WIDTH * 45) - 1:0] tlb_miss_req_enq_payload;
	wire tlb_miss_req_grant_vld;
	wire [1:0] tlb_miss_req_grant_access_type;
	wire [26:0] tlb_miss_req_grant_vpn;
	wire [15:0] tlb_miss_req_grant_asid;
	wire tlb_miss_requset_waived;
	wire [ENTRY_COUNT - 1:0] tlb_miss_request_waive_mask;
	wire mshr_rdy;
	wire [ENTRY_COUNT - 1:0] mshr_alloc_mask;
	wire [MSHR_ENTRY_ID_WIDTH - 1:0] mshr_alloc_trans_id;
	wire tlb_miss_req_grant_fire;
	wire [ENTRY_COUNT - 1:0] mshr_dealloc_mask;
	assign exist_inflight_req_o = (|tlb_miss_req_vld_i | |mshr_entry_vld_q) | tlb_miss_req_grant_vld;
	generate
		for (macro = 0; macro < ALLOC_WIDTH; macro = macro + 1) begin : gen_tlb_miss_request_enq_payload
			assign tlb_miss_req_enq_payload[macro * 45+:45] = {tlb_miss_req_access_type_i[macro * 2+:2], tlb_miss_req_vpn_i[macro * 27+:27], tlb_miss_req_asid_i[macro * 16+:16]};
		end
		for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_request_waiver
			assign tlb_miss_request_waive_mask[macro] = mshr_entry_vld_q[macro] & (mshr_entry_vpn_q[macro * 27+:27] == tlb_miss_req_grant_vpn);
		end
	endgenerate
	assign tlb_miss_requset_waived = |tlb_miss_request_waive_mask;
	assign tlb_miss_req_grant_vld_o = (tlb_miss_req_grant_vld & mshr_rdy) & ~tlb_miss_requset_waived;
	assign tlb_miss_req_grant_trans_id_o = {{TRANS_ID_WIDTH - MSHR_ENTRY_ID_WIDTH {1'b0}}, mshr_alloc_trans_id};
	assign tlb_miss_req_grant_asid_o = tlb_miss_req_grant_asid;
	assign tlb_miss_req_grant_access_type_o = tlb_miss_req_grant_access_type;
	assign tlb_miss_req_grant_vpn_o = tlb_miss_req_grant_vpn;
	assign mshr_rdy = |(~mshr_entry_vld_q);
	assign mshr_alloc_mask = ~mshr_entry_vld_q & ~(~mshr_entry_vld_q - 1'b1);
	assign tlb_miss_req_grant_fire = tlb_miss_req_grant_vld_o & tlb_miss_req_grant_rdy_i;
	assign mshr_dealloc_mask = 1'sb1 << tlb_miss_respone_trans_id_i[MSHR_ENTRY_ID_WIDTH - 1:0];
	assign mshr_entry_vld_clk_en = tlb_miss_req_grant_fire | tlb_miss_response_vld_i;
	assign mshr_entry_vld_d = (~mshr_entry_vld_q & ({ENTRY_COUNT {tlb_miss_req_grant_fire}} & mshr_alloc_mask)) | (mshr_entry_vld_q & ~({ENTRY_COUNT {tlb_miss_response_vld_i}} & mshr_dealloc_mask));
	assign mshr_entry_payload_clk_en = mshr_entry_vld_clk_en;
	generate
		for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_mshr_entry_vpn_d
			assign mshr_entry_vpn_d[macro * 27+:27] = (mshr_entry_vld_d[macro] ? (mshr_alloc_mask[macro] ? tlb_miss_req_grant_vpn : mshr_entry_vpn_q[macro * 27+:27]) : {VPN_WIDTH {1'b0}});
		end
	endgenerate
	MultiPortStreamFIFO #(
		.Depth(ALLOC_WIDTH * 2),
		.DataWidth(45),
		.EnqWidth(ALLOC_WIDTH),
		.DeqWidth(1),
		.TakenAll(0)
	) u_tlb_miss_grant_buffer(
		.enq_vld_i(tlb_miss_req_vld_i & ~tlb_miss_response_vld_i),
		.enq_payload_i(tlb_miss_req_enq_payload),
		.enq_rdy_o(),
		.deq_vld_o(tlb_miss_req_grant_vld),
		.deq_payload_o({tlb_miss_req_grant_access_type, tlb_miss_req_grant_vpn, tlb_miss_req_grant_asid}),
		.deq_rdy_i(tlb_miss_req_grant_fire | tlb_miss_requset_waived),
		.flush_i(1'b0),
		.clk(clk),
		.rstn(rstn)
	);
	OH2UInt #(.InputWidth(ENTRY_COUNT)) u_OH2UInt(
		.oh_i(mshr_alloc_mask),
		.result_o(mshr_alloc_trans_id)
	);
	DFFRE #(.Width(ENTRY_COUNT)) u_mshr_entry_vld_DFFRE(
		.CLK(clk),
		.RSTN(rstn),
		.EN(mshr_entry_vld_clk_en),
		.DRST({ENTRY_COUNT {1'b0}}),
		.D(mshr_entry_vld_d),
		.Q(mshr_entry_vld_q)
	);
	generate
		for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_mshr_entry_payload
			DFFE #(.Width(VPN_WIDTH)) u_mshr_entry_payload_DFFE(
				.CLK(clk),
				.EN(mshr_entry_payload_clk_en[macro]),
				.D(mshr_entry_vpn_d[macro * 27+:27]),
				.Q(mshr_entry_vpn_q[macro * 27+:27])
			);
		end
	endgenerate
endmodule
