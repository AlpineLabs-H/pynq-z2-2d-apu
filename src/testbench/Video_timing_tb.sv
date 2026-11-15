`timescale 1ns / 1ps

module Video_timing_tb;

    // -------------------------------------------------------------------------
    // 1. Test Parameters (Scaled down for fast simulation; matches 480p60 ratios)
    //    To run full 480p60, set H_ACTIVE=640, H_FP=16, H_SYNC=96, H_BP=48,
    //    V_ACTIVE=480, V_FP=10, V_SYNC=2, V_BP=33
    // -------------------------------------------------------------------------
    localparam int H_ACTIVE      = 16;
    localparam int H_FRONT_PORCH = 4;
    localparam int H_SYNC_WIDTH  = 6;
    localparam int H_BACK_PORCH  = 4;
    localparam bit H_SYNC_POL    = 1'b0; // Active Low

    localparam int V_ACTIVE      = 10;
    localparam int V_FRONT_PORCH = 2;
    localparam int V_SYNC_WIDTH  = 2;
    localparam int V_BACK_PORCH  = 3;
    localparam bit V_SYNC_POL    = 1'b0; // Active Low

    localparam int H_TOTAL = H_ACTIVE + H_FRONT_PORCH + H_SYNC_WIDTH + H_BACK_PORCH;
    localparam int V_TOTAL = V_ACTIVE + V_FRONT_PORCH + V_SYNC_WIDTH + V_BACK_PORCH;
    localparam int FRAME_CYCLES = H_TOTAL * V_TOTAL;

    // 25.175 MHz pixel clock (~39.72 ns period)
    localparam real CLK_PERIOD = 39.72;

    // -------------------------------------------------------------------------
    // 2. DUT Signals
    // -------------------------------------------------------------------------
    logic       clk_pixel;
    logic       rst_n;
    logic       hsync;
    logic       vsync;
    logic       de;
    logic [9:0] pixel_x;
    logic [9:0] pixel_y;
    logic       frame_start;

    int error_count = 0;

    // -------------------------------------------------------------------------
    // 3. Instantiate the Design Under Test (DUT)
    // -------------------------------------------------------------------------
    hdmi_timing_controller #(
        .H_ACTIVE      (H_ACTIVE),
        .H_FRONT_PORCH (H_FRONT_PORCH),
        .H_SYNC_WIDTH  (H_SYNC_WIDTH),
        .H_BACK_PORCH  (H_BACK_PORCH),
        .H_SYNC_POL    (H_SYNC_POL),
        .V_ACTIVE      (V_ACTIVE),
        .V_FRONT_PORCH (V_FRONT_PORCH),
        .V_SYNC_WIDTH  (V_SYNC_WIDTH),
        .V_BACK_PORCH  (V_BACK_PORCH),
        .V_SYNC_POL    (V_SYNC_POL)
    ) dut (
        .clk_pixel   (clk_pixel),
        .rst_n       (rst_n),
        .hsync       (hsync),
        .vsync       (vsync),
        .de          (de),
        .pixel_x     (pixel_x),
        .pixel_y     (pixel_y),
        .frame_start (frame_start)
    );

    // -------------------------------------------------------------------------
    // 4. Pixel Clock Generation
    // -------------------------------------------------------------------------
    initial begin
        clk_pixel = 1'b0;
        forever #(CLK_PERIOD / 2.0) clk_pixel = ~clk_pixel;
    end

    // -------------------------------------------------------------------------
    // 5. Reference Scoreboard & Cycle-by-Cycle Checker
    //    Note: DUT outputs are registered (1-cycle latency behind h_cnt/v_cnt)
    // -------------------------------------------------------------------------
    int ref_h = 0;
    int ref_v = 0;
    bit check_active = 0;

    always_ff @(posedge clk_pixel) begin
        if (!rst_n) begin
            ref_h        <= 0;
            ref_v        <= 0;
            check_active <= 1'b0;
        end else begin
            check_active <= 1'b1;

            // Advance reference raster counters matching DUT counters
            if (ref_h == H_TOTAL - 1) begin
                ref_h <= 0;
                if (ref_v == V_TOTAL - 1)
                    ref_v <= 0;
                else
                    ref_v <= ref_v + 1;
            end else begin
                ref_h <= ref_h + 1;
            end
        end
    end

    // Compare DUT outputs against reference model on every active clock edge
    always @(negedge clk_pixel) begin
        if (rst_n && check_active) begin
            // Previous cycle's ref_h / ref_v produced the current registered outputs
            int prev_h, prev_v;
            bit exp_hsync, exp_vsync, exp_de, exp_fstart;
            logic [9:0] exp_x, exp_y;

            prev_h = (ref_h == 0) ? (H_TOTAL - 1) : (ref_h - 1);
            prev_v = (ref_h == 0) ? ((ref_v == 0) ? (V_TOTAL - 1) : (ref_v - 1)) : ref_v;

            exp_hsync  = (prev_h >= (H_ACTIVE + H_FRONT_PORCH) && 
                          prev_h <  (H_ACTIVE + H_FRONT_PORCH + H_SYNC_WIDTH)) ? H_SYNC_POL : ~H_SYNC_POL;
            exp_vsync  = (prev_v >= (V_ACTIVE + V_FRONT_PORCH) && 
                          prev_v <  (V_ACTIVE + V_FRONT_PORCH + V_SYNC_WIDTH)) ? V_SYNC_POL : ~V_SYNC_POL;
            exp_de     = (prev_h < H_ACTIVE) && (prev_v < V_ACTIVE);
            exp_x      = exp_de ? prev_h[9:0] : 10'd0;
            exp_y      = exp_de ? prev_v[9:0] : 10'd0;
            exp_fstart = (prev_h == 0) && (prev_v == 0);

            if (hsync !== exp_hsync) begin
                $error("[%0t] HSYNC mismatch at (H=%0d, V=%0d): got %b, expected %b", $time, prev_h, prev_v, hsync, exp_hsync);
                error_count++;
            end
            if (vsync !== exp_vsync) begin
                $error("[%0t] VSYNC mismatch at (H=%0d, V=%0d): got %b, expected %b", $time, prev_h, prev_v, vsync, exp_vsync);
                error_count++;
            end
            if (de !== exp_de) begin
                $error("[%0t] DE mismatch at (H=%0d, V=%0d): got %b, expected %b", $time, prev_h, prev_v, de, exp_de);
                error_count++;
            end
            if (pixel_x !== exp_x || pixel_y !== exp_y) begin
                $error("[%0t] Coord mismatch at (H=%0d, V=%0d): got (%0d,%0d), expected (%0d,%0d)", 
                       $time, prev_h, prev_v, pixel_x, pixel_y, exp_x, exp_y);
                error_count++;
            end
            if (frame_start !== exp_fstart) begin
                $error("[%0t] FRAME_START mismatch at (H=%0d, V=%0d): got %b, expected %b", 
                       $time, prev_h, prev_v, frame_start, exp_fstart);
                error_count++;
            end
        end
    end

    // -------------------------------------------------------------------------
    // 6. SystemVerilog Assertions (Protocol Rules)
    // -------------------------------------------------------------------------
    // Rule 1: Data Enable must never be active during HSYNC or VSYNC
    property p_no_de_during_sync;
        @(posedge clk_pixel) disable iff (!rst_n)
        de |-> (hsync == ~H_SYNC_POL) && (vsync == ~V_SYNC_POL);
    endproperty
    assert property (p_no_de_during_sync)
        else begin $error("[%0t] SVA FAIL: DE asserted during sync pulse!", $time); error_count++; end

    // Rule 2: Coordinates must stay clamped to (0,0) whenever DE is low
    property p_coords_zero_when_blanking;
        @(posedge clk_pixel) disable iff (!rst_n)
        !de |-> (pixel_x == 10'd0) && (pixel_y == 10'd0);
    endproperty
    assert property (p_coords_zero_when_blanking)
        else begin $error("[%0t] SVA FAIL: Coordinates non-zero during blanking!", $time); error_count++; end

    // Rule 3: frame_start must only be a single-cycle pulse
    property p_frame_start_single_cycle;
        @(posedge clk_pixel) disable iff (!rst_n)
        frame_start |=> !frame_start;
    endproperty
    assert property (p_frame_start_single_cycle)
        else begin $error("[%0t] SVA FAIL: frame_start lasted more than 1 cycle!", $time); error_count++; end

    // -------------------------------------------------------------------------
    // 7. Main Test Stimulus Sequence
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("hdmi_timing.vcd");
        $dumpvars(0, Video_timing_tb);

        // Apply synchronous reset
        rst_n = 1'b0;
        repeat (5) @(posedge clk_pixel);
        
        // Verify reset state
        #1;
        assert (hsync == ~H_SYNC_POL && vsync == ~V_SYNC_POL && de == 1'b0)
            else begin $error("Reset state incorrect!"); error_count++; end

        // Release reset and run for 2.5 full video frames
        @(posedge clk_pixel);
        rst_n <= 1'b1;
        $display("[%0t] Reset released. Simulating 2.5 frames (%0d cycles/frame)...", $time, FRAME_CYCLES);

        repeat (FRAME_CYCLES * 2 + (FRAME_CYCLES / 2)) @(posedge clk_pixel);

        // Test mid-frame synchronous reset recovery
        $display("[%0t] Testing mid-frame synchronous reset...", $time);
        rst_n <= 1'b0;
        repeat (3) @(posedge clk_pixel);
        rst_n <= 1'b1;

        // Run 1 more full frame after reset recovery
        repeat (FRAME_CYCLES) @(posedge clk_pixel);

        // Final Test Summary
        if (error_count == 0)
            $display("\n=== TEST PASSED: 0 errors across all frames! ===\n");
        else
            $fatal(1, "\n=== TEST FAILED: %0d errors detected! ===\n", error_count);

        $finish;
    end

endmodule
