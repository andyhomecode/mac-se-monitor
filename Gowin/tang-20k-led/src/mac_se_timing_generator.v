// rewrote from scratch after looking at more Mac SE specs
// 4/20/2025 -> Updated with Classic II diagram timings 4/21/2025
// Andy Maxwell


module mac_se_timing_generator (
    input wire clk,         // Pixel clock input (e.g., 15.6672 MHz)

    output reg hsync,       // Horizontal Sync output (active low)
    output reg vsync,       // Vertical Sync output (active low)
    output reg active,      // Active display area (high when active)
    output reg [9:0] pixel_x,   // Horizontal pixel coordinate (0-511 when active)
    output reg [8:0] pixel_y,   // Vertical pixel coordinate (0-341 when active)
    output reg [17:0] pixel     // Pixel counter (counts every pixel in the frame)
);

    // Timing Parameters (Based on Standard Mac Specs / Classic II Diagram)
    parameter H_TOTAL         = 704;
    parameter H_SYNC_PULSE    = 228;
    parameter H_ACTIVE        = 512;
    parameter H_FRONT_PORCH   = 14;

    parameter H_SYNC_END      = H_SYNC_PULSE;
    parameter H_ACTIVE_START  = 192;
    parameter H_ACTIVE_END    = H_ACTIVE_START + H_ACTIVE - 1;

    parameter V_TOTAL           = 370;
    parameter V_SYNC_PULSE_LINES= 4;
    parameter V_BLANK_LINES     = 28;
    parameter V_ACTIVE_LINES    = 342;

    parameter V_SYNC_END_LINE   = V_SYNC_PULSE_LINES - 1;
    parameter V_ACTIVE_START_LINE = V_BLANK_LINES;
    parameter V_ACTIVE_END_LINE = V_ACTIVE_START_LINE + V_ACTIVE_LINES - 1;

    // Internal Counters
    reg [9:0] h_count = 0; // Horizontal counter (0 to H_TOTAL - 1)
    reg [8:0] v_count = 0; // Vertical counter   (0 to V_TOTAL - 1)
    reg [17:0] pixel_counter = 0; // Internal Pixel Counter

    // Logic
    always @(posedge clk) begin
        // --- Counters ---
        if (h_count == H_TOTAL - 1) begin
            h_count <= 0;
            if (v_count == V_TOTAL - 1) begin
                v_count <= 0; // Frame wrap around
                pixel_counter <= 0; // Reset pixel counter at the top of the frame
            end else begin
                v_count <= v_count + 1; // Increment line counter
            end
        end else begin
            h_count <= h_count + 1; // Increment horizontal counter
        end

        // --- Output Generation ---
        // HSYNC: High during front porch, low during sync pulse and back porch
        hsync <= (h_count < H_FRONT_PORCH || h_count >= H_FRONT_PORCH + H_SYNC_PULSE) ? 1'b1 : 1'b0;


        // VSYNC: Active low during the first V_SYNC_PULSE_LINES lines of the frame
        vsync <= (v_count <= V_SYNC_END_LINE) ? 1'b0 : 1'b1;

        // ACTIVE: High only when both H and V counters are in the active display region
        active <= (h_count >= H_ACTIVE_START && h_count <= H_ACTIVE_END &&
                   v_count >= V_ACTIVE_START_LINE && v_count <= V_ACTIVE_END_LINE);

        // Pixel Coordinates: Output 0-based coordinates only during active region
        if (active) begin
            pixel_x <= h_count - H_ACTIVE_START;
            pixel_y <= v_count - V_ACTIVE_START_LINE;
            pixel_counter <= pixel_counter + 1; // Increment pixel counter
        end else begin
            pixel_x <= 0;
            pixel_y <= 0;
        end

        pixel <= pixel_counter; // Assign pixel counter to output
    end

endmodule