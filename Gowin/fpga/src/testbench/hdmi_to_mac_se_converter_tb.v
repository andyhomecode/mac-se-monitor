// filepath: /hdmi_to_mac_se_converter_project/testbench/hdmi_to_mac_se_converter_tb.v
`timescale 1ns / 1ps

module hdmi_to_mac_se_converter_tb;

    // Parameters
    parameter CLK_PERIOD = 25; // 40MHz clock period

    // Inputs
    reg tfp401_pclk;
    reg tfp401_hs;
    reg tfp401_vs;
    reg tfp401_de;
    reg [7:0] tfp401_r;
    reg [7:0] tfp401_g;
    reg [7:0] tfp401_b;
    reg mac_se_clk_in;
    reg test_mode_switch;
    reg [2:0] input_select_switches;
    reg reset;

    // Outputs
    wire mac_se_pixel_clk;
    wire mac_se_hsync;
    wire mac_se_vsync;
    wire mac_se_data;

    // Instantiate the Unit Under Test (UUT)
    hdmi_to_mac_se_converter uut (
        .tfp401_pclk(tfp401_pclk),
        .tfp401_hs(tfp401_hs),
        .tfp401_vs(tfp401_vs),
        .tfp401_de(tfp401_de),
        .tfp401_r(tfp401_r),
        .tfp401_g(tfp401_g),
        .tfp401_b(tfp401_b),
        .mac_se_clk_in(mac_se_clk_in),
        .mac_se_pixel_clk(mac_se_pixel_clk),
        .mac_se_hsync(mac_se_hsync),
        .mac_se_vsync(mac_se_vsync),
        .mac_se_data(mac_se_data),
        .test_mode_switch(test_mode_switch),
        .input_select_switches(input_select_switches),
        .reset(reset)
    );

    // Clock Generation
    initial begin
        tfp401_pclk = 0;
        forever #(CLK_PERIOD / 2) tfp401_pclk = ~tfp401_pclk;
    end

    initial begin
        mac_se_clk_in = 0;
        forever #(64) mac_se_clk_in = ~mac_se_clk_in; // 15.6672 MHz clock
    end

    // Test Sequence
    initial begin
        // Initialize Inputs
        reset = 1;
        tfp401_hs = 0;
        tfp401_vs = 0;
        tfp401_de = 0;
        tfp401_r = 0;
        tfp401_g = 0;
        tfp401_b = 0;
        test_mode_switch = 0;
        input_select_switches = 3'b000;

        // Wait for global reset
        #(CLK_PERIOD);
        reset = 0;

        // Test Pattern Generation
        // Apply test vectors here
        // Example: Simulate HDMI input
        // ...

        // Finish simulation after some time
        #(1000000);
        $finish;
    end

    // Monitor Outputs
    initial begin
        $monitor("Time: %0t | Pixel Clock: %b | HSync: %b | VSync: %b | Data: %b", 
                 $time, mac_se_pixel_clk, mac_se_hsync, mac_se_vsync, mac_se_data);
    end

endmodule // hdmi_to_mac_se_converter_tb