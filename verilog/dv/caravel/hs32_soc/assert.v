module assert(input wire clk, input wire test);
    always @(posedge clk)
    begin
        if (test !== 1)
        begin
            $display("%c[1;31mAssertation failed in %m %c[0m", 27, 27);
            $finish_and_return(1);
        end
    end
endmodule