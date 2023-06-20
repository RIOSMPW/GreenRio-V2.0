
# Design
set ::env(DESIGN_NAME) "hehe"
set ::env(PDK) "sky130B"
set ::env(PDK_ROOT) "/home/rios/Documents/AugOpenLane/OpenLane/pdks/"
set ::env(STD_CELL_LIBRARY) "sky130_fd_sc_hd"
set ::env(DESIGN_IS_CORE) 1
set ::env(FP_ASPECT_RATIO) 0.8
set ::env(MACRO_EXTENSION) 1
# Timing configuration
set ::env(CLOCK_PERIOD) "15"
set ::env(SYNTH_MAX_FANOUT) 4
set ::env(CLOCK_PORT) "clk"
set ::env(FP_CORE_UTIL) 35
set ::env(PL_TIME_DRIVEN) 1
set ::env(PL_TARGET_DENSITY) 0.40
set ::env(PL_BASIC_PLACEMENT) 0
set ::env(CELL_PAD) 4
set ::env(GLB_RESIZER_TIMING_OPTIMIZATIONS) 1
set ::env(SET_MACRO_EXTENSION) 1
set ::env(ROUTING_CORES) 16
set ::env(SYNTH_STRATEGY) "AREA 0"
## CTS BUFFER
set ::env(CTS_CLK_BUFFER_LIST) "sky130_fd_sc_hd__clkbuf_4 sky130_fd_sc_hd__clkbuf_8"
set ::env(CTS_SINK_CLUSTERING_SIZE) "16"
set ::env(CLOCK_BUFFER_FANOUT) "8"
set script_dir $::env(DESIGN_DIR)
# Sources
# -------
# Local sources + no2usb sources
set ::env(VERILOG_FILES) "\
		$::env(DESIGN_DIR)/src/params.vh \
		$::env(DESIGN_DIR)/src/units/btb.v     \
		$::env(DESIGN_DIR)/src/units/gshare.v     \
		$::env(DESIGN_DIR)/src/units/counter.v     \
		$::env(DESIGN_DIR)/src/units/fifo_tmp.v     \
		$::env(DESIGN_DIR)/src/units/csr.v     \
		$::env(DESIGN_DIR)/src/units/excep_ctrl.v     \
		$::env(DESIGN_DIR)/src/cache/cacheblock/std_dffe.v     \
		$::env(DESIGN_DIR)/src/cache/cacheblock/std_dffr.v     \
		$::env(DESIGN_DIR)/src/cache/l1dcache.v     \
		$::env(DESIGN_DIR)/src/cache/l1icache.v     \
		$::env(DESIGN_DIR)/src/units/fifo.v     \
		$::env(DESIGN_DIR)/src/units/ins_buffer.v     \
		$::env(DESIGN_DIR)/src/units/fetch.v     \
		$::env(DESIGN_DIR)/src/units/decode.v     \
		$::env(DESIGN_DIR)/src/pipeline/frontend.v     \
		$::env(DESIGN_DIR)/src/units/physical_regfile.v     \
		$::env(DESIGN_DIR)/src/units/rcu.v     \
		$::env(DESIGN_DIR)/src/units/alu.v     \
		$::env(DESIGN_DIR)/src/units/cmp.v     \
		$::env(DESIGN_DIR)/src/lsu/ac.v     \
		$::env(DESIGN_DIR)/src/lsu/agu.v     \
		$::env(DESIGN_DIR)/src/lsu/cu.v     \
		$::env(DESIGN_DIR)/src/lsu/lsq.v     \
		$::env(DESIGN_DIR)/src/lsu/lsu.v     \
		$::env(DESIGN_DIR)/src/lsu/nblsu.v     \
		$::env(DESIGN_DIR)/src/units/fu.v     \
		$::env(DESIGN_DIR)/src/pipeline/backend.v     \
		$::env(DESIGN_DIR)/src/core_empty.v     \
		$::env(DESIGN_DIR)/src/hehe.v
	"

set ::env(EXTRA_LEFS) " \ 
		$script_dir/macros/lef/sky130_sram_1kbyte_1rw1r_32x256_8.lef \
		$script_dir/macros/lef/sky130_sram_1rw1r_64x256_8.lef
		"

set ::env(EXTRA_GDS_FILES) " \ 
		$script_dir/macros/gds/sky130_sram_1rw1r_64x256_8.gds \
		$script_dir/macros/gds/sky130_sram_1rw1r_64x256_8.gds
		"
set ::env(VERILOG_FILES_BLACKBOX) " \ 
		$script_dir/macros/verilog/sky130_sram_1kbyte_1rw1r_32x256_8.v \
		$script_dir/macros/verilog/sky130_sram_1rw1r_64x256_8.v
		"
set ::env(SDC_FILE) $::env(DESIGN_DIR)/src/base.sdc
set ::env(BASE_SDC_FILE) $::env(DESIGN_DIR)/src/base.sdc

set ::env(LEC_ENABLE) 0
#set ::env(VDD_PIN) [list {vccd1}]
#set ::env(GND_PIN) [list {vssd1}]
# If you're going to use multiple power domains, then keep this disabled.
set ::env(RUN_CVC) 1
#set ::env(PDN_CFG) $script_dir/pdn.tcl
# helps in anteena fix
set ::env(USE_ARC_ANTENNA_CHECK) "0"
set ::env(GLB_RT_MAXLAYER) 5
set ::env(RT_MAX_LAYER) {met4}
#set ::env(GLB_RT_MAX_DIODE_INS_ITERS) 10
set ::env(DIODE_INSERTION_STRATEGY) 4
set ::env(QUIT_ON_TIMING_VIOLATIONS) "0"
set ::env(QUIT_ON_MAGIC_DRC) "1"
set ::env(QUIT_ON_LVS_ERROR) "1"
set ::env(QUIT_ON_SLEW_VIOLATIONS) "0"
set filename $::env(DESIGN_DIR)/$::env(PDK)_$::env(STD_CELL_LIBRARY)_config.tcl
if { [file exists $filename] == 1} {
	source $filename
}