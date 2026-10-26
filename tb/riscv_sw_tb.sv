`timescale 1ns/1ps

module riscv_sw_tb;

    logic clk;
    logic reset;

    riscv_top #(
        .MEM_DEPTH(1024),
        .HEX_FILE ("program.hex")
    ) dut (
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 1'b0;
        reset = 1'b1;

        $display("=======================================================================");
        $display("                    STARTING RISC-V C SOFTWARE TEST                    ");
        $display("=======================================================================");

        $dumpfile("riscv_sw.vcd");
        $dumpvars(0, riscv_sw_tb);

        #20;
        reset = 1'b0;

        repeat (50) @(posedge clk);
        #1;

        $display("=======================================================================");
        $display("                       SOFTWARE EXECUTION RESULT                       ");
        $display("=======================================================================");
        $display("Register x10 (a0 / Return Value) : %0d (0x%08h)", dut.u_reg_file.registers[10], dut.u_reg_file.registers[10]);
        $display("Register x2  (sp  / Stack Pointer): 0x%08h", dut.u_reg_file.registers[2]);
        $display("=======================================================================");

        if (dut.u_reg_file.registers[2] !== 32'h00001000) begin
            $fatal(1, "[FAILED] Expected stack pointer x2 = 0x00001000, got 0x%08h", dut.u_reg_file.registers[2]);
        end

        if (dut.u_reg_file.registers[10] === 32'd13) begin
            $display("[PASSED] Fibonacci result in x10 matches expected value (13)!");
        end else begin
            $fatal(1, "[FAILED] Expected x10 = 13, got %0d", dut.u_reg_file.registers[10]);
        end

        $finish;
    end

endmodule