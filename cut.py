import os
import sys


if (int(sys.argv[1])):
    sequence = int(sys.argv[1])
else:
    sequence = 0

width = 800000
turn = width * sequence
offset = 14
if sequence > 0:
    offset = offset + 2
else:
    offset = offset

# input
spike = open("vcs_test/spike.log", "r")
spike_content = spike.readlines()
print(len(spike_content))
spike_content_new = spike_content[0 + offset + turn:width + offset + turn]

# output
spike_new = open("vcs_test/spike_new.log", "w")
for line in spike_content_new:
    spike_new.write(line)

spike.close()
spike_new.close()


co_sim = open("vcs_test/logs/isa.log", "r")
co_content = co_sim.readlines()
co_content_new = co_content[0 + turn:width + turn]

co_sim_new = open("vcs_test/haha_new.log", "w")
for line in co_content_new:
    co_sim_new.write(line)

co_sim_new.close()
co_sim.close()

print("times: ", sequence)