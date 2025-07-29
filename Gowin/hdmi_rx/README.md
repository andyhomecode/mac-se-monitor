# HDMI RX Project Setup
## Andy Maxwell - 2025-07-27

This project implements a complete HDMI receiver with:
- **Hot Plug Detect (HPD)** - Tells the source we're present
- **EDID Support** - Advertises our display capabilities (640x480@60Hz)
- **HDMI Data Reception** - Decodes RGB video data
- **Status LEDs** - Shows system status

## Files Created:
- `hdmi_rx.v` - Main HDMI receiver module
- `hdmi_rx_pins.cst` - Pin constraint file (needs DDC/HPD pin verification)
- `tb_hdmi_rx.v` - Testbench for simulation
- `../../../bram_initializer/edid_640x480_fixed.mi` - EDID initialization file

## Setup Steps:

### 1. Configure EDID PROM IP
1. In Gowin IDE, add the EDID_PROM IP core
2. Configure it to use the initialization file: `edid_640x480_fixed.mi`
3. Set memory depth to 256 bytes, data width to 8 bits

### 2. Configure DVI_RX IP  
1. Add the DVI_RX IP core
2. Configure for your target resolution (640x480 minimum support)
3. Enable differential TMDS inputs

### 3. Pin Assignments (CRITICAL - Verify with Schematic)
The constraint file has placeholder pins for DDC and HPD:
```verilog
IO_LOC "I_scl" XX;    # Find actual DDC clock pin
IO_LOC "IO_sda" XX;   # Find actual DDC data pin  
IO_LOC "O_hpd" XX;    # Find actual HPD output pin
```

**You MUST verify these pins from the Tang Nano 20K Dock schematic!**

### 4. Expected Behavior:
- **LED0**: Heartbeat (1Hz blink) - shows system running
- **LED1**: OFF when PLL phase locked, ON when not locked
- **LED2**: OFF when RX PLL locked, ON when not locked  
- **LED3**: ON during reset, OFF when running

### 5. Usage with Your Framebuffer:
The module outputs standard RGB signals you can connect to your framebuffer logic:
- `O_rgb_clk` - Pixel clock (varies with input resolution)
- `O_rgb_vs/hs` - Sync signals
- `O_rgb_de` - Data enable (marks valid pixel data)
- `O_rgb_r/g/b[7:0]` - 8-bit RGB pixel data

### 6. Testing Procedure:
1. Program the FPGA with this design
2. Connect HDMI source (PC/laptop) to the dock's HDMI input
3. Check LEDs:
   - LED0 should blink (heartbeat)
   - LED2&3 should go OFF when HDMI source locks
4. PC should detect the display as "Mac SE Monitor 640x480"

### 7. Integration with Your Main Project:
To integrate with your Mac SE framebuffer:
1. Connect `O_rgb_*` signals to your framebuffer write logic
2. Use `O_rgb_de` to gate pixel writes
3. Scale/crop from input resolution to 512x342 Mac SE format

## Troubleshooting:
- **No HDMI detection**: Check HPD pin assignment and DDC pins
- **LED2/3 stay ON**: HDMI input not connected or wrong pin assignments
- **PC doesn't see display**: EDID not loading - check I2C pins and EDID file

## Next Steps:
1. Verify and fix DDC/HPD pin assignments from schematic
2. Test with actual HDMI source
3. Integrate RGB outputs with your Mac SE framebuffer logic
