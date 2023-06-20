UT_DIR := ./
ELF_DIR := ./elf
HEX_DIR := ./hex
LOG_DIR := ./sail_log
FRTND_INPUT := ./frontend_input
BKND_INPUT := ./backend_input
EMUL_DIR := /work/stu/xwan/tools/sail-riscv/c_emulator

PRECLUDED_NAMES = rv64mi-p-access rv64mi-p-csr rv64mi-p-illegal rv64mi-p-ma_fetch
PRECLUDED_TESTS := $(foreach name, $(PRECLUDED_NAMES), $(LOG_DIR)/$(name).log)

ELF_FILES := $(wildcard $(ELF_DIR)/*)
SAIL_LOG := $(patsubst $(ELF_DIR)/%, $(LOG_DIR)/%.log, $(ELF_FILES))
HEX_FILES := $(patsubst $(ELF_DIR)/%, $(HEX_DIR)/%.hex, $(ELF_FILES))

all: prep hex sail tb_input

.PHONY: all prep hex sail tb_input clean

prep:
	mkdir $(LOG_DIR)
	mkdir $(HEX_DIR)
	mkdir $(FRTND_INPUT)
	mkdir $(BKND_INPUT)

hex: $(HEX_FILES)

$(HEX_DIR)/%.hex : $(ELF_DIR)/%
	elf2hex 8 2048 $< 2147483648 > $@

sail: $(SAIL_LOG)

$(LOG_DIR)/%.log : $(ELF_DIR)/%
	$(EMUL_DIR)/riscv_sim_RV64 $< > $@

tb_input:
	-rm $(PRECLUDED_TESTS)
	python3 sail_log.py
	# python3 input_gen.py

clean: 
	-rm -rf $(LOG_DIR) $(HEX_DIR) $(FRTND_INPUT) $(BKND_INPUT)