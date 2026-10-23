extends SceneTree
# Art for the rebuilt Calling evolutions' marks (Roguelite asset chat; Roguelite Code's request 2026-10-23: "the rebuilt
# Calling evolutions (section 33) draw placeholder marks in code that want real art … Owner reviews before anything is
# wired"). Writes assets/effects/calling_evo/<name>.png (frames side by side) and calling_evo.json (frame size, frames,
# fps, anchor, loop, where it goes). NOT wired: the code still draws its placeholders until the owner approves.
# Heartwood 32 only (HeartwoodPalette.snap_image); 1x pixel art at 64 px per cell (art_direction.md "detailed 64"):
# marks over a nightmare keep a dark NIGHT outline so they read on the pale path and on dark bodies; marks on the
# ground have none and use the 0.75 / 0.4 alpha steps. Bronze (Bellflower) has no palette ramp: OAK, EMBER, GOLD.
# Run:  Godot --headless --path . --script res://tools/calling_evo_art.gd

const OUT := "res://assets/effects/calling_evo/"
const PALETTE_TOOL := "res://tools/art/heartwood_palette.gd"

# Heartwood 32
const NIGHT := Color("24243c")
const DUSK := Color("3c3c5c")
const SLATE := Color("5c5a78")
const DREAD := Color("140f26")
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

func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)

# A pixel grid: one string per row, `keys` maps each character to a colour ('.' and ' ' are empty).
func _grid(img: Image, rows: Array, keys: Dictionary, at: Vector2i = Vector2i.ZERO) -> void:
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if keys.has(ch):
				_px(img, at.x + x, at.y + y, keys[ch])

# A 1 px NIGHT outline round everything opaque (marks that float over nightmares and the path).
func _outline(img: Image, ink: Color = NIGHT) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var add: Array = []
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var q := Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < w and q.y < h and img.get_pixelv(q).a >= 0.99:
					add.append(Vector2i(x, y))
					break
	for p: Vector2i in add:
		img.set_pixelv(p, ink)

static func _hash01(x: int, y: int, salt: int = 0) -> float:
	return fposmod(sin(float(x) * 12.9898 + float(y) * 78.233 + float(salt) * 37.719) * 43758.5453, 1.0)

# --- Lantern Light (Firefly) --------------------------------------------------------------------------------------

const FLAME_KEYS := {"E": EMBER, "y": GOLD, "G": GLOW, "H": HEART}
const FLAME_HOT := {"E": GOLD, "y": GLOW, "G": HEART, "H": MOON}  # Moth to Flame ready: burns white

func _firefly() -> void:
	_sheet("lf_waiting_flame", Vector2i(9, 12), 4, 8.0, Vector2i(4, 11), true, _waiting_flame,
		"Bonfire: the small flame over a nightmare holding a waiting crit (LanternMark, was two circles at (-10, -30)). Anchor = its base.")
	_sheet("lf_moth_flame", Vector2i(15, 16), 4, 6.0, Vector2i(7, 15), true, _moth_flame.bind(false),
		"Moth to Flame: the kept crit, a larger flame with a moth circling it (LanternMark, was circles at (10, -32)). Anchor = its base.")
	_sheet("lf_moth_flame_ready", Vector2i(15, 16), 4, 8.0, Vector2i(7, 15), true, _moth_flame.bind(true),
		"Moth to Flame: the same flame once its 4 hits are in, burning white. Same frames and anchor as lf_moth_flame.")
	_sheet("lf_strung_pip", Vector2i(7, 7), 2, 3.0, Vector2i(3, 3), true, _spark_pip.bind(GLOW, GOLD),
		"Strung Lights: one spark pip per glow entered, in a row 6 px apart over the health bar. Anchor = centre.")
	_sheet("lf_constellation_pip", Vector2i(7, 7), 2, 3.0, Vector2i(3, 3), true, _spark_pip.bind(MOON, MIST),
		"Constellation: one silver pip per different Warden counted toward the star. Anchor = centre.")
	_sheet("lf_constellation_star", Vector2i(17, 17), 4, 6.0, Vector2i(8, 8), true, _star,
		"Constellation: the star lit over a nightmare (its 3 charges stay as constellation pips under it). Anchor = centre.")
	_sheet("lf_full_glow_ring", Vector2i(34, 14), 4, 6.0, Vector2i(17, 7), true, _full_glow,
		"Full Glow: the carried light round a lit nightmare's feet, a banded gold ring (on the ground, under it). Anchor = centre.")
	_sheet("lf_pale_path_dot", Vector2i(9, 7), 4, 4.0, Vector2i(4, 3), true, _pale_dot,
		"Sightline: the silver glint on each pale-path step (on the ground). Anchor = centre of the step.")

func _waiting_flame(img: Image, f: int) -> void:
	var frames := [
		["....E....", "...EyE...", "...EyE...", "..EyGyE..", "..EyGyE..", ".EyGGGyE.", ".EyGHGyE.", ".EyGHHyE.", ".EyGHGyE.", "..EyGyE..", "...EEE...", "........."],
		[".....E...", "....EyE..", "...EyyE..", "..EyGyE..", "..EyGyE..", ".EyGGGyE.", ".EyGHGyE.", ".EyHHGyE.", ".EyGHGyE.", "..EyGyE..", "...EEE...", "........."],
		["...E.....", "..EyE....", "..EyyE...", "..EyGyE..", "..EyGyE..", ".EyGGGyE.", ".EyGHGyE.", ".EyGHHyE.", ".EyGHGyE.", "..EyGyE..", "...EEE...", "........."],
		[".........", "....E....", "...EyE...", "..EyGyE..", "..EyGyE..", ".EyGGGyE.", ".EyGHGyE.", ".EyHHHyE.", ".EyGHGyE.", "..EyGyE..", "...EEE...", "........."],
	]
	_grid(img, frames[f], FLAME_KEYS)
	_outline(img)

func _moth_flame(img: Image, f: int, hot: bool) -> void:
	var flame := [
		[".....E.....", "....EyE....", "....EyE....", "...EyGyE...", "...EyGyE...", "..EyGGGyE..", "..EyGHGyE..", ".EyGHHHGyE.", ".EyGHHHGyE.", ".EyGHHHGyE.", "..EyGHGyE..", "...EyyyE...", "....EEE...."],
		["......E....", ".....EyE...", "....EyyE...", "...EyGyE...", "...EyGyE...", "..EyGGGyE..", "..EyGHGyE..", ".EyGHHHGyE.", ".EyGHHHGyE.", ".EyGHHGGyE.", "..EyGHGyE..", "...EyyyE...", "....EEE...."],
		["....E......", "...EyE.....", "...EyyE....", "...EyGyE...", "...EyGyE...", "..EyGGGyE..", "..EyGHGyE..", ".EyGHHHGyE.", ".EyGHHHGyE.", ".EyGGHHGyE.", "..EyGHGyE..", "...EyyyE...", "....EEE...."],
		["...........", ".....E.....", "....EyE....", "...EyGyE...", "...EyGyE...", "..EyGGGyE..", "..EyGHGyE..", ".EyGHHHGyE.", ".EyHHHHGyE.", ".EyGHHHGyE.", "..EyGHGyE..", "...EyyyE...", "....EEE...."],
	]
	_grid(img, flame[f], FLAME_HOT if hot else FLAME_KEYS, Vector2i(2, 2))
	_outline(img)
	# The moth: two pale wings and a body, circling the flame (drawn after the outline: it flies in front)
	var moth: Vector2i = [Vector2i(0, 4), Vector2i(11, 1), Vector2i(12, 8), Vector2i(1, 11)][f]
	var wings: Array = [["m.m", ".b."], [".m.", "mbm"]][f % 2]
	_grid(img, wings, {"m": MIST, "b": SLATE}, moth)

func _spark_pip(img: Image, f: int, lit: Color, dim: Color) -> void:
	if f == 0:
		_grid(img, ["...a...", "...a...", "..aHa..", "aaHHHaa", "..aHa..", "...a...", "...a..."], {"a": lit, "H": HEART})
	else:
		_grid(img, [".......", "...b...", "..bab..", ".baHab.", "..bab..", "...b...", "......."], {"a": lit, "b": dim, "H": HEART})
	_outline(img)

func _star(img: Image, f: int) -> void:
	var c := Vector2i(8, 8)
	var long: int = [6, 7, 6, 5][f]
	for i in range(1, long + 1):  # The four long rays, fading to MIST at their tips
		var col: Color = MOON if i <= long - 2 else MIST
		for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			_px(img, c.x + d.x * i, c.y + d.y * i, col)
	for d: Vector2i in [Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:  # Short diagonal glints
		_px(img, c.x + d.x, c.y + d.y, MOON)
		if f % 2 == 1:
			_px(img, c.x + d.x * 2, c.y + d.y * 2, Color(MIST, 0.75))
	_px(img, c.x, c.y, HEART)
	for d: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		_px(img, c.x + d.x, c.y + d.y, HEART)
	_outline(img)

func _full_glow(img: Image, f: int) -> void:
	var c := Vector2(17.0, 7.0)
	for y in img.get_height():
		for x in img.get_width():
			var e := Vector2((x + 0.5 - c.x) / 16.0, (y + 0.5 - c.y) / 6.5)
			var r := e.length()
			var ang := atan2(e.y, e.x)
			var march := int(floor((ang + PI) / TAU * 24.0)) + f  # Dots marching round the ring
			if r > 0.82 and r <= 1.0:
				_px(img, x, y, Color(GLOW, 0.75) if march % 3 != 0 else Color(GOLD, 0.75))
			elif r > 0.64 and r <= 0.82 and march % 2 == 0:
				_px(img, x, y, Color(GLOW, 0.4))

func _pale_dot(img: Image, f: int) -> void:
	var c := Vector2i(4, 3)
	var size: int = [1, 2, 1, 0][f]
	_px(img, c.x, c.y, HEART)
	for i in range(1, size + 1):
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT]:
			_px(img, c.x + d.x * i, c.y, MOON if i == 1 else Color(MIST, 0.75))
		_px(img, c.x, c.y - i, MOON if i == 1 else Color(MIST, 0.75))
		_px(img, c.x, c.y + i, MOON if i == 1 else Color(MIST, 0.75))
	for d: Vector2i in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
		_px(img, c.x + d.x * (size + 1), c.y + d.y, Color(MIST, 0.4))

# --- Spore Print (Sporeling) --------------------------------------------------------------------------------------

func _sporeling() -> void:
	_sheet("sp_throne_rim", Vector2i(28, 12), 2, 2.0, Vector2i(14, 7), true, _throne,
		"Toadstool Throne: the gold plinth under a throne clump, three crown points at its back (on the ground, under the clump). Anchor = the clump's foot.")
	_sheet("sp_rot_ring", Vector2i(28, 14), 2, 1.5, Vector2i(14, 7), true, _rot_ring,
		"Rot Ground: the rot ring on a Sprout bed's step that never goes out (on the ground). Anchor = the step's route point.")
	_sheet("sp_fed_ground", Vector2i(18, 10), 2, 2.0, Vector2i(9, 5), true, _fed_ground,
		"Feeding Ground: a fed patch on each route point for 8 s, two little shoots in it; fade it with alpha as it runs out. Anchor = the route point.")
	_sheet("sp_cap_badge", Vector2i(13, 10), 2, 0.0, Vector2i(6, 9), false, _cap_badge,
		"Host Trees: the cap a Warden of another family wears. Frame 0 its own cap (Blossom), frame 1 a passed-on cap (Spreading Caps: Mist). Anchor = the stem's foot, on the Warden's head.")

func _throne(img: Image, f: int) -> void:
	var c := Vector2(14.0, 7.5)
	for y in img.get_height():
		for x in img.get_width():
			var e := Vector2((x + 0.5 - c.x) / 12.5, (y + 0.5 - c.y) / 4.0)
			var r := e.length()
			if r > 1.0:
				continue
			if r > 0.72:  # The rim: lit gold on the upper left, ember in the lower right
				var lit := e.x * 0.6 + e.y * 0.8
				_px(img, x, y, GLOW if lit < -0.45 else (GOLD if lit < 0.45 else EMBER))
			elif r > 0.5 and (x + y) % 2 == 0:
				_px(img, x, y, Color(GOLD, 0.4))  # A faint inner band
	# Three crown points rising at its back
	for p: Vector2i in [Vector2i(9, 2), Vector2i(14, 1), Vector2i(19, 2)]:
		_px(img, p.x, p.y, GOLD)
		_px(img, p.x, p.y + 1, GOLD)
		_px(img, p.x, p.y - 1, GLOW if f == 1 and p.x == 14 else GOLD)
	if f == 1:  # A glint travelling the rim
		_px(img, 5, 6, HEART)
		_px(img, 6, 5, GLOW)

func _rot_ring(img: Image, f: int) -> void:
	var c := Vector2(14.0, 7.0)
	for y in img.get_height():
		for x in img.get_width():
			var e := Vector2((x + 0.5 - c.x) / 13.0, (y + 0.5 - c.y) / 6.0)
			var r := e.length() + (_hash01(x, y, 3) - 0.5) * 0.18  # A ragged ring
			if r > 0.74 and r <= 1.0:
				_px(img, x, y, Color(DEEPMOSS, 0.75) if _hash01(x, y, 4) > 0.2 else Color(ROOT, 0.75))
			elif r > 0.6 and r <= 0.74 and (x + y) % 2 == 0:
				_px(img, x, y, Color(DEEPMOSS, 0.4))
	# Rot specks and a bubble that swells and pops
	for p: Vector2i in [Vector2i(5, 4), Vector2i(21, 3), Vector2i(23, 9), Vector2i(7, 10)]:
		_px(img, p.x, p.y, Color(BRUISE, 0.75))
	var bub := Vector2i(20, 9) if f == 0 else Vector2i(6, 3)
	_px(img, bub.x, bub.y, Color(SPRIG, 0.75))
	_px(img, bub.x + 1, bub.y, Color(MOSS, 0.75))

func _fed_ground(img: Image, f: int) -> void:
	var c := Vector2(9.0, 5.5)
	for y in img.get_height():
		for x in img.get_width():
			var e := Vector2((x + 0.5 - c.x) / 8.5, (y + 0.5 - c.y) / 4.5)
			var r := e.length()
			if r <= 0.55 and (x + y) % 2 == 0:
				_px(img, x, y, Color(SPRIG, 0.4))
			elif r <= 0.55:
				_px(img, x, y, Color(LEAF, 0.4))
			elif r <= 1.0 and (x + y) % 2 == 0 and _hash01(x, y, 7) > 0.35:
				_px(img, x, y, Color(LEAF, 0.4))
	# Two shoots, leaning with the breeze
	var lean: int = [0, 1][f]
	for s: Vector2i in [Vector2i(6, 6), Vector2i(12, 5)]:
		_px(img, s.x, s.y, LEAF)
		_px(img, s.x, s.y - 1, SPRIG)
		_px(img, s.x - 1 + lean, s.y - 2, NEWLEAF)
		_px(img, s.x + lean, s.y - 2, SPRIG)

func _cap_badge(img: Image, f: int) -> void:
	var keys := {"o": BRUISE, "s": ORCHID, "m": BLOSSOM, "h": HEART, "t": MOONPATH, "d": DEADWOOD} if f == 0 \
		else {"o": SLATE, "s": STONE, "m": MIST, "h": MOON, "t": MOONPATH, "d": DEADWOOD}
	_grid(img, [
		".............",
		"....mmmmm....",
		"..mmhmmmmms..",
		".mhhmmmhmmss.",
		".mmmmmmmmsss.",
		"ooooooooooooo",
		".....ttd.....",
		".....ttd.....",
		".....ttd.....",
		"............."], keys)
	_outline(img)

# --- Puddles (Dewdrop) --------------------------------------------------------------------------------------------

func _dewdrop() -> void:
	_sheet("dw_reeds", Vector2i(11, 16), 4, 3.0, Vector2i(5, 15), true, _reeds,
		"Reed Bed: a reed clump where a wall or Sprout carries the water (stands on the bank: y-sort it or draw over the water). Anchor = its foot.")
	_sheet("dw_mud", Vector2i(34, 20), 2, 0.0, Vector2i(17, 10), false, _mud,
		"Mudflats: a mud patch on each mud step (on the ground, under the water's damp band); two variants, pick by route index. Anchor = the route point.")
	_sheet("dw_still_sheen", Vector2i(22, 6), 4, 3.0, Vector2i(11, 3), true, _sheen,
		"Still Water: the glassy sheen sliding slowly over still water (on the water surface). Anchor = the route point.")
	_sheet("dw_footprints", Vector2i(14, 10), 2, 0.0, Vector2i(7, 5), false, _prints,
		"Wet Footprints: a pair of wet prints; frame 0 and 1 alternate down the path; fade them with alpha over PRINT_SECONDS. Anchor = the route point.")
	_sheet("dw_wave_flash", Vector2i(26, 14), 5, 14.0, Vector2i(13, 11), false, _wave,
		"Breaking Wave / Flash Flood: a white crest that rises, curls and breaks into spray (one shot, ~0.35 s). Anchor = the water's middle.")

func _reeds(img: Image, f: int) -> void:
	var sway: Array = [0, 1, 1, 0]
	var s: int = sway[f]
	# Thin stalks with gaps between them (no outline: it filled the gaps into one green cone), each a 1 px line with
	# its lit pixels near the top: [foot x, height, lean (-1 / 0 / 1), dark, lit, cattail]
	for stalk: Array in [[2, 9, -1, MOSS, LEAF, false], [5, 14, 0, MOSS, SPRIG, true], [7, 11, 1, DEEPMOSS, LEAF, false], [9, 7, 1, MOSS, SPRIG, false]]:
		var x0: int = stalk[0]
		var h: int = stalk[1]
		var lean: int = stalk[2]
		for i in h:
			var bend := 0
			if i > h * 0.5:
				bend = lean + s
			var x := x0 + bend
			_px(img, x, 15 - i, stalk[4] if i > h * 0.55 else stalk[3])
		if stalk[5]:  # A cattail head on the tallest, a dark seed spike over it
			for i in 3:
				_px(img, x0 + lean + s, 15 - h - i + 2, BARK if i == 1 else OAK)
				_px(img, x0 + lean + s + 1, 15 - h - i + 2, ROOT if i == 1 else BARK)
			_px(img, x0 + lean + s, 15 - h - 2, SPRIG)
	_px(img, 4, 15, DEEPMOSS)  # Their roots in the wet bank
	_px(img, 6, 15, DEEPMOSS)

func _mud(img: Image, f: int) -> void:
	var c := Vector2(17.0, 10.0)
	for y in img.get_height():
		for x in img.get_width():
			var e := Vector2((x + 0.5 - c.x) / 16.0, (y + 0.5 - c.y) / 9.0)
			var r := e.length() + (_hash01(x / 3, y / 3, 11 + f) - 0.5) * 0.35
			if r > 1.0:
				continue
			var col: Color = LOAM
			if r > 0.85:
				if (x + y) % 2 == 1:
					continue  # Dithered, drying edge
				col = Color(LOAM, 0.75)
			elif _hash01(x, y, 12 + f) > 0.8:
				col = BARK
			elif e.x * 0.6 + e.y * 0.8 > 0.35:
				col = BARK  # Wetter, darker in the lower right
			_px(img, x, y, col)
	# Wet highlights: a few cold glints and a small puddle-eye
	for p: Vector2i in [[Vector2i(10, 6), Vector2i(23, 12)], [Vector2i(13, 5), Vector2i(21, 13)]][f]:
		_px(img, p.x, p.y, MOONPATH)
		_px(img, p.x + 1, p.y, DEADWOOD)
	var eye: Vector2i = [Vector2i(19, 8), Vector2i(9, 11)][f]
	for d: Vector2i in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i(2, 0), Vector2i(1, 1)]:
		_px(img, eye.x + d.x, eye.y + d.y, POOL)
	_px(img, eye.x, eye.y, DEW)

func _sheen(img: Image, f: int) -> void:
	var start := f * 3
	for i in 9:  # The long glassy line, brightest in its middle
		var x := start + i
		var col: Color = MOON if i >= 3 and i <= 5 else Color(MOON, 0.75 if i >= 1 and i <= 7 else 0.4)
		_px(img, x, 2, col)
	for i in 4:  # A shorter one under it, lagging
		_px(img, start + 2 + i + (1 if f % 2 == 0 else 0), 4, Color(DEWLIGHT, 0.4))

func _prints(img: Image, f: int) -> void:
	var keys := {"p": Color(DEW, 0.75), "r": Color(DEWLIGHT, 0.75), "t": Color(DEW, 0.75)}
	var left := ["..t.t.", ".t...t", "..rpr.", ".rpppr", ".rpppr", "..rpr."]
	_grid(img, left, keys, Vector2i(0, 4) if f == 0 else Vector2i(7, 0))
	_grid(img, left, keys, Vector2i(7, 0) if f == 0 else Vector2i(1, 4))

# A breaker running left to right: a long back slope, a steep front, the white lip curling over it and spilling into
# foam and spray (it was a symmetric hump that read as a hill).
func _wave(img: Image, f: int) -> void:
	var w := img.get_width()
	var crest_h: float = [4.0, 7.0, 9.0, 7.0, 3.0][f]
	var peak_x: float = [12.0, 14.0, 16.0, 18.0, 19.0][f]  # The crest runs forward as it breaks
	var tops := []
	for x in w:
		var hgt := 0.0
		if x <= peak_x:
			hgt = crest_h * pow(float(x) / peak_x, 1.6)  # The long back slope
		else:
			hgt = crest_h * maxf(1.0 - (float(x) - peak_x) / 3.0, 0.0)  # The steep front
		var top := 13 - int(round(hgt))
		tops.append(top)
		for y in range(top, 14):
			var col: Color = Color(DEW, 0.75)
			if y == top:
				col = DEWLIGHT
			elif y == top + 1 and x > peak_x - 6.0:
				col = DEWLIGHT  # The lit face under the crest
			_px(img, x, y, col)
	var crest := int(peak_x)
	var lip: int = tops[crest]
	if f >= 1 and f <= 3:  # The white lip along the crest, curling over the front
		for x in range(crest - 4, crest + 1):
			_px(img, x, int(tops[x]), HEART)
		var curl: Array = [[], [Vector2i(1, 0), Vector2i(2, 1)], [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 1), Vector2i(3, 2)],
			[Vector2i(1, 1), Vector2i(2, 2), Vector2i(3, 4), Vector2i(2, 4), Vector2i(4, 6)]][f]
		for d: Vector2i in curl:
			_px(img, crest + d.x, lip + d.y, HEART if d.y < 3 else MOON)
	if f >= 3:  # Foam spilling down the front and spray thrown up off it
		for x in range(crest - 2, mini(crest + 7, w)):
			_px(img, x, 13, HEART if x % 2 == 0 else MOON)
			_px(img, x, 12, Color(MOON, 0.75) if x % 3 == 0 else Color(HEART, 0.4))
		var rise: int = 0 if f == 3 else 2
		for p: Vector2i in [Vector2i(2, -3), Vector2i(4, -5), Vector2i(6, -2), Vector2i(-1, -4), Vector2i(5, -7)]:
			_px(img, crest + p.x, lip + p.y - rise, HEART if p.x % 2 == 0 else Color(MOON, 0.75))

# --- Keeping Time (Bellflower) ------------------------------------------------------------------------------------

const BRONZE := {"o": OAK, "e": EMBER, "g": GOLD, "h": GLOW}  # No bronze in Heartwood 32: Oak, Ember, Gold, Glow

func _bellflower() -> void:
	_sheet("kt_bronze_prime", Vector2i(11, 11), 2, 3.0, Vector2i(5, 10), true, _prime,
		"Down the Line / Both Ways: a primed nightmare's mark, a small bronze bell with a glint (over its pips). Its ring arcs can use the same ramp: Oak, Ember, Gold. Anchor = the bell's lip.")
	_sheet("kt_allegro_note", Vector2i(8, 11), 2, 3.0, Vector2i(3, 9), true, _note,
		"Allegro: a kept Toll, a bronze note circling the bell (up to 3). Anchor = the note's head.")
	_sheet("kt_humming_pip", Vector2i(11, 7), 2, 4.0, Vector2i(5, 3), true, _hum,
		"Humming Walls: the pip a wall filled, a leaf-green bead with hum lines either side. Anchor = centre.")

func _prime(img: Image, f: int) -> void:
	_grid(img, [
		"...........",
		"....ooo....",
		"...ogghe...",
		"...ogghe...",
		"...oggge...",
		"..oggggge..",
		"..ogggggeo.",
		".oeeeeeeeo.",
		".ooooooooo.",
		".....e.....",
		"..........."], BRONZE)
	if f == 1:  # The glint moving down the lit side
		_px(img, 5, 5, HEART)
	else:
		_px(img, 6, 2, HEART)
	_outline(img)

func _note(img: Image, f: int) -> void:
	_grid(img, [
		"...g....",
		"...gg...",
		"...g.g..",
		"...g..g.",
		"...g..e.",
		"...g....",
		"...g....",
		".ogg....",
		"oggge...",
		"ogeee...",
		".ooo...."], BRONZE)
	_px(img, 1 if f == 0 else 2, 8, GLOW)
	_outline(img)

func _hum(img: Image, f: int) -> void:
	_grid(img, ["...lll...", "..lsnsl..", "..lsssl..", "...lll..."], {"l": LEAF, "s": SPRIG, "n": NEWLEAF}, Vector2i(1, 1))
	_outline(img)
	var reach: int = 1 + f  # Hum lines either side, wider on the beat
	for i in reach:
		_px(img, 1 - i, 3, Color(SPRIG, 0.75))
		_px(img, 9 + i, 3, Color(SPRIG, 0.75))
	_px(img, 0, 1, Color(LEAF, 0.4 if f == 0 else 0.75))
	_px(img, 10, 5, Color(LEAF, 0.4 if f == 0 else 0.75))
