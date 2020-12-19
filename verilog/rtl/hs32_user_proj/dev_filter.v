// TODO: Hahaha too lazy to do it
module dev_filter (
    input wire clk,
    input wire rst,
    input wire a,
    output wire b,
    output reg rise,
    output reg fall
);
    reg[1:0] sync;
    assign b = sync[1];

    always @(posedge clk) if(rst) begin
        sync <= 0;
    end else begin
        sync <= { sync[0], a };
    end
    
    always @(posedge clk) if(rst) begin
        rise <= 0;
        fall <= 0;
    end else begin
        rise <= sync == 2'b01;
        fall <= sync == 2'b10;
    end
endmodule