#!/usr/bin/env python3
"""
Generate 3D nameplate STL files from a list of names using OpenSCAD.

This script reads names from a text file and generates individual STL files
for each name using an OpenSCAD template.
"""

import subprocess
import os
import sys
from pathlib import Path


def generate_stl(name, template_file, output_dir):
    """
    Generate an STL file for a given name using OpenSCAD.

    Args:
        name: The name to put on the nameplate
        template_file: Path to the OpenSCAD template file
        output_dir: Directory where STL files will be saved
    """
    # Create a safe filename from the name (remove special characters)
    safe_name = "".join(c for c in name if c.isalnum() or c in (' ', '-', '_')).strip()
    safe_name = safe_name.replace(' ', '_')

    output_file = os.path.join(output_dir, f"{safe_name}.stl")

    # Escape quotes in the name for the command line
    escaped_name = name.replace('"', '\\"')

    # Build the OpenSCAD command
    # -D sets a variable, -o specifies output file
    cmd = [
        r'C:\Program Files\OpenSCAD\openscad.exe',
        '-D', f'name="{escaped_name}"',
        '-o', output_file,
        template_file
    ]

    print(f"Generating: {safe_name}.stl for '{name}'...")

    try:
        # Run OpenSCAD
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            check=True
        )
        print(f"  [OK] Successfully created {safe_name}.stl")
        return True
    except subprocess.CalledProcessError as e:
        print(f"  [ERROR] Error generating {safe_name}.stl")
        print(f"    {e.stderr}")
        return False
    except FileNotFoundError:
        print("Error: OpenSCAD not found. Please install OpenSCAD and ensure it's in your PATH.")
        print("Download from: https://openscad.org/downloads.html")
        sys.exit(1)


def main():
    # Configuration
    template_file = "nameplate_template.scad"
    names_file = "names.txt"
    output_dir = "output_stl"

    # Check if template exists
    if not os.path.exists(template_file):
        print(f"Error: Template file '{template_file}' not found!")
        sys.exit(1)

    # Check if names file exists
    if not os.path.exists(names_file):
        print(f"Error: Names file '{names_file}' not found!")
        sys.exit(1)

    # Create output directory if it doesn't exist
    Path(output_dir).mkdir(exist_ok=True)

    # Read names from file
    with open(names_file, 'r', encoding='utf-8') as f:
        names = [line.strip() for line in f if line.strip()]

    if not names:
        print(f"Error: No names found in '{names_file}'")
        sys.exit(1)

    print(f"Found {len(names)} name(s) to process")
    print(f"Output directory: {output_dir}")
    print("-" * 50)

    # Generate STL for each name
    success_count = 0
    for name in names:
        if generate_stl(name, template_file, output_dir):
            success_count += 1

    print("-" * 50)
    print(f"Complete! Generated {success_count}/{len(names)} STL files")
    print(f"Files saved in: {output_dir}/")


if __name__ == "__main__":
    main()
