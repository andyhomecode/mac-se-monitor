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
        // *** Internal logic NOT IMPLEMENTED ***
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
        // *** Internal logic NOT IMPLEMENTED ***
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
    // Test pattern address uses direct output coordinates
    assign test_pattern_addr = mac_se_y[$clog2(OUTPUT_V_ACTIVE)-1:0] * OUTPUT_H_ACTIVE + mac_se_x[$clog2(OUTPUT_H_ACTIVE)-1:0];
    // Enable writing test pattern only during active display time
    assign test_pattern_write_enable = mac_se_active;

    //--------------------------------------------------------------------------
    // Frame Buffer Write Port Multiplexing
    //--------------------------------------------------------------------------
    // Select clock source for BRAM write port
    // WARNING: Switching clocks driving BRAM ports like this requires careful
    //          timing analysis or might be disallowed by some BRAM primitives.
    //          Ensure the chosen BRAM supports asynchronous R/W clocks.
    assign fb_write_clk_mux = test_mode_switch ? mac_se_timing_clk_out : tfp401_pclk;

    // Select write enable source
    assign fb_write_enable_mux = test_mode_switch ? test_pattern_write_enable : scaled_write_enable;

    // Calculate write address from scaler outputs (for normal mode)
    assign fb_write_addr_from_scaler = scaled_write_y * OUTPUT_H_ACTIVE + scaled_write_x;

    // Select write address source
    assign fb_write_addr_mux = test_mode_switch ? test_pattern_addr : fb_write_addr_from_scaler;

    // Select write data source
    assign fb_write_data_mux = test_mode_switch ? test_pattern_data : scaled_mono_pixel;

    //--------------------------------------------------------------------------
    // 5. Frame Buffer (CDC Buffer) Instantiation
    //--------------------------------------------------------------------------
    frame_buffer #(
        .BUFFER_WIDTH(OUTPUT_H_ACTIVE),
        .BUFFER_HEIGHT(OUTPUT_V_ACTIVE),
        .ADDR_WIDTH(FB_ADDR_WIDTH)
    ) u_frame_buffer (
        // Write Side (Clock selected by Mux)
        .write_clk      (fb_write_clk_mux),       // CLK Source depends on test_mode_switch
        .write_enable   (fb_write_enable_mux),    // Input: Write enable (from scaler OR test pattern)
        .write_addr     (fb_write_addr_mux),      // Input: Write address (from scaler OR test pattern)
        .write_data     (fb_write_data_mux),      // Input: Scaled data (from scaler OR test pattern)

        // Read Side (Mac SE Clock Domain)
        .read_clk       (mac_se_timing_clk_out),  // Clocked by Mac SE pixel clock
        .read_enable    (fb_read_enable_sig),     // Input: Read enable (from mac_se_active)
        .read_addr      (fb_read_addr),           // Input: Read address (from mac_se coords)
        .read_data      (mono_pixel_out),         // Output: Data read from buffer

        // System Reset
        .reset          (reset)
        // *** Internal logic (BRAM instantiation, CDC handling) NOT IMPLEMENTED ***
    );

    // Logic to control frame buffer read address/enable
    assign fb_read_enable_sig = mac_se_active; // Read only during Mac SE active display
    assign fb_read_addr = mac_se_y[$clog2(OUTPUT_V_ACTIVE)-1:0] * OUTPUT_H_ACTIVE + mac_se_x[$clog2(OUTPUT_H_ACTIVE)-1:0]; // Direct linear mapping


    //--------------------------------------------------------------------------
    // Top-Level Outputs
    //--------------------------------------------------------------------------
    assign mac_se_pixel_clk = mac_se_timing_clk_out;
    assign mac_se_hsync     = mac_se_hsync_out;
    assign mac_se_vsync     = mac_se_vsync_out;

    // Output data *always* comes from the frame buffer read port now.
    // Output '1' (idle high) during blanking periods.
    assign mac_se_data      = mac_se_active ? mono_pixel_out : 1'b1;


endmodule // hdmi_to_mac_se_converter


//==============================================================================
// Module: input_coordinate_generator (Skeleton)
//==============================================================================
module input_coordinate_generator #(
    parameter H_ACTIVE = 800,
    parameter V_ACTIVE = 600
    // May need H_TOTAL, V_TOTAL parameters for the *input* signal if known/fixed
) (
    input wire clk,   // TFP401 pixel clock
    input wire reset,
    input wire hs,    // TFP401 HSync
    input wire vs,    // TFP401 VSync
    input wire de,    // TFP401 Data Enable
    output reg valid_out, // Active pixel indicator
    output reg [$clog2(H_ACTIVE)-1:0] x_out,
    output reg [$clog2(V_ACTIVE)-1:0] y_out
);
    // *** Placeholder ***
    // Requires logic to count active pixels/lines based on clk, hs, vs, de.
    // Output x_out, y_out coordinates relative to the input frame (0 to H_ACTIVE-1, 0 to V_ACTIVE-1).
    // Set valid_out high when de is high.

    initial begin
        valid_out = 1'b0;
        x_out = 0;
        y_out = 0;
    end
    // *** Actual implementation needed here ***

endmodule // input_coordinate_generator


//==============================================================================
// Module: color_converter (UPDATED LOGIC - OR Condition)
//==============================================================================
module color_converter (
    input wire clk,            // Should be tfp401_pclk
    input wire reset,
    input wire enable,        // Should be input_coord_valid
    input wire [23:0] rgb_in, // Assuming {R[7:0], G[7:0], B[7:0]}
    output reg mono_out
);
    // Converts RGB to Monochrome based on simple thresholding:
    // If R OR G OR B are >= 50% (128), output is 1 (White).
    // Otherwise, output is 0 (Black).

    localparam MID_LEVEL = 8'd128; // Threshold for 50% intensity for 8-bit color

    wire [7:0] r_val = rgb_in[23:16];
    wire [7:0] g_val = rgb_in[15:8];
    wire [7:0] b_val = rgb_in[7:0];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mono_out <= 1'b0;
        end else if (enable) begin
            // Check if ANY color component is at or above the midpoint
            if (r_val >= MID_LEVEL || g_val >= MID_LEVEL || b_val >= MID_LEVEL) begin
                mono_out <= 1'b1; // White
            end else begin
                mono_out <= 1'b0; // Black
            end
        end else begin
             mono_out <= 1'b0; // Output Black during blanking intervals
        end
    end

endmodule // color_converter


//==============================================================================
// Module: scaler (Skeleton - Nearest Neighbor)
//==============================================================================
module scaler #(
    parameter INPUT_WIDTH   = 800,
    parameter INPUT_HEIGHT  = 600,
    parameter OUTPUT_WIDTH  = 512,
    parameter OUTPUT_HEIGHT = 342
) (
    input wire clk,                 // Input clock (tfp401_pclk)
    input wire reset,
    input wire enable_in,           // Input pixel valid (input_coord_valid)
    input wire mono_pixel_in,       // Input monochrome pixel
    input wire [$clog2(INPUT_WIDTH)-1:0]  input_x, // Input X coordinate
    input wire [$clog2(INPUT_HEIGHT)-1:0] input_y, // Input Y coordinate

    output reg scaled_mono_pixel,     // Output: Scaled pixel value
    output reg scaled_write_enable,   // Output: Enable write to buffer
    output reg [$clog2(OUTPUT_WIDTH)-1:0]  scaled_write_x, // Output: Target X coord in buffer
    output reg [$clog2(OUTPUT_HEIGHT)-1:0] scaled_write_y  // Output: Target Y coord in buffer
);
    // *** Placeholder ***
    // Implements Nearest Neighbor downscaling.
    // Needs logic to determine IF the current input pixel (input_x, input_y)
    // corresponds to a sample point for the output grid (scaled_write_x, scaled_write_y).
    // If it does, set scaled_write_enable high for one clock cycle, output the
    // input pixel value (scaled_mono_pixel = mono_pixel_in), and the corresponding
    // output coordinates (scaled_write_x, scaled_write_y).

    initial begin
        scaled_mono_pixel   <= 1'b0;
        scaled_write_enable <= 1'b0;
        scaled_write_x      <= 0;
        scaled_write_y      <= 0;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            scaled_mono_pixel   <= 1'b0;
            scaled_write_enable <= 1'b0;
            scaled_write_x      <= 0;
            scaled_write_y      <= 0;
        end else begin
            scaled_write_enable <= 1'b0; // Default to low, pulse high when needed

            if (enable_in) begin
                // --- Nearest Neighbor Logic ---
                // Needs proper implementation using fixed-point or integer math
                // to determine when input_x/input_y corresponds to a sample point
                // for scaled_write_x/scaled_write_y.
            end
        end
    end
    // *** Actual implementation needed here ***

endmodule // scaler


//==============================================================================
// Module: frame_buffer (CDC Buffer - No Scaler)
//==============================================================================
module frame_buffer #(
    parameter BUFFER_WIDTH  = 512,
    parameter BUFFER_HEIGHT = 342,
    parameter ADDR_WIDTH    = $clog2(BUFFER_WIDTH * BUFFER_HEIGHT) // ~18 bits
) (
    // Write Side (Input/Scaler OR Output Clock Domain depending on test_mode_switch)
    input wire write_clk,
    input wire write_enable,
    input wire [ADDR_WIDTH-1:0] write_addr,
    input wire write_data,                  // 1-bit scaled monochrome data
    // Read Side (Output Clock Domain)
    input wire read_clk,
    input wire read_enable,
    input wire [ADDR_WIDTH-1:0] read_addr,
    output wire read_data,                  // 1-bit monochrome data
    // System Reset
    input wire reset
);
    // *** Placeholder ***
    // ** BRAM REQUIREMENT**: Needs BUFFER_WIDTH * BUFFER_HEIGHT bits (~175 Kbits).
    // Requires instantiation of a suitable dual-port Block RAM primitive for the target FPGA.
    // Ensure the BRAM primitive supports asynchronous clocks on Port A (write) and Port B (read).
    // True Dual Port (TDP) RAM is generally recommended for CDC buffers.
    // Use Gowin EDA IP Generator to create the BRAM instance.
    // WARNING: Write clock is multiplexed in test mode - ensure BRAM supports this or handle carefully.

    // Example BRAM Instantiation (Generic - Replace with vendor-specific primitive, e.g., from Gowin IP Generator)
    /*
    Gowin_TDPB #( // Or SDPB if appropriate and handled carefully
        .DATA_WIDTH(1),         // Storing 1-bit monochrome data
        .ADDR_WIDTH(ADDR_WIDTH)
        // Add other configuration parameters as needed (e.g., block type, output reg)
    ) bram_instance (
        .clka   (write_clk),    // Write clock (MUXED!)
        .wea    (write_enable), // Write enable (MUXED)
        .addra  (write_addr),   // Write address (MUXED)
        .dina   (write_data),   // Data to write (MUXED)
        .ocea   (1'b0),         // Output clock enable A (unused for write)
        .cea    (write_enable), // Clock enable A (optional, often tied to write_enable)
        .reseta (reset),        // Reset A

        .clkb   (read_clk),     // Read clock (Mac SE Clock)
        .web    (1'b0),         // Write enable B (low for read)
        .addrb  (read_addr),    // Read address (Mac SE Coords)
        .doutb  (read_data),    // Data read from RAM
        .oceb   (read_enable),  // Output clock enable B (optional, can gate output reg)
        .ceb    (read_enable),  // Clock enable B (optional, enables read clocking)
        .resetb (reset)         // Reset B
    );
    */
     assign read_data = 1'b0; // Default output when BRAM not implemented

    // *** Actual implementation of BRAM instantiation needed here ***

endmodule // frame_buffer


//==============================================================================
// Module: mac_se_timing_generator (Timing parameters updated)
//==============================================================================
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
    // Based on 15.6672 MHz pixel clock (~63.827 ns period)
    // Derived from research (esp. Retrocomputing StackExchange) and PDF notes.

    // Horizontal Parameters (Best Guess - Require Verification)
    // NOTE: H_SYNC value is an educated guess based on typical timings and reconciling
    //       conflicting source information (PDF HSync pulse width seemed incorrect).
    //       These values (H_FRONT, H_SYNC, H_BACK) likely require adjustment
    //       based on empirical testing with the actual monitor.
    parameter H_DISPLAY = 512; // Active video pixels (Standard Mac SE)
    parameter H_FRONT   = 16;  // Best Guess Front porch
    parameter H_SYNC    = 64;  // Best Guess Sync pulse width --> VERIFY THIS!
    parameter H_BACK    = 112; // Best Guess Back porch (Derived from H_SYNC guess + PDF delay)
    parameter H_TOTAL   = 704; // Total clocks per line (512+16+64+112 = 704)

    // Vertical Parameters (Derived from PDF calculations - Likely Correct)
    // V_TOTAL = 16.64ms / 44.93us = ~370 lines
    // V_SYNC  = 180us / 44.93us = ~4 lines
    // V_SYNC + V_BACK = 1.26ms / 44.93us = ~28 lines => V_BACK = 24 lines
    // V_FRONT = V_TOTAL - V_DISPLAY - V_SYNC - V_BACK = 370 - 342 - 4 - 24 = 0 lines
    parameter V_DISPLAY = 342; // Active video lines (Standard Mac SE)
    parameter V_FRONT   = 0;   // Front porch (Calculated)
    parameter V_SYNC    = 4;   // Sync pulse lines (Calculated)
    parameter V_BACK    = 24;  // Back porch (Calculated)
    parameter V_TOTAL   = 370; // Total lines per frame (Calculated)

    // Counters
    // Need enough bits to hold max count - 1
    localparam H_BITS = $clog2(H_TOTAL); // e.g., $clog2(704) = 10
    localparam V_BITS = $clog2(V_TOTAL); // e.g., $clog2(370) = 9
    reg [H_BITS-1:0] h_counter = 0; // Horizontal counter
    reg [V_BITS-1:0] v_counter = 0; // Vertical counter

    // Pixel clock output (direct passthrough in this version)
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
            hsync <= 1; // Inactive high
            vsync <= 1; // Inactive high
        end else begin
            // HSYNC: Active low during the sync pulse period
            hsync <= ~((h_counter >= H_DISPLAY + H_FRONT) &&
                       (h_counter < H_DISPLAY + H_FRONT + H_SYNC));
            // VSYNC: Active low during the sync pulse period
            vsync <= ~((v_counter >= V_DISPLAY + V_FRONT) &&
                       (v_counter < V_DISPLAY + V_FRONT + V_SYNC));
        end
    end

    // Active video region signal
    assign active = (h_counter < H_DISPLAY) && (v_counter < V_DISPLAY);

    // Output coordinates (ensure width matches potential consumers)
    // Use calculated bit widths for output ports
    assign x_coord = h_counter;
    assign y_coord = v_counter;

endmodule // mac_se_timing_generator

