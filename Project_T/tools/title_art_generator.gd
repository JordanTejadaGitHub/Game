extends SceneTree
# Generates the title screen background (screens_ui.md "Meta screens": the Heartwood on the title).
# Detailed pixel art at 640×360, shown at a whole-number scale (3× at 1080p, 2× at 720p, 4× at 1440p).
# A moonlit night: the Heartwood fills the right half with its golden hollow at the end of a pale
# path, the Sporeling sits huge in the foreground guarding it, and cold eyes watch from the thickets at the
# edges (art_direction.md: warm centre, cold edge). The upper left stays calm for the logo and menu.
# Every pixel is snapped to Heartwood 32 (art_direction.md).
#   assets/ui/title/title_background.png   640×360, the art
#   tools/previews/title_background_3x.png 1920×1080 preview
# Run:  Godot --headless --path . --script res://tools/title_art_generator.gd

const W := 640
const H := 360
const OUT := "res://assets/ui/title/"
const PREVIEW := "res://tools/previews/title_background_3x.png"
const Palette := preload("res://tools/art/heartwood_palette.gd")

const LIGHT := Vector2(-0.55, -0.83)  # towards the moon: light from the upper left
const MOON := Vector2(262, 56)
const MOON_R := 12.0
const HORIZON := 234
const TREE_X := 478.0                 # the Heartwood's trunk centre at the ground
const GROUND_Y := 274                 # where the trunk meets the ground (the hollow's sill)
const HOLLOW_W := 12                  # half width of the hollow's doorway
const HOLLOW_H := 38
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

const SKY := ["void", "night", "dusk", "slate", "stone"]
const CLOUD := ["night", "dusk", "slate", "stone", "mist", "moonlight"]
const BARK := ["root", "bark", "oak", "deadwood"]
const LEAVES := ["deepmoss", "moss", "leaf", "sprig", "newleaf"]
const GRASS := ["deepmoss", "moss", "leaf", "sprig"]
const PATH := ["loam", "path", "moonpath"]
const FIRE := ["ember", "gold", "glow", "heartlight"]
const DREAD := ["dread", "shade", "bruise"]

var img: Image
var noise := FastNoiseLite.new()
var grain := FastNoiseLite.new()
var rng := RandomNumberGenerator.new()
var _colors := {}
var _canopy_bottom := PackedInt32Array()  # lowest canopy pixel per column (-1 = none)
var _path_x := PackedFloat32Array()       # path centre per row (NAN above the path)
var _path_w := PackedFloat32Array()       # path half width per row


func _init() -> void:
	rng.seed = 20260930
	noise.seed = 11
	noise.frequency = 0.045
	noise.fractal_octaves = 3
	grain.seed = 5
	grain.frequency = 0.25
	img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	_canopy_bottom.resize(W)
	_canopy_bottom.fill(-1)

	_sky()
	_stars()
	_moon()
	_clouds()
	_hills()
	_meadow()
	_path()
	_trunk()
	_hollow()
	_roots()
	_canopy()
	_vines()
	_ground_mist()
	_thickets()
	_warm_light()
	_giant_sporeling()  # after the warm light, so the path's glow doesn't cross it
	_foreground()
	_cold_edges()
	_watchers()
	_fireflies()
	Palette.snap_image(img)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEW.get_base_dir()))
	img.save_png(OUT + "title_background.png")
	var big := img.duplicate() as Image
	big.resize(W * 3, H * 3, Image.INTERPOLATE_NEAREST)
	big.save_png(PREVIEW)
	print("title_art_generator: wrote ", OUT, "title_background.png")
	quit()


# --- helpers -------------------------------------------------------------------------------------

func col(color_name: String) -> Color:
	if not _colors.has(color_name):
		_colors[color_name] = Palette.color(color_name)
	return _colors[color_name]


func bayer(x: int, y: int) -> float:
	return (BAYER[(y & 3) * 4 + (x & 3)] + 0.5) / 16.0


func inside(x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < W and y < H


func put(x: int, y: int, c: Color) -> void:
	if inside(x, y):
		img.set_pixel(x, y, c)


func blend(x: int, y: int, c: Color, a: float) -> void:
	if inside(x, y) and a > 0.0:
		img.set_pixel(x, y, img.get_pixel(x, y).lerp(c, clampf(a, 0.0, 1.0)))


func hash01(x: int, y: int, salt := 0) -> float:
	var h := (x * 374761393 + y * 668265263 + salt * 2147483647) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h % 10007) / 10007.0


## A colour from a named ramp at v (0..1). Bands meet in a short ordered-dither seam, not a blur.
func pick(ramp: Array, v: float, x: int, y: int, seam := 0.16) -> Color:
	var f := clampf(v, 0.0, 0.9999) * (ramp.size() - 1)
	var i := int(floor(f))
	var t := f - i
	var lo := 0.5 - seam
	var hi := 0.5 + seam
	var up := t > hi or (t >= lo and (t - lo) / (hi - lo) > bayer(x, y))
	return col(ramp[mini(i + 1, ramp.size() - 1)] if up else ramp[i])


## A banded glow: a few alpha steps, never a soft blur (art_direction.md "Banded glow").
func glow(center: Vector2, radius: float, c: Color, strength := 0.35, squash := 1.0) -> void:
	var r := int(ceil(radius))
	for y in range(int(center.y) - r, int(center.y) + r + 1):
		for x in range(int(center.x) - r, int(center.x) + r + 1):
			var d := Vector2((x - center.x), (y - center.y) / squash).length() / radius
			if d >= 1.0:
				continue
			var step := 1.0 if d < 0.34 else (0.55 if d < 0.67 else 0.25)
			blend(x, y, c, strength * step)


## A shaded tube along a polyline (roots, branches): outline pass, then a lit fill pass.
func tube(points: PackedVector2Array, r0: float, r1: float, ramp: Array, outline: String, bias := 0.0) -> void:
	var samples: Array[Vector3] = []
	var total := 0.0
	for i in range(1, points.size()):
		total += points[i].distance_to(points[i - 1])
	var run := 0.0
	for i in range(1, points.size()):
		var a := points[i - 1]
		var b := points[i]
		var seg := a.distance_to(b)
		var steps := maxi(1, int(seg * 1.5))
		for s in steps:
			var p := a.lerp(b, float(s) / steps)
			var r := lerpf(r0, r1, (run + seg * s / steps) / total)
			samples.append(Vector3(p.x, p.y, r))
		run += seg
	for pass_index in 2:
		for s in samples:
			var r := s.z + (1.0 if pass_index == 0 else 0.0)
			var ri := int(ceil(r))
			for y in range(int(s.y) - ri, int(s.y) + ri + 1):
				for x in range(int(s.x) - ri, int(s.x) + ri + 1):
					var off := Vector2(x - s.x, y - s.y)
					if off.length() > r:
						continue
					if pass_index == 0:
						put(x, y, col(outline))
						continue
					var n := off / maxf(s.z, 0.5)
					var v := 0.45 + 0.45 * n.dot(LIGHT) + bias
					if grain.get_noise_2d(x * 2.0, y * 0.7) > 0.45:
						v -= 0.25
					put(x, y, pick(ramp, v, x, y))


# --- sky -----------------------------------------------------------------------------------------

func _sky() -> void:
	for y in H:
		for x in W:
			var v := float(y) / HORIZON * 0.78
			v += 0.32 * exp(-Vector2(x, y).distance_to(MOON) / 55.0)
			v += noise.get_noise_2d(x * 0.5, y * 2.2) * 0.05
			img.set_pixel(x, y, pick(SKY, v, x, y, 0.22))


func _stars() -> void:
	for i in 300:
		var x := rng.randi_range(0, W - 1)
		var y := rng.randi_range(0, 175)
		if Vector2(x, y).distance_to(MOON) < MOON_R + 16:
			continue
		var roll := rng.randf()
		if roll < 0.62:
			put(x, y, col("slate") if y > 90 else col("stone"))
		elif roll < 0.92:
			put(x, y, col("mist"))
		else:  # a twinkle: a bright centre with short arms
			put(x, y, col("moonlight"))
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				put(x + d.x, y + d.y, col("stone"))
			if roll > 0.97:
				for d in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
					blend(x + d.x, y + d.y, col("slate"), 0.7)


func _moon() -> void:
	var r := int(MOON_R) + 26
	for y in range(int(MOON.y) - r, int(MOON.y) + r + 1):
		for x in range(int(MOON.x) - r, int(MOON.x) + r + 1):
			var d := Vector2(x, y).distance_to(MOON)
			if d > MOON_R:
				var halo := 0.0
				if d < MOON_R + 3:
					halo = 0.45
				elif d < MOON_R + 9:
					halo = 0.22
				elif d < MOON_R + 20:
					halo = 0.09
				blend(x, y, col("mist"), halo)
				continue
			var n := (Vector2(x, y) - MOON) / MOON_R
			var v := 0.62 + 0.4 * n.dot(Vector2(-0.6, -0.6))
			var crater := noise.get_noise_2d(x * 4.0 + 300.0, y * 4.0)
			if crater > 0.22:
				v -= 0.28
			elif crater > 0.12:
				v -= 0.12
			put(x, y, pick(["slate", "stone", "mist", "moonlight"], v, x, y, 0.1))


# --- clouds --------------------------------------------------------------------------------------

func _clouds() -> void:
	# A thin band across the moon's lower edge, a calm bank on the left horizon, and a towering
	# bank behind the Heartwood that its canopy half hides.
	_stratus(214, 338, 72, 4.0, 1)
	_stratus(-10, 230, 128, 3.0, 2)
	_stratus(40, 180, 150, 2.0, 3)
	_cloud_bank(-30, 290, 222, 46, 103, Vector2(9, 18), true)
	_cloud_bank(300, 670, 212, 118, 104, Vector2(14, 28), true)


func _stratus(x0: float, x1: float, mid: float, thick: float, salt: int) -> void:
	# A long, thin cloud: moonlit on top, a dark underside, ragged tapered ends.
	for x in range(maxi(int(x0), 0), mini(int(x1), W)):
		var t := (x - x0) / (x1 - x0)
		var taper := pow(sin(t * PI), 0.6)
		var h := thick * taper * (0.7 + 0.6 * (0.5 + 0.5 * noise.get_noise_1d(x * 1.6 + salt * 97.0)))
		var y_mid := mid + noise.get_noise_1d(x * 0.4 + salt * 31.0) * 3.0
		if h < 0.6:
			continue
		for y in range(int(y_mid - h), int(y_mid + h * 0.6) + 1):
			var u := (y - (y_mid - h)) / (h * 1.6)  # 0 top .. 1 bottom
			var v := 0.62 - u * 0.5 - Vector2(x, y).distance_to(MOON) / 900.0
			put(x, y, pick(CLOUD, v, x, y, 0.2))


func _cloud_bank(x0: float, x1: float, base: float, height: float, seed_value: int, puff_r: Vector2, front_row: bool) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	var puffs: Array[Vector3] = []
	var n := maxi(3, int((x1 - x0) / (puff_r.y * 0.9)))
	for i in n:
		var t := (i + 0.5) / n
		var hump := pow(sin(t * PI), 0.8)
		var pr := lerpf(puff_r.x, puff_r.y, hump * r.randf_range(0.6, 1.0))
		var px := lerpf(x0, x1, t) + r.randf_range(-4.0, 4.0)
		var py := base - hump * height * r.randf_range(0.55, 1.0) + pr * 0.5
		puffs.append(Vector3(px, minf(py, base - pr * 0.3), pr))
		if hump > 0.5 and height > 40.0:  # towers: stack puffs up the middle
			puffs.append(Vector3(px + r.randf_range(-6, 6), py + pr * 0.9, pr * 1.1))
	puffs.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.y < b.y)
	if front_row:
		for i in n * 2:
			var pr := r.randf_range(puff_r.x * 0.6, puff_r.x * 1.1)
			puffs.append(Vector3(r.randf_range(x0, x1), base - r.randf_range(0.0, pr * 0.6), pr))
	for p in puffs:
		_puff(Vector2(p.x, p.y), p.z, base, base - height - puff_r.y)


func _puff(c: Vector2, radius: float, base: float, top: float) -> void:
	var ri := int(ceil(radius))
	for y in range(int(c.y) - ri, mini(int(base), int(c.y) + ri) + 1):
		for x in range(int(c.x) - ri, int(c.x) + ri + 1):
			if not inside(x, y):
				continue
			var off := Vector2(x, y) - c
			var d := off.length()
			var edge := radius + noise.get_noise_2d(x * 3.0, y * 3.0) * 1.2
			if d > edge:
				continue
			var n := off / radius
			var v := 0.5 + 0.42 * n.dot(LIGHT)
			v -= clampf((y - top) / maxf(base - top, 1.0), 0.0, 1.0) * 0.28  # darker bellies
			v -= Vector2(x, y).distance_to(MOON) / 1400.0                   # dimmer away from the moon
			if d > edge - 1.3 and n.dot(LIGHT) < 0.2:
				v -= 0.18  # the crease where this puff sits over the one behind
			put(x, y, pick(CLOUD, v, x, y, 0.14))


# --- land ----------------------------------------------------------------------------------------

func _hills() -> void:
	# Far mountains, then two tree lines, each fading into the fog below it.
	_ridge(196, 26, 0.012, ["night", "dusk", "slate", "stone"], 0.0, 0, 0.55)
	_ridge(216, 10, 0.03, ["night", "pool", "dusk", "slate"], 3.0, 1, 0.4)
	_ridge(230, 6, 0.05, ["night", "deepmoss", "pool", "moss"], 7.0, 2, 0.28)


func _ridge(base: float, amp: float, freq: float, ramp: Array, tree: float, salt: int, fog: float) -> void:
	var tops := PackedFloat32Array()
	tops.resize(W + 1)
	for x in W + 1:
		tops[x] = base - amp * (0.5 + 0.5 * noise.get_noise_1d(x * freq * 20.0 + salt * 500.0))
	if tree > 0.0:  # overlapping trees of mixed sizes: pines far, rounded crowns nearer
		var r := RandomNumberGenerator.new()
		r.seed = salt * 1000 + 17
		var tx := -8.0
		while tx < W + 8:
			tx += r.randf_range(2.0, 6.0 + salt)
			var tw := r.randf_range(2.5, 4.0 + salt * 1.5)
			var th := tree * r.randf_range(0.4, 1.4)
			var pine := salt == 1 or r.randf() < 0.3
			var ground := base - amp * (0.5 + 0.5 * noise.get_noise_1d(tx * freq * 20.0 + salt * 500.0))
			for x in range(int(tx - tw) - 1, int(tx + tw) + 2):
				if x < 0 or x > W:
					continue
				var u := absf(x - tx) / tw
				if u > 1.0:
					continue
				var lift := th * (1.0 - u) * 1.6 if pine else th * sqrt(1.0 - u * u)
				tops[x] = minf(tops[x], ground - lift)
	for x in W:
		var top := int(tops[x])
		var slope := tops[x + 1] - tops[x]
		for y in range(maxi(top, 0), H):
			var depth := (y - top) / 22.0
			var v := 0.36 - depth * 0.3 - (slope * 0.35 if y <= top + 2 else 0.0)
			if y <= top + 1 and slope <= 0.2:
				v += 0.35  # moonlit rim on the tops that face the moon
			if tree > 0.0 and hash01(x, y, salt + 9) < 0.03:
				v -= 0.2
			var c := pick(ramp, v, x, y)
			var mist := clampf((y - base) / 18.0, 0.0, 1.0) * fog
			mist = floorf(mist * 4.0) / 4.0  # banded fog
			put(x, y, c.lerp(col("slate"), mist))


func _meadow() -> void:
	for y in range(HORIZON, H):
		var near := float(y - HORIZON) / (H - HORIZON)
		for x in W:
			var v := 0.2 + near * 0.35 + noise.get_noise_2d(x * 0.8, y * 1.6) * 0.18
			v += 0.12 * exp(-Vector2(x - MOON.x, (y - 260) * 3.0).length() / 140.0)
			put(x, y, pick(GRASS, v, x, y))
	# Grass blades and clover, denser and longer toward the viewer.
	for i in 5200:
		var y := rng.randi_range(HORIZON + 2, H - 1)
		var x := rng.randi_range(0, W - 1)
		var near := float(y - HORIZON) / (H - HORIZON)
		if rng.randf() > 0.25 + near:
			continue
		var length := 1 + int(near * rng.randf_range(1.0, 5.0))
		var lean := rng.randi_range(-1, 1)
		var tone := "sprig" if rng.randf() < 0.25 + near * 0.3 else "leaf"
		put(x, y + 1, col("deepmoss"))
		for k in length:
			put(x + (lean if k > length / 2 else 0), y - k, col(tone) if k == length - 1 else col("moss"))
	for i in 140:  # night flowers: moon-pale, dew-blue and blossom
		var y := rng.randi_range(HORIZON + 14, H - 30)
		var x := rng.randi_range(0, W - 1)
		var petal: String = ["moonlight", "dewlight", "blossom", "mist"][rng.randi_range(0, 3)]
		put(x, y, col(petal))
		if y > 290:
			put(x - 1, y, col(petal))
			put(x + 1, y, col(petal))
			put(x, y - 1, col(petal))
			put(x, y + 1, col("deepmoss"))
			put(x, y, col("glow") if petal == "blossom" else col("moonlight"))


func _path() -> void:
	# A cubic curve from the bottom edge to the hollow's sill; wide near, narrow far.
	var p0 := Vector2(236, 372)
	var p1 := Vector2(350, 336)
	var p2 := Vector2(330, 290)
	var p3 := Vector2(TREE_X, GROUND_Y)
	_path_x.resize(H)
	_path_w.resize(H)
	_path_x.fill(NAN)
	for i in 800:
		var t := i / 799.0
		var u := 1.0 - t
		var p := u * u * u * p0 + 3.0 * u * u * t * p1 + 3.0 * u * t * t * p2 + t * t * t * p3
		var y := int(round(p.y))
		if y >= 0 and y < H:
			_path_x[y] = p.x
			_path_w[y] = lerpf(40.0, 9.0, pow(t, 0.8))
	for y in range(GROUND_Y - 1, H):
		if is_nan(_path_x[y]):
			_path_x[y] = _path_x[y - 1] if y > 0 and not is_nan(_path_x[y - 1]) else NAN
			_path_w[y] = _path_w[y - 1]
		if is_nan(_path_x[y]):
			continue
		var cx := _path_x[y]
		var hw := _path_w[y]
		for x in range(int(cx - hw - 2), int(cx + hw + 3)):
			var u := (x - cx) / hw
			var ragged := noise.get_noise_2d(x * 2.5, y * 2.5) * 0.14
			var e := absf(u) + ragged
			if e > 1.05:
				continue
			if e > 0.92:
				put(x, y, col("loam"))
				continue
			var v := 0.78 - absf(u) * 0.35 + noise.get_noise_2d(x * 1.5 + 90.0, y * 3.0) * 0.12
			v -= u * 0.1  # the left verge catches the moon
			if absf(absf(u) - 0.45) < 0.05 and y > 300:
				v -= 0.25  # old cart ruts
			put(x, y, pick(PATH, v, x, y))
		# Pebbles: a dark underside, a pale top.
		if hash01(y, 3) < 0.55:
			var px := int(cx + (hash01(y, 4) - 0.5) * hw * 1.4)
			if y > 296:
				put(px, y, col("loam"))
				put(px + 1, y, col("loam"))
				put(px, y - 1, col("moonpath"))
				put(px + 1, y - 1, col("mist"))
			else:
				put(px, y, col("loam"))


# --- the Heartwood -------------------------------------------------------------------------------

func _trunk_center(y: float) -> float:
	return TREE_X + 9.0 * sin(y * 0.021 + 0.6) - 4.0


func _trunk_half(y: float) -> float:
	var flare := clampf((y - 150.0) / (GROUND_Y - 150.0), 0.0, 1.0)
	return 36.0 + 34.0 * pow(flare, 2.2) + 4.0 * sin(y * 0.09)


func _trunk() -> void:
	# A braid of nine strands that twist around each other as they climb (the bark grooves are the
	# gaps between them), with vertical grain, knots and moss on the moonlit side.
	const STRANDS := 9
	for y in range(40, GROUND_Y + 8):
		var cx := _trunk_center(y)
		var hw := _trunk_half(y)
		var ground_fade := clampf((y - GROUND_Y) / 8.0, 0.0, 1.0)
		for x in range(int(cx - hw), int(cx + hw) + 1):
			put(x, y, col("root"))
		var strands: Array[Vector3] = []
		for i in STRANDS:
			var theta := i * TAU / STRANDS + y * 0.03 + sin(y * 0.013 + i) * 0.25
			strands.append(Vector3(cx + hw * 0.78 * sin(theta), cos(theta), i))
		strands.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.y < b.y)
		for s in strands:
			var depth := s.y  # -1 back .. 1 front
			var th := hw * (0.2 + 0.07 * depth) + 1.0
			for x in range(int(s.x - th), int(s.x + th) + 1):
				if absf(x - cx) > hw + 1.0:
					continue
				var u := (x - s.x) / th
				if absf(u) > 1.0:
					continue
				if absf(u) > 0.84:
					put(x, y, col("root"))
					continue
				var side := -(s.x - cx) / hw  # +1 on the trunk's moonlit left
				var v := 0.42 - u * 0.3 + depth * 0.16 + side * 0.14 - ground_fade * 0.3
				var g := grain.get_noise_2d(u * 5.0 + s.z * 13.0, y * 0.35)
				if g > 0.42:
					v -= 0.28  # grain line
				elif g < -0.55 and u < 0.0:
					v += 0.18  # worn ridge
				var c := pick(BARK, v, x, y)
				# Moss clumps on the lit side, each with a shadow pixel under it.
				var m := noise.get_noise_2d(x * 1.8 + 40.0, y * 1.1)
				if side > -0.1 and u < 0.2 and depth > -0.2 and m > 0.28 and y > 120:
					c = pick(["deepmoss", "moss", "leaf", "sprig"], 0.35 + (m - 0.28) * 2.2 - u * 0.2, x, y)
				put(x, y, c)
		# Knot holes that could be eyes (they're not: the tree is on our side).
		for k in [Vector2i(452, 214), Vector2i(506, 176)]:
			if y == k.y:
				for dx in range(-2, 3):
					put(k.x + dx, y, col("root"))
				put(k.x - 3, y, col("bark"))
				put(k.x + 3, y, col("oak"))
			elif absi(y - k.y) == 1:
				for dx in range(-1, 2):
					put(k.x + dx, y, col("root"))
				put(k.x - 2, y, col("oak") if y < k.y else col("bark"))


func _hollow() -> void:
	# The arched doorway full of golden light (art_direction.md "The Heartwood").
	var cx := int(_trunk_center(GROUND_Y - HOLLOW_H / 2.0))
	var top := GROUND_Y - HOLLOW_H
	var light := Vector2(cx, GROUND_Y - 8)
	for y in range(top - 3, GROUND_Y + 1):
		for x in range(cx - HOLLOW_W - 3, cx + HOLLOW_W + 4):
			var e := _arch(x - cx, y - top)
			if e > 3.0:
				continue
			if e > 0.0:  # the bark lip: dark outside, a warm rim where the light catches it
				put(x, y, col("root") if e > 1.5 else col("oak" if x < cx else "bark"))
				if e <= 1.0 and y > top + 6:
					put(x, y, col("ember"))
				continue
			var d := Vector2(x - light.x, (y - light.y) * 0.8).length() / (HOLLOW_H * 0.8)
			put(x, y, pick(FIRE, 1.0 - d * 1.1, x, y, 0.1))
	# A root step at the sill and a small stair of roots inside, dark against the light.
	for x in range(cx - HOLLOW_W, cx + HOLLOW_W + 1):
		put(x, GROUND_Y, col("root"))
		if absi(x - cx) < HOLLOW_W - 3:
			put(x, GROUND_Y - 1, col("bark"))
		if absi(x - cx) < HOLLOW_W - 6:
			put(x, GROUND_Y - 5, col("ember"))
			put(x, GROUND_Y - 4, col("gold"))


func _arch(dx: int, dy: int) -> float:
	# Distance outside a round-topped doorway (<= 0 inside).
	var r := float(HOLLOW_W)
	if dy >= r:
		return absf(dx) - r
	return Vector2(dx, dy - r).length() - r


func _roots() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 77
	# Side, start height and reach for each root; none cross the path to the hollow.
	var roots := [
		[-1, 250.0, 118.0, 30.0, 7.5], [-1, 262.0, 70.0, 18.0, 6.0], [-1, 268.0, 40.0, 10.0, 4.5],
		[1, 248.0, 150.0, 34.0, 8.0], [1, 258.0, 95.0, 26.0, 6.5], [1, 266.0, 52.0, 12.0, 5.0],
		[-1, 240.0, 105.0, 16.0, 5.0], [1, 238.0, 120.0, 14.0, 5.0],
	]
	for spec in roots:
		var side: int = spec[0]
		var y0: float = spec[1]
		var x0 := _trunk_center(y0) + side * (_trunk_half(y0) - 6.0)
		var pts := PackedVector2Array()
		var reach: float = spec[2]
		var drop: float = spec[3]
		for i in 11:
			var t := i / 10.0
			var x := x0 + side * reach * t
			var y := y0 + (GROUND_Y - y0 + drop) * (1.0 - (1.0 - t) * (1.0 - t)) + sin(t * 7.0 + reach) * 3.0 * t
			pts.append(Vector2(x, y))
		tube(pts, spec[4] * 1.35, 1.5, BARK, "root", 0.05)
		# Moss along the top of each root.
		for p in pts:
			if r.randf() < 0.6:
				var mx := int(p.x) + r.randi_range(-2, 2)
				var my := int(p.y - spec[4] * (1.0 - (p.x - x0) / (side * reach + 0.001) * 0.5))
				put(mx, my, col("leaf"))
				put(mx + 1, my, col("sprig"))
				put(mx, my + 1, col("moss"))
		# Where the root meets the grass: a shadow and a few blades over it.
		var end := pts[pts.size() - 1]
		for k in 5:
			var gx := int(end.x) + r.randi_range(-3, 3)
			put(gx, int(end.y) - r.randi_range(0, 2), col("sprig"))
			put(gx, int(end.y) + 1, col("deepmoss"))


func _canopy() -> void:
	# A dome of leaf clumps, cropped by the top and right edges: a dark back layer, the branches,
	# then lit front clusters. The canopy stays warm moss-gold (art_direction.md).
	var r := RandomNumberGenerator.new()
	r.seed = 4242
	var center := Vector2(488, 58)
	var radius := Vector2(196, 104)
	var back: Array[Vector3] = []
	var front: Array[Vector3] = []
	for i in 120:
		var a := r.randf_range(PI * 0.92, TAU * 1.04)
		var dist := sqrt(r.randf())
		var p := center + Vector2(cos(a) * radius.x, sin(a) * radius.y * 0.6) * dist
		if r.randf() < 0.35:
			p.y += r.randf_range(10.0, radius.y * 0.8)  # the lower skirt
		p.x = clampf(p.x, center.x - radius.x, W + 20.0)
		back.append(Vector3(p.x, p.y, r.randf_range(16.0, 28.0)))
	for i in 150:
		var a := r.randf_range(0.0, TAU)
		var dist := pow(r.randf(), 0.6)
		var p := center + Vector2(cos(a) * radius.x * 0.95, sin(a) * radius.y * 0.95) * dist
		front.append(Vector3(p.x, p.y, r.randf_range(8.0, 17.0)))
	back.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.y < b.y)
	front.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.y < b.y)
	for c in back:
		_clump(Vector2(c.x, c.y), c.z, -0.28, center)
	_branches()
	for c in front:
		_clump(Vector2(c.x, c.y), c.z, 0.0, center)
	# Dream-leaves: a few twinkles of gold in the leaves.
	for i in 34:
		var x := r.randi_range(300, W - 1)
		var y := r.randi_range(0, 170)
		if not _is_leaf(img.get_pixel(x, y)):
			continue
		put(x, y, col("heartlight") if i % 3 == 0 else col("glow"))
		if i % 3 == 0:
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				put(x + d.x, y + d.y, col("gold"))


func _is_leaf(c: Color) -> bool:
	for n in LEAVES:
		if c.is_equal_approx(col(n)):
			return true
	return false


func _clump(c: Vector2, radius: float, bias: float, center: Vector2) -> void:
	var ri := int(ceil(radius)) + 2
	for y in range(int(c.y) - ri, int(c.y) + ri + 1):
		for x in range(int(c.x) - ri, int(c.x) + ri + 1):
			if not inside(x, y):
				continue
			var off := Vector2(x, y) - c
			var d := off.length()
			# A ragged, leafy edge: small bites and points out of the circle.
			var edge := radius + grain.get_noise_2d(x * 1.6, y * 1.6) * 2.6
			if d > edge:
				continue
			var n := off / radius
			var v := 0.27 + 0.42 * n.dot(LIGHT) + bias
			v -= clampf((y - center.y) / 150.0, -0.2, 0.4) * 0.5   # the canopy's underside is darker
			v += clampf((center.x - x) / 600.0, -0.1, 0.2)         # the moonlit left edge
			# Leaf texture: small clusters, one step lighter on the lit side, darker in shadow.
			var leaf := grain.get_noise_2d(x * 3.2 + 7.0, y * 3.2)
			if leaf > 0.38:
				v += 0.2 if n.dot(LIGHT) > -0.1 else -0.18
			elif leaf < -0.5:
				v -= 0.16
			if d > edge - 1.4 and n.dot(LIGHT) < 0.3:
				v -= 0.22  # the dark seam under a clump
			put(x, y, pick(LEAVES, v, x, y, 0.12))
			if y > _canopy_bottom[x]:
				_canopy_bottom[x] = y


func _branches() -> void:
	var top := 150.0
	var base := Vector2(_trunk_center(top), top)
	var limbs := [
		[Vector2(-40, -40), Vector2(-120, -70), Vector2(-170, -62), 11.0],
		[Vector2(-10, -60), Vector2(-50, -110), Vector2(-60, -150), 10.0],
		[Vector2(15, -50), Vector2(40, -100), Vector2(70, -150), 10.0],
		[Vector2(40, -30), Vector2(100, -60), Vector2(170, -70), 11.0],
		[Vector2(-20, -24), Vector2(-70, -30), Vector2(-110, -18), 7.0],
		[Vector2(30, -18), Vector2(80, -8), Vector2(140, 6), 7.0],
	]
	for limb in limbs:
		var pts := PackedVector2Array([base + Vector2(0, 20)])
		for k in 3:
			pts.append(base + limb[k])
		tube(pts, limb[3], 2.0, BARK, "root", -0.05)


func _vines() -> void:
	# Vines hang from beneath the canopy, each ending in a glowing dream-fruit.
	var r := RandomNumberGenerator.new()
	r.seed = 909
	var placed := 0
	var tries := 0
	while placed < 16 and tries < 400:
		tries += 1
		var x := r.randi_range(318, W - 6)
		var top := _canopy_bottom[x]
		if top < 60 or absf(x - _trunk_center(top)) < _trunk_half(top) + 4:
			continue
		placed += 1
		var length := r.randi_range(10, 44)
		var phase := r.randf_range(0.0, TAU)
		var fx := x
		for k in length:
			fx = x + int(round(sin(k * 0.18 + phase) * 1.6))
			put(fx, top + k, col("moss") if k % 5 != 0 else col("leaf"))
			if k % 6 == 3:  # a leaf pair
				put(fx - 1, top + k, col("leaf"))
				put(fx + 1, top + k - 1, col("sprig"))
		_fruit(Vector2(fx, top + length + 2))


func _fruit(p: Vector2) -> void:
	glow(p, 7.0, col("gold"), 0.28)
	for y in range(-2, 3):
		for x in range(-2, 3):
			if x * x + y * y > 5:
				continue
			var v := 0.62 - (x + y) * 0.1
			put(int(p.x) + x, int(p.y) + y, pick(FIRE, v, x, y, 0.0))
	put(int(p.x) - 1, int(p.y) - 1, col("heartlight"))
	put(int(p.x), int(p.y) - 3, col("moss"))


func _ground_mist() -> void:
	# Low wisps across the far meadow and around the tree's feet.
	for y in range(HORIZON - 4, 254):
		for x in W:
			# Drawn as dithered palette pixels, not blended (a blend snaps to muddy browns).
			var m := noise.get_noise_2d(x * 0.35 + 200.0, y * 2.6)
			var band := maxf(0.0, 1.0 - absf(y - 240.0) / 12.0)
			var a := (m - 0.12) * band
			if a > 0.2 and (x + y) % 2 == 0:
				put(x, y, col("stone"))
			elif a > 0.1 and bayer(x, y) < 0.25:
				put(x, y, col("slate"))


# --- characters ----------------------------------------------------------------------------------

# The Sporeling (the mascot, tower_art_generator.gd's round pink spirit) seen close up and huge,
# sitting guard in front of the Heartwood: moonlight on its upper left, the hollow's gold on its
# right edge, spores drifting up off it.
const SPORE_X := 312.0
const BODY := ["shade", "bruise", "orchid", "blossom"]
const LIGHT3 := Vector3(-0.5, -0.66, 0.56)


func _giant_sporeling() -> void:
	var cx := SPORE_X
	# Back to front: the lumps behind, the body, the head, the arms, the lumps in front.
	_blob(Vector2(cx - 96, 346), Vector2(34, 26))
	_blob(Vector2(cx + 104, 342), Vector2(38, 28))
	_blob(Vector2(cx, 292), Vector2(92, 118))
	_moss_cap(Vector2(cx, 292), Vector2(92, 118), -0.8)  # before the head, so it stays on the shoulders
	_blob(Vector2(cx - 60, 200), Vector2(18, 13))  # spore lumps on the shoulders
	_blob(Vector2(cx + 64, 206), Vector2(14, 10))
	_blob(Vector2(cx, 146), Vector2(48, 43))
	# Heavy, soft arms: narrow at the shoulder, wide mitts resting on the ground.
	_capsule(Vector2(cx - 74, 214), Vector2(cx - 108, 326), 15.0, 25.0)
	_capsule(Vector2(cx + 74, 218), Vector2(cx + 110, 328), 15.0, 25.0)
	_blob(Vector2(cx - 132, 356), Vector2(22, 16))
	_blob(Vector2(cx + 146, 358), Vector2(26, 18))
	_blob(Vector2(cx - 30, 364), Vector2(28, 18))
	_face(Vector2(cx, 146))
	# It's been sitting guard a long time: moss on its crown and shoulders, a sprout, small mushrooms.
	_moss_cap(Vector2(cx, 146), Vector2(48, 43), -0.6)
	_moss_cap(Vector2(cx - 60, 200), Vector2(18, 13), -0.2)
	_moss_cap(Vector2(cx + 64, 206), Vector2(14, 10), -0.1)
	_sprout(Vector2i(int(cx) - 8, 104))
	_mushroom(Vector2i(int(cx) - 66, 190), 7)
	_mushroom(Vector2i(int(cx) - 54, 192), 5)
	_mushroom(Vector2i(int(cx) + 68, 199), 6)
	# A soft glint on the crown's lit side.
	for g in [Vector2i(-24, -26), Vector2i(-23, -26), Vector2i(-25, -25), Vector2i(-24, -25), Vector2i(-26, -24)]:
		put(int(cx) + g.x, 146 + g.y, col("heartlight"))
	# A little spore floating over its head, and spores drifting up around it.
	_blob(Vector2(cx + 6, 94), Vector2(4, 4))
	glow(Vector2(cx + 6, 94), 9.0, col("blossom"), 0.22)
	var r := RandomNumberGenerator.new()
	r.seed = 606
	for i in 40:
		var p := Vector2(cx + r.randf_range(-150.0, 150.0), r.randf_range(70.0, 330.0))
		if _is_sporeling(img.get_pixel(int(p.x), int(p.y))):
			continue
		if i % 3 == 0:
			glow(p, 4.0, col("blossom"), 0.3)
		put(int(p.x), int(p.y), col("heartlight") if i % 4 == 0 else col("blossom"))
		if i % 5 == 0:
			put(int(p.x) + 1, int(p.y), col("blossom"))
			put(int(p.x), int(p.y) + 1, col("orchid"))


func _is_sporeling(c: Color) -> bool:
	for n in BODY + ["night"]:
		if c.is_equal_approx(col(n)):
			return true
	return false


func _blob(c: Vector2, r: Vector2) -> void:
	for y in range(int(c.y - r.y) - 1, int(c.y + r.y) + 2):
		for x in range(int(c.x - r.x) - 1, int(c.x + r.x) + 2):
			var q := Vector2((x - c.x) / r.x, (y - c.y) / r.y)
			var d := q.length()
			if d > 1.0:
				continue
			_body_pixel(x, y, q, (1.0 - d) * minf(r.x, r.y))


func _capsule(a: Vector2, b: Vector2, r0: float, r1: float) -> void:
	# A tapered capsule, r0 at a and r1 at b.
	var ab := b - a
	var rm := maxf(r0, r1)
	for y in range(int(minf(a.y, b.y) - rm) - 1, int(maxf(a.y, b.y) + rm) + 2):
		for x in range(int(minf(a.x, b.x) - rm) - 1, int(maxf(a.x, b.x) + rm) + 2):
			var p := Vector2(x, y)
			var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
			var radius := lerpf(r0, r1, t)
			var q := (p - (a + ab * t)) / radius
			if q.length() > 1.0:
				continue
			_body_pixel(x, y, q, (1.0 - q.length()) * radius)


func _body_pixel(x: int, y: int, q: Vector2, depth: float) -> void:
	# depth = px inside the edge. A dark outline, a round lit form, a warm rim on the right.
	if depth < 1.3:
		put(x, y, col("night"))
		return
	var n := Vector3(q.x, q.y, sqrt(maxf(0.0, 1.0 - q.length_squared())))
	var lam := n.dot(LIGHT3.normalized())
	# Mostly Blossom pink (the in-game look), Orchid for the turned-away side, Bruise in the deepest shade.
	var v := 0.42 + 0.62 * lam
	var c := pick(BODY, v, x, y, 0.1)
	if q.x > 0.55 and q.y > -0.6 and depth < 3.6:
		c = col("gold") if depth < 2.5 else col("orchid")  # the hollow's light on its right edge
	put(x, y, c)


func _moss_cap(c: Vector2, r: Vector2, level: float) -> void:
	# Moss over the top of a blob (above `level` in its -1..1 height), with a ragged, clumpy lower
	# edge and a dark shadow line under it.
	for y in range(int(c.y - r.y), int(c.y + r.y) + 1):
		for x in range(int(c.x - r.x), int(c.x + r.x) + 1):
			var q := Vector2((x - c.x) / r.x, (y - c.y) / r.y)
			if q.length() > 1.0 or not inside(x, y) or not _is_sporeling(img.get_pixel(x, y)) or img.get_pixel(x, y).is_equal_approx(col("night")):
				continue
			var lobe := fposmod(x + c.x * 0.37, 14.0) / 14.0 * 2.0 - 1.0  # rounded clumps hanging over the edge
			var edge := level + 0.09 * sqrt(maxf(0.0, 1.0 - lobe * lobe)) * (0.5 + 0.5 * hash01(int((x + c.x * 0.37) / 14.0), 7)) + noise.get_noise_1d(x * 2.0) * 0.05
			if q.y > edge + 0.06:
				continue
			if q.y > edge:
				put(x, y, col("bruise"))  # the shadow the moss casts on the body
				continue
			if q.y > edge - 0.035:
				put(x, y, col("deepmoss"))  # the dark underside of each clump
				continue
			var n := Vector3(q.x, q.y, sqrt(maxf(0.0, 1.0 - q.length_squared())))
			var v := 0.18 + 0.5 * n.dot(LIGHT3.normalized())
			var leaf := grain.get_noise_2d(x * 3.0 + 50.0, y * 3.0)
			if leaf > 0.35:
				v += 0.22
			elif leaf < -0.45:
				v -= 0.2
			put(x, y, pick(LEAVES, v, x, y, 0.1))


func _sprout(base: Vector2i) -> void:
	# A two-leaf sprout growing out of the moss on its crown, leaning toward the moon.
	for k in 14:
		var x := base.x - int(k * k / 60.0)
		put(x, base.y - k, col("moss"))
		put(x + 1, base.y - k, col("deepmoss"))
	var tip := Vector2(base.x - 3, base.y - 14)
	for leaf in [[Vector2(-7, -2), 0.5, "leaf", "sprig"], [Vector2(6, -5), -0.6, "sprig", "newleaf"]]:
		var c: Vector2 = tip + leaf[0]
		var ang: float = leaf[1]
		var along := Vector2(cos(ang), sin(ang))
		for y in range(-8, 9):
			for x in range(-9, 10):
				var p := Vector2(x, y)
				var u := p.dot(along) / 7.5
				var w := p.dot(Vector2(-along.y, along.x)) / 3.4
				var d := u * u + w * w
				if d > 1.0:
					continue
				var shade: String = leaf[3] if w < -0.1 else leaf[2]
				put(int(c.x) + x, int(c.y) + y, col("deepmoss") if d > 0.7 else col(shade))


func _mushroom(base: Vector2i, size: int) -> void:
	# A tiny pale mushroom: an outlined cap with a lit top and a dark underside, on a short stem.
	for k in size:
		put(base.x, base.y - k, col("deadwood"))
		put(base.x + 1, base.y - k, col("oak"))
	var top := base.y - size
	for y in range(-size / 2 - 1, 1):
		for x in range(-size, size + 2):
			var q := Vector2((x - 0.5) / (size + 0.5), float(y) / (size / 2.0 + 1.0))
			if q.length() > 1.0:
				continue
			var c := col("moonpath") if q.x < 0.1 and y < 0 else col("path")
			if q.length() > 0.8:
				c = col("root")
			elif y == 0:
				c = col("loam")
			put(base.x + x, top + y, c)


func _face(c: Vector2) -> void:
	# Big dark eyes with a glint, a small smile and blushing cheeks: cute, and not afraid.
	for side in [-1, 1]:
		var ex: float = c.x + side * 15.0
		var ey := c.y - 2.0
		for y in range(-5, 6):
			for x in range(-3, 4):
				if pow(x / 3.2, 2) + pow(y / 5.4, 2) <= 1.0:
					put(int(ex) + x, int(ey) + y, col("void"))
		put(int(ex) - 1, int(ey) - 3, col("heartlight"))
		put(int(ex) - 1, int(ey) - 2, col("heartlight"))
		put(int(ex), int(ey) - 3, col("heartlight"))
		put(int(ex) + 1, int(ey) + 3, col("dusk"))
		for y in 3:  # a blush: solid in the middle row, dithered above and below
			for x in range(-4, 5):
				if (y == 1 and absi(x) < 4) or ((x + y) % 2 == 0 and absi(x) < 3):
					put(int(ex + side * 4) + x, int(ey) + 8 + y, col("orchid"))
	for x in range(-5, 6):
		var y := int(round(pow(x / 5.0, 2) * -2.0))
		put(int(c.x) + x, int(c.y) + 14 + y, col("night"))
	put(int(c.x) - 6, int(c.y) + 11, col("bruise"))
	put(int(c.x) + 6, int(c.y) + 11, col("bruise"))


func _thickets() -> void:
	# The cold edge: thorny dark thickets at the edges of the light, with eyes that watch the dream.
	_thicket(0, 64, 262, true)
	_thicket(W - 44, W, 280, false)
	# Cold mist creeping in along the ground from both edges, as dithered palette pixels.
	for y in range(252, H):
		for x in W:
			var reach := minf(x, W - x) / 90.0
			var m := noise.get_noise_2d(x * 0.8 + 900.0, y * 1.8) + 0.25 - reach * 0.5
			if m > 0.12 and (x + y) % 2 == 0:
				put(x, y, col("bruise"))
			elif m > 0.0 and bayer(x, y) < 0.25:
				put(x, y, col("shade"))


func _thicket(x0: int, x1: int, top: int, left: bool) -> void:
	# A bramble: dark clumps (Dread, Shade texture, a violet rim where the moon finds it) with
	# thorny canes arching out of it toward the light.
	var r := RandomNumberGenerator.new()
	r.seed = x0 + 3
	var width := x1 - x0
	for i in 26:
		var t := r.randf()  # 0 at the screen edge .. 1 toward the light
		var x := x0 + (t if left else 1.0 - t) * width
		var y := top + t * t * 80.0 + r.randf_range(0.0, H - top)
		var radius := r.randf_range(8.0, 16.0) * (1.2 - t * 0.5)
		var ri := int(radius) + 2
		for yy in range(int(y) - ri, int(y) + ri + 1):
			for xx in range(int(x) - ri, int(x) + ri + 1):
				var off := Vector2(xx - x, yy - y)
				if off.length() > radius + grain.get_noise_2d(xx * 2.0, yy * 2.0) * 3.0:
					continue
				var lit := (off / radius).dot(LIGHT if left else Vector2(0.55, -0.83))
				var v := 0.12 + noise.get_noise_2d(xx * 2.5, yy * 2.5) * 0.2
				if off.length() > radius - 1.5 and lit > 0.35:
					v = 0.8  # the violet rim
				put(xx, yy, pick(DREAD, v, xx, yy))
	for i in 7:
		var t := r.randf_range(0.3, 1.0)
		var sx := x0 + (t if left else 1.0 - t) * width
		var sy := top + t * t * 80.0 + 4.0
		var dir := -1.0 if left else 1.0
		var reach := r.randf_range(18.0, 34.0)
		var pts := PackedVector2Array()
		for k in 9:
			var u := k / 8.0
			pts.append(Vector2(sx - dir * reach * u * 0.9, sy - sin(u * PI * 0.8) * reach * 0.6 + u * u * 10.0))
		for k in range(1, pts.size()):
			var a := pts[k - 1]
			var b := pts[k]
			for s in 4:
				var p := a.lerp(b, s / 4.0)
				put(int(p.x), int(p.y), col("dread"))
				put(int(p.x), int(p.y) - 1, col("shade"))
			if k % 2 == 0:  # a thorn
				put(int(b.x), int(b.y) - 2, col("shade"))
				put(int(b.x - dir), int(b.y) - 3, col("bruise"))


func _watchers() -> void:
	# Eyes in the thickets, drawn after the vignette so they stay bright: the nightmares watching.
	for e in [Vector3(20, 284, 0), Vector3(46, 304, 1), Vector3(10, 330, 0), Vector3(W - 22, 298, 1), Vector3(W - 30, 324, 0)]:
		_eyes(Vector2i(int(e.x), int(e.y)), e.z > 0.5)


func _eyes(p: Vector2i, violet: bool) -> void:
	# Two slanted slits, bright toward the middle, in a cold banded glow.
	var c := col("wraithlight") if violet else col("moonlight")
	glow(Vector2(p.x + 4, p.y), 7.0, col("wraithlight"), 0.3, 0.5)
	for side in [0, 1]:
		var x0: int = p.x + side * 7
		var inner := 2 if side == 0 else 0
		for dx in 3:
			put(x0 + dx, p.y, c if dx == inner else col("wraithlight") if violet else col("mist"))
		put(x0 + (0 if side == 0 else 2), p.y - 1, col("bruise"))  # the slant
		put(x0 + inner, p.y + 1, col("bruise"))


func _foreground() -> void:
	# Tall dark grass and ferns framing the bottom, their tips caught by the moon.
	var r := RandomNumberGenerator.new()
	r.seed = 31
	for i in 260:
		var x := r.randi_range(0, W - 1)
		if not is_nan(_path_x[H - 1]) and absf(x - _path_x[H - 1]) < _path_w[H - 1] + 4:
			continue
		var height := r.randi_range(6, 24)
		var lean := r.randf_range(-0.35, 0.35)
		for k in height:
			var bx := x + int(round(lean * k * k / height))
			var tone := "night" if k < height - 3 else ("moss" if k < height - 1 else "leaf")
			if x < 70 or x > W - 44:
				tone = "dread" if k < height - 2 else "shade"
			put(bx, H - 1 - k, col(tone))
	for fern in [Vector2(96, 360), Vector2(186, 364), Vector2(574, 362)]:
		_fern(fern, 22.0)


func _fern(base: Vector2, length: float) -> void:
	for side in [-1, 1]:
		for f in 3:
			var ang: float = -PI / 2 + side * (0.35 + f * 0.35)
			var dir := Vector2(cos(ang), sin(ang))
			for k in int(length - f * 4):
				var p: Vector2 = base + dir * k + Vector2(side * k * k * 0.012, 0)
				put(int(p.x), int(p.y), col("deepmoss"))
				if k % 3 == 0 and k > 2:  # leaflets
					var leaflet := Vector2(-dir.y, dir.x) * 2.0
					put(int(p.x + leaflet.x), int(p.y + leaflet.y), col("moss"))
					put(int(p.x - leaflet.x), int(p.y - leaflet.y), col("night"))


# --- light ---------------------------------------------------------------------------------------

func _warm_light() -> void:
	# The Heartwood's warm halo: gold spilling from the hollow over the roots, the path and the
	# canopy's belly, in three bands.
	var source := Vector2(TREE_X, GROUND_Y - 14)
	for y in range(60, H):
		for x in range(250, W):
			var d := Vector2((x - source.x) * 0.8, (y - source.y) * 1.25).length()
			var a := 0.0
			if d < 26.0:
				a = 0.3
			elif d < 54.0:
				a = 0.18
			elif d < 96.0:
				a = 0.08
			blend(x, y, col("gold"), a)
	# A wedge of light along the path from the doorway.
	for y in range(GROUND_Y + 1, GROUND_Y + 40):
		if is_nan(_path_x[y]):
			continue
		var fade := 1.0 - float(y - GROUND_Y) / 40.0
		for x in range(int(_path_x[y] - _path_w[y]), int(_path_x[y] + _path_w[y]) + 1):
			blend(x, y, col("glow"), 0.35 if fade > 0.5 else 0.18)


func _cold_edges() -> void:
	# A cold, banded vignette toward the edges (art_direction.md "Warm centre, cold edge").
	for y in H:
		for x in W:
			var e := Vector2((x - W * 0.58) / (W * 0.66), (y - H * 0.42) / (H * 0.72)).length()
			e += (bayer(x, y) - 0.5) * 0.05  # dithered band edges
			var a := 0.0
			if e > 1.02:
				a = 0.4
			elif e > 0.94:
				a = 0.25
			elif e > 0.86:
				a = 0.12
			blend(x, y, col("dread"), a)


func _fireflies() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 5150
	for i in 46:
		var a := r.randf_range(0.0, TAU)
		var d := r.randf_range(20.0, 170.0)
		var p := Vector2(TREE_X + cos(a) * d * 1.2, GROUND_Y - 40 + sin(a) * d * 0.6)
		if not inside(int(p.x), int(p.y)):
			continue
		if i % 4 == 0:
			glow(p, 4.0, col("gold"), 0.4)
		put(int(p.x), int(p.y), col("glow") if i % 3 else col("heartlight"))
