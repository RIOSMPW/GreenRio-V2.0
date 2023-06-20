module  l1dcache 
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

    //resp
    input  resp_ready_i,
    output resp_valid_o,
    output [XLEN -1:0] ld_data_o,

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

);
reg dirty_data_has_write_back;
reg [7:0] counter = '0;
reg reset;
wire [2:0] offset = req_addr_i[2:0];
wire [7:0] index =  reset ? counter :
                    req_addr_i[10:3]; 
wire [20:0] tag = req_addr_i[31:11];
wire tag_chip_en_nxt;
wire tag_chip_en;
wire data_chip_en_nxt;
wire data_chip_en;
wire tag_write_en;
wire data_write_en;
wire [7:0] write_tag_mask;
wire [7:0] write_data_mask;
wire [63:0] tag_data_in;
wire [63:0] data_in;
reg [63:0] tag_out;
reg [63:0] data_out;
wire req_hsk;
reg work;
// reg work_u;
reg req_ready;
// reg req_ready_u;
wire ld_tag_is_hit;
wire st_tag_is_hit;
wire [7:0] write_data_mask_in;
wire refill_data_hsk;
wire refill_tag_hsk;
wire cache_mem_is_write;
reg ans = '0;
wire st_tag_is_hit_u;
wire cache_mem_is_write_u;
always @(posedge clk) begin

    if((~rstn) && (counter != 8'b11111111) && (ans=='0)) begin
        counter <= counter +1;
        reset <= '1;
        req_ready <= '0;
        work <= '0;
    end else if((~rstn) && (counter == 8'b11111111)) begin
        counter <= 8'b00000000;
        ans <= '1;
    end else if((~rstn) && (counter == 8'b00000000) && (ans=='1)) begin
        reset <= '0;
    end
end

always @(posedge rstn) begin
    req_ready <= '1;
    counter <= 8'b00000000;
    ans <= '0;
end
reg resp_valid;
assign resp_valid_o = resp_valid;

always @(posedge clk ) begin

    
    if (req_hsk) begin
        //work <= '1;
        req_ready <= '0;
        resp_valid <= '0;
        dirty_data_has_write_back <= '0;
    end  
end


always @(posedge clk) begin
    if (req_hsk) begin
        work <= '1;
    end
    if (work & (ld_tag_is_hit | st_tag_is_hit)) begin
        work <= '0;
    end
end


assign req_hsk = req_valid_i & req_ready_o;
assign req_ready_o = req_ready;
assign tag_chip_en = ~(req_hsk | refill_tag_hsk | reset | st_tag_is_hit);
assign data_chip_en = ~(req_hsk | refill_data_hsk | reset | st_tag_is_hit);

sky130_sram_1rw1r_64x256_8 sky130_sram_1rw1r_64x256_8_tag(
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
);

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

//s1
wire req_hsk_u;
wire [63:0] ld_data_cache;
wire [63:0] ld_data_refill;



assign ld_tag_is_hit =  req_hsk_u ? (tag==tag_out[20:0]) & (opcode==0) :
                        (refill_data_hsk & opcode==0) ? 1'b1:
                        1'b0;

assign st_tag_is_hit =  req_hsk_u ? (tag==tag_out[20:0]) & (opcode==1) :
                        (refill_data_hsk & opcode==1) ? 1'b1:
                        1'b0;


reg [63:0] ld_data;
assign ld_data_o = ld_data;
reg resp_valid;
assign resp_valid_o = resp_valid;

std_dffr #(.WIDTH(1)) ST_TAG_HIT_NXT (.clk(clk),.rstn(rstn),.d(st_tag_is_hit),.q(st_tag_is_hit_u));
always @(posedge clk) begin
    if(ld_tag_is_hit) begin
        if (req_hsk_u) begin
            resp_valid <= '1;
            ld_data <= ld_data_cache;
            //req_ready_o <= '1;
            //work <= '0;
        end else if(refill_data_hsk) begin
            resp_valid <= '1;
            ld_data <= ld_data_refill;
            //req_ready_o <= '1;
            //work <= '0;
        end
    end
    if(st_tag_is_hit_u) begin
        resp_valid <= '1;
        //req_ready_o <= '1;
        //work <= '0;
    end
end

std_dffr #(.WIDTH(1)) REQ_HSK (.clk(clk),.rstn(rstn),.d(req_hsk),.q(req_hsk_u));
//load tag hit
assign ld_data_cache = (opcode == 0 && type_i == 3'b000) ? {{56{data_out[offset*8+7]}},{data_out[offset*8+:8]}}:
                   (opcode == 0 && type_i == 3'b001) ? {{48{data_out[offset*8+15]}},{data_out[offset*8+:16]}}:
                   (opcode == 0 && type_i == 3'b010) ? {32'b0,data_out[offset*8+:32]}:
                   (opcode == 0 && type_i == 3'b100) ? {56'b0,data_out[offset*8+:8]}:
                   (opcode == 0 && type_i == 3'b101) ? {48'b0,data_out[offset*8+:16]}:
                   64'b0;
assign ld_data_refill = (opcode == 0 && type_i == 3'b000) ? {{56{wb_dat_i[offset*8+7]}}, {wb_dat_i[offset*8+:8]}}:
                   (opcode == 0 && type_i == 3'b001) ? {{48{wb_dat_i[offset*8+15]}},{wb_dat_i[offset*8+:16]}}:
                   (opcode == 0 && type_i == 3'b010) ? {32'b0,wb_dat_i[offset*8+:32]}:
                   (opcode == 0 && type_i == 3'b100) ? {56'b0,wb_dat_i[offset*8+:8]}:
                   (opcode == 0 && type_i == 3'b101) ? {48'b0,wb_dat_i[offset*8+:16]}:
                   64'b0;
//store tag hit

assign refill_tag_hsk =  wb_ack_i & ~cache_mem_is_write_u;
assign refill_data_hsk = wb_ack_i & ~cache_mem_is_write_u;
assign data_write_en = ~(st_tag_is_hit_u | refill_data_hsk| reset) ;
assign tag_write_en  = ~(st_tag_is_hit_u | refill_tag_hsk | reset) ;

assign write_data_mask_in = 
                    (opcode == 1 && type_i == 3'b000) ?  (8'b00000001 << offset):
                    (opcode == 1 && type_i == 3'b001) ?  (8'b00000011 << offset):
                    (opcode == 1 && type_i == 3'b010) ?  (8'b00001111 << offset):
                    8'b0;
assign write_data_mask = reset ? 8'b11111111 :
                         refill_data_hsk ? 8'b11111111:
                         write_data_mask_in;
assign write_tag_mask = reset ? 8'b11111111 :
                        refill_tag_hsk ? 8'b00000111 :
                        8'b10000000;
assign tag_data_in = reset ? 64'hFFFFFFFFFFFFFFFF :
                     //refill_tag_hsk ? 64'b1:
                     refill_tag_hsk ? {43'b0,tag}:
                     st_tag_is_hit_u ? {1'b1,63'b0}:
                     64'b0;
                     
assign data_in = reset ? 64'hFFFFFFFFFFFFFFFF:
                 refill_data_hsk ? wb_dat_i:
                 st_data_i;
//load or store miss


always @(posedge clk) begin
    if (wb_ack_i & cache_mem_is_write_u) begin
        dirty_data_has_write_back <= 1'b1;
    end
end

assign cache_mem_is_write =  (wb_ack_i & cache_mem_is_write_u) ? 1'b0:
                             work ? ((tag_out[63]==1) & ~dirty_data_has_write_back) :
                             1'b0;//write 1
wire cache_mem_is_write_u;

std_dffr #(.WIDTH(1)) CACHE_MEM_IS_WRITE (.clk(clk),.rstn(rstn),.d(cache_mem_is_write),.q(cache_mem_is_write_u));
reg wb_cyc;
assign wb_stb_o = wb_cyc_o;
assign wb_cyc_o = (wb_ack_i & ~cache_mem_is_write_u) ? 1'b0:
                  wb_cyc;

always @(posedge clk) begin
    if(work & ~(ld_tag_is_hit | st_tag_is_hit)) begin
        wb_cyc <= 1'b1;
    end else begin
        wb_cyc <= 1'b0;
    end
end

                   


assign wb_we_o = cache_mem_is_write;
assign wb_adr_o = cache_mem_is_write ? {tag_out[20:0],index,3'b0}:
                                       {req_addr_i[31:3],3'b000};
assign wb_dat_o = data_out;
assign wb_sel_o = 8'b11111111;
assign wb_cti_o = 3'b000;
assign wb_bte_o = 2'b00;



endmodule