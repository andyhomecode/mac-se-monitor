// filepath: /hdmi_to_mac_se_converter_project/hdmi_to_mac_se_converter_project/src/mac_se_timing_generator.v
//////////////////////////////////////////////////////////////////////////////////
// Module: mac_se_timing_generator
// Description:
// This module generates the timing signals (horizontal sync, vertical sync, and
// active signals) required for the Mac SE display based on the input clock.
// The timing parameters are derived from the specifications for the Mac SE display.
//////////////////////////////////////////////////////////////////////////////////

module mac_se_timing_generator (
    input wire clk_in, // Should be the target Mac SE pixel clock freq (e.g., 15.6672 MHz)
    input wire reset,
    output wire pixel_clk,
    output reg hsync,
    output reg vsync,
    output wire active,
    output wire [9:0] x_coord, // Needs H_BITS width
    output wire [9:0] y_coord  // Needs V_BITS width
);

    // --- Mac SE Timing Parameters ---
    parameter H_DISPLAY = 512; // Active video pixels (Standard Mac SE)
    parameter H_FRONT   = 16;  // Best Guess Front porch
    parameter H_SYNC    = 64;  // Best Guess Sync pulse width --> VERIFY THIS!
    parameter H_BACK    = 112; // Best Guess Back porch (Derived from H_SYNC guess + PDF delay)
    parameter H_TOTAL   = 704; // Total clocks per line (512+16+64+112 = 704)

    parameter V_DISPLAY = 342; // Active video lines (Standard Mac SE)
    parameter V_FRONT   = 0;   // Front porch (Calculated)
    parameter V_SYNC    = 4;   // Sync pulse lines (Calculated)
    parameter V_BACK    = 24;  // Back porch (Calculated)
    parameter V_TOTAL   = 370; // Total lines per frame (Calculated)

    localparam H_BITS = $clog2(H_TOTAL); // e.g., $clog2(704) = 10
    localparam V_BITS = $clog2(V_TOTAL); // e.g., $clog2(370) = 9
    reg [H_BITS-1:0] h_counter = 0; // Horizontal counter
    reg [V_BITS-1:0] v_counter = 0; // Vertical counter

    assign pixel_clk = clk_in;

    // Horizontal and Vertical Counters
    always @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            h_counter <= 0;
            v_counter <= 0;
        end else begin
            if (h_counter < H_TOTAL - 1) begin
                h_counter <= h_counter + 1;
            end else begin
                h_counter <= 0;
                if (v_counter < V_TOTAL - 1) begin
                    v_counter <= v_counter + 1;
                end else begin
                    v_counter <= 0;
                end
            end
        end
    end

    // HSYNC and VSYNC Generation (Active Low)
    always @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            hsync <= 1'b1; // Active high
            vsync <= 1'b1; // Active high
        end else begin
            hsync <= (h_counter < H_SYNC) ? 1'b0 : 1'b1; // Active low during sync pulse
            vsync <= (v_counter < V_SYNC) ? 1'b0 : 1'b1; // Active low during sync pulse
        end
    end

    // Active signal generation
    assign active = (h_counter < H_DISPLAY) && (v_counter < V_DISPLAY);
    assign x_coord = h_counter;
    assign y_coord = v_counter;

endmodule // mac_se_timing_generator