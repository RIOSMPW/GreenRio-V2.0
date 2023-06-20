module cmp (
    input clk,
    input rstn,
    input stall,
    input flush,

    input [63:0] input_a,
    input [63:0] input_b,
    input [2:0] function_select,

    input [ROB_INDEX_WIDTH - 1:0] rob_index_i,
    input valid_i,

    output done_o,
    output ready_o,
    output [ROB_INDEX_WIDTH - 1:0] rob_index_o,
    output result
);

reg quasi_result;
reg negate;
reg valid;
reg [ROB_INDEX_WIDTH - 1:0] rob_index;

wire usign = function_select[1];
wire less = function_select[2];

wire is_equal = (input_a == input_b);
wire is_less = ($signed({usign ? 1'b0 : input_a[63], input_a}) < $signed({usign ? 1'b0 : input_b[63], input_b}));

assign ready_o = ~stall;
assign done_o = valid;
assign rob_index_o = rob_index;
assign result = negate ? !quasi_result : quasi_result;

always @(posedge clk) begin
    if(rstn | flush) begin
        negate <= '0;
        quasi_result <= '0;
        valid <= '0;
        rob_index <= '0;
    end
    else begin
        if(~stall) begin
            negate <= function_select[0];
            quasi_result <= less ? is_less : is_equal;
            valid <= valid_i;
            if(flush) begin
                valid <= '0;
            end
            rob_index <= rob_index_i;
        end
        else begin
            negate <= negate;
            quasi_result <= quasi_result;
            valid <= valid;
            if(flush) begin
                valid <= '0;
            end
            rob_index <= rob_index;
        end
    end
end





endmodule
