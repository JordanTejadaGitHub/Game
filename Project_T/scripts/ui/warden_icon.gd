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
	if frame.size.x <= SIZE or data.footprint <= 1:
		return frame  # (Bigger one-cell art, art_direction.md bcabe980, is wider than 64 too: still whole)
	var w := minf(frame.size.x, SIZE)
	var h := minf(frame.size.y, SIZE)
	return Rect2(frame.position.x + (frame.size.x - w) / 2.0, frame.position.y + frame.size.y - h, w, h)

# The Warden's drawn pixels in frame 0 (the union over its idle frames, so the loop never leaves the crop), in sheet
# coordinates: a Warden on a disc or a tile is centred by what's drawn, not by its canvas (user, via UI Asset
# 2026-10-05: bigger forms have empty canvas around the art). The frame itself when the image can't be read; the
# 2x2 Sapling keeps its bottom square (region). Cached as plain rects, never a texture.
static var _visible := {}

static func visible_region(data: TowerData) -> Rect2:
	if data == null or data.texture == null:
		return Rect2()
	if data.footprint > 1:
		return region(data)
	var frame := data.get_frame_rect(0)
	var key := "%s:%s:%d" % [data.texture.resource_path if data.texture.resource_path != "" else str(data.texture.get_instance_id()), frame, data.frame_count]
	if _visible.has(key):
		return _visible[key]
	var result := frame
	var image := data.texture.get_image()
	if image != null and not image.is_empty():
		if image.is_compressed():
			image.decompress()
		var used := Rect2i()
		var found := false
		for i in maxi(data.frame_count, 1):
			var part := image.get_region(Rect2i(data.get_frame_rect(i))).get_used_rect()
			if part.size == Vector2i.ZERO:
				continue
			used = used.merge(part) if found else part
			found = true
		if found:
			result = Rect2(frame.position + Vector2(used.position), Vector2(used.size))
	_visible[key] = result
	return result
