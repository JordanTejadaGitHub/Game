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
	_sporeling_s33()
	_firefly_s33()
	_dewdrop_s33()
	_bellflower_s33()
	_stand_in_rows_s33()
	_wading_marks()
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
	# Final council (readability): at 1x dark sticks vanished and it read as a moth-less Moth to Flame: the sticks lighter
	# (Oak and Ember, lit Deadwood on top) and a pixel wider than the flame each side, so its foot is a woodpile.
	var sticks := _blank(img)  # Two crossed sticks, outlined: a little bonfire
	_line(sticks, Vector2i(1, 13), Vector2i(10, 10), OAK)
	_line(sticks, Vector2i(11, 13), Vector2i(2, 10), EMBER)
	for p: Vector2i in [Vector2i(2, 12), Vector2i(4, 12), Vector2i(7, 11), Vector2i(10, 12), Vector2i(8, 12)]:
		_px(sticks, p.x, p.y, DEADWOOD)  # The lit upper edges
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
	# Final council: the checker pool read as a mesh and greyed the nightmare's feet: a sparse 1-in-4 Ember light in the
	# middle thinning to 1-in-8 out to the rim, so the motes stay the stars.
	for y in img.get_height():
		for x in img.get_width():
			var e := Vector2((x + 0.5 - c.x) / (r.x - 1.0), (y + 0.5 - c.y) / (r.y - 1.0))
			var d := pow(absf(e.x), 3.3) + e.y * e.y
			if d < 0.4 and (x + 2 * y + f) % 4 == 0:
				_px(img, x, y, Color(EMBER, 0.4))
			elif d < 1.0 and (x + 2 * y + f) % 8 == 0:
				_px(img, x, y, Color(EMBER, 0.4))
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
	_sheet("sp_throne_rim", Vector2i(40, 46), 4, 3.0, Vector2i(20, 42), true, _throne,
		"Toadstool Throne: a throne made of mushroom, drawn under the clump (before the mushroom sheet; the clump stands in front): a great toadstool cap tipped upright behind it, its brown gill underside fanning from a pale stem stub, a gold and Ember rim, a three-point crown on top (a glint sweeps its points), two little toadstool armrests and a squat plinth. Anchor = the clump's feet.")
	_sheet("sp_rot_ring", Vector2i(30, 16), 4, 3.0, Vector2i(15, 8), true, _rot_ring,
		"Rot Ground: a rotten ring on a Sprout bed's step, fallen grey cap stubs on it and a pink spore wisp rising (on the ground). Anchor = the step's route point.")
	_sheet("sp_fed_ground", Vector2i(20, 12), 4, 3.0, Vector2i(10, 7), true, _fed_ground,
		"Feeding Ground: a fed patch on each route point, pink spore dust settling and two curled shoots swaying; fade it with alpha as its 8 s run out. Anchor = the route point.")
	_sheet("sp_cap_badge", Vector2i(17, 12), 2, 0.0, Vector2i(8, 11), false, _cap_badge,
		"Host Trees: the cap a Warden of another family wears. Frame 0 its own cap (Blossom), frame 1 a passed-on cap (Spreading Caps: pale). Anchor = the stem's foot, on the Warden's head.")

# A throne made of mushroom: its back is a great toadstool cap tipped upright behind the clump, seen from below: a
# smooth round cap edge, wider than it is tall (an arch, a faceted frame or bars read as a window, a mirror or a cage,
# council rounds 2-3), its underside a warm grey-brown with thin dark gills fanning from a pale stem stub (violet stripes
# hid violet nightmares and read as a shell; this toadstool's underside is brown like a real one's, so a nightmare
# behind it still shows); a flesh band of Bruise just inside the rim, Orchid only at its lit corner; the rim gold where
# lit and Ember in shadow, a Night outline; a chunky three-point crown on top; two little toadstool armrests against the
# cap; a squat plinth with an Ember lip. The clump in front stays the brightest pink. A glint walks the crown.
const THRONE_C := Vector2(20.0, 27.0)  # The cap's centre (its stem stub; the clump's feet are at (20, 42))
const THRONE_R := Vector2(15.5, 16.5)  # Its half width and height above the centre

func _in_cap(p: Vector2) -> bool:
	var d := p - THRONE_C
	return d.y <= 0.5 and Vector2(d.x / THRONE_R.x, d.y / THRONE_R.y).length() <= 1.0

func _throne(img: Image, f: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var inside := {}
	for y in h:
		for x in w:
			if _in_cap(Vector2(x + 0.5, y + 0.5)):
				inside[Vector2i(x, y)] = true
	var rim := {}
	for p: Vector2i in inside:
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
			if not inside.has(p + d):
				rim[p] = true
	var cap := _blank(img)
	for p: Vector2i in inside:  # The underside: warm grey-brown, a step darker toward the shadow side
		_px(cap, p.x, p.y, LOAM if p.x < 24 else BARK)
	for p: Vector2i in inside:  # The flesh band just inside the rim: Bruise, Orchid only at the lit upper-left corner
		if rim.has(p):
			continue
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]:
			if rim.has(p + d):
				var corner := p.x < THRONE_C.x - 6 and p.y < THRONE_C.y - 8 and p.x > THRONE_C.x - 13
				_px(cap, p.x, p.y, ORCHID if corner else BRUISE)
				break
	for p: Vector2i in rim:  # The rim: gold where lit, Ember in shadow
		var lit := (p.x - THRONE_C.x) * 0.8 + (p.y - THRONE_C.y) * 0.6 < 0.0
		_px(cap, p.x, p.y, GOLD if lit else EMBER)
	_outline(cap, NIGHT)
	_over(img, cap)
	var gills := _blank(img)  # Thin dark gills fanning from the stub, gaps 3x wider, stopping short of the flesh band
	var hub := Vector2i(int(THRONE_C.x), int(THRONE_C.y))
	for i in 11:
		if i == 8:
			continue  # One fewer on the shadow side, where they stair-stepped heavier (council round 4)
		var a := lerpf(-PI * 0.9, -PI * 0.1, i / 10.0)
		var tip := Vector2i((Vector2(hub) + Vector2(cos(a) * THRONE_R.x, sin(a) * THRONE_R.y) * 1.2).round())
		for q: Vector2i in _bresenham(hub, tip):
			if not inside.has(q) or rim.has(q):
				break
			var c := cap.get_pixel(q.x, q.y)
			if Color(c.r, c.g, c.b) == BRUISE or Color(c.r, c.g, c.b) == ORCHID:
				break
			if Vector2(q - hub).length() < 3.0:
				continue
			_px(gills, q.x, q.y, ROOT if q.x >= 24 else BARK)
	_grid(gills, [".d.", "ddd", "ddd"], {"d": DEADWOOD}, hub + Vector2i(-1, -2))  # The stem stub the gills fan from
	_over(img, gills)
	for side: int in [-1, 1]:  # The armrests: little toadstools against the cap, a domed cap with a gold rim, pale stem
		var ax := 20 + side * 13
		var arm := _blank(img)
		_grid(arm, ["..bbb..", ".bobbb.", "bbbbbss", "ggggggg", "...d...", "...d...", "..ddd.."],
			{"b": BRUISE, "o": ORCHID, "s": SHADE, "g": GOLD if side < 0 else EMBER, "d": DEADWOOD}, Vector2i(ax - 3, 31))
		_outline(arm, NIGHT)
		_over(img, arm)
	var plinth := _blank(img)  # The plinth: squat, an Ember lip (gold only on the cap and armrests)
	for y in range(39, 44):
		for x in range(9, 32):
			var col: Color = BRUISE if x < 24 else SHADE
			if y == 39:
				col = EMBER
			elif y == 43:
				col = SHADE
			_px(plinth, x, y, col)
	for x in range(10, 31, 3):  # Its gills, under the lip
		_px(plinth, x, 42, SHADE)
	_outline(plinth, NIGHT)
	_over(img, plinth)
	var crown := _blank(img)  # A chunky three-point crown on the cap's top
	var top := int(THRONE_C.y - THRONE_R.y)
	_grid(crown, ["G...G...G", "gG.gGg.Gg", "ggggggggg", "eeeeeeeee"], {"G": GLOW, "g": GOLD, "e": EMBER},
		Vector2i(16, top - 3))
	_outline(crown, NIGHT)
	_over(img, crown)
	var glint: Vector2i = [Vector2i(16, top - 3), Vector2i(20, top - 3), Vector2i(24, top - 3), Vector2i(-9, -9)][f]  # A sweep across the three points, then a rest
	for d: Vector2i in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if not _empty(crown, glint.x + d.x, glint.y + d.y):  # Only on the crown itself
			_px(img, glint.x + d.x, glint.y + d.y, HEART if d == Vector2i.ZERO else GLOW)

# A line one pixel a step (Bresenham).
func _bresenham(a: Vector2i, b: Vector2i) -> Array:
	var out: Array = []
	var dx := absi(b.x - a.x)
	var dy := -absi(b.y - a.y)
	var sx := 1 if a.x < b.x else -1
	var sy := 1 if a.y < b.y else -1
	var err := dx + dy
	var p := a
	while true:
		out.append(p)
		if p == b:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			p.x += sx
		if e2 <= dx:
			err += dx
			p.y += sy
	return out

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
		var k := (x + f) % 4  # A period of 4 on a 4-frame loop (5 skipped a step at the seam, final council)
		if k < 2:
			_px(img, x, 6, Color(MOON, 0.75 if x > 5 and x < 12 else 0.4))
		elif k == 3:
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
	for x in range(7, 10):  # The beam's highlight in Bellflower pink (final council: all bronze read as a Firefly mark)
		_px(note, x, 2, BLOSSOM)
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

# --- Section 33 marks (2026-10-25): board visuals for the evolution rows and drift-45 capstones (owner: "draft the new
# ones through the art council before the owner sees them"; approved after council passes 1-5). Same rules as above.
# Council pass 1 (art direction + theme, effects peer, readability): Black Spot solid black with a pale rim; dark and
# blue-on-blue marks get their one light accent (orchid, moss, white foam); every loop's periods divide its frames (no
# seam pops); no dithered fades on the ground; the tally a dark bronze hanging plaque, not a bar; the streak flare its own
# ring-and-sparks shape in stepped tiers, never scaled. ------------------------------------------------------------------

func _sporeling_s33() -> void:
	_sheet("sp_season_haze", Vector2i(32, 14), 4, 3.0, Vector2i(16, 8), true, _season_haze,
		"Spore Season: a low green spore haze lying over each trail step while the Season is lit, pink spores rising out of it (on the ground, over the path, under the nightmares; flip every other step's tile so the trail doesn't repeat). Anchor = the route point.")
	_sheet("sp_spore_fleck", Vector2i(15, 15), 4, 12.0, Vector2i(7, 7), false, _spore_fleck,
		"Host Trees: the pink spore fleck where a capped Warden's tick or hit lands (one shot, ~0.33 s). Anchor = the hit point.")
	_sheet("sp_black_spot", Vector2i(13, 10), 4, 4.0, Vector2i(6, 9), true, _black_spot,
		"Black Spot: a solid black (Root) rot spot over the marked nightmare's head, a Night outline lit Bruise on its upper left, three orchid pustules on it pulsing together. Anchor = its foot, at the head-mark point.")
	_sheet("sp_spot_fleck", Vector2i(11, 11), 4, 12.0, Vector2i(3, 8), false, _spot_fleck,
		"Black Spot: the black rot splat that lands on each Warden as it hits the marked nightmare, drops flicked off it (drawn flicking up-right: flip it toward the Warden; one shot, ~0.33 s). Anchor = the splat on the Warden.")
	_sheet("sp_deep_rot_ring", Vector2i(44, 20), 5, 10.0, Vector2i(22, 10), false, _deep_rot_ring,
		"Deep Rot: every 10 steps a dark green rot ring swells out from under the boss, a moss light on its front, then breaks into chunks that sink (one shot, 0.5 s, on the ground). Anchor = its feet.")

func _season_haze(img: Image, f: int) -> void:
	# Low, soft wisps of spore haze 2-3 px tall, lit on top, hand-shaped (no dither), drifting along the trail and back
	# (0, 1, 2, 1: no seam), and pink spores rising a pixel a frame.
	var drift: int = [0, 1, 2, 1][f]
	# Pass 3: long low streaks, 1-2 px tall and 12 px or more, the top row leaning the way it drifts and lit only at its
	# leading end (lit tops over dark bases read as grass tufts, narrower rows under wide ones as mushrooms).
	# Wiring capture (Roguelite Code, 2026-10-25): Sprig at 0.4 vanished on the light path: Leaf at 0.75 (a step under the
	# path's value, still green on dark ground), its leading end Sprig.
	var keys := {"t": Color(SPRIG, 0.75), "b": Color(LEAF, 0.75)}
	# Recheck: long green strokes still led (path grass): the green is short stubs now and the spores lead.
	_grid(img, ["..bbt", "bbbb."], keys, Vector2i(3 + drift, 4))
	_grid(img, [".bbbt", "bbbb."], keys, Vector2i(17 + drift, 8))
	_grid(img, ["bbbt"], keys, Vector2i(8 + drift, 12))
	# Final council: twice the spores, each with a 2 px rising trail, so the pink reads first (the streaks alone looked
	# like the path's own grass strokes).
	for m: Vector2i in [Vector2i(9, 9), Vector2i(26, 6), Vector2i(4, 11), Vector2i(20, 12)]:
		var y := m.y - f
		var a := 1.0 if f < 3 else 0.75
		# A round 2x2 spore lit on its upper left, its trail dotted below with a gap (a dot over a joined trail read as a
		# tiny mushroom)
		_grid(img, ["Hb", "bb"], {"H": Color(HEART, a), "b": Color(BLOSSOM, 0.75)}, Vector2i(m.x, y))
		_px(img, m.x, y + 3, Color(ORCHID, 0.4))

func _spore_fleck(img: Image, f: int) -> void:
	# A pink spore puff that lands and scatters: a lit core, then seven 2 px bits flying out on rays, thinning.
	# Wiring capture (2026-10-25): at 9 px it read as tiny specks at 2x: now 15 px, a 5 px core, 2 px bits.
	var c := Vector2i(7, 7)
	var rays := [Vector2(1, 0), Vector2(0.7, -0.7), Vector2(0, -1), Vector2(-0.7, -0.7), Vector2(-1, 0), Vector2(-0.7, 0.7),
		Vector2(0.7, 0.7)]
	match f:
		0:
			_grid(img, ["..c..", ".cbc.", "cbHbc", ".cbc.", "..c.."], {"c": ORCHID, "b": BLOSSOM, "H": HEART}, c - Vector2i(2, 2))
		_:
			var reach: float = [0.0, 3.0, 5.0, 6.0][f]
			var col: Color = [BLOSSOM, BLOSSOM, Color(BLOSSOM, 0.75), Color(ORCHID, 0.4)][f]
			for d: Vector2 in rays:
				var p := Vector2(c) + Vector2(0.5, 0.5) + d * reach
				_px(img, floori(p.x), floori(p.y), col)
				var q := p - d * 1.0  # Its tail
				_px(img, floori(q.x), floori(q.y), Color(col, minf(col.a, 0.75)))
			if f == 1:
				_grid(img, [".b.", "bHb", ".b."], {"b": BLOSSOM, "H": HEART}, c - Vector2i(1, 1))

func _black_spot(img: Image, f: int) -> void:
	# A plant's black spot: a solid, ragged Night blot, a 1 px Bruise rim, lit pale (Mist) on its upper left so it shows
	# on a dark head, three pustules on it, one lighting Orchid / Blossom in turn (the fourth frame rests).
	# Pass 2: on dark ground the Night fill vanished and only the rim showed (a hollow oval again): a 2 px Mist rim on the
	# upper left, Bruise filling its lower third, the rim broken on the lower right, 2x2 pustules.
	# Pass 3: it read as an EYE (an almond with a pale lid and one bright dot glancing round): now a lobed, ragged blot with
	# a notch, three loose specks of rot beside it, the pale light broken into separate glints, and the pustules a dim
	# cluster off centre sharing one faint pulse.
	# Pass 4: inner bruise bits (a notch, a pustule cluster) read as grain and two side-by-side glints as eyes again: a
	# solid Night core with a Bruise edge only, its lobes in the outline, one Mist glint off centre, one small pustule.
	# Final council: a Night body is the nightmares' own darkest tone, so over a head only its orchid edge showed (a hollow
	# purple outline): the body is Root, the one black darker than any nightmare, a Night outline like the other solid
	# objects, a pale Bruise light on its upper-left edge only, and three pustules the only orchid pixels, pulsing together.
	var spot := _blank(img)
	_grid(spot, [
		"...RRR.....",
		".RRRRRR..R.",
		"RRRRRRRRR..",
		"RRRRRRRRRR.",
		".RRRRRRRRRR",
		"..RRRRRRRR.",
		"..RR...RR..",
		"R.........."], {"R": ROOT}, Vector2i(1, 1))
	_rim(spot, [ROOT], BRUISE, Vector2(8.5, 6.0))  # Recheck: the light runs further round the upper arc (centre moved right)
	_outline(spot, NIGHT)
	_over(img, spot)
	var pulse := f == 1 or f == 2
	for p: Vector2i in [Vector2i(6, 3), Vector2i(9, 5), Vector2i(4, 6)]:  # Round 2x2 pustules, a pale centre at the pulse
		_grid(img, ["co", "oo"], {"c": BLOSSOM if pulse else ORCHID, "o": ORCHID if pulse else BRUISE}, p)
	_px(img, 3, 2, MIST)  # One brighter rim pixel on its upper left, so its edge shows on night ground

func _spot_fleck(img: Image, f: int) -> void:
	# A dark splat (Night core, Orchid rim on its lit side) with drops flicked off it in an arc; the lead drops stay Orchid.
	# Pass 2: the splat 5 px, a Mist glint and Bruise edge so it shows on dark ground and on a Warden; drops 2 px.
	var c := Vector2i(3, 8)
	# Final council: the splat a pixel larger at its peak (frame 1) and one drop a frame lit pale orchid (Blossom), so it
	# reads on night ground.
	var splat: Array = [[".mb.", "mNNb", "bNNN", ".bN."], [".mbb.", "mNNNb", "bNNNN", ".bNNb", "..b.."],
		[".mb.", "mNNb", "bNNN", ".bN."], [".b..", "bNb.", ".b.."]][f]
	_grid(img, splat, {"N": NIGHT, "b": BRUISE, "m": MIST}, c - Vector2i(1, 2))
	var drops: Array = [[], [Vector2i(3, -3), Vector2i(2, -5)], [Vector2i(5, -4), Vector2i(3, -6), Vector2i(6, -2)],
		[Vector2i(7, -4), Vector2i(4, -7)]][f]
	for i in drops.size():
		var d: Vector2i = drops[i]
		var col: Color = BLOSSOM if i == 0 else BRUISE
		_px(img, c.x + d.x, c.y + d.y, col)
		_px(img, c.x + d.x, c.y + d.y + 1, Color(NIGHT, 1.0 if f < 3 else 0.75))

func _deep_rot_ring(img: Image, f: int) -> void:
	# A broken ring of dark green rot swelling out on the ground (gaps fixed: it swells, never spins), Moss on its lit
	# upper-left arc and a Sprig light on its front at the peak; then it stops, breaks into chunks and sinks (alpha in
	# steps, no dither).
	var c := Vector2(22.0, 10.0)
	var rx: float = [6.0, 11.0, 15.0, 17.0, 17.0][f]
	var ry := rx * 0.45
	var alpha: float = [0.75, 0.75, 0.75, 0.75, 0.4][f]
	var gap := 0.3 if f < 3 else 0.75  # Wider breaks: the ring falls apart into chunks
	for y in img.get_height():
		for x in img.get_width():
			var e := Vector2((x + 0.5 - c.x) / rx, (y + 0.5 - c.y) / ry)
			var r := e.length()
			var thick := 2.2 if f < 4 else 1.2
			if r > 1.0 or r <= 1.0 - thick / rx:
				continue
			var a := fposmod(atan2(e.y, e.x), TAU)
			if fposmod(a + 0.4, 1.6) < gap:
				continue
			var lit := e.x + e.y < -0.4
			var col: Color = MOSS if lit else DEEPMOSS
			if f == 2 and e.y > 0.7 and absf(e.x) < 0.35:
				col = SPRIG  # Its front catches the light at the peak
			_px(img, x, y, Color(col, alpha))
	if f < 2:
		for p: Vector2i in [Vector2i(-6, -2), Vector2i(7, -1)]:
			_px(img, int(c.x) + p.x, int(c.y) + p.y - f, Color(BLOSSOM, 0.75))

func _firefly_s33() -> void:
	# Final council: loop false (a plain loop would play blazing straight into dim): code loops 1-2 or 3-4 itself; the
	# anchor on the base's outline (y 15; at 17 it floated 2 px above its point).
	_sheet("lf_lantern", Vector2i(17, 18), 5, 6.0, Vector2i(8, 15), false, _lantern,
		"Early Lamps / Carried / Late Lanterns / Lantern Alley / Hunting Lantern: the small lantern over a nightmare. Frame 0 dim (between glows); frames 1-2 lit, 3-4 blazing: code loops the pair itself at the sheet's fps (the flame flickers, the halo shimmers); not a plain looping animation. Anchor = its base's foot.")
	_sheet("lf_streak_flare", Vector2i(27, 27), 15, 14.0, Vector2i(13, 13), false, _streak_flare,
		"Lantern Alley: the lantern's flare each time its streak grows, an ember ring bursting with sparks flying out (fire, not a bell's ring; one shot, 5 frames, ~0.36 s). Three tiers, never scaled: frames 0-4 streak 2, 5-9 streak 3-4, 10-14 streak 5+ (bigger ring, more sparks). Anchor = centre (the lantern's flame).")

func _lantern(img: Image, f: int) -> void:
	# A little oak lantern on a short hook: the flame inside dims or blazes by frame, flickering between each pair
	# (lights: no outline, a banded halo whose pattern moves).
	var body := _blank(img)
	_grid(body, [
		"....o....",
		"..OOOOO..",
		".OOOOOOO.",
		".b.....b.",
		".b.....b.",
		".b.....b.",
		".b.....b.",
		".b.....b.",
		".b.....b.",
		".OOOOOOO.",
		"..bbbbb.."], {"o": OAK, "O": OAK, "b": BARK}, Vector2i(4, 4))
	_outline(body)
	_rim(body, [OAK, BARK], DEADWOOD, Vector2(8.5, 9.0))
	_over(img, body)
	var level: int = [0, 1, 1, 2, 2][f]
	var flick: int = 0 if f % 2 == 1 else 1
	var glass_fill: Color = [Color(DUSK, 0.75), Color(GOLD, 0.4), Color(GLOW, 0.75)][level]
	for y in range(7, 13):
		for x in range(6, 11):
			_px(img, x, y, glass_fill)
	match level:
		0:
			_grid(img, ["E", "E"], {"E": EMBER}, Vector2i(8, 11))
		1:
			_grid(img, [".y." if flick == 0 else "y..", "yGy", "yGy", ".y."], {"y": GOLD, "G": GLOW}, Vector2i(7, 8))
		2:
			_grid(img, [".G." if flick == 0 else "..G", "GHG", "GHG", "GHG", ".G."], {"G": GLOW, "H": HEART}, Vector2i(7, 7))
	if level > 0:
		_halo(img, Vector2(8.5, 10.0), 5.5 if level == 1 else 7.5, GLOW, f, 0.4 if level == 1 else 0.75)

func _streak_flare(img: Image, f: int) -> void:
	# The lantern's own flare (not the crit's four-point star): a hot core that bursts into a warm ring, ember sparks
	# flying out of it, the ring breaking and fading. Tier t (0-2): the ring 1 px wider and 2 more sparks a tier.
	# Final council: a 27 px frame (tier 2's sparks fell outside 21 px as it faded); the ring sampled by its length (32
	# samples left gaps on the big rings before they should break); it burns toward Ember with sparks streaking outward,
	# so it reads as fire bursting, not a bell's dotted gold ring.
	var tier := f / 5
	var k := f % 5
	var c := Vector2(13.5, 13.5)
	if k <= 1:  # The core
		_grid(img, [".G.", "GHG", ".G."] if k == 0 else ["GGG", "GHG", "GGG"], {"G": GLOW, "H": HEART}, Vector2i(12, 12))
	var r: float = [0.0, 3.0, 5.0, 6.5, 7.5][k] + tier
	if k >= 1:
		var ring_col: Color = [GLOW, GLOW, EMBER, Color(EMBER, 0.75), Color(EMBER, 0.4)][k]
		var n := ceili(TAU * r)
		for i in n:
			var a := TAU * i / n
			if k >= 3 and i % 4 == 0:
				continue  # Breaking up
			var p := c + Vector2(cos(a), sin(a)) * r
			_px(img, floori(p.x), floori(p.y), ring_col)
	var sparks := 4 + 2 * tier
	if k >= 2:
		for i in sparks:
			var a := TAU * (i + 0.5) / sparks
			var dir := Vector2(cos(a), sin(a))
			var p := c + dir * minf(r + 1.5 + (k - 2) * 1.5, 12.0)
			var col: Color = [GLOW, GOLD, Color(GOLD, 0.75)][k - 2]
			_px(img, floori(p.x), floori(p.y), col)
			var tail := p - dir  # A streak behind it: flying out
			_px(img, floori(tail.x), floori(tail.y), Color(EMBER, 0.75))
	if k == 1:  # A halo only at the burst (on later frames it filled the ring with a mesh)
		_halo(img, c, r + 2.0, GLOW, f)

func _dewdrop_s33() -> void:
	_sheet("dw_heavy_cling", Vector2i(30, 14), 4, 6.0, Vector2i(19, 8), true, _heavy_cling,
		"Heavy Water: water heaped round one nightmare's legs, a white crest sloshing on its front, foam trailing behind it in dashes as it walks (drawn walking right: flip it walking left). Under the nightmare, over the wading ripple (code hides the ripple while it shows). Anchor = its feet.")
	_sheet("dw_floodgate_froth", Vector2i(32, 18), 4, 8.0, Vector2i(16, 9), true, _floodgate_froth,
		"Floodgate: for the surge's 3 s each water step heaves and goes pale, two ragged bands of froth rolling across it (tiles along the water every 32 px; over the water surface, under the nightmares); the nightmares' stagger is a shake in code. Anchor = the route point.")
	_sheet("dw_floodgate_froth_end", Vector2i(32, 18), 4, 8.0, Vector2i(16, 9), true, _floodgate_froth_end,
		"Floodgate: the froth tile for each END of the surged water (its last drawn point; flip it for the first), the same frames as dw_floodgate_froth with its right half rounding off like the water's rounded end, so the froth never stops in a hard edge. Anchor = the route point.")
	_sheet("dw_tidal_bore", Vector2i(30, 26), 6, 10.0, Vector2i(15, 25), true, _tidal_bore,
		"Tidal Bore: a tidal wave rolling with the tough nightmare through the mouth, heaving, its lip curling forward in foam (drawn rolling right: flip it rolling left); drawn just behind the nightmare. Anchor = the wave's foot, under the nightmare.")
	_sheet("dw_blue_splash", Vector2i(15, 15), 4, 12.0, Vector2i(7, 13), false, _blue_splash,
		"Tidal Bore / River Mouth / Delta: the big splash on a hit, a crown of water rising with white tips, breaking into drops and falling back into a pale ring (one shot, ~0.33 s). Anchor = the hit's foot.")

func _heavy_cling(img: Image, f: int) -> void:
	# A heap of water round the feet (an open ring: the body shows through): lit Dewlight on its upper-left lip, darker
	# under, a white crest on the front rim that sloshes up and down; foam dashes trailing behind, thinning.
	var c := Vector2(19.0, 8.0)
	var slosh: int = [0, 1, 0, -1][f]
	for y in img.get_height():
		for x in img.get_width():
			var e := Vector2((x + 0.5 - c.x) / 9.0, (y + 0.5 - c.y) / 3.6)
			var r := e.length()  # A steady heap (a wobbling rim squared it into a log in frame 1, council pass 2): only the crest and foam move
			if r > 1.0 or r <= 0.6:
				continue
			var col: Color = DEW
			if e.y < -0.2 and e.x < 0.4:
				col = DEWLIGHT if r > 0.84 else DEW
			elif e.y > 0.35:
				col = POOL
			_px(img, x, y, col)
	# Pass 3: one white point on its front read as a fish's snout (with the hollow as its eye): the front stays round, and
	# the foam is two short bumps along its top rim, sloshing in turn.
	for b in 2:
		var bx: int = [15, 21][b]
		var up: int = slosh if b == 0 else -slosh
		_grid(img, [".hm", "mmm"], {"h": HEART, "m": MOON}, Vector2i(bx, 4 - maxi(up, 0)))
	# The wake: foam dashes 4 px apart running back a pixel a frame (a period of 4 on the 4-frame loop: each dash ends
	# where the next began, final council), each one's look taken from how far behind it is, not from its index.
	for i in 4:
		var x := 12 - i * 4 - f
		if x < 0:
			continue
		var near := x >= 6
		var col := Color(MOON if near else DEWLIGHT, 0.75 if near else 0.4)
		var y := 8 if near else 9
		_px(img, x, y, col)
		if near:
			_px(img, x - 1, y, col)

func _floodgate_froth(img: Image, f: int) -> void:
	# The surge: a pale wash over the water with ragged edges and two froth bands heaving across it. Every period divides
	# the tile (16 px) and the loop (4 frames): no seam between steps, no pop at the loop.
	var w := img.get_width()
	var heave: int = [0, 1, 0, -1][f]
	var ph := f * PI * 0.5
	for x in w:
		var top := 3 + roundi(sin(x * TAU / 8.0 + ph) * 1.0)
		var bottom := 15 + roundi(sin(x * TAU / 16.0 - ph) * 1.0)
		for y in range(top, bottom):
			_px(img, x, y, Color(DEWLIGHT, 0.4))
	for band: int in [6, 11]:
		for x in w:
			var y := band + heave + roundi(sin(x * TAU / 16.0 + ph + band) * 1.5)
			_px(img, x, y, Color(MOON, 0.75))
			_px(img, x, y + 1, Color(DEWLIGHT, 0.75))
			if (x + f * 2 + band) % 8 == 0:
				_px(img, x, y - 1, HEART)  # Foam catching the light, carried along
	for p: Vector2i in [Vector2i(5, 9), Vector2i(19, 4), Vector2i(26, 13)]:
		_px(img, (p.x + f * 8) % w, p.y + heave, Color(MOON, 0.75))  # Bubbles carried a quarter tile a frame

# The froth at the water's end: the same tile, its right half cut to a rounded end (an ellipse from the tile's middle),
# the cut edge a step of Moonlight foam (wiring capture 2026-10-25: the last tile ended in a hard vertical edge).
func _floodgate_froth_end(img: Image, f: int) -> void:
	_floodgate_froth(img, f)
	for y in img.get_height():
		for x in range(16, img.get_width()):
			var e := Vector2((x + 0.5 - 16.0) / 14.0, (y + 0.5 - 9.0) / 6.5)
			if e.length() > 1.0:
				_px(img, x, y, Color(0, 0, 0, 0))
			elif e.length() > 0.86 and img.get_pixel(x, y).a > 0.0:
				_px(img, x, y, Color(MOON, 0.75))  # Foam along its rounded edge

func _tidal_bore(img: Image, f: int) -> void:
	# The language of dw_wave_flash (the approved breaking wave), held at its peak and rolling over 6 frames: a domed
	# swell (not a ramp) that heaves, a lit face under the crest, a white lip in runs that roll forward along the crest and
	# curl over the front, foam runs at the front's foot, spray thrown up and falling. Water: no outline. Periods of 6.
	var base := 24
	var peak := 19
	var crest_h: float = [13.0, 14.0, 14.0, 13.0, 12.0, 12.0][f]
	var tops := {}
	for x in range(3, 24):
		var hgt: float
		if x <= peak:
			var u := float(peak - x) / float(peak - 3)
			hgt = crest_h * sqrt(maxf(1.0 - u * u, 0.0))  # A rounded dome of water
		else:
			hgt = crest_h - (x - peak) * 3.0  # The steep front
		var top := base - roundi(hgt)
		if top >= base:
			continue
		tops[x] = top
		for y in range(top, base + 1):
			var col: Color = Color(DEW, 0.75)
			if y >= base - 1:
				col = Color(POOL, 0.75)  # Its deep foot
			if y == top or (y == top + 1 and x > peak - 7):
				col = DEWLIGHT  # The lit face under the crest
			elif x < peak - 2 and y == top + 3 and (x + f) % 3 == 0:
				col = Color(DEWLIGHT, 0.75)  # Light rolling over its back
			elif x > peak and y > top + 2 and (y - f) % 3 == 0:
				col = Color(DEWLIGHT, 0.75)  # Water running down the face
			_px(img, x, y, col)
	for x in range(peak - 7, peak + 1):  # The white lip in runs, rolling forward a pixel a frame
		_px(img, x, int(tops[x]), HEART if (x - f) % 6 < 3 else MOON)
	var lip: int = tops[peak]
	var curl := [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 1), Vector2i(4, 2), Vector2i(4, 3), Vector2i(3, 4)]
	for i in curl.size():
		var d: Vector2i = curl[i]
		_px(img, peak + d.x + (1 if f >= 3 and i >= 2 else 0), lip + d.y, HEART if i < 3 else MOON)
	_px(img, peak + 3, lip + 6 + f % 3, Color(MOON, 0.75))  # A drop falling off the curl
	for x in range(peak - 1, 30):  # Foam in runs along the front's foot, rolling
		if (x - f) % 6 < 4:
			_px(img, x, base, HEART if (x - f) % 6 == 0 else MOON)
	for i in 4:  # Spray thrown up off the lip and falling: each on a 6-frame cycle, staggered
		var t := (f + i * 3 / 2) % 6
		var p := Vector2i(peak + 2 + i * 2, lip - 1 - [1, 3, 4, 4, 3, 1][t])
		_px(img, p.x, p.y, Color(MOON if i % 2 == 0 else HEART, 0.75 if t < 4 else 0.4))

func _blue_splash(img: Image, f: int) -> void:
	# A crown of water: rises in leaning, staggered columns with white tips, breaks into drops, falls back into a pale
	# ring (a step lighter than the water, white flecks in it).
	var c := Vector2i(7, 13)
	match f:
		0:
			for col: Vector3i in [Vector3i(-4, 3, -1), Vector3i(-2, 5, 0), Vector3i(0, 4, 0), Vector3i(2, 6, 0), Vector3i(4, 3, 1)]:
				for k in col.y:
					var lean := col.z * (k / 2)
					_px(img, c.x + col.x + lean, c.y - k, MOON if k == col.y - 1 else (DEWLIGHT if k > 0 else DEW))
		1:
			for d: Vector2i in [Vector2i(-6, -5), Vector2i(-2, -8), Vector2i(1, -9), Vector2i(3, -7), Vector2i(6, -4)]:
				_grid(img, ["H", "D"], {"H": HEART, "D": DEWLIGHT}, c + d)
			for x in range(-3, 4):
				_px(img, c.x + x, c.y, DEWLIGHT)
		2:
			for d: Vector2i in [Vector2i(-7, -2), Vector2i(-3, -5), Vector2i(2, -6), Vector2i(5, -4), Vector2i(7, -1)]:
				_px(img, c.x + d.x, c.y + d.y, MOON)
			for x: int in [-5, -4, -3, 3, 4, 5]:
				_px(img, c.x + x, c.y, Color(DEWLIGHT, 0.75))
		3:
			for x: int in [-6, -5, -3, 3, 5, 6]:
				_px(img, c.x + x, c.y - (1 if absi(x) < 5 else 0), Color(MOON if absi(x) == 5 else DEWLIGHT, 0.4))

func _bellflower_s33() -> void:
	_sheet("kt_tally", Vector2i(19, 15), 2, 0.0, Vector2i(9, 14), false, _tally,
		"Last Bell / Curfew / Passing Bell / Last Rites: a dark bronze plaque with a shield bottom hanging by a cord from a nail over the nightmare, a rivet each side. Frame 0 the plaque, frame 1 struck (rung out). Code draws kt_tally_mark on its face (top left of the marks at (5, 7); the face runs x 5..13, y 7..11): one group of five, then a count. Anchor = its bottom middle.")
	_sheet("kt_tally_mark", Vector2i(8, 5), 2, 0.0, Vector2i(0, 0), false, _tally_mark,
		"Last Bell: the tally's engraved marks. Frame 0 one stroke, a 1 px Glow cut lit Heartlight at its top, 1 px in from the frame's left (the plaque's face shows between strokes): advance 2 px per stroke; four strokes span 8 px. Frame 1 the slash, a 1 px Orchid line with a Night shadow, drawn at the same top left as the first stroke, crossing all four. Anchor = top left.")
	_sheet("kt_counter_note", Vector2i(9, 12), 2, 0.0, Vector2i(4, 11), false, _counter_note,
		"Counterpoint: one small note per kind over the nightmare, modulated (multiplier) by that kind's colour; space them 6 px apart, at most 4. Frame 0 hanging, frame 1 flashing at the toll. Anchor = the note head's foot.")

func _tally(img: Image, f: int) -> void:
	# A small hanging plaque of dark bronze (Bark face, an Oak top band, Gold rim on its upper left: metal, not wood
	# grain), notched (swallowtail) ends so it never reads as a health bar, a rivet each side, a hook on top. Struck,
	# it glows hot with a short halo above it.
	# Pass 2: still read as warm wood (a chest lid): the face darker and cooler, Shade with a Bark band (dark bronze),
	# Gold only on its rim and rivets, and a 2 px hook ring clearly hanging it.
	# Pass 3: it still read as a chest (a top band over a wide face, a handle): no band, a narrower plaque with a shield
	# bottom, hung by a cord running up to one nail; struck, the face stays dark and only its rim, rivets and cuts light.
	var plate := _blank(img)
	var widths := [11, 13, 13, 13, 13, 11, 7, 3, 1]  # Rows from y 5: a tag narrowing to a 2 px V point (pass 5: a round bottom read as a purse)
	for i in widths.size():
		var w: int = widths[i]
		for x in range(9 - w / 2, 9 - w / 2 + w):
			_px(plate, x, 5 + i, BARK)
	# Pass 4: a Shade face matched the night ground (only the lit rim read, a bracket): a dark bronze Bark face one step
	# above it, the Gold rim on the upper left and a dim Oak rim down the right and the point; the nail apart from the cord.
	for y in range(5, 14):  # The dim rim, lower right (before the outline: after it nothing borders empty space)
		for x in range(9, 17):
			if plate.get_pixel(x, y).a > 0.0 and (_empty(plate, x + 1, y) or _empty(plate, x, y + 1)):
				_px(plate, x, y, OAK)
	_rim(plate, [BARK], GOLD if f == 0 else GLOW, Vector2(9.0, 8.0))
	_outline(plate)
	_over(img, plate)
	# The cord, up to just under its nail, in Bellflower pink (final council: all bronze read as a Firefly mark)
	_line(img, Vector2i(8, 2), Vector2i(4, 4), BLOSSOM)
	_line(img, Vector2i(10, 2), Vector2i(14, 4), BLOSSOM)
	_px(img, 9, 1, NIGHT)
	_px(img, 9, 0, GLOW if f == 1 else GOLD)  # The nail, a pixel above the cord's peak
	for r: Vector2i in [Vector2i(4, 6), Vector2i(14, 6)]:
		_px(img, r.x, r.y, HEART if f == 1 else GOLD)
	if f == 1:  # A short halo, above it only (r 9 was cut flat by the frame's edges, final council)
		_halo(img, Vector2(9.0, 8.0), 7.0, GLOW, 1, 0.4, true)

# --- Last Bell's tally marks, softened (owner 2026-10-25: "soften the tally marks through the council") -------------
# In game the 2 px strokes (a Night shadow and a Heartlight cut, touching) ran into one bright cream block on the
# plaque at 5 and 7 rings. Now each stroke is a 1 px warm Glow cut lit Heartlight at its top, with the plaque's face
# showing in the 1 px gap before the next (code still advances 2 px a stroke, from (5, 7)); the fifth is a 1 px slash in
# the deeper Bellflower pink (Orchid), so it reads across the four strokes instead of merging with them (council rounds 1-2).
func _tally_mark(img: Image, f: int) -> void:
	if f == 0:
		_grid(img, ["H", "G", "G", "G"], {"H": HEART, "G": GLOW}, Vector2i(1, 0))  # 1 px in: the first stroke clear of the rim
	else:
		# Council round 1: a 1 px line (one pixel a step) crossing each stroke (x 1, 3, 5, 7) at one pixel only, in the
		# deeper Bellflower pink with a Night shadow under each step, so the five reads as a slashed bundle at 1x.
		var line: Array = _bresenham(Vector2i(1, 3), Vector2i(7, 0))  # From 1 px in: clear of the rim
		for p: Vector2i in line:
			if p.x % 2 == 0:  # Its shadow only between the strokes (under a stroke it cut the stroke in two)
				_px(img, p.x, p.y + 1, NIGHT)
		for p: Vector2i in line:
			_px(img, p.x, p.y, ORCHID)

func _counter_note(img: Image, f: int) -> void:
	# An eighth note in pale tones (it takes its kind's colour as a multiplier), a Night outline and an upper-left rim of
	# light like kt_allegro_note; flashing, its head is a light (Glow core, Heartlight centre) in a banded halo.
	var note := _blank(img)
	_grid(note, [
		"...sf..",
		"...s.f.",
		"...s..f",
		"...s...",
		"...s...",
		".hhs...",
		"hhhh...",
		".hh...."], {"s": MIST, "f": MIST, "h": MIST}, Vector2i(1, 2))
	_outline(note)
	_rim(note, [MIST], HEART, Vector2(4.0, 6.0))
	_over(img, note)
	if f == 1:
		_grid(img, [".GG.", "GHHG", ".GG."], {"G": GLOW, "H": HEART}, Vector2i(1, 7))
		_halo(img, Vector2(3.0, 8.5), 4.0, GLOW, 0, 0.4)

# --- Built rows still on stand-ins (owner 2026-10-25: "create these and do the pass with the council") ---------------
# Rot Bloom, Silt, Rapids, Sinking Mud, Fathoms, Deep End, Undertow, Crushing Depth (Dewdrop), Ensemble / Sounding
# Board (Bellflower). Same rules as calling_evo_art.gd's header. Council round 1 (all three seats) fixes in the comments.
func _stand_in_rows_s33() -> void:
	_sheet("sp_rot_bloom", Vector2i(32, 18), 7, 10.0, Vector2i(16, 10), false, _rot_bloom,
		"Rot Bloom: a rot flower opening on the ground under the nightmare on its third cap: an orchid-tipped bud opens into six bruised petal lobes rimmed orchid round a plain dark centre, reaching past the body, pink spores puffing up, then it wilts (one shot, 0.7 s; the big green number is code's). It stays on the ground where it opened (it never follows the nightmare). Anchor = the nightmare's feet when it opened.")
	_sheet("dw_silt", Vector2i(32, 10), 2, 2.0, Vector2i(16, 5), true, _silt,
		"Silt: the pale tide line left on each surged path step, lumpy, a dark wet edge under it, glints shifting (tiles every 32 px along the path; fade it out with alpha over the 4 s). Anchor = the route point.")
	_sheet("dw_rapids", Vector2i(32, 18), 4, 8.0, Vector2i(16, 9), true, _rapids,
		"Rapids: white water on the water's last 3 steps, clusters of foam racing downstream with short wakes (drawn flowing right: flip it flowing left; on water running up or down the screen rotate it 90 degrees, never scale; tiles every 32 px). Over the water surface, under the nightmares. Anchor = the route point.")
	_sheet("dw_mud_cling", Vector2i(27, 12), 4, 6.0, Vector2i(13, 5), true, _mud_cling,
		"Sinking Mud: clumps of mud clinging round a nightmare's feet for its 4 steps, drips lengthening and falling off. Drawn over the nightmare's feet (its front clumps cover them: that is the clinging). Anchor = its feet.")
	_sheet("dw_mud_splash", Vector2i(17, 14), 4, 12.0, Vector2i(8, 12), false, _mud_splash,
		"Sinking Mud: mud splashing up at a flyer's shadow on water or mud, a crown of round clods and a splat at its foot (one shot, ~0.33 s). Anchor = the shadow.")
	_sheet("dw_fathoms", Vector2i(26, 14), 5, 0.0, Vector2i(13, 12), false, _fathoms,
		"Fathoms: dark water climbing the nightmare's body, one frame per depth (0 = +10% ... 4 = full at +50%); code swaps the frame as the depth grows and holds it; on a nightmare shorter than about 20 px cap the frame so the water stays below its eyes. Drawn over the nightmare's lower body, never above its eyes; see-through (0.4, 0.75 at the deepest), a lit waterline with one bright crest. Anchor = its feet.")
	_sheet("dw_spray_ring", Vector2i(37, 37), 20, 14.0, Vector2i(18, 18), false, _spray_ring,
		"Deep End: the spray ring round the Black Pond spill, drops flung out in a ring (one shot: play the 5 frames of one tier at 14 fps). Four tiers by rank, never scaled, each wider, thicker and brighter: frames 0-4 rank 0-I, 5-9 II-III, 10-14 IV-V, 15-19 VI-VII (a solid rim flash). Anchor = the hit nightmare's centre.")
	_sheet("dw_swirl", Vector2i(29, 29), 12, 12.0, Vector2i(14, 14), false, _swirl,
		"Undertow: the spray folding back into the nightmare hit, three comma-tailed spiral arms turning in to the centre (one shot, 6 frames). Frames 0-5 with company around it, 6-11 dark ink (the fewer around, the darker: pick by count). Undertow only hits a nightmare in the pond, so it always plays over water (the dark ink is drawn for the water, not dry ground). Anchor = the hit nightmare's centre.")
	_sheet("dw_shell_crack", Vector2i(17, 15), 5, 12.0, Vector2i(8, 7), false, _shell_crack,
		"Crushing Depth: the nightmare's shell cracking just under the water line: a dark jagged crack with a lit edge and a white-hot start, branching, chips flying up (one shot, ~0.42 s). Anchor = the waterline on its body (its wading waterline point).")
	_sheet("kt_staff_clef", Vector2i(13, 17), 2, 0.0, Vector2i(6, 15), false, _staff_clef,
		"Ensemble / Sounding Board: a small bronze clef at the bell's end of the staff lines; show frame 1 (lit) for ~0.2 s when a repeat lands. Code draws the staff: three 1 px lines 2 px apart from the clef's right side to each joined Warden, solid Oak (alpha 1: at 0.75 they were faint at play zoom), the top line Blossom; Sounding Board's run-on lines Warden to Warden in Oak at 0.75. Anchor = the clef's foot.")
	_sheet("kt_staff_echo", Vector2i(17, 15), 5, 10.0, Vector2i(3, 12), false, _staff_echo,
		"Ensemble: the second repeat landing as an echo: a bronze note (head, stem, flag) with two pink echo arcs rippling off it, fading (one shot, 0.5 s). Anchor = the note head's foot, at the Warden.")

func _rot_bloom(img: Image, f: int) -> void:
	# A flower of rot opening flat on the ground (no outline, one light accent): five petals with clear gaps, Bruise, every
	# petal rimmed Orchid (Bruise alone melted into the purple nightmares standing on it, round 1), Shade on the far side,
	# reaching past a 24 px body; a Root centre with a Sprig fleck; spores at the full bloom; then it wilts. The bud tip is
	# Orchid from the first frame.
	# Round 2: thin radiating petals round a lit centre read as a purple spider or octopus: six rounded petal lobes, wider
	# than long, round a plain Root disc (no outline, no fleck: no face).
	var c := Vector2(16.0, 10.0)
	var big: float = [1.5, 5.0, 9.0, 13.0, 14.5, 14.5, 14.0][f]
	var alpha: float = [1.0, 1.0, 1.0, 1.0, 1.0, 0.75, 0.4][f]
	var centre_r := maxf(1.6, big * 0.22)
	var inside := func(x: float, y: float) -> bool:
		var d := Vector2(x - c.x, (y - c.y) * 2.0)
		if d.length() <= centre_r:
			return true
		if big < 3.0:
			return false
		for i in 6:
			var a := TAU * i / 6.0 + 0.26
			var along := Vector2(cos(a), sin(a))
			var q := d - along * big * 0.62
			var u := q.dot(along) / (big * 0.36)
			var v := q.dot(Vector2(-along.y, along.x)) / (big * 0.26)  # Narrow enough that the six keep gaps between them
			if u * u + v * v <= 1.0:
				return true
		return false
	for y in img.get_height():
		for x in img.get_width():
			if not inside.call(x + 0.5, y + 0.5):
				continue
			var d := Vector2(x + 0.5 - c.x, (y + 0.5 - c.y) * 2.0)
			var col: Color = BRUISE
			if d.length() <= centre_r:
				col = ROOT
			else:
				var edge := false
				for o: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					if not inside.call(x + o.x + 0.5, y + o.y + 0.5):
						edge = true
				if edge:
					col = ORCHID if d.x + d.y < 3.0 else BRUISE
				elif d.x + d.y > 2.0:
					col = SHADE
			_px(img, x, y, Color(col, alpha))
	if f == 0:  # The bud: 3 px with an Orchid tip (a single pixel was invisible at play zoom, wiring capture)
		_grid(img, [".o.", "obo", ".b."], {"o": ORCHID, "b": BRUISE}, Vector2i(15, 8))
	if f >= 3 and f <= 5:
		for i in 4:
			var p := Vector2i(13 + i * 2, 8 - (f - 3) * 2 - (i % 2) * 2)
			_px(img, p.x, p.y, Color(BLOSSOM, 0.75 if f < 5 else 0.4))

func _silt(img: Image, f: int) -> void:
	# A pale tide line wavering across the step (period 16 divides the 32 px tile), lumpy (thicker in three uneven
	# places), a dark wet edge under it so it holds on the pale path (round 1), grains of silt glinting (shifting).
	for x in img.get_width():
		var y := 4 + roundi(sin(x * TAU / 16.0) * 1.0)
		_px(img, x, y, Color(MOONPATH, 0.75))
		_px(img, x, y + 1, Color(POOL, 0.75))
		if x % 32 in [3, 4, 5, 6, 14, 15, 24, 25, 26]:
			_px(img, x, y - 1, Color(MOONPATH, 0.75))  # Its lumps
			_px(img, x, y + 2, Color(POOL, 0.4))
	for gx: int in [5, 13, 21, 29]:
		var g := (gx + f * 4) % 32
		_px(img, g, 3 + roundi(sin(g * TAU / 16.0)), Color(DEADWOOD, 0.75))
	var gl := (9 + f * 8) % 32
	_px(img, gl, 3 + roundi(sin(gl * TAU / 16.0)), MOON)

func _rapids(img: Image, f: int) -> void:
	# White water: clusters of foam (a 3x2 Moonlight blob, a Heartlight head) with a short Dewlight wake, twice as many as
	# the water's own glints and moving 8 px a frame (4 x 8 = the 32 px tile: no seam); no arrows (owner: no direction
	# chevrons on the water).
	var w := img.get_width()
	var clusters := [Vector2i(2, 3), Vector2i(18, 4), Vector2i(10, 7), Vector2i(26, 8), Vector2i(4, 11), Vector2i(20, 12),
		Vector2i(12, 15), Vector2i(28, 15)]
	for cl: Vector2i in clusters:
		var x0 := (cl.x + f * 8) % w
		for k in 4:  # The wake behind it
			_px(img, (x0 - 1 - k + w) % w, cl.y + 1, Color(DEWLIGHT, 0.75 if k < 2 else 0.4))
		_px(img, x0 % w, cl.y, MOON)
		_px(img, (x0 + 1) % w, cl.y, MOON)
		_px(img, (x0 + 2) % w, cl.y, HEART)
		_px(img, x0 % w, cl.y + 1, MOON)
		_px(img, (x0 + 1) % w, cl.y + 1, MOON)

func _mud_cling(img: Image, f: int) -> void:
	# Clumps of mud clinging round the feet (four lumps with gaps, round 1: a closed ring read as a boat or Heavy Water's
	# oval), Loam lit on top with a wet Moonpath glint, Bark under, a Root outline; drips lengthening, then falling (each
	# on a 4-frame cycle, inside the frame).
	# Round 2: the touching lumps still read as one log at 1x: three lumps with clear gaps between their outlines, drips in
	# lighter Loam, lengthening further before they fall.
	var body := _blank(img)
	for cl: Vector3i in [Vector3i(4, 5, 3), Vector3i(13, 6, 3), Vector3i(22, 5, 3)]:  # Wider than tall: clods, not caps
		for y in range(cl.y - 2, cl.y + 2):
			for x in range(cl.x - cl.z, cl.x + cl.z + 1):
				var e := Vector2((x + 0.5 - cl.x) / (cl.z + 0.5), (y + 0.5 - cl.y) / 1.8)
				if e.length() <= 1.0:
					_px(body, x, y, LOAM if y < cl.y else BARK)
	_outline(body, ROOT)
	_over(img, body)
	for p: Vector2i in [Vector2i(3, 4), Vector2i(12, 5), Vector2i(21, 4)]:
		_px(img, p.x, p.y, MOONPATH)  # Wet glints
	for i in 3:
		var dx: int = [6, 11, 24][i]  # Off to one side of each lump (a drip under its middle read as a mushroom stem)
		var t := (f + i) % 4
		var top: int = [7, 8, 7][i]
		match t:
			0:
				_px(img, dx, top, LOAM)
			1:
				_px(img, dx, top, LOAM)
				_px(img, dx, top + 1, LOAM)
			2:
				_px(img, dx, top, LOAM)
				_px(img, dx, top + 1, LOAM)
				_px(img, dx, top + 2, LOAM)
			3:
				_px(img, dx, top + 3, Color(LOAM, 0.75))

func _mud_splash(img: Image, f: int) -> void:
	# A crown of mud: round 2x2 clods (a Root core, Loam, a Moonpath glint) fanned out in an arc, a flat splat at its
	# foot; then the clods fall back and the splat thins (round 1: thin stalks read as candles).
	var c := Vector2i(8, 12)
	var clods: Array = [[], [Vector2i(-4, -4), Vector2i(-1, -6), Vector2i(2, -6), Vector2i(4, -4)],
		[Vector2i(-6, -6), Vector2i(-2, -8), Vector2i(2, -8), Vector2i(6, -6)],
		[Vector2i(-7, -3), Vector2i(-3, -5), Vector2i(3, -5), Vector2i(7, -3)]][f]
	# Wiring capture: 2x2 dark clods read as specks at play zoom: 3x3 clods lit Deadwood with a Moonpath glint, Loam,
	# a Bark underside; a 2-row splat with wet Moonpath ends.
	for d: Vector2i in clods:
		var ca := 1.0 if f < 3 else 0.75  # Round 2: the last frame's clods fade with the splat instead of popping
		_grid(img, ["md.", "dLL", ".LB"], {"m": Color(MOONPATH, ca), "d": Color(DEADWOOD, ca), "L": Color(LOAM, ca),
			"B": Color(BARK, ca)}, c + d - Vector2i(1, 1))
	var splat: int = [3, 5, 6, 6][f]
	var sa := 1.0 if f < 3 else 0.4
	for x in range(-splat, splat + 1):
		_px(img, c.x + x, c.y, Color(LOAM if absi(x) < splat else MOONPATH, sa))
		if absi(x) < splat - 1:
			_px(img, c.x + x, c.y + 1, Color(BARK, sa))
	if f <= 1:
		_px(img, c.x - 1, c.y - 1, ROOT)
		_px(img, c.x, c.y - 1, LOAM)
		_px(img, c.x + 1, c.y - 1, ROOT)

func _fathoms(img: Image, f: int) -> void:
	# Dark water standing round the body, higher each stage but never past its eyes (8 px at the deepest, round 1: a
	# 14 px slab hid the nightmare), its sides following the body (narrowing as it climbs), see-through Pool (0.4, 0.75 at
	# the two deepest), a darker Pool rim only along its bottom curve, a Dewlight waterline with one Heartlight crest.
	var h: int = [2, 4, 5, 7, 8][f]
	var fill_a: float = 0.4 if f < 3 else 0.75
	var c := Vector2(13.0, 12.0)
	var top := c.y - h
	for y in img.get_height():
		for x in img.get_width():
			var up := clampf((c.y - (y + 0.5)) / 9.0, 0.0, 1.0)
			var half := 12.0 - 4.0 * up
			var dx := (x + 0.5 - c.x) / half
			if absf(dx) > 1.0:
				continue
			var bottom := c.y + 1.5 * sqrt(maxf(1.0 - dx * dx, 0.0))
			var surface := top + 1.2 * sqrt(maxf(1.0 - dx * dx, 0.0)) - 1.2 + 0.6 * sin(x * 1.3)
			if y + 0.5 < surface or y + 0.5 > bottom:
				continue
			var col: Color = Color(POOL, fill_a)
			if y == floori(surface):
				col = DEWLIGHT
			elif y + 1.5 > bottom:
				col = POOL  # The darker rim along its bottom
			_px(img, x, y, col)
	var crest_x := 9
	var crest_y := floori(top + 1.2 - 1.2 + 0.6 * sin(crest_x * 1.3))
	_px(img, crest_x, crest_y, HEART)
	_px(img, crest_x + 1, crest_y, MOON)

func _spray_ring(img: Image, f: int) -> void:
	# Drops flung out in a ring, each tier clearly wider, thicker and brighter (round 1: the tiers were too alike):
	# tier 0 1 px Dewlight drops; tier 1 2 px with a Moonlight head; tier 2 2 px with a Heartlight head; tier 3 3 px
	# streaks and a solid Moonlight rim flash. A Pool pixel just inside each drop keeps it from melting into the water.
	var tier := f / 5
	var k := f % 5
	var c := Vector2(18.5, 18.5)
	var r: float = [3.0, 6.0, 9.0, 11.0, 12.0][k] + tier * 1.5
	var n := 8 + 2 * tier
	var alpha: float = [1.0, 1.0, 1.0, 0.75, 0.4][k]
	var length: int = [2, 2, 3, 3][tier]  # Round 2: tier 0 (the rank seen most) 2 px with a Moonlight head, not a faint 1 px drop
	var head: Color = [MOON, HEART, HEART, HEART][tier]
	for i in n:
		var a := TAU * (i + 0.5 * (tier % 2)) / n
		var dir := Vector2(cos(a), sin(a))
		var tip := c + dir * r
		var dark := tip - dir * (length + 0.5)
		_px(img, floori(dark.x), floori(dark.y), Color(POOL, alpha * 0.75))
		for s in range(length - 1, 0, -1):
			var t := tip - dir * s
			_px(img, floori(t.x), floori(t.y), Color(DEWLIGHT, alpha))
		_px(img, floori(tip.x), floori(tip.y), Color(head, alpha))
	if k == 0:
		_grid(img, [".d.", "dMd", ".d."], {"d": DEWLIGHT, "M": MOON}, Vector2i(17, 17))
	if tier == 3 and (k == 1 or k == 2):  # The top tier's rim flash
		var inner := r - 2.0
		var m := ceili(TAU * inner)
		for i in m:
			var a := TAU * i / m
			_px(img, floori(c.x + cos(a) * inner), floori(c.y + sin(a) * inner), Color(MOON, 0.75))

func _swirl(img: Image, f: int) -> void:
	# The spray folding back in: three comma-tailed spiral arms all turning the same way, closing on the centre and
	# turning 0.3 rad a frame (0.7 wagon-wheeled against the drop spacing, round 1), a small splash at the centre, then a
	# fade frame. Dark variant (frames 6-11): ink (Night / Shade) with one light Dewlight pixel at each head, so it still
	# shows on water.
	var dark := f >= 6
	var k := f % 6
	var c := Vector2(14.5, 14.5)
	var r0: float = [6.5, 5.0, 3.5, 2.5, 1.5, 1.5][k]  # Round 2: tails clipped at 9; 6.5 + 6 steps x 1.0 stays inside
	var alpha: float = 1.0 if k < 5 else 0.4
	var head: Color = DEWLIGHT if dark else MOON
	var body: Color = SHADE if dark else DEWLIGHT
	var tail: Color = NIGHT if dark else DEW
	# Round 2: from the first frame each arm is a solid curved stroke (its points joined), not dots: dots read as a
	# second spray ring.
	for arm in 3:
		var base := TAU * arm / 3.0 + k * 0.3
		var prev := Vector2i.ZERO
		var first := Vector2i.ZERO
		for t in 7:
			var rr := r0 + t * 1.0
			var a := base - t * 0.32
			var p := c + Vector2(cos(a), sin(a)) * rr
			var cur := Vector2i(floori(p.x), floori(p.y))
			var col: Color = body if t < 3 else tail
			if t == 0:
				first = cur
			else:
				for q: Vector2i in _bresenham(prev, cur):
					_px(img, q.x, q.y, Color(col, alpha * (1.0 if t < 5 else 0.75)))
			prev = cur
		_px(img, first.x, first.y, Color(head, alpha))
	if k >= 4:
		_grid(img, [".h.", "hHh", ".h."], {"h": body, "H": head}, Vector2i(13, 13))

func _shell_crack(img: Image, f: int) -> void:
	# The shell cracking just under the water line (a 1 px Dewlight water line across the top): a dark jagged gap (Night)
	# with a lit edge above it in the shell's own light (Mist), a white-hot start (Heartlight) so it holds on water,
	# branching; chips of shell (Bruise lit Mist) flying up into the headroom above, then it dims.
	var c := Vector2i(8, 9)
	var path := [Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 0), Vector2i(3, 1), Vector2i(4, 2), Vector2i(5, 1), Vector2i(6, 2),
		Vector2i(7, 3)]
	var reach: int = [0, 3, 8, 8, 8][f]
	var alpha: float = [1.0, 1.0, 1.0, 0.75, 0.4][f]
	for x in range(1, 16):
		_px(img, x, 7, Color(DEWLIGHT, 0.75 * alpha))  # The water line, fading with the crack (round 2: it popped off)
	if f == 0:
		_grid(img, [".h.", "hHh", ".h."], {"h": MIST, "H": HEART}, c - Vector2i(1, 1))
	for side: int in [-1, 1]:
		for i in reach:
			var p: Vector2i = path[i]
			_px(img, c.x + side * p.x, c.y + p.y, Color(NIGHT, alpha))
			_px(img, c.x + side * p.x, c.y + p.y - 1, Color(MIST, alpha))
	if f >= 1:
		_px(img, c.x, c.y, Color(HEART, alpha))
	if f >= 2 and f <= 3:
		for b: Vector2i in [Vector2i(-3, 2), Vector2i(-3, 3), Vector2i(4, 3), Vector2i(4, 4)]:
			_px(img, c.x + b.x, c.y + b.y, Color(NIGHT, alpha))
	if f >= 2:
		var out: int = f - 2
		for chip: Vector2i in [Vector2i(-4, -3), Vector2i(3, -4), Vector2i(-1, -5)]:
			var p := c + chip + Vector2i(signi(chip.x) * out, -out)
			_px(img, p.x, p.y, Color(MIST, alpha))
			_px(img, p.x + 1, p.y, Color(BRUISE, alpha))

func _staff_clef(img: Image, f: int) -> void:
	# A small clef in bronze (Gold, lit Glow; a Blossom curl), a Night outline like the notes (a row down so its top is not
	# clipped, round 1); lit, a Heartlight glint.
	var clef := _blank(img)
	_grid(clef, [
		"...gg..",
		"..g..g.",
		"..g..g.",
		"...gg..",
		"...g...",
		"..gg...",
		".g.gg..",
		"g..g.g.",
		"g.ppg.g",
		".g..g.g",
		"..ggg..",
		"....g..",
		"..gg..."], {"g": GLOW if f == 1 else GOLD, "p": BLOSSOM}, Vector2i(3, 2))
	_outline(clef)
	_rim(clef, [GOLD, GLOW], HEART if f == 1 else GLOW, Vector2(6.0, 8.0))
	_over(img, clef)
	if f == 1:  # Lit: the whole clef burns Glow, rimmed Heartlight, in a bigger halo (wiring capture: too like frame 0)
		_px(img, 6, 3, HEART)
		_halo(img, Vector2(6.5, 8.5), 6.0, GLOW, 0, 0.75)

func _staff_echo(img: Image, f: int) -> void:
	# A bronze note (an oval head, a straight stem, a flag), a Night outline and an upper-left Glow rim like the notes,
	# landing; two Blossom / Oak echo arcs rippling off its right side, inside the frame; it fades.
	var note := _blank(img)
	_grid(note, [
		"...sf.",
		"...s.f",
		"...s.f",
		"...s..",
		"...s..",
		".hhs..",
		"hhhh..",
		".hh..."], {"s": GOLD, "f": GOLD, "h": GOLD}, Vector2i(1, 3))
	_outline(note)
	_rim(note, [GOLD], GLOW, Vector2(3.0, 8.0))
	var a: float = [1.0, 1.0, 1.0, 0.75, 0.4][f]
	for y in note.get_height():
		for x in note.get_width():
			var px := note.get_pixel(x, y)
			if px.a > 0.0:
				_px(img, x, y, Color(px, a))
	for i in 2:
		var step := f - i
		if step < 1 or step > 3:
			continue
		var r := 2.0 + step * 2.0
		var ca := Color(BLOSSOM if i == 0 else OAK, 0.75 if step < 3 else 0.4)
		for s in range(-3, 4):
			var ang := s * 0.25
			_px(img, floori(7.5 + cos(ang) * r), floori(9.5 + sin(ang) * r), ca)
# --- Wading, redone (owner 2026-10-25, screenshot: a nightmare entering the Dewdrop water was drawn under it, as if it
# walked under the path. Direction: nightmares always draw on top of the water; show wading instead: a small ripple ring
# at the feet, the bottom few pixels of the sprite tinted with the water colour (knee-deep), a soft splash on entering
# and leaving; flyers get no ripple). Council rounds 1-3. The tint is a shader on the nightmare (code's: dw_wade_ripple's
# note has its numbers); these are its marks.
func _wading_marks() -> void:
	_sheet("dw_wade_ripple", Vector2i(30, 10), 6, 6.0, Vector2i(15, 5), true, _wade_ripple,
		"Wading: rings spreading from a walker's feet while it stands in the water (never on flyers): two soft rings a half-cycle apart, the front arc lit, the back arc faint (the body hides most of it). Drawn just under the nightmare (before its sprite), over the water. Hide it while the nightmare wears Heavy Water (dw_heavy_cling takes the feet). With it, code tints the nightmare knee-deep: the bottom 18% of its drawn height (at least 3 px), measured up from the feet anchor (never from a frame's lowest pixel), mixed 55% toward Dew, the band's top row 50% toward Dewlight (the waterline on the body); nightmares always draw over the water. Anchor = its feet.")
	_sheet("dw_wade_splash", Vector2i(31, 14), 5, 14.0, Vector2i(15, 11), false, _wade_splash,
		"Wading: a soft, low splash as a walker steps into or out of the water: a few low drops kicked out to the sides and a ring at the feet (one shot, ~0.36 s; never on flyers; quieter than dw_blue_splash, which is a hit). Drawn under the nightmare's sprite like the ripple (the body hides the drops behind it; the ones beside it show). Anchor = its feet.")

func _wade_ripple(img: Image, f: int) -> void:
	# Two rings spreading from the feet, a half-cycle apart (period 6 on the 6-frame loop: no seam): squashed for the
	# ground, the front (lower) arc Dewlight with a Moonlight lead on the young ring, the back arc faint; each fades in
	# steps as it widens.
	var c := Vector2(15.0, 5.0)
	for i in 2:
		var age := (f + 3 * i) % 6
		var rx := 6.0 + age * 1.6
		var ry := rx * 0.32
		var alpha: float = [0.75, 0.75, 0.75, 0.4, 0.4, 0.4][age]  # Round 1: at 1.0 the ring outshone the nightmare
		var n := ceili(TAU * rx)
		for k in n:
			var a := TAU * k / n
			var p := c + Vector2(cos(a) * rx, sin(a) * ry)
			var front := sin(a) > 0.0
			var col: Color = (MOON if age < 2 and absf(cos(a)) < 0.5 else DEWLIGHT) if front else DEWLIGHT
			_px(img, floori(p.x), floori(p.y), Color(col, alpha if front else 0.4))

func _wade_splash(img: Image, f: int) -> void:
	# A low, soft splash (knee-deep, not a crown): a flat ring at the feet widening, four Dewlight drops kicked out to the
	# sides and falling back; then only the ring, fading.
	var c := Vector2(15.5, 11.5)
	var rx: float = [3.0, 5.0, 7.0, 8.5, 9.5][f]
	var ring_a: float = [0.75, 0.75, 0.75, 0.4, 0.4][f]
	var n := ceili(TAU * rx)
	for k in n:
		var a := TAU * k / n
		if sin(a) < -0.2 and f < 2:
			continue  # The back of the ring is behind the feet at first
		var p := c + Vector2(cos(a) * rx, sin(a) * rx * 0.32)
		_px(img, floori(p.x), floori(p.y), Color(DEWLIGHT, ring_a))
	# Rounds 1-2: Dewlight only and never above 6 px (white-tipped drops rising from a ring is dw_blue_splash's hit: this
	# is a step); drawn under the sprite and fanned out to +-14: none sit on a body; beside a Shade the drops show, a Husk
	# (+-18) hides most of them and its splash reads mainly as the ring.
	var drops: Array = [[Vector2i(-8, -1), Vector2i(8, -1)], [Vector2i(-11, -3), Vector2i(-8, -4), Vector2i(8, -4), Vector2i(11, -3)],
		[Vector2i(-13, -4), Vector2i(-10, -6), Vector2i(10, -6), Vector2i(13, -4)], [Vector2i(-14, -2), Vector2i(-11, -3), Vector2i(11, -3), Vector2i(14, -2)], []][f]
	for d: Vector2i in drops:
		var p := Vector2i(c) + d
		_px(img, p.x, p.y, Color(DEWLIGHT, 0.75 if f < 3 else 0.4))

