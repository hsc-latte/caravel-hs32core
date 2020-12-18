`ifdef verilator
    `include "defines.v"
    `include "hs32_user_proj/hs32_core1.v"
    `include "sram_1rw1r_32_256_8_sky130.v"
`endif

`ifdef SIM
    `include "../../macros/bm/sram_1rw1r_32_256_8_sky130.v"
    `define SRAM_MODULE sram_1rw1r_32_256_8_sky130_dbg
`else
    `define SRAM_MODULE sram_1rw1r_32_256_8_sky130
`endif

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */

module user_project_wrapper (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oen,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7.
    inout [`MPRJ_IO_PADS-8:0] analog_io,

    // Independent clock (on independent integer divider)
    input wire user_clock2
);
    wire zero, one, ce;

    hs32_core1 core0 ();

    hs32_core1 core1 (
`ifdef USE_POWER_PINS
	    .vdda1(vdda1),	// User area 1 3.3V power
	    .vdda2(vdda2),	// User area 2 3.3V power
	    .vssa1(vssa1),	// User area 1 analog ground
	    .vssa2(vssa2),	// User area 2 analog ground
	    .vccd1(vccd1),	// User area 1 1.8V power
	    .vccd2(vccd2),	// User area 2 1.8V power
	    .vssd1(vssd1),	// User area 1 digital ground
	    .vssd2(vssd2),	// User area 2 digital ground
`endif

	    // MGMT core clock and reset

    	.wb_clk_i(wb_clk_i),
    	.wb_rst_i(wb_rst_i),

	    // MGMT SoC Wishbone Slave

	    .wbs_cyc_i(wbs_cyc_i),
	    .wbs_stb_i(wbs_stb_i),
	    .wbs_we_i(wbs_we_i),
	    .wbs_sel_i(wbs_sel_i),
	    .wbs_adr_i(wbs_adr_i),
	    .wbs_dat_i(wbs_dat_i),
	    .wbs_ack_o(wbs_ack_o),
	    .wbs_dat_o(wbs_dat_o),

	    // Logic Analyzer

	    .la_data_in(la_data_in),
	    .la_data_out(la_data_out),
	    .la_oen (la_oen),

        // SRAM meme :3
        .cpu_mask_n(mask_n),
        .cpu_mask_e(mask_e),
        .cpu_wen_n(wen_n),
        .cpu_wen_e(wen_e),
        .cpu_addr_n(addr_n),
        .cpu_addr_e(addr_e),
        .cpu_dtw_n(dtw_n),
        .cpu_dtw_e(dtw_e),
        .cpu_dtr_n0(dtr_n0),
        .cpu_dtr_n1(dtr_n1),
        .cpu_dtr_e0(dtr_e0),
        .cpu_dtr_e1(dtr_e1),

        // Constants
        .zero(zero),
        .one(one),

        // Chip enable
        .ram_ce(ce)
    );

    wire [31:0] dtr_n0, dtr_n1, dtr_e0, dtr_e1;
    wire [1:0] wen_n, wen_e;
    wire [7:0] mask_n, mask_e;
    wire [15:0] dtw_n, dtw_e, addr_n, addr_e;

    `SRAM_MODULE sram0(
`ifdef USE_POWER_PINS
        .vdd(vccd1), .gnd(vssd1),
`endif
        .clk0(wb_clk_i),
        .csb0(ce),
        .web0(wen_n[1]),
        .wmask0(mask_n[7:4]),
        .addr0(addr_n[15:8]),
        .din0({ 4{dtw_n[15:8]} }),
        .dout0(dtr_n0),
        // Disabled port
        .clk1(zero), .csb1(one), .addr1({8{zero}}), .dout1()
    );

    `SRAM_MODULE sram1(
`ifdef USE_POWER_PINS
        .vdd(vccd1), .gnd(vssd1),
`endif
        .clk0(wb_clk_i),
        .csb0(ce),
        .web0(wen_n[0]),
        .wmask0(mask_n[3:0]),
        .addr0(addr_n[7:0]),
        .din0({ 4{dtw_n[7:0]} }),
        .dout0(dtr_n1),
        // Disabled port
        .clk1(zero), .csb1(one), .addr1({8{zero}}), .dout1()
    );

    `SRAM_MODULE sram2(
`ifdef USE_POWER_PINS
        .vdd(vccd1), .gnd(vssd1),
`endif
        .clk0(wb_clk_i),
        .csb0(ce),
        .web0(wen_e[1]),
        .wmask0(mask_e[7:4]),
        .addr0(addr_e[15:8]),
        .din0({ 4{dtw_e[15:8]} }),
        .dout0(dtr_e0),
        // Disabled port
        .clk1(zero), .csb1(one), .addr1({8{zero}}), .dout1()
    );

    `SRAM_MODULE sram3(
`ifdef USE_POWER_PINS
        .vdd(vccd1), .gnd(vssd1),
`endif
        .clk0(wb_clk_i),
        .csb0(ce),
        .web0(wen_e[0]),
        .wmask0(mask_e[3:0]),
        .addr0(addr_e[7:0]),
        .din0({ 4{dtw_e[7:0]} }),
        .dout0(dtr_e1),
        // Disabled port
        .clk1(zero), .csb1(one), .addr1({8{zero}}), .dout1()
    );

    `SRAM_MODULE sram4(
`ifdef USE_POWER_PINS
        .vdd(vccd1), .gnd(vssd1),
`endif
        .clk0(wb_clk_i),
        .clk1(wb_clk_i)
    );

    `SRAM_MODULE sram5(
`ifdef USE_POWER_PINS
        .vdd(vccd1), .gnd(vssd1),
`endif
        .clk0(wb_clk_i),
        .clk1(wb_clk_i)
    );

endmodule // user_project_wrapper
