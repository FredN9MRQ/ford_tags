// Two-Layer Check Mark Design
// Black base (box + check mark) + White fill layer on top
// Based on CF00089-08 Check Mark 01.svg

// Parameters - adjust these to customize
black_base_thickness = 0.5;    // Black base layer (thin, bottom)
white_fill_thickness = 1.5;    // White fill layer (middle)
black_top_thickness = 0.5;     // Black top (check mark shows through)
desired_size = 14;             // Desired box size (mm) - makes design square

// SVG file path
svg_file = "Check-Mark/CF00089-08 Check Mark 01.svg";

// Calculate dimensions from SVG viewBox (720 x 570.9)
svg_width = 720;
svg_height = 570.9;

// Scale factors to make the design exactly square
scale_x = desired_size / svg_width;   // Scale for width
scale_y = desired_size / svg_height;  // Scale for height
design_width = desired_size;
design_height = desired_size;

// White fill inset (how much smaller than the outer box)
white_inset = 1.5;  // mm inset from edges (adjusted for 14mm box)
white_width = design_width - (white_inset * 2);
white_height = design_height - (white_inset * 2);

// Total thickness
total_thickness = black_base_thickness + white_fill_thickness + black_top_thickness;

echo(str("Design size: ", design_width, "mm x ", design_height, "mm"));
echo(str("White fill size: ", white_width, "mm x ", white_height, "mm"));
echo(str("Total thickness: ", total_thickness, "mm"));

// Build the two-layer design
module checkmark_design() {
    // Layer 1: Black base - full SVG design (box + check mark)
    color("black")
    translate([0, 0, 0])
    linear_extrude(height = total_thickness)
    // Center the SVG design
    translate([-design_width/2, -design_height/2, 0])
    scale([scale_x, scale_y, 1])
    import(svg_file, center = false);

    // Layer 2: White fill - sits on top of black base, inside the box
    color("white")
    translate([0, 0, black_base_thickness])
    linear_extrude(height = white_fill_thickness)
    offset(r = 1)  // Slightly round the corners
    square([white_width, white_height], center = true);
}

// Render the complete design
checkmark_design();
