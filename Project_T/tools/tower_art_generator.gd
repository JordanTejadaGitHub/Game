extends SceneTree
# Generates the Warden (tower) spritesheets in assets/towers/ (64x64 frames, FRAMES per row) and
# their projectiles in assets/towers/projectiles/ (16x16 frames). Wardens are listed in
# documentation/game_design.md. They all doze on the mossy waystone from the original concept
# mock (POSE_UP / POSE_DOWN below); the Sporeling is the mock's figure itself.
# Run:  Godot --headless --path . --script res://tools/tower_art_generator.gd
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
	for warden: String in ["sprout", "thornwall", "sporeling", "pebbling", "dewdrop", "firefly_jar", "rootling", "acorn"]:
		_make(warden, Callable(self, "_draw_" + warden))
	_save_preview()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "projectiles/"))
	for p: String in ["spore", "pebble", "dew_drop", "spark"]:
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
	for y in range(maxi(0, floori(c.y - r.y)), mini(S, ceili(c.y + r.y) + 1)):
		for x in range(maxi(0, floori(c.x - r.x)), mini(S, ceili(c.x + r.x) + 1)):
			var p := Vector2(x + 0.5, y + 0.5)
			if p.y > max_y:
				continue
			var d := (p - c) / r
			var q := d.length_squared()
			if q <= 1.0:
				layer.set_pixel(x, y, _shade(ramp, Vector3(d.x, d.y, sqrt(1.0 - q))))

func _flat_ellipse(layer: Image, c: Vector2, r: Vector2, color: Color) -> void:
	for y in range(maxi(0, floori(c.y - r.y)), mini(S, ceili(c.y + r.y) + 1)):
		for x in range(maxi(0, floori(c.x - r.x)), mini(S, ceili(c.x + r.x) + 1)):
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


func _flat_polygon(layer: Image, pts: PackedVector2Array, color: Color) -> void:
	for y in S:
		for x in S:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				layer.set_pixel(x, y, color)

# Faceted prism: shadow / mid / light facets, pointed top, optional pointed bottom and lean.

# --- Waystone & faces -------------------------------------------------------------------------

const BLUSH := Color("#f49aa8")

# The mossy waystone every Warden dozes on: the mock's slab recoloured, with the gap where the
# mock's figure stood filled back in, and moss over the top. Returns the slab's top-face mask.
func _draw_waystone(canvas: Image, pose: Dictionary) -> Image:
	var stone := {a = Color("#aaa4bc"), d = Color("#6a6484"), e = Color("#34304c")}
	var top := _layer()
	for i in S * S:
		var ch: String = pose.grid[i]
		if ch == ".":
			continue
		var x := i % S
		var y := i / S
		if pose.outside[i] == 1:
			canvas.set_pixel(x, y, stone[ch])
			if ch == "a":
				top.set_pixel(x, y, Color.WHITE)
			continue
		# Under the figure: the top face, bounded by the slab's back edges (2:1 slopes).
		var xl := 2 * (40 - y) - 1
		var xr := 64 - 2 * (40 - y) + 1
		if y > 40 or (x > xl + 1 and x < xr - 1):
			canvas.set_pixel(x, y, stone.a)
			top.set_pixel(x, y, Color.WHITE)
		elif x >= xl and x <= xr:
			canvas.set_pixel(x, y, stone.d)
	for c: Vector2i in [Vector2i(28, 34), Vector2i(29, 34), Vector2i(36, 30), Vector2i(40, 45), Vector2i(41, 45), Vector2i(24, 44)]:
		_px(canvas, c.x, c.y, stone.d)
	# Moss patches: lighter towards the top, dithered at the edges.
	var moss := _ramp(["#3f7a3e", "#5a9a48", "#7cbc5a"])
	for blob: Rect2 in [Rect2(11, 40, 9, 3.5), Rect2(51, 41, 8, 3), Rect2(30, 51, 10, 3), Rect2(42, 30, 6, 2.5),
			Rect2(21, 31, 5, 2)]:
		for y in S:
			for x in S:
				if top.get_pixel(x, y).a == 0.0:
					continue
				var d := (Vector2(x + 0.5, y + 0.5) - blob.position) / blob.size
				var q := d.length()
				if q > 1.0 or (q > 0.8 and (x + y) % 2 == 0):
					continue
				canvas.set_pixel(x, y, moss[2] if (q < 0.5 and d.y < 0.0) else (moss[0] if q > 0.8 else moss[1]))
	return top

# Mock-style face: 3px tall eyes six apart, a small mouth, rosy cheeks. Closed eyes on blink.
func _face(canvas: Image, cx: int, eye_y: int, o: Color, blink: bool, mouth: int = 3, blush: bool = true) -> void:
	var eyes := [cx - 3, cx + 3]
	for i in 2:
		var ex: int = eyes[i]
		if blink:
			_px(canvas, ex, eye_y + 1, o)
			_px(canvas, ex + (-1 if i == 0 else 1), eye_y + 1, o)
		else:
			for k in 3:
				_px(canvas, ex, eye_y + k, o)
	for k in mouth:
		_px(canvas, cx - mouth / 2 + k, eye_y + 4, o)
	if blush:
		for bx: int in [cx - 6, cx - 5, cx + 5, cx + 6]:
			_px(canvas, bx, eye_y + 3, BLUSH)

# Lens-shaped leaf from base to tip: one half lit, the other shaded, with a dark midrib.
func _leaf(canvas: Image, base: Vector2, tip: Vector2, width: float, ramp: Array[Color], o: Color) -> void:
	var layer := _layer()
	var axis := tip - base
	var length := axis.length()
	var dir := axis / length
	var nrm := Vector2(-dir.y, dir.x)
	for y in S:
		for x in S:
			var p := Vector2(x + 0.5, y + 0.5) - base
			var t := p.dot(dir) / length
			if t < 0.0 or t > 1.0:
				continue
			var s := p.dot(nrm)
			if absf(s) > width * sin(t * PI):
				continue
			var col: Color = ramp[2] if s < 0.0 else ramp[1]
			if absf(s) < 0.6 and t > 0.15 and t < 0.8:
				col = ramp[0]
			layer.set_pixel(x, y, col)
	_stamp(canvas, layer, o)

# Thick line of round dabs, for stems, roots and arms.
func _stroke(layer: Image, pts: Array, r: float, color: Color) -> void:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var steps := int(ceilf(a.distance_to(b) * 2.0))
		for s in steps + 1:
			_flat_ellipse(layer, a.lerp(b, s / maxf(steps, 1.0)), Vector2(r, r), color)

# A body that "breathes": on the down pose it squashes 1px while its bottom stays planted.
func _breathing_body(canvas: Image, bottom: Vector2, r: Vector2, dy: int, ramp: Array[Color], o: Color) -> Image:
	var rr := r + Vector2(0.5, -0.5) * dy
	var layer := _layer()
	_ellipse(layer, Vector2(bottom.x, bottom.y - rr.y), rr, ramp)
	_stamp(canvas, layer, o)
	return layer

func _mask_px(canvas: Image, mask: Image, pts: Array, color: Color) -> void:
	for p: Vector2i in pts:
		if p.x >= 0 and p.y >= 0 and p.x < S and p.y < S and mask.get_pixelv(p).a > 0.0:
			canvas.set_pixelv(p, color)

# Motes drifting up and fading; one per phase offset.
func _motes(canvas: Image, f: int, xs: Array, from_y: float, rise: float, colors: Array) -> void:
	for k in xs.size():
		var t := float((f + k * 3) % FRAMES) / FRAMES
		var x: int = xs[k] + roundi(sin(t * TAU) * 1.5)
		_px(canvas, x, roundi(from_y - t * rise), colors[0] if t < 0.6 else colors[1])

# --- Wardens ----------------------------------------------------------------------------------

const LEAF := ["#3f7a3e", "#6ab04a", "#9ad86a"]

# Sprout: the tiny sleepy shoot every Warden starts as. A seed-bulb with a face, two leaves
# swaying on top, sitting in a little mound of soil, puffing weak spores.
func _draw_sprout(canvas: Image, f: int) -> void:
	var dy: int = FRAME_POSE[f]
	var sway: int = [0, 1, 1, 0, 0, -1, -1, 0][f]
	var o := Color("#1e3a24")
	_draw_waystone(canvas, poses[0])
	var soil := _layer()
	_ellipse(soil, Vector2(32, 44), Vector2(10, 3.5), _ramp(["#5a3a24", "#7a5234", "#9a6e48"]))
	_stamp(canvas, soil, Color("#2a1a10"))
	var stem := _layer()
	_stroke(stem, [Vector2(32, 34 + dy), Vector2(32.5, 27 + dy)], 1.5, Color("#5a9a3c"))
	_stamp(canvas, stem, o)
	_leaf(canvas, Vector2(32, 27 + dy), Vector2(22 + sway, 21 + dy), 3.5, _ramp(LEAF), o)
	_leaf(canvas, Vector2(33, 26 + dy), Vector2(43 + sway, 18 + dy), 4.0, _ramp(LEAF), o)
	_breathing_body(canvas, Vector2(32, 45), Vector2(8.5, 7.5), dy, _ramp(["#7aa850", "#a4d070", "#cce898", "#eefcd0"]), o)
	_face(canvas, 32, 36 + dy, o, f == BLINK_FRAME)
	_motes(canvas, f, [24, 42], 20, 14, [Color("#eefcd0"), Color("#a4d070")])

# Thornwall: a plain bramble hedge. No face, no soothing; clumps of leaves, a thorny vine,
# berries and a couple of blossoms.
func _draw_thornwall(canvas: Image, f: int) -> void:
	var o := Color("#14241a")
	var bush := _ramp(["#2a5232", "#3c7040", "#58964a", "#7cbc5a"])
	_draw_waystone(canvas, poses[0])
	var hedge := _layer()
	for clump: Rect2 in [Rect2(21, 32, 9, 8), Rect2(43, 31, 9, 8), Rect2(32, 25, 10, 9), Rect2(14, 41, 7, 5),
			Rect2(50, 40, 7, 5), Rect2(26, 39, 10, 7), Rect2(39, 40, 10, 7)]:
		var layer := _layer()
		_ellipse(layer, clump.position, clump.size, bush)
		_stamp(canvas, layer, o)
		_stamp(hedge, layer)
	# Leaf texture and thorns on the silhouette.
	for y in S:
		for x in S:
			if hedge.get_pixel(x, y).a == 0.0 or canvas.get_pixel(x, y) == o:
				continue
			var h := (x * 73 + y * 151) % 13
			if h == 0:
				canvas.set_pixel(x, y, bush[0])
			elif h == 5 and canvas.get_pixel(x, y) == bush[2]:
				canvas.set_pixel(x, y, bush[3])
	for y in range(1, S):
		for x in S:
			if hedge.get_pixel(x, y).a > 0.0 and hedge.get_pixel(x, y - 1).a == 0.0 and (x * 7) % 5 == 0:
				_px(canvas, x, y - 1, Color("#d8c090"))
	# Bramble vine looping through the hedge.
	var vine := [Vector2(12, 37), Vector2(19, 31), Vector2(27, 34), Vector2(33, 26), Vector2(41, 29), Vector2(51, 35)]
	_line(canvas, vine, Color("#6a4030"), hedge)
	for p: Vector2i in [Vector2i(16, 33), Vector2i(30, 29), Vector2i(45, 31)]:
		_px(canvas, p.x, p.y - 1, Color("#d8c090"))
	# Berries (they glint in turn) and blossoms.
	for i in 3:
		var b: Vector2i = [Vector2i(24, 29), Vector2i(37, 37), Vector2i(18, 41)][i]
		for d: Vector2i in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1)]:
			_px(canvas, b.x + d.x, b.y + d.y, Color("#8a2a5a"))
		_px(canvas, b.x, b.y, Color("#f0a0c8") if (f / 2) % 3 == i else Color("#c8387a"))
	for bl: Vector2i in [Vector2i(44, 26), Vector2i(29, 40), Vector2i(52, 38)]:
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			_px(canvas, bl.x + d.x, bl.y + d.y, Color("#fff4f0"))
		_px(canvas, bl.x, bl.y, Color("#ffd24a"))
	# A leaf drifting off the hedge.
	var t := float(f) / FRAMES
	_px(canvas, 47 + roundi(sin(t * TAU) * 2), 20 + roundi(t * 8), Color("#7cbc5a"))

# Sporeling: the original concept art (the mock), dozing on the mossy waystone, releasing spores.
func _draw_sporeling(canvas: Image, f: int) -> void:
	var pose: Dictionary = poses[FRAME_POSE[f]]
	var fig := _pal("#17174d", "#ed9df2", "#de73e5", "#ba41d9")
	_draw_waystone(canvas, pose)
	_draw_template_figure(canvas, pose, fig)
	if f == BLINK_FRAME:
		_blink(canvas, FRAME_POSE[f], fig.a, fig.o)
	_motes(canvas, f, [21, 42, 34], 16, 16, [Color("#f7c8fa"), Color("#de73e5")])

# Pebbling: a small round stone spirit wearing a cap of moss with a flower in it, with little
# pebble feet.
func _draw_pebbling(canvas: Image, f: int) -> void:
	var dy: int = FRAME_POSE[f]
	var o := Color("#1c1c36")
	var stone := _ramp(["#686d9a", "#979dc2", "#c4c9e2", "#e4e7f4"])
	var moss := _ramp(["#3f7a3e", "#5a9a48", "#7cbc5a", "#a8dc7a"])
	var top := _draw_waystone(canvas, poses[0])
	_rock(canvas, PackedVector2Array([Vector2(12, 44), Vector2(14, 41), Vector2(18, 41), Vector2(19, 44), Vector2(16, 46)]), stone, o)
	_rock(canvas, PackedVector2Array([Vector2(48, 44), Vector2(50, 42), Vector2(53, 42), Vector2(54, 45), Vector2(51, 46)]), stone, o)
	var body := _breathing_body(canvas, Vector2(32, 45), Vector2(12, 10.5), dy, stone, o)
	_mask_px(canvas, body, [Vector2i(25, 38), Vector2i(37, 41), Vector2i(40, 36), Vector2i(23, 33)], stone[0])
	# Moss cap with drips and a flower.
	var cap := _layer()
	_ellipse(cap, Vector2(32, 29 + dy), Vector2(10, 5.5), moss, 30.0 + dy)
	for p: Vector2i in [Vector2i(24, 30), Vector2i(24, 31), Vector2i(25, 30), Vector2i(39, 30), Vector2i(39, 31), Vector2i(31, 30), Vector2i(32, 30)]:
		cap.set_pixel(p.x, p.y + dy, moss[1])
	_stamp(canvas, cap, o)
	for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		_px(canvas, 36 + d.x, 25 + dy + d.y, Color("#fff4f0"))
	_px(canvas, 36, 25 + dy, Color("#ffd24a"))
	_face(canvas, 32, 35 + dy, o, f == BLINK_FRAME)
	# Pebble feet.
	var feet := _layer()
	_ellipse(feet, Vector2(26, 45), Vector2(3.5, 2.5), stone)
	_ellipse(feet, Vector2(38, 45), Vector2(3.5, 2.5), stone)
	_stamp(canvas, feet, o)

# Dewdrop: a bead of morning dew with a face, wobbling on a lily pad, a tiny droplet hopping
# beside it.
func _draw_dewdrop(canvas: Image, f: int) -> void:
	var dy: int = FRAME_POSE[f]
	var sway: int = [0, 1, 1, 0, 0, -1, -1, 0][f]
	var o := Color("#16305e")
	var water := _ramp(["#3a78c8", "#5aa8ec", "#9ad4ff", "#e8faff"])
	_draw_waystone(canvas, poses[0])
	# Lily pad with a notch and veins.
	var pad := _layer()
	_ellipse(pad, Vector2(32, 44), Vector2(16, 5), _ramp(["#3f7a3e", "#5a9a48", "#7cbc5a"]))
	_flat_polygon(pad, PackedVector2Array([Vector2(36, 45), Vector2(49, 44), Vector2(49, 47.5)]), Color(0, 0, 0, 0))
	_stamp(canvas, pad, Color("#1e3a24"))
	_line(canvas, [Vector2(20, 44), Vector2(28, 44)], Color("#3f7a3e"), pad)
	_line(canvas, [Vector2(24, 47), Vector2(29, 45)], Color("#3f7a3e"), pad)
	# The drop: a teardrop, lit from the upper left, with a light crescent in its base.
	var r := 9.0 + 0.5 * dy
	var c := Vector2(32, 44 - r)
	var drop := _layer()
	_flame(drop, c, r, 17.0 - dy, sway, Color.WHITE)
	for y in S:
		for x in S:
			if drop.get_pixel(x, y).a == 0.0:
				continue
			var p := Vector2(x + 0.5, y + 0.5)
			var q := (p - c - Vector2(-2, -3)).length() / r
			var col: Color = water[2] if q < 0.55 else (water[1] if q < 1.0 else water[0])
			if p.y - c.y > r * 0.5 and absf(p.x - c.x) < r * 0.55:
				col = water[2]
			drop.set_pixel(x, y, col)
	_stamp(canvas, drop, o)
	for h: Vector2i in [Vector2i(27, 31), Vector2i(27, 32), Vector2i(28, 30), Vector2i(26, 33)]:
		_px(canvas, h.x, h.y + dy, water[3])
	_px(canvas, 37, 40, water[3])
	_face(canvas, 32, 34 + dy, o, f == BLINK_FRAME)
	# A tiny droplet hopping on the pad.
	var hop: int = [0, 1, 2, 1, 0, 0, 0, 0][f]
	var bead := _layer()
	_flat_ellipse(bead, Vector2(46, 42 - hop), Vector2(1.6, 1.6), water[2])
	_stamp(canvas, bead, o)

# Firefly Jar: a glass jar with a cork, tied with string, a sprout growing from the cork and
# fireflies drifting and blinking inside.
func _draw_firefly_jar(canvas: Image, f: int) -> void:
	var o := Color("#1a2230")
	var glass := _ramp(["#2e4a58", "#4e7482", "#86b4bc", "#d8f4f4"])
	var cork := _ramp(["#6a4428", "#8a5a3a", "#b07a4a", "#d09a6a"])
	var top := _draw_waystone(canvas, poses[0])
	var bright := f % 4 < 2
	# Warm glow on the slab around the jar.
	for y in S:
		for x in S:
			var q := ((Vector2(x + 0.5, y + 0.5) - Vector2(32, 45)) / Vector2(17, 6)).length()
			if top.get_pixel(x, y).a > 0.0 and q < 1.0 and q > 0.6 and (x + y) % 2 == 0 and bright:
				canvas.set_pixel(x, y, Color("#d8d890"))
	# Jar: body and neck, glass dark inside with light edges.
	var jar := _layer()
	_round_rect(jar, Rect2i(21, 22, 23, 24), 6, glass[0])
	_round_rect(jar, Rect2i(25, 17, 15, 7), 2, glass[0])
	for y in S:
		for x in S:
			if jar.get_pixel(x, y).a == 0.0:
				continue
			if x <= 23 and y > 20:
				jar.set_pixel(x, y, glass[2])
			elif x >= 41 or y >= 43:
				jar.set_pixel(x, y, glass[1])
	_stamp(canvas, jar, o)
	for y in range(25, 40):
		_px(canvas, 24, y, glass[3])
	_px(canvas, 25, 26, glass[3])
	# Fireflies.
	for k in 5:
		var home: Vector2 = [Vector2(28, 28), Vector2(36, 26), Vector2(32, 34), Vector2(27, 39), Vector2(37, 38)][k]
		var a := float(f) / FRAMES * TAU + k * 1.3
		var p := Vector2i((home + Vector2(cos(a) * 2.0, sin(a * 2.0) * 1.5)).round())
		if (f + k) % 4 == 0:
			_px(canvas, p.x, p.y, Color("#8aa860"))
			continue
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			_px(canvas, p.x + d.x, p.y + d.y, Color("#a8c868"))
		_px(canvas, p.x, p.y, Color("#fff27a"))
	# String around the neck, cork, and a sprout on the cork.
	var tie := _layer()
	_round_rect(tie, Rect2i(24, 20, 17, 3), 1, Color("#e0c8a0"))
	_stamp(canvas, tie, o)
	_px(canvas, 42, 20, Color("#e0c8a0"))
	_px(canvas, 43, 22, Color("#e0c8a0"))
	var lid := _layer()
	_round_rect(lid, Rect2i(26, 11, 13, 8), 2, cork[1])
	for y in range(11, 19):
		for x in range(26, 39):
			if lid.get_pixel(x, y).a > 0.0:
				lid.set_pixel(x, y, cork[2] if y < 13 else (cork[0] if x > 35 else cork[1]))
	_stamp(canvas, lid, o)
	_px(canvas, 29, 15, cork[0])
	_px(canvas, 33, 16, cork[3])
	var sway: int = [0, 1, 1, 0, 0, -1, -1, 0][f]
	_leaf(canvas, Vector2(32, 11), Vector2(26 + sway, 5), 2.8, _ramp(LEAF), o)
	_leaf(canvas, Vector2(33, 11), Vector2(39 + sway, 4), 3.0, _ramp(LEAF), o)

# Rootling: a little root spirit with a bark body, root legs gripping the stone, root arms (one
# waving) and a leafy sprout on its head.
func _draw_rootling(canvas: Image, f: int) -> void:
	var dy: int = FRAME_POSE[f]
	var sway: int = [0, 1, 1, 0, 0, -1, -1, 0][f]
	var o := Color("#24160e")
	var bark := _ramp(["#5a3a24", "#7a5234", "#9a6e48", "#c09268"])
	_draw_waystone(canvas, poses[0])
	var roots := _layer()
	for root: Array in [[Vector2(28, 40), Vector2(22, 44), Vector2(15, 45)], [Vector2(31, 42), Vector2(28, 48)],
			[Vector2(36, 41), Vector2(42, 45), Vector2(49, 44)], [Vector2(34, 42), Vector2(37, 49)]]:
		_stroke(roots, root, 1.7, bark[1])
	_stamp(canvas, roots, o)
	# Head sprout (behind the body so the stem tucks in).
	_leaf(canvas, Vector2(31, 24 + dy), Vector2(24 + sway, 17 + dy), 3.2, _ramp(LEAF), o)
	_leaf(canvas, Vector2(33, 24 + dy), Vector2(40 + sway, 15 + dy), 3.6, _ramp(LEAF), o)
	var body := _breathing_body(canvas, Vector2(32, 44), Vector2(9.5, 10.5), dy, bark, o)
	# Bark grain.
	for g: Array in [[Vector2(27, 29 + dy), Vector2(26, 34 + dy)], [Vector2(37, 31 + dy), Vector2(38, 37 + dy)],
			[Vector2(30, 40), Vector2(30, 42)]]:
		_line(canvas, g, bark[0], body)
	_face(canvas, 32, 32 + dy, o, f == BLINK_FRAME)
	# Arms: the left one waves.
	var wave: int = [0, -1, -2, -1, 0, 0, 0, 0][f]
	var arms := _layer()
	_stroke(arms, [Vector2(24, 34 + dy), Vector2(20, 30 + dy), Vector2(18, 25 + dy + wave)], 1.5, bark[2])
	_stroke(arms, [Vector2(40, 35 + dy), Vector2(44, 38 + dy), Vector2(45, 42)], 1.5, bark[2])
	_stamp(canvas, arms, o)

# Acorn: an acorn spirit with a scaly cap, a stem and a leaf, sitting on the stone.
func _draw_acorn(canvas: Image, f: int) -> void:
	var dy: int = FRAME_POSE[f]
	var sway: int = [0, 1, 1, 0, 0, -1, -1, 0][f]
	var o := Color("#2a1a10")
	var nut := _ramp(["#8a5a2a", "#b07a3a", "#d49c54", "#f0c080"])
	var shell := _ramp(["#4a3018", "#6a4828", "#8a6440", "#a88258"])
	_draw_waystone(canvas, poses[0])
	var nub := _layer()
	_flat_ellipse(nub, Vector2(32, 46), Vector2(2, 1.5), nut[0])
	_stamp(canvas, nub, o)
	_breathing_body(canvas, Vector2(32, 46), Vector2(11, 11), dy, nut, o)
	# Cap with a scale pattern, stem and leaf.
	var stem := _layer()
	_stroke(stem, [Vector2(32, 22 + dy), Vector2(33, 18 + dy)], 1.5, shell[1])
	_stamp(canvas, stem, o)
	_leaf(canvas, Vector2(34, 19 + dy), Vector2(43 + sway, 14 + dy), 3.2, _ramp(LEAF), o)
	var cap := _layer()
	_ellipse(cap, Vector2(32, 30 + dy), Vector2(13, 8), shell, 31.0 + dy)
	for y in S:
		for x in S:
			if cap.get_pixel(x, y).a > 0.0 and (x + 2 * y) % 4 == 0 and y < 30 + dy:
				cap.set_pixel(x, y, shell[0])
	_stamp(canvas, cap, o)
	_face(canvas, 32, 34 + dy, o, f == BLINK_FRAME)

func _round_rect(layer: Image, rect: Rect2i, r: int, color: Color) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var cx := clampi(x, rect.position.x + r, rect.end.x - 1 - r)
			var cy := clampi(y, rect.position.y + r, rect.end.y - 1 - r)
			if Vector2(x - cx, y - cy).length() <= r + 0.25:
				layer.set_pixel(x, y, color)

# Teardrop built from a column of shrinking circles; the upper part bends with sway.
func _flame(layer: Image, base: Vector2, r: float, height: float, sway: float, color: Color) -> void:
	for step in 25:
		var t := step / 24.0
		var c := base + Vector2(sway * 3.0 * t * t, -height * t)
		var rr := r * pow(1.0 - t, 1.5)
		if rr >= 0.5:
			_flat_ellipse(layer, c, Vector2(rr, rr), color)

# --- Projectiles (new) --------------------------------------------------------------------------

func _proj_pebble(canvas: Image, f: int) -> void:
	_spinning_rock(canvas, f, 4.5, _ramp(["#686d9a", "#979dc2", "#c4c9e2", "#e4e7f4"]), Color("#1c1c36"))
	_px(canvas, 31, 30, Color("#7cbc5a"))

# A water bead flying right: round front, tail trailing behind, spray drops.
func _proj_dew_drop(canvas: Image, f: int) -> void:
	var water := _ramp(["#3a78c8", "#5aa8ec", "#9ad4ff", "#e8faff"])
	var layer := _layer()
	for step in 16:
		var t := step / 15.0
		var rr := 4.0 * pow(1.0 - t, 1.3)
		if rr >= 0.5:
			_flat_ellipse(layer, Vector2(35 - t * 10, 32), Vector2(rr, rr), water[1])
	for y in S:
		for x in S:
			if layer.get_pixel(x, y).a > 0.0 and y < 32:
				layer.set_pixel(x, y, water[2])
	_stamp(canvas, layer, Color("#16305e"))
	_px(canvas, 35, 30, water[3])
	_px(canvas, 36, 30, water[3])
	_px(canvas, 23 - f % 2, 30 + f % 2, water[2])
	_px(canvas, 25, 35 - f % 2, water[1])

# A firefly spark: glowing core with a flickering halo and a short trail.
func _proj_spark(canvas: Image, f: int) -> void:
	var halo: float = 3.5 + [0.0, 0.8, 0.3, 1.0][f]
	for y in S:
		for x in S:
			var q := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(34, 32))
			if q < halo and q >= 2.0 and (x + y + f) % 2 == 0:
				canvas.set_pixel(x, y, Color("#c8e060"))
	var core := _layer()
	_flat_ellipse(core, Vector2(34, 32), Vector2(2.2, 2.2), Color("#fff27a"))
	_stamp(canvas, core, Color("#e8b030"))
	_px(canvas, 34, 32, Color.WHITE)
	for k in 3:
		_px(canvas, 29 - k * 2, 32 + ((k + f) % 2), Color("#e8f090") if k == 0 else Color("#a8c868"))
