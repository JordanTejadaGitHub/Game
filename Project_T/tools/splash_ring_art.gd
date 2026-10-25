extends RefCounted
# Splash rings that belong to their Warden's attack (user-approved 2026-10-21: "make sure all splash wardens have the
# splash circle radius, make sure it blends in with their attack animation", then "fade it a bit more", "a bit more
# translucent"). One sheet per family style, splash_ring_<style>: stone (Pebbling, Cairn, Rockslide, Boulderback, Old
# Mountain), acorn, water (Dewdrop, Rain Lily), frost (Hoarfrost), spore (Puffball), firework (Sparkler, Starburst).
# Drawn at a 1-cell reference radius (R = 64 px) in a 160x160 frame, centre (80, 80) = where the splash lands; play it
# scaled by radius / 64 on the ground (z -1). 8 frames at 18 fps (~0.45 s, the old code ring's SPLASH_TIME): out to the
# radius in 3 frames, hold, fade. The edge is a see-through 2 px line (0.4) on a soft Night rim at exactly R; the
# family's debris (0.75) sits on and just past it. effect_art_generator.gd writes them through draw().

const R := 64.0
const FS := 160
const CC := Vector2(80, 80)
const STYLES := ["stone", "acorn", "water", "frost", "spore", "firework", "generic"]

const NIGHT := Color("24243c")
const LOAM := Color("6c5c5c")
const PATH := Color("b4a494")
const MOONPATH := Color("dccdb2")
const STONE := Color("8c8cac")
const MIST := Color("b4b0c8")
const MOON := Color("dce8f4")
const HEART := Color("fff4dc")
const GLOW := Color("fcd47c")
const GOLD := Color("e9a83c")
const EMBER := Color("b8662c")
const OAK := Color("8c5c34")
const BARK := Color("5c3c24")
const SPRIG := Color("9cc46c")
const LEAF := Color("5c944c")
const DEW := Color("4c8ca4")
const DEWLIGHT := Color("9cd4fc")
const BLOSSOM := Color("ec9cf4")
const ORCHID := Color("bc44dc")

# Draws style `style`'s frame `f` into `img` (160x160).
func draw(img: Image, f: int, style: String) -> void:
	call("_" + style, img, f)

# --- Primitives ---------------------------------------------------------------------------------------------------
func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, img.get_pixel(x, y).blend(c))

const GROW: Array[float] = [0.45, 0.75, 0.93, 1.0, 1.0, 1.0, 1.0, 1.0]
const FADE: Array[float] = [0.75, 0.75, 0.75, 0.75, 0.75, 0.6, 0.4, 0.3]  # Debris strength by frame; the edge is 0.6 of it

# The clear edge every style shares: a 2 px line at radius r in `col`, a 1 px Night rim just outside it; `dots` > 0
# leaves gaps (a dotted edge every `dots` px of arc).
func _edge(img: Image, r: float, col: Color, alpha_in: float, dots: int = 0) -> void:
	var alpha := alpha_in * 0.6  # see-through (user: "a bit more translucent"): the 0.4 step while it holds
	for y in range(int(CC.y - r) - 3, int(CC.y + r) + 4):
		for x in range(int(CC.x - r) - 3, int(CC.x + r) + 4):
			var q := Vector2(x + 0.5, y + 0.5) - CC
			var d := q.length()
			if dots > 0 and int((atan2(q.y, q.x) + PI) * r) % dots >= dots - 2:
				continue
			if d > r and d <= r + 1.0:
				_px(img, x, y, Color(NIGHT, 0.55 * alpha))
			elif d <= r and d > r - 2.0:
				_px(img, x, y, Color(col, alpha_in * (1.0 if (x + y) % 2 == 0 else 0.55)))  # 0.75 and 0.4 pixels alternating: between the two steps (user: "a bit less translucent")

# A small blob with a 1 px outline (a pebble, a dust puff, a spore puff), lit upper left.
func _blob(img: Image, c: Vector2, rad: float, lit: Color, shade: Color, outline: Color, alpha: float, dither: bool = false) -> void:
	var cells := {}
	for y in range(int(c.y - rad) - 1, int(c.y + rad) + 2):
		for x in range(int(c.x - rad) - 1, int(c.x + rad) + 2):
			var q := Vector2(x + 0.5, y + 0.5) - c
			if q.length() <= rad and (not dither or (x + y) % 2 == 0):
				cells[Vector2i(x, y)] = lit if q.x + q.y < 0.0 else shade
	if outline.a > 0.0 and not dither:
		for p: Vector2i in cells:
			for n: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if not cells.has(p + n):
					_px(img, p.x + n.x, p.y + n.y, Color(outline, alpha * 0.75))
	for p: Vector2i in cells:
		_px(img, p.x, p.y, Color(cells[p], alpha))

func _on_ring(k: int, n: int, r: float, turn: float = 0.0) -> Vector2:
	var a := k * TAU / n + turn
	return CC + Vector2(cos(a), sin(a)) * r

# --- Stone: a dust ring kicked up along the edge, pebbles thrown out to it -------------------------------------------
func _stone(img: Image, f: int) -> void:
	var r := R * GROW[f]
	var al := FADE[f]
	for k in 16:  # dust puffs riding the edge, settling and thinning
		var p := _on_ring(k, 16, r - 2.0, 0.1)
		var size := (3.5 if k % 2 == 0 else 2.5) * (1.0 if f < 4 else 0.8)
		_blob(img, p, size, MOONPATH, PATH, LOAM, al, f >= 6)
	_edge(img, r, MOONPATH, al)
	for k in 8:  # pebbles flying out, landing just past the edge
		var u := minf((f + 1) / 4.0, 1.0)
		var p := CC.lerp(_on_ring(k, 8, R + 4.0, 0.35), u) + Vector2(0, -sin(u * PI) * 6.0)
		_blob(img, p, 2.2, MIST, STONE, NIGHT, al)

# --- Acorn: husk chips and a couple of leaves flicked out to a warm edge -----------------------------------------------
func _acorn(img: Image, f: int) -> void:
	var r := R * GROW[f]
	var al := FADE[f]
	_edge(img, r, GOLD, al)
	for k in 12:  # husk chips: Oak slivers with a Bark side and a Gold lit edge, outlined, flicked out to the edge
		var u := minf((f + 1) / 4.0, 1.0)
		var a := k * TAU / 12.0 + 0.2
		var p := CC.lerp(_on_ring(k, 12, R + 1.0, 0.2), u) + Vector2(0, -sin(u * PI) * 5.0)
		var d := Vector2.from_angle(a + f * 0.6)
		var cells := {Vector2i(int(p.x), int(p.y)): OAK, Vector2i(int(p.x + d.x), int(p.y + d.y)): BARK, Vector2i(int(p.x - d.x), int(p.y - d.y)): GOLD, Vector2i(int(p.x - d.x * 2.0), int(p.y - d.y * 2.0)): OAK}
		for c: Vector2i in cells:
			for n: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if not cells.has(c + n):
					_px(img, c.x + n.x, c.y + n.y, Color(NIGHT, 0.75 * al))
		for c: Vector2i in cells:
			_px(img, c.x, c.y, Color(cells[c], al))
	for k in 5:  # leaves tumbling out
		var u := minf((f + 1) / 5.0, 1.0)
		var p := CC.lerp(_on_ring(k, 5, R - 4.0, 0.9), u) + Vector2(sin(f + k) * 2.0, -sin(u * PI) * 10.0)
		_blob(img, p, 2.2, SPRIG, LEAF, NIGHT, al)

# --- Water: the drop lands, ripples run out behind the clear edge, droplets fall back round it --------------------------
func _water(img: Image, f: int) -> void:
	var r := R * GROW[f]
	var al := FADE[f]
	_edge(img, r, MOON, al)
	for k in 2:  # inner ripples, a step behind, fading first
		var rk := r * (0.5 + 0.22 * k) * minf((f + 1) / 5.0, 1.0)
		if rk > 4.0 and f < 6:
			for y in range(int(CC.y - rk) - 1, int(CC.y + rk) + 2):
				for x in range(int(CC.x - rk) - 1, int(CC.x + rk) + 2):
					var d := Vector2(x + 0.5, y + 0.5).distance_to(CC)
					if d <= rk and d > rk - 1.0:
						_px(img, x, y, Color(DEWLIGHT, 0.75 * al))
	if f <= 1:
		_blob(img, CC, 3.0, HEART, DEWLIGHT, DEW, 1.0)
	for k in 8:  # droplets arcing out and landing on the edge
		var u := minf((f + 1) / 4.0, 1.0)
		var p := CC.lerp(_on_ring(k, 8, R - 3.0, 0.4), u) + Vector2(0, -sin(u * PI) * 9.0)
		_px(img, int(p.x), int(p.y), Color(MOON, al))
		_px(img, int(p.x), int(p.y) + 1, Color(DEW, al))

# --- Frost: a ring of ice spikes pushes up along the edge, glinting --------------------------------------------------
func _frost(img: Image, f: int) -> void:
	var r := R * GROW[f]
	var al := FADE[f]
	_edge(img, r, DEWLIGHT, al)
	var grow: float = [0.3, 0.6, 0.9, 1.0, 1.0, 1.0, 0.9, 0.7][f]
	for k in 14:
		var a := k * TAU / 14.0 + 0.15
		var out := Vector2.from_angle(a)
		var base := CC + out * (r - 1.0)
		var h := (6.0 if k % 2 == 0 else 4.0) * grow
		var side := out.orthogonal() * 2.0
		var cells := {}
		var pts := PackedVector2Array([base - side, base + out * h, base + side])
		for y in range(int(base.y) - 8, int(base.y) + 9):
			for x in range(int(base.x) - 8, int(base.x) + 9):
				var q := Vector2(x + 0.5, y + 0.5)
				if Geometry2D.is_point_in_polygon(q, pts):
					cells[Vector2i(x, y)] = MOON if (q - base).dot(Vector2(-1, -1)) > 0.0 else DEWLIGHT
		for p: Vector2i in cells:
			for n: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if not cells.has(p + n):
					_px(img, p.x + n.x, p.y + n.y, Color(NIGHT, 0.75 * al))
		for p: Vector2i in cells:
			_px(img, p.x, p.y, Color(cells[p], al))
		if (k + f) % 5 == 0 and f >= 2:
			var tip := base + out * h
			_px(img, int(tip.x), int(tip.y), HEART)

# --- Spore: a puffy pink band of spores along the edge, a few spores drifting up -------------------------------------
func _spore(img: Image, f: int) -> void:
	var r := R * GROW[f]
	var al := FADE[f]
	for k in 18:
		var p := _on_ring(k, 18, r - 2.0, 0.0) + Vector2(0, -float(f) * 0.6)
		_blob(img, p, 3.0 if k % 3 == 0 else 2.2, BLOSSOM, ORCHID, NIGHT, al, f >= 5)
	_edge(img, r, BLOSSOM, al)
	for k in 8:
		var p := _on_ring(k, 8, r * 0.8, 0.3) + Vector2(sin(f + k) * 2.0, -f * 2.0)
		_px(img, int(p.x), int(p.y), Color(BLOSSOM if k % 2 == 0 else HEART, al))

# --- Generic: every splash's ring (splash rework, owner 2026-10-25: "1 generic splash ring"; the family rings above show
# only once Spattered makes splashes carry their status). Damage, not a family (UI council 2026-10-25): a pale Mist edge
# no family uses, broken every 16 px so it never reads as a range circle, a stronger Night rim for the sand path, 8 short
# impact streaks thrown just past the edge; it fades first (the commonest ring on the map).
const GENERIC_FADE: Array[float] = [0.75, 0.75, 0.75, 0.75, 0.55, 0.35, 0.2, 0.08]
const GENERIC_STREAK: Array[int] = [4, 4, 4, 3, 3, 2, 1, 1]  # Length by frame
func _generic(img: Image, f: int) -> void:
	var r := R * GROW[f]
	var al := GENERIC_FADE[f]
	_edge(img, r, MIST, al, 16)
	for y in range(int(CC.y - r) - 2, int(CC.y + r) + 3):  # A stronger Night rim than _edge's, this style only
		for x in range(int(CC.x - r) - 2, int(CC.x + r) + 3):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(CC)
			if d > r and d <= r + 1.0:
				_px(img, x, y, Color(NIGHT, 0.5 * al))
	var u := minf((f + 1) / 4.0, 1.0)
	for k in 8:  # streaks: 2 px wide, outlined, flung just past the edge in a small arc
		var out := Vector2.from_angle(k * TAU / 8.0 + 0.26)
		var head := CC + out * (R + 3.0) * u + Vector2(0, -sin(u * PI) * 4.0)
		var side := out.orthogonal().round()
		var cells := {}
		for d in GENERIC_STREAK[f]:
			var p := (head - out * d).round()
			var ink: Color = (GLOW if f <= 2 else HEART) if d == 0 else (MIST if d < GENERIC_STREAK[f] - 1 else STONE)
			for q: Vector2 in [p, p + side]:
				if f < 5 or (int(q.x) + int(q.y)) % 2 == 0:
					cells[Vector2i(int(q.x), int(q.y))] = ink
		for c: Vector2i in cells:
			for n: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if not cells.has(c + n):
					_px(img, c.x + n.x, c.y + n.y, Color(NIGHT, 0.75 * al))
		for c: Vector2i in cells:
			_px(img, c.x, c.y, Color(cells[c], al))
	if f <= 1:  # the landing's own small flash
		_blob(img, CC, 2.5, HEART, MIST, NIGHT, 0.9)

# --- Firework: a gold dotted edge, sparks blinking on it ------------------------------------------------------------
func _firework(img: Image, f: int) -> void:
	var r := R * GROW[f]
	var al := FADE[f]
	_edge(img, r, GOLD, al, 6)
	for k in 10:
		if (k + f) % 3 == 0:
			continue
		var p := _on_ring(k, 10, r, f * 0.05)
		var arm := 3 if (k + f) % 2 == 0 else 2
		for d in range(-arm, arm + 1):
			_px(img, int(p.x) + d, int(p.y), Color(GLOW, al))
			_px(img, int(p.x), int(p.y) + d, Color(GLOW, al))
		_px(img, int(p.x), int(p.y), Color(HEART, al))
