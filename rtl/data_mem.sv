`timescale 1ps/1ps

module data_mem #(
    parameter int MEM_DEPTH=1024
) (
    input logic clk,
    input logic reset,

    //Control signals form main control unit
    input logic mem_read,
    input logic mem_write,

    //Memory bus
    input logic [31:0] addr,
    input logic [31:0] wdata,
    output logic [31:0] rdata
);

logic [31:0] mem [0: MEM_DEPTH-1];
integer i;

//Read
assign rdata=(mem_read)?mem[32'(addr[31:2])%MEM_DEPTH]:32'h00000000;

//Write
always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
        // for(i=0; i<MEM_DEPTH; ++i) begin
        //     mem[i]=32'h00000000;
        // end
    end
    else if(mem_write) begin
        mem[32'(addr[31:2])%MEM_DEPTH]<=wdata;
    end
end

endmodule
