// filepath: /hdmi_to_mac_se_converter_project/testbench/frame_buffer_tb.v
`timescale 1ns / 1ps

module frame_buffer_tb;

    // Parameters
    localparam BUFFER_WIDTH  = 512;
    localparam BUFFER_HEIGHT = 342;
    localparam ADDR_WIDTH    = $clog2(BUFFER_WIDTH * BUFFER_HEIGHT); // ~18 bits

    // Testbench Signals
    reg write_clk;
    reg write_enable;
    reg [ADDR_WIDTH-1:0] write_addr;
    reg write_data;                  // 1-bit scaled monochrome data
    reg read_clk;
    reg read_enable;
    reg [ADDR_WIDTH-1:0] read_addr;
    wire read_data;                  // 1-bit monochrome data
    reg reset;

    // Instantiate the frame_buffer module
    frame_buffer #(
        .BUFFER_WIDTH(BUFFER_WIDTH),
        .BUFFER_HEIGHT(BUFFER_HEIGHT),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) uut (
        .write_clk(write_clk),
        .write_enable(write_enable),
        .write_addr(write_addr),
        .write_data(write_data),
        .read_clk(read_clk),
        .read_enable(read_enable),
        .read_addr(read_addr),
        .read_data(read_data),
        .reset(reset)
    );

    // Clock generation
    initial begin
        write_clk = 0;
        read_clk = 0;
        forever begin
            #5 write_clk = ~write_clk; // 100MHz write clock
            #10 read_clk = ~read_clk;   // 50MHz read clock
        end
    end

    // Test sequence
    initial begin
        // Initialize signals
        reset = 1;
        write_enable = 0;
        read_enable = 0;
        write_addr = 0;
        write_data = 0;
        read_addr = 0;

        // Release reset
        #20 reset = 0;

        // Write test data to frame buffer
        write_enable = 1;
        for (integer i = 0; i < 10; i = i + 1) begin
            write_addr = i;
            write_data = i[0]; // Write alternating 0s and 1s
            #10; // Wait for a clock cycle
        end
        write_enable = 0;

        // Read back the data
        read_enable = 1;
        for (integer i = 0; i < 10; i = i + 1) begin
            read_addr = i;
            #10; // Wait for a clock cycle
            $display("Read Address: %d, Data: %b", read_addr, read_data);
        end
        read_enable = 0;

        // Finish simulation
        #50;
        $finish;
    end

endmodule // frame_buffer_tb