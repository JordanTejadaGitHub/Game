shader_type canvas_item;

// 1 = fully blighted (grey, dull), 0 = cleansed (original colours).
uniform float blight : hint_range(0.0, 1.0) = 1.0;
uniform vec3 blight_tint : source_color = vec3(0.89, 0.91, 1.0);
// Blighted brightness = floor + range * luminance. The floor lifts dark creatures off the ground
// and the range keeps their faces and markings readable; a plain luminance grey turns most of
// them into near-black blobs.
uniform float blight_floor : hint_range(0.0, 0.5) = 0.13;
uniform float blight_range : hint_range(0.0, 1.5) = 0.76;

void fragment() {
	// In Godot 4, COLOR already holds texture * vertex colour * modulate here.
	vec4 color = COLOR;
	float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	vec3 grey = min((blight_floor + blight_range * luminance) * blight_tint, vec3(1.0));
	COLOR = vec4(mix(color.rgb, grey, blight), color.a);
}
