// filepath: /hdmi_to_mac_se_converter_project/hdmi_to_mac_se_converter_project/src/color_converter.v
//////////////////////////////////////////////////////////////////////////////////
// Module: color_converter
//
// Description:
// Converts RGB input data into monochrome output based on a simple thresholding method.
// If any of the input values are 1, the output is white (1).
// Otherwise, the output is black (0).
// 
// Honestly, I don't think I need a separate module for this, but 
// if I want to make it more complicated later, I've got it broken out.
//////////////////////////////////////////////////////////////////////////////////
module color_converter (
    input wire clk,            // Should be tfp401_pclk
    input wire reset,
    input wire enable,         // Should be input_coord_valid
    input wire rgb_r3_N7,      // Red bit 3 (MSB)
    input wire rgb_r4_N6,      // Red bit 4
    input wire rgb_g3_P7,      // Green bit 3 (MSB)
    input wire rgb_g4_R7,      // Green bit 4
    input wire rgb_g5_D10,     // Green bit 5
    input wire rgb_b3_A14,     // Blue bit 3 (MSB)
    input wire rgb_b4_B14,     // Blue bit 4
    output reg mono_out
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mono_out <= 1'b0;
        end else if (enable) begin
            // Perform a big OR to check if any input value is 1
            mono_out <= rgb_r3_N7 | rgb_r4_N6 | rgb_g3_P7 | rgb_g4_R7 | rgb_g5_D10 | rgb_b3_A14 | rgb_b4_B14;
        end else begin
            mono_out <= 1'b0; // Output Black during blanking intervals
        end
    end

endmodule // color_converter