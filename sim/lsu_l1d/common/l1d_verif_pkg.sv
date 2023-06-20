package l1d_verif_pkg;

import riscv_pkg::*;
import rvh_l1d_pkg::*;
import uop_encoding_pkg::*;
import rvh_pkg::*;

parameter FAKE_MEMORY_WIDTH = 16;
parameter DATA_BASE_ADDR = 56'h80000000;
parameter DATA_ADDR_RANGE = 1 << FAKE_MEMORY_WIDTH;
parameter PAGETABLE_BASE_ADDR = 56'h10000000;
parameter PAGETABLE_ADDR_RANGE = 1 << FAKE_MEMORY_WIDTH;

localparam ADDR_OFFSET_LEN = 6;
localparam ADDR_INDEX_LEN = 6;

int ERROR_LOG_HANDLE;


function void error_quit(string msg);
    $display($realtime, ":\t%s", msg);
    $fdisplay(ERROR_LOG_HANDLE, $realtime, ":\t%s", msg);
    $finish;
endfunction

function bit[1:0] stop2size (stu_minor_op_t stop);
    if(stop == STU_SB) begin
        return 2'b00;
    end
    else if(stop == STU_SH) begin
        return 2'b01;
    end
    else if(
        stop == STU_SW || stop == STU_SCW || stop == STU_AMOSWAPW || 
        stop == STU_AMOADDW || stop == STU_AMOANDW || stop == STU_AMOORW || 
        stop == STU_AMOXORW || stop == STU_AMOMAXW || stop == STU_AMOMAXUW || 
        stop == STU_AMOMINW || stop == STU_AMOMINUW || stop == STU_LRW
    )begin
        return 2'b10;
    end
    else begin
        return 2'b11;
    end
endfunction

function bit[1:0] ldop2size(ldu_minor_op_t ldop);
    if(ldop == LDU_LB || ldop == LDU_LBU) begin
        return 2'b00;
    end
    else if(ldop == LDU_LH || ldop == LDU_LHU) begin
        return 2'b01;
    end
    else if(ldop == LDU_LW || ldop == LDU_LWU ) begin
        return 2'b10;
    end
    else begin
        return 2'b11;
    end
endfunction

function [XLEN / 8 - 1 : 0] gen_mask64(bit[ADDR_OFFSET_LEN - 1 : 0] offset, bit[1:0] size);
    bit[XLEN / 8 - 1 : 0] mask;
    if(size == 2'b00) begin
        mask = {{(XLEN / 8 - 1){1'b0}}, 1'b1};
        mask = mask << offset[2:0];
    end
    else if (size == 2'b01) begin
        mask = {{(XLEN / 8 - 2){1'b0}}, 2'b11};
        mask = mask << (offset[2 : 1] * 2);
    end
    else if (size == 2'b10) begin
        mask = {{(XLEN / 8 - 4){1'b0}}, 4'b1111};
        mask = mask << (offset[2] * 4);
    end
    else begin
        mask = {(XLEN / 8){1'b1}};
    end
    return mask;
endfunction

class lsu_req_t;
    bit                                         issued;
    bit                                         success;
    rand bit                                    is_load_or_store;
    bit                                         is_fence;
    bit                                         ptag_vld;
    rand bit [VPN_WIDTH - 1 : 0]                vtag;
    rand bit [PPN_WIDTH - 1 : 0]                ptag;
    rand bit [ADDR_INDEX_LEN - 1 : 0]           index;
    rand bit [ADDR_OFFSET_LEN - 1 : 0]          offset;
    bit [ROB_TAG_WIDTH - 1 : 0]                 rob_index;
    bit [PREG_TAG_WIDTH - 1 : 0]                rd_addr;
    rand ldu_minor_op_t                         ld_opcode;
    rand stu_minor_op_t                         st_opcode;
    rand bit [XLEN - 1 : 0]                     data;
    rand bit [XLEN / 8 - 1 : 0]                 mask;


    function new;
        issued = 0;
        success = 0;
        // FIXME: no fence
        is_fence = 0;
        ptag_vld = 0;
    endfunction

    function string to_string;
        string str;
        string t = is_load_or_store ? "st" : "ld";
        string name = ~is_load_or_store ? ld_opcode.name() : st_opcode.name();
        if($size(name) < 8) begin
            $sformat(name, "%s\t", name);
        end
        $sformat(str, "%s req\t%s\t@ %x.\trob index:%d\trd_addr:%d\tdata:%x\tmask:%b\tsize:%b", 
            t, name, {vtag, index, offset}, rob_index, rd_addr, data, mask, 
            ~is_load_or_store ? ldop2size(ld_opcode) : stop2size(st_opcode)
        ); 
        return str;
    endfunction
    function bit[VADDR_WIDTH - 1 : 0] vaddr();
        return {vtag, index, offset};
    endfunction
    function void init(int test_num, bit[VADDR_WIDTH -1 : 0] vaddr, bit reset_addr);
        if(reset_addr == 1'b1) begin
            {vtag, index, offset} = vaddr;
            ptag = {{(PADDR_WIDTH - VADDR_WIDTH){1'b0}}, vtag};
        end
        if(is_load_or_store == 1'b1) begin
            if(stop2size(st_opcode) == 2'b01)begin
                offset[0] = '0;
            end
            else if(stop2size(st_opcode) == 2'b10)begin
                offset[1 : 0] = '0;
            end
            else if(stop2size(st_opcode) == 2'b11)begin
                offset[2 : 0] = '0;
            end
        end
        else begin
            if(ldop2size(ld_opcode) == 2'b01)begin
                offset[0] = '0;
            end
            else if(ldop2size(ld_opcode) == 2'b10)begin
                offset[1 : 0] = '0;
            end
            else if(ldop2size(ld_opcode) == 2'b11)begin
                offset[2 : 0] = '0;
            end  
        end

        if(is_load_or_store)begin
            mask = gen_mask64(offset, stop2size(st_opcode));
        end
        else begin
            mask = gen_mask64(offset, ldop2size(ld_opcode));
        end

        rob_index = test_num % 16;
        rd_addr = (test_num % (48 - 1)) + 1;
        if(is_load_or_store & (st_opcode == STU_SB || st_opcode == STU_SH || st_opcode == STU_SW || st_opcode == STU_SD)) begin
            rd_addr = 0;
        end
    endfunction

    function bit is_unsigend;
        return ~is_load_or_store & (ld_opcode == LDU_LBU || ld_opcode == LDU_LHU || ld_opcode == LDU_LWU);
    endfunction
    function bit[1:0] size;
        if(is_load_or_store) begin
            if(
                st_opcode == STU_SB 
            ) begin
                return 2'b00;
            end
            else if(
                st_opcode == STU_SH 
            )begin
                return 2'b01;
            end
            else if(
                st_opcode == STU_SW 
            ) begin
                return 2'b10;
            end
            else if(
                st_opcode == STU_SD 
            ) begin
                return 2'b11;
            end
            else begin
                string msg;
                $sformat(msg, "opcode %s not supported", is_load_or_store ? st_opcode.name() : ld_opcode.name());
                $error(msg);
                assert(0);
            end
        end
        else begin
            if(
                ld_opcode == LDU_LBU || ld_opcode == LDU_LB
            ) begin
                return 2'b00;
            end
            else if(
                ld_opcode == LDU_LHU || ld_opcode == LDU_LH
            )begin
                return 2'b01;
            end
            else if(
                ld_opcode == LDU_LWU || ld_opcode == LDU_LW
            ) begin
                return 2'b10;
            end
            else if(
                ld_opcode == LDU_LD
            ) begin
                return 2'b11;
            end
            else begin
                string msg;
                $sformat(msg, "opcode %s not supported", is_load_or_store ? st_opcode.name() : ld_opcode.name());
                $error(msg);
                assert(0);
            end
        end
    endfunction

    constraint tag_c{
        vtag[VPN_WIDTH - 1 : 4] == {{(VPN_WIDTH - 20){1'b0}},16'h8000};
        // vtag == 44'h80000;
        // index == 6'b0;
        ptag[PPN_WIDTH - 1 : 0] == {{(PPN_WIDTH - VPN_WIDTH){1'b0}},vtag};
    }
    constraint ld_opcode_c{
        ld_opcode == LDU_LB || ld_opcode == LDU_LH || ld_opcode == LDU_LW || 
        ld_opcode == LDU_LBU || ld_opcode == LDU_LHU || ld_opcode == LDU_LWU || 
        ld_opcode == LDU_LD;
        // ld_opcode == LDU_LD;
    }
    constraint st_opcode_c{
        st_opcode == STU_SB || st_opcode == STU_SH || st_opcode == STU_SW || st_opcode == STU_SD;
        // st_opcode == STU_SD;
    }
    // constraint rob_index_c{
    //     rob_index < 16;
    // }
    // constraint rd_addr_c{
    //     rd_addr < 48;
    // }
endclass

function lsu_req_t gen_random_req(int i);
    lsu_req_t req;
    req = new();
    assert(req.randomize());
    req.init(i, 0, 0);
`ifdef LOG_LV1
    $display("%s", req.to_string());
`endif // LOG_LV1
    return req;
endfunction

parameter SCAN_GROUP_TEST_NUM = 4;
parameter SCAN_STEP_WIDTH = 4; // in byte
class scan_test_t;
    lsu_req_t scan_q[SCAN_GROUP_TEST_NUM - 1 : 0];

    function new(bit[VADDR_WIDTH - 1 : 0] base, int step);
        lsu_req_t req;
        req = new();
        req.is_load_or_store = 1; // st
        {req.vtag, req.index, req.offset} = base + step * SCAN_STEP_WIDTH;
        // req.ptag;
        // req.index;
        // req.offset;
        // req.rob_index;
        // req.rd_addr;
        // req.ld_opcode;
        // req.st_opcode;
        // req.data;
        // req.mask;
        for(int i = 1; i < SCAN_GROUP_TEST_NUM - 1; i ++) begin
            req = new();
            assert(req.randomize());
            req.init(SCAN_GROUP_TEST_NUM * step + i, base + step * SCAN_STEP_WIDTH, 1);
            scan_q[i] = req;
        end
    endfunction
endclass

endpackage
