//Copyright (C)2014-2024 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.9.03 (64-bit) 
//Created Time: 2024-06-06 10:10:34
create_clock -name I_tmds_clk_p -period 12.579 -waveform {0 6.29} [get_ports {I_tmds_clk_p}] -add
create_clock -name hclkx5 -period 2.516 -waveform {0 1.258} [get_nets {DVI_RX_Top_inst/dvi2rgb_inst/hclkx5}] -add
create_clock -name I_clk -period 20 -waveform {0 10} [get_ports {I_clk}] -add
create_clock -name rx0_pclk -period 12.579 -waveform {0 6.29} [get_nets {rx0_pclk}] -add
set_clock_groups -exclusive -group [get_clocks {rx0_pclk}] -group [get_clocks {hclkx5}] -group [get_clocks {I_tmds_clk_p}]
