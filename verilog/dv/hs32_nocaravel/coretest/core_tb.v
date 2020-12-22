`define LOG_MEMORY_WRITE

`default_nettype none

`timescale 1 ns / 1 ns

`include "defines.v"
`include "user_proj_example.v"
`include "user_project_wrapper.v"

module tb();
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

	// Memory array
	localparam NUM_INSTR = 10;
	reg[NUM_INSTR*32-1:0] instr = {
		// Default Test
		// { 32'h2400CAFE },
		// { 32'h24100005 },
		// { 32'h34010001 },
		// { 32'h14210001 },
		// { 32'h50000000 }

		// Test 2
		// { 32'h240003F1 },
		// { 32'h20100080 },
		// { 32'h202000A0 },
		// { 32'h203000C0 },
		// { 32'h204000E0 },
		// { 32'h50000000 }

		// Test 7
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