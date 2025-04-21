// rewrote from scratch after looking at more Mac SE specs
// 4/20/2025
// Andy Maxwell

module mac_se_timing_generator (
    input wire clk,         // Pixel clock input (e.g., 15.6672 MHz)
    input wire rst_n,       // Asynchronous reset, active low

    output reg hsync,       // Horizontal Sync output (active low)
    output reg vsync,       // Vertical Sync output (active low)
    output reg active,      // Active display area (high when active)
    output reg [9:0] pixel_x,   // Horizontal pixel coordinate (0-511 when active)
    output reg [8:0] pixel_y    // Vertical pixel coordinate (0-341 when active)
);

    // Timing Parameters (Based on Standard Mac SE Specs)
    // Horizontal Timing (704 clocks total)
    parameter H_TOTAL         = 704;
    parameter H_SYNC_PULSE    = 75;   // Duration HSYNC is low
    parameter H_BACK_PORCH    = 86;   // Blanking after HSYNC pulse
    parameter H_ACTIVE        = 512;  // Active pixel data
    parameter H_FRONT_PORCH   = 31;   // Blanking before next HSYNC

    // Calculated Horizontal Points (relative to start of line, HSYNC fall = 0)
    parameter H_SYNC_END      = H_SYNC_PULSE;                     // 75
    parameter H_ACTIVE_START  = H_SYNC_PULSE + H_BACK_PORCH;      // 75 + 86 = 161
    parameter H_ACTIVE_END    = H_ACTIVE_START + H_ACTIVE - 1;    // 161 + 512 - 1 = 672

    // Vertical Timing (370 lines total)
    parameter V_TOTAL           = 370;
    parameter V_SYNC_PULSE_LINES= 4;    // Number of lines VSYNC is low (~2820 clocks / 704 clk/line)
    parameter V_BLANK_LINES     = 28;   // Total vertical blanking lines (incl VSYNC pulse)
    parameter V_ACTIVE_LINES    = 342;  // Active display lines

    // Calculated Vertical Points (relative to start of frame, VSYNC fall = line 0)
    parameter V_SYNC_END_LINE   = V_SYNC_PULSE_LINES - 1;         // Line 3
    parameter V_ACTIVE_START_LINE = V_BLANK_LINES;                // Line 28
    parameter V_ACTIVE_END_LINE = V_ACTIVE_START_LINE + V_ACTIVE_LINES - 1; // 28 + 342 - 1 = 369

    // Internal Counters
    reg [9:0] h_count = 0; // Horizontal counter (0 to H_TOTAL - 1) -> 0 to 703 (needs 10 bits)
    reg [8:0] v_count = 0; // Vertical counter   (0 to V_TOTAL - 1) -> 0 to 369 (needs 9 bits)

    // Internal flags for clarity (optional)
    wire h_is_active;
    wire v_is_active;

// Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset state
            h_count <= 0;
            v_count <= 0;
            hsync   <= 1'b1; // Inactive high
            vsync   <= 1'b1; // Inactive high
            active  <= 1'b0; // Inactive low
            pixel_x <= 0;
            pixel_y <= 0;
        end else begin
            // --- Counters ---
            if (h_count == H_TOTAL - 1) begin
                h_count <= 0;
                if (v_count == V_TOTAL - 1) begin
                    v_count <= 0; // Frame wrap around
                end else begin
                    v_count <= v_count + 1; // Increment line counter
                end
            end else begin
                h_count <= h_count + 1; // Increment horizontal counter
            end

            // --- Output Generation ---
            // HSYNC: Active low during the first H_SYNC_PULSE clocks of the line
            if (h_count < H_SYNC_PULSE) begin
                hsync <= 1'b0; // Active
            end else begin
                hsync <= 1'b1; // Inactive
            end

            // VSYNC: Active low during the first V_SYNC_PULSE_LINES lines of the frame
            if (v_count <= V_SYNC_END_LINE) begin
                vsync <= 1'b0; // Active
            end else begin
                vsync <= 1'b1; // Inactive
            end

            // ACTIVE: High only when both H and V counters are in the active display region
            // Calculate active condition directly within the if statement
            if ((h_count >= H_ACTIVE_START) && (h_count <= H_ACTIVE_END) &&
                (v_count >= V_ACTIVE_START_LINE) && (v_count <= V_ACTIVE_END_LINE)) begin
                active <= 1'b1;
            end // ***** ADDED 'end' HERE *****
            else begin
                active <= 1'b0;
            end

            // Pixel Coordinates: Output 0-based coordinates *only* during active region
            // Use the same combined condition directly
            if ((h_count >= H_ACTIVE_START) && (h_count <= H_ACTIVE_END) &&
                (v_count >= V_ACTIVE_START_LINE) && (v_count <= V_ACTIVE_END_LINE)) begin
                pixel_x <= h_count - H_ACTIVE_START;
                pixel_y <= v_count - V_ACTIVE_START_LINE;
            end // ***** ADDED 'end' HERE *****
            else begin
                // Optionally clear coordinates during blanking
                pixel_x <= 0;
                pixel_y <= 0;
            end
        end
    end

endmodule