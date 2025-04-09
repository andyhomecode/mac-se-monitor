module mac_se_crt_driver (
    input wire clk_in,        // Base clock input (e.g., 27 MHz)  TODO: Right now PLL is 16.59mhz, not 27mhz
    input wire reset,         // Reset signal
    output wire pixel_clk,    // Pixel clock output
    output reg vsync,         // Vertical sync output
    output reg hsync,         // Horizontal sync output
    output reg data           // 1-bit pixel data output (monochrome)
);

    ////////////////////////////////
    // Pixel Clock Divider
    ////////////////////////////////
    parameter BASE_CLOCK = 24000000;  // 27 MHz base clock
    parameter TARGET_CLOCK = 16590000; // 16.59 MHz pixel clock
    localparam DIV_RATIO = BASE_CLOCK / TARGET_CLOCK; // Approximation of division ratio

    reg [31:0] clk_counter = 0; // Counter for clock division
    reg clk_pixel = 0;          // Pixel clock signal

    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            clk_counter <= 0;
            clk_pixel <= 0;
        end else if (clk_counter >= (DIV_RATIO / 2) - 1) begin
            clk_counter <= 0;
            clk_pixel <= ~clk_pixel; // Toggle pixel clock
        end else begin
            clk_counter <= clk_counter + 1;
        end
    end

    assign pixel_clk = clk_pixel;

    ////////////////////////////////
    // CRT Timing Parameters
    ////////////////////////////////
    // Horizontal timing (values in clock cycles)
    parameter H_DISPLAY = 512; // Active video
    parameter H_FRONT = 24;    // Front porch
    parameter H_SYNC = 64;     // Sync pulse
    parameter H_BACK = 120;    // Back porch
    parameter H_TOTAL = H_DISPLAY + H_FRONT + H_SYNC + H_BACK;

    // Vertical timing (values in lines)
    parameter V_DISPLAY = 342; // Active video
    parameter V_FRONT = 1;     // Front porch
    parameter V_SYNC = 3;      // Sync pulse
    parameter V_BACK = 38;     // Back porch
    parameter V_TOTAL = V_DISPLAY + V_FRONT + V_SYNC + V_BACK;

    // Counters
    reg [9:0] h_counter = 0; // Horizontal counter
    reg [9:0] v_counter = 0; // Vertical counter

    ////////////////////////////////
    // Horizontal and Vertical Counters
    ////////////////////////////////
    always @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            h_counter <= 0;
            v_counter <= 0;
        end else begin
            if (h_counter < H_TOTAL - 1) begin
                h_counter <= h_counter + 1;
            end else begin
                h_counter <= 0;
                if (v_counter < V_TOTAL - 1) begin
                    v_counter <= v_counter + 1;
                end else begin
                    v_counter <= 0;
                end
            end
        end
    end

    ////////////////////////////////
    // HSYNC and VSYNC Generation
    ////////////////////////////////
    always @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            hsync <= 1;
            vsync <= 1;
        end else begin
            // HSYNC: Active low during the sync pulse
            hsync <= ~((h_counter >= H_DISPLAY + H_FRONT) &&
                       (h_counter < H_DISPLAY + H_FRONT + H_SYNC));
            // VSYNC: Active low during the sync pulse
            vsync <= ~((v_counter >= V_DISPLAY + V_FRONT) &&
                       (v_counter < V_DISPLAY + V_FRONT + V_SYNC));
        end
    end

    ////////////////////////////////
    // Data Output (1-bit Monochrome)
    ////////////////////////////////
    always @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            data <= 0;
        end else begin
            if (h_counter < H_DISPLAY && v_counter < V_DISPLAY) begin
                // Generate a checkerboard pattern for testing
                data <= (h_counter[4] ^ v_counter[4]);
            end else begin
                data <= 0; // Blank outside active video
            end
        end
    end

endmodule
