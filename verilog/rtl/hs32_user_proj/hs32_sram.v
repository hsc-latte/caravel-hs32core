`default_nettype none
`ifdef verilator
    `include "defines.v"
    `include "sram_1rw1r_32_256_8_sky130.v"
`endif

module hs32_sram (
    input clk,
`ifdef USE_POWER_PINS
    inout vdd;
    inout gnd;
`endif
    input  [1:0] cpu_we_n,
    input  [9:0] cpu_addr0,
    input  [9:0] cpu_addr1,
    input  [7:0] cpu_dtw0,
    input  [7:0] cpu_dtw1,
    input  [3:0] cpu_mask0,
    input  [3:0] cpu_mask1,
    output [7:0] cpu_dtr0,
    output [7:0] cpu_dtr1,
);
    /*wire[3:0] mask0 =
        cpu_addr0[1:0] == 2'b00 ? 4'b0001 :
        cpu_addr0[1:0] == 2'b01 ? 4'b0010 :
        cpu_addr0[1:0] == 2'b11 ? 4'b1000 : 4'b0100;
    wire[3:0] mask1 =
        cpu_addr1[1:0] == 2'b00 ? 4'b0001 :
        cpu_addr1[1:0] == 2'b01 ? 4'b0010 :
        cpu_addr1[1:0] == 2'b11 ? 4'b1000 : 4'b0100;*/

    sram_1rw1r_32_256_8_sky130 SRAM_0 (
        .clk0(clk), 
        .csb0(0),   
        .web0(cpu_we_n[0]),  
        .wmask0(cpu_mask0),
        .addr0(cpu_addr0[9:2]),
        .din0({ cpu_dtw0, cpu_dtw0, cpu_dtw0, cpu_dtw0 }),
        .dout0(cpu_dtr0),
        
        .clk1(),
        .csb1(), 
        .addr1(),
        .dout1()
    ); 

    sram_1rw1r_32_256_8_sky130 SRAM_1 (
        .clk0(clk),
        .csb0(0),   
        .web0(cpu_we_n[1]),  
        .wmask0(cpu_mask1),
        .addr0(cpu_addr1[9:2]),
        .din0({ cpu_dtw1, cpu_dtw1, cpu_dtw1, cpu_dtw1 }),
        .dout0(cpu_dtr1),

        .clk1(),
        .csb1(), 
        .addr1(),
        .dout1()
    );

    /*wire[31:0] rbuf0, rbuf1;
    assign cpu_dtr0 =
        cpu_addr0[1:0] == 2'b00 ? rbuf0[7:0] :
        cpu_addr0[1:0] == 2'b01 ? rbuf0[15:8] :
        cpu_addr0[1:0] == 2'b11 ? rbuf0[31:24] : rbuf0[23:16];
    assign cpu_dtr1 =
        cpu_addr0[1:0] == 2'b00 ? rbuf1[7:0] :
        cpu_addr0[1:0] == 2'b01 ? rbuf1[15:8] :
        cpu_addr0[1:0] == 2'b11 ? rbuf1[31:24] : rbuf1[23:16];*/
endmodule
