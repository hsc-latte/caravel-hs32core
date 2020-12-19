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
 * @file   hs32_core1.v
 * @author Kevin Dai <kevindai02@outlook.com>
 * @date   Created on December 16 2020, 12:25 AM
 */

`ifdef verilator
    `include "defines.v"
    `include "cpu/hs32_cpu.v"

    `include "hs32_user_proj/hs32_aic.v"
    `include "hs32_user_proj/hs32_bram_ctl.v"
    `include "hs32_user_proj/dev_filter.v"
    `include "hs32_user_proj/dev_timer.v"
    `include "hs32_user_proj/dev_intercon.v"
`endif

`default_nettype none

module hs32_core1 (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (south face)
    input  wire wb_clk_i,
    input  wire wb_rst_i,
    input  wire wbs_stb_i,
    input  wire wbs_cyc_i,
    input  wire wbs_we_i,
    input  wire [3:0] wbs_sel_i,
    input  wire [31:0] wbs_dat_i,
    input  wire [31:0] wbs_adr_i,
    output wire wbs_ack_o,
    output wire [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  wire [1:0] la_data_in,
    // output wire [127:0] la_data_out,
    input  wire [1:0] la_oen,

    // IOs
    input  wire [`MPRJ_IO_PADS-1:0] io_in,
    output reg  [`MPRJ_IO_PADS-1:0] io_out,
    output reg  [`MPRJ_IO_PADS-1:0] io_oeb,
    
    // Output (north and east faces)
    output wire [7:0]  cpu_mask_n,
    output wire [7:0]  cpu_mask_e,
    output wire [1:0]  cpu_wen_n,
    output wire [1:0]  cpu_wen_e,
    output wire [15:0] cpu_addr_n,
    output wire [15:0] cpu_addr_e,
    output wire [15:0] cpu_dtw_n,
    output wire [15:0] cpu_dtw_e,
    input  wire [31:0] cpu_dtr_n0,
    input  wire [31:0] cpu_dtr_n1,
    input  wire [31:0] cpu_dtr_e0,
    input  wire [31:0] cpu_dtr_e1,

    // Can't have constants in wrapper
    output wire zero,
    output wire one,

    // Chip enable
    output wire ram_ce
);
    // Output constants
    assign zero = 1'b0;
    assign one = 1'b1;

    // Clock and reset
    // wire clk = (~la_oen[64])? la_data_in[64] : wb_clk_i;
    wire clk = wb_clk_i;
    wire rst = (~la_oen[0]) ? la_data_in[0] : wb_rst_i;
    
    //===============================//
    // Main CPU core
    //===============================//

    wire[31:0] cpu_addr, cpu_dread, cpu_dwrite;
    wire cpu_rw, cpu_stb, cpu_ack, flush;

    hs32_cpu #(
        .IMUL(1), .BARREL_SHIFTER(1), .PREFETCH_SIZE(3)
    ) core (
        .i_clk(clk), .reset(rst),

        .addr(cpu_addr), .rw(cpu_rw),
        .din(cpu_dread), .dout(cpu_dwrite),
        .stb(cpu_stb), .ack(cpu_ack),

        .interrupts(inte),
        .iack(), .handler(isr),
        .intrq(irq), .vec(ivec),
        .nmi(nmi),

        .flush(flush), .fault(), .userbit()
    );

    //===============================//
    // Caravel + CPU Memory Bus
    //===============================//

    // Wishbone logic
    wire bus_hold = !(~la_oen[1] & la_data_in[1]);
    wire wb_stb = wbs_cyc_i && wbs_stb_i; 
    wire wb_rw = |wbs_sel_i & wbs_we_i;

    // Bus multiplexer (caravel and main core)
    wire[31:0] addr, dread, dwrite;
    wire rw, stb, ack;
    assign stb      = bus_hold ? wb_stb : cpu_stb;
    assign addr     = bus_hold ? wbs_adr_i : cpu_addr;
    assign dwrite   = bus_hold ? wbs_dat_i : cpu_dwrite;
    assign rw       = bus_hold ? wb_rw : cpu_rw;
    assign wbs_dat_o = dread;
    assign cpu_dread = dread;
    assign wbs_ack_o = bus_hold ? ack : 0;
    assign cpu_ack = bus_hold ? 0: ack;

    reg ram_bsy;
    assign ram_ce = ~(ram_stb | ram_bsy);
    always @(posedge clk) if(rst)
        ram_bsy <= 0;
    else begin
        if(ram_stb && !ram_bsy) begin
            ram_bsy <= 1;
        end else if(ram_ack && ram_bsy) begin
            ram_bsy <= 0;
        end
    end

    `ifdef SIM
        reg bsy;
        always @(posedge clk) if(rst)
            bsy <= 0;
        else if(stb && !bsy) begin
            bsy <= 1;
        end else if(ack && bsy) begin
            bsy <= 0;
            `ifdef LOG_MEMORY_WRITE
                if(rw) $display($time, " Writing [%X] <- %X", addr, dwrite);
            `endif
            `ifdef LOG_MEMORY_READ
                if(!rw) $display($time, " Reading [%X] -> %X", addr, dread);
            `endif
        end
    `endif

    //===============================//
    // Memory bus interconnect
    //===============================//

    wire [31:0] aic_dtr, sr0_dtr, sr1_dtr;
    reg  [31:0] gpt_dtr;
    wire aic_ack, gpt_ack, sr0_ack, sr1_ack;
    wire aic_stb, gpt_stb, sr0_stb, sr1_stb;
    wire[9:0] mmio_addr;
    dev_intercon mmio_conn (
        .clk(clk), .reset(rst),
        
        // Input
        .i_stb(stb), .o_ack(ack),
        .i_addr(addr), .o_dtr(dread),
        .i_rw(rw), .i_dtw(dwrite),

        // Devices
        .i_dtr({ sr1_dtr, sr0_dtr, gpt_dtr, aic_dtr }),
        .i_ack({ sr1_ack, sr0_ack, gpt_ack, aic_ack }),
        .o_stb({ sr1_stb, sr0_stb, gpt_stb, aic_stb }),
        .o_addr(mmio_addr),

        // SRAM
        .sstb(ram_stb), .sack(ram_ack), .sdtr(ram_dread)
    );
    assign ram_rw = rw;
    assign ram_addr = addr;
    assign ram_dwrite = dwrite;

    //===============================//
    // Interrupts
    //===============================//

    wire [23:0] inte;
    wire [4:0] ivec;
    wire [31:0] isr;
    wire irq, nmi;

    hs32_aic aict (
        .clk(clk), .reset(rst),
        // Bus
        .stb(aic_stb), .ack(aic_ack),
        .addr(mmio_addr), .dtw(dwrite),
        .dtr(aic_dtr), .rw(rw),
        // Interrupt controller
        .interrupts(inte), .handler(isr),
        .intrq(irq), .vec(ivec), .nmi(nmi)
    );

    //===============================//
    // GPIO
    //===============================//

    localparam NUM_IO = `MPRJ_IO_PADS;
    wire[NUM_IO-1:0] io_in_sync, io_in_rise, io_in_fall;

    // Generate filter block
    dev_filter filter[NUM_IO-1:0](
        .clk(clk),
        .rst(rst),
        .a(io_in),
        .b(io_in_sync),
        .rise(io_in_rise),
        .fall(io_in_fall)
    );

    assign gpt_ack = 1;
    reg[75:0] io_int;
    always @(posedge clk) if(rst) begin
        io_out <= 0;
        io_oeb <= 0;
        io_int <= 0;
    end else begin
        if(gpt_stb && rw) case(mmio_addr)
            0: begin end
            1: io_out[31:0] <= dwrite;
            2: io_out[37:32] <= dwrite[5:0];
            3: io_oeb[31:0] <= dwrite;
            4: io_oeb[37:32] <= dwrite[5:0];
            5: io_int[31:0] <= dwrite;
            6: io_int[63:32] <= dwrite;
            7: io_int[75:64] <= dwrite[11:0];
            default: begin end
        endcase
    end
    always @(*) begin
        case(mmio_addr)
            0: begin end
            1: gpt_dtr = io_out[31:0];
            2: gpt_dtr = { 26'b0, io_out[37:32] };
            3: gpt_dtr = io_oeb[31:0];
            4: gpt_dtr = { 26'b0, io_oeb[37:32] };
            5: gpt_dtr = io_int[31:0];
            6: gpt_dtr = io_int[63:32];
            7: gpt_dtr = { 20'b0, io_int[75:64] };
            default: begin end
        endcase
    end

    //===============================//
    // Timer
    //===============================//

    localparam T0_IO_NUM = 15;
    localparam T1_IO_NUM = 16;
    localparam T2_IO_NUM = 17;

    // Timer 0 (there has to be a better way to do this)
    wire t0_match_int;
    wire t0_io_out;
    reg[7:0] t0_config;
    reg[15:0] t0_match;
    dev_timer #(
        .TIMER_BITS(16)
    ) dev_timer0 (
        .clk(clk), .reset(rst),
        .clk_source(t0_config[2:0]),
        .timer_mode(t0_config[4:3]),
        .output_mode(t0_config[6:5]),
        .match(t0_match),
        .int_match(t0_match_int),
        .io(t0_io_out),
        .io_risen(io_in_rise[T0_IO_NUM]),
        .io_fallen(io_in_fall[T0_IO_NUM])
    );

    // Timer 1
    wire t1_match_int;
    wire t1_io_out;
    reg[7:0] t1_config;
    reg[15:0] t1_match;
    dev_timer #(
        .TIMER_BITS(16)
    ) dev_timer1 (
        .clk(clk), .reset(rst),
        .clk_source(t1_config[2:0]),
        .timer_mode(t1_config[4:3]),
        .output_mode(t1_config[6:5]),
        .match(t1_match),
        .int_match(t1_match_int),
        .io(t1_io_out),
        .io_risen(io_in_rise[T1_IO_NUM]),
        .io_fallen(io_in_fall[T1_IO_NUM])
    );

    // Timer 2
    wire t2_match_int;
    wire t2_io_out;
    reg[7:0] t2_config;
    reg[31:0] t2_match;
    dev_timer #(
        .TIMER_BITS(32)
    ) dev_timer2 (
        .clk(clk), .reset(rst),
        .clk_source(t2_config[2:0]),
        .timer_mode(t2_config[4:3]),
        .output_mode(t2_config[6:5]),
        .match(t2_match),
        .int_match(t2_match_int),
        .io(t2_io_out),
        .io_risen(io_in_rise[T2_IO_NUM]),
        .io_fallen(io_in_fall[T2_IO_NUM])
    );

    //===============================//
    // UART
    //===============================//



    //===============================//
    // Internal SRAM controller
    //===============================//

    wire[31:0] ram_addr, ram_dread, ram_dwrite;
    wire ram_rw, ram_stb, ram_ack;

    hs32_bram_ctl bram_ctl(
        .i_clk(clk),
        .i_reset(rst || flush),
        .i_addr(ram_addr[11:0]), .i_rw(ram_rw),
        .o_dread(ram_dread), .i_dwrite(ram_dwrite),
        .i_stb(ram_stb), .o_ack(ram_ack),

        // Outputs
        .cpu_mask_n(cpu_mask_n),
        .cpu_mask_e(cpu_mask_e),
        .cpu_wen_n(cpu_wen_n),
        .cpu_wen_e(cpu_wen_e),
        .cpu_addr_n(cpu_addr_n),
        .cpu_addr_e(cpu_addr_e),
        .wbuf({ cpu_dtw_n, cpu_dtw_e }),
        .dbuf3(cpu_dtr_n0),
        .dbuf2(cpu_dtr_n1),
        .dbuf1(cpu_dtr_e0),
        .dbuf0(cpu_dtr_e1)
    );
endmodule
