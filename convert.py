import os
import re

# input
spike = open("vcs_test/test.log", "r")
content = spike.readlines()
instructions = []
for line in content:
    if (re.match(r'core   0: [0-3] ',line)):
        instructions.append(line)
spike.close()

# print(instructions[1])

# output
cosim = open("vcs_test/spike.log", "w")
for line in instructions:
    cosim.write("-----\n")
    # convert
    line_obj = re.search(r"core   0: [0-3] 0x00000000(.+) \(0x(.+)\)([\s\S]*?)\n", line)
    pc = line_obj.group(1)
    instr = line_obj.group(2)
    action = line_obj.group(3)
    cosim.write("0x" + pc + "\n")
    if action != "":
        if "mem" not in action:
            action_obj = re.search(r" (.+) (.+)", action)
            reg = action_obj.group(1)
            val = action_obj.group(2)
            cosim.write(reg.strip() + " <- " + val.strip() + "\n")
        elif action[1:4] != "mem":
            action_obj = re.search(r" (.+) (.+) mem (.+)", action)
            reg = action_obj.group(1)
            val = action_obj.group(2)
            addr = action_obj.group(3)
            cosim.write(reg.strip() + " <- " + val.strip() + "\n")
        else:
            action_obj = re.search(r" mem 0x(.+) 0x(.+)", action)
            addr = action_obj.group(1)
            val = action_obj.group(2).strip()
            cosim.write("0x" + "0" * (16 - len(val))  + val + " -> 0x" + addr.strip() + "\n")

cosim.close()
