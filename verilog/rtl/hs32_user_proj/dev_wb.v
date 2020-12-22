module dev_wb (
    input wire clk,
    input wire reset,

    // Wishbone input
    input wire wb_stb,
    input wire wb_we,
    input wire[31:0] wb_dat_i,
    input wire[31:0] wb_adr,
    
    output wire wb_ack,
    output wire[31:0] wb_dat_o,

    // Memory bus
    input wire stb,
    output wire ack,
    input wire we,
    output reg[31:0] dtr,
    input wire[31:0] dtw,
    input wire[1:0] addr,

    // Interrupt output
    output wire intrq
);
    reg[31:0] r_adr, r_dtw, r_dtr;
    reg r_we, r_wb_ack;
    reg[1:0] r_cfg;
    assign wb_dat_o = r_dtr;
    assign wb_ack = r_cfg[1] ? r_cfg[0] : r_wb_ack;
    assign intrq = wb_stb;
    
    // Stores incoming wb req (drives: r_dtw, r_adr, r_wb_ack)
    always @(posedge clk) if(reset) begin
        r_dtw <= 0;
        r_adr <= 0;
        r_wb_ack <= 0;
    end else begin
        if(wb_stb) begin
            r_wb_ack <= 1;
            r_we <= wb_we;
            r_dtw <= wb_dat_i;
            r_adr <= wb_adr;
        end else if(r_wb_ack) begin
            r_wb_ack <= 0;
        end
    end

    // Accept writes to register (drives: r_dtr)
    assign ack = 1;
    always @(posedge clk) if(reset) begin
        r_dtr <= 0;
        r_cfg <= 0;
    end else begin
        if(we && stb) case(addr)
            2: r_dtr <= dtw;
            3: r_cfg <= dtw[1:0];
            default: begin end
        endcase else if(r_cfg[0]) begin
            r_cfg[0] <= 0;
        end
    end

    // Read
    always @(*) case(addr)
        0: dtr = r_adr;
        1: dtr = r_dtw;
        2: dtr = r_dtr;
        3: dtr = { 29'b0, r_we, r_cfg };
        default: dtr = 0; // Paranoid default
    endcase
endmodule
