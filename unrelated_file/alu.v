`ifndef ALU_V
`define ALU_V
`include "../params.vh"
module alu (
    input clk,
    input rstn,
    input stall,
    input flush,

    input [XLEN - 1:0] input_a,
    input [XLEN - 1:0] input_b,
    input half,
    input [2:0] function_select,
    input function_modifier,

    input valid_i,
    input [PHY_REG_ADDR_WIDTH - 1 : 0] rd_addr_i,
    input [ROB_INDEX_WIDTH - 1:0] rob_index_i,

    //btb/gshare
    input jump_i,
    input branch_i,
    input [31:0] pc_i,
    input [VIRTUAL_ADDR_LEN - 1 : 0] next_pc_i,
    output jump_o,
    output branch_o,
    output [VIRTUAL_ADDR_LEN - 1 : 0] pc_o,
    output [VIRTUAL_ADDR_LEN - 1 : 0] next_pc_o,

    // csr
    input is_csr_i,
    input [CSR_ADDR_LEN - 1 : 0] csr_address_i,
    input [XLEN - 1 : 0] csr_data_i,
    input csr_read_i,
    input csr_write_i,
    input csr_readable_i,
    input csr_writeable_i,

    output csr_valid_o,
    output csr_read_o,
    output csr_write_o,
    output [XLEN - 1 : 0] csr_data_o,
    output [CSR_ADDR_LEN - 1 : 0] csr_address_o,

    // exception
    output exception_valid_o,
    output [EXCEPTION_CODE_WIDTH - 1 : 0] ecause_o,

    // 1st cycle output
    // output [XLEN - 1:0] add_result,
    output ready_o,
    output done_o,
    output [PHY_REG_ADDR_WIDTH-1:0] rd_addr_o,
    output [ROB_INDEX_WIDTH - 1:0] rob_index_o,
    // 2nd cycle output
    output reg [XLEN - 1:0] result
);

assign ready_o = ~stall;

/* verilator lint_off UNUSED */ // The first bit [32] will intentionally be ignored
wire [64:0] tmp_shifted = $signed({function_modifier ? input_a[63] : 1'b0, input_a}) >>> input_b[5:0]; //64 modified srli and srai
wire [32:0] tmp_shiftedw = $signed({function_modifier ? input_a[31] : 1'b0, input_a[31:0]}) >>> input_b[4:0]; //64 modified srliw and sraiw
/* verilator lint_on UNUSED */


/* verilator lint_off UNUSED */
reg dff_half;
reg [63:0] result_add_sub;
reg [63:0] result_sll;
reg [63:0] result_sllw;
reg [63:0] result_slt;
reg [63:0] result_xor;
reg [63:0] result_srl_sra;
reg [63:0] result_or;
reg [63:0] result_and_clr;
reg [31:0] result_srlw_sraw;
/* verilator lint_on UNUSED */

// assign add_result = result_add_sub;

reg exception_valid;
reg [EXCEPTION_CODE_WIDTH - 1 : 0] exception_code;

// btb/gshare
reg jump;
reg branch;
reg [VIRTUAL_ADDR_LEN - 1 : 0] pc;
reg [VIRTUAL_ADDR_LEN - 1 : 0] next_pc;

// csr
reg [XLEN - 1 : 0] csr_wb_data;
reg csr_valid;
reg csr_read;
reg csr_write;
reg [CSR_ADDR_LEN - 1 : 0] csr_address;
 
// csr
wire csr_exception = is_csr_i & ((csr_read_i ^ csr_readable_i) || (csr_write_i ^ csr_writeable_i));

reg [2:0] old_function;
reg [PHY_REG_ADDR_WIDTH - 1 : 0] rd_addr;
reg [ROB_INDEX_WIDTH - 1 : 0] rob_index;
reg alu_valid;

assign done_o = alu_valid;
assign rd_addr_o = rd_addr;
assign rob_index_o = rob_index;
assign exception_valid_o = exception_valid;
assign ecause_o = exception_code;
// pc
assign pc_o = pc;
assign jump_o = jump;
assign branch_o = branch;
assign next_pc_o = next_pc;
// csr
assign csr_data_o = csr_wb_data;
assign csr_valid_o = csr_valid;
assign csr_read_o = csr_read;
assign csr_write_o = csr_write;
assign csr_address_o = csr_address;

always @(posedge clk) begin
    // $display("nxt pc: %h", next_pc);
    if(rstn | flush) begin
        old_function <= '0;
        result_add_sub <= '0;
        result_sll <= '0; //64 modified slli
        result_sllw <= '0; //64 modified slliw
        result_slt <= '0;
        result_xor <= '0;
        result_srl_sra <= '0;
        result_srlw_sraw <= '0; //64 modified srliw and sraiw
        result_or <= '0;
        result_and_clr <= '0;
        alu_valid <= '0;
        rd_addr <= '0;
        rob_index <= '0;
        exception_valid <= '0;
        exception_code <= '0;
        csr_wb_data <= '0;
        csr_valid <= '0;
        csr_read <= '0;
        csr_write <= '0;
        csr_address <= '0;
        jump <= '0;
        branch <= '0;
        pc <= '0;
        next_pc <= '0;
        dff_half <= '0;
    end
    else begin
        if(~stall) begin         
            // $display("is_csr_i: %h", is_csr_i);
            // $display("csr_valid: %h", csr_valid);
            // $display("csr_write_i: %h", csr_write_i);
            old_function <= function_select;
            result_add_sub <= input_a + (function_modifier ? -input_b : input_b);
            result_sll <= input_a << input_b[5:0]; //64 modified slli
            result_sllw <= input_a << input_b[4:0]; //64 modified slliw
            result_slt <= {
                {63{1'b0}},
                (
                    $signed({function_select[0] ? 1'b0 : input_a[63], input_a})
                    < $signed({function_select[0] ? 1'b0 : input_b[63], input_b})
                )
            }; 
            result_xor <= input_a ^ input_b;
            result_srl_sra <= tmp_shifted[63:0];

            result_srlw_sraw <= tmp_shiftedw[31:0]; //64 modified srliw and sraiw

            result_or <= input_a | input_b;
            result_and_clr <= (function_modifier ? ~input_a : input_a) & input_b;
            alu_valid <= !flush & valid_i;
            rd_addr <= rd_addr_i;
            rob_index <= rob_index_i;
            exception_valid <= csr_exception & alu_valid;
            exception_code <= csr_exception ? 2 : 0;
            // btb/gshare
            jump <= jump_i & valid_i;
            branch <= branch_i & valid_i;
            pc <= pc_i;
            next_pc <= next_pc_i;
            // csr
            csr_valid <=  is_csr_i & valid_i;
            csr_read <= csr_read_i;
            csr_write <= csr_write_i;
            csr_address <= csr_address_i;
            csr_wb_data <= csr_data_i;
            dff_half <= half;
        end
    end
    
end

always @(*) begin
    case (old_function)
        ALU_ADD_SUB: if(dff_half) begin
            result = {{32{result_add_sub[31]}}, result_add_sub[31:0]}; //64 modified
        end else begin
            result = result_add_sub;
        end
        ALU_SLL:     if(dff_half) begin
            result = {{32{result_sllw[31]}}, result_sllw[31:0]};
        end else begin 
            result = result_sll;
        end
        ALU_SLT,
        ALU_SLTU:    result = result_slt; 
        ALU_XOR:     result = result_xor;
        ALU_SRL_SRA: if(dff_half) begin
            result = {{32{result_srlw_sraw[31]}}, result_srlw_sraw};
        end else begin
            result = result_srl_sra;
        end
        ALU_OR:      result = result_or;
        ALU_AND_CLR: result = result_and_clr;
    endcase
end

endmodule

`endif // ALU_V
