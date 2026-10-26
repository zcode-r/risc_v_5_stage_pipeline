# RV32I Five-Stage Pipelined Processor

A 32-bit RISC-V integer processor implemented in SystemVerilog using a classic in-order five-stage pipeline. The project includes data forwarding, load-use hazard handling, control-flow flushing, RTL verification testbenches, and a bare-metal C compilation workflow.

## Table of Contents

1. [Overview and Features](#overview-and-features)
2. [Repository Structure](#repository-structure)
3. [Pipeline Architecture](#pipeline-architecture)
4. [Hazard Handling](#hazard-handling)
5. [Supported Instructions](#supported-instructions)
6. [Memory Architecture](#memory-architecture)
7. [Software Toolchain](#software-toolchain)
8. [Verification and Testing](#verification-and-testing)
9. [Getting Started](#getting-started)
10. [Waveform Analysis](#waveform-analysis)
11. [Future Improvements](#future-improvements)

---

## Overview and Features

### Key Features

- **Architecture:** 32-bit, in-order, five-stage pipelined processor.
- **Instruction Set:** Implemented subset of the RISC-V RV32I base integer instruction set.
- **Pipeline Stages:** Instruction Fetch (IF), Instruction Decode (ID), Execute (EX), Memory Access (MEM), and Writeback (WB).
- **Data Hazard Handling:** Operand forwarding and load-use hazard detection.
- **Control Hazard Handling:** Pipeline flushing for branches and jumps.
- **Register File:** 32 general-purpose 32-bit integer registers, with `x0` hardwired to zero.
- **Memory:** Separate instruction and data memories.
- **Software Execution:** Bare-metal C programs compiled for the RV32I target.
- **Verification:** SystemVerilog testbenches for processor-level and compiled software execution.
- **Simulation and Debugging:** Icarus Verilog and GTKWave.

## Repository Structure

```text
.
├── Makefile
├── README.md
├── program.hex
├── hardware_test.hex
├── rtl/
│   ├── pack.sv
│   ├── riscv_top.sv
│   ├── control_unit.sv
│   ├── alu_control.sv
│   ├── alu.sv
│   ├── imm.sv
│   ├── instruction_mem.sv
│   ├── data_mem.sv
│   ├── reg_file.sv
│   ├── forwarding_unit.sv
│   └── hazard_unit.sv
├── sw/
│   ├── main.c
│   ├── boot.s
│   ├── link.ld
│   └── build.sh
└── tb/
    ├── riscv_top_tb.sv
    └── riscv_sw_tb.sv
```

### Directory Description

| Directory/File | Description |
|---|---|
| `rtl/` | Processor datapath, control logic, memories, and hazard units |
| `sw/` | Bare-metal C application, assembly startup code, linker script, and build script |
| `tb/` | SystemVerilog testbenches for hardware and software execution |
| `Makefile` | Build and simulation automation |
| `hardware_test.hex` | Machine-code image for hardware regression testing |
| `program.hex` | Machine-code image generated from the software build |

## Pipeline Architecture

The processor follows a classic five-stage pipeline.

```text
       +------+     +------+     +------+     +------+     +------+
PC --->|  IF  |---->|  ID  |---->|  EX  |---->| MEM  |---->|  WB  |
       +------+     +------+     +------+     +------+     +------+
          |             |            |            |            |
          |             |            |            |            |
          +-------------+------------+------------+------------+
                       Pipeline Control
                  Forwarding / Stall / Flush
```

### 1. Instruction Fetch (IF)

- Fetches the instruction using the current Program Counter (PC).
- Retrieves instructions from instruction memory.
- Advances the PC to the next sequential instruction or redirects it when control flow changes.

### 2. Instruction Decode (ID)

- Decodes the instruction fields, including `opcode`, `rs1`, `rs2`, `rd`, `funct3`, and `funct7`.
- Reads source operands from the register file.
- Generates sign-extended immediate values using the immediate generator.

### 3. Execute (EX)

- Performs arithmetic and logical operations using the ALU.
- Evaluates branch conditions.
- Calculates branch and jump target addresses.
- Uses forwarding logic to obtain the latest available operand values when required.

### 4. Memory Access (MEM)

- Performs data-memory reads for load instructions.
- Performs data-memory writes for store instructions.
- Passes the appropriate result toward the writeback stage.

### 5. Writeback (WB)

- Writes the selected result into the destination register.
- Depending on the instruction, the result may originate from the ALU, data memory, or a link address.

## Hazard Handling

Pipeline hazards occur when instructions cannot proceed normally because of data dependencies or changes in control flow.

### Data Forwarding

Forwarding reduces unnecessary stalls by supplying a result directly to a dependent instruction instead of waiting for it to be written back to the register file.

The forwarding unit handles dependencies involving results available from later pipeline stages.

| Hazard | Purpose |
|---|---|
| EX-to-EX forwarding | Supplies a recent execution result to a dependent instruction in the EX stage |
| MEM-to-EX forwarding | Supplies a result from the later pipeline stage to a dependent instruction |
| Register dependency checking | Compares source and destination register indices to identify dependencies |

Forwarding must account for register-write control and ignore `x0` as a destination.

### Load-Use Hazard

A load-use hazard occurs when an instruction immediately depends on a value that a preceding load instruction has not yet made available.

The hazard unit handles this dependency using a stall and pipeline bubble when required.

Typical actions include:

- Holding the PC.
- Holding the IF/ID pipeline register.
- Inserting a bubble into the next pipeline stage.

### Control Hazards

Branches and jumps can change the program's execution path.

When a branch is taken or a jump redirects execution, instructions fetched from the incorrect path must be flushed according to the processor's control logic.

The hazard unit coordinates the necessary PC redirection and pipeline flushing.

## Supported Instructions

The processor implements a subset of the RV32I base integer instruction set.

### R-Type Instructions

```text
ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
```

### I-Type Instructions

```text
ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI, JALR
```

### Load and Store Instructions

```text
LW, SW
```

### Branch Instructions

```text
BEQ, BNE, BLT, BGE, BLTU, BGEU
```

### Upper Immediate Instructions

```text
LUI, AUIPC
```

### Jump Instructions

```text
JAL
```

> **Note:** This list describes the intended instruction subset. Confirm that every listed instruction is implemented and tested in the current RTL revision. Instructions such as byte and halfword memory operations, multiplication and division, atomic operations, CSRs, and exception handling are outside the described scope unless implemented separately.

## Memory Architecture

The processor uses separate instruction and data memories, following a Harvard-style architecture.

### Instruction Memory

- Stores the program's machine-code instructions.
- Loads the program image using `$readmemh`.
- Uses the PC to select the instruction to fetch.

### Data Memory

- Stores data accessed by load and store instructions.
- Supports the memory operations implemented in the processor.
- Uses the configured memory depth and addressing logic defined in the RTL.

### Memory Layout

The software toolchain uses a linker script to place program sections and startup code into the configured memory layout.

The startup assembly initializes the stack pointer before calling the C program.

```text
Instruction Memory                 Data Memory
+----------------------+           +----------------------+
| Program Instructions |           | .data / .bss         |
| Startup Code         |           | Runtime Data         |
| Application Code     |           | Stack                |
+----------------------+           +----------------------+
```

The exact memory capacity, address mapping, word indexing, and stack boundary depend on the RTL and linker-script configuration.

## Software Toolchain

The project supports a bare-metal C workflow targeting a 32-bit RISC-V processor.

### Software Components

| File | Purpose |
|---|---|
| `sw/main.c` | C application logic |
| `sw/boot.s` | Startup assembly and stack initialization |
| `sw/link.ld` | Linker script for memory-section placement |
| `sw/build.sh` | Software compilation and machine-code generation |
| `program.hex` | Generated program image for simulation |

### Compilation Flow

```text
       sw/main.c
           |
           v
       sw/boot.s
           |
           v
       sw/link.ld
           |
           v
  RISC-V Cross-Compiler
           |
           v
       program.elf
           |
           v
         objcopy
           |
           v
       program.hex
           |
           v
   Instruction Memory
           |
           v
    Processor Execution
```

The build targets the RV32I instruction set and the ILP32 ABI.

Example compiler options:

```bash
-march=rv32i -mabi=ilp32
```

The exact compiler command and generated image format are determined by `sw/build.sh` and the Makefile.

## Verification and Testing

The project contains separate testbenches for hardware-level verification and compiled software execution.

### 1. Hardware Regression Test

**Testbench:** `tb/riscv_top_tb.sv`

**Program image:** `hardware_test.hex`

This testbench is intended to exercise processor functionality, including:

- Arithmetic and logical instructions.
- Data forwarding.
- Load-use hazard handling.
- Load and store operations.
- Branch and jump behavior.
- Pipeline stalls and flushing.

Expected register values and other verification results should be checked against the assertions in the actual testbench.

### 2. Software Execution Test

**Testbench:** `tb/riscv_sw_tb.sv`

**Program image:** `program.hex`

This testbench executes the machine code generated from the bare-metal C application.

The software test can verify:

- Startup and stack initialization.
- Execution of compiled C instructions.
- Correct arithmetic results.
- Return-value handling through the RISC-V ABI.

If the application computes a Fibonacci sequence, verify the expected result against the actual program input and implementation.

## Getting Started

### Prerequisites

The following tools are used by the documented workflow:

- Icarus Verilog
- VVP runtime
- GTKWave
- RISC-V cross-compiler
- GNU Make

On Ubuntu or WSL, install the available packages using:

```bash
sudo apt update
sudo apt install iverilog gtkwave make gcc-riscv64-unknown-elf
```

If a package is unavailable in your distribution, install the equivalent toolchain package for your environment.

### Clone the Repository

```bash
git clone <YOUR_REPOSITORY_URL>
cd <YOUR_REPOSITORY_DIRECTORY>
```

Replace the placeholders with your actual Git repository URL and directory name.

### Run the Tests

Run these commands from the project root, provided the corresponding targets exist in your Makefile.

**Run the hardware regression test:**

```bash
make test-hw
```

**Build and run the software execution test:**

```bash
make test-sw
```

**Run both test suites:**

```bash
make test
```

**Build the software image:**

```bash
make build-sw
```

**Clean generated artifacts:**

```bash
make clean
```

## Waveform Analysis

Waveform inspection helps debug pipeline execution, data dependencies, stalls, and control-flow changes.

If the simulation generates VCD waveform files, open them using GTKWave.

```bash
gtkwave riscv_top.vcd
```

For the software execution test, use the corresponding VCD filename generated by your testbench.

### Recommended Signals to Inspect

| Signal/Category | What to Observe |
|---|---|
| `clk`, `rst` | Clock cycles and reset behavior |
| PC and fetched instruction | Instruction sequencing |
| Source and destination register indices | Register dependencies |
| Forwarding control signals | Operand forwarding decisions |
| Stall signals | Load-use hazard handling |
| Flush signals | Control-hazard handling |
| Register-file contents | Architectural results |
| Data-memory signals | Load and store operations |

Signal names vary with the implementation. Select the signals exposed by your actual RTL hierarchy in GTKWave.

## Future Improvements

Potential extensions to the project include:

- Expanding RV32I instruction coverage.
- Improving verification with assertions and constrained-random testing.
- Adding performance counters and CPI analysis.
- Measuring the impact of forwarding and pipeline stalls.
- Improving automated regression testing.
- Adding FPGA synthesis and implementation support.
- Exploring a deeper pipeline or more advanced branch handling.

## Tools and Technologies

- **HDL:** SystemVerilog
- **Architecture:** RISC-V RV32I subset
- **Simulation:** Icarus Verilog
- **Waveform Debugging:** GTKWave
- **Software:** C and RISC-V assembly
- **Build Automation:** GNU Make and shell scripts

---

## Project Goal

The goal of this project is to understand and implement the fundamental components of a pipelined RISC-V processor, including instruction execution, datapath design, control logic, hazard handling, bare-metal software execution, and hardware verification.
