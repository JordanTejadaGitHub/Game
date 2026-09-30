extends SceneTree
# Generates the title screen background (screens_ui.md "Meta screens"). Detailed pixel art at 640×360,
# shown at a whole-number scale (3× at 1080p, 2× at 720p, 4× at 1440p).
# A swamp forest at night, seen from the water's edge: an ancient Warden, grown as big as a hill,
# sits half-sunk in still water with its back to the Heartwood. The great tree is far behind it in the
# fog; its hollow is hidden behind the Warden, and its golden light warms the fog, rims the Warden's
# outline and lies on the water. The Warden has the Wardens' shape (a big round head with narrow warm
# eyes, a broad round body, heavy arms) in mossy stone, trees growing on it. Tall trunks fade into
# teal fog; dark trees, roots and reeds frame the shot (the left stays calm for the logo and menu).
# A tiny Shade (a nightmare) crouches on the bank in front, looking up at the Warden; faint eyes wait
# in the dark trees behind it.
# Every pixel is snapped to Heartwood 32 (art_direction.md).
#   assets/ui/title/title_background.png   640×360, the art
#   tools/previews/title_background_3x.png 1920×1080 preview
# Run:  Godot --headless --path . --script res://tools/title_art_generator.gd

const W := 640
const H := 360
const OUT := "res://assets/ui/title/"
const PREVIEW := "res://tools/previews/title_background_3x.png"
const Palette := preload("res://tools/art/heartwood_palette.gd")

const MOON := Vector2(440, 150)  # the light: the Heartwood's hollow, glowing from behind the Warden
const TITAN_X := 438.0
const HEAD := Vector2(438, 96)
const FIGURE := Vector2i(282, 334)  # on the mossy bank in front
const WATER_Y := 292               # the swamp's surface
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

const SKY := ["void", "night", "dusk", "slate", "stone"]
const INK := ["void", "night", "dusk", "slate", "stone", "mist", "moonlight"]
const MOSS := ["deepmoss", "moss", "leaf", "sprig"]
const DARK_MOSS := ["void", "night", "deepmoss", "moss"]
const FOG := ["void", "night", "pool", "slate", "stone", "mist", "moonlight"]  # teal-grey swamp fog
const WARM := ["slate", "loam", "path", "moonpath", "heartlight"]  # fog lit by the Heartwood

const FLESH := ["void", "dread", "shade", "bruise", "loam", "blossom"]  # the Sporeling variant's body
const CAP := ["void", "dread", "shade", "bruise", "stone", "mist"]      # its Bloomcap cap
const BARK := ["void", "root", "bark", "oak", "deadwood"]               # the Rootling variant's bark

## Which Warden the titan is: "stone" (the title art) or "sporeling" (a comparison variant, a vast
## Bloomcap). Set with `-- --warden=sporeling --out=<file.png>`; a variant never overwrites the title art.
var variant := "stone"
var out_file := ""
var img: Image
var noise := FastNoiseLite.new()
var grain := FastNoiseLite.new()
var rng := RandomNumberGenerator.new()
var _colors := {}
var _mask := PackedByteArray()    # titan part id per pixel (0 = none), for rims and occlusion lines
var _shape := []                  # per part: Vector4(centre x, centre y, radius x, radius y) for form shading


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--warden="):
			variant = arg.get_slice("=", 1)
		elif arg.begins_with("--out="):
			out_file = arg.get_slice("=", 1)
	if variant != "stone" and out_file == "":
		push_error("title_art_generator: a variant needs --out=<file.png>")
		quit(1)
		return
	rng.seed = 20260930
	noise.seed = 11
	noise.frequency = 0.045
	noise.fractal_octaves = 3
	grain.seed = 5
	grain.frequency = 0.25
	img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	_mask.resize(W * H)

	_sky()
	_heartwood()
	_trunk_layer(46, 0.58, Vector2(2.0, 5.0), 290.0, 1, 96.0)   # far trees, ghostly in the fog (none over the Heartwood)
	_mist(210, 290, 0.62)
	_titan()
	_islets()
	_mist(246, 292, 0.58)
	_trunk_layer(20, 0.38, Vector2(4.0, 8.0), 292.0, 2, 128.0)  # nearer trees round the Warden
	_mist(262, 292, 0.5)
	_trunk_layer(9, 0.18, Vector2(7.0, 12.0), 294.0, 3, 150.0)  # dark trees, closer still
	_water()
	_mist(288, 302, 0.45)
	_lilies()
	_banks()
	_glow_shrooms()
	_figure()
	_frame_trees()
	_motes()
	_fireflies()
	Palette.snap_image(img)

	if out_file != "":
		img.save_png(out_file)
		var big_variant := img.duplicate() as Image
		big_variant.resize(W * 3, H * 3, Image.INTERPOLATE_NEAREST)
		big_variant.save_png(out_file.get_basename() + "_3x.png")
		print("title_art_generator: wrote ", out_file)
		quit()
		return
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


## True where t crosses 0.5: solid on each side, dithered only in a narrow seam. For light that should
## read as painted bands (the Heartwood's haze, the rim), not a field of dots.
func band(t: float, x: int, y: int, width := 0.06) -> bool:
	if t > 0.5 + width:
		return true
	if t < 0.5 - width:
		return false
	return bayer(x, y) < (t - (0.5 - width)) / (2.0 * width)


## A banded glow: a few alpha steps, never a soft blur (art_direction.md "Banded glow").
func glow(center: Vector2, radius: float, c: Color, strength := 0.35) -> void:
	var r := int(ceil(radius))
	for y in range(int(center.y) - r, int(center.y) + r + 1):
		for x in range(int(center.x) - r, int(center.x) + r + 1):
			var d := Vector2(x, y).distance_to(center) / radius
			if d >= 1.0:
				continue
			var step := 1.0 if d < 0.34 else (0.55 if d < 0.67 else 0.25)
			blend(x, y, c, strength * step)


func blocky(x: int, y: int, cell: int, salt: int) -> float:
	return hash01(int(floor(float(x) / cell)), int(floor(float(y) / cell)), salt)


## Voronoi stones: (distance to the nearest seed, gap to the second nearest, cell hash).
func stones(x: int, y: int, size: float, salt: int) -> Vector3:
	var gx := int(floor(x / size))
	var gy := int(floor(y / size))
	var d1 := 1e9
	var d2 := 1e9
	var id := 0.0
	for oy in range(-1, 2):
		for ox in range(-1, 2):
			var cx := gx + ox
			var cy := gy + oy
			var seed := Vector2((cx + 0.15 + hash01(cx, cy, salt) * 0.7) * size, (cy + 0.15 + hash01(cx, cy, salt + 1) * 0.7) * size)
			var d := Vector2(x, y).distance_to(seed)
			if d < d1:
				d2 = d1
				d1 = d
				id = hash01(cx, cy, salt + 2)
			elif d < d2:
				d2 = d
	return Vector3(d1, d2 - d1, id)


func in_poly(p: Vector2, poly: PackedVector2Array) -> bool:
	var result := false
	var j := poly.size() - 1
	for i in poly.size():
		var a := poly[i]
		var b := poly[j]
		if (a.y > p.y) != (b.y > p.y) and p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x:
			result = not result
		j = i
	return result


func poly_sd(p: Vector2, poly: PackedVector2Array) -> float:
	var best := 1e9
	var j := poly.size() - 1
	for i in poly.size():
		var a := poly[j]
		var b := poly[i]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t))
		j = i
	return -best if in_poly(p, poly) else best


## A rounded outline with a weathered, lumpy edge (boulders, moss mounds), not a clean ellipse.
func lumpy(c: Vector2, r: Vector2, amount: float, salt: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var n := int(clampf((r.x + r.y) * 0.9, 24.0, 90.0))
	for i in n:
		var a := TAU * i / n
		var k := 1.0 + amount * noise.get_noise_1d(i * 7.0 + salt * 131.0) + (hash01(i, salt) - 0.5) * amount * 0.5
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y) * k)
	return pts


## A heavy limb: a tapered, lumpy capsule from a (radius r0) to b (radius r1).
func limb(a: Vector2, b: Vector2, r0: float, r1: float, salt: int) -> PackedVector2Array:
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x)
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in 13:
		var t := i / 12.0
		var p := a.lerp(b, t)
		var r := lerpf(r0, r1, t)
		left.append(p + n * r * (1.0 + 0.1 * noise.get_noise_1d(i * 9.0 + salt * 50.0)))
		right.append(p - n * r * (1.0 + 0.1 * noise.get_noise_1d(i * 9.0 + salt * 50.0 + 400.0)))
	var pts := PackedVector2Array()
	for p in left:
		pts.append(p)
	for i in range(1, 8):  # the rounded end at b
		var ang := PI * i / 8.0
		pts.append(b + (n * cos(ang) + d * sin(ang)) * r1)
	for i in range(right.size() - 1, -1, -1):
		pts.append(right[i])
	for i in range(1, 8):  # the rounded end at a
		var ang := PI * i / 8.0
		pts.append(a + (-n * cos(ang) - d * sin(ang)) * r0)
	return pts


# --- sky -----------------------------------------------------------------------------------------

func _sky() -> void:
	# No open sky: teal-grey fog between the canopy, warmed to pale gold round the Heartwood's light
	# behind the Warden (dithered between the fog and warm ramps, never blended to mud).
	for y in H:
		for x in W:
			var d := Vector2(x, y).distance_to(MOON)
			var v := 0.28 + 0.2 * exp(-absf(y - 200.0) / 70.0) + 0.45 * exp(-d / 110.0)
			v -= clampf((70.0 - y) / 70.0, 0.0, 1.0) * 0.16
			v += noise.get_noise_2d(x * 0.4, y * 1.6) * 0.05
			var c := pick(FOG, v, x, y, 0.1)
			var heat := exp(-d / 150.0) * 1.3 - 0.1 + noise.get_noise_2d(x * 0.7, y * 0.7) * 0.12
			if band(heat, x, y):  # the Heartwood's haze in two painted bands, not scattered dots
				c = pick(WARM, v * 1.05 - 0.1, x, y, 0.1)
			elif band(heat + 0.22, x, y):
				c = pick(WARM, v * 0.9 - 0.14, x, y, 0.1)
			img.set_pixel(x, y, c)


func _heartwood() -> void:
	# The Heartwood, far behind the Warden and deep in the fog: drawn like the other trees (a fogged
	# trunk with soft grain), only vast, with a gentle twist in its strands and roots flaring into the
	# water. Its hollow is hidden behind the Warden; its light is a warm haze on the fog around it.
	for y in range(0, WATER_Y + 1):
		var t := float(y) / WATER_Y
		var cx := MOON.x + sin(y * 0.018) * 5.0
		var hw := 54.0 + 12.0 * t + pow(maxf(0.0, (t - 0.75) / 0.25), 2.0) * 80.0
		for x in range(maxi(int(cx - hw), 0), mini(int(cx + hw), W - 1) + 1):
			var u := (x - cx) / hw
			var band := sin((u * 2.2 + y * 0.02) * PI)  # the strands, twisting slowly
			var v := 0.5 + (0.03 if grain.get_noise_2d(u * 4.0 + 90.0, y * 0.3) > 0.3 else 0.0) - absf(u) * 0.06
			if absf(band) < 0.1:
				v -= 0.06  # a soft groove between strands
			var warm := exp(-Vector2(x, y).distance_to(MOON) / 110.0)
			var c := pick(FOG, v, x, y)
			if band(warm * 0.9 - 0.15 + noise.get_noise_2d(x * 0.7, y * 0.7) * 0.12 + 0.2, x, y):
				c = pick(WARM, v + 0.05, x, y)
			put(x, y, c)
	var r := RandomNumberGenerator.new()
	r.seed = 808
	for branch in [[Vector2(-30, 36), Vector2(-120, 6), Vector2(-210, 22)], [Vector2(30, 30), Vector2(120, 2), Vector2(200, 18)]]:
		var a := Vector2(MOON.x, 0) + (branch[0] as Vector2)
		var b := Vector2(MOON.x, 0) + (branch[1] as Vector2)
		var e := Vector2(MOON.x, 0) + (branch[2] as Vector2)
		for i in 100:
			var s := i / 99.0
			var p := a.lerp(b, s).lerp(b.lerp(e, s), s)
			var rr := lerpf(9.0, 2.0, s)
			for y in range(int(p.y - rr), int(p.y + rr) + 1):
				for x in range(int(p.x - rr), int(p.x + rr) + 1):
					if Vector2(x, y).distance_to(p) <= rr:
						put(x, y, pick(FOG, 0.47, x, y))
			if i % 4 == 0 and r.randf() < 0.6:  # moss hanging from the branch, as on the other trees
				for d in r.randi_range(4, 20):
					put(int(p.x), int(p.y + rr) + d, pick(FOG, 0.5, int(p.x), int(p.y + rr) + d))


# --- forest --------------------------------------------------------------------------------------

func _trunk_layer(count: int, value: float, widths: Vector2, foot_y: float, salt: int, clear: float) -> void:
	# A layer of tall swamp trees rising out of the water into the canopy, bending a little, with
	# branches trailing curtains of moss. `value` sets how far (pale, fogged) the layer is.
	var r := RandomNumberGenerator.new()
	r.seed = salt * 131
	for i in count:
		var x0 := r.randf_range(-10.0, W + 10.0)
		if absf(x0 - TITAN_X) < clear:
			continue
		var half := r.randf_range(widths.x, widths.y)
		var bend := r.randf_range(-10.0, 10.0)
		var foot := foot_y + r.randf_range(-4.0, 6.0)
		for y in range(0, int(foot) + 1):
			var t := y / foot
			var cx := x0 + bend * sin(t * PI) + noise.get_noise_1d(y * 0.6 + x0 * 3.0) * 1.5
			var hw := half * (0.75 + 0.25 * t) + pow(maxf(0.0, (t - 0.88) / 0.12), 2.0) * half * 1.6
			for x in range(int(cx - hw), int(cx + hw) + 1):
				var u := (x - cx) / maxf(hw, 1.0)
				var v := value + (0.04 if grain.get_noise_2d(u * 4.0 + x0, y * 0.3) > 0.3 else 0.0) - absf(u) * 0.04
				if u * signf(MOON.x - cx) > 0.8:
					v += 0.06  # the side facing the glow
				put(x, y, pick(FOG, v, x, y))
		for b in r.randi_range(1, 3):  # branches, each dripping moss
			var by := r.randf_range(foot * 0.15, foot * 0.6)
			var dir := -1.0 if r.randf() < 0.5 else 1.0
			var length := r.randf_range(12.0, 40.0) * (half / widths.y + 0.4)
			var start := Vector2(x0 + bend * sin(by / foot * PI), by)
			for k in int(length):
				var p := start + Vector2(dir * k, -k * 0.35 + k * k * 0.008)
				put(int(p.x), int(p.y), pick(FOG, value, int(p.x), int(p.y)))
				put(int(p.x), int(p.y) + 1, pick(FOG, value - 0.03, int(p.x), int(p.y) + 1))
				if value < 0.5 and k % 3 == 0 and r.randf() < 0.35:  # moss only on the nearer layers
					var drop := r.randi_range(3, 18)
					for d in drop:
						var mx := int(p.x) + int(sin(d * 0.3) * 0.8)
						put(mx, int(p.y) + 2 + d, pick(FOG, value + 0.02, mx, int(p.y) + 2 + d))


# --- mist -------------------------------------------------------------------------------------------

func _mist(y0: int, y1: int, value: float) -> void:
	# A drifting fog band, as dithered palette pixels (a blend would snap to muddy colours).
	for y in range(y0, y1):
		for x in W:
			var m := noise.get_noise_2d(x * 0.35 + y0, y * 2.4)
			var band := maxf(0.0, 1.0 - absf(y - (y0 + y1) * 0.5) / ((y1 - y0) * 0.5))
			var a := (m + 0.3) * band
			if a > 0.42:
				put(x, y, pick(FOG, value, x, y))
			elif a > 0.26 and (x + y) % 2 == 0:
				put(x, y, pick(FOG, value, x, y))
			elif a > 0.14 and bayer(x, y) < 0.25:
				put(x, y, pick(FOG, value, x, y))


# --- the titan -----------------------------------------------------------------------------------

func _titan() -> void:
	# The Warden shape, grown huge: body, arms resting on the ground, knees, spore boulders on the
	# shoulders, then the big round head (drawn last so its chin overlaps the body).
	var parts := [
		[lumpy(Vector2(TITAN_X, 218), Vector2(104, 100), 0.05, 1), Vector4(TITAN_X, 218, 104, 100)],
		[lumpy(Vector2(TITAN_X - 52, 292), Vector2(46, 30), 0.08, 2), Vector4(TITAN_X - 52, 292, 46, 30)],
		[lumpy(Vector2(TITAN_X + 56, 294), Vector2(48, 30), 0.08, 3), Vector4(TITAN_X + 56, 294, 48, 30)],
		[limb(Vector2(TITAN_X - 76, 150), Vector2(TITAN_X - 110, 272), 28.0, 30.0, 4), Vector4(TITAN_X - 101, 211, 30, 70)],
		[limb(Vector2(TITAN_X + 76, 152), Vector2(TITAN_X + 112, 274), 28.0, 30.0, 5), Vector4(TITAN_X + 102, 213, 30, 70)],
		[lumpy(Vector2(TITAN_X - 70, 136), Vector2(22, 15), 0.12, 6), Vector4(TITAN_X - 70, 136, 22, 15)],
		[lumpy(Vector2(TITAN_X + 74, 140), Vector2(18, 13), 0.12, 7), Vector4(TITAN_X + 74, 140, 18, 13)],
		[lumpy(HEAD, Vector2(50, 45), 0.05, 8), Vector4(HEAD.x, HEAD.y, 50, 45)],
	]
	_shape.clear()
	for i in parts.size():
		var poly: PackedVector2Array = parts[i][0]
		_shape.append(parts[i][1])
		var box := Rect2(poly[0], Vector2.ZERO)
		for p in poly:
			box = box.expand(p)
		for y in range(int(box.position.y) - 3, int(box.end.y) + 4):
			for x in range(int(box.position.x) - 3, int(box.end.x) + 4):
				if not inside(x, y):
					continue
				var rough := (blocky(x, y, 2, 60 + i) - 0.5) * 2.2
				if poly_sd(Vector2(x, y), poly) < rough:
					_mask[y * W + x] = i + 1
	for y in H:
		for x in W:
			var id := _mask[y * W + x]
			if id != 0:
				put(x, y, _titan_pixel(x, y, id))
	if variant == "sporeling":
		_spore_mushrooms()
		_face()
		_giant_cap()
		return
	if variant == "rootling":
		_hanging_moss()
		_great_roots()
		_face()
		_giant_sprout()
		return
	_hanging_moss()
	_crown_tree(Vector2(HEAD.x - 20, HEAD.y - 40), 1.0)
	_crown_tree(Vector2(TITAN_X - 74, 124), 0.6)
	_crown_tree(Vector2(TITAN_X + 90, 130), 0.5)
	_spore_mushrooms()
	_face()


func _titan_pixel(x: int, y: int, id: int) -> Color:
	var shape: Vector4 = _shape[id - 1]
	var q := Vector2((x - shape.x) / shape.z, (y - shape.y) / shape.w)
	var to_moon := (MOON - Vector2(x, y)).normalized()
	# Body, arms and shoulders share one stone pattern, so the arms read as grown from the body.
	var s := stones(x, y, 8.0, 7 if id in [1, 4, 5, 6, 7] else 7 + id)
	# Round form: brighter toward the moon, darker away; plus stones, cracks and a sky-lit top.
	# Backlit, it is one great dark mass against the light: detail lives in the upper body and fades below.
	var v := 0.17 + 0.1 * q.normalized().dot(to_moon) * minf(q.length(), 1.0) + (s.z - 0.5) * 0.08
	if s.y < 1.0 and variant != "sporeling":  # flesh has no cracks
		v -= 0.07 * (1.0 - clampf((y - 160.0) / 100.0, 0.0, 1.0))  # the cracks, softer and lost in the mist lower down
	if _part_at(x, y - 2) == 0:
		v += 0.1
	var behind := false
	for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var other := _part_at(x + d.x, y + d.y)
		if other != 0 and other < id:
			behind = true
	if id == 4 or id == 5:
		v += 0.03  # the arms stand a little forward of the body
	if behind:
		if id == 8:
			return col("void")  # the chin keeps a hard line under the head
		v -= 0.2  # elsewhere a soft shadowed crease: the arms and knees grow out of the body
	if id == 1:
		# The body darkens where an arm hangs beside it (a shadow, not an outline).
		for dx in [-4, -3, -2, 2, 3, 4]:
			var other := _part_at(x + dx, y)
			if other == 4 or other == 5:
				v -= 0.09
				break
	# Backlit: the Heartwood's light is behind it, so its outer edges catch a rim near the light. Broken
	# and fading with distance, never a full outline.
	var rim := 0
	for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		if _part_at(x + d.x, y + d.y) == 0:
			rim = 2
	if rim == 0:
		for d in [Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, -2)]:
			if _part_at(x + d.x, y + d.y) == 0:
				rim = 1
	var warm := exp(-Vector2(x, y).distance_to(MOON) / 130.0)
	var lit := warm * 1.6 - 0.3 + noise.get_noise_2d(x * 2.0, y * 2.0) * 0.3
	if rim == 2 and y < WATER_Y - 4 and band(lit, x, y, 0.1):
		return col("glow") if lit > 0.8 else col("gold")
	if rim == 1 and lit < 0.35:
		rim = 0  # away from the light the edge stays in shadow
	var fog := clampf((y - 160.0) / 120.0, 0.0, 1.0) * 0.8 + 0.05  # the mist swallows it from the waist down
	if variant == "sporeling":
		return _flesh_pixel(x, y, id, v, rim, lit, fog)
	if variant == "rootling":
		return _bark_pixel(x, y, v, rim, lit, fog)
	# Moss grows over the tops and down the sides in thick patches.
	var mossy := noise.get_noise_2d(x * 0.9 + 13.0, y * 0.9) - q.y * 0.25
	if id == 8:
		mossy -= 0.2 if absf(q.x) < 0.7 and q.y > -0.45 else -0.2  # keep the face mostly bare
	if mossy > 0.2:
		var mv := 0.22 + (s.z - 0.5) * 0.1 + (0.45 if rim == 2 else (0.22 if rim == 1 else 0.0))
		if grain.get_noise_2d(x * 3.0, y * 3.0) > 0.4:
			mv += 0.14
		if band(fog + noise.get_noise_2d(x * 0.8, y * 0.8) * 0.2, x, y, 0.08):
			return pick(FOG, lerpf(v, 0.52, fog), x, y)
		return pick(MOSS, mv - 0.08, x, y)
	if rim == 2:
		v = maxf(v, 0.3 + lit * 0.4)
	elif rim == 1:
		v = maxf(v, 0.4)
	return pick(FOG, lerpf(v, 0.5, fog), x, y, 0.1)


## The Sporeling variant's body: soft fungal flesh (no cracks), fibrous streaks and pale spore
## freckles, in shadow under its cap.
func _flesh_pixel(x: int, y: int, id: int, v: float, rim: int, lit: float, fog: float) -> Color:
	v += 0.05 if grain.get_noise_2d(x * 0.5, y * 3.0) > 0.4 else 0.0  # fibres, running down
	if blocky(x, y, 2, 91) > 0.988:
		v += 0.1  # freckles, faint
	if id == 8 and y < HEAD.y - 4:
		v -= 0.12  # the cap's shadow on the head
	if rim == 2:
		v = maxf(v, 0.3 + lit * 0.4)
	elif rim == 1:
		v = maxf(v, 0.4)
	if band(fog + noise.get_noise_2d(x * 0.8, y * 0.8) * 0.2, x, y, 0.08):
		return pick(FOG, lerpf(v, 0.5, fog), x, y, 0.1)
	return pick(FLESH, v + 0.14, x, y, 0.1)


## The Rootling variant's body: old bark in long vertical grain with dark grooves, moss in the hollows.
func _bark_pixel(x: int, y: int, v: float, rim: int, lit: float, fog: float) -> Color:
	var g := grain.get_noise_2d(x * 0.7 + noise.get_noise_1d(y * 0.4) * 6.0, y * 0.035)
	if absf(g) < 0.1:
		v -= 0.2  # a groove between the bark ridges
	elif g > 0.3:
		v += 0.06  # a ridge catching a little light
	if rim == 2:
		v = maxf(v, 0.3 + lit * 0.4)
	elif rim == 1:
		v = maxf(v, 0.4)
	if band(fog + noise.get_noise_2d(x * 0.8, y * 0.8) * 0.2, x, y, 0.08):
		return pick(FOG, lerpf(v, 0.5, fog), x, y, 0.1)
	if noise.get_noise_2d(x * 0.6 + 40.0, y * 0.9) > 0.5:
		return pick(MOSS, v + 0.02, x, y, 0.1)  # moss in the hollows
	return pick(BARK, v + 0.1, x, y, 0.1)


## The Rootling variant's crown: the Rootling's sprout grown huge, two great leaves on a stem, backlit.
func _giant_sprout() -> void:
	var base := Vector2(HEAD.x + 4, HEAD.y - 40)
	for k in 18:  # the stem, curving a little
		var p := base + Vector2(sin(k * 0.08) * 4.0, -k)
		for dx in range(-2, 3):
			put(int(p.x) + dx, int(p.y), col("night") if absi(dx) < 2 else col("deepmoss"))
	var tip := base + Vector2(1, -18)
	for leaf: Vector3 in [Vector3(-1.0, 40.0, 0.1), Vector3(1.0, 36.0, -0.1)]:
		var dir := Vector2(leaf.x, -0.25).normalized().rotated(leaf.z)
		var length := leaf.y
		var n := Vector2(-dir.y, dir.x)
		for k in int(length):
			var t := k / length
			var half := sin(t * PI) * length * 0.3
			var mid := tip + dir * k + Vector2(0, t * t * 14.0 - sin(t * PI) * 4.0)  # drooping at the tip
			for w in range(-int(half), int(half) + 1):
				var p := mid + n * w
				var warm := exp(-p.distance_to(MOON) / 130.0)
				var edge := absi(w) >= int(half) - 1
				var v := 0.18 + (0.08 if absi(w) < 1 else 0.0) + (0.1 if grain.get_noise_2d(p.x * 2.0, p.y * 2.0) > 0.35 else 0.0)
				if edge and w * signf(n.y) < 0 and band(warm * 1.6 - 0.1, int(p.x), int(p.y), 0.1):
					put(int(p.x), int(p.y), col("gold"))  # the Heartwood's rim on the upper edge
				else:
					put(int(p.x), int(p.y), pick(MOSS, v, int(p.x), int(p.y)))
			put(int(mid.x), int(mid.y), col("deepmoss"))  # the vein


## The Rootling variant's roots: great roots arching from its base into the water.
func _great_roots() -> void:
	for root: Array in [[Vector2(-104, 250), Vector2(-160, 214), Vector2(-186, 296), 10.0, 4.0],
			[Vector2(-80, 268), Vector2(-120, 240), Vector2(-132, 300), 8.0, 3.0],
			[Vector2(106, 252), Vector2(164, 216), Vector2(188, 298), 10.0, 4.0],
			[Vector2(82, 270), Vector2(124, 242), Vector2(138, 300), 8.0, 3.0],
			[Vector2(-20, 290), Vector2(-36, 284), Vector2(-50, 302), 6.0, 3.0]]:
		var off := Vector2(TITAN_X, 0)
		_root_arch(off + (root[0] as Vector2), off + (root[1] as Vector2), off + (root[2] as Vector2), root[3], root[4])


## The Sporeling variant's crown: a vast cap (the Bloomcap's), backlit, its brim drooping low over the
## eyes; faintly glowing gills underneath and spores drifting down from them.
func _giant_cap() -> void:
	var c := Vector2(HEAD.x, HEAD.y - 22)
	var rx := 108.0
	var top := 62.0
	for x in range(int(c.x - rx) - 4, int(c.x + rx) + 5):
		var u := (x - c.x) / rx
		if absf(u) > 1.0:
			continue
		var dome_top := c.y - top * sqrt(1.0 - u * u) + noise.get_noise_1d(x * 3.0) * 3.0
		var under := c.y + pow(absf(u), 1.6) * 18.0  # where the dome's rim meets the gills
		var brim := c.y + 7.0 + pow(absf(u), 1.6) * 26.0 + grain.get_noise_1d(x * 2.0) * 2.0
		for y in range(int(dome_top), int(brim) + 1):
			if not inside(x, y):
				continue
			var warm := exp(-Vector2(x, y).distance_to(MOON) / 130.0)
			if y < under:
				# The dome: dark against the light, pale spots, a gold rim along its top edge.
				var edge := y - dome_top
				var lit := warm * 1.6 - 0.3 + noise.get_noise_2d(x * 2.0, y * 2.0) * 0.3
				if edge < 2.0 and band(lit + 0.25, x, y, 0.1):
					put(x, y, col("glow") if edge < 1.0 and lit > 0.6 else col("gold"))
					continue
				var v := 0.24 + (1.0 - (y - dome_top) / maxf(under - dome_top, 1.0)) * 0.12
				if noise.get_noise_2d(x * 1.4 + 70.0, y * 2.2) > 0.32:
					v += 0.2  # the Bloomcap's pale patches
				put(x, y, pick(CAP, v, x, y, 0.1))
			else:
				# The gills: dark, fine lines running out from the stem, some glowing faintly.
				var ang := atan2(y - (c.y - 40.0), x - c.x)
				var line := absf(fmod(ang * 60.0, 1.0))
				var c2 := col("void") if line > 0.3 else col("dread")
				if line < 0.12 and hash01(int(ang * 60.0), 3) > 0.55 and y > brim - 4.0:
					c2 = col("blossom") if hash01(x, y, 5) > 0.5 else col("orchid")
				put(x, y, c2)
	var r := RandomNumberGenerator.new()
	r.seed = 77
	for i in 260:  # spores, falling from the gills
		var sx := c.x + r.randf_range(-rx, rx) * 0.95
		var sy := c.y + 14.0 + pow(r.randf(), 1.8) * 170.0
		if sy >= WATER_Y:
			continue
		var fade := 1.0 - (sy - c.y) / 190.0
		if r.randf() > fade:
			continue
		put(int(sx), int(sy), col("blossom") if r.randf() < 0.5 else col("dewlight"))


func _part_at(x: int, y: int) -> int:
	if not inside(x, y):
		return 0
	return _mask[y * W + x]


func _hanging_moss() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 88
	for i in 1400:
		var x := r.randi_range(300, 580)
		var y := r.randi_range(100, 260)
		if _part_at(x, y) == 0 or _part_at(x, y + 1) != 0:
			continue
		var length := r.randi_range(3, 14)
		for k in length:
			if _part_at(x, y + 1 + k) != 0:
				break
			put(x, y + 1 + k, col("deepmoss") if k < length - 2 else col("moss"))
			if k % 4 == 2:
				put(x + 1, y + 1 + k, col("deepmoss"))


func _crown_tree(base: Vector2, scale: float) -> void:
	# A small tree growing out of the titan, backlit.
	var trunk_h := 22.0 * scale
	for k in int(trunk_h):
		var x := int(base.x + sin(k * 0.2) * 1.5)
		put(x, int(base.y) - k, col("night"))
		put(x + 1, int(base.y) - k, col("night"))
		put(x + 2, int(base.y) - k, col("slate") if k % 3 else col("night"))
	var clumps := [Vector3(-7, -26, 9), Vector3(4, -29, 8), Vector3(-14, -20, 6), Vector3(10, -21, 6), Vector3(-3, -35, 6)]
	for cl: Vector3 in clumps:
		var c := base + Vector2(cl.x, cl.y) * scale
		var rr := cl.z * scale + 1.0
		for y in range(int(c.y - rr) - 2, int(c.y + rr) + 3):
			for x in range(int(c.x - rr) - 2, int(c.x + rr) + 3):
				var off := Vector2(x, y) - c
				if off.length() > rr + grain.get_noise_2d(x * 2.0, y * 2.0) * 2.2:
					continue
				var dir := (MOON - Vector2(x, y)).normalized()
				var edge := off.length() > rr - 1.6 and off.normalized().dot(dir) > 0.3
				var v := 0.15 + (0.5 if edge else 0.0) + (0.12 if grain.get_noise_2d(x * 3.0, y * 3.0) > 0.35 else 0.0)
				put(x, y, pick(MOSS, v, x, y))


func _spore_mushrooms() -> void:
	# Pale glowing mushrooms on its knees and shoulders.
	for m in [Vector3(TITAN_X - 70, 266, 4), Vector3(TITAN_X - 60, 268, 3), Vector3(TITAN_X - 36, 266, 5),
			Vector3(TITAN_X + 40, 268, 4), Vector3(TITAN_X + 72, 267, 5), Vector3(TITAN_X - 80, 123, 3),
			Vector3(TITAN_X + 66, 129, 3)]:
		var p := Vector2(m.x, m.y)
		var s := int(m.z)
		glow(p + Vector2(0, -s), s * 3.0, col("dewlight"), 0.18)
		for k in s:
			put(int(p.x), int(p.y) - k, col("mist"))
		for y in range(-s / 2 - 1, 1):
			for x in range(-s, s + 1):
				if Vector2(x, y * 2).length() > s + 0.5:
					continue
				put(int(p.x) + x, int(p.y) - s + y, col("dewlight") if y < 0 and x < s / 2 else col("dew"))
		put(int(p.x) - s / 2, int(p.y) - s - 1, col("heartlight"))


func _face() -> void:
	# No mouth: two narrow warm eyes deep in shadowed sockets under a heavy brow. Watchful, not cute.
	for side in [-1, 1]:
		var e := HEAD + Vector2(side * 17, 0)
		for y in range(-5, 6):  # the socket
			for x in range(-8, 9):
				if pow(x / 8.5, 2) + pow(y / 5.5, 2) > 1.0 or _part_at(int(e.x) + x, int(e.y) + y) == 0:
					continue
				put(int(e.x) + x, int(e.y) + y, col("void") if y > -4 else col("night"))
		glow(e, 8.0, col("gold"), 0.18)
		for x in range(-5, 6):  # the slit, brightest in the middle
			var c := col("heartlight") if absi(x) < 2 else (col("glow") if absi(x) < 4 else col("ember"))
			put(int(e.x) + x, int(e.y), c)
			if absi(x) < 4:
				put(int(e.x) + x, int(e.y) + 1, col("gold") if absi(x) < 2 else col("ember"))
	for x in range(-30, 31):  # the brow's hard shadow line
		var bx := int(HEAD.x) + x
		var by := int(HEAD.y) - 7 + int(absf(x) / 10.0)
		if _part_at(bx, by) != 0:
			put(bx, by, col("void"))


# --- foreground ----------------------------------------------------------------------------------

func _water() -> void:
	# Still swamp water: everything above mirrored and darkened, broken by ripples and pale glints.
	var src := img.duplicate() as Image
	for y in range(WATER_Y, H):
		var depth := float(y - WATER_Y) / (H - WATER_Y)
		for x in W:
			var ripple := int(round(sin(y * 0.9 + x * 0.04) * (0.5 + depth * 2.0)))
			var sy := clampi(2 * WATER_Y - y - 1, 0, H - 1)
			var sx := clampi(x + ripple, 0, W - 1)
			put(x, y, src.get_pixel(sx, sy).lerp(col("night"), 0.45 + depth * 0.25))
			var glint := noise.get_noise_2d(x * 0.25, y * 3.0)
			if glint > 0.45 and y % 2 == 0:
				put(x, y, col("slate") if glint < 0.6 else col("stone"))


func _banks() -> void:
	# Mossy mud banks and tussocks in the water; the Shade crouches on the one in front.
	for b: Vector4 in [Vector4(190, 302, 30, 9), Vector4(418, 308, 36, 10), Vector4(70, 326, 96, 22),
			Vector4(566, 336, 96, 24), Vector4(282, 352, 70, 24)]:
		for y in range(int(b.y - b.w) - 3, mini(int(b.y + b.w) + 2, H)):
			for x in range(int(b.x - b.z) - 4, int(b.x + b.z) + 5):
				var q := Vector2((x - b.x) / b.z, (y - b.y) / b.w)
				if q.length() > 1.0 + grain.get_noise_2d(x * 1.8, y * 1.8) * 0.25:
					continue
				var lit := q.y < -0.6 and (x - b.x) * signf(MOON.x - b.x) > 0.0
				var v := 0.3 + (0.4 if lit else 0.0) + (0.14 if grain.get_noise_2d(x * 3.0, y * 3.0) > 0.4 else 0.0) - maxf(q.y, 0.0) * 0.3
				var c := pick(DARK_MOSS, v, x, y)  # dark mounds, only the rim catches the glow
				if q.y > 0.35:
					c = pick(["void", "root", "bark"], 0.3 + (0.25 if grain.get_noise_2d(x * 2.0, y * 2.0) > 0.3 else 0.0), x, y)  # wet mud
				put(x, y, c)
		_reeds(Vector2(b.x - b.z * 0.6, b.y - b.w * 0.5), 6, b.w * 1.6 + 6.0, int(b.x))
		_reeds(Vector2(b.x + b.z * 0.55, b.y - b.w * 0.4), 5, b.w * 1.4 + 5.0, int(b.x) + 1)


func _reeds(base: Vector2, count: int, height: float, salt: int) -> void:
	# A clump of tall swamp grass: long curving blades, dark at the root, tips catching the light.
	var r := RandomNumberGenerator.new()
	r.seed = salt * 7 + 3
	for i in count:
		var lean := r.randf_range(-0.9, 0.9)
		var h := height * r.randf_range(0.5, 1.0)
		var x0 := base.x + r.randf_range(-6.0, 6.0)
		for k in int(h):
			var t := k / h
			var p := Vector2(x0 + lean * t * t * h * 0.6, base.y - k * (1.0 - t * 0.25))
			var c := col("void") if t < 0.5 else (col("deepmoss") if t < 0.85 else col("moss"))
			put(int(p.x), int(p.y), c)
			if t < 0.3:
				put(int(p.x) + 1, int(p.y), col("night"))


func _root_arch(a: Vector2, c: Vector2, b: Vector2, r0: float, r1: float) -> void:
	# A gnarled root arching out of the water: dark, with a thin rim where it faces the glow.
	for i in 80:
		var t := i / 79.0
		var p := a.lerp(c, t).lerp(c.lerp(b, t), t)
		var rr := lerpf(r0, r1, t)
		for y in range(int(p.y - rr) - 1, int(p.y + rr) + 2):
			for x in range(int(p.x - rr) - 1, int(p.x + rr) + 2):
				var off := Vector2(x, y) - p
				if off.length() > rr:
					continue
				var lit := off.normalized().dot((MOON - p).normalized()) > 0.5 and off.length() > rr - 1.5
				put(x, y, col("slate") if lit else (col("night") if grain.get_noise_2d(x * 2.0, y * 2.0) > 0.3 else col("void")))


func _figure() -> void:
	# The nightmares are the game's own sprites (assets/creatures/, frame 0), so they look exactly like
	# the nightmares in play. They stand on the banks and roots, turned toward the Warden; only the
	# will-o'-wisp floats, as it does in the game. Further ones sink a little into the fog.
	_sprite("leaf_bug", Vector2i(0, 2), Vector2i(282, 340), false, 0.0)     # a Shade on the front bank, its back to us
	_sprite("leaf_bug", Vector2i(0, 0), Vector2i(236, 346), false, 0.0)    # another, creeping right toward it
	_sprite("gravecrawler", Vector2i(0, 0), Vector2i(560, 334), true, 0.0)  # crawling off the right bank
	_sprite("weeper", Vector2i(0, 0), Vector2i(84, 322), false, 0.15)       # on the left bank, turned toward it
	_sprite("watcher", Vector2i(0, 0), Vector2i(186, 302), false, 0.35)     # half in the fog, all eyes on it
	_sprite("will_o_wisp", Vector2i(0, 0), Vector2i(360, 290), false, 0.0)  # drifting toward the light


func _sprite(sheet: String, frame: Vector2i, foot: Vector2i, flip: bool, fog: float) -> void:
	# Blits one 64×64 frame with its lowest opaque pixel on `foot`: a soft contact shadow first,
	# opaque pixels only (the sheet's soft ground shadow is left out), dithered into the fog by `fog`.
	var src := Image.load_from_file(ProjectSettings.globalize_path("res://assets/creatures/%s.png" % sheet))
	var cell := src.get_region(Rect2i(frame * 64, Vector2i(64, 64)))
	var bottom := 0
	var left := 64
	var right := 0
	for y in 64:
		for x in 64:
			if cell.get_pixel(x, y).a > 0.6:
				bottom = maxi(bottom, y)
				left = mini(left, x)
				right = maxi(right, x)
	var cx := (left + right) / 2
	for x in range(-(right - left) / 2 - 2, (right - left) / 2 + 3):
		if (x + foot.y) % 2 == 0 or absi(x) < (right - left) / 3:
			put(foot.x + x, foot.y + 1, col("void"))
	for y in 64:
		for x in 64:
			var c := cell.get_pixel(x, y)
			if c.a <= 0.6:
				continue
			var px := foot.x + ((cx - x) if flip else (x - cx))
			var py := foot.y - (bottom - y)
			c.a = 1.0
			if fog > 0.0 and bayer(px, py) < fog:
				c = pick(FOG, 0.34, px, py)
			put(px, py, c)


# --- dreamlike touches ---------------------------------------------------------------------------

func _islets() -> void:
	# Small islands of moss and rock floating in the fog, trailing roots (like the dream-map's islands
	# adrift in their void). Fogged by distance like the trees.
	for isl: Vector4 in [Vector4(246, 134, 30, 0.2), Vector4(324, 70, 12, 0.5), Vector4(588, 108, 16, 0.45)]:
		var c := Vector2(isl.x, isl.y)
		var w := isl.z
		var fog := isl.w
		for y in range(int(c.y) - 3, int(c.y + w * 0.9) + 1):
			var t := (y - c.y) / (w * 0.9)  # 0 at the top .. 1 at the point underneath
			var half := w * (1.0 - maxf(t, 0.0)) * (1.0 + noise.get_noise_1d(y * 2.0 + c.x) * 0.2)
			for x in range(int(c.x - half), int(c.x + half) + 1):
				var col_c: Color
				if y < c.y:
					col_c = pick(MOSS, 0.3 + (0.3 if x > c.x else 0.0), x, y)  # the grassy top
				else:
					var v := 0.3 - t * 0.15 + (0.06 if grain.get_noise_2d(x * 3.0, y * 3.0) > 0.3 else 0.0)
					col_c = pick(["night", "root", "bark", "loam"], v + 0.2, x, y)
				if bayer(x, y) < fog:
					col_c = pick(FOG, 0.46, x, y)
				put(x, y, col_c)
		for k in int(w * 0.6):  # roots dangling from the underside
			var rx := int(c.x - w * 0.5 + hash01(k, int(c.x)) * w)
			var length := int(4.0 + hash01(k, int(c.y)) * w * 0.8)
			for d in length:
				var yy := int(c.y + w * 0.9 * (1.0 - absf(rx - c.x) / w)) + d
				put(rx + int(sin(d * 0.4 + k) * 0.8), yy, pick(FOG, 0.3 + fog * 0.2, rx, yy))
		for g in 3:  # a few glowing blossoms on top
			var gx := int(c.x - w * 0.6 + hash01(g, int(c.x) + 5) * w * 1.2)
			put(gx, int(c.y) - 2, col("dewlight") if g % 2 else col("blossom"))
			glow(Vector2(gx, c.y - 2), 3.0, col("dewlight"), 0.25)


func _lilies() -> void:
	# Lily pads on the still water, some holding a softly glowing bloom.
	var r := RandomNumberGenerator.new()
	r.seed = 2112
	for i in 26:
		var p := Vector2(r.randf_range(150.0, 620.0), r.randf_range(300.0, 352.0))
		var near := (p.y - WATER_Y) / (H - WATER_Y)
		var rw := 3.0 + near * 6.0
		for y in range(int(p.y - rw * 0.35) - 1, int(p.y + rw * 0.35) + 2):
			for x in range(int(p.x - rw), int(p.x + rw) + 1):
				var q := Vector2((x - p.x) / rw, (y - p.y) / (rw * 0.35))
				if q.length() > 1.0 or (q.x > 0.2 and absf(q.y) < 0.25):  # the notch
					continue
				put(x, y, pick(MOSS, 0.2 + (0.35 if q.y < -0.3 else 0.0), x, y))  # lit along the far edge
		if r.randf() < 0.45:
			var bloom := Vector2i(int(p.x - rw * 0.3), int(p.y - 1))
			glow(Vector2(bloom), 5.0 + near * 3.0, col("blossom"), 0.22)
			put(bloom.x, bloom.y, col("heartlight"))
			put(bloom.x - 1, bloom.y, col("blossom"))
			put(bloom.x + 1, bloom.y, col("blossom"))
			put(bloom.x, bloom.y - 1, col("blossom"))


func _glow_shrooms() -> void:
	# Clusters of luminous mushrooms on the banks and the frame roots, pale blue and soft pink.
	for cl: Vector3 in [Vector3(58, 312, 0), Vector3(128, 318, 1), Vector3(206, 338, 0), Vector3(318, 334, 1),
			Vector3(520, 326, 0), Vector3(604, 318, 1), Vector3(160, 296, 0), Vector3(424, 300, 1)]:
		var cap := "dewlight" if cl.z < 0.5 else "blossom"
		var dark := "dew" if cl.z < 0.5 else "orchid"
		glow(Vector2(cl.x, cl.y - 3), 9.0, col(cap), 0.22)
		for m in 3:  # one big cap and two small ones: rounded domes on short pale stems
			var size := 3 if m == 0 else 2
			var offsets: Array[int] = [0, -5, 5]
			var mx: int = int(cl.x) + offsets[m] + int(hash01(m, int(cl.x)) * 2.0)
			var h := size + 1 + int(hash01(m, int(cl.y)) * 2.0)
			for k in h:
				put(mx, int(cl.y) - k, col("mist"))
			var top := int(cl.y) - h
			for x in range(-size, size + 1):
				put(mx + x, top, col(dark))  # the dark gill line under the cap
				if absi(x) < size:
					put(mx + x, top - 1, col(cap))
				if absi(x) < size - 1 or size == 2 and x == 0:
					put(mx + x, top - 2, col("heartlight") if x <= 0 else col(cap))


func _motes() -> void:
	# Dream motes drifting up through the fog, and faint four-point sparkles.
	var r := RandomNumberGenerator.new()
	r.seed = 4040
	for i in 90:
		var p := Vector2(r.randf_range(160.0, 630.0), r.randf_range(30.0, 330.0))
		var kind := i % 3
		var c := col("dewlight") if kind == 0 else (col("blossom") if kind == 1 else col("glow"))
		if i % 5 == 0:
			glow(p, 3.5, c, 0.3)
		put(int(p.x), int(p.y), c)
		if i % 7 == 0:  # a short fading trail below a rising mote
			put(int(p.x), int(p.y) + 1, col("mist"))
			put(int(p.x), int(p.y) + 3, col("slate"))
	for i in 14:
		var p := Vector2i(r.randi_range(170, 630), r.randi_range(30, 280))
		put(p.x, p.y, col("heartlight"))
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			put(p.x + d.x, p.y + d.y, col("mist"))
		if i % 3 == 0:
			for d in [Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2)]:
				put(p.x + d.x, p.y + d.y, col("slate"))


func _frame_trees() -> void:
	# Dark foreground trees framing the shot: a big trunk on the left (the menu sits over its
	# shadow), a thinner one on the right, an overhanging canopy fringe with hanging vines, ferns.
	_trunk(Vector2(26, 360), 0, 30.0, 1)
	_trunk(Vector2(624, 360), 0, 18.0, 2)
	_trunk(Vector2(140, 360), 60, 8.0, 3)
	# The canopy fringe along the top, leaves hanging in clumps.
	for x in W:
		var depth := 14.0 + noise.get_noise_1d(x * 1.2) * 12.0 + (40.0 if x < 180 else 0.0) * (1.0 - x / 180.0)
		depth += (30.0 if x > 560 else 0.0) * ((x - 560) / 80.0)
		for y in range(0, int(depth)):
			var leaf := grain.get_noise_2d(x * 2.0, y * 2.0)
			var c := pick(DARK_MOSS, 0.08 + (0.3 if leaf > 0.4 else 0.0) * (1.0 - y / depth), x, y)
			put(x, y, c)
		if int(depth) < H:  # the lit lower lip of the canopy
			if noise.get_noise_1d(x * 3.0 + 50.0) > 0.1:
				put(x, int(depth), col("deepmoss"))
	var r := RandomNumberGenerator.new()
	r.seed = 404
	for i in 30:
		var x := r.randi_range(0, W - 1)
		if x > 330 and x < 550:
			continue  # keep the titan's head clear
		var top := 20 + r.randi_range(0, 30)
		var length := r.randi_range(20, 90)
		var phase := r.randf_range(0.0, TAU)
		for k in length:
			var vx := x + int(round(sin(k * 0.09 + phase) * 2.5))
			put(vx, top + k, col("void"))
			if k % 5 == 2:
				put(vx - 2, top + k, col("night"))
				put(vx - 1, top + k, col("deepmoss"))
				put(vx + 1, top + k - 1, col("deepmoss"))
				put(vx + 2, top + k - 1, col("night"))
	# Gnarled roots arching out of the water from the frame trees, and tall reeds in front.
	_root_arch(Vector2(30, 300), Vector2(96, 262), Vector2(150, 356), 7.0, 3.0)
	_root_arch(Vector2(20, 330), Vector2(80, 318), Vector2(118, 362), 6.0, 3.0)
	_root_arch(Vector2(622, 300), Vector2(566, 272), Vector2(516, 356), 6.0, 3.0)
	_root_arch(Vector2(140, 330), Vector2(176, 320), Vector2(206, 362), 3.0, 2.0)
	for reed in [Vector2(96, 362), Vector2(196, 364), Vector2(470, 364), Vector2(600, 362), Vector2(372, 366)]:
		_reeds(reed, 9, 46.0, int(reed.x) + 90)


func _trunk(foot: Vector2, lean: int, half: float, salt: int) -> void:
	# A dark foreground trunk: bark ridges, a moonlit edge on the side facing the moon, roots.
	for y in H:
		var t := float(y) / H
		var cx := foot.x + lean * (1.0 - t) * 0.3 + noise.get_noise_1d(y * 0.8 + salt * 90.0) * 3.0
		var hw := half * (0.85 + 0.15 * t) + (pow(maxf(t - 0.8, 0.0) * 5.0, 2.0) * half * 0.8)
		for x in range(int(cx - hw), int(cx + hw) + 1):
			var u := (x - cx) / hw
			var ridge := grain.get_noise_2d(u * 6.0 + salt * 11.0, y * 0.25)
			var v := 0.05 + (0.06 if ridge > 0.2 else 0.0)
			var toward := signf(MOON.x - cx)
			if u * toward > 0.9:
				v = 0.3
			put(x, y, pick(INK, v, x, y))
			if ridge < -0.5 and absf(u) < 0.8 and noise.get_noise_2d(x * 1.5, y * 1.5) > 0.2:
				put(x, y, col("deepmoss"))  # moss on the bark


func _fern(base: Vector2, length: float) -> void:
	for side in [-1, 1]:
		for f in 4:
			var ang: float = -PI / 2 + side * (0.25 + f * 0.3)
			var dir := Vector2(cos(ang), sin(ang))
			for k in int(length - f * 5):
				var p: Vector2 = base + dir * k + Vector2(side * k * k * 0.014, 0)
				put(int(p.x), int(p.y), col("void"))
				if k % 3 == 0 and k > 2:
					var leaflet := Vector2(-dir.y, dir.x) * 3.0
					for s in 3:
						put(int(p.x + leaflet.x * s / 3.0), int(p.y + leaflet.y * s / 3.0), col("night"))
						put(int(p.x - leaflet.x * s / 3.0), int(p.y - leaflet.y * s / 3.0), col("void"))


func _fireflies() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 5150
	for i in 60:
		var p := Vector2(r.randf_range(60.0, 620.0), r.randf_range(120.0, 340.0))
		if i % 4 == 0:
			glow(p, 4.0, col("gold"), 0.4)
		put(int(p.x), int(p.y), col("glow") if i % 3 else col("heartlight"))
