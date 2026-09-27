extends SceneTree
# Generates the blighted creature (enemy) spritesheets in assets/creatures/ and a SpriteFrames
# resource per creature in animation/enemy/. Creatures are listed in documentation/enemy_design.md.
# Each sheet has one row per animation (walk_side facing right, walk_down, walk_up, then extras such
# as the Hedgehog's roll) of FRAMES 64x64 frames. Art is drawn in full colour: in game the blight
# shader greys it until the creature is cleansed. Same look as the Wardens: dark outline, banded
# shading lit from the upper right, dot eyes with a shine, rosy cheeks.
# Run:  Godot --headless --path . --script res://tools/creature_art_generator.gd
# then once with --import so new sheets are imported (re-running afterwards adds their uids to the
# SpriteFrames; existing SpriteFrames keep their own uid, so references to them stay valid).

const S := 64
const FRAMES := 6
const OUT := "res://assets/creatures/"
const ANIM_OUT := "res://animation/enemy/"
const PREVIEW := "res://tools/creature_art_preview.png"
const PREVIEW_SCALE := 2
const WALKS := ["walk_side", "walk_down", "walk_up"]
enum { SIDE, DOWN, UP }

# fps: animation speed. draw: shared draw function (default: the creature's own). k: size scale for
# the small versions spawned by splitters.
const CREATURES := {
	"leaf_bug": {fps = 10.0},
	"bark_beetle": {fps = 6.0},
	"dusk_moth": {fps = 12.0},
	"dandelion_seed": {fps = 6.0},
	"puffcap": {fps = 9.0},
	"puffcaplet": {fps = 11.0, draw = "puffcap", k = 0.6},
	"mother_spider": {fps = 9.0},
	"spiderling": {fps = 14.0, draw = "mother_spider", k = 0.5},
	"hedgehog": {fps = 9.0, extra = ["roll"]},
	"wandering_hare": {fps = 8.0},
}

const BLUSH := Color("#f49aa8")
const SHADOW := Color(0.08, 0.14, 0.06, 0.32)
const LEAF := ["#3f7a3e", "#6ab04a", "#9ad86a"]

var light := Vector3(0.45, -0.55, 0.7).normalized()
var sheets: Array[Image] = []

func _init() -> void:
	for dir: String in [OUT, ANIM_OUT]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for creature: String in CREATURES:
		_make(creature, CREATURES[creature])
	_save_preview()
	quit()

func _make(creature: String, info: Dictionary) -> void:
	var anims: Array = WALKS + info.get("extra", [])
	var draw := Callable(self, "_draw_" + info.get("draw", creature))
	var sheet := Image.create_empty(S * FRAMES, S * anims.size(), false, Image.FORMAT_RGBA8)
	for row in anims.size():
		for f in FRAMES:
			var canvas := _layer()
			var st := {anim = anims[row], dir = row if row < WALKS.size() else -1, f = f,
				ph = TAU * f / FRAMES, k = info.get("k", 1.0)}
			draw.call(canvas, st)
			sheet.blit_rect(canvas, Rect2i(0, 0, S, S), Vector2i(f * S, row * S))
	sheet.save_png(OUT + creature + ".png")
	sheets.append(sheet)
	_save_sprite_frames(creature, anims, info.fps)

# Writes animation/enemy/<creature>.tres: one AtlasTexture per frame, one looping animation per row.
func _save_sprite_frames(creature: String, anims: Array, fps: float) -> void:
	var path := ANIM_OUT + creature + ".tres"
	var png := OUT + creature + ".png"
	var uid := _read_uid(path)
	var tex_uid := _read_uid(png + ".import")
	var text := "[gd_resource type=\"SpriteFrames\" format=3%s]\n\n" % ((" uid=\"%s\"" % uid) if uid else "")
	text += "[ext_resource type=\"Texture2D\"%s path=\"%s\" id=\"1_sheet\"]\n\n" % [(" uid=\"%s\"" % tex_uid) if tex_uid else "", png]
	for row in anims.size():
		for f in FRAMES:
			text += "[sub_resource type=\"AtlasTexture\" id=\"frame_%d_%d\"]\natlas = ExtResource(\"1_sheet\")\n" % [row, f]
			text += "region = Rect2(%d, %d, %d, %d)\n\n" % [f * S, row * S, S, S]
	var entries: Array[String] = []
	for row in anims.size():
		var frames: Array[String] = []
		for f in FRAMES:
			frames.append("{\n\"duration\": 1.0,\n\"texture\": SubResource(\"frame_%d_%d\")\n}" % [row, f])
		entries.append("{\n\"frames\": [%s],\n\"loop\": true,\n\"name\": &\"%s\",\n\"speed\": %s\n}" % [", ".join(frames), anims[row], str(fps)])
	text += "[resource]\nanimations = [%s]\n" % ", ".join(entries)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)

func _read_uid(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var found := RegEx.create_from_string("uid=\"(uid://[a-z0-9]+)\"").search(FileAccess.get_file_as_string(path))
	return found.get_string(1) if found else ""

# All sheets on grass in two columns, scaled up, for eyeballing.
func _save_preview() -> void:
	var pad := 6
	var block_w := FRAMES * (S + pad) + pad
	var heights := [pad, pad]
	for i in sheets.size():
		heights[i % 2] += sheets[i].get_height() / S * (S + pad)
	var preview := Image.create_empty(block_w * 2, maxi(heights[0], heights[1]), false, Image.FORMAT_RGBA8)
	preview.fill(Color("#5fa844"))
	var y := [pad, pad]
	for i in sheets.size():
		var col := i % 2
		for row in sheets[i].get_height() / S:
			for f in FRAMES:
				preview.blend_rect(sheets[i], Rect2i(f * S, row * S, S, S), Vector2i(col * block_w + pad + f * (S + pad), y[col]))
			y[col] += S + pad
	preview.resize(preview.get_width() * PREVIEW_SCALE, preview.get_height() * PREVIEW_SCALE, Image.INTERPOLATE_NEAREST)
	preview.save_png(PREVIEW)

# --- Primitives -------------------------------------------------------------------------------

func _layer() -> Image:
	return Image.create_empty(S, S, false, Image.FORMAT_RGBA8)

func _px(canvas: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < S and y < S:
		canvas.set_pixel(x, y, color)

func _ramp(hexes: Array) -> Array[Color]:
	var out: Array[Color] = []
	for h in hexes:
		out.append(Color(h))
	return out

# One step darker within a ramp (colours not in it are kept).
func _darker(ramp: Array[Color], color: Color) -> Color:
	var i := ramp.find(color)
	return ramp[maxi(i - 1, 0)] if i >= 0 else color

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

# Shaded ellipse on its own layer, outlined onto the canvas. Returns the layer (a mask of the part).
func _blob(canvas: Image, c: Vector2, r: Vector2, ramp: Array[Color], o: Color, max_y: float = INF) -> Image:
	var layer := _layer()
	_ellipse(layer, c, r, ramp, max_y)
	_stamp(canvas, layer, o)
	return layer

func _line(canvas: Image, pts: Array, color: Color) -> void:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
		for s in steps + 1:
			var p := a.lerp(b, s / maxf(steps, 1.0)).round()
			_px(canvas, int(p.x), int(p.y), color)

# Thick line of round dabs, for legs, horns and stalks.
func _stroke(layer: Image, pts: Array, r: float, color: Color) -> void:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var steps := int(ceilf(a.distance_to(b) * 2.0))
		for s in steps + 1:
			_flat_ellipse(layer, a.lerp(b, s / maxf(steps, 1.0)), Vector2(r, r), color)

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

# Pointed at both ends, lit on the side facing the light. For ears and wings seen edge-on.
func _lens(layer: Image, a: Vector2, b: Vector2, width: float, lit: Color, dark: Color) -> void:
	var axis := b - a
	var length := axis.length()
	var dir := axis / length
	var nrm := Vector2(-dir.y, dir.x)
	var lit_side := 1.0 if nrm.dot(Vector2(light.x, light.y)) >= 0.0 else -1.0
	for y in S:
		for x in S:
			var p := Vector2(x + 0.5, y + 0.5) - a
			var t := p.dot(dir) / length
			var s := p.dot(nrm)
			if t >= 0.0 and t <= 1.0 and absf(s) <= width * sin(t * PI):
				layer.set_pixel(x, y, lit if s * lit_side > 0.0 else dark)

# Soft contact shadow on the ground, drawn before the creature.
func _shadow(canvas: Image, c: Vector2, r: Vector2) -> void:
	_flat_ellipse(canvas, c, r, SHADOW)

# A dark w x h eye with a shine in its top-right corner (lit from the upper right).
func _eye(canvas: Image, x: int, y: int, w: int, h: int, o: Color) -> void:
	for dy in h:
		for dx in w:
			_px(canvas, x + dx, y + dy, o)
	if w * h >= 4:
		_px(canvas, x + w - 1, y, Color.WHITE)

# Two eyes mirrored around column `axis` (32 = the frame's centre line).
func _eye_pair(canvas: Image, axis: int, x: int, y: int, w: int, h: int, o: Color) -> void:
	_eye(canvas, x, y, w, h, o)
	_eye(canvas, 2 * axis - x - w, y, w, h, o)

# Moss patch on a part's layer (before stamping), dithered at the edge.
func _moss(layer: Image, c: Vector2, r: Vector2) -> void:
	var moss := _ramp(["#3f7a3e", "#5a9a48", "#7cbc5a"])
	for y in S:
		for x in S:
			if layer.get_pixel(x, y).a == 0.0:
				continue
			var d := (Vector2(x + 0.5, y + 0.5) - c) / r
			var q := d.length()
			if q > 1.0 or (q > 0.75 and (x + y) % 2 == 0):
				continue
			layer.set_pixel(x, y, moss[2] if q < 0.5 and d.y < 0.0 else (moss[0] if q > 0.75 else moss[1]))

# Pixels of a colour dotted onto a layer's own pixels only (spots, marks).
func _spots(layer: Image, pts: Array, r: float, color: Color) -> void:
	for p: Vector2 in pts:
		for y in range(floori(p.y - r), ceili(p.y + r) + 1):
			for x in range(floori(p.x - r), ceili(p.x + r) + 1):
				if x >= 0 and y >= 0 and x < S and y < S and layer.get_pixel(x, y).a > 0.0 \
						and Vector2(x + 0.5, y + 0.5).distance_to(p) <= r:
					layer.set_pixel(x, y, color)

# Leg from root through knee to foot: an outlined 3px limb, or a 1px dark line for tiny creatures.
func _leg(canvas: Image, pts: Array, color: Color, o: Color, thin: bool) -> void:
	if thin:
		_line(canvas, pts, o)
		return
	var layer := _layer()
	_stroke(layer, pts, 1.0, color)
	_stamp(canvas, layer, o)

# --- Leaf Bug -----------------------------------------------------------------------------------
# Common and quick: a little green bug whose back is a leaf, with a round face and antennae.

# Leaf from its stalk end to its tip: lit half, shaded half, dark midrib and veins angled to the tip.
func _leaf_back(layer: Image, base: Vector2, tip: Vector2, width: float, ramp: Array[Color]) -> void:
	var axis := tip - base
	var length := axis.length()
	var dir := axis / length
	var nrm := Vector2(-dir.y, dir.x)
	var lit_side := 1.0 if nrm.dot(Vector2(light.x, light.y)) >= 0.0 else -1.0
	for y in S:
		for x in S:
			var p := Vector2(x + 0.5, y + 0.5) - base
			var t := p.dot(dir) / length
			if t < 0.0 or t > 1.0:
				continue
			var s := p.dot(nrm)
			var w := width * sin(PI * (0.15 + 0.85 * t))
			if absf(s) > w:
				continue
			var lit := s * lit_side > 0.0
			var col: Color = ramp[2] if lit else ramp[1]
			if absf(s) < 0.6:
				col = ramp[0]
			elif absf(s) < w - 1.0 and posmod(roundi(t * length - absf(s) * 1.2), 4) == 0:
				col = ramp[1] if lit else ramp[0]
			elif lit and ramp.size() > 3 and absf(s) > w * 0.35 and absf(s) < w * 0.6 and t > 0.25 and t < 0.55:
				col = ramp[3]
			layer.set_pixel(x, y, col)

func _draw_leaf_bug(canvas: Image, st: Dictionary) -> void:
	var o := Color("#1e3a24")
	var leaf := _ramp(["#3f7a3e", "#5aa044", "#86c85a", "#b4e67e"])
	var skin := _ramp(["#6a9a3c", "#a4d070", "#cce898"])
	var f: int = st.f
	var ph: float = st.ph
	var bob: int = [0, -1, 0, 0, -1, 0][f]
	var wave: int = [0, 1, 1, 0, -1, -1][f]
	var body := _layer()
	match st.dir:
		SIDE:
			_shadow(canvas, Vector2(30, 42), Vector2(14, 2.5))
			for i in 3:  # far legs
				var s := sin(ph + i * PI + PI)
				_line(canvas, [Vector2(25 + i * 7, 37 + bob), Vector2(25 + i * 7 + roundi(s * 1.5), 40 - (1 if s > 0.5 else 0))], o)
			_leaf_back(body, Vector2(40, 33 + bob), Vector2(13, 32 + bob), 6.0, leaf)
			_stamp(canvas, body, o)
			for i in 3:  # near legs
				var s := sin(ph + i * PI)
				_line(canvas, [Vector2(23 + i * 7, 38 + bob), Vector2(23 + i * 7 + roundi(s * 1.5), 42 - (1 if s > 0.5 else 0))], o)
			_blob(canvas, Vector2(42, 36 + bob), Vector2(5, 4.5), skin, o)
			_line(canvas, [Vector2(42, 31 + bob), Vector2(44, 28 + bob), Vector2(47, 26 + bob + wave)], o)
			_px(canvas, 48, 26 + bob + wave, leaf[3])
			_eye(canvas, 43, 34 + bob, 2, 2, o)
			_px(canvas, 45, 37 + bob, BLUSH)
		DOWN:
			_shadow(canvas, Vector2(32, 43), Vector2(11, 2.5))
			_leaf_bug_legs(canvas, 23 + bob, st, o)
			_leaf_back(body, Vector2(32, 36 + bob), Vector2(32, 16 + bob), 8.0, leaf)
			_stamp(canvas, body, o)
			_blob(canvas, Vector2(32, 38 + bob), Vector2(5.5, 4.5), skin, o)
			for side: int in [-1, 1]:
				_line(canvas, [Vector2(32 + side * 2, 34 + bob), Vector2(32 + side * 5, 30 + bob), Vector2(32 + side * 7, 27 + bob + wave)], o)
				_px(canvas, 32 + side * 7 + (0 if side > 0 else -1), 26 + bob + wave, leaf[3])
			_eye_pair(canvas, 32, 28, 37 + bob, 2, 2, o)
			_px(canvas, 28, 40 + bob, BLUSH)
			_px(canvas, 35, 40 + bob, BLUSH)
			_px(canvas, 31, 40 + bob, skin[0])
			_px(canvas, 32, 40 + bob, skin[0])
		UP:
			_shadow(canvas, Vector2(32, 42), Vector2(11, 2.5))
			_blob(canvas, Vector2(32, 24 + bob), Vector2(5.5, 4.5), skin, o)
			for side: int in [-1, 1]:
				_line(canvas, [Vector2(32 + side * 2, 20 + bob), Vector2(32 + side * 5, 16 + bob), Vector2(32 + side * 7, 13 + bob + wave)], o)
				_px(canvas, 32 + side * 7 + (0 if side > 0 else -1), 12 + bob + wave, leaf[3])
			_leaf_bug_legs(canvas, 28 + bob, st, o)
			_leaf_back(body, Vector2(32, 25 + bob), Vector2(32, 45 + bob), 8.0, leaf)
			_stamp(canvas, body, o)

# Three legs a side poking out from under the leaf, in a tripod gait.
func _leaf_bug_legs(canvas: Image, top: int, st: Dictionary, o: Color) -> void:
	for i in 3:
		for side: int in [-1, 1]:
			var s := sin(st.ph + (i + (1 if side > 0 else 0)) * PI)
			var y := top + i * 5
			_line(canvas, [Vector2(32 + side * 6, y), Vector2(32 + side * 11, y + 2 - (1 if s > 0.5 else 0) + roundi(s))], o)

# --- Bark Beetle --------------------------------------------------------------------------------
# Slow and sturdy: a chunky beetle under a thick ridged bark shell with moss and a sprout on top.

# Ridges running front to back along the shell: curved lines one step darker, with a few breaks.
func _grooves(layer: Image, c: Vector2, r: Vector2, ramp: Array[Color], lengthwise_x: bool) -> void:
	for y in S:
		for x in S:
			var col := layer.get_pixel(x, y)
			if col.a == 0.0 or (x * 5 + y * 3) % 11 == 0:
				continue
			var d := (Vector2(x + 0.5, y + 0.5) - c) / r
			var v := d.y / sqrt(maxf(1.0 - d.x * d.x, 0.05)) if lengthwise_x else d.x / sqrt(maxf(1.0 - d.y * d.y, 0.05))
			if absf(fposmod(v * 2.5, 1.0) - 0.5) > 0.4:
				layer.set_pixel(x, y, _darker(ramp, col))

func _draw_bark_beetle(canvas: Image, st: Dictionary) -> void:
	var o := Color("#24160e")
	var bark := _ramp(["#4a3020", "#6a4830", "#8a6444", "#a8845c"])
	var skin := _ramp(["#8a6440", "#b08858", "#d4b080"])
	var leg := Color("#3a2418")
	var f: int = st.f
	var ph: float = st.ph
	var bob: int = [0, 0, -1, 0, 0, -1][f]
	var sway: int = [0, 0, 1, 0, 0, -1][f]
	var shell := _layer()
	var horn := _layer()
	match st.dir:
		SIDE:
			_shadow(canvas, Vector2(31, 43), Vector2(17, 3))
			for i in 3:
				var s := sin(ph + i * PI + PI)
				_beetle_leg(canvas, Vector2(24 + i * 8, 37 + bob), Vector2(25 + i * 8 + roundi(s * 1.5), 41 - (1 if s > 0.5 else 0)), o)
			var c := Vector2(29, 34 + bob)
			_ellipse(shell, c, Vector2(15, 11), bark, 38.5 + bob)
			_grooves(shell, c, Vector2(15, 11), bark, true)
			for x in S:
				for y in [37 + bob, 38 + bob]:
					if shell.get_pixel(x, y).a > 0.0:
						shell.set_pixel(x, y, bark[0])
			_moss(shell, Vector2(27, 25 + bob), Vector2(8, 3.5))
			_stamp(canvas, shell, o)
			_sprout(canvas, Vector2i(26, 23 + bob), o)
			for i in 3:
				var s := sin(ph + i * PI)
				_beetle_leg(canvas, Vector2(21 + i * 8, 38 + bob), Vector2(21 + i * 8 + roundi(s * 1.5), 43 - (1 if s > 0.5 else 0)), leg)
			_stroke(horn, [Vector2(46, 34 + bob), Vector2(48.5, 30 + bob), Vector2(48.5, 28 + bob)], 1.3, skin[1])
			_stamp(canvas, horn, o)
			_blob(canvas, Vector2(45, 37 + bob), Vector2(5.5, 5), skin, o)
			_eye(canvas, 46, 35 + bob, 2, 3, o)
			_px(canvas, 48, 39 + bob, BLUSH)
		DOWN:
			_shadow(canvas, Vector2(32, 44), Vector2(16, 3))
			_beetle_side_legs(canvas, 26 + bob, 32 + sway, st, leg)
			var c := Vector2(32 + sway, 29 + bob)
			_ellipse(shell, c, Vector2(14, 11), bark)
			_grooves(shell, c, Vector2(14, 11), bark, false)
			for y in S:
				if shell.get_pixel(32 + sway, y).a > 0.0:
					shell.set_pixel(32 + sway, y, bark[0])
			_moss(shell, Vector2(32 + sway, 22 + bob), Vector2(8, 3.5))
			_stamp(canvas, shell, o)
			_sprout(canvas, Vector2i(34 + sway, 20 + bob), o)
			_stroke(horn, [Vector2(32 + sway, 36 + bob), Vector2(32 + sway, 31 + bob)], 1.4, skin[1])
			_stamp(canvas, horn, o)
			_blob(canvas, Vector2(32 + sway, 39 + bob), Vector2(6.5, 5.5), skin, o)
			_eye_pair(canvas, 32 + sway, 28 + sway, 38 + bob, 2, 3, o)
			_px(canvas, 27 + sway, 42 + bob, BLUSH)
			_px(canvas, 36 + sway, 42 + bob, BLUSH)
			_px(canvas, 31 + sway, 42 + bob, skin[0])
			_px(canvas, 32 + sway, 42 + bob, skin[0])
		UP:
			_shadow(canvas, Vector2(32, 43), Vector2(16, 3))
			_stroke(horn, [Vector2(32 + sway, 18 + bob), Vector2(32 + sway, 13 + bob)], 1.4, skin[1])
			_stamp(canvas, horn, o)
			_blob(canvas, Vector2(32 + sway, 20 + bob), Vector2(6, 4.5), skin, o)
			_beetle_side_legs(canvas, 27 + bob, 32 + sway, st, leg)
			var c := Vector2(32 + sway, 32 + bob)
			_ellipse(shell, c, Vector2(14, 11.5), bark)
			_grooves(shell, c, Vector2(14, 11.5), bark, false)
			for y in S:
				if shell.get_pixel(32 + sway, y).a > 0.0:
					shell.set_pixel(32 + sway, y, bark[0])
			_moss(shell, Vector2(30 + sway, 26 + bob), Vector2(8, 3.5))
			_stamp(canvas, shell, o)
			_sprout(canvas, Vector2i(30 + sway, 24 + bob), o)

func _beetle_leg(canvas: Image, root: Vector2, foot: Vector2, color: Color) -> void:
	_line(canvas, [root, foot], color)
	_line(canvas, [root + Vector2.RIGHT, foot + Vector2.RIGHT], color)

func _beetle_side_legs(canvas: Image, top: int, cx: int, st: Dictionary, color: Color) -> void:
	for i in 3:
		for side: int in [-1, 1]:
			var s := sin(st.ph + (i + (1 if side > 0 else 0)) * PI)
			var y := top + i * 5
			var foot := Vector2(cx + side * 16 - (1 if side > 0 else 0), y + 3 - (1 if s > 0.5 else 0) + roundi(s))
			_beetle_leg(canvas, Vector2(cx + side * 10 - (1 if side > 0 else 0), y), foot, color)

# A two-leaf sprout growing from moss: stem at `p`, leaves up either side.
func _sprout(canvas: Image, p: Vector2i, o: Color) -> void:
	var leaf := _ramp(LEAF)
	_px(canvas, p.x, p.y, leaf[0])
	_px(canvas, p.x, p.y - 1, leaf[0])
	for q: Vector2i in [Vector2i(-1, -2), Vector2i(-2, -2), Vector2i(-2, -3)]:
		_px(canvas, p.x + q.x, p.y + q.y, leaf[2])
	for q: Vector2i in [Vector2i(1, -2), Vector2i(2, -3), Vector2i(3, -3)]:
		_px(canvas, p.x + q.x, p.y + q.y, leaf[1])
	_px(canvas, p.x - 3, p.y - 3, o)
	_px(canvas, p.x + 4, p.y - 4, o)

# --- Dusk Moth ----------------------------------------------------------------------------------
# Fast, hides in fog: a fluffy moth with dusky violet wings, eye spots and feathery antennae.

# Flat two-tone wing with a pale edge band and an optional eye spot, as a rotated ellipse.
func _wing(canvas: Image, c: Vector2, r: Vector2, angle: float, ramp: Array[Color], lit: bool, spot: bool, o: Color) -> void:
	var layer := _layer()
	var reach := ceili(maxf(r.x, r.y))
	for y in range(maxi(0, floori(c.y) - reach), mini(S, ceili(c.y) + reach + 1)):
		for x in range(maxi(0, floori(c.x) - reach), mini(S, ceili(c.x) + reach + 1)):
			var d := (Vector2(x + 0.5, y + 0.5) - c).rotated(-angle) / r
			var q := d.length()
			if q > 1.0:
				continue
			var col: Color = ramp[2] if lit else ramp[1]
			if q > 0.72:
				col = ramp[3] if lit else ramp[2]
			elif q < 0.3 and spot:
				col = Color("#f0b080") if q > 0.14 else Color("#3a2440")
			layer.set_pixel(x, y, col)
	_stamp(canvas, layer, o)

func _feather_antenna(canvas: Image, a: Vector2, b: Vector2, stem: Color, barb: Color) -> void:
	_line(canvas, [a, b], stem)
	var out := signf(b.x - a.x)
	for k in range(1, 4):
		var p := a.lerp(b, k / 4.0 + 0.1).round()
		_px(canvas, int(p.x + out), int(p.y + 1), barb)

func _draw_dusk_moth(canvas: Image, st: Dictionary) -> void:
	var o := Color("#221a36")
	var wing := _ramp(["#3a3470", "#5a5498", "#8a82c8", "#b8b0e8"])
	var fur := _ramp(["#a89078", "#d0bca0", "#f0e4cc", "#fffaf0"])
	var f: int = st.f
	var bob := roundi(sin(st.ph) * 1.2)
	var open: float = [1.0, 0.75, 0.35, 0.1, 0.45, 0.8][f]
	_shadow(canvas, Vector2(32, 47), Vector2(7, 2))
	if st.dir == SIDE:
		var ang := deg_to_rad([-105, -130, -160, 175, -150, -115][f])
		var root := Vector2(31, 24 + bob)
		_wing(canvas, root + Vector2(1, -1) + Vector2.from_angle(ang + 0.25) * 6.0, Vector2(8, 4.5), ang + 0.25, wing, false, false, o)
		var belly := _layer()
		_ellipse(belly, Vector2(26, 27 + bob), Vector2(7, 3.8), fur)
		for y in S:
			for x in range(19, 32):
				if belly.get_pixel(x, y).a > 0.0 and x % 3 == 0:
					belly.set_pixel(x, y, _darker(fur, belly.get_pixel(x, y)))
		_stamp(canvas, belly, o)
		_blob(canvas, Vector2(35, 25 + bob), Vector2(4.5, 4.5), fur, o)
		_feather_antenna(canvas, Vector2(36, 21 + bob), Vector2(41, 15 + bob), fur[0], fur[1])
		_eye(canvas, 36, 24 + bob, 2, 2, o)
		_px(canvas, 38, 27 + bob, BLUSH)
		_wing(canvas, root + Vector2.from_angle(ang) * 6.0, Vector2(8.5, 5), ang, wing, true, true, o)
		return
	var wx := 2.0 + 8.0 * open
	for side: int in [-1, 1]:
		_wing(canvas, Vector2(32 + side * (3 + wx * 0.7), 31 + bob), Vector2(wx * 0.7, 4.5), -side * 0.2, wing, side > 0, false, o)
	for side: int in [-1, 1]:
		_wing(canvas, Vector2(32 + side * (3 + wx), 23 + bob), Vector2(wx, 6.5), -side * 0.3, wing, side > 0, wx > 6.0, o)
	var body := _layer()
	_ellipse(body, Vector2(32, 29 + bob), Vector2(3.5, 6.5), fur)
	for y in range(26, 37):
		for x in S:
			if body.get_pixel(x, y + bob).a > 0.0 and y % 3 == 0:
				body.set_pixel(x, y + bob, _darker(fur, body.get_pixel(x, y + bob)))
	_stamp(canvas, body, o)
	_blob(canvas, Vector2(32, 21 + bob), Vector2(5, 4.5), fur, o)
	_feather_antenna(canvas, Vector2(30, 17 + bob), Vector2(26, 11 + bob), fur[0], fur[1])
	_feather_antenna(canvas, Vector2(33, 17 + bob), Vector2(37, 11 + bob), fur[0], fur[1])
	if st.dir == DOWN:
		_eye_pair(canvas, 32, 28, 20 + bob, 2, 3, o)
		_px(canvas, 28, 23 + bob, BLUSH)
		_px(canvas, 35, 23 + bob, BLUSH)
	else:
		for p: Vector2i in [Vector2i(30, 19), Vector2i(33, 18), Vector2i(31, 22), Vector2i(34, 21)]:
			_px(canvas, p.x, p.y + bob, fur[3])

# --- Dandelion Seed -----------------------------------------------------------------------------
# Floats straight to the Heartwood: a fluffy seed clock on a stalk, a tiny seed with a face below.

func _draw_dandelion_seed(canvas: Image, st: Dictionary) -> void:
	var o := Color("#5a6480")
	var fluff := _ramp(["#b8c4d8", "#dde6f0", "#ffffff"])
	var seed := _ramp(["#8a6440", "#b08858", "#d8b888"])
	var seed_o := Color("#3a2818")
	var f: int = st.f
	var bob := roundi(sin(st.ph) * 1.5)
	var sway := roundi(sin(st.ph + 1.0))
	var lean: int = -2 if st.dir == SIDE else 0
	_shadow(canvas, Vector2(32, 48), Vector2(5.0 - bob * 0.4, 1.5))
	var top := Vector2(32 + sway + lean, 19 + bob)
	var seed_c := Vector2(32, 34 + bob)
	_line(canvas, [top, seed_c + Vector2(0, -4)], Color("#c8b890"))
	# The clock: tufts in a ring (open at the bottom where the stalk is), filaments to the centre.
	var puff := _layer()
	var tips: Array[Vector2] = []
	for i in 13:
		var a := deg_to_rad(-235.0 + i * 24.0)
		tips.append(top + Vector2.from_angle(a) * Vector2(9.5, 8.5))
	for t in tips:
		_flat_ellipse(puff, t, Vector2(2.4, 2.2), fluff[1])
	for y in S:
		for x in S:
			if puff.get_pixel(x, y).a > 0.0 and y < top.y - 1:
				puff.set_pixel(x, y, fluff[2])
	for t in tips:
		_line(canvas, [top, top.lerp(t, 0.8)], Color("#e8eef6"))
	_stamp(canvas, puff, o)
	_px(canvas, int(top.x), int(top.y), seed[1])
	_px(canvas, int(top.x) - 1, int(top.y), seed[1])
	_blob(canvas, seed_c, Vector2(3.5, 4.5), seed, seed_o)
	match st.dir:
		DOWN:
			_eye_pair(canvas, 32, 30, 33 + bob, 1, 2, seed_o)
			_px(canvas, 30, 36 + bob, BLUSH)
			_px(canvas, 33, 36 + bob, BLUSH)
		SIDE:
			_eye(canvas, 33, 33 + bob, 1, 2, seed_o)
			_px(canvas, 34, 36 + bob, BLUSH)
	# A loose filament drifting away behind it.
	var t := float(f) / FRAMES
	var drift := top + (Vector2(-10 - t * 10, -2 - t * 6) if st.dir == SIDE else Vector2(8 + t * 6, 4 - t * 10))
	_px(canvas, roundi(drift.x), roundi(drift.y), fluff[2])
	_px(canvas, roundi(drift.x) + 1, roundi(drift.y), fluff[0])

# --- Puffcap ------------------------------------------------------------------------------------
# Splits into little puffcaps: a hopping mushroom with a spotted rosy cap. k scales it down.

func _draw_puffcap(canvas: Image, st: Dictionary) -> void:
	var k: float = st.k
	var o := Color("#3a1e24")
	var cap := _ramp(["#a8404a", "#d05a58", "#f08a74", "#ffb8a0"])
	var stem := _ramp(["#c8b090", "#e8d4b0", "#fff4dc"])
	var f: int = st.f
	var hop: float = [0.0, 2.0, 5.0, 6.0, 3.5, 1.0][f] * k
	var sq: Vector2 = [Vector2(1.12, 0.86), Vector2(0.94, 1.08), Vector2.ONE, Vector2.ONE, Vector2(0.96, 1.05), Vector2(1.06, 0.92)][f]
	var ground := 44.0
	var base := Vector2(32, ground - roundf(hop))
	var turn: float = {SIDE: 3.0, DOWN: 0.0, UP: -1.0}[st.dir] * k
	_shadow(canvas, Vector2(32, ground), Vector2(10.0 * k * (1.0 - hop * 0.04), 2.5 * k))
	var feet := _layer()
	for side: int in [-1, 1]:
		_flat_ellipse(feet, base + Vector2(side * 3.5 * sq.x + turn * 0.5, -1.0) * Vector2(k, k), Vector2(2.2, 1.6) * k, stem[1])
	_stamp(canvas, feet, o)
	var body_c := base + Vector2(0, -6.5 * k * sq.y)
	_blob(canvas, body_c, Vector2(6.5 * sq.x, 6.5 * sq.y) * k, stem, o)
	var cap_c := base + Vector2(0, -14.0 * k * sq.y)
	var cap_l := _layer()
	var cap_r := Vector2(13.5 * sq.x, 9.0 * sq.y) * k
	_ellipse(cap_l, cap_c, cap_r, cap, cap_c.y + 2.5 * k)
	for y in range(S - 1):
		for x in S:
			if cap_l.get_pixel(x, y).a > 0.0 and cap_l.get_pixel(x, y + 1).a == 0.0 and y > cap_c.y:
				cap_l.set_pixel(x, y, cap[0])
	var spots: Array = []
	for s: Vector2 in [Vector2(-6, -3), Vector2(1, -6), Vector2(7, -2), Vector2(-1, -1.5), Vector2(-10, 0)]:
		spots.append(cap_c + (s + Vector2(turn / k, 0)) * k)
	_spots(cap_l, spots, maxf(1.8 * k, 1.0), Color("#fff0d8"))
	_stamp(canvas, cap_l, o)
	if st.dir == UP:
		return
	var w := 2 if k > 0.8 else 1
	var ey := roundi(body_c.y - 1.0 * k)
	var ex := int(32.0 - 2.0 * k) - w
	var shift := roundi(turn)
	_eye(canvas, ex + shift, ey, w, 2, o)
	_eye(canvas, 64 - ex - w + shift, ey, w, 2, o)
	_px(canvas, ex - 1 + shift, ey + 2, BLUSH)
	_px(canvas, 64 - ex + shift, ey + 2, BLUSH)

# --- Mother Spider ------------------------------------------------------------------------------
# Releases spiderlings when cleansed: a round fuzzy plum spider with a heart on her back, big eyes
# and four little ones. k scales her down into a spiderling.

func _draw_mother_spider(canvas: Image, st: Dictionary) -> void:
	var k: float = st.k
	var thin := k < 0.7
	var o := Color("#1a0e22")
	var body := _ramp(["#3a2048", "#5a3468", "#7a4c8a", "#9a6aa8"])
	var mark := Color("#f0c8dc")
	var f: int = st.f
	var ph: float = st.ph
	var bob: float = 0.0 if thin else float([0, -1, 0, 0, -1, 0][f])
	var a := Vector2(32, 43)
	_shadow(canvas, a + Vector2(0, -1), Vector2(15, 3) * k)
	var abdomen := _layer()
	match st.dir:
		SIDE:
			for i in 4:  # far legs
				var s := sin(ph + i * PI + PI)
				var root := a + Vector2(-1 + i * 3, -10) * k + Vector2(0, bob)
				var foot := a + Vector2(-10 + i * 7 + s * 1.2, -2 - (1.0 if s > 0.5 else 0.0)) * k
				_line(canvas, [root, (root + foot) / 2 + Vector2(0, -8) * k, foot], o)
			var ac := a + Vector2(-8, -12) * k + Vector2(0, bob)
			_ellipse(abdomen, ac, Vector2(10, 8.5) * k, body)
			if not thin:
				_heart(abdomen, ac + Vector2(-1, -3) * k, k, mark)
			_stamp(canvas, abdomen, o)
			var hc := a + Vector2(7, -7) * k + Vector2(0, bob)
			_blob(canvas, hc, Vector2(6, 5.5) * k, body, o)
			for i in 4:  # near legs
				var s := sin(ph + i * PI)
				var root := a + Vector2(-3 + i * 3, -8) * k + Vector2(0, bob)
				var foot := a + Vector2(-13 + i * 8 + s * 1.5, -(1.0 if s > 0.5 else 0.0)) * k
				_leg(canvas, [root, (root + foot) / 2 + Vector2(0, -8) * k, foot], body[1], o, thin)
			var e := Vector2i(hc.round()) + Vector2i(roundi(2 * k), -1)
			if thin:
				_px(canvas, e.x, e.y, o)
			else:
				_eye(canvas, e.x, e.y, 2, 2, o)
				_px(canvas, e.x - 1, e.y - 2, o)
				_px(canvas, e.x + 1, e.y - 3, o)
				_px(canvas, e.x + 2, e.y + 3, BLUSH)
				_tuft(canvas, Vector2i(hc.round()) + Vector2i(-1, -6), body[3])
		DOWN, UP:
			var down: bool = st.dir == DOWN
			var hc := a + (Vector2(0, -6) if down else Vector2(0, -21)) * k + Vector2(0, bob)
			var ac := a + (Vector2(0, -16) if down else Vector2(0, -12)) * k + Vector2(0, bob)
			if not down:
				_blob(canvas, hc, Vector2(6, 5) * k, body, o)
				_tuft(canvas, Vector2i(hc.round()) + Vector2i(-1, -5), body[3])
			for i in 4:
				for side: int in [-1, 1]:
					var s := sin(ph + (i + (1 if side > 0 else 0)) * PI)
					var root := a + Vector2(side * 5, -15 + i * 2.5) * k + Vector2(0, bob)
					var foot := a + Vector2(side * (14 + i * 0.5) + s, -11 + i * 3.5 - (1.5 if s > 0.5 else 0.0)) * k
					_leg(canvas, [root, (root + foot) / 2 + Vector2(side * 2, -7) * k, foot], body[1], o, thin)
			_ellipse(abdomen, ac, Vector2(11, 9) * k, body)
			if not thin:
				_heart(abdomen, ac + Vector2(0, -2) * k, k, mark)
			_stamp(canvas, abdomen, o)
			if down:
				_blob(canvas, hc, Vector2(7, 6) * k, body, o)
				var ey := roundi(hc.y - 1)
				if thin:
					_eye_pair(canvas, 32, 30, ey, 1, 1, o)
				else:
					_eye_pair(canvas, 32, 28, ey, 2, 2, o)
					_px(canvas, 30, ey - 2, o)
					_px(canvas, 33, ey - 2, o)
					_px(canvas, 27, ey + 3, BLUSH)
					_px(canvas, 36, ey + 3, BLUSH)
					_px(canvas, 31, ey + 4, body[0])
					_px(canvas, 32, ey + 4, body[0])
					_tuft(canvas, Vector2i(hc.round()) + Vector2i(-1, -6), body[3])

func _heart(layer: Image, c: Vector2, k: float, color: Color) -> void:
	_spots(layer, [c + Vector2(-1.5, -1) * k, c + Vector2(1.5, -1) * k], 1.8 * k, color)
	for y in range(ceili(c.y), ceili(c.y + 3 * k)):
		var half := (c.y + 3 * k - y) * 0.9
		for x in range(floori(c.x - half), ceili(c.x + half)):
			if layer.get_pixel(x, y).a > 0.0:
				layer.set_pixel(x, y, color)

func _tuft(canvas: Image, p: Vector2i, color: Color) -> void:
	for q: Vector2i in [Vector2i(0, 0), Vector2i(1, -1), Vector2i(2, 0)]:
		_px(canvas, p.x + q.x, p.y + q.y, color)

# --- Hedgehog -----------------------------------------------------------------------------------
# Rolls on long straights: a round spiny back, a cream face with a button nose. "roll" is the
# curled-up ball, spinning clockwise (moving right; flip it for left).

func _draw_hedgehog(canvas: Image, st: Dictionary) -> void:
	var o := Color("#2a1a10")
	var spine := _ramp(["#4a3020", "#6a4a30", "#8a6a48", "#b0906a"])
	var face := _ramp(["#c8a880", "#e8cca0", "#fae8c8"])
	var f: int = st.f
	var ph: float = st.ph
	if st.anim == "roll":
		_hedgehog_roll(canvas, f, o, spine)
		return
	var bob: int = [0, -1, 0, 0, -1, 0][f]
	var step := roundi(sin(ph))
	match st.dir:
		SIDE:
			_shadow(canvas, Vector2(30, 43), Vector2(14, 3))
			_px(canvas, 25 - step, 41, o)
			_px(canvas, 37 + step, 41, o)
			_spines(canvas, Vector2(28, 35 + bob), Vector2(12, 9), -170, -10, spine, o, 39.5 + bob)
			for x: int in [22 + step, 23 + step, 35 - step, 36 - step]:
				_px(canvas, x, 42, o)
				_px(canvas, x, 41, face[0])
			_blob(canvas, Vector2(39, 38 + bob), Vector2(5.5, 4), face, o)
			_blob(canvas, Vector2(36, 34 + bob), Vector2(1.8, 1.8), face, o)
			_eye(canvas, 39, 36 + bob, 2, 2, o)
			_px(canvas, 41, 39 + bob, BLUSH)
			for p: Vector2i in [Vector2i(44, 37), Vector2i(45, 37), Vector2i(44, 38), Vector2i(45, 38)]:
				_px(canvas, p.x, p.y + bob, o)
		DOWN:
			_shadow(canvas, Vector2(32, 44), Vector2(13, 3))
			_spines(canvas, Vector2(32, 31 + bob), Vector2(12, 9), -175, -5, spine, o)
			for side: int in [-1, 1]:
				_blob(canvas, Vector2(32 + side * 5.5, 34 + bob), Vector2(1.8, 1.8), face, o)
			_blob(canvas, Vector2(32, 38 + bob), Vector2(6.5, 5), face, o)
			_eye_pair(canvas, 32, 28, 37 + bob, 2, 2, o)
			_px(canvas, 27, 40 + bob, BLUSH)
			_px(canvas, 36, 40 + bob, BLUSH)
			for p: Vector2i in [Vector2i(31, 40), Vector2i(32, 40), Vector2i(31, 41), Vector2i(32, 41)]:
				_px(canvas, p.x, p.y + bob, o)
			for x: int in [28, 29]:
				_px(canvas, x, 43 - (1 if step > 0 else 0), face[0])
				_px(canvas, 63 - x, 43 - (1 if step < 0 else 0), face[0])
		UP:
			_shadow(canvas, Vector2(32, 44), Vector2(13, 3))
			for x: int in [27, 28]:
				_px(canvas, x, 43 - (1 if step > 0 else 0), face[0])
				_px(canvas, 63 - x, 43 - (1 if step < 0 else 0), face[0])
			_spines(canvas, Vector2(32, 33 + bob), Vector2(12, 10), -180, 0, spine, o)

# Spiny dome: shaded body with spikes poking out along the arc between the two angles (degrees)
# and a streaky spine texture with pale tips.
func _spines(canvas: Image, c: Vector2, r: Vector2, from_deg: int, to_deg: int, ramp: Array[Color], o: Color, max_y: float = INF) -> void:
	var layer := _layer()
	_ellipse(layer, c, r, ramp, max_y)
	for a_deg in range(from_deg, to_deg + 1, 16):
		var a := deg_to_rad(a_deg)
		var out := Vector2(cos(a), sin(a))
		var edge := c + out * r * 0.92
		var perp := out.orthogonal()
		var tip := edge + out * 3.5 + Vector2(-1.5, 0)
		var tri := PackedVector2Array([edge - perp * 2.0, edge + perp * 2.0, tip])
		for y in range(floori(minf(edge.y, tip.y)) - 3, ceili(maxf(edge.y, tip.y)) + 3):
			for x in range(floori(minf(edge.x, tip.x)) - 3, ceili(maxf(edge.x, tip.x)) + 3):
				if x >= 0 and y >= 0 and x < S and y < S and y + 0.5 <= max_y \
						and Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), tri):
					layer.set_pixel(x, y, ramp[1])
	for y in S:
		for x in S:
			if layer.get_pixel(x, y).a == 0.0:
				continue
			var h := posmod(x + 2 * y, 5)
			if h == 0:
				layer.set_pixel(x, y, ramp[0])
			elif h == 2 and y % 2 == 0:
				layer.set_pixel(x, y, Color("#e8d4b0"))
	_stamp(canvas, layer, o)

func _hedgehog_roll(canvas: Image, f: int, o: Color, spine: Array[Color]) -> void:
	var c := Vector2(32, 35 + [0, -1, -2, -1, 0, 0][f])
	var rot := deg_to_rad(10.0 * f)
	_shadow(canvas, Vector2(32, 44), Vector2(10, 2.5))
	var ball := _layer()
	for i in 12:
		var a := rot + i * TAU / 12.0
		var out := Vector2.from_angle(a)
		var perp := out.orthogonal()
		var tri := PackedVector2Array([c + out * 8.5 - perp * 2.0, c + out * 8.5 + perp * 2.0, c + out * 12.0 + perp * 1.2])
		for y in S:
			for x in S:
				if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), tri):
					ball.set_pixel(x, y, spine[1])
	_ellipse(ball, c, Vector2(9.5, 9.5), spine)
	for y in S:
		for x in S:
			var d := Vector2(x + 0.5, y + 0.5) - c
			if ball.get_pixel(x, y).a == 0.0 or d.length() > 9.5:
				continue
			var stripe := posmod(floori((d.angle() - rot) / TAU * 24.0 + d.length() * 0.25), 3)
			if stripe == 0:
				ball.set_pixel(x, y, _darker(spine, ball.get_pixel(x, y)))
			elif stripe == 1 and d.length() > 6.0 and (x + y) % 2 == 0:
				ball.set_pixel(x, y, Color("#e8d4b0"))
	_stamp(canvas, ball, o)
	# Speed lines trailing behind.
	var streak := Color(1, 1, 1, 0.55)
	for l: Vector3i in [Vector3i(15, 30, 4), Vector3i(13, 36, 5), Vector3i(16, 41, 3)]:
		for x in range(l.x, l.x + l.z):
			if (x + f) % 3 != 0:
				_px(canvas, x - (f % 2), l.y, streak)

# --- Wandering Hare -----------------------------------------------------------------------------
# Takes wrong turns: a hopping hare with long ears (they trail the hop) and a daisy behind one ear.

func _draw_wandering_hare(canvas: Image, st: Dictionary) -> void:
	var o := Color("#2e2218")
	var fur := _ramp(["#7a6450", "#a08468", "#c4a888", "#e0ccb0"])
	var white := _ramp(["#d8d0c8", "#f0ece6", "#ffffff"])
	var pink := Color("#f0a8b0")
	var f: int = st.f
	var y: int = -[0, 2, 5, 6, 3, 0][f]
	var lag: int = [0, 1, 2, 1, -1, -1][f]
	var up := Vector2(0, y)
	_shadow(canvas, Vector2(30 if st.dir == SIDE else 32, 44), Vector2(12.0 + y * 0.6, 2.5))
	match st.dir:
		SIDE:
			_ear(canvas, Vector2(37, 26) + up, Vector2(30 - lag, 14 + lag) + up, 2.6, fur[0], fur[1], o, Color(0, 0, 0, 0))
			_blob(canvas, Vector2(18, 32) + up, Vector2(2.8, 2.6), white, o)
			_blob(canvas, Vector2(29, 35) + up, Vector2(10, 6.5), fur, o)
			var hind: Array = [[Vector2(21, 42), Vector2(28, 42)], [Vector2(16, 40), Vector2(21, 42)], [Vector2(15, 38), Vector2(21, 40)],
				[Vector2(17, 38), Vector2(23, 40)], [Vector2(21, 40), Vector2(27, 41)], [Vector2(21, 42), Vector2(28, 42)]][f]
			var fore: Array = [[Vector2(37, 39), Vector2(38, 42)], [Vector2(38, 38), Vector2(40, 41)], [Vector2(40, 36), Vector2(43, 38)],
				[Vector2(41, 37), Vector2(44, 39)], [Vector2(39, 38), Vector2(41, 41)], [Vector2(37, 39), Vector2(38, 42)]][f]
			var feet := _layer()
			_stroke(feet, [hind[0] + up * 0.5, hind[1] + up], 1.3, fur[1])
			_stamp(canvas, feet, o)
			_blob(canvas, Vector2(23, 36) + up, Vector2(5.5, 5.5), fur, o)
			var paw := _layer()
			_stroke(paw, [fore[0] + up, fore[1] + up], 1.1, fur[2])
			_stamp(canvas, paw, o)
			_blob(canvas, Vector2(39, 29) + up, Vector2(5.5, 5), fur, o)
			_blob(canvas, Vector2(43, 31) + up, Vector2(2.5, 2), white, o)
			_px(canvas, 45, 30 + y, pink)
			_eye(canvas, 39, 27 + y, 2, 2, o)
			_px(canvas, 38, 31 + y, BLUSH)
			_ear(canvas, Vector2(39, 25) + up, Vector2(34 - lag, 12 + lag) + up, 2.8, fur[2], fur[1], o, pink)
			_daisy(canvas, Vector2i(41, 24 + y))
		DOWN:
			var spread: int = 1 if y < -2 else 0
			for side: int in [-1, 1]:
				_blob(canvas, Vector2(32 + side * (7 + spread), 43 + y * 0.5), Vector2(3, 1.6), fur, o)
			_blob(canvas, Vector2(32, 37) + up, Vector2(9, 7.5), fur, o)
			for side: int in [-1, 1]:
				_blob(canvas, Vector2(32 + side * 3, 43) + up, Vector2(1.8, 1.5), white, o)
			for side: int in [-1, 1]:
				_ear(canvas, Vector2(32 + side * 3, 24) + up, Vector2(32 + side * 6, 11 + lag) + up, 2.8, fur[2], fur[1], o, pink)
			_blob(canvas, Vector2(32, 28) + up, Vector2(7, 6), fur, o)
			_blob(canvas, Vector2(32, 31) + up, Vector2(3, 2), white, o)
			_px(canvas, 31, 30 + y, pink)
			_px(canvas, 32, 30 + y, pink)
			_eye_pair(canvas, 32, 27, 27 + y, 2, 2, o)
			_px(canvas, 27, 31 + y, BLUSH)
			_px(canvas, 36, 31 + y, BLUSH)
			_daisy(canvas, Vector2i(37, 23 + y))
		UP:
			for side: int in [-1, 1]:
				_blob(canvas, Vector2(32 + side * 6, 44 + y * 0.5), Vector2(2.5, 1.6), fur, o)
			_blob(canvas, Vector2(32, 26) + up, Vector2(6.5, 5.5), fur, o)
			for side: int in [-1, 1]:
				_ear(canvas, Vector2(32 + side * 2.5, 22) + up, Vector2(32 + side * 5, 9 + lag) + up, 2.8, fur[2], fur[1], o, Color(0, 0, 0, 0))
			_daisy(canvas, Vector2i(35, 22 + y))
			_blob(canvas, Vector2(32, 36) + up, Vector2(9.5, 8), fur, o)
			_blob(canvas, Vector2(32, 42) + up, Vector2(3, 2.5), white, o)

# Long ear from base to tip, with an optional pink inner ear.
func _ear(canvas: Image, base: Vector2, tip: Vector2, width: float, lit: Color, dark: Color, o: Color, inner: Color) -> void:
	var layer := _layer()
	_lens(layer, base + (base - tip) * 0.1, tip, width, lit, dark)
	_stamp(canvas, layer, o)
	if inner.a > 0.0:
		var ins := _layer()
		_lens(ins, base.lerp(tip, 0.05), base.lerp(tip, 0.85), width * 0.45, inner, inner)
		_stamp(canvas, ins)

func _daisy(canvas: Image, p: Vector2i) -> void:
	for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		_px(canvas, p.x + d.x, p.y + d.y, Color("#fff8f0"))
	_px(canvas, p.x, p.y, Color("#ffd24a"))
