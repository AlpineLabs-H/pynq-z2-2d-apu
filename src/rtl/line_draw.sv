`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/13/2026 02:30:58 PM
// Design Name: 
// Module Name: line_draw
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


module line_draw(
    input  logic        clk,        //100mhz
    input  logic        rst,
    input  logic        start,      //pulse from draw_ctrl to begin fill
    input  logic [8:0]  x0, x1,     //top left/right corner in framebuffer coordinates
    input  logic [7:0]  y0, y1,     //top left corner in framebuffer coordinates
    input  logic [5:0]  color,
    output logic        busy,       //High while a fill is in progress
    output logic        done,       //One-cycle pulse when the fill completes
    output logic        wr_en,
    output logic [16:0] wr_addr,
    output logic [5:0]  wr_data
    );
    typedef enum logic [1:0] {
        IDLE = 2'b00,
        FILL = 2'b01,
        DONE = 2'b10
    } state_t;

    
    //Internal stignals
    logic [8:0]  cur_x;
    logic [7:0]  cur_y;
    logic [8:0] x1_lat;
    logic [7:0] y1_lat;
    logic [5:0] color_lat;
    logic signed [9:0] dx;
    logic signed [9:0] dy;
    logic signed [1:0] sx;
    logic signed [1:0] sy;
    logic signed [10:0] err;
    logic signed [10:0] err2;
    state_t state, next_state;

    //FSM state register
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    //Next-state + output logic
    always_comb begin
        next_state = state;
        busy  = 1'b0;
        done  = 1'b0;
        wr_en = 1'b0;
        case (state)
            IDLE: begin
                if (start) begin
                    next_state = FILL;
                end
            end
            FILL: begin
                busy  = 1'b1;
                wr_en = 1'b1;
                if (cur_x == x1_lat && cur_y == y1_lat) begin
                    next_state = DONE;
                end
            end
            DONE: begin
                done = 1'b1;
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    //Input latch (normalized corners)
    always_ff @(posedge clk) begin
        if (rst) begin
            x1_lat    <= 9'd0;
            y1_lat    <= 8'd0;
            color_lat <= 6'd0;
        end else if (state == IDLE && start) begin
            x1_lat    <= x1;
            y1_lat    <= y1;
            color_lat <= color;
        end
    end

    //Datapath
    always_ff @(posedge clk) begin
        if (rst) begin
            cur_x <= 9'd0;
            cur_y <= 8'd0;
            dx    <= 10'd0;
            dy    <= 10'd0;
            sx    <= 2'd0;
            sy    <= 2'd0;
            err   <= 11'd0;
        end else if(state == IDLE && start) begin
            cur_x <= x0;
            cur_y <= y0;
            dx <= (x1 >= x0) ? (x1 - x0) : (x0 - x1);
            dy <= (y1 >= y0) ? -(y1-y0) : -(y0-y1);
            sx <= (x0 < x1) ? 2'sd1 : -2'sd1;
            sy <= (y0 < y1) ? 2'sd1 : -2'sd1;
            err   <= dx + dy;
        end else if(state == FILL) begin
            if (err2 >= dy && err2 <= dx) begin
                err   <= err + dy + dx;
                cur_x <= cur_x + sx;
                cur_y <= cur_y + sy;
            end else if (err2 >= dy) begin
                err   <= err + dy;
                cur_x <= cur_x + sx;
            end else if (err2 <= dx) begin
                err   <= err + dx;
                cur_y <= cur_y + sy;
            end
        end
    end
    assign wr_data = color_lat;
    assign err2 = err <<< 1;
    assign wr_addr = ({9'd0, cur_y} * 17'd320) + {8'd0, cur_x};
endmodule
