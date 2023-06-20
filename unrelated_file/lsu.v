`ifndef LSU_V
`define LSU_V
`include "../params.vh"
module lsu (
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
    output [ROB_INDEX_WIDTH - 1 : 0] ROB_index_o,
    output ls_done_o,
    output lsu_ready_o,

    output exception_valid_o,
    output [EXCEPTION_CODE_WIDTH - 1 : 0] ecause_o,
    // <> fu
    output exception_valid_forward_o,
    // lsu <> dcache
    output req_valid_o,
    output req_opcode_o, // 0 for load, 1 for store
    output [1:0] req_size_o, 
    output [VIRTUAL_ADDR_LEN - 1 : 0] req_addr_o,
    output [XLEN - 1 : 0] req_data_o,
    input req_ready_i,
    input resp_valid_i,
    input [XLEN - 1 : 0]resp_data_i,
    output resp_ready_o
);
    //debug 
    `ifdef LSU_SELFCHECK
    always @(posedge clk) begin
        $display("");
        $display("");
        $display("rs1_data_i: %h", rs1_data_i);
        $display("rs2_data_i: %h", rs2_data_i);
        $display("valid_i: %h", valid_i);
        $display("rob_index_i: %h", rob_index_i);
        $display("rd_addr_i: %h", rd_addr_i);
        $display("imm_i: %h", imm_i);
        $display("req_ready_i: %h", req_ready_i);
        $display("resp_valid_i: %h", resp_valid_i);
        $display("resp_data_i: %h", resp_data_i);
        $display("");

        $display("load_data_valid_o: %h", load_data_valid_o);
        $display("load_data_o: %h", load_data_o);
        $display("rd_addr_o: %h", rd_addr_o);
        $display("ROB_index_o: %h", ROB_index_o);
        $display("ls_done_o: %h", ls_done_o);
        $display("lsu_ready_o: %h", lsu_ready_o);
        $display("req_valid_o: %h", req_valid_o);
        $display("req_addr_o: %h", req_addr_o);
        $display("exception_valid_o: %h", exception_valid_o);
        $display("ecause_o: %h", ecause_o);
        $display("");
    end
    `endif //LSU_SELFCHECK


    // S1 


    reg [ROB_INDEX_WIDTH - 1 : 0] s1_ROB_index; 
    reg [PHY_REG_ADDR_WIDTH - 1 : 0] s1_rd_addr;
    reg [XLEN - 1 : 0] s1_rs1_data;
    reg [XLEN - 1 : 0] s1_rs2_data;
    reg [XLEN - 1 : 0] s1_imm;
    reg s1_opcode;
    reg [1:0] s1_size;
    reg s1_load_unsign;
    reg s1_valid;

    wire [VIRTUAL_ADDR_LEN - 1 : 0] s1_address;
    wire [EXCEPTION_CODE_WIDTH - 1 : 0] s1_exception_code;
    wire s1_exception_valid;

    assign exception_valid_forward_o = s1_exception_valid;

    agu lsu_agu(
        .base_i(s1_rs1_data),
        .offset_i(s1_imm),
        .addr_o(s1_address)
    );
    ac lsu_ac(
        .valid_i(s1_valid),
        .rd_addr_i(s1_rd_addr),
        .opcode_i(s1_opcode),
        .size_i(s1_size),
        .addr_i(s1_address),

        .exception_valid_o(s1_exception_valid),
        .ecause_o(s1_exception_code)
    );

    always @(posedge clk) begin

        `ifdef LSU_SELFCHECK
        $display("s1_ROB_index: %h", s1_ROB_index);
        $display("s1_rd_addr: %h", s1_rd_addr);
        $display("s1_rs1_data: %h", s1_rs1_data);
        $display("s1_rs2_data: %h", s1_rs2_data);
        $display("s1_imm: %h", s1_imm);
        $display("s1_opcode: %h", s1_opcode);
        $display("s1_valid: %h", s1_valid);
        $display("");
        `endif // LSU_SELFCHECK

        if(~rstn | flush) begin
            s1_ROB_index <= '0;
            s1_rd_addr <= '0;
            s1_rs1_data <= '0;
            s1_rs2_data <= '0;
            s1_imm <= '0;
            s1_opcode <= '0;
            s1_size <= '0;
            s1_load_unsign <= '0;
            s1_valid <= '0;
        end
        else begin
            if(~stall && lsu_ready_o) begin 
                s1_valid <= valid_i;
            end
            else begin //此时lsu内部的ls并没有完成，valid维持，
                s1_valid <= s1_valid;
            end
            if(~stall & valid_i & lsu_ready_o) begin //? 是否需要valid_i?
                s1_ROB_index <= rob_index_i;
                s1_rd_addr <= rd_addr_i;
                s1_rs1_data <= rs1_data_i;
                s1_rs2_data <= rs2_data_i;
                s1_imm <= imm_i;
                s1_opcode <= opcode_i;
                s1_size <= size_i;
                s1_load_unsign <= ~load_sign_i;
            end
            else begin
                s1_ROB_index <= s1_ROB_index;
                s1_rd_addr <= s1_rd_addr;
                s1_rs1_data <= s1_rs1_data;
                s1_rs2_data <= s1_rs2_data;
                s1_imm <= s1_imm;
                s1_opcode <= s1_opcode;
                s1_size <= s1_size;
                s1_load_unsign <= s1_load_unsign;
            end
            
        end
    end 


    // S2 


    reg [VIRTUAL_ADDR_LEN - 1 : 0] s2_address;
    reg [ROB_INDEX_WIDTH - 1 : 0] s2_ROB_index; 
    reg [XLEN - 1 : 0] s2_rs2_data;
    reg s2_opcode;
    reg [1:0] s2_size;
    reg s2_load_sign;
    reg s2_valid;
    reg [PHY_REG_ADDR_WIDTH - 1 : 0] s2_rd_addr;
    reg [EXCEPTION_CODE_WIDTH - 1 : 0] s2_exception_code;
    reg s2_exception_valid;

    // wire s2_lsu_ready;
    // assign lsu_ready_o = s2_lsu_ready & ~s1_exception_valid;

    assign ROB_index_o = s2_ROB_index;
    assign rd_addr_o = s2_rd_addr;
    assign ecause_o = s2_exception_code;
    assign exception_valid_o = s2_exception_valid;

    cu lsu_cu(
        .clk(clk),
        .rstn(rstn),
        // <> s2 reg
        .opcode_i(s2_opcode),
        .size_i(s2_size),
        .addr_i(s2_address),
        .store_data_i(s2_rs2_data),
        .valid_i(s2_valid),
        .exception_valid_i(s2_exception_valid),
        // <> dcache
        .req_valid_o(req_valid_o),
        .req_addr_o(req_addr_o),
        .req_data_o(req_data_o),
        .req_ready_i(req_ready_i),
        .req_opcode_o(req_opcode_o),
        .req_size_o(req_size_o),

        .resp_valid_i(resp_valid_i),
        .resp_data_i(resp_data_i),
        .resp_ready_o(resp_ready_o),
        // <> PRF
        .load_data_valid_o(load_data_valid_o),
        .load_data_o(load_data_o),
        // <> ROB
        .ls_done_o(ls_done_o),
        .lsu_ready_o(lsu_ready_o)
    );

    always @(posedge clk) begin
        $display("s1_address: %h", s1_address);
        $display("s1_size: %h", s1_size);
        // $display("s1_exception_valid: %h", s1_exception_valid);
        // $display("s2_exception_valid: %h", s2_exception_valid);
        `ifdef LSU_SELFCHECK
        $display("s2_address: %h", s2_address);
        $display("s2_ROB_index: %h", s2_ROB_index);
        $display("s2_rd_addr: %h", s2_rd_addr);
        $display("s2_rs2_data: %h", s2_rs2_data);
        $display("s2_opcode: %h", s2_opcode);
        $display("s2_valid: %h", s2_valid);
        $display("");
        `endif // LSU_SELFCHECK
        if(~rstn | flush) begin
            s1_ROB_index <= '0;
            s1_rs2_data <= '0;
            s1_opcode <= '0;
            s1_size <= '0;
            s1_load_unsign <= '0;
            s1_valid <= '0;
            s2_address <= '0;
            s2_rd_addr <= '0;
            s2_exception_code <= '0;
            s2_exception_valid <= '0;
        end
        else begin
            if(flush) begin
                s1_valid <= '0;
            end 
            else if(~stall && lsu_ready_o) begin 
                s2_valid <= s1_valid;
            end
            else begin //此时lsu内部的ls并没有完成，valid维持，
                s2_valid <= s2_valid;
            end
            if(~stall & s1_valid & lsu_ready_o) begin //? 是否需要valid_i?
                s2_ROB_index <= s1_ROB_index;
                s2_rs2_data <= s1_rs2_data;
                s2_opcode <= s1_opcode;
                s2_size <= s1_size;
                s2_load_sign <= s1_load_unsign;
                s2_address <= s1_address;
                s2_rd_addr <= s1_rd_addr;
                s2_exception_code <= s1_exception_code;
                s2_exception_valid <= s1_exception_valid;
            end
            else begin
                s2_ROB_index <= s2_ROB_index;
                s2_rs2_data <= s2_rs2_data;
                s2_opcode <= s2_opcode;
                s2_size <= s2_size;
                s2_load_sign <= s2_load_sign;
                s2_address <= s2_address;
                s2_rd_addr <= s2_rd_addr;
                s2_exception_code <= s2_exception_code;
                s2_exception_valid <= s2_exception_valid;
            end
            
        end
    end



endmodule
`endif // LSU_V
