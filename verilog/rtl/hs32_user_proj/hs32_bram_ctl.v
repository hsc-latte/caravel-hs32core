/**
 * Copyright (c) 2020 The HSC Core Authors
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     https://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * @file   bram_ctl.v
 * @author Kevin Dai <kevindai02@outlook.com>
 * @date   Created on October 26 2020, 7:12 PM
 */

module hs32_bram_ctl (
    input   wire i_clk,
    input   wire i_reset,
    input   wire[addr_width-1:0] i_addr,
    output  wire[31:0] o_dread,
    input   wire[31:0] i_dwrite,
    input   wire i_rw,
    input   wire i_stb,
    output  reg  o_ack,

    // Terrible things
    output wire [15:0] cpu_addr_n,
    output wire [15:0] cpu_addr_e,
    output wire [7:0] cpu_mask_n,
    output wire [7:0] cpu_mask_e,
    output wire [1:0] cpu_wen_n,
    output wire [1:0] cpu_wen_e,
    output wire [31:0] wbuf,
    input  wire [31:0] dbuf0,
    input  wire [31:0] dbuf1,
    input  wire [31:0] dbuf2,
    input  wire [31:0] dbuf3
);
    parameter addr_width = 12;

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

    // Latch inputs
    wire[addr_width-1:0] addr;
    wire[31:0] dwrite;
    assign addr = i_addr;
    assign dwrite = i_dwrite;

    reg[31:0] r_dread;
    reg r_bsy;
    assign o_dread = r_bsy ? dout : r_dread;
    always @(posedge i_clk)
    if(i_reset) begin
        o_ack <= 0;
        r_bsy <= 0;
        r_dread <= 0;
    end else begin
        if(i_stb && !r_bsy) begin
            o_ack <= 1;
            r_bsy <= 1;
        end else if(r_bsy) begin
            o_ack <= 0;
            r_bsy <= 0;
            r_dread <= dout;
        end
    end

    // SRAM signal generation :(

    wire[31:0] dbuf;

    assign dbuf[7:0] =
        a3[1:0] == 2'b00 ? dbuf0[7:0] :
        a3[1:0] == 2'b01 ? dbuf0[15:8] :
        a3[1:0] == 2'b11 ? dbuf0[31:24] : dbuf0[23:16];
    assign dbuf[15:8] =
        a2[1:0] == 2'b00 ? dbuf1[7:0] :
        a2[1:0] == 2'b01 ? dbuf1[15:8] :
        a2[1:0] == 2'b11 ? dbuf1[31:24] : dbuf1[23:16];
    assign dbuf[23:16] =
        a1[1:0] == 2'b00 ? dbuf2[7:0] :
        a1[1:0] == 2'b01 ? dbuf2[15:8] :
        a1[1:0] == 2'b11 ? dbuf2[31:24] : dbuf2[23:16];
    assign dbuf[31:24] =
        a0[1:0] == 2'b00 ? dbuf3[7:0] :
        a0[1:0] == 2'b01 ? dbuf3[15:8] :
        a0[1:0] == 2'b11 ? dbuf3[31:24] : dbuf3[23:16];

    assign cpu_mask_n[7:4] =
        a0[1:0] == 2'b00 ? 4'b0001 :
        a0[1:0] == 2'b01 ? 4'b0010 :
        a0[1:0] == 2'b11 ? 4'b1000 : 4'b0100;
    assign cpu_mask_n[3:0] =
        a1[1:0] == 2'b00 ? 4'b0001 :
        a1[1:0] == 2'b01 ? 4'b0010 :
        a1[1:0] == 2'b11 ? 4'b1000 : 4'b0100;
    assign cpu_mask_e[7:4] =
        a2[1:0] == 2'b00 ? 4'b0001 :
        a2[1:0] == 2'b01 ? 4'b0010 :
        a2[1:0] == 2'b11 ? 4'b1000 : 4'b0100;
    assign cpu_mask_e[3:0] =
        a3[1:0] == 2'b00 ? 4'b0001 :
        a3[1:0] == 2'b01 ? 4'b0010 :
        a3[1:0] == 2'b11 ? 4'b1000 : 4'b0100;
    assign { cpu_wen_n, cpu_wen_e } = { 4{!i_rw} };
    assign cpu_addr_n = { a0[9:2], a1[9:2] };
    assign cpu_addr_e = { a2[9:2], a3[9:2] };
endmodule