// =====================================================
// Keycap Body Scaling Script
// =====================================================
// This script scales down the keycap body while preserving
// the Cherry MX stem at its original 4mm x 4mm dimensions
// within a CIRCULAR region (for off-brand switches)
//
// Usage:
// 1. Adjust body_scale_xy below (start with 0.98 = 98%)
// 2. Adjust stem_x and stem_y to position circle on the cross
// 3. Press F5 to preview, F6 to render
// 4. Export STL: File > Export > Export as STL
// =====================================================

// ----- ADJUSTABLE PARAMETERS -----

// Body scaling factor for X and Y axes
body_scale_xy = 0.98;  // 98% of original (2% smaller)
body_scale_z = 1.00;   // Keep height at 100%

// ----- STEM DIMENSIONS -----
// Position the circular preservation region on the stem cross

stem_x = 209;          // X position of stem center (adjust to align with cross)
stem_y = 223.5;        // Y position of stem center (adjust to align with cross)
stem_z = 3.85;         // Z position of stem center (adjust if needed)

stem_diameter = 5.5;   // Diameter of circular region around the stem
stem_height = 8.0;     // Height of stem region to preserve

$fn = 128;             // Circle smoothness (128 = very smooth, 64 = balanced)

stl_filename = "Body5.stl";

// =====================================================
// MAIN MODEL
// =====================================================

union() {
    // Part 1: Scaled body WITHOUT the circular stem region
    difference() {
        // The scaled keycap body (scaled around origin, then positioned)
        translate([stem_x * (1 - body_scale_xy), stem_y * (1 - body_scale_xy), 0]) {
            scale([body_scale_xy, body_scale_xy, body_scale_z]) {
                import(stl_filename);
            }
        }

        // Cut out a cylinder where the stem is
        translate([stem_x, stem_y, stem_z]) {
            cylinder(
                h = stem_height,
                d = stem_diameter + 0.5,
                center = true
            );
        }
    }

    // Part 2: Original stem at 100% scale in CIRCULAR region
    intersection() {
        // The original unscaled model
        import(stl_filename);

        // A cylinder that defines the CIRCULAR stem region to keep
        translate([stem_x, stem_y, stem_z]) {
            cylinder(
                h = stem_height,
                d = stem_diameter,
                center = true
            );
        }
    }
}

// =====================================================
// NOTES
// =====================================================
//
// ADJUSTING THE CIRCULAR REGION POSITION:
// If the circle is not centered on the cross stem:
// 1. Open in OpenSCAD and press F5 to preview
// 2. Rotate the view to see the stem from below
// 3. Adjust stem_x and stem_y values until circle is centered on cross
// 4. Typical adjustment: try values between 208-210 for X, 222-225 for Y
//
// ITERATIVE TESTING WORKFLOW:
// 1. Start with body_scale_xy = 0.98 (98%)
// 2. Export STL and test print
// 3. If keycap is still too tight, decrease to 0.97
// 4. If keycap is too loose, increase to 0.99
// 5. Fine-tune in 0.005 increments (e.g., 0.975, 0.985)
//
// STEM DIAMETER ADJUSTMENT:
// - Increase stem_diameter if you need more clearance around the cross
// - Decrease stem_diameter for tighter tolerance
// - Typical range: 4.5mm to 6.0mm
//
// =====================================================
