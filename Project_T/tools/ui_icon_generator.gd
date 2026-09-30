extends SceneTree
# Generates Warden-bar tool icons in assets/ui/ (64x64 frames, one row per icon, drawn like the
# Warden sheets so they sit in the bar at the same size).
#   clear_tool.png: the Clear tool (screens_ui.md "The Clear tool"): tending hands cupped round a
#   small sprout. Frames: 0 locked (dim, a closed bud), 1 available, 2 active / selected (glowing).
# Run:  Godot --headless --path . --script res://tools/ui_icon_generator.gd

const S := 64
const OUT := "res://assets/ui/"
const PREVIEW := "res://tools/previews/ui_icons.png"
# Every pixel is snapped to the Heartwood 32 palette (art_direction.md); nightmare icons to its cold ramps.
const Palette := preload("res://tools/art/heartwood_palette.gd")

const OUTLINE := Color("#3a2618")
var SKIN_LIGHT := Palette.color("moonpath")
var SKIN_MID := Palette.color("deadwood")
var SKIN_DARK := Palette.color("oak")
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
	Palette.snap_image(sheet)
	sheet.save_png(OUT + "clear_tool.png")
	_save_preview(sheet)
	_make_icons()
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

# --- Status and stat icons (screens_ui.md "Stat and status icons") -------------------------------
# 16 px icons in one row (assets/ui/icons.png) with assets/ui/icons.json ({id: column}). Each icon
# is built from shapes on a 16x16 grid of cells; every cell gets its ramp's light colour on its
# top/left edge, dark on its bottom/right edge, mid inside, and the shape gets a dark 1 px outline.
# Statuses differ by SHAPE, not only colour. No icons for combos or Reactions: they are discovered.

const ICON := 16
const ICON_OUTLINE := Color("#1a1420")
const STATUS_ICONS := ["damp", "drowsy", "spored", "marked", "static", "held", "caught", "frozen", "deeply_blighted", "hidden"]
const STAT_ICONS := ["damage", "attack_speed", "range", "crit_chance", "crit_damage", "potency", "rank",
	"focus_power", "focus_swift", "focus_reach", "focus_deep", "dew_cost", "dreamlight_cost"]
# Nightmare traits and boss abilities (screens_ui.md "Nightmare info", "Boss dossier"), in a cold
# palette (warm is for Wardens). The trait "hidden" reuses the status icon of the same id.
const NIGHTMARE_ICONS := ["flying", "dread_shell", "through_walls", "sprints", "rises",
	"trample", "charge", "sink", "bog_water", "eclipse", "brood", "sapling", "grief",
	"wanders", "splits", "ignores_slows", "leap", "mender", "waker", "revealer", "ash", "thief",
	"followers", "swarm", "bulky"]
# Warden damage types (enemy_design.md "Damage types"): a warm symbol on a small gold-rimmed badge,
# so they never read as statuses (which have no badge).
const DAMAGE_TYPE_ICONS := ["spore", "stone", "water", "light", "root", "song", "wing", "wind", "plain"]

# Run resources for the HUD counters (ui_style.md): leaves, path length, Seeds. Dew and Dreamlight
# reuse the cost icons (aliases "dew", "dreamlight").
const RESOURCE_ICONS := ["leaves", "path_length", "seeds"]
# Omens (run_design.md "How an Omen looks"): a moth before the moon, and the calm moon of Clear Skies.
const OMEN_ICONS := ["omen", "clear_skies"]
# Ids that share another icon's column.
const ICON_ALIASES := {"always_damp": "damp", "burrows": "rises", "dew": "dew_cost", "dreamlight": "dreamlight_cost"}

var _cells := {}  # Vector2i -> ramp index
var _ramps: Array = []  # [light, mid, dark]
var _details: Array = []  # [Vector2i, Color], painted last

func _make_icons() -> void:
	var ids: Array = STATUS_ICONS + STAT_ICONS + NIGHTMARE_ICONS + DAMAGE_TYPE_ICONS + RESOURCE_ICONS + OMEN_ICONS
	var sheet := Image.create(ICON * ids.size(), ICON, false, Image.FORMAT_RGBA8)
	var index := {}
	for i in ids.size():
		var icon := _icon(ids[i])
		Palette.snap_image(icon, ids[i] in NIGHTMARE_ICONS)
		sheet.blit_rect(icon, Rect2i(0, 0, ICON, ICON), Vector2i(i * ICON, 0))
		index[ids[i]] = i
	for alias: String in ICON_ALIASES:
		index[alias] = index[ICON_ALIASES[alias]]
	sheet.save_png(OUT + "icons.png")
	var data := {frame_size = ICON, icons = index, statuses = STATUS_ICONS, stats = STAT_ICONS,
		nightmare = NIGHTMARE_ICONS + ["hidden", "always_damp", "burrows"], damage_type = DAMAGE_TYPE_ICONS,
		resources = RESOURCE_ICONS + ["dew", "dreamlight"],
		omen = OMEN_ICONS,
		note = "One row of 16x16 icons; column = icons[id]. Readable at 12 px; for 24-32 px panels scale by whole numbers with nearest filtering."}
	var file := FileAccess.open(OUT + "icons.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t") + "\n")
	# Preview: 4x on a dark panel, then 2x and 1x on grass.
	var n := ids.size()
	var pre := Image.create(n * 72 + 8, 168, false, Image.FORMAT_RGBA8)
	pre.fill(Color("#1c2230"))
	var grass := Image.create(n * 72 + 8, 84, false, Image.FORMAT_RGBA8)
	grass.fill(Color("#5fa844"))
	pre.blit_rect(grass, Rect2i(0, 0, n * 72 + 8, 84), Vector2i(0, 84))
	for i in n:
		var ic := sheet.get_region(Rect2i(i * ICON, 0, ICON, ICON))
		var big := ic.duplicate() as Image
		big.resize(64, 64, Image.INTERPOLATE_NEAREST)
		pre.blend_rect(big, Rect2i(0, 0, 64, 64), Vector2i(8 + i * 72, 8))
		var mid := ic.duplicate() as Image
		mid.resize(32, 32, Image.INTERPOLATE_NEAREST)
		pre.blend_rect(mid, Rect2i(0, 0, 32, 32), Vector2i(8 + i * 72, 100))
		pre.blend_rect(ic, Rect2i(0, 0, ICON, ICON), Vector2i(48 + i * 72, 108))
	pre.save_png("res://tools/previews/ui_icon_set.png")

func _icon(id: String) -> Image:
	_cells = {}
	_ramps = []
	_details = []
	call("_ic_" + id)
	var img := Image.create(ICON, ICON, false, Image.FORMAT_RGBA8)
	for cell: Vector2i in _cells:
		var k: int = _cells[cell]
		var r: Array = _ramps[k]
		var up: bool = _cells.get(cell + Vector2i.UP, -1) != k
		var left: bool = _cells.get(cell + Vector2i.LEFT, -1) != k
		var down: bool = _cells.get(cell + Vector2i.DOWN, -1) != k
		var right: bool = _cells.get(cell + Vector2i.RIGHT, -1) != k
		var col: Color = r[1]
		if up or left:
			col = r[0]
		elif down or right:
			col = r[2]
		img.set_pixelv(cell, col)
	for y in ICON:
		for x in ICON:
			var p := Vector2i(x, y)
			if _cells.has(p):
				continue
			for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if _cells.has(p + d):
					img.set_pixelv(p, ICON_OUTLINE)
					break
	for d: Array in _details:
		var p: Vector2i = d[0]
		if p.x >= 0 and p.y >= 0 and p.x < ICON and p.y < ICON:
			img.set_pixelv(p, d[1])
	return img

func _rp(light: String, mid: String, dark: String) -> int:
	_ramps.append([Color(light), Color(mid), Color(dark)])
	return _ramps.size() - 1

func _cset(x: int, y: int, k: int) -> void:
	if x >= 0 and y >= 0 and x < ICON and y < ICON:
		_cells[Vector2i(x, y)] = k

func _c_disc(c: Vector2, r: float, k: int) -> void:
	for y in ICON:
		for x in ICON:
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r:
				_cset(x, y, k)

func _c_ring(c: Vector2, ro: float, ri: float, k: int) -> void:
	for y in ICON:
		for x in ICON:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d <= ro and d > ri:
				_cset(x, y, k)

func _c_ell(c: Vector2, r: Vector2, k: int, angle: float = 0.0) -> void:
	for y in ICON:
		for x in ICON:
			if ((Vector2(x + 0.5, y + 0.5) - c).rotated(-angle) / r).length() <= 1.0:
				_cset(x, y, k)

func _c_poly(pts: PackedVector2Array, k: int) -> void:
	for y in ICON:
		for x in ICON:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				_cset(x, y, k)

func _c_line(pts: Array, w: float, k: int) -> void:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		for y in ICON:
			for x in ICON:
				var p := Vector2(x + 0.5, y + 0.5)
				var t := clampf((p - a).dot(b - a) / maxf((b - a).length_squared(), 0.001), 0.0, 1.0)
				if p.distance_to(a.lerp(b, t)) <= w * 0.5:
					_cset(x, y, k)

func _c_rect(r: Rect2i, k: int) -> void:
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			_cset(x, y, k)

func _dt(x: int, y: int, col: Color) -> void:
	_details.append([Vector2i(x, y), col])

func _dt_line(a: Vector2i, b: Vector2i, col: Color) -> void:
	var steps := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for s in steps + 1:
		var p := Vector2(a).lerp(Vector2(b), s / maxf(steps, 1.0)).round()
		_dt(int(p.x), int(p.y), col)

# Statuses ---------------------------------------------------------------------------------------

func _ic_damp() -> void:
	var k := _rp("#d8f0ff", "#6ab0f0", "#3a70c0")
	_c_disc(Vector2(7, 9.6), 4.2, k)
	_c_poly(PackedVector2Array([Vector2(7, 1.6), Vector2(3.0, 8.6), Vector2(11.0, 8.6)]), k)
	_c_disc(Vector2(12.6, 12.4), 1.8, k)
	_c_poly(PackedVector2Array([Vector2(12.6, 8.8), Vector2(11.0, 11.8), Vector2(14.2, 11.8)]), k)
	_dt(5, 8, Color.WHITE)
	_dt(5, 9, Color("#f0faff"))

func _ic_drowsy() -> void:
	var k := _rp("#f4ecff", "#c8a8f0", "#8a6ac8")
	_c_rect(Rect2i(2, 2, 8, 2), k)
	_c_line([Vector2(9, 4.2), Vector2(3, 9.8)], 2.2, k)
	_c_rect(Rect2i(2, 10, 8, 2), k)
	_c_rect(Rect2i(10, 9, 4, 1), k)
	_c_line([Vector2(13.4, 10), Vector2(10.6, 12.6)], 1.3, k)
	_c_rect(Rect2i(10, 13, 4, 1), k)

func _ic_spored() -> void:
	var k := _rp("#e8f8b0", "#a8d860", "#5a8a30")
	_c_disc(Vector2(9.6, 5), 3.2, k)
	_c_disc(Vector2(4.6, 10.2), 3.0, k)
	_c_disc(Vector2(11.8, 12), 2.3, k)
	for p: Vector2i in [Vector2i(8, 3), Vector2i(3, 8), Vector2i(11, 11)]:
		_dt(p.x, p.y, Color.WHITE)
	for p: Vector2i in [Vector2i(10, 6), Vector2i(5, 11)]:
		_dt(p.x, p.y, Color("#5a8a30"))

func _ic_marked() -> void:
	var k := _rp("#fff4b0", "#f0c040", "#a87818")
	_c_ring(Vector2(8, 8), 6.3, 4.1, k)
	_c_disc(Vector2(8, 8), 1.7, k)
	_dt(7, 7, Color.WHITE)

func _ic_static() -> void:
	var k := _rp("#fffbe0", "#fff27a", "#d0a820")
	_c_poly(PackedVector2Array([Vector2(9.5, 1), Vector2(3.4, 8.6), Vector2(7, 8.6), Vector2(5.4, 14.8),
		Vector2(12.6, 6.4), Vector2(8.8, 6.4), Vector2(11.6, 1)]), k)

func _ic_held() -> void:
	# A small dark nightmare tied up by two vine bands.
	var shade := _rp("#6a5a90", "#3e3060", "#241a3a")
	var vine := _rp("#c8f0a0", "#6ab04a", "#2e6a2a")
	_c_disc(Vector2(8, 8.5), 5.2, shade)
	_c_line([Vector2(1.2, 5.2), Vector2(8, 6.6), Vector2(14.8, 5.8)], 1.9, vine)
	_c_line([Vector2(1.2, 11.4), Vector2(8, 10.4), Vector2(14.8, 11.8)], 1.9, vine)
	_dt(6, 8, Color("#ffd0e0"))
	_dt(10, 8, Color("#ffd0e0"))
	_dt(14, 4, Color("#a8dc7a"))
	_dt(13, 3, Color("#a8dc7a"))

func _ic_caught() -> void:
	var k := _rp("#f4ecff", "#c8a8f0", "#7a5ab8")
	var gold := _rp("#fff0b0", "#f0c050", "#a87020")
	_c_ring(Vector2(8, 6.2), 5.4, 3.7, k)
	_c_ell(Vector2(4.5, 13.2), Vector2(1.3, 1.9), gold)
	_c_ell(Vector2(11.5, 13.2), Vector2(1.3, 1.9), gold)
	var web := Color("#b898e8")
	_dt_line(Vector2i(8, 3), Vector2i(8, 9), web)
	_dt_line(Vector2i(5, 6), Vector2i(11, 6), web)
	_dt(8, 6, Color("#ffe890"))
	_dt(5, 11, web)
	_dt(11, 11, web)

func _ic_frozen() -> void:
	var k := _rp("#f4fcff", "#9ad8f0", "#4a90c8")
	var c := Vector2(8, 8)
	for i in 3:
		var d := Vector2.from_angle(PI * 0.5 + i * PI / 3.0)
		_c_line([c - d * 6.3, c + d * 6.3], 1.3, k)
		for s: float in [-1.0, 1.0]:
			var p := c + d * 4.2 * s
			_c_line([p, p + d.rotated(0.8) * 1.8 * s], 1.1, k)
			_c_line([p, p + d.rotated(-0.8) * 1.8 * s], 1.1, k)
	_c_disc(c, 1.8, k)
	_dt(8, 8, Color.WHITE)

func _ic_deeply_blighted() -> void:
	var k := _rp("#7a5aa8", "#4a3270", "#2a1a40")
	_c_disc(Vector2(8, 9), 5.0, k)
	_c_poly(PackedVector2Array([Vector2(4.2, 6), Vector2(2.6, 1.2), Vector2(6.8, 4.4)]), k)
	_c_poly(PackedVector2Array([Vector2(6.8, 4.4), Vector2(8, 1.0), Vector2(9.4, 4.4)]), k)
	_c_poly(PackedVector2Array([Vector2(11.8, 6), Vector2(13.4, 1.2), Vector2(9.2, 4.4)]), k)
	_c_poly(PackedVector2Array([Vector2(3.4, 8), Vector2(1.0, 10), Vector2(3.6, 11)]), k)
	_c_poly(PackedVector2Array([Vector2(12.6, 8), Vector2(15.0, 10), Vector2(12.4, 11)]), k)
	for x in range(6, 10):
		_dt(x, 8, Color("#ffd0e0"))
		_dt(x, 9, Color("#ffd0e0"))
	_dt(7, 8, Color("#ff3a6a"))
	_dt(8, 8, Color("#ff3a6a"))
	_dt(7, 9, Color("#c01a4a"))
	_dt(8, 9, Color("#c01a4a"))
	_dt(6, 13, Color("#2a1a40"))
	_dt(10, 14, Color("#2a1a40"))

func _ic_hidden() -> void:
	var k := _rp("#ffffff", "#e0dcf0", "#8a84b0")
	for y in ICON:
		for x in ICON:
			var p := Vector2(x + 0.5, y + 0.5)
			if p.distance_to(Vector2(8, 15.5)) <= 10.5 and p.distance_to(Vector2(8, 0.5)) <= 10.5 and x >= 1 and x <= 14:
				_cset(x, y, k)
	for y in range(6, 10):
		for x in range(6, 10):
			if Vector2(x + 0.5, y + 0.5).distance_to(Vector2(8, 8)) <= 2.2:
				_dt(x, y, Color("#6a4ab0"))
	_dt(7, 7, Color("#241634"))
	_dt(8, 7, Color("#241634"))
	_dt(7, 8, Color("#241634"))
	_dt(8, 8, Color("#241634"))
	_dt(7, 7, Color.WHITE)
	# The slash: a light stroke with a dark edge, over everything.
	_dt_line(Vector2i(3, 14), Vector2i(14, 3), ICON_OUTLINE)
	_dt_line(Vector2i(2, 13), Vector2i(13, 2), Color("#fff4f8"))
	_dt_line(Vector2i(1, 13), Vector2i(12, 2), ICON_OUTLINE)

# Warden stats -----------------------------------------------------------------------------------

func _ic_damage() -> void:
	var k := _rp("#ffe8b0", "#f09040", "#b05020")
	var c := Vector2(8, 8)
	for i in 8:
		var d := Vector2.from_angle(i * PI / 4.0 - PI * 0.5)
		var tip := c + d * (6.9 if i % 2 == 0 else 5.4)
		var perp := d.orthogonal() * 1.7
		_c_poly(PackedVector2Array([c + d * 2.5 + perp, tip, c + d * 2.5 - perp]), k)
	_c_disc(c, 3.6, k)
	_dt(7, 7, Color.WHITE)
	_dt(8, 7, Color("#fff8e0"))
	_dt(7, 8, Color("#fff8e0"))

func _ic_attack_speed() -> void:
	var k := _rp("#e8fff0", "#7ad8a8", "#2e8a60")
	_c_line([Vector2(3, 2.6), Vector2(7.4, 8), Vector2(3, 13.4)], 2.3, k)
	_c_line([Vector2(8.4, 2.6), Vector2(12.8, 8), Vector2(8.4, 13.4)], 2.3, k)

func _ic_range() -> void:
	var k := _rp("#f0f6ff", "#9ab8e8", "#4a68a8")
	_c_line([Vector2(4, 8), Vector2(12, 8)], 2.0, k)
	_c_poly(PackedVector2Array([Vector2(1.0, 8), Vector2(5.2, 3.8), Vector2(5.2, 12.2)]), k)
	_c_poly(PackedVector2Array([Vector2(15.0, 8), Vector2(10.8, 3.8), Vector2(10.8, 12.2)]), k)

func _ic_crit_chance() -> void:
	# A four-leaf clover: leaves on the cross, gaps on the diagonals, a stem.
	var leaf := _rp("#d8f8b0", "#6ab04a", "#2e6a2a")
	_c_line([Vector2(9, 10), Vector2(13.6, 14.6)], 1.3, leaf)
	for d: Vector2 in [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]:
		_c_disc(Vector2(7.5, 7.5) + d * 3.4, 2.5, leaf)
	_dt(7, 7, Color("#fff27a"))
	_dt(8, 8, Color("#e8c040"))

func _ic_crit_damage() -> void:
	var k := _rp("#fffbe0", "#ffd24a", "#c08a10")
	_c_poly(PackedVector2Array([Vector2(8, 0.8), Vector2(9.9, 6.1), Vector2(15.2, 8), Vector2(9.9, 9.9),
		Vector2(8, 15.2), Vector2(6.1, 9.9), Vector2(0.8, 8), Vector2(6.1, 6.1)]), k)
	_dt(8, 8, Color.WHITE)
	_dt(7, 7, Color.WHITE)

func _ic_potency() -> void:
	var glass := _rp("#f4f0ff", "#c8c0e0", "#7a70a0")
	var liquid := _rp("#f0b8ff", "#b050e0", "#6a2090")
	_c_disc(Vector2(8, 10.2), 4.5, glass)
	_c_rect(Rect2i(6, 3, 4, 4), glass)
	for cell: Vector2i in _cells.keys():
		if cell.y >= 10:
			_cells[cell] = liquid
	for p: Vector2i in [Vector2i(6, 1), Vector2i(9, 1), Vector2i(6, 2), Vector2i(9, 2)]:
		_dt(p.x, p.y, Color("#9a6a3a"))
	for p: Vector2i in [Vector2i(7, 1), Vector2i(8, 1), Vector2i(7, 2), Vector2i(8, 2)]:
		_dt(p.x, p.y, Color("#c8904a"))
	_dt(6, 12, Color("#fff0ff"))
	_dt(9, 11, Color("#f0c8ff"))
	_dt(5, 8, Color.WHITE)

func _ic_rank() -> void:
	var ribbon := _rp("#ff9a9a", "#d84a4a", "#8a2020")
	var gold := _rp("#fff0b0", "#f0c050", "#a87020")
	_c_poly(PackedVector2Array([Vector2(3.5, 0.8), Vector2(7.2, 0.8), Vector2(7.8, 6), Vector2(5.4, 6)]), ribbon)
	_c_poly(PackedVector2Array([Vector2(12.5, 0.8), Vector2(8.8, 0.8), Vector2(8.2, 6), Vector2(10.6, 6)]), ribbon)
	_c_disc(Vector2(8, 10), 4.9, gold)
	for y in range(8, 13):
		_dt(7, y, Color("#7a4a10"))
		_dt(8, y, Color("#7a4a10"))
	for x in range(6, 10):
		_dt(x, 8, Color("#7a4a10"))
		_dt(x, 12, Color("#7a4a10"))

func _ic_focus_power() -> void:
	var stone := _rp("#e8ecf8", "#9aa0c0", "#5a6080")
	var wood := _rp("#e0b078", "#9a6a3a", "#5a3a1a")
	_c_line([Vector2(8, 7), Vector2(8, 14.6)], 2.2, wood)
	_c_rect(Rect2i(2, 2, 12, 5), stone)
	_dt(4, 4, Color("#5a6080"))
	_dt(11, 4, Color("#5a6080"))

func _ic_focus_swift() -> void:
	var k := _rp("#fffbf0", "#a8e0d0", "#4a9a8a")
	_c_ell(Vector2(8.6, 6.8), Vector2(6.6, 2.9), k, -PI * 0.25)
	_c_line([Vector2(1.4, 14.6), Vector2(5, 11)], 1.2, k)
	_dt_line(Vector2i(4, 11), Vector2i(12, 3), Color("#4a9a8a"))
	_dt(10, 3, Color("#fffbf0"))

func _ic_focus_reach() -> void:
	var brass := _rp("#fff0c0", "#d8a848", "#8a6020")
	var a := Vector2(2.6, 12.4)
	var b := Vector2(12.6, 3.4)
	var d := (b - a).normalized()
	var perp := d.orthogonal()
	_c_poly(PackedVector2Array([a + perp * 1.9, a - perp * 1.9, b - perp * 2.6, b + perp * 2.6]), brass)
	for t: float in [0.35, 0.68]:
		var p := a.lerp(b, t)
		_dt_line(Vector2i((p + perp * 2.0).round()), Vector2i((p - perp * 2.0).round()), Color("#8a6020"))
	_dt(12, 3, Color("#bfe8ff"))
	_dt(13, 4, Color("#e8f8ff"))

func _ic_focus_deep() -> void:
	var leaf := _rp("#d8f8b0", "#6ab04a", "#2e6a2a")
	var earth := _rp("#b08a60", "#7a5234", "#4a3020")
	var root := _rp("#f0dcb8", "#b08858", "#6a4a28")
	_c_ell(Vector2(5.4, 3.4), Vector2(2.6, 1.5), leaf, 0.35)
	_c_ell(Vector2(10.6, 3.4), Vector2(2.6, 1.5), leaf, -0.35)
	_c_line([Vector2(8, 3.8), Vector2(8, 6.4)], 1.2, leaf)
	_c_rect(Rect2i(1, 7, 14, 2), earth)
	_c_line([Vector2(8, 9), Vector2(8, 14.6)], 1.3, root)
	_c_line([Vector2(7.5, 10), Vector2(4, 13.8)], 1.2, root)
	_c_line([Vector2(8.5, 10), Vector2(12, 13.8)], 1.2, root)
	_dt(8, 15, Color("#ffd860"))

func _ic_dew_cost() -> void:
	var k := _rp("#e8fffa", "#7ae0d0", "#2a9a90")
	_c_disc(Vector2(7.4, 10), 4.6, k)
	_c_poly(PackedVector2Array([Vector2(7.4, 1.2), Vector2(3.0, 8.4), Vector2(11.8, 8.4)]), k)
	_dt(5, 8, Color.WHITE)
	_dt(5, 9, Color.WHITE)
	_dt(6, 7, Color("#f0fffc"))
	for p: Vector2i in [Vector2i(13, 2), Vector2i(12, 3), Vector2i(14, 3), Vector2i(13, 4)]:
		_dt(p.x, p.y, Color("#fff4c0"))
	_dt(13, 3, Color.WHITE)

func _ic_dreamlight_cost() -> void:
	var k := _rp("#fff8e0", "#d8b8ff", "#8a60c8")
	_c_poly(PackedVector2Array([Vector2(8, 0.8), Vector2(13.2, 8), Vector2(8, 15.2), Vector2(2.8, 8)]), k)
	_dt_line(Vector2i(6, 4), Vector2i(6, 8), Color("#fffbe8"))
	_dt(8, 8, Color("#ffe890"))

# Nightmare traits and boss abilities -------------------------------------------------------------
# Cold nightmare colours: violet, slate, bone, sickly teal, mire green; small pink-red eyes.

const NM_EYE := Color("#ff4a7a")

func _ic_flying() -> void:
	# Two ragged bat-like wings round a small body.
	var k := _rp("#9a8ac8", "#5a4a8a", "#2e2450")
	_c_poly(PackedVector2Array([Vector2(7.2, 7), Vector2(1, 3), Vector2(1.6, 7), Vector2(0.8, 10), Vector2(3.4, 9), Vector2(4.6, 11.4), Vector2(7.2, 9.6)]), k)
	_c_poly(PackedVector2Array([Vector2(8.8, 7), Vector2(15, 3), Vector2(14.4, 7), Vector2(15.2, 10), Vector2(12.6, 9), Vector2(11.4, 11.4), Vector2(8.8, 9.6)]), k)
	_c_ell(Vector2(8, 8.4), Vector2(1.8, 2.8), k)
	_dt(7, 7, NM_EYE)
	_dt(8, 7, NM_EYE)

func _ic_dread_shell() -> void:
	# A dark hexagonal shell with a crack.
	var k := _rp("#a8b0c8", "#6a7090", "#3a3e58")
	var pts := PackedVector2Array()
	for i in 6:
		pts.append(Vector2(8, 8) + Vector2.from_angle(i * TAU / 6.0 - PI * 0.5) * Vector2(6.4, 6.8))
	_c_poly(pts, k)
	_dt_line(Vector2i(8, 3), Vector2i(8, 13), Color("#3a3e58"))
	_dt_line(Vector2i(4, 6), Vector2i(12, 10), Color("#3a3e58"))
	_dt_line(Vector2i(12, 6), Vector2i(4, 10), Color("#3a3e58"))
	_dt(6, 4, Color("#e0e4f4"))
	_dt(9, 7, Color("#c8d0e8"))

func _ic_through_walls() -> void:
	# A ghost passing through a brick wall.
	var wall := _rp("#b8b0a8", "#7a7068", "#4a4440")
	var ghost := _rp("#f0ecfa", "#b8b0d8", "#7a70a8")
	_c_rect(Rect2i(1, 2, 5, 12), wall)
	_c_ell(Vector2(9.5, 6.5), Vector2(4.4, 4.4), ghost)
	_c_rect(Rect2i(6, 7, 8, 5), ghost)
	for x in [6, 8, 10, 12]:
		_cset(x, 12, ghost)
	for y in [5, 9]:
		_dt_line(Vector2i(1, y), Vector2i(5, y), Color("#4a4440"))
	_dt(3, 3, Color("#4a4440"))
	_dt(3, 7, Color("#4a4440"))
	_dt(3, 11, Color("#4a4440"))
	_dt(8, 6, Color("#241634"))
	_dt(11, 6, Color("#241634"))

func _ic_sprints() -> void:
	# A dashing shadow wisp with speed lines behind it.
	var k := _rp("#8ae0d0", "#3a9a90", "#1e5a58")
	_c_ell(Vector2(11, 8), Vector2(3.4, 3.0), k)
	_c_poly(PackedVector2Array([Vector2(8, 5.4), Vector2(3, 7), Vector2(8, 10.6)]), k)
	_c_line([Vector2(1, 4), Vector2(5.5, 4)], 1.0, k)
	_c_line([Vector2(0.5, 8), Vector2(3, 8)], 1.0, k)
	_c_line([Vector2(1, 12), Vector2(5.5, 12)], 1.0, k)
	_dt(12, 7, NM_EYE)

func _ic_rises() -> void:
	# A bony hand clawing up out of a mound of earth (it burrows under walls).
	var bone := _rp("#e8e4f0", "#b8b0cc", "#7a7098")
	var earth := _rp("#8a7a6a", "#5a4a40", "#302622")
	_c_ell(Vector2(8, 13.6), Vector2(7, 2.4), earth)
	_c_rect(Rect2i(6, 7, 4, 5), bone)
	for x in [5, 7, 9, 11]:
		_c_line([Vector2(x + 0.5, 7.5), Vector2(x + 0.5 + (x - 8) * 0.3, 2.5 + absf(x - 8) * 0.6)], 1.1, bone)
	_dt(8, 9, Color("#7a7098"))

func _ic_trample() -> void:
	# A heavy cloven hoofprint: two toes with a clear split, dew-claw dots behind.
	var k := _rp("#a8a0c0", "#5e5680", "#302a48")
	_c_ell(Vector2(5.2, 6.2), Vector2(2.5, 4.0), k, 0.2)
	_c_ell(Vector2(10.8, 6.2), Vector2(2.5, 4.0), k, -0.2)
	_c_disc(Vector2(3.8, 13.8), 1.2, k)
	_c_disc(Vector2(12.2, 13.8), 1.2, k)
	_dt(5, 3, Color("#d0c8e8"))
	_dt(10, 3, Color("#d0c8e8"))

func _ic_charge() -> void:
	# The Stag's head lowered, antlers first, speed lines behind.
	var bone := _rp("#e0d8c8", "#a09480", "#5a5040")
	var head := _rp("#8a8aa8", "#4a4a6a", "#262640")
	_c_ell(Vector2(11.2, 11.2), Vector2(3.4, 2.4), head, 0.3)
	_c_line([Vector2(10, 9.4), Vector2(7, 5.2), Vector2(4.6, 4.2)], 1.3, bone)
	_c_line([Vector2(7.6, 6), Vector2(7.4, 2)], 1.1, bone)
	_c_line([Vector2(12, 9), Vector2(13.4, 4.4)], 1.1, bone)
	_dt(12, 11, NM_EYE)
	for y in [8, 11, 14]:
		_dt_line(Vector2i(0, y), Vector2i(3 + (y % 2), y), Color("#8a8aa8"))

func _ic_sink() -> void:
	# A whirlpool pulling down: a dark pool with a spiral, bubbles rising.
	var water := _rp("#7a9a9a", "#2e4a4a", "#162626")
	_c_ell(Vector2(8, 9.6), Vector2(7, 4.8), water)
	var swirl := Color("#9ac0c0")
	for s in 22:
		var t := s / 21.0
		var a := t * TAU * 1.6
		var p := Vector2(8, 9.6) + Vector2(cos(a), sin(a) * 0.62) * (5.6 * (1.0 - t) + 0.6)
		_dt(int(round(p.x)), int(round(p.y)), swirl)
	_dt(8, 10, Color("#0a1414"))
	_c_disc(Vector2(4.6, 2.6), 1.2, water)
	_c_disc(Vector2(11.4, 3.4), 0.9, water)

func _ic_bog_water() -> void:
	# A murky bog: a flat green puddle, ripples and two bubbles.
	var k := _rp("#8ab070", "#4a6a48", "#26382a")
	_c_ell(Vector2(8, 10.4), Vector2(7.2, 4.0), k)
	_dt_line(Vector2i(4, 10), Vector2i(7, 10), Color("#a8c890"))
	_dt_line(Vector2i(9, 12), Vector2i(12, 12), Color("#a8c890"))
	_c_disc(Vector2(5, 4), 1.5, k)
	_c_disc(Vector2(10.5, 5.6), 1.1, k)
	_dt(5, 3, Color("#e0f0c8"))

func _ic_eclipse() -> void:
	# A dark moon swallowing the sun: a black disc with a cold bright corona.
	var corona := _rp("#f0ecff", "#b8a8e8", "#6a58a8")
	_c_disc(Vector2(8, 8), 6.6, corona)
	var dark := Color("#120c20")
	for y in ICON:
		for x in ICON:
			if Vector2(x + 0.5, y + 0.5).distance_to(Vector2(9.2, 7.2)) <= 5.4:
				_dt(x, y, dark)
	_dt(12, 5, Color("#2a1e40"))

func _ic_brood() -> void:
	# A clutch of three eggs, each with a watching eye (Lurkers hatch from them).
	var k := _rp("#9a8ac8", "#5a4a8a", "#2e2450")
	for c: Vector2 in [Vector2(5, 10.6), Vector2(11, 10.6), Vector2(8, 5)]:
		_c_ell(c, Vector2(2.9, 3.4), k)
	for c: Vector2i in [Vector2i(5, 11), Vector2i(11, 11), Vector2i(8, 5)]:
		_dt(c.x, c.y, NM_EYE)
		_dt(c.x - 1, c.y - 2, Color("#c8b8f0"))

func _ic_sapling() -> void:
	# A thorny, blighted sapling.
	var k := _rp("#8a8aa0", "#4a4a62", "#26263a")
	_c_line([Vector2(8, 15), Vector2(8, 3), Vector2(6, 1.2)], 1.8, k)
	_c_line([Vector2(8, 9), Vector2(3.4, 5.6)], 1.3, k)
	_c_line([Vector2(8, 7), Vector2(12.6, 3.6)], 1.3, k)
	for p: Vector2i in [Vector2i(9, 12), Vector2i(6, 10), Vector2i(9, 5), Vector2i(4, 5), Vector2i(12, 3)]:
		_dt(p.x, p.y, Color("#c8c8e0"))
	_c_rect(Rect2i(5, 14, 6, 1), k)

func _ic_grief() -> void:
	# A hooded mourner, head bowed, one cold tear.
	var k := _rp("#c8c0e0", "#7a70a8", "#3e3666")
	_c_ell(Vector2(8, 5.6), Vector2(4.2, 4.2), k)
	_c_poly(PackedVector2Array([Vector2(3.6, 6), Vector2(12.4, 6), Vector2(14, 14.6), Vector2(2, 14.6)]), k)
	for x in range(5, 11):
		for y in range(5, 8):
			if Vector2(x + 0.5, y + 0.5).distance_to(Vector2(8, 6.4)) <= 2.6:
				_dt(x, y, Color("#120c20"))
	_dt(9, 7, Color("#8ad8ff"))
	_dt(9, 8, Color("#bfe8ff"))

func _ic_wanders() -> void:
	# A sleepwalker's winding trail (an S), ending in an arrowhead.
	var k := _rp("#c8c0e0", "#7a70a8", "#3e3666")
	var pts: Array = []
	for s in 13:
		var t := s / 12.0
		pts.append(Vector2(2.5 + sin(t * TAU) * 3.0 + t * 6.0, 14 - t * 10.0))
	_c_line(pts, 1.5, k)
	_c_poly(PackedVector2Array([Vector2(7, 3.4), Vector2(13.6, 1.4), Vector2(11, 7)]), k)

func _ic_splits() -> void:
	# One nightmare blob tearing into two.
	var k := _rp("#9a8ac8", "#5a4a8a", "#2e2450")
	_c_ell(Vector2(5.2, 8.4), Vector2(3.8, 4.6), k, 0.35)
	_c_ell(Vector2(11, 8.4), Vector2(3.4, 4.2), k, -0.35)
	_dt_line(Vector2i(8, 3), Vector2i(8, 13), Color("#120c20"))
	_dt(4, 7, NM_EYE)
	_dt(11, 7, NM_EYE)

func _ic_ignores_slows() -> void:
	# A broken shackle: slows don't hold it.
	var k := _rp("#a8b0c8", "#6a7090", "#3a3e58")
	_c_ring(Vector2(6, 9), 4.6, 2.6, k)
	# Snap the ring open at the top right.
	for y in range(3, 8):
		for x in range(7, 12):
			_cells.erase(Vector2i(x, y))
	_c_line([Vector2(10, 7), Vector2(14, 3)], 1.6, k)
	_c_line([Vector2(9, 3), Vector2(10.6, 1.4)], 1.2, k)
	_dt(12, 6, Color("#e0e4f4"))

func _ic_leap() -> void:
	# An arc over a wall.
	var wall := _rp("#b8b0a8", "#7a7068", "#4a4440")
	var arc := _rp("#c8f0e8", "#5ab0a0", "#2a6a60")
	_c_rect(Rect2i(6, 9, 4, 6), wall)
	var pts: Array = []
	for s in 11:
		var t := s / 10.0
		pts.append(Vector2(2 + t * 11, 12 - sin(t * PI) * 9))
	_c_line(pts, 1.4, arc)
	_c_poly(PackedVector2Array([Vector2(11, 9.4), Vector2(15, 10), Vector2(12.6, 13.6)]), arc)

func _ic_mender() -> void:
	# A cold, stitched cross: it mends other nightmares.
	var k := _rp("#9ae0d0", "#3a9a90", "#1e5a58")
	_c_rect(Rect2i(6, 2, 4, 12), k)
	_c_rect(Rect2i(2, 6, 12, 4), k)
	for p: Vector2i in [Vector2i(7, 4), Vector2i(8, 5), Vector2i(4, 7), Vector2i(5, 8), Vector2i(10, 7), Vector2i(11, 8), Vector2i(7, 10), Vector2i(8, 11)]:
		_dt(p.x, p.y, Color("#1e5a58"))

func _ic_waker() -> void:
	# A crossed-out Z: it wakes sleepers.
	var k := _rp("#e0a0c8", "#a84a8a", "#5a1e4a")
	_c_rect(Rect2i(3, 3, 9, 2), k)
	_c_line([Vector2(11, 5.2), Vector2(4, 11)], 2.2, k)
	_c_rect(Rect2i(3, 11, 9, 2), k)
	_dt_line(Vector2i(1, 15), Vector2i(15, 1), Color("#fff4f8"))
	_dt_line(Vector2i(2, 15), Vector2i(15, 2), ICON_OUTLINE)
	_dt_line(Vector2i(1, 14), Vector2i(14, 1), ICON_OUTLINE)

func _ic_revealer() -> void:
	# A will-o'-wisp: a floating cold orb trailing a wispy tail, rays round it.
	var k := _rp("#e8f8ff", "#8ad0f0", "#3a78a8")
	_c_line([Vector2(9.4, 7), Vector2(6, 10), Vector2(6.4, 12.6), Vector2(3, 14.4)], 1.4, k)
	_c_disc(Vector2(10, 5.6), 3.6, k)
	for p: Vector2i in [Vector2i(9, 5), Vector2i(10, 5), Vector2i(9, 6)]:
		_dt(p.x, p.y, Color.WHITE)
	for d: Vector2i in [Vector2i(10, 0), Vector2i(15, 5), Vector2i(14, 10), Vector2i(4, 3), Vector2i(15, 1)]:
		_dt(d.x, d.y, Color("#bfe8ff"))

func _ic_ash() -> void:
	# A grey ash flame with dull embers in it.
	var k := _rp("#c0bcc8", "#7a7688", "#3e3a4a")
	_c_disc(Vector2(8, 11), 3.8, k)
	_c_poly(PackedVector2Array([Vector2(4.4, 10), Vector2(6, 3), Vector2(8, 6.6), Vector2(10, 1.6), Vector2(11.6, 10)]), k)
	for p: Vector2i in [Vector2i(7, 11), Vector2i(9, 9), Vector2i(8, 13), Vector2i(6, 8)]:
		_dt(p.x, p.y, Color("#d8503a"))
	_dt(8, 12, Color("#ff8a5a"))

func _ic_thief() -> void:
	# A tied sack with a stolen dew drop on it.
	var sack := _rp("#c8b8a0", "#8a7458", "#4a3a2a")
	_c_disc(Vector2(8, 10), 5.0, sack)
	_c_rect(Rect2i(6, 3, 4, 3), sack)
	_dt_line(Vector2i(5, 5), Vector2i(10, 5), Color("#4a3a2a"))
	for p: Vector2i in [Vector2i(8, 8), Vector2i(7, 10), Vector2i(8, 10), Vector2i(9, 10), Vector2i(7, 11), Vector2i(8, 11), Vector2i(9, 11), Vector2i(8, 12)]:
		_dt(p.x, p.y, Color("#7ae0d0"))
	_dt(7, 10, Color.WHITE)

func _ic_followers() -> void:
	# A lantern leading a little train of followers.
	var lamp := _rp("#e0e8ff", "#8a90c8", "#3a3e70")
	var small := _rp("#9a8ac8", "#5a4a8a", "#2e2450")
	_c_rect(Rect2i(10, 4, 4, 6), lamp)
	_c_rect(Rect2i(11, 2, 2, 2), lamp)
	_dt(11, 6, Color("#bfe8ff"))
	_dt(12, 7, Color("#bfe8ff"))
	_c_disc(Vector2(7, 12), 1.8, small)
	_c_disc(Vector2(2.8, 12.6), 1.5, small)
	_dt(7, 12, NM_EYE)
	_dt(3, 12, NM_EYE)

func _ic_swarm() -> void:
	# A cloud of tiny specks with eyes.
	var k := _rp("#9a8ac8", "#5a4a8a", "#2e2450")
	for c: Vector2 in [Vector2(4, 4), Vector2(9, 3), Vector2(13, 6), Vector2(3, 9), Vector2(8, 8), Vector2(12, 11), Vector2(5, 13), Vector2(10, 14)]:
		_c_disc(c, 1.2, k)
	for c: Vector2i in [Vector2i(8, 8), Vector2i(4, 4), Vector2i(12, 11)]:
		_dt(c.x, c.y, NM_EYE)

func _ic_bulky() -> void:
	# A huge hulking body, a tiny head.
	var k := _rp("#a8a0c0", "#5e5680", "#302a48")
	_c_ell(Vector2(8, 10), Vector2(6.8, 5.2), k)
	_c_disc(Vector2(8, 3.6), 2.2, k)
	_dt(7, 3, NM_EYE)
	_dt(9, 3, NM_EYE)
	_dt_line(Vector2i(4, 12), Vector2i(12, 12), Color("#302a48"))

# Warden damage types ------------------------------------------------------------------------------
# A warm dark badge with a gold rim, the type's symbol inside (warm Warden colours).

func _type_badge() -> void:
	var fill := _rp("#6a4a34", "#4a3226", "#33221a")
	var rim := _rp("#fff0b0", "#e8b048", "#a8701e")
	_c_disc(Vector2(8, 8), 7.4, fill)
	_c_ring(Vector2(8, 8), 7.4, 6.2, rim)

func _ic_spore() -> void:
	_type_badge()
	var k := _rp("#ffd8f8", "#e888d8", "#a8489a")
	_c_disc(Vector2(9.4, 6), 2.0, k)
	_c_disc(Vector2(5.6, 8.4), 1.8, k)
	_c_disc(Vector2(9.2, 10.6), 1.6, k)
	_dt(9, 5, Color.WHITE)
	_dt(5, 8, Color.WHITE)

func _ic_stone() -> void:
	_type_badge()
	var k := _rp("#e8ecf8", "#a0a6c8", "#626890")
	_c_poly(PackedVector2Array([Vector2(3.6, 9.6), Vector2(5, 5), Vector2(9, 3.8), Vector2(12.2, 6.4), Vector2(11.6, 11), Vector2(7, 12.2)]), k)
	_dt_line(Vector2i(8, 5), Vector2i(7, 8), Color("#626890"))
	_dt_line(Vector2i(7, 8), Vector2i(9, 10), Color("#626890"))

func _ic_water() -> void:
	# A single round-bottomed drop with a wave line through it (the status Soaked is a bare drop
	# with a second small drop and no badge).
	_type_badge()
	var k := _rp("#d8f0ff", "#6ab0f0", "#3a70c0")
	_c_disc(Vector2(8, 9.4), 3.2, k)
	_c_poly(PackedVector2Array([Vector2(8, 3.2), Vector2(5, 8.6), Vector2(11, 8.6)]), k)
	_dt(6, 8, Color.WHITE)
	_dt_line(Vector2i(6, 10), Vector2i(7, 10), Color("#f0faff"))
	_dt_line(Vector2i(8, 11), Vector2i(10, 11), Color("#f0faff"))

func _ic_light() -> void:
	_type_badge()
	var k := _rp("#fffbe0", "#ffe070", "#d0a020")
	_c_poly(PackedVector2Array([Vector2(8, 2.6), Vector2(9.2, 6.8), Vector2(13.4, 8), Vector2(9.2, 9.2),
		Vector2(8, 13.4), Vector2(6.8, 9.2), Vector2(2.6, 8), Vector2(6.8, 6.8)]), k)
	_dt(8, 8, Color.WHITE)

func _ic_root() -> void:
	_type_badge()
	var k := _rp("#e0c090", "#a07448", "#5e4028")
	_c_line([Vector2(8, 12.6), Vector2(8, 8), Vector2(9.6, 5.4), Vector2(11.4, 5.6), Vector2(11.2, 7.4), Vector2(9.8, 7.6)], 1.5, k)
	_c_line([Vector2(8, 10), Vector2(5, 8.4), Vector2(4.4, 6.2)], 1.2, k)
	_dt(4, 5, Color("#8ad060"))
	_dt(5, 5, Color("#8ad060"))

func _ic_song() -> void:
	_type_badge()
	var k := _rp("#f4e8ff", "#c8a8f0", "#8a6ac8")
	_c_ell(Vector2(6.4, 11), Vector2(2.2, 1.7), k, -0.3)
	_c_line([Vector2(8.2, 10.6), Vector2(8.2, 3.6)], 1.2, k)
	_c_line([Vector2(8.2, 3.6), Vector2(11.4, 5.2), Vector2(11.4, 6.6)], 1.3, k)

func _ic_wing() -> void:
	# Talon: one curved, hooked claw, thick at its root and sharp at the tip.
	_type_badge()
	var claw := _rp("#ffffff", "#f4e4c8", "#d8b88c")
	var pts: Array = []
	for s in 10:
		var t := s / 9.0
		var a := lerpf(-PI * 0.9, PI * 0.25, t)
		pts.append(Vector2(8.2, 9.2) + Vector2(cos(a), sin(a)) * Vector2(4.6, 4.2))
	_c_line(pts.slice(0, 5), 1.9, claw)
	_c_line(pts.slice(4, 8), 1.4, claw)
	_c_line(pts.slice(7), 0.9, claw)
	_dt(5, 6, Color.WHITE)

func _ic_wind() -> void:
	_type_badge()
	var k := _rp("#f4fff8", "#a8e8d0", "#58a890")
	var pts: Array = []
	for s in 16:
		var t := s / 15.0
		var a := t * TAU * 1.1
		pts.append(Vector2(8, 8) + Vector2(cos(a), sin(a)) * (0.6 + t * 4.4))
	_c_line(pts, 1.2, k)
	_c_line([Vector2(3.4, 11.6), Vector2(8, 12.6)], 1.2, k)

func _ic_plain() -> void:
	# A small plain dot: never resisted.
	_type_badge()
	var k := _rp("#fffbf0", "#e8dcc4", "#b8a888")
	_c_disc(Vector2(8, 8), 2.2, k)

# Run resources ----------------------------------------------------------------------------------

func _ic_leaves() -> void:
	# One warm green leaf with a gold midrib and a short stem (the Heartwood's leaves).
	var k := _rp("#d8f8a0", "#6ab04a", "#2e6a2a")
	var stem := _rp("#e0b078", "#9a6a3a", "#5a3a1a")
	_c_ell(Vector2(8.8, 7.0), Vector2(6.4, 3.8), k, -PI * 0.25)
	_c_line([Vector2(1.6, 14.4), Vector2(4.4, 11.6)], 1.3, stem)
	_dt_line(Vector2i(4, 11), Vector2i(12, 3), Color("#e8d070"))
	_dt(7, 5, Color("#f0ffd0"))
	_dt(6, 6, Color("#f0ffd0"))

func _ic_path_length() -> void:
	# A footpath: eight stepping stones winding in an S from the bottom up, in the path tiles' sandy
	# colours. Each stone is its own shape, so the generator outlines every one and it reads on fog.
	var k := _rp(Palette.color("moonpath").to_html(false), Palette.color("path").to_html(false), Palette.color("loam").to_html(false))
	for p: Vector2i in [Vector2i(2, 13), Vector2i(6, 13), Vector2i(10, 11), Vector2i(10, 7), Vector2i(6, 7),
			Vector2i(2, 4), Vector2i(5, 1), Vector2i(10, 1)]:
		_c_rect(Rect2i(p, Vector2i(3, 2)), k)

func _ic_seeds() -> void:
	# An acorn-brown seed with a small green sprout (Seeds, the meta currency).
	var k := _rp("#f0c890", "#b07a44", "#6a4222")
	var leaf := _rp("#d8f8a0", "#6ab04a", "#2e6a2a")
	_c_ell(Vector2(8, 10.4), Vector2(4.2, 4.8), k)
	_c_line([Vector2(8, 5.6), Vector2(8, 3.4)], 1.2, leaf)
	_c_ell(Vector2(10.6, 2.8), Vector2(2.2, 1.3), leaf, -0.4)
	_dt(6, 9, Color("#fff0d0"))
	_dt(6, 10, Color("#fff0d0"))

# Omens ------------------------------------------------------------------------------------------

func _moon(c: Vector2, r: float) -> void:
	var k := _rp(Palette.color("moonlight").to_html(false), Palette.color("mist").to_html(false), Palette.color("stone").to_html(false))
	_c_disc(c, r, k)

func _star(x: int, y: int) -> void:
	# A four-point glint: a bright centre with dimmer arms.
	_dt(x, y, Palette.color("heartlight"))
	for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		_dt(x + d.x, y + d.y, Palette.color("glow"))

# The moth, drawn by hand: "m" = silhouette (Void), "g" = Gold rim light, "l" = Glow.
const MOTH := [
	"................",
	"................",
	"................",
	"................",
	".....m....m.....",
	"......m..m......",
	"..g....mm....g..",
	"..lm...mm...ml..",
	"..mmm.mmmm.mmm..",
	"...mmmmmmmmmm...",
	"....mmmmmmmm....",
	".....mmmmmm.....",
	"....mmm..mmm....",
	".....m.mm.m.....",
	"................",
	"................"]

func _ic_omen() -> void:
	# A dark moth crossing a pale full moon: a flat silhouette so it reads at 16 px, with Gold rim
	# light only on the wingtips. The moon shows all round it.
	_moon(Vector2(8, 8), 6.8)
	_dt(4, 11, Palette.color("mist"))
	_dt(11, 3, Palette.color("mist"))
	var cols := {"m": Palette.color("void"), "g": Palette.color("gold"), "l": Palette.color("glow")}
	for y in MOTH.size():
		for x in MOTH[y].length():
			var ch: String = MOTH[y][x]
			if cols.has(ch):
				_dt(x, y, cols[ch])

func _ic_clear_skies() -> void:
	# The same moon, alone and calm, with a few small stars.
	_moon(Vector2(6.6, 9.4), 5.4)
	_dt(5, 8, Palette.color("mist"))
	_dt(8, 11, Palette.color("mist"))
	_dt(4, 11, Palette.color("mist"))
	_star(13, 3)
	_star(14, 8)
	_dt(9, 1, Palette.color("glow"))
	_dt(2, 2, Palette.color("glow"))
