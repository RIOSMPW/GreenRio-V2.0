# >>> functions to generate frontend input signals >>>



# <<< functions to generate frontend input signals <<<

# -----------------------------------------------

# >>> functions to generate backend input signals >>>

def uses_rs1(field_dict):
    if "rs1" in field_dict:
        if field_dict["opcode"] == "0b1110011": # system instruction
            if field_dict["funct3"][-2:] != "00": # CSR instruction
                if field_dict["funct3"][-3] != "1": # not CSR immediate
                    return 1
                else: # CSR immediate
                    return 0
            elif "funct7" in field_dict and field_dict["funct7"] == "0b0001001": # sfence.vma
                return 1
            else:
                return 0
        elif field_dict["opcode"] == "0b0001111": # fence
            return 0
        else:
            return 1
    else:
        return 0

def uses_rs2(field_dict):
    if "rs2" in field_dict:
        if field_dict["opcode"] == "0b1110011": # system instruction
            if field_dict["funct3"] == "000" and field_dict["funct7"] == "0b0001001": # sfence.vma
                return 1
            else: 
                return 0
        else:
            return 1
    else:
        return 0

def uses_csr(field_dict):
    if field_dict["opcode"] == "0b1110011" and field_dict["funct3"][-2:] != "00": # CSR instruction
        if field_dict["funct3"][-2:] == "01" and field_dict["rd"] == "0b00000": # CSR write but rd is 0
            return 0
        else: 
            return 1
    else:
        return 0

def uses_rd(field_dict):
    if "rd" in field_dict:
        if field_dict["opcode"] == "0b1110011": # system instruction
            if field_dict["funct3"][-2:] != "00": # CSR instruction
                return 1
            else:
                return 0
        elif field_dict["opcode"] == "0b0001111": # fence
            return 0
        else:
            return 1
    else:
        return 0

def pc_i(field_dict):
    return field_dict["pc"]

def next_pc_i(field_dict):
    pc_int = int(field_dict["pc"], 16)
    tmp_pc = hex(pc_int + 4)[2:]
    len_tmp = len(tmp_pc)
    return "0x" + "0" * (16 - len_tmp) + tmp_pc

def is_alu(field_dict):
    use_alu = ["0b0110111", "0b0010111", "0b1101111", "0b1100111", "0b1100011", 
        "0b0010011", "0b0011011", "0b0110011", "0b0111011"]
    if field_dict["opcode"] in use_alu:
        return 1
    elif field_dict["opcode"] == "0b1110011" and field_dict["funct3"][-2:] != "00": # CSR instruction
        return 1
    else:
        return 0

def deco_alu_select_a_i(field_dict):
    if field_dict["opcode"] in ["0b1100111", "0b0000011", 
    "0b0100011", "0b0010011", "0b0011011", "0b0110011", "0b0111011"] or \
    (field_dict["opcode"] == "0b1110011" and field_dict["funct3"] in ["0b001", "0b010", "0b011"]):
        return "0b00" # ALU_SEL_REG
    elif field_dict["opcode"] in ["0b0010111", "0b1101111", "0b1100011"]:
        return "0b10" # ALU_SEL_PC
    else:
        return "0b01" # ALU_SEL_IMM

def deco_alu_select_b_i(field_dict):
    if field_dict["opcode"] in ["0b0110011", "0b0111011"]:
        return "0b00" # ALU_SEL_REG
    elif field_dict["opcode"] == "0b1110011" and \
    field_dict["funct3"] in ["0b010", "0b011", "0b110", "0b111"]:
        return "0b11" # ALU_SEL_CSR
    else:
        return "0b01" # ALU_SEL_IMM

def cmp_function_i(field_dict):
    return "0b" + bin_instr(field_dict["instr"])[-15:-12]

def imm_data_i(field_dict):
    if field_dict["opcode"] == ("0b0110111" or "0b0010111"): # U-type imm
        return field_dict["imm"] + "000"
    elif field_dict["opcode"] == "0b1101111": # J-type imm
        return "0b" + field_dict["imm"][2] * 12 + field_dict["imm"][3:]
    elif field_dict["opcode"] == ("0b1100111" or "0b0000011"): # I-type imm: jalr, load
        imm_bin = bin_imm12(field_dict["imm"])
        return "0b" + imm_bin[2] * 21 + imm_bin[3:]
    elif field_dict["opcode"] == ("0b0010011" or "0b0011011"): # I-type imm: others
        if "shamt" in field_dict:
            if "funct7" in field_dict: # 5-bits shamt
                imm_bin = field_dict["funct7"] + field_dict["shamt"][2:]
            else: # 6-bits shamt
                imm_bin = field_dict["funct6"] + field_dict["shamt"][2:]
        else: # 12-bits imm
            imm_bin = bin_imm12(field_dict["imm"])
        return "0b" + imm_bin[2] * 21 + imm_bin[3:]
    elif field_dict["opcode"] == "0b1100011": # B-type imm
        return "0b" + field_dict["imm"][2] * 20 + field_dict["imm"][3:]
    elif field_dict["opcode"] == "0b0100011": # S-type imm
        imm_bin = bin_imm12(field_dict["imm"])
        return "0b" + imm_bin[2] * 21 + imm_bin[3:]
    elif field_dict["opcode"] == "0b1110011" and \
    field_dict["funct3"] in ["101", "110", "111"]: # CSR imm
        return "0b" + "0" * 27 + field_dict["rs1"][2:]
    else:
        return 0

def half(field_dict):
    if field_dict["opcode"] == ("0b0011011" or "0b0111011"):
        return 1
    else:
        return 0

def alu_function_i(field_dict):
    if field_dict["opcode"] in ["0b0010111", "0b1101111", 
    "0b1100111", "0b1100011", "0b0000011", "0b0100011"]:
        return "0b000" # ALU_ADD_SUB
    elif field_dict["opcode"] in ["0b0010011", "0b0011011", "0b0110011", "0b0111011"]:
        return "0b" + bin_instr(field_dict["instr"])[-15:-12]
    elif field_dict["opcode"] == "0b1110011" and field_dict["funct3"] in ["0b011", "0b111"]:
        return "0b111" # ALU_AND_CLR
    else:
        return "0b110" # ALU_OR

def alu_function_modifier_i(field_dict):
    if field_dict["opcode"] == "0b1110011" and field_dict["funct3"] in ["0b011", "0b111"]:
        return 1
    elif field_dict["opcode"] in ["0b0010011", "0b0011011"]:
        instr = bin_instr(field_dict["instr"])
        if instr[-15:-12] == "101" and instr[-31] == "1":
            return 1
        else:
            return 0
    elif field_dict["opcode"] in ["0b0110011", "0b0111011"]:
        instr = bin_instr(field_dict["instr"])
        if instr[-31] == "1":
            return 1
        else:
            return 0
    else: 
        return 0

def branch_i(field_dict):
    if field_dict["opcode"] == ("0b1101111" or "0b1100111" or "0b1100011"):
        return 1
    else:
        return 0

def jump_i(field_dict):
    if field_dict["opcode"] == ("0b1101111" or "0b1100111"):
        return 1
    else:
        return 0

def load_i(field_dict):
    if field_dict["opcode"] == "0b0000011":
        return 1
    else:
        return 0

def store_i(field_dict):
    if field_dict["opcode"] == "0b0100011":
        return 1
    else:
        return 0

def load_store_size_i(field_dict):
    return "0b" + bin_instr(field_dict["instr"])[-14:-12]

def load_signed_i(field_dict):
    if bin_instr(field_dict["instr"])[-15] == "1":
        return 0
    else:
        return 1

def rs1_address(field_dict):
    return "0b" + bin_instr(field_dict["instr"])[-20:-15]

def rs2_address(field_dict):
    return "0b" + bin_instr(field_dict["instr"])[-25:-20]

def rd_address(field_dict):
    if uses_rd(field_dict):
        return "0b" + bin_instr(field_dict["instr"])[-12:-7]
    else:
        return 0

def csr_address_i(field_dict):
    return "0b" + bin_instr(field_dict["instr"])[-32:-20]

def csr_read_i(field_dict):
    if field_dict["opcode"] == "0b1110011" and field_dict["funct3"][-2:] != "00": # CSR instruction
        return 1
    else:
        return 0    

def csr_write_i(field_dict):
    if field_dict["opcode"] == "0b1110011" and field_dict["funct3"][-2:] != "00": # CSR instruction
        if field_dict["funct3"] in ["0b001", "0b101"]:
            return 1
        else:
            if int(rs1_address(field_dict), 2):
                return 1
            else:
                return 0
    else:
        return 0

def wfi_i(field_dict):
    return field_dict["assemb"] == "wfi"

def mret_i(field_dict):
    return field_dict["assemb"] == "mret"

def is_fence_i(field_dict):
    if field_dict["opcode"] == "0b0001111":
        return 1
    else:
        return 0

# <<< functions to generate backend input signals <<<

# -----------------------------------------------

# >>> util functions >>>

# convert an instruction string from hex to bin
def bin_instr(hex_instr):
    tmp_instr = bin(int(hex_instr, 16))[2:]
    len_tmp = len(tmp_instr)
    return "0b" + "0" * (32 - len_tmp) + tmp_instr

# convert an 12-bit imm string from hex to bin
def bin_imm12(hex_imm12):
    tmp_imm = bin(int(hex_imm12, 16))[2:]
    len_tmp = len(tmp_imm)
    return "0b" + "0" * (12 - len_tmp) + tmp_imm

# <<< util functions <<<