module hdmi_timing_controller #(
    // Horizontal timing parameters (pixels) - Default 480p60
    parameter int H_ACTIVE      = 640,
    parameter int H_FRONT_PORCH = 16,
    parameter int H_SYNC_WIDTH  = 96,
    parameter int H_BACK_PORCH  = 48,
    parameter bit H_SYNC_POL    = 1'b0, 

    // Vertical timing parameters (lines) - Default 480p60
    parameter int V_ACTIVE      = 480,
    parameter int V_FRONT_PORCH = 10,
    parameter int V_SYNC_WIDTH  = 2,
    parameter int V_BACK_PORCH  = 33,
    parameter bit V_SYNC_POL    = 1'b0  // 1 = Active High, 0 = Active Low
) (
    input  logic        clk_pixel,   
    input  logic        rst_n,       // Active-low synchronous reset

    output logic        hsync,       // Horizontal sync
    output logic        vsync,       // Vertical sync
    output logic        de,          // Data Enable (active video region)
    output logic [9:0] pixel_x,     // Current active X coordinate
    output logic [9:0] pixel_y,     // Current active Y coordinate
    output logic        frame_start  // Single-cycle pulse at start of frame
);

    localparam int H_TOTAL = H_ACTIVE + H_FRONT_PORCH + H_SYNC_WIDTH + H_BACK_PORCH;
    localparam int V_TOTAL = V_ACTIVE + V_FRONT_PORCH + V_SYNC_WIDTH + V_BACK_PORCH;

    localparam int H_SYNC_START = H_ACTIVE + H_FRONT_PORCH;
    localparam int H_SYNC_END   = H_SYNC_START + H_SYNC_WIDTH;

    localparam int V_SYNC_START = V_ACTIVE + V_FRONT_PORCH;
    localparam int V_SYNC_END   = V_SYNC_START + V_SYNC_WIDTH;

    logic [$clog2(H_TOTAL)-1:0] h_cnt;
    logic [$clog2(V_TOTAL)-1:0] v_cnt;

    // Horizontal and Vertical Raster Counters
    always_ff @(posedge clk_pixel) begin
        if (!rst_n) begin
            h_cnt <= '0;
            v_cnt <= '0;
        end else begin
            if (h_cnt == H_TOTAL - 1) begin
                h_cnt <= '0;
                if (v_cnt == V_TOTAL - 1) begin
                    v_cnt <= '0;
                end else begin
                    v_cnt <= v_cnt + 1'b1;
                end
            end else begin
                h_cnt <= h_cnt + 1'b1;
            end
        end
    end

    // Registered Control and Coordinate Outputs
    always_ff @(posedge clk_pixel) begin
        if (!rst_n) begin
            hsync       <= ~H_SYNC_POL;
            vsync       <= ~V_SYNC_POL;
            de          <= 1'b0;
            pixel_x     <= '0;
            pixel_y     <= '0;
            frame_start <= 1'b0;
        end else begin
            // Generate sync pulses with configurable polarity
            hsync <= (h_cnt >= H_SYNC_START && h_cnt < H_SYNC_END) ? H_SYNC_POL : ~H_SYNC_POL;
            vsync <= (v_cnt >= V_SYNC_START && v_cnt < V_SYNC_END) ? V_SYNC_POL : ~V_SYNC_POL;

            // Active display region
            de <= (h_cnt < H_ACTIVE) && (v_cnt < V_ACTIVE);

            // Coordinates (clamped to 0 during blanking)
            pixel_x <= (h_cnt < H_ACTIVE) ? 12'(h_cnt) : 12'd0;
            pixel_y <= (v_cnt < V_ACTIVE) ? 12'(v_cnt) : 12'd0;

            // Useful trigger for updating framebuffers or game logic
            frame_start <= (h_cnt == 0) && (h_cnt == 0);
        end
    end

endmodule
