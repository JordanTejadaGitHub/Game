shader_type canvas_item;

// 1 = fully blighted (grey, dull), 0 = cleansed (original colours).
uniform float blight : hint_range(0.0, 1.0) = 1.0;
uniform vec3 blight_tint : source_color = vec3(0.62, 0.64, 0.7);

void fragment() {
	// In Godot 4, COLOR already holds texture * vertex colour * modulate here.
	vec4 color = COLOR;
	float luminance = dot(color.rgb, vec3(0.299, 0.587, 0.114));
	vec3 grey = luminance * blight_tint;
	COLOR = vec4(mix(color.rgb, grey, blight), color.a);
}
