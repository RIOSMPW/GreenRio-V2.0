$PROJ_ROOT/sim/lsu_l1d/common/uncore_test_cfg.sv

-f $PROJ_ROOT/src/common.f
-f $PROJ_ROOT/src/rvh_mmu/flist.f
-f $PROJ_ROOT/src/lsuv1/flist.f
-f $PROJ_ROOT/src/wmz_l1d/flist.f


$PROJ_ROOT/sim/lsu_l1d/common/l1d_verif_pkg.sv
$PROJ_ROOT/sim/lsu_l1d/perfect_dtlb.sv
$PROJ_ROOT/sim/lsu_l1d/perfect_memory.sv
$PROJ_ROOT/sim/lsu_l1d/wmz_top.sv
