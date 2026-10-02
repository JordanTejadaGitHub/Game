extends RefCounted
class_name WardenIcon

# A Warden's icon for UI (the Warden bar, family and offer cards): frame 0 of its idle sheet, whole (tall
# 64x96 Wardens included). Big
# Wardens (the 2×2 Heartwood Sapling: 128×160 frames) are cropped to a 64×64 square at the bottom
# centre, where the Warden sits, so they read at button size like the others.

const SIZE := 64.0

static func make(data: TowerData) -> Texture2D:
	if data == null or data.texture == null:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = data.texture
	atlas.region = region(data)
	return atlas

static func region(data: TowerData) -> Rect2:
	var frame := data.get_frame_rect(0)
	# A tall one-cell Warden (64x96: its top rises over the cell above) shows whole; only wide, multi-cell art (the
	# Sapling) is cropped (user: "some of the Wardens' top parts being cut off" in the bar, Codex, Remember).
	if frame.size.x <= SIZE:
		return frame
	var w := minf(frame.size.x, SIZE)
	var h := minf(frame.size.y, SIZE)
	return Rect2(frame.position.x + (frame.size.x - w) / 2.0, frame.position.y + frame.size.y - h, w, h)
