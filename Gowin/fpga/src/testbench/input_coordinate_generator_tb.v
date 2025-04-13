// filepath: hdmi_to_mac_se_converter_project/testbench/input_coordinate_generator_tb.v
`timescale 1ns / 1ps

module input_coordinate_generator_tb;

    // Parameters
    parameter H_ACTIVE = 800;
    parameter V_ACTIVE = 600;

    // Inputs
    reg clk;
    reg reset;
    reg hs;
    reg vs;
    reg de;

    // Outputs
    wire valid_out;
    wire [$clog2(H_ACTIVE)-1:0] x_out;
    wire [$clog2(V_ACTIVE)-1:0] y_out;

    // Instantiate the Unit Under Test (UUT)
    input_coordinate_generator #(
        .H_ACTIVE(H_ACTIVE),
        .V_ACTIVE(V_ACTIVE)
    ) uut (
        .clk(clk),
        .reset(reset),
        .hs(hs),
        .vs(vs),
        .de(de),
        .valid_out(valid_out),
        .x_out(x_out),
        .y_out(y_out)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // Test sequence
    initial begin
        // Initialize inputs
        reset = 1;
        hs = 0;
        vs = 0;
        de = 0;

        // Wait for global reset
        #10;
        reset = 0;

        // Simulate horizontal sync and data enable
        // Example sequence to generate coordinates
        // This is a simplified example; actual timing and values may vary
        #10 hs = 1; #10 hs = 0; // Horizontal sync pulse
        #10 de = 1; // Data enable
        // Simulate pixel data
        repeat (H_ACTIVE) begin
            #10;
            // Increment x coordinate
        end
        de = 0; // Disable data

        // Simulate vertical sync
        #10 vs = 1; #10 vs = 0; // Vertical sync pulse

        // Finish simulation
        #100;
        $finish;
    end

    // Monitor outputs
    initial begin
        $monitor("Time: %0t | Valid: %b | X: %d | Y: %d", $time, valid_out, x_out, y_out);
    end

endmodule // input_coordinate_generator_tb