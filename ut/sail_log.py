import os
import re

def parse_log():
    logs = os.listdir("./sail_log")
    for log in logs:
        sail = open("./sail_log/{}".format(log), "r")
        content = sail.read().split("0x00001010\n-----\n")[1]
        content = '-----\n' + content
        content = content.split("-----\n0x80000040\n")[0]
        sail.close()

        sail = open("./sail_log/{}".format(log), "w")
        content = re.sub(r"mark\n([a-z]*)\n", "", content)
        content = re.sub(r"mark\nx(.*) <- 0x(.*)\n", "", content)
        content = re.sub(r"mark\n", "", content)
        sail.write(content)
        sail.close()

if __name__ == "__main__":
    parse_log()