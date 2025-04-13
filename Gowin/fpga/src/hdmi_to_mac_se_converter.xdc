# Constraints file for hdmi_to_mac_se_converter project

# Define the clock signal
set_property PACKAGE_PIN A1 [get_ports {mac_se_clk_in}]
set_property IOSTANDARD LVCMOS33 [get_ports {mac_se_clk_in}]

# Define the pixel clock output
set_property PACKAGE_PIN B1 [get_ports {mac_se_pixel_clk}]
set_property IOSTANDARD LVCMOS33 [get_ports {mac_se_pixel_clk}]

# Define the horizontal sync output
set_property PACKAGE_PIN C1 [get_ports {mac_se_hsync}]
set_property IOSTANDARD LVCMOS33 [get_ports {mac_se_hsync}]

# Define the vertical sync output
set_property PACKAGE_PIN D1 [get_ports {mac_se_vsync}]
set_property IOSTANDARD LVCMOS33 [get_ports {mac_se_vsync}]

# Define the monochrome video data output
set_property PACKAGE_PIN E1 [get_ports {mac_se_data}]
set_property IOSTANDARD LVCMOS33 [get_ports {mac_se_data}]

# Define the reset signal
set_property PACKAGE_PIN F1 [get_ports {reset}]
set_property IOSTANDARD LVCMOS33 [get_ports {reset}]