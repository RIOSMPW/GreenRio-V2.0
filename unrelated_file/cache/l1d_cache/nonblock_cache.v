module  dcache 
#(
    parameter XLEN = 64,
    parameter VIRTUAL_ADDR_LEN = 32
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
    input  resp_ready_i,//no use
    output resp_valid_o,//no use
    output [XLEN -1:0] ld_data_o,
    output [1 : 0] rob_index_o, 

    //memory
    output wb_cyc_o,//1
    output wb_stb_o,//1
    output wb_we_o,
    output [VIRTUAL_ADDR_LEN - 1 : 0] wb_adr_o,
    output [XLEN-1:0] wb_dat_o,
    output [XLEN/8-1:0] wb_sel_o,
    output [2:0] wb_cti_o,
    output [1:0] wb_bte_o,
    input  wb_ack_i,//1
    input  wb_err_i,//no use
    input  wb_rty_i,//no use
    input  [XLEN -1:0] wb_dat_i//data

    //mmu
);

reg input_stall = '0;
wire req_hsk;
wire req_hsk_q;
wire s1_ld_tag_is_hit;
wire s1_st_tag_is_hit;
wire s1_ld_tag_is_miss;
wire s1_st_tag_is_miss;
wire refill_hsk;
reg mshr_is_full = '0;
reg [VIRTUAL_ADDR_LEN - 1 : 0] mshr_addr = '0;
reg [2:0] mshr_type;
reg [XLEN -1:0] mshr_data;
reg mshr_opcode;
reg [1 : 0] mshr_rob_index;
reg [XLEN -1:0] mlfb_data;
wire  req_hsk; 
wire  s1_opcode_nxt;
wire  [31:0] s1_addr_nxt;
wire  [63:0] s1_data_nxt;
wire  [2:0]  s1_type_nxt;
wire  s1_valid_nxt;
wire  [2:0] s1_rob_index_nxt; 
wire  s1_opcode;
wire  [31:0] s1_addr;
wire  [63:0] s1_data;
wire  [2:0] s1_type;
wire  s1_valid;
wire  [2:0] s1_rob_index;
wire  s2_opcode_nxt;
wire [31:0] s2_addr_nxt;
wire [63:0] s2_data_nxt;
wire [2:0] s2_type_nxt;
wire [1:0] s2_rob_index_nxt;
wire s2_valid_nxt;
wire s2_ena;
wire s2_opcode;
wire [31:0] s2_addr;
wire [63:0] s2_data;
wire [2:0] s2_type;
wire s2_valid;
wire [1:0] s2_rob_index;
wire cache_mem_is_write;
wire cache_mem_is_write_q;
wire [63:0] wb_dat;
wire [31:0] wb_tag;
wire [63:0] st_dat;
wire [31:0] tag_out;
wire [63:0] st_dat_mask;
wire [63:0] wb_ack_i_mask;
wire [7:0] index;
wire [31:0] tag_data_in;
wire [63:0] data_in;
wire [63:0] write_data_in;
wire [63:0] data_out;
wire [3:0] write_tag_mask;
wire [7:0] write_data_mask;
wire [7:0] write_data_mask_in;
wire [63:0] ld_data_refill;
wire [63:0] ld_data_cache;
wire refill_hsk;
wire refill_hsk_q;
wire req_hsk_mshr_is_full;
wire req_hsk_mshr_is_full_q;
wire s1_st_tag_is_hit_q; 
wire s1_st_tag_is_miss_q;
wire s1_ld_tag_is_hit_q;
wire s1_ld_tag_is_miss_q;
wire s1_opcode_nxt_q;
wire [31:0] s1_addr_nxt_q;
wire [63:0] s1_data_nxt_q;
wire [2:0] s1_type_nxt_q;
wire s1_valid_nxt_q;
wire [2:0] s1_rob_index_nxt_q;
wire s2_opcode_nxt_q;
wire [31:0] s2_addr_nxt_q;
wire [63:0] s2_data_nxt_q;
wire [2:0] s2_type_nxt_q;
wire s2_valid_nxt_q;
wire [2:0] s2_rob_index_nxt_q;
wire req_hsk_q_q;
/////////////////////////////////////////
//clean sram
reg [7:0] counter = 8'b00000000;
reg reset = '1;
reg ans = '0;
always @(posedge clk) begin

    if(reset && (counter != 8'b11111111) && (ans=='0)) begin
        counter <= counter +1;
    end else if(reset && (counter == 8'b11111111)) begin
        counter <= 8'b00000000;
        ans <= '1;
    end else if(reset && (counter == 8'b00000000) && (ans=='1)) begin
        reset <= '0;
    end
end

always @(negedge rstn) begin
    reset <= '1;
    counter <= 8'b00000000;
    ans <= '0;
    input_stall <= '0;
end
//////////////////////////////////////////
//save req
reg opcode_save;
reg [VIRTUAL_ADDR_LEN - 1 : 0] addr_save;
reg [2:0] type_save;
reg [XLEN -1:0] data_save;
reg [1 : 0] rob_index_save;

always @(posedge clk) begin
    if (req_hsk) begin
        opcode_save <= opcode;
        addr_save <= req_addr_i;
        type_save <= type_i;
        data_save <= st_data_i;
        rob_index_save <= rob_index_i;
    end

end


////////////////////////////////////////
// tag data sram
sky130_sram_1kbyte_1rw1r_32x256_8 sky130_sram_1kbyte_1rw1r_32x256_8_tag(
    .clk0 (clk),
    .csb0 (tag_chip_en),
    .web0 (tag_write_en),
    .wmask0 (write_tag_mask),
    .addr0 (index),
    .din0 (tag_data_in),
    .dout0 (tag_out),
    .clk1 (),
    .csb1 ('1),
    .addr1 (),
    .dout1 ()
);//0 clean 1 dirty 0 valid 1 invalid

sky130_sram_1rw1r_64x256_8 sky130_sram_1rw1r_64x256_8_data(
    .clk0 (clk),
    .csb0 (data_chip_en),
    .web0 (data_write_en),
    .wmask0 (write_data_mask),
    .addr0 (index),
    .din0 (data_in),
    .dout0 (data_out),
    .clk1 (),
    .csb1 ('1),
    .addr1 (),
    .dout1 ()
);
///////////////save tag data out
reg [31:0] tag_out_save;
reg [63:0] data_out_save;

always @(posedge clk) begin
    if(req_hsk_q) begin
        tag_out_save <= tag_out;
        data_out_save <= data_out;
    end
end




assign tag_chip_en = ~(req_hsk | (s2_valid & s2_opcode) | refill_hsk | reset | (refill_hsk_q & input_stall));
assign data_chip_en = ~(req_hsk | (s2_valid & s2_opcode) | refill_hsk | reset | (refill_hsk_q & input_stall));

assign index = reset ? counter :
               refill_hsk ? mshr_addr[10:3] :
               (refill_hsk_q & input_stall) ? addr_save[10:3] :
               req_hsk ? req_addr_i[10:3] :
               (s2_valid & s2_opcode) ? s2_addr[10:3]: 
               8'b0;

assign data_write_en = ~(reset | (s2_valid & s2_opcode) | refill_hsk);
assign tag_write_en = ~(reset | (s2_valid & s2_opcode) | refill_hsk);

assign write_data_mask_in = 
                    (s2_opcode == 1 && s2_type == 3'b000) ?  (8'b00000001 << s2_addr[2:0]):
                    (s2_opcode == 1 && s2_type == 3'b001) ?  (8'b00000011 << s2_addr[2:0]):
                    (s2_opcode == 1 && s2_type == 3'b010) ?  (8'b00001111 << s2_addr[2:0]):
                    8'b0;
assign write_data_in = 
                    (s2_opcode == 1 && s2_type == 3'b000) ?  (s2_data << 8*s2_addr[2:0]):
                    (s2_opcode == 1 && s2_type == 3'b001) ?  (s2_data << 8*s2_addr[2:0]):
                    (s2_opcode == 1 && s2_type == 3'b010) ?  (s2_data << 8*s2_addr[2:0]):
                    8'b0;
assign write_data_mask = reset ? 8'b11111111 :
                         refill_hsk ? 8'b11111111 :
                         (s2_valid & s2_opcode) ? write_data_mask_in :
                         8'b0;
                         

assign write_tag_mask = reset ? 4'b1111 :
                        refill_hsk ? 4'b1111 :
                        (s2_valid & s2_opcode) ? 4'b1000: 
                        4'b0;

assign data_in = reset ? 64'hFFFFFFFFFFFFFFFF :
                 refill_hsk ? wb_dat :
                 (s2_valid & s2_opcode) ? write_data_in :
                 64'b0;

                 

assign tag_data_in = reset ? 32'h0FFFFFFF :// F
                     refill_hsk ? wb_tag :
                     (s2_valid & s2_opcode) ? {1'b1,31'b0}: 
                     32'b0;




//////////////////////////////////////
//replay tag miss req when mshr is full

always @(posedge clk) begin
    if (req_hsk) begin
        opcode_save <= opcode;
        addr_save <= req_addr_i;
        type_save <= type_i;
        data_save <= st_data_i;
        rob_index_save <= rob_index_i;
    end

end


//////////////////////////////////////
// req_ready_o and resp_valid_o and stall

//assign pipeline_stall = refill_hsk; 
assign s2_stall = refill_hsk;
assign s1_stall = refill_hsk;

always @(posedge clk) begin
    if(mshr_is_full & (s1_ld_tag_is_miss | s1_st_tag_is_miss)) begin
        input_stall <= '1;
    end
    if(refill_hsk_q & input_stall) begin
        input_stall <= '0;
    end
end
std_dffr #(.WIDTH(1)) REFILL_HSK (.clk(clk),.rstn(rstn),.d(refill_hsk),.q(refill_hsk_q));  
assign req_ready_o = refill_hsk ? 1'b0 :
                     req_hsk_mshr_is_full_q ? 1'b0 :
                     input_stall ? 1'b0:
                     (req_hsk_q_q & req_hsk_q) ? 1'b0:
                     1'b1;

                     
std_dffr #(.WIDTH(1)) REQ_HSK_1 (.clk(clk),.rstn(rstn),.d(req_hsk),.q(req_hsk_q));
std_dffr #(.WIDTH(1)) REQ_HSK_2 (.clk(clk),.rstn(rstn),.d(req_hsk_q),.q(req_hsk_q_q));
assign req_hsk_mshr_is_full = mshr_is_full & req_hsk;
std_dffr #(.WIDTH(1)) REQ_HSK_MSHR_IS_FULL (.clk(clk),.rstn(rstn),.d(req_hsk_mshr_is_full),.q(req_hsk_mshr_is_full_q));                     
//assign resp_hsk = resp_ready_i & resp_valid_o;
assign resp_valid_o = refill_hsk & ~mshr_opcode ? 1'b1 :
                      (s2_valid & ~s2_opcode)? 1'b1 :
                      1'b0;

assign refill_hsk = (wb_ack_i & ~cache_mem_is_write_q);
//////////////////////////////////////
// mshr and mlfb

reg mshr_just_full = '0;

always @(posedge clk) begin
    if((s1_st_tag_is_miss | s1_ld_tag_is_miss) & ~mshr_is_full) begin
        mshr_is_full <= '1;
        mshr_addr <= s1_addr;
        mshr_type <= s1_type;
        mshr_data <= s1_data;
        mshr_opcode <= s1_opcode;
        mshr_rob_index <= s1_rob_index;
        mshr_just_full <='1;
    end else begin
        mshr_just_full <='0;
    end
    if(refill_hsk) begin
        mshr_is_full <= '0;
    end



end



assign cache_mem_is_write = (wb_ack_i & cache_mem_is_write_q) ? 1'b0 :
                            (s1_st_tag_is_miss_q | s1_ld_tag_is_miss_q) & (tag_out_save[30]==1) ? 1'b0 :
                            (s1_st_tag_is_miss_q | s1_ld_tag_is_miss_q) & mshr_is_full &  (tag_out_save[31]==1) & mshr_just_full ? 1'b1 :
                            cache_mem_is_write_q; 
std_dffr #(.WIDTH(1)) CACHE_MEM_IS_WRITE (.clk(clk),.rstn(rstn),.d(cache_mem_is_write),.q(cache_mem_is_write_q));
assign wb_stb_o = wb_cyc_o;
assign wb_cyc_o = //(s1_st_tag_is_miss | s1_ld_tag_is_miss) & ~mshr_is_full ? 1'b1 :
                  refill_hsk ? 1'b0:
                  mshr_is_full ? 1'b1 :
                  1'b0;


assign wb_we_o = cache_mem_is_write;
assign wb_adr_o = cache_mem_is_write ? {tag_out_save[20:0],addr_save[10:3],3'b0}:
                                       {addr_save[31:3],3'b000};
assign wb_dat_o = data_out_save;
assign wb_sel_o = 8'b11111111;
assign wb_cti_o = 3'b000;
assign wb_bte_o = 2'b00;





////////////////


//s0
assign req_hsk = req_valid_i & req_ready_o;

assign s1_opcode_nxt = req_hsk ? opcode :
                       refill_hsk_q & input_stall ? opcode_save : 
                       s1_stall ? s1_opcode_nxt_q :
                       1'b0;
assign s1_addr_nxt = req_hsk ? req_addr_i : 
                       s1_stall ? s1_addr_nxt_q :
                       refill_hsk_q & input_stall ? addr_save : 
                       32'b0;
assign s1_data_nxt =   req_hsk ? st_data_i : 
                       refill_hsk_q & input_stall ? data_save : 
                       s1_stall ? s1_data_nxt_q :
                       64'b0;
assign s1_type_nxt = req_hsk ? type_i : 
                       refill_hsk_q & input_stall ? type_save : 
                       s1_stall ? s1_type_nxt_q :
                       3'b0;
assign s1_rob_index_nxt = req_hsk ? rob_index_i : 
                        refill_hsk_q & input_stall ? rob_index_save : 
                        s1_stall ? s1_rob_index_nxt_q :
                        2'b0;
assign s1_valid_nxt = req_hsk ? 1'b1 :
                      refill_hsk_q & input_stall ? 1'b1 : 
                      s1_stall ? s1_valid_nxt_q :          
                        1'b0;

assign s1_ena = s1_stall ? 1'b0 : 1'b1;



std_dffr #(.WIDTH(1)) S1_OPCODE_Q (.clk(clk),.rstn(rstn),.d(s1_opcode_nxt),.q(s1_opcode_nxt_q));
std_dffr #(.WIDTH(32)) S1_ADDR_Q (.clk(clk),.rstn(rstn),.d(s1_addr_nxt),.q(s1_addr_nxt_q));
std_dffr #(.WIDTH(64)) S1_DATA_Q (.clk(clk),.rstn(rstn),.d(s1_data_nxt),.q(s1_data_nxt_q));
std_dffr #(.WIDTH(3)) S1_TYPE_Q (.clk(clk),.rstn(rstn),.d(s1_type_nxt),.q(s1_type_nxt_q));
std_dffr #(.WIDTH(1)) S1_VALID_Q (.clk(clk),.rstn(rstn),.d(s1_valid_nxt),.q(s1_valid_nxt_q));
std_dffr #(.WIDTH(3)) S1_ROB_INDEX_Q (.clk(clk),.rstn(rstn),.d(s1_rob_index_nxt),.q(s1_rob_index_nxt_q));

std_dffe #(.WIDTH(1)) S1_OPCODE (.clk(clk),.en(s1_ena),.d(s1_opcode_nxt),.q(s1_opcode));
std_dffe #(.WIDTH(32)) S1_ADDR (.clk(clk),.en(s1_ena),.d(s1_addr_nxt),.q(s1_addr));
std_dffe #(.WIDTH(64)) S1_DATA (.clk(clk),.en(s1_ena),.d(s1_data_nxt),.q(s1_data));
std_dffe #(.WIDTH(3)) S1_TYPE (.clk(clk),.en(s1_ena),.d(s1_type_nxt),.q(s1_type));
std_dffe #(.WIDTH(1)) S1_VALID (.clk(clk),.en(s1_ena),.d(s1_valid_nxt),.q(s1_valid));
std_dffe #(.WIDTH(3)) S1_ROB_INDEX (.clk(clk),.en(s1_ena),.d(s1_rob_index_nxt),.q(s1_rob_index));



//s1
assign s1_ld_tag_is_hit = s1_valid & (s1_addr[31:11] == tag_out[20:0]) & (s1_opcode==0) & (tag_out[30] == 0) & ~((tag_out[20:0] == mshr_addr[31:11]) & (mshr_is_full == 1));

assign s1_st_tag_is_hit = s1_valid & (s1_addr[31:11] == tag_out[20:0]) & (s1_opcode==1) & (tag_out[30] == 0) & ~((tag_out[20:0] == mshr_addr[31:11]) & (mshr_is_full == 1));

assign s1_ld_tag_is_miss = (s1_valid & ~s1_opcode) ? ~s1_ld_tag_is_hit : 1'b0;

assign s1_st_tag_is_miss = (s1_valid & s1_opcode) ? ~s1_st_tag_is_hit : 1'b0;

std_dffr #(.WIDTH(1)) S1_LD_TAG_IS_HIT (.clk(clk),.rstn(rstn),.d(s1_ld_tag_is_hit),.q(s1_ld_tag_is_hit_q));
std_dffr #(.WIDTH(1)) S1_ST_TAG_IS_HIT (.clk(clk),.rstn(rstn),.d(s1_st_tag_is_hit),.q(s1_st_tag_is_hit_q));
std_dffr #(.WIDTH(1)) S1_LD_TAG_IS_MISS (.clk(clk),.rstn(rstn),.d(s1_ld_tag_is_miss),.q(s1_ld_tag_is_miss_q));
std_dffr #(.WIDTH(1)) S1_ST_TAG_IS_MISS (.clk(clk),.rstn(rstn),.d(s1_st_tag_is_miss),.q(s1_st_tag_is_miss_q));


assign s2_opcode_nxt = (s1_ld_tag_is_hit | s1_st_tag_is_hit ) ? s1_opcode : 
                       s2_stall ? s2_opcode_nxt_q :
                        1'b0;
assign s2_addr_nxt = (s1_ld_tag_is_hit | s1_st_tag_is_hit ) ? s1_addr : 
                       s2_stall ? s2_addr_nxt_q :
                       32'b0;
assign s2_data_nxt = (s1_ld_tag_is_hit | s1_st_tag_is_hit ) ? s1_data : 
                       s2_stall ? s2_data_nxt_q :
                       64'b0;
assign s2_type_nxt = (s1_ld_tag_is_hit | s1_st_tag_is_hit ) ? s1_type : 
                       s2_stall ? s2_type_nxt_q :
                        3'b0;
assign s2_rob_index_nxt = (s1_ld_tag_is_hit | s1_st_tag_is_hit ) ? s1_rob_index : 
                        s2_stall ? s2_rob_index_nxt_q :
                        2'b0;
assign s2_valid_nxt = (s1_ld_tag_is_hit | s1_st_tag_is_hit ) ? 1'b1 : 
                        s2_stall ? s2_valid_nxt_q :
                        1'b0 ;

assign s2_ena = s2_stall ? 1'b0 : 1'b1;



std_dffr #(.WIDTH(1)) S2_OPCODE_Q (.clk(clk),.rstn(rstn),.d(s2_opcode_nxt),.q(s2_opcode_nxt_q));
std_dffr #(.WIDTH(32)) S2_ADDR_Q (.clk(clk),.rstn(rstn),.d(s2_addr_nxt),.q(s2_addr_nxt_q));
std_dffr #(.WIDTH(64)) S2_DATA_Q (.clk(clk),.rstn(rstn),.d(s2_data_nxt),.q(s2_data_nxt_q));
std_dffr #(.WIDTH(3)) S2_TYPE_Q (.clk(clk),.rstn(rstn),.d(s2_type_nxt),.q(s2_type_nxt_q));
std_dffr #(.WIDTH(1)) S2_VALID_Q (.clk(clk),.rstn(rstn),.d(s2_valid_nxt),.q(s2_valid_nxt_q));
std_dffr #(.WIDTH(3)) S2_ROB_INDEX_Q (.clk(clk),.rstn(rstn),.d(s2_rob_index_nxt),.q(s2_rob_index_nxt_q));

std_dffe #(.WIDTH(1)) S2_OPCODE (.clk(clk),.en(s2_ena),.d(s2_opcode_nxt),.q(s2_opcode));
std_dffe #(.WIDTH(32)) S2_ADDR (.clk(clk),.en(s2_ena),.d(s2_addr_nxt),.q(s2_addr));
std_dffe #(.WIDTH(64)) S2_DATA (.clk(clk),.en(s2_ena),.d(s2_data_nxt),.q(s2_data));
std_dffe #(.WIDTH(3)) S2_TYPE (.clk(clk),.en(s2_ena),.d(s2_type_nxt),.q(s2_type));
std_dffe #(.WIDTH(1)) S2_VALID (.clk(clk),.en(s2_ena),.d(s2_valid_nxt),.q(s2_valid));
std_dffe #(.WIDTH(3)) S2_ROB_INDEX (.clk(clk),.en(s2_ena),.d(s2_rob_index_nxt),.q(s2_rob_index));


//s2 resp
assign ld_data_cache = (s2_opcode == 0 && s2_type == 3'b000) ? {{56{s2_data[s2_addr[2:0]*8+7]}},{s2_data[s2_addr[2:0]*8+:8]}}:
                       (s2_opcode == 0 && s2_type == 3'b001) ? {{48{s2_data[s2_addr[2:0]*8+15]}},{s2_data[s2_addr[2:0]*8+:16]}}:
                       (s2_opcode == 0 && s2_type == 3'b010) ? {32'b0,{s2_data[s2_addr[2:0]*8+:32]}}:
                       (s2_opcode == 0 && s2_type == 3'b100) ? {56'b0,{s2_data[s2_addr[2:0]*8+:8]}}:
                       (s2_opcode == 0 && s2_type == 3'b101) ? {48'b0,{s2_data[s2_addr[2:0]*8+:16]}}:
                       64'b0;

assign ld_data_refill = (mshr_opcode == 0 && mshr_type == 3'b000) ? {{56{wb_dat_i[mshr_addr[2:0]*8+7]}}, {wb_dat_i[mshr_addr[2:0]*8+:8]}}:
                   (mshr_opcode == 0 && mshr_type == 3'b001) ? {{48{wb_dat_i[mshr_addr[2:0]*8+15]}},{wb_dat_i[mshr_addr[2:0]*8+:16]}}:
                   (mshr_opcode == 0 && mshr_type == 3'b010) ? {32'b0,wb_dat_i[mshr_addr[2:0]*8+:32]}:
                   (mshr_opcode == 0 && mshr_type == 3'b100) ? {56'b0,wb_dat_i[mshr_addr[2:0]*8+:8]}:
                   (mshr_opcode == 0 && mshr_type == 3'b101) ? {48'b0,wb_dat_i[mshr_addr[2:0]*8+:16]}:
                   64'b0;

assign wb_dat = ~mshr_opcode ? wb_dat_i :
                mshr_opcode ? st_dat :
                64'b0;

assign wb_tag = ~mshr_opcode ? {11'b0,mshr_addr[31:11]} :
                mshr_opcode ? {11'b10000000000,mshr_addr[31:11]} :
                32'b0;

assign st_dat_mask =(mshr_opcode == 1 && mshr_type == 3'b000) ?  64'h00000000000000FF << mshr_addr[2:0]*8 :
                    (mshr_opcode == 1 && mshr_type == 3'b001) ?  64'h000000000000FFFF << mshr_addr[2:0]*8 : 
                    (mshr_opcode == 1 && mshr_type == 3'b010) ?  64'h00000000FFFFFFFF << mshr_addr[2:0]*8 :
                    64'b0;
assign wb_ack_i_mask = ~st_dat_mask & wb_dat_i;

assign st_dat =     (mshr_opcode == 1 && mshr_type == 3'b000) ?  (mshr_data << mshr_addr[2:0]*8) | wb_ack_i_mask :
                    (mshr_opcode == 1 && mshr_type == 3'b001) ?  (mshr_data << mshr_addr[2:0]*8) | wb_ack_i_mask :
                    (mshr_opcode == 1 && mshr_type == 3'b010) ?  (mshr_data << mshr_addr[2:0]*8) | wb_ack_i_mask :
                    64'b0;
///resp ld

assign ld_data_o = refill_hsk ? ld_data_refill :
                   s2_valid ? ld_data_cache :
                   64'b0;

assign rob_index_o = refill_hsk ? mshr_rob_index :
                     s2_valid ? s2_rob_index :
                     2'b00;


endmodule