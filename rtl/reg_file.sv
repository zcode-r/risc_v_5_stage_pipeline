
`timescale 1ns/1ps

module reg_file #(
    parameter DATA_WIDTH = 32,
    parameter REG_COUNT  = 32
)(
    input logic clk,
    input logic reset,

    // Write port
    input logic wen,
    input logic [$clog2(REG_COUNT)-1:0] waddr,
    input logic [DATA_WIDTH-1:0] wdata,

    // Read port 1
    input logic [$clog2(REG_COUNT)-1:0] raddr1,
    output logic [DATA_WIDTH-1:0] rdata1,

    // Read port 2
    input logic [$clog2(REG_COUNT)-1:0] raddr2,
    output logic [DATA_WIDTH-1:0] rdata2
);

    logic [DATA_WIDTH-1:0] registers [0:REG_COUNT-1];

    integer i;

    // Asynchronous reads; x0 always returns zero
    always_comb begin
        if (raddr1 == 0)
            rdata1 = '0;
        else
            rdata1 = registers[raddr1];

        if (raddr2 == 0)
            rdata2 = '0;
        else
            rdata2 = registers[raddr2];
    end

    // Synchronous write and asynchronous reset
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < REG_COUNT; i = i + 1)
                registers[i] <= '0;
        end
        else if (wen && (waddr != 0)) begin
            registers[waddr] <= wdata;
        end
    end

endmodule
