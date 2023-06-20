# for all files in sail_log (rv64*-p-*.log), 
# for all instructions in the file,
# parse the decoding information to get backend inputs
# write the inputs into a CSV file (tb_input/rv64*-p-*.csv)

import os
import re
import csv
from params import *

frontend_params = [
    # "valid_real_branch_i", "real_branch_i", "trap_vector_i", "mret_vector_i",
    # "trap", "mret", "wfi", "icache_ready_i", "icache_valid_i", "fetch_data_i",
    # "ready_in_i", "branch_back_i", "csr_data_i", "csr_readable_i", "csr_writeable_i"
]

backend_params = [
    "uses_rs1", "uses_rs2", "uses_csr", "uses_rd", 
    "pc_i", "next_pc_i", "is_alu", "deco_alu_select_a_i", "deco_alu_select_b_i",
    "cmp_function_i", "imm_data_i", "half", "alu_function_i", "alu_function_modifier_i",
    "branch_i", "jump_i", "load_i", "store_i", "load_store_size_i", "load_signed_i",
    "rs1_address", "rs2_address", "rd_address", "csr_address_i",
    "csr_read_i", "csr_write_i", "wfi_i", "mret_i", "is_fence_i"
]

def param_gen(field_dict, for_backend):
    param_dict = {}
    if for_backend == False:
        param_list = frontend_params
    else:
        param_list = backend_params
    for param in param_list:
        param_dict[param] = globals()[param](field_dict)
    return param_dict

def parse_instr(segment, filename, dict_writer, for_backend):
    # parse the string segment of a single instruction
    # 1. match the line of instruction
    instr_obj = re.search(r"\[(.*)\] \[(.*)\]: (.*) \((.*)\) ([\s\S]*?)\n", segment)
    index = instr_obj.group(1)
    mode = instr_obj.group(2)
    pc = instr_obj.group(3)
    instr = instr_obj.group(4)
    assemb = instr_obj.group(5)
    # 2. match the lines of decoding
    decode_obj = re.search(r">>> decode >>>\n([\s\S]*)\n<<< decode <<<", segment)
    decode = decode_obj.group(1)
    fields = decode.split("\n")

    # build a dict for the above fields
    field_dict = {}
    field_dict["index"] = index
    field_dict["pc"] = pc
    field_dict["instr"] = instr
    field_dict["assemb"] = assemb
    for field in fields:
        field_dict[field.split("=")[0]] = field.split("=")[1]

    # generate parameters and write into the csv file
    param_dict = param_gen(field_dict, for_backend)
    if for_backend == False:
        tb_input = open("./frontend_input/{}.csv".format(filename), "a")
    else:
        tb_input = open("./backend_input/{}.csv".format(filename), "a")
    dict_writer.writerow(param_dict)
    tb_input.close()

def parse_log(for_backend):
    logs = os.listdir("./sail_log")
    for log in logs:
        # 1. read sail log and identify instructions
        sail = open("./sail_log/{}".format(log), "r")
        content = sail.read().split("\n\n")[:-1]
        sail.close()
        # 2. create output csv file
        if for_backend == False:
            tb_input = open("./frontend_input/{}.csv".format(log.split(".")[0]), "w")
            writer = csv.DictWriter(tb_input, fieldnames=frontend_params)
        else:
            tb_input = open("./backend_input/{}.csv".format(log.split(".")[0]), "w")
            writer = csv.DictWriter(tb_input, fieldnames=backend_params)
        writer.writeheader()
        # 3. generate tb input and write csv file
        for segment in content:
            parse_instr(segment, log.split(".")[0], writer, for_backend)
        tb_input.close()

if __name__ == "__main__":
    # generate frontend tb input
    # parse_log(False)
    # generate backend tb input
    parse_log(True)