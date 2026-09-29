extends "res://tools/tower_art_generator.gd"
# Generates the endgame art in assets/towers/ascended/ (tower_design.md "Ascended forms",
# run_design.md "The Heartwood Sapling"):
# - the 9 Ascended Wardens: the family's golem grown huge, rising off its (lush) 64 px waystone, with
#   a halo behind the head. 128x128 frames, 8-frame idle + 6-frame attack (release on frame 2) like
#   every Warden. The waystone sits at BASE_AT, so the cell centre is (64, 96) in the frame: draw
#   the sprite offset by (0, -32) and the normal rank art lines up with the slab.
# - the effects they put in the world (tide wave, Dawnwing's bird, the Tempest's cyclone, Old
#   Mountain's boulder and impact, World Root's grasp),
# - the Heartwood Sapling: 2x2 cells, 128x160 frames (footprint centre (64, 96)).
# Frame sizes, anchors and attack points: assets/towers/ascended/ascended.json.
# Run:  Godot --headless --path . --script res://tools/ascended_art_generator.gd

const W := 160  # frame size; the figure and its waystone are drawn on a 128 px layer (L) placed at LAYER_AT
const H := 160
const L := 128
const LAYER_AT := Vector2i(16, 8)
const DAIS := Vector2(80, 118)  # centre of the dais top face (frame px)
const AOUT := "res://assets/towers/ascended/"
const BASE_AT := Vector2i(32, 64)
var HEAD := Vector2(60, 44)  # the figure's head centre on the layer (set by _place_figure)

# name: [waystone theme, figure palette (outline, light, mid, shadow), halo colour, attack kind,
# attack point in frame px].
const ASCENDED := {
	"sporemother": ["fairy_ring", ["#17174d", "#ed9df2", "#de73e5", "#ba41d9"], "#ffc0e8", "storm", Vector2i(63, 20)],
	"tidecaller": ["pond", ["#16305e", "#9ad4ff", "#5aa8ec", "#3a78c8"], "#bfe8ff", "tide", Vector2i(100, 40)],
	"stormheart": ["night", ["#1a2230", "#5a8492", "#46707e", "#325260"], "#ffe070", "chain", Vector2i(64, 76)],
	"old_mountain": ["cobble", ["#1c1c36", "#c4c9e2", "#979dc2", "#686d9a"], "#e8ecff", "crush", Vector2i(63, 6)],
	"world_root": ["stump", ["#24160e", "#c09268", "#9a6e48", "#7a5234"], "#d8f0a0", "hold", Vector2i(64, 96)],
	"the_great_bell": ["bellflower", ["#22183a", "#e0d0f8", "#c0a8ec", "#9a80d0"], "#ffe8a0", "toll", Vector2i(64, 84)],
	"grandmother_oak": ["leaf_litter", ["#2a1a10", "#f0c080", "#d49c54", "#b07a3a"], "#ffe0a0", "aura", Vector2i(64, 96)],
	"dawnwing": ["nest", ["#2a1a10", "#f4e0c0", "#dcc098", "#b89870"], "#ffd0a0", "circle", Vector2i(64, 14)],
	"the_tempest": ["windswept", ["#1e3a30", "#e8fff0", "#c0ecd8", "#90c8b0"], "#e8fff0", "cyclone", Vector2i(64, 10)],
}
const GOLD := ["#a86a1a", "#e0a030", "#ffd860", "#fff8d0"]
const MAPLE_SEED := ["#b0602e", "#e0a060", "#f8d8a0"]

func _is_extension() -> bool:
	return true

func _init() -> void:
	var stretch: Array = POSE_UP.slice(0, 13) + POSE_UP.slice(12)
	poses = [_parse(POSE_UP), _parse(POSE_DOWN), _parse(stretch, TOP - 1)]
	_place_figure()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(AOUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEWS))
	var rows: Array = []
	for warden: String in ASCENDED:
		var idle := _gsheet(warden + ".png", FRAMES, W, H, func(cv: Image, f: int) -> void: _draw_ascended(warden, cv, _idle_state(f)), true)
		var attack := _gsheet(warden + "_attack.png", ATTACK_FRAMES, W, H, func(cv: Image, a: int) -> void: _draw_ascended(warden, cv, _attack_state(a)), true)
		rows.append([idle, attack])
	var empty := _gsheet("dawnwing_empty.png", FRAMES, W, H, func(cv: Image, f: int) -> void:
		var st := _idle_state(f)
		st["empty"] = true
		_draw_ascended("dawnwing", cv, st), true)
	rows.append([empty, null])
	_save_rows(rows, W, H, PREVIEWS + "ascended.png", 2)
	var fx: Array = []
	fx.append(_gsheet("tide_wave.png", 8, 64, 64, _tide_wave))
	fx.append(_gsheet("dawnwing_bird.png", 8, 64, 64, _dawn_bird))
	fx.append(_gsheet("tempest_cyclone.png", 8, 64, 80, _cyclone))
	fx.append(_gsheet("mountain_boulder.png", 4, 32, 32, _mountain_boulder))
	fx.append(_gsheet("mountain_impact.png", 6, 192, 192, _mountain_impact))
	fx.append(_gsheet("root_grasp.png", 6, 64, 64, _root_grasp))
	_save_fx_preview(fx, PREVIEWS + "ascended_effects.png")
	var sap: Array = []
	sap.append(_gsheet("heartwood_sapling.png", FRAMES, 128, 160, func(cv: Image, f: int) -> void: _sapling(cv, f, 0, false, -1), true))
	sap.append(_gsheet("heartwood_sapling_ripen.png", 6, 128, 160, func(cv: Image, a: int) -> void: _sapling(cv, a, a, false, -1), true))
	sap.append(_gsheet("heartwood_sapling_withered.png", FRAMES, 128, 160, func(cv: Image, f: int) -> void: _sapling(cv, f, 0, true, -1), true))
	sap.append(_gsheet("heartwood_sapling_ranks.png", 5, 128, 160, func(cv: Image, r: int) -> void: _sapling_rank(cv, r + 1)))
	_save_rows([[sap[0], sap[1]], [sap[2], null], [sap[3], null]], 128, 160, PREVIEWS + "heartwood_sapling.png", 2)
	_save_info()
	print("ascended art written")
	quit()

func _gsheet(file: String, n: int, w: int, h: int, draw: Callable, warden_art: bool = false) -> Image:
	var sheet := Image.create_empty(w * n, h, false, Image.FORMAT_RGBA8)
	for i in n:
		var cv := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
		draw.call(cv, i)
		sheet.blit_rect(cv, Rect2i(0, 0, w, h), Vector2i(i * w, 0))
	if warden_art:
		sheet = _detail_pass(sheet, Vector2i(w, h))  # the palette pass, like every Warden sheet
	sheet.save_png(AOUT + file)
	return sheet

func _save_info() -> void:
	var wardens := {}
	for warden: String in ASCENDED:
		var p: Vector2i = ASCENDED[warden][4]
		wardens[warden] = {kind = ASCENDED[warden][3], point = [p.x + LAYER_AT.x, p.y + LAYER_AT.y]}
	var data := {
		frame_size = [W, H], anchor = [80, 104], sprite_offset = [0, -24], frames = FRAMES,
		attack_frames = ATTACK_FRAMES, release_frame = RELEASE_FRAME, wardens = wardens,
		dawnwing_empty = "dawnwing_empty.png",
		effects = {
			tide_wave = {frame_size = [64, 64], frames = 8, anchor = [32, 48], loop = true, faces = "right"},
			dawnwing_bird = {frame_size = [64, 64], frames = 8, anchor = [32, 32], loop = true, faces = "right"},
			tempest_cyclone = {frame_size = [64, 80], frames = 8, anchor = [32, 72], loop = true},
			mountain_boulder = {frame_size = [32, 32], frames = 4, anchor = [16, 16], loop = true},
			mountain_impact = {frame_size = [192, 192], frames = 6, anchor = [96, 96], loop = false},
			root_grasp = {frame_size = [64, 64], frames = 6, anchor = [32, 44], loop = false},
		},
		sapling = {
			frame_size = [128, 160], anchor = [64, 96], sprite_offset = [0, -16], cells = [2, 2],
			idle = "heartwood_sapling.png", idle_frames = FRAMES,
			ripen = "heartwood_sapling_ripen.png", ripen_frames = 6, ripen_release_frame = 3,
			withered = "heartwood_sapling_withered.png",
			ranks = "heartwood_sapling_ranks.png", rank_frames = 5,
		},
	}
	var file := FileAccess.open(AOUT + "ascended.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t") + "\n")

# --- Size-aware primitives (the parent's are fixed to 64 px) -------------------------------------

func _in(img: Image, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height()

func _gpx(img: Image, x: int, y: int, color: Color) -> void:
	if _in(img, x, y):
		img.set_pixel(x, y, color)

func _gnew(img: Image) -> Image:
	return Image.create_empty(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)

# Shaded (optionally rotated) ellipse; rows outside [min_y, max_y] are cut off.
func _gell(layer: Image, c: Vector2, r: Vector2, ramp: Array[Color], angle: float = 0.0, max_y: float = INF, min_y: float = -INF) -> void:
	var e := maxf(r.x, r.y)
	for y in range(maxi(0, floori(c.y - e)), mini(layer.get_height(), ceili(c.y + e) + 1)):
		for x in range(maxi(0, floori(c.x - e)), mini(layer.get_width(), ceili(c.x + e) + 1)):
			var p := Vector2(x + 0.5, y + 0.5)
			if p.y > max_y or p.y < min_y:
				continue
			var d := (p - c).rotated(-angle) / r
			var q := d.length_squared()
			if q <= 1.0:
				var n := d.rotated(angle)
				layer.set_pixel(x, y, _shade(ramp, Vector3(n.x, n.y, sqrt(1.0 - q))))

func _gflat(layer: Image, c: Vector2, r: Vector2, color: Color) -> void:
	for y in range(maxi(0, floori(c.y - r.y)), mini(layer.get_height(), ceili(c.y + r.y) + 1)):
		for x in range(maxi(0, floori(c.x - r.x)), mini(layer.get_width(), ceili(c.x + r.x) + 1)):
			if ((Vector2(x + 0.5, y + 0.5) - c) / r).length_squared() <= 1.0:
				layer.set_pixel(x, y, color)

func _gpoly(layer: Image, pts: PackedVector2Array, ramp: Array[Color], facets: bool = false) -> void:
	var rect := Rect2(pts[0], Vector2.ZERO)
	var centre := Vector2.ZERO
	for p in pts:
		rect = rect.expand(p)
		centre += p
	centre /= pts.size()
	for y in range(maxi(0, floori(rect.position.y)), mini(layer.get_height(), ceili(rect.end.y) + 1)):
		for x in range(maxi(0, floori(rect.position.x)), mini(layer.get_width(), ceili(rect.end.x) + 1)):
			var p := Vector2(x + 0.5, y + 0.5)
			if not Geometry2D.is_point_in_polygon(p, pts):
				continue
			var n := Vector3(0, -0.3, 1)
			if facets and (p - centre).length() > 2.0:
				var a := snappedf((p - centre).angle(), TAU / 6.0)
				n = Vector3(cos(a), sin(a), 0.8)
			elif not facets:
				var d := (p - centre) / (rect.size * 0.5)
				n = Vector3(d.x, d.y, 0.8)
			layer.set_pixel(x, y, _shade(ramp, n.normalized()))

func _gstroke(layer: Image, pts: Array, r: float, color: Color) -> void:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var box := Rect2(a, Vector2.ZERO).expand(b).grow(r + 1)
		for y in range(maxi(0, floori(box.position.y)), mini(layer.get_height(), ceili(box.end.y))):
			for x in range(maxi(0, floori(box.position.x)), mini(layer.get_width(), ceili(box.end.x))):
				var p := Vector2(x + 0.5, y + 0.5)
				var t := clampf((p - a).dot(b - a) / maxf((b - a).length_squared(), 0.001), 0.0, 1.0)
				if p.distance_to(a.lerp(b, t)) <= r:
					layer.set_pixel(x, y, color)

func _gline(img: Image, pts: Array, color: Color, mask: Image = null) -> void:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
		for s in steps + 1:
			var p := a.lerp(b, s / maxf(steps, 1.0)).round()
			if mask == null or (_in(mask, int(p.x), int(p.y)) and mask.get_pixel(int(p.x), int(p.y)).a > 0.0):
				_gpx(img, int(p.x), int(p.y), color)

func _gstamp(canvas: Image, layer: Image, outline: Color = Color(0, 0, 0, 0)) -> void:
	var w := layer.get_width()
	var h := layer.get_height()
	for y in h:
		for x in w:
			var col := layer.get_pixel(x, y)
			if col.a == 0.0:
				continue
			if outline.a > 0.0:
				for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var p: Vector2i = Vector2i(x, y) + d
					if p.x < 0 or p.y < 0 or p.x >= w or p.y >= h or layer.get_pixelv(p).a == 0.0:
						col = outline
						break
			canvas.set_pixel(x, y, col)

# Dithered light on empty pixels only (draw it last).
func _gglow(canvas: Image, c: Vector2, r: Vector2, inner: Color, outer: Color, phase: int = 0, density: int = 2) -> void:
	for y in range(maxi(0, floori(c.y - r.y)), mini(canvas.get_height(), ceili(c.y + r.y) + 1)):
		for x in range(maxi(0, floori(c.x - r.x)), mini(canvas.get_width(), ceili(c.x + r.x) + 1)):
			if canvas.get_pixel(x, y).a > 0.0:
				continue
			var q := ((Vector2(x + 0.5, y + 0.5) - c) / r).length()
			if q < 0.55 and (x + y + phase) % density == 0 and (density == 2 or (x + 2 * y) % density == 0):
				canvas.set_pixel(x, y, inner)
			elif q < 1.0 and density == 2 and (x + 2 * y + phase) % 4 == 0:
				canvas.set_pixel(x, y, outer)

# A dotted ellipse ring (ground rings, halos, toll waves).
func _gring(canvas: Image, c: Vector2, r: Vector2, color: Color, step: int = 1, phase: int = 0, only_empty: bool = false) -> void:
	var n := int(TAU * maxf(r.x, r.y) * 1.2)
	for k in n:
		if step > 1 and (k + phase) % step != 0:
			continue
		var p := c + Vector2(cos(k * TAU / n), sin(k * TAU / n)) * r
		var x := floori(p.x)
		var y := floori(p.y)
		if only_empty and _in(canvas, x, y) and canvas.get_pixel(x, y).a > 0.0:
			continue
		_gpx(canvas, x, y, color)

func _gsparkle(canvas: Image, p: Vector2i, core: Color, arm: Color, big: bool = false) -> void:
	for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		_gpx(canvas, p.x + d.x, p.y + d.y, arm)
		if big:
			_gpx(canvas, p.x + d.x * 2, p.y + d.y * 2, arm)
	_gpx(canvas, p.x, p.y, core)

func _gbolt(canvas: Image, a: Vector2, b: Vector2, core: Color, glow: Color, seed_i: int, kinks: int = 5) -> void:
	var pts: Array = [a]
	var normal := (b - a).orthogonal().normalized()
	for k in range(1, kinks):
		var t := float(k) / kinks
		var off := (float((seed_i * 37 + k * 53) % 11) - 5.0) * 0.9
		pts.append(a.lerp(b, t) + normal * off)
	pts.append(b)
	for i in pts.size() - 1:
		var p0: Vector2 = pts[i]
		var p1: Vector2 = pts[i + 1]
		for o: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
			_gline(canvas, [p0 + o, p1 + o], glow)
	_gline(canvas, pts, core)

func _ramp_of(pal: Array) -> Array[Color]:
	# [outline, light, mid, shadow] -> shading ramp [shadow, mid, light, highlight]
	return _ramp([pal[3], pal[2], pal[1], Color(pal[1]).lightened(0.3).to_html()])

# Rising motes: each mote climbs `rise` px over the loop and fades.
func _gmotes(canvas: Image, st: Dictionary, xs: Array, from_y: float, rise: float, colors: Array) -> void:
	for k in xs.size():
		var t: float = fposmod(float(st.f) / st.n + k * 0.37, 1.0)
		var col: Color = colors[k % colors.size()]
		var x: int = xs[k] + roundi(sin((t + k) * TAU) * 2)
		var y := roundi(from_y - t * rise)
		_gpx(canvas, x, y, col)
		if t < 0.5:
			_gpx(canvas, x, y + 1, col.darkened(0.2))

# --- The Ascended golem --------------------------------------------------------------------------

func _base(canvas: Image, st: Dictionary, theme: String) -> void:
	var slab := _layer()
	_draw_waystone(slab, st, theme, true)
	canvas.blend_rect(slab, Rect2i(0, 0, S, S), BASE_AT)

func _draw_ascended(warden: String, frame: Image, st: Dictionary) -> void:
	var info: Array = ASCENDED[warden]
	var pal: Array = info[1]
	var fig := {o = Color(pal[0]), a = Color(pal[1]), b = Color(pal[2]), c = Color(pal[3]), ramp = _ramp_of(pal)}
	var halo := Color(info[2])
	# The Warden itself (themed waystone, halo, golem, accessories) on a 128 px layer.
	var canvas := Image.create_empty(L, L, false, Image.FORMAT_RGBA8)
	_base(canvas, st, info[0])
	_halo(canvas, st, halo)
	# Accessories move with the scaled-up head bob; the figure itself reads the template bob (tdy).
	var st2 := st.duplicate()
	st2["tdy"] = st.dy
	st2["dy"] = roundi(st.dy * K)
	st2["halo"] = halo
	call("_asc_" + warden, canvas, st2, fig)
	# The frame: light rays behind, the great dais, crystals orbiting, then the Warden on top.
	_rays(frame, st, halo)
	_dais(frame, st, info[0], halo)
	_crystals(frame, st, halo, fig, false)
	frame.blend_rect(canvas, Rect2i(0, 0, L, L), LAYER_AT)
	_crystals(frame, st, halo, fig, true)

# Soft beams of light fanning up from behind the Warden, turning slowly.
func _rays(frame: Image, st: Dictionary, halo: Color) -> void:
	var c := Vector2(HEAD) + Vector2(LAYER_AT) + Vector2(0, 6)
	for k in 7:
		var a := -PI * 0.5 + (k - 3) * 0.33 + sin(TAU * float(st.f) / st.n + k) * 0.03
		var len := 70.0 + (k % 3) * 10.0
		var col := Color(halo, 0.28 if k % 2 == 0 else 0.18)
		for s in int(len):
			var p := c + Vector2.from_angle(a) * (22.0 + s)
			var w := 1 + s / 24
			for o in range(-w, w + 1):
				var q := p + Vector2.from_angle(a + PI * 0.5) * o
				var x := roundi(q.x)
				var y := roundi(q.y)
				# Thin out towards the end so the beams fade instead of hitting the frame edge.
				var sparse: int = 2 if s < len * 0.45 else (4 if s < len * 0.75 else 8)
				if _in(frame, x, y) and y > 2 and (x + y * 3 + st.f) % sparse == 0:
					frame.set_pixel(x, y, col)

# The great dais under the waystone: an isometric plinth in the theme's stone, flagstones on top, a
# glowing rune ring, block seams and a lit trim on the sides, and four lantern posts.
func _dais(frame: Image, st: Dictionary, theme: String, halo: Color) -> void:
	var pal: Array = THEMES[theme]
	var top := Color(pal[0])
	var side_l := Color(pal[1])
	var side_r := Color(pal[2])
	var edge := Color(pal[2]).darkened(0.45)
	var hw := 70.0
	var hh := 30.0
	var thick := 10
	for y in H:
		for x in W:
			var u := (x + 0.5 - DAIS.x) / hw
			var v := (y + 0.5 - DAIS.y) / hh
			if absf(u) + absf(v) <= 1.0:
				# Top face: flagstones along both iso axes, each stone a slightly different shade.
				var a := (u + v) * 3.5
				var b := (v - u) * 3.5
				var seam := absf(a - roundf(a)) < 0.07 or absf(b - roundf(b)) < 0.07
				var cell := int(floorf(a) * 7 + floorf(b) * 13)
				var col := top.darkened(0.08 * (absi(cell) % 3))
				if seam:
					col = side_l.lerp(top, 0.35)
				if absf(u) + absf(v) > 0.97:
					col = top.lightened(0.25) if v < 0.0 else side_l
				frame.set_pixel(x, y, col)
				continue
			# Side faces below the front edges.
			var down := v - (1.0 - absf(u))
			if v > 0.0 and absf(u) <= 1.0 and down * hh <= thick and down > 0.0:
				var face := side_l if u < 0.0 else side_r
				var depth := down * hh
				var blocks := int(floorf((u + 1.0) * 7.0))
				var bx := absf((u + 1.0) * 7.0 - roundf((u + 1.0) * 7.0)) < 0.06
				var col := face
				if bx or absi(roundi(depth) - thick / 2) == 0 and blocks % 2 == 0:
					col = face.darkened(0.25)
				if depth < 2.0:
					col = Color(halo, 1.0).lerp(face, 0.45)  # the lit trim
				if depth > thick - 1.5:
					col = edge
				frame.set_pixel(x, y, col)
	# Outline round the dais.
	var src := frame.duplicate() as Image
	for y in range(1, H - 1):
		for x in range(1, W - 1):
			var u := (x + 0.5 - DAIS.x) / hw
			var v := (y + 0.5 - DAIS.y) / hh
			var inside := absf(u) + absf(v) <= 1.0 or (v > 0.0 and absf(u) <= 1.0 and (v - (1.0 - absf(u))) * hh <= thick)
			if not inside:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q := Vector2i(x, y) + d
				var qu := (q.x + 0.5 - DAIS.x) / hw
				var qv := (q.y + 0.5 - DAIS.y) / hh
				var q_in := absf(qu) + absf(qv) <= 1.0 or (qv > 0.0 and absf(qu) <= 1.0 and (qv - (1.0 - absf(qu))) * hh <= thick)
				if not q_in:
					frame.set_pixel(x, y, edge)
					break
	# The rune ring, runes lighting in turn.
	var runes := 24
	for k in runes:
		var ang := k * TAU / runes
		var p := DAIS + Vector2(cos(ang) * hw * 0.74, sin(ang) * hh * 0.74)
		var lit: bool = (k + st.f * 3) % runes < 6
		var col := Color.WHITE.lerp(halo, 0.3) if lit else halo.darkened(0.35)
		var x := roundi(p.x)
		var y := roundi(p.y)
		match k % 3:
			0:
				_gpx(frame, x, y, col); _gpx(frame, x + 1, y, col); _gpx(frame, x, y - 1, col)
			1:
				_gpx(frame, x, y, col); _gpx(frame, x, y + 1, col)
			2:
				_gpx(frame, x - 1, y, col); _gpx(frame, x + 1, y, col); _gpx(frame, x, y, col)
	_gring(frame, DAIS, Vector2(hw * 0.82, hh * 0.82), halo.darkened(0.2), 3, st.f, false)
	# Lantern posts: small standing stones with a glowing gem, at the dais corners.
	for post: Vector2 in [Vector2(DAIS.x - hw + 8, DAIS.y - 2), Vector2(DAIS.x + hw - 8, DAIS.y - 2), Vector2(DAIS.x - 34, DAIS.y + 15), Vector2(DAIS.x + 34, DAIS.y + 15)]:
		_post(frame, post, st, halo, top, side_l, side_r, edge)

func _post(frame: Image, p: Vector2, st: Dictionary, halo: Color, light: Color, mid: Color, dark: Color, o: Color) -> void:
	var l := _gnew(frame)
	var stone := _ramp([dark.to_html(), mid.to_html(), light.to_html(), light.lightened(0.2).to_html()])
	_gpoly(l, PackedVector2Array([p + Vector2(-4, 0), p + Vector2(-4, -13), p + Vector2(0, -16), p + Vector2(4, -13), p + Vector2(4, 0)]), stone, true)
	_gstamp(frame, l, o)
	var pulse: int = [0, 1, 1, 0, 0, 0, 1, 0][(st.f + int(p.x)) % 8]
	var gem := p + Vector2(0, -20 - pulse)
	var g := _gnew(frame)
	_gpoly(g, PackedVector2Array([gem + Vector2(0, -4), gem + Vector2(3, 0), gem + Vector2(0, 4), gem + Vector2(-3, 0)]), _ramp([halo.darkened(0.4).to_html(), halo.darkened(0.15).to_html(), halo.to_html(), "#ffffff"]))
	_gstamp(frame, g, o)
	_gglow(frame, gem, Vector2(8, 7), Color.WHITE.lerp(halo, 0.3), halo, st.f)

# Three family crystals orbiting the Warden at chest height (behind, then in front).
func _crystals(frame: Image, st: Dictionary, halo: Color, fig: Dictionary, front: bool) -> void:
	var c := Vector2(80, 76)
	for k in 3:
		var a: float = k * TAU / 3.0 + float(st.f) / st.n * TAU / 3.0
		var depth := sin(a)
		if (depth >= 0.0) != front:
			continue
		var p := c + Vector2(cos(a) * 62, depth * 12 - 6 + sin(TAU * float(st.f) / st.n + k) * 2)
		var g := _gnew(frame)
		var s := 4.0 + depth
		_gpoly(g, PackedVector2Array([p + Vector2(0, -s * 1.6), p + Vector2(s, 0), p + Vector2(0, s * 1.6), p + Vector2(-s, 0)]),
			_ramp([fig.c.to_html(), fig.b.to_html(), fig.a.to_html(), Color.WHITE.lerp(halo, 0.5).to_html()]))
		_gstamp(frame, g, fig.o)
		if (st.f + k) % 3 == 0:
			_gsparkle(frame, Vector2i(p.round()) + Vector2i(2, -5), Color.WHITE, halo)

# A ring of light behind the head, the Ascended mark; a spark runs round it.
func _halo(canvas: Image, st: Dictionary, color: Color) -> void:
	var c := HEAD + Vector2(0, st.dy - 4)
	_gring(canvas, c, Vector2(27, 25), color, 2, st.f)
	_gring(canvas, c, Vector2(30, 28), color.darkened(0.25), 5, st.f)
	var a: float = float(st.f) / st.n * TAU - PI * 0.5
	_gsparkle(canvas, Vector2i((c + Vector2(cos(a) * 27, sin(a) * 25)).round()), Color.WHITE, color)
	_gsparkle(canvas, Vector2i((c + Vector2(cos(a + PI) * 27, sin(a + PI) * 25)).round()), Color.WHITE, color)

# The seated golem of the mock, the same template every Warden uses (POSE_UP / POSE_DOWN /
# stretch), drawn K times bigger: its banded shading scales up, while outlines stay 1 px (template
# outline runs keep only their first row / column, and the silhouette gets a fresh 1 px outline).
# Sets gh (head centre) and gb (belly centre) in frame px for the accessories. Returns its mask.
const K := 2.0
const HEAD_T := Vector2(30.0, 11.5)  # head centre in template px
const BELLY_T := Vector2(34.0, 30.0)
const BELL_HAND_T := Vector2(42.0, 32.0)  # the side arm's hand, template px
var fo := Vector2(0, 0)  # frame position of template (0, 0)
var gh := Vector2.ZERO
var gb := Vector2.ZERO

func _fig_at(pose: Dictionary, tx: int, ty: int) -> String:
	if tx < 0 or ty < 0 or tx >= S or ty >= S:
		return "."
	var i := ty * S + tx
	if pose.outside[i] == 1:
		return "."
	return pose.grid[i]

# The Ascended golem's template: no rocks (the body and right foot behind the front one are drawn in
# _golem, since the golem is bigger than the rocks now).
var _asc_pose_cache := {}

func _ascended_pose(pose: Dictionary) -> Dictionary:
	var key: int = pose.grid.hash()
	if _asc_pose_cache.has(key):
		return _asc_pose_cache[key]
	var grid: Array = pose.grid.duplicate()
	var outside: PackedByteArray = pose.outside.duplicate()
	for i in S * S:
		if grid[i] != "." and outside[i] == 0 and _is_rock(pose, i % S, i / S):
			grid[i] = "."
	var result := {grid = grid, outside = outside}
	_asc_pose_cache[key] = result
	return result

func _place_figure() -> void:
	# Centre the figure on the slab, feet on its top face.
	var pose: Dictionary = poses[0]
	var box := Rect2i()
	var first := true
	for i in S * S:
		if pose.grid[i] != "." and pose.outside[i] == 0:
			var p := Vector2i(i % S, i / S)
			box = Rect2i(p, Vector2i.ONE) if first else box.expand(p)
			first = false
	fo = Vector2(roundf(67.0 - (box.position.x + box.size.x * 0.5) * K), roundf(119.0 - (box.end.y + 1) * K))
	HEAD = fo + HEAD_T * K

func _golem(canvas: Image, st: Dictionary, fig: Dictionary, opts: Dictionary = {}) -> Image:
	if fo == Vector2.ZERO:
		_place_figure()
	var pose: Dictionary = _ascended_pose(st.pose)
	var dy: int = st.get("tdy", st.dy)
	var colors := {a = fig.a, b = fig.b, c = fig.c, o = fig.o}
	var body := _gnew(canvas)
	for y in 128:
		for x in 128:
			var t := (Vector2(x, y) - fo) / K
			var tx := floori(t.x)
			var ty := floori(t.y)
			var ch := _fig_at(pose, tx, ty)
			if ch == ".":
				continue
			if ch == "o":
				var first_x := floori((x - 1 - fo.x) / K) != tx
				var first_y := floori((y - 1 - fo.y) / K) != ty
				var h := _fig_at(pose, tx - 1, ty) == "o" or _fig_at(pose, tx + 1, ty) == "o"
				var v := _fig_at(pose, tx, ty - 1) == "o" or _fig_at(pose, tx, ty + 1) == "o"
				if not ((h and first_y) or (v and first_x) or (not h and not v)):
					# A dropped outline pixel takes the fill beside it (below / right), if any.
					var n := _fig_at(pose, tx + (0 if first_x else 1), ty + (0 if first_y else 1))
					if n == "o" or n == ".":
						n = _fig_at(pose, tx, ty + 1) if not first_y else _fig_at(pose, tx + 1, ty)
					if n == "o" or n == "." or not colors.has(n):
						continue
					ch = n
			if not colors.has(ch):
				continue
			body.set_pixel(x, y, colors[ch])
	# Where the front rock stood: the backside. From the feet (front middle, on the ground) its
	# outline curves round and up to the body's right side, a tapering quarter-oval.
	var butt_c := Vector2(34.0, 37.0)  # template px: the curve's corner, above the feet
	var butt_r := Vector2(12.0, 8.5)
	for y in 128:
		for x in 128:
			var t := (Vector2(x + 0.5, y + 0.5) - fo - Vector2(0, dy)) / K
			if t.x < butt_c.x or t.y < butt_c.y or body.get_pixel(x, y).a > 0.0:
				continue
			var d := (t - butt_c) / butt_r
			if d.length_squared() > 1.0:
				continue
			body.set_pixel(x, y, colors["c" if d.length_squared() > 0.72 else ("a" if t.x > 41.0 else "b")])
	# Fresh 1 px outline round the silhouette.
	var mask := _gnew(canvas)
	for y in 128:
		for x in 128:
			if body.get_pixel(x, y).a == 0.0:
				continue
			mask.set_pixel(x, y, Color.WHITE)
			var col := body.get_pixel(x, y)
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q := Vector2i(x, y) + d
				if not _in(body, q.x, q.y) or body.get_pixelv(q).a == 0.0:
					col = fig.o
					break
			canvas.set_pixel(x, y, col)
	# Detail: dither where the shading bands meet, a few speckles, and a rim light (the Ascended
	# glow) on the silhouette's lit edge.
	var rim: Color = fig.a.lerp(st.get("halo", Color.WHITE), 0.55).lightened(0.15)
	var src := canvas.duplicate() as Image
	for y in range(1, 127):
		for x in range(1, 127):
			if mask.get_pixel(x, y).a == 0.0:
				continue
			var col := src.get_pixel(x, y)
			if col == fig.o:
				continue
			var left := src.get_pixel(x - 1, y)
			var above := src.get_pixel(x, y - 1)
			if col == fig.a and left == fig.b and y % 2 == 0:
				canvas.set_pixel(x, y, fig.b)
			elif col == fig.b and left == fig.c and y % 2 == 1:
				canvas.set_pixel(x, y, fig.c)
			elif col == fig.b and above == fig.a and x % 2 == 0:
				canvas.set_pixel(x, y, fig.a)
			elif (x * 7 + y * 13) % 37 == 0:
				canvas.set_pixel(x, y, col.lightened(0.12) if (x + y) % 2 == 0 else col.darkened(0.08))
			var right := src.get_pixel(x + 1, y)
			var up_out: bool = above == fig.o and mask.get_pixel(x, y - 2).a == 0.0
			var right_out: bool = right == fig.o and mask.get_pixel(x + 2, y).a == 0.0
			if (up_out or right_out) and col != fig.c:
				canvas.set_pixel(x, y, rim)
	gh = fo + (HEAD_T + Vector2(0, dy)) * K
	gb = fo + BELLY_T * K
	_face(canvas, st, fig, opts.get("asleep", false))
	return mask

func _face(canvas: Image, st: Dictionary, fig: Dictionary, asleep: bool) -> void:
	var dy: int = st.get("tdy", st.dy)
	var ey := floori(fo.y + (EYE_TOP + dy) * K)
	for ex: int in EYES:
		var x0 := floori(fo.x + ex * K)
		# Clear the template's eye, then draw a 2 px wide one (or a closed smile).
		for k in 6:
			for w in 3:
				var p := Vector2i(x0 - 1 + w, ey - 1 + k)
				if canvas.get_pixelv(p) == fig.o:
					canvas.set_pixelv(p, fig.a)
		if asleep or st.blink:
			_gpx(canvas, x0 - 1, ey + 2, fig.o)
			_gpx(canvas, x0, ey + 3, fig.o)
			_gpx(canvas, x0 + 1, ey + 3, fig.o)
			_gpx(canvas, x0 + 2, ey + 2, fig.o)
		else:
			for k in 5:
				_gpx(canvas, x0, ey + k, fig.o)
				_gpx(canvas, x0 + 1, ey + k, fig.o)
			_gpx(canvas, x0, ey, Color.WHITE)
	var by := floori(fo.y + (EYE_TOP + 3 + dy) * K) + 1
	for bx: int in [24, 34]:
		var x0 := floori(fo.x + bx * K)
		for w in 3:
			_gpx(canvas, x0 + w, by, BLUSH)
			_gpx(canvas, x0 + w, by + 1, BLUSH.darkened(0.08))

func _on_mask(mask: Image, x: int, y: int) -> bool:
	return _in(mask, x, y) and mask.get_pixel(x, y).a > 0.0

# --- 1. Sporemother: a constant spore storm ------------------------------------------------------

func _asc_sporemother(canvas: Image, st: Dictionary, fig: Dictionary) -> void:
	var dy: int = st.dy
	var sac := _ramp(["#c8b080", "#e8dcb0", "#fff6dc", "#ffffff"])
	var orbit := func(front: bool) -> void:
		for k in 4:
			var a: float = k * TAU / 4.0 + float(st.f) / st.n * TAU * 0.5
			var p := Vector2(64 + cos(a) * 44, 80 + sin(a) * 14 + dy)
			if (sin(a) >= 0.0) != front:
				continue
			var l := _gnew(canvas)
			var r: float = 6.0 + (2.0 * st.power if st.attack >= 0 else 0.0)
			_gell(l, p, Vector2(r, r * 0.9), sac)
			_gstamp(canvas, l, fig.o)
			_gpx(canvas, int(p.x) - 2, int(p.y) - 2, Color.WHITE)
			_gpx(canvas, int(p.x) + 2, int(p.y) + 1, Color("#c8b080"))
			_gpx(canvas, int(p.x) - 1, int(p.y) + 2, Color("#c8b080"))
	orbit.call(false)
	var mask := _golem(canvas, st, fig, {raise = st.power * 0.6, both = true})
	# The great cap: a pink dome with glowing cream spots and a pale gill band.
	var cap := _gnew(canvas)
	var cy := HEAD.y - 10 + dy
	_gell(cap, Vector2(63, cy), Vector2(33, 17), _ramp(["#a0306a", "#d04c8a", "#f07ab0", "#ffc0dc"]), 0.0, cy + 5)
	_gstamp(canvas, cap, fig.o)
	for x in range(33, 94):
		var col := Color("#f8dcea") if x % 3 != 0 else Color("#d8a0c0")
		if canvas.get_pixel(x, int(cy) + 5).a > 0.0:
			_gpx(canvas, x, int(cy) + 5, fig.o)
			_gpx(canvas, x, int(cy) + 4, col)
	var spots := [Vector2i(50, -8), Vector2i(64, -13), Vector2i(78, -7), Vector2i(40, -1), Vector2i(86, 0), Vector2i(57, -2), Vector2i(71, -3)]
	for i in spots.size():
		var s: Vector2i = spots[i]
		var p := Vector2i(s.x, int(cy) + s.y)
		var lit: bool = (st.f + i) % 4 == 0
		for d: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(-1, 0)]:
			_gpx(canvas, p.x + d.x, p.y + d.y, Color("#fffbe8") if lit else Color("#fff0c8"))
	orbit.call(true)
	_gmotes(canvas, st, [30, 44, 58, 72, 86, 98, 38, 90], 70, 60, [Color("#fff6c8"), Color("#ffc0e8"), Color("#f7c8fa")])
	if st.attack >= 0:
		_spore_burst(canvas, st, Vector2(63, cy - 8), fig.o)
	_gglow(canvas, Vector2(63, cy + 2), Vector2(44, 26), Color("#ffe8f4"), Color("#ffc0e8"), st.f, 4)

func _spore_burst(canvas: Image, st: Dictionary, c: Vector2, o: Color) -> void:
	var a: int = st.attack
	var puff := _ramp(["#c8b080", "#e8dcb0", "#fff6dc", "#ffffff"])
	if a == RELEASE_FRAME or a == RELEASE_FRAME + 1:
		var rad := 16.0 if a == RELEASE_FRAME else 26.0
		for k in 8:
			var p := c + Vector2.from_angle(k * TAU / 8.0 + a * 0.3) * Vector2(rad * 1.4, rad * 0.8)
			var l := _gnew(canvas)
			_gell(l, p, Vector2(5, 4) * (1.2 if a == RELEASE_FRAME else 0.8), puff)
			_gstamp(canvas, l, o)
		_gring(canvas, Vector2(64, 104), Vector2(40 + a * 6, 16 + a * 2), Color("#ffe8f4"), 2, a)
	elif a == RELEASE_FRAME + 2:
		for k in 12:
			var p := c + Vector2.from_angle(k * TAU / 12.0) * Vector2(50, 30)
			_gpx(canvas, int(p.x), int(p.y), Color("#fff6c8"))
	if a >= 0 and a < RELEASE_FRAME:
		_gglow(canvas, c, Vector2(14, 10) * (1.0 + a * 0.4), Color("#fff6dc"), Color("#ffc0e8"), a)

# --- 2. Tidecaller: a rolling tide ---------------------------------------------------------------

func _asc_tidecaller(canvas: Image, st: Dictionary, fig: Dictionary) -> void:
	var dy: int = st.dy
	var surge: float = st.power if st.attack >= 0 else 0.0
	_wave_curl(canvas, st, surge)
	var mask := _golem(canvas, st, fig, {raise = surge, both = true})
	# Water gloss: bright streaks down the left of the body and head.
	for k in 3:
		_gline(canvas, [Vector2(49 + k * 2, 68 + dy + k * 3), Vector2(47 + k * 2, 88 + dy)], Color("#dff4ff") if k == 0 else Color("#b8e2ff"), mask)
	_gline(canvas, [Vector2(52, 36 + dy), Vector2(51, 44 + dy)], Color("#e8f8ff"), mask)
	# Droplet tip and a lily pad crown with a pink flower.
	var tip := _gnew(canvas)
	_gpoly(tip, PackedVector2Array([Vector2(58, 32 + dy), Vector2(63, 22 + dy), Vector2(68, 32 + dy)]), fig.ramp)
	_gstamp(canvas, tip, fig.o)
	var pad := _gnew(canvas)
	_gell(pad, Vector2(63, 31 + dy), Vector2(17, 4.5), _ramp(["#3f7a3e", "#5a9a48", "#7cbc5a", "#a8dc7a"]))
	_gstamp(canvas, pad, Color("#14301a"))
	_gline(canvas, [Vector2(63, 31 + dy), Vector2(70, 34 + dy)], Color("#2e5a30"))
	var petals := _gnew(canvas)
	for k in 5:
		var d := Vector2.from_angle(k * TAU / 5.0 - PI * 0.5 + st.sway * 0.1) * 4.5
		_gell(petals, Vector2(56, 27 + dy) + d, Vector2(3, 3), _ramp(["#d880a8", "#f4a0c0", "#ffd0e4", "#fff0f6"]))
	_gstamp(canvas, petals, Color("#6a2a4a"))
	_gflat(canvas, Vector2(56, 27 + dy), Vector2(1.6, 1.6), Color("#ffd24a"))
	# Bubbles rising.
	_gmotes(canvas, st, [36, 50, 78, 92, 42, 86], 96, 70, [Color("#bfe8ff"), Color("#e8f8ff")])
	if st.attack == RELEASE_FRAME or st.attack == RELEASE_FRAME + 1:
		for k in 10:
			var p: Vector2 = Vector2(96, 44) + Vector2.from_angle(-PI * 0.9 + k * 0.28) * (16.0 + st.attack * 5)
			_gsparkle(canvas, Vector2i(p.round()), Color.WHITE, Color("#9ad4ff"))
		_gring(canvas, Vector2(64, 104), Vector2(42 + st.attack * 6, 16 + st.attack * 2), Color("#bfe8ff"), 2, st.attack)
	_gglow(canvas, Vector2(64, 60), Vector2(46, 34), Color("#e8f8ff"), Color("#9ad4ff"), st.f, 4)

# A great curling wave behind the golem, rising from the left over its head.
func _wave_curl(canvas: Image, st: Dictionary, surge: float) -> void:
	var water := _ramp(["#2a5eb0", "#4a88d8", "#7ab8f0", "#bfe8ff"])
	var c := Vector2(66, 70)
	var lift: float = surge * 8.0 + [0, 1, 1, 0, 0, -1, -1, 0][st.f % 8]
	var layer := _gnew(canvas)
	for y in 128:
		for x in 128:
			var p := Vector2(x + 0.5, y + 0.5) - c
			var a := p.angle()
			var r := p.length()
			var a0 := -PI * 0.98
			var a1 := -PI * 0.12 + surge * 0.5
			if a < a0 or a > a1:
				continue
			var t := (a - a0) / (a1 - a0)
			var inner := 40.0 + lift
			var outer := inner + 7.0 + sin(t * PI) * 7.0
			if r >= inner and r <= outer:
				var q := (r - inner) / (outer - inner)
				layer.set_pixel(x, y, _shade(water, Vector3(0, -q + 0.3, 0.8).normalized()))
	_gstamp(canvas, layer, Color("#0e2048"))
	# Foam on the crest, running along it.
	for k in 22:
		var t := float(k) / 22.0
		var a := lerpf(-PI * 0.98, -PI * 0.12 + surge * 0.5, t)
		var r := 40.0 + lift + 7.0 + sin(t * PI) * 7.0
		if (k + st.f) % 3 == 0:
			continue
		var p := c + Vector2(cos(a), sin(a)) * r
		_gpx(canvas, int(p.x), int(p.y), Color.WHITE)
		_gpx(canvas, int(p.x), int(p.y) - 1, Color("#e8f8ff"))
	# The curl at the wave's front.
	var tipa := -PI * 0.12 + surge * 0.5
	var tip := c + Vector2(cos(tipa), sin(tipa)) * (47.0 + lift)
	_gring(canvas, tip + Vector2(-3, 2), Vector2(4, 4), Color.WHITE, 1)
	_gring(canvas, tip + Vector2(-3, 2), Vector2(2, 2), Color("#bfe8ff"), 1)

# --- 3. Stormheart: a lightning heart ------------------------------------------------------------

func _asc_stormheart(canvas: Image, st: Dictionary, fig: Dictionary) -> void:
	var dy: int = st.dy
	var flare: float = st.power if st.attack >= 0 else 0.0
	# The storm crown behind the head.
	var cloud := _gnew(canvas)
	var storm := _ramp(["#383862", "#4a4a7c", "#5c5c8e", "#8080b4"])
	for b: Vector3 in [Vector3(44, 26, 11), Vector3(58, 19, 13), Vector3(74, 20, 12), Vector3(86, 28, 10), Vector3(64, 30, 14)]:
		_gell(cloud, Vector2(b.x + st.sway, b.y + dy), Vector2(b.z, b.z * 0.72), storm)
	_gstamp(canvas, cloud, Color("#16162a"))
	var mask := _golem(canvas, st, fig, {raise = flare * 0.8, both = true})
	# Glass: a long highlight and fireflies drifting inside.
	_gline(canvas, [Vector2(48, 66 + dy), Vector2(46, 90 + dy)], Color("#a8d0d8"), mask)
	_gline(canvas, [Vector2(52, 36 + dy), Vector2(51, 42 + dy)], Color("#d8f4f4"), mask)
	for k in 7:
		var p := Vector2i(46 + (k * 13) % 36, 64 + (k * 7) % 28 + dy)
		if (st.f + k) % 3 != 0 and _on_mask(mask, p.x, p.y):
			_gpx(canvas, p.x, p.y, Color("#fff27a"))
	# The heart: gold, beating, a bolt inside.
	var beat: float = [0.0, 0.5, 1.0, 0.5, 0.0, 0.0, 0.3, 0.0][st.f % 8] if st.attack < 0 else flare
	var hc := Vector2(64, 76 + dy)
	var hs := 1.0 + beat * 0.15
	var heart := _gnew(canvas)
	var gold := _ramp(GOLD)
	_gell(heart, hc + Vector2(-5, -3) * hs, Vector2(6, 6) * hs, gold)
	_gell(heart, hc + Vector2(5, -3) * hs, Vector2(6, 6) * hs, gold)
	_gpoly(heart, PackedVector2Array([hc + Vector2(-10.5, -1) * hs, hc + Vector2(10.5, -1) * hs, hc + Vector2(0, 11) * hs]), gold)
	_gstamp(canvas, heart, Color("#5a3200"))
	_gline(canvas, [hc + Vector2(1, -6), hc + Vector2(-2, 0), hc + Vector2(2, 1), hc + Vector2(-1, 7)], Color.WHITE)
	# Light spilling from the heart through the glass.
	for y in range(int(hc.y) - 18, int(hc.y) + 18):
		for x in range(int(hc.x) - 22, int(hc.x) + 22):
			if not _on_mask(mask, x, y) or heart.get_pixel(x, y).a > 0.0:
				continue
			var q := (Vector2(x, y) - hc).length() / (14.0 + beat * 6.0)
			var col := canvas.get_pixel(x, y)
			if q < 1.0 and col != fig.o and (x + y) % 2 == 0:
				canvas.set_pixel(x, y, col.lerp(Color("#ffe070"), 0.35 * (1.0 - q)))
	# Small bolts flicker at the cloud's edges.
	if st.attack < 0 and st.f % 4 == 1:
		_gbolt(canvas, Vector2(34 + st.f, 30), Vector2(28, 44), Color("#fffbe0"), Color("#ffe070"), st.f, 3)
	if st.attack < 0 and st.f % 4 == 3:
		_gbolt(canvas, Vector2(94, 30), Vector2(102, 42), Color("#fffbe0"), Color("#ffe070"), st.f, 3)
	if st.attack == RELEASE_FRAME or st.attack == RELEASE_FRAME + 1:
		for k in 4:
			var end := hc + Vector2.from_angle(-PI * 0.95 + k * PI * 0.3) * 58.0
			_gbolt(canvas, hc, end, Color.WHITE, Color("#ffe070"), k + st.attack * 5, 6)
		_gglow(canvas, hc, Vector2(40, 34), Color("#fffbe0"), Color("#ffe070"), st.attack)
	_gglow(canvas, hc + Vector2(0, -20), Vector2(44, 36), Color("#fff6c0"), Color("#ffe070"), st.f, 4)

# --- 4. Old Mountain: the boulder crusher --------------------------------------------------------

func _asc_old_mountain(canvas: Image, st: Dictionary, fig: Dictionary) -> void:
	var dy: int = st.dy
	var stone := _ramp(["#686d9a", "#979dc2", "#c4c9e2", "#e8ecff"])
	# Two peaks behind the shoulders, snow-capped, with a pine on each.
	for peak: Array in [[Vector2(36, 76), 30.0, 16.0], [Vector2(92, 74), 34.0, 17.0]]:
		var base: Vector2 = peak[0]
		var h: float = peak[1]
		var w: float = peak[2]
		var l := _gnew(canvas)
		_gpoly(l, PackedVector2Array([base + Vector2(-w, 0), base + Vector2(-w * 0.2, -h), base + Vector2(w * 0.25, -h * 0.85), base + Vector2(w, 0)]), stone, true)
		for y in range(int(base.y - h), int(base.y - h * 0.6)):
			for x in range(int(base.x - w), int(base.x + w)):
				if l.get_pixel(x, y).a > 0.0:
					l.set_pixel(x, y, Color("#f4f6ff") if (x + y) % 5 != 0 else Color("#d0d6f0"))
		_gstamp(canvas, l, fig.o)
		var pine := _gnew(canvas)
		var px := base.x + w * 0.55
		_gpoly(pine, PackedVector2Array([Vector2(px - 5, base.y - 6), Vector2(px, base.y - 20), Vector2(px + 5, base.y - 6)]), _ramp(["#2e5a30", "#3f7a3e", "#5a9a48", "#7cbc5a"]))
		_gstamp(canvas, pine, Color("#14241a"))
	var lift: float = [0.4, 1.0, 0.2, 0.0, 0.0, 0.0][st.attack] if st.attack >= 0 else 0.0
	var mask := _golem(canvas, st, fig, {raise = lift, both = true})
	# Facets and cracks across the body.
	for crack: Array in [[Vector2(52, 70), Vector2(58, 78), Vector2(56, 88)], [Vector2(72, 66), Vector2(76, 74)], [Vector2(66, 86), Vector2(74, 92)], [Vector2(54, 38), Vector2(57, 44)]]:
		var pts: Array = []
		for p: Vector2 in crack:
			pts.append(p + Vector2(0, dy))
		_gline(canvas, pts, fig.c, mask)
	# Moss cap with a flower.
	var moss := _gnew(canvas)
	_gell(moss, Vector2(62, 31 + dy), Vector2(14, 6), _ramp(["#3f7a3e", "#5a9a48", "#7cbc5a", "#a8dc7a"]), 0.0, 34 + dy)
	_gstamp(canvas, moss, Color("#14241a"))
	_gflat(canvas, Vector2(70, 27 + dy), Vector2(1.5, 1.5), Color("#fff4f0"))
	_gpx(canvas, 70, 27 + dy, Color("#ffd24a"))
	# The boulder, lifted overhead before the throw.
	if st.attack >= 0 and st.attack < RELEASE_FRAME:
		var c := Vector2(64, 22 - st.attack * 6)
		var l := _gnew(canvas)
		var pts := PackedVector2Array()
		for k in 7:
			pts.append(c + Vector2.from_angle(k * TAU / 7.0 + 0.3) * 13.0 * [1.0, 0.85, 0.95, 0.8, 1.0, 0.9, 0.85][k])
		_gpoly(l, pts, stone, true)
		_gstamp(canvas, l, fig.o)
	elif st.attack == RELEASE_FRAME or st.attack == RELEASE_FRAME + 1:
		for k in 8:
			var p: Vector2 = Vector2(64, 8) + Vector2.from_angle(k * TAU / 8.0) * (8.0 + st.attack * 4)
			_gpx(canvas, int(p.x), int(p.y), Color("#e8ecff"))
		_gglow(canvas, Vector2(64, 10), Vector2(18, 10), Color("#fffbe0"), Color("#e8ecff"), st.attack)
	_gmotes(canvas, st, [30, 98, 44, 84], 100, 50, [Color("#e8ecff"), Color("#c4c9e2")])
	_gglow(canvas, Vector2(64, 60), Vector2(46, 36), Color("#f4f6ff"), Color("#c4c9e2"), st.f, 4)

# --- 5. World Root: vast roots -------------------------------------------------------------------

func _asc_world_root(canvas: Image, st: Dictionary, fig: Dictionary) -> void:
	var dy: int = st.dy
	var bark := Color("#7a5234")
	# Roots spreading out over the slab and beyond it, with gold runes pulsing along them.
	var roots := _gnew(canvas)
	var paths := [
		[Vector2(50, 100), Vector2(34, 108), Vector2(18, 110), Vector2(4, 118)],
		[Vector2(56, 104), Vector2(46, 116), Vector2(40, 127)],
		[Vector2(76, 104), Vector2(88, 116), Vector2(96, 127)],
		[Vector2(80, 100), Vector2(98, 106), Vector2(112, 108), Vector2(124, 116)],
		[Vector2(64, 104), Vector2(66, 118), Vector2(62, 127)],
	]
	for path: Array in paths:
		_gstroke(roots, path, 3.2, bark)
	for y in 128:
		for x in 128:
			if roots.get_pixel(x, y).a > 0.0 and (x * 3 + y) % 7 == 0:
				roots.set_pixel(x, y, Color("#9a6e48"))
	_gstamp(canvas, roots, fig.o)
	for i in paths.size():
		var path: Array = paths[i]
		var t: float = fposmod(float(st.f) / st.n + i * 0.2, 1.0)
		var seg: int = mini(int(t * (path.size() - 1)), path.size() - 2)
		var local := t * (path.size() - 1) - seg
		var p: Vector2 = (path[seg] as Vector2).lerp(path[seg + 1], local)
		_gsparkle(canvas, Vector2i(p.round()), Color("#fffbe0"), Color("#d8f0a0"))
	# The leafy crown: the Rootling's two leaves grown into a small tree.
	var branch := _gnew(canvas)
	_gstroke(branch, [Vector2(63, 32 + dy), Vector2(62, 22 + dy), Vector2(52, 12 + dy)], 1.6, bark)
	_gstroke(branch, [Vector2(62, 22 + dy), Vector2(74, 12 + dy)], 1.4, bark)
	_gstamp(canvas, branch, fig.o)
	var leaves := _gnew(canvas)
	var green := _ramp(["#3f7a3e", "#5a9a48", "#7cbc5a", "#b0e080"])
	for b: Vector3 in [Vector3(48, 10, 8), Vector3(60, 6, 7), Vector3(76, 9, 8), Vector3(86, 16, 6), Vector3(40, 17, 6)]:
		_gell(leaves, Vector2(b.x + st.sway, b.y + dy), Vector2(b.z, b.z * 0.7), green)
	_gstamp(canvas, leaves, Color("#14241a"))
	var raise: float = st.power if st.attack >= 0 else 0.0
	var mask := _golem(canvas, st, fig, {raise = raise, both = true})
	# Bark grain.
	for k in 5:
		var x := 50 + k * 7
		_gline(canvas, [Vector2(x, 66 + dy), Vector2(x + 1, 76 + dy), Vector2(x, 90 + dy)], fig.c, mask)
	# Attack: roots burst up on both sides, gold-tipped.
	if st.attack >= 1 and st.attack <= 4:
		var h: float = [0.0, 10.0, 24.0, 20.0, 10.0][st.attack]
		var spikes := _gnew(canvas)
		for sx: float in [14.0, 30.0, 98.0, 114.0]:
			_gstroke(spikes, [Vector2(sx, 118), Vector2(sx + 2, 118 - h * 0.6), Vector2(sx - 1, 118 - h)], 2.4, bark)
		_gstamp(canvas, spikes, fig.o)
		for sx: float in [13.0, 29.0, 97.0, 113.0]:
			_gsparkle(canvas, Vector2i(int(sx), int(118 - h)), Color("#fffbe0"), Color("#d8f0a0"))
		_gring(canvas, Vector2(64, 108), Vector2(46 + st.attack * 4, 16 + st.attack), Color("#d8f0a0"), 2, st.attack)
	_gglow(canvas, Vector2(64, 50), Vector2(48, 40), Color("#f0ffd8"), Color("#d8f0a0"), st.f, 4)

# --- 6. The Great Bell: it tolls -----------------------------------------------------------------

func _asc_the_great_bell(canvas: Image, st: Dictionary, fig: Dictionary) -> void:
	var dy: int = st.dy
	var violet := _ramp(["#6a4aa8", "#8a6ac8", "#a88ae0", "#c8b0f0"])
	# Bellflower stems arching on both sides, a small bell hanging from each.
	var stems := _gnew(canvas)
	_gstroke(stems, [Vector2(30, 100), Vector2(24, 70), Vector2(30, 46), Vector2(40, 40)], 2.0, Color("#7cbc5a"))
	_gstroke(stems, [Vector2(98, 100), Vector2(104, 70), Vector2(98, 46), Vector2(88, 40)], 2.0, Color("#7cbc5a"))
	_gstamp(canvas, stems, Color("#2e5a30"))
	for b: Vector2 in [Vector2(40, 42), Vector2(88, 42)]:
		var l := _gnew(canvas)
		_gpoly(l, PackedVector2Array([b + Vector2(-4, 0), b + Vector2(4, 0), b + Vector2(6, 9), b + Vector2(-6, 9)]), violet)
		_gstamp(canvas, l, fig.o)
	var swing: float = [0.0, -3.0, 4.0, -2.0, 1.0, 0.0][st.attack] if st.attack >= 0 else [0.0, 0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5][st.f % 8]
	var mask := _golem(canvas, st, fig, {raise = 0.0, asleep = st.attack < 0})
	# The bellflower hood: a violet petal cap with a scalloped rim.
	var hood := _gnew(canvas)
	_gell(hood, Vector2(63, 34 + dy), Vector2(20, 13), violet, 0.0, 38 + dy)
	for k in 6:
		_gell(hood, Vector2(46 + k * 7, 38 + dy), Vector2(4, 3), violet)
	_gstamp(canvas, hood, fig.o)
	for k in 3:
		_gline(canvas, [Vector2(52 + k * 11, 25 + dy), Vector2(50 + k * 12, 36 + dy)], Color("#6a4aa8"))
	# The great bell hangs from its side hand (the golem's own arm), swinging.
	var hand := fo + BELL_HAND_T * K + Vector2(0, dy)
	var bz := 0.8
	var bc := hand + Vector2(swing * 0.6, 17)
	var bell := _gnew(canvas)
	var gold := _ramp(GOLD)
	var pts := PackedVector2Array()
	for p: Vector2 in [Vector2(-8, -12), Vector2(8, -12), Vector2(11, -2), Vector2(14, 10), Vector2(17, 16), Vector2(-17, 16), Vector2(-14, 10), Vector2(-11, -2)]:
		pts.append(bc + p * bz)
	_gpoly(bell, pts, gold)
	_gell(bell, bc + Vector2(0, -12) * bz, Vector2(8, 4) * bz, gold)
	_gstamp(canvas, bell, Color("#5a3200"))
	_gline(canvas, [bc + Vector2(-15, 12) * bz, bc + Vector2(15, 12) * bz], Color("#a86a1a"))
	_gline(canvas, [bc + Vector2(-7, -6) * bz, bc + Vector2(-9, 8) * bz], Color("#fff8d0"))
	_gflat(canvas, bc + Vector2(0, 18) * bz, Vector2(2.5, 1.8), Color("#7a4a10"))
	# The bell's loop, gripped in the hand.
	_gring(canvas, hand + Vector2(swing * 0.3, 2), Vector2(3, 3), Color("#a86a1a"))
	_gline(canvas, [hand + Vector2(swing * 0.3, 5), bc + Vector2(0, -15) * bz], Color("#a86a1a"))
	_gmotes(canvas, st, [34, 94, 26, 102], 60, 40, [Color("#ffe8a0"), Color("#c8b0f0")])
	for k in 2:
		var t: float = fposmod(float(st.f) / st.n + k * 0.5, 1.0)
		_note(canvas, Vector2i(22 + k * 80, int(56 - t * 24)), Color("#ffe8a0") if k == 0 else Color("#c8b0f0"))
	if st.attack >= RELEASE_FRAME and st.attack <= RELEASE_FRAME + 2:
		var k: int = st.attack - RELEASE_FRAME
		for i in 3:
			_gring(canvas, bc + Vector2(0, 8), Vector2(22 + k * 10 + i * 8, 10 + k * 4 + i * 3), Color("#ffe8a0") if i % 2 == 0 else Color("#c8b0f0"), 1 + k, i)
		_gglow(canvas, bc, Vector2(30, 22), Color("#fff8d0"), Color("#ffe8a0"), st.attack)
	_gglow(canvas, bc, Vector2(42, 30), Color("#fff8d0"), Color("#ffe8a0"), st.f, 4)

func _note(canvas: Image, p: Vector2i, color: Color) -> void:
	for k in 5:
		_gpx(canvas, p.x + 2, p.y - k, color)
	_gpx(canvas, p.x + 3, p.y - 4, color)
	_gpx(canvas, p.x + 4, p.y - 3, color)
	_gflat(canvas, Vector2(p.x + 1, p.y + 0.5), Vector2(1.8, 1.4), color)

# --- 7. Grandmother Oak: a gentle aura -----------------------------------------------------------

func _asc_grandmother_oak(canvas: Image, st: Dictionary, fig: Dictionary) -> void:
	var dy: int = st.dy
	# The aura: a warm ring on the ground, breathing.
	var breathe: int = [0, 1, 2, 1, 0, -1, -2, -1][st.f % 8]
	_gring(canvas, Vector2(64, 104), Vector2(56 + breathe, 20 + breathe * 0.4), Color("#ffe0a0"), 2, st.f, true)
	# The canopy: an oak crown grown from the acorn cap, acorns hanging from it.
	var crown := _gnew(canvas)
	var green := _ramp(["#3a6a2e", "#5a8a3a", "#7cac4a", "#b8dc70"])
	for b: Vector3 in [Vector3(36, 30, 14), Vector3(52, 18, 15), Vector3(74, 16, 15), Vector3(92, 28, 14), Vector3(64, 28, 16)]:
		_gell(crown, Vector2(b.x + st.sway * 0.5, b.y), Vector2(b.z, b.z * 0.7), green)
	for y in 128:
		for x in 128:
			if crown.get_pixel(x, y).a > 0.0 and (x * 7 + y * 3) % 23 == 0:
				crown.set_pixel(x, y, Color("#d8f0a0"))
	_gstamp(canvas, crown, Color("#1e3014"))
	for a: Vector2 in [Vector2(30, 40), Vector2(48, 30), Vector2(84, 30), Vector2(100, 38)]:
		_acorn(canvas, Vector2i(a) + Vector2i(0, [0, 1, 0, -1][(st.f / 2 + int(a.x)) % 4]))
	var mask := _golem(canvas, st, fig, {raise = 0.0, asleep = true})
	# Acorn cap on the head.
	var cap := _gnew(canvas)
	_gell(cap, Vector2(63, 33 + dy), Vector2(15, 7), _ramp(["#5a3a20", "#7a5234", "#9a6e48", "#c09268"]), 0.0, 37 + dy)
	_gstamp(canvas, cap, Color("#2a1a10"))
	for x in range(50, 77, 3):
		_gpx(canvas, x, 31 + dy, Color("#5a3a20"))
		_gpx(canvas, x + 1, 33 + dy, Color("#5a3a20"))
	# A shawl of leaves over the shoulders.
	var shawl := _gnew(canvas)
	for k in 7:
		var p := Vector2(44 + k * 6.5, 62 + dy + absf(k - 3) * 1.5)
		_gell(shawl, p, Vector2(4.5, 3), green, 0.4 * (k - 3) / 3.0)
	_gstamp(canvas, shawl, Color("#1e3014"))
	# Falling leaves.
	for k in 3:
		var t: float = fposmod(float(st.f) / st.n + k * 0.33, 1.0)
		var p := Vector2i(26 + k * 36 + roundi(sin(t * TAU) * 4), roundi(46 + t * 50))
		_gpx(canvas, p.x, p.y, Color("#e8a040"))
		_gpx(canvas, p.x + 1, p.y, Color("#c07a2a"))
	if st.attack >= RELEASE_FRAME and st.attack <= RELEASE_FRAME + 2:
		var k: int = st.attack - RELEASE_FRAME
		_gring(canvas, Vector2(64, 104), Vector2(30 + k * 14, 11 + k * 5), Color("#fff4c8"), 1, k)
		_gring(canvas, Vector2(64, 104), Vector2(24 + k * 14, 9 + k * 5), Color("#ffe0a0"), 2, k)
		for i in 6:
			var p := Vector2(64, 60) + Vector2.from_angle(i * TAU / 6.0 + k * 0.4) * (28.0 + k * 8)
			_gsparkle(canvas, Vector2i(p.round()), Color.WHITE, Color("#ffe0a0"))
	_gglow(canvas, Vector2(64, 66), Vector2(50, 40), Color("#fff4d8"), Color("#ffe0a0"), st.f, 4)

func _acorn(canvas: Image, p: Vector2i) -> void:
	_gline(canvas, [Vector2(p.x, p.y - 4), Vector2(p.x, p.y - 2)], Color("#5a3a20"))
	_gflat(canvas, Vector2(p.x + 0.5, p.y + 2), Vector2(2.5, 3), Color("#d49c54"))
	_gpx(canvas, p.x - 1, p.y + 1, Color("#f0c080"))
	_gline(canvas, [Vector2(p.x - 2, p.y - 1), Vector2(p.x + 3, p.y - 1)], Color("#7a5234"))
	_gline(canvas, [Vector2(p.x - 1, p.y - 2), Vector2(p.x + 2, p.y - 2)], Color("#7a5234"))

# --- 8. Dawnwing: a great bird of dawn -----------------------------------------------------------

const DAWN := ["#c8503a", "#f0884a", "#ffc060", "#fff0b0"]

func _asc_dawnwing(canvas: Image, st: Dictionary, fig: Dictionary) -> void:
	var dy: int = st.dy
	var empty: bool = st.get("empty", false) or st.attack >= 0
	# Sunrise behind: rays fanning up from the nest.
	var rc := Vector2(63, 26 + dy)
	for k in 9:
		var a := -PI + (k + 0.5) * PI / 9.0
		if (k + st.f / 2) % 2 == 0:
			_gline(canvas, [rc + Vector2(cos(a), sin(a)) * 22.0, rc + Vector2(cos(a), sin(a)) * 34.0], Color("#ffd0a0"))
	var calling: float = st.power if st.attack >= 0 else 0.0
	var mask := _golem(canvas, st, fig, {raise = calling})
	# Feathered chest.
	for k in 4:
		for j in 3:
			_gpx(canvas, 56 + j * 6 + (k % 2) * 3, 68 + k * 5 + dy, fig.c)
			_gpx(canvas, 57 + j * 6 + (k % 2) * 3, 69 + k * 5 + dy, fig.c)
	# The nest crown.
	var nest := _gnew(canvas)
	_gell(nest, Vector2(63, 30 + dy), Vector2(19, 6), _ramp(["#5a3a20", "#7a5234", "#9a6e48", "#c09268"]))
	_gstamp(canvas, nest, Color("#2a1a10"))
	for k in 9:
		var x := 47 + k * 4
		_gline(canvas, [Vector2(x, 27 + dy + k % 2), Vector2(x + 4, 32 + dy - k % 2)], Color("#5a3a20"))
	if empty:
		# A golden feather left in the nest.
		_gline(canvas, [Vector2(58, 25 + dy), Vector2(68, 22 + dy)], Color("#ffc060"))
		_gline(canvas, [Vector2(59, 24 + dy), Vector2(67, 21 + dy)], Color("#fff0b0"))
	else:
		_dawn_bird_body(canvas, Vector2(64, 16 + dy), st.f, false, 1.6)
	if st.attack >= RELEASE_FRAME and st.attack <= RELEASE_FRAME + 2:
		var k: int = st.attack - RELEASE_FRAME
		for i in 10:
			var a := -PI + i * PI / 9.0
			_gline(canvas, [rc + Vector2(cos(a), sin(a)) * (26.0 + k * 6), rc + Vector2(cos(a), sin(a)) * (40.0 + k * 8)], Color("#fff0b0"))
		_gglow(canvas, rc, Vector2(34, 24), Color("#fff8e0"), Color("#ffc060"), st.attack)
	_gglow(canvas, rc + Vector2(0, 10), Vector2(48, 36), Color("#fff4d8"), Color("#ffd0a0"), st.f, 4)

# The great bird, side view facing right: a round golden body, a rose crest, three long tail
# plumes with eye-spots, one big wing. Perched, the wing is folded and lifts now and then; flying
# (the path sprite), it beats. `z` scales the whole bird.
func _dawn_bird_body(canvas: Image, c: Vector2, f: int, flying: bool, z: float = 1.5) -> void:
	var dawn := _ramp(DAWN)
	var deep := _ramp(["#8a2a2a", "#c8503a", "#f0884a", "#ffc060"])
	var o := Color("#4a1a10")
	var beat: float = [0.0, 0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5][f % 8]
	var at := func(x: float, y: float) -> Vector2: return c + Vector2(x, y) * z
	# Tail plumes.
	var tail := _gnew(canvas)
	var ends: Array = []
	var root: Vector2 = at.call(-6, 1)
	for k in 3:
		var dir := Vector2(-1, 0.35 * (k - 1)).normalized() if flying else Vector2(-0.55, 0.85).rotated(0.25 * (k - 1))
		var mid := root + (dir * 10.0 + Vector2(0, beat * (1.0 if flying else 0.4))) * z
		var end := root + (dir * (15.0 if flying else 20.0) + Vector2(0, beat * (2.0 if flying else 0.6))) * z
		_gstroke(tail, [root, mid, end], 1.5 * z, Color(DAWN[1]))
		ends.append(end)
	_gstamp(canvas, tail, o)
	for e: Vector2 in ends:
		_gflat(canvas, e, Vector2(2.2, 2.2) * z, Color(DAWN[2]))
		_gflat(canvas, e, Vector2(1, 1) * z, Color("#8a2a2a"))
	# Body and head.
	var body := _gnew(canvas)
	_gell(body, c, Vector2(9, 6.5) * z, dawn, -0.15 if not flying else 0.0)
	_gell(body, at.call(8, -6), Vector2(5, 4.5) * z, dawn)
	_gstamp(canvas, body, o)
	# Crest, beak, eye.
	for k in 3:
		_gline(canvas, [at.call(6 + k * 2, -10), at.call(4 + k * 2.5, -14 - k % 2)], Color(DAWN[0]))
	var beak := _gnew(canvas)
	_gpoly(beak, PackedVector2Array([at.call(12, -7.5), at.call(16, -6), at.call(12, -4.5)]), _ramp(["#c89020", "#ffd24a", "#ffe890", "#fff8d0"]))
	_gstamp(canvas, beak, o)
	var eye: Vector2 = at.call(10, -7)
	_gpx(canvas, int(eye.x), int(eye.y), o)
	_gpx(canvas, int(eye.x), int(eye.y) + 1, o)
	_gpx(canvas, int(eye.x), int(eye.y) - 1, Color.WHITE)
	# The wing: a long leaf of feathers from the shoulder.
	var lift := (0.6 + beat * 0.9) if flying else maxf(0.0, beat) * 0.5
	var shoulder: Vector2 = at.call(-1, -2)
	var dir := Vector2(-1, 0).rotated(lift * 1.4 + (0.1 if not flying else 0.0))
	var length := (18.0 if flying else 12.0) * z
	var perp := dir.orthogonal()
	var wing := _gnew(canvas)
	_gpoly(wing, PackedVector2Array([shoulder + perp * 3.0 * z, shoulder + dir * length * 0.5 + perp * 5.0 * z, shoulder + dir * length,
		shoulder + dir * length * 0.6 - perp * 2.0 * z, shoulder - perp * 2.5 * z]), deep)
	_gstamp(canvas, wing, o)
	for k in 3:
		var p := shoulder + dir * length * (0.45 + k * 0.17)
		_gline(canvas, [p + perp * 2.5 * z, p - perp * 1.0 * z], Color(DAWN[2]))
	# Trailing sparks.
	if flying:
		for k in 3:
			var p: Vector2 = at.call(-28 - k * 5, sin(f + k) * 2)
			_gpx(canvas, int(p.x), int(p.y), Color("#fff0b0") if (f + k) % 2 == 0 else Color("#ffc060"))

func _dawn_bird(canvas: Image, f: int) -> void:
	_dawn_bird_body(canvas, Vector2(38, 34 + [0, -1, -2, -1, 0, 1, 2, 1][f]), f, true, 1.25)
	_gglow(canvas, Vector2(34, 32), Vector2(28, 20), Color("#fff4d8"), Color("#ffc060"), f, 4)

# --- 9. The Tempest: a slow cyclone of maple seeds -----------------------------------------------

func _asc_the_tempest(canvas: Image, st: Dictionary, fig: Dictionary) -> void:
	var dy: int = st.dy
	var gather: float = st.power if st.attack >= 0 else 0.0
	var seeds := func(front: bool) -> void:
		for k in 6:
			var a: float = k * TAU / 6.0 + float(st.f) / st.n * TAU * 0.25
			var rad := lerpf(46.0, 18.0, gather)
			var p := Vector2(64 + cos(a) * rad, 70 - k * 4.5 + sin(a) * 10 + dy - gather * 30)
			if (sin(a) >= 0.0) != front:
				continue
			_maple_seed(canvas, Vector2i(p.round()), a + st.f * 0.4)
	seeds.call(false)
	# Wind ribbons behind.
	for k in 3:
		var t: float = fposmod(float(st.f) / st.n + k * 0.33, 1.0)
		var y := 50 + k * 16
		_gline(canvas, [Vector2(20 + t * 10, y), Vector2(34 + t * 10, y - 3), Vector2(46 + t * 10, y - 1)], Color("#e8f8f0"))
		_gline(canvas, [Vector2(82 + t * 10, y + 6), Vector2(96 + t * 10, y + 3), Vector2(108 + t * 10, y + 5)], Color("#e8f8f0"))
	var mask := _golem(canvas, st, fig, {raise = gather, both = true})
	# Maple ears and a seed propeller on the head, spinning.
	var ears := _gnew(canvas)
	var maple := _ramp(["#b0602e", "#d88a48", "#f0b070", "#ffd8a0"])
	_gell(ears, Vector2(50, 32 + dy), Vector2(6, 3.5), maple, -0.6)
	_gell(ears, Vector2(76, 32 + dy), Vector2(6, 3.5), maple, 0.6)
	_gstamp(canvas, ears, Color("#2a140a"))
	var spin: float = float(st.f) / st.n * TAU * 2.0
	var prop := _gnew(canvas)
	for s in 2:
		var a := spin + s * PI
		_gell(prop, Vector2(63, 24 + dy) + Vector2(cos(a) * 8, sin(a) * 2), Vector2(8, 2.5), maple, a * 0.0 + (0.2 if cos(a) > 0 else -0.2))
	_gstamp(canvas, prop, Color("#2a140a"))
	_gflat(canvas, Vector2(63, 25 + dy), Vector2(2, 2), Color("#8a4a1e"))
	seeds.call(true)
	if st.attack >= 0 and st.attack < RELEASE_FRAME + 2:
		_funnel(canvas, Vector2(64, 30), 0.6 + gather * 0.4, st.attack)
	_gglow(canvas, Vector2(64, 60), Vector2(50, 38), Color("#f4fff8"), Color("#c0ecd8"), st.f, 4)

func _maple_seed(canvas: Image, p: Vector2i, a: float) -> void:
	var d := Vector2(cos(a), sin(a) * 0.6).normalized()
	var l := _gnew(canvas)
	_gell(l, Vector2(p) + d * 3.6, Vector2(4.4, 2.6), _ramp(["#d8904a", "#f0b878", "#fbe0b0", "#fff6e4"]), d.angle() + 0.3)
	_gell(l, Vector2(p), Vector2(2.4, 2.4), _ramp(["#4a200a", "#7a3a14", "#a8561e", "#c87434"]))
	_gstamp(canvas, l, Color("#2a140a"))

# A funnel of wind: stacked ellipse bands narrowing downward.
func _funnel(canvas: Image, top: Vector2, scale: float, phase: int) -> void:
	for k in 7:
		var y := top.y + k * 6.0 * scale
		var r := Vector2((22.0 - k * 2.6) * scale, (4.0 - k * 0.3) * scale)
		_gring(canvas, Vector2(top.x + sin(k + phase) * 1.5, y), r, Color("#e8fff0") if k % 2 == 0 else Color("#c0ecd8"), 2, phase + k)

# --- World effects -------------------------------------------------------------------------------

# Tidecaller's tide: a wave rolling right along the path.
func _tide_wave(canvas: Image, f: int) -> void:
	var water := _ramp(["#2a5eb0", "#4a88d8", "#7ab8f0", "#bfe8ff"])
	var l := _gnew(canvas)
	var crest: float = [0.0, 1.0, 2.0, 1.0, 0.0, -1.0, -1.0, 0.0][f]
	var pts := PackedVector2Array([Vector2(2, 50), Vector2(10, 38 - crest), Vector2(26, 26 - crest), Vector2(42, 20 - crest), Vector2(54, 24 - crest), Vector2(58, 32), Vector2(50, 36), Vector2(56, 50)])
	_gpoly(l, pts, water)
	_gstamp(canvas, l, Color("#0e2048"))
	for k in 12:
		var t := float(k) / 11.0
		var p := Vector2(10, 38 - crest).lerp(Vector2(54, 24 - crest), t) + Vector2(0, -sin(t * PI) * 4)
		if (k + f) % 3 != 0:
			_gpx(canvas, int(p.x), int(p.y), Color.WHITE)
	_gring(canvas, Vector2(50, 30 - crest), Vector2(3, 3), Color.WHITE)
	for k in 5:
		var p := Vector2(56 + (k * 3 + f) % 7, 22 + k * 5 - crest)
		_gpx(canvas, int(p.x), int(p.y), Color("#e8f8ff"))
	_gglow(canvas, Vector2(32, 36), Vector2(30, 22), Color("#e8f8ff"), Color("#9ad4ff"), f, 4)

func _cyclone(canvas: Image, f: int) -> void:
	var wind := [Color("#f4fff8"), Color("#c0ecd8"), Color("#90c8b0")]
	for k in 10:
		var y := 8.0 + k * 6.5
		var r := Vector2(24.0 - k * 1.9, 5.0 - k * 0.25)
		var c := Vector2(32 + sin(k * 0.7 + f * 0.8) * 2.0, y)
		_gring(canvas, c, r, wind[k % 3], 2, f + k)
		_gring(canvas, c + Vector2(0, 1), r * 0.8, wind[(k + 1) % 3], 3, f)
	for k in 6:
		var a := k * TAU / 6.0 + f * TAU / 16.0
		var y := 14.0 + k * 9.0
		var rad := 20.0 - k * 2.2
		_maple_seed(canvas, Vector2i(roundi(32 + cos(a) * rad), roundi(y + sin(a) * 3)), a)
	_gflat(canvas, Vector2(32, 74), Vector2(10, 2.5), Color("#c0ecd8"))
	for k in 4:
		_gpx(canvas, 22 + k * 7 + f % 3, 73 - k % 2, Color("#e8d8b0"))
	_gglow(canvas, Vector2(32, 40), Vector2(30, 36), Color("#f4fff8"), Color("#c0ecd8"), f, 4)

func _mountain_boulder(canvas: Image, f: int) -> void:
	var stone := _ramp(["#686d9a", "#979dc2", "#c4c9e2", "#e8ecff"])
	var l := _gnew(canvas)
	var pts := PackedVector2Array()
	for k in 7:
		pts.append(Vector2(16, 16) + Vector2.from_angle(k * TAU / 7.0 + f * TAU / 28.0) * 11.0 * [1.0, 0.85, 0.95, 0.8, 1.0, 0.9, 0.85][k])
	_gpoly(l, pts, stone, true)
	_gstamp(canvas, l, Color("#1c1c36"))
	var moss := Vector2(16, 16) + Vector2.from_angle(-PI * 0.5 + f * TAU / 28.0) * 6.0
	_gflat(canvas, moss, Vector2(3, 2), Color("#5a9a48"))
	_gglow(canvas, Vector2(16, 16), Vector2(15, 15), Color("#f4f6ff"), Color("#c4c9e2"), f, 4)

# Old Mountain's crush: the boulder lands on a 3x3 area (192 px), dust and shards fly out.
func _mountain_impact(canvas: Image, a: int) -> void:
	var c := Vector2(96, 96)
	var stone := _ramp(["#686d9a", "#979dc2", "#c4c9e2", "#e8ecff"])
	if a <= 1:
		var l := _gnew(canvas)
		var r := 26.0 + a * 4.0
		var pts := PackedVector2Array()
		for k in 7:
			pts.append(c + Vector2(0, -8 + a * 8) + Vector2.from_angle(k * TAU / 7.0 + 0.3) * r * [1.0, 0.85, 0.95, 0.8, 1.0, 0.9, 0.85][k])
		_gpoly(l, pts, stone, true)
		_gstamp(canvas, l, Color("#1c1c36"))
	# Cracks spreading over the ground.
	if a >= 1:
		for k in 8:
			var ang := k * TAU / 8.0 + 0.2
			var len := minf(20.0 + a * 14.0, 64.0)
			var p0 := c + Vector2.from_angle(ang) * 18.0
			var p1 := c + Vector2.from_angle(ang + 0.15) * len * 0.6
			var p2 := c + Vector2.from_angle(ang - 0.1) * len
			_gline(canvas, [p0, p1, p2], Color("#3a3050") if a < 5 else Color("#5a5070"))
	# Dust ring and flying shards.
	if a >= 1 and a <= 4:
		var rr := 30.0 + a * 16.0
		_gring(canvas, c, Vector2(rr, rr * 0.9), Color("#e8e0d0"), 2, a)
		_gring(canvas, c, Vector2(rr - 6, (rr - 6) * 0.9), Color("#c8c0b0"), 3, a)
		for k in 10:
			var ang := k * TAU / 10.0 + a * 0.2
			var p := c + Vector2.from_angle(ang) * (rr + 6.0)
			var s := _gnew(canvas)
			_gpoly(s, PackedVector2Array([p + Vector2(-3, 0), p + Vector2(0, -3), p + Vector2(3, 1), p + Vector2(0, 3)]), stone, true)
			_gstamp(canvas, s, Color("#1c1c36"))
	if a == 1 or a == 2:
		_gglow(canvas, c, Vector2(60, 54), Color("#fffbe8"), Color("#e8ecff"), a)
	if a >= 2:
		# Rubble left in the centre.
		for k in 5:
			var p := c + Vector2.from_angle(k * 1.3) * (6.0 + k * 3)
			var s := _gnew(canvas)
			_gell(s, p, Vector2(4, 3), stone)
			_gstamp(canvas, s, Color("#1c1c36"))

# World Root's grasp on one nightmare: roots rise and wrap, then sink.
func _root_grasp(canvas: Image, a: int) -> void:
	var bark := Color("#7a5234")
	var h: float = [6.0, 16.0, 24.0, 24.0, 18.0, 8.0][a]
	var l := _gnew(canvas)
	for k in 4:
		var x := 14.0 + k * 12.0
		var lean := (k - 1.5) * -2.5
		_gstroke(l, [Vector2(x, 50), Vector2(x + lean, 50 - h * 0.6), Vector2(x + lean * 2.4, 50 - h)], 2.2, bark)
	if a >= 2 and a <= 4:
		_gstroke(l, [Vector2(14, 34), Vector2(32, 30), Vector2(50, 34)], 1.6, bark)
	_gstamp(canvas, l, Color("#24160e"))
	for k in 4:
		var x := 14.0 + k * 12.0 + (k - 1.5) * -6.0
		if a >= 1 and a <= 4:
			_gsparkle(canvas, Vector2i(roundi(x), roundi(50 - h)), Color("#fffbe0"), Color("#d8f0a0"))
	_gflat(canvas, Vector2(32, 52), Vector2(22, 4), Color(0.2, 0.12, 0.06, 0.5))
	if a >= 1 and a <= 3:
		_gglow(canvas, Vector2(32, 40), Vector2(28, 18), Color("#f0ffd8"), Color("#d8f0a0"), a)

# --- The Heartwood Sapling -----------------------------------------------------------------------

const RING := [Vector2(20, 100), Vector2(38, 90), Vector2(64, 86), Vector2(90, 90), Vector2(108, 100),
	Vector2(104, 122), Vector2(84, 134), Vector2(44, 134), Vector2(24, 122)]
const FRUIT := [Vector2(30, 70), Vector2(46, 80), Vector2(82, 80), Vector2(98, 68), Vector2(64, 76), Vector2(18, 56), Vector2(110, 54)]

# ripen: 0 = idle; 1-5 = the ripening sheet (glow builds, frame 3 releases Dew + Dreamlight).
func _sapling(canvas: Image, f: int, ripen: int, withered: bool, _rank: int) -> void:
	var sway: int = SWAY[f % 8]
	var o := Color("#1e1a14")
	# Ground: a mossy disc filling the 2x2 footprint.
	var ground := _gnew(canvas)
	var grass := _ramp(["#3a6a2e", "#4a7a34", "#5a9a48", "#7cbc5a"]) if not withered else _ramp(["#4a4a32", "#5e5a3c", "#706a48", "#8a8258"])
	_gell(ground, Vector2(64, 112), Vector2(60, 30), grass)
	for y in 160:
		for x in 128:
			if ground.get_pixel(x, y).a > 0.0 and (x * 5 + y * 3) % 17 == 0:
				ground.set_pixel(x, y, Color("#a8dc7a") if not withered else Color("#9a9068"))
	_gstamp(canvas, ground, Color("#1e3014"))
	# The waystone ring: back stones first.
	for i in RING.size():
		if RING[i].y < 110:
			_ring_stone(canvas, RING[i], i, 0)
	# Roots over the ground.
	var bark := _ramp(["#4a3020", "#6a4428", "#8a6040", "#b08a60"]) if not withered else _ramp(["#3e3228", "#524436", "#665848", "#7e7060"])
	var roots := _gnew(canvas)
	for r: Array in [[Vector2(58, 112), Vector2(40, 116), Vector2(26, 112)], [Vector2(70, 112), Vector2(88, 118), Vector2(100, 114)],
			[Vector2(62, 114), Vector2(56, 126), Vector2(50, 132)], [Vector2(66, 114), Vector2(74, 128)], [Vector2(60, 110), Vector2(46, 104)]]:
		_gstroke(roots, r, 2.4, bark[1])
	_gstamp(canvas, roots, o)
	# Trunk: short and sturdy, a little S-curve, with a glowing hollow.
	var trunk := _gnew(canvas)
	for y in range(62, 116):
		var t := (y - 62) / 54.0
		var cx := 64.0 + sin(t * PI * 1.2) * 3.0 + (1.0 - t) * sway
		var hw := lerpf(5.0, 9.5, t * t)
		for x in range(int(cx - hw), int(cx + hw) + 1):
			var n := Vector3((x - cx) / hw, -0.2, 0.8)
			trunk.set_pixel(x, y, _shade(bark, n.normalized()))
	for y in range(64, 114, 3):
		trunk.set_pixel(62 + (y / 3) % 3, y, bark[0])
	_gstamp(canvas, trunk, o)
	var hollow := Color("#ffd890") if not withered else Color("#5a4a3a")
	_gflat(canvas, Vector2(64, 104), Vector2(3.5, 5), Color("#3a2410"))
	_gflat(canvas, Vector2(64, 104.5), Vector2(2.5, 4), hollow)
	if not withered:
		_gpx(canvas, 63, 102, Color("#fff4d0"))
	# Canopy: soft leafy clumps, warm light speckles.
	var leaf := _ramp(["#2e5a2a", "#4a7a34", "#6a9a3c", "#9ac050"])
	if withered:
		leaf = _ramp(["#3e3a2a", "#56503a", "#6e6646", "#8a8058"])
	var canopy := _gnew(canvas)
	var clumps := [Vector3(64, 38, 30), Vector3(36, 52, 20), Vector3(92, 50, 20), Vector3(50, 24, 18), Vector3(80, 22, 18), Vector3(64, 58, 24), Vector3(22, 60, 12), Vector3(106, 58, 12)]
	for i in clumps.size():
		var b: Vector3 = clumps[i]
		var dx := sway * (1.0 if b.y < 40 else 0.5)
		_gell(canopy, Vector2(b.x + dx, b.y + (2 if withered else 0)), Vector2(b.z, b.z * 0.72), leaf)
	for y in 160:
		for x in 128:
			if canopy.get_pixel(x, y).a > 0.0 and (x * 7 + y * 11) % 19 == 0:
				canopy.set_pixel(x, y, leaf[3].lightened(0.2))
	if withered:
		# Blight patches, like the Heartwood's.
		for b: Vector3 in [Vector3(44, 30, 7), Vector3(78, 44, 8), Vector3(58, 56, 6), Vector3(96, 30, 5)]:
			for y in range(int(b.y - b.z), int(b.y + b.z)):
				for x in range(int(b.x - b.z * 1.3), int(b.x + b.z * 1.3)):
					var q := (Vector2(x, y) - Vector2(b.x, b.y)) / Vector2(b.z * 1.3, b.z)
					if canopy.get_pixel(x, y).a > 0.0 and q.length() < 1.0 and (q.length() < 0.7 or (x + y) % 2 == 0):
						canopy.set_pixel(x, y, Color("#2a1a3a") if (x + y) % 3 else Color("#3e2a52"))
	_gstamp(canvas, canopy, Color("#1a2a14") if not withered else o)
	# Dream-fruit: glowing peach-gold orbs hanging under the canopy.
	var fruit := _ramp(["#d87a3a", "#f0a850", "#ffd080", "#fff4d0"]) if not withered else _ramp(["#6a5a4a", "#7e6e5c", "#948470", "#a89880"])
	var glow: float = [0.0, 0.3, 0.7, 1.0, 0.5, 0.2][ripen] if ripen > 0 else [0.0, 0.1, 0.2, 0.1, 0.0, 0.0, 0.1, 0.0][f % 8]
	for i in FRUIT.size():
		var p: Vector2 = FRUIT[i] + Vector2(sway * 0.5, [0, 1, 0, 0][(f + i) % 4])
		if withered and i % 2 == 1:
			continue
		_gline(canvas, [p + Vector2(0, -6), p + Vector2(0, -3)], Color("#3a5a2a"))
		var l := _gnew(canvas)
		var r := 3.2 + glow * 0.8
		_gell(l, p, Vector2(r, r), fruit)
		_gstamp(canvas, l, Color("#6a2a10") if not withered else o)
		if not withered and (glow > 0.5 or (f + i) % 5 == 0):
			_gsparkle(canvas, Vector2i(p.round()) + Vector2i(-1, -1), Color.WHITE, Color("#fff4d0"))
	# Front stones.
	for i in RING.size():
		if RING[i].y >= 110:
			_ring_stone(canvas, RING[i], i, 0)
	if not withered:
		_gmotes(canvas, {f = f, n = 8}, [20, 40, 58, 76, 96, 110], 96, 60, [Color("#fff4d0"), Color("#ffd080"), Color("#d8f0a0")])
	if ripen >= 2:
		for i in FRUIT.size():
			var p: Vector2 = FRUIT[i]
			_gglow(canvas, p, Vector2(8, 8) * (0.6 + glow), Color("#fff4d0"), Color("#ffd080"), ripen)
	if ripen == 3 or ripen == 4:
		# Release: a dew drop and a Dreamlight mote rise from the crown.
		var rise := (ripen - 3) * 10
		var drop := _gnew(canvas)
		_gell(drop, Vector2(54, 14 - rise), Vector2(3, 4), _ramp(["#3a78c8", "#5aa8ec", "#9ad4ff", "#e8f8ff"]))
		_gpoly(drop, PackedVector2Array([Vector2(52, 12 - rise), Vector2(54, 6 - rise), Vector2(56, 12 - rise)]), _ramp(["#3a78c8", "#5aa8ec", "#9ad4ff", "#e8f8ff"]))
		_gstamp(canvas, drop, Color("#16305e"))
		_gsparkle(canvas, Vector2i(76, 10 - rise), Color.WHITE, Color("#c8a0ff"), true)
		_gglow(canvas, Vector2(64, 12 - rise), Vector2(22, 10), Color("#fff4d0"), Color("#c8a0ff"), ripen)
	if not withered:
		_gglow(canvas, Vector2(64, 44), Vector2(64, 48), Color("#fff4d8"), Color("#ffd890"), f, 6)

func _ring_stone(canvas: Image, p: Vector2, i: int, lit: int) -> void:
	var stone := _ramp(["#34304c", "#6a6484", "#aaa4bc", "#d0cce0"])
	var h := 14.0 + (i % 3) * 3.0
	var l := _gnew(canvas)
	_gpoly(l, PackedVector2Array([p + Vector2(-5, 0), p + Vector2(-4, -h + 2), p + Vector2(0, -h), p + Vector2(4, -h + 3), p + Vector2(5, 0)]), stone, true)
	_gstamp(canvas, l, Color("#1c1a2a"))
	# A moss tuft on top and a rune.
	_gpx(canvas, int(p.x) - 1, int(p.y - h) + 1, Color("#7cbc5a"))
	_gpx(canvas, int(p.x), int(p.y - h) + 1, Color("#5a9a48"))
	var rune := Color("#ffd860") if lit > 0 else Color("#4a4668")
	var ry := int(p.y - h * 0.55)
	_gpx(canvas, int(p.x), ry, rune)
	_gpx(canvas, int(p.x), ry + 2, rune)
	_gpx(canvas, int(p.x) - 1, ry + 1, rune)
	_gpx(canvas, int(p.x) + 1, ry + 1, rune)
	if lit > 1:
		_gpx(canvas, int(p.x), ry + 1, Color("#fffbe0"))

# Rank overlay for the Sapling: rank N lights the runes of N ring stones and hangs gold around them
# (V: a golden garland across the front stones). Drawn on top of the sapling sheets.
func _sapling_rank(canvas: Image, rank: int) -> void:
	var order := [2, 4, 0, 6, 7]  # which stones light, in order (visible ones first)
	for k in rank:
		var i: int = order[k]
		var p: Vector2 = RING[i]
		var h := 14.0 + (i % 3) * 3.0
		var ry := int(p.y - h * 0.55)
		for d: Vector2i in [Vector2i(0, 0), Vector2i(0, 2), Vector2i(-1, 1), Vector2i(1, 1)]:
			_gpx(canvas, int(p.x) + d.x, ry + d.y, Color("#ffd860"))
		_gpx(canvas, int(p.x), ry + 1, Color("#fffbe0"))
		_gglow(canvas, Vector2(p.x, ry + 1), Vector2(6, 6), Color("#fff4c8"), Color("#ffd860"), k)
		_gpx(canvas, int(p.x) - 1, int(p.y - h) - 1, Color("#ffd860"))
		_gpx(canvas, int(p.x) + 1, int(p.y - h) - 1, Color("#ffd860"))
	if rank >= 5:
		var pts: Array = []
		for i: int in [8, 7, 6, 5]:
			var p: Vector2 = RING[i]
			pts.append(p + Vector2(0, -12))
		for i in pts.size() - 1:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[i + 1]
			for s in 12:
				var t := s / 11.0
				var q := a.lerp(b, t) + Vector2(0, sin(t * PI) * 4)
				_gpx(canvas, int(q.x), int(q.y), Color("#f0c860") if s % 3 else Color("#fffbe0"))

# --- Previews ------------------------------------------------------------------------------------

func _save_rows(rows: Array, w: int, h: int, path: String, scale: int) -> void:
	var pad := 4
	var gap := 16
	var cols := FRAMES + ATTACK_FRAMES
	var img := Image.create_empty(pad + cols * (w + pad) + gap, pad + rows.size() * (h + pad), false, Image.FORMAT_RGBA8)
	img.fill(Color("#5fa844"))
	for i in rows.size():
		var y := pad + i * (h + pad)
		var x := pad
		for sheet_i in 2:
			var sheet: Image = rows[i][sheet_i]
			if sheet == null:
				continue
			var n := sheet.get_width() / w
			for f in n:
				img.blend_rect(sheet, Rect2i(f * w, 0, w, h), Vector2i(x + f * (w + pad), y))
			x += n * (w + pad) + gap
	img.resize(img.get_width() * scale, img.get_height() * scale, Image.INTERPOLATE_NEAREST)
	img.save_png(path)

func _save_fx_preview(sheets: Array, path: String) -> void:
	var pad := 6
	var width := 0
	var height := pad
	for s: Image in sheets:
		width = maxi(width, s.get_width() + pad * 2)
		height += s.get_height() + pad
	var img := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color("#3a5a3a"))
	var y := pad
	for s: Image in sheets:
		img.blend_rect(s, Rect2i(0, 0, s.get_width(), s.get_height()), Vector2i(pad, y))
		y += s.get_height() + pad
	img.resize(img.get_width() * 2, img.get_height() * 2, Image.INTERPOLATE_NEAREST)
	img.save_png(path)
