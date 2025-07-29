// HDMI receiver test
// Andy Maxwell
// 2025 07 27 version
// Complete HDMI receiver with hotplug, EDID, and status indicators

module hdmi_rx_top
(
    // No external clock needed - using internal oscillator
    
    // System reset
    input             I_rst_n,         // Active low reset
    
    // HDMI RX physical interface
    input             I_tmds_clk_p,    // HDMI differential clock positive
    input             I_tmds_clk_n,    // HDMI differential clock negative  
    input      [2:0]  I_tmds_data_p,   // HDMI differential data positive {R,G,B}
    input      [2:0]  I_tmds_data_n,   // HDMI differential data negative {R,G,B}
    
    // DDC/EDID interface (I2C for EDID communication)
    input             I_scl,           // I2C clock from HDMI source
    inout             IO_sda,          // I2C data bidirectional
    
    // Hot Plug Detect
    output            O_hpd,           // Hot plug detect - tells source we're present
    
    // Status LEDs
    output     [3:0]  O_led,          // Status indicator LEDs
    
    // Debug signals for oscilloscope
    output            DEBUG_P11,       // I2C SCL debug
    output            DEBUG_T11,       // I2C SDA debug (input only)
    output            DEBUG_R11,       // EDID clock debug
    output            DEBUG_T12,       // HPD debug
    output            DEBUG_M15,       // EDID reset debug
    output            DEBUG_M14,       // System clock divided
    output            DEBUG_J14,       // Heartbeat debug
    output            DEBUG_J16        // PLL lock status debug
);

//==================================================
// Internal clock generation using Gowin oscillator
//==================================================
wire I_clk; // Internal 50MHz-ish system clock

// Use internal oscillator instead of external clock
Gowin_OSC u_system_clock (
    .oscout(I_clk) // Generate system clock internally
);

//==================================================
// Internal wires for HDMI RX signals
//==================================================
// RGB output signals (internal wires for your framebuffer logic)
wire            O_rgb_clk;       // Pixel clock output
wire            O_rgb_vs;        // Vertical sync output
wire            O_rgb_hs;        // Horizontal sync output  
wire            O_rgb_de;        // Data enable output
wire     [7:0]  O_rgb_r;         // Red data output
wire     [7:0]  O_rgb_g;         // Green data output
wire     [7:0]  O_rgb_b;         // Blue data output

// PLL status outputs (internal wires)
wire            O_pll_lock;      // RX PLL lock status
wire     [3:0]  O_pll_phase;     // PLL phase information
wire            O_pll_phase_lock; // PLL phase lock status

//==================================================
// Status and heartbeat logic
//==================================================
reg  [31:0] run_cnt;
wire        heartbeat;

// Heartbeat counter for LED0 (indicates system is running)
always @(posedge I_clk or negedge I_rst_n) 
begin
    if(!I_rst_n)
        run_cnt <= 32'd0;
    else if(run_cnt >= 32'd50_000_000) // 1 second at 50MHz
        run_cnt <= 32'd0;
    else
        run_cnt <= run_cnt + 1'b1;
end

assign heartbeat = (run_cnt < 32'd25_000_000) ? 1'b1 : 1'b0; // 50% duty cycle

//==================================================
// Hot Plug Detect Logic
//==================================================
// Simple HPD logic - always high when system is ready (like it used to work)
reg [15:0] hpd_delay_counter;
reg hpd_ready;

always @(posedge I_clk or negedge I_rst_n) 
begin
    if(!I_rst_n) begin
        hpd_delay_counter <= 16'd0;
        hpd_ready <= 1'b0;
    end
    else if(hpd_delay_counter < 16'd10000) begin // ~200us delay at 50MHz
        hpd_delay_counter <= hpd_delay_counter + 1'b1;
        hpd_ready <= 1'b0;
    end
    else begin
        hpd_ready <= 1'b1;
    end
end

assign O_hpd = hpd_ready; // Simple HPD - always high when ready

//==================================================
// Status LED assignments
//==================================================
assign O_led[0] = heartbeat;        // Heartbeat - system running
assign O_led[1] = ~O_pll_phase_lock; // PLL phase lock (active low, so LED on = not locked)
assign O_led[2] = ~O_pll_lock;      // RX PLL lock (active low, so LED on = not locked)  
assign O_led[3] = ~I_rst_n;         // Reset indicator (LED on when in reset)

//==================================================
// EDID PROM instantiation
//==================================================

//==================================================
// EDID PROM instantiation
//==================================================
EDID_PROM_Top edid_prom_inst
(
    .I_clk     (I_clk    ), // System clock >= 5MHz, <=200MHz 
    .I_rst_n   (I_rst_n  ), // Active low reset
    .I_scl     (I_scl    ), // I2C clock from HDMI source    
    .IO_sda    (IO_sda   )  // I2C data bidirectional
);

//==================================================
// HDMI/DVI RX instantiation  
//==================================================
DVI_RX_Top dvi_rx_inst
(
    .I_rst_n         (I_rst_n       ), // Active low reset
    .I_tmds_clk_p    (I_tmds_clk_p  ), // HDMI differential clock positive
    .I_tmds_clk_n    (I_tmds_clk_n  ), // HDMI differential clock negative
    .I_tmds_data_p   (I_tmds_data_p ), // HDMI differential data positive {R,G,B}
    .I_tmds_data_n   (I_tmds_data_n ), // HDMI differential data negative {R,G,B}
    .O_pll_lock      (O_pll_lock    ), // RX PLL lock status
    .O_pll_phase     (O_pll_phase   ), // PLL phase information [3:0] 
    .O_pll_phase_lock(O_pll_phase_lock), // PLL phase lock status
    .O_rgb_clk       (O_rgb_clk     ), // Recovered pixel clock
    .O_rgb_vs        (O_rgb_vs      ), // Vertical sync
    .O_rgb_hs        (O_rgb_hs      ), // Horizontal sync
    .O_rgb_de        (O_rgb_de      ), // Data enable
    .O_rgb_r         (O_rgb_r       ), // Red data [7:0]
    .O_rgb_g         (O_rgb_g       ), // Green data [7:0]
    .O_rgb_b         (O_rgb_b       )  // Blue data [7:0]
);

//==================================================
// Debug signal assignments for oscilloscope
//==================================================
// Clock divider for debug signals
reg [15:0] debug_clk_div;
always @(posedge I_clk or negedge I_rst_n) 
begin
    if(!I_rst_n)
        debug_clk_div <= 16'd0;
    else
        debug_clk_div <= debug_clk_div + 1'b1;
end

// I2C activity detector
reg i2c_scl_prev;
reg i2c_activity;
reg [15:0] i2c_activity_timer;

always @(posedge I_clk or negedge I_rst_n) 
begin
    if(!I_rst_n) begin
        i2c_scl_prev <= 1'b1;
        i2c_activity <= 1'b0;
        i2c_activity_timer <= 16'd0;
    end
    else begin
        i2c_scl_prev <= I_scl;
        
        // Detect I2C activity (any edge on SCL only)
        if(I_scl != i2c_scl_prev) begin
            i2c_activity <= 1'b1;
            i2c_activity_timer <= 16'd50000; // Hold for ~1ms at 50MHz
        end
        else if(i2c_activity_timer > 0) begin
            i2c_activity_timer <= i2c_activity_timer - 1'b1;
        end
        else begin
            i2c_activity <= 1'b0;
        end
    end
end

// Debug signal assignments
assign DEBUG_P11 = I_scl;                    // Monitor I2C clock from source
assign DEBUG_T11 = i2c_activity;             // I2C activity indicator
assign DEBUG_R11 = I_clk;                    // System clock for timing reference  
assign DEBUG_T12 = O_hpd;                    // HPD output (should be steady high)
assign DEBUG_M15 = I_rst_n;                  // Reset status (active low)
assign DEBUG_M14 = debug_clk_div[15];        // Divided system clock (~1.5kHz at 50MHz)
assign DEBUG_J14 = heartbeat;                // Heartbeat indicator
assign DEBUG_J16 = O_pll_lock;               // PLL lock status

endmodule

