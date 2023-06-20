module perfect_lsu
    import riscv_pkg::*;
    import rvh_l1d_pkg::*;
    import uop_encoding_pkg::*;
    import rvh_pkg::*;
    import l1d_verif_pkg::*;
#(
    parameter LSQ_ENTRY_NUM = 8,
    parameter LSQ_ENTRY_NUM_WIDTH = 3,
    parameter RANDOM_TESTCASE_NUM = 10
)
(   // <> top
    input                                                                                               clk,
    input                                                                                               rst,
    output                                                                                              test_done,
    output                                                                                              test_succ,
    // <> d$                                                    
    // Load request                                                 
    input                                                                                               l1d_lsu_ld_req_rdy_i,
    output                                                                                              lsu_l1d_ld_req_vld_o,
    output  [     ROB_TAG_WIDTH - 1 : 0]                                                                lsu_l1d_ld_req_rob_index_o,
    output  [    PREG_TAG_WIDTH - 1 : 0]                                                                lsu_l1d_ld_req_rd_addr_o, // no need
    output  [      LDU_OP_WIDTH - 1 : 0]                                                                lsu_l1d_ld_req_opcode_o,
    output  [       L1D_INDEX_WIDTH - 1 : 0]                                                            lsu_l1d_ld_req_index_o, 
    output  [      L1D_OFFSET_WIDTH - 1 : 0]                                                            lsu_l1d_ld_req_offset_o, 
    output  [     L1D_TAG_WIDTH -1 : 0]                                                                 lsu_l1d_ld_req_vtag_o, 
    // Store request                                                    
    input                                                                                               l1d_lsu_st_req_rdy_i,
    output                                                                                              lsu_l1d_st_req_vld_o,
    output                                                                                              lsu_l1d_st_req_is_fence_o,
    output  [     ROB_TAG_WIDTH - 1 : 0]                                                                lsu_l1d_st_req_rob_index_o,
    output  [    PREG_TAG_WIDTH - 1 : 0]                                                                lsu_l1d_st_req_rd_addr_o,
    output  [      STU_OP_WIDTH - 1 : 0]                                                                lsu_l1d_st_req_opcode_o,
    output  [       PADDR_WIDTH - 1 : 0]                                                                lsu_l1d_st_req_paddr_o, 
    output  [              XLEN - 1 : 0]                                                                lsu_l1d_st_req_data_o,
    // ld replay: 1. mshr full or 2. stb partial hit                                                     
    input                                                                                               l1d_lsu_ld_replay_vld_i,
    // wb rob
    input  [LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT - 1 : 0]                                          l1d_lsu_wb_vld_i,
    input  [(LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT) * ROB_INDEX_WIDTH - 1 : 0]                      l1d_lsu_wb_rob_index_i,
    // wb prf
    input                                                                                               l1d_lsu_prf_wb_vld_i,
    input  [PREG_TAG_WIDTH - 1 : 0]                                                                     l1d_lsu_prf_wb_rd_addr_i,
    input  [XLEN - 1 : 0]                                                                               l1d_lsu_prf_wb_data_i,
    // kill                                                     
    output                                                                                              lsu_l1d_kill_req_o
);


lsu_req_t req_q[$];
lsu_req_t lsq[$];
lsu_req_t iss_q[$];

function lsu_req_t gen_random_req();
    lsu_req_t req;
    req = new();
    assert(req.randomize());
    req.init();
    // $display("%s", req.to_string());
    return req;
endfunction

function void reset();
    while($size(lsq) > 0) begin
        lsq.pop_front();
    end
    while($size(req_q) > 0) begin
        req_q.pop_front();
    end
endfunction

function void init();
    for(int i = 0; i < RANDOM_TESTCASE_NUM; i ++) begin
        req_q.push_back(gen_random_req());
    end
endfunction

wire ld_req_hsk;
wire st_req_hsk;

// Load request
assign lsu_l1d_ld_req_vld_o = ($size(lsq) > 0) && ~lsq[0].is_load_or_store;
assign lsu_l1d_ld_req_rob_index_o = ($size(lsq) > 0) ? lsq[0].rob_index : '0;
assign lsu_l1d_ld_req_rd_addr_o = ($size(lsq) > 0) ? lsq[0].rd_addr : '0; // no need
assign lsu_l1d_ld_req_opcode_o = ($size(lsq) > 0) ? lsq[0].ld_opcode : '0;
assign lsu_l1d_ld_req_index_o = ($size(lsq) > 0) ? lsq[0].index : '0;
assign lsu_l1d_ld_req_offset_o = ($size(lsq) > 0) ? lsq[0].offset : '0;
assign lsu_l1d_ld_req_vtag_o = ($size(lsq) > 0) ? lsq[0].vtag : '0;
assign ld_req_hsk = lsu_l1d_ld_req_vld_o & l1d_lsu_ld_req_rdy_i;
// Store request                                                    
assign lsu_l1d_st_req_vld_o = ($size(lsq) > 0) && lsq[0].is_load_or_store && lsq[0].ptag_vld;
assign lsu_l1d_st_req_is_fence_o = ($size(lsq) > 0) ? lsq[0].is_fence : '0;
assign lsu_l1d_st_req_rob_index_o = ($size(lsq) > 0) ? lsq[0].rob_index : '0;
assign lsu_l1d_st_req_rd_addr_o = ($size(lsq) > 0) ? lsq[0].rd_addr : '0;
assign lsu_l1d_st_req_opcode_o = ($size(lsq) > 0) ? lsq[0].st_opcode : '0;
assign lsu_l1d_st_req_paddr_o = ($size(lsq) > 0) ? {lsq[0].ptag, lsq[0].index, lsq[0].offset} : '0;
assign lsu_l1d_st_req_data_o = ($size(lsq) > 0) ? lsq[0].data : '0;
assign st_req_hsk = lsu_l1d_st_req_vld_o & l1d_lsu_st_req_rdy_i;

always @(posedge clk) begin
    if(rst) begin
        while($size(lsq) > 0) begin
            lsq.pop_front();
        end
    end
    else begin
        // req enque
        if($size(lsq) < LSQ_ENTRY_NUM) begin
            lsq.push_back(req_q.pop_front());
        end
        // req sent
        if(ld_req_hsk || st_req_hsk) begin
            iss_q.push_back(lsq.pop_front());
        end
        // handle prf wb
        if(l1d_lsu_prf_wb_vld_i) begin
            bit flag = 0;
            for(int i = 0; i < $size(lsq); i ++) begin
                if(lsq[i].rd_addr == l1d_lsu_prf_wb_rd_addr_i) begin
                    flag = 1;
                    lsq[i].data = l1d_lsu_prf_wb_data_i;
                end
            end
            prf_wb_a: assert(flag == 1)
            else $error("prf wb rf address is not avaible in iss_q");
        end
        // handle comm wb
        for(int i = 0; i < LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT; i ++) begin
            if(l1d_lsu_wb_vld_i[i]) begin

            end
        end
    end 
end

endmodule