# UT

## Contents

1. ELF files of rv64ui and rv64mi ISA test in hehecore/ut/elf
2. Disassembly files of rv64ui and rv64mi ISA test in hehecore/ut/dump
3. The cosim tb of backend in backend.cpp
4. Python code to generate backend input signals (input_gen.py, params.py)

## Usage

On cad1, before running these commands,
```
source /work/stu/yzhu/.bashrc
make clean
```

1. To convert ELF files to hex format
```
make prep
make hex
```
2. To generate sail logs for ELF files
```
make prep
make sail
```
3. To generate input signals (in CSV format) for tb
```
make prep
make sail
make tb_input
```
or simply
```
make
```
to get all of the above files (hex, sail log, tb input).

## Cosim

After generating input signals,
```
cd ..
make backend_cosim
```
we can get wave.vcd and backend_cosim.log
