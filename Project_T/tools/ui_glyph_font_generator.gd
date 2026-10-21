extends SceneTree

# Saves the resource glyph font (UiStyle.GLYPH_FONT_PATH): the private-use characters UiStyle.GLYPHS drawn as the
# Dew, Dreamlight and Seeds icons from assets/ui/icons.png, so any Label, Button, tooltip or RichTextLabel shows
# "<icon>15" through the theme fonts' fallback (user via Main Merger 2026-10-06: prices and rewards are the
# resource icon and the number, never "15 Dew").
# The font is a tiny TrueType file made here (a character map for the glyphs, empty outlines) with the icons as
# RGBA bitmaps in its fixed-size cache: Godot draws a colour bitmap untinted only when the font has a real face,
# so the icons keep their colours next to a GOLD or POOR number. The art is upscaled by whole pixels (crisp),
# then scaled to the text's size like any glyph. Re-run it after the icons change, then tools/ui_theme_generator.gd:
#   godot --headless --path . --script res://tools/ui_glyph_font_generator.gd

const ICONS := "res://assets/ui/icons.png"
const ICONS_JSON := "res://assets/ui/icons.json"
const PIXEL := 4  # Font pixels per art pixel in the atlas
const ICON_EM := 0.8  # The tallest icon fills this share of the font size, about the digits' height
const PAD := 2  # Atlas pixels between glyphs

func _initialize() -> void:
	var sheet: Image = (load(ICONS) as Texture2D).get_image()
	sheet.decompress()
	sheet.convert(Image.FORMAT_RGBA8)
	var json: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ICONS_JSON))
	var frame: int = int(json.get("frame_size", 16))
	var icons: Dictionary = json.icons
	var arts: Array[Image] = []
	var tallest := 0
	for entry in UiStyle.GLYPHS:
		var art := sheet.get_region(Rect2i(int(icons[entry[1]]) * frame, 0, frame, frame))
		art = art.get_region(art.get_used_rect())  # Trimmed to its drawn pixels
		art.resize(art.get_width() * PIXEL, art.get_height() * PIXEL, Image.INTERPOLATE_NEAREST)
		arts.append(art)
		tallest = maxi(tallest, art.get_height())
	var size := int(round(tallest / ICON_EM))  # The font's own size: every icon keeps the same pixel scale
	var atlas_w := PAD
	for art in arts:
		atlas_w += art.get_width() + PAD
	var atlas := Image.create_empty(atlas_w, tallest + PAD * 2, false, Image.FORMAT_RGBA8)
	var sink := roundi(size * 0.06)  # The icon sits a little below the baseline, like round letters
	var side := roundi(size * 0.05)
	var codes: Array[int] = []
	var advances: Array[int] = []  # In font units (1000 per em): the text takes the advance from the face
	for i in arts.size():
		codes.append(int(UiStyle.GLYPHS[i][0]))
		advances.append(roundi((arts[i].get_width() + side * 3) * 1000.0 / size))
	var font := FontFile.new()
	font.data = _truetype(codes, advances)
	font.font_name = "Heartwood Glyphs"
	font.fixed_size = size
	font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_ENABLED
	font.allow_system_fallback = false
	var key := Vector2i(size, 0)
	font.set_cache_ascent(0, size, size * 0.8)  # Never taller than the body face, so lines keep their height
	font.set_cache_descent(0, size, size * 0.2)
	var x := PAD
	for i in arts.size():
		var image := arts[i]
		var glyph := i + 1  # Glyph indices in the TrueType file: 0 is .notdef
		atlas.blit_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), Vector2i(x, PAD))
		font.set_glyph_texture_idx(0, key, glyph, 0)
		font.set_glyph_uv_rect(0, key, glyph, Rect2(x, PAD, image.get_width(), image.get_height()))
		font.set_glyph_size(0, key, glyph, Vector2(image.get_size()))
		font.set_glyph_offset(0, key, glyph, Vector2(side, -image.get_height() + sink))
		font.set_glyph_advance(0, size, glyph, Vector2(image.get_width() + side * 3, 0))
		x += image.get_width() + PAD
	font.set_texture_image(0, key, 0, atlas)
	var error := ResourceSaver.save(font, UiStyle.GLYPH_FONT_PATH)
	print("Saved %s: size %d, %d glyphs (error %d)" % [UiStyle.GLYPH_FONT_PATH, size, arts.size(), error])
	quit(error)

# A minimal TrueType font: `codes` map to glyphs 1…n (empty outlines), glyph 0 is .notdef. Just enough for FreeType
# to give the font a face and a character map; the drawing comes from the bitmap cache.
func _truetype(codes: Array[int], advances: Array[int]) -> PackedByteArray:
	var glyphs := codes.size() + 1
	var tables := {}
	tables["cmap"] = _cmap(codes)
	tables["glyf"] = PackedByteArray([0, 0, 0, 0])
	var head := _be()
	for v in [[4, 0x00010000], [4, 0x00010000], [4, 0], [4, 0x5F0F3CF5], [2, 0x000B], [2, 1000], [8, 0], [8, 0],
			[2, 0], [2, 0], [2, 1000], [2, 800], [2, 0], [2, 8], [2, 2], [2, 0], [2, 0]]:
		_put(head, v[0], v[1])  # version, revision, checksum adj., magic, flags, units/em, dates, bbox, style…, short loca
	tables["head"] = head.data_array
	var hhea := _be()
	for v in [[4, 0x00010000], [2, 800], [2, 0x10000 - 200], [2, 0], [2, 1000], [2, 0], [2, 0], [2, 1000], [2, 1], [2, 0],
			[2, 0], [2, 0], [2, 0], [2, 0], [2, 0], [2, 0], [2, glyphs]]:
		_put(hhea, v[0], v[1])  # version, ascender, descender, gap, max advance, …, caret, reserved, metric format, hmetrics
	tables["hhea"] = hhea.data_array
	var hmtx := _be()
	for g in glyphs:
		_put(hmtx, 2, 1000 if g == 0 else advances[g - 1])
		_put(hmtx, 2, 0)
	tables["hmtx"] = hmtx.data_array
	var loca := _be()
	for g in glyphs + 1:
		_put(loca, 2, 0)  # Every glyph empty
	tables["loca"] = loca.data_array
	var maxp := _be()
	_put(maxp, 4, 0x00010000)
	_put(maxp, 2, glyphs)
	for v in [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0]:  # maxPoints…maxComponentDepth (maxZones 1)
		_put(maxp, 2, v)
	tables["maxp"] = maxp.data_array
	var post := _be()
	for v in [[4, 0x00030000], [4, 0], [2, 0], [2, 0], [4, 0], [4, 0], [4, 0], [4, 0], [4, 0]]:
		_put(post, v[0], v[1])
	tables["post"] = post.data_array
	var tags := tables.keys()
	tags.sort()
	var out := _be()
	var count := tags.size()
	var power := 1
	while power * 2 <= count:
		power *= 2
	for v in [[4, 0x00010000], [2, count], [2, power * 16], [2, int(log(power) / log(2))], [2, count * 16 - power * 16]]:
		_put(out, v[0], v[1])
	var offset := 12 + count * 16
	var body := PackedByteArray()
	for tag in tags:
		var data: PackedByteArray = tables[tag]
		out.put_data(String(tag).to_ascii_buffer())
		_put(out, 4, _checksum(data))
		_put(out, 4, offset + body.size())
		_put(out, 4, data.size())
		body.append_array(data)
		while body.size() % 4 != 0:
			body.append(0)
	out.put_data(body)
	return out.data_array

# cmap with one format 4 subtable (Windows, Unicode BMP): one segment per code, then the 0xFFFF end segment.
func _cmap(codes: Array[int]) -> PackedByteArray:
	var segs := codes.size() + 1
	var sub := _be()
	_put(sub, 2, 4)
	_put(sub, 2, 16 + segs * 8)  # length
	_put(sub, 2, 0)  # language
	var power := 1
	while power * 2 <= segs:
		power *= 2
	_put(sub, 2, segs * 2)
	_put(sub, 2, power * 2)
	_put(sub, 2, int(log(power) / log(2)))
	_put(sub, 2, segs * 2 - power * 2)
	for code in codes:
		_put(sub, 2, code)  # endCode
	_put(sub, 2, 0xFFFF)
	_put(sub, 2, 0)  # reservedPad
	for code in codes:
		_put(sub, 2, code)  # startCode
	_put(sub, 2, 0xFFFF)
	for i in codes.size():
		_put(sub, 2, (i + 1 - codes[i]) & 0xFFFF)  # idDelta: code -> glyph i + 1
	_put(sub, 2, 1)
	for i in segs:
		_put(sub, 2, 0)  # idRangeOffset
	var cmap := _be()
	for v in [0, 1, 3, 1]:
		_put(cmap, 2, v)  # version, tables, platform 3, encoding 1
	_put(cmap, 4, 12)
	cmap.put_data(sub.data_array)
	return cmap.data_array

func _be() -> StreamPeerBuffer:
	var b := StreamPeerBuffer.new()
	b.big_endian = true
	return b

func _put(b: StreamPeerBuffer, bytes: int, value: int) -> void:
	match bytes:
		2: b.put_u16(value & 0xFFFF)
		4: b.put_u32(value & 0xFFFFFFFF)
		8: b.put_u64(value)

func _checksum(data: PackedByteArray) -> int:
	var sum := 0
	var padded := data.duplicate()
	while padded.size() % 4 != 0:
		padded.append(0)
	for i in range(0, padded.size(), 4):
		sum = (sum + (padded[i] << 24 | padded[i + 1] << 16 | padded[i + 2] << 8 | padded[i + 3])) & 0xFFFFFFFF
	return sum
