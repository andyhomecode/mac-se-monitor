module led(
    input  Clock,
    output IO_voltage,
    output clock_out,
    output five_hz
);

/********** Counter **********/
//parameter Clock_frequency = 27_000_000; // Crystal oscillator frequency is 27Mhz
parameter count_value       = 13_499_999; // The number of times needed to time 0.5S

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
    wire second_clk;

    // 4. Instantiate a Global Clock Buffer (BUFG)
    //    Connect raw clock to BUFG input, use BUFG output for logic
    BUFG u_clk_buffer (
        .I(osc_clk_raw),   // Input is the raw oscillator clock
        .O(second_clk)       // Output is the buffered clock
    );

reg flopper = 1'b0; // initial state

// output a 1/2 frequency wave 
always @(posedge second_clk) begin
     flopper <= ~flopper;

end

// assign clock_out = flopper; // from the posedge 

assign clock_out = second_clk; // direct from the clock

/***** Add an extra line of code *****/
assign IO_voltage = IO_voltage_reg;
assign five_hz = IO_voltage_reg;



// ************************************************************
// ****** BRAM for Frame Buffer ***********************

// TODO: Created the 1 bit framebuffer but haven't implemented it yet.

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

//    Gowin_SDPB your_instance_name(
//        .dout(dout), //output [31:0] dout
//        .clka(clka), //input clka
//        .cea(cea), //input cea
//        .reseta(reseta), //input reseta
//        .clkb(clkb), //input clkb
//        .ceb(ceb), //input ceb
//        .resetb(resetb), //input resetb
//        .oce(oce), //input oce
//        .ada(ada), //input [12:0] ada
//        .din(din), //input [31:0] din
//        .adb(adb) //input [12:0] adb
//    );

//--------Copy end-------------------

endmodule
