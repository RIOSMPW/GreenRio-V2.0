`ifndef VCS
`include "../params.vh"
`endif // VCS

module rvh_mmu  (
    
    // priv lvl
    input [1:0] priv_lvl_i,
    // PMP Configuration Port
    input pmp_cfg_set_vld_i,
    input [PMPCFG_ID_WIDTH-1:0] pmp_cfg_set_addr_i,
    input [63:0] pmp_cfg_set_payload_i,
    output [63:0] pmp_cfg_origin_payload_o,
    input pmp_addr_set_vld_i,
    input [PMPADDR_ID_WIDTH-1:0] pmp_addr_set_addr_i,
    input [63:0] pmp_addr_set_payload_i,
    output [63:0] pmp_addr_origin_payload_o,
    // stap
    input [3:0] satp_mode_i,
    input [PPN_WIDTH-1:0] satp_ppn_i,


    // DTLB Miss -> To Next Level Request
    input dtlb_miss_req_vld_i,
    input [TRANS_ID_WIDTH-1:0] dtlb_miss_req_trans_id_i,
    input [ASID_WIDTH-1:0] dtlb_miss_req_asid_i,
    input [VPN_WIDTH-1:0] dtlb_miss_req_vpn_i,
    input [1:0] dtlb_miss_req_access_type_i,
    output dtlb_miss_req_rdy_o,
    // DTLB Miss -> From Next Level Response
    output dtlb_miss_resp_vld_o,
    output [TRANS_ID_WIDTH-1:0] dtlb_miss_resp_trans_id_o,
    output [ASID_WIDTH-1:0] dtlb_miss_resp_asid_o,
    output [PTE_WIDTH-1:0] dtlb_miss_resp_pte_o,
    output [PAGE_LVL_WIDTH-1:0] dtlb_miss_resp_page_lvl_o,
    output [VPN_WIDTH-1:0] dtlb_miss_resp_vpn_o,
    output [1:0] dtlb_miss_resp_access_type_o,
    output dtlb_miss_resp_access_fault_o,
    output dtlb_miss_resp_page_fault_o,
    
    // ITLB Miss -> To Next Level Request
    input itlb_miss_req_vld_i,
    input [TRANS_ID_WIDTH-1:0] itlb_miss_req_trans_id_i,
    input [ASID_WIDTH-1:0] itlb_miss_req_asid_i,
    input [VPN_WIDTH-1:0] itlb_miss_req_vpn_i,
    input [1:0] itlb_miss_req_access_type_i,
    output itlb_miss_req_rdy_o,
    // ITLB Miss -> From Next Level Response
    output itlb_miss_resp_vld_o,
    output [TRANS_ID_WIDTH-1:0] itlb_miss_resp_trans_id_o,
    output [ASID_WIDTH-1:0] itlb_miss_resp_asid_o,
    output [PTE_WIDTH-1:0] itlb_miss_resp_pte_o,
    output [PAGE_LVL_WIDTH-1:0] itlb_miss_resp_page_lvl_o,
    output [VPN_WIDTH-1:0] itlb_miss_resp_vpn_o,
    output [1:0] itlb_miss_resp_access_type_o,
    output itlb_miss_resp_access_fault_o,
    output itlb_miss_resp_page_fault_o,


    // MMU -> L1D
    // ptw walk request port
    output ptw_walk_req_vld_o,
    output [PTW_ID_WIDTH-1:0] ptw_walk_req_id_o,
    output [PADDR_WIDTH-1:0] ptw_walk_req_addr_o,
    input ptw_walk_req_rdy_i,


    // L1D -> MMU
    // ptw walk response port
    input ptw_walk_resp_vld_i,
    // input [PTW_ID_WIDTH-1:0] ptw_walk_resp_id_i,
    input [PTE_WIDTH-1:0] ptw_walk_resp_pte_i,
    output ptw_walk_resp_rdy_o,


    // tlb shoot down
    input tlb_flush_vld_i,
    input tlb_flush_use_asid_i,
    input tlb_flush_use_vpn_i,
    input [VPN_WIDTH-1:0] tlb_flush_vpn_i,
    input [ASID_WIDTH-1:0] tlb_flush_asid_i,
    output tlb_flush_grant_o,
    input clk,
    input rstn
);

  // Access type
  localparam PMP_ACCESS_TYPE_R = 0;
  localparam PMP_ACCESS_TYPE_W = 1;
  localparam PMP_ACCESS_TYPE_X = 2;

  // Request Arbitiration
  wire dtlb_miss_request;
  wire itlb_miss_request;
  wire miss_port_conflict;
  wire sel_dtlb_req;
  wire sel_itlb_req;
  wire rr_arbiter_d;
  reg rr_arbiter_q;

  wire translate_req_vld;
  wire [ASID_WIDTH-1:0] translate_req_asid;
  wire [TRANS_ID_WIDTH-1:0] translate_req_trans_id;
  wire [VPN_WIDTH-1:0] translate_req_vpn;
  wire [1:0] translate_req_access_type;
  wire translate_req_rdy;

  // translate response port
  wire translate_resp_vld;
  wire [ASID_WIDTH-1:0] translate_resp_asid;
  wire [PTE_WIDTH-1:0] translate_resp_pte;
  wire [PAGE_LVL_WIDTH-1:0] translate_resp_page_lvl;
  wire [TRANS_ID_WIDTH-1:0] translate_resp_trans_id;
  wire [VPN_WIDTH-1:0] translate_resp_vpn;
  wire [1:0] translate_resp_access_type;
  wire translate_resp_access_fault;
  wire translate_resp_page_fault;

  // DOESN'T EXIST STLB. TIE TO ZERO
  assign tlb_flush_grant_o = 1'b0;

  assign dtlb_miss_request = dtlb_miss_req_vld_i;
  assign itlb_miss_request = itlb_miss_req_vld_i;
  assign miss_port_conflict = dtlb_miss_request & itlb_miss_request;
  assign sel_dtlb_req = (dtlb_miss_request & ~miss_port_conflict) | (miss_port_conflict & ~rr_arbiter_q);
  assign sel_itlb_req = (itlb_miss_request & ~miss_port_conflict) | (miss_port_conflict & rr_arbiter_q);
  assign rr_arbiter_d = ~rr_arbiter_q;
  assign dtlb_miss_req_rdy_o = sel_dtlb_req & translate_req_rdy;
  assign itlb_miss_req_rdy_o = sel_itlb_req & translate_req_rdy;

  assign translate_req_vld = dtlb_miss_request | itlb_miss_request;
  assign translate_req_trans_id = ({TRANS_ID_WIDTH{sel_dtlb_req}} & dtlb_miss_req_trans_id_i) |
        ({TRANS_ID_WIDTH{sel_itlb_req}} & itlb_miss_req_trans_id_i);
  assign translate_req_vpn = ({VPN_WIDTH{sel_dtlb_req}} & dtlb_miss_req_vpn_i) |
        ({VPN_WIDTH{sel_itlb_req}} & itlb_miss_req_vpn_i);
  assign translate_req_access_type = ({2{sel_dtlb_req}} & dtlb_miss_req_access_type_i) |
        ({2{sel_itlb_req}} & itlb_miss_req_access_type_i);
  assign translate_req_asid = ({ASID_WIDTH{sel_dtlb_req}} & dtlb_miss_req_asid_i) |
        ({ASID_WIDTH{sel_itlb_req}} & itlb_miss_req_asid_i);

  // TLB Miss Response 
  assign dtlb_miss_resp_vld_o = translate_resp_vld & ((translate_resp_access_type == PMP_ACCESS_TYPE_R) | (translate_resp_access_type == PMP_ACCESS_TYPE_W)) ;
  assign dtlb_miss_resp_asid_o = translate_resp_asid;
  assign dtlb_miss_resp_trans_id_o = translate_resp_trans_id;
  assign dtlb_miss_resp_pte_o = translate_resp_pte;
  assign dtlb_miss_resp_page_lvl_o = translate_resp_page_lvl;
  assign dtlb_miss_resp_vpn_o = translate_resp_vpn;
  assign dtlb_miss_resp_access_type_o = translate_resp_access_type;
  assign dtlb_miss_resp_access_fault_o = translate_resp_access_fault;
  assign dtlb_miss_resp_page_fault_o = translate_resp_page_fault;
  assign itlb_miss_resp_vld_o = translate_resp_vld & (translate_resp_access_type == PMP_ACCESS_TYPE_X) ;
  assign itlb_miss_resp_trans_id_o = translate_resp_trans_id;
  assign itlb_miss_resp_asid_o = translate_resp_asid;
  assign itlb_miss_resp_pte_o = translate_resp_pte;
  assign itlb_miss_resp_page_lvl_o = translate_resp_page_lvl;
  assign itlb_miss_resp_vpn_o = translate_resp_vpn;
  assign itlb_miss_resp_access_type_o = translate_resp_access_type;
  assign itlb_miss_resp_access_fault_o = translate_resp_access_fault;
  assign itlb_miss_resp_page_fault_o = translate_resp_page_fault;

  // Reserved
  assign ptw_walk_req_id_o = {PTW_ID_WIDTH{1'b0}};

  rvh_ptw u_rvh_ptw (
      .priv_lvl_i(priv_lvl_i),
      .pmp_cfg_set_vld_i(pmp_cfg_set_vld_i),
      .pmp_cfg_set_addr_i(pmp_cfg_set_addr_i),
      .pmp_cfg_set_payload_i(pmp_cfg_set_payload_i),
      .pmp_cfg_origin_payload_o(pmp_cfg_origin_payload_o),
      .pmp_addr_set_vld_i(pmp_addr_set_vld_i),
      .pmp_addr_set_addr_i(pmp_addr_set_addr_i),
      .pmp_addr_set_payload_i(pmp_addr_set_payload_i),
      .pmp_addr_origin_payload_o(pmp_addr_origin_payload_o),
      .satp_mode_i(satp_mode_i),
      .satp_ppn_i(satp_ppn_i),
      .translate_req_vld_i(translate_req_vld),
      .translate_req_asid_i(translate_req_asid),
      .translate_req_vpn_i(translate_req_vpn),
      .translate_req_trans_id_i(translate_req_trans_id),
      .translate_req_access_type_i(translate_req_access_type),
      .translate_req_rdy_o(translate_req_rdy),
      .translate_resp_vld_o(translate_resp_vld),
      .translate_resp_asid_o(translate_resp_asid),
      .translate_resp_pte_o(translate_resp_pte),
      .translate_resp_page_lvl_o(translate_resp_page_lvl),
      .translate_resp_trans_id_o(translate_resp_trans_id),
      .translate_resp_vpn_o(translate_resp_vpn),
      .translate_resp_access_type_o(translate_resp_access_type),
      .translate_resp_access_fault_o(translate_resp_access_fault),
      .translate_resp_page_fault_o(translate_resp_page_fault),
      .ptw_walk_req_vld_o(ptw_walk_req_vld_o),
      .ptw_walk_req_addr_o(ptw_walk_req_addr_o),
      .ptw_walk_req_rdy_i(ptw_walk_req_rdy_i),
      .ptw_walk_resp_vld_i(ptw_walk_resp_vld_i),
      .ptw_walk_resp_pte_i(ptw_walk_resp_pte_i),
      .ptw_walk_resp_rdy_o(ptw_walk_resp_rdy_o),
      .clk(clk),
      .rstn(rstn)
  );



  DFFRE #(
      .Width(1)
  ) u_miss_req_port_arbiter_DFFRE (
      .CLK(clk),
      .RSTN(rstn),
      .DRST(1'b0),
      .EN(miss_port_conflict),
      .D(rr_arbiter_d),
      .Q(rr_arbiter_q)
  );

endmodule
