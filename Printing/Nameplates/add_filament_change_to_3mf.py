#!/usr/bin/env python3
"""
Add M600 filament change command to all objects in an Orca Slicer 3MF file.

This script modifies a 3MF file (which is a ZIP archive containing XML) to add
a height range modifier at 1.5mm (end of blue base layer) with M600 command
for all zipper pull objects.

Usage:
    python add_filament_change_to_3mf.py input.3mf [output.3mf]

    If output.3mf is not specified, creates input_modified.3mf
"""

import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path
import shutil
import tempfile
import os


def add_height_range_to_3mf(input_file, output_file=None, height_mm=1.5):
    """
    Add height range modifier with M600 at specified height to all objects in 3MF.

    Args:
        input_file: Path to input 3MF file
        output_file: Path to output 3MF file (optional)
        height_mm: Height in mm where filament change occurs (default: 1.5)
    """
    input_path = Path(input_file)

    if not input_path.exists():
        print(f"Error: Input file '{input_file}' not found!")
        return False

    # Determine output filename
    if output_file is None:
        output_path = input_path.parent / f"{input_path.stem}_modified.3mf"
    else:
        output_path = Path(output_file)

    print(f"Processing: {input_path}")
    print(f"Output will be: {output_path}")
    print(f"Filament change height: {height_mm}mm")
    print("-" * 50)

    # Create a temporary directory to work in
    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)

        # Extract the 3MF (it's a ZIP file)
        print("Extracting 3MF file...")
        with zipfile.ZipFile(input_path, 'r') as zip_ref:
            zip_ref.extractall(temp_path)

        # Find and modify the 3D model file (usually 3D/3dmodel.model)
        model_file = temp_path / "3D" / "3dmodel.model"

        if not model_file.exists():
            print("Error: Could not find 3dmodel.model in 3MF file!")
            return False

        print(f"Modifying {model_file}...")

        # Parse the XML
        tree = ET.parse(model_file)
        root = tree.getroot()

        # Define namespaces (3MF uses namespaces)
        namespaces = {
            '': 'http://schemas.microsoft.com/3dmanufacturing/core/2015/02',
            'p': 'http://schemas.microsoft.com/3dmanufacturing/production/2015/06',
            's': 'http://schemas.orca-3d.com/3mf/2023/06'
        }

        # Register namespaces for output
        for prefix, uri in namespaces.items():
            if prefix:
                ET.register_namespace(prefix, uri)
            else:
                ET.register_namespace('', uri)

        # Find all objects (build items)
        # In Orca Slicer 3MF, objects are in <build><item> tags
        build_elem = root.find('.//build', namespaces)

        if build_elem is None:
            print("Warning: No <build> element found. Looking for items directly...")
            items = root.findall('.//item', namespaces)
        else:
            items = build_elem.findall('.//item', namespaces)

        if not items:
            print("Error: No items found in 3MF file!")
            return False

        print(f"Found {len(items)} object(s) in the file")

        # Count modified items
        modified_count = 0

        # Add height range modifier to each item
        for idx, item in enumerate(items, 1):
            object_id = item.get('objectid', f'unknown_{idx}')
            print(f"  Processing object {idx}/{len(items)} (ID: {object_id})...")

            # Check if this item already has metadata for height range
            # In Orca Slicer, this is typically stored as metadata
            # We need to add the height range modifier metadata

            # Note: The exact XML structure for height range modifiers in Orca Slicer
            # may vary. This is a generic approach that adds metadata.
            # You may need to adjust based on actual Orca Slicer 3MF structure.

            # Create or find metadata container
            metadata_group = item.find('metadatagroup', namespaces)
            if metadata_group is None:
                metadata_group = ET.SubElement(item, 'metadatagroup')

            # Add height range modifier metadata
            # Format: height range from 0 to height_mm = blue (original)
            #         height range from height_mm to top = white (with M600)

            height_modifier = ET.SubElement(metadata_group, 'metadata')
            height_modifier.set('name', 'height_range_modifier')
            height_modifier.text = f'{{"ranges":[{{"min":0,"max":{height_mm},"color":"RoyalBlue"}},{{"min":{height_mm},"max":999,"color":"white","gcode":"M600"}}]}}'

            modified_count += 1

        print(f"\nModified {modified_count} object(s)")

        # Save the modified XML back to the file
        print("Saving modified model file...")
        tree.write(model_file, encoding='utf-8', xml_declaration=True)

        # Re-create the 3MF (ZIP) file with all contents
        print("Creating new 3MF file...")
        with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zip_out:
            # Walk through the temp directory and add all files
            for root_dir, dirs, files in os.walk(temp_path):
                for file in files:
                    file_path = Path(root_dir) / file
                    arcname = file_path.relative_to(temp_path)
                    zip_out.write(file_path, arcname)

        print(f"\nSuccess! Modified 3MF saved to: {output_path}")
        print(f"\nNext steps:")
        print(f"1. Open {output_path.name} in Orca Slicer")
        print(f"2. Verify the height range modifiers are present")
        print(f"3. Slice and check for M600 commands in the G-code")
        return True


def main():
    if len(sys.argv) < 2:
        print("Usage: python add_filament_change_to_3mf.py input.3mf [output.3mf]")
        print("\nAdds M600 filament change at 1.5mm to all objects in a 3MF file.")
        print("If output.3mf is not specified, creates input_modified.3mf")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None

    success = add_height_range_to_3mf(input_file, output_file)

    if not success:
        sys.exit(1)


if __name__ == "__main__":
    main()
