// filepath: /hdmi_to_mac_se_converter_project/hdmi_to_mac_se_converter_project/src/input_coordinate_generator.v
//////////////////////////////////////////////////////////////////////////////////
// Module: input_coordinate_generator
// Description:
// This module generates the x and y coordinates based on the input signals from
// the HDMI source. It outputs valid pixel coordinates and a validity signal.
//////////////////////////////////////////////////////////////////////////////////
module input_coordinate_generator #(
    parameter H_ACTIVE = 800,
    parameter V_ACTIVE = 600
) (
    input wire clk,   // TFP401 pixel clock
    input wire reset,
    input wire hs,    // TFP401 HSync
    input wire vs,    // TFP401 VSync
    input wire de,    // TFP401 Data Enable
    output reg valid_out, // Active pixel indicator
    output reg [$clog2(H_ACTIVE)-1:0] x_out,
    output reg [$clog2(V_ACTIVE)-1:0] y_out
);

    // Internal counters
    reg [$clog2(H_ACTIVE)-1:0] h_counter;
    reg [$clog2(V_ACTIVE)-1:0] v_counter;

    initial begin
        valid_out = 1'b0;
        x_out = 0;
        y_out = 0;
        h_counter = 0;
        v_counter = 0;
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            h_counter <= 0;
            v_counter <= 0;
            valid_out <= 1'b0;
        end else begin
            if (hs) begin
                h_counter <= 0; // Reset horizontal counter on HSync
                if (v_counter < V_ACTIVE) begin
                    v_counter <= v_counter + 1; // Increment vertical counter
                end
            end else if (de) begin
                valid_out <= 1'b1; // Set valid output when data is enabled
                x_out <= h_counter; // Output current horizontal coordinate
                y_out <= v_counter; // Output current vertical coordinate
                h_counter <= h_counter + 1; // Increment horizontal counter
            end else begin
                valid_out <= 1'b0; // Reset valid output when not enabled
            end
        end
    end

endmodule // input_coordinate_generator