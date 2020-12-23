// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
module dev_intercon (
    input   wire clk,
    input   wire reset,
    // Usermode?
    input wire userbit,

    // Controller interface
    // rw and dtw are connected to all devices
    input   wire i_stb,
    output  wire o_ack,
    input   wire[31:0] i_addr,
    output  wire[31:0] o_dtr,
    input   wire[31:0] i_dtw,
    input   wire i_rw,

    // Devices interface
    input   wire[32*NS-1:0] i_dtr,
    input   wire[NS-1:0] i_ack,
    output  wire[NS-1:0] o_stb,
    output  wire[MASK_LEN-1:0] o_addr,

    // SRAM Interface
    output wire sstb,
    input  wire sack,
    input  wire[31:0] sdtr,

    // Interrupt (unknown address)
    output wire estb,
    input  wire eack,
    input  wire[31:0] edtr
);
    parameter NS = 1;
    parameter[MASK_LEN*NS-1:0] BASE = 0;
    parameter[MASK_LEN*NS-1:0] MASK = 0;
    parameter MASK_LEN = 8;
    parameter LIMITS = 12;

    reg[31:0] aict_base;
    reg[31:0] r_dtr;
    wire[NS-1:0] sel;
    wire none = userbit || (~(|sel));
    wire in_aict = !userbit && (aict_base[31:MASK_LEN] == i_addr[31:MASK_LEN]);
    wire in_base = in_aict && (i_addr[0+:MASK_LEN] == 0);
    wire ext = (|i_addr[31:LIMITS]) & ~in_aict;

    // Address decoder
    genvar i;
    generate
        for(i = 0; i < NS; i = i+1) begin
            assign sel[i] =
                in_aict &&
                ((i_addr[0+:MASK_LEN] & MASK[i*MASK_LEN+:MASK_LEN])
                    == BASE[i*MASK_LEN+:MASK_LEN]);
        end
    endgenerate

    assign o_addr = i_addr[0+:MASK_LEN];

    // Data selector
    integer j;
    always @(*) begin
        r_dtr = 32'b0;
        for(j = 0; j < 32 * NS; j = j+1)
            r_dtr[j%32] = r_dtr[j%32] | (sel[j/32] & i_dtr[j]);
    end

    // Assign outputs
    assign o_ack = ext ? eack : none ? sack : (in_base ? 1'b1 : |(i_ack & sel));
    assign o_stb = { NS{ i_stb & ~in_base } } & sel;
    assign o_dtr = ext ? edtr : none ? sdtr : (in_base ? aict_base : r_dtr);

    // SRAM select
    assign sstb = ~ext & none & i_stb & ~in_base;
    assign estb = ext & i_stb & ~in_base;

    // AICT base register
    always @(posedge clk) if(reset) begin
        aict_base <= 32'h0000_FF00;
    end else if(in_base && i_stb && i_rw) begin
        aict_base <= i_dtw;
        `ifdef SIM
            $display($time, " AICT moved to %X", i_dtw);
        `endif
    end
endmodule
