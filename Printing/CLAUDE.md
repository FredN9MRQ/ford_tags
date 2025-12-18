# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A collection of 3D printing utilities for generating personalized STL files using **Python + OpenSCAD**. The repository contains two main subprojects:

1. **Nameplates** - Batch nameplate and zipper pull generator
2. **Key caps** - Mechanical keyboard keycap scaling utilities

All projects use OpenSCAD as the 3D modeling engine, invoked via Python scripts or standalone SCAD files.

## Repository Structure

```
Printing/
├── Nameplates/           # Nameplate and zipper pull generators
│   ├── generate_nameplates.py      # Batch nameplate generator
│   ├── generate_zipper_pulls.py    # Batch zipper pull generator
│   ├── nameplate_template.scad     # Nameplate template (38mm height, no hole)
│   ├── zipper_pull_template.scad   # Zipper pull template (34mm height, 4mm hole)
│   ├── names.txt                   # Input names (one per line)
│   ├── output_stl/                 # Generated nameplate STLs
│   ├── zipper-pulls/               # Generated zipper pull STLs
│   ├── Fordscript.ttf              # Custom cursive font (must be installed)
│   └── CLAUDE.md                   # Detailed nameplate documentation
│
└── Key caps/             # Keyboard keycap scaling
    ├── Body5_scaled_FIXED.scad     # Primary keycap scaling script
    ├── Body5.stl                   # Original keycap model
    ├── CLAUDE.md                   # Detailed keycap documentation
    └── README_scaling.md           # User guide for scaling workflow
```

## Critical Dependencies

### OpenSCAD Installation
- **Path**: `C:\Program Files\OpenSCAD\openscad.exe` (hardcoded in Python scripts)
- **Download**: https://openscad.org/downloads.html
- **Update path** in scripts if installed elsewhere (see `generate_nameplates.py:36`, `generate_zipper_pulls.py:36`)

### Font Requirements (Nameplates/Zipper Pulls Only)
- **Font**: Fordscript cursive font (`Nameplates/Fordscript.ttf`)
- **Installation**: Must be installed in Windows (right-click → Install for all users)
- **Critical**: OpenSCAD references fonts by system name, not file path
- **Verification**: After install, restart OpenSCAD before generating files

## Key Commands

### Nameplates
```bash
# Generate all nameplates (38mm height, no hole)
cd Nameplates
python generate_nameplates.py

# Output: output_stl/*.stl
```

### Zipper Pulls
```bash
# Generate all zipper pulls (100mm × 34mm total, 4mm hole with 1mm clearance)
cd Nameplates
python generate_zipper_pulls.py

# Output: zipper-pulls/*.stl
```

### Key Caps
```powershell
# Render scaled keycap (command line)
& "C:\Program Files\OpenSCAD\openscad.exe" -o "output.stl" "Body5_scaled_FIXED.scad"

# Or: Open in OpenSCAD GUI, adjust parameters, press F6 to render, export STL
& "C:\Program Files\OpenSCAD\openscad.exe" "Body5_scaled_FIXED.scad"
```

### Manual OpenSCAD Testing
```powershell
# Test single nameplate
& "C:\Program Files\OpenSCAD\openscad.exe" -D 'name="TestName"' -o test_output.stl nameplate_template.scad

# Test single zipper pull
& "C:\Program Files\OpenSCAD\openscad.exe" -D 'name="TestName"' -o test_output.stl zipper_pull_template.scad

# Preview in GUI (edit parameters at top of file)
& "C:\Program Files\OpenSCAD\openscad.exe" nameplate_template.scad
```

## Architecture Overview

### Nameplates vs Zipper Pulls

Both use the same two-layer oval design (white base + blue top with engraved text) but differ in dimensions and features:

| Feature | Nameplates | Zipper Pulls |
|---------|-----------|-------------|
| Template | `nameplate_template.scad` | `zipper_pull_template.scad` |
| Generator | `generate_nameplates.py` | `generate_zipper_pulls.py` |
| Total Size (W×H) | 100mm × 38mm | 100mm × 34mm |
| Blue Layer Size | 96mm × 34mm | 96mm × 30mm |
| White Base Offset | 2mm all sides | 2mm all sides |
| Font Size | 30mm | 13mm |
| Hole | None | 4mm diameter, left side |
| Hole Clearance | N/A | 1mm from white base edge |
| Output Directory | `output_stl/` | `zipper-pulls/` |
| Use Case | Display nameplates | Zipper/bag attachments |

**Important**: These are separate templates and scripts. Modifying one does not affect the other.

### Pipeline Architecture

```
names.txt
    ↓
Python Generator Script (reads names, iterates)
    ↓
OpenSCAD CLI (renders each name via template)
    ↓
STL Files (output to respective directories)
```

**Key Pattern**: Python script calls OpenSCAD subprocess for each name:
```python
cmd = [
    r'C:\Program Files\OpenSCAD\openscad.exe',
    '-D', f'name="{escaped_name}"',  # Override parameter
    '-o', output_file,                # Output STL path
    template_file                     # SCAD template
]
subprocess.run(cmd, capture_output=True, text=True, check=True)
```

### OpenSCAD Template Pattern

All SCAD templates follow this structure:
```scad
// 1. Parameters (overridable via -D flag)
name = "NAME";
oval_width = 100;
// ... more parameters

// 2. Modules (reusable geometry functions)
module oval(width, height, depth) { ... }
module base_layer() { ... }
module top_layer() { ... }

// 3. Assembly module
module nameplate() {
    base_layer();
    top_layer();
}

// 4. Execution (builds the model)
nameplate();
```

## Project-Specific Conventions

### Name Sanitization
Python scripts convert names to safe filenames:
- Removes special characters (keeps alphanumeric, spaces, hyphens, underscores)
- Replaces spaces with underscores
- Escapes quotes for shell: `name.replace('"', '\\"')`
- Example: `"John Doe"` → `John_Doe.stl`

### Two-Layer Design Philosophy
- **White base layer**: Structural foundation, extends beyond blue layer by `base_offset` (2mm)
- **Blue top layer**: Visual layer with engraved text
- **Text engraving**: Cuts completely through blue layer (`text_depth = top_thickness = 1mm`) to expose white base underneath
- **Result**: White text on blue background

### Hole Positioning (Zipper Pulls)
Hole is positioned on left side with clearance from white base edge:
```scad
white_width = oval_width + base_offset*2;
hole_x = -(white_width/2) + (hole_diameter/2) + hole_clearance;
// For 96mm blue + 2mm offset = 100mm white, 4mm hole, 1mm clearance:
// hole_x = -50 + 2 + 1 = -47mm from center
```

**Critical**:
- `hole_clearance` must be sufficient to prevent hole from breaking through oval edge. Current value (1mm) tested and verified.
- Hole is positioned relative to **white base width**, not blue layer width, to ensure it stays within the white outline.

## Common Workflows

### Add New Names to Both Systems
1. Edit `Nameplates/names.txt`, add name on new line
2. Run both generators:
   ```bash
   cd Nameplates
   python generate_nameplates.py     # Creates nameplate
   python generate_zipper_pulls.py   # Creates zipper pull
   ```
3. Find STLs in `output_stl/` and `zipper-pulls/` respectively

### Adjust Zipper Pull Hole Clearance
If hole is too close to edge or breaking through:
1. Edit `zipper_pull_template.scad`, line 17:
   ```scad
   hole_clearance = 1; // Increase this value
   ```
2. Regenerate all zipper pulls:
   ```bash
   python generate_zipper_pulls.py
   ```

**Note**: Hole clearance is measured from the **white base edge**, not the blue layer edge.

### Create Custom Dimension Variant
To create a new variant (e.g., smaller nameplates):
1. Copy existing template: `nameplate_template.scad` → `nameplate_small_template.scad`
2. Modify dimensions at top of new file
3. Copy generator script: `generate_nameplates.py` → `generate_nameplates_small.py`
4. Update generator to use new template and output directory:
   ```python
   template_file = "nameplate_small_template.scad"
   output_dir = "output_stl_small"
   ```

### Scale Keycaps for Different Tolerances
1. Open `Key caps/Body5_scaled_FIXED.scad` in OpenSCAD GUI
2. Adjust `body_scale_xy` parameter at top (default: 0.98 = 98%)
   - Too tight: decrease to 0.97 (3% reduction)
   - Too loose: increase to 0.99 (1% reduction)
3. Press `F5` for preview, `F6` for full render
4. Export via `File > Export > Export as STL`
5. Test print and iterate

See `Key caps/README_scaling.md` for detailed keycap scaling workflow.

## Troubleshooting

### Font Not Found (Nameplates/Zipper Pulls)
**Symptom**: Text is missing or uses default font in generated STLs.

**Fix**:
1. Install `Fordscript.ttf`: Right-click → "Install for all users"
2. Restart OpenSCAD if running
3. Test with manual command:
   ```powershell
   & "C:\Program Files\OpenSCAD\openscad.exe" -D 'name="Test"' -o test.stl nameplate_template.scad
   ```
4. Open `test.stl` in slicer and verify text appears

### OpenSCAD Path Not Found
**Symptom**: `FileNotFoundError: OpenSCAD not found`

**Fix**: Update hardcoded path in generator scripts:
```python
# In generate_nameplates.py and generate_zipper_pulls.py, line 36:
cmd = [
    r'C:\Program Files\OpenSCAD\openscad.exe',  # ← Update this path
    # ...
]
```

### Zipper Pull Hole Breaking Through Edge
**Symptom**: Hole intersects with oval edge, causing weak point or break.

**Fix**: Increase `hole_clearance` in `zipper_pull_template.scad`:
```scad
hole_clearance = 1.5; // Increase from 1mm to 1.5mm
```
Then regenerate all zipper pulls.

**Note**: Ensure hole clearance is measured from the white base edge (100mm total width), not the blue layer edge (96mm).

### Keycap Stem Scaled Incorrectly
**Symptom**: Cherry MX stem doesn't fit switch after scaling.

**Cause**: Using wrong SCAD file (non-FIXED version requires manual stem positioning).

**Fix**: Always use `Body5_scaled_FIXED.scad` which uses centered import approach. The stem preservation region is automatically centered at origin.

## Advanced Customization

### Add Custom Parameter to Templates
To add a new parameter (e.g., border thickness):

1. Add parameter to template:
   ```scad
   border_thickness = 0.5; // New parameter
   ```

2. Use in geometry:
   ```scad
   module base_layer() {
       difference() {
           oval(oval_width, oval_height, base_thickness);
           // Cut border groove
           translate([0, 0, base_thickness - border_thickness])
               oval(oval_width - 4, oval_height - 4, border_thickness + 0.1);
       }
   }
   ```

3. Pass from Python script (optional):
   ```python
   cmd = [
       r'C:\Program Files\OpenSCAD\openscad.exe',
       '-D', f'name="{escaped_name}"',
       '-D', f'border_thickness={thickness}',  # Override parameter
       '-o', output_file,
       template_file
   ]
   ```

### Batch Generate Multiple Sizes
Modify generator script to loop over multiple configurations:

```python
configs = [
    {"template": "nameplate_template.scad", "width": 100, "height": 38},
    {"template": "nameplate_template.scad", "width": 80, "height": 30},
    {"template": "nameplate_template.scad", "width": 60, "height": 23},
]

for name in names:
    for config in configs:
        output_file = f"{config['width']}x{config['height']}_{safe_name}.stl"
        cmd = [
            r'C:\Program Files\OpenSCAD\openscad.exe',
            '-D', f'name="{escaped_name}"',
            '-D', f'oval_width={config["width"]}',
            '-D', f'oval_height={config["height"]}',
            '-o', output_file,
            config["template"]
        ]
        subprocess.run(cmd, ...)
```

## Development Reference

### OpenSCAD Command Line Flags
```powershell
# Override parameter
-D 'name="value"'

# Output file
-o output.stl

# Check syntax (no output)
--check

# Verbose output
--verbose

# Clear cache (useful when changing imports)
--clear-cache

# Version info
--version
```

### Python Subprocess Pattern
All generators use the same pattern:
```python
result = subprocess.run(
    cmd,
    capture_output=True,  # Capture stdout/stderr
    text=True,            # Return strings, not bytes
    check=True            # Raise CalledProcessError on non-zero exit
)
```

Error handling:
```python
try:
    subprocess.run(cmd, capture_output=True, text=True, check=True)
except subprocess.CalledProcessError as e:
    print(f"Error: {e.stderr}")
except FileNotFoundError:
    print("OpenSCAD not found. Install from https://openscad.org")
```

## File Organization Guidelines

### When to Create New Template vs Modify Existing

**Create New Template** if:
- Fundamentally different design (e.g., adding holes, changing shape)
- Different use case (nameplates vs zipper pulls)
- Need to maintain both versions simultaneously

**Modify Existing Template** if:
- Adjusting dimensions only
- Tweaking existing features
- Single-use or temporary change

### Output Directory Naming
- Use descriptive names: `output_stl/`, `zipper-pulls/`
- Keep separate output directories for different variants
- Never mix different variants in the same directory (prevents confusion)

### Generator Script Naming
- Match template name: `generate_nameplates.py` uses `nameplate_template.scad`
- Be explicit: `generate_zipper_pulls.py` not `generate_zippers.py`
- One template per generator for clarity

## 3D Printing Notes

### Recommended Slicer Settings
- **Material**: Two colors (white + blue PLA recommended)
- **Layer Height**: 0.1-0.2mm for clean text details
- **Infill**: 20-30% (thin parts don't need much)
- **Supports**: Not needed (flat design, print as modeled)
- **Orientation**: Print flat on bed
- **Bed Adhesion**: Brim or raft recommended for thin parts
- **First Layer**: Critical for thin 1.5mm base - ensure good adhesion

### Multi-Color Printing
Two approaches:
1. **Filament swap**: Print white base, pause, swap to blue, continue
2. **Two prints**: Print white base separately, print blue top, glue together

**Important**: Text must be fully engraved through blue layer to show white underneath.

#### M600 Filament Change Height
When using M600 command for automatic filament change in slicer:
- **Base layer thickness**: 1.5mm
- **Actual M600 height**: 1.5mm + one layer height
- **Reason**: M600 triggers BEFORE the specified layer is printed. If set to exactly 1.5mm, the slicer will print one solid white layer at 1.5mm, then trigger M600, then start the blue outline and text.
- **Example**: With 0.2mm layer height, set M600 at 1.7mm (1.5 + 0.2) to ensure filament change happens at the correct layer.
- **Verification**: After slicing, verify that the layer immediately after M600 begins the blue top layer, not another white layer.

## Project-Specific Quirks

### Why Two Separate Templates for Nameplates/Zipper Pulls?
- Different dimensions (38mm vs 34mm height)
- Zipper pulls need hole, nameplates don't
- Maintains backward compatibility with existing nameplate output
- Allows independent evolution of each variant

### Why Hardcoded OpenSCAD Path?
- Windows standard installation location is consistent
- Avoids PATH environment complexity
- Easy to update in one place per script
- Future: Consider environment variable or config file

### Why Manual Font Installation?
- OpenSCAD uses system font registry, not file paths
- Ensures consistent font rendering across machines
- Font must be available to OpenSCAD process
- No programmatic workaround exists

### Keycap Stem Preservation Algorithm
- Circular region around stem preserved at 100% scale
- Rest of keycap scaled down for better fit
- Cherry MX stem is exactly 4mm × 4mm by spec (must not scale)
- Circular preservation accommodates off-brand switch tolerances
- See `Key caps/CLAUDE.md` for detailed algorithm explanation
