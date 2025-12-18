#!/usr/bin/env python3
"""
Add M600 filament change to Orca Slicer 3MF file.

Based on actual Orca Slicer format analysis.
Adds global height_range_modifier metadata that applies to all objects.

Usage:
    python add_height_modifier_orca.py input.3mf [output.3mf]
"""

import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path
import tempfile
import os


def add_height_modifier(input_file, output_file=None, height_mm=1.5):
    """
    Add height range modifier metadata to 3MF file.

    Args:
        input_file: Path to input 3MF file
        output_file: Path to output 3MF file (optional)
        height_mm: Height in mm where filament change occurs
    """
    input_path = Path(input_file)

    if not input_path.exists():
        print(f"Error: Input file '{input_file}' not found!")
        return False

    if output_file is None:
        output_path = input_path.parent / f"{input_path.stem}_modified.3mf"
    else:
        output_path = Path(output_file)

    print(f"Processing: {input_path}")
    print(f"Output: {output_path}")
    print(f"Filament change at: {height_mm}mm")
    print("-" * 60)

    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)

        # Extract 3MF
        print("Extracting 3MF...")
        with zipfile.ZipFile(input_path, 'r') as zip_ref:
            zip_ref.extractall(temp_path)

        # Find model file
        model_file = temp_path / "3D" / "3dmodel.model"
        if not model_file.exists():
            print("Error: Could not find 3dmodel.model!")
            return False

        print("Modifying model file...")

        # Parse XML
        tree = ET.parse(model_file)
        root = tree.getroot()

        # Register namespaces
        namespaces = {
            '': 'http://schemas.microsoft.com/3dmanufacturing/core/2015/02',
            'BambuStudio': 'http://schemas.bambulab.com/package/2021',
            'p': 'http://schemas.microsoft.com/3dmanufacturing/production/2015/06'
        }

        for prefix, uri in namespaces.items():
            if prefix:
                ET.register_namespace(prefix, uri)
            else:
                ET.register_namespace('', uri)

        # Find or create metadata section (should be at root level, before <resources>)
        # Check if height_range_modifier already exists
        existing_modifier = None
        for metadata in root.findall('.//metadata[@name="height_range_modifier"]', namespaces):
            existing_modifier = metadata
            break

        if existing_modifier is not None:
            print("  Found existing height_range_modifier, replacing...")
            root.remove(existing_modifier)

        # Create the height range modifier metadata
        # Format: JSON string - we'll manually insert it to avoid auto-escaping
        metadata_json = (
            '{"ranges":['
            f'{{"min":0,"max":{height_mm},"color":"RoyalBlue"}},'
            f'{{"min":{height_mm},"max":999,"color":"white","gcode":"M600"}}'
            ']}'
        )

        # Create metadata element - we'll manually set the text with proper escaping
        metadata_elem = ET.Element('metadata')
        metadata_elem.set('name', 'height_range_modifier')
        # Don't use .text = ... as it will auto-escape
        # We'll replace this after writing

        # Insert after the last existing metadata element (before <resources>)
        resources = root.find('.//resources', namespaces)
        if resources is not None:
            resources_index = list(root).index(resources)
            root.insert(resources_index, metadata_elem)
        else:
            # No resources found, just append
            root.append(metadata_elem)

        print(f"  Added height_range_modifier metadata")
        print(f"    Blue layer: 0mm to {height_mm}mm")
        print(f"    White layer: {height_mm}mm to top (with M600)")

        # Save modified XML
        tree.write(model_file, encoding='utf-8', xml_declaration=True)

        # Post-process the file to fix the escaping
        # Python's ET auto-escapes, but we need &amp;quot; not &amp;amp;quot;
        with open(model_file, 'r', encoding='utf-8') as f:
            content = f.read()

        # Replace the empty metadata element with our properly escaped version
        escaped_json = metadata_json.replace('"', '&amp;quot;')
        content = content.replace(
            '<metadata name="height_range_modifier" />',
            f'<metadata name="height_range_modifier">{escaped_json}</metadata>'
        )
        content = content.replace(
            '<metadata name="height_range_modifier"></metadata>',
            f'<metadata name="height_range_modifier">{escaped_json}</metadata>'
        )

        with open(model_file, 'w', encoding='utf-8') as f:
            f.write(content)

        # Re-create 3MF file
        print("Creating modified 3MF...")
        with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zip_out:
            for root_dir, dirs, files in os.walk(temp_path):
                for file in files:
                    file_path = Path(root_dir) / file
                    arcname = file_path.relative_to(temp_path)
                    zip_out.write(file_path, arcname)

        print()
        print("Success! Modified 3MF saved.")
        print()
        print("Next steps:")
        print("1. Open the modified file in Orca Slicer")
        print("2. Check if height range modifier appears")
        print("3. Slice and verify M600 in G-code")
        print()
        print("Note: This adds a GLOBAL height modifier that applies to")
        print("      all objects in the build plate.")

        return True


def main():
    if len(sys.argv) < 2:
        print("Usage: python add_height_modifier_orca.py input.3mf [output.3mf]")
        print()
        print("Adds M600 filament change at 1.5mm (global, applies to all objects)")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None

    success = add_height_modifier(input_file, output_file)

    if not success:
        sys.exit(1)


if __name__ == "__main__":
    main()
