


def generate_framebuffer_test_file(filename, width=512, height=342):
    with open(filename, 'w') as f:
        # Write a header line indicating format and size
        f.write(f"#File_format=Bin\n")
        f.write(f"#Address_depth=175104\n")
        f.write(f"#Data_width=1\n")
        # Loop through each pixel
        for x in range(14592):  # divided by 12
            f.write(f"1\n")
            f.write(f"0\n")
            f.write(f"1\n")
            f.write(f"0\n")
            f.write(f"1\n")
            f.write(f"0\n")
            f.write(f"1\n")
            f.write(f"1\n")
            f.write(f"1\n")
            f.write(f"0\n")
            f.write(f"0\n")
            f.write(f"0\n")
 
# Call the function
generate_framebuffer_test_file('framebuffer_test_pattern.mi')
