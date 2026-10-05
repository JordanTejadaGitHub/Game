shader_type canvas_item;

// Withered Trees (96x128 tiles: the bottom 64 rows on their own cell, the top 64 overhang the cell above):
// the overhang fades while a Warden, a nightmare, the build ghost or the hovered / selected cell is behind
// it (TallObstacleFade picks the tile alternative; one material per alpha step). In a TileMapLayer UV spans
// the whole sheet, so the row's local v comes from the sheet's row count.
uniform float top_alpha : hint_range(0.0, 1.0) = 1.0;
uniform float rows = 9.0;  // withered_tree.png: one dead tree per row
uniform float top_share = 0.5;  // 64 of 128 rows

void fragment() {
	vec4 c = texture(TEXTURE, UV) * COLOR;
	if (fract(UV.y * rows) < top_share) {
		c.a *= top_alpha;
	}
	COLOR = c;
}
