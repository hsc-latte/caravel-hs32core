`ifdef verilator
    `include "defines.v"
    `include "hs32_user_proj/io_filter.v"
`endif

module dev_gpio32 (
    input   wire clk,
    input   wire reset,

    // External IO
    input  wire [`MPRJ_IO_PADS-1:0] io_in,
    output wire [`MPRJ_IO_PADS-1:0] io_out,
    output wire [`MPRJ_IO_PADS-1:0] io_oeb,

    // Filtered signals
    output wire[31:0] io_in_sync,
    output wire[31:0] io_in_rise,
    output wire[31:0] io_in_fall,

    // Memory bus
    input wire stb,
    output wire ack,
    input wire rw,
    input wire[2:0] addr,
    input wire[31:0] dwrite,
    output wire[31:0] dtr,

    // Interrupts
    output wire io_irqr,
    output wire io_irqf
);
    localparam NUM_IO = 32;

    assign ack = 1;

    // [0] = oeb
    // [1] = out
    // [2] = int enb rise
    // [3] = int enb fall
    // [4] = int reg rise
    // [5] = int reg fall
    reg[NUM_IO-1:0] cfg[5:0];
    assign dtr = cfg[addr];

    // Generate filter block
    io_filter filter[NUM_IO-1:0](
        .clk(clk),
        .rst(reset),
        .a(io_in[37:6]),
        .b(io_in_sync),
        .rise(io_in_rise),
        .fall(io_in_fall)
    );

    // Assign outputs
    assign io_out = { cfg[1], 6'b0 };
    assign io_oeb = { cfg[0], 6'b0 }; // Output when NC

    // Generate rising/falling interrupts
    wire[NUM_IO-1:0] io_ir, io_if;
    assign io_irqr = | io_ir;
    assign io_irqf = | io_if;
    genvar g_io;
    generate
        for(g_io = 0; g_io < NUM_IO; g_io = g_io+1) begin
            assign io_ir[g_io] = cfg[2][g_io] & io_in_rise[g_io] & io_oeb[g_io];
            assign io_if[g_io] = cfg[3][g_io] & io_in_fall[g_io] & io_oeb[g_io];
        end
    endgenerate

    // Interrupt latches (TODO: set interrupt ack)
    always @(posedge clk) begin
        if(io_irqr) cfg[4] <= io_ir;
        if(io_irqf) cfg[5] <= io_if;
    end

    // Memory bus logic
    always @(posedge clk) if(reset) begin
        cfg[0] = 0;
        cfg[1] = 0; // Output when NC default
        cfg[2] = 0;
        cfg[3] = 0;
    end else if(stb && rw) begin
        if(addr != 4 && addr != 5) begin
            cfg[addr] <= dwrite;
        end
    end
endmodule