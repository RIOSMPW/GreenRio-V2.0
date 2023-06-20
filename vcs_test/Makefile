SIM_ROOT := $(shell pwd)
sim_log := $(SIM_ROOT)/logs
RV_ROOT := $(SIM_ROOT)/../src
FILE_LIST := $(RV_ROOT)/flist.f
# FILE_LIST := $(RV_ROOT)/flist_test.f
TOP_MODULE := tb_top
# HEX_DIR := $(SIM_ROOT)/../test/isa/build/hex
# HEX_DIR := $(SIM_ROOT)/../test/torture/build/hex
HEX_DIR := $(SIM_ROOT)/../test/benchmark/build/hex
SIMV := $(basename $(shell find $(HEX_DIR) -type f -name '*[hex]'))
RUN := $(addprefix RUN., $(SIMV))

dump_on ?= 1
DEFINE := SYNTHESIS+DPRAM64_2R1W+REG_TEST
# DEFINE += HEX_DIR=$(shell find $(HEX_DIR) -type f -name '*[hex]' | xargs -0 | sed "s/ /+/g")

default: $(RUN) 

.PHONY: compile, run, wave, clean

%: RUN.$(SIMV)

$(HEX_DIR)/%: 
	@true

SIMV:
	vcs +vcs+lic+wait -sverilog -kdb \
		+vc+list +vpi \
		+vcs+flush+all \
		+define+$(DEFINE)+HAHA \
		-o Riscv_Green \
		+lint=TFIPC-L -full64 -F ${FILE_LIST} \
		-top $(TOP_MODULE) -timescale=1ns/1ps \
		-v2k_generate -debug_access+all \
		+vcs+loopreport+10000 \
		+error+10 +lint=PCWM-L -q

RUN.$(HEX_DIR)/%: $(HEX_DIR)/% SIMV
	-mkdir $(patsubst $(HEX_DIR)/%/, %, $(dir $<))
	-mkdir results
	time ./Riscv_Green +dumpon=0 \
				+HEX_DIR="$<.hex" \
				+HEX="$(notdir $<)" \
				+WAVE="$(sim_log)/$(patsubst $(HEX_DIR)/%/, %, $(dir $<))" \
	 			2>&1 | tee results/run_$(notdir $<).log

haha: SIMV
	time ./Riscv_Green +dumpon=$(dump_on) \
				+HEX_DIR="/work/stu/yzhang/workspace/hehecore-2-0/test/benchmark/build/hex/matmult-int.hex" \
				+HEX="matmult-int" \
				+WAVE="$(sim_log)/waves.fsdb" \
	 			2>&1 | tee run_2_$(debug_print_on).log

isa: SIMV
	time ./Riscv_Green +dumpon=$(dump_on) \
				+HEX_DIR="/work/stu/yzhang/workspace/hehecore-2-0/test/isa/build/hex/rv64mi/ld-misaligned.hex" \
				+HEX="coremark" \
				+WAVE="$(sim_log)/waves.fsdb" \
	 			2>&1 | tee run_2_$(debug_print_on).log

pk: 
	vcs +vcs+lic+wait -sverilog -kdb \
		+vc+list +vpi \
		+vcs+flush+all \
		+define+$(DEFINE)+HAHA+PK \
		-o Riscv_Green \
		+lint=TFIPC-L -full64 -F ${FILE_LIST} \
		-top $(TOP_MODULE) -timescale=1ns/1ps \
		-v2k_generate -debug_access+all \
		+vcs+loopreport+10000 \
		+error+10 +lint=PCWM-L -q

	time ./Riscv_Green +dumpon=$(dump_on) \
				+HEX_DIR="$(PROJ_ROOT)/test/linux/proxy_kernel/pk.hex" \
				+HEX="pk" \
				+PAYLOAD_DIR="$(PROJ_ROOT)/test/linux/proxy_kernel/hello.hex.new" \
				+PAYLOAD="hello" \
				+WAVE="$(sim_log)/waves.fsdb" \
	 			2>&1 | tee run_2_$(debug_print_on).log
run-pk:
	time ./Riscv_Green +dumpon=$(dump_on) \
				+HEX_DIR="$(PROJ_ROOT)/test/linux/proxy_kernel/pk.hex" \
				+HEX="pk" \
				+WAVE="$(sim_log)/waves.fsdb" \
	 			2>&1 | tee run_2_$(debug_print_on).log

debug:
	$(info $(SIMV))
	$(info $(notdir $(SIMV)))

wave:
	Verdi-SX -ssf $(sim_log)/waves.fsdb