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

stem_diameter = 5.5;   // Diameter of circular stem preservation region
stem_height = 8.0;     // Height of stem region to preserve
$fn = 128;             // Circle smoothness

stl_filename = "Body5.stl";

// =====================================================
// MAIN MODEL - CENTERED APPROACH
// =====================================================

// First, we need to center the imported model
// The original STL is positioned around x≈209, y≈220
// We'll measure the bounding box and center it

module centered_import() {
    // Import and center the model at origin
    translate([-209, -223.5, -4.9])  // Approximate center based on STL coordinates
        import(stl_filename);
}

union() {
    // Part 1: Scaled body WITHOUT the circular stem region
    difference() {
        scale([body_scale_xy, body_scale_xy, body_scale_z]) {
            centered_import();
        }

        // Cut out a cylinder where the stem is (now centered at origin)
        cylinder(h = stem_height, d = stem_diameter + 0.5, center = true);
    }

    // Part 2: Original unscaled stem region (circular)
    intersection() {
        centered_import();

        // Cylinder defines the circular stem region to keep
        cylinder(h = stem_height, d = stem_diameter, center = true);
    }
}
