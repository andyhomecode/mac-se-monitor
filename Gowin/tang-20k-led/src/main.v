module main(
    input  Clock,
    input T5,  // Switch for Number5
    input T4,  // Switch for Number4
    input E8,  // Switch for Number3

    output mac_hsync,
    output mac_vsync,
    output mac_active,
    output mac_pixel_clk,
    output reg test_pattern, // Changed to reg for procedural assignment
    output L16, // LED for Number5
    output L14, // LED for Number4
    output N14  // LED for Number3
);

    // --- Clock Generation and Buffering for 15.xx MHz pixel clock ---
    wire osc_clk_raw; // Raw oscillator output
    wire fifteen_clk; // Buffered clock for logic

    Gowin_OSC u_osc_generator (
        .oscout(osc_clk_raw) // Connect oscillator output
    );

    Gowin_rPLL mac_clock_pll(
        .clkout(fifteen_clk), // Buffered clock output
        .clkin(osc_clk_raw)   // Raw clock input
    );

    assign mac_pixel_clk = fifteen_clk;


    // the BRAM is semi dual port, 
    // port A is write only to take data in from HDMI (TODO)
    // port B is read-only to read data from the framebuffer and output it to the screen
    // it is 175104 x 1, pass in the pixel counter to read.

    // --- BRAM for Frame Buffer ---
    wire [17:0] ada, adb; // Address inputs
    wire din, dout;       // Data inputs/outputs
    wire clka, cea, reseta, clkb, ceb, resetb, oce; // Control signals

    Gowin_SDPB framebuffer(
        .dout(dout),
        .clka(clka),
        .cea(cea),
        .reseta(1'b0),
        .clkb(clkb),
        .ceb(ceb),
        .resetb(1'b0), // reset should always be low to enable it
        .oce(oce),
        .ada(ada),
        .din(din),
        .adb(adb)
    );

    // --- Mac SE Timing Generator ---
    wire [9:0] mac_x_coord;
    wire [8:0] mac_y_coord;
    wire [17:0] mac_pixel; // Pixel counter

    mac_se_timing_generator mac_timer(
        .clk(fifteen_clk),
        .hsync(mac_hsync),
        .vsync(mac_vsync),
        .active(mac_active),
        .pixel_x(mac_x_coord),
        .pixel_y(mac_y_coord),
        .pixel(mac_pixel)
    );

    // --- Framebuffer Address and Clock Feeding ---
    // port B is read-only, port A is write-only
    assign clkb = fifteen_clk; // Use the pixel clock for framebuffer
    assign ceb = 1'b1;         // Enable framebuffer read
    assign adb = mac_pixel;    // Address is the pixel counter

    // Ensure BRAM output is valid
    assign oce = 1'b1;         // Output clock enable for BRAM

    // just read from the framebuffer
    always @(posedge fifteen_clk) begin
        test_pattern <= dout; // Use the framebuffer data
    end

/*     // --- Test Pattern Logic ---
    always @(*) begin
        if (T5) begin
            test_pattern = (mac_x_coord[0] == 1'b0); // Pattern 1: High if x-coordinate is even
        end else if (T4) begin
            test_pattern = (mac_y_coord[0] == 1'b0); // Pattern 2: High if y-coordinate is even
        end else if (T5 & T4) begin
            test_pattern = ((mac_x_coord + mac_y_coord) % 2 == 0); // Pattern 3: Checkerboard
        end else if (E8) begin
            test_pattern = ((mac_x_coord[3] ^ mac_y_coord[3]) == 1'b0); // Pattern 4: Larger checkerboard
        end else begin
            test_pattern = ((mac_x_coord + mac_y_coord) % 2 == 0); // Pattern 3: Checkerboard
            // test_pattern = dout; // Use the framebuffer data
        end
    end */

    // --- LED Connections ---
    assign L16 = T5; // LED L16 lights up if T5 is on
    assign L14 = T4; // LED L14 lights up if T4 is on
    assign N14 = E8; // LED N14 lights up if E8 is on

endmodule
