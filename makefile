
# == Directories
#SRC_DIR   := src
SRC_DIR := src
BUILD_DIR := build
TEST_DIR  := tests
UNIT_TEST_DIR := unit_tests
SIM_DIR   := sim
# ==

# == Test files
#VERILOG_SRC := $(shell find $(SRC_DIR) -type f -name '*.v')
#VERILOG_SRC += $(shell find $(SRC_DIR) -type f -name '*.vh')
VERILOG_SRC += $(shell find $(SRC_DIR) -type f -name '*.v')
VERILOG_SRC += $(shell find $(SRC_DIR) -type f -name '*.sv')
VERILOG_SRC += $(shell find $(SRC_DIR) -type f -name '*.vh')
# TEST_SRC    := $(shell find $(TEST_DIR) -type f -name '*.[Sc]')

TEST_BINS   := $(patsubst $(TEST_DIR)/%.c, $(TEST_DIR)/build/%, $(patsubst $(TEST_DIR)/%.S, $(TEST_DIR)/build/%, $(TEST_SRC)))
# ==

# == Simulator files
SIM_SRC := $(shell find $(SIM_DIR) -type f -name '*.cpp')
SIM_SRC += $(shell find $(SIM_DIR) -type f -name '*.hpp')
# ==

# == Runing goals
RUNTESTS  := $(addprefix RUNTEST.,$(TEST_BINS))
# ==

# == Verilator config
VERILATOR := /work/stu/zxluan/verilator/bin/verilator
VERIFLAGS := $(addprefix -I,$(shell find $(SRC_DIR) $(SRC_DIR) -type d)) -Wall -Mdir $(BUILD_DIR)
# ==

# .SILENT:
.SECONDARY:
.SECONDEXPANSION:
.PHONY: test sim build-tests RUNTEST.$(TEST_DIR)/build/% $(TEST_DIR)/build clean

test: $(RUNTESTS)

clean:
	-rm -rf build/*
	-rm -rf tests/build/
	-rm *.vcd
	-rm *.log

sim: $(BUILD_DIR)/Vhehecore

# $(BUILD_DIR)/V%: $(SRC_DIR)/units/%.v $(UNITS_DIR)/%.cpp
# 	@echo Building $@
# 	$(VERILATOR) $(VERIFLAGS) --cc --exe --build $^

$(BUILD_DIR)/Vcore: $(VERILOG_SRC) $(SIM_SRC)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) --cc --trace --exe --build -LDFLAGS -lelf $(SRC_DIR)/core.v $(SIM_SRC)
# --build:同时生成executable 
# -LDFLAGS -lelf: add elf archive

$(TEST_DIR)/build: $(TEST_SRC)
	$(MAKE) -C $(TEST_DIR)

$(TEST_DIR)/build/%: $(TEST_DIR)/build $(TEST_DIR)/%.S
	@true

%/:
	mkdir -p $@

RUNTEST.$(TEST_DIR)/build/%: $(TEST_DIR)/build/% $(BUILD_DIR)/Vcore
	@echo "Running test $(notdir $<)"
	$(BUILD_DIR)/Vcore -c 1000 -e -l 5 $<

lsu: $(BUILD_DIR)/Vlsu
$(BUILD_DIR)/Vlsu: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) --cc --exe --build -Wno-UNUSED -LDFLAGS -lelf $(SRC_DIR)/lsu/lsu.v $(SIM_DIR)/selfcheck/lsu.cpp
	./build/Vlsu

mmu: $(BUILD_DIR)/Vrvh_monolithic_mmu
$(BUILD_DIR)/Vrvh_monolithic_mmu: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) -Wno-SYNCASYNCNET -Wno-BLKSEQ \
	-Wno-VARHIDDEN -Wno-IMPLICIT  -Wno-WIDTH -Wno-UNDRIVEN -Wno-PINCONNECTEMPTY \
	--trace --cc --exe --build -Wno-UNUSED -LDFLAGS -lelf $(SRC_DIR)/rvh_mmu/rvh_monolithic_mmu.v $(SIM_DIR)/selfcheck/rvh_monolithic_mmu.cpp
	./build/Vrvh_monolithic_mmu

mmu_sv2v:
	mkdir -p $(SRC_DIR)/rvh_mmu_v
	mkdir -p $(SRC_DIR)/rvh_mmu_v/rvh_pmp
	cp $(SRC_DIR)/rvh_mmu/*.v $(SRC_DIR)/rvh_mmu_v/
	cp $(SRC_DIR)/rvh_mmu/rvh_pmp/*.v $(SRC_DIR)/rvh_mmu_v/rvh_pmp/
	rename .v .sv $(SRC_DIR)/rvh_mmu_v/*.v
	rename .v .sv $(SRC_DIR)/rvh_mmu_v/rvh_pmp/*.v
	PROJ_ROOT=$(PWD) python3 $(SRC_DIR)/rvh_mmu_v/sv2v.py -g
	rm $(SRC_DIR)/rvh_mmu_v/*.sv
	rm $(SRC_DIR)/rvh_mmu_v/rvh_pmp/*.sv

mmuv: $(BUILD_DIR)/Vrvh_monolithic_mmu
$(BUILD_DIR)/Vrvh_monolithic_mmu: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) -Wno-SYNCASYNCNET -Wno-BLKSEQ \
	-Wno-VARHIDDEN -Wno-IMPLICIT  -Wno-WIDTH -Wno-UNDRIVEN -Wno-PINCONNECTEMPTY \
	--trace --cc --exe --build -Wno-UNUSED -LDFLAGS \
	-lelf $(SRC_DIR)/rvh_mmu_v/rvh_monolithic_mmu.v $(SIM_DIR)/selfcheck/rvh_monolithic_mmu.cpp
	./build/Vrvh_monolithic_mmu

new_fu: $(BUILD_DIR)/Vnew_fu
$(BUILD_DIR)/Vnew_fu: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	@echo Building $@
	make nblsu
	$(VERILATOR) $(VERIFLAGS) --cc --exe --build -Wno-UNUSED -LDFLAGS -lelf $(SRC_DIR)/units/new_fu.v $(SIM_DIR)/selfcheck/new_fu.cpp
	./build/Vnew_fu

nblsu: $(BUILD_DIR)/Vnblsu
$(BUILD_DIR)/Vnblsu: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) --cc --exe --build --trace -Wno-UNUSED -LDFLAGS -lelf $(SRC_DIR)/core_empty/lsu/nblsu.v $(SIM_DIR)/selfcheck/nblsu.cpp
	./build/Vnblsu

backend: $(BUILD_DIR)/Vbackend
$(BUILD_DIR)/Vbackend: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) --cc --exe --build --trace -Wno-UNUSED -LDFLAGS -lelf $(SRC_DIR)/pipeline/backend.v $(SIM_DIR)/selfcheck/backend.cpp
	./build/Vbackend
	
btb: $(BUILD_DIR)/btb
$(BUILD_DIR)/btb: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) --trace --cc --exe --build -Wno-UNUSED -LDFLAGS -lelf $(SRC_DIR)/units/btb.v $(SIM_DIR)/selfcheck/btb.cpp

gshare: $(BUILD_DIR)/gshare
$(BUILD_DIR)/gshare: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) --cc --exe --build -Wno-UNUSED -LDFLAGS -lelf $(SRC_DIR)/units/gshare.v $(SIM_DIR)/selfcheck/gshare.cpp

fetch: $(BUILD_DIR)/fetch
$(BUILD_DIR)/fetch: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) --trace --cc --exe --build -Wno-UNUSED -LDFLAGS -lelf $(SRC_DIR)/pipeline/fetch.v $(SIM_DIR)/selfcheck/fetch.cpp

core_empty: $(BUILD_DIR)/core_empty
$(BUILD_DIR)/core_empty: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) --trace --cc --exe --build -Wno-UNUSED -LDFLAGS -lelf $(SRC_DIR)/core_empty.v $(SIM_DIR)/core_empty.cpp

perfect_memory: $(BUILD_DIR)/perfect_mem
$(BUILD_DIR)/perfect_mem: $(SIM_SRC) | $$(dir $$@)
	@echo Building $@
	g++ $(SIM_DIR)/perfect_mem_test.cpp -o $(BUILD_DIR)/perfect_mem_test
	$(BUILD_DIR)/perfect_mem_test·
	
lsu_dcache: $(BUILD_DIR)/Vlsu_dcache
$(BUILD_DIR)/Vlsu_dcache: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) --cc --exe --trace --build -Wno-UNUSED -Wno-PINCONNECTEMPTY -Wno-ASSIGNDLY -Wno-STMTDLY -Wno-MULTIDRIVEN -Wno-SYNCASYNCNET -LDFLAGS -lelf $(SRC_DIR)/lsu/lsu_dcache.v $(SIM_DIR)/selfcheck/lsu_dcache.cpp
	./build/Vlsu_dcache

lsu_fake_dcache: $(BUILD_DIR)/Vlsu_fake_dcache
$(BUILD_DIR)/Vlsu_fake_dcache: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) --cc --exe --trace --build -Wno-UNUSED -Wno-PINCONNECTEMPTY -Wno-ASSIGNDLY -Wno-STMTDLY -Wno-MULTIDRIVEN -Wno-SYNCASYNCNET -LDFLAGS -lelf $(SRC_DIR)/lsu/lsu_fake_dcache.v $(SIM_DIR)/selfcheck/lsu_fake_dcache.cpp
	./build/Vlsu_fake_dcache

rcu: $(BUILD_DIR)/Vrcu
$(BUILD_DIR)/Vrcu: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) --cc --exe --build -LDFLAGS -lelf $(SRC_DIR)/units/rcu.v $(SIM_DIR)/selfcheck/rcu.cpp
	./build/Vrcu

lsu_dcache_top: $(BUILD_DIR)/Vlsu_dcache_top
$(BUILD_DIR)/Vlsu_dcache_top: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) --cc --exe --build -Wno-UNUSED -Wno-PINCONNECTEMPTY -Wno-ASSIGNDLY -Wno-STMTDLY -Wno-MULTIDRIVEN -Wno-SYNCASYNCNET -LDFLAGS -lelf $(SRC_DIR)/lsu/lsu_dcache_top.v $(SIM_DIR)/selfcheck/lsu_dcache_top.cpp
	./build/Vlsu_dcache_top

decode: $(BUILD_DIR)/Vdecode
$(BUILD_DIR)/Vdecode: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) --cc --exe --build  --trace src/units/decode.v $(SIM_DIR)/selfcheck/decode.cpp 
	./build/Vdecode

backend_cosim: $(BUILD_DIR)/backend_cosim
$(BUILD_DIR)/backend_cosim: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	@echo Building $@
	-rm backend_cosim.log
	$(VERILATOR) $(VERIFLAGS) --trace --cc --exe --build -Wno-UNUSED -LDFLAGS -lelf $(SRC_DIR)/pipeline/backend.v ut/backend.cpp
	./build/Vbackend > backend_cosim.log

lsuv1:$(BUILD_DIR)/Vlsuv1
$(BUILD_DIR)/Vlsuv1: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	# @echo $(SIM_SRC)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) --cc --exe --build --trace +define+LSU_DEBUG -Wno-UNUSED -Wno-UNOPTFLAT -LDFLAGS -lelf $(SRC_DIR)/lsuv1/lsuv1.v $(SIM_DIR)/lsu_ut/lsuv1.cpp $(SIM_DIR)/lsu_ut/monitor.cpp $(SIM_DIR)/lsu_ut/fake_tlb.cpp $(SIM_DIR)/lsu_ut/fake_rcu.cpp $(SIM_DIR)/lsu_ut/fake_mem.cpp $(SIM_DIR)/lsu_ut/fake_cache.cpp $(SIM_DIR)/lsu_ut/fake_bus.cpp $(SIM_DIR)/lsu_ut/util.cpp
	./build/Vlsuv1

alu: $(BUILD_DIR)/alu
$(BUILD_DIR)/alu: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) --trace --cc --exe --build -Wno-UNUSED -LDFLAGS -lelf $(SRC_DIR)/fu/alu.v $(SRC_DIR)/fu/selftest/alu.cpp
	./build/Valu

fu: $(BUILD_DIR)/fu
$(BUILD_DIR)/fu: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) --trace --cc --exe --build -Wno-UNUSED -Wno-UNOPTFLAT -LDFLAGS -lelf $(SRC_DIR)/fu/fu.v  $(SRC_DIR)/fu/selftest/fu.cpp
	./build/Vfu

uncore: $(BUILD_DIR)/uncore
$(BUILD_DIR)/uncore: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) --trace --cc --exe --build -Wno-UNUSED -Wno-UNOPTFLAT -LDFLAGS -lelf $(SRC_DIR)/uncore.v $(SIM_DIR)/uncore/uncore.cpp

wmz_l1d:$(BUILD_DIR)/wmz_l1d
$(BUILD_DIR)/wmz_l1d: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	echo $(VERILOG_SRC)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) --trace --cc --exe --build  \
	-Wno-UNUSED -Wno-UNOPTFLAT -Wno-PINMISSING -Wno-EOFNEWLINE -Wno-PINCONNECTEMPTY -Wno-VARHIDDEN -Wno-WIDTH \
	+define+USE_VERILATOR+LSU_DEBUG \
	-LDFLAGS -lelf $(SRC_DIR)/wmz_l1d/wmz_l1d.sv $(SIM_DIR)/uncore/wmz_l1d.cpp 
