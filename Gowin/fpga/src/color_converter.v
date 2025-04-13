// filepath: /hdmi_to_mac_se_converter_project/hdmi_to_mac_se_converter_project/src/color_converter.v
//////////////////////////////////////////////////////////////////////////////////
// Module: color_converter
//
// Description:
// Converts RGB input data into monochrome output based on a simple thresholding method.
// If any of the R, G, or B components are above 50% intensity, the output is white (1).
// Otherwise, the output is black (0).
//
//////////////////////////////////////////////////////////////////////////////////
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