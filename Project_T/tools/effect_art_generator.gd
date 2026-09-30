extends SceneTree
# Generates combat effect sheets in assets/effects/ plus assets/effects/effects.json (frame size,
# frames, fps, anchor, loop, kind, callout colour) for the code to play them. Pixel art to match
# the Warden sheets. The look: WARM light breaking COLD shadow (art_direction.md), with a bright
# 2-3 frame peak so effects read over dark, translucent nightmares.
#   Reactions: thunderclap (+ arc segment), ignite, overgrowth (+ ground cloud), shatter, drown,
#   pinned, smother, lightning_rod.
#   Chain UI: chain_badge, chain_digits, dawnburst, surge, light_thread, crit_flare, status_flash.
#   Final-form signatures: thunderhead_strike, monsoon_sweep, moonstone_beam, puffball_bloom,
#   long_way_home_drag.
#   Lite variants (fewer particles, no big flash): thunderclap_lite, ignite_lite, dawnburst_lite.
# Run:  Godot --headless --path . --script res://tools/effect_art_generator.gd

const OUT := "res://assets/effects/"
const PREVIEW := "res://tools/previews/effects.png"

const CORE := Color("#fffbe8")
const WARM := Color("#ffe890")
const GOLD := Color("#f0c050")
const AMBER := Color("#e08a30")
const SHADOW := Color("#2a2440")
const SHADOW_RIM := Color("#7a5ad0")
const OUTLINE := Color("#1a1420")

var index := {}
var previews: Array = []  # [name, sheet, frame size, frames]

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_reactions()
	_chain_ui()
	_signatures()
	_family_review()
	_crowned()
	_kinship()
	_kinship_combat()
	_clouds()
	_support()
	_pull_drag()
	var file := FileAccess.open(OUT + "effects.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({effects = index}, "\t") + "\n")
	_save_preview()
	_save_crowned_preview()
	_save_kinship_preview()
	quit()

# Renders `frames` frames of `size` with draw.call(img, f), saves <name>.png, records it in the index.
func _sheet(name: String, size: Vector2i, frames: int, fps: float, anchor: Vector2i, loop: bool, kind: String,
		draw: Callable, extra: Dictionary = {}) -> void:
	var sheet := Image.create_empty(size.x * frames, size.y, false, Image.FORMAT_RGBA8)
	for f in frames:
		var img := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
		draw.call(img, f)
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, size), Vector2i(f * size.x, 0))
	sheet.save_png(OUT + name + ".png")
	var entry := {file = name + ".png", frame_size = [size.x, size.y], frames = frames, fps = fps,
		anchor = [anchor.x, anchor.y], loop = loop, kind = kind}
	entry.merge(extra)
	index[name] = entry
	previews.append([name, sheet, size, frames])

# --- Primitives ---------------------------------------------------------------------------------

func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)

func _disc(img: Image, c: Vector2, r: float, col: Color, dither: bool = false, phase: int = 0) -> void:
	for y in range(maxi(0, floori(c.y - r)), mini(img.get_height(), ceili(c.y + r) + 1)):
		for x in range(maxi(0, floori(c.x - r)), mini(img.get_width(), ceili(c.x + r) + 1)):
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r and (not dither or (x + y + phase) % 2 == 0):
				img.set_pixel(x, y, col)

func _ellipse(img: Image, c: Vector2, r: Vector2, col: Color, dither: bool = false, phase: int = 0) -> void:
	for y in range(maxi(0, floori(c.y - r.y)), mini(img.get_height(), ceili(c.y + r.y) + 1)):
		for x in range(maxi(0, floori(c.x - r.x)), mini(img.get_width(), ceili(c.x + r.x) + 1)):
			if ((Vector2(x + 0.5, y + 0.5) - c) / r).length() <= 1.0 and (not dither or (x + y + phase) % 2 == 0):
				img.set_pixel(x, y, col)

# An elliptical ring `thick` px wide (radii are the outer edge); dithered when fading.
func _ring(img: Image, c: Vector2, r: Vector2, thick: float, col: Color, dither: bool = false, phase: int = 0) -> void:
	for y in range(maxi(0, floori(c.y - r.y)), mini(img.get_height(), ceili(c.y + r.y) + 1)):
		for x in range(maxi(0, floori(c.x - r.x)), mini(img.get_width(), ceili(c.x + r.x) + 1)):
			var q := ((Vector2(x + 0.5, y + 0.5) - c) / r).length()
			if q <= 1.0 and q >= 1.0 - thick / minf(r.x, r.y) and (not dither or (x + y + phase) % 2 == 0):
				img.set_pixel(x, y, col)

func _line(img: Image, a: Vector2, b: Vector2, col: Color, width: int = 1) -> void:
	var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for s in steps + 1:
		var p := a.lerp(b, s / float(steps))
		for w in width:
			for h in width:
				_px(img, roundi(p.x) + w - width / 2, roundi(p.y) + h - width / 2, col)

func _poly_line(img: Image, pts: Array, col: Color, width: int = 1) -> void:
	for i in pts.size() - 1:
		_line(img, pts[i], pts[i + 1], col, width)

# Zigzag lightning from a to b, seeded so each frame differs. Glow around a bright core.
func _bolt(img: Image, a: Vector2, b: Vector2, seed: int, core: Color, glow: Color, kinks: int = 6, jag: float = 4.0, width: int = 1) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var pts: Array = [a]
	var n := (b - a).orthogonal().normalized()
	for k in range(1, kinks):
		pts.append(a.lerp(b, float(k) / kinks) + n * rng.randf_range(-jag, jag))
	pts.append(b)
	for d: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var shifted: Array = []
		for p: Vector2 in pts:
			shifted.append(p + d * width)
		_poly_line(img, shifted, glow, width)
	_poly_line(img, pts, core, width)
	return pts

# Dithered warm glow that only lights empty pixels.
func _glow(img: Image, c: Vector2, r: Vector2, phase: int = 0, inner: Color = WARM, outer: Color = GOLD) -> void:
	for y in range(maxi(0, floori(c.y - r.y)), mini(img.get_height(), ceili(c.y + r.y) + 1)):
		for x in range(maxi(0, floori(c.x - r.x)), mini(img.get_width(), ceili(c.x + r.x) + 1)):
			if img.get_pixel(x, y).a > 0.0:
				continue
			var q := ((Vector2(x + 0.5, y + 0.5) - c) / r).length()
			if q < 0.55 and (x + y + phase) % 2 == 0:
				img.set_pixel(x, y, inner)
			elif q < 1.0 and (x + 2 * y + phase) % 4 == 0:
				img.set_pixel(x, y, outer)

# A four-point star glint.
func _star(img: Image, c: Vector2, arm: int, core: Color, edge: Color) -> void:
	for k in range(-arm, arm + 1):
		var col := core if absi(k) < arm / 2 + 1 else edge
		_px(img, int(c.x) + k, int(c.y), col)
		_px(img, int(c.x), int(c.y) + k, col)
	_px(img, int(c.x), int(c.y), Color.WHITE)

# A shard of cold shadow flying off: a small dark triangle with a violet rim.
func _shadow_shard(img: Image, p: Vector2, dir: Vector2, size: float) -> void:
	var side := dir.orthogonal() * size * 0.5
	var pts := PackedVector2Array([p + dir * size, p - side, p + side])
	for y in range(maxi(0, floori(p.y - size - 1)), mini(img.get_height(), ceili(p.y + size + 2))):
		for x in range(maxi(0, floori(p.x - size - 1)), mini(img.get_width(), ceili(p.x + size + 2))):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				img.set_pixel(x, y, SHADOW)
	_line(img, pts[0], pts[1], SHADOW_RIM)

# Radial sparks at radius r (n of them), each a short streak pointing outward.
func _sparks(img: Image, c: Vector2, n: int, r: float, length: float, col: Color, turn: float = 0.0, squash: float = 1.0) -> void:
	for k in n:
		var d := Vector2.from_angle(k * TAU / n + turn)
		var p := c + Vector2(d.x, d.y * squash) * r
		_line(img, p, p + Vector2(d.x, d.y * squash) * length, col)

# Shadow shards breaking away from `c` (frame k of the burst).
func _shadow_break(img: Image, c: Vector2, n: int, r: float, size: float, turn: float = 0.3) -> void:
	for k in n:
		var d := Vector2.from_angle(k * TAU / n + turn)
		_shadow_shard(img, c + d * r, d, size)

# --- Reactions ----------------------------------------------------------------------------------

func _reactions() -> void:
	var c := Vector2i(32, 32)
	_sheet("thunderclap", Vector2i(64, 64), 6, 20, c, false, "reaction", _thunderclap.bind(false),
		{callout = "#bfe0ff", lite = "thunderclap_lite", reaction = "Damp + Static"})
	_sheet("thunderclap_lite", Vector2i(64, 64), 6, 20, c, false, "reaction", _thunderclap.bind(true))
	_sheet("thunderclap_arc", Vector2i(64, 16), 4, 20, Vector2i(0, 8), true, "segment", _thunderclap_arc,
		{note = "Stretch or tile along x between two points; starts and ends at y = 8."})
	_sheet("ignite", Vector2i(64, 64), 6, 20, c, false, "reaction", _ignite.bind(false),
		{callout = "#ffc040", lite = "ignite_lite", reaction = "Spored + Static"})
	_sheet("ignite_lite", Vector2i(64, 64), 6, 20, c, false, "reaction", _ignite.bind(true))
	_sheet("overgrowth", Vector2i(64, 64), 7, 16, Vector2i(32, 44), false, "reaction", _overgrowth,
		{callout = "#c080ff", reaction = "Spored + Damp", then = "overgrowth_cloud"})
	_sheet("overgrowth_cloud", Vector2i(64, 64), 8, 10, c, true, "ground_loop", _overgrowth_cloud,
		{note = "One path tile (64x64), loops while the cloud lasts. Draw under nightmares."})
	_sheet("shatter", Vector2i(64, 64), 7, 18, c, false, "reaction", _shatter,
		{callout = "#bff4ff", reaction = "frozen + heavy hit or crit"})
	_sheet("drown", Vector2i(64, 64), 8, 16, c, false, "reaction", _drown,
		{callout = "#6ab0ff", reaction = "Damp + max Drowsy"})
	_sheet("pinned", Vector2i(64, 64), 6, 18, c, false, "reaction", _pinned,
		{callout = "#e8ecff", reaction = "Marked + Held or asleep"})
	_sheet("smother", Vector2i(64, 64), 8, 12, c, true, "reaction_loop", _smother,
		{callout = "#a8d060", reaction = "Held + Spored", note = "Loops while the hold lasts."})
	_sheet("lightning_rod", Vector2i(64, 128), 6, 18, Vector2i(32, 112), false, "reaction", _lightning_rod,
		{callout = "#fff27a", reaction = "Marked + Static", note = "Anchor is the impact point; the bolt falls from the top."})

func _thunderclap(img: Image, f: int, lite: bool) -> void:
	var c := Vector2(32, 32)
	var blue := Color("#bfe0ff")
	var pale := Color("#e8f4ff")
	match f:
		0:
			_disc(img, c, 3, CORE)
			_ring(img, c, Vector2(5, 5), 1, blue)
		1, 2:
			if not lite:
				_disc(img, c, 9 + f * 2, blue, true, f)
				_disc(img, c, 5 + f, pale)
				_disc(img, c, 3, CORE)
			for k in (4 if lite else 6):
				var d := Vector2.from_angle(k * TAU / (4 if lite else 6) + 0.4)
				_bolt(img, c + d * 4, c + d * (14 + f * 5), f * 13 + k, pale, blue, 4, 2.5)
			if not lite:
				_shadow_break(img, c, 5, 12 + f * 4, 3.5)
				_glow(img, c, Vector2(18 + f * 3, 18 + f * 3), f)
		3:
			_ring(img, c, Vector2(18, 18), 2, blue, true)
			_sparks(img, c, 8, 13, 3, pale, 0.2)
			if not lite:
				_shadow_break(img, c, 5, 22, 3.0)
		4:
			_ring(img, c, Vector2(22, 22), 1, blue, true, 1)
			_sparks(img, c, 6, 18, 2, blue, 0.6)
		5:
			_sparks(img, c, 4, 22, 1, blue, 0.9)

func _thunderclap_arc(img: Image, f: int) -> void:
	_bolt(img, Vector2(0, 8), Vector2(63, 8), 101 + f * 7, Color("#f4faff"), Color("#7ab8ff"), 8, 5.0)
	for k in 3:
		var x := 8 + ((f * 13 + k * 21) % 48)
		_px(img, x, 8 + (-5 if k % 2 else 5), CORE)

func _ignite(img: Image, f: int, lite: bool) -> void:
	var c := Vector2(32, 32)
	var spore := Color("#c080ff")
	match f:
		0:
			for k in (3 if lite else 6):
				var p := c + Vector2.from_angle(k * 1.9) * (3 + k % 3)
				_disc(img, p, 1.5, spore)
				_px(img, int(p.x), int(p.y), WARM)
			_glow(img, c, Vector2(8, 8))
		1:
			if not lite:
				_disc(img, c, 7, WARM, true)
			_disc(img, c, 4, CORE)
			_sparks(img, c, 8 if not lite else 4, 5, 6, GOLD)
			_glow(img, c, Vector2(14, 14))
		2:
			_disc(img, c, 2.5, CORE)
			_sparks(img, c, 8 if not lite else 4, 10, 4, WARM, 0.2)
			if not lite:
				_sparks(img, c, 8, 7, 2, AMBER, 0.6)
				_shadow_break(img, c, 4, 11, 2.5)
		3:
			_sparks(img, c, 8 if not lite else 4, 15, 3, GOLD, 0.25)
			if not lite:
				for k in 5:
					_px(img, 26 + k * 3, 22 - (k % 2) * 2, spore)
		4:
			_sparks(img, c, 6 if not lite else 3, 19, 2, AMBER, 0.3)
		5:
			for k in (6 if not lite else 3):
				var p := c + Vector2.from_angle(k * TAU / 6.0 + 0.35) * 22 + Vector2(0, 3)
				_px(img, int(p.x), int(p.y), AMBER)

func _mushroom(img: Image, base: Vector2, h: float, w: float, glow_on: bool) -> void:
	_line(img, base, base + Vector2(0, -h), Color("#f0e4d8"), 2)
	var cap_c := base + Vector2(0, -h)
	for y in range(int(cap_c.y - w * 0.7), int(cap_c.y + 1)):
		for x in range(int(cap_c.x - w), int(cap_c.x + w + 1)):
			var q := ((Vector2(x + 0.5, y + 0.5) - cap_c) / Vector2(w, w * 0.7)).length()
			if q <= 1.0:
				_px(img, x, y, OUTLINE if q > 0.8 else (Color("#e0a8ff") if y < cap_c.y - w * 0.35 else Color("#a060e0")))
	_px(img, int(cap_c.x) - 1, int(cap_c.y - w * 0.4), WARM if glow_on else Color("#fff0c8"))
	_px(img, int(cap_c.x) + 2, int(cap_c.y - w * 0.25), WARM)

func _overgrowth(img: Image, f: int) -> void:
	var base := Vector2(32, 44)
	var sizes := [[0, 0], [5, 3], [11, 6], [12, 6.5], [11, 6], [8, 4.5], [5, 3]]
	var h: float = sizes[f][0]
	var w: float = sizes[f][1]
	if f == 0:
		_line(img, base + Vector2(-8, 0), base + Vector2(8, 0), WARM)
		_line(img, base + Vector2(-3, -1), base + Vector2(3, 1), CORE)
		_glow(img, base, Vector2(12, 5))
		return
	for m: Array in [[Vector2(-8, 1), 0.7], [Vector2(0, 0), 1.0], [Vector2(8, 1), 0.8]]:
		var off: Vector2 = m[0]
		var s: float = m[1]
		_mushroom(img, base + off, h * s, maxf(w * s, 1.5), f == 2 or f == 3)
	if f == 2 or f == 3:
		_shadow_break(img, base + Vector2(0, -8), 4, 14 + f * 2, 3.0)
		_glow(img, base + Vector2(0, -10), Vector2(20, 14), f)
	for k in 5:
		var t := float(f) / 6.0
		_px(img, 18 + k * 7, int(40 - t * 30 - (k % 3) * 3), Color("#c080ff") if k % 2 else WARM)

func _overgrowth_cloud(img: Image, f: int) -> void:
	var c := Vector2(32, 40)
	_ellipse(img, c, Vector2(28, 12), Color(0.55, 0.35, 0.8, 0.45), true, f)
	_ellipse(img, c, Vector2(18, 7), Color(0.65, 0.45, 0.9, 0.5), true, f + 1)
	for k in 7:
		var t := fmod(float(f) / 8.0 + k / 7.0, 1.0)
		var x := 8 + k * 8 + roundi(sin(t * TAU) * 2)
		var y := roundi(46 - t * 22)
		_px(img, x, y, WARM if k % 3 == 0 else Color("#e0a8ff"))
		if k % 3 == 0:
			_px(img, x + 1, y, GOLD)

func _shatter(img: Image, f: int) -> void:
	var c := Vector2(32, 32)
	var ice := Color("#bff4ff")
	var ice_mid := Color("#7ac8f0")
	if f <= 1:
		var pts := PackedVector2Array([c + Vector2(0, -12), c + Vector2(10, -2), c + Vector2(6, 11), c + Vector2(-6, 11), c + Vector2(-10, -2)])
		for y in range(16, 48):
			for x in range(16, 48):
				if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
					img.set_pixel(x, y, ice if x < 32 else ice_mid)
		for k in 5:
			_line(img, pts[k], pts[(k + 1) % 5], OUTLINE)
		var cracks := [[c, c + Vector2(-7, -6)], [c, c + Vector2(6, 8)]]
		if f == 1:
			cracks += [[c, c + Vector2(8, -3)], [c, c + Vector2(-5, 9)], [c + Vector2(-7, -6), c + Vector2(-3, -11)]]
		for cr: Array in cracks:
			_line(img, cr[0], cr[1], Color.WHITE)
		return
	var k := f - 2
	if k <= 1:
		_disc(img, c, 6 - k * 2, CORE)
		_glow(img, c, Vector2(16, 16), k)
	for i in 8:
		var d := Vector2.from_angle(i * TAU / 8.0 + 0.2)
		var p := c + d * (6 + k * 6) + Vector2(0, k * k * 0.8)
		var tip := p + d * (4 - k * 0.5)
		var side := d.orthogonal() * 2.0
		_line(img, p - side, tip, ice)
		_line(img, p + side, tip, ice_mid)
		_line(img, p - side, p + side, OUTLINE)
	if k >= 3:
		for i in 6:
			_px(img, 14 + i * 7, 44 + (i % 2) * 3, Color.WHITE if (i + f) % 2 == 0 else ice)

func _drown(img: Image, f: int) -> void:
	var c := Vector2(32, 36)
	var deep := Color("#1a3a6a")
	var water := Color("#2a6aa8")
	var light := Color("#8ad0f8")
	var strength: float = [0.6, 1.0, 1.0, 0.9, 0.7, 0.5, 0.3, 0.15][f]
	for arm in 3:
		var pts: Array = []
		for s in 14:
			var t := s / 13.0
			var a := arm * TAU / 3.0 + f * 0.7 + t * 4.0
			pts.append(c + Vector2(cos(a), sin(a) * 0.5) * (4 + t * 18 * strength))
		_poly_line(img, pts, water if arm % 2 else deep, 2)
		_poly_line(img, pts.slice(8), light)
	_ellipse(img, c, Vector2(4, 2), OUTLINE)
	for k in 5:
		var t := fmod(f / 8.0 + k / 5.0, 1.0)
		var p := Vector2(22 + k * 5, 34 - t * 26)
		_ring(img, p, Vector2(1.8, 1.8), 1, light)
		_px(img, int(p.x) - 1, int(p.y) - 1, CORE)
	if f == 1 or f == 2:
		_glow(img, c + Vector2(0, -6), Vector2(16, 10), f, Color("#d8f4ff"), Color("#8ad0f8"))

func _pinned(img: Image, f: int) -> void:
	var c := Vector2(32, 32)
	var silver := Color("#e8ecff")
	var steel := Color("#a8b0d8")
	if f == 0:
		_line(img, c + Vector2(-14, -10), c + Vector2(14, 10), silver)
		return
	if f <= 3:
		var fade := f == 3
		for w in (4 if f == 1 else (3 if f < 3 else 2)):
			var pts: Array = []
			for s in 17:
				var a := lerpf(-2.3, 0.7, s / 16.0)
				pts.append(c + Vector2(cos(a), sin(a)) * (15 - w))
			for i in pts.size() - 1:
				if not fade or i % 2 == 0:
					_line(img, pts[i], pts[i + 1], CORE if w == 1 else (silver if w == 0 else steel))
		if f == 1:
			_star(img, c + Vector2(-13, -6), 5, Color.WHITE, silver)
			_shadow_break(img, c, 4, 18, 3.0, 0.8)
		if f == 2:
			_star(img, c + Vector2(10, -11), 4, Color.WHITE, silver)
	else:
		for k in 3:
			_star(img, c + Vector2(-10 + k * 10, -12 + k * 6 + (f - 4) * 3), 2, silver, steel)

func _smother(img: Image, f: int) -> void:
	var c := Vector2(32, 34)
	var squeeze := 1.0 - 0.12 * (0.5 + 0.5 * sin(TAU * f / 8.0))
	var root := Color("#8a6040")
	var root_light := Color("#c89868")
	var moss := Color("#6ab04a")
	for strand in 3:
		var pts: Array = []
		for s in 20:
			var t := s / 19.0
			var a := strand * TAU / 3.0 + t * TAU * 0.9 + f * 0.15
			pts.append(c + Vector2(cos(a) * 14, sin(a) * 9) * squeeze + Vector2(0, (t - 0.5) * 6))
		_poly_line(img, pts, OUTLINE, 3)
		_poly_line(img, pts, root, 2)
		_poly_line(img, pts.slice(0, 10), root_light)
		_px(img, int(pts[10].x), int(pts[10].y) - 1, moss)
	for k in 3:
		if (f + k * 3) % 8 < 3:
			var p := c + Vector2.from_angle(k * 2.1 + 0.5) * Vector2(15, 9) * squeeze
			var t := ((f + k * 3) % 8) / 3.0
			_disc(img, p + Vector2(0, -t * 5), 3 + t * 1.5, Color("#c080ff"), t > 0.6, f)
			_disc(img, p + Vector2(0, -t * 5), 1.5, Color("#e0a8ff"))
			_px(img, int(p.x), int(p.y - t * 5), WARM)

func _lightning_rod(img: Image, f: int) -> void:
	var hit := Vector2(32, 112)
	var pale := Color("#fffbd8")
	var yellow := Color("#fff27a")
	match f:
		0:
			_star(img, Vector2(32, 6), 3, Color.WHITE, yellow)
			_ring(img, hit, Vector2(8, 3), 1, yellow, true)
		1, 2:
			_bolt(img, Vector2(32, 2), hit, 77 + f, pale, GOLD, 9, 6.0, 1 if f == 2 else 2)
			if f == 1:
				_disc(img, hit, 7, CORE)
				_ellipse(img, hit, Vector2(14, 6), WARM, true)
			else:
				_ring(img, hit, Vector2(12, 5), 2, yellow)
				_shadow_break(img, hit + Vector2(0, -3), 5, 11, 3.0)
			_glow(img, hit + Vector2(0, -4), Vector2(18, 10), f)
		3:
			_ring(img, hit, Vector2(18, 7), 1, yellow, true)
			_sparks(img, hit + Vector2(0, -4), 6, 8, 3, WARM, 0.0, 0.5)
		4:
			_ring(img, hit, Vector2(22, 8), 1, GOLD, true, 1)
		5:
			_sparks(img, hit + Vector2(0, -3), 4, 14, 1, GOLD, 0.4, 0.5)

# --- Chain and hit-feedback UI --------------------------------------------------------------------

const DIGITS := "x0123456789"
const DIGIT_FONT := {
	"x": ["....", "#..#", ".##.", ".##.", "#..#", "....", "...."],
	"0": [".##.", "#..#", "#.##", "##.#", "#..#", "#..#", ".##."],
	"1": [".#..", "##..", ".#..", ".#..", ".#..", ".#..", "###."],
	"2": [".##.", "#..#", "...#", "..#.", ".#..", "#...", "####"],
	"3": ["###.", "...#", "...#", ".##.", "...#", "...#", "###."],
	"4": ["#..#", "#..#", "#..#", "####", "...#", "...#", "...#"],
	"5": ["####", "#...", "###.", "...#", "...#", "#..#", ".##."],
	"6": [".##.", "#...", "###.", "#..#", "#..#", "#..#", ".##."],
	"7": ["####", "...#", "..#.", "..#.", ".#..", ".#..", ".#.."],
	"8": [".##.", "#..#", "#..#", ".##.", "#..#", "#..#", ".##."],
	"9": [".##.", "#..#", "#..#", ".###", "...#", "..#.", ".#.."],
}

func _chain_ui() -> void:
	_sheet("chain_badge", Vector2i(48, 32), 5, 20, Vector2i(24, 16), false, "ui", _chain_badge,
		{note = "Pop-in; hold the last frame. Draw chain_digits centred on it (x then the number)."})
	_sheet("chain_digits", Vector2i(8, 12), DIGITS.length(), 0, Vector2i(0, 0), false, "font", _digit,
		{glyphs = DIGITS, note = "Bitmap font: frame i is glyph i of `glyphs` ('x' = the multiply sign). 7 px advance."})
	_sheet("dawnburst", Vector2i(256, 256), 8, 16, Vector2i(128, 128), false, "screen", _dawnburst.bind(false),
		{lite = "dawnburst_lite", note = "x10 chain. Screen-level: draw centred on the reaction, above the map."})
	_sheet("dawnburst_lite", Vector2i(256, 256), 8, 16, Vector2i(128, 128), false, "screen", _dawnburst.bind(true))
	_sheet("surge", Vector2i(128, 128), 1, 0, Vector2i(64, 64), false, "overlay", _surge,
		{note = "x5 chain: stretch over the whole screen and fade alpha 0 -> 0.8 -> 0 over ~0.5 s. Smooth, not pixel art."})
	_sheet("light_thread", Vector2i(32, 8), 4, 16, Vector2i(0, 4), true, "segment", _light_thread,
		{note = "Stretch or tile along x from a Warden to the reaction; starts and ends at y = 4."})
	_sheet("crit_flare", Vector2i(48, 48), 5, 20, Vector2i(24, 24), false, "hit", _crit_flare)
	_sheet("chain_link", Vector2i(16, 16), 4, 8, Vector2i(8, 8), true, "ui", _chain_link.bind(false),
		{bright = "chain_link_bright", note = "Icon beside the chain badge's \"Chain N\" text. Loops a glint; use chain_link_bright from Chain 5."})
	_sheet("chain_link_bright", Vector2i(16, 16), 4, 10, Vector2i(8, 8), true, "ui", _chain_link.bind(true))
	var colours := {"damp": "#6ab0ff", "drowsy": "#c8b0f0", "spored": "#c080ff", "marked": "#e8ecff", "static": "#fff27a", "held": "#9a8a40"}
	_sheet("status_flash", Vector2i(32, 32), 5, 20, Vector2i(16, 16), false, "hit", _status_flash.bind(colours.values()),
		{rows = colours.keys(), colours = colours, note = "One row per status (top to bottom in `rows`); each sheet row is 32 px tall."})
	_stack_rows("status_flash", colours.size())

func _chain_badge(img: Image, f: int) -> void:
	var scale: float = [0.55, 0.95, 1.15, 1.02, 1.0][f]
	var c := Vector2(24, 16)
	var r := Vector2(20, 12) * scale
	_ellipse(img, c, r + Vector2(1, 1), OUTLINE)
	_ellipse(img, c, r, Color("#c88a30"))
	_ellipse(img, c + Vector2(0, -1), r - Vector2(2, 2), GOLD)
	_ellipse(img, c + Vector2(-2, -3), (r - Vector2(2, 2)) * Vector2(0.7, 0.45), WARM)
	_ellipse(img, c + Vector2(0, 1), r * Vector2(0.62, 0.55), Color("#3a2410"))  # dark window for the digits
	for side: int in [-1, 1]:
		var leaf := c + Vector2(side * (r.x + 1), 0)
		_line(img, leaf, leaf + Vector2(side * 3, -3), Color("#6ab04a"))
		_line(img, leaf, leaf + Vector2(side * 3, 3), Color("#9ad86a"))
	if f == 2:
		_glow(img, c, r + Vector2(6, 6))
		_star(img, c + Vector2(r.x - 3, -r.y + 2), 3, Color.WHITE, WARM)

func _digit(img: Image, f: int) -> void:
	var rows: Array = DIGIT_FONT[DIGITS[f]]
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] == "#":
				for d: Vector2i in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
					if img.get_pixel(clampi(x + 2 + d.x, 0, 7), clampi(y + 2 + d.y, 0, 11)).a == 0.0:
						_px(img, x + 2 + d.x, y + 2 + d.y, OUTLINE)
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] == "#":
				_px(img, x + 2, y + 2, CORE if y < 3 else WARM)

func _dawnburst(img: Image, f: int, lite: bool) -> void:
	var c := Vector2(128, 128)
	var t := f / 7.0
	var rays := 12 if lite else 20
	var reach := 40.0 + t * 90.0
	for k in rays:
		var d := Vector2.from_angle(k * TAU / rays + t * 0.3)
		var ray := reach * (1.0 if k % 2 == 0 else 0.7)
		var base_w := (6.0 if k % 2 == 0 else 3.5) * (1.0 - t * 0.6) if not lite else 1.5
		for s in int(ray):
			var along := s / ray
			if f >= 5 and (s + f) % 2 != 0:
				continue  # the rays thin out as the flare fades
			var p := c + d * (10 + s)
			var col := CORE if along < 0.3 else (WARM if along < 0.7 else GOLD)
			var half := maxf(base_w * (1.0 - along), 0.5)  # wedge: wide at the centre, tapering out
			for w in range(-int(half), int(half) + 1):
				_px(img, roundi(p.x + d.orthogonal().x * w), roundi(p.y + d.orthogonal().y * w), col)
	if not lite and f <= 3:
		_disc(img, c, 34 - f * 6, WARM, true, f)
		_disc(img, c, 20 - f * 4, CORE)
		_shadow_break(img, c, 10, 30 + f * 22, 7.0)
	elif lite:
		_disc(img, c, 8, WARM)
	_ring(img, c, Vector2(30 + t * 90, 30 + t * 90), 3 if f < 5 else 2, WARM, f >= 4, f)

func _surge(img: Image, _f: int) -> void:
	var c := Vector2(64, 64)
	for y in 128:
		for x in 128:
			var q := clampf((Vector2(x + 0.5, y + 0.5).distance_to(c) / 90.0), 0.0, 1.0)
			var a := smoothstep(0.35, 1.0, q) * 0.85
			img.set_pixel(x, y, Color(1.0, 0.82, 0.45, a))

func _light_thread(img: Image, f: int) -> void:
	for x in 32:
		_px(img, x, 4, WARM if (x + f * 2) % 8 < 6 else GOLD)
		if (x + f * 2) % 4 == 0:
			_px(img, x, 3, Color(GOLD, 0.6))
			_px(img, x, 5, Color(GOLD, 0.6))
	var dot := (f * 8) % 32
	_px(img, dot, 4, CORE)
	_px(img, dot, 3, WARM)
	_px(img, dot, 5, WARM)

# Two interlocked warm-gold links on the diagonal; a glint runs round them.
func _chain_link(img: Image, f: int, bright: bool) -> void:
	var centres := [Vector2(5.6, 5.6), Vector2(10.4, 10.4)]
	var half := 2.3  # half the straight part of each capsule-shaped link
	var ro := 3.9
	var ri := 1.3
	var light := Color("#fff4c0") if bright else Color("#ffe070")
	var mid := Color("#ffd860") if bright else Color("#e8b040")
	var dark := Color("#c8902a") if bright else Color("#a86a1a")
	var edge := Color("#5a3200")
	# Which link a pixel belongs to (link 1 on top above the diagonal, link 2 below: interlocked).
	# Returns the normal-ish offset from the link's centre line, or INF when off the link. `solid`
	# ignores the hole (for finding the outer edge).
	var on_link := func(p: Vector2, k: int, solid: bool = false) -> Vector2:
		var d := (p - (centres[k] as Vector2)).rotated(-PI / 4.0)
		var near := Vector2(clampf(d.x, -half, half), 0.0)
		var r := d.distance_to(near)
		if r <= ro and (solid or r > ri):
			return (d - near) / ro
		return Vector2(INF, INF)
	var owner := func(x: int, y: int) -> int:
		var p := Vector2(x + 0.5, y + 0.5)
		var a: bool = (on_link.call(p, 0) as Vector2).x != INF
		var b: bool = (on_link.call(p, 1) as Vector2).x != INF
		if a and b:
			return 0 if x > y else 1
		return 0 if a else (1 if b else -1)
	for y in 16:
		for x in 16:
			var k: int = owner.call(x, y)
			if k < 0:
				continue
			# Outline only against the outside and the other link, never into the hole.
			var border := false
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := x + d.x
				var ny := y + d.y
				if nx < 0 or ny < 0 or nx >= 16 or ny >= 16:
					border = true
					break
				var other: int = owner.call(nx, ny)
				var in_hole: bool = other < 0 and (on_link.call(Vector2(nx + 0.5, ny + 0.5), k, true) as Vector2).x != INF
				if other != k and not in_hole:
					border = true
					break
			if border:
				img.set_pixel(x, y, edge)
				continue
			var n: Vector2 = on_link.call(Vector2(x + 0.5, y + 0.5), k)
			var lit := -n.rotated(PI / 4.0).dot(Vector2(0.7, 0.7))
			img.set_pixel(x, y, light if lit > 0.25 else (dark if lit < -0.3 else mid))
	# The glint travels from one link to the other.
	var glints := [Vector2i(3, 5), Vector2i(6, 3), Vector2i(10, 8), Vector2i(12, 11)]
	var g: Vector2i = glints[f]
	if img.get_pixelv(g) != edge and img.get_pixelv(g).a > 0.0:
		img.set_pixelv(g, Color.WHITE)
	if bright:
		for s: Vector2i in [Vector2i(14, 2), Vector2i(1, 13)]:
			if (f + s.x) % 2 == 0:
				_px(img, s.x, s.y, CORE)
				_px(img, s.x - 1, s.y, WARM)
				_px(img, s.x, s.y + 1, WARM)

func _crit_flare(img: Image, f: int) -> void:
	var c := Vector2(24, 24)
	var arm: int = [6, 14, 18, 12, 6][f]
	if f <= 2:
		_glow(img, c, Vector2(arm + 4, arm + 4), f)
	for k in range(-arm, arm + 1):
		var col := CORE if absi(k) < arm * 0.4 else (WARM if absi(k) < arm * 0.75 else GOLD)
		_px(img, 24 + k, 24, col)
		_px(img, 24, 24 + k, col)
		if absi(k) < arm * 0.25:
			_px(img, 24 + k, 23, col)
			_px(img, 24 + k, 25, col)
			_px(img, 23, 24 + k, col)
			_px(img, 25, 24 + k, col)
	var diag := arm / 2
	for k in range(-diag, diag + 1):
		if k != 0:
			_px(img, 24 + k, 24 + k, WARM)
			_px(img, 24 + k, 24 - k, WARM)
	_disc(img, c, 2 if f < 3 else 1, Color.WHITE)

func _status_flash(img: Image, f: int, colours: Array) -> void:
	# Drawn as one wide strip here; _stack_rows turns it into one row per status.
	pass

# status_flash: one row per status colour (5 frames each), built from _flash_row.
func _stack_rows(name: String, rows: int) -> void:
	var colours: Array = index[name].colours.values()
	var sheet := Image.create_empty(32 * 5, 32 * rows, false, Image.FORMAT_RGBA8)
	for r in rows:
		for f in 5:
			var img := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
			_flash_row(img, f, Color(colours[r]))
			sheet.blit_rect(img, Rect2i(0, 0, 32, 32), Vector2i(f * 32, r * 32))
	sheet.save_png(OUT + name + ".png")
	for p in previews:
		if p[0] == name:
			p[1] = sheet

func _flash_row(img: Image, f: int, col: Color) -> void:
	var c := Vector2(16, 16)
	var r: float = [4.0, 8.0, 11.0, 13.0, 14.5][f]
	if f <= 1:
		_disc(img, c, r - 2, Color(col, 0.9), true, f)
		_disc(img, c, 2, Color.WHITE)
	_ring(img, c, Vector2(r, r), 2 if f < 3 else 1, col.lightened(0.2) if f < 2 else col, f >= 3, f)
	if f == 1:
		_ring(img, c, Vector2(r + 2, r + 2), 1, Color.WHITE, true)

# --- Final-form signatures ----------------------------------------------------------------------

func _signatures() -> void:
	_sheet("thunderhead_strike", Vector2i(96, 160), 7, 18, Vector2i(48, 148), false, "signature", _thunderhead_strike,
		{note = "Thunderhead's every 5th strike. Anchor = ground impact; the bolt comes from the sky above."})
	_sheet("monsoon_sweep", Vector2i(64, 64), 8, 14, Vector2i(32, 32), true, "overlay_loop", _monsoon_sweep,
		{note = "Tiles in x and y. Fill Monsoon's range and slide it across while it rains."})
	_sheet("moonstone_beam", Vector2i(32, 128), 6, 16, Vector2i(16, 120), false, "signature", _moonstone_beam,
		{note = "Moonstone's first shot on each nightmare: a moonbeam from above. Anchor = where it lands."})
	_sheet("puffball_bloom", Vector2i(128, 128), 8, 16, Vector2i(64, 64), false, "signature", _puffball_bloom,
		{note = "Puffball's pop at 10+ Spored stacks."})
	_sheet("long_way_home_drag", Vector2i(64, 24), 6, 14, Vector2i(0, 12), false, "segment", _long_way_home_drag,
		{note = "Roots dragging a nightmare back: stretch along x from where it was to where it lands (x = 0 end)."})

func _thunderhead_strike(img: Image, f: int) -> void:
	var hit := Vector2(48, 148)
	var pale := Color("#fffbd8")
	var yellow := Color("#fff27a")
	if f == 0:
		_ellipse(img, Vector2(48, 6), Vector2(30, 6), Color("#6a6a90"), true)
		_star(img, Vector2(48, 10), 4, Color.WHITE, yellow)
		_ring(img, hit, Vector2(14, 5), 1, yellow, true)
		return
	if f <= 3:
		_ellipse(img, Vector2(48, 6), Vector2(34, 7), WARM if f == 1 else Color("#9a9ac0"), true, f)
		var main := _bolt(img, Vector2(48, 4), hit, 300 + f, pale, GOLD, 12, 9.0, 2 if f < 3 else 1)
		for k in 2:
			var from: Vector2 = main[4 + k * 3]
			_bolt(img, from, from + Vector2((24 if k == 0 else -22), 30), 400 + f * 3 + k, pale, GOLD, 4, 4.0)
		if f == 1:
			_disc(img, hit, 10, CORE)
			_ellipse(img, hit, Vector2(26, 9), WARM, true)
		else:
			_ring(img, hit, Vector2(14 + f * 5, 5 + f * 2), 2, yellow)
			_shadow_break(img, hit + Vector2(0, -5), 7, 12 + f * 5, 4.0)
		_glow(img, hit + Vector2(0, -6), Vector2(30, 14), f)
	else:
		var k := f - 4
		_ring(img, hit, Vector2(30 + k * 6, 11 + k * 2), 1, GOLD, true, f)
		_sparks(img, hit + Vector2(0, -4), 8, 12 + k * 6, 3, WARM, 0.2, 0.45)

func _monsoon_sweep(img: Image, f: int) -> void:
	var rain := Color("#bfe0ff")
	var lit := Color("#fff0c0")
	for k in 16:
		var x0 := (k * 23 + 7) % 64
		var y0 := (k * 37 + f * 8) % 64
		for s in 4:
			var x := (x0 - s + 64) % 64
			var y := (y0 + s * 2) % 64
			img.set_pixel(x, y, lit if (k % 4 == 0 and s == 0) else Color(rain, 0.85))
	for k in 2:
		var p := Vector2((k * 29 + f * 11) % 64, (k * 41 + 20) % 64)
		if (f + k) % 3 == 0:
			_ring(img, p, Vector2(3, 1.5), 1, Color(rain, 0.8))

func _moonstone_beam(img: Image, f: int) -> void:
	var land := Vector2(16, 120)
	var silver := Color("#dfeeff")
	var pale := Color("#f4f8ff")
	var width: float = [2.0, 7.0, 6.0, 4.0, 2.0, 1.0][f]
	var top: float = [100.0, 0.0, 0.0, 0.0, 40.0, 80.0][f]
	for y in range(int(top), 121):
		for x in 32:
			var d := absf(x + 0.5 - 16)
			if d <= width:
				img.set_pixel(x, y, CORE if d < width * 0.35 else (pale if d < width * 0.7 else silver))
	if f >= 1 and f <= 3:
		var moon_r := 6.0 - (f - 1)
		_disc(img, land, moon_r + 2, silver, true, f)
		_disc(img, land, moon_r, pale)
		_disc(img, land + Vector2(2, -1), moon_r - 1, Color(0, 0, 0, 0))
		_star(img, land + Vector2(-8, -6), 3, Color.WHITE, silver)
	if f == 1:
		_glow(img, land, Vector2(15, 8), 0, pale, silver)

func _puffball_bloom(img: Image, f: int) -> void:
	var c := Vector2(64, 64)
	var cream := Color("#f6eedc")
	var puff_r: float = [10.0, 22.0, 32.0, 38.0, 42.0, 44.0, 45.0, 46.0][f]
	if f <= 5:
		for k in 7:
			var d := Vector2.from_angle(k * TAU / 7.0 + 0.2)
			_disc(img, c + d * puff_r * 0.55, puff_r * 0.42, cream if f < 3 else Color(cream, 0.7), f >= 3, f + k)
		_disc(img, c, puff_r * 0.5, WARM if f <= 2 else Color(WARM, 0.6), f >= 2, f)
	if f >= 1 and f <= 4:
		for k in 12:
			var d := Vector2.from_angle(k * TAU / 12.0 + f * 0.1)
			var p0 := c + d * (puff_r * 0.6)
			_line(img, p0, p0 + d * (8 + f * 4), CORE if k % 2 == 0 else GOLD)
	if f == 1 or f == 2:
		_disc(img, c, 12 - f * 3, CORE)
		_shadow_break(img, c, 8, puff_r + 6, 5.0)
	for k in 10:
		var t := f / 7.0
		var p := c + Vector2.from_angle(k * 0.63) * (20 + t * 40) + Vector2(0, -t * 10)
		_px(img, int(p.x), int(p.y), Color("#c080ff") if k % 3 else WARM)

func _long_way_home_drag(img: Image, f: int) -> void:
	var root := Color("#8a6040")
	var root_light := Color("#c89868")
	for strand in 3:
		var y0 := 8 + strand * 4
		var pts: Array = []
		for x in range(0, 64, 4):
			pts.append(Vector2(x, y0 + sin((x + f * 6 + strand * 9) * 0.2) * 2))
		_poly_line(img, pts, OUTLINE, 3)
		_poly_line(img, pts, root, 2)
		_poly_line(img, pts.slice(0, 6), root_light)
	# Warm motion streaks along the pull, brightest near the head (x = 0).
	for k in 5:
		var x := (k * 13 + f * 9) % 64
		_line(img, Vector2(x, 3 + k % 2 * 17), Vector2(x + 6, 3 + k % 2 * 17), WARM if x < 32 else GOLD)
	for k in 2:
		var p := Vector2((56 - f * 8 + k * 20) % 64, 20)
		_disc(img, p, 2.0, Color(0.85, 0.8, 0.7, 0.7), true, f)
	_glow(img, Vector2(4, 12), Vector2(8, 8), f)

# --- Family review (Bellflower, Cairn, Hummingbird) -----------------------------------------------

const LILAC := Color("#c8a8f0")
const LILAC_PALE := Color("#e8dcff")

func _family_review() -> void:
	_sheet("caught", Vector2i(64, 64), 8, 8, Vector2i(32, 32), true, "status_loop", _caught,
		{note = "Dreamcatcher: loops over a Caught (sleeping, +damage) nightmare. Draw above it."})
	_sheet("dreamlight_shard", Vector2i(16, 16), 8, 10, Vector2i(8, 12), true, "pickup",
		_dreamlight_shard, {note = "Great Dreamcatcher: dropped by a Caught nightmare when dispelled. Loops until collected."})
	_sheet("echo", Vector2i(64, 64), 6, 16, Vector2i(32, 32), false, "overlay",
		_echo, {note = "Echo Hollow: play with the repeated Reaction (which can also be drawn at ~60% alpha, lilac-tinted)."})
	_sheet("rubble", Vector2i(64, 64), 1, 0, Vector2i(32, 32), true, "ground",
		_rubble, {note = "Rockslide: one path tile of slowing rubble. Draw under nightmares. Loops: Fx.play(&\"rubble\", tile, world, 1.0, true, 3.0) holds it 3 s and fades it out."})
	_sheet("landing_dust", Vector2i(64, 64), 6, 18, Vector2i(32, 40), false, "hit", _landing_dust,
		{note = "Cairn / Rockslide: where the lobbed stone lands. Anchor = impact point."})
	_sheet("peck_spark", Vector2i(16, 16), 4, 24, Vector2i(8, 8), false, "hit", _peck_spark,
		{note = "Hummingbird: one per peck (6-8 a second), so it's tiny and quick."})
	_sheet("lob_shadow", Vector2i(16, 8), 1, 0, Vector2i(8, 4), true, "shadow", _lob_shadow,
		{note = "Under a lobbed stone, on the ground below it; scale it down as the stone rises."})

func _caught(img: Image, f: int) -> void:
	var c := Vector2(32, 30)
	var pulse := 0.5 + 0.5 * sin(TAU * f / 8.0)
	var alpha := 0.55 + 0.25 * pulse
	_ring(img, c, Vector2(13, 13), 1, Color(LILAC, alpha))
	_ring(img, c, Vector2(7, 7), 1, Color(LILAC_PALE, alpha * 0.8), true, f)
	for k in 6:
		var a := k * TAU / 6.0 + f * TAU / 48.0  # the web turns slowly
		var d := Vector2.from_angle(a)
		_line(img, c + d * 2.0, c + d * 12.0, Color(LILAC_PALE, alpha * 0.7))
	_disc(img, c, 1.5, Color(WARM, 0.9))
	for k in 3:
		var top := c + Vector2(-6 + k * 6, 13)
		_line(img, top, top + Vector2(0, 4 + (k % 2) * 2), Color(LILAC, alpha * 0.8))
		_px(img, int(top.x), int(top.y) + 5 + (k % 2) * 2, Color(GOLD, alpha))

func _dreamlight_shard(img: Image, f: int) -> void:
	var bob := roundi(sin(TAU * f / 8.0) * 1.5)
	var c := Vector2(8, 7 + bob)
	var pts := PackedVector2Array([c + Vector2(0, -5), c + Vector2(3, 0), c + Vector2(0, 5), c + Vector2(-3, 0)])
	for y in 16:
		for x in 16:
			var p := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(p, pts):
				img.set_pixel(x, y, CORE if p.x < c.x else (WARM if p.y < c.y else LILAC))
	for i in 4:
		_line(img, pts[i], pts[(i + 1) % 4], Color("#6a4a9a"))
	if f % 4 == 0:
		_star(img, c + Vector2(4, -4), 1, Color.WHITE, WARM)
	_px(img, 8, 14, Color(0.1, 0.08, 0.14, 0.5))  # a little shadow below
	_px(img, 7, 14, Color(0.1, 0.08, 0.14, 0.35))
	_px(img, 9, 14, Color(0.1, 0.08, 0.14, 0.35))

func _echo(img: Image, f: int) -> void:
	var c := Vector2(32, 32)
	var r := 8.0 + f * 4.0
	_ring(img, c, Vector2(r, r * 0.8), 1, Color(LILAC_PALE, 0.9 - f * 0.12), f >= 3, f)
	if f >= 1:
		_ring(img, c, Vector2(r - 5, (r - 5) * 0.8), 1, Color(LILAC, 0.8 - f * 0.1), true, f + 1)
	if f <= 2:
		for k in 4:
			var d := Vector2.from_angle(k * TAU / 4.0 + 0.8)
			_px(img, roundi(c.x + d.x * (r + 2)), roundi(c.y + d.y * (r + 2) * 0.8), WARM)

func _rubble(img: Image, _f: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_ellipse(img, Vector2(32, 36), Vector2(26, 12), Color(0.42, 0.4, 0.5, 0.35), true)
	for k in 14:
		var p := Vector2(rng.randf_range(10, 54), rng.randf_range(28, 46))
		var r := rng.randf_range(1.5, 3.5)
		_ellipse(img, p, Vector2(r, r * 0.7), OUTLINE)
		_ellipse(img, p + Vector2(0, -0.5), Vector2(r - 0.8, r * 0.7 - 0.6), Color("#979dc2"))
		_px(img, int(p.x) - 1, int(p.y) - 1, Color("#c4c9e2"))

func _landing_dust(img: Image, f: int) -> void:
	var c := Vector2(32, 40)
	var t := f / 5.0
	if f == 0:
		_disc(img, c, 5, CORE)
		_glow(img, c, Vector2(12, 7))
	for k in 7:
		var d := Vector2.from_angle(PI + k * PI / 6.0)
		var p := c + Vector2(d.x * (6 + t * 18), d.y * (3 + t * 12) - t * 2)
		_disc(img, p, 3.2 - t * 2.2, Color(0.85, 0.82, 0.78, 0.85 - t * 0.6), f >= 3, f + k)
	if f <= 2:
		_ring(img, c, Vector2(10 + f * 6, 4 + f * 2), 1, Color("#d8d4e4"), f == 2)
		for k in 4:
			_px(img, int(c.x) - 14 + k * 9, int(c.y) - 6 - f * 3, Color("#979dc2"))

func _peck_spark(img: Image, f: int) -> void:
	var c := Vector2(8, 8)
	var arm: int = [2, 4, 3, 1][f]
	_star(img, c, arm, CORE if f < 2 else WARM, GOLD)
	if f == 1:
		for d: Vector2i in [Vector2i(-3, -3), Vector2i(3, -3), Vector2i(-3, 3), Vector2i(3, 3)]:
			_px(img, 8 + d.x, 8 + d.y, WARM)

func _lob_shadow(img: Image, _f: int) -> void:
	_ellipse(img, Vector2(8, 4), Vector2(6.5, 2.8), Color(0.05, 0.04, 0.08, 0.35))
	_ellipse(img, Vector2(8, 4), Vector2(4, 1.8), Color(0.05, 0.04, 0.08, 0.5))
# --- Crowned Reactions (tower_design.md "Crowned Reactions: three families at once") ---------------
# The gold impact tier: each is its Reaction drawn again inside a bigger frame, gold-edged, with a
# wider gold burst, dark-violet shadow shards flung further, and its own twist. Ground loops
# (still_pool, nightbloom_cloud, fairy_circle_ring) are one path tile. Plus the delivery-rule
# overlays and the crowned UI pieces (crown mark, callout frame, card accent, Codex silhouette).

const CROWN_GOLD := Color("#ffd860")
const CROWN_DEEP := Color("#b8801c")
const VIOLET := Color("#b070f0")
const VIOLET_PALE := Color("#e0c0ff")
const RAINBOW := ["#ff8a8a", "#ffc070", "#fff27a", "#9aec8a", "#8ad8ff", "#c8a0ff"]

var crowned_from := 0

func _crowned() -> void:
	crowned_from = previews.size()
	var s := Vector2i(96, 96)
	var c := Vector2i(48, 48)
	_sheet("crowned_tempest", s, 8, 18, c, false, "crowned", _crowned_tempest.bind(false),
		_crown_info("#bfe0ff", "Thunderclap + Spored", {lite = "crowned_tempest_lite"}))
	_sheet("crowned_tempest_lite", s, 8, 18, c, false, "crowned", _crowned_tempest.bind(true))
	_sheet("crowned_still_pool", s, 8, 14, c, false, "crowned", _crowned_still_pool,
		_crown_info("#6ab0ff", "Drown + Held", {then = "still_pool"}))
	_sheet("still_pool", Vector2i(64, 64), 8, 8, Vector2i(32, 32), true, "ground_loop", _still_pool,
		{note = "One path tile, loops for the pool's 5 s. Draw under nightmares."})
	_sheet("crowned_fever_dream", s, 8, 14, c, false, "crowned", _crowned_fever_dream,
		_crown_info("#a8d060", "Smother ends + max Drowsy"))
	_sheet("crowned_starfall", Vector2i(64, 160), 7, 16, Vector2i(32, 150), false, "crowned", _crowned_starfall.bind(false),
		_crown_info("#fff27a", "Pinned + Static", {lite = "crowned_starfall_lite", note = "Anchor = the impact point; the column falls from the top."}))
	_sheet("crowned_starfall_lite", Vector2i(64, 160), 7, 16, Vector2i(32, 150), false, "crowned", _crowned_starfall.bind(true))
	_sheet("crowned_avalanche", Vector2i(128, 96), 8, 16, Vector2i(64, 64), false, "crowned", _crowned_avalanche,
		_crown_info("#bff4ff", "Shatter from a lob", {note = "Anchor = where the stone lands; the ice spreads over the lob's area (about 3 cells wide)."}))
	_sheet("crowned_prismstorm", s, 8, 18, c, false, "crowned", _crowned_prismstorm.bind(false),
		_crown_info("#bff4ff", "Shatter + Static", {lite = "crowned_prismstorm_lite"}))
	_sheet("crowned_prismstorm_lite", s, 8, 18, c, false, "crowned", _crowned_prismstorm.bind(true))
	_sheet("crowned_nightbloom", s, 8, 14, Vector2i(48, 64), false, "crowned", _crowned_nightbloom,
		_crown_info("#c080ff", "Mushrooming + max Drowsy", {then = "nightbloom_cloud"}))
	_sheet("nightbloom_cloud", Vector2i(64, 64), 8, 10, Vector2i(32, 32), true, "ground_loop", _nightbloom_cloud,
		{note = "One path tile, loops while the cloud lasts. Draw under nightmares."})
	_sheet("crowned_fairy_circle", s, 8, 14, c, false, "crowned", _crowned_fairy_circle,
		_crown_info("#c080ff", "Mushrooming + Held", {then = "fairy_circle_ring"}))
	_sheet("fairy_circle_ring", Vector2i(64, 64), 8, 8, Vector2i(32, 32), true, "ground_loop", _fairy_circle_ring,
		{note = "One ring tile (the 8 around the held nightmare, path tiles only), loops for 6 s. Draw under nightmares."})
	# Delivery rules.
	_sheet("grafted_harmony_a", Vector2i(64, 64), 8, 8, Vector2i(32, 32), true, "overlay_loop", _grafted_harmony.bind(0),
		{note = "Graftling's two-colour glow, left half. White: tint it with the first status colour (modulate). Pair with grafted_harmony_b."})
	_sheet("grafted_harmony_b", Vector2i(64, 64), 8, 8, Vector2i(32, 32), true, "overlay_loop", _grafted_harmony.bind(1),
		{note = "Right half; tint with the second status colour."})
	_sheet("storm_front", s, 8, 14, c, true, "overlay_loop", _storm_front,
		{note = "Wraps a Reaction set off by a status Gust carried: play over the Reaction's effect."})
	_sheet("carried_storm", Vector2i(32, 8), 4, 16, Vector2i(0, 4), true, "segment", _carried_storm,
		{note = "Samara seed trail. White: tint with the carried Reaction's callout colour; stretch along the seed's path like light_thread."})
	# UI.
	_sheet("crowned_crown", Vector2i(16, 12), 4, 8, Vector2i(7, 11), true, "ui", _crowned_crown,
		{note = "Crown mark for a Crowned callout: sits centred on top of the callout text (anchor = its base)."})
	_sheet("crowned_callout_frame", Vector2i(64, 22), 1, 0, Vector2i(32, 11), false, "ui_frame", _crowned_callout_frame,
		{note = "Nine-patch behind a Crowned callout: patch margins 6 px left/right, 5 px top/bottom."})
	_sheet("crowned_card_accent", Vector2i(32, 32), 1, 0, Vector2i(0, 0), false, "ui", _crowned_card_accent,
		{note = "Gold corner for a Crowned discovery card: top-left corner, mirror it for the other three."})
	_sheet("crowned_codex_silhouette", Vector2i(96, 96), 1, 0, Vector2i(48, 48), false, "ui", _crowned_codex_silhouette,
		{note = "Undiscovered Crowned Reaction in the Codex. Family icon slots (18 px, centres): (22, 80), (48, 84), (74, 80); put the family icons (assets/meta/icons/family_icons.png) in them."})

func _crown_info(base_callout: String, reaction: String, extra: Dictionary = {}) -> Dictionary:
	var info := {callout = Color(base_callout).lerp(CROWN_GOLD, 0.45).to_html(false), reaction = reaction,
		tier = "gold", crown = "crowned_crown"}
	info.merge(extra)
	return info

# Draws a 64 px Reaction frame into the middle of a bigger image.
func _base_reaction(img: Image, draw: Callable, f: int, offset: Vector2i = Vector2i(16, 16)) -> void:
	var tmp := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	draw.call(tmp, f)
	img.blend_rect(tmp, Rect2i(0, 0, 64, 64), offset)

# Gold edge: every empty pixel touching a solid part of the effect (dithered glow doesn't count).
func _gold_edge(img: Image, col: Color = CROWN_GOLD) -> void:
	var src := img.duplicate() as Image
	var w := img.get_width()
	var h := img.get_height()
	var solid := func(x: int, y: int) -> bool:
		if x < 1 or y < 1 or x >= w - 1 or y >= h - 1 or src.get_pixel(x, y).a == 0.0:
			return false
		var n := 0
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if src.get_pixel(x + d.x, y + d.y).a > 0.0:
				n += 1
		return n >= 3
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if solid.call(x + d.x, y + d.y):
					img.set_pixel(x, y, col)
					break

# The gold tier's own burst around any Crowned Reaction: a wide gold ring, long sparks and shadow
# shards flung far, fading to gold motes.
func _crown_burst(img: Image, c: Vector2, f: int, reach: float, lite: bool = false) -> void:
	match f:
		1, 2:
			var r := reach * (0.55 + f * 0.2)
			_ring(img, c, Vector2(r, r * 0.9), 2, CROWN_GOLD, f == 2, f)
			_sparks(img, c, 12 if not lite else 6, r * 0.75, 5, CROWN_GOLD, 0.13 * f)
			if not lite:
				_shadow_break(img, c, 6, r + 4, 4.0, 0.5 + f * 0.2)
		3:
			_ring(img, c, Vector2(reach, reach * 0.9), 1, CROWN_GOLD, true, f)
			_sparks(img, c, 10 if not lite else 5, reach * 0.9, 3, CROWN_DEEP, 0.4)
			if not lite:
				_shadow_break(img, c, 6, reach + 6, 3.0, 0.9)
		4, 5:
			for k in (10 if not lite else 5):
				var p := c + Vector2.from_angle(k * TAU / 10.0 + f * 0.3) * (reach * (0.9 + (f - 4) * 0.1)) + Vector2(0, -(f - 3) * 3)
				_px(img, int(p.x), int(p.y), CROWN_GOLD if (k + f) % 2 == 0 else WARM)

func _crowned_tempest(img: Image, f: int, lite: bool) -> void:
	var c := Vector2(48, 48)
	var blue := Color("#bfe0ff")
	var pale := Color("#f4faff")
	if f <= 5:
		_base_reaction(img, _thunderclap.bind(lite), mini(f, 5))
	if f >= 1 and f <= 4:
		_base_reaction(img, _ignite.bind(lite), f)
	if not lite:
		_gold_edge(img)
	# Forks racing outward (blue-white, drawn after the gold edge), threaded with gold spore pops.
	if f >= 1 and f <= 4:
		var n := 4 if lite else 7
		for k in n:
			var d := Vector2.from_angle(k * TAU / n + 0.25)
			var reach := 22.0 + f * 6.0
			var pts := _bolt(img, c + d * 10, c + d * reach, 300 + f * 17 + k, pale, blue, 5, 3.5)
			var mid: Vector2 = pts[pts.size() / 2]
			if (k + f) % 2 == 0:
				_disc(img, mid, 2.2, CROWN_GOLD)
				_px(img, int(mid.x), int(mid.y), CORE)
				_px(img, int(mid.x) + 1, int(mid.y) - 1, VIOLET)
			if f >= 2 and not lite:
				_star(img, pts[pts.size() - 1], 2, CORE, CROWN_GOLD)
	_crown_burst(img, c, f, 40.0, lite)
	if f == 1 and not lite:
		_glow(img, c, Vector2(44, 44), f, WARM, CROWN_GOLD)

func _crowned_still_pool(img: Image, f: int) -> void:
	var c := Vector2(48, 50)
	if f <= 5:
		_base_reaction(img, _drown, mini(f + 1, 7))
		_gold_edge(img)
	_crown_burst(img, c + Vector2(0, -4), f, 36.0)
	# The pool spreads out under it.
	if f >= 3:
		var t: float = minf((f - 2) / 4.0, 1.0)
		_pool(img, c + Vector2(0, 8), Vector2(26, 11) * t, f)
	if f <= 2:
		_ring(img, c + Vector2(0, 6), Vector2(20 + f * 4, 8 + f * 2), 1, CROWN_GOLD)

func _pool(img: Image, c: Vector2, r: Vector2, f: int) -> void:
	if r.x < 2.0:
		return
	_ellipse(img, c, r, Color("#0e1a34"))
	_ellipse(img, c + Vector2(0, -1), r - Vector2(2, 1.5), Color("#16294a"))
	_ellipse(img, c + Vector2(-r.x * 0.2, -r.y * 0.3), r * Vector2(0.45, 0.35), Color("#1e3a64"))
	_ring(img, c, r, 1, Color("#3a5a8a"))
	# Gold-lilac shimmer drifting across the glass.
	var sx := c.x - r.x * 0.6 + fmod(f * r.x * 0.2, r.x * 1.2)
	_line(img, Vector2(sx, c.y - r.y * 0.35), Vector2(sx + r.x * 0.3, c.y - r.y * 0.35), Color("#e8d0a0"))
	_px(img, int(sx) + 2, int(c.y - r.y * 0.35) - 1, VIOLET_PALE)

func _still_pool(img: Image, f: int) -> void:
	var c := Vector2(32, 36)
	_pool(img, c, Vector2(26, 12), f)
	# Slow sleepy ripples.
	for k in 2:
		var t := fmod(f / 8.0 + k * 0.5, 1.0)
		_ring(img, c, Vector2(6 + t * 18, 2.5 + t * 8), 1, Color(Color("#8ab0e0"), 0.9 - t * 0.7), t > 0.5, f)
	if f % 4 == 1:
		_star(img, c + Vector2(10 - f, -4), 1, CORE, Color("#e8d0a0"))
	# A small "z" drifting up now and then.
	if f >= 4:
		var zy := 26 - (f - 4) * 3
		for p: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]:
			_px(img, 40 + p.x, zy + p.y, Color(VIOLET_PALE, 1.0 - (f - 4) * 0.2))

func _crowned_fever_dream(img: Image, f: int) -> void:
	var c := Vector2(48, 48)
	var haze := Color("#c8a0f0")
	if f <= 2:
		_base_reaction(img, _smother, f * 2)
	# The pop: every Spored tick at once.
	if f == 1 or f == 2:
		_disc(img, c, 9 - f * 2, VIOLET)
		_disc(img, c, 5 - f, CORE)
		_sparks(img, c, 10, 8 + f * 4, 5, CROWN_GOLD, 0.2)
	_gold_edge(img)
	# The sweet wave rolling out to the neighbours: lilac haze, gold flecks, spores and sleep.
	if f >= 1:
		var r := 10.0 + f * 5.0
		_ring(img, c, Vector2(r, r * 0.8), 3, Color(haze, 0.8), f >= 4, f)
		_ring(img, c, Vector2(r - 4, (r - 4) * 0.8), 1, Color(VIOLET, 0.8), true, f + 1)
		for k in 8:
			var d := Vector2.from_angle(k * TAU / 8.0 + 0.2)
			var p := c + Vector2(d.x * r, d.y * r * 0.8)
			if f <= 5:
				_disc(img, p, 2.5 - f * 0.25, VIOLET if k % 2 else Color("#a8d060"))
				_px(img, int(p.x), int(p.y) - 1, CROWN_GOLD)
			elif k % 2 == 0:
				_px(img, int(p.x), int(p.y), haze)
	_crown_burst(img, c, f, 38.0)
	if f == 1:
		_glow(img, c, Vector2(24, 20), f, VIOLET_PALE, VIOLET)

func _crowned_starfall(img: Image, f: int, lite: bool) -> void:
	var hit := Vector2(32, 150)
	var yellow := Color("#fff27a")
	match f:
		0:
			_star(img, Vector2(32, 6), 4, Color.WHITE, CROWN_GOLD)
			_ring(img, hit, Vector2(10, 4), 1, CROWN_GOLD, true)
		1, 2, 3:
			var w: float = [7.0, 10.0, 5.0][f - 1] * (0.7 if lite else 1.0)
			for y in range(0, int(hit.y)):
				var taper := 0.6 + 0.4 * y / hit.y
				for x in range(int(32 - w * taper), int(32 + w * taper) + 1):
					var q := absf(x - 32.0) / (w * taper)
					var col := CORE if q < 0.35 else (WARM if q < 0.7 else CROWN_GOLD)
					if q > 0.85 and (x + y + f) % 2 == 0:
						continue
					_px(img, x, y, col)
			if f <= 2:
				_disc(img, hit, 10 + f * 2, CORE)
				_ellipse(img, hit, Vector2(22, 8), WARM, true, f)
				if not lite:
					# Bolts streak in from the sides into the column.
					for k in 4:
						var from := Vector2(0 if k % 2 == 0 else 63, 70 + k * 18)
						_bolt(img, from, Vector2(32, 96 + k * 12), 500 + f * 9 + k, Color("#fffbd8"), yellow, 5, 3.0)
					_shadow_break(img, hit + Vector2(0, -4), 6, 18 + f * 4, 3.5)
			else:
				_ring(img, hit, Vector2(20, 7), 2, CROWN_GOLD)
		4:
			_ring(img, hit, Vector2(26, 9), 1, CROWN_GOLD, true)
			_sparks(img, hit + Vector2(0, -4), 8, 12, 4, WARM, 0.0, 0.5)
			for k in 5:
				_px(img, 30 + (k % 2) * 4, 40 + k * 20, CROWN_GOLD)
		5:
			_ring(img, hit, Vector2(30, 10), 1, CROWN_DEEP, true, 1)
			_sparks(img, hit + Vector2(0, -3), 6, 18, 2, CROWN_GOLD, 0.4, 0.5)
		6:
			for k in 6:
				var p := hit + Vector2.from_angle(k * TAU / 6.0) * Vector2(26, 9) + Vector2(0, -6)
				_px(img, int(p.x), int(p.y), CROWN_GOLD)
	if f >= 1 and f <= 2:
		_glow(img, hit + Vector2(0, -8), Vector2(30, 16), f, WARM, CROWN_GOLD)

func _crowned_avalanche(img: Image, f: int) -> void:
	var c := Vector2(64, 64)
	var ice := Color("#bff4ff")
	var ice_mid := Color("#7ac8f0")
	var stone := Color("#979dc2")
	if f <= 1:
		# The lobbed stone coming down.
		var p := c + Vector2(0, -34 + f * 26)
		_disc(img, p, 7, OUTLINE)
		_disc(img, p + Vector2(0, -0.5), 6, stone)
		_px(img, int(p.x) - 2, int(p.y) - 3, Color("#c4c9e2"))
		_ellipse(img, c + Vector2(0, 4), Vector2(10 + f * 4, 3 + f), Color(0.05, 0.04, 0.08, 0.35))
		if f == 1:
			_ring(img, c + Vector2(0, 4), Vector2(18, 6), 1, CROWN_GOLD, true)
		return
	var k := f - 2
	if k <= 1:
		_disc(img, c, 9 - k * 3, CORE)
		_ellipse(img, c + Vector2(0, 2), Vector2(30 + k * 10, 10 + k * 3), WARM, true, k)
	# Ice bursting across the whole area, wider than a Shatter.
	for i in 14:
		var d := Vector2.from_angle(i * TAU / 14.0 + 0.1)
		var reach := 10.0 + k * 11.0
		var p := c + Vector2(d.x * reach * 1.9, d.y * reach * 0.75)
		var tip := p + Vector2(d.x, d.y * 0.5) * (6 - k * 0.6)
		var side := d.orthogonal() * 2.5
		if k <= 4:
			_line(img, p - side, tip, ice)
			_line(img, p + side, tip, ice_mid)
			_line(img, p - side, p + side, OUTLINE)
	# Ice crusted on the ground where it spread.
	if k >= 1:
		for i in 9:
			var p := c + Vector2(-44 + i * 11, 6 + (i % 3) * 3 - 3)
			_line(img, p, p + Vector2(4, -3), ice if (i + f) % 2 == 0 else Color.WHITE)
	if k >= 0 and k <= 2:
		_shadow_break(img, c + Vector2(0, -4), 7, 20 + k * 10, 3.5)
	_gold_edge(img)
	_crown_burst(img, c, mini(k + 1, 5), 44.0)
	if k == 0:
		_glow(img, c, Vector2(56, 26), k, Color("#e8faff"), CROWN_GOLD)

func _crowned_prismstorm(img: Image, f: int, lite: bool) -> void:
	var c := Vector2(48, 48)
	_base_reaction(img, _shatter, mini(f, 6))
	if not lite:
		_gold_edge(img)
	# Shards throwing rainbow-edged sparks of lightning.
	if f >= 2 and f <= 5:
		var k := f - 2
		var n := 4 if lite else 8
		for i in n:
			var d := Vector2.from_angle(i * TAU / n + 0.2)
			var from := c + d * (8 + k * 6)
			var to := from + d * (10 + k * 4)
			_bolt(img, from, to, 700 + f * 11 + i, CORE, Color(RAINBOW[(i + k) % RAINBOW.size()]), 3, 2.5)
			if not lite and k <= 1:
				_star(img, to, 2, CORE, Color(RAINBOW[(i + k + 2) % RAINBOW.size()]))
	_crown_burst(img, c, f, 40.0, lite)
	if f == 2 and not lite:
		_glow(img, c, Vector2(30, 30), f, Color("#f4faff"), CROWN_GOLD)

func _glow_mushroom(img: Image, base: Vector2, h: float, w: float, lit: bool) -> void:
	_line(img, base, base + Vector2(0, -h), Color("#e8dcf8"), 2)
	var cap_c := base + Vector2(0, -h)
	for y in range(int(cap_c.y - w * 0.75), int(cap_c.y + 1)):
		for x in range(int(cap_c.x - w), int(cap_c.x + w + 1)):
			var q := ((Vector2(x + 0.5, y + 0.5) - cap_c) / Vector2(w, w * 0.75)).length()
			if q <= 1.0:
				var col := OUTLINE if q > 0.82 else (Color("#f0d8ff") if y < cap_c.y - w * 0.4 else VIOLET)
				_px(img, x, y, col)
	if lit:
		for d: Vector2 in [Vector2(-w * 0.4, -w * 0.4), Vector2(w * 0.3, -w * 0.25), Vector2(0, -w * 0.55)]:
			_px(img, int(cap_c.x + d.x), int(cap_c.y + d.y), CROWN_GOLD)

func _crowned_nightbloom(img: Image, f: int) -> void:
	var base := Vector2(48, 64)
	var sizes := [[0.0, 0.0], [7.0, 4.0], [16.0, 8.5], [18.0, 9.5], [17.0, 9.0], [15.0, 8.0], [14.0, 7.5], [12.0, 6.5]]
	var h: float = sizes[f][0]
	var w: float = sizes[f][1]
	if f == 0:
		_line(img, base + Vector2(-12, 0), base + Vector2(12, 0), VIOLET_PALE)
		_line(img, base + Vector2(-4, -1), base + Vector2(4, 1), CORE)
		_glow(img, base, Vector2(18, 7), 0, VIOLET_PALE, VIOLET)
		return
	for m: Array in [[Vector2(-13, 2), 0.65], [Vector2(12, 2), 0.72], [Vector2(-5, 0), 0.85], [Vector2(5, -1), 1.0]]:
		var off: Vector2 = m[0]
		var s: float = m[1]
		_glow_mushroom(img, base + off, h * s, maxf(w * s, 2.0), f >= 2)
	_gold_edge(img)
	_crown_burst(img, base + Vector2(0, -14), f, 36.0)
	for k in 7:
		var t := float(f) / 7.0
		_px(img, 22 + k * 8, int(58 - t * 40 - (k % 3) * 4), VIOLET_PALE if k % 2 else CROWN_GOLD)
	if f >= 2 and f <= 4:
		_glow(img, base + Vector2(0, -16), Vector2(30, 22), f, VIOLET_PALE, VIOLET)

func _nightbloom_cloud(img: Image, f: int) -> void:
	var c := Vector2(32, 38)
	var pulse := 0.5 + 0.5 * sin(TAU * f / 8.0)
	_ellipse(img, c, Vector2(30, 14), Color(0.45, 0.25, 0.75, 0.5), true, f)
	_ellipse(img, c, Vector2(22, 9), Color(0.6, 0.38, 0.92, 0.6 + 0.2 * pulse), true, f + 1)
	_ellipse(img, c + Vector2(0, -1), Vector2(10, 4), Color(0.85, 0.7, 1.0, 0.55 + 0.3 * pulse), true, f)
	for k in 9:
		var t := fmod(float(f) / 8.0 + k / 9.0, 1.0)
		var x := 6 + k * 6 + roundi(sin(t * TAU) * 2)
		var y := roundi(46 - t * 26)
		_px(img, x, y, CROWN_GOLD if k % 3 == 0 else VIOLET_PALE)
		if k % 3 == 0:
			_px(img, x, y - 1, WARM)
	if f % 4 == 0:
		_star(img, c + Vector2(-12 + f * 2, -8), 1, CORE, VIOLET_PALE)

func _crowned_fairy_circle(img: Image, f: int) -> void:
	var c := Vector2(48, 50)
	var ring := Vector2(34, 17)
	# Mushrooms pop up round the ring one after another.
	for i in 8:
		var a := i * TAU / 8.0 - PI * 0.5
		var p := c + Vector2(cos(a) * ring.x, sin(a) * ring.y)
		var age := f - (i % 4)
		if age < 0:
			continue
		var grow: float = [0.4, 1.0, 0.9, 0.85, 0.85, 0.8, 0.8, 0.8][mini(age, 7)]
		_glow_mushroom(img, p + Vector2(0, 4), 7.0 * grow, 4.0 * grow, age == 1)
		if age == 1:
			_star(img, p + Vector2(0, -8), 2, CORE, CROWN_GOLD)
	if f >= 1:
		_ring(img, c + Vector2(0, 4), ring, 1, Color(VIOLET_PALE, 0.8), true, f)
	_gold_edge(img)
	_crown_burst(img, c, f, 44.0)
	if f == 1 or f == 2:
		_glow(img, c, Vector2(20, 12), f, VIOLET_PALE, VIOLET)

func _fairy_circle_ring(img: Image, f: int) -> void:
	var c := Vector2(32, 38)
	var pulse := 0.5 + 0.5 * sin(TAU * f / 8.0)
	_ring(img, c, Vector2(20, 10), 1, Color(VIOLET_PALE, 0.35 + 0.35 * pulse), true, f)
	for i in 6:
		var a := i * TAU / 6.0 + 0.3
		var p := c + Vector2(cos(a) * 18, sin(a) * 9)
		_glow_mushroom(img, p + Vector2(0, 2), 3.5, 2.5, (f + i) % 4 == 0)
	if f % 2 == 0:
		_px(img, int(c.x) + (f - 4), int(c.y) - 12 - f % 3, CROWN_GOLD)

func _grafted_harmony(img: Image, f: int, side: int) -> void:
	var c := Vector2(32, 36)
	var pulse := 0.5 + 0.5 * sin(TAU * (f + side * 4) / 8.0)
	var white := Color(1, 1, 1, 0.55 + 0.35 * pulse)
	var soft := Color(1, 1, 1, 0.35 + 0.25 * pulse)
	var sgn := -1.0 if side == 0 else 1.0
	for y in 64:
		for x in 64:
			var d := Vector2(x + 0.5, y + 0.5) - c
			if d.x * sgn < 0.0:
				continue
			var q := (d / Vector2(28, 26)).length()
			if q >= 0.86 and q <= 1.0:
				_px(img, x, y, white)
			elif q > 0.6 and q < 0.86 and (x + y + f) % 3 == 0:
				_px(img, x, y, soft)
	for k in 3:
		var t := fmod(float(f) / 8.0 + k / 3.0, 1.0)
		var x := int(c.x + sgn * (10 + k * 6))
		_px(img, x, int(54 - t * 36), white)

func _storm_front(img: Image, f: int) -> void:
	var c := Vector2(48, 50)
	var cream := Color("#f4f0d8")
	var mint := Color("#c8ecd0")
	for strand in 3:
		var pts: Array = []
		for s in 24:
			var t := s / 23.0
			var a := strand * TAU / 3.0 + f * TAU / 16.0 + t * PI * 1.3
			var r := 30.0 + sin(t * PI) * 6.0
			pts.append(c + Vector2(cos(a) * r, sin(a) * r * 0.55 - t * 8))
		_poly_line(img, pts.slice(0, 16), mint)
		_poly_line(img, pts.slice(12), cream)
		var tip: Vector2 = pts[23]
		_px(img, int(tip.x), int(tip.y), CORE)
	for k in 4:
		var a := k * TAU / 4.0 - f * TAU / 12.0
		var p := c + Vector2(cos(a) * 40, sin(a) * 20)
		_line(img, p, p + Vector2(-sin(a), cos(a) * 0.5) * 5, cream)

func _carried_storm(img: Image, f: int) -> void:
	for x in 32:
		var t := x / 31.0  # 0 = the tail end, 1 = at the seed
		var a := 0.25 + 0.75 * t
		_px(img, x, 4, Color(1, 1, 1, a))
		if (x + f * 3) % 5 < 2:
			_px(img, x, 3, Color(1, 1, 1, a * 0.7))
		if (x + f * 3 + 2) % 7 < 2:
			_px(img, x, 5, Color(1, 1, 1, a * 0.6))
	for k in 2:
		_px(img, (f * 8 + k * 16) % 32, 1 + k * 5, Color(1, 1, 1, 0.8))

const CROWN_PX := [
	".......o........",
	"..o...###...o...",
	".###..#g#..###..",
	".#g#.##g##.#g#..",
	".#gg##ggg##gg#..",
	".#ggggggggggg#..",
	".#gwgggogggwg#..",
	".#ggggggggggg#..",
	".#############..",
]

func _crowned_crown(img: Image, f: int) -> void:
	for y in CROWN_PX.size():
		var row: String = CROWN_PX[y]
		for x in row.length():
			match row[x]:
				"#":
					_px(img, x, y + 2, CROWN_DEEP)
				"g":
					_px(img, x, y + 2, CROWN_GOLD)
				"o":
					_px(img, x, y + 2, Color("#ff8aa0"))
				"w":
					_px(img, x, y + 2, CORE)
	# A glint running along the band.
	var gx: int = [3, 6, 9, 12][f]
	_px(img, gx, 7, Color.WHITE)
	_px(img, gx, 9, CORE)

func _crowned_callout_frame(img: Image, _f: int) -> void:
	var w := 64
	var h := 22
	var dark := Color(0.08, 0.06, 0.12, 0.85)
	for y in range(2, h - 2):
		for x in range(2, w - 2):
			img.set_pixel(x, y, dark)
	for x in range(3, w - 3):
		_px(img, x, 1, CROWN_GOLD)
		_px(img, x, h - 2, CROWN_DEEP)
		_px(img, x, 2, Color(CROWN_GOLD, 0.5) if x % 2 == 0 else dark)
	for y in range(3, h - 3):
		_px(img, 1, y, CROWN_GOLD)
		_px(img, w - 2, y, CROWN_DEEP)
	for p: Vector2i in [Vector2i(2, 2), Vector2i(w - 3, 2), Vector2i(2, h - 3), Vector2i(w - 3, h - 3)]:
		_px(img, p.x, p.y, CROWN_GOLD)
	# Little leaf-points at both ends.
	for s: int in [0, 1]:
		var x := 0 if s == 0 else w - 1
		_px(img, x, h / 2, CROWN_GOLD)
		_px(img, x, h / 2 - 1, CROWN_DEEP)

func _crowned_card_accent(img: Image, _f: int) -> void:
	# An L of gold with a curling vine and a small star at the corner.
	for k in range(2, 30):
		_px(img, k, 2, CROWN_GOLD if k < 24 or k % 2 == 0 else CROWN_DEEP)
		_px(img, 2, k, CROWN_GOLD if k < 24 or k % 2 == 0 else CROWN_DEEP)
		if k < 20:
			_px(img, k, 3, CROWN_DEEP)
			_px(img, 3, k, CROWN_DEEP)
	# Gold laurel leaves along both arms.
	for k in 3:
		var t := 9 + k * 6
		for leaf: Array in [[Vector2(t, 5), Vector2(1, 1)], [Vector2(5, t), Vector2(1, 1)]]:
			var p: Vector2 = leaf[0]
			_px(img, int(p.x), int(p.y), CROWN_GOLD)
			_px(img, int(p.x) + 1, int(p.y), CROWN_GOLD if p.y == 5 else CROWN_DEEP)
			_px(img, int(p.x), int(p.y) + 1, CROWN_DEEP if p.y == 5 else CROWN_GOLD)
			_px(img, int(p.x) + 1, int(p.y) + 1, CROWN_DEEP)
	_star(img, Vector2(5, 5), 2, CORE, CROWN_GOLD)

func _crowned_codex_silhouette(img: Image, _f: int) -> void:
	var c := Vector2(48, 40)
	var dark := Color("#241c34")
	var rim := Color("#4a3a6a")
	# A burst silhouette: a disc with eight rays.
	_disc(img, c, 16, dark)
	for k in 8:
		var d := Vector2.from_angle(k * TAU / 8.0 + PI / 8.0)
		var tip := c + d * 30.0
		var side := d.orthogonal() * 5.0
		var pts := PackedVector2Array([c + d * 12.0 - side, tip, c + d * 12.0 + side])
		for y in 96:
			for x in 96:
				if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
					img.set_pixel(x, y, dark)
	# Rim light on the silhouette's edge, and a dim crown outline above.
	var src := img.duplicate() as Image
	for y in range(1, 95):
		for x in range(1, 95):
			if src.get_pixel(x, y).a > 0.0 and (src.get_pixel(x, y - 1).a == 0.0 or src.get_pixel(x - 1, y).a == 0.0):
				img.set_pixel(x, y, rim)
	for y in CROWN_PX.size():
		var row: String = CROWN_PX[y]
		for x in row.length():
			if row[x] == "#":
				_px(img, 40 + x, 2 + y, rim)
	_disc(img, c, 3, rim)
	# Three slots for the family icons.
	for p: Vector2 in [Vector2(22, 80), Vector2(48, 84), Vector2(74, 80)]:
		_disc(img, p, 10, Color(0.1, 0.08, 0.16, 0.9))
		_ring(img, p, Vector2(10, 10), 1, rim)
		_ring(img, p, Vector2(11, 11), 1, Color(CROWN_DEEP, 0.6))

func _save_crowned_preview() -> void:
	var pad := 6
	var width := 0
	var height := pad
	for i in range(crowned_from, previews.size()):
		var sheet: Image = previews[i][1]
		width = maxi(width, sheet.get_width() + pad * 2)
		height += sheet.get_height() + pad
	var out := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	out.fill(Color("#1c1a2c"))
	var y := pad
	for i in range(crowned_from, previews.size()):
		var sheet: Image = previews[i][1]
		out.blend_rect(sheet, Rect2i(Vector2i.ZERO, sheet.get_size()), Vector2i(pad, y))
		y += sheet.get_height() + pad
	out.resize(out.get_width() * 2, out.get_height() * 2, Image.INTERPOLATE_NEAREST)
	out.save_png("res://tools/previews/effects_crowned.png")

# --- Kinships (tower_design.md "Kinships", screens_ui.md "Kinship feedback") ------------------------
# Same-family combos: the forest growing between Wardens (vines, leaves, petals), not light bursting
# on nightmares. Everything is drawn in white-to-grey so the code tints it with the family's colour
# (modulate); outlines stay dark. Quiet on purpose: thin vines, small bursts, a tiny harmony spark.

const K_WHITE := Color("#ffffff")
const K_LIGHT := Color("#e4e4e4")
const K_MID := Color("#b4b4b4")
const K_DARK := Color("#787878")
const K_EDGE := Color("#343434")

var kinship_from := 0

func _kinship() -> void:
	kinship_from = previews.size()
	var seg := {note = "Ground vine between two kin Wardens: stretch or tile along x (tiles every 32 px), y = 5 on the line. Tint with the family colour; drawn under the Wardens, ~30% alpha most of the time."}
	_sheet("kin_vine_sapling", Vector2i(32, 10), 4, 4, Vector2i(0, 5), true, "kinship", _kin_vine.bind(0), seg)
	_sheet("kin_vine_blooming", Vector2i(32, 10), 4, 4, Vector2i(0, 5), true, "kinship", _kin_vine.bind(1), seg)
	_sheet("kin_vine_oldkin", Vector2i(32, 10), 4, 4, Vector2i(0, 5), true, "kinship", _kin_vine.bind(2), seg)
	_sheet("kin_vine_grow", Vector2i(64, 10), 8, 14, Vector2i(0, 5), false, "kinship", _kin_vine_grow,
		{note = "The bond moment: a blooming vine grows left to right with a bright bud at its tip. Stretch it between the two Wardens (or clip kin_vine_blooming instead)."})
	_sheet("kin_bond_burst", Vector2i(64, 64), 8, 13, Vector2i(32, 32), false, "kinship", _kin_bond_burst,
		{note = "Plays on both Wardens when a bond forms (~0.6 s). Tint with the family colour."})
	_sheet("kin_stage_up", Vector2i(64, 64), 8, 12, Vector2i(32, 40), false, "kinship", _kin_stage_up,
		{note = "A Kinship grows a stage: leaves unfurl and a small flower opens. Anchor = its base."})
	_sheet("harmony_spark_a", Vector2i(24, 24), 6, 20, Vector2i(12, 12), false, "kinship", _harmony_spark.bind(0),
		{note = "Tiny: a petal spirals in from the left and sparks. Tint with the first Warden's colour; play with harmony_spark_b.", lite = "harmony_spark_lite"})
	_sheet("harmony_spark_b", Vector2i(24, 24), 6, 20, Vector2i(12, 12), false, "kinship", _harmony_spark.bind(1),
		{note = "The other petal, from the right; tint with the second Warden's colour."})
	_sheet("harmony_spark_lite", Vector2i(16, 16), 4, 20, Vector2i(8, 8), false, "kinship", _harmony_spark_lite)
	_sheet("whole_tree_sigil", Vector2i(128, 128), 12, 10, Vector2i(64, 88), false, "kinship", _whole_tree_sigil,
		{note = "Plays ON the Heartwood: same 128x128 frame as its sprite, anchor (64, 88) = the Heartwood's position, so Fx.play at heartwood.global_position lines it up. Draw above the Heartwood (~1.2 s, settles at the end). Tint with the family colour."})
	_sheet("whole_tree_badge", Vector2i(16, 16), 1, 0, Vector2i(8, 8), false, "kinship", _whole_tree_badge,
		{note = "Small leaf badge on the family's Wardens after a Whole Tree."})
	_sheet("kin_callout_frame", Vector2i(64, 22), 1, 0, Vector2i(32, 11), false, "ui_frame", _kin_callout_frame,
		{note = "Nine-patch behind a Kinship callout: patch margins 7 px left/right, 5 px top/bottom."})
	_sheet("kin_leaf_icon", Vector2i(16, 16), 1, 0, Vector2i(8, 8), false, "ui", _kin_leaf_icon,
		{note = "Kinship mark for callouts and the Codex."})
	_sheet("kin_codex_frame", Vector2i(96, 96), 1, 0, Vector2i(48, 48), false, "ui_frame", _kin_codex_frame,
		{note = "Locked \"???\" Kinship entry: a vine border round a dark panel (nine-patch margins 14 px)."})

# A small leaf pointing along `dir` from `base`, shaded light on its upper half.
func _kin_leaf(img: Image, base: Vector2, dir: Vector2, length: float, width: float) -> void:
	var tip := base + dir * length
	var side := dir.orthogonal() * width
	var mid := base + dir * length * 0.5
	var pts := PackedVector2Array([base, mid + side, tip, mid - side])
	var box := Rect2(base, Vector2.ZERO).expand(tip).expand(mid + side).expand(mid - side).grow(1)
	for y in range(maxi(0, floori(box.position.y)), mini(img.get_height(), ceili(box.end.y))):
		for x in range(maxi(0, floori(box.position.x)), mini(img.get_width(), ceili(box.end.x))):
			var p := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(p, pts):
				img.set_pixel(x, y, K_LIGHT if (p - mid).dot(side) > 0.0 else K_MID)
	_line(img, base, tip, K_DARK)

# A small flower: rounded petals round a dark centre (four when tiny, five when bigger).
func _kin_flower(img: Image, c: Vector2, r: float, open: float = 1.0) -> void:
	if r < 3.0 and open >= 1.0:
		# Too small for round petals: a pixel blossom (white petals on the cross, pale between).
		var p := Vector2i(c.round())
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			_px(img, p.x + d.x, p.y + d.y, K_WHITE)
			_px(img, p.x + d.x * 2, p.y + d.y * 2, K_LIGHT if d.y <= 0 else K_MID)
		_px(img, p.x, p.y, K_DARK)
		return
	var n := 4 if r < 3.0 else 5
	for k in n:
		var d := Vector2.from_angle(k * TAU / n + (PI / 4.0 if n == 4 else -PI * 0.5))
		_disc(img, c + d * r * 0.7 * open, maxf(r * 0.5, 0.9), K_WHITE)
	_disc(img, c, maxf(r * 0.35, 0.7), K_DARK)

# Stage 0 sapling (thin), 1 blooming (thicker, leaves), 2 old kin (flowers too). Tiles every 32 px.
func _kin_vine(img: Image, f: int, stage: int) -> void:
	var sway := sin(f * TAU / 4.0) * 0.6
	var pts: Array = []
	for x in 33:
		pts.append(Vector2(x, 5 + sin(x * TAU / 32.0) * 1.5 + sway * sin(x * TAU / 16.0)))
	if stage >= 1:
		_poly_line(img, pts, K_EDGE, 2)
		for i in pts.size() - 1:
			var p: Vector2 = pts[i]
			_px(img, int(p.x), int(round(p.y)), K_MID)
			_px(img, int(p.x), int(round(p.y)) - 1, K_LIGHT)
	else:
		_poly_line(img, pts, K_MID)
		for p: Vector2 in pts:
			_px(img, int(p.x), int(round(p.y)) + 1, K_EDGE)
	if stage >= 1:
		for leaf: Array in [[8.0, -1.0], [24.0, 1.0]]:
			var x: float = leaf[0]
			var up: float = leaf[1]
			var base: Vector2 = pts[int(x)]
			_kin_leaf(img, base, Vector2(0.7, -0.7 * up + sway * 0.2).normalized(), 5.5, 2.2)
	else:
		var b: Vector2 = pts[16]
		_px(img, int(b.x) + 1, int(b.y) - 1, K_LIGHT)
	if stage >= 2:
		var c: Vector2 = pts[16]
		_kin_flower(img, c + Vector2(0, -2), 2.2)

func _kin_vine_grow(img: Image, f: int) -> void:
	var reach := int(64.0 * (f + 1) / 8.0)
	var pts: Array = []
	for x in reach:
		pts.append(Vector2(x, 5 + sin(x * TAU / 32.0) * 1.5))
	if pts.size() >= 2:
		_poly_line(img, pts, K_EDGE, 2)
		for p: Vector2 in pts:
			_px(img, int(p.x), int(round(p.y)), K_MID)
			_px(img, int(p.x), int(round(p.y)) - 1, K_LIGHT)
	for x: int in [8, 24, 40, 56]:
		if x < reach - 3:
			var base: Vector2 = pts[x]
			var grow := clampf((reach - x) / 10.0, 0.3, 1.0)
			_kin_leaf(img, base, Vector2(0.55, -0.85 if x % 16 == 8 else 0.85).normalized(), 4.0 * grow, 1.6 * grow)
	# The bright bud at the growing tip.
	if pts.size() >= 1 and f < 7:
		var tip: Vector2 = pts[pts.size() - 1]
		_disc(img, tip, 1.8, K_WHITE)
		_px(img, int(tip.x) + 1, int(tip.y) - 2, K_WHITE)
	if f == 7:
		_kin_flower(img, Vector2(60, 3), 2.0)

func _kin_bond_burst(img: Image, f: int) -> void:
	var c := Vector2(32, 34)
	var t := f / 7.0
	if f <= 1:
		_ring(img, c, Vector2(6 + f * 5, 4 + f * 3), 1, K_WHITE)
	for k in 10:
		var a := k * TAU / 10.0 + 0.3 + t * 1.2
		var r := 6.0 + t * 24.0
		var p := c + Vector2(cos(a) * r, sin(a) * r * 0.75 - t * 8.0)
		var fade := f >= 6 and (k + f) % 2 == 0
		if fade:
			continue
		if k % 2 == 0:
			# A petal: a small oval tumbling outward.
			var d := Vector2.from_angle(a + f * 0.9)
			_disc(img, p, 1.6, K_WHITE)
			_px(img, int(p.x + d.x * 2), int(p.y + d.y * 2), K_LIGHT)
		else:
			_kin_leaf(img, p, Vector2.from_angle(a + f * 0.6), 4.0 - t * 1.5, 1.4)
	if f >= 1 and f <= 3:
		_sparks(img, c, 6, 10 + f * 4, 2, K_LIGHT, 0.2 + f * 0.3)

func _kin_stage_up(img: Image, f: int) -> void:
	var base := Vector2(32, 40)
	var grow: float = [0.2, 0.45, 0.7, 0.9, 1.0, 1.0, 1.0, 1.0][f]
	_line(img, base, base + Vector2(0, -12 * grow), K_DARK, 2)
	_kin_leaf(img, base + Vector2(0, -3), Vector2(-0.8, -0.55).normalized(), 7.0 * grow, 2.2 * grow)
	_kin_leaf(img, base + Vector2(0, -6), Vector2(0.8, -0.55).normalized(), 7.0 * grow, 2.2 * grow)
	if f >= 3:
		var open: float = [0.0, 0.0, 0.0, 0.4, 0.8, 1.0, 1.0, 1.0][f]
		_kin_flower(img, base + Vector2(0, -14), 3.2, open)
	if f >= 4 and f <= 6:
		var r := 8.0 + (f - 4) * 6.0
		for k in 8:
			var p := base + Vector2(0, -14) + Vector2.from_angle(k * TAU / 8.0 + f * 0.2) * r
			if (k + f) % 2 == 0:
				_px(img, int(p.x), int(p.y), K_WHITE)
	if f >= 6:
		_ellipse(img, base + Vector2(0, 1), Vector2(9, 2), Color(K_MID, 0.5), true, f)

# Two tiny petals spiral in and meet in a spark; side 0 = from the left, 1 = from the right.
func _harmony_spark(img: Image, f: int, side: int) -> void:
	var c := Vector2(12, 12)
	var sgn := -1.0 if side == 0 else 1.0
	if f <= 3:
		var t := f / 3.0
		var a := (PI if side == 0 else 0.0) + t * PI * 0.9 * sgn
		var r := 9.0 * (1.0 - t)
		var p := c + Vector2(cos(a), sin(a)) * r
		_disc(img, p, 1.5, K_WHITE)
		_px(img, int(p.x - cos(a) * 2), int(p.y - sin(a) * 2), K_LIGHT)
	else:
		var arm: int = [0, 0, 0, 0, 3, 2][f]
		for k in range(1, arm + 1):
			_px(img, int(c.x) + k * int(sgn), int(c.y), K_WHITE if k < arm else K_LIGHT)
			_px(img, int(c.x), int(c.y) - k if side == 0 else int(c.y) + k, K_WHITE if k < arm else K_LIGHT)
		_px(img, int(c.x), int(c.y), K_WHITE)

func _harmony_spark_lite(img: Image, f: int) -> void:
	var c := Vector2(8, 8)
	var arm: int = [1, 2, 2, 1][f]
	for k in range(-arm, arm + 1):
		_px(img, int(c.x) + k, int(c.y), K_LIGHT)
		_px(img, int(c.x), int(c.y) + k, K_LIGHT)
	_px(img, int(c.x), int(c.y), K_WHITE)

# The Whole Tree happens ON the Heartwood (same 128x128 frame and anchor as its sprite, so it lays
# exactly over the tree): light runs up the trunk's cracks and out along the roots, the canopy
# bursts into blossom from the middle outward, its rim glows, a ring pulses round the base, petals
# drift up, and it all settles. Masks come from the Heartwood's own art (its shape is the same in
# every act). White-to-grey so the code tints it with the family colour.
const HEARTWOOD_ART := "res://assets/environment/forest_edge/heartwood.png"
var _hw_canopy := {}
var _hw_bark := {}
var _hw_blossoms: Array = []

func _heartwood_masks() -> void:
	if not _hw_canopy.is_empty():
		return
	var art := Image.load_from_file(ProjectSettings.globalize_path(HEARTWOOD_ART))
	art.convert(Image.FORMAT_RGBA8)
	for y in 128:
		for x in 128:
			var c := art.get_pixel(x, y)
			if c.a < 0.9:
				continue
			if c.g > c.r + 0.04 and c.g > c.b:
				_hw_canopy[Vector2i(x, y)] = true
			elif c.r > c.g and c.g >= c.b and c.get_luminance() < 0.45 and y > 50:
				_hw_bark[Vector2i(x, y)] = c.get_luminance()
	# Blossom spots: a loose grid over the canopy, only where there's leaf all round.
	var centre := Vector2(64, 36)
	for y in range(5, 70, 8):
		for x in range(6, 124, 10):
			var p := Vector2i(x + (y / 8 % 2) * 5 + (x * 7 + y * 3) % 5 - 2, y + (x * 5 + y) % 5 - 2)
			if (x * 13 + y * 7) % 10 < 3:
				continue
			var inside := true
			for d: Vector2i in [Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, -2), Vector2i(0, 2)]:
				if not _hw_canopy.has(p + d):
					inside = false
			if inside:
				_hw_blossoms.append([p, (Vector2(p) - centre).length()])

func _whole_tree_sigil(img: Image, f: int) -> void:
	_heartwood_masks()
	var fading := f >= 9
	# 1. Light runs up through the bark (frames 0-4): the darker bark pixels (its cracks) light up
	#    as a wave climbs from the roots to the crown, then glow and dim.
	var wave := 118.0 - f * 16.0
	for p: Vector2i in _hw_bark:
		# Only the bark's crack lines: pixels darker than the bark on both sides of them.
		var lum: float = _hw_bark[p]
		if not (_hw_bark.has(p + Vector2i.LEFT) and _hw_bark.has(p + Vector2i.RIGHT)):
			continue
		if float(_hw_bark[p + Vector2i.LEFT]) <= lum + 0.02 or float(_hw_bark[p + Vector2i.RIGHT]) <= lum + 0.02:
			continue
		if f <= 4 and p.y >= wave and p.y < wave + 10.0:
			img.set_pixel(p.x, p.y, K_WHITE)
		elif f >= 1 and f <= 8 and p.y >= wave + 10.0 and (p.x + p.y) % 2 == 0:
			img.set_pixel(p.x, p.y, K_LIGHT if f < 7 else K_MID)
	# 2. The canopy's rim glows while it blooms.
	if f >= 3 and f <= 8:
		for p: Vector2i in _hw_canopy:
			var edge := false
			for d: Vector2i in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0)]:
				if not _hw_canopy.has(p + d):
					edge = true
					break
			if edge and (p.x + f) % (2 if f < 7 else 3) == 0:
				img.set_pixel(p.x, p.y, K_WHITE if f < 7 else K_LIGHT)
	# 3. Blossoms burst open from the middle of the crown outward, then some drop away.
	for b: Array in _hw_blossoms:
		var p: Vector2i = b[0]
		var born := 2.0 + (b[1] as float) / 22.0
		if f < born:
			continue
		var age := f - born
		if fading and (p.x * 7 + p.y * 3) % 3 <= f - 9:
			continue
		_kin_flower(img, Vector2(p), 2.2 if age >= 1.0 else 1.2, 1.0 if age >= 1.0 else 0.5)
		if age < 1.0:
			_px(img, p.x, p.y - 3, K_WHITE)
	# 4. A ring of light pulses out round the base, over the roots.
	if f >= 4 and f <= 8:
		var r := 20.0 + (f - 4) * 10.0
		_ring(img, Vector2(64, 104), Vector2(r, r * 0.35), 1, K_WHITE if f < 7 else K_LIGHT, f >= 6, f)
	# 5. Petals drift up off the crown and away.
	if f >= 5:
		for k in 9:
			var t := (f - 5) / 6.0
			var x := 18 + k * 12 + roundi(sin(k * 1.7 + f * 0.6) * 4)
			var y := roundi(40 - (k % 3) * 10 - t * 40)
			if y < 1 or (fading and (k + f) % 2 == 0):
				continue
			_px(img, x, y, K_WHITE)
			_px(img, x + 1, y, K_LIGHT)
			_px(img, x, y + 1, K_MID)
	# A soft sheen over the crown at the peak.
	if f == 6:
		for p: Vector2i in _hw_canopy:
			if (p.x + p.y) % 4 == 0 and img.get_pixelv(p).a == 0.0:
				img.set_pixelv(p, Color(K_WHITE, 0.35))

func _whole_tree_badge(img: Image, _f: int) -> void:
	_disc(img, Vector2(8, 8), 7.2, K_EDGE)
	_disc(img, Vector2(8, 8), 6.2, K_DARK)
	_disc(img, Vector2(8, 8), 5.2, K_MID)
	_kin_leaf(img, Vector2(4.5, 11.5), Vector2(0.7, -0.7), 8.5, 2.6)
	_px(img, 6, 5, K_WHITE)

func _kin_leaf_icon(img: Image, _f: int) -> void:
	# A leaf with a curled stem and a smaller leaf beside it: kinship, growing together.
	_kin_leaf(img, Vector2(3, 13), Vector2(0.6, -0.8), 12.0, 3.6)
	_kin_leaf(img, Vector2(6, 13), Vector2(0.95, -0.3), 7.0, 2.2)
	var src := img.duplicate() as Image
	for y in 16:
		for x in 16:
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q := Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < 16 and q.y < 16 and src.get_pixelv(q).a > 0.0:
					img.set_pixel(x, y, K_EDGE)
					break
	_px(img, 2, 14, K_DARK)
	_px(img, 1, 15, K_DARK)

func _kin_callout_frame(img: Image, _f: int) -> void:
	var w := 64
	var h := 22
	var dark := Color(0.08, 0.08, 0.08, 0.85)
	for y in range(2, h - 2):
		for x in range(3, w - 3):
			img.set_pixel(x, y, dark)
	# A vine along the top and bottom edges, small leaves at the ends.
	for x in range(3, w - 3):
		_px(img, x, 1 + (1 if x % 8 < 4 else 0), K_LIGHT)
		_px(img, x, h - 2 - (1 if (x + 4) % 8 < 4 else 0), K_MID)
	for y in range(3, h - 3):
		_px(img, 2, y, K_LIGHT)
		_px(img, w - 3, y, K_MID)
	for s: int in [0, 1]:
		var x0 := 1 if s == 0 else w - 2
		var dir := Vector2(-1, -0.6) if s == 0 else Vector2(1, -0.6)
		_kin_leaf(img, Vector2(x0, h / 2.0), dir.normalized(), 3.0, 1.2)

func _kin_codex_frame(img: Image, _f: int) -> void:
	var dark := Color(0.07, 0.07, 0.08, 0.9)
	for y in range(6, 90):
		for x in range(6, 90):
			img.set_pixel(x, y, dark)
	# A vine running round the border, leaves every so often, a bud at each corner.
	var pts: Array = []
	for i in 80:
		var t := i / 80.0 * 4.0
		var side := int(t)
		var u := t - side
		var p: Vector2 = [Vector2(8 + u * 80, 6), Vector2(88, 8 + u * 80), Vector2(88 - u * 80, 89), Vector2(7, 88 - u * 80)][side]
		p += Vector2(0, 1).rotated(side * PI * 0.5) * sin(i * 0.8) * 1.2
		pts.append(p)
	pts.append(pts[0])
	_poly_line(img, pts, K_EDGE, 2)
	_poly_line(img, pts, K_MID)
	for i in range(0, 80, 7):
		var p: Vector2 = pts[i]
		var inward := (Vector2(48, 48) - p).normalized()
		_kin_leaf(img, p, (inward.orthogonal() * (1.0 if i % 14 == 0 else -1.0) - inward * 0.6).normalized(), 5.0, 1.8)
	for c: Vector2 in [Vector2(7, 7), Vector2(88, 7), Vector2(88, 88), Vector2(7, 88)]:
		_disc(img, c, 2.5, K_WHITE)
		_px(img, int(c.x), int(c.y), K_MID)

func _save_kinship_preview() -> void:
	# On a green-gold tint, the way the game shows them.
	var pad := 6
	var width := 0
	var height := pad
	for i in range(kinship_from, previews.size()):
		var sheet: Image = previews[i][1]
		width = maxi(width, sheet.get_width() + pad * 2)
		height += sheet.get_height() + pad
	var out := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	out.fill(Color("#1c2a1c"))
	var tint := Color("#b8e070")
	var y := pad
	for i in range(kinship_from, previews.size()):
		var sheet: Image = (previews[i][1] as Image).duplicate()
		for py in sheet.get_height():
			for px in sheet.get_width():
				var c := sheet.get_pixel(px, py)
				if c.a > 0.0:
					sheet.set_pixel(px, py, Color(c.r * tint.r, c.g * tint.g, c.b * tint.b, c.a))
		out.blend_rect(sheet, Rect2i(Vector2i.ZERO, sheet.get_size()), Vector2i(pad, y))
		y += sheet.get_height() + pad
	out.resize(out.get_width() * 2, out.get_height() * 2, Image.INTERPOLATE_NEAREST)
	out.save_png("res://tools/previews/effects_kinship.png")


# --- Kinships in combat (tower_design.md "Kinships": impact on the Wardens and vines) -------------
func _kinship_combat() -> void:
	_sheet("kin_vine_bead", Vector2i(8, 8), 4, 12, Vector2i(4, 4), true, "kinship", _kin_vine_bead,
		{note = "Runs along the vine from one Warden to the other when a borrowed trait fires (~0.3 s). Drawn moving right: rotate to the vine. Tint with the family colour."})
	_sheet("kin_oldkin_arch", Vector2i(64, 32), 4, 4, Vector2i(0, 31), true, "kinship", _kin_oldkin_arch,
		{note = "Old Kin: a flowering arch over the pair. Anchor (0, 31) = left foot, right foot at (63, 31): stretch along x between the two Wardens' bases (don't scale y). Gentle: ~50-70% alpha. Tint with the family colour."})
	_sheet("harmony_petals_a", Vector2i(32, 32), 6, 16, Vector2i(16, 16), false, "kinship", _harmony_petals.bind(0),
		{note = "Blooming Harmony strike: petals spiral in from the left and open half a flower. Tint with the first Warden's colour; play with harmony_petals_b."})
	_sheet("harmony_petals_b", Vector2i(32, 32), 6, 16, Vector2i(16, 16), false, "kinship", _harmony_petals.bind(1),
		{note = "The other half, from the right; tint with the second Warden's colour."})
	_sheet("harmony_beam", Vector2i(32, 8), 4, 16, Vector2i(0, 4), true, "segment", _harmony_beam,
		{note = "Old Kin Harmony strike: a beam from each Warden to the nightmare (stretch or tile along x, y = 4 on the line, 0.3-0.4 s). White: tint with the Warden's colour lerped ~30% to warm gold (#ffe890)."})
	_sheet("harmony_bloom", Vector2i(32, 32), 6, 16, Vector2i(16, 16), false, "kinship", _harmony_bloom,
		{note = "Where the two harmony_beams meet on the nightmare. Tint with a mix of the two colours (or warm white)."})

func _kin_vine_bead(img: Image, f: int) -> void:
	var c := Vector2(5, 4)
	var pulse: float = [0.0, 0.5, 1.0, 0.5][f]
	# Soft halo, a short trail behind (left), the bright bead.
	for y in 8:
		for x in 8:
			var q := Vector2(x + 0.5, y + 0.5).distance_to(c) / (3.2 + pulse * 0.6)
			if q < 1.0:
				img.set_pixel(x, y, Color(K_LIGHT, snappedf(0.45 * (1.0 - q), 0.05)))
	_px(img, 1, 4, Color(K_MID, 0.5))
	_px(img, 2, 4, Color(K_LIGHT, 0.7))
	_px(img, 3, 4, K_LIGHT)
	_disc(img, c + Vector2(0.5, 0.5), 1.4, K_WHITE)

func _kin_oldkin_arch(img: Image, f: int) -> void:
	# A vine arch from foot to foot (peak at y 6), leaves along it, little five-petal flowers.
	var pts: Array = []
	for s in 33:
		var t := s / 32.0
		pts.append(Vector2(0.5 + t * 63.0, 31.0 - pow(sin(t * PI), 0.55) * 24.0 + sin(t * TAU * 2.0 + f * PI / 2.0) * 0.4 * sin(t * PI)))
	for i in pts.size() - 1:
		_line(img, pts[i], pts[i + 1], K_MID)
		_line(img, (pts[i] as Vector2) + Vector2(0, 1), (pts[i + 1] as Vector2) + Vector2(0, 1), K_DARK)
	# Leaves alternate sides, turning with the arch.
	for i in range(3, 30, 4):
		var p: Vector2 = pts[i]
		var along: Vector2 = ((pts[i + 1] as Vector2) - (pts[i - 1] as Vector2)).normalized()
		var side := along.orthogonal() * (1.0 if i % 8 == 3 else -1.0)
		var sway := 0.15 * sin(f * PI / 2.0 + i)
		_kin_leaf(img, p, (side * 0.8 + along * 0.4).rotated(sway).normalized(), 4.0, 1.4)
	# Flowers along the top, one twinkling in turn.
	var flowers := [8, 13, 16, 19, 24]
	for k in flowers.size():
		var p: Vector2 = pts[flowers[k]] + Vector2(0, -1)
		var lit := k == f % flowers.size() or k == (f + 2) % flowers.size()
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i(-1, 1), Vector2i(1, 1)]:
			_px(img, floori(p.x) + d.x, floori(p.y) + d.y, K_LIGHT)
		_px(img, floori(p.x), floori(p.y), K_WHITE if lit else K_MID)
		if lit:
			_px(img, floori(p.x), floori(p.y) - 2, Color(K_WHITE, 0.6))

func _harmony_petals(img: Image, f: int, side: int) -> void:
	var c := Vector2(16, 16)
	var sgn := -1.0 if side == 0 else 1.0
	if f <= 3:
		# Three petals spiral in from this side, tumbling as they come.
		var t := f / 3.0
		for k in 3:
			var a := (PI if side == 0 else 0.0) + (k - 1) * 0.7 + t * PI * 0.8 * -sgn
			var r := 14.0 * (1.0 - t) + 2.0 + k
			var p := c + Vector2(cos(a), sin(a)) * r
			var dir := (c - p).normalized().rotated(0.6 * sgn + f * 0.8)
			_kin_leaf(img, p - dir * 2.5, dir, 5.0, 2.0)
			_px(img, floori(p.x - dir.x * 3.0), floori(p.y - dir.y * 3.0), Color(K_LIGHT, 0.5))
	else:
		# Half a flower opens on the point (this side's petals), then fades.
		var open: float = [0.0, 0.0, 0.0, 0.0, 0.7, 1.0][f]
		for k in 3:
			var d := Vector2.from_angle(PI * 0.5 + (k + 0.5) * PI / 3.0)  # 120..240 degrees: the left half
			var dir := d if side == 0 else Vector2(-d.x, d.y)
			_kin_leaf(img, c + dir * 1.0, dir, 3.5 + open * 3.5, 2.0 + open * 0.6)
		_disc(img, c, 1.5, K_WHITE)
		if f == 5:
			for k in 3:
				var p := c + Vector2(sgn * (5 + k * 2), -3 + k * 3)
				_px(img, floori(p.x), floori(p.y), Color(K_WHITE, 0.6))

func _harmony_beam(img: Image, f: int) -> void:
	# A bright core, a soft two-pixel glow either side, a pulse running along; light motes above.
	for x in 32:
		var run := (x + f * 3) % 12
		var core := K_WHITE if run < 9 else K_LIGHT
		_px(img, x, 4, core)
		_px(img, x, 3, Color(K_LIGHT, 0.75))
		_px(img, x, 5, Color(K_LIGHT, 0.75))
		_px(img, x, 2, Color(K_MID, 0.3))
		_px(img, x, 6, Color(K_MID, 0.3))
	var dot := (f * 8) % 32
	for d in [-1, 0, 1]:
		_px(img, dot + d, 3, K_WHITE)
		_px(img, dot + d, 5, K_WHITE)
	_px(img, (dot + 12) % 32, 1, Color(K_WHITE, 0.5))
	_px(img, (dot + 22) % 32, 7, Color(K_WHITE, 0.4))

func _harmony_bloom(img: Image, f: int) -> void:
	var c := Vector2(16, 16)
	var t := f / 5.0
	if f < 2:
		_disc(img, c, 4.0 - f * 1.5, K_WHITE)
		_ring(img, c, Vector2(5.5 + f * 2.0, 5.5 + f * 2.0), 1.0, Color(K_LIGHT, 0.9))
	# Five petals open outward, then drift and fade.
	var reach := 3.0 + t * 8.0
	for k in 5:
		var dir := Vector2.from_angle(k * TAU / 5.0 - PI / 2.0 + t * 0.4)
		if f >= 1:
			_kin_leaf(img, c + dir * (reach - 3.0), dir, 3.5 + (1.0 - t) * 2.0, 2.0)
	if f >= 2:
		_ring(img, c, Vector2(8.0 + t * 6.0, 8.0 + t * 6.0), 1.0, Color(K_MID, 0.8 - t * 0.6))
	for k in 6:
		var p := c + Vector2.from_angle(k * TAU / 6.0 + 0.3) * (4.0 + t * 11.0)
		_px(img, floori(p.x), floori(p.y), Color(K_WHITE, 1.0 - t * 0.8))

# --- Rootcurl / Long Way Home pull-back: a visible drag (tower_design.md, Rootling table) ---------
#   root_grab: roots burst out of the ground and wrap a nightmare's feet (frames 0-2 burst, 3-5
#     wrap and hold; 4-5 loop while held), then sink back (6-7). Anchor = the ground under its feet.
#   drag_dust: a soil puff kicked up behind a dragged nightmare; spawn every ~0.1 s along the drag.
#   path_furrow: a groove the drag leaves in the path, a 64x16 segment tiling along x; translucent
#     so it darkens any act's path dirt. Fade it out over ~1 s.

const ROOT_DARK := Color("#5a4028")
const ROOT_MID := Color("#7a5634")
const ROOT_LIGHT := Color("#c8a070")
const ROOT_EDGE := Color("#1e160e")
const SOIL := [Color("#5a4028"), Color("#8a6a44"), Color("#b09070"), Color("#d0b48c")]

func _pull_drag() -> void:
	_sheet("root_grab", Vector2i(48, 32), 8, 12, Vector2i(24, 28), false, "support", _root_grab,
		{note = "Frames 0-2 burst, 3-5 wrap and hold (loop 4-5 while the nightmare is held / dragged), 6-7 sink back. Anchor = ground under the nightmare's feet; draw it under the nightmare with a front copy (or just above it at ~80% alpha).", hold_frames = [4, 5], release_frames = [6, 7]})
	_sheet("drag_dust", Vector2i(16, 16), 5, 14, Vector2i(8, 12), false, "support", _drag_dust,
		{note = "Soil kicked up behind a dragged nightmare; spawn one every ~0.1 s along the drag. Anchor = ground."})
	_sheet("path_furrow", Vector2i(64, 16), 1, 1, Vector2i(0, 8), false, "ground", _path_furrow,
		{note = "Ground decal: tile or stretch along x from where the drag started to where it ended, y = 8 on the line, under the nightmares. Translucent, fade out over ~1 s."})

# One root into `layer`: a curve from `base` bending via `lean` to `top`, grown to `grow` (0..1) of
# its length, tapering from thick to thin, lit on its upper left. Returns its tip.
func _grab_root(layer: Image, base: Vector2, top: Vector2, lean: Vector2, grow: float) -> Vector2:
	var tip := base
	var n := 40
	for s in n + 1:
		var t := s / float(n) * grow
		var p := base.lerp(lean, t).lerp(lean.lerp(top, t), t)
		var r := lerpf(1.7, 0.7, t)
		_disc(layer, p, r, ROOT_MID)
		_disc(layer, p + Vector2(-0.5, -0.5), r * 0.45, ROOT_LIGHT)
		tip = p
	return tip

# Everything in `layer` gets a 1 px dark outline, then goes onto `img`.
func _outlined(img: Image, layer: Image, edge: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		for x in w:
			if layer.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var q := Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and layer.get_pixelv(q).a > 0.0:
					img.set_pixel(x, y, edge)
					break
	img.blend_rect(layer, Rect2i(0, 0, w, h), Vector2i.ZERO)

func _root_grab(img: Image, f: int) -> void:
	var foot := Vector2(24, 24)  # where the feet are wrapped
	var grow: float = [0.35, 0.7, 1.0, 1.0, 1.0, 1.0, 0.6, 0.25][f]
	var wrap: float = [0.0, 0.0, 0.2, 0.7, 1.0, 1.0, 0.4, 0.0][f]
	var roots := [
		[Vector2(6, 29), Vector2(17, 10), Vector2(0, 2)],
		[Vector2(14, 30), Vector2(21, 6), Vector2(8, 0)],
		[Vector2(34, 30), Vector2(27, 6), Vector2(40, 0)],
		[Vector2(42, 29), Vector2(31, 10), Vector2(48, 2)],
	]
	# Torn earth where they break out.
	if f < 7:
		for r: Array in roots:
			var b: Vector2 = r[0]
			_ellipse(img, b + Vector2(0, 0.5), Vector2(4, 1.6), SOIL[0])
			_px(img, floori(b.x) - 4, floori(b.y) - 1, SOIL[2])
			_px(img, floori(b.x) + 3, floori(b.y) - 1, SOIL[1])
	var layer := Image.create_empty(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	var tips: Array = []
	for r: Array in roots:
		# Up and over first, then the tips curl down onto the feet.
		var side := -1.0 if (r[0] as Vector2).x < foot.x else 1.0
		tips.append(_grab_root(layer, r[0], (r[1] as Vector2).lerp(foot + Vector2(side * 3.0, -7.0), wrap),
			(r[2] as Vector2).lerp(foot + Vector2(side * 10.0, -14.0), wrap), grow))
	# The wrap: two coils round the feet, a band each.
	if wrap > 0.3:
		for band in 2:
			var c := foot + Vector2(0, -1 - band * 5)
			var span := PI * 1.1 * wrap
			for s in 30:
				var a := PI / 2.0 - span / 2.0 + span * s / 29.0
				var p := c + Vector2(cos(a) * 8.0, sin(a) * 2.8)
				_disc(layer, p, 0.9, ROOT_MID)
				if sin(a) < 0.5:
					_px(layer, floori(p.x), floori(p.y) - 1, ROOT_LIGHT)
	_outlined(img, layer, ROOT_EDGE)
	# Warm glowing tips while they reach and hold.
	if f <= 5:
		for tip: Vector2 in tips:
			_px(img, floori(tip.x), floori(tip.y), WARM)
			for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i(1, -1), Vector2i(-1, -1)]:
				var q := Vector2i(tip.floor()) + d
				if q.x >= 0 and q.y >= 0 and q.x < 48 and q.y < 32 and img.get_pixelv(q).a == 0.0:
					img.set_pixelv(q, Color(GOLD, 0.45))
	# A leaf sprouting from the coils and a warm pulse along them while it holds.
	if f in [4, 5]:
		_px(img, floori(foot.x) + 6, floori(foot.y) - 8, Color("#7cbc5a"))
		_px(img, floori(foot.x) + 7, floori(foot.y) - 9, Color("#a8dc78"))
		_px(img, floori(foot.x) - 7, floori(foot.y) - 4, Color("#7cbc5a"))
		for s in 5:
			var p := foot + Vector2(-6 + s * 3, 1)
			_px(img, floori(p.x), floori(p.y), Color(WARM, 0.9 if (s + f) % 2 == 0 else 0.5))
	# Sinking back: crumbs of soil falling in.
	if f >= 6:
		for r: Array in roots:
			var b: Vector2 = r[0]
			_px(img, floori(b.x) - 1, floori(b.y) - (f - 5), SOIL[2])
			_px(img, floori(b.x) + 1, floori(b.y) - (f - 4), SOIL[1])

func _drag_dust(img: Image, f: int) -> void:
	var c := Vector2(8, 12)
	var t := f / 4.0
	# Three clumps puffing up and back, fading; a couple of clods thrown out.
	for k in 3:
		var p := c + Vector2(-2.0 + k * 2.5, -t * (3.0 + k)) + Vector2(-t * 2.0, 0)
		var r := 1.6 + t * 2.2 - k * 0.3
		_disc(img, p, r, Color(SOIL[1], 0.9 - t * 0.7))
		_disc(img, p + Vector2(-0.5, -0.6), r * 0.55, Color(SOIL[3], 0.85 - t * 0.7))
	if f < 4:
		_px(img, floori(c.x - 4 - t * 4), floori(c.y - 2 - t * 3 + t * t * 6), SOIL[0])
		_px(img, floori(c.x + 3 + t * 2), floori(c.y - 3 - t * 2 + t * t * 5), SOIL[1])

func _path_furrow(img: Image, _f: int) -> void:
	# Two grooves (dark), churned ridges beside them (light), clods; tiles every 64 px.
	for x in 64:
		var wob := sin(x * TAU / 64.0 * 2.0) * 0.6
		for g: float in [5.5, 10.5]:
			var y := g + wob
			_px(img, x, floori(y), Color(0.12, 0.08, 0.04, 0.55))
			_px(img, x, floori(y) + 1, Color(0.12, 0.08, 0.04, 0.3))
			if (x * 7) % 5 != 0:
				_px(img, x, floori(y) - 1, Color(0.9, 0.8, 0.62, 0.3))
		if x % 9 == 3:
			_px(img, x, 2 + (x % 2), Color(0.35, 0.25, 0.15, 0.5))
			_px(img, (x + 4) % 64, 13 + (x % 3), Color(0.35, 0.25, 0.15, 0.45))
	# The middle, pressed flat and a touch darker.
	for x in 64:
		for y in range(7, 10):
			if img.get_pixel(x, y).a == 0.0:
				img.set_pixel(x, y, Color(0.1, 0.07, 0.03, 0.15))

# --- Support and economy feedback (screens_ui.md "Support and economy feedback") -------------------
# Kind "support". Gold is caught / harvested Dew (the ordinary Dew pop stays blue).
#   dew_catch_droplet: a gold dew bead, drawn flying right (rotate to travel), shimmering; the code
#     arcs it from a dispelled nightmare into a Dewcatcher / Wellspring. harvest_pour reuses it.
#   dew_pop_gold: a small gold sparkle burst to play behind the "+N Dew" of caught Dew.
#   catcher_fill_dewcatcher / catcher_fill_wellspring: 64x64 overlays drawn to line up with the
#     Warden sprite (same origin), frame = fill level 0 empty, 1 quarter, 2 half, 3 full. Add the
#     idle frame's bob (attacks.json bowls.<id>.dy_by_frame) to y.
#   harvest_pour: droplets leaping out of the bowl at a rest (play at the bowl; then fly
#     dew_catch_droplet beads to the Dew counter). harvest_splash: where they land on the counter.
#   leaf_mote: a faint tiny leaf drifting and turning, near-white so it can be tinted.
#   aura_ring_breath: a soft ring that breathes; white, tint it and scale it to the aura's range.

const DEW_GOLD := [Color("#a8641c"), Color("#e8a830"), Color("#ffd870"), Color("#fff4c8")]

func _support() -> void:
	_sheet("dew_catch_droplet", Vector2i(14, 14), 6, 12, Vector2i(7, 7), true, "support", _dew_droplet,
		{note = "Drawn flying right; rotate to its travel. Arc it into the catcher; harvest_pour reuses it."})
	_sheet("dew_pop_gold", Vector2i(24, 24), 6, 14, Vector2i(12, 12), false, "support", _dew_pop_gold,
		{note = "Behind the \"+N Dew\" of caught Dew; draw that text in gold (#ffd870) instead of blue."})
	_sheet("catcher_fill_dewcatcher", Vector2i(64, 64), 4, 1, Vector2i(32, 32), false, "support", _catcher_fill.bind(false),
		{note = "Frame = fill level (0 empty .. 3 full), not animation. Same origin as the Warden sprite; add bowls.dewcatcher.dy_by_frame[idle frame] to y."})
	_sheet("catcher_fill_wellspring", Vector2i(64, 64), 4, 1, Vector2i(32, 32), false, "support", _catcher_fill.bind(true),
		{note = "Frame = fill level (0 empty .. 3 full). Same origin as the Warden sprite; add bowls.wellspring.dy_by_frame[idle frame] to y."})
	_sheet("harvest_pour", Vector2i(40, 40), 8, 14, Vector2i(20, 32), false, "support", _harvest_pour,
		{note = "At the bowl (anchor = bowl surface): droplets leap up and out. Then fly dew_catch_droplet beads to the Dew counter (~0.8 s)."})
	_sheet("harvest_splash", Vector2i(32, 32), 6, 14, Vector2i(16, 16), false, "support", _harvest_splash,
		{note = "UI: where the harvested Dew lands on the Dew counter."})
	_sheet("leaf_mote", Vector2i(10, 10), 8, 6, Vector2i(5, 5), true, "support", _leaf_mote,
		{note = "Near-white, tint it. Very subtle: drift it slowly upward over aura-boosted Wardens, low alpha."})
	_sheet("aura_ring_breath", Vector2i(64, 64), 8, 6, Vector2i(32, 32), true, "support", _aura_ring,
		{note = "White, tint it and scale it to the aura's range (64 px = 1 cell radius 28). Brighter (higher alpha) in build mode."})

func _dew_droplet(img: Image, f: int) -> void:
	# A bead with a short tail behind it (pointing right), the glint sliding round.
	var c := Vector2(8.5, 7.5)
	for step in 8:
		var t := step / 7.0
		var r := 3.2 * (1.0 - t * 0.85)
		_disc(img, c + Vector2(-t * 5.0, 0), r, DEW_GOLD[1])
	_disc(img, c, 3.2, DEW_GOLD[1])
	_disc(img, c + Vector2(-0.4, -0.6), 2.2, DEW_GOLD[2])
	var glint: Vector2i = [Vector2i(9, 5), Vector2i(10, 6), Vector2i(10, 7), Vector2i(9, 6), Vector2i(8, 5), Vector2i(8, 6)][f]
	_px(img, glint.x, glint.y, DEW_GOLD[3])
	_px(img, glint.x, glint.y - 1 if f % 3 == 0 else glint.y, DEW_GOLD[3])
	# Outline, then a faint warm glow.
	var outline := img.duplicate()
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var q := Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height() and img.get_pixelv(q).a > 0.9:
					outline.set_pixel(x, y, DEW_GOLD[0])
					break
	img.copy_from(outline)
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a == 0.0:
				var q := Vector2(x + 0.5, y + 0.5).distance_to(c) / 6.5
				if q < 1.0:
					img.set_pixel(x, y, Color(DEW_GOLD[2], snappedf(0.3 * (1.0 - q), 0.05)))

func _dew_pop_gold(img: Image, f: int) -> void:
	var c := Vector2(12, 12)
	var t := f / 5.0
	# A quick ring and eight motes flying out and fading.
	if f < 3:
		_ring(img, c, Vector2(3.0 + f * 3.0, 3.0 + f * 3.0), 1.0, Color(DEW_GOLD[2], 0.9 - f * 0.25))
	for k in 8:
		var d := Vector2.from_angle(k * TAU / 8.0 + 0.2)
		var p := c + d * (3.0 + t * 8.0)
		var col: Color = DEW_GOLD[3] if k % 2 == 0 else DEW_GOLD[2]
		_px(img, floori(p.x), floori(p.y), Color(col, 1.0 - t * 0.8))
		if f < 2 and k % 2 == 0:
			_px(img, floori(p.x - d.x), floori(p.y - d.y), Color(DEW_GOLD[1], 0.7))
	if f == 0:
		_disc(img, c, 2.5, DEW_GOLD[3])

func _catcher_fill(img: Image, f: int, well: bool) -> void:
	# The bowl's inside (same ellipse as the sprite's water), empty-dark first, then gold dew from
	# the middle out. Full glows and brims over with a sparkle.
	var c := Vector2(30.5, 5.5) if well else Vector2(30.5, 5.0)
	var r := Vector2(7.5, 1.6) if well else Vector2(11, 2.2)
	var empty := Color("#3a2a1c") if well else Color("#2a3a20")
	_ellipse(img, c, r, empty)
	if f == 0:
		_px(img, floori(c.x) - 2, floori(c.y), Color("#5a4a34") if well else Color("#3e5430"))
		return
	var share: float = [0.0, 0.4, 0.7, 1.0][f]
	var fill_r := Vector2(r.x * share, maxf(r.y * (0.55 + share * 0.45), 1.0))
	_ellipse(img, c, fill_r, DEW_GOLD[1])
	_line(img, c + Vector2(-fill_r.x * 0.6, -fill_r.y * 0.4), c + Vector2(fill_r.x * 0.5, -fill_r.y * 0.4), DEW_GOLD[2])
	if f >= 2:
		_px(img, floori(c.x) + 1, floori(c.y) - 1, DEW_GOLD[3])
	if f == 3:
		# Brimming: the glow rises off it, a bead on the rim, a sparkle.
		for x in range(floori(c.x - r.x) - 1, ceili(c.x + r.x) + 2):
			for y in range(0, floori(c.y)):
				var q := ((Vector2(x + 0.5, y + 0.5) - c) / Vector2(r.x + 2.0, 5.0)).length()
				if q < 1.0 and img.get_pixel(x, y).a == 0.0:
					img.set_pixel(x, y, Color(DEW_GOLD[2], snappedf(0.35 * (1.0 - q), 0.05)))
		_px(img, floori(c.x + r.x) - 1, floori(c.y) + 1, DEW_GOLD[2])
		_px(img, floori(c.x + r.x) - 1, floori(c.y) + 2, DEW_GOLD[1])
		for d: Vector2i in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
			_px(img, floori(c.x) - 4 + d.x, floori(c.y) - 2 + d.y, DEW_GOLD[3])

func _harvest_pour(img: Image, f: int) -> void:
	# Beads leap out of the bowl (anchor (20, 32)) in fountain arcs, rising and spreading.
	var base := Vector2(20, 32)
	if f < 3:
		_ellipse(img, base, Vector2(6 - f, 1.5), Color(DEW_GOLD[2], 0.8 - f * 0.2))
	for k in 6:
		var start := k * 0.6
		var t := (f - start) / 5.0
		if t <= 0.0 or t > 1.2:
			continue
		var side := -1.0 if k % 2 == 0 else 1.0
		var p := base + Vector2(side * (2.0 + k) * t * 2.2, -t * 26.0 + t * t * 6.0)
		_disc(img, p, 1.8 if k < 4 else 1.3, DEW_GOLD[2])
		_px(img, floori(p.x), floori(p.y) - 1, DEW_GOLD[3])
		_px(img, floori(p.x), floori(p.y) + 2, Color(DEW_GOLD[1], 0.6))

func _harvest_splash(img: Image, f: int) -> void:
	var c := Vector2(16, 16)
	var t := f / 5.0
	if f < 2:
		_disc(img, c, 4.5 - f * 1.5, DEW_GOLD[3])
	_ring(img, c, Vector2(4.0 + t * 11.0, 4.0 + t * 11.0), 1.5 if f < 3 else 1.0, Color(DEW_GOLD[2], 1.0 - t * 0.85))
	for k in 6:
		var d := Vector2.from_angle(k * TAU / 6.0 - PI / 2.0)
		var p := c + d * (5.0 + t * 9.0) + Vector2(0, t * t * 4.0)
		_px(img, floori(p.x), floori(p.y), Color(DEW_GOLD[3] if k % 2 == 0 else DEW_GOLD[1], 1.0 - t * 0.7))

func _leaf_mote(img: Image, f: int) -> void:
	# A tiny leaf turning as it drifts: its width swings with the turn so it seems to tumble.
	var turn := sin(f * TAU / 8.0)
	var c := Vector2(5, 5 + sin(f * TAU / 8.0 + 1.0) * 0.8)
	var w := maxf(0.6, absf(turn) * 1.8)
	var a := 0.6 + f * TAU / 16.0
	var along := Vector2.from_angle(a)
	for y in 10:
		for x in 10:
			var d := Vector2(x + 0.5, y + 0.5) - c
			var u := d.dot(along)
			var v := d.dot(along.orthogonal())
			if absf(u) <= 3.4 and absf(v) <= w * (1.0 - pow(u / 3.4, 2.0)):
				img.set_pixel(x, y, Color("#f4fff0") if v * turn < 0.0 else Color("#c8dcc0"))
	var stem := c - along * 4.0
	_px(img, floori(stem.x), floori(stem.y), Color("#c8dcc0", 0.8))

func _aura_ring(img: Image, f: int) -> void:
	# Radius 28 breathing ±1.5 px; bright thread with a soft inside fade, four small nodes turning.
	var c := Vector2(32, 32)
	var br := sin(f * TAU / 8.0)
	var r := 28.0 + br * 1.5
	for y in 64:
		for x in 64:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			var edge := absf(d - r)
			if edge < 0.8:
				img.set_pixel(x, y, Color(1, 1, 1, 0.75 + br * 0.1))
			elif d < r and r - d < 6.0:
				img.set_pixel(x, y, Color(1, 1, 1, snappedf(0.22 * (1.0 - (r - d) / 6.0), 0.04)))
	for k in 4:
		var p := c + Vector2.from_angle(k * TAU / 4.0 + f * TAU / 32.0) * r
		for dd: Vector2i in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			_px(img, floori(p.x) + dd.x, floori(p.y) + dd.y, Color(1, 1, 1, 0.95 if dd == Vector2i.ZERO else 0.6))

# --- Lingering clouds (PathCloud: Bloomcap / Dreamshroom sleepy clouds, Mistveil / Morning Fog) ----
# Near-white so PathCloud can tint them with the Warden's colour (modulate multiplies). Drawn at 1x.
#   cloud_puffs: 4 variants (not an animation) of a fairytale cloud puff: round lobes lit from the
#     top left, a soft seam between lobes, a curl in the biggest one, soft translucent edges.
#   fog_wisps: 3 variants of a long tapering fog strand ending in a curl, drifted across fog clouds.

const CLOUD_LIGHT := Color("#ffffff")
const CLOUD_MID := Color("#eef0f8")
const CLOUD_SHADE := Color("#d0d6ea")
const CLOUD_DEEP := Color("#a8b0cc")
const CLOUD_SEAM := Color("#b8c0da")

func _clouds() -> void:
	_sheet("cloud_puffs", Vector2i(48, 32), 4, 1, Vector2i(24, 20), false, "ground", _cloud_puff,
		{note = "Variants, not frames: PathCloud picks one per puff and tints it with projectile_color."})
	_sheet("fog_wisps", Vector2i(56, 14), 3, 1, Vector2i(28, 7), false, "ground", _fog_wisp,
		{note = "Variants: fog strands PathCloud drifts across fog clouds (cloud_fog)."})

func _cloud_puff(img: Image, f: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7100 + f * 31
	# Lobes: a low row of four, one or two on top; the front (lower) ones are drawn over the back.
	var blobs: Array = []
	var base_y := 22.0
	for k in 4:
		var r := rng.randf_range(6.5, 8.5)
		blobs.append([Vector2(8.5 + k * 10.3 + rng.randf_range(-1.0, 1.0), base_y - r * 0.3 + rng.randf_range(-1, 1)), r])
	for k in (2 if f % 2 == 0 else 1):
		var r := rng.randf_range(8.5, 11.0)
		blobs.append([Vector2(18.0 + k * 13.0 + rng.randf_range(-2, 2), 13.5 + rng.randf_range(-1.5, 1.0)), r])
	var owner := {}
	for y in img.get_height():
		for x in img.get_width():
			var p := Vector2(x + 0.5, y + 0.5)
			var best := -1
			var best_v := 0.0
			for i in blobs.size():
				var c: Vector2 = blobs[i][0]
				var r: float = blobs[i][1]
				var v := 1.0 - p.distance_to(c) / r
				# Lobes in front (lower centre) win where they overlap, so seams follow their tops.
				if v > 0.0 and (best < 0 or c.y > (blobs[best][0] as Vector2).y + 0.5 or (v > best_v and absf(c.y - (blobs[best][0] as Vector2).y) <= 0.5)):
					best = i
					best_v = v
			if best < 0 or y > 29:
				continue
			owner[Vector2i(x, y)] = best
			var c: Vector2 = blobs[best][0]
			var r: float = blobs[best][1]
			var n2 := (p - c) / r
			# Lit from above like a painted cloud (not a sphere): bright crown, soft middle, shaded base.
			var i := -n2.y * 0.85 - n2.x * 0.25
			var col := CLOUD_LIGHT if i > 0.5 else (CLOUD_MID if i > -0.05 else (CLOUD_SHADE if i > -0.6 else CLOUD_DEEP))
			if y >= 27:
				col = CLOUD_DEEP  # the flat underside
			var a := 0.92
			if best_v < 0.1:
				a = 0.5  # soft edge
			img.set_pixel(x, y, Color(col, a))
	# Seams: where a front lobe's top edge crosses a back lobe.
	for key: Vector2i in owner:
		var up := key + Vector2i(0, -1)
		if owner.has(up) and owner[up] != owner[key] and (blobs[owner[key]][0] as Vector2).y > (blobs[owner[up]][0] as Vector2).y:
			img.set_pixel(key.x, key.y, Color(CLOUD_SEAM, 0.95))

func _fog_wisp(img: Image, f: int) -> void:
	var w := img.get_width()
	var phase := f * 1.7
	for x in range(2, w - 6):
		var t := x / float(w - 6)
		var cy := 7.0 + sin(x * 0.16 + phase) * 1.8
		var thick := 3.2 * pow(sin(PI * clampf(t * 1.1, 0.0, 1.0)), 0.7)
		for y in img.get_height():
			var d := (y + 0.5 - cy) / maxf(thick, 0.01)
			if absf(d) > 1.0:
				continue
			var col := CLOUD_LIGHT if d < -0.3 else (CLOUD_MID if d < 0.4 else CLOUD_SHADE)
			var a := 0.75 * (1.0 - t * 0.35)
			if absf(d) > 0.7:
				a *= 0.55
			img.set_pixel(x, y, Color(col, a))

# --- Preview ----------------------------------------------------------------------------------------

func _save_preview() -> void:
	var pad := 8
	var width := 0
	var height := pad
	for p in previews:
		var sheet: Image = p[1]
		width = maxi(width, sheet.get_width() + pad * 2)
		height += sheet.get_height() + pad
	var out := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	out.fill(Color("#1c1a2c"))
	var y := pad
	for p in previews:
		var sheet: Image = p[1]
		out.blend_rect(sheet, Rect2i(Vector2i.ZERO, sheet.get_size()), Vector2i(pad, y))
		y += sheet.get_height() + pad
	out.resize(out.get_width() * 2, out.get_height() * 2, Image.INTERPOLATE_NEAREST)
	out.save_png(PREVIEW)
