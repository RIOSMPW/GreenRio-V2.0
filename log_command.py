import os
import re
import sys

def parse_log():
    sail_name = sys.argv[1]
    sail = open(sail_name, "r")
    content = sail.read().split("0x00001010\n-----\n")[1]
    content = '-----\n' + content
    content = content.split("-----\n0x80000040\n")[0]
    sail.close()

    sail = open(sail_name, "w")
    content = re.sub(r"mark\n([a-z]*)\n", "", content)
    content = re.sub(r"mark\nx(.*) <- 0x(.*)\n", "", content)
    content = re.sub(r"mark\n", "", content)
    sail.write(content)
    sail.close()

if __name__ == "__main__":
    parse_log()