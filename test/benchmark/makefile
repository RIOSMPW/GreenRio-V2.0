# == Directories
SRC_DIR   := src
BUILD_DIR := build
DISASSEMBLY_DIR := build/disassembly
HEX_DIR   := build/hex
# ==

# == Files
TESTS_DHRY := $(wildcard $(SRC_DIR)/dhrystone/*.c)
BENCHMARK_SRC := $(shell find . -type f -name '*.riscv')
# TEST_BINS  := $(patsubst $(SRC_DIR)/%.S, $(BUILD_DIR)/%, $(TESTS))
# TEXTS := $(patsubst $(BUILD_DIR)/%, $(DISASSEMBLY_DIR)/%.txt, $(TEST_BINS))
# ==
BENCHMARK_BASE := $(patsubst ./%, %, $(BENCHMARK_SRC))
BENCHMARK := $(patsubst %.riscv, %, $(BENCHMARK_BASE))
BENCHMARK_RUN := $(addprefix RUN., $(BENCHMARK))


# == Tools
CC      := riscv64-unknown-elf-gcc
OBJDUMP := riscv64-unknown-elf-objdump
ELF2HEX := elf2hex
# ==

# == elf parameter
HEX_WIDTH := 16 	#bytes
HEX_DEPTH := 2048
HEX_BASE  := 2147483648
# ==

CFLAGS := -DPREALLOCATE=1 -v -mcmodel=medany -static -std=gnu99 -O2 -ffast-math -fno-common -fno-builtin-printf -fno-tree-loop-distribute-patterns
CLINKS := -static -nostdlib -nostartfiles -lm -lgcc -T ../include/test_dhrystone.ld


default: $(BENCHMARK_RUN)

.SECONDARY:
.SECONDEXPANSION:
.PHONY: build clean coremark benchmark

clean:
	find $(BUILD_DIR) -type f | xargs rm -f

build: $(TEST_BINS)  $(BUILD_DIR) $(DISASSEMBLY_DIR) $(HEX_DIR)

debug:
	$(info $(BENCHMARK_BASE))
	$(info $(BENCHMARK))
	$(info $(BENCHMARK_RUN))

#由于64位链接器无法识别目录，需要手动添加目录
haha: $(TESTS_DHRY)
	@echo "Building $@"
	$(CC) $(CFLAGS) $(CLINKS) $< -o $@
	$(OBJDUMP) -D $@ > $(patsubst $(BUILD_DIR)/%, $(DISASSEMBLY_DIR)/%.txt, $@)
	$(ELF2HEX) $(HEX_WIDTH) $(HEX_DEPTH) $@ $(HEX_BASE) > $(patsubst $(BUILD_DIR)/%, $(HEX_DIR)/%.hex, $@)

$(BENCHMARK):
	@true

RUN.%: %
	$(OBJDUMP) -d $<.riscv > build/disassembly/$<.txt
	$(ELF2HEX) $(HEX_WIDTH) $(HEX_DEPTH) $<.riscv $(HEX_BASE) > build/hex/$<.hex

dhrystone:
	$(OBJDUMP) -D dhrystone.riscv > build/disassembly/dhrystone.txt
	$(ELF2HEX) $(HEX_WIDTH) $(HEX_DEPTH) dhrystone.riscv $(HEX_BASE) > build/hex/dhrystone.hex

coremark:
	$(OBJDUMP) -D coremark.riscv > build/disassembly/coremark.txt
	$(ELF2HEX) $(HEX_WIDTH) $(HEX_DEPTH) coremark.riscv $(HEX_BASE) > build/hex/coremark.hex
	

%/:
	mkdir -p $@


