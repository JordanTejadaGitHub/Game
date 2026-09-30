extends SceneTree
# Generates the title screen background (screens_ui.md "Meta screens"). Detailed pixel art at 640×360,
# shown at a whole-number scale (3× at 1080p, 2× at 720p, 4× at 1440p).
# The view from a ruined castle gate at night: the dark arch frames the shot (its left pillar is the
# calm backdrop for the logo and menu), a moonlit courtyard leads in, and a stone Warden titan stands
# among the ruins, backlit by the moon, fog around its feet, moss and a small tree growing on it and
# the Heartwood's warm light glowing through a crack in its chest. The Sporeling, tiny, stands at the
# threshold with its lantern, looking up. Scale comes from that contrast, not from detail on the titan.
# Every pixel is snapped to Heartwood 32 (art_direction.md).
#   assets/ui/title/title_background.png   640×360, the art
#   tools/previews/title_background_3x.png 1920×1080 preview
# Run:  Godot --headless --path . --script res://tools/title_art_generator.gd

const W := 640
const H := 360
const OUT := "res://assets/ui/title/"
const PREVIEW := "res://tools/previews/title_background_3x.png"
const Palette := preload("res://tools/art/heartwood_palette.gd")

const MOON := Vector2(506, 84)
const MOON_R := 27.0
const HORIZON := 262            # the far side of the courtyard, where the titan stands
const VANISH := Vector2(410, 262)
const ARCH_C := Vector2(396, 178)  # the gate's opening: straight jambs, an elliptical arch on top
const ARCH_R := Vector2(222, 152)
const REVEAL := 13.0               # the depth of the arch's inner face that we can see
const FIGURE := Vector2i(292, 322)
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

const SKY := ["void", "night", "dusk", "slate", "stone"]
const INK := ["void", "night", "dusk", "slate", "stone", "mist", "moonlight"]
const MOSS := ["deepmoss", "moss", "leaf", "sprig"]
const FIRE := ["ember", "gold", "glow", "heartlight"]

var img: Image
var noise := FastNoiseLite.new()
var grain := FastNoiseLite.new()
var rng := RandomNumberGenerator.new()
var _colors := {}
var _mask := PackedByteArray()    # titan part id per pixel (0 = none), for rims and occlusion lines


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
	_far_ruins()
	_near_ruins()
	_courtyard()
	_titan()
	_birds()
	_ground_fog()
	_figure()
	_gate()
	_ivy()
	_motes()
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


## Blocky value noise: one random value per `cell`-sized square, for stony, stepped edges.
func blocky(x: int, y: int, cell: int, salt: int) -> float:
	return hash01(int(floor(float(x) / cell)), int(floor(float(y) / cell)), salt)


## Voronoi stones: returns (distance to the nearest seed, gap to the second nearest, cell hash).
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


## Signed distance to a polygon's outline (negative inside).
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


func in_opening(x: float, y: float) -> bool:
	# The gate's opening; the top right of the arch has fallen in (the notch shows sky).
	if y >= ARCH_C.y:
		return absf(x - ARCH_C.x) <= ARCH_R.x
	var q := Vector2((x - ARCH_C.x) / ARCH_R.x, (y - ARCH_C.y) / ARCH_R.y)
	return q.length() <= 1.0


func in_breach(x: float, y: float) -> bool:
	var breach := PackedVector2Array([Vector2(492, -2), Vector2(596, -2), Vector2(584, 18), Vector2(566, 26),
		Vector2(560, 44), Vector2(538, 50), Vector2(520, 38), Vector2(508, 30), Vector2(500, 12)])
	return in_poly(Vector2(x, y), breach) and blocky(int(x), int(y), 5, 44) > 0.12


# --- sky -----------------------------------------------------------------------------------------

func _sky() -> void:
	for y in H:
		for x in W:
			var v := float(y) / HORIZON * 0.62
			v += 0.42 * exp(-Vector2(x, y).distance_to(MOON) / 70.0)
			v += noise.get_noise_2d(x * 0.5, y * 2.2) * 0.04
			img.set_pixel(x, y, pick(SKY, v, x, y, 0.22))
	for i in 220:
		var x := rng.randi_range(0, W - 1)
		var y := rng.randi_range(0, 150)
		if Vector2(x, y).distance_to(MOON) < MOON_R + 34:
			continue
		put(x, y, col("mist") if rng.randf() < 0.3 else col("slate"))
		if rng.randf() < 0.06:
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				put(x + d.x, y + d.y, col("dusk"))


func _moon() -> void:
	var r := int(MOON_R) + 40
	for y in range(int(MOON.y) - r, int(MOON.y) + r + 1):
		for x in range(int(MOON.x) - r, int(MOON.x) + r + 1):
			var d := Vector2(x, y).distance_to(MOON)
			if d > MOON_R:
				var halo := 0.0
				if d < MOON_R + 4:
					halo = 0.5
				elif d < MOON_R + 12:
					halo = 0.25
				elif d < MOON_R + 30:
					halo = 0.1
				blend(x, y, col("mist"), halo)
				continue
			var n := (Vector2(x, y) - MOON) / MOON_R
			var v := 0.7 + 0.3 * n.dot(Vector2(-0.6, -0.6))
			var crater := noise.get_noise_2d(x * 3.0 + 300.0, y * 3.0)
			if crater > 0.2:
				v -= 0.22
			elif crater > 0.1:
				v -= 0.1
			put(x, y, pick(["stone", "mist", "moonlight"], v, x, y, 0.1))


func _clouds() -> void:
	# Long, thin clouds, moonlit on top; the one across the moon is lit from behind.
	_stratus(380, 640, 102, 5.0, 1)
	_stratus(180, 420, 60, 3.0, 2)
	_stratus(0, 260, 128, 4.0, 3)
	_stratus(420, 640, 150, 6.0, 4)


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
			var lit := exp(-Vector2(x, y).distance_to(MOON) / 60.0)
			var v := 0.4 - u * 0.25 + lit * 0.5
			put(x, y, pick(INK, v, x, y, 0.2))


# --- ruins and courtyard -------------------------------------------------------------------------

func _skyline(x0: int, x1: int, base: int, salt: int, towers: Array) -> PackedInt32Array:
	# A ruined wall top: crenellations, broken gaps, and towers with pointed or broken tops.
	var tops := PackedInt32Array()
	tops.resize(W)
	tops.fill(H)
	for x in range(x0, x1):
		var y := base + int(noise.get_noise_1d(x * 0.6 + salt * 70.0) * 6.0)
		if (x / 5) % 2 == 0:
			y -= 3  # merlons
		if blocky(x, 0, 18, salt) < 0.22:
			y += 10 + int(blocky(x, 1, 6, salt) * 10.0)  # a collapsed stretch
		tops[x] = y
	for t: Vector4 in towers:  # x centre, half width, top y, 1 = pointed roof
		for x in range(int(t.x - t.y), int(t.x + t.y) + 1):
			if x < 0 or x >= W:
				continue
			var top := int(t.z)
			if t.w > 0.5:
				top += int(absf(x - t.x) * 2.2)
			else:
				top += int(blocky(x, 2, 3, salt) * 8.0)  # broken top
			tops[x] = mini(tops[x], top)
	return tops


func _far_ruins() -> void:
	# The castle's far walls and towers, pale in the fog behind the titan.
	var tops := _skyline(0, W, 212, 1, [Vector4(236, 11, 150, 1), Vector4(292, 7, 176, 0),
		Vector4(560, 13, 138, 0), Vector4(610, 9, 170, 1), Vector4(470, 6, 186, 0)])
	for x in W:
		for y in range(tops[x], HORIZON + 4):
			var v := 0.52 - (y - tops[x]) * 0.002
			if (y - tops[x]) < 1:
				v += 0.12
			var window := (x % 9 < 2) and ((y + 4) % 14 < 5) and y > tops[x] + 8 and blocky(x, y, 9, 3) < 0.25
			if window:
				v -= 0.18
			put(x, y, pick(INK, v, x, y))


func _near_ruins() -> void:
	# The courtyard's side walls, darker and closer, their tops lit by the moon.
	var tops := _skyline(0, W, 226, 2, [Vector4(270, 16, 170, 0), Vector4(588, 18, 160, 0)])
	for x in W:
		for y in range(tops[x], HORIZON + 6):
			var s := stones(x, y, 6.0, 30)
			var v := 0.36 + (s.z - 0.5) * 0.06
			if s.y < 0.9:
				v -= 0.1
			if y - tops[x] < 2:
				v = 0.5
			var arch := absf(x - 270) < 5 and y > tops[x] + 16 and y < tops[x] + 34  # an arrow slit
			if arch:
				v = 0.14
			put(x, y, pick(INK, v, x, y))


func _courtyard() -> void:
	# Flagstones in perspective (their joints run to the titan's feet), grass and rubble.
	for y in range(HORIZON, H):
		var depth := float(y - HORIZON + 6) / (H - HORIZON + 6)  # 0 far .. 1 near
		for x in W:
			var z := 70.0 / (y - HORIZON + 4.0)  # a rough distance: rows get taller toward us
			var along := z * 9.0
			var across := (x - VANISH.x) / (y - HORIZON + 4.0) * 7.0
			var row := int(floor(along))
			var colx := int(floor(across + (row % 2) * 0.5))
			var joint := absf(along - round(along)) < 0.06 / z * 3.0 or absf(across + (row % 2) * 0.5 - round(across + (row % 2) * 0.5)) < 0.05 * (1.0 + depth)
			var v := 0.46 + (hash01(colx, row, 9) - 0.5) * 0.14 - depth * 0.12
			v += 0.12 * exp(-absf(x - VANISH.x) / 120.0) * (1.0 - depth)  # the moonlit lane to the titan
			if joint:
				v -= 0.18
			var c := pick(INK, v, x, y)
			var g := noise.get_noise_2d(x * 1.2, y * 2.4)
			if g > 0.34 or (joint and g > 0.12):  # grass taking the courtyard back
				c = pick(MOSS, 0.22 + (g - 0.1) * 0.8 - depth * 0.1, x, y)
			put(x, y, c)
	# Grass blades and rubble, bigger near the gate.
	for i in 500:
		var y := rng.randi_range(HORIZON + 2, H - 1)
		var x := rng.randi_range(0, W - 1)
		var depth := float(y - HORIZON) / (H - HORIZON)
		var length := 1 + int(depth * rng.randf_range(1.0, 5.0))
		put(x, y + 1, col("deepmoss"))
		for k in length:
			put(x, y - k, col("leaf") if k == length - 1 else col("moss"))
	for i in 24:
		var y := rng.randi_range(HORIZON + 4, H - 20)
		var x := rng.randi_range(60, W - 60)
		var depth := float(y - HORIZON) / (H - HORIZON)
		_rubble(Vector2i(x, y), int(2 + depth * 8.0))


func _rubble(at: Vector2i, size: int) -> void:
	# A fallen block: a lit top, a dark front, a hard shadow on the ground.
	for x in range(-size, size + 1):
		put(at.x + x + 1, at.y + 1, col("night"))
	for y in range(-size, 1):
		for x in range(-size, size + 1):
			var top := y < -size + maxi(1, size / 2)
			var c := col("slate") if top else col("dusk")
			if x == -size or x == size or y == -size or y == 0:
				c = col("night")
			elif top and x > size / 3:
				c = col("stone")  # the moon's side
			put(at.x + x, at.y + y, c)


# --- the titan -----------------------------------------------------------------------------------

func _titan_parts() -> Array:
	# Hand-placed outlines, back to front. Low view: heavy legs, a torso that narrows up to a small
	# head sunk between boulder shoulders, long arms (the right one reaching a little toward the gate).
	return [
		PackedVector2Array([Vector2(360, 92), Vector2(390, 84), Vector2(440, 84), Vector2(468, 92),
			Vector2(474, 120), Vector2(460, 160), Vector2(438, 178), Vector2(388, 178), Vector2(366, 158), Vector2(352, 120)]),
		PackedVector2Array([Vector2(384, 170), Vector2(444, 170), Vector2(452, 194), Vector2(432, 206),
			Vector2(396, 206), Vector2(378, 194)]),
		PackedVector2Array([Vector2(380, 194), Vector2(412, 196), Vector2(408, 236), Vector2(382, 238)]),
		PackedVector2Array([Vector2(378, 232), Vector2(408, 232), Vector2(410, 266), Vector2(374, 268)]),
		PackedVector2Array([Vector2(366, 262), Vector2(410, 262), Vector2(416, 276), Vector2(362, 278)]),
		PackedVector2Array([Vector2(418, 196), Vector2(450, 190), Vector2(456, 232), Vector2(428, 236)]),
		PackedVector2Array([Vector2(428, 230), Vector2(456, 228), Vector2(460, 266), Vector2(430, 268)]),
		PackedVector2Array([Vector2(424, 262), Vector2(462, 260), Vector2(470, 276), Vector2(420, 278)]),
		PackedVector2Array([Vector2(396, 52), Vector2(408, 44), Vector2(424, 46), Vector2(432, 58),
			Vector2(430, 80), Vector2(414, 90), Vector2(400, 86), Vector2(394, 68)]),
		PackedVector2Array([Vector2(332, 102), Vector2(344, 86), Vector2(372, 84), Vector2(382, 102),
			Vector2(372, 118), Vector2(340, 118)]),
		PackedVector2Array([Vector2(452, 98), Vector2(466, 82), Vector2(490, 82), Vector2(500, 98),
			Vector2(492, 116), Vector2(460, 118)]),
		PackedVector2Array([Vector2(336, 110), Vector2(364, 114), Vector2(356, 162), Vector2(332, 158)]),
		PackedVector2Array([Vector2(330, 154), Vector2(356, 158), Vector2(350, 212), Vector2(324, 208)]),
		PackedVector2Array([Vector2(320, 204), Vector2(352, 208), Vector2(356, 222), Vector2(348, 236),
			Vector2(340, 232), Vector2(334, 238), Vector2(326, 232), Vector2(316, 222)]),
		PackedVector2Array([Vector2(474, 108), Vector2(498, 110), Vector2(510, 154), Vector2(486, 158)]),
		PackedVector2Array([Vector2(486, 152), Vector2(510, 150), Vector2(526, 196), Vector2(502, 202)]),
		PackedVector2Array([Vector2(498, 196), Vector2(528, 192), Vector2(536, 206), Vector2(532, 222),
			Vector2(524, 218), Vector2(518, 226), Vector2(508, 220), Vector2(500, 212)]),
	]


func _titan() -> void:
	var parts := _titan_parts()
	# 1. The silhouette: each outline roughened into stepped stone edges.
	for i in parts.size():
		var poly: PackedVector2Array = parts[i]
		var box := Rect2(poly[0], Vector2.ZERO)
		for p in poly:
			box = box.expand(p)
		for y in range(int(box.position.y) - 4, int(box.end.y) + 5):
			for x in range(int(box.position.x) - 4, int(box.end.x) + 5):
				if not inside(x, y):
					continue
				var sd := poly_sd(Vector2(x, y), poly)
				var rough := blocky(x, y, 3, 60 + i) * 3.2 - 1.6 + (blocky(x, y, 7, 80 + i) - 0.5) * 2.4
				if sd < rough:
					_mask[y * W + x] = i + 1
	# 2. Shading: backlit dark stone with moonlit rims, stones and cracks, moss on the tops,
	# thickening fog toward the feet.
	for y in H:
		for x in W:
			var id := _mask[y * W + x]
			if id == 0:
				continue
			var s := stones(x, y, 7.0, 7 + id)
			var v := 0.24 + (s.z - 0.5) * 0.1
			if s.y < 1.0:
				v -= 0.12  # the crack between two stones
			elif s.x < 2.0 and s.z > 0.5:
				v += 0.05
			# Sky light on surfaces that face up.
			if _part_at(x, y - 2) == 0:
				v += 0.12
			# An occlusion line where a part in front meets one behind it.
			var behind := false
			for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var other := _part_at(x + d.x, y + d.y)
				if other != 0 and other < id:
					behind = true
			if behind:
				v = 0.06
			# The rim: open sky one or two pixels toward the moon.
			var dir := (MOON - Vector2(x, y)).normalized()
			var rim := 0
			if _part_at(int(round(x + dir.x)), int(round(y + dir.y))) == 0:
				rim = 2
			elif _part_at(int(round(x + dir.x * 2.5)), int(round(y + dir.y * 2.5))) == 0:
				rim = 1
			var fog := clampf((y - 170.0) / 110.0, 0.0, 1.0) * 0.55 + 0.08
			var c: Color
			var mossy := noise.get_noise_2d(x * 1.1 + 13.0, y * 1.1) + (0.25 if _part_at(x, y - 5) == 0 else 0.0)
			if mossy > 0.32 and not behind:
				var mv := 0.2 + (s.z - 0.5) * 0.12 + (0.5 if rim == 2 else (0.25 if rim == 1 else 0.0))
				c = pick(MOSS, mv, x, y)
				if bayer(x, y) < fog * 0.8:
					c = pick(INK, lerpf(v, 0.5, fog), x, y)
			else:
				if rim == 2:
					v = 0.7
				elif rim == 1:
					v = maxf(v, 0.62)
				c = pick(INK, lerpf(v, 0.5, fog), x, y)
			put(x, y, c)
	_hanging_moss()
	_head_tree(Vector2(402, 48))
	_heart_crack()
	_eyes()


func _part_at(x: int, y: int) -> int:
	if not inside(x, y):
		return 0
	return _mask[y * W + x]


func _hanging_moss() -> void:
	# Moss hanging from the undersides of the shoulders and arms.
	var r := RandomNumberGenerator.new()
	r.seed = 88
	for i in 900:
		var x := r.randi_range(326, 534)
		var y := r.randi_range(90, 230)
		if _part_at(x, y) == 0 or _part_at(x, y + 1) != 0:
			continue  # only from an underside edge
		var length := r.randi_range(3, 12)
		for k in length:
			if _part_at(x, y + 1 + k) != 0:
				break
			put(x, y + 1 + k, col("deepmoss") if k < length - 2 else col("moss"))
			if k % 4 == 2:
				put(x + 1, y + 1 + k, col("deepmoss"))


func _head_tree(base: Vector2) -> void:
	# A small gnarled tree growing out of the titan's head, backlit like the rest of it.
	var trunk := PackedVector2Array([base, base + Vector2(-3, -8), base + Vector2(-2, -16), base + Vector2(-6, -24)])
	for i in range(1, trunk.size()):
		for s in 6:
			var p := trunk[i - 1].lerp(trunk[i], s / 6.0)
			var w := 2 if i < 3 else 1
			for dx in range(-w, w + 1):
				put(int(p.x) + dx, int(p.y), col("night") if dx < w else col("slate"))
	put(int(base.x) + 4, int(base.y) - 12, col("night"))
	put(int(base.x) + 5, int(base.y) - 13, col("night"))
	put(int(base.x) + 6, int(base.y) - 15, col("night"))
	var clumps := [Vector3(-8, -30, 9), Vector3(2, -32, 8), Vector3(-16, -24, 6), Vector3(9, -24, 6), Vector3(-4, -38, 6)]
	for cl: Vector3 in clumps:
		var c := base + Vector2(cl.x, cl.y)
		var rr := cl.z
		for y in range(int(c.y - rr) - 2, int(c.y + rr) + 3):
			for x in range(int(c.x - rr) - 2, int(c.x + rr) + 3):
				var off := Vector2(x, y) - c
				if off.length() > rr + grain.get_noise_2d(x * 2.0, y * 2.0) * 2.4:
					continue
				var dir := (MOON - Vector2(x, y)).normalized()
				var edge := off.length() > rr - 1.6 and off.normalized().dot(dir) > 0.3
				var v := 0.18 + (0.5 if edge else 0.0) + (0.12 if grain.get_noise_2d(x * 3.0, y * 3.0) > 0.35 else 0.0)
				put(x, y, pick(MOSS, v, x, y))


func _heart_crack() -> void:
	# The Heartwood's warm light glowing through a crack in the titan's chest: it's one of ours.
	var pts := PackedVector2Array([Vector2(416, 104), Vector2(412, 116), Vector2(418, 126), Vector2(413, 138),
		Vector2(419, 150), Vector2(415, 160)])
	glow(Vector2(415, 132), 14.0, col("gold"), 0.16)
	for i in range(1, pts.size()):
		for s in 8:
			var p := pts[i - 1].lerp(pts[i], s / 8.0)
			var core := i > 1 and i < pts.size() - 1
			put(int(p.x), int(p.y), col("heartlight") if core else col("glow"))
			put(int(p.x) - 1, int(p.y), col("gold"))
			put(int(p.x) + 1, int(p.y), col("ember") if core else col("gold"))
			if core and s % 3 == 0:
				put(int(p.x) + 2, int(p.y), col("ember"))
	# Small side cracks catching the light.
	for b in [[Vector2(413, 138), Vector2(404, 132)], [Vector2(418, 126), Vector2(428, 120)], [Vector2(419, 150), Vector2(430, 156)]]:
		var a: Vector2 = b[0]
		var e: Vector2 = b[1]
		for s in 10:
			var p := a.lerp(e, s / 10.0)
			put(int(p.x), int(p.y), col("gold") if s < 6 else col("ember"))


func _eyes() -> void:
	# Two warm eyes deep under the brow.
	for e in [Vector2(406, 68), Vector2(420, 67)]:
		glow(e, 6.0, col("gold"), 0.35)
		put(int(e.x), int(e.y), col("heartlight"))
		put(int(e.x) + 1, int(e.y), col("glow"))
		put(int(e.x) - 1, int(e.y), col("gold"))
	for x in range(400, 428):  # the brow's shadow
		if _part_at(x, 63) != 0:
			put(x, 63, col("void"))


func _birds() -> void:
	# A few birds wheeling around its head, for scale.
	for b in [Vector2i(350, 44), Vector2i(372, 30), Vector2i(470, 40), Vector2i(452, 24), Vector2i(492, 56), Vector2i(330, 64)]:
		put(b.x, b.y, col("night"))
		put(b.x - 1, b.y - 1, col("night"))
		put(b.x + 1, b.y - 1, col("night"))
		put(b.x - 2, b.y - 1, col("night"))
		put(b.x + 2, b.y - 2, col("night"))


func _ground_fog() -> void:
	# Fog pooling around the titan's feet and across the far courtyard, as dithered palette pixels.
	for y in range(236, 300):
		for x in W:
			var m := noise.get_noise_2d(x * 0.35 + 200.0, y * 2.2)
			var band := maxf(0.0, 1.0 - absf(y - 268.0) / 26.0)
			var near_titan := exp(-absf(x - 420.0) / 120.0)
			var a := (m + 0.25) * band * (0.5 + near_titan)
			if a > 0.36:
				put(x, y, pick(INK, 0.6, x, y))
			elif a > 0.22 and (x + y) % 2 == 0:
				put(x, y, col("slate"))
			elif a > 0.12 and bayer(x, y) < 0.25:
				put(x, y, col("slate"))


# --- the Sporeling, the gate ---------------------------------------------------------------------

func _figure() -> void:
	# The Sporeling at the threshold, tiny, looking up: a dark shape with a moonlit rim, its long
	# shadow falling toward us, and its lantern held out.
	# Its head tilted back to look up at the titan; the rim is on the moon's side (upper right).
	var shape := [
		".....OOOOOr......",
		"...OOOOOOOOrr....",
		"..OOOOOOOOOOOr...",
		".OOOOOOOOOOOOOr..",
		".OOOOOOOOOOOOOr..",
		".OOOOOOOOOOOOOr..",
		"..OOOOOOOOOOOr...",
		"...OOOOOOOOOr....",
		".....OOOOOO......",
		"...OOOOOOOOOr....",
		"..OOOOOOOOOOOr...",
		".OOOOOOOOOOOOOr..",
		"OOOOOOOOOOOOOOOr.",
		"OOOOOOOOOOOOOOOr.",
		"OOOOOOOOOOOOOOOr.",
		"OOOOOOOOOOOOOOOr.",
		".OOOOOOOOOOOOOr..",
		"..OOOOOOOOOOOr...",
		"...OOO....OOO....",
		"...OOO....OOO....",
	]
	var ox := FIGURE.x - 8
	var oy := FIGURE.y - shape.size()
	for k in 38:  # the shadow, stretching toward the viewer
		var w := 7.0 - k * 0.1
		for dx in range(int(-w), int(w) + 1):
			put(FIGURE.x - k / 2 + dx, FIGURE.y + k, col("night"))
	for row in shape.size():
		var line: String = shape[row]
		for i in line.length():
			if line[i] != ".":
				put(ox + i, oy + row, col("void") if line[i] == "O" else col("mist"))
	# The lantern on a short stick, held out to the left.
	for k in 8:
		put(ox - k, oy + 12 - k / 3, col("void"))
	var lamp := Vector2(ox - 9, oy + 12)
	glow(lamp, 12.0, col("gold"), 0.3)
	for y in range(-1, 3):
		for x in range(-1, 2):
			put(int(lamp.x) + x, int(lamp.y) + y, col("glow") if x == 0 else col("gold"))
	put(int(lamp.x), int(lamp.y), col("heartlight"))
	put(int(lamp.x), int(lamp.y) - 2, col("night"))


func _gate() -> void:
	# The ruined gate we look through: dark stone in coursed blocks, the arch's inner face (voussoirs)
	# catching moonlight, cracks, a fallen notch at the top right.
	for y in H:
		for x in W:
			if in_opening(x, y) or in_breach(x, y):
				continue
			var reveal := _reveal_depth(x, y)
			var course := int(floor(y / 11.0))
			var bx := int(floor((x + (course % 2) * 13) / 26.0))
			var in_block_x := fposmod(x + (course % 2) * 13, 26.0)
			var in_block_y := fposmod(y, 11.0)
			var v := 0.02 if hash01(bx, course, 3) > 0.72 else 0.12  # flat blocks: Night, some Void
			if in_block_x < 1.0 or in_block_y < 1.0:
				v = 0.0  # mortar joints
			elif in_block_y < 2.0:
				v += 0.04
			if grain.get_noise_2d(x * 0.9, y * 0.9) > 0.7:
				v -= 0.05  # weathering
			if reveal >= 0.0 and reveal < REVEAL:
				# The inner face: radial arch stones up top, courses on the jambs; lit from inside.
				var lit := 1.0 - reveal / REVEAL
				v = 0.2 + lit * 0.24 + (hash01(int(_voussoir(x, y)), course, 5) - 0.5) * 0.08
				if fposmod(_voussoir(x, y), 1.0) < 0.12 or (in_block_y < 1.0 and y > ARCH_C.y):
					v -= 0.14
				if reveal < 1.5:
					v = 0.55  # the moonlit edge
			var c := pick(INK, v, x, y, 0.1)
			# Moss on the ledges and the lower courses.
			var m := noise.get_noise_2d(x * 1.4 + 70.0, y * 1.4)
			if (y > 300 and m > 0.4) or (reveal >= 0.0 and reveal < 3.0 and m > 0.3):
				c = pick(MOSS, 0.05 + (m - 0.2) * 0.3 + (0.3 if reveal >= 0.0 and reveal < 3.0 else 0.0), x, y)
			put(x, y, c)
	# Big cracks running through the wall.
	for crack in [[Vector2(120, 40), 90.0, 1], [Vector2(40, 170), 120.0, 2], [Vector2(612, 60), 70.0, 3], [Vector2(150, 230), 80.0, 4]]:
		_crack(crack[0], crack[1], crack[2])
	_portcullis()


func _reveal_depth(x: int, y: int) -> float:
	# How far outside the opening this wall pixel is, measured toward the opening's centre.
	var dir := Vector2(ARCH_C.x - x, 0.0 if y >= ARCH_C.y else ARCH_C.y - y).normalized()
	for d in int(REVEAL) + 1:
		var p := Vector2(x, y) + dir * d
		if in_opening(p.x, p.y):
			return float(d)
	return -1.0


func _voussoir(x: int, y: int) -> float:
	# The arch stones' index around the arch (their joints point at the arch's centre).
	if y >= ARCH_C.y:
		return y / 11.0
	var a := atan2((y - ARCH_C.y) / ARCH_R.y, (x - ARCH_C.x) / ARCH_R.x)
	return a / (PI / 22.0)


func _crack(start: Vector2, length: float, salt: int) -> void:
	var p := start
	var r := RandomNumberGenerator.new()
	r.seed = salt * 13
	var dir := Vector2(r.randf_range(-0.4, 0.4), 1.0).normalized()
	for i in int(length):
		if in_opening(p.x, p.y):
			return
		put(int(p.x), int(p.y), col("void"))
		put(int(p.x) + 1, int(p.y), col("dusk") if i % 3 == 0 else col("night"))
		dir = (dir + Vector2(r.randf_range(-0.5, 0.5), 0)).normalized()
		p += dir
		if r.randf() < 0.04:  # a branch
			var q := p
			for k in r.randi_range(4, 12):
				q += Vector2(signf(dir.x + 0.01) * 0.8, 0.6)
				put(int(q.x), int(q.y), col("void"))


func _portcullis() -> void:
	# The broken portcullis still hanging in the top of the arch: a few iron bars with points.
	for bar in [[300, 34], [318, 46], [336, 20], [354, 38], [372, 28]]:
		var x: int = bar[0]
		var length: int = bar[1]
		var top := 0
		while top < H and not in_opening(x, top):
			top += 1
		for y in range(top, top + length):
			put(x, y, col("void"))
			put(x + 1, y, col("night"))
			put(x + 2, y, col("dusk") if y % 7 == 0 else col("void"))
		put(x + 1, top + length, col("void"))
		put(x + 1, top + length + 1, col("night"))
	for y in [24, 38]:  # cross bars
		for x in range(298, 376):
			if in_opening(x, y) and (x < 332 or y == 24):
				put(x, y, col("void"))
				put(x, y + 1, col("night"))


func _ivy() -> void:
	# Ivy and vines hanging over the arch, dark against the moonlit courtyard.
	var r := RandomNumberGenerator.new()
	r.seed = 321
	for i in 16:
		var x := r.randi_range(150, 639)
		var y := 0
		while y < H and not in_opening(x, y):
			y += 1
		if y >= 200 or (x > 280 and x < 380 and y < 60):
			continue
		var length := r.randi_range(8, 60)
		var phase := r.randf_range(0.0, TAU)
		for k in length:
			var vx := x + int(round(sin(k * 0.12 + phase) * 2.0))
			put(vx, y + k, col("void"))
			put(vx + 1, y + k, col("night"))
			if k % 4 == 1:  # a leaf pair: dark, with a moonlit edge on the inner side
				for leaf in [Vector2i(-2, 0), Vector2i(-3, 1), Vector2i(-2, 1), Vector2i(2, -1), Vector2i(3, 0), Vector2i(2, 0)]:
					put(vx + leaf.x, y + k + leaf.y, col("deepmoss"))
				put(vx + 3, y + k - 1, col("moss"))
	# Clumps of ivy spilling over the arch's edge.
	for i in 40:
		var x := r.randi_range(160, 630)
		var y := 0
		while y < H and not in_opening(x, y):
			y += 1
		y -= r.randi_range(0, 4)
		for dy in range(-3, 3):
			for dx in range(-4, 5):
				if dx * dx + dy * dy * 2 > 14 or grain.get_noise_2d((x + dx) * 3.0, (y + dy) * 3.0) < -0.2:
					continue
				put(x + dx, y + dy, col("deepmoss") if dy > -2 else col("moss"))


func _motes() -> void:
	# Warm motes rising from the titan's heart, a few pale ones in the moonlight.
	var r := RandomNumberGenerator.new()
	r.seed = 5150
	for i in 40:
		var p := Vector2(415 + r.randf_range(-70.0, 70.0), r.randf_range(50.0, 170.0))
		if not in_opening(p.x, p.y) or _part_at(int(p.x), int(p.y)) != 0:
			continue
		if i % 4 == 0:
			glow(p, 3.0, col("gold"), 0.35)
		put(int(p.x), int(p.y), col("glow") if i % 3 else col("heartlight"))
	for i in 20:
		var p := Vector2(r.randf_range(200.0, 620.0), r.randf_range(180.0, 330.0))
		if in_opening(p.x, p.y) and _part_at(int(p.x), int(p.y)) == 0:
			put(int(p.x), int(p.y), col("mist"))
