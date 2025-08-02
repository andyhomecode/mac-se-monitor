/*
Andy's amazing Mac SE Monitor HDMI Video Card
2025 08 01


                             __________________________
                    __..--/".'                        '.
            __..--""      | |                          |
            /              | |                          |
            /               | |    ___________________   |
            ;                | |   :__________________/:  |
            |                | |   |                 '.|  |
            |                | |   |                  ||  |
            |                | |   |                  ||  |
            |                | |   |                  ||  |
            |                | |   |                  ||  |
            |                | |   |                  ||  |
            |                | |   |                  ||  |
            |                | |   |                  ||  |
            |                | |   |______......-----"\|  |
            |                | |   |_______......-----"   |
            |                | |                          |
            |                | |                          |
            |                | |                  ____----|
            |                | |_____.....----|#######|---|
            |                | |______.....----""""       |
            |                | |                          |
            |. ..            | |   ,                      |
            |... ....        | |  (c ----- """           .'
            |..... ......  |\|_|    ____......------"""|"
            |. .... .......| |""""""                   |
            '... ..... ....| |                         |
            "-._ .....  .| |                         |
                "-._.....| |             ___...---"""'
                    "-._.| | ___...---"""
                        """""                                */

module main(


    output mac_hsync,
    output mac_vsync,
    output mac_active, // output for diagnostic
    output mac_pixel_clk, // output for diagnostic
    output reg video_out, // Changed to reg for procedural assignment

    // TTL RGB in from the HDMI decoder
    // 2025 07 20 only loading most significant bits of RGb 
    input rgb_r_B14,
    input rgb_g_A14,
    input rgb_b_b13,

    input rgb_odck, // pixel clock
    input rgb_hsync, // Goes to A15
    input rgb_vsync,  // 
    input rgb_de,  // DISPEN on the Adafruit board schematic
    input rgb_active, // Active Video signal, not used currently

    // TODO: Show the Mac Icon if no HDMI video

    // --- Switches and LEDs for test settings, not used currently ---
    input T5,  // Switch for Number5 can't seem to get it working.

    output RBG_CLOCK_LED3_N14,  // for incoming HDMI pixel clock divider
    output HDMI_ACTIVE_LED2_N16, // for incoming HDMI active

    // couple of outputs for the o'scope
    output J14,
    output J16,
    output M14,
    output M15,
    output T12,
    output R11,
    output T11,
    output P11

);


    //  #######                                                                                 
    //  #        #####     ##    #    #  ######  #####   #    #  ######  ######  ######  #####  
    //  #        #    #   #  #   ##  ##  #       #    #  #    #  #       #       #       #    # 
    //  #####    #    #  #    #  # ## #  #####   #####   #    #  #####   #####   #####   #    # 
    //  #        #####   ######  #    #  #       #    #  #    #  #       #       #       #####  
    //  #        #   #   #    #  #    #  #       #    #  #    #  #       #       #       #   #  
    //  #        #    #  #    #  #    #  ######  #####    ####   #       #       ######  #    # 
                                                                                            



    ///////////////////////////
    // FRAMEBUFFER BRAM SECTION
    ////////////////////////////
    // the BRAM is semi dual port, 
    // port A is write only to take data in from HDMI (TODO)
    // port B is read-only to read data from the framebuffer and output it to the screen
    // it is 175104 x 1, pass in the pixel counter to read.
    // Initialized with the Susan Kare original Mac icon.  [:^)]]

    // --- BRAM for Frame Buffer ---
    wire [17:0] ada, adb; // Address inputs
    wire din, dout;       // Data inputs/outputs
    wire clka, cea, reseta, clkb, ceb, resetb, oce; // Control signals - removed wea

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


        

    //  #     #                      #######                                       
    //  ##   ##    ##     ####       #     #  #    #  #####  #####   #    #  ##### 
    //  # # # #   #  #   #    #      #     #  #    #    #    #    #  #    #    #   
    //  #  #  #  #    #  #           #     #  #    #    #    #    #  #    #    #   
    //  #     #  ######  #           #     #  #    #    #    #####   #    #    #   
    //  #     #  #    #  #    #      #     #  #    #    #    #       #    #    #   
    //  #     #  #    #   ####       #######   ####     #    #        ####     #   
                                                                                



    // --- Clock Generation and Buffering for 15.xx MHz pixel clock ---
    // not exactly right, but close enough
    // The clock is generated by the Gowin oscillator and then passed through a PLL
    // to get the right frequency for the Mac SE
    wire osc_clk_raw; // Raw oscillator output
    wire fifteen_clk; // Buffered clock for logic

    // get the clock, should be 125MHz (or 250MHz/2, see gowin_osc.v)
    Gowin_OSC u_osc_generator (
        .oscout(osc_clk_raw) // Connect oscillator output
    );

    // then do some fancy-dancy math with the PLL 
    // to get it to 15.6672MHz (but still not right)
    Gowin_rPLL mac_clock_pll(
        .clkout(fifteen_clk), // Buffered clock output
        .clkin(osc_clk_raw)   // Raw clock input
    );

    assign mac_pixel_clk = fifteen_clk;


    //////////////////////////////////
    // --- Mac SE Timing Generator ---
    //////////////////////////////////
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

    // so now with every clock cycle the box should be spitting out perfect 
    // Mac SE VSYNC, and HSYNC signals, just like Woz used to make.
    // Internally, it's returning X & Y and total pixel count
    // to use to lookup black/white in the framebuffer
    // in the same time domain as the VSYNC and HSYNC


    // --- Mac CLock Time Domain Framebuffer Address and Clock Feeding ---
    // port B is read-only, port A is write-only
    assign clkb = fifteen_clk; // Use the pixel clock for framebuffer
    assign ceb = 1'b1;         // Enable framebuffer read
    assign adb = mac_pixel;    // Address is the pixel counter

    // Ensure BRAM output is valid
    assign oce = 1'b1;         // Output clock enable for BRAM

    // whenever the clock goes low, get the current pixel out of the framebuffer
    // and send it right out of the board i/o to make a beautiful picture
    always @(posedge fifteen_clk) begin
        video_out <= !(mac_active & dout); // Use AND condition for video_out
    end

    /////////////////////////////
    /////// HDMI DECODER SECTION //////////
    /////////////////////////////


    // --- Corrected Input Coordinate Generator ---
    // Assumes standard video timing: DE high for active pixels,
    // HSync/VSync pulses occur during blanking (DE low).
    // HSync and VSync are active-low pulses 
 
    // Define active display dimensions
    localparam H_ACTIVE = 800;
    localparam V_ACTIVE = 480;

    // Define scaled output dimensions
    localparam H_SCALED = 512;
    localparam V_SCALED = 342;
    localparam BRAM_ADDR_WIDTH = $clog2(H_SCALED * V_SCALED); // 18 bits for 512x342


    // --- Internal Registers and Wires ---

    localparam V_BACK_PORCH = 30; // Adjust this value based on testing
    reg [9:0] v_line_counter;     // Counts all lines including blanking
    reg in_active_region;         // Flag for active display region

    // Simplified Coordinate Generation Registers
    reg [9:0] input_x; // Input X coordinate (10 bits for H_ACTIVE)
    reg [9:0] input_y; // Input Y coordinate (10 bits for V_ACTIVE) // 2025 07 28 changed to 10 bits to avoid overflow errors 
    reg input_coord_valid;             // Valid signal for input coordinates
    reg rgb_hsync_prev;
    reg rgb_vsync_prev;
    reg rgb_de_prev;
    reg mono_pixel; // Monochrome pixel output (1 bit)
    
    // Sync flag registers - only driven from rgb pixel clock domain
    reg newV; // VSYNC event flag - set by VSYNC detection, cleared after processing
    reg newH; // HSYNC event flag - set by HSYNC detection, cleared after processing
    
    // Sync edge detection registers (for rgb pixel clock domain)
    reg rgb_vsync_sync1, rgb_vsync_sync2; // VSYNC synchronizer chain
    reg rgb_hsync_sync1, rgb_hsync_sync2; // HSYNC synchronizer chain

    // Scaler Registers
    reg [8:0] scaled_write_x; // Scaled X coordinate (9 bits for H_SCALED)
    reg [8:0] scaled_write_y; // Scaled Y coordinate (9 bits for V_SCALED)
    reg scaled_mono_pixel;
    reg scaled_write_enable;

    // *** BRAM Interface Registers (KEEP THESE) ***
    reg [17:0] bram_addr_reg; // BRAM address register (18 bits for 512x342)
    reg bram_din_reg;
    reg bram_ena_reg; // Port Enable register for BRAM

    // Combinatorial calculation for next BRAM address
    wire [17:0] next_bram_addr = (scaled_write_y * H_SCALED) + scaled_write_x;

    // --- Logic Implementation ---

    // --- PIXEL CLOCK: Handle all logic in single clock domain with sync detection ---
    always @(posedge rgb_odck) begin
        // --- Synchronize sync signals to pixel clock domain ---
        rgb_vsync_sync1 <= rgb_vsync;
        rgb_vsync_sync2 <= rgb_vsync_sync1;
        rgb_hsync_sync1 <= rgb_hsync;
        rgb_hsync_sync2 <= rgb_hsync_sync1;
        
        // --- Detect rising edges of synchronized signals ---
        if (rgb_vsync_sync1 && !rgb_vsync_sync2) begin
            // VSYNC rising edge detected
            newV <= 1'b1;
        end
        
        if (rgb_hsync_sync1 && !rgb_hsync_sync2) begin
            // HSYNC rising edge detected  
            newH <= 1'b1;
        end

        // --- Latch Previous States for debugging ---
        rgb_hsync_prev <= rgb_hsync;
        rgb_vsync_prev <= rgb_vsync;
        rgb_de_prev    <= rgb_de;

        // --- VSYNC flag: Reset frame ---
        if (newV) begin
            // VSYNC event detected - reset frame
            input_y <= 0;
            input_x <= 0;
            v_line_counter <= 0;
            in_active_region <= 1'b0;
            newV <= 1'b0;  // Clear the flag
        end
        // --- HSYNC flag: Process line and increment counters ---
        else if (newH) begin
            // HSYNC event detected - reset X counter
            input_x <= 0;
            
            // Increment line counter regardless of active region
            v_line_counter <= v_line_counter + 1;
            
            // Check if we're exactly at the back porch transition
            if (v_line_counter == V_BACK_PORCH - 1) begin
                // We're just reaching active region - set flag but don't increment y yet
                in_active_region <= 1'b1;
                // First active line is y=0, so don't increment
            end 
            else if (in_active_region) begin
                // Already in active region, increment input_y for subsequent lines
                if (input_y < V_ACTIVE - 1) begin
                    input_y <= input_y + 1;
                end
            end
            
            newH <= 1'b0;  // Clear the flag
        end
        
        // --- X Counter: Increment during active video (independent of sync flags) ---
        if (rgb_de && input_x < H_ACTIVE - 1) begin
            // During active video - increment X counter
            input_x <= input_x + 1;
        end

        // Coordinate Valid Signal - follows DE and active region flag
        input_coord_valid <= rgb_de && in_active_region;

        // --- Color to Black and White Converter ---
        if (input_coord_valid) begin
            // Set mono_pixel high if any of R, G, or B are high
            mono_pixel <= rgb_r_B14 | rgb_g_A14 | rgb_b_b13;
        end else begin
            mono_pixel <= 1'b0;
        end

        // --- Scaler Logic ---
        // T5 switch: 1 = scaled mode, 0 = crop mode (top-left corner)
        if (input_coord_valid) begin // Uses previous cycle's valid implicitly
            if (T5) begin
                // SCALED MODE: Scale 800x480 to 512x342
                scaled_write_x <= (input_x * H_SCALED) / H_ACTIVE;
                // Alternative Y scaling to ensure full range coverage
                if (input_y >= V_ACTIVE - 1) begin
                    scaled_write_y <= V_SCALED - 1; // Ensure we hit the last line
                end else begin
                    scaled_write_y <= (input_y * V_SCALED) / V_ACTIVE;
                end
            end else begin
                // CROP MODE: Direct 1:1 mapping (top-left 512x342 pixels)
                if (input_x < H_SCALED && input_y < V_SCALED) begin
                    scaled_write_x <= input_x[8:0]; // Take lower 9 bits 
                    scaled_write_y <= input_y[8:0]; // Take lower 9 bits
                end else begin
                    // Outside crop area - don't write
                    scaled_write_enable <= 1'b0;
                end
            end
            
            // Common logic for both modes
            if (T5 || (input_x < H_SCALED && input_y < V_SCALED)) begin
                scaled_mono_pixel <= mono_pixel;
                scaled_write_enable <= 1'b1;
            end
        end else begin
            scaled_write_enable <= 1'b0;
        end

        // --- Framebuffer Write Logic (Register BRAM Inputs) ---
        // Uses values from the *previous* cycle (scaler outputs)
        if (scaled_write_enable) begin
            bram_addr_reg <= next_bram_addr;    // Register address
            bram_din_reg  <= scaled_mono_pixel; // Register data
            bram_ena_reg  <= 1'b1;             // Register Port Enable (asserted)
            // bram_wea_reg  <= 1'b1;             // Register Write Enable (asserted)
        end else begin
            bram_ena_reg  <= 1'b0;             // Register Port Enable (deasserted)
            // bram_wea_reg  <= 1'b0;             // Register Write Enable (deasserted)
        end
    end

    // --- BRAM Interface Assignments ---
    // Assign BRAM inputs directly from the dedicated registers
    // For Gowin BRAM: cea controls both clock enable and write enable

    assign clka = rgb_odck; // BRAM clock
    assign ada = bram_addr_reg; // Use registered address (assuming Port A)
    assign din = bram_din_reg;   // Use registered data (assuming Port A)
    assign cea = bram_ena_reg;    // Clock Enable A also controls writes

        
    // ZO RELAXEN UND WATSCHEN DER BLINKENLICHTEN.

    // ACHTUNG! DAS INKOMMEN HDMI-SIGNAL IST NUN GE-AKTIVEN!
    assign HDMI_ACTIVE_LED2_N16 = ~rgb_active; // shine LED2 if HDMI is active


    // Fight Bugs                      |     |
    //                                 \\_V_//
    //                                 \/=|=\/
    //                                  [=v=]
    //                                __\___/_____
    //                               /..[  _____  ]
    //                              /_  [ [  M /] ]
    //                             /../.[ [ M /@] ]
    //                            <-->[_[ [M /@/] ]
    //                           /../ [.[ [ /@/ ] ]
    //      _________________]\ /__/  [_[ [/@/ C] ]
    //     <_________________>>0---]  [=\ \@/ C / /
    //        ___      ___   ]/000o   /__\ \ C / /
    //           \    /              /....\ \_/ /
    //        ....\||/....           [___/=\___/
    //       .    .  .    .          [...] [...]
    //      .      ..      .         [___/ \___]
    //      .    0 .. 0    .         <---> <--->
    //   /\/\.    .  .    ./\/\      [..]   [..]
    //  / / / .../|  |\... \ \ \    _[__]   [__]_
    // / / /       \/       \ \ \  [____>   <____]

    // DEUGGER STUFF TO SEE IF THE RGB INPUTS ARE WORKING
    // --- rgb_odck activity indicator ---
    reg [23:0] rgb_odck_counter = 0;
    reg rgb_odck_blink = 0;
    always @(posedge rgb_odck) begin
        rgb_odck_counter <= rgb_odck_counter + 1;
        if (rgb_odck_counter == 24'd0) // overflow, about once per ~16M clocks
            rgb_odck_blink <= ~rgb_odck_blink;
    end

    assign RBG_CLOCK_LED3_N14 = rgb_odck_blink; // Blink LED3 on RGB clock activity


    // debugging - simplified signals
    assign J16 = T5; 
    // assign J16 = rgb_vsync;           // Current VSYNC state
    assign J14 = rgb_hsync;           // Current HSYNC state  
    assign M14 = T5;                  // T5 switch state (1=scale, 0=crop)
    assign M15 = scaled_write_y[8];   // MSB of scaled Y (should reach 341 in scale mode)  
    assign T12 = rgb_de;              // Data Enable
    assign R11 = input_x[0];          // LSB of X counter
    assign T11 = input_y[0];          // LSB of Y counter
    assign P11 = bram_ena_reg;        // BRAM Write Enable for debugging
endmodule
