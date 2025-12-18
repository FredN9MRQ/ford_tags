// Simple test for Fred text rendering
name = "Fred";
text_size = 13;

color("white")
translate([0, 0, 1.5])
    linear_extrude(height=1)
        text(name,
             size=text_size,
             font="Fordscript",
             halign="center",
             valign="center");
