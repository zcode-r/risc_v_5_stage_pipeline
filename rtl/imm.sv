`timescale 1ns/1ps

import riscv_pkg::*;

module imm_gen (
  input  logic [31:0] inst,
  output logic [31:0] imm_out
);

  logic [6:0] opcode;
  assign opcode = inst[6:0];

  always_comb begin
    case (opcode)
      OPC_I_ARITH,
      OPC_I_LOAD,
      OPC_I_JALR: begin
        imm_out = {{20{inst[31]}}, inst[31:20]};
      end

      OPC_S_TYPE: begin
        imm_out = {{20{inst[31]}}, inst[31:25], inst[11:7]};
      end

      OPC_B_TYPE: begin
        imm_out = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
      end

      OPC_U_LUI,
      OPC_U_AUIPC: begin
        imm_out = {inst[31:12], 12'h000};
      end

      OPC_J_JAL: begin
        imm_out = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
      end

      default: begin
        imm_out = 32'h0000_0000;
      end
    endcase
  end

endmodule
