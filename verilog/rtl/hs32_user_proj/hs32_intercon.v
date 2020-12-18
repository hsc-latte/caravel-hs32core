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
    parameter NS = 4;
    parameter[32*NS-1:0] MASK = {
        { 27'b0, 5'b11111 },
        { 27'b0, 5'b01111 },
        { 24'b0, 8'hFF },
        { 24'b0, 8'hFF }
    };
    parameter [32*NS-1:0] LIMITS = {
        { 27'b0, 5'd25 }, // 24 + 1 base
        { 27'b0, 5'd12 },
        { 24'b0, 8'hFF },
        { 24'b0, 8'hFF }
    };
    parameter BASE_MASK = 
    
    reg[31:0] aict_base;



endmodule
