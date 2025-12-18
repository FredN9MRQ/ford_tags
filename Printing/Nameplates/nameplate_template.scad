// Two-Layer Oval Nameplate Template with Engraved Text
// Creates a white base oval with a blue top oval and engraved text

// Parameters - these can be overridden from command line
name = "NAME"; // Text to display on nameplate
oval_width = 100; // Width of the oval (mm) - max 100mm
oval_height = 38; // Height of the oval (mm) - proportional to width
base_thickness = 1.5; // Thickness of white base layer (mm)
top_thickness = 1; // Thickness of blue top layer (mm)
base_offset = 2; // How much larger the white base is (mm)
text_size = 15; // Font size for the text
text_depth = 1; // How deep the text is engraved (mm) - cuts through blue to show white
font_file = "C:/Users/Fred/claude/Fordscript.ttf"; // Path to the custom font file

// Module to create an oval (ellipse)
module oval(width, height, depth) {
    scale([width/2, height/2, 1])
        cylinder(h=depth, r=1, $fn=100);
}

// White base layer (larger oval)
module base_layer() {
    color("white")
    oval(
        oval_width + base_offset*2,
        oval_height + base_offset*2,
        base_thickness
    );
}

// Blue top layer with engraved text
module top_layer() {
    color("RoyalBlue")
    difference() {
        // Blue oval
        translate([0, 0, base_thickness])
            oval(oval_width, oval_height, top_thickness);

        // Engraved text (cuts into the blue layer)
        translate([0, 0, base_thickness + top_thickness - text_depth + 0.01])
            linear_extrude(height=text_depth)
                text(name,
                     size=text_size,
                     font="Fordscript",
                     halign="center",
                     valign="center");
    }
}

// Main nameplate assembly
module nameplate() {
    base_layer();
    top_layer();
}

// Generate the nameplate
nameplate();
