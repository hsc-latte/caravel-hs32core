`ifdef verilator
    `include "defines.v"
    `include "cpu/hs32_cpu.v"
    `include "hs32_user_proj/hs32_bram_ctl.v"
    `include "frontend/mmio.v"
`endif

`default_nettype none

module hs32_core1 (
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

    // Wishbone Slave ports (south face)
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
    /*input  wire [`MPRJ_IO_PADS-1:0] io_in,
    output wire [`MPRJ_IO_PADS-1:0] io_out,
    output wire [`MPRJ_IO_PADS-1:0] io_oeb,*/
    
    // Output (north and east faces)
    output wire [7:0]  cpu_mask_n,
    output wire [7:0]  cpu_mask_e,
    output wire [1:0]  cpu_wen_n,
    output wire [1:0]  cpu_wen_e,
    output wire [15:0] cpu_addr_n,
    output wire [15:0] cpu_addr_e,
    output wire [15:0] cpu_dtw_n,
    output wire [15:0] cpu_dtw_e,
    input  wire [31:0] cpu_dtr_n0,
    input  wire [31:0] cpu_dtr_n1,
    input  wire [31:0] cpu_dtr_e0,
    input  wire [31:0] cpu_dtr_e1,

    // Can't have constants in wrapper
    output wire zero,
    output wire one
);
    assign zero = 1'b0;
    assign one = 1'b1;

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
    
    //===============================//
    // Main CPU core
    //===============================//

    wire[31:0] addr, dread, dwrite;
    wire rw, stb, ack, flush;

    hs32_cpu #(
        .IMUL(1), .BARREL_SHIFTER(1), .PREFETCH_SIZE(3)
    ) core1 (
        .i_clk(clk), .reset(rst),

        .addr(addr), .rw(rw),
        .din(dread), .dout(dwrite),
        .stb(stb), .ack(ack),

        .interrupts(inte),
        .iack(), .handler(isr),
        .intrq(irq), .vec(ivec),
        .nmi(nmi),

        .flush(flush), .fault(), .userbit()
    );

    //===============================//
    // MMIO and Interrupts
    //===============================//

    wire [23:0] inte;
    wire [4:0] ivec;
    wire [31:0] isr;
    wire irq, nmi;

    mmio #(
        .AICT_NUM_RE(0), .AICT_NUM_RI(0)
    ) mmio_unit (
        .clk(clk), .reset(rst),
        // CPU
        .stb(stb), .ack(ack),
        .addr(addr), .dtw(dwrite), .dtr(dread), .rw(rw),
        // RAM
        .sstb(ram_stb), .sack(ram_ack), .srw(ram_rw),
        .saddr(ram_addr), .sdtw(ram_dwrite), .sdtr(ram_dread),
        // Interrupt controller
        .interrupts(inte), .handler(isr), .intrq(irq), .vec(ivec), .nmi(nmi)
        // More registers
        //.aict_r(), .aict_w()
    );

    //===============================//
    // Internal SRAM controller
    //===============================//

    wire[31:0] ram_addr, ram_dread, ram_dwrite;
    wire ram_rw, ram_stb, ram_ack;

    hs32_bram_ctl bram_ctl(
        .i_clk(clk),
        .i_reset(rst || flush),
        .i_addr(ram_addr[11:0]), .i_rw(ram_rw),
        .o_dread(ram_dread), .i_dwrite(ram_dwrite),
        .i_stb(ram_stb), .o_ack(ram_ack),

        // Outputs
        .cpu_mask_n(cpu_mask_n),
        .cpu_mask_e(cpu_mask_e),
        .cpu_wen_n(cpu_wen_n),
        .cpu_wen_e(cpu_wen_e),
        .cpu_addr_n(cpu_addr_n),
        .cpu_addr_e(cpu_addr_e),
        .wbuf({ cpu_dtw_n, cpu_dtw_e }),
        .dbuf0(cpu_dtr_n0),
        .dbuf1(cpu_dtr_n1),
        .dbuf2(cpu_dtr_e0),
        .dbuf3(cpu_dtr_e1)
    );
endmodule