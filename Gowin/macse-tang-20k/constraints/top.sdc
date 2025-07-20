//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.01 Education (64-bit) 
//Created Time: 2025-07-20 13:13:30
create_clock -name rgb_odck -period 30 -waveform {0 15} [get_ports {rgb_odck}]
