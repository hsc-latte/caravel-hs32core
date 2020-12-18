module hs32_timer(
    input   wire clk,
    input   wire reset,

    // Config
    input   wire[2:0] clk_source,
    input   wire[1:0] timer_mode,
    input   wire[1:0] output_mode,

    // Registers
    input   wire[31:0] match,

    // Outputs
    output  wire int_match,
    output  wire io
);
    reg[31:0] counter;
    reg[9:0] divider;

    wire scale_clk8 = divider[2];
    wire scale_clk64 = divider[5];
    wire scale_clk256 = divider[7];
    wire scale_clk1024 = divider[9];
    
    always @(posedge clk) if(reset) begin
        divider <= 0;
    end else begin
        divider <= divider + 1;
    end

    always @(posedge clk) if(reset) begin
        counter <= 0;
    end else begin
        
    end
endmodule