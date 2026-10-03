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
	_make_omen_cards()
	_make_hud_icons()
	_make_dream_glyphs()
	_make_buff_pips()
	_make_grow_hints()
	_make_emblems()
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
# Statuses differ by SHAPE, not only colour. Reaction icons exist but only show once discovered (see REACTION_ICONS).

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
# Reactions and Crowned Reactions (tower_design.md): shown only once discovered (discovery card, combo
# tips, unlocked Codex entries), never on locked "???" entries (screens_ui.md). Each pairs its two
# statuses' colours; Crowned ones wear a small gold crown.
const REACTION_ICONS := ["thunderclap", "ignite", "mushrooming", "drown", "shatter", "pinned", "smother", "lightning_rod"]
const CROWNED_ICONS := ["tempest", "still_pool", "fever_dream", "starfall", "avalanche", "prismstorm", "nightbloom", "fairy_circle"]
# Legendary Dream marks for discovery cards and the Codex (Dawnbreak fires at a Chain 10).
const LEGENDARY_ICONS := ["dawnbreak"]
# Statuses added after the sheet was laid out: appended at the end so no column moves; listed under
# "statuses" in icons.json with the rest.
const LATE_STATUS_ICONS := ["silenced"]
# Ids that share another icon's column.
const ICON_ALIASES := {"always_damp": "damp", "burrows": "rises", "dew": "dew_cost", "dreamlight": "dreamlight_cost"}

var _cells := {}  # Vector2i -> ramp index
var _ramps: Array = []  # [light, mid, dark]
var _details: Array = []  # [Vector2i, Color], painted last
var _n := ICON  # size of the icon being drawn (16; the Omen card emblems are 32)

func _make_icons() -> void:
	var ids: Array = STATUS_ICONS + STAT_ICONS + NIGHTMARE_ICONS + DAMAGE_TYPE_ICONS + RESOURCE_ICONS + OMEN_ICONS \
		+ REACTION_ICONS + CROWNED_ICONS + LEGENDARY_ICONS + LATE_STATUS_ICONS
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
	var data := {frame_size = ICON, icons = index, statuses = STATUS_ICONS + LATE_STATUS_ICONS, stats = STAT_ICONS,
		nightmare = NIGHTMARE_ICONS + ["hidden", "always_damp", "burrows"], damage_type = DAMAGE_TYPE_ICONS,
		resources = RESOURCE_ICONS + ["dew", "dreamlight"],
		omen = OMEN_ICONS,
		reactions = REACTION_ICONS, crowned = CROWNED_ICONS, legendary = LEGENDARY_ICONS,
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

func _icon(id: String, size := ICON) -> Image:
	_n = size
	_cells = {}
	_ramps = []
	_details = []
	call("_ic_" + id)
	var img := Image.create(_n, _n, false, Image.FORMAT_RGBA8)
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
	for y in _n:
		for x in _n:
			var p := Vector2i(x, y)
			if _cells.has(p):
				continue
			for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if _cells.has(p + d):
					img.set_pixelv(p, ICON_OUTLINE)
					break
	for d: Array in _details:
		var p: Vector2i = d[0]
		if p.x >= 0 and p.y >= 0 and p.x < _n and p.y < _n:
			img.set_pixelv(p, d[1])
	return img

func _rp(light: String, mid: String, dark: String) -> int:
	_ramps.append([Color(light), Color(mid), Color(dark)])
	return _ramps.size() - 1

func _cset(x: int, y: int, k: int) -> void:
	if x >= 0 and y >= 0 and x < _n and y < _n:
		_cells[Vector2i(x, y)] = k

func _c_disc(c: Vector2, r: float, k: int) -> void:
	for y in _n:
		for x in _n:
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r:
				_cset(x, y, k)

func _c_ring(c: Vector2, ro: float, ri: float, k: int) -> void:
	for y in _n:
		for x in _n:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d <= ro and d > ri:
				_cset(x, y, k)

func _c_ell(c: Vector2, r: Vector2, k: int, angle: float = 0.0) -> void:
	for y in _n:
		for x in _n:
			if ((Vector2(x + 0.5, y + 0.5) - c).rotated(-angle) / r).length() <= 1.0:
				_cset(x, y, k)

func _c_poly(pts: PackedVector2Array, k: int) -> void:
	for y in _n:
		for x in _n:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				_cset(x, y, k)

func _c_line(pts: Array, w: float, k: int) -> void:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		for y in _n:
			for x in _n:
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

func _moth_ramps() -> Array:
	# [wings, wing band, body] by palette name: dark night wings with a pale band, never a face.
	return [_rpn("slate", "shade", "dread"), _rpn("mist", "stone", "slate"), _rpn("dusk", "night", "void")]

func _ic_omen() -> void:
	# Revised 2026-10-01 (run_design.md): the moth's spread wings come first, in front of a moon that
	# only peeks out at the top right; no dark-blobs-on-a-white-disc symmetry.
	_moon(Vector2(12, 4.4), 4.0)
	var r := _moth_ramps()
	_c_poly(PackedVector2Array([Vector2(6.6, 7.4), Vector2(0.4, 3.6), Vector2(0.4, 8.6), Vector2(6.6, 10.6)]), r[0])
	_c_poly(PackedVector2Array([Vector2(8.4, 7.4), Vector2(14.6, 3.6), Vector2(14.6, 8.6), Vector2(8.4, 10.6)]), r[0])
	_c_ell(Vector2(4.4, 12.2), Vector2(2.6, 2.0), r[0])
	_c_ell(Vector2(10.6, 12.2), Vector2(2.6, 2.0), r[0])
	_c_line([Vector2(7.5, 7), Vector2(7.5, 14.6)], 1.2, r[2])
	_dt_line(Vector2i(7, 6), Vector2i(5, 3), Palette.color("night"))
	_dt_line(Vector2i(8, 6), Vector2i(10, 3), Palette.color("night"))
	_dt(1, 4, Palette.color("gold"))
	_dt(14, 4, Palette.color("gold"))
	_dt(2, 5, Palette.color("glow"))
	_dt(13, 5, Palette.color("glow"))
	_dt(4, 12, Palette.color("gold"))
	_dt(10, 12, Palette.color("gold"))

func _c_erase_disc(c: Vector2, r: float) -> void:
	for y in _n:
		for x in _n:
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r:
				_cells.erase(Vector2i(x, y))

func _big_star(c: Vector2i, arm: int) -> void:
	var gold := _rpn("heartlight", "glow", "gold")
	_c_rect(Rect2i(c.x - arm, c.y, arm * 2 + 1, 1), gold)
	_c_rect(Rect2i(c.x, c.y - arm, 1, arm * 2 + 1), gold)
	_c_rect(Rect2i(c.x - 1, c.y - 1, 3, 3), gold)

# --- Omen card emblems (32x32, shown x2 on the Face an Omen / Clear Skies cards) --------------------

const OMEN_CARD_ICONS := ["omen_card", "clear_skies_card"]

func _make_omen_cards() -> void:
	var sheet := Image.create(32 * OMEN_CARD_ICONS.size(), 32, false, Image.FORMAT_RGBA8)
	var index := {}
	for i in OMEN_CARD_ICONS.size():
		var icon := _icon(OMEN_CARD_ICONS[i], 32)
		Palette.snap_image(icon)
		sheet.blit_rect(icon, Rect2i(0, 0, 32, 32), Vector2i(i * 32, 0))
		index[OMEN_CARD_ICONS[i]] = i
	sheet.save_png(OUT + "omen_cards.png")
	var file := FileAccess.open(OUT + "omen_cards.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({frame_size = 32, icons = index,
		note = "Omen card emblems (run_design.md \"How an Omen looks\"). Show x2, nearest. Tags and lists use the 16 px omen / clear_skies in icons.png."}, "\t") + "\n")
	_n = ICON

func _ic_omen_card() -> void:
	# A moth with wide, patterned wings in front of a pale moon that shows only behind its right wing.
	_moon(Vector2(25, 6.6), 7.0)
	_dt(23, 3, Palette.color("mist"))
	_dt(28, 6, Palette.color("mist"))
	_dt(25, 9, Palette.color("mist"))
	var r := _moth_ramps()
	# Forewings, swept up and out, each crossed by a pale band.
	_c_poly(PackedVector2Array([Vector2(13.6, 13), Vector2(1, 7), Vector2(0.4, 13.6), Vector2(4.4, 19), Vector2(13.6, 18.6)]), r[0])
	_c_poly(PackedVector2Array([Vector2(16.4, 13), Vector2(29, 7), Vector2(29.6, 13.6), Vector2(25.6, 19), Vector2(16.4, 18.6)]), r[0])
	_c_line([Vector2(3, 10.6), Vector2(8, 13.6), Vector2(12.6, 14.4)], 1.4, r[1])
	_c_line([Vector2(27, 10.6), Vector2(22, 13.6), Vector2(17.4, 14.4)], 1.4, r[1])
	# Hindwings, rounder, with gold-ringed eye-spots low down.
	_c_ell(Vector2(9, 22.4), Vector2(5.4, 4.4), r[0], 0.3)
	_c_ell(Vector2(21, 22.4), Vector2(5.4, 4.4), r[0], -0.3)
	var gold := _rpn("heartlight", "glow", "gold")
	_c_ring(Vector2(8.6, 23), 2.3, 1.1, gold)
	_c_ring(Vector2(21.4, 23), 2.3, 1.1, gold)
	_dt(8, 22, Palette.color("void"))
	_dt(21, 22, Palette.color("void"))
	# A thin body and feathered antennae.
	_c_line([Vector2(15, 11), Vector2(15, 27.6)], 1.4, r[2])
	_c_disc(Vector2(15, 11.2), 1.4, r[2])
	_dt_line(Vector2i(14, 9), Vector2i(10, 3), Palette.color("night"))
	_dt_line(Vector2i(15, 9), Vector2i(19, 3), Palette.color("night"))
	for p: Vector2i in [Vector2i(11, 5), Vector2i(12, 6), Vector2i(17, 6), Vector2i(18, 5)]:
		_dt(p.x - 1, p.y, Palette.color("night"))
	# Rim light along the forewing tips.
	for p: Vector2i in [Vector2i(1, 7), Vector2i(2, 7), Vector2i(3, 8), Vector2i(28, 7), Vector2i(27, 7), Vector2i(26, 8)]:
		_dt(p.x, p.y, Palette.color("gold"))
	_dt(1, 8, Palette.color("glow"))
	_dt(28, 8, Palette.color("glow"))

func _ic_clear_skies_card() -> void:
	# A calm crescent moon and three small stars; no moth.
	_moon(Vector2(13, 16), 11)
	_c_erase_disc(Vector2(19.4, 11.6), 9.6)
	_dt(6, 18, Palette.color("mist"))
	_dt(9, 24, Palette.color("mist"))
	_big_star(Vector2i(25, 5), 2)
	_big_star(Vector2i(27, 19), 2)
	_dt(20, 26, Palette.color("glow"))
	_dt(19, 26, Palette.color("gold"))
	_dt(21, 26, Palette.color("gold"))
	_dt(20, 25, Palette.color("gold"))
	_dt(20, 27, Palette.color("gold"))

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

# Reactions --------------------------------------------------------------------------------------
# Status colours by name: water (Soaked), sleep (Drowsy), spore (Poisoned), gold (Exposed / Charged),
# vine (Rooted), ice (Frozen), stone (rocks, clouds).

func _rpn(light: String, mid: String, dark: String) -> int:
	return _rp(Palette.color(light).to_html(false), Palette.color(mid).to_html(false), Palette.color(dark).to_html(false))

func _bolt(pts: PackedVector2Array) -> void:
	_c_poly(pts, _rpn("heartlight", "glow", "gold"))

func _drop(c: Vector2, r: float, k: int) -> void:
	_c_disc(c, r, k)
	_c_poly(PackedVector2Array([c + Vector2(0, -r * 2.1), c + Vector2(-r * 0.95, -r * 0.3), c + Vector2(r * 0.95, -r * 0.3)]), k)

func _zz(x: int, y: int, k: int) -> void:
	# A small "z".
	_c_rect(Rect2i(x, y, 4, 1), k)
	_c_line([Vector2(x + 3.4, y + 1.0), Vector2(x + 0.6, y + 2.8)], 1.2, k)
	_c_rect(Rect2i(x, y + 3, 4, 1), k)

func _crown() -> void:
	# The Crowned mark: a small three-point gold crown along the top.
	_c_poly(PackedVector2Array([Vector2(3.6, 3.6), Vector2(3.6, 0.4), Vector2(6, 2.2), Vector2(8, 0), Vector2(10, 2.2),
		Vector2(12.4, 0.4), Vector2(12.4, 3.6)]), _rpn("heartlight", "glow", "gold"))
	_dt(8, 2, Palette.color("dewlight"))

func _ic_thunderclap() -> void:
	# Soaked + Charged: a gold bolt splitting a water drop.
	_drop(Vector2(6, 10.6), 4.0, _rpn("dewlight", "dew", "pool"))
	_bolt(PackedVector2Array([Vector2(12.6, 0.6), Vector2(7.6, 7.2), Vector2(10.2, 7.2), Vector2(6.4, 15.2),
		Vector2(13.6, 5.8), Vector2(11, 5.8), Vector2(14.6, 0.6)]))
	_dt(2, 6, Palette.color("glow"))
	_dt(14, 12, Palette.color("glow"))

func _ic_ignite() -> void:
	# Poisoned + Charged: spores going off in a gold burst.
	var spore := _rpn("newleaf", "sprig", "leaf")
	_c_disc(Vector2(4.6, 11.4), 2.8, spore)
	_c_disc(Vector2(9.4, 12.8), 2.0, spore)
	_c_disc(Vector2(3.6, 6.0), 1.8, spore)
	var gold := _rpn("heartlight", "glow", "gold")
	var c := Vector2(10.6, 5.4)
	for i in 8:
		var d := Vector2.from_angle(i * TAU / 8.0)
		_c_line([c + d * 1.5, c + d * (4.4 if i % 2 == 0 else 3.4)], 1.2, gold)
	_c_disc(c, 1.6, gold)
	_dt(4, 10, Palette.color("heartlight"))

func _ic_mushrooming() -> void:
	# Poisoned + Soaked: a spore mushroom swelling, a drop at its foot.
	var cap := _rpn("newleaf", "sprig", "leaf")
	_c_poly(PackedVector2Array([Vector2(1.4, 8.4), Vector2(3, 4), Vector2(8, 1.6), Vector2(13, 4), Vector2(14.6, 8.4)]), cap)
	_c_rect(Rect2i(6, 8, 4, 6), _rpn("moonpath", "deadwood", "loam"))
	_drop(Vector2(12.6, 13.2), 1.8, _rpn("dewlight", "dew", "pool"))
	for p: Vector2i in [Vector2i(5, 4), Vector2i(10, 5), Vector2i(8, 3)]:
		_dt(p.x, p.y, Palette.color("heartlight"))

func _ic_drown() -> void:
	# Soaked + Drowsy: a heavy drop falling asleep.
	_drop(Vector2(6.4, 10.2), 4.4, _rpn("dewlight", "dew", "pool"))
	_zz(10, 1, _rpn("moonlight", "wraithlight", "bruise"))
	_dt(4, 9, Palette.color("moonlight"))
	_dt_line(Vector2i(4, 11), Vector2i(5, 12), Palette.color("pool"))
	_dt_line(Vector2i(8, 11), Vector2i(7, 12), Palette.color("pool"))

func _ic_shatter() -> void:
	# Rooted + Soaked, then a hard hit: ice bursting into shards.
	var ice := _rpn("moonlight", "dewlight", "dew")
	_c_poly(PackedVector2Array([Vector2(7.6, 6.6), Vector2(2, 1.4), Vector2(4.4, 8.2)]), ice)
	_c_poly(PackedVector2Array([Vector2(8.8, 6.4), Vector2(14.6, 2.6), Vector2(11.6, 8.6)]), ice)
	_c_poly(PackedVector2Array([Vector2(7.2, 9.4), Vector2(3.2, 14.8), Vector2(9.4, 11.6)]), ice)
	_c_poly(PackedVector2Array([Vector2(10, 10), Vector2(14.6, 13.6), Vector2(11.4, 9)]), ice)
	_dt(8, 8, Palette.color("heartlight"))
	_dt_line(Vector2i(1, 12), Vector2i(3, 10), Palette.color("leaf"))

func _ic_smother() -> void:
	# Rooted + Poisoned: a spore cluster bound tight by dark vines.
	var spore := _rpn("newleaf", "sprig", "leaf")
	_c_disc(Vector2(6.4, 6.4), 3.6, spore)
	_c_disc(Vector2(10.4, 9.6), 3.4, spore)
	_c_disc(Vector2(5.6, 11.6), 2.6, spore)
	var vine := _rpn("leaf", "moss", "deepmoss")
	_c_line([Vector2(0.8, 4.6), Vector2(7, 8.4), Vector2(15.2, 7.2)], 1.6, vine)
	_c_line([Vector2(1.2, 13.6), Vector2(8.6, 11.2), Vector2(14.6, 14.4)], 1.6, vine)
	_dt(5, 5, Palette.color("heartlight"))
	_dt(9, 9, Palette.color("heartlight"))

# Crowned Reactions: crown on rows 0-3, the motif below.

func _ic_tempest() -> void:
	# Thunderclap + Poisoned: a storm cloud raining bolts and spores.
	_crown()
	var cloud := _rpn("mist", "stone", "slate")
	_c_disc(Vector2(5, 8), 2.6, cloud)
	_c_disc(Vector2(9, 7), 3.0, cloud)
	_c_disc(Vector2(12, 8.6), 2.2, cloud)
	_c_rect(Rect2i(3, 8, 11, 2), cloud)
	_bolt(PackedVector2Array([Vector2(8.6, 10), Vector2(6.4, 13.4), Vector2(8, 13.4), Vector2(6.8, 15.8),
		Vector2(10.6, 12), Vector2(9, 12), Vector2(10.4, 10)]))
	var spore := _rpn("newleaf", "sprig", "leaf")
	_c_disc(Vector2(3.4, 13.4), 1.3, spore)
	_c_disc(Vector2(13.2, 13.6), 1.3, spore)

func _ic_still_pool() -> void:
	# Drown + Rooted: a calm, sleeping pool ringed by vines.
	_crown()
	_c_ell(Vector2(8, 11), Vector2(6.6, 3.4), _rpn("leaf", "moss", "deepmoss"))
	_c_ell(Vector2(8, 11), Vector2(5.0, 2.2), _rpn("dewlight", "dew", "pool"))
	_dt_line(Vector2i(5, 10), Vector2i(8, 10), Palette.color("moonlight"))
	_zz(11, 5, _rpn("moonlight", "wraithlight", "bruise"))

func _ic_fever_dream() -> void:
	# Smother ending in sleep: a drowsy spiral shedding spores.
	_crown()
	var sleep := _rpn("moonlight", "wraithlight", "bruise")
	_c_line([Vector2(8, 10), Vector2(9.6, 9.2), Vector2(10.2, 11), Vector2(8.6, 12.8), Vector2(5.6, 12.2),
		Vector2(4.6, 9.2), Vector2(6.4, 6.4), Vector2(10, 5.8), Vector2(12.8, 8.2), Vector2(13, 12)], 1.5, sleep)
	var spore := _rpn("newleaf", "sprig", "leaf")
	_c_disc(Vector2(2.4, 14), 1.2, spore)
	_c_disc(Vector2(13.6, 14.6), 1.0, spore)
	_c_disc(Vector2(2.2, 6.4), 1.0, spore)

func _ic_starfall() -> void:
	# Pinned + Charged: a falling star striking a gold target.
	_crown()
	var gold := _rpn("heartlight", "glow", "gold")
	_c_ring(Vector2(5.4, 11.4), 4.0, 2.2, gold)
	_c_disc(Vector2(5.4, 11.4), 1.0, gold)
	_c_poly(PackedVector2Array([Vector2(12, 4.4), Vector2(12.8, 6.4), Vector2(15, 6.6), Vector2(13.2, 7.8), Vector2(13.8, 10),
		Vector2(12, 8.6), Vector2(10.2, 10), Vector2(10.8, 7.8), Vector2(9, 6.6), Vector2(11.2, 6.4)]), gold)
	_dt_line(Vector2i(9, 10), Vector2i(7, 12), Palette.color("glow"))

func _ic_avalanche() -> void:
	# A Cairn lob sets off Shatter: tumbling boulders and ice shards.
	_crown()
	var rock := _rpn("mist", "stone", "slate")
	_c_disc(Vector2(5, 11.4), 3.2, rock)
	_c_disc(Vector2(10.6, 13.2), 2.2, rock)
	var ice := _rpn("moonlight", "dewlight", "dew")
	_c_poly(PackedVector2Array([Vector2(9.6, 9.6), Vector2(14.6, 5.2), Vector2(12.4, 10.4)]), ice)
	_c_poly(PackedVector2Array([Vector2(7.6, 7.2), Vector2(9.2, 4.6), Vector2(9.6, 8.2)]), ice)
	_dt(4, 10, Palette.color("moonlight"))

func _ic_prismstorm() -> void:
	# Shatter + Charged: an ice prism carrying lightning.
	_crown()
	_c_poly(PackedVector2Array([Vector2(8, 4.4), Vector2(12.6, 10), Vector2(8, 15.6), Vector2(3.4, 10)]), _rpn("moonlight", "dewlight", "dew"))
	_dt_line(Vector2i(8, 6), Vector2i(8, 14), Palette.color("moonlight"))
	_bolt(PackedVector2Array([Vector2(15.4, 5.6), Vector2(10.4, 10.2), Vector2(12, 10.2), Vector2(9.6, 14.4),
		Vector2(15.6, 9), Vector2(13.6, 9), Vector2(15.8, 5.6)]))
	_dt(1, 7, Palette.color("glow"))

func _ic_nightbloom() -> void:
	# Mushrooming + Drowsy: a mushroom glowing in sleep, where nothing wakes.
	_crown()
	_c_poly(PackedVector2Array([Vector2(1.6, 10.6), Vector2(3.4, 6.6), Vector2(8, 5), Vector2(12.6, 6.6), Vector2(14.4, 10.6)]),
		_rpn("moonlight", "wraithlight", "bruise"))
	_c_rect(Rect2i(6, 10, 4, 5), _rpn("moonpath", "deadwood", "loam"))
	for p: Vector2i in [Vector2i(5, 7), Vector2i(10, 8), Vector2i(8, 6)]:
		_dt(p.x, p.y, Palette.color("sprig"))
	_dt(2, 13, Palette.color("newleaf"))
	_dt(13, 14, Palette.color("newleaf"))


func _ic_pinned() -> void:
	# Exposed + Rooted: a thorn pin driven into a gold target, head out at the top right.
	var gold := _rpn("heartlight", "glow", "gold")
	_c_ring(Vector2(6.6, 9.4), 5.6, 3.6, gold)
	_c_disc(Vector2(6.6, 9.4), 1.4, gold)
	var vine := _rpn("sprig", "leaf", "moss")
	_c_line([Vector2(7.4, 8.6), Vector2(13, 3)], 1.5, vine)
	_c_disc(Vector2(13.4, 2.6), 2.0, vine)

func _ic_fairy_circle() -> void:
	# Mushrooming + Rooted: a ring of little mushrooms on a dark vine.
	_crown()
	_c_ring(Vector2(8, 11), 5.6, 4.4, _rpn("moss", "deepmoss", "deepmoss"))
	var cap := _rpn("newleaf", "sprig", "leaf")
	var stem := _rpn("moonpath", "deadwood", "loam")
	for c: Vector2 in [Vector2(2.8, 8.4), Vector2(13.2, 8.4), Vector2(3.4, 13.4), Vector2(12.6, 13.4), Vector2(8, 6)]:
		_c_rect(Rect2i(int(c.x) - 0, int(c.y) + 1, 1, 2), stem)
		_c_ell(c, Vector2(2.2, 1.4), cap)

func _ic_lightning_rod() -> void:
	# Exposed + Charged: a bolt bent off its path onto a gold crosshair.
	var gold := _rpn("heartlight", "glow", "gold")
	var c := Vector2(9.6, 10.2)
	_c_ring(c, 3.8, 2.0, gold)
	_c_disc(c, 0.9, gold)
	for d: Vector2 in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		_c_line([c + d * 4.2, c + d * 5.6], 1.1, gold)
	_c_line([Vector2(0.8, 0.8), Vector2(5.6, 2.6), Vector2(3.0, 5.0), Vector2(7.4, 7.4)], 1.6, _rpn("heartlight", "glow", "gold"))

# Legendary marks ---------------------------------------------------------------------------------

func _ic_dawnbreak() -> void:
	# Dawnbreak: the dawn breaking up between dark nightmare petals, thin rays fanning out above.
	var c := Vector2(8, 11.2)
	for i in 7:
		var d := Vector2.from_angle(PI + (i + 0.0) * PI / 6.0)
		var a := Vector2i((c + d * 5.4).round())
		var b := Vector2i((c + d * (7.6 if i % 2 == 1 else 6.6)).round())
		_dt_line(a, b, Palette.color("glow") if i % 2 == 1 else Palette.color("gold"))
	_c_disc(c, 3.8, _rpn("heartlight", "glow", "gold"))
	var petal := _rpn("slate", "shade", "dread")
	_c_poly(PackedVector2Array([Vector2(0.4, 15.8), Vector2(1.4, 8.8), Vector2(5.4, 15.8)]), petal)
	_c_poly(PackedVector2Array([Vector2(3.8, 15.8), Vector2(5.8, 12.4), Vector2(8, 15.8)]), petal)
	_c_poly(PackedVector2Array([Vector2(8, 15.8), Vector2(10.2, 12.4), Vector2(12.2, 15.8)]), petal)
	_c_poly(PackedVector2Array([Vector2(10.6, 15.8), Vector2(14.6, 8.8), Vector2(15.6, 15.8)]), petal)
	_dt(7, 9, Palette.color("heartlight"))

# --- HUD-size icons (drawn by hand, shown at exactly x2) --------------------------------------------
# The top-right counters at 12 px (x2 = 24 px) and the HUD button glyphs at 10 px (x2 = 20 px), so
# nothing is ever scaled by a fraction. Same designs as the 16 px icons, simplified.
# Letters are Heartwood 32 names; "o" is the icon outline.

const HUD_INK := {
	"o": "dread", "H": "heartlight", "G": "glow", "g": "gold",
	"N": "newleaf", "S": "sprig", "L": "leaf", "b": "oak",
	"D": "dewlight", "d": "dew", "P": "pool",
	"W": "wraithlight", "U": "bruise",
	"m": "moonpath", "p": "path", "l": "loam",
	"M": "mist", "s": "stone",
}

const HUD_COUNTERS := {
	"leaf_hud": [
		"........ooo.",
		"......ooNNo.",
		".....oNNSSo.",
		"....oNSSSgo.",
		"...oNSSSgLo.",
		"..oNSSSgSLo.",
		"..oSSSgSLo..",
		".oSSSgSLLo..",
		".oSSgSLLo...",
		".oSgLLoo....",
		"obgooo......",
		"bo.........."],
	"dew_hud": [
		".....oo.....",
		"....oDdo....",
		"...oDDddo...",
		"...oDdddo...",
		"..oDHdddPo..",
		".oDHHddddPo.",
		".oDHdddddPo.",
		".oDddddddPo.",
		".oddddddPPo.",
		"..oddddPPo..",
		"...oPPPPo...",
		"....oooo...."],
	"dreamlight_hud": [
		".....oo.....",
		"....oHWo....",
		"...oHWWUo...",
		"..oHWWWWUo..",
		".oHWWWWWWUo.",
		"oHHWWGWWWWUo",
		"oHWWWWWWWUUo",
		".oWWWWWWUUo.",
		"..oWWWWUUo..",
		"...oWWUUo...",
		"....oUUo....",
		".....oo....."],
	"path_hud": [
		".......ooo..",
		"......ommpo.",
		"......opplo.",
		"..ooo..ooo..",
		".ommpo......",
		".opplo.ooo..",
		"..ooo.ommpo.",
		"......opplo.",
		"..ooo..ooo..",
		".ommpo......",
		".opplo......",
		"..ooo......."],
}

const HUD_GLYPHS := {
	"remember_hud": [
		"....oo....",
		"...oHgo...",
		"...oGgo...",
		"..oHGGgo..",
		"oHGGHHGGgo",
		"ogggHGgggo",
		"..oGGggo..",
		"...oGgo...",
		"...oggo...",
		"....oo...."],
	"boosts_hud": [
		"....oo....",
		"...oHGo...",
		"..oHGGgo..",
		".oHGGGggo.",
		"ooooGgoooo",
		"...oGgo...",
		"...oGgo...",
		"...oGgo...",
		"...oggo...",
		"...oooo..."],
	"help_hud": [
		"..oooooo..",
		".oHGGGGgo.",
		".oGgo.oGgo",
		"..oo.oGggo",
		"....oGGgo.",
		"...oGgoo..",
		"...oooo...",
		"...oHGo...",
		"...oGgo...",
		"...oooo..."],
	"menu_hud": [
		".oooooooo.",
		".oHGGGGgo.",
		".oggggggo.",
		".oooooooo.",
		".oHGGGGgo.",
		".oggggggo.",
		".oooooooo.",
		".oHGGGGgo.",
		".oggggggo.",
		".oooooooo."],
	"boosts_off": [
		"....oo....",
		"...oMso...",
		"..oMssso..",
		".oMssssso.",
		"ooooMsoooo",
		"...oMso...",
		"...oMso...",
		"...oMso...",
		"...osso...",
		"...oooo..."],
	"boosts_on": [
		"G...oo...G",
		"...oHGo...",
		"..oHGGgo..",
		".oHGGGggo.",
		"ooooGgoooo",
		"G..oGgo..G",
		"...oGgo...",
		"...oGgo...",
		"...oggo...",
		"...oooo..."],
}

func _hud_sheet(maps: Dictionary, size: int, file_name: String) -> Dictionary:
	var ids := maps.keys()
	var sheet := Image.create(size * ids.size(), size, false, Image.FORMAT_RGBA8)
	var index := {}
	for i in ids.size():
		var rows: Array = maps[ids[i]]
		assert(rows.size() == size, "%s: %d rows" % [ids[i], rows.size()])
		for y in size:
			var row: String = rows[y]
			assert(row.length() == size, "%s row %d: %d wide" % [ids[i], y, row.length()])
			for x in size:
				var ch := row[x]
				if HUD_INK.has(ch):
					sheet.set_pixel(i * size + x, y, Palette.color(HUD_INK[ch]))
		index[ids[i]] = i
	sheet.save_png(OUT + file_name)
	return {image = file_name, frame_size = size, icons = index}

func _make_hud_icons() -> void:
	var data := {
		counters = _hud_sheet(HUD_COUNTERS, 12, "hud_counters.png"),
		glyphs = _hud_sheet(HUD_GLYPHS, 10, "hud_glyphs.png"),
		note = "HUD-size icons, drawn for exactly x2: counters 12 px -> 24 px, button glyphs 10 px -> 20 px. Nearest filtering.",
	}
	var file := FileAccess.open(OUT + "hud_icons.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t") + "\n")

# --- Dream card glyphs (8x8, shown x2 = 16 px inside the rarity gem) -------------------------------
# One light glyph per card tag group, drawn on the dark gem (no outline). "H" = Heartlight, "M" = Mist.
# No family emblems: the family lines use their attack's mark (spore puff, bolt, bell...), as on the
# damage-type badges.

const GLYPH_INK := {"H": "heartlight", "M": "mist"}

const DREAM_GLYPHS := {
	"spore": [
		".HH.....",
		"HHHH....",
		"HHHH.HH.",
		".HH.HHHH",
		"....HHHH",
		".HH..HH.",
		"HHHH....",
		".HH....."],
	"water": [
		"........",
		".HH..HH.",
		"H..HH..H",
		"........",
		".HH..HH.",
		"H..HH..H",
		"........",
		"........"],
	"storm": [
		"....HHH.",
		"...HHH..",
		"..HHH...",
		".HHHHHH.",
		"...HHH..",
		"..HHH...",
		".HHH....",
		".H......"],
	"stone": [
		"........",
		"..HHHH..",
		".HHHHHH.",
		"HHHMHHHH",
		"HHHHHMHH",
		"HHHHHHHH",
		".HHHHHH.",
		"........"],
	"root": [
		"HHHHHHHH",
		"...HH...",
		"..HHHH..",
		".H.HH.H.",
		"H..HH..H",
		"...HH...",
		"..H..H..",
		".H....H."],
	"song": [
		"...HH...",
		"..HHHH..",
		".HHHHHH.",
		".HHMHHH.",
		".HHMHHH.",
		"HHHHHHHH",
		"...HH...",
		"........"],
	"wing": [
		".......H",
		".....HHH",
		"...HHHH.",
		".HHHHM..",
		"HHHHM...",
		".HHM....",
		"H.H.....",
		"........"],
	"wind": [
		"HHHHH...",
		".....H..",
		"HHHH.H..",
		"....H...",
		"HHHHHHH.",
		".......H",
		".HHHH..H",
		".....HH."],
	"acorn": [
		"...H....",
		".HHHHH..",
		"HHHHHHH.",
		"HMMMMMH.",
		".HHHHH..",
		".HHHHH..",
		"..HHH...",
		"...H...."],
	"sprout": [
		"........",
		"HHH...HH",
		".HHH.HHH",
		"..HHHHH.",
		"...HH...",
		"...HH...",
		".HHHHHH.",
		"HHHHHHHH"],
	"wall": [
		".H..H..H",
		"HHHHHHHH",
		"HMHHHMHH",
		"HHHHHHHH",
		"HHHMHHHM",
		"HHHHHHHH",
		"HMHHHMHH",
		"HHHHHHHH"],
	"kinship": [
		".HHH....",
		"H...H...",
		"H..HHHH.",
		"H.H.H..H",
		".HHH...H",
		"...H...H",
		"....HHH.",
		"........"],
	"economy": [
		"..H...H.",
		"..HH.HHH",
		".HHHH.H.",
		".HHHH...",
		"HHHHHH..",
		"HMHHHH..",
		".HHHH...",
		"........"],
	"clearing": [
		"........",
		".HHHHHH.",
		"HMMMMMMH",
		"HMHHHHMH",
		".HHHHHH.",
		".HHHHHH.",
		"HH.HH.HH",
		"........"],
	"leaves": [
		".....HHH",
		"...HHHHH",
		"..HHHHHH",
		".HHHMHH.",
		".HHMHH..",
		".HMHH...",
		"HM......",
		"H......."],
	"maze": [
		"HHHHHHHH",
		"H......H",
		"H.HHHH.H",
		"H.H..H.H",
		"H.H.HH.H",
		"H.H....H",
		"H.HHHHHH",
		"H......."],
	"nurture": [
		"...HH...",
		"..HHHH..",
		".HH..HH.",
		"H..HH..H",
		"..HHHH..",
		".HH..HH.",
		"H......H",
		"........"],
	"crit": [
		"..HHHH..",
		".H....H.",
		"H......H",
		"H..HH..H",
		"H..HH..H",
		"H......H",
		".H....H.",
		"..HHHH.."],
	"reaction": [
		"H..H..H.",
		".H.H.H..",
		"..HHH...",
		"HHHHHHH.",
		"..HHH...",
		".H.H.H..",
		"H..H..H.",
		"........"],
	"bittersweet": [
		".HH..HH.",
		"HHHHHHHH",
		"HHHMHHHH",
		"HHHHHHHH",
		".HHHHHH.",
		"H.HHHH.H",
		"...HH...",
		"........"],
	"generic": [
		"...HH...",
		"...HH...",
		"..HHHH..",
		"HHHHHHHH",
		"HHHHHHHH",
		"..HHHH..",
		"...HH...",
		"...HH..."],
}

# Every card tag (resource/dream/*.tres) -> its glyph. Rare tags fold into the closest one.
const DREAM_TAG_GLYPHS := {
	"spore": "spore", "trap": "spore",
	"water": "water", "fog": "water",
	"storm": "storm", "light": "storm",
	"stone": "stone",
	"root": "root", "held": "root",
	"song": "song", "wing": "wing",
	"wind": "wind", "swift": "wind", "tempo": "wind",
	"acorn": "acorn", "support": "acorn",
	"sprout": "sprout", "seed": "sprout",
	"wall": "wall",
	"kinship": "kinship",
	"economy": "economy", "dreamlight": "economy",
	"clearing": "clearing", "tending": "clearing",
	"leaves": "leaves",
	"maze": "maze", "wide": "maze", "narrow": "maze",
	"nurture": "nurture", "tall": "nurture", "potency": "nurture",
	"crit": "crit", "precision": "crit", "reach": "crit", "range": "crit", "mark": "crit",
	"reaction": "reaction", "affliction": "reaction", "status": "reaction", "on-hit": "reaction", "sleep": "reaction",
	"bittersweet": "bittersweet",
	"daring": "generic", "variety": "generic", "opener": "generic", "dreams": "generic", "overgrowth": "generic",
}

# A card with several tags shows the first glyph in this order that any of its tags maps to.
const DREAM_GLYPH_PRIORITY := ["bittersweet", "kinship", "spore", "water", "storm", "stone", "root", "song",
	"wing", "wind", "acorn", "sprout", "wall", "clearing", "economy", "leaves", "maze", "nurture", "crit",
	"reaction", "generic"]

func _make_dream_glyphs() -> void:
	var ids := DREAM_GLYPHS.keys()
	var sheet := Image.create(8 * ids.size(), 8, false, Image.FORMAT_RGBA8)
	var index := {}
	for i in ids.size():
		var rows: Array = DREAM_GLYPHS[ids[i]]
		assert(rows.size() == 8, "%s: %d rows" % [ids[i], rows.size()])
		for y in 8:
			var row: String = rows[y]
			assert(row.length() == 8, "%s row %d: %d wide" % [ids[i], y, row.length()])
			for x in 8:
				if GLYPH_INK.has(row[x]):
					sheet.set_pixel(i * 8 + x, y, Palette.color(GLYPH_INK[row[x]]))
		index[ids[i]] = i
	sheet.save_png(OUT + "dream_glyphs.png")
	var data := {frame_size = 8, icons = index, tags = DREAM_TAG_GLYPHS, priority = DREAM_GLYPH_PRIORITY,
		fallback = "generic",
		note = "Dream card glyphs, light on the dark rarity gem. Show x2 (16 px), nearest. A card shows the first glyph in `priority` that any of its tags maps to in `tags`; untagged or unknown tags use `fallback`."}
	var file := FileAccess.open(OUT + "dream_glyphs.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t") + "\n")

# --- Buff pips (screens_ui.md "Buff readability"; kinds from BuffSources) ---------------------------
# 10x10, outlined so they read on the map under a Warden (shown x1 in the world, x2 in panels). Each
# kind has its own shape and its BuffSources.COLORS colour; kinship and penalty are light greys for
# code to tint (the family colour; the Bittersweet plum). Stack counts ("x2".."x9") are 9x7 badges.

const PIP_INK := {
	"o": "dread", "H": "heartlight", "G": "glow", "g": "gold", "e": "ember",
	"D": "deadwood", "k": "oak", "b": "bark",
	"N": "newleaf", "S": "sprig", "L": "leaf",
	"m": "moonpath", "p": "path",
	"W": "moonlight", "M": "mist", "s": "stone",
}

const BUFF_PIPS := {
	"acorn": [
		"....oo....",
		"..oobboo..",
		".obkkkkbo.",
		".okkkkkko.",
		".oooooooo.",
		".oGGGGggo.",
		".oGHGGggo.",
		"..oGGggo..",
		"...oggo...",
		"....oo...."],
	"elder_stump": [
		"..........",
		".oooooooo.",
		"oHGGGGGGgo",
		"oGGgggGGgo",
		"oGGGgGGggo",
		".oooooooo.",
		".ogeggego.",
		".ogeggego.",
		"oggeggeggo",
		"oooooooooo"],
	"grove_heart": [
		"..........",
		".ooo..ooo.",
		"oHHGooHGgo",
		"oHGGGGGGgo",
		"oHGGGGGGgo",
		".oGGGGGgo.",
		"..oGGGgo..",
		"...oGgo...",
		"....oo....",
		".........."],
	"grandmother_oak": [
		"..oooooo..",
		".oDDDDDko.",
		"oDDDDDDDko",
		"oDDDDDDkko",
		"oDDDDDkkko",
		".oDkkkkko.",
		"...obko...",
		"...obko...",
		"..obbkko..",
		"..oooooo.."],
	"old_growth": [
		"....oo....",
		"...oNNo...",
		"..oNNSSo..",
		"...oNSo...",
		"..oNNSSo..",
		".oNNSSSSo.",
		".oNSSSSLo.",
		"oNSSSSLLLo",
		"oooobboooo",
		"...obbo..."],
	"kinship": [
		"......ooo.",
		"....ooWWo.",
		"...oWWWMo.",
		"..oWWMMso.",
		".oWWMMso..",
		".oWMMso...",
		".oMMso....",
		"oMsoo.....",
		"oso.......",
		"oo........"],
	"kindred": [
		"....oo....",
		"...oHmo...",
		"..oHmmpo..",
		".oHmmmmpo.",
		"oHmmoommpo",
		"ommmoomppo",
		".ommmmppo.",
		"..ommppo..",
		"...oppo...",
		"....oo...."],
	"whole_tree": [
		"oooooooooo",
		"oSSSNNSSLo",
		"oSSNNNNSLo",
		"oSNNNNNNLo",
		"oSSSkkSSLo",
		"oSSSkkSSLo",
		".oSSSSSLo.",
		"..oSSSLo..",
		"...oSLo...",
		"....oo...."],
	"penalty": [
		"..........",
		"..........",
		"ooo....ooo",
		"oWMo..oWso",
		".oWMooWso.",
		"..oWMWso..",
		"...oWso...",
		"....oo....",
		"..........",
		".........."],
}

const STACK_DIGITS := {
	"2": ["HHH", "..H", "HHH", "H..", "HHH"], "3": ["HHH", "..H", "HHH", "..H", "HHH"],
	"4": ["H.H", "H.H", "HHH", "..H", "..H"], "5": ["HHH", "H..", "HHH", "..H", "HHH"],
	"6": ["HHH", "H..", "HHH", "H.H", "HHH"], "7": ["HHH", "..H", "..H", "..H", "..H"],
	"8": ["HHH", "H.H", "HHH", "H.H", "HHH"], "9": ["HHH", "H.H", "HHH", "..H", "HHH"],
}

func _paint_map(sheet: Image, rows: Array, at: Vector2i, ink: Dictionary) -> void:
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if ink.has(row[x]):
				sheet.set_pixel(at.x + x, at.y + y, Palette.color(ink[row[x]]))

func _stack_badge(digit: String) -> Array:
	# "x" (3x3) then the digit (3x5) in Heartlight, outlined all round in Dread: 9x7.
	var grid := []
	for y in 7:
		grid.append(".........".split(""))
	for p: Vector2i in [Vector2i(1, 2), Vector2i(3, 2), Vector2i(2, 3), Vector2i(1, 4), Vector2i(3, 4)]:
		grid[p.y][p.x] = "H"
	var d: Array = STACK_DIGITS[digit]
	for y in 5:
		for x in 3:
			if d[y][x] == "H":
				grid[y + 1][x + 5] = "H"
	for y in 7:
		for x in 9:
			if grid[y][x] != ".":
				continue
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var nx: int = x + dx
					var ny: int = y + dy
					if nx >= 0 and ny >= 0 and nx < 9 and ny < 7 and grid[ny][nx] == "H":
						grid[y][x] = "o"
	var rows := []
	for y in 7:
		rows.append("".join(grid[y]))
	return rows

func _make_buff_pips() -> void:
	var ids := BUFF_PIPS.keys()
	var pips := Image.create(10 * ids.size(), 10, false, Image.FORMAT_RGBA8)
	var pip_index := {}
	for i in ids.size():
		var rows: Array = BUFF_PIPS[ids[i]]
		assert(rows.size() == 10, "%s: %d rows" % [ids[i], rows.size()])
		for row: String in rows:
			assert(row.length() == 10, "%s: a row is %d wide" % [ids[i], row.length()])
		_paint_map(pips, rows, Vector2i(10 * i, 0), PIP_INK)
		pip_index[ids[i]] = i
	pips.save_png(OUT + "buff_pips.png")
	var digits := STACK_DIGITS.keys()
	var stacks := Image.create(9 * digits.size(), 7, false, Image.FORMAT_RGBA8)
	var stack_index := {}
	for i in digits.size():
		_paint_map(stacks, _stack_badge(digits[i]), Vector2i(9 * i, 0), PIP_INK)
		stack_index["x" + digits[i]] = i
	stacks.save_png(OUT + "buff_stacks.png")
	var data := {
		pips = {image = "buff_pips.png", frame_size = 10, icons = pip_index},
		stacks = {image = "buff_stacks.png", frame_width = 9, frame_height = 7, icons = stack_index},
		tint = ["kinship", "penalty"],
		note = "Buff pips: 10 px, x1 under a Warden on the map, x2 in panels; nearest. kinship and penalty are light greys: modulate them (family colour; plum). Stack badges x2..x9 sit to the pip's right; use x9 for 9 or more.",
	}
	var file := FileAccess.open(OUT + "buff_pips.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t") + "\n")

# --- Grow hints (Main's GrowHints, at a Warden's base during rests) --------------------------------
# Replace the gold arrow with themed world glyphs, warm side of Heartwood 32, outlined for grass and
# the pale path (GrowHints draws them at ~60%):
#   grow_bud:        "can grow"   16x16, 3 frames (a bud swaying and opening)
#   rank_dew:        "can rank"   12x12, 2 frames (a dewdrop shimmering)
#   grow_spotlight:  first time   24x24, 4 frames (a bigger bud opening, pollen motes rising)

const GROW_HINTS := [["grow_bud", 16, 3], ["rank_dew", 12, 2], ["grow_spotlight", 24, 4]]

var _frame := 0

func _make_grow_hints() -> void:
	var index := {}
	for spec: Array in GROW_HINTS:
		var id: String = spec[0]
		var size: int = spec[1]
		var frames: int = spec[2]
		var sheet := Image.create(size * frames, size, false, Image.FORMAT_RGBA8)
		for f in frames:
			_frame = f
			var img := _icon(id, size)
			Palette.snap_image(img)
			sheet.blit_rect(img, Rect2i(0, 0, size, size), Vector2i(f * size, 0))
		sheet.save_png(OUT + id + ".png")
		index[id] = {image = id + ".png", frame_size = size, frames = frames}
	_frame = 0
	_n = ICON
	var file := FileAccess.open(OUT + "grow_hints.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({hints = index,
		note = "Grow hints at a Warden's base (screens_ui.md). Whole-number scale, nearest; ~60% opacity. grow_bud = can grow, rank_dew = can rank, grow_spotlight = the one-time first-grow spotlight. Frames left to right; loop grow_bud 0-1-2-1, rank_dew 0-1, grow_spotlight 0-3."}, "\t") + "\n")

func _sprout(base: Vector2, top: Vector2, leaf_y: float, leaf_r: Vector2, stem_w: float) -> void:
	_c_line([base, Vector2(base.x, leaf_y), top], stem_w, _rpn("sprig", "leaf", "moss"))
	var leaf := _rpn("newleaf", "sprig", "leaf")
	_c_ell(Vector2(base.x - leaf_r.x * 0.9, leaf_y), leaf_r, leaf, -0.45)
	_c_ell(Vector2(base.x + leaf_r.x * 0.9, leaf_y), leaf_r, leaf, 0.45)

func _bud(c: Vector2, r: Vector2, opening: float) -> void:
	# A gold bud; opening 0 = closed, 1 = petals parted round a glowing heart.
	var gold := _rpn("heartlight", "glow", "gold")
	if opening <= 0.0:
		_c_ell(c, r, gold)
		return
	var spread := r.x * 0.55 * opening
	_c_ell(c + Vector2(-spread, 0.3), Vector2(r.x * 0.7, r.y), gold, -0.35 * opening)
	_c_ell(c + Vector2(spread, 0.3), Vector2(r.x * 0.7, r.y), gold, 0.35 * opening)
	_c_disc(c + Vector2(0, -r.y * 0.15), r.x * 0.45, _rpn("heartlight", "heartlight", "glow"))

func _ic_grow_bud() -> void:
	var sway: float = [0.0, 0.8, 0.0][_frame]
	var opening: float = [0.0, 0.0, 1.0][_frame]
	_sprout(Vector2(8, 15.4), Vector2(8 + sway, 7), 11.6, Vector2(2.6, 1.3), 1.5)
	_bud(Vector2(8 + sway, 5.2), Vector2(2.3, 2.8), opening)

func _ic_rank_dew() -> void:
	# The hand-drawn 12 px Dew drop from the HUD counters; frame 1 shimmers (the highlight moves, a glint).
	var rows: Array = HUD_COUNTERS["dew_hud"]
	for y in rows.size():
		for x in rows[y].length():
			var ch: String = rows[y][x]
			if HUD_INK.has(ch):
				_dt(x, y, Palette.color(HUD_INK[ch]))
	if _frame == 1:
		_dt(4, 5, Palette.color("dewlight"))
		_dt(3, 7, Palette.color("heartlight"))
		_dt(10, 1, Palette.color("glow"))
		_dt(9, 2, Palette.color("gold"))
		_dt(11, 2, Palette.color("gold"))
		_dt(10, 3, Palette.color("gold"))
		_dt(10, 2, Palette.color("heartlight"))

func _ic_grow_spotlight() -> void:
	var opening: float = [0.0, 0.45, 0.8, 1.0][_frame]
	var sway: float = [0.0, 0.6, 0.0, -0.6][_frame]
	_sprout(Vector2(12, 23.4), Vector2(12 + sway, 11), 18.0, Vector2(4.0, 1.9), 2.0)
	_bud(Vector2(12 + sway, 8.2), Vector2(3.4, 4.0), opening)
	# Pollen motes drifting up, a step higher each frame.
	for m: Vector2i in [Vector2i(5, 14), Vector2i(19, 12), Vector2i(8, 6), Vector2i(17, 4)]:
		var y := m.y - _frame * 2
		if y < 0:
			y += 16
		_dt(m.x, y, Palette.color("glow"))
		_dt(m.x, y + 1, Palette.color("gold"))
# Late statuses ------------------------------------------------------------------------------------

func _ic_silenced() -> void:
	# Silenced (Hushbell): a pale bell muffled by a band of moss, crossed out by a gold line; the same
	# read as the overhead silence_mark effect.
	var bell := _rpn("moonlight", "mist", "stone")
	_c_poly(PackedVector2Array([Vector2(8, 1.6), Vector2(11.2, 4.4), Vector2(12, 10.4), Vector2(13.6, 12.4),
		Vector2(2.4, 12.4), Vector2(4, 10.4), Vector2(4.8, 4.4)]), bell)
	_c_disc(Vector2(8, 14), 1.4, _rpn("mist", "stone", "slate"))
	_c_rect(Rect2i(4, 6, 8, 2), _rpn("sprig", "leaf", "moss"))
	_c_line([Vector2(1.4, 15), Vector2(14.6, 1.4)], 1.3, _rpn("heartlight", "glow", "gold"))
# --- Family and branch emblems (32x32, shown x1 / x2) ---------------------------------------------
# Heraldic badges, not portraits. Each family has its own frame SHAPE and border colour (its Kinship
# family colour), so the family reads even in grey; a branch keeps its family's frame and border and
# swaps the centre symbol for its job. Dark field, light symbol, outline. The merged sky family
# (Nestling + Whirligig, tower_design.md "Branch expansion") gets its own frame and its own copies of
# the six branches, so both rosters work. The last branch of each family is its hidden one.

const EMBLEM_FAMILIES := {
	"sporeling": {"frame": "cap", "ramp": ["newleaf", "sprig", "leaf"], "motif": "spore_cap",
		"branches": ["driftspore", "bloomcap", "lichenling", "brood_cap", "inkcap", "fairy_ring"]},
	"dewdrop": {"frame": "drop", "ramp": ["dewlight", "dew", "pool"], "motif": "water_drop",
		"branches": ["rain_lily", "mistveil", "cloudlet", "undercurrent", "jetreed", "frostfern"]},
	"firefly_jar": {"frame": "hex", "ramp": ["heartlight", "glow", "gold"], "motif": "light_jar",
		"branches": ["stormcap", "lanternmoth", "jarlink", "prism_jar", "sparkler", "sunpetal"]},
	"bellflower": {"frame": "bell", "ramp": ["blossom", "orchid", "bruise"], "motif": "bell",
		"branches": ["chime_stone", "dreamcatcher", "silver_bell", "hushbell", "thrum", "echo_hollow"]},
	"pebbling": {"frame": "octagon", "ramp": ["moonpath", "deadwood", "loam"], "motif": "stone",
		"branches": ["mossback", "standing_stone", "whetstone", "rampart", "quaker", "cairn"]},
	"rootling": {"frame": "shield", "ramp": ["sprig", "leaf", "moss"], "motif": "root",
		"branches": ["rootcurl", "tangleroot", "groundroot", "deeproot", "thorncoil", "rootlight"]},
	"acorn": {"frame": "acorn", "ramp": ["glow", "gold", "ember"], "motif": "acorn",
		"branches": ["elder_stump", "dewcatcher", "seedbearer", "nurse_log", "dream_oak", "graftling"]},
	"nestling": {"frame": "circle", "ramp": ["heartlight", "moonpath", "path"], "motif": "wing",
		"branches": ["wrens_nest", "magpie_perch", "hummingbird_bower"]},
	"whirligig": {"frame": "diamond", "ramp": ["moonlight", "mist", "stone"], "motif": "whirl",
		"branches": ["gust", "pinwheel", "samara"]},
	"sky": {"frame": "winged", "ramp": ["heartlight", "moonlight", "mist"], "motif": "sky",
		"branches": ["wrens_nest", "magpie_perch", "gust", "pinwheel", "samara", "hummingbird_bower"]},
}

var _em_family := ""
var _em_symbol := ""
var _em_off := Vector2.ZERO

# Each branch's final form shows its branch's emblem (BranchEmblem looks up branch_<tower id>).
const EMBLEM_FINALS := {
	"driftspore": "puffball", "bloomcap": "dreamshroom", "lichenling": "old_lichen", "brood_cap": "hatchery",
	"inkcap": "deliquescent", "fairy_ring": "elf_circle",
	"rain_lily": "monsoon", "mistveil": "morning_fog", "cloudlet": "nimbus", "undercurrent": "maelstrom",
	"jetreed": "torrent", "frostfern": "hoarfrost",
	"stormcap": "thunderhead", "lanternmoth": "beacon", "jarlink": "lightning_fence", "prism_jar": "rainbow_prism",
	"sparkler": "starburst", "sunpetal": "midsummer",
	"chime_stone": "lullaby_bell", "dreamcatcher": "great_dreamcatcher", "silver_bell": "vesper_bell",
	"hushbell": "silence", "thrum": "resonance", "echo_hollow": "whispering_hollow",
	"mossback": "boulderback", "standing_stone": "moonstone", "whetstone": "edgestone", "rampart": "bastion",
	"quaker": "earthshaker", "cairn": "rockslide",
	"rootcurl": "long_way_home", "tangleroot": "snugroot", "groundroot": "earthbind", "deeproot": "heartroot",
	"thorncoil": "crown_of_thorns", "rootlight": "starcave",
	"elder_stump": "grove_heart", "dewcatcher": "wellspring", "seedbearer": "grove_keeper", "nurse_log": "mother_log",
	"dream_oak": "dreamroot", "graftling": "grafted_elder",
	"wrens_nest": "starling_murmuration", "magpie_perch": "magpies_hoard", "hummingbird_bower": "jewelwing_court",
	"gust": "zephyr", "pinwheel": "windmill", "samara": "autumn_gale",
}

func _make_emblems() -> void:
	# Roguelite's BranchEmblem reads assets/ui/emblems/emblems.png + emblems.json:
	# {"family_<base id>": [x, y, w, h], "branch_<tower id>": [x, y, w, h]} (finals share their branch's).
	# The merged sky family (Phase 3) is "family_sky" and "sky_branch_<tower id>".
	var cells: Array = []  # [family, symbol, branch id or ""]
	for fam: String in EMBLEM_FAMILIES:
		cells.append([fam, EMBLEM_FAMILIES[fam].motif, ""])
	for fam: String in EMBLEM_FAMILIES:
		for b: String in EMBLEM_FAMILIES[fam].branches:
			cells.append([fam, b, b])
	var sheet := Image.create(32 * cells.size(), 32, false, Image.FORMAT_RGBA8)
	var index := {}
	for i in cells.size():
		_em_family = cells[i][0]
		_em_symbol = cells[i][1]
		var img := _icon("emblem", 32)
		Palette.snap_image(img)
		sheet.blit_rect(img, Rect2i(0, 0, 32, 32), Vector2i(i * 32, 0))
		var rect := [i * 32, 0, 32, 32]
		var branch: String = cells[i][2]
		if branch == "":
			index["family_" + _em_family] = rect
			continue
		var prefix := "sky_branch_" if _em_family == "sky" else "branch_"
		index[prefix + branch] = rect
		if EMBLEM_FINALS.has(branch):
			index[prefix + EMBLEM_FINALS[branch]] = rect
	_n = ICON
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "emblems/"))
	sheet.save_png(OUT + "emblems/emblems.png")
	var file := FileAccess.open(OUT + "emblems/emblems.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(index, "\t") + "\n")
func _ramp_named(names: Array) -> int:
	var c: Array = []
	for n: String in names:
		c.append(Palette.color(n).to_html(false) if Palette.has_color(n) else n)
	return _rp(c[0], c[1], c[2])

func V(x: float, y: float) -> Vector2:
	return Vector2(x, y) + _em_off

func D(x: float, y: float, colour: String) -> void:
	var p := V(x, y)
	_dt(int(p.x), int(p.y), Palette.color(colour))

func _pts(raw: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Vector2 in raw:
		out.append(p + _em_off)
	return out

func _frame_points(shape: String) -> Array:
	# [outer polygon, symbol offset]
	var c := Vector2(16, 16)
	var pts: Array = []
	match shape:
		"cap":
			for i in 13:
				pts.append(Vector2(16, 16) + Vector2.from_angle(PI + i * PI / 12.0) * 13.5)
			pts.append_array([Vector2(29.5, 29.5), Vector2(2.5, 29.5)])
			return [pts, Vector2(0, 1)]
		"drop":
			pts.append(Vector2(16, 0.8))
			for i in 15:
				var a := deg_to_rad(-55.0 + i * (290.0 / 14.0))
				pts.append(Vector2(16, 19) + Vector2.from_angle(a) * 12.0)
			return [pts, Vector2(0, 2.5)]
		"hex":
			for i in 6:
				pts.append(c + Vector2.from_angle(i * PI / 3.0) * 15.2)
			return [pts, Vector2.ZERO]
		"bell":
			pts = [Vector2(16, 1.5), Vector2(21, 2.5), Vector2(24.5, 6.5), Vector2(25.5, 13), Vector2(27, 21),
				Vector2(30.5, 29.5), Vector2(1.5, 29.5), Vector2(5, 21), Vector2(6.5, 13), Vector2(7.5, 6.5), Vector2(11, 2.5)]
			return [pts, Vector2(0, 1.5)]
		"octagon":
			for i in 8:
				pts.append(c + Vector2.from_angle(PI / 8.0 + i * PI / 4.0) * 15.6)
			return [pts, Vector2.ZERO]
		"shield":
			pts = [Vector2(2.5, 2.5), Vector2(29.5, 2.5), Vector2(29.5, 15), Vector2(26, 23.5), Vector2(16, 30.5),
				Vector2(6, 23.5), Vector2(2.5, 15)]
			return [pts, Vector2(0, -0.5)]
		"acorn":
			pts = [Vector2(16, 1.5), Vector2(23, 2.8), Vector2(28.5, 6.5), Vector2(30.5, 11), Vector2(27, 13),
				Vector2(28, 19), Vector2(24, 26), Vector2(16, 30.8), Vector2(8, 26), Vector2(4, 19), Vector2(5, 13),
				Vector2(1.5, 11), Vector2(3.5, 6.5), Vector2(9, 2.8)]
			return [pts, Vector2(0, 1.5)]
		"circle":
			for i in 20:
				pts.append(c + Vector2.from_angle(i * TAU / 20.0) * 14.8)
			return [pts, Vector2.ZERO]
		"diamond":
			pts = [Vector2(16, 0.4), Vector2(31.6, 16), Vector2(16, 31.6), Vector2(0.4, 16)]
			return [pts, Vector2.ZERO]
		"winged":
			for i in 24:
				var a := i * TAU / 24.0
				var r := 12.6
				if i == 11 or i == 13 or i == 23 or i == 1:
					r = 14.0
				if i == 12 or i == 0:
					r = 15.8
				pts.append(Vector2(16, 16.5) + Vector2.from_angle(a) * r)
			return [pts, Vector2(0, 0.5)]
	return [pts, Vector2.ZERO]

func _ic_emblem() -> void:
	var fam: Dictionary = EMBLEM_FAMILIES[_em_family]
	var fp: Array = _frame_points(fam.frame)
	var outer: Array = fp[0]
	_em_off = Vector2.ZERO
	var border := _ramp_named(fam.ramp)
	_c_poly(PackedVector2Array(outer), border)
	var centre := Vector2.ZERO
	for p: Vector2 in outer:
		centre += p
	centre /= outer.size()
	var inner := PackedVector2Array()
	for p: Vector2 in outer:
		inner.append(centre + (p - centre) * 0.8)
	_c_poly(inner, _ramp_named(["dusk", "night", "void"]))
	_em_off = fp[1]
	var light: String = fam.ramp[0]
	var mid: String = fam.ramp[1]
	var k := _ramp_named(["heartlight", light, mid])
	var a := _ramp_named(["heartlight", "glow", "gold"])
	call("_sym_" + _em_symbol, k, a)
	_em_off = Vector2.ZERO

func _rect_pts(x: float, y: float, w: float, h: float) -> PackedVector2Array:
	return _pts([Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)])

func _cap(cx: float, cy: float, rx: float, ry: float, k: int) -> void:
	var raw: Array = []
	for i in 9:
		raw.append(Vector2(cx, cy) + Vector2.from_angle(PI + i * PI / 8.0) * Vector2(rx, ry))
	_c_poly(_pts(raw), k)

func _bell_shape(cx: float, top: float, h: float, w: float, k: int) -> void:
	_c_poly(_pts([Vector2(cx, top), Vector2(cx + w * 0.3, top + 0.6), Vector2(cx + w * 0.42, top + h * 0.35),
		Vector2(cx + w * 0.46, top + h * 0.75), Vector2(cx + w * 0.62, top + h), Vector2(cx - w * 0.62, top + h),
		Vector2(cx - w * 0.46, top + h * 0.75), Vector2(cx - w * 0.42, top + h * 0.35), Vector2(cx - w * 0.3, top + 0.6)]), k)

# Family motifs --------------------------------------------------------------------------------

func _sym_spore_cap(k: int, a: int) -> void:
	_cap(16, 16, 8.5, 7.5, k)
	_c_poly(_rect_pts(14, 16, 4, 7), _ramp_named(["moonpath", "deadwood", "loam"]))
	D(12, 12, "leaf"); D(19, 11, "leaf"); D(17, 14, "leaf"); D(13, 13, "leaf")

func _sym_water_drop(k: int, a: int) -> void:
	_drop(V(16, 16.5), 5.6, k)
	D(14, 15, "heartlight"); D(13, 16, "heartlight")

func _sym_light_jar(k: int, a: int) -> void:
	_c_poly(_rect_pts(12, 7, 8, 2.5), _ramp_named(["moonpath", "deadwood", "oak"]))
	_c_ell(V(16, 16.5), Vector2(6, 7), _ramp_named(["moonlight", "mist", "stone"]))
	_c_disc(V(16, 17), 3.4, a)
	D(16, 16, "heartlight"); D(13, 13, "heartlight")

func _sym_bell(k: int, a: int) -> void:
	_bell_shape(16, 7, 14, 15, k)
	_c_disc(V(16, 23), 1.7, a)
	_c_disc(V(16, 6.4), 1.3, k)

func _sym_stone(k: int, a: int) -> void:
	_c_ell(V(16, 17), Vector2(8.5, 6.5), _ramp_named(["moonlight", "mist", "stone"]))
	_dt_line(Vector2i(V(13, 13)), Vector2i(V(16, 17)), Palette.color("slate"))
	_dt_line(Vector2i(V(16, 17)), Vector2i(V(15, 21)), Palette.color("slate"))

func _sym_root(k: int, a: int) -> void:
	_c_line([V(16, 6), V(16, 15)], 2.4, k)
	_c_line([V(16, 14), V(12, 18), V(9, 24)], 1.8, k)
	_c_line([V(16, 14), V(16, 25)], 1.8, k)
	_c_line([V(16, 14), V(20, 18), V(23, 24)], 1.8, k)
	_c_line([V(12, 18), V(8, 18)], 1.2, k)
	_c_line([V(20, 18), V(24, 17)], 1.2, k)

func _sym_acorn(k: int, a: int) -> void:
	_c_ell(V(16, 18.5), Vector2(5.6, 6.2), k)
	_c_ell(V(16, 12), Vector2(7.2, 3.4), _ramp_named(["moonpath", "deadwood", "oak"]))
	_c_line([V(16, 9), V(17.5, 5.5)], 1.4, _ramp_named(["moonpath", "deadwood", "oak"]))
	D(14, 17, "heartlight")

func _wing_shape(dx: float, dy: float, s: float, k: int) -> void:
	var raw := [Vector2(7, 21), Vector2(10, 13), Vector2(16, 8.5), Vector2(25, 6.5), Vector2(21.5, 11.5),
		Vector2(25.5, 13), Vector2(20.5, 16.5), Vector2(23.5, 19.5), Vector2(15, 22.5)]
	var out: Array = []
	for p: Vector2 in raw:
		out.append(Vector2(16, 16) + (p - Vector2(16, 16)) * s + Vector2(dx, dy))
	_c_poly(_pts(out), k)

func _sym_wing(k: int, a: int) -> void:
	_wing_shape(0, 0, 1.0, k)
	_dt_line(Vector2i(V(11, 18)), Vector2i(V(19, 11)), Palette.color("path"))
	_dt_line(Vector2i(V(13, 20)), Vector2i(V(20, 15)), Palette.color("path"))

func _blades(c: Vector2, r: float, k: int) -> void:
	for i in 4:
		var d := Vector2.from_angle(i * PI / 2.0 - PI / 4.0)
		_c_poly(PackedVector2Array([c, c + d * r, c + d * (r * 0.42) + d.orthogonal() * (r * 0.5)]), k)

func _sym_whirl(k: int, a: int) -> void:
	_blades(V(16, 16), 10, k)
	_c_disc(V(16, 16), 1.6, a)

func _sym_sky(k: int, a: int) -> void:
	_wing_shape(-2.5, 1.5, 0.8, k)
	_c_line([V(17, 8), V(23, 7), V(26, 10), V(24, 13), V(21, 12)], 1.3, _ramp_named(["moonlight", "mist", "stone"]))
	_c_line([V(19, 22), V(25, 21), V(27, 18)], 1.3, _ramp_named(["moonlight", "mist", "stone"]))

# Sporeling branches -------------------------------------------------------------------------

func _sym_driftspore(k: int, a: int) -> void:
	_c_disc(V(11, 20), 3.0, k)
	_c_disc(V(17.5, 14.5), 2.5, k)
	_c_disc(V(22.5, 9), 2.0, k)
	for y: float in [23.0, 18.0, 12.0]:
		_dt_line(Vector2i(V(5, y + 1)), Vector2i(V(8, y)), Palette.color("leaf"))

func _sym_bloomcap(k: int, a: int) -> void:
	_cap(14, 18, 7.5, 6.5, _ramp_named(["heartlight", "blossom", "orchid"]))
	_c_poly(_rect_pts(12, 18, 4, 5), _ramp_named(["moonpath", "deadwood", "loam"]))
	var z := V(19, 6)
	_zz(int(z.x), int(z.y), k)

func _sym_lichenling(k: int, a: int) -> void:
	_c_ell(V(11.5, 20), Vector2(5.4, 2.6), k)
	_c_ell(V(20, 16.5), Vector2(5.4, 2.6), k)
	_c_ell(V(13.5, 12), Vector2(4.8, 2.4), k)
	D(11, 20, "leaf"); D(20, 16, "leaf"); D(13, 12, "leaf")

func _sym_brood_cap(k: int, a: int) -> void:
	_cap(16, 13, 7, 6, k)
	_c_poly(_rect_pts(14.5, 13, 3, 4), _ramp_named(["moonpath", "deadwood", "loam"]))
	for x: float in [9.5, 22.5]:
		_c_disc(V(x, 21.5), 2.1, k)
		_dt(int(V(x - 1.5, 24).x), int(V(0, 24).y), Palette.color(EMBLEM_FAMILIES[_em_family].ramp[1]))
		_dt(int(V(x + 1.5, 24).x), int(V(0, 24).y), Palette.color(EMBLEM_FAMILIES[_em_family].ramp[1]))

func _sym_inkcap(k: int, a: int) -> void:
	_c_poly(_pts([Vector2(16, 5.5), Vector2(20, 8.5), Vector2(21.5, 17), Vector2(19.5, 19.5), Vector2(12.5, 19.5),
		Vector2(10.5, 17), Vector2(12, 8.5)]), k)
	for x: float in [12.0, 16.0, 20.0]:
		_c_line([V(x, 19.5), V(x, 24.5 - absf(x - 16) * 0.3)], 1.1, k)

func _sym_fairy_ring(k: int, a: int) -> void:
	for i in 6:
		var p := V(16, 16.5) + Vector2.from_angle(i * TAU / 6.0 - PI / 2) * 7.6
		_c_ell(p, Vector2(2.2, 1.5), k)
		_dt(int(p.x), int(p.y + 2), Palette.color("moonpath"))
	_dt(int(V(16, 16).x), int(V(16, 16).y), Palette.color("glow"))

# Dewdrop branches ---------------------------------------------------------------------------

func _sym_rain_lily(k: int, a: int) -> void:
	for d: float in [-1.0, 0.0, 1.0]:
		_c_ell(V(16 + d * 4.5, 19 - absf(d) * 1.5), Vector2(2.4, 5.2), k, d * 0.55)
	for x: float in [9.0, 15.0, 21.0]:
		_dt_line(Vector2i(V(x + 1, 6)), Vector2i(V(x, 9)), Palette.color("dewlight"))

func _sym_mistveil(k: int, a: int) -> void:
	for y: float in [11.0, 16.5, 22.0]:
		var pts: Array = []
		for i in 7:
			pts.append(V(7 + i * 3, y + (1.2 if i % 2 == 0 else -1.2)))
		_c_line(pts, 1.6, k)

func _cloud(cx: float, cy: float, s: float, k: int) -> void:
	_c_disc(V(cx - 4.5 * s, cy + 1 * s), 3.2 * s, k)
	_c_disc(V(cx, cy - 1.5 * s), 4.2 * s, k)
	_c_disc(V(cx + 4.5 * s, cy + 1 * s), 3.0 * s, k)
	_c_poly(_rect_pts(cx - 7 * s, cy + 0.5 * s, 14 * s, 3.4 * s), k)

func _sym_cloudlet(k: int, a: int) -> void:
	_cloud(16, 12, 1.0, k)
	for x: float in [10.0, 15.0, 20.0]:
		_c_line([V(x, 18.5), V(x - 1, 22.5)], 1.2, _ramp_named(["dewlight", "dew", "pool"]))

func _sym_undercurrent(k: int, a: int) -> void:
	var pts: Array = []
	for i in 22:
		var t := i / 21.0
		pts.append(V(16, 16.5) + Vector2.from_angle(t * TAU * 1.6) * (1.0 + t * 8.5))
	_c_line(pts, 1.6, k)

func _sym_jetreed(k: int, a: int) -> void:
	_c_line([V(7, 24), V(14, 17)], 3.0, _ramp_named(["sprig", "leaf", "moss"]))
	_c_line([V(14.5, 16.5), V(25, 7)], 1.8, k)
	for p: Vector2 in [Vector2(22, 12), Vector2(26, 10), Vector2(20, 9)]:
		D(p.x, p.y, "dewlight")

func _sym_frostfern(k: int, a: int) -> void:
	var c := V(16, 16.5)
	var ice := _ramp_named(["heartlight", "moonlight", "dewlight"])
	for i in 3:
		var d := Vector2.from_angle(PI * 0.5 + i * PI / 3.0)
		_c_line([c - d * 8.5, c + d * 8.5], 1.4, ice)
		for s: float in [-1.0, 1.0]:
			var p := c + d * 5.5 * s
			_c_line([p, p + d.rotated(0.8) * 2.4 * s], 1.1, ice)
			_c_line([p, p + d.rotated(-0.8) * 2.4 * s], 1.1, ice)

# Firefly branches ----------------------------------------------------------------------------

func _sym_stormcap(k: int, a: int) -> void:
	_c_poly(_pts([Vector2(19, 5), Vector2(11, 17), Vector2(15.5, 17), Vector2(12, 27), Vector2(22, 13),
		Vector2(17.5, 13), Vector2(21.5, 5)]), a)

func _sym_lanternmoth(k: int, a: int) -> void:
	var w := _ramp_named(["moonpath", "deadwood", "oak"])
	_c_poly(_pts([Vector2(15, 14), Vector2(7, 8), Vector2(6.5, 15), Vector2(14.5, 18)]), w)
	_c_poly(_pts([Vector2(17, 14), Vector2(25, 8), Vector2(25.5, 15), Vector2(17.5, 18)]), w)
	_c_ell(V(11, 20), Vector2(3, 2.4), w)
	_c_ell(V(21, 20), Vector2(3, 2.4), w)
	_c_ell(V(16, 17), Vector2(1.6, 5.5), a)

func _sym_jarlink(k: int, a: int) -> void:
	var glass := _ramp_named(["moonlight", "mist", "stone"])
	for x: float in [8.0, 24.0]:
		_c_ell(V(x, 19), Vector2(3.2, 4.2), glass)
		_c_disc(V(x, 19.5), 1.6, a)
	_c_line([V(10, 13), V(13, 10), V(15, 13), V(18, 9), V(20, 12), V(22, 13)], 1.3, a)

func _sym_prism_jar(k: int, a: int) -> void:
	_c_poly(_pts([Vector2(16, 5), Vector2(21.5, 12), Vector2(16, 22), Vector2(10.5, 12)]), _ramp_named(["heartlight", "moonlight", "dewlight"]))
	_dt_line(Vector2i(V(16, 7)), Vector2i(V(16, 20)), Palette.color("moonlight"))
	_c_line([V(16, 22), V(10, 27)], 1.0, _ramp_named(["sprig", "sprig", "leaf"]))
	_c_line([V(16, 22), V(16, 27.5)], 1.0, a)
	_c_line([V(16, 22), V(22, 27)], 1.0, _ramp_named(["blossom", "blossom", "orchid"]))

func _sym_sparkler(k: int, a: int) -> void:
	var c := V(17, 13)
	for i in 8:
		var d := Vector2.from_angle(i * TAU / 8.0)
		_c_line([c + d * 2.0, c + d * (7.0 if i % 2 == 0 else 5.0)], 1.2, a)
	_c_disc(c, 1.8, a)
	_c_line([V(15.5, 15), V(10, 26)], 1.4, _ramp_named(["moonpath", "deadwood", "oak"]))

func _sym_sunpetal(k: int, a: int) -> void:
	var c := V(16, 16.5)
	for i in 8:
		var d := Vector2.from_angle(i * TAU / 8.0 + PI / 8.0)
		_c_ell(c + d * 7.5, Vector2(2.4, 1.3), a, d.angle())
	_c_disc(c, 4.2, a)
	D(15, 15, "heartlight")

# Bellflower branches -------------------------------------------------------------------------

func _sym_chime_stone(k: int, a: int) -> void:
	# A chiming stone with two arcs of sound rising off it.
	_c_ell(V(16, 20), Vector2(6.5, 4.8), _ramp_named(["moonlight", "mist", "stone"]))
	for r: float in [9.0, 12.5]:
		var pts: Array = []
		for i in 9:
			pts.append(V(16, 20) + Vector2.from_angle(PI + 0.55 + i * (PI - 1.1) / 8.0) * r)
		_c_line(pts, 1.3, k)
func _sym_dreamcatcher(k: int, a: int) -> void:
	_c_ring(V(16, 13), 7.5, 6.1, k)
	var c := V(16, 13)
	for i in 3:
		var d := Vector2.from_angle(i * PI / 3.0)
		_dt_line(Vector2i(c - d * 5.5), Vector2i(c + d * 5.5), Palette.color("orchid"))
	_dt(int(c.x), int(c.y), Palette.color("glow"))
	for x: float in [11.0, 16.0, 21.0]:
		_c_line([V(x, 20), V(x, 25 - absf(x - 16) * 0.2)], 1.0, k)
		_c_ell(V(x, 26 - absf(x - 16) * 0.2), Vector2(1.0, 1.8), _ramp_named(["moonpath", "deadwood", "oak"]))

func _sym_silver_bell(k: int, a: int) -> void:
	_c_line([V(8, 6), V(24, 6)], 1.6, _ramp_named(["moonpath", "deadwood", "oak"]))
	_c_line([V(9, 6), V(9, 24)], 1.4, _ramp_named(["moonpath", "deadwood", "oak"]))
	_c_line([V(23, 6), V(23, 24)], 1.4, _ramp_named(["moonpath", "deadwood", "oak"]))
	_bell_shape(16, 8, 14, 9, _ramp_named(["heartlight", "moonlight", "mist"]))
	_c_disc(V(16, 23.5), 1.3, a)

func _sym_hushbell(k: int, a: int) -> void:
	_bell_shape(16, 7, 15, 14, _ramp_named(["moonlight", "mist", "stone"]))
	_c_poly(_rect_pts(10.5, 13, 11, 3), _ramp_named(["sprig", "leaf", "moss"]))
	_c_line([V(7, 25), V(25, 7)], 1.5, a)

func _sym_thrum(k: int, a: int) -> void:
	_c_poly(_pts([Vector2(6, 16), Vector2(15, 11), Vector2(15, 21)]), k)
	for r: float in [4.0, 7.0, 10.0]:
		var pts: Array = []
		for i in 7:
			pts.append(V(15, 16) + Vector2.from_angle(-0.6 + i * 0.2) * r)
		_c_line(pts, 1.2, k)

func _sym_echo_hollow(k: int, a: int) -> void:
	_c_disc(V(16, 16.5), 2.0, a)
	for r: float in [5.0, 8.5]:
		_c_ring(V(16, 16.5), r + 0.6, r - 0.6, k)
	_c_poly(_rect_pts(15, 5, 2, 23), _ramp_named(["dusk", "night", "void"]))
	_c_disc(V(16, 16.5), 2.0, a)

# Pebbling branches ---------------------------------------------------------------------------

func _sym_mossback(k: int, a: int) -> void:
	_c_ell(V(16, 18), Vector2(8.5, 6.5), _ramp_named(["moonlight", "mist", "stone"]))
	_c_ell(V(15, 12.5), Vector2(6.5, 2.6), _ramp_named(["sprig", "leaf", "moss"]))

func _sym_standing_stone(k: int, a: int) -> void:
	_c_poly(_pts([Vector2(12, 26), Vector2(11, 12), Vector2(14, 6.5), Vector2(18.5, 7.5), Vector2(20.5, 13), Vector2(20, 26)]),
		_ramp_named(["moonlight", "mist", "stone"]))
	_c_disc(V(23.5, 8), 2.2, _ramp_named(["heartlight", "moonlight", "mist"]))
	_dt_line(Vector2i(V(14, 14)), Vector2i(V(17, 17)), Palette.color("slate"))

func _sym_whetstone(k: int, a: int) -> void:
	_c_poly(_pts([Vector2(7, 25), Vector2(24, 6), Vector2(25.5, 8.5), Vector2(10, 26.5)]), _ramp_named(["heartlight", "moonlight", "mist"]))
	_dt_line(Vector2i(V(9, 25)), Vector2i(V(24, 8)), Palette.color("stone"))
	for p: Vector2 in [Vector2(22, 14), Vector2(25, 13), Vector2(23, 16)]:
		D(p.x, p.y, "glow")

func _sym_rampart(k: int, a: int) -> void:
	var st := _ramp_named(["moonlight", "mist", "stone"])
	_c_poly(_rect_pts(7, 9, 18, 15), st)
	for y: float in [13.0, 18.0]:
		_dt_line(Vector2i(V(7, y)), Vector2i(V(24, y)), Palette.color("slate"))
	for p: Array in [[12, 9, 13], [19, 9, 13], [10, 13, 18], [16, 13, 18], [22, 13, 18], [13, 18, 24], [19, 18, 24]]:
		_dt_line(Vector2i(V(p[0], p[1])), Vector2i(V(p[0], p[2] - 1)), Palette.color("slate"))
	for x: float in [7.0, 12.0, 17.0, 22.0]:
		_c_poly(_rect_pts(x, 6, 3, 3), st)

func _sym_quaker(k: int, a: int) -> void:
	_c_poly(_rect_pts(11, 6, 10, 9), _ramp_named(["moonlight", "mist", "stone"]))
	_dt_line(Vector2i(V(13, 7)), Vector2i(V(13, 13)), Palette.color("slate"))
	_dt_line(Vector2i(V(16, 7)), Vector2i(V(16, 13)), Palette.color("slate"))
	_dt_line(Vector2i(V(19, 7)), Vector2i(V(19, 13)), Palette.color("slate"))
	_c_line([V(6, 22), V(26, 22)], 1.4, k)
	_c_line([V(16, 22), V(13, 26)], 1.1, k)
	_c_line([V(16, 22), V(20, 26)], 1.1, k)
	for p: Vector2 in [Vector2(8, 18), Vector2(24, 18), Vector2(10, 16), Vector2(22, 16)]:
		D(p.x, p.y, "glow")

func _sym_cairn(k: int, a: int) -> void:
	var st := _ramp_named(["moonlight", "mist", "stone"])
	_c_ell(V(16, 23), Vector2(8, 3.2), st)
	_c_ell(V(15.5, 17), Vector2(6, 2.8), st)
	_c_ell(V(16.5, 11.5), Vector2(4.2, 2.4), st)
	_c_ell(V(16, 7), Vector2(2.6, 1.8), st)

# Rootling branches ---------------------------------------------------------------------------

func _sym_rootcurl(k: int, a: int) -> void:
	var pts: Array = [V(9, 25), V(11, 18), V(14, 12)]
	for i in 12:
		var t := i / 11.0
		pts.append(V(18, 12) + Vector2.from_angle(PI + t * TAU * 0.9) * (4.5 - t * 3.0))
	_c_line(pts, 1.8, k)

func _sym_tangleroot(k: int, a: int) -> void:
	_c_line([V(6, 9), V(12, 14), V(20, 18), V(26, 24)], 1.8, k)
	_c_line([V(26, 9), V(20, 13), V(12, 19), V(6, 24)], 1.8, k)
	_c_ring(V(16, 16), 4.2, 2.8, k)

func _sym_groundroot(k: int, a: int) -> void:
	_c_line([V(6, 26), V(26, 26)], 1.6, k)
	_c_line([V(10, 26), V(9, 18), V(7, 12)], 1.6, k)
	_c_line([V(16, 26), V(16, 16), V(16, 8)], 1.8, k)
	_c_line([V(22, 26), V(23, 18), V(25, 12)], 1.6, k)
	for p: Vector2 in [Vector2(6, 11), Vector2(8, 10), Vector2(15, 7), Vector2(17, 7), Vector2(24, 10), Vector2(26, 11)]:
		D(p.x, p.y, "newleaf")

func _sym_deeproot(k: int, a: int) -> void:
	_c_ring(V(16, 16.5), 8.6, 6.9, k)
	_c_disc(V(16, 16.5), 3.0, a)
	_c_line([V(16, 25), V(16, 28)], 1.4, k)

func _sym_thorncoil(k: int, a: int) -> void:
	_c_poly(_pts([Vector2(7, 22), Vector2(7, 12), Vector2(11, 16), Vector2(16, 8), Vector2(21, 16), Vector2(25, 12), Vector2(25, 22)]), k)
	for p: Array in [[7, 17, 4, 16], [25, 17, 28, 16], [12, 22, 11, 25], [20, 22, 21, 25]]:
		_c_line([V(p[0], p[1]), V(p[2], p[3])], 1.1, k)

func _sym_rootlight(k: int, a: int) -> void:
	_c_line([V(16, 26), V(15, 19), V(17, 13)], 1.8, k)
	_c_line([V(15, 22), V(10, 26)], 1.3, k)
	_c_line([V(16, 23), V(21, 26)], 1.3, k)
	_c_disc(V(17, 10), 3.6, a)
	D(16, 9, "heartlight")

# Acorn branches ------------------------------------------------------------------------------

func _sym_elder_stump(k: int, a: int) -> void:
	var bark := _ramp_named(["moonpath", "deadwood", "oak"])
	_c_poly(_rect_pts(9, 11, 14, 12), bark)
	_c_ell(V(16, 11), Vector2(7, 2.8), k)
	_dt_line(Vector2i(V(13, 11)), Vector2i(V(19, 11)), Palette.color("ember"))
	_c_line([V(9, 23), V(6, 26)], 1.6, bark)
	_c_line([V(23, 23), V(26, 26)], 1.6, bark)

func _sym_dewcatcher(k: int, a: int) -> void:
	_drop(V(16, 11), 2.8, _ramp_named(["dewlight", "dew", "pool"]))
	var raw: Array = []
	for i in 9:
		raw.append(Vector2(16, 17) + Vector2.from_angle(i * PI / 8.0) * Vector2(9, 7))
	_c_poly(_pts(raw), k)

func _sym_seedbearer(k: int, a: int) -> void:
	var sack := _ramp_named(["moonpath", "deadwood", "oak"])
	_c_ell(V(16, 19), Vector2(7.5, 7), sack)
	_c_poly(_pts([Vector2(13, 12), Vector2(19, 12), Vector2(21, 8), Vector2(11, 8)]), sack)
	_c_line([V(12.5, 12), V(19.5, 12)], 1.2, k)
	_c_ell(V(16, 19), Vector2(2.2, 3), k)

func _sym_nurse_log(k: int, a: int) -> void:
	var bark := _ramp_named(["moonpath", "deadwood", "oak"])
	_c_poly(_rect_pts(6, 18, 18, 6), bark)
	_c_ell(V(24, 21), Vector2(2.6, 3.2), k)
	_c_line([V(14, 18), V(14, 11)], 1.3, _ramp_named(["sprig", "leaf", "moss"]))
	_c_ell(V(11.5, 11), Vector2(2.4, 1.4), _ramp_named(["newleaf", "sprig", "leaf"]), -0.4)
	_c_ell(V(16.5, 10), Vector2(2.4, 1.4), _ramp_named(["newleaf", "sprig", "leaf"]), 0.4)

func _sym_dream_oak(k: int, a: int) -> void:
	_c_poly(_rect_pts(14.5, 16, 3, 9), _ramp_named(["moonpath", "deadwood", "oak"]))
	_c_disc(V(16, 12), 7.0, _ramp_named(["newleaf", "sprig", "leaf"]))
	_c_disc(V(19.5, 14), 2.0, _ramp_named(["heartlight", "blossom", "orchid"]))
	D(19, 13, "heartlight")

func _sym_graftling(k: int, a: int) -> void:
	var bark := _ramp_named(["moonpath", "deadwood", "oak"])
	_c_line([V(16, 26), V(16, 16)], 2.4, bark)
	_c_line([V(16, 16), V(10, 8)], 1.8, bark)
	_c_line([V(16, 16), V(22, 8)], 1.8, _ramp_named(["sprig", "leaf", "moss"]))
	_c_poly(_rect_pts(13.5, 15, 5, 3), k)

# Sky branches (Nestling, Whirligig) ----------------------------------------------------------

func _sym_wrens_nest(k: int, a: int) -> void:
	var nest := _ramp_named(["moonpath", "deadwood", "oak"])
	var raw: Array = []
	for i in 9:
		raw.append(Vector2(16, 16) + Vector2.from_angle(i * PI / 8.0) * Vector2(10, 7))
	_c_poly(_pts(raw), nest)
	for x: float in [12.5, 16.5, 20.0]:
		_c_ell(V(x, 15), Vector2(2.0, 2.5), _ramp_named(["heartlight", "moonlight", "dewlight"]))
	_dt_line(Vector2i(V(8, 19)), Vector2i(V(24, 19)), Palette.color("oak"))

func _sym_magpie_perch(k: int, a: int) -> void:
	_c_ring(V(13, 19), 5.4, 3.6, a)
	_c_poly(_pts([Vector2(21, 6), Vector2(25, 10), Vector2(21, 15), Vector2(17, 10)]), _ramp_named(["heartlight", "moonlight", "dewlight"]))
	D(20, 9, "heartlight")

func _sym_hummingbird_bower(k: int, a: int) -> void:
	_c_ell(V(17, 16), Vector2(4.2, 2.6), k, -0.3)
	_c_line([V(13, 17.5), V(5, 21)], 1.0, k)
	_c_poly(_pts([Vector2(18, 15), Vector2(23, 6), Vector2(25, 9), Vector2(20, 16)]), _ramp_named(["dewlight", "dew", "pool"]))
	_c_line([V(20.5, 17), V(25, 22)], 1.4, k)
	_c_disc(V(7, 25), 2.0, _ramp_named(["heartlight", "blossom", "orchid"]))

func _sym_gust(k: int, a: int) -> void:
	var w := _ramp_named(["heartlight", "moonlight", "mist"])
	_c_line([V(5, 11), V(19, 11), V(22, 8.5), V(19.5, 6.5)], 1.6, w)
	_c_line([V(8, 16.5), V(24, 16.5), V(27, 19), V(24, 21)], 1.6, w)
	_c_line([V(5, 22), V(15, 22)], 1.6, w)

func _sym_pinwheel(k: int, a: int) -> void:
	_c_line([V(16, 16), V(16, 28)], 1.4, _ramp_named(["moonpath", "deadwood", "oak"]))
	_blades(V(16, 13.5), 8, k)
	_c_disc(V(16, 13.5), 1.4, a)

func _sym_samara(k: int, a: int) -> void:
	_c_disc(V(10, 21), 3.0, _ramp_named(["moonpath", "deadwood", "oak"]))
	_c_ell(V(17.5, 13.5), Vector2(8.5, 3.2), k, -0.75)
	_dt_line(Vector2i(V(12, 19)), Vector2i(V(22, 9)), Palette.color("mist"))
