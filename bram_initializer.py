import argparse
from PIL import Image  # Pillow is the modern replacement for PIL

def generate_framebuffer_from_bmp(input_bmp, output_filename):
    # Open the BMP file
    img = Image.open(input_bmp).convert('1')  # Convert to black and white
    width, height = img.size

    if width != 512 or height != 342:
        raise ValueError("Input BMP must be 512x342 in size.")

    # Open the output file
    with open(output_filename, 'w') as f:
        # Write the header
        f.write(f"#File_format=Bin\n")
        f.write(f"#Address_depth={width * height}\n")
        f.write(f"#Data_width=1\n")

        # Write pixel data
        for y in range(height):
            for x in range(width):
                pixel = img.getpixel((x, y))  # Get pixel value (0 or 255)
                f.write(f"{1 if pixel == 255 else 0}\n")  # Write 1 for white, 0 for black
            # f.write("\n")  # Newline after each row

def main():
    parser = argparse.ArgumentParser(description="Generate framebuffer test file from a BMP image.")
    parser.add_argument("input_bmp", help="Path to the input BMP file (must be 512x342 and black-and-white).")
    parser.add_argument("output_filename", help="Path to the output file to generate.")
    args = parser.parse_args()

    generate_framebuffer_from_bmp(args.input_bmp, args.output_filename)

if __name__ == "__main__":
    main()
