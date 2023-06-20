module perfect_dtlb
#(
    parameter int DTLB_DEPTH = 64,
    parameter int DTLB_MSHR_DEPTH = 4,
    parameter int DTLB_MISS_MAX_DELAY = 100,
    parameter int DTLB_MISS_MIN_DELAY = 10
)(
    // lsu
    output logic                                                                                                dtlb_lsu_rdy_o,
    output logic                                                                                                dtlb_lsu_vld_o, // should be the dtlb_lsu_iss_vld_o in last cycle
    output logic                                                                                                dtlb_lsu_hit_o,
    output logic  [PHYSICAL_ADDR_TAG_LEN - 1 : 0]                                                               dtlb_lsu_ptag_o,
    output wire                                                                                                 dtlb_lsu_exception_vld_o,
    output wire  [EXCEPTION_CAUSE_WIDTH - 1 : 0]                                                                dtlb_lsu_ecause_o,

    input logic                                                                                                 lsu_dtlb_iss_vld_i,
    input logic [VIRTUAL_ADDR_TAG_LEN - 1 : 0]                                                                  lsu_dtlb_iss_vtag_i,
    input logic [PMP_ACCESS_TYPE_WIDTH - 1 : 0]                                                                 lsu_dtlb_iss_type_i,
     // <> l1d
    output  logic                                                                      dtlb_l1d_resp_vld_o,
    output  logic [         PPN_WIDTH-1:0]                                             dtlb_l1d_resp_ppn_o,
    output  wire                                                                      dtlb_l1d_resp_excp_vld_o,
    output  logic                                                                      dtlb_l1d_resp_hit_o,
    output  logic                                                                     dtlb_l1d_resp_miss_o,

    input clk, rst
);
class dtlb_mshr_entry;
    rand int delay;
    bit [VIRTUAL_ADDR_TAG_LEN - 1 : 0] vtag;
    function new([VIRTUAL_ADDR_TAG_LEN - 1 : 0] vt);
        vtag = vt;
    endfunction
    constraint delay_c{
        delay < DTLB_MISS_MAX_DELAY;
        DTLB_MISS_MIN_DELAY < delay;
    }
endclass

bit [VIRTUAL_ADDR_TAG_LEN - 1 : 0] vtag_q[$];
dtlb_mshr_entry mshr_q[$];


assign  dtlb_lsu_exception_vld_o = 0;
assign  dtlb_lsu_ecause_o = 0;
assign  dtlb_l1d_resp_excp_vld_o = 0;

always @(posedge clk) begin
    if(rst) begin
        while($size(vtag_q) > 0) begin
            vtag_q.pop_front();
        end
        while($size(mshr_q) > 0) begin
            mshr_q.pop_front();
        end
        dtlb_lsu_rdy_o <= 0;
        dtlb_lsu_vld_o <= 0;
        dtlb_lsu_hit_o <= 0;
        dtlb_lsu_ptag_o <= 0;
        dtlb_l1d_resp_vld_o <= 0;
        dtlb_l1d_resp_ppn_o <= 0;
        dtlb_l1d_resp_hit_o <= 0;
        dtlb_l1d_resp_miss_o <= 0;
    end
    else begin
        // mshr update
        for(int i = 0; i < $size(mshr_q); i ++) begin
            if(mshr_q[i].delay == 0) begin
                vtag_q.push_back(mshr_q[i].vtag);
                if($size(vtag_q) > DTLB_DEPTH) begin
                    vtag_q.pop_front();
                end
                mshr_q.delete(i);
                i--;
            end
            else begin
                mshr_q[i].delay --;
            end
        end
        // new req
        dtlb_lsu_vld_o <= lsu_dtlb_iss_vld_i;
        dtlb_l1d_resp_vld_o <= lsu_dtlb_iss_vld_i;
        if(lsu_dtlb_iss_vld_i & dtlb_lsu_rdy_o) begin
            bit hit = 0;
            int delete_index = 0;
            for(int i = 0; i < $size(vtag_q); i ++) begin
                if(vtag_q[i] == lsu_dtlb_iss_vtag_i) begin
                    delete_index = i;
                    hit = 1;
                    break;
                end
            end
            if(hit == 1) begin
                bit [VIRTUAL_ADDR_TAG_LEN - 1 : 0] tmp = vtag_q[delete_index];
                vtag_q.delete(delete_index);
                vtag_q.push_back(tmp);
                
                dtlb_lsu_hit_o <= '1;
                dtlb_l1d_resp_hit_o <= '1;
                dtlb_l1d_resp_miss_o <= '0;

                dtlb_lsu_ptag_o <= {{(PHYSICAL_ADDR_TAG_LEN - VIRTUAL_ADDR_TAG_LEN){1'b0}}, lsu_dtlb_iss_vtag_i};
                dtlb_l1d_resp_ppn_o <= {{(PHYSICAL_ADDR_TAG_LEN - VIRTUAL_ADDR_TAG_LEN){1'b0}}, lsu_dtlb_iss_vtag_i};
            end
            else begin
                int flag = 0;
                dtlb_lsu_hit_o <= '0;
                dtlb_l1d_resp_hit_o <= '0;
                dtlb_l1d_resp_miss_o <= '1;

                dtlb_lsu_ptag_o <= '0;
                dtlb_l1d_resp_ppn_o <= '0;

                for(int i = 0; i < $size(mshr_q); i ++) begin
                    if(mshr_q[i].vtag != lsu_dtlb_iss_vtag_i) continue;
                    flag = 1;
                    break;
                end
                if(flag == 0) begin
                    dtlb_mshr_entry mshr_e;
                    mshr_e = new(lsu_dtlb_iss_vtag_i);
                    mshr_e.randomize();
                    mshr_q.push_back(mshr_e);
                end
            end
        end
        dtlb_lsu_rdy_o <= ($size(mshr_q) < DTLB_MSHR_DEPTH);
    end
end
endmodule
