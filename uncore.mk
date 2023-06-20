
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
VERILOG_SRC := $(shell find $(SRC_DIR)/lsuv1/ -type f -name '*.v')
VERILOG_SRC += $(shell find $(SRC_DIR)/rcu/unit/ -type f -name '*.v')
VERILOG_SRC += $(shell find $(SRC_DIR)/rvh_mmu/ -type f -name '*.v')
VERILOG_SRC += $(shell find $(SRC_DIR)/wmz_l1d/ -type f -name '*.sv')
VERILOG_SRC += $(shell find $(SRC_DIR)/wmz_l1d/ -type f -name '*.v')
VERILOG_SRC += $(shell find $(SRC_DIR)/utils/ -type f -name '*.v')
VERILOG_SRC += $(shell find $(SRC_DIR)/perips/ -type f -name '*.v')
VERILOG_SRC += $(SRC_DIR)/hehe_cfg.vh
VERILOG_SRC += $(SRC_DIR)/params.vh
VERILOG_SRC += $(SRC_DIR)/uncore.sv
# TEST_SRC    := $(shell find $(TEST_DIR) -type f -name '*.[Sc]')

TEST_BINS   := $(patsubst $(TEST_DIR)/%.c, $(TEST_DIR)/build/%, $(patsubst $(TEST_DIR)/%.S, $(TEST_DIR)/build/%, $(TEST_SRC)))
# ==

# == Simulator files
SIM_SRC := $(shell find $(SIM_DIR)/uncore -type f -name '*.cpp')
SIM_SRC += $(shell find $(SIM_DIR)/uncore -type f -name '*.hpp')
# ==

# == Runing goals
RUNTESTS  := $(addprefix RUNTEST.,$(TEST_BINS))
# ==

# == Verilator config
VERILATOR := /work/stu/zxluan/verilator/bin/verilator

VERIFLAGS := $(addprefix -I,$(SRC_DIR)/lsuv1)
VERIFLAGS += $(addprefix -I,$(SRC_DIR)/rcu/unit/oldest2_abitter)
VERIFLAGS += $(addprefix -I,$(SRC_DIR)/rcu/unit/counter)
VERIFLAGS += $(addprefix -I,$(shell find $(SRC_DIR)/rvh_mmu -type d)) 
VERIFLAGS += $(addprefix -I,$(shell find $(SRC_DIR)/wmz_l1d -type d)) 
VERIFLAGS += $(addprefix -I,$(shell find $(SRC_DIR)/include -type d)) 
VERIFLAGS += $(addprefix -I,$(shell find $(SRC_DIR)/utils -type d)) 
VERIFLAGS += $(addprefix -I,$(shell find $(SRC_DIR) -type d)) 
VERIFLAGS += -Wall -Mdir $(BUILD_DIR)

# ==

# .SILENT:
.SECONDARY:
.SECONDEXPANSION:
.PHONY: test sim build-tests RUNTEST.$(TEST_DIR)/build/% $(TEST_DIR)/build clean

test: $(RUNTESTS)

clean:
	-rm -rf build/*
	-rm -rf tests/build/
	-rm *.vcdrvh_l1d_ewrq.sv
	-rm *.log

sim: $(BUILD_DIR)/Vhehecore

default: uncore

uncore:$(BUILD_DIR)/uncore
$(BUILD_DIR)/uncore: $(VERILOG_SRC) $(SIM_SRC) | $$(dir $$@)
	echo $(VERILOG_SRC)
	@echo Building $@
	$(VERILATOR) $(VERIFLAGS) --trace --cc --exe --build --top-module uncore \
	-Wno-UNUSED -Wno-UNOPTFLAT -Wno-PINMISSING -Wno-EOFNEWLINE -Wno-PINCONNECTEMPTY -Wno-VARHIDDEN -Wno-WIDTH \
	+define+USE_VERILATOR+LSU_DEBUG \
	-LDFLAGS -lelf $(SRC_DIR)/uncore.sv $(SIM_DIR)/uncore/uncore.cpp 