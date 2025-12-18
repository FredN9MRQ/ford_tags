// =====================================================
// Numbered Keycap Generator - Multi-Color Printing
// =====================================================
// This script generates 20 numbered keycap STL files
// with recessed numbers for multi-material printing
//
// Numbers are 14mm tall, recessed 0.6mm deep
// Positioned on triangular top face, centered on apex-to-midpoint line
// Apex oriented as "up" (aligned with Cherry MX cross arm)
// =====================================================

// ----- ADJUSTABLE PARAMETERS -----

number_to_generate = 1;  // Change this value (1-20) to generate different numbers

number_height = 14;      // Height of numbers in mm
number_depth = 0.6;      // Recess depth for color saturation
text_font = "Liberation Sans:style=Bold";  // Font (use bold for visibility)
text_thickness = number_depth;  // Same as recess depth

// Triangular face positioning
// The top face is opposite the stem pocket
// One apex aligns with a Cherry MX cross arm
face_z_position = 8.0;   // Approximate Z height of top triangular face
face_rotation = 0;       // Rotation to align apex with cross arm
text_y_offset = 0;       // Offset along apex-to-midpoint centerline

$fn = 128;               // Circle smoothness

base_stl_filename = "Body5(1)_scaled_98percent.stl";

// =====================================================
// CENTERED IMPORT MODULE
// =====================================================

module centered_base() {
    // Import the scaled keycap base
    // Already centered from the previous scaling script
    import(base_stl_filename);
}

// =====================================================
// NUMBERED TEXT MODULE
// =====================================================

module recessed_number(num) {
    // Create text for the number
    rotate([0, 0, face_rotation]) {
        translate([0, text_y_offset, face_z_position]) {
            rotate([0, 0, 0]) {  // Text faces up
                linear_extrude(height = text_thickness + 1) {  // +1 to ensure clean cut
                    text(
                        str(num),
                        size = number_height,
                        halign = "center",
                        valign = "center",
                        font = text_font
                    );
                }
            }
        }
    }
}

// =====================================================
// MAIN MODEL
// =====================================================

difference() {
    // The base keycap
    centered_base();

    // Subtract the recessed number
    recessed_number(number_to_generate);
}

// =====================================================
// USAGE INSTRUCTIONS
// =====================================================
//
// MANUAL GENERATION (one at a time):
// 1. Change number_to_generate value (1-20)
// 2. Render with F6
// 3. Export as STL with desired filename
//
// COMMAND LINE GENERATION (all 20 files):
// Use the companion batch script or run:
//   openscad -D number_to_generate=N -o Body5_numN.stl generate_numbered_keycaps.scad
//
// ADJUSTING POSITION:
// - face_z_position: Move numbers up/down on the keycap
// - face_rotation: Rotate around Z axis to align with cross arm
// - text_y_offset: Move along the apex-to-midpoint centerline
//
// MULTI-MATERIAL PRINTING:
// 1. Slice the numbered STL normally
// 2. At layer with recess (approx 0.6mm from top), insert material change
// 3. Printer will pause, swap filament for number color
// 4. Resume printing - number will be filled with new color
// 5. At end of recess depth, change back to original material
//
// =====================================================
