shader_type canvas_item;

// Nightmare presence on top of the (already dark, cold) nightmare art: partly translucent with a
// slow shimmer running through it, the brightest pixels (eyes, cores) glowing a little harder.
// No recolour: the darkness lives in the sprites. `crack` splits it with lines of light (dispel).

// 1 = full nightmare presence, 0 = the plain sprite.
uniform float blight : hint_range(0.0, 1.0) = 1.0;
// Body alpha; glowing pixels stay solid. The shimmer is a slow wave of extra see-through.
uniform float translucency : hint_range(0.3, 1.0) = 0.85;
uniform float shimmer : hint_range(0.0, 0.3) = 0.08;
// Pixels brighter than glow_start (eyes, cores) are brightened by up to glow_strength.
uniform float glow_start : hint_range(0.0, 1.0) = 0.6;
uniform float glow_strength : hint_range(0.0, 2.0) = 0.5;

// 0 = whole, 1 = cracked through with light (dispel).
uniform float crack : hint_range(0.0, 1.0) = 0.0;
uniform vec3 crack_color : source_color = vec3(1.0, 0.93, 0.66);
uniform float crack_cell_px = 9.0;  // Size of the cracked shards, in texture pixels

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

// Distance to the nearest shard edge (Voronoi F2 - F1), in cells.
float shard_edge(vec2 p) {
	vec2 cell = floor(p);
	float f1 = 8.0;
	float f2 = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 o = vec2(float(x), float(y));
			float d = length(cell + o + hash2(cell + o) - p);
			if (d < f1) {
				f2 = f1;
				f1 = d;
			} else if (d < f2) {
				f2 = d;
			}
		}
	}
	return f2 - f1;
}

void fragment() {
	// In Godot 4, COLOR already holds texture * vertex colour * modulate here.
	vec4 color = COLOR;
	float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	float glow = smoothstep(glow_start, 1.0, luminance);
	float wave = sin(TIME * 2.3 + UV.y * 90.0 + UV.x * 40.0) * 0.5 + 0.5;
	float alpha = mix(translucency - shimmer * wave, 1.0, glow);
	vec3 lit = color.rgb * (1.0 + glow * glow_strength);
	COLOR = vec4(mix(color.rgb, lit, blight), color.a * mix(1.0, alpha, blight));

	if (crack > 0.0) {
		// Pixel-snapped so the cracks stay crisp on pixel art; they widen as crack goes 0 -> 1.
		vec2 px = floor(UV / TEXTURE_PIXEL_SIZE) + 0.5;
		float edge = shard_edge(px / crack_cell_px);
		float lit_crack = step(edge, crack * 0.35);
		COLOR.rgb = mix(COLOR.rgb, crack_color * 1.6, max(lit_crack, crack * crack * 0.5));
		COLOR.a = max(COLOR.a, lit_crack * color.a);
	}
}
