`timescale 1ns/1ns
module wmz_top;
    import riscv_pkg::*;
    import rvh_l1d_pkg::*;
    import uop_encoding_pkg::*;
    import rvh_pkg::*;
    import l1d_verif_pkg::*;

localparam LSQ_ENTRY_NUM = 8;
localparam MEMORY_PORT_NUM = 1;

localparam REQ_ENQUE_BASE_DELAY = 100;
localparam REQ_ENQUE_MAX_DELAY = 1;


// <> top
reg                                                                                                 clk;
reg                                                                                                 rst;
logic                                                                                                test_done;
logic                                                                                                test_succ;

// <> RCU
wire                                                                                                lsu_top_rdy;
logic                                                                                               lsu_top_rdy_q;
logic                                                                                               top_lsu_vld;
logic                                                                                               top_lsu_ls;
logic  [LDU_OP_WIDTH - 1 : 0]                                                                       top_lsu_ld_opcode;
logic  [STU_OP_WIDTH - 1 : 0]                                                                       top_lsu_st_opcode;
logic                                                                                               top_lsu_fenced;
logic  [XLEN - 1 : 0]                                                                               top_agu_virt_base;
logic  [XLEN - 1 : 0]                                                                               top_agu_virt_offset;
logic  [ROB_INDEX_WIDTH - 1 : 0]                                                                    top_lsu_rob_index;
logic  [PHY_REG_ADDR_WIDTH - 1 : 0]                                                                 top_lsu_rd_addr;
logic  [XLEN - 1 : 0]                                                                               top_lsu_data;
logic                                                                                               top_lsu_wakeup_vld;
logic  [ROB_INDEX_WIDTH - 1 : 0]                                                                    top_lsu_wakeup_rob_index;
wire                                                                                                lsu_top_comm_vld;
wire [ROB_INDEX_WIDTH - 1 : 0]                                                                      lsu_top_comm_rob_index;
wire                                                                                                lsu_top_exception_vld;
wire [EXCEPTION_CAUSE_WIDTH - 1 : 0]                                                                lsu_top_ecause;
//                                                      
// <> PRF                                                       
wire                                                                                                lsu_top_prf_wb_vld;
wire  [PHY_REG_ADDR_WIDTH - 1 : 0]                                                                  lsu_top_comm_rd_addr;
wire  [XLEN - 1 : 0]                                                                                lsu_top_comm_data;
    
// <> TLB                                                   
wire                                                                                                dtlb_lsu_rdy;
wire                                                                                                dtlb_lsu_vld; // should be the lsu_dtlb_iss_vld_o in last cycle
wire                                                                                                dtlb_lsu_hit;
wire  [PHYSICAL_ADDR_TAG_LEN - 1 : 0]                                                               dtlb_lsu_ptag;
wire                                                                                                dtlb_lsu_exception_vld;
wire  [EXCEPTION_CAUSE_WIDTH - 1 : 0]                                                               dtlb_lsu_ecause;
wire                                                                                                lsu_dtlb_iss_vld;
wire [VIRTUAL_ADDR_TAG_LEN - 1 : 0]                                                                 lsu_dtlb_iss_vtag;
wire [PMP_ACCESS_TYPE_WIDTH - 1 : 0]                                                                lsu_dtlb_iss_type;
    
// <> l1d   
// Load request                                                 
wire   [LSU_ADDR_PIPE_COUNT-1:0]                                                                    l1d_lsu_ld_req_rdy;
wire                                                                                                lsu_l1d_ld_req_vld;
wire  [     ROB_INDEX_WIDTH - 1 : 0]                                                                lsu_l1d_ld_req_rob_index;
wire  [    PHY_REG_ADDR_WIDTH - 1 : 0]                                                              lsu_l1d_ld_req_rd_addr; // no need
wire  [      LDU_OP_WIDTH - 1 : 0]                                                                  lsu_l1d_ld_req_opcode;
wire  [       L1D_INDEX_WIDTH - 1 : 0]                                                              lsu_l1d_ld_req_index; 
wire  [      L1D_OFFSET_WIDTH - 1 : 0]                                                              lsu_l1d_ld_req_offset; 
wire  [     L1D_TAG_WIDTH -1 : 0]                                                                   lsu_l1d_ld_req_vtag; 
// Store request                                                    
wire  [LSU_ADDR_PIPE_COUNT-1:0]                                                                     l1d_lsu_st_req_rdy;
wire                                                                                                lsu_l1d_st_req_vld;
wire                                                                                                lsu_l1d_st_req_is_fence;
wire  [     ROB_INDEX_WIDTH - 1 : 0]                                                                lsu_l1d_st_req_rob_index;
wire  [    PHY_REG_ADDR_WIDTH - 1 : 0]                                                              lsu_l1d_st_req_rd_addr;
wire  [      STU_OP_WIDTH - 1 : 0]                                                                  lsu_l1d_st_req_opcode; 
wire  [       PHYSICAL_ADDR_LEN - 1 : 0]                                                            lsu_l1d_st_req_paddr; 
wire  [              XLEN - 1 : 0]                                                                  lsu_l1d_st_req_data;
// ld replay: 1. mshr full or 2. stb partial hit                                                     
wire  [LSU_ADDR_PIPE_COUNT-1:0]                                                                     l1d_lsu_ld_replay_vld;
// wb       
wire  [LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT - 1 : 0]                                           l1d_lsu_wb_vld;
wire  [(LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT) * ROB_INDEX_WIDTH - 1 : 0]                       l1d_lsu_wb_rob_index;
wire  [LSU_DATA_PIPE_COUNT - 1 : 0]                                                                 l1d_lsu_prf_wb_vld;
wire  [PHY_REG_ADDR_WIDTH * LSU_DATA_PIPE_COUNT - 1 : 0]                                            l1d_lsu_prf_wb_rd_addr;
wire  [XLEN*LSU_DATA_PIPE_COUNT - 1 : 0]                                                            l1d_lsu_prf_wb_data;
// kill                                                     
wire                                                                                                lsu_l1d_kill_req;
// AR
wire                    [MEMORY_PORT_NUM - 1 : 0]                                                                      l2_req_if_arvalid;
wire                    [MEMORY_PORT_NUM - 1 : 0]                                                                      l2_req_if_arready;
wire cache_mem_if_ar_t  [MEMORY_PORT_NUM - 1 : 0]                                                                      l2_req_if_ar     ;
// ewrq -> mem bus                                            
// AW                                             
wire                    [MEMORY_PORT_NUM - 1 : 0]                                                                      l2_req_if_awvalid;
wire                    [MEMORY_PORT_NUM - 1 : 0]                                                                      l2_req_if_awready;
wire cache_mem_if_aw_t  [MEMORY_PORT_NUM - 1 : 0]                                                                      l2_req_if_aw     ;
// W                                                                 
wire                    [MEMORY_PORT_NUM - 1 : 0]                                                                      l2_req_if_wvalid ;
wire                    [MEMORY_PORT_NUM - 1 : 0]                                                                      l2_req_if_wready ;
wire cache_mem_if_w_t   [MEMORY_PORT_NUM - 1 : 0]                                                                      l2_req_if_w      ;
// B                                                                 
wire                    [MEMORY_PORT_NUM - 1 : 0]                                                                      l2_resp_if_bvalid;
wire                    [MEMORY_PORT_NUM - 1 : 0]                                                                      l2_resp_if_bready;
wire  cache_mem_if_b_t  [MEMORY_PORT_NUM - 1 : 0]                                                                      l2_resp_if_b     ; 
// mem bus -> mlfb                                            
// R                                                                 
wire                    [MEMORY_PORT_NUM - 1 : 0]                                                                      l2_resp_if_rvalid;
wire                    [MEMORY_PORT_NUM - 1 : 0]                                                                      l2_resp_if_rready;    
wire cache_mem_if_r_t   [MEMORY_PORT_NUM - 1 : 0]                                                                      l2_resp_if_r     ; 

wire                                                                       ls_pipe_l1d_dtlb_resp_vld;
wire [         PPN_WIDTH-1:0]                                              ls_pipe_l1d_dtlb_resp_ppn;
wire                                                                       ls_pipe_l1d_dtlb_resp_excp_vld;
wire                                                                       ls_pipe_l1d_dtlb_resp_hit;
wire                                                                       ls_pipe_l1d_dtlb_resp_miss;

// mmu & dtlb
// priv lvl
logic       [                 1:0]                  priv_lvl;
// stap                 
logic       [                 3:0]                  satp_mode;
logic       [      ASID_WIDTH-1:0]                  satp_asid;
logic       [       PPN_WIDTH-1:0]                  satp_ppn;
                
logic       [            XLEN-1:0]                  misc_mstatus;

// PMP Configuration Port
logic                                               pmp_cfg_set_vld;
logic       [ PMPCFG_ID_WIDTH-1:0]                  pmp_cfg_set_addr;
logic       [                63:0]                  pmp_cfg_set_payload;
logic      [                63:0]                   pmp_cfg_origin_payload;
logic                                               pmp_addr_set_vld;
logic       [PMPADDR_ID_WIDTH-1:0]                  pmp_addr_set_addr;
logic       [                63:0]                  pmp_addr_set_payload;
logic      [                63:0]                   pmp_addr_origin_payload; 




// DTLB Translate Port -> Request
logic [TRANSLATE_WIDTH-1:0]                         dtlb_translate_req_vld;
logic [TRANSLATE_WIDTH-1:0][1:0]                    dtlb_translate_req_access_type;
logic [TRANSLATE_WIDTH-1:0][VPN_WIDTH-1:0]          dtlb_translate_req_vpn;
logic [TRANSLATE_WIDTH-1:0]                         dtlb_translate_req_rdy;
// DTLB Translate Port -> Response
logic [TRANSLATE_WIDTH-1:0]                         dtlb_translate_resp_vld;
logic [TRANSLATE_WIDTH-1:0][PPN_WIDTH-1:0]          dtlb_translate_resp_ppn;
logic [TRANSLATE_WIDTH-1:0]                         dtlb_translate_resp_excp_vld;
logic [TRANSLATE_WIDTH-1:0][EXCP_CAUSE_WIDTH-1:0]   dtlb_translate_resp_excp_cause;
logic [TRANSLATE_WIDTH-1:0]                         dtlb_translate_resp_miss;
logic [TRANSLATE_WIDTH-1:0]                         dtlb_translate_resp_hit;

// ITLB Translate Port -> Request
logic [TRANSLATE_WIDTH-1:0]                         itlb_translate_req_vld;
// MODE == Read(Execute)
// logic [TRANSLATE_WIDTH-1:0][1:0] itlb_translate_req_access_type;
logic [TRANSLATE_WIDTH-1:0][VPN_WIDTH-1:0]          itlb_translate_req_vpn;
logic [TRANSLATE_WIDTH-1:0]                         itlb_translate_req_rdy;
// ITLB Translate Port -> Response
logic [TRANSLATE_WIDTH-1:0]                         itlb_translate_resp_vld;
logic [TRANSLATE_WIDTH-1:0][PPN_WIDTH-1:0]          itlb_translate_resp_ppn;
logic [TRANSLATE_WIDTH-1:0]                         itlb_translate_resp_excp_vld;
logic [TRANSLATE_WIDTH-1:0][EXCP_CAUSE_WIDTH-1:0]   itlb_translate_resp_excp_cause;
logic [TRANSLATE_WIDTH-1:0]                         itlb_translate_resp_miss;
logic [TRANSLATE_WIDTH-1:0]                         itlb_translate_resp_hit;


// dtlb shoot down
logic                                               dtlb_flush_vld;
logic                                               dtlb_flush_use_asid;
logic                                               dtlb_flush_use_vpn;
logic [VPN_WIDTH-1:0]                               dtlb_flush_vpn;
logic [ASID_WIDTH-1:0]                              dtlb_flush_asid;
logic                                               dtlb_flush_grant;
// itlb shoot down
logic                                               itlb_flush_vld;
logic                                               itlb_flush_use_asid;
logic                                               itlb_flush_use_vpn;
logic [VPN_WIDTH-1:0]                               itlb_flush_vpn;
logic [ASID_WIDTH-1:0]                              itlb_flush_asid;
logic                                               itlb_flush_grant;

logic                                               tlb_flush_grant;


// ptw walk request port
logic                                               ptw_walk_req_vld;
logic [PTW_ID_WIDTH-1:0]                            ptw_walk_req_id;
logic [PADDR_WIDTH-1:0]                             ptw_walk_req_addr;
logic                                               ptw_walk_req_rdy;
// ptw walk response port
logic                                               ptw_walk_resp_vld;
logic [PTE_WIDTH-1:0]                               ptw_walk_resp_pte;
logic                                               ptw_walk_resp_rdy;






lsu_req_t req_q[$];
lsu_req_t req_wait_q[$];
lsu_req_t iss_q[$];
bit [PADDR_WIDTH - 1 : 0] addr;
bit [XLEN - 1 : 0] correct_data;

string dump_file_dir;
string log_msg;

int req_done_cnt;
int req_done_cnt_q;
int req_iss_cnt;
int printed_flag;
int timeout_cnt;

int last_rob_index_send;


initial begin
    req_done_cnt = 0;
    req_iss_cnt = 0;
    req_done_cnt_q = 0;
    printed_flag = 0;
    timeout_cnt = 0;
    last_rob_index_send = 15;
    ERROR_LOG_HANDLE = $fopen(`ERROR_LOG_DIR);
end



initial begin
    $display("========= lsu_l1d test started =========");
`ifndef NO_WAVE
    $sformat(dump_file_dir, "%s/waves/wmz_top.vcd", `SIM_DIR);
    $dumpfile(dump_file_dir);
    $dumpvars(0, wmz_top);

    $sformat(dump_file_dir, "%s/waves/wmz_top.fsdb", `SIM_DIR);
    $fsdbDumpfile(dump_file_dir);  //记录波形，波形名字testname.fsdb
    $fsdbDumpvars("+all");  //+all参数，dump SV中的struct结构体
    // $fsdbDumpSVA();   //将assertion的结果存在fsdb中
    $fsdbDumpMDA(0, wmz_top);  //dump memory arrays
`endif // NO_WAVE


    correct_mem.init();
    real_mem.init();
    // init
// `ifdef LOG_LV1
//     $display("\t===== request list =====");
// `endif // LOG_LV1
//     for(int i = 0; i < `RANDOM_TESTCASE_NUM; i ++) begin
//         req_wait_q.push_back(gen_random_req(i));
//     end
// `ifdef LOG_LV1
//     $display("\t===== request list =====");
// `endif // LOG_LV1

    //check page table

    $display("check mem @ %x: %x", 56'h80000000, correct_mem.get_word(56'h80000000));
    $display("check mem @ %x: %x", 56'h80000008, correct_mem.get_word(56'h80000008));
    $display("check mem @ %x: %x", 56'h80000010, correct_mem.get_word(56'h80000010));
    

    $display("check pagetable @ %x: %x", 56'h10000000, correct_mem.get_pte(56'h10000000));
    $display("check pagetable @ %x: %x", 56'h10000008, correct_mem.get_pte(56'h10000008));
    $display("check pagetable @ %x: %x", 56'h10000010, correct_mem.get_pte(56'h10000010));

    rst = '1;
    clk = '0;
    #100 
    rst = '0;
    #`MAX_TIME // run time (ns)
    $display("lsu_l1d test failed: time limit reached. %d cases done", req_done_cnt);
    $fclose(ERROR_LOG_HANDLE);
    $finish;
end

always #20 clk = ~clk;


// assign top_lsu_vld = ($size(req_q) > 0) & ~rst;

// TODO: wake up immediately
always @(posedge clk) begin
    if(~rst) begin
        if(lsu_l1d_ld_req_vld | lsu_l1d_st_req_vld) begin
            if(lsu_l1d_ld_req_vld) begin
                if(last_rob_index_send > lsu_l1d_ld_req_rob_index) begin
                    if(last_rob_index_send != 15 && lsu_l1d_ld_req_rob_index != 0) begin
                        error_quit("lsq wrong order");
                    end
                    last_rob_index_send = 0;
                end
            end
            else begin
                if(last_rob_index_send > lsu_l1d_st_req_rob_index) begin
                    if(last_rob_index_send != 15 && lsu_l1d_st_req_rob_index != 0) begin
                        error_quit("lsq wrong order");
                    end
                    last_rob_index_send = 0;
                end
            end
            if(l1d_lsu_ld_replay_vld) begin
                last_rob_index_send = lsu_l1d_ld_req_rob_index;
            end
        end
    end
end
always @(posedge clk) begin
    if(~rst) begin
        if(req_iss_cnt < `RANDOM_TESTCASE_NUM && $size(req_q) < ROB_SIZE)begin
            int delay;
            int tmp_delay;
            lsu_req_t req;
            bit[VADDR_WIDTH - 1 : 0] vaddr;
            // delay = REQ_ENQUE_BASE_DELAY + $urandom_range(REQ_ENQUE_MAX_DELAY);
            // delay = 1;
            // repeat(delay) @(posedge clk);
            req = gen_random_req(req_iss_cnt);
            req_q.push_back(req);
            vaddr = req.vaddr();
            if(vaddr[31:3] == (32'h8000d6f4 >> 3)) begin
                $display("%s", req.to_string());
            end
            req_iss_cnt = req_iss_cnt + 1;
            // if({req_wait_q[0].vtag, req_wait_q[0].index, req_wait_q[0].offset}[31:0] == 32'h8000a7b8) begin
            //     $display("%s", req_wait_q[0].to_string());
            //     // tmp_delay = 200;
            //     // repeat(tmp_delay) @(posedge clk);
            //     // $finish;
            // end
            // req_wait_q.pop_front();
        end
    end
end
always @(posedge clk) begin
    if(~rst) begin
        // assert(~l1d_lsu_ld_replay_vld);
        if(test_done) begin
            $display("=========test success========");
            $display("%d cases done", req_done_cnt);
            $display("=========test success========");
            $finish;
        end
        if(req_done_cnt_q < req_done_cnt) begin
            timeout_cnt = 0;
            req_done_cnt_q = req_done_cnt;
        end
        else begin
            timeout_cnt = timeout_cnt + 1;
            if(timeout_cnt > 2000) begin
                error_quit("time out kill");
                $finish;
            end
        end
    end
end

always @(posedge clk) begin
    if(~rst) begin
        if(req_done_cnt > 0 && (req_done_cnt % 100 == 0) & (printed_flag == 1)) begin
            $display("==============================");
            $display($realtime, "time taken");
            $display("%d cases done", req_done_cnt);
            $display("==============================");
            printed_flag = 0;
        end
        if(req_done_cnt > 0 && (req_done_cnt % 100 == 1)) begin
            printed_flag = 1;
        end
    end
end
`ifdef LOG_LV1
always @(posedge clk) begin
    if(~rst && l1d_lsu_ld_replay_vld) begin
        $display($realtime, ":\t replay");
    end
end
`endif // LOG_LV1

always @(posedge clk) begin
    if(rst) begin
        test_done <= '0;

        top_lsu_vld <= '0;
        top_lsu_ls <= '0;
        top_lsu_ld_opcode <= '0;
        top_lsu_st_opcode <= '0;
        top_lsu_fenced <= '0;
        top_agu_virt_base <= '0;
        top_agu_virt_offset <= '0;
        top_lsu_rob_index <= '0;
        top_lsu_rd_addr <= '0;
        top_lsu_data <= '0;

        top_lsu_wakeup_vld <= '0;
        top_lsu_wakeup_rob_index <= '0;

        lsu_top_rdy_q <= '0;
    end
    else begin
        lsu_top_rdy_q <= lsu_top_rdy;
        test_done <= (req_done_cnt == `RANDOM_TESTCASE_NUM);
        // req_q -> iss_q
        if(top_lsu_vld & lsu_top_rdy) begin //hsk
`ifdef LOG_LV1
            $display($realtime, ":\ttop req sent\t%s", req_q[0].to_string());
`endif // LOG_LV1
            iss_q.push_back(req_q[0]);
            req_q.pop_front();
        end
        if($size(req_q) > 0) begin
            top_lsu_vld <= ~rst;
            top_lsu_ls <= req_q[0].is_load_or_store;
            top_lsu_ld_opcode <= req_q[0].ld_opcode;
            top_lsu_st_opcode <= req_q[0].st_opcode;
            top_lsu_fenced <= req_q[0].is_fence;
            top_agu_virt_base <= {req_q[0].vtag, req_q[0].index, req_q[0].offset};
            top_agu_virt_offset <= 0;
            top_lsu_rob_index <= req_q[0].rob_index;
            top_lsu_rd_addr <= req_q[0].rd_addr;
            top_lsu_data <= req_q[0].data;
        end
        else begin
            top_lsu_vld <= '0;
        end

        if($size(req_q) > 0) begin //wake up hand shake
            top_lsu_wakeup_vld <= '1;
            top_lsu_wakeup_rob_index <= req_q[0].rob_index;
        end
        else begin
            top_lsu_wakeup_vld <= '0;
        end
        

        // handle comm resp
        if(lsu_top_comm_vld) begin
            bit flag = 0;
            assert($size(iss_q) > 0);
            for(int i = 0; i < $size(iss_q); i = i + 1) begin
                if(iss_q[i].rob_index == lsu_top_comm_rob_index) begin
                    iss_q[i].success = 1;
                    if(lsu_top_comm_rd_addr != 0)
                        iss_q[i].data = lsu_top_comm_data;
                    flag = 1;
`ifdef LOG_LV1
                    $display($realtime, ":\ttop resp recieved\t%s", iss_q[i].to_string());
`endif // LOG_LV1
                end
            end
            prf_wb_a: assert(flag == 1)
            else $error("comm wb rob index is not avaible in iss_q");
        end
        // commit req
        while($size(iss_q) > 0 && iss_q[0].success == 1) begin
// `ifdef LOG_LV1
//             $display($realtime, ":\ttop resp recieved\t%s", iss_q[0].to_string());
// `endif // LOG_LV1
            if(iss_q[0].is_load_or_store) begin // store
                int pt;
                pt = 0;
                addr = {iss_q[0].ptag, iss_q[0].index, iss_q[0].offset[L1D_OFFSET_WIDTH - 1 : 3], 3'b000};
                // $display("%s", iss_q[0].to_string());
                for(int i = 0; i < (XLEN / 8); i ++) begin
`ifdef PERFECT_MEMORY
                    if(iss_q[0].mask[i] == 1) begin
                        // $display("%x @ %x", iss_q[0].data[8 * pt +: 8], addr + i);
                        correct_mem.set_byte(addr + i, iss_q[0].data[8 * pt +: 8]);
                        pt = pt + 1;
                    end
`endif //PERFECT_MEMORY
                end
            end
            else begin // load
                // $display("ld");
`ifdef PERFECT_MEMORY
                correct_data = 0;
                addr = {iss_q[0].ptag, iss_q[0].index, iss_q[0].offset};

                if(iss_q[0].size() == 2'b00) begin
                    correct_data[7:0] = correct_mem.get_byte(addr);
                end
                else if(iss_q[0].size() == 2'b01) begin
                    correct_data[15:0] = correct_mem.get_hword(addr);
                end
                else if(iss_q[0].size() == 2'b10) begin
                    correct_data[31:0] = correct_mem.get_word(addr);
                end
                else begin
                    correct_data[63:0] = correct_mem.get_dword(addr);
                end
                // if(iss_q[0].mask[i] == 1) begin
                //     correct_data[pt * 8 +: 8] = correct_mem.get_byte(addr + i);
                //     pt = pt + 1;
                // end
                if(~iss_q[0].is_unsigend()&& (iss_q[0].size() != 2'b11) && correct_data[(1 << iss_q[0].size()) * 8 - 1 +: 1]) begin
                    correct_data = ({XLEN{1'b1}} << ((1 << iss_q[0].size()) * 8)) | correct_data;
                end
                if(correct_data != iss_q[0].data) begin
                    string msg;
                    $sformat(msg, "%s failed\nload %s fail @ %x. real:%x - correct:%x ", iss_q[0].to_string(), iss_q[0].ld_opcode.name(), {iss_q[0].vtag, iss_q[0].index, iss_q[0].offset}, iss_q[0].data, correct_data);
                    error_quit(msg);
                    // $error(msg);
                    // assert(0);
                end
`endif //PERFECT_MEMORY
            end
`ifdef LOG_LV1
            $display($realtime, ":\ttop commit\t%s", iss_q[0].to_string());
`endif // LOG_LV1
            iss_q.pop_front();
            req_done_cnt = req_done_cnt + 1;
        end
    end
end

lsuv1 #(
    .LSQ_ENTRY_NUM(LSQ_ENTRY_NUM),
    .LSQ_ENTRY_NUM_WIDTH($clog2(LSQ_ENTRY_NUM))
)lsu(
    .clk(clk),
    .rst(rst),
    .flush('0),

    // <> top
    .lsu_rdy_o(lsu_top_rdy),
    .rcu_lsu_vld_i(top_lsu_vld),
    .rcu_lsu_ls_i(top_lsu_ls),
    .rcu_lsu_ld_opcode_i(top_lsu_ld_opcode),
    .rcu_lsu_st_opcode_i(top_lsu_st_opcode),
    .rcu_lsu_fenced_i(top_lsu_fenced),
    .rcu_agu_virt_base_i(top_agu_virt_base),
    .rcu_agu_virt_offset_i(top_agu_virt_offset),
    .rcu_lsu_rob_index_i(top_lsu_rob_index),
    .rcu_lsu_rd_addr_i(top_lsu_rd_addr),
    .rcu_lsu_data_i(top_lsu_data),
    .rcu_lsu_wakeup_i(top_lsu_wakeup_vld),
    .rcu_lsu_wakeup_rob_index_i(top_lsu_wakeup_rob_index),
    .lsu_rcu_comm_vld_o(lsu_top_comm_vld),
    .lsu_rcu_comm_rob_index_o(lsu_top_comm_rob_index),
    .lsu_rcu_comm_rd_addr_o(lsu_top_comm_rd_addr),
    .lsu_rcu_comm_data_o(lsu_top_comm_data),
    .lsu_rcu_exception_vld_o(lsu_top_exception_vld),
    .lsu_rcu_ecause_o(lsu_top_ecause),
    // <> dtlb
    .dtlb_lsu_rdy_i(dtlb_lsu_rdy),
    .dtlb_lsu_vld_i(dtlb_lsu_vld),
    .dtlb_lsu_hit_i(dtlb_lsu_hit),
    .dtlb_lsu_ptag_i(dtlb_lsu_ptag),
    .dtlb_lsu_exception_vld_i(dtlb_lsu_exception_vld),
    .dtlb_lsu_ecause_i(dtlb_lsu_ecause),
    .lsu_dtlb_iss_vld_o(lsu_dtlb_iss_vld),
    .lsu_dtlb_iss_vtag_o(lsu_dtlb_iss_vtag),
    .lsu_dtlb_iss_type_o(lsu_dtlb_iss_type),
    // <> l1d
    .l1d_lsu_ld_req_rdy_i(l1d_lsu_ld_req_rdy[0]),
    .lsu_l1d_ld_req_vld_o(lsu_l1d_ld_req_vld),
    .lsu_l1d_ld_req_rob_index_o(lsu_l1d_ld_req_rob_index),
    .lsu_l1d_ld_req_rd_addr_o(lsu_l1d_ld_req_rd_addr),
    .lsu_l1d_ld_req_opcode_o(lsu_l1d_ld_req_opcode),
    .lsu_l1d_ld_req_index_o(lsu_l1d_ld_req_index),
    .lsu_l1d_ld_req_offset_o(lsu_l1d_ld_req_offset),
    .lsu_l1d_ld_req_vtag_o(lsu_l1d_ld_req_vtag),

    .l1d_lsu_st_req_rdy_i(l1d_lsu_st_req_rdy[0]),
    .lsu_l1d_st_req_vld_o(lsu_l1d_st_req_vld),
    .lsu_l1d_st_req_is_fence_o(lsu_l1d_st_req_is_fence),
    .lsu_l1d_st_req_rob_index_o(lsu_l1d_st_req_rob_index),
    .lsu_l1d_st_req_rd_addr_o(lsu_l1d_st_req_rd_addr),
    .lsu_l1d_st_req_opcode_o(lsu_l1d_st_req_opcode),
    .lsu_l1d_st_req_paddr_o(lsu_l1d_st_req_paddr),
    .lsu_l1d_st_req_data_o(lsu_l1d_st_req_data),

    .l1d_lsu_ld_replay_vld_i(l1d_lsu_ld_replay_vld[0]),
    
    .l1d_lsu_wb_vld_i(l1d_lsu_wb_vld),
    .l1d_lsu_wb_rob_index_i(l1d_lsu_wb_rob_index),
    .l1d_lsu_prf_wb_vld_i(l1d_lsu_prf_wb_vld),
    .l1d_lsu_prf_wb_rd_addr_i(l1d_lsu_prf_wb_rd_addr),
    .l1d_lsu_prf_wb_data_i(l1d_lsu_prf_wb_data),

    .lsu_l1d_kill_req_o(lsu_l1d_kill_req),
`ifdef LSU_DEBUG
/* verilator lint_off PINCONNECTEMPTY */
    .lsu_debug_head_o(),
    .lsu_debug_tail_o(),
    .lsu_debug_issued_o(),
    .lsu_debug_iss_vld_o(),
    .lsu_debug_iss_is_fenced_o(),
    .lsu_debug_iss_lsq_index_o(),
/* verilator lint_on PINCONNECTEMPTY */
`endif // LSU_DEBUG 
    // <> bus
    .lsu_wb_cyc_o(),
    .lsu_wb_stb_o(),
    .lsu_wb_we_o(),
    .lsu_wb_adr_o(),
    .lsu_wb_dat_o(),
    .lsu_wb_sel_o(),
    .wb_lsu_ack_i('0),
    .wb_lsu_dat_i('0)
);
`ifdef PERFECT_MEMORY
perfect_memory 
#(
    .N_PORT(MEMORY_PORT_NUM),
    .N_BANK(1),
    .CACHELINE_WIDTH(L1D_BANK_LINE_DATA_SIZE),
    .FAKE_MEMORY_SIZE(FAKE_MEMORY_WIDTH),
    .ADDR_WIDTH(PADDR_WIDTH),
    .ID_WIDTH(12),
    .N_THREAD_PER_BANK(4),
    .MAX_DELAY_CYCLE(10)
) correct_mem
(
    .l2_req_if_arvalid_i('0),
    .l2_req_if_arready_o(),
    .l2_req_if_ar_i     ('0),
    
    .l2_req_if_awvalid_i('0),
    .l2_req_if_awready_o(),
    .l2_req_if_aw_i     ('0),
    
    .l2_req_if_wvalid_i ('0),
    .l2_req_if_wready_o (),
    .l2_req_if_w_i      ('0),
    
    .l2_resp_if_bvalid_o(),
    .l2_resp_if_bready_i('0),
    .l2_resp_if_b_o     (), 

    .l2_resp_if_rvalid_o(),
    .l2_resp_if_rready_i('0),    
    .l2_resp_if_r_o     (), 

    .clk(clk),
    .rst(rst)
);

perfect_memory 
#(
    .N_PORT(MEMORY_PORT_NUM),
    .N_BANK(1),
    .CACHELINE_WIDTH(L1D_BANK_LINE_DATA_SIZE),
    .FAKE_MEMORY_SIZE(FAKE_MEMORY_WIDTH),
    .ADDR_WIDTH(PADDR_WIDTH),
    .N_THREAD_PER_BANK(4),
    .MAX_DELAY_CYCLE(10)
) real_mem
(
    .l2_req_if_arvalid_i(l2_req_if_arvalid),
    .l2_req_if_arready_o(l2_req_if_arready),
    .l2_req_if_ar_i     (l2_req_if_ar),
    
    .l2_req_if_awvalid_i(l2_req_if_awvalid),
    .l2_req_if_awready_o(l2_req_if_awready),
    .l2_req_if_aw_i     (l2_req_if_aw),
    
    .l2_req_if_wvalid_i (l2_req_if_wvalid),
    .l2_req_if_wready_o (l2_req_if_wready),
    .l2_req_if_w_i      (l2_req_if_w),
    
    .l2_resp_if_bvalid_o(l2_resp_if_bvalid),
    .l2_resp_if_bready_i(l2_resp_if_bready),
    .l2_resp_if_b_o     (l2_resp_if_b), 

    .l2_resp_if_rvalid_o(l2_resp_if_rvalid),
    .l2_resp_if_rready_i(l2_resp_if_rready),    
    .l2_resp_if_r_o     (l2_resp_if_r), 

    .clk(clk),
    .rst(rst)
);
`else //PERFECT_MEMORY
generate 
for(genvar i = 0; i < MEMORY_PORT_NUM; i ++) begin
    assign l2_req_if_arready[i] = '1;
    assign l2_req_if_awready[i] = '1;
    assign l2_req_if_wready[i] = '1;

    assign l2_resp_if_bvalid[i] = '0;
    assign l2_resp_if_b[i] = '0;
    assign l2_resp_if_rvalid[i] = '0;
    assign l2_resp_if_r[i] = '0;
end
endgenerate
`endif // PERFECT_MEMORY
`ifdef RVH_L1D
wmz_l1d l1d(
    .ls_pipe_l1d_ld_req_vld_i(lsu_l1d_ld_req_vld),
    .ls_pipe_l1d_ld_req_rob_tag_i(lsu_l1d_ld_req_rob_index),
    .ls_pipe_l1d_ld_req_prd_i(lsu_l1d_ld_req_rd_addr),
    .ls_pipe_l1d_ld_req_opcode_i(lsu_l1d_ld_req_opcode),
    .ls_pipe_l1d_ld_req_idx_i(lsu_l1d_ld_req_index), //
    .ls_pipe_l1d_ld_req_offset_i(lsu_l1d_ld_req_offset), //
    .ls_pipe_l1d_ld_req_vtag_i(lsu_l1d_ld_req_vtag), // vtag
    .ls_pipe_l1d_ld_req_rdy_o(l1d_lsu_ld_req_rdy),

    // LS Pipe -> D$ : DTLB response
    .dtlb_l1d_resp_vld_i(ls_pipe_l1d_dtlb_resp_vld),
    .dtlb_l1d_resp_ppn_i(ls_pipe_l1d_dtlb_resp_ppn),
    .dtlb_l1d_resp_excp_vld_i(ls_pipe_l1d_dtlb_resp_excp_vld),
    .dtlb_l1d_resp_hit_i(ls_pipe_l1d_dtlb_resp_hit),
    // .ls_pipe_l1d_dtlb_resp_miss_i(ls_pipe_l1d_dtlb_resp_miss),

    // LS Pipe -> D$ : Store request
    .ls_pipe_l1d_st_req_vld_i(lsu_l1d_st_req_vld),
    .ls_pipe_l1d_st_req_io_region_i('0),
    .ls_pipe_l1d_st_req_is_fence_i(lsu_l1d_st_req_is_fence),
    .ls_pipe_l1d_st_req_rob_tag_i(lsu_l1d_st_req_rob_index),
    .ls_pipe_l1d_st_req_prd_i(lsu_l1d_st_req_rd_addr),
    .ls_pipe_l1d_st_req_opcode_i(lsu_l1d_st_req_opcode),
    .ls_pipe_l1d_st_req_paddr_i(lsu_l1d_st_req_paddr), //
    .ls_pipe_l1d_st_req_data_i(lsu_l1d_st_req_data),
    .ls_pipe_l1d_st_req_rdy_o(l1d_lsu_st_req_rdy),
    // L1D -> LS Pipe ld replay: 1. mshr full or 2. stb partial hit 
    .l1d_ls_pipe_replay_vld_o(l1d_lsu_ld_replay_vld),


    // LS Pipe -> L1D : Kill D-Cache Response
    .lsu_l1d_s2_kill_valid_i(lsu_l1d_kill_req),
    // D$ -> ROB : Write Back
    .l1d_rob_wb_vld_o(l1d_lsu_wb_vld),
    .l1d_rob_wb_rob_tag_o(l1d_lsu_wb_rob_index),
    // D$ -> Int PRF : Write Back
    .l1d_int_prf_wb_vld_o(l1d_lsu_prf_wb_vld),
    .l1d_int_prf_wb_tag_o(l1d_lsu_prf_wb_rd_addr),
    .l1d_int_prf_wb_data_o(l1d_lsu_prf_wb_data),


    // ptw walk request port
    .ptw_walk_req_vld_i(ptw_walk_req_vld),
    .ptw_walk_req_id_i(0),
    .ptw_walk_req_addr_i(ptw_walk_req_addr),
    .ptw_walk_req_rdy_o(ptw_walk_req_rdy),
    // ptw walk response port
    .ptw_walk_resp_vld_o(ptw_walk_resp_vld),
    .ptw_walk_resp_id_o(),
    .ptw_walk_resp_pte_o(ptw_walk_resp_pte),
    .ptw_walk_resp_rdy_i(ptw_walk_resp_rdy),

    // L1D -> L2 : Request
      // mshr -> mem bus
      // AR
    .l2_req_if_arvalid(l2_req_if_arvalid[0]),
    .l2_req_if_arready(l2_req_if_arready[0]),
    .l2_req_if_ar(l2_req_if_ar[0]),
      // ewrq -> mem bus
      // AW 
    .l2_req_if_awvalid(l2_req_if_awvalid[0]),
    .l2_req_if_awready(l2_req_if_awready[0]),
    .l2_req_if_aw(l2_req_if_aw[0]),
      // W 
    .l2_req_if_wvalid(l2_req_if_wvalid[0]),
    .l2_req_if_wready(l2_req_if_wready[0]),
    .l2_req_if_w(l2_req_if_w[0]),
    // L1D -> L2 : Response
      // B
    .l2_resp_if_bvalid(l2_resp_if_bvalid[0]),
    .l2_resp_if_bready(l2_resp_if_bready[0]),
    .l2_resp_if_b(l2_resp_if_b[0]),
      // mem bus -> mlfb
      // R
    .l2_resp_if_rvalid(l2_resp_if_rvalid[0]),
    .l2_resp_if_rready(l2_resp_if_rready[0]),
    .l2_resp_if_r(l2_resp_if_r[0]),


    .rob_flush_i('0),

    .fencei_flush_vld_i('0),
    .fencei_flush_grant_o(),

    .clk(clk),
    .rst(~rst)
);
`else // RVH_L1D
// rvh_l1d_bank l1d(
//     .ls_pipe_l1d_ld_req_vld_i(lsu_l1d_ld_req_vld),
//     .ls_pipe_l1d_ld_req_rob_tag_i(lsu_l1d_ld_req_rob_index),
//     .ls_pipe_l1d_ld_req_prd_i(lsu_l1d_ld_req_rd_addr),
//     .ls_pipe_l1d_ld_req_opcode_i(lsu_l1d_ld_req_opcode),
//     .ls_pipe_l1d_ld_req_index_i(lsu_l1d_ld_req_index), //
//     .ls_pipe_l1d_ld_req_offset_i(lsu_l1d_ld_req_offset), //
//     .ls_pipe_l1d_ld_req_vtag_i(lsu_l1d_ld_req_vtag), // vtag
//     .stb_l1d_ld_rdy_i('1),
//     .ls_pipe_l1d_ld_req_rdy_o(l1d_lsu_ld_req_rdy[0]),
//     .ls_pipe_l1d_ld_kill_i(lsu_l1d_kill_req),
//     .ls_pipe_l1d_ld_rar_fail_i('0),

//     // LS Pipe -> D$ : DTLB response
//     .ls_pipe_l1d_dtlb_resp_vld_i(ls_pipe_l1d_dtlb_resp_vld),
//     .ls_pipe_l1d_dtlb_resp_ppn_i(ls_pipe_l1d_dtlb_resp_ppn),
//     .ls_pipe_l1d_dtlb_resp_excp_vld_i(ls_pipe_l1d_dtlb_resp_excp_vld),
//     .ls_pipe_l1d_dtlb_resp_hit_i(ls_pipe_l1d_dtlb_resp_hit),
//     .ls_pipe_l1d_dtlb_resp_miss_i(ls_pipe_l1d_dtlb_resp_miss),

//     // LS Pipe -> D$ : Store request
//     .ls_pipe_l1d_st_req_vld_i(lsu_l1d_st_req_vld),
//     .ls_pipe_l1d_st_req_io_region_i('0), // check later
//     .ls_pipe_l1d_st_req_is_fence_i({1'b0, lsu_l1d_st_req_is_fence}),
//     .ls_pipe_l1d_st_req_rob_tag_i(lsu_l1d_st_req_rob_index),
//     .ls_pipe_l1d_st_req_prd_i(lsu_l1d_st_req_rd_addr),
//     .ls_pipe_l1d_st_req_opcode_i(lsu_l1d_st_req_opcode),
//    .ls_pipe_l1d_st_req_paddr_i(lsu_l1d_st_req_paddr), //
//    .ls_pipe_l1d_st_req_data_i(lsu_l1d_st_req_data),
//    .ls_pipe_l1d_st_req_rdy_o(l1d_lsu_st_req_rdy[0]),

//    .ls_pipe_l1d_st_req_data_byte_mask_i(),
//    .ls_pipe_l1d_st_req_sc_rt_check_succ_i(), // sc
//    .ls_pipe_l1d_st_req_sc_amo_offset_i(), // amo
//     // L1D -> LS Pipe ld replay: 1. mshr full or 2. stb partial hit 
//     .l1d_ls_pipe_replay_vld_o(l1d_lsu_ld_replay_vld[0]),

//     .l1d_ls_pipe_mshr_full_o(),

//     .ls_pipe_l1d_ld_raw_fail_i('0).

//     // LS Pipe -> L1D : Kill D-Cache Response
//     .ls_pipe_l1d_kill_resp_i({1'b0, lsu_l1d_kill_req}),

//     .l1d_int_prf_wb_rdy_from_mlfb_i(),
//     .l1d_int_prf_wb_vld_from_mlfb_o(),

//     // D$ -> ROB : Write Back
//     .l1d_rob_wb_vld_o(l1d_lsu_wb_vld),
//     .l1d_rob_wb_rob_tag_o(l1d_lsu_wb_rob_index),
//     // D$ -> Int PRF : Write Back
//     .l1d_int_prf_wb_vld_o(l1d_lsu_prf_wb_vld),
//     .l1d_int_prf_wb_tag_o(l1d_lsu_prf_wb_rd_addr),
//     .l1d_int_prf_wb_data_o(l1d_lsu_prf_wb_data),

    
//     // ptw walk request port
//     .ptw_walk_req_vld_i('0),
//     .ptw_walk_req_id_i('0),
//     .ptw_walk_req_addr_i('0),
//     .ptw_walk_req_rdy_o(),
//     // ptw walk response port
//     .ptw_walk_resp_vld_o(),
//     .ptw_walk_resp_id_o(),
//     .ptw_walk_resp_pte_o(),
//     .ptw_walk_resp_rdy_i('0),

//     // L1D -> L2 : Request
//       // mshr -> mem bus
//       // AR
//     .l1d_l2_req_arvalid_o(l2_req_if_arvalid[0]),
//     .l1d_l2_req_arready_i(l2_req_if_arready[0]),
//     .l1d_l2_req_ar_o(l2_req_if_ar[0]),
//       // ewrq -> mem bus
//       // AW 
//     .l1d_l2_req_awvalid_o(l2_req_if_awvalid[0]),
//     .l1d_l2_req_awready_i(l2_req_if_awready[0]),
//     .l1d_l2_req_aw_o(l2_req_if_aw[0]),
//       // W 
//     .l1d_l2_req_wvalid_o(l2_req_if_wvalid[0]),
//     .l1d_l2_req_wready_i(l2_req_if_wready[0]),
//     .l1d_l2_req_w_o(l2_req_if_w[0]),
//     // L1D -> L2 : Response
//       // B
//     .l2_l1d_resp_bvalid_i(l2_resp_if_bvalid[0]),
//     .l2_l1d_resp_bready_o(l2_resp_if_bready[0]),
//     .l2_l1d_resp_b_i(l2_resp_if_b[0]),
//       // mem bus -> mlfb
//       // R
//     .l2_l1d_resp_rvalid_i(l2_resp_if_rvalid[0]),
//     .l2_l1d_resp_rready_o(l2_resp_if_rready[0]),
//     .l2_l1d_resp_r_i(l2_resp_if_r[0]),

//     // snoop
    


//     .rob_flush_i('0),

//     .fencei_flush_vld_i('0),
//     .fencei_flush_grant_o(),

//     .clk(clk),
//     .rst(~rst)
// );
`endif // RVH_L1D
`ifdef PERFECT_DTLB
perfect_dtlb #(
    .DTLB_MISS_MIN_DELAY(1),
    .DTLB_MISS_MAX_DELAY(3)
) dtlb(
    // lsu
    .dtlb_lsu_rdy_o(dtlb_lsu_rdy),
    .dtlb_lsu_vld_o(dtlb_lsu_vld), // should be the dtlb_lsu_iss_vld_o in last cycle
    .dtlb_lsu_hit_o(dtlb_lsu_hit),
    .dtlb_lsu_ptag_o(dtlb_lsu_ptag),
    .dtlb_lsu_exception_vld_o(dtlb_lsu_exception_vld),
    .dtlb_lsu_ecause_o(dtlb_lsu_ecause),

    .lsu_dtlb_iss_vld_i(lsu_dtlb_iss_vld),
    .lsu_dtlb_iss_vtag_i(lsu_dtlb_iss_vtag),
    .lsu_dtlb_iss_type_i(lsu_dtlb_iss_type),
    
    .dtlb_l1d_resp_vld_o(ls_pipe_l1d_dtlb_resp_vld),
    .dtlb_l1d_resp_ppn_o(ls_pipe_l1d_dtlb_resp_ppn),
    .dtlb_l1d_resp_excp_vld_o(ls_pipe_l1d_dtlb_resp_excp_vld),
    .dtlb_l1d_resp_hit_o(ls_pipe_l1d_dtlb_resp_hit),
    .dtlb_l1d_resp_miss_o(ls_pipe_l1d_dtlb_resp_miss),

    .clk(clk), 
    .rst(rst)
);
`else // PERFECT_DTLB
assign dtlb_translate_req_vld = lsu_dtlb_iss_vld;
assign dtlb_translate_req_access_type = lsu_dtlb_iss_type;
assign dtlb_translate_req_vpn = lsu_dtlb_iss_vtag;
assign dtlb_lsu_rdy = dtlb_translate_req_rdy;
assign dtlb_lsu_vld = dtlb_translate_resp_vld; // should be the lsu_dtlb_iss_vld_o in last cycle
assign dtlb_lsu_hit = dtlb_translate_resp_hit;
assign dtlb_lsu_ptag = dtlb_translate_resp_ppn;
assign dtlb_lsu_exception_vld = dtlb_translate_resp_excp_vld;
assign dtlb_lsu_ecause = dtlb_translate_resp_excp_cause;
assign ls_pipe_l1d_dtlb_resp_vld = dtlb_translate_resp_vld;
assign ls_pipe_l1d_dtlb_resp_ppn = dtlb_translate_resp_ppn;
assign ls_pipe_l1d_dtlb_resp_excp_vld = dtlb_translate_resp_excp_vld;
assign ls_pipe_l1d_dtlb_resp_hit = dtlb_translate_resp_hit;
assign ls_pipe_l1d_dtlb_resp_miss = dtlb_translate_resp_miss;
rvh_monolithic_mmu #(
    .PADDR_WIDTH(PHYSICAL_ADDR_LEN),
    .PPN_WIDTH(PPN_WIDTH)
) mmu
(
     // priv lvl
    .priv_lvl_i(2'b00),// u mode
    // stap
    .satp_mode_i(4'h8), // 
    .satp_asid_i('0),
    .satp_ppn_i((PAGETABLE_BASE_ADDR[PHYSICAL_ADDR_TAG_UPP - 1: PHYSICAL_ADDR_TAG_LOW])), 

    .misc_mstatus_i(0),

    // disable pmp
    // PMP Configuration Port
    .pmp_cfg_set_vld_i(0),
    .pmp_cfg_set_addr_i(0),
    .pmp_cfg_set_payload_i(0),
    .pmp_cfg_origin_payload_o(),
    .pmp_addr_set_vld_i(0),
    .pmp_addr_set_addr_i(0),
    .pmp_addr_set_payload_i(0),
    .pmp_addr_origin_payload_o(), 

    // DTLB Translate Port -> Request
    .dtlb_translate_req_vld_i(dtlb_translate_req_vld),
    .dtlb_translate_req_access_type_i(dtlb_translate_req_access_type),
    .dtlb_translate_req_vpn_i(dtlb_translate_req_vpn),
    .dtlb_translate_req_rdy_o(dtlb_translate_req_rdy),
    // DTLB Translate Port -> Response
    .dtlb_translate_resp_vld_o(dtlb_translate_resp_vld),
    .dtlb_translate_resp_ppn_o(dtlb_translate_resp_ppn),
    .dtlb_translate_resp_excp_vld_o(dtlb_translate_resp_excp_vld),
    .dtlb_translate_resp_excp_cause_o(dtlb_translate_resp_excp_cause),
    .dtlb_translate_resp_miss_o(dtlb_translate_resp_miss),
    .dtlb_translate_resp_hit_o(dtlb_translate_resp_hit),

    // ITLB Translate Port -> Request
    .itlb_translate_req_vld_i('0),
    // MODE == Read(Execute)
    // input [TRANSLATE_WIDTH-1:0][1:0] itlb_translate_req_access_type_i(),
    .itlb_translate_req_vpn_i('0),
    .itlb_translate_req_rdy_o(),
    // ITLB Translate Port -> Response
    .itlb_translate_resp_vld_o(),
    .itlb_translate_resp_ppn_o(),
    .itlb_translate_resp_excp_vld_o(),
    .itlb_translate_resp_excp_cause_o(),
    .itlb_translate_resp_miss_o(),
    .itlb_translate_resp_hit_o(),


    // dtlb shoot down
    .dtlb_flush_vld_i('0),
    .dtlb_flush_use_asid_i('0),
    .dtlb_flush_use_vpn_i('0),
    .dtlb_flush_vpn_i('0),
    .dtlb_flush_asid_i('0),
    .dtlb_flush_grant_o(),
    // itlb shoot down
    .itlb_flush_vld_i('0),
    .itlb_flush_use_asid_i('0),
    .itlb_flush_use_vpn_i('0),
    .itlb_flush_vpn_i('0),
    .itlb_flush_asid_i('0),
    .itlb_flush_grant_o(),

    .tlb_flush_grant_o(),


    // ptw walk request port
    .ptw_walk_req_vld_o(ptw_walk_req_vld),
    .ptw_walk_req_id_o(ptw_walk_req_id),
    .ptw_walk_req_addr_o(ptw_walk_req_addr),
    .ptw_walk_req_rdy_i(ptw_walk_req_rdy),
    // ptw walk response port
    .ptw_walk_resp_vld_i(ptw_walk_resp_vld),
    .ptw_walk_resp_pte_i(ptw_walk_resp_pte),
    .ptw_walk_resp_rdy_o(ptw_walk_resp_rdy),

    .clk(clk),
    .rstn(~rst)
);
`endif // PERFECT_DTLB
endmodule