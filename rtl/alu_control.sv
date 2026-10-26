`timescale 1ns/1ps

import riscv_pkg::*;

module alu_control (
  input  logic [1:0] alu_op_type,
  input  logic [2:0] funct3,
  input  logic       funct7_b5,
  input  logic       is_i_type,
  output alu_op_e    alu_ctrl
);

  always_comb begin
    case (alu_op_type)
      2'b00: alu_ctrl = ALU_ADD; // LW, SW, AUIPC, JALR

      // Branch Comparison Selection
      2'b01: begin
        case (funct3)
          F3_BEQ, F3_BNE:   alu_ctrl = ALU_SUB;  // Generates zero flag
          F3_BLT, F3_BGE:   alu_ctrl = ALU_SLT;  // Generates signed lt flag
          F3_BLTU, F3_BGEU: alu_ctrl = ALU_SLTU; // Generates unsigned ltu flag
          default:          alu_ctrl = ALU_SUB;
        endcase
      end

      // R-Type and I-Type Arithmetic
      2'b10: begin
        case (funct3)
          F3_ADD_SUB: begin
            if (!is_i_type && funct7_b5) alu_ctrl = ALU_SUB;
            else                         alu_ctrl = ALU_ADD;
          end

          F3_SLL:  alu_ctrl = ALU_SLL;
          F3_SLT:  alu_ctrl = ALU_SLT;
          F3_SLTU: alu_ctrl = ALU_SLTU;
          F3_XOR:  alu_ctrl = ALU_XOR;

          F3_SRL_SRA: begin
            if (funct7_b5) alu_ctrl = ALU_SRA;
            else           alu_ctrl = ALU_SRL;
          end

          F3_OR:   alu_ctrl = ALU_OR;
          F3_AND:  alu_ctrl = ALU_AND;
          default: alu_ctrl = ALU_ADD;
        endcase
      end

      2'b11:   alu_ctrl = ALU_PASS; // LUI
      default: alu_ctrl = ALU_ADD;
    endcase
  end

endmodule