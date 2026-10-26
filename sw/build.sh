#!/bin/bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "================================================="
echo " Compiling C software flow for RV32I Core        "
echo "================================================="

# 1. Compile C code and boot startup assembly into an ELF binary
riscv64-unknown-elf-gcc -O2 -mabi=ilp32 -march=rv32i -nostdlib -T sw/link.ld sw/boot.s sw/main.c -o sw/main.elf

# 2. Emit one 32-bit instruction word per $readmemh entry.
riscv64-unknown-elf-objcopy --verilog-data-width=4 -O verilog sw/main.elf program.hex

echo "[SUCCESS] Generated program.hex in project root!"