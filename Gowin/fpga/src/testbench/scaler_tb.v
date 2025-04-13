// filepath: /hdmi_to_mac_se_converter_project/hdmi_to_mac_se_converter_project/testbench/scaler_tb.v
`timescale 1ns / 1ps

module scaler_tb;

    // Parameters
    parameter INPUT_WIDTH = 800;
    parameter INPUT_HEIGHT = 600;
    parameter OUTPUT_WIDTH = 512;
    parameter OUTPUT_HEIGHT = 342;

    // Testbench Signals
    reg clk;
    reg reset;
    reg enable_in;
    reg mono_pixel_in;
    reg [$clog2(INPUT_WIDTH)-1:0] input_x;
    reg [$clog2(INPUT_HEIGHT)-1:0] input_y;

    wire scaled_mono_pixel;
    wire scaled_write_enable;
    wire [$clog2(OUTPUT_WIDTH)-1:0] scaled_write_x;
    wire [$clog2(OUTPUT_HEIGHT)-1:0] scaled_write_y;

    // Instantiate the scaler module
    scaler #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .INPUT_HEIGHT(INPUT_HEIGHT),
        .OUTPUT_WIDTH(OUTPUT_WIDTH),
        .OUTPUT_HEIGHT(OUTPUT_HEIGHT)
    ) uut (
        .clk(clk),
        .reset(reset),
        .enable_in(enable_in),
        .mono_pixel_in(mono_pixel_in),
        .input_x(input_x),
        .input_y(input_y),
        .scaled_mono_pixel(scaled_mono_pixel),
        .scaled_write_enable(scaled_write_enable),
        .scaled_write_x(scaled_write_x),
        .scaled_write_y(scaled_write_y)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // Test Sequence
    initial begin
        // Initialize signals
        reset = 1;
        enable_in = 0;
        mono_pixel_in = 0;
        input_x = 0;
        input_y = 0;

        // Release reset
        #10 reset = 0;

        // Test case 1: Enable scaling with a pixel input
        #10;
        enable_in = 1;
        mono_pixel_in = 1; // Input pixel is white
        input_x = 100; // Example input coordinates
        input_y = 150;

        // Wait for a clock cycle
        #10;

        // Test case 2: Disable scaling
        enable_in = 0;

        // Wait for a clock cycle
        #10;

        // Test case 3: Enable scaling with a black pixel
        enable_in = 1;
        mono_pixel_in = 0; // Input pixel is black
        input_x = 200; // Example input coordinates
        input_y = 300;

        // Wait for a clock cycle
        #10;

        // Finish simulation
        $finish;
    end

    // Monitor outputs
    initial begin
        $monitor("Time: %0t | scaled_mono_pixel: %b | scaled_write_enable: %b | scaled_write_x: %d | scaled_write_y: %d", 
                 $time, scaled_mono_pixel, scaled_write_enable, scaled_write_x, scaled_write_y);
    end

endmodule // scaler_tb