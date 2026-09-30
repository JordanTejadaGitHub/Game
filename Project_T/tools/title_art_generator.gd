extends SceneTree
# Generates the title screen background (screens_ui.md "Meta screens"). Detailed pixel art at 640×360,
# shown at a whole-number scale (3× at 1080p, 2× at 720p, 4× at 1440p).
# A dream forest at night, seen from the forest floor: an ancient Warden, grown as big as a hill,
# sits among the trees with its head against the moon. It has the Wardens' shape (a big round head
# with narrow warm eyes, a broad round body, heavy arms resting on the ground) but it's
# mossy stone, with trees growing on it and glowing spore-mushrooms at its knees. Mist hides its base;
# dark trees frame the shot (the left side stays calm for the logo and menu). A tiny Shade (a nightmare)
# sits on a narrow trail among the trees, looking up at it: the scale comes from that contrast.
# Every pixel is snapped to Heartwood 32 (art_direction.md).
#   assets/ui/title/title_background.png   640×360, the art
#   tools/previews/title_background_3x.png 1920×1080 preview
# Run:  Godot --headless --path . --script res://tools/title_art_generator.gd

const W := 640
const H := 360
const OUT := "res://assets/ui/title/"
const PREVIEW := "res://tools/previews/title_background_3x.png"
const Palette := preload("res://tools/art/heartwood_palette.gd")

const MOON := Vector2(446, 74)
const MOON_R := 36.0
const TITAN_X := 438.0
const HEAD := Vector2(438, 96)
const FIGURE := Vector2i(282, 334)
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

const SKY := ["void", "night", "dusk", "slate", "stone"]
const INK := ["void", "night", "dusk", "slate", "stone", "mist", "moonlight"]
const MOSS := ["deepmoss", "moss", "leaf", "sprig"]
const DARK_MOSS := ["void", "night", "deepmoss", "moss"]

var img: Image
var noise := FastNoiseLite.new()
var grain := FastNoiseLite.new()
var rng := RandomNumberGenerator.new()
var _colors := {}
var _mask := PackedByteArray()    # titan part id per pixel (0 = none), for rims and occlusion lines
var _shape := []                  # per part: Vector4(centre x, centre y, radius x, radius y) for form shading


func _init() -> void:
	rng.seed = 20260930
	noise.seed = 11
	noise.frequency = 0.045
	noise.fractal_octaves = 3
	grain.seed = 5
	grain.frequency = 0.25
	img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	_mask.resize(W * H)

	_sky()
	_moon()
	_clouds()
	_forest(238, 130, 0.48, 1, 0, 40.0, 100.0)   # far trees, pale in the fog
	_titan()
	_mist(230, 262, 0.62)
	_forest(270, 80, 0.2, 2, 120, 50.0, 120.0)   # nearer trees, close around the titan
	_mist(266, 292, 0.5)
	_forest_floor()
	_mid_trunks()
	_undergrowth()
	_figure()
	_frame_trees()
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
	for y in H:
		for x in W:
			var v := float(y) / 250.0 * 0.6
			v += 0.45 * exp(-Vector2(x, y).distance_to(MOON) / 80.0)
			v += noise.get_noise_2d(x * 0.5, y * 2.2) * 0.04
			img.set_pixel(x, y, pick(SKY, v, x, y, 0.22))
	for i in 240:
		var x := rng.randi_range(0, W - 1)
		var y := rng.randi_range(0, 160)
		if Vector2(x, y).distance_to(MOON) < MOON_R + 40:
			continue
		put(x, y, col("mist") if rng.randf() < 0.3 else col("slate"))
		if rng.randf() < 0.06:
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				put(x + d.x, y + d.y, col("dusk"))


func _moon() -> void:
	var r := int(MOON_R) + 50
	for y in range(int(MOON.y) - r, int(MOON.y) + r + 1):
		for x in range(int(MOON.x) - r, int(MOON.x) + r + 1):
			var d := Vector2(x, y).distance_to(MOON)
			if d > MOON_R:
				var halo := 0.0
				if d < MOON_R + 5:
					halo = 0.5
				elif d < MOON_R + 16:
					halo = 0.25
				elif d < MOON_R + 40:
					halo = 0.1
				blend(x, y, col("mist"), halo)
				continue
			var n := (Vector2(x, y) - MOON) / MOON_R
			var v := 0.72 + 0.28 * n.dot(Vector2(-0.6, -0.6))
			var crater := noise.get_noise_2d(x * 3.0 + 300.0, y * 3.0)
			if crater > 0.2:
				v -= 0.2
			elif crater > 0.1:
				v -= 0.09
			put(x, y, pick(["stone", "mist", "moonlight"], v, x, y, 0.1))


func _clouds() -> void:
	_stratus(0, 300, 118, 4.0, 1)
	_stratus(40, 240, 60, 3.0, 2)
	_stratus(520, 640, 132, 5.0, 3)
	_stratus(300, 520, 150, 3.0, 4)


func _stratus(x0: float, x1: float, mid: float, thick: float, salt: int) -> void:
	for x in range(maxi(int(x0), 0), mini(int(x1), W)):
		var t := (x - x0) / (x1 - x0)
		var taper := pow(sin(t * PI), 0.6)
		var h := thick * taper * (0.7 + 0.6 * (0.5 + 0.5 * noise.get_noise_1d(x * 1.6 + salt * 97.0)))
		var y_mid := mid + noise.get_noise_1d(x * 0.4 + salt * 31.0) * 4.0
		if h < 0.6:
			continue
		for y in range(int(y_mid - h), int(y_mid + h * 0.6) + 1):
			var u := (y - (y_mid - h)) / (h * 1.6)
			var lit := exp(-Vector2(x, y).distance_to(MOON) / 70.0)
			put(x, y, pick(INK, 0.38 - u * 0.22 + lit * 0.5, x, y, 0.2))




# --- forest --------------------------------------------------------------------------------------

func _forest(base: int, count: int, value: float, salt: int, clear: int, hmin: float, hmax: float) -> void:
	# A band of trees: tall pines and round-crowned trees, darker toward their feet, with a moonlit
	# edge on the side facing the moon. `value` sets how pale (far) they are.
	var r := RandomNumberGenerator.new()
	r.seed = salt * 77
	var trees := []
	for i in count:
		var x := r.randf_range(-20.0, W + 20.0)
		if absf(x - TITAN_X) < clear:
			continue  # keep the titan clear
		var h := r.randf_range(hmin, hmax)
		trees.append(Vector4(x, base + r.randf_range(-6.0, 10.0), h, 1.0 if r.randf() < 0.6 else 0.0))
	trees.sort_custom(func(a: Vector4, b: Vector4) -> bool: return a.y < b.y)
	for t: Vector4 in trees:
		_tree(Vector2(t.x, t.y), t.z, t.w > 0.5, value, salt)
	# Fill below the band so the ground behind is solid.
	for x in W:
		for y in range(base + 8, H):
			put(x, y, pick(INK, value - 0.14, x, y))


func _tree(foot: Vector2, height: float, pine: bool, value: float, salt: int) -> void:
	var top := foot.y - height
	var width := height * (0.13 if pine else 0.2)
	for y in range(int(top), int(foot.y) + 1):
		var t := (y - top) / height  # 0 at the top .. 1 at the foot
		var half := 0.0
		if pine:
			# Stacked tiers: each widens then steps back in, with a ragged edge.
			var tier := fposmod(t * 6.0, 1.0)
			half = width * (0.25 + t * 0.85) * (0.6 + tier * 0.5)
			if t > 0.9:
				half = 1.5  # the trunk
		else:
			var crown := 1.0 - pow((t - 0.35) / 0.4, 2.0)
			half = width * sqrt(maxf(crown, 0.0)) if t < 0.78 else 1.8
		half += noise.get_noise_2d(foot.x + y * 1.7, y * 1.3) * 1.6
		if half <= 0.0:
			continue
		for x in range(int(foot.x - half), int(foot.x + half) + 1):
			var side := (x - foot.x) / maxf(half, 1.0)  # -1 left .. 1 right
			var v := value - t * 0.12 + (0.05 if grain.get_noise_2d(x * 2.0, y * 2.0) > 0.3 else 0.0)
			var toward := signf(MOON.x - foot.x)
			if side * toward > 0.93 and t < 0.85 and half > 3.0:
				v += 0.08  # moonlit edge
			put(x, y, pick(INK, v, x, y))


func _mist(y0: int, y1: int, value: float) -> void:
	# A drifting fog band, as dithered palette pixels (a blend would snap to muddy colours).
	for y in range(y0, y1):
		for x in W:
			var m := noise.get_noise_2d(x * 0.35 + y0, y * 2.4)
			var band := maxf(0.0, 1.0 - absf(y - (y0 + y1) * 0.5) / ((y1 - y0) * 0.5))
			var a := (m + 0.3) * band
			if a > 0.42:
				put(x, y, pick(INK, value, x, y))
			elif a > 0.26 and (x + y) % 2 == 0:
				put(x, y, pick(INK, value, x, y))
			elif a > 0.14 and bayer(x, y) < 0.25:
				put(x, y, pick(INK, value, x, y))


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
	var v := 0.3 + 0.12 * q.normalized().dot(to_moon) * minf(q.length(), 1.0) + (s.z - 0.5) * 0.08
	if s.y < 1.0:
		v -= 0.11
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
	var rim := 0
	if _part_at(int(round(x + to_moon.x)), int(round(y + to_moon.y))) == 0:
		rim = 2
	elif _part_at(int(round(x + to_moon.x * 2.5)), int(round(y + to_moon.y * 2.5))) == 0:
		rim = 1
	var fog := clampf((y - 200.0) / 90.0, 0.0, 1.0) * 0.5 + 0.1
	# Moss grows over the tops and down the sides in thick patches.
	var mossy := noise.get_noise_2d(x * 0.9 + 13.0, y * 0.9) - q.y * 0.25
	if id == 8:
		mossy -= 0.2 if absf(q.x) < 0.7 and q.y > -0.45 else -0.2  # keep the face mostly bare
	if mossy > 0.2:
		var mv := 0.22 + (s.z - 0.5) * 0.1 + (0.45 if rim == 2 else (0.22 if rim == 1 else 0.0))
		if grain.get_noise_2d(x * 3.0, y * 3.0) > 0.4:
			mv += 0.14
		var c := pick(MOSS, mv, x, y)
		if bayer(x, y) < fog * 0.7:
			c = pick(INK, lerpf(v, 0.52, fog), x, y)
		return c
	if rim == 2:
		v = 0.72
	elif rim == 1:
		v = maxf(v, 0.55)
	return pick(INK, lerpf(v, 0.52, fog), x, y)


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

func _lane_x(y: float) -> float:
	# The trail's centre: from the Warden's knees down to the Shade and on toward us.
	var near := clampf((y - 284.0) / (H - 284.0), 0.0, 1.0)
	return lerpf(TITAN_X - 30.0, FIGURE.x, near) + sin(y * 0.08) * 6.0


func _forest_floor() -> void:
	# Dark mossy forest floor: leaf litter, a narrow trail, dappled moonlight between the trees.
	for y in range(272, H):
		var near := clampf(float(y - 284) / (H - 284), 0.0, 1.0)
		for x in W:
			if y < 284 + noise.get_noise_1d(x * 1.5 + 70.0) * 12.0:
				continue  # a ragged far edge, meeting the mist
			var lane := exp(-pow((x - _lane_x(y)) / (8.0 + near * 18.0), 2.0))
			var dapple := noise.get_noise_2d(x * 0.9 + 300.0, y * 2.2)
			var v := 0.1 + near * 0.06 + (0.16 if dapple > 0.35 else 0.0) + noise.get_noise_2d(x * 1.4, y * 2.6) * 0.08
			var c := pick(MOSS, v, x, y)
			if hash01(x, y, 17) < 0.05:  # leaf litter
				c = col(["bark", "oak", "loam", "root"][int(hash01(x, y, 18) * 4.0)])
			if lane > 0.6 and noise.get_noise_2d(x * 2.0 + 40.0, y * 3.0) > -0.2:
				c = pick(["root", "loam", "path"], 0.25 + lane * 0.35 + (0.2 if dapple > 0.35 else 0.0), x, y)
			put(x, y, c)
	for i in 500:  # short grass tufts, mostly in the moonlit patches
		var y := rng.randi_range(290, H - 1)
		var x := rng.randi_range(0, W - 1)
		var lit := noise.get_noise_2d(x * 0.9 + 300.0, y * 2.2) > 0.35
		var length := 1 + int(float(y - 290) / (H - 290) * rng.randf_range(1.0, 4.0))
		for k in length:
			put(x, y - k, col("leaf") if lit else col("moss"))
	for i in 30:  # pale night flowers
		var y := rng.randi_range(296, H - 12)
		var x := rng.randi_range(60, W - 60)
		put(x, y, col("dewlight"))
		if rng.randf() < 0.3:
			glow(Vector2(x, y), 3.0, col("dewlight"), 0.2)
	_roots()


func _roots() -> void:
	# Roots snaking across the floor from the trees, crossing the trail.
	var r := RandomNumberGenerator.new()
	r.seed = 61
	for i in 16:
		var p := Vector2(r.randf_range(0.0, W), r.randf_range(292.0, H))
		var dir := Vector2(r.randf_range(-1.0, 1.0), r.randf_range(-0.15, 0.15)).normalized()
		var width := r.randi_range(1, 3)
		for k in r.randi_range(20, 70):
			p += dir
			dir = (dir + Vector2(0, r.randf_range(-0.08, 0.08))).normalized()
			for w in width:
				put(int(p.x), int(p.y) + w, col("root") if w > 0 else col("bark"))
			if k % 9 == 0:
				put(int(p.x), int(p.y) - 1, col("moss"))


func _mid_trunks() -> void:
	# Trees between us and the Warden, standing on the forest floor, rising into the canopy.
	for t in [Vector3(196, 306, 10), Vector3(244, 292, 5), Vector3(292, 298, 7),
			Vector3(586, 300, 9), Vector3(612, 306, 6)]:  # clear of the Warden's arms
		var x0: float = t.x
		var foot: float = t.y
		var half: float = t.z
		var toward := signf(MOON.x - x0)
		for y in range(0, int(foot) + 1):
			var flare := pow(maxf(0.0, (y - (foot - 14.0)) / 14.0), 2.0) * half * 1.4
			var lean := (hash01(int(x0), 5) - 0.5) * 0.12  # each trunk leans a little
			var cx := x0 + (foot - y) * lean + noise.get_noise_1d(y * 0.7 + x0) * 2.0
			var hw := half * (0.7 + 0.3 * y / foot) + flare  # tapering upward
			for x in range(int(cx - hw), int(cx + hw) + 1):
				var u := (x - cx) / hw
				var v := 0.06 + (0.05 if grain.get_noise_2d(u * 5.0 + x0, y * 0.3) > 0.25 else 0.0)
				if u * toward > 0.72:
					v = 0.32 if u * toward > 0.88 else 0.2  # the moonlit side
				var c := pick(INK, v, x, y)
				if u * toward < -0.2 and noise.get_noise_2d(x * 1.3, y * 0.9) > 0.3:
					c = pick(DARK_MOSS, 0.5, x, y)  # moss on the shaded side
				put(x, y, c)


func _undergrowth() -> void:
	# Bushes, ferns and bracken along the edge of the floor and round the tree feet; the trail
	# stays open.
	var r := RandomNumberGenerator.new()
	r.seed = 73
	for i in 70:
		var y := r.randf_range(282.0, 312.0)
		var x := r.randf_range(-10.0, W + 10.0)
		if absf(x - _lane_x(y)) < 22.0:
			continue
		var rr := Vector2(r.randf_range(8.0, 20.0), r.randf_range(5.0, 11.0))
		for yy in range(int(y - rr.y) - 2, int(y) + 2):
			for xx in range(int(x - rr.x) - 2, int(x + rr.x) + 3):
				var q := Vector2((xx - x) / rr.x, (yy - y) / rr.y)
				if q.length() > 1.0 + grain.get_noise_2d(xx * 2.2, yy * 2.2) * 0.35:
					continue
				var lit := q.normalized().dot((MOON - Vector2(xx, yy)).normalized()) > 0.4 and q.length() > 0.75
				var v := 0.28 + (0.5 if lit else 0.0) + (0.14 if grain.get_noise_2d(xx * 3.0, yy * 3.0) > 0.4 else 0.0)
				put(xx, yy, pick(DARK_MOSS, v, xx, yy))
	for fern in [Vector2(172, 318), Vector2(236, 300), Vector2(356, 306), Vector2(470, 312), Vector2(520, 300), Vector2(590, 318)]:
		_fern(fern, 20.0)


func _figure() -> void:
	# A Shade (enemy_design.md: "a small hunched shadow with two pinprick eyes"), tiny in the clearing,
	# turned toward the Warden. Cold only (art_direction.md): dark body, a violet rim on the moon's
	# side, pale eyes in a cold glow, a ragged smoky lower edge trailing on the grass.
	var shape := [
		"......OOOO......",
		"....OOSSSSOB....",
		"...OSSSSSSSSBO..",
		"..OSSSSSSSSSSBO.",
		"..OSSSSSSSSESEO.",
		".OSSSSSSSSSSSSBO",
		".OSSSSSSSSSSSSBO",
		"OSSSSSSSSSSSSSBO",
		"OSSSSSSSSSSSSSBO",
		"OSSSSSSSSSSSSSSO",
		".OSSSSSSSSSSSSO.",
		".OSS.SSSSS.SSSO.",
		"..S...SS.S..SO..",
		"..S....S....S...",
	]
	var key := {"O": "dread", "S": "shade", "B": "bruise", "E": "moonlight"}
	var ox := FIGURE.x - 8
	var oy := FIGURE.y - shape.size()
	# Cold mist curling round it on the grass.
	for y in range(-4, 5):
		for x in range(-22, 23):
			var a := 1.0 - Vector2(x / 22.0, y / 4.5).length() + noise.get_noise_2d(x * 3.0, y * 5.0) * 0.4
			if a > 0.3 and (x + y) % 2 == 0:
				put(FIGURE.x + x, FIGURE.y + y, col("bruise"))
			elif a > 0.05 and bayer(FIGURE.x + x, FIGURE.y + y) < 0.25:
				put(FIGURE.x + x, FIGURE.y + y, col("shade"))
	glow(Vector2(ox + 13, oy + 4), 7.0, col("wraithlight"), 0.3)
	for row in shape.size():
		var line: String = shape[row]
		for i in line.length():
			var ch := line[i]
			if ch == ".":
				continue
			var c := col(key[ch])
			if row >= 12 and bayer(ox + i, oy + row) < 0.5:
				c = col("bruise")  # the smoky, fraying bottom
			put(ox + i, oy + row, c)
	put(ox + 11, oy + 1, col("wraithlight"))  # the violet rim along its hunched back
	put(ox + 12, oy + 2, col("wraithlight"))
	for row in range(5, 10):
		put(ox + 15, oy + row, col("wraithlight") if row % 2 else col("bruise"))
	# Wisps of smoke rising off it.
	for k in 8:
		put(ox + 3 + int(sin(k * 0.8) * 1.5), oy - 1 - k, col("shade") if k < 5 else col("bruise"))
		if k % 3 == 0:
			put(ox + 9 + int(sin(k * 0.6 + 2.0)), oy - 2 - k, col("shade"))


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
	for i in 14:
		var x := r.randi_range(0, W - 1)
		if x > 200 and x < 580:
			continue  # keep the titan's head clear
		var top := 20 + r.randi_range(0, 30)
		var length := r.randi_range(16, 60)
		var phase := r.randf_range(0.0, TAU)
		for k in length:
			var vx := x + int(round(sin(k * 0.09 + phase) * 2.5))
			put(vx, top + k, col("void"))
			if k % 5 == 2:
				put(vx - 2, top + k, col("night"))
				put(vx - 1, top + k, col("deepmoss"))
				put(vx + 1, top + k - 1, col("deepmoss"))
				put(vx + 2, top + k - 1, col("night"))
	for fern in [Vector2(80, 362), Vector2(10, 350), Vector2(560, 364), Vector2(630, 352), Vector2(200, 364)]:
		_fern(fern, 34.0)


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
