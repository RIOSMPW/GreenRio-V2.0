`ifndef LSU_FAKE_DCACHE_V
`define LSU_FAKE_DCACHE_V
`include "../params.vh"
module lsu_fake_dcache (
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

    
    output lsu_ready_o,
    output [ROB_INDEX_WIDTH - 1 : 0] rob_index_o,
    output ls_done_o,
    output exception_valid_o,
    output [EXCEPTION_CODE_WIDTH - 1 : 0] ecause_o,
    output resp_ready_o,
    output exception_valid_forward_o

    
);
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

wire resp_valid_i;
wire [LSU_LSQ_SIZE_WIDTH - 1: 0] resp_lsq_index_i;
wire [XLEN - 1 : 0]resp_data_i;

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
fake_dcache lsu_fake_dcache(
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
    .rob_index_o(resp_lsq_index_i)
);

endmodule
`endif // LSU_FAKE_DCACHE_V
