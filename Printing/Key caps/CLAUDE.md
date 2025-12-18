# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an OpenSCAD project for scaling 3D-printed mechanical keyboard keycaps while preserving the Cherry MX stem dimensions. The project contains scripts to reduce keycap body dimensions for better socket fit while maintaining the exact 4mm × 4mm stem cross dimensions required for Cherry MX switches.

## Key Commands

### Rendering STL Files

On Windows, OpenSCAD is typically installed at `C:\Program Files\OpenSCAD\openscad.exe`. Use Git Bash path format:

```bash
# Render a SCAD file to STL
"/c/Program Files/OpenSCAD/openscad.exe" -o "output.stl" "input.scad"

# Clear cache and render (recommended when changing imports)
"/c/Program Files/OpenSCAD/openscad.exe" --clear-cache -o "output.stl" "input.scad"
```

### Verify OpenSCAD Installation

```bash
# Check if OpenSCAD is installed
if exist "C:\Program Files\OpenSCAD\openscad.exe" echo Found at C:\Program Files\OpenSCAD\openscad.exe
```

## Project Architecture

### Main Scripts

- **`Body5_scaled_FIXED.scad`**: The primary working script that uses a centered-import approach. This is the recommended version for scaling keycaps.
- **`Body5_scaled.scad`**: Earlier version that manually positions the stem preservation cylinder using explicit X/Y coordinates.
- **`Body5_test_circle.scad`**: Test script with exaggerated parameters (larger cylinder) to verify the circular stem preservation is working.
- **`test_cylinder.scad`**: Simple cylinder rendering test for OpenSCAD verification.

### STL Files

- **`Body5.stl`**: The original keycap model that gets imported and processed by the SCAD scripts.
- **`Body2.stl`**: Alternative keycap model.
- **Generated STL files**: Output from rendering the SCAD scripts (e.g., `Body5_scaled_98percent.stl`).

### Scaling Algorithm

The scripts use a two-part union approach:

1. **Scaled Body with Cutout**: The entire keycap is scaled down by `body_scale_xy`, then a cylinder is subtracted where the stem should be
2. **Unscaled Stem Region**: A cylinder intersection preserves the original stem region at 100% scale
3. **Union**: Both parts are merged, creating a keycap with scaled body but original stem dimensions

The `_FIXED` version centers the model at the origin before operations, making cylinder placement simpler. The non-FIXED version requires manual positioning of the preservation cylinder using `stem_x` and `stem_y` coordinates.

### Critical Parameters

- **`body_scale_xy`**: X/Y scaling factor (typically 0.97-0.99 for 1-3% reduction)
- **`body_scale_z`**: Z scaling factor (keep at 1.00 to maintain keycap height)
- **`stem_diameter`**: Diameter of circular preservation region (default: 5.5mm)
- **`stem_height`**: Height of stem region (default: 8.0mm)
- **`$fn`**: OpenSCAD circle resolution (64-128, higher = smoother but slower)

### Centering Approach (FIXED version)

The `centered_import()` module translates the imported STL by `[-209, -223.5, -4.9]` to center it at the origin. These values were determined by analyzing the original STL's bounding box. This allows stem operations to use simple `cylinder()` calls at the origin rather than calculating offsets.

## Development Workflow

1. Modify SCAD script parameters (typically just `body_scale_xy`)
2. Render to STL using OpenSCAD command line or GUI (F5 preview, F6 full render in GUI)
3. Import STL into slicer and print test keycap
4. Measure fit and iterate on scaling factor
5. Typical iteration: start at 0.98, adjust by 0.01 increments based on fit testing

## Important Notes

- The Cherry MX stem cross is exactly 4mm × 4mm by specification and must not be scaled
- The circular preservation region accommodates off-brand switches that may have slightly different tolerances
- All SCAD scripts expect `Body5.stl` (or specified STL file) to be in the same directory
- Rendering is computationally intensive due to importing the STL twice (once for scaling, once for stem preservation)
