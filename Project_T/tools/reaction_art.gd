extends RefCounted
# The eight base Reactions (user-approved redraw 2026-10-21: "make reactions jump out", "make sure the animations hit",
# "the whirlpool ... should be underneath"). Drawn in the house effect style (boss_burst, crowned_avalanche, bolt_strike):
# thin bright strokes and organic tendrils, cores stepped in bands, a 1-2 px banded glow, ringed shockwaves, motes at the
# end; bright strokes get a 1 px Night shadow so they hold on the pale path; light from the upper left.
#
# Each Reaction is two sheets, both 96x112, anchor (48, 80) = the nightmare's route point (its feet), where Fx.reaction
# plays it: <name> over the nightmare (the hit lands on its body, C, 11 px up) and <name>_ground under it (shockwaves,
# pools, scorch, cracks, frost, landed shards, whatever is behind it). 12 frames at 16 fps (~0.75 s); Smother is an
# 8-frame loop (it plays while the Hold lasts). effect_art_generator.gd writes them through draw(); _sheet snaps them to
# the Heartwood 32 and steps the alpha.

const NIGHT := Color("24243c")
const VOID := Color("05050d")
const ROOT := Color("241c14")
const BARK := Color("5c3c24")
const EMBER := Color("b8662c")
const GOLD := Color("e9a83c")
const GLOW := Color("fcd47c")
const HEART := Color("fff4dc")
const MOON := Color("dce8f4")
const MIST := Color("b4b0c8")
const STONE := Color("8c8cac")
const POOL := Color("2c4c5c")
const DEW := Color("4c8ca4")
const DEWLIGHT := Color("9cd4fc")
const PATH := Color("b4a494")
const MOONPATH := Color("dccdb2")
const BLOSSOM := Color("ec9cf4")
const ORCHID := Color("bc44dc")
const SPRIG := Color("9cc46c")
const NEWLEAF := Color("d4ec9c")
const LEAF_C := Color("5c944c")
const MOSS_C := Color("34643c")
const DEEPMOSS := Color("1c3c2c")
# --- Drawing, v2: the house style (boss_burst, crowned_avalanche, bolt_strike): thin bright strokes and organic
# tendrils, cores stepped in bands, dithered halos, ringed shockwaves, motes at the end. Bright strokes get a 1 px Night
# shadow below-right so they hold on the pale path. Light from the upper left. (frame 96x96, the nightmare's centre C.)
const C := Vector2(48, 69)  # the body: 11 px above the feet (the anchor, F), a Shade-sized nightmare's middle
const F := Vector2(48, 80)  # the feet = the anchor = where Fx.reaction plays it (the nightmare's route point)
const FH := 112  # frame height
const SLATE := Color("5c5a78")
const DUSK := Color("3c3c5c")

func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, img.get_pixel(x, y).blend(c))

func _hard_alpha(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0 and c.a < 1.0:
				c.a = 0.0 if c.a < 0.15 else (0.4 if c.a < 0.55 else (0.75 if c.a < 0.88 else 1.0))
				img.set_pixel(x, y, c)

# A stroke along `pts` (a polyline): its colour from `ramp` by position (start -> end), `width` px at the start tapering
# to 1, a Night shadow 1 px below-right under it.
func _stroke(img: Image, pts: Array, ramp: Array, width: float, alpha: float = 1.0, shadow: bool = true) -> void:
	var dots := {}
	var total := 0.0
	for i in range(1, pts.size()):
		total += (pts[i] as Vector2).distance_to(pts[i - 1])
	var run := 0.0
	for i in range(1, pts.size()):
		var a: Vector2 = pts[i - 1]
		var b: Vector2 = pts[i]
		var seg := a.distance_to(b)
		var n := maxi(1, int(seg * 2.0))
		for s in n + 1:
			var p := a.lerp(b, s / float(n))
			var u := (run + seg * s / float(n)) / maxf(total, 0.01)
			var w := lerpf(width, 1.0, u)
			var col: Color = ramp[mini(int(u * ramp.size()), ramp.size() - 1)]
			for oy in range(-int(w / 2.0), int(ceil(w / 2.0))):
				for ox in range(-int(w / 2.0), int(ceil(w / 2.0))):
					dots[Vector2i(int(p.x) + ox, int(p.y) + oy)] = col
		run += seg
	for d: Vector2i in (dots if shadow else {}):
		if not dots.has(d + Vector2i(1, 1)):
			_px(img, d.x + 1, d.y + 1, Color(NIGHT, alpha * 0.75))
	for d: Vector2i in dots:
		_px(img, d.x, d.y, Color(dots[d], alpha))

# An organic tendril: a jagged walk from `from` at angle `a`, `length` px, wandering by `wiggle`, with a branch or two.
func _tendril(img: Image, rng: RandomNumberGenerator, from: Vector2, a: float, length: float, ramp: Array, width: float, wiggle: float = 0.5, branches: int = 1, squash: float = 1.0, shadow: bool = true) -> void:
	var pts := [from]
	var p := from
	var steps := maxi(2, int(length / 3.0))
	for i in steps:
		a += rng.randf_range(-wiggle, wiggle)
		p += Vector2(cos(a), sin(a) * squash) * 3.0
		pts.append(p)
		if branches > 0 and i == steps / 2 and length > 9.0:
			_tendril(img, rng, p, a + rng.randf_range(0.6, 1.0) * (1.0 if rng.randf() < 0.5 else -1.0), length * 0.4, ramp, maxf(1.0, width - 1.0), wiggle, 0, squash, shadow)
	_stroke(img, pts, ramp, width, 1.0, shadow)

# A core stepped in bands (ramp outer -> inner), each band a ring of radius r * share.
func _core(img: Image, c: Vector2, r: float, ramp: Array) -> void:
	for i in ramp.size():
		var rr := r * (1.0 - float(i) / ramp.size())
		for y in range(int(c.y - rr) - 1, int(c.y + rr) + 2):
			for x in range(int(c.x - rr) - 1, int(c.x + rr) + 2):
				if Vector2(x + 0.5, y + 0.5).distance_to(c) <= rr:
					img.set_pixel(clampi(x, 0, 95), clampi(y, 0, FH - 1), ramp[i])

# A dithered halo: two checker steps out to r (only where nothing is drawn yet).
func _halo(img: Image, c: Vector2, r: float, col: Color, strength: float = 1.0, squash: float = 1.0) -> void:
	for y in range(int(c.y - r * squash) - 1, int(c.y + r * squash) + 2):
		for x in range(int(c.x - r) - 1, int(c.x + r) + 2):
			if x < 0 or y < 0 or x > 95 or y > FH - 1 or img.get_pixel(x, y).a > 0.5:
				continue
			var d := Vector2(x + 0.5 - c.x, (y + 0.5 - c.y) / squash).length() / r
			if d <= 0.6 and (x + y) % 2 == 0:
				_px(img, x, y, Color(col, 0.75 * strength))
			elif d <= 1.0 and (x + y) % 2 == 0 and (x / 2 + y / 2) % 2 == 0:
				_px(img, x, y, Color(col, 0.4 * strength))

# A ground shockwave: an ellipse band 2 px (bright outer line, a darker inner line), a Night line just outside, and a
# dithered wake inside; `alpha` fades it.
func _wave(img: Image, c: Vector2, r: float, col: Color, inner: Color, alpha: float, on_ground: bool = true) -> void:
	var dst := gimg if on_ground else img  # a shockwave on the ground goes under the nightmare
	for y in range(int(c.y - r * 0.45) - 3, int(c.y + r * 0.45) + 4):
		for x in range(int(c.x - r) - 3, int(c.x + r) + 4):
			var d := Vector2(x + 0.5 - c.x, (y + 0.5 - c.y) / 0.45).length()
			if d > r and d <= r + 1.0:
				_px(dst, x, y, Color(NIGHT, alpha * 0.75))
			elif d <= r and d > r - 1.0:
				_px(dst, x, y, Color(col, alpha))
			elif d <= r - 1.0 and d > r - 2.0:
				_px(dst, x, y, Color(inner, alpha))
			elif d <= r - 2.0 and d > r - 6.0 and (x + y) % 2 == 0 and (x / 2 + y) % 3 == 0:
				_px(dst, x, y, Color(inner, alpha * 0.6))

# Motes: a few single pixels drifting up and fading (the dissolve every house effect ends on).
func _motes(img: Image, rng: RandomNumberGenerator, c: Vector2, n: int, spread: float, rise: float, cols: Array, alpha: float) -> void:
	for k in n:
		var p := c + Vector2(rng.randf_range(-spread, spread), rng.randf_range(-spread * 0.4, spread * 0.3) - rise * rng.randf_range(0.6, 1.0))
		_px(img, int(p.x), int(p.y), Color(cols[k % cols.size()], alpha))

# --- Ignite: embers rush in, it catches (a stepped gold core in a halo, a burst of flame tendrils), flame wisps lick up
# round it, burning spores arc off to its neighbours trailing smoke, a smouldering scorch is left.
func _ignite(img: Image, f: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 40 + f
	var ground := F
	var flame := [GLOW, GOLD, EMBER]  # bright root -> darker tip
	var lick := [EMBER, GOLD, GLOW, HEART]  # a wisp: dark base -> bright tip
	if f >= 4:  # the scorch: an uneven smouldering patch (stays; thins at the end)
		for y in range(-6, 7):
			for x in range(-20, 21):
				var d := Vector2(x / 20.0, y / 6.0).length() + sin(x * 0.7) * 0.08 + cos(y * 1.3 + x) * 0.06
				if d > 1.0 or (f >= 10 and (x + y) % 2 == 0):
					continue
				var col := BARK if d > 0.8 else (ROOT if (x + y) % 2 == 0 else BARK)
				if d <= 0.65 and (x * 5 + y * 7 + f * 3) % 11 == 0:
					col = EMBER if f < 9 else BARK
				_px(gimg, int(ground.x) + x, int(ground.y) + y, Color(col, 0.75 if (x + y) % 2 == 0 or d < 0.8 else 0.4))
	if f <= 1:  # embers streaking in
		var u: float = [0.0, 0.55][f]
		for k in 8:
			var a := k * TAU / 8.0 + 0.3
			var far := Vector2(cos(a), sin(a) * 0.75) * 38.0
			var p := C + far * (1.0 - u)
			_stroke(img, [p + far.normalized() * 7.0, p], [EMBER, GOLD, GLOW], 1.0)
			_px(img, int(p.x), int(p.y), HEART)
	if f >= 2 and f <= 4:  # the catch
		var r: float = [6.0, 9.0, 6.0][f - 2]
		for k in 7:
			_tendril(img, rng, C, k * TAU / 7.0 + rng.randf(), r * 2.0 + 6.0, [HEART, GLOW, GOLD, EMBER], 2.0 if f == 3 else 1.0, 0.45, 0, 1.0, false)  # rays of fire: light, no shadow
		_core(img, C, r, [GOLD, GLOW, HEART])
		_band_glow(img, 0.75 if f < 4 else 0.4)
	if f >= 3 and f <= 8:  # the shockwave
		_wave(img, ground, 12.0 + (f - 3) * 7.0, GLOW, GOLD, 1.0 if f < 6 else 0.6)
	if f >= 3 and f <= 9:  # the fire: one flame body with flickering tips (tongues summed), a white-gold heart low in it,
		# gold body, Ember edges (fire glows: no Night outline), then a 1 px banded glow round it
		var h: float = [0, 0, 0, 18, 24, 26, 23, 18, 12, 7][f]
		_fire(img, ground + Vector2(0, -1), h, 18.0 * (1.0 if f < 8 else 0.8), f)
	if f >= 5 and f <= 11:  # burning spores arcing to the neighbours, smoke behind them
		var u := (f - 5) / 6.0
		for s: int in [-1, 1]:
			for k in 2:
				var end := C + Vector2(s * (32.0 + k * 7.0), 4.0 - k * 9.0)
				var arc := 12.0 + k * 4.0
				for tr in 4:  # the smoke trail: dithered slate puffs
					var v := maxf(u - 0.07 * (tr + 1), 0.0)
					var q := C.lerp(end, v) + Vector2(0, -sin(v * PI) * arc - tr)
					if (tr + f) % 2 == 0:
						_px(img, int(q.x), int(q.y), Color(SLATE, 0.75 - tr * 0.15))
				var p := C.lerp(end, u) + Vector2(0, -sin(u * PI) * arc)
				if u < 0.95:
					_halo(img, p, 4.0, GLOW, 0.6)
					_core(img, p, 2.5, [EMBER, GOLD, GLOW])
				else:
					_core(img, p, 2.0, [EMBER, GOLD])
	if f >= 9:  # smoke curling up off the scorch, and the last motes
		_motes(img, rng, ground + Vector2(0, -4), 6, 14.0, 6.0 + (f - 9) * 5.0, [SLATE, DUSK, EMBER], 0.75)

# --- Pinned: arcs of light circle in and close on it, a shaft of light drives down through it into the ground (a
# four-armed glint where it lands, cracks running out, a shockwave), it narrows to a pin that glints, a mark stays.
func _pinned(img: Image, f: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 70
	var ground := F
	var light := [HEART, MOON, MIST]
	if f >= 3:  # cracks running out from the pin (stay; thin out at the end)
		var reach := minf((f - 2) * 7.0, 22.0)
		for k in 6:
			var a := k * TAU / 6.0 + 0.4
			var p := ground
			var pts := [p]
			var crng := RandomNumberGenerator.new()
			crng.seed = 100 + k
			for i in int(reach / 3.0):
				a += crng.randf_range(-0.5, 0.5)
				p += Vector2(cos(a), sin(a) * 0.45) * 3.0
				pts.append(p)
			if pts.size() > 1:
				for i in range(1, pts.size()):
					var q0: Vector2 = pts[i - 1]
					var q1: Vector2 = pts[i]
					for s in 4:
						var q := q0.lerp(q1, s / 4.0)
						if f >= 10 and (int(q.x) + int(q.y)) % 2 == 0:
							continue
						_px(gimg, int(q.x), int(q.y), NIGHT)
						_px(gimg, int(q.x), int(q.y) - 1, Color(MOONPATH, 0.75))  # the lit lip of the crack
	if f <= 2:  # three arcs circling in
		var r: float = [26.0, 17.0, 10.0][f]
		for k in 3:
			var a0 := k * TAU / 3.0 + f * 0.9
			var pts := []
			for s in 7:
				var a := a0 + s * 0.16
				pts.append(C + Vector2(cos(a), sin(a) * 0.8) * r)
			_stroke(img, pts, [MIST, MOON, HEART], 2.0)
	if f >= 2 and f <= 6:  # the shaft of light, then narrowing to a pin
		var top: float = [2.0, 2.0, 18.0, 30.0, 38.0][f - 2]
		var w: float = [5.0, 4.0, 3.0, 2.0, 2.0][f - 2]
		var tip := ground + Vector2(0, -1)
		var glow_a := 0.75 if f < 5 else 0.4
		for y in range(int(top), int(tip.y) + 1):
			for x in range(-int(w), int(w) + 1):
				var col: Color = HEART if absf(x) <= w * 0.35 else (MOON if absf(x) <= w * 0.7 else GLOW)
				if absf(x) > w * 0.7 and y % 2 == 0:
					continue
				_px(img, int(tip.x) + x, y, col)
			_px(img, int(tip.x) + int(w) + 1, y, Color(NIGHT, 0.75))  # its shaded edge
			_px(img, int(tip.x) - int(w) - 1, y, Color(GLOW, glow_a))  # a 1-2 px banded glow on the lit side
			if y % 2 == 0:
				_px(img, int(tip.x) - int(w) - 2, y, Color(GLOW, glow_a * 0.5))
	if f == 3 or f == 4:  # the four-armed glint where it lands
		var arm: float = 16.0 if f == 3 else 10.0
		for d: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2(0, 1)]:
			var len := arm * (0.45 if d.y != 0 else 1.0)
			_stroke(img, [ground, ground + d * len], [HEART, MOON, GLOW], 2.0)
		_core(img, ground, 3.0, [GLOW, HEART])
	if f >= 3 and f <= 8:
		_wave(img, ground, 10.0 + (f - 3) * 7.0, MOON, MIST, 1.0 if f < 6 else 0.6)
	if f >= 7 and f <= 9:  # the pin left standing, a glint running down it
		for y in range(int(ground.y) - 12, int(ground.y)):
			_px(img, int(ground.x), y, MOON)
			_px(img, int(ground.x) + 1, y, Color(NIGHT, 0.75))
		var gy: int = int(ground.y) - [11, 6, 2][f - 7]
		for d in range(-2, 3):
			_px(img, int(ground.x) + d, gy, HEART)
			_px(img, int(ground.x), gy + d, HEART)
	if f >= 8:
		_motes(img, rng, ground + Vector2(0, -6), 5, 10.0, 6.0 + (f - 8) * 4.0, [MOON, GLOW], 0.75 if f < 11 else 0.4)
	if f >= 10:  # the mark: a small four-point sparkle on the ground
		_px(img, int(ground.x), int(ground.y), HEART)
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			_px(img, int(ground.x) + d.x, int(ground.y) + d.y, Color(MOON, 0.75 if f == 10 else 0.4))

# --- Shatter: frost ferns creep up round it, it glazes over (a see-through faceted crust, lit upper left), light cracks
# across the glaze, it bursts in a stepped flash into many small two-tone slivers, they fly, tumble and land glinting
# in a frost patch.
func _shatter(img: Image, f: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 90
	var ground := F
	var ice := [MOON, DEWLIGHT, DEW]
	if f >= 3:  # the frost patch: fern lines on the ground (stay; thin out at the end)
		var frng := RandomNumberGenerator.new()
		frng.seed = 33
		for k in 7:
			var a := k * TAU / 7.0
			var p := ground
			for i in 7:
				a += frng.randf_range(-0.4, 0.4)
				p += Vector2(cos(a), sin(a) * 0.4) * 3.0
				if f >= 10 and i % 2 == 0:
					continue
				_px(gimg, int(p.x), int(p.y), Color(DEWLIGHT, 0.75))
				if i % 2 == 1:
					_px(gimg, int(p.x) + 1, int(p.y) - 1, Color(MOON, 0.75))
	if f <= 1:  # frost ferns creeping up round it
		for k in 6:
			var a := -PI / 2.0 + (k - 2.5) * 0.45
			var from := ground + Vector2((k - 2.5) * 7.0, 0)
			_tendril(img, rng, from, a, 8.0 + f * 10.0, [MOON, DEWLIGHT], 1.0, 0.35, 1)
	if f >= 1 and f <= 2:  # the glaze: a see-through faceted crust (checker fill), facet lines, a glint upper left
		var s: float = [1.0, 0.9, 1.0][f]
		var pts := PackedVector2Array()
		for i in 7:
			var a := -PI / 2.0 + i * TAU / 7.0 + 0.15
			pts.append(C + Vector2(cos(a) * 18.0, sin(a) * 21.0) * s)
		for y in range(int(C.y) - 24, int(C.y) + 24):
			for x in range(int(C.x) - 22, int(C.x) + 22):
				var q := Vector2(x + 0.5, y + 0.5)
				if Geometry2D.is_point_in_polygon(q, pts) and (x + y * 2) % 3 != 0:
					var lit := q.x - C.x + (q.y - C.y)  # upper left lit, lower right in shade
					_px(img, x, y, Color(MOON if lit < -10 else (DEWLIGHT if lit < 8 else DEW), 0.75))
		for i in 7:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % 7]
			var col := HEART if i >= 4 else (MOON if i < 2 else DEW)  # lit edges upper left
			_stroke(img, [a, b], [col], 1.0)
			if i % 2 == 0:
				_stroke(img, [a, C + Vector2(-2, -3)], [MOON], 1.0, 0.75)
		if f == 2:  # cracks of light across it
			for k in 4:
				_tendril(img, rng, C + Vector2(-2, -3), k * 1.6 + 0.3, 16.0, [HEART, MOON], 1.0, 0.7, 0)
	if f == 3:  # the burst: a stepped flash in a halo

		_core(img, C, 10.0, [DEWLIGHT, MOON, HEART])
		_band_glow(img, 1.0, DEWLIGHT)
	if f >= 3 and f <= 8:
		_wave(img, ground, 12.0 + (f - 3) * 7.0, DEWLIGHT, DEW, 1.0 if f < 6 else 0.6)
	if f >= 3 and f <= 11:  # slivers flying out, tumbling, falling, a few landing and glinting
		var t := float(f - 3)
		var srng := RandomNumberGenerator.new()
		srng.seed = 7
		for k in 16:
			var a := k * TAU / 16.0 + srng.randf_range(-0.25, 0.25)
			var spd := srng.randf_range(4.0, 7.5)
			var size := srng.randf_range(2.5, 5.0)
			var land_y := ground.y + srng.randf_range(-5.0, 6.0)
			var p := C + Vector2(cos(a), sin(a) * 0.75) * spd * minf(t + 0.6, 4.5) + Vector2(0, t * t * 0.7)
			var landed := p.y >= land_y and t > 2.0
			if landed:
				p.y = land_y
				if k % 4 != 0 and f >= 9:
					continue  # most melt away; a few stay
			var rot := a + t * (0.7 if k % 2 == 0 else -0.7) * (0.0 if landed else 1.0)
			_sliver(gimg if landed else img, p, rot, size, (f + k) % 4 == 0, 1.0 if f < 10 else 0.75)
	if f >= 8:
		_motes(img, rng, ground + Vector2(0, -4), 5, 14.0, 4.0 + (f - 8) * 4.0, [MOON, DEWLIGHT], 0.75)

# An ice sliver: a thin diamond `size` long, its upper-left facet Moonlight (a Heartlight tip when it glints), the
# other Dewlight, the shaded edge Dew, a Night outline.
func _sliver(img: Image, p: Vector2, rot: float, size: float, glint: bool, alpha: float) -> void:
	var dir := Vector2.from_angle(rot)
	var side := dir.orthogonal() * maxf(1.2, size * 0.32)
	var pts := PackedVector2Array([p + dir * size, p + side, p - dir * size * 0.6, p - side])
	var cells := {}
	for y in range(int(p.y - size) - 2, int(p.y + size) + 3):
		for x in range(int(p.x - size) - 2, int(p.x + size) + 3):
			var q := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(q, pts):
				var lit := (q - p).dot(Vector2(-1, -1).normalized()) > 0.0
				cells[Vector2i(x, y)] = MOON if lit else DEWLIGHT
	if cells.size() < 2:
		cells[Vector2i(int(p.x), int(p.y))] = MOON
		cells[Vector2i(int(p.x + dir.x * 2.0), int(p.y + dir.y * 2.0))] = DEWLIGHT
	for c: Vector2i in cells:
		for n: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not cells.has(c + n):
				_px(img, c.x + n.x, c.y + n.y, Color(NIGHT, alpha * 0.75))
	for c: Vector2i in cells:
		_px(img, c.x, c.y, Color(cells[c], alpha))
	if glint:
		var tip := p + dir * (size - 1.0)
		_px(img, int(tip.x), int(tip.y), HEART)

# A fire mass on `base`, `half_w` wide each side, up to `h` tall: the top edge is a sum of flickering tongues, so it is
# one body with several tips. Heartlight low in the middle, Glow, Gold, Ember at the top and along the edges.
func _fire(img: Image, base: Vector2, h: float, half_w: float, f: int) -> void:
	var tops := {}
	for x in range(-int(half_w), int(half_w) + 1):
		var t := 0.0
		for k in 4:
			var cx := (k - 1.5) * half_w * 0.5 + sin(f * 1.3 + k * 2.0) * 1.5
			var share: float = [0.6, 0.95, 0.8, 0.55][k]
			var hk := h * share * (0.85 + 0.2 * sin(f * 1.7 + k * 2.6))
			var w := half_w * 0.32
			t = maxf(t, hk * exp(-pow((x - cx) / w, 2.0)))
		t *= sqrt(maxf(0.0, 1.0 - pow(x / (half_w + 0.5), 2.0)))
		tops[x] = t
	var body := {}
	for x: int in tops:
		var t: float = tops[x]
		for y in int(t) + 1:
			var v := y / maxf(t, 1.0)  # 0 at the root, 1 at this column's tip
			var mid := 1.0 - absf(x) / half_w
			var col := EMBER
			if v < 0.85:
				col = GOLD
			if v < 0.6 and mid > 0.3:
				col = GLOW
			if v < 0.3 and mid > 0.55:
				col = HEART
			body[Vector2i(int(base.x) + x, int(base.y) - y)] = col
	for p: Vector2i in body:  # Ember rim where the flame meets the air (a dark-ish edge that holds on the path)
		var col: Color = body[p]
		for n: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
			if not body.has(p + n) and col != HEART:
				col = EMBER
		_px(img, p.x, p.y, col)
	for p: Vector2i in body:  # a 1 px banded glow round it, two steps
		for n: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
			var q := p + n
			if not body.has(q) and img.get_pixel(clampi(q.x, 0, 95), clampi(q.y, 0, FH - 1)).a < 0.5:
				_px(img, q.x, q.y, Color(GLOW, 0.4))

# The glow every house effect uses: transparent pixels 1 px out from what is drawn get Glow, 2 px out a lighter checker.
func _band_glow(img: Image, strength: float, col: Color = GLOW) -> void:
	var solid := {}
	for y in FH:
		for x in 96:
			if img.get_pixel(x, y).a > 0.5:
				solid[Vector2i(x, y)] = true
	var ring := {}
	for p: Vector2i in solid:
		for n: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not solid.has(p + n):
				ring[p + n] = true
	for p: Vector2i in ring:
		_px(img, p.x, p.y, Color(col, 0.75 * strength))
		for n: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var q := p + n
			if not solid.has(q) and not ring.has(q) and (q.x + q.y) % 2 == 0:
				_px(img, q.x, q.y, Color(col, 0.4 * strength))

# --- Thunderclap: static crackles round it, a gold bolt slams down (branching, Heartlight core), a stepped flash and a
# shockwave, arcs jump out to the nightmares either side, the wet throws up droplets, steam and sparks drift off.
func _thunderclap(img: Image, f: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 200 + f
	var ground := F
	var bolt := [HEART, GLOW, GOLD]
	if f <= 1:  # static crackling round it: little zigzags flicking on and off
		for k in 6:
			var a := k * TAU / 6.0 + f * 0.7
			var p := C + Vector2(cos(a) * 16.0, sin(a) * 13.0)
			var q := p + Vector2(rng.randf_range(-4, 4), rng.randf_range(-4, 4))
			_stroke(img, [p, p.lerp(q, 0.5) + Vector2(2, -2), q], [GLOW, GOLD], 1.0)
	if f >= 2 and f <= 4:  # the bolt from the sky, branching
		var top := Vector2(C.x + 6.0, 0.0)
		var pts := [top]
		var p := top
		var brng := RandomNumberGenerator.new()
		brng.seed = 21
		while p.y < C.y - 2.0:
			p += Vector2(brng.randf_range(-5.0, 5.0), brng.randf_range(6.0, 9.0))
			p.x = lerpf(p.x, C.x, 0.25)
			pts.append(p)
		pts.append(C)
		_stroke(img, pts, bolt, 3.0 if f < 4 else 2.0, 1.0 if f < 4 else 0.75)
		for b in 2:
			var from: Vector2 = pts[2 + b * 2]
			_tendril(img, brng, from, PI / 2.0 + (0.9 if b == 0 else -0.9), 12.0, [GLOW, GOLD], 1.0, 0.5, 0)
	if f == 3 or f == 4:  # the stepped flash where it lands
		_core(img, C, 9.0 if f == 3 else 6.0, [GOLD, GLOW, HEART])
		_band_glow(img, 0.75 if f == 3 else 0.4)
	if f >= 3 and f <= 8:
		_wave(img, ground, 12.0 + (f - 3) * 7.0, GLOW, GOLD, 1.0 if f < 6 else 0.6)
	if f >= 4 and f <= 7:  # arcs leaping to the nightmares either side
		for s: int in [-1, 1]:
			var arng := RandomNumberGenerator.new()
			arng.seed = 40 + f * 3 + s
			var reach: float = [0.0, 0.0, 0.0, 0.0, 24.0, 38.0, 44.0, 44.0][f]
			var pts := [C]
			var steps := 6
			for i in steps:
				var u := (i + 1) / float(steps)
				pts.append(C + Vector2(s * reach * u, -sin(u * PI) * 6.0 + arng.randf_range(-3.0, 3.0)))
			_stroke(img, pts, bolt, 2.0 if f < 6 else 1.0, 1.0 if f < 7 else 0.6)
	if f >= 4 and f <= 9:  # droplets thrown up off its wet
		var t := float(f - 4)
		var drng := RandomNumberGenerator.new()
		drng.seed = 8
		for k in 8:
			var a := -PI / 2.0 + drng.randf_range(-1.2, 1.2)
			var v := drng.randf_range(4.0, 6.0)
			var p := C + Vector2(cos(a) * v * t, sin(a) * v * t + t * t * 0.9)
			if p.y > ground.y + 2.0:
				continue
			_px(img, int(p.x), int(p.y), DEWLIGHT)
			_px(img, int(p.x), int(p.y) + 1, Color(DEW, 0.75))
	if f >= 7:  # steam curling up, the last sparks
		_motes(img, rng, C + Vector2(0, -6), 7, 12.0, 6.0 + (f - 7) * 4.0, [MIST, MOON, GLOW], 0.75 if f < 11 else 0.4)

# --- Mushrooming: spores bubble up off it, a ring of pink caps bursts out of the ground round it, each puffs, the puffs
# swell into a dithered spore dome over the cell, the caps sink back and spores drift.
func _mushrooming(img: Image, f: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 300 + f
	var ground := F
	if f <= 2:  # spores bubbling up off it
		for k in 6 + f * 3:
			var p := C + Vector2(rng.randf_range(-12, 12), rng.randf_range(-6, 8) - f * 3.0)
			_px(img, int(p.x), int(p.y), BLOSSOM)
			if k % 3 == 0:
				_px(img, int(p.x) + 1, int(p.y), Color(HEART, 0.75))
	if f >= 4 and f <= 10:  # the spore dome: a dithered Blossom dome over the cell, a lit rim
		var r: float = [0, 0, 0, 0, 14.0, 20.0, 25.0, 28.0, 29.0, 29.0, 28.0][f]
		var fade := 1.0 if f < 9 else 0.6
		for y in range(int(ground.y - r * 1.1), int(ground.y) + 1):
			for x in range(int(ground.x - r) - 1, int(ground.x + r) + 2):
				var d := Vector2((x + 0.5 - ground.x) / r, (y + 0.5 - ground.y) / (r * 1.1)).length()
				if d > 1.0:
					continue
				if d > 0.9:
					_px(img, x, y, Color(BLOSSOM if y < ground.y - r * 0.4 else ORCHID, fade))
				elif (x + y) % 2 == 0 and (x / 2 + y / 3 + f) % 3 != 0:
					_px(img, x, y, Color(BLOSSOM, 0.4 * fade))
	if f >= 2 and f <= 10:  # the ring of caps bursting up (Spore Print's mushroom look: Blossom cap, Heartlight spots,
		# Moonpath stem, Night outline), each puffing on its way up
		var grow: float = [0, 0, 0.4, 0.8, 1.1, 1.0, 1.0, 1.0, 0.85, 0.6, 0.35][f]
		for k in 5:
			var a := k * TAU / 5.0 + 0.3
			var base := ground + Vector2(cos(a) * 18.0, sin(a) * 6.0)
			var size := (5.0 if k % 2 == 0 else 4.0) * grow
			if size < 1.0:
				continue
			var l := {}
			for y in range(int(-size * 1.2), 1):  # the stem
				l[Vector2i(int(base.x), int(base.y) + y)] = MOONPATH
				l[Vector2i(int(base.x) + 1, int(base.y) + y)] = Color("bca48c")
			var top := base + Vector2(0.5, -size * 1.2)
			for y in range(-int(size), 1):
				for x in range(-int(size * 1.4), int(size * 1.4) + 1):
					if Vector2(x / (size * 1.4), y / size).length() <= 1.0:
						var col := BLOSSOM if x < size * 0.3 else ORCHID
						if (x * 3 + y * 5 + k) % 7 == 0:
							col = HEART
						l[Vector2i(int(top.x) + x, int(top.y) + y)] = col
			_shape(gimg if sin(a) < 0.0 else img, l, NIGHT)  # caps behind it grow under it
			if f >= 4 and f <= 7 and (k + f) % 2 == 0:  # a puff off the cap
				var pp := top + Vector2(0, -size - (f - 3) * 2.0)
				_core(img, pp, 2.5, [ORCHID, BLOSSOM])
	if f >= 3 and f <= 8:
		_wave(img, ground, 12.0 + (f - 3) * 6.0, BLOSSOM, ORCHID, 1.0 if f < 6 else 0.6)
	if f >= 8:
		_motes(img, rng, ground + Vector2(0, -10), 9, 18.0, 4.0 + (f - 8) * 4.0, [BLOSSOM, HEART], 0.75 if f < 11 else 0.4)

# --- Drown: ripples close in round its feet, a see-through whirlpool opens under it (a waterline over its feet), waves rise either side
# and close over it, bubbles rise, the pool keeps turning.
func _drown(img: Image, f: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 400 + f
	var ground := F
	if f <= 2:  # ripples closing in
		for k in 2:
			var r := 30.0 - f * 8.0 - k * 7.0
			if r > 4.0:
				_wave(img, ground, r, DEWLIGHT, DEW, 0.75)
	if f >= 2:  # the whirlpool under it: see-through water (dithered Dew) with Dewlight swirl lines turning in it, a
		# rim lit upper left, a small dark eye under its feet only, so the nightmare's dark legs stay readable
		var r: float = minf(6.0 + (f - 2) * 5.0, 18.0)
		for y in range(int(ground.y - r * 0.45) - 1, int(ground.y + r * 0.45) + 2):
			for x in range(int(ground.x - r) - 1, int(ground.x + r) + 2):
				var q := Vector2((x + 0.5 - ground.x) / r, (y + 0.5 - ground.y) / (r * 0.45))
				var d := q.length()
				if d > 1.0:
					continue
				var swirl := fmod(atan2(q.y, q.x) + d * 5.5 - f * 0.7 + TAU * 4.0, TAU / 3.0)
				if d > 0.86:
					_px(gimg, x, y, DEWLIGHT if q.x + q.y < -0.3 else DEW)
				elif d < 0.28:
					_px(gimg, x, y, POOL)
				elif swirl < 0.4:
					_px(gimg, x, y, DEWLIGHT if d > 0.5 else DEW)
				elif (x + y) % 2 == 0:
					_px(gimg, x, y, Color(DEW, 0.75))
		for y in range(int(ground.y - r * 0.45) - 1, int(ground.y + r * 0.45) + 3):  # a Night edge on its lower rim
			for x in range(int(ground.x - r) - 1, int(ground.x + r) + 2):
				var d := Vector2((x + 0.5 - ground.x) / r, (y + 0.5 - ground.y) / (r * 0.45)).length()
				if d > 1.0 and d < 1.12 and y > ground.y:
					_px(gimg, x, y, Color(NIGHT, 0.75))
	if f >= 3:  # the waterline across the front of its feet (over it): it stands in the water, being pulled down
		var half: float = minf(5.0 + (f - 3) * 3.0, 11.0)
		for x in range(-int(half), int(half) + 1):
			var y := int(ground.y) - 1 + int(round(sin(x * 0.7 + f * 1.3) * 0.6))
			_px(img, int(ground.x) + x, y, MOON if (x + f) % 3 != 0 else DEWLIGHT)
			_px(img, int(ground.x) + x, y + 1, Color(DEW, 0.75))
	if f >= 3 and f <= 8:  # waves rising either side and closing over it: curling crests
		var h: float = [0, 0, 0, 12.0, 20.0, 26.0, 24.0, 18.0, 10.0][f]
		var close: float = [0, 0, 0, 0.0, 0.25, 0.55, 0.8, 0.9, 1.0][f]
		for s: int in [-1, 1]:
			var base := ground + Vector2(s * 18.0, -1)
			var crest := base + Vector2(-s * 10.0 * close, -h)
			var curl := crest + Vector2(-s * 7.0, 3.0)
			_stroke(img, [base, base.lerp(crest, 0.5) + Vector2(s * 3.0, 0), crest, curl], [DEW, DEWLIGHT, MOON, HEART], 4.0)
			_px(img, int(crest.x), int(crest.y) - 1, HEART)
	if f >= 4:  # bubbles rising
		for k in 5:
			var t := float((f - 4 + k * 2) % 8)
			var p := ground + Vector2((k - 2) * 5.0 + sin(t + k) * 1.5, -2.0 - t * 3.5)
			_px(img, int(p.x), int(p.y), MOON)
			_px(img, int(p.x) + 1, int(p.y), Color(DEWLIGHT, 0.75))
			_px(img, int(p.x), int(p.y) + 1, Color(DEW, 0.75))

# --- Lightning Rod: a gold rod of light rises over it with a spark at its tip, bolts arc in from the sides into the
# tip, the rod flares, then hums: the spark flickers and small arcs crawl down it to the nightmare.
func _lightning_rod(img: Image, f: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 600 + f
	var foot := C + Vector2(0, -6)  # the rod stands on its head
	var rise: float = [6.0, 14.0, 20.0, 22.0, 22.0, 22.0, 22.0, 22.0, 22.0, 22.0, 22.0, 20.0][f]
	var tip := foot + Vector2(0, -rise)
	for y in range(int(tip.y), int(foot.y) + 1):  # the rod: Heartlight core, Gold edge, Night shade side
		_px(img, int(tip.x), y, HEART)
		_px(img, int(tip.x) - 1, y, GOLD)
		_px(img, int(tip.x) + 1, y, Color(NIGHT, 0.75))
	var spark: float = [2.0, 2.5, 3.0, 5.0, 4.0, 3.0, 3.5, 3.0, 3.5, 3.0, 2.5, 2.0][f]
	_core(img, tip, spark, [GOLD, GLOW, HEART])
	if f >= 2 and f <= 4:  # bolts arcing in from the sides (and above) into the tip
		var brng := RandomNumberGenerator.new()
		brng.seed = 66
		for s in 3:
			var from := Vector2([4.0, 92.0, 70.0][s], [30.0, 24.0, 0.0][s])
			var pts := [from]
			for i in 5:
				var u := (i + 1) / 6.0
				pts.append(from.lerp(tip, u) + Vector2(brng.randf_range(-4, 4), brng.randf_range(-4, 4)))
			pts.append(tip)
			_stroke(img, pts, [GOLD, GLOW, HEART], 2.0 if f == 3 else 1.0, 1.0 if f < 4 else 0.6)
	if f == 3:
		_band_glow(img, 0.75)
	if f >= 3 and f <= 7:  # a gold ring rippling out round the tip
		_wave(img, tip, 6.0 + (f - 3) * 6.0, GLOW, GOLD, 1.0 if f < 6 else 0.6, false)  # in the air round the tip
	if f >= 5:  # humming: small arcs crawling down to the nightmare
		for k in 2:
			var a := rng.randf_range(0.6, 2.5)
			var from := tip + Vector2(rng.randf_range(-2, 2), 2)
			_tendril(img, rng, from, a, 12.0, [GLOW, GOLD], 1.0, 0.7, 0)

# A filled shape from a mask dictionary {Vector2i: Color}, with a 1 px outline round it.
func _shape(img: Image, layer: Dictionary, outline: Color, alpha: float = 1.0) -> void:
	for p: Vector2i in layer:
		for n: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not layer.has(p + n):
				_px(img, p.x + n.x, p.y + n.y, Color(outline, alpha))
	for p: Vector2i in layer:
		_px(img, p.x, p.y, Color(layer[p], alpha))


var gimg: Image  # the ground layer being drawn (under the nightmare); `img` in the draw functions is the over layer

# Draws Reaction `name`'s frame `f` into `img`: its over layer, or its ground layer when `ground`.
func draw(img: Image, f: int, name: String, ground: bool) -> void:
	var over := Image.create_empty(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	gimg = Image.create_empty(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	call("_" + name, over, f)
	var src := gimg if ground else over
	img.blend_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), Vector2i.ZERO)

# Smother loops while its Hold lasts: the two ribbons wrapped round it, turning, and the pods pulsing (8 frames).
func _smother_loop(img: Image, f: int) -> void:
	var ground := F
	var smoke := [NEWLEAF, SPRIG, LEAF_C, MOSS_C]
	var turn := f * TAU / 8.0
	for s in 2:
		var pts := []
		for i in 16:
			var u := i / 15.0
			var a := s * PI + u * TAU * 1.4 + turn
			var r := 26.0 * 0.45 * (1.0 - u * 0.3)
			pts.append(ground + Vector2(cos(a) * r, sin(a) * r * 0.4 - u * 34.0))
		for i in range(1, pts.size()):
			var a_mid := s * PI + (i - 0.5) / 15.0 * TAU * 1.4 + turn
			var col: Color = smoke[mini(int((i - 1) / 15.0 * smoke.size()), smoke.size() - 1)]
			_stroke(img if sin(a_mid) >= 0.0 else gimg, [pts[i - 1], pts[i]], [col], lerpf(3.0, 1.0, i / 15.0))
	var swell := 2.6 + 0.6 * sin(turn)
	for k in 5:
		var a := k * 1.9 + 0.5
		var p := C + Vector2(cos(a) * 11.0, sin(a) * 12.0 - 2.0)
		var l := {}
		for y in range(-int(swell) - 1, int(swell) + 2):
			for x in range(-int(swell) - 1, int(swell) + 2):
				if Vector2(x, y).length() <= swell:
					l[Vector2i(int(p.x) + x, int(p.y) + y)] = NEWLEAF if x + y < 0 else SPRIG
		_shape(img, l, DEEPMOSS)
		_px(img, int(p.x) - 1, int(p.y) - 1, HEART)
