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
 * limitations under the License. SPDX-License-Identifier: Apache-2.0
 * 
 * @file   dev_timer.v
 * @author Kevin Dai <kevindai02@outlook.com>
 * @date   Created on December 17 2020, 12:31 AM
 */

module dev_timer (
    input   wire clk,
    input   wire reset,

    // Outputs
    output  reg  int_match,
    output  reg  int_ovf,
    output  wire io,
    output  wire io_oe,

    // Pulse for 1T if I/O risen/fallen
    input wire io_risen,
    input wire io_fallen,

    // R/W Port
    input wire we,
    input wire[1:0] addr,
    input wire[31:0] dtw,
    output reg[31:0] dtr,
    input wire stb,
    output wire ack
);
    parameter TIMER_BITS = 16;

`define TIMER_MODE_CTC      1
`define TIMER_MODE_SPWM     2 // Single edge PWM
`define TIMER_MODE_DPWM     3 // Dual edge PWM (rise/fall)
`define TIMER_OUTPUT_TOGGLE 1
`define TIMER_OUTPUT_INV    3

    // Registers
    reg[6:0] tconfig;
    reg[TIMER_BITS-1:0] match;
    reg[TIMER_BITS-1:0] counter;
    wire[2:0] clk_source = tconfig[2:0];
    wire[1:0] timer_mode = tconfig[4:3];
    wire[1:0] output_mode = tconfig[6:5];
    always @(*) case(addr)
        0: dtr = { 25'b0, tconfig };
        1: dtr = { {(32-TIMER_BITS){1'b0}}, match };
        2: dtr = { {(32-TIMER_BITS){1'b0}}, counter };
        default: dtr = 0;
    endcase

    // Timer scaling
    reg[10:0] divider;
    wire scale_clk =
        clk_source == 1 ? 1 :
        clk_source == 2 ? divider[3] : // scale clk 8
        clk_source == 3 ? divider[6] : // scale clk 64
        clk_source == 4 ? divider[8] : // scale clk 256
        clk_source == 5 ? divider[10] : // scale clk 1024
        clk_source == 6 ? io_risen :
        clk_source == 7 ? io_fallen : 0;
    // !! Check not disabled !! //
    wire timer_match = match == counter && clk_source != 0;
    wire timer_ovf = & counter;

    reg direction; // 1 is ++
    reg io_normal, io_spwm, io_dpwm;
    wire io_output =
        timer_mode == `TIMER_MODE_SPWM ? io_spwm :
        timer_mode == `TIMER_MODE_DPWM ? io_dpwm : io_normal;
    assign io = output_mode == `TIMER_OUTPUT_INV ? ~io_output : io_output;
    assign io_oe = output_mode != 0;

    // Configuration, drives: match, tconfig
    always @(posedge clk) if(reset) begin
        match <= 0;
        tconfig <= 0;
    end else if(we && stb) begin
        if(addr == 0) begin
            tconfig <= dtw[6:0];
        end else if(addr == 1) begin
            match <= dtw[TIMER_BITS-1:0];
        end
    end
    assign ack = 1;
    /*always @(posedge clk) if(reset) begin
        ack <= 0;
    end else if(stb) begin
        ack <= 1;
    end else begin
        ack <= 0;
    end*/
    
    // Clock divider, drives: divider
    always @(posedge clk) if(reset || we) begin
        divider <= 0;
    end else begin
        if(scale_clk) begin
            divider <= 0;
        end else begin
            divider <= divider + 1;
        end
    end

    // Counter, drives: counter
    always @(posedge clk) if(reset) begin
        counter <= 0;
    end else if(we && addr == 2) begin
        counter <= dtw[TIMER_BITS-1:0];
    end else if(scale_clk) begin
        if(timer_match && timer_mode == `TIMER_MODE_CTC) begin
            counter <= 0;
        end else begin
            counter <=
                timer_mode == `TIMER_MODE_DPWM && (counter == {TIMER_BITS{1'b1}} || !direction) ?
                counter - 1 : counter + 1;
        end
    end

    // Counter direction, drives: direction
    always @(posedge clk) if(reset || we) begin
        direction <= 1;
    end else if(scale_clk) begin
        if(timer_ovf && timer_mode == `TIMER_MODE_DPWM) begin
            direction <= ~direction;
        end else if(counter == 1) begin
            direction <= 1;
        end
    end

    // Timer output, drives: io_normal
    always @(posedge clk) if(reset || we) begin
        io_normal <= 0;
    end else begin
        if(timer_match) begin
            io_normal <= output_mode == `TIMER_OUTPUT_TOGGLE ? ~io_normal : 1;
        end
    end

    // Timer output, drives: io_spwm
    always @(posedge clk) if(reset || we) begin
        io_spwm <= 0;
    end else begin
        if(timer_match) begin
            io_spwm <= 1;
        end else if(timer_ovf) begin
            io_spwm <= 0;
        end
    end

    // Timer output, drives: io_dpwm
    always @(posedge clk) if(reset || we) begin
        io_dpwm <= 0;
    end else begin
        if(timer_match && direction) begin
            io_dpwm <= 1;
        end else if(timer_match && !direction) begin
            io_dpwm <= 0;
        end
    end

    // Interrupts, drive: int_match
    always @(posedge clk) if(reset) begin
        int_match <= 0;
    end else begin
        if(timer_match) begin
            int_match <= 1;
        end else begin
            int_match <= 0;
        end
    end

    // Interrupts, drive: int_ovf
    always @(posedge clk) if(reset) begin
        int_ovf <= 0;
    end else begin
        if(timer_ovf) begin
            int_ovf <= 1;
        end else begin
            int_ovf <= 0;
        end
    end
endmodule