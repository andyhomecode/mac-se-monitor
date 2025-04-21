// filepath: /hdmi_to_mac_se_converter_project/hdmi_to_mac_se_converter_project/src/scaler.v
//////////////////////////////////////////////////////////////////////////////////
// Module: scaler (Nearest Neighbor)
// Version: 1
//
// Description:
// This module performs nearest neighbor scaling of the input monochrome pixel data.
// It determines the corresponding output coordinates and enables writing to the frame buffer.
//
// Parameters:
// INPUT_WIDTH   - Width of the input image
// INPUT_HEIGHT  - Height of the input image
// OUTPUT_WIDTH  - Width of the output image
// OUTPUT_HEIGHT - Height of the output image
//
//////////////////////////////////////////////////////////////////////////////////
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
    // Internal variables for scaling calculations
    localparam X_SCALE_FACTOR = INPUT_WIDTH / OUTPUT_WIDTH;
    localparam Y_SCALE_FACTOR = INPUT_HEIGHT / OUTPUT_HEIGHT;

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
                // Nearest Neighbor Logic
                if ((input_x % X_SCALE_FACTOR == 0) && (input_y % Y_SCALE_FACTOR == 0)) begin
                    scaled_write_x <= input_x / X_SCALE_FACTOR;
                    scaled_write_y <= input_y / Y_SCALE_FACTOR;
                    scaled_mono_pixel <= mono_pixel_in;
                    scaled_write_enable <= 1'b1; // Enable write for this pixel
                end
            end
        end
    end

endmodule // scaler