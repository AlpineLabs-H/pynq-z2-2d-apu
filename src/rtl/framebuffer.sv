`timescale 1ns / 1ps

module framebuffer(
    input  logic        clk,      // 100 MHz clock
    input  logic        wr_en,    // write enable, from draw_ctrl
    input  logic [16:0] wr_addr,  // write address, from draw_ctrl
    input  logic [5:0]  wr_data,  // color to write, from draw_ctrl
    input  logic [16:0] rd_addr,  // read address, from vga_out address-gen
    output logic [5:0]  rd_data   // color read out, 1-cycle latency
    );
    
    logic [5:0] mem [0:76799];  // 320x240 @ 6 bits/pixel
    
    always_ff @(posedge clk) begin
        if (wr_en) mem[wr_addr] <= wr_data;
    end
    
    always_ff @(posedge clk) begin
        rd_data <= mem[rd_addr];
    end

endmodule