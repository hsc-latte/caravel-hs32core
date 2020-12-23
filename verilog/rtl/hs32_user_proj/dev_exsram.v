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
 * @file   sram.v
 * @author Kevin Dai <kevindai02@outlook.com>
 * @date   Created on December 09 2020, 11:48 AM
 */

module dev_exsram (
    input clk, input reset,

    // Request interface
    output  reg  ack,
    input   wire stb,
    input   wire i_rw, // Write = 1
    input   wire[31:0] i_addr,
    input   wire[31:0] i_dtw,
    output  reg [31:0] dtr,

    // External IO, all active > HIGH <
    input   wire[15:0] din,
    output  reg [15:0] dout,
    output  reg we,
    output  reg oe,
    output  reg oe_negedge,
    output  reg ale0_negedge,
    output  reg ale1_negedge,
    output  reg bhe,
    output  reg isout
);
    parameter SRAM_LATCH_LAZY = 1;

    `define B0 7:0
    `define B1 15:8
    `define B2 23:16
    `define B3 31:24

    /*
     * Byte aligned read and write:
     * Mask = 0011, 1100
     * BHLE = 11, 11
     * Misaligned read and write:
     * Mask = 0001, 0110, 1000
     * BHLE = 10, 11, 01
    */

    // For byte addressing headaches
    reg addrl, lastble, hasinit;
    wire ble;
    reg[3:0] mask;
    reg[31:0] addr;
    reg[2:0] state;

    // Latched inputs
    wire[31:0] addri, dtw;
    wire rw;
    reg[31:0] r_addr, r_dtw;
    reg r_rw;
    assign addri = state == 0 ? i_addr : r_addr;
    assign dtw = state == 0 ? i_dtw : r_dtw;
    assign rw = state == 0 ? i_rw : r_rw;

    // Bleh
    assign ble = !(mask[1] | !rw);

    // Generate SRAM_LATCH_LAZY
    // For waveforms and cycle names, see CPU.md
    generate always @(posedge clk)
    if(reset) begin
        state   <= 0;
        mask    <= 0;
        addrl   <= 0;
        addr    <= 0;
        lastble <= 0;
        hasinit <= 0;
        isout <= 0;
    end else case(state)
        // T1
        3'b000: begin
            state   <= stb ?
                // We can skip 1 cycle if the MSBs is the same
                ({ ble, addr[31:17] } == { lastble, addri[31:17] }) && hasinit
                ? 3'b010 : 3'b001 : 0;
            dout    <= addri[16:1];
            addrl   <= addri[0];
            mask    <= addri[0] && !rw ? 4'b0001 : 4'b0011;
            addr    <= addri;
            r_addr  <= i_addr;
            r_rw    <= i_rw;
            r_dtw   <= i_dtw;
            isout   <= stb;
            oe      <= 0;
            ack     <= 0;
        end
        // T2
        3'b001: begin
            state   <= reset ? 0 : 3'b010;
            // BLE is active low and NOT inverted on the output
            dout    <= { ble, addr[31:17] };
            we      <= rw;
            if(SRAM_LATCH_LAZY) begin
                hasinit <= 1;
            end
        end
        // TW (wait 1 cycle)
        3'b010: begin
            state   <= reset ? 0 : 3'b100;
            // I/O output mode only in write mode
            isout   <= rw;
            // Dirty hack :(
            dout    <= rw ?
                mask == 4'b0001 ? { dtw[`B1], 8'b0 } :
                mask == 4'b0011 ? dtw[15:0] :
                mask == 4'b0110 ? dtw[23:8] :
                mask == 4'b1100 ? dtw[31:16] :
                { 8'b0, dtw[`B3] } : 16'b0;
            // BHE is active low and INVERTED on the output
            bhe     <= mask[0] | !rw;
            // Output enable only in read mode
            oe      <= !rw;
        end
        // T3 (wait for oe_negedge)
        3'b100: begin
            state   <= mask[3] || reset ? 3'b000 : 3'b101;
            mask    <= mask[0] ? addrl  && !rw ? 4'b0110 : 4'b1100 : 4'b1000;
            ack     <= !reset && mask[3];
            we      <= 0;
            addr    <= addr + 2;        
            lastble <= ble;
            // Write result to dtr (always)
            dtr[`B0] <= mask[0] ? addrl ? din[`B1] : din[`B0] : dtr[`B0];
            dtr[`B1] <= mask[1] ? addrl ? din[`B0] : din[`B1] : dtr[`B1];
            dtr[`B2] <= mask[2] ? addrl ? din[`B1] : din[`B0] : dtr[`B2];
            dtr[`B3] <= mask[3] ? addrl ? din[`B0] : din[`B1] : dtr[`B3];
        end
        3'b101: begin
            state   <= reset ? 0 :
                // We can skip 1 cycle if the MSBs is the same
                { ble, addr[31:17] } == { lastble, addri[31:17] }
                ? 3'b010 : 3'b001;
            dout    <= addr[16:1];
            isout   <= 1;
            oe      <= 0;
            ack     <= 0;
        end
        // So Anthony doesn't complain
        default: begin
            state   <= 3'd0;
        end
    endcase

    // Negedge signals
    always @(negedge clk) case(state)
        // Before T1
        3'b000, 3'b101: begin
            oe_negedge   <= 0;
            ale0_negedge <= 1;
        end
        // Before T2
        3'b001: begin
            ale0_negedge <= 0;
            ale1_negedge <= 1;
        end
        // Before TW
        3'b010: begin
            ale0_negedge <= 0;
            ale1_negedge <= 0;
            oe_negedge   <= 1;
        end
        // So verilator doesn't complain
        default: begin end
    endcase
    endgenerate
endmodule