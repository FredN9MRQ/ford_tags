// Single-Layer Oval Zipper Pull Template with Raised Text
// Creates a blue base oval with raised white text and a hole for zipper attachment

// Parameters - these can be overridden from command line
name = "NAME"; // Text to display on zipper pull
oval_width = 96; // Width of blue oval (mm) - total with border will be 100mm (96 + 2*2)
oval_height = 30; // Height of blue oval (mm) - total with border will be 34mm (30 + 2*2)
base_thickness = 1.5; // Thickness of blue base layer (mm)
text_thickness = 1; // Thickness of raised white text (mm)
base_text_size = 13; // Base font size for medium names
font_file = "C:/Users/Fred/claude/Fordscript.ttf"; // Path to the custom font file

// Dynamic font sizing based on name length (mimics Ford oval proportions)
// "Fred" (4 chars) at 13mm gives ~20% coverage - our target
name_length = len(name);
text_size = name_length <= 3 ? 18 :      // Short names (Zoe, Sam, Al) - larger
            name_length <= 5 ? 13 :      // Medium names (Fred, John, Mary) - standard
            name_length <= 8 ? 11 :      // Longer names (Michael, Jessica) - smaller
            9;                           // Very long names (Christopher) - smallest

// Border parameters
border_width = 2; // Width of the white border around the oval (mm)
border_thickness = 1; // Thickness of the white border (mm)

// Hole parameters for zipper pull
hole_diameter = 4; // Diameter of the hole (mm)
hole_clearance = 3; // Minimum clearance from edge of outer border (mm) - increased to fully clear white border

// Module to create an oval (ellipse)
module oval(width, height, depth) {
    scale([width/2, height/2, 1])
        cylinder(h=depth, r=1, $fn=100);
}

// Blue base layer with hole
module base_layer() {
    color("RoyalBlue")
    difference() {
        // Blue base matches the outer size of the white border
        oval(oval_width + border_width*2, oval_height + border_width*2, base_thickness);

        // Hole for zipper pull - positioned relative to outer edge
        // Total width = oval_width + border_width*2
        // Position: left edge + hole_radius + clearance
        total_width = oval_width + border_width*2;
        hole_x = -(total_width/2) + (hole_diameter/2) + hole_clearance;
        translate([hole_x, 0, -0.05])
            cylinder(h=base_thickness + 0.1, d=hole_diameter, $fn=50);
    }
}

// White border around the oval
module white_border() {
    color("white")
    translate([0, 0, base_thickness])
        difference() {
            // Outer oval (larger)
            oval(oval_width + border_width*2, oval_height + border_width*2, border_thickness);
            // Inner oval (cut out the center)
            translate([0, 0, -0.05])
                oval(oval_width, oval_height, border_thickness + 0.1);
        }
}

// Raised white text on top of base - REDUCED bold effect (3 renders instead of 9)
module raised_text() {
    color("white")
    // Reduced bold effect - only 3 offsets
    for (x = [-0.4, 0, 0.4]) {
        translate([x, 0, base_thickness])
            linear_extrude(height=text_thickness)
                text(name,
                     size=text_size,
                     font="Fordscript",
                     halign="center",
                     valign="center");
    }
}

// Main zipper pull assembly
module zipper_pull() {
    base_layer();
    white_border();
    raised_text();
}

// Generate the zipper pull
zipper_pull();
