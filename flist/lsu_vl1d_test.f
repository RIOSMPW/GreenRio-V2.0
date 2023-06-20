$PROJ_ROOT/sim/lsu_l1d/common/uncore_test_cfg.sv

-f $PROJ_ROOT/src/common.f
-f $PROJ_ROOT/src/rvh_mmu/flist.f
-f $PROJ_ROOT/src/lsuv1/flist.f
-f $PROJ_ROOT/src/rvh_l1d/vflist.f


$PROJ_ROOT/src/rvh_l1d/include/rvh_pkg.sv
$PROJ_ROOT/src/rvh_l1d/include/riscv_pkg.sv
$PROJ_ROOT/src/rvh_l1d/include/uop_encoding_pkg.sv
$PROJ_ROOT/src/rvh_l1d/include/rvh_l1d_pkg.sv
$PROJ_ROOT/sim/lsu_l1d/common/l1d_verif_pkg.sv
$PROJ_ROOT/sim/lsu_l1d/perfect_dtlb.sv
$PROJ_ROOT/sim/lsu_l1d/perfect_memory.sv
$PROJ_ROOT/sim/lsu_l1d/l1d_test_top.sv
