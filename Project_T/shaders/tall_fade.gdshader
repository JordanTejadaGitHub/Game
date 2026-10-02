shader_type canvas_item;

// Tall Wardens (64x96: the body is the bottom 64 rows, the top 32 overhang the cell above): their top band
// fades while a nightmare, or the hovered / selected cell, is behind it, so the path stays readable
// (Tower._update_tall_fade; the inland Heartwood's canopy does the same).
uniform float top_alpha : hint_range(0.0, 1.0) = 1.0;
uniform float top_share = 0.3333;  // 32 of 96 rows

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	if (UV.y < top_share) {
		c.a *= top_alpha;
	}
	COLOR = c;
}
