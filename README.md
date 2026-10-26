# RV32I Five-Stage Pipeline

A small SystemVerilog implementation of a 32-bit RISC-V integer processor with
an in-order five-stage pipeline. The repository includes a hand-assembled
pipeline test program and a C-to-machine-code flow that runs a Fibonacci
example on the processor.

## Features

- Five pipeline stages: instruction fetch (IF), instruction decode (ID),
  execute (EX), memory access (MEM), and writeback (WB).
- 32 32-bit integer registers. Register `x0` always reads as zero.
- Forwarding from the MEM and WB stages to resolve common data dependencies.
- A load-use interlock that stalls fetch/decode and inserts a bubble.
- A taken-branch/jump flush to discard the instruction fetched along the
  wrong path.
- Instruction and data memories with configurable depth (default: 1,024
  32-bit words each).
- An RV32I integer instruction subset, described below.

## Repository layout

```text
.
├── Makefile
├── README.md
├── program.hex             # Machine code generated from sw/boot.s and sw/main.c
├── hardware_test.hex       # Hand-encoded test program for the pipeline
├── rtl/
│   ├── pack.sv             # Shared RISC-V opcodes, funct3 values, and ALU enum
│   ├── riscv_top.sv        # Five-stage datapath and pipeline registers
│   ├── control_unit.sv     # Opcode-level control signals
│   ├── alu_control.sv      # ALU operation selection
│   ├── alu.sv              # Integer arithmetic, logic, shifts, and comparisons
│   ├── imm.sv              # I/S/B/U/J immediate generation
│   ├── instruction_mem.sv  # Instruction ROM initialized with $readmemh
│   ├── data_mem.sv         # Word-addressed data RAM
│   ├── reg_file.sv         # 32-entry integer register file
│   ├── forwarding_unit.sv  # EX operand forwarding selection
│   └── hazard_unit.sv      # Load-use stall and control-flow flush logic
├── sw/
│   ├── main.c              # Fibonacci example
│   ├── boot.s              # Minimal startup code
│   ├── link.ld             # Places startup and program at address zero
│   └── build.sh            # Builds the ELF and emits program.hex
└── tb/
    ├── riscv_top_tb.sv     # Pipeline-feature test
    └── riscv_sw_tb.sv      # C-program execution test
```

The simulator executables, generated ELF, and waveform dumps are build
artifacts; the source files and both hex images are the useful inputs to keep
under version control.

## Pipeline overview

1. **IF — Instruction Fetch:** `if_pc_curr` addresses instruction memory.
   The PC normally advances by four bytes. A branch or jump redirects it to
   the calculated target.
2. **ID — Instruction Decode:** The instruction's opcode, register fields,
   and function fields are decoded. The register file is read and the
   instruction's immediate is generated.
3. **EX — Execute:** The ALU performs arithmetic, logic, address calculation,
   or branch comparison. The forwarding unit can select a newer value from
   MEM or WB instead of the value originally read in ID.
4. **MEM — Memory Access:** Loads read data memory and stores write a 32-bit
   word.
5. **WB — Writeback:** The selected ALU result, loaded word, or jump link
   address is written to the destination register.

Pipeline registers separate each stage (`IF/ID`, `ID/EX`, `EX/MEM`, and
`MEM/WB`). If an instruction in EX is a load whose destination is needed by
the instruction in ID, the hazard unit holds the PC and IF/ID register for
one cycle and inserts a bubble into ID/EX. A taken branch or jump flushes the
instruction behind it. Forwarding prioritizes the most recent matching
producer in MEM, then WB.

## Implemented instructions

The decoder and ALU implement these RV32I integer operations:

- **Register-register (R-type):** `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`,
  `SRL`, `SRA`, `OR`, `AND`.
- **Immediate arithmetic/logical (I-type):** `ADDI`, `SLTI`, `SLTIU`, `XORI`,
  `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI`.
- **Memory:** `LW` and `SW` for 32-bit words.
- **Branches:** `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`.
- **Control flow:** `JAL`, `JALR`.
- **Upper immediates:** `LUI`, `AUIPC`.

This is a learning core, not a complete RISC-V implementation. In particular,
byte and halfword loads/stores, the M extension, compressed instructions,
CSRs, exceptions, and privilege modes are not implemented. Although the
opcode control signals include the general load/store opcode classes, the
data path currently transfers whole 32-bit words and does not implement
byte/halfword access or sign/zero extension.

## Software flow and `program.hex`

`sw/main.c` computes the seventh Fibonacci number using the sequence
`0, 1, 1, 2, 3, 5, 8, 13` and returns the result. The function's C return value
is passed in the standard RISC-V ABI register `a0` (`x10`).

`sw/boot.s` supplies a minimal `_start` entry point. It sets `sp` (`x2`) to
`0x00001000`, calls `main`, and provides an infinite `trap_loop` as the return
destination. The linker script puts `_start` at address zero, followed by the
program text. No C runtime or standard library is linked.

Build the program and generate its instruction image with:

```sh
make build-sw
```

This invokes `sw/build.sh`, which compiles for RV32I (`-march=rv32i`,
`-mabi=ilp32`, `-O2`, `-nostdlib`), creates `sw/main.elf`, and uses
`riscv64-unknown-elf-objcopy` to write one 32-bit instruction word per
`$readmemh` entry in the root-level `program.hex`.

The checked-in `program.hex` currently contains:

| Byte address | Hex word | Instruction | Meaning |
|---:|---:|---|---|
| `0x00` | `00001137` | `lui sp, 0x1` | Load upper immediate `1` into `x2`; this sets the stack pointer to `0x1000`. |
| `0x04` | `008000EF` | `jal ra, 0x0c` | Call `main`: save return address `0x08` in `x1` and jump to byte address `0x0c`. |
| `0x08` | `0000006F` | `jal x0, 0x08` | Infinite self-loop used as the return/trap loop. |
| `0x0c` | `00D00513` | `addi a0, x0, 13` | Place the Fibonacci result, decimal `13`, in `x10` (`a0`). |
| `0x10` | `00008067` | `jalr x0, 0(x1)` | Return from `main` to the saved address `0x08`; `x0` discards the link value. |

Although the C source contains a loop, the current `-O2` compiler optimizes
this particular computation to the constant `13`; therefore the image does
not contain a runtime Fibonacci loop. The C test checks that after execution
`x10 == 13` and `x2 == 0x1000`.

### How the hex image is addressed

The `@00000000` line in `program.hex` is a `$readmemh` address directive: the
following word is loaded at instruction-memory word index zero. Each following
eight-hex-digit value is one 32-bit instruction. The CPU PC is a **byte**
address, while `instruction_mem.sv` selects a word using `PC >> 2`; thus the
five words above are fetched at byte addresses `0x00`, `0x04`, `0x08`,
`0x0c`, and `0x10`. The instruction memory returns zero for an out-of-range
word address.

## Hardware test image: `hardware_test.hex`

`tb/riscv_top_tb.sv` loads `hardware_test.hex` and checks forwarding, word
memory access, a load-use stall, taken-branch flushing, AUIPC, and JALR link
writeback. Each row below is one 32-bit instruction at the given byte address.
The numbers in the meaning column are decimal unless shown in hexadecimal.

| Address | Hex word | Instruction | Meaning |
|---:|---:|---|---|
| `0x00` | `00500093` | `addi x1, x0, 5` | Set `x1 = 5`. |
| `0x04` | `00A00113` | `addi x2, x0, 10` | Set `x2 = 10`. |
| `0x08` | `002081B3` | `add x3, x1, x2` | Set `x3 = 15`; depends on recent values and exercises forwarding. |
| `0x0c` | `00310233` | `add x4, x2, x3` | Set `x4 = 25`. |
| `0x10` | `00402023` | `sw x4, 0(x0)` | Store the word `25` at data-memory byte address zero. |
| `0x14` | `00002283` | `lw x5, 0(x0)` | Load that word into `x5`; expected `25`. |
| `0x18` | `00128333` | `add x6, x5, x1` | Add the just-loaded `x5` and `x1`; expected `30`, with a load-use stall. |
| `0x1c` | `00000093` | `addi x1, x0, 0` | Set `x1 = 0` for branch tests. |
| `0x20` | `00100113` | `addi x2, x0, 1` | Set `x2 = 1` for branch tests. |
| `0x24` | `0020C463` | `blt x1, x2, +8` | Since `0 < 1`, branch to `0x2c`, skipping the next instruction. |
| `0x28` | `06300413` | `addi x8, x0, 99` | Wrong-path “poison” instruction; the branch must flush it, leaving `x8 = 0`. |
| `0x2c` | `0020E463` | `bltu x1, x2, +8` | Since unsigned `0 < 1`, branch to `0x34`. |
| `0x30` | `06300493` | `addi x9, x0, 99` | Wrong-path poison instruction; the branch must flush it, leaving `x9 = 0`. |
| `0x34` | `00000013` | `addi x0, x0, 0` (`nop`) | No-op; writes to `x0` are ignored. |
| `0x38` | `00001217` | `auipc x4, 0x1` | Add `0x1000` to the current PC `0x38`; expected `x4 = 0x1038`. |
| `0x3c` | `000203E7` | `jalr x7, 0(x4)` | Jump to `0x1038` with bit zero cleared, and save link address `0x40` in `x7`. |

The hardware test runs for 35 cycles and asserts the final values:
`x3 = 15`, `x4 = 0x1038`, `x5 = 25`, `x6 = 30`, `x8 = 0`, `x9 = 0`, and
`x7 = 0x40`.

## Build and run the simulations

Required tools:

- GNU Make
- Icarus Verilog (`iverilog` and `vvp`) for RTL simulations
- The RISC-V GNU Embedded Toolchain (`riscv64-unknown-elf-gcc` and
  `riscv64-unknown-elf-objcopy`) to regenerate `program.hex`

From the repository root:

```sh
make test-hw   # Compile and run the hand-encoded pipeline test
make test-sw   # Build the C image, then compile and run the software test
make test      # Run both testbenches (hardware test first)
```

The testbenches write VCD waveform files (`riscv_top.vcd` and
`riscv_sw.vcd`) in the current working directory. Open them with a waveform
viewer such as GTKWave to inspect pipeline and register activity. The
simulator executables and waveform files are ignored by Git.

## Useful implementation notes

- `MEM_DEPTH` defaults to 1,024 **words**, not bytes. The default memory size
  is 4 KiB.
- Instruction addresses are byte addresses and instructions are word-aligned.
- Data-memory operations access full words. The implementation uses address
  bits `[31:2]` modulo `MEM_DEPTH` to select a data word.
- The software startup sets the stack pointer to `0x1000`, the one-past-the-end
  byte address for the default 4 KiB data memory.
- `hardware_test.hex` is a standalone micro-test image; `program.hex` is the
  software build output. The two testbenches deliberately load different
  images.
