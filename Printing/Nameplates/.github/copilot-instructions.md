# AI Coding Instructions for Nameplates Generator

## Project Overview

A batch 3D nameplate generator using **Python + OpenSCAD**. Reads names from text file, generates parametric two-layer oval nameplates with engraved text, outputs STL files for 3D printing.

**Design**: White base (1.5mm) + blue top layer (1mm) with text engraved through blue layer to expose white underneath.

## Critical Dependencies

### OpenSCAD Installation
- **Path**: `C:\Program Files\OpenSCAD\openscad.exe` (hardcoded in line 36 of `generate_nameplates.py`)
- Download: https://openscad.org/downloads.html
- **Must update path** if installed elsewhere

### Font Requirements (CRITICAL)
- **Font**: Fordscript cursive font (`Fordscript.ttf` in project root)
- **Installation**: Must be installed in Windows (right-click → Install for all users)
- **Why**: OpenSCAD references fonts by name, not file path
- **Reference in SCAD**: `font="Fordscript"` (line 44 of `nameplate_template.scad`)
- **Path hardcoded**: `font_file = "C:/Users/Fred/claude/Fordscript.ttf"` in SCAD (line 10) - informational only, not used by OpenSCAD

## Architecture & Data Flow

```
names.txt → generate_nameplates.py → OpenSCAD CLI → output_stl/*.stl
                                       ↑
                                nameplate_template.scad
```

### Pipeline
1. **Input**: `names.txt` (one name per line, UTF-8 encoded)
2. **Processing**: Python script iterates, calling OpenSCAD for each name
3. **OpenSCAD**: Renders 3D model from parametric template
4. **Output**: Individual STL files in `output_stl/` directory

### Key Files
- `generate_nameplates.py` - Batch processor, subprocess orchestration
- `nameplate_template.scad` - Parametric OpenSCAD template
- `names.txt` - Input data (plain text, one name per line)
- `output_stl/` - Generated STL files (created automatically)
- `Fordscript.ttf` - Custom font (must be installed)

## Critical Developer Workflows

### Generate All Nameplates
```bash
python generate_nameplates.py
```

### Test Single Nameplate (Manual)
```powershell
# PowerShell syntax
& "C:\Program Files\OpenSCAD\openscad.exe" -D 'name="TestName"' -o test_output.stl nameplate_template.scad

# Or from CMD
"C:\Program Files\OpenSCAD\openscad.exe" -D "name=\"TestName\"" -o test_output.stl nameplate_template.scad
```

### Preview in OpenSCAD GUI
```powershell
# Open template in GUI for visual editing
& "C:\Program Files\OpenSCAD\openscad.exe" nameplate_template.scad
```

Then manually edit `name` parameter at top of file to preview different text.

### Validate Font Installation
```powershell
# Check if font is installed
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" | Select-String "Fordscript"

# Or check fonts directory
ls $env:WINDIR\Fonts\Fordscript*
```

## Project-Specific Conventions

### Name Sanitization
Python script converts names to safe filenames:
- Removes special characters (keeps alphanumeric, spaces, hyphens, underscores)
- Replaces spaces with underscores
- Example: `"John Doe"` → `John_Doe.stl`

### OpenSCAD Command Pattern
```python
cmd = [
    r'C:\Program Files\OpenSCAD\openscad.exe',
    '-D', f'name="{escaped_name}"',  # Set variable
    '-o', output_file,                # Output file
    template_file                     # Input SCAD file
]
```

**Key flags**:
- `-D name="value"` - Override parameter in SCAD file
- `-o file.stl` - Output file path
- No flag for input file (positional argument)

### SCAD Template Structure
```scad
// Parameters (overridable via -D flag)
name = "NAME";
oval_width = 100;
oval_height = 38;
// ... more parameters

// Modules (functions)
module oval(width, height, depth) { ... }
module base_layer() { ... }
module top_layer() { ... }
module nameplate() { ... }

// Execution (builds the model)
nameplate();
```

## Common Pitfalls

### Font Not Found Error
**Symptom**: OpenSCAD renders but text is missing or uses default font.

**Causes**:
1. Font not installed in Windows (right-click TTF → Install)
2. Font name mismatch (must be exactly "Fordscript" in SCAD)
3. OpenSCAD needs restart after font installation

**Fix**: Install font, restart OpenSCAD, verify with manual test.

### Special Characters in Names
**Symptom**: Subprocess error or malformed STL.

**Cause**: Shell escaping issues with quotes, backslashes, etc.

**Current handling**: `escaped_name = name.replace('"', '\\"')` (line 33)

**Extension**: Add more sanitization if needed:
```python
# Escape more shell-sensitive characters
escaped_name = name.replace('"', '\\"').replace('\\', '\\\\')
```

### OpenSCAD Path Issues
**Symptom**: `FileNotFoundError: OpenSCAD not found`.

**Fix**: Update hardcoded path in `generate_nameplates.py:36`:
```python
cmd = [
    r'C:\Program Files\OpenSCAD\openscad.exe',  # ← Update this
    # ...
]
```

**Better approach**: Use environment variable or config file:
```python
OPENSCAD_PATH = os.getenv('OPENSCAD_PATH', r'C:\Program Files\OpenSCAD\openscad.exe')
```

## Modifying Dimensions

All dimensions in `nameplate_template.scad` (lines 6-12):

| Parameter | Current Value | Purpose |
|-----------|---------------|---------|
| `oval_width` | 100mm | Overall width |
| `oval_height` | 38mm | Overall height (proportional) |
| `base_thickness` | 1.5mm | White layer thickness |
| `top_thickness` | 1mm | Blue layer thickness |
| `base_offset` | 2mm | White extension beyond blue |
| `text_size` | 15mm | Font size |
| `text_depth` | 1mm | Engraving depth (full blue layer) |

### Maintaining Proportions
Height typically 38% of width for aesthetic oval shape:
```scad
oval_height = oval_width * 0.38;
```

### Text Depth Critical
`text_depth` must equal `top_thickness` to engrave through entire blue layer:
```scad
text_depth = 1; // Must match top_thickness for full engraving
```

If `text_depth < top_thickness`, text won't reach white base. If `text_depth > top_thickness`, text cuts into white base (undesirable).

## Extending the Template

### Add New Shape Option
```scad
// Add rectangle module
module rectangle(width, height, depth) {
    cube([width, height, depth], center=true);
}

// Add shape parameter at top
shape = "oval"; // or "rectangle"

// Use conditional in base_layer
module base_layer() {
    if (shape == "rectangle")
        rectangle(oval_width + base_offset*2, oval_height + base_offset*2, base_thickness);
    else
        oval(oval_width + base_offset*2, oval_height + base_offset*2, base_thickness);
}
```

### Add Logo/Icon
```scad
// Import SVG or PNG
module logo() {
    translate([0, -oval_height/3, base_thickness + top_thickness - text_depth])
        linear_extrude(height=text_depth)
            import("logo.svg", center=true);
}

// Add to top_layer difference
difference() {
    // ... existing blue oval
    logo();  // Cut logo
}
```

### Batch Different Sizes
Modify Python script to pass multiple parameters:
```python
cmd = [
    r'C:\Program Files\OpenSCAD\openscad.exe',
    '-D', f'name="{escaped_name}"',
    '-D', f'oval_width={width}',    # Variable width
    '-D', f'text_size={text_size}', # Variable text size
    '-o', output_file,
    template_file
]
```

## Troubleshooting Commands

```powershell
# Check OpenSCAD version
& "C:\Program Files\OpenSCAD\openscad.exe" --version

# Test SCAD syntax (no output, just validation)
& "C:\Program Files\OpenSCAD\openscad.exe" --check nameplate_template.scad

# Render with verbose output
& "C:\Program Files\OpenSCAD\openscad.exe" -D 'name="Test"' -o test.stl nameplate_template.scad --verbose

# List available fonts in OpenSCAD (run in OpenSCAD console)
# Help → Font List
```

## 3D Printing Notes

- **Material**: Two colors required (white + blue recommended)
- **Layer Height**: 0.1-0.2mm for clean text
- **Infill**: 20-30% sufficient for thin nameplates
- **Supports**: Not needed (flat design)
- **Orientation**: Print flat (as modeled)
- **Bed Adhesion**: Brim or raft recommended for thin parts

## Quick Reference

### Add New Name
1. Edit `names.txt`, add line with new name
2. Run `python generate_nameplates.py`
3. Find STL in `output_stl/` directory

### Change All Dimensions
1. Edit parameters at top of `nameplate_template.scad`
2. Run `python generate_nameplates.py` to regenerate all
3. Or manually test with single name first

### Install Font on New Machine
1. Copy `Fordscript.ttf` to new machine
2. Right-click → "Install for all users"
3. Restart OpenSCAD if running
4. Test with manual OpenSCAD command
