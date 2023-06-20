`ifndef FAKE_DCACHE
`define FAKE_DCACHE
`include "../params.vh"

module  fake_dcache 
#(
    // parameter XLEN = 64,
    // parameter VIRTUAL_ADDR_LEN = 32,
    parameter WB_DATA_LEN = 32
)
(
    input clk,
    input rstn,
    
    //req
    input  req_valid_i,
    output req_ready_o,
    input  opcode,//0 load ,1 store 
    input [VIRTUAL_ADDR_LEN - 1 : 0] req_addr_i,
    input [2:0]  type_i,
    input [XLEN -1:0] st_data_i,
    input [1 : 0] rob_index_i,

    //resp
    input  resp_ready_i,
    output resp_valid_o,
    output [XLEN -1:0] ld_data_o,
    output [1 : 0] rob_index_o
);
  
reg [XLEN - 1 : 0] mem[FAKE_MEM_DEPTH - 1 : 0];

reg [XLEN - 1 : 0] req_que_data[FAKE_CACHE_MSHR_WIDTH - 1 : 0];
reg [LSU_LSQ_SIZE_WIDTH - 1 : 0] req_lsq_id[FAKE_CACHE_MSHR_WIDTH - 1 : 0];
reg [FAKE_CACHE_MSHR_WIDTH - 1 : 0] req_que_valid;
reg [FAKE_CACHE_DELAY_WIDTH - 1 : 0] req_que_delay[FAKE_CACHE_MSHR_WIDTH - 1 : 0];

reg [FAKE_CACHE_MSHR_WIDTH - 1 : 0] valid_pt;
reg [FAKE_CACHE_MSHR_WIDTH - 1 : 0] return_pt;

assign resp_valid_o = (req_que_delay[return_pt] == 0) & req_que_valid[return_pt];
assign ld_data_o = req_que_data[return_pt];
assign rob_index_o = req_lsq_id[return_pt];
assign req_ready_o = ~(&req_que_valid);

always @ (posedge clk) begin
    if(rstn) begin
        integer i;
        for(i = 0; i < FAKE_MEM_SIZE; i = i + 1) begin
            mem[i] <= ((i + 1) << 2) << 32 + (i << 2);
        end 
        for(i = 0; i < FAKE_CACHE_MSHR_DEPTH; i = i + 1) begin
            req_que_data[i] <= '0;
            req_lsq_id[i] <= '0;
            req_que_valid <= '0;
            req_que_delay <= '0;
        end
        valid_pt <= '1;
        return_pt <= '1;
    end
    else begin
        if(req_valid_i) begin // store
            if(opcode == 1)begin
                if(type_i[1:0] == 0) begin
                    mem[{req_addr_i[FAKE_MEM_ADDR_LEN - 1:3], 3'b0}][(req_addr_i[2:0] + 1) * 8 - 1:  req_addr_i[2:0] * 8 ] <= st_data_i[7:0];
                end
                else if (type_i[1:0] == 1) begin
                    mem[{req_addr_i[FAKE_MEM_ADDR_LEN - 1:2], 2'b0}][(req_addr_i[1:0] + 1) * 16 - 1:  req_addr_i[1:0] * 16 ] <= st_data_i[15:0];
                end
                else if (type_i[1:0] == 2) begin
                    mem[{req_addr_i[FAKE_MEM_ADDR_LEN - 1:1], 1'b0}][(req_addr_i[0] + 1) * 32 - 1:  req_addr_i[0] * 32] <= st_data_i[31:0];
                end
                else begin
                    mem[req_addr_i[FAKE_MEM_ADDR_LEN - 1:0]] <= req_addr_i;
                end
            end
            else begin
                if(type_i[1:0] == 0) begin
                    req_que_data[valid_pt] <= 
                        mem[{req_addr_i[FAKE_MEM_ADDR_LEN - 1:3], 3'b0}][(req_addr_i[2:0] + 1) * 8 - 1:  req_addr_i[2:0] * 8 ];
                end
                else if (type_i[1:0] == 1) begin
                    req_que_data[valid_pt] <= 
                        mem[{req_addr_i[FAKE_MEM_ADDR_LEN - 1:2], 2'b0}][(req_addr_i[1:0] + 1) * 16 - 1:  req_addr_i[1:0] * 16];
                end
                else if (type_i[1:0] == 2) begin
                    req_que_data[valid_pt] <= 
                        mem[{req_addr_i[FAKE_MEM_ADDR_LEN - 1:1], 1'b0}][(req_addr_i[0] + 1) * 32 - 1:  req_addr_i[0] * 32];
                end
                else begin
                    req_que_data[valid_pt] <= 
                        mem[req_addr_i[FAKE_MEM_ADDR_LEN - 1:0]];
                end
                req_que_delay[valid_pt] <= (req_que_delay[~valid_pt] < FAKE_MEM_DELAY_BASE ) ? FAKE_MEM_DELAY_BASE + req_que_delay[~valid_pt] + $random(0) % 4 :
                                        (random(0) % 2 == 1) ? req_que_delay[~valid_pt] + 2 :
                                        req_que_delay[~valid_pt] - 2
                                        ; //FIXME: RANDOM DELAY
                req_lsq_id[valid_pt] <= rob_index_i;
                req_valid[valid_pt] <= '1;
            end
        end

        // integer i;
        for(i = 0; i < FAKE_CACHE_MSHR_DEPTH; i = i + 1) begin
            if(~req_valid[i]) begin
                req_pt <= i;
            end
            else begin
                if(1 < req_que_delay[i])
                    req_que_delay[i] <= req_que_delay[i] - 1;
                if(req_que_delay[i] == 1) begin
                    return_pt = i;
                end
                else if(req_que_delay[i] == 0) begin
                    req_valid[i] <= '0;
                end
            end
        end
    end
end

endmodule
`endif // FAKE_DCACHE
