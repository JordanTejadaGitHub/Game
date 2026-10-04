extends Resource
class_name TowerData

# PROJECTILE fires at the "first" target (optionally splashing); PULSE soothes every creature in
# range at once; CHAIN is instant lightning that jumps between creatures; CLOUD leaves a lingering
# cloud on the target's path tile that soothes and applies its status to creatures inside.
# TRAP plants rings on path tiles that burst when stepped on (Fairy Ring); BEAM holds one target and
# ramps up (Sunpetal); COPY uses the strongest adjacent Warden's attack (Graftling); SWOOP sends a
# bird that flies back (Nestling line); SWEEP is unused (Starling Murmuration swoops now; kept so the
# numbers after it don't shift); SPREAD copies statuses between nightmares (Gust); SPIN hits the 8 tiles around it
# (Pinwheel); PULL grabs a nightmare and drags it back (Pond Keeper); LIGHT lights path tiles and
# Marks nightmares on them (Rootlight); AURA never attacks but affects everything in range (White Stag).
# PECK sends birds that peck one nightmare several times, each a full hit (Hummingbird Bower);
# BOOMERANG throws a seed along a straight line and back through everything (Samara).
# PATROL: something that travels back and forth along the path in range, hitting what it passes
# (Dawnwing's great bird, The Whirlwind's cyclone).
enum AttackKind { PROJECTILE, PULSE, CHAIN, CLOUD, TRAP, BEAM, COPY, SWOOP, SWEEP, SPREAD, SPIN, PULL, LIGHT, AURA,
	PECK, BOOMERANG, PATROL }
# Who a Warden shoots at. FIRST = furthest along the path. Snipers let the player choose.
enum TargetMode { FIRST, STRONGEST, BOSSES, FASTEST, CLOSEST, LAST }  # Append only (saved as ints)

const ATTACKS_JSON := "res://assets/towers/attacks.json"
const ASCENDED_JSON := "res://assets/towers/ascended/ascended.json"  # 128×128 Ascended art: anchor + points

@export var id: String = ""  # Unique id (Dream prerequisites, unlocks). Empty = the .tres file name
@export var display_name: String = "Tower"  # Name shown in the UI
@export_multiline var description: String = ""  # One line for the Warden panel
@export var cost: int = 10  # Dew cost to build
@export var texture: Texture2D  # Tower sprite; leave empty to draw a placeholder block
@export var frame_count: int = 1  # Idle-loop frames laid out in one row of `texture`
@export var animation_fps: float = 6.0
@export var placeholder_color: Color = Palette.STONE  # Placeholder block colour when there's no texture

@export_group("Evolution")
@export var line: String = ""  # sprout, wall, spore, light, water, stone, root, acorn (Dream tags)
@export var tier: int = 0  # 0 Sprout/Thornwall, 1 base, 2 branch, 3 final form
@export var buildable_directly: bool = true  # Branches and final forms only come from evolving
@export var evolve_cost: int = 0  # Dew to grow into this Warden from the one before it
# TowerData resources this can grow into. Typed as Resource because a script whose export is an
# array of its own class never gets freed (leaks at exit).
@export var evolves_to: Array[Resource] = []
# Branch expansion (tower_design.md "Branch expansion"): the nightmare types this branch answers, for the
# 2-of-5 smart draw (Roguelite's DreamState): &"anti_air", &"detection", &"anti_armour", &"anti_swarm",
# &"anti_tank", &"anti_support", &"boss_abilities".
@export var counter_tags: Array[StringName] = []
# A branch with no counter job: its one-line role in the family pick / Codex (IconInfo.role_text falls back to it):
# &"control", &"setup", &"support", &"economy". Display only (the smart draw reads counter_tags).
@export var role_tag: StringName = &""
# 1 = a Phase 1 expansion branch or its final (the demo keeps today's 2 branches per family); 0 = the original roster.
@export var expansion_phase: int = 0

@export_group("Special")
# The expansion branches' own mechanics (BranchKit): &"lichen", &"brood", &"inkcap", &"cloud", &"whirlpool",
# &"jet", &"jarlink", &"prism", &"sparkler", &"silver_bell", &"hush", &"thrum"; "" = none.
@export var special: StringName = &""
# Its numbers (Balancing Discussion's), by name: each special's keys are listed in BranchKit.
@export var special_params: Dictionary = {}
# A final form: its branch's special plus the final's twist (BranchKit reads it).
@export var special_final: bool = false

@export_group("Attack")
@export var can_attack: bool = true
@export var attack_range: float = 2.5  # Reach in cells, measured from the tower's centre
@export var damage: int = 20  # Soothe dealt per hit
@export var attacks_per_second: float = 1.0
@export var splash_radius: float = 0.0  # Cells; > 0 = projectile soothes everything near where it lands
@export var projectile_speed: float = 400.0  # Pixels per second
@export var projectile_texture: Texture2D  # Row of frames drawn pointing right; empty = coloured puff
@export var projectile_frames: int = 4
@export var projectile_color: Color = Palette.BLOSSOM  # Placeholder puff colour

@export_group("Crits and targeting")
@export var crit_chance: float = 0.0  # 0.05 = 5% of hits deal crit_multiplier × damage
@export var crit_multiplier: float = 2.0
@export var potency: float = 1.0  # Effect damage (Spored, bolts, clouds, pops, Reactions, echoes) ×this; 1.15 = 115%
@export var crit_bonus_vs_held: float = 0.0  # Extra crit chance against Held nightmares (Hoarfrost)
@export var first_hit_crits: bool = false  # First hit on each nightmare always crits (Moonstone)
@export var target_mode: TargetMode = TargetMode.FIRST
@export var has_target_priority: bool = false  # Player can change target_mode (snipers)
@export var min_range: float = 0.0  # Cells; can't hit nightmares closer than this
# +X damage per cell of distance beyond `distance_bonus_from` cells, up to distance_bonus_max.
@export var distance_bonus_per_cell: float = 0.0
@export var distance_bonus_from: float = 3.0
@export var distance_bonus_max: float = 0.0
# Extra damage against these nightmares (EnemyData file names), and against sprinting ones.
@export var bonus_vs_enemies: Array[String] = []
@export var bonus_vs_sprinting: bool = false
@export var bonus_vs_multiplier: float = 1.0

@export_group("Status")
@export var applies_status: StringName = &""  # damp, drowsy, spored, marked, static (EnemyStatuses)
@export var status_stacks: int = 1
@export var status_duration: float = 0.0  # 0 = the status's default
@export var status_max_stacks: int = 0  # 0 = the status's default (Driftspore: 12 Spored)

@export_group("Chain")
@export var chain_targets: int = 3  # Creatures hit per strike (the first plus jumps)
@export var chain_jump_range: float = 1.5  # Cells between jumps
@export var storm_every: int = 0  # Every Nth attack strikes every Damp creature in range (Thunderhead)

@export_group("Cloud")
@export var cloud_radius: float = 0.7  # Cells
@export var cloud_duration: float = 3.0
@export var cloud_fog: bool = false  # Mistveil fog: Spored ticks harder inside

@export_group("Song")
# Only every Nth attack applies `applies_status` (Bellflower: Drowsy on every 2nd pulse). 1 = always.
@export var status_every: int = 1
# A second status on every hit (Lullaby Bell: Static and Drowsy).
@export var extra_status: StringName = &""
@export var extra_status_stacks: int = 1
# Pulses set off a Static bolt on nightmares with this many Static stacks or more (Chime Stone). 0 = no.
@export var sets_off_static_at: int = 0
@export var set_off_share: float = 1.0  # Bolts its pulse sets off deal this share (The Great Bell: 0.5)
# Dreamcatcher: nightmares in range that are asleep or at max Drowsy are Caught and take this much
# more damage from everything (0 = not a Dreamcatcher).
@export var caught_bonus: float = 0.0
@export var sleep_extend: float = 0.0  # Great Dreamcatcher: sleep in range lasts this much longer (once each)
@export var caught_shards: bool = false  # Great Dreamcatcher: Caught nightmares dispelled drop Dreamlight shards
# Echo Hollow: a Reaction within range repeats 1 s later at this share on the same nightmare, wherever it is now (where it died if dispelled; 0 = no echo).
@export var echo_share: float = 0.0
@export var echo_is_chain_link: bool = false  # Whispering Hollow: echoes count as chain links

@export_group("Lob")
# Cairn: the shot lobs over walls onto the target's tile (lands there even if the target moves on).
@export var lob: bool = false
@export var lob_height: float = 90.0  # Pixels at the top of the arc
@export var rubble_slow: float = 0.0  # Rockslide: path tiles hit get rubble that slows this much…
@export var rubble_time: float = 3.0  # …for this long

@export_group("Birds and seeds")
@export var multi_targets: int = 1  # Swoops at this many different nightmares at once (Starling Murmuration)
@export var pecks: int = 6  # PECK: pecks per bird per attack…
@export var peck_time: float = 1.0  # …spread over this long, then the bird flies home
@export var peck_birds: int = 1  # Jewelwing Court: 3
@export var flurry_every: int = 0  # Jewelwing Court: every Nth peck is a guaranteed crit
@export var has_bird_toggle: bool = false  # Jewelwing Court: birds spread out or all focus the strongest
@export var boomerang_length: float = 4.0  # BOOMERANG: cells out along the line
@export var boomerang_seeds: int = 1  # Autumn Gale: 2 seeds along the 2 busiest lines
@export var catch_bonus: float = 0.0  # Autumn Gale: +damage per caught throw that hit something…
@export var catch_bonus_max: float = 0.0  # …up to this

@export_group("Heavy hits and sleep")
@export var marked_multiplier: float = 1.0  # Mossback / Boulderback: ×2 damage against Marked nightmares
@export var splash_share: float = 1.0  # Share of the hit the splash deals to the others (Boulderback: 0.5)
@export var crits_vs_drowsy: bool = false  # Boulderback: always crits on a Drowsy nightmare
# Dreamshroom: a nightmare it brings to full Drowsy falls asleep for this long, once (bosses never).
@export var sleep_at_max_drowsy: float = 0.0

@export_group("Ascended and the Sapling")
@export var chain_all_in_range: bool = false  # Stormheart: the chain reaches every nightmare in range…
@export var chain_falloff: float = 0.0  # …each jump doing this much less (0.15 = −15%)
@export var crits_vs_held: bool = false  # Old Mountain: always crits on Held nightmares
@export var held_damage_bonus: float = 0.0  # World Root: nightmares it Holds take this much more damage
@export var aura_damage_bonus: float = 0.0  # Grandmother Oak: Wardens in range +damage…
@export var aura_speed_bonus: float = 0.0  # …and +attack speed
@export var slows_in_aura: bool = false  # The White Stag: nightmares in its aura are slower and take more
@export var patrol_speed: float = 150.0  # PATROL: pixels per second along the path…
@export var patrol_speed_per_nightmare: float = 0.0  # …+this share per nightmare in range (Dawnwing)…
@export var patrol_speed_max: float = 1.0  # …up to this multiple
@export var patrol_carries_statuses: bool = false  # The Whirlwind: statuses it touches travel with it
@export var dew_per_drift: int = 0  # Dew at the end of every drift (Grandmother Oak, the Sapling)
@export var dew_per_rank: int = 0  # Sapling: +Dew per drift for each Nurture rank
@export var dreamlight_every: int = 0  # Sapling: +1 Dreamlight every N drifts…
@export var dreamlight_every_ranked: int = 0  # …every M from rank III
@export var footprint: int = 1  # Cells per side (the Sapling is 2×2)
@export var rooted: bool = false  # Can't be sold or moved once planted (the Sapling)
@export var nurture_cost_multiplier: float = 0.0  # Overrides the tier's Nurture price (Sapling: 3, like a final form)
@export var sprite_offset: Vector2 = Vector2.ZERO  # Tall art (Ascended, the Sapling): (0, −32) puts the slab on the cell
@export var patrol_texture: Texture2D  # PATROL: the bird / cyclone sheet (drawn at its own size)…
@export var patrol_frames: int = 8
@export var patrol_anchor: Vector2 = Vector2(32, 32)  # …the pixel that sits on the path
@export var patrol_idle_texture: Texture2D  # Dawnwing: the idle while its bird is out (the perch empty)
@export var hit_effect_texture: Texture2D  # One-shot on every nightmare a pulse hits (tide wave, root grasp)…
@export var hit_effect_frames: int = 6
@export var hit_effect_anchor: Vector2 = Vector2(32, 32)
@export var impact_texture: Texture2D  # One-shot where a lob lands (Old Mountain's crush)…
@export var impact_frames: int = 6
@export var impact_anchor: Vector2 = Vector2(96, 96)
@export var ripen_texture: Texture2D  # Sapling: plays when it yields (Dew drop + Dreamlight mote)…
@export var ripen_frames: int = 6
@export var withered_texture: Texture2D  # …crossfaded over the idle by how withered it is…
@export var rank_overlay_texture: Texture2D  # …and one overlay frame per rank I–V (instead of the rank rings)
@export var rank_overlay_frames: int = 5

@export_group("Rootling, Acorn, Monsoon, Beacon")
# A timed ability besides the attack (every `ability_every` s, while a nightmare is in range), on the
# nightmares furthest along: pull them back (Rootcurl, Long Way Home), Hold them (Tangleroot,
# Snugroot), or Mark everything in range (Beacon).
@export var ability_every: float = 0.0
@export var pull_tiles: float = 0.0  # Tiles pulled back along the route (bosses: pull_boss_tiles)
@export var pull_once: bool = false  # Long Way Home: each nightmare only once
@export var hold_targets: int = 0  # Tangleroot 1, Snugroot up to 3…
@export var hold_time: float = 1.0  # …for this long
@export var mark_all: bool = false  # Beacon: Marks every nightmare in range…
@export var marked_bonus: float = 0.0  # …and its Marked is this strong (0.35 = +35%, instead of +25%)
@export var rain: bool = false  # Monsoon: each pulse is a sheet of rain over its range
# Auras (Acorn, Elder Stump, Grove Heart): Wardens within aura_radius cells get aura_damage_bonus /
# aura_speed_bonus, + aura_per_warden for each other Warden in the radius, up to aura_max.
@export var aura_radius: float = 0.0  # 0 = the attack range; 1.5 = the 8 around it
@export var aura_per_warden: float = 0.0
@export var aura_max: float = 0.0
@export var rest_interest: float = 0.0  # Wellspring: at every rest, this share of your banked Dew…
@export var rest_interest_max: int = 0  # …up to this per Wellspring (all together: DewCatch.INTEREST_CAP)
# Catchers (Dewcatcher, Wellspring; warden_stats.md 2026-09-29): nightmares dispelled within catch_radius
# cells drop catch_share more Dew (+catch_per_rank per Nurture rank, instead of damage), caught into the
# bowl and poured out at the rest (the Harvest). Several catchers never stack: the highest applies.
@export var catch_share: float = 0.0
@export var catch_radius: float = 0.0
@export var catch_per_rank: float = 0.1
# Skip (Pebbling): a single-target shot that lands bounces on to the nearest other nightmare within
# skip_radius cells, dealing skip_share of the hit (once; the skip doesn't skip again).
@export var skip_share: float = 0.0
@export var skip_radius: float = 1.0
@export var cloud_slow: float = 0.0  # Morning Fog: nightmares inside are this much slower…
@export var cloud_drowsy_per_second: float = 0.0  # …and gain Drowsy at this rate

@export_group("Pop")

@export_group("Freeze")
# Hits on nightmares with `freeze_needs` (empty = any) Hold them for freeze_duration s, at most
# once per freeze_cooldown s each (Frostfern, Hoarfrost).
@export var freeze_duration: float = 0.0
@export var freeze_needs: StringName = &"damp"
@export var freeze_needs_stacks: int = 1  # Hoarfrost: freezes at 2 Soaked
# Rootling (status jobs, 2026-09-29): every `pulse_hold_every`-th pulse Holds the nightmare furthest along
# in range for `pulse_hold_time` s.
@export var pulse_hold_every: int = 0
@export var pulse_hold_time: float = 0.0
# Rootlight / Starcave (status jobs): Held lasts this many times as long on their lit tiles (0 = no light).
@export var lit_hold_multiplier: float = 0.0
# Whirligig (status jobs): every `copy_status_every` s, one status (half its stacks) of the most afflicted
# nightmare in range goes onto one neighbour within 1.5 cells.
@export var copy_status_every: float = 0.0
@export var freeze_cooldown: float = 4.0

@export_group("Trap")
@export var trap_max: int = 4  # Rings out at once
@export var trap_lifetime: float = 10.0  # Seconds; 0 = until stepped on
@export var trap_radius: float = 0.6  # Cells hit by a burst
@export var trap_texture: Texture2D  # Row of 16x16 frames
@export var trap_frames: int = 4

@export_group("Beam")
@export var beam_ramp_per_second: float = 0.25  # +25% damage per second on the same target
@export var beam_ramp_max: float = 4.0  # Damage multiplier cap
@export var beam_behind_share: float = 0.0  # Also hits the nightmare right behind at this share
@export var beam_keep_share: float = 0.0  # Midsummer: switching target within BEAM_KEEP_TIME keeps this share of the ramp
@export var beam_color: Color = Palette.GLOW
# A channel loop shown while the beam is on (2–3 frames of 64×64: the flower glowing, no baked ray). Null =
# the idle loop (the attack sheet's firing frames have a ray baked in one direction, which fought the real beam).
@export var beam_sustain_texture: Texture2D = null
@export var beam_sustain_frames: int = 3

@export_group("Copy")
@export var copy_share: float = 0.6  # Graftling: copies the strongest neighbour's attack at 60%

@export_group("Birds")
@export var projectile_returns: bool = false  # The projectile flies back to the Warden (swoop)
@export var dew_mark: bool = false  # Nightmares it hits drop +1 Dew when dispelled (Magpie Perch)
@export var strips_buffs: bool = false  # Magpie (status jobs): each hit strips a buff (Enemy.strip_buff)
@export var crit_dew: int = 0  # Dew per crit (Magpie's Hoard)
@export var crit_dew_per_drift: int = 0  # Cap on crit Dew per drift

@export_group("Wind")
@export var push_back_tiles: float = 0.0  # Pulse hits push nightmares back this far (the Tidecaller's wave)
@export var push_cooldown: float = 3.0  # Seconds before the same nightmare can be pushed again
@export var spread_targets: int = 2  # Gust: nightmares that get the copied statuses
@export var spread_radius: float = 1.5  # Cells from the most-afflicted nightmare
@export var spin_free_path_tiles: int = 2  # Pinwheel: +spin_bonus per adjacent path tile beyond this
@export var spin_bonus: float = 0.2
@export var spin_bonus_max: float = 1.0

@export_group("Pull")
@export var pull_boss_tiles: int = 2  # Pond Keeper: bosses only go back this many tiles

@export_group("Aura")
@export var aura_crit_bonus: float = 0.0  # Wardens in range get this much crit chance (White Stag)
@export var range_aura_bonus: float = 0.0  # Wardens within range_aura_radius get +range (Moon Moth)
@export var range_aura_radius: float = 3.0

@export_group("Memory")
# Memory Wardens (from bosses): one per run each, free, can't evolve.
@export var is_unique: bool = false
# Parked (cut for now, kept for a possible return; Tower Discussion 3288e88): never in a run's roster,
# Test Grove and Unlock all included. The Memory Wardens (White Stag, Pond Keeper, Moon Moth).
@export var parked: bool = false

@export_group("Attack animation")
@export var attack_kind: AttackKind = AttackKind.PROJECTILE
@export var attack_texture: Texture2D  # Row of frames (wind up, release, settle); empty = no animation
@export var attack_frame_count: int = 6
@export var attack_release_frame: int = 2  # Frame on which the shot / pulse happens
@export var attack_animation_fps: float = 12.0  # Sped up if needed to fit between attacks
# Where projectiles spawn (or the pulse's centre), in pixels from the tower's centre. Read from
# `attacks.json` (key `art_id`) when it has a point, so regenerated art stays aligned.
@export var attack_origin: Vector2 = Vector2.ZERO
@export var art_id: String = ""

var _origin_from_json = null  # Cached attacks.json point (Vector2), or false when it has none

var _id_cache := ""  # Performance: get_id is asked on every hit (card and support checks)

func get_id() -> String:
	if id != "":
		return id
	if _id_cache == "":
		_id_cache = resource_path.get_file().get_basename()
	return _id_cache

func get_attack_origin() -> Vector2:
	if _origin_from_json == null:
		var key := art_id if art_id != "" else get_id()
		_origin_from_json = _read_attack_point(key)
		if not _origin_from_json is Vector2:
			_origin_from_json = _read_ascended_point(key)
	return _origin_from_json if _origin_from_json is Vector2 else attack_origin

# Region of `texture` holding idle frame `frame`.
# Where the sprite sits so its slab is on the cell: sprite_offset when a .tres sets it (the Sapling), else from the
# frame height (Tower Assets 2026-10-02: regular art is 64×80, tall 64×96, Ascended 128): the body is the bottom 64
# rows, so a frame h tall moves up (h − 64) / 2.
func get_sprite_offset() -> Vector2:
	if sprite_offset != Vector2.ZERO or texture == null:
		return sprite_offset
	return Vector2(0, -(texture.get_height() - 64) / 2.0)

func get_frame_rect(frame: int) -> Rect2:
	var size := Vector2(texture.get_width() / float(frame_count), texture.get_height())
	return Rect2(Vector2(size.x * frame, 0), size)

# The attack point for `key` in attacks.json, relative to the frame centre, or false.
static func _read_attack_point(key: String):
	if not FileAccess.file_exists(ATTACKS_JSON):
		return false
	var json = JSON.parse_string(FileAccess.get_file_as_string(ATTACKS_JSON))
	if typeof(json) != TYPE_DICTIONARY or not json.get("wardens", {}).has(key):
		return false
	var point = json.wardens[key].get("point")
	if not (point is Array and point.size() == 2):
		return false
	# A bigger canvas (art_direction.md "Bigger Wardens", up to 80×128): the entry's own "frame" [w, h]. Tower Assets
	# (2c398d71) gives x in the w-wide frame and y from the top of the bottom 64 rows (the cell), so the cell centre is
	# at (w / 2, 32) in those units; a point above the cell has a negative y.
	var frame = json.wardens[key].get("frame")
	if frame is Array and frame.size() == 2:
		return Vector2(point[0] - frame[0] / 2.0, point[1] - 32.0)
	var half: float = json.get("frame_size", 64) / 2.0
	return Vector2(point[0] - half, point[1] - half)

# Ascended art: the point relative to the cell centre (the json's anchor), or false.
static func _read_ascended_point(key: String):
	if not FileAccess.file_exists(ASCENDED_JSON):
		return false
	var json = JSON.parse_string(FileAccess.get_file_as_string(ASCENDED_JSON))
	if typeof(json) != TYPE_DICTIONARY or not json.get("wardens", {}).has(key):
		return false
	var point = json.wardens[key].get("point")
	var anchor = json.get("anchor", [64, 96])
	return Vector2(point[0] - anchor[0], point[1] - anchor[1])
