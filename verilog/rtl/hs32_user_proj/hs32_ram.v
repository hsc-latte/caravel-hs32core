`ifdef verilator
    `include "defines.v"
`endif

`default_nettype none
 
module storage (
    input   wire clk,
    input   wire[addr_width-1:0] addr,
    output  reg [31:0] dread,
    input   wire[31:0] dwrite,
    input   wire rw,
    input   wire valid,
    output  reg  ready
);
    parameter addr_width = 8;
    
    // 4 addresses for each bram
    // Selects between current dword and next dword
    wire [addr_width-3:0] a0, a1, a2, a3;
    assign a0 = (addr[1:0] == 2'b00) ?
        addr[addr_width-1:2] : addr[addr_width-1:2] + 1;
    assign a1 = (addr[1:0] == 2'b00) || (addr[1:0] == 2'b01) ?
        addr[addr_width-1:2] : addr[addr_width-1:2] + 1;
    assign a2 = (addr[1:0] == 2'b11) ?
        addr[addr_width-1:2] + 1 : addr[addr_width-1:2];
    assign a3 = addr[addr_width-1:2];
    //
    // The read buffer shifted over.
    // Regarding the ending 2 bits of the address:
    // x = read, . = ignore
    //       a'  a'+1   -> where a' = addr[addr_width-1:2]
    // 00 [xxxx][....]
    // 01 [.xxx][x...]
    // 10 [..xx][xx..]
    // 11 [...x][xxx.]
    //     0123  0123   -> bram# the byte came from
    // dbuf will always be in the form of [0123]
    // So, an address ending in 11 should be [3012]
    //
    wire[31:0] dout;
    wire[31:0] dbuf, wbuf;
    assign dout =
        (addr[1:0] == 2'b00) ? { dbuf[31:0] } :
        (addr[1:0] == 2'b01) ? { dbuf[23:0], dbuf[31:24] } :
        (addr[1:0] == 2'b10) ? { dbuf[15:0], dbuf[31:16] } :
                               { dbuf[ 7:0], dbuf[31:8] } ;
    assign wbuf =
        (addr[1:0] == 2'b00) ? { dwrite[31:0] } :
        (addr[1:0] == 2'b01) ? { dwrite[ 7:0], dwrite[31:8 ] } :
        (addr[1:0] == 2'b10) ? { dwrite[15:0], dwrite[31:16] } :
                               { dwrite[23:0], dwrite[31:24] } ;

    // Write enable signal
    wire we; assign we = valid & rw;

    // FSM (needed?)
    reg[1:0] state = 0;
    always @(posedge clk) case(state)
        0: begin 
            if(valid) begin
                state <= 1;
            end
            ready <= 1;
            dread <= dout;
        end
        1: begin
            state <= 0;
            ready <= 0;
        end
    endcase

    sram_1rw1r_32_256_8_sky130 SRAM_0 (
        // MGMT R/W port
        .clk0(clk),
        .csb0(mgmt_ena[0]),
        .web0(mgmt_wen[0]),
        .wmask0(mgmt_wen_mask[3:0]),
        .addr0(addr),
        .din0(dwrite),
        .dout0(dread)
    ); 

    sram_1rw1r_32_256_8_sky130 SRAM_1 (
        // MGMT R/W port
        .clk0(mgmt_clk),
        .csb0(mgmt_ena[1]),   
        .web0(mgmt_wen[1]),
        .wmask0(mgmt_wen_mask[7:4]),
        .addr0(mgmt_addr),
        .din0(mgmt_wdata),
        .dout0(mgmt_rdata[63:32])
    );
endmodule
`default_nettype wire
