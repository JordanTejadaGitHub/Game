extends SceneTree
# Generates the nightmare (enemy) spritesheets in assets/creatures/ and a SpriteFrames resource per
# nightmare in animation/enemy/. Roster and art direction: documentation/enemy_design.md. Nightmares
# are dark, cold and partly translucent, glow only in their eyes or core, have one strong silhouette
# tied to their trait and move a little wrong (twitches, stop-start, gliding). Warm, cute Wardens vs
# cold nightmares is the game's core look. Each sheet has one row per animation (walk_side facing
# right, walk_down, walk_up, then extras such as the Night Hound's sprint, which the game still calls
# "roll") of FRAMES frames. Files keep the old creature names (see CREATURES) until the code renames
# them. The preview ends each row with a frame as shaders/blight.gdshader shows it in game.
# Run:  Godot --headless --path . --script res://tools/creature_art_generator.gd
# then once with --import so new sheets are imported (re-running afterwards adds their uids to the
# SpriteFrames; existing SpriteFrames keep their own uid, so references to them stay valid).

const FRAMES := 6
const OUT := "res://assets/creatures/"
const ANIM_OUT := "res://animation/enemy/"
const PREVIEW := "res://tools/creature_art_preview.png"
const PREVIEW_SCALE := 2
const WALKS := ["walk_side", "walk_down", "walk_up"]
enum { SIDE, DOWN, UP }

# fps: animation speed (extra_fps for the extra rows). draw: shared draw function (default: the
# file's own). k: size scale for the small ones spawned by splitters. size: frame size in px (default
# 64); bosses get bigger frames instead of a sprite_scale so their pixels match everyone else's.
const CREATURES := {
	"leaf_bug": {fps = 10.0},  # Shade
	"bark_beetle": {fps = 6.0},  # Husk
	"dusk_moth": {fps = 10.0},  # Lurker
	"dandelion_seed": {fps = 6.0},  # Phantom
	"puffcap": {fps = 6.0},  # Mourner
	"puffcaplet": {fps = 8.0, draw = "puffcap", k = 0.55},  # Sob
	"mother_spider": {fps = 9.0},  # Widow
	"spiderling": {fps = 14.0, draw = "mother_spider", k = 0.5},  # Creep
	"hedgehog": {fps = 9.0, extra = ["roll"], extra_fps = 14.0},  # Night Hound; "roll" = sprint
	"wandering_hare": {fps = 5.0},  # Sleepwalker
	"mother_duck": {fps = 6.0},  # Lantern Bearer
	"duckling": {fps = 7.0},  # Wraith
	"old_stag": {fps = 7.0, size = 112},  # The Hollow Stag
	"great_toad": {fps = 6.0, size = 144},  # The Mire Hag
}
# Defaults of shaders/blight.gdshader, for the in-game frame at the end of each preview row.
const SHADER_TRANSLUCENCY := 0.85
const SHADER_GLOW_START := 0.6
const SHADER_GLOW_STRENGTH := 0.5

# Shadow-stuff, lit from the upper right like the Wardens: [deep, dark, mid, rim].
const NIGHT := ["#0e0c18", "#1a1730", "#2a2646", "#3e3962"]
const NIGHT_O := Color("#05040a")
const HOLLOW := Color("#030206")
const EYE := Color("#dff8ff")  # cold glow
const EYE_HALO := Color(0.37, 0.72, 0.88, 0.55)
const SHADOW := Color(0.02, 0.02, 0.06, 0.38)
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

var light := Vector3(0.45, -0.55, 0.7).normalized()
var sheets: Array[Image] = []
var S := 64  # frame size of the nightmare being drawn

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
	S = info.get("size", 64)
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
	_save_sprite_frames(creature, anims, info.fps, info.get("extra_fps", info.fps))

# Writes animation/enemy/<creature>.tres: one AtlasTexture per frame, one looping animation per row.
func _save_sprite_frames(creature: String, anims: Array, fps: float, extra_fps: float) -> void:
	var path := ANIM_OUT + creature + ".tres"
	var png := OUT + creature + ".png"
	var uid := _read_uid(path, true)
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
		var speed := fps if row < WALKS.size() else extra_fps
		entries.append("{\n\"frames\": [%s],\n\"loop\": true,\n\"name\": &\"%s\",\n\"speed\": %s\n}" % [", ".join(frames), anims[row], str(speed)])
	text += "[resource]\nanimations = [%s]\n" % ", ".join(entries)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)

# header_only: look only at the first line, so a .tres doesn't pick up its texture's uid.
func _read_uid(path: String, header_only: bool = false) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var text := FileAccess.get_file_as_string(path)
	if header_only:
		text = text.get_slice("\n", 0)
	var found := RegEx.create_from_string("uid=\"(uid://[a-z0-9]+)\"").search(text)
	return found.get_string(1) if found else ""

# All sheets on grass in two columns, scaled up, for eyeballing. Each row ends with its first frame
# as the blight shader shows it in game.
func _save_preview() -> void:
	var pad := 6
	var cols := [[], []]
	var heights := [pad, pad]
	var widest := [0, 0]
	for sheet in sheets:
		var col := 0 if heights[0] <= heights[1] else 1
		cols[col].append(sheet)
		heights[col] += sheet.get_height() + (sheet.get_height() / _frame_size(sheet)) * pad
		widest[col] = maxi(widest[col], _frame_size(sheet))
	var block_w: Array[int] = [(FRAMES + 1) * (widest[0] + pad) + pad, (FRAMES + 1) * (widest[1] + pad) + pad]
	var preview := Image.create_empty(block_w[0] + block_w[1], maxi(heights[0], heights[1]), false, Image.FORMAT_RGBA8)
	preview.fill(Color("#5fa844"))
	for col in 2:
		var y := pad
		for sheet: Image in cols[col]:
			var s := _frame_size(sheet)
			var lit := _in_game(sheet)
			for row in sheet.get_height() / s:
				for f in FRAMES + 1:
					var src := sheet if f < FRAMES else lit
					var at := Vector2i(col * block_w[0] + pad + f * (s + pad), y)
					preview.blend_rect(src, Rect2i((f % FRAMES) * s, row * s, s, s), at)
				y += s + pad
	preview.resize(preview.get_width() * PREVIEW_SCALE, preview.get_height() * PREVIEW_SCALE, Image.INTERPOLATE_NEAREST)
	preview.save_png(PREVIEW)

func _frame_size(sheet: Image) -> int:
	return sheet.get_width() / FRAMES

# The sheet as the blight shader shows it in game at blight = 1 (without its shimmer): see-through
# body, the brightest pixels solid and brightened.
func _in_game(sheet: Image) -> Image:
	var out: Image = sheet.duplicate()
	for y in out.get_height():
		for x in out.get_width():
			var c := out.get_pixel(x, y)
			if c.a == 0.0:
				continue
			var lum := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
			var glow := smoothstep(SHADER_GLOW_START, 1.0, lum)
			var col := c * (1.0 + glow * SHADER_GLOW_STRENGTH)
			col.a = c.a * lerpf(SHADER_TRANSLUCENCY, 1.0, glow)
			out.set_pixel(x, y, col.clamp())
	return out

# --- Primitives -------------------------------------------------------------------------------

func _layer() -> Image:
	return Image.create_empty(S, S, false, Image.FORMAT_RGBA8)

func _px(canvas: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < S and y < S:
		canvas.set_pixel(x, y, color)

# Alpha-blends a colour over what's already there.
func _blend_px(canvas: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < S and y < S:
		canvas.set_pixel(x, y, canvas.get_pixel(x, y).blend(color))

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

func _blend_ellipse(canvas: Image, c: Vector2, r: Vector2, color: Color) -> void:
	for y in range(maxi(0, floori(c.y - r.y)), mini(S, ceili(c.y + r.y) + 1)):
		for x in range(maxi(0, floori(c.x - r.x)), mini(S, ceili(c.x + r.x) + 1)):
			if ((Vector2(x + 0.5, y + 0.5) - c) / r).length_squared() <= 1.0:
				_blend_px(canvas, x, y, color)

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

# Thick line of round dabs, for legs, arms, necks and antlers.
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

# Pointed at both ends, lit on the side facing the light. For ears, snouts, arms and limbs.
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

# Cold contact shadow on the ground, drawn before the nightmare.
func _shadow(canvas: Image, c: Vector2, r: Vector2) -> void:
	_flat_ellipse(canvas, c, r, SHADOW)

# A glowing eye: a bright core, optionally with a soft halo on its four sides.
func _glow(canvas: Image, p: Vector2i, core: Color = EYE, halo: Color = Color(0, 0, 0, 0)) -> void:
	if halo.a > 0.0:
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			_blend_px(canvas, p.x + d.x, p.y + d.y, halo)
	_px(canvas, p.x, p.y, core)

func _spots(layer: Image, pts: Array, r: float, color: Color) -> void:
	for p: Vector2 in pts:
		for y in range(floori(p.y - r), ceili(p.y + r) + 1):
			for x in range(floori(p.x - r), ceili(p.x + r) + 1):
				if x >= 0 and y >= 0 and x < S and y < S and layer.get_pixel(x, y).a > 0.0 \
						and Vector2(x + 0.5, y + 0.5).distance_to(p) <= r:
					layer.set_pixel(x, y, color)

# Ordered-dither test: keeps `amount` (0..1) of the pixels, evenly spread. `shift` moves the pattern.
func _keep(x: int, y: int, amount: float, shift: int = 0) -> bool:
	return amount > (BAYER[posmod(y + shift, 4) * 4 + posmod(x + shift * 3, 4)] + 0.5) / 16.0

# Fades a layer out from `from` to `to` (gone past `to`) by dropping pixels in a dither, so it
# dissolves into wisps instead of turning see-through.
func _dissolve(img: Image, from: Vector2, to: Vector2) -> void:
	var axis := to - from
	var len2 := axis.length_squared()
	for y in S:
		for x in S:
			if img.get_pixel(x, y).a > 0.0 and not _keep(x, y, 1.0 - (Vector2(x + 0.5, y + 0.5) - from).dot(axis) / len2):
				img.set_pixel(x, y, Color(0, 0, 0, 0))

# Blends a finished figure layer onto the canvas, optionally see-through and offset.
func _merge(canvas: Image, img: Image, alpha: float = 1.0, offset: Vector2i = Vector2i.ZERO) -> void:
	var src := img
	if alpha < 1.0:
		src = img.duplicate()
		for y in S:
			for x in S:
				var c := src.get_pixel(x, y)
				if c.a > 0.0:
					c.a *= alpha
					src.set_pixel(x, y, c)
	canvas.blend_rect(src, Rect2i(0, 0, S, S), offset)

# Smoke curling off a nightmare: puffs drifting from `origin` along `dir`, shrinking and fading.
func _wisps(canvas: Image, origin: Vector2, dir: Vector2, f: int, count: int = 3, reach: float = 9.0, size: float = 2.2) -> void:
	for k in count:
		var t := fposmod(float(f) / FRAMES + float(k) / count, 1.0)
		var p := origin + dir * t * reach + dir.orthogonal() * sin(t * TAU + k) * 1.5
		var r := size * (1.0 - t) + 0.6
		var col := Color(NIGHT[2])
		col.a = 0.8 * (1.0 - t)
		_blend_ellipse(canvas, p, Vector2(r, r), col)

# Hooded robe or veil from the shoulders (y0, half-width w0) to a ragged hem (y1, half-width w1),
# leaning `lean` px at the hem, with folds; the tatters sway with `ph`.
func _robe(layer: Image, cx: float, y0: float, w0: float, y1: float, w1: float, lean: float, ph: float, ramp: Array[Color]) -> void:
	for y in range(maxi(0, floori(y0)), mini(S, ceili(y1) + 3)):
		var t := clampf((y + 0.5 - y0) / (y1 - y0), 0.0, 1.0)
		var w := lerpf(w0, w1, sqrt(t))
		var mid := cx + lean * t
		for x in range(maxi(0, floori(mid - w) - 1), mini(S, ceili(mid + w) + 1)):
			var px := x + 0.5
			var u := (px - mid) / w
			if absf(u) > 1.0:
				continue
			var hem := y1 + sin(px * 0.8 + ph) * 1.5 + (2.0 if posmod(x, 5) == 0 else 0.0)
			if y + 0.5 > hem:
				continue
			var col := _shade(ramp, Vector3(u, -0.2, sqrt(maxf(1.0 - u * u, 0.0))).normalized())
			if posmod(roundi(px - mid + t * 2.0), 5) == 0 and absf(u) < 0.85 and t > 0.15:
				col = _darker(ramp, col)
			layer.set_pixel(x, y, col)

# Jagged cracks across a part (points in units of its radii from its centre), drawn in `color` on the
# part's own pixels. Returns the crack pixels in order, for something to move along inside them.
func _crack(layer: Image, c: Vector2, r: Vector2, polys: Array, color: Color) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for poly: Array in polys:
		for i in poly.size() - 1:
			var a: Vector2 = c + (poly[i] as Vector2) * r
			var b: Vector2 = c + (poly[i + 1] as Vector2) * r
			var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
			for s in steps + 1:
				var p := Vector2i(a.lerp(b, s / maxf(steps, 1.0)).round())
				if p.x >= 0 and p.y >= 0 and p.x < S and p.y < S and layer.get_pixelv(p).a > 0.0 and not out.has(p):
					layer.set_pixelv(p, color)
					out.append(p)
	return out

# A cold light crawling along crack pixels: something alive inside.
func _crawl(canvas: Image, pixels: Array[Vector2i], f: int, count: int = 2) -> void:
	var n := pixels.size()
	if n == 0:
		return
	for k in count:
		var i := (f * 3 + k * n / count) % n
		for j: int in [-1, 1]:
			if i + j >= 0 and i + j < n:
				_px(canvas, pixels[i + j].x, pixels[i + j].y, Color("#2e6478"))
		_px(canvas, pixels[i].x, pixels[i].y, Color("#a8ecff"))

# Little ragged tufts sticking up off a shadow's back.
func _ragged(canvas: Image, pts: Array, dy: int) -> void:
	for p: Vector2i in pts:
		_px(canvas, p.x, p.y + dy, NIGHT_O)
		_px(canvas, p.x + 1, p.y + dy - 1, NIGHT_O)

# --- Shade (leaf_bug) ---------------------------------------------------------------------------
# Common and quick: a small hunched shadow with two pinprick eyes. Scuttles, stops, twitches its
# head; smoke curls off its back.

func _draw_leaf_bug(canvas: Image, st: Dictionary) -> void:
	var body := _ramp(NIGHT)
	var f: int = st.f
	var ph: float = st.ph
	var bob: int = [0, 0, -1, 0, 0, -1][f]
	var twitch: int = [0, 0, 0, 1, 1, 0][f]
	var fig := _layer()
	_shadow(canvas, Vector2(32, 43), Vector2(11, 2.5))
	match st.dir:
		SIDE:
			_wisps(canvas, Vector2(24, 31 + bob), Vector2(-0.8, -0.6), f)
			for i in 4:
				var s := sin(ph + i * PI)
				var x := 25 + i * 4
				_line(fig, [Vector2(x, 38 + bob), Vector2(x + 1 + roundi(s * 1.5), 40 + bob), Vector2(x + roundi(s * 2.0), 43 - (1 if s > 0.5 else 0))], body[0])
			_ellipse(fig, Vector2(30, 35 + bob), Vector2(9, 6.5), body)
			_ellipse(fig, Vector2(37 + twitch, 37 + bob), Vector2(5, 4), body)
			_stamp(canvas, fig, NIGHT_O)
			_ragged(canvas, [Vector2i(24, 30), Vector2i(27, 29), Vector2i(30, 28), Vector2i(33, 29)], bob)
			_glow(canvas, Vector2i(38 + twitch, 36 + bob))
			_glow(canvas, Vector2i(40 + twitch, 36 + bob))
		DOWN, UP:
			var down: bool = st.dir == DOWN
			_wisps(canvas, Vector2(32, 28 + bob), Vector2(0.3, -1), f)
			for i in 2:
				for side: int in [-1, 1]:
					var s := sin(ph + (i + (1 if side > 0 else 0)) * PI)
					var y := 35 + i * 3 + bob
					_line(fig, [Vector2(32 + side * 6, y), Vector2(32 + side * (9 + i), y - 1), Vector2(32 + side * (10 + i) + roundi(s), 42 + i - (1 if s > 0.5 else 0))], body[0])
			_ellipse(fig, Vector2(32, 34 + bob), Vector2(9, 7), body)
			_ellipse(fig, Vector2(32 + twitch, 38 + bob if down else 29 + bob), Vector2(5.5, 4.5) if down else Vector2(4.5, 3.5), body)
			_stamp(canvas, fig, NIGHT_O)
			_ragged(canvas, [Vector2i(26, 29), Vector2i(30, 27), Vector2i(34, 27), Vector2i(37, 29)], bob)
			if down:
				_glow(canvas, Vector2i(30 + twitch, 38 + bob))
				_glow(canvas, Vector2i(33 + twitch, 38 + bob))

# --- Husk (bark_beetle) -------------------------------------------------------------------------
# Slow and sturdy: a hollow shell of dead bark on stubby legs. Something cold moves inside the
# cracks; two eyes watch from the dark opening at the front.

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
	var o := NIGHT_O
	var bark := _ramp(["#1c1818", "#2c2626", "#403834", "#564a42"])
	var f: int = st.f
	var ph: float = st.ph
	var bob: int = [0, 0, 0, -1, 0, 0][f]  # a heavy lurch, then still
	var sway: int = [0, 0, 1, 1, 0, 0][f]
	var shell := _layer()
	var snag := _layer()
	var cracks: Array[Vector2i] = []
	match st.dir:
		SIDE:
			_shadow(canvas, Vector2(31, 43), Vector2(17, 3))
			for i in 3:
				var s := sin(ph + i * PI + PI)
				_beetle_leg(canvas, Vector2(24 + i * 8, 37 + bob), Vector2(25 + i * 8 + roundi(s * 1.5), 41 - (1 if s > 0.5 else 0)), o)
			var c := Vector2(29, 34 + bob)
			var r := Vector2(15, 11)
			_ellipse(shell, c, r, bark, 38.5 + bob)
			_grooves(shell, c, r, bark, true)
			for x in S:
				for y: int in [37 + bob, 38 + bob]:
					if shell.get_pixel(x, y).a > 0.0:
						shell.set_pixel(x, y, bark[0])
			cracks = _crack(shell, c, r, [[Vector2(-0.8, -0.1), Vector2(-0.45, -0.45), Vector2(-0.1, -0.2), Vector2(0.25, -0.6), Vector2(0.5, -0.35)],
				[Vector2(-0.55, 0.3), Vector2(-0.1, 0.05), Vector2(0.3, 0.3), Vector2(0.75, 0.05)]], HOLLOW)
			_stamp(canvas, shell, o)
			_crawl(canvas, cracks, f)
			_twig(canvas, Vector2i(25, 24 + bob), bark[2])
			for i in 3:
				var s := sin(ph + i * PI)
				_beetle_leg(canvas, Vector2(21 + i * 8, 38 + bob), Vector2(21 + i * 8 + roundi(s * 1.5), 43 - (1 if s > 0.5 else 0)), bark[0])
			_stroke(snag, [Vector2(45, 34 + bob), Vector2(47, 30 + bob), Vector2(46, 27 + bob)], 1.1, bark[1])
			_stamp(canvas, snag, o)
			_blob(canvas, Vector2(45, 37 + bob), Vector2(5.5, 5), bark, o)
			_flat_ellipse(canvas, Vector2(46.5, 37.5 + bob), Vector2(3, 3.2), HOLLOW)
			_glow(canvas, Vector2i(46, 36 + bob))
			_glow(canvas, Vector2i(48, 37 + bob))
		DOWN, UP:
			var down: bool = st.dir == DOWN
			var cx := 32 + sway
			_shadow(canvas, Vector2(32, 44), Vector2(16, 3))
			if not down:
				_stroke(snag, [Vector2(cx, 18 + bob), Vector2(cx + 1, 15 + bob), Vector2(cx - 1, 12 + bob)], 1.1, bark[1])
				_stamp(canvas, snag, o)
				_blob(canvas, Vector2(cx, 20 + bob), Vector2(6, 4.5), bark, o)
			_beetle_side_legs(canvas, (26 if down else 27) + bob, cx, st, bark[0])
			var c := Vector2(cx, (29 if down else 32) + bob)
			var r := Vector2(14, 11 if down else 11.5)
			_ellipse(shell, c, r, bark)
			_grooves(shell, c, r, bark, false)
			for y in S:
				if shell.get_pixel(cx, y).a > 0.0:
					shell.set_pixel(cx, y, bark[0])
			cracks = _crack(shell, c, r, [[Vector2(-0.7, -0.3), Vector2(-0.3, -0.1), Vector2(-0.35, 0.4), Vector2(0.0, 0.7)],
				[Vector2(0.2, -0.8), Vector2(0.35, -0.3), Vector2(0.7, -0.1)]], HOLLOW)
			_stamp(canvas, shell, o)
			_crawl(canvas, cracks, f)
			_twig(canvas, Vector2i(cx + 3, (21 if down else 24) + bob), bark[2])
			if down:
				snag = _layer()
				_stroke(snag, [Vector2(cx, 36 + bob), Vector2(cx + 1, 32 + bob), Vector2(cx - 1, 30 + bob)], 1.1, bark[1])
				_stamp(canvas, snag, o)
				_blob(canvas, Vector2(cx, 39 + bob), Vector2(6.5, 5.5), bark, o)
				_flat_ellipse(canvas, Vector2(cx, 40 + bob), Vector2(4, 3.2), HOLLOW)
				_glow(canvas, Vector2i(cx - 2, 39 + bob))
				_glow(canvas, Vector2i(cx + 1, 39 + bob))

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

# A bare dead twig growing out of the bark at `p`.
func _twig(canvas: Image, p: Vector2i, color: Color) -> void:
	for q: Vector2i in [Vector2i(0, 0), Vector2i(0, -1), Vector2i(0, -2), Vector2i(-1, -3), Vector2i(-2, -4), Vector2i(1, -3),
			Vector2i(2, -4), Vector2i(2, -5)]:
		_px(canvas, p.x + q.x, p.y + q.y, color)

# --- Lurker (dusk_moth) -------------------------------------------------------------------------
# Fast, hidden in fog: a thin, long-limbed shape that's only half there. It flickers (the dither
# shifts every frame) and a band of it slips sideways now and then; only its eyes stay solid.

func _draw_dusk_moth(canvas: Image, st: Dictionary) -> void:
	var body := _ramp(["#16142a", "#24203e", "#36305a", "#4a4278"])
	var f: int = st.f
	var ph: float = st.ph
	var keep: float = [0.62, 0.5, 0.7, 0.38, 0.58, 0.46][f]
	var h := roundi(sin(ph))
	var step := sin(ph)
	var fig := _layer()
	_shadow(canvas, Vector2(32, 45), Vector2(6, 1.5))
	match st.dir:
		SIDE:
			_stroke(fig, [Vector2(31, 33 + h), Vector2(31 - step * 3, 39), Vector2(30 - step * 5, 45)], 0.8, body[0])
			_stroke(fig, [Vector2(34, 20 + h), Vector2(30, 27 + h), Vector2(27, 34 + h)], 0.7, body[0])
			_lens(fig, Vector2(36, 16 + h), Vector2(31, 36 + h), 3.4, body[2], body[1])
			_ellipse(fig, Vector2(37, 14 + h), Vector2(3, 4.5), body)
			_stroke(fig, [Vector2(31, 33 + h), Vector2(31 + step * 3, 39), Vector2(30 + step * 5, 45)], 0.8, body[1])
			_stroke(fig, [Vector2(35, 20 + h), Vector2(40, 24 + h), Vector2(45, 25 + h)], 0.7, body[1])
			for d: Vector2 in [Vector2(3, 1), Vector2(3, 3)]:
				_line(fig, [Vector2(45, 25 + h), Vector2(45, 25 + h) + d], body[1])
		DOWN, UP:
			var sway := step * 1.5
			for side: int in [-1, 1]:
				var s := step * side
				_stroke(fig, [Vector2(32 + side * 2, 35 + h), Vector2(32 + side * 3, 40 + s), Vector2(32 + side * 3, 45 - maxf(s, 0.0))], 0.8, body[1])
				_stroke(fig, [Vector2(32 + side * 3.5, 21 + h), Vector2(32 + side * 6 + sway, 30 + h), Vector2(32 + side * 7 + sway, 39 + h)], 0.7, body[1])
			_lens(fig, Vector2(32, 17 + h), Vector2(32, 37 + h), 3.8, body[2], body[1])
			_ellipse(fig, Vector2(32, 14 + h), Vector2(3.5, 5), body)
	var ghost := _layer()
	_stamp(ghost, fig, NIGHT_O)
	for y in S:
		for x in S:
			if ghost.get_pixel(x, y).a > 0.0 and not _keep(x, y, keep, f):
				ghost.set_pixel(x, y, Color(0, 0, 0, 0))
	if f == 1 or f == 3:  # a band of it slips sideways
		var band := ghost.get_region(Rect2i(0, 24, S, 3))
		ghost.fill_rect(Rect2i(0, 24, S, 3), Color(0, 0, 0, 0))
		ghost.blit_rect(band, Rect2i(0, 0, S, 3), Vector2i(2 if f == 1 else -2, 24))
	_merge(canvas, ghost, 0.9)
	match st.dir:
		SIDE:
			_glow(canvas, Vector2i(38, 13 + h), EYE, EYE_HALO)
		DOWN:
			_glow(canvas, Vector2i(30, 14 + h), EYE, EYE_HALO)
			_glow(canvas, Vector2i(33, 14 + h), EYE, EYE_HALO)

# --- Phantom (dandelion_seed) -------------------------------------------------------------------
# Glides through walls straight to the Heartwood: a pale floating veiled ghost with hollow eyes and
# mouth, arms reaching ahead, its tail streaming behind and a faint after-image where it just was.

func _draw_dandelion_seed(canvas: Image, st: Dictionary) -> void:
	var body := _ramp(["#5a7a98", "#86aac8", "#b6d8ee", "#e6f8ff"])
	var o := Color("#26384e")
	var f: int = st.f
	var ph: float = st.ph
	var h := roundi(sin(ph) * 2.0)
	_shadow(canvas, Vector2(32, 47), Vector2(6, 1.5))
	var fig := _layer()
	var ghost := _layer()
	var trail := Vector2i(-5, 0)  # after-image, only in side view (front/back it reads as a hood)
	match st.dir:
		SIDE:
			for i in range(12, 0, -1):
				var t := i / 12.0
				_ellipse(fig, Vector2(39 - i * 2.1, 23 + h + i * 0.8 + sin(ph - i * 0.55) * 1.6), Vector2.ONE * (6.5 * (1.0 - t) + 1.0), body)
			_ellipse(fig, Vector2(39, 22 + h), Vector2(7, 7), body)
			_lens(fig, Vector2(40, 27 + h), Vector2(49, 26 + h + roundi(sin(ph))), 1.8, body[2], body[1])
			_stamp(ghost, fig, o)
			_dissolve(ghost, Vector2(24, 0), Vector2(12, 0))
			_face_hole(ghost, 41, 19 + h, 2, 3)
			_face_hole(ghost, 43, 24 + h, 2, 2)
		DOWN, UP:
			trail = Vector2i.ZERO
			for i in range(12, 0, -1):
				var t := i / 12.0
				_ellipse(fig, Vector2(32 + sin(ph - i * 0.55) * 2.5 * t, 21 + h + i * 1.9), Vector2.ONE * (7.0 * (1.0 - t) + 1.0), body)
			_ellipse(fig, Vector2(32, 20 + h), Vector2(7.5, 7), body)
			for side: int in [-1, 1]:
				_lens(fig, Vector2(32 + side * 6, 25 + h), Vector2(32 + side * 12, 31 + h + roundi(sin(ph + side))), 1.6, body[2], body[1])
			_stamp(ghost, fig, o)
			_dissolve(ghost, Vector2(0, 36 + h), Vector2(0, 46 + h))
			if st.dir == DOWN:
				_face_hole(ghost, 28, 17 + h, 2, 3)
				_face_hole(ghost, 34, 17 + h, 2, 3)
				_face_hole(ghost, 31, 23 + h, 2, 3)
	if trail != Vector2i.ZERO:
		_merge(canvas, ghost, 0.22, trail)
	_merge(canvas, ghost, 0.82)

func _face_hole(canvas: Image, x: int, y: int, w: int, h: int) -> void:
	for dy in h:
		for dx in w:
			_px(canvas, x + dx, y + dy, HOLLOW)

# --- Mourner (puffcap) / Sob (puffcaplet) -------------------------------------------------------
# Breaks into 3 Sobs when dispelled: a veiled, weeping ghost, hood bowed over a dark face with
# sad glowing eyes and tears running. Its shoulders shake. k shrinks it into a Sob.

func _draw_puffcap(canvas: Image, st: Dictionary) -> void:
	var k: float = st.k
	var veil := _ramp(["#262c44", "#3e4764", "#5c6688", "#8089ac"])
	var o := Color("#0a0c18")
	var tear := Color("#8fdcff")
	var f: int = st.f
	var ph: float = st.ph
	var h := roundf(sin(ph) * 1.5 * k)
	var shake: int = [0, 1, 0, -1, 0, 0][f] if k > 0.8 else 0
	var ground := 45.0
	_shadow(canvas, Vector2(32, ground), Vector2(9, 2) * k)
	var top := ground - 36.0 * k + h
	var side_view: bool = st.dir == SIDE
	var fig := _layer()
	_robe(fig, 32.0, top + 8.0 * k, 6.0 * k, ground - 2.0 * k + h, 11.0 * k, -3.0 * k if side_view else 0.0, ph, veil)
	_ellipse(fig, Vector2(32.0 + (1.0 * k if side_view else 0.0), top + 8.0 * k), Vector2(7.0, 8.0) * k, veil)
	var ghost := _layer()
	_stamp(ghost, fig, o)
	_dissolve(ghost, Vector2(0, ground - 7.0 * k + h), Vector2(0, ground + 1.0 + h))
	if st.dir != UP:
		var fx := roundi(32.0 + (2.5 * k if side_view else 0.0))
		var hc := Vector2(fx, top + 9.0 * k)
		_flat_ellipse(ghost, hc, Vector2(4.5, 4.2) * k, HOLLOW)
		var ey := roundi(hc.y - 0.5 * k)
		var drop := ey + 5 + (f % 3) * 2
		if k > 0.8:
			for p: Vector2i in [Vector2i(fx - 3, ey), Vector2i(fx - 4, ey + 1), Vector2i(fx + 2, ey), Vector2i(fx + 3, ey + 1)]:
				_px(ghost, p.x, p.y, EYE)
			for tx: int in [fx - 4, fx + 3]:
				for ty in range(ey + 2, ey + 5):
					_px(ghost, tx, ty, tear)
				_px(ghost, tx, drop, tear)
		else:
			for tx: int in [fx - 2, fx + 1]:
				_px(ghost, tx, ey, EYE)
				_px(ghost, tx, ey + 1, tear)
				_px(ghost, tx, ey + 2 + f % 2, tear)
	_merge(canvas, ghost, 0.88, Vector2i(shake, 0))

# --- Widow (mother_spider) / Creep (spiderling) -------------------------------------------------
# Bursts into 6 Creeps when dispelled: a bloated many-legged shadow on thin spiked legs, a cluster
# of cold eyes, and something glowing through the veins of its swollen body. k shrinks it into a Creep.

func _draw_mother_spider(canvas: Image, st: Dictionary) -> void:
	var k: float = st.k
	var thin := k < 0.7
	var o := NIGHT_O
	var body := _ramp(["#0e0a16", "#1c1428", "#2c2040", "#40305a"])
	var f: int = st.f
	var ph: float = st.ph
	var bob: float = 0.0 if thin else float([0, -1, 0, 0, -1, 0][f])
	var a := Vector2(32, 43)
	var veins: Array = [[Vector2(-0.6, -0.4), Vector2(-0.2, -0.1), Vector2(0.0, -0.6)], [Vector2(0.1, 0.1), Vector2(0.5, -0.2), Vector2(0.7, 0.2)],
		[Vector2(-0.3, 0.5), Vector2(0.1, 0.3), Vector2(0.2, 0.6)]]
	_shadow(canvas, a + Vector2(0, -1), Vector2(15, 3) * k)
	var abdomen := _layer()
	var glow: Array[Vector2i] = []
	match st.dir:
		SIDE:
			for i in 4:  # far legs
				var s := sin(ph + i * PI + PI)
				var root := a + Vector2(-1 + i * 3, -10) * k + Vector2(0, bob)
				var foot := a + Vector2(-10 + i * 7 + s * 1.2, -2 - (1.0 if s > 0.5 else 0.0)) * k
				_line(canvas, [root, (root + foot) / 2 + Vector2(0, -10) * k, foot], o)
			var ac := a + Vector2(-8, -13) * k + Vector2(0, bob)
			_ellipse(abdomen, ac, Vector2(11, 9.5) * k, body)
			if not thin:
				glow = _crack(abdomen, ac, Vector2(11, 9.5) * k, veins, HOLLOW)
			_stamp(canvas, abdomen, o)
			_crawl(canvas, glow, f, 3)
			var hc := a + Vector2(6, -7) * k + Vector2(0, bob)
			_blob(canvas, hc, Vector2(5.5, 5) * k, body, o)
			for i in 4:  # near legs
				var s := sin(ph + i * PI)
				var root := a + Vector2(-3 + i * 3, -8) * k + Vector2(0, bob)
				var foot := a + Vector2(-13 + i * 8 + s * 1.5, -(1.0 if s > 0.5 else 0.0)) * k
				_spider_leg(canvas, [root, (root + foot) / 2 + Vector2(0, -10) * k, foot], o, thin)
			var e := Vector2i(hc.round()) + Vector2i(roundi(2 * k), -1)
			_glow(canvas, e)
			if not thin:
				for q: Vector2i in [Vector2i(2, 0), Vector2i(-1, -2), Vector2i(1, -2), Vector2i(3, 2)]:
					_glow(canvas, e + q)
		DOWN, UP:
			var down: bool = st.dir == DOWN
			var hc := a + (Vector2(0, -6) if down else Vector2(0, -22)) * k + Vector2(0, bob)
			var ac := a + (Vector2(0, -17) if down else Vector2(0, -12)) * k + Vector2(0, bob)
			if not down:
				_blob(canvas, hc, Vector2(6, 5) * k, body, o)
			for i in 4:
				for side: int in [-1, 1]:
					var s := sin(ph + (i + (1 if side > 0 else 0)) * PI)
					var root := a + Vector2(side * 5, -15 + i * 2.5) * k + Vector2(0, bob)
					var foot := a + Vector2(side * (15 + i * 0.5) + s, -11 + i * 3.5 - (1.5 if s > 0.5 else 0.0)) * k
					_spider_leg(canvas, [root, (root + foot) / 2 + Vector2(side * 2, -9) * k, foot], o, thin)
			_ellipse(abdomen, ac, Vector2(12, 10) * k, body)
			if not thin:
				glow = _crack(abdomen, ac, Vector2(12, 10) * k, veins, HOLLOW)
			_stamp(canvas, abdomen, o)
			_crawl(canvas, glow, f, 3)
			if down:
				_blob(canvas, hc, Vector2(6.5, 5.5) * k, body, o)
				var ey := roundi(hc.y - 1)
				if thin:
					_glow(canvas, Vector2i(30, ey))
					_glow(canvas, Vector2i(33, ey))
				else:
					for p: Vector2i in [Vector2i(29, ey), Vector2i(34, ey), Vector2i(30, ey - 2), Vector2i(33, ey - 2), Vector2i(27, ey - 1),
							Vector2i(36, ey - 1), Vector2i(31, ey + 2), Vector2i(32, ey + 2)]:
						_glow(canvas, p)

# Thin spiky leg: 2px dark for the Widow, 1px for a Creep.
func _spider_leg(canvas: Image, pts: Array, o: Color, thin: bool) -> void:
	_line(canvas, pts, o)
	if not thin:
		var shifted: Array = []
		for p: Vector2 in pts:
			shifted.append(p + Vector2.RIGHT)
		_line(canvas, shifted, o)

# --- Night Hound (hedgehog) ---------------------------------------------------------------------
# Sprints after 3 straight tiles: a long, lean shadow-dog with glowing eye slits and a smoking tail.
# "roll" is its sprint: stretched low, ears back, galloping, eyes streaking.

func _draw_hedgehog(canvas: Image, st: Dictionary) -> void:
	var body := _ramp(NIGHT)
	var o := NIGHT_O
	var f: int = st.f
	var ph: float = st.ph
	var fig := _layer()
	if st.anim == "roll":
		_hound_sprint(canvas, f, ph, body, o)
		return
	var bob: int = [0, -1, 0, 0, -1, 0][f]
	match st.dir:
		SIDE:
			_shadow(canvas, Vector2(31, 44), Vector2(16, 2.5))
			var far := _layer()
			_hound_leg(far, Vector2(40, 33 + bob), ph + PI, false, body[0])
			_hound_leg(far, Vector2(22, 33 + bob), ph, true, body[0])
			_stamp(canvas, far, o)
			_wisps(canvas, Vector2(10, 36 + bob), Vector2(-1, -0.4), f, 3, 7.0, 1.6)
			_stroke(fig, [Vector2(17, 30 + bob), Vector2(13, 33 + bob), Vector2(10, 37 + bob)], 1.3, body[1])
			_ellipse(fig, Vector2(30, 31 + bob), Vector2(11, 4.5), body)
			_ellipse(fig, Vector2(38, 31 + bob), Vector2(5, 5.5), body)
			_ellipse(fig, Vector2(21, 31 + bob), Vector2(5.5, 4.5), body)
			_stroke(fig, [Vector2(40, 29 + bob), Vector2(45, 25 + bob)], 2.5, body[2])
			_ellipse(fig, Vector2(46, 25 + bob), Vector2(4, 3.5), body)
			_lens(fig, Vector2(46, 26 + bob), Vector2(55, 28 + bob), 2.2, body[2], body[1])
			_lens(fig, Vector2(44, 24 + bob), Vector2(42, 16 + bob), 1.8, body[2], body[1])
			_lens(fig, Vector2(46, 23 + bob), Vector2(45, 16 + bob), 1.6, body[2], body[1])
			_hound_leg(fig, Vector2(38, 34 + bob), ph, false, body[1])
			_hound_leg(fig, Vector2(20, 34 + bob), ph + PI, true, body[1])
			for x: int in [28, 31, 34]:  # ribs under the skin
				_line(fig, [Vector2(x, 31 + bob), Vector2(x, 33 + bob)], body[0])
			_stamp(canvas, fig, o)
			_line(canvas, [Vector2(49, 28 + bob), Vector2(53, 28 + bob)], HOLLOW)
			_glow(canvas, Vector2i(47, 24 + bob), EYE, EYE_HALO)
			_px(canvas, 48, 24 + bob, EYE)
		DOWN:
			_shadow(canvas, Vector2(32, 44), Vector2(9, 2.5))
			_wisps(canvas, Vector2(32, 16), Vector2(0.2, -1), f, 3, 6.0, 1.6)
			for side: int in [-1, 1]:  # hind paws behind
				_ellipse(fig, Vector2(32 + side * 6, 39 + bob), Vector2(1.8, 2), body)
			_ellipse(fig, Vector2(32, 27 + bob), Vector2(6.5, 8.5), body)
			_ellipse(fig, Vector2(32, 33 + bob), Vector2(7, 4.5), body)
			for side: int in [-1, 1]:
				var s := sin(ph + (PI if side > 0 else 0.0))
				_stroke(fig, [Vector2(32 + side * 3, 36 + bob), Vector2(32 + side * 3, 44 - (1.5 if s > 0.3 else 0.0))], 1.0, body[1])
			_stamp(canvas, fig, o)
			var head := _layer()  # its own outline, so the ears and snout read against the body
			for side: int in [-1, 1]:
				_lens(head, Vector2(32 + side * 2, 33 + bob), Vector2(32 + side * 8, 26 + bob), 2.0, body[3], body[2])
			_ellipse(head, Vector2(32, 34 + bob), Vector2(4.5, 4), body)
			_lens(head, Vector2(32, 35 + bob), Vector2(32, 44 + bob), 2.4, body[3], body[2])
			_stamp(canvas, head, o)
			for x: int in [29, 30, 33, 34]:
				_glow(canvas, Vector2i(x, 33 + bob))
		UP:
			_shadow(canvas, Vector2(32, 44), Vector2(9, 2.5))
			for side: int in [-1, 1]:
				_ellipse(fig, Vector2(32 + side * 6, 30 + bob), Vector2(1.8, 2), body)
				_lens(fig, Vector2(32 + side * 1.5, 19 + bob), Vector2(32 + side * 6, 14 + bob), 1.8, body[2], body[1])
			_ellipse(fig, Vector2(32, 19 + bob), Vector2(4, 3.5), body)
			_lens(fig, Vector2(32, 18 + bob), Vector2(32, 12 + bob), 1.8, body[2], body[1])  # snout, pointing away
			_ellipse(fig, Vector2(32, 29 + bob), Vector2(6.5, 8.5), body)
			_ellipse(fig, Vector2(32, 37 + bob), Vector2(7, 4.5), body)
			for side: int in [-1, 1]:
				var s := sin(ph + (PI if side > 0 else 0.0))
				_stroke(fig, [Vector2(32 + side * 4, 39 + bob), Vector2(32 + side * 4, 45 - (1.5 if s > 0.3 else 0.0))], 1.0, body[1])
			_stroke(fig, [Vector2(32, 40 + bob), Vector2(33, 44 + bob), Vector2(32, 47 + bob)], 1.2, body[1])
			_stamp(canvas, fig, o)
			_wisps(canvas, Vector2(32, 48 + bob), Vector2(0.3, 1), f, 3, 6.0, 1.4)

# Leg from the shoulder or hip: two segments to a small paw; hind legs bend back at the hock.
func _hound_leg(layer: Image, top: Vector2, phase: float, hind: bool, color: Color) -> void:
	var swing := sin(phase) * 4.0
	var lift := 1.5 if cos(phase) > 0.3 else 0.0
	var paw := top + Vector2(swing, 10.0 - lift)
	var knee := top + Vector2(swing * 0.4 + (-2.0 if hind else 1.0), 5.0)
	_stroke(layer, [top, knee, paw], 1.0, color)
	_flat_ellipse(layer, paw + Vector2(1, 0), Vector2(1.5, 1), color)

func _hound_sprint(canvas: Image, f: int, ph: float, body: Array[Color], o: Color) -> void:
	var ext := sin(ph)  # 1 = legs stretched out, -1 = gathered under
	var lift := roundi(maxf(-ext, 0.0) * 2.0)
	var y := 35 - lift
	_shadow(canvas, Vector2(32, 44), Vector2(18, 2.5))
	for k in 3:  # smoke streaming off the back
		var t := fposmod(float(f) / FRAMES + k / 3.0, 1.0)
		var col := Color(NIGHT[2])
		col.a = 0.7 * (1.0 - t)
		_blend_ellipse(canvas, Vector2(14 - t * 12, y - 3 + k * 2), Vector2(3.0 - t * 2.0, 1.2), col)
	var fig := _layer()
	var gather := maxf(-ext, 0.0)
	for leg: Vector4 in [Vector4(41, 1, 0, 0), Vector4(22, -1, 1, 0)]:  # x, direction, hind?, unused
		var top := Vector2(leg.x, y + 2)
		var reach := ext * 7.0 * leg.y
		var paw := top + Vector2(reach + (4.0 * gather * -leg.y), 8.0 - absf(ext) * 3.0)
		_stroke(fig, [top, top.lerp(paw, 0.5) + Vector2(-leg.y * 1.5, 0.5), paw], 1.0, body[1])
		_stroke(fig, [top + Vector2(-2 * leg.y, 0), paw + Vector2(-3 * leg.y, -1)], 0.9, body[0])
	_stroke(fig, [Vector2(16, y - 1), Vector2(10, y - 1), Vector2(5, y)], 1.2, body[1])
	_ellipse(fig, Vector2(30, y), Vector2(14, 4), body)
	_ellipse(fig, Vector2(40, y), Vector2(5, 4.5), body)
	_stroke(fig, [Vector2(43, y - 1), Vector2(48, y - 2)], 2.3, body[2])
	_ellipse(fig, Vector2(49, y - 2), Vector2(4, 3.2), body)
	_lens(fig, Vector2(49, y - 1), Vector2(58, y), 2.0, body[2], body[1])
	_lens(fig, Vector2(48, y - 4), Vector2(41, y - 6), 1.6, body[2], body[1])
	_stamp(canvas, fig, o)
	for i in 4:  # eye streak
		_px(canvas, 50 - i, y - 3, [EYE, EYE, Color("#5fa8c8"), Color("#2e5a70")][i])

# --- Sleepwalker (wandering_hare) ---------------------------------------------------------------
# Sometimes takes a wrong turn: a drifting figure in a pale gown, eyes closed, arms held out in
# front, head lolling. It floats, never quite walking.

func _draw_wandering_hare(canvas: Image, st: Dictionary) -> void:
	var gown := _ramp(["#322e48", "#4c466a", "#6c6690", "#948eb8"])
	var skin := _ramp(["#58546e", "#7a7694", "#a09cb8"])
	var hair := Color("#0c0a14")
	var o := Color("#100e1a")
	var f: int = st.f
	var ph: float = st.ph
	var h := roundi(sin(ph) * 1.5)
	var loll: int = [0, 0, 1, 1, 1, 0][f]
	var side_view: bool = st.dir == SIDE
	_shadow(canvas, Vector2(32, 45), Vector2(7, 2))
	var fig := _layer()
	var hx := 32 + (1 if side_view else 0) + loll
	if side_view:
		_stroke(fig, [Vector2(33, 19 + h), Vector2(43, 18 + h)], 1.0, skin[0])
	_robe(fig, 32.0, 21.0 + h, 4.0, 43.0 + h, 8.0, -2.0 if side_view else 0.0, ph, gown)
	_ellipse(fig, Vector2(hx, 15 + h), Vector2(4.5, 5), skin)
	match st.dir:
		SIDE:
			_stroke(fig, [Vector2(34, 21 + h), Vector2(40, 21 + h), Vector2(45, 21 + h)], 1.0, skin[1])
			_flat_ellipse(fig, Vector2(46, 21 + h), Vector2(1.6, 1.4), skin[2])
		DOWN:
			for side: int in [-1, 1]:
				_ellipse(fig, Vector2(32 + side * 4, 22 + h), Vector2(2, 2), gown)
				_flat_ellipse(fig, Vector2(32 + side * 5, 25 + h), Vector2(1.8, 1.6), skin[2])
	var ghost := _layer()
	_stamp(ghost, fig, o)
	# Long dark hair: a cap over the head, strands down to the shoulders (all over the back from behind).
	if st.dir == UP:
		_flat_ellipse(ghost, Vector2(hx, 15 + h), Vector2(5, 5.5), hair)
		for x in range(hx - 4, hx + 5, 2):
			_line(ghost, [Vector2(x, 18 + h), Vector2(x + roundi(sin(ph + x) * 0.8), 25 + h)], hair)
	else:
		_flat_ellipse(ghost, Vector2(hx - (1 if side_view else 0), 12 + h), Vector2(4.8, 2.6), hair)
		for x: int in ([hx - 4] if side_view else [hx - 5, hx + 4]):
			_line(ghost, [Vector2(x, 12 + h), Vector2(x, 22 + h)], hair)
	_dissolve(ghost, Vector2(0, 37 + h), Vector2(0, 46 + h))
	match st.dir:
		DOWN:
			for p: Vector2i in [Vector2i(hx - 4, 16), Vector2i(hx - 3, 17), Vector2i(hx - 2, 16), Vector2i(hx + 1, 16), Vector2i(hx + 2, 17), Vector2i(hx + 3, 16)]:
				_px(ghost, p.x, p.y + h, o)
			_px(ghost, hx, 19 + h, o)
		SIDE:
			_px(ghost, hx + 2, 16 + h, o)
			_px(ghost, hx + 3, 16 + h, o)
	_merge(canvas, ghost, 0.8)

# --- Lantern Bearer (mother_duck) ---------------------------------------------------------------
# Leads a Procession of 4 Wraiths: a tall hooded ghost with one long arm holding out a cold
# swinging lantern. Its light pools on the ground; one eye glints under the hood.

func _draw_mother_duck(canvas: Image, st: Dictionary) -> void:
	var robe := _ramp(["#141222", "#221e36", "#322c4c", "#463e66"])
	var o := NIGHT_O
	var f: int = st.f
	var ph: float = st.ph
	var h := roundi(sin(ph))
	var swing := sin(ph + 0.8) * 2.5
	var ground := 45.0
	_shadow(canvas, Vector2(32, ground), Vector2(9, 2.2))
	var fig := _layer()
	var lantern := Vector2.ZERO
	var hand := Vector2.ZERO
	match st.dir:
		SIDE:
			_robe(fig, 33.0, 17.0 + h, 4.5, ground - 1.0 + h, 9.0, -3.0, ph, robe)
			_ellipse(fig, Vector2(34, 13 + h), Vector2(4.5, 5.5), robe)
			_lens(fig, Vector2(34, 11 + h), Vector2(31, 4 + h), 2.2, robe[2], robe[1])
			hand = Vector2(45, 24 + h)
			_stroke(fig, [Vector2(36, 19 + h), Vector2(41, 23 + h), hand], 1.1, robe[2])
			lantern = Vector2(45 + swing, 31 + h)
		DOWN:
			_robe(fig, 32.0, 17.0 + h, 5.0, ground - 1.0 + h, 10.0, 0.0, ph, robe)
			_ellipse(fig, Vector2(32, 12 + h), Vector2(5, 6), robe)
			_lens(fig, Vector2(32, 9 + h), Vector2(32, 2 + h), 2.2, robe[2], robe[1])
			hand = Vector2(39, 27 + h)
			_stroke(fig, [Vector2(36, 19 + h), Vector2(39, 24 + h), hand], 1.1, robe[2])
			lantern = Vector2(39 + swing * 0.4, 32 + h)
		UP:
			lantern = Vector2(42 + swing * 0.4, 30 + h)
			_lantern(canvas, lantern, f, ground)
			_robe(fig, 32.0, 17.0 + h, 5.0, ground - 1.0 + h, 10.0, 0.0, ph, robe)
			_ellipse(fig, Vector2(32, 12 + h), Vector2(5, 6), robe)
			_lens(fig, Vector2(32, 9 + h), Vector2(32, 2 + h), 2.2, robe[2], robe[1])
			_stroke(fig, [Vector2(36, 19 + h), Vector2(40, 24 + h)], 1.1, robe[2])
	var ghost := _layer()
	_stamp(ghost, fig, o)
	_dissolve(ghost, Vector2(0, ground - 7.0 + h), Vector2(0, ground + 1.0 + h))
	match st.dir:
		SIDE:
			_flat_ellipse(ghost, Vector2(36, 14 + h), Vector2(2.5, 3), HOLLOW)
			_px(ghost, 37, 13 + h, EYE)
		DOWN:
			_flat_ellipse(ghost, Vector2(32, 13 + h), Vector2(3, 3.2), HOLLOW)
			_px(ghost, 30, 13 + h, EYE)
			_px(ghost, 33, 13 + h, EYE)
	_merge(canvas, ghost, 0.92)
	if st.dir != UP:
		_line(canvas, [hand, lantern + Vector2(0, -4)], Color("#4a4a5a"))
		_lantern(canvas, lantern, f, ground)

# A cold lantern: dark cap and base, glowing glass, a flickering halo and light pooled on the ground.
func _lantern(canvas: Image, p: Vector2, f: int, ground: float) -> void:
	var halo_r: float = [6.0, 6.5, 5.5, 6.5, 6.0, 7.0][f]
	_blend_ellipse(canvas, Vector2(p.x, ground), Vector2(8, 2.5), Color(0.55, 0.9, 1.0, 0.14))
	for y in range(floori(p.y - halo_r), ceili(p.y + halo_r) + 1):
		for x in range(floori(p.x - halo_r), ceili(p.x + halo_r) + 1):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(p)
			if d > 2.5 and d < halo_r and (x + y + f) % 2 == 0:
				_blend_px(canvas, x, y, Color(0.45, 0.8, 0.95, 0.35 * (1.0 - d / halo_r)))
	var q := Vector2i(p.round())
	var metal := Color("#2a2a38")
	_px(canvas, q.x, q.y - 4, metal)
	for x in range(q.x - 1, q.x + 2):
		_px(canvas, x, q.y - 3, metal)
	for y in range(q.y - 2, q.y + 2):
		_px(canvas, q.x - 2, y, metal)
		_px(canvas, q.x + 2, y, metal)
		for x in range(q.x - 1, q.x + 2):
			_px(canvas, x, y, EYE)
	_px(canvas, q.x, q.y - 1, Color.WHITE)
	_px(canvas, q.x, q.y, Color.WHITE)
	for x in range(q.x - 2, q.x + 3):
		_px(canvas, x, q.y + 2, metal)

# --- Wraith (duckling) --------------------------------------------------------------------------
# Follows the Lantern Bearer in single file: a small hunched hooded wisp, head bowed, two faint
# eyes under the hood. Every so often its head jerks.

func _draw_duckling(canvas: Image, st: Dictionary) -> void:
	var robe := _ramp(["#141222", "#221e36", "#322c4c", "#463e66"])
	var f: int = st.f
	var ph: float = st.ph
	var h := roundi(sin(ph))
	var twitch: int = [0, 0, 0, 0, 1, 0][f]
	var side_view: bool = st.dir == SIDE
	_shadow(canvas, Vector2(32, 45), Vector2(6, 1.8))
	var fig := _layer()
	var fx := 32 + (2 if side_view else 0) + twitch
	_robe(fig, 32.0, 31.0 + h, 3.5, 44.0 + h, 6.5, -2.0 if side_view else 0.0, ph, robe)
	_ellipse(fig, Vector2(32 + (1 if side_view else 0) + twitch, 29 + h), Vector2(4, 4.5), robe)
	var ghost := _layer()
	_stamp(ghost, fig, NIGHT_O)
	_dissolve(ghost, Vector2(0, 39 + h), Vector2(0, 46 + h))
	if st.dir != UP:
		_flat_ellipse(ghost, Vector2(fx, 30.5 + h), Vector2(2.4, 2.2), HOLLOW)
		for x: int in ([fx + 1] if side_view else [fx - 2, fx + 1]):
			_px(ghost, x, 30 + h, Color("#a8c8ff"))
	_merge(canvas, ghost, 0.85)

# --- The Hollow Stag (old_stag) -----------------------------------------------------------------
# Act 1 boss, tramples Thornwalls: a gaunt stag of dead bark and bone, a skull for a face with
# cold eyes in its sockets, ribs open around a ghost-fire heart, and ghost-fire burning in its
# antlers. Drawn on a 112px frame.

func _draw_old_stag(canvas: Image, st: Dictionary) -> void:
	var o := NIGHT_O
	var bark := _ramp(["#1a1616", "#2a2424", "#3e3632", "#54483e"])
	var bone := _ramp(["#8a8478", "#b8b0a0", "#e0d8c6"])
	var f: int = st.f
	var ph: float = st.ph
	var bob: int = [0, -1, -1, 0, -1, -1][f]
	var nod: int = [0, 0, 1, 1, 0, 0][f]
	match st.dir:
		SIDE:
			_shadow(canvas, Vector2(56, 77), Vector2(30, 4))
			_deer_leg(canvas, Vector2(43, 57 + bob), ph + PI, bark[0], o)
			_deer_leg(canvas, Vector2(67, 57 + bob), ph, bark[0], o)
			var body := _layer()
			var c := Vector2(55, 50 + bob)
			var r := Vector2(22, 10)
			_ellipse(body, c, r, bark)
			_grooves(body, c, r, bark, true)
			var ribs: Array[Vector2i] = []
			for y in S:
				for x in S:
					if body.get_pixel(x, y).a == 0.0:
						continue
					var d := (Vector2(x + 0.5, y + 0.5) - c) / r
					if d.x > -0.05 and d.x < 0.6 and d.y > -0.35 and d.y < 0.75:
						var rib := posmod(x, 4) == 0
						body.set_pixel(x, y, bone[1] if rib else HOLLOW)
						if not rib:
							ribs.append(Vector2i(x, y))
			_stamp(canvas, body, o)
			_heart_fire(canvas, c + Vector2(r.x * 0.3, r.y * 0.2), f)
			_blob(canvas, Vector2(33, 44 + bob), Vector2(2, 2.5), bark, o)
			_deer_leg(canvas, Vector2(40, 58 + bob), ph, bark[1], o)
			_deer_leg(canvas, Vector2(70, 58 + bob), ph + PI, bark[1], o)
			var neck := _layer()
			_stroke(neck, [Vector2(68, 50 + bob), Vector2(76, 43 + bob + nod), Vector2(81, 38 + bob + nod)], 5.0, bark[2])
			_stamp(canvas, neck, o)
			for i in 4:  # dead bark hanging off the neck
				var x := 68 + i * 3
				_line(canvas, [Vector2(x, 47 + bob - i * 2 + nod), Vector2(x - 1, 53 + bob - i * 2 + nod)], bark[0])
			var hd := Vector2(84, 37 + bob + nod)
			_bone_antler(canvas, hd + Vector2(-5, -5), -1.0, 0.85, bone, o, f, false)
			_blob(canvas, hd, Vector2(6.5, 5.5), bone, o)
			_blob(canvas, hd + Vector2(7, 3), Vector2(4.5, 2.8), bone, o)
			_flat_ellipse(canvas, hd + Vector2(0.5, -1), Vector2(2.2, 2.4), HOLLOW)
			_glow(canvas, Vector2i(hd) + Vector2i(1, -1), EYE, EYE_HALO)
			_px(canvas, int(hd.x) + 10, int(hd.y) + 2, HOLLOW)
			_line(canvas, [hd + Vector2(3, 2), hd + Vector2(5, 5)], bone[0])
			_bone_antler(canvas, hd + Vector2(-2, -5), -1.0, 1.0, bone, o, f, true)
		DOWN, UP:
			var down: bool = st.dir == DOWN
			_shadow(canvas, Vector2(56, 77), Vector2(20, 4))
			for side: int in [-1, 1]:
				_deer_leg(canvas, Vector2(56 + side * 11, 60 + bob), ph + (PI if side > 0 else 0.0), bark[0], o, true)
			var body := _layer()
			var c := Vector2(56, 55 + bob)
			_ellipse(body, c, Vector2(15, 12), bark)
			_grooves(body, c, Vector2(15, 12), bark, false)
			if down:  # the open ribcage
				for y in S:
					for x in S:
						var d := (Vector2(x + 0.5, y + 0.5) - c - Vector2(0, 3)) / Vector2(8, 7)
						if body.get_pixel(x, y).a > 0.0 and d.length() < 1.0:
							body.set_pixel(x, y, bone[1] if posmod(y, 3) == 0 and absf(d.x) > 0.2 else HOLLOW)
			_stamp(canvas, body, o)
			if down:
				_heart_fire(canvas, c + Vector2(0, 3), f)
			for side: int in [-1, 1]:
				_deer_leg(canvas, Vector2(56 + side * 6, 62 + bob), ph + (0.0 if side > 0 else PI), bark[1], o, true)
			var neck := _layer()
			_ellipse(neck, Vector2(56, 45 + bob), Vector2(7.5, 8), bark)
			_stamp(canvas, neck, o)
			var hd := Vector2(56, 37 + bob + nod)
			if not down:
				for side: int in [-1, 1]:
					_bone_antler(canvas, hd + Vector2(side * 3, -6), side, 1.0, bone, o, f, true)
			_blob(canvas, hd, Vector2(6.5, 8), bark if not down else bone, o)
			if down:
				_blob(canvas, hd + Vector2(0, 7), Vector2(4, 3.5), bone, o)
				for side: int in [-1, 1]:
					_flat_ellipse(canvas, hd + Vector2(side * 3, -1), Vector2(2, 2.4), HOLLOW)
					_glow(canvas, Vector2i(hd.round()) + Vector2i(side * 3 - (1 if side < 0 else 0), -1), EYE, EYE_HALO)
				for x in range(54, 58):
					_px(canvas, x, int(hd.y) + 8, HOLLOW)
				for side: int in [-1, 1]:
					_bone_antler(canvas, hd + Vector2(side * 3, -6), side, 1.0, bone, o, f, true)

# Leg from `top`: upper leg, knee, shin and a dark hoof. The swing follows `phase`; the foot lifts
# while it moves forward. `straight` is for front/back views (the leg lifts instead of swinging).
func _deer_leg(canvas: Image, top: Vector2, phase: float, color: Color, o: Color, straight: bool = false) -> void:
	var s := sin(phase)
	var lift := 2.0 if cos(phase) > 0.3 else 0.0
	var swing := 0.0 if straight else s * 4.0
	var hoof := top + Vector2(swing, 19.0 - lift)
	var layer := _layer()
	_stroke(layer, [top, top + Vector2(swing * 0.3 + (0.0 if straight else 1.5), 10.0 - lift * 0.5), hoof], 1.8, color)
	_stamp(canvas, layer, o)
	for dx in range(-1, 2):
		_px(canvas, int(hoof.x) + dx, int(hoof.y) + 1, o)

# One bone antler from its root on the head: a beam curving out (`sx` = -1 left, 1 right) and up,
# with tines; `burning` puts ghost-fire on the tips. `scale` shrinks the far antler in side view.
func _bone_antler(canvas: Image, root: Vector2, sx: float, scale: float, ramp: Array[Color], o: Color, f: int, burning: bool) -> void:
	var m := Vector2(sx, 1.0) * scale
	var beam: Array = [Vector2(0, 0), Vector2(3, -8), Vector2(7, -15), Vector2(13, -20), Vector2(18, -27)]
	var tines: Array = [[Vector2(1, -4), Vector2(7, -5)], [Vector2(4, -11), Vector2(2, -20)],
		[Vector2(8, -16), Vector2(8, -25)], [Vector2(13, -20), Vector2(21, -19)]]
	var layer := _layer()
	var pts: Array = []
	for p: Vector2 in beam:
		pts.append(root + p * m)
	_stroke(layer, pts, 1.7 * scale, ramp[1] if burning else ramp[0])
	for t: Array in tines:
		_stroke(layer, [root + t[0] * m, root + t[1] * m], 1.2 * scale, ramp[1] if burning else ramp[0])
	if burning:
		for y in S:
			for x in S:
				if layer.get_pixel(x, y).a > 0.0 and (x + 1 >= S or layer.get_pixel(x + 1, y).a == 0.0):
					layer.set_pixel(x, y, ramp[2])
	_stamp(canvas, layer, o)
	if burning:
		for i in 3:
			var tip: Vector2 = [Vector2(18, -27), Vector2(8, -25), Vector2(2, -20)][i]
			_ghost_fire(canvas, root + tip * m, f + i * 2)

# A flickering tongue of cold ghost-fire rising from `p`.
func _ghost_fire(canvas: Image, p: Vector2, f: int) -> void:
	var height: float = [5.0, 7.0, 4.5, 6.5, 5.5, 7.5][f % FRAMES]
	for layer_i in 2:
		var col := Color(0.25, 0.72, 0.8, 0.85) if layer_i == 0 else Color("#d8ffff")
		var r0 := 2.2 if layer_i == 0 else 1.0
		for s in 10:
			var t := s / 9.0
			var c := p + Vector2(sin(f * 1.7 + t * 4.0) * t * 1.2, -t * height * (1.0 if layer_i == 0 else 0.6))
			var rr := r0 * (1.0 - t) + 0.3
			if layer_i == 0:
				_blend_ellipse(canvas, c, Vector2(rr, rr), col)
			else:
				_flat_ellipse(canvas, c, Vector2(rr, rr), col)

# The cold fire in its chest, pulsing.
func _heart_fire(canvas: Image, c: Vector2, f: int) -> void:
	var r: float = [1.6, 2.0, 2.4, 2.0, 1.6, 1.4][f]
	_blend_ellipse(canvas, c, Vector2(r + 2.0, r + 2.0), Color(0.3, 0.75, 0.85, 0.35))
	_flat_ellipse(canvas, c, Vector2(r, r), Color("#8ff0f0"))
	_px(canvas, int(c.x), int(c.y), Color.WHITE)

# --- The Mire Hag (great_toad) ------------------------------------------------------------------
# Act 2 boss, sinks into the mire and rises 3 tiles ahead: a bent bog witch wading waist-deep in a
# pool of black water, wrapped in reeds, long wet hair down her back, a crooked staff and a long
# clawed hand reaching ahead; her eyes glow a sickly cold green. Drawn on a 144px frame.

func _draw_great_toad(canvas: Image, st: Dictionary) -> void:
	var o := Color("#040506")
	var robe := _ramp(["#0e1210", "#18201a", "#243026", "#324236"])
	var skin := _ramp(["#3a4a40", "#566a5a", "#7a8e7c"])
	var hair := _ramp(["#080c0a", "#121a14", "#1e2a20"])
	var reed := Color("#3e5230")
	var wood := Color("#2a2018")
	var eye := Color("#c8ffe8")
	var eye_halo := Color(0.4, 0.9, 0.7, 0.5)
	var f: int = st.f
	var ph: float = st.ph
	var b: int = [0, 1, 2, 1, 0, -1][f]
	var ground := 97.0
	_mire(canvas, Vector2(70, ground), f, false)
	var fig := _layer()
	match st.dir:
		SIDE:
			var staff := _layer()
			_stroke(staff, [Vector2(55, 30 + b), Vector2(53, 60 + b), Vector2(56, ground)], 1.6, wood)
			_stroke(staff, [Vector2(55, 30 + b), Vector2(51, 25 + b), Vector2(54, 21 + b)], 1.4, wood)
			_stamp(canvas, staff, o)
			_ellipse(fig, Vector2(66, 67 + b), Vector2(18, 26), robe, ground)
			_ellipse(fig, Vector2(62, 52 + b), Vector2(15, 13), robe)
			_reed_bands(fig, [[Vector2(48, 62), Vector2(82, 54)], [Vector2(47, 76), Vector2(84, 68)], [Vector2(50, 88), Vector2(84, 82)]], b, reed)
			_stamp(canvas, fig, o)
			_hag_hair(canvas, [Vector2(80, 30), Vector2(84, 29), Vector2(88, 30), Vector2(91, 32)], Vector2(-26, 48), ph, b, hair, o)
			var sleeve := _layer()
			_ellipse(sleeve, Vector2(78, 55 + b), Vector2(5, 4.5), robe)
			_stamp(canvas, sleeve, o)
			var arm := _layer()
			_stroke(arm, [Vector2(79, 57 + b), Vector2(90, 66 + b), Vector2(101, 62 + b + roundi(sin(ph)))], 1.8, skin[1])
			_stamp(canvas, arm, o)
			_claws(canvas, Vector2(101, 62 + b + roundi(sin(ph))), 1.0, skin[2])
			var head := _layer()
			_ellipse(head, Vector2(88, 39 + b), Vector2(8, 9.5), skin)
			_ellipse(head, Vector2(92, 49 + b), Vector2(3.5, 3), skin)
			_lens(head, Vector2(93, 38 + b), Vector2(104, 47 + b), 2.6, skin[2], skin[1])
			_stamp(canvas, head, o)
			_flat_ellipse(canvas, Vector2(86, 32 + b), Vector2(8.5, 4.5), hair[1])
			_line(canvas, [Vector2(94, 33 + b), Vector2(96, 40 + b), Vector2(95, 47 + b)], hair[0])
			_line(canvas, [Vector2(92, 46 + b), Vector2(97, 47 + b)], HOLLOW)
			for x in range(91, 94):
				_glow(canvas, Vector2i(x, 37 + b), eye, eye_halo)
		DOWN, UP:
			var down: bool = st.dir == DOWN
			var staff := _layer()
			var sx := 42 if down else 102
			_stroke(staff, [Vector2(sx, 27 + b), Vector2(sx - 2, 62 + b), Vector2(sx + 1, ground)], 1.6, wood)
			_stroke(staff, [Vector2(sx, 27 + b), Vector2(sx - 4, 22 + b), Vector2(sx - 1, 18 + b)], 1.4, wood)
			_stamp(canvas, staff, o)
			_ellipse(fig, Vector2(72, 70 + b), Vector2(21, 24), robe, ground)
			_ellipse(fig, Vector2(72, 53 + b), Vector2(18, 10), robe)
			_reed_bands(fig, [[Vector2(52, 64), Vector2(92, 58)], [Vector2(51, 78), Vector2(93, 74)], [Vector2(53, 90), Vector2(91, 88)]], b, reed)
			_stamp(canvas, fig, o)
			for side: int in [-1, 1]:
				var arm := _layer()
				var hand := Vector2(72 + side * 19, 84 + b + roundi(sin(ph + side)))
				_stroke(arm, [Vector2(72 + side * 16, 54 + b), Vector2(72 + side * 22, 70 + b), hand], 1.8, skin[1])
				_stamp(canvas, arm, o)
				_claws(canvas, hand, 0.0, skin[2])
			if down:
				_hag_hair(canvas, [Vector2(62, 32), Vector2(64, 30), Vector2(80, 30), Vector2(82, 32)], Vector2(0, 42), ph, b, hair, o)
				var head := _layer()
				_ellipse(head, Vector2(72, 38 + b), Vector2(9.5, 11), skin)
				_lens(head, Vector2(72, 36 + b), Vector2(72, 49 + b), 2.2, skin[2], skin[1])
				_stamp(canvas, head, o)
				_flat_ellipse(canvas, Vector2(72, 29 + b), Vector2(10.5, 5), hair[1])
				for side: int in [-1, 1]:
					_line(canvas, [Vector2(72 + side * 8, 31 + b), Vector2(72 + side * 10, 46 + b), Vector2(72 + side * 11, 58 + b)], hair[0])
				_line(canvas, [Vector2(69, 51 + b), Vector2(75, 51 + b)], HOLLOW)
				for x: int in [66, 67, 68, 75, 76, 77]:
					_glow(canvas, Vector2i(x, 38 + b), eye, eye_halo)
			else:
				var head := _layer()
				_ellipse(head, Vector2(72, 36 + b), Vector2(9.5, 10), hair)
				_stamp(canvas, head, o)
				_hag_hair(canvas, [Vector2(64, 36), Vector2(68, 38), Vector2(72, 39), Vector2(76, 38), Vector2(80, 36)], Vector2(0, 36), ph, b, hair, o)
	_mire(canvas, Vector2(70, ground), f, true)

# The black pool she wades in. The back half and ripples go under her; `front` draws the near
# edge of the water over her waist.
func _mire(canvas: Image, c: Vector2, f: int, front: bool) -> void:
	var water := Color("#06080a")
	var sheen := Color("#1e2c34")
	var r := Vector2(36, 8)
	for y in range(floori(c.y - r.y), ceili(c.y + r.y) + 1):
		for x in range(floori(c.x - r.x), ceili(c.x + r.x) + 1):
			var d := (Vector2(x + 0.5, y + 0.5) - c) / r
			if d.length_squared() > 1.0 or (front and d.y < -0.1):
				continue
			var col := water
			for k in 2:  # ripples spreading out
				var rr := fposmod(f / float(FRAMES) + k * 0.5, 1.0) * 0.8 + 0.25
				if absf(d.length() - rr) < 0.06 and (x + y) % 2 == 0:
					col = sheen
			_px(canvas, x, y, col)
	if front:
		for x in range(floori(c.x - r.x * 0.75), ceili(c.x + r.x * 0.75)):
			if (x + f) % 3 != 0:
				_px(canvas, x, roundi(c.y - r.y * 0.1) - 1, sheen)

# Reed stalks bound round her body in bands, only over her own pixels.
func _reed_bands(layer: Image, bands: Array, b: int, color: Color) -> void:
	for band: Array in bands:
		var a: Vector2 = band[0] + Vector2(0, b)
		var e: Vector2 = band[1] + Vector2(0, b)
		for off: int in [0, 2]:
			var steps := int(absf(e.x - a.x))
			for s in steps + 1:
				var p := a.lerp(e, float(s) / steps).round() + Vector2(0, off)
				if layer.get_pixel(int(p.x), int(p.y)).a > 0.0 and posmod(int(p.x) + off, 7) != 0:
					layer.set_pixel(int(p.x), int(p.y), color if off == 0 else color.darkened(0.35))

# Long wet hair: strands from the crown points trailing by `fall`, swaying at the ends.
func _hag_hair(canvas: Image, crown: Array, fall: Vector2, ph: float, b: int, ramp: Array[Color], o: Color) -> void:
	var layer := _layer()
	for i in crown.size():
		for j in 3:
			var start: Vector2 = crown[i] + Vector2(j * 1.5 - 1.5, b)
			var end := start + fall + Vector2(sin(ph + i + j) * 2.0 + j * 2.0 - 2.0, j * 2.0)
			_stroke(layer, [start, start.lerp(end, 0.5) + Vector2(1.5 * sin(i + j), 0), end], 1.0, ramp[(i + j) % ramp.size()])
	_stamp(canvas, layer, o)

# Long claw fingers curling down from a hand; `forward` 1 = reaching right, 0 = hanging down.
func _claws(canvas: Image, hand: Vector2, forward: float, color: Color) -> void:
	for i in 4:
		var spread := (i - 1.5) * 1.5
		var tip := hand + (Vector2(5, spread + 2) if forward > 0.5 else Vector2(spread, 6))
		var bend := tip + (Vector2(1, 2) if forward > 0.5 else Vector2(0, 1))
		_line(canvas, [hand, tip, bend], color)
