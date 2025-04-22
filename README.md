# Mac SE Modern Input Custom Video Card

## update 4/21: Updated timing generator with Classic II specs. Added scaler, color converter, and frame buffer logic.

## Project Overview

This project aims to create a custom video card for classic Macintosh SE, allowing modern HDMI video input to be displayed on the original monochrome Mac CRT monitor. Finally, I'll be able to watch youtubes on a low resolution monochrome curved monitor. 

## Features

- Preservation of original Mac SE monitor, case, powersupply for maximum retro-nerd
- Modern HDMI video input compatibility (800x600 60hz)
- Nearest-neighbor scaling from 800x600 to 512x342 resolution
- Monochrome conversion with simple RGB thresholding
- Frame buffer for cross time-domain output synchronization
- test pattern

## Hardware Components

- Macintosh SE (bad logic board)
- HDMI Decoder: TFP401
- FPGA: Tang Nano 20k (Gowin GW2A-18)
- connector for J12 (power for circuit and VIDEO, HSYNC, VSYNC input)
- panel mount HDMI connector
- FPGA 3.3v should be fine as inputs on analogue board are buffered through 74LS38 Quad 2-input NAND

## Timing Diagram

![Mac Classic II Timing Diagram](mac_classic_ii_timing.png)

### Display Characteristics
- Original Resolution: 512 × 342 pixels
- Monochrome display

### Key Modules
1. **Input Coordinate Generator**: Generates pixel coordinates from HDMI input signals (HSync, VSync, Data Enable).
2. **Color Converter**: Converts 24-bit RGB input to 1-bit monochrome using a simple thresholding method.
3. **Scaler**: Performs nearest-neighbor scaling from 800x600 to 512x342 resolution.
4. **Frame Buffer**: Stores scaled monochrome pixel data for synchronization with Mac SE timing.
5. **Mac SE Timing Generator**: Generates horizontal and vertical sync signals, active display region, and pixel coordinates for the Mac SE monitor.


## Development Stages

- Got the Arduino setting the PLL working. ✅
    Spent hours struggling because Claude couldn't set it right. 
    Found example code and just had Claude write the timing data, which worked.
- Got a first untested draft of the Verilog for the FPGA -- untested but compiled. ✅
    Spent an hour trying to mount the FPGA as a drive to drop the compiled .JED to it.
    Turns out I need a dumb USB-A to USB-C cable and that works. Actual USB-C doesn't.
-  Gave up on using external PLL since I got the Gowin internal clock working, no need for external PLL or Arduino to configure it
- Vibe coded huge hunks of Verilog based on ancient technical specifications.
- Implemented key Verilog modules:
    - **Mac SE Timing Generator**: Updated with Classic II specs.
    - **Scaler**: Nearest-neighbor scaling logic.
    - **Color Converter**: Simple RGB-to-monochrome thresholding.
    - **Frame Buffer**: Added BRAM instantiation for synchronization.
- TODO: Test the Verilog code on hardware.
- TODO: Verify timing and scaling accuracy.
- TODO: Integrate HDMI input and test full pipeline.

## Prerequisites


### Software/Tools
- Gowin FPGA Development Environment
- Oscilloscope
- Gemini 2.5 Pro (Experimental) (for vibe coding)
- Github Co-pilot

## Potential Challenges

- Precise timing synchronization
- Signal integrity maintenance
- Power management
- Resolution scaling
- Wrong timing might fry tube
- high voltage coil + capacitor might fry developer


## Disclaimer

This is an experimental project. Proceed with caution when modifying vintage hardware. And remember kids, electricity kills. Be very, very careful around the CRT.

## Contact
