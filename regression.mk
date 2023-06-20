# == Directories
TEST_DIR  ?= test/isa
TEST_SRC_DIR := $(addsuffix /src, $(TEST_DIR))
BUILD_DIR := $(addsuffix /build, $(TEST_DIR))
# ==

# == Test files
TORTURE_PATH := test/torture/torture_generator

VERILOG_SRC := $(shell find src/cache/ -type f -name '*.[v]')
VERILOG_SRC += src/hehe.v src/params.vh src/bus_arbiter.v src/core_empty/core_empty.v
VERILOG_SRC += $(shell find src/core_empty/lsu/ -type f -name '*.[v]')
VERILOG_SRC += $(shell find src/core_empty/pipeline/ -type f -name '*.[v]')
VERILOG_SRC += $(shell find src/core_empty/units/ -type f -name '*.[v]')

TEST_SRC    := $(shell find $(TEST_SRC_DIR) -type f -name '*.[cS]')
TEST_BINS   := $(patsubst $(TEST_SRC_DIR)/%.c, $(BUILD_DIR)/%, $(patsubst $(TEST_SRC_DIR)/%.S, $(BUILD_DIR)/%, $(TEST_SRC)))

SIM_SRC := sim/core.cpp sim/memory.cpp sim/simulator.cpp sim/tracelog.cpp

REGRESSION_LOG := $(BUILD_DIR)/regression.txt
# ==

# == Runing goals
RUNTESTS  := $(addprefix RUNTEST.,$(TEST_BINS))
# ==

# == verification flags
DUMP_WAVE = 1
COSIM = 1

ifdef DUMP_WAVE
# 还要修改param.vh
CONFIGURABLE_FLAG +=-CFLAGS -DDUMP_WAVE
endif
ifdef COSIM
CONFIGURABLE_FLAG +=-CFLAGS -DCOSIM
SIM_SRC += sim/tracelog.cpp
endif
# ==

# == Verilator config
VERILATOR := /work/stu/zxluan/verilator/bin/verilator
VERIFLAGS := $(addprefix -I,$(shell find src -type d)) -Wall -Mdir build --timescale 1ns/1ps --timescale-override 1ns/1ps --prof-cfuncs -CFLAGS -DVL_DEBUG  $(CONFIGURABLE_FLAG) --Wno-VARHIDDEN --Wno-UNUSED --Wno-STMTDLY --Wno-ASSIGNDLY --Wno-EOFNEWLINE --cc --trace --exe --build -LDFLAGS -lelf 
# ==

# == SAIL config
SAIL := ./riscv_sim_RV64
# SALI_TEST := test/benchmark/dhrystone.riscv
# SALI_TEST := test/isa/build/rv64ui/sw
# SALI_TEST := test/isa/build/rv64mi/illegal
SALI_TEST := test/isa/build/rv64si/csr
# SALI_TEST := test/torture/build/test1
# ==

# == spike config
SPIKE := ./spike
# SPIKE_FLAG :=
SPIKE_FLAG := --isa rv64imc -l --log-commits --log vcs_test/test.log
# SPIKE_FILE := test/isa/build/rv64mi/ld-misaligned
SPIKE_FILE := test/benchmark/matmult-int.riscv
# ==

# == vcs parameter
VCS_DIR = ./vcs_test
# ==

.SECONDARY:
#保留所有中间文件
.PHONY: run sim clean build_dir test spikelog spikecut RUNTEST.$(BUILD_DIR)/% BUILDTEST.$(BUILD_DIR) $(BUILD_DIR)/%
.DEFAULT_GOAL := run

build/Vhehe: $(VERILOG_SRC) $(SIM_SRC)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) src/hehe.v $(SIM_SRC)

sim: build/Vhehe

run: sim $(RUNTESTS) 

TORTUE_NUM := 5
gen_torture: 
	find test/torture/ -type f -name "*.S" | xargs rm -f
	bash test/torture/gen_torture.sh $(TORTURE_PATH) $(TORTUE_NUM)

clean:
	-find build -type f | xargs rm -f
	$(MAKE) -C test clean


BUILDTEST.$(BUILD_DIR): $(TEST_SRC)
	$(MAKE) -C $(TEST_DIR) build

$(BUILD_DIR)/%: BUILDTEST.$(BUILD_DIR) $(TEST_SRC_DIR)/%.S
	@true

%/:
	mkdir -p $@

RUNTEST.$(BUILD_DIR)/%: $(BUILD_DIR)/% build/Vhehe
# python3 ./regression/own_tests/generate_lsu_test.py 
	@echo "Running  $(notdir $<)"
	-build/Vhehe -c 1000000 -w $(patsubst $(BUILD_DIR)/%, $(BUILD_DIR)/wave/%.vcd, $<) -e $< -l $(patsubst $(BUILD_DIR)/%, $(BUILD_DIR)/cosim/%.log, $<) >> $(REGRESSION_LOG)
ifeq ($(COSIM), 1)
	touch $(patsubst $(BUILD_DIR)/%, $(BUILD_DIR)/ref_cosim/%.log, $<)
	$(SAIL) $< > $(patsubst $(BUILD_DIR)/%, $(BUILD_DIR)/ref_cosim/%.log, $<)
	python3 log_command.py $(patsubst $(BUILD_DIR)/%, $(BUILD_DIR)/ref_cosim/%.log, $<)
endif
	@echo >> $(REGRESSION_LOG)

# 笨蛋链接器
build_dir:
	mkdir -p test/isa/build/wave/rv64ui
	mkdir -p test/isa/build/wave/rv64mi
	mkdir -p test/isa/build/wave/rv64uc
	mkdir -p test/isa/build/wave/rv64um
	mkdir -p test/isa/build/wave/rv64si
	mkdir -p test/isa/build/wave/own_tests
	mkdir -p test/isa/build/cosim/rv64ui
	mkdir -p test/isa/build/cosim/rv64mi
	mkdir -p test/isa/build/cosim/rv64uc
	mkdir -p test/isa/build/cosim/rv64um
	mkdir -p test/isa/build/cosim/rv64si
	mkdir -p test/isa/build/cosim/own_tests
	mkdir -p test/isa/build/ref_cosim/rv64ui
	mkdir -p test/isa/build/ref_cosim/rv64mi
	mkdir -p test/isa/build/ref_cosim/rv64uc
	mkdir -p test/isa/build/ref_cosim/rv64um
	mkdir -p test/isa/build/ref_cosim/rv64si
	mkdir -p test/isa/build/ref_cosim/own_tests
	mkdir -p test/isa/build/disassembly/rv64ui
	mkdir -p test/isa/build/disassembly/rv64mi
	mkdir -p test/isa/build/disassembly/rv64uc
	mkdir -p test/isa/build/disassembly/rv64um
	mkdir -p test/isa/build/disassembly/rv64si
	mkdir -p test/isa/build/disassembly/own_tests
	mkdir -p test/isa/build/hex/rv64ui
	mkdir -p test/isa/build/hex/rv64mi
	mkdir -p test/isa/build/hex/rv64uc
	mkdir -p test/isa/build/hex/rv64um
	mkdir -p test/isa/build/hex/rv64si
	mkdir -p test/isa/build/rv64ui
	mkdir -p test/isa/build/rv64mi
	mkdir -p test/isa/build/rv64uc
	mkdir -p test/isa/build/rv64um
	mkdir -p test/isa/build/rv64si
	mkdir -p test/isa/build/own_tests
	mkdir -p test/torture/build
	mkdir -p test/torture/build/wave
	mkdir -p test/torture/build/disassembly
	mkdir -p test/torture/build/cosim
	mkdir -p test/torture/build/hex
	mkdir -p test/torture/build/ref_cosim
	mkdir -p test/benchmark/build/wave
	mkdir -p test/benchmark/build/hex
	mkdir -p test/benchmark/build/disassembly
	mkdir -p test/benchmark/build/cosim
	mkdir -p test/benchmark/build/ref_cosim


ceshi:
	@echo $(TEST_SRC)

vcs: 
	$(MAKE) -C $(VCS_DIR)

haha:
	$(MAKE) -C $(VCS_DIR) haha

sail_log:
	$(SAIL) $(SALI_TEST) > vcs_test/ref_co_sim.log
	python3 log_command.py vcs_test/ref_co_sim.log

spikelog:
	$(SPIKE) $(SPIKE_FLAG) $(SPIKE_FILE)
	python3 convert.py

spikecut:
	python3 cut.py
