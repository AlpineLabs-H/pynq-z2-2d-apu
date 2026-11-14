`timescale 1ns / 1ps

module vga_out(
    input  logic        clk,        // 100 MHz clock
    input  logic        rst,
    input  logic [9:0]  pixel_x,    // from vga_timing, 0-799 (640 visible)
    input  logic [9:0]  pixel_y,    // from vga_timing, 0-524 (480 visible)
    input  logic        blank,      // from vga_timing
    input  logic        h_sync_in,  // from vga_timing
    input  logic        v_sync_in,  // from vga_timing
    input  logic [5:0]  rd_data,    // from framebuffer, 1-cycle delayed
    output logic [16:0] rd_addr,    // to framebuffer
    output logic [1:0]  vgaRed,
    output logic [1:0]  vgaGreen,
    output logic [1:0]  vgaBlue,
    output logic        Hsync,
    output logic        Vsync
);

    // ---- Stage 0: address generation (pixel-doubling 640x480 -> 320x240) ----
    logic [8:0] fb_x;      // 0-319
    logic [7:0] fb_y;      // 0-239
    logic [7:0] fb_y_prev;
    logic [16:0] row_base;

    assign fb_x = pixel_x[9:1];  // divide by 2
    assign fb_y = pixel_y[9:1];  // divide by 2

    always_ff @(posedge clk) begin
        if (rst) begin
            row_base  <= 17'd0;
            fb_y_prev <= 8'd0;
        end else if (pixel_x == 10'd0 && pixel_y == 10'd0) begin
            // start of frame - reset row base
            row_base  <= 17'd0;
            fb_y_prev <= 8'd0;
        end else if (fb_y != fb_y_prev) begin
            // crossed into a new framebuffer row (every 2 lines)
            row_base  <= row_base + 17'd320;
            fb_y_prev <= fb_y;
        end
    end

    assign rd_addr = row_base + {8'd0, fb_x};

    // ---- Stage 1: delay blank/sync by 1 cycle to match BRAM read latency ----
    logic blank_d1, h_sync_d1, v_sync_d1;

    always_ff @(posedge clk) begin
        if (rst) begin
            blank_d1  <= 1'b1;
            h_sync_d1 <= 1'b1;
            v_sync_d1 <= 1'b1;
        end else begin
            blank_d1  <= blank;
            h_sync_d1 <= h_sync_in;
            v_sync_d1 <= v_sync_in;
        end
    end

    // ---- Stage 2: combinational blank-forcing mux ----
    logic [5:0] color_pre;
    assign color_pre = blank_d1 ? 6'b0 : rd_data;

    // ---- Stage 3: output-stabilizing register ----
    always_ff @(posedge clk) begin
        if (rst) begin
            Hsync    <= 1'b1;
            Vsync    <= 1'b1;
            vgaRed   <= 2'b0;
            vgaGreen <= 2'b0;
            vgaBlue  <= 2'b0;
        end else begin
            Hsync    <= h_sync_d1;
            Vsync    <= v_sync_d1;
            vgaRed   <= color_pre[5:4];
            vgaGreen <= color_pre[3:2];
            vgaBlue  <= color_pre[1:0];
        end
    end

endmodule