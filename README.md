# KASUMI, the RISC-V RV32I implementation written by Verilog HDL
## Introduction
KASUMI is a Implemenation of RV32I processor written by Veirlog HDL. 
This is a asignment of my university homework so it is normal that designing RISC-V is designed by using Chisel, however my professor demand to me that "You must design RISC-V by using Verilog HDL, NO CHISEL".
That is reason of KASUMI was written by Verilog.

KASUMI supports basic insturctions of RISC-V(RV32I), there is no plan to support any modes for Operating Systems. KASUMI was designed for microcontroller uses. Maybe supervisor mode and user mode will be implmented at SETSUNA.

The name of processor was influenced by members of Nijigasaki School Idol Club. However, I selected general verbs and nouns only. KASUMI is a general verb and noun of Japanese.  

## Directories
- core: Core of KASUMI
- cache: (Under Construction) Cache Memory
- test_mem: Register File and Block RAM for Test
- hex: Verilog Hex File for Test
- kasumi.v: (Under Construction) Top of KASUMI
- kasumi_test.v: Top of KASUMI for Test

## Environment of Evaluation
### Simulation
Icarus Verilog and GtkWave on ARM Mac(Macbook Pro 14')

### FPGA
Zedboard(Xilinx Zynq Series FPGA) and Vivado

## License
MIT License

## Written by
Prokuma, A Master Course Student, Nara Institute of Science and Technology

## This Project Supported by
Computer Architecture Laboratory, Nara Institute of Science and Technology

## Special Thanks
- Yasuhiko Nakashima, NAIST: Support of Zynq FPGA Board and Advice of How to Design
- Members of Arch. Lab.: Support of Designing KASUMI
- Kasumi Nakasu, Nijigasaki School Idol Club: Influenced by hers name
- Kanata Konoe, Nijigasaki School Idol Club: Support of Mental health
- Members of OPTiM Kyutech CSSE Office: Motivation of KASUMI
- Takaichi Yoshida, Kyutech CSSE: Motivation of Self-designed Processor
- Members of Composite Computer Club, Kyutech CSSE: Motivation of Continuing Computer Science