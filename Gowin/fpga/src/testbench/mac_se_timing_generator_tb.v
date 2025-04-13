// filepath: /hdmi_to_mac_se_converter_project/testbench/mac_se_timing_generator_tb.v
`timescale 1ns / 1ps

module mac_se_timing_generator_tb;

    // Parameters
    localparam CLK_PERIOD = 64; // Clock period for 15.6672 MHz

    // Testbench Signals
    reg clk_in;
    reg reset;
    wire pixel_clk;
    wire hsync;
    wire vsync;
    wire active;
    wire [9:0] x_coord;
    wire [9:0] y_coord;

    // Instantiate the Unit Under Test (UUT)
    mac_se_timing_generator uut (
        .clk_in(clk_in),
        .reset(reset),
        .pixel_clk(pixel_clk),
        .hsync(hsync),
        .vsync(vsync),
        .active(active),
        .x_coord(x_coord),
        .y_coord(y_coord)
    );

    // Clock Generation
    initial begin
        clk_in = 0;
        forever #(CLK_PERIOD / 2) clk_in = ~clk_in; // Toggle clock
    end

    // Test Sequence
    initial begin
        // Initialize Inputs
        reset = 1;
        #100; // Wait for some time
        reset = 0;

        // Wait for a few clock cycles to observe outputs
        #1000;

        // Add more test cases as needed

        // Finish simulation
        $finish;
    end

    // Monitor Outputs
    initial begin
        $monitor("Time: %0t | hsync: %b | vsync: %b | active: %b | x_coord: %d | y_coord: %d", 
                 $time, hsync, vsync, active, x_coord, y_coord);
    end

endmodule // mac_se_timing_generator_tb