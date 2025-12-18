// =====================================================
// Keycap Body Scaling Script - FIXED VERSION
// =====================================================
// This script scales down the keycap body while preserving
// the Cherry MX stem at its original 4mm x 4mm dimensions
//
// FIX: Centers the model first so cylinder operations work correctly
// =====================================================

// ----- ADJUSTABLE PARAMETERS -----

body_scale_xy = 0.98;  // 98% of original (2% smaller)
body_scale_z = 1.00;   // Keep height at 100%

stem_diameter = 4.8;   // Diameter of circular stem preservation region (4.8mm to preserve 4mm x 4mm cross)
stem_height = 10.0;    // Height of stem region to preserve (tall enough to capture entire stem)
stem_z_offset = -1.0;  // Z offset to position cylinder on the stem
$fn = 128;             // Circle smoothness

stl_filename = "Body5(1).stl";

// =====================================================
// MAIN MODEL - CENTERED APPROACH
// =====================================================

// Center the imported model at origin
// The stem cross should be centered at X=209, Y=223.5 in the original STL
module centered_import() {
    translate([-209, -223.5, 0])  // Center X and Y on the stem
        import(stl_filename);
}

union() {
    // Part 1: Scaled body WITHOUT the circular stem region
    difference() {
        scale([body_scale_xy, body_scale_xy, body_scale_z]) {
            centered_import();
        }

        // Cut out a cylinder where the stem is
        translate([0, 0, stem_z_offset]) {
            cylinder(h = stem_height, d = stem_diameter + 0.5, center = true);
        }
    }

    // Part 2: Original UNSCALED stem region (circular)
    intersection() {
        centered_import();  // NOT scaled - preserves original 4mm x 4mm cross

        // Cylinder defines the 4.8mm circular stem region to keep at 100% scale
        translate([0, 0, stem_z_offset]) {
            cylinder(h = stem_height, d = stem_diameter, center = true);
        }
    }
}
