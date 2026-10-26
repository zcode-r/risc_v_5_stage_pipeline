`timescale 1ns/1ps

import riscv_pkg::*;

// ============================================================================
// Module: Main Control Unit
// ============================================================================
module control_unit (
  input  logic [6:0] opcode,

  // ALU Helpers
  output logic [1:0] alu_op_type, // 00: ADD, 01: SUB/Branch, 10: R/I-Arith, 11: PASS
  output logic       is_i_type,   // 1 for I-Type arithmetic

  // Datapath MUX Controls
  output logic       alu_src,     // 0: Operand B from rs2, 1: from Immediate
  output logic [1:0] mem_to_reg,  // 00: ALU Result, 01: Memory Data, 10: PC + 4
  output logic       reg_write,   // 1: Write to destination register rd
  output logic       mem_read,    // 1: Read from Data RAM (LW)
  output logic       mem_write,   // 1: Write to Data RAM (SW)
  output logic       branch,      // 1: Branch instruction (BEQ, BNE, BLT, BGE...)
  output logic       jump,        // 1: Unconditional jump (JAL, JALR)
  output logic       pc_src_a,    // 0: ALU Input A from rs1, 1: from PC (for AUIPC)
  output logic       is_jalr      // 1: Indirect Jump via Register (JALR)
);

  always_comb begin
    // Default Signal States
    alu_op_type = 2'b00;
    is_i_type   = 1'b0;
    alu_src     = 1'b0;
    mem_to_reg  = 2'b00;
    reg_write   = 1'b0;
    mem_read    = 1'b0;
    mem_write   = 1'b0;
    branch      = 1'b0;
    jump        = 1'b0;
    pc_src_a    = 1'b0;
    is_jalr     = 1'b0;

    case (opcode)

      // 1. R-Type (ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND)
      OPC_R_TYPE: begin
        reg_write   = 1'b1;
        alu_src     = 1'b0;
        alu_op_type = 2'b10; // Decode via funct3 & funct7
      end

      // 2. I-Type Arithmetic (ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI)
      OPC_I_ARITH: begin
        reg_write   = 1'b1;
        alu_src     = 1'b1;
        is_i_type   = 1'b1; // Ignore funct7 bit 5 for ADDI
        alu_op_type = 2'b10;
      end

      // 3. Load Word (LW)
      OPC_I_LOAD: begin
        reg_write   = 1'b1;
        alu_src     = 1'b1;
        mem_to_reg  = 2'b01; // Write Memory Data to rd
        mem_read    = 1'b1;
        alu_op_type = 2'b00; // Address calculation (ADD)
      end

      // 4. Store Word (SW)
      OPC_S_TYPE: begin
        alu_src     = 1'b1;
        mem_write   = 1'b1;  // Write Memory
        alu_op_type = 2'b00; // Address calculation (ADD)
      end

      // 5. Branch Instructions (BEQ, BNE, BLT, BGE, BLTU, BGEU)
      OPC_B_TYPE: begin
        branch      = 1'b1;
        alu_src     = 1'b0;  // Select rs2 for ALU Port B
        alu_op_type = 2'b01; // Branch Mode
      end

      // 6. Jump and Link (JAL)
      OPC_J_JAL: begin
        jump        = 1'b1;
        reg_write   = 1'b1;
        mem_to_reg  = 2'b10; // Write PC + 4 into rd
      end

      // 7. Jump and Link Register (JALR)
      OPC_I_JALR: begin
        jump        = 1'b1;
        is_jalr     = 1'b1;  // Target calculation = (rs1 + Imm) & ~1
        reg_write   = 1'b1;
        alu_src     = 1'b1;
        mem_to_reg  = 2'b10; // Write PC + 4 into rd
        alu_op_type = 2'b00; // Target calculation (ADD)
      end

      // 8. Load Upper Immediate (LUI)
      OPC_U_LUI: begin
        reg_write   = 1'b1;
        alu_src     = 1'b1;
        alu_op_type = 2'b11; // ALU_PASS (passes imm20 shifted into rd)
      end

      // 9. Add Upper Immediate to PC (AUIPC)
      OPC_U_AUIPC: begin
        reg_write   = 1'b1;
        alu_src     = 1'b1;
        pc_src_a    = 1'b1;  // Pass PC into ALU Input A
        alu_op_type = 2'b00; // PC + Imm calculation (ADD)
      end

      default: begin
        // Retain default safe values
      end

    endcase
  end

endmodule
