extends SceneTree
# Generates the Warden (tower) spritesheets in assets/towers/ (64x64 frames, FRAMES per row) and
# their projectiles in assets/towers/projectiles/ (16x16 frames). Wardens are listed in
# documentation/game_design.md. Each Warden is a golem in the pose of the original concept mock
# (POSE_UP / POSE_DOWN below), dozing on the mock's slab as a mossy waystone; the Sporeling is the
# mock's figure itself.
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

# Motes drifting up and fading; one per phase offset.
func _motes(canvas: Image, f: int, xs: Array, from_y: float, rise: float, colors: Array) -> void:
	for k in xs.size():
		var t := float((f + k * 3) % FRAMES) / FRAMES
		var x: int = xs[k] + roundi(sin(t * TAU) * 1.5)
		_px(canvas, x, roundi(from_y - t * rise), colors[0] if t < 0.6 else colors[1])

# --- Warden golems ----------------------------------------------------------------------------
# Every Warden is a golem in the mock's seated pose (the Sporeling is the mock itself), themed
# after its line in game_design.md, dozing on the mossy waystone.

const LEAF := ["#3f7a3e", "#6ab04a", "#9ad86a"]
const SWAY := [0, 1, 1, 0, 0, -1, -1, 0]

# Recoloured mock face: blink (or always asleep), optional glowing eyes and rosy cheeks.
func _golem_face(canvas: Image, f: int, dy: int, fig: Dictionary, eye: Color = Color(0, 0, 0, 0),
		blush: bool = true, asleep: bool = false) -> void:
	if blush:
		for bx: int in [24, 25, 34, 35]:
			_px(canvas, bx, EYE_TOP + 3 + dy, BLUSH)
	var closed := asleep or f == BLINK_FRAME
	for ex: int in EYES:
		for k in 3:
			var col: Color = fig.a if closed and k != 1 else (eye if eye.a > 0.0 else fig.o)
			_px(canvas, ex, EYE_TOP + k + dy, col)
		if closed:
			_px(canvas, ex, EYE_TOP + 1 + dy, fig.o)
			_px(canvas, ex + 1, EYE_TOP + 1 + dy, fig.o)

# Pixels of the figure that aren't outline, for texture and decorations.
func _skin_px(canvas: Image, mask: Image, o: Color, pts: Array, color: Color) -> void:
	for p: Vector2i in pts:
		if p.x >= 0 and p.y >= 0 and p.x < S and p.y < S and mask.get_pixelv(p).a > 0.0 and canvas.get_pixelv(p) != o:
			canvas.set_pixelv(p, color)

func _glow_dot(canvas: Image, p: Vector2i, core: Color, halo: Color, mask: Image = null) -> void:
	for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var q := p + d
		if mask == null or (q.x >= 0 and q.y >= 0 and q.x < S and q.y < S and mask.get_pixelv(q).a > 0.0):
			_px(canvas, q.x, q.y, halo)
	_px(canvas, p.x, p.y, core)

# Sprout: a pale green seedling golem with two leaves sprouting from its head and soil on its
# feet, puffing weak spores.
func _draw_sprout(canvas: Image, f: int) -> void:
	var dy: int = FRAME_POSE[f]
	var sway: int = SWAY[f]
	var fig := _pal("#1e3a24", "#cce898", "#a4d070", "#7aa850")
	var soil := Color("#7a5234")
	_draw_waystone(canvas, poses[dy])
	var mask := _draw_template_figure(canvas, poses[dy], fig)
	var stem := _layer()
	_stroke(stem, [Vector2(30.5, 8 + dy), Vector2(30.5, 3 + dy)], 1.5, Color("#5a9a3c"))
	_stamp(canvas, stem, fig.o)
	_leaf(canvas, Vector2(30, 4 + dy), Vector2(19 + sway, 1 + dy), 3.5, _ramp(LEAF), fig.o)
	_leaf(canvas, Vector2(31, 4 + dy), Vector2(43 + sway, 0 + dy), 4.0, _ramp(LEAF), fig.o)
	# Seed-coat speckles and soil clinging to the legs.
	_skin_px(canvas, mask, fig.o, [Vector2i(33, 22 + dy), Vector2i(37, 26 + dy), Vector2i(26, 27 + dy), Vector2i(31, 33)], fig.c)
	_skin_px(canvas, mask, fig.o, [Vector2i(12, 41), Vector2i(13, 41), Vector2i(14, 42), Vector2i(20, 45), Vector2i(21, 45),
		Vector2i(36, 47), Vector2i(37, 47), Vector2i(38, 46), Vector2i(48, 41), Vector2i(49, 41)], soil)
	_golem_face(canvas, f, dy, fig)
	_motes(canvas, f, [15, 46, 38], 20, 16, [Color("#eefcd0"), Color("#a4d070")])

# Thornwall: a bramble golem that never wakes up. Leafy body, a thorny vine wrapped round it,
# berries, blossoms, and bramble tufts on the stone.
func _draw_thornwall(canvas: Image, f: int) -> void:
	var dy: int = FRAME_POSE[f]
	var fig := _pal("#14241a", "#7cbc5a", "#58964a", "#3c7040")
	var bush := _ramp(["#2a5232", "#3c7040", "#58964a", "#7cbc5a"])
	var thorn := Color("#d8c090")
	_draw_waystone(canvas, poses[dy])
	for tuft: Rect2 in [Rect2(8, 42, 5, 3.5), Rect2(56, 42, 5, 3.5)]:
		var t := _layer()
		_ellipse(t, tuft.position, tuft.size, bush)
		_stamp(canvas, t, fig.o)
	var mask := _draw_template_figure(canvas, poses[dy], fig)
	for y in S:
		for x in S:
			if mask.get_pixel(x, y).a == 0.0 or canvas.get_pixel(x, y) == fig.o:
				continue
			var h := (x * 73 + y * 151) % 11
			if h == 0:
				canvas.set_pixel(x, y, bush[0])
			elif h == 4 and canvas.get_pixel(x, y) == fig.a:
				canvas.set_pixel(x, y, Color("#a8dc7a"))
	# Thorns poking out of the top of the silhouette.
	for y in range(1, S):
		for x in S:
			if mask.get_pixel(x, y).a > 0.0 and mask.get_pixel(x, y - 1).a == 0.0 and (x * 7) % 4 == 0:
				_px(canvas, x, y - 1, thorn)
	# Vine wrapped round the body.
	for vine: Array in [[Vector2(19, 31), Vector2(25, 26 + dy), Vector2(31, 29), Vector2(37, 24 + dy), Vector2(44, 28)],
			[Vector2(20, 40), Vector2(27, 36), Vector2(34, 39)]]:
		_line(canvas, vine, Color("#6a4030"), mask)
	_skin_px(canvas, mask, fig.o, [Vector2i(22, 28 + dy), Vector2i(34, 26 + dy), Vector2i(41, 25 + dy), Vector2i(24, 37)], thorn)
	for i in 3:
		var b: Vector2i = [Vector2i(28, 32), Vector2i(39, 36), Vector2i(17, 38)][i]
		_skin_px(canvas, mask, fig.o, [b, b + Vector2i.RIGHT, b + Vector2i.DOWN, b + Vector2i(1, 1)], Color("#8a2a5a"))
		_skin_px(canvas, mask, fig.o, [b], Color("#f0a0c8") if (f / 2) % 3 == i else Color("#c8387a"))
	for bl: Vector2i in [Vector2i(36, 8 + dy), Vector2i(23, 24 + dy), Vector2i(42, 31)]:
		_skin_px(canvas, mask, fig.o, [bl + Vector2i.LEFT, bl + Vector2i.RIGHT, bl + Vector2i.UP, bl + Vector2i.DOWN], Color("#fff4f0"))
		_skin_px(canvas, mask, fig.o, [bl], Color("#ffd24a"))
	_golem_face(canvas, f, dy, fig, Color(0, 0, 0, 0), false, true)
	var t := float(f) / FRAMES
	_px(canvas, 50 + roundi(sin(t * TAU) * 2), 14 + roundi(t * 10), Color("#7cbc5a"))

# Sporeling: the original concept art, releasing drowsy spores.
func _draw_sporeling(canvas: Image, f: int) -> void:
	var dy: int = FRAME_POSE[f]
	var fig := _pal("#17174d", "#ed9df2", "#de73e5", "#ba41d9")
	_draw_waystone(canvas, poses[dy])
	_draw_template_figure(canvas, poses[dy], fig)
	_golem_face(canvas, f, dy, fig, Color(0, 0, 0, 0), false)
	_motes(canvas, f, [21, 42, 34], 16, 16, [Color("#f7c8fa"), Color("#de73e5")])

# Pebbling: a mossy stone golem with boulder shoulders, a moss cap with a flower, cracks and
# pebbles at its feet.
func _draw_pebbling(canvas: Image, f: int) -> void:
	var dy: int = FRAME_POSE[f]
	var fig := _pal("#1c1c36", "#c4c9e2", "#979dc2", "#686d9a")
	var stone := _ramp(["#686d9a", "#979dc2", "#c4c9e2", "#e4e7f4"])
	var moss := _ramp(["#3f7a3e", "#5a9a48", "#7cbc5a", "#a8dc7a"])
	_draw_waystone(canvas, poses[dy])
	_rock(canvas, PackedVector2Array([Vector2(4, 43), Vector2(6, 40), Vector2(10, 40), Vector2(11, 43), Vector2(8, 45)]), stone, fig.o)
	_rock(canvas, PackedVector2Array([Vector2(53, 45), Vector2(55, 42), Vector2(58, 42), Vector2(59, 45), Vector2(56, 47)]), stone, fig.o)
	var mask := _draw_template_figure(canvas, poses[dy], fig)
	_line(canvas, [Vector2(36, 9 + dy), Vector2(35, 11 + dy)], fig.c, mask)
	_line(canvas, [Vector2(21, 30), Vector2(23, 33), Vector2(22, 35)], fig.c, mask)
	_line(canvas, [Vector2(34, 36), Vector2(35, 39)], fig.c, mask)
	_line(canvas, [Vector2(28, 25 + dy), Vector2(30, 28 + dy)], fig.c, mask)
	_rock(canvas, PackedVector2Array([Vector2(14, 25 + dy), Vector2(16, 19 + dy), Vector2(22, 17 + dy),
		Vector2(27, 20 + dy), Vector2(25, 26 + dy), Vector2(18, 28 + dy)]), stone, fig.o)
	_rock(canvas, PackedVector2Array([Vector2(37, 20 + dy), Vector2(41, 15 + dy), Vector2(47, 16 + dy),
		Vector2(50, 21 + dy), Vector2(47, 26 + dy), Vector2(40, 25 + dy)]), stone, fig.o)
	# Moss: a cap with drips on the head, patches on the shoulders and legs.
	var cap := _layer()
	_ellipse(cap, Vector2(30.5, 9 + dy), Vector2(9.5, 5), moss, 9.0 + dy)
	for p: Vector2i in [Vector2i(22, 9), Vector2i(22, 10), Vector2i(29, 9), Vector2i(38, 9), Vector2i(38, 10)]:
		cap.set_pixel(p.x, p.y + dy, moss[1])
	_stamp(canvas, cap, fig.o)
	for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		_px(canvas, 34 + d.x, 5 + dy + d.y, Color("#fff4f0"))
	_px(canvas, 34, 5 + dy, Color("#ffd24a"))
	for m: Vector2i in [Vector2i(19, 19), Vector2i(20, 19), Vector2i(21, 18), Vector2i(43, 17), Vector2i(44, 17)]:
		_px(canvas, m.x, m.y + dy, moss[2])
	_skin_px(canvas, mask, fig.o, [Vector2i(12, 37), Vector2i(13, 37), Vector2i(14, 37), Vector2i(50, 34), Vector2i(51, 34), Vector2i(52, 35)], moss[1])
	_golem_face(canvas, f, dy, fig)

# Dewdrop: a water golem with a droplet tip on its head, a glossy body with bubbles rising
# inside, a drip falling from its hand and lily pads on the stone.
func _draw_dewdrop(canvas: Image, f: int) -> void:
	var dy: int = FRAME_POSE[f]
	var sway: int = SWAY[f]
	var fig := _pal("#16305e", "#9ad4ff", "#5aa8ec", "#3a78c8")
	var shine := Color("#e8faff")
	_draw_waystone(canvas, poses[dy])
	for pad: Rect2 in [Rect2(27, 50, 6.5, 3)]:
		var p := _layer()
		_ellipse(p, pad.position, pad.size, _ramp(LEAF))
		_stamp(canvas, p, Color("#1e3a24"))
	# Droplet tip behind the head, so only the point shows above it.
	var tip := _layer()
	_flame(tip, Vector2(30.5, 11 + dy), 6.0, 13.0, sway, fig.a)
	_stamp(canvas, tip, fig.o)
	var mask := _draw_template_figure(canvas, poses[dy], fig)
	# Gloss streaks.
	_skin_px(canvas, mask, fig.o, [Vector2i(24, 7 + dy), Vector2i(25, 7 + dy), Vector2i(24, 8 + dy), Vector2i(29, 1 + dy),
		Vector2i(22, 25 + dy), Vector2i(22, 26 + dy), Vector2i(21, 27 + dy), Vector2i(21, 28 + dy), Vector2i(21, 29 + dy),
		Vector2i(43, 28), Vector2i(43, 29)], shine)
	# Bubbles rising inside the body.
	for k in 3:
		var t := float((f + k * 3) % FRAMES) / FRAMES
		var b := Vector2i([27, 34, 38][k], roundi(42 - t * 18))
		_skin_px(canvas, mask, fig.o, [b, b + Vector2i.RIGHT], shine)
	# A drip falling from the hand.
	var drip := _layer()
	_flat_ellipse(drip, Vector2(44, 41 + f * 1.2), Vector2(1.4, 1.8), fig.a)
	_stamp(canvas, drip, fig.o)
	_golem_face(canvas, f, dy, fig)

# Firefly Jar: a glass golem with fireflies drifting inside it, a cork hat with a sprout,
# string tied round its neck and eyes lit like fireflies.
func _draw_firefly_jar(canvas: Image, f: int) -> void:
	var dy: int = FRAME_POSE[f]
	var sway: int = SWAY[f]
	var fig := _pal("#1a2230", "#4e7482", "#3e6270", "#2e4a58")
	var cork := _ramp(["#6a4428", "#8a5a3a", "#b07a4a", "#d09a6a"])
	var bright := f % 4 < 2
	var top := _draw_waystone(canvas, poses[dy])
	for y in S:
		for x in S:
			var q := ((Vector2(x + 0.5, y + 0.5) - Vector2(31, 45)) / Vector2(24, 8)).length()
			if bright and top.get_pixel(x, y).a > 0.0 and q < 1.0 and q > 0.7 and (x + y) % 2 == 0:
				canvas.set_pixel(x, y, Color("#d8d890"))
	var mask := _draw_template_figure(canvas, poses[dy], fig)
	# Glass highlights down the left side and on the head.
	for y in range(24, 40):
		_skin_px(canvas, mask, fig.o, [Vector2i(21, y + dy)], Color("#a8d0d8"))
	_skin_px(canvas, mask, fig.o, [Vector2i(24, 7 + dy), Vector2i(24, 8 + dy), Vector2i(25, 7 + dy), Vector2i(22, 24 + dy)], Color("#d8f4f4"))
	# Fireflies.
	for k in 6:
		var home: Vector2 = [Vector2(27, 25), Vector2(35, 27), Vector2(30, 33), Vector2(24, 36), Vector2(37, 22), Vector2(33, 8)][k]
		var a := float(f) / FRAMES * TAU + k * 1.3
		var p := Vector2i((home + Vector2(cos(a) * 2.0, sin(a * 2.0) * 1.5)).round()) + Vector2i(0, dy)
		if (f + k) % 4 == 0:
			_skin_px(canvas, mask, fig.o, [p], Color("#8aa860"))
		elif mask.get_pixelv(p).a > 0.0:
			_glow_dot(canvas, p, Color("#fff27a"), Color("#a8c868"), mask)
	# String round the neck.
	_line(canvas, [Vector2(25, 19 + dy), Vector2(44, 19 + dy)], Color("#e0c8a0"), mask)
	_px(canvas, 45, 19 + dy, Color("#e0c8a0"))
	_px(canvas, 46, 20 + dy, Color("#e0c8a0"))
	# Cork hat and its sprout.
	var lid := _layer()
	_round_rect(lid, Rect2i(24, 1 + dy, 14, 7), 2, cork[1])
	for y in S:
		for x in S:
			if lid.get_pixel(x, y).a > 0.0:
				lid.set_pixel(x, y, cork[2] if y < 3 + dy else (cork[0] if x > 34 else cork[1]))
	_stamp(canvas, lid, fig.o)
	_px(canvas, 27, 4 + dy, cork[0])
	_px(canvas, 31, 5 + dy, cork[3])
	_leaf(canvas, Vector2(37, 3 + dy), Vector2(45 + sway, 0), 2.8, _ramp(LEAF), fig.o)
	_golem_face(canvas, f, dy, fig, Color("#fff27a"), false)

# Rootling: a bark golem with roots spreading from its feet into the stone, root tendrils
# curling from its shoulders (one waves), a knot hole and a leafy sprout on its head.
func _draw_rootling(canvas: Image, f: int) -> void:
	var dy: int = FRAME_POSE[f]
	var sway: int = SWAY[f]
	var fig := _pal("#24160e", "#c09268", "#9a6e48", "#7a5234")
	_draw_waystone(canvas, poses[dy])
	var roots := _layer()
	for root: Array in [[Vector2(16, 44), Vector2(10, 46), Vector2(5, 44)], [Vector2(27, 47), Vector2(25, 53)],
			[Vector2(40, 48), Vector2(46, 52), Vector2(53, 50)], [Vector2(52, 42), Vector2(57, 41), Vector2(61, 42)]]:
		_stroke(roots, root, 1.6, fig.b)
	_stamp(canvas, roots, fig.o)
	var mask := _draw_template_figure(canvas, poses[dy], fig)
	for g: Array in [[Vector2(24, 26 + dy), Vector2(23, 31 + dy), Vector2(24, 35)], [Vector2(29, 23 + dy), Vector2(30, 29 + dy)],
			[Vector2(36, 28 + dy), Vector2(37, 34)], [Vector2(27, 7 + dy), Vector2(26, 9 + dy)], [Vector2(15, 40), Vector2(18, 42)]]:
		_line(canvas, g, fig.c, mask)
	var knot := _layer()
	_flat_ellipse(knot, Vector2(33, 33), Vector2(1.6, 2.2), fig.c)
	_stamp(canvas, knot, fig.o)
	_leaf(canvas, Vector2(30, 5 + dy), Vector2(21 + sway, 1 + dy), 3.2, _ramp(LEAF), fig.o)
	_leaf(canvas, Vector2(31, 5 + dy), Vector2(41 + sway, 0 + dy), 3.6, _ramp(LEAF), fig.o)
	var wave: int = [0, -1, -2, -1, 0, 0, 0, 0][f]
	var tendrils := _layer()
	_stroke(tendrils, [Vector2(21, 23 + dy), Vector2(17, 19 + dy), Vector2(16, 14 + dy + wave)], 1.3, fig.b)
	_stroke(tendrils, [Vector2(42, 23 + dy), Vector2(47, 21 + dy), Vector2(49, 17 + dy)], 1.3, fig.b)
	_stamp(canvas, tendrils, fig.o)
	_golem_face(canvas, f, dy, fig)

# Acorn: a nut golem wearing a scaly acorn cap with a stem and leaf, little acorns beside it.
func _draw_acorn(canvas: Image, f: int) -> void:
	var dy: int = FRAME_POSE[f]
	var sway: int = SWAY[f]
	var fig := _pal("#2a1a10", "#f0c080", "#d49c54", "#b07a3a")
	var shell := _ramp(["#4a3018", "#6a4828", "#8a6440", "#a88258"])
	_draw_waystone(canvas, poses[dy])
	var mask := _draw_template_figure(canvas, poses[dy], fig)
	# A little acorn on the stone in front.
	var nut := _layer()
	_ellipse(nut, Vector2(26, 50), Vector2(3, 3.5), _ramp(["#b07a3a", "#d49c54", "#f0c080"]))
	_stamp(canvas, nut, fig.o)
	var hat := _layer()
	_ellipse(hat, Vector2(26, 48), Vector2(4, 2.5), shell, 48.5)
	_stamp(canvas, hat, fig.o)
	for g: Array in [[Vector2(26, 24 + dy), Vector2(25, 30 + dy)], [Vector2(35, 26 + dy), Vector2(36, 31)]]:
		_line(canvas, g, fig.b, mask)
	var stem := _layer()
	_stroke(stem, [Vector2(30.5, 5 + dy), Vector2(31.5, 1 + dy)], 1.3, shell[1])
	_stamp(canvas, stem, fig.o)
	_leaf(canvas, Vector2(32, 2 + dy), Vector2(41 + sway, 0), 3.0, _ramp(LEAF), fig.o)
	var cap := _layer()
	_ellipse(cap, Vector2(30.5, 10 + dy), Vector2(12.5, 7), shell, 10.5 + dy)
	for y in S:
		for x in S:
			if cap.get_pixel(x, y).a > 0.0 and (x + 2 * y) % 4 == 0 and y < 9 + dy:
				cap.set_pixel(x, y, shell[0])
	_stamp(canvas, cap, fig.o)
	_golem_face(canvas, f, dy, fig)

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
