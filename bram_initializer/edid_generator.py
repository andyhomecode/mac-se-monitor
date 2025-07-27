import argparse

# Vibe Coded by ANDY MAXWELL 2025 07 27
# produces the EDID initializer file format for GOWIN FPGA IP Core BSRAM
# generates a standard EDID block for 640x480@60Hz display
# part of the Mac SE HDMI video card project

def generate_edid_framebuffer(output_filename):
    # Standard EDID block for 640x480@60Hz display (VGA standard)
    # This is a basic EDID that should work with most HDMI sources
    edid_data = [
        # Header (8 bytes) - EDID signature
        0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00,
        
        # Vendor & Product ID (10 bytes)
        0x06, 0x10,  # Manufacturer ID (Apple Computer Inc - PNP ID "APP")
        0x00, 0x40,  # Product code
        0x00, 0x00, 0x00, 0x00,  # Serial number
        0x01,        # Week of manufacture
        0x20,        # Year of manufacture (2022 + 1990 = 2012, adjust as needed)
        
        # EDID Version (2 bytes)
        0x01, 0x03,  # EDID 1.3
        
        # Basic Display Parameters (5 bytes)
        0x80,        # Digital input, no sync on green
        0x22,        # Horizontal screen size in cm (34cm ~= 13.4")
        0x1B,        # Vertical screen size in cm (27cm ~= 10.6")
        0x78,        # Display gamma (2.2)
        0x0A,        # Features bitmap
        
        # Color Characteristics (10 bytes) - standard sRGB
        0xEE, 0x91, 0xA3, 0x54, 0x4C, 0x99, 0x26, 0x0F, 0x50, 0x54,
        
        # Established Timings (3 bytes)
        0x00, 0x00, 0x00,  # No established timings
        
        # Standard Timings (16 bytes) - all unused
        0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
        0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
        
        # Detailed Timing Descriptor 1 (18 bytes) - 640x480@60Hz
        0x40, 0x19,  # Pixel clock (6528 / 10 = 652.8 -> 0x1940 little endian)
        0x80, 0x02,  # Horizontal active pixels (640)
        0xA0,        # Horizontal blanking (160)
        0x12,        # Horizontal active high byte | blanking high
        0xE0, 0x01,  # Vertical active lines (480)
        0x2D,        # Vertical blanking (45)
        0x10,        # Vertical active high | blanking high
        0x10,        # Horizontal sync offset (16)
        0x60,        # Horizontal sync pulse width (96)
        0x13,        # Vertical sync offset (1) | pulse width (3)
        0x00,        # Sync info high bits
        0x1E, 0x11,  # Horizontal/vertical image size (mm)
        0x00,        # Horizontal border
        0x00,        # Vertical border
        0x1E,        # Features (non-interlaced, normal display)
        
        # Detailed Timing Descriptor 2 (18 bytes) - Monitor name
        0x00, 0x00, 0x00, 0xFC, 0x00,  # Display name tag
        ord('M'), ord('a'), ord('c'), ord(' '), ord('S'), ord('E'), ord(' '), 
        ord('M'), ord('o'), ord('n'), ord('i'), ord('t'), ord('o'), ord('r'),
        
        # Detailed Timing Descriptor 3 (18 bytes) - Range limits
        0x00, 0x00, 0x00, 0xFD, 0x00,  # Range limits tag
        0x38, 0x4B,  # Vertical freq range (56-75 Hz)
        0x1E, 0x51,  # Horizontal freq range (30-81 kHz)
        0x0E,        # Max pixel clock (140 MHz / 10)
        0x00,        # No extended timing info
        0x0A, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,  # Padding
        
        # Detailed Timing Descriptor 4 (18 bytes) - Unused
        0x00, 0x00, 0x00, 0x10, 0x00,  # Dummy descriptor
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00,
        
        # Extension flag & checksum will be calculated below
        0x00,  # No extensions
        0x00   # Checksum placeholder
    ]
    
    # Calculate checksum (sum of all bytes should equal 0)
    checksum = (256 - (sum(edid_data[:-1]) % 256)) % 256
    edid_data[-1] = checksum
    
    # Open the output file
    with open(output_filename, 'w') as f:
        # Write the header for Gowin BRAM format
        f.write(f"#File_format=Hex\n")
        f.write(f"#Address_depth=128\n")  # EDID is 128 bytes
        f.write(f"#Data_width=8\n")
        
        # Write EDID data in hex format
        for byte_val in edid_data:
            f.write(f"{byte_val:02X}\n")

def main():
    parser = argparse.ArgumentParser(description="Generate EDID BRAM initializer file for 640x480@60Hz display.")
    parser.add_argument("output_filename", help="Path to the output .mi file to generate.")
    args = parser.parse_args()
    
    generate_edid_framebuffer(args.output_filename)
    print(f"EDID file generated: {args.output_filename}")
    print("This EDID represents a 640x480@60Hz display named 'Mac SE Monitor' (Apple)")

if __name__ == "__main__":
    main()
