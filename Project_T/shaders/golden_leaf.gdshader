shader_type canvas_item;

// The Golden Leaf keepsake (meta_design.md "Keepsakes"): the in-run Heartwood's leaves drawn gold. A palette
// swap: each canopy green (from[i]) becomes its gold-family shade (to[i]), only in the crown rows of each frame
// (the trunk's moss stays green), so the leaf-loss rot and the art's values hold. Colours come from Palette
// (Heartwood.GOLDEN_FROM / GOLDEN_TO). Sprite2D frames: UV spans the whole sheet, so the frame-local v comes
// from the frame count.
uniform vec3 from_colours[6];
uniform vec3 to_colours[6];
uniform vec2 frames = vec2(4.0, 21.0);
uniform float crown_bottom = 0.6;  // Frame-local v below which (upwards) leaves are swapped

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	if (fract(UV.y * frames.y) < crown_bottom) {
		for (int i = 0; i < 6; i++) {
			if (distance(c.rgb, from_colours[i]) < 0.02) {
				c.rgb = to_colours[i];
				break;
			}
		}
	}
	COLOR = c * COLOR;
}
