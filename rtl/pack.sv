`timescale 1ns/1ps

package riscv_pkg;

  // -------------------------------------------------------------
  // Fully Typed RV32I ALU Operation Selector
  // -------------------------------------------------------------
  typedef enum logic [3:0] {
    ALU_ADD  = 4'b0000,
    ALU_SUB  = 4'b0001,
    ALU_SLL  = 4'b0010, // Shift Left Logical
    ALU_SLT  = 4'b0011, // Set Less Than (Signed)
    ALU_SLTU = 4'b0100, // Set Less Than (Unsigned)
    ALU_XOR  = 4'b0101,
    ALU_SRL  = 4'b0110, // Shift Right Logical
    ALU_SRA  = 4'b0111, // Shift Right Arithmetic (Preserves Sign)
    ALU_OR   = 4'b1000,
    ALU_AND  = 4'b1001,
    ALU_PASS = 4'b1111  // Pass Operand B (for LUI)
  } alu_op_e;

  // -------------------------------------------------------------
  // Standard RV32I 7-bit Opcodes
  // -------------------------------------------------------------
  typedef enum logic [6:0] {
    OPC_R_TYPE  = 7'b0110011, // ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
    OPC_I_ARITH = 7'b0010011, // ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
    OPC_I_LOAD  = 7'b0000011, // LW, LH, LB, LHU, LBU
    OPC_I_JALR  = 7'b1100111, // JALR
    OPC_S_TYPE  = 7'b0100011, // SW, SH, SB
    OPC_B_TYPE  = 7'b1100011, // BEQ, BNE, BLT, BGE, BLTU, BGEU
    OPC_U_LUI   = 7'b0110111, // LUI
    OPC_U_AUIPC = 7'b0010111, // AUIPC
    OPC_J_JAL   = 7'b1101111  // JAL
  } opcode_e;

  // -------------------------------------------------------------
  // Standard RV32I 3-bit funct3 Encodings
  // -------------------------------------------------------------
  localparam logic [2:0] F3_ADD_SUB = 3'b000;
  localparam logic [2:0] F3_SLL     = 3'b001;
  localparam logic [2:0] F3_SLT     = 3'b010;
  localparam logic [2:0] F3_SLTU    = 3'b011;
  localparam logic [2:0] F3_XOR     = 3'b100;
  localparam logic [2:0] F3_SRL_SRA = 3'b101;
  localparam logic [2:0] F3_OR      = 3'b110;
  localparam logic [2:0] F3_AND     = 3'b111;

  // Branch funct3 Encodings
  localparam logic [2:0] F3_BEQ     = 3'b000;
  localparam logic [2:0] F3_BNE     = 3'b001;
  localparam logic [2:0] F3_BLT     = 3'b100;
  localparam logic [2:0] F3_BGE     = 3'b101;
  localparam logic [2:0] F3_BLTU    = 3'b110;
  localparam logic [2:0] F3_BGEU    = 3'b111;

endpackage