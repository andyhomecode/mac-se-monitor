import argparse

# Vibe Coded by ANDY MAXWELL 2025 07 27  
# produces a COMPLIANT EDID initializer file format for GOWIN FPGA IP Core BSRAM
# generates a properly formatted EDID block for 640x480@60Hz display  
# based on working 800x600 and 1024x768 reference EDIDs
# part of the Mac SE HDMI video card project

# this one is the working version.

def generate_edid_framebuffer(output_filename):
    # VGA 640x480@59.94Hz EDID - properly encoded using standard VGA timing
    # Based on VESA CVT standard timing: 25.175MHz pixel clock
    edid_data = [
        # EDID Header (8 bytes) - Standard signature
        0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00,
        
        # Vendor & Product Identification (10 bytes)
        0x06, 0x10,  # Manufacturer ID: Apple Computer Inc (PNP ID "APP")  
        0x40, 0x00,  # Product code: 0x0040
        0x00, 0x00, 0x00, 0x00,  # Serial number: 0
        0x01,        # Week of manufacture: 1
        0x20,        # Year of manufacture: 2022 (1990 + 32)
        
        # EDID Structure Version (2 bytes)
        0x01, 0x03,  # EDID 1.3
        
        # Basic Display Parameters (5 bytes)
        0x80,        # Digital input, DVI compliant
        0x1E,        # Max horizontal image size: 30cm
        0x17,        # Max vertical image size: 23cm 
        0x78,        # Display gamma: 2.2 (120 = (gamma*100)-100)
        0x0A,        # Feature support: RGB 4:4:4, no preferred timing
        
        # Color Characteristics (10 bytes) - Standard sRGB
        0xEE, 0x91, 0xA3, 0x54, 0x4C, 0x99, 0x26, 0x0F, 0x50, 0x54,
        
        # Established Timings (3 bytes)
        0x21, 0x00, 0x00,  # 640x480@60Hz (bit 5 of byte 0)
        
        # Standard Timings (16 bytes) - All unused (0x0101 = unused)
        0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
        0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01,
    ]
    
    # Verify base structure is 54 bytes
    assert len(edid_data) == 54, f"Base EDID should be 54 bytes, got {len(edid_data)}"
    
    # Detailed Timing Descriptor 1: VGA 640x480@59.94Hz (18 bytes)
    # VESA CVT timing: 25.175MHz, 640x480, 60Hz nominal
    # Horizontal: 640 + 16 + 96 + 48 = 800 total
    # Vertical: 480 + 10 + 2 + 33 = 525 total  
    # Frame rate: 25.175MHz / (800 * 525) = 59.94Hz
    
    # Detailed Timing Descriptor format (18 bytes):
    # Byte 0-1: Pixel clock / 10000 (little endian)
    # Byte 2: H active low 8 bits
    # Byte 3: H blanking low 8 bits  
    # Byte 4: H active[11:8] (upper 4 bits) | H blanking[11:8] (lower 4 bits)
    # Byte 5: V active low 8 bits
    # Byte 6: V blanking low 8 bits
    # Byte 7: V active[11:8] (upper 4 bits) | V blanking[11:8] (lower 4 bits)
    # Byte 8: H sync offset low 8 bits
    # Byte 9: H sync pulse width low 8 bits
    # Byte 10: V sync offset (upper 4 bits) | V sync pulse width (lower 4 bits)
    # Byte 11: H sync offset[9:8] | H sync width[9:8] | V sync offset[3:2] | V sync width[3:2]
    # Byte 12: H image size low 8 bits
    # Byte 13: V image size low 8 bits
    # Byte 14: H image size[11:8] (upper 4 bits) | V image size[11:8] (lower 4 bits)
    # Byte 15: H border
    # Byte 16: V border
    # Byte 17: Features
    
    dtd1 = [
        # 0-1: Pixel clock: 25.175MHz = 25175kHz, EDID format = 25175/10 = 2517.5 ≈ 2518
        # 2518 = 0x09D6, stored little-endian
        0xD6, 0x09,
        
        # 2: H active low 8 bits: 640 = 0x280, low 8 bits = 0x80
        0x80,
        
        # 3: H blanking low 8 bits: 160 = 0xA0
        0xA0,
        
        # 4: H active[11:8] | H blanking[11:8]: (640>>8)<<4 | (160>>8) = 2<<4 | 0 = 0x20
        0x20,
        
        # 5: V active low 8 bits: 480 = 0x1E0, low 8 bits = 0xE0
        0xE0,
        
        # 6: V blanking low 8 bits: 45 = 0x2D
        0x2D,
        
        # 7: V active[11:8] | V blanking[11:8]: (480>>8)<<4 | (45>>8) = 1<<4 | 0 = 0x10
        0x10,
        
        # 8: H sync offset low 8 bits: 16 = 0x10
        0x10,
        
        # 9: H sync pulse width low 8 bits: 96 = 0x60
        0x60,
        
        # 10: V sync offset (upper 4) | V sync pulse width (lower 4): 10<<4 | 2 = 0xA2
        0xA2,
        
        # 11: High bits for sync timing (all fit in 8 bits, so 0x00)
        0x00,
        
        # 12-13: Image size: 30cm, 23cm
        0x1E, 0x17,
        
        # 14: Image size high bits (both fit in 8 bits, so 0x00)
        0x00,
        
        # 15-16: Borders (none)
        0x00, 0x00,
        
        # 17: Features
        0x1E,
    ]  # Total: 18 bytes exactly
    
    assert len(dtd1) == 18, f"DTD1 must be 18 bytes, got {len(dtd1)}"
    print(f"DTD1 length: {len(dtd1)} bytes")
    # Add DTD1 to EDID data
    edid_data.extend(dtd1)
    print(f"After DTD1: {len(edid_data)} bytes")
    
    # Detailed Timing Descriptor 2: Monitor Name (18 bytes)
    dtd2 = [
        0x00, 0x00, 0x00, 0xFC, 0x00,  # Monitor name descriptor tag (5 bytes)
        ord('M'), ord('a'), ord('c'), ord(' '), ord('S'), ord('E'), ord(' '),  # "Mac SE " (7 bytes)
        ord('M'), ord('o'), ord('n'), ord('i'), ord('t'), ord('o'),  # "Monito" (6 bytes = 18 total)
    ]
    print(f"DTD2 length: {len(dtd2)} bytes")
    edid_data.extend(dtd2)
    print(f"After DTD2: {len(edid_data)} bytes")
    
    # Detailed Timing Descriptor 3: Range Limits (18 bytes)
    dtd3 = [
        0x00, 0x00, 0x00, 0xFD, 0x00,  # Range limits descriptor tag (5 bytes)
        0x38, 0x4B,  # Vertical freq range: 56-75 Hz (2 bytes)
        0x1E, 0x50,  # Horizontal freq range: 30-80 kHz (2 bytes)
        0x0E,        # Max pixel clock: 140 MHz / 10 (1 byte)
        0x00,        # No secondary GTF curve support (1 byte)
        0x0A, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,  # Padding (7 bytes = 18 total)
    ]
    print(f"DTD3 length: {len(dtd3)} bytes")
    edid_data.extend(dtd3)
    print(f"After DTD3: {len(edid_data)} bytes")
    
    # Detailed Timing Descriptor 4: Dummy/Unused (18 bytes)
    dtd4 = [0x00] * 18
    dtd4[3] = 0x10  # Dummy descriptor tag
    edid_data.extend(dtd4)
    print(f"After DTD4: {len(edid_data)} bytes")
    
    # We should have exactly 126 bytes now (before extension count)
    print(f"Before extension count: {len(edid_data)} bytes")
    
    # Extension count (byte 126) - 1 extension block
    edid_data.append(0x01)  # One extension block
    print(f"After extension count: {len(edid_data)} bytes")
    
    # Calculate checksum for base block (bytes 0-126), then add as byte 127
    checksum = (256 - (sum(edid_data) % 256)) % 256
    edid_data.append(checksum)
    print(f"Base block complete: {len(edid_data)} bytes")
    
    # CEA-861 Extension Block (128 bytes)
    extension_block = [
        0x02,  # CEA-861 extension tag
        0x03,  # Revision number
        0x04,  # DTD offset (start of detailed timing descriptors)
        0x00,  # No native formats, no basic audio, no YCbCr
    ]
    
    # Padding to fill extension block to 127 bytes  
    extension_block.extend([0x00] * (127 - len(extension_block)))
    
    # Calculate extension block checksum
    ext_checksum = (256 - (sum(extension_block) % 256)) % 256
    extension_block.append(ext_checksum)
    
    # Add extension block to EDID
    edid_data.extend(extension_block)
    print(f"Final EDID length: {len(edid_data)} bytes")
    
    # Verify we have exactly 256 bytes (128 + 128)
    print(f"Debug: EDID length = {len(edid_data)} bytes")
    assert len(edid_data) == 256, f"EDID must be exactly 256 bytes, got {len(edid_data)}"
    
    # Write to file in Gowin BRAM format  
    with open(output_filename, 'w') as f:
        f.write("#File_format=Hex\n")
        f.write("#Address_depth=256\n")  # 256 bytes for dual-block EDID
        f.write("#Data_width=8\n")
        
        for byte_val in edid_data:
            f.write(f"{byte_val:02X}\n")

def main():
    parser = argparse.ArgumentParser(description="Generate compliant VGA 640x480@60Hz EDID for Gowin BRAM.")
    parser.add_argument("output_filename", help="Output .mi file path")
    args = parser.parse_args()
    
    generate_edid_framebuffer(args.output_filename)
    print(f"Compliant VGA EDID generated: {args.output_filename}")
    print("640x480@59.94Hz, 25.175MHz pixel clock, Apple manufacturer ID")

if __name__ == "__main__":
    main()
