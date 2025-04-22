# Mac SE Modern Input Custom Video Card

## update 4/21: Updated timing generator with Classic II specs. Added scaler, color converter, and frame buffer logic.

## Project Overview

This project aims to create a custom video card for classic Macintosh SE, allowing modern HDMI video input to be displayed on the original monochrome Mac CRT monitor. Finally, I'll be able to watch youtubes on a low resolution monochrome curved monitor. 

## Features

- Modern video input compatibility (HDMI via TFP401 decoder)
- Preservation of original Mac SE monitor functionality
- Custom signal conversion using FPGA technology
- Nearest-neighbor scaling from 800x600 to 512x342 resolution
- Monochrome conversion with simple RGB thresholding
- Frame buffer for cross time-domain output synchronization
- Low-modification approach to vintage hardware by using existing connectors

## Hardware Components

- Macintosh SE
- HDMI Decoder: TFP401
- FPGA: Tang Nano 20k (Gowin GW2A-18)

## Timing Diagram

Horizontal Timing (One Full Line - 704 Clocks - Updated Values)

<pre>
Clock Cycle: -->
             0       110      178                           689 690      703 704 (End/Start)
             |<--Pulse-->|<--Back Porch-->|<-----Active Pixels----->|<Front Porch>| Total=704 clks |
             |          |        |                             |   |        |   |
             ▼          ▼        ▼                             ▼   ▼        ▼   ▼
HSYNC:      _|__________|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|_           (Next Line)
Signal      <-- LOW ---> <----------------------- HIGH ------------------------> LOW

ACTIVE:     ____________|________|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|________|________           (Next Line)
Signal      LOW          LOW      <----------- HIGH ------------->   LOW      LOW
            <------------------ Horizontal Blanking ---------------> <- H Blank ->
                                  <------ Active Pixel Window ------>
</pre>

- HSYNC: Goes LOW for the first 110 clocks, then HIGH for the remaining 594 clocks.
- ACTIVE: (Assuming the current line is vertically active) Goes HIGH only during the Active Pixel Window (clocks 178-689). It's LOW during the HSYNC pulse (0-109), Back Porch (110-177), and Front Porch (690-703).

Vertical Timing (One Full Frame - 370 Lines - No Change)

<pre>
Line Number: -->
             0       3 4                27 28                                  369 370 (End/Start)
             |<--Pulse-->|<---- VBLANK ---->|<----------- Active Lines ----------->| Total=370 Lines|
             |       | |                |  |                                    |   |
             ▼       ▼ ▼                ▼  ▼                                    ▼   ▼
VSYNC:      _|_______|_|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|_          (Next Frame)
Signal      <-- LOW --> <-------------------------- HIGH ------------------------> LOW

ACTIVE:     <-------------------------- LOW ------------------------------------->          (Next Frame)
(Vertical
 Component)  <---- Vertical Blanking ------> <------------- HIGH ----------------->
             Line 0-27: VBLANK             Line 28-369: ACTIVE FRAME
             (ACTIVE output is LOW)        (ACTIVE follows horizontal pattern)

</pre>
- VSYNC: Goes LOW for the first 4 lines (Lines 0-3), then HIGH.
- ACTIVE (Vertical Component): Only allows the ACTIVE output to be potentially HIGH during Lines 28-369.

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
- Gemini 2.5 Pro (Experimental)
- Github Co-pilot

## Potential Challenges

- Precise timing synchronization
- Signal integrity maintenance
- Power management
- Resolution scaling
- Minimal vintage hardware disruption

## Contributing

## Disclaimer

This is an experimental project. Proceed with caution when modifying vintage hardware. And remember kids, electricity kills. Be very, very careful around the CRT.

## Contact
