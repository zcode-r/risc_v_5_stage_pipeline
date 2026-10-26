`timescale 1ns/1ps

import riscv_pkg::*;

module alu #(
  parameter int DATA_WIDTH = 32
)(
  input  logic [DATA_WIDTH-1:0] a,
  input  logic [DATA_WIDTH-1:0] b,
  input  alu_op_e               alu_op,

  output logic [DATA_WIDTH-1:0] alu_out,
  output logic                  zero,
  output logic                  carry,
  output logic                  sign,
  output logic                  overflow,
  output logic                  lt,   // Signed less-than flag  (for BLT/BGE)
  output logic                  ltu   // Unsigned less-than flag (for BLTU/BGEU)
);

  logic [DATA_WIDTH:0] temp_math;
  logic [4:0]          shift_amt;

  assign shift_amt = b[4:0]; // Limit shift amount to 0-31 bits

  always_comb begin
    alu_out   = '0;
    temp_math = '0;
    overflow  = 1'b0;
    carry     = 1'b0;

    case (alu_op)
      ALU_ADD: begin
        temp_math = {1'b0, a} + {1'b0, b};
        alu_out   = temp_math[DATA_WIDTH-1:0];
        carry     = temp_math[DATA_WIDTH];
        overflow  = (~(a[DATA_WIDTH-1] ^ b[DATA_WIDTH-1])) & (a[DATA_WIDTH-1] ^ alu_out[DATA_WIDTH-1]);
      end

      ALU_SUB: begin
        temp_math = {1'b0, a} - {1'b0, b};
        alu_out   = temp_math[DATA_WIDTH-1:0];
        carry     = temp_math[DATA_WIDTH];
        overflow  = ((a[DATA_WIDTH-1] ^ b[DATA_WIDTH-1])) & (a[DATA_WIDTH-1] ^ alu_out[DATA_WIDTH-1]);
      end

      ALU_SLL: begin
        alu_out = a << shift_amt;
      end

      ALU_SRL: begin
        alu_out = a >> shift_amt;
      end

      ALU_SRA: begin
        alu_out = $signed(a) >>> shift_amt;
      end

      ALU_SLT: begin
        alu_out = ($signed(a) < $signed(b)) ? {{DATA_WIDTH-1{1'b0}}, 1'b1} : '0;
      end

      ALU_SLTU: begin
        alu_out = (a < b) ? {{DATA_WIDTH-1{1'b0}}, 1'b1} : '0;
      end

      ALU_XOR:  alu_out = a ^ b;
      ALU_OR:   alu_out = a | b;
      ALU_AND:  alu_out = a & b;
      ALU_PASS: alu_out = b; // Pass Operand B (used by LUI)

      default:  alu_out = '0;
    endcase
  end

  // Continuous Flag Outputs
  assign zero = (alu_out == 32'h0);
  assign sign = alu_out[DATA_WIDTH-1];

  // Explicit Signed Comparison (a < b)
  assign lt   = ($signed(a) < $signed(b)) ? 1'b1 : 1'b0;

  // Explicit Unsigned Comparison (a < b)
  assign ltu  = (a < b) ? 1'b1 : 1'b0;

endmodule