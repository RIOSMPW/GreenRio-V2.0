import os
import sys
SV2V = os.environ['SV2V']
PROJ_ROOT = os.environ['PROJ_ROOT']
FILELIST_DIR = f"{PROJ_ROOT}/src/lsuv1/flist.f"
NEW_FILELIST_DIR = f"{PROJ_ROOT}/src/lsuv1/vflist.f"

usage = """\
a stupid python script.
usage:
    use ONLY one of the following options.
    -g, --generate, generate    : genegate v from sv using a filelist
    -c, --clean, clean          : delete generated v files
    -h, --help, help            : help
    the following option must be included:
    -d <filelist dir>           : goal filelist. e.g. /src/lsuv1/flist.f.
"""

def parse(command):
    if command == "-h" or command == "--help" or command == "help":
        print(usage)
    elif command == "-g" or command == "--generate" or command == "generate":
        flist = open(FILELIST_DIR, mode='r')
        newflist = open(NEW_FILELIST_DIR, mode='w')
        fstring = ""
        for line in flist:
            if(line == "\n"):
                continue
            if(line.find(".v") != -1):
                newflist.write(line)   
                continue
            if(line[0] == '/'  and line[1] == '/'):
                continue
            if(line[0] == '+' ):
                continue
            newflist.write(line.replace(".sv", ".v"))
            line = line.replace("\n", "")
            fstring += line
            fstring += " "
        print(fstring)
        os.system(f"{SV2V} {fstring} --write=adjacent --define=SYNTHESIS")
        flist.close()
        newflist.close()
    elif command == "-c" or command == "--clean" or command == "clean":
        flist = open(FILELIST_DIR, mode='r')
        rmfilelist = []
        for line in flist:
            if(line == "\n"):
                continue
            if(line.find(".v") != -1):
                continue
            if(line[0] == '/'  and line[1] == '/'):
                continue
            if(line[0] == '+' ):
                continue
            line = line.replace("\n", "")
            rmfilelist.append(line.replace(".sv", ".v"))
        flist.close()
        for file in rmfilelist:
            os.system(f"rm {file}")
        # print(rmfilelist)
    else:
        print("illegal usage: " + command)
        print(usage)

argv = sys.argv
dir = ""
if '-d' in argv:
    dir_index = argv.index('-d') + 1
    if(dir_index > len(argv)):
        print("illegal usage: -d must be followed by flist dir")
        print(usage)
    dir = argv[dir_index]
    FILELIST_DIR = f"{PROJ_ROOT}/{dir}"
    filename = dir.split('/')[-1]
    new_dir = dir.replace(filename, "v" + filename)
    NEW_FILELIST_DIR = f"{PROJ_ROOT}/{new_dir}"
else:
    print("illegal usage: must contain -d")
    print(usage)

for arg in argv:
    if(arg == "-d" or arg == dir or arg == "sv2v.py"):
        continue
    parse(arg)