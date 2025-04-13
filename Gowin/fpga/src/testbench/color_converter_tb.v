// filepath: /hdmi_to_mac_se_converter_project/testbench/color_converter_tb.v
`timescale 1ns / 1ps

module color_converter_tb;

    // Parameters
    reg clk;
    reg reset;
    reg enable;
    reg [23:0] rgb_in;
    wire mono_out;

    // Instantiate the color_converter module
    color_converter uut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .rgb_in(rgb_in),
        .mono_out(mono_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // Test procedure
    initial begin
        // Initialize inputs
        reset = 1;
        enable = 0;
        rgb_in = 24'b0;

        // Release reset
        #10 reset = 0;

        // Test case 1: All colors below threshold
        rgb_in = 24'h007F7F; // RGB(127, 127, 127)
        enable = 1;
        #10;
        if (mono_out !== 1'b0) $display("Test Case 1 Failed: Expected 0, got %b", mono_out);

        // Test case 2: One color above threshold
        rgb_in = 24'h80FF00; // RGB(128, 255, 0)
        #10;
        if (mono_out !== 1'b1) $display("Test Case 2 Failed: Expected 1, got %b", mono_out);

        // Test case 3: All colors above threshold
        rgb_in = 24'hFFFFFF; // RGB(255, 255, 255)
        #10;
        if (mono_out !== 1'b1) $display("Test Case 3 Failed: Expected 1, got %b", mono_out);

        // Test case 4: Reset functionality
        reset = 1;
        #10;
        reset = 0;
        rgb_in = 24'h007F7F; // RGB(127, 127, 127)
        #10;
        if (mono_out !== 1'b0) $display("Test Case 4 Failed: Expected 0, got %b", mono_out);

        // End simulation
        $finish;
    end

endmodule // color_converter_tb