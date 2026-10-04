extends SceneTree
# Generates the Warden (tower) spritesheets in assets/towers/ (64x80 frames: a 64x64 body with HEADROOM rows
# of headroom above it, tall Wardens 64x96; FRAMES per row) and
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
	"sporeling": ["sporeling", "driftspore", "puffball", "bloomcap", "dreamshroom", "fairy_ring", "elf_circle",
		"lichenling", "old_lichen", "brood_cap", "hatchery", "inkcap", "deliquescent"],
	"pebbling": ["pebbling", "mossback", "boulderback", "standing_stone", "moonstone", "cairn", "rockslide",
		"whetstone", "edgestone", "rampart", "bastion", "quaker", "earthshaker"],
	"bellflower": ["bellflower", "chime_stone", "lullaby_bell", "dreamcatcher", "great_dreamcatcher", "echo_hollow", "whispering_hollow",
		"silver_bell", "vesper_bell", "hushbell", "silence", "thrum", "resonance"],
	"dewdrop": ["dewdrop", "rain_lily", "monsoon", "mistveil", "morning_fog", "frostfern", "hoarfrost",
		"cloudlet", "nimbus", "undercurrent", "maelstrom", "jetreed", "torrent"],
	"firefly_jar": ["firefly_jar", "stormcap", "thunderhead", "lanternmoth", "beacon", "sunpetal", "midsummer",
		"jarlink", "lightning_fence", "prism_jar", "rainbow_prism", "sparkler", "starburst"],
	"rootling": ["rootling", "rootcurl", "long_way_home", "tangleroot", "snugroot", "rootlight", "starcave",
		"groundroot", "earthbind", "deeproot", "heartroot", "thorncoil", "crown_of_thorns"],
	"acorn": ["acorn", "elder_stump", "grove_heart", "dewcatcher", "wellspring", "graftling", "grafted_elder",
		"seedbearer", "grove_keeper", "nurse_log", "mother_log", "dream_oak", "dreamroot"],
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
	# Branch expansion (2026-10-02): Sporeling C, D, E.
	"lichenling": {kind = "projectile", projectile = "lichen_flake", point = Vector2i(46, 6)},
	"old_lichen": {kind = "projectile", projectile = "lichen_flake", point = Vector2i(48, 4)},
	"brood_cap": {kind = "spawn", projectile = "spore_sprite", point = Vector2i(44, 14)},
	"hatchery": {kind = "spawn", projectile = "spore_sprite", point = Vector2i(44, 14)},
	"inkcap": {kind = "projectile", projectile = "ink_drop", point = Vector2i(40, 12)},
	"deliquescent": {kind = "projectile", projectile = "ink_drop", point = Vector2i(40, 12)},
	"driftspore": {kind = "projectile", projectile = "spore", point = Vector2i(46, 9)},
	"puffball": {kind = "projectile", projectile = "spore", point = Vector2i(46, 9)},
	"bloomcap": {kind = "cloud", point = Vector2i(49, 14)},
	"dreamshroom": {kind = "cloud", point = Vector2i(49, 14)},
	"pebbling": {kind = "projectile", projectile = "pebble", point = Vector2i(46, 14)},
	"mossback": {kind = "projectile", projectile = "boulder", point = Vector2i(51, 8)},
	"boulderback": {kind = "projectile", projectile = "boulder", point = Vector2i(51, 8)},
	# Phase 2 (2026-10-02): Whetstone, Rampart, Quaker.
	"whetstone": {kind = "projectile", projectile = "whetstone_slash", point = Vector2i(52, 22)},
	"edgestone": {kind = "projectile", projectile = "whetstone_slash", point = Vector2i(52, 20)},
	"rampart": {kind = "pulse", point = Vector2i(31, 44)},
	"bastion": {kind = "pulse", point = Vector2i(31, 44)},
	"quaker": {kind = "pulse", point = Vector2i(31, 44)},
	"earthshaker": {kind = "pulse", point = Vector2i(31, 44)},
	"chime_stone": {kind = "pulse", point = Vector2i(31, 46)},
	"lullaby_bell": {kind = "pulse", point = Vector2i(31, 46)},
	"dewdrop": {kind = "projectile", projectile = "dew_drop", point = Vector2i(30, 2)},
	"rain_lily": {kind = "projectile", projectile = "dew_drop", point = Vector2i(30, 2)},
	# Branch expansion (2026-10-02): Dewdrop C, D, E. Rain / whirlpool zones and the jet are
	# drawn by the code (effects rain_zone, whirlpool, water_jet); the point is where they leave from.
	"cloudlet": {kind = "zone", point = Vector2i(11, 12)},
	"nimbus": {kind = "zone", point = Vector2i(52, 9)},
	"undercurrent": {kind = "zone", point = Vector2i(31, 44)},
	"maelstrom": {kind = "zone", point = Vector2i(31, 44)},
	"jetreed": {kind = "jet", point = Vector2i(60, 20)},
	"torrent": {kind = "jet", point = Vector2i(61, 18)},
	"monsoon": {kind = "pulse", point = Vector2i(31, 46)},
	"mistveil": {kind = "cloud", point = Vector2i(31, 46)},
	"morning_fog": {kind = "cloud", point = Vector2i(31, 46)},
	"firefly_jar": {kind = "projectile", projectile = "spark", point = Vector2i(31, 6)},
	# Branch expansion (2026-10-02): Firefly Jar C, D, E. The fence arc, crystal-split beams and
	# fireworks are drawn by the code (effects arc_fence, prism_beam, firework_burst).
	"jarlink": {kind = "fence", point = Vector2i(8, 9)},
	"lightning_fence": {kind = "fence", point = Vector2i(7, 7)},
	"prism_jar": {kind = "aura", point = Vector2i(30, 9)},
	"rainbow_prism": {kind = "beam", point = Vector2i(30, 9)},
	"sparkler": {kind = "firework", point = Vector2i(54, 12)},
	"starburst": {kind = "firework", point = Vector2i(56, 13)},
	"stormcap": {kind = "chain", point = Vector2i(40, 6)},
	"thunderhead": {kind = "chain", point = Vector2i(44, 5)},
	"lanternmoth": {kind = "projectile", projectile = "light_orb", point = Vector2i(31, 4)},
	"beacon": {kind = "pulse", point = Vector2i(31, 46)},
	"sunpetal": {kind = "beam", point = Vector2i(38, 12)},
	"rootling": {kind = "pulse", point = Vector2i(31, 46)},
	"rootcurl": {kind = "pull", point = Vector2i(60, 31)},
	"long_way_home": {kind = "pull", point = Vector2i(60, 31)},
	"tangleroot": {kind = "hold", point = Vector2i(31, 46)},
	# Phase 2 (2026-10-02): Groundroot, Deeproot, Thorncoil (pulses like Tangleroot, a root lash on the release).
	"groundroot": {kind = "pulse", point = Vector2i(31, 46)},
	"earthbind": {kind = "pulse", point = Vector2i(31, 46)},
	"deeproot": {kind = "pulse", point = Vector2i(31, 46)},
	"heartroot": {kind = "pulse", point = Vector2i(31, 46)},
	"thorncoil": {kind = "pulse", point = Vector2i(31, 46)},
	"crown_of_thorns": {kind = "pulse", point = Vector2i(31, 46)},
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
	# Branch expansion (2026-10-02): Bellflower C, D, E. The toll ring, silence and sound cone are
	# drawn by the code (effects toll_ring, silence_mark, sound_cone).
	"silver_bell": {kind = "toll", point = Vector2i(45, 14)},
	"vesper_bell": {kind = "toll", point = Vector2i(48, 16)},
	"hushbell": {kind = "aura", point = Vector2i(31, 40)},
	"silence": {kind = "aura", point = Vector2i(31, 40)},
	"thrum": {kind = "cone", point = Vector2i(51, 9)},
	"resonance": {kind = "cone", point = Vector2i(47, 8)},
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
			if warden in CHANNEL_WARDENS:
				_make_channel(warden)
		_save_line_preview(rows, PREVIEWS + line + ".png")
	for wall: String in ["thornwall", "bramble", "honeysuckle"]:
		_make(wall + "_stone", Callable(self, "_draw_" + wall + "_stone"))
	if not overflow.is_empty():
		push_warning("Wardens cut off at the top of their frame (rows above the body): %s" % overflow)
	_save_attack_info()
	_make_ranks()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "projectiles/"))
	for p: String in ["spore", "pebble", "boulder", "dew_drop", "spark", "light_orb", "sling_stone", "moon_shard",
			"frost_shard", "sparrow", "wren", "magpie", "starling", "moon_mote", "fairy_ring", "elf_circle",
			"dream_mote", "lob_stone", "hummingbird", "maple_seed", "autumn_seed", "starling_bird",
			"lichen_flake", "ink_drop", "spore_sprite", "whetstone_slash"]:
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
	_warden_name = tower_name
	var h := _frame_h(tower_name)
	var sheet := Image.create_empty(S * FRAMES, h, false, Image.FORMAT_RGBA8)
	for f in FRAMES:
		OY = HEADROOM
		var canvas := _layer()
		var st := _idle_state(f)
		draw.call(canvas, st)
		_final_extra(tower_name, canvas, st)
		sheet.blit_rect(_tall_frame(tower_name, canvas, st), Rect2i(0, 0, S, h), Vector2i(f * S, 0))
	sheet = _warden_night(_detail_pass(sheet, Vector2i(S, h), true))
	if NIGHT_RIM.has(tower_name):
		_night_rim(sheet, HeartwoodPalette_color(NIGHT_RIM[tower_name]))
	sheet.save_png(OUT + tower_name + ".png")
	return sheet

# The darkest Wardens sink into the night-indigo map ground (2026-09-30 re-theme), so they get a thin
# moonlit rim: the silhouette's edge on its lit (top / left) sides, where it's dark, turns
# one lighter palette colour. A hand fix inside Warden Night: no new colours.
const NIGHT_RIM := {"firefly_jar": "Stone", "stormcap": "Stone", "thunderhead": "Stone", "jarlink": "Stone",
	"lightning_fence": "Stone", "prism_jar": "Stone", "rainbow_prism": "Stone", "sparkler": "Stone", "starburst": "Stone",
	"starling_murmuration": "Stone", "thornwall": "Sprig"}

func HeartwoodPalette_color(color_name: String) -> Color:
	return (load(PALETTE) as Script).color(color_name)

func _night_rim(sheet: Image, rim: Color) -> void:
	# The silhouette's own edge pixels on its lit sides (open space above or to the left) turn the rim
	# colour where they're dark; right and bottom edges keep their dark outline.
	var src := sheet.duplicate() as Image
	var w := sheet.get_width()
	var h := sheet.get_height()
	var lum := func(c: Color) -> float: return c.r * 0.3 + c.g * 0.59 + c.b * 0.11
	for y in range(1, h):
		for x in range(1, w):
			var c := src.get_pixel(x, y)
			if c.a < 1.0 or lum.call(c) > 0.3 or x % S == 0:
				continue
			if src.get_pixel(x - 1, y).a < 0.6 or src.get_pixel(x, y - 1).a < 0.6:
				sheet.set_pixel(x, y, rim)

# Warden Night (art_direction.md, 2026-09-30): idle sheets only step one shade darker inside their
# own ramp (HeartwoodPalette.warden_night, after the palette pass), so the Wardens sit in the fog.
# Attack sheets, projectiles and glows keep full warm light. Alpha is kept, so glow halos stay.
const PALETTE := "res://tools/art/heartwood_palette.gd"

func _warden_night(sheet: Image) -> Image:
	if not ResourceLoader.exists(PALETTE):
		return sheet
	var palette: Script = load(PALETTE)
	if not palette.has_method("warden_night"):
		push_warning("HeartwoodPalette.warden_night missing: saving idle sheets without Warden Night")
		return sheet
	return palette.warden_night(sheet)

# Everything else these generators save (projectiles, rank art, Ascended extras) is snapped to the
# plain Heartwood 32 (art_direction.md): RGB to the nearest palette colour, alpha kept, so glows
# stay translucent in palette colours. Left as drawn when the palette tool isn't present.
func _snap32(img: Image) -> Image:
	if ResourceLoader.exists(PALETTE):
		(load(PALETTE) as Script).snap_image(img)
	return img

# The Heartwood 32 palette and the detailed-64 pass (tools/art/detail_pass.gd, art_direction.md
# "Rendering style"): every Warden sheet goes through it before saving, frame by frame. Loaded by
# path so the generator still runs where the tools aren't present (then the art is left as drawn).
const DETAIL_PASS := "res://tools/art/detail_pass.gd"

func _detail_pass(sheet: Image, frame: Vector2i, idle: bool = false) -> Image:
	if not ResourceLoader.exists(DETAIL_PASS):
		push_warning("tools/art/detail_pass.gd not found: saving Warden art without the palette pass")
		return sheet
	var pass_script: Script = load(DETAIL_PASS)
	# Calm mode (AI-look audit, 4bb3b376): no grain, in-ramp shading; idle sheets get no glow at all
	# (glow marks the attack), attack sheets keep it in two hard steps.
	return pass_script.apply_sheet(sheet, frame, pass_script.Kind.WARDEN, -1 if idle else 0, 1.0, true)

# <name>_attack.png: the Warden's body in attack poses plus its attack effect on top.
func _make_attack(tower_name: String) -> Image:
	_warden_name = tower_name
	var h := _frame_h(tower_name)
	var sheet := Image.create_empty(S * ATTACK_FRAMES, h, false, Image.FORMAT_RGBA8)
	for a in ATTACK_FRAMES:
		OY = HEADROOM
		var canvas := _layer()
		var st := _attack_state(a)
		call("_draw_" + tower_name, canvas, st)
		_final_extra(tower_name, canvas, st)
		call("_attack_" + tower_name, canvas, st)
		sheet.blit_rect(_tall_frame(tower_name, canvas, st), Rect2i(0, 0, S, h), Vector2i(a * S, 0))
	sheet = _detail_pass(sheet, Vector2i(S, h))
	sheet.save_png(OUT + tower_name + "_attack.png")
	return sheet

# Tall Wardens (64x96 frames, the body's 64x64 frame in the bottom 64 rows; the 32 rows above hold
# what rises over it). In game: TowerData.sprite_offset (0, -16) keeps the slab on its cell, and the
# attacks.json point stays in body-frame pixels (it's measured from the body, not the tall frame).
const TALL_WARDENS := ["beacon", "thunderhead", "wellspring", "elf_circle", "starcave", "snugroot", "grafted_elder", "midsummer", "puffball", "monsoon"]
const TALL_H := 96
# Rows of headroom over the 64x64 body: every Warden is drawn with them (see OY) and the frame keeps
# them (64x80; tall Wardens 64x96), so nothing is cut off at the top. Wardens that still rise past
# their frame are collected in `overflow` and warned about.
const HEADROOM := 16
var overflow := {}

func _frame_h(tower_name: String) -> int:
	return TALL_H if tower_name in TALL_WARDENS else S + HEADROOM

# Puts a drawn 64x64 body frame into its tall frame with the Warden's tall parts (behind and in front).
func _tall_frame(tower_name: String, body: Image, st: Dictionary) -> Image:
	# The body was drawn with HEADROOM rows of headroom (OY); the frame keeps what fits its height.
	var head := OY
	OY = 0
	var top := _top_row(body) - head
	var h := _frame_h(tower_name)
	if top < S - h:
		overflow[tower_name] = mini(overflow.get(tower_name, 0), top)
	var frame := Image.create_empty(S, h, false, Image.FORMAT_RGBA8)
	if not tower_name in TALL_WARDENS:
		frame.blit_rect(body, Rect2i(0, S + head - h, S, h), Vector2i.ZERO)
		return frame
	var back := _layer()   # tall-frame rows 0..63
	var front := _layer()
	call("_tall_" + tower_name, back, front, st)
	frame.blend_rect(back, Rect2i(0, 0, S, S), Vector2i.ZERO)
	frame.blend_rect(body, Rect2i(0, 0, S, S + head), Vector2i(0, TALL_H - S - head))
	frame.blend_rect(front, Rect2i(0, 0, S, S), Vector2i.ZERO)
	if has_method("_tall_full_" + tower_name):
		call("_tall_full_" + tower_name, frame, st)  # drawn over the whole 64x96 frame
	return frame

# The first image row with anything on it (the image height when empty).
func _top_row(img: Image) -> int:
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				return y
	return img.get_height()

# A thick outlined stroke straight onto a tall frame (any size), for parts spanning body and tall rows.
func _tall_stroke(frame: Image, pts: Array, r: float, color: Color, o: Color) -> void:
	var w := frame.get_width()
	var h := frame.get_height()
	var layer := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var steps := int(a.distance_to(b) * 2.0) + 1
		for s in steps + 1:
			var p := a.lerp(b, s / float(steps))
			for y in range(floori(p.y - r), ceili(p.y + r) + 1):
				for x in range(floori(p.x - r), ceili(p.x + r) + 1):
					if x >= 0 and y >= 0 and x < w and y < h and Vector2(x + 0.5, y + 0.5).distance_to(p) <= r:
						_sp(layer, x, y, color)
	for y in h:
		for x in w:
			if _gp(layer, x, y).a == 0.0:
				continue
			var edge := false
			for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var q := Vector2i(x, y) + d
				if q.x < 0 or q.y < 0 or q.x >= w or q.y >= h or _gpv(layer, q).a == 0.0:
					edge = true
			frame.set_pixel(x, y, o if edge else color)

# <name>_channel.png for the BEAM Wardens (Sunpetal, Midsummer): 3 frames the game ping-pongs while
# the beam is held (TowerData.beam_sustain_texture). The code draws the beam itself, toward the
# target in any direction, so these frames draw no ray: the flower in its release pose, glowing and
# pouring light from the attack point (attacks.json), sparks round it on every side.
const CHANNEL_WARDENS := ["sunpetal", "midsummer"]
const CHANNEL_FRAMES := 3

func _make_channel(tower_name: String) -> Image:
	_warden_name = tower_name
	var h := _frame_h(tower_name)
	var sheet := Image.create_empty(S * CHANNEL_FRAMES, h, false, Image.FORMAT_RGBA8)
	var at := Vector2(ATTACKS[tower_name].point)
	for c in CHANNEL_FRAMES:
		OY = HEADROOM
		var canvas := _layer()
		var st := _attack_state(RELEASE_FRAME)
		st.f = c
		st.power = [0.85, 1.0, 0.9][c]
		call("_draw_" + tower_name, canvas, st)
		_final_extra(tower_name, canvas, st)
		# The pouring light: a bright core on the flower's face, a ring that breathes, eight short
		# sparks round it (no direction), all warm.
		var r: float = [2.0, 2.6, 2.3][c]
		var core := _layer()
		_flat_ellipse(core, at + Vector2(0.5, 0.5), Vector2(r, r), Color("#fff4a0"))
		_stamp(canvas, core)
		_px(canvas, int(at.x), int(at.y), Color.WHITE)
		for k in 8:
			var d := Vector2.from_angle(k * TAU / 8.0 + c * TAU / 24.0)
			var len := 2 + (k + c) % 2
			for i in range(int(r) + 2, int(r) + 2 + len):
				_px(canvas, roundi(at.x + d.x * i), roundi(at.y + d.y * i), Color("#ffd24a") if i > int(r) + 2 else Color("#fff4a0"))
		_warm_glow(canvas, at, Vector2(8.0 + c, 7.0 + c), c)
		sheet.blit_rect(_tall_frame(tower_name, canvas, st), Rect2i(0, 0, S, h), Vector2i(c * S, 0))
	sheet = _detail_pass(sheet, Vector2i(S, h))
	sheet.save_png(OUT + tower_name + "_channel.png")
	return sheet

func _save_attack_info() -> void:
	var wardens := {}
	for warden: String in ATTACKS:
		var info: Dictionary = ATTACKS[warden].duplicate()
		info.point = [info.point.x, info.point.y]
		wardens[warden] = info
	# Where the Dew catchers' bowls sit (the bowl's surface centre and radii at dy 0), and how far the
	# bowl bobs per idle frame (add dy_by_frame[frame] to point.y). Fill overlays in effects.json
	# (catcher_fill_<id>) are drawn to line up with the sprite already.
	var idle_dy: Array = []
	for f in FRAMES:
		idle_dy.append(_idle_state(f).dy)
	var bowls := {
		dewcatcher = {point = [30, 5], radius = [11, 2], dy_by_frame = idle_dy},
		wellspring = {point = [30, 5], radius = [7, 1], dy_by_frame = idle_dy},
	}
	var data := {frame_size = S, frames = ATTACK_FRAMES, release_frame = RELEASE_FRAME, wardens = wardens, bowls = bowls}
	var file := FileAccess.open(OUT + "attacks.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t") + "\n")

# One row per Warden on grass: its idle loop, a gap, then its attack. Scaled up for eyeballing.
func _save_line_preview(rows: Array, path: String) -> void:
	var pad := 6
	var gap := 24
	var width := pad + FRAMES * (S + pad) + gap + ATTACK_FRAMES * (S + pad)
	var fh := TALL_H  # every row as tall as the tallest frame, bodies lined up at the bottom
	var preview := Image.create_empty(width, pad + rows.size() * (fh + pad), false, Image.FORMAT_RGBA8)
	preview.fill(Color("#5fa844"))
	for i in rows.size():
		var idle: Image = rows[i][0]
		var h := idle.get_height()
		var y := pad + i * (fh + pad) + fh - h
		for f in FRAMES:
			preview.blend_rect(idle, Rect2i(f * S, 0, S, h), Vector2i(pad + f * (S + pad), y))
		if rows[i][1] != null:
			var attack: Image = rows[i][1]
			for a in ATTACK_FRAMES:
				preview.blend_rect(attack, Rect2i(a * S, 0, S, h), Vector2i(pad + FRAMES * (S + pad) + gap + a * (S + pad), y))
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

# Draws the figure and returns its mask (for decorations that should only land on the golem). The
# two little rocks beside the golem are the same neutral stone on every Warden (ROCK_PAL).
func _draw_template_figure(canvas: Image, pose: Dictionary, pal: Dictionary) -> Image:
	pal = _body_pal(pal)
	var mask := _layer()
	for i in S * S:
		var ch: String = pose.grid[i]
		if ch != "." and pose.outside[i] == 0:
			var rock := _is_rock(pose, i % S, i / S)
			if rock and _rock_group(i % S, i / S) in _hidden_rocks():
				continue  # This Warden's own props stand there.
			_sp(canvas, i % S, i / S, ROCK_PAL[ch] if rock else pal[ch])
			if not rock:
				_sp(mask, i % S, i / S, Color.WHITE)
	var rock_px := {}
	for i in S * S:
		if pose.grid[i] != "." and pose.outside[i] == 0 and _is_rock(pose, i % S, i / S) \
				and not _rock_group(i % S, i / S) in _hidden_rocks():
			rock_px[Vector2i(i % S, i / S)] = true
	_touch_rocks(canvas, rock_px, _rock_touch_for(_warden_name))
	return mask

# --- The rocks' family touches -------------------------------------------------------------------
# The rocks are the same stone everywhere; each family leaves a small mark on them: moss, ice, a
# wet sheen, tiny mushrooms, resting fireflies... Set per Warden while its sheets are drawn.

var _warden_name := ""
const ROCK_TOUCH_LINES := {
	"sporeling": "spores", "dewdrop": "wet", "firefly_jar": "fireflies", "pebbling": "lichen",
	"rootling": "roots", "bellflower": "bells", "acorn": "acorns", "nestling": "twigs",
	"whirligig": "seeds", "memory": "runes", "starters": "leaves",
}
const ROCK_TOUCH_WARDENS := {
	"frostfern": "ice", "hoarfrost": "ice", "sunpetal": "moss", "midsummer": "moss",
	"thornwall": "thorns", "bramble": "thorns", "honeysuckle": "thorns",
}
# Rocks hidden where a Warden's own props stand (left / right / front of the golem).
const HIDDEN_ROCKS := {
	"echo_hollow": ["left"], "whispering_hollow": ["left"], "starcave": ["left"],
	# The Pebbling line's own stones stand there: the menhir, the cairn stack.
	"standing_stone": ["left"], "moonstone": ["left"], "cairn": ["left"], "rockslide": ["left"],
}

func _hidden_rocks() -> Array:
	return HIDDEN_ROCKS.get(_warden_name, [])

func _rock_touch_for(warden: String) -> String:
	if ROCK_TOUCH_WARDENS.has(warden):
		return ROCK_TOUCH_WARDENS[warden]
	for line: String in LINES:
		if warden in LINES[line]:
			return ROCK_TOUCH_LINES.get(line, "")
	return ""

# Which of the three rocks a template pixel belongs to.
func _rock_group(tx: int, ty: int) -> String:
	if ty >= 42 or (tx >= 32 and tx <= 43 and ty >= 38):
		return "front"
	return "left" if tx < 26 else "right"

# Marks the rock pixels `px` ({Vector2i: true}, in canvas pixels) with a family touch. Works on any
# canvas size (the Ascended layer is 128 px).
func _touch_rocks(canvas: Image, px: Dictionary, touch: String) -> void:
	if touch == "" or px.is_empty():
		return
	var w := canvas.get_width()
	var h := canvas.get_height()
	var put := func(p: Vector2i, c: Color) -> void:
		if p.x >= 0 and p.y >= -OY and p.x < w and p.y < h - OY:
			_spv(canvas, p, c)
	var tops: Array[Vector2i] = []  # rock pixels with open space above: where things settle
	for p: Vector2i in px:
		if not px.has(p + Vector2i.UP) and _gpv(canvas, p) != ROCK_PAL.o:
			tops.append(p)
	tops.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x)
	var hash := func(p: Vector2i) -> int: return absi(p.x * 73 + p.y * 151) % 7
	match touch:
		"moss", "lichen", "leaves":
			var greens: Array = [Color("#5a9a48"), Color("#8ad060")] if touch != "lichen" else [Color("#a8b860"), Color("#d8d890")]
			for p in tops:
				put.call(p, greens[1])
				if hash.call(p) < 4:
					put.call(p + Vector2i.DOWN, greens[0])
		"ice":
			for p: Vector2i in px:
				var c := _gpv(canvas, p)
				if c != ROCK_PAL.o:
					put.call(p, c.lerp(Color("#bfe8ff"), 0.4))
			for p in tops:
				put.call(p, Color("#eefaff"))
				if hash.call(p) == 0:
					put.call(p + Vector2i.DOWN, Color.WHITE)
		"wet":
			for p in tops:
				if hash.call(p) < 5:
					put.call(p, Color("#9ad4ff"))
			if tops.size() > 2:
				put.call(tops[tops.size() / 2] + Vector2i(0, 2), Color("#e8f8ff"))
		"spores":
			for k in range(1, tops.size(), 4):
				var p: Vector2i = tops[k]
				put.call(p, Color("#f0e4d8"))
				put.call(p + Vector2i(0, -1), Color("#e070c0"))
				put.call(p + Vector2i(-1, -1), Color("#e070c0"))
				put.call(p + Vector2i(1, -1), Color("#f7a8e8"))
		"fireflies":
			for k in range(0, tops.size(), 5):
				var p: Vector2i = tops[k] + Vector2i(0, 1)
				put.call(p, Color("#fff27a"))
		"roots":
			for p: Vector2i in px:
				if (p.y + p.x / 3) % 4 == 0 and _gpv(canvas, p) != ROCK_PAL.o:
					put.call(p, Color("#7a5234"))
		"bells":
			for k in range(1, tops.size(), 5):
				var p: Vector2i = tops[k] + Vector2i(0, -1)
				put.call(p, Color("#c0a8ec"))
				put.call(p + Vector2i(1, 0), Color("#9a80d0"))
				put.call(p + Vector2i(0, 1), Color("#58964a"))
		"acorns":
			for k in range(2, tops.size(), 7):
				var p: Vector2i = tops[k] + Vector2i(0, -1)
				put.call(p, Color("#7a5234"))
				put.call(p + Vector2i(0, 1), Color("#d49c54"))
				put.call(p + Vector2i(1, 1), Color("#b07a3a"))
		"twigs":
			for k in range(0, tops.size(), 6):
				var p: Vector2i = tops[k]
				put.call(p + Vector2i(-1, 0), Color("#8a6040"))
				put.call(p, Color("#a07850"))
				put.call(p + Vector2i(1, -1), Color("#8a6040"))
			if tops.size() > 3:
				put.call(tops[3] + Vector2i(0, -1), Color("#f4f2f0"))
		"seeds":
			for k in range(2, tops.size(), 8):
				var p: Vector2i = tops[k] + Vector2i(0, -1)
				put.call(p, Color("#b0602e"))
				put.call(p + Vector2i(1, 0), Color("#f0b070"))
				put.call(p + Vector2i(2, -1), Color("#f8d8a0"))
		"runes":
			for p: Vector2i in px:
				if hash.call(p) == 0 and _gpv(canvas, p) != ROCK_PAL.o:
					put.call(p, Color("#c8b0ff"))
		"thorns":
			for k in range(0, tops.size(), 3):
				var p: Vector2i = tops[k]
				put.call(p, Color("#58964a"))
				put.call(p + Vector2i(0, -1), Color("#d8c090"))

# The mock's three rocks: left of the golem, right of it, and one in front of its seat. The template
# draws them with facet lines, so a rock is found by region: the template is split into regions of
# fill pixels by its 'o' lines, and every region lying mostly inside a rock zone is rock, plus the
# 'o' pixels that only border rock (or nothing).
const ROCK_PAL := {o = Color("#1e1c28"), a = Color("#b9b6c6"), b = Color("#8f8ca2"), c = Color("#65627a")}
# The same stone as a shading ramp, for loose props that lie on the ground beside the side rocks
# (pebbles, cairn stacks, rockslide boulders) so they match them instead of the golem's body.
const ROCK_RAMP := ["#65627a", "#8f8ca2", "#b9b6c6", "#d6d3e0"]
var _rock_cache := {}  # pose grid -> {index: true}

func _rock_zone(x: int, y: int) -> bool:
	if y >= 33 and y <= 41 and x <= (17 if y <= 35 else 15):
		return true  # left
	if (y >= 30 and y <= 38 and x >= 47) or (y >= 39 and y <= 41 and x >= 44):
		return true  # right (its lower-left corner tucks in under the arm; the arm itself is x 43-46)
	return y >= 39 and y <= 47 and x >= 33 and x <= 45  # in front of the golem's seat

func _is_rock(pose: Dictionary, x: int, y: int) -> bool:
	if x < 0 or y < 0 or x >= S or y >= S:
		return false
	var key: int = pose.grid.hash()
	if not _rock_cache.has(key):
		_rock_cache[key] = _find_rocks(pose)
	return (_rock_cache[key] as Dictionary).has(y * S + x)

func _find_rocks(pose: Dictionary) -> Dictionary:
	var fill := func(i: int) -> bool:
		var ch: String = pose.grid[i]
		return ch != "." and ch != "o" and pose.outside[i] == 0
	var rocks := {}
	var seen := {}
	for start in S * S:
		if seen.has(start) or not fill.call(start):
			continue
		var region: Array[int] = [start]
		seen[start] = true
		var k := 0
		while k < region.size():
			var i: int = region[k]
			k += 1
			for n: int in [i - 1, i + 1, i - S, i + S]:
				if n < 0 or n >= S * S or seen.has(n) or absi(n % S - i % S) > 1 or not fill.call(n):
					continue
				seen[n] = true
				region.append(n)
		var inside := 0
		for i in region:
			if _rock_zone(i % S, i / S):
				inside += 1
		if inside * 2 > region.size():
			for i in region:
				rocks[i] = true
	# Outline pixels that only border rock pixels or empty space belong to the rock too.
	for i in S * S:
		if pose.grid[i] != "o" or pose.outside[i] == 1:
			continue
		var touches_rock := false
		var touches_body := false
		for n: int in [i - 1, i + 1, i - S, i + S]:
			if n < 0 or n >= S * S or absi(n % S - i % S) > 1:
				continue
			if rocks.has(n):
				touches_rock = true
			elif fill.call(n):
				touches_body = true
		if touches_rock and not touches_body:
			rocks[i] = true
	return rocks

func _blink(canvas: Image, dy: int, skin: Color, outline: Color) -> void:
	for ex: int in EYES:
		_px(canvas, ex, EYE_TOP + dy, skin)
		_px(canvas, ex, EYE_TOP + 2 + dy, skin)
		_px(canvas, ex + 1, EYE_TOP + 1 + dy, outline)

# --- Primitives -------------------------------------------------------------------------------

# Headroom: while a Warden frame is drawn, canvases are OY rows taller than S and drawing
# coordinates stay body-frame pixels (row y lives at image row y + OY), so parts that rise above the
# 64x64 body (hats, leaves, glows, the attack stretch) aren't cut off. 0 everywhere else.
var OY := 0

func _layer() -> Image:
	return Image.create_empty(S, S + OY, false, Image.FORMAT_RGBA8)

func _gp(img: Image, x: int, y: int) -> Color:
	return img.get_pixel(x, y + OY)

func _sp(img: Image, x: int, y: int, c: Color) -> void:
	img.set_pixel(x, y + OY, c)

func _gpv(img: Image, p: Vector2i) -> Color:
	return img.get_pixel(p.x, p.y + OY)

func _spv(img: Image, p: Vector2i, c: Color) -> void:
	img.set_pixel(p.x, p.y + OY, c)

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
	for y in range(maxi(-OY, floori(c.y - r.y)), mini(S, ceili(c.y + r.y) + 1)):
		for x in range(maxi(0, floori(c.x - r.x)), mini(S, ceili(c.x + r.x) + 1)):
			var p := Vector2(x + 0.5, y + 0.5)
			if p.y > max_y:
				continue
			var d := (p - c) / r
			var q := d.length_squared()
			if q <= 1.0:
				_sp(layer, x, y, _shade(ramp, Vector3(d.x, d.y, sqrt(1.0 - q))))

func _flat_ellipse(layer: Image, c: Vector2, r: Vector2, color: Color) -> void:
	for y in range(maxi(-OY, floori(c.y - r.y)), mini(S, ceili(c.y + r.y) + 1)):
		for x in range(maxi(0, floori(c.x - r.x)), mini(S, ceili(c.x + r.x) + 1)):
			if ((Vector2(x + 0.5, y + 0.5) - c) / r).length_squared() <= 1.0:
				_sp(layer, x, y, color)

# Faceted stone: pixels are grouped into wedges around the centre, each wedge lit as a flat face.
func _rock(canvas: Image, pts: PackedVector2Array, ramp: Array[Color], outline: Color) -> void:
	var centre := Vector2.ZERO
	for p in pts:
		centre += p
	centre /= pts.size()
	var layer := _layer()
	for y in range(-OY, S):
		for x in S:
			var p := Vector2(x + 0.5, y + 0.5)
			if not Geometry2D.is_point_in_polygon(p, pts):
				continue
			var d := p - centre
			var n := Vector3(0, -0.3, 1)
			if d.length() > 2.0:
				var a := snappedf(d.angle(), TAU / 6.0)
				n = Vector3(cos(a), sin(a), 0.8)
			_sp(layer, x, y, _shade(ramp, n.normalized()))
	_stamp(canvas, layer, outline)

func _line(canvas: Image, pts: Array, color: Color, mask: Image = null) -> void:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
		for s in steps + 1:
			var p := a.lerp(b, s / maxf(steps, 1.0)).round()
			if mask == null or _gp(mask, int(p.x), int(p.y)).a > 0.0:
				_px(canvas, int(p.x), int(p.y), color)

func _px(canvas: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= -OY and x < S and y < S:
		_sp(canvas, x, y, color)

# Copies a layer onto the canvas, turning the layer's own border pixels into an outline.
func _stamp(canvas: Image, layer: Image, outline: Color = Color(0, 0, 0, 0)) -> void:
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for y in range(-OY, S):
		for x in S:
			var col := _gp(layer, x, y)
			if col.a == 0.0:
				continue
			if outline.a > 0.0:
				for d: Vector2i in dirs:
					var p: Vector2i = Vector2i(x, y) + d
					if p.x < 0 or p.y < -OY or p.x >= S or p.y >= S or _gpv(layer, p).a == 0.0:
						col = outline
						break
			_sp(canvas, x, y, col)

func _pal(o: String, a: String, b: String, c: String) -> Dictionary:
	return {o = Color(o), a = Color(a), b = Color(b), c = Color(c)}

# --- Projectiles ------------------------------------------------------------------------------
# 24x24 frames, 4 per sheet, drawn pointing right (+x) so the game can rotate them to face travel.
# Drawn round (32, 32) of the work canvas. Projectile / PeckingBird / SeedBoomerang / PatrolFlight
# read the frame size from the texture.

const P := 24
const P_FRAMES := 4
const P_AT := 20  # the frame's top-left on the work canvas
# Shots that light themselves in their own colour, and traps (they lie on the path, unlit).
const P_OWN_GLOW := ["dew_drop", "spark", "light_orb", "moon_shard", "frost_shard", "moon_mote", "dream_mote",
	"fairy_ring", "elf_circle", "spore_sprite"]  # spore_sprite: its own warm rim
var projectile_sheets: Array[Image] = []

func _make_projectile(proj_name: String) -> void:
	var sheet := Image.create_empty(P * P_FRAMES, P, false, Image.FORMAT_RGBA8)
	for f in P_FRAMES:
		var canvas := _layer()
		call("_proj_" + proj_name, canvas, f)
		if not proj_name in P_OWN_GLOW:
			_soft_glow(canvas, Vector2(32, 32), Vector2(10.5, 9), f)  # every Warden shot glows warmly
		sheet.blit_rect(canvas, Rect2i(P_AT, P_AT, P, P), Vector2i(f * P, 0))
	_snap32(sheet).save_png(OUT + "projectiles/" + proj_name + ".png")
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

# Soft warm light round a projectile: translucent steps (not dithered) so it reads as a glow at any
# zoom, breathing a little with the frame. It only lights empty pixels: draw it after the shot.
func _soft_glow(canvas: Image, c: Vector2, r: Vector2, f: int = 0, col: Color = GLOW_OUTER, strength: float = 0.34) -> void:
	var rr: Vector2 = r * (1.0 + [0.0, 0.06, 0.1, 0.06][f % 4])
	for y in range(-OY, S):
		for x in S:
			if _gp(canvas, x, y).a > 0.0:
				continue
			var q: float = ((Vector2(x + 0.5, y + 0.5) - c) / rr).length()
			if q >= 1.0:
				continue
			var a := snappedf(strength * pow(1.0 - q, 1.5), 0.05)
			if a > 0.0:
				_sp(canvas, x, y, Color(col.lerp(GLOW_INNER, 1.0 - q), a))

# A pixel that only lands on empty canvas (trails and streaks stay behind the shot).
func _px_under(canvas: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= -OY and x < S and y < S and _gp(canvas, x, y).a == 0.0:
		_sp(canvas, x, y, color)

# A fading, wavy trail running left (behind the shot) from `from`, broken up towards its end.
func _trail(canvas: Image, from: Vector2, length: int, col: Color, f: int, wobble: float = 0.0) -> void:
	for k in length:
		var t := k / float(length)
		if t > 0.5 and (k + f) % 2 == 1:
			continue
		var p := from + Vector2(-k, sin((k + f * 2) * 0.8) * wobble * t)
		_px_under(canvas, roundi(p.x), roundi(p.y), Color(col, snappedf(0.95 * (1.0 - t), 0.1)))

# Speed dashes behind a thrown stone.
func _speed_lines(canvas: Image, at: Vector2, f: int, col: Color) -> void:
	for k in 3:
		var y := roundi(at.y) + (k - 1) * 4
		var x0 := roundi(at.x) - (f + k) % 2 - (1 if k == 1 else 0)
		var n := 4 if k == 1 else 3
		for i in n:
			_px_under(canvas, x0 - i, y, Color(col, 0.8 - i * 0.18))

# Cracks and a moss tuft that turn with a _spinning_rock (TAU/24 per frame).
func _rock_marks(canvas: Image, c: Vector2, f: int, r: float) -> void:
	var a := f * TAU / 24.0
	var crack := c + Vector2.from_angle(a + 0.9) * r * 0.2
	for i in 3:
		var p := crack + Vector2.from_angle(a + 0.9 + (0.5 if i == 2 else 0.0)) * i
		_px(canvas, roundi(p.x), roundi(p.y), Color("#4a4e7a"))
	var moss := c + Vector2.from_angle(a - 2.1) * r * 0.55
	_px(canvas, roundi(moss.x), roundi(moss.y), Color("#7cbc5a"))
	_px(canvas, roundi(moss.x) + 1, roundi(moss.y), Color("#5a9a3a"))
	_px(canvas, roundi(moss.x), roundi(moss.y) - 1, Color("#a8dc78"))
	var shine := c + Vector2(-0.35, -0.5) * r
	_px(canvas, roundi(shine.x), roundi(shine.y), Color("#f4f6ff"))

# A fluffy spore puff trailing loose spores (Sprout, Sporeling, Puffball, Driftspore).
func _proj_spore(canvas: Image, f: int) -> void:
	var puff := _ramp(["#8aa040", "#c8dc78", "#eef6b0", "#ffffff"])
	var g: float = [0.0, 0.4, 0.8, 0.4][f]
	var layer := _layer()
	_ellipse(layer, Vector2(34, 32), Vector2(5.0 + g, 4.6 + g), puff)
	_ellipse(layer, Vector2(29.5, 34), Vector2(3.2, 3.0), puff)
	_ellipse(layer, Vector2(30.5, 28.5), Vector2(3.0, 2.8), puff)
	_ellipse(layer, Vector2(37.5, 35.5), Vector2(2.4, 2.2), puff)
	_stamp(canvas, layer, Color("#2a3a1a"))
	for d: Vector2i in [Vector2i(33, 31), Vector2i(36, 33), Vector2i(30, 34), Vector2i(29, 28), Vector2i(35, 29)]:
		_px(canvas, d.x + (f % 2 if d.x > 32 else 0), d.y, Color("#9ab04a"))
	_px(canvas, 32, 29, Color.WHITE)
	_px(canvas, 33, 29, Color.WHITE)
	for k in 4:
		var p := Vector2(25.0 - k * 2.5, 32.0 + sin(f * PI / 2.0 + k * 2.0) * 2.5)
		_px_under(canvas, roundi(p.x), roundi(p.y), Color("#e8f4a8") if k < 2 else Color("#b8d470", 0.7))
		if k == 0:
			_px_under(canvas, roundi(p.x) + 1, roundi(p.y), Color("#c8dc78"))

func _proj_pebble(canvas: Image, f: int) -> void:
	_spinning_rock(canvas, f, 5.5, _ramp(["#686d9a", "#979dc2", "#c4c9e2", "#e4e7f4"]), Color("#1c1c36"))
	_rock_marks(canvas, Vector2(32, 32), f, 5.5)
	_speed_lines(canvas, Vector2(25, 32), f, Color("#e4e7f4"))

# A heavy mossy boulder (Boulderback, Mossback).
func _proj_boulder(canvas: Image, f: int) -> void:
	var c := Vector2(33, 32)
	var pts := PackedVector2Array()
	var radii := [1.0, 0.82, 0.95, 0.78, 1.0, 0.86, 0.92]
	for k in 7:
		pts.append(c + Vector2.from_angle(k * TAU / 7.0 + f * TAU / 28.0) * 9.0 * radii[k])
	_rock(canvas, pts, _ramp(STONE), Color("#1c1c36"))
	_rock_marks(canvas, c, f, 8.0)
	# A moss cap on whichever side is up.
	var top := c + Vector2.from_angle(-PI / 2.0 + f * TAU / 28.0) * 5.0
	for dx in range(-3, 4):
		_px(canvas, roundi(top.x) + dx, roundi(top.y) + (1 if absi(dx) == 3 else 0), Color("#5a9a3a" if dx % 2 else "#7cbc5a"))
	_px(canvas, roundi(top.x), roundi(top.y) - 1, Color("#a8dc78"))
	_speed_lines(canvas, Vector2(22, 32), f, Color("#e4e7f4"))

# A water bead flying right: round front, wobbling tail, a bubble inside, spray behind.
func _proj_dew_drop(canvas: Image, f: int) -> void:
	var water := _ramp(["#2a60b0", "#4a90dc", "#8ac8f8", "#e8faff"])
	var wob: float = [0.0, 0.3, 0.0, -0.3][f]
	var layer := _layer()
	for step in 20:
		var t := step / 19.0
		var rr := 5.0 * pow(1.0 - t, 1.25)
		if rr >= 0.5:
			_ellipse(layer, Vector2(36 - t * 14, 32 + sin(t * 3.0 + f) * wob * 2.0), Vector2(rr * (1.0 + wob * 0.1), rr * (1.0 - wob * 0.1)), water)
	_stamp(canvas, layer, Color("#12285a"))
	_px(canvas, 37, 29, water[3])
	_px(canvas, 38, 30, water[3])
	_px(canvas, 36, 29, water[3])
	_px(canvas, 33, 34, Color("#bfe6ff"))
	_px(canvas, 34, 33, Color("#bfe6ff"))
	for k in 3:
		var p := Vector2(22.0 - k * 2.0, 30.0 + [0, 4, 1][k] + (f + k) % 2)
		_px_under(canvas, roundi(p.x), roundi(p.y), Color(water[2], 0.9 - k * 0.2))
	_soft_glow(canvas, Vector2(34, 32), Vector2(9, 8), f, Color("#9ad4ff"), 0.28)

# A firefly: glowing tail, dark head and feelers, flickering wings, a trail of sparks.
func _proj_spark(canvas: Image, f: int) -> void:
	var lit: float = [1.0, 0.8, 1.0, 0.9][f]
	_soft_glow(canvas, Vector2(30, 32), Vector2(7.5, 6.5), f, Color("#d8f060"), 0.45 * lit)
	var tail := _layer()
	_ellipse(tail, Vector2(30, 32.5), Vector2(3.8, 3.0), _ramp(["#e8b030", "#ffe060", "#fff6a0", "#ffffff"]))
	_stamp(canvas, tail, Color("#8a6a18"))
	for x in range(28, 32):
		if x % 2 == 0:
			_px(canvas, x, 31, Color("#ffffff"))
	var body := _layer()
	_flat_ellipse(body, Vector2(34.5, 32), Vector2(1.8, 1.8), Color("#4a3620"))
	_flat_ellipse(body, Vector2(37, 31.5), Vector2(1.3, 1.3), Color("#2a1e14"))
	_stamp(canvas, body, Color("#140c08"))
	_px(canvas, 37, 31, Color("#f07050"))
	_px(canvas, 39, 30, Color("#2a1e14"))
	_px(canvas, 40, 29, Color("#2a1e14"))
	var up := f % 2 == 0
	var wing := _layer()
	_flat_ellipse(wing, Vector2(32.5, 28.5 if up else 30.0), Vector2(3.2, 1.6 if up else 1.2), Color(0.92, 0.97, 1.0, 0.75))
	_stamp(canvas, wing, Color(0.55, 0.65, 0.8, 0.8))
	_trail(canvas, Vector2(25, 33), 7, Color("#f0f090"), f, 2.0)
	_px_under(canvas, 23 - f % 2, 30, Color("#fff6a0"))

# A lantern-light orb: a flame inside a glowing bead, four rays turning, embers behind.
func _proj_light_orb(canvas: Image, f: int) -> void:
	var c := Vector2(33.5, 32.5)  # half-pixel centres keep small orbs round
	for k in 4:
		var d := Vector2.from_angle(k * TAU / 4.0 + (PI / 4.0 if f % 2 else 0.0))
		for i in range(6, 9):
			_px(canvas, roundi(c.x + d.x * i), roundi(c.y + d.y * i), Color("#fff0b0", 1.0 - (i - 6) * 0.3))
	var orb := _layer()
	_ellipse(orb, c, Vector2(4.6, 4.6), _ramp(["#e89040", "#f8c060", "#fff0b0", "#ffffff"]))
	_stamp(canvas, orb, Color("#a8602a"))
	# The little flame at its heart, leaning back from the flight.
	var flame := [Vector2i(0, 1), Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1), Vector2i(-1 - f % 2, -2)]
	for i in flame.size():
		var q: Vector2i = flame[i]
		_px(canvas, floori(c.x) + q.x, floori(c.y) + q.y, Color("#ff9a3a") if i < 2 else Color("#fff6d0"))
	_trail(canvas, Vector2(27, 32), 8, Color("#f8c060"), f, 2.5)
	_soft_glow(canvas, c, Vector2(11, 10), f, GLOW_OUTER, 0.4)

# A sling stone with a golden streak behind it (Standing Stone).
func _proj_sling_stone(canvas: Image, f: int) -> void:
	_spinning_rock(canvas, f, 4.5, _ramp(STONE), Color("#1c1c36"))
	_rock_marks(canvas, Vector2(32, 32), f, 4.5)
	# A carved rune glowing on its face.
	_px(canvas, 32, 31, MEMORY_GOLD)
	_px(canvas, 32, 32, MEMORY_GOLD)
	_px(canvas, 31, 31, Color("#fff0b0"))
	for k in 10:
		var col := GLOW_INNER.lerp(GLOW_OUTER, k / 10.0)
		_px_under(canvas, 27 - k, 32 + (1 if k > 5 and (k + f) % 2 else 0), Color(col, 1.0 - k * 0.09))
		if k < 6:
			_px_under(canvas, 27 - k, 31, Color(col, 0.6 - k * 0.1))

# A silver crescent shard, lit on its inner edge, trailing star-glints (Moonstone).
func _proj_moon_shard(canvas: Image, f: int) -> void:
	var layer := _layer()
	_ellipse(layer, Vector2(34, 32), Vector2(6, 6), _ramp(["#8aa0d8", "#c0d4f4", "#e8f2ff", "#ffffff"]))
	var hole := Vector2(31.2, 30.6)
	for y in range(-OY, S):
		for x in S:
			if Vector2(x + 0.5, y + 0.5).distance_to(hole) < 5.2:
				_sp(layer, x, y, Color(0, 0, 0, 0))
	_stamp(canvas, layer, Color("#2a2a5a"))
	_px(canvas, 38, 33, Color.WHITE)
	_px(canvas, 37, 35, Color.WHITE)
	for k in 3:
		var p := Vector2i(27 - k * 3, 33 + (k + f) % 2 * 2 - 1)
		if (k + f) % 3 == 0:
			_sparkle(canvas, p, Color("#dfeeff"))
		else:
			_px_under(canvas, p.x, p.y, Color("#c8e0ff", 0.8 - k * 0.2))
	_soft_glow(canvas, Vector2(34, 32), Vector2(9, 9), f, Color("#c8dcff"), 0.3)

# A faceted ice shard pointing right: light top facet, ridge, frost motes behind (Frostfern).
func _proj_frost_shard(canvas: Image, f: int) -> void:
	var o := Color("#16305e")
	var top := PackedVector2Array([Vector2(43, 32), Vector2(35, 28.5), Vector2(24, 29.5), Vector2(27.5, 32.1)])
	var bottom := PackedVector2Array([Vector2(43, 32), Vector2(27.5, 32), Vector2(24, 34.5), Vector2(35, 35.5)])
	var layer := _layer()
	_flat_polygon(layer, top, Color("#e4f6ff"))
	_flat_polygon(layer, bottom, Color("#8ac4f0"))
	_stamp(canvas, layer, o)
	for x in range(28, 42):
		_px(canvas, x, 32, Color("#ffffff") if x > 33 else Color("#b8e2ff"))
	for x in range(30, 36):
		_px(canvas, x, 34, Color("#6aa8e0"))
	_px(canvas, [29, 32, 35, 38][f], 30, Color.WHITE)
	_px(canvas, [29, 32, 35, 38][f] + 1, 30, Color.WHITE)
	for k in 2:
		var p := Vector2i(20 - k * 3 + f % 2, 30 + k * 4)
		_px_under(canvas, p.x, p.y, Color("#e4f6ff"))
		if (k + f) % 2 == 0:
			for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				_px_under(canvas, p.x + d.x, p.y + d.y, Color("#b8e2ff", 0.7))
	_soft_glow(canvas, Vector2(33, 32), Vector2(11, 7), f, Color("#b8e2ff"), 0.28)

# Swooping birds: Warden-sized, with a drifting feather behind.
func _bird_proj(canvas: Image, f: int, body: Array[Color], o: Color, beak: Color = Color("#e8a040")) -> void:
	_bird(canvas, Vector2(33, 33), 1, body, o, f % 2 == 0, beak, 1.55)
	var eye := Vector2(33, 33) + Vector2(2.4, -1.6) * 1.55
	_px(canvas, roundi(eye.x) + 1, roundi(eye.y) - 1, Color.WHITE)
	for x in range(30, 35):
		_px(canvas, x, 35, body[2])  # pale belly
	var fe := Vector2i(22 - f % 2, 29 + [0, 1, 2, 1][f])
	_px_under(canvas, fe.x, fe.y, body[1])
	_px_under(canvas, fe.x + 1, fe.y, body[2])
	_px_under(canvas, fe.x - 1, fe.y + 1, body[1])

func _proj_sparrow(canvas: Image, f: int) -> void:
	_bird_proj(canvas, f, _ramp(["#8a5a3a", "#b88058", "#e0b890"]), Color(FEATHER[0]))

func _proj_wren(canvas: Image, f: int) -> void:
	_bird_proj(canvas, f, _ramp(["#6a4020", "#9a6438", "#c89060"]), Color("#2a140a"))
	for x in [31, 33]:
		_px(canvas, x, 31, Color("#4a2810"))  # barred wings

func _proj_magpie(canvas: Image, f: int) -> void:
	_magpie(canvas, Vector2(33, 34), Color("#141420"), f % 2 == 0, f < 2, 1.45, 1)

# Starling Murmuration: an iridescent starling with star-speckles.
func _proj_starling_bird(canvas: Image, f: int) -> void:
	_bird_proj(canvas, f, _ramp(["#241c34", "#3e3258", "#7a6a9a"]), Color("#0e0a16"), Color("#f0c050"))
	for d: Vector2i in [Vector2i(31, 32), Vector2i(34, 33), Vector2i(29, 34), Vector2i(36, 31)]:
		_px(canvas, d.x, d.y, Color("#f4f0ff") if (d.x + f) % 2 else Color("#7ad0b0"))

# Kept for old saves / art that still names it: a small flock.
func _proj_starling(canvas: Image, f: int) -> void:
	for k in 4:
		var p := Vector2i(36 - k * 4, 31 + [0, 4, -3, 2][k])
		var up := (f + k) % 2 == 0
		_px(canvas, p.x, p.y, Color("#241c34"))
		_px(canvas, p.x + 1, p.y, Color("#3e3258"))
		_px(canvas, p.x - 1, p.y - (1 if up else 0), Color("#241c34"))
		_px(canvas, p.x - 2, p.y - (2 if up else -1), Color("#241c34"))
		_px(canvas, p.x + 2, p.y - 1, Color("#241c34"))

# A little glowing moon moth: pale wings beating round a lit body, gold dust behind (Moon Moth).
func _proj_moon_mote(canvas: Image, f: int) -> void:
	# From the side, flying right: big pale wings beating up and down over a lit body, feathery
	# feelers, a trail of gold dust.
	var c := Vector2(32.5, 32.5)
	var lift: float = [1.0, 0.35, -0.6, 0.35][f]  # wings up, level, down, level
	var wings := _layer()
	_flat_ellipse(wings, c + Vector2(-2.5, -2.0 * lift), Vector2(3.0, 1.2 + 1.6 * absf(lift)), Color("#c8d0f4"))
	_flat_ellipse(wings, c + Vector2(0.5, -3.2 * lift), Vector2(3.4, 1.4 + 2.2 * absf(lift)), Color("#eef2ff"))
	_stamp(canvas, wings, Color("#6a6aa8"))
	if absf(lift) > 0.5:
		_px(canvas, floori(c.x) + 1, floori(c.y - 3.2 * lift), MEMORY_GOLD)  # eye-spot
		_px(canvas, floori(c.x) - 3, floori(c.y - 2.0 * lift), Color("#a8b0e8"))
	var body := _layer()
	_ellipse(body, c + Vector2(0, 0.5), Vector2(3.8, 1.8), _ramp(["#a8b0e8", "#e8eeff", "#ffffff"]))
	_stamp(canvas, body, Color("#5a5a98"))
	_px(canvas, floori(c.x) + 3, floori(c.y), Color("#2a2a5a"))  # eye
	for q: Vector2i in [Vector2i(5, -1), Vector2i(6, -2), Vector2i(7, -2), Vector2i(5, -2)]:
		_px(canvas, floori(c.x) + q.x, floori(c.y) + q.y, Color("#8a8ac8"))
	for k in 6:
		var p := Vector2(27.0 - k * 1.6, 33.5 + sin(f * PI / 2.0 + k) * 2.0)
		_px_under(canvas, floori(p.x), floori(p.y), Color(MEMORY_GOLD if k % 2 else Color("#dfeeff"), 0.9 - k * 0.13))
	_soft_glow(canvas, c, Vector2(10, 9), f, Color("#dfe4ff"), 0.36)

# Trap sprites (drawn on a path tile, not flying): a ring of little mushrooms, a light running round.
func _proj_fairy_ring(canvas: Image, f: int) -> void:
	_trap_ring(canvas, f, ["#b0784a", "#e0b078", "#fff0c8"], Color("#fff0c8"), 6)

func _proj_elf_circle(canvas: Image, f: int) -> void:
	_trap_ring(canvas, f, ["#2a8878", "#5ad0c0", "#b8fff4"], Color("#7ff0e0"), 7)

func _trap_ring(canvas: Image, f: int, cap: Array, light_col: Color, n: int) -> void:
	var c := Vector2(32, 33)
	var r := Vector2(8.5, 5.5)
	var o := Color("#3a2a20")
	# A faint glowing ring on the ground.
	for k in 48:
		var p := Vector2i((c + Vector2.from_angle(k * TAU / 48.0) * r).round())
		_px_under(canvas, p.x, p.y, Color(light_col, 0.35))
	# Back half first so the front caps overlap them.
	var order: Array = range(n)
	order.sort_custom(func(a: int, b: int) -> bool: return sin(a * TAU / n + 0.3) < sin(b * TAU / n + 0.3))
	for i: int in order:
		var p := Vector2i((c + Vector2.from_angle(i * TAU / n + 0.3) * r).round())
		var lit := (i + f * 2) % n <= 1
		# A domed cap on a short pale stem, drawn row by row with the outline outside it (a stamp
		# would eat such a small cap): top 3 wide, brim 5 wide, a dark gill line, the stem.
		var rows := [[-4, -1, 1, o], [-3, -2, -2, o], [-3, 2, 2, o], [-3, -1, 1, Color(cap[2])],
			[-2, -3, -3, o], [-2, 3, 3, o], [-2, -2, 2, Color(cap[1])], [-1, -2, 2, o], [0, -1, -1, o], [0, 1, 1, o]]
		for row: Array in rows:
			for x in range(int(row[1]), int(row[2]) + 1):
				_px(canvas, p.x + x, p.y + int(row[0]), row[3])
		_px(canvas, p.x, p.y - 1, Color("#f0e4d8"))
		_px(canvas, p.x, p.y, Color("#d8c8b8"))
		_px(canvas, p.x + 1, p.y + 1, Color(o, 0.5))
		_px(canvas, p.x - 2, p.y - 2, Color(cap[0]))
		_px(canvas, p.x + 2, p.y - 2, Color(cap[0]))
		_px(canvas, p.x - 1, p.y - 3, Color.WHITE if lit else Color(cap[2]))
		_px(canvas, p.x + 1, p.y - 2, Color("#ffffff", 0.7))  # a spot
		if lit:
			_px_under(canvas, p.x, p.y - 6, Color(light_col, 0.95))
			_px_under(canvas, p.x - 1, p.y - 6, Color(light_col, 0.45))
			_px_under(canvas, p.x + 1, p.y - 6, Color(light_col, 0.45))
			_px_under(canvas, p.x, p.y - 7, Color(light_col, 0.45))

# A dream bead trailing a little dreamcatcher feather (Dreamcatcher).
func _proj_dream_mote(canvas: Image, f: int) -> void:
	var c := Vector2(36.5, 32.5)
	var sway: float = [0.0, 1.0, 0.0, -1.0][f]
	# The thread, then the feather hanging off it, streaming behind.
	_line(canvas, [c + Vector2(-3, 0), c + Vector2(-6, sway * 0.4)], Color("#8a6ab8"))
	_leaf(canvas, c + Vector2(-6, sway * 0.4), c + Vector2(-15, sway), 2.2, _ramp(["#a888d8", "#d8c8f8", "#f4f0ff"]), Color("#5a3a8a"))
	_line(canvas, [c + Vector2(-7, sway * 0.4), c + Vector2(-14, sway)], Color("#9a7ac8"))  # the quill
	var bead := _layer()
	_ellipse(bead, c, Vector2(3.6, 3.6), _ramp(["#e0b048", "#ffe890", "#fff8d0", "#ffffff"]))
	_stamp(canvas, bead, Color("#6a4a9a"))
	# A tiny web woven in the bead.
	var m := Vector2i(floori(c.x), floori(c.y))
	_px(canvas, m.x, m.y, Color("#a878d8"))
	_px(canvas, m.x - 1, m.y - 1, Color("#c8a8f0"))
	_px(canvas, m.x + 1, m.y + 1, Color("#c8a8f0"))
	_px(canvas, m.x + 1, m.y - 1, Color("#c8a8f0"))
	_px(canvas, m.x - 1, m.y + 1, Color("#c8a8f0"))
	_soft_glow(canvas, c, Vector2(8, 7), f, BELL_GLOW, 0.4)

# A flat cairn stone tumbling end over end, strata on its face (Cairn, Rockslide).
func _proj_lob_stone(canvas: Image, f: int) -> void:
	var c := Vector2(32, 32)
	var a := f * TAU / 8.0
	var pts := PackedVector2Array()
	for k in 10:
		var ang := k * TAU / 10.0
		pts.append(c + Vector2(cos(ang) * 7.0 * (1.0 if k % 3 else 0.9), sin(ang) * 3.8).rotated(a))
	_rock(canvas, pts, _ramp(STONE), Color("#1c1c36"))
	for i in range(-4, 5):
		var p := c + Vector2(i, 0.8).rotated(a)
		_px(canvas, roundi(p.x), roundi(p.y), Color("#7a80ae"))
	var moss := c + Vector2(-2, -2.5).rotated(a)
	_px(canvas, roundi(moss.x), roundi(moss.y), Color("#7cbc5a"))
	_px(canvas, roundi(moss.x) + 1, roundi(moss.y), Color("#a8dc78"))
	_speed_lines(canvas, Vector2(23, 32), f, Color("#e4e7f4"))

func _proj_hummingbird(canvas: Image, f: int) -> void:
	_hummingbird(canvas, Vector2(32, 33), 1, EMERALD, f, 1.5)
	for k in 5:
		_px_under(canvas, 23 - k, 33 + (k + f) % 2, Color(Color(EMERALD[2]), 0.8 - k * 0.15))

func _proj_maple_seed(canvas: Image, f: int) -> void:
	_maple_key(canvas, f, ["#8a4a20", "#c07a40", "#e8b070", "#f8d8a0"])

func _proj_autumn_seed(canvas: Image, f: int) -> void:
	_maple_key(canvas, f, ["#a02a10", "#d8502a", "#f07a4a", "#ffb07a"])

# A spinning maple key: a round seed with a long veined wing, a quarter turn per frame.
func _maple_key(canvas: Image, f: int, wing: Array) -> void:
	var c := Vector2(32.5, 32.5)
	var a := f * TAU / 4.0 + 0.3
	var o := Color(MAPLE[0])
	var outline_pts := [Vector2(1, -2.2), Vector2(5, -5), Vector2(9, -5.5), Vector2(11.8, -3.8), Vector2(12, -1),
		Vector2(8.5, 1.2), Vector2(4, 1.8), Vector2(1, 1.8)]
	var pts := PackedVector2Array()
	for q: Vector2 in outline_pts:
		pts.append(c + q.rotated(a))
	var layer := _layer()
	for y in range(-OY, S):
		for x in S:
			var p := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(p, pts):
				# Lighter towards the leading (upper) edge of the wing.
				var local := (p - c).rotated(-a)
				_sp(layer, x, y, Color(wing[3] if local.y < -3.0 else (wing[2] if local.y < -1.0 else wing[1])))
	_stamp(canvas, layer, o)
	for v: Vector2 in [Vector2(10, -3.8), Vector2(10.5, -1.2)]:
		_line(canvas, [c + Vector2(2, 0).rotated(a), c + v.rotated(a)], Color(wing[0]))
	var nut := _layer()
	_ellipse(nut, c, Vector2(2.6, 2.6), _ramp(["#6a3a1a", "#9a5a2a", "#c88a4a"]))
	_stamp(canvas, nut, o)
	_spin_blur(canvas, c, f, Color(wing[3]))

# The faint arc a spinning seed's wing leaves behind it.
func _spin_blur(canvas: Image, c: Vector2, f: int, col: Color) -> void:
	for k in 5:
		var ang := f * TAU / 4.0 - 0.35 * (k + 1)
		var p := c + Vector2.from_angle(ang) * 9.0
		_px_under(canvas, roundi(p.x), roundi(p.y), Color(col, 0.6 - k * 0.1))


func _flat_polygon(layer: Image, pts: PackedVector2Array, color: Color) -> void:
	for y in range(-OY, S):
		for x in S:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				_sp(layer, x, y, color)

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
	"cobble": ["#aeabbd", "#6a677e", "#34323f"],
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
			_sp(canvas, x, y, stone[ch])
			if ch == "a" and on_top:
				_sp(top, x, y, Color.WHITE)
			else:
				_sp(side, x, y, Color.WHITE)
			continue
		# Under the figure: the top face, bounded by the slab's back edges.
		var xl := 2 * (40 - y) - 1
		var xr := 64 - 2 * (40 - y) + 1
		if y > 40 or (x > xl + 1 and x < xr - 1):
			_sp(canvas, x, y, stone.a)
			_sp(top, x, y, Color.WHITE)
		elif x >= xl and x <= xr:
			_sp(canvas, x, y, stone.d)
	for c: Vector2i in [Vector2i(28, 34), Vector2i(29, 34), Vector2i(36, 30), Vector2i(40, 45), Vector2i(41, 45), Vector2i(24, 44)]:
		_px(canvas, c.x, c.y, stone.d)
	call("_decor_" + theme, canvas, top, side, st, lush)
	return top

func _on(mask: Image, x: int, y: int) -> bool:
	return x >= 0 and y >= -OY and x < S and y < S and _gp(mask, x, y).a > 0.0

# Soft blobs on the top face: lighter towards the top, dithered at the edges.
func _patches(canvas: Image, top: Image, blobs: Array, ramp: Array[Color]) -> void:
	for blob: Rect2 in blobs:
		for y in range(maxi(-OY, floori(blob.position.y - blob.size.y)), mini(S, ceili(blob.position.y + blob.size.y) + 1)):
			for x in range(maxi(0, floori(blob.position.x - blob.size.x)), mini(S, ceili(blob.position.x + blob.size.x) + 1)):
				if not _on(top, x, y):
					continue
				var d := (Vector2(x + 0.5, y + 0.5) - blob.position) / blob.size
				var q := d.length()
				if q > 1.0:
					continue  # crisp edges, no checker (AI-look audit)
				_sp(canvas, x, y, ramp[2] if (q < 0.5 and d.y < 0.0) else (ramp[0] if q > 0.8 else ramp[1]))

const MOSS_BLOBS := [Rect2(11, 40, 9, 3.5), Rect2(51, 41, 8, 3), Rect2(30, 51, 10, 3), Rect2(42, 30, 6, 2.5), Rect2(21, 31, 5, 2)]
# Spots on the top face that stay visible around the seated figure.
const OPEN_SPOTS := [Vector2i(6, 40), Vector2i(12, 44), Vector2i(16, 37), Vector2i(50, 40), Vector2i(56, 43), Vector2i(46, 48),
	Vector2i(22, 50), Vector2i(35, 52), Vector2i(9, 43), Vector2i(59, 41), Vector2i(40, 51), Vector2i(28, 53), Vector2i(3, 40)]

func _decor_moss(canvas: Image, top: Image, _side: Image, _st: Dictionary, _lush: bool) -> void:
	_patches(canvas, top, MOSS_BLOBS, _ramp(["#3f7a3e", "#5a9a48", "#7cbc5a"]))

# Tilled soil with furrows and seedlings.
func _decor_soil(canvas: Image, top: Image, _side: Image, _st: Dictionary, lush: bool) -> void:
	for y in range(-OY, S):
		for x in S:
			if not _on(top, x, y):
				continue
			var furrow := int(floor(x * 0.5 + y)) % 4 == 0
			var clod := (x * 37 + y * 91) % 11 == 0
			_sp(canvas, x, y, Color("#5a3a24") if furrow else (Color("#9a6e48") if clod else Color("#7a5234")))
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
	# Neutral grey a step darker than the side rocks (ROCK_PAL) so they stand out on it; bluer greys
	# turn icy in the palette pass.
	var shades := [Color("#94919f"), Color("#878494"), Color("#7b7889")]
	for y in range(-OY, S):
		for x in S:
			if not _on(top, x, y):
				continue
			var u := x * 0.5 + y
			var v := x * 0.5 - y
			if fposmod(u, 5.0) < 1.0 or fposmod(v, 5.0) < 1.0:
				var mossy := (x * 13 + y * 7) % (3 if lush else 5) == 0
				_sp(canvas, x, y, Color("#5a9a48") if mossy else Color("#5f5c70"))
			else:
				_sp(canvas, x, y, shades[absi(int(floor(u / 5.0)) * 7 + int(floor(v / 5.0)) * 3) % 3])

# Stone with rain pools (a ripple travels across them); a lily flowers on one when lush.
func _decor_pond(canvas: Image, top: Image, _side: Image, st: Dictionary, lush: bool) -> void:
	_patches(canvas, top, [Rect2(42, 30, 6, 2.5), Rect2(21, 31, 5, 2)], _ramp(["#3f7a3e", "#5a9a48", "#7cbc5a"]))
	var ripple := float(st.f % 4) / 4.0
	for pool: Rect2 in [Rect2(12, 42, 9, 3.5), Rect2(53, 42, 7, 3), Rect2(38, 51, 7, 2.5)]:
		for y in range(-OY, S):
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
				_sp(canvas, x, y, col)
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
	for y in range(-OY, S):
		for x in S:
			if not _on(top, x, y):
				continue
			var h := (x * 29 + y * 53) % 9
			_sp(canvas, x, y, Color("#8ad060") if h == 0 else (Color("#3f7a3e") if h == 4 else Color("#5a9a48")))
	var flowers: Array = OPEN_SPOTS.slice(0, 8 if lush else 5)
	for i in flowers.size():
		var p: Vector2i = flowers[i]
		if _on(top, p.x, p.y):
			_flower(canvas, p, Color("#ffe070") if i % 2 == 0 else Color("#fff4f0"), Color("#d89a20"))

# A tree stump: growth rings on top, bark grain down the sides.
func _decor_stump(canvas: Image, top: Image, side: Image, _st: Dictionary, lush: bool) -> void:
	for y in range(-OY, S):
		for x in S:
			if _on(top, x, y):
				var q := Vector2((x + 0.5 - 31.5) / 2.0, y + 0.5 - 44.0).length()
				var col := Color("#d8b080") if int(q) % 4 < 2 else Color("#c8a070")
				if int(q) % 4 == 0:
					col = Color("#a07850")
				if q < 1.5:
					col = Color("#8a6040")
				_sp(canvas, x, y, col)
			elif _on(side, x, y) and x % 3 == 0:
				_sp(canvas, x, y, _gp(canvas, x, y).darkened(0.25))
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
	for y in range(-OY, S):
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
			_sp(layer, x, y, col)
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
	fig = _body_pal(fig)
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
		if p.x >= 0 and p.y >= -OY and p.x < S and p.y < S and _gpv(mask, p).a > 0.0 and _gpv(canvas, p) != o:
			_spv(canvas, p, color)

func _glow_dot(canvas: Image, p: Vector2i, core: Color, halo: Color, mask: Image = null) -> void:
	for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var q := p + d
		if mask == null or (q.x >= 0 and q.y >= -OY and q.x < S and q.y < S and _gpv(mask, q).a > 0.0):
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
	# Thornwall reads as a dark, wild, THORNY hedge (spikes all round its outline, thick thorny canes
	# wrapped round it, dark berries). Bramble is the same hedge gone bright and ROSY: big wild roses
	# all over and a crown of them, only small thorns left.
	var dy: int = st.dy
	var fig := _pal("#14241a", "#7cbc5a", "#58964a", "#3c7040") if bloom else _pal("#121a10", "#6a9448", "#4e763c", "#34552e")
	var bush := _ramp(["#2a5232", "#3c7040", "#58964a", "#7cbc5a"]) if bloom else _ramp(["#1e3a22", "#34552e", "#4e763c", "#6a9448"])
	var thorn := Color("#e8d4a0")
	var cane := Color("#6a4030")
	_draw_waystone(canvas, st, "bramble", bloom)
	for tuft: Rect2 in [Rect2(8, 42, 5, 3.5), Rect2(56, 42, 5, 3.5)]:
		var t := _layer()
		_ellipse(t, tuft.position, tuft.size, bush)
		_stamp(canvas, t, fig.o)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	for y in range(-OY, S):
		for x in S:
			if _gp(mask, x, y).a == 0.0 or _gp(canvas, x, y) == fig.o:
				continue
			var h := (x * 73 + y * 151) % 11
			if h == 0:
				_sp(canvas, x, y, bush[0])
			elif h == 4 and _gp(canvas, x, y) == fig.a:
				_sp(canvas, x, y, Color("#a8dc7a") if bloom else Color("#86b060"))
	var on := func(x: int, y: int) -> bool:
		return x >= 0 and y >= -OY and x < S and y < S and _gp(mask, x, y).a > 0.0
	if bloom:
		# Small thorns poking out of the top only.
		for y in range(1, S):
			for x in S:
				if on.call(x, y) and not on.call(x, y - 1) and (x * 7) % 4 == 0:
					_px(canvas, x, y - 1, thorn)
	else:
		# Big thorns all round the outline: two-pixel spikes out of the top and the sides.
		for y in range(2, S - 2):
			for x in range(2, S - 2):
				if not on.call(x, y):
					continue
				if not on.call(x, y - 1) and x % 3 == 0 and y < 40:
					_px(canvas, x, y - 1, cane)
					_px(canvas, x, y - 2, thorn)
				elif not on.call(x - 1, y) and y % 3 == 1 and y < 40:
					_px(canvas, x - 1, y, cane)
					_px(canvas, x - 2, y - 1, thorn)
				elif not on.call(x + 1, y) and y % 3 == 1 and y < 40:
					_px(canvas, x + 1, y, cane)
					_px(canvas, x + 2, y - 1, thorn)
	# Canes wrapped round the body: thick and thorny on Thornwall, a thin vine on Bramble.
	var canes: Array = [[Vector2(18, 31), Vector2(25, 26 + dy), Vector2(31, 29), Vector2(37, 24 + dy), Vector2(45, 28)],
			[Vector2(19, 40), Vector2(27, 35), Vector2(35, 38), Vector2(43, 34)]]
	if not bloom:
		canes.append([Vector2(22, 20 + dy), Vector2(28, 24 + dy), Vector2(24, 33), Vector2(30, 41)])
	for c: Array in canes:
		_line(canvas, c, cane, mask)
		if not bloom:
			var lower: Array = []
			for p: Vector2 in c:
				lower.append(p + Vector2(0, 1))
			_line(canvas, lower, Color("#4a2a20"), mask)
			for i in c.size() - 1:
				var m: Vector2 = ((c[i] as Vector2) + (c[i + 1] as Vector2)) / 2.0
				_skin_px(canvas, mask, fig.o, [Vector2i(m.floor()) + Vector2i(0, -1)], thorn)
	if not bloom:
		# Dark berries in clusters.
		for i in 3:
			var b: Vector2i = [Vector2i(28, 32), Vector2i(39, 36), Vector2i(17, 38)][i]
			_skin_px(canvas, mask, fig.o, [b, b + Vector2i.RIGHT, b + Vector2i.DOWN, b + Vector2i(1, 1)], Color("#4a1a3a"))
			_skin_px(canvas, mask, fig.o, [b], Color("#b85a8a") if (st.f / 2) % 3 == i else Color("#7a2a5a"))
	else:
		# Big wild roses all over: a pink ring, a deep centre, a highlight.
		for r: Vector2i in [Vector2i(20, 29), Vector2i(33, 22 + dy), Vector2i(41, 37), Vector2i(26, 37),
				Vector2i(15, 38), Vector2i(49, 32), Vector2i(44, 25 + dy), Vector2i(35, 31)]:
			var ring: Array[Vector2i] = []
			for d: Vector2i in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]:
				ring.append(r + d)
			_skin_px(canvas, mask, fig.o, ring, Color("#f4a0c0"))
			_skin_px(canvas, mask, fig.o, [r], Color("#c8386a"))
			_skin_px(canvas, mask, fig.o, [r + Vector2i(-1, -1)], Color("#ffe0ec"))
		# A crown of roses on its head.
		for k in 3:
			var c := Vector2i(24 + k * 6, 4 + dy - (1 if k == 1 else 0))
			var crown := _layer()
			_flat_ellipse(crown, Vector2(c) + Vector2(0.5, 0.5), Vector2(2.7, 2.4), Color("#f07aa8"))
			_stamp(canvas, crown, Color("#6a1a3a"))
			_px(canvas, c.x, c.y, Color("#c8386a"))
			_px(canvas, c.x - 1, c.y - 1, Color("#ffe0ec"))
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), bloom, true)
	var t: float = float(st.f) / st.n
	_px(canvas, 50 + roundi(sin(t * TAU) * 2), 14 + roundi(t * 10), Color("#f4a0c0") if bloom else Color("#6a9448"))
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
		_sp(cap, p.x, p.y + dy, moss[1])
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
	for y in range(-OY, S):
		for x in S:
			var q := ((Vector2(x + 0.5, y + 0.5) - Vector2(31, 45)) / Vector2(24, 8)).length()
			if bright and _gp(top, x, y).a > 0.0 and q < 1.0 and q > 0.78:
				_sp(canvas, x, y, _gp(canvas, x, y).lerp(Color("#d8d890"), 0.55))  # a solid band of light, no checker
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
		elif _gpv(mask, p).a > 0.0:
			_glow_dot(canvas, p, Color("#fff27a"), Color("#a8c868"), mask)
	_neck_string(canvas, mask, st, fig.o)
	# Cork hat and its sprout (it pops up when the jar fires).
	var cy: int = dy + maxi(-2, mini(0, st.lift))
	var lid := _layer()
	_round_rect(lid, Rect2i(24, 1 + cy, 14, 7), 2, cork[1])
	for y in range(-OY, S):
		for x in S:
			if _gp(lid, x, y).a > 0.0:
				_sp(lid, x, y, cork[2] if y < 3 + cy else (cork[0] if x > 34 else cork[1]))
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
	for y in range(-OY, S):
		for x in S:
			if _gp(cap, x, y).a > 0.0 and (x + 2 * y) % 4 == 0 and y < 9 + dy:
				_sp(cap, x, y, shell[0])
	_stamp(canvas, cap, fig.o)
	_golem_face(canvas, st, fig)

func _round_rect(layer: Image, rect: Rect2i, r: int, color: Color) -> void:
	for y in range(maxi(-OY, rect.position.y), mini(S, rect.end.y)):
		for x in range(maxi(0, rect.position.x), mini(S, rect.end.x)):
			var cx := clampi(x, rect.position.x + r, rect.end.x - 1 - r)
			var cy := clampi(y, rect.position.y + r, rect.end.y - 1 - r)
			if Vector2(x - cx, y - cy).length() <= r + 0.25:
				_sp(layer, x, y, color)

# Teardrop built from a column of shrinking circles; the upper part bends with sway.
func _flame(layer: Image, base: Vector2, r: float, height: float, sway: float, color: Color) -> void:
	for step in 25:
		var t := step / 24.0
		var c := base + Vector2(sway * 3.0 * t * t, -height * t)
		var rr := r * pow(1.0 - t, 1.5)
		if rr >= 0.5:
			_flat_ellipse(layer, c, Vector2(rr, rr), color)

# --- Attack effects ---------------------------------------------------------------------------
# Drawn over the Warden's attack-pose body. st.attack is the frame (RELEASE_FRAME = the shot).

# Warden attacks glow warmly: light pushing back the cold, dark nightmares (story.md).
const GLOW_INNER := Color("#ffe8a0")
const GLOW_OUTER := Color("#ffc860")

# Warm light spilling round an attack or projectile, dithered so it reads as a glow. It only lights
# empty pixels, so it never paints over the Warden or its base: draw it after the effect itself.
func _warm_glow(canvas: Image, c: Vector2, r: Vector2, phase: int = 0) -> void:
	for y in range(maxi(-OY, floori(c.y - r.y)), mini(S, ceili(c.y + r.y) + 1)):
		for x in range(maxi(0, floori(c.x - r.x)), mini(S, ceili(c.x + r.x) + 1)):
			if _gp(canvas, x, y).a > 0.0:
				continue
			var q := ((Vector2(x + 0.5, y + 0.5) - c) / r).length()
			# Two hard alpha bands, no checker (AI-look audit).
			if q < 0.55:
				_sp(canvas, x, y, Color(GLOW_INNER, 0.75))
			elif q < 1.0:
				_sp(canvas, x, y, Color(GLOW_OUTER, 0.4))

# A puff that bursts on release, then scatters into dots and fades.
func _burst(canvas: Image, c: Vector2, a: int, light_col: Color, dark_col: Color, o: Color) -> void:
	if a == RELEASE_FRAME:
		var puff := _layer()
		_flat_ellipse(puff, c, Vector2(4, 3.4), light_col)
		_flat_ellipse(puff, c + Vector2(-3.5, 2), Vector2(2.4, 2.2), light_col)
		_flat_ellipse(puff, c + Vector2(3.5, 2), Vector2(2.6, 2.4), light_col)
		for y in range(-OY, S):
			for x in S:
				if _gp(puff, x, y).a > 0.0 and y > c.y + 2:
					_sp(puff, x, y, dark_col)
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
	for y in range(-OY, S):
		for x in S:
			var q := ((Vector2(x + 0.5, y + 0.5) - c) / r).length()
			if absf(q - 1.0) * minf(r.x, r.y) < 0.55:
				_sp(canvas, x, y, Color(color, color.a * 0.4) if fading else color)

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
	_root_burst(canvas, st, 1.0, false)
	var a: int = st.attack
	var zs: Array = [[], [], [Vector2i(45, 14)], [Vector2i(47, 10), Vector2i(15, 12)], [Vector2i(49, 6), Vector2i(13, 8)], [Vector2i(14, 4)]]
	for z: Vector2i in zs[a]:
		for d: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]:
			_px(canvas, z.x + d.x, z.y + d.y, Color("#ece0ff"))

# The Rootling pulse: an earthen ring rolling out over the slab and a ring of root tips breaking the
# ground all round its base (the front half and sides, so they don't cover its body).
func _root_burst(canvas: Image, st: Dictionary, size: float, flowers: bool) -> void:
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	var c := Vector2(31.5, 45)
	_ring(canvas, c, Vector2(22 + k * 6, 7.5 + k * 2) * size, Color("#dccdb2"), k == 2)
	_ring(canvas, c, Vector2(20 + k * 6, 6.5 + k * 2) * size, Color("#8c5c34"), true)
	var spots: Array = []
	for i in 7:
		var a: float = -0.25 + i * (PI + 0.5) / 6.0
		spots.append(c + Vector2(cos(a) * 24.0 * size, sin(a) * 8.0 * size))
	_root_spikes(canvas, st, spots, flowers)


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
	for y in range(maxi(-OY, floori(c.y - r.y)), mini(S, ceili(c.y + r.y) + 1)):
		for x in range(maxi(0, floori(c.x - r.x)), mini(S, ceili(c.x + r.x) + 1)):
			var q := ((Vector2(x + 0.5, y + 0.5) - c) / r).length()
			if q > 1.0:
				continue
			_sp(canvas, x, y, Color(color, color.a * (0.75 if q < 0.55 else 0.4)))  # two hard alpha bands, no checker

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
		for y in range(-OY, S):
			for x in S:
				if _gp(cap, x, y).a > 0.0 and (x + 2 * y) % 5 == 0:
					_sp(cap, x, y, puff[0])
		_stamp(canvas, cap, fig.o)
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), false)
	_orbit_sacs(canvas, st, 2 if puffy else 3, sac, fig.o)
	_motes(canvas, st, [18, 44, 36], 16, 16, [Color("#f0eaff"), Color("#b4a0ee")])

func _puffball(canvas: Image, c: Vector2, r: float, ramp: Array[Color], o: Color) -> void:
	var layer := _layer()
	_ellipse(layer, c, Vector2(r, r * 0.9), ramp)
	for y in range(-OY, S):
		for x in S:
			if _gp(layer, x, y).a > 0.0 and (x + 2 * y) % 5 == 0:
				_sp(layer, x, y, ramp[0])
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
		_sp(cap, p.x, p.y + dy, moss[1])
	_stamp(canvas, cap, o)
	_flower(canvas, Vector2i(34, 5 + dy), Color("#fff4f0"), Color("#ffd24a"))

# A stone shell behind the figure: plates, and a mossy garden with grass and flowers on top.
func _shell(canvas: Image, c: Vector2, r: Vector2, o: Color, flowers: int) -> void:
	var stone := _ramp(["#5c6088", "#7c82aa", "#a0a6c8", "#c4c9e2"])
	var moss := _ramp(MOSS)
	var layer := _layer()
	_ellipse(layer, c, r, stone)
	var garden_c := c - Vector2(0, r.y * 0.45)
	for y in range(-OY, S):
		for x in S:
			if _gp(layer, x, y).a == 0.0:
				continue
			if ((Vector2(x + 0.5, y + 0.5) - garden_c) / Vector2(r.x * 0.85, r.y * 0.55)).length() < 1.0:
				_sp(layer, x, y, moss[2] if y < garden_c.y - 2 else moss[1])
			elif (x + 2 * y) % 9 == 0 or (x - 2 * y + 90) % 9 == 0:
				_sp(layer, x, y, stone[0])
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
			if y >= -OY and y < S:
				_sp(layer, clampi(x - 1, 0, S - 1), y, fig.a)
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
	for y in range(-OY, S):
		for x in S:
			var p := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(p, body):
				var nx := clampf((p.x - c.x) / (s * 0.9), -1.0, 1.0)
				_sp(layer, x, y, _shade(ramp, Vector3(nx, 0.0, sqrt(1.0 - nx * nx))))
				if p.y > c.y + s * 1.25:
					_sp(layer, x, y, ramp[3])
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
	# Its rain cloud hovers above it in the tall rows (_tall_monsoon); the rain falls past its head.
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
		if _gp(mask, x, y).a == 0.0:
			continue
		_px(canvas, x, y, twine if (x % 3) != 0 else Color("#d8b880"))  # a twist every few pixels
		if _gp(mask, x, y + 1).a > 0.0:
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

# Thunderhead's tall rows: its cap cloud towers up into a storm column with an anvil top (narrow, about
# Beacon's width, so it hides little of the cell above), lightning flickering inside it.
func _tall_thunderhead(back: Image, front: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var ramp := _ramp(["#2a2a44", "#44446a", "#6a6a90", "#9a9ac0"])
	var o := Color("#10101e")
	var base_y := 32.0 + 3 + dy  # the cap cloud's centre, in tall-frame rows
	# Puffs overlapping and stepping sideways as they climb, then a wide flat anvil, lit from the top.
	_cloud(front, Vector2(27, base_y - 7), 20, ramp, o)
	_cloud(front, Vector2(35, base_y - 12), 19, ramp, o)
	_cloud(front, Vector2(29, base_y - 17), 18, ramp, o)
	var anvil := _layer()
	_ellipse(anvil, Vector2(31, base_y - 24), Vector2(14, 4.5), _ramp(["#44446a", "#6a6a90", "#9a9ac0", "#c0c0dc"]))
	_ellipse(anvil, Vector2(24, base_y - 22), Vector2(6, 3.5), ramp)
	_ellipse(anvil, Vector2(39, base_y - 22), Vector2(6, 3.5), ramp)
	_stamp(front, anvil, o)
	var zap := Color("#fff6a0")
	if st.attack < 0:
		var k: int = st.f % 4
		if k == 0:
			_bolt(front, Vector2(26, base_y - 22), Vector2(24, base_y - 12), zap, Color("#8a8af0"), 3)
		elif k == 2:
			_bolt(front, Vector2(36, base_y - 20), Vector2(38, base_y - 10), zap, Color("#8a8af0"), 3)
	for p: Vector2i in [Vector2i(22, int(base_y) - 25), Vector2i(40, int(base_y) - 24)]:
		if (p.x + st.f) % 3 == 0:
			_px(front, p.x, p.y, Color("#c0f0ff"))

# Wellspring's tall rows: the spring shoots up out of the well on its head as a tall jet, crowned with
# a splash, its spray arcing down either side (narrow: little of the cell above is hidden).
func _tall_wellspring(back: Image, front: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var top_well := 32.0 + 5 + dy  # the well's water, in tall-frame rows
	var crest: float = 9.0 + [0.0, 1.0, 2.0, 1.0][st.f % 4]
	var jet := _layer()
	for y in range(int(crest), int(top_well)):
		var w := 2.0 + (y - crest) / (top_well - crest) * 1.6
		_flat_ellipse(jet, Vector2(30.5, y + 0.5), Vector2(w, 0.6), Color("#4c8ca4"))
	_stamp(front, jet, Color("#2c4c5c"))
	for y in range(int(crest) + 1, int(top_well)):
		_px(front, 30, y, Color("#dce8f4") if (y + st.f) % 3 != 0 else Color("#9cd4fc"))
	# The splash crown on top.
	var crown := _layer()
	_flat_ellipse(crown, Vector2(30.5, crest), Vector2(7.5, 3.0), Color("#9cd4fc"))
	_flat_ellipse(crown, Vector2(24.5, crest + 3.0), Vector2(2.5, 2.0), Color("#4c8ca4"))
	_flat_ellipse(crown, Vector2(36.5, crest + 3.0), Vector2(2.5, 2.0), Color("#4c8ca4"))
	_stamp(front, crown, Color("#2c4c5c"))
	_px(front, 29, int(crest) - 1, Color("#dce8f4"))
	_px(front, 32, int(crest) - 1, Color("#dce8f4"))
	# Spray arcing down either side.
	for k in 10:
		var t := fposmod(float(st.f) / st.n + k / 10.0, 1.0)
		var side := -1.0 if k % 2 == 0 else 1.0
		var p := Vector2(30.5 + side * (5.0 + t * 11.0), crest + 2.0 + t * t * 24.0)
		var bead := _layer()
		_flat_ellipse(bead, p, Vector2(1.5, 1.5), Color("#9cd4fc"))
		_stamp(front, bead, Color("#2c4c5c"))
		_px(front, int(p.x), int(p.y) - 1, Color("#dce8f4"))

# Elf Circle's tall rows: a tall pointed leaf hat rising off its head, its tip bending over with a
# glowing teal light hanging from it (narrow: little of the cell above is hidden).
func _tall_elf_circle(back: Image, front: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var base := 32.0 + 6 + dy  # the hat brim, in tall-frame rows
	var sway: float = [0.0, 0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5][st.f % 8]
	var tip := Vector2(41 + sway, 9)
	var hat := _layer()
	_flat_polygon(hat, PackedVector2Array([Vector2(22, base), Vector2(27, base - 14), Vector2(32 + sway * 0.5, base - 24),
		tip, Vector2(37 + sway * 0.5, base - 20), Vector2(36, base - 10), Vector2(40, base)]), Color(LEAF[1]))
	for y in range(-OY, S):
		for x in S:
			if _gp(hat, x, y).a > 0.0 and x > 31 + (base - y) * 0.15:
				_sp(hat, x, y, Color(LEAF[0]))  # its shaded side
	_stamp(front, hat, Color("#17174d"))
	# The leaf's midrib and a band of mushrooms round the brim.
	_line(front, [Vector2(31, base - 1), Vector2(32 + sway * 0.5, base - 22), tip + Vector2(-1, 1)], Color(LEAF[2]))
	for k in 4:
		var x := 24 + k * 5
		_px(front, x, int(base) - 1, Color("#7ff0e0"))
		_px(front, x + 1, int(base) - 1, Color("#7ff0e0"))
		_px(front, x, int(base) - 2, Color("#d8fff8"))
	# The light hanging off the tip, swinging.
	var light := Vector2i((tip + Vector2(1, 4)).round())
	_px(front, light.x, light.y - 1, Color("#17174d"))
	_glow_dot(front, light + Vector2i(0, 1), Color("#d8fff8"), Color("#7ff0e0"))

# Starcave's tall rows: a cluster of crystal spires grown up behind it (drawn behind the body so its
# head and shoulders sit in front), stars twinkling round their tips.
func _tall_starcave(back: Image, front: Image, st: Dictionary) -> void:
	var gems := _ramp(["#8a60d0", "#c0a0ff", "#f0e8ff"])
	var o := Color("#1e120a")
	for c: Vector4 in [Vector4(24, 50, 22, -3), Vector4(41, 50, 18, 3), Vector4(32.5, 52, 38, 0)]:
		_prism(back, Vector2(c.x, c.y), 3.2, c.z, c.w, gems, o)
	for k in 4:
		var p: Vector2i = [Vector2i(32, 11), Vector2i(19, 26), Vector2i(46, 30), Vector2i(38, 18)][k]
		if (st.f + k) % 2 == 0:
			_sparkle(front, p, Color("#f0e8ff"))
		else:
			_px(front, p.x, p.y, Color("#c0a0ff"))

# Snugroot's tall frame: two roots rise from the slab's back corners and arch over its head into a
# bower (thin, so the cell above shows through), hung with blossoms; the tall rows behind are empty.
func _tall_snugroot(back: Image, front: Image, st: Dictionary) -> void:
	pass

func _tall_full_snugroot(frame: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var root := Color("#d8c08a")
	var o := Color("#1e160e")
	var apex := 12 + dy
	_tall_stroke(frame, [Vector2(8, 76), Vector2(7, 52), Vector2(10, 30), Vector2(18, apex + 8), Vector2(31, apex), Vector2(44, apex + 8), Vector2(53, 30), Vector2(56, 52), Vector2(55, 76)], 1.4, root, o)
	# Twigs off the arch and blossoms along it.
	for b: Vector2 in [Vector2(12, 26), Vector2(22, apex + 4), Vector2(31, apex - 1), Vector2(40, apex + 4), Vector2(51, 26), Vector2(8, 44), Vector2(56, 44)]:
		var p := Vector2i(b)
		frame.set_pixel(p.x, p.y - 1, Color("#6ab04a"))
		frame.set_pixel(p.x + 1, p.y - 2, Color("#9ad86a"))
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			frame.set_pixelv(p + d + Vector2i(0, 1), Color("#f4a0c0"))
		frame.set_pixelv(p + Vector2i(0, 1), Color("#ffd24a"))

# Grafted Elder's tall rows: a small grafted tree grows up out of its stump-top, its trunk splitting
# into three compact crowns, blossom, leaf and gold (one per graft), each swaying a little.
func _tall_grafted_elder(back: Image, front: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var o := Color("#22160e")
	var foot := Vector2(31, 32 + 5 + dy)  # its stump-top, in tall-frame rows
	var fork := Vector2(31, 26 + dy)
	var trunk := _layer()
	_stroke(trunk, [foot, fork], 1.6, Color("#7a5234"))
	var crowns := [[Vector2(22, 14 + dy), _ramp(["#c05080", "#f090b8", "#ffd0e4"])],
		[Vector2(31, 9 + dy), _ramp(LEAF)],
		[Vector2(40, 14 + dy), _ramp(["#b87a20", "#e8b040", "#ffe080"])]]
	for c: Array in crowns:
		_stroke(trunk, [fork, (c[0] as Vector2) + Vector2(0, 4)], 1.0, Color("#7a5234"))
	_stamp(front, trunk, o)
	for i in crowns.size():
		var c: Vector2 = crowns[i][0]
		var sway: float = [0.0, 0.5, 0.0, -0.5][(st.f + i * 2) % 4]
		var crown := _layer()
		_ellipse(crown, c + Vector2(sway, 0), Vector2(5.2, 4.4), crowns[i][1])
		_ellipse(crown, c + Vector2(sway - 3, 2), Vector2(3.0, 2.6), crowns[i][1])
		_ellipse(crown, c + Vector2(sway + 3, 2), Vector2(3.0, 2.6), crowns[i][1])
		_stamp(front, crown, o)
	# Twine where the grafts are bound.
	_px(front, int(fork.x) - 1, int(fork.y) + 1, Color("#e8d8b0"))
	_px(front, int(fork.x) + 1, int(fork.y) + 1, Color("#e8d8b0"))

# Midsummer's tall rows: two tall sunflowers grown up behind it, one either side, their heads turned
# to the light, so the final towers over Sunpetal's single bloom.
func _tall_midsummer(back: Image, front: Image, st: Dictionary) -> void:
	var o := Color("#1e3a14")
	for s: Vector3 in [Vector3(12, 20, -1), Vector3(51, 16, 1)]:
		var head := Vector2(s.x, s.y + (1.0 if st.f % 4 == 2 else 0.0))
		var stalk := _layer()
		_stroke(stalk, [Vector2(s.x - s.z * 3, 63), Vector2(s.x - s.z, 40), head], 1.0, Color(LEAF[1]))
		_stamp(back, stalk, o)
		_leaf(back, Vector2(s.x - s.z * 2, 44), Vector2(s.x - s.z * 2 - s.z * 7, 38), 2.6, _ramp(LEAF), o)
		_petals(back, head, 13, 4.0, 10.0, 2.8, _ramp(["#f0c030", "#ffe070", "#fff4c0"]), o, float(st.f) * TAU / 96.0 + s.x)
		var disc := _layer()
		_flat_ellipse(disc, head, Vector2(4.2, 3.8), Color("#6a4020"))
		_stamp(back, disc, o)
		_px(back, int(head.x) - 1, int(head.y) - 1, Color("#8a5a2a"))

# Puffball's tall rows: a giant puffball grown up out of its cap with a smaller one on top, puffing a
# little cloud of spores from its opening each loop.
func _tall_puffball(back: Image, front: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var puff := _ramp(["#c8b898", "#e4d8bc", "#f6eedc", "#ffffff"])
	var o := Color(LAVENDER[0])
	var big := Vector2(30.5, 27 + dy)
	_puffball(front, big, 9.5, puff, o)
	_puffball(front, Vector2(38, 20 + dy), 4.5, puff, o)
	# The opening on top of the big one, and the spores puffing out of it.
	_px(front, int(big.x) - 1, int(big.y) - 8, Color("#8a7a5a"))
	_px(front, int(big.x), int(big.y) - 8, Color("#8a7a5a"))
	var t := fposmod(float(st.f) / st.n, 1.0)
	for k in 5:
		var a := k * TAU / 5.0 + t * 2.0
		var p := Vector2(big.x - 0.5, big.y - 9) + Vector2(cos(a) * (2.0 + t * 7.0), -t * 10.0 + sin(a) * 1.5)
		_px(front, int(p.x), int(p.y), Color("#f0eaff", 1.0 - t * 0.7))
		if k % 2 == 0:
			_px(front, int(p.x) + 1, int(p.y), Color("#b4a0ee", 1.0 - t * 0.7))

# Monsoon's tall rows: a broad, flat rain cloud hovering above it (not Thunderhead's tall column), heavy
# rain falling from it in slanted sheets onto the Warden.
func _tall_monsoon(back: Image, front: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var ramp := _ramp(["#4a5a80", "#6a7aa0", "#9aaac8", "#c8d4e8"])
	var o := Color("#1e2a48")
	var c := Vector2(31, 14 + dy)
	var cloud := _layer()
	_ellipse(cloud, c, Vector2(15, 5), ramp)
	_ellipse(cloud, c + Vector2(-8, -3), Vector2(7, 5), ramp)
	_ellipse(cloud, c + Vector2(6, -4), Vector2(8, 6), ramp)
	_ellipse(cloud, c + Vector2(13, 0), Vector2(5, 4), ramp)
	_stamp(front, cloud, o)
	for x in range(int(c.x) - 13, int(c.x) + 14):
		if _gp(front, x, int(c.y) + 4).a > 0.0 and _gp(front, x, int(c.y) + 4) != o:
			_sp(front, x, int(c.y) + 4, ramp[0])  # its dark rainy underside
	for k in 9:
		var x := int(c.x) - 12 + k * 3
		var y0: int = int(c.y) + 6 + ((st.f * 4 + k * 7) % 18)
		for i in 3:
			_px(back, x - i / 2 - (y0 + i) / 12, y0 + i, Color("#9ad4ff", 0.9 - i * 0.2))

# --- Final forms: a stronger 64x64 silhouette than their branch (grey 32 px test) ----------------
# Drawn over the finished body (idle and attack), framing the figure so its face stays clear: a
# wider stance, a distinct crown or prop, a different outline mass. Ten finals went tall instead
# (TALL_WARDENS); the rest stay 64x64 and get one of these.

func _final_extra(tower_name: String, canvas: Image, st: Dictionary) -> void:
	if has_method("_final_extra_" + tower_name):
		call("_final_extra_" + tower_name, canvas, st)
	if EPIC.has(tower_name):
		_epic_final(tower_name, canvas, st)

# Hoarfrost: great ice spikes jutting out of both shoulders and icicles off the arms (Frostfern has
# a few small crystals).
func _final_extra_hoarfrost(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var ice := _ramp(["#6aa8e0", "#b4e4ff", "#f4fcff"])
	var o := Color("#16305e")
	for s: Vector4 in [Vector4(16, 24, 17, -10), Vector4(46, 24, 17, 10), Vector4(13, 32, 11, -8), Vector4(49, 32, 11, 8)]:
		_prism(canvas, Vector2(s.x, s.y + dy), 3.6, s.z, s.w, ice, o)
	for x in [19, 22, 41, 44]:
		var len: int = 2 + (x + st.f) % 2
		for i in len:
			_px(canvas, x, 34 + i, Color("#b4e4ff") if i < len - 1 else Color("#f4fcff"))

# Lullaby Bell: two big bells hung from the ends of its frame's crossbar, swinging out past the frame
# (Chime Stone has thin chimes there).
func _final_extra_lullaby_bell(canvas: Image, st: Dictionary) -> void:
	var swing: float = [0.0, 1.0, 0.0, -1.0][st.f % 4]
	var bronze := _ramp(["#a86a1a", "#e8b040", "#ffe080"])
	var o := Color("#3a2410")
	for side: int in [-1, 1]:
		var top := Vector2(31.5 + side * 25, 15)
		var c := top + Vector2(swing * side, 7)
		var bell := _layer()
		_flat_polygon(bell, PackedVector2Array([c + Vector2(-2, -5), c + Vector2(2, -5), c + Vector2(3, -1), c + Vector2(5, 4), c + Vector2(-5, 4), c + Vector2(-3, -1)]), bronze[1])
		_ellipse(bell, c + Vector2(0, -4), Vector2(2.6, 2.0), bronze)
		_stamp(canvas, bell, o)
		_line(canvas, [c + Vector2(-1, -3), c + Vector2(-2, 2)], bronze[2])
		_px(canvas, int(c.x), int(c.y) + 5, o)  # the clapper
		_line(canvas, [top, c + Vector2(0, -6)], o)

# Long Way Home: a broad-brimmed traveller's hat and a bundle slung at its side (Rootcurl is bare-headed).
func _final_extra_long_way_home(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var o := Color("#1e160e")
	var hat := _layer()
	_flat_ellipse(hat, Vector2(30.5, 5.5 + dy), Vector2(15, 2.6), Color("#5c3c24"))
	_ellipse(hat, Vector2(30.5, 2.5 + dy), Vector2(7, 3.5), _ramp(["#3a2410", "#5c3c24", "#8c5c34"]), 5.0 + dy)
	_stamp(canvas, hat, o)
	_line(canvas, [Vector2(24, 4 + dy), Vector2(37, 4 + dy)], Color("#e9a83c"))  # a hat band
	_leaf(canvas, Vector2(36, 3 + dy), Vector2(41, -1 + dy), 1.6, _ramp(LEAF), o)  # a leaf tucked in it
	var bundle := _layer()
	_ellipse(bundle, Vector2(11, 33), Vector2(6, 5), _ramp(["#8a6a44", "#b09070", "#d0b48c"]))
	_stamp(canvas, bundle, o)
	_line(canvas, [Vector2(8, 30), Vector2(14, 36)], Color("#5c3c24"))
	_line(canvas, [Vector2(11, 28), Vector2(19, 22)], Color("#5c3c24"))  # its strap

# Autumn Gale: a whirl of big autumn leaves orbiting it, widening its outline (Samara holds one seed).
func _final_extra_autumn_gale(canvas: Image, st: Dictionary) -> void:
	var o := Color(MAPLE[0])
	for k in 8:
		var a: float = k * TAU / 8.0 + float(st.f) * TAU / st.n * 0.5
		var p := Vector2(31, 20) + Vector2(cos(a) * 26.0, sin(a) * 13.0)
		if sin(a) < -0.85:
			continue  # the ones behind are hidden by it
		var d := Vector2.from_angle(a + PI / 2.0 + k)
		_leaf(canvas, p - d * 4.5, p + d * 5.0, 3.6, _ramp(["#b8662c", "#e9a83c", "#fcd47c"]), o)

# Zephyr: a long scarf streaming from its neck far out to one side in the wind (Gust has none).
func _final_extra_zephyr(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var pts: Array = []
	for i in 9:
		var t := i / 8.0
		pts.append(Vector2(38 + t * 24, 16 + dy - t * 6 + sin(t * 5.0 + st.f * 0.8) * 2.0))
	var scarf := _layer()
	_stroke(scarf, pts, 2.3, Color("#9cd4fc"))
	_stroke(scarf, [Vector2(22, 17 + dy), Vector2(30, 19 + dy), Vector2(39, 16 + dy)], 2.0, Color("#9cd4fc"))
	_stamp(canvas, scarf, Color("#1e2a48"))
	for i in range(1, pts.size(), 2):
		var p: Vector2 = pts[i]
		_px(canvas, int(p.x), int(p.y), Color("#4c8ca4"))  # stripes
	var end: Vector2 = pts[pts.size() - 1]
	for i in 3:
		_px(canvas, int(end.x) - i, int(end.y) + 2 + i, Color("#9cd4fc"))  # the fringe

# Jewelwing Court: a jewelled crown and big trumpet blossoms at the top of its bower (the Bower is bare).
func _final_extra_jewelwing_court(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var o := Color("#12101e")
	var crown := _layer()
	_flat_polygon(crown, PackedVector2Array([Vector2(24, 7 + dy), Vector2(24, 2 + dy), Vector2(27, 4 + dy), Vector2(30.5, 0 + dy),
		Vector2(34, 4 + dy), Vector2(37, 2 + dy), Vector2(37, 7 + dy)]), Color("#e9a83c"))
	_stamp(canvas, crown, o)
	_px(canvas, 30, 3 + dy, Color("#3ac070"))
	_px(canvas, 26, 5 + dy, Color("#ec9cf4"))
	_px(canvas, 35, 5 + dy, Color("#9cd4fc"))
	for c: Vector2 in [Vector2(9, 15), Vector2(54, 15)]:
		for k in 3:
			var d := Vector2.from_angle(PI / 2.0 + (k - 1) * 0.7)
			var tr := _layer()
			_stroke(tr, [c, c + d * 6.0], 1.0, Color("#ec9cf4"))
			_flat_ellipse(tr, c + d * 6.5, Vector2(1.8, 1.8), Color("#ec9cf4"))
			_stamp(canvas, tr, o)
			_px(canvas, int(c.x + d.x * 6.5), int(c.y + d.y * 6.5), Color("#fcd47c"))

# Magpie's Hoard: an open treasure chest spilling coins at its right foot, opposite the coin mound
# (the Perch has neither).
func _final_extra_magpies_hoard(canvas: Image, st: Dictionary) -> void:
	var o := Color("#141420")
	var chest := _layer()
	_round_rect(chest, Rect2i(44, 37, 15, 8), 1, Color("#8c5c34"))
	_round_rect(chest, Rect2i(44, 31, 15, 6), 1, Color("#5c3c24"))  # the open lid, tipped back
	_stamp(canvas, chest, o)
	_line(canvas, [Vector2(44, 40), Vector2(58, 40)], Color("#e9a83c"))
	_line(canvas, [Vector2(51, 37), Vector2(51, 44)], Color("#e9a83c"))
	for p: Vector2i in [Vector2i(46, 36), Vector2i(49, 35), Vector2i(53, 36), Vector2i(56, 35), Vector2i(43, 44), Vector2i(60, 44)]:
		_px(canvas, p.x, p.y, Color("#fcd47c"))
		_px(canvas, p.x + 1, p.y, Color("#e9a83c"))
	if st.f % 4 < 2:
		_sparkle(canvas, Vector2i(52, 33), Color("#fff4dc"))

# Grove Heart: a broad leafy canopy spreading over its head like a small grove (Elder Stump is bare).
func _final_extra_grove_heart(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var o := Color("#22160e")
	var canopy := _layer()
	for c: Vector3 in [Vector3(17, 4, 6), Vector3(26, 1, 6.5), Vector3(36, 1, 6.5), Vector3(45, 4, 6)]:
		_ellipse(canopy, Vector2(c.x + (st.sway if c.x > 30 else 0), c.y + dy), Vector2(c.z, c.z * 0.65), _ramp(LEAF))
	# Keep its face clear: nothing below the brow line.
	for y in range(EYE_TOP - 4 + dy, S):
		for x in S:
			_sp(canopy, x, y, Color(0, 0, 0, 0))
	_stamp(canvas, canopy, o)
	for p: Vector2i in [Vector2i(20, 2), Vector2i(31, 0), Vector2i(41, 2)]:
		_px(canvas, p.x, p.y + dy, Color("#fcd47c"))  # blossoms in it

# Beacon's crook foot, drawn after the body so the pole stands in front of the slab rock it's planted
# beside (the rock tucked behind its base), rising out of the top of the body frame into the tall rows.
func _final_extra_beacon(canvas: Image, st: Dictionary) -> void:
	var o := Color("#2a1a10")
	var staff := _layer()
	_stroke(staff, [Vector2(BEACON_STAFF_X - 1, 45), Vector2(BEACON_STAFF_X, 20), Vector2(BEACON_STAFF_X, -2)], 0.9, Color("#8a5c34"))
	_stamp(canvas, staff, o)
	# Clear the stamp's outline across the top edge so the staff runs on into the tall rows.
	for x in range(BEACON_STAFF_X - 3, BEACON_STAFF_X + 4):
		if _gp(canvas, x, -OY) == o:
			_sp(canvas, x, -OY, Color("#8a5c34") if absi(x - BEACON_STAFF_X) <= 0 else Color(0, 0, 0, 0))

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
	if not beacon:
		_leaf(canvas, Vector2(21, 21 + dy), Vector2(21 - span + flap, 5 + dy), 7.5, wing, fig.o)
		_leaf(canvas, Vector2(40, 21 + dy), Vector2(40 + span - flap, 4 + dy), 7.5, wing, fig.o)
		_leaf(canvas, Vector2(22, 29 + dy), Vector2(22 - span * 0.8, 38), 5.0, wing, fig.o)
		_leaf(canvas, Vector2(39, 29 + dy), Vector2(39 + span * 0.8, 38), 5.0, wing, fig.o)
		for s: Vector2 in [Vector2(21 - span * 0.55 + flap * 0.5, 12 + dy), Vector2(40 + span * 0.55 - flap * 0.5, 11 + dy)]:
			var eye := _layer()
			_flat_ellipse(eye, s, Vector2(2.2, 2.2), Color("#5a3a2a"))
			_flat_ellipse(eye, s, Vector2(1.2, 1.2), Color("#f0a040"))
			_stamp(canvas, eye)
	else:
		_beacon_wings_and_crook(canvas, st, fig, wing)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	_glass(canvas, mask, st, fig, Color("#f8d8a0"))
	# The light in its chest, pulsing.
	# Beacon's light is steady and brighter; Lanternmoth's flickers.
	var pulse: float = (1.3 + st.power * 0.3) if beacon else (1.0 + 0.2 * sin(TAU * float(st.f) / st.n) + st.power * 0.4)
	for y in range(-OY, S):
		for x in S:
			var q := ((Vector2(x + 0.5, y + 0.5) - Vector2(30, 29 + dy)) / (Vector2(5, 6) * pulse)).length()
			if q < 1.0 and _gp(mask, x, y).a > 0.0 and _gp(canvas, x, y) != fig.o:
				if q < 0.5:
					_sp(canvas, x, y, Color.WHITE if beacon else Color("#fff0b0"))
				elif q < 0.8:
					_sp(canvas, x, y, Color("#f8d890"))
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

# Beacon: broad, flat-spread wings with eye-spots and bands (a resting moth, not Lanternmoth's raised
# wings), and a shepherd's crook planted beside it that lifts a big lantern high above it: Beacon is
# a TALL Warden (64x96, see TALL_WARDENS), its light the highest point of the sprite. The crook's
# foot is drawn here in body space; its top, the lantern and the light cone in _tall_beacon.
const BEACON_STAFF_X := 55

func _beacon_wings_and_crook(canvas: Image, st: Dictionary, fig: Dictionary, wing: Array[Color]) -> void:
	var dy: int = st.dy
	var flap: int = st.sway
	var layer := _layer()
	_leaf(layer, Vector2(21, 21 + dy), Vector2(1 + flap, 10 + dy), 9.0, wing, fig.o)
	_leaf(layer, Vector2(40, 21 + dy), Vector2(62 - flap, 10 + dy), 9.0, wing, fig.o)
	_leaf(layer, Vector2(22, 29 + dy), Vector2(4, 37), 6.5, wing, fig.o)
	_leaf(layer, Vector2(39, 29 + dy), Vector2(58, 37), 6.5, wing, fig.o)
	# Bands across the upper wings and a big eye-spot on each.
	for side: int in [-1, 1]:
		for b in 2:
			var bx := 30.5 + side * (14.0 + b * 6.0)
			for y in range(4, 26):
				var x := int(bx + (y - 14) * 0.3 * side)
				var c := _gp(layer, x, y + dy)
				if c.a > 0.0 and c != fig.o:
					_sp(layer, x, y + dy, wing[0])
		var spot := Vector2(30.5 + side * 20.0 - side * flap * 0.5, 13 + dy)
		var eye := _layer()
		_flat_ellipse(eye, spot, Vector2(3.2, 2.8), Color("#5a3a2a"))
		_flat_ellipse(eye, spot, Vector2(2.0, 1.8), Color("#fcd47c"))
		_flat_ellipse(eye, spot, Vector2(0.8, 0.8), Color.WHITE)
		for y in range(-OY, S):
			for x in S:
				if _gp(eye, x, y).a > 0.0 and _gp(layer, x, y).a > 0.0 and _gp(layer, x, y) != fig.o:
					_sp(layer, x, y, _gp(eye, x, y))
	canvas.blend_rect(layer, Rect2i(0, 0, S, S + OY), Vector2i.ZERO)

# Beacon's tall rows (frame y 0..63 of the 64x96 frame; the body frame starts at y 32): the crook's top
# hooking over, the big lantern hanging from it, and a soft cone of light falling towards the moth.
const BEACON_LAMP := Vector2(46, 18)

func _tall_beacon(back: Image, front: Image, st: Dictionary) -> void:
	var o := Color("#2a1a10")
	var bright: bool = st.f % 4 < 2 or st.power > 0.5
	# The light cone (behind the moth), in alpha steps.
	for y in range(int(BEACON_LAMP.y) + 5, 46):
		var half := (y - BEACON_LAMP.y - 2) * 0.5
		for x in range(int(BEACON_LAMP.x - half), int(BEACON_LAMP.x + half) + 1):
			if x >= 0 and x < S:
				_sp(back, x, y, Color("#fcd47c", snappedf(0.3 * (1.0 - (y - BEACON_LAMP.y) / 32.0), 0.04)))
	var staff := _layer()
	_stroke(staff, [Vector2(BEACON_STAFF_X, 64), Vector2(BEACON_STAFF_X, 11), Vector2(BEACON_STAFF_X - 1, 7),
		Vector2(BEACON_STAFF_X - 4, 5), Vector2(BEACON_LAMP.x + 1, 6), Vector2(BEACON_LAMP.x, 9)], 0.9, Color("#8a5c34"))
	_stamp(front, staff, o)
	var lamp := _layer()
	_round_rect(lamp, Rect2i(int(BEACON_LAMP.x) - 4, int(BEACON_LAMP.y) - 6, 9, 11), 2, Color("#e9a83c"))
	_stamp(front, lamp, o)
	# Glass panes, the steady flame, the cap and a little ring it hangs from.
	_round_rect(front, Rect2i(int(BEACON_LAMP.x) - 2, int(BEACON_LAMP.y) - 4, 5, 7), 1, Color("#fff4dc"))
	_round_rect(front, Rect2i(int(BEACON_LAMP.x) - 1, int(BEACON_LAMP.y) - 2, 3, 4), 0, Color.WHITE if bright else Color("#fcd47c"))
	_line(front, [BEACON_LAMP + Vector2(-4, -7), BEACON_LAMP + Vector2(4, -7)], Color("#5c3c24"))
	_line(front, [BEACON_LAMP + Vector2(-3, -8), BEACON_LAMP + Vector2(3, -8)], Color("#5c3c24"))
	_px(front, int(BEACON_LAMP.x), int(BEACON_LAMP.y) - 9, o)
	if st.attack >= 0:
		_warm_glow(front, BEACON_LAMP, Vector2(8, 8), st.f)  # the lamp glows when it fires (AI-look audit: glow marks the attack)
	# Motes rising off the light.
	for k in 3:
		var t := fposmod(float(st.f) / st.n + k / 3.0, 1.0)
		_px(front, int(BEACON_LAMP.x) - 4 + k * 4, int(BEACON_LAMP.y - 9 - t * 8), Color("#fff4dc", 1.0 - t))

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
	for y in range(-OY, S):
		for x in S:
			if ((Vector2(x + 0.5, y + 0.5) - face_c) / Vector2(8.5, 6.5)).length() < 1.0 and _gp(mask, x, y).a > 0.0 and _gp(canvas, x, y) != fig.o:
				_sp(canvas, x, y, Color("#6a4020") if ((Vector2(x + 0.5, y + 0.5) - face_c) / Vector2(8.5, 6.5)).length() < 0.55 else Color("#8a5a2a"))
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
	_stroke(staff, [Vector2(52, 46), Vector2(51, 12), Vector2(52, 8), Vector2(55, 7.5), Vector2(57, 9)], 1.2, Color("#8a6a4a"))
	_flat_ellipse(staff, Vector2(51.5, 9), Vector2(1.6, 1.6), Color("#8a6a4a"))
	_stamp(canvas, staff, fig.o)
	var lamp := _layer()
	_round_rect(lamp, Rect2i(55, 12, 5, 6), 1, Color("#fff0b0") if st.f % 4 < 2 else Color("#f8d890"))
	_stamp(canvas, lamp, fig.o)
	_px(canvas, 57, 10, fig.o)
	_px(canvas, 57, 11, fig.o)
	_curls(canvas, st, fig)
	_golem_face(canvas, st, fig)
	var beard := _layer()
	_flat_polygon(beard, PackedVector2Array([Vector2(24, 16 + dy), Vector2(37, 16 + dy), Vector2(35, 21 + dy),
		Vector2(30.5, 25 + dy), Vector2(26, 21 + dy)]), Color("#5a9a48"))
	for y in range(-OY, S):
		for x in S:
			if _gp(beard, x, y).a > 0.0 and (x + y) % 3 == 0:
				_sp(beard, x, y, Color("#7cbc5a"))
	_stamp(canvas, beard, Color("#1e3a24"))

func _curls(canvas: Image, st: Dictionary, fig: Dictionary) -> void:
	var dy: int = st.dy
	var lift: int = st.lift
	var layer := _layer()
	_stroke(layer, _spiral_pts(Vector2(23, 26 + dy), Vector2(14, 14 + dy + lift), 4.5, 1.25, 0.0), 1.4, fig.a)
	_stroke(layer, _spiral_pts(Vector2(40, 26 + dy), Vector2(48, 13 + dy + lift), 4.5, 1.25, PI), 1.4, fig.a)
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
			if _gp(mask, x, y).a > 0.0 and _gp(canvas, x, y) != fig.o:
				_px(canvas, x, y, water)
	var rim := _layer()
	_ellipse(rim, Vector2(30.5, 6 + dy), Vector2(10, 3.2), _ramp(["#6a5a4a", "#8a7a6a", "#b0a090", "#d0c4b4"]))
	_stamp(canvas, rim, fig.o)
	var pool := _layer()
	_flat_ellipse(pool, Vector2(30.5, 5.5 + dy), Vector2(7.5, 1.6), Color("#4a8ed0"))
	_stamp(canvas, pool)
	# The spring spouting up out of the well.
	var spout_h: int = 4 + (st.f % 2)
	for y in range(maxi(-OY, 5 + dy - spout_h), 5 + dy):
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
	# Lash out and hook (release), pull taut, YANK back (speed lines, the hook dragging its catch),
	# then recoil into a coil, so the pull-back reads as a drag, not a teleport.
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 3:
		return
	var reach := Vector2(ATTACKS["rootcurl"].point)
	var tip: Vector2 = [reach, reach, Vector2(52, 27), Vector2(47, 24)][k]
	var layer := _layer()
	if k == 1:
		_stroke(layer, [Vector2(42, 24), tip], 2.0, fig.a)  # taut
	else:
		_stroke(layer, [Vector2(42, 24), Vector2(46 + k, 25 - k), tip], 2.0, fig.a)
	if k < 3:
		_stroke(layer, [tip, tip + Vector2(2, 3), tip + Vector2(-1, 5), tip + Vector2(-3, 3.5)], 1.5, fig.a)
	else:
		_stroke(layer, _spiral_pts(tip, tip + Vector2(0, -2), 2.2, 1.0, 0.0), 1.0, fig.a)
	_stamp(canvas, layer, fig.o)
	if k == 1:
		for x in range(46, 58, 3):  # it strains
			_px(canvas, x, 22 + ((x - 42) * 7) / 18 - 2, Color("#fff4c0"))
	if k == 2:
		for row in 3:  # yanked: streaks trailing where the hook came from
			for i in range(3 + row, 10 - row):
				_px(canvas, int(tip.x) + i, int(tip.y) - 1 + row * 2 + i / 4, Color("#fff4c0", 1.0 - i * 0.08))
	if k <= 2:
		_warm_glow(canvas, tip, Vector2(7, 6))  # the hook glows as it catches
	if k <= 1:
		_ring(canvas, tip, Vector2(5 + k * 3, 4 + k * 2), Color("#fff4c0"), k == 1)  # the catch
	if sparkly and k <= 1:
		_sparkle(canvas, Vector2i(tip) + Vector2i(2, -3), Color("#fff4c0"))

func _attack_rootcurl(canvas: Image, st: Dictionary) -> void:
	_root_lash(canvas, st, _pal(BARK[0], BARK[1], BARK[2], BARK[3]), false)

func _attack_long_way_home(canvas: Image, st: Dictionary) -> void:
	_root_lash(canvas, st, _pal(BARK[0], BARK[1], BARK[2], BARK[3]), true)

# Roots spiking up out of the ground round the stump, then sinking back.
func _root_spikes(canvas: Image, st: Dictionary, spots: Array, flowers: bool) -> void:
	# Roots breaking the ground (release frames 2-4): thick tapering root tips punch up out of the soil
	# at each spot, a puff of earth and flung soil at their feet, a warm glint at the tips.
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	var h: float = [9.0, 13.0, 6.0][k]
	var layer := _layer()
	for p: Vector2 in spots:
		var lean := (p.x - 31.5) * 0.08
		_flat_polygon(layer, PackedVector2Array([p + Vector2(-2.6, 0), p + Vector2(lean, -h), p + Vector2(2.6, 0)]), Color("#dccdb2"))
		_stroke(layer, [p + Vector2(-0.8, 0), p + Vector2(lean * 0.5 - 0.5, -h * 0.6)], 0.6, Color("#fff4dc"))
	_stamp(canvas, layer, Color("#241c14"))
	for p: Vector2 in spots:
		var lean := (p.x - 31.5) * 0.08
		_px(canvas, int(p.x + lean), int(p.y - h), Color("#fff4dc"))
		if k < 2:
			for s: int in [-1, 1]:
				_px(canvas, int(p.x) + s * (3 + k), int(p.y) - 1 - k, Color("#8c5c34"))  # flung soil
				_px(canvas, int(p.x) + s * (4 + k * 2), int(p.y) - 2 - k * 2, Color("#5c3c24"))
		_warm_glow(canvas, p + Vector2(lean, -h), Vector2(4, 3), k)
	if flowers and k == 1:
		for p: Vector2 in spots:
			_flower(canvas, Vector2i(p) + Vector2i(1, -int(h) - 1), Color("#f4a0c0"), Color("#ffd24a"))


func _attack_tangleroot(canvas: Image, st: Dictionary) -> void:
	_root_burst(canvas, st, 1.05, false)

func _attack_snugroot(canvas: Image, st: Dictionary) -> void:
	_root_burst(canvas, st, 1.15, true)

func _attack_elder_stump(canvas: Image, st: Dictionary) -> void:
	_pulse(canvas, st, Color("#b8f080"))

func _attack_grove_heart(canvas: Image, st: Dictionary) -> void:
	_pulse(canvas, st, Color("#b8f080"))
	var k: int = st.attack - RELEASE_FRAME
	if k >= 0 and k < 3:
		for p: Vector2i in [Vector2i(10, 14), Vector2i(52, 12), Vector2i(6, 26), Vector2i(56, 26)]:
			_px(canvas, p.x + k, p.y + k * 3, Color("#6ab04a"))
			_px(canvas, p.x + k + 1, p.y + k * 3, Color("#9ad86a"))

# --- New Wardens (tower_design.md, 2026-09-27) ------------------------------------------------
# Hidden branches, the Nestling (wing) and Whirligig (wind) lines, Honeysuckle, and the Memory
# Wardens freed from the act bosses.

const MEMORY_GOLD := Color("#f0c860")

# Waystone themes for the new lines.
func _decor_nest(canvas: Image, top: Image, _side: Image, _st: Dictionary, lush: bool) -> void:
	var twigs := [Color("#5a4228"), Color("#8a6a40"), Color("#b08a50")]
	for y in range(-OY, S):
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
			_sp(canvas, x, y, col)
	var eggs: Array = [Vector2i(9, 42), Vector2i(54, 43)] if lush else [Vector2i(54, 43)]
	for e: Vector2i in eggs:
		if _on(top, e.x, e.y):
			var egg := _layer()
			_ellipse(egg, Vector2(e), Vector2(2, 2.6), _ramp(["#8ab8c8", "#b8e0ec", "#e8f8fc"]))
			_stamp(canvas, egg, Color("#2a1a10"))
			_px(canvas, e.x - 1, e.y - 1, Color("#5a8898"))

func _decor_windswept(canvas: Image, top: Image, _side: Image, st: Dictionary, lush: bool) -> void:
	for y in range(-OY, S):
		for x in S:
			if not _on(top, x, y):
				continue
			var h := (x * 29 + y * 53) % 9
			var streak: bool = (x + 2 * y + st.f) % 11 == 0
			_sp(canvas, x, y, Color("#b8e0a0") if streak else (Color("#8ad060") if h == 0 else (Color("#3f7a3e") if h == 4 else Color("#5a9a48"))))
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
	for y in range(-OY, S):
		for x in S:
			if not _on(top, x, y):
				continue
			var q := ((Vector2(x + 0.5, y + 0.5) - Vector2(31.5, 45)) / Vector2(26, 9.5)).length()
			if absf(q - 1.0) < 0.05 or (absf(q - 0.82) < 0.04 and int((Vector2(x + 0.5, y + 0.5) - Vector2(31.5, 45)).angle() * 8.0) % 2 == 0):
				_sp(canvas, x, y, MEMORY_GOLD if bright else Color("#c8a048"))
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
	for y in range(-OY, S):
		for x in S:
			var p := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(p, pts):
				var rel := p.x - (base.x + (base.y - p.y) / h * lean)
				_sp(layer, x, y, ramp[0] if rel < -w / 3.0 else (ramp[2] if rel > w / 3.0 else ramp[1]))
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
		# Two tall glowing toadstools on the slab either side (its hat is in _tall_elf_circle).
		for t: Vector3 in [Vector3(9, 45, 11), Vector3(55, 44, 9)]:
			var foot := Vector2(t.x, t.y)
			var stem := _layer()
			_stroke(stem, [foot, foot + Vector2(0, -t.z)], 0.9, Color("#f0e4d8"))
			_stamp(canvas, stem, fig.o)
			var cap_l := _layer()
			_ellipse(cap_l, foot + Vector2(0.5, -t.z - 0.5), Vector2(4.2, 2.6), _ramp(["#2a8878", "#5ad0c0", "#b8fff4"]), foot.y - t.z + 0.5)
			_stamp(canvas, cap_l, fig.o)
			_px(canvas, int(foot.x) - 1, int(foot.y - t.z) - 2, Color("#d8fff8"))
			_px(canvas, int(foot.x) + 2, int(foot.y - t.z) - 1, Color("#d8fff8"))
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
	# The menhir stands on the slab where the left rock was, its foot set a little into the ground.
	_flat_polygon(stone, PackedVector2Array([Vector2(6, 44), Vector2(7, 12), Vector2(11, 5), Vector2(17, 7), Vector2(19, 14), Vector2(19, 43)]), fig.b)
	for y in range(-OY, S):
		for x in S:
			if _gp(stone, x, y).a > 0.0 and x < 10:
				_sp(stone, x, y, fig.a)
			elif _gp(stone, x, y).a > 0.0 and x > 16:
				_sp(stone, x, y, fig.c)
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
	for y in range(-OY, S):
		for x in S:
			if _gp(halo, x, y).a > 0.0 and (x + y + st.f) % 3 != 0:
				_sp(halo, x, y, Color(0, 0, 0, 0))
	_stamp(canvas, halo)
	_petals(canvas, face_c, 14, 9.0, 16.0 - st.lift * 0.5, 2.6, _ramp(["#e07a20", "#f0a030", "#ffc860"]), fig.o, float(st.f) * TAU / 128.0 + 0.2)
	_petals(canvas, face_c, 12, 6.5, 13.0 - st.lift * 0.5, 2.6, _ramp(["#d89a20", "#f0c030", "#ffe070"]), fig.o, float(st.f) * TAU / 96.0)
	_leaf(canvas, Vector2(18, 31), Vector2(8, 24), 3.2, _ramp(LEAF), fig.o)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	for y in range(-OY, S):
		for x in S:
			if ((Vector2(x + 0.5, y + 0.5) - face_c) / Vector2(8.5, 6.5)).length() < 1.0 and _gp(mask, x, y).a > 0.0 and _gp(canvas, x, y) != fig.o:
				_sp(canvas, x, y, Color("#6a4020") if ((Vector2(x + 0.5, y + 0.5) - face_c) / Vector2(8.5, 6.5)).length() < 0.55 else Color("#8a5a2a"))
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
		# The star cave: a geode sat on the slab where the left rock was, crystals growing out of it.
		var geode := _layer()
		_ellipse(geode, Vector2(9.5, 38.5), Vector2(7.5, 5), _ramp(["#4a3e66", "#6a5a88", "#8e7eac", "#b0a2cc"]))
		_stamp(canvas, geode, fig.o)
		var mouth := _layer()
		_flat_ellipse(mouth, Vector2(9.5, 37), Vector2(4.5, 2), Color("#241c3a"))
		_stamp(canvas, mouth)
		var gems := _ramp(["#8a60d0", "#c0a0ff", "#f0e8ff"])
		for c: Vector3 in [Vector3(6, 37, 6), Vector3(10, 37, 11), Vector3(13.5, 38, 6)]:
			_prism(canvas, Vector2(c.x, c.y), 2.0, c.z, 0.4, gems, fig.o)
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
				_sparkle(canvas, [Vector2i(5, 27), Vector2i(56, 6), Vector2i(15, 30), Vector2i(58, 30)][k], Color("#f0e8ff"))

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
	for y in range(-OY, S):
		for x in S:
			if _gp(nest, x, y).a > 0.0 and (x * 2 + y) % 5 == 0:
				_sp(nest, x, y, Color("#e0c070"))
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
			if _gp(mask, x, y).a > 0.0 and _gp(canvas, x, y) != fig.o:
				_sp(canvas, x, y, ink[1] if x < 30 else ink[2])
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
		# The hoard: a heaped mound of coins against the golem's left side, gems pressed into it.
		var mound := _layer()
		_ellipse(mound, Vector2(11, 39), Vector2(9, 7), gold, 43)
		_ellipse(mound, Vector2(11, 42), Vector2(10, 3.4), gold)
		_stamp(canvas, mound, Color("#5a3a10"))
		for c: Vector2i in [Vector2i(7, 38), Vector2i(11, 35), Vector2i(15, 37), Vector2i(9, 41), Vector2i(13, 40), Vector2i(5, 42), Vector2i(17, 42)]:
			_px(canvas, c.x, c.y, Color("#b8862a"))
			_px(canvas, c.x + 1, c.y, Color("#fff0a0"))
		for g: Array in [[Vector2(8, 39), Color("#e04a6a"), Color("#5a1020")], [Vector2(15, 40), Color("#4a8ae0"), Color("#102a5a")]]:
			var gem := _layer()
			var gp: Vector2 = g[0]
			_flat_polygon(gem, PackedVector2Array([gp + Vector2(-1.5, 0), gp + Vector2(0, -1.8), gp + Vector2(1.5, 0), gp + Vector2(0, 1.8)]), g[1])
			_stamp(canvas, gem, g[2])
		_sparkle(canvas, Vector2i([Vector2(10, 38), Vector2(52, 41), Vector2(16, 40)][(st.f / 2) % 3]), Color.WHITE)
		# A gold chain with a ruby pendant across the chest.
		for x in range(24, 43):
			var y := 21 + dy + roundi(sin((x - 24) / 18.0 * PI) * 3.0)
			if _gp(mask, x, y).a > 0.0:
				_px(canvas, x, y, Color("#ffe070") if x % 2 == 0 else Color("#c8902a"))
		_px(canvas, 33, 25 + dy, Color("#e04a6a"))
		_px(canvas, 34, 25 + dy, Color("#e04a6a"))
		_px(canvas, 33, 26 + dy, Color("#a02040"))
		_px(canvas, 34, 26 + dy, Color("#ff8aa8"))
		# A little gold crown on the hood.
		for p: Vector2i in [Vector2i(27, 4), Vector2i(28, 4), Vector2i(29, 4), Vector2i(30, 4), Vector2i(31, 4), Vector2i(32, 4), Vector2i(33, 4),
				Vector2i(27, 3), Vector2i(30, 2), Vector2i(30, 3), Vector2i(33, 3)]:
			_px(canvas, p.x, p.y + dy, Color("#ffd24a") if p.y == 4 else Color("#fff0a0"))
		_px(canvas, 30, 4 + dy, Color("#e04a6a"))
		# A second magpie guarding the hoard.
		_magpie(canvas, Vector2(11, 29 - (1 if st.f % 4 == 3 else 0)), fig.o, st.f % 4 == 3, true, 1.6, 1)
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
	# Warm yellow-green (not the hedge green), a garland of honeysuckle draped across its chest and
	# round its head, cream-and-gold trumpet flowers hanging off it, a bee visiting.
	var dy: int = st.dy
	var fig := _pal("#1e2412", "#b8cc6a", "#94ae52", "#6e8a3e")
	_draw_waystone(canvas, st, "bramble", true)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	for y in range(-OY, S):
		for x in S:
			if _gp(mask, x, y).a > 0.0 and _gp(canvas, x, y) != fig.o and (x * 73 + y * 151) % 11 == 0:
				_sp(canvas, x, y, Color("#7a9a44"))
	var vine := Color("#3e5a22")
	var trumpet_o := Color("#4a2410")
	# The garland across the chest (sagging), a thick outlined vine.
	var chest: Array = []
	for s in 13:
		var u := s / 12.0
		chest.append(Vector2(17 + u * 28, 26 + sin(u * PI) * 7 + (dy if u < 0.2 or u > 0.8 else 0)))
	var g := _layer()
	_stroke(g, chest, 0.9, vine)
	_stamp(canvas, g, Color("#1e2a10"))
	# Trumpet flowers: a tube from the vine, a flared mouth; cream or gold (pinks snap to brown in
	# the palette pass), an orange throat.
	var trumpets: Array = []
	for i in [2, 5, 8, 11]:
		var p: Vector2 = chest[i]
		trumpets.append([p, p + Vector2(-1.5 if i < 6 else 1.5, 5), i % 2 == 0])
	# A fan of them on the head, like a flower crown.
	for k in 5:
		var a := lerpf(-PI * 0.85, -PI * 0.15, k / 4.0)
		var base := Vector2(30.5 + (k - 2) * 3.5, 6 + dy)
		trumpets.append([base, base + Vector2.from_angle(a) * 5.5, k % 2 == 1])
	for tr: Array in trumpets:
		var b: Vector2 = tr[0]
		var m: Vector2 = tr[1]
		var cream: bool = tr[2]
		var layer := _layer()
		_stroke(layer, [b, m], 1.2, Color("#fff4c8") if cream else Color("#ffd870"))
		_flat_ellipse(layer, m, Vector2(2.3, 2.3), Color("#fff4c8") if cream else Color("#ffd870"))
		_stamp(canvas, layer, trumpet_o)
		_px(canvas, int(m.x), int(m.y), Color("#f0a020"))
		_px(canvas, int(b.x), int(b.y), Color("#d8406a"))
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), true, true)
	# A bee visiting, looping round the flowers.
	var t: float = float(st.f) / st.n
	var bee := Vector2i((Vector2(47, 18) + Vector2(cos(t * TAU) * 5.0, sin(t * TAU * 2.0) * 2.0)).round())
	_px(canvas, bee.x, bee.y, Color("#ffd24a"))
	_px(canvas, bee.x + 1, bee.y, Color("#2a1e10"))
	_px(canvas, bee.x - 1, bee.y, Color("#2a1e10"))
	_px(canvas, bee.x, bee.y - 1, Color(1, 1, 1, 0.8) if st.f % 2 == 0 else Color(1, 1, 1, 0.5))
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
			if _gp(mask, x, y).a > 0.0 and _gp(canvas, x, y) != fig.o and ((Vector2(x, y) - Vector2(31, 36)) / Vector2(5.5, 8)).length() < 1.0:
				_sp(canvas, x, y, Color("#e8f0c0"))
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
	# The light pulse: a flash of light sinks down through its body into its roots (release), runs out
	# along the roots over the slab, and the tiles at their ends flare up as they're lit.
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	var core := Color("#fff4dc")
	var gold := Color("#fcd47c")
	var dy: int = st.dy
	if k == 0:
		_warm_glow(canvas, Vector2(31, 26 + dy), Vector2(16, 14), k)
		for y in range(16, 44, 3):
			_px(canvas, 31, y + dy, core)  # light sinking down its middle
	# Light running out along the roots, further each frame.
	var roots: Array = [[Vector2(24, 40), Vector2(16, 44), Vector2(10, 46), Vector2(4, 44)], [Vector2(29, 43), Vector2(27, 47), Vector2(25, 54)],
		[Vector2(36, 43), Vector2(40, 48), Vector2(46, 52), Vector2(54, 50)], [Vector2(44, 40), Vector2(52, 42), Vector2(57, 41), Vector2(62, 42)]]
	var reach: float = [0.45, 0.85, 1.0][k]
	for r: Array in roots:
		var total := 0.0
		for i in r.size() - 1:
			total += (r[i] as Vector2).distance_to(r[i + 1])
		var left := total * reach
		for i in r.size() - 1:
			var a: Vector2 = r[i]
			var b: Vector2 = r[i + 1]
			var seg := a.distance_to(b)
			var t := minf(1.0, left / seg)
			if t <= 0.0:
				break
			_line(canvas, [a, a.lerp(b, t)], gold if k < 2 else GLOW_OUTER)
			_line(canvas, [a + Vector2(0, -1), a.lerp(b, t) + Vector2(0, -1)], core if k == 0 else gold)
			left -= seg
		# The lit tile flaring at the root's end.
		if k >= 1:
			var end: Vector2 = r[r.size() - 1]
			var arm: int = 4 if k == 1 else 2
			for i in range(-arm, arm + 1):
				_px(canvas, int(end.x) + i, int(end.y), core if absi(i) < 2 else gold)
				_px(canvas, int(end.x), int(end.y) + i / 2, core if absi(i) < 2 else gold)
			_warm_glow(canvas, end, Vector2(6, 4) * (1.3 if big else 1.0), k)
	_ring(canvas, Vector2(31.5, 45), Vector2(18 + k * 7, 6 + k * 2) * (1.2 if big else 1.0), GLOW_INNER, k == 2)


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


# --- Branch expansion, Sporeling (tower_design.md "Branch expansion", 2026-10-02) ----------------
# Lichenling -> Old Lichen (a crust of flat lichen plates, a broad flat cap), Brood Cap -> Hatchery
# (a cap with tiny spore-sprites clinging to it), Inkcap -> Deliquescent (a tall dripping ink cap).

const LICHEN := ["#5c944c", "#9cc46c", "#d4ec9c"]
# Ink in the Ink ramp (never the nightmare ramp: a Warden must never read as a nightmare).
const INK := ["#24243c", "#3c3c5c", "#5c5a78"]

func _spore_fig() -> Dictionary:
	return _pal("#17174d", "#ed9df2", "#de73e5", "#ba41d9")

# A flat lichen plate: a little uneven disc, lit on top, a darker rim.
func _lichen_plate(canvas: Image, c: Vector2, r: float, o: Color, mask: Image = null) -> void:
	var layer := _layer()
	_ellipse(layer, c, Vector2(r, r * 0.6), _ramp(LICHEN))
	if mask != null:
		for y in range(-OY, S):
			for x in S:
				if _gp(layer, x, y).a > 0.0 and _gp(mask, x, y).a == 0.0:
					_sp(layer, x, y, Color(0, 0, 0, 0))
	_stamp(canvas, layer, o)

# A broad, flat shelf cap (one tier, or two for Old Lichen) with lichen frills along its rim.
func _shelf_cap(canvas: Image, c: Vector2, w: float, o: Color, tiers: int) -> void:
	for t in tiers:
		var cc := c + Vector2(0, -t * 4.0)
		var ww := w - t * 5.0
		var cap := _layer()
		_ellipse(cap, cc, Vector2(ww, 3.2), _ramp(["#7a8a5a", "#a8b880", "#d4e0b0"]))
		_stamp(canvas, cap, o)
		var x := cc.x - ww + 2.0
		while x < cc.x + ww - 1.0:
			_px(canvas, int(x), int(cc.y) + 2, Color(LICHEN[1]))
			x += 3.0

func _draw_lichenling(canvas: Image, st: Dictionary) -> void:
	_lichen_body(canvas, st, false)

func _draw_old_lichen(canvas: Image, st: Dictionary) -> void:
	_lichen_body(canvas, st, true)

func _lichen_body(canvas: Image, st: Dictionary, old: bool) -> void:
	# Lichen shelves jut out sideways from its shoulders and arms like bracket fungus (no other
	# Sporeling branch has a sideways outline), a broad flat shelf cap; Old Lichen is crusted all over,
	# more and bigger shelves, a two-tier cap and long lichen beards.
	var dy: int = st.dy
	var fig := _spore_fig()
	_draw_waystone(canvas, st, "fairy_ring", old)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	for p: Vector3 in [Vector3(25, 27, 2.6), Vector3(35, 33, 2.4), Vector3(29, 38, 2.2)]:
		_lichen_plate(canvas, Vector2(p.x, p.y + (dy if p.y < 30 else 0)), p.z, fig.o, mask)
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), true)
	# The shelves: flat half-discs sticking out past the body's edge, in steps down each side.
	var shelves: Array = [Vector4(13, 20, 7, -1), Vector4(48, 21, 7, 1), Vector4(11, 30, 6, -1), Vector4(51, 31, 6, 1)]
	if old:
		shelves.append_array([Vector4(9, 25, 8, -1), Vector4(54, 26, 8, 1), Vector4(14, 37, 5, -1), Vector4(49, 38, 5, 1)])
	for s: Vector4 in shelves:
		_bracket(canvas, Vector2(s.x, s.y + (dy if s.y < 30 else 0)), s.z, fig.o)
	_shelf_cap(canvas, Vector2(30.5, 5 + dy), 22.0 if old else 18.0, fig.o, 2 if old else 1)
	if old:
		for x in [12, 17, 44, 49]:
			for i in 7 + x % 4:
				_px(canvas, x, 8 + dy + i, Color(LICHEN[1]) if i % 2 == 0 else Color(LICHEN[0]))
		for p: Vector3 in [Vector3(10, 45, 3.0), Vector3(54, 44, 2.6)]:
			_lichen_plate(canvas, Vector2(p.x, p.y), p.z, fig.o)
	_motes(canvas, st, [16, 46], 18, 12, [Color(LICHEN[2]), Color("#de73e5")])

func _attack_lichenling(canvas: Image, st: Dictionary) -> void:
	_blow(canvas, st, Color("#ed9df2"), Color("#17174d"), Color(LICHEN[2]))
	_burst(canvas, Vector2(ATTACKS["lichenling"].point), st.attack, Color(LICHEN[2]), Color(LICHEN[0]), Color("#17174d"))

func _attack_old_lichen(canvas: Image, st: Dictionary) -> void:
	_blow(canvas, st, Color("#ed9df2"), Color("#17174d"), Color(LICHEN[2]))
	_burst(canvas, Vector2(ATTACKS["old_lichen"].point), st.attack, Color(LICHEN[2]), Color(LICHEN[0]), Color("#17174d"))
	if st.attack == RELEASE_FRAME + 1:
		for p: Vector2i in [Vector2i(10, 4), Vector2i(52, 3)]:
			_sparkle(canvas, p, Color(LICHEN[2]))

# A tiny spore-sprite: a round pink body, two dot eyes, stubby legs (Brood Cap's brood).
func _spore_sprite(canvas: Image, p: Vector2, o: Color, f: int, big: bool = false) -> void:
	# A baby mushroom: a pink spotted cap over a little cream body with two eyes, tiny feet stepping.
	var z: float = 1.5 if big else 1.0
	var layer := _layer()
	_ellipse(layer, p + Vector2(0, 1.2 * z), Vector2(1.9, 1.7) * z, _ramp(["#bca48c", "#dccdb2", "#fff4dc"]))
	_ellipse(layer, p + Vector2(0, -0.8 * z), Vector2(3.2, 2.2) * z, _ramp(["#bc44dc", "#ec9cf4", "#ec9cf4", "#fff4dc"]), p.y + 0.2 * z)
	_stamp(canvas, layer, o)
	_px(canvas, int(p.x), int(p.y - 1.6 * z), Color("#fff4dc"))  # a spot on its cap
	_px(canvas, int(p.x) - 1, int(p.y + 1.2 * z), o)
	_px(canvas, int(p.x) + 1, int(p.y + 1.2 * z), o)
	var leg := 1 if f % 2 == 0 else 0
	_px(canvas, int(p.x) - 1 - leg, int(p.y + 3.2 * z), o)
	_px(canvas, int(p.x) + 1 + leg, int(p.y + 3.2 * z), o)


# Brood Cap's walking spore-sprite, drawn natively at `z` (1.0 = the 24x24 projectile sheet's size: a
# baby mushroom about 16 px wide): a wide spotted cap that reads from every side, a little cream body
# looking right, two stepping feet, and a warm rim round the whole shape so it shows on light and dark
# paths alike.
func _spore_walker(canvas: Image, p: Vector2, o: Color, f: int, z: float = 1.0, rim: bool = true) -> void:
	var target := canvas
	canvas = _layer()  # drawn on its own, so the rim goes round the sprite only
	var step: float = [1.0, 0.0, -1.0, 0.0][f % 4]
	var layer := _layer()
	for s: float in [-1.0, 1.0]:
		_ellipse(layer, p + Vector2(s * 2.6 + step * s * 0.8, 6.6) * z, Vector2(1.8, 1.2) * z, _ramp(["#bca48c", "#dccdb2", "#dccdb2"]))
	_ellipse(layer, p + Vector2(0.5, 2.6) * z, Vector2(4.6, 3.8) * z, _ramp(["#bca48c", "#dccdb2", "#fff4dc"]))
	_ellipse(layer, p + Vector2(0, -3.0) * z, Vector2(7.6, 4.4) * z, _ramp(["#bc44dc", "#ec9cf4", "#ec9cf4", "#fff4dc"]), p.y - 0.4 * z)
	_stamp(canvas, layer, o)
	for e: float in [-0.6, 2.4]:  # eyes, looking right
		_px(canvas, roundi(p.x + e * z), roundi(p.y + 1.6 * z), o)
		_px(canvas, roundi(p.x + e * z), roundi(p.y + 2.6 * z), o)
	for s: Vector2 in [Vector2(-4, -5), Vector2(-3, -5), Vector2(2, -6), Vector2(3, -6), Vector2(5, -3)]:  # spots
		_px(canvas, roundi(p.x + s.x * z), roundi(p.y + s.y * z), Color("#fff4dc"))
	if rim:
		_warm_rim(canvas, Color("#fcd47c", 0.75))
	for y in range(-OY, S):
		for x in S:
			var c := _gp(canvas, x, y)
			if c.a > 0.0:
				_sp(target, x, y, _gp(target, x, y).blend(c))

# A 1 px rim of `col` round everything drawn on the canvas (the empty pixels touching it).
func _warm_rim(canvas: Image, col: Color) -> void:
	var src := canvas.duplicate()
	for y in range(-OY, S):
		for x in S:
			if _gp(src, x, y).a > 0.0:
				continue
			for n: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q := Vector2i(x, y) + n
				if q.x >= 0 and q.y >= -OY and q.x < S and q.y < S and _gpv(src, q).a > 0.9:
					_sp(canvas, x, y, col)
					break

func _draw_brood_cap(canvas: Image, st: Dictionary) -> void:
	_brood_body(canvas, st, false)

func _draw_hatchery(canvas: Image, st: Dictionary) -> void:
	_brood_body(canvas, st, true)

func _brood_body(canvas: Image, st: Dictionary, hive: bool) -> void:
	# A big round brood cap with its spore-sprites riding on top and clinging to the shoulders (a
	# bumpy outline); Hatchery's cap is a ribbed hive dome and egg piles rise either side of the slab.
	var dy: int = st.dy
	var fig := _spore_fig()
	_draw_waystone(canvas, st, "fairy_ring", hive)
	if hive:
		for e: Vector3 in [Vector3(9, 40, 4.2), Vector3(14, 43, 3.6), Vector3(7, 45, 3.2), Vector3(11, 35, 3.2),
				Vector3(54, 39, 4.0), Vector3(50, 43, 3.4), Vector3(57, 44, 3.0), Vector3(53, 34, 3.0)]:
			var egg := _layer()
			_ellipse(egg, Vector2(e.x, e.y), Vector2(e.z, e.z * 0.9), _ramp(["#c8a8e0", "#f0dcff", "#fff4fc"]))
			_stamp(canvas, egg, fig.o)
			_px(canvas, int(e.x), int(e.y), Color("#ba41d9"))
	_draw_template_figure(canvas, st.pose, fig)
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), false)
	var cap := _layer()
	_ellipse(cap, Vector2(30.5, 8 + dy), Vector2(19.0 if hive else 17.0, 9.0 if hive else 8.0), _ramp(["#8a3aa0", "#c060d0", "#e898f0", "#ffd0ff"]), 10.0 + dy)
	if hive:
		for y in range(-OY, S):
			for x in S:
				if _gp(cap, x, y).a > 0.0 and absi((x - 30) % 5) == 0:
					_sp(cap, x, y, Color("#8a3aa0"))  # its ribs
	_stamp(canvas, cap, fig.o)
	var spots: Array = [Vector2(14, 9), Vector2(47, 9), Vector2(15, 19), Vector2(46, 19), Vector2(30, -1)]  # on the cap rim and shoulders
	if hive:
		spots.append_array([Vector2(13, 28), Vector2(48, 28), Vector2(22, 0), Vector2(39, 0)])  # down the arms, up the dome
	for i in spots.size():
		var p: Vector2 = spots[i] + Vector2(0, dy + (1 if (st.f + i) % 4 == 0 else 0) + 3)
		_spore_sprite(canvas, p, fig.o, st.f + i, true)

func _attack_brood_cap(canvas: Image, st: Dictionary) -> void:
	_brood_release(canvas, st, "brood_cap")

func _attack_hatchery(canvas: Image, st: Dictionary) -> void:
	_brood_release(canvas, st, "hatchery")

# The throw: a sprite gathers on the cap rim in a warm glow (wind-up), then the cap puffs it out in a
# high arc off the slab's front corner, towards the path, a trail of spores behind it; it lands with a
# little ring. Hatchery's sprite is bigger.
const BROOD_ARC := [Vector2(0, 0), Vector2(1, -3), Vector2(6, -8), Vector2(11, -4), Vector2(13, 12), Vector2(12, 31)]

func _brood_release(canvas: Image, st: Dictionary, key: String) -> void:
	var a: int = st.attack
	var start := Vector2(ATTACKS[key].point) + Vector2(0, st.dy)
	var z := 0.95 if key == "hatchery" else 0.8
	var o := Color("#17174d")
	var p: Vector2 = start + BROOD_ARC[a]
	if a < RELEASE_FRAME:
		_warm_glow(canvas, p, Vector2(7, 6), 1 - a)  # gathering on the rim
	elif a == RELEASE_FRAME:
		for c: Vector3 in [Vector3(-3, 1, 3.2), Vector3(1, 3, 2.6), Vector3(-1, -2, 2.4)]:  # the cap's puff
			var puff := _layer()
			_flat_ellipse(puff, start + Vector2(c.x, c.y), Vector2(c.z, c.z * 0.8), Color("#f7c8fa"))
			_stamp(canvas, puff, Color("#ba41d9"))
	for k in range(RELEASE_FRAME, a):  # spores trailing behind along the arc
		var q: Vector2 = start + (BROOD_ARC[k] as Vector2).lerp(BROOD_ARC[k + 1], 0.35)
		_px(canvas, roundi(q.x), roundi(q.y), Color("#ec9cf4"))
		_px(canvas, roundi(q.x) + 1, roundi(q.y) - 1, Color("#fff4dc") if k == a - 1 else Color("#bc44dc"))
	if a == ATTACK_FRAMES - 1:  # landed: a little ring on the ground
		_ring(canvas, p + Vector2(0, 6 * z), Vector2(9, 3), Color("#ec9cf4"), true)
	_spore_walker(canvas, p, o, a, z, a >= RELEASE_FRAME)

func _draw_inkcap(canvas: Image, st: Dictionary) -> void:
	_ink_body(canvas, st, false)

func _draw_deliquescent(canvas: Image, st: Dictionary) -> void:
	_ink_body(canvas, st, true)

func _ink_body(canvas: Image, st: Dictionary, melt: bool) -> void:
	# A long inky bell cap hanging down round its face like a hood, ink dripping from its ragged hem
	# (a tall narrow dark shape, unlike the wide domes of the other branches); Deliquescent's cap has
	# melted wider, runnels down its sides into a wide ink pool on the slab.
	var dy: int = st.dy
	var fig := _spore_fig()
	_draw_waystone(canvas, st, "fairy_ring", melt)
	if melt:
		var pool := _layer()
		_flat_ellipse(pool, Vector2(31, 47), Vector2(23, 4.5), Color(INK[1]))
		_stamp(canvas, pool, Color(INK[0]))
		for p: Vector2i in [Vector2i(14, 46), Vector2i(26, 48), Vector2i(41, 46), Vector2i(50, 47)]:
			_px(canvas, p.x, p.y, Color(INK[2]))
	_draw_template_figure(canvas, st.pose, fig)
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), true)
	var w: float = 15.0 if melt else 12.0
	var hem: float = 25.0 if melt else 23.0
	var top := Vector2(30.5, 0 + dy)
	var cap := _layer()
	_flat_polygon(cap, PackedVector2Array([top + Vector2(-2, 0), top + Vector2(2, 0), top + Vector2(w - 3, 7), top + Vector2(w, hem),
		top + Vector2(w - 6, hem - 2), top + Vector2(w - 7, 10), top + Vector2(-w + 7, 10), top + Vector2(-w + 6, hem - 2), top + Vector2(-w, hem)]), Color(INK[1]))
	for y in range(-OY, S):
		for x in S:
			if _gp(cap, x, y).a > 0.0 and x < 30 - (y - top.y) * 0.3:
				_sp(cap, x, y, Color(INK[2]))
	_stamp(canvas, cap, Color(INK[0]))
	for i in 4:
		_px(canvas, 26 + i * 2, int(top.y) + 2 + i, Color("#dce8f4"))  # a sheen down it
	if melt:
		# Its hem has melted into two thick streams running down to the pool.
		var streams := _layer()
		for side: int in [-1, 1]:
			var x0: float = 30.5 + side * (w - 1.0)
			_stroke(streams, [Vector2(x0, hem + dy), Vector2(x0 + side * 2.0, hem + 10 + dy), Vector2(x0 + side * 3.0, 44)], 1.3, Color(INK[1]))
		_stamp(canvas, streams, Color(INK[0]))
	# Drips off the hem, longer on Deliquescent.
	for i in 4:
		var d := Vector2([20.5, 23.5, 37.5, 40.5][i] + (-2.0 if i < 2 else 2.0) * (w - 10.0) * 0.5, hem + dy + 1)
		var len: int = (3 + (st.f + i * 3) % 5) if not melt else (8 + (st.f + i * 2) % 10)
		for j in len:
			_px(canvas, int(d.x), int(d.y) + j, Color(INK[1]) if j < len - 1 else Color(INK[0]))

func _attack_inkcap(canvas: Image, st: Dictionary) -> void:
	# It flings ink from its cap: a dark splash at the cap's tip, drops arcing out and falling.
	var k: int = st.attack - RELEASE_FRAME
	var c := Vector2(ATTACKS["inkcap"].point)
	_burst(canvas, c, st.attack, Color("#5c5a78"), Color(INK[0]), Color(INK[0]))
	if k < 0 or k > 2:
		return
	for i in 7:
		var a: float = -PI * 0.85 + i * 0.28
		var d := Vector2.from_angle(a)
		var p := c + d * (6.0 + k * 5.0) + Vector2(0, k * k * 1.5)
		var drop := _layer()
		_flat_ellipse(drop, p, Vector2(1.9, 1.9), Color(INK[1]))
		_stamp(canvas, drop, Color(INK[0]))
		_px(canvas, roundi(p.x), roundi(p.y) - 1, Color("#dce8f4"))


func _attack_deliquescent(canvas: Image, st: Dictionary) -> void:
	_burst(canvas, Vector2(ATTACKS["deliquescent"].point), st.attack, Color("#dce8f4"), Color(INK[1]), Color(INK[0]))
	if st.attack == RELEASE_FRAME + 1:
		var pool := _layer()
		_flat_ellipse(pool, Vector2(31, 48), Vector2(24, 4.5), Color(INK[2]))
		_stamp(canvas, pool)

# Projectiles: a spinning lichen flake (Lichenling), a falling ink drop (Inkcap), and the brood's
# walking spore-sprite (Brood Cap: 4 walk frames, drawn walking right).
func _proj_lichen_flake(canvas: Image, f: int) -> void:
	var a := f * TAU / 8.0
	var layer := _layer()
	var pts := PackedVector2Array()
	for k in 7:
		var r := 5.0 if k % 2 == 0 else 3.8
		pts.append(Vector2(32, 32) + Vector2(cos(a + k * TAU / 7.0) * r, sin(a + k * TAU / 7.0) * r * 0.6))
	_flat_polygon(layer, pts, Color(LICHEN[1]))
	_stamp(canvas, layer, Color("#1e3a1a"))
	_px(canvas, 31, 31, Color(LICHEN[2]))
	_px(canvas, 33, 32, Color(LICHEN[0]))
	for k in 3:
		_px_under(canvas, 25 - k * 2, 32 + (k + f) % 2, Color(LICHEN[2], 0.8 - k * 0.2))

func _proj_ink_drop(canvas: Image, f: int) -> void:
	var layer := _layer()
	for step in 14:
		var t := step / 13.0
		var rr := 4.2 * pow(1.0 - t, 1.2)
		if rr >= 0.5:
			_flat_ellipse(layer, Vector2(35 - t * 11, 32), Vector2(rr, rr), Color(INK[1]))
	_stamp(canvas, layer, Color(INK[0]))
	_px(canvas, 36, 30, Color("#dce8f4"))
	_px(canvas, 37, 31, Color(INK[2]))
	for k in 2:
		_px_under(canvas, 22 - k * 3, 33 + (k + f) % 2, Color(INK[1], 0.7))

func _proj_spore_sprite(canvas: Image, f: int) -> void:
	var bob: float = [0.0, -1.0, 0.0, -1.0][f]
	_spore_walker(canvas, Vector2(32, 32 + bob), Color("#17174d"), f)


# --- Branch expansion, Dewdrop -----------------------------------------------------------------
# Cloudlet -> Nimbus (a cloud floating beside it; Nimbus wears a cloud mantle round its shoulders,
# unlike Monsoon's cloud overhead), Undercurrent -> Maelstrom (a swirl of water round its feet; a
# whirlpool filling the slab), Jetreed -> Torrent (a reed pipe held like a hose; a bundle of reeds
# with a jet arcing out).

const CLOUD_RAMP := ["#6a7aa0", "#9aaac8", "#c8d4e8", "#f0f4fc"]

func _dew_body(canvas: Image, st: Dictionary, lush: bool) -> Dictionary:
	var fig := _pal(WATER[0], WATER[1], WATER[2], WATER[3])
	_draw_waystone(canvas, st, "pond", lush)
	_droplet_tip(canvas, st, fig)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	_water_gloss(canvas, mask, st, fig)
	_golem_face(canvas, st, fig)
	return fig

# A small fluffy cloud (lumps on a flat underside), drizzling a few drops.
func _puffy_cloud(canvas: Image, c: Vector2, w: float, o: Color, f: int, drizzle: int) -> void:
	var cl := _layer()
	_ellipse(cl, c, Vector2(w, w * 0.45), _ramp(CLOUD_RAMP))
	_ellipse(cl, c + Vector2(-w * 0.45, w * 0.1), Vector2(w * 0.5, w * 0.38), _ramp(CLOUD_RAMP))
	_ellipse(cl, c + Vector2(w * 0.4, w * 0.12), Vector2(w * 0.55, w * 0.36), _ramp(CLOUD_RAMP))
	_stamp(canvas, cl, o)
	for k in drizzle:
		var x := int(c.x - w * 0.6 + k * (w * 1.2 / maxf(drizzle - 1, 1)))
		var y := int(c.y + w * 0.5) + 1 + (f + k * 2) % 5
		_px(canvas, x, y, Color("#9ad4ff"))
		_px(canvas, x, y + 1, Color("#5aa8ec"))

func _draw_cloudlet(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _dew_body(canvas, st, false)
	var bob: float = [0.0, -1.0, -1.0, 0.0, 0.0, 1.0, 1.0, 0.0][st.f % 8]
	_puffy_cloud(canvas, Vector2(12, 8 + bob), 11.0, fig.o, st.f, 4)

func _draw_nimbus(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _dew_body(canvas, st, true)
	# A cloud mantle draped round its shoulders, wider than its body, rain beading off it.
	var mantle := _layer()
	for c: Vector3 in [Vector3(14, 21, 6.5), Vector3(22, 19, 6.0), Vector3(30.5, 20, 6.0), Vector3(39, 19, 6.0), Vector3(47, 21, 6.5), Vector3(9, 26, 4.5), Vector3(52, 26, 4.5)]:
		_ellipse(mantle, Vector2(c.x, c.y + dy), Vector2(c.z, c.z * 0.7), _ramp(CLOUD_RAMP))
	_stamp(canvas, mantle, fig.o)
	for k in 5:
		var x := 9 + k * 11
		_px(canvas, x, 28 + dy + (st.f + k * 3) % 6, Color("#9ad4ff"))
	var bob: float = [0.0, -1.0, -1.0, 0.0, 0.0, 1.0, 1.0, 0.0][st.f % 8]
	_puffy_cloud(canvas, Vector2(52, 6 + bob), 7.0, fig.o, st.f, 3)

func _attack_cloudlet(canvas: Image, st: Dictionary) -> void:
	_cloud_rain_attack(canvas, st, "cloudlet")

func _attack_nimbus(canvas: Image, st: Dictionary) -> void:
	_cloud_rain_attack(canvas, st, "nimbus")

# The cloud darkens and lets go a burst of rain on release.
func _cloud_rain_attack(canvas: Image, st: Dictionary, key: String) -> void:
	# The cloud darkens and lets go: a flash of lightning on release, then a heavy curtain of rain
	# falling out of it, splashing on the slab.
	var k: int = st.attack - RELEASE_FRAME
	var c := Vector2(ATTACKS[key].point)
	if k < 0 or k > 2:
		return
	_fog(canvas, c + Vector2(0, -1), Vector2(10, 4), Color("#5c5a78", 0.6), st.f)
	for i in 9:
		var x := int(c.x) - 8 + i * 2
		for j in 4:
			var y := int(c.y) + 5 + k * 4 + j * 3 + i % 2
			_px(canvas, x - j / 2, y, Color("#e8faff") if j == 0 else Color("#9ad4ff"))
			_px(canvas, x - j / 2, y + 1, Color("#5aa8ec"))
	if k == 0:
		_bolt(canvas, c + Vector2(-1, 3), c + Vector2(-5, 16), Color("#fff4dc"), Color("#9ad4ff"), 3)
		_warm_glow(canvas, c, Vector2(10, 6))
	if k == 2:
		for i in 4:
			_px(canvas, int(c.x) - 7 + i * 5, int(c.y) + 28, Color("#e8faff"))


# A swirl of water round its feet (a ring of foam turning); Maelstrom's fills the slab, spray rising.
func _swirl(canvas: Image, st: Dictionary, r: Vector2, arms: int, spray: bool) -> void:
	# A whirlpool round its feet: dark water, rings of lighter water, thick white foam arms turning in.
	var c := Vector2(31, 44)
	var water := _layer()
	_flat_ellipse(water, c, r, Color("#3a78c8"))
	_flat_ellipse(water, c, r * 0.7, Color("#5aa8ec"))
	_flat_ellipse(water, c, r * 0.35, Color("#16305e"))
	_stamp(canvas, water, Color("#16305e"))
	for a in arms:
		for s in 22:
			var t := s / 21.0
			var ang: float = a * TAU / arms + t * PI * 1.4 + st.f * TAU / 16.0
			var p := c + Vector2(cos(ang) * r.x * (0.25 + t * 0.72), sin(ang) * r.y * (0.25 + t * 0.72))
			_px(canvas, int(p.x), int(p.y), Color("#e8faff"))
			_px(canvas, int(p.x) + 1, int(p.y), Color("#e8faff") if s % 3 != 0 else Color("#9ad4ff"))
	if spray:
		for k in 6:
			var ang: float = k * TAU / 6.0 + st.f * 0.4
			var p := c + Vector2(cos(ang) * r.x, sin(ang) * r.y - 3 - (st.f + k) % 3)
			_px(canvas, int(p.x), int(p.y), Color("#e8faff"))


func _draw_undercurrent(canvas: Image, st: Dictionary) -> void:
	var fig := _pal(WATER[0], WATER[1], WATER[2], WATER[3])
	_draw_waystone(canvas, st, "pond")
	_swirl(canvas, st, Vector2(27, 8.5), 3, false)
	_droplet_tip(canvas, st, fig)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	_water_gloss(canvas, mask, st, fig)
	_golem_face(canvas, st, fig)
	# A ring of water whirling round its feet, raised off the slab, cresting into a wave at each side
	# (its outline spreads wide at the bottom, unlike Dewdrop's).
	var ring := _layer()
	var pts: Array = []
	for s in 25:
		var a: float = PI * (s / 24.0)
		pts.append(Vector2(31 + cos(a) * 26.0, 41 + sin(a) * 5.0))
	_stroke(ring, pts, 1.8, Color("#5aa8ec"))
	for side: int in [-1, 1]:
		var base := Vector2(31 + side * 26.0, 41)
		_stroke(ring, [base, base + Vector2(side * 1.0, -6), base + Vector2(-side * 2.5, -9)], 1.6, Color("#9ad4ff"))
	_stamp(canvas, ring, fig.o)
	for s in range(0, 25, 3):
		var p: Vector2 = pts[(s + st.f) % 25]
		_px(canvas, int(p.x), int(p.y) - 1, Color("#e8faff"))  # foam running round it

func _draw_maelstrom(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _pal(WATER[0], WATER[1], WATER[2], WATER[3])
	_draw_waystone(canvas, st, "pond", true)
	_swirl(canvas, st, Vector2(28, 8), 4, true)
	_droplet_tip(canvas, st, fig)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	_water_gloss(canvas, mask, st, fig)
	_golem_face(canvas, st, fig)
	# Water spiralling up round its body in a ribbon, out past its sides.
	var ribbon := _layer()
	var pts: Array = []
	for s in 20:
		var t := s / 19.0
		var ang: float = t * TAU * 1.5 + st.f * TAU / 16.0
		pts.append(Vector2(31 + cos(ang) * (20.0 - t * 6.0), 40 - t * 26.0 + sin(ang) * 3.0 + (dy if t > 0.5 else 0)))
	_stroke(ribbon, pts, 2.0, Color("#9ad4ff"))
	_stamp(canvas, ribbon, fig.o)

func _attack_undercurrent(canvas: Image, st: Dictionary) -> void:
	_whirl_pulse(canvas, st, 1.0)

func _attack_maelstrom(canvas: Image, st: Dictionary) -> void:
	_whirl_pulse(canvas, st, 1.4)

# Rings of water drawn in towards the middle on release (it gathers, it doesn't push).
func _whirl_pulse(canvas: Image, st: Dictionary, size: float) -> void:
	# The pull: a thick white ring of water drawn in towards it, spray leaping up off the whirlpool.
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	var c := Vector2(31, 44)
	var r := Vector2(29, 9) * size * (1.0 - k * 0.28)
	for s in 48:
		var ang := s * TAU / 48.0
		var p := c + Vector2(cos(ang) * r.x, sin(ang) * r.y)
		var inward := (c - p).normalized()
		_px(canvas, roundi(p.x), roundi(p.y), Color("#e8faff"))
		_px(canvas, roundi(p.x + inward.x * 1.5), roundi(p.y + inward.y * 1.5), Color("#9ad4ff"))
		if s % 6 == k:
			_px(canvas, roundi(p.x + inward.x * 4), roundi(p.y + inward.y * 4), Color("#e8faff"))
	for i in 6:
		var a := i * TAU / 6.0 + k
		var p := c + Vector2(cos(a) * 20.0 * size, sin(a) * 6.0) + Vector2(0, -3 - k * 3 - (i % 2) * 2)
		_px(canvas, roundi(p.x), roundi(p.y), Color("#e8faff"))
		_px(canvas, roundi(p.x), roundi(p.y) + 1, Color("#9ad4ff"))


# A green reed pipe, banded, held out like a hose (from the hand, pointing ahead and up).
func _reed(canvas: Image, a: Vector2, b: Vector2, o: Color) -> void:
	var reed := _layer()
	_stroke(reed, [a, b], 2.0, Color(LEAF[1]))
	_flat_ellipse(reed, b, Vector2(2.6, 2.6), Color(LEAF[1]))  # its flared nozzle
	_stamp(canvas, reed, o)
	var d := (b - a)
	for i in range(2, int(d.length()), 4):
		var p := a + d.normalized() * i
		_px(canvas, int(p.x), int(p.y), Color(LEAF[0]))
	_px(canvas, int(b.x), int(b.y), Color("#9ad4ff"))

func _draw_jetreed(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _dew_body(canvas, st, false)
	_reed(canvas, Vector2(43, 30), Vector2(60, 20 + dy), fig.o)
	if st.f % 4 == 1:
		_px(canvas, 61, 19 + dy, Color("#9ad4ff"))  # a drip at the nozzle

func _draw_torrent(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _dew_body(canvas, st, true)
	# A great bamboo water cannon under its arm, banded with nodes, a jet always running out of it.
	var cannon := _layer()
	_stroke(cannon, [Vector2(40, 33), Vector2(60, 19 + dy)], 2.6, Color("#9cc46c"))
	_stamp(canvas, cannon, fig.o)
	var d := (Vector2(60, 19 + dy) - Vector2(40, 33)).normalized()
	for i in range(4, 22, 6):
		var p := Vector2(40, 33) + d * i
		var n := d.orthogonal()
		_line(canvas, [p - n * 2.0, p + n * 2.0], Color("#34643c"))
	var mouth := _layer()
	_flat_ellipse(mouth, Vector2(60.5, 18.5 + dy), Vector2(1.6, 1.6), Color("#2c4c5c"))
	_stamp(canvas, mouth)
	for s in 7:
		var t := s / 6.0
		var p := Vector2(62 + t * 2.0, 17 + dy + t * t * 12.0 + (st.f % 2))
		_px(canvas, int(p.x), int(p.y), Color("#9ad4ff") if s % 2 == 0 else Color("#e8faff"))
		_px(canvas, int(p.x) - 1, int(p.y), Color("#5aa8ec"))


func _attack_jetreed(canvas: Image, st: Dictionary) -> void:
	_jet_attack(canvas, st, "jetreed", 2)

func _attack_torrent(canvas: Image, st: Dictionary) -> void:
	_jet_attack(canvas, st, "torrent", 3)

# A straight jet of water out of the reed's tip on release (the line pierces).
func _jet_attack(canvas: Image, st: Dictionary, key: String, width: int) -> void:
	# A thick jet of water blasting out of the reed / cannon (it pierces a line), a spray burst at the
	# mouth, the jet thinning to spray as it ends.
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	var from := Vector2(ATTACKS[key].point)
	var dir := Vector2(1, -0.55).normalized()
	var n := dir.orthogonal()
	var w: float = (width + 1.5) * (1.0 - k * 0.3)
	for i in 26:
		var p := from + dir * i
		for j in range(-int(w), int(w) + 1):
			if k == 2 and (i + j) % 2 == 0:
				continue
			var q := p + n * j
			_px(canvas, roundi(q.x), roundi(q.y), Color("#e8faff") if absi(j) < 1 else (Color("#9ad4ff") if absi(j) < w - 0.5 else Color("#3a78c8")))
	# The splash where the jet leaves (the jet runs off past the frame, so the mouth carries the beat).
	var splash := _layer()
	for i in 7:
		var a: float = PI * 0.55 + i * PI * 0.22 + k * 0.3
		_flat_ellipse(splash, from + Vector2(cos(a), sin(a)) * (4.0 + k * 3.0), Vector2(1.6, 1.6) * (1.0 - k * 0.25), Color("#9ad4ff"))
	_flat_ellipse(splash, from, Vector2(3.5, 3.5) * (1.0 - k * 0.3), Color("#e8faff"))
	_stamp(canvas, splash, Color("#16305e"))
	_warm_glow(canvas, from, Vector2(6, 5), k)



# --- Branch expansion, Firefly Jar -------------------------------------------------------------
# Jarlink -> Lightning Fence (a jar on a tall pole with a wire coil; two coiled poles with an arc
# between them), Prism Jar -> Rainbow Prism (a faceted crystal for a cork; a crystal crown, shoulder
# crystals and three coloured beams), Sparkler -> Starburst (a fizzing sparkler held up; one in each
# hand and a starburst above). All drawn over the Firefly Jar's body.

const PRISM := ["#4c8ca4", "#9cd4fc", "#dce8f4", "#ffffff"]
const COPPER := Color("#b8662c")

# A tall pole planted on the slab, a copper wire coiled round it, a little jar of light on top.
func _coil_pole(canvas: Image, x: float, top: float, st: Dictionary, o: Color) -> void:
	var pole := _layer()
	_stroke(pole, [Vector2(x, 46), Vector2(x, top + 6)], 1.5, Color("#5c3c24"))
	_stamp(canvas, pole, o)
	for y in range(int(top) + 9, 42, 3):
		_px(canvas, int(x) - 2, y, COPPER)
		_px(canvas, int(x) + 2, y + 1, COPPER)
		_px(canvas, int(x), y + 2, COPPER)
	var jar := _layer()
	_round_rect(jar, Rect2i(int(x) - 4, int(top), 9, 8), 2, Color("#4e7482"))
	_stamp(canvas, jar, o)
	_round_rect(canvas, Rect2i(int(x) - 3, int(top) - 2, 7, 2), 0, Color("#8a5a3a"))  # its cork
	_glow_dot(canvas, Vector2i(int(x), int(top) + 3), Color("#fff27a") if st.f % 4 < 2 else Color("#ffe8a0"), Color("#a8c868"))

func _draw_jarlink(canvas: Image, st: Dictionary) -> void:
	_draw_firefly_jar(canvas, st)
	_coil_pole(canvas, 8, 6, st, Color("#1a2230"))

func _draw_lightning_fence(canvas: Image, st: Dictionary) -> void:
	_draw_firefly_jar(canvas, st)
	_coil_pole(canvas, 7, 4, st, Color("#1a2230"))
	_coil_pole(canvas, 56, 4, st, Color("#1a2230"))
	# The arc between the two jars, crackling over its head (a different path each frame).
	if st.f % 2 == 0 or st.attack >= 0:
		_bolt(canvas, Vector2(10, 7), Vector2(53, 7), Color("#fff6a0"), Color("#8a8af0"), 6)

func _attack_jarlink(canvas: Image, st: Dictionary) -> void:
	_attack_firefly_jar(canvas, st)
	_jar_arc_flash(canvas, st, Vector2(8, 9))

func _attack_lightning_fence(canvas: Image, st: Dictionary) -> void:
	_attack_firefly_jar(canvas, st)
	_jar_arc_flash(canvas, st, Vector2(7, 7))
	_jar_arc_flash(canvas, st, Vector2(56, 7))

func _jar_arc_flash(canvas: Image, st: Dictionary, p: Vector2) -> void:
	if st.attack == RELEASE_FRAME:
		_sparkle(canvas, Vector2i(p), Color.WHITE)
		_warm_glow(canvas, p, Vector2(6, 6))

# A faceted crystal: a hexagonal gem, light facets on the upper left, rainbow glints.
func _faceted_crystal(canvas: Image, c: Vector2, w: float, h: float, o: Color, f: int) -> void:
	var gem := _layer()
	var pts := PackedVector2Array([c + Vector2(0, -h), c + Vector2(w, -h * 0.4), c + Vector2(w, h * 0.4), c + Vector2(0, h),
		c + Vector2(-w, h * 0.4), c + Vector2(-w, -h * 0.4)])
	_flat_polygon(gem, pts, Color(PRISM[1]))
	for y in range(-OY, S):
		for x in S:
			if _gp(gem, x, y).a > 0.0:
				var d := Vector2(x + 0.5, y + 0.5) - c
				if d.x < 0 and d.y < 0:
					_sp(gem, x, y, Color(PRISM[2]))
				elif d.x > 0 and d.y > 0:
					_sp(gem, x, y, Color(PRISM[0]))
	_stamp(canvas, gem, o)
	_line(canvas, [c + Vector2(0, -h), c + Vector2(0, h)], Color(PRISM[3]))
	var glints := [Color("#ec9cf4"), Color("#fcd47c"), Color("#9cc46c")]
	_px(canvas, int(c.x) - int(w * 0.5), int(c.y) - 1, glints[f % 3])
	_px(canvas, int(c.x) + int(w * 0.5), int(c.y) + 1, glints[(f + 1) % 3])

func _draw_prism_jar(canvas: Image, st: Dictionary) -> void:
	_draw_firefly_jar(canvas, st)
	_faceted_crystal(canvas, Vector2(30.5, 9 + st.dy), 8.0, 9.0, Color("#1a2230"), st.f)

func _draw_rainbow_prism(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	_draw_firefly_jar(canvas, st)
	# Three coloured beams fanning up out of the crown (its hits split three ways).
	var cols := [Color("#ec9cf4"), Color("#fcd47c"), Color("#9cd4fc")]
	for k in 3:
		var a: float = -PI / 2.0 + (k - 1) * 1.05
		for i in range(11, 20 + (st.f + k) % 3):
			var p := Vector2(30.5, 9 + dy) + Vector2.from_angle(a) * i
			_px(canvas, int(p.x), int(p.y), cols[k])
	_faceted_crystal(canvas, Vector2(30.5, 9 + dy), 10.0, 9.0, Color("#1a2230"), st.f)
	_faceted_crystal(canvas, Vector2(14, 21 + dy), 4.0, 5.0, Color("#1a2230"), st.f + 1)
	_faceted_crystal(canvas, Vector2(47, 21 + dy), 4.0, 5.0, Color("#1a2230"), st.f + 2)

func _attack_prism_jar(canvas: Image, st: Dictionary) -> void:
	_prism_flash(canvas, st, "prism_jar", 1)

func _attack_rainbow_prism(canvas: Image, st: Dictionary) -> void:
	_prism_flash(canvas, st, "rainbow_prism", 3)

# The crystal flares and splits its light into beams (one, or three coloured ones).
func _prism_flash(canvas: Image, st: Dictionary, key: String, beams: int) -> void:
	# The crystal flares and splits its light: a bright star on the crystal, beams fanning out of it
	# (white for Prism Jar, three colours for Rainbow Prism), two pixels thick.
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	var c := Vector2(ATTACKS[key].point)
	var cols := [Color("#ec9cf4"), Color("#fcd47c"), Color("#9cd4fc")]
	var n: int = maxi(beams, 3)
	for b in n:
		var a: float = -0.55 + b * 0.55 - PI * 0.12
		var d := Vector2.from_angle(a)
		var col: Color = Color.WHITE if beams == 1 else cols[b % 3]
		for i in range(4, 28 - k * 4):
			var p := c + d * i
			_px(canvas, roundi(p.x), roundi(p.y), col)
			if k < 2:
				_px(canvas, roundi(p.x + d.orthogonal().x), roundi(p.y + d.orthogonal().y), Color("#dce8f4") if beams == 1 else col)
	for i in range(-5, 6):
		_px(canvas, int(c.x) + i, int(c.y), Color.WHITE)
		_px(canvas, int(c.x), int(c.y) + i, Color.WHITE)
	_warm_glow(canvas, c, Vector2(9, 8), k)


# A sparkler: a thin stick held up, a fizzing star of sparks at its tip, a few falling.
func _sparkler(canvas: Image, hand: Vector2, tip: Vector2, f: int, o: Color) -> void:
	var stick := _layer()
	_stroke(stick, [hand, tip], 1.0, Color("#8c8cac"))
	_stamp(canvas, stick, o)
	for k in 8:
		var a: float = k * TAU / 8.0 + f * 0.4
		var r: float = 4.0 + (k + f) % 3
		var p := tip + Vector2.from_angle(a) * r
		_px(canvas, int(p.x), int(p.y), Color("#fff4dc") if k % 2 == 0 else Color("#fcd47c"))
	_glow_dot(canvas, Vector2i(tip), Color.WHITE, Color("#fcd47c"))
	for k in 2:
		var p := tip + Vector2(-2 + k * 4, 4 + (f + k * 2) % 5)
		_px(canvas, int(p.x), int(p.y), Color("#e9a83c"))

func _draw_sparkler(canvas: Image, st: Dictionary) -> void:
	_draw_firefly_jar(canvas, st)
	_sparkler(canvas, Vector2(44, 30), Vector2(54, 12 + st.dy), st.f, Color("#1a2230"))

func _draw_starburst(canvas: Image, st: Dictionary) -> void:
	_draw_firefly_jar(canvas, st)
	_sparkler(canvas, Vector2(44, 30), Vector2(56, 13 + st.dy), st.f, Color("#1a2230"))
	_sparkler(canvas, Vector2(18, 30), Vector2(6, 13 + st.dy), st.f + 2, Color("#1a2230"))

func _attack_sparkler(canvas: Image, st: Dictionary) -> void:
	_firework_burst(canvas, st, "sparkler", 6, false)

func _attack_starburst(canvas: Image, st: Dictionary) -> void:
	_firework_burst(canvas, st, "starburst", 6, true)

# A firework shoots up out of the sparkler and bursts into sparks (twice for Starburst).
func _firework_burst(canvas: Image, st: Dictionary, key: String, n: int, double: bool) -> void:
	var k: int = st.attack - RELEASE_FRAME
	var from := Vector2(ATTACKS[key].point)
	if k == 0:
		_line(canvas, [from, from + Vector2(2, -8)], Color("#fcd47c"))
		_glow_dot(canvas, Vector2i(from + Vector2(2, -9)), Color.WHITE, Color("#fcd47c"))
	elif k == 1 or k == 2:
		var centres := [from + Vector2(2, -10)]
		if double:
			centres.append(from + Vector2(-12, -6))
		for c: Vector2 in centres:
			for s in n:
				var d := Vector2.from_angle(s * TAU / n) * (4.0 + k * 3.0)
				_px(canvas, int(c.x + d.x), int(c.y + d.y), Color("#fff4dc") if k == 1 else Color("#e9a83c"))
			_warm_glow(canvas, c, Vector2(6, 6), k)


# --- Branch expansion, Bellflower --------------------------------------------------------------
# Silver Bell -> Vesper Bell (one big silver bell hung from a post and crossbeam; a little peaked
# belfry with an evening star), Hushbell -> Silence (its bell cap muffled in moss, a finger to its
# lips; a moss cloak to the ground, eyes shut), Thrum -> Resonance (a trumpet flower on its head
# facing forward; a great horn flower on a stem beside it, sound rings rolling out).

const SILVER := ["#8c8cac", "#b4b0c8", "#dce8f4", "#ffffff"]

func _bell_fig() -> Dictionary:
	return _pal("#22183a", "#e0d0f8", "#c0a8ec", "#9a80d0")

func _bell_base(canvas: Image, st: Dictionary, lush: bool) -> Dictionary:
	var fig := _bell_fig()
	_draw_waystone(canvas, st, "bellflower", lush)
	_draw_template_figure(canvas, st.pose, fig)
	return fig

func _draw_silver_bell(canvas: Image, st: Dictionary) -> void:
	_silver_body(canvas, st, false)

func _draw_vesper_bell(canvas: Image, st: Dictionary) -> void:
	_silver_body(canvas, st, true)

func _silver_body(canvas: Image, st: Dictionary, vesper: bool) -> void:
	var dy: int = st.dy
	var fig := _bell_base(canvas, st, vesper)
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), true, st.attack < 0)
	_bell_cap(canvas, Vector2(30.5, 10 + dy), 12.0, 8, fig.o)
	var wood := _layer()
	if vesper:
		# A little belfry: two posts and a peaked roof, the evening star above it.
		_stroke(wood, [Vector2(56, 46), Vector2(56, 3)], 2.0, Color("#5c3c24"))
		_stroke(wood, [Vector2(40, 46), Vector2(40, 3)], 1.8, Color("#5c3c24"))
		_stroke(wood, [Vector2(56, 4), Vector2(40, 4)], 1.6, Color("#5c3c24"))
		_stamp(canvas, wood, fig.o)
		var roof := _layer()
		_flat_polygon(roof, PackedVector2Array([Vector2(35, 5), Vector2(48, -3), Vector2(61, 5), Vector2(61, 6), Vector2(35, 6)]), Color("#8c5c34"))
		_stamp(canvas, roof, fig.o)
		_sparkle(canvas, Vector2i(48, 1), Color("#fcd47c") if st.f % 4 < 2 else Color("#fff4dc"))
	else:
		# A curved crook planted beside it, leafing, the bell hanging from its hook like a lantern.
		_stroke(wood, [Vector2(56, 46), Vector2(57, 20), Vector2(56, 8), Vector2(52, 3), Vector2(47, 3), Vector2(45, 6)], 1.8, Color("#8c5c34"))
		_stamp(canvas, wood, fig.o)
		for p: Vector2i in [Vector2i(57, 30), Vector2i(56, 16)]:
			_leaf(canvas, Vector2(p), Vector2(p) + Vector2(4, -3), 1.6, _ramp(LEAF), fig.o)
	var swing: int = [0, 1, 0, -1][st.f % 4]
	var hook := Vector2(48, 4) if vesper else Vector2(45, 6)
	_line(canvas, [hook, hook + Vector2(swing, 3)], fig.o)
	_bell(canvas, hook + Vector2(0, 3), 8.5 if vesper else 7.5, swing, _ramp(SILVER), fig.o)


func _attack_silver_bell(canvas: Image, st: Dictionary) -> void:
	_toll(canvas, st, "silver_bell", 1)

func _attack_vesper_bell(canvas: Image, st: Dictionary) -> void:
	_toll(canvas, st, "vesper_bell", 2)

# One toll: rings going out from the bell, long and thin (it reaches far); Vesper's echoes.
func _toll(canvas: Image, st: Dictionary, key: String, echoes: int) -> void:
	# One toll: the bell flashes and thick silver rings spread from it (Vesper's echo after them), a
	# note leaping off.
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	var c := Vector2(ATTACKS[key].point)
	for e in echoes + 1:
		var r := 5.0 + k * 5.0 + e * 5.0
		for s in 40:
			var a := s * TAU / 40.0
			if (s + k) % 5 == 4:
				continue
			var p := c + Vector2(cos(a) * r, sin(a) * r * 0.75)
			_px(canvas, roundi(p.x), roundi(p.y), Color(SILVER[3]) if e == 0 else Color(SILVER[1]))
			if e == 0 and k < 2:
				_px(canvas, roundi(p.x), roundi(p.y) + 1, Color(SILVER[1]))
	_glyph(canvas, Vector2i(int(c.x) - 10 - k * 2, int(c.y) - 10 - k * 3), NOTE_GLYPH, Color(SILVER[3]))
	if k == 0:
		_warm_glow(canvas, c, Vector2(9, 8))


func _draw_hushbell(canvas: Image, st: Dictionary) -> void:
	_hush_body(canvas, st, false)

func _draw_silence(canvas: Image, st: Dictionary) -> void:
	_hush_body(canvas, st, true)

func _hush_body(canvas: Image, st: Dictionary, deep: bool) -> void:
	var dy: int = st.dy
	var fig := _bell_fig()
	_draw_waystone(canvas, st, "bellflower", deep)
	if deep:
		# A moss cloak over its back and shoulders, falling to the slab either side.
		var cloak := _layer()
		_flat_polygon(cloak, PackedVector2Array([Vector2(16, 12 + dy), Vector2(45, 12 + dy), Vector2(53, 45), Vector2(9, 45)]), Color(MOSS[1]))
		_stamp(canvas, cloak, Color("#1e3a24"))
		for x in range(11, 52, 4):
			_px(canvas, x, 44, Color(MOSS[3]))
	_draw_template_figure(canvas, st.pose, fig)
	fig = _body_pal(fig)
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), true, deep)
	# Its bell cap, muffled in a thick cushion of moss.
	_bell_cap(canvas, Vector2(30.5, 10 + dy), 13.0, 9, fig.o)
	var muffle := _layer()
	_ellipse(muffle, Vector2(30.5, 4 + dy), Vector2(15.0 if deep else 13.0, 5.5), _ramp(MOSS), 8.0 + dy)
	_stamp(canvas, muffle, Color("#1e3a24"))
	for x in [20, 26, 34, 40]:
		_px(canvas, x, 8 + dy, Color(MOSS[0]))
	# Shh: a hand raised to its mouth, one finger up across its lips, the forearm down to its side.
	var hand := _layer()
	_stroke(hand, [Vector2(44, 30 + dy), Vector2(38, 21 + dy)], 1.6, fig.b)  # the forearm
	_flat_ellipse(hand, Vector2(35.5, 19 + dy), Vector2(3.2, 2.6), fig.a)  # the fist
	_stroke(hand, [Vector2(33.5, 19 + dy), Vector2(33.5, 13 + dy)], 0.9, fig.a)  # the finger
	_stamp(canvas, hand, fig.o)
	if st.attack < 0:
		# The hush drifting away: a little sound wave fading off.
		var t: int = st.f % 8
		var p := Vector2i(39 + t / 2, 13 + dy - t / 2)
		for d: Vector2i in [Vector2i(0, 0), Vector2i(1, -1), Vector2i(2, 0), Vector2i(3, -1)]:
			_px(canvas, p.x + d.x, p.y + d.y, Color("#dce8f4"))


func _attack_hushbell(canvas: Image, st: Dictionary) -> void:
	_hush_wave(canvas, st, 1.0)

func _attack_silence(canvas: Image, st: Dictionary) -> void:
	_hush_wave(canvas, st, 1.3)

# A soft muffling ring spreading out low (no sound: a dim, quiet wave).
func _hush_wave(canvas: Image, st: Dictionary, size: float) -> void:
	# The hush: its muffled bell glows dim violet, a thick ring of muted sound rolls out over the slab
	# (dark, with a pale inner edge, so it reads as quiet, not as light) and "shh" waves leave its finger.
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	var dy: int = st.dy
	_fog(canvas, Vector2(30.5, 6 + dy), Vector2(16, 7) * (1.0 + k * 0.15), Color("#9a84e8", 0.55), st.f)
	var c := Vector2(31, 42)
	var r := Vector2(12 + k * 8, 4 + k * 2.5) * size
	for s in 64:
		var a := s * TAU / 64.0
		if (s + k * 2) % 8 == 7:
			continue
		var p := c + Vector2(cos(a) * r.x, sin(a) * r.y)
		_px(canvas, roundi(p.x), roundi(p.y), Color("#4c3c74"))
		_px(canvas, roundi(p.x), roundi(p.y) - 1, Color("#9a84e8") if k < 2 else Color("#4c3c74"))
	for w in 2:
		var o := Vector2(37 + k * 3 + w * 3, 13 + dy - k * 2 - w * 2)
		for d: Vector2i in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(2, 1), Vector2i(3, 0)]:
			_px(canvas, int(o.x) + d.x, int(o.y) + d.y, Color("#dce8f4"))


# A trumpet flower: a stem, a long flaring horn facing `dir`, a pale throat.
func _horn_flower(canvas: Image, base: Vector2, dir: Vector2, length: float, flare: float, o: Color) -> void:
	var horn := _layer()
	var pts := PackedVector2Array()
	var n := dir.orthogonal()
	pts.append(base + n * 1.5)
	pts.append(base + dir * length + n * flare)
	pts.append(base + dir * (length + 1.5))
	pts.append(base + dir * length - n * flare)
	pts.append(base - n * 1.5)
	_flat_polygon(horn, pts, Color("#c0a8ec"))
	for y in range(-OY, S):
		for x in S:
			if _gp(horn, x, y).a > 0.0 and (Vector2(x + 0.5, y + 0.5) - base).dot(n) > 0.0:
				_sp(horn, x, y, Color("#e0d0f8"))
	_stamp(canvas, horn, o)
	var mouth := base + dir * (length - 0.5)
	_line(canvas, [mouth + n * (flare - 1.5), mouth - n * (flare - 1.5)], Color("#fff4dc"))

func _draw_thrum(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _bell_base(canvas, st, false)
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), true, st.attack < 0)
	# A trumpet flower on its head, its horn flaring out ahead of it.
	_horn_flower(canvas, Vector2(32, 6 + dy), Vector2(1, 0.15).normalized(), 18.0, 5.5, fig.o)
	_leaf(canvas, Vector2(30, 6 + dy), Vector2(22, 1 + dy), 2.6, _ramp(LEAF), fig.o)

func _draw_resonance(canvas: Image, st: Dictionary) -> void:
	var dy: int = st.dy
	var fig := _bell_base(canvas, st, true)
	_golem_face(canvas, st, fig, Color(0, 0, 0, 0), true, st.attack < 0)
	_horn_flower(canvas, Vector2(32, 6 + dy), Vector2(1, 0.15).normalized(), 14.0, 4.5, fig.o)
	# A great horn flower on a tall stem beside it, aimed ahead, sound rings rolling out of it.
	var stem := _layer()
	_stroke(stem, [Vector2(12, 46), Vector2(11, 28), Vector2(13, 22)], 1.6, Color(LEAF[1]))
	_stamp(canvas, stem, fig.o)
	_horn_flower(canvas, Vector2(13, 22), Vector2(-0.2, -1).normalized(), 16.0, 9.5, fig.o)
	if st.attack < 0:
		for k in 2:
			var r: float = 3.0 + ((st.f * 2 + k * 4) % 8)
			var c := Vector2(10, 4)
			for s in 8:
				var a := -PI / 2.0 + (s - 3.5) * 0.25
				_px(canvas, int(c.x + cos(a) * r - r * 0.3), int(c.y + sin(a) * r * 0.5), Color("#e0c8ff", 1.0 - r / 12.0))

func _attack_thrum(canvas: Image, st: Dictionary) -> void:
	_sound_cone(canvas, st, "thrum", 0.45)

func _attack_resonance(canvas: Image, st: Dictionary) -> void:
	_sound_cone(canvas, st, "resonance", 0.7)

# Arcs of sound rolling out of the horn in a cone ahead of it.
func _sound_cone(canvas: Image, st: Dictionary, key: String, spread: float) -> void:
	# Arcs of sound rolling out of the horn: three thick arcs, the nearest brightest, widening as they go.
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	var c := Vector2(ATTACKS[key].point)
	for ring in 3:
		var r := 3.0 + k * 2.5 + ring * 3.0
		var col := Color("#fff4dc") if ring == 0 else (Color("#ec9cf4") if ring == 1 else Color("#9a84e8"))
		for s in 15:
			var a := (s - 7) / 7.0 * (spread + 0.5 + ring * 0.15)
			var p := c + Vector2.from_angle(a) * r
			_px(canvas, roundi(p.x), roundi(p.y), col)
			_px(canvas, roundi(p.x) + 1, roundi(p.y), col)
	_warm_glow(canvas, c, Vector2(7, 6), k)


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
			_snap32(sheet).save_png(RANKS_OUT + "rank_%d_%s.png" % [rank, layer])
	var badges := Image.create_empty(BADGE_SIZE * RANK_TOP, BADGE_SIZE, false, Image.FORMAT_RGBA8)
	for rank in range(1, RANK_TOP + 1):
		badges.blit_rect(_rank_badge(rank), Rect2i(0, 0, BADGE_SIZE, BADGE_SIZE), Vector2i((rank - 1) * BADGE_SIZE, 0))
	_snap32(badges).save_png(RANKS_OUT + "rank_badges.png")
	var burst := Image.create_empty(S * RANKUP_FRAMES, S, false, Image.FORMAT_RGBA8)
	for f in RANKUP_FRAMES:
		var canvas := _layer()
		_rank_up(canvas, f)
		burst.blit_rect(canvas, Rect2i(0, 0, S, S), Vector2i(f * S, 0))
	_snap32(burst).save_png(RANKS_OUT + "rank_up.png")
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
				_sp(top, x, y, Color.WHITE)
	var rim := _layer()
	for y in range(S - 1):
		for x in S:
			if _on(top, x, y) and _on(side, x, y + 1) and y >= 40:
				_sp(rim, x, y, Color.WHITE)
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
		for y in range(-OY, S):
			for x in S:
				if not _on(masks.side, x, y):
					continue
				var ch: String = masks.grid[y * S + x]
				var col := Color("#d8a840") if ch == "d" else (Color("#a8782a") if ch == "e" else Color("#f4d878"))
				if rank >= 7:  # radiant: paler, brighter gold
					col = Color("#f4d070") if ch == "d" else (Color("#d0a040") if ch == "e" else Color("#fff0b8"))
				if (x * 3 + y * 5) % 11 == 0:
					col = col.lightened(0.3) if lit else col.lightened(0.15)
				_sp(canvas, x, y, col)
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
	for y in range(-OY, S):
		for x in S:
			var q := ((Vector2(x + 0.5, y + 0.5) - c) / r).length()
			if q > 1.0:
				continue
			if q > 0.85 and (x + y + f) % 2 == 0:
				_sp(canvas, x, y, Color(GLOW_OUTER, 0.55))
			elif q <= 0.85 and (x + 2 * y + f) % (3 if rank >= 4 else 4) == 0:
				_sp(canvas, x, y, Color(GLOW_INNER, 0.6))

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
	for y in range(-OY, S):
		for x in S:
			if not _on(top, x, y):
				continue
			var h := (x * 29 + y * 53) % 9
			_sp(canvas, x, y, Color("#8ab07a") if h == 0 else (Color("#4a7a50") if h == 4 else Color("#5f8f5c")))
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
	for y in range(-OY, S):
		for x in S:
			var p := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(p, pts):
				var nx := clampf((p.x - c.x) / w, -1.0, 1.0)
				_sp(layer, x, y, _shade(ramp, Vector3(nx, -0.3, sqrt(maxf(0.1, 1.0 - nx * nx)))))
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
		for y in range(-OY, S):
			for x in S:
				if _gp(trunk, x, y).a > 0.0 and x % 4 == 0:
					_sp(trunk, x, y, fig.c)
				elif _gp(trunk, x, y).a > 0.0 and x < 8:
					_sp(trunk, x, y, fig.a)
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
	var stone := _ramp(ROCK_RAMP)
	for i in stones.size():
		var s: Vector3 = stones[i]
		if lifted and i == stones.size() - 1:
			continue
		var layer := _layer()
		var y := s.y + (bob if i == stones.size() - 1 else 0)
		_ellipse(layer, Vector2(s.x, y), Vector2(s.z, s.z * 0.45), stone)
		_stamp(canvas, layer, o)
		_px(canvas, int(s.x) - 1, int(y) - 1, Color("#d6d3e0"))

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
		# The rockslide: a heap of boulders piled up behind the golem's right shoulder, sliding down
		# onto the slab, with pebbles tumbling down it and dust where they land.
		var radii := [1.0, 0.8, 0.95, 0.75, 1.0, 0.85, 0.9]
		for b: Array in [[Vector2(45, 18), 6.0], [Vector2(53, 25), 6.5], [Vector2(40, 24), 4.5],
				[Vector2(57, 34), 6.0], [Vector2(48, 30), 5.0], [Vector2(59, 44), 5.0], [Vector2(51, 40), 5.5]]:
			var c: Vector2 = b[0]
			var r: float = b[1]
			var pts := PackedVector2Array()
			for k in 7:
				pts.append(c + Vector2.from_angle(k * TAU / 7.0 + c.x * 0.1) * r * radii[k])
			_rock(canvas, pts, _ramp(ROCK_RAMP), ROCK_PAL.o)
		for k in 3:
			var t: float = fposmod(float(st.f) / st.n + k / 3.0, 1.0)
			var p := Vector2i((Vector2(44, 12).lerp(Vector2(60, 46), t)).round())
			_px(canvas, p.x, p.y, Color("#c4c9e2"))
			_px(canvas, p.x + 1, p.y, Color("#979dc2"))
			_px(canvas, p.x, p.y + 1, Color("#686d9a"))
			if t > 0.8:
				for d: Vector2i in [Vector2i(-2, 1), Vector2i(2, 1), Vector2i(0, 2)]:
					_px(canvas, 60 + d.x, 47 + d.y, Color("#d8d4e4"))
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
func _hummingbird(canvas: Image, p: Vector2, face: int, jewel: Array, f: int, s: float = 1.0) -> void:
	var o := Color("#12101e")
	var body := _layer()
	_ellipse(body, p, Vector2(2.6, 1.9) * s, _ramp(jewel))
	_ellipse(body, p + Vector2(face * 2.2, -1.2) * s, Vector2(1.6, 1.5) * s, _ramp(jewel))
	_flat_polygon(body, PackedVector2Array([p + Vector2(-face * 2, 0) * s, p + Vector2(-face * 5, 1.5) * s, p + Vector2(-face * 4, -1) * s]), Color(jewel[0]))
	_stamp(canvas, body, o)
	_line(canvas, [p + Vector2(face * 3.6, -1.4) * s, p + Vector2(face * 6.5, -1) * s], Color("#2a2030"))
	_px(canvas, roundi(p.x + face * 2.6 * s), roundi(p.y - 1.8 * s), o)
	_px(canvas, roundi(p.x + face * 1.6 * s), roundi(p.y), Color("#ff6a8a"))
	var wing_y := (-3.0 if f % 2 == 0 else -1.5) * s
	_flat_ellipse(canvas, p + Vector2(-face * 0.5 * s, wing_y), Vector2(2.2, 1.0) * s, Color(1, 1, 1, 0.55))

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

# --- Epic finals (user 2026-10-02: "keep the warden look all around but just make it epic"; "each
# family should be unique but still be epic") ---------------------------------------------------------
# Every Warden stays a golem. A final is its branch's golem become a boss: on top of its own design
# (through _final_extra, idle and attack sheets) it gets its family's own epic motif, tinted per final,
# and its eyes glow:
#   Sporeling: a grove of tall glowing mushrooms rising behind it
#   Pebbling: rune stones floating round it
#   Bellflower: rings of sound rippling out behind it
#   Dewdrop: a flowing mantle of water (ice for Hoarfrost, mist for Morning Fog) and a crown of drops
#   Firefly Jar: a swarm of fireflies circling it
#   Rootling: a throne of roots risen behind it
#   Acorn: great branching antlers with leaves
#   Nestling: huge spread wings
#   Whirligig: a wind vortex spiralling round it, leaves riding it

# glow / core: its light. tint: the motif's material ramp (shadow → light).
const EPIC := {
	"puffball": {glow = "#ec9cf4", core = "#fff4dc", tint = ["#bca48c", "#dccdb2", "#dccdb2", "#fff4dc"]},
	"dreamshroom": {glow = "#9cd4fc", core = "#dce8f4", tint = ["#2c2444", "#4c3c74", "#4c3c74", "#9a84e8"]},
	"elf_circle": {glow = "#9cd4fc", core = "#dce8f4", tint = ["#2c4c5c", "#4c8ca4", "#4c8ca4", "#9cd4fc"]},
	"boulderback": {glow = "#e9a83c", core = "#fcd47c", tint = ["#65627a", "#8f8ca2", "#b9b6c6", "#d6d3e0"]},
	"moonstone": {glow = "#9cd4fc", core = "#dce8f4", tint = ["#65627a", "#8f8ca2", "#b9b6c6", "#d6d3e0"]},
	"rockslide": {glow = "#e9a83c", core = "#fcd47c", tint = ["#5c3c24", "#8c5c34", "#bca48c", "#dccdb2"]},
	"lullaby_bell": {glow = "#fcd47c", core = "#fff4dc", tint = []},
	"great_dreamcatcher": {glow = "#ec9cf4", core = "#fff4dc", tint = []},
	"whispering_hollow": {glow = "#9a84e8", core = "#dce8f4", tint = []},
	"monsoon": {glow = "#9cd4fc", core = "#dce8f4", tint = ["#2c4c5c", "#4c8ca4", "#9cd4fc", "#dce8f4"]},
	"morning_fog": {glow = "#dce8f4", core = "#ffffff", tint = ["#8c8cac", "#b4b0c8", "#dce8f4", "#ffffff"]},
	"hoarfrost": {glow = "#9cd4fc", core = "#ffffff", tint = ["#4c8ca4", "#9cd4fc", "#dce8f4", "#ffffff"]},
	"thunderhead": {glow = "#9cd4fc", core = "#dce8f4", tint = []},  # cold, so its idle ring carries no warm halo (AI-look audit)
	"beacon": {glow = "#fcd47c", core = "#fff4dc", tint = []},
	"midsummer": {glow = "#e9a83c", core = "#fff4dc", tint = []},
	"long_way_home": {glow = "#e9a83c", core = "#fcd47c", tint = ["#241c14", "#5c3c24", "#8c5c34", "#bca48c"]},
	"snugroot": {glow = "#d4ec9c", core = "#fff4dc", tint = ["#5c3c24", "#8c5c34", "#bca48c", "#dccdb2"]},
	"starcave": {glow = "#9a84e8", core = "#dce8f4", tint = ["#241c14", "#5c3c24", "#8c5c34", "#bca48c"]},
	"grove_heart": {glow = "#d4ec9c", core = "#fff4dc", tint = ["#241c14", "#5c3c24", "#8c5c34", "#bca48c"], leaf = ["#1c3c2c", "#34643c", "#5c944c", "#9cc46c"]},
	"wellspring": {glow = "#9cd4fc", core = "#dce8f4", tint = ["#241c14", "#5c3c24", "#8c5c34", "#bca48c"], leaf = ["#2c4c5c", "#4c8ca4", "#9cd4fc", "#dce8f4"]},
	"grafted_elder": {glow = "#d4ec9c", core = "#fff4dc", tint = ["#241c14", "#5c3c24", "#8c5c34", "#bca48c"], leaf = ["#5c3c24", "#b8662c", "#e9a83c", "#fcd47c"]},
	"starling_murmuration": {glow = "#dce8f4", core = "#ffffff", tint = ["#140f26", "#24243c", "#3c3c5c", "#9cd4fc"]},
	"magpies_hoard": {glow = "#fcd47c", core = "#fff4dc", tint = ["#140f26", "#24243c", "#dce8f4", "#ffffff"]},
	"jewelwing_court": {glow = "#ec9cf4", core = "#fff4dc", tint = ["#2c4c5c", "#4c8ca4", "#9cd4fc", "#ec9cf4"]},
	"zephyr": {glow = "#dce8f4", core = "#ffffff", tint = ["#4c8ca4", "#9cd4fc", "#dce8f4", "#ffffff"], leaf = ["#34643c", "#5c944c", "#9cc46c", "#d4ec9c"]},
	"windmill": {glow = "#fcd47c", core = "#fff4dc", tint = ["#bca48c", "#dccdb2", "#dccdb2", "#fff4dc"], leaf = ["#5c3c24", "#8c5c34", "#bca48c", "#dccdb2"]},
	"autumn_gale": {glow = "#fcd47c", core = "#fff4dc", tint = ["#b8662c", "#e9a83c", "#fcd47c", "#fff4dc"], leaf = ["#b8662c", "#e9a83c", "#fcd47c", "#fff4dc"]},
	# The branch expansion's finals.
	"old_lichen": {glow = "#d4ec9c", core = "#fff4dc", tint = ["#5c944c", "#9cc46c", "#9cc46c", "#d4ec9c"]},
	"hatchery": {glow = "#ec9cf4", core = "#fff4dc", tint = ["#4c3c74", "#9a84e8", "#9a84e8", "#ec9cf4"]},
	"deliquescent": {glow = "#9a84e8", core = "#dce8f4", tint = ["#24243c", "#3c3c5c", "#3c3c5c", "#5c5a78"]},
	"vesper_bell": {glow = "#dce8f4", core = "#fcd47c", tint = []},
	"silence": {glow = "#9a84e8", core = "#dce8f4", tint = []},
	"resonance": {glow = "#ec9cf4", core = "#fff4dc", tint = []},
	"nimbus": {glow = "#9cd4fc", core = "#dce8f4", tint = []},
	"maelstrom": {glow = "#9cd4fc", core = "#dce8f4", tint = ["#2c4c5c", "#4c8ca4", "#9cd4fc", "#dce8f4"]},
	"torrent": {glow = "#9cd4fc", core = "#dce8f4", tint = ["#2c4c5c", "#4c8ca4", "#9cd4fc", "#dce8f4"]},
	"lightning_fence": {glow = "#9a84e8", core = "#fff4dc", tint = []},
	"rainbow_prism": {glow = "#ec9cf4", core = "#ffffff", tint = []},
	"starburst": {glow = "#fcd47c", core = "#fff4dc", tint = []},
	"edgestone": {glow = "#dce8f4", core = "#ffffff", tint = []},
	"bastion": {glow = "#fcd47c", core = "#fff4dc", tint = ["#5c5a78", "#8c8cac", "#b4b0c8", "#dce8f4"]},
	"earthshaker": {glow = "#e9a83c", core = "#fcd47c", tint = ["#241c14", "#5c3c24", "#8c5c34", "#bca48c"]},
	"earthbind": {glow = "#d4ec9c", core = "#fff4dc", tint = ["#5c3c24", "#bca48c", "#dccdb2"]},
	"heartroot": {glow = "#fcd47c", core = "#fff4dc", tint = ["#5c3c24", "#8c5c34", "#b8662c"]},
	"crown_of_thorns": {glow = "#ec9cf4", core = "#fff4dc", tint = ["#241c14", "#5c3c24", "#8c5c34"]},
	"grove_keeper": {glow = "#d4ec9c", core = "#fff4dc", tint = ["#241c14", "#5c3c24", "#8c5c34", "#bca48c"], leaf = ["#1c3c2c", "#34643c", "#5c944c", "#9cc46c"]},
	"mother_log": {glow = "#d4ec9c", core = "#fff4dc", tint = [], leaf = ["#1c3c2c", "#34643c", "#5c944c", "#9cc46c"]},
	"dreamroot": {glow = "#ec9cf4", core = "#fff4dc", tint = ["#2c2444", "#4c3c74", "#9a84e8"]},
}
const EPIC_O := Color("#140f26")

func _epic_family(tower_name: String) -> String:
	for line: String in LINES:
		if tower_name in LINES[line]:
			return line
	return ""

# The golem's own pixels (the template figure without its rocks).
func _figure_mask(st: Dictionary) -> Image:
	var pose: Dictionary = st.pose
	var mask := _layer()
	for i in S * S:
		if pose.grid[i] != "." and pose.outside[i] == 0 and not _is_rock(pose, i % S, i / S):
			_sp(mask, i % S, i / S, Color.WHITE)
	return mask

# Puts `layer` behind what's already on the canvas (only into its empty pixels).
func _under(canvas: Image, layer: Image) -> void:
	for y in range(-OY, S):
		for x in S:
			var c := _gp(layer, x, y)
			if c.a > 0.0 and _gp(canvas, x, y).a == 0.0:
				_sp(canvas, x, y, c)

# Outlines a layer's shapes (EPIC_O round their outer edge) so they read as bold shapes.
func _outline_layer(layer: Image) -> void:
	var src := layer.duplicate() as Image
	for y in range(-OY, S):
		for x in S:
			if _gp(src, x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var q := Vector2i(x, y) + d
				if q.x >= 0 and q.x < S and q.y >= -OY and q.y < S and _gpv(src, q).a > 0.0:
					_sp(layer, x, y, EPIC_O)
					break

func _epic_final(tower_name: String, canvas: Image, st: Dictionary) -> void:
	var cfg: Dictionary = EPIC[tower_name]
	var glow := Color(cfg.glow)
	var core := Color(cfg.core)
	if has_method("_epic_" + tower_name):
		call("_epic_" + tower_name, canvas, cfg, st, glow, core)
	else:
		_epic_family_motif(_epic_family(tower_name), canvas, cfg, st, glow, core)
	# Its eyes glow in its light.
	if not st.blink:
		for ex: int in EYES:
			for k in 3:
				_px(canvas, ex, EYE_TOP + k + st.dy, core if k == 1 else glow)

# Each family's own motif (a final without its own version takes it as it is).
func _epic_family_motif(family: String, canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	match family:
		"sporeling": _epic_mushroom_grove(canvas, cfg, st, glow, core)
		"pebbling": _epic_rune_stones(canvas, cfg, st, glow, core)
		"bellflower": _epic_sound_rings(canvas, st, glow, core)
		"dewdrop": _epic_water_mantle(canvas, cfg, st, glow, core)
		"firefly_jar": _epic_swarm(canvas, st, glow, core)
		"rootling": _epic_root_throne(canvas, cfg, st, glow, core)
		"acorn": _epic_antlers(canvas, cfg, st, glow, core)
		"nestling": _epic_wings(canvas, cfg, st, glow, core)
		"whirligig": _epic_vortex(canvas, cfg, st, glow, core)

# Sporeling: a grove of tall mushrooms risen behind it, caps glowing at the rim, spores drifting up.
func _epic_mushroom_grove(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var grove := _layer()
	var cap := _ramp(cfg.tint)
	var sway: float = [0.0, 0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5][st.f % 8]
	# x, cap height (top of cap), cap half-width
	for m: Vector3 in [Vector3(7, 10, 6.5), Vector3(16, -4, 8.5), Vector3(47, -8, 9.0), Vector3(56, 6, 6.5)]:
		var top := Vector2(m.x + sway * (1.0 if m.x > 31 else -1.0), m.y)
		var stem := _layer()
		_stroke(stem, [Vector2(m.x, 40), top + Vector2(0, m.z * 0.6)], 1.6, Color("#dccdb2"))
		for y in range(-OY, S):
			for x in S:
				if _gp(stem, x, y).a > 0.0:
					_sp(grove, x, y, Color("#bca48c") if x > int(m.x) else Color("#dccdb2"))
		_ellipse(grove, top + Vector2(0, m.z * 0.65), Vector2(m.z, m.z * 0.7), cap, top.y + m.z * 0.65)
		for x in range(int(top.x - m.z) + 1, int(top.x + m.z)):
			_px(grove, x, int(top.y + m.z * 0.65), glow)  # the glowing gill rim
	_outline_layer(grove)
	_under(canvas, grove)
	for k in 6:
		var t := float((st.f + k * 3) % 8) / 8.0
		var p := Vector2([10, 18, 46, 54, 24, 40][k] + sin(t * TAU + k) * 2.0, 6 - t * 18.0 + (k % 3) * 4)
		_px(canvas, roundi(p.x), roundi(p.y), core if k % 2 == 0 else glow)

# Pebbling: three rune stones floating round it, bobbing, a glowing rune cut in each, light under them.
func _epic_rune_stones(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var ramp := _ramp(cfg.tint)
	for k in 3:
		var bob: float = [0.0, -1.0, -1.0, 0.0, 0.0, 1.0, 1.0, 0.0][(st.f + k * 3) % 8]
		var c: Vector2 = [Vector2(7, 14), Vector2(56, 10), Vector2(31.5, -10)][k] + Vector2(0, bob)
		var s: float = [7.5, 7.0, 8.0][k]
		var pts := PackedVector2Array()
		for i in 6:
			var a := i * TAU / 6.0 + 0.3 + k
			pts.append(c + Vector2(cos(a) * s * 0.85, sin(a) * s))
		if k == 2:
			var back := _layer()
			_rock(back, pts, ramp, EPIC_O)
			_under(canvas, back)
		else:
			_rock(canvas, pts, ramp, EPIC_O)
		# The rune: a little glowing glyph.
		var g := Vector2i(c.round())
		for p: Vector2i in [[Vector2i(0, -2), Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(-1, -1), Vector2i(1, 0)],
				[Vector2i(-1, -2), Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 2)],
				[Vector2i(0, -2), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)]][k]:
			_px(canvas, g.x + p.x, g.y + p.y, core if p.y == 0 else glow)
		# Light falling from it.
		for i in 3:
			if (st.f + i + k) % 2 == 0:
				_px(canvas, g.x - 1 + i, g.y + int(s) + 2 + i, Color(glow, 0.7))

# Bellflower: rings of sound rippling out behind its head, travelling outward over the loop.
func _epic_sound_rings(canvas: Image, st: Dictionary, glow: Color, core: Color) -> void:
	var rings := _layer()
	var c := Vector2(31.5, 16 + st.dy)
	var t := float(st.f % 8) / 8.0
	for k in 3:
		var r := 19.0 + k * 6.0 + t * 6.0
		if r > 34.0:
			continue
		for i in 64:
			var a := PI + 0.2 + i * (PI - 0.4) / 63.0
			if i % 8 == 7:
				continue  # a gap now and then, so they read as sound, not a wall
			var p := c + Vector2(cos(a), sin(a)) * Vector2(r, r * 0.9)
			_px(rings, roundi(p.x), roundi(p.y), core if k == 0 else glow)
			_px(rings, roundi(p.x), roundi(p.y) + 1, glow)
	_outline_layer(rings)
	_under(canvas, rings)
	for k in 2:
		_glyph(canvas, Vector2i([8, 53][k], 6 - (st.f + k * 4) % 8), NOTE_GLYPH, core)

# Dewdrop: a flowing mantle of water off its shoulders to the slab, its hem rippling, and a crown of
# three drops floating over its head.
func _epic_water_mantle(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var ramp := _ramp(cfg.tint)
	var dy: int = st.dy
	var mantle := _layer()
	var wave: float = st.f * TAU / 8.0
	for s: int in [-1, 1]:
		var pts := PackedVector2Array()
		pts.append(Vector2(31.5 + s * 6, 14 + dy))
		pts.append(Vector2(31.5 + s * 20, 15 + dy))
		for i in 7:
			pts.append(Vector2(31.5 + s * (27.0 + sin(i * 1.3 + wave) * 2.0), 20.0 + i * 4.0))
		pts.append(Vector2(31.5 + s * 22, 48))
		pts.append(Vector2(31.5 + s * 16, 45 + sin(wave + s) * 1.5))
		pts.append(Vector2(31.5 + s * 12, 30))
		_flat_polygon(mantle, pts, ramp[1])
	# Flowing water: light ripples running down it, a bright rim on its outer edge.
	for y in range(-OY, S):
		for x in S:
			if _gp(mantle, x, y).a == 0.0:
				continue
			var ox: float = absf(x - 31.5)
			var ripple: bool = (y + roundi(sin(ox * 0.5 + wave) * 2.0)) % 5 == 0
			_sp(mantle, x, y, ramp[3] if ox > 24.5 else (ramp[2] if ripple else (ramp[0] if ox < 15.0 else ramp[1])))
	_outline_layer(mantle)
	_under(canvas, mantle)
	# The clasp at its throat and a crown of three drops floating over its head.
	for d: Vector2i in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		_px(canvas, 31 + d.x, 20 + dy + d.y, core if d == Vector2i.ZERO else glow)
	for k in 3:
		var bob: int = [0, -1, -1, 0, 0, 1, 1, 0][(st.f + k * 2) % 8]
		var p := Vector2(21 + k * 10.5, (-1 if k == 1 else 3) + dy + bob)
		var drop := _layer()
		_ellipse(drop, p + Vector2(0, 1.5), Vector2(3.2, 3.2), ramp)
		_flat_polygon(drop, PackedVector2Array([p + Vector2(-2.6, 0.5), p + Vector2(0, -5.5), p + Vector2(2.6, 0.5)]), ramp[2])
		_stamp(canvas, drop, EPIC_O)
		_px(canvas, int(p.x) - 1, int(p.y), core)
		_px(canvas, int(p.x) - 1, int(p.y) + 1, core)

# Firefly Jar: a swarm of fireflies circling it, the ones behind it dimmer, each with a warm halo.
func _epic_swarm(canvas: Image, st: Dictionary, glow: Color, core: Color) -> void:
	var back := _layer()
	for k in 11:
		var a: float = k * TAU / 11.0 + st.f * TAU / 32.0
		var h := sin(k * 2.3) * 9.0
		var p := Vector2(31.5 + cos(a) * 28.0, 22 + sin(a) * 11.0 + h)
		var front := sin(a) > 0.0
		var target := canvas if front else back
		var q := Vector2i(p.round())
		# Its trail: two fading dots behind it.
		for i in range(1, 3):
			var b := Vector2(31.5 + cos(a - i * 0.12) * 28.0, 22 + sin(a - i * 0.12) * 11.0 + h)
			_px(target, roundi(b.x), roundi(b.y), Color(glow, 0.7 - i * 0.2))
		if st.attack >= 0:  # halos only when it fires (AI-look audit: glow marks the attack)
			for d: Vector2i in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1), Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, -2), Vector2i(0, 2)]:
				_px(target, q.x + d.x, q.y + d.y, Color(glow, 0.55))
		for d: Vector2i in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			_px(target, q.x + d.x, q.y + d.y, core if d == Vector2i.ZERO or (k + st.f) % 3 == 0 else glow)
	_under(canvas, back)

# Rootling: a throne of roots risen behind it: two great roots curling over its head, smaller ones
# twisting up between, light in the knots.
func _epic_root_throne(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var wood := _ramp(cfg.tint)
	var throne := _layer()
	for s: int in [-1, 1]:
		var x0 := 31.5 + s * 22.0
		_stroke(throne, [Vector2(x0, 44), Vector2(x0 + s * 2, 26), Vector2(x0 - s * 1, 8), Vector2(x0 - s * 8, -4), Vector2(x0 - s * 14, -2), Vector2(x0 - s * 13, 4)], 2.6, wood[1])
		_stroke(throne, [Vector2(x0 - s * 6, 40), Vector2(x0 - s * 4, 22), Vector2(x0 - s * 9, 6)], 1.4, wood[2])
	# Light the bark: darker on the inner side.
	for y in range(-OY, S):
		for x in S:
			if _gp(throne, x, y).a > 0.0 and (x + y * 2) % 7 == 0:
				_sp(throne, x, y, wood[0])
	_outline_layer(throne)
	_under(canvas, throne)
	for p: Vector2i in [Vector2i(10, 20), Vector2i(53, 18), Vector2i(17, -1), Vector2i(46, -1)]:
		if (st.f + p.x) % 4 < 2:
			_px(canvas, p.x, p.y, core)
			_px(canvas, p.x + 1, p.y, glow)

# Acorn: great branching antlers of wood rising from its head, leaves budding at the tips.
func _epic_antlers(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var wood := _ramp(cfg.tint)
	var leaf := _ramp(cfg.get("leaf", ["#1c3c2c", "#34643c", "#5c944c", "#9cc46c"]))
	var dy: int = st.dy
	var antlers := _layer()
	var tips: Array = []
	for s: int in [-1, 1]:
		var root := Vector2(31.5 + s * 7, 8 + dy)
		var bend := root + Vector2(s * 9, -8)
		var tip := root + Vector2(s * 22, -14)
		_stroke(antlers, [root, bend, tip], 1.5, wood[1])
		for b: Array in [[0.35, Vector2(s * 2, -9)], [0.65, Vector2(s * 1, -8)], [0.9, Vector2(s * 5, -3)]]:
			var from := root.lerp(tip, b[0]) + Vector2(0, -3)
			_stroke(antlers, [from, from + b[1]], 1.0, wood[2])
			tips.append(from + b[1])
		tips.append(tip)
	_outline_layer(antlers)
	_under(canvas, antlers)
	for i in tips.size():
		var t: Vector2 = tips[i]
		_leaf(canvas, t + Vector2(0, 1), t + Vector2(2 if i % 2 == 0 else -2, -5), 2.0, leaf, EPIC_O)
	if st.f % 4 < 2:
		_sparkle(canvas, Vector2i(tips[3]) + Vector2i(0, -6), core)

# Nestling: huge feathered wings spread from its shoulders, the long flight feathers fanned out.
func _epic_wings(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var ramp := _ramp(cfg.tint)
	var dy: int = st.dy
	var lift: float = [0.0, -1.0, -2.0, -1.0, 0.0, 1.0, 1.0, 0.0][st.f % 8] if st.attack < 0 else -3.0
	var wings := _layer()
	for s: int in [-1, 1]:
		var root := Vector2(31.5 + s * 10, 20 + dy)
		for k in 6:
			var a: float = deg_to_rad(-80.0 + k * 22.0)
			var d := Vector2(cos(a) * s, sin(a))
			var len: float = 26.0 - absf(k - 2) * 3.0
			_leaf(wings, root, root + d * len + Vector2(0, lift * (1.0 - k / 6.0)), 3.6, ramp, EPIC_O)
		# The covert feathers over their roots.
		_ellipse(wings, root + Vector2(s * 6, -4), Vector2(7, 4.5), ramp)
	_outline_layer(wings)
	_under(canvas, wings)
	for s: int in [-1, 1]:
		_px(canvas, int(31.5 + s * 20), 4 + dy, core)  # a glint on each wing

# Whirligig: a wind vortex spiralling up round it, the back of each ribbon behind it, leaves riding it.
func _epic_vortex(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var ramp := _ramp(cfg.tint)
	var leaf := _ramp(cfg.get("leaf", ["#34643c", "#5c944c", "#9cc46c", "#d4ec9c"]))
	var back := _layer()
	var front := _layer()
	for ribbon in 2:
		for i in 140:
			var t := i / 139.0
			var a: float = t * TAU * 1.6 + ribbon * PI + st.f * TAU / 8.0
			var r := 26.0 - t * 8.0
			var p := Vector2(31.5 + cos(a) * r, 46 - t * 50.0 + sin(a) * 5.0)
			var target := front if sin(a) > 0.0 else back
			var col := ramp[2] if i % 6 < 4 else ramp[3]
			_px(target, roundi(p.x), roundi(p.y), col)
			_px(target, roundi(p.x), roundi(p.y) + 1, ramp[1])
	_outline_layer(back)
	_under(canvas, back)
	_outline_layer(front)
	for y in range(-OY, S):
		for x in S:
			var c := _gp(front, x, y)
			if c.a > 0.0 and c != EPIC_O:
				_sp(canvas, x, y, c)
	for k in 3:
		var a: float = k * TAU / 3.0 + st.f * TAU / 8.0
		var p := Vector2(31.5 + cos(a) * 22.0, 14 + k * 9 + sin(a) * 4.0)
		_leaf(canvas, p, p + Vector2(cos(a + 1.2), sin(a + 1.2)) * 5.0, 1.8, leaf, EPIC_O)

# --- Each final its own take on its family's motif (user: "don't make the same family exactly the
# same as well, but they should tell they came from the same family") ------------------------------
# _epic_final calls _epic_<name> when a final has its own version, else its family's motif.

# Puffball: a cluster of great puffballs on stout stalks rising behind it, puffing spores.
func _epic_puffball(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var grove := _layer()
	var puff := _ramp(cfg.tint)
	for m: Vector3 in [Vector3(8, 14, 5.5), Vector3(17, 0, 7.0), Vector3(46, -2, 7.5), Vector3(55, 12, 5.5)]:
		_stroke(grove, [Vector2(m.x, 40), Vector2(m.x, m.y + m.z)], 1.8, Color("#bca48c"))
		_puffball(grove, Vector2(m.x, m.y), m.z, puff, Color(LAVENDER[0]))
		_px(grove, int(m.x), int(m.y - m.z) + 1, Color("#8c5c34"))
	_outline_layer(grove)
	_under(canvas, grove)
	for k in 6:
		var t := float((st.f + k * 3) % 8) / 8.0
		var src: Vector2 = [Vector2(17, -7), Vector2(46, -9), Vector2(8, 8)][k % 3]
		var p := src + Vector2(sin(t * TAU + k) * (1.0 + t * 4.0), -t * 12.0)
		_px(canvas, roundi(p.x), roundi(p.y), core if k % 2 == 0 else glow)

# Elf Circle: an arch of little glowing mushrooms over it, a fairy ring standing on end.
func _epic_elf_circle(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var arch := _layer()
	var c := Vector2(31.5, 26)
	var cap := _ramp(cfg.tint)
	for k in 11:
		var a: float = PI + k * PI / 10.0
		var p := c + Vector2(cos(a) * 25.0, sin(a) * 28.0)
		_small_shroom(arch, p + Vector2(0, 3), 2.6 + (k % 2) * 0.8, cap, EPIC_O)
	_under(canvas, arch)
	for k in 3:
		if (st.f + k * 3) % 8 < 3:
			_sparkle(canvas, [Vector2i(10, 4), Vector2i(31, -6), Vector2i(53, 4)][k], core)

# Boulderback: two heavy boulders floating low at its shoulders, molten light in their cracks.
func _epic_boulderback(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	for k in 2:
		var bob: float = [0.0, -1.0, -1.0, 0.0, 0.0, 1.0, 1.0, 0.0][(st.f + k * 4) % 8]
		var c: Vector2 = [Vector2(6, 12), Vector2(57, 9)][k] + Vector2(0, bob)
		var pts := PackedVector2Array()
		for i in 7:
			var a := i * TAU / 7.0 + k
			pts.append(c + Vector2(cos(a) * 9.5, sin(a) * 8.5 * (0.85 + (i % 2) * 0.15)))
		_rock(canvas, pts, _ramp(cfg.tint), EPIC_O)
		var crack := [c + Vector2(-4, -3), c + Vector2(-1, 0), c + Vector2(-2, 3), c + Vector2(2, 5)]
		_line(canvas, crack, glow)
		_line(canvas, [c + Vector2(-1, 0), c + Vector2(4, -2)], core)
		for i in 2:
			_px(canvas, int(c.x) - 1 + i * 2, int(c.y) + 9 + (st.f + i) % 3, Color(glow, 0.7))

# Moonstone: three pale rune stones floating round it (the family motif) under a small moon.
func _epic_moonstone(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	_epic_rune_stones(canvas, cfg, st, glow, core)
	var moon := _layer()
	var c := Vector2(48, -4)
	for y in range(-OY, S):
		for x in S:
			var p := Vector2(x + 0.5, y + 0.5)
			if p.distance_to(c) <= 5.0 and p.distance_to(c + Vector2(2.5, -1.5)) > 4.2:
				_sp(moon, x, y, core)
	_outline_layer(moon)
	_under(canvas, moon)

# Rockslide: a ring of rubble swirling round it, big and small stones tumbling.
func _epic_rockslide(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var back := _layer()
	for k in 9:
		var a: float = k * TAU / 9.0 + st.f * TAU / 24.0
		var c := Vector2(31.5 + cos(a) * 28.0, 22 + sin(a) * 13.0 - (k % 3) * 3.0)
		var s: float = [5.5, 3.8, 4.6][k % 3]
		var pts := PackedVector2Array()
		for i in 5:
			var b: float = i * TAU / 5.0 + k + st.f * 0.3
			pts.append(c + Vector2(cos(b), sin(b)) * s)
		_rock(back if sin(a) < 0.0 else canvas, pts, _ramp(cfg.tint), EPIC_O)
		if k % 3 == 0:
			_px(back if sin(a) < 0.0 else canvas, int(c.x), int(c.y) + int(s) + 1, Color(glow, 0.8))
	_under(canvas, back)

# Great Dreamcatcher: a giant hoop behind it, a web strung across it, feathers and beads hanging.
func _epic_great_dreamcatcher(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var hoop := _layer()
	var c := Vector2(31.5, 16 + st.dy)
	var r := 24.0
	for i in 160:
		var a := i * TAU / 160.0
		var p := c + Vector2(cos(a), sin(a)) * r
		if p.y < 34.0:
			_px(hoop, roundi(p.x), roundi(p.y), Color("#8c5c34"))
			_px(hoop, roundi(p.x + cos(a)), roundi(p.y + sin(a)), Color("#bca48c"))
	for k in 8:
		var a: float = PI + k * PI / 7.0
		var a2: float = PI + (k + 3) * PI / 7.0
		if k + 3 <= 7:
			_line(hoop, [c + Vector2(cos(a), sin(a)) * r, c + Vector2(cos(a2), sin(a2)) * r], Color(glow, 0.8))
	_outline_layer(hoop)
	_under(canvas, hoop)
	for s: int in [-1, 1]:
		var top := c + Vector2(s * r, 2)
		_line(canvas, [top, top + Vector2(0, 8)], Color("#bca48c"))
		_leaf(canvas, top + Vector2(0, 8), top + Vector2(s, 16), 2.0, _ramp(["#4c3c74", "#9a84e8", "#ec9cf4", "#fff4dc"]), EPIC_O)
		_px(canvas, int(top.x), int(top.y) + 5, core)

# Whispering Hollow: whispers curling up out of it in pairs of wisps, fading as they rise.
func _epic_whispering_hollow(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var wisps := _layer()
	for s: int in [-1, 1]:
		for k in 2:
			var pts: Array = []
			for i in 24:
				var t := i / 23.0
				var a: float = t * TAU * 1.2 + st.f * TAU / 8.0 + k * PI
				pts.append(Vector2(31.5 + s * (16.0 + k * 7.0 + cos(a) * 4.0), 34 - t * 40.0 + sin(a) * 2.0))
			for i in pts.size() - 1:
				if i % 7 != 6:
					_line(wisps, [pts[i], pts[i + 1]], core if i < 8 else glow)
	_outline_layer(wisps)
	_under(canvas, wisps)
	for k in 2:
		_glyph(canvas, Vector2i([7, 54][k], 2 - (st.f + k * 4) % 8), NOTE_GLYPH, core)

# Morning Fog: a wide shawl of mist over its shoulders, drifting off in wisps, a pale sun behind it.
func _epic_morning_fog(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var sun := _layer()
	_flat_ellipse(sun, Vector2(31.5, 8 + st.dy), Vector2(15, 15), Color("#fff4dc"))
	_flat_ellipse(sun, Vector2(31.5, 8 + st.dy), Vector2(12, 12), Color("#fcd47c"))
	_outline_layer(sun)
	_under(canvas, sun)
	for k in 3:
		_fog(canvas, Vector2([12, 51, 31][k], [24, 22, 40][k]) + Vector2(sin((st.f + k * 3) * TAU / 8.0) * 2.0, st.dy), Vector2(11, 6), core, st.f + k)

# Hoarfrost: a collar of great ice spikes fanned behind its shoulders and a snowflake crown.
func _epic_hoarfrost(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var collar := _layer()
	var gems := _ramp(cfg.tint)
	for k in 7:
		var a: float = PI + 0.25 + k * (PI - 0.5) / 6.0
		var base := Vector2(31.5, 22 + st.dy) + Vector2(cos(a) * 12.0, sin(a) * 6.0)
		var tip := Vector2(31.5, 22 + st.dy) + Vector2(cos(a) * (28.0 - absf(k - 3) * 2.0), sin(a) * (30.0 - absf(k - 3) * 3.0))
		var n := (tip - base).normalized().orthogonal()
		_flat_polygon(collar, PackedVector2Array([base - n * 3.0, tip, base + n * 3.0]), gems[1])
		_line(collar, [base, tip], gems[3])
	_outline_layer(collar)
	_under(canvas, collar)
	var flake := Vector2i(31, -4 + st.dy)
	for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN, Vector2i(-1, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1)]:
		_px(canvas, flake.x + d.x * 2, flake.y + d.y * 2, glow)
		_px(canvas, flake.x + d.x, flake.y + d.y, core)

# Thunderhead: a ring of crackling lightning round it, a different path every frame.
func _epic_thunderhead(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var back := _layer()
	var pts: Array = []
	for k in 7:
		var a: float = k * TAU / 7.0 + st.f * 0.4
		pts.append(Vector2(31.5 + cos(a) * 27.0, 26 + sin(a) * 11.0))
	for k in 7:
		if (k + st.f) % 3 == 0:
			continue
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[(k + 1) % 7]
		_bolt(back if (a.y + b.y) * 0.5 < 26.0 else canvas, a, b, core, glow, 3)
	_under(canvas, back)
	for p: Vector2 in pts:
		_glow_dot(canvas, Vector2i(p.round()), core, glow)

# Midsummer: sun rays fanned behind it and warm petals drifting round it.
func _epic_midsummer(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var rays := _layer()
	var c := Vector2(31.5, 18 + st.dy)
	for k in 11:
		var a: float = PI + 0.15 + k * (PI - 0.3) / 10.0
		var d := Vector2(cos(a), sin(a))
		var len := 30.0 if k % 2 == 0 else 23.0
		_stroke(rays, [c + d * 16.0, c + d * len], 1.4 if k % 2 == 0 else 0.9, glow if k % 2 == 0 else core)
	_outline_layer(rays)
	_under(canvas, rays)
	for k in 5:
		var t := float((st.f + k * 2) % 8) / 8.0
		var p := Vector2([6, 57, 12, 50, 31][k] + sin(t * TAU + k) * 2.0, 30 - t * 20.0 - (k % 2) * 6)
		_leaf(canvas, p, p + Vector2(2, -2), 1.2, _ramp(["#b8662c", "#e9a83c", "#fcd47c"]), EPIC_O)

# Long Way Home: roots sprawled out over the slab and beyond it like a map of ways home, curling up
# at the ends round little lights.
func _epic_long_way_home(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var wood := _ramp(cfg.tint)
	var roots := _layer()
	for s: int in [-1, 1]:
		_stroke(roots, [Vector2(31.5 + s * 10, 40), Vector2(31.5 + s * 22, 38), Vector2(31.5 + s * 29, 30), Vector2(31.5 + s * 28, 20), Vector2(31.5 + s * 23, 21)], 2.6, wood[3])
		_stroke(roots, [Vector2(31.5 + s * 18, 30), Vector2(31.5 + s * 22, 12), Vector2(31.5 + s * 18, 2), Vector2(31.5 + s * 14, 5)], 1.8, wood[2])
	_outline_layer(roots)
	_under(canvas, roots)
	for p: Vector2i in [Vector2i(8, 21), Vector2i(55, 21), Vector2i(13, 4), Vector2i(50, 4)]:
		if (st.f + p.x) % 4 < 2:
			_glow_dot(canvas, p, core, glow)
		else:
			_px(canvas, p.x, p.y, glow)

# Snugroot: the root throne (the family motif).
func _epic_snugroot(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	_epic_root_throne(canvas, cfg, st, glow, core)

# Starcave: the root throne grown through with violet crystals.
func _epic_starcave(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	_epic_root_throne(canvas, cfg, st, glow, core)
	var gems := _ramp(["#4c3c74", "#9a84e8", "#dce8f4"])
	var back := _layer()
	for c: Vector4 in [Vector4(8, 28, 8, -2), Vector4(55, 26, 9, 2), Vector4(14, 8, 6, -1), Vector4(49, 6, 6, 1)]:
		_prism(back, Vector2(c.x, c.y), 2.4, c.z, c.w, gems, EPIC_O)
	_under(canvas, back)

# Grove Heart: leafy antlers (the family motif).
func _epic_grove_heart(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	_epic_antlers(canvas, cfg, st, glow, core)

# Wellspring: antlers of living water, branching like coral, drops at the tips.
func _epic_wellspring(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var water := _ramp(["#2c4c5c", "#4c8ca4", "#9cd4fc", "#dce8f4"])
	var dy: int = st.dy
	var coral := _layer()
	var tips: Array = []
	for s: int in [-1, 1]:
		var root := Vector2(31.5 + s * 8, 10 + dy)
		var mid := root + Vector2(s * 8, -10)
		_stroke(coral, [root, mid, mid + Vector2(s * 9, -4)], 1.6, water[1])
		_stroke(coral, [mid, mid + Vector2(s * 1, -10)], 1.2, water[2])
		_stroke(coral, [root.lerp(mid, 0.5), root.lerp(mid, 0.5) + Vector2(s * 9, 2)], 1.0, water[2])
		tips.append_array([mid + Vector2(s * 9, -4), mid + Vector2(s * 1, -10), root.lerp(mid, 0.5) + Vector2(s * 9, 2)])
	_outline_layer(coral)
	_under(canvas, coral)
	for i in tips.size():
		var t: Vector2 = tips[i]
		var fall: int = (st.f + i * 3) % 8
		_px(canvas, int(t.x), int(t.y) - 1, core)
		_px(canvas, int(t.x), int(t.y) + fall, Color(glow, 1.0 - fall / 8.0))

# Grafted Elder: antlers hung with blossoms and little grafted fruits.
func _epic_grafted_elder(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var wood := _ramp(cfg.tint)
	var dy: int = st.dy
	var antlers := _layer()
	var tips: Array = []
	for s: int in [-1, 1]:
		var root := Vector2(31.5 + s * 7, 8 + dy)
		var tip := root + Vector2(s * 20, -12)
		_stroke(antlers, [root, root + Vector2(s * 10, -5), tip], 1.5, wood[1])
		for b: Array in [[0.4, Vector2(s * 3, -8)], [0.75, Vector2(s * 4, 5)]]:
			var from := root.lerp(tip, b[0])
			_stroke(antlers, [from, from + b[1]], 1.0, wood[2])
			tips.append(from + b[1])
		tips.append(tip)
	_outline_layer(antlers)
	_under(canvas, antlers)
	for i in tips.size():
		var t: Vector2 = tips[i]
		if i % 3 == 1:
			var fruit := _layer()
			_ellipse(fruit, t + Vector2(0, 3), Vector2(2.4, 2.4), _ramp(["#b8662c", "#e9a83c", "#fcd47c"]))
			_stamp(canvas, fruit, EPIC_O)
		else:
			for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				_px(canvas, int(t.x) + d.x, int(t.y) + d.y, Color("#ec9cf4"))
			_px(canvas, int(t.x), int(t.y), Color("#fcd47c"))

# Starling Murmuration: the great dark wings (the family motif).
func _epic_starling_murmuration(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	_epic_wings(canvas, cfg, st, glow, core)

# Magpie's Hoard: pied wings, white-banded, gold glinting in the feathers and spilling below.
func _epic_magpies_hoard(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var dy: int = st.dy
	var lift: float = [0.0, -1.0, -2.0, -1.0, 0.0, 1.0, 1.0, 0.0][st.f % 8] if st.attack < 0 else -3.0
	var wings := _layer()
	for s: int in [-1, 1]:
		var root := Vector2(31.5 + s * 10, 22 + dy)
		for k in 5:
			var a: float = deg_to_rad(-60.0 + k * 22.0)
			var d := Vector2(cos(a) * s, sin(a))
			var ramp := _ramp(["#140f26", "#24243c", "#3c3c5c", "#4c8ca4"]) if k > 1 else _ramp(["#b4b0c8", "#dce8f4", "#dce8f4", "#ffffff"])
			_leaf(wings, root, root + d * (24.0 - k * 2.0) + Vector2(0, lift), 3.8, ramp, EPIC_O)
	_outline_layer(wings)
	_under(canvas, wings)
	for p: Vector2i in [Vector2i(9, 14), Vector2i(54, 16), Vector2i(13, 30), Vector2i(50, 28)]:
		if (st.f + p.x) % 4 < 2:
			_sparkle(canvas, p + Vector2i(0, dy), core)
	for p: Vector2i in [Vector2i(10, 44), Vector2i(13, 45), Vector2i(50, 46), Vector2i(53, 45)]:
		_px(canvas, p.x, p.y, Color("#fcd47c"))
		_px(canvas, p.x + 1, p.y, Color("#e9a83c"))

# Jewelwing Court: four jewelled dragonfly wings, clear and veined, shimmering.
func _epic_jewelwing_court(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var dy: int = st.dy
	var flick: float = [0.0, 1.0, 0.0, -1.0][st.f % 4]
	var wings := _layer()
	var shimmer := [Color("#9cd4fc"), Color("#ec9cf4"), Color("#d4ec9c")]
	for s: int in [-1, 1]:
		for k in 2:
			var root := Vector2(31.5 + s * 8, 18 + dy + k * 5)
			var tip := root + Vector2(s * (24.0 - k * 4.0), -10.0 + k * 14.0 + flick)
			_leaf(wings, root, tip, 4.6 - k * 0.6, _ramp(["#2c4c5c", "#4c8ca4", "#9cd4fc", "#dce8f4"]), EPIC_O)
			_line(wings, [root, tip], Color(shimmer[(st.f + k) % 3]))
	_outline_layer(wings)
	_under(canvas, wings)

# Zephyr: wind ribbons spiralling round it (the family motif).
func _epic_zephyr(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	_epic_vortex(canvas, cfg, st, glow, core)

# Windmill: a great sail wheel turning behind it, four canvas sails on a wooden cross.
func _epic_windmill(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var wheel := _layer()
	var c := Vector2(31.5, 12 + st.dy)
	var turn: float = st.f * TAU / 32.0
	for k in 4:
		var a: float = turn + k * TAU / 4.0
		var d := Vector2(cos(a), sin(a))
		var n := d.orthogonal()
		_stroke(wheel, [c, c + d * 28.0], 1.0, Color("#8c5c34"))
		_flat_polygon(wheel, PackedVector2Array([c + d * 9.0, c + d * 27.0, c + d * 27.0 + n * 6.5, c + d * 9.0 + n * 5.0]), Color("#dccdb2"))
		for i in range(10, 27, 4):
			_line(wheel, [c + d * i, c + d * i + n * 5.5], Color("#bca48c"))
	_outline_layer(wheel)
	_under(canvas, wheel)

# Autumn Gale: a storm of autumn leaves whirling round it, no ribbons, only leaves.
func _epic_autumn_gale(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var leaf := _ramp(cfg.leaf)
	var back := _layer()
	for k in 16:
		var a: float = k * TAU / 16.0 + st.f * TAU / 16.0
		var h := 42.0 - (k % 8) * 6.5
		var p := Vector2(31.5 + cos(a) * (28.0 - (k % 8) * 1.2), h + sin(a) * 6.0)
		var dir := Vector2(cos(a + 1.6), sin(a + 1.6)) * 7.5
		_leaf(back if sin(a) < 0.0 else canvas, p, p + dir, 3.0, leaf, EPIC_O)
		if k % 4 == 0:
			_line(back if sin(a) < 0.0 else canvas, [p - dir * 0.6, p - dir * 1.4], glow)
	_under(canvas, back)

# A small mushroom: a pale stem and a round cap.
func _small_shroom(canvas: Image, p: Vector2, s: float, cap: Array[Color], o: Color) -> void:
	var layer := _layer()
	_flat_ellipse(layer, p + Vector2(0, -s * 0.8), Vector2(s * 0.45, s * 0.9), Color("#f0e4d8"))
	_ellipse(layer, p + Vector2(0, -s * 1.7), Vector2(s * 1.1, s * 0.75), cap, p.y - s * 1.55)
	_stamp(canvas, layer, o)
	_px(canvas, int(p.x), int(p.y - s * 2.0), cap[cap.size() - 1])

# --- The branch expansion's finals (2026-10-02), each its own take on its family's motif ----------

# Old Lichen: shelf fungi stacked up two old stumps behind it, crusted with lichen.
func _epic_old_lichen(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var back := _layer()
	var tint := _ramp(cfg.tint)
	for s: int in [-1, 1]:
		var x := 31.5 + s * 23.0
		_stroke(back, [Vector2(x, 42), Vector2(x - s, 4)], 2.6, Color("#5c3c24"))
		for k in 4:
			var y := 34.0 - k * 9.0
			_bracket(back, Vector2(x - s * 4.0, y), 6.5 - k * 0.6, EPIC_O)
	_outline_layer(back)
	_under(canvas, back)
	for p: Vector2i in [Vector2i(9, 6), Vector2i(54, 10), Vector2i(10, 24), Vector2i(53, 28)]:
		_px(canvas, p.x, p.y, core)

# Hatchery: glowing brood pods on stalks behind it, little sprites peeking out of the open ones.
func _epic_hatchery(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var back := _layer()
	var pod := _ramp(cfg.tint)
	var pods: Array = [Vector3(9, 12, 5.0), Vector3(19, -2, 6.0), Vector3(44, -4, 6.0), Vector3(54, 10, 5.0)]
	for m: Vector3 in pods:
		_stroke(back, [Vector2(m.x, 40), Vector2(m.x, m.y + m.z)], 1.4, Color("#5c944c"))
		_ellipse(back, Vector2(m.x, m.y), Vector2(m.z * 0.8, m.z), pod)
	_outline_layer(back)
	_under(canvas, back)
	for i in pods.size():
		var m: Vector3 = pods[i]
		var open: bool = (st.f + i * 2) % 8 < 4
		if open:
			_px(canvas, int(m.x) - 1, int(m.y) - 1, EPIC_O)
			_px(canvas, int(m.x) + 1, int(m.y) - 1, EPIC_O)
			_px(canvas, int(m.x), int(m.y) + 1, core)
		else:
			_px(canvas, int(m.x), int(m.y), glow)

# Deliquescent: tall drooping ink caps behind it, their rims melting into falling drops of ink.
func _epic_deliquescent(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	# Shaggy ink caps clustered either side of it: tall white caps melting black at the hem, ink dripping.
	var caps := _layer()
	var drips: Array = []
	for m: Vector3 in [Vector3(9, 40, 1.0), Vector3(15, 43, 0.75), Vector3(4, 44, 0.6), Vector3(54, 40, 1.0), Vector3(48, 43, 0.75), Vector3(59, 44, 0.6)]:
		var h := 16.0 * m.z
		var w := 4.5 * m.z + 1.0
		var foot := Vector2(m.x, m.y)
		_stroke(caps, [foot, foot + Vector2(0, -h * 0.4)], 0.8, Color("#dccdb2"))
		var top := foot + Vector2(0, -h)
		for y in range(int(top.y), int(foot.y - h * 0.3)):
			var t := (y - top.y) / (h * 0.7)
			var half := w * sqrt(clampf(t * 1.6, 0.0, 1.0))
			for x in range(int(m.x - half), int(m.x + half) + 1):
				var ink: bool = t > 0.72 or (t > 0.5 and (x + y) % 3 == 0)
				_px(caps, x, y, Color("#24243c") if ink else (Color("#fff4dc") if x < m.x else Color("#dccdb2")))
		drips.append(Vector2(m.x, foot.y - h * 0.3))
	_outline_layer(caps)
	_under(canvas, caps)
	for k in drips.size():
		var d: Vector2 = drips[k]
		var fall: int = (st.f + k * 3) % 8
		_px(canvas, int(d.x) + (k % 2) * 2 - 1, int(d.y) + 1 + fall, Color("#24243c") if fall < 5 else glow)


# Vesper Bell: two silver bells hung from an arch behind it, swinging, the evening star above.
func _epic_vesper_bell(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var back := _layer()
	var c := Vector2(31.5, 18 + st.dy)
	for i in 120:
		var a := PI + i * PI / 119.0
		var p := c + Vector2(cos(a) * 25.0, sin(a) * 22.0)
		_px(back, roundi(p.x), roundi(p.y), Color("#8c5c34"))
		_px(back, roundi(p.x), roundi(p.y) + 1, Color("#5c3c24"))
	_outline_layer(back)
	_under(canvas, back)
	var swing: int = [0, 1, 0, -1][st.f % 4]
	for s: int in [-1, 1]:
		var top := c + Vector2(s * 17, -14)
		_line(canvas, [top, top + Vector2(swing, 4)], EPIC_O)
		_bell(canvas, top + Vector2(swing, 4), 4.2, swing, _ramp(["#8c8cac", "#b4b0c8", "#dce8f4", "#ffffff"]), EPIC_O)
	_sparkle(canvas, Vector2i(c + Vector2(0, -26)), core if st.f % 4 < 2 else glow)

# Silence: a ring of sound falling still: dim and broken behind it, its pieces sinking as motes.
func _epic_silence(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var back := _layer()
	var c := Vector2(31.5, 16 + st.dy)
	for i in 64:
		if i % 8 >= 5:
			continue
		var a := PI + 0.2 + i * (PI - 0.4) / 63.0
		var p := c + Vector2(cos(a), sin(a)) * 22.0
		_flat_ellipse(back, p, Vector2(1.6, 1.6), Color("#2c2444"))
		_px(back, roundi(p.x), roundi(p.y), glow)
	_outline_layer(back)
	_under(canvas, back)
	for k in 6:
		var t := float((st.f + k * 3) % 8) / 8.0
		var a: float = PI + 0.4 + k * (PI - 0.8) / 5.0
		var p := c + Vector2(cos(a), sin(a)) * 22.0 + Vector2(0, t * 10.0)
		_px(canvas, roundi(p.x), roundi(p.y), Color(core, 1.0 - t * 0.8))

# Resonance: a fan of horn flowers behind it, turned outward, rings rolling out of them.
func _epic_resonance(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var back := _layer()
	var c := Vector2(31.5, 24 + st.dy)
	var horns: Array = []
	for k in 5:
		var a: float = PI + 0.4 + k * (PI - 0.8) / 4.0
		var d := Vector2(cos(a), sin(a))
		_leaf(back, c + d * 10.0, c + d * 29.0, 5.5, _ramp(["#4c3c74", "#9a84e8", "#ec9cf4", "#fff4dc"]), EPIC_O)
		horns.append(c + d * 27.0)
	_under(canvas, back)
	var t := float(st.f % 4) / 4.0
	for h: Vector2 in horns:
		var d := (h - c).normalized()
		var p := h + d * (2.0 + t * 4.0)
		var n := d.orthogonal()
		_line(canvas, [p - n * 2.0, p + n * 2.0], Color(glow, 1.0 - t * 0.6))

# Nimbus: a halo of cloud round its head, raining down past its shoulders.
func _epic_nimbus(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var back := _layer()
	var c := Vector2(31.5, 14 + st.dy)
	for k in 7:
		var a: float = PI + 0.2 + k * (PI - 0.4) / 6.0
		_cloud(back, c + Vector2(cos(a) * 25.0, sin(a) * 22.0), 14.0, _ramp(["#8c8cac", "#b4b0c8", "#dce8f4", "#ffffff"]), Color("#3c3c5c"))
	_under(canvas, back)
	for k in 6:
		var x: int = [8, 13, 18, 45, 50, 55][k]
		var y: int = 16 + (st.f * 3 + k * 5) % 22
		_px(canvas, x, y, glow)
		_px(canvas, x, y + 1, core)

# Maelstrom: a waterspout twisting up behind it out of its whirlpool, spray flung off the top.
func _epic_maelstrom(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	# A waterspout behind it: a funnel of water rising out of the whirlpool and flaring at the top,
	# white foam spiralling up it, spray flung off the rim.
	var tint := _ramp(cfg.tint)
	var spout := _layer()
	var turn: float = st.f * TAU / 8.0
	for y in range(-14, 42):
		var t := (41.0 - y) / 55.0
		var half := 3.0 + t * t * 15.0
		var cx := 31.5 + sin(t * 5.0 + turn) * 1.5
		for x in range(int(cx - half), int(cx + half) + 1):
			var u := (x - cx) / half
			var foam: bool = fposmod(asin(clampf(u, -1.0, 1.0)) / PI + t * 3.0 - turn / TAU, 0.5) < 0.09
			_px(spout, x, y, Color("#e8faff") if foam else (tint[2] if u < -0.3 else (tint[1] if u < 0.4 else tint[0])))
	_outline_layer(spout)
	_under(canvas, spout)
	for k in 6:
		var a: float = k * TAU / 6.0 + st.f * 0.5
		_px(canvas, roundi(31.5 + cos(a) * 20.0), roundi(-15 + sin(a) * 3.0 - (st.f + k) % 3), core)



# Torrent: jets of water arcing up out of the slab either side of it and falling back.
func _epic_torrent(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var tint := _ramp(cfg.tint)
	var back := _layer()
	for s: int in [-1, 1]:
		for j in 2:
			var from := Vector2(31.5 + s * (14 + j * 6), 40)
			var pts: Array = []
			for i in 16:
				var t := i / 15.0
				pts.append(from + Vector2(s * t * (10.0 + j * 4.0), -t * (40.0 - j * 10.0) + t * t * (24.0 - j * 6.0)))
			for i in pts.size() - 1:
				_stroke(back, [pts[i], pts[i + 1]], 1.2, tint[2])
				_line(back, [pts[i] + Vector2(-s, 0), pts[i + 1] + Vector2(-s, 0)], tint[3])
	_outline_layer(back)
	_under(canvas, back)
	for k in 4:
		_px(canvas, [4, 59, 8, 55][k], 34 + (st.f + k * 2) % 8, core)

# Lightning Fence: three jars of light floating round it, arcs crackling between them.
func _epic_lightning_fence(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var jars: Array = []
	for k in 3:
		var bob: float = [0.0, -1.0, -1.0, 0.0, 0.0, 1.0, 1.0, 0.0][(st.f + k * 3) % 8]
		jars.append([Vector2(4, 2), Vector2(31.5, -12), Vector2(59, 0)][k] + Vector2(0, bob))
	var back := _layer()
	for k in 2:
		if (st.f + k) % 3 != 0:
			_bolt(back, jars[k], jars[k + 1], core, glow, 4)
	_under(canvas, back)
	for p: Vector2 in jars:
		var jar := _layer()
		_round_rect(jar, Rect2i(int(p.x) - 3, int(p.y) - 3, 7, 8), 2, Color("#4c8ca4"))
		_stamp(canvas, jar, EPIC_O)
		_round_rect(canvas, Rect2i(int(p.x) - 2, int(p.y) - 5, 5, 2), 0, Color("#8c5c34"))
		_glow_dot(canvas, Vector2i(p) + Vector2i(0, 1), core, glow)

# Rainbow Prism: rainbow rays fanned behind it out of a crystal over its head.
func _epic_rainbow_prism(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var rays := _layer()
	var c := Vector2(31.5, 14 + st.dy)
	var cols := [Color("#ec9cf4"), Color("#fcd47c"), Color("#d4ec9c"), Color("#9cd4fc"), Color("#9a84e8")]
	for k in 10:
		var a: float = PI + 0.15 + k * (PI - 0.3) / 9.0
		var d := Vector2(cos(a), sin(a))
		_stroke(rays, [c + d * 14.0, c + d * (28.0 if k % 2 == 0 else 23.0)], 1.2, cols[(k + int(st.f) / 2) % cols.size()])
	_outline_layer(rays)
	_under(canvas, rays)
	_prism(canvas, c + Vector2(0, -8), 2.6, 7.0, 0.0, _ramp(["#4c8ca4", "#9cd4fc", "#ffffff"]), EPIC_O)

# Starburst: fireworks bursting over it in turn, sparks falling.
func _epic_starburst(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var cols := [Color("#ec9cf4"), Color("#fcd47c"), Color("#9cd4fc")]
	for k in 3:
		var age: int = (st.f + k * 3) % 8
		if age > 5:
			continue
		var c: Vector2 = [Vector2(10, 4), Vector2(31.5, -8), Vector2(53, 2)][k]
		var r := 3.0 + age * 3.0
		for i in 10:
			var d := Vector2.from_angle(i * TAU / 10.0 + k)
			var p := c + d * r + Vector2(0, age * age * 0.25)
			_px(canvas, roundi(p.x), roundi(p.y), core if age < 3 else cols[k])
			if age < 4:
				var q := c + d * (r - 2.0)
				_px(canvas, roundi(q.x), roundi(q.y), cols[k])
		if age == 0:
			_glow_dot(canvas, Vector2i(c), core, glow)

# --- The branch expansion's own bodies (user 2026-10-02: the new Wardens "look too similar to each
# other to begin with, even the pre evolution") ----------------------------------------------------
# Each new branch has its own body material (the original branches stand apart the same way); its
# final is a richer take on the same material. Applied wherever the template figure and its face are
# drawn, so every body helper picks it up.
const BODY_PAL := {
	"lichenling": ["#1c3c2c", "#9cc46c", "#5c944c", "#34643c"],
	"old_lichen": ["#1c3c2c", "#d4ec9c", "#9cc46c", "#5c944c"],
	"brood_cap": ["#140f26", "#9a84e8", "#4c3c74", "#2c2444"],
	"hatchery": ["#140f26", "#dce8f4", "#9a84e8", "#4c3c74"],
	"inkcap": ["#3c3c5c", "#dccdb2", "#b4a494", "#6c5c5c"],
	"deliquescent": ["#24243c", "#b4b0c8", "#8c8cac", "#5c5a78"],
	"cloudlet": ["#3c3c5c", "#dce8f4", "#b4b0c8", "#8c8cac"],
	"nimbus": ["#24243c", "#b4b0c8", "#8c8cac", "#5c5a78"],
	"undercurrent": ["#140f26", "#4c8ca4", "#2c4c5c", "#24243c"],
	"maelstrom": ["#140f26", "#9cd4fc", "#4c8ca4", "#2c4c5c"],
	"jetreed": ["#1c3c2c", "#9cc46c", "#5c944c", "#2c4c5c"],
	"torrent": ["#1c3c2c", "#d4ec9c", "#9cc46c", "#34643c"],
	"jarlink": ["#241c14", "#e9a83c", "#b8662c", "#5c3c24"],
	"lightning_fence": ["#241c14", "#fcd47c", "#e9a83c", "#b8662c"],
	"prism_jar": ["#2c4c5c", "#dce8f4", "#9cd4fc", "#4c8ca4"],
	"rainbow_prism": ["#2c4c5c", "#fff4dc", "#dce8f4", "#9cd4fc"],
	"sparkler": ["#140f26", "#ec9cf4", "#bc44dc", "#4c3c74"],
	"starburst": ["#140f26", "#fff4dc", "#ec9cf4", "#bc44dc"],
	"silver_bell": ["#24243c", "#8c8cac", "#5c5a78", "#3c3c5c"],
	"vesper_bell": ["#140f26", "#9a84e8", "#4c3c74", "#2c2444"],
	"hushbell": ["#1c3c2c", "#9cc46c", "#5c944c", "#34643c"],
	"silence": ["#140f26", "#5c944c", "#34643c", "#1c3c2c"],
	"thrum": ["#140f26", "#ec9cf4", "#bc44dc", "#4c3c74"],
	"resonance": ["#140f26", "#fff4dc", "#ec9cf4", "#bc44dc"],
	"whetstone": ["#241c14", "#dccdb2", "#b4a494", "#6c5c5c"],
	"edgestone": ["#241c14", "#fff4dc", "#dccdb2", "#b4a494"],
	"rampart": ["#24243c", "#b4b0c8", "#8c8cac", "#5c5a78"],
	"bastion": ["#140f26", "#8c8cac", "#5c5a78", "#3c3c5c"],
	"quaker": ["#241c14", "#bca48c", "#8c5c34", "#5c3c24"],
	"earthshaker": ["#140f26", "#8c5c34", "#5c3c24", "#241c14"],
	"groundroot": ["#24160e", "#dccdb2", "#bca48c", "#8c5c34"],
	"earthbind": ["#24160e", "#fff4dc", "#dccdb2", "#bca48c"],
	"deeproot": ["#241c14", "#b8662c", "#8c5c34", "#5c3c24"],
	"heartroot": ["#241c14", "#e9a83c", "#b8662c", "#5c3c24"],
	"thorncoil": ["#1c3c2c", "#5c944c", "#34643c", "#241c14"],
	"crown_of_thorns": ["#1c3c2c", "#9cc46c", "#5c944c", "#34643c"],
	"seedbearer": ["#241c14", "#b8662c", "#8c5c34", "#5c3c24"],
	"grove_keeper": ["#241c14", "#e9a83c", "#b8662c", "#8c5c34"],
	"nurse_log": ["#1c3c2c", "#9cc46c", "#5c944c", "#5c3c24"],
	"mother_log": ["#1c3c2c", "#d4ec9c", "#9cc46c", "#5c944c"],
	"dream_oak": ["#140f26", "#9a84e8", "#4c3c74", "#2c2444"],
	"dreamroot": ["#140f26", "#ec9cf4", "#9a84e8", "#4c3c74"],
}

# The figure palette a Warden's body is drawn in: its own (BODY_PAL) or the one its helper passed.
func _body_pal(pal: Dictionary) -> Dictionary:
	if not BODY_PAL.has(_warden_name):
		return pal
	var p: Array = BODY_PAL[_warden_name]
	return _pal(p[0], p[1], p[2], p[3])

# A bracket fungus (turkey tail): a flat half-disc shelf banded in rings of rust, gold and cream, its
# dark gills along the underside.
func _bracket(canvas: Image, c: Vector2, w: float, o: Color) -> void:
	var layer := _layer()
	var bands := [Color("#b8662c"), Color("#e9a83c"), Color("#fcd47c"), Color("#fff4dc")]
	for y in range(int(c.y - 4.0), int(c.y) + 2):
		for x in range(int(c.x - w) - 1, int(c.x + w) + 2):
			var d := ((Vector2(x + 0.5, y + 0.5) - c) / Vector2(w, 3.6)).length()
			if d > 1.0 or y + 0.5 > c.y + 1.0:
				continue
			_px(layer, x, y, Color("#5c3c24") if y + 0.5 > c.y else bands[clampi(int((1.0 - d) * 4.0), 0, 3)])
	_stamp(canvas, layer, o)

# --- Phase 2, Pebbling (tower_design.md 7816b7e0): Whetstone -> Edgestone (the finisher, a golem at a
# sharpening wheel), Rampart -> Bastion (a golem built into a stone wall, one arm a wall block),
# Quaker -> Earthshaker (a squat golem mid-stomp, fists down). Bodies from BODY_PAL. ------------------

func _p2_fig() -> Dictionary:
	return _body_pal(_pal("#000000", "#000000", "#000000", "#000000"))

# A grindstone on a wooden frame, seen three-quarter, turning (a notch runs round its rim), a crank
# and sparks flying off the top while it grinds.
func _grind_wheel(canvas: Image, st: Dictionary, c: Vector2, r: float, o: Color, sparks: int) -> void:
	var wood := _layer()
	_stroke(wood, [Vector2(c.x - 6, 46), c + Vector2(0, 2)], 1.2, Color("#8c5c34"))
	_stroke(wood, [Vector2(c.x + 6, 46), c + Vector2(0, 2)], 1.2, Color("#8c5c34"))
	_stamp(canvas, wood, o)
	var wheel := _layer()
	_ellipse(wheel, c, Vector2(r * 0.55, r), _ramp(["#5c5a78", "#8c8cac", "#b4b0c8", "#dce8f4"]))
	_stamp(canvas, wheel, o)
	_flat_ellipse(canvas, c, Vector2(1.4, 1.6), Color("#3c3c5c"))
	var a: float = st.f * TAU / 8.0
	_px(canvas, roundi(c.x + cos(a) * r * 0.45), roundi(c.y + sin(a) * r * 0.85), Color("#3c3c5c"))
	var crank := _layer()
	_stroke(crank, [c, c + Vector2(r * 0.55 + 3, -1), c + Vector2(r * 0.55 + 3, 3)], 0.7, Color("#8c5c34"))
	_stamp(canvas, crank, o)
	for k in sparks:
		if (st.f + k) % 3 == 0:
			continue
		var t := float((st.f + k * 2) % 4) / 4.0
		var p := c + Vector2(-2 - k * 2 - t * 4, -r - 1 - t * 3)
		_px(canvas, roundi(p.x), roundi(p.y), Color("#fcd47c") if k % 2 == 0 else Color("#fff4dc"))

func _draw_whetstone(canvas: Image, st: Dictionary) -> void:
	var fig := _p2_fig()
	var dy: int = st.dy
	_pebble_golem(canvas, st, fig, false)
	_golem_face(canvas, st, fig)
	# A leather apron and the stone it's sharpening in its hand.
	var apron := _layer()
	_flat_polygon(apron, PackedVector2Array([Vector2(25, 26 + dy), Vector2(36, 26 + dy), Vector2(37, 35), Vector2(24, 35)]), Color("#b8662c"))
	_stamp(canvas, apron, fig.o)
	_line(canvas, [Vector2(24, 24 + dy), Vector2(30, 18 + dy), Vector2(37, 24 + dy)], Color("#5c3c24"))
	_grind_wheel(canvas, st, Vector2(52, 30), 9.0, fig.o, 3)

func _draw_edgestone(canvas: Image, st: Dictionary) -> void:
	var fig := _p2_fig()
	var dy: int = st.dy
	# A great stone blade strapped across its back (behind it), honed to a pale edge.
	_pebble_golem(canvas, st, fig, true, func(c: Image, s: Dictionary, _f: Dictionary) -> void:
		var blade := _layer()
		_flat_polygon(blade, PackedVector2Array([Vector2(8, 40), Vector2(12, 42), Vector2(46, 2 + s.dy), Vector2(44, -2 + s.dy)]), Color("#b4b0c8"))
		_line(blade, [Vector2(9, 39), Vector2(44, -1 + s.dy)], Color("#ffffff"))
		_stamp(c, blade, Color("#140f26")))
	_golem_face(canvas, st, fig)
	var strap := _layer()
	_stroke(strap, [Vector2(19, 22 + dy), Vector2(40, 34)], 1.0, Color("#5c3c24"))
	_stamp(canvas, strap)
	_grind_wheel(canvas, st, Vector2(52, 29), 11.0, fig.o, 5)

func _attack_whetstone(canvas: Image, st: Dictionary) -> void:
	_clean_cut(canvas, st, 1.0)

func _attack_edgestone(canvas: Image, st: Dictionary) -> void:
	_clean_cut(canvas, st, 1.3)

# The clean cut: a bright crescent slash sweeping across in front of it, a trailing edge, a glint.
func _clean_cut(canvas: Image, st: Dictionary, size: float) -> void:
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	var c := Vector2(36, 26)
	var r := 18.0 * size
	var a0: float = -2.2 + k * 0.5
	for i in 30:
		var t := i / 29.0
		var a := a0 + t * 1.9
		var w: float = sin(t * PI) * (3.0 if k == 0 else 2.0)
		for j in range(0, int(w) + 1):
			var p := c + Vector2(cos(a), sin(a)) * (r - j)
			_px(canvas, roundi(p.x), roundi(p.y), Color("#ffffff") if j == 0 else (Color("#dce8f4") if j == 1 else Color("#9cd4fc")))
	if k == 0:
		var tip := c + Vector2(cos(a0 + 1.9), sin(a0 + 1.9)) * r
		_sparkle(canvas, Vector2i(tip.round()), Color("#ffffff"))
		_warm_glow(canvas, tip, Vector2(6, 5))

# A stretch of castle wall behind it: coursed stone, crenellated along the top.
func _castle_wall(canvas: Image, top: int, x0: int, x1: int, o: Color, pale: bool = false) -> void:
	var wall := _layer()
	var stone := [Color("#b4a494"), Color("#dccdb2"), Color("#6c5c5c")] if pale else [Color("#8c8cac"), Color("#b4b0c8"), Color("#5c5a78")]
	for y in range(top, 42):
		for x in range(x0, x1 + 1):
			var merlon: bool = y >= top + 4 or (x - x0) % 8 < 5
			if not merlon:
				continue
			var row: int = (y - top) / 4
			var mortar: bool = (y - top) % 4 == 3 or (x + (row % 2) * 4) % 8 == 0
			_px(wall, x, y, stone[2] if mortar else (stone[1] if (x + row) % 5 == 0 else stone[0]))
	_stamp(canvas, wall, o)

# A wall block for an arm: a squared stone with its mortar lines.
func _wall_block(canvas: Image, r: Rect2i, o: Color) -> void:
	var blk := _layer()
	_round_rect(blk, r, 1, Color("#8c8cac"))
	_stamp(canvas, blk, o)
	_line(canvas, [Vector2(r.position.x + 1, r.position.y + r.size.y / 2), Vector2(r.end.x - 2, r.position.y + r.size.y / 2)], Color("#5c5a78"))
	_line(canvas, [Vector2(r.position.x + r.size.x / 2, r.position.y + 1), Vector2(r.position.x + r.size.x / 2, r.position.y + r.size.y / 2)], Color("#5c5a78"))
	_px(canvas, r.position.x + 1, r.position.y + 1, Color("#dce8f4"))

func _draw_rampart(canvas: Image, st: Dictionary) -> void:
	var fig := _p2_fig()
	var dy: int = st.dy
	_pebble_golem(canvas, st, fig, false, func(c: Image, _s: Dictionary, f: Dictionary) -> void:
		_castle_wall(c, 18, 4, 59, f.o, true))
	_golem_face(canvas, st, fig)
	# Its left arm is a block of the wall.
	_wall_block(canvas, Rect2i(8, 27 + dy, 10, 12), fig.o)

func _draw_bastion(canvas: Image, st: Dictionary) -> void:
	var fig := _p2_fig()
	var dy: int = st.dy
	_pebble_golem(canvas, st, fig, true, func(c: Image, _s: Dictionary, f: Dictionary) -> void:
		_castle_wall(c, 12, 2, 61, f.o)
		# A round tower rising at the back right, a pennant on top.
		var tower := _layer()
		_round_rect(tower, Rect2i(44, -2, 14, 22), 2, Color("#8c8cac"))
		_stamp(c, tower, f.o)
		for y in range(0, 20, 4):
			_line(c, [Vector2(45, y), Vector2(56, y)], Color("#5c5a78"))
		_line(c, [Vector2(51, -2), Vector2(51, -9)], Color("#5c3c24"))
		var flag := _layer()
		_flat_polygon(flag, PackedVector2Array([Vector2(52, -9), Vector2(58, -7), Vector2(52, -5)]), Color("#e9a83c"))
		_stamp(c, flag, f.o))
	_golem_face(canvas, st, fig)
	_wall_block(canvas, Rect2i(6, 26 + dy, 12, 14), fig.o)
	_wall_block(canvas, Rect2i(42, 18 + dy, 9, 7), fig.o)  # a block for a pauldron

func _attack_rampart(canvas: Image, st: Dictionary) -> void:
	_wall_slam(canvas, st, 1.0)

func _attack_bastion(canvas: Image, st: Dictionary) -> void:
	_wall_slam(canvas, st, 1.25)

# Heavy hits on the tiles beside it: its block arm slams down, stone chips burst off the slab's
# edges, a jolt ring round its base.
func _wall_slam(canvas: Image, st: Dictionary, size: float) -> void:
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	_ring(canvas, Vector2(31.5, 44), Vector2(22 + k * 6, 7 + k * 2) * size, Color("#dce8f4"), k == 2)
	_ring(canvas, Vector2(31.5, 44), Vector2(19 + k * 6, 6 + k * 2) * size, Color("#8c8cac"), true)
	for i in 8:
		var a: float = PI + i * PI / 7.0
		var p := Vector2(31.5, 44) + Vector2(cos(a) * (24 + k * 5) * size, sin(a) * (9 + k * 3) - k * 2)
		var chip := _layer()
		_flat_ellipse(chip, p, Vector2(1.3, 1.1), Color("#b4b0c8"))
		_stamp(canvas, chip, Color("#24243c"))
	if k == 0:
		_fog(canvas, Vector2(13, 42), Vector2(8, 4), Color("#dce8f4"), st.f)

# Two great stone fists planted on the slab, lifting and slamming in a slow stomp; cracks spread from
# where they land.
func _quake_fists(canvas: Image, st: Dictionary, fig: Dictionary, size: float, glow: Color) -> void:
	var dy: int = st.dy
	var lift: float = [0.0, -1.0, -2.0, -1.0, 0.0, 0.0, 0.0, 0.0][st.f % 8] if st.attack < 0 else [-2.0, -4.0, 1.0, 0.0, 0.0, 0.0][st.attack]
	for s: int in [-1, 1]:
		var fist := Vector2(31.5 + s * 21.0, 40 + lift)
		var arm := _layer()
		_stroke(arm, [Vector2(31.5 + s * 13, 24 + dy), fist], 2.2 * size, Color("#8c8cac"))
		_stamp(canvas, arm, fig.o)
		var pts := PackedVector2Array()
		for i in 6:
			var a := i * TAU / 6.0 + 0.4
			pts.append(fist + Vector2(cos(a) * 7.0, sin(a) * 6.0) * size)
		var stone: Array[Color] = _ramp(["#3c3c5c", "#5c5a78", "#8c8cac"])
		_rock(canvas, pts, stone, fig.o)
	# Cracks in the slab.
	for s: int in [-1, 1]:
		var from := Vector2(31.5 + s * 21.0, 46)
		_line(canvas, [from, from + Vector2(s * -6, 2), from + Vector2(s * -9, 1)], glow)

func _draw_quaker(canvas: Image, st: Dictionary) -> void:
	var fig := _p2_fig()
	_pebble_golem(canvas, st, fig, false)
	_golem_face(canvas, st, fig)
	_quake_fists(canvas, st, fig, 1.0, Color("#5c3c24"))

func _draw_earthshaker(canvas: Image, st: Dictionary) -> void:
	var fig := _p2_fig()
	var dy: int = st.dy
	var mask := _pebble_golem(canvas, st, fig, true)
	# Molten fissures down its body, glowing.
	for path: Array in [[Vector2(28, 18 + dy), Vector2(26, 26 + dy), Vector2(29, 33)], [Vector2(35, 20 + dy), Vector2(37, 28 + dy), Vector2(34, 36)]]:
		_line(canvas, path, Color("#e9a83c"), mask)
	_golem_face(canvas, st, fig, Color("#fcd47c"))
	_quake_fists(canvas, st, fig, 1.25, Color("#e9a83c"))

func _attack_quaker(canvas: Image, st: Dictionary) -> void:
	_ground_slam(canvas, st, 1.0)

func _attack_earthshaker(canvas: Image, st: Dictionary) -> void:
	_ground_slam(canvas, st, 1.3)

# The slam: a thick shock ring rolling out over the ground, dust bursting up at both fists.
func _ground_slam(canvas: Image, st: Dictionary, size: float) -> void:
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	var c := Vector2(31.5, 44)
	for w in 3:
		_ring(canvas, c, Vector2(14 + k * 8 - w, 5 + k * 3 - w * 0.4) * size, Color("#fcd47c") if w == 0 else Color("#bca48c"), k == 2 and w > 0)
	for s: int in [-1, 1]:
		_fog(canvas, Vector2(31.5 + s * 21.0, 40 - k * 2), Vector2(7 + k * 2, 4 + k), Color("#dccdb2"), st.f + k)
	if k == 0:
		_warm_glow(canvas, c, Vector2(16, 6))

# Epic finals, the family's floating stones each its own way.
# Edgestone: three honed stone blades floating round it, edges glinting.
func _epic_edgestone(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	for k in 3:
		var bob: float = [0.0, -1.0, -1.0, 0.0, 0.0, 1.0, 1.0, 0.0][(st.f + k * 3) % 8]
		var c: Vector2 = [Vector2(6, 16), Vector2(31.5, -12), Vector2(58, 6)][k] + Vector2(0, bob)
		var d := Vector2.from_angle([-1.0, -1.57, -2.1][k])
		var blade := _layer()
		_flat_polygon(blade, PackedVector2Array([c - d * 7.0, c + d.orthogonal() * 2.2, c + d * 7.0, c - d.orthogonal() * 2.2]), Color("#b4b0c8"))
		_line(blade, [c - d * 6.0, c + d * 6.0], Color("#ffffff"))
		_stamp(canvas, blade, EPIC_O)
		if (st.f + k) % 4 == 0:
			_sparkle(canvas, Vector2i((c + d * 6.0).round()), core)

# Bastion: rocks hanging over its wall, ready to fall, dust trickling from them.
func _epic_bastion(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	for k in 3:
		var bob: float = [0.0, -1.0, -1.0, 0.0, 0.0, 1.0, 1.0, 0.0][(st.f + k * 2) % 8]
		var c: Vector2 = [Vector2(10, -2), Vector2(26, -12), Vector2(38, -6)][k] + Vector2(0, bob)
		var pts := PackedVector2Array()
		for i in 6:
			var a := i * TAU / 6.0 + k
			pts.append(c + Vector2(cos(a) * 5.5, sin(a) * 4.8))
		_rock(canvas, pts, _ramp(cfg.tint), EPIC_O)
		for i in 3:
			_px(canvas, int(c.x) - 1 + i, int(c.y) + 6 + (st.f + i * 2) % 5, Color(glow, 0.8))

# Earthshaker: rubble lifted off the ground by its stomps, hanging in the air round it, glowing below.
func _epic_earthshaker(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	for k in 6:
		var t := float((st.f + k * 3) % 8) / 8.0
		var c := Vector2([6, 14, 22, 41, 49, 57][k], 34 - t * 18.0 - (k % 3) * 4)
		var s: float = [2.6, 3.4, 2.2, 2.4, 3.2, 2.6][k]
		var pts := PackedVector2Array()
		for i in 5:
			var a: float = i * TAU / 5.0 + k + t * 2.0
			pts.append(c + Vector2(cos(a), sin(a)) * s)
		_rock(canvas, pts, _ramp(cfg.tint), EPIC_O)
		_px(canvas, int(c.x), int(c.y + s) + 1, glow)

# Whetstone's shot: a bright crescent of a cut flying edge-first (pointing right), a pale trail.
func _proj_whetstone_slash(canvas: Image, f: int) -> void:
	var c := Vector2(30, 32)
	for i in 24:
		var a: float = -1.2 + i * 2.4 / 23.0
		var w: float = sin(i / 23.0 * PI) * 2.2
		for j in range(0, int(w) + 1):
			var p := c + Vector2(cos(a), sin(a)) * (7.0 - j)
			_px(canvas, roundi(p.x), roundi(p.y), Color("#ffffff") if j == 0 else Color("#9cd4fc"))
	for k in 6:
		_px(canvas, 23 - k - f % 2, 32 + (k % 2), Color("#dce8f4", 0.8 - k * 0.12))

# --- Phase 2, Rootling (tower_design.md 7816b7e0): Groundroot -> Earthbind (roots reaching up like
# hands), Deeproot -> Heartroot (a root coiled in a ring, low), Thorncoil -> Crown of Thorns (a thorny
# crown on its head). Bodies from BODY_PAL. --------------------------------------------------------

# A root hand rising out of the slab: a thick root arm, a palm and splayed fingers reaching up,
# flexing over the loop (`grab` 0..1 closes the fingers).
func _root_hand(canvas: Image, base: Vector2, top: Vector2, size: float, grab: float, wood: Array[Color], o: Color) -> void:
	var layer := _layer()
	var mid := base.lerp(top, 0.5) + Vector2((top.x - base.x) * 0.2, 0)
	_stroke(layer, [base, mid, top], 1.6 * size, wood[1])
	_flat_ellipse(layer, top, Vector2(3.4, 2.8) * size, wood[1])
	for i in 4:
		var a: float = -PI / 2.0 + (i - 1.5) * (0.5 - grab * 0.3)
		var tip := top + Vector2(cos(a), sin(a)) * (6.5 - grab * 2.5) * size
		_stroke(layer, [top, tip + Vector2(0, grab * 2.0)], 0.95 * size, wood[2])
	_stroke(layer, [top + Vector2(-2.5, 1) * size, top + Vector2(-6, -1) * size], 0.95 * size, wood[2])  # the thumb
	_stamp(canvas, layer, o)

func _draw_groundroot(canvas: Image, st: Dictionary) -> void:
	_root_hands_body(canvas, st, false)

func _draw_earthbind(canvas: Image, st: Dictionary) -> void:
	_root_hands_body(canvas, st, true)

func _root_hands_body(canvas: Image, st: Dictionary, great: bool) -> void:
	var fig := _p2_fig()
	var wood := _ramp(["#5c3c24", "#bca48c", "#dccdb2"])
	var flex: float = [0.0, 0.1, 0.3, 0.4, 0.3, 0.1, 0.0, 0.0][st.f % 8] if st.attack < 0 else [0.0, 0.0, 1.0, 0.8, 0.3, 0.0][st.attack]
	var hands: Array = [[Vector2(9, 44), Vector2(6, 14)], [Vector2(55, 43), Vector2(58, 12)]]
	if great:
		hands.append_array([[Vector2(16, 46), Vector2(13, 4)], [Vector2(48, 46), Vector2(51, 2)]])
	# The hands behind it, reaching up past its shoulders.
	_root_golem(canvas, st, fig, great)
	_golem_face(canvas, st, fig)
	for i in hands.size():
		var h: Array = hands[i]
		_root_hand(canvas, h[0], h[1], 1.25 if i < 2 else 1.0, flex if i % 2 == 0 else flex * 0.7, wood, fig.o)

func _attack_groundroot(canvas: Image, st: Dictionary) -> void:
	_grab_lash(canvas, st, [Vector2(6, 12), Vector2(58, 10)])

func _attack_earthbind(canvas: Image, st: Dictionary) -> void:
	_grab_lash(canvas, st, [Vector2(6, 12), Vector2(58, 10), Vector2(13, 2), Vector2(51, 0)])

# The grab: the hands snap shut on something in the air: a burst of motes at each fist, a streak of
# light pulled down from the sky into it.
func _grab_lash(canvas: Image, st: Dictionary, fists: Array) -> void:
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	for p: Vector2 in fists:
		for i in 6:
			var a: float = i * TAU / 6.0 + k
			_px(canvas, roundi(p.x + cos(a) * (3 + k * 2)), roundi(p.y + sin(a) * (3 + k * 2)), Color("#d4ec9c"))
		_line(canvas, [p + Vector2(0, -12 + k * 4), p + Vector2(0, -3)], Color("#fff4dc"))
		_warm_glow(canvas, p, Vector2(5, 5), k)

# A root coiled round its base in a low ring, the end curling up beside it like a tail.
func _root_coil(canvas: Image, st: Dictionary, rings: int, wood: Array[Color], o: Color, glow: Color) -> void:
	for r in rings:
		var back := _layer()
		var front := _layer()
		var rx := 24.0 - r * 4.0
		var cy := 42.0 - r * 3.0
		for i in 64:
			var a: float = i * TAU / 64.0
			var p := Vector2(31.5 + cos(a) * rx, cy + sin(a) * rx * 0.33)
			_flat_ellipse(front if sin(a) > 0.0 else back, p, Vector2(2.8, 2.5), wood[1])
		_stamp(canvas, front, o)
		_under(canvas, back)
		for i in 8:
			var a: float = i * TAU / 8.0 + st.f * TAU / 32.0
			if sin(a) > 0.0:
				_px(canvas, roundi(31.5 + cos(a) * rx), roundi(cy + sin(a) * rx * 0.33) - 1, wood[2])
	var tail := _layer()
	_stroke(tail, [Vector2(55, 42), Vector2(59, 34), Vector2(57, 28), Vector2(54, 29)], 1.6, wood[1])
	_stamp(canvas, tail, o)
	if glow.a > 0.0:
		_px(canvas, 54, 29, glow)

func _draw_deeproot(canvas: Image, st: Dictionary) -> void:
	var fig := _p2_fig()
	_root_golem(canvas, st, fig, false)
	_golem_face(canvas, st, fig)
	_root_coil(canvas, st, 1, _ramp(["#8c5c34", "#dccdb2", "#fff4dc"]), fig.o, Color(0, 0, 0, 0))

func _draw_heartroot(canvas: Image, st: Dictionary) -> void:
	var fig := _p2_fig()
	var dy: int = st.dy
	_root_golem(canvas, st, fig, true)
	_golem_face(canvas, st, fig, Color("#fcd47c"))
	_root_coil(canvas, st, 2, _ramp(["#8c5c34", "#dccdb2", "#fff4dc"]), fig.o, Color("#fcd47c"))
	# A heart of glowing heartwood in its chest, beating.
	var beat: bool = st.f % 4 < 2 or st.power > 0.5
	var heart := _layer()
	for p: Vector2 in [Vector2(29.5, 25 + dy), Vector2(32.5, 25 + dy)]:
		_flat_ellipse(heart, p, Vector2(2.0, 2.0), Color("#e9a83c"))
	_flat_polygon(heart, PackedVector2Array([Vector2(27.5, 26 + dy), Vector2(34.5, 26 + dy), Vector2(31, 30 + dy)]), Color("#e9a83c"))
	_stamp(canvas, heart, Color("#5c3c24"))
	_px(canvas, 29, 24 + dy, Color("#fff4dc"))
	if beat:
		_warm_glow(canvas, Vector2(31, 26 + dy), Vector2(6, 5), st.f)

func _attack_deeproot(canvas: Image, st: Dictionary) -> void:
	_coil_lash(canvas, st, 1.0)

func _attack_heartroot(canvas: Image, st: Dictionary) -> void:
	_coil_lash(canvas, st, 1.25)

# The hold: the coil snaps tight and roots lash up out of the ground all round it.
func _coil_lash(canvas: Image, st: Dictionary, size: float) -> void:
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	_ring(canvas, Vector2(31.5, 43), Vector2(26 - k * 3, 9 - k) * size, Color("#fcd47c"), k == 2)
	_root_spikes(canvas, st, [Vector2(4, 46), Vector2(60, 45), Vector2(14, 53), Vector2(50, 53), Vector2(31, 57)], false)

# A crown of thorns: a twisted band round its head with thorns jutting up and out (bigger for Crown
# of Thorns, with rose hips), thorny vines wound round its arms.
func _thorn_crown(canvas: Image, st: Dictionary, great: bool, o: Color) -> void:
	var dy: int = st.dy
	var band := _layer()
	var c := Vector2(30.5, 7 + dy)
	var w: float = 11.0 if great else 9.5
	for i in 40:
		var a: float = PI + i * PI / 39.0
		_flat_ellipse(band, c + Vector2(cos(a) * w, sin(a) * 2.5 + 2.0), Vector2(1.4, 1.4), Color("#5c3c24"))
	var n := 9 if great else 7
	for i in n:
		var t := float(i) / (n - 1)
		var base := c + Vector2(-w + t * w * 2.0, 1.0 - sin(t * PI) * 1.5)
		var len: float = (9.0 if great else 7.0) * (0.7 + 0.3 * sin(t * PI))
		var tip := base + Vector2((t - 0.5) * 4.0, -len)
		_flat_polygon(band, PackedVector2Array([base + Vector2(-1.8, 0), tip, base + Vector2(1.8, 0)]), Color("#dccdb2"))
	_stamp(canvas, band, o)
	if great:
		for p: Vector2 in [Vector2(22, 7 + dy), Vector2(30, 5 + dy), Vector2(39, 7 + dy)]:
			_flat_ellipse(canvas, p, Vector2(1.4, 1.4), Color("#bc44dc"))
			_px(canvas, int(p.x), int(p.y) - 1, Color("#ec9cf4"))
	# Thorny vines wound round its arms.
	for s: int in [-1, 1]:
		for i in 6:
			var p := Vector2(31.5 + s * (13 + i * 0.6), 24 + i * 3 + (dy if i < 2 else 0))
			_px(canvas, int(p.x), int(p.y), Color("#34643c"))
			_px(canvas, int(p.x) + s, int(p.y) - 1, Color("#8c5c34"))

func _draw_thorncoil(canvas: Image, st: Dictionary) -> void:
	var fig := _p2_fig()
	_root_golem(canvas, st, fig, false)
	_golem_face(canvas, st, fig)
	_thorn_crown(canvas, st, false, fig.o)

func _draw_crown_of_thorns(canvas: Image, st: Dictionary) -> void:
	var fig := _p2_fig()
	_root_golem(canvas, st, fig, true)
	_golem_face(canvas, st, fig, Color("#ec9cf4"))
	_thorn_crown(canvas, st, true, fig.o)

func _attack_thorncoil(canvas: Image, st: Dictionary) -> void:
	_thorn_burst(canvas, st, 1.0)

func _attack_crown_of_thorns(canvas: Image, st: Dictionary) -> void:
	_thorn_burst(canvas, st, 1.3)

# Thorns: a ring of thorn spikes driven up out of the ground round it, red sparks where they bite.
func _thorn_burst(canvas: Image, st: Dictionary, size: float) -> void:
	var k: int = st.attack - RELEASE_FRAME
	if k < 0 or k > 2:
		return
	var h: float = [5.0, 8.0, 4.0][k] * size
	var layer := _layer()
	for i in 10:
		var a: float = i * TAU / 10.0
		var base := Vector2(31.5 + cos(a) * 25.0 * size, 44 + sin(a) * 8.5 * size)
		_flat_polygon(layer, PackedVector2Array([base + Vector2(-2.0, 0), base + Vector2(cos(a) * 1.5, -h), base + Vector2(2.0, 0)]), Color("#dccdb2"))
	_stamp(canvas, layer, Color("#241c14"))
	_ring(canvas, Vector2(31.5, 44), Vector2(25, 8.5) * size, Color("#ec9cf4"), k == 2)
	if k < 2:
		for i in 10:
			var a: float = i * TAU / 10.0
			_sparkle(canvas, Vector2i(roundi(31.5 + cos(a) * 25.0 * size + cos(a) * 1.5), roundi(44 + sin(a) * 8.5 * size - h - 2)), Color("#ec9cf4"))

# Epic finals, the family's roots each their own way.
# Earthbind: two more great root hands rise behind it, reaching for the sky, light caught in them.
func _epic_earthbind(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var back := _layer()
	var flex: float = [0.0, 0.2, 0.4, 0.5, 0.4, 0.2, 0.0, 0.0][st.f % 8]
	_root_hand(back, Vector2(22, 30), Vector2(17, -10), 1.3, flex, _ramp(cfg.tint), EPIC_O)
	_root_hand(back, Vector2(41, 30), Vector2(46, -12), 1.3, flex * 0.7, _ramp(cfg.tint), EPIC_O)
	_under(canvas, back)
	for p: Vector2i in [Vector2i(17, -16), Vector2i(46, -18)]:
		if st.f % 4 < 2:
			_sparkle(canvas, p, core)

# Heartroot: rings of light pulsing out from its heart through the coils, like a heartbeat.
func _epic_heartroot(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var t := float(st.f % 4) / 4.0
	_ring(canvas, Vector2(31.5, 40), Vector2(16 + t * 14, 5 + t * 4), glow, t > 0.5)
	var back := _layer()
	for s: int in [-1, 1]:
		_stroke(back, [Vector2(31.5 + s * 18, 40), Vector2(31.5 + s * 24, 20), Vector2(31.5 + s * 20, 4), Vector2(31.5 + s * 12, -2)], 1.8, Color(cfg.tint[2]))
	_outline_layer(back)
	_under(canvas, back)
	for p: Vector2i in [Vector2i(10, 20), Vector2i(53, 20), Vector2i(19, -1), Vector2i(44, -1)]:
		_px(canvas, p.x, p.y, core if st.f % 4 < 2 else glow)

# Crown of Thorns: a great briar arching behind it, thorned and hung with roses.
func _epic_crown_of_thorns(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var briar := _layer()
	var c := Vector2(31.5, 26 + st.dy)
	for i in 80:
		var a: float = PI + i * PI / 79.0
		var p := c + Vector2(cos(a) * 26.0, sin(a) * 28.0)
		_flat_ellipse(briar, p, Vector2(1.3, 1.3), Color(cfg.tint[1]))
		if i % 8 == 4:
			var d := Vector2(cos(a), sin(a))
			_flat_polygon(briar, PackedVector2Array([p - d.orthogonal() * 1.4, p + d * 4.0, p + d.orthogonal() * 1.4]), Color(cfg.tint[2]))
	_outline_layer(briar)
	_under(canvas, briar)
	for k in 5:
		var a: float = PI + 0.3 + k * (PI - 0.6) / 4.0
		var p := c + Vector2(cos(a) * 26.0, sin(a) * 28.0)
		var rose := _layer()
		_flat_ellipse(rose, p, Vector2(2.2, 2.0), Color("#bc44dc"))
		_stamp(canvas, rose, EPIC_O)
		_px(canvas, int(p.x), int(p.y), Color("#ec9cf4"))

# --- Phase 2, Acorn (tower_design.md 7816b7e0): Seedbearer -> Grove Keeper (a golem carrying a seed
# sack), Nurse Log -> Mother Log (a mossy fallen log with a sapling growing from it), Dream Oak ->
# Dreamroot (a small oak with a glowing fruit). Weak pulses without an attack sheet, like Dewcatcher.

func _acorn_golem(canvas: Image, st: Dictionary, fig: Dictionary, lush: bool) -> Image:
	_draw_waystone(canvas, st, "leaf_litter", lush)
	var mask := _draw_template_figure(canvas, st.pose, fig)
	for g: Array in [[Vector2(26, 24 + st.dy), Vector2(25, 30 + st.dy)], [Vector2(35, 26 + st.dy), Vector2(36, 31)]]:
		_line(canvas, g, fig.c, mask)
	return mask

# A burlap seed sack slung over its shoulder on a cord, bulging, seeds trickling from a tear.
func _seed_sack(canvas: Image, st: Dictionary, c: Vector2, size: float, o: Color) -> void:
	var dy: int = st.dy
	var sack := _layer()
	_ellipse(sack, c + Vector2(0, dy), Vector2(7.5, 8.5) * size, _ramp(["#8c5c34", "#bca48c", "#dccdb2"]))
	_ellipse(sack, c + Vector2(0, -8.0 * size + dy), Vector2(3.0, 2.2) * size, _ramp(["#8c5c34", "#bca48c", "#dccdb2"]))
	_stamp(canvas, sack, o)
	_line(canvas, [c + Vector2(-3, -6.5 * size + dy), c + Vector2(3, -6.5 * size + dy)], Color("#5c3c24"))  # its tie
	_line(canvas, [c + Vector2(-2, -7 * size + dy), Vector2(26, 18 + dy)], Color("#5c3c24"))  # the cord over its shoulder
	for i in 3:
		_line(canvas, [c + Vector2(-5 + i * 4, -3 + dy), c + Vector2(-4 + i * 4, 5 + dy)], Color("#8c5c34"))  # weave
	for k in 3:
		var t: int = (st.f + k * 3) % 8
		_px(canvas, int(c.x) + 4 - k, int(c.y + 7 * size) + dy + t, Color("#e9a83c") if k % 2 == 0 else Color("#9cc46c"))

func _draw_seedbearer(canvas: Image, st: Dictionary) -> void:
	var fig := _p2_fig()
	_acorn_golem(canvas, st, fig, false)
	_golem_face(canvas, st, fig)
	_seed_sack(canvas, st, Vector2(49, 27), 1.0, fig.o)
	# A straw hat.
	var hat := _layer()
	_ellipse(hat, Vector2(30.5, 8 + st.dy), Vector2(14, 3.5), _ramp(["#b8662c", "#e9a83c", "#fcd47c"]))
	_ellipse(hat, Vector2(30.5, 5 + st.dy), Vector2(7, 4), _ramp(["#b8662c", "#e9a83c", "#fcd47c"]), 7.0 + st.dy)
	_stamp(canvas, hat, fig.o)
	_line(canvas, [Vector2(24, 6 + st.dy), Vector2(37, 6 + st.dy)], Color("#5c944c"))

func _draw_grove_keeper(canvas: Image, st: Dictionary) -> void:
	var fig := _p2_fig()
	var dy: int = st.dy
	_acorn_golem(canvas, st, fig, true)
	_golem_face(canvas, st, fig)
	_seed_sack(canvas, st, Vector2(50, 26), 1.25, fig.o)
	# A crook staff on its other side, leafing at the hook, and sprouts at its feet.
	var staff := _layer()
	_stroke(staff, [Vector2(8, 46), Vector2(9, 12), Vector2(12, 6), Vector2(16, 7), Vector2(16, 11)], 1.1, Color("#8c5c34"))
	_stamp(canvas, staff, fig.o)
	_leaf(canvas, Vector2(12, 6), Vector2(8, 1), 2.2, _ramp(LEAF), fig.o)
	_leaf(canvas, Vector2(9, 20), Vector2(4, 16), 1.8, _ramp(LEAF), fig.o)
	for p: Vector2 in [Vector2(20, 46), Vector2(41, 47), Vector2(13, 44)]:
		_leaf(canvas, p, p + Vector2(-3, -4), 1.6, _ramp(LEAF), fig.o)
		_leaf(canvas, p, p + Vector2(3, -4), 1.6, _ramp(LEAF), fig.o)
	var hat := _layer()
	_ellipse(hat, Vector2(30.5, 8 + dy), Vector2(15, 3.8), _ramp(["#b8662c", "#e9a83c", "#fcd47c"]))
	_ellipse(hat, Vector2(30.5, 4 + dy), Vector2(7.5, 5), _ramp(["#b8662c", "#e9a83c", "#fcd47c"]), 7.0 + dy)
	_stamp(canvas, hat, fig.o)
	for p: Vector2i in [Vector2i(25, 6), Vector2i(34, 5)]:
		_flower(canvas, p + Vector2i(0, dy), Color("#fff4dc"), Color("#fcd47c"))

# A mossy fallen log lying across the front of the slab, its end showing rings, a sapling (or
# several) growing out of it.
func _nurse_log(canvas: Image, st: Dictionary, big: bool, o: Color) -> void:
	var log := _layer()
	var y := 43.0
	var x0 := 6.0
	var x1 := 56.0 if big else 50.0
	var r := 6.0 if big else 5.2
	var bark := [Color("#5c3c24"), Color("#8c5c34"), Color("#bca48c")]
	for x in range(int(x0), int(x1) + 1):
		for yy in range(int(y - r), int(y + r) + 1):
			var v := (yy - (y - r)) / (2.0 * r)
			var grain: bool = (yy + int(x / 9)) % 3 == 0 and (x * 5) % 7 > 1
			_px(log, x, yy, bark[0] if (v > 0.7 or grain) else (bark[2] if v < 0.3 else bark[1]))
	_stamp(canvas, log, o)
	# The cut end: rings.
	var end := _layer()
	_flat_ellipse(end, Vector2(x1, y), Vector2(3.2, 5.8 if big else 5.0), Color("#dccdb2"))
	_stamp(canvas, end, o)
	end = _layer()
	_flat_ellipse(end, Vector2(x1, y), Vector2(1.8, 3.4 if big else 2.8), Color("#bca48c"))
	_stamp(canvas, end, o)
	_px(canvas, int(x1), int(y), Color("#8c5c34"))
	_px(canvas, int(x1), int(y) - 2, Color("#bca48c"))
	# Moss along its top.
	for x in range(int(x0) + 1, int(x1) - 2):
		if (x * 7) % 5 != 0:
			_px(canvas, x, int(y - (6.0 if big else 5.2)), Color("#5c944c") if x % 3 else Color("#9cc46c"))
			_px(canvas, x, int(y - (6.0 if big else 5.2)) + 1, Color("#34643c") if x % 2 else Color("#5c944c"))
	# Saplings growing from it, swaying.
	var saplings: Array = [Vector2(18, 37)] if not big else [Vector2(14, 36), Vector2(27, 36), Vector2(41, 36)]
	for i in saplings.size():
		var b: Vector2 = saplings[i]
		var h: float = 13.0 if (not big or i == 1) else 9.0
		var sw: float = [0.0, 0.5, 1.0, 0.5, 0.0, -0.5, -1.0, -0.5][(st.f + i * 2) % 8]
		var stem := _layer()
		_stroke(stem, [b, b + Vector2(sw, -h)], 0.7, Color("#5c944c"))
		_stamp(canvas, stem, o)
		_leaf(canvas, b + Vector2(sw, -h), b + Vector2(sw - 6, -h - 4), 2.8, _ramp(LEAF), o)
		_leaf(canvas, b + Vector2(sw, -h + 3), b + Vector2(sw + 6, -h), 2.4, _ramp(LEAF), o)
		_leaf(canvas, b + Vector2(sw, -h), b + Vector2(sw + 1, -h - 6), 2.2, _ramp(LEAF), o)
	if big:
		for p: Vector2 in [Vector2(35, 40), Vector2(48, 41)]:
			var cap := _layer()
			_ellipse(cap, p, Vector2(2.2, 1.6), _ramp(["#b8662c", "#e9a83c", "#fcd47c"]), p.y + 0.5)
			_stamp(canvas, cap, o)

func _draw_nurse_log(canvas: Image, st: Dictionary) -> void:
	var fig := _p2_fig()
	_acorn_golem(canvas, st, fig, false)
	_golem_face(canvas, st, fig)
	_moss_cap(canvas, st.dy, fig.o)
	_nurse_log(canvas, st, false, fig.o)

func _draw_mother_log(canvas: Image, st: Dictionary) -> void:
	var fig := _p2_fig()
	_acorn_golem(canvas, st, fig, true)
	_golem_face(canvas, st, fig)
	_moss_cap(canvas, st.dy, fig.o)
	_nurse_log(canvas, st, true, fig.o)

# A small oak growing from its head: a short trunk, a round crown of leaves, a glowing dream-fruit
# hanging from it (two for Dreamroot), the fruit's light pulsing.
func _dream_oak_crown(canvas: Image, st: Dictionary, big: bool, o: Color) -> void:
	var dy: int = st.dy
	var trunk := _layer()
	_stroke(trunk, [Vector2(30.5, 8 + dy), Vector2(30.5, 0 + dy)], 1.3, Color("#5c3c24"))
	_stamp(canvas, trunk, o)
	var crown := _layer()
	var r: float = 12.0 if big else 9.5
	for c: Vector3 in [Vector3(0, -6, 1.0), Vector3(-6, -3, 0.7), Vector3(6, -3, 0.7), Vector3(-3, -9, 0.6), Vector3(4, -9, 0.6)]:
		_ellipse(crown, Vector2(30.5 + c.x * r / 9.5, dy + c.y * r / 9.5), Vector2(r, r * 0.75) * c.z, _ramp(["#1c3c2c", "#34643c", "#5c944c", "#9cc46c"]))
	_stamp(canvas, crown, o)
	var fruits: Array = [Vector2(36, 4)] if not big else [Vector2(37, 6), Vector2(23, 3)]
	var bright: bool = st.f % 4 < 2 or st.power > 0.5
	for p: Vector2 in fruits:
		var q := p + Vector2(0, dy)
		_line(canvas, [q + Vector2(0, -3), q + Vector2(0, -1)], Color("#5c3c24"))
		var fruit := _layer()
		_flat_ellipse(fruit, q + Vector2(0, 1), Vector2(2.2, 2.4), Color("#ec9cf4"))
		_stamp(canvas, fruit, Color("#4c3c74"))
		_px(canvas, int(q.x) - 1, int(q.y), Color("#fff4dc"))
		if bright:
			_warm_glow(canvas, q + Vector2(0, 1), Vector2(6, 5), st.f)

func _draw_dream_oak(canvas: Image, st: Dictionary) -> void:
	var fig := _p2_fig()
	_acorn_golem(canvas, st, fig, false)
	_golem_face(canvas, st, fig)
	_dream_oak_crown(canvas, st, false, fig.o)
	_motes(canvas, st, [16, 46], 26, 14, [Color("#ec9cf4"), Color("#9a84e8")])

func _draw_dreamroot(canvas: Image, st: Dictionary) -> void:
	var fig := _p2_fig()
	var mask := _acorn_golem(canvas, st, fig, true)
	_golem_face(canvas, st, fig, Color("#ec9cf4"))
	# Dream-light running in its roots down to the slab.
	for path: Array in [[Vector2(20, 40), Vector2(14, 45), Vector2(8, 46)], [Vector2(42, 41), Vector2(49, 46), Vector2(56, 45)]]:
		_line(canvas, path, Color("#ec9cf4"))
	_dream_oak_crown(canvas, st, true, fig.o)
	_motes(canvas, st, [12, 50, 24, 40], 26, 18, [Color("#ec9cf4"), Color("#9a84e8")])

# Epic finals, the family's antlers each their own way.
# Grove Keeper: antlers of sprouting branches, buds and seed pods at the tips.
func _epic_grove_keeper(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	_epic_antlers(canvas, cfg, st, glow, core)
	for p: Vector2i in [Vector2i(9, -6), Vector2i(54, -6)]:
		_flower(canvas, p + Vector2i(0, st.dy), Color("#fff4dc"), Color("#fcd47c"))

# Mother Log: a young tree grown up behind it out of the log, its branches spread like antlers.
func _epic_mother_log(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var tree := _layer()
	_stroke(tree, [Vector2(48, 40), Vector2(50, 20), Vector2(48, 4)], 1.8, Color("#8c5c34"))
	for b: Array in [[Vector2(49, 22), Vector2(58, 12)], [Vector2(49, 14), Vector2(40, 2)], [Vector2(48, 8), Vector2(54, -4)]]:
		_stroke(tree, b, 1.0, Color("#bca48c"))
	_outline_layer(tree)
	_under(canvas, tree)
	for p: Vector2 in [Vector2(58, 12), Vector2(40, 2), Vector2(54, -4), Vector2(48, 2)]:
		_leaf(canvas, p, p + Vector2(-3, -4), 2.4, _ramp(cfg.leaf), EPIC_O)
		_leaf(canvas, p, p + Vector2(3, -3), 2.0, _ramp(cfg.leaf), EPIC_O)
	if st.f % 4 < 2:
		_sparkle(canvas, Vector2i(44, -4), core)

# Dreamroot: antlers of dreaming branches, a dream-fruit glowing at every tip.
func _epic_dreamroot(canvas: Image, cfg: Dictionary, st: Dictionary, glow: Color, core: Color) -> void:
	var dy: int = st.dy
	var antlers := _layer()
	var tips: Array = []
	for s: int in [-1, 1]:
		var root := Vector2(31.5 + s * 8, 2 + dy)
		var tip := root + Vector2(s * 20, -10)
		_stroke(antlers, [root, root + Vector2(s * 9, -6), tip], 1.4, Color(cfg.tint[1]))
		for b: Array in [[0.4, Vector2(s * 2, -8)], [0.8, Vector2(s * 4, 4)]]:
			var from := root.lerp(tip, b[0])
			_stroke(antlers, [from, from + b[1]], 0.9, Color(cfg.tint[2]))
			tips.append(from + b[1])
		tips.append(tip)
	_outline_layer(antlers)
	_under(canvas, antlers)
	for i in tips.size():
		var t: Vector2 = tips[i]
		_flat_ellipse(canvas, t, Vector2(1.6, 1.6), core if (st.f + i) % 4 < 2 else glow)


# Stone walls (Phase 2, Rampart / Bastion): a wall touching Rampart turned to stone, the same layout as
# its normal sheet (8 idle frames, 64x80) so the game swaps the texture 1:1. The wall's own drawing is
# recoloured by brightness into grey stone (the slab untouched, a little moss in the cracks), except its
# tell, which a player must still read at a glance (Tower Discussion): `tell` returns the colour a
# pixel keeps, or a clear colour to turn it to stone.
func _stone_over(canvas: Image, st: Dictionary, theme: String, lush: bool, draw: Callable, tell: Callable = Callable()) -> void:
	var base := _layer()
	_draw_waystone(base, st, theme, lush)
	draw.call(canvas, st)
	var stone := [Color("#24243c"), Color("#3c3c5c"), Color("#5c5a78"), Color("#8c8cac"), Color("#b4b0c8"), Color("#dce8f4")]
	for y in range(-OY, S):
		for x in S:
			var c := _gp(canvas, x, y)
			if c.a == 0.0 or c == _gp(base, x, y):
				continue
			if tell.is_valid():
				var keep: Color = tell.call(c)
				if keep.a > 0.0:
					_sp(canvas, x, y, keep)
					continue
			var lum := c.r * 0.3 + c.g * 0.59 + c.b * 0.11
			var i: int = clampi(int(lum * 8.0), 0, stone.size() - 1)
			var mossy: bool = i == 2 and (x * 7 + y * 3) % 11 == 0
			_sp(canvas, x, y, Color("#5c944c") if mossy else Color(stone[i], c.a))

func _draw_thornwall_stone(canvas: Image, st: Dictionary) -> void:
	_stone_over(canvas, st, "bramble", false, Callable(self, "_draw_thornwall"))

# Stone Bramble: its thorns stay sharp and dark on the stone, its canes dark.
func _draw_bramble_stone(canvas: Image, st: Dictionary) -> void:
	_stone_over(canvas, st, "bramble", true, Callable(self, "_draw_bramble"), func(c: Color) -> Color:
		if c.is_equal_approx(Color("#e8d4a0")):
			return Color("#140f26")
		if c.is_equal_approx(Color("#6a4030")):
			return Color("#5c3c24")
		return Color(0, 0, 0, 0))
	_stone_thorns(canvas, st, "bramble", true)

# Stone Honeysuckle: its trumpet flowers (and the bee) still bloom in colour on the stone.
func _draw_honeysuckle_stone(canvas: Image, st: Dictionary) -> void:
	_stone_over(canvas, st, "bramble", true, Callable(self, "_draw_honeysuckle"), func(c: Color) -> Color:
		var warm: bool = c.h < 0.17 or c.h > 0.9
		return c if warm and c.s > 0.12 and c.v > 0.25 else Color(0, 0, 0, 0))

# Dark thorns jutting out of a stone wall's outline (stone Bramble's tell): every few pixels along the
# top and sides of the wall, a three-pixel spike pointing out into the open (its tip a shade lighter).
func _stone_thorns(canvas: Image, st: Dictionary, theme: String, lush: bool) -> void:
	var base := _layer()
	_draw_waystone(base, st, theme, lush)
	var src := canvas.duplicate() as Image
	for y in range(-OY + 2, 42):
		for x in range(2, S - 2):
			var c := _gp(src, x, y)
			if c.a == 0.0 or c == _gp(base, x, y) or (x * 3 + y * 5) % 7 != 0:
				continue
			for d: Vector2i in [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
				if _gp(src, x + d.x, y + d.y).a == 0.0:
					_px(canvas, x + d.x, y + d.y, Color("#140f26"))
					_px(canvas, x + d.x * 2, y + d.y * 2, Color("#140f26"))
					_px(canvas, x + d.x * 3, y + d.y * 3, Color("#3c3c5c"))
					break
