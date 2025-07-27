// HDMI RX Testbench
// Andy Maxwell 2025-07-27
// Simple testbench for HDMI receiver verification

`timescale 1ns / 1ps

module tb_hdmi_rx();

// Testbench signals
reg         tb_clk;
reg         tb_rst_n;
reg         tb_tmds_clk_p;
reg         tb_tmds_clk_n; 
reg  [2:0]  tb_tmds_data_p;
reg  [2:0]  tb_tmds_data_n;
reg         tb_scl;
wire        tb_sda;
wire        tb_hpd;
wire [3:0]  tb_led;
wire        tb_rgb_clk;
wire        tb_rgb_vs;
wire        tb_rgb_hs;
wire        tb_rgb_de;
wire [7:0]  tb_rgb_r;
wire [7:0]  tb_rgb_g;
wire [7:0]  tb_rgb_b;
wire        tb_pll_lock;
wire [3:0]  tb_pll_phase;
wire        tb_pll_phase_lock;

// Clock generation
initial begin
    tb_clk = 0;
    forever #10 tb_clk = ~tb_clk; // 50MHz system clock
end

// HDMI clock simulation (much faster for simulation)
initial begin
    tb_tmds_clk_p = 0;
    forever #6.67 tb_tmds_clk_p = ~tb_tmds_clk_p; // ~75MHz HDMI clock
end

assign tb_tmds_clk_n = ~tb_tmds_clk_p;

// Reset and stimulus
initial begin
    // Initialize signals
    tb_rst_n = 0;
    tb_tmds_data_p = 3'b000;
    tb_tmds_data_n = 3'b111;
    tb_scl = 1;
    
    // Reset sequence
    #100;
    tb_rst_n = 1;
    $display("Reset released at time %t", $time);
    
    // Wait for system to stabilize
    #1000;
    
    // Simulate some HDMI data activity
    repeat(100) begin
        @(posedge tb_tmds_clk_p);
        tb_tmds_data_p = $random;
        tb_tmds_data_n = ~tb_tmds_data_p;
    end
    
    // Simulate I2C activity (EDID read)
    #10000;
    $display("Simulating I2C/EDID activity at time %t", $time);
    repeat(16) begin
        tb_scl = 0;
        #500;
        tb_scl = 1; 
        #500;
    end
    
    // Continue simulation
    #50000;
    
    $display("Simulation completed at time %t", $time);
    $finish;
end

// Monitor key signals
always @(posedge tb_clk) begin
    if(tb_hpd && tb_pll_lock) begin
        $display("HPD asserted and PLL locked at time %t", $time);
    end
end

// Instance under test
hdmi_rx_top dut (
    .I_clk            (tb_clk),
    .I_rst_n          (tb_rst_n),
    .I_tmds_clk_p     (tb_tmds_clk_p),
    .I_tmds_clk_n     (tb_tmds_clk_n),
    .I_tmds_data_p    (tb_tmds_data_p),
    .I_tmds_data_n    (tb_tmds_data_n),
    .I_scl            (tb_scl),
    .IO_sda           (tb_sda),
    .O_hpd            (tb_hpd),
    .O_led            (tb_led),
    .O_rgb_clk        (tb_rgb_clk),
    .O_rgb_vs         (tb_rgb_vs), 
    .O_rgb_hs         (tb_rgb_hs),
    .O_rgb_de         (tb_rgb_de),
    .O_rgb_r          (tb_rgb_r),
    .O_rgb_g          (tb_rgb_g),
    .O_rgb_b          (tb_rgb_b),
    .O_pll_lock       (tb_pll_lock),
    .O_pll_phase      (tb_pll_phase),
    .O_pll_phase_lock (tb_pll_phase_lock)
);

endmodule
