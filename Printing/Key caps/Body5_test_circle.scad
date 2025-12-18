// TEST VERSION - Exaggerated circular cutout to verify it's working

body_scale_xy = 0.98;
body_scale_z = 1.00;

stem_diameter = 8.0;    // MUCH larger to make the circle obvious
stem_height = 10.0;     // Taller to ensure we capture everything
stem_z_position = 0;
$fn = 128;

stl_filename = "Body5.stl";

union() {
    difference() {
        scale([body_scale_xy, body_scale_xy, body_scale_z]) {
            import(stl_filename);
        }
        // Large obvious cylinder
        translate([0, 0, stem_z_position]) {
            cylinder(h = 20, d = stem_diameter + 0.5, center = true);
        }
    }

    intersection() {
        import(stl_filename);
        // Large obvious cylinder
        translate([0, 0, stem_z_position]) {
            cylinder(h = 20, d = stem_diameter, center = true);
        }
    }
}
