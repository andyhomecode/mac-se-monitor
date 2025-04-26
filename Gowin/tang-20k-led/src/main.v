module main(
    input  Clock,
    input T5,  // Switch for Number5
    input T4,  // Switch for Number4
    input E8,  // Switch for Number3
    // output IO_voltage,
    // output clock_out,
    // output five_hz

    output mac_hsync,
    output mac_vsync,
    output mac_active,
    output mac_pixel_clk,
    output test_pattern, // New output for test pattern video
    output L16, // LED for Number5
    output L14, // LED for Number4
    output N14  // LED for Number3
);

/********** Counter **********/
//parameter Clock_frequency = 27_000_000; // Crystal oscillator frequency is 27Mhz
parameter count_value       = 1_499_999; // The number of times needed to time 0.5S

wire IO_voltage;

reg [23:0]  count_value_reg ; // counter_value
reg         count_value_flag; // IO change flag

always @(posedge Clock) begin
    if ( count_value_reg <= count_value ) begin //not count to 0.5S
        count_value_reg  <= count_value_reg + 1'b1; // Continue counting
        count_value_flag <= 1'b0 ; // No flip flag
    end
    else begin //Count to 0.5S
        count_value_reg  <= 23'b0; // Clear counter,prepare for next time counting.
        count_value_flag <= 1'b1 ; // Flip flag
    end
end

/********** IO voltage flip **********/
reg IO_voltage_reg = 1'b0; // Initial state

always @(posedge Clock) begin
    if ( count_value_flag )  //  Flip flag, runs once ever 1/2 second
        IO_voltage_reg <= ~IO_voltage_reg; // IO voltage flip
    else //  No flip flag
        IO_voltage_reg <= IO_voltage_reg; // IO voltage constant
end



    // --- Clock Generation and Buffering for 15.xxmhz pixel clock---

    // 1. Wire to capture the raw oscillator output
    wire osc_clk_raw;

    // 2. Instantiate the Gowin Oscillator module
    Gowin_OSC u_osc_generator (
        .oscout(osc_clk_raw) // Connect its output to our wire
    );

    // 3. Wire for the buffered, low-skew clock to be used by logic
    wire fifteen_clk;

    // 4. Instantiate a Global Clock Buffer (BUFG)
    //    Connect raw clock to BUFG input, use BUFG output for logic
    BUFG u_clk_buffer (
        .I(osc_clk_raw),   // Input is the raw oscillator clock
        .O(fifteen_clk)       // Output is the buffered clock
    );

//reg flopper = 1'b0; // initial state

// output a 1/2 frequency wave 
//always @(posedge second_clk) begin
//     flopper <= ~flopper;

//end

// assign clock_out = flopper; // from the posedge 

assign clock_out = fifteen_clk; // direct from the clock

/***** Add an extra line of code *****/
//assign IO_voltage = IO_voltage_reg;
//assign five_hz = IO_voltage_reg;



// ************************************************************
// ****** BRAM for Frame Buffer ***********************


// Difine the inputs for the BRAM
wire [17:0] ada;     // CORRECT - 18 bits for address
wire [17:0] adb;     // 
wire din;     // 1 bit for b/w pixel
wire dout;    // 

// Also ensure your clock, reset, enable signals are declared correctly (usually single bit 'wire' or 'reg')
wire clka;
wire cea;
wire reseta;
wire clkb;
wire ceb;
wire resetb;
wire oce; //


// TODO: Created the 1 bit framebuffer but haven't implemented it yet.

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

    Gowin_SDPB framebuffer(
        .dout(dout), //output [0:0] dout
        .clka(clka), //input clka
        .cea(cea), //input cea
        .reseta(reseta), //input reseta
        .clkb(clkb), //input clkb
        .ceb(ceb), //input ceb
        .resetb(resetb), //input resetb
        .oce(oce), //input oce
        .ada(ada), //input [17:0] ada
        .din(din), //input [0:0] din
        .adb(adb) //input [17:0] adb
    );
//--------Copy end-------------------


//  Mac SE timing Generator


wire [9:0] mac_x_coord;
wire [8:0] mac_y_coord;
wire [17:0] mac_pixel; // New wire for pixel counter

assign mac_pixel_clk = fifteen_clk;

mac_se_timing_generator mac_timer(
    .clk(fifteen_clk),       // Pixel clock input
    .hsync(mac_hsync),       // Horizontal sync output
    .vsync(mac_vsync),       // Vertical sync output
    .active(mac_active),     // Active display area
    .pixel_x(mac_x_coord),   // Horizontal pixel coordinate
    .pixel_y(mac_y_coord),   // Vertical pixel coordinate
    .pixel(mac_pixel)        // Pixel counter
);

// Test pattern logic based on switches
// ANDY: I don't love the patterns yet, but will work on that later
assign test_pattern = (T5) ? (mac_x_coord[0] == 1'b0) : // Pattern 1: High if x-coordinate is even
                      (T4) ? (mac_y_coord[0] == 1'b0) : // Pattern 2: High if y-coordinate is even
                      (T5 & T4) ? ((mac_x_coord + mac_y_coord) % 2 == 0) : // Pattern 3: Checkerboard
                      (E8) ? (((mac_x_coord[3] ^ mac_y_coord[3]) == 1'b0)) : // Pattern 4: Larger checkerboard
                      1'b0; // Default: Low

// Connect switches to LEDs
assign L16 = T5;      // LED L16 lights up if T5 is on
assign L14 = T4;      // LED L14 lights up if T4 is on
assign N14 = E8;      // LED N14 lights up if E8 is on

endmodule
