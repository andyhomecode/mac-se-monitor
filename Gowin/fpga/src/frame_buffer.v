// filepath: /hdmi_to_mac_se_converter_project/hdmi_to_mac_se_converter_project/src/frame_buffer.v
//////////////////////////////////////////////////////////////////////////////////
// Module: frame_buffer
// Description:
// This module acts as a dual-port memory for storing pixel data. It handles
// writing and reading operations based on the selected clock domain and control signals.
//////////////////////////////////////////////////////////////////////////////////

module frame_buffer #(
    parameter BUFFER_WIDTH  = 512,
    parameter BUFFER_HEIGHT = 342,
    parameter ADDR_WIDTH    = $clog2(BUFFER_WIDTH * BUFFER_HEIGHT) // ~18 bits
) (
    // Write Side (Input/Scaler OR Output Clock Domain depending on test_mode_switch)
    input wire write_clk,
    input wire write_enable,
    input wire [ADDR_WIDTH-1:0] write_addr,
    input wire write_data,                  // 1-bit scaled monochrome data
    // Read Side (Output Clock Domain)
    input wire read_clk,
    input wire read_enable,
    input wire [ADDR_WIDTH-1:0] read_addr,
    output wire read_data,                  // 1-bit monochrome data
    // System Reset
    input wire reset
);

    // Dual-port RAM declaration
    reg [1:0] ram [0:BUFFER_WIDTH * BUFFER_HEIGHT - 1]; // 1-bit storage for each pixel

    // Write operation
    always @(posedge write_clk) begin
        if (write_enable) begin
            ram[write_addr] <= write_data; // Write data to RAM
        end
    end

    // Read operation
    assign read_data = (read_enable) ? ram[read_addr] : 1'b0; // Read data from RAM

endmodule // frame_buffer