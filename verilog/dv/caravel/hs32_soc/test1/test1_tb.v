`ifdef GL_SIM
	`define SRAM_LOG_READ
	`define SRAM_LOG_WRITE
`endif

`default_nettype none
`timescale 1 ns / 1 ns

`include "caravel.v"
`include "spiflash.v"
`include "../assert.v"

module tb();
	parameter TEST_ID = 1;
	parameter FILENAME = "test1.hex";

	`include "../common.v"

`ifndef GL_SIM
	// Weak test cases for debugging
	initial begin
	    // MOV r0 <- 0xCAFE
		wait(tb.uut.mprj.core1.core.EXEC.regfile_s.regs[0] == 32'hCAFE);
		// MOV r1 <- 5
		wait(tb.uut.mprj.core1.core.EXEC.regfile_s.regs[1] == 32'h5);
		// LDR r2 <- [r1+1]
		wait(tb.uut.mprj.core1.core.EXEC.regfile_s.regs[2] == 32'hCAFE);
		failed = 0;
		$display("%c[1;32mTest %0d: Passed weak cases. %c[0m", 27, TEST_ID, 27);
	end

	// Trigger when register write
	wire trigger = tb.uut.mprj.core1.core.EXEC.regfile_s.we === 1'b1;
	reg[31:0] step = 0;
	always @(posedge clock) if(trigger) step <= step + 1;
	// Strict assertations for each instruction
	assert a0(clock, implies(trigger && step == 0,
		tb.uut.mprj.core1.core.EXEC.regfile_s.wadr == 0 &&
		tb.uut.mprj.core1.core.EXEC.regfile_s.din == 32'hCAFE));
	assert a1(clock, implies(trigger && step == 1,
		tb.uut.mprj.core1.core.EXEC.regfile_s.wadr == 1 &&
		tb.uut.mprj.core1.core.EXEC.regfile_s.din == 32'h5));
	assert a2(clock, implies(trigger && step == 2,
		tb.uut.mprj.core1.core.EXEC.regfile_s.wadr == 2 &&
		tb.uut.mprj.core1.core.EXEC.regfile_s.din == 32'hCAFE));
	assert a3(clock, step <= 3);
`endif
endmodule

`default_nettype wire
