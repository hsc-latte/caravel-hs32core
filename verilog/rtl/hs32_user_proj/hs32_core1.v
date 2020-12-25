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
    `include "hs32_user_proj/dev_timer.v"
    `include "hs32_user_proj/dev_gpio.v"
    `include "hs32_user_proj/dev_wb.v"
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
    output wire [2:0] la_data_out,
    input  wire [1:0] la_oen,

    // IOs
    input  wire [`MPRJ_IO_PADS-1:0] io_in,
    output wire [`MPRJ_IO_PADS-1:0] io_out,
    output wire [`MPRJ_IO_PADS-1:0] io_oeb, // Active low
    
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
    output wire zero_n,
    output wire one_n,
    output wire zero_e,
    output wire one_e,

    // Chip enable
    output wire ram_ce_n,
    output wire ram_ce_e
);
    // Output constants
    assign zero_n = 1'b0;
    assign zero_e = 1'b0;
    assign one_n = 1'b1;
    assign one_e = 1'b1;
    assign ram_ce_n = ram_ce;
    assign ram_ce_e = ram_ce;

    // Clock and reset
    // wire clk = (~la_oen[64])? la_data_in[64] : wb_clk_i;
    wire clk = wb_clk_i;
    wire rst = (~la_oen[0]) ? la_data_in[0] : wb_rst_i;

    assign la_data_out[0] = iack;
    assign la_data_out[1] = fault;
    assign la_data_out[2] = userbit;
    
    //===============================//
    // Main CPU core
    //===============================//

    wire[31:0] cpu_addr, cpu_dread, cpu_dwrite;
    wire cpu_rw, cpu_stb, cpu_ack, flush;
    wire iack, fault, userbit;

    hs32_cpu #(
        .IMUL(1), .BARREL_SHIFTER(1),
        .PREFETCH_SIZE(3)
        ,.LOW_WATER(1)
    ) core (
        .i_clk(clk), .reset(rst),

        .addr(cpu_addr), .rw(cpu_rw),
        .din(cpu_dread), .dout(cpu_dwrite),
        .stb(cpu_stb), .ack(cpu_ack),

        .interrupts(inte),
        .iack(iack), .handler(isr),
        .intrq(irq), .vec(ivec),
        .nmi(nmi),

        .flush(flush), .fault(fault), .userbit(userbit)
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
    assign addr     = bus_hold ? wbs_adr_i & 32'h0FFF_FFFF : cpu_addr;
    assign dwrite   = bus_hold ? wbs_dat_i : cpu_dwrite;
    assign rw       = bus_hold ? wb_rw : cpu_rw;
    assign wbs_dat_o = bus_hold ? dread : wbs_dev_dtr;
    assign cpu_dread = dread;
    assign wbs_ack_o = bus_hold ? ack : wbs_dev_ack;
    assign cpu_ack = bus_hold ? 0 : ack;

    reg ram_bsy;
    wire ram_ce = ~(ram_stb | ram_bsy);
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
        wire dolog = (stb && ack) || (ack && bsy);

        always @(posedge clk) if(rst)
            bsy <= 0;
        else if(stb && !ack) begin
            bsy <= 1;
        end else if(ack && bsy) begin
            bsy <= 0;
        end

        always @(posedge clk) if(dolog) begin
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

    wire[7:0] mmio_addr;
    dev_intercon #(
        .NS(7),
        .BASE({
            { 1'b0, 7'b0 },
            { 1'b1, 2'b00, 5'b0 },
            { 1'b1, 2'b01, 1'b0, 4'b0 },
            { 1'b1, 2'b01, 1'b1, 4'b0 },
            { 1'b1, 2'b10, 1'b0, 4'b0 },
            { 1'b1, 2'b10, 1'b1, 4'b0 },
            { 1'b1, 2'b11, 1'b0, 4'b0 }
        }),
        .MASK({
            { 1'b1, 7'b0 },
            { 1'b1, 2'b11, 5'b0 },
            { 1'b1, 2'b11, 1'b1, 4'b0 },
            { 1'b1, 2'b11, 1'b1, 4'b0 },
            { 1'b1, 2'b11, 1'b1, 4'b0 },
            { 1'b1, 2'b11, 1'b1, 4'b0 },
            { 1'b1, 2'b11, 1'b1, 4'b0 }
        }),
        .MASK_LEN(8),
        .LIMITS(12)
    ) mmio_conn (
        .clk(clk), .reset(rst), .userbit(userbit),
        
        // Input
        .i_stb(stb), .o_ack(ack),
        .i_addr(addr), .o_dtr(dread),
        .i_rw(rw), .i_dtw(dwrite),

        // Devices
        .i_dtr({ aic_dtr, gpt_dtr, t0_dtr, t1_dtr, t2_dtr, dwb_dtr, ext_dtr }),
        .i_ack({ aic_ack, gpt_ack, t0_ack, t1_ack, t2_ack, dwb_ack, ext_ack }),
        .o_stb({ aic_stb, gpt_stb, t0_stb, t1_stb, t2_stb, dwb_stb, ext_stb }),
        .o_addr(mmio_addr),

        // SRAM
        .sstb(ram_stb), .sack(ram_ack), .sdtr(ram_dread),

        // Buf
        .estb(ext_dev_stb), .eack(ext_dev_ack), .edtr(ext_dev_dtr)
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

    wire [31:0] aic_dtr;
    wire aic_ack, aic_stb;

    hs32_aic aict (
        .clk(clk), .reset(rst),
        // Bus
        .stb(aic_stb), .ack(aic_ack),
        .addr(mmio_addr[6:2]), .dtw(dwrite),
        .dtr(aic_dtr), .rw(rw),
        // Interrupt controller
        .interrupts(hw_irq | inte), .handler(isr),
        .intrq(irq), .vec(ivec), .nmi(nmi)
    );

    wire[23:0] hw_irq = {
        gpt_irqr | gpt_irqf,
        tn_ints,
        dwb_irq & !bus_hold,
        ext_irq,
        15'b0
    };

    //===============================//
    // GPIO
    //===============================//
    
    wire[31:0] gpt_dtr;
    wire gpt_ack, gpt_stb, gpt_irqr, gpt_irqf;

    // IO rise/fall triggers
    wire[31:0] io_in_sync, io_in_rise, io_in_fall;
    wire[37:0] io_out_buf, io_oeb_buf;

    dev_gpio32 #(
        .TOTAL_IO(`MPRJ_IO_PADS)
    ) gpio32 (
        .clk(clk), .reset(rst),
        .io_in(io_in),
        .io_out(io_out_buf),
        .io_oeb(io_oeb_buf),
        .io_in_sync(io_in_sync),
        .io_in_rise(io_in_rise),
        .io_in_fall(io_in_fall),
        
        .stb(gpt_stb), .ack(gpt_ack),
        .rw(rw), .addr(mmio_addr[4:2]),
        .dwrite(dwrite), .dtr(gpt_dtr),

        .io_irqr(gpt_irqr),
        .io_irqf(gpt_irqf)
    );

    // Assign outputs
    assign io_out = {
        io_out_buf[37:T0_IO_NUM+3],
        t2_io_oe ? t2_io_out : io_out_buf[T0_IO_NUM+2],
        t1_io_oe ? t1_io_out : io_out_buf[T0_IO_NUM+1],
        t0_io_oe ? t0_io_out : io_out_buf[T0_IO_NUM],
        io_out_buf[T0_IO_NUM-1:0]
    };
    assign io_oeb = io_oeb_buf;

    //===============================//
    // Timer
    //===============================//

    localparam T0_IO_NUM = 15;
    wire t0_stb, t1_stb, t2_stb;
    wire t0_ack, t1_ack, t2_ack;
    wire[31:0] t0_dtr, t1_dtr, t2_dtr;
    wire[5:0] tn_ints;

    // Timer 0
    wire t0_io_out, t0_io_oe;
    dev_timer #(
        .TIMER_BITS(16)
    ) dev_timer0 (
        .clk(clk), .reset(rst),
        .int_match(tn_ints[0]),
        .int_ovf(tn_ints[1]),
        .io(t0_io_out),
        .io_oe(t0_io_oe),
        .io_risen(io_in_rise[T0_IO_NUM]),
        .io_fallen(io_in_fall[T0_IO_NUM]),
        .we(rw), .stb(t0_stb), .ack(t0_ack),
        .addr(mmio_addr[3:2]),
        .dtw(dwrite), .dtr(t0_dtr)
    );

    // Timer 1
    wire t1_io_out, t1_io_oe, t1_we;
    dev_timer #(
        .TIMER_BITS(16)
    ) dev_timer1 (
        .clk(clk), .reset(rst),
        .int_match(tn_ints[2]),
        .int_ovf(tn_ints[3]),
        .io(t1_io_out),
        .io_oe(t1_io_oe),
        .io_risen(io_in_rise[T0_IO_NUM+1]),
        .io_fallen(io_in_fall[T0_IO_NUM+1]),
        .we(rw), .stb(t1_stb), .ack(t1_ack),
        .addr(mmio_addr[3:2]),
        .dtw(dwrite), .dtr(t1_dtr)
    );

    // Timer 2
    wire t2_io_out, t2_io_oe, t2_we;
    dev_timer #(
        .TIMER_BITS(32)
    ) dev_timer2 (
        .clk(clk), .reset(rst),
        .int_match(tn_ints[4]),
        .int_ovf(tn_ints[5]),
        .io(t2_io_out),
        .io_oe(t2_io_oe),
        .io_risen(io_in_rise[T0_IO_NUM+2]),
        .io_fallen(io_in_fall[T0_IO_NUM+2]),
        .we(rw), .stb(t2_stb), .ack(t2_ack),
        .addr(mmio_addr[3:2]),
        .dtw(dwrite), .dtr(t2_dtr)
    );

    //===============================//
    // Wishbone Memory Mapped
    //===============================//

    wire dwb_stb, dwb_ack, wbs_dev_ack, dwb_irq;
    wire[31:0] dwb_dtr, wbs_dev_dtr;
    dev_wb wb(
        .clk(clk), .reset(rst),

        .wb_stb(wb_stb), .wb_we(wb_rw),
        .wb_dat_i(wbs_dat_i), .wb_adr(wbs_adr_i),
        .wb_ack(wbs_dev_ack),
        .wb_dat_o(wbs_dev_dtr),

        .stb(dwb_stb), .ack(dwb_ack),
        .we(rw), .dtr(dwb_dtr),
        .dtw(dwrite), .addr(mmio_addr[3:2]),

        .intrq(dwb_irq)
    );

    wire ext_stb, ext_ack, ext_irq;
    wire ext_dev_stb, ext_dev_ack;
    wire[31:0] ext_dtr, ext_dev_dtr;
    dev_wb ext(
        .clk(clk), .reset(rst),

        .wb_stb(ext_dev_stb),
        .wb_ack(ext_dev_ack),
        .wb_we(rw),
        .wb_dat_i(dwrite),
        .wb_adr(addr),
        .wb_dat_o(ext_dev_dtr),

        .stb(ext_stb), .ack(ext_ack),
        .we(rw), .dtr(ext_dtr),
        .dtw(dwrite), .addr(mmio_addr[3:2]),

        .intrq(ext_irq)
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
