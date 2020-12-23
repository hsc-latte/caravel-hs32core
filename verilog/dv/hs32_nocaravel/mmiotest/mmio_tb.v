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

	// Memory array, { address, data }
	localparam NUM_TRANS = 4;
	reg[NUM_TRANS*64-1:0] entries = {
		{ 32'hFF00, 32'h0000_CA00 },
		{ 32'hCA84, 32'hFFFF_FFFF },
		{ 32'hCAA4, 32'h0000_0010 },
		{ 32'hCAA0, { 25'b0, 2'd1, 2'd1, 3'd1 } } // output, timer, source
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
		
		wait(state == 2);
		$display($time, " Sequence completed");

		// Wait
		repeat (1000) @(posedge wb_clk_i);
		$finish;
	end

	// Write data/address pairs
	reg[31:0] ip = 0;
	always @(posedge wb_clk_i) case(state)
		1: begin
			{ wbs_adr_i, wbs_dat_i } <= entries[(NUM_TRANS-ip-1)*64+:64];
			wbs_sel_i <= 4'b1111;
			wbs_stb_i <= 1;
			wbs_cyc_i <= 1;
			wbs_we_i <= 1;
			state <= 3;
		end
		3: begin
			wbs_stb_i <= 0;
			if(wbs_ack_o) begin
				ip <= ip+1;
				if(ip+1 == NUM_TRANS) begin
					state <= 2;
					wbs_stb_i <= 0;
					wbs_cyc_i <= 0;
					wbs_we_i <= 0;
					wbs_sel_i <= 0;
				end else begin
					state <= 1;
				end
			end
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