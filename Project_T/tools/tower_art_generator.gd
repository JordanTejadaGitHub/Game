extends SceneTree
# Generates the Warden (tower) spritesheets in assets/towers/ (64x64 frames, FRAMES per row) and
# their projectiles in assets/towers/projectiles/ (16x16 frames). Wardens are listed in
# documentation/tower_design.md. Each Warden is a golem in the pose of the original concept mock
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
	"...................eeee...eeddddeeeeee..........................",	"............................eeddeeee............................",
	"..............................eeee..............................",
]

# Idle loop: which pose each frame uses (0 = up, 1 = breathing down) and when the golem blinks.
const FRAME_POSE := [0, 0, 1, 1, 0, 0, 1, 1]
const BLINK_FRAME := 5
# Eye columns and the eye's top row in the up pose (3px tall). Mouth row is EYE_TOP + 4.
const EYES := [26, 32]
const EYE_TOP := 11

# Attack: wind up (squash, squint), release on RELEASE_FRAME (stretch), follow through, settle.
# Poses: 0 up, 1 down, 2 stretched (head 1px higher). POSE_DY is each pose's head offset.
const ATTACK_FRAMES := 6
const RELEASE_FRAME := 2
const ATTACK_POSE := [1, 1, 2, 2, 0, 0]
const ATTACK_LIFT := [2, 2, -3, -2, 0, 0]  # leaves / tendrils / cork: + droops, - flings up
const ATTACK_POWER := [0.3, 0.6, 1.0, 0.7, 0.3, 0.0]  # glow and gathering
const POSE_DY := [0, 1, -1]
# Every Warden, grouped by line (base, then branch A -> final, branch B -> final). One preview
# image per line is written to tools/previews/.
const LINES := {
	"starters": ["sprout", "thornwall", "bramble", "honeysuckle"],
	"sporeling": ["sporeling", "driftspore", "puffball", "bloomcap", "dreamshroom", "fairy_ring", "elf_circle"],
	"pebbling": ["pebbling", "mossback", "boulderback", "standing_stone", "moonstone", "cairn", "rockslide"],
	"bellflower": ["bellflower", "chime_stone", "lullaby_bell", "dreamcatcher", "great_dreamcatcher", "echo_hollow", "whispering_hollow"],
	"dewdrop": ["dewdrop", "rain_lily", "monsoon", "mistveil", "morning_fog", "frostfern", "hoarfrost"],
	"firefly_jar": ["firefly_jar", "stormcap", "thunderhead", "lanternmoth", "beacon", "sunpetal", "midsummer"],
	"rootling": ["rootling", "rootcurl", "long_way_home", "tangleroot", "snugroot", "rootlight", "starcave"],
	"acorn": ["acorn", "elder_stump", "grove_heart", "dewcatcher", "wellspring", "graftling", "grafted_elder"],
	"nestling": ["nestling", "wrens_nest", "starling_murmuration", "magpie_perch", "magpies_hoard", "hummingbird_bower", "jewelwing_court"],
	"whirligig": ["whirligig", "gust", "zephyr", "pinwheel", "windmill", "samara", "autumn_gale"],
	"memory": ["white_stag", "pond_keeper", "moon_moth"],
}
# How each Warden acts, and where from, in sprite pixels (0,0 = top-left): the projectile spawn
# point, or the centre of a pulse / fog, or where a bolt / beam / root starts. Kinds: projectile,
# pulse, cloud (leaves a cloud on path tiles), chain, beam, pull, hold. Wardens not listed
# (Thornwall, Dewcatcher, Wellspring) don't attack. Written to assets/towers/attacks.json.
const ATTACKS := {
	"sprout": {kind = "projectile", projectile = "spore", point = Vector2i(46, 9)},
	"bramble": {kind = "pulse", point = Vector2i(31, 46)},
	"sporeling": {kind = "projectile", projectile = "spore", point = Vector2i(46, 9)},
	"driftspore": {kind = "projectile", projectile = "spore", point = Vector2i(46, 9)},
	"puffball": {kind = "projectile", projectile = "spore", point = Vector2i(46, 9)},
	"bloomcap": {kind = "cloud", point = Vector2i(49, 14)},
	"dreamshroom": {kind = "cloud", point = Vector2i(49, 14)},
	"pebbling": {kind = "projectile", projectile = "pebble", point = Vector2i(46, 14)},
	"mossback": {kind = "projectile", projectile = "boulder", point = Vector2i(51, 8)},
	"boulderback": {kind = "projectile", projectile = "boulder", point = Vector2i(51, 8)},
	"chime_stone": {kind = "pulse", point = Vector2i(31, 46)},
	"lullaby_bell": {kind = "pulse", point = Vector2i(31, 46)},
	"dewdrop": {kind = "projectile", projectile = "dew_drop", point = Vector2i(30, 2)},
	"rain_lily": {kind = "projectile", projectile = "dew_drop", point = Vector2i(30, 2)},
	"monsoon": {kind = "pulse", point = Vector2i(31, 46)},
	"mistveil": {kind = "cloud", point = Vector2i(31, 46)},
	"morning_fog": {kind = "cloud", point = Vector2i(31, 46)},
	"firefly_jar": {kind = "projectile", projectile = "spark", point = Vector2i(31, 6)},
	"stormcap": {kind = "chain", point = Vector2i(40, 6)},
	"thunderhead": {kind = "chain", point = Vector2i(44, 5)},
	"lanternmoth": {kind = "projectile", projectile = "light_orb", point = Vector2i(31, 4)},
	"beacon": {kind = "pulse", point = Vector2i(31, 46)},
	"sunpetal": {kind = "beam", point = Vector2i(38, 12)},
	"rootling": {kind = "pulse", point = Vector2i(31, 46)},
	"rootcurl": {kind = "pull", point = Vector2i(60, 31)},
	"long_way_home": {kind = "pull", point = Vector2i(60, 31)},
	"tangleroot": {kind = "hold", point = Vector2i(31, 46)},
	"snugroot": {kind = "hold", point = Vector2i(31, 46)},
	"acorn": {kind = "pulse", point = Vector2i(31, 46)},
	"elder_stump": {kind = "pulse", point = Vector2i(31, 46)},
	"grove_heart": {kind = "pulse", point = Vector2i(31, 46)},
	# New Wardens. trap = plants on path tiles (sprite in projectiles/); light = lit path tiles;
	# copy = copies a neighbour's attack; swoop = a bird flies out and back (sprite in projectiles/);
	# sweep = a flock crosses a stretch of path; gust / spread / spin = wind around it. The White
	# Stag's aura is always on; its "attack" sheet is just the aura's pulse.
	"honeysuckle": {kind = "pulse", point = Vector2i(31, 46)},
	"fairy_ring": {kind = "trap", projectile = "fairy_ring", point = Vector2i(31, 50)},
	"elf_circle": {kind = "trap", projectile = "elf_circle", point = Vector2i(31, 50)},
	"standing_stone": {kind = "projectile", projectile = "sling_stone", point = Vector2i(36, 11)},
	"moonstone": {kind = "projectile", projectile = "moon_shard", point = Vector2i(36, 11)},
	"frostfern": {kind = "projectile", projectile = "frost_shard", point = Vector2i(45, 4)},
	"hoarfrost": {kind = "projectile", projectile = "frost_shard", point = Vector2i(45, 4)},
	"midsummer": {kind = "beam", point = Vector2i(38, 12)},
	"rootlight": {kind = "light", point = Vector2i(31, 46)},
	"starcave": {kind = "light", point = Vector2i(31, 46)},
	"graftling": {kind = "copy", point = Vector2i(31, 1)},
	"grafted_elder": {kind = "copy", point = Vector2i(31, 1)},
	"nestling": {kind = "swoop", projectile = "sparrow", point = Vector2i(44, 6)},
	"wrens_nest": {kind = "swoop", projectile = "wren", point = Vector2i(44, 8)},
	"starling_murmuration": {kind = "swoop", projectile = "starling_bird", point = Vector2i(46, 8)},  # 3 starlings hunt the 3 fastest
	"magpie_perch": {kind = "swoop", projectile = "magpie", point = Vector2i(50, 10)},
	"magpies_hoard": {kind = "swoop", projectile = "magpie", point = Vector2i(50, 10)},
	"whirligig": {kind = "gust", point = Vector2i(31, 46)},
	"gust": {kind = "spread", point = Vector2i(31, 46)},
	"zephyr": {kind = "spread", point = Vector2i(31, 46)},
	"pinwheel": {kind = "spin", point = Vector2i(31, 38)},
	"windmill": {kind = "spin", point = Vector2i(31, 38)},
	"pond_keeper": {kind = "pull", point = Vector2i(60, 30)},
	"moon_moth": {kind = "projectile", projectile = "moon_mote", point = Vector2i(31, 4)},
	"white_stag": {kind = "aura", point = Vector2i(31, 46)},  # its aura is always on; this is the visible pulse
	# Family review: Bellflower family and the Cairn, Hummingbird and Samara hidden branches. lob = an arc
	# over the maze; echo = repeats a nearby Reaction; multi = one bird, several quick pecks;
	# boomerang = a seed thrown down a line and back.
	"bellflower": {kind = "pulse", point = Vector2i(31, 46)},
	"dreamcatcher": {kind = "projectile", projectile = "dream_mote", point = Vector2i(46, 14)},
	"great_dreamcatcher": {kind = "projectile", projectile = "dream_mote", point = Vector2i(46, 14)},
	"echo_hollow": {kind = "echo", point = Vector2i(34, 29)},
	"whispering_hollow": {kind = "echo", point = Vector2i(34, 29)},
	"cairn": {kind = "lob", projectile = "lob_stone", point = Vector2i(12, 12)},
	"rockslide": {kind = "lob", projectile = "lob_stone", point = Vector2i(12, 6)},
	"hummingbird_bower": {kind = "multi", projectile = "hummingbird", point = Vector2i(51, 16)},
	"jewelwing_court": {kind = "multi", projectile = "hummingbird", point = Vector2i(51, 16)},
	"samara": {kind = "boomerang", projectile = "maple_seed", point = Vector2i(54, 14)},
	"autumn_gale": {kind = "boomerang", projectile = "autumn_seed", point = Vector2i(54, 14)},
}
const PREVIEWS := "res://tools/previews/"

var light := Vector3(0.45, -0.55, 0.7).normalized()
var poses: Array[Dictionary] = []

func _init() -> void:
	if _is_extension():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEWS))
	# Stretched pose: the head rows (template rows 0-12) move up 1px, the chin row is doubled.
	var stretch: Array = POSE_UP.slice(0, 13) + POSE_UP.slice(12)
	poses = [_parse(POSE_UP), _parse(POSE_DOWN), _parse(stretch, TOP - 1)]
	for line: String in LINES:
		var rows: Array = []
		for warden: String in LINES[line]:
			var idle := _make(warden, Callable(self, "_draw_" + warden))
			rows.append([idle, _make_attack(warden) if ATTACKS.has(warden) else null])
		_save_line_preview(rows, PREVIEWS + line + ".png")
	_save_attack_info()
	_make_ranks()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "projectiles/"))
	for p: String in ["spore", "pebble", "boulder", "dew_drop", "spark", "light_orb", "sling_stone", "moon_shard",
			"frost_shard", "sparrow", "wren", "magpie", "starling", "moon_mote", "fairy_ring", "elf_circle",
			"dream_mote", "lob_stone", "hummingbird", "maple_seed", "autumn_seed", "starling_bird"]:
		_make_projectile(p)
	_save_projectile_preview()
	quit()
# Generators that extend this one (ascended_art_generator.gd) return true to reuse its helpers
# without drawing the whole roster.
func _is_extension() -> bool:
	return false

func _idle_state(f: int) -> Dictionary:
	var pose: int = FRAME_POSE[f]
	return {f = f, n = FRAMES, attack = -1, pose = poses[pose], dy = POSE_DY[pose], sway = SWAY[f],
		blink = f == BLINK_FRAME, lift = 0, power = 0.0, wave = [0, -1, -2, -1, 0, 0, 0, 0][f]}

func _attack_state(a: int) -> Dictionary:
	var pose: int = ATTACK_POSE[a]
	return {f = a, n = ATTACK_FRAMES, attack = a, pose = poses[pose], dy = POSE_DY[pose], sway = 0,
		blink = a < RELEASE_FRAME, lift = ATTACK_LIFT[a], power = ATTACK_POWER[a], wave = ATTACK_LIFT[a] * 2}

func _make(tower_name: String, draw: Callable) -> Image:
	var sheet := Image.create_empty(S * FRAMES, S, false, Image.FORMAT_RGBA8)
	for f in FRAMES:
		var canvas := _layer()
		draw.call(canvas, _idle_state(f))
		sheet.blit_rect(canvas, Rect2i(0, 0, S, S), Vector2i(f * S, 0))
	sheet.save_png(OUT + tower_name + ".png")
	return sheet

# <name>_attack.png: the Warden's body in attack poses plus its attack effect on top.
func _make_attack(tower_name: String) -> Image:
	var sheet := Image.create_empty(S * ATTACK_FRAMES, S, false, Image.FORMAT_RGBA8)
	for a in ATTACK_FRAMES:
		var canvas := _layer()
		var st := _attack_state(a)
		call("_draw_" + tower_name, canvas, st)
		call("_attack_" + tower_name, canvas, st)
		sheet.blit_rect(canvas, Rect2i(0, 0, S, S), Vector2i(a * S, 0))
	sheet.save_png(OUT + tower_name + "_attack.png")
	return sheet

func _save_attack_info() -> void:
	var wardens := {}
	for warden: String in ATTACKS:
		var info: Dictionary = ATTACKS[warden].duplicate()
		info.point = [info.point.x, info.point.y]
		wardens[warden] = info
	var data := {frame_size = S, frames = ATTACK_FRAMES, release_frame = RELEASE_FRAME, wardens = wardens}
	var file := FileAccess.open(OUT + "attacks.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t") + "\n")

# One row per Warden on grass: its idle loop, a gap, then its attack. Scaled up for eyeballing.
func _save_line_preview(rows: Array, path: String) -> void:
	var pad := 6
	var gap := 24
	var width := pad + FRAMES * (S + pad) + gap + ATTACK_FRAMES * (S + pad)
	var preview := Image.create_empty(width, pad + rows.size() * (S + pad), false, Image.FORMAT_RGBA8)
	preview.fill(Color("#5fa844"))
	for i in rows.size():
		var y := pad + i * (S + pad)
		var idle: Image = rows[i][0]
		for f in FRAMES:
			preview.blend_rect(idle, Rect2i(f * S, 0, S, S), Vector2i(pad + f * (S + pad), y))
		if rows[i][1] != null:
			var attack: Image = rows[i][1]
			for a in ATTACK_FRAMES:
				preview.blend_rect(attack, Rect2i(a * S, 0, S, S), Vector2i(pad + FRAMES * (S + pad) + gap + a * (S + pad), y))
	preview.resize(preview.get_width() * 3, preview.get_height() * 3, Image.INTERPOLATE_NEAREST)
	preview.save_png(path)
# --- Template -----------------------------------------------------------------------------------

# Splits a template into base and figure: figure pixels are the ones enclosed by 'o' outlines,
# found by flooding in from the transparent area without crossing an outline.
func _parse(rows: Array, top: int = TOP) -> Dictionary:
	var grid: Array[String] = []
	grid.resize(S * S)
	grid.fill(".")
	for i in rows.size():
		var row: String = rows[i]
		for x in row.length():
			grid[(i + top) * S + x] = row[x]
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
		_warm_glow(canvas, Vector2(33, 32), Vector2(7.5, 6.5), f)  # every Warden shot glows warmly
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
	preview.save_png(PREVIEWS + "projectiles.png")

# A spinning faceted stone: an irregular polygon rotated a quarter turn per frame.
func _spinning_rock(canvas: Image, f: int, r: float, ramp: Array[Color], o: Color) -> void:
	var pts := PackedVector2Array()
	var radii := [1.0, 0.8, 0.95, 0.75, 1.0, 0.85]
	for k in 6:
		var a := k * TAU / 6.0 + f * TAU / 24.0
		pts.append(Vector2(32, 32) + Vector2.from_angle(a) * r * radii[k])
	_rock(canvas, pts, ramp, o)

func _proj_spore(canvas: Image, f: int) -> void:
	var puff := _ramp(["#9ab04a", "#e0ec98", "#fff6c8", "#ffffff"])  # warm, sunlit spores
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

# Each line's waystone: the mock's slab recoloured per theme, with the gap where the mock's figure
# stood filled back in, then the theme's surface (_decor_<theme>). `lush` dresses it up for final
# forms. Returns the slab's top-face mask.
const THEMES := {
	"moss": ["#aaa4bc", "#6a6484", "#34304c"],
	"soil": ["#a8988a", "#6e5a4a", "#3a2e2a"],
	"bramble": ["#9a9aa8", "#5e5e70", "#2e2e3c"],
	"fairy_ring": ["#bcb0cc", "#74628e", "#3c2e54"],
	"cobble": ["#b4b8cc", "#6a6e90", "#34364e"],
	"pond": ["#9aaccc", "#4a6090", "#22305a"],
	"night": ["#6a7098", "#3a3e66", "#1c1e38"],
	"meadow": ["#aaa4bc", "#6a6484", "#34304c"],
	"stump": ["#c8a070", "#7a5234", "#4a3020"],
	"leaf_litter": ["#b0a498", "#6e6258", "#3a322e"],
	"nest": ["#a89878", "#6a5a44", "#3a2e22"],
	"windswept": ["#a8b0a0", "#646e60", "#343a30"],
	"memory": ["#d0cce0", "#8a86a8", "#4a4668"],
	"bellflower": ["#b8b0c8", "#6e6488", "#383050"],
}

func _draw_waystone(canvas: Image, st: Dictionary, theme: String = "moss", lush: bool = false) -> Image:
	var pose: Dictionary = st.pose
	var pal: Array = THEMES[theme]
	var stone := {a = Color(pal[0]), d = Color(pal[1]), e = Color(pal[2])}
	var top := _layer()
	var side := _layer()
	for i in S * S:
		var ch: String = pose.grid[i]
		if ch == ".":
			continue
		var x := i % S
		var y := i / S
		# The top face lies above the slab's two front edges (2:1 slopes down to the front corner).
		var on_top := y <= 40 + mini(x, 63 - x) / 2
		if pose.outside[i] == 1:
			canvas.set_pixel(x, y, stone[ch])
			if ch == "a" and on_top:
				top.set_pixel(x, y, Color.WHITE)
			else:
				side.set_pixel(x, y, Color.WHITE)
			continue
		# Under the figure: the top face, bounded by the slab's back edges.
		var xl := 2 * (40 - y) - 1
		var xr := 64 - 2 * (40 - y) + 1
		if y > 40 or (x > xl + 1 and x < xr - 1):
			canvas.set_pixel(x, y, stone.a)
			top.set_pixel(x, y, Color.WHITE)
		elif x >= xl and x <= xr:
			canvas.set_pixel(x, y, stone.d)
	for c: Vector2i in [Vector2i(28, 34), Vector2i(29, 34), Vector2i(36, 30), Vector2i(40, 45), Vector2i(41, 45), Vector2i(24, 44)]:
		_px(canvas, c.x, c.y, stone.d)
	call("_decor_" + theme, canvas, top, side, st, lush)
	return top

func _on(mask: Image, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < S and y < S and mask.get_pixel(x, y).a > 0.0

# Soft blobs on the top face: lighter towards the top, dithered at the edges.
func _patches(canvas: Image, top: Image, blobs: Array, ramp: Array[Color]) -> void:
	for blob: Rect2 in blobs:
		for y in range(maxi(0, floori(blob.position.y - blob.size.y)), mini(S, ceili(blob.position.y + blob.size.y) + 1)):
			for x in range(maxi(0, floori(blob.position.x - blob.size.x)), mini(S, ceili(blob.position.x + blob.size.x) + 1)):
				if not _on(top, x, y):
					continue
				var d := (Vector2(x + 0.5, y + 0.5) - blob.position) / blob.size
				var q := d.length()
				if q > 1.0 or (q > 0.8 and (x + y) % 2 == 0):
					continue
				canvas.set_pixel(x, y, ramp[2] if (q < 0.5 and d.y < 0.0) else (ramp[0] if q > 0.8 else ramp[1]))

const MOSS_BLOBS := [Rect2(11, 40, 9, 3.5), Rect2(51, 41, 8, 3), Rect2(30, 51, 10, 3), Rect2(42, 30, 6, 2.5), Rect2(21, 31, 5, 2)]
# Spots on the top face that stay visible around the seated figure.
const OPEN_SPOTS := [Vector2i(6, 40), Vector2i(12, 44), Vector2i(16, 37), Vector2i(50, 40), Vector2i(56, 43), Vector2i(46, 48),
	Vector2i(22, 50), Vector2i(35, 52), Vector2i(9, 43), Vector2i(59, 41), Vector2i(40, 51), Vector2i(28, 53), Vector2i(3, 40)]

func _decor_moss(canvas: Image, top: Image, _side: Image, _st: Dictionary, _lush: bool) -> void:
	_patches(canvas, top, MOSS_BLOBS, _ramp(["#3f7a3e", "#5a9a48", "#7cbc5a"]))

# Tilled soil with furrows and seedlings.
func _decor_soil(canvas: Image, top: Image, _side: Image, _st: Dictionary, lush: bool) -> void:
	for y in S:
		for x in S:
			if not _on(top, x, y):
				continue
			var furrow := int(floor(x * 0.5 + y)) % 4 == 0
			var clod := (x * 37 + y * 91) % 11 == 0
			canvas.set_pixel(x, y, Color("#5a3a24") if furrow else (Color("#9a6e48") if clod else Color("#7a5234")))
	var seedlings: Array = OPEN_SPOTS.slice(0, 9 if lush else 6)
	for p: Vector2i in seedlings:
		if _on(top, p.x, p.y):
			_px(canvas, p.x, p.y, Color("#5a9a3c"))
			_px(canvas, p.x - 1, p.y - 1, Color("#8ad060"))
			_px(canvas, p.x + 1, p.y - 1, Color("#8ad060"))

# Dark stone overgrown by bramble vines that creep over the edges; blooms when lush.
func _decor_bramble(canvas: Image, top: Image, _side: Image, _st: Dictionary, lush: bool) -> void:
	_patches(canvas, top, MOSS_BLOBS, _ramp(["#2a5232", "#3c7040", "#58964a"]))
	var vines := [[Vector2(1, 40), Vector2(6, 37), Vector2(11, 40), Vector2(16, 36)], [Vector2(62, 41), Vector2(57, 38), Vector2(53, 41), Vector2(48, 38)],
		[Vector2(20, 51), Vector2(27, 49), Vector2(34, 53), Vector2(42, 50)], [Vector2(6, 42), Vector2(7, 47), Vector2(5, 51)],
		[Vector2(57, 44), Vector2(58, 48), Vector2(56, 52)], [Vector2(31, 56), Vector2(32, 61)]]
	for v: Array in vines:
		_line(canvas, v, Color("#2e5a30"))
		for p: Vector2 in v:
			_px(canvas, int(p.x) + 1, int(p.y) - 1, Color("#58964a"))
			_px(canvas, int(p.x) - 1, int(p.y), Color("#d8c090"))
	if lush:
		for p: Vector2i in [Vector2i(6, 37), Vector2i(57, 38), Vector2i(27, 49), Vector2i(42, 50), Vector2i(7, 47)]:
			_flower(canvas, p, Color("#f4a0c0"), Color("#ffd24a"))

# Lilac stone with a fairy ring of little mushrooms and spore dust; the ring glows when lush.
func _decor_fairy_ring(canvas: Image, top: Image, _side: Image, st: Dictionary, lush: bool) -> void:
	_patches(canvas, top, MOSS_BLOBS, _ramp(["#4a7a4e", "#6a9a5a", "#8cbc72"]))
	var cap := Color("#7ff0e0") if lush else Color("#d070b0")
	for k in 16:
		var a := k * TAU / 16.0
		var p := Vector2i((Vector2(31.5, 44) + Vector2(cos(a) * 27.0, sin(a) * 11.0)).round())
		if not _on(top, p.x, p.y) or not _on(top, p.x, p.y - 2):
			continue
		_px(canvas, p.x, p.y, Color("#f0e4d8"))
		for dx in [-1, 0, 1]:
			_px(canvas, p.x + dx, p.y - 1, cap)
		_px(canvas, p.x, p.y - 2, cap.lightened(0.3))
	for k in 5:
		var p: Vector2i = OPEN_SPOTS[(k * 3 + st.f) % OPEN_SPOTS.size()]
		if _on(top, p.x, p.y - 3):
			_px(canvas, p.x, p.y - 3, Color("#f7c8fa"))

# Cobblestones with mossy mortar.
func _decor_cobble(canvas: Image, top: Image, _side: Image, _st: Dictionary, lush: bool) -> void:
	var shades := [Color("#c4c8dc"), Color("#b0b4cc"), Color("#9ea4c0")]
	for y in S:
		for x in S:
			if not _on(top, x, y):
				continue
			var u := x * 0.5 + y
			var v := x * 0.5 - y
			if fposmod(u, 5.0) < 1.0 or fposmod(v, 5.0) < 1.0:
				var mossy := (x * 13 + y * 7) % (3 if lush else 5) == 0
				canvas.set_pixel(x, y, Color("#5a9a48") if mossy else Color("#7e82a0"))
			else:
				canvas.set_pixel(x, y, shades[absi(int(floor(u / 5.0)) * 7 + int(floor(v / 5.0)) * 3) % 3])

# Stone with rain pools (a ripple travels across them); a lily flowers on one when lush.
func _decor_pond(canvas: Image, top: Image, _side: Image, st: Dictionary, lush: bool) -> void:
	_patches(canvas, top, [Rect2(42, 30, 6, 2.5), Rect2(21, 31, 5, 2)], _ramp(["#3f7a3e", "#5a9a48", "#7cbc5a"]))
	var ripple := float(st.f % 4) / 4.0
	for pool: Rect2 in [Rect2(12, 42, 9, 3.5), Rect2(53, 42, 7, 3), Rect2(38, 51, 7, 2.5)]:
		for y in S:
			for x in S:
				if not _on(top, x, y):
					continue
				var d := (Vector2(x + 0.5, y + 0.5) - pool.position) / pool.size
				var q := d.length()
				if q > 1.25:
					continue
				var col := Color("#7a8cb0")
				if q <= 1.0:
					col = Color("#6ab0e8") if d.y < -0.2 else Color("#4a8ed0")
					if absf(q - ripple) < 0.12:
						col = Color("#bfe8ff")
				canvas.set_pixel(x, y, col)
		_px(canvas, int(pool.position.x) - 2, int(pool.position.y) - 1, Color.WHITE)
	if lush:
		_flower(canvas, Vector2i(13, 42), Color("#f4c0dc"), Color("#ffd24a"))

# Night-blue stone with glowing moss and resting fireflies that blink.
func _decor_night(canvas: Image, top: Image, _side: Image, st: Dictionary, lush: bool) -> void:
	_patches(canvas, top, MOSS_BLOBS, _ramp(["#2e6a5a", "#4aa088", "#8af0c8"]))
	var n := 7 if lush else 4
	for k in n:
		var p: Vector2i = OPEN_SPOTS[(k * 5) % OPEN_SPOTS.size()]
		if _on(top, p.x, p.y) and (st.f + k) % 3 != 0:
			_glow_dot(canvas, p, Color("#fff27a"), Color("#6a8a70"))

# Meadow grass with wildflowers.
func _decor_meadow(canvas: Image, top: Image, _side: Image, _st: Dictionary, lush: bool) -> void:
	for y in S:
		for x in S:
			if not _on(top, x, y):
				continue
			var h := (x * 29 + y * 53) % 9
			canvas.set_pixel(x, y, Color("#8ad060") if h == 0 else (Color("#3f7a3e") if h == 4 else Color("#5a9a48")))
	var flowers: Array = OPEN_SPOTS.slice(0, 8 if lush else 5)
	for i in flowers.size():
		var p: Vector2i = flowers[i]
		if _on(top, p.x, p.y):
			_flower(canvas, p, Color("#ffe070") if i % 2 == 0 else Color("#fff4f0"), Color("#d89a20"))

# A tree stump: growth rings on top, bark grain down the sides.
func _decor_stump(canvas: Image, top: Image, side: Image, _st: Dictionary, lush: bool) -> void:
	for y in S:
		for x in S:
			if _on(top, x, y):
				var q := Vector2((x + 0.5 - 31.5) / 2.0, y + 0.5 - 44.0).length()
				var col := Color("#d8b080") if int(q) % 4 < 2 else Color("#c8a070")
				if int(q) % 4 == 0:
					col = Color("#a07850")
				if q < 1.5:
					col = Color("#8a6040")
				canvas.set_pixel(x, y, col)
			elif _on(side, x, y) and x % 3 == 0:
				canvas.set_pixel(x, y, canvas.get_pixel(x, y).darkened(0.25))
	_line(canvas, [Vector2(44, 39), Vector2(52, 41), Vector2(58, 40)], Color("#8a6040"), top)
	if lush:
		_patches(canvas, top, [Rect2(11, 40, 7, 3), Rect2(52, 41, 6, 2.5)], _ramp(["#3f7a3e", "#5a9a48", "#7cbc5a"]))

# Warm stone under fallen autumn leaves and acorn caps.
func _decor_leaf_litter(canvas: Image, top: Image, _side: Image, _st: Dictionary, lush: bool) -> void:
	_patches(canvas, top, [Rect2(11, 40, 7, 3), Rect2(30, 51, 8, 2.5)], _ramp(["#3f7a3e", "#5a9a48", "#7cbc5a"]))
	var colors := [Color("#e08a3a"), Color("#c84a3a"), Color("#e8c050"), Color("#b8642a")]
	var spots: Array = OPEN_SPOTS if lush else OPEN_SPOTS.slice(0, 9)
	for i in spots.size():
		var p: Vector2i = spots[i]
		if not _on(top, p.x, p.y):
			continue
		if i % 4 == 3:
			_px(canvas, p.x, p.y, Color("#6a4828"))
			_px(canvas, p.x + 1, p.y, Color("#6a4828"))
			_px(canvas, p.x + 1, p.y - 1, Color("#4a3018"))
		else:
			var col: Color = colors[i % colors.size()]
			for d: Vector2i in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i(0, -1), Vector2i(1, -1)]:
				_px(canvas, p.x + d.x, p.y + d.y, col)
			_px(canvas, p.x + 2, p.y - 2, col.darkened(0.3))

func _flower(canvas: Image, p: Vector2i, petal: Color, centre: Color) -> void:
	for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		_px(canvas, p.x + d.x, p.y + d.y, petal)
	_px(canvas, p.x, p.y, centre)

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

# Motes drifting up and fading; one per phase offset. Idle only: attacks have their own effects.
func _motes(canvas: Image, st: Dictionary, xs: Array, from_y: float, rise: float, colors: Array) -> void:
	if st.attack >= 0:
		return
	for k in xs.size():
		var t: float = float((st.f + k * 3) % st.n) / st.n
		var x: int = xs[k] + roundi(sin(t * TAU) * 1.5)
		_px(canvas, x, roundi(from_y - t * rise), colors[0] if t < 0.6 else colors[1])

# --- Warden golems ----------------------------------------------------------------------------
# Every Warden is a golem in the mock's seated pose (the Sporeling is the mock itself), themed
# after its line in tower_design.md, dozing on the mossy waystone.

const LEAF := ["#3f7a3e", "#6ab04a", "#9ad86a"]
const SWAY := [0, 1, 1, 0, 0, -1, -1, 0]

# Recoloured mock face: blink (or always asleep), optional glowing eyes and rosy cheeks.
func _golem_face(canvas: Image, st: Dictionary, fig: Dictionary, eye: Color = Color(0, 0, 0, 0),
		blush: bool = true, asleep: bool = false) -> void:
	var dy: int = st.dy
	if blush:
		for bx: int in [24, 25, 34, 35]:
			_px(canvas, bx, EYE_TOP + 3 + dy, BLUSH)
	var closed: bool = asleep or st.blink
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
func _draw_sprout(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var sway: int = st.sway
	var fig := _pal("#1e3a24", "#cce898", "#a4d070", "#7aa850")
	var soil := Color("#7a5234")
	_draw_waystone(canvas, st, "soil")
	var mask := _draw_template_figure(canvas, st.pose, fig)
	var stem := _layer()
	_stroke(stem, [Vector2(30.5, 8 + dy), Vector2(30.5, 3 + dy)], 1.5, Color("#5a9a3c"))
	_stamp(canvas, stem, fig.o)
	_leaf(canvas, Vector2(30, 4 + dy), Vector2(19 + sway, 1 + dy + st.lift), 3.5, _ramp(LEAF), fig.o)
	_leaf(canvas, Vector2(31, 4 + dy), Vector2(43 + sway, 0 + dy + st.lift), 4.0, _ramp(LEAF), fig.o)
	# Seed-coat speckles and soil clinging to the legs.
	_skin_px(canvas, mask, fig.o, [Vector2i(33, 22 + dy), Vector2i(37, 26 + dy), Vector2i(26, 27 + dy), Vector2i(31, 33)], fig.c)
	_skin_px(canvas, mask, fig.o, [Vector2i(12, 41), Vector2i(13, 41), Vector2i(14, 42), Vector2i(20, 45), Vector2i(21, 45),
		Vector2i(36, 47), Vector2i(37, 47), Vector2i(38, 46), Vector2i(48, 41), Vector2i(49, 41)], soil)
	_golem_face(canvas, st, fig)
	_motes(canvas, st, [15, 46, 38], 20, 16, [Color("#eefcd0"), Color("#a4d070")])

# Thornwall: a bramble golem that never wakes up. Leafy body, a thorny vine wrapped round it,
# berries, blossoms, and bramble tufts on the stone.
func _draw_thornwall(canvas: Image, st: Dictionary) -> void:
	_bramble_body(canvas, st, false)

# Bramble (Thornwall's growth): the same hedge in full bloom, wild roses all over, awake and content,
# petals drifting off it.
func _draw_bramble(canvas: Image, st: Dictionary) -> void:
	_bramble_body(canvas, st, true)

func _bramble_body(canvas: Image, st: Dictionary, bloom: bool) -> void:
	var dy: int = st.dy
	var fig := _pal("#14241a", "#7cbc5a", "#58964a", "#3c7040")
	var bush := _ramp(["#2a5232", "#3c7040", "#58964a", "#7cbc5a"])
	var thorn := Color("#d8c090")
	_draw_waystone(canvas, st, "bramble", bloom)
	for tuft: Rect2 in [Rect2(8, 42, 5, 3.5), Rect2(56, 42, 5, 3.5)]:
		var t := _layer()
		_ellipse(t, tuft.position, tuft.size, bush)
		_stamp(canvas, t, fig.o)
	var mask := _draw_template_figure(canvas, st.pose, fig)
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
		_skin_px(canvas, mask, fig.o, [b], Color("#f0a0c8") if (st.f / 2) % 3 == i else Color("#c8387a"))
	for bl: Vector2i in [Vector2i(36, 8 + dy), Vector2i(23, 24 + dy), Vector2i(42, 31)]:
		_skin_px(canvas, mask, fig.o, [bl + Vector2i.LEFT, bl + Vector2i.RIGHT, bl + Vector2i.UP, bl + Vector2i.DOWN], Color("#fff4f0"))
		_skin_px(canvas, mask, fig.o, [bl], Color("#ffd24a"))
	if bloom:
		for r: Vector2i in [Vector2i(20, 29), Vector2i(33, 22 + dy), Vector2i(40, 38), Vector2i(26, 36), Vector2i(29, 7 + dy),
				Vector2i(15, 38), Vector2i(50, 33), Vector2i(44, 24 + dy)]:
			_skin_px(canvas, mask, fig.o, [r + Vector2i.LEFT, r + Vector2i.RIGHT, r + Vector2i.UP, r + Vector2i.DOWN, r + Vector2i(1, 1)], Color("#f4a0c0"))
			_skin_px(canvas, mask, fig.o, [r], Color("#ffd24a"))
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), bloom, true)
	var t: float = float(st.f) / st.n
	_px(canvas, 50 + roundi(sin(t * TAU) * 2), 14 + roundi(t * 10), Color("#f4a0c0") if bloom else Color("#7cbc5a"))
	if bloom:
		_px(canvas, 12 - roundi(sin(t * TAU) * 2), 10 + roundi(t * 12), Color("#f4a0c0"))

# Sporeling: the original concept art, releasing drowsy spores.
func _draw_sporeling(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal("#17174d", "#ed9df2", "#de73e5", "#ba41d9")
	_draw_waystone(canvas, st, "fairy_ring")
	_draw_template_figure(canvas, st.pose, fig)
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), false)
	_motes(canvas, st, [21, 42, 34], 16, 16, [Color("#f7c8fa"), Color("#de73e5")])

# Pebbling: a mossy stone golem with boulder shoulders, a moss cap with a flower, cracks and
# pebbles at its feet.
func _draw_pebbling(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal("#1c1c36", "#c4c9e2", "#979dc2", "#686d9a")
	var stone := _ramp(["#686d9a", "#979dc2", "#c4c9e2", "#e4e7f4"])
	var moss := _ramp(["#3f7a3e", "#5a9a48", "#7cbc5a", "#a8dc7a"])
	_draw_waystone(canvas, st, "cobble")
	_rock(canvas, PackedVector2Array([Vector2(4, 43), Vector2(6, 40), Vector2(10, 40), Vector2(11, 43), Vector2(8, 45)]), stone, fig.o)
	_rock(canvas, PackedVector2Array([Vector2(53, 45), Vector2(55, 42), Vector2(58, 42), Vector2(59, 45), Vector2(56, 47)]), stone, fig.o)
	var mask := _draw_template_figure(canvas, st.pose, fig)
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
	_golem_face(canvas, st, fig)

# Dewdrop: a water golem with a droplet tip on its head, a glossy body with bubbles rising
# inside, a drip falling from its hand and lily pads on the stone.
func _draw_dewdrop(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var sway: int = st.sway
	var fig := _pal("#16305e", "#9ad4ff", "#5aa8ec", "#3a78c8")
	var shine := Color("#e8faff")
	_draw_waystone(canvas, st, "pond")
	for pad: Rect2 in [Rect2(27, 50, 6.5, 3)]:
		var p := _layer()
		_ellipse(p, pad.position, pad.size, _ramp(LEAF))
		_stamp(canvas, p, Color("#1e3a24"))
	# Droplet tip behind the head, so only the point shows above it.
	var tip := _layer()
	_flame(tip, Vector2(30.5, 11 + dy), 6.0, 13.0 - st.lift * 1.5, sway, fig.a)
	_stamp(canvas, tip, fig.o)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	# Gloss streaks.
	_skin_px(canvas, mask, fig.o, [Vector2i(24, 7 + dy), Vector2i(25, 7 + dy), Vector2i(24, 8 + dy), Vector2i(29, 1 + dy),
		Vector2i(22, 25 + dy), Vector2i(22, 26 + dy), Vector2i(21, 27 + dy), Vector2i(21, 28 + dy), Vector2i(21, 29 + dy),
		Vector2i(43, 28), Vector2i(43, 29)], shine)
	# Bubbles rising inside the body.
	for k in 3:
		var t: float = float((st.f + k * 3) % st.n) / st.n
		var b := Vector2i([27, 34, 38][k], roundi(42 - t * 18))
		_skin_px(canvas, mask, fig.o, [b, b + Vector2i.RIGHT], shine)
	# A drip falling from the hand.
	var drip := _layer()
	_flat_ellipse(drip, Vector2(44, 41 + st.f * 1.2), Vector2(1.4, 1.8), fig.a)
	_stamp(canvas, drip, fig.o)
	_golem_face(canvas, st, fig)

# Firefly Jar: a glass golem with fireflies drifting inside it, a cork hat with a sprout,
# string tied round its neck and eyes lit like fireflies.
func _draw_firefly_jar(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var sway: int = st.sway
	var fig := _pal("#1a2230", "#4e7482", "#3e6270", "#2e4a58")
	var cork := _ramp(["#6a4428", "#8a5a3a", "#b07a4a", "#d09a6a"])
	var bright: bool = st.f % 4 < 2 or st.power > 0.5
	var top := _draw_waystone(canvas, st, "night")
	for y in S:
		for x in S:
			var q := ((Vector2(x + 0.5, y + 0.5) - Vector2(31, 45)) / Vector2(24, 8)).length()
			if bright and top.get_pixel(x, y).a > 0.0 and q < 1.0 and q > 0.7 and (x + y) % 2 == 0:
				canvas.set_pixel(x, y, Color("#d8d890"))
	var mask := _draw_template_figure(canvas, st.pose, fig)
	# Glass highlights down the left side and on the head.
	for y in range(24, 40):
		_skin_px(canvas, mask, fig.o, [Vector2i(21, y + dy)], Color("#a8d0d8"))
	_skin_px(canvas, mask, fig.o, [Vector2i(24, 7 + dy), Vector2i(24, 8 + dy), Vector2i(25, 7 + dy), Vector2i(22, 24 + dy)], Color("#d8f4f4"))
	# Fireflies.
	for k in 6:
		var home: Vector2 = [Vector2(27, 25), Vector2(35, 27), Vector2(30, 33), Vector2(24, 36), Vector2(37, 22), Vector2(33, 8)][k]
		var a: float = float(st.f) / st.n * TAU + k * 1.3
		var drift := home + Vector2(cos(a) * 2.0, sin(a * 2.0) * 1.5)
		var p := Vector2i(drift.lerp(Vector2(31, 16), st.power * 0.6).round()) + Vector2i(0, dy)
		if (st.f + k) % 4 == 0 and st.power < 0.5:
			_skin_px(canvas, mask, fig.o, [p], Color("#8aa860"))
		elif mask.get_pixelv(p).a > 0.0:
			_glow_dot(canvas, p, Color("#fff27a"), Color("#a8c868"), mask)
	_neck_string(canvas, mask, st, fig.o)
	# Cork hat and its sprout (it pops up when the jar fires).
	var cy: int = dy + maxi(-2, mini(0, st.lift))
	var lid := _layer()
	_round_rect(lid, Rect2i(24, 1 + cy, 14, 7), 2, cork[1])
	for y in S:
		for x in S:
			if lid.get_pixel(x, y).a > 0.0:
				lid.set_pixel(x, y, cork[2] if y < 3 + cy else (cork[0] if x > 34 else cork[1]))
	_stamp(canvas, lid, fig.o)
	_px(canvas, 27, 4 + cy, cork[0])
	_px(canvas, 31, 5 + cy, cork[3])
	_leaf(canvas, Vector2(37, 3 + cy), Vector2(45 + sway, cy - dy), 2.8, _ramp(LEAF), fig.o)
	_golem_face(canvas, st, fig, Color("#fff27a"), false)

# Rootling: a bark golem with roots spreading from its feet into the stone, root tendrils
# curling from its shoulders (one waves), a knot hole and a leafy sprout on its head.
func _draw_rootling(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var sway: int = st.sway
	var fig := _pal("#24160e", "#c09268", "#9a6e48", "#7a5234")
	_draw_waystone(canvas, st, "stump")
	var roots := _layer()
	for root: Array in [[Vector2(16, 44), Vector2(10, 46), Vector2(5, 44)], [Vector2(27, 47), Vector2(25, 53)],
			[Vector2(40, 48), Vector2(46, 52), Vector2(53, 50)], [Vector2(52, 42), Vector2(57, 41), Vector2(61, 42)]]:
		_stroke(roots, root, 1.6, fig.b)
	_stamp(canvas, roots, fig.o)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	for g: Array in [[Vector2(24, 26 + dy), Vector2(23, 31 + dy), Vector2(24, 35)], [Vector2(29, 23 + dy), Vector2(30, 29 + dy)],
			[Vector2(36, 28 + dy), Vector2(37, 34)], [Vector2(27, 7 + dy), Vector2(26, 9 + dy)], [Vector2(15, 40), Vector2(18, 42)]]:
		_line(canvas, g, fig.c, mask)
	var knot := _layer()
	_flat_ellipse(knot, Vector2(33, 33), Vector2(1.6, 2.2), fig.c)
	_stamp(canvas, knot, fig.o)
	_leaf(canvas, Vector2(30, 5 + dy), Vector2(21 + sway, 1 + dy), 3.2, _ramp(LEAF), fig.o)
	_leaf(canvas, Vector2(31, 5 + dy), Vector2(41 + sway, 0 + dy), 3.6, _ramp(LEAF), fig.o)
	var wave: int = st.wave
	var tendrils := _layer()
	_stroke(tendrils, [Vector2(21, 23 + dy), Vector2(17, 19 + dy), Vector2(16, 14 + dy + wave)], 1.3, fig.b)
	_stroke(tendrils, [Vector2(42, 23 + dy), Vector2(47, 21 + dy), Vector2(49, 17 + dy + st.lift * 2)], 1.3, fig.b)
	_stamp(canvas, tendrils, fig.o)
	_golem_face(canvas, st, fig)

# Acorn: a nut golem wearing a scaly acorn cap with a stem and leaf, little acorns beside it.
func _draw_acorn(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var sway: int = st.sway
	var fig := _pal("#2a1a10", "#f0c080", "#d49c54", "#b07a3a")
	var shell := _ramp(["#4a3018", "#6a4828", "#8a6440", "#a88258"])
	_draw_waystone(canvas, st, "leaf_litter")
	var mask := _draw_template_figure(canvas, st.pose, fig)
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
	_leaf(canvas, Vector2(32, 2 + dy), Vector2(41 + sway, st.lift), 3.0, _ramp(LEAF), fig.o)
	var cap := _layer()
	_ellipse(cap, Vector2(30.5, 10 + dy), Vector2(12.5, 7), shell, 10.5 + dy)
	for y in S:
		for x in S:
			if cap.get_pixel(x, y).a > 0.0 and (x + 2 * y) % 4 == 0 and y < 9 + dy:
				cap.set_pixel(x, y, shell[0])
	_stamp(canvas, cap, fig.o)
	_golem_face(canvas, st, fig)

func _round_rect(layer: Image, rect: Rect2i, r: int, color: Color) -> void:
	for y in range(maxi(0, rect.position.y), mini(S, rect.end.y)):
		for x in range(maxi(0, rect.position.x), mini(S, rect.end.x)):
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

# --- Attack effects ---------------------------------------------------------------------------
# Drawn over the Warden's attack-pose body. st.attack is the frame (RELEASE_FRAME = the shot).

# Warden attacks glow warmly: light pushing back the cold, dark nightmares (story.md).
const GLOW_INNER := Color("#ffe8a0")
const GLOW_OUTER := Color("#ffc860")

# Warm light spilling round an attack or projectile, dithered so it reads as a glow. It only lights
# empty pixels, so it never paints over the Warden or its base: draw it after the effect itself.
func _warm_glow(canvas: Image, c: Vector2, r: Vector2, phase: int = 0) -> void:
	for y in range(maxi(0, floori(c.y - r.y)), mini(S, ceili(c.y + r.y) + 1)):
		for x in range(maxi(0, floori(c.x - r.x)), mini(S, ceili(c.x + r.x) + 1)):
			if canvas.get_pixel(x, y).a > 0.0:
				continue
			var q := ((Vector2(x + 0.5, y + 0.5) - c) / r).length()
			if q < 0.6 and (x + y + phase) % 2 == 0:
				canvas.set_pixel(x, y, GLOW_INNER)
			elif q < 1.0 and (x + 2 * y + phase) % 4 == 0:
				canvas.set_pixel(x, y, GLOW_OUTER)

# A puff that bursts on release, then scatters into dots and fades.
func _burst(canvas: Image, c: Vector2, a: int, light_col: Color, dark_col: Color, o: Color) -> void:
	if a == RELEASE_FRAME:
		var puff := _layer()
		_flat_ellipse(puff, c, Vector2(4, 3.4), light_col)
		_flat_ellipse(puff, c + Vector2(-3.5, 2), Vector2(2.4, 2.2), light_col)
		_flat_ellipse(puff, c + Vector2(3.5, 2), Vector2(2.6, 2.4), light_col)
		for y in S:
			for x in S:
				if puff.get_pixel(x, y).a > 0.0 and y > c.y + 2:
					puff.set_pixel(x, y, dark_col)
		_stamp(canvas, puff, o)
		for k in 4:
			var d := Vector2.from_angle(k * TAU / 4.0 + 0.4) * 8.0
			_px(canvas, roundi(c.x + d.x), roundi(c.y + d.y), light_col)
		_warm_glow(canvas, c + Vector2(0, 1), Vector2(9, 7.5))
	elif a == RELEASE_FRAME + 1 or a == RELEASE_FRAME + 2:
		var radius := 8.0 if a == RELEASE_FRAME + 1 else 11.0
		for k in 6:
			var d := Vector2.from_angle(k * TAU / 6.0 + 0.2) * radius
			_px(canvas, roundi(c.x + d.x), roundi(c.y + d.y), light_col if a == RELEASE_FRAME + 1 else dark_col)
		if a == RELEASE_FRAME + 1:
			var core := _layer()
			_flat_ellipse(core, c, Vector2(2.5, 2.2), light_col)
			_stamp(canvas, core, o)
			_warm_glow(canvas, c, Vector2(6, 5), 1)

# A 1px ellipse ring on the ground; dithered when fading.
func _ring(canvas: Image, c: Vector2, r: Vector2, color: Color, fading: bool) -> void:
	for y in S:
		for x in S:
			var q := ((Vector2(x + 0.5, y + 0.5) - c) / r).length()
			if absf(q - 1.0) * minf(r.x, r.y) < 0.55 and not (fading and (x + y) % 2 == 0):
				canvas.set_pixel(x, y, color)

func _pulse(canvas: Image, st: Dictionary, color: Color) -> void:
	var c := Vector2(ATTACKS["rootling"].point)
	var k: int = st.attack - RELEASE_FRAME
	if k >= 0 and k < 3:
		var r := Vector2(12 + k * 8, 4.5 + k * 3)
		_ring(canvas, c, r * 0.82, GLOW_INNER, true)  # warm light just inside the wave
		_ring(canvas, c, r, color, k == 2)

func _sparkle(canvas: Image, p: Vector2i, color: Color) -> void:
	for d: Vector2i in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		_px(canvas, p.x + d.x, p.y + d.y, color)

# Opens the mouth into a small "o" (release and follow-through) and trails spores from it.
func _blow(canvas: Image, st: Dictionary, skin: Color, o: Color, spore: Color) -> void:
	var a: int = st.attack
	var my: int = EYE_TOP + 4 + st.dy
	if a == RELEASE_FRAME or a == RELEASE_FRAME + 1:
		_px(canvas, 27, my, skin)
		_px(canvas, 31, my, skin)
		for x in range(28, 31):
			_px(canvas, x, my + 1, o)
	if a == RELEASE_FRAME:
		for p: Vector2i in [Vector2i(34, my - 1), Vector2i(37, my - 2), Vector2i(40, my - 4)]:
			_px(canvas, p.x, p.y, spore)

func _attack_sprout(canvas: Image, st: Dictionary) -> void:
	_blow(canvas, st, Color("#cce898"), Color("#1e3a24"), Color("#eefcd0"))
	_burst(canvas, Vector2(ATTACKS["sprout"].point), st.attack, Color("#eefcd0"), Color("#a4d070"), Color("#1e3a24"))

func _attack_sporeling(canvas: Image, st: Dictionary) -> void:
	var a: int = st.attack
	if a < RELEASE_FRAME:
		# Spores gathering towards the head.
		var t := 0.4 + a * 0.4
		for from: Vector2 in [Vector2(18, 14), Vector2(44, 12), Vector2(22, 3)]:
			var p := from.lerp(Vector2(30, 5), t)
			_px(canvas, roundi(p.x), roundi(p.y), Color("#f7c8fa"))
	_blow(canvas, st, Color("#ed9df2"), Color("#17174d"), Color("#f7c8fa"))
	_burst(canvas, Vector2(ATTACKS["sporeling"].point), a, Color("#f7c8fa"), Color("#de73e5"), Color("#17174d"))

func _attack_pebbling(canvas: Image, st: Dictionary) -> void:
	var a: int = st.attack
	var o := Color("#1c1c36")
	var stone := _ramp(["#5a7a4a", "#7aa05a", "#a8c878", "#d8ecb0"])
	# The pebble (mossy, so it stands out against the grey body): picked up at the hand, lifted, hurled up and away on release.
	var at: Array = [Vector2(42, 38), Vector2(43, 29), Vector2(ATTACKS["pebbling"].point)]
	if a <= RELEASE_FRAME:
		var c: Vector2 = at[a]
		_rock(canvas, PackedVector2Array([c + Vector2(-3, 0), c + Vector2(-1, -3), c + Vector2(2, -2),
			c + Vector2(3, 1), c + Vector2(0, 3)]), stone, o)
		_px(canvas, int(c.x) - 1, int(c.y) - 1, Color("#7cbc5a"))
	if a == RELEASE_FRAME:
		for s: Vector2i in [Vector2i(44, 20), Vector2i(43, 23), Vector2i(42, 26)]:
			_px(canvas, s.x, s.y, GLOW_INNER)
		_warm_glow(canvas, Vector2(ATTACKS["pebbling"].point), Vector2(7, 6))
	# Dust kicked up at the feet.
	if a == RELEASE_FRAME or a == RELEASE_FRAME + 1:
		var spread: int = a - RELEASE_FRAME
		for d: Vector2i in [Vector2i(-6, 0), Vector2i(-4, -2), Vector2i(4, -1), Vector2i(7, 0), Vector2i(0, -3)]:
			_px(canvas, 40 + d.x * (1 + spread), 48 + d.y - spread, Color("#d8d4e4") if spread == 0 else Color("#aaa4bc"))

func _attack_dewdrop(canvas: Image, st: Dictionary) -> void:
	var a: int = st.attack
	# A spout of droplets from the tip on release.
	if a == RELEASE_FRAME:
		for d: Vector3 in [Vector3(25, 3, 1.9), Vector3(36, 3, 1.9)]:
			var spout := _layer()
			_flat_ellipse(spout, Vector2(d.x, d.y), Vector2(d.z, d.z), Color("#e8faff"))
			_stamp(canvas, spout, Color("#16305e"))
		_warm_glow(canvas, Vector2(30.5, 3), Vector2(11, 5))
	# Splash droplets arcing out and falling.
	if a > RELEASE_FRAME and a < ATTACK_FRAMES:
		var k: int = a - RELEASE_FRAME
		for side: int in [-1, 1]:
			var bead := _layer()
			_flat_ellipse(bead, Vector2(30 + side * (7 + k * 4), 3 + k * k * 1.5), Vector2(2, 2), Color("#9ad4ff"))
			_stamp(canvas, bead, Color("#16305e"))

func _attack_firefly_jar(canvas: Image, st: Dictionary) -> void:
	var a: int = st.attack
	var c := Vector2(ATTACKS["firefly_jar"].point)
	if a == RELEASE_FRAME:
		for k in 8:
			var d := Vector2.from_angle(k * TAU / 8.0) * (3.5 if k % 2 == 0 else 5.5)
			_glow_dot(canvas, Vector2i((c + d).round()), Color("#fff27a"), Color("#c8e060"))
		_glow_dot(canvas, Vector2i(c), Color.WHITE, Color("#fff27a"))
		_warm_glow(canvas, c, Vector2(9, 8))
	elif a == RELEASE_FRAME + 1 or a == RELEASE_FRAME + 2:
		var radius := 8.0 if a == RELEASE_FRAME + 1 else 11.0
		for k in 5:
			var d := Vector2.from_angle(k * TAU / 5.0 - 0.3) * radius
			_px(canvas, roundi(c.x + d.x), roundi(c.y + d.y), Color("#fff27a") if a == RELEASE_FRAME + 1 else GLOW_OUTER)

# Rootling: its tendrils fling up and a Drowsy pulse ripples out over the stone, sending up z's.
func _attack_rootling(canvas: Image, st: Dictionary) -> void:
	var a: int = st.attack
	_pulse(canvas, st, Color("#c8b0f0"))
	var zs: Array = [[], [], [Vector2i(45, 14)], [Vector2i(47, 10), Vector2i(15, 12)], [Vector2i(49, 6), Vector2i(13, 8)], [Vector2i(14, 4)]]
	for z: Vector2i in zs[a]:
		for d: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]:
			_px(canvas, z.x + d.x, z.y + d.y, Color("#ece0ff"))

# Acorn (support): a warm pulse spreads over the stone to its neighbours, with sparkles.
func _attack_acorn(canvas: Image, st: Dictionary) -> void:
	var a: int = st.attack
	_pulse(canvas, st, Color("#ffe08a"))
	var sparkles: Array = [[], [Vector2i(31, 1)], [Vector2i(19, 8), Vector2i(43, 6)], [Vector2i(15, 3), Vector2i(47, 2), Vector2i(31, 1)],
		[Vector2i(12, 12), Vector2i(50, 10)], []]
	for p: Vector2i in sparkles[a]:
		_sparkle(canvas, p, Color("#fff4c0"))

# --- Evolved Wardens --------------------------------------------------------------------------
# Branches (A, B) and final forms (A+, B+) from tower_design.md. Final forms reuse their branch's
# body with additions (bigger, glowing, flowering), and stand on the lush version of the base.

const LAVENDER := ["#1e1850", "#d4c4fa", "#b4a0ee", "#8a74d8"]
const BARK := ["#24160e", "#c09268", "#9a6e48", "#7a5234"]
const WATER := ["#16305e", "#9ad4ff", "#5aa8ec", "#3a78c8"]

# Puffy cloud of overlapping shaded circles.
func _cloud(canvas: Image, c: Vector2, w: float, ramp: Array[Color], o: Color) -> void:
	var layer := _layer()
	_ellipse(layer, c, Vector2(w * 0.3, w * 0.26), ramp)
	_ellipse(layer, c + Vector2(-w * 0.28, w * 0.08), Vector2(w * 0.22, w * 0.18), ramp)
	_ellipse(layer, c + Vector2(w * 0.28, w * 0.08), Vector2(w * 0.24, w * 0.2), ramp)
	_stamp(canvas, layer, o)

# Dithered mist: dense in the middle, wispy at the edges; `phase` shifts the dither to drift it.
func _fog(canvas: Image, c: Vector2, r: Vector2, color: Color, phase: int) -> void:
	for y in range(maxi(0, floori(c.y - r.y)), mini(S, ceili(c.y + r.y) + 1)):
		for x in range(maxi(0, floori(c.x - r.x)), mini(S, ceili(c.x + r.x) + 1)):
			var q := ((Vector2(x + 0.5, y + 0.5) - c) / r).length()
			if q > 1.0:
				continue
			if (q < 0.55 and (x + y + phase) % 2 == 0) or (q >= 0.55 and (x + 2 * y + phase) % 4 == 0):
				canvas.set_pixel(x, y, color)

# Zigzag lightning from a to b with a glow beside it.
func _bolt(canvas: Image, a: Vector2, b: Vector2, core: Color, glow: Color, kinks: int = 4) -> void:
	var pts: Array = [a]
	var n := (b - a).orthogonal().normalized()
	for k in range(1, kinks):
		pts.append(a.lerp(b, float(k) / kinks) + n * (2.5 if k % 2 == 0 else -2.5))
	pts.append(b)
	for d: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP]:
		var shifted: Array = []
		for p: Vector2 in pts:
			shifted.append(p + d)
		_line(canvas, shifted, glow)
	_line(canvas, pts, core)

func _glyph(canvas: Image, p: Vector2i, pixels: Array, color: Color) -> void:
	for d: Vector2i in pixels:
		_px(canvas, p.x + d.x, p.y + d.y, color)

const Z_GLYPH := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]
const NOTE_GLYPH := [Vector2i(0, 3), Vector2i(1, 3), Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2),
	Vector2i(2, 3), Vector2i(3, 0), Vector2i(4, 1)]

# A glyph (z, note) rising and drifting over the idle loop.
func _rising_glyph(canvas: Image, st: Dictionary, glyph: Array, x: int, from_y: int, color: Color, phase: int = 0) -> void:
	var t: float = float((st.f + phase) % st.n) / st.n
	_glyph(canvas, Vector2i(x + roundi(sin(t * TAU) * 1.5), from_y - roundi(t * 10)), glyph, color)

func _spots(canvas: Image, mask: Image, o: Color, pts: Array, color: Color) -> void:
	for p: Vector2i in pts:
		_skin_px(canvas, mask, o, [p, p + Vector2i.RIGHT, p + Vector2i.DOWN, p + Vector2i(1, 1)], color)

func _orbit_sacs(canvas: Image, st: Dictionary, n: int, ramp: Array[Color], o: Color) -> void:
	for k in n:
		var ang: float = TAU * float(st.f) / st.n + k * TAU / n
		var c := Vector2(30.5 + cos(ang) * 19.0, 25 + st.dy + sin(ang) * 7.0)
		var orb := _layer()
		_ellipse(orb, c, Vector2(2.6, 2.6), ramp)
		_stamp(canvas, orb, o)
		_px(canvas, int(c.x) - 1, int(c.y) - 1, Color.WHITE)

func _petals(canvas: Image, c: Vector2, n: int, r0: float, r1: float, width: float, ramp: Array[Color], o: Color, turn: float = 0.0) -> void:
	for k in n:
		var d := Vector2.from_angle(k * TAU / n + turn)
		_leaf(canvas, c + d * r0, c + d * r1, width, ramp, o)

func _spiral_pts(start: Vector2, centre: Vector2, r: float, turns: float, start_angle: float) -> Array:
	var pts: Array = [start]
	var steps := int(turns * 12)
	for s in steps + 1:
		var t := float(s) / steps
		pts.append(centre + Vector2.from_angle(start_angle + t * turns * TAU) * r * (1.0 - t * 0.75))
	return pts

# --- Sporeling line: Driftspore -> Puffball, Bloomcap -> Dreamshroom ---

# Driftspore: a lavender Sporeling carrying stacks of spores: sacs orbit it, spots cover it.
func _draw_driftspore(canvas: Image, st: Dictionary) -> void:
	_driftspore_body(canvas, st, false)

# Puffball: Driftspore grown puffy: a puffball cap, puffballs on its shoulders and knee.
func _draw_puffball(canvas: Image, st: Dictionary) -> void:
	_driftspore_body(canvas, st, true)

func _driftspore_body(canvas: Image, st: Dictionary, puffy: bool) -> void:
	var dy: int = st.dy
	var fig := _pal(LAVENDER[0], LAVENDER[1], LAVENDER[2], LAVENDER[3])
	var sac := _ramp(["#a890e8", "#d8ccff", "#f6f0ff"])
	var puff := _ramp(["#c8b898", "#e4d8bc", "#f6eedc", "#ffffff"])
	_draw_waystone(canvas, st, "fairy_ring", puffy)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	_spots(canvas, mask, fig.o, [Vector2i(24, 26 + dy), Vector2i(36, 22 + dy), Vector2i(29, 33), Vector2i(40, 30),
		Vector2i(21, 36), Vector2i(35, 8 + dy), Vector2i(50, 34), Vector2i(14, 40)], Color("#f0eaff"))
	if puffy:
		for p: Vector3 in [Vector3(17, 22 + dy, 4.5), Vector3(44, 21 + dy, 5.0), Vector3(52, 31, 4.0), Vector3(10, 38, 3.5)]:
			_puffball(canvas, Vector2(p.x, p.y), p.z, puff, fig.o)
		var cap := _layer()
		_ellipse(cap, Vector2(30.5, 7 + dy), Vector2(11.5, 7), puff, 9.5 + dy)
		for y in S:
			for x in S:
				if cap.get_pixel(x, y).a > 0.0 and (x + 2 * y) % 5 == 0:
					cap.set_pixel(x, y, puff[0])
		_stamp(canvas, cap, fig.o)
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), false)
	_orbit_sacs(canvas, st, 2 if puffy else 3, sac, fig.o)
	_motes(canvas, st, [18, 44, 36], 16, 16, [Color("#f0eaff"), Color("#b4a0ee")])

func _puffball(canvas: Image, c: Vector2, r: float, ramp: Array[Color], o: Color) -> void:
	var layer := _layer()
	_ellipse(layer, c, Vector2(r, r * 0.9), ramp)
	for y in S:
		for x in S:
			if layer.get_pixel(x, y).a > 0.0 and (x + 2 * y) % 5 == 0:
				layer.set_pixel(x, y, ramp[0])
	_stamp(canvas, layer, o)

# Bloomcap: the Sporeling under a big frilly bloom cap, always drowsy, a sleepy cloud beside it.
func _draw_bloomcap(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal("#17174d", "#ed9df2", "#de73e5", "#ba41d9")
	_draw_waystone(canvas, st, "fairy_ring")
	_draw_template_figure(canvas, st.pose, fig)
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), true, true)
	_bloom_cap(canvas, dy, 17, 9, _ramp(["#a0508a", "#d070b0", "#f0a0d0", "#ffd0ec"]), fig.o, Color("#f6dcec"), Color("#fff4fa"))
	if st.attack < 0:
		var bob: int = [0, 0, 1, 1, 1, 0, 0, 0][st.f]
		_cloud(canvas, Vector2(50, 19 + bob), 11, _ramp(["#b8a8d8", "#e0d4f4", "#f8f0ff"]), Color("#5a4a7a"))
		_rising_glyph(canvas, st, Z_GLYPH, 54, 12, Color("#f8f0ff"))

# Dreamshroom: Bloomcap as a night-purple dreamer under a vast indigo cap with glowing spots,
# stars twinkling round it.
func _draw_dreamshroom(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal("#140c30", "#a88ae0", "#8a6ac8", "#6a4aa8")
	var glow := Color("#7ff0e0") if st.f % 4 < 2 or st.power > 0.5 else Color("#4ac0b8")
	_draw_waystone(canvas, st, "fairy_ring", true)
	_draw_template_figure(canvas, st.pose, fig)
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), true, true)
	_bloom_cap(canvas, dy, 19, 9.5, _ramp(["#2a2070", "#3a3090", "#5a50c0", "#8a80e8"]), fig.o, Color("#b8b0e8"), glow)
	for i in 4:
		var p: Vector2i = [Vector2i(8, 8), Vector2i(54, 5), Vector2i(4, 22), Vector2i(58, 20)][i]
		if (st.f + i * 2) % 4 < 2:
			_sparkle(canvas, p, Color("#fff4c0"))
	if st.attack < 0:
		_rising_glyph(canvas, st, Z_GLYPH, 52, 16, Color("#e8e0ff"))
		_rising_glyph(canvas, st, Z_GLYPH, 9, 18, Color("#e8e0ff"), 4)

func _bloom_cap(canvas: Image, dy: int, w: float, h: float, ramp: Array[Color], o: Color, gill: Color, spot: Color) -> void:
	var gills := _layer()
	_flat_ellipse(gills, Vector2(30.5, 10.5 + dy), Vector2(w - 2, 1.5), gill)
	_stamp(canvas, gills, o)
	var cap := _layer()
	_ellipse(cap, Vector2(30.5, 10 + dy), Vector2(w, h), ramp, 10.0 + dy)
	var x := 30.5 - w + 2.0
	while x < 30.5 + w - 1.0:
		_flat_ellipse(cap, Vector2(x, 10.5 + dy), Vector2(1.8, 1.6), ramp[1])
		x += 4.0
	_stamp(canvas, cap, o)
	var spots := _layer()
	for s: Vector3 in [Vector3(-8, -5, 1.6), Vector3(0, -7, 1.4), Vector3(8, -4, 1.8), Vector3(-2, -3, 1.0), Vector3(13, -2, 1.0), Vector3(-13, -2, 1.0)]:
		_flat_ellipse(spots, Vector2(30.5 + s.x * w / 17.0, 10 + dy + s.y * h / 9.0), Vector2(s.z, s.z * 0.8), spot)
	_stamp(canvas, spots)

# --- Pebbling line: Mossback -> Boulderback, Chime Stone -> Lullaby Bell ---

const STONE := ["#686d9a", "#979dc2", "#c4c9e2", "#e4e7f4"]
const MOSS := ["#3f7a3e", "#5a9a48", "#7cbc5a", "#a8dc7a"]

func _pebble_golem(canvas: Image, st: Dictionary, fig: Dictionary, lush: bool, before: Callable = Callable(), theme: String = "cobble") -> Image:
	var dy: int = st.dy
	_draw_waystone(canvas, st, theme, lush)
	if before.is_valid():
		before.call(canvas, st, fig)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	_line(canvas, [Vector2(36, 9 + dy), Vector2(35, 11 + dy)], fig.c, mask)
	_line(canvas, [Vector2(21, 30), Vector2(23, 33), Vector2(22, 35)], fig.c, mask)
	_line(canvas, [Vector2(34, 36), Vector2(35, 39)], fig.c, mask)
	return mask

func _moss_cap(canvas: Image, dy: int, o: Color) -> void:
	var moss := _ramp(MOSS)
	var cap := _layer()
	_ellipse(cap, Vector2(30.5, 9 + dy), Vector2(9.5, 5), moss, 9.0 + dy)
	for p: Vector2i in [Vector2i(22, 9), Vector2i(22, 10), Vector2i(29, 9), Vector2i(38, 9), Vector2i(38, 10)]:
		cap.set_pixel(p.x, p.y + dy, moss[1])
	_stamp(canvas, cap, o)
	_flower(canvas, Vector2i(34, 5 + dy), Color("#fff4f0"), Color("#ffd24a"))

# A stone shell behind the figure: plates, and a mossy garden with grass and flowers on top.
func _shell(canvas: Image, c: Vector2, r: Vector2, o: Color, flowers: int) -> void:
	var stone := _ramp(["#5c6088", "#7c82aa", "#a0a6c8", "#c4c9e2"])
	var moss := _ramp(MOSS)
	var layer := _layer()
	_ellipse(layer, c, r, stone)
	var garden_c := c - Vector2(0, r.y * 0.45)
	for y in S:
		for x in S:
			if layer.get_pixel(x, y).a == 0.0:
				continue
			if ((Vector2(x + 0.5, y + 0.5) - garden_c) / Vector2(r.x * 0.85, r.y * 0.55)).length() < 1.0:
				layer.set_pixel(x, y, moss[2] if y < garden_c.y - 2 else moss[1])
			elif (x + 2 * y) % 9 == 0 or (x - 2 * y + 90) % 9 == 0:
				layer.set_pixel(x, y, stone[0])
	_stamp(canvas, layer, o)
	var tufts := [-12.0, -6.0, 6.0, 12.0, -16.0, 16.0]
	for i in tufts.size():
		var gx: float = c.x + tufts[i]
		var top_y := c.y - r.y * sqrt(maxf(0.0, 1.0 - pow((gx - c.x) / r.x, 2.0)))
		_px(canvas, int(gx), int(top_y) - 1, moss[2])
		_px(canvas, int(gx) + 1, int(top_y) - 2, moss[3])
		if i < flowers:
			_flower(canvas, Vector2i(int(gx) + 3, int(top_y) + 1), Color("#fff4f0") if i % 2 == 0 else Color("#f4a0c0"), Color("#ffd24a"))

# Mossback: a stone tortoise golem with a garden growing on its shell.
func _draw_mossback(canvas: Image, st: Dictionary) -> void:
	var fig := _pal("#1c1c36", "#c4c9e2", "#979dc2", "#686d9a")
	_pebble_golem(canvas, st, fig, false, func(cv: Image, s: Dictionary, fg: Dictionary) -> void:
		_shell(cv, Vector2(32, 23 + s.dy), Vector2(24, 17), fg.o, 3))
	_moss_cap(canvas, st.dy, fig.o)
	_golem_face(canvas, st, fig)

# Boulderback: Mossback's shell grown huge, boulders heaped on it and a little tree in its garden.
func _draw_boulderback(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal("#1c1c36", "#c4c9e2", "#979dc2", "#686d9a")
	var stone := _ramp(STONE)
	_pebble_golem(canvas, st, fig, true, func(cv: Image, s: Dictionary, fg: Dictionary) -> void:
		_shell(cv, Vector2(32, 22 + s.dy), Vector2(26, 17), fg.o, 5)
		var trunk := _layer()
		_stroke(trunk, [Vector2(47, 12 + s.dy), Vector2(48, 5 + s.dy)], 1.2, Color("#7a5234"))
		_stamp(cv, trunk, fg.o)
		var crown := _layer()
		_ellipse(crown, Vector2(48, 4 + s.dy), Vector2(6, 4), _ramp(LEAF))
		_stamp(cv, crown, fg.o))
	_rock(canvas, PackedVector2Array([Vector2(9, 18 + dy), Vector2(12, 12 + dy), Vector2(18, 11 + dy), Vector2(21, 16 + dy), Vector2(15, 20 + dy)]), stone, fig.o)
	_rock(canvas, PackedVector2Array([Vector2(50, 20 + dy), Vector2(53, 15 + dy), Vector2(58, 16 + dy), Vector2(59, 21 + dy), Vector2(54, 23 + dy)]), stone, fig.o)
	_moss_cap(canvas, dy, fig.o)
	_golem_face(canvas, st, fig)

# Chime Stone: a polished stone golem with glowing runes and a wooden yoke on its shoulders,
# stone chimes hanging from it that sway and hum.
func _draw_chime_stone(canvas: Image, st: Dictionary) -> void:
	_chime_body(canvas, st, false)

# Lullaby Bell: Chime Stone with a big bronze bell hung from the yoke, humming everyone to sleep.
func _draw_lullaby_bell(canvas: Image, st: Dictionary) -> void:
	_chime_body(canvas, st, true)

func _chime_body(canvas: Image, st: Dictionary, bell: bool) -> void:
	var dy: int = st.dy
	var fig := _pal("#1c1c36", "#e4e0f0", "#bcb8d8", "#9490b8")
	var rune := Color("#f0e0ff") if st.power > 0.5 else Color("#c8a8f0")  # Bellflower lilac
	var mask := _pebble_golem(canvas, st, fig, bell, Callable(), "bellflower")
	_line(canvas, [Vector2(24, 25 + dy), Vector2(27, 22 + dy), Vector2(31, 23 + dy), Vector2(30, 27 + dy), Vector2(26, 27 + dy)], rune, mask)
	_line(canvas, [Vector2(34, 33), Vector2(37, 31), Vector2(39, 34)], rune, mask)
	_line(canvas, [Vector2(15, 40), Vector2(18, 38)], rune, mask)
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), true, bell)
	var yoke := _layer()
	_stroke(yoke, [Vector2(8, 23 + dy), Vector2(17, 18 + dy), Vector2(30.5, 17 + dy), Vector2(44, 18 + dy), Vector2(53, 23 + dy)], 1.2, Color("#8a5a3a"))
	_stamp(canvas, yoke, fig.o)
	var swing: int = st.sway + (1 if st.lift < 0 else 0)
	var rods := [[10, 22, 8], [15, 19, 10], [46, 19, 10], [51, 22, 8]]
	for i in rods.size():
		var rod: Array = rods[i]
		var x: int = rod[0] + (swing if i % 2 == 0 else -swing)
		var y0: int = rod[1] + dy + 2
		_line(canvas, [Vector2(rod[0], rod[1] + dy), Vector2(x, y0)], Color("#e0c8a0"))
		var layer := _layer()
		_round_rect(layer, Rect2i(x - 1, y0, 3, rod[2]), 1, Color("#c8b8e8"))
		for y in range(y0, y0 + rod[2]):
			if y >= 0 and y < S:
				layer.set_pixel(clampi(x - 1, 0, S - 1), y, fig.a)
		_stamp(canvas, layer, fig.o)
	if bell:
		_line(canvas, [Vector2(30.5, 17 + dy), Vector2(30.5, 21 + dy)], Color("#e0c8a0"))
		_bell(canvas, Vector2(30.5, 21 + dy), 7.0, swing, _ramp(["#8a5a2a", "#b8823a", "#e0b060", "#fff0b0"]), fig.o)
		if st.attack < 0:
			_rising_glyph(canvas, st, NOTE_GLYPH, 50, 12, Color("#ffe08a"))
			_rising_glyph(canvas, st, Z_GLYPH, 9, 14, Color("#ece0ff"), 4)
	elif st.attack < 0:
		_rising_glyph(canvas, st, NOTE_GLYPH, 50, 12, rune)

func _bell(canvas: Image, top: Vector2, s: float, swing: int, ramp: Array[Color], o: Color) -> void:
	var c := top + Vector2(swing, 0)
	var layer := _layer()
	_ellipse(layer, c + Vector2(0, s * 0.6), Vector2(s * 0.55, s * 0.6), ramp, c.y + s * 0.6)
	var body := PackedVector2Array([c + Vector2(-s * 0.55, s * 0.55), c + Vector2(s * 0.55, s * 0.55),
		c + Vector2(s * 0.9, s * 1.4), c + Vector2(-s * 0.9, s * 1.4)])
	for y in S:
		for x in S:
			var p := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(p, body):
				var nx := clampf((p.x - c.x) / (s * 0.9), -1.0, 1.0)
				layer.set_pixel(x, y, _shade(ramp, Vector3(nx, 0.0, sqrt(1.0 - nx * nx))))
				if p.y > c.y + s * 1.25:
					layer.set_pixel(x, y, ramp[3])
	_stamp(canvas, layer, o)
	var clapper := _layer()
	_flat_ellipse(clapper, c + Vector2(swing, s * 1.55), Vector2(1.3, 1.3), ramp[0])
	_stamp(canvas, clapper, o)

# Heaves a stone from the hand up and away on release, kicking up dust.
func _throw(canvas: Image, st: Dictionary, launch: Vector2, size: float, ramp: Array[Color], o: Color) -> void:
	var a: int = st.attack
	var at: Array = [Vector2(42, 38), Vector2(43, 29), launch]
	if a <= RELEASE_FRAME:
		var c: Vector2 = at[a]
		var pts := PackedVector2Array()
		var radii := [1.0, 0.8, 0.95, 0.75, 1.0, 0.85]
		for k in 6:
			pts.append(c + Vector2.from_angle(k * TAU / 6.0 + 0.3) * size * radii[k])
		_rock(canvas, pts, ramp, o)
		_px(canvas, int(c.x) - 1, int(c.y) - 2, Color("#7cbc5a"))
	if a == RELEASE_FRAME:
		for k in 3:
			var p: Vector2 = (at[1] as Vector2).lerp(launch, 0.3 + k * 0.2)
			_px(canvas, int(p.x), int(p.y), GLOW_INNER)
		_warm_glow(canvas, launch, Vector2(size + 4, size + 3))
	if a == RELEASE_FRAME or a == RELEASE_FRAME + 1:
		var spread: int = a - RELEASE_FRAME
		for d: Vector2i in [Vector2i(-7, 0), Vector2i(-4, -2), Vector2i(4, -1), Vector2i(8, 0), Vector2i(0, -3), Vector2i(-10, 1)]:
			_px(canvas, 40 + d.x * (1 + spread), 48 + d.y - spread, Color("#d8d4e4") if spread == 0 else Color("#aaa4bc"))

# --- Dewdrop line: Rain Lily -> Monsoon, Mistveil -> Morning Fog ---

func _water_gloss(canvas: Image, mask: Image, st: Dictionary, fig: Dictionary) -> void:
	var dy: int = st.dy
	var shine := Color("#e8faff")
	_skin_px(canvas, mask, fig.o, [Vector2i(24, 7 + dy), Vector2i(25, 7 + dy), Vector2i(24, 8 + dy),
		Vector2i(22, 25 + dy), Vector2i(22, 26 + dy), Vector2i(21, 27 + dy), Vector2i(21, 28 + dy), Vector2i(21, 29 + dy),
		Vector2i(43, 28), Vector2i(43, 29)], shine)
	for k in 3:
		var t: float = float((st.f + k * 3) % st.n) / st.n
		var b := Vector2i([27, 34, 38][k], roundi(42 - t * 18))
		_skin_px(canvas, mask, fig.o, [b, b + Vector2i.RIGHT], shine)

func _droplet_tip(canvas: Image, st: Dictionary, fig: Dictionary) -> void:
	var tip := _layer()
	_flame(tip, Vector2(30.5, 11 + st.dy), 6.0, 13.0 - st.lift * 1.5, st.sway, fig.a)
	_stamp(canvas, tip, fig.o)

# Rain Lily: the Dewdrop wearing a lily pad collar with a water lily blooming on its head.
func _draw_rain_lily(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal(WATER[0], WATER[1], WATER[2], WATER[3])
	_draw_waystone(canvas, st, "pond")
	var mask := _draw_template_figure(canvas, st.pose, fig)
	_water_gloss(canvas, mask, st, fig)
	_golem_face(canvas, st, fig)
	var collar := _layer()
	_ellipse(collar, Vector2(30.5, 18.5 + dy), Vector2(12, 2.6), _ramp(LEAF))
	_stamp(canvas, collar, Color("#1e3a24"))
	_petals(canvas, Vector2(30.5, 5.5 + dy), 6, 1.0, 7.0 - st.lift * 0.5, 2.4, _ramp(["#d8a0c0", "#f4d0e4", "#ffffff"]), fig.o, 0.3)
	var heart := _layer()
	_flat_ellipse(heart, Vector2(30.5, 5.5 + dy), Vector2(1.6, 1.4), Color("#ffd24a"))
	_stamp(canvas, heart)

# Monsoon: a deep-water golem with a rain cloud over its head, rain falling all around it.
func _draw_monsoon(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal("#0e2048", "#7ab8f0", "#4a88d8", "#2a5eb0")
	_draw_waystone(canvas, st, "pond", true)
	_droplet_tip(canvas, st, fig)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	_water_gloss(canvas, mask, st, fig)
	_golem_face(canvas, st, fig)
	_cloud(canvas, Vector2(30.5, 3 + dy), 24, _ramp(["#4a5a80", "#6a7aa0", "#9aaac8", "#c8d4e8"]), Color("#1e2a48"))
	_rain(canvas, st, 7)

func _rain(canvas: Image, st: Dictionary, n: int, color: Color = Color("#9ad4ff")) -> void:
	for k in n:
		var x := 8 + k * 7
		var y: int = 10 + ((st.f * 3 + k * 5) % 22)
		_px(canvas, x, y, color)
		_px(canvas, x - 1, y + 1, color)

# Mistveil: a pale mist golem under a hood and veil of fog, wisps curling round its feet.
func _draw_mistveil(canvas: Image, st: Dictionary) -> void:
	_mist_body(canvas, st, false)

# Morning Fog: Mistveil at sunrise: warm-tinted, a rising sun behind its shoulder, heavier fog.
func _draw_morning_fog(canvas: Image, st: Dictionary) -> void:
	_mist_body(canvas, st, true)

func _mist_body(canvas: Image, st: Dictionary, dawn: bool) -> void:
	var dy: int = st.dy
	var fig := _pal("#3a2a3a", "#fff2ea", "#f6d8d2", "#dcb4bc") if dawn else _pal("#2a3a50", "#eef6fa", "#cfe0ea", "#a8c0d0")
	var veil := Color("#f8e4dc") if dawn else Color("#dce8f0")
	var mist := Color("#fff8f0") if dawn else Color("#f4faff")
	_draw_waystone(canvas, st, "pond", dawn)
	if dawn:
		var sun := _layer()
		_ellipse(sun, Vector2(49, 12 + dy), Vector2(6, 6), _ramp(["#f0a040", "#ffc860", "#ffe8a0", "#fffbe0"]))
		_stamp(canvas, sun, Color("#b8602a"))
		for k in 8:
			if (k + st.f) % 2 == 0:
				var d := Vector2.from_angle(k * TAU / 8.0)
				_px(canvas, roundi(49 + d.x * 8.5), roundi(12 + dy + d.y * 8.5), Color("#ffe8a0"))
	var hood := _layer()
	_flat_ellipse(hood, Vector2(30.5, 11 + dy), Vector2(12.5, 11), veil)
	_flat_polygon(hood, PackedVector2Array([Vector2(19, 12 + dy), Vector2(12, 31 + dy), Vector2(18, 32 + dy), Vector2(23, 18 + dy)]), veil)
	_flat_polygon(hood, PackedVector2Array([Vector2(42, 12 + dy), Vector2(49, 31 + dy), Vector2(43, 32 + dy), Vector2(38, 18 + dy)]), veil)
	_stamp(canvas, hood, fig.o)
	_draw_template_figure(canvas, st.pose, fig)
	_golem_face(canvas, st, fig, Color("#e0a080") if dawn else Color("#6fe0e0"), true, dawn)
	var phase: int = st.f
	_fog(canvas, Vector2(14, 44), Vector2(11, 4), mist, phase)
	_fog(canvas, Vector2(50, 42), Vector2(11, 4), mist, phase + 1)
	if dawn:
		_fog(canvas, Vector2(32, 52), Vector2(15, 4), mist, phase + 2)
		if st.attack < 0:
			_rising_glyph(canvas, st, Z_GLYPH, 9, 16, Color("#fff2ea"))

# --- Firefly Jar line: Stormcap -> Thunderhead, Lanternmoth -> Beacon, hidden Sunpetal ---

func _glass(canvas: Image, mask: Image, st: Dictionary, fig: Dictionary, hi: Color) -> void:
	var dy: int = st.dy
	for y in range(24, 40):
		_skin_px(canvas, mask, fig.o, [Vector2i(21, y + dy)], hi)
	_skin_px(canvas, mask, fig.o, [Vector2i(24, 7 + dy), Vector2i(24, 8 + dy), Vector2i(25, 7 + dy), Vector2i(22, 24 + dy)], hi.lightened(0.4))
	_neck_string(canvas, mask, st, fig.o)

# The twine tied round a jar's neck: it sags a little with the neck, has a dark underside so it
# reads as a cord, and ends in a knot on the right with two short ends that sway.
func _neck_string(canvas: Image, mask: Image, st: Dictionary, o: Color) -> void:
	var dy: int = st.dy
	var twine := Color("#f0d8a8")
	var under := Color("#8a6a40")
	for x in range(24, 45):
		var t := (x - 24) / 20.0
		var y := 19 + dy + roundi(sin(t * PI) * 1.4)
		if mask.get_pixel(x, y).a == 0.0:
			continue
		_px(canvas, x, y, twine if (x % 3) != 0 else Color("#d8b880"))  # a twist every few pixels
		if mask.get_pixel(x, y + 1).a > 0.0:
			_px(canvas, x, y + 1, under)
	# The knot, and its two ends hanging down (swaying with the idle).
	var kx := 44
	var ky := 19 + dy
	for p: Vector2i in [Vector2i(kx, ky - 1), Vector2i(kx + 1, ky - 1), Vector2i(kx, ky), Vector2i(kx + 1, ky)]:
		_px(canvas, p.x, p.y, twine)
	_px(canvas, kx + 2, ky, o)
	_px(canvas, kx + 1, ky + 1, under)
	var sway: int = st.sway
	for end: Array in [[Vector2(kx, ky + 1), Vector2(kx - 1 + sway, ky + 5)], [Vector2(kx + 1, ky + 1), Vector2(kx + 3 + sway, ky + 4)]]:
		_line(canvas, [end[0], end[1]], twine)
		var tip: Vector2 = end[1]
		_px(canvas, int(tip.x), int(tip.y) + 1, under)

# Stormcap: a storm-glass golem capped with a little storm cloud, static crackling inside it.
func _draw_stormcap(canvas: Image, st: Dictionary) -> void:
	_storm_body(canvas, st, false)

# Thunderhead: Stormcap's cloud grown into a thunderhead, lightning licking out of it.
func _draw_thunderhead(canvas: Image, st: Dictionary) -> void:
	_storm_body(canvas, st, true)

func _storm_body(canvas: Image, st: Dictionary, big: bool) -> void:
	var dy: int = st.dy
	var fig := _pal("#16162a", "#5c5c8e", "#4a4a7c", "#383862")
	var zap := Color("#fff6a0")
	_draw_waystone(canvas, st, "night", big)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	_glass(canvas, mask, st, fig, Color("#8a8ac0"))
	var sparks := [Vector2i(24, 28), Vector2i(34, 25), Vector2i(28, 36), Vector2i(37, 33), Vector2i(26, 22)]
	for k in (4 if big else 2):
		var p: Vector2i = sparks[(st.f + k * 2) % sparks.size()] + Vector2i(0, dy)
		_skin_px(canvas, mask, fig.o, [p, p + Vector2i(1, -1), p + Vector2i(2, 0), p + Vector2i(3, -1)], zap)
	_golem_face(canvas, st, fig, Color("#c0f0ff"), false)
	if big:
		_cloud(canvas, Vector2(30.5, 3 + dy), 27, _ramp(["#2a2a44", "#44446a", "#6a6a90", "#9a9ac0"]), Color("#10101e"))
		if st.attack < 0 and st.f % 4 == 1:
			_bolt(canvas, Vector2(45, 7), Vector2(50, 15), zap, Color("#8a8af0"), 3)
		elif st.attack < 0 and st.f % 4 == 3:
			_bolt(canvas, Vector2(16, 7), Vector2(11, 15), zap, Color("#8a8af0"), 3)
	else:
		_cloud(canvas, Vector2(30.5, 4 + dy), 19, _ramp(["#3a3a58", "#5a5a7a", "#8a8aa8", "#b8b8d0"]), Color("#16162a"))

# Lanternmoth: an amber lantern golem with soft moth wings, feathery antennae and a warm light
# glowing in its chest.
func _draw_lanternmoth(canvas: Image, st: Dictionary) -> void:
	_moth_body(canvas, st, false)

# Beacon: Lanternmoth in gold, its light so bright it throws rays in every direction.
func _draw_beacon(canvas: Image, st: Dictionary) -> void:
	_moth_body(canvas, st, true)

func _moth_body(canvas: Image, st: Dictionary, beacon: bool) -> void:
	var dy: int = st.dy
	var fig := _pal("#2a1a10", "#e8b070", "#c88c50", "#a06a3a")
	var wing := _ramp(["#a07a30", "#e0b860", "#fff0b0"]) if beacon else _ramp(["#8a6a4a", "#c8a878", "#ecd8b0"])
	var span := 18.0 if beacon else 16.0
	var flap: int = st.sway
	_draw_waystone(canvas, st, "night", beacon)
	if beacon:
		for k in 12:
			if (k + st.f) % 2 == 0:
				var d := Vector2.from_angle(k * TAU / 12.0)
				_line(canvas, [Vector2(30.5, 8 + dy) + d * 9.0, Vector2(30.5, 8 + dy) + d * 15.0], Color("#fff4c0"))
	_leaf(canvas, Vector2(21, 21 + dy), Vector2(21 - span + flap, 5 + dy), 7.5, wing, fig.o)
	_leaf(canvas, Vector2(40, 21 + dy), Vector2(40 + span - flap, 4 + dy), 7.5, wing, fig.o)
	_leaf(canvas, Vector2(22, 29 + dy), Vector2(22 - span * 0.8, 38), 5.0, wing, fig.o)
	_leaf(canvas, Vector2(39, 29 + dy), Vector2(39 + span * 0.8, 38), 5.0, wing, fig.o)
	for s: Vector2 in [Vector2(21 - span * 0.55 + flap * 0.5, 12 + dy), Vector2(40 + span * 0.55 - flap * 0.5, 11 + dy)]:
		var eye := _layer()
		_flat_ellipse(eye, s, Vector2(2.2, 2.2), Color("#5a3a2a"))
		_flat_ellipse(eye, s, Vector2(1.2, 1.2), Color("#ffffff") if beacon else Color("#f0a040"))
		_stamp(canvas, eye)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	_glass(canvas, mask, st, fig, Color("#f8d8a0"))
	# The light in its chest, pulsing.
	var pulse: float = 1.0 + 0.2 * sin(TAU * float(st.f) / st.n) + st.power * 0.4
	for y in S:
		for x in S:
			var q := ((Vector2(x + 0.5, y + 0.5) - Vector2(30, 29 + dy)) / (Vector2(5, 6) * pulse)).length()
			if q < 1.0 and mask.get_pixel(x, y).a > 0.0 and canvas.get_pixel(x, y) != fig.o:
				if q < 0.5:
					canvas.set_pixel(x, y, Color.WHITE if beacon else Color("#fff0b0"))
				elif (x + y) % 2 == 0:
					canvas.set_pixel(x, y, Color("#f8d890"))
	var lid := _layer()
	_round_rect(lid, Rect2i(25, 3 + dy, 12, 3), 1, Color("#5a5a6a"))
	_stamp(canvas, lid, fig.o)
	for p: Vector2i in [Vector2i(29, 2), Vector2i(30, 1), Vector2i(31, 1), Vector2i(32, 2)]:
		_px(canvas, p.x, p.y + dy, Color("#5a5a6a"))
	for side: int in [-1, 1]:
		var base := Vector2(30.5 + side * 3, 3 + dy)
		_line(canvas, [base, base + Vector2(side * 3, -2), base + Vector2(side * 6, -3)], fig.o)
		_px(canvas, int(base.x + side * 5), int(base.y - 4), fig.c)
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), false)

# Sunpetal (hidden branch): a sunflower golem, a slowly turning ring of petals round its seed-disc
# face, leaves on its arms.
func _draw_sunpetal(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal("#1e3a14", "#c0e080", "#94c45a", "#6a9a3a")
	var face_c := Vector2(30.5, 11.5 + dy)
	_draw_waystone(canvas, st, "meadow", true)
	_petals(canvas, face_c, 12, 6.5, 13.5 - st.lift * 0.5, 2.6, _ramp(["#d89a20", "#f0c030", "#ffe070"]), fig.o, float(st.f) * TAU / 96.0)
	_leaf(canvas, Vector2(18, 31), Vector2(9, 25), 3.0, _ramp(LEAF), fig.o)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	for y in S:
		for x in S:
			if ((Vector2(x + 0.5, y + 0.5) - face_c) / Vector2(8.5, 6.5)).length() < 1.0 and mask.get_pixel(x, y).a > 0.0 and canvas.get_pixel(x, y) != fig.o:
				canvas.set_pixel(x, y, Color("#8a5a2a") if (x + y) % 2 == 0 else Color("#6a4020"))
	_leaf(canvas, Vector2(43, 30), Vector2(52, 24), 3.0, _ramp(LEAF), fig.o)
	_golem_face(canvas, st, fig, Color("#ffe070"), false)

# --- Rootling line: Rootcurl -> Long Way Home, Tangleroot -> Snugroot ---

func _root_golem(canvas: Image, st: Dictionary, fig: Dictionary, lush: bool) -> Image:
	var dy: int = st.dy
	var sway: int = st.sway
	_draw_waystone(canvas, st, "stump", lush)
	var roots := _layer()
	for root: Array in [[Vector2(16, 44), Vector2(10, 46), Vector2(5, 44)], [Vector2(27, 47), Vector2(25, 53)],
			[Vector2(40, 48), Vector2(46, 52), Vector2(53, 50)], [Vector2(52, 42), Vector2(57, 41), Vector2(61, 42)]]:
		_stroke(roots, root, 1.6, fig.b)
	_stamp(canvas, roots, fig.o)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	for g: Array in [[Vector2(24, 26 + dy), Vector2(23, 31 + dy), Vector2(24, 35)], [Vector2(29, 23 + dy), Vector2(30, 29 + dy)],
			[Vector2(36, 28 + dy), Vector2(37, 34)], [Vector2(27, 7 + dy), Vector2(26, 9 + dy)], [Vector2(15, 40), Vector2(18, 42)]]:
		_line(canvas, g, fig.c, mask)
	var knot := _layer()
	_flat_ellipse(knot, Vector2(33, 33), Vector2(1.6, 2.2), fig.c)
	_stamp(canvas, knot, fig.o)
	_leaf(canvas, Vector2(30, 5 + dy), Vector2(21 + sway, 1 + dy), 3.2, _ramp(LEAF), fig.o)
	_leaf(canvas, Vector2(31, 5 + dy), Vector2(41 + sway, 0 + dy), 3.6, _ramp(LEAF), fig.o)
	return mask

# Rootcurl: a Rootling whose shoulder tendrils coil into springy curls, ready to hook and tug.
func _draw_rootcurl(canvas: Image, st: Dictionary) -> void:
	var fig := _pal(BARK[0], BARK[1], BARK[2], BARK[3])
	_root_golem(canvas, st, fig, false)
	_curls(canvas, st, fig)
	_golem_face(canvas, st, fig)

# Long Way Home: Rootcurl grown old and wise: a mossy beard, a root walking staff with a little
# lantern for the long walk home.
func _draw_long_way_home(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal(BARK[0], BARK[1], BARK[2], BARK[3])
	_root_golem(canvas, st, fig, true)
	var staff := _layer()
	_stroke(staff, [Vector2(52, 46), Vector2(51, 10)], 1.2, Color("#8a6a4a"))
	_flat_ellipse(staff, Vector2(51, 9), Vector2(2, 2), Color("#8a6a4a"))
	_stamp(canvas, staff, fig.o)
	var lamp := _layer()
	_round_rect(lamp, Rect2i(53, 11, 5, 6), 1, Color("#fff0b0") if st.f % 4 < 2 else Color("#f8d890"))
	_stamp(canvas, lamp, fig.o)
	_px(canvas, 55, 10, fig.o)
	_curls(canvas, st, fig)
	_golem_face(canvas, st, fig)
	var beard := _layer()
	_flat_polygon(beard, PackedVector2Array([Vector2(24, 16 + dy), Vector2(37, 16 + dy), Vector2(35, 21 + dy),
		Vector2(30.5, 25 + dy), Vector2(26, 21 + dy)]), Color("#5a9a48"))
	for y in S:
		for x in S:
			if beard.get_pixel(x, y).a > 0.0 and (x + y) % 3 == 0:
				beard.set_pixel(x, y, Color("#7cbc5a"))
	_stamp(canvas, beard, Color("#1e3a24"))

func _curls(canvas: Image, st: Dictionary, fig: Dictionary) -> void:
	var dy: int = st.dy
	var lift: int = st.lift
	var layer := _layer()
	_stroke(layer, _spiral_pts(Vector2(21, 23 + dy), Vector2(14, 14 + dy + lift), 4.5, 1.25, 0.0), 1.2, fig.a)
	_stroke(layer, _spiral_pts(Vector2(42, 23 + dy), Vector2(48, 13 + dy + lift), 4.5, 1.25, PI), 1.2, fig.a)
	_stamp(canvas, layer, fig.o)

# Tangleroot: a mossy Rootling wrapped in its own roots, more roots climbing up from the stump
# to hold whatever wanders past.
func _draw_tangleroot(canvas: Image, st: Dictionary) -> void:
	_tangle_body(canvas, st, false)

# Snugroot: Tangleroot's roots curled into a cosy nest round it, blossoming.
func _draw_snugroot(canvas: Image, st: Dictionary) -> void:
	_tangle_body(canvas, st, true)

func _tangle_body(canvas: Image, st: Dictionary, snug: bool) -> void:
	var dy: int = st.dy
	var fig := _pal("#1e160e", "#b0906a", "#8a6a4a", "#6a4e34")
	var root := Color("#d8c08a")
	var mask := _root_golem(canvas, st, fig, snug)
	var wraps := _layer()
	_stroke(wraps, [Vector2(15, 38), Vector2(22, 33), Vector2(30, 35), Vector2(38, 30), Vector2(46, 33)], 1.5, root)
	_stroke(wraps, [Vector2(18, 27 + dy), Vector2(25, 23 + dy), Vector2(33, 26 + dy), Vector2(41, 21 + dy)], 1.3, root)
	_stroke(wraps, [Vector2(8, 47), Vector2(10, 41), Vector2(14, 36)], 1.5, root)
	_stroke(wraps, [Vector2(55, 47), Vector2(56, 40), Vector2(52, 34)], 1.5, root)
	if snug:
		_stroke(wraps, [Vector2(3, 44), Vector2(9, 49), Vector2(20, 51), Vector2(31, 52)], 1.8, root)
		_stroke(wraps, [Vector2(61, 43), Vector2(55, 49), Vector2(44, 51), Vector2(31, 52)], 1.8, root)
	_stamp(canvas, wraps, fig.o)
	# Moss along the wrapping roots.
	for p: Vector2i in [Vector2i(18, 36), Vector2i(26, 34), Vector2i(34, 33), Vector2i(42, 31), Vector2i(21, 25 + dy), Vector2i(37, 23 + dy)]:
		_px(canvas, p.x, p.y, Color("#5a9a48"))
		_px(canvas, p.x + 1, p.y, Color("#7cbc5a"))
	for p: Vector2i in [Vector2i(22, 32), Vector2i(38, 29), Vector2i(29, 25 + dy), Vector2i(10, 40), Vector2i(56, 39)]:
		_px(canvas, p.x, p.y, Color("#6ab04a"))
		_px(canvas, p.x + 1, p.y - 1, Color("#9ad86a"))
	if snug:
		for p: Vector2i in [Vector2i(14, 50), Vector2i(26, 51), Vector2i(42, 50), Vector2i(52, 48), Vector2i(34, 29)]:
			_flower(canvas, p, Color("#f4a0c0"), Color("#ffd24a"))
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), true, snug and st.attack < 0)

# --- Acorn line: Elder Stump -> Grove Heart, Dewcatcher -> Wellspring ---

# Elder Stump: a grumpy old stump golem: a cut top with growth rings, bushy eyebrows, a frown and
# bracket fungi on its side.
func _draw_elder_stump(canvas: Image, st: Dictionary) -> void:
	_stump_body(canvas, st, false)

# Grove Heart: the Elder Stump grown a leafy crown, a heart-knot glowing in its chest. Less grumpy.
func _draw_grove_heart(canvas: Image, st: Dictionary) -> void:
	_stump_body(canvas, st, true)

func _stump_body(canvas: Image, st: Dictionary, grove: bool) -> void:
	var dy: int = st.dy
	var fig := _pal("#22160e", "#b89a78", "#94785a", "#705a42")
	_draw_waystone(canvas, st, "leaf_litter", grove)
	if grove:
		# A young tree growing up from behind its shoulder.
		var trunk := _layer()
		_stroke(trunk, [Vector2(42, 26 + dy), Vector2(46, 16 + dy), Vector2(47, 9 + dy)], 1.8, Color("#7a5234"))
		_stamp(canvas, trunk, fig.o)
		_cloud(canvas, Vector2(48, 8 + dy), 24, _ramp(["#2a5a32", "#3f7a3e", "#6ab04a", "#9ad86a"]), Color("#14241a"))
	var mask := _draw_template_figure(canvas, st.pose, fig)
	for g: Array in [[Vector2(24, 24 + dy), Vector2(23, 31 + dy)], [Vector2(35, 25 + dy), Vector2(36, 32)], [Vector2(28, 36), Vector2(28, 40)]]:
		_line(canvas, g, fig.c, mask)
	for fungus: Rect2 in [Rect2(17, 29 + dy, 4, 2), Rect2(16, 34, 3.5, 1.8)]:
		var layer := _layer()
		_ellipse(layer, fungus.position, fungus.size, _ramp(["#a06030", "#d08a40", "#f0b060"]), fungus.position.y + 0.5)
		_stamp(canvas, layer, fig.o)
	var top := _layer()
	_flat_ellipse(top, Vector2(30.5, 6 + dy), Vector2(8.5, 2.6), Color("#d8b888"))
	_stamp(canvas, top, fig.o)
	_line(canvas, [Vector2(27, 6 + dy), Vector2(34, 6 + dy)], Color("#a88a60"))
	_px(canvas, 30, 6 + dy, Color("#8a6040"))
	if grove:
		_leaf(canvas, Vector2(32, 5 + dy), Vector2(37 + st.sway, 1 + dy), 2.2, _ramp(LEAF), fig.o)
		var heart := _layer()
		var bright: bool = st.f % 4 < 2 or st.power > 0.5
		_flat_ellipse(heart, Vector2(30, 27 + dy), Vector2(3, 3.5), Color("#b8f080") if bright else Color("#88d060"))
		_stamp(canvas, heart, fig.o)
		_px(canvas, 29, 26 + dy, Color("#f0ffe0"))
		_golem_face(canvas, st, fig)
		if st.attack < 0:
			var t: float = float(st.f) / st.n
			_px(canvas, 12 + roundi(sin(t * TAU) * 2), 8 + roundi(t * 20), Color("#6ab04a"))
	else:
		_leaf(canvas, Vector2(32, 5 + dy), Vector2(37 + st.sway, 1 + dy), 2.2, _ramp(LEAF), fig.o)
		_golem_face(canvas, st, fig, Color(0, 0, 0, 0), false)
		# Grumpy: bushy brows slanting down to the middle, and a frown.
		for p: Vector2i in [Vector2i(23, 9), Vector2i(24, 9), Vector2i(25, 10), Vector2i(26, 10), Vector2i(27, 10),
				Vector2i(35, 9), Vector2i(34, 9), Vector2i(33, 10), Vector2i(32, 10), Vector2i(31, 10)]:
			_px(canvas, p.x, p.y + dy, Color("#e8e0d0"))
		var my := EYE_TOP + 4 + dy
		_px(canvas, 27, my, fig.a)
		_px(canvas, 31, my, fig.a)
		_px(canvas, 27, my + 1, fig.o)
		_px(canvas, 31, my + 1, fig.o)

# Dewcatcher: an Acorn holding a curled leaf cup on its head, full of dew that glistens.
func _draw_dewcatcher(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal("#2a1a10", "#f0c080", "#d49c54", "#b07a3a")
	_draw_waystone(canvas, st, "leaf_litter")
	var mask := _draw_template_figure(canvas, st.pose, fig)
	for g: Array in [[Vector2(26, 24 + dy), Vector2(25, 30 + dy)], [Vector2(35, 26 + dy), Vector2(36, 31)]]:
		_line(canvas, g, fig.b, mask)
	_golem_face(canvas, st, fig)
	_leaf(canvas, Vector2(18, 6 + dy), Vector2(13, 1 + dy), 2.2, _ramp(LEAF), fig.o)
	_leaf(canvas, Vector2(43, 6 + dy), Vector2(48, 1 + dy), 2.2, _ramp(LEAF), fig.o)
	var cup := _layer()
	_ellipse(cup, Vector2(30.5, 6 + dy), Vector2(14, 4.5), _ramp(LEAF))
	_stamp(canvas, cup, Color("#1e3a24"))
	var water := _layer()
	_flat_ellipse(water, Vector2(30.5, 5 + dy), Vector2(11, 2.2), Color("#6ab0e8"))
	_line(water, [Vector2(24, 4 + dy), Vector2(34, 4 + dy)], Color("#bfe8ff"))
	_stamp(canvas, water)
	var glint: Vector2i = [Vector2i(19, 5), Vector2i(26, 3), Vector2i(35, 3), Vector2i(42, 5)][(st.f / 2) % 4]
	_sparkle(canvas, glint + Vector2i(0, dy), Color.WHITE)

# Wellspring: an Acorn with a little stone well on its head, a spring bubbling up out of it and
# spilling down its shoulders.
func _draw_wellspring(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal("#2a1a10", "#f0c080", "#d49c54", "#b07a3a")
	var water := Color("#8ad0f8")
	_draw_waystone(canvas, st, "leaf_litter", true)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	for g: Array in [[Vector2(26, 24 + dy), Vector2(25, 30 + dy)], [Vector2(35, 26 + dy), Vector2(36, 31)]]:
		_line(canvas, g, fig.b, mask)
	_golem_face(canvas, st, fig)
	# Water spilling over the shoulders.
	for side: int in [-1, 1]:
		for k in 5:
			var y: int = 9 + dy + ((k * 3 + st.f) % 12)
			var x: int = 30 + side * (10 + (y - 9 - dy) / 3)
			if mask.get_pixel(x, y).a > 0.0 and canvas.get_pixel(x, y) != fig.o:
				_px(canvas, x, y, water)
	var rim := _layer()
	_ellipse(rim, Vector2(30.5, 6 + dy), Vector2(10, 3.2), _ramp(["#6a5a4a", "#8a7a6a", "#b0a090", "#d0c4b4"]))
	_stamp(canvas, rim, fig.o)
	var pool := _layer()
	_flat_ellipse(pool, Vector2(30.5, 5.5 + dy), Vector2(7.5, 1.6), Color("#4a8ed0"))
	_stamp(canvas, pool)
	# The spring spouting up out of the well.
	var spout_h: int = 4 + (st.f % 2)
	for y in range(maxi(0, 5 + dy - spout_h), 5 + dy):
		_px(canvas, 30, y, water)
		_px(canvas, 31, y, Color("#e8faff"))
	for k in 4:
		var t: float = fmod(float(st.f) / st.n + k * 0.25, 1.0)
		var side := -1.0 if k % 2 == 0 else 1.0
		var p := Vector2(30.5 + side * t * 9.0, 5 + dy - sin(t * PI) * 6.0)
		if p.y >= 1.0:
			var bead := _layer()
			_flat_ellipse(bead, p, Vector2(1.6, 1.6), water)
			_stamp(canvas, bead, Color("#16305e"))

# --- Attack effects (evolved) -----------------------------------------------------------------

func _attack_bramble(canvas: Image, st: Dictionary) -> void:
	_pulse(canvas, st, Color("#f4a0c0"))
	var k: int = st.attack - RELEASE_FRAME
	if k >= 0 and k < 3:
		for d: Vector2 in [Vector2(-1, -0.4), Vector2(1, -0.5), Vector2(-0.6, 0.6), Vector2(0.7, 0.5)]:
			var p := Vector2(31, 40) + d * (12 + k * 6)
			_px(canvas, int(p.x), int(p.y), Color("#f4a0c0"))
			_px(canvas, int(p.x) + 1, int(p.y), Color("#ffd0e0"))

func _attack_driftspore(canvas: Image, st: Dictionary) -> void:
	_blow(canvas, st, Color(LAVENDER[1]), Color(LAVENDER[0]), Color("#f0eaff"))
	_burst(canvas, Vector2(ATTACKS["driftspore"].point), st.attack, Color("#f0eaff"), Color("#b4a0ee"), Color(LAVENDER[0]))

func _attack_puffball(canvas: Image, st: Dictionary) -> void:
	_blow(canvas, st, Color(LAVENDER[1]), Color(LAVENDER[0]), Color("#f6eedc"))
	_burst(canvas, Vector2(ATTACKS["puffball"].point), st.attack, Color("#f6eedc"), Color("#c8b898"), Color(LAVENDER[0]))
	if st.attack == RELEASE_FRAME or st.attack == RELEASE_FRAME + 1:
		var r: float = 6.0 + (st.attack - RELEASE_FRAME) * 3.0
		for c: Vector2 in [Vector2(17, 22), Vector2(52, 31)]:
			for k in 5:
				var d := Vector2.from_angle(k * TAU / 5.0) * r
				_px(canvas, roundi(c.x + d.x), roundi(c.y + d.y), Color("#f6eedc"))

# A cloud puffed out on release that swells and thins as it drifts.
func _cloud_puff(canvas: Image, st: Dictionary, at: Vector2, ramp: Array[Color], o: Color, mist: Color) -> void:
	var k: int = st.attack - RELEASE_FRAME
	if k == 0:
		_cloud(canvas, at, 10, ramp, o)
		_warm_glow(canvas, at, Vector2(8, 6))
	elif k == 1:
		_cloud(canvas, at + Vector2(3, 3), 14, ramp, o)
		_warm_glow(canvas, at + Vector2(3, 3), Vector2(10, 7), 1)
	elif k == 2:
		_fog(canvas, at + Vector2(5, 5), Vector2(9, 5), mist, st.f)

func _attack_bloomcap(canvas: Image, st: Dictionary) -> void:
	_cloud_puff(canvas, st, Vector2(ATTACKS["bloomcap"].point), _ramp(["#b8a8d8", "#e0d4f4", "#f8f0ff"]), Color("#5a4a7a"), Color("#e0d4f4"))
	if st.attack == RELEASE_FRAME + 1:
		_glyph(canvas, Vector2i(56, 6), Z_GLYPH, Color("#f8f0ff"))

func _attack_dreamshroom(canvas: Image, st: Dictionary) -> void:
	_cloud_puff(canvas, st, Vector2(ATTACKS["dreamshroom"].point), _ramp(["#5a50c0", "#8a80e8", "#c8c0ff"]), Color("#140c30"), Color("#c8c0ff"))
	var k: int = st.attack - RELEASE_FRAME
	if k >= 0 and k < 3:
		for p: Vector2i in [Vector2i(56, 8), Vector2i(60, 20), Vector2i(46, 26)]:
			_sparkle(canvas, p + Vector2i(k, -k), Color("#fff4c0"))

func _attack_mossback(canvas: Image, st: Dictionary) -> void:
	_throw(canvas, st, Vector2(ATTACKS["mossback"].point), 4.5, _ramp(["#5a7a4a", "#7aa05a", "#a8c878", "#d8ecb0"]), Color("#1c1c36"))

func _attack_boulderback(canvas: Image, st: Dictionary) -> void:
	_throw(canvas, st, Vector2(ATTACKS["boulderback"].point), 6.0, _ramp(STONE), Color("#1c1c36"))

func _attack_chime_stone(canvas: Image, st: Dictionary) -> void:
	_pulse(canvas, st, Color("#c8b0f0"))
	var k: int = st.attack - RELEASE_FRAME
	if k >= 1 and k < 4:
		_glyph(canvas, Vector2i(8, 14 - k * 3), NOTE_GLYPH, Color("#e0c8ff"))
		_glyph(canvas, Vector2i(52, 12 - k * 3), NOTE_GLYPH, Color("#ffe890"))

func _attack_lullaby_bell(canvas: Image, st: Dictionary) -> void:
	_pulse(canvas, st, Color("#c8b0f0"))
	var k: int = st.attack - RELEASE_FRAME
	if k >= 1 and k < 4:
		_glyph(canvas, Vector2i(7, 14 - k * 3), NOTE_GLYPH, Color("#ffe08a"))
		_glyph(canvas, Vector2i(53, 12 - k * 3), Z_GLYPH, Color("#ece0ff"))

func _attack_rain_lily(canvas: Image, st: Dictionary) -> void:
	var a: int = st.attack
	if a == RELEASE_FRAME:
		for d: Vector3 in [Vector3(22, 3, 1.9), Vector3(39, 3, 1.9)]:
			var spout := _layer()
			_flat_ellipse(spout, Vector2(d.x, d.y), Vector2(d.z, d.z), Color("#e8faff"))
			_stamp(canvas, spout, Color(WATER[0]))
		_warm_glow(canvas, Vector2(30.5, 3), Vector2(13, 5))
	if a > RELEASE_FRAME:
		var k: int = a - RELEASE_FRAME
		for side: int in [-1, 1]:
			var bead := _layer()
			_flat_ellipse(bead, Vector2(30.5 + side * (10 + k * 4), 3 + k * k * 1.5), Vector2(2, 2), Color(WATER[1]))
			_stamp(canvas, bead, Color(WATER[0]))

func _attack_monsoon(canvas: Image, st: Dictionary) -> void:
	_pulse(canvas, st, Color("#8ad0f8"))
	if st.attack >= RELEASE_FRAME - 1 and st.attack <= RELEASE_FRAME + 2:
		_rain(canvas, st, 9, Color("#fff0c0"))  # warm-lit rain
		var shifted := st.duplicate()
		shifted.f = st.f + 3
		_rain(canvas, shifted, 9, GLOW_INNER)

func _attack_mistveil(canvas: Image, st: Dictionary) -> void:
	_fog_roll(canvas, st, Color("#fff2d8"))

func _attack_morning_fog(canvas: Image, st: Dictionary) -> void:
	_fog_roll(canvas, st, Color("#ffe4c0"))
	var k: int = st.attack - RELEASE_FRAME
	if k >= 0 and k < 3:
		_sparkle(canvas, Vector2i(14 + k * 3, 46 - k), Color("#ffe8a0"))
		_glyph(canvas, Vector2i(52, 14 - k * 3), Z_GLYPH, Color("#fff2ea"))

# Fog rolling out over the path in front of it.
func _fog_roll(canvas: Image, st: Dictionary, mist: Color) -> void:
	var k: int = st.attack - RELEASE_FRAME
	if k >= 0 and k < 3:
		var c := Vector2(ATTACKS["mistveil"].point) + Vector2(0, 4)
		_fog(canvas, c, Vector2(12 + k * 7, 4 + k * 2), mist, st.f)

func _attack_stormcap(canvas: Image, st: Dictionary) -> void:
	var a: int = st.attack
	var from := Vector2(ATTACKS["stormcap"].point)
	if a == RELEASE_FRAME - 1:
		_sparkle(canvas, Vector2i(from), Color("#fff6a0"))
	elif a == RELEASE_FRAME:
		_bolt(canvas, from, Vector2(62, 22), Color("#fff6a0"), GLOW_OUTER)
	elif a == RELEASE_FRAME + 1:
		_bolt(canvas, from, Vector2(56, 14), Color("#fff0c0"), Color("#d8a040"), 3)

func _attack_thunderhead(canvas: Image, st: Dictionary) -> void:
	var a: int = st.attack
	var from := Vector2(ATTACKS["thunderhead"].point)
	if a == RELEASE_FRAME - 1:
		_sparkle(canvas, Vector2i(from), Color("#fff6a0"))
		_sparkle(canvas, Vector2i(18, 5), Color("#fff6a0"))
	elif a == RELEASE_FRAME:
		_bolt(canvas, from, Vector2(63, 24), Color("#fff6a0"), GLOW_OUTER, 5)
		_bolt(canvas, Vector2(17, 5), Vector2(1, 22), Color("#fff6a0"), GLOW_OUTER, 5)
	elif a == RELEASE_FRAME + 1:
		_bolt(canvas, from, Vector2(58, 16), Color("#fff0c0"), Color("#d8a040"), 3)

# A flash of light from `c` scattering into sparks.
func _flash(canvas: Image, st: Dictionary, c: Vector2, core: Color, halo: Color) -> void:
	var a: int = st.attack
	if a == RELEASE_FRAME:
		for k in 8:
			var d := Vector2.from_angle(k * TAU / 8.0) * (3.5 if k % 2 == 0 else 5.5)
			_glow_dot(canvas, Vector2i((c + d).round()), core, halo)
		_glow_dot(canvas, Vector2i(c), Color.WHITE, core)
		_warm_glow(canvas, c, Vector2(9, 8))
	elif a == RELEASE_FRAME + 1 or a == RELEASE_FRAME + 2:
		var radius := 8.0 if a == RELEASE_FRAME + 1 else 11.0
		for k in 5:
			var d := Vector2.from_angle(k * TAU / 5.0 - 0.3) * radius
			_px(canvas, roundi(c.x + d.x), roundi(c.y + d.y), core if a == RELEASE_FRAME + 1 else halo)

func _attack_lanternmoth(canvas: Image, st: Dictionary) -> void:
	_flash(canvas, st, Vector2(ATTACKS["lanternmoth"].point), Color("#fff0b0"), Color("#f0b060"))

func _attack_beacon(canvas: Image, st: Dictionary) -> void:
	_pulse(canvas, st, Color("#ffe08a"))
	if st.attack == RELEASE_FRAME:
		for k in 12:
			var d := Vector2.from_angle(k * TAU / 12.0)
			_line(canvas, [Vector2(30.5, 7) + d * 9.0, Vector2(30.5, 7) + d * 20.0], Color("#fffbe0"))

# A sunbeam from the seed-disc face, thick on release and thinning out.
func _attack_sunpetal(canvas: Image, st: Dictionary) -> void:
	var k: int = st.attack - RELEASE_FRAME
	var from := Vector2(ATTACKS["sunpetal"].point)
	if k < 0 or k > 2:
		return
	var to := Vector2(63, from.y - 3)
	for w in range(-(2 - k), 3 - k):
		_line(canvas, [from + Vector2(0, w), to + Vector2(0, w)], Color("#fff4a0") if w == 0 else Color("#ffd24a"))
	_sparkle(canvas, Vector2i(from), Color.WHITE)
	for t in [0.25, 0.6, 0.95]:
		_warm_glow(canvas, from.lerp(to, t), Vector2(6, 5 - k), k)

# Lashes a curling root out to hook a creature, then reels it back in.
func _root_lash(canvas: Image, st: Dictionary, fig: Dictionary, sparkly: bool) -> void:
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 1:
		return
	var tip := Vector2(ATTACKS["rootcurl"].point) if k == 0 else Vector2(54, 28)
	var layer := _layer()
	_stroke(layer, [Vector2(42, 24), Vector2(50, 25), tip], 1.3, fig.a)
	_stroke(layer, [tip, tip + Vector2(1.5, 2), tip + Vector2(-0.5, 3.5), tip + Vector2(-2, 2.5)], 1.0, fig.a)
	_stamp(canvas, layer, fig.o)
	_warm_glow(canvas, tip, Vector2(6, 5))  # the hook glows as it catches
	if sparkly:
		_sparkle(canvas, Vector2i(tip) + Vector2i(2, -3), Color("#fff4c0"))

func _attack_rootcurl(canvas: Image, st: Dictionary) -> void:
	_root_lash(canvas, st, _pal(BARK[0], BARK[1], BARK[2], BARK[3]), false)

func _attack_long_way_home(canvas: Image, st: Dictionary) -> void:
	_root_lash(canvas, st, _pal(BARK[0], BARK[1], BARK[2], BARK[3]), true)

# Roots spiking up out of the ground round the stump, then sinking back.
func _root_spikes(canvas: Image, st: Dictionary, spots: Array, flowers: bool) -> void:
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	var h: int = [4, 7, 3][k]
	var layer := _layer()
	for p: Vector2 in spots:
		_stroke(layer, [p, p + Vector2(1, -h)], 1.1, Color("#9a7a54"))
	_stamp(canvas, layer, Color("#1e160e"))
	for p: Vector2 in spots:
		_warm_glow(canvas, p + Vector2(1, -h), Vector2(4, 3), k)
	if flowers and k == 1:
		for p: Vector2 in spots:
			_flower(canvas, Vector2i(p) + Vector2i(1, -h - 1), Color("#f4a0c0"), Color("#ffd24a"))

func _attack_tangleroot(canvas: Image, st: Dictionary) -> void:
	_root_spikes(canvas, st, [Vector2(6, 48), Vector2(58, 46), Vector2(20, 55), Vector2(44, 55)], false)

func _attack_snugroot(canvas: Image, st: Dictionary) -> void:
	_root_spikes(canvas, st, [Vector2(4, 46), Vector2(60, 45), Vector2(14, 53), Vector2(50, 53), Vector2(31, 58)], true)

func _attack_elder_stump(canvas: Image, st: Dictionary) -> void:
	_pulse(canvas, st, Color("#b8f080"))

func _attack_grove_heart(canvas: Image, st: Dictionary) -> void:
	_pulse(canvas, st, Color("#b8f080"))
	var k: int = st.attack - RELEASE_FRAME
	if k >= 0 and k < 3:
		for p: Vector2i in [Vector2i(10, 14), Vector2i(52, 12), Vector2i(6, 26), Vector2i(56, 26)]:
			_px(canvas, p.x + k, p.y + k * 3, Color("#6ab04a"))
			_px(canvas, p.x + k + 1, p.y + k * 3, Color("#9ad86a"))

# --- Projectiles (evolved) --------------------------------------------------------------------

func _proj_boulder(canvas: Image, f: int) -> void:
	_spinning_rock(canvas, f, 7.0, _ramp(STONE), Color("#1c1c36"))
	_px(canvas, 30, 28, Color("#7cbc5a"))
	_px(canvas, 31, 28, Color("#7cbc5a"))

# A warm orb of lantern light with a flickering halo and a short trail.
func _proj_light_orb(canvas: Image, f: int) -> void:
	var halo: float = 4.5 + [0.0, 0.8, 0.3, 1.0][f]
	for y in S:
		for x in S:
			var q := Vector2(x + 0.5, y + 0.5).distance_to(Vector2(34, 32))
			if q < halo and q >= 3.0 and (x + y + f) % 2 == 0:
				canvas.set_pixel(x, y, Color("#f8d890"))
	var core := _layer()
	_flat_ellipse(core, Vector2(34, 32), Vector2(3, 3), Color("#fff0b0"))
	_stamp(canvas, core, Color("#c8864a"))
	_px(canvas, 33, 31, Color.WHITE)
	_px(canvas, 34, 31, Color.WHITE)
	for k in 3:
		_px(canvas, 27 - k * 2, 32 + ((k + f) % 2), Color("#fff0b0") if k == 0 else Color("#f0b060"))

# --- New Wardens (tower_design.md, 2026-09-27) ------------------------------------------------
# Hidden branches, the Nestling (wing) and Whirligig (wind) lines, Honeysuckle, and the Memory
# Wardens freed from the act bosses.

const MEMORY_GOLD := Color("#f0c860")

# Waystone themes for the new lines.
func _decor_nest(canvas: Image, top: Image, _side: Image, _st: Dictionary, lush: bool) -> void:
	var twigs := [Color("#5a4228"), Color("#8a6a40"), Color("#b08a50")]
	for y in S:
		for x in S:
			if not _on(top, x, y):
				continue
			var u := x * 0.5 + y
			var v := x * 0.5 - y
			var col: Color = twigs[1]
			if fposmod(u, 3.0) < 1.0:
				col = twigs[2] if (x + y) % 3 else twigs[0]
			elif fposmod(v, 3.0) < 1.0:
				col = twigs[0]
			if (x * 31 + y * 17) % 13 == 0:
				col = Color("#e0c070")  # straw
			canvas.set_pixel(x, y, col)
	var eggs: Array = [Vector2i(9, 42), Vector2i(54, 43)] if lush else [Vector2i(54, 43)]
	for e: Vector2i in eggs:
		if _on(top, e.x, e.y):
			var egg := _layer()
			_ellipse(egg, Vector2(e), Vector2(2, 2.6), _ramp(["#8ab8c8", "#b8e0ec", "#e8f8fc"]))
			_stamp(canvas, egg, Color("#2a1a10"))
			_px(canvas, e.x - 1, e.y - 1, Color("#5a8898"))

func _decor_windswept(canvas: Image, top: Image, _side: Image, st: Dictionary, lush: bool) -> void:
	for y in S:
		for x in S:
			if not _on(top, x, y):
				continue
			var h := (x * 29 + y * 53) % 9
			var streak: bool = (x + 2 * y + st.f) % 11 == 0
			canvas.set_pixel(x, y, Color("#b8e0a0") if streak else (Color("#8ad060") if h == 0 else (Color("#3f7a3e") if h == 4 else Color("#5a9a48"))))
	var seeds: Array = OPEN_SPOTS.slice(0, 7 if lush else 4)
	for p: Vector2i in seeds:
		if _on(top, p.x, p.y):
			_px(canvas, p.x, p.y, Color("#8a5a2a"))
			_px(canvas, p.x + 1, p.y - 1, Color("#e0a860"))
			_px(canvas, p.x + 2, p.y - 1, Color("#f0c890"))

# Pale moonlit stone with a glowing gold rune circle, for the Memory Wardens.
func _decor_memory(canvas: Image, top: Image, _side: Image, st: Dictionary, _lush: bool) -> void:
	_patches(canvas, top, MOSS_BLOBS, _ramp(["#4a8a5a", "#6aaa6a", "#9ad88a"]))
	var bright: bool = st.f % 4 < 2 or st.power > 0.5
	for y in S:
		for x in S:
			if not _on(top, x, y):
				continue
			var q := ((Vector2(x + 0.5, y + 0.5) - Vector2(31.5, 45)) / Vector2(26, 9.5)).length()
			if absf(q - 1.0) < 0.05 or (absf(q - 0.82) < 0.04 and (x + y) % 2 == 0):
				canvas.set_pixel(x, y, MEMORY_GOLD if bright else Color("#c8a048"))
	for k in 6:
		var p := Vector2i((Vector2(31.5, 45) + Vector2.from_angle(k * TAU / 6.0 + 0.5) * Vector2(26, 9.5)).round())
		if _on(top, p.x, p.y):
			_glow_dot(canvas, p, Color("#fff8d8"), MEMORY_GOLD)

# A small bird: body, head, wing (up or down), tail, beak. `face` = 1 faces right, -1 left.
func _bird(canvas: Image, p: Vector2, face: int, body: Array[Color], o: Color, wing_up: bool, beak: Color = Color("#e8a040"), s: float = 1.6) -> void:
	var layer := _layer()
	_ellipse(layer, p, Vector2(2.8, 2.2) * s, body)
	_ellipse(layer, p + Vector2(face * 2.4, -1.6) * s, Vector2(1.8, 1.7) * s, body)
	_flat_polygon(layer, PackedVector2Array([p + Vector2(-face * 2, -0.5) * s, p + Vector2(-face * 5, -2) * s, p + Vector2(-face * 4.5, 1) * s]), body[0])
	_stamp(canvas, layer, o)
	var wing := _layer()
	var wc := p + Vector2(-face * 0.5, -2.5 if wing_up else 0.5) * s
	_flat_ellipse(wing, wc, Vector2(2.2, 1.4) * s, body[0])
	_stamp(canvas, wing, o)
	var head := p + Vector2(face * 2.4, -1.6) * s
	var beak_p := head + Vector2(face * 1.9 * s, 0)
	_px(canvas, roundi(beak_p.x), roundi(beak_p.y), beak)
	_px(canvas, roundi(beak_p.x + face), roundi(beak_p.y), beak)
	_px(canvas, roundi(head.x + face * 0.5), roundi(head.y - 0.5), o)

# Spinning blades (whirligig seeds, pinwheel, windmill sails) round `c` at `angle`.
func _blades(canvas: Image, c: Vector2, n: int, r: float, angle: float, width: float, ramp: Array[Color], o: Color) -> void:
	for k in n:
		var d := Vector2.from_angle(angle + k * TAU / n)
		_leaf(canvas, c + d * 1.5, c + d * r, width, ramp, o)
	var hub := _layer()
	_flat_ellipse(hub, c, Vector2(1.6, 1.6), ramp[0])
	_stamp(canvas, hub, o)

# Faceted crystal pointing up (Starcave, frost).
func _prism(canvas: Image, base: Vector2, w: float, h: float, lean: float, ramp: Array[Color], o: Color) -> void:
	var tip := base + Vector2(lean, -h)
	var pts := PackedVector2Array([base + Vector2(-w, 0), base + Vector2(-w + lean * 0.7, -h * 0.7), tip,
		base + Vector2(w + lean * 0.7, -h * 0.7), base + Vector2(w, 0)])
	var layer := _layer()
	for y in S:
		for x in S:
			var p := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(p, pts):
				var rel := p.x - (base.x + (base.y - p.y) / h * lean)
				layer.set_pixel(x, y, ramp[0] if rel < -w / 3.0 else (ramp[2] if rel > w / 3.0 else ramp[1]))
	_stamp(canvas, layer, o)

func _wisp(canvas: Image, from: Vector2, t: float, color: Color) -> void:
	for k in 4:
		var s := t * 10.0 + k * 1.5
		_px(canvas, roundi(from.x + sin(s * 0.9) * 2.5 + k * 0.5), roundi(from.y - s), color)

# --- Hidden branches ---

# Fairy Ring: the Sporeling in a crown of little mushrooms, fairy lights drifting round it.
func _draw_fairy_ring(canvas: Image, st: Dictionary) -> void:
	_fairy_body(canvas, st, false)

# Elf Circle: Fairy Ring with a pointed leaf cap, glowing mushrooms and more lights.
func _draw_elf_circle(canvas: Image, st: Dictionary) -> void:
	_fairy_body(canvas, st, true)

func _fairy_body(canvas: Image, st: Dictionary, elf: bool) -> void:
	var dy: int = st.dy
	var fig := _pal("#17174d", "#ed9df2", "#de73e5", "#ba41d9")
	_draw_waystone(canvas, st, "fairy_ring", elf)
	_draw_template_figure(canvas, st.pose, fig)
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), false)
	var cap := Color("#7ff0e0") if elf else Color("#fff0c8")
	for k in 4:
		var x := 23 + k * 5
		var y := 5 + dy + (1 if k == 0 or k == 3 else 0)
		for sy in [1, 2]:
			_px(canvas, x, y + sy, Color("#f0e4d8"))
		for dx in [-2, -1, 0, 1, 2]:
			_px(canvas, x + dx, y, fig.o)
		for dx in [-1, 0, 1]:
			_px(canvas, x + dx, y - 1, cap)
			_px(canvas, x + dx, y, cap)
		_px(canvas, x, y - 2, fig.o)
		_px(canvas, x - 1, y - 1, cap.lightened(0.35))
	if elf:
		_leaf(canvas, Vector2(30.5, 6 + dy), Vector2(36 + st.sway, -2), 4.0, _ramp(LEAF), fig.o)
	for k in (6 if elf else 4):
		var a: float = TAU * float(st.f) / st.n + k * TAU / (6 if elf else 4)
		var p := Vector2i((Vector2(31, 22) + Vector2(cos(a) * 22.0, sin(a) * 9.0 - 6)).round())
		if (st.f + k) % 3 != 0:
			_glow_dot(canvas, p, Color("#fffbe0"), Color("#9ff0d0") if elf else Color("#ffd8f0"))

# Standing Stone: a sniper with a tall carved menhir on its back and a holed stone for a scope.
func _draw_standing_stone(canvas: Image, st: Dictionary) -> void:
	_menhir_body(canvas, st, false)

# Moonstone: Standing Stone gone silver, a glowing moon on its menhir.
func _draw_moonstone(canvas: Image, st: Dictionary) -> void:
	_menhir_body(canvas, st, true)

func _menhir_body(canvas: Image, st: Dictionary, moon: bool) -> void:
	var dy: int = st.dy
	var fig := _pal("#1c1c36", "#dcdcf4", "#b4b4dc", "#8a8ab8") if moon else _pal("#1c1c36", "#c4c9e2", "#979dc2", "#686d9a")
	var rune := Color("#bfe8ff") if moon else Color("#ffd870")
	if st.power > 0.5 or st.f % 4 < 2:
		rune = rune.lightened(0.3)
	_draw_waystone(canvas, st, "cobble", moon)
	var stone := _layer()
	_flat_polygon(stone, PackedVector2Array([Vector2(7, 40), Vector2(7, 12), Vector2(11, 5), Vector2(17, 7), Vector2(19, 14), Vector2(18, 40)]), fig.b)
	for y in S:
		for x in S:
			if stone.get_pixel(x, y).a > 0.0 and x < 10:
				stone.set_pixel(x, y, fig.a)
			elif stone.get_pixel(x, y).a > 0.0 and x > 16:
				stone.set_pixel(x, y, fig.c)
	_stamp(canvas, stone, fig.o)
	_line(canvas, [Vector2(12, 13), Vector2(14, 15), Vector2(12, 18), Vector2(10, 16), Vector2(12, 14)], rune, stone)
	_line(canvas, [Vector2(12, 23), Vector2(12, 32)], rune, stone)
	if moon:
		var orb := _layer()
		_ellipse(orb, Vector2(12.5, 4), Vector2(3.5, 3.5), _ramp(["#8ab0e0", "#c8e0ff", "#f4f8ff"]))
		_stamp(canvas, orb, fig.o)
		_px(canvas, 11, 3, Color.WHITE)
		for k in 3:
			if (st.f + k) % 3 == 0:
				_sparkle(canvas, [Vector2i(56, 6), Vector2i(36, 2), Vector2i(58, 18)][k], Color("#e8f0ff"))
	var mask := _draw_template_figure(canvas, st.pose, fig)
	_line(canvas, [Vector2(21, 30), Vector2(23, 33), Vector2(22, 35)], fig.c, mask)
	_line(canvas, [Vector2(34, 36), Vector2(35, 39)], fig.c, mask)
	_golem_face(canvas, st, fig)
	# Holed stone held up to one eye like a scope.
	var scope := _layer()
	_ellipse(scope, Vector2(33, 12 + dy), Vector2(3.2, 3.2), _ramp(STONE))
	_flat_ellipse(scope, Vector2(33, 12 + dy), Vector2(1.3, 1.3), Color(0, 0, 0, 0))
	_stamp(canvas, scope, fig.o)
	_px(canvas, 33, 12 + dy, rune)

# Frostfern: a frosted water golem with frost-tipped fern fronds, snowflakes drifting.
func _draw_frostfern(canvas: Image, st: Dictionary) -> void:
	_frost_body(canvas, st, false)

# Hoarfrost: Frostfern deep in winter: a crown of ice, icicles, crystals on the stone.
func _draw_hoarfrost(canvas: Image, st: Dictionary) -> void:
	_frost_body(canvas, st, true)

func _frost_body(canvas: Image, st: Dictionary, deep: bool) -> void:
	var dy: int = st.dy
	var fig := _pal("#16305e", "#f0faff", "#c8e4f8", "#98bce0") if deep else _pal("#16305e", "#d8f0ff", "#a8d4f4", "#78a8dc")
	var fern := _ramp(["#4a8a9a", "#8ad0d8", "#e0fcff"])
	var ice := _ramp(["#6aa8e0", "#b4e4ff", "#f4fcff"])
	_draw_waystone(canvas, st, "pond", deep)
	for c: Vector3 in [Vector3(9, 45, 4), Vector3(55, 44, 5)]:
		_prism(canvas, Vector2(c.x, c.y), 2.0, c.z + (2 if deep else 0), 0.5, ice, fig.o)
	_leaf(canvas, Vector2(24, 9 + dy), Vector2(15 + st.sway, 0), 3.2, fern, fig.o)
	_leaf(canvas, Vector2(37, 9 + dy), Vector2(46 + st.sway, 1), 3.2, fern, fig.o)
	_leaf(canvas, Vector2(42, 22 + dy), Vector2(52 + st.sway, 12 + dy), 3.0, fern, fig.o)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	_water_gloss(canvas, mask, st, fig)
	_golem_face(canvas, st, fig, Color("#4aa0e0"))
	if deep:
		for k in 5:
			_prism(canvas, Vector2(23 + k * 4, 7 + dy), 1.5, 4 + (k % 2) * 3, 0.0, ice, fig.o)
		for x in [21, 24, 40, 43]:
			_line(canvas, [Vector2(x, 20 + dy), Vector2(x, 23 + dy + (x % 2))], ice[2])
	for k in 3:
		var t: float = float((st.f + k * 3) % st.n) / st.n
		var p := Vector2i(roundi([12, 50, 40][k] + sin(t * TAU) * 1.5), roundi(2 + t * 16))
		_glyph(canvas, p, [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)], Color("#f4fcff"))

# Midsummer: Sunpetal at the height of summer: a double ring of petals, a sun halo, fireflies.
func _draw_midsummer(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal("#1e3a14", "#c8e888", "#9ccc60", "#6aa03a")
	var face_c := Vector2(30.5, 11.5 + dy)
	_draw_waystone(canvas, st, "meadow", true)
	var halo := _layer()
	_flat_ellipse(halo, face_c, Vector2(17, 16), Color("#fff0a0"))
	for y in S:
		for x in S:
			if halo.get_pixel(x, y).a > 0.0 and (x + y + st.f) % 3 != 0:
				halo.set_pixel(x, y, Color(0, 0, 0, 0))
	_stamp(canvas, halo)
	_petals(canvas, face_c, 14, 9.0, 16.0 - st.lift * 0.5, 2.6, _ramp(["#e07a20", "#f0a030", "#ffc860"]), fig.o, float(st.f) * TAU / 128.0 + 0.2)
	_petals(canvas, face_c, 12, 6.5, 13.0 - st.lift * 0.5, 2.6, _ramp(["#d89a20", "#f0c030", "#ffe070"]), fig.o, float(st.f) * TAU / 96.0)
	_leaf(canvas, Vector2(18, 31), Vector2(8, 24), 3.2, _ramp(LEAF), fig.o)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	for y in S:
		for x in S:
			if ((Vector2(x + 0.5, y + 0.5) - face_c) / Vector2(8.5, 6.5)).length() < 1.0 and mask.get_pixel(x, y).a > 0.0 and canvas.get_pixel(x, y) != fig.o:
				canvas.set_pixel(x, y, Color("#8a5a2a") if (x + y) % 2 == 0 else Color("#6a4020"))
	_leaf(canvas, Vector2(43, 30), Vector2(53, 23), 3.2, _ramp(LEAF), fig.o)
	_golem_face(canvas, st, fig, Color("#ffe070"), false)
	for k in 3:
		var a: float = TAU * float(st.f) / st.n + k * 2.1
		_glow_dot(canvas, Vector2i((Vector2(31, 30) + Vector2(cos(a) * 26.0, sin(a) * 10.0)).round()), Color("#fff27a"), Color("#c8e060"))

# Rootlight: a Rootling whose roots glow gold from inside, lighting the stump around it.
func _draw_rootlight(canvas: Image, st: Dictionary) -> void:
	_rootlight_body(canvas, st, false)

# Starcave: Rootlight carrying a little geode cave of glowing crystals on its back, stars round it.
func _draw_starcave(canvas: Image, st: Dictionary) -> void:
	_rootlight_body(canvas, st, true)

func _rootlight_body(canvas: Image, st: Dictionary, cave: bool) -> void:
	var dy: int = st.dy
	var fig := _pal("#1e120a", "#a8805a", "#86603e", "#664628")
	var glow := Color("#ffe890") if st.f % 4 < 2 or st.power > 0.5 else Color("#f0c860")
	_draw_waystone(canvas, st, "stump", cave)
	if cave:
		var geode := _layer()
		_ellipse(geode, Vector2(14, 22 + dy), Vector2(9, 8), _ramp(["#3a3050", "#5a4a70", "#7a6a90"]))
		_stamp(canvas, geode, fig.o)
		var gems := _ramp(["#8a60d0", "#c0a0ff", "#f0e8ff"])
		for c: Vector3 in [Vector3(10, 25, 5), Vector3(14, 24, 8), Vector3(18, 26, 4)]:
			_prism(canvas, Vector2(c.x, c.y + dy), 1.6, c.z, 0.3, gems, fig.o)
	var roots := _layer()
	for root: Array in [[Vector2(16, 44), Vector2(10, 46), Vector2(5, 44)], [Vector2(27, 47), Vector2(25, 53)],
			[Vector2(40, 48), Vector2(46, 52), Vector2(53, 50)], [Vector2(52, 42), Vector2(57, 41), Vector2(61, 42)]]:
		_stroke(roots, root, 1.6, fig.b)
	_stamp(canvas, roots, fig.o)
	for root: Array in [[Vector2(14, 45), Vector2(7, 45)], [Vector2(26, 49), Vector2(25, 52)], [Vector2(43, 50), Vector2(51, 50)], [Vector2(55, 41), Vector2(60, 42)]]:
		_line(canvas, root, glow, roots)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	for vein: Array in [[Vector2(24, 25 + dy), Vector2(26, 30 + dy), Vector2(24, 35)], [Vector2(33, 22 + dy), Vector2(35, 28 + dy), Vector2(33, 33)],
			[Vector2(28, 36), Vector2(30, 41)], [Vector2(17, 39), Vector2(21, 42)]]:
		_line(canvas, vein, glow, mask)
	_leaf(canvas, Vector2(30, 5 + dy), Vector2(21 + st.sway, 1 + dy), 3.2, _ramp(LEAF), fig.o)
	_leaf(canvas, Vector2(31, 5 + dy), Vector2(41 + st.sway, 0 + dy), 3.6, _ramp(LEAF), fig.o)
	_golem_face(canvas, st, fig, glow, false)
	if cave:
		for k in 4:
			if (st.f + k) % 2 == 0:
				_sparkle(canvas, [Vector2i(8, 12), Vector2i(56, 6), Vector2i(12, 26), Vector2i(58, 30)][k], Color("#f0e8ff"))

# Graftling: an Acorn with a sapling grafted onto its head (bound with twine) and a patched body,
# ready to borrow a neighbour's knack.
func _draw_graftling(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal("#2a1a10", "#f0c080", "#d49c54", "#b07a3a")
	var shell := _ramp(["#4a3018", "#6a4828", "#8a6440", "#a88258"])
	_draw_waystone(canvas, st, "leaf_litter")
	var mask := _draw_template_figure(canvas, st.pose, fig)
	# Graft seams: a stitched line across the body.
	_line(canvas, [Vector2(20, 30), Vector2(28, 28 + dy), Vector2(36, 31), Vector2(43, 29)], fig.c, mask)
	for x in [22, 26, 30, 34, 38, 42]:
		_skin_px(canvas, mask, fig.o, [Vector2i(x, 29 + (x % 3) - 1 + (dy if x < 36 else 0)), Vector2i(x, 31 + (x % 3) - 1)], Color("#e8d8b0"))
	_golem_face(canvas, st, fig)
	var cap := _layer()
	_ellipse(cap, Vector2(30.5, 10 + dy), Vector2(12.5, 7), shell, 10.5 + dy)
	_stamp(canvas, cap, fig.o)
	_graft(canvas, st, Vector2(31, 5 + dy), [_ramp(LEAF)], fig.o)
	_graft(canvas, st, Vector2(43, 19 + dy), [_ramp(["#c05080", "#f090b8", "#ffd0e4"])], fig.o)  # a blossom sprig grafted on its shoulder

# Grafted Elder: the Elder Stump grown into a many-grafted tree: branches of blossom, oak and gold.
func _draw_grafted_elder(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal("#22160e", "#b89a78", "#94785a", "#705a42")
	_draw_waystone(canvas, st, "leaf_litter", true)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	for g: Array in [[Vector2(24, 24 + dy), Vector2(23, 31 + dy)], [Vector2(35, 25 + dy), Vector2(36, 32)]]:
		_line(canvas, g, fig.c, mask)
	var top := _layer()
	_flat_ellipse(top, Vector2(30.5, 6 + dy), Vector2(8.5, 2.6), Color("#d8b888"))
	_stamp(canvas, top, fig.o)
	_golem_face(canvas, st, fig)
	_graft(canvas, st, Vector2(25, 4 + dy), [_ramp(["#c05080", "#f090b8", "#ffd0e4"])], fig.o)
	_graft(canvas, st, Vector2(31, 3 + dy), [_ramp(LEAF)], fig.o)
	_graft(canvas, st, Vector2(37, 4 + dy), [_ramp(["#b87a20", "#e8b040", "#ffe080"])], fig.o)

# A grafted sprig: a twine-bound stub with a leaf of each given colour.
func _graft(canvas: Image, st: Dictionary, at: Vector2, leaves: Array, o: Color) -> void:
	var stem := _layer()
	_stroke(stem, [at + Vector2(0, 3), at + Vector2(0, -3)], 1.4, Color("#7a5234"))
	_stamp(canvas, stem, o)
	_px(canvas, int(at.x) - 1, int(at.y) + 1, Color("#e8d8b0"))
	_px(canvas, int(at.x) + 1, int(at.y) + 1, Color("#e8d8b0"))
	for i in leaves.size() * 2:
		var side := -1 if i % 2 == 0 else 1
		var ramp: Array[Color] = leaves[i / 2]
		_leaf(canvas, at + Vector2(0, -2), at + Vector2(side * 10 + st.sway, -3 - i * 0.5), 3.2, ramp, o)

# --- Nestling line (wing) ---

const FEATHER := ["#2a1a10", "#e8d0a8", "#c8a878", "#a0805a"]

func _nest_ring(canvas: Image, o: Color) -> void:
	var nest := _layer()
	_ellipse(nest, Vector2(31.5, 45), Vector2(22, 6), _ramp(["#5a4228", "#8a6a40", "#b08a50"]))
	_flat_ellipse(nest, Vector2(31.5, 43.5), Vector2(18, 3.8), Color(0, 0, 0, 0))
	for y in S:
		for x in S:
			if nest.get_pixel(x, y).a > 0.0 and (x * 2 + y) % 5 == 0:
				nest.set_pixel(x, y, Color("#e0c070"))
	_stamp(canvas, nest, o)

func _feathers(canvas: Image, mask: Image, fig: Dictionary, dy: int) -> void:
	_spots(canvas, mask, fig.o, [Vector2i(24, 25 + dy), Vector2i(33, 22 + dy), Vector2i(29, 31), Vector2i(38, 29), Vector2i(21, 35)], fig.a.lightened(0.25))

# Nestling: a feathery golem sitting in a twig nest, a little sparrow perched on its head.
func _draw_nestling(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal(FEATHER[0], FEATHER[1], FEATHER[2], FEATHER[3])
	_draw_waystone(canvas, st, "nest")
	var mask := _draw_template_figure(canvas, st.pose, fig)
	_feathers(canvas, mask, fig, dy)
	_nest_ring(canvas, fig.o)
	_golem_face(canvas, st, fig)
	if st.attack < 0 or st.attack < RELEASE_FRAME:
		_bird(canvas, Vector2(31, 4 + dy - (1 if st.f % 4 == 1 else 0)), 1, _ramp(["#8a5a3a", "#b88058", "#e0b890"]), fig.o, st.f % 4 == 1)

# Wren's Nest: a russet golem wearing a dome nest for a hat, two quick wrens darting about it.
func _draw_wrens_nest(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal("#2a140a", "#e0b890", "#c08a60", "#946040")
	var wren := _ramp(["#6a4020", "#9a6438", "#c89060"])
	_draw_waystone(canvas, st, "nest")
	var mask := _draw_template_figure(canvas, st.pose, fig)
	_feathers(canvas, mask, fig, dy)
	_nest_ring(canvas, fig.o)
	_golem_face(canvas, st, fig)
	var dome := _layer()
	_ellipse(dome, Vector2(30.5, 7 + dy), Vector2(10, 6), _ramp(["#5a4228", "#8a6a40", "#b08a50"]), 9.5 + dy)
	_flat_ellipse(dome, Vector2(34, 6 + dy), Vector2(2, 1.8), Color(0, 0, 0, 0))
	_stamp(canvas, dome, fig.o)
	if st.attack < 0 or st.attack < RELEASE_FRAME:
		var t: float = TAU * float(st.f) / st.n
		_bird(canvas, Vector2(12 + cos(t) * 3, 10 + sin(t * 2) * 2), 1, wren, fig.o, st.f % 2 == 0)
	_bird(canvas, Vector2(51 + (st.sway), 16), -1, wren, fig.o, st.f % 2 == 1)

# Starling Murmuration: an iridescent speckled golem, a flock of starlings swirling above it.
func _draw_starling_murmuration(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal("#120e1e", "#7a6a9a", "#5a4a7a", "#3e3258")
	_draw_waystone(canvas, st, "nest", true)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	for k in 12:
		var p := Vector2i(18 + (k * 7) % 26, 20 + (k * 11) % 26)
		_skin_px(canvas, mask, fig.o, [p], Color("#ffe890") if k % 3 == 0 else (Color("#7ad0a0") if k % 3 == 1 else Color("#c090e0")))
	_nest_ring(canvas, fig.o)
	_golem_face(canvas, st, fig, Color("#ffe890"), false)
	if st.attack < 0:
		for k in 9:
			var a: float = TAU * float(st.f) / st.n + k * TAU / 9.0
			var r := 12.0 + (k % 3) * 3.0
			var p := Vector2i((Vector2(31, 5) + Vector2(cos(a) * r, sin(a) * r * 0.35)).round())
			_px(canvas, p.x, p.y, Color("#241c34"))
			_px(canvas, p.x + (1 if cos(a) > 0 else -1), p.y - (1 if (st.f + k) % 2 else 0), Color("#241c34"))

# Magpie Perch: a golem in magpie colours (dark head, white body) with a perch on its shoulder and
# a magpie on it, a shiny coin in the nest.
func _draw_magpie_perch(canvas: Image, st: Dictionary) -> void:
	_magpie_body(canvas, st, false)

# Magpie's Hoard: the Magpie Perch sitting on a glittering hoard of coins and trinkets.
func _draw_magpies_hoard(canvas: Image, st: Dictionary) -> void:
	_magpie_body(canvas, st, true)

func _magpie_body(canvas: Image, st: Dictionary, hoard: bool) -> void:
	var dy: int = st.dy
	var fig := _pal("#141420", "#f4f2f0", "#d8d4d0", "#aaa6a4")
	var ink := _ramp(["#1a1a2a", "#2e3048", "#4a5a8a"])
	_draw_waystone(canvas, st, "nest", hoard)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	# Dark hood with a blue sheen over the head.
	for y in range(0, 18 + dy):
		for x in S:
			if mask.get_pixel(x, y).a > 0.0 and canvas.get_pixel(x, y) != fig.o:
				canvas.set_pixel(x, y, ink[1] if x < 30 else ink[2])
	_nest_ring(canvas, fig.o)
	_golem_face(canvas, st, fig, Color("#f4f2f0"), false)
	var gold := _ramp(["#b8862a", "#e8b840", "#fff0a0"])
	var coins: Array = [Vector2(12, 44), Vector2(50, 46)]
	if hoard:
		coins = [Vector2(9, 43), Vector2(13, 45), Vector2(48, 46), Vector2(52, 44), Vector2(56, 46), Vector2(20, 48), Vector2(42, 49)]
	for i in coins.size():
		var coin := _layer()
		_ellipse(coin, coins[i], Vector2(2.2, 1.6), gold)
		_stamp(canvas, coin, Color("#5a3a10"))
	if hoard:
		_sparkle(canvas, Vector2i([Vector2(10, 40), Vector2(52, 41), Vector2(44, 46)][(st.f / 2) % 3]), Color.WHITE)
		var gem := _layer()
		_flat_polygon(gem, PackedVector2Array([Vector2(16, 47), Vector2(18, 45), Vector2(20, 47), Vector2(18, 49)]), Color("#e04a6a"))
		_stamp(canvas, gem, Color("#5a1020"))
	var perch := _layer()
	_stroke(perch, [Vector2(40, 20 + dy), Vector2(47, 18 + dy), Vector2(53, 19 + dy)], 1.1, Color("#7a5234"))
	_stamp(canvas, perch, fig.o)
	if st.attack < 0 or st.attack < RELEASE_FRAME:
		_magpie(canvas, Vector2(50, 13 + dy - (1 if st.f % 4 == 1 else 0)), fig.o, st.f % 4 == 1, hoard)

func _magpie(canvas: Image, p: Vector2, o: Color, wing_up: bool, coin: bool, s: float = 1.6, face: int = -1) -> void:
	_bird(canvas, p, face, _ramp(["#1a1a2a", "#2e3048", "#f4f2f0"]), o, wing_up, Color("#2a2a3a"), s)
	_px(canvas, roundi(p.x), roundi(p.y + s), Color("#f4f2f0"))
	_px(canvas, roundi(p.x + 1), roundi(p.y + s), Color("#f4f2f0"))
	_px(canvas, roundi(p.x - face * 7 * s / 1.6), roundi(p.y - s), Color("#4a6ae0"))  # blue tail sheen
	if coin:
		_px(canvas, roundi(p.x + face * 6 * s / 1.6), roundi(p.y - s), Color("#ffd24a"))

# --- Whirligig line (wind) ---

const MAPLE := ["#2a140a", "#f0b070", "#d88a48", "#b0602e"]

# Whirligig: an autumn-maple golem with a maple-seed propeller on its head, always spinning.
func _draw_whirligig(canvas: Image, st: Dictionary) -> void:
	_whirl_body(canvas, st, 0)

# Gust: Whirligig with puffed cheeks and wind ribbons curling round it.
func _draw_gust(canvas: Image, st: Dictionary) -> void:
	_whirl_body(canvas, st, 1)

# Zephyr: an airy, pale Gust with leaves riding its winds.
func _draw_zephyr(canvas: Image, st: Dictionary) -> void:
	_whirl_body(canvas, st, 2)

func _whirl_body(canvas: Image, st: Dictionary, kind: int) -> void:
	var dy: int = st.dy
	var fig := _pal(MAPLE[0], MAPLE[1], MAPLE[2], MAPLE[3])
	if kind == 2:
		fig = _pal("#1e3a30", "#e8fff0", "#c0ecd8", "#90c8b0")
	var seed := _ramp(["#b0602e", "#e0a060", "#f8d8a0"])
	_draw_waystone(canvas, st, "windswept", kind == 2)
	if kind >= 1:
		for k in (2 if kind == 1 else 3):
			var t: float = float((st.f + k * 3) % st.n) / st.n
			var y := 16 + k * 10
			_line(canvas, [Vector2(4 + t * 6, y), Vector2(14 + t * 6, y - 3), Vector2(22 + t * 6, y - 1)], Color("#e8f8f0"))
			_line(canvas, [Vector2(42 - t * 4, y + 4), Vector2(52 - t * 4, y + 1), Vector2(60 - t * 4, y + 3)], Color("#e8f8f0"))
	var mask := _draw_template_figure(canvas, st.pose, fig)
	_line(canvas, [Vector2(24, 26 + dy), Vector2(27, 32)], fig.c, mask)
	_line(canvas, [Vector2(36, 27 + dy), Vector2(38, 33)], fig.c, mask)
	_golem_face(canvas, st, fig)
	if kind == 1:
		for bx in [23, 24, 36, 37]:
			_px(canvas, bx, 13 + dy, Color("#f8c8a8"))
	var spin: float = float(st.f) * TAU / (st.n * (0.5 if st.attack >= 0 else 1.0))
	var stem := _layer()
	_stroke(stem, [Vector2(30.5, 6 + dy), Vector2(30.5, 3 + dy)], 1.0, Color("#8a5a2a"))
	_stamp(canvas, stem, fig.o)
	_blades(canvas, Vector2(30.5, 4 + dy), 2, 14.0, spin, 4.0, seed, fig.o)
	if kind == 2:
		for k in 3:
			var a: float = spin * 0.5 + k * TAU / 3.0
			var p := Vector2(31, 26) + Vector2(cos(a) * 24.0, sin(a) * 10.0)
			_leaf(canvas, p, p + Vector2(3, -2), 1.8, _ramp(["#c86a2a", "#e89a4a", "#f8c878"]), fig.o)

# Pinwheel: a golem holding up a bright paper pinwheel on a stick, spinning in the breeze.
func _draw_pinwheel(canvas: Image, st: Dictionary) -> void:
	_pinwheel_body(canvas, st, false)

# Windmill: the Pinwheel grown into a little windmill, four big sails turning behind it.
func _draw_windmill(canvas: Image, st: Dictionary) -> void:
	_pinwheel_body(canvas, st, true)

func _pinwheel_body(canvas: Image, st: Dictionary, mill: bool) -> void:
	var dy: int = st.dy
	var fig := _pal("#2a1a10", "#f4e0c0", "#dcc098", "#b89870")
	var spin: float = float(st.f) * TAU / (st.n * (0.35 if st.attack >= 0 else 1.0))
	_draw_waystone(canvas, st, "windswept", mill)
	if mill:
		var hub_m := Vector2(13, 15 + dy)
		var post := _layer()
		_stroke(post, [Vector2(14, 40), hub_m], 1.6, Color("#8a6a4a"))
		_stamp(canvas, post, fig.o)
		for k in 4:
			var d := Vector2.from_angle(spin + k * TAU / 4.0)
			var sail := _layer()
			_stroke(sail, [hub_m + d * 2.0, hub_m + d * 13.0], 0.8, Color("#8a6a4a"))
			_stamp(canvas, sail, fig.o)
			var cloth := _layer()
			var side := d.orthogonal() * 2.5
			_flat_polygon(cloth, PackedVector2Array([hub_m + d * 4.0, hub_m + d * 13.0,
				hub_m + d * 13.0 + side, hub_m + d * 4.0 + side]), Color("#f4ecdc"))
			_stamp(canvas, cloth, fig.o)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	_line(canvas, [Vector2(24, 26 + dy), Vector2(27, 32)], fig.c, mask)
	_golem_face(canvas, st, fig)
	var paper := [_ramp(["#c83a4a", "#e85a6a", "#ff9aa0"]), _ramp(["#3a8ac8", "#5ab0e8", "#9ad4ff"]),
		_ramp(["#d8a020", "#f0c030", "#ffe070"]), _ramp(["#3a9a5a", "#5ac070", "#9ae0a0"])]
	var stick := _layer()
	_stroke(stick, [Vector2(44, 40), Vector2(46, 14 + dy)], 0.9, Color("#8a6a4a"))
	_stamp(canvas, stick, fig.o)
	var hub := Vector2(46, 12 + dy)
	for k in 4:
		var d := Vector2.from_angle(spin + k * TAU / 4.0)
		var blade := PackedVector2Array([hub, hub + d * 7.0, hub + d * 5.0 + d.orthogonal() * 4.0])
		var layer := _layer()
		_flat_polygon(layer, blade, paper[k][1])
		_stamp(canvas, layer, fig.o)
	_px(canvas, int(hub.x), int(hub.y), Color("#fff4f0"))
	if not mill:
		for p: Vector2 in [Vector2(9, 42), Vector2(55, 43)]:
			for k in 4:
				var d := Vector2.from_angle(spin * 1.3 + k * TAU / 4.0)
				_px(canvas, roundi(p.x + d.x * 2), roundi(p.y + d.y * 2), paper[k][1])
			_px(canvas, int(p.x), int(p.y), Color("#8a6a4a"))

# --- Honeysuckle (Thornwall growth) ---

# Honeysuckle: the bramble golem wrapped in honeysuckle, trumpet flowers everywhere, sweet scent
# curling up off it. Asleep and content.
func _draw_honeysuckle(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal("#14241a", "#8cc46a", "#68a452", "#487a44")
	_draw_waystone(canvas, st, "bramble", true)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	for y in S:
		for x in S:
			if mask.get_pixel(x, y).a > 0.0 and canvas.get_pixel(x, y) != fig.o and (x * 73 + y * 151) % 11 == 0:
				canvas.set_pixel(x, y, Color("#3c7040"))
	_line(canvas, [Vector2(18, 33), Vector2(24, 27 + dy), Vector2(31, 30), Vector2(37, 25 + dy), Vector2(44, 29)], Color("#5a7a30"), mask)
	for i in 7:
		var p := Vector2i([Vector2i(21, 30), Vector2i(28, 27), Vector2i(35, 28), Vector2i(41, 33), Vector2i(25, 38), Vector2i(33, 7), Vector2i(17, 40)][i])
		if p.y < 20:
			p.y += dy
		var col := Color("#fff4c8") if i % 2 == 0 else Color("#ffd870")
		_skin_px(canvas, mask, fig.o, [p, p + Vector2i.RIGHT, p + Vector2i(2, -1), p + Vector2i(-1, 1)], col)
		_skin_px(canvas, mask, fig.o, [p + Vector2i(2, 0)], Color("#f4a0c0"))
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), true, true)
	if st.attack < 0:
		for k in 2:
			_wisp(canvas, Vector2([14, 46][k], 20), float((st.f + k * 4) % st.n) / st.n, Color("#f8c8e0"))

# --- Memory Wardens (from the act bosses) ---

# The White Stag: a white stag spirit with glowing golden branch-antlers, stars round it, on a
# rune stone. Its aura is always on, so it has no attack.
func _draw_white_stag(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal("#2a2a3a", "#fbfaf6", "#e4e0d8", "#c0bcb4")
	var antler := Color("#f0c860") if st.f % 4 < 2 else Color("#ffe090")
	_draw_waystone(canvas, st, "memory", true)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	_spots(canvas, mask, fig.o, [Vector2i(33, 24 + dy), Vector2i(37, 28), Vector2i(29, 33)], Color("#fff8ec"))
	_golem_face(canvas, st, fig, Color("#8a6a3a"), true)
	for side: int in [-1, 1]:
		var base := Vector2(30.5 + side * 5, 6 + dy)
		var layer := _layer()
		_stroke(layer, [base, base + Vector2(side * 4, -3), base + Vector2(side * 9, -5)], 0.9, antler)
		_stroke(layer, [base + Vector2(side * 4, -3), base + Vector2(side * 4, -6)], 0.8, antler)
		_stroke(layer, [base + Vector2(side * 7, -4), base + Vector2(side * 9, -8)], 0.8, antler)
		_stamp(canvas, layer, Color("#6a4a20"))
	for ex: float in [19.5, 41.5]:
		var ear := _layer()
		_ellipse(ear, Vector2(ex, 9 + dy), Vector2(3.6, 2), _ramp(["#c0bcb4", "#e4e0d8", "#fbfaf6"]))
		_stamp(canvas, ear, fig.o)
		_px(canvas, int(ex), 9 + dy, Color("#f0c0c0"))
	for k in 4:
		if (st.f + k) % 3 != 1:
			_sparkle(canvas, [Vector2i(8, 10), Vector2i(55, 8), Vector2i(4, 28), Vector2i(59, 26)][k], Color("#fff8d8"))

# The Pond Keeper: an old toad spirit with bulging eyes and a lily-pad hat, sitting in its pond.
func _draw_pond_keeper(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal("#1a2a14", "#a8c878", "#7aa050", "#56783a")
	_draw_waystone(canvas, st, "memory", true)
	var pond := _layer()
	_ellipse(pond, Vector2(31.5, 46), Vector2(24, 6.5), _ramp(["#2a6aa8", "#4a8ed0", "#8ad0f8"]))
	_stamp(canvas, pond, Color("#16305e"))
	var mask := _draw_template_figure(canvas, st.pose, fig)
	for p: Vector2i in [Vector2i(22, 26), Vector2i(26, 33), Vector2i(36, 24), Vector2i(40, 31), Vector2i(19, 38), Vector2i(33, 38)]:
		_skin_px(canvas, mask, fig.o, [p, p + Vector2i.RIGHT], fig.c)
	# Pale belly.
	for y in range(28, 44):
		for x in range(26, 37):
			if mask.get_pixel(x, y).a > 0.0 and canvas.get_pixel(x, y) != fig.o and ((Vector2(x, y) - Vector2(31, 36)) / Vector2(5.5, 8)).length() < 1.0:
				canvas.set_pixel(x, y, Color("#e8f0c0"))
	# Bulging eyes on top of the head, then a wide smile.
	var skin: Array[Color] = [fig.c, fig.b, fig.a]
	for ex: int in [25, 36]:
		var eye := _layer()
		_ellipse(eye, Vector2(ex, 7 + dy), Vector2(3.2, 3), skin)
		_stamp(canvas, eye, fig.o)
		var closed: bool = st.blink
		if closed:
			_line(canvas, [Vector2(ex - 1, 7 + dy), Vector2(ex + 1, 7 + dy)], fig.o)
		else:
			_px(canvas, ex, 7 + dy, fig.o)
			_px(canvas, ex, 6 + dy, fig.o)
			_px(canvas, ex - 1, 6 + dy, Color.WHITE)
	_line(canvas, [Vector2(24, 13 + dy), Vector2(27, 15 + dy), Vector2(34, 15 + dy), Vector2(37, 13 + dy)], fig.o, mask)
	for bx in [22, 23, 38, 39]:
		_px(canvas, bx, 14 + dy, BLUSH)
	var hat := _layer()
	_ellipse(hat, Vector2(30.5, 4 + dy), Vector2(6, 2), _ramp(LEAF))
	_flat_polygon(hat, PackedVector2Array([Vector2(31, 4 + dy), Vector2(37, 3 + dy), Vector2(37, 5 + dy)]), Color(0, 0, 0, 0))
	_stamp(canvas, hat, Color("#1e3a24"))
	var ripple := float(st.f % 4) / 4.0
	_ring(canvas, Vector2(12, 47), Vector2(3 + ripple * 5, 1 + ripple * 1.5), Color("#bfe8ff"), ripple > 0.5)

# The Moon Moth: a pale luminous moth spirit, wide moon-pale wings with crescent eye-spots.
func _draw_moon_moth(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal("#1e1e3a", "#f4f4ff", "#d4d4f0", "#a8a8d0")
	var wing := _ramp(["#9a9ac8", "#d8d8f4", "#fbfbff"])
	var flap: int = st.sway
	_draw_waystone(canvas, st, "memory", true)
	_leaf(canvas, Vector2(21, 21 + dy), Vector2(1 + flap, 3 + dy), 8.5, wing, fig.o)
	_leaf(canvas, Vector2(40, 21 + dy), Vector2(60 - flap, 2 + dy), 8.5, wing, fig.o)
	_leaf(canvas, Vector2(22, 29 + dy), Vector2(6, 40), 5.5, wing, fig.o)
	_leaf(canvas, Vector2(39, 29 + dy), Vector2(56, 40), 5.5, wing, fig.o)
	for s: Vector2 in [Vector2(11 + flap * 0.5, 12 + dy), Vector2(50 - flap * 0.5, 11 + dy)]:
		var spot := _layer()
		_flat_ellipse(spot, s, Vector2(2.6, 2.6), MEMORY_GOLD)
		_flat_ellipse(spot, s + Vector2(1.2, -0.6), Vector2(2.1, 2.1), Color(0, 0, 0, 0))
		_stamp(canvas, spot)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	_spots(canvas, mask, fig.o, [Vector2i(26, 26 + dy), Vector2i(35, 29), Vector2i(29, 35)], Color.WHITE)
	_golem_face(canvas, st, fig, Color("#5a5aa8"), true)
	for side: int in [-1, 1]:
		var base := Vector2(30.5 + side * 3, 5 + dy)
		_line(canvas, [base, base + Vector2(side * 3, -3), base + Vector2(side * 6, -4)], fig.o)
		_px(canvas, int(base.x + side * 4), int(base.y - 5), fig.c)
		_px(canvas, int(base.x + side * 2), int(base.y - 4), fig.c)
	for k in 3:
		if (st.f + k) % 2 == 0:
			_glow_dot(canvas, [Vector2i(6, 26), Vector2i(58, 24), Vector2i(31, 1)][k], Color("#fffbe8"), Color("#c8c8f0"))

# --- Attack effects (new Wardens) ---

# Mushrooms springing up in a ring on the stone in front, then glowing.
func _sprout_ring(canvas: Image, st: Dictionary, cap: Color, big: bool) -> void:
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	var c := Vector2(ATTACKS["fairy_ring"].point)
	var n := 8 if big else 6
	for i in n:
		var p := Vector2i((c + Vector2.from_angle(i * TAU / n) * Vector2(9, 3.5)).round())
		var h: int = [1, 2, 2][k]
		_px(canvas, p.x, p.y, Color("#f0e4d8"))
		for dx in [-1, 0, 1]:
			_px(canvas, p.x + dx, p.y - h, cap)
		if h > 1:
			_px(canvas, p.x, p.y - 1, Color("#f0e4d8"))
			_px(canvas, p.x, p.y - h - 1, cap.lightened(0.3))
	if k >= 1:
		_warm_glow(canvas, c + Vector2(0, -1), Vector2(13, 6), k)

func _attack_fairy_ring(canvas: Image, st: Dictionary) -> void:
	_sprout_ring(canvas, st, Color("#fff0c8"), false)

func _attack_elf_circle(canvas: Image, st: Dictionary) -> void:
	_sprout_ring(canvas, st, Color("#7ff0e0"), true)

# The rune flares, then a heavy shot leaves the scope.
func _sniper_shot(canvas: Image, st: Dictionary, key: String, core: Color) -> void:
	var a: int = st.attack
	var c := Vector2(ATTACKS[key].point)
	if a == RELEASE_FRAME - 1:
		_sparkle(canvas, Vector2i(12, 15), core)
	elif a == RELEASE_FRAME:
		for k in 4:
			_px(canvas, int(c.x) + 2 + k * 2, int(c.y) - k, core)
		_glow_dot(canvas, Vector2i(c), Color.WHITE, core)
		_warm_glow(canvas, c, Vector2(8, 6))
	elif a == RELEASE_FRAME + 1:
		_warm_glow(canvas, c, Vector2(5, 4), 1)

func _attack_standing_stone(canvas: Image, st: Dictionary) -> void:
	_sniper_shot(canvas, st, "standing_stone", Color("#ffd870"))

func _attack_moonstone(canvas: Image, st: Dictionary) -> void:
	_sniper_shot(canvas, st, "moonstone", Color("#dfeeff"))

# A puff of frost glittering off the fern tip.
func _frost_burst(canvas: Image, st: Dictionary, key: String, big: bool) -> void:
	_burst(canvas, Vector2(ATTACKS[key].point), st.attack, Color("#f4fcff"), Color("#a8d4f4"), Color("#16305e"))
	var k: int = st.attack - RELEASE_FRAME
	if big and k >= 0 and k < 3:
		for d: Vector2 in [Vector2(-1, -0.4), Vector2(1, -0.3), Vector2(0.2, 1)]:
			var p := Vector2(ATTACKS[key].point) + d * (6 + k * 4)
			_glyph(canvas, Vector2i(p.round()), [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)], Color("#f4fcff"))

func _attack_frostfern(canvas: Image, st: Dictionary) -> void:
	_frost_burst(canvas, st, "frostfern", false)

func _attack_hoarfrost(canvas: Image, st: Dictionary) -> void:
	_frost_burst(canvas, st, "hoarfrost", true)

# Midsummer's beam: thicker than Sunpetal's, with a second beam carrying through behind.
func _attack_midsummer(canvas: Image, st: Dictionary) -> void:
	var k: int = st.attack - RELEASE_FRAME
	var from := Vector2(ATTACKS["midsummer"].point)
	if k < 0 or k > 2:
		return
	var to := Vector2(63, from.y - 4)
	for w in range(-(3 - k), 4 - k):
		_line(canvas, [from + Vector2(0, w), to + Vector2(0, w)], Color("#fffbe0") if w == 0 else (Color("#fff0a0") if absi(w) == 1 else Color("#ffc860")))
	_line(canvas, [to + Vector2(-8, 5), to + Vector2(0, 5)], Color("#ffe890"))
	_sparkle(canvas, Vector2i(from), Color.WHITE)
	for t in [0.3, 0.7]:
		_warm_glow(canvas, from.lerp(to, t), Vector2(7, 6 - k), k)

# Light running out along the roots, and a warm lit ring over the path.
func _root_light(canvas: Image, st: Dictionary, big: bool) -> void:
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	var c := Vector2(ATTACKS["rootlight"].point)
	var reach := (8.0 + k * 7.0) * (1.3 if big else 1.0)
	for i in 6:
		var d := Vector2.from_angle(i * TAU / 6.0 + 0.3) * Vector2(1.0, 0.4)
		_line(canvas, [c + d * 3.0, c + d * reach], Color("#ffe890") if k < 2 else GLOW_OUTER)
	_ring(canvas, c, Vector2(reach, reach * 0.4), GLOW_INNER, k == 2)
	_warm_glow(canvas, c + Vector2(0, -2), Vector2(reach * 0.6, 5), k)

func _attack_rootlight(canvas: Image, st: Dictionary) -> void:
	_root_light(canvas, st, false)

func _attack_starcave(canvas: Image, st: Dictionary) -> void:
	_root_light(canvas, st, true)
	var k: int = st.attack - RELEASE_FRAME
	if k >= 0 and k < 3:
		for p: Vector2i in [Vector2i(44, 10), Vector2i(52, 14), Vector2i(38, 12)]:
			_sparkle(canvas, p + Vector2i(k, -k), Color("#f0e8ff"))

# The graft glows and a spiral of borrowed leaves spins off it.
func _graft_glow(canvas: Image, st: Dictionary, at: Vector2) -> void:
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	for i in 5:
		var a := i * TAU / 5.0 + k * 0.8
		var p := at + Vector2.from_angle(a) * (4.0 + k * 3.0)
		_px(canvas, roundi(p.x), roundi(p.y), [Color("#9ad86a"), Color("#f090b8"), Color("#ffe080")][i % 3])
	_warm_glow(canvas, at, Vector2(7 + k * 2, 6 + k), k)

func _attack_graftling(canvas: Image, st: Dictionary) -> void:
	_graft_glow(canvas, st, Vector2(ATTACKS["graftling"].point))

func _attack_grafted_elder(canvas: Image, st: Dictionary) -> void:
	_graft_glow(canvas, st, Vector2(ATTACKS["grafted_elder"].point))

# The bird takes off from its perch and flies out; it comes back as the idle loop resumes.
func _swoop(canvas: Image, st: Dictionary, key: String, body: Array[Color], o: Color, magpie: bool) -> void:
	var a: int = st.attack
	var launch := Vector2(ATTACKS[key].point)
	var path: Array = [Vector2(), Vector2(), launch, launch + Vector2(8, 3), Vector2(), Vector2()]
	if a == RELEASE_FRAME or a == RELEASE_FRAME + 1:
		var p: Vector2 = path[a]
		if magpie:
			_magpie(canvas, p, o, a == RELEASE_FRAME, false, 1.6, 1)
		else:
			_bird(canvas, p, 1, body, o, a == RELEASE_FRAME)
		_warm_glow(canvas, p, Vector2(6, 5), a)

func _attack_nestling(canvas: Image, st: Dictionary) -> void:
	_swoop(canvas, st, "nestling", _ramp(["#8a5a3a", "#b88058", "#e0b890"]), Color(FEATHER[0]), false)

func _attack_wrens_nest(canvas: Image, st: Dictionary) -> void:
	_swoop(canvas, st, "wrens_nest", _ramp(["#6a4020", "#9a6438", "#c89060"]), Color("#2a140a"), false)

func _attack_magpie_perch(canvas: Image, st: Dictionary) -> void:
	_swoop(canvas, st, "magpie_perch", _ramp(["#1a1a2a", "#2e3048", "#f4f2f0"]), Color("#141420"), true)

func _attack_magpies_hoard(canvas: Image, st: Dictionary) -> void:
	_swoop(canvas, st, "magpies_hoard", _ramp(["#1a1a2a", "#2e3048", "#f4f2f0"]), Color("#141420"), true)

# The three starlings each dart out after a different nightmare (the 3 fastest), then return.
func _attack_starling_murmuration(canvas: Image, st: Dictionary) -> void:
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 1:
		return
	var body := _ramp(["#241c34", "#3e3258", "#7a6a9a"])
	for i in 3:
		var p := Vector2(ATTACKS["starling_murmuration"].point) + Vector2(k * 6, i * 9 - 4) + Vector2(i * 3, 0)
		_bird(canvas, p, 1, body, Color("#0e0a16"), (st.f + i) % 2 == 0, Color("#f0c050"), 1.2)
		_warm_glow(canvas, p, Vector2(5, 4), k + i)
# Wind rushing outward in curved streaks, with a pale ring.
func _gust_rush(canvas: Image, st: Dictionary, spiral: bool) -> void:
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	var c := Vector2(31, 24)
	for i in 6:
		var a := i * TAU / 6.0 + (k * 0.5 if spiral else 0.0)
		var r0 := 12.0 + k * 5.0
		var p0 := c + Vector2.from_angle(a) * Vector2(r0, r0 * 0.6)
		var p1 := c + Vector2.from_angle(a + (0.5 if spiral else 0.15)) * Vector2(r0 + 6, (r0 + 6) * 0.6)
		_line(canvas, [p0, p1], Color("#e8f8f0"))
	_pulse(canvas, st, Color("#d8f4e8"))
	_warm_glow(canvas, Vector2(31, 46), Vector2(12 + k * 6, 4 + k * 2), k)

func _attack_whirligig(canvas: Image, st: Dictionary) -> void:
	_gust_rush(canvas, st, false)

func _attack_gust(canvas: Image, st: Dictionary) -> void:
	_gust_rush(canvas, st, true)

func _attack_zephyr(canvas: Image, st: Dictionary) -> void:
	_gust_rush(canvas, st, true)
	var k: int = st.attack - RELEASE_FRAME
	if k >= 0 and k < 3:
		for i in 4:
			var p := Vector2(31, 26) + Vector2.from_angle(i * TAU / 4.0 + k) * Vector2(18 + k * 5, 9 + k * 2)
			_leaf(canvas, p, p + Vector2(3, -2), 1.8, _ramp(["#c86a2a", "#e89a4a", "#f8c878"]), Color("#1e3a30"))

# Blades sweeping the tiles round it: arcs of wind in a ring.
func _spin_sweep(canvas: Image, st: Dictionary, big: bool) -> void:
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	var c := Vector2(31, 38)
	var r := Vector2(22, 9) * (1.2 if big else 1.0)
	for i in 3:
		var a0 := i * TAU / 3.0 + k * 1.1
		var pts: Array = []
		for s in 6:
			pts.append(c + Vector2.from_angle(a0 + s * 0.25) * r)
		_line(canvas, pts, Color("#fffbe8") if i % 2 == 0 else Color("#e8f8f0"))
	_warm_glow(canvas, c, r * 0.8, k)

func _attack_pinwheel(canvas: Image, st: Dictionary) -> void:
	_spin_sweep(canvas, st, false)

func _attack_windmill(canvas: Image, st: Dictionary) -> void:
	_spin_sweep(canvas, st, true)

# A sweet-scented pulse: pink wisps and a warm ring.
func _attack_honeysuckle(canvas: Image, st: Dictionary) -> void:
	_pulse(canvas, st, Color("#f8c8e0"))
	var k: int = st.attack - RELEASE_FRAME
	if k >= 0 and k < 3:
		for x in [12, 24, 40, 52]:
			_wisp(canvas, Vector2(x, 40 - k * 4), 0.3 + k * 0.2, Color("#f8c8e0"))

# The Pond Keeper's tongue shoots out, sticks, and reels a nightmare back.
func _attack_pond_keeper(canvas: Image, st: Dictionary) -> void:
	var a: int = st.attack
	var mouth := Vector2(31, 15 + st.dy)
	var tip := Vector2(ATTACKS["pond_keeper"].point)
	var ends: Array = [mouth, mouth, tip, mouth.lerp(tip, 0.5), mouth, mouth]
	var end: Vector2 = ends[a]
	if end == mouth:
		return
	var tongue := _layer()
	_stroke(tongue, [mouth, end], 1.1, Color("#e87a8a"))
	_flat_ellipse(tongue, end, Vector2(2.2, 2.2), Color("#f09aa8"))
	_stamp(canvas, tongue, Color("#6a2030"))
	_warm_glow(canvas, end, Vector2(5, 4), a)

# The White Stag's aura breathing out: a soft silver ring and a warm one, with a shimmer of stars.
func _attack_white_stag(canvas: Image, st: Dictionary) -> void:
	_pulse(canvas, st, Color("#e8ecff"))
	var k: int = st.attack - RELEASE_FRAME
	if k >= 0 and k < 3:
		for p: Vector2i in [Vector2i(10, 20), Vector2i(52, 18), Vector2i(31, 2), Vector2i(6, 36), Vector2i(57, 34)]:
			if (p.x + k) % 3 != 0:
				_sparkle(canvas, p + Vector2i(0, -k), Color("#f4f8ff"))

func _attack_moon_moth(canvas: Image, st: Dictionary) -> void:
	_flash(canvas, st, Vector2(ATTACKS["moon_moth"].point), Color("#f4f8ff"), MEMORY_GOLD)

# --- Projectiles (new) ---

# A thrown sling stone with a golden streak behind it.
func _proj_sling_stone(canvas: Image, f: int) -> void:
	_spinning_rock(canvas, f, 3.5, _ramp(STONE), Color("#1c1c36"))
	for k in 4:
		_px(canvas, 28 - k * 2, 32 + (k + f) % 2, GLOW_INNER if k < 2 else GLOW_OUTER)

# A silver crescent shard trailing moonlight.
func _proj_moon_shard(canvas: Image, f: int) -> void:
	var layer := _layer()
	_flat_ellipse(layer, Vector2(34, 32), Vector2(4, 4), Color("#dfeeff"))
	_flat_ellipse(layer, Vector2(32.5, 31), Vector2(3.4, 3.4), Color(0, 0, 0, 0))
	_stamp(canvas, layer, Color("#3a3a6a"))
	_px(canvas, 36, 32, Color.WHITE)
	for k in 3:
		_px(canvas, 29 - k * 2, 33 + (k + f) % 2, Color("#c8e0ff"))

# An ice shard pointing right, a glint sliding along it.
func _proj_frost_shard(canvas: Image, f: int) -> void:
	var ice := _ramp(["#6aa8e0", "#b4e4ff", "#f4fcff"])
	var layer := _layer()
	var pts := PackedVector2Array([Vector2(41, 32), Vector2(34, 29), Vector2(25, 30), Vector2(28, 32), Vector2(25, 34), Vector2(34, 35)])
	for y in S:
		for x in S:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				layer.set_pixel(x, y, ice[2] if y < 32 else ice[1])
	_stamp(canvas, layer, Color("#16305e"))
	_px(canvas, [29, 32, 35, 38][f], 31, Color.WHITE)
	_px(canvas, 22 - f % 2, 31, ice[2])

func _bird_proj(canvas: Image, f: int, body: Array[Color], o: Color) -> void:
	_bird(canvas, Vector2(32, 34), 1, body, o, f % 2 == 0, Color("#e8a040"), 1.1)

func _proj_sparrow(canvas: Image, f: int) -> void:
	_bird_proj(canvas, f, _ramp(["#8a5a3a", "#b88058", "#e0b890"]), Color(FEATHER[0]))

func _proj_wren(canvas: Image, f: int) -> void:
	_bird_proj(canvas, f, _ramp(["#6a4020", "#9a6438", "#c89060"]), Color("#2a140a"))

func _proj_magpie(canvas: Image, f: int) -> void:
	_magpie(canvas, Vector2(32, 34), Color("#141420"), f % 2 == 0, false, 1.1, 1)

func _proj_starling(canvas: Image, f: int) -> void:
	for k in 3:
		var p := Vector2(34 - k * 4, 31 + [0, 3, -2][k])
		_px(canvas, int(p.x), int(p.y), Color("#241c34"))
		_px(canvas, int(p.x) + 1, int(p.y) - (f + k) % 2, Color("#241c34"))
		_px(canvas, int(p.x) - 1, int(p.y) - (f + k + 1) % 2, Color("#241c34"))

# A pale moth-dust orb.
func _proj_moon_mote(canvas: Image, f: int) -> void:
	var core := _layer()
	_flat_ellipse(core, Vector2(34, 32), Vector2(2.8, 2.8), Color("#f4f8ff"))
	_stamp(canvas, core, Color("#8a8ac8"))
	_px(canvas, 33, 31, Color.WHITE)
	for k in 4:
		var a := k * TAU / 4.0 + f * 0.4
		_px(canvas, roundi(34 + cos(a) * 4.5), roundi(32 + sin(a) * 4.5), MEMORY_GOLD if k % 2 else Color("#dfeeff"))

# Trap sprites (drawn on a path tile, not flying): a little mushroom ring that pulses.
func _proj_fairy_ring(canvas: Image, f: int) -> void:
	_trap_ring(canvas, f, Color("#fff0c8"), 6)

func _proj_elf_circle(canvas: Image, f: int) -> void:
	_trap_ring(canvas, f, Color("#7ff0e0"), 8)

func _trap_ring(canvas: Image, f: int, cap: Color, n: int) -> void:
	for i in n:
		var p := Vector2i((Vector2(32, 33) + Vector2.from_angle(i * TAU / n) * Vector2(6, 4)).round())
		_px(canvas, p.x, p.y, Color("#f0e4d8"))
		_px(canvas, p.x - 1, p.y - 1, cap)
		_px(canvas, p.x, p.y - 1, cap)
		_px(canvas, p.x + 1, p.y - 1, cap)
		if (i + f) % n == 0:
			_px(canvas, p.x, p.y - 2, Color.WHITE)

# --- Nurture ranks (warden_stats.md "Ranks: Nurture") -----------------------------------------
# Every Warden stands on the same waystone slab (the mock's), so rank art is drawn once and layered
# on any Warden: rank_<n>_over.png sits on top of the Warden sprite but only touches the slab's
# rim and side faces (never the figure); rank_<n>_under.png is a warm halo drawn below it. Both
# are 8-frame loops like the idle. Ranks build up: I seedlings, II blossoming vine, III glowing
# runes, IV gold trim, V golden laurels and rising motes. VI and VII only come from the Deeper
# Rings card (dream_design.md): VI doubles the gold trim into rings and grows golden saplings, VII
# runs gold root filigree down the stone. Plus rank badges and a rank-up burst.

const RANKS_OUT := "res://assets/towers/ranks/"
const RANK_GOLD := Color("#f0c860")
const RANK_GOLD_DARK := Color("#a87a28")
const BADGE_SIZE := 16
const RANK_TOP := 7  # Deeper Rings' cap
const RANKUP_FRAMES := 8

func _make_ranks() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RANKS_OUT))
	var masks := _slab_masks()
	for rank in range(1, RANK_TOP + 1):
		for layer in ["over", "under"]:
			var sheet := Image.create_empty(S * FRAMES, S, false, Image.FORMAT_RGBA8)
			for f in FRAMES:
				var canvas := _layer()
				if layer == "over":
					_rank_over(canvas, rank, f, masks)
				else:
					_rank_under(canvas, rank, f, masks)
				sheet.blit_rect(canvas, Rect2i(0, 0, S, S), Vector2i(f * S, 0))
			sheet.save_png(RANKS_OUT + "rank_%d_%s.png" % [rank, layer])
	var badges := Image.create_empty(BADGE_SIZE * RANK_TOP, BADGE_SIZE, false, Image.FORMAT_RGBA8)
	for rank in range(1, RANK_TOP + 1):
		badges.blit_rect(_rank_badge(rank), Rect2i(0, 0, BADGE_SIZE, BADGE_SIZE), Vector2i((rank - 1) * BADGE_SIZE, 0))
	badges.save_png(RANKS_OUT + "rank_badges.png")
	var burst := Image.create_empty(S * RANKUP_FRAMES, S, false, Image.FORMAT_RGBA8)
	for f in RANKUP_FRAMES:
		var canvas := _layer()
		_rank_up(canvas, f)
		burst.blit_rect(canvas, Rect2i(0, 0, S, S), Vector2i(f * S, 0))
	burst.save_png(RANKS_OUT + "rank_up.png")
	_save_rank_preview(masks, badges)

# The slab's top face, side faces and front rim (the top face's front edges), from the template.
func _slab_masks() -> Dictionary:
	var pose: Dictionary = poses[0]
	var top := _layer()
	var side := _layer()
	for i in S * S:
		var ch: String = pose.grid[i]
		if ch == ".":
			continue
		var x := i % S
		var y := i / S
		var on_top := y <= 40 + mini(x, 63 - x) / 2
		if pose.outside[i] == 1:
			(top if ch == "a" and on_top else side).set_pixel(x, y, Color.WHITE)
		else:
			var xl := 2 * (40 - y) - 1
			var xr := 64 - 2 * (40 - y) + 1
			if y > 40 or (x > xl + 1 and x < xr - 1):
				top.set_pixel(x, y, Color.WHITE)
	var rim := _layer()
	for y in range(S - 1):
		for x in S:
			if _on(top, x, y) and _on(side, x, y + 1) and y >= 40:
				rim.set_pixel(x, y, Color.WHITE)
	return {top = top, side = side, rim = rim, grid = pose.grid}

# The rim's y at column x (the front edge of the top face), or -1.
func _rim_y(masks: Dictionary, x: int) -> int:
	for y in range(40, S):
		if _on(masks.rim, x, y):
			return y
	return -1

func _rank_over(canvas: Image, rank: int, f: int, masks: Dictionary) -> void:
	var sway: int = SWAY[f]
	var twinkle := f % 4 < 2
	# V: golden laurels at the three corners.
	if rank >= 5:
		var laurel := _ramp(["#c89030", "#f0c850", "#fff4b0"])
		for c: Array in [[Vector2(4, 44), -1], [Vector2(59, 44), 1]]:
			var at: Vector2 = c[0]
			var dir: int = c[1]
			for k in 3:
				_leaf(canvas, at, at + Vector2(dir * (2 + k), -5 + k * 2), 2.0, laurel, Color("#7a5218"))
	# IV: gold trim along the rim with a glint running along it.
	if rank >= 4:
		var glint := int(f * S / float(FRAMES))
		for x in S:
			var y := _rim_y(masks, x)
			if y < 0:
				continue
			_px(canvas, x, y, Color.WHITE if absi(x - glint) <= 1 else RANK_GOLD)
			if _on(masks.side, x, y + 1):
				_px(canvas, x, y + 1, RANK_GOLD_DARK)
	# VI+: the whole slab is gilded: gold side faces that keep the template's brick lines and streaks.
	if rank >= 6:
		var lit: bool = f % 4 < 2
		for y in S:
			for x in S:
				if not _on(masks.side, x, y):
					continue
				var ch: String = masks.grid[y * S + x]
				var col := Color("#d8a840") if ch == "d" else (Color("#a8782a") if ch == "e" else Color("#f4d878"))
				if rank >= 7:  # radiant: paler, brighter gold
					col = Color("#f4d070") if ch == "d" else (Color("#d0a040") if ch == "e" else Color("#fff0b8"))
				if (x * 3 + y * 5) % 11 == 0:
					col = col.lightened(0.3) if lit else col.lightened(0.15)
				canvas.set_pixel(x, y, col)
	# VI: a second gold ring just inside the trim, and ring emblems in the stone.
	if rank >= 6:
		for x in S:
			var y := _rim_y(masks, x)
			if y > 0 and _on(masks.top, x, y - 2) and (x + f) % 2 == 0:
				_px(canvas, x, y - 2, RANK_GOLD)
		for p: Vector2i in [Vector2i(13, 51), Vector2i(31, 58), Vector2i(49, 51)]:
			for d: Vector2i in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]:
				if _on(masks.side, p.x + d.x, p.y + d.y):
					_px(canvas, p.x + d.x, p.y + d.y, RANK_GOLD)
			if _on(masks.side, p.x, p.y):
				_px(canvas, p.x, p.y, Color.WHITE if f % 4 < 2 else Color("#ffe890"))
			for d: Vector2i in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]:
				if _on(masks.side, p.x + d.x, p.y + d.y):
					_px(canvas, p.x + d.x, p.y + d.y, Color("#6a4418"))
	# VII: golden root filigree running down the side faces.
	if rank >= 7:
		var gold := Color("#fffbe0") if f % 4 < 2 else Color("#fff0a0")
		for root: Array in [[Vector2(5, 44), Vector2(7, 48), Vector2(5, 52)], [Vector2(22, 53), Vector2(23, 57), Vector2(21, 61)],
				[Vector2(41, 54), Vector2(40, 58), Vector2(42, 61)], [Vector2(57, 45), Vector2(56, 49), Vector2(58, 52)]]:
			for i in root.size() - 1:
				var a: Vector2 = root[i]
				var b: Vector2 = root[i + 1]
				for s in 9:
					var p := Vector2i(a.lerp(b, s / 8.0).round())
					if _on(masks.side, p.x, p.y):
						_px(canvas, p.x, p.y, gold)
	# III: warm runes glowing in the side faces.
	if rank >= 3:
		var rune := Color("#ffe890") if twinkle else Color("#f0c060")
		var glyphs := [[Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 0), Vector2i(1, 2)], [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 1), Vector2i(2, 2)],
			[Vector2i(1, 0), Vector2i(0, 1), Vector2i(2, 1), Vector2i(1, 2)]]
		for i in 6:
			var p: Vector2i = [Vector2i(9, 48), Vector2i(17, 52), Vector2i(25, 56), Vector2i(37, 56), Vector2i(45, 52), Vector2i(53, 48)][i]
			for d: Vector2i in glyphs[i % 3]:
				if _on(masks.side, p.x + d.x, p.y + d.y):
					_px(canvas, p.x + d.x, p.y + d.y, rune)
	# II: a flowering vine creeping along just under the rim.
	if rank >= 2:
		for x in range(2, 62):
			var y := _rim_y(masks, x)
			if y < 0:
				continue
			var vy := y + 2 + (1 if (x / 4) % 2 == 0 else 0)
			if _on(masks.side, x, vy) and x % 3 != 0:
				_px(canvas, x, vy, Color("#4a8a3e"))
			if x % 9 == 4 and _on(masks.side, x, vy):
				_flower(canvas, Vector2i(x, vy), Color("#f4a0c0") if x % 18 == 4 else Color("#fff4f0"), Color("#ffd24a"))
	# I: two glowing seedlings on the front rim (they bloom from rank II).
	for base: Vector2i in [Vector2i(16, 47), Vector2i(47, 47)]:
		var y := _rim_y(masks, base.x)
		var stem := _layer()
		_stroke(stem, [Vector2(base.x, y), Vector2(base.x, y - 4)], 0.9, Color("#5a9a3c"))
		_stamp(canvas, stem, Color("#1e3a24"))
		_leaf(canvas, Vector2(base.x, y - 4), Vector2(base.x - 5 + sway, y - 7), 2.2, _ramp(LEAF), Color("#1e3a24"))
		_leaf(canvas, Vector2(base.x, y - 4), Vector2(base.x + 5 + sway, y - 8), 2.2, _ramp(LEAF), Color("#1e3a24"))
		if rank >= 6:
			var crown := _layer()
			_ellipse(crown, Vector2(base.x + sway * 0.5, y - 8), Vector2(4, 3), _ramp(["#c89030", "#f0c850", "#fff4b0"]))
			_stamp(canvas, crown, Color("#7a5218"))
			_px(canvas, base.x - 1 + sway, y - 9, Color.WHITE)
		elif rank >= 2:
			_flower(canvas, Vector2i(base.x + sway, y - 6), Color("#ffe890"), Color("#f0a030"))
		_warm_glow(canvas, Vector2(base.x, y - 4), Vector2(7, 5), f)
	# V: motes of light drifting up off the slab.
	if rank >= 5:
		for k in 4:
			var t := float((f + k * 2) % FRAMES) / FRAMES
			var x: int = [6, 22, 42, 58][k] + roundi(sin(t * TAU) * 1.5)
			var y := roundi(46 - t * 14)
			if not _on(masks.top, x, y):
				_glow_dot(canvas, Vector2i(x, y), Color("#fffbe0"), GLOW_OUTER if t < 0.6 else Color(0, 0, 0, 0))

# A warm halo round the foot of the slab, growing with rank (drawn under the Warden sprite, so only
# the part outside the slab shows).
func _rank_under(canvas: Image, rank: int, f: int, _masks: Dictionary) -> void:
	if rank < 3:
		return
	var pulse := 0.5 + 0.5 * sin(TAU * f / FRAMES)
	var r := Vector2(32 + mini(rank, 5) * 1.2 + pulse, 13 + mini(rank, 5) * 0.8)
	var c := Vector2(31.5, 49)
	if rank >= 7:
		_ring(canvas, c, r + Vector2(1.5, 1), Color(GLOW_INNER, 0.7), f % 2 == 0)
	# VI+: warm light rays fanning out over the ground round the gilded slab.
	if rank >= 6:
		var rays := 10 if rank >= 7 else 8
		for k in rays:
			var d := Vector2.from_angle(k * TAU / rays + f * 0.05)
			var reach := 1.25 + (0.1 if (k + f) % 2 == 0 else 0.0)
			for s in 12:
				var p := c + Vector2(d.x * r.x, d.y * r.y) * lerpf(0.75, reach, s / 11.0)
				if (s + f) % 2 == 0:
					_px(canvas, roundi(p.x), roundi(p.y), Color(GLOW_INNER, 0.8))
	for y in S:
		for x in S:
			var q := ((Vector2(x + 0.5, y + 0.5) - c) / r).length()
			if q > 1.0:
				continue
			if q > 0.85 and (x + y + f) % 2 == 0:
				canvas.set_pixel(x, y, Color(GLOW_OUTER, 0.55))
			elif q <= 0.85 and (x + 2 * y + f) % (3 if rank >= 4 else 4) == 0:
				canvas.set_pixel(x, y, Color(GLOW_INNER, 0.6))

# A 16x16 badge: a gold seed-medallion with the rank's numeral, dressed up at higher ranks.
func _rank_badge(rank: int) -> Image:
	var canvas := _layer()
	var c := Vector2(8, 8.5)
	var o := Color("#4a2e10")
	if rank >= 3:
		for side: int in [-1, 1]:
			_px(canvas, int(c.x) + side * 7, 7, Color("#6ab04a"))
			_px(canvas, int(c.x) + side * 7, 9, Color("#6ab04a"))
			_px(canvas, int(c.x) + side * 8 - (1 if side < 0 else 0), 8, Color("#9ad86a"))
	var coin := _layer()
	_ellipse(coin, c, Vector2(6.2, 6.2), _ramp(["#c89030", "#f0c060", "#fff0a0"]))
	_stamp(canvas, coin, o)
	if rank >= 6:
		_ring(canvas, c, Vector2(5.6, 5.6), Color("#fff4b0"), false)
	if rank >= 5:
		for p: Vector2i in [Vector2i(8, 0), Vector2i(7, 1), Vector2i(9, 1), Vector2i(8, 1)]:
			_px(canvas, p.x, p.y, Color("#fffbe0"))
	var numerals := {
		1: [0], 2: [0, 2], 3: [0, 2, 4],
	}
	var ink := Color("#5a3410")
	var i_col := func(x: int) -> void:
		for y in range(6, 11):
			_px(canvas, x, y, ink)
	var v_at := func(x: int) -> void:
		for p: Vector2i in [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 2), Vector2i(1, 3), Vector2i(2, 4), Vector2i(3, 3), Vector2i(3, 2), Vector2i(4, 1), Vector2i(4, 0)]:
			_px(canvas, x + p.x, 6 + p.y, ink)
	if rank <= 3:
		var cols: Array = numerals[rank]
		var start := 8 - int(cols[-1]) / 2
		for dx: int in cols:
			i_col.call(start + dx)
	elif rank == 4:
		i_col.call(5)
		v_at.call(7)
	elif rank == 5:
		v_at.call(6)
	elif rank == 6:
		v_at.call(4)
		i_col.call(10)
	else:
		v_at.call(3)
		i_col.call(9)
		i_col.call(11)
	return canvas

# Played once when a Warden is nurtured: a warm ring swells off the slab, leaves and sparks fly up.
func _rank_up(canvas: Image, f: int) -> void:
	var t := float(f) / (RANKUP_FRAMES - 1)
	var c := Vector2(31.5, 46)
	if f < 6:
		_ring(canvas, c, Vector2(10 + t * 30, 4 + t * 11), GLOW_INNER, f >= 4)
		_ring(canvas, c, Vector2(7 + t * 26, 3 + t * 9), GLOW_OUTER, f >= 3)
	for k in 7:
		var a := k * TAU / 7.0 + 0.3
		var p := c + Vector2(cos(a) * (6 + t * 20), -t * 34 - absf(sin(a)) * 6 + sin(a) * 4)
		if p.y < 0:
			continue
		if k % 2 == 0:
			_px(canvas, int(p.x), int(p.y), Color("#9ad86a"))
			_px(canvas, int(p.x) + 1, int(p.y) - 1, Color("#d8f8a8"))
			_px(canvas, int(p.x) + 1, int(p.y), Color("#6ab04a"))
		elif f < 7:
			_sparkle(canvas, Vector2i(p.round()), Color("#fffbe0") if f % 2 == 0 else RANK_GOLD)
	if f <= 2:
		_warm_glow(canvas, c + Vector2(0, -8), Vector2(18 - f * 3, 10), f)

# Sample Wardens at ranks 0-V (under + sprite + over, frame 0), then the badges and the burst.
func _save_rank_preview(masks: Dictionary, badges: Image) -> void:
	var demo := ["sprout", "sporeling", "pebbling", "firefly_jar", "moon_moth"]
	var pad := 6
	var preview := Image.create_empty(pad + (RANK_TOP + 1) * (S + pad), pad + (demo.size() + 2) * (S + pad), false, Image.FORMAT_RGBA8)
	preview.fill(Color("#5fa844"))
	for r in demo.size():
		var body := _layer()
		call("_draw_" + demo[r], body, _idle_state(0))
		for rank in RANK_TOP + 1:
			var tile := _layer()
			if rank > 0:
				_rank_under(tile, rank, 0, masks)
			tile.blend_rect(body, Rect2i(0, 0, S, S), Vector2i.ZERO)
			if rank > 0:
				var over := _layer()
				_rank_over(over, rank, 0, masks)
				tile.blend_rect(over, Rect2i(0, 0, S, S), Vector2i.ZERO)
			preview.blend_rect(tile, Rect2i(0, 0, S, S), Vector2i(pad + rank * (S + pad), pad + r * (S + pad)))
	var y := pad + demo.size() * (S + pad)
	for rank in RANK_TOP:
		var badge := badges.get_region(Rect2i(rank * BADGE_SIZE, 0, BADGE_SIZE, BADGE_SIZE))
		badge.resize(BADGE_SIZE * 3, BADGE_SIZE * 3, Image.INTERPOLATE_NEAREST)
		preview.blend_rect(badge, Rect2i(0, 0, BADGE_SIZE * 3, BADGE_SIZE * 3), Vector2i(pad + (rank + 1) * (S + pad) + 8, y + 8))
	y += S + pad
	for f in 6:
		var canvas := _layer()
		_rank_up(canvas, f + 1)
		preview.blend_rect(canvas, Rect2i(0, 0, S, S), Vector2i(pad + f * (S + pad), y))
	preview.resize(preview.get_width() * 3, preview.get_height() * 3, Image.INTERPOLATE_NEAREST)
	preview.save_png(PREVIEWS + "ranks.png")

# --- Family review (tower_design.md "Family design rules", 2026-09-27) --------------------------
# Bellflower family (song and sleep), and the hidden branches Cairn, Hummingbird Bower and Samara.

const BELL_LILAC := ["#9a80d0", "#c0a8ec", "#e0d0f8", "#f4ecff"]
const BELL_GLOW := Color("#ffe890")

# Lilac-grey stone under a meadow of bellflowers, some glowing warm gold.
func _decor_bellflower(canvas: Image, top: Image, _side: Image, st: Dictionary, lush: bool) -> void:
	for y in S:
		for x in S:
			if not _on(top, x, y):
				continue
			var h := (x * 29 + y * 53) % 9
			canvas.set_pixel(x, y, Color("#8ab07a") if h == 0 else (Color("#4a7a50") if h == 4 else Color("#5f8f5c")))
	var spots: Array = OPEN_SPOTS.slice(0, 9 if lush else 6)
	for i in spots.size():
		var p: Vector2i = spots[i]
		if not _on(top, p.x, p.y):
			continue
		var glowing: bool = i % 3 == 0 and (st.f + i) % 4 < 2
		_px(canvas, p.x, p.y, Color("#4a7a50"))
		_px(canvas, p.x - 1, p.y - 1, Color(BELL_LILAC[1]))
		_px(canvas, p.x, p.y - 1, Color(BELL_LILAC[2]))
		_px(canvas, p.x + 1, p.y - 1, Color(BELL_LILAC[1]))
		_px(canvas, p.x, p.y - 2, Color(BELL_LILAC[0]))
		if glowing:
			_glow_dot(canvas, Vector2i(p.x, p.y), BELL_GLOW, Color("#c8a8f0"))

# A little bellflower on a curved stem: `ground` is where the stem starts, the bell hangs at the tip.
func _stem_bell(canvas: Image, ground: Vector2, height: float, lean: float, o: Color) -> void:
	var tip := ground + Vector2(lean * 4.0, -height)
	var stem := _layer()
	_stroke(stem, [ground, ground + Vector2(lean, -height * 0.6), tip], 0.8, Color("#4a8a4e"))
	_stamp(canvas, stem, o)
	var bell := _layer()
	_ellipse(bell, tip + Vector2(lean * 1.5, 2.5), Vector2(2.6, 2.2), _ramp(BELL_LILAC), tip.y + 3.5)
	_stamp(canvas, bell, o)
	_px(canvas, roundi(tip.x + lean * 1.5), roundi(tip.y + 4), BELL_GLOW)

# A big bell-flower worn as a cap: petals flaring to a scalloped rim, warm light glowing inside.
func _bell_cap(canvas: Image, c: Vector2, w: float, h: float, o: Color) -> void:
	var ramp := _ramp(["#5a3aa0", "#8a60d8", "#b890f4", "#e8d8ff"])  # deeper than the lilac body
	var pts := PackedVector2Array([c + Vector2(-w, 0), c + Vector2(-w * 0.8, -h * 0.55), c + Vector2(-w * 0.35, -h),
		c + Vector2(w * 0.35, -h), c + Vector2(w * 0.8, -h * 0.55), c + Vector2(w, 0)])
	var layer := _layer()
	for y in S:
		for x in S:
			var p := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(p, pts):
				var nx := clampf((p.x - c.x) / w, -1.0, 1.0)
				layer.set_pixel(x, y, _shade(ramp, Vector3(nx, -0.3, sqrt(maxf(0.1, 1.0 - nx * nx)))))
	var x := c.x - w + 1.5
	while x < c.x + w - 1.0:
		_flat_ellipse(layer, Vector2(x, c.y), Vector2(1.8, 1.5), ramp[1])
		x += 3.5
	_stamp(canvas, layer, o)
	for k in 3:
		_line(canvas, [c + Vector2(-w * 0.55 + k * w * 0.55, -h * 0.9), c + Vector2(-w * 0.7 + k * w * 0.7, -1)], ramp[0])
	_px(canvas, int(c.x), int(c.y) + 1, BELL_GLOW)
	_px(canvas, int(c.x) - 1, int(c.y) + 1, Color("#f0c050"))

# --- Bellflower line ---

# Bellflower: a lilac golem wearing a big bell-flower, little bells ringing on stems round it.
func _draw_bellflower(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal("#22183a", "#e0d0f8", "#c0a8ec", "#9a80d0")
	_draw_waystone(canvas, st, "bellflower")
	_stem_bell(canvas, Vector2(9, 44), 10, -1 + st.sway * 0.5, fig.o)
	_stem_bell(canvas, Vector2(55, 43), 12, 1 + st.sway * 0.5, fig.o)
	_draw_template_figure(canvas, st.pose, fig)
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), true, st.attack < 0)
	_bell_cap(canvas, Vector2(30.5 + st.sway * 0.5, 10 + dy), 14.0, 10, fig.o)
	_stem_bell(canvas, Vector2(43, 21 + dy), 6, 1 + st.sway, fig.o)
	if st.attack < 0:
		_rising_glyph(canvas, st, NOTE_GLYPH, 50, 14, Color("#e0c8ff"))

func _attack_bellflower(canvas: Image, st: Dictionary) -> void:
	_pulse(canvas, st, Color("#c8b0f0"))
	var k: int = st.attack - RELEASE_FRAME
	if k >= 0 and k < 3:
		_glyph(canvas, Vector2i(7, 14 - k * 3), NOTE_GLYPH, Color("#e0c8ff"))
		_glyph(canvas, Vector2i(52, 12 - k * 3), NOTE_GLYPH, BELL_GLOW)
		_warm_glow(canvas, Vector2(30.5, 12), Vector2(12, 6), k)

# A dreamcatcher hoop: a ring with a woven web, a glowing bead, and bead strings with a feather.
func _hoop(canvas: Image, c: Vector2, r: float, sway: float, o: Color, glow: bool) -> void:
	var ring := _layer()
	_ring(ring, c, Vector2(r, r), Color("#a8845a"), false)
	_ring(ring, c, Vector2(r - 1, r - 1), Color("#d8b888"), false)
	_stamp(canvas, ring, Color(0, 0, 0, 0))
	var web := Color("#e8e0ff")
	for k in 6:
		var d := Vector2.from_angle(k * TAU / 6.0 + 0.3)
		_line(canvas, [c + d * 1.5, c + d * (r - 1.5)], web)
	if r >= 5:
		_ring(canvas, c, Vector2(r * 0.5, r * 0.5), web, true)
	_glow_dot(canvas, Vector2i(c.round()), BELL_GLOW if glow else Color("#c8a8f0"), Color("#c8a8f0"))
	for k in 3:
		var top := c + Vector2(-r * 0.6 + k * r * 0.6, r - 0.5)
		var end := top + Vector2(sway, 3 + (k % 2) * 2)
		_line(canvas, [top, end], Color("#d8b888"))
		_px(canvas, int(end.x), int(end.y) - 1, Color("#f0c050") if k != 1 else Color(BELL_LILAC[1]))
		if k == 1:
			_leaf(canvas, end, end + Vector2(sway * 0.5, 5), 1.6, _ramp(["#8a74c0", "#c8b8f0", "#f4f0ff"]), o)

# Dreamcatcher: an indigo golem with a woven dreamcatcher hung from a crooked branch beside it.
func _draw_dreamcatcher(canvas: Image, st: Dictionary) -> void:
	_dreamcatcher_body(canvas, st, false)

# Great Dreamcatcher: a bigger branch hung with three dreamcatchers and glowing beads.
func _draw_great_dreamcatcher(canvas: Image, st: Dictionary) -> void:
	_dreamcatcher_body(canvas, st, true)

func _dreamcatcher_body(canvas: Image, st: Dictionary, great: bool) -> void:
	var dy: int = st.dy
	var fig := _pal("#1a1430", "#b8a8e0", "#9080c8", "#6a5aa8")
	var sway: float = st.sway
	var glow: bool = st.f % 4 < 2 or st.power > 0.5
	_draw_waystone(canvas, st, "bellflower", great)
	var branch := _layer()
	_stroke(branch, [Vector2(51, 44), Vector2(52, 30), Vector2(50, 18), Vector2(53, 8), Vector2(46, 3)], 1.3, Color("#7a5234"))
	if great:
		_stroke(branch, [Vector2(10, 44), Vector2(9, 28), Vector2(12, 14), Vector2(18, 8)], 1.1, Color("#7a5234"))
	_stamp(canvas, branch, fig.o)
	_draw_template_figure(canvas, st.pose, fig)
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), true, st.attack < 0)
	_line(canvas, [Vector2(47, 4), Vector2(46 + sway, 8)], Color("#d8b888"))
	_hoop(canvas, Vector2(46 + sway, 14), 7.0 if great else 6.0, sway, fig.o, glow)
	if great:
		_line(canvas, [Vector2(17, 9), Vector2(16 + sway, 12)], Color("#d8b888"))
		_hoop(canvas, Vector2(16 + sway, 16), 4.0, sway, fig.o, not glow)
		_hoop(canvas, Vector2(57 + sway, 31), 3.5, sway, fig.o, glow)
		for p: Vector2i in [Vector2i(4, 30), Vector2i(60, 20), Vector2i(24, 2)]:
			if (st.f + p.x) % 3 != 0:
				_glow_dot(canvas, p, BELL_GLOW, Color("#c8a8f0"))

# Threads flick out of the hoop, a glowing bead on the end.
func _thread_flick(canvas: Image, st: Dictionary, key: String) -> void:
	var k: int = st.attack - RELEASE_FRAME
	var from := Vector2(ATTACKS[key].point)
	if k < 0 or k > 1:
		return
	var to := from + (Vector2(16, 10) if k == 0 else Vector2(10, 6))
	for w in [-1, 0, 1]:
		_line(canvas, [from, to + Vector2(0, w * 2)], Color("#e8e0ff") if w == 0 else Color("#c8a8f0"))
	_glow_dot(canvas, Vector2i(to.round()), BELL_GLOW, Color("#c8a8f0"))
	_warm_glow(canvas, to, Vector2(5, 4), k)

func _attack_dreamcatcher(canvas: Image, st: Dictionary) -> void:
	_thread_flick(canvas, st, "dreamcatcher")

func _attack_great_dreamcatcher(canvas: Image, st: Dictionary) -> void:
	_thread_flick(canvas, st, "great_dreamcatcher")

# Sound ripples: arcs spreading out of an opening towards the right.
func _ripples(canvas: Image, from: Vector2, count: int, spacing: float, color: Color, phase: int) -> void:
	for k in count:
		var r := 4.0 + k * spacing + (phase % 2)
		for s in 7:
			var a := lerpf(-0.9, 0.9, s / 6.0)
			var p := from + Vector2(cos(a), sin(a) * 1.2) * r
			if (s + k + phase) % 3 != 0:
				_px(canvas, roundi(p.x), roundi(p.y), color)

# Echo Hollow: a sleepy log golem with a hollow in its chest that echoes, ripples coming out.
func _draw_echo_hollow(canvas: Image, st: Dictionary) -> void:
	_hollow_body(canvas, st, false)

# Whispering Hollow: an old hollow tree behind it, whispering from several openings.
func _draw_whispering_hollow(canvas: Image, st: Dictionary) -> void:
	_hollow_body(canvas, st, true)

func _hollow_body(canvas: Image, st: Dictionary, whispering: bool) -> void:
	var dy: int = st.dy
	var fig := _pal("#24160e", "#b08a64", "#8a6a4a", "#6a4e36")
	var ripple := Color("#d8c0ff")
	_draw_waystone(canvas, st, "bellflower", whispering)
	if whispering:
		var trunk := _layer()
		_flat_polygon(trunk, PackedVector2Array([Vector2(4, 44), Vector2(6, 12), Vector2(3, 2), Vector2(12, 4),
			Vector2(17, 1), Vector2(19, 12), Vector2(21, 44)]), fig.b)
		for y in S:
			for x in S:
				if trunk.get_pixel(x, y).a > 0.0 and x % 4 == 0:
					trunk.set_pixel(x, y, fig.c)
				elif trunk.get_pixel(x, y).a > 0.0 and x < 8:
					trunk.set_pixel(x, y, fig.a)
		_stamp(canvas, trunk, fig.o)
		for hole: Vector2 in [Vector2(12, 14), Vector2(11, 28)]:
			var h := _layer()
			_flat_ellipse(h, hole, Vector2(2.5, 3.5), Color("#1a1008"))
			_stamp(canvas, h, fig.o)
			_px(canvas, int(hole.x), int(hole.y) + 1, Color("#8a6ad0"))
	var mask := _draw_template_figure(canvas, st.pose, fig)
	for g: Array in [[Vector2(24, 24 + dy), Vector2(23, 31 + dy)], [Vector2(37, 27 + dy), Vector2(38, 34)]]:
		_line(canvas, g, fig.c, mask)
	var top := _layer()
	_flat_ellipse(top, Vector2(30.5, 6 + dy), Vector2(8.5, 2.6), Color("#d8b888"))
	_stamp(canvas, top, fig.o)
	_line(canvas, [Vector2(27, 6 + dy), Vector2(34, 6 + dy)], Color("#a88a60"))
	_px(canvas, 36, 4 + dy, Color("#6ab04a"))
	_px(canvas, 37, 4 + dy, Color("#9ad86a"))
	var hollow := _layer()
	_flat_ellipse(hollow, Vector2(30, 29 + dy), Vector2(4.5, 5.5), Color("#1a1008"))
	_stamp(canvas, hollow, fig.o)
	_ellipse(canvas, Vector2(30, 30 + dy), Vector2(2, 2.5), _ramp(["#5a3a8a", "#8a6ad0", "#c8a8f0"]))
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), true, true)
	if st.attack < 0:
		_ripples(canvas, Vector2(35, 29 + dy), 2, 4.0, ripple, st.f)
		if whispering:
			_ripples(canvas, Vector2(15, 14), 1, 4.0, ripple, st.f + 1)
			_wisp(canvas, Vector2(12, 26), float(st.f) / st.n, Color("#e8d8ff"))

func _attack_echo_hollow(canvas: Image, st: Dictionary) -> void:
	_echo_burst(canvas, st, false)

func _attack_whispering_hollow(canvas: Image, st: Dictionary) -> void:
	_echo_burst(canvas, st, true)

func _echo_burst(canvas: Image, st: Dictionary, big: bool) -> void:
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	_ripples(canvas, Vector2(35, 28), 3 + (1 if big else 0), 5.0 + k * 2, Color("#e8d8ff") if k < 2 else Color("#a888d8"), k)
	if big:
		_ripples(canvas, Vector2(15, 14), 2, 5.0 + k * 2, Color("#e8d8ff"), k + 1)
	_warm_glow(canvas, Vector2(30, 29), Vector2(8, 7), k)

# --- Pebbling hidden: Cairn -> Rockslide ---

# A balanced stack of flat stones on the slab beside the golem; the top one bobs (it's next).
func _cairn(canvas: Image, stones: Array, bob: int, o: Color, lifted: bool) -> void:
	var stone := _ramp(STONE)
	for i in stones.size():
		var s: Vector3 = stones[i]
		if lifted and i == stones.size() - 1:
			continue
		var layer := _layer()
		var y := s.y + (bob if i == stones.size() - 1 else 0)
		_ellipse(layer, Vector2(s.x, y), Vector2(s.z, s.z * 0.45), stone)
		_stamp(canvas, layer, o)
		_px(canvas, int(s.x) - 1, int(y) - 1, Color("#e4e7f4"))

func _draw_cairn(canvas: Image, st: Dictionary) -> void:
	_cairn_body(canvas, st, false)

func _draw_rockslide(canvas: Image, st: Dictionary) -> void:
	_cairn_body(canvas, st, true)

func _cairn_body(canvas: Image, st: Dictionary, slide: bool) -> void:
	var fig := _pal("#1c1c36", "#c4c9e2", "#979dc2", "#686d9a")
	var stones: Array = [Vector3(11, 43, 7), Vector3(11, 37, 6), Vector3(12, 32, 5), Vector3(11, 27, 4.2), Vector3(12, 22, 3.6)]
	if slide:
		stones = [Vector3(11, 44, 7.5), Vector3(11, 38, 6.5), Vector3(12, 33, 6), Vector3(11, 28, 5), Vector3(12, 23, 4.4),
			Vector3(11, 18, 4), Vector3(12, 13, 3.6)]
	var bob: int = [0, 0, -1, -1, 0, 0, -1, -1][st.f] if st.attack < 0 else [-1, -2, 0, 0, 0, 0][st.attack]
	_draw_waystone(canvas, st, "cobble", slide)
	_cairn(canvas, stones, bob, fig.o, st.attack >= RELEASE_FRAME and st.attack <= RELEASE_FRAME + 1)
	if slide:
		_cairn(canvas, [Vector3(54, 43, 5), Vector3(54, 38, 4), Vector3(55, 34, 3)], 0, fig.o, false)
		_rock(canvas, PackedVector2Array([Vector2(44, 49), Vector2(46, 47), Vector2(49, 48), Vector2(48, 51)]), _ramp(STONE), fig.o)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	for band in [26, 33, 40]:
		_line(canvas, [Vector2(19, band), Vector2(44, band + 1)], fig.c, mask)
	_golem_face(canvas, st, fig)

func _attack_cairn(canvas: Image, st: Dictionary) -> void:
	_lob(canvas, st, "cairn", 3.6)

func _attack_rockslide(canvas: Image, st: Dictionary) -> void:
	_lob(canvas, st, "rockslide", 4.4)

# The top stone lifts off the stack and is lobbed high over the maze.
func _lob(canvas: Image, st: Dictionary, key: String, size: float) -> void:
	var k: int = st.attack - RELEASE_FRAME
	var launch := Vector2(ATTACKS[key].point)
	if k == 0:
		var layer := _layer()
		_ellipse(layer, launch, Vector2(size, size * 0.6), _ramp(STONE))
		_stamp(canvas, layer, Color("#1c1c36"))
		for s in 3:
			_px(canvas, int(launch.x) + 1, int(launch.y) + 4 + s * 3, GLOW_INNER)
		_warm_glow(canvas, launch, Vector2(size + 4, size + 3))
	if k == 0 or k == 1:
		for d: Vector2i in [Vector2i(-5, 0), Vector2i(5, 0), Vector2i(-3, -2), Vector2i(3, -2)]:
			_px(canvas, 12 + d.x * (1 + k), 20 + d.y - k, Color("#d8d4e4") if k == 0 else Color("#aaa4bc"))

# --- Nestling hidden: Hummingbird Bower -> Jewelwing Court ---

const EMERALD := ["#1a7a4a", "#3ac070", "#9af0b0"]
const RUBY := ["#a02040", "#e04a6a", "#ffa0b8"]
const SAPPHIRE := ["#2a4aa8", "#4a7ae0", "#a0c8ff"]

# A hummingbird hovering: jewel body, long beak, a blur of wings, a bright throat.
func _hummingbird(canvas: Image, p: Vector2, face: int, jewel: Array, f: int) -> void:
	var o := Color("#12101e")
	var body := _layer()
	_ellipse(body, p, Vector2(2.6, 1.9), _ramp(jewel))
	_ellipse(body, p + Vector2(face * 2.2, -1.2), Vector2(1.6, 1.5), _ramp(jewel))
	_flat_polygon(body, PackedVector2Array([p + Vector2(-face * 2, 0), p + Vector2(-face * 5, 1.5), p + Vector2(-face * 4, -1)]), Color(jewel[0]))
	_stamp(canvas, body, o)
	_line(canvas, [p + Vector2(face * 3.6, -1.4), p + Vector2(face * 6.5, -1)], Color("#2a2030"))
	_px(canvas, roundi(p.x + face * 2.6), roundi(p.y - 1.8), o)
	_px(canvas, roundi(p.x + face * 1.6), roundi(p.y), Color("#ff6a8a"))
	var wing_y := -3.0 if f % 2 == 0 else -1.5
	_flat_ellipse(canvas, p + Vector2(-face * 0.5, wing_y), Vector2(2.2, 1.0), Color(1, 1, 1, 0.55))

# A bower: an arch of vine over the golem, hung with trumpet flowers.
func _bower(canvas: Image, st: Dictionary, big: bool, o: Color) -> void:
	var pts: Array = []
	var r := Vector2(27 if big else 26, 41 if big else 39)  # arches right over the golem's head
	for s in 17:
		var a := lerpf(PI, TAU, s / 16.0)
		pts.append(Vector2(31.5, 44) + Vector2(cos(a) * r.x, sin(a) * r.y))
	var vine := _layer()
	_stroke(vine, pts, 1.3 if big else 1.1, Color("#5a7a30"))
	_stamp(canvas, vine, o)
	for i in pts.size():
		if i % 2 == 1:
			var p: Vector2 = pts[i]
			_px(canvas, int(p.x) + 1, int(p.y) - 1, Color("#7cbc5a"))
		if i % (3 if big else 4) == 2:
			var p: Vector2 = pts[i]
			var col := Color("#f08a4a") if i % 2 == 0 else Color("#f4a0c0")
			_px(canvas, int(p.x), int(p.y) + 1, col)
			_px(canvas, int(p.x), int(p.y) + 2, col)
			_px(canvas, int(p.x) - 1, int(p.y) + 3, col.lightened(0.2))
			_px(canvas, int(p.x) + 1, int(p.y) + 3, col.lightened(0.2))

func _draw_hummingbird_bower(canvas: Image, st: Dictionary) -> void:
	_bower_body(canvas, st, false)

func _draw_jewelwing_court(canvas: Image, st: Dictionary) -> void:
	_bower_body(canvas, st, true)

func _bower_body(canvas: Image, st: Dictionary, court: bool) -> void:
	var dy: int = st.dy
	var fig := _pal(FEATHER[0], FEATHER[1], FEATHER[2], FEATHER[3])
	_draw_waystone(canvas, st, "nest", court)
	_bower(canvas, st, court, fig.o)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	_feathers(canvas, mask, fig, dy)
	_golem_face(canvas, st, fig)
	var hover: int = [0, -1, -1, 0, 0, 1, 1, 0][st.f % 8] if st.attack < 0 else 0
	var birds: Array = [[Vector2(51, 16), -1, EMERALD]]
	if court:
		birds = [[Vector2(51, 16), -1, EMERALD], [Vector2(11, 18), 1, RUBY], [Vector2(45, 6), -1, SAPPHIRE]]
	for i in birds.size():
		var b: Array = birds[i]
		if st.attack >= RELEASE_FRAME and st.attack <= RELEASE_FRAME + 1:
			continue  # They're out pecking
		_hummingbird(canvas, b[0] + Vector2(0, hover * (1 if i % 2 == 0 else -1)), b[1], b[2], st.f + i)

func _attack_hummingbird_bower(canvas: Image, st: Dictionary) -> void:
	_peck_flurry(canvas, st, [EMERALD])

func _attack_jewelwing_court(canvas: Image, st: Dictionary) -> void:
	_peck_flurry(canvas, st, [EMERALD, RUBY, SAPPHIRE])

# The hummingbirds dart out and peck in a quick flurry, a spark on each peck.
func _peck_flurry(canvas: Image, st: Dictionary, jewels: Array) -> void:
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 1:
		return
	for i in jewels.size():
		var p := Vector2(56 - i * 4, 26 + i * 7) + Vector2(k * 2, 0)
		_hummingbird(canvas, p, 1, jewels[i], st.f + i)
		var spark := Vector2i((p + Vector2(8, -1)).round())
		_sparkle(canvas, spark, Color.WHITE if k == 0 else GLOW_INNER)
		_warm_glow(canvas, Vector2(spark), Vector2(4, 3), k + i)

# --- Whirligig hidden: Samara -> Autumn Gale ---

# A maple seed (samara): a round nut with one veined wing, turned by `angle`.
func _samara_seed(canvas: Image, c: Vector2, angle: float, wing: Array, o: Color, size: float = 1.0) -> void:
	var d := Vector2.from_angle(angle)
	_leaf(canvas, c + d * 1.0 * size, c + d * 9.0 * size, 2.6 * size, _ramp(wing), o)
	var nut := _layer()
	_ellipse(nut, c, Vector2(2.2, 2.2) * size, _ramp(["#6a3a1a", "#9a5a2a", "#c88a4a"]))
	_stamp(canvas, nut, o)

func _draw_samara(canvas: Image, st: Dictionary) -> void:
	_samara_body(canvas, st, false)

func _draw_autumn_gale(canvas: Image, st: Dictionary) -> void:
	_samara_body(canvas, st, true)

func _samara_body(canvas: Image, st: Dictionary, gale: bool) -> void:
	var dy: int = st.dy
	var fig := _pal("#2a0e0a", "#f0906a", "#d86a48", "#b04a30") if gale else _pal(MAPLE[0], MAPLE[1], MAPLE[2], MAPLE[3])
	var wing := ["#c8401a", "#f06a3a", "#ffb07a"] if gale else ["#b0602e", "#e0a060", "#f8d8a0"]
	var spin: float = float(st.f) * TAU / st.n * 0.5
	_draw_waystone(canvas, st, "windswept", gale)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	_line(canvas, [Vector2(24, 26 + dy), Vector2(27, 32)], fig.c, mask)
	_golem_face(canvas, st, fig)
	_leaf(canvas, Vector2(31, 6 + dy), Vector2(36 + st.sway, 1 + dy), 2.4, _ramp(wing), fig.o)
	var holding: bool = st.attack < RELEASE_FRAME
	var arms := _layer()
	var right_hand := Vector2(48, 15 + dy) if st.attack != 1 else Vector2(44, 13 + dy)  # drawn back to throw
	_stroke(arms, [Vector2(42, 22 + dy), right_hand + Vector2(-1, 3)], 2.0, fig.b)
	if gale:
		_stroke(arms, [Vector2(20, 22 + dy), Vector2(14, 15 + dy)], 2.0, fig.b)
	_stamp(canvas, arms, fig.o)
	if holding:
		_samara_seed(canvas, right_hand, spin - PI / 2.0, wing, fig.o, 1.3)
	if gale:
		_samara_seed(canvas, Vector2(14, 13 + dy), -spin - PI / 2.0, wing, fig.o, 1.3)
		for k in 3:
			var t: float = float((st.f + k * 3) % st.n) / st.n
			var p := Vector2([8, 30, 56][k] + sin(t * TAU) * 3.0, 2 + t * 20)
			_leaf(canvas, p, p + Vector2(3, 2), 1.6, _ramp(["#a83a1a", "#e05a2a", "#f8a060"]), fig.o)
	if st.attack < 0:
		for k in 2:
			var t: float = float((st.f + k * 4) % st.n) / st.n
			_line(canvas, [Vector2(52 + t * 6, 10 + k * 8), Vector2(58 + t * 6, 9 + k * 8)], Color("#e8f8f0"))

func _attack_samara(canvas: Image, st: Dictionary) -> void:
	_seed_throw(canvas, st, "samara", ["#b0602e", "#e0a060", "#f8d8a0"], 1)

func _attack_autumn_gale(canvas: Image, st: Dictionary) -> void:
	_seed_throw(canvas, st, "autumn_gale", ["#c8401a", "#f06a3a", "#ffb07a"], 2)

# The seed leaves the hand spinning, with a wind trail behind it.
func _seed_throw(canvas: Image, st: Dictionary, key: String, wing: Array, seeds: int) -> void:
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 1:
		return
	for i in seeds:
		var p := Vector2(ATTACKS[key].point) + Vector2(k * 5, i * 14 - k * 2)
		_samara_seed(canvas, p, st.attack * 1.9 + i, wing, Color(MAPLE[0]))
		for s in 3:
			_px(canvas, int(p.x) - 5 - s * 3, int(p.y) + (s % 2), Color("#e8f8f0"))
		_warm_glow(canvas, p, Vector2(7, 6), k + i)

# --- Projectiles (family review) ---

func _proj_dream_mote(canvas: Image, f: int) -> void:
	for x in range(24, 30):
		if (x + f) % 2 == 0:
			_px(canvas, x, 32, Color("#e8e0ff"))
	var bead := _layer()
	_flat_ellipse(bead, Vector2(33, 32), Vector2(2.4, 2.4), BELL_GLOW)
	_stamp(canvas, bead, Color("#6a4a9a"))
	_px(canvas, 32, 31, Color.WHITE)

func _proj_lob_stone(canvas: Image, f: int) -> void:
	var layer := _layer()
	var c := Vector2(32, 32)
	var a := f * TAU / 8.0
	var pts := PackedVector2Array()
	for k in 8:
		var ang := a + k * TAU / 8.0
		pts.append(c + Vector2(cos(ang) * 5.0, sin(ang) * 2.8).rotated(a))
	_rock(canvas, pts, _ramp(STONE), Color("#1c1c36"))
	_px(canvas, 31, 30, Color("#7cbc5a"))

func _proj_hummingbird(canvas: Image, f: int) -> void:
	_hummingbird(canvas, Vector2(31, 33), 1, EMERALD, f)

func _proj_maple_seed(canvas: Image, f: int) -> void:
	_samara_seed(canvas, Vector2(32, 32), f * TAU / 4.0, ["#b0602e", "#e0a060", "#f8d8a0"], Color(MAPLE[0]), 0.75)

func _proj_autumn_seed(canvas: Image, f: int) -> void:
	_samara_seed(canvas, Vector2(32, 32), f * TAU / 4.0, ["#c8401a", "#f06a3a", "#ffb07a"], Color(MAPLE[0]), 0.75)

func _proj_starling_bird(canvas: Image, f: int) -> void:
	_bird(canvas, Vector2(32, 34), 1, _ramp(["#241c34", "#3e3258", "#7a6a9a"]), Color("#0e0a16"), f % 2 == 0, Color("#f0c050"), 1.1)
