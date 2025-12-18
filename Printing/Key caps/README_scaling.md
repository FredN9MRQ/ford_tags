# Keycap Scaling Guide

## Quick Start

1. **Open the script**: Open `Body5_scaled.scad` in OpenSCAD
2. **Adjust scaling**: Edit the `body_scale_xy` parameter at the top (default: 0.98 = 98%)
3. **Preview**: Press `F5` to see a quick preview
4. **Render**: Press `F6` to fully render (required before export)
5. **Export**: Go to `File > Export > Export as STL`
6. **Test print**: Print and check the fit
7. **Iterate**: Adjust the scale parameter and repeat if needed

## Key Parameters

### `body_scale_xy`
- **Default**: `0.98` (98% of original size)
- **Purpose**: Scales the X and Y dimensions of the keycap body
- **Recommendations**:
  - Start with `0.98` for a 2% reduction
  - If too tight: try `0.97` (3% reduction)
  - If too loose: try `0.99` (1% reduction)
  - Fine-tune: use `0.975`, `0.985`, etc.

### `body_scale_z`
- **Default**: `1.00` (no scaling)
- **Purpose**: Scales the Z (height) dimension
- **Recommendation**: Keep at `1.00` to maintain keycap height

### Stem Parameters (Advanced)
Only adjust these if the stem preservation isn't working correctly:

- `stem_diameter`: Diameter of the circular preservation region (default: 5.5mm)
- `stem_height`: Height of the stem (default: 4.0mm)
- `stem_z_position`: Vertical position offset (default: -2.0mm)
- `$fn`: Circle smoothness (default: 64, range: 32-128)

## How It Works

The script uses a two-part approach:

1. **Scaled Body**: The entire keycap is scaled down by your chosen percentage, BUT a circular region around the stem is cut out
2. **Original Stem**: The circular stem region is preserved at 100% scale (keeping the 4mm × 4mm Cherry MX cross dimensions)
3. **Combined**: Both parts are merged together

This ensures:
- ✅ The outer keycap body fits better in sockets (scaled down)
- ✅ The Cherry MX stem remains exactly 4mm × 4mm (unscaled)
- ✅ The circular region around the stem is preserved (for off-brand switches)
- ✅ The stem stays centered and properly positioned

## Workflow for Iterative Testing

1. Export STL with `body_scale_xy = 0.98`
2. Slice and print the keycap
3. Test fit on your keyboard
4. **If too tight**: Decrease scale (try 0.97)
5. **If too loose**: Increase scale (try 0.99)
6. **If just right**: You're done!

## Troubleshooting

### The stem looks wrong or is scaled
- The circular stem region might not be positioned correctly
- Measure your stem in the original STL
- Adjust `stem_z_position`, `stem_diameter`, or `stem_height`
- If the circle is too jagged, increase `$fn` to 128

### The keycap won't render
- Make sure `Body5.stl` is in the same folder as the `.scad` file
- Check for errors in the OpenSCAD console (bottom of window)

### Rendering is slow
- This is normal! The script imports the STL twice
- `F5` preview is fast but lower quality
- `F6` render is slow but required for STL export
- Consider reducing the preview quality in OpenSCAD preferences

### The seam between body and stem is visible
- This is usually not noticeable in the printed part
- If needed, increase `stem_diameter` by 0.5mm increments (try 6.0mm or 6.5mm)

## File Structure

```
Key caps/
├── Body5.stl              # Original keycap STL
├── Body5_scaled.scad      # OpenSCAD scaling script
└── README_scaling.md      # This guide
```

## Export Settings

When exporting STL from OpenSCAD:
- File format: STL (binary is smaller, ASCII is more compatible)
- Units: millimeters (mm)

## Next Steps

After exporting your scaled STL:
1. Import into your slicer (Cura, PrusaSlicer, etc.)
2. Use typical keycap print settings:
   - Layer height: 0.1-0.2mm
   - Infill: 15-20%
   - Supports: Probably not needed for most keycaps
3. Print and test!

---

**Note**: The Cherry MX stem dimensions (4mm × 4mm) are standardized. The script is designed to preserve these exactly, so you should only need to adjust the `body_scale_xy` parameter for tolerance testing.
