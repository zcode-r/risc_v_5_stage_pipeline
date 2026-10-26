`timescale 1ns/1ps

module instruction_mem #(
    parameter int MEM_DEPTH = 1024,
    parameter HEX_FILE = "program.hex"
)(
    input  logic [31:0] addr,
    output logic [31:0] inst
);

  logic [31:0] mem [0:MEM_DEPTH-1];
  logic [31:0] word_addr;
  localparam logic [31:0] MEM_DEPTH_WORDS = MEM_DEPTH;

  initial begin
    $readmemh(HEX_FILE, mem);
  end

  // Word-aligned indexing (Divide PC byte address by 4)
  assign word_addr = addr >> 2;
  assign inst = (word_addr < MEM_DEPTH_WORDS)
      ? mem[word_addr[$clog2(MEM_DEPTH)-1:0]]
      : 32'h0000_0000;

endmodule
