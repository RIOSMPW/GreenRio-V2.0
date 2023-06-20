# == Directories
SRC_DIR   := src
BUILD_DIR := build
DISASSEMBLY_DIR := build/disassembly
HEX_DIR   := build/hex
# ==

# == Files
TESTS := $(shell find $(SRC_DIR) -type f -name '*.[Sc]')
TEST_BINS  := $(patsubst $(SRC_DIR)/%.S, $(BUILD_DIR)/%, $(TESTS))
# TEXTS := $(patsubst $(BUILD_DIR)/%, $(DISASSEMBLY_DIR)/%.txt, $(TEST_BINS))
# ==

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

CFLAGS := -O0 -march=rv64imc -mabi=lp64 -nostdlib -mcmodel=medany -fvisibility=hidden -static -I../include -Wl,-Bstatic,-T,../include/test.ld,--strip-debug -mno-relax

.SECONDARY:
.SECONDEXPANSION:
.PHONY: build clean

clean:
	find $(BUILD_DIR) -type f | xargs rm -f

build: $(TEST_BINS)  $(BUILD_DIR) $(DISASSEMBLY_DIR) $(HEX_DIR)

#由于64位链接器无法识别目录，需要手动添加目录
$(BUILD_DIR)/%: $(SRC_DIR)/%.S
	@echo "Building $@"
	$(CC) $(CFLAGS) $< -o $@
	$(OBJDUMP) -D $@ > $(patsubst $(BUILD_DIR)/%, $(DISASSEMBLY_DIR)/%.txt, $@)
	$(ELF2HEX) $(HEX_WIDTH) $(HEX_DEPTH) $@ $(HEX_BASE) > $(patsubst $(BUILD_DIR)/%, $(HEX_DIR)/%.hex, $@)

%/:
	mkdir -p $@


