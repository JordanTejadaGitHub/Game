extends SceneTree
# Generates the golem tower spritesheets in assets/towers/ (64x64 frames, FRAMES per row).
# Every golem is built on the original hand-drawn golem mock (POSE_UP / POSE_DOWN below): the
# mock is split into base slab and figure, recoloured per golem, then decorated in code.
# ARCHIVED: golem tower set, superseded by the Warden set in tools/tower_art_generator.gd.
# Run:  Godot --headless --path . --script res://tools/archive/golem_art_generator.gd

const S := 64
const FRAMES := 8
const OUT := "res://assets/towers/"
const PREVIEW_SCALE := 4

# Template rows start at this canvas row. Legend: o outline, a light, b mid, c shadow,
# d base left face / back edge, e base right face.
const TOP := 5
const POSE_UP := [
	"...........................oooooooo.............................",
	"..........................obaaaaaaao............................",
	".........................obbaaaaaaaao...........................",
	"........................obbaaaaaaaaaao..........................",
	".......................ocbaaaaaaaaaaaao.........................",
	"......................ocbbaaaaaaaaaaaaao........................",
	"......................ocbboaaaaaoaaaaaao........................",
	"......................ocbboaaaaaoaaaaaao........................",
	"......................ocbboaaaaaoaaaaaao........................",
	"......................ocbbaaaaaaaaaaaaaooo......................",
	".......................ocbboooooaaaaaaoaaoo.....................",
	"........................ocbbbaaaaaaaaoaaaaoo....................",
	".........................occbbaaaaaooaaaaaaoo...................",
	"........................oooooooooooaaaaaaaaao...................",
	"........................occccccbbbaaaaaaaaaaao..................",
	"......................oocbbbbbbbbaaaaaaaaaaaaao.................",
	".....................occbbbbbbbbaaaaaaaaaaaaaao.................",
	"....................ocbbbbbbbbbaaaaaaaaaaaaaaaao................",
	"...................occbbbbbbbbaaaaaaaaabaaaaaaao................",
	"...................ocbbbbbbbbbaaaaaaaaobbaaaaaao................",
	"..................occbbbbbbbbbaaaaaaaaocbbaaaaao................",
	"..................occbbbbbbbbbaaaaaaaacocbbaaaao................",
	"..................occbbbbbbbbbaaaaaaaacocbbaaaao................",
	"..................occbbbbbbbbbaaaaaaaabcocbaaaao................",
	"..................occbbbbbbbbbaaaaaaaabcocbaaaao................",
	"..................occbbbbbbbbbaaaaaaaabcocbaaaao...ooo..........",
	".................doccbbbbbbbbbaaaaaaaabcocbaaaaooooaaao.........",
	"...............ddaoccbbbbbbbbbaaaaaaaabcocbaaaaoaaaaaaao........",
	".............ddaaaoccbbbbbbbbbaaaaaaaacocbbaaaaoaaaaaaaao.......",
	"...........ooaaaaaoccbbbbbbbbbbaaaaaaacobbaaaaaoaaaaaaaaao......",
	".........doaaoaaaoocccbbbbbbbbbbaaaaaaocbaaaaaooccccbbaaao......",
	".......ddaoaaaoaobbocccbbbbbbbbbbaaaaaobaoaaaaoaaaacbbbbbo......",
	".....ddaaaocaaaocbbaocccbbbbbbboobaaaaoboaaaaooaaaaabbbbbod.....",
	"...ddaaaaoacccbocbbaaocccbbbbbobaobaaooooooaooaaaaaaabbbboadd...",
	".ddaadaaaoaaaaaocbbbaaoccbbbbocbaaoboaaaaaoaoccaaaaaabbbboaaadd.",
	"eaaaaadaoccccaaocbbbaaaoccbbbocbaaaocaaaaaaocccccaaaabbbboaaaaae",
	"eddaadaaaooooooocbbbbaaocccbbocbbaocccaaaaaaoooooooooooooaaaaeee",
	"eddddaaaaaaaaaaaocbbbaaoccccbocbboaaaccaaaaaoaaadaaaadaaaaaeeeee",
	"eddddddaaaaaaaaaaocbbbaooooooocbboaaaacbbbbboaaadaaaaadaaeeeeeee",
	"eddddddddaaaaaaaddoccbooaaadaocbboaaaaaabbaaaoaaadaaaaaeeeeeeeee",
	"eddddddddddaaaaaaaaooooaaaaaddococcaaaaaabaaaaoadaaaaeeeeeeeeeee",
	"eddedddddddddaaaaaaaaaaaadaaaaaooccccaaabbcaaaoaaaaeeeeeeeeeeeee",
	"edddeddddddddddaaaaaaaaaaadaaaaaocccccbbbbcccaoaaeeeeeeeeeeeeeee",
	"eeddeddddddddddddaaaaaadaddaaaaaaoooooooooooooaeeeeeeeeeeeeeeeee",
	"..eeddddaadddddddddaaaaadaadaaaaaaaaaaaaaaaaaeeeeeeeeeeeeeeeee..",
	"....eeaaaaaadddddddddaadaaaaaaaaaaaaaaaaaaaeeeeeeeeeeeeeeeee....",
	".....eddaaadaaddddddddeaaaaaaaaddaaaaaaaaeeeeeeeeeeeeeeeee......",
	".....eddddaadaaaddddddeddaaaaaaaadaaaaaeeeeeeeeeeeeeeeee........",
	".....edddeddaaaaaadddddedddaaaaaaaaaaeeeeeeeeeeeeeeeee..........",
	".....eedddedddaaadaaddddeddddaaaaaaeeeeeeeeeeeeeeeee............",
	".......eeddeddddaaaaaadddddddddaaeeeeeeeeeeeeeeeee..............",
	".........eedddddddaaaaaaedddddddeeeeeeeeeeeeeeee................",
	"...........eddddddddaaeeedddddddeeeeeeeeeeeeee..................",
	".............eeddddddeeeeddddeddeeeeeeeeeeee....................",
	"...............eeddddeeeedddedddeeeeeeeeee......................",
	".................eeddeeeeeddedddeeeeeeee........................",
	"...................eeee...eeddddeeeeee..........................",
	"............................eeddeeee............................",
	"..............................eeee..............................",
]
const POSE_DOWN := [
	"................................................................",
	"...........................oooooooo.............................",
	"..........................obaaaaaaao............................",
	".........................obbaaaaaaaao...........................",
	"........................obbaaaaaaaaaao..........................",
	".......................ocbaaaaaaaaaaaao.........................",
	"......................ocbbaaaaaaaaaaaaao........................",
	"......................ocbboaaaaaoaaaaaao........................",
	"......................ocbboaaaaaoaaaaaao........................",
	"......................ocbboaaaaaoaaaaaao........................",
	"......................ocbbaaaaaaaaaaaaaoo.......................",
	".......................ocbboooooaaaaaaoaoo......................",
	"........................ocbbbaaaaaaaaoaaaoo.....................",
	"........................ooccbbaaaaaooaaaaaoo....................",
	"........................ocoooooooooaaaaaaaao....................",
	"......................ooccccccccbaaaaaaaaaaao...................",
	".....................occbbbbbbbbaaaaaaaaaaaaao..................",
	"....................ocbbbbbbbbbaaaaaaaaaaaaaao..................",
	"...................occbbbbbbbbaaaaaaaaaaaaaaaao.................",
	"...................ocbbbbbbbbbaaaaaaaabaaaaaaao.................",
	"..................occbbbbbbbbbaaaaaaaobbaaaaaao.................",
	"..................occbbbbbbbbbaaaaaaaocbbaaaaao.................",
	"..................occbbbbbbbbbaaaaaaacocbbaaaao.................",
	"..................occbbbbbbbbbaaaaaaabocbbaaaao.................",
	"..................occbbbbbbbbbaaaaaaabcocbaaaao.................",
	"..................occbbbbbbbbbaaaaaaabcocbaaaao....ooo..........",
	".................doccbbbbbbbbbaaaaaaabcocbaaaao.oooaaao.........",
	"...............ddaoccbbbbbbbbbaaaaaaabcocbaaaaooaaaaaaao........",
	".............ddaaaoccbbbbbbbbbaaaaaaabcocbaaaaoaaaaaaaaao.......",
	"...........ooaaaaaoccbbbbbbbbbbaaaaaabocbbaaaaoaaaaaaaaaao......",
	".........doaaoaaaoocccbbbbbbbbbbaaaaacobbaaaaaocccccbbaaao......",
	".......ddaoaaaoaobbocccbbbbbbbbbbaaaaocbaaaaaooaaaacbbbbbo......",
	".....ddaaaocaaaocbbaocccbbbbbbboobaaaobaoaaaaoaaaaaabbbbbod.....",
	"...ddaaaaoacccbocbbaaocccbbbbbobaobaaoooooaaooaaaaaaabbbboadd...",
	".ddaadaaaoaaaaaocbbbaaoccbbbbocbaaoboaaaaaoooccaaaaaabbbboaaadd.",
	"eaaaaadaoccccaaocbbbaaaoccbbbocbaaaocaaaaaaocccccaaaabbbboaaaaae",
	"eddaadaaaooooooocbbbbaaocccbbocbbaocccaaaaaaoooooooooooooaaaaeee",
	"eddddaaaaaaaaaaaocbbbaaoccccbocbboaaaccaaaaaoaaadaaaadaaaaaeeeee",
	"eddddddaaaaaaaaaaocbbbaooooooocbboaaaacbbbbboaaadaaaaadaaeeeeeee",
	"eddddddddaaaaaaaddoccbooaaadaocbboaaaaaabbaaaoaaadaaaaaeeeeeeeee",
	"eddddddddddaaaaaaaaooooaaaaaddococcaaaaaabaaaaoadaaaaeeeeeeeeeee",
	"eddedddddddddaaaaaaaaaaaadaaaaaooccccaaabbcaaaoaaaaeeeeeeeeeeeee",
	"edddeddddddddddaaaaaaaaaaadaaaaaocccccbbbbcccaoaaeeeeeeeeeeeeeee",
	"eeddeddddddddddddaaaaaadaddaaaaaaoooooooooooooaeeeeeeeeeeeeeeeee",
	"..eeddddaadddddddddaaaaadaadaaaaaaaaaaaaaaaaaeeeeeeeeeeeeeeeee..",
	"....eeaaaaaadddddddddaadaaaaaaaaaaaaaaaaaaaeeeeeeeeeeeeeeeee....",
	".....eddaaadaaddddddddeaaaaaaaaddaaaaaaaaeeeeeeeeeeeeeeeee......",
	".....eddddaadaaaddddddeddaaaaaaaadaaaaaeeeeeeeeeeeeeeeee........",
	".....edddeddaaaaaadddddedddaaaaaaaaaaeeeeeeeeeeeeeeeee..........",
	".....eedddedddaaadaaddddeddddaaaaaaeeeeeeeeeeeeeeeee............",
	".......eeddeddddaaaaaadddddddddaaeeeeeeeeeeeeeeeee..............",
	".........eedddddddaaaaaaedddddddeeeeeeeeeeeeeeee................",
	"...........eddddddddaaeeedddddddeeeeeeeeeeeeee..................",
	".............eeddddddeeeeddddeddeeeeeeeeeeee....................",
	"...............eeddddeeeedddedddeeeeeeeeee......................",
	".................eeddeeeeeddedddeeeeeeee........................",
	"...................eeee...eeddddeeeeee..........................",
	"............................eeddeeee............................",
	"..............................eeee..............................",
]

# Idle loop: which pose each frame uses (0 = up, 1 = breathing down) and when the golem blinks.
const FRAME_POSE := [0, 0, 1, 1, 0, 0, 1, 1]
const BLINK_FRAME := 5
# Eye columns and the eye's top row in the up pose (3px tall). Mouth row is EYE_TOP + 4.
const EYES := [26, 32]
const EYE_TOP := 11

var light := Vector3(0.45, -0.55, 0.7).normalized()
var poses: Array[Dictionary] = []
var sheets: Array[Image] = []

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	poses = [_parse(POSE_UP), _parse(POSE_DOWN)]
	_make("golem", _draw_golem)
	_make("rock_golem", _draw_rock_golem)
	_make("mushroom_golem", _draw_mushroom_golem)
	_make("fire_golem", _draw_fire_golem)
	_make("ice_golem", _draw_ice_golem)
	_make("crystal_golem", _draw_crystal_golem)
	_save_preview()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "projectiles/"))
	for p: String in ["pebble", "boulder", "spore", "fireball", "ice_shard", "crystal_bolt"]:
		_make_projectile(p)
	_save_projectile_preview()
	quit()

func _make(tower_name: String, draw: Callable) -> void:
	var sheet := Image.create_empty(S * FRAMES, S, false, Image.FORMAT_RGBA8)
	for f in FRAMES:
		var canvas := _layer()
		draw.call(canvas, f)
		sheet.blit_rect(canvas, Rect2i(0, 0, S, S), Vector2i(f * S, 0))
	sheet.save_png(OUT + tower_name + ".png")
	sheets.append(sheet)

# Every sheet on grass, scaled up, for eyeballing.
func _save_preview() -> void:
	var pad := 8
	var preview := Image.create_empty(S * FRAMES + pad * (FRAMES + 1), (S + pad) * sheets.size() + pad, false, Image.FORMAT_RGBA8)
	preview.fill(Color("#5fa844"))
	for i in sheets.size():
		for f in FRAMES:
			preview.blend_rect(sheets[i], Rect2i(f * S, 0, S, S), Vector2i(pad + f * (S + pad), pad + i * (S + pad)))
	preview.resize(preview.get_width() * PREVIEW_SCALE, preview.get_height() * PREVIEW_SCALE, Image.INTERPOLATE_NEAREST)
	preview.save_png("res://tools/tower_art_preview.png")

# --- Template -----------------------------------------------------------------------------------

# Splits a template into base and figure: figure pixels are the ones enclosed by 'o' outlines,
# found by flooding in from the transparent area without crossing an outline.
func _parse(rows: Array) -> Dictionary:
	var grid: Array[String] = []
	grid.resize(S * S)
	grid.fill(".")
	for i in rows.size():
		var row: String = rows[i]
		for x in row.length():
			grid[(i + TOP) * S + x] = row[x]
	var outside := PackedByteArray()
	outside.resize(S * S)
	var stack: Array[int] = []
	for i in S * S:
		if grid[i] == ".":
			outside[i] = 1
			stack.append(i)
	while not stack.is_empty():
		var i: int = stack.pop_back()
		var x := i % S
		var y := i / S
		for n: Vector2i in [Vector2i(x + 1, y), Vector2i(x - 1, y), Vector2i(x, y + 1), Vector2i(x, y - 1)]:
			if n.x < 0 or n.y < 0 or n.x >= S or n.y >= S:
				continue
			var j := n.y * S + n.x
			if outside[j] == 0 and grid[j] != "o":
				outside[j] = 1
				stack.append(j)
	return {grid = grid, outside = outside}

func _draw_template_base(canvas: Image, pose: Dictionary, pal: Dictionary) -> void:
	for i in S * S:
		var ch: String = pose.grid[i]
		if ch != "." and pose.outside[i] == 1:
			canvas.set_pixel(i % S, i / S, pal[ch])

# Draws the figure and returns its mask (for decorations that should only land on the golem).
func _draw_template_figure(canvas: Image, pose: Dictionary, pal: Dictionary) -> Image:
	var mask := _layer()
	for i in S * S:
		var ch: String = pose.grid[i]
		if ch != "." and pose.outside[i] == 0:
			canvas.set_pixel(i % S, i / S, pal[ch])
			mask.set_pixel(i % S, i / S, Color.WHITE)
	return mask

func _blink(canvas: Image, dy: int, skin: Color, outline: Color) -> void:
	for ex: int in EYES:
		_px(canvas, ex, EYE_TOP + dy, skin)
		_px(canvas, ex, EYE_TOP + 2 + dy, skin)
		_px(canvas, ex + 1, EYE_TOP + 1 + dy, outline)

# --- Primitives -------------------------------------------------------------------------------

func _layer() -> Image:
	return Image.create_empty(S, S, false, Image.FORMAT_RGBA8)

func _ramp(hexes: Array) -> Array[Color]:
	var out: Array[Color] = []
	for h in hexes:
		out.append(Color(h))
	return out

# Banded lighting: ramp is [shadow, mid, light, (highlight)].
func _shade(ramp: Array[Color], n: Vector3) -> Color:
	var i := n.dot(light)
	if i < 0.2:
		return ramp[0]
	if i < 0.55:
		return ramp[1]
	if i < 0.9 or ramp.size() < 4:
		return ramp[2]
	return ramp[3]

func _ellipse(layer: Image, c: Vector2, r: Vector2, ramp: Array[Color], max_y: float = INF) -> void:
	for y in S:
		for x in S:
			var p := Vector2(x + 0.5, y + 0.5)
			if p.y > max_y:
				continue
			var d := (p - c) / r
			var q := d.length_squared()
			if q <= 1.0:
				layer.set_pixel(x, y, _shade(ramp, Vector3(d.x, d.y, sqrt(1.0 - q))))

func _flat_ellipse(layer: Image, c: Vector2, r: Vector2, color: Color) -> void:
	for y in S:
		for x in S:
			if ((Vector2(x + 0.5, y + 0.5) - c) / r).length_squared() <= 1.0:
				layer.set_pixel(x, y, color)

# Faceted stone: pixels are grouped into wedges around the centre, each wedge lit as a flat face.
func _rock(canvas: Image, pts: PackedVector2Array, ramp: Array[Color], outline: Color) -> void:
	var centre := Vector2.ZERO
	for p in pts:
		centre += p
	centre /= pts.size()
	var layer := _layer()
	for y in S:
		for x in S:
			var p := Vector2(x + 0.5, y + 0.5)
			if not Geometry2D.is_point_in_polygon(p, pts):
				continue
			var d := p - centre
			var n := Vector3(0, -0.3, 1)
			if d.length() > 2.0:
				var a := snappedf(d.angle(), TAU / 6.0)
				n = Vector3(cos(a), sin(a), 0.8)
			layer.set_pixel(x, y, _shade(ramp, n.normalized()))
	_stamp(canvas, layer, outline)

func _line(canvas: Image, pts: Array, color: Color, mask: Image = null) -> void:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
		for s in steps + 1:
			var p := a.lerp(b, s / maxf(steps, 1.0)).round()
			if mask == null or mask.get_pixel(int(p.x), int(p.y)).a > 0.0:
				_px(canvas, int(p.x), int(p.y), color)

func _px(canvas: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < S and y < S:
		canvas.set_pixel(x, y, color)

# Copies a layer onto the canvas, turning the layer's own border pixels into an outline.
func _stamp(canvas: Image, layer: Image, outline: Color = Color(0, 0, 0, 0)) -> void:
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for y in S:
		for x in S:
			var col := layer.get_pixel(x, y)
			if col.a == 0.0:
				continue
			if outline.a > 0.0:
				for d: Vector2i in dirs:
					var p: Vector2i = Vector2i(x, y) + d
					if p.x < 0 or p.y < 0 or p.x >= S or p.y >= S or layer.get_pixelv(p).a == 0.0:
						col = outline
						break
			canvas.set_pixel(x, y, col)

func _pal(o: String, a: String, b: String, c: String) -> Dictionary:
	return {o = Color(o), a = Color(a), b = Color(b), c = Color(c)}

func _base_pal(a: String, d: String, e: String) -> Dictionary:
	return {a = Color(a), d = Color(d), e = Color(e), o = Color(e)}

# --- Golems -----------------------------------------------------------------------------------

# The original design, unchanged apart from the breathing loop and a blink.
func _draw_golem(canvas: Image, f: int) -> void:
	var pose: Dictionary = poses[FRAME_POSE[f]]
	var fig := _pal("#17174d", "#ed9df2", "#de73e5", "#ba41d9")
	_draw_template_base(canvas, pose, _base_pal("#ed9df2", "#6c29a6", "#281d73"))
	_draw_template_figure(canvas, pose, fig)
	if f == BLINK_FRAME:
		_blink(canvas, FRAME_POSE[f], fig.a, fig.o)

# Grey stone golem: jagged boulders on the shoulders and back, cracks, moss, glowing eyes and a
# rune crack on the chest that pulses.
func _draw_rock_golem(canvas: Image, f: int) -> void:
	var dy: int = FRAME_POSE[f]
	var pose: Dictionary = poses[dy]
	var o := Color("#1c1c36")
	var fig := _pal("#1c1c36", "#c4c9e2", "#979dc2", "#686d9a")
	var stone := _ramp(["#686d9a", "#979dc2", "#c4c9e2", "#e4e7f4"])
	var moss := Color("#6cb04e")
	var glow_on := f % 4 == 1 or f % 4 == 2
	var glow := Color("#9ff4ff") if glow_on else Color("#5cc8e8")
	_draw_template_base(canvas, pose, _base_pal("#8a8fb4", "#4c507c", "#242444"))
	var mask := _draw_template_figure(canvas, pose, fig)
	# Cracks on the head and body.
	_line(canvas, [Vector2(24, 7 + dy), Vector2(25, 9 + dy), Vector2(24, 10 + dy)], fig.c, mask)
	_line(canvas, [Vector2(36, 8 + dy), Vector2(35, 10 + dy)], fig.c, mask)
	_line(canvas, [Vector2(21, 30), Vector2(23, 33), Vector2(22, 35)], fig.o, mask)
	_line(canvas, [Vector2(34, 36), Vector2(35, 39)], fig.c, mask)
	# Chest rune crack.
	_line(canvas, [Vector2(29, 25 + dy), Vector2(31, 27 + dy), Vector2(29, 29 + dy), Vector2(31, 31 + dy)], glow, mask)
	# Boulder pauldrons on both shoulders.
	_rock(canvas, PackedVector2Array([Vector2(14, 25 + dy), Vector2(16, 19 + dy), Vector2(22, 17 + dy),
		Vector2(27, 20 + dy), Vector2(25, 26 + dy), Vector2(18, 28 + dy)]), stone, o)
	_rock(canvas, PackedVector2Array([Vector2(37, 20 + dy), Vector2(41, 15 + dy), Vector2(47, 16 + dy),
		Vector2(50, 21 + dy), Vector2(47, 26 + dy), Vector2(40, 25 + dy)]), stone, o)
	# Moss on the head, shoulder and legs.
	for m: Vector2i in [Vector2i(28, 6), Vector2i(29, 6), Vector2i(30, 6), Vector2i(29, 7),
			Vector2i(20, 18), Vector2i(21, 18), Vector2i(22, 18)]:
		_px(canvas, m.x, m.y + dy, moss)
	for m: Vector2i in [Vector2i(12, 37), Vector2i(13, 37), Vector2i(50, 34), Vector2i(51, 34), Vector2i(52, 34)]:
		_px(canvas, m.x, m.y, moss)
	_glow_eyes(canvas, f, dy, glow, fig)

# Mushroom golem: a spotted cap for a head, small mushrooms sprouting from the shoulder and the
# slab, freckled stalk-coloured body, and spores drifting up.
func _draw_mushroom_golem(canvas: Image, f: int) -> void:
	var dy: int = FRAME_POSE[f]
	var pose: Dictionary = poses[dy]
	var o := Color("#2a1a2e")
	var fig := _pal("#2a1a2e", "#f4e6c8", "#dcc39c", "#b0906c")
	var cap := _ramp(["#8c2448", "#c8385a", "#ec6a80", "#ffa4b0"])
	var spot := Color("#fff1e0")
	var gill := Color("#d8b8a4")
	_draw_template_base(canvas, pose, _base_pal("#8ccf6e", "#3f8a4c", "#1f4a44"))
	# Little mushrooms on the slab.
	_mini_mushroom(canvas, Vector2(7, 43), 3.0, cap, fig, o)
	var mask := _draw_template_figure(canvas, pose, fig)
	_mini_mushroom(canvas, Vector2(52, 46), 3.5, cap, fig, o)
	# Freckles on the body.
	for s: Vector2i in [Vector2i(33, 22), Vector2i(36, 25), Vector2i(34, 29), Vector2i(26, 27), Vector2i(23, 33),
			Vector2i(40, 23), Vector2i(29, 36)]:
		if mask.get_pixel(s.x, s.y + dy).a > 0.0:
			_px(canvas, s.x, s.y + dy, fig.c)
	# Cap: gills first so their bottom row peeks out under the dome.
	var gills := _layer()
	_flat_ellipse(gills, Vector2(30.5, 10.0 + dy), Vector2(14, 1.6), gill)
	_stamp(canvas, gills, o)
	var dome := _layer()
	_ellipse(dome, Vector2(30.5, 10.0 + dy), Vector2(16, 10), cap, 10.0 + dy)
	_stamp(canvas, dome, o)
	var spots := _layer()
	for s: Vector3 in [Vector3(23, 6, 2.2), Vector3(31, 3, 2.0), Vector3(38, 7, 1.8), Vector3(29, 8, 1.2), Vector3(18, 9, 1.0)]:
		_flat_ellipse(spots, Vector2(s.x, s.y + dy), Vector2(s.z, s.z * 0.8), spot)
	_stamp(canvas, spots)
	# A mushroom sprouting from the right shoulder.
	_mini_mushroom(canvas, Vector2(43, 19 + dy), 3.5, cap, fig, o)
	# Spores drifting up and fading out.
	for k in 3:
		var t := float((f + k * 3) % FRAMES) / FRAMES
		var x: int = [14, 47, 40][k] + roundi(sin(t * TAU) * 1.5)
		var y := roundi(18 - t * 16)
		_px(canvas, x, y, Color("#d8f4a8") if t < 0.6 else Color("#a8d888"))

# Fire golem: charcoal basalt body split by glowing lava cracks, a crown of fire on its head,
# yellow eyes, lava seams in the slab and embers rising.
func _draw_fire_golem(canvas: Image, f: int) -> void:
	var dy: int = FRAME_POSE[f]
	var pose: Dictionary = poses[dy]
	var o := Color("#1a0e1e")
	var fig := _pal("#1a0e1e", "#6e5e74", "#524460", "#3a2e48")
	var glow_on := f % 4 == 1 or f % 4 == 2
	var lava := Color("#ffb03c") if glow_on else Color("#f0702c")
	var lava_core := Color("#fff0a0") if glow_on else Color("#ffc850")
	_draw_template_base(canvas, pose, _base_pal("#6e5a6a", "#3e2a3e", "#1e1024"))
	var top := _base_top_mask(pose)
	_line(canvas, [Vector2(47, 44), Vector2(50, 46), Vector2(54, 45)], lava, top)
	_line(canvas, [Vector2(5, 41), Vector2(8, 43)], lava, top)
	_line(canvas, [Vector2(20, 49), Vector2(24, 51), Vector2(27, 50)], lava, top)
	var mask := _draw_template_figure(canvas, pose, fig)
	# The top of the head is a crown of fire, ending just above the eyes.
	var sway: int = [0, 1, 0, -1][f % 4]
	var lick: float = [0.0, 1.0, 2.0, 1.0][f % 4]
	var flames := [[Color("#d8362c"), 7.5, 10.0], [Color("#f78a2c"), 5.5, 8.0], [Color("#ffd24a"), 3.5, 5.0]]
	for i in flames.size():
		var spec: Array = flames[i]
		var layer := _layer()
		_flame(layer, Vector2(30.5, 11 + dy), spec[1], spec[2] + lick * 0.5, sway, spec[0])
		_flame(layer, Vector2(25, 12 + dy), spec[1] * 0.6, spec[2] * 0.7 + 1.0 - lick * 0.5, -sway, spec[0])
		_flame(layer, Vector2(36, 12 + dy), spec[1] * 0.6, spec[2] * 0.7 + lick * 0.5, sway, spec[0])
		layer.fill_rect(Rect2i(0, 10 + dy, S, S), Color(0, 0, 0, 0))
		_stamp(canvas, layer, Color("#6a1420") if i == 0 else Color(0, 0, 0, 0))
	# Lava cracks across the head, chest, arm and legs.
	for crack: Array in [
			[Vector2(24, 8 + dy), Vector2(25, 10 + dy)],
			[Vector2(27, 21 + dy), Vector2(29, 24 + dy), Vector2(28, 27 + dy), Vector2(30, 30 + dy)],
			[Vector2(22, 26), Vector2(24, 29), Vector2(23, 32)],
			[Vector2(42, 28), Vector2(43, 31)],
			[Vector2(18, 40), Vector2(20, 42)],
			[Vector2(38, 43), Vector2(41, 44)]]:
		_line(canvas, crack, lava, mask)
	_line(canvas, [Vector2(28, 24 + dy), Vector2(28, 26 + dy)], lava_core, mask)
	_glow_eyes(canvas, f, dy, Color("#ffe066"), fig)
	# Embers drifting up.
	for k in 3:
		var t := float((f + k * 3) % FRAMES) / FRAMES
		var x: int = [21, 42, 33][k] + roundi(sin(t * TAU) * 1.5)
		_px(canvas, x, roundi(20 - t * 18), Color("#ffd24a") if t < 0.5 else Color("#f0702c"))

# Ice golem: frosty white-blue body with snow on the head and shoulders, ice crystals growing
# out of its back and the slab, pale glowing eyes and snowflakes drifting down.
func _draw_ice_golem(canvas: Image, f: int) -> void:
	var dy: int = FRAME_POSE[f]
	var pose: Dictionary = poses[dy]
	var o := Color("#142048")
	var fig := _pal("#142048", "#d2ecfc", "#a4cdef", "#7aa4d8")
	var ice := _ramp(["#3f7fcf", "#6fc6ee", "#b4f0ff", "#ffffff"])
	var snow := Color("#ffffff")
	_draw_template_base(canvas, pose, _base_pal("#a8d0ee", "#4a78bc", "#22306e"))
	var top := _base_top_mask(pose)
	for s: Vector2i in [Vector2i(6, 42), Vector2i(7, 42), Vector2i(12, 46), Vector2i(48, 47), Vector2i(49, 47),
			Vector2i(55, 43), Vector2i(26, 52), Vector2i(27, 52), Vector2i(38, 52)]:
		if top.get_pixel(s.x, s.y).a > 0.0:
			_px(canvas, s.x, s.y, snow)
	# Ice crystals growing out of the back.
	_crystal(canvas, 44, 27 + dy, 3, 8, 5, 1.5, 0.45, ice, o)
	_crystal(canvas, 39, 22 + dy, 2.5, 6, 4, 1.0, 0.15, ice, o)
	_crystal(canvas, 17, 28 + dy, 3, 7, 4, 1.5, -0.45, ice, o)
	var mask := _draw_template_figure(canvas, pose, fig)
	# Snow caps on the head and shoulders, frost streaks on the body.
	for y in range(6, 9):
		for x in range(22, 41):
			var sy := y + dy + (1 if x < 25 or x > 37 else 0)
			if mask.get_pixel(x, sy).a > 0.0 and canvas.get_pixel(x, sy) != fig.o:
				_px(canvas, x, sy, snow if y < 8 else fig.a)
	for s: Vector2i in [Vector2i(22, 20), Vector2i(23, 20), Vector2i(24, 20), Vector2i(23, 21), Vector2i(41, 22), Vector2i(42, 22)]:
		if mask.get_pixel(s.x, s.y + dy).a > 0.0 and canvas.get_pixel(s.x, s.y + dy) != fig.o:
			_px(canvas, s.x, s.y + dy, snow)
	_line(canvas, [Vector2(33, 23 + dy), Vector2(34, 26 + dy)], fig.c, mask)
	_line(canvas, [Vector2(20, 33), Vector2(21, 36)], fig.c, mask)
	# Crystals on the slab, in front of the figure.
	_crystal(canvas, 9, 45, 2.5, 5, 3, 1.0, -0.3, ice, o)
	_crystal(canvas, 54, 44, 2.5, 6, 3, 1.0, 0.3, ice, o)
	_glow_eyes(canvas, f, dy, Color("#6fe0ff"), fig)
	# Snowflakes drifting down.
	for k in 3:
		var t := float((f + k * 3) % FRAMES) / FRAMES
		var x: int = [16, 46, 38][k] + roundi(sin(t * TAU) * 1.5)
		var y := roundi(2 + t * 18)
		_px(canvas, x, y, snow)
		if k == 0:
			for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				_px(canvas, x + d.x, y + d.y, Color("#b4f0ff"))

# Crystal golem (long range): teal stone body with emerald crystals growing from its back, a
# crystal horn that works as a focusing lens, and a gem in its chest that pulses.
func _draw_crystal_golem(canvas: Image, f: int) -> void:
	var dy: int = FRAME_POSE[f]
	var pose: Dictionary = poses[dy]
	var o := Color("#0e1a26")
	var fig := _pal("#0e1a26", "#8fb0b4", "#6a8e96", "#4a6a78")
	var gem := _ramp(["#1a7a6a", "#34c49e", "#8ef4d4", "#ffffff"])
	var glow_on := f % 4 == 1 or f % 4 == 2
	_draw_template_base(canvas, pose, _base_pal("#7fa0a6", "#3e5c6a", "#1a2c3a"))
	# Crystal cluster on the back.
	_crystal(canvas, 42, 27 + dy, 3.5, 12, 6, 1.5, 0.3, gem, o)
	_crystal(canvas, 47, 29 + dy, 2.5, 7, 4, 1.0, 0.55, gem, o)
	_crystal(canvas, 18, 27 + dy, 3, 9, 5, 1.5, -0.4, gem, o)
	var mask := _draw_template_figure(canvas, pose, fig)
	_line(canvas, [Vector2(21, 31), Vector2(23, 34)], fig.c, mask)
	_line(canvas, [Vector2(35, 35), Vector2(36, 38)], fig.c, mask)
	# Horn crystal on the head.
	_crystal(canvas, 30.5, 8 + dy, 2.5, 3, 5, 1.0, 0.0, gem, o)
	# Chest gem.
	var chest := _layer()
	_flat_polygon(chest, PackedVector2Array([Vector2(30, 23 + dy), Vector2(34, 27 + dy), Vector2(30, 31 + dy), Vector2(26, 27 + dy)]),
		gem[2] if glow_on else gem[1])
	_stamp(canvas, chest, o)
	_px(canvas, 29, 26 + dy, Color.WHITE if glow_on else gem[2])
	# Small crystals on the slab.
	_crystal(canvas, 8, 45, 2, 4, 3, 1.0, -0.3, gem, o)
	_crystal(canvas, 55, 44, 2.5, 5, 3, 1.0, 0.25, gem, o)
	_glow_eyes(canvas, f, dy, Color("#8ef4d4"), fig)
	# A sparkle travelling over the crystals.
	var sparkle: Vector2i = [Vector2i(44, 12), Vector2i(-1, -1), Vector2i(19, 17), Vector2i(-1, -1),
		Vector2i(31, 1), Vector2i(-1, -1), Vector2i(49, 20), Vector2i(-1, -1)][f]
	if sparkle.x >= 0:
		for d: Vector2i in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			_px(canvas, sparkle.x + d.x, sparkle.y + d.y + dy, Color.WHITE)

func _glow_eyes(canvas: Image, f: int, dy: int, glow: Color, fig: Dictionary) -> void:
	for ex: int in EYES:
		for k in 3:
			var closed := f == BLINK_FRAME and k != 1
			_px(canvas, ex, EYE_TOP + k + dy, fig.a if closed else glow)
		if f == BLINK_FRAME:
			_px(canvas, ex, EYE_TOP + 1 + dy, fig.o)

# Top face of the slab (light base pixels), for details that should stay on the slab.
func _base_top_mask(pose: Dictionary) -> Image:
	var mask := _layer()
	for i in S * S:
		if pose.grid[i] == "a" and pose.outside[i] == 1:
			mask.set_pixel(i % S, i / S, Color.WHITE)
	return mask

# --- Projectiles ------------------------------------------------------------------------------
# 16x16 frames, 4 per sheet, drawn pointing right (+x) so the game can rotate them to face travel.

const P := 16
const P_FRAMES := 4
var projectile_sheets: Array[Image] = []

func _make_projectile(proj_name: String) -> void:
	var sheet := Image.create_empty(P * P_FRAMES, P, false, Image.FORMAT_RGBA8)
	for f in P_FRAMES:
		var canvas := _layer()
		call("_proj_" + proj_name, canvas, f)
		sheet.blit_rect(canvas, Rect2i(24, 24, P, P), Vector2i(f * P, 0))
	sheet.save_png(OUT + "projectiles/" + proj_name + ".png")
	projectile_sheets.append(sheet)

func _save_projectile_preview() -> void:
	var pad := 4
	var preview := Image.create_empty(P * P_FRAMES + pad * (P_FRAMES + 1), (P + pad) * projectile_sheets.size() + pad, false, Image.FORMAT_RGBA8)
	preview.fill(Color("#5fa844"))
	for i in projectile_sheets.size():
		for f in P_FRAMES:
			preview.blend_rect(projectile_sheets[i], Rect2i(f * P, 0, P, P), Vector2i(pad + f * (P + pad), pad + i * (P + pad)))
	preview.resize(preview.get_width() * 8, preview.get_height() * 8, Image.INTERPOLATE_NEAREST)
	preview.save_png("res://tools/projectile_preview.png")

# A spinning faceted stone: an irregular polygon rotated a quarter turn per frame.
func _spinning_rock(canvas: Image, f: int, r: float, ramp: Array[Color], o: Color) -> void:
	var pts := PackedVector2Array()
	var radii := [1.0, 0.8, 0.95, 0.75, 1.0, 0.85]
	for k in 6:
		var a := k * TAU / 6.0 + f * TAU / 24.0
		pts.append(Vector2(32, 32) + Vector2.from_angle(a) * r * radii[k])
	_rock(canvas, pts, ramp, o)

func _proj_pebble(canvas: Image, f: int) -> void:
	_spinning_rock(canvas, f, 4.5, _ramp(["#ba41d9", "#de73e5", "#ed9df2", "#f7c8fa"]), Color("#17174d"))

func _proj_boulder(canvas: Image, f: int) -> void:
	_spinning_rock(canvas, f, 7.0, _ramp(["#686d9a", "#979dc2", "#c4c9e2", "#e4e7f4"]), Color("#1c1c36"))
	_px(canvas, 30, 29, Color("#6cb04e"))
	_px(canvas, 31, 29, Color("#6cb04e"))

func _proj_spore(canvas: Image, f: int) -> void:
	var puff := _ramp(["#6a9a3c", "#a8d468", "#d8f4a8", "#ffffff"])
	var grow: float = [0.0, 0.5, 1.0, 0.5][f]
	var layer := _layer()
	_ellipse(layer, Vector2(33, 32), Vector2(4 + grow, 4 + grow), puff)
	_ellipse(layer, Vector2(28, 33), Vector2(2.5 + grow * 0.5, 2.5 + grow * 0.5), puff)
	_ellipse(layer, Vector2(31, 28), Vector2(2.5, 2.5), puff)
	_stamp(canvas, layer, Color("#2a3a1a"))
	# Trailing spore dots.
	_px(canvas, 25 - f % 2, 30 + f % 2, Color("#d8f4a8"))
	_px(canvas, 26, 35 - f % 2, Color("#a8d468"))

func _proj_fireball(canvas: Image, f: int) -> void:
	var flick: float = [0.0, 0.7, 0.3, 1.0][f]
	var specs := [[Color("#d8362c"), 5.5], [Color("#f78a2c"), 4.0], [Color("#ffd24a"), 2.6], [Color("#fff6c8"), 1.3]]
	for i in specs.size():
		var spec: Array = specs[i]
		var layer := _layer()
		var r: float = spec[1] + (flick if i < 2 else 0.0) * 0.5
		# Ball at the front, flame trail streaming back to the left.
		for step in 8:
			var t := step / 7.0
			var rr := r * (1.0 - t * 0.85)
			var wob := sin((t * 3.0 + f * 0.5) * PI) * t * 1.5
			if rr >= 0.5:
				_flat_ellipse(layer, Vector2(34 - t * r * 2.2, 32 + wob), Vector2(rr, rr), spec[0])
		_stamp(canvas, layer, Color("#6a1420") if i == 0 else Color(0, 0, 0, 0))

func _proj_ice_shard(canvas: Image, f: int) -> void:
	var o := Color("#142048")
	var ice := _ramp(["#3f7fcf", "#6fc6ee", "#b4f0ff", "#ffffff"])
	var layer := _layer()
	var pts := PackedVector2Array([Vector2(41, 32), Vector2(34, 28), Vector2(24, 29), Vector2(27, 32), Vector2(24, 35), Vector2(34, 36)])
	for y in S:
		for x in S:
			var p := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(p, pts):
				layer.set_pixel(x, y, ice[2] if p.y < 32 else ice[1])
	_stamp(canvas, layer, o)
	# Glint sliding along the shard.
	var gx: int = [28, 31, 34, 37][f]
	_px(canvas, gx, 31, ice[3])
	_px(canvas, gx - 1, 31, ice[2])
	# Frost trail.
	_px(canvas, 22 - f % 2, 31, ice[2])
	_px(canvas, 20, 33 + f % 2, ice[1])

func _proj_crystal_bolt(canvas: Image, f: int) -> void:
	var o := Color("#0e1a26")
	var gem := _ramp(["#1a7a6a", "#34c49e", "#8ef4d4", "#ffffff"])
	# Long thin diamond with a bright core and a fading streak behind it.
	var layer := _layer()
	_flat_polygon(layer, PackedVector2Array([Vector2(41, 32), Vector2(34, 29), Vector2(27, 32), Vector2(34, 35)]), gem[1])
	_stamp(canvas, layer, o)
	var core := _layer()
	_flat_polygon(core, PackedVector2Array([Vector2(39, 32), Vector2(34, 30.5), Vector2(30, 32), Vector2(34, 33.5)]),
		gem[3] if f % 2 == 0 else gem[2])
	_stamp(canvas, core)
	for x in range(22, 27):
		_px(canvas, x, 31 + (x + f) % 2, gem[2] if x > 24 else gem[1])
	var sp: Vector2i = [Vector2i(35, 27), Vector2i(31, 36), Vector2i(38, 29), Vector2i(29, 28)][f]
	_px(canvas, sp.x, sp.y, Color.WHITE)

# Teardrop flame built from a column of shrinking circles; the upper part bends with sway.
func _flame(layer: Image, base: Vector2, r: float, height: float, sway: float, color: Color) -> void:
	for step in 25:
		var t := step / 24.0
		var c := base + Vector2(sway * 3.0 * t * t, -height * t)
		var rr := r * pow(1.0 - t, 1.5)
		if rr >= 0.5:
			_flat_ellipse(layer, c, Vector2(rr, rr), color)

func _flat_polygon(layer: Image, pts: PackedVector2Array, color: Color) -> void:
	for y in S:
		for x in S:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				layer.set_pixel(x, y, color)

# Faceted prism: shadow / mid / light facets, pointed top, optional pointed bottom and lean.
func _crystal(canvas: Image, cx: float, by: float, w: float, h: float, tip: float, bottom: float,
		slant: float, ramp: Array[Color], outline: Color) -> void:
	var raw := [Vector2(cx - w, by), Vector2(cx - w, by - h), Vector2(cx, by - h - tip),
		Vector2(cx + w, by - h), Vector2(cx + w, by), Vector2(cx, by + bottom)]
	var pts := PackedVector2Array()
	for v: Vector2 in raw:
		pts.append(Vector2(v.x + (by - v.y) * slant, v.y))
	var layer := _layer()
	for y in S:
		for x in S:
			var p := Vector2(x + 0.5, y + 0.5)
			if not Geometry2D.is_point_in_polygon(p, pts):
				continue
			var xs := p.x - (by - p.y) * slant
			var facet := 0 if xs < cx - w / 3.0 else (1 if xs < cx + w / 3.0 else 2)
			if p.y < by - h:
				facet = mini(facet + 1, ramp.size() - 1)
			if absf(xs - (cx + w / 3.0)) < 0.6 and p.y < by - 1:
				facet = ramp.size() - 1
			layer.set_pixel(x, y, ramp[facet])
	_stamp(canvas, layer, outline)

func _mini_mushroom(canvas: Image, top: Vector2, r: float, cap: Array[Color], fig: Dictionary, o: Color) -> void:
	var stalk := _layer()
	for y in range(int(top.y), int(top.y + 4)):
		for x in range(int(top.x - 1), int(top.x + 2)):
			stalk.set_pixel(x, y, fig.b)
	_stamp(canvas, stalk, o)
	var head := _layer()
	_ellipse(head, top, Vector2(r, r * 0.8), cap, top.y + 0.5)
	_stamp(canvas, head, o)
	_px(canvas, int(top.x) - 1, int(top.y - r * 0.4), Color("#fff1e0"))
