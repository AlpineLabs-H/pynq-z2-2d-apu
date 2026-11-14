`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/13/2026 02:30:58 PM
// Design Name: 
// Module Name: curve_draw
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module curve_draw(
    input logic clk,
    input logic rst,
    input logic start,
    input logic [8:0] cx, cy,
    input logic [8:0] radius,
    input logic [5:0] color
    );
    
    //latches for stablity
    logic [8:0] cx_lat, cy_lat;
    logic [8:0] randius_lat;
    logic [6:0] color_lat;

    logic [8:0] x,y;
    logic signed [11:0] err;
    logic [3:0] octant_cnt;

    always_ff @(posedge clk) begin
        
    end

    
endmodule
