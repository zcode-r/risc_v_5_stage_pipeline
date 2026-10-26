`timescale 1ns/1ps

module riscv_top_tb;

    logic clk;
    logic reset;

    // Instantiate 5-Stage Top Module
    riscv_top #(
        .MEM_DEPTH(1024),
        .HEX_FILE ("hardware_test.hex")
    ) dut (
        .clk  (clk),
        .reset(reset)
    );

    // 100MHz Clock Generation
    always #5 clk = ~clk;

    int cycle_cnt;

    initial begin
        clk       = 0;
        reset     = 1;
        cycle_cnt = 0;

        $display("=======================================================================");
        $display("   STARTING FULL 5-STAGE PIPELINE TEST (HAZARDS + FORWARDING + ISA)   ");
        $display("=======================================================================");

        #15;
        reset = 0;

        // Run for 35 cycles to allow full pipeline traversal
        repeat (35) begin
            @(posedge clk);
            #1; // Delta delay for signal settling
            cycle_cnt++;
            $display("[Cycle %2d] IF_PC:0x%08h | ID_Inst:0x%08h | x3:%0d x4:0x%08h x5:%0d x6:%0d x7:0x%08h",
                     cycle_cnt,
                     dut.if_pc_curr,
                     dut.id_inst,
                     dut.u_reg_file.registers[3],
                     dut.u_reg_file.registers[4],
                     dut.u_reg_file.registers[5],
                     dut.u_reg_file.registers[6],
                     dut.u_reg_file.registers[7]);
        end

        // VERIFY ALL PIPELINE FEATURES
        $display("=======================================================================");
        $display("                       VERIFYING CPU STATE                             ");
        $display("=======================================================================");

        // 1. Forwarding Check
        assert(dut.u_reg_file.registers[3] === 32'd15)
            else $fatal(1, "[FAILED] EX-to-EX Forwarding failed! x3 should be 15, got %0d", dut.u_reg_file.registers[3]);

        // 2. Load-Use Stall & Memory Check
        assert(dut.u_reg_file.registers[5] === 32'd25)
            else $fatal(1, "[FAILED] LW Memory Read failed! x5 should be 25, got %0d", dut.u_reg_file.registers[5]);

        assert(dut.u_reg_file.registers[6] === 32'd30)
            else $fatal(1, "[FAILED] Load-Use Hazard Stall failed! x6 should be 30, got %0d", dut.u_reg_file.registers[6]);

        // 3. Branch Flush Checks (Poisoned instructions must stay 0)
        assert(dut.u_reg_file.registers[8] === 32'd0)
            else $fatal(1, "[FAILED] Control Hazard Flush failed! x8 should be 0, got %0d", dut.u_reg_file.registers[8]);

        assert(dut.u_reg_file.registers[9] === 32'd0)
            else $fatal(1, "[FAILED] Control Hazard Flush failed! x9 should be 0, got %0d", dut.u_reg_file.registers[9]);

        // 4. AUIPC Check (0x38 + 0x1000 = 0x1038)
        assert(dut.u_reg_file.registers[4] === 32'h00001038)
            else $fatal(1, "[FAILED] AUIPC failed! x4 should be 0x00001038, got 0x%08h", dut.u_reg_file.registers[4]);

        // 5. JALR Return Link Save Check (0x3C + 4 = 0x40)
        assert(dut.u_reg_file.registers[7] === 32'h00000040)
            else $fatal(1, "[FAILED] JALR link address failed! x7 should be 0x00000040, got 0x%08h", dut.u_reg_file.registers[7]);

        $display("[SUCCESS] All Data Forwarding, Load-Use Stalls, Branch Flushes, AUIPC & JALR PASSED!");
        $display("=======================================================================");
        $finish;
    end

    initial begin
        $dumpfile("riscv_top.vcd");
        $dumpvars(0, riscv_top_tb);
    end

endmodule