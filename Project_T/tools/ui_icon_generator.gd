extends SceneTree
# Generates Warden-bar tool icons in assets/ui/ (64x64 frames, one row per icon, drawn like the
# Warden sheets so they sit in the bar at the same size).
#   clear_tool.png: the Clear tool (screens_ui.md "The Clear tool"): tending hands cupped round a
#   small sprout. Frames: 0 locked (dim, a closed bud), 1 available, 2 active / selected (glowing).
# Run:  Godot --headless --path . --script res://tools/ui_icon_generator.gd

const S := 64
const OUT := "res://assets/ui/"
const PREVIEW := "res://tools/previews/ui_icons.png"

const OUTLINE := Color("#3a2618")
const SKIN_LIGHT := Color("#f0c898")
const SKIN_MID := Color("#d49a6a")
const SKIN_DARK := Color("#a86a48")
const MOSS_LIGHT := Color("#8ad060")
const MOSS_MID := Color("#5a9a48")
const MOSS_DARK := Color("#3f7a3e")
const SOIL := Color("#6a4828")
const SOIL_LIGHT := Color("#9a6e48")
const LEAF_LIGHT := Color("#a8e070")
const LEAF_MID := Color("#62b04a")
const LEAF_DARK := Color("#3a7a34")
const LEAF_OUTLINE := Color("#1e3a1a")
const GLOW_INNER := Color("#ffe8a0")
const GLOW_OUTER := Color("#ffc860")
const LIGHT_DIR := Vector2(-0.55, -0.83)

enum { LOCKED, AVAILABLE, ACTIVE }

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var sheet := Image.create(S * 3, S, false, Image.FORMAT_RGBA8)
	for state in [LOCKED, AVAILABLE, ACTIVE]:
		sheet.blit_rect(_clear_tool(state), Rect2i(0, 0, S, S), Vector2i(S * state, 0))
	sheet.save_png(OUT + "clear_tool.png")
	_save_preview(sheet)
	print("ui icons written")
	quit()

func _clear_tool(state: int) -> Image:
	var canvas := _layer()
	var lit := state == ACTIVE

	# Wrists with moss cuffs, under the hands.
	var wrists := _layer()
	for cx in [27.0, 37.0]:
		_shaded_ellipse(wrists, Vector2(cx, 54), Vector2(6, 7.5), SKIN_LIGHT, SKIN_MID, SKIN_DARK)
	_stamp(canvas, wrists, OUTLINE)
	var cuffs := _layer()
	_shaded_ellipse(cuffs, Vector2(32, 58.5), Vector2(12, 3.2), MOSS_LIGHT, MOSS_MID, MOSS_DARK)
	_stamp(canvas, cuffs, MOSS_DARK.darkened(0.45))

	# The cupped palms: a bowl, fingers curling up at both sides.
	var hands := _layer()
	_shaded_ellipse(hands, Vector2(32, 40), Vector2(20, 13), SKIN_LIGHT, SKIN_MID, SKIN_DARK, 35)
	_shaded_ellipse(hands, Vector2(13.5, 36), Vector2(5, 7.5), SKIN_LIGHT, SKIN_MID, SKIN_DARK)
	_shaded_ellipse(hands, Vector2(50.5, 36), Vector2(5, 7.5), SKIN_LIGHT, SKIN_MID, SKIN_DARK)
	_stamp(canvas, hands, OUTLINE)
	# Inside of the cup, the seam between the hands, knuckle creases on the curled fingers.
	_fill_ellipse(canvas, Vector2(32, 36), Vector2(15, 4.5), SKIN_DARK)
	_line(canvas, [Vector2(32, 41), Vector2(32, 52)], SKIN_DARK)
	_line(canvas, [Vector2(31, 45), Vector2(31, 51)], OUTLINE)
	for y in [38, 41]:
		_line(canvas, [Vector2(10, y), Vector2(13, y + 1)], SKIN_DARK)
		_line(canvas, [Vector2(54, y), Vector2(51, y + 1)], SKIN_DARK)
	# A little soil in the cup.
	var soil := _layer()
	_shaded_ellipse(soil, Vector2(32, 36.5), Vector2(9, 3), SOIL_LIGHT, SOIL, SOIL.darkened(0.3))
	_stamp(canvas, soil, OUTLINE)
	# Thumbs resting on the rim.
	var thumbs := _layer()
	_shaded_ellipse(thumbs, Vector2(21.5, 35.5), Vector2(5, 2.6), SKIN_LIGHT, SKIN_MID, SKIN_DARK)
	_shaded_ellipse(thumbs, Vector2(42.5, 35.5), Vector2(5, 2.6), SKIN_LIGHT, SKIN_MID, SKIN_DARK)
	_stamp(canvas, thumbs, OUTLINE)

	# The sprout (a closed bud while locked).
	var sprout := _layer()
	if state == LOCKED:
		_stroke(sprout, [Vector2(32, 35), Vector2(32, 29)], 1.0, LEAF_MID)
		_shaded_ellipse(sprout, Vector2(32, 26.5), Vector2(2.8, 4), LEAF_LIGHT, LEAF_MID, LEAF_DARK)
		_shaded_ellipse(sprout, Vector2(30, 31), Vector2(2.2, 1.3), LEAF_LIGHT, LEAF_MID, LEAF_DARK)
	else:
		_stroke(sprout, [Vector2(32, 35), Vector2(32.8, 25), Vector2(32, 15)], 1.1, LEAF_MID)
		_leaf(sprout, Vector2(23.5, 22.5), Vector2(8.5, 3.8), deg_to_rad(-26))
		_leaf(sprout, Vector2(40.5, 17.5), Vector2(9, 4), deg_to_rad(26))
		_shaded_ellipse(sprout, Vector2(32, 13), Vector2(2.2, 2.8), LEAF_LIGHT, LEAF_MID, LEAF_DARK)
	_stamp(canvas, sprout, LEAF_OUTLINE)
	if state != LOCKED:
		# Leaf veins and the bud's highlight.
		_line(canvas, [Vector2(17, 25), Vector2(29, 20)], LEAF_DARK)
		_line(canvas, [Vector2(35, 20), Vector2(47, 15)], LEAF_DARK)
		_px(canvas, 31, 11, LEAF_LIGHT.lightened(0.4))

	if state == LOCKED:
		_dim(canvas)
		return canvas

	# Warm light from the sprout, onto the thumbs and fingertips when active.
	if lit:
		_rim_light(canvas)
		_warm_glow(canvas, Vector2(32, 21), Vector2(26, 20))
		for p: Vector2i in [Vector2i(9, 20), Vector2i(53, 8), Vector2i(55, 26), Vector2i(14, 6)]:
			_sparkle(canvas, p)
	else:
		_warm_glow(canvas, Vector2(32, 20), Vector2(14, 11), true)
	return canvas

func _leaf(layer: Image, c: Vector2, r: Vector2, angle: float) -> void:
	for y in S:
		for x in S:
			var d := (Vector2(x + 0.5, y + 0.5) - c).rotated(-angle) / r
			if d.length() > 1.0:
				continue
			var col := LEAF_MID
			if d.y < -0.25:
				col = LEAF_LIGHT
			elif d.y > 0.45:
				col = LEAF_DARK
			layer.set_pixel(x, y, col)

# Locked: grey the whole icon down so it reads as asleep.
func _dim(canvas: Image) -> void:
	var slate := Color("#6a6e80")
	for y in S:
		for x in S:
			var col := canvas.get_pixel(x, y)
			if col.a == 0.0:
				continue
			var grey := Color(col.get_luminance(), col.get_luminance(), col.get_luminance())
			var out := grey.lerp(slate, 0.45).lerp(col, 0.25).darkened(0.2)
			out.a = col.a
			canvas.set_pixel(x, y, out)

# Warms the light pixels facing the sprout (upper edges of the hands).
func _rim_light(canvas: Image) -> void:
	for y in range(24, 50):
		for x in S:
			var col := canvas.get_pixel(x, y)
			if col.a == 0.0 or col == OUTLINE:
				continue
			if col == SKIN_LIGHT or col == SKIN_MID:
				var near := 1.0 - clampf((Vector2(x, y) - Vector2(32, 26)).length() / 24.0, 0.0, 1.0)
				canvas.set_pixel(x, y, col.lerp(GLOW_INNER, 0.2 + 0.5 * near))

func _sparkle(canvas: Image, p: Vector2i) -> void:
	for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if canvas.get_pixelv(p + d).a == 0.0 or canvas.get_pixelv(p + d) == GLOW_OUTER or canvas.get_pixelv(p + d) == GLOW_INNER:
			_px(canvas, p.x + d.x, p.y + d.y, GLOW_OUTER)
	_px(canvas, p.x, p.y, Color("#fffbe8"))

# --- Drawing helpers (same conventions as tower_art_generator.gd) ---

func _layer() -> Image:
	return Image.create(S, S, false, Image.FORMAT_RGBA8)

func _px(canvas: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < S and y < S:
		canvas.set_pixel(x, y, color)

func _fill_ellipse(canvas: Image, c: Vector2, r: Vector2, color: Color) -> void:
	for y in S:
		for x in S:
			if ((Vector2(x + 0.5, y + 0.5) - c) / r).length() <= 1.0 and canvas.get_pixel(x, y).a > 0.0 \
					and canvas.get_pixel(x, y) != OUTLINE:
				canvas.set_pixel(x, y, color)

# An ellipse lit from the top left; rows above min_y are cut off.
func _shaded_ellipse(layer: Image, c: Vector2, r: Vector2, light: Color, mid: Color, dark: Color, min_y: int = -1) -> void:
	for y in range(maxi(0, min_y), S):
		for x in S:
			var d := (Vector2(x + 0.5, y + 0.5) - c) / r
			if d.length() > 1.0:
				continue
			var t := d.dot(LIGHT_DIR)
			layer.set_pixel(x, y, light if t > 0.35 else (dark if t < -0.45 else mid))

func _stroke(layer: Image, pts: Array, radius: float, color: Color) -> void:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		for y in S:
			for x in S:
				var p := Vector2(x + 0.5, y + 0.5)
				var t := clampf((p - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
				if p.distance_to(a.lerp(b, t)) <= radius:
					layer.set_pixel(x, y, color)

func _line(canvas: Image, pts: Array, color: Color) -> void:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
		for s in steps + 1:
			var p := a.lerp(b, s / maxf(steps, 1.0)).round()
			_px(canvas, int(p.x), int(p.y), color)

# Copies a layer onto the canvas, turning the layer's own border pixels into an outline.
func _stamp(canvas: Image, layer: Image, outline: Color) -> void:
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for y in S:
		for x in S:
			var col := layer.get_pixel(x, y)
			if col.a == 0.0:
				continue
			for d: Vector2i in dirs:
				var p: Vector2i = Vector2i(x, y) + d
				if p.x < 0 or p.y < 0 or p.x >= S or p.y >= S or layer.get_pixelv(p).a == 0.0:
					col = outline
					break
			canvas.set_pixel(x, y, col)

# Dithered warm light on empty pixels only.
func _warm_glow(canvas: Image, c: Vector2, r: Vector2, soft: bool = false) -> void:
	for y in range(maxi(0, floori(c.y - r.y)), mini(S, ceili(c.y + r.y) + 1)):
		for x in range(maxi(0, floori(c.x - r.x)), mini(S, ceili(c.x + r.x) + 1)):
			if canvas.get_pixel(x, y).a > 0.0:
				continue
			var q := ((Vector2(x + 0.5, y + 0.5) - c) / r).length()
			if q < 0.6 and (x + y) % 2 == 0 and not (soft and (x + 2 * y) % 4 != 0):
				canvas.set_pixel(x, y, GLOW_INNER)
			elif q < 1.0 and (x + 2 * y) % 4 == 0:
				canvas.set_pixel(x, y, GLOW_OUTER)

# The sheet at 4x on a bar-coloured strip, then each frame at bar size (34 px).
func _save_preview(sheet: Image) -> void:
	var big := sheet.duplicate() as Image
	big.resize(S * 3 * 4, S * 4, Image.INTERPOLATE_NEAREST)
	var preview := Image.create(S * 3 * 4 + 16, S * 4 + 16 + 50, false, Image.FORMAT_RGBA8)
	preview.fill(Color("#1c2230"))
	preview.blend_rect(big, Rect2i(0, 0, big.get_width(), big.get_height()), Vector2i(8, 8))
	for i in 3:
		var frame := sheet.get_region(Rect2i(S * i, 0, S, S))
		frame.resize(34, 34, Image.INTERPOLATE_BILINEAR)
		preview.blend_rect(frame, Rect2i(0, 0, 34, 34), Vector2i(8 + i * S * 4 + S * 2 - 17, S * 4 + 16))
	preview.save_png(PREVIEW)
