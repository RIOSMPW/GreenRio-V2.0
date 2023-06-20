module perfect_memory 
    import rvh_pkg::*;
    import riscv_pkg::*;
    import l1d_verif_pkg::*;
    import uop_encoding_pkg::*;
    // import rvh_lsu_pkg::*;
    import l1d_verif_pkg::*;
    import rvh_l1d_pkg::*;
#(
    parameter int N_PORT = 4,
    parameter int N_BANK = 2,
    parameter int CACHELINE_WIDTH = 512, // length of the cache line
    parameter int ADDR_WIDTH = 32,
    parameter int FAKE_MEMORY_SIZE = 16,
    parameter int ID_WIDTH = 12,
    parameter int N_THREAD_PER_BANK = 4,
    parameter int MAX_DELAY_CYCLE = 10,
    parameter bit [ADDR_WIDTH-1:0] BASE_ADDR = '0
)
(
    // AR
    input                     [N_PORT - 1 : 0]            l2_req_if_arvalid_i ,
    output                    [N_PORT - 1 : 0]            l2_req_if_arready_o ,
    input   cache_mem_if_ar_t [N_PORT - 1 : 0]            l2_req_if_ar_i      ,
    // ewrq -> mem bus  
    // AW   
    input                     [N_PORT - 1 : 0]            l2_req_if_awvalid_i ,
    output                    [N_PORT - 1 : 0]            l2_req_if_awready_o ,
    input   cache_mem_if_aw_t [N_PORT - 1 : 0]            l2_req_if_aw_i      ,
    // W    
    input                     [N_PORT - 1 : 0]            l2_req_if_wvalid_i  ,
    output                    [N_PORT - 1 : 0]            l2_req_if_wready_o  ,
    input   cache_mem_if_w_t  [N_PORT - 1 : 0]            l2_req_if_w_i       ,
    // B    
    output                    [N_PORT - 1 : 0]            l2_resp_if_bvalid_o ,
    input                     [N_PORT - 1 : 0]            l2_resp_if_bready_i ,
    output  cache_mem_if_b_t  [N_PORT - 1 : 0]            l2_resp_if_b_o      , 
    // mem bus -> mlfb  
    // R    
    output                    [N_PORT - 1 : 0]            l2_resp_if_rvalid_o ,
    input                     [N_PORT - 1 : 0]            l2_resp_if_rready_i ,    
    output  cache_mem_if_r_t  [N_PORT - 1 : 0]            l2_resp_if_r_o      , 

    input   logic           rst, clk
);

`define RANDOM_DELAY
`ifndef RANDOM_DELAY
localparam int FIXED_DELAY = 5;
`endif // RANDOM_DELAY

localparam int MASK_WIDTH = CACHELINE_WIDTH / 8;
localparam int PORT_ID_WIDTH = $clog2(N_PORT);
localparam int BANK_ID_WIDTH = $clog2(N_BANK);
localparam int BANK_ID_LSB = $clog2(CACHELINE_WIDTH/8);
localparam int BANK_ID_MSB = (BANK_ID_WIDTH == 0) ? BANK_ID_LSB : (BANK_ID_LSB + BANK_ID_WIDTH - 1);
localparam int AXI_DATA_WIDTH = MEM_DATA_WIDTH;
localparam int AXI_MASK_WIDTH = AXI_DATA_WIDTH / 8;
localparam int N_AXI_DATA_PER_CACHE_LINE = CACHELINE_WIDTH / AXI_DATA_WIDTH;
localparam int OFFSET_WIDTH = $clog2(CACHELINE_WIDTH / 8);

typedef struct {
    bit                             vld;
    bit [CACHELINE_WIDTH-1:0]    data;
    bit [ADDR_WIDTH-1:0]    addr;
    bit [MASK_WIDTH-1:0]    mask;
    mem_tid_t      id;
    bit                     rw; // 0=read; 1=write
    bit [PORT_ID_WIDTH-1:0] port_id;
    l1d_snoop_type_e        snp_type;
} cache_req_t;

typedef struct {
    bit                     vld;
    bit                     rw;
    bit [CACHELINE_WIDTH-1:0]    data;
    mem_tid_t     id;
    bit [PORT_ID_WIDTH-1:0] port_id;
    rrv64_mesi_type_e mesi_type;
} cache_resp_t;

typedef struct{
    bit                     bvld;
    bit                     brdy;
    cache_mem_if_b_t        b;
    bit                     rvld;
    bit                     rrdy;
    cache_mem_if_r_t        r;
} axi_resp_t;

typedef struct{
    bit                     arvld;
    cache_mem_if_ar_t       ar;
    bit                     awvld;
    cache_mem_if_aw_t       aw;
    bit                     wvld;
    cache_mem_if_w_t        w;
} axi_req_t;

// mem array
bit [7:0] mem [bit[FAKE_MEMORY_SIZE-1:0]];
bit [7:0] pagetable [bit[FAKE_MEMORY_SIZE-1:0]];

// interface queue
cache_mem_if_ar_t                                                   q_ar[N_PORT - 1 : 0][$];
cache_mem_if_aw_t                                                   q_aw[N_PORT - 1 : 0][$];
cache_mem_if_w_t                                                    q_w[N_PORT - 1 : 0][$];
cache_mem_if_b_t                                                    q_b[N_PORT - 1 : 0][$];
cache_mem_if_r_t                                                    q_r[N_PORT - 1 : 0][$];
// req/resp queue
cache_req_t                                                         q_req[$];
cache_resp_t                                                        q_bank_resp[N_BANK][$];                                    
axi_req_t                                                           axi_req[N_PORT - 1 : 0];
axi_resp_t                                                          axi_resp[N_PORT - 1 : 0];

function int get_bank_id (bit [ADDR_WIDTH-1:0] addr);
    if (BANK_ID_WIDTH == 0)
      get_bank_id = 0;
    else
      get_bank_id = addr[BANK_ID_MSB:BANK_ID_LSB];
endfunction

generate
    for (genvar i=0; i<N_PORT; i++) begin : req_if_to_struct
      always @ (*) begin
        axi_req[i].awvld = l2_req_if_awvalid_i[i];
        axi_req[i].wvld = l2_req_if_wvalid_i[i];
        axi_req[i].arvld = l2_req_if_arvalid_i[i];
        axi_req[i].ar = l2_req_if_ar_i[i];
        axi_req[i].w = l2_req_if_w_i[i];
        axi_req[i].aw = l2_req_if_aw_i[i];
        axi_resp[i].brdy = l2_resp_if_bready_i[i];
        l2_resp_if_b_o[i] = axi_resp[i].b;
        axi_resp[i].rrdy = l2_resp_if_rready_i[i];
        l2_resp_if_r_o[i] = axi_resp[i].r;
      end
    assign l2_resp_if_bvalid_o[i] = axi_resp[i].bvld;
    assign l2_resp_if_rvalid_o[i] = axi_resp[i].rvld;
    end
endgenerate
assign l2_req_if_arready_o = ~rst;
assign l2_req_if_awready_o = ~rst;
assign l2_req_if_wready_o = ~rst;

always @(posedge clk) begin
    for(int i = 0; i < N_PORT; i ++) begin
        cache_req_t req;
        cache_resp_t resp;
        // process new req
        if(axi_req[i].awvld) begin
            q_aw[i].push_back(axi_req[i].aw);
`ifdef LOG_LV2
            if(axi_req[i].aw.awaddr[31:0] == 32'h80001140) begin
                $display($realtime, "\t\taw in: %x.",axi_req[i].aw.awaddr);
            end
`endif //LOG_LV2
        end
        if(axi_req[i].arvld) begin
            q_ar[i].push_back(axi_req[i].ar);
`ifdef LOG_LV2
            if(axi_req[i].ar.araddr[31:0] == 32'h80001140) begin
                $display($realtime, "\t\tar in: %x. size:%d", axi_req[i].ar.araddr, $size(q_ar));
            end
            
`endif //LOG_LV2
        end

        if(axi_req[i].wvld) begin
            q_w[i].push_back(axi_req[i].w);
        end
        // add aw and w to req_q
        if(($size(q_aw[i]) > 0)) begin 
            cache_mem_if_aw_t aw;
            aw = q_aw[i].pop_front();
            if(aw.mesi != SHARED && aw.mesi != EXCLUSIVE) begin
                req.addr = aw.awaddr;
                req.vld = 0;
                req.rw = '1;
                req.port_id = i;
                q_req.push_back(req);
            end
        end 

        if(($size(q_w[i]) >= N_AXI_DATA_PER_CACHE_LINE)) begin
            int pt;
            for(pt = 0; pt < $size(q_req); pt ++) begin
                if(q_req[pt].rw == 1 && q_req[pt].vld == 0) begin
                    break;
                end
            end
            assert(pt != $size(q_req));
            for(int j = 0; j < N_AXI_DATA_PER_CACHE_LINE; j ++) begin 
                cache_mem_if_w_t w;
                w = q_w[i].pop_front();
                if(j == 0) begin
                    q_req[pt].id = w.wid;
                end
                q_req[pt].data[j * AXI_DATA_WIDTH +: AXI_DATA_WIDTH] = w.wdata;
                q_req[pt].mask[j * AXI_MASK_WIDTH +: AXI_MASK_WIDTH] = '1; // FIXME: no mask in cache_mem_if_w_t
            end
`ifdef LOG_LV2
            if(q_req[pt].addr[31:0] == 32'h80001140) begin
                $display($realtime, "\t\twb: %x. mask = %x", q_req[pt].data, q_req[pt].mask);
            end
`endif //LOG_LV2
            q_req[pt].vld = 1;
        end

        // add ar to req_q
        if($size(q_ar[i]) > 0) begin
            cache_mem_if_ar_t ar;
            ar = q_ar[i].pop_front();

            req.data = '0;
            req.addr = ar.araddr;
            req.mask = '1;
            req.id = ar.arid;
            req.rw = '0;
            req.port_id = i;
            req.vld = 1;
            req.snp_type = ar.arsnoop;
`ifdef LOG_LV2
            if(req.addr[31:0] == 32'h80001140) begin
                $display($realtime, "\t\treq in: %x, %d", req.addr, req.rw);
            end
`endif //LOG_LV2
            q_req.push_back(req);
        end
        

        // process req
        while($size(q_req) > 0) begin
            int bank_id;
`ifdef LOG_LV2
            if(q_req[0].addr[31:0] == 32'h80001140) begin
                $display($realtime, "\t\treq parse: %x, %d, vld %b", q_req[0].addr, q_req[0].rw, q_req[0].vld);
            end
`endif //LOG_LV2
            if(q_req[0].vld == 0) begin
                break;
            end
            req = q_req.pop_front();

            req.addr[OFFSET_WIDTH - 1 : 0] = '0;
            resp.vld = 1;
            resp.rw = req.rw;
            resp.data = 0;
            resp.id = req.id;
            resp.port_id = req.port_id;
            resp.mesi_type = SHARED;
            if(req.rw == 1) begin // write
`ifdef LOG_LV2
                if(req.addr[31:0] == 32'h80001140) begin
                    $display($realtime, "\t\twb mem @ %x:  %x", req.addr, req.data);
                end
`endif //LOG_LV2
                for(int k = 0; k < (CACHELINE_WIDTH / 8); k ++) begin
                    if(req.mask[k] == 1) begin
                        bit [ADDR_WIDTH-1:0] addr;
                        addr = req.addr + k - BASE_ADDR;
                        if(DATA_BASE_ADDR <= addr && addr < DATA_BASE_ADDR + DATA_ADDR_RANGE) begin
`ifdef LOG_LV2
                            if(req.addr[31:0] == 32'h80001140) begin
                                $display($realtime, "\t\twb mem @ %x:  %x", addr, req.data[k * 8 +: 8]);
                            end
`endif //LOG_LV2
                            mem[addr[FAKE_MEMORY_SIZE - 1 : 0]] = req.data[k * 8 +: 8];
                        end
                        else if(PAGETABLE_BASE_ADDR <= addr && addr < PAGETABLE_BASE_ADDR + PAGETABLE_ADDR_RANGE) begin
                            $error("page table mem unaccessable");
                            assert(0);
                        end
                        else begin
                            string msg;
                            $sformat(msg, "illegal addr: %x", addr);
                            error_quit(msg);
                        end
                    end
                end
            end
            else begin // read
                for(int k = 0; k < (CACHELINE_WIDTH / 8); k ++) begin
                    bit [ADDR_WIDTH-1:0] addr;
                    addr = req.addr + k - BASE_ADDR;
`ifdef LOG_LV2
                    if(addr == 32'h80001140) begin
                        $display($realtime, "\t\tar resp gen: %x.", addr);
                    end
`endif //LOG_LV2
                    if(req.snp_type == DIRECTORYW) begin
                        resp.mesi_type = MODIFIED;
                    end
                    else if(req.snp_type == DIRECTORYR) begin
                        resp.mesi_type = EXCLUSIVE;
                    end
                    if(DATA_BASE_ADDR <= addr && addr < DATA_BASE_ADDR + DATA_ADDR_RANGE) begin
                        if(mem.exists(addr[FAKE_MEMORY_SIZE - 1 : 0])) begin // mem visit in the range
                            resp.data[k * 8 +: 8] = mem[addr[FAKE_MEMORY_SIZE - 1 : 0]];
                        end 
                        else begin
                            resp.data[k * 8 +: 8] = '1;
                        end 
                    end
                    else if(PAGETABLE_BASE_ADDR <= addr && addr < PAGETABLE_BASE_ADDR + PAGETABLE_ADDR_RANGE) begin
                        if(pagetable.exists(addr[FAKE_MEMORY_SIZE - 1 : 0])) begin // mem visit in the range
                            resp.data[k * 8 +: 8] = pagetable[addr[FAKE_MEMORY_SIZE - 1 : 0]];
                        end 
                        else begin
                            resp.data[k * 8 +: 8] = '1;
                        end 
                        // $display("\n\n====================");
                        // $display("page table r resp for %x", addr);
                        // $display("data  = %x", resp.data);
                        // $display("\n====================");
                    end
                    else begin
                        string msg;
                        $sformat(msg, "illegal addr: %x", addr);
                        error_quit(msg);
                    end
                end
`ifdef LOG_LV2
                if(req.addr[31:0] == 32'h80001140) begin
                    $display($realtime, "\t\tread: %x", resp.data);
                end
`endif //LOG_LV2
            end

            bank_id = get_bank_id(req.addr);
            q_bank_resp[bank_id].push_back(resp);
        end
    end
end

//==========================================================
// random delay {{{
cache_resp_t      q_bank_resp_dly[N_BANK][$];
generate
    for(genvar j = 0; j < N_BANK; j ++) begin: PER_BANK
        for(genvar k = 0; k < N_THREAD_PER_BANK; k ++) begin: PER_THREAD
            always @(posedge clk) begin
                if($size(q_bank_resp[j]) > 0) begin
                    cache_resp_t resp;
                    int delay;
                    resp = q_bank_resp[j].pop_front();
`ifdef RANDOM_DELAY
                    delay = $urandom_range(MAX_DELAY_CYCLE);
`else // RANDOM_DELAY
                    delay = FIXED_DELAY;
`endif // RANDOM_DELAY
                    repeat (delay) @ (posedge clk);
                    q_bank_resp_dly[j].push_back(resp);
                end
            end
        end // PER_THREAD
    end // PER_BANK
endgenerate
// }}}

//==========================================================
// always@ (posedge clk) begin
//     if(~rst) begin
//         if(l2_req_if_wvalid_i[0] & l2_req_if_awvalid_i[0]) begin
//             $display("l1d->axi mem wb @ %x", l2_req_if_aw_i[0].awaddr);
//             if(l2_req_if_aw_i[0].awaddr[31:0] == 32'h8000a780) begin
//                 int delay = 100;
//                 repeat(delay) @(posedge clk);
//                 $finish;
//             end
//         end
//     end
// end

// process resp {{{ 
always @ (posedge clk) begin
    if(rst) begin
        // for(int i = 0; i < N_PORT; i ++) begin
        //     resp[i].bvld <= 0;
        //     resp[i].rvld <= 0;
        //     resp[i].r.rlast <= 0;
        // end
    end
    else begin
        for(int i = 0; i < N_PORT; i ++) begin
            // axi_resp handshake. Last resp is accepted, deque 
            cache_mem_if_b_t b;
            cache_mem_if_r_t r;
            // b
            if((axi_resp[i].brdy == 1) && (axi_resp[i].bvld == 1)) begin
                b = q_b[i].pop_front();
            end
            // r
            if((axi_resp[i].rrdy == 1) && (axi_resp[i].rvld == 1)) begin
                b = q_r[i].pop_front();
            end

            // if resp queue is empty. resp_delay_q -> resp_q
            for(int j = 0; j < N_BANK; j ++) begin
                if(($size(q_bank_resp_dly[j]) > 0) && (q_bank_resp_dly[j][0].port_id == i)) begin
                    if(q_bank_resp_dly[j][0].rw == 1 && ($size(q_b[i]) == 0)) begin // b
                        cache_resp_t resp;
                        resp = q_bank_resp_dly[j].pop_front();

                        b.bid = resp.id;
                        b.bresp = AXI_RESP_OKAY;

                        q_b[i].push_back(b);
                    end
                    else begin
                        if(q_bank_resp_dly[j][0].rw == 0 && ($size(q_b[i]) == 0)) begin // r
                            cache_resp_t resp;

                            resp = q_bank_resp_dly[j].pop_front();

                            r.rid = resp.id;
                            r.err = 0;
                            r.mesi_sta = resp.mesi_type;
                            r.rresp = AXI_RESP_OKAY;
                            for(int k = 0; k < N_AXI_DATA_PER_CACHE_LINE; k ++) begin
                                if(k == N_AXI_DATA_PER_CACHE_LINE - 1) begin
                                    r.rlast = 1;
                                end
                                else begin
                                    r.rlast = 0;
                                end
                                r.dat = resp.data[k * AXI_DATA_WIDTH +: AXI_DATA_WIDTH];
                                q_r[i].push_back(r);
                            end
                        end
                    end
                end
            end

            // drive axi
            if($size(q_b[i]) > 0) begin
                axi_resp[i].bvld <= '1;
                axi_resp[i].b <= q_b[i][0];
            end
            else begin
                axi_resp[i].bvld <= '0;
            end
            if($size(q_r[i]) > 0) begin
                axi_resp[i].rvld <= '1;
                axi_resp[i].r <= q_r[i][0];
            end
            else begin
                axi_resp[i].rvld <= '0;
            end

        end
    end
end
// }}}


//==========================================================
// backdoor access {{{
function bit[7:0] get_byte(bit [ADDR_WIDTH-1:0] addr);
    return mem[addr[FAKE_MEMORY_SIZE - 1 : 0]];
endfunction

function bit[15:0] get_hword(bit [ADDR_WIDTH-1:0] addr);
    bit[15:0] data;
    for(int i = 0; i < 2; i ++) begin
        data[i*8 +: 8] = mem[addr[FAKE_MEMORY_SIZE - 1 : 0] + i];
    end
    return data;
endfunction

function bit[31:0] get_word(bit [ADDR_WIDTH-1:0] addr);
    bit[31:0] data;
    for(int i = 0; i < 4; i ++) begin
        data[i*8 +: 8] = mem[addr[FAKE_MEMORY_SIZE - 1 : 0] + i];
    end
    return data;
endfunction

function bit[63:0] get_dword(bit [ADDR_WIDTH-1:0] addr);
    bit[63:0] data;
    for(int i = 0; i < 8; i ++) begin
        data[i*8 +: 8] = mem[addr[FAKE_MEMORY_SIZE - 1 : 0] + i];
    end
    return data;
endfunction

function bit[63:0] get_pte(bit [ADDR_WIDTH-1:0] addr);
    bit[63:0] data;
    for(int i = 0; i < 8; i ++) begin
        data[i*8 +: 8] = pagetable[addr[FAKE_MEMORY_SIZE - 1 : 0] + i];
    end
    return data;
endfunction

function void set_byte (bit [ADDR_WIDTH-1:0] addr, bit [7:0] data);
    mem[addr[FAKE_MEMORY_SIZE - 1 : 0]] = data;
endfunction

function void set_hword (bit [ADDR_WIDTH-1:0] addr, bit [31:0] data);
    addr[0] = '0;
    for (int i=0; i<2; i++) begin
        set_byte(addr+i, data[i*8 +: 8]);
    end
endfunction

function void set_word (bit [ADDR_WIDTH-1:0] addr, bit [31:0] data);
    addr[1:0] = '0;
    for (int i=0; i<4; i++) begin
        set_byte(addr+i, data[i*8 +: 8]);
    end
endfunction


function void set_dword (bit [ADDR_WIDTH-1:0] addr, bit [63:0] data);
    // if(data != 0) $display("data:%h @ addr: %h\n", data, addr);
    addr[2:0] = '0;
    set_word(addr, data[31:0]);
    addr[2] = '1;
    set_word(addr, data[63:32]);
endfunction

function void reset ();
    mem.delete();
    while ($size(q_req) > 0) begin
        q_req.delete(0);
    end
    for (int i=0; i<N_PORT; i++) begin
        while ($size(q_ar[i]) > 0) begin
        q_ar[i].delete(0);
        end
        while ($size(q_aw[i]) > 0) begin
        q_aw[i].delete(0);
        end
        while ($size(q_w[i]) > 0) begin
        q_w[i].delete(0);
        end
        while ($size(q_r[i]) > 0) begin
        q_r[i].delete(0);
        end
        while ($size(q_b[i]) > 0) begin
        q_b[i].delete(0);
        end
    end
    for (int j=0; j<N_BANK; j++) begin
        while ($size(q_bank_resp[j]) > 0) begin
            q_bank_resp[j].delete(0);
        end
        while ($size(q_bank_resp_dly[j]) > 0) begin
            q_bank_resp_dly[j].delete(0);
        end
    end
endfunction

function void init;
    $readmemh(`PERFECT_MEM_FILE, mem);
    $readmemh(`PAGE_TABLE_FILE, pagetable);
endfunction
// }}}

endmodule