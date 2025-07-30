# EDID validation script
# See if the generated VGA one seems to be valid
# run it against the GOWIN provided examples too
# test driven development, baby
import sys

edid_hex = []
for line in sys.stdin:
    line = line.strip()
    if line and not line.startswith('#'):
        tokens = line.strip().split()  # might be multiple tokens per line
        for token in tokens:
            edid_hex.append(int(token, 16))

print('EDID Validation Report:')
print(f'Total bytes: {len(edid_hex)}')
is_extended = len(edid_hex) == 256
base_block_size = 128

# Validate only the base block (first 128 bytes)
edid_base = edid_hex[:base_block_size]

# Check header
header = edid_base[0:8]
expected_header = [0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00]
print(f'Header valid: {header == expected_header}')

# Check manufacturer ID (bytes 8-9)
mfg = (edid_base[8] << 8) | edid_base[9]
mfg_chars = [chr(((mfg >> 10) & 0x1F) + ord('A') - 1), 
             chr(((mfg >> 5) & 0x1F) + ord('A') - 1), 
             chr((mfg & 0x1F) + ord('A') - 1)]
print(f'Manufacturer ID: {mfg:04X} = {"".join(mfg_chars)}')

print('\nMonitor Descriptors:')

# EDID detailed descriptors start at byte 54, each 18 bytes
for i in range(4):
    desc = edid_base[54 + 18*i : 54 + 18*(i+1)]
    if desc[0:3] == [0x00, 0x00, 0x00]:
        tag = desc[3]
        if tag == 0xFC:
            # Monitor Name
            name = ''.join(chr(c) for c in desc[5:18] if 32 <= c <= 126).strip()
            print(f'  Monitor Name (0xFC): "{name}"')
        elif tag == 0xFF:
            # Serial Number
            serial = ''.join(chr(c) for c in desc[5:18] if 32 <= c <= 126).strip()
            print(f'  Serial Number (0xFF): "{serial}"')
        elif tag == 0xFD:
            # Range Limits
            min_vrate = desc[5]
            max_vrate = desc[6]
            min_hrate = desc[7]
            max_hrate = desc[8]
            max_pixclk = desc[9] * 10  # in MHz
            print(f'  Range Limits (0xFD): {min_vrate}-{max_vrate} Hz vertical, {min_hrate}-{max_hrate} kHz horizontal, up to {max_pixclk} MHz pixel clock')
        else:
            print(f'  Descriptor {i+1}: Unknown tag 0x{tag:02X}')
    else:
        print(f'  Descriptor {i+1}: Timing descriptor (not metadata)')

# Check EDID version (bytes 18-19)
print(f'EDID Version: {edid_base[18]}.{edid_base[19]}')

# Check detailed timing descriptor 1 (bytes 54-71)
dtd1 = edid_base[54:72]
pixel_clock = (dtd1[1] << 8) | dtd1[0]
h_active = ((dtd1[4] & 0xF0) << 4) | dtd1[2]
h_blank = ((dtd1[4] & 0x0F) << 8) | dtd1[3]
v_active = ((dtd1[7] & 0xF0) << 4) | dtd1[5]
v_blank = ((dtd1[7] & 0x0F) << 8) | dtd1[6]

print(f'Detailed Timing Descriptor 1:')
print(f'  Pixel Clock: {pixel_clock * 10} kHz ({pixel_clock * 10 / 1000:.2f} MHz)')
print(f'  H Active: {h_active} pixels')
print(f'  H Blanking: {h_blank} pixels')
print(f'  V Active: {v_active} lines')  
print(f'  V Blanking: {v_blank} lines')
print(f'  Total H: {h_active + h_blank} pixels')
print(f'  Total V: {v_active + v_blank} lines')

# Calculate frame rate
h_total = h_active + h_blank
v_total = v_active + v_blank
frame_rate = (pixel_clock * 10000) / (h_total * v_total)
print(f'  Frame Rate: {frame_rate:.2f} Hz')

# Calculate and verify checksum for base block only
calculated_checksum = (256 - (sum(edid_base[:-1]) % 256)) % 256
actual_checksum = edid_base[127]
print(f'Base Block Checksum: calculated=0x{calculated_checksum:02X}, actual=0x{actual_checksum:02X}, valid={calculated_checksum == actual_checksum}')

if is_extended:
    # Check extension block checksum if present
    ext_block = edid_hex[128:256]
    ext_calculated_checksum = (256 - (sum(ext_block[:-1]) % 256)) % 256
    ext_actual_checksum = ext_block[127]
    print(f'Extension Block Checksum: calculated=0x{ext_calculated_checksum:02X}, actual=0x{ext_actual_checksum:02X}, valid={ext_calculated_checksum == ext_actual_checksum}')
    checksum_valid = (calculated_checksum == actual_checksum) and (ext_calculated_checksum == ext_actual_checksum)
else:
    checksum_valid = (calculated_checksum == actual_checksum)

# Check for standard resolutions
vga_standard = (h_active == 640 and v_active == 480 and 59 <= frame_rate <= 61)
svga_standard = (h_active == 800 and v_active == 600 and 59 <= frame_rate <= 61)
xga_standard = (h_active == 1024 and v_active == 768 and 59 <= frame_rate <= 61)
print(f'Standard VGA 640x480@60Hz: {vga_standard}')
print(f'Standard SVGA 800x600@60Hz: {svga_standard}')
print(f'Standard XGA 1024x768@60Hz: {xga_standard}')

print('\nEDID Compliance Summary:')
print(f'✓ Header: {"PASS" if header == expected_header else "FAIL"}')
print(f'✓ Length: {"PASS" if len(edid_hex) in [128, 256] else "FAIL"}')
print(f'✓ Checksum: {"PASS" if checksum_valid else "FAIL"}')
print(f'✓ Standard Resolution: {"PASS" if (vga_standard or svga_standard or xga_standard) else "FAIL"}')
print(f'✓ Manufacturer: {"PASS" if len("".join(mfg_chars)) == 3 else "FAIL"} ({"".join(mfg_chars)})')
print(f'✓ Extension Block: {"PRESENT" if is_extended else "NOT PRESENT"}')
