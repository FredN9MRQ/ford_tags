# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a 3D nameplate generator that creates two-layer oval nameplates with engraved text using OpenSCAD. The system batch-processes names from a text file and outputs STL files ready for 3D printing.

## Architecture

**Pipeline:**
1. Python script (`generate_nameplates.py`) reads names from `names.txt`
2. For each name, it invokes OpenSCAD CLI with the parametric template
3. OpenSCAD renders the 3D model using `nameplate_template.scad`
4. STL files are output to `output_stl/` directory

**Design Structure:**
- Two-layer design: white base (1.5mm) + blue top layer (1mm)
- Text is engraved completely through the blue layer to expose white underneath
- Oval shape created by scaling a cylinder
- All dimensions parametric for easy customization

## Key Commands

**Generate nameplates:**
```bash
python generate_nameplates.py
```

**Test single nameplate (manual):**
```bash
"C:\Program Files\OpenSCAD\openscad.exe" -D "name=\"TestName\"" -o output.stl nameplate_template.scad
```

## Critical Configuration

**OpenSCAD Path:**
The script uses hardcoded path: `C:\Program Files\OpenSCAD\openscad.exe`
Update in `generate_nameplates.py:36` if OpenSCAD is installed elsewhere.

**Font Requirements:**
- Uses Fordscript font (Fordscript.ttf in project root)
- Font MUST be installed in Windows (right-click → Install) for OpenSCAD to access it
- OpenSCAD references fonts by name, not file path
- Referenced in template as `font="Fordscript"` (line 44)

**Dimensions:**
Default nameplate size: 3" tall × 8" wide (76mm × 200mm)
All dimensions in `nameplate_template.scad:6-12`

## File Purposes

- `nameplate_template.scad` - OpenSCAD parametric template defining the 3D geometry
- `generate_nameplates.py` - Batch processor that calls OpenSCAD for each name
- `names.txt` - Input file with one name per line
- `Fordscript.ttf` - Custom cursive font (must be installed in Windows)
- `output_stl/` - Generated STL files (one per name)

## Modifying Dimensions

Key parameters in `nameplate_template.scad`:
- `oval_height` - Overall height (currently 76mm = 3 inches)
- `oval_width` - Overall width (currently 200mm ≈ 8 inches)
- `base_thickness` - White layer thickness (1.5mm)
- `top_thickness` - Blue layer thickness (1mm)
- `text_depth` - Engraving depth (1mm - cuts through entire blue layer)
- `text_size` - Font size (30mm)
- `base_offset` - How much white extends beyond blue (2mm)
