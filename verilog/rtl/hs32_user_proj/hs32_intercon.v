module hs32_intercon (
    input   wire clk,
    input   wire reset,

    // Controller interface
    input   wire stb,
    output  wire ack,
    input   wire[31:0] addr,
    input   wire[31:0] dtw,
    input   wire rw,

    // Devices interface
    input   wire[32*NS-1:0] dtr,
    input   wire[NS-1:0] i_ack,
    output  wire[NS-1:0] o_stb
);
    parameter NS = 1;
    parameter[32*NS-1:0] MASK = {
        { 5'b11111 },
        { 1'b1 },
        { 1'b1 },
        
    };
    
    reg[31:0] aict_base;

endmodule
