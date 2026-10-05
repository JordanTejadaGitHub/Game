shader_type canvas_item;

// Big Wardens (art over 64x80): the art outside the Warden's own footprint (above and beside it) is its overhang.
// - Over the trail it stays see-through all the time (path_rects, set on path_changed by Tower), so the path reads
//   (user 2026-10-04: "when the Wardens cover the trail, make it transparent; on top of other Wardens you don't").
// - The whole overhang fades while a nightmare, the build ghost or a hovered / selected Warden is behind it (top_alpha).
// Rects are in the sprite's local pixels (VERTEX), so they hold for every sheet and frame (Tower._update_tall_fade).
uniform float top_alpha : hint_range(0.0, 1.0) = 1.0;
uniform float path_alpha : hint_range(0.0, 1.0) = 1.0;
uniform vec4 foot_rect = vec4(-32.0, -32.0, 64.0, 64.0);  // x, y, w, h
uniform int path_count = 0;
uniform vec4 path_rects[16];

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

bool inside(vec2 p, vec4 r) {
	return p.x >= r.x && p.y >= r.y && p.x < r.x + r.z && p.y < r.y + r.w;
}

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	if (!inside(local_pos, foot_rect)) {
		float a = top_alpha;
		for (int i = 0; i < path_count; i++) {
			if (inside(local_pos, path_rects[i])) {
				a = min(a, path_alpha);
				break;
			}
		}
		c.a *= a;
	}
	COLOR = c;
}
