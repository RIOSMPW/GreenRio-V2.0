params.vh

-f $PROJ_ROOT/src/lsuv1/flist.f
-f $PROJ_ROOT/src/utils/commoncell/flist.f
-f $PROJ_ROOT/src/rvh_monolithic_mmu/flist.f

csr/excep_ctrl.v
rcu/rcu.sv
utils/commoncell/dpram64_3r1w.sv

fetch/btb.v
fetch/gshare.v
fetch/ins_buffer.v
fetch/fetch.v

decode/rvc_decoder.v
decode/rv_decoder.v
decode/decode.v

fu/alu.v
fu/div.v
fu/lowRisc_mul_fast.v
fu/md.v
fu/fu.v
lsuv1/lsu_agu.v
lsuv1/lsu_bus_ctrl.v
lsuv1/lsu_lsq_entry.v
lsuv1/lsu_lsq.v
lsuv1/lsu_mc.v
lsuv1/lsu_pma_checker.v
lsuv1/lsu_wb_arb.v
lsuv1/lsuv1.v
csr/csr_regfile.v
csr/csr.sv

core.sv
routing.v
tb_top.sv

