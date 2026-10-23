extends SceneTree
# Art for the rebuilt Calling evolutions' marks (Roguelite asset chat; Roguelite Code's request 2026-10-23, section 33).
# Writes assets/effects/calling_evo/<name>.png (frames side by side) and calling_evo.json (frame size, frames, fps,
# anchor, loop, where it goes). Not wired by this tool: Roguelite Code draws them.
# Rework 2026-10-23 (owner: "make the art look better … go over with a council that fits the theme of other assets and
# the standard of quality"; four-seat art council: art direction, effects peer, readability, theme) — the rules it set:
# - Lights (flames, sparks, stars, glows) have NO dark outline: a bright core lit from the upper left, Glow then Gold
#   then Ember, and a banded dithered halo (checker near, 1-in-4 out, alpha steps 0.75 / 0.4, phase moves each frame),
#   as crit_flare / spark_burst / calling_spark do. Solid objects (moth, caps, bell, notes, sticks, thorns) keep a
#   Night outline and the 1 px upper-left rim of light.
# - Each mark is a thing that says its evolution: a bonfire, a moth at a flame, fairy lights on a string, a warm star,
#   firefly motes circling, an eye-shaped glint, a mushroom throne, rot with fallen caps, a moon in still water, a
#   nightmare's dripping trail, beamed quick notes, a humming thorn bead.
# - Warden effects are warm and in the family's colours; only nightmare traces (the dripping trail) may go cold.
# - Ground marks are hand-shaped (no hash grain, no dithered soft edges), sit under the path's value, and keep one light
#   accent so they read on dark ground. Over-head marks are 9 px or more tall; neighbours differ in silhouette.
# - Loops change every frame; one-shots have a peak and a dithered fade.
# Heartwood 32 only (HeartwoodPalette.snap_image), 1x at 64 px per cell (art_direction.md "detailed 64").
# Run:  Godot --headless --path . --script res://tools/calling_evo_art.gd

const OUT := "res://assets/effects/calling_evo/"
const PALETTE_TOOL := "res://tools/art/heartwood_palette.gd"

# Heartwood 32
const NIGHT := Color("24243c")
const DUSK := Color("3c3c5c")
const SLATE := Color("5c5a78")
const SHADE := Color("2c2444")
const BRUISE := Color("4c3c74")
const STONE := Color("8c8cac")
const MIST := Color("b4b0c8")
const MOON := Color("dce8f4")
const DEEPMOSS := Color("1c3c2c")
const MOSS := Color("34643c")
const LEAF := Color("5c944c")
const SPRIG := Color("9cc46c")
const NEWLEAF := Color("d4ec9c")
const ROOT := Color("241c14")
const BARK := Color("5c3c24")
const OAK := Color("8c5c34")
const DEADWOOD := Color("bca48c")
const LOAM := Color("6c5c5c")
const MOONPATH := Color("dccdb2")
const EMBER := Color("b8662c")
const GOLD := Color("e9a83c")
const GLOW := Color("fcd47c")
const HEART := Color("fff4dc")
const ORCHID := Color("bc44dc")
const BLOSSOM := Color("ec9cf4")
const POOL := Color("2c4c5c")
const DEW := Color("4c8ca4")
const DEWLIGHT := Color("9cd4fc")

var index := {}

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_firefly()
	_sporeling()
	_dewdrop()
	_bellflower()
	var file := FileAccess.open(OUT + "calling_evo.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({marks = index}, "\t") + "\n")
	print("calling_evo: ", index.size(), " sheets")
	quit()

# --- Sheets and primitives ----------------------------------------------------------------------------------------

func _sheet(name: String, size: Vector2i, frames: int, fps: float, anchor: Vector2i, loop: bool, draw: Callable, use: String) -> void:
	var sheet := Image.create_empty(size.x * frames, size.y, false, Image.FORMAT_RGBA8)
	for f in frames:
		var img := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
		draw.call(img, f)
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, size), Vector2i(f * size.x, 0))
	if ResourceLoader.exists(PALETTE_TOOL):
		(load(PALETTE_TOOL) as Script).snap_image(sheet)
	sheet.save_png(OUT + name + ".png")
	index[name] = {file = name + ".png", frame_size = [size.x, size.y], frames = frames, fps = fps,
		anchor = [anchor.x, anchor.y], loop = loop, use = use}

func _blank(img: Image) -> Image:
	return Image.create_empty(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)

func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)

func _empty(img: Image, x: int, y: int) -> bool:
	return x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height() or img.get_pixel(x, y).a == 0.0

# A pixel grid: one string per row, `keys` maps each character to a colour ('.' and ' ' are empty).
func _grid(img: Image, rows: Array, keys: Dictionary, at: Vector2i = Vector2i.ZERO) -> void:
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if keys.has(row[x]):
				_px(img, at.x + x, at.y + y, keys[row[x]])

# Lays `src`'s opaque pixels over `dst`.
func _over(dst: Image, src: Image, at: Vector2i = Vector2i.ZERO) -> void:
	for y in src.get_height():
		for x in src.get_width():
			var c := src.get_pixel(x, y)
			if c.a > 0.0:
				_px(dst, at.x + x, at.y + y, c)

# A 1 px outline round everything opaque in `img` (solid objects only).
func _outline(img: Image, ink: Color = NIGHT) -> void:
	var add: Array = []
	for y in img.get_height():
		for x in img.get_width():
			if not _empty(img, x, y):
				continue
			for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				if not _empty(img, x + d.x, y + d.y) and img.get_pixel(x + d.x, y + d.y).a >= 0.99:
					add.append(Vector2i(x, y))
					break
	for p: Vector2i in add:
		img.set_pixelv(p, ink)

# The 1 px rim of light: pixels of `colours` whose left or upper neighbour is empty, on the upper-left side of `centre`.
func _rim(img: Image, colours: Array, light: Color, centre: Vector2) -> void:
	var set: Array = []
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a == 0.0 or not colours.has(Color(c.r, c.g, c.b)):
				continue
			if (x + 0.5 - centre.x) + (y + 0.5 - centre.y) > 0.0:
				continue
			if _empty(img, x - 1, y) or _empty(img, x, y - 1):
				set.append(Vector2i(x, y))
	for p: Vector2i in set:
		img.set_pixelv(p, light)

# Banded glow (art_direction.md; effect_art_generator's _glow): a checker near the light, 1-in-4 further out, in alpha
# steps, only on empty pixels, its pattern shifted by `phase` so it shimmers frame to frame.
func _halo(img: Image, c: Vector2, r: float, col: Color, phase: int, near_alpha: float = 0.4, top_only: bool = false) -> void:
	for y in range(maxi(0, floori(c.y - r)), mini(img.get_height(), ceili(c.y + r) + 1)):
		for x in range(maxi(0, floori(c.x - r)), mini(img.get_width(), ceili(c.x + r) + 1)):
			if not _empty(img, x, y) or (top_only and y > c.y + 1.0):
				continue
			var d := Vector2(x + 0.5 - c.x, y + 0.5 - c.y).length() / r
			if d < 0.55 and (x + y + phase) % 2 == 0:
				_px(img, x, y, Color(col, near_alpha))
			elif d <= 1.0 and (x + 2 * y + phase) % 4 == 0:
				_px(img, x, y, Color(col, 0.4))

func _line(img: Image, a: Vector2i, b: Vector2i, col: Color) -> void:
	var n := maxi(absi(b.x - a.x), absi(b.y - a.y))
	for i in n + 1:
		var t := float(i) / maxf(n, 1)
		_px(img, roundi(lerpf(a.x, b.x, t)), roundi(lerpf(a.y, b.y, t)), col)

# --- Lantern Light (Firefly) --------------------------------------------------------------------------------------

const FLAME := {"y": GOLD, "G": GLOW, "H": HEART, "E": EMBER}
const FLAME_READY := {"y": GLOW, "G": HEART, "H": HEART, "E": GOLD}  # Ready burns hotter and paler, still warm (never Moonlight)

func _firefly() -> void:
	_sheet("lf_waiting_flame", Vector2i(13, 15), 4, 8.0, Vector2i(6, 14), true, _bonfire,
		"Bonfire: a little bonfire, a two-tongued flame on crossed sticks, over a nightmare holding a waiting crit (LanternMark; was two circles at (-10, -30)). Anchor = the sticks' foot.")
	_sheet("lf_moth_flame", Vector2i(19, 19), 4, 6.0, Vector2i(9, 18), true, _moth_flame.bind(false),
		"Moth to Flame: the kept crit, a tall flame with a moth circling and dipping to it (LanternMark; was circles at (10, -32)). Anchor = the flame's foot.")
	_sheet("lf_moth_flame_ready", Vector2i(19, 19), 4, 9.0, Vector2i(9, 18), true, _moth_flame.bind(true),
		"Moth to Flame, ready (its 4 hits are in): the flame burns hotter with a denser halo and the moth's wings catch fire. Same frames and anchor as lf_moth_flame.")
	_sheet("lf_strung_pip", Vector2i(7, 9), 4, 4.0, Vector2i(3, 1), true, _bulb,
		"Strung Lights: one fairy-light bulb per glow entered, hung 6 px apart: their strings join into one line. Anchor = the string at the bulb's top.")
	_sheet("lf_constellation_pip", Vector2i(9, 9), 2, 3.0, Vector2i(4, 4), true, _star_pip,
		"Constellation: one small warm star per different Warden counted (and the star's charges). Draw faint dotted Gold lines (alpha 0.4) from each pip to the star so it reads as a star chart. Anchor = centre.")
	_sheet("lf_constellation_star", Vector2i(21, 21), 4, 6.0, Vector2i(10, 10), true, _star,
		"Constellation: the star lit over a nightmare, warm (Heartlight core, Glow and Gold rays, a banded halo). Anchor = centre.")
	_sheet("lf_full_glow_ring", Vector2i(36, 16), 4, 6.0, Vector2i(18, 8), true, _full_glow,
		"Full Glow: eight firefly motes circling a lit nightmare's feet in a faint pool of light (on the ground, under it). Anchor = centre.")
	_sheet("lf_pale_path_dot", Vector2i(9, 7), 4, 4.0, Vector2i(4, 3), true, _gleam,
		"Sightline: a warm eye-shaped gleam on each pale-path step that blinks slowly (on the ground). Anchor = the step's centre.")

func _flame_rows(f: int, two: bool) -> Array:
	if two:
		return [
			["...y.....", "..yG...E.", "..yGE.yE.", ".yGHE.yGE", ".yGHGyGyE", "yGHHGGGyE", "yGHHHGGyE", "yGHHGGyEE", ".yGGGyEE.", "..yyEEE.."],
			[".......E.", "...y..yE.", "..yGE.yGE", ".yGHE.GyE", ".yGHGyGyE", "yGHHGGGyE", "yGHHHGGyE", "yGHHGGyEE", ".yGGGyEE.", "..yyEEE.."],
			["..y......", "..yG..E..", ".yGHE.yE.", ".yGHEyGE.", ".yGHGyGyE", "yGHHGGGyE", "yGHHHGGyE", "yGHHGGyEE", ".yGGGyEE.", "..yyEEE.."],
			["......yE.", "...y..GE.", "..yGE.yGE", ".yGHEyGyE", ".yGHGyGyE", "yGHHGGGyE", "yGHHHGGyE", "yGHHGGyEE", ".yGGGyEE.", "..yyEEE.."],
		][f]
	return [
		["....y......", "....yG.....", "...yGG.....", "...yGHE....", "..yGHGE....", "..yGHHGE...", ".yGHHHGyE..", ".yGHHHGGyE.", "yGHHHHGGyE.", "yGHHHHGGyEE", "yGHHHGGyyEE", ".yGGGGyyEE.", "..yyyEEEE.."],
		[".....y.....", ".....yG....", "....yGGE...", "...yGHGE...", "...yGHGE...", "..yGHHGE...", ".yGHHHGyE..", ".yGHHHGGyE.", "yGHHHHGGyE.", "yGHHHHGGyEE", "yGHHHGGyyEE", ".yGGGGyyEE.", "..yyyEEEE.."],
		["...y.......", "...yG......", "...yGG.....", "..yGHGE....", "..yGHGE....", "..yGHHGE...", ".yGHHHGyE..", ".yGHHHGGyE.", "yGHHHHGGyE.", "yGHHHHGGyEE", "yGHHHGGyyEE", ".yGGGGyyEE.", "..yyyEEEE.."],
		["...........", "....yG.....", "...yGGE....", "...yGHE....", "..yGHGE....", "..yGHHGE...", ".yGHHHGyE..", ".yGHHHGGyE.", "yGHHHHGGyE.", "yGHHHHGGyEE", "yGHHHGGyyEE", ".yGGGGyyEE.", "..yyyEEEE.."],
	][f]

func _bonfire(img: Image, f: int) -> void:
	var sticks := _blank(img)  # Two crossed sticks, outlined: a little bonfire
	_line(sticks, Vector2i(2, 13), Vector2i(9, 10), OAK)
	_line(sticks, Vector2i(10, 13), Vector2i(3, 10), BARK)
	_px(sticks, 3, 12, DEADWOOD)  # The lit upper edge of the front stick
	_px(sticks, 5, 11, DEADWOOD)
	_outline(sticks)
	_over(img, sticks)
	_grid(img, _flame_rows(f, true), FLAME, Vector2i(2, 1))
	_halo(img, Vector2(6.5, 6.0), 7.0, GOLD, f, 0.4, true)
	for e: Vector2i in [[Vector2i(4, 0)], [Vector2i(9, 1)], [Vector2i(3, 1), Vector2i(8, 0)], [Vector2i(10, 2)]][f]:
		_px(img, e.x, e.y, Color(GLOW, 0.75))  # An ember rising

func _moth_flame(img: Image, f: int, ready: bool) -> void:
	_grid(img, _flame_rows(f, false), FLAME_READY if ready else FLAME, Vector2i(4, 5))
	_halo(img, Vector2(9.5, 11.0), 8.5 if ready else 7.0, GOLD, f, 0.75 if ready else 0.4, not ready)
	# The moth (council pass 2): 7 px across, warm bone wings (Moonpath, Deadwood; never cold silver on a Warden effect),
	# a gold edge on the wing facing the flame, a dark body, an Ink outline; always beside the flame, never on its tip.
	var up := ["W.....W", "Ww.b.wW", ".wwbww.", "...b..."]
	var down := ["...b...", ".wwbww.", "Ww.b.wW", "W.....W"]
	# Ready (council pass 3: "the wings never catch fire"): the outer wing burns Gold with Heartlight tips, an Ember spark
	# trailing behind it; only the inner wing stays bone.
	var keys := {"W": HEART, "w": GOLD, "b": BARK} if ready else {"W": MOONPATH, "w": DEADWOOD, "b": BARK}
	var moth := _blank(img)
	var at: Vector2i = [Vector2i(0, 6), Vector2i(0, 0), Vector2i(12, 5), Vector2i(12, 0)][f]
	var wings: Array = up if f % 2 == 0 else down
	_grid(moth, wings, keys, at)
	var inner := 6 if at.x < 6 else 0  # The wing tip nearest the flame catches its light
	var tip_y := 0 if f % 2 == 0 else 3
	if ready:
		for p: Vector2i in [Vector2i(2, 2), Vector2i(4, 2), Vector2i(2, 1), Vector2i(4, 1)]:  # The inner wing, still bone
			if moth.get_pixel(at.x + p.x, at.y + p.y).a > 0.0:
				moth.set_pixel(at.x + p.x, at.y + p.y, DEADWOOD)
	else:
		_px(moth, at.x + inner, at.y + tip_y, GOLD)
	_outline(moth)
	_over(img, moth)
	if ready:  # An Ember spark trailing behind it, a Glow flicker over its wings
		var behind: Vector2i = [Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(7, 0), Vector2i(7, -1)][f]
		_px(img, at.x + behind.x, at.y + 2 + behind.y, EMBER)
		_px(img, at.x + 3, at.y + tip_y - 1 if tip_y > 0 else at.y - 1, Color(GLOW, 0.75))

func _bulb(img: Image, f: int) -> void:
	for x in img.get_width():  # The string: it runs through, so bulbs 6 px apart join
		_px(img, x, 1, Color(OAK, 0.75))
	var bulb := _blank(img)
	_grid(bulb, ["..c..", ".HGy.", "HGGyE", "GGyyE", ".yyE.", "..E.."], {"c": BARK, "H": HEART, "G": GLOW, "y": GOLD, "E": EMBER}, Vector2i(1, 1))
	# An Ember edge on its lower right (a Night one showed as a dark V on the path; it's a light, not an object)
	for p: Vector2i in [Vector2i(6, 3), Vector2i(6, 4), Vector2i(5, 5), Vector2i(4, 6), Vector2i(3, 7), Vector2i(2, 6)]:
		_px(bulb, p.x, p.y, EMBER)
	_over(img, bulb)
	_px(img, 0, 4, Color(GOLD, 0.4))  # Its glow either side
	_px(img, 6, 5, Color(GOLD, 0.4))
	if f == 1 or f == 2:  # It brightens and its halo shows, then dims
		_px(img, 2, 3, HEART)
		_halo(img, Vector2(3.5, 4.5), 3.6, GOLD, f, 0.4)
	if f == 2:
		_px(img, 3, 3, HEART)

func _star_pip(img: Image, f: int) -> void:
	_grid(img, ["....y....", "....G....", "....H....", "..yGHGy..", "....H....", "....G....", "....y...."], {"y": Color(GOLD, 0.75), "G": GLOW, "H": HEART}, Vector2i(0, 1))
	_px(img, 4, 4, HEART)
	_px(img, 5, 5, Color(EMBER, 0.75))  # The shaded lower-right of its core
	if f == 1:
		for d: Vector2i in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
			_px(img, 4 + d.x * 2, 4 + d.y * 2, Color(GOLD, 0.4))

func _star(img: Image, f: int) -> void:
	var c := Vector2i(10, 10)
	var v: int = [6, 8, 7, 5][f]  # The vertical rays are longer: a star, never a crosshair
	var h: int = [4, 5, 4, 4][f]
	for i in range(1, v + 1):
		var col: Color = HEART if i <= 1 else (GLOW if i <= v - 3 else (Color(GOLD, 0.75) if i <= v - 1 else Color(GOLD, 0.4)))
		_px(img, c.x, c.y - i, col)
		_px(img, c.x, c.y + i, col)
	for i in range(1, h + 1):
		var col: Color = HEART if i <= 1 else (GLOW if i <= h - 2 else (Color(GOLD, 0.75) if i <= h - 1 else Color(GOLD, 0.4)))
		_px(img, c.x - i, c.y, col)
		_px(img, c.x + i, c.y, col)
	var diag: int = [1, 2, 2, 1][f]
	for d: Vector2i in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		for i in range(1, diag + 1):
			_px(img, c.x + d.x * i, c.y + d.y * i, GLOW if i == 1 else Color(GOLD, 0.75))
	_px(img, c.x, c.y, HEART)
	_px(img, c.x + 1, c.y + 1, GOLD)  # Its core shades to the lower right
	_halo(img, Vector2(c) + Vector2(0.5, 0.5), 5.5, GOLD, f, 0.4)

# Council pass 2: rounded ends (pointed ones read as an eye), a faint pool of light inside, motes 2 px with a Heartlight
# core and a dark under-pixel so they hold on the beige path.
func _glow_rim(a: float, c: Vector2, r: Vector2) -> Vector2:
	var cx := cos(a)
	return c + Vector2(signf(cx) * pow(absf(cx), 0.6) * r.x, sin(a) * r.y)

func _full_glow(img: Image, f: int) -> void:
	var c := Vector2(18.0, 8.0)
	var r := Vector2(16.0, 6.5)
	for y in img.get_height():  # The pool of light (council pass 3): two bands of Glow dither, lightest in the middle
		for x in img.get_width():
			var e := Vector2((x + 0.5 - c.x) / (r.x - 1.0), (y + 0.5 - c.y) / (r.y - 1.0))
			var d := pow(absf(e.x), 3.3) + e.y * e.y
			if d < 0.4 and (x + y + f) % 2 == 0:
				_px(img, x, y, Color(GLOW, 0.4))
			elif d < 1.0 and (x + 2 * y + f) % 4 == 0:
				_px(img, x, y, Color(GLOW, 0.4))
	for i in 72:  # The rim, dotted
		var p := _glow_rim(TAU * i / 72.0, c, r)
		if i % 2 == 0:
			_px(img, int(p.x), int(p.y), Color(GOLD, 0.4))
	for m in 8:  # Eight motes circling; those behind (top) dimmer
		var a := TAU * m / 8.0 + TAU * f / 32.0
		var p := _glow_rim(a, c, r)
		var x := int(p.x)
		var y := int(p.y)
		var front := sin(a) > 0.0
		_px(img, x, y + 1, GOLD)  # A Gold pixel under each, then a dark one, so they hold on the beige path
		_px(img, x + 1, y + 1, Color(GOLD, 0.75))
		_px(img, x, y + 2, Color(BARK, 0.75))
		_px(img, x, y, HEART)  # Every lead mote a Heartlight core (council pass 3)
		_px(img, x + 1, y, GLOW if front else Color(GLOW, 0.75))
		_px(img, x, y - 1, Color(GOLD, 0.4))

# Council pass 2: a watching eye, an almond with a dark lid line, a Gold iris and one Heartlight pupil, that blinks.
func _gleam(img: Image, f: int) -> void:
	var keys := {"b": Color(BARK, 0.75), "g": Color(GLOW, 0.4), "y": GOLD, "G": GLOW, "H": HEART}
	if f == 3:  # Blinking: the lids close to a line
		_grid(img, ["", "", "...bbb...", ".bbyHybb.", "...bbb..."], keys)
	else:
		_grid(img, ["", "...bbb...", ".bgyyygb.", "bgyGHGygb", ".bgyyygb.", "...bbb..."], keys)
		if f == 1:  # The pupil catches the light
			_px(img, 3, 3, Color(HEART, 0.75))

# --- Spore Print (Sporeling) --------------------------------------------------------------------------------------

const CAP := {"m": BLOSSOM, "s": ORCHID, "h": HEART, "u": ORCHID, "t": MOONPATH, "d": DEADWOOD}
const CAP_PASSED := {"m": MOONPATH, "s": DEADWOOD, "h": HEART, "u": OAK, "t": MOONPATH, "d": DEADWOOD}  # Warm bone, never cold silver

func _sporeling() -> void:
	_sheet("sp_throne_rim", Vector2i(32, 37), 4, 3.0, Vector2i(16, 33), true, _throne,
		"Toadstool Throne: a mushroom throne, a broad cap seat with a tall cap backrest and gold trim and crown studs, drawn under the clump (before the mushroom sheet; the clump stands in front of the backrest). Anchor = the clump's foot.")
	_sheet("sp_rot_ring", Vector2i(30, 16), 4, 3.0, Vector2i(15, 8), true, _rot_ring,
		"Rot Ground: a rotten ring on a Sprout bed's step, fallen grey cap stubs on it and a pink spore wisp rising (on the ground). Anchor = the step's route point.")
	_sheet("sp_fed_ground", Vector2i(20, 12), 4, 3.0, Vector2i(10, 7), true, _fed_ground,
		"Feeding Ground: a fed patch on each route point, pink spore dust settling and two curled shoots swaying; fade it with alpha as its 8 s run out. Anchor = the route point.")
	_sheet("sp_cap_badge", Vector2i(17, 12), 2, 0.0, Vector2i(8, 11), false, _cap_badge,
		"Host Trees: the cap a Warden of another family wears. Frame 0 its own cap (Blossom), frame 1 a passed-on cap (Spreading Caps: pale). Anchor = the stem's foot, on the Warden's head.")

func _throne(img: Image, f: int) -> void:
	# Council pass 2: a throne that sits under the clump without swamping it. The mushroom's own darker tones (Orchid lit,
	# Bruise in shade, a Shade outline: below the clump's brightest pink, so the clump stays the bright thing), a short
	# backrest with three lobes and gold crown studs, two arm knobs, a flat seat lit on top with a gill line under it and
	# gold trim on its front edge. A glint steps across the studs, one a frame.
	# Drawn as a chair (a wide oval seat read as a hat's brim): a straight-sided back with three lobes on top, two arm
	# posts with cap knobs, a thin seat slab. The back rises above the clump's caps (32 px; a 14 px one hid entirely
	# behind them and left a dark box): its lobes and crown show over the clump, the arms beside its stems.
	# Council pass 3: the back is a tall cap, a dome on top with a gill line under it, shaded in three tones a step
	# darker than the clump (Orchid only on the lit upper left, Bruise, Shade in the lower right), so the caps in
	# front stay the brightest pink.
	var body := _blank(img)
	var dome_c := Vector2(16.5, 10.0)
	for y in range(3, 12):  # The dome: a cap, wider than the back
		for x in range(7, 27):
			var e := Vector2((x + 0.5 - dome_c.x) / 9.5, (y + 0.5 - dome_c.y) / 6.5)
			if y <= dome_c.y and e.length() <= 1.0:
				var lit := e.x * 0.6 + e.y * 0.8
				_px(body, x, y, ORCHID if lit < -0.45 else (BRUISE if lit < 0.2 else SHADE))
	for x in range(8, 26):  # The gill line under the dome
		_px(body, x, 11, SHADE if x % 2 == 0 else BRUISE)
	for y in range(12, 32):  # The back below it: straight sides, x 10..22
		for x in range(10, 23):
			_px(body, x, y, BRUISE if x < 19 else SHADE)
	for y in range(12, 31):  # Its lit left edge
		_px(body, 10, y, ORCHID)
	for post: int in [6, 25]:  # The arm posts, a cap knob on each
		for y in range(25, 33):
			_px(body, post, y, ORCHID if post == 6 else BRUISE)
			_px(body, post + 1, y, BRUISE)
		_grid(body, [".k.", "kkk"], {"k": ORCHID}, Vector2i(post - 1, 23))
		_px(body, post + 1, 24, BRUISE)
	for x in range(6, 27):  # The seat: a thin slab, lit on top, its front edge gold
		_px(body, x, 31, ORCHID)
		_px(body, x, 32, BRUISE)
		_px(body, x, 33, GOLD if x > 7 and x < 25 else BRUISE)
	for x in range(7, 26):  # The gill line under the seat
		_px(body, x, 34, SHADE if x % 2 == 0 else BRUISE)
	for p: Vector2i in [Vector2i(11, 6), Vector2i(14, 5), Vector2i(10, 8), Vector2i(6, 23)]:  # Cap speckles, lit side
		_px(body, p.x, p.y, BLOSSOM)
	_outline(body, SHADE)
	_rim(body, [ORCHID, BRUISE], GOLD, Vector2(16.0, 9.0))  # Gold trim round the dome's upper-left edge
	_over(img, body)
	var studs := _blank(img)  # Three crown studs on its lobes, 3 px wide at the base, Glow tips
	var stud_at := [Vector2i(12, 4), Vector2i(16, 3), Vector2i(21, 4)]
	for s: Vector2i in stud_at:
		_grid(studs, [".h.", "ggg"], {"h": GLOW, "g": GOLD}, Vector2i(s.x - 1, s.y - 2))
	_outline(studs, SHADE)
	_over(img, studs)
	if f < 3:  # The glint steps across the studs, then rests a frame
		var s: Vector2i = stud_at[f]
		_px(img, s.x, s.y - 2, HEART)

func _rot_ring(img: Image, f: int) -> void:
	# Council pass 2: a broken oval of rot (it read as a pentagon wreath), brown and dark purple-brown, not leafy, with
	# gaps where it has eaten through, and four fallen cap stubs 3 px wide.
	var c := Vector2(15.0, 8.0)
	for y in img.get_height():
		for x in img.get_width():
			var e := Vector2((x + 0.5 - c.x) / 13.0, (y + 0.5 - c.y) / 6.0)
			var a := fposmod(atan2(e.y, e.x), TAU)
			if (a > 0.35 and a < 0.75) or (a > 2.55 and a < 2.85) or (a > 4.45 and a < 4.75):
				continue  # The gaps
			var r := e.length() + 0.04 * sin(a * 3.0 + 1.0)
			if r > 0.78 and r <= 1.0:
				var col: Color = Color(BARK, 0.75)
				if e.x + e.y > 0.8:
					col = Color(ROOT, 0.75)  # Darkest on the lower right
				elif (x * 3 + y) % 7 == 0:
					col = Color(SHADE, 0.75)  # Purple-brown rot in it
				_px(img, x, y, col)
			elif r > 0.68 and r <= 0.78 and e.x + e.y < 0.0:
				_px(img, x, y, Color(MOSS, 0.75))  # Its inner lip catches the light
	var stub := _blank(img)  # Fallen grey cap stubs on the ring, cap-shaped
	for at: Vector2i in [Vector2i(3, 3), Vector2i(18, 11), Vector2i(24, 3), Vector2i(7, 11)]:
		_grid(stub, [".D.", "DDs", ".r."], {"D": DEADWOOD, "s": STONE, "r": BARK}, at)
	_outline(stub, ROOT)
	_over(img, stub)
	for p: Vector2i in [Vector2i(9, 13), Vector2i(26, 9)]:  # Sickly green flecks: the light accent on dark ground
		_px(img, p.x, p.y, SPRIG)
	var rise: int = f * 2  # A pink spore wisp rising out of the rot and thinning
	var wisp := Color(BLOSSOM, 0.75 if f < 2 else 0.4)
	_px(img, 15, 7 - rise, wisp)
	_px(img, 16, 6 - rise, wisp)
	if f < 3:
		_px(img, 14, 5 - rise, Color(BLOSSOM, 0.4))

func _fed_ground(img: Image, f: int) -> void:
	# Council pass 2: a step darker than the path (Moss / Deepmoss), its upper-left edge tinged with spore pink, two shoots
	# drawn as 1 px stems with a 2 px hook and a pink tip, and the dust settled in three clumps.
	var c := Vector2(10.0, 7.0)
	for y in img.get_height():
		for x in img.get_width():
			var e := Vector2((x + 0.5 - c.x) / 9.0, (y + 0.5 - c.y) / 4.5)
			var a := atan2(e.y, e.x)
			var r := e.length() + 0.07 * sin(a * 4.0)
			if r <= 1.0:  # Dark fed soil (council pass 3: not moss), under the path's value, with a stepped, wobbly edge
				var col: Color = Color(BARK, 0.75) if e.x + e.y < 0.0 else Color(ROOT, 0.75)
				if r > 0.82 and e.x + e.y < -0.3:
					col = Color(BLOSSOM, 0.4)
				_px(img, x, y, col)
	var sway: int = [0, 1, 1, 0][f]
	for s: Vector2i in [Vector2i(7, 8), Vector2i(13, 7)]:  # A 1 px stem that curls once at the top, a pink tip
		_px(img, s.x, s.y, LEAF)
		_px(img, s.x, s.y - 1, LEAF)
		_px(img, s.x, s.y - 2, SPRIG)
		_px(img, s.x + sway, s.y - 3, SPRIG)
		_px(img, s.x + 1 + sway, s.y - 4, BLOSSOM)
	var drift: int = [0, 0, 1, 1][f]
	for clump: Vector2i in [Vector2i(3, 5), Vector2i(10, 9), Vector2i(16, 5)]:  # Pink spore dust, settled in clumps
		_px(img, clump.x, clump.y + drift, Color(BLOSSOM, 0.75))
		_px(img, clump.x + 1, clump.y + drift, Color(BLOSSOM, 0.75))
		_px(img, clump.x, clump.y + 1 + drift, Color(BLOSSOM, 0.4))

func _cap_badge(img: Image, f: int) -> void:
	var cap := _blank(img)
	_grid(cap, [
		"......mmm......",
		"....mhmmmms....",
		"...mhhmmmmss...",
		"..mmmmmmmmsss..",
		".mmmmmmmmmssss.",
		".uuuuuuuuuuuuu.",
		"u.....ttd.....u",
		"......ttd......",
		"......ttd......"], CAP if f == 0 else CAP_PASSED, Vector2i(1, 1))
	_outline(cap)
	_over(img, cap)

# --- Puddles (Dewdrop) --------------------------------------------------------------------------------------------

func _dewdrop() -> void:
	_sheet("dw_reeds", Vector2i(13, 18), 4, 3.0, Vector2i(6, 16), true, _reeds,
		"Reed Bed: a reed clump standing in the carried water, a cattail on the tallest, swaying (stands on the bank: y-sort it, or draw it over the water). Anchor = its foot at the water line.")
	_sheet("dw_mud", Vector2i(34, 20), 2, 0.0, Vector2i(17, 10), false, _mud,
		"Mudflats: a wet mud patch on each mud step, a small puddle eye in it (frame 1 a bubble instead); pick by route index; on the ground under the water's damp band. Anchor = the route point.")
	_sheet("dw_still_sheen", Vector2i(18, 9), 4, 2.0, Vector2i(9, 4), true, _moon_reflection,
		"Still Water: the water goes mirror-still and a pale crescent moon shows in it, wavering a little (on the water surface, one every few steps). Anchor = the route point.")
	_sheet("dw_footprints", Vector2i(16, 11), 2, 0.0, Vector2i(8, 5), false, _drips,
		"Wet Footprints: the nightmare's wet dragging trail, two ragged smears with a cold wet shine (frames alternate down the path); fade them with alpha over PRINT_SECONDS. Anchor = the route point.")
	_sheet("dw_wave_flash", Vector2i(26, 14), 6, 14.0, Vector2i(13, 11), false, _wave,
		"Breaking Wave / Flash Flood: a wave that rises, curls a white lip and breaks into foam and spray, then fades (one shot, ~0.43 s). Flip it when the wave runs right to left. Anchor = the water's middle.")

func _reeds(img: Image, f: int) -> void:
	var top_shift: Array = [[0, 0], [1, 0], [1, 1], [1, 0]][f]  # [the top px moves, the next 2 move]
	# Thin stalks, each 1 px with a lit top; the tallest 2 px (Sprig lit side, Moss shade)
	for stalk: Array in [[3, 10], [9, 11], [11, 8]]:
		var x0: int = stalk[0]
		var h: int = stalk[1]
		for i in h:
			var x := x0 + (int(top_shift[0]) if i == h - 1 else (int(top_shift[1]) if i >= h - 3 else 0))
			_px(img, x, 15 - i, SPRIG if i >= h - 3 else (LEAF if i >= h / 2 else MOSS))
	var tall := 14
	for i in tall:
		var s := int(top_shift[0]) if i >= tall - 1 else (int(top_shift[1]) if i >= tall - 3 else 0)
		_px(img, 6 + s, 15 - i, SPRIG if i >= 4 else LEAF)
		_px(img, 7 + s, 15 - i, MOSS)
	var head := Vector2i(6 + int(top_shift[1]), 15 - tall - 2)  # The cattail: brown, lit on its left, a cream glint
	for i in 4:
		_px(img, head.x, head.y + i, OAK)
		_px(img, head.x + 1, head.y + i, BARK)
	_px(img, head.x, head.y, MOONPATH)
	_px(img, head.x + int(top_shift[0]), head.y - 1, SPRIG)
	for x in range(5, 9):  # A clump at the foot, in the water
		_px(img, x, 15, DEEPMOSS)
	for x in range(1, 12):  # The water line
		_px(img, x, 16, Color(DEW, 0.75))
		_px(img, x, 17, Color(POOL, 0.4))
	_px(img, 2, 16, DEWLIGHT)
	_px(img, 10, 16, DEWLIGHT)

func _mud(img: Image, f: int) -> void:
	var c := Vector2(17.0, 9.5)
	var body := _blank(img)
	for y in img.get_height():
		for x in img.get_width():
			var e := Vector2((x + 0.5 - c.x) / 15.0, (y + 0.5 - c.y) / 8.0)
			var a := atan2(e.y, e.x)
			if e.length() + 0.08 * sin(a * 4.0 + f * 2.0) + 0.05 * sin(a * 7.0 + 2.0) <= 1.0:  # A crisp, wobbly edge
				_px(body, x, y, LOAM)
	# Council pass 3: an even 1 px dark wet edge all round (a darker bottom lip read as a slab's side) and a lighter
	# wet sheen on its upper left, so it lies flat.
	var edge: Array = []
	for y in img.get_height():
		for x in img.get_width():
			if not _empty(body, x, y) and (_empty(body, x - 1, y) or _empty(body, x + 1, y) or _empty(body, x, y - 1) or _empty(body, x, y + 1)):
				edge.append(Vector2i(x, y))
	for p: Vector2i in edge:
		body.set_pixelv(p, BARK)
	for p: Vector2i in [Vector2i(8, 5), Vector2i(9, 5), Vector2i(10, 4), Vector2i(11, 4), Vector2i(7, 6)]:
		if not _empty(body, p.x, p.y):
			body.set_pixelv(p, Color(DEADWOOD, 1.0))
	_over(img, body)
	if f == 0:  # A small puddle eye, two wet glints at its upper left
		_grid(img, [".PPP.", "PdPPP", ".PPP."], {"P": POOL, "d": DEW}, Vector2i(18, 8))
		_px(img, 19, 8, DEWLIGHT)
		_px(img, 17, 7, MOONPATH)
		_px(img, 16, 8, Color(MOONPATH, 0.75))
	else:  # A mud bubble, its glints the same way
		_grid(img, [".oo.", "oLLo", ".oo."], {"o": DEADWOOD, "L": LOAM}, Vector2i(19, 9))
		_px(img, 18, 8, MOONPATH)
		_px(img, 17, 9, Color(MOONPATH, 0.75))

func _moon_reflection(img: Image, f: int) -> void:
	# Council pass 2: a clear crescent "C" (the computed one came out as a stair-step L), its rows wavering a pixel, and
	# a reflection streak of dashes under it that shift a pixel each frame.
	var moon := [".MMm.", "MMm..", "MM...", "MMm..", ".MMm."]
	var waver: Array = [[0, 0, 0, 0, 0], [0, 1, 0, 0, 0], [0, 0, 0, 1, 0], [0, 0, 1, 0, 0]][f]
	for y in moon.size():
		var row: String = moon[y]
		for x in row.length():
			if row[x] == "M":
				_px(img, 6 + x + int(waver[y]), y, Color(MOON, 0.75))
			elif row[x] == "m":
				_px(img, 6 + x + int(waver[y]), y, Color(MIST, 0.75))
	for x in range(2, 17):  # The streak: dashes of light down the still water
		var k := (x + f) % 5
		if k < 2:
			_px(img, x, 6, Color(MOON, 0.75 if x > 5 and x < 12 else 0.4))
		elif k == 3 and x % 2 == 0:
			_px(img, x, 7, Color(MOON, 0.4))

func _drips(img: Image, f: int) -> void:
	# Council pass 2: each print a solid wet blot with a tapered streak dragged out behind it and drips after (the speckled
	# blots read as fish or bugs). Drawn walking right; flip the sheet for the other way.
	# Council pass 3: a ragged, rounded smear (no point, no forked tail: they read as fish), parallel drag streaks
	# trailing behind it, one cold sheen pixel at its upper left.
	var print_rows := [".....pPPp", "dd..pPPPP", "...pPPPPp", "dd..pPPPP", ".....pPp."]
	var keys := {"P": Color(POOL, 0.75), "p": Color(POOL, 0.4), "d": Color(DEW, 0.4)}
	var a := Vector2i(0, 0) if f == 0 else Vector2i(7, 5)
	var b := Vector2i(7, 5) if f == 0 else Vector2i(0, 0)
	for at: Vector2i in [a, b]:
		_grid(img, print_rows, keys, at)
		_px(img, at.x + 6, at.y + 1, Color(DEWLIGHT, 0.75))

func _wave(img: Image, f: int) -> void:
	var w := img.get_width()
	var crest_h: float = [4.0, 7.0, 9.0, 7.0, 3.0, 1.0][f]
	var peak_x: float = [12.0, 14.0, 16.0, 18.0, 19.0, 20.0][f]  # The crest runs forward as it breaks
	var tops := []
	for x in w:
		var hgt := crest_h * pow(float(x) / peak_x, 1.6) if x <= peak_x else crest_h * maxf(1.0 - (float(x) - peak_x) / 3.0, 0.0)
		var top := 13 - int(round(hgt))
		tops.append(top)
		if f == 5:
			continue  # The last frame: only the fading foam
		for y in range(top, 14):
			var col: Color = Color(DEW, 0.75)
			if y >= 12:
				col = Color(POOL, 0.75)  # Its deep foot
			if y == top or (y == top + 1 and x > peak_x - 6.0):
				col = DEWLIGHT  # The lit face under the crest
			_px(img, x, y, col)
	var crest := int(peak_x)
	var lip: int = tops[mini(crest, w - 1)]
	if f >= 1 and f <= 3:  # The white lip along the crest in runs, curling over the front
		for x in range(crest - 5, crest + 1):
			_px(img, x, int(tops[x]), HEART if (x - crest + 5) % 5 < 3 else MOON)
		var curl: Array = [[], [Vector2i(1, 0), Vector2i(2, 1)], [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 1), Vector2i(3, 2)],
			[Vector2i(1, 1), Vector2i(2, 2), Vector2i(3, 4), Vector2i(2, 4), Vector2i(4, 6)]][f]
		for d: Vector2i in curl:
			_px(img, crest + d.x, lip + d.y, HEART if d.y < 3 else MOON)
		if f == 2:
			_px(img, crest - 2, lip, GLOW)  # One warm glint at the peak
	if f >= 3:  # Foam in runs along the front, then spray thrown off it
		for x in range(crest - 2, mini(crest + 7, w)):
			var alpha := 1.0 if f == 3 else (0.75 if f == 4 else 0.4)
			if f == 5 and x % 2 == 1:
				continue
			_px(img, x, 13, Color(HEART if (x % 5) < 3 else MOON, alpha))
		var rise: int = (f - 3) * 2
		for p: Vector2i in [Vector2i(2, -3), Vector2i(4, -5), Vector2i(6, -2), Vector2i(-1, -4), Vector2i(5, -7)]:
			_px(img, crest + p.x, lip + p.y - rise, Color(HEART if p.x % 2 == 0 else MOON, 0.75 if f < 5 else 0.4))

# --- Keeping Time (Bellflower) ------------------------------------------------------------------------------------

func _bellflower() -> void:
	_sheet("kt_bronze_prime", Vector2i(11, 12), 2, 3.0, Vector2i(5, 9), true, _prime,
		"Down the Line / Both Ways: a primed nightmare's mark, a small bronze bell lit from the upper left, its clapper swinging (over its pips). Its ring arcs can use the same ramp: Oak, Ember, Gold. Anchor = the bell's lip.")
	_sheet("kt_allegro_note", Vector2i(13, 12), 2, 3.0, Vector2i(6, 10), true, _note,
		"Allegro: a kept Toll, two beamed quick notes in bronze with a motion streak, circling the bell (up to 3). Anchor = between the note heads.")
	_sheet("kt_humming_pip", Vector2i(25, 9), 4, 6.0, Vector2i(12, 4), true, _hum,
		"Humming Walls: the pip a wall filled, a thorn-wrapped bead in Thornwall colours with hum arcs pulsing outward. Anchor = centre.")

func _prime(img: Image, f: int) -> void:
	var bell := _blank(img)
	var rows := [[4, 6], [3, 7], [3, 7], [3, 7], [2, 8], [2, 8], [1, 9]]  # A bell's silhouette, row by row (y 1..7)
	for i in rows.size():
		var y := i + 1
		var l: int = rows[i][0]
		var r: int = rows[i][1]
		for x in range(l, r + 1):
			var col: Color = GOLD
			if x == l:
				col = GLOW  # Its lit left edge
			elif x >= r - 1:
				col = OAK if x == r else EMBER
			if y == 7:
				col = GOLD if x < 5 else EMBER  # The lip
			_px(bell, x, y, col)
	for x in range(1, 10):
		_px(bell, x, 8, OAK)  # The lip's underside
	_px(bell, 4 if f == 0 else 6, 9, EMBER)  # The clapper, swinging
	_px(bell, 4, 2 if f == 0 else 4, HEART)  # A glint on the lit side
	_outline(bell)
	_over(img, bell)

func _note(img: Image, f: int) -> void:
	var note := _blank(img)
	_grid(note, [
		".....gggggg",
		".....g....g",
		".....gggggg",
		".....g....g",
		".....g....g",
		"...hgg..hgg",
		"..hgge.hgge",
		"...eo...eo."], {"g": GOLD, "h": GLOW, "e": EMBER, "o": OAK}, Vector2i(1, 2))
	_px(note, 4 if f == 0 else 9, 7, HEART)  # A glint moving from head to head
	_outline(note, OAK)  # A bronze outline, not Night (it sits with chorus_note's light notes)
	_over(img, note)
	var s: int = f  # A motion streak behind them: it is quick
	_px(img, 0, 8 - s, Color(GOLD, 0.4))
	_px(img, 1, 8 - s, Color(GOLD, 0.75))
	_px(img, 0, 10 - s, Color(GOLD, 0.4))

func _hum(img: Image, f: int) -> void:
	# Council pass 2: a 5x5 bramble bead (Oak lit upper left, Bark in shade, a Sprig vine round it), four thorn points
	# poking out past its outline, and curved hum arcs, 2 px thick in the middle, darker green, fading as they travel.
	var bead := _blank(img)
	_grid(bead, [".OOO.", "OOvOB", "OvvvB", "BvBBB", ".BBB."], {"O": OAK, "B": BARK, "v": SPRIG}, Vector2i(10, 2))
	_px(bead, 11, 2, DEADWOOD)  # The rim of light, upper left
	_px(bead, 10, 3, DEADWOOD)
	_outline(bead)
	_over(img, bead)
	for t: Vector2i in [Vector2i(12, 0), Vector2i(16, 3), Vector2i(12, 8), Vector2i(8, 5)]:  # Thorns past the outline
		_px(img, t.x, t.y, DEADWOOD)
	var cy := 4
	var rings: Array = [[[1, 0.75]], [[1, 0.75], [2, 0.4]], [[2, 0.75], [3, 0.4]], [[3, 0.4]]][f]  # Hum arcs pulsing out
	for ring: Array in rings:
		var d: int = ring[0]
		var col := Color(LEAF, float(ring[1]))
		var xr := 16 + d * 2  # Curved ")" and "(" arcs, 5 px tall
		var xl := 8 - d * 2
		for p: Vector2i in [Vector2i(0, -2), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(2, 0), Vector2i(2, -1), Vector2i(2, 1)]:
			if p.x == 2 and float(ring[1]) < 0.5:
				continue  # The faded outer arc thins to 1 px
			_px(img, xr + p.x, cy + p.y, col)
			_px(img, xl - p.x, cy + p.y, col)
