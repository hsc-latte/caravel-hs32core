module dev_timer (
    input   wire clk,
    input   wire reset,

    // Config
    input   wire[2:0] clk_source,
    input   wire[1:0] timer_mode,
    input   wire[1:0] output_mode,

    // Registers
    input   wire[TIMER_BITS-1:0] match,

    // Outputs
    output  reg  int_match,
    output  wire io,

    // Pulse for 1T if I/O risen/fallen
    input wire io_risen,
    input wire io_fallen
);
    parameter TIMER_BITS = 16;

`define TIMER_MODE_CTC      1
`define TIMER_MODE_SPWM     2 // Single edge PWM
`define TIMER_MODE_DPWM     3 // Dual edge PWM (rise/fall)
`define TIMER_OUTPUT_TOGGLE 1
`define TIMER_OUTPUT_INV    3

    reg[TIMER_BITS-1:0] counter;
    reg[9:0] divider;
    reg direction; // 1 is ++

    wire scale_clk =
        clk_source == 1 ? 1 :
        clk_source == 2 ? divider[2] : // scale clk 8
        clk_source == 3 ? divider[5] : // scale clk 64
        clk_source == 4 ? divider[7] : // scale clk 256
        clk_source == 5 ? divider[9] : // scale clk 1024
        clk_source == 6 ? io_risen :
        clk_source == 7 ? io_fallen : 0;
    wire timer_match = match == counter;
    wire timer_ovf = & counter;

    reg io_normal, io_spwm, io_dpwm;
    wire io_output =
        timer_mode == `TIMER_MODE_SPWM ? io_spwm :
        timer_mode == `TIMER_MODE_DPWM ? io_dpwm : io_normal;
    assign io = output_mode == `TIMER_OUTPUT_INV ? ~io_output : io_output;
    
    // Clock divider, drives: divider
    always @(posedge clk) if(reset) begin
        divider <= 0;
    end else begin
        divider <= divider + 1;
    end

    // Counter, drives: counter
    always @(posedge clk) if(reset) begin
        counter <= 0;
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
    always @(posedge clk) if(reset) begin
        direction <= 1;
    end else if(scale_clk) begin
        if(timer_ovf && timer_mode == `TIMER_MODE_DPWM) begin
            direction <= ~direction;
        end else if(counter == 1) begin
            direction <= 1;
        end
    end

    // Timer output, drives: io_normal
    always @(posedge clk) if(reset) begin
        io_normal <= 0;
    end else begin
        if(timer_match) begin
            io_normal <= output_mode == `TIMER_OUTPUT_TOGGLE ? ~io_normal : 1;
        end
    end

    // Timer output, drives: io_spwm
    always @(posedge clk) if(reset) begin
        io_spwm <= 0;
    end else begin
        if(timer_match) begin
            io_spwm <= 1;
        end else if(timer_ovf) begin
            io_spwm <= 0;
        end
    end

    // Timer output, drives: io_dpwm
    always @(posedge clk) if(reset) begin
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
endmodule