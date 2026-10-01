extends Node2D
class_name Tower

# A Warden. Plays its idle loop, and when a nightmare is in range winds up its attack animation and
# releases on the release frame: a projectile (optionally splashing or swooping back), a pulse, chain
# lightning, a lingering cloud, a trap ring, a sweep of birds, a status-spreading gust, spinning
# blades, a grab, or lit path tiles. Beams and auras work continuously instead. Hits can crit and
# apply the Warden's status. Stats go through DreamState (group "dream_state") so Dreams can modify
# them. Kinds and their numbers: documentation/tower_design.md and warden_stats.md.

signal evolved(tower: Tower)
# The Warden gained a Nurture rank (`rank` is the new one).
signal nurtured(tower: Tower)
# The attack's release frame: the shot / pulse / chain / cloud happens (sound hooks listen).
signal attack_released(tower: Tower)
# A hit from this Warden was a critical hit (sound: a sharp chime).
signal crit_landed(tower: Tower, enemy: Node2D)
# A hit from this Warden landed on `enemy` (sound: the impact). Every attack kind goes through hit().
signal hit_landed(tower: Tower, enemy: Node2D, is_area: bool, is_crit: bool)
# The first grow into a final form this run (TowerPlacer.evolve, with Fx.final_bloom): sound.
signal final_bloomed(tower: Tower)
# A beam (Sunpetal line) hit its target; `ramp` is its current damage multiplier.
signal beam_ticked(tower: Tower, ramp: float)
# Sound hooks for the Warden sound sheet (audio_direction.md); SoundHooks connects to these.
signal cloud_formed(tower: Tower, where: Vector2, duration: float)  # Bloomcap / Dreamshroom / Mistveil
signal trap_set(tower: Tower, where: Vector2)  # Fairy Ring planted a ring
signal trap_triggered(tower: Tower, where: Vector2)  # A ring went off
signal seed_caught(tower: Tower)  # Samara / Autumn Gale caught a seed
signal echoed(tower: Tower, reaction: StringName, where: Vector2)  # Echo Hollow repeated a Reaction
signal put_to_sleep(tower: Tower, enemy: Node2D)  # A nightmare fell asleep because of this Warden
signal shard_dropped(tower: Tower, where: Vector2)  # A Great Dreamcatcher's Caught nightmare left a shard
signal grab_finished(tower: Tower, enemy: Node2D)  # The Pond Keeper's drag ended
signal ascended(tower: Tower)  # Grew into an Ascended form (tier 4)
signal ascended_event(tower: Tower, where: Vector2, targets: int)  # One per Ascended pulse / chain
signal sap_yielded(tower: Tower, dew: int)  # The Sapling / Grandmother Oak paid out at a drift's end
signal dreamlight_ripened(tower: Tower)  # The Sapling gave a Dreamlight
# Catchers (DewCatch): Dew caught into the bowl on a dispel near it; the bowl poured at the rest (the
# Harvest); a Wellspring's interest paid at the rest.
signal dew_caught(tower: Tower, where: Vector2, amount: float)
signal harvest_poured(tower: Tower, amount: int)
signal interest_paid(tower: Tower, amount: int)
signal withered(tower: Tower)  # A leaf lost withered the Sapling's yield
signal statics_set_off(tower: Tower, where: Vector2, count: int)  # An Ascended pulse (the Great Bell) set off Static charges
signal legacy_released(tower: Tower)  # An Ascended form made its final form's attack (no wind-up; sound)

@export var tower_data: TowerData
@onready var sprite: Sprite2D = $Sprite2D

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const ENEMY_GROUP := "enemies"
const SPORE_POTENCY := 0.25  # Spored soothes this share of the Warden's soothe per second per stack
const CHAIN_DAMP_EXTRA_JUMPS := 2
const CHAIN_DAMP_EXTRA_RANGE := 1.0  # Cells
const LOOSE_STONE_SHARE := 0.35  # Loose Stones: each of the 3 fragments
const HUSH_RADIUS := 0.25  # Hush: Bellflower-line pulses +25% radius per stack (max 3; dream_audit.md)
const BEAM_TICK := 0.25  # Seconds between beam hits
const BEAM_RAMP_FAST := 2.0  # Beams ramp this much faster on Drowsy or Held nightmares
const AURA_TICK := 0.25  # Seconds between aura refreshes (White Stag)
const AURA_PULSE_EVERY := 2.5  # Seconds between the White Stag's pulse animations
const NEIGHBOUR_REFRESH := 5.0  # Seconds between looks at neighbouring Wardens (copy, auras); map changes, growing and ranks refresh sooner
const TONGUE_COLOR := Palette.BLOSSOM
const WIND_COLOR := Palette.MOONLIGHT
const LIGHT_COLOR := Palette.GLOW
# Nurture ranks (warden_stats.md "Nurture v2"). Costs are base × tier multiplier (at purchase) × Dreams.
const RANK_MAX := 5  # Without Dreams (Deeper Rings: VII)
const RANK_COSTS: Array[int] = [25, 40, 60, 90, 135]  # Base Dew for ranks I-V (economy pass v2)
const RANK_DAMAGE := 0.10
const COOLDOWN_JITTER := 0.08  # ± share of each attack's cooldown (desyncs Wardens; see _start_attack)
const PATIENT_ROOTS_PULL := 0.5  # Patient Roots (Seed card): the Rootling line pulls this much further…
const PATIENT_ROOTS_ROOT_HOLD := 0.25  # …and holds this much longer, on top of the +0.25 s for every Hold
const KIND_CANOPY_WARDENS := ["acorn", "elder_stump", "grove_heart"]  # Kind Canopy (Seed card): these auras reach…
const KIND_CANOPY_REACH := 1.0  # …a cell further
const ACORN_CACHE_AURA := 0.10  # Acorn Cache: the Acorn's aura (dream_audit.md)
const GRANDFATHER_PER_WARDEN := 0.04  # Grandfather Stump: the Elder Stump +4% per Warden around it…
const GRANDFATHER_MAX := 0.45  # …up to this in all
const SHARED_LIGHT := 0.5  # Shared Light (Seed card): aura bonuses +50%
const QUIET_ONES := 0.5  # The Quiet Ones: non-attacking Wardens +50%
const BRAMBLE_OATH_WARDENS := ["bramble", "honeysuckle"]
const GROVE_SPEED_RULES: Array[StringName] = [&"momentum", &"quickening"]  # GroveRules (Swift)
const GROVE_AREA_RULES: Array[StringName] = [&"lingering_splash", &"great_ripple"]  # GroveRules (Wide Reach)
const WALL_DROWSY_CAP := 3  # Drowsy from walls (Honeysuckle, Scented Hedge) stops here; Wardens' Drowsy can go past it
const BRAMBLE_OATH := 0.5  # Bramble Oath (Seed card): +50%
const WALL_TICK := 0.2
const THORN_SNARE_KINDS := ["dandelion_seed", "gravecrawler"]  # Phantom (through), Gravecrawler (under)
const THORN_SNARE_REACH := 0.6  # Cells from the wall's centre that count as passing through / under it
const THORN_SNARE_SPRINT_REACH := 1.5  # II: a Night Hound sprinting past
const THORN_SNARE_TIME := [0.5, 1.0]
const SCENTED_HEDGE := 0.5  # Scented Hedge: the Thornwall's scent is half the Honeysuckle's
const LIVING_WALLS_DRIFTS := 5
const MANY_THREADS_DROWSY := 4
# The 9 hidden Kinships (tower_design.md; the hidden branch is side "a" of each)
const HOAR_FOG_PUFF := 2.0  # Hoar Fog A: Frostfern shots leave a 1-tile fog puff for this long (x share)
const SUNSPOT_RAMP := 0.10  # Sunspot B: Lanternmoth shots +10% per hit on the same target…
const SUNSPOT_RAMP_MAX := 0.5  # …up to +50% (x share)
const SPOTTER_SPLASH := 0.3  # Spotter B: Standing Stone shots splash 30%…
const SPOTTER_SPLASH_RADIUS := 0.75  # …within this many cells
const LANTERN_ROOTS_HOLD := 0.3  # Lantern Roots A: a lit tile holds a nightmare entering it (once)
const LANTERN_ROOTS_REVEAL := 3.0  # Lantern Roots B: Tangleroot's holds reveal hidden nightmares nearby this long
const RESONANT_ECHO := 0.3  # Resonant Hollow B: Chime Stone pulses echo once at 30%…
const RESONANT_ECHO_DELAY := 0.5  # …this long after
const RESONANT_CHARGES := 3  # Resonant Hollow A: echoes set off Static at 3 charges, like a chime
const JEWEL_THIEVES_EVERY := 6  # Jewel Thieves A: every 6th peck strips a buff (+1 Dew if there's none)
const TAILWIND_REACH := 3.0  # Tailwind B: Gust's copies reach this far
const AURA_RING_RADIUS := 28.0  # aura_ring_breath: its ring's radius in the 64 px sheet (1 cell)
const AURA_RING_SOFT := 0.22
const AURA_RING_BRIGHT := 0.55  # In build mode or with a selection
const LEAF_MOTE_AT := Vector2(8, -20)  # Where a boosted Warden's leaf mote starts, from its centre
const LEAF_MOTE_ALPHA := 0.35
const LEAF_MOTE_RISE := 6.0  # Pixels a second…
const LEAF_MOTE_SPAN := 14.0  # …over this far, then again
const RANK_SPEED := 0.04
const RANK_RANGE := 0.1  # Cells
const RANK_NAMES: Array[String] = ["", "I", "II", "III", "IV", "V", "VI", "VII"]

# The forms `data` can grow into, as the Warden panel lists them (screens_ui.md "Grow into"): a Sprout
# lists only the families picked this run (unpicked ones are hidden, not greyed); every other Warden
# lists all its forms, locked or not. [[TowerData, unlocked], …]
static func grow_options(dreams: DreamState, data: TowerData) -> Array:
	var options: Array = dreams.get_evolutions(data)
	if data.line != "sprout" or dreams.unlock_everything:
		return options
	return options.filter(func(option: Array) -> bool: return option[1])

const NO_FAMILY_YET := "Pick a family after the first drift to grow Sprouts."

const GROUP := &"wardens"
const BADGE_COLORS: Array[Color] = [Palette.MIST, Palette.SPRIG, Palette.DEWLIGHT, Palette.GOLD]  # Common … Legendary (UiStyle.RARITY)

# Card badges (screens_ui.md "Dream bonuses on Wardens", On the map): a Warden with an active position
# card shows a small badge at its base while in build mode or while Wardens are selected.
static var _badge_reasons := {}
var _badge_cards: Array = []  # Its active position cards (rows), refreshed with its neighbours

static func set_badges_visible(reason: StringName, on: bool) -> void:
	if on == _badge_reasons.has(reason):
		return
	if on:
		_badge_reasons[reason] = true
	else:
		_badge_reasons.erase(reason)
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		for tower in tree.get_nodes_in_group(GROUP):
			if on:
				tower._refresh_badge()  # Badges only refresh while they show
			tower.queue_redraw()

static func badges_visible() -> bool:
	return not _badge_reasons.is_empty()

# The active position cards on this Warden ([] = no badge).
func get_badge_cards() -> Array:
	return _badge_cards

func _refresh_badge() -> void:
	if is_inside_tree():
		_refresh_dream_rows()  # The badges come from the same pass as the Dream bonuses

# "IV", "XII"…: rank names past VII (Endless Rings) are worked out.
static func rank_name(value: int) -> String:
	if value < RANK_NAMES.size():
		return RANK_NAMES[maxi(value, 0)]
	var out := ""
	for pair in [[90, "XC"], [50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]:
		while value >= pair[0]:
			out += pair[1]
			value -= pair[0]
	return out
const FOCUS_RANK := 3  # The rank that asks for a Focus; its bonus counts from here on
const FOCUS_TOP_RANK := 5  # The Focus bonus stops here (Endless Rings: ranks past it only add damage)
const CHAIN_BLOOM_SPLASH := 2.0  # Chain Bloom: Puffball puffs landing in fog cover 2 tiles instead of 1
const STAT_TOP_RANK := 7  # Attack speed and range from ranks stop at VII (Endless Rings: VIII+ is damage only)
enum Focus { NONE, POWER, SWIFT, REACH, DEEP, WIDE, STRONG, KINDRED }  # Append only (saved as ints)
const FOCUS_NAMES := {Focus.POWER: "Power", Focus.SWIFT: "Swift", Focus.REACH: "Reach", Focus.DEEP: "Deep",
	Focus.WIDE: "Wide", Focus.STRONG: "Strong", Focus.KINDRED: "Kindred"}
const FOCUS_TEXT := {Focus.POWER: "+18% damage", Focus.SWIFT: "+12% attack speed", Focus.REACH: "+0.3 range",
	Focus.DEEP: "+18% Potency and status duration",
	Focus.WIDE: "+0.2 aura reach", Focus.STRONG: "+5% aura", Focus.KINDRED: "ignores the aura falloff"}
const FOCUS_COLORS := {Focus.POWER: Palette.EMBER, Focus.SWIFT: Palette.NEWLEAF,
	Focus.REACH: Palette.DEWLIGHT, Focus.DEEP: Palette.ORCHID,
	Focus.WIDE: Palette.SPRIG, Focus.STRONG: Palette.GLOW, Focus.KINDRED: Palette.BLOSSOM}
# Nurture v3 (warden_stats.md): every rank is a choice; each rank of a choice adds this.
const FOCUS_POWER := 0.18  # Damage
const FOCUS_SWIFT := 0.12  # Attack speed
const FOCUS_REACH := 0.3  # Range, cells
const FOCUS_DEEP := 0.18  # Potency and status duration
# Support Wardens (warden_stats.md "Support Wardens and Nurture", fdd7003): ranks multiply the aura (×1.1
# each) instead of damage, speed and range; their rank III Focus is Wide / Strong / Kindred.
const SUPPORT_AURA_WARDENS := ["elder_stump", "grove_heart"]  # Acorn keeps attacker ranks + Focus: its family's opener
const ATTACKER_FOCUSES: Array[Focus] = [Focus.POWER, Focus.SWIFT, Focus.REACH, Focus.DEEP]
const SUPPORT_FOCUSES: Array[Focus] = [Focus.WIDE, Focus.STRONG, Focus.KINDRED]
const AURA_PER_RANK := 1.1  # The aura bonus ×1.1 per rank (Grove Heart: its base only)
const FOCUS_WIDE := 0.2  # Wide, per rank: aura reach / catch radius (+1 cell over five ranks)
const FOCUS_STRONG_AURA := 0.05  # Strong, per rank: the aura +5% (×1.25 over five)
const FOCUS_STRONG_CATCH := 0.06  # Strong catchers, per rank: +6% catch (+30% over five)
const KINDRED_INTEREST := 0.004  # Kindred Wellspring, per rank: +0.4% interest (+2% over five)
const KINDRED_DEW := 0.8  # Kindred Dewcatcher, per rank: +0.8 Dew per drift (+4 over five)
# Same-kind auras stack with falloff: the strongest counts 100%, the next 50%, 25%… (Kindred: always 100%).
const AURA_FALLOFF := 0.5
const PIP_COLOR := Palette.GLOW
const RANK_ART := "res://assets/towers/ranks/rank_%d_%s.png"
const RANK_UP_ART := preload("res://assets/towers/ranks/rank_up.png")
const RANK_UP_FPS := 16.0
# Crit argument for hit(): roll the dice, or force it (a burst or splash uses its main hit's roll).
const ROLL_CRIT := -1
const NO_CRIT := 0
const CRIT := 1

# The grid cell this tower occupies (set by TowerPlacer).
var cell: Vector2
# All Dew put into this Warden (build cost, evolutions, ranks). Selling refunds a share of it.
var invested_dew := 0
var rest_dew := 0  # Dew spent on it during the current rest (refunded in full until the next drift)
static var resting := false  # A rest is on (TowerSeller keeps it in step with the DriftDirector)
# Nurture rank 0-5 (7 with Deeper Rings): each rank +10% damage, +4% attack speed, +0.1 range, and
# from rank III the Focus bonus. Kept through evolution, like the Focus (chosen at rank III, fixed).
# Setting it from outside (Dream cards, the save) refreshes the rank art and pips too.
var rank := 0:
	set(value):
		rank = value
		_update_rank_art()
		queue_redraw()
var focus: Focus = Focus.NONE:
	set(value):
		focus = value
		queue_redraw()
# Nurture v3: the choice made at each rank (kept through evolution, never changed). `focus` is the latest
# one (old saves: their rank III Focus, migrated by _migrate_choices).
var rank_choices: Array[int] = []

# "Power ×2, Reach": the rank choices, for labels.
func choices_text() -> String:
	_migrate_choices()
	var parts: Array[String] = []
	for which in focus_options():
		var n := rank_choices.count(which)
		if n > 0:
			parts.append(FOCUS_NAMES[which] + (" ×%d" % n if n > 1 else ""))
	return ", ".join(parts)

func choice_count(which: Focus) -> int:
	_migrate_choices()
	return rank_choices.count(which)

# Old saves and ranks given by Dreams: Power (supports: their first option) for I–II, the old Focus from III.
func _migrate_choices() -> void:
	if rank_choices.size() == rank:
		return
	var fallback: int = focus_options()[0]
	while rank_choices.size() < rank:
		rank_choices.append(focus if rank_choices.size() >= 2 and focus != Focus.NONE else fallback)
	if rank_choices.size() > rank:
		rank_choices.resize(rank)

# The choice a rank takes when none is given (a free rank from a Dream): the latest, else the first option.
func default_choice() -> Focus:
	_migrate_choices()
	return rank_choices[-1] as Focus if not rank_choices.is_empty() else focus_options()[0]
# What the attack does: `tower_data` itself, or for a Graftling the neighbour it copies.
var attack_data: TowerData
# Who snipers shoot at (the player can change it in the Warden panel).
var target_mode: TowerData.TargetMode = TowerData.TargetMode.FIRST
var target_chosen := false  # The player set target_mode (kept through growing, saved with the run)
var is_selected := false  # In TowerSeller's selection (the targeting pip shows)

var _cooldown := 0.0  # Seconds until the tower can attack again
var _anim_time := 0.0
var _attack_time := -1.0  # Seconds into the attack animation; negative while idling
var _attack_fps := 0.0
var _released := false  # The current attack's shot / pulse has happened
var _pending_pull := Callable()  # Rootcurl / Long Way Home: the pull waits for the attack's release frame (the lash)
var _pull_only := false  # The attack animation playing is only for that pull (no shot at release)
var _attack_count := 0  # For "every Nth attack" effects (Thunderhead)
var _damage_share := 1.0  # Graftling: share of the copied Warden's damage
var _dream_state: DreamState
var _omens: OmenDirector  # Fog Bank (range) and Wilting (attack speed) Omens
var _hit_before := {}  # Nightmare instance ids already hit (Moonstone's first-hit crit)
var _rings: Array[FairyRing] = []
var _beam_target: Node2D = null
var _beam_behind: Node2D = null
var _beam_ramp := 1.0
var _beam_tick := 0.0
var _aura_tick := 0.0
var _neighbour_timer := 0.0
var _aura_crit := 0.0  # From a White Stag in range
var _aura_range := 0.0  # From a Moon Moth nearby
var _aura_damage := 0.0  # From a Grandmother Oak nearby
var _aura_speed := 0.0
var _aura_damage_from: Tower = null  # The aura Warden behind _aura_damage (SupportLog credits it)
var _aura_speed_from: Tower = null
# Boss pools (enemy_design.md): the Lamplighter's cold lanterns slow Wardens near them (set each frame
# by the EnemyContainer; 1.0 = none), and the Withering Oak withers one (no attacks while it lasts).
var dim_multiplier := 1.0
var withered_left := 0.0
const WITHERED_TINT := Color(0.55, 0.55, 0.5)  # A multiplier (self_modulate) on the Warden art, not a colour
var _last_fired: Node2D = null  # The nightmare its last projectile flew at (Spotter: the sniper's target)
var _ramp_target: Node2D = null  # Sunspot B: the nightmare the last hits went to…
var _ramp_hits := 0  # …and how many in a row
var _nursery_ring: FairyRing = null  # Spore Nursery B: the one ring its puffs planted
var _jewel_pecks := 0  # Jewel Thieves A
var _graft_status: Array = []  # True Graft B: [status, stacks] of the strongest neighbour
var _leaf_mote: Node2D = null  # Drifts up in _process while an aura boosts this Warden
# Grafted Harmony (a Crowned delivery rule): a Graftling touching Wardens of 2+ status families also
# applies each of their statuses at half strength. Status id -> stacks; its two-tone glow.
var _harmony := {}
var _harmony_glow: Array = []
var _lit_cells: Array[Vector2] = []  # Rootlight: path tiles it lights
var _twist: StringName = &""  # Its final form's signature twist (FinalTwists), or ""
var _twist_state := {}  # The twist's own state (timers, counts)
var _chorus := 0.0  # Lullaby Bell's Chorus: +damage from the Bellflower-family Wardens around it
var _grove := {}  # Grove build-branch state (GroveRules): Momentum streak, Quickening, area counts
var _lit_until := {}  # Long Light: cell -> _anim_time it stops being lit (after the light moved on)
var _out: Array = []  # Hummingbirds / seeds that are away (the next attack waits for them)
var _catch_tick := 0.0
var _pecks_landed := 0  # Jewelwing Court's Flurry: every Nth peck crits
var _throws := 0  # Seed Storm: every 5th throw
var _catch_streak := 0.0  # Autumn Gale: +damage on the next throw from catches
var _seeds_thrown := 0
var _seeds_home := 0
var _throw_hit := false
var focus_strongest := false  # Jewelwing Court's toggle: all birds on the strongest nightmare
var _echo_tracker: ReactionTracker = null
var _patrol: PatrolFlight = null
var _aura_count := 0  # Other Wardens inside this Warden's aura (Grove Heart)
var _kin: Kinships = null  # The run's Kinships (two branches of one family bond)
var _root_links: Array[Vector2] = []  # Root Network: directions to touching Sprouts (glow on shared edges)
var kin_branch := ""  # The branch an Ascended form grew from (Kinships); saved with the run
var footprint_size := 0  # 0 = the data's footprint; 1 keeps an old save's 1-cell Ascended form
var _hits_landed := 0  # Eternal Charge / Rooted Nightmares count this Warden's hits
var _hunted := {}  # Hunter's Moon: nightmares this Warden has hit (instance ids)
var bloom_left := 0.0  # Sudden Bloom: seconds left at ×2 damage after growing
const SUDDEN_BLOOM_SECONDS := 10.0  # dream_audit.md: was "next 3 attacks ×2"
var watch_charged := false  # Watchful Rest: a stored charge (its next attack deals ×2)
var _watch_time := 0.0  # Watchful Rest: seconds with nothing in range
var _hit_boost := 1.0  # ×2 while a boosted attack's hits land (Sudden Bloom, Watchful Rest)
var _underdog_drawn := false
var legacy_data: TowerData = null  # An Ascended form's final form (its legacy attack); saved with the run
var _legacy_cooldown := 0.0
var _legacy_active := false  # Inside the legacy attack (a legacy beam leaves the sprite alone)
const EMPOWERED_MULTIPLIER := 2.0
const WATCH_CHECK := 0.25  # Watchful Rest looks for nightmares this often
var _watch_check := 0.0
const ETERNAL_STATIC_EVERY := 4
const ROOTED_NIGHTMARES_EVERY := 8
const ROOTED_TIME := 1.0
const ROOTED_BOSS_TIME := 0.5
var _ability_timer := 0.0  # Rootcurl / Tangleroot / Beacon: seconds until the timed ability
var _drifts_yielded := 0  # Sapling: drifts since planted (Dreamlight every N)
var _wither := 0  # Sapling: leaves lost since the last rest (−5% yield each)
var _last_leaves := -1
var _crit_dew_drift := -1  # Magpie's Hoard: drift the crit-Dew count belongs to
var _crit_dew_given := 0

func _ready() -> void:
	_dream_state = get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	if _dream_state:
		GroveRules.listen(self)  # Quickening: dispels in range speed Wardens up
	_omens = get_tree().get_first_node_in_group(OmenDirector.GROUP) as OmenDirector
	if _dream_state:
		_dream_state.card_taken.connect(clear_dream_cache.unbind(1))
		if _dream_state.map_generator:
			_dream_state.map_generator.path_changed.connect(_on_map_changed)
	add_to_group(GROUP)
	_apply_data()
	# Start each tower at a random point in its idle loop so neighbours don't breathe in sync.
	_anim_time = randf() * tower_data.frame_count / tower_data.animation_fps

func _apply_data() -> void:
	clear_dream_cache()
	_aura_support = SUPPORT_AURA_WARDENS.has(tower_data.get_id())
	_twist = FinalTwists.twist_of(tower_data)
	_twist_state = {}
	attack_data = tower_data
	_damage_share = 1.0
	if not target_chosen:
		target_mode = tower_data.target_mode  # A mode the player chose is kept through growing
	_attack_time = -1.0
	_flush_pull()  # Grown mid-lash: the pull still happens
	_stop_beam()
	sprite.offset = tower_data.sprite_offset
	_show_idle()
	_update_withered()
	_refresh_neighbours()
	_show_bowl()
	_connect_echo.call_deferred()  # Echo Hollow listens for Reactions (after entering the tree)
	_connect_yield.call_deferred()  # Grandmother Oak / the Sapling pay out after each drift
	if is_instance_valid(_patrol) and attack_data.attack_kind != TowerData.AttackKind.PATROL:
		_patrol.queue_free()
	queue_redraw()

# Grows into `data` in place (the cell and path don't change). `cost` is added to invested Dew.
func evolve(data: TowerData, cost: int) -> void:
	# An Ascended form keeps the branch it grew from, so its Kinship stays ("evolving keeps it").
	if data.tier >= DreamState.ASCENDED_TIER and kin_branch == "":
		kin_branch = Kinships.branch_of(tower_data)
	# A Warden keeps its size unless it was given room: TowerPlacer takes the 2×2 square first (and sets
	# footprint_size); growing any other way stays on the cells it has.
	var size := get_footprint()
	if data.tier >= DreamState.ASCENDED_TIER and tower_data.tier == DreamState.ASCENDED_TIER - 1:
		legacy_data = tower_data  # It keeps its final form's attack
	tower_data = data
	if size != data.footprint:
		footprint_size = size
	invested_dew += cost
	if resting:
		rest_dew += cost
	_apply_data()
	_nudge_neighbours()
	if _rule_stacks(&"sudden_bloom") > 0:
		bloom_left = maxf(bloom_left, SUDDEN_BLOOM_SECONDS * _rule_power(&"sudden_bloom"))  # ×2 damage for 10 s
		queue_redraw()
	evolved.emit(self)
	if data.tier >= 4:
		ascended.emit(self)

func _process(delta: float) -> void:
	_anim_time += delta
	if is_instance_valid(_leaf_mote):
		_leaf_mote.position = LEAF_MOTE_AT + Vector2(0, -fmod(_anim_time * LEAF_MOTE_RISE, LEAF_MOTE_SPAN))
	_tick_dream_cache(delta)
	_neighbour_timer -= delta
	if _neighbour_timer <= 0.0 and _refresh_slot():
		_refresh_neighbours()
	if _attack_time >= 0.0:
		_advance_attack(delta)
	else:
		# Performance: frames change a few times a second; only set them when they do (each set redraws),
		# and the rank art / Withered overlay are looked up by name only when this frame changed.
		var idle_frame := int(_anim_time * tower_data.animation_fps)
		if idle_frame != _last_idle_frame:
			_last_idle_frame = idle_frame
			if _beam_target == null:
				sprite.frame = idle_frame % tower_data.frame_count
			if is_catcher():
				_bob_bowl()
			if tower_data.withered_texture != null:
				var withered := get_node_or_null("Withered") as Sprite2D
				if withered:
					withered.frame = sprite.frame % tower_data.frame_count
			if rank > 0:
				for art in [get_node_or_null("RankUnder"), get_node_or_null("RankOver")]:
					if art:
						art.frame = idle_frame % 8
	if tower_data.get_id() == "thornwall" and _dream_state:
		_update_wall(delta)
	if not tower_data.can_attack:
		return
	if withered_left > 0.0:  # Withering Oak: grey and drooping, no attacks until it comes back
		withered_left -= delta
		if withered_left <= 0.0:
			sprite.self_modulate = Color.WHITE
		return
	if tower_data.caught_bonus > 0.0:
		_update_catch(delta)  # Dreamcatchers catch sleepy nightmares whether or not they're shooting
	if attack_data.ability_every > 0.0:
		_update_ability(delta)
	if attack_data.lit_hold_multiplier > 0.0 and not _lit_cells.is_empty():
		_update_lit_holds(delta)
	if attack_data.copy_status_every > 0.0:
		_update_status_copy(delta)
	_update_legacy(delta)
	if _twist != &"":
		FinalTwists.update(self, delta)  # Signature twists (tower_design.md)
	match attack_data.attack_kind:
		TowerData.AttackKind.AURA:
			_update_aura(delta)
			return
		TowerData.AttackKind.PATROL:
			if not is_instance_valid(_patrol):
				_patrol = PatrolFlight.new(self)  # Dawnwing's bird / The Whirlwind's cyclone
				add_child(_patrol)
			if attack_data.patrol_idle_texture != null:
				# Dawnwing: the perch is empty while the bird is out.
				sprite.texture = attack_data.patrol_idle_texture if _patrol.is_out() else tower_data.texture
			return
		TowerData.AttackKind.BEAM:
			_update_beam(delta)
			return
		TowerData.AttackKind.COPY:
			return  # A Graftling with nothing to copy
	_update_watch(delta)
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown > 0.0 or _attack_time >= 0.0:
		return
	# Performance: a Warden with nothing to do looks again IDLE_SEARCH seconds later instead of every
	# frame (with ~200 Wardens the searches were ~10 ms a frame). A nightmare walks ~20 px meanwhile.
	_idle_search -= delta
	if _idle_search > 0.0:
		return
	if not _has_work():
		_idle_search = IDLE_SEARCH * randf_range(0.75, 1.25)  # Jittered: Wardens planted together don't all search on one frame
		return
	_start_attack()

# Whether an attack now would do anything.
func _has_work() -> bool:
	match attack_data.attack_kind:
		TowerData.AttackKind.TRAP:
			# Untyped lambda + assign(): a freed ring can't be passed to a typed parameter, and filter()
			# returns an untyped Array (the old line errored every frame once a ring had gone).
			_rings.assign(_rings.filter(func(r) -> bool: return is_instance_valid(r) and not r.is_spent()))
			return _rings.size() < attack_data.trap_max and not _free_trap_cells().is_empty()
		TowerData.AttackKind.SPIN:
			return not _enemies_on_adjacent_tiles().is_empty()
		TowerData.AttackKind.PECK, TowerData.AttackKind.BOOMERANG:
			# Hummingbirds and seeds must come home before the next attack.
			_out = _out.filter(func(n) -> bool: return is_instance_valid(n))
			if not _out.is_empty():
				return false
	return has_enemy_in_range()  # Performance: whether one is in range, not which (find_target scores them)


# --- Effective stats (base × Dreams) ----------------------------------------------------------------

func get_damage() -> float:
	if _stats_fresh() and _stats.has(&"damage"):
		return _stats[&"damage"]
	_stats[&"damage"] = _compute_damage()
	return _stats[&"damage"]

func _compute_damage() -> float:
	return attack_data.damage * _damage_share * get_rank_damage_multiplier() * (1.0 + _aura_damage) \
		* _dream_bonus(&"soothe") \
		* (1.0 + (_kin.damage_bonus(self) if is_instance_valid(_kin) else 0.0)) \
		* get_wall_multiplier() * (1.0 + _chorus) \
		* (1.0 + (GroveRules.hummingheart(self, get_attacks_per_second()) if _dream_state and _has_rule(&"hummingheart") else 0.0))
	# (Kindred / Whole Tree, Kinship cards; Bramble Oath; Lullaby Bell's Chorus; Hummingheart: bonus speed as damage)

# Withering Oak: the Warden withers for `seconds` (grey, no attacks), then comes back unharmed.
func wither(seconds: float) -> void:
	withered_left = maxf(withered_left, seconds)
	sprite.self_modulate = WITHERED_TINT

func is_withered() -> bool:
	return withered_left > 0.0

func get_attacks_per_second() -> float:
	var momentum := FinalTwists.momentum(self) if _twist == &"momentum" else 0.0  # Windmill: spins up
	if _dream_state and _any_rule(&"grove_speed", GROVE_SPEED_RULES):
		momentum += GroveRules.speed_bonus(self)  # Momentum (a streak), Quickening (a dispel in range)
	if _stats_fresh() and _stats.has(&"speed"):
		return _stats[&"speed"] * (1.0 + momentum)
	_stats[&"speed"] = _compute_attacks_per_second()
	return _stats[&"speed"] * (1.0 + momentum)

func _compute_attacks_per_second() -> float:
	var ranks := mini(get_effective_rank(), STAT_TOP_RANK)
	var speed := 1.0 + RANK_SPEED * _plain_ranks() + FOCUS_SWIFT * choice_count(Focus.SWIFT)  # Nurture v3
	if is_aura_support():
		speed = 1.0  # Its ranks scale the aura instead
	var dreams := 1.0
	if _dream_state:
		dreams = _dream_state.get_attack_speed_multiplier(tower_data)
		if _dream_state.has_method("get_tower_attack_speed_bonus"):
			dreams += _dream_bonus(&"speed")  # Sprout Chorus, The Last Light
	var omen := _omens.get_warden_speed_multiplier() if _omens and _omens.has_method("get_warden_speed_multiplier") else 1.0  # Wilting
	if _big_family:
		speed += DreamState.BIG_FAMILY_SPEED * _rule_power(&"big_family")  # Big Family: a Sprout near a Kinship pair
	var bonus := speed * dreams * (1.0 + _aura_speed) * omen
	if _dream_state and _has_rule(&"whirlwind_heart"):
		bonus = GroveRules.whirlwind(self, bonus)  # Whirlwind Heart: the bonus part counts double
	return attack_data.attacks_per_second * bonus * dim_multiplier \
		* (get_wall_multiplier() if attack_data.damage <= 0 else 1.0)  # Honeysuckle: Bramble Oath, The Quiet Ones

func get_range_cells() -> float:
	if _stats_fresh() and _stats.has(&"range"):
		return _stats[&"range"]
	_stats[&"range"] = _compute_range_cells()
	return _stats[&"range"]

var _range_frame := -1
var _last_idle_frame := -1  # The idle animation frame last shown (see _process)
const BEAM_KEEP_TIME := 1.0  # Midsummer keeps part of its ramp for this long after losing a target
var _kept_ramp := 1.0
var _kept_ramp_at := -100.0
const IDLE_SEARCH := 0.25
var _idle_search := 0.0  # Seconds until an idle Warden looks for a target again
var _range_data: TowerData = null
var _range_value := 0.0

# Performance: damage, attack speed and range are asked for on every hit, search and attack (a range
# was ~36 µs to work out: ranks, the court, Dreams, Omens). They're kept while nothing they read has
# changed: the form, rank, Focus, auras, copy share, the board and the taken cards, the Kinship pairs
# and the active Omen; STAT_CACHE_TIME is the backstop for the rest (the Eldest's court, Omen timing).
# clear_dream_cache drops them too.
const STAT_CACHE_TIME := 2.0
var _stats := {}
var _stats_key := []
var _stats_until := -1.0

func _stats_fresh() -> bool:
	var key := [attack_data, rank, focus, _aura_range, _aura_damage, _aura_speed, _damage_share, _aura_crit, dim_multiplier, _big_family,
		_dream_state.board_version if _dream_state else 0, _dream_state.stacks.size() if _dream_state else 0,
		_kin.get_pairs(self).size() if is_instance_valid(_kin) else 0,
		_kin.families.hash() if is_instance_valid(_kin) else 0,
		_chorus,
		_omens.active if _omens else null]
	if key != _stats_key or _anim_time > _stats_until:
		_stats_key = key
		_stats = {}
		_stats_until = _anim_time + STAT_CACHE_TIME * randf_range(0.75, 1.25)  # Staggered: ~200 Wardens never all recompute in one frame (a 60 ms hitch every 2 s)
		return false
	return true

func _compute_range_cells() -> float:
	var ranks := mini(get_effective_rank(), STAT_TOP_RANK)
	var reach := RANK_RANGE * _plain_ranks() + FOCUS_REACH * choice_count(Focus.REACH)  # Nurture v3
	if is_aura_support():
		reach = 0.0  # Its ranks scale the aura instead
	if _dream_state and _dream_state.has_method("get_tower_range_bonus"):
		reach += _dream_bonus(&"range")  # Solitude
	var total := get_range_for(attack_data, _dream_state) + _aura_range + reach
	if tower_data.get_id() == "honeysuckle" and _rule_stacks(&"sweet_scent") > 0:
		total = maxf(total, DreamState.SWEET_SCENT_TILES * _rule_power(&"sweet_scent"))  # Sweet Scent
	if tower_data.line == "song" and attack_data.attack_kind == TowerData.AttackKind.PULSE:
		total *= 1.0 + HUSH_RADIUS * _rule_stacks(&"hush") * _rule_power(&"hush")  # Hush: wider song pulses
	if _omens and _omens.has_method("get_warden_range_add"):
		var fog: float = _omens.get_warden_range_add()  # Fog Bank: -1 range, never below 1
		if fog != 0.0:
			total = maxf(total + fog, minf(total, 1.0))
	return total


# --- Nurture ranks -------------------------------------------------------------------------------------

# The rank that counts for stats (The Old Ones can lift it by one next to a rank V+ Warden).
func get_effective_rank() -> int:
	if _dream_state and _dream_state.has_method("get_effective_rank"):
		return _dream_state.get_effective_rank(self)
	return rank

# Ranks from III up (the ones that carry the Focus bonus).
static func _focus_ranks(ranks: int) -> int:
	return maxi(mini(ranks, FOCUS_TOP_RANK) - FOCUS_RANK + 1, 0)  # Focus stops at V

# Damage multiplier from ranks: +10% each (+ Warm Hands), + Power's +8% from rank III.
func get_rank_damage_multiplier() -> float:
	if is_catcher() or is_aura_support():
		return 1.0  # Catchers' ranks add catch; aura supports' ranks scale the aura (get_aura_bonus)
	var warm := 0.0
	if _dream_state and _dream_state.has_method("get_rank_damage_bonus"):
		warm = _dream_state.get_rank_damage_bonus()  # Warm Hands: every rank, whatever it chose
	return 1.0 + RANK_DAMAGE * _plain_ranks() + warm * rank + FOCUS_POWER * choice_count(Focus.POWER)

# Rank-equivalents that aren't chosen ranks (The Old Ones' +1, the Eldest's Court): the plain old gains.
func _plain_ranks() -> float:
	return maxf(get_effective_rank() - rank, 0) + get_court_ranks()

# Court of the Eldest: rank-equivalents from touching the Eldest (25% of its rank). They count for the
# per-rank damage, attack speed and range, never the Focus.
func get_court_ranks() -> float:
	var court := 0.0
	if _dream_state and _dream_state.has_method("get_court_rank_share"):
		court = _dream_state.get_court_rank_share(self)
	# Elder Kin (Dream): a ranked kin shares 25% of its ranks, like the Court.
	if is_instance_valid(_kin) and _rule_stacks(&"elder_kin") > 0:
		for pair in _kin.get_pairs(self):
			var partner: Tower = pair.b if pair.a == self else pair.a
			if is_instance_valid(partner) and partner.rank > 0:
				court += DreamState.ELDER_KIN_SHARE * _rule_power(&"elder_kin") * partner.rank
	return court

# Potency: the multiplier on this Warden's effect damage (Spored, Static bolts, clouds, pops, Reactions
# it completes, echoes). The Warden's own (100% by default) + Dreams (Bitter Sap, Venom Bloom,
# Nightshade) + the Deep Focus (+10% per rank III–V).
func get_potency() -> float:
	var total := attack_data.potency
	if _dream_state and _dream_state.has_method("get_potency_bonus"):
		total += _dream_state.get_potency_bonus(tower_data)
	total += FOCUS_DEEP * choice_count(Focus.DEEP)  # Deep ranks
	return total

# Deep Focus: status strength and duration multiplier.
func get_status_focus_multiplier() -> float:
	return 1.0 + FOCUS_DEEP * choice_count(Focus.DEEP)

func get_max_rank() -> int:
	var cap := RANK_MAX
	if _dream_state and _dream_state.has_method("get_max_rank_for"):
		cap = _dream_state.get_max_rank_for(self)  # Past V only for the Eldest
	elif _dream_state and _dream_state.has_method("get_max_rank"):
		cap = _dream_state.get_max_rank()
	# Nurture v3: ranks I–V for Dew, no Nurture Dream needed (Deeper Rings still opens VI–VII).
	cap = maxi(cap, RANK_MAX)
	return cap

const UNDREAMED_MAX_RANK := 2

func has_nurture_dream() -> bool:
	return _dream_state == null or not _dream_state.has_method("count_taken_with_tag") \
		or _dream_state.count_taken_with_tag("nurture") > 0

# Why the next rank can't be bought, for the Nurture button ("" = it can, or it's simply the top).
func nurture_blocker() -> String:
	return ""  # Nurture v3: nothing gates ranks I–V any more

# Attacking Wardens can be nurtured (not walls or wall growths, not the White Stag's aura).
func can_be_nurtured() -> bool:
	if tower_data.dew_per_rank > 0:
		return true  # The Heartwood Sapling: ranks raise its yield
	return tower_data.can_attack and tower_data.line != "wall" \
		and tower_data.attack_kind != TowerData.AttackKind.AURA

func can_nurture() -> bool:
	return can_be_nurtured() and rank < get_max_rank()

# The next rank asks for a Focus first (rank II -> III, no Focus yet).
func needs_focus() -> bool:
	return can_nurture() and tower_data.dew_per_rank <= 0  # Nurture v3: every rank is a choice (the Sapling's ranks only raise its yield)

# Support Wardens: the aura ones (ranks scale the aura) and the catchers (ranks add catch).
func is_support() -> bool:
	return is_aura_support() or is_catcher()

func is_aura_support() -> bool:
	return _aura_support  # Cached in _apply_data (asked in hot paths)

# The Focus choices at rank III: Wide / Strong / Kindred for support Wardens, else Power / Swift / Reach / Deep.
func focus_options() -> Array[Focus]:
	return SUPPORT_FOCUSES if is_support() else ATTACKER_FOCUSES

# What `which` does for this Warden (catchers read their catch versions).
func focus_text(which: Focus) -> String:
	if is_catcher():
		match which:
			Focus.WIDE:
				return "+1 catch radius"
			Focus.STRONG:
				return "+10% catch per rank III–V"
			Focus.KINDRED:
				return "+%d%% interest" % roundi(KINDRED_INTEREST * 100) if tower_data.rest_interest > 0.0 else "+%d Dew each drift" % KINDRED_DEW
	return FOCUS_TEXT.get(which, "")

# Cost multiplier from the Warden's tier right now: Sprout ×0.5, base ×1, branch ×2, final ×3,
# Memory Warden ×2.
func get_tier_cost_multiplier() -> float:
	return tier_cost_multiplier_for(tower_data)

# Nurture price multiplier for a Warden of `data`: Sprout ×0.5, base ×1, branch ×2, final ×3,
# Ascended ×4, Memory Wardens ×2, the Sapling its own.
static func tier_cost_multiplier_for(data: TowerData) -> float:
	if data.nurture_cost_multiplier > 0.0:
		return data.nurture_cost_multiplier  # The Heartwood Sapling ranks at the final-form price
	if data.tier >= 4:
		return 4.0  # Ascended
	if data.is_unique:
		return 2.0
	match data.tier:
		0:
			return 0.5
		1:
			return 1.0
		2:
			return 2.0
	return 3.0

# The Dew rank `which` (1 = I) costs for a Warden of `data`, with today's Dream discounts. `self_price`:
# this Warden's own discounts (Nursery's Sprout half price); otherwise the ones a grown form would get.
func _rank_price_for(which: int, data: TowerData, self_price: bool) -> int:
	var base: float = RANK_COSTS[which - 1] if which <= RANK_COSTS.size() else 0.0
	if which > RANK_COSTS.size() and _dream_state and _dream_state.has_method("get_extra_rank_cost"):
		base = _dream_state.get_extra_rank_cost(which)
	var multiplier := tier_cost_multiplier_for(data)
	if _dream_state and _dream_state.has_method("get_nurture_cost_multiplier"):
		multiplier *= _dream_state.get_nurture_cost_multiplier(self if self_price else null)
	if _dream_state and _dream_state.has_method("rank_cost_factor"):
		var factor: float = _dream_state.rank_cost_factor(which)  # Tender Care: rank I free, II: ranks II–V 20% off
		if factor <= 0.0:
			return 0
		multiplier *= factor
	return maxi(roundi(base * multiplier), 1)

# What growing into `into` costs (warden_stats.md "Growing a ranked Warden pays the rank difference"):
# the evolve cost plus, for each rank held, that rank's price at the new tier minus its price at this
# one (free ranks pay it too). {"total", "base", "ranks"}. Every Grow button, group grow, the G hotkey
# and TowerPlacer.evolve use this, so they all agree.
func get_grow_cost(into: TowerData) -> Dictionary:
	var base: int = _dream_state.get_evolve_cost(into) if _dream_state else into.evolve_cost
	var ranks := 0
	for which in range(1, rank + 1):
		ranks += maxi(_rank_price_for(which, into, false) - _rank_price_for(which, tower_data, true), 0)
	return {"total": base + ranks, "base": base, "ranks": ranks}

# What the next rank adds to growing into `into` (warden_stats.md: growing pays the ranks held; the
# Nurture button says so, so players don't rank a Warden out of its growth).
func get_next_rank_growth_extra(into: TowerData) -> int:
	var which := rank + 1
	return maxi(_rank_price_for(which, into, false) - _rank_price_for(which, tower_data, true), 0)

# The growth the Nurture button warns about: the first form open now, else the first that can be unlocked.
func next_growth() -> TowerData:
	var options := grow_options(_dream_state, tower_data) if _dream_state else []
	for option in options:
		if option[1]:
			return option[0]
	return options[0][0] if not options.is_empty() else null

# Dew for the next rank (0 when it can't be nurtured further).
func get_nurture_cost() -> int:
	if not can_nurture():
		return 0
	if free_nurtures_left() > 0:
		return 0  # First Care: the run's first few ranks are free
	return get_nurture_price()

# First Care (a Grove perk): free Nurture ranks left this run (RunState.free_nurtures).
func free_nurtures_left() -> int:
	var run_state = _dream_state.run_state if _dream_state else null
	return run_state.free_nurtures if run_state and "free_nurtures" in run_state else 0

# Dew for the next rank at its normal price (ignoring First Care's free ranks).
func get_nurture_price() -> int:
	if not can_nurture():
		return 0
	var next := rank + 1
	var base: float = RANK_COSTS[rank] if rank < RANK_COSTS.size() else 0.0
	if next > RANK_COSTS.size() and _dream_state and _dream_state.has_method("get_extra_rank_cost"):
		base = _dream_state.get_extra_rank_cost(next)  # Deeper Rings: VI and VII
	var multiplier := get_tier_cost_multiplier()
	if _dream_state and _dream_state.has_method("get_nurture_cost_multiplier"):
		multiplier *= _dream_state.get_nurture_cost_multiplier(self)  # Nursery: Sprouts at half price
	if _dream_state and _dream_state.has_method("rank_cost_factor"):
		var factor: float = _dream_state.rank_cost_factor(next)  # Tender Care: rank I free, II: ranks II–V 20% off
		if factor <= 0.0:
			return 0
		multiplier *= factor
	return maxi(roundi(base * multiplier), 1)

# Raises the rank by one; `cost` is added to invested Dew (TowerPlacer.nurture charges it).
# `chosen` sets the Focus when this is the rank that asks for one.
func nurture(cost: int, chosen: Focus = Focus.NONE) -> void:
	if chosen == Focus.NONE or not focus_options().has(chosen):
		chosen = default_choice()
	_migrate_choices()
	var before := rank
	rank = mini(rank + 1, get_max_rank())
	if rank > before:
		rank_choices.append(chosen)
		focus = chosen
	clear_dream_cache()
	_nudge_neighbours()
	invested_dew += cost
	if resting:
		rest_dew += cost
	_play_rank_up()
	queue_redraw()
	nurtured.emit(self)

# The rank's slab art: a halo under the sprite, and a looping overlay on the slab's rim over it.
func _update_rank_art() -> void:
	var under := get_node_or_null("RankUnder") as Sprite2D
	var over := get_node_or_null("RankOver") as Sprite2D
	var art_rank := mini(rank, 7)
	if tower_data.rank_overlay_texture != null:
		# The Sapling has its own rank art: one overlay frame per rank, drawn over it.
		var overlay := get_node_or_null("RankOverlay") as Sprite2D
		if art_rank <= 0:
			if overlay:
				overlay.queue_free()
			return
		if overlay == null:
			overlay = Sprite2D.new()
			overlay.name = "RankOverlay"
			add_child(overlay)
		overlay.texture = tower_data.rank_overlay_texture
		overlay.hframes = tower_data.rank_overlay_frames
		overlay.frame = mini(art_rank, tower_data.rank_overlay_frames) - 1
		overlay.offset = tower_data.sprite_offset
		return
	if art_rank <= 0:
		for node in [under, over]:
			if node:
				node.queue_free()
		return
	if under == null:
		under = Sprite2D.new()
		under.name = "RankUnder"
		under.hframes = 8
		add_child(under)
		move_child(under, 0)  # Drawn before (under) the Warden's sprite
	if over == null:
		over = Sprite2D.new()
		over.name = "RankOver"
		over.hframes = 8
		add_child(over)
	under.texture = load(RANK_ART % [art_rank, "under"])
	over.texture = load(RANK_ART % [art_rank, "over"])

func _play_rank_up() -> void:
	if not is_inside_tree():
		return
	var burst := Sprite2D.new()
	burst.texture = RANK_UP_ART
	burst.hframes = 8
	burst.z_index = 2
	add_child(burst)
	var tween := burst.create_tween()
	tween.tween_property(burst, "frame", 7, 7.0 / RANK_UP_FPS)
	tween.tween_callback(burst.queue_free)

func get_splash_cells() -> float:
	if attack_data.splash_radius <= 0.0:
		return 0.0
	var broad: float = _dream_state.get_area_radius_add() if _dream_state and _dream_state.has_method("get_area_radius_add") else 0.0  # Broad Splash
	return (attack_data.splash_radius + broad) * (_dream_state.get_splash_multiplier(tower_data) if _dream_state else 1.0)

func get_crit_chance(enemy: Node2D = null) -> float:
	return minf(get_raw_crit_chance(enemy), 1.0)

# Crit chance before the 100% cap (Full Moon turns what's above 100% into crit damage).
func get_raw_crit_chance(enemy: Node2D = null) -> float:
	# Performance: the part that doesn't depend on the nightmare rides the stat cache (asked every hit).
	var cached: Array = _stats.get(&"crit_base", []) if _stats_fresh() else []
	var chance := -1.0
	if not cached.is_empty() and cached[1] == attack_data.crit_chance:
		chance = cached[0]
	else:
		chance = attack_data.crit_chance + _aura_crit + 0.1 * kin_share(&"hammer_and_anvil", "a")  # Hammer and Anvil: the sniper's eye
		if _dream_state and _dream_state.has_method("get_rank_crit_bonus"):
			chance += _dream_state.get_rank_crit_bonus() * get_effective_rank()  # The Old Ones
		_stats[&"crit_base"] = [chance, attack_data.crit_chance]  # (the data's own chance too: tests change it in place)
	if _dream_state and _dream_state.has_method("get_crit_chance_bonus"):
		chance += _dream_state.get_crit_chance_bonus(self, enemy)  # Still Target, Starlit Aim, Full Moon…
	if enemy != null and enemy.statuses.is_held():
		chance += attack_data.crit_bonus_vs_held
	return chance

# Range in cells for `data` including Dreams (shared with the build ghost).
static func get_range_for(data: TowerData, dream_state: DreamState) -> float:
	return data.attack_range + (dream_state.get_range_bonus(data) if dream_state else 0.0)


# --- Neighbours and auras -----------------------------------------------------------------------------

# Other Wardens on the map (the tower's siblings).
# Performance: other Wardens bucketed by TOWER_BUCKET px, rebuilt only when Wardens come, go or move
# (towers_moved), so a neighbour scan looks at the ~9 buckets around it, not the whole map.
const TOWER_BUCKET := 320.0  # 5 cells: past the furthest neighbour effect (the White Stag's crit aura, 4)
const NEIGHBOUR_REACH := 5.0  # Cells: past every neighbour effect (auras 4 with Wide + Kind Canopy, a relay +1.5)
static var _tower_buckets := {}
static var _tower_key := []
static var _towers_epoch := 0

static func towers_moved() -> void:
	_towers_epoch += 1

# Other Wardens within about 5 cells (a superset: callers check the distance).
func _towers_near() -> Array:
	var parent := get_parent()
	if parent == null:
		return []
	var key := [parent.get_instance_id(), parent.get_child_count(), _towers_epoch]
	if key != _tower_key:
		_tower_key = key
		_tower_buckets = {}
		for t in parent.get_children():
			if t is Tower and not t.is_queued_for_deletion():
				var bucket := Vector2i((t.global_position / TOWER_BUCKET).floor())
				if _tower_buckets.has(bucket):
					_tower_buckets[bucket].append(t)
				else:
					_tower_buckets[bucket] = [t]
	var here := Vector2i((global_position / TOWER_BUCKET).floor())
	var out := []
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			for t in _tower_buckets.get(here + Vector2i(dx, dy), []):
				if t != self and is_instance_valid(t) and not t.is_queued_for_deletion():
					out.append(t)
	return out

func _other_towers() -> Array:
	if get_parent() == null:
		return []
	return get_parent().get_children().filter(func(t: Node) -> bool:
		return t is Tower and t != self and not t.is_queued_for_deletion())

# How far this Warden's aura reaches, in cells (aura_radius, or its attack range; Kind Canopy +1 for the
# Acorn line's auras).
func get_aura_reach() -> float:
	var reach := tower_data.aura_radius if tower_data.aura_radius > 0.0 else tower_data.attack_range
	if _rule_stacks(&"kind_canopy") > 0 and KIND_CANOPY_WARDENS.has(tower_data.get_id()):
		reach += KIND_CANOPY_REACH
	if is_aura_support():
		reach += FOCUS_WIDE * choice_count(Focus.WIDE)  # Wide ranks
	return reach

# Grove Heart: +aura_per_warden for each Warden in its radius, keeping the total under aura_max.
# Grandfather Stump (card): the Elder Stump gets +4% per Warden around it too, up to +45% in all.
func get_aura_extra() -> float:
	var base := maxf(tower_data.aura_damage_bonus, tower_data.aura_speed_bonus)
	var extra := 0.0
	if tower_data.aura_per_warden > 0.0:
		extra = clampf(tower_data.aura_per_warden * _aura_count, 0.0, maxf(tower_data.aura_max - base, 0.0))
	if tower_data.get_id() == "elder_stump" and _rule_stacks(&"grandfather_stump") > 0:
		extra = maxf(extra, clampf(GRANDFATHER_PER_WARDEN * _aura_count, 0.0, maxf(GRANDFATHER_MAX - base, 0.0)))
	return extra

# The damage (`speed` false) or attack-speed bonus this aura Warden gives right now, cards included:
# Acorn Cache (the Acorn's +5% is +8%), Shared Light (+50%), The Quiet Ones (non-attackers +50%).
func get_aura_bonus(speed: bool) -> float:
	var base := tower_data.aura_speed_bonus if speed else tower_data.aura_damage_bonus
	if base <= 0.0:
		return 0.0
	if not speed and tower_data.get_id() == "acorn" and _rule_stacks(&"acorn_cache") > 0:
		base = 0.05 + (ACORN_CACHE_AURA - 0.05) * _rule_power(&"acorn_cache")  # Tag resonance scales the card's part
	if is_aura_support():
		var ranks := get_effective_rank()
		base *= pow(AURA_PER_RANK, ranks)  # Grove Heart: its base only, not the per-Warden extra
		base *= 1.0 + FOCUS_STRONG_AURA * choice_count(Focus.STRONG)  # Strong ranks
	var bonus := base + get_aura_extra()
	if _rule_stacks(&"shared_light") > 0:
		bonus *= 1.0 + SHARED_LIGHT * _rule_power(&"shared_light")
	return bonus * get_quiet_multiplier()

# Bramble Oath (Seed card): Bramble and Honeysuckle 50% stronger (Bramble's damage, Honeysuckle's
# scent rate); The Quiet Ones for Honeysuckle. Scented Hedge's Thornwalls carry it at half strength.
func get_wall_multiplier() -> float:
	var multiplier := get_quiet_multiplier()
	if BRAMBLE_OATH_WARDENS.has(tower_data.get_id()) and _rule_stacks(&"bramble_oath") > 0:
		multiplier *= 1.0 + BRAMBLE_OATH
	if tower_data.get_id() == "bramble" and _rule_stacks(&"thornheart") > 0:
		var brambles := get_parent().get_children().filter(func(t) -> bool: return t is Tower and t.tower_data.get_id() == "bramble").size() if get_parent() else 1
		multiplier *= 1.0 + minf(DreamState.THORNHEART_PER * brambles, DreamState.THORNHEART_MAX) * _rule_power(&"thornheart")  # Thornheart
	return multiplier

# The Quiet Ones (card): Wardens that don't attack (walls, Grandmother Oak, the White Stag, Honeysuckle)
# are 50% stronger.
func get_quiet_multiplier() -> float:
	return 1.0 + QUIET_ONES if is_quiet() and _rule_stacks(&"the_quiet_ones") > 0 else 1.0

func is_quiet() -> bool:
	return not tower_data.can_attack or tower_data.damage <= 0

# Hedgerow Roots (card): the Thornwalls touching this Warden, which auras reach past.
func _hedge_walls() -> Array:
	if _rule_stacks(&"hedgerow_roots") <= 0:
		return []
	return _other_towers().filter(func(t: Tower) -> bool:
		return t.tower_data.get_id() == "thornwall" and absf(t.cell.x - cell.x) <= 1 and absf(t.cell.y - cell.y) <= 1)

# Whether this aura reaches one of `walls` (so it hops that Thornwall to the Warden behind it).
func reaches_past(walls: Array) -> bool:
	for wall in walls:
		if wall.global_position.distance_to(global_position) / MAP_GRID.cell_size.x <= get_aura_reach():
			return true
	return false

# Performance (platforms.md budget at 1x): at most MAX_REFRESHES_PER_FRAME neighbour looks run in one
# frame (a nudge after planting sets many due at once); the rest wait a frame or two.
const MAX_REFRESHES_PER_FRAME := 2
static var _refresh_frame := -1
static var _refreshes := 0

static func _refresh_slot() -> bool:
	var frame := Engine.get_process_frames()
	if frame != _refresh_frame:
		_refresh_frame = frame
		_refreshes = 0
	if _refreshes >= MAX_REFRESHES_PER_FRAME:
		return false
	_refreshes += 1
	return true

# Same-kind auras stack with falloff (warden_stats.md fdd7003): per kind, strongest first, they count
# 100% / 50% / 25% …; a Kindred-Focus aura always counts 100% and sits outside the falloff. Different kinds add
# fully. _aura_sources keeps each Warden's share (AuraView, the panel's "Elder Stump ×3" lines); the
# _from fields name the biggest giver (SupportLog credit).
var _aura_sources: Array = []  # [{"tower", "kind", "damage", "speed", "position", "kindred", "relayed"}, …]
var _touch_lines := {}  # Lines of the Wardens on the 8 cells around (Mycelium, Fireflies in the Grass)
var _aura_support := false  # is_aura_support(), set with the form
var _big_family := false  # Big Family: a Sprout within BIG_FAMILY_CELLS of a Kinship pair

func _near_kin_pair() -> bool:
	var kin := Kinships.find(self)
	if kin == null:
		return false
	for pair in kin.pairs:
		for member in [pair.a, pair.b]:
			if is_instance_valid(member) and member.global_position.distance_to(global_position) / MAP_GRID.cell_size.x <= DreamState.BIG_FAMILY_CELLS + 0.001:
				return true
	return false

func _stack_auras(auras: Dictionary) -> void:
	_aura_sources = []
	var top_damage := 0.0
	var top_speed := 0.0
	for kind in auras:
		var list: Array = auras[kind]
		list.sort_custom(func(a: Array, b: Array) -> bool: return maxf(a[1], a[2]) > maxf(b[1], b[2]))
		var weight := 1.0
		var position := 0  # Place in this kind's falloff (1st, 2nd…; 0 = Kindred, outside it)
		for entry in list:
			var giver: Tower = entry[0]
			var share := weight
			var kindred := giver.is_aura_support() and giver.choice_count(Focus.KINDRED) > 0
			if kindred:
				share = 1.0  # Kindred: outside the falloff
			else:
				weight *= AURA_FALLOFF
				position += 1
			var damage: float = entry[1] * share
			var speed: float = entry[2] * share
			_aura_damage += damage
			_aura_speed += speed
			_aura_sources.append({"tower": giver, "kind": kind, "damage": damage, "speed": speed,
				"position": 0 if kindred else position, "kindred": kindred, "relayed": entry[3]})
			if damage > top_damage:
				top_damage = damage
				_aura_damage_from = giver
			if speed > top_speed:
				top_speed = speed
				_aura_speed_from = giver

# The Warden panel's aura lines: "Elder Stump ×3: +35% attack speed", one per kind touching this Warden.
func get_aura_lines() -> Array[String]:
	var kinds := {}
	for source in _aura_sources:
		if not is_instance_valid(source.tower):
			continue
		var row: Array = kinds.get(source.kind, [source.tower.tower_data.display_name, 0, 0.0, 0.0])
		row[1] += 1
		row[2] += source.damage
		row[3] += source.speed
		kinds[source.kind] = row
	var lines: Array[String] = []
	for kind in kinds:
		var row: Array = kinds[kind]
		var parts: Array[String] = []
		if row[2] > 0.0:
			parts.append("+%d%% damage" % roundi(row[2] * 100.0))
		if row[3] > 0.0:
			parts.append("+%d%% attack speed" % roundi(row[3] * 100.0))
		if parts.is_empty():
			continue
		var name: String = row[0] if kind != "old_growth" else "Old Growth"
		lines.append("%s%s: %s" % [name, " ×%d" % row[1] if row[1] > 1 else "", ", ".join(parts)])
	return lines

# Refreshes what depends on nearby Wardens: the copied attack (Graftling) and aura bonuses.
func _refresh_neighbours() -> void:
	_neighbour_timer = NEIGHBOUR_REFRESH * randf_range(0.75, 1.25)  # Staggered: ~200 Wardens never all look at once
	if _is_underdog() != _underdog_drawn:
		queue_redraw()  # DreamState picks the Underdogs at each rest
	_aura_crit = 0.0
	_aura_range = 0.0
	_aura_damage = 0.0
	_aura_speed = 0.0
	var aura_count := 0
	_aura_damage_from = null
	_aura_speed_from = null
	var hedge_walls := _hedge_walls()  # Hedgerow Roots: auras reach past a Thornwall next to this Warden
	var auras := {}  # Aura kind -> [[Warden, damage bonus, speed bonus], …]
	var harmony := {}
	var best: Tower = null
	var best_dps := 0.0
	var second: Tower = null
	var second_dps := 0.0
	var voices := 0
	_touch_lines = {}
	var my_aura := tower_data.aura_damage_bonus > 0.0 or tower_data.aura_speed_bonus > 0.0
	var my_reach := get_aura_reach() if my_aura else 0.0
	for other in _towers_near():
		var distance: float = other.global_position.distance_to(global_position) / MAP_GRID.cell_size.x
		if distance > NEIGHBOUR_REACH:
			continue  # Performance: the bucket window is ~15 cells wide; nothing reaches this far
		var data: TowerData = other.tower_data
		var touching := absf(other.cell.x - cell.x) <= 1 and absf(other.cell.y - cell.y) <= 1
		if touching:
			_touch_lines[data.line] = true  # Mycelium, Fireflies in the Grass
		if data.aura_crit_bonus > 0.0 and distance <= data.attack_range:
			_aura_crit = maxf(_aura_crit, data.aura_crit_bonus)  # Auras don't stack with themselves
		if (data.aura_damage_bonus > 0.0 or data.aura_speed_bonus > 0.0) \
				and (distance <= other.get_aura_reach() or other.reaches_past(hedge_walls)):
			# Acorn, Elder Stump, Grove Heart, Grandmother Oak: gathered per kind, stacked with falloff below.
			var kind: String = data.get_id()
			if not auras.has(kind):
				auras[kind] = []
			auras[kind].append([other, other.get_aura_bonus(false), other.get_aura_bonus(true), distance > other.get_aura_reach()])
		if my_aura and distance <= my_reach:
			aura_count += 1
		var growth: float = other.kin_share(&"old_growth", "b") if distance <= 1.5 else 0.0
		if growth > 0.0:  # Old Growth: the Dewcatcher kin's small aura (its own kind)
			if not auras.has("old_growth"):
				auras["old_growth"] = []
			auras["old_growth"].append([other, 0.0, 0.1 * growth, false])
		if data.range_aura_bonus > 0.0 and distance <= data.range_aura_radius:
			_aura_range = maxf(_aura_range, data.range_aura_bonus)
		if tower_data.attack_kind == TowerData.AttackKind.COPY and data.applies_status != &"" \
				and absf(other.cell.x - cell.x) <= 1 and absf(other.cell.y - cell.y) <= 1:
			harmony[data.applies_status] = maxi(harmony.get(data.applies_status, 0), data.status_stacks)
		if tower_data.attack_kind == TowerData.AttackKind.COPY and _can_copy(other) \
				and absf(other.cell.x - cell.x) <= 1 and absf(other.cell.y - cell.y) <= 1:
			var dps: float = other.get_damage() * other.get_attacks_per_second()
			if dps > best_dps:
				second = best  # Double graft: the runner-up too
				second_dps = best_dps
				best_dps = dps
				best = other
			elif dps > second_dps:
				second = other
				second_dps = dps
		if _twist == &"chorus" and data.line == "song" and distance <= FinalTwists.CHORUS_REACH:
			voices += 1  # Chorus: each other Bellflower-family Warden within 3 cells
	_chorus = FinalTwists.chorus_bonus(self, voices)
	if _twist == &"double_graft":
		_twist_state[&"graft_pair"] = [best.tower_data, second.tower_data] if best != null and second != null else []
	_stack_auras(auras)
	if tower_data.get_id() == "sprout" and _rule_stacks(&"warm_hearth") > 0:
		var hearth := 1.0 + DreamState.WARM_HEARTH_SPROUTS * _rule_power(&"warm_hearth")  # Warm Hearth: auras on Sprouts
		_aura_damage *= hearth
		_aura_speed *= hearth
		for source in _aura_sources:
			source.damage *= hearth
			source.speed *= hearth
	_big_family = tower_data.get_id() == "sprout" and _rule_stacks(&"big_family") > 0 and _near_kin_pair()
	_aura_count = aura_count
	_graft_status = _strongest_neighbour_status() if kin_share(&"true_graft", "b") > 0.0 else []
	_update_support_looks()
	_set_harmony(harmony if harmony.size() >= 2 else {})
	if badges_visible() or _dream_cache.is_empty():
		_refresh_badge()  # Only while badges show (build mode, a selection); else the cache refresh does it
	_refresh_root_links()
	if tower_data.attack_kind != TowerData.AttackKind.COPY:
		return
	var copied: TowerData = best.tower_data if best != null else tower_data
	if copied != attack_data:
		_stop_beam()
		attack_data = copied
	_damage_share = lerpf(tower_data.copy_share, 1.0, kin_share(&"true_graft", "a")) if best != null else 1.0  # True Graft: 100%

# Graftlings copy attacking, non-unique Wardens, and never other Graftlings.
static func _can_copy(other: Tower) -> bool:
	var data := other.tower_data
	return data.can_attack and not data.is_unique and data.attack_kind != TowerData.AttackKind.COPY \
		and data.attack_kind != TowerData.AttackKind.AURA

# The Warden this Graftling is copying right now (null = none). For the Warden panel.
func get_copied() -> TowerData:
	return attack_data if tower_data.attack_kind == TowerData.AttackKind.COPY and attack_data != tower_data else null


# --- Attacking ----------------------------------------------------------------------------------------

# Winds up the attack animation; the shot / pulse happens on its release frame.
func _start_attack() -> void:
	if _twist == &"double_graft":
		FinalTwists.next_graft(self)  # Double graft: alternates between its two borrowed attacks
	# Performance: a little jitter (the same rate on average) so Wardens planted together drift out of
	# step instead of all releasing on the same frame (test_perf_stress: 25-48 ms spikes every ~0.4 s).
	_cooldown = randf_range(1.0 - COOLDOWN_JITTER, 1.0 + COOLDOWN_JITTER) / get_attacks_per_second()
	if tower_data.attack_texture == null:
		_release()
		return
	# Play the attack faster if it wouldn't finish before the next one is due.
	_attack_fps = maxf(tower_data.attack_animation_fps, tower_data.attack_frame_count * get_attacks_per_second())
	_pull_only = false
	_attack_time = 0.0
	_released = false
	sprite.texture = tower_data.attack_texture
	sprite.hframes = tower_data.attack_frame_count
	sprite.frame = 0

func _advance_attack(delta: float) -> void:
	_attack_time += delta
	var frame := int(_attack_time * _attack_fps)
	if not _released and frame >= tower_data.attack_release_frame:
		_released = true
		_flush_pull()
		if not _pull_only:
			_release()
	if frame >= tower_data.attack_frame_count:
		_attack_time = -1.0
		_pull_only = false
		_show_idle()
		return
	sprite.frame = frame

func _show_idle() -> void:
	sprite.texture = tower_data.texture
	sprite.hframes = tower_data.frame_count
	sprite.frame = int(_anim_time * tower_data.animation_fps) % tower_data.frame_count

# Holds the attack pose (the release frame) while beaming.
func _show_attack_pose() -> void:
	if tower_data.attack_texture == null or _legacy_active:
		return
	sprite.texture = tower_data.attack_texture
	sprite.hframes = tower_data.attack_frame_count
	sprite.frame = tower_data.attack_release_frame

# The attack lands. A target that left range during the wind-up wastes a projectile/chain/cloud.
func _release() -> void:
	_attack_count += 1
	_aim_idle = _anim_time - _last_release  # Patient Aim: how long it waited
	_last_release = _anim_time
	attack_released.emit(self)
	var boost := _take_empowered()
	if _chorus_sync:
		boost *= 1.0 + DreamState.CHORUS_BONUS  # Chorus: pulled into a Bellflower's pulse
	elif _chorus_pulse():
		boost *= 1.0 + DreamState.CHORUS_BONUS
	if boost == 1.0:
		_release_attack()
	else:
		_boosted(boost, _release_attack)
	# Flurry (Grove card): every 5th attack fires twice; the extra shot never counts toward it.
	if _dream_state and _has_rule(&"flurry") and _attack_count % DreamState.FLURRY_EVERY == 0:
		_release_attack()

# Card hit multipliers (dream_design.md): Patient Aim (+15% per second it didn't fire, max +60%), Crush (area
# hits on a crowded nightmare), Crowd Breaker (area attacks +5% per nightmare hit, max +45%), Shiny Things
# (the Magpie's stolen buffs). Tag resonance on each.
const HIT_CARD_RULES: Array[StringName] = [&"patient_aim", &"crush", &"crowd_breaker", &"shiny_things"]
const CATALOGUE_HIT_RULES: Array[StringName] = [&"mycelium", &"fireflies_in_the_grass", &"resonance"]

# True if any of `rules` is owned; cached with the shared rule cache under `key`.
func _any_rule(key: StringName, rules: Array[StringName]) -> bool:
	if _dream_state == null:
		return false
	_rule_entry(rules[0])  # Refreshes the shared cache if the run's rules changed
	if not _rules.has(key):
		var any := false
		for rule in rules:
			if _rule_stacks(rule) > 0:
				any = true
				break
		_rules[key] = [1 if any else 0, 0]
	return _rules[key][0] > 0

var _aim_idle := 0.0
var _last_release := 0.0
var _area_count := 0  # Nightmares the current area attack hits (Crowd Breaker)
var _shiny: Array[float] = []  # Shiny Things: _anim_time each stolen buff runs out

func _card_hit_multiplier(enemy: Node2D, is_area: bool) -> float:
	if _dream_state == null or (_shiny.is_empty() and not _any_rule(&"__hit_cards", HIT_CARD_RULES)):
		return 1.0  # Performance: most runs own none of these (one cached check per hit)
	var multiplier := 1.0
	if _rule_stacks(&"patient_aim") > 0:
		multiplier *= 1.0 + minf(DreamState.PATIENT_AIM_PER * _aim_idle, DreamState.PATIENT_AIM_MAX) * _rule_power(&"patient_aim")  # Slow snipers gain most
	if is_area and _rule_stacks(&"crush") > 0:
		var crowd := 0
		for other in get_tree().get_nodes_in_group(ENEMY_GROUP):
			if other != enemy and other.global_position.distance_to(enemy.global_position) <= MAP_GRID.cell_size.x * 1.0:
				crowd += 1
		if crowd >= DreamState.CRUSH_CROWD:
			multiplier *= 1.0 + DreamState.CRUSH_BONUS[_rule_level(&"crush")] * _rule_power(&"crush")
	if is_area and _rule_stacks(&"crowd_breaker") > 0 and _area_count > 1:
		multiplier *= 1.0 + minf(DreamState.CROWD_BREAKER_PER * _area_count, DreamState.CROWD_BREAKER_MAX) * _rule_power(&"crowd_breaker")
	if not _shiny.is_empty():
		_shiny = _shiny.filter(func(until: float) -> bool: return until > _anim_time)
		multiplier *= 1.0 + DreamState.SHINY_THINGS_BONUS * _shiny.size() * _rule_power(&"shiny_things")
	return multiplier

func _shiny_stole() -> void:
	if _rule_stacks(&"shiny_things") <= 0:
		return
	_shiny.append(_anim_time + DreamState.SHINY_THINGS_TIME)
	if _shiny.size() > DreamState.SHINY_THINGS_STACKS:
		_shiny.pop_front()

# Chorus (Dream): a Bellflower-line pulse pulls in the others of its line within CHORUS_CELLS whose attack
# is ready within CHORUS_SYNC_WINDOW; they fire with it and every synced pulse deals +30%. A soft ring links
# them. True if any joined.
var _chorus_sync := false

func _chorus_pulse() -> bool:
	if tower_data.line != "song" or attack_data.attack_kind != TowerData.AttackKind.PULSE or _dream_state == null \
			or not _dream_state.has_method("has_chorus") or not _dream_state.has_chorus():
		return false
	var joined := false
	for other in _towers_near():
		if other.tower_data.line != "song" or other.attack_data.attack_kind != TowerData.AttackKind.PULSE \
				or other._attack_time >= 0.0 or other._cooldown > DreamState.CHORUS_SYNC_WINDOW \
				or other.global_position.distance_to(global_position) / MAP_GRID.cell_size.x > DreamState.CHORUS_CELLS:
			continue
		other._chorus_sync = true
		other._cooldown = 1.0 / maxf(other.get_attacks_per_second(), 0.01)
		other._release()
		other._chorus_sync = false
		add_child(ChainBolt.new(PackedVector2Array([global_position, other.global_position]), CHORUS_RING_COLOR, 0.0))
		joined = true
	return joined

const CHORUS_RING_COLOR := Color(Palette.BLOSSOM, 0.45)

# Sudden Bloom / Watchful Rest: this attack's multiplier (×2 each), using up what it spends.
func _take_empowered() -> float:
	var boost := 1.0
	if bloom_left > 0.0:
		boost *= EMPOWERED_MULTIPLIER  # Sudden Bloom: every attack while it lasts
	if watch_charged:
		watch_charged = false
		_watch_time = 0.0
		boost *= EMPOWERED_MULTIPLIER
	if boost != 1.0:
		queue_redraw()  # The glow fades once the charge is spent
	return boost

# Runs `action` with every hit it lands at ×`boost` (projectiles carry it to where they land).
func _boosted(boost: float, action: Callable) -> void:
	run_as(attack_data, boost, action)

# Runs `action` as this Warden attacking with `data` (null = its own) at ×`boost`. Delayed attack nodes
# (projectiles, clouds, rings, birds, seeds) keep what they were made with and land through this, so an
# Ascended form's legacy attack and a Sudden Bloom / Watchful Rest boost reach them.
func run_as(data: TowerData, boost: float, action: Callable) -> void:
	var own_data := attack_data
	var own_boost := _hit_boost
	if data != null:
		attack_data = data
	_hit_boost = boost
	action.call()
	attack_data = own_data
	_hit_boost = own_boost

# Legacy (run_design.md "Act 3 probe"): an Ascended form keeps the final form it grew from and still
# makes that attack on the final's own cadence (and ranks, Dreams), besides its own. A Graftling
# final's copy has nothing to copy on its own, so Grandmother Oak keeps none.
func _update_legacy(delta: float) -> void:
	if legacy_data == null or not legacy_data.can_attack or legacy_data.attack_kind == TowerData.AttackKind.COPY:
		return
	var own := attack_data
	attack_data = legacy_data
	_legacy_active = true
	if legacy_data.attack_kind == TowerData.AttackKind.BEAM:
		_update_beam(delta)  # Stormheart keeps Midsummer's beam (its own attack is a chain)
	else:
		_legacy_cooldown = maxf(_legacy_cooldown - delta, 0.0)
		if _legacy_cooldown <= 0.0 and _has_work():
			_legacy_cooldown = 1.0 / get_attacks_per_second()
			_release_attack()
			legacy_released.emit(self)
	_legacy_active = false
	attack_data = own

# Watchful Rest (card, rule watchful_rest): nothing in range for WATCHFUL_REST_TIME seconds (II: less)
# stores one charge.
func _update_watch(delta: float) -> void:
	if bloom_left > 0.0:
		bloom_left = maxf(bloom_left - delta, 0.0)
		if bloom_left == 0.0:
			queue_redraw()  # The Sudden Bloom glow fades
	if watch_charged or _rule_stacks(&"watchful_rest") <= 0:
		return
	_watch_check -= delta
	_watch_time += delta
	if _watch_check > 0.0:
		return
	_watch_check = WATCH_CHECK
	if has_enemy_in_range():
		_watch_time = 0.0
	elif _watch_time >= DreamState.WATCHFUL_REST_TIME[mini(_rule_level(&"watchful_rest"), 1)]:
		watch_charged = true
		queue_redraw()

func _release_attack() -> void:
	match attack_data.attack_kind:
		TowerData.AttackKind.PULSE:
			var in_range := get_enemies_in_range()
			_area_count = in_range.size()
			var statics := 0
			if attack_data.rain:
				var world := Reactions._world(self)
				if world:
					Fx.rain_sweep(global_position, get_range_pixels(), world)  # Monsoon's sheet of rain
			if attack_data.tier >= 4:
				ascended_event.emit(self, global_position, in_range.size())
			for enemy in in_range:
				if attack_data.hit_effect_texture != null:  # Tidecaller's wave, World Root's grasp
					play_sheet(attack_data.hit_effect_texture, attack_data.hit_effect_frames,
						attack_data.hit_effect_anchor, enemy.global_position,
						enemy.global_position.x < global_position.x)
				hit(enemy, 1.0, true)
				_push(enemy)
				if _set_off_static(enemy):
					statics += 1
			_resonant_echo(in_range)
			if _dream_state and _any_rule(&"grove_area", GROVE_AREA_RULES):
				GroveRules.area_attack(self, global_position, get_range_pixels(), 1.0)  # A pulse is an area attack
			if statics > 0 and attack_data.tier >= 4:
				statics_set_off.emit(self, global_position, statics)  # The Great Bell's toll
			if attack_data.pulse_hold_every > 0 and _attack_count % attack_data.pulse_hold_every == 0:
				_pulse_hold(in_range)
			_kin_chime_catch(in_range)
		TowerData.AttackKind.CHAIN:
			var target := find_target()
			if target != null:
				_chain_strike(target)
		TowerData.AttackKind.CLOUD:
			var target := find_target()
			if target != null:
				_drop_cloud(target)
		TowerData.AttackKind.TRAP:
			_plant_ring()
		TowerData.AttackKind.PECK:
			_send_hummingbirds()
		TowerData.AttackKind.BOOMERANG:
			_throw_seeds()
		TowerData.AttackKind.SPREAD:
			_spread()
		TowerData.AttackKind.SPIN:
			_spin()
		TowerData.AttackKind.PULL:
			var target := find_target()
			if target != null:
				_grab(target)
		TowerData.AttackKind.LIGHT:
			_light()
		TowerData.AttackKind.AURA:
			pass  # The White Stag's pulse is only its animation; the aura works in _update_aura
		_:
			# Starling Murmuration swoops at several different nightmares at once.
			for target in find_targets(attack_data.multi_targets):
				fire_at(target)
				if _twin_puff():
					fire_at(target)  # Twin Puff: this Sporeling attack fires twice

# Soothes `enemy` and applies this Warden's status. `is_area`: splash, pulse and cloud hits (creatures
# with an attack-shape resistance, like the Bee Swarm, take these differently). `crit`: ROLL_CRIT,
# NO_CRIT or CRIT. The creature's family resistance or weakness to this Warden's line is applied in
# Enemy.take_damage. `combo`: a DamageLog combo tag this hit owes itself to (&"conducted").
# Returns whether it was a crit.
func hit(enemy: Node2D, soothe_multiplier: float = 1.0, is_area: bool = false, crit: int = ROLL_CRIT,
		combo: StringName = &"") -> bool:
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return false
	var is_crit := roll_crit(enemy) if crit == ROLL_CRIT else crit == CRIT
	if _has_rule(&"called_shot") and _dream_state.called_shot(self, enemy):
		is_crit = true  # Called Shot: the first hit on a Marked nightmare (once per Warden per nightmare)
	if attack_data.dew_mark:
		enemy.bonus_dew = maxi(enemy.bonus_dew, 1)  # Before the hit, so a dispelling hit counts
	if attack_data.strips_buffs and enemy.has_method("strip_buff"):
		if enemy.strip_buff(self):  # Magpie, the thief: shell chip x2, a Weeper's mending stopped, Omen boosts gone (Enemy's side)
			_shiny_stole()
	var soothe := get_damage() * soothe_multiplier * _damage_against(enemy) * _hit_boost
	soothe *= _card_hit_multiplier(enemy, is_area)  # Patient Aim, Crush, Crowd Breaker, Shiny Things
	if kin_share(&"sunspot", "b") > 0.0:  # Sunspot: hits in a row on one nightmare ramp up
		_ramp_hits = _ramp_hits + 1 if enemy == _ramp_target else 0
		_ramp_target = enemy
	if _dream_state and _dream_state.has_method("get_hit_damage_multiplier"):
		soothe *= _dream_state.get_hit_damage_multiplier()  # Venom Bloom: hits weaker, effects stronger
	if _dream_state and _dream_state.has_method("on_hit_multiplier"):
		# First Light, Last Stand, Hunter's Patience, Bitter Hedges (tracked inside: once per hit).
		soothe *= _dream_state.on_hit_multiplier(self, enemy)
	# Reactions that change a hit: Pinned (a guaranteed ×3 crit) and Shatter (×2.5, shards).
	var reaction := Reactions.before_hit(enemy, self, is_crit)
	is_crit = reaction.crit
	var crit_multiplier: float = reaction.crit_multiplier
	var hammer := kin_share(&"hammer_and_anvil", "a")
	if hammer > 0.0:
		crit_multiplier = maxf(crit_multiplier, 2.0 + 0.5 * hammer)  # Hammer and Anvil: the sniper's eye
	if _kin_roll(kin_share(&"flock_together", "a")):
		# Flock Together A (status jobs): the wren strips a buff like a magpie, and the robbed nightmare
		# drops +1 Dew when dispelled.
		if enemy.has_method("strip_buff"):
			enemy.strip_buff(self)
		enemy.bonus_dew = maxi(enemy.bonus_dew, 1)
		_kin_fired(&"flock_together")
	if is_crit and _dream_state and _dream_state.has_method("get_crit_overflow_multiplier"):
		crit_multiplier += _dream_state.get_crit_overflow_multiplier(get_raw_crit_chance(enemy))  # Full Moon
	var non_crit := 1.0
	if not is_crit and _dream_state and _dream_state.has_method("get_non_crit_multiplier"):
		non_crit = _dream_state.get_non_crit_multiplier()  # Reckless Bloom
	var dealt: float = soothe * (crit_multiplier if is_crit else non_crit) * reaction.multiplier
	if reaction.tag != &"":
		combo = reaction.tag
	var damage_line := "light" if _resonance() else tower_data.line  # Resonance: Chime Stone pulses count as lightning
	var health_before: int = enemy.health
	enemy.take_damage(dealt, damage_line, is_area, is_crit, self, combo)
	if _dream_state and not is_area and _has_rule(&"momentum"):
		GroveRules.note_hit(self, enemy)  # Momentum: a streak on one nightmare
	if _dream_state and is_area and combo != &"spillover" and enemy.is_cleansed and _has_rule(&"spillover"):
		GroveRules.spillover(self, enemy, dealt - health_before)  # Spillover: the leftover splashes on
	if reaction.shatter:
		Reactions.shatter_splash(enemy, self, dealt)
	if is_crit:
		_shattering_blow(enemy, dealt)
	if _dream_state and _has_rule(&"thousand_cuts") and is_instance_valid(enemy):
		enemy.statuses.add_cut()  # Every hit within 2 s: +2% damage taken from everyone (max +60%)
	hit_landed.emit(self, enemy, is_area, is_crit)
	apply_status_to(enemy, soothe)
	_after_hit(enemy, is_crit)
	_catalogue_hit(enemy)
	_legendary_hit_rules(enemy, soothe)
	if is_instance_valid(_kin):
		_kin_night_chimes(enemy)
		_kin.note_hit(self, enemy, dealt)  # Harmony strike when its kin hit this nightmare within 1 s
	if is_crit:
		crit_landed.emit(self, enemy)
	return is_crit

# --- Kinships (tower_design.md): a trait borrowed from a kin of another branch of the family ---

# The share (0.5 Sapling / 0.75 Blooming / 1.0 Old Kin) of Kinship `id`'s trait this Warden borrows on
# `side` ("a" = the table's first branch), or 0.
func kin_share(id: StringName, side: String) -> float:
	return _kin.share(self, id, side) if is_instance_valid(_kin) else 0.0

# Borrowed looks (2026-09-29): the colour this Warden's attacks carry while bonded (transparent if not).
func kin_look() -> Color:
	return _kin.look_for(self) if is_instance_valid(_kin) else Color(0, 0, 0, 0)

func _kin_partner() -> Tower:
	return _kin.get_partner(self) if is_instance_valid(_kin) else null

# A per-hit trait at 50% goes off half the time.
static func _kin_roll(share: float) -> bool:
	return share > 0.0 and randf() < share

# Called by this Warden's clouds (PathCloud) for each nightmare inside; `entered` on its first tick
# there. Slumber Rot (Bloomcap line): +1 Spored per tick. Rainfog (Mistveil line): the fog deals the
# Rain Lily kin's splash damage to nightmares entering it.
func kin_cloud_tick(enemy: Node2D, entered: bool) -> void:
	if _kin_roll(kin_share(&"slumber_rot", "b")):
		enemy.apply_status(EnemyStatuses.SPORED, 1, 0.0, get_damage() * SPORE_POTENCY, 0, tower_data.line, self)
		_kin_fired(&"slumber_rot")
	var fog := kin_share(&"rainfog", "b")
	if entered and fog > 0.0 and is_instance_valid(enemy) and not enemy.is_cleansed:
		var partner := _kin_partner()
		if partner:
			enemy.take_damage(partner.get_damage() * fog, partner.tower_data.line, true, false, partner, &"fog")
			_kin_fired(&"rainfog")

# Night Chimes A (Chime Stone line; status jobs, 2026-09-29): its pulses Catch full-Drowsy nightmares as if
# a Dreamcatcher were there (statuses stop wearing off), until the next pulse. No damage bonus any more.
func _kin_chime_catch(in_range: Array) -> void:
	var share := kin_share(&"night_chimes", "a")
	if share <= 0.0:
		return
	var hold := 1.1 / maxf(get_attacks_per_second(), 0.1)  # Until just after the next pulse
	for enemy in in_range:
		if not is_instance_valid(enemy) or enemy.is_cleansed or not _kin_roll(share):
			continue
		var s: EnemyStatuses = enemy.statuses
		if not s.is_catchable():
			continue
		if not s.is_caught():
			Reactions._effect(&"caught", enemy.global_position, self, 1.0, 0.8)
		s.caught_time = maxf(s.caught_time, hold)

# Night Chimes (Dreamcatcher line): its hits set off Static at 3 charges, like a chime.
func _kin_night_chimes(enemy: Node2D) -> void:
	if not is_instance_valid(enemy) or enemy.is_cleansed or not _kin_roll(kin_share(&"night_chimes", "b")):
		return
	var s: EnemyStatuses = enemy.statuses
	if s.stacks(EnemyStatuses.STATIC) < 3:
		return
	var bolt := s.potency(EnemyStatuses.STATIC) * EnemyStatuses.STATIC_BOLT_MULTIPLIER
	var source := s.source(EnemyStatuses.STATIC)
	s.remove(EnemyStatuses.STATIC)
	Reactions.strike_bolt(enemy, bolt, source if source else self, &"static")

# Hit rules of the new Legendaries (dream_design.md "New Legendaries"), read by rule id:
# Hunter's Moon (a Warden's first hit on a nightmare Exposes it, and that never runs out), Eternal
# Static (every 4th hit adds a Charge, and Charge never decays), Rooted Nightmares (every 8th hit Roots
# it for 1 s, bosses 0.5 s).
func _legendary_hit_rules(enemy: Node2D, soothe: float) -> void:
	if _dream_state == null or not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	_hits_landed += 1
	var s: EnemyStatuses = enemy.statuses
	if _has_rule(&"hunters_moon"):
		s.marked_forever = true
		var id := enemy.get_instance_id()
		if not _hunted.has(id):
			_hunted[id] = true
			if _hunted.size() > 512:
				_hunted.clear()  # Forget long-gone nightmares now and then
			_apply_one_status(enemy, EnemyStatuses.MARKED, 1, soothe)
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	if _has_rule(&"eternal_static"):
		s.static_forever = true
		if _hits_landed % ETERNAL_STATIC_EVERY == 0:
			enemy.apply_status(EnemyStatuses.STATIC, 1, 0.0, soothe, 0, "light", self)
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	if _has_rule(&"rooted_nightmares") and _hits_landed % ROOTED_NIGHTMARES_EVERY == 0:
		var time := ROOTED_BOSS_TIME if s.is_boss else ROOTED_TIME
		hold(enemy, time)

# Twin Puff: every 3rd Sporeling attack (II: every 2nd) fires twice.
func _twin_puff() -> bool:
	if tower_data.get_id() != "sporeling" or _dream_state == null or not _has_rule(&"twin_puff"):
		return false
	var every := 2 if _rule_level(&"twin_puff") > 0 else 3
	return _attack_count % every == 0

# Shattering Blow: a crit splashes 50% of its damage within 1 cell (II: 75% within 1.5). The splash
# is area damage and never crits itself.
func _shattering_blow(enemy: Node2D, dealt: float) -> void:
	if _dream_state == null or not _has_rule(&"shattering_blow"):
		return
	var deep := _rule_level(&"shattering_blow") > 0
	var share := 0.75 if deep else 0.5
	var reach := (1.5 if deep else 1.0) * MAP_GRID.cell_size.x
	var at := enemy.global_position
	for other in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if other != enemy and other.global_position.distance_to(at) <= reach:
			other.take_damage(dealt * share, tower_data.line, true, false, self, &"shattering_blow")

# Rolls for a crit on `enemy` (Moonstone: the first hit on each nightmare always crits).
func roll_crit(enemy: Node2D) -> bool:
	if not is_instance_valid(enemy):
		return false
	var id := enemy.get_instance_id()
	var first := not _hit_before.has(id)
	_hit_before[id] = true
	if attack_data.first_hit_crits and first:
		Reactions._effect(&"moonstone_beam", enemy.global_position, self)  # Signature: a moonbeam from above
		return true
	if attack_data.crits_vs_drowsy and enemy.statuses.has(EnemyStatuses.DROWSY):
		return true  # Boulderback: a guaranteed crit on Drowsy, no roll
	if attack_data.crits_vs_held and enemy.statuses.is_held():
		return true  # Old Mountain: and on Held
	var chance := get_crit_chance(enemy)
	return chance > 0.0 and randf() < chance

# Damage multiplier for this Warden against `enemy`: sniper distance bonus, favoured prey.
func _damage_against(enemy: Node2D) -> float:
	var multiplier := 1.0
	if attack_data.distance_bonus_per_cell > 0.0:
		var cells := global_position.distance_to(enemy.global_position) / MAP_GRID.cell_size.x
		multiplier += clampf((cells - attack_data.distance_bonus_from) * attack_data.distance_bonus_per_cell,
			0.0, attack_data.distance_bonus_max)
	if attack_data.bonus_vs_multiplier != 1.0:
		var kind: String = enemy.enemy_data.resource_path.get_file().get_basename()
		if kind in attack_data.bonus_vs_enemies or (attack_data.bonus_vs_sprinting and enemy.rolling):
			multiplier *= attack_data.bonus_vs_multiplier
	# Mossback / Boulderback cash in Marked: double damage (Codex: Marked Blow).
	if attack_data.marked_multiplier != 1.0 and enemy.statuses.has(EnemyStatuses.MARKED):
		multiplier *= attack_data.marked_multiplier
		ComboFeedback.report(&"marked_blow", self)
	if is_instance_valid(_kin) and _kin.get_pair(self).size() > 0:
		var anvil := kin_share(&"hammer_and_anvil", "b")
		if anvil > 0.0 and enemy.statuses.has(EnemyStatuses.MARKED):
			multiplier *= 1.0 + anvil  # Hammer and Anvil: Mossback's weight, ×2 vs Marked
		var sun := kin_share(&"sunspot", "b")
		if sun > 0.0 and enemy == _ramp_target:
			multiplier *= 1.0 + minf(SUNSPOT_RAMP * _ramp_hits, SUNSPOT_RAMP_MAX) * sun  # Sunspot: the beam's ramp
		var flock := kin_share(&"flock_together", "b")
		if flock > 0.0 and enemy.enemy_data.resource_path.get_file().get_basename() == "dandelion_seed":
			multiplier *= 1.0 + 0.25 * flock  # Flock Together: +25% vs Phantoms
	return multiplier

# On-hit rules: freeze (Frostfern), Dew from crits (Magpie's Hoard).
func _after_hit(enemy: Node2D, is_crit: bool) -> void:
	if attack_data.freeze_duration > 0.0 and enemy.freeze_cooldown <= 0.0 and not enemy.is_cleansed \
			and (attack_data.freeze_needs == &"" or enemy.statuses.stacks(attack_data.freeze_needs) >= attack_data.freeze_needs_stacks):
		enemy.freeze_cooldown = attack_data.freeze_cooldown
		hold(enemy, attack_data.freeze_duration)
		FinalTwists.frozen(self, enemy)  # Shatter chain: a real freeze can chain when it's dispelled
		if attack_data.held_damage_bonus > 0.0:
			enemy.statuses.held_bonus = maxf(enemy.statuses.held_bonus, attack_data.held_damage_bonus)  # World Root
	if is_crit and attack_data.crit_dew > 0:
		_give_crit_dew(enemy.global_position)

# Magpie's Hoard: +Dew per crit, capped per drift.
func _give_crit_dew(where: Vector2) -> void:
	if _dream_state == null:
		return
	var drift: int = _dream_state.drift_director.drifts_started
	if drift != _crit_dew_drift:
		_crit_dew_drift = drift
		_crit_dew_given = 0
	if _crit_dew_given >= attack_data.crit_dew_per_drift:
		return
	_crit_dew_given += 1
	_dream_state.run_state.earn_dew_at(attack_data.crit_dew, where)

func apply_status_to(enemy: Node2D, soothe: float) -> void:
	# Bellflower: its Drowsy only comes with every Nth pulse.
	if attack_data.status_every <= 1 or _attack_count % attack_data.status_every == 0:
		_apply_one_status(enemy, attack_data.applies_status, attack_data.status_stacks, soothe)
	if attack_data.extra_status != &"":
		_apply_one_status(enemy, attack_data.extra_status, attack_data.extra_status_stacks, soothe)  # Lullaby Bell
	if _kin_roll(kin_share(&"slumber_rot", "a")):
		_apply_one_status(enemy, EnemyStatuses.DROWSY, 1, soothe)  # Slumber Rot: puffs add Drowsy
		_kin_fired(&"slumber_rot")
	if _kin_roll(kin_share(&"storm_beacon", "b")):
		_apply_one_status(enemy, EnemyStatuses.STATIC, 1, soothe)  # Storm Beacon: shots add Static
		_kin_fired(&"storm_beacon")
	if attack_data.attack_kind == TowerData.AttackKind.TRAP and _kin_roll(kin_share(&"spore_nursery", "a")):
		_apply_one_status(enemy, attack_data.applies_status, attack_data.status_stacks, soothe)  # Spore Nursery: rings apply double
		_kin_fired(&"spore_nursery")
	if not _graft_status.is_empty() and _kin_roll(kin_share(&"true_graft", "b")):
		_apply_one_status(enemy, _graft_status[0], _graft_status[1], soothe)  # True Graft: the strongest neighbour's status
		_kin_fired(&"true_graft")
	for status in _harmony:  # Grafted Harmony: each neighbour family's status at half strength
		_apply_one_status(enemy, status, maxi(_harmony[status] / 2, 1), soothe * 0.5)
	_put_to_sleep(enemy)

# Grafted Harmony turns on or off (a Graftling touching Wardens of 2+ status families), with a glow
# whose left and right halves are tinted with two of the statuses' colours.
func _set_harmony(harmony: Dictionary) -> void:
	if harmony.keys() == _harmony.keys():
		return
	_harmony = harmony
	for glow in _harmony_glow:
		if is_instance_valid(glow):
			glow.queue_free()
	_harmony_glow.clear()
	if _harmony.is_empty() or not is_inside_tree():
		return
	var ids: Array = _harmony.keys()
	for i in 2:
		var glow := Fx.play([&"grafted_harmony_a", &"grafted_harmony_b"][i], global_position, self, 1.0, false, 1e6)
		if glow != null:
			glow.modulate = EnemyStatuses.COLORS.get(ids[i], Palette.HEARTLIGHT)
			_harmony_glow.append(glow)

# Dreamshroom: a nightmare at full Drowsy falls asleep (once each; bosses never sleep, their cap is 3).
func _put_to_sleep(enemy: Node2D) -> void:
	if attack_data.sleep_at_max_drowsy <= 0.0 or not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	var s: EnemyStatuses = enemy.statuses
	if s.is_boss or s.dreamshroom_slept or not s.has(EnemyStatuses.DROWSY) \
			or s.stacks(EnemyStatuses.DROWSY) < s.get_max_stacks(EnemyStatuses.DROWSY):
		return
	s.dreamshroom_slept = true
	var was_asleep := s.is_asleep()
	s.sleep_time = maxf(s.sleep_time, attack_data.sleep_at_max_drowsy)
	ComboFeedback.report(&"asleep", self)  # Codex: Asleep
	if not was_asleep:
		put_to_sleep.emit(self, enemy)

func _apply_one_status(enemy: Node2D, status: StringName, stacks: int, soothe: float) -> void:
	if status == &"" or not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	var potency := soothe
	if status == EnemyStatuses.SPORED:
		potency = soothe * SPORE_POTENCY
	elif status == EnemyStatuses.DAMP:
		potency = 1.0  # Damp's potency is its strength: it scales the water-hit bonus in Enemy.take_damage, not soothe
	var duration := attack_data.status_duration
	var max_stacks := attack_data.status_max_stacks
	if _dream_state:
		# Performance: the Dreams' status numbers ride the stat cache (they change with cards and the board).
		var cached: Array = _stats.get(status, []) if _stats_fresh() else []
		if cached.is_empty() or cached[3] != attack_data.status_duration or cached[4] != attack_data.status_max_stacks:
			cached = [_dream_state.get_status_strength_multiplier(status), _dream_state.get_status_duration(attack_data, status),
				_dream_state.get_status_max_stacks(attack_data, status), attack_data.status_duration, attack_data.status_max_stacks]
			_stats[status] = cached
		potency *= cached[0]
		duration = cached[1]
		max_stacks = cached[2]
	var deep := get_status_focus_multiplier()  # Deep Focus: stronger and longer
	if deep != 1.0:
		if duration <= 0.0:
			duration = EnemyStatuses.DEFAULT_DURATION[status]
		duration *= deep  # Its strength side is Potency (get_potency)
	var at: Vector2 = enemy.global_position
	if status == EnemyStatuses.DROWSY and tower_data.line == "wall":
		stacks = _wall_drowsy_room(enemy, stacks)  # Walls slow, but can't put a nightmare to sleep alone
	enemy.apply_status(status, stacks, duration, potency, max_stacks, tower_data.line, self)
	if status == EnemyStatuses.DROWSY:
		SupportLog.credit(self, &"drowsy", stacks)  # Honeysuckle's panel line and the rest report
	# Guiding Light: Marked spreads to nightmares within 1 tile of the target (II: 2 tiles).
	if status == EnemyStatuses.MARKED and _dream_state and _has_rule(&"guiding_light"):
		var reach := (2.0 if _rule_level(&"guiding_light") > 0 else 1.0) * MAP_GRID.cell_size.x
		for other in get_tree().get_nodes_in_group(ENEMY_GROUP):
			if other != enemy and other.global_position.distance_to(at) <= reach:
				other.apply_status(status, stacks, duration, potency, max_stacks, tower_data.line, self)

# Projectile landed at `where` (on `target` if it's still there): soothe it, or everything in the
# splash radius (the splash shares the main hit's crit roll).
func projectile_landed(target: Node2D, where: Vector2) -> void:
	var splash := get_splash_cells() * MAP_GRID.cell_size.x
	if splash > 0.0 and tower_data.get_id() == "puffball" and _dream_state \
			and PathCloud.fog_at(get_tree(), where, "mistveil"):
		_dream_state.note_discovery(DreamState.EVENT_PUFF_IN_FOG)  # Lets Chain Bloom into the profile's pool
		if _has_rule(&"chain_bloom"):
			splash *= CHAIN_BLOOM_SPLASH  # Chain Bloom: a puff inside Mistveil's fog covers 2 tiles
	_kin_on_landing(target, where)
	if splash <= 0.0:
		hit(target)
		_skip(target, where)  # Pebbling: the pebble skips on to a second nightmare
		if _kin_roll(kin_share(&"jewel_thieves", "b")):
			hit(target)  # Jewel Thieves: the magpie pecks twice per swoop
			_kin_fired(&"jewel_thieves")
		_spotter_splash(target, where)
		# Sharp Beaks: Wren's Nest's wrens strike again (+1 per stack).
		if tower_data.get_id() == "wrens_nest":
			for i in _rule_stacks(&"sharp_beaks"):
				hit(target)
		return
	var crit := CRIT if target != null and is_instance_valid(target) and roll_crit(target) else NO_CRIT
	if crit == NO_CRIT and target != null and is_instance_valid(target) and _kin_roll(kin_share(&"spotter", "a")):
		crit = CRIT  # Spotter: a lob at the sniper's target lands as a crit
		_kin_fired(&"spotter")
	if attack_data.splash_share < 1.0 and target != null and is_instance_valid(target):
		# Boulderback: the full hit on its target, a share of it to everything else nearby.
		hit(target, 1.0, false, crit)
		_area_count = get_tree().get_nodes_in_group(ENEMY_GROUP).filter(func(e: Node2D) -> bool: return e.global_position.distance_to(where) <= splash).size()
		for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
			if enemy != target and enemy.global_position.distance_to(where) <= splash:
				hit(enemy, attack_data.splash_share, true, crit)
		_skip(target, where)  # Pebbling: the splash, then the skip
		if _twist == &"landslide":
			FinalTwists.landslide(self, target)  # Every 4th hit rolls a boulder back along the path
	else:
		_splash(where, splash, 1.0, crit)
		var rainfog := kin_share(&"rainfog", "a")
		if rainfog > 0.0 and is_instance_valid(_kin):
			_kin.fog_patch(where, 2.0 * rainfog)  # Rainfog: the splash leaves a fog patch
		_kin_fired(&"rainfog")
	if attack_data.lob:
		_lob_landed(where, splash)
	if attack_data.impact_texture != null:  # Old Mountain's crush
		play_sheet(attack_data.impact_texture, attack_data.impact_frames, attack_data.impact_anchor, where)

# Pebbling's skip: the pebble bounces on to the nearest other nightmare within skip_radius cells of where
# it landed, for skip_share of a hit (a second, smaller throw from the landing spot; it doesn't skip again).
func _skip(from_target: Node2D, where: Vector2) -> void:
	if attack_data.skip_share <= 0.0:
		return
	var reach := attack_data.skip_radius * MAP_GRID.cell_size.x
	var best: Node2D = null
	var best_distance := INF
	for enemy in nightmares_near(get_tree(), where, reach):
		if enemy == from_target or not is_instance_valid(enemy) or enemy.is_cleansed:
			continue
		var distance := where.distance_to(enemy.global_position)
		if distance <= reach and distance < best_distance:
			best_distance = distance
			best = enemy
	if best == null:
		return
	var bounce := Projectile.new(best, attack_data, _skip_landed.bind(attack_data.skip_share))
	bounce.position = where
	add_child(bounce)

func _skip_landed(target, _where: Vector2, share: float) -> void:
	if target != null and is_instance_valid(target):
		hit(target, share)

func _splash(where: Vector2, radius: float, share: float, crit: int) -> void:
	if _dream_state and _any_rule(&"grove_area", GROVE_AREA_RULES):
		GroveRules.area_attack(self, where, radius, share)  # Lingering Splash, Great Ripple
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if enemy.global_position.distance_to(where) <= radius:
			hit(enemy, share, true, crit)

# Cairn / Rockslide: a lobbed stone came down. Loose Stones breaks it into 3 smaller splashes nearby;
# Rockslide leaves rubble on the path tiles it hit.
func _lob_landed(where: Vector2, splash: float) -> void:
	Reactions._effect(&"landing_dust", where, self, splash / MAP_GRID.cell_size.x)
	var hit_spots: Array[Vector2] = [where]
	if _dream_state and _has_rule(&"loose_stones"):
		for i in 3:
			var spot := where + Vector2.from_angle(randf() * TAU) * randf_range(0.5, 1.5) * MAP_GRID.cell_size.x
			spot = MAP_GRID.calculate_map_position(MAP_GRID.calculate_grid_coordinates(spot))  # A tile centre
			_splash(spot, MAP_GRID.cell_size.x * 0.5, LOOSE_STONE_SHARE, NO_CRIT)
			Reactions._effect(&"crit_flare", spot, self, 0.6)
			hit_spots.append(spot)
	if attack_data.rubble_slow <= 0.0:
		return
	var route := _route()
	var cells: Array[Vector2] = []
	for spot in hit_spots:
		for at in route:
			if not cells.has(at) and MAP_GRID.calculate_map_position(at).distance_to(spot) <= splash:
				cells.append(at)
	if not cells.is_empty():
		var rubble := RubblePatch.new(cells, attack_data.rubble_slow * get_slow_multiplier(), attack_data.rubble_time)
		var world := Reactions._world(self)
		rubble.z_index = -1  # On the ground: after the ground and path layers, under the y-sorted map
		world.add_child(rubble)

func fire_at(target: Node2D) -> void:
	if kin_share(&"spotter", "a") > 0.0:
		target = _spotter_target(target)
	_last_fired = target
	var on_land := projectile_landed
	if _hit_boost != 1.0 or _legacy_active:
		# Sudden Bloom / Watchful Rest and a legacy attack's data ride the projectile to where it lands.
		on_land = _land_as.bind(attack_data, _hit_boost)
	var projectile := Projectile.new(target, attack_data, on_land)
	if attack_data.projectile_returns and _dream_state and _dream_state.has_method("get_swoop_return_multiplier"):
		projectile.return_multiplier = _dream_state.get_swoop_return_multiplier()  # Homing Instinct (swoops only)
	projectile.trail = kin_look()
	# Placed before it enters the tree: _ready() takes its home (swoops fly back to it) and a lob's arc
	# length from where it starts. It's top_level, so position is world space.
	projectile.position = global_position + tower_data.get_attack_origin()
	add_child(projectile)

# A projectile fired with `data` at ×`boost` lands. A bound method: the lambda this replaced lost its
# captures by the time the projectile landed ("Lambda capture was freed") and dealt nothing.
func _land_as(target, where: Vector2, data: TowerData, boost: float) -> void:
	run_as(data, boost, projectile_landed.bind(target, where))

# Whirligig: pulses nudge nightmares back a little (each at most once per push_cooldown).
# The timed ability (warden_stats.md, Rootling and Firefly Jar families): every ability_every seconds
# while a nightmare is in range. Rootcurl / Long Way Home pull the one furthest along back along its
# route, Tangleroot / Snugroot Hold the ones furthest along, Beacon Marks everything in range.
func _update_ability(delta: float) -> void:
	_ability_timer -= delta
	if _ability_timer > 0.0:
		return
	var in_range := get_enemies_in_range()
	if in_range.is_empty():
		return
	_ability_timer = attack_data.ability_every
	in_range.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.get_remaining_distance() < b.get_remaining_distance())  # Furthest along first
	if attack_data.mark_all:
		for enemy in in_range:
			_apply_one_status(enemy, EnemyStatuses.MARKED, 1, get_damage())
			if is_instance_valid(enemy) and enemy.statuses.has(EnemyStatuses.MARKED):
				enemy.statuses.marked_extra = maxf(enemy.statuses.marked_extra, attack_data.marked_bonus)
		Reactions._effect(&"pinned", global_position, self, 0.6)  # A flare of light from the Beacon
	if attack_data.pull_tiles > 0.0:
		for enemy in in_range:
			if attack_data.pull_once and enemy.has_meta(&"pulled_home"):
				continue
			var tiles: float = attack_data.pull_boss_tiles if enemy.enemy_data.is_boss else attack_data.pull_tiles
			_pull_on_release(func() -> void:
				if not is_instance_valid(enemy) or enemy.is_cleansed:
					return
				pull(enemy, tiles)
				var snare := kin_share(&"snare", "a")
				if snare > 0.0:
					hold(enemy, 0.5 * snare)  # Snare: the pull ends in a hold
					_kin_fired(&"snare"))
			if attack_data.pull_once:
				enemy.set_meta(&"pulled_home", true)
			break  # One nightmare per pull
	if attack_data.hold_targets > 0:
		for enemy in in_range.slice(0, attack_data.hold_targets):
			hold(enemy, attack_data.hold_time)
			FinalTwists.jammed(self, enemy)  # Logjam: a walker Snugroot holds jams its cell
			var drag := kin_share(&"snare", "b")
			if drag > 0.0 and is_instance_valid(enemy):
				pull(enemy, 0.5 * drag)  # Snare: the hold drags it back
				_kin_fired(&"snare")

# Holds `enemy` for `seconds` (+ Patient Roots: +0.25 s, the Rootling line another +0.25 s), credited to
# this Warden (SupportLog "held_seconds").
func hold(enemy: Node2D, seconds: float) -> void:
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	var bonus: float = _dream_state.get_held_bonus() if _dream_state and _dream_state.has_method("get_held_bonus") else 0.0
	if bonus > 0.0 and tower_data.line == "root":
		bonus += PATIENT_ROOTS_ROOT_HOLD * _rule_power(&"patient_roots")
	enemy.apply_status(EnemyStatuses.HELD, 1, seconds + bonus, 0.0, 0, tower_data.line, self)
	if is_instance_valid(enemy) and enemy.statuses.is_held():
		SupportLog.credit(self, &"held_seconds", seconds + bonus)
		_lantern_reveal(enemy)

# True Graft B: the status of the strongest (damage per second) Warden touching this one, [id, stacks].
func _strongest_neighbour_status() -> Array:
	var best: Array = []
	var best_dps := 0.0
	for other in _other_towers():
		if absf(other.cell.x - cell.x) > 1 or absf(other.cell.y - cell.y) > 1 or other.attack_data.applies_status == &"":
			continue
		var dps: float = other.get_damage() * other.get_attacks_per_second()
		if best.is_empty() or dps > best_dps:
			best_dps = dps
			best = [other.attack_data.applies_status, maxi(other.attack_data.status_stacks, 1)]
	return best

# --- Support looks (screens_ui.md "Support and economy feedback") --------------------------------

# Aura Wardens: the aura_ring_breath ring, scaled to its reach, soft (brighter in build mode or with a
# selection). Boosted Wardens: a faint leaf_mote drifting up, in the aura's colour.
func _update_support_looks() -> void:
	var ring := get_node_or_null("AuraRing") as Node2D
	var is_aura := tower_data.aura_damage_bonus > 0.0 or tower_data.aura_speed_bonus > 0.0
	if is_aura and ring == null and is_inside_tree():
		ring = Fx.play(&"aura_ring_breath", global_position, self, get_aura_reach() * MAP_GRID.cell_size.x / AURA_RING_RADIUS)
		if ring:
			ring.name = "AuraRing"
			ring.z_index = -1  # On the ground, under the Wardens
			ring.modulate = Kinships.FAMILY_COLORS.get(tower_data.line, Palette.GOLD)
	elif ring and not is_aura:
		ring.queue_free()
		ring = null
	if ring:
		ring.scale = Vector2.ONE * get_aura_reach() * MAP_GRID.cell_size.x / AURA_RING_RADIUS
		ring.modulate.a = AURA_RING_BRIGHT if badges_visible() else AURA_RING_SOFT
	var mote := get_node_or_null("LeafMote") as Node2D
	var aura: Tower = _aura_damage_from if is_instance_valid(_aura_damage_from) else \
		(_aura_speed_from if is_instance_valid(_aura_speed_from) else null)
	if aura and mote == null and is_inside_tree():
		mote = Fx.play(&"leaf_mote", global_position + LEAF_MOTE_AT, self)
		if mote:
			mote.name = "LeafMote"
			mote.modulate = Color(Kinships.FAMILY_COLORS.get(aura.tower_data.line, Palette.GOLD), LEAF_MOTE_ALPHA)
	elif mote and aura == null:
		mote.queue_free()
		mote = null
	_leaf_mote = mote


# --- The hidden Kinships' helpers -------------------------------------------------------------------

# A borrowed trait went off (the vine's light bead runs from the teacher to this Warden).
func _kin_fired(id: StringName) -> void:
	if is_instance_valid(_kin) and _kin.has_method("trait_fired"):
		_kin.trait_fired(self, id)

# A projectile landed: Spore Nursery B (a Driftspore puff plants a mushroom ring, one at a time) and
# Hoar Fog A (a Frostfern shot leaves a 1-tile fog puff).
func _kin_on_landing(_target: Node2D, where: Vector2) -> void:
	var fog := kin_share(&"hoar_fog", "a")
	if fog > 0.0 and is_instance_valid(_kin):
		_kin.fog_patch(where, HOAR_FOG_PUFF * fog)
		_kin_fired(&"hoar_fog")
	var nursery := kin_share(&"spore_nursery", "b")
	if nursery <= 0.0 or (is_instance_valid(_nursery_ring) and not _nursery_ring.is_spent()):
		return
	var partner := _kin_partner()
	var at := MAP_GRID.calculate_grid_coordinates(where)
	if partner == null or not _route().has(at):
		return
	_nursery_ring = FairyRing.new(self, at, partner.attack_data, nursery)
	add_child(_nursery_ring)
	trap_set.emit(self, _nursery_ring.global_position)
	_kin_fired(&"spore_nursery")

# Spotter A: the Cairn lobs at what its Standing Stone kin last shot at, when that's in its range.
func _spotter_target(fallback: Node2D) -> Node2D:
	var partner := _kin_partner()
	var spot: Node2D = partner._last_fired if partner else null
	if spot == null or not is_instance_valid(spot) or spot.is_cleansed or not spot.is_in_group(ENEMY_GROUP) \
			or spot.global_position.distance_to(global_position) > get_range_pixels():
		return fallback
	return spot

# Spotter B: the Standing Stone's shot splashes a share onto nightmares right beside its target.
func _spotter_splash(target: Node2D, where: Vector2) -> void:
	var share := kin_share(&"spotter", "b")
	if share <= 0.0:
		return
	var reach := SPOTTER_SPLASH_RADIUS * MAP_GRID.cell_size.x
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if enemy != target and enemy.global_position.distance_to(where) <= reach:
			hit(enemy, SPOTTER_SPLASH * share, true, NO_CRIT)

# Resonant Hollow B: the Chime Stone's pulse echoes once, a moment later, at 30%.
func _resonant_echo(in_range: Array) -> void:
	var share := kin_share(&"resonant_hollow", "b")
	if share <= 0.0 or in_range.is_empty() or not _kin_roll(share):
		return
	var data := attack_data
	var boost := _hit_boost
	get_tree().create_timer(RESONANT_ECHO_DELAY, false).timeout.connect(_resonant_echo_now.bind(data, boost))

func _resonant_echo_now(data: TowerData, boost: float) -> void:
	if not is_inside_tree():
		return
	for enemy in get_enemies_in_range():
		run_as(data, boost, func() -> void: hit(enemy, RESONANT_ECHO, true, NO_CRIT, &"echo"))
	_kin_fired(&"resonant_hollow")

# Resonant Hollow A: an Echo Hollow's echo sets off Static at 3 charges, like a chime (Reactions.echo).
func resonant_set_off(enemy: Node2D) -> void:
	if not _kin_roll(kin_share(&"resonant_hollow", "a")) or not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	var s: EnemyStatuses = enemy.statuses
	if s.stacks(EnemyStatuses.STATIC) < RESONANT_CHARGES:
		return
	var bolt := s.potency(EnemyStatuses.STATIC) * EnemyStatuses.STATIC_BOLT_MULTIPLIER
	var source := s.source(EnemyStatuses.STATIC)
	s.remove(EnemyStatuses.STATIC)
	Reactions.strike_bolt(enemy, bolt, source if source else self, &"static")
	_kin_fired(&"resonant_hollow")

# Lantern Roots B: the Tangleroot's holds reveal hidden nightmares nearby and stop the held one burrowing.
func _lantern_reveal(held: Node2D) -> void:
	var share := kin_share(&"lantern_roots", "b")
	if share <= 0.0:
		return
	if held.has_method("stop_burrowing"):
		held.stop_burrowing()
	var reach := get_range_pixels()
	var container: Node = _dream_state.get_node_or_null("%EnemyContainer") if _dream_state else null
	for enemy in container.get_children() if container else []:
		if enemy.has_method("is_hidden") and enemy.is_hidden() and enemy.global_position.distance_to(global_position) <= reach \
				and enemy.has_method("reveal_for"):
			enemy.reveal_for(LANTERN_ROOTS_REVEAL * share)
	_kin_fired(&"lantern_roots")

# The timed pull lands on the attack's release frame (tower_design.md: the roots lash on frame 2, then
# the grab): plays the attack animation for it, or rides the one already winding up. No attack art, or
# already past the release: right away.
func _pull_on_release(action: Callable) -> void:
	if tower_data.attack_texture == null or _legacy_active or (_attack_time >= 0.0 and _released):
		action.call()
		return
	_flush_pull()
	_pending_pull = action
	if _attack_time >= 0.0:
		return  # An attack is winding up: the pull goes with its release
	_pull_only = true
	_attack_fps = maxf(tower_data.attack_animation_fps, 1.0)
	_attack_time = 0.0
	_released = false
	sprite.texture = tower_data.attack_texture
	sprite.hframes = tower_data.attack_frame_count
	sprite.frame = 0

func _flush_pull() -> void:
	if _pending_pull.is_valid():
		var action := _pending_pull
		_pending_pull = Callable()
		action.call()

# Pulls `enemy` back `tiles` along its route (Patient Roots: the Rootling line 0.5 further), credited to
# this Warden (SupportLog "tiles_pulled").
func pull(enemy: Node2D, tiles: float) -> void:
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	if tower_data.line == "root" and _rule_stacks(&"patient_roots") > 0:
		tiles += PATIENT_ROOTS_PULL * _rule_power(&"patient_roots")
	enemy.push_back(tiles * MAP_GRID.cell_size.x)
	SupportLog.credit(self, &"tiles_pulled", tiles)
	var look := kin_look()
	if look.a > 0.0 and is_instance_valid(enemy):  # Borrowed looks: the pull ends in a small wrap in the kin's colour
		var world := Reactions._world(self)
		if world:
			var wrap := Kinships.KinBurst.new(look, 0.4, 14.0)
			world.add_child(wrap)
			wrap.global_position = enemy.global_position

func _push(enemy: Node2D) -> void:
	if attack_data.push_back_tiles <= 0.0 or not is_instance_valid(enemy) or enemy.is_cleansed \
			or enemy.push_cooldown > 0.0:
		return
	enemy.push_cooldown = attack_data.push_cooldown
	pull(enemy, attack_data.push_back_tiles)

# Lightning: jumps from creature to creature (further between Damp ones). Thunderhead's every Nth
# strike and the Conductive Soil Dream also hit every Damp creature in range.
func _chain_strike(first: Node2D) -> void:
	var hits: Array[Node2D] = [first]
	var max_hits := attack_data.chain_targets
	if first.statuses.has(EnemyStatuses.DAMP):
		max_hits += CHAIN_DAMP_EXTRA_JUMPS
	while hits.size() < max_hits:
		var next := _nearest_jump(hits)
		if next == null:
			break
		hits.append(next)
	if attack_data.chain_all_in_range:
		# Stormheart: the chain goes on until every nightmare in range is struck.
		for enemy in get_enemies_in_range():
			if not hits.has(enemy):
				hits.append(enemy)

	var storm := attack_data.storm_every > 0 and _attack_count % attack_data.storm_every == 0
	if storm:
		Reactions._effect(&"thunderhead_strike", first.global_position, self)  # Signature: a bolt from the sky
	if storm or (_dream_state and _has_rule(&"conductive_soil")):
		for enemy in get_enemies_in_range():
			if enemy.statuses.has(EnemyStatuses.DAMP) and not hits.has(enemy):
				hits.append(enemy)

	# Jumps past the normal count only happened through Damp (DamageLog: "conducted").
	var points := PackedVector2Array([global_position + tower_data.get_attack_origin()])
	# Static Bloom: every nightmare the chain strikes also gets Drowsy (II: 2 stacks).
	var bloom := 0
	if _dream_state and _has_rule(&"static_bloom"):
		bloom = 2 if _rule_level(&"static_bloom") > 0 else 1
	for i in hits.size():
		var enemy := hits[i]
		points.append(enemy.global_position)
		var falloff := maxf(1.0 - attack_data.chain_falloff * i, 0.1)  # Stormheart: −15% per jump
		hit(enemy, falloff, false, ROLL_CRIT, &"conducted" if i >= attack_data.chain_targets and not attack_data.chain_all_in_range else &"")
		var beacon := kin_share(&"storm_beacon", "a")
		if beacon > 0.0 and is_instance_valid(enemy) and not enemy.is_cleansed:
			enemy.apply_status(EnemyStatuses.MARKED, 1, 2.0 * beacon, 0.0, 0, tower_data.line, self)  # Storm Beacon
		if bloom > 0 and is_instance_valid(enemy) and not enemy.is_cleansed:
			enemy.apply_status(EnemyStatuses.DROWSY, bloom, 0.0, 0.0, 0, tower_data.line, self)
	if attack_data.tier >= 4:
		ascended_event.emit(self, first.global_position, hits.size())
	var bolt := ChainBolt.new(points)
	bolt.edge = kin_look()
	add_child(bolt)

# The unstruck creature closest to any creature already struck, within jump range (longer between
# two Damp creatures). Lightning spreads through a group rather than running off in one direction.
func _nearest_jump(struck: Array[Node2D]) -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if struck.has(enemy):
			continue
		for from in struck:
			var reach := attack_data.chain_jump_range
			if from.statuses.has(EnemyStatuses.DAMP) and enemy.statuses.has(EnemyStatuses.DAMP):
				reach += CHAIN_DAMP_EXTRA_RANGE
			var distance := from.global_position.distance_to(enemy.global_position)
			if distance <= reach * MAP_GRID.cell_size.x and distance < best_distance:
				best_distance = distance
				best = enemy
	return best

# A lingering cloud on the path tile the target is walking through.
func _drop_cloud(target: Node2D) -> void:
	var center: Vector2 = MAP_GRID.calculate_map_position(target.get_current_cell())
	var cloud := PathCloud.new(self, center)
	cloud.flecks = kin_look()
	add_child(cloud)
	cloud_formed.emit(self, center, attack_data.cloud_duration)


# --- New kinds -------------------------------------------------------------------------------------------

# The route nightmares walk from the start (empty without a map, e.g. in isolated tests).
func _route() -> PackedVector2Array:
	if _dream_state == null or _dream_state.map_generator == null:
		return PackedVector2Array()
	var map = _dream_state.map_generator
	return map.get_path_from(map.startPath)

func _is_cell_in_range(at: Vector2) -> bool:
	var distance := global_position.distance_to(MAP_GRID.calculate_map_position(at))
	return distance <= get_range_pixels() and distance >= attack_data.min_range * MAP_GRID.cell_size.x

# Fairy Ring: route tiles in range without a ring on them.
func _free_trap_cells() -> Array[Vector2]:
	var taken := {}
	for ring in _rings:
		if is_instance_valid(ring):
			taken[ring.cell] = true
	var free: Array[Vector2] = []
	for at in _route():
		if not taken.has(at) and _is_cell_in_range(at):
			free.append(at)
	return free

func _plant_ring() -> void:
	var free := _free_trap_cells()
	if free.is_empty():
		return
	var ring := FairyRing.new(self, free[randi() % free.size()])
	add_child(ring)
	_rings.append(ring)
	trap_set.emit(self, ring.global_position)

# --- Bellflower family (song and sleep) -----------------------------------------------------------------

# Chime Stone / Lullaby Bell: a pulse sets off a Static bolt on nightmares carrying enough charge.
# Returns whether it set one off.
func _set_off_static(enemy: Node2D) -> bool:
	var at := attack_data.sets_off_static_at
	if at <= 0 or not is_instance_valid(enemy) or enemy.is_cleansed:
		return false
	var s: EnemyStatuses = enemy.statuses
	if s.stacks(EnemyStatuses.STATIC) < at:
		return false
	var bolt := s.potency(EnemyStatuses.STATIC) * EnemyStatuses.STATIC_BOLT_MULTIPLIER * attack_data.set_off_share
	var source := s.source(EnemyStatuses.STATIC)
	s.remove(EnemyStatuses.STATIC)
	Reactions.strike_bolt(enemy, bolt, source if source else self, &"static")
	ComboFeedback.report(&"set_off", self)  # Codex: a pulse set off Static
	return true

# Dreamcatcher: every AURA_TICK, nightmares in range that are asleep or at full Drowsy are Caught
# (+damage taken). Great Dreamcatcher also lengthens sleep once per nightmare and marks them for
# Dreamlight shards; Bad Dreams keeps Caught nightmares Drowsy.
func _update_catch(delta: float) -> void:
	_catch_tick -= delta
	if _catch_tick > 0.0:
		return
	_catch_tick = AURA_TICK
	var bad_dreams := 0
	if _dream_state and _has_rule(&"bad_dreams"):
		bad_dreams = 2 if _rule_level(&"bad_dreams") > 0 else 1
	var many_threads := _rule_stacks(&"many_threads") > 0  # Many Threads: Catch at 4 Drowsy
	for enemy in get_enemies_in_range():
		var s: EnemyStatuses = enemy.statuses
		if tower_data.sleep_extend > 0.0 and s.is_asleep() and not s.sleep_extended:
			s.sleep_extended = true
			s.sleep_time += tower_data.sleep_extend
		if not s.is_catchable() and not (many_threads and s.stacks(EnemyStatuses.DROWSY) >= MANY_THREADS_DROWSY):
			continue
		if not s.is_caught():
			Reactions._effect(&"caught", enemy.global_position, self, 1.0, 0.8)  # The dreamcatcher glyph
			ComboFeedback.report(&"caught", self)  # Codex: a nightmare is Caught
		s.caught_time = AURA_TICK * 1.6
		s.caught_bonus = maxf(s.caught_bonus if s.is_caught() else 0.0, tower_data.caught_bonus)
		if tower_data.caught_shards:
			s.caught_shard = true
			s.caught_shard_tower = self  # Told when the shard drops (shard_dropped)
		if bad_dreams > 0:
			s.bad_dreams_timer += AURA_TICK
			while s.bad_dreams_timer >= 1.0:
				s.bad_dreams_timer -= 1.0
				enemy.apply_status(EnemyStatuses.DROWSY, bad_dreams, 0.0, 0.0, 0, tower_data.line, self)

# Echo Hollow: listens for Reactions; one within range repeats 1 s later on the same spot.
func _connect_echo() -> void:
	if _echo_tracker and _echo_tracker.reaction_fired.is_connected(_on_reaction_nearby):
		_echo_tracker.reaction_fired.disconnect(_on_reaction_nearby)
	_echo_tracker = null
	if tower_data.echo_share <= 0.0 or not is_inside_tree():
		return
	_echo_tracker = ReactionTracker.find(self)
	if _echo_tracker:
		_echo_tracker.reaction_fired.connect(_on_reaction_nearby)

func _on_reaction_nearby(id: StringName, enemy: Node2D, chain: int, towers: Array) -> void:
	if not is_instance_valid(enemy) or tower_data.echo_share <= 0.0:
		return
	var depth := _echo_tracker.echo_depth
	var encore := _dream_state != null and _has_rule(&"encore")
	if depth > 0 and not (encore and depth == 1):
		return  # Echoes don't echo (Encore: once more, at half strength)
	var spot := enemy.global_position
	if spot.distance_to(global_position) > get_range_pixels():
		return
	var share := tower_data.echo_share * (0.5 if depth == 1 else 1.0)
	var applier: Tower = null
	for t in towers:
		if is_instance_valid(t) and t is Tower:
			applier = t
			break
	var as_link := tower_data.echo_is_chain_link
	# Bound, not a lambda: a lambda capturing this Warden errors if it's gone before the timer fires.
	get_tree().create_timer(1.0, false).timeout.connect(_echo_now.bind(id, spot, share, applier, chain, as_link, depth + 1))

func _echo_now(id: StringName, spot: Vector2, share: float, applier, chain: int, as_link: bool, depth: int) -> void:
	Reactions.echo(id, spot, share, self, applier if is_instance_valid(applier) else null, chain, as_link, depth)


# --- Yields (Grandmother Oak, the Heartwood Sapling) ---------------------------------------------------

const WITHER_PER_LEAF := 0.05  # Sapling: each leaf lost since the last rest

func _connect_yield() -> void:
	if not is_inside_tree():
		return
	_kin = Kinships.find(self)  # Made on the first Warden of the run
	SupportLog.find(self)  # Support credit and the drift meter listen from the run's first Warden on
	WardenMeter.find(self)
	if _dream_state == null:
		return
	if _dream_state.has_signal("eldest_changed") and not _dream_state.eldest_changed.is_connected(_on_eldest_changed):
		_dream_state.eldest_changed.connect(_on_eldest_changed)
	var director: DriftDirector = _dream_state.drift_director
	DewCatch.hook(director, _dream_state.run_state)  # The Harvest and interest at every rest (once a run)
	if tower_data.get_id() == "thornwall" and not director.drift_cleared.is_connected(_on_wall_drift_cleared):
		director.drift_cleared.connect(_on_wall_drift_cleared)  # Living Walls
	if tower_data.dew_per_drift <= 0:
		return
	if not director.drift_cleared.is_connected(_on_drift_cleared):
		director.drift_cleared.connect(_on_drift_cleared)
		director.rest_started.connect(_on_yield_rest)  # A method, not a lambda: it must not outlive this Warden
		var run_state: RunState = _dream_state.run_state
		_last_leaves = run_state.leaves
		run_state.leaves_changed.connect(_on_leaves_changed)

# The rest: the Sapling's withering from leaks is forgiven.
func _on_yield_rest(_block: int, _boss: bool, _bonus: int, _perfect: bool) -> void:
	_wither = 0
	_update_withered()

func _on_eldest_changed(_eldest) -> void:
	queue_redraw()  # The crown moves

func _on_leaves_changed(leaves: int, _max_leaves: int) -> void:
	if tower_data.rooted and _last_leaves >= 0 and leaves < _last_leaves:
		_wither += _last_leaves - leaves  # Leaks wither the Sapling until the next rest
		withered.emit(self)
		_update_withered()
	_last_leaves = leaves

# Dew (and for the Sapling, a Dreamlight every few drifts) at the end of each drift.
func _on_drift_cleared(_number: int, _bonus: int, _perfect: bool) -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	var dew := get_drift_yield()
	if dew > 0 and is_catcher():
		add_to_bowl(dew)  # A catcher's drift Dew waits in the bowl for the Harvest
		var log := SupportLog.find(self)
		if log:
			log.add(self, &"dew_caught", dew)
		dew = 0
	if dew > 0:
		_dream_state.run_state.earn_dew_at(dew, global_position)
		sap_yielded.emit(self, dew)
		_play_ripen()
	if tower_data.dreamlight_every > 0:
		_drifts_yielded += 1
		var every := tower_data.dreamlight_every
		if rank >= FOCUS_RANK and tower_data.dreamlight_every_ranked > 0:
			every = tower_data.dreamlight_every_ranked
		if _drifts_yielded % every == 0:
			_dream_state.add_dreamlight(1, &"sapling")  # The Sapling ripens (tagged for Sound)
			dreamlight_ripened.emit(self)


# --- Catch (Dewcatcher, Wellspring, Old Growth's Elder Stump; DewCatch) ---------------------------

var bowl := 0.0  # Dew caught since the last Harvest

func is_catcher() -> bool:
	return tower_data.catch_share > 0.0

func get_catch_radius() -> float:
	# Dew Trail (any level) also widens the catch (Wide Bowl merged into it, dream_audit.md).
	return tower_data.catch_radius + (DewCatch.WIDE_BOWL_STEP if _rule_stacks(&"dew_trail") > 0 else 0.0) + FOCUS_WIDE * choice_count(Focus.WIDE)

# The extra share of Dew `enemy` drops if it's dispelled now (0 = out of reach). Nurture ranks add
# catch instead of damage; Old Growth's Elder Stump catches inside its aura.
func get_catch_share(enemy: Node2D) -> float:
	var distance := enemy.global_position.distance_to(global_position) / MAP_GRID.cell_size.x
	var share := 0.0
	if is_catcher() and distance <= get_catch_radius():
		share = tower_data.catch_share + tower_data.catch_per_rank * get_effective_rank() \
			+ DewCatch.DEW_BOWL_STEP * _rule_stacks(&"dew_bowl") \
			+ FOCUS_STRONG_CATCH * choice_count(Focus.STRONG)
	var growth := kin_share(&"old_growth", "a")
	if growth > 0.0 and distance <= get_aura_reach():
		share = maxf(share, DewCatch.OLD_GROWTH_CATCH * growth)
	if share > 0.0 and _rule_stacks(&"dew_trail") > 0 and enemy.statuses.has(EnemyStatuses.DAMP):
		share += DewCatch.DEW_TRAIL[_rule_level(&"dew_trail")] * _rule_power(&"dew_trail")
	return share

func add_to_bowl(amount: float) -> void:
	bowl += amount
	_show_bowl()

func empty_bowl() -> void:
	bowl = 0.0
	_show_bowl()

# The bowl overlay (catcher_fill_<id>): frame = how full it is, bobbing with the idle frame.
func _show_bowl() -> void:
	var fill := sprite.get_node_or_null("BowlFill") as Sprite2D
	var effect := StringName("catcher_fill_" + tower_data.get_id())
	if fill and (not is_catcher() or fill.texture != Fx.texture(effect)):
		fill.free()  # Sold its bowl, or grew into another catcher
		fill = null
	if not is_catcher():
		return
	if fill == null:
		var texture := Fx.texture(effect)
		if texture == null:
			return
		fill = Sprite2D.new()
		fill.name = "BowlFill"
		fill.texture = texture
		fill.hframes = int(Fx.info(effect).get("frames", 4))
		sprite.add_child(fill)
	fill.frame = 0 if bowl < 1.0 else clampi(1 + int(bowl * 3.0 / DewCatch.BOWL_FULL), 1, fill.hframes - 1)
	_bob_bowl()

func _bob_bowl() -> void:
	var fill := sprite.get_node_or_null("BowlFill") as Sprite2D
	if fill == null:
		return
	var bob: Array = DewCatch.bowl_info(tower_data).get("dy_by_frame", [])
	var dy: float = bob[sprite.frame % bob.size()] if not bob.is_empty() else 0.0
	fill.offset = sprite.offset + Vector2(0, dy)

# --- Wall cards (Thornwall; dream_design.md "Support Warden cards") -------------------------------

var _wall_tick := 0.0
var _scent_time := 0.0

# Thorn Snare: Phantoms passing through and Gravecrawlers passing under this Thornwall are Held (II:
# longer, and Night Hounds sprinting past too), once each. Scented Hedge: touching a Honeysuckle, it
# gives off the scent at half strength.
func _update_wall(delta: float) -> void:
	_wall_tick -= delta
	if _wall_tick > 0.0:
		return
	_wall_tick = WALL_TICK
	var snare := _rule_stacks(&"thorn_snare") > 0
	var scent := _scented_by() if _rule_stacks(&"scented_hedge") > 0 else null
	if not snare and scent == null:
		return
	var level: int = _rule_level(&"thorn_snare") if snare else 0
	var cell_px := MAP_GRID.cell_size.x
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if not is_instance_valid(enemy) or enemy.is_cleansed:
			continue
		var distance: float = enemy.global_position.distance_to(global_position) / cell_px
		if snare and not enemy.has_meta(_snare_key()):
			var kind: String = enemy.enemy_data.resource_path.get_file().get_basename()
			var caught: bool = distance <= THORN_SNARE_REACH and THORN_SNARE_KINDS.has(kind) \
				or level > 0 and kind == "hedgehog" and enemy.rolling and distance <= THORN_SNARE_SPRINT_REACH
			if caught:
				enemy.set_meta(_snare_key(), true)
				hold(enemy, THORN_SNARE_TIME[level])
	if scent != null:
		_scent_time -= WALL_TICK
		if _scent_time <= 0.0:
			_scent_time = 1.0 / maxf(scent.get_attacks_per_second() * SCENTED_HEDGE, 0.01)  # Half as often
			for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
				if is_instance_valid(enemy) and not enemy.is_cleansed \
						and enemy.global_position.distance_to(global_position) / cell_px <= scent.tower_data.attack_range:
					var data: TowerData = scent.tower_data
					var added := _wall_drowsy_room(enemy, data.status_stacks)  # The relay is a wall too: capped at 3
					enemy.apply_status(EnemyStatuses.DROWSY, added, data.status_duration, 1.0, data.status_max_stacks, data.line, self)
					SupportLog.credit(self, &"drowsy", added)

func _snare_key() -> StringName:
	return StringName("snared_%d" % get_instance_id())

# Scented Hedge: the Honeysuckle touching this Thornwall, or null.
func _scented_by() -> Tower:
	for other in _other_towers():
		if other.tower_data.get_id() == "honeysuckle" and absf(other.cell.x - cell.x) <= 1 and absf(other.cell.y - cell.y) <= 1:
			return other
	return null

# Living Walls: a Thornwall that has stood 5 drifts grows into a free Bramble (at the drift's end).
func _on_wall_drift_cleared(_number: int, _bonus: int, _perfect: bool) -> void:
	if not is_inside_tree() or is_queued_for_deletion() or tower_data.get_id() != "thornwall" \
			or _rule_stacks(&"living_walls") <= 0 or DreamState.drifts_stood(self) < LIVING_WALLS_DRIFTS:
		return
	for data in tower_data.evolves_to:
		if data is TowerData and data.get_id() == "bramble":
			evolve(data, 0)
			return

# Dew this Warden yields at the end of a drift right now.
func get_drift_yield() -> int:
	var dew := tower_data.dew_per_drift + tower_data.dew_per_rank * rank
	if is_catcher() and tower_data.rest_interest <= 0.0:
		dew += roundi(KINDRED_DEW * choice_count(Focus.KINDRED))  # Kindred Dewcatcher ranks
	return roundi(dew * maxf(1.0 - WITHER_PER_LEAF * _wither, 0.0))

# Plays one pass of a sheet (a row of `frames`) with its `anchor` pixel on `at`, in the world (never
# under the Warden or nightmare containers). Ascended effects: tide wave, root grasp, the crush.
func play_sheet(texture: Texture2D, frames: int, anchor: Vector2, at: Vector2, flip: bool = false,
		fps: float = 12.0) -> void:
	var world := Reactions._world(self)
	if world == null and get_parent() != null:
		world = get_parent().get_parent()
	if world == null:
		return
	var sheet := Sprite2D.new()
	sheet.texture = texture
	sheet.hframes = frames
	sheet.centered = false
	sheet.offset = -anchor
	sheet.flip_h = flip
	sheet.z_index = 5
	world.add_child(sheet)
	sheet.global_position = at
	var tween := sheet.create_tween()
	tween.tween_property(sheet, "frame", frames - 1, (frames - 1) / fps)
	tween.tween_interval(1.0 / fps)
	tween.tween_callback(sheet.queue_free)

# The Sapling's withered overlay: crossfaded over the idle by how many leaves were lost since the rest.
func _update_withered() -> void:
	var overlay := get_node_or_null("Withered") as Sprite2D
	if tower_data.withered_texture == null:
		if overlay:
			overlay.queue_free()
		return
	if overlay == null:
		overlay = Sprite2D.new()
		overlay.name = "Withered"
		add_child(overlay)
		move_child(overlay, sprite.get_index() + 1)
	overlay.texture = tower_data.withered_texture
	overlay.hframes = tower_data.frame_count
	overlay.offset = tower_data.sprite_offset
	overlay.modulate.a = clampf(WITHER_PER_LEAF * _wither * 4.0, 0.0, 1.0)  # 5 leaves = fully withered
	overlay.visible = overlay.modulate.a > 0.0

# The Sapling ripens when it yields: a glow, a Dew drop and a Dreamlight mote rise.
func _play_ripen() -> void:
	if tower_data.ripen_texture == null or not is_inside_tree():
		return
	var ripen := Sprite2D.new()
	ripen.texture = tower_data.ripen_texture
	ripen.hframes = tower_data.ripen_frames
	ripen.offset = tower_data.sprite_offset
	ripen.z_index = 1
	add_child(ripen)
	var tween := ripen.create_tween()
	tween.tween_property(ripen, "frame", tower_data.ripen_frames - 1, (tower_data.ripen_frames - 1) / 10.0)
	tween.tween_interval(0.1)
	tween.tween_callback(ripen.queue_free)

# The cells this Warden stands on (the Sapling covers 2×2 from `cell`).
func get_cells() -> Array[Vector2]:
	return footprint_cells(cell, get_footprint())

# Cells per side this Warden covers: its data's (Ascended forms and the Sapling: 2), or 1 for an
# Ascended form from a save made before they grew to 2×2.
func get_footprint() -> int:
	return footprint_size if footprint_size > 0 else tower_data.footprint

static func footprint_cells(origin: Vector2, size: int) -> Array[Vector2]:
	var cells: Array[Vector2] = []
	for dy in size:
		for dx in size:
			cells.append(origin + Vector2(dx, dy))
	return cells

# Where a Warden of `size` cells per side sits when its top-left cell is `origin`.
static func footprint_centre(origin: Vector2, size: int) -> Vector2:
	return MAP_GRID.calculate_map_position(origin) + MAP_GRID.cell_size * (size - 1) / 2.0


# --- Birds and seeds --------------------------------------------------------------------------------

# Up to `count` different nightmares in range, best first by this Warden's target mode.
func find_targets(count: int) -> Array:
	if count <= 1:
		var one := find_target()
		return [one] if one != null else []
	var mode := get_target_mode()
	# Perf (stacked drifts): each nightmare scored once, not twice per comparison inside the sort.
	var scored: Array = []
	for enemy in get_enemies_in_range():
		scored.append([_target_score(enemy, mode), enemy])
	scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var ranked: Array = []
	for i in mini(count, scored.size()):
		ranked.append(scored[i][1])
	return ranked

# Hummingbird Bower / Jewelwing Court: birds fly out and peck; each peck is a full hit.
func _send_hummingbirds() -> void:
	var birds := attack_data.peck_birds
	# Spread: each bird takes a different nightmare (doubling up when there are fewer). Focus
	# (Jewelwing Court's toggle): every bird on the strongest.
	var chosen: Array
	if focus_strongest:
		var all := get_enemies_in_range()
		all.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.health > b.health)
		chosen = all.slice(0, 1)
	else:
		chosen = find_targets(birds)
	if chosen.is_empty():
		return
	var targets := []
	for i in birds:
		targets.append(chosen[i % chosen.size()])
	var pecks := attack_data.pecks + _rule_stacks(&"sharp_beaks")
	for target in targets:
		var bird := PeckingBird.new(self, target, pecks, attack_data.peck_time)
		add_child(bird)
		bird.global_position = global_position + tower_data.get_attack_origin()
		_out.append(bird)

# One peck from a hummingbird (PeckingBird calls this). Jewelwing's Flurry makes every Nth crit;
# Needle Point pierces the dread shell; Charged Feathers / Pollen Beaks add a status per peck.
func peck(enemy: Node2D) -> void:
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	_pecks_landed += 1
	var crit := ROLL_CRIT
	if attack_data.flurry_every > 0 and _pecks_landed % attack_data.flurry_every == 0:
		crit = CRIT
	if _dream_state and _has_rule(&"needle_point"):
		enemy.pierce_coat_once = true
	Reactions._effect(&"peck_spark", enemy.global_position + Vector2(randf_range(-6, 6), -14), self)
	hit(enemy, 1.0, false, crit)
	if kin_share(&"jewel_thieves", "a") > 0.0 and is_instance_valid(enemy) and not enemy.is_cleansed:
		_jewel_pecks += 1
		if _jewel_pecks % JEWEL_THIEVES_EVERY == 0 and _kin_roll(kin_share(&"jewel_thieves", "a")):
			var stripped: bool = enemy.strip_buff(self) if enemy.has_method("strip_buff") else false
			if not stripped:
				enemy.bonus_dew = maxi(enemy.bonus_dew, 1)  # Nothing to steal: +1 Dew instead
			_kin_fired(&"jewel_thieves")
	if not is_instance_valid(enemy) or enemy.is_cleansed or _dream_state == null:
		return
	if _has_rule(&"charged_feathers"):
		enemy.apply_status(EnemyStatuses.STATIC, 1, 0.0, get_damage(), 0, "light", self)
	if _has_rule(&"pollen_beaks"):
		enemy.apply_status(EnemyStatuses.SPORED, 1, 0.0, get_damage() * SPORE_POTENCY, 0, "spore", self)

# Samara / Autumn Gale: seeds fly out along a straight line and back through everything.
func _throw_seeds() -> void:
	var target := find_target()
	if target == null:
		return
	_throws += 1
	var length := (attack_data.boomerang_length + _rule_stacks(&"longer_flight")) * MAP_GRID.cell_size.x
	var from := global_position + tower_data.get_attack_origin()
	var directions: Array[Vector2] = []
	if attack_data.boomerang_seeds > 1:
		directions = _busiest_lines(from, length, attack_data.boomerang_seeds)
	else:
		directions = [from.direction_to(target.global_position)]
	if _dream_state and _has_rule(&"seed_storm") and _throws % 5 == 0:
		# Seed Storm: every 5th throw bursts into 5 seeds in a fan around the first line.
		var centre := directions[0]
		directions = []
		for i in 5:
			directions.append(centre.rotated(deg_to_rad(-40.0 + 20.0 * i)))
	var bonus := _catch_streak
	var world := Reactions._world(self)  # Never the TowerContainer: its children are all Wardens
	_seeds_thrown = directions.size()
	_seeds_home = 0
	_throw_hit = false
	for direction in directions:
		var seed := SeedBoomerang.new(self, from, direction, length, 1.0 + bonus)
		world.add_child(seed)  # Flies over the maze in world space
		_out.append(seed)

# A seed came home. Once every seed of a throw is back, Autumn Gale's catch rhythm counts the throw:
# +10% on the next one if any seed hit something, back to nothing if none did.
func catch_seed(hit_anything: bool) -> void:
	seed_caught.emit(self)
	_throw_hit = _throw_hit or hit_anything
	_seeds_home += 1
	if _seeds_home < _seeds_thrown:
		return
	if attack_data.catch_bonus > 0.0:
		if _throw_hit:
			_catch_streak = minf(_catch_streak + attack_data.catch_bonus, attack_data.catch_bonus_max)
		else:
			_catch_streak = 0.0
	_seeds_home = 0
	_throw_hit = false

# The `count` directions from `from` whose `length`-long lines cross the most nightmares.
func _busiest_lines(from: Vector2, length: float, count: int) -> Array[Vector2]:
	var candidates: Array[Vector2] = []
	for enemy in get_enemies_in_range():
		candidates.append(from.direction_to(enemy.global_position))
	var scored := candidates.map(func(d: Vector2) -> Array:
		var on_line := 0
		for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
			var p: Vector2 = enemy.global_position - from
			var along := p.dot(d)
			if along >= 0.0 and along <= length and absf(p.cross(d)) <= SeedBoomerang.HIT_RADIUS:
				on_line += 1
		return [on_line, d])
	scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var result: Array[Vector2] = []
	for entry in scored:
		var d: Vector2 = entry[1]
		if result.any(func(r: Vector2) -> bool: return r.angle_to(d) < 0.15 and r.angle_to(d) > -0.15):
			continue  # Two seeds down the same line is a waste
		result.append(d)
		if result.size() >= count:
			break
	return result

# Performance: Dream rule lookups are cached for every Warden together (DreamState.rule_stacks walks the
# taken cards; Wardens asked ~500 times a frame). The key changes with any card taken or stacked (take()
# bumps the board version), a card added or dropped, a board change (dormant cards waking) and
# unlock_everything, so a lookup never sees a stale set.
static var _rules := {}  # rule -> [stacks (uncapped), level]

# Performance: one rule cache for every Warden (the rules are the run's); its key is compared field by
# field (no array built per call: hits ask several rules each).
static var _rules_owner := 0
static var _rules_board := -1
static var _rules_stacks := -1
static var _rules_pool := -1
static var _rules_all := false

func _rule_entry(rule: StringName) -> Array:
	if _dream_state == null or not _dream_state.has_method("rule_stacks"):
		return [0, 0]
	var ds := _dream_state
	if _rules_owner != ds.get_instance_id() or _rules_board != ds.board_version or _rules_stacks != ds.stacks.size() \
			or _rules_pool != ds.pool.size() or _rules_all != ds.unlock_everything:
		_rules_owner = ds.get_instance_id()
		_rules_board = ds.board_version
		_rules_stacks = ds.stacks.size()
		_rules_pool = ds.pool.size()
		_rules_all = ds.unlock_everything
		_rules = {}
	var entry: Array = _rules.get(rule, [])
	if entry.is_empty():
		entry = [_dream_state.rule_stacks(rule), _dream_state.rule_level(rule)]
		_rules[rule] = entry
	return entry

func _rule_stacks(rule: StringName) -> int:
	return mini(_rule_entry(rule)[0], 3)

func _has_rule(rule: StringName) -> bool:
	return _rule_entry(rule)[0] > 0

func _rule_level(rule: StringName) -> int:
	return _rule_entry(rule)[1]

# Tag resonance (dream_audit.md): a card's numbers scale with the owned cards sharing its tags (1.0 = none).
func _rule_power(rule: StringName) -> float:
	return _dream_state.rule_power(rule) if _dream_state and _dream_state.has_method("rule_power") else 1.0

# Gust: soothes everything in range a little, then copies the statuses of the most-afflicted
# nightmare onto up to `spread_targets` others near it (half stacks, full duration).
func _spread() -> void:
	var in_range := get_enemies_in_range()
	var source: Node2D = null
	for enemy in in_range:
		if source == null or enemy.statuses.total_stacks() > source.statuses.total_stacks():
			source = enemy
	for enemy in in_range:
		hit(enemy, 1.0, true)
	if source == null or not is_instance_valid(source) or source.is_cleansed or source.statuses.total_stacks() == 0:
		return
	var reach := lerpf(attack_data.spread_radius, TAILWIND_REACH, kin_share(&"tailwind", "b")) * MAP_GRID.cell_size.x  # Tailwind
	var others := get_tree().get_nodes_in_group(ENEMY_GROUP).filter(func(e: Node2D) -> bool:
		return e != source and e.global_position.distance_to(source.global_position) <= reach)
	others.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.global_position.distance_squared_to(source.global_position) \
			< b.global_position.distance_squared_to(source.global_position))
	var copied: Array = source.statuses.snapshot()
	var full_copy := _rule_stacks(&"carried_on_the_wind") > 0  # Carried on the Wind (Entwined): full stacks
	# Ill Wind (Dream): copied statuses deal more effect damage (their potency).
	var ill_wind := 1.0 + (DreamState.ILL_WIND_BONUS * _rule_power(&"ill_wind") if _rule_stacks(&"ill_wind") > 0 else 0.0)
	# Eddy (Dream): Gust copies also reach nightmares on the path tiles beside each target (a bend: 2 along).
	if tower_data.line == "wind" and _rule_stacks(&"eddy") > 0:
		others = _eddy_targets(others.slice(0, attack_data.spread_targets), source)
	var points := PackedVector2Array()
	var copies := others.size() if tower_data.line == "wind" and _rule_stacks(&"eddy") > 0 else mini(attack_data.spread_targets, others.size())
	for i in copies:
		others[i].statuses.gust_time = 0.5  # Storm Front: a Reaction these statuses complete reaches further
		for status in copied:
			others[i].apply_status(status.id, status.stacks if full_copy else maxi(ceili(status.stacks / 2.0), 1), status.time,
				status.potency * ill_wind, 0, status.line, status.source)
		var devil := kin_share(&"dust_devil", "a")
		var blade := _kin_partner()
		if devil > 0.0 and blade and is_instance_valid(others[i]):
			blade.hit(others[i], devil, true)  # Dust Devil: each copy also deals one blade hit
			_kin_fired(&"dust_devil")
		points.append(source.global_position)
		points.append(others[i].global_position)
	for i in range(0, points.size(), 2):
		add_child(ChainBolt.new(PackedVector2Array([points[i], points[i + 1]]), WIND_COLOR, 3.0))

# Catalogue cards on a hit (dream_design.md 204–226): Mycelium (a Sprout touching a Sporeling-line Warden
# poisons), Fireflies in the Grass (… touching a Firefly-line Warden: 1 Charged every 3rd hit), Resonance
# (Chime Stone: +1 Charged per nightmare it pulses).
var _firefly_hits := 0

func _catalogue_hit(enemy: Node2D) -> void:
	if not is_instance_valid(enemy) or enemy.is_cleansed or _dream_state == null:
		return
	if not _any_rule(&"__catalogue_cards", CATALOGUE_HIT_RULES):
		return
	if tower_data.get_id() == "sprout":
		if _touch_lines.has("spore") and _rule_stacks(&"mycelium") > 0:
			_apply_one_status(enemy, EnemyStatuses.SPORED, roundi(DreamState.MYCELIUM_SPORED * _rule_power(&"mycelium")), get_damage())
		if _touch_lines.has("light") and _rule_stacks(&"fireflies_in_the_grass") > 0:
			_firefly_hits += 1
			if _firefly_hits % DreamState.FIREFLIES_EVERY == 0 and is_instance_valid(enemy):
				_apply_one_status(enemy, EnemyStatuses.STATIC, 1, get_damage())
	if _resonance() and is_instance_valid(enemy) and not enemy.is_cleansed:
		_apply_one_status(enemy, EnemyStatuses.STATIC, roundi(DreamState.RESONANCE_CHARGED * _rule_power(&"resonance")), get_damage())

func _resonance() -> bool:
	return _dream_state != null and tower_data.get_id() == "chime_stone" and _has_rule(&"resonance")

# Eddy: `targets` plus the nightmares on the route tiles next to each (2 along where the path bends).
func _eddy_targets(targets: Array, source: Node2D) -> Array:
	var route := _route()
	var result := targets.duplicate()
	var extra_cells := {}
	for target in targets:
		var at: int = route.find(target.get_current_cell())
		if at < 0:
			continue
		var reach := 2 if _is_bend(route, at) else 1
		for step in range(-reach, reach + 1):
			if step != 0 and at + step >= 0 and at + step < route.size():
				extra_cells[route[at + step]] = true
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if enemy != source and not result.has(enemy) and extra_cells.has(enemy.get_current_cell()):
			result.append(enemy)
	return result

static func _is_bend(route: PackedVector2Array, at: int) -> bool:
	if at <= 0 or at >= route.size() - 1:
		return false
	return (route[at] - route[at - 1]) != (route[at + 1] - route[at])

# Pinwheel: blades hit every nightmare on the 8 tiles around it, harder the more of those tiles are path.
func _spin() -> void:
	var path_tiles := 0
	var route := _route()
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if (dx != 0 or dy != 0) and route.has(cell + Vector2(dx, dy)):
				path_tiles += 1
	var hairpin := DreamState.HAIRPIN_WINDS_EXTRA * _rule_power(&"hairpin_winds") if _rule_stacks(&"hairpin_winds") > 0 else 0.0
	var bonus := clampf((path_tiles - attack_data.spin_free_path_tiles) * attack_data.spin_bonus,
		0.0, attack_data.spin_bonus_max + hairpin * attack_data.spin_bonus)  # Hairpin Winds: one more path tile counts
	var struck := _enemies_on_adjacent_tiles()
	for enemy in struck:
		hit(enemy, 1.0 + bonus, true)
	# Dust Devil (Pinwheel line): the blades copy the most-afflicted nightmare's statuses (half stacks)
	# onto the others they hit.
	if _kin_roll(kin_share(&"dust_devil", "b")) and struck.size() > 1:
		var alive := struck.filter(func(e) -> bool: return is_instance_valid(e) and not e.is_cleansed)
		if alive.size() > 1:
			alive.sort_custom(func(a, b) -> bool: return a.statuses.total_stacks() > b.statuses.total_stacks())
			var copied: Array = alive[0].statuses.snapshot()
			for other in alive.slice(1):
				for status in copied:
					if is_instance_valid(other) and not other.is_cleansed:
						other.apply_status(status.id, maxi(ceili(status.stacks / 2.0), 1), status.time,
							status.potency, 0, status.line, status.source)

func _enemies_on_adjacent_tiles() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		var at: Vector2 = enemy.get_current_cell()
		if absf(at.x - cell.x) <= 1 and absf(at.y - cell.y) <= 1:
			result.append(enemy)
	return result

# Pond Keeper: its tongue grabs the target, soothes it and makes it Damp, then drags it back to the
# path tile nearest the pond (bosses only go back a couple of tiles).
func _grab(target: Node2D) -> void:
	var from := global_position + tower_data.get_attack_origin()
	add_child(ChainBolt.new(PackedVector2Array([from, target.global_position]), TONGUE_COLOR, 0.0))
	hit(target)
	if not is_instance_valid(target) or target.is_cleansed:
		return
	if target.enemy_data.is_boss:
		pull(target, attack_data.pull_boss_tiles)
		grab_finished.emit(self, target)
		return
	var behind: PackedVector2Array = target.get_cells_behind()
	var best := -1
	var best_distance := INF
	for i in behind.size():
		var distance := behind[i].distance_squared_to(cell)
		if distance < best_distance:
			best_distance = distance
			best = i
	if best >= 0:
		target.pull_back_to(best)
	grab_finished.emit(self, target)  # The drag is instant: it ends right away

# Rootlight: glowing roots light the path tiles in range; nightmares there are soothed and Marked.
func _light() -> void:
	var before := _lit_cells.duplicate()
	_lit_cells.clear()
	for at in _route():
		if _is_cell_in_range(at):
			_lit_cells.append(at)
	# Long Light (Dream): tiles the light moved on from stay lit a while (still holding once per nightmare).
	var linger: float = _dream_state.get_lit_linger() if _dream_state and _dream_state.has_method("get_lit_linger") else 0.0
	if linger > 0.0:
		for at in before:
			if not _lit_cells.has(at) and not _lit_until.has(at):
				_lit_until[at] = _anim_time + linger
		for at in _lit_until.keys():
			if _lit_until[at] < _anim_time or _lit_cells.has(at):
				_lit_until.erase(at)
			else:
				_lit_cells.append(at)
	queue_redraw()
	for enemy in get_enemies_in_range():
		hit(enemy, 1.0, true)

# Sunpetal: a beam on one target that ramps up the longer it holds (faster on Drowsy or Held).
func _update_beam(delta: float) -> void:
	var target := find_target()
	if target != _beam_target:
		if target == null:
			_stop_beam()  # Back to the idle sheet (it knows a beam was on only before the target is cleared)
			return
		# Midsummer (beam_keep_share): a new target within BEAM_KEEP_TIME of the last keeps part of the ramp.
		var old_ramp := _beam_ramp if _beam_target != null else \
			(_kept_ramp if _anim_time - _kept_ramp_at <= BEAM_KEEP_TIME else 1.0)
		_beam_ramp = 1.0 + (old_ramp - 1.0) * attack_data.beam_keep_share
		_beam_tick = 0.0
		_beam_target = target
		_show_attack_pose()
	if _beam_target == null:
		return
	var fast: bool = _beam_target.statuses.has(EnemyStatuses.DROWSY) or _beam_target.statuses.is_held()
	var rate := attack_data.beam_ramp_per_second * (BEAM_RAMP_FAST if fast else 1.0)
	_beam_ramp = minf(_beam_ramp + rate * delta, attack_data.beam_ramp_max)
	_beam_behind = _find_behind(_beam_target) if attack_data.beam_behind_share > 0.0 else null
	_beam_tick += delta
	while _beam_tick >= BEAM_TICK and is_instance_valid(_beam_target):
		_beam_tick -= BEAM_TICK
		var share := get_attacks_per_second() * BEAM_TICK * _beam_ramp
		hit(_beam_target, share)
		beam_ticked.emit(self, _beam_ramp)
		if is_instance_valid(_beam_target) and not _beam_target.statuses.has(EnemyStatuses.MARKED) \
				and _kin_roll(kin_share(&"sunspot", "a")):
			_apply_one_status(_beam_target, EnemyStatuses.MARKED, 1, get_damage())  # Sunspot: the beam Marks
			_kin_fired(&"sunspot")
		if is_instance_valid(_beam_behind):
			hit(_beam_behind, share * attack_data.beam_behind_share)
		if _twist == &"solstice" and is_instance_valid(_beam_target):
			FinalTwists.solstice_tick(self, share)  # Solstice: at full ramp the beam forks
	if not is_instance_valid(_beam_target) or _beam_target.is_cleansed:
		_stop_beam()  # The target is gone: back to the idle sheet (8 frames), not the 6-frame pose
	queue_redraw()

func _stop_beam() -> void:
	var was_beaming := _beam_target != null
	if was_beaming:
		_kept_ramp = _beam_ramp  # A new target soon after keeps part of it (beam_keep_share)
		_kept_ramp_at = _anim_time
	_beam_target = null
	_beam_behind = null
	_beam_ramp = 1.0
	if was_beaming and is_node_ready() and not _legacy_active:
		_show_idle()
	queue_redraw()

# The nightmare right behind `target` on the path (Midsummer's beam carries through to it).
func _find_behind(target: Node2D) -> Node2D:
	var best: Node2D = null
	var best_remaining := INF
	var target_remaining: float = target.get_remaining_distance()
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if enemy == target or enemy.global_position.distance_to(target.global_position) > 1.5 * MAP_GRID.cell_size.x:
			continue
		var remaining: float = enemy.get_remaining_distance()
		if remaining > target_remaining and remaining < best_remaining:
			best_remaining = remaining
			best = enemy
	return best

# The White Stag: nightmares in range are slower and take more damage (Wardens in range get crit
# chance, see _refresh_neighbours).
func _update_aura(delta: float) -> void:
	_aura_tick -= delta
	if _aura_tick > 0.0:
		return
	_aura_tick = AURA_TICK
	var inside := get_enemies_in_range()
	if tower_data.slows_in_aura:  # The White Stag (Grandmother Oak's aura is for Wardens only)
		for enemy in inside:
			enemy.statuses.set_in_stag_aura(AURA_TICK * 1.6)
	# Its pulse animation plays every few seconds while nightmares are inside.
	_cooldown = maxf(_cooldown - AURA_TICK, 0.0)
	if not inside.is_empty() and tower_data.attack_texture != null and _cooldown <= 0.0 and _attack_time < 0.0:
		_start_attack()
		_cooldown = AURA_PULSE_EVERY


# --- Drawing and targeting ------------------------------------------------------------------------------

func _draw() -> void:
	_draw_empowered()
	if tower_data.texture == null:
		draw_placeholder(self, tower_data.placeholder_color)
	_draw_rank_pips()
	for at in _lit_cells:
		var centre := to_local(MAP_GRID.calculate_map_position(at))
		var half := MAP_GRID.cell_size / 2.0 - Vector2(6, 6)
		draw_rect(Rect2(centre - half, half * 2.0), Color(LIGHT_COLOR, 0.12))
	if is_instance_valid(_beam_target):
		var from := tower_data.get_attack_origin()
		var width := 2.0 + 2.0 * _beam_ramp
		for target in [_beam_target, _beam_behind]:
			if not is_instance_valid(target):
				continue
			var to := to_local(target.global_position)
			draw_line(from, to, Color(_beam_data().beam_color, 0.35), width * 2.0)
			draw_line(from, to, Color(Palette.HEARTLIGHT, 0.9), maxf(width * 0.5, 1.5))
			from = to  # Midsummer's beam carries on from the target to the one behind it
	if attack_data != null and attack_data.attack_kind == TowerData.AttackKind.AURA:
		draw_arc(Vector2.ZERO, get_range_pixels(), 0.0, TAU, 64, Color(Palette.MOONLIGHT, 0.12), 3.0)
	_draw_badges()
	_draw_target_pip()
	if _dream_state and _dream_state.has_method("is_eldest") and _dream_state.is_eldest(self):
		# The Eldest: a small crown of three golden rings over the slab.
		var top := Vector2(0, -MAP_GRID.cell_size.y * 0.5 - 4.0) + tower_data.sprite_offset
		for i in 3:
			draw_arc(top + Vector2((i - 1) * 7.0, -absf(i - 1) * -2.0), 3.5, 0.0, TAU, 12, Color(Palette.GLOW, 0.95), 1.5)

# Under the sprite: a warm ring while an attack is stored (Sudden Bloom, Watchful Rest) and a soft
# rising glow on this block's Underdogs (DreamState.is_underdog: the least damage last block).
const EMPOWERED_GLOW := Palette.GLOW
const UNDERDOG_GLOW := Palette.DEWLIGHT

func _draw_empowered() -> void:
	var radius := MAP_GRID.cell_size.x * 0.42 * get_footprint()
	_underdog_drawn = _is_underdog()
	if _underdog_drawn:
		for i in 3:
			draw_circle(Vector2(0, 6), radius * (1.0 - i * 0.2), Color(UNDERDOG_GLOW, 0.07))
	if bloom_left > 0.0 or watch_charged:
		draw_arc(Vector2(0, 6), radius, 0.0, TAU, 32, Color(EMPOWERED_GLOW, 0.3), 5.0)
		draw_arc(Vector2(0, 6), radius, 0.0, TAU, 32, Color(EMPOWERED_GLOW, 0.85), 1.5)

# Whose beam is drawn: Stormheart's is Midsummer's (its legacy).
func _beam_data() -> TowerData:
	if legacy_data != null and legacy_data.attack_kind == TowerData.AttackKind.BEAM:
		return legacy_data
	return attack_data

func _is_underdog() -> bool:
	return _dream_state != null and _dream_state.has_method("is_underdog") and _dream_state.is_underdog(self)

# Whirligig (status jobs, 2026-09-29): every copy_status_every s, the most afflicted nightmare in range
# (the most status stacks) lends its biggest status, half the stacks, to the nearest other nightmare
# within COPY_REACH cells. The copy keeps the original's strength and applier.
const COPY_REACH := 1.5
const COPYABLE: Array[StringName] = [EnemyStatuses.DAMP, EnemyStatuses.DROWSY, EnemyStatuses.SPORED,
	EnemyStatuses.MARKED, EnemyStatuses.STATIC]
var _copy_timer := 0.0

func _update_status_copy(delta: float) -> void:
	_copy_timer -= delta
	if _copy_timer > 0.0:
		return
	var from: Node2D = null
	var most := 0
	for enemy in get_enemies_in_range():
		var total := 0
		for id in COPYABLE:
			total += enemy.statuses.stacks(id)
		if total > most:
			most = total
			from = enemy
	if from == null:
		return  # Nothing to carry: look again next frame
	_copy_timer = attack_data.copy_status_every
	var s: EnemyStatuses = from.statuses
	var status := &""
	for id in COPYABLE:
		if s.stacks(id) > 0 and (status == &"" or s.stacks(id) > s.stacks(status)):
			status = id
	var to: Node2D = null
	for other in nightmares_near(get_tree(), from.global_position, COPY_REACH * MAP_GRID.cell_size.x):
		if other != from and is_instance_valid(other) and not other.is_cleansed \
				and other.global_position.distance_to(from.global_position) <= COPY_REACH * MAP_GRID.cell_size.x \
				and (to == null or other.global_position.distance_to(from.global_position) < to.global_position.distance_to(from.global_position)):
			to = other
	if to == null:
		return
	var applier: Node = s.source(status)
	to.apply_status(status, maxi(s.stacks(status) / 2, 1), s.time_left(status), s.potency(status), 0,
		applier.tower_data.line if applier is Tower else tower_data.line, applier if applier is Tower else self)

# Rootlight / Starcave (status jobs, 2026-09-29): a Hold on a nightmare standing on a lit tile lasts
# lit_hold_multiplier times as long. Each Hold is stretched once (remembered until it would have ended).
const LIT_CHECK := 0.25
var _lit_check := 0.0
var _lit_stretched := {}  # nightmare instance id -> _anim_time its stretched Hold ends

func _update_lit_holds(delta: float) -> void:
	_lit_check -= delta
	if _lit_check > 0.0:
		return
	_lit_check = LIT_CHECK
	var roots := kin_share(&"lantern_roots", "a")
	for enemy in get_enemies_in_range():
		var s: EnemyStatuses = enemy.statuses
		# Lantern Roots: a nightmare stepping onto a lit tile is held a moment (once each).
		if roots > 0.0 and not s.is_held() and _lit_cells.has(enemy.get_current_cell()) \
				and not enemy.has_meta(&"lantern_held") and not Reactions.cant_be_held(enemy):
			enemy.set_meta(&"lantern_held", true)
			if _kin_roll(roots):
				hold(enemy, LANTERN_ROOTS_HOLD)
				_kin_fired(&"lantern_roots")
			continue
		if not s.is_held() or not _lit_cells.has(enemy.get_current_cell()):
			continue
		var id: int = enemy.get_instance_id()
		if _lit_stretched.get(id, -1.0) >= _anim_time:
			continue  # This Hold was already stretched
		var longer := s.time_left(EnemyStatuses.HELD) * attack_data.lit_hold_multiplier
		SupportLog.credit(self, &"held_seconds", longer - s.time_left(EnemyStatuses.HELD))
		s.apply(EnemyStatuses.HELD, 1, longer)
		_lit_stretched[id] = _anim_time + longer
	if _lit_stretched.size() > 256:
		_lit_stretched.clear()

# Rootling: every pulse_hold_every-th pulse Holds the nightmare furthest along (not ones that can't be held).
func _pulse_hold(in_range: Array) -> void:
	var furthest: Node2D = null
	for enemy in in_range:
		if is_instance_valid(enemy) and not enemy.is_cleansed and not Reactions.cant_be_held(enemy) \
				and (furthest == null or enemy.get_remaining_distance() < furthest.get_remaining_distance()):
			furthest = enemy
	if furthest:
		hold(furthest, attack_data.pulse_hold_time)

# Heavy Air (card, rule heavy_air): slows that aren't statuses (Rockslide's rubble, Drown's pull-under)
# are 20% stronger too; Drowsy gets it in DreamState.get_status_strength_multiplier (fog no longer slows).
func get_slow_multiplier() -> float:
	return 1.0 + DreamState.HEAVY_AIR_BONUS if _rule_stacks(&"heavy_air") > 0 else 1.0

# Root Network (card, rule root_network): Sprouts touching side by side (II: diagonally too) glow along
# their shared edges. Each Sprout draws its half of every link, so a pair reads as one glowing root.
const ROOT_GLOW := Palette.NEWLEAF

func _refresh_root_links() -> void:
	var links: Array[Vector2] = []
	if tower_data.get_id() == "sprout" and _dream_state and _has_rule(&"root_network"):
		var diagonals := _rule_level(&"root_network") > 0
		for other in _other_towers():
			if other.tower_data.get_id() != "sprout":
				continue
			var d: Vector2 = other.cell - cell
			var side := absf(d.x) + absf(d.y) == 1.0
			var corner := absf(d.x) == 1.0 and absf(d.y) == 1.0
			if side or (diagonals and corner):
				links.append(d)
	if links != _root_links:
		_root_links = links
		_redraw_root_network()

# The links are drawn once per pair by the board's RootNetworkOverlay (a vertical pair drawn here, under
# the Sprouts' own sprites, was hidden).
func _redraw_root_network() -> void:
	if not is_inside_tree():
		return
	var overlay := RootNetworkOverlay.find(get_parent())
	if overlay:
		overlay.queue_redraw()

# Badges in one column up the tile's left edge, clear of the rank pips along the bottom (so nothing
# stacks on top of anything else): a leaf pair when the Warden is in a Kinship (always shown, tinted
# with its family), then one rarity-coloured diamond per active position card (in build mode or while
# Wardens are selected). Tapping the Warden opens its panel, which names them.
func _draw_badges() -> void:
	var items: Array = []
	if is_instance_valid(_kin) and not _kin.get_pairs(self).is_empty():
		items.append(["kin", _kin.get_pair(self)])
	if badges_visible():
		for row in _badge_cards:
			items.append(["card", row])
	var x := -MAP_GRID.cell_size.x / 2.0 + 7.0
	var y := MAP_GRID.cell_size.y / 2.0 - 8.0
	for item in items:
		var at := Vector2(x, y)
		if item[0] == "kin":
			var colour: Color = Kinships.FAMILY_COLORS.get(tower_data.line, Palette.NEWLEAF)
			var leaf := Fx.texture(&"kin_leaf_icon")
			if leaf:
				draw_texture_rect(leaf, Rect2(at - Vector2(7, 7), Vector2(14, 14)), false, colour)
			else:
				for side in [-1.0, 1.0]:
					draw_colored_polygon(PackedVector2Array([at, at + Vector2(3 * side, -6), at + Vector2(6 * side, -1)]), colour)
		else:
			var row: Dictionary = item[1]
			var rarity: int = row.card.rarity if row.get("card") != null else 0
			var colour: Color = BADGE_COLORS[clampi(rarity, 0, BADGE_COLORS.size() - 1)]
			var diamond := PackedVector2Array([at + Vector2(0, -5), at + Vector2(5, 0), at + Vector2(0, 5), at + Vector2(-5, 0)])
			draw_colored_polygon(diamond, colour)
			draw_polyline(diamond + PackedVector2Array([diamond[0]]), Color(Palette.ROOT, 0.8), 1.0)
		y -= 13.0

# Small warm pips along the bottom of the tile, one per Nurture rank, with the Focus icon after them.
# Drawn on a child so they sit over the sprite.
func _draw_rank_pips() -> void:
	var pips := get_node_or_null("RankPips") as Node2D
	if rank <= 0:
		if pips:
			pips.queue_redraw()
		return
	if pips == null:
		pips = Node2D.new()
		pips.name = "RankPips"
		pips.z_index = 1
		pips.draw.connect(func() -> void:
			if rank <= 0:
				return
			# Nurture v3: one pip per rank, each its choice's glyph (shape and colour).
			_migrate_choices()
			var step := 9.0 if rank <= 5 else 7.5
			var left := -(rank - 1) * step / 2.0
			for i in rank:
				draw_focus_icon(pips, Vector2(left + i * step, 27.0), rank_choices[i] as Focus, 0.8))
		add_child(pips)
	pips.queue_redraw()

# A tiny Focus glyph: Power an upward flame, Swift a double chevron, Reach a ring, Deep a drop.
# Shared with the Warden panel.
static func draw_focus_icon(canvas: CanvasItem, at: Vector2, which: Focus, size: float = 1.0) -> void:
	var color: Color = FOCUS_COLORS.get(which, Palette.HEARTLIGHT)
	var dark := Color(Palette.ROOT, 0.9)
	canvas.draw_circle(at, 4.6 * size, dark)
	match which:
		Focus.POWER:
			var flame := PackedVector2Array([at + Vector2(0, -3.5) * size, at + Vector2(3, 2.5) * size,
				at + Vector2(-3, 2.5) * size])
			canvas.draw_colored_polygon(flame, color)
		Focus.SWIFT:
			for dx in [-1.5, 1.5]:
				canvas.draw_polyline(PackedVector2Array([at + Vector2(dx - 1.5, -2.5) * size,
					at + Vector2(dx + 1.0, 0) * size, at + Vector2(dx - 1.5, 2.5) * size]), color, 1.2 * size)
		Focus.REACH:
			canvas.draw_arc(at, 2.8 * size, 0.0, TAU, 12, color, 1.3 * size)
			canvas.draw_circle(at, 0.9 * size, color)
		Focus.DEEP:
			canvas.draw_circle(at + Vector2(0, 1) * size, 2.3 * size, color)
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -3.5) * size,
				at + Vector2(2.1, 0.3) * size, at + Vector2(-2.1, 0.3) * size]), color)

# Attack reach in pixels.
func get_range_pixels() -> float:
	return range_to_pixels(get_range_cells())

# Targeting (screens_ui.md "Targeting"): the four modes the player picks from, in the switch's order.
const PLAYER_TARGET_MODES: Array[TowerData.TargetMode] = [TowerData.TargetMode.FIRST, TowerData.TargetMode.LAST,
	TowerData.TargetMode.STRONGEST, TowerData.TargetMode.CLOSEST]
const TARGET_MODE_NAMES := {TowerData.TargetMode.FIRST: "First", TowerData.TargetMode.STRONGEST: "Strongest",
	TowerData.TargetMode.CLOSEST: "Closest", TowerData.TargetMode.BOSSES: "Bosses",
	TowerData.TargetMode.FASTEST: "Fastest", TowerData.TargetMode.LAST: "Last"}
# Attacks that don't pick a target: pulses, auras, traps / rings, spins, patrols and lit tiles.
const UNTARGETED_KINDS := [TowerData.AttackKind.PULSE, TowerData.AttackKind.AURA, TowerData.AttackKind.TRAP,
	TowerData.AttackKind.SPIN, TowerData.AttackKind.PATROL, TowerData.AttackKind.LIGHT]

# The mode this Warden aims with: the player's choice, else its data's (Wren's Nest: fastest).
func get_target_mode() -> TowerData.TargetMode:
	return target_mode if target_chosen else attack_data.target_mode

# Whether the Targeting switch shows for this Warden (Thornwalls and untargeted attacks: no).
func can_choose_target() -> bool:
	return tower_data.can_attack and attack_data != null and not UNTARGETED_KINDS.has(attack_data.attack_kind)

func set_target_mode(mode: TowerData.TargetMode) -> void:
	target_mode = mode
	target_chosen = true
	queue_redraw()

# T: First -> Last -> Strongest -> Closest -> First.
func cycle_target_mode() -> void:
	var index := PLAYER_TARGET_MODES.find(get_target_mode())
	set_target_mode(PLAYER_TARGET_MODES[(index + 1) % PLAYER_TARGET_MODES.size()])

# A tiny pip at the tile's top-right while selected: an arrow (First), a back-pointing arrow (Last), a
# filled diamond (Strongest) or a ring (Closest).
func _draw_target_pip() -> void:
	if not (is_selected and can_choose_target()):
		return
	var at := Vector2(MAP_GRID.cell_size.x / 2.0 - 8.0, -MAP_GRID.cell_size.y / 2.0 + 8.0)
	draw_circle(at, 6.0, Color(Palette.ROOT, 0.85))
	var ink := Palette.HEARTLIGHT
	match get_target_mode():
		TowerData.TargetMode.STRONGEST:
			draw_colored_polygon(PackedVector2Array([at + Vector2(0, -3.5), at + Vector2(3.5, 0), at + Vector2(0, 3.5), at + Vector2(-3.5, 0)]), ink)
		TowerData.TargetMode.CLOSEST:
			draw_arc(at, 3.0, 0.0, TAU, 12, ink, 1.5)
		TowerData.TargetMode.LAST:
			draw_colored_polygon(PackedVector2Array([at + Vector2(2.5, -3.5), at + Vector2(-3.5, 0), at + Vector2(2.5, 3.5)]), ink)
		_:
			draw_colored_polygon(PackedVector2Array([at + Vector2(-2.5, -3.5), at + Vector2(3.5, 0), at + Vector2(-2.5, 3.5)]), ink)

# The nightmare in range this Warden should attack, or null. Most Wardens pick the one furthest
# along the path; snipers let the player choose, and Wren's Nest hunts the fastest.
func find_target() -> Node2D:
	var mode := get_target_mode()
	if kin_share(&"flock_together", "b") > 0.0:
		mode = TowerData.TargetMode.FASTEST  # Flock Together: hunts the fastest nightmare
	var best: Node2D = null
	var best_score := -INF
	for enemy in get_enemies_in_range():
		var score := _target_score(enemy, mode)
		if score > best_score:
			best_score = score
			best = enemy
	return best

# How much this Warden wants to shoot `enemy` under `mode` (higher = sooner).
func _target_score(enemy: Node2D, mode: TowerData.TargetMode) -> float:
	match mode:
		TowerData.TargetMode.STRONGEST:
			return enemy.health
		TowerData.TargetMode.BOSSES:
			return -enemy.get_remaining_distance() + (1e9 if enemy.enemy_data.is_boss else 0.0)
		TowerData.TargetMode.FASTEST:
			return enemy.get_move_speed()
		TowerData.TargetMode.CLOSEST:
			return -global_position.distance_squared_to(enemy.global_position)
		TowerData.TargetMode.LAST:
			return enemy.get_remaining_distance()  # The newest arrival: the most path left
	return -enemy.get_remaining_distance()

# Blighted enemies within attack range (and outside a sniper's minimum range).
func get_enemies_in_range() -> Array[Node2D]:
	var range_squared := get_range_pixels() ** 2
	# Skyward Gaze (card, rule skyward_gaze): flying nightmares count from further away.
	var sky_squared := range_squared
	if _rule_stacks(&"skyward_gaze") > 0:
		sky_squared = range_to_pixels(get_range_cells() + DreamState.SKYWARD_RANGE) ** 2
	var min_squared := (attack_data.min_range * MAP_GRID.cell_size.x) ** 2
	# Performance: _has_work, find_target and the attack each asked for this in one frame, each building
	# the group array again. One list of nightmares per frame is shared, and this Warden's answer is
	# kept for the frame (nightmares dispelled since are dropped on the way out).
	var frame := Engine.get_process_frames()
	_nightmares_this_frame(get_tree())  # Refreshes the shared list first if nightmares came or went
	if frame == _in_range_frame and _in_range_key == Vector3(range_squared, sky_squared, min_squared) \
			and _in_range_count == _nightmares.size():
		var kept: Array[Node2D] = []  # A plain loop: filter() with a lambda cost more than the scan (perf probe)
		for e in _in_range:
			if is_instance_valid(e) and not e.is_cleansed:
				kept.append(e)
		return kept
	var result: Array[Node2D] = []
	var reach := sqrt(maxf(range_squared, sky_squared))
	for bucket in _buckets_near(global_position, reach):  # The buckets themselves: no merged array built
		for enemy in bucket:
			if not is_instance_valid(enemy) or enemy.is_cleansed:
				continue
			var distance_squared := global_position.distance_squared_to(enemy.global_position)
			var flying: bool = enemy.enemy_data != null and enemy.enemy_data.trait_kind == EnemyData.Trait.FLYING
			if distance_squared <= (sky_squared if flying else range_squared) and distance_squared >= min_squared:
				result.append(enemy)
	_in_range_frame = frame
	_in_range_key = Vector3(range_squared, sky_squared, min_squared)
	_in_range_count = _nightmares.size()
	_in_range = result
	return result.duplicate()

var _in_range_frame := -1
var _in_range_key := Vector3.ZERO
var _in_range_count := -1  # How many nightmares there were when it was worked out
var _in_range: Array[Node2D] = []
static var _nightmares_frame := -1
static var _nightmares: Array = []

# The targetable nightmares, fetched once per frame for every Warden, and bucketed by BUCKET-pixel
# squares so a Warden only looks at the ones near it (the buckets either side of its own always reach
# at least BUCKET px past it, and a nightmare moves only a few px within a frame).
const BUCKET := 192.0
static var _buckets := {}

static func _nightmares_this_frame(tree: SceneTree) -> Array:
	var frame := Engine.get_process_frames()
	if frame != _nightmares_frame or tree.get_node_count_in_group(ENEMY_GROUP) != _nightmares.size():
		_nightmares_frame = frame
		_nightmares = tree.get_nodes_in_group(ENEMY_GROUP)
		_buckets = {}
		for enemy in _nightmares:
			var key := Vector2i((enemy.global_position / BUCKET).floor())
			if _buckets.has(key):
				_buckets[key].append(enemy)
			else:
				_buckets[key] = [enemy]
	return _nightmares

func _nightmares_near(at: Vector2, reach: float) -> Array:
	return nightmares_near(get_tree(), at, reach)

# The nightmares whose bucket is within `reach` px of `at` (a superset: callers check the distance and
# is_cleansed). Also used by Reactions (Thunderclap arcs, neighbours).
# The shared list holds nightmare nodes; left in a static at exit it crashed the engine's teardown about
# one run in seven (test_late_game, signal 11 after PASS). Any Warden leaving the tree drops it (it's
# rebuilt on the next query), so it's always empty by the time the scene is freed.
func _exit_tree() -> void:
	_nightmares = []
	_buckets = {}
	_nightmares_frame = -1
	_tower_buckets = {}  # Wardens too (a static list of nodes at exit crashed the teardown)
	_tower_key = []
	if not _root_links.is_empty() and get_parent() and get_parent().owner:
		var overlay := get_parent().owner.get_node_or_null("RootNetworkOverlay")
		if overlay:
			overlay.queue_redraw()  # Its roots go with it (never made here: this may be the exit teardown)

static func nightmares_near(tree: SceneTree, at: Vector2, reach: float) -> Array:
	_nightmares_this_frame(tree)
	var r := int(ceil(reach / BUCKET))  # A bucket either side reaches at least BUCKET px past this one
	var centre := Vector2i((at / BUCKET).floor())
	var out: Array = []
	if (2 * r + 1) * (2 * r + 1) >= _buckets.size():
		for key: Vector2i in _buckets:  # Fewer occupied buckets than squares: walk those (not every nightmare)
			if absi(key.x - centre.x) <= r and absi(key.y - centre.y) <= r:
				out.append_array(_buckets[key])
		return out
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var bucket = _buckets.get(centre + Vector2i(dx, dy))
			if bucket != null:
				out.append_array(bucket)
	return out

# Converts a range in cells to pixels. Shared with the build-mode ghost preview.
static func range_to_pixels(range_cells: float) -> float:
	return range_cells * MAP_GRID.cell_size.x

# Draws a simple stone block centred on the origin. Shared with the build-mode ghost preview.
static func draw_placeholder(canvas: CanvasItem, color: Color) -> void:
	var block := Rect2(-24, -24, 48, 48)
	canvas.draw_rect(block, color.darkened(0.45))
	canvas.draw_rect(block.grow(-4), color)
	canvas.draw_circle(Vector2.ZERO, 10, color.lightened(0.35))

# --- Cached Dream bonuses (performance: platforms.md "Performance budget") ---------------------------
# DreamState's per-Warden card rows (position cards: Solitude, Crowded Path, Heart of the Maze, …) look
# at the whole board, and every stat read and badge poll asked again: with ~200 Wardens that was ~70 ms
# a frame. One DreamEffects.rows() pass now gives the damage / speed / range bonuses and the badge cards
# together; it's dropped when a card is taken, the maze changes or the Warden grows or ranks up, and
# redone every DREAM_CACHE_TIME for cards that change with the field (staggered across Wardens).
const DREAM_CACHE_TIME := 1.0  # Only for cards that follow the live field (Crowded Path); the board version covers the rest
var _dream_cache_board := -1
var _dream_cache := {}
var _dream_cache_left := 0.0

func _dream_bonus(key: StringName) -> float:
	if _dream_state == null:
		return 1.0 if key == &"soothe" else 0.0
	if _dream_cache.is_empty() or ("board_version" in _dream_state and _dream_state.board_version != _dream_cache_board):
		_refresh_dream_rows()
	return _dream_cache.get(key, 1.0 if key == &"soothe" else 0.0)

# The one pass: bonuses as DreamState.get_soothe_multiplier / get_tower_attack_speed_bonus /
# get_tower_range_bonus give them (active, non-plain rows), badges = active positional rows.
func _refresh_dream_rows() -> void:
	if _dream_state == null or not _dream_state.has_method("effects"):
		_dream_cache = {&"soothe": 1.0, &"speed": 0.0, &"range": 0.0}
		return
	var damage := 0.0
	var speed := 0.0
	var reach := 0.0
	var cards := []
	# Roguelite's rows_cached: one Board per DreamState.board_version, live-field cards recomputed.
	var rows: Array = _dream_state.effects().rows_cached(self) if _dream_state.effects().has_method("rows_cached") \
		else _dream_state.effects().rows(DreamEffects.spot_for(self))
	_dream_cache_board = _dream_state.board_version if "board_version" in _dream_state else -1
	for row in rows:
		if not row.active:
			continue
		if not row.plain:
			damage += row.get("damage", 0.0)
			speed += row.get("speed", 0.0)
			reach += row.get("range", 0.0)
		if row.get("positional", false):
			cards.append(row)
	var stat: float = _dream_state.get_stat_bonus(tower_data, "soothe_bonus") if _dream_state.has_method("get_stat_bonus") \
		else _dream_state._sum_stat(tower_data, "soothe_bonus")
	_dream_cache = {&"soothe": 1.0 + stat + damage,
		&"speed": speed, &"range": reach}
	if cards.size() != _badge_cards.size():
		queue_redraw()
	_badge_cards = cards

func clear_dream_cache() -> void:
	_dream_cache.clear()
	_range_frame = -1
	_stats_key = []

# A Warden planted, sold or grown: Dream rows and neighbours (auras, copies, Root Network) look again
# soon, spread over the next few frames rather than all at once.
# This Warden grew or ranked up: its neighbours' auras and copies look again soon (spread out).
const NUDGE_SPREAD := 0.3  # Seconds a nudge spreads the neighbours' looks over
const NUDGE_SELF_SPREAD := 0.1  # …and the nudged Warden's own look

func _nudge_neighbours() -> void:
	if _neighbour_timer > NUDGE_SELF_SPREAD:  # Soon, but spread: a group grow / Nurture ranks many at once
		_neighbour_timer = randf_range(0.0, NUDGE_SELF_SPREAD)
	if not is_inside_tree():
		return
	for other in _other_towers():
		# Only reschedule ones not already due within the spread: taking the min of many random draws
		# (group Nurture nudges every Warden 200 times) lands them all at ~0, in the same frame.
		if other._neighbour_timer > NUDGE_SPREAD:
			other._neighbour_timer = randf_range(0.0, NUDGE_SPREAD)

func _on_map_changed() -> void:
	_dream_cache.clear()
	_range_frame = -1
	_neighbour_timer = minf(_neighbour_timer, randf_range(0.0, 0.3))

func _tick_dream_cache(delta: float) -> void:
	_dream_cache_left -= delta
	if _dream_cache_left <= 0.0:
		_dream_cache.clear()  # Rebuilt on the next stat read
		_dream_cache_left = DREAM_CACHE_TIME * randf_range(0.75, 1.25)  # Spread the refreshes over frames

# A nightmare was dispelled (FinalTwists: Hoarfrost's Shatter chain, the Great Dreamcatcher's Mended leaves).
func _twist_dispelled(enemy: Node2D) -> void:
	FinalTwists.dispelled(self, enemy)

# Lullaby Bell's pulse went off (FinalTwists: Chorus notes).
func _twist_released(_tower: Tower) -> void:
	if _chorus > 0.0:
		FinalTwists._chorus_notes(self)

# How many of `stacks` Drowsy a wall may add to `enemy` (warden_stats.md, Honeysuckle: walls cap at
# WALL_DROWSY_CAP). 0 still refreshes its timer.
func _wall_drowsy_room(enemy: Node2D, stacks: int) -> int:
	return clampi(WALL_DROWSY_CAP - enemy.statuses.stacks(EnemyStatuses.DROWSY), 0, stacks)

# The nightmare buckets within `reach` px of `at` ([[nightmares], …]; the whole list as one bucket for a
# long reach). Callers check the distance and is_cleansed. Perf probe (stacked drifts): walking the
# buckets in place is cheaper than merging them into a new array per query.
func _buckets_near(at: Vector2, reach: float) -> Array:
	_nightmares_this_frame(get_tree())
	var r := int(ceil(reach / BUCKET))
	var centre := Vector2i((at / BUCKET).floor())
	var out: Array = []
	if (2 * r + 1) * (2 * r + 1) >= _buckets.size():
		# Fewer occupied buckets than squares in reach: walk those and keep the ones in reach (perf probe:
		# returning every nightmare here made every Warden scan the whole crowd at the start).
		for key: Vector2i in _buckets:
			if absi(key.x - centre.x) <= r and absi(key.y - centre.y) <= r:
				out.append(_buckets[key])
		return out
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var bucket = _buckets.get(centre + Vector2i(dx, dy))
			if bucket != null:
				out.append(bucket)
	return out

# Whether any nightmare is in range: stops at the first (_has_work and Watchful Rest only need yes / no).
func has_enemy_in_range() -> bool:
	var range_squared := get_range_pixels() ** 2
	var sky_squared := range_squared
	if _rule_stacks(&"skyward_gaze") > 0:
		sky_squared = range_to_pixels(get_range_cells() + DreamState.SKYWARD_RANGE) ** 2
	var min_squared := (attack_data.min_range * MAP_GRID.cell_size.x) ** 2
	for bucket in _buckets_near(global_position, sqrt(maxf(range_squared, sky_squared))):
		for enemy in bucket:
			if not is_instance_valid(enemy) or enemy.is_cleansed:
				continue
			var distance_squared := global_position.distance_squared_to(enemy.global_position)
			var flying: bool = enemy.enemy_data != null and enemy.enemy_data.trait_kind == EnemyData.Trait.FLYING
			if distance_squared <= (sky_squared if flying else range_squared) and distance_squared >= min_squared:
				return true
	return false
