`ifndef FETCH_V
`define FETCH_V
//`include "../params.vh"
`ifndef SYNTHESIS
//`include "../params.vh"
`endif
module fetch (
    // for itlb
    /* for test
    input [1:0] priv_lvl_i,
    input mstatus_mxr_i,
    input mstatus_sum_i,
    input [MODE_WIDTH-1:0] satp_mode_i,
    input [ASID_WIDTH-1:0] satp_asid_i,

    */
    //whole fetch
    input clk,
    input rst,
    input branch_valid_first_i, 
    input branch_valid_second_i, 

    //btb from fu
    input [PC_WIDTH-1:0] btb_req_pc_i, 
    input [PC_WIDTH-1:0] btb_predict_target_i, 

    //gshare from fu
    input [PC_WIDTH-1:0] prev_pc_first_i,
    input prev_taken_first_i,
    input [PC_WIDTH-1:0] prev_pc_second_i,
    input prev_taken_second_i,

    //instruction buffer
    // input rd_en_i,
    // first inst
    output reg [PC_WIDTH-1:0] pc_first_o,
    output reg [PC_WIDTH-1:0] next_pc_first_o,
    output reg [PC_WIDTH-1:0] predict_pc_first_o,
    output reg [31:0] instruction_first_o,
    output reg is_rv_first_o,
    output reg is_first_valid_o, 
    // second inst
    output reg [PC_WIDTH-1:0] pc_second_o,
    output reg [PC_WIDTH-1:0] next_pc_second_o,
    output reg [PC_WIDTH-1:0] predict_pc_second_o,
    output reg [31:0] instruction_second_o,
    output reg is_rv_second_o,
    output reg is_second_valid_o,

    // IF<>ID
    input single_rdy_i,
    input double_rdy_i,

    // from fu
    input [PC_WIDTH-1:0] real_branch_i,
    
    // from exception ctrl
    // input trap_i,
    // input mret_i,
    input global_wfi_i,
    input global_ret_i,
    input global_trap_i,
    input global_predict_miss_i,

    // from csr
    input [PC_WIDTH-1:0] trap_vector_i,
    input [PC_WIDTH-1:0] mret_vector_i,

    // I$ -> FETCH : resp
    input fetch_l1i_if_req_rdy_i, // i$ has recv fetch's req
    input l1i_fetch_if_resp_vld_i, // i$ fetch a valid cacheline
    input [$clog2(IFQ_DEPTH)-1:0] l1i_fetch_if_resp_if_tag_i, // notice
    input [FETCH_WIDTH-1:0] l1i_fetch_if_resp_data_i, // i$'s cacheline
    
    // FETCH -> I$ : IFETCH request
    output reg fetch_l1i_if_req_vld_o, // 1: fetch has req
    output [$clog2(IFQ_DEPTH)-1:0] fetch_l1i_if_req_if_tag_o, // notice
    output [L1I_INDEX_WIDTH-1:0] fetch_l1i_if_req_index_o,
    output [L1I_OFFSET_WIDTH-1:0] fetch_l1i_if_req_offset_o,
    output [L1I_TAG_WIDTH-1:0] fetch_l1i_if_req_vtag_o, // virtual tag

    // FETCH -> itlb: request
    input itlb_fetch_req_rdy_i,

    input itlb_fetch_miss_i,
    input itlb_fetch_hit_i,
    input itlb_fetch_resp_excp_vld_i,
    input [EXCEPTION_CAUSE_WIDTH-1:0] itlb_fetch_resp_ecause_i,
    output reg fetch_itlb_req_vld_o,

    /* for test
    output fetch_l1i_if_itlb_resp_vld_o, // 1: itlb hit, 0: itlb miss
    output [PPN_WIDTH-1:0] fetch_l1i_if_itlb_resp_ppn_o,
    output fetch_l1i_if_itlb_resp_excp_vld_o, // 1: itlb miss, 0: itlb hit
    output fetch_l1i_if_itlb_resp_hit_o, // 1: itlb hit, 0: itlb miss
    */

    //for test
    output ins_empty_o,

    // exceptions
    output reg exception_valid_first_o,
    output reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_first_o,
    output reg [XLEN-1:0] etval_first_o,
    output reg exception_valid_second_o,
    output reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_second_o,
    output reg [XLEN-1:0] etval_second_o

);

reg [PC_WIDTH-1:0] pc;
// wire fetch_l1i_if_itlb_resp_excp_vld_o = 0; // for test
// wire [EXCEPTION_CAUSE_WIDTH-1:0] ecause_itlb = 0; // for test

reg rff_icache_resp; //to match misfetch signal, make sure the next response from icache after branch should be ignore

reg [PC_WIDTH-1:0] predict_pc;
wire judge_from_gshare;
wire btb_taken;
wire [PC_WIDTH-1:0] pc_from_btb;
wire flush = global_ret_i | global_trap_i | global_predict_miss_i;

// issue: should exception from misalign be included ?
// wire exception_valid_in = pc[1:0] != 2'b00;
// wire [EXCEPTION_CAUSE_WIDTH-1:0] ecause_in = (pc[1:0] != 2'b00) ? EXCEPTION_INSTR_ADDR_MISALIGNED : 0;

wire fetch_req_vld;
wire buffer_full;
reg [PC_WIDTH-1:0] ins_pc_in;
wire [PC_WIDTH-1:0] ins_next_pc_in;
// wire [31:0] instruction_in;

reg rff_misfetch;
wire misfetch;
// wire pc_unpredict_taken;

reg [PC_WIDTH-1:0] ib_fetch_req_pc;
reg [PC_WIDTH-1:0] ib_fetch_resp_pc;
wire ins_hit;
// wire refill_i;
wire predict_pc_from_pred;

wire icache_same;

// teg gen
wire fetch_tag_wr_en                                ;
wire fetch_tag_rd_en                                ;
wire [$clog2(IFQ_DEPTH)-1:0] fetch_tag_wrdata       ;
wire [$clog2(IFQ_DEPTH)-1:0] fetch_tag_rdata        ;
wire fetch_tag_full                                 ;
wire fetch_tag_empty                                ;
wire [$clog2(IFQ_DEPTH):0] fetch_tag_num          ;
wire tag_hit                                        ;
reg [$clog2(IFQ_DEPTH)-1:0] dff_tag        ;


// FETCH -> I$ : IFETCH request
// inst buffer hit: prefetch needed; inst buffer miss: no prefetch, but fetch a line corresponding to current pc
assign fetch_l1i_if_req_offset_o = ib_fetch_req_pc[L1I_OFFSET_WIDTH-1:0];
assign fetch_l1i_if_req_index_o = {ib_fetch_req_pc[L1I_INDEX_WIDTH-1:L1I_OFFSET_WIDTH], {L1I_OFFSET_WIDTH{1'b0}}};
assign fetch_l1i_if_req_vtag_o = ib_fetch_req_pc[PC_WIDTH-1:L1I_INDEX_WIDTH];
assign predict_pc_from_pred = btb_taken && !judge_from_gshare;

//next pc 
always @(*) begin
    if (global_wfi_i) begin
        predict_pc = pc;
    end else if (global_trap_i) begin
        predict_pc = trap_vector_i;
    end else if (global_ret_i) begin
        predict_pc = mret_vector_i;
    end else if (global_predict_miss_i) begin
        predict_pc = real_branch_i;
    end else if (predict_pc_from_pred) begin //need && judge_from_gshare
        predict_pc = pc_from_btb;
    end else begin
        if (is_second_valid_o) begin
            if (is_rv_first_o && is_rv_second_o) begin
                predict_pc = pc + 8;
            end else if (is_rv_first_o || is_rv_second_o) begin
                predict_pc = pc + 6;
            end else begin
                predict_pc = pc + 4;
            end
        end else if (is_first_valid_o) begin
            if (is_rv_first_o) begin
                predict_pc = pc + 4;
            end else begin
                predict_pc = pc + 2;
            end
        end else begin
            predict_pc = pc;
        end
    end
end

// assign pc_unpredict_taken = global_trap_i | global_ret_i | branch_predict_wrong;

//pc switch
always @(posedge clk) begin
    if (rst) begin
        pc <= RESET_VECTOR;
    end else if (ins_hit || flush) begin
        pc <= predict_pc;
    end
end

assign fetch_l1i_if_req_vld_o = ~global_wfi_i & ~flush & ~rst & fetch_req_vld;
assign fetch_itlb_req_vld_o = fetch_l1i_if_req_vld_o;

// if fetch has req hosted by icache, and tlb hit, stop sending another req
// reg fsm = 1;
// flush: global_ret_i | global_trap_i | global_predict_miss_i;

// assign icache_resp_ready = !global_wfi_i && !buffer_full;

// instr_buffer_wr_en not in use?
// wire instr_buffer_wr_en = icache_resp_ready && l1i_fetch_if_resp_vld_i && (icache_resp_address == ins_pc_in) && !misfetch; // resp_address can equal both ins_next_pc_in and pc 

btb #(
    .BTB_SIZE_1(3)
) btb_u(
    .clk(clk),
    .reset(rst),
    .pc_in(pc),
    .buffer_hit(btb_taken),
    .next_pc_out(pc_from_btb),
    .is_req_pc(branch_valid_first_i),
    .req_pc(btb_req_pc_i),
    .predict_target(btb_predict_target_i)
);

gshare gshare_u(
    .clk(clk),
    .reset(rst),
    .pc(pc),
    .prev_pc_first(prev_pc_first_i),
    .prev_branch_in_first(branch_valid_first_i),
    .prev_taken_first(prev_taken_first_i),
    .prev_pc_second(prev_pc_second_i),
    .prev_branch_in_second(branch_valid_second_i),
    .prev_taken_second(prev_taken_second_i),
    .cur_pred(judge_from_gshare)
);

// reg refill_o;
reg icache_prefetch_valid_o;
reg [INS_BUFFER_SIZE_WIDTH-1:0] prefetch_line_number_o;
reg [INS_BUFFER_SIZE_WIDTH-1:0] prefetch_line_number_i;

always @(posedge clk) begin
    if (rst) begin
        // refill_o <= 0;
        icache_prefetch_valid_o <= 0;
        prefetch_line_number_o <= 0;
        ib_fetch_resp_pc <= 0;
    end else if (flush) begin
        // refill_o <= 0;
        icache_prefetch_valid_o <= 0;
        prefetch_line_number_o <= 0;
        ib_fetch_resp_pc <= 0;
    end else begin
        // refill_o <= refill_i;
        icache_prefetch_valid_o <= ins_hit;
        prefetch_line_number_o <= prefetch_line_number_i;
        ib_fetch_resp_pc <= ib_fetch_req_pc;
    end
end

assign predict_pc_first_o = pc_second_o;
assign predict_pc_second_o = predict_pc;

reg [FETCH_WIDTH-1:0] last_fetch_line;
assign icache_same = last_fetch_line == l1i_fetch_if_resp_data_i;
always @(posedge clk) begin
    if (rst || flush) begin
        last_fetch_line <= 0;
        //last_flush <= 0;
    end else if (last_fetch_line != l1i_fetch_if_resp_data_i && l1i_fetch_if_resp_vld_i) begin
        last_fetch_line <= l1i_fetch_if_resp_data_i;
    end
end

ins_buffer #(
    .OFFSET_WIDTH(L1I_OFFSET_WIDTH)
) buffer_u(
    .clk(clk),
    .reset(rst),
    .flush(flush),
    .query_pc_req_i(pc),
    .exception_valid_in(itlb_fetch_resp_excp_vld_i), // exception from itlb
    .ecause_in(itlb_fetch_resp_ecause_i),
    .ins_hit(ins_hit),
    .fetch_req_pc_o(ib_fetch_req_pc),
    .fetch_pc_resp_i(ib_fetch_resp_pc),
    .prefetch_line_number_o(prefetch_line_number_i),
    .prefetch_line_number_i(prefetch_line_number_o),
    .icache_prefetch_valid(icache_prefetch_valid_o),
    .l1i_fetch_if_resp_vld_i(l1i_fetch_if_resp_vld_i), // write ins buffer: tag_hit & resp_vld
    .icache_input_prefetch_line(l1i_fetch_if_resp_data_i), // from icache: one cacheline
    .ins_full(buffer_full),
    .ins_empty(ins_empty_o),
    .fetch_req_vld_o(fetch_req_vld),
    .single_rdy_i(single_rdy_i),
    .double_rdy_i(double_rdy_i),
    .icache_same(icache_same),
    .fetch_l1i_if_req_rdy_i(fetch_l1i_if_req_rdy_i),
    .fetch_itlb_if_req_rdy_i(itlb_fetch_req_rdy_i),
    .itlb_fetch_miss_i(itlb_fetch_miss_i),
    .pc_first_o(pc_first_o),
    .next_pc_first_o(next_pc_first_o),
    .instruction_first_o(instruction_first_o),
    .is_rv_first_o(is_rv_first_o),
    .exception_valid_first_o(exception_valid_first_o), 
    .ecause_first_o(ecause_first_o),
    .etval_first_o(etval_first_o),
    .is_first_valid_o(is_first_valid_o),
    .pc_second_o(pc_second_o),
    .next_pc_second_o(next_pc_second_o),
    .instruction_second_o(instruction_second_o),
    .is_rv_second_o(is_rv_second_o),
    .exception_valid_second_o(exception_valid_second_o),
    .ecause_second_o(ecause_second_o),
    .etval_second_o(etval_second_o),
    .is_second_valid_o(is_second_valid_o)
);

wire [PC_WIDTH-L1I_OFFSET_WIDTH-1:0] vpn_if2ic = icache_prefetch_valid_o ? ib_fetch_req_pc[PC_WIDTH-1:L1I_OFFSET_WIDTH] : pc[PC_WIDTH-1:L1I_OFFSET_WIDTH];

endmodule

`endif // FETCH_V
