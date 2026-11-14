`timescale 1ns / 1ps

module rect_fill(
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

//Internal states
state_t state, next_state;
logic [8:0]  cur_x;
logic [7:0]  cur_y;
logic [16:0] row_base;

//Latches
logic [8:0] x0_lat, x1_lat;
logic [7:0] y0_lat, y1_lat;
logic [5:0] color_lat;

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
        x0_lat    <= 9'd0;
        y1_lat    <= 8'd0;
        y0_lat    <= 8'd0;
        color_lat <= 6'd0;
    end else if (state == IDLE && start) begin
        x0_lat    <= (x0 <= x1) ? x0 : x1;
        x1_lat    <= (x0 <= x1) ? x1 : x0;
        y0_lat    <= (y0 <= y1) ? y0 : y1;
        y1_lat    <= (y0 <= y1) ? y1 : y0;
        color_lat <= color;
    end
end

//Datapath: cur_x, cur_y, row_base
always_ff @(posedge clk) begin
    if (rst) begin
        cur_x    <= 9'd0;
        cur_y    <= 8'd0;
        row_base <= 17'd0;
    end else if (state == IDLE && start) begin
        cur_x    <= (x0 <= x1) ? x0 : x1;
        cur_y    <= (y0 <= y1) ? y0 : y1;
        row_base <= {8'd0, ((y0 <= y1) ? y0 : y1)} * 17'd320;
    end else if (state == FILL) begin
        if (cur_x == x1_lat) begin
            cur_x    <= x0_lat;
            cur_y    <= cur_y + 8'd1;
            row_base <= row_base + 17'd320;
        end else begin
            cur_x <= cur_x + 9'd1;
        end
    end
end

assign wr_addr = row_base + {8'd0, cur_x};
assign wr_data = color_lat;

endmodule