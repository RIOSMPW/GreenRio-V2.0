/*

Perfect memory model
- Parameterized number of ports (N_PORT)
  - Support AXI (oursring) I/F
    - Support burst of N_AXI_DATA_PER_CACHE_LINE (a cache line access)
- All requests are logged into axi_que q_ar/q_aw/q_w, then into one single request queu and processed immediately to generate response packets
- The responses packets are put into bank queues (q_bank_resp) first, to mimic the behavior of L2 bank. To make things simpler, can set N_BANK to 1 to use a single queue.
- Each bank has N_THREAD_PER_BANK threads to process responds, and move them to delayed bank queues q_bank_resp_dly
    - Random number of delay cycles were waited for these threads to process each packet
- Every cycle, one packet is popped out from each bank queue and put into axi queue q_r/q_b, in case there is race to the same port

*/

module perfect_mem_model
  import pygmy_typedef::*;
  import pygmy_intf_typedef::*;
#(
  parameter int N_PORT = 4,
  parameter int N_BANK = 2,
  parameter int DATA_WIDTH = 256, // length of the cache line
  parameter int ADDR_WIDTH = 32,
  parameter int ID_WIDTH = 12,
  parameter int N_THREAD_PER_BANK = 4,
  parameter int MAX_DELAY_CYCLE = 10,
  parameter bit [ADDR_WIDTH-1:0] BASE_ADDR = '0
) (
  oursring_req_if.slave   req_if[N_PORT],
  oursring_resp_if.master resp_if[N_PORT],
  // AR
  output logic              l2_req_if_arvalid_i [N_PORT],
  input  logic              l2_req_if_arready_o [N_PORT],
  output cache_mem_if_ar_t  l2_req_if_ar_i      [N_PORT],
    // ewrq -> mem bus
    // AW 
  output logic              l2_req_if_awvalid_i [N_PORT],
  input  logic              l2_req_if_awready_o [N_PORT],
  output cache_mem_if_aw_t  l2_req_if_aw_i      [N_PORT],
    // W 
  output logic              l2_req_if_wvalid_i  [N_PORT],
  input  logic              l2_req_if_wready_o  [N_PORT],
  output cache_mem_if_w_t   l2_req_if_w_i       [N_PORT],
    // B
  input  logic              l2_resp_if_bvalid_o [N_PORT],
  output logic              l2_resp_if_bready_i [N_PORT],
  input  cache_mem_if_b_t   l2_resp_if_b_o      [N_PORT],
    // mem bus -> mlfb
    // R
  input  logic              l2_resp_if_rvalid_o [N_PORT],
  output logic              l2_resp_if_rready_i [N_PORT],
  input cache_mem_if_r_t    l2_resp_if_r_o      [N_PORT],
  
  input   logic           rstn, clk
);

  localparam int MASK_WIDTH = DATA_WIDTH / 8;

  localparam int PORT_ID_WIDTH = $clog2(N_PORT);

  localparam int BANK_ID_WIDTH = $clog2(N_BANK);
  localparam int BANK_ID_LSB = $clog2(DATA_WIDTH/8);
  localparam int BANK_ID_MSB = (BANK_ID_WIDTH == 0) ? BANK_ID_LSB : (BANK_ID_LSB + BANK_ID_WIDTH - 1);
  
  localparam int AXI_DATA_WIDTH = $bits(req_if.w.wdata);
  localparam int AXI_MASK_WIDTH = AXI_DATA_WIDTH / 8;
  localparam int N_AXI_DATA_PER_CACHE_LINE = DATA_WIDTH / AXI_DATA_WIDTH;

  localparam int OFFSET_WIDTH = $clog2(DATA_WIDTH / 8);

  bit [7:0] mem [bit[ADDR_WIDTH-1:0]];
`ifdef PMM_TRACE
  bit debug_info = 1'b1;
  bit debug_info_deep = 1'b1;
`else //PMM_TRACE
  bit debug_info = 1'b0;
  bit debug_info_deep = 1'b0;
`endif //PMM_TRACE
  initial begin
    if ($test$plusargs("print_perfect_mem_model_debug_info")) begin
      debug_info = 1'b1;
    end
    if ($test$plusargs("print_perfect_mem_model_debug_info_deep")) begin
      debug_info_deep = 1'b1;
    end
  end

  typedef struct {
    bit [DATA_WIDTH-1:0]    data;
    bit [ADDR_WIDTH-1:0]    addr;
    bit [MASK_WIDTH-1:0]    mask;
    bit [ID_WIDTH-1:0]      id;
    bit                     rw; // 0=read; 1=write
    bit [PORT_ID_WIDTH-1:0] port_id;
  } cache_req_t;

  typedef struct {
    bit                     valid;
    bit                     rw;
    bit [DATA_WIDTH-1:0]    data;
    bit [ID_WIDTH-1:0]      id;
    bit [PORT_ID_WIDTH-1:0] port_id;
  } cache_resp_t;

  function int get_bank_id (bit [ADDR_WIDTH-1:0] addr);
    if (BANK_ID_WIDTH == 0)
      get_bank_id = 0;
    else
      get_bank_id = addr[BANK_ID_MSB:BANK_ID_LSB];
  endfunction

  //==========================================================
  // process request {{{
  oursring_req_if_t axi_req[N_PORT];
  cache_req_t       q_req[$];
  cache_resp_t      q_bank_resp[N_BANK][$];

  // i/f <-> struct
  generate
    for (genvar i=0; i<N_PORT; i++) begin : req_if_to_struct
      always @ (*) begin
        axi_req[i].awvalid = req_if[i].awvalid;
        req_if[i].awready = axi_req[i].awready;
        axi_req[i].wvalid = req_if[i].wvalid;
        req_if[i].wready = axi_req[i].wready;
        axi_req[i].arvalid = req_if[i].arvalid;
        req_if[i].arready = axi_req[i].arready;
        axi_req[i].ar = req_if[i].ar;
        axi_req[i].w = req_if[i].w;
        axi_req[i].aw = req_if[i].aw;
      //`oursring_req_if_slave_assign(req_if[i], axi_req[i]);
      end
    end
  endgenerate

  // from interface to axi queue
  oursring_req_if_ar_t  q_ar[N_PORT][$];
  oursring_req_if_aw_t  q_aw[N_PORT][$];
  oursring_req_if_w_t   q_w[N_PORT][$];

  always @ (*) begin
    for (int i=0; i<N_PORT; i++) begin
      axi_req[i].arready = rstn;
      axi_req[i].awready = rstn;
      axi_req[i].wready = rstn;
    end
  end

  always @ (posedge clk) begin
    for (int i=0; i<N_PORT; i++) begin
      cache_req_t   req;
      cache_resp_t  resp;

      // i/f to axi queue {{{
      if (axi_req[i].arvalid) begin
        q_ar[i].push_back(axi_req[i].ar);
        if (debug_info) $display("PMM-PORT-AR: addr=%h id=%h port_id=%0d size(q_ar)=%-4d @ %t in %m", 
          axi_req[i].ar.araddr, axi_req[i].ar.arid, i, $size(q_ar[i]), $time(),
            N_AXI_DATA_PER_CACHE_LINE, DATA_WIDTH, AXI_DATA_WIDTH);
      end
      if (axi_req[i].awvalid) begin
        q_aw[i].push_back(axi_req[i].aw);
        if (debug_info) $display("PMM-PORT-AW: addr=%h id=%h port_id=%0d size(q_aw)=%-4d @ %t in %m", axi_req[i].aw.awaddr, axi_req[i].aw.awid, i, $size(q_aw[i]), $time());
      end
      if (axi_req[i].wvalid) begin
        q_w[i].push_back(axi_req[i].w);
        assert (!$isunknown(axi_req[i].w.wdata));
        if (debug_info) $display("PMM-PORT-W:  data=%h strb=%h port_id=%0d size(q_w)=%-4d @ %t in %m", axi_req[i].w.wdata, axi_req[i].w.wstrb, i, $size(q_w[i]), $time());
      end
      // }}}

      // read: axi queue -> request queue {{{
      if ($size(q_ar[i]) > 0) begin
        oursring_req_if_ar_t ar;
        ar = q_ar[i].pop_front();

        req.data = '0;
        req.addr = ar.araddr;
        req.mask = '1;
        req.id = ar.arid;
        req.rw = '0;
        req.port_id = i;

        q_req.push_back(req);
        if (debug_info_deep) $display("PMM-READ-REQ: addr=%h id=%h port=%h size(q_req)=%-4d @ %t in %m", req.addr, req.id, req.port_id, $size(q_req), $time());
      end // }}}

      // write: axi queue -> request queue {{{
      if (($size(q_aw[i]) >= 1) && ($size(q_w[i]) >= N_AXI_DATA_PER_CACHE_LINE)) begin
        oursring_req_if_aw_t aw;

        for (int j=0; j<N_AXI_DATA_PER_CACHE_LINE; j++) begin
          oursring_req_if_w_t w;
          w = q_w[i].pop_front();
          req.data[j*AXI_DATA_WIDTH +: AXI_DATA_WIDTH] = w.wdata;
          req.mask[j*AXI_MASK_WIDTH +: AXI_MASK_WIDTH] = w.wstrb;
        end

        aw = q_aw[i].pop_front();
        req.addr = aw.awaddr;
        req.id = aw.awid;
        req.rw = '1;
        req.port_id = i;

        q_req.push_back(req);
        if (debug_info_deep) 
          $display("PMM-WRITE-REQ: addr=%h id=%h port=%h data=%h mask=%h size(q_req)=%-4d @ %t in %m", req.addr, req.id, req.port_id, req.data, req.mask, $size(q_req), $time());
      end // }}}

      // request queue -> response queue per bank, and process the request on memory {{{
      while ($size(q_req) > 0) begin
        int bank_id, delay;

        req = q_req.pop_front();
        req.addr[OFFSET_WIDTH-1:0] = '0;
        if (debug_info_deep) $display("PMM-PROCESS-REQ: rw=%b id=%h port_id=%0h @ %t in %m", req.rw, req.id, req.port_id, $time());

        resp.valid = '1;
        resp.id = req.id;
        resp.rw = req.rw;
        resp.port_id = req.port_id;

        if (req.rw) begin
          // write
          for (int k=0; k<(DATA_WIDTH/8); k++) begin
            if (req.mask[k]) begin
              bit [ADDR_WIDTH-1:0] addr;
              addr = req.addr + k - BASE_ADDR;
              mem[addr] = req.data[k*8 +: 8];
              if (debug_info_deep) $display("PMM-WRITE-BYTE: addr=%h data=%h", addr + BASE_ADDR, req.data[k*8 +: 8]);
            end
          end
        end else begin
          // read
          for (int k=0; k<(DATA_WIDTH/8); k++) begin
            bit [ADDR_WIDTH-1:0] addr;
            addr = req.addr + k - BASE_ADDR;
            if (mem.exists(addr)) begin
              resp.data[k*8 +: 8] = mem[addr];
              if (debug_info_deep) $display("PMM-READ-BYTE:  addr=%h data=%h", addr + BASE_ADDR, resp.data[k*8 +: 8]);
            end else begin
              bit [31:0] fake_data;
              fake_data = '0;
              resp.data[k*8 +: 8] = fake_data[addr[1:0]*8 +:8];
              if (debug_info_deep) $display("PMM-READ-BYTE-FAKE:  addr=%h data=%h", addr + BASE_ADDR, resp.data[k*8 +: 8]);
            end
          end
        end

        bank_id = get_bank_id(req.addr);
        q_bank_resp[bank_id].push_back(resp);
        if (debug_info_deep) $display("PMM-RESP-BANK: id=%h port_id=%0h bank_id=%h @ %t in %m", resp.id, resp.port_id, bank_id, $time());
      end
        // }}}

    end
  end
  // }}}

  //==========================================================
  // random delay {{{
  cache_resp_t      q_bank_resp_dly[N_BANK][$];
  generate
    for (genvar j=0; j<N_BANK; j++) begin : per_bank
      for (genvar k=0; k<N_THREAD_PER_BANK; k++) begin : per_thread
        always @ (posedge clk) begin
          if ($size(q_bank_resp[j]) > 0) begin
            cache_resp_t resp;
            int delay;

            resp = q_bank_resp[j].pop_front();
            delay = $urandom_range(MAX_DELAY_CYCLE);
            if (debug_info_deep) $display("PMM-RESP-BANK-DLY-IN: id=%h bank_id=%0h thread_id=%0h delay=%0d size(q_bank_resp[%0d])=%0d @ %t", resp.id, j, k, delay, j, $size(q_bank_resp[j]), $time());

            repeat (delay) @ (posedge clk);
            q_bank_resp_dly[j].push_back(resp);
            if (debug_info_deep) $display("PMM-RESP-BANK-DLY-OUT: id=%h bank_id=%0h thread_id=%0h delay=%0d size(q_bank_resp[%0d])=%0d @ %t", resp.id, j, k, delay, j, $size(q_bank_resp[j]), $time());
          end
        end // always
      end // for per_thread
    end // for per_bank
  endgenerate
  // }}}

  //==========================================================
  // process response {{{
  oursring_resp_if_r_t  q_r[N_PORT][$];
  oursring_resp_if_b_t  q_b[N_PORT][$];

  oursring_resp_if_t    axi_resp[N_PORT];

  // i/f <-> struct
  generate
    for (genvar i=0; i<N_PORT; i++) begin : resp_if_to_struct
      always @ (*) begin
        resp_if[i].rvalid = axi_resp[i].rvalid;
        axi_resp[i].rready = resp_if[i].rready;
        resp_if[i].bvalid = axi_resp[i].bvalid;
        axi_resp[i].bready = resp_if[i].bready;
        resp_if[i].r = axi_resp[i].r;
        resp_if[i].b = axi_resp[i].b;
        //`oursring_resp_if_master_assign(resp_if[i], axi_resp[i]);
      end
    end
  endgenerate
  
  always @ (posedge clk) begin
    if (~rstn) begin
      for (int i=0; i<N_PORT; i++) begin
        axi_resp[i].bvalid <= '0;
        axi_resp[i].rvalid <= '0;
        axi_resp[i].r.rlast <= '0;
      end
    end else begin
      // response per bank
      for (int i=0; i<N_PORT; i++) begin

        // axi queue: if axi_resp is accepted, remove it from the queue {{{
        // B
        if ((axi_resp[i].bready === '1) && (axi_resp[i].bvalid === '1)) begin // prev valid is accepted
          oursring_resp_if_b_t b;
          b = q_b[i].pop_front();
          if (debug_info) $display("PMM-PORT-B: id=%h size(q_b[%-4d])=%-4d @ %t in %m", b.bid, i, $size(q_b[i]), $time());
        end
        // R
        if ((axi_resp[i].rready === '1) && (axi_resp[i].rvalid === '1)) begin // prev valid is accepted
          oursring_resp_if_r_t r;
          r = q_r[i].pop_front();
          if (debug_info) $display("PMM-PORT-R: id=%h data=%h size(q_r[%-4d])=%-4d @ %t in %m", r.rid, r.rdata, i, $size(q_r[i]), $time());
        end
        // }}}

        // if axi queue is empty, move resp from q_bank_resp_dly into axi_resp {{{
        for (int j=0; j<N_BANK; j++) begin
          if (($size(q_bank_resp_dly[j]) > 0) && (q_bank_resp_dly[j][0].port_id == i)) begin
            if (q_bank_resp_dly[j][0].rw && ($size(q_b[i]) == 0)) begin // write resp
              cache_resp_t resp;
              oursring_resp_if_b_t b;

              resp = q_bank_resp_dly[j].pop_front();

              b.bid = resp.id;
              b.bresp = '0;

              q_b[i].push_back(b);
              if (debug_info_deep) $display("PMM-RESP-AXI-B: id=%h size(q_b[%-4d])=%-4d @ %t in %m", b.bid, i, $size(q_b[i]), $time());

              continue; // if already served write resp, don't serve read resp the same cycle
            end // write resp

            if (!q_bank_resp_dly[j][0].rw && ($size(q_r[i]) == 0)) begin // read resp
              cache_resp_t resp;
              oursring_resp_if_r_t r;

              resp = q_bank_resp_dly[j].pop_front();

              r.rid = resp.id;
              r.rresp = '0;

              for (int n=0; n<N_AXI_DATA_PER_CACHE_LINE; n++) begin
                r.rlast = '0;
                if (n == (N_AXI_DATA_PER_CACHE_LINE-1)) begin
                  r.rlast = '1;
                end
                r.rdata = resp.data[n*AXI_DATA_WIDTH +: AXI_DATA_WIDTH];

                q_r[i].push_back(r);

                if (debug_info_deep) $display("PMM-RESP-AXI-R: id=%h data=%h size(q_r[%-4d])=%-4d @ %t in %m", r.rid, r.rdata, i, $size(q_r[i]), $time());
              end // for N_AXI_DATA_PER_CACHE_LINE
            end // read resp
          end // if q_bank_resp_dly is not empty
        end // for N_BANK
        // }}}

        // drive axi_resp i/f {{{
        if ($size(q_b[i]) > 0) begin
          axi_resp[i].bvalid <= '1;
          axi_resp[i].b <= q_b[i][0];
        end else begin
          axi_resp[i].bvalid <= '0;
        end

        if ($size(q_r[i]) > 0) begin
          axi_resp[i].rvalid <= '1;
          axi_resp[i].r <= q_r[i][0];
        end else begin
          axi_resp[i].rvalid <= '0;
        end
        // }}}

      end // for N_PORT
    end
  end
  // }}}

  //==========================================================
  // backdoor access {{{

  function void set_byte (bit [ADDR_WIDTH-1:0] addr, bit [7:0] data);
    mem[addr] = data;
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

  // }}}

endmodule
