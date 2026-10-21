extends SceneTree
# Growing into the next form (user-approved 2026-10-21, the fireflies at 0.8 s): one sheet per grow, from -> into, in
# assets/towers/grow/<from>__<into>.png, 12 frames at 15 fps, every frame the same size (FRAME), and grow.json.
#
# Fireflies blink on and circle in round the Warden (behind it dimmer, in front brighter, short trails) over a warm pool
# of light on the ground; the old form's body goes to a Night shadow; they land along the next form's outline and a thin
# gold line draws it up both sides to the top over its silhouette; light fills it from the feet up; they lift off and
# blink out, the last one on its head. The slabs stay as they are (plant/<id>.png frame 0 = the bare slab, 1 = the body).
#
# The sheet replaces the Warden while it plays (hide the sprite): every frame holds both forms, drawn where the game
# draws them. Frame pixel ANCHOR is the Warden node's origin (its cell centre); each form's idle frame 0 sits as Tower
# draws it (centred on the node + TowerData.get_sprite_offset()). Run from the project:
#   godot --headless --path Project_T --script res://tools/grow_art_generator.gd
# It reads the finished idle sheets and plant sheets, so run it after tower_art_generator / ascended_art_generator.
const OUT := "res://assets/towers/grow/"
const TOWERS := "res://resource/tower/"
const PLANT := "res://assets/towers/plant/%s.png"
const PALETTE_TOOL := "res://tools/art/heartwood_palette.gd"
const FPS := 15
const STEPS: Array[int] = [1, 5, 8, 10, 11, 12, 13, 14, 15, 18, 21, 24]  # Steps of the 26-step long cut the user saw first
const FLIES := 30
const TRACE_START := 10
const TRACE_FRAMES := 3.0
const WIDTH := 128          # At least room for the widest orbit (54 px out) either side; wider for wider art (Ascended 160)
const ABOVE := 40           # Room over the tallest form for the fireflies lifting off
const BELOW := 36           # At least: the cell bottom is +32 (the pool ends above); lower for art reaching lower (Ascended +56)

const CORE := Color("fff4dc")       # Heartlight: a firefly
const GLOW := Color("fcd47c")       # Glow: its halo, the trace, the pool
const SHADOW := Color("24243c")     # Night: a body gone dark (never a nightmare violet)

var _palette: Script
var _top := 0                       # The highest and lowest pixel any form reaches (node y) and its widest frame,
var _bottom := 0                    # for one frame size for all
var _wide := 0
var _frame := Vector2i.ZERO
var _anchor := Vector2i.ZERO
var _parts := {}                    # id -> {slab: Image, body: Image, at: Vector2i (frame top-left, node coords)}

func _init() -> void:
	_palette = load(PALETTE_TOOL)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var datas := {}
	for file in DirAccess.get_files_at(TOWERS):
		if not file.ends_with(".tres"):
			continue
		var data := load(TOWERS + file) as TowerData
		if data == null or data.texture == null:
			continue
		datas[data.get_id()] = data
		var size := data.get_frame_rect(0).size
		_top = mini(_top, int(data.get_sprite_offset().y - size.y / 2.0))
		_bottom = maxi(_bottom, int(data.get_sprite_offset().y + size.y / 2.0))
		_wide = maxi(_wide, int(size.x))
	var width := maxi(WIDTH, _wide + 8)
	var below := maxi(BELOW, _bottom + 2)
	_frame = Vector2i(width, below - (_top - ABOVE))
	_anchor = Vector2i(width / 2, -(_top - ABOVE))
	var index := {}
	for id: String in datas:
		var from: TowerData = datas[id]
		for into_res in from.evolves_to:
			var into := into_res as TowerData
			if into == null or into.texture == null:
				continue
			var name := "%s__%s" % [id, into.get_id()]
			_save(name, from, into)
			index[name] = {file = name + ".png", frames = STEPS.size()}
	var json := {fps = FPS, frame_size = [_frame.x, _frame.y], anchor = [_anchor.x, _anchor.y],
		note = "Growing into the next form (fireflies, 0.8 s). Hide the Warden's sprite (and its rank art) and play <from>__<into>.png in its place: hframes = frames, frame pixel `anchor` on the Warden's node origin (Sprite2D centred: offset = frame_size / 2 - anchor), z / y-sort as the sprite. The new form is whole from frame 8 (light fills it on 7); show the real sprite after the last frame. Both slabs and bodies are in the sheet.",
		grows = index}
	var f := FileAccess.open(OUT + "grow.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(json, "\t", true))
	f.close()
	print("grow sheets: %d, frame %s, anchor %s" % [index.size(), _frame, _anchor])
	quit()

# --- One grow -------------------------------------------------------------------------------------------------
var _targets: Array[Vector2] = []
var _ranks: Array[float] = []
var _edge: Array[Vector2] = []
var _edge_ranks: Array[float] = []
var _a0: Array[float] = []
var _r0: Array[float] = []
var _speed: Array[float] = []
var _mid := Vector2.ZERO
var _crown := Vector2.ZERO

func _save(name: String, from: TowerData, into: TowerData) -> void:
	var was: Dictionary = _part(from)
	var now: Dictionary = _part(into)
	_plan(now)
	var sheet := Image.create_empty(_frame.x * STEPS.size(), _frame.y, false, Image.FORMAT_RGBA8)
	for i in STEPS.size():
		var img := _step(STEPS[i], was, now)
		_hard_alpha(img)
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, _frame), Vector2i(i * _frame.x, 0))
	_palette.call("snap_image", sheet, false, true)  # Warden colours (the night pinks) allowed
	sheet.save_png(OUT + name + ".png")

# A form's idle frame 0 split into its slab and its body (plant sheet frames 0 / 1), and where its frame sits.
# An Ascended form has no plant sheet: all of it is body.
func _part(data: TowerData) -> Dictionary:
	var id := data.get_id()
	if _parts.has(id):
		return _parts[id]
	var size := Vector2i(data.get_frame_rect(0).size)
	var idle := data.texture.get_image()
	idle.convert(Image.FORMAT_RGBA8)
	var body := idle.get_region(Rect2i(Vector2i.ZERO, size))
	var slab := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var path := PLANT % id
	if ResourceLoader.exists(path):
		var plant := (load(path) as Texture2D).get_image()
		plant.convert(Image.FORMAT_RGBA8)
		slab = plant.get_region(Rect2i(0, 0, size.x, size.y))
		body = plant.get_region(Rect2i(size.x, 0, size.x, size.y))
	var at := Vector2i(int(-size.x / 2.0), int(data.get_sprite_offset().y - size.y / 2.0))
	_parts[id] = {slab = slab, body = body, at = at, whole = not ResourceLoader.exists(path)}
	return _parts[id]

# Long-cut step f (0..25) of the grow.
func _step(f: int, was: Dictionary, now: Dictionary) -> Image:
	var img := Image.create_empty(_frame.x, _frame.y, false, Image.FORMAT_RGBA8)
	var shown: float = minf(1.0, (f + 1) / 4.0)
	var dark: float = clampf((f - 6) / 6.0, 0.0, 1.0) if f <= 13 else 0.0
	var trace := clampf((f - TRACE_START + 1) / TRACE_FRAMES, 0.0, 1.0) if f <= 15 else 0.0
	var pool: float = [0, 0, 0, 0, 0.2, 0.35, 0.5, 0.6, 0.7, 0.8, 0.9, 1, 1, 1, 1, 1, 0.7, 0.45, 0.2, 0, 0, 0, 0, 0, 0, 0][f]
	if pool > 0.0:
		_pool(img, Vector2(0, 8), pool)
	var flies := []
	for k in FLIES:
		var fly := _fly(k, f, shown)
		if not fly.is_empty():
			flies.append(fly)
	for fly: Array in flies:
		if not fly[2]:
			_firefly(img, fly[0], fly[1] * 0.6, fly[3])
	if f <= 12:
		_layer(img, was.slab, was.at, 0.0, 0.0)
		_layer(img, was.body, was.at, dark, 0.0)
	elif f <= 13:
		_layer(img, now.slab, now.at, 0.0, 0.0)
		_layer(img, now.body, now.at, 1.0, 0.0)
	else:  # light fills the new form from its feet up
		var fill: float = [0.55, 1.0, 1.0, 1.0][mini(f - 14, 3)]
		var bright: float = [0.5, 0.35, 0.15, 0.0][mini(f - 14, 3)]
		_layer(img, now.slab, now.at, 0.0, 0.0)
		_fill(img, now.body, now.at, fill, bright)
	if trace > 0.0:
		for i in _edge.size():
			if _edge_ranks[i] <= trace:
				_blend(img, _edge[i], Color(GLOW, 0.75 if f <= 13 else 0.4))
	if f == 15:
		_banded_glow(img)
	for fly: Array in flies:
		if fly[2]:
			_firefly(img, fly[0], fly[1], fly[3])
	return img

# Firefly k at step f: [position, alpha, in front, trail points], or [] when it is not out.
func _fly(k: int, f: int, shown: float) -> Array:
	if float(k) / FLIES >= shown and f < 4:
		return []
	var land := TRACE_START + int(_ranks[k] * TRACE_FRAMES)
	var blink := 0.45 if (f + k * 3) % 7 == 0 else 1.0
	if k == 0 and f >= 16:  # the last one: up to the crown, sits, blinks twice, goes out
		if f >= 23:
			return []
		var p0 := _targets[k].lerp(_crown + Vector2(0, -2), clampf((f - 16) / 3.0, 0.0, 1.0))
		return [p0, 0.5 if f == 20 or f == 22 else 1.0, true, []]
	if f >= 16:  # lifting off and drifting up, blinking out one by one
		var k_t := float(f - 16)
		if k - int(k_t * 4.0) < 0:
			return []
		return [_targets[k] + Vector2(sin(k_t * 0.9 + k) * 2.5, -k_t * (2.0 + (k % 3))), blink, true, []]
	if f >= land:
		return [_targets[k], blink, true, []]
	var p := _orbit(k, float(f))
	var trail := [_orbit(k, f - 0.5), _orbit(k, f - 1.0)]
	if f >= land - 1:
		p = p.lerp(_targets[k], 0.6)
		trail = [p.lerp(_orbit(k, float(f)), 0.5)]
	var front := sin(_a0[k] + maxf(f - 3.0, 0.0) * _speed[k]) > 0.0
	return [p, blink, front, trail]

# Out in the dark (barely moving) to step 3, then round the Warden on a shrinking, rising ellipse.
func _orbit(k: int, f: float) -> Vector2:
	var g := maxf(f - 3.0, 0.0)
	var a := _a0[k] + g * _speed[k]
	var s := lerpf(1.0, 0.5, clampf(g / 7.0, 0.0, 1.0))
	var bob := Vector2(sin(f * 1.3 + k * 2.0), cos(f * 1.1 + k)) * 1.5
	return _mid + Vector2(cos(a) * _r0[k] * s, sin(a) * _r0[k] * 0.42 * s - g * 0.6) + bob

# The new form's outline (node coords), ranked from straight down (0) up both sides to the top (1); where each
# firefly lands; the crown; and each firefly's orbit.
func _plan(now: Dictionary) -> void:
	_targets.clear()
	_ranks.clear()
	_edge.clear()
	_edge_ranks.clear()
	_a0.clear()
	_r0.clear()
	_speed.clear()
	var body: Image = now.body
	var at: Vector2i = now.at
	var rows: int = body.get_height() - (24 if now.whole else 0)  # An Ascended form: the outline above its slab
	var top := 99999.0
	for y in rows:
		for x in body.get_width():
			if body.get_pixel(x, y).a <= 0.0:
				continue
			for n: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var q := Vector2i(x, y) + n
				if q.x < 0 or q.y < 0 or q.x >= body.get_width() or q.y >= body.get_height() or body.get_pixel(q.x, q.y).a <= 0.0:
					var p := Vector2(at) + Vector2(x, y) + Vector2(0.5, 0.5)
					_edge.append(p)
					if p.y < top:
						top = p.y
						_crown = p
					break
	var centre := Vector2.ZERO
	for p in _edge:
		centre += p
	centre /= maxf(_edge.size(), 1)
	_mid = centre
	for p in _edge:
		_edge_ranks.append(absf(angle_difference(PI / 2.0, (p - centre).angle())) / PI)
	var order: Array = range(_edge.size())
	order.sort_custom(func(i: int, j: int) -> bool: return _edge_ranks[i] < _edge_ranks[j])
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	for k in FLIES:
		var i: int = order[int((k + 0.5) * order.size() / float(FLIES))]
		_targets.append(_edge[i])
		_ranks.append(_edge_ranks[i])
		_a0.append(rng.randf() * TAU)
		_r0.append(rng.randf_range(40.0, 54.0))
		_speed.append(rng.randf_range(0.28, 0.42) * (1.0 if k % 4 else -1.0))

# --- Drawing (node coords; the frame's ANCHOR is the node origin) -------------------------------------------------
func _blend(img: Image, p: Vector2, c: Color) -> void:
	var q := Vector2i(int(floor(p.x)), int(floor(p.y))) + _anchor
	if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height():
		img.set_pixel(q.x, q.y, img.get_pixel(q.x, q.y).blend(c))

func _put(img: Image, q: Vector2i, c: Color) -> void:
	var p := q + _anchor
	if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
		img.set_pixel(p.x, p.y, c)

# A form's slab or body at its place, pulled down to the Night shadow by `dark`.
func _layer(img: Image, part: Image, at: Vector2i, dark: float, _bright: float) -> void:
	for y in part.get_height():
		for x in part.get_width():
			var c := part.get_pixel(x, y)
			if c.a > 0.0:
				_put(img, at + Vector2i(x, y), c.lerp(SHADOW, dark * 0.85) if dark > 0.0 else c)

# The body lit from its feet up to `fill` of its height (above still shadow), lifted towards Heartlight; a bright edge
# on the rising line.
func _fill(img: Image, part: Image, at: Vector2i, fill: float, bright: float) -> void:
	var top := part.get_height()
	for y in part.get_height():
		for x in part.get_width():
			if part.get_pixel(x, y).a > 0.0:
				top = mini(top, y)
	var cut := lerpf(float(part.get_height()), float(top), fill)
	for y in part.get_height():
		for x in part.get_width():
			var c := part.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			if y < cut:
				c = c.lerp(SHADOW, 0.85)
			else:
				c = c.lerp(CORE, bright + (0.3 if absf(y - cut) < 2.0 and fill < 1.0 else 0.0))
			_put(img, at + Vector2i(x, y), c)

# A firefly: a Heartlight core, Glow on its four sides, a fainter step on two diagonals, a fading trail.
func _firefly(img: Image, p: Vector2, alpha: float, trail: Array) -> void:
	for i in trail.size():
		_blend(img, trail[i], Color(GLOW, (0.5 if i == 0 else 0.25) * alpha))
	var c := Vector2(floor(p.x), floor(p.y))
	for n: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		_blend(img, c + n, Color(GLOW, 0.55 * alpha))
	for n: Vector2 in [Vector2(-1, -1), Vector2(1, 1)]:
		_blend(img, c + n, Color(GLOW, 0.25 * alpha))
	_blend(img, c, Color(CORE, alpha))

# Warm light gathering on the ground: an ellipse in two hard steps.
func _pool(img: Image, c: Vector2, strength: float) -> void:
	for y in range(int(c.y - 12), int(c.y + 13)):
		for x in range(int(c.x - 40), int(c.x + 41)):
			var d := Vector2((x + 0.5 - c.x) / 40.0, (y + 0.5 - c.y) / 12.0).length()
			if d <= 0.55:
				_blend(img, Vector2(x, y), Color(GLOW, 0.2 * strength))
			elif d <= 1.0 and (x + y) % 2 == 0:
				_blend(img, Vector2(x, y), Color(GLOW, 0.14 * strength))

# The flash as light fills the form: Glow on the clear pixels 1 px out from the forms, a checker step 2 px out
# (not along the ground under the slab).
func _banded_glow(img: Image) -> void:
	var solid := {}
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				solid[Vector2i(x, y)] = true
	var ring1 := {}
	for q: Vector2i in solid:
		for n: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if not solid.has(q + n):
				ring1[q + n] = true
	for q: Vector2i in ring1:
		if q.y - _anchor.y >= 14:
			continue
		if q.x >= 0 and q.y >= 0 and q.x < img.get_width() and q.y < img.get_height():
			img.set_pixel(q.x, q.y, img.get_pixel(q.x, q.y).blend(Color(GLOW, 0.55)))
		for n: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var r := q + n
			if not solid.has(r) and not ring1.has(r) and (r.x + r.y) % 2 == 0 and r.x >= 0 and r.y >= 0 and r.x < img.get_width() and r.y < img.get_height():
				img.set_pixel(r.x, r.y, img.get_pixel(r.x, r.y).blend(Color(GLOW, 0.3)))

# Effects' alpha steps (effect_art_generator): 0 / 0.4 / 0.75 / 1.
func _hard_alpha(img: Image) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a <= 0.0 or c.a >= 1.0:
				continue
			c.a = 0.0 if c.a < 0.15 else (0.4 if c.a < 0.55 else (0.75 if c.a < 0.88 else 1.0))
			img.set_pixel(x, y, c)
