// Two-Layer Oval Zipper Pull Template with Engraved Text
// Creates a white base oval with a blue top oval, engraved text, and a hole for zipper attachment

// Parameters - these can be overridden from command line
name = "NAME"; // Text to display on zipper pull
oval_width = 96; // Width of blue oval (mm) - white base will be 100mm total (96 + 2*2)
oval_height = 30; // Height of blue oval (mm) - white base will be 34mm total (30 + 2*2)
base_thickness = 1.5; // Thickness of white base layer (mm)
top_thickness = 1; // Thickness of blue top layer (mm)
base_offset = 2; // How much larger the white base is (mm)
base_text_size = 13; // Base font size for medium names (reduced to prevent interference with hole)
text_depth = 1; // How deep the text is engraved (mm) - cuts through blue to show white
font_file = "C:/Users/Fred/claude/Fordscript.ttf"; // Path to the custom font file

// Dynamic font sizing based on name length (mimics Ford oval proportions)
// "Fred" (4 chars) at 13mm gives ~20% coverage - our target
name_length = len(name);
text_size = name_length <= 3 ? 18 :      // Short names (Zoe, Sam, Al) - larger
            name_length <= 5 ? 13 :      // Medium names (Fred, John, Mary) - standard
            name_length <= 8 ? 11 :      // Longer names (Michael, Jessica) - smaller
            9;                           // Very long names (Christopher) - smallest

// Hole parameters for zipper pull
hole_diameter = 4; // Diameter of the hole (mm)
hole_clearance = 1; // Minimum clearance from edge of white base layer (mm)

// Module to create an oval (ellipse)
module oval(width, height, depth) {
    scale([width/2, height/2, 1])
        cylinder(h=depth, r=1, $fn=100);
}

// White base layer (larger oval) with hole
module base_layer() {
    color("white")
    difference() {
        oval(
            oval_width + base_offset*2,
            oval_height + base_offset*2,
            base_thickness
        );

        // Hole for zipper pull - positioned relative to white base edge
        // Calculate from white base width: (oval_width + base_offset*2)
        white_width = oval_width + base_offset*2;
        hole_x = -(white_width/2) + (hole_diameter/2) + hole_clearance;
        translate([hole_x, 0, -0.05])
            cylinder(h=base_thickness + 0.1, d=hole_diameter, $fn=50);
    }
}

// Blue top layer with engraved text and hole
module top_layer() {
    color("RoyalBlue")
    difference() {
        // Blue oval
        translate([0, 0, base_thickness])
            oval(oval_width, oval_height, top_thickness);

        // Engraved text (cuts into the blue layer)
        // Multiple offset renders create a "fake bold" effect
        for (x = [-0.3, 0, 0.3]) {
            for (y = [-0.3, 0, 0.3]) {
                translate([x, y, base_thickness + top_thickness - text_depth + 0.01])
                    linear_extrude(height=text_depth)
                        text(name,
                             size=text_size,
                             font="Fordscript",
                             halign="center",
                             valign="center");
            }
        }

        // Hole for zipper pull (positioned on left side)
        // Position: matches white base layer hole position
        white_width = oval_width + base_offset*2;
        hole_x = -(white_width/2) + (hole_diameter/2) + hole_clearance;
        translate([hole_x, 0, base_thickness])
            cylinder(h=top_thickness + 0.1, d=hole_diameter, $fn=50);
    }
}

// Main zipper pull assembly
module zipper_pull() {
    base_layer();
    top_layer();
}

// Generate the zipper pull
zipper_pull();
