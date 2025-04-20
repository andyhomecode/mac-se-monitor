/*
 * Module: switch_to_led
 * Description: Reads a single switch input and drives an LED output
 * to match the switch state. Assumes active-high logic
 * (switch ON = high signal, LED ON = high signal).
 */
module switch_to_led (
    // Input Port
    input wire switch_in,   // Signal coming from the physical switch

    // Output Port
    output wire led_out     // Signal going to the physical LED
);

    // Continuous assignment: Make the LED output signal identical
    // to the switch input signal at all times.
    assign led_out = switch_in;

endmodule