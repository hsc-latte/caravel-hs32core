`define LOG_MEMORY_WRITE

`default_nettype none

`timescale 1 ns / 1 ns

`include "defines.v"
`include "user_proj_example.v"
`include "user_project_wrapper.v"

module tb();
	parameter TEST = 1;

	reg wb_clk_i, wb_rst_i, user_clock2;
	reg wbs_stb_i = 0, wbs_cyc_i = 0, wbs_we_i = 0;
	reg [3:0] wbs_sel_i = 0;
	reg [31:0] wbs_dat_i, wbs_adr_i;
	reg [127:0] la_data_in, la_oen;
	reg [`MPRJ_IO_PADS-1:0] io_in, io_oeb;

	wire wbs_ack_o;
	wire [31:0] wbs_dat_o;
	wire [`MPRJ_IO_PADS-1:0] io_out;
	reg [127:0] la_data_out;

	// Initialize Clock
	initial begin
		wb_clk_i = 0;
	end
	always #10 wb_clk_i = wb_clk_i === 1'b0;

`ifdef TEST1
	// Default Test
	localparam NUM_INSTR = 5;
	reg[NUM_INSTR*32-1:0] instr = {
		{ 32'h2400CAFE },
		{ 32'h24100005 },
		{ 32'h34010001 },
		{ 32'h14210001 },
		{ 32'h50000000 }
	};
`elsif TEST2
	// Custom test
	localparam NUM_INSTR = 8;
	reg[NUM_INSTR*32-1:0] instr = {
		{ 32'h2400FF00 }, // MOV r0 <- 0xFF00
		{ 32'h24100019 }, // MOV r1 <- (0x18 | 1)
		{ 32'h34100010 }, // STR [r0+0x10] <- r1
		{ 32'h90000003 }, // INT 3
		{ 32'h2450CAFE }, // MOV r5 <- 0xCAFE
		{ 32'h50000000 }, // B<0000> 0
		{ 32'h2440C0DE }, // MOV r4 <- 0xC0DE
		{ 32'h5F000000 }  // B<1111> 0 (return from interrupt)
	};
`elsif TEST3
	// WB test
	localparam NUM_INSTR = 12; // Fake memory access test
	// Theoretical penalties @40 MHz:
	// < 4k = 0 cycle penalty (* control *)
	// > 4k + no HW = +28 cycle penalty (* current method *)
	// > 4k + HW, aligned = +6 cycle penalty
	// > 4k + HW, misaligned = +12 cycle penalty
	reg[NUM_INSTR*32-1:0] instr = {
		{ 32'h2400FF00 }, // MOV r0 <- 0xFF00
		{ 32'h24100021 }, // MOV r1 <- (0x20 | 1)
		{ 32'h34100040 }, // STR [r0+0x40] <- r1
		{ 32'h24100006 }, // MOV r1 <- 6
		{ 32'h341000EC }, // STR [r0+0xEC] <- r1
		{ 32'h20300800 }, // MOV r3 <- (r0 << 16)
		{ 32'h10230000 }, // LDR r2 <- [r3]
		{ 32'h50000000 }, // B<0000> 0
		{ 32'h2440C0DE }, // MOV r4 <- 0xC0DE
		{ 32'h344000E8 }, // STR [r0+0xE8] <- r4
		{ 32'h64EE0004 }, // SUB lr <- lr - 4
		{ 32'h5F000000 }  // B<1111> 0 (return from interrupt)
	};
`elsif TEST4
	// Interrupt Tests
	localparam NUM_INSTR = 10;
	reg[NUM_INSTR*32-1:0] instr = {
		{ 32'h2400FF00 },
		{ 32'h10100000 },
		{ 32'h24200BA0 },
		{ 32'h24305000 },
		{ 32'h20303800 },
		{ 32'h30320000 },
		{ 32'h24400BA1 },
		{ 32'h34400010 },
		{ 32'h14500010 },
		{ 32'h90000003 }
	};
`endif
	
	// Main block
	reg[3:0] state = 0;
	initial begin
		$dumpfile("dump.vcd");
		$dumpvars(0,mprj);

		// Initial Reset
		$display($time, " PoR Sequence");
		la_oen = 128'b0;
		la_data_in = 128'b01;
		wb_rst_i = 1'b1;
		repeat (10) @(posedge wb_clk_i);
		wb_rst_i = 1'b0;
		la_data_in = 128'b00;
		repeat (2) @(posedge wb_clk_i);
		state = 1; // Done init
		
		wait(state == 3);
		$display($time, " Second reset sequence");
		la_data_in = 128'b11;
		wb_rst_i = 1'b1;
		repeat (10) @(posedge wb_clk_i);
		wb_rst_i = 1'b0;
		la_data_in = 128'b10;
		$display($time, " Sequence completed");

		// Wait
		repeat (1000) @(posedge wb_clk_i);
		$finish;
	end

	// Write instructions
	reg[31:0] ip = 0;
	always @(posedge wb_clk_i) case(state)
		1: begin
			wbs_dat_i <= instr[(NUM_INSTR-ip-1)*32+:32];
			wbs_adr_i <= ip * 4;
			wbs_sel_i <= 4'b1111;
			wbs_stb_i <= 1;
			wbs_cyc_i <= 1;
			wbs_we_i <= 1;
			if(wbs_stb_i) begin
				wbs_stb_i <= 0;
			end
			if(wbs_ack_o) begin
				ip <= ip+1;
				if(ip+1 == NUM_INSTR) begin
					state <= 2;
					wbs_stb_i <= 0;
					wbs_cyc_i <= 0;
					wbs_we_i <= 0;
					wbs_sel_i <= 0;
				end
			end
		end
		2: begin
			la_data_in = 128'b10;
			state <= 3;
		end
		default: begin end
	endcase

	always @(*) begin
		if(mprj.core1.core.EXEC.fault) begin
			$display("%c[1;31m", 8'd27);
			$display($time, " Test faulted!");
			$display("%c[0m", 8'd27);
			$finish;
		end
	end

	user_project_wrapper mprj (
		// Wishbone Slave ports (WB MI A)
		.wb_clk_i(wb_clk_i),
		.wb_rst_i(wb_rst_i),
		.wbs_stb_i(wbs_stb_i),
		.wbs_cyc_i(wbs_cyc_i),
		.wbs_we_i(wbs_we_i),
		.wbs_sel_i(wbs_sel_i),
		.wbs_dat_i(wbs_dat_i),
		.wbs_adr_i(wbs_adr_i),
		.wbs_ack_o(wbs_ack_o),
		.wbs_dat_o(wbs_dat_o),

		// Logic Analyzer Signals
		.la_data_in(la_data_in),
		.la_data_out(),
		.la_oen(la_oen),

		// IOs
		.io_in(),
		.io_out(),
		.io_oeb(),

		// Analog
		.analog_io(),

		// Independent clock (on independent integer divider)
		.user_clock2()
	);

endmodule