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
 * @file   mmio.v
 * @author Kevin Dai <kevindai02@outlook.com>
 * @date   Created on November 29 2020, 9:04 PM
 */

`default_nettype none

module hs32_aic(
    input   wire clk,
    input   wire reset,

    // Memory interface in
    input   wire stb,
    output  wire ack,
    input   wire[4:0] addr,
    input   wire[31:0] dtw,
    output  wire[31:0] dtr,
    input   wire rw,

    // Interrupt controller
    input   wire[23:0] interrupts,  // Interrupt lines
    output  wire[31:0] handler,     // ISR address
    output  wire intrq,             // Request interrupt
    output  wire[4:0] vec,          // Interrupt vector
    output  wire nmi                // Non maskable interrupt
);
    assign ack = 1;

    // Advanced Interrupt Controller Table
    reg[31:0] aict[23:0];

    // Check if there's interrupt(s)
    assign intrq = (|interrupts) & (aict[vec][0] | nmi);

    // NMI
    assign nmi = interrupts[0] || interrupts[1];

    // Interrupt Priority
    // LSB gets higher priority
    assign vec =
        interrupts[0] ? 0 :
        interrupts[1] ? 1 :
        interrupts[2] ? 2 :
        interrupts[3] ? 3 :
        interrupts[4] ? 4 :
        interrupts[5] ? 5 :
        interrupts[6] ? 6 :
        interrupts[7] ? 7 :
        interrupts[8] ? 8 :
        interrupts[9] ? 9 :
        interrupts[10] ? 10 :
        interrupts[11] ? 11 :
        interrupts[12] ? 12 :
        interrupts[13] ? 13 :
        interrupts[14] ? 14 :
        interrupts[15] ? 15 :
        interrupts[16] ? 16 :
        interrupts[17] ? 17 :
        interrupts[18] ? 18 :
        interrupts[19] ? 19 :
        interrupts[20] ? 20 :
        interrupts[21] ? 21 :
        interrupts[22] ? 22 : 23;
    assign handler = aict[vec] & (~32'b11);

    // Calculate table index
    wire[4:0] aict_idx = addr-1;

    // 1 clock cycle
    // assign ack = stb;
    assign dtr = aict[aict_idx];

    // Reset and write
    integer i;
    always @(posedge clk) if(reset) begin
        for(i = 0; i < 24; i++)
            aict[i] <= 0;
    end else if(stb && rw) begin
        aict[aict_idx] <= dtw;
        `ifdef SIM
            $display($time, " AICT write %X <- %X", aict_idx, dtw);
        `endif
    end
endmodule
