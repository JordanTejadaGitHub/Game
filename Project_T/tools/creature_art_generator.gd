extends SceneTree
# Generates the nightmare (enemy) spritesheets in assets/creatures/ and a SpriteFrames resource per
# nightmare in animation/enemy/. Roster and art direction: documentation/enemy_design.md. Nightmares
# are dark, cold and partly translucent, glow only in their eyes or core, have one strong silhouette
# tied to their trait and move a little wrong (twitches, stop-start, gliding). Warm, cute Wardens vs
# cold nightmares is the game's core look. Each sheet has one row per animation (walk_side facing
# right, walk_down, walk_up, then extras such as the Night Hound's sprint, which the game still calls
# "roll") of FRAMES frames. Files keep the old creature names (see CREATURES) until the code renames
# them. Colours are Heartwood 32 names (tools/art/heartwood_palette.gd, never raw hex) and every
# sheet goes through DetailPass (NIGHTMARE: cold ramps only) before saving; the Dream Thief's stolen
# light is the one warm exception, laid on top after the pass. The preview ends each row with a
# frame as shaders/blight.gdshader shows it in game.
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

# fps: animation speed (extra_fps for the extra rows; `once` lists extra rows that don't loop, such
# as a burrow the game plays forwards to sink and backwards to surface). draw: shared draw function (default: the
# file's own). k: size scale for the small ones spawned by splitters. variant: passed to the draw
# function as st.variant. anims: replaces the walk rows (for things that don't walk; dir is -1).
# size: frame size in px (default
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
	# Acts 3-4 (acts_3_4.md): new names from the start.
	"will_o_wisp": {fps = 8.0},
	"gravecrawler": {fps = 8.0, extra = ["burrow"], extra_fps = 10.0, once = ["burrow"]},
	"drowned_one": {fps = 6.0},
	"barrow_wight": {fps = 4.0},
	"watcher": {fps = 6.0},
	"ash_crawler": {fps = 6.0},
	"moth_queen": {fps = 6.0, size = 144, extra = ["eclipse"], extra_fps = 8.0, once = ["eclipse"]},
	"shellbound": {fps = 7.0},
	"shellbound_cracked": {fps = 8.0, draw = "shellbound", variant = "cracked"},  # once its dread shell breaks
	"whisper_swarm": {fps = 8.0},
	"dream_thief": {fps = 12.0},
	"weeper": {fps = 5.0},
	"hollow_oak": {fps = 5.0, size = 176, extra = ["grief"], extra_fps = 8.0},
	# Pool bosses (enemy_design.md "Boss pools") and their followers.
	"night_mare": {fps = 8.0, size = 112, extra = ["gallop"], extra_fps = 12.0},
	"scarecrow": {fps = 6.0, size = 112, extra = ["burst"], extra_fps = 10.0, once = ["burst"]},
	"crow": {fps = 12.0},
	# Not a nightmare: the obstacle the Hollow Oak plants. No walks, just its own rows.
	"thorn_sapling": {fps = 4.0, obstacle = true, anims = ["idle", "grow", "wither"], extra_fps = 8.0, once = ["grow", "wither"]},
}
# Defaults of shaders/blight.gdshader, for the in-game frame at the end of each preview row.
const SHADER_TRANSLUCENCY := 0.85
const SHADER_GLOW_START := 0.6
const SHADER_GLOW_STRENGTH := 0.5

# Shadow-stuff, lit from the upper left like the Wardens: [deep, dark, mid, rim].
const NIGHT := ["Void", "Dread", "Shade", "Bruise"]
var NIGHT_O := _c("Void")
var HOLLOW := _c("Void")
var EYE := _c("Moonlight")  # cold glow
var EYE_HALO := _c("Dewlight", 0.55)
var SHADOW := _c("Void", 0.38)
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

var light := Vector3(-0.45, -0.55, 0.7).normalized()  # from the upper left (art_direction.md)
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
	var walks: bool = not info.has("anims")
	var anims: Array = WALKS + info.get("extra", []) if walks else info.anims
	var draw := Callable(self, "_draw_" + info.get("draw", creature))
	S = info.get("size", 64)
	var sheet := Image.create_empty(S * FRAMES, S * anims.size(), false, Image.FORMAT_RGBA8)
	# Stolen Heartwood light, the one warm thing allowed on a nightmare (art_direction.md): drawn to
	# st.warm, kept out of the cold detail pass and laid on top afterwards.
	var warm_sheet := Image.create_empty(S * FRAMES, S * anims.size(), false, Image.FORMAT_RGBA8)
	for row in anims.size():
		for f in FRAMES:
			var canvas := _layer()
			var warm := _layer()
			var st := {anim = anims[row], dir = row if walks and row < WALKS.size() else -1, f = f,
				ph = TAU * f / FRAMES, k = info.get("k", 1.0), variant = info.get("variant", ""), warm = warm}
			draw.call(canvas, st)
			sheet.blit_rect(canvas, Rect2i(0, 0, S, S), Vector2i(f * S, row * S))
			warm_sheet.blit_rect(warm, Rect2i(0, 0, S, S), Vector2i(f * S, row * S))
	# The detailed-64 pass; glow radius 3 so boss frames get the same px spread as 64px ones.
	var kind := DetailPass.Kind.OBSTACLE if info.get("obstacle", false) else DetailPass.Kind.NIGHTMARE
	sheet = DetailPass.apply_sheet(sheet, Vector2i(S, S), kind, 3)
	HeartwoodPalette.snap_image(warm_sheet)
	sheet.blend_rect(warm_sheet, Rect2i(Vector2i.ZERO, sheet.get_size()), Vector2i.ZERO)
	sheet.save_png(OUT + creature + ".png")
	sheets.append(sheet)
	_save_sprite_frames(creature, anims, info.fps, info.get("extra_fps", info.fps), info.get("once", []))

# Writes animation/enemy/<creature>.tres: one AtlasTexture per frame, one animation per row.
func _save_sprite_frames(creature: String, anims: Array, fps: float, extra_fps: float, once: Array) -> void:
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
		var speed := extra_fps if row >= WALKS.size() or once.has(anims[row]) else fps
		var loop := "false" if once.has(anims[row]) else "true"
		entries.append("{\n\"frames\": [%s],\n\"loop\": %s,\n\"name\": &\"%s\",\n\"speed\": %s\n}" % [", ".join(frames), loop, anims[row], str(speed)])
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
	preview.fill(_c("Leaf"))
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

# A Heartwood 32 colour by name (art_direction.md): generators never use raw hex.
func _c(color_name: String, alpha: float = 1.0) -> Color:
	return HeartwoodPalette.color(color_name, alpha)

# A shading ramp from palette names, dark to light.
func _ramp(names: Array) -> Array[Color]:
	var out: Array[Color] = []
	for n: String in names:
		out.append(_c(n))
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
		var col := _c(NIGHT[2])
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
func _crawl(canvas: Image, pixels: Array[Vector2i], f: int, count: int = 2, core: Color = _c("Moonlight"),
		edge: Color = _c("Slate")) -> void:
	var n := pixels.size()
	if n == 0:
		return
	for k in count:
		var i := (f * 3 + k * n / count) % n
		for j: int in [-1, 1]:
			if i + j >= 0 and i + j < n:
				_px(canvas, pixels[i + j].x, pixels[i + j].y, edge)
		_px(canvas, pixels[i].x, pixels[i].y, core)

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
	var bark := _ramp(["Void", "Night", "Dusk", "Slate"])
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
	var body := _ramp(["Dread", "Shade", "Bruise", "Wraithlight"])
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
	var body := _ramp(["Dew", "Stone", "Dewlight", "Moonlight"])
	var o := _c("Dusk")
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
	var veil := _ramp(["Night", "Dusk", "Slate", "Stone"])
	var o := _c("Dread")
	var tear := _c("Dewlight")
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
	var body := _ramp(["Void", "Dread", "Shade", "Dusk"])
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
		var col := _c(NIGHT[2])
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
		_px(canvas, 50 - i, y - 3, [EYE, EYE, _c("Stone"), _c("Pool")][i])

# --- Sleepwalker (wandering_hare) ---------------------------------------------------------------
# Sometimes takes a wrong turn: a drifting figure in a pale gown, eyes closed, arms held out in
# front, head lolling. It floats, never quite walking.

func _draw_wandering_hare(canvas: Image, st: Dictionary) -> void:
	var gown := _ramp(["Dusk", "Slate", "Stone", "Mist"])
	var skin := _ramp(["Slate", "Stone", "Mist"])
	var hair := _c("Void")
	var o := _c("Dread")
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
	var robe := _ramp(["Void", "Dread", "Shade", "Bruise"])
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
		_line(canvas, [hand, lantern + Vector2(0, -4)], _c("Pool"))
		_lantern(canvas, lantern, f, ground)

# A cold lantern: dark cap and base, glowing glass, a flickering halo and light pooled on the ground.
func _lantern(canvas: Image, p: Vector2, f: int, ground: float) -> void:
	var halo_r: float = [6.0, 6.5, 5.5, 6.5, 6.0, 7.0][f]
	_blend_ellipse(canvas, Vector2(p.x, ground), Vector2(8, 2.5), _c("Dewlight", 0.14))
	for y in range(floori(p.y - halo_r), ceili(p.y + halo_r) + 1):
		for x in range(floori(p.x - halo_r), ceili(p.x + halo_r) + 1):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(p)
			if d > 2.5 and d < halo_r and (x + y + f) % 2 == 0:
				_blend_px(canvas, x, y, _c("Dewlight", 0.35 * (1.0 - d / halo_r)))
	var q := Vector2i(p.round())
	var metal := _c("Night")
	_px(canvas, q.x, q.y - 4, metal)
	for x in range(q.x - 1, q.x + 2):
		_px(canvas, x, q.y - 3, metal)
	for y in range(q.y - 2, q.y + 2):
		_px(canvas, q.x - 2, y, metal)
		_px(canvas, q.x + 2, y, metal)
		for x in range(q.x - 1, q.x + 2):
			_px(canvas, x, y, EYE)
	_px(canvas, q.x, q.y - 1, _c("Moonlight"))
	_px(canvas, q.x, q.y, _c("Moonlight"))
	for x in range(q.x - 2, q.x + 3):
		_px(canvas, x, q.y + 2, metal)

# --- Wraith (duckling) --------------------------------------------------------------------------
# Follows the Lantern Bearer in single file: a small hunched hooded wisp, head bowed, two faint
# eyes under the hood. Every so often its head jerks.

func _draw_duckling(canvas: Image, st: Dictionary) -> void:
	var robe := _ramp(["Void", "Dread", "Shade", "Bruise"])
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
			_px(ghost, x, 30 + h, _c("Dewlight"))
	_merge(canvas, ghost, 0.85)

# --- The Hollow Stag (old_stag) -----------------------------------------------------------------
# Act 1 boss, tramples Thornwalls: a gaunt stag of dead bark and bone, a skull for a face with
# cold eyes in its sockets, ribs open around a ghost-fire heart, and ghost-fire burning in its
# antlers. Drawn on a 112px frame.

func _draw_old_stag(canvas: Image, st: Dictionary) -> void:
	var o := NIGHT_O
	var bark := _ramp(["Void", "Night", "Dusk", "Slate"])
	var bone := _ramp(["Stone", "Mist", "Moonlight"])
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
				if layer.get_pixel(x, y).a > 0.0 and (x == 0 or layer.get_pixel(x - 1, y).a == 0.0):
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
		var col := _c("Dew", 0.85) if layer_i == 0 else _c("Moonlight")
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
	_blend_ellipse(canvas, c, Vector2(r + 2.0, r + 2.0), _c("Dew", 0.35))
	_flat_ellipse(canvas, c, Vector2(r, r), _c("Dewlight"))
	_px(canvas, int(c.x), int(c.y), _c("Moonlight"))

# --- The Mire Hag (great_toad) ------------------------------------------------------------------
# Act 2 boss, sinks into the mire and rises 3 tiles ahead: a bent bog witch wading waist-deep in a
# pool of black water, wrapped in reeds, long wet hair down her back, a crooked staff and a long
# clawed hand reaching ahead; her eyes glow a sickly cold green. Drawn on a 144px frame.

func _draw_great_toad(canvas: Image, st: Dictionary) -> void:
	var o := _c("Void")
	var robe := _ramp(["Void", "Dread", "Night", "Dusk"])
	var skin := _ramp(["Dusk", "Slate", "Stone"])
	var hair := _ramp(["Void", "Dread", "Night"])
	var reed := _c("Pool")
	var wood := _c("Night")
	var eye := _c("Moonlight")
	var eye_halo := _c("Dewlight", 0.5)
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
	var water := _c("Void")
	var sheen := _c("Pool")
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

# --- Will-o'-Wisp -------------------------------------------------------------------------------
# Reveals Lurkers near it: a treacherous floating light, a cold green-white flame with two tiny
# dark eyes in its core. It flickers, and every so often it stutters dim.

func _draw_will_o_wisp(canvas: Image, st: Dictionary) -> void:
	var glow := _ramp(["Pool", "Dew", "Dewlight", "Moonlight"])
	var f: int = st.f
	var ph: float = st.ph
	var h := roundi(sin(ph) * 2.0)
	var flick: float = [1.0, 0.85, 1.1, 0.6, 1.0, 0.9][f]
	var c := Vector2(32, 25 + h)
	var back := Vector2(-1, -0.5) if st.dir == SIDE else Vector2(0, -1)  # flames rise
	_blend_ellipse(canvas, Vector2(32, 45), Vector2(9 * flick, 2.5), _c("Dewlight", 0.16 * flick))
	var halo_r := 9.0 * flick
	for y in range(floori(c.y - halo_r), ceili(c.y + halo_r) + 1):
		for x in range(floori(c.x - halo_r), ceili(c.x + halo_r) + 1):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d > 3.0 and d < halo_r and (x + y + f) % 2 == 0:
				_blend_px(canvas, x, y, _c("Dewlight", 0.4 * (1.0 - d / halo_r)))
	var flame := _layer()
	for s in 12:
		var t := s / 11.0
		var p := c + back * t * 10.0 * flick + back.orthogonal() * sin(ph * 2.0 + t * 5.0) * t * 2.0
		_flat_ellipse(flame, p, Vector2.ONE * (4.2 * (1.0 - t) + 0.4), glow[1] if t > 0.45 else glow[2])
	_stamp(canvas, flame)
	_flat_ellipse(canvas, c, Vector2(3.4, 3.4) * flick, glow[2])
	_flat_ellipse(canvas, c, Vector2(2.0, 2.0) * flick, glow[3])
	match st.dir:
		DOWN:
			_px(canvas, 30, int(c.y), HOLLOW)
			_px(canvas, 33, int(c.y), HOLLOW)
		SIDE:
			_px(canvas, 33, int(c.y), HOLLOW)
			_px(canvas, 35, int(c.y), HOLLOW)
	for k in 2:  # stray sparks drifting off
		var t := fposmod(float(f) / FRAMES + k * 0.5, 1.0)
		var p := c + back * (4.0 + t * 10.0) + back.orthogonal() * (k * 5.0 - 2.5)
		var col := glow[2]
		col.a = 1.0 - t
		_blend_px(canvas, roundi(p.x), roundi(p.y), col)

# --- Gravecrawler -------------------------------------------------------------------------------
# Burrows under one Warden or wall per trip: a low hunched thing that drags itself along on long
# clawed arms, elbows high. "burrow" sinks it into the earth (played backwards, it surfaces).

func _draw_gravecrawler(canvas: Image, st: Dictionary) -> void:
	var body := _ramp(["Void", "Dread", "Shade", "Bruise"])
	var claw := _c("Stone")
	var o := NIGHT_O
	var f: int = st.f
	var ph: float = st.ph
	if st.anim == "burrow":
		_gravecrawler_burrow(canvas, st)
		return
	var bob: int = [0, 1, 0, 0, 1, 0][f]
	var fig := _layer()
	match st.dir:
		SIDE:
			_shadow(canvas, Vector2(31, 43), Vector2(15, 2.5))
			var pull := sin(ph)
			_crawler_arm(canvas, Vector2(37, 33 + bob), Vector2(42 - pull * 3, 28 + bob), Vector2(47 - pull * 4, 42 - (2 if pull < -0.3 else 0)), Vector2(1, 0.3), body[0], claw, o)
			_stroke(fig, [Vector2(21, 37 + bob), Vector2(17, 40), Vector2(13, 42)], 1.1, body[1])
			_ellipse(fig, Vector2(28, 35 + bob), Vector2(11, 6.5), body)
			_ellipse(fig, Vector2(26, 31 + bob), Vector2(7, 5), body)
			_ellipse(fig, Vector2(40, 38 + bob), Vector2(4.5, 4), body)
			_stamp(canvas, fig, o)
			_ragged(canvas, [Vector2i(20, 28), Vector2i(23, 26), Vector2i(26, 25), Vector2i(29, 26)], bob)
			_crawler_arm(canvas, Vector2(35, 34 + bob), Vector2(41 + pull * 3, 28 + bob), Vector2(46 + pull * 4, 43 - (2 if pull > 0.3 else 0)), Vector2(1, 0.3), body[1], claw, o)
			_glow(canvas, Vector2i(41, 37 + bob))
			_glow(canvas, Vector2i(43, 38 + bob))
		DOWN, UP:
			var down: bool = st.dir == DOWN
			_shadow(canvas, Vector2(32, 43), Vector2(13, 2.5))
			if not down:
				_ellipse(fig, Vector2(32, 26 + bob), Vector2(4.5, 4), body)
			_ellipse(fig, Vector2(32, (30 if down else 34) + bob), Vector2(9, 8), body)
			if down:
				_ellipse(fig, Vector2(32, 37 + bob), Vector2(5, 4), body)
			_stamp(canvas, fig, o)
			_ragged(canvas, [Vector2i(27, 24), Vector2i(31, 22), Vector2i(35, 24)] if down else [Vector2i(27, 30), Vector2i(31, 28), Vector2i(35, 30)], bob)
			for side: int in [-1, 1]:
				var s := sin(ph + (PI if side > 0 else 0.0))
				var lift := 2 if s > 0.3 else 0
				if down:
					_crawler_arm(canvas, Vector2(32 + side * 6, 34 + bob), Vector2(32 + side * 13, 30 + bob), Vector2(32 + side * 10, 42 - lift), Vector2(0, 1), body[1], claw, o)
				else:
					_crawler_arm(canvas, Vector2(32 + side * 6, 30 + bob), Vector2(32 + side * 13, 27 + bob), Vector2(32 + side * 10, 19 - lift), Vector2(0, -1), body[1], claw, o)
			if down:
				_glow(canvas, Vector2i(30, 37 + bob))
				_glow(canvas, Vector2i(33, 37 + bob))

# A long arm from shoulder through a high elbow to the hand, three pale claws hooking along `reach`.
func _crawler_arm(canvas: Image, shoulder: Vector2, elbow: Vector2, hand: Vector2, reach: Vector2, color: Color, claw: Color, o: Color) -> void:
	var layer := _layer()
	_stroke(layer, [shoulder, elbow, hand], 1.1, color)
	_stamp(canvas, layer, o)
	var side := reach.normalized().orthogonal()
	for k in 3:
		var tip := hand + reach.normalized() * 3.0 + side * (k - 1) * 1.5
		_line(canvas, [hand, tip, tip + Vector2(0, 1.5) + reach.normalized()], claw)

# Sinking into the earth: the front view drops through a dark hole while dirt flies.
func _gravecrawler_burrow(canvas: Image, st: Dictionary) -> void:
	var f: int = st.f
	var sink: int = [0, 3, 6, 10, 14, 19][f]
	var earth := _ramp(["Void", "Dread", "Night"])
	_flat_ellipse(canvas, Vector2(32, 41), Vector2(14, 4), _c("Void"))
	var fig := _layer()
	_draw_gravecrawler(fig, {anim = "walk_down", dir = DOWN, f = 0, ph = 0.0, k = 1.0})
	var sunk := _layer()
	sunk.blit_rect(fig, Rect2i(0, 0, S, S - sink), Vector2i(0, sink))
	sunk.fill_rect(Rect2i(0, 42, S, S - 42), Color(0, 0, 0, 0))
	canvas.blend_rect(sunk, Rect2i(0, 0, S, S), Vector2i.ZERO)
	for y in range(42, 46):  # the near rim of the hole
		for x in range(18, 47):
			if ((Vector2(x + 0.5, y + 0.5) - Vector2(32, 42)) / Vector2(15, 3.5)).length_squared() <= 1.0:
				_px(canvas, x, y, earth[1] if y == 42 else earth[0])
	for k in 4:  # clods thrown out
		var t := fposmod(float(f) / FRAMES + k * 0.25, 1.0)
		var p := Vector2(32 + (k - 1.5) * 7.0 * (0.4 + t), 40 - sin(t * PI) * 9.0)
		_px(canvas, roundi(p.x), roundi(p.y), earth[2])
		_px(canvas, roundi(p.x) + 1, roundi(p.y), earth[1])

# --- Drowned One --------------------------------------------------------------------------------
# Always Damp, immune to slows: a bloated, dripping shape, head lolling, arms hanging, black water
# streaming down it and trailing behind in puddles.

func _draw_drowned_one(canvas: Image, st: Dictionary) -> void:
	var skin := _ramp(["Night", "Dusk", "Pool", "Slate"])
	var o := _c("Void")
	var water := _c("Void")
	var sheen := _c("Pool")
	var f: int = st.f
	var ph: float = st.ph
	var b: int = [0, 1, 1, 0, 1, 1][f]
	var s := roundi(sin(ph) * 1.5)
	var trail: Vector2 = Vector2(-1, 0) if st.dir == SIDE else (Vector2(0, -1) if st.dir == DOWN else Vector2(0, 1))
	var pool := water
	pool.a = 0.85
	_blend_ellipse(canvas, Vector2(32, 44), Vector2(10, 2.5), pool)
	for k in 3:
		pool.a = 0.6 - k * 0.15
		_blend_ellipse(canvas, Vector2(32, 44) + trail * (9 + k * 6), Vector2(5 - k, 1.6), pool)
	var fig := _layer()
	var top := 0
	match st.dir:
		SIDE:
			_stroke(fig, [Vector2(29, 39), Vector2(29 + s, 44)], 1.4, skin[1])
			_stroke(fig, [Vector2(34, 39), Vector2(34 - s, 44)], 1.4, skin[1])
			_ellipse(fig, Vector2(31, 31 + b), Vector2(9.5, 11), skin)
			_ellipse(fig, Vector2(35, 34 + b), Vector2(5, 6), skin)
			_ellipse(fig, Vector2(37, 20 + b), Vector2(4.5, 4), skin)
			_stroke(fig, [Vector2(35, 25 + b), Vector2(39, 31 + b), Vector2(40, 38 + b)], 1.3, skin[2])
			top = 20
		DOWN, UP:
			for side: int in [-1, 1]:
				_stroke(fig, [Vector2(32 + side * 4, 39), Vector2(32 + side * 4, 44 - (1 if s * side > 0 else 0))], 1.4, skin[1])
			_ellipse(fig, Vector2(32, 31 + b), Vector2(10.5, 11), skin)
			_ellipse(fig, Vector2(32, 19 + b), Vector2(5, 4.5), skin)
			for side: int in [-1, 1]:
				_stroke(fig, [Vector2(32 + side * 9, 25 + b), Vector2(32 + side * 12, 32 + b), Vector2(32 + side * 12, 39 + b)], 1.3, skin[2])
			top = 22
	# Black water running down it in streaks, a glint sliding down each.
	for x in S:
		if posmod(x * 3, 7) != 0:
			continue
		var run := -1
		for y in range(top, 44):
			if fig.get_pixel(x, y + b).a > 0.0:
				run += 1
				fig.set_pixel(x, y + b, sheen if run == (f * 2 + x) % 12 else water)
	_stamp(canvas, fig, o)
	match st.dir:
		SIDE:
			_glow(canvas, Vector2i(39, 19 + b))
			_face_hole(canvas, 39, 22 + b, 2, 1)
			_px(canvas, 40, 40 + b + (f % 3) * 2, water)
		DOWN:
			_glow(canvas, Vector2i(30, 18 + b))
			_glow(canvas, Vector2i(33, 18 + b))
			_face_hole(canvas, 31, 21 + b, 2, 2)
			for side: int in [-1, 1]:
				_px(canvas, 32 + side * 12, 40 + b + ((f + (1 if side > 0 else 0)) % 3) * 2, water)

# --- Barrow Wight -------------------------------------------------------------------------------
# Can't be Held; very slow, very high health: an ancient king in a long ragged cloak, a dull iron
# crown on a bone-pale face, a grey beard, leaning on an iron staff. It holds still, then shuffles.

func _draw_barrow_wight(canvas: Image, st: Dictionary) -> void:
	var cloak := _ramp(["Void", "Night", "Dusk", "Slate"])
	var bone := _ramp(["Slate", "Stone", "Mist"])
	var crown := _ramp(["Night", "Dusk", "Stone"])
	var iron := _c("Dusk")
	var o := NIGHT_O
	var f: int = st.f
	var ph: float = st.ph
	var h: int = [0, 0, 0, 1, 1, 0][f]
	_shadow(canvas, Vector2(32, 45), Vector2(10, 2.5))
	var fig := _layer()
	var staff_x := 41 if st.dir != UP else 23
	if st.dir == UP:
		_line(canvas, [Vector2(staff_x, 10 + h), Vector2(staff_x + 1, 45)], iron)
	match st.dir:
		SIDE:
			_robe(fig, 32.0, 18.0 + h, 6.0, 45.0, 11.0, -2.0, ph * 0.3, cloak)
			_ellipse(fig, Vector2(34, 13 + h), Vector2(4.5, 5), bone)
			_stroke(fig, [Vector2(35, 20 + h), Vector2(39, 25 + h), Vector2(41, 25 + h)], 1.2, cloak[2])
		DOWN:
			_robe(fig, 32.0, 18.0 + h, 6.5, 45.0, 11.0, 0.0, ph * 0.3, cloak)
			_ellipse(fig, Vector2(32, 13 + h), Vector2(4.5, 5), bone)
			_stroke(fig, [Vector2(36, 20 + h), Vector2(39, 24 + h), Vector2(41, 25 + h)], 1.2, cloak[2])
		UP:
			_robe(fig, 32.0, 18.0 + h, 6.5, 45.0, 11.0, 0.0, ph * 0.3, cloak)
			_ellipse(fig, Vector2(32, 13 + h), Vector2(4.5, 5), bone)
	_stamp(canvas, fig, o)
	match st.dir:
		SIDE:
			for p: Array in [[Vector2(35, 17), Vector2(34, 24)], [Vector2(36, 17), Vector2(36, 23)], [Vector2(37, 16), Vector2(38, 22)]]:
				_line(canvas, [p[0] + Vector2(0, h), p[1] + Vector2(0, h)], bone[0])
			_flat_ellipse(canvas, Vector2(36.5, 13.5 + h), Vector2(1.5, 1.5), HOLLOW)
			_glow(canvas, Vector2i(36, 13 + h))
			_crown(canvas, 30, 38, 9 + h, [30, 33, 36, 38], crown, o)
		DOWN:
			for x: int in [29, 31, 32, 34]:
				_line(canvas, [Vector2(x, 17 + h), Vector2(x + (1 if x > 32 else (-1 if x < 31 else 0)), 23 + h + (1 if x == 31 or x == 32 else 0))], bone[0])
			for side: int in [-1, 1]:
				_flat_ellipse(canvas, Vector2(32 + side * 2, 13.5 + h), Vector2(1.5, 1.5), HOLLOW)
			_glow(canvas, Vector2i(30, 13 + h))
			_glow(canvas, Vector2i(33, 13 + h))
			_crown(canvas, 27, 36, 9 + h, [28, 30, 31, 32, 33, 35], crown, o)
		UP:
			_crown(canvas, 27, 36, 9 + h, [28, 30, 31, 32, 33, 35], crown, o)
	if st.dir != UP:
		_line(canvas, [Vector2(staff_x, 10 + h), Vector2(staff_x + 1, 45)], iron)
		_px(canvas, staff_x, 25 + h, bone[1])

# A dull iron crown: a band across the head with points sticking up.
func _crown(canvas: Image, x0: int, x1: int, y: int, spikes: Array, ramp: Array[Color], o: Color) -> void:
	var layer := _layer()
	for x in range(x0, x1 + 1):
		layer.set_pixel(x, y, ramp[1])
		layer.set_pixel(x, y + 1, ramp[0])
	for x: int in spikes:
		var tall := 3 if x == 31 or x == 32 else 2
		for k in range(1, tall + 1):
			layer.set_pixel(x, y - k, ramp[2] if k == tall else ramp[1])
	_stamp(canvas, layer, o)

# --- Watcher ------------------------------------------------------------------------------------
# Never sleeps; wakes Drowsy nightmares: a floating lump of shadow studded with unblinking eyes,
# tendrils trailing beneath. All the eyes look where it's going, then snap aside together.

func _draw_watcher(canvas: Image, st: Dictionary) -> void:
	var body := _ramp(NIGHT)
	var f: int = st.f
	var ph: float = st.ph
	var h := roundi(sin(ph) * 1.5)
	var look: Vector2 = Vector2(1, 0) if st.dir == SIDE else (Vector2(0, 1) if st.dir == DOWN else Vector2(0, -1))
	if f == 3:
		look = look.orthogonal()
	_shadow(canvas, Vector2(32, 46), Vector2(9, 2))
	var fig := _layer()
	for k in 4:
		var x := 24.0 + k * 5.0
		_stroke(fig, [Vector2(x, 34 + h), Vector2(x + sin(ph + k) * 2.0, 40 + h), Vector2(x + sin(ph + k + 1.0) * 3.0, 46)], 0.9, body[1])
	for l: Vector4 in [Vector4(32, 26, 11, 10), Vector4(24, 30, 6, 5), Vector4(40, 29, 6, 5.5), Vector4(28, 19, 6, 5), Vector4(37, 18, 6, 5), Vector4(32, 34, 7, 4)]:
		_ellipse(fig, Vector2(l.x, l.y + h), Vector2(l.z, l.w), body)
	var ghost := _layer()
	_stamp(ghost, fig, NIGHT_O)
	_dissolve(ghost, Vector2(0, 40 + h), Vector2(0, 47 + h))
	_merge(canvas, ghost)
	var eyes: Array = [Vector3(32, 25, 4.0), Vector3(24, 30, 2.5), Vector3(40, 29, 2.5), Vector3(28, 18, 2.2), Vector3(37, 18, 2.2),
		Vector3(32, 33, 1.8), Vector3(21, 24, 1.6), Vector3(43, 23, 1.6), Vector3(34, 12, 1.4)]
	if st.dir == UP:
		eyes = [Vector3(28, 18, 2.2), Vector3(37, 18, 2.2), Vector3(34, 12, 1.4), Vector3(21, 24, 1.6), Vector3(43, 23, 1.6)]
	for e: Vector3 in eyes:
		_watch_eye(canvas, Vector2(e.x, e.y + h), e.z, look)

func _watch_eye(canvas: Image, c: Vector2, r: float, look: Vector2) -> void:
	var layer := _layer()
	_flat_ellipse(layer, c, Vector2(r, r * 0.85), _c("Moonlight"))
	for y in S:
		for x in S:
			if layer.get_pixel(x, y).a > 0.0 and y + 0.5 > c.y + r * 0.3:
				layer.set_pixel(x, y, _c("Mist"))
	_flat_ellipse(layer, c + look * r * 0.35, Vector2.ONE * maxf(r * 0.55, 0.8), _c("Dewlight"))
	var pupil := Vector2i((c + look * r * 0.45).floor())
	layer.set_pixelv(pupil, HOLLOW)
	_stamp(canvas, layer, NIGHT_O)

# --- Ash Crawler --------------------------------------------------------------------------------
# Its burning ash clears Spored behind it: a slow segmented crawler of charcoal, cold ghost-fire
# smouldering in its cracks (never warm, art_direction.md), ash flaking off and left in a grey trail.

func _draw_ash_crawler(canvas: Image, st: Dictionary) -> void:
	var coal := _ramp(["Void", "Night", "Dusk", "Slate"])
	var ember := _c("Wraithlight")
	var ember_dim := _c("Bruise")
	var hot := _c("Moonlight")
	var ash := _c("Slate")
	var o := NIGHT_O
	var f: int = st.f
	var ph: float = st.ph
	var cracks: Array = [[Vector2(-0.6, -0.2), Vector2(-0.1, 0.2), Vector2(0.5, -0.3)], [Vector2(-0.3, -0.6), Vector2(0.1, -0.2)]]
	var trail: Rect2i
	var segs: Array[Vector3] = []  # x, y, radius scale; drawn in order (far to near)
	match st.dir:
		SIDE:
			trail = Rect2i(3, 41, 12, 3)
			for i in 5:
				segs.append(Vector3(16 + i * 6.5, 36 + sin(ph - i * 0.9), 1.0 + i * 0.08))
		DOWN:
			trail = Rect2i(28, 6, 8, 10)
			for i in 5:
				segs.append(Vector3(32 + sin(ph - i * 0.9), 17 + i * 5.5, 1.0 + i * 0.08))
		UP:
			trail = Rect2i(28, 46, 8, 10)
			for i in range(4, -1, -1):
				segs.append(Vector3(32 + sin(ph - i * 0.9), 45 - i * 5.5 - 4, 1.0 + i * 0.08))
	_shadow(canvas, Vector2(32 if st.dir != SIDE else 30, 43), Vector2(15 if st.dir == SIDE else 8, 2.5))
	for y in range(trail.position.y, trail.end.y):
		for x in range(trail.position.x, trail.end.x):
			if (x * 7 + y * 3 + f) % 4 == 0:
				_px(canvas, x, y, ash)
	for i in segs.size():
		var sg: Vector3 = segs[i]
		var c := Vector2(sg.x, sg.y)
		var r := Vector2(5.0, 4.5) * sg.z if st.dir == SIDE else Vector2(5.5, 4.0) * sg.z
		if st.dir == SIDE:  # a pair of tiny legs under each segment
			var s := sin(ph + i * PI)
			_line(canvas, [c + Vector2(-1, r.y - 1), Vector2(c.x - 1 + roundi(s), 42)], o)
		var seg := _layer()
		_ellipse(seg, c, r, coal)
		var glow := _crack(seg, c, r, cracks if i % 2 == 0 else [cracks[0]], ember_dim)
		_stamp(canvas, seg, o)
		_crawl(canvas, glow, f + i, 1, hot, ember)
	var head: Vector3 = segs[segs.size() - 1] if st.dir != UP else segs[0]
	match st.dir:
		SIDE:
			_px(canvas, int(head.x) + 2, int(head.y) - 1, hot)
			_px(canvas, int(head.x) + 4, int(head.y), hot)
		DOWN:
			_px(canvas, 30, int(head.y) + 1, hot)
			_px(canvas, 33, int(head.y) + 1, hot)
	for k in 3:  # ash and embers floating up
		var t := fposmod(float(f) / FRAMES + k / 3.0, 1.0)
		var sg: Vector3 = segs[k + 1]
		var col := ember if k == 1 else ash
		col.a = 1.0 - t
		_blend_px(canvas, roundi(sg.x + sin(t * TAU + k) * 2.0), roundi(sg.y - 5 - t * 10.0), col)

# --- The Moth Queen -----------------------------------------------------------------------------
# Act 3 boss, flies over the maze dropping Lurkers: a vast dusky moth whose wings carry a skull,
# pale patches with hollow sockets on the forewings and a band of teeth on the hindwings; feathery
# antennae and cold eyes. Drawn head-up on a 144px frame and turned to face the way she flies.
# "eclipse": her wings fold up and close over the dream (played backwards, they open).

func _draw_moth_queen(canvas: Image, st: Dictionary) -> void:
	var f: int = st.f
	var eclipse: bool = st.anim == "eclipse"
	var open: float = ([0.9, 0.7, 0.5, 0.32, 0.18, 0.08] if eclipse else [1.0, 0.93, 0.82, 0.74, 0.82, 0.93])[f]
	var h := 0 if eclipse else roundi(sin(st.ph) * 2.0)
	var shadow := SHADOW
	shadow.a = 0.25
	var side_view: bool = st.dir == SIDE and not eclipse
	_blend_ellipse(canvas, Vector2(72, 116), Vector2(22, 7) if side_view else Vector2(20 + 40 * open, 7), shadow)
	var pose := _layer()
	_moth_queen_pose(pose, f, st.ph, open, eclipse, h)
	if not eclipse:
		match st.dir:
			SIDE:
				pose.rotate_90(CLOCKWISE)
			DOWN:
				pose.rotate_180()
	canvas.blend_rect(pose, Rect2i(0, 0, S, S), Vector2i.ZERO)

func _moth_queen_pose(canvas: Image, f: int, ph: float, open: float, eclipse: bool, h: int) -> void:
	var wing := _ramp(["Void", "Dread", "Shade", "Bruise"])
	var fur := _ramp(["Void", "Night", "Dusk", "Slate"])
	var bone := _ramp(["Slate", "Stone", "Mist"])
	var o := NIGHT_O
	var c := Vector2(72, 62 + h)
	var lift := (1.0 - open) * 16.0 if eclipse else 0.0
	for side: int in [-1, 1]:  # hindwings, with the skull's teeth along their inner edge
		var hc := c + Vector2(side * (14 + 10 * open), 16 - lift * 0.5)
		_moth_wing(canvas, hc, Vector2(16 * open + 6, 15), side * 0.5, wing, bone, side, false, f)
	for side: int in [-1, 1]:  # forewings, with the skull's pale cheeks and hollow sockets
		var fc := c + Vector2(side * (18 + 18 * open), -10 - lift)
		_moth_wing(canvas, fc, Vector2(24 * open + 8, 17), side * (-0.35 - (1.0 - open) * 0.6 if eclipse else -0.35), wing, bone, side, true, f)
	var body := _layer()
	_ellipse(body, c + Vector2(0, 18), Vector2(7, 16), fur)
	for y in S:
		for x in S:
			if body.get_pixel(x, y).a > 0.0 and posmod(y - int(c.y), 5) == 0:
				body.set_pixel(x, y, _darker(fur, body.get_pixel(x, y)))
	_ellipse(body, c, Vector2(9, 9), fur)
	_ellipse(body, c + Vector2(0, -12), Vector2(6, 5), fur)
	_stamp(canvas, body, o)
	for p: Vector2i in [Vector2i(0, 0), Vector2i(-1, 1), Vector2i(1, 1), Vector2i(0, 2)]:  # the skull's nose on her back
		_px(canvas, int(c.x) + p.x, int(c.y) + p.y, HOLLOW)
	for side: int in [-1, 1]:
		_feather_antenna(canvas, c + Vector2(side * 3, -16), c + Vector2(side * 16, -36), fur[3], fur[2])
		var e := Vector2i((c + Vector2(side * 4 - (1 if side < 0 else 0), -13)).round())
		_glow(canvas, e, EYE, EYE_HALO)
		_px(canvas, e.x + side, e.y, EYE)

# One of her wings as a rotated ellipse: dark with a paler ragged rim; `skull` puts a bone patch
# with a hollow socket on the inner part (forewings), otherwise a band of pale teeth (hindwings).
func _moth_wing(canvas: Image, c: Vector2, r: Vector2, angle: float, ramp: Array[Color], bone: Array[Color], side: int, skull: bool, f: int) -> void:
	var layer := _layer()
	var reach := ceili(maxf(r.x, r.y)) + 1
	for y in range(maxi(0, floori(c.y) - reach), mini(S, ceili(c.y) + reach + 1)):
		for x in range(maxi(0, floori(c.x) - reach), mini(S, ceili(c.x) + reach + 1)):
			var d := (Vector2(x + 0.5, y + 0.5) - c).rotated(-angle) / r
			var q := d.length()
			if q > 1.0 or (q > 0.92 and (x * 7 + y * 3) % 5 == 0):
				continue
			var inner := -d.x * side  # 1 = towards the body
			var col: Color = ramp[2] if side < 0 else ramp[1]
			if q > 0.82:
				col = ramp[3] if (x + y) % 2 == 0 else ramp[2]
			elif posmod(roundi(atan2(d.y, d.x * side) * 9.0), 4) == 0 and q > 0.35:
				col = ramp[0]  # veins
			if skull:
				var pd := (Vector2(inner, d.y) - Vector2(0.4, -0.05)) / Vector2(0.36, 0.52)
				if pd.length() < 1.0:
					col = bone[2] if pd.y < -0.3 else (bone[1] if pd.length() < 0.8 else bone[0])
					var sd := (Vector2(inner, d.y) - Vector2(0.42, -0.08)) / Vector2(0.15, 0.24)
					if sd.length() < 1.0:
						col = HOLLOW
					elif sd.length() < 1.35 and (x + y + f) % 2 == 0:
						col = _c("Dew")
			elif inner > 0.45 and d.y < 0.2 and posmod(roundi(d.y * r.y), 4) != 0 and absf(fposmod(inner * 8.0, 1.0) - 0.5) < 0.3:
				col = bone[1]
			layer.set_pixel(x, y, col)
	_stamp(canvas, layer, NIGHT_O)

# Feathery antenna: a stalk with barbs on its outer side.
func _feather_antenna(canvas: Image, a: Vector2, b: Vector2, stem: Color, barb: Color) -> void:
	_line(canvas, [a, b], stem)
	var out := signf(b.x - a.x)
	for k in range(1, 8):
		var p := a.lerp(b, k / 8.0).round()
		_px(canvas, int(p.x + out), int(p.y + 1), barb)
		_px(canvas, int(p.x + out * 2), int(p.y + 2), barb)

# --- Shellbound (+ shellbound_cracked) ----------------------------------------------------------
# Dread shell soaks chip damage: a low, heavy shadow-beast armoured in faceted plates of hardened
# dread, a helm plate over its eyes. The cracked variant is what's left once the shell breaks off:
# the shadow underneath, a few shards clinging on and cracks of cold light where the plates were.

func _draw_shellbound(canvas: Image, st: Dictionary) -> void:
	var body := _ramp(NIGHT)
	var shell := _ramp(["Dread", "Shade", "Bruise", "Wraithlight"])
	var o := NIGHT_O
	var cracked: bool = st.variant == "cracked"
	var f: int = st.f
	var ph: float = st.ph
	var b: int = [0, 0, -1, 0, 0, -1][f]
	var off := Vector2(0, b)
	var fig := _layer()
	var plates: Array = []
	var scars: Array = []  # where plates were, for the cracked variant
	match st.dir:
		SIDE:
			_shadow(canvas, Vector2(31, 44), Vector2(17, 3))
			var far := _layer()
			for x: int in [26, 40]:
				_hound_leg(far, Vector2(x, 38 + b), ph + (0.0 if x == 26 else PI), false, body[0])
			_stamp(canvas, far, o)
			_wisps(canvas, Vector2(16, 32 + b), Vector2(-1, -0.4), f, 3, 6.0, 1.6)
			_ellipse(fig, Vector2(30, 35 + b), Vector2(13, 8), body)
			_ellipse(fig, Vector2(44, 37 + b), Vector2(5.5, 5), body)
			for x: int in [23, 37]:
				_hound_leg(fig, Vector2(x, 39 + b), ph + (PI if x == 23 else 0.0), false, body[1])
			_stamp(canvas, fig, o)
			plates = [[Vector2(18, 35), Vector2(19, 28), Vector2(26, 24), Vector2(31, 30), Vector2(26, 37)],
				[Vector2(27, 25), Vector2(33, 22), Vector2(39, 25), Vector2(37, 32), Vector2(30, 31)],
				[Vector2(37, 26), Vector2(42, 29), Vector2(43, 35), Vector2(38, 36), Vector2(36, 31)],
				[Vector2(40, 34), Vector2(43, 30), Vector2(49, 32), Vector2(49, 36)]]
			scars = [[Vector2(20, 31), Vector2(24, 29), Vector2(27, 32)], [Vector2(31, 27), Vector2(34, 29), Vector2(33, 32)]]
			if cracked:
				_glow(canvas, Vector2i(46, 35 + b), EYE, EYE_HALO)
				_glow(canvas, Vector2i(48, 36 + b), EYE, EYE_HALO)
		DOWN, UP:
			var down: bool = st.dir == DOWN
			_shadow(canvas, Vector2(32, 44), Vector2(15, 3))
			for side: int in [-1, 1]:
				var s := sin(ph + (PI if side > 0 else 0.0))
				_stroke(fig, [Vector2(32 + side * 9, 36 + b), Vector2(32 + side * 11, 44 - (1.5 if s > 0.3 else 0.0))], 1.5, body[1])
			_ellipse(fig, Vector2(32, (31 if down else 34) + b), Vector2(12, 9.5), body)
			if down:
				_ellipse(fig, Vector2(32, 39 + b), Vector2(6, 5), body)
			else:
				_ellipse(fig, Vector2(32, 24 + b), Vector2(5, 4), body)
			_stamp(canvas, fig, o)
			var y0 := 0 if down else 3
			plates = [[Vector2(21, 33 + y0), Vector2(22, 25 + y0), Vector2(29, 21 + y0), Vector2(31, 30 + y0), Vector2(26, 36 + y0)],
				[Vector2(43, 33 + y0), Vector2(42, 25 + y0), Vector2(35, 21 + y0), Vector2(33, 30 + y0), Vector2(38, 36 + y0)],
				[Vector2(29, 22 + y0), Vector2(32, 19 + y0), Vector2(35, 22 + y0), Vector2(34, 32 + y0), Vector2(30, 32 + y0)]]
			scars = [[Vector2(24, 28 + y0), Vector2(27, 26 + y0), Vector2(29, 30 + y0)], [Vector2(40, 28 + y0), Vector2(37, 26 + y0), Vector2(35, 30 + y0)]]
			if down:
				plates.append([Vector2(27, 37), Vector2(32, 34), Vector2(37, 37), Vector2(32, 39)])
				if cracked:
					_glow(canvas, Vector2i(30, 39 + b), EYE, EYE_HALO)
					_glow(canvas, Vector2i(33, 39 + b), EYE, EYE_HALO)
	if cracked:
		for sc: Array in scars:
			var pts: Array = []
			for p: Vector2 in sc:
				pts.append(p + off)
			_line(canvas, pts, _c("Wraithlight"))
		var shard: Array = plates[1]
		_plate(canvas, [shard[0] + off, shard[1] + off, (shard[1] + shard[2]) / 2 + off], shell, o)
		return
	for p: Array in plates:
		var moved: Array = []
		for q: Vector2 in p:
			moved.append(q + off)
		_plate(canvas, moved, shell, o)
	if st.dir == SIDE:  # eyes glinting under the helm plate
		_px(canvas, 46, 36 + b, EYE)
		_px(canvas, 48, 36 + b, EYE)
	elif st.dir == DOWN:
		_px(canvas, 30, 40 + b, EYE)
		_px(canvas, 33, 40 + b, EYE)

# A faceted plate: pixels grouped into wedges around its centre, each lit as a flat face.
func _plate(canvas: Image, pts: Array, ramp: Array[Color], o: Color) -> void:
	var poly := PackedVector2Array(pts)
	var centre := Vector2.ZERO
	for p in poly:
		centre += p
	centre /= poly.size()
	var box := Rect2(poly[0], Vector2.ZERO)
	for p in poly:
		box = box.expand(p)
	var layer := _layer()
	for y in range(maxi(0, floori(box.position.y)), mini(S, ceili(box.end.y) + 1)):
		for x in range(maxi(0, floori(box.position.x)), mini(S, ceili(box.end.x) + 1)):
			var p := Vector2(x + 0.5, y + 0.5)
			if not Geometry2D.is_point_in_polygon(p, poly):
				continue
			var d := p - centre
			var n := Vector3(0, -0.3, 1)
			if d.length() > 1.5:
				var a := snappedf(d.angle(), TAU / 5.0)
				n = Vector3(cos(a), sin(a), 0.8)
			layer.set_pixel(x, y, _shade(ramp, n.normalized()))
	_stamp(canvas, layer, o)

# --- Whisper Swarm ------------------------------------------------------------------------------
# Single-target damage halved: a cloud of dark whispering motes swirling at different speeds in a
# faint haze, streaming out behind; a few motes glint.

func _draw_whisper_swarm(canvas: Image, st: Dictionary) -> void:
	var f: int = st.f
	var ph: float = st.ph
	var dir: Vector2 = Vector2(1, 0) if st.dir == SIDE else (Vector2(0, 1) if st.dir == DOWN else Vector2(0, -1))
	var c := Vector2(32, 27 + roundi(sin(ph)))
	_shadow(canvas, Vector2(32, 46), Vector2(10, 2))
	var haze := _c(NIGHT[1])
	for k in 3:
		haze.a = 0.28 - k * 0.08  # thin: the detail pass adds its own smoke
		_blend_ellipse(canvas, c - dir * k * 4.0, Vector2(12, 9) - Vector2.ONE * k * 2.0, haze)
	for i in 24:
		var a := i * 2.39996 + ph * (0.5 + (i % 3) * 0.35) * (1.0 if i % 2 == 0 else -1.0)
		var rad := 2.5 + (i % 7) * 1.4
		var p := (c + Vector2(cos(a) * rad, sin(a) * rad * 0.75) - dir * (i % 5) * 1.3).round()
		var q := Vector2i(p)
		if i % 6 == 0:  # a glinting mote
			_glow(canvas, q, _c("Moonlight"))
			continue
		_px(canvas, q.x, q.y, _c(NIGHT[3]))
		_px(canvas, q.x + 1, q.y, _c(NIGHT[1]))
		_px(canvas, q.x, q.y + 1, _c(NIGHT[1]))
		_px(canvas, q.x + 1, q.y + 1, NIGHT_O)
	for k in 3:  # whispers curling off behind
		var col := _c(NIGHT[3])
		for s in 6:
			var t := s / 5.0
			var p := c - dir * (10.0 + t * 8.0) + dir.orthogonal() * (k - 1) * 5.0 + dir.orthogonal() * sin(ph + t * 4.0 + k) * 2.0
			col.a = 0.6 * (1.0 - t)
			_blend_px(canvas, roundi(p.x), roundi(p.y), col)

# --- Dream Thief --------------------------------------------------------------------------------
# Steals Dew: a quick, lanky imp-shadow sprinting hunched over, a wide pale grin under glowing
# slit eyes, clutching a warm ball of stolen dream-light to its chest (the only warm thing on a
# nightmare) and dribbling sparks of it behind.

func _draw_dream_thief(canvas: Image, st: Dictionary) -> void:
	var body := _ramp(NIGHT)
	var o := NIGHT_O
	var warm := _ramp(["Gold", "Glow", "Heartlight"])
	var teeth := _c("Moonlight")
	var f: int = st.f
	var ph: float = st.ph
	var b: int = [0, -2, -1, 0, -2, -1][f]
	var fig := _layer()
	var orb := Vector2.ZERO
	match st.dir:
		SIDE:
			_shadow(canvas, Vector2(30, 44), Vector2(11, 2.5))
			for k: int in [0, 1]:
				var s := sin(ph + k * PI)
				var hip := Vector2(28, 36 + b)
				var foot := Vector2(28 + s * 6, 44 - (2.0 if cos(ph + k * PI) > 0.3 else 0.0))
				_stroke(fig, [hip, hip.lerp(foot, 0.5) + Vector2(2, -1), foot], 0.9, body[k + 1])
			_stroke(fig, [Vector2(24, 34 + b), Vector2(18, 31 + b + roundi(sin(ph) * 2)), Vector2(12, 33 + b)], 0.8, body[1])
			_ellipse(fig, Vector2(30, 31 + b), Vector2(6, 6.5), body)
			_ellipse(fig, Vector2(37, 25 + b), Vector2(5, 4.5), body)
			_lens(fig, Vector2(35, 22 + b), Vector2(27, 17 + b), 1.8, body[3], body[2])
			_stamp(canvas, fig, o)
			for x in range(37, 42):
				_px(canvas, x, 27 + b, teeth if x % 2 == 1 else HOLLOW)
			_px(canvas, 36, 26 + b, teeth)
			_px(canvas, 42, 26 + b, teeth)
			_glow(canvas, Vector2i(38, 23 + b))
			_glow(canvas, Vector2i(40, 23 + b))
			orb = Vector2(35, 33 + b)
		DOWN, UP:
			var down: bool = st.dir == DOWN
			_shadow(canvas, Vector2(32, 44), Vector2(8, 2.5))
			for side: int in [-1, 1]:
				var s := sin(ph + (PI if side > 0 else 0.0))
				_stroke(fig, [Vector2(32 + side * 3, 37 + b), Vector2(32 + side * 4, 44 - (2.0 if s > 0.3 else 0.0))], 0.9, body[1])
				_lens(fig, Vector2(32 + side * 3, 23 + b), Vector2(32 + side * 11, 18 + b), 1.8, body[3], body[2])
			if not down:
				_stroke(fig, [Vector2(32, 38 + b), Vector2(32 + roundi(sin(ph) * 3), 44), Vector2(34, 48)], 0.8, body[1])
			_ellipse(fig, Vector2(32, 33 + b), Vector2(6, 6.5), body)
			_ellipse(fig, Vector2(32, 24 + b), Vector2(5.5, 5), body)
			_stamp(canvas, fig, o)
			if down:
				for x in range(28, 36):
					_px(canvas, x, 27 + b, teeth if x % 2 == 0 else HOLLOW)
				_px(canvas, 27, 26 + b, teeth)
				_px(canvas, 36, 26 + b, teeth)
				_glow(canvas, Vector2i(29, 23 + b))
				_glow(canvas, Vector2i(34, 23 + b))
				orb = Vector2(32, 34 + b)
			else:
				for side: int in [-1, 1]:  # its light spilling out past its sides
					_blend_ellipse(st.warm, Vector2(32 + side * 7, 33 + b), Vector2(2, 3), _c("Glow", 0.35))
	if orb != Vector2.ZERO:
		_blend_ellipse(st.warm, orb, Vector2(4, 4), _c("Glow", 0.3))
		_flat_ellipse(st.warm, orb, Vector2(3, 3), warm[1])
		_flat_ellipse(st.warm, orb + Vector2(0.5, -0.5), Vector2(1.5, 1.5), warm[2])
		var claws := _layer()  # thin arms wrapped round it
		_stroke(claws, [orb + Vector2(-4, -3), orb + Vector2(-3, 2), orb + Vector2(1, 3)], 0.7, body[2])
		_stamp(st.warm, claws, o)  # over the orb, so on the warm layer too
	for k in 2:  # sparks of stolen light dribbling behind
		var t := fposmod(float(f) / FRAMES + k * 0.5, 1.0)
		var back := Vector2(-1, 0) if st.dir == SIDE else (Vector2(0, -1) if st.dir == DOWN else Vector2(0, 1))
		var p := Vector2(32, 34) + back * (8.0 + t * 10.0) + Vector2(0, t * 6.0)
		var col := warm[1]
		col.a = 1.0 - t
		_blend_px(st.warm, roundi(p.x), roundi(p.y), col)

# --- Weeper -------------------------------------------------------------------------------------
# Mends nearby nightmares: a hunched figure in a grey shroud, bald pale head bowed low, long arms
# hanging to the ground, pale slit eyes streaming black tears that drip and pool.

func _draw_weeper(canvas: Image, st: Dictionary) -> void:
	var shroud := _ramp(["Night", "Dusk", "Slate", "Stone"])
	var skin := _ramp(["Slate", "Stone", "Mist"])
	var tear := _c("Void")
	var o := NIGHT_O
	var f: int = st.f
	var ph: float = st.ph
	var h: int = [0, 0, 1, 0, 0, 1][f]
	var side_view: bool = st.dir == SIDE
	_shadow(canvas, Vector2(32, 45), Vector2(11, 2.5))
	var fig := _layer()
	_robe(fig, 31.0, 27.0 + h, 7.0, 45.0, 11.0, -2.0 if side_view else 0.0, ph, shroud)
	_ellipse(fig, Vector2(29 if side_view else 32, 26 + h), Vector2(9, 7), shroud)
	var hc := Vector2(39, 28 + h) if side_view else Vector2(32, 27 + h)
	match st.dir:
		SIDE:
			_stroke(fig, [Vector2(36, 29 + h), Vector2(40, 36 + h), Vector2(41, 43)], 1.0, skin[1])
		DOWN, UP:
			for side: int in [-1, 1]:
				_stroke(fig, [Vector2(32 + side * 7, 29 + h), Vector2(32 + side * 9, 36 + h), Vector2(32 + side * 8, 43)], 1.0, skin[1])
	if st.dir != UP:
		_ellipse(fig, hc, Vector2(4.5, 4.5), skin)
	var ghost := _layer()
	_stamp(ghost, fig, o)
	_merge(canvas, ghost, 0.95)
	var drip := (f % 3) * 2
	match st.dir:
		SIDE:
			_px(canvas, 41, 27 + h, EYE)
			_line(canvas, [Vector2(41, 28 + h), Vector2(41, 32 + h)], tear)
			_px(canvas, 41, 34 + h + drip, tear)
			_blend_ellipse(canvas, Vector2(42, 44), Vector2(3, 1), _c("Void", 0.8))
		DOWN:
			for x: int in [29, 30, 33, 34]:
				_px(canvas, x, 27 + h, EYE)
			for x: int in [29, 34]:
				_line(canvas, [Vector2(x, 28 + h), Vector2(x, 31 + h + (1 if x == 29 else 0))], tear)
				_px(canvas, x, 33 + h + drip, tear)
			_blend_ellipse(canvas, Vector2(32, 44), Vector2(4, 1.2), _c("Void", 0.8))

# --- The Hollow Oak -----------------------------------------------------------------------------
# Act 4 boss and the run's end: the Hollow's corrupted heart, a huge dead oak walking on its roots,
# thorned branches clawing at the sky, knot-hole eyes and a hollow mouth with the cold heart
# burning inside. "grief": it stops and wails, mouth gaping, branches thrown up, shaking. Drawn on
# a 176px frame.

func _draw_hollow_oak(canvas: Image, st: Dictionary) -> void:
	var bark := _ramp(["Void", "Night", "Dusk", "Slate"])
	var thorn := _c("Void")
	var o := NIGHT_O
	var f: int = st.f
	var ph: float = st.ph
	var grief: bool = st.anim == "grief"
	var dir: int = DOWN if grief else st.dir
	var shake: int = [1, -1, 1, -1, 1, -1][f] if grief else 0
	var b: int = 0 if grief else [0, 0, 1, 1, 0, 0][f]
	var cx := 88 + shake
	_shadow(canvas, Vector2(88, 121), Vector2(48, 7))
	# Roots it walks on: they lift and reach in turn.
	var roots := _layer()
	for i in 6:
		var side := -1 if i < 3 else 1
		var j := i % 3
		var lift := 0.0 if grief else maxf(sin(ph + i * 2.1), 0.0) * 4.0
		var start := Vector2(cx + side * (6 + j * 5), 104 + b)
		var foot := Vector2(88 + side * (20 + j * 14) + (0.0 if grief else sin(ph + i * 2.1) * 3.0), 116 + j * 3 - lift)
		var mid := start.lerp(foot, 0.5) + Vector2(side * 2, -7)
		_stroke(roots, [start, mid], 4.0 - j * 0.5, bark[1])
		_stroke(roots, [mid, foot], 2.5 - j * 0.4, bark[1])
	_stamp(canvas, roots, o)
	# Branches: thick at the trunk, thinning to thorned twigs; thrown up in grief.
	var top := Vector2(cx, 52 + b)
	var branches: Array = [[Vector2(0, 0), Vector2(-8, -14), Vector2(-20, -26), Vector2(-34, -30)],
		[Vector2(-4, -2), Vector2(-16, -6), Vector2(-30, -4), Vector2(-44, -12)],
		[Vector2(4, -2), Vector2(16, -8), Vector2(30, -6), Vector2(44, -14)],
		[Vector2(2, 0), Vector2(8, -16), Vector2(18, -30), Vector2(30, -38)],
		[Vector2(0, 0), Vector2(-2, -18), Vector2(-6, -32), Vector2(-4, -44)],
		[Vector2(-6, 4), Vector2(-22, 4), Vector2(-36, 10)],
		[Vector2(6, 4), Vector2(22, 6), Vector2(36, 14)]]
	var crown := _layer()
	var twigs: Array[Vector2] = []
	for br: Array in branches:
		var pts: Array = []
		for i in br.size():
			var t := float(i) / (br.size() - 1)
			var p: Vector2 = br[i]
			if grief:
				p += Vector2(sin(f * 2.0 + i) * 2.0 * t, -8.0 * t)
			else:
				p += Vector2(sin(ph + p.x * 0.05) * 1.5 * t, 0)
			pts.append(top + p)
		for i in pts.size() - 1:
			_stroke(crown, [pts[i], pts[i + 1]], lerpf(4.0, 1.0, float(i) / (pts.size() - 1)), bark[2])
		for i in pts.size() - 1:
			for s in range(1, 4):
				twigs.append((pts[i] as Vector2).lerp(pts[i + 1], s / 4.0))
	_stamp(canvas, crown, o)
	for i in twigs.size():  # thorns sticking out of the branches
		var p: Vector2 = twigs[i]
		var d := Vector2(1, -1) if i % 2 == 0 else Vector2(-1, -1)
		_px(canvas, roundi(p.x + d.x * 2), roundi(p.y + d.y * 2), thorn)
		_px(canvas, roundi(p.x + d.x * 3), roundi(p.y + d.y * 3), thorn)
	# The trunk.
	var trunk := _layer()
	_robe(trunk, cx, 46.0 + b, 14.0, 112.0 + b, 23.0, 0.0, ph * 0.2, bark)
	var mouth_r := Vector2(10, 15) if grief else Vector2(8, 11)
	var glow: Array[Vector2i] = []
	if dir == UP:
		glow = _crack(trunk, Vector2(cx, 80 + b), Vector2(14, 28), [[Vector2(0.1, -0.9), Vector2(-0.2, -0.4), Vector2(0.15, 0.1), Vector2(-0.1, 0.7)]], HOLLOW)
	_stamp(canvas, trunk, o)
	_crawl(canvas, glow, f, 3)
	match dir:
		DOWN:
			for side: int in [-1, 1]:
				var e := Vector2(cx + side * 8, 68 + b)
				_flat_ellipse(canvas, e, Vector2(4, 5), HOLLOW)
				_line(canvas, [e + Vector2(-4, -7), e + Vector2(4, -6 - side)], bark[0])
				_glow(canvas, Vector2i(e.round()), EYE, EYE_HALO)
			_oak_mouth(canvas, Vector2(cx, 90 + b), mouth_r, bark, f)
		SIDE:
			var e := Vector2(cx + 11, 68 + b)
			_flat_ellipse(canvas, e, Vector2(3, 4.5), HOLLOW)
			_glow(canvas, Vector2i(e.round()), EYE, EYE_HALO)
			_oak_mouth(canvas, Vector2(cx + 10, 90 + b), Vector2(5, 10), bark, f)
	if grief:  # the wail rings out
		var r := 24.0 + f * 9.0
		for y in S:
			for x in S:
				var q := ((Vector2(x + 0.5, y + 0.5) - Vector2(88, 72)) / Vector2(r, r * 0.7)).length()
				if absf(q - 1.0) * r < 0.8 and (x + y) % 2 == 0:
					_blend_px(canvas, x, y, _c("Moonlight", 0.4 * (1.0 - f / 6.0)))

# The hollow mouth: dark, splintered at the rim, the heart's cold fire burning in its depths.
func _oak_mouth(canvas: Image, c: Vector2, r: Vector2, bark: Array[Color], f: int) -> void:
	_flat_ellipse(canvas, c, r, HOLLOW)
	for i in 5:  # splinters
		var x := c.x - r.x * 0.6 + i * r.x * 0.3
		for d in 3:
			_px(canvas, roundi(x), roundi(c.y - r.y + 1 + d), bark[2] if d < 2 else bark[1])
			if i % 2 == 1:
				_px(canvas, roundi(x), roundi(c.y + r.y - 2 - d), bark[1])
	_heart_fire(canvas, c + Vector2(0, r.y * 0.25), f)

# --- Thorn-sapling (obstacle) -------------------------------------------------------------------
# Planted by the Hollow Oak beside the path: a twisted black sapling of thorns on a patch of
# blighted earth, a faint cold light in its knot. "idle" sways, "grow" sprouts it, "wither"
# crumbles it to ash when the Oak is dispelled.

func _draw_thorn_sapling(canvas: Image, st: Dictionary) -> void:
	var bark := _ramp(["Void", "Night", "Dusk", "Slate"])
	var thorn := _c("Void")
	var o := NIGHT_O
	var f: int = st.f
	var g: float = [0.12, 0.3, 0.5, 0.7, 0.88, 1.0][f] if st.anim == "grow" else 1.0
	var crumble: float = f / 5.0 if st.anim == "wither" else 0.0
	var sway := sin(st.ph) if st.anim == "idle" else 0.0
	for y in range(39, 49):  # blighted earth
		for x in range(18, 47):
			var q := ((Vector2(x + 0.5, y + 0.5) - Vector2(32, 44)) / Vector2(13, 4)).length()
			if q < 1.0 and not (q > 0.75 and (x + y) % 2 == 0):
				_px(canvas, x, y, _c("Dread") if (x * 3 + y) % 7 else _c("Dread"))
	var tree := _layer()
	var height := 26.0 * g
	var trunk: Array = [Vector2(32, 44), Vector2(33, 44 - height * 0.4), Vector2(31, 44 - height * 0.75), Vector2(32 + sway, 44 - height)]
	_stroke(tree, trunk.slice(0, 2), 2.2 * g + 0.4, bark[2])
	_stroke(tree, trunk.slice(1, 4), 1.4 * g + 0.3, bark[2])
	var tips: Array[Vector2] = []
	for k in 3:
		var t: float = [0.45, 0.65, 0.85][k]
		var root: Vector2 = (trunk[1] as Vector2).lerp(trunk[3], (t - 0.4) / 0.6) if t > 0.4 else trunk[1]
		var side := -1.0 if k % 2 == 0 else 1.0
		var tip := root + Vector2(side * 8.0 * g, -5.0 * g) + Vector2(sway * t, 0)
		_stroke(tree, [root, tip], 0.8, bark[2])
		tips.append(tip)
	var ghost := _layer()
	_stamp(ghost, tree, o)
	for i in 12:  # thorns
		var t := i / 11.0
		var p := (trunk[0] as Vector2).lerp(trunk[3], t) + Vector2(sway * t, 0)
		var d := 1 if i % 2 == 0 else -1
		_px(ghost, roundi(p.x) + d * 2, roundi(p.y), thorn)
	for tip in tips:
		_px(ghost, roundi(tip.x), roundi(tip.y) - 1, thorn)
	var knot := Vector2i(Vector2(32, 44 - height * 0.45).round())
	if crumble < 0.5:
		var pulse: float = [1.0, 0.8, 0.6, 0.5, 0.6, 0.8][f]
		_glow(ghost, knot, EYE.lerp(_c("Mist"), 1.0 - pulse), EYE_HALO)
	if crumble > 0.0:  # crumbling from the top down into grey ash
		for y in S:
			for x in S:
				var c := ghost.get_pixel(x, y)
				if c.a == 0.0:
					continue
				var from_top := 1.0 - float(y - 18) / 26.0
				if not _keep(x, y, 1.0 - crumble * 1.3 + from_top * -0.3 + 0.3):
					ghost.set_pixel(x, y, Color(0, 0, 0, 0))
				else:
					ghost.set_pixel(x, y, c.lerp(_c("Slate"), crumble))
		for k in 5:  # ash falling
			var p := Vector2(26 + k * 3, 20 + crumble * 20 + (k % 2) * 3)
			_px(ghost, roundi(p.x), roundi(p.y), _c("Slate"))
	_merge(canvas, ghost)

# --- The Night Mare -----------------------------------------------------------------------------
# Act 1 pool boss, laps the maze until dispelled: a black horse made of smoke, its mane and tail
# streaming off as smoke, legs fading out before the hooves (they never touch the ground), eyes
# like cold coals. "gallop" is its bolt: stretched low, mane flat, legs reaching. Drawn on a 112px
# frame; _horse() is also the Huntsman's mount.

func _draw_night_mare(canvas: Image, st: Dictionary) -> void:
	_shadow(canvas, Vector2(56, 78), Vector2(28 if st.dir == SIDE or st.anim == "gallop" else 16, 3.5))
	_horse(canvas, st, st.anim == "gallop")

# Draws the smoke horse on a 112px frame (ground at 77, hooves floating at ~71). Returns the point
# on its back where a rider sits.
func _horse(canvas: Image, st: Dictionary, gallop: bool) -> Vector2:
	var body := _ramp(NIGHT)
	var o := NIGHT_O
	var f: int = st.f
	var ph: float = st.ph
	var smoke := _c("Shade", 0.75)
	var ghost := _layer()
	var eyes: Array[Vector2i] = []
	var saddle := Vector2(50, 38)
	var dir: int = SIDE if gallop else st.dir
	match dir:
		SIDE:
			var ext := sin(ph)
			var b: float = (2.0 + maxf(-ext, 0.0) * 2.0) if gallop else float([0, -1, -2, -1, 0, -1][f])
			var tail: Array = [Vector2(26, 44 + b), Vector2(14, 44 + b), Vector2(2, 46 + b)] if gallop else [Vector2(26, 44 + b), Vector2(16, 48 + b), Vector2(6, 56 + b)]
			_smoke_trail(canvas, tail, f, 4.5, smoke)
			var far := _layer()
			var near := _layer()
			if gallop:
				for leg: Vector2 in [Vector2(68, 1), Vector2(36, -1)]:  # x, forward sign
					var top := Vector2(leg.x, 52 + b)
					var foot := top + Vector2(leg.y * (ext * 10.0 + 3.0), 15.0 - absf(ext) * 5.0)
					_stroke(near, [top, top.lerp(foot, 0.5) + Vector2(-leg.y * 2.0, 1.0), foot], 1.6, body[1])
					_stroke(far, [top + Vector2(-3 * leg.y, 0), foot + Vector2(-4 * leg.y, -2)], 1.4, body[0])
			else:
				_mare_leg(far, Vector2(70, 52 + b), ph + PI, true, body[0])
				_mare_leg(far, Vector2(38, 52 + b), ph, false, body[0])
				_mare_leg(near, Vector2(66, 53 + b), ph, true, body[1])
				_mare_leg(near, Vector2(34, 53 + b), ph + PI, false, body[1])
			_stamp(ghost, far, o)
			var fig := _layer()
			var stretch := 1.1 if gallop else 1.0
			_ellipse(fig, Vector2(36, 47 + b), Vector2(11, 10), body)
			_ellipse(fig, Vector2(52, 48 + b), Vector2(18 * stretch, 9.5 - (1.0 if gallop else 0.0)), body)
			_ellipse(fig, Vector2(68, 47 + b), Vector2(9, 10.5), body)
			var hd := Vector2(90, 30 + b) if gallop else Vector2(84, 25 + b)
			_stroke(fig, [Vector2(70, 42 + b), hd.lerp(Vector2(70, 42 + b), 0.5) + Vector2(0, -3), hd], 5.5, body[2])
			_ellipse(fig, hd, Vector2(6, 5.5), body)
			_lens(fig, hd + Vector2(0, 2), hd + Vector2(15, 9), 4.5, body[2], body[1])
			if gallop:
				_lens(fig, hd + Vector2(-2, -4), hd + Vector2(-10, -8), 1.6, body[2], body[1])
			else:
				_lens(fig, hd + Vector2(-2, -5), hd + Vector2(-5, -13), 1.6, body[2], body[1])
				_lens(fig, hd + Vector2(2, -5), hd + Vector2(1, -13), 1.5, body[2], body[1])
			_stamp(ghost, fig, o)
			_stamp(ghost, near, o)
			_px(ghost, int(hd.x) + 13, int(hd.y) + 7, HOLLOW)
			eyes = [Vector2i(hd) + Vector2i(3, -2)]
			var mane: Array = [hd + Vector2(-3, -5), hd + Vector2(-12, -4), Vector2(62, 36 + b)] if gallop else [hd + Vector2(-3, -5), hd + Vector2(-9, 3), Vector2(66, 38 + b)]
			_merge(canvas, _fade_legs(ghost, 66 + roundi(b), 73 + roundi(b)))
			_smoke_trail(canvas, mane, f, 3.0, smoke)
			saddle = Vector2(50, 38 + b)
			if gallop:
				for i in 3:  # the coals streak behind
					_px(canvas, eyes[0].x - 1 - i, eyes[0].y, [EYE, _c("Dewlight"), _c("Dew")][i])
		DOWN, UP:
			var down: bool = dir == DOWN
			var b: int = [0, -1, -2, -1, 0, -1][f]
			var legs := _layer()
			for side: int in [-1, 1]:
				var s := sin(ph + (PI if side > 0 else 0.0))
				var lift := 3.0 if s > 0.3 else 0.0
				var fx := 56 + side * (6 if down else 7)
				_stroke(legs, [Vector2(56 + side * 11, 54 + b), Vector2(56 + side * 11, 68 - lift * 0.5)], 1.4, body[0])  # far pair
				_stroke(legs, [Vector2(fx, 58 + b), Vector2(fx, 66 - lift), Vector2(fx, 72 - lift)], 1.7, body[1])
			if not down:
				_smoke_trail(canvas, [Vector2(56, 60 + b), Vector2(58, 68 + b), Vector2(55, 76)], f, 4.0, smoke)
			var fig := _layer()
			if down:
				_smoke_trail(canvas, [Vector2(56, 32 + b), Vector2(54, 24 + b), Vector2(57, 14 + b)], f, 4.0, smoke)
				_ellipse(fig, Vector2(56, 44 + b), Vector2(11, 13), body)
				_ellipse(fig, Vector2(56, 54 + b), Vector2(16, 10.5), body)
			else:
				_ellipse(fig, Vector2(56, 28 + b), Vector2(5.5, 6), body)
				for side: int in [-1, 1]:
					_lens(fig, Vector2(56 + side * 3, 24 + b), Vector2(56 + side * 5, 16 + b), 1.6, body[2], body[1])
				_ellipse(fig, Vector2(56, 42 + b), Vector2(11, 13), body)
				_ellipse(fig, Vector2(56, 55 + b), Vector2(13, 10), body)
			_stamp(ghost, legs, o)
			_stamp(ghost, fig, o)
			if down:
				var head := _layer()
				for side: int in [-1, 1]:
					_lens(head, Vector2(56 + side * 3, 34 + b), Vector2(56 + side * 7, 25 + b), 1.7, body[2], body[1])
				_ellipse(head, Vector2(56, 39 + b), Vector2(6.5, 6), body)
				_lens(head, Vector2(56, 36 + b), Vector2(56, 64 + b), 5.5, body[2], body[1])
				_stamp(ghost, head, o)
				_px(ghost, 54, 61 + b, HOLLOW)
				_px(ghost, 58, 61 + b, HOLLOW)
				eyes = [Vector2i(50, 40 + b), Vector2i(62, 40 + b)]
			_merge(canvas, _fade_legs(ghost, 64 + b, 72 + b))
			if not down:
				_smoke_trail(canvas, [Vector2(56, 22 + b), Vector2(58, 14 + b), Vector2(55, 6 + b)], f, 3.0, smoke)
			saddle = Vector2(56, 38 + b)
	for e in eyes:  # cold coals
		_glow(canvas, e, EYE, EYE_HALO)
		_px(canvas, e.x + 1, e.y, _c("Dewlight"))
	return saddle

# Horse leg from shoulder or hip: two segments, the knee bending the right way, swinging with
# `phase`; the foot lifts as it comes forward.
func _mare_leg(layer: Image, top: Vector2, phase: float, fore: bool, color: Color) -> void:
	var s := sin(phase)
	var lift := 3.0 if cos(phase) > 0.3 else 0.0
	var knee := top + Vector2(s * 2.0 + (1.0 if fore else -2.0), 8.0 - lift * 0.5)
	var foot := top + Vector2(s * 5.0, 18.0 - lift)
	_stroke(layer, [top, knee], 1.8, color)
	_stroke(layer, [knee, foot], 1.4, color)

# Legs (and anything else low) dissolve into smoke between two rows.
func _fade_legs(img: Image, from_y: int, to_y: int) -> Image:
	_dissolve(img, Vector2(0, from_y), Vector2(0, to_y))
	return img

# Smoke streaming along a polyline: soft puffs shrinking and thinning towards the end, rippling.
func _smoke_trail(canvas: Image, pts: Array, f: int, r0: float, color: Color) -> void:
	var n := 14
	for i in n:
		var t := float(i) / (n - 1)
		var seg := minf(t * (pts.size() - 1), pts.size() - 1.001)
		var k := int(seg)
		var p: Vector2 = (pts[k] as Vector2).lerp(pts[k + 1], seg - k)
		p += Vector2(sin(f * 1.1 + t * 7.0), cos(f * 0.9 + t * 5.0)) * t * 1.8
		var col := color
		col.a = color.a * (1.0 - t * 0.85)
		_blend_ellipse(canvas, p, Vector2.ONE * (r0 * (1.0 - t * 0.6)), col)

# --- The Scarecrow ------------------------------------------------------------------------------
# Act 1 pool boss: a sack-headed scarecrow hopping on its crooked pole, a stitched grin under
# hollow eyes, a floppy hat, a ragged coat on a crossbar with straw poking from the cuffs, and
# crows peering out from under the coat. "burst": the coat flies open and a flock bursts out.

func _draw_scarecrow(canvas: Image, st: Dictionary) -> void:
	var coat := _ramp(["Void", "Night", "Dusk", "Slate"])
	var sack := _ramp(["Slate", "Stone", "Mist"])  # pale burlap, so the stitched face reads
	var straw := _c("Mist")
	var wood := _c("Night")
	var o := NIGHT_O
	var f: int = st.f
	var ph: float = st.ph
	var burst: bool = st.anim == "burst"
	var dir: int = DOWN if burst else st.dir
	var y: int = 0 if burst else -[0, 2, 5, 6, 3, 0][f]
	var flare: float = [16.0, 20.0, 24.0, 24.0, 20.0, 17.0][f] if burst else 16.0
	var side_view := dir == SIDE
	_shadow(canvas, Vector2(56, 78), Vector2(14, 3))
	var pole := _layer()
	_stroke(pole, [Vector2(57, 77 + y), Vector2(55, 70 + y), Vector2(56, 60 + y)], 1.5, wood)
	_stamp(canvas, pole, o)
	if not burst:  # crows peering out from under the coat
		for p: Vector2i in ([Vector2i(52, 63)] if side_view else [Vector2i(47, 62), Vector2i(65, 63)]):
			_crow_head(canvas, p + Vector2i(0, y), f)
	var arms: Array = [[Vector2(56, 38), Vector2(76, 40)], [Vector2(56, 38), Vector2(45, 39)]] if side_view else [[Vector2(56, 38), Vector2(26, 40)], [Vector2(56, 38), Vector2(86, 38)]]
	if burst:
		arms = [[Vector2(56, 38), Vector2(26, 34 - f)], [Vector2(56, 38), Vector2(86, 32 - f)]]
	for arm: Array in arms:  # the crossbar poking out of the sleeves
		var a: Vector2 = arm[0] + Vector2(0, y)
		var e: Vector2 = arm[1] + Vector2(0, y)
		_line(canvas, [e, e + (e - a).normalized() * 4.0], wood)
	var fig := _layer()
	for arm: Array in arms:
		_stroke(fig, [arm[0] + Vector2(0, y), arm[1] + Vector2(0, y)], 3.4, coat[2])
	_robe(fig, 56.0, 34.0 + y, 7.0 if side_view else 10.0, 64.0 + y, flare * (0.75 if side_view else 1.0), -2.0 if side_view else 0.0, ph, coat)
	for p: Vector2 in ([Vector2(54, 50)] if side_view else [Vector2(50, 48), Vector2(61, 55)]):  # patches
		for yy in 4:
			for xx in 4:
				if fig.get_pixel(int(p.x) + xx, int(p.y) + y + yy).a > 0.0:
					fig.set_pixel(int(p.x) + xx, int(p.y) + y + yy, coat[3] if (xx + yy) % 3 else coat[1])
	_stamp(canvas, fig, o)
	for arm: Array in arms:  # straw poking out of the cuffs
		var e: Vector2 = arm[1] + Vector2(0, y)
		var out := signf(e.x - 56.0)
		for k in 4:
			_line(canvas, [e + Vector2(0, k - 1), e + Vector2(out * (3 + k % 2), k + 2)], straw)
	# The sack head, tied at the neck, and the hat.
	var hc := Vector2(57 if side_view else 56, 24 + y)
	var head := _layer()
	_ellipse(head, hc, Vector2(9 if side_view else 10, 11), sack)
	for yy in S:
		for xx in S:
			if head.get_pixel(xx, yy).a > 0.0 and (xx + yy) % 4 == 0:
				head.set_pixel(xx, yy, _darker(sack, head.get_pixel(xx, yy)))
	_stamp(canvas, head, o)
	_line(canvas, [hc + Vector2(-5, 10), hc + Vector2(5, 10)], wood)
	var hat := _layer()
	_flat_ellipse(hat, hc + Vector2(0, -10), Vector2(10 if side_view else 14, 3), coat[1])
	_lens(hat, hc + Vector2(-5, -10), hc + Vector2(6 if side_view else 4, -24), 6.0, coat[2], coat[1])
	_stamp(canvas, hat, o)
	match dir:
		DOWN:
			for side: int in [-1, 1]:
				_flat_ellipse(canvas, hc + Vector2(side * 5, -3), Vector2(2.2, 2.2), HOLLOW)
				_glow(canvas, Vector2i(hc) + Vector2i(side * 5 - (1 if side < 0 else 0), -3))
			_line(canvas, [hc + Vector2(-8, 5), hc + Vector2(0, 8), hc + Vector2(8, 5)], HOLLOW)
			for x in range(int(hc.x) - 7, int(hc.x) + 8, 2):  # the stitches across the grin
				var gy := roundi(hc.y + 5 + 3.0 * (1.0 - absf(x - hc.x) / 8.0))
				_px(canvas, x, gy - 1, HOLLOW)
				_px(canvas, x, gy + 1, HOLLOW)
		SIDE:
			_flat_ellipse(canvas, hc + Vector2(5, -3), Vector2(1.8, 2.2), HOLLOW)
			_glow(canvas, Vector2i(hc) + Vector2i(5, -3))
			_line(canvas, [hc + Vector2(2, 6), hc + Vector2(6, 7), hc + Vector2(9, 4)], HOLLOW)
			for x: int in [3, 5, 7]:
				_px(canvas, int(hc.x) + x, int(hc.y) + 5, HOLLOW)
				_px(canvas, int(hc.x) + x, int(hc.y) + 8, HOLLOW)
	if burst:  # the flock bursting out of the coat
		for i in 6:
			var a := -PI * 0.5 + (i - 2.5) * 0.55
			var r := 8.0 + (f + 1) * 7.0
			var p := Vector2(56, 52) + Vector2(cos(a) * 1.4, sin(a)) * r
			_crow_small(canvas, Vector2i(p.round()), (f + i) % 2 == 0)
		for k in 8:  # loose feathers
			var t := (f + 1) / 6.0
			var p := Vector2(56 + (k - 3.5) * 5.0 * t * 1.6, 54 - sin(k * 1.3) * 16.0 * t)
			_px(canvas, roundi(p.x), roundi(p.y), NIGHT_O)

# A crow's head peeking out: dark round head, beak tip, one cold eye that blinks now and then.
func _crow_head(canvas: Image, p: Vector2i, f: int) -> void:
	var layer := _layer()
	_flat_ellipse(layer, Vector2(p), Vector2(2.6, 2.2), _c("Dread"))
	_stamp(canvas, layer, NIGHT_O)
	_px(canvas, p.x + 3, p.y + 1, _c("Dusk"))
	if f % 5 != 4:
		_px(canvas, p.x + 1, p.y - 1, EYE)

# A tiny flying crow for the burst: body and two wing strokes, up or down.
func _crow_small(canvas: Image, p: Vector2i, up: bool) -> void:
	for d: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1)]:
		_px(canvas, p.x + d.x, p.y + d.y, _c("Dread"))
	var wy := -2 if up else 1
	_line(canvas, [Vector2(p) + Vector2(-1, 0), Vector2(p) + Vector2(-4, wy)], NIGHT_O)
	_line(canvas, [Vector2(p) + Vector2(1, 0), Vector2(p) + Vector2(4, wy)], NIGHT_O)
	_px(canvas, p.x + 1, p.y, EYE)

# --- Crow ---------------------------------------------------------------------------------------
# The Scarecrow's crows (fast, 1 leaf): a small ragged black crow flying the route, cold eye,
# tattered wings beating.

func _draw_crow(canvas: Image, st: Dictionary) -> void:
	var body := _ramp(["Void", "Dread", "Night", "Dusk"])
	var o := NIGHT_O
	var f: int = st.f
	var d: float = [0.0, 0.3, 0.7, 1.0, 0.6, 0.25][f]  # wing: 0 = up, 1 = down
	var h := roundi(sin(st.ph) * 1.5)
	_shadow(canvas, Vector2(32, 46), Vector2(5, 1.5))
	var fig := _layer()
	match st.dir:
		SIDE:
			var sh := Vector2(31, 25 + h)
			_lens(fig, sh + Vector2(1, 0), sh + Vector2(-9, -9 + 18 * d), 3.2, body[2], body[1])  # far wing
			_ellipse(fig, Vector2(31, 27 + h), Vector2(6, 3.5), body)
			_ellipse(fig, Vector2(37, 25 + h), Vector2(3.2, 3), body)
			_poly_fill(fig, PackedVector2Array([Vector2(26, 26 + h), Vector2(18, 23 + h), Vector2(17, 27 + h), Vector2(19, 30 + h)]), body[1])
			_lens(fig, sh, sh + Vector2(-8, -10 + 20 * d), 3.4, body[3], body[2])
		DOWN, UP:
			var down: bool = st.dir == DOWN
			for side: int in [-1, 1]:
				_lens(fig, Vector2(32 + side * 2, 26 + h), Vector2(32 + side * 15, 18 + 16 * d + h), 3.2, body[3], body[2])
			_ellipse(fig, Vector2(32, 27 + h), Vector2(4, 6), body)
			var tail_y := 20 if down else 34
			_poly_fill(fig, PackedVector2Array([Vector2(32, 27 + h), Vector2(28, tail_y + h), Vector2(36, tail_y + h)]), body[1])
			_ellipse(fig, Vector2(32, (33 if down else 21) + h), Vector2(3, 3), body)
	for y in S:  # ragged: nick the feather edges
		for x in S:
			if fig.get_pixel(x, y).a > 0.0 and (x * 3 + y * 5) % 7 == 0 and (x == 0 or x == S - 1 or fig.get_pixel(x - 1, y).a == 0.0 or fig.get_pixel(x + 1, y).a == 0.0):
				fig.set_pixel(x, y, Color(0, 0, 0, 0))
	_stamp(canvas, fig, o)
	match st.dir:
		SIDE:
			_line(canvas, [Vector2(40, 25 + h), Vector2(44, 26 + h)], _c("Dusk"))
			_px(canvas, 38, 24 + h, EYE)
		DOWN:
			_line(canvas, [Vector2(32, 36 + h), Vector2(32, 38 + h)], _c("Dusk"))
			_px(canvas, 30, 32 + h, EYE)
			_px(canvas, 33, 32 + h, EYE)

func _poly_fill(layer: Image, pts: PackedVector2Array, color: Color) -> void:
	var box := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		box = box.expand(p)
	for y in range(maxi(0, floori(box.position.y)), mini(S, ceili(box.end.y) + 1)):
		for x in range(maxi(0, floori(box.position.x)), mini(S, ceili(box.end.x) + 1)):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				layer.set_pixel(x, y, color)
