    function [0:0] implies;
		input [0:0] p, q;
		begin
			implies = (!p) || q;
		end
	endfunction

	reg clock;
  	reg RSTB;
	reg power1, power2;
	reg power3, power4;

  	wire gpio;
  	wire [37:0] mprj_io;
	wire [7:0] mprj_io_0;

	assign mprj_io_0 = mprj_io[7:0];

	// External clock is used by default.  Make this artificially fast for the
	// simulation.  Normally this would be a slow clock and the digital PLL
	// would be the fast clock.

	always #12 clock <= (clock === 1'b0);

	initial begin
		clock = 0;
	end

	reg failed = 1;

	initial begin
		$dumpfile("tb.vcd");
		$dumpvars(0, tb);
		// Repeat cycles of 1000 clock edges as needed to complete testbench
		repeat (25) begin
			repeat (1000) @(posedge clock);
			// $display("+1000 cycles");
		end
`ifndef GL_SIM
		if(failed) begin
			$display("%c[1;31mTest %0d: Failed. %c[0m", 27, TEST_ID, 27);
			$finish_and_return(1);
		end else begin
			$display("%c[1;32mTest %0d: Passed all cases. %c[0m", 27, TEST_ID, 27);
			$finish_and_return(0);
		end
`endif
		$finish;
	end

	initial begin
		RSTB <= 1'b0;
		#1000;
		RSTB <= 1'b1;	    // Release reset
		#2000;
	end

	initial begin			// Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		power3 <= 1'b0;
		power4 <= 1'b0;
		#200;
		power1 <= 1'b1;
		#200;
		power2 <= 1'b1;
		#200;
		power3 <= 1'b1;
		#200;
		power4 <= 1'b1;
	end

`ifndef GL_SIM
    // If fault, then test failed
	always @(*) begin
		if(tb.uut.mprj.core1.core.EXEC.fault) begin
			$display("%c[1;31mTest %0d: Faulted. %c[0m", 27, TEST_ID, 27);
			$finish_and_return(1);
		end
	end
`endif

    always @(mprj_io) begin
		#1 $display("MPRJ-IO state = %b ", mprj_io[7:0]);
	end

	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;

	wire VDD3V3 = power1;
	wire VDD1V8 = power2;
	wire USER_VDD3V3 = power1;
	wire USER_VDD1V8 = power2;
	wire VSS = 1'b0;

	caravel uut (
		.vddio	  (VDD3V3),
		.vssio	  (VSS),
		.vdda	  (VDD3V3),
		.vssa	  (VSS),
		.vccd	  (VDD1V8),
		.vssd	  (VSS),
		.vdda1    (USER_VDD3V3),
		.vdda2    (USER_VDD3V3),
		.vssa1	  (VSS),
		.vssa2	  (VSS),
		.vccd1	  (USER_VDD1V8),
		.vccd2	  (USER_VDD1V8),
		.vssd1	  (VSS),
		.vssd2	  (VSS),
		.clock	  (clock),
		.gpio     (gpio),
        .mprj_io  (mprj_io),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.resetb	  (RSTB)
	);

	spiflash #(
		.FILENAME(FILENAME)
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);