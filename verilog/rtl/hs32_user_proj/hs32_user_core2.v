`ifdef verilator
    `include "defines.v"
    `include "cpu/hs32_cpu.v"
    `include "frontend/sram.v"
    `include "frontend/mmio.v"
`endif

`default_nettype none

module hs32_user_proj (
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
    input  wire wb_clk_i,
    input  wire wb_rst_i,
    input  wire wbs_stb_i,
    input  wire wbs_cyc_i,
    input  wire wbs_we_i,
    input  wire [3:0] wbs_sel_i,
    input  wire [31:0] wbs_dat_i,
    input  wire [31:0] wbs_adr_i,
    output wire wbs_ack_o,
    output wire [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  wire [127:0] la_data_in,
    output wire [127:0] la_data_out,
    input  wire [127:0] la_oen,

    // IOs
    input  wire [`MPRJ_IO_PADS-1:0] io_in,
    output wire [`MPRJ_IO_PADS-1:0] io_out,
    output wire [`MPRJ_IO_PADS-1:0] io_oeb
);
    // Clock and reset
    // wire clk = (~la_oen[64])? la_data_in[64] : wb_clk_i;
    // wire rst = (~la_oen[65])? la_data_in[65] : wb_rst_i;
    wire clk = wb_clk_i;
    wire rst = wb_rst_i;

    // Wishbone logic
    wire valid;
    wire [3:0] wstrb;
    assign valid = wbs_cyc_i && wbs_stb_i; 
    assign wstrb = wbs_sel_i & { 4 { wbs_we_i } };
    // TODO
    
    // CPU Core 0 Connection
    wire[31:0] adr0, dtr0, dtw0, isr0;
    wire rw0, val0, rdy0, iack0, irq0, nmi0, usr0, fault0;
    wire[23:0] int0;
    wire[4:0] vec0;
    hs32_cpu #(
        .IMUL(1), .BARREL_SHIFTER(1), .PREFETCH_SIZE(3)
    ) core0 (
        .i_clk(clk), .reset(rst),
        // Mem
        .addr(adr0), .rw(rw0), .din(dtr0), .dout(dtw0),
        .valid(val0), .ready(rdy0),
        // Int
        .interrupts(int0), .iack(iack0), .handler(isr0),
        .intrq(irq0), .vec(vec0), .nmi(nmi0),
        // Misc
        .userbit(usr0), .fault(fault0)
    );

    // MMIO
    mmio mmio_unit(
        .clk(clk), .reset(rst),
        // CPU
        .valid(val0), .ready(rdy0),
        .addr(adr0), .dtw(dtw0), .dtr(dtr0), .rw(rw0),
        // SRAM
        .sval(svalid), .srdy(sready),
        .saddr(saddr), .sdtw(sdtw), .sdtr(sdtr), .srw(srw),
        // Interrupt controller
        .interrupts(int0), .handler(isr0), .intrq(irq0),
        .vec(vec0), .nmi(nmi0)
    );

    // SRAM Controller
    wire sready, svalid, srw;
    wire [31:0] saddr, sdtw, sdtr;
    // Output
    wire[15:0] data_in;
    wire[15:0] data_out;
    wire we, oe, oe_neg, ale0_neg, ale1_neg, bhe, isout;
    ext_sram #(
        .SRAM_LATCH_LAZY(1)
    ) sram (
        .clk(clk), .reset(rst),
        // Memory requests
        .ready(sready), .valid(svalid), .rw(srw),
        .addri(saddr), .dtw(sdtw), .dtr(sdtr),
        // External IO interface, active >> HIGH <<
        .din(data_in), .dout(data_out),
        .we(we), .oe(oe), .oe_negedge(oe_neg),
        .ale0_negedge(ale0_neg),
        .ale1_negedge(ale1_neg),
        .bhe(bhe), .isout(isout)
    );

    // SRAM GPIO Logic
    assign io_out[36] = usr0;
    assign data_in = io_in[35:20];
    assign io_out[35:20] = data_out;
    assign io_out[19] = !(oe & oe_neg);
    assign io_out[18] = !we;
    assign io_out[17] = ale0_neg;
    assign io_out[16] = ale1_neg;
    assign io_out[15] = !bhe;

    // Output enables
    assign io_oeb[36] = 0;
    assign io_oeb[35:20] = { (16){ ~isout } };
    assign io_oeb[19:15] = 0;
endmodule