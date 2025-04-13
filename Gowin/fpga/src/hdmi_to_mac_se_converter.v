// filepath: /hdmi_to_mac_se_converter_project/hdmi_to_mac_se_converter_project/src/hdmi_to_mac_se_converter.v
//////////////////////////////////////////////////////////////////////////////////
// Module: hdmi_to_mac_se_converter (Top Level Skeleton - TFP401 Input)
// Version: 8 (Buffer Write Test Mode Added)
//
// Description:
// Top-level module skeleton for converting HDMI input (decoded by TFP401,
// e.g., outputting 800x600 digital video) to Mac SE CRT output format
// (512x342 @ ~60.1Hz).
// Architecture: Scaling occurs *before* the frame buffer. Frame buffer is sized
//               for the output resolution (512x342) and primarily handles CDC.
// Includes a test mode (test_mode_switch=1) that writes a pattern directly
// into the frame buffer using the output clock domain signals.
//
// WARNING: This is a structural skeleton only. The internal logic for
//          critical modules (input coordinate generation, scaler, frame
//          buffer BRAM instantiation, CDC handling) is NOT IMPLEMENTED
//          and requires significant development, simulation, and testing.
//          Multiplexing the BRAM write clock requires careful timing analysis.
//
// Mac SE Timing Parameters updated based on research/calculations.
// Horizontal parameters require verification.
// Color Converter uses simple thresholding (Any R,G,B > 50% = White).
// Assumes Mac SE output driven by a 15.6672 MHz pixel clock.
// Input resolution assumed 800x600 from TFP401.
//
//////////////////////////////////////////////////////////////////////////////////
module hdmi_to_mac_se_converter (
    // TFP401 Input Interface (Example)
    input wire tfp401_pclk,      // Pixel Clock from TFP401 (e.g., ~40MHz for 800x600@60Hz)
    input wire tfp401_hs,        // Horizontal Sync from TFP401
    input wire tfp401_vs,        // Vertical Sync from TFP401
    input wire tfp401_de,        // Data Enable from TFP401 (indicates active pixel)
    input wire [7:0] tfp401_r,   // Red channel from TFP401
    input wire [7:0] tfp401_g,   // Green channel from TFP401
    input wire [7:0] tfp401_b,   // Blue channel from TFP401

    // Mac SE Output Interface
    input wire mac_se_clk_in,    // Base clock for Mac SE timing (e.g., 15.6672 MHz)
                                 // Assumed to be the target pixel clock directly here.
    output wire mac_se_pixel_clk,// Mac SE Pixel Clock output (likely same as mac_se_clk_in)
    output wire mac_se_hsync,    // Mac SE Horizontal Sync output
    output wire mac_se_vsync,    // Mac SE Vertical Sync output
    output wire mac_se_data,     // Mac SE 1-bit Monochrome Video Data output

    // Control Inputs
    input wire test_mode_switch, // Switch to enable test pattern write to buffer
    input wire [2:0] input_select_switches, // Placeholder for future input selection

    // System Reset
    input wire reset             // System reset
);

    //--------------------------------------------------------------------------
    // Parameters
    //--------------------------------------------------------------------------
    localparam INPUT_H_ACTIVE  = 800; // Example Input Active Width
    localparam INPUT_V_ACTIVE  = 600; // Example Input Active Height
    localparam OUTPUT_H_ACTIVE = 512; // Mac SE Active Width
    localparam OUTPUT_V_ACTIVE = 342; // Mac SE Active Height

    // Frame Buffer Address Width (Based on Output Resolution)
    localparam FB_ADDR_WIDTH = $clog2(OUTPUT_H_ACTIVE * OUTPUT_V_ACTIVE); // ~18 bits for 512x342

    //--------------------------------------------------------------------------
    // Internal Signals
    //--------------------------------------------------------------------------

    // Signals from Input Coordinate Generator
    wire input_coord_valid;     // Derived from tfp401_de, potentially gated
    wire [$clog2(INPUT_H_ACTIVE)-1:0] input_x; // Current X coordinate from TFP401 input
    wire [$clog2(INPUT_V_ACTIVE)-1:0] input_y; // Current Y coordinate from TFP401 input

    // Signals from Color Converter
    wire [23:0] tfp401_rgb_data;// Combined RGB data from TFP401 input
    wire mono_pixel_in;         // 1-bit monochrome pixel data (to scaler)

    // Signals from Scaler (Normal Mode)
    wire scaled_mono_pixel;     // Scaled 1-bit pixel data (to buffer mux)
    wire scaled_write_enable;   // Enable signal for writing scaled pixel to buffer (to mux)
    wire [$clog2(OUTPUT_H_ACTIVE)-1:0] scaled_write_x; // Target X coord in buffer (to mux)
    wire [$clog2(OUTPUT_V_ACTIVE)-1:0] scaled_write_y; // Target Y coord in buffer (to mux)
    wire [FB_ADDR_WIDTH-1:0] fb_write_addr_from_scaler; // Calculated write address from scaler

    // Signals for Frame Buffer Read Side
    wire fb_read_enable_sig;    // Connects mac_se_active to buffer input
    wire [FB_ADDR_WIDTH-1:0] fb_read_addr;   // Read address for the 512x342 buffer
    wire mono_pixel_out;        // 1-bit monochrome pixel data (from buffer)

    // Signals from Mac SE Timing Generator
    wire mac_se_timing_clk_out; // Output pixel clock from timing generator
    wire mac_se_hsync_out;      // HSync from timing generator
    wire mac_se_vsync_out;      // VSync from timing generator
    wire mac_se_active;         // Indicates active display area for Mac SE output
    wire [9:0] mac_se_x;        // Current X coordinate for Mac SE output (0-511+) - Note: Width depends on H_TOTAL
    wire [9:0] mac_se_y;        // Current Y coordinate for Mac SE output (0-341+) - Note: Width depends on V_TOTAL

    // Test Pattern Signals (Generated in Output Clock Domain for Test Mode)
    wire test_pattern_data;     // Generated test pattern data
    wire [FB_ADDR_WIDTH-1:0] test_pattern_addr; // Address for test pattern write
    wire test_pattern_write_enable; // Write enable for test pattern

    // Multiplexed Signals for Frame Buffer Write Port
    wire fb_write_clk_mux;
    wire fb_write_enable_mux;
    wire [FB_ADDR_WIDTH-1:0] fb_write_addr_mux;
    wire fb_write_data_mux;

    //--------------------------------------------------------------------------
    // Input Data Combination
    //--------------------------------------------------------------------------
    assign tfp401_rgb_data = {tfp401_r, tfp401_g, tfp401_b};

    //--------------------------------------------------------------------------
    // Module Instantiations (Skeletons - Guts need implementation!)
    //--------------------------------------------------------------------------

    // 1. Input Coordinate Generator
    input_coordinate_generator #(
        .H_ACTIVE(INPUT_H_ACTIVE),
        .V_ACTIVE(INPUT_V_ACTIVE)
    ) u_input_coord_gen (
        .clk        (tfp401_pclk),
        .reset      (reset),
        .hs         (tfp401_hs),
        .vs         (tfp401_vs),
        .de         (tfp401_de),
        .valid_out  (input_coord_valid),
        .x_out      (input_x),
        .y_out      (input_y)
    );

    // 2. Color Space Converter
    color_converter u_color_conv (
        .clk            (tfp401_pclk),
        .reset          (reset),
        .enable         (input_coord_valid),
        .rgb_in         (tfp401_rgb_data),
        .mono_out       (mono_pixel_in)
    );

    // 3. Scaler (Nearest Neighbor)
    scaler #(
        .INPUT_WIDTH(INPUT_H_ACTIVE),
        .INPUT_HEIGHT(INPUT_V_ACTIVE),
        .OUTPUT_WIDTH(OUTPUT_H_ACTIVE),
        .OUTPUT_HEIGHT(OUTPUT_V_ACTIVE)
    ) u_scaler (
        .clk                (tfp401_pclk),
        .reset              (reset),
        .enable_in          (input_coord_valid),
        .mono_pixel_in      (mono_pixel_in),
        .input_x            (input_x),
        .input_y            (input_y),
        .scaled_mono_pixel  (scaled_mono_pixel),
        .scaled_write_enable(scaled_write_enable),
        .scaled_write_x     (scaled_write_x),
        .scaled_write_y     (scaled_write_y)
    );

    // 4. Mac SE Timing Generator
    mac_se_timing_generator u_mac_se_timing (
        .clk_in         (mac_se_clk_in),
        .reset          (reset),
        .pixel_clk      (mac_se_timing_clk_out),
        .hsync          (mac_se_hsync_out),
        .vsync          (mac_se_vsync_out),
        .active         (mac_se_active),
        .x_coord        (mac_se_x),
        .y_coord        (mac_se_y)
    );

    //--------------------------------------------------------------------------
    // Test Pattern Generation (Output Clock Domain)
    //--------------------------------------------------------------------------
    assign test_pattern_data = mac_se_x[4] ^ mac_se_y[4]; // Example: Checkerboard
    assign test_pattern_addr = mac_se_y[$clog2(OUTPUT_V_ACTIVE)-1:0] * OUTPUT_H_ACTIVE + mac_se_x[$clog2(OUTPUT_H_ACTIVE)-1:0];
    assign test_pattern_write_enable = mac_se_active;

    //--------------------------------------------------------------------------
    // Frame Buffer Write Port Multiplexing
    //--------------------------------------------------------------------------
    assign fb_write_clk_mux = test_mode_switch ? mac_se_timing_clk_out : tfp401_pclk;
    assign fb_write_enable_mux = test_mode_switch ? test_pattern_write_enable : scaled_write_enable;
    assign fb_write_addr_from_scaler = scaled_write_y * OUTPUT_H_ACTIVE + scaled_write_x;
    assign fb_write_addr_mux = test_mode_switch ? test_pattern_addr : fb_write_addr_from_scaler;
    assign fb_write_data_mux = test_mode_switch ? test_pattern_data : scaled_mono_pixel;

    //--------------------------------------------------------------------------
    // 5. Frame Buffer (CDC Buffer) Instantiation
    //--------------------------------------------------------------------------
    frame_buffer #(
        .BUFFER_WIDTH(OUTPUT_H_ACTIVE),
        .BUFFER_HEIGHT(OUTPUT_V_ACTIVE),
        .ADDR_WIDTH(FB_ADDR_WIDTH)
    ) u_frame_buffer (
        .write_clk      (fb_write_clk_mux),
        .write_enable   (fb_write_enable_mux),
        .write_addr     (fb_write_addr_mux),
        .write_data     (fb_write_data_mux),
        .read_clk       (mac_se_timing_clk_out),
        .read_enable    (fb_read_enable_sig),
        .read_addr      (fb_read_addr),
        .read_data      (mono_pixel_out),
        .reset          (reset)
    );

    assign fb_read_enable_sig = mac_se_active;
    assign fb_read_addr = mac_se_y[$clog2(OUTPUT_V_ACTIVE)-1:0] * OUTPUT_H_ACTIVE + mac_se_x[$clog2(OUTPUT_H_ACTIVE)-1:0];

    //--------------------------------------------------------------------------
    // Top-Level Outputs
    //--------------------------------------------------------------------------
    assign mac_se_pixel_clk = mac_se_timing_clk_out;
    assign mac_se_hsync     = mac_se_hsync_out;
    assign mac_se_vsync     = mac_se_vsync_out;
    assign mac_se_data      = mac_se_active ? mono_pixel_out : 1'b1;

endmodule // hdmi_to_mac_se_converter