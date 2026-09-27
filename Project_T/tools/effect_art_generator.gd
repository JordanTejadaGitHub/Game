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
	var file := FileAccess.open(OUT + "effects.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({effects = index}, "\t") + "\n")
	_save_preview()
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
