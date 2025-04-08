# Mac SE Modern Video Input Conversion

## Project Overview

This project aims to create a custom video input solution for the classic Macintosh SE, allowing modern video input (VGA/HDMI) to be displayed on the original monochrome monitor. By utilizing an FPGA and custom signal conversion logic, we breathe new life into vintage Macintosh hardware.

## Features

- Modern video input compatibility (VGA/USB-C to VGA)
- Preservation of original Mac SE monitor functionality
- Custom signal conversion using FPGA technology
- Low-modification approach to vintage hardware

## Hardware Components

- Target Hardware: Macintosh SE
- Microcontroller: Arduino
- Clock Generator: SI5351 PLL
- FPGA: Lattice STEP-MXO2-LPC
- Developed online https://stepfpga.eimtechnology.com/project/3143/
- Input Interfaces: VGA/USB-C to VGA adapter

## Technical Specifications

### Display Characteristics
- Original Resolution: 512 × 342 pixels
- Monochrome display
- Unique vintage display timing requirements

### Signal Conversion Architecture
- Arduino-controlled clock generation
- FPGA-based signal translation
- Direct interface with original analog board connector

## Project Goals

1. Create a seamless video input solution for Mac SE
2. Minimize hardware modifications
3. Maintain original display characteristics
4. Support multiple modern video input sources

## Development Stages


- Got the Arduino setting the PLL working.  Check
    Spent hours struggling because Claude couldn't set it right. 
    Found example code and just had Claude write the timing data, which worked
- Got a first untested draft of the Verilog for the FPGA -- untested but compiled
    Spent an hour trying to mount the FPGA as a drive to drop the compiled .JED to it
    Turns out I need a dumb USB-A to USB-C cable and that works.  Actual USB-C doesn't
- TODO: Pick up from there and test the verilog code.
- TODO: Verilog code assumes 27mhz clock, currently 16.xxxmhz.  Change PLL.


## Prerequisites

### Hardware
- Macintosh SE with functional analog board
- Arduino board
- Lattice STEP-MXO2-LPC FPGA
- SI5351 PLL Clock Generator
- VGA/USB-C to VGA adapter

### Software/Tools
- Arduino IDE
- FPGA Development Environment (Lattice Diamond)
- Signal analysis tools
- Oscilloscope (recommended)

## Potential Challenges

- Precise timing synchronization
- Signal integrity maintenance
- Power management
- Resolution scaling
- Minimal vintage hardware disruption


## Contributing

Interested in contributing? Great! Please:
- Fork the repository
- Create a feature branch
- Submit pull requests
- Follow existing code style

## Acknowledgments

- Vintage Mac preservation community
- Open-source hardware enthusiasts
- Retro computing researchers

## Disclaimer

This is an experimental project. Proceed with caution when modifying vintage hardware. Always backup and protect original components.

## Contact
