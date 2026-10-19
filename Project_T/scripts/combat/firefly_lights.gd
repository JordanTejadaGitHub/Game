extends Node2D
# Firefly Jar class prototype (documentation/dream_council_review.md section 20; the spec is
# D:\Projects\logs\dream_council\v4_sporeling_firefly.md sections 0 and 11-20; owner direction 2026-10-12).
#
# The family's thing: "damage spreads to other nightmares". The word on the cards is FORK: a damage-only strike that
# adds no status and that nothing triggers from (tag FORK_TAG: every hook here ignores its own forks).
#   Glow       the path within GLOW_CELLS of a Firefly Warden (any light-line form)
#   Lit        a nightmare standing in any glow, flyers too; Lit nightmares can't hide
#   A light    one Firefly Warden's glow; glows sharing a path cell are one light; a lit Sprout is its own light
#   Gold path  path inside two or more Firefly Wardens' glows
# One node per run, made by DreamState (group GROUP). It listens to DamageLog.damage_dealt, so no Warden or nightmare
# code calls it. Forks are queued and struck at the end of the frame: one per nightmare per event (the largest wins),
# at most EVENT_MAX per event, bosses take half. No class_name: DreamState preloads this file.
#
# Every number is a starting point from Balancing's queue. They all live here.

const GROUP := &"firefly_lights"
const FAMILY := "firefly_jar"  # DreamState.calling on a Firefly start
const LINE := "light"  # A Firefly Warden: any form of this line
const FORK_TAG := &"fork"

const GLOW_CELLS := 1.5  # Glow: path within this many cells of a Firefly Warden, plus the range it gained (owner 2026-10-16: lighting was too easy; was 3 / the whole range)
const GLOW_BASE_RANGE := 3.0  # …a Firefly Warden's range beyond this (the Firefly Jar's) adds to its glow
const SPROUT_TOUCH := 1.25  # A lit Sprout's light: the path touching it (the path rule, both axes)
const NEAR_CELLS := 2.0  # "near": within 2 cells on both axes (lent cards)
const CALLING_SHARE := 0.5  # Lantern Light: half the dispelling Warden's hit
const BRIGHTNESS_SECONDS := 3.0  # Another family's fork is capped at this many seconds of the lighting Firefly Warden
const BOSS_SHARE := 0.5  # Bosses take half of any fork
const EVENT_MAX := 6  # Forks one event can throw
const MEET_MAX := 4  # Where Lights Meet: one fork per Firefly Warden lighting the gold path, up to this
const CHAIN_TARGETS := 2  # Chain of Lanterns
const CHAIN_SHARE := 0.5
const HAMMER_SHARE := 0.5  # Hammerfall
const SPOTLIGHT_SHARE := 0.25  # Spotlight
const SPOTLIGHT_MAX := 6
const NEXT_LIGHT_STEPS := 8  # The next light ahead is at most this many steps along the path
const SIGNAL_SHARE := 0.5  # Signal Fires
const SIGNAL_EVERY := 1.0  # ...once for each light each second
const LANTERNWAY_LIGHTS := 3  # Lanternway
const LANTERNWAY_SHARE := 0.5
const AMBUSH_SHARE := 0.5  # Ambush
const SPARK_MAX := 3  # Waiting Spark: sparks that can wait in one light
const SPARK_TIME := 5.0
const LIVE_WIRE_SHARE := 0.5  # Nothing Wasted's Live Wire part: half the hit, per dispel (owner 2026-10-13: never more than the Calling)
const CROSSFIRE_WINDOW := 1.0  # Lent
const CROSSFIRE_TARGETS := 2
const CROSSFIRE_SHARE := 0.5
const CROSSFIRE_WAIT := 3.0
const LIKE_SHARE := 0.5  # Lent: Like to Like
const LIKE_TICK_EVERY := 1.0  # ...ticks and clouds fork once a second per nightmare
const HEAVY_ATTACK_SHARE := 0.8  # A heavy Warden's next hit counts as a new attack after this share of its attack time

# Rule ids of the class cards (UpgradeData.calling = FAMILY) and the lent cards.
const WHERE_LIGHTS_MEET := &"where_lights_meet"
const CHAIN_OF_LANTERNS := &"chain_of_lanterns"
const LAST_SPARK := &"last_spark"
const HAMMERFALL := &"hammerfall"
const KNOCK_ON := &"knock_on"
const SPOTLIGHT := &"spotlight"
const LIT_SPROUTS := &"lit_sprouts"  # Fireflies in the Grass
const SIGNAL_FIRES := &"signal_fires"
const LANTERNWAY := &"lanternway"
const NOTHING_WASTED := &"nothing_wasted"
const AMBUSH := &"ambush"
const WAITING_SPARK := &"waiting_spark"
const LENT_LIVE_WIRE := &"lent_live_wire"
const LENT_CROSSFIRE := &"lent_crossfire"
const LIKE_TO_LIKE := &"like_to_like"
# Lent, 2026-10-14 (lent_noplace_sporeling_firefly.md with dream_council_review.md 26's fixes)
const SPARKS_FLY := &"sparks_fly"
const SPARKS_EVERY_HIT := 3  # Sparks Fly: every 3rd hit a Warden lands on a nightmare…
const SPARKS_WINDOW := 2.0  # …a Firefly Warden hit in the last 2 s…
const SPARKS_SHARE := 0.5  # …jumps on at half
const STRUCK_TWICE := &"struck_twice"  # Struck Twice (self-sufficiency audit 2026-10-18): a jump landing readies the next hit…
const STRUCK_BONUS := 1.3  # …from a Firefly Warden or a Warden near one: 30% more…
const STRUCK_TIME := 2.0  # …for 2 s; one waiting hit per nightmare
const STRUCK_META := &"ff_struck"  # On a nightmare: [time, frame, the jump's source id, WeakRef spark]
const FLASHOVER := &"flashover"
const FLASHOVER_SHARE := 0.5  # Flashover: an area attack on 2+ nightmares jumps half to the nearest one it missed
const FLASHOVER_MIN := 2
const SPARKLERS := ["sparkler", "starburst"]  # Firefly area forms: they count for Flashover beside another Firefly Warden
const THUNDERSTRUCK := &"thunderstruck"
const THUNDER_SHARE := 0.25  # Thunderstruck: a heavy hit on a nightmare with a status fans a quarter to the ones near it with a status…
const THUNDER_MAX := 4  # …up to this many…
const THUNDER_STATIC := 1  # Thunderstruck: each jump adds this many Charged, from the Firefly Warden
const THUNDER_CAP_SECONDS := 1.5  # …the whole fan at most this many seconds of the Firefly Warden near the heavy one
const CHAIN_EVERY := 1.0  # Chain of Lanterns: each Firefly Warden's Reactions jump once a second
const CHAIN_META := &"ff_chain_next"  # On a Firefly Warden
const CLASS_KIT := preload("res://scripts/combat/class_kit.gd")  # The shared Reaction list (REACTION_BURSTS)
const SETUP := preload("res://scripts/run/setup_credit.gd")  # Setup credit 2026-10-16: the stack ledger; "credit" on a jump request = its own damage
const BRUSHFIRE := &"brushfire"
const BRUSH_SHARE := 0.5  # Brushfire: half the damage over time of a nightmare a Firefly Warden hit in the last 2 s, each second
const BRUSH_EVERY := 1.0
const BRUSH_TAGS: Array[StringName] = [&"spored", &"cloud", &"fog"]  # Damage over time (not bolts, Reactions or jumps)
const GATHERING_STORM := &"gathering_storm"
const GATHER_STEP := 0.25  # Gathering Storm: each jump a nightmare takes makes the next 25% stronger…
const GATHER_MAX := 3.0  # …up to +200% (owner, hard cards 2026-10-16); the jump's cap stretches with it, never past 3x…
const GATHER_RESET := 2.0  # …reset after 2 s without one
const GATHER_WIDTH_STEP := 1.0  # …each stack draws the jump 1 px thicker…
const GATHER_WIDTH_MAX := 4  # …for at most this many stacks
const CHAIN_REACTIONS: Array[StringName] = [&"thunderclap", &"ignite", &"lightning_rod", &"tempest", &"night_terror"]  # Reactions that spend Charged (Night Terror: 2026-10-17)
const SPARKS_META := &"ff_sparks"  # On a nightmare: {Warden id: hits counted}
const FF_HIT_META := &"ff_firefly_hit"  # On a nightmare: [time, WeakRef]: the last Firefly Warden hit (Sparks Fly)
const SPARKS_FRAME_META := &"ff_sparks_frame"  # On a Warden: the frame its last hit was counted (an area attack counts once)
const GATHER_META := &"ff_gather"  # On a nightmare: [jumps, last time] (Gathering Storm)
const GUIDING_LIGHT := &"guiding_light"  # A general card (needs Lanternmoth), reworked to fork: Firefly spreads damage, never statuses
const GUIDING_SHARE := 0.5
const GUIDING_CELLS: Array[float] = [1.0, 2.0]  # II

# --- Calling evolutions (scripts/combat/calling_paths.gd ids lf_*; council calling_evolution_*.md, owner 2026-10-16) ----
# Read with evo(id) (the Firefly start with that id on DreamState.calling_path). Every number is a paper starting value
# (Balancing). Each one shows itself (a bolt in its own colour, a thread, a coal, a flash) and credits its id
# (DreamState.note_card). Recursive jumps keep their event id and carry a hop counter ("hops", TD correction 3): no
# chain is ever longer than EVENT_MAX, and one event never strikes more than EVENT_MAX nightmares (_event_seen).
# Spread
const EVO_STRUNG := &"lf_strung_lights"
const STRING_STEPS := 4  # Strung Lights: gaps of at most this many path steps between lit steps are lit too
const EVO_TORCH := &"lf_torchbearers"
const RELAY_SHARE := 0.5  # Torchbearers: half the dispelling hit jumps to the nearest Lit nightmare further along the path
const EVO_BALE := &"lf_bale_fires"
const BALE_HOPS := 4  # Bale-fires: a Torchbearers jump that dispels jumps on to the next Lit nightmare ahead, up to this many more
const TORCH_STEPS := 8  # Torchbearers / Bale-fires (hard cards 2026-10-16): "further along" = at most this many steps ahead
const TORCH_CLAIM := 0.25  # …a nightmare just jumped to is skipped for this long, so the fire runs on ahead
const TORCH_CLAIM_META := &"lf_torch_claim"  # On a nightmare: the clock until which Torchbearers skips it
const EVO_GLOWWORMS := &"lf_glowworms"
const GLOW_SPROUTS_PER_JAR := 2  # Glowworms: Sprouts touching each Firefly Warden that glow (nearest the Heartwood first)
const GLOW_SPROUT_TOUCH := 1.25  # …"touching": within this many cells on both axes
const EVO_SWARM := &"lf_swarm_night"
const SWARM_AT := 6  # Swarm Night: while this many nightmares are Lit, every jump jumps once more… (10 before the smaller glow, 2026-10-16)
const SWARM_SHARE := 1.0  # …at this share of the jump
# Focus
const EVO_BONFIRE := &"lf_bonfire"
const GOLD_JUMPS := 2  # Bonfire: a dispel on gold path jumps to this many (never past MEET_MAX)
const BONFIRE_BONUS := 1.25  # Bonfire (self-sufficiency audit 2026-10-18): Firefly Wardens' hits on gold path deal 25% more
const STRUNG_PER_GLOW := 0.05  # Strung Lights (same audit): Firefly Wardens' hits deal 5% more per glow the nightmare entered…
const STRUNG_MAX := 0.25  # …up to +25%
const GLOWS_META := &"lf_glows_entered"  # On a nightmare: {light id: true}, the glows it has entered (Strung Lights)
const EVO_MOTH := &"lf_moth_to_flame"
const MOTH_EXPOSED := 2  # Moth to Flame: a jump landing on gold path adds this many Exposed (bosses half, at least 1)
const EVO_PYRE := &"lf_pyre"
const PYRE_HOPS := 3  # Pyre: a jump that dispels on gold path jumps again, same strength, up to this many times
const EVO_EMBERS := &"lf_embers"
const EMBER_SHARE := 0.5  # Embers: a dispel on gold path leaves this share of the dispelling hit…
const EMBER_TIME := 4.0  # …for this long…
const EMBER_REACH := 0.6  # …for the next nightmare within this many cells of its step
const EMBER_MAX := 8  # Embers (piles) on the map at once
const EVO_WITCHFIRE := &"lf_witchfire"
const HEARTH_JOIN := 2  # Witchfire: an ember within this many steps of a pile joins it…
const HEARTH_MAX := 3  # …up to this many embers in a pile…
const HEARTH_CELLS := 1.0  # …and the pile bursts on the nightmares within this many cells…
const HEARTH_TARGETS := 6  # …up to this many
# Support
const EVO_BORROWED := &"lf_borrowed_light"
const LAMP_SHARE := 0.33  # Borrowed Light: another Warden's hit on a Lit nightmare jumps this share (Sprouts count)…
const LAMP_EVERY := 1.0  # …once a second per Warden
const LAMP_META := &"lf_lamp_next"  # On a Warden
const EVO_SHOW := &"lf_show_the_way"
const SHOW_SHARE := 0.5  # Show the Way (owner 2026-10-17: Firefly's own trait, was +1 stack): a Borrowed Light jump jumps once more, this share of it, to another Lit nightmare
const EVO_WAKE := &"lf_lantern_wake"
const WAKE_STACKS := 1  # Lantern Wake: a jump carries this many of each status its nightmare had (onto statuses already there)…
const WAKE_STATUSES := 4  # …up to this many statuses
const EVO_SIGHT := &"lf_sightline"
const SIGHT_WARDENS := 3  # Sightline: this many different Wardens hitting one Lit nightmare…
const SIGHT_WINDOW := 2.0  # …within this long…
const SIGHT_SHARE := 0.25  # …each jump this share of its hit to the nearest other Lit nightmare…
const SIGHT_MAX := 4  # …from at most this many Wardens…
const SIGHT_LOCK := 4.0  # …then not on that nightmare for this long
const SIGHT_META := &"lf_sight"  # On a nightmare: {Warden id: [time, WeakRef, base]}
const SIGHT_NEXT_META := &"lf_sight_next"
const EVO_CONSTELLATION := &"lf_constellation"
const CONST_WARDENS := 3  # Constellation: jumps from this many different Wardens…
const CONST_WINDOW := 3.0  # …within this long make a nightmare fully Exposed…
const CONST_EVERY := 8.0  # …each nightmare once in this long…
const CONST_BOSS_SHARE := 0.5  # …bosses fill only this share
const CONST_META := &"lf_const"  # On a nightmare: {Warden id: [time, WeakRef]}
const CONST_NEXT_META := &"lf_const_next"
const EVENT_MEMORY := 512  # Events whose struck nightmares are remembered (recursive hops land a frame later)

const LIT_SPROUT_META := &"lit_sprout"  # On a Sprout the player chose to glow
const GROUPS_META := &"ff_lights"  # On a nightmare: the lights it stands in (Array of light ids)
const AMBUSH_META := &"ff_ambushed"  # On a nightmare: {light id: true}
const CROSS_META := &"ff_crossfire"  # On a nightmare: the last qualifying hit, for Crossfire
const LIKE_META := &"ff_like_next"  # On a nightmare: when its ticks may fork again (Like to Like)
const HEAVY_META := &"ff_heavy_next"  # On a Warden: when its next hit counts as a new attack

const POLL := 0.1  # Seconds between looks at who is Lit
const REBUILD := 0.5  # Seconds between rebuilds of the light map when nothing told us it changed

var dream_state: Node  # DreamState (untyped: DreamState preloads this script)
var _hooked := false
var _sources: Array = []  # [{tower, sprout: bool, light: int}]
var _glow := {}  # Route cell -> {jars: int, lights: Array}
var _max_lit_step := -1
var _board := -1
var _rebuild_in := 0.0
var _poll_in := 0.0
var _queue: Array = []  # Fork requests waiting for the end of the frame
var _event := 0
var _sparks := {}  # Light id -> Array of {amount, source, until, cap}
var _signal_next := {}  # Light id -> clock
var _base_jar_dps := 0.0
var forks_thrown := 0  # This run (tests and the owner's eye)
var _flashes := {}  # Flashover: Warden id -> {frame, source: WeakRef, hits: Array, base}: one attack's hits, struck next frame
var _brush := {}  # Brushfire: nightmare id -> {enemy: WeakRef, source: WeakRef, amount}: this second's damage over time
var _brush_in := BRUSH_EVERY
var _heavy_now := false  # This event is a new heavy attack (worked out once per event: _new_heavy_attack has a clock)
var saved_sprouts: Array = []  # From the run save (DreamState.load_save); applied once the Wardens are back
var _strung := {}  # Strung Lights: route cell -> the light ids lighting the gap it sits in
var _light_rep := {}  # Light id -> one source of it (a gap borrows it for brightness)
var _step_px := {}  # Route step -> map position (embers)
var _end_px := Vector2.ZERO  # The route's last step (the Heartwood): Glowworms pick the Sprouts nearest it
var _embers := {}  # Embers / Witchfire: route step -> {amount, cap, source: WeakRef, until, count}
var _lit_count := 0  # Nightmares Lit at the last poll (Swarm Night)
var _lit_by_step: Array = []  # [[step, nightmare], …] Lit walkers at the last poll, sorted by step (Torchbearers, hard cards 2026-10-16)
var _event_seen := {}  # Event id -> {nightmare id: true}: struck by it (EVENT_MAX across a recursive chain)

func _ready() -> void:
	add_to_group(GROUP)
	z_index = -1  # With the ground: the glow lies on the path, under Wardens and nightmares
	var jar: TowerData = load("res://resource/tower/firefly_jar.tres")
	if jar != null:
		_base_jar_dps = jar.damage * jar.attacks_per_second
	if dream_state != null and dream_state.get("drift_director") != null:
		dream_state.drift_director.rest_started.connect(_on_rest.unbind(4))

func _on_rest() -> void:
	_sparks.clear()  # Waiting sparks go out when a rest starts
	_embers.clear()  # So do embers (nothing waits through a rest)
	queue_redraw()

# --- Who this is on for -----------------------------------------------------------------------------------------

func class_on() -> bool:
	return dream_state != null and dream_state.calling == FAMILY

func _rule(id: StringName) -> bool:
	return dream_state != null and dream_state.has_rule(id)

# A Calling evolution on the path (DreamState.calling_path): the Firefly start only (as class_kit.evo).
func evo(id: StringName) -> bool:
	return class_on() and dream_state.has_evolution(id)

func _evolved() -> bool:
	return class_on() and not dream_state.calling_path.is_empty()

# Credit an effect to its evolution (DreamState.note_card: callouts and the rest report), as class_kit.credit.
func credit(id: StringName, at: Vector2 = Vector2.INF, source = null) -> void:  # source: the Warden (badge pop; visual feedback spec B5, owner 2026-10-18)
	if dream_state != null:
		dream_state.note_card(id, at, 1, source if is_instance_valid(source) and source is Node else null)

# A thin line between two points for a moment (as class_kit._line_fx).
func _line_fx(from: Vector2, to: Vector2, width: float, color: Color = Palette.HEARTLIGHT) -> void:
	var world := Reactions._world(self)
	if world != null and not from.is_equal_approx(to):
		world.add_child(ChainBolt.new(PackedVector2Array([from, to]), color, width))

# Nightmares Lit at the last look (Swarm Night's count; the Calling badge can show "Lit 7/10").
func lit_count() -> int:
	return _lit_count

# Lent cards never give the Calling's setup (owner 2026-10-14, dream_council_review.md 25-26): Lit, the glow, lights and
# gold path are the first pick's only. The lent cards work from Firefly Wardens, where Wardens stand, their attacks and
# Charged; they never read Lit (no sources_at, nearest_lit or is_lit in a lent path).
const LENT_RULES: Array[StringName] = [HAMMERFALL, KNOCK_ON, THUNDERSTRUCK, CHAIN_OF_LANTERNS, NOTHING_WASTED, LENT_CROSSFIRE,
	SPARKS_FLY, FLASHOVER, BRUSHFIRE, GATHERING_STORM, STRUCK_TWICE, LENT_LIVE_WIRE, LIKE_TO_LIKE]  # (Live Wire, Like to Like: retired; old saves)

func _lent_on() -> bool:
	for id in LENT_RULES:
		if _rule(id):
			return true
	return false

# Cards retired or moved to class-only that worked in the light when a later owner could hold them: an old save holding
# one keeps the lights on Continue (the "keep a retired card's effect" convention).
const LEGACY_LIT: Array[StringName] = [SPOTLIGHT, SIGNAL_FIRES]

# Whether the lights are worked out: the Firefly start (or an old save's legacy card).
func _lit_on() -> bool:
	if class_on():
		return true
	for id in LEGACY_LIT:
		if _rule(id):
			return true
	return false

func _cell() -> float:
	return Tower.MAP_GRID.cell_size.x

func _now() -> float:
	return dream_state._game_clock

static func is_firefly(tower) -> bool:
	return tower is Tower and tower.tower_data != null and tower.tower_data.line == LINE and tower.tower_data.can_attack

# "Another family's Warden": not this family, not a Sprout, not a wall.
static func is_other_family(tower) -> bool:
	return tower is Tower and tower.tower_data != null and tower.tower_data.can_attack and tower.tower_data.line != LINE \
		and tower.tower_data.line != "wall" and tower.tower_data.get_id() != "sprout"

# Any other attacking Warden: not this family, not a wall; Sprouts count.
static func is_other(tower) -> bool:
	return tower is Tower and tower.tower_data != null and tower.tower_data.can_attack and tower.tower_data.line != LINE \
		and tower.tower_data.line != "wall"

static func is_heavy(tower) -> bool:
	if not (tower is Tower) or tower.attack_data == null:
		return false
	return bool(tower.attack_data.get("heavy"))  # attack_data: a Graftling follows the form it copies

static func _living(enemy) -> bool:
	return is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and not enemy.is_cleansed and enemy.health > 0

# --- The light map ----------------------------------------------------------------------------------------------

# Perf (Enemy Code's probe6, 2026-10-17): the DamageLog dispatch per damage event cost ~0.15 ms a frame for each idle
# node, so it is connected only while a rule of this family is on (checked each frame from the cached rule map).
var _hooked_log: Object = null

# DreamState calls it when cards or the Calling change, so a hit in the same frame is heard.
func sync_hook() -> void:
	_sync_hook(_any_rule_on())

func _sync_hook(on: bool) -> void:
	var want: Object = DamageLog.instance if on else null
	if want == _hooked_log:
		return
	if _hooked_log != null and is_instance_valid(_hooked_log) and _hooked_log.damage_dealt.is_connected(_on_damage):
		_hooked_log.damage_dealt.disconnect(_on_damage)
	_hooked_log = want
	_hooked = want != null
	if want != null and not want.damage_dealt.is_connected(_on_damage):
		want.damage_dealt.connect(_on_damage)

func _process(delta: float) -> void:
	if dream_state == null:
		return
	_sync_hook(_any_rule_on())  # Listens to DamageLog only while this family's rules are on (perf)
	var on := _lit_on()
	if not on and not _lent_on():
		if not _sources.is_empty() or not _glow.is_empty():
			_sources.clear()
			_glow.clear()
			queue_redraw()
		_flush()  # Guiding Light forks on any start
		return
	_rebuild_in -= delta
	if _rebuild_in <= 0.0 or _board != int(dream_state.board_version):
		_rebuild()
	if on:
		_poll_in -= delta
		if _poll_in <= 0.0:
			_poll_in = POLL
			_poll()
	if not _flashes.is_empty():
		_flash_over()
	if not _brush.is_empty() and not get_tree().paused:
		_brush_in -= delta
		if _brush_in <= 0.0:
			_brush_in = BRUSH_EVERY
			_brush_fire()
	_flush()

func _towers() -> Array:
	return get_tree().get_nodes_in_group(Tower.GROUP).filter(_tower_ok)

func _tower_ok(tower) -> bool:
	return is_instance_valid(tower) and not tower.is_queued_for_deletion() and tower.tower_data != null

func _rebuild() -> void:
	_rebuild_in = REBUILD
	if not saved_sprouts.is_empty() and not _towers().is_empty():
		var cells := saved_sprouts
		saved_sprouts = []
		load_save(cells)
	_board = int(dream_state.board_version)
	_sources.clear()
	_glow.clear()
	_max_lit_step = -1
	_strung.clear()
	_light_rep.clear()
	var jars: Array = []
	var sprouts: Array = []
	var plain_sprouts: Array = []  # Glowworms' candidates
	for tower in _towers():
		if is_firefly(tower):
			jars.append(tower)
		elif tower.tower_data.get_id() == "sprout" and tower.get_meta(LIT_SPROUT_META, false):
			sprouts.append(tower)
		elif tower.tower_data.get_id() == "sprout":
			plain_sprouts.append(tower)
	if not _lit_on():
		for tower in jars:
			_sources.append({"tower": tower, "sprout": false, "light": _sources.size()})  # Lent cards only ask "near a Firefly Warden"
		return
	var allowed := jars.size() if _rule(LIT_SPROUTS) else 0
	while sprouts.size() > allowed:
		sprouts.pop_back().remove_meta(LIT_SPROUT_META)  # One glowing Sprout per Firefly Warden: a sold Jar frees the newest pick
	var touch := SPROUT_TOUCH * _cell()
	var parent: Array = []  # Union-find over the Jars: glows sharing a path cell are one light
	for i in jars.size():
		parent.append(i)
	var cells_of: Array = []
	var path: Dictionary = dream_state._path_index
	for i in jars.size():
		var mine: Array = []
		var reach := glow_reach(jars[i])
		for cell in path:
			if jars[i].global_position.distance_to(Tower.MAP_GRID.calculate_map_position(cell)) <= reach:
				mine.append(cell)
		cells_of.append(mine)
	var owner_of := {}  # Route cell -> the first Jar lighting it
	for i in jars.size():
		for cell in cells_of[i]:
			if owner_of.has(cell):
				var a := _find(parent, i)
				var b := _find(parent, int(owner_of[cell]))
				if a != b:
					parent[a] = b
			else:
				owner_of[cell] = i
	var names := {}  # Union-find root -> the light's stable id: the smallest cell code among its Jars
	for i in jars.size():
		var root := _find(parent, i)
		names[root] = mini(int(names.get(root, 1 << 30)), _cell_code(jars[i]))
	for i in jars.size():
		var light := int(names[_find(parent, i)])
		_sources.append({"tower": jars[i], "sprout": false, "light": light})
		for cell in cells_of[i]:
			_note(cell, light, true)
	_step_px.clear()
	var last_step := -1
	for cell in path:
		var s := int(path[cell])
		if not _step_px.has(s):
			_step_px[s] = Tower.MAP_GRID.calculate_map_position(cell)
		if s > last_step:
			last_step = s
			_end_px = Tower.MAP_GRID.calculate_map_position(cell)
	var worms := _glowworms(jars, plain_sprouts) if evo(EVO_GLOWWORMS) else []
	for j in sprouts.size() + worms.size():
		var worm := j >= sprouts.size()
		var sprout = worms[j - sprouts.size()] if worm else sprouts[j]
		var light := -1 - _cell_code(sprout)  # Always its own light (negative ids), and never gold path
		_sources.append({"tower": sprout, "sprout": true, "light": light, "worm": worm})
		for cell in path:
			var at: Vector2 = Tower.MAP_GRID.calculate_map_position(cell)
			if absf(at.x - sprout.global_position.x) <= touch and absf(at.y - sprout.global_position.y) <= touch:
				_note(cell, light, false)
	for source in _sources:
		if not _light_rep.has(source.light) or (_light_rep[source.light].sprout and not source.sprout):
			_light_rep[source.light] = source
	if evo(EVO_STRUNG):
		_string_lights(path)
	for cell in _glow:
		_max_lit_step = maxi(_max_lit_step, int(path.get(cell, -1)))
	queue_redraw()

# Glowworms: up to GLOW_SPROUTS_PER_JAR Sprouts touching each Firefly Warden glow by themselves, the ones nearest the
# Heartwood first (chosen automatically; TD fix 4: never "any number", so the lights stay bounded).
func _glowworms(jars: Array, candidates: Array) -> Array:
	var out: Array = []
	var reach := GLOW_SPROUT_TOUCH * _cell()
	for jar in jars:
		var near: Array = []
		for s in candidates:
			if not out.has(s) and absf(s.global_position.x - jar.global_position.x) <= reach \
					and absf(s.global_position.y - jar.global_position.y) <= reach:
				near.append(s)
		near.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(_end_px) < b.global_position.distance_squared_to(_end_px))
		out.append_array(near.slice(0, GLOW_SPROUTS_PER_JAR))
	return out

# Strung Lights: a gap of at most STRING_STEPS unlit steps between two lit steps is lit by both lights. The lights keep
# their own ids (Torchbearers and Bale-fires throw from light to light along the strung road), and a gap is never gold.
func _string_lights(path: Dictionary) -> void:
	var cells_at := {}  # Step -> its route cells
	for cell in path:
		(cells_at.get_or_add(int(path[cell]), []) as Array).append(cell)
	var lit_steps: Array = []
	for cell in _glow:
		var s := int(path.get(cell, -1))
		if s >= 0 and not lit_steps.has(s):
			lit_steps.append(s)
	lit_steps.sort()
	for k in range(1, lit_steps.size()):
		var a: int = lit_steps[k - 1]
		var b: int = lit_steps[k]
		if b - a - 1 < 1 or b - a > STRING_STEPS:
			continue  # Glows at most STRING_STEPS apart, as the text says (council full_review 2026-10-17)
		var lights: Array = []
		for s in [a, b]:
			for cell in cells_at.get(s, []):
				for light in (_glow[cell].lights if _glow.has(cell) else []):
					if not lights.has(light):
						lights.append(light)
		for s in range(a + 1, b):
			for cell in cells_at.get(s, []):
				_strung[cell] = lights
				for light in lights:
					_note(cell, light, false)  # Twice a second at most: the glow follows planting, selling, growing and new cards

# A Warden's cell as one number (half cells count): stable while it stands there.
func _cell_code(tower) -> int:
	return roundi(tower.cell.x * 2.0) * 1000 + roundi(tower.cell.y * 2.0)

func _find(parent: Array, i: int) -> int:
	while int(parent[i]) != i:
		i = int(parent[i])
	return i

func _note(cell: Vector2, light: int, jar: bool) -> void:
	var entry: Dictionary = _glow.get(cell, {"jars": 0, "lights": []})
	if jar:
		entry.jars += 1
	if not entry.lights.has(light):
		entry.lights.append(light)
	_glow[cell] = entry

# How far a Firefly Warden's glow reaches: GLOW_CELLS, plus every cell of range it has beyond a Firefly Jar's (ranks,
# forms and cards that add range grow it; owner 2026-10-14 "it doesn't grow when range grows"). Small on purpose
# (owner 2026-10-16): where you plant Fireflies decides what is Lit, so Strung Lights, Glowworms and Bonfire matter.
func glow_reach(tower) -> float:
	return (GLOW_CELLS + maxf(tower.get_range_cells() - GLOW_BASE_RANGE, 0.0)) * _cell()

# The sources lighting `at` (by distance, so flyers count).
func sources_at(at: Vector2) -> Array:
	var out: Array = []
	var touch := SPROUT_TOUCH * _cell()
	for source in _sources:
		var tower = source.tower
		if not is_instance_valid(tower):
			continue
		if source.sprout:
			if absf(at.x - tower.global_position.x) <= touch and absf(at.y - tower.global_position.y) <= touch:
				out.append(source)
		elif tower.global_position.distance_to(at) <= glow_reach(tower):
			out.append(source)
	return out

func is_lit(enemy) -> bool:
	return _lit_on() and is_instance_valid(enemy) and not _lit_sources(enemy).is_empty()

# The sources lighting a nightmare: by distance (sources_at), or, on a Strung Lights gap, one source of each light the
# gap joins (marked "gap": never gold path, never shows hidden nightmares). Every Lit question about a nightmare asks this.
func _lit_sources(enemy) -> Array:
	var out := sources_at(enemy.global_position)
	if out.is_empty() and not _strung.is_empty() and enemy.has_method("get_current_cell"):
		for light in _strung.get(enemy.get_current_cell(), []):
			var rep = _light_rep.get(light)
			if rep != null and is_instance_valid(rep.tower):
				var gap: Dictionary = rep.duplicate()
				gap["gap"] = true
				out.append(gap)
	return out

# Only a Firefly Warden's own light shows hidden nightmares (or an old save's chosen Sprout): never a Strung gap or a
# Glowworm (TD fix 4).
func _reveals(sources: Array) -> bool:
	for source in sources:
		if not source.get("gap", false) and not source.get("worm", false):
			return true
	return false

# Credit for being Lit by an evolution's light only: Strung Lights (a gap) or Glowworms (a Sprout's).
func _credit_light(sources: Array, at: Vector2) -> void:
	var gap := false
	var worm := false
	for source in sources:
		if source.get("gap", false):
			gap = true
		elif source.get("worm", false):
			worm = true
		else:
			return  # A Firefly Warden lights it anyway
	if gap and evo(EVO_STRUNG):
		credit(EVO_STRUNG, at)
	elif worm and evo(EVO_GLOWWORMS):
		credit(EVO_GLOWWORMS, at)

func lights_of(sources: Array) -> Array:
	var out: Array = []
	for source in sources:
		if not out.has(source.light):
			out.append(source.light)
	return out

# Firefly Wardens lighting this spot (gold path = two or more).
func jars_at(sources: Array) -> int:
	var count := 0
	for source in sources:
		if not source.sprout and not source.get("gap", false):
			count += 1
	return count

# The most another family's fork can be, started on a nightmare lit by `sources` (INF: uncapped).
func brightness(source_tower, sources: Array) -> float:
	if is_firefly(source_tower):
		return INF  # Firefly Wardens' own hits and bolts are never capped
	var best := 0.0
	for source in sources:
		var tower = source.tower
		if not is_instance_valid(tower):
			continue
		best = maxf(best, _base_jar_dps if source.sprout else tower.get_damage() * tower.get_attacks_per_second())
	return best * BRIGHTNESS_SECONDS if best > 0.0 else INF

func _enemies() -> Array:
	return get_tree().get_nodes_in_group(Tower.ENEMY_GROUP).filter(_living)

# The nearest Lit nightmares to `at`, nearest first (not those in `skip`).
func nearest_lit(at: Vector2, skip: Array, count: int = 1) -> Array:
	var found: Array = []
	for enemy in _enemies():
		if skip.has(enemy) or _lit_sources(enemy).is_empty():
			continue
		found.append(enemy)
	found.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
	return found.slice(0, count)

# The nearest Lit nightmares that event `id` has not struck yet (recursive hops).
func _fresh_lit(at: Vector2, id: int, skip: Array, count: int = 1) -> Array:
	var seen: Dictionary = _event_seen.get(id, {})
	var out: Array = []
	for enemy in nearest_lit(at, skip, count + seen.size()):
		if not seen.has(enemy.get_instance_id()):
			out.append(enemy)
	return out.slice(0, count)

func _step_of(enemy) -> int:
	return int(dream_state._path_index.get(enemy.get_current_cell(), -1))

# The front (furthest along the path) living nightmare standing in light `light`, or null.
func front_in(light: int, skip: Array = []):
	var best = null
	var best_step := -INF
	for enemy in _enemies():
		if skip.has(enemy) or not lights_of(_lit_sources(enemy)).has(light):
			continue
		var step := float(_step_of(enemy))
		if step > best_step:
			best_step = step
			best = enemy
	return best

# The next light ahead of path step `step`, not one of `from`: walk forward at most NEXT_LIGHT_STEPS. -1 = none.
func next_light(step: int, from: Array) -> Array:
	if step < 0:
		return [-1, -1]
	var by_step := {}
	for cell in _glow:
		var s := int(dream_state._path_index.get(cell, -1))
		if s > step and s <= step + NEXT_LIGHT_STEPS:
			by_step[s] = _glow[cell].lights
	for s in range(step + 1, step + NEXT_LIGHT_STEPS + 1):
		for light in by_step.get(s, []):
			if not from.has(light):
				return [light, s]
	return [-1, -1]

# --- Who is Lit, each POLL: reveals, entries (Ambush, Waiting Spark), leaving the last light (Last Spark) ----------

func _poll() -> void:
	var now := _now()
	for light in _sparks.keys():
		var waiting: Array = _sparks[light].filter(func(s: Dictionary) -> bool: return s.until > now)
		if waiting.is_empty():
			_sparks.erase(light)
			queue_redraw()
		else:
			_sparks[light] = waiting
	if not _embers.is_empty():
		_ember_poll(now)
	var container: Node = dream_state.spawner
	if container == null:
		return
	var lit := 0
	_lit_by_step = []
	for enemy in container.get_children():
		if not _living(enemy) or not enemy.has_method("get_current_cell"):
			continue
		var sources := _lit_sources(enemy)
		var lights: Array = lights_of(sources)
		var before: Array = enemy.get_meta(GROUPS_META, [])
		if not lights.is_empty():
			lit += 1
			var lit_step := _step_of(enemy)
			if lit_step >= 0:  # Walkers only (a flyer has no step): Torchbearers' list (hard cards 2026-10-16)
				_lit_by_step.append([lit_step, enemy])
		if not lights.is_empty() and enemy.has_method("is_hidden") and enemy.is_hidden() and _reveals(sources):
			enemy.reveal_for(POLL * 3.0)  # Lit nightmares can't hide (a Firefly Warden's own light only)
		if lights == before:
			continue
		enemy.set_meta(GROUPS_META, lights)
		for light in lights:
			if not before.has(light):
				_entered(enemy, light)
		if lights.is_empty() and not before.is_empty() and _step_of(enemy) >= _max_lit_step:
			_left_last_light(enemy)
	_lit_count = lit
	_lit_by_step.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))

# Torchbearers / Bale-fires (hard cards 2026-10-16): the nearest Lit nightmare further along the path than `step`, at most
# TORCH_STEPS ahead, not in `skip` and not claimed by another throw in the last TORCH_CLAIM s (smallest step first, then
# nearest to `at`). Reads the poll's sorted list: at most 0.1 s stale. Null = none. `seen` = instance ids the event
# already struck (an _event_seen entry), skipped as _fresh_lit does (council full_review 2026-10-17: Bale-fires).
func next_lit_ahead(step: int, at: Vector2, skip: Array = [], seen: Dictionary = {}):
	if step < 0 or _lit_by_step.is_empty():
		return null
	var i: int = _lit_by_step.bsearch_custom([step, null], func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]), false)
	var now := _now()
	var best = null
	var best_step := -1
	while i < _lit_by_step.size():
		var entry: Array = _lit_by_step[i]
		i += 1
		var s := int(entry[0])
		if s > step + TORCH_STEPS or (best != null and s > best_step):
			break
		var enemy = entry[1]
		if not _living(enemy) or skip.has(enemy) or seen.has(enemy.get_instance_id()) \
				or now < float(enemy.get_meta(TORCH_CLAIM_META, -INF)):
			continue
		if best == null or enemy.global_position.distance_squared_to(at) < best.global_position.distance_squared_to(at):
			best = enemy
			best_step = s
	return best

# Torchbearers: half the dispelling hit jumps to the nearest Lit nightmare ahead (no per-light clock: EVENT_MAX bounds a
# chain, the claim spreads many throws forward). Bale-fires: `parent` is the jump that just dispelled, so this one keeps
# its event and hops. The spark threads through the glow spot of the target's light.
func _torch(id: int, source, at: Vector2, step: int, amount: float, cap: float, parent: Dictionary = {}, origin = null,
		skip: Array = []) -> void:
	var target = next_lit_ahead(step, at, skip, _event_seen.get(id, {}))
	if target == null:
		return
	target.set_meta(TORCH_CLAIM_META, _now() + TORCH_CLAIM)
	var relay := int(parent.get("relay", -1)) + 1
	var opts := _hop(parent, {"relay": relay, "color": Palette.HEARTLIGHT}) if not parent.is_empty() \
		else {"relay": 0, "color": Palette.HEARTLIGHT}
	if origin != null:
		opts["origin"] = origin
	elif parent.has("carry"):
		opts["carry"] = parent.carry
	var from := at
	var groups: Array = target.get_meta(GROUPS_META, [])
	var spot := _light_spot(int(groups[0])) if not groups.is_empty() else Vector2.ZERO
	if spot != Vector2.ZERO:
		_line_fx(at, spot, 2.0, Palette.GLOW)  # The spark flies to the target's light…
		from = spot  # …and the light throws it
	# Credited in _strike once the throw lands, never here: _flush may still drop it (council full_review 2026-10-17)
	opts["credit"] = EVO_BALE if relay > 0 else EVO_TORCH  # Setup credit 2026-10-16: its own damage
	opts["calling"] = true  # F1 (f1_spec.md): a Calling output (a hit by `source` for other families' lent cards)
	_fork(id, source, from, target, amount, cap, opts)

# Waiting Spark: every spark waiting in a light strikes the next nightmare to enter it. Strung Lights counts the glow
# (a set of light ids: a joined stretch borrows a joined light's id, so it is never a new glow).
func _entered(enemy, light: int) -> void:
	if evo(EVO_STRUNG):
		var glows: Dictionary = enemy.get_meta(GLOWS_META, {})
		glows[light] = true
		enemy.set_meta(GLOWS_META, glows)
	if not _sparks.has(light):
		return
	var id := _next_event()
	for spark in _sparks[light]:
		var source = spark.source.get_ref()
		_strike({"event": id, "source": source, "from": enemy.global_position + Vector2(0, -24), "target": enemy,
			"amount": spark.amount, "cap": spark.cap, "waited": true, "final": true})  # A spark never waits twice
	_sparks.erase(light)
	queue_redraw()

# Last Spark: a Charged nightmare walking out of its last light throws its charge back into the light.
func _left_last_light(enemy) -> void:
	if not _rule(LAST_SPARK) or not enemy.statuses.has(EnemyStatuses.STATIC):
		return
	var charge: float = enemy.statuses.stored_bolt_damage()
	var source = enemy.statuses.source(EnemyStatuses.STATIC)
	enemy.statuses.remove(EnemyStatuses.STATIC)  # On walking out its Charged ends
	var targets := nearest_lit(enemy.global_position, [enemy])
	if charge > 0.0 and not targets.is_empty():
		_fork(_next_event(), source, enemy.global_position, targets[0], charge, INF, {"final": true})

# --- Damage events ----------------------------------------------------------------------------------------------

func _next_event() -> int:
	_event += 1
	return _event

# Whether any rule _on_damage reads is on (Chain of Lanterns, the lights, a lent card, Guiding Light), cached against
# the run's rule map and Calling as class_kit.active(): asked for every damage event (Enemy Code perf, 2026-10-17).
var _any_on_map = null
var _any_on_calling := ""
var _any_on := false
var _any_on_key := Vector3i(-1, -1, -1)  # Frame x rules_stamp x stacks: repeat asks in a frame skip even _rule_map (perf, Main Merger 2026-10-17)

func _any_rule_on() -> bool:
	var key := Vector3i(Engine.get_process_frames(), dream_state.rules_stamp, dream_state.stacks.size())
	if key == _any_on_key and dream_state.calling == _any_on_calling:
		return _any_on
	_any_on_key = key
	var map: Dictionary = dream_state._rule_map()
	if not is_same(map, _any_on_map) or dream_state.calling != _any_on_calling:
		_any_on_map = map
		_any_on_calling = dream_state.calling
		_any_on = _rule(CHAIN_OF_LANTERNS) or _lit_on() or _lent_on() or _rule(GUIDING_LIGHT)
	return _any_on

func _on_damage(event) -> void:
	if dream_state == null or event.tag == FORK_TAG or not is_instance_valid(event.enemy):
		return  # A fork triggers nothing
	if not _any_rule_on():
		return  # Nothing of the Firefly set is held: the common case, and the cheap one
	if event.calling != &"" and String(event.calling) != FAMILY and event.kind != &"reaction":
		_calling_event(event)  # F1 (f1_spec.md): another family's Calling output: the lent cards only, as a hit
		return
	if _rule(CHAIN_OF_LANTERNS) and CLASS_KIT.is_reaction_burst(event):
		_chain_more(event)  # Any family's Reaction on a nightmare a Firefly Warden hit in the last 2 s (the shared list, council 2026-10-15)
	if event.kind == &"reaction":
		return  # A Reaction's own lightning gets nothing else added (a burst logged as a hit, Shatter, still counts as a dispel)
	var on := _lit_on()
	var lent := _lent_on()
	var guiding := _rule(GUIDING_LIGHT)
	if not on and not lent and not guiding:
		return
	var source = event.source if is_instance_valid(event.source) and event.source is Tower else null
	if source == null:
		return
	var id := _next_event()  # One event for every rule this hit sets off: one fork per nightmare, the largest wins
	if guiding and event.kind == &"hit" and event.tag == &"":
		_guiding_light(id, event, source)
	if not on and not lent:
		return
	var enemy = event.enemy
	var dispel: bool = enemy.health <= 0
	var is_bolt: bool = event.kind == &"bolt"
	var is_hit: bool = event.kind == &"hit" and event.tag == &""
	# One clock for every heavy rule on this event (a second call would read the clock this one just set)
	_heavy_now = is_hit and (is_heavy(source) or source.tower_data.get_id() == "sprout") \
		and (_rule(SPOTLIGHT) or _rule(HAMMERFALL) or _rule(THUNDERSTRUCK)) and _new_heavy_attack(source)
	if on:
		_class_rules(id, event, source, enemy, dispel, is_hit, is_bolt)
	if lent:
		_lent_rules(id, event, source, enemy, dispel, is_hit, is_bolt)

# F1 lent × Calling (owner 2026-10-18; D:\Projects\logs\dream_council\f1_spec.md): another family's Calling output (a
# Toll, a dose's Warden, a Reflection…) is a hit by its Warden for the lent cards here: Hammerfall, Thunderstruck, Sparks
# Fly, Nothing Wasted, the Firefly-hit mark (Struck Twice spends on it in damage_multiplier). Never Flashover, Crossfire
# (attack-shaped) or Brushfire (ticks); never the Calling's class rules. Each card's own clock is shared with real hits.
func _calling_event(event) -> void:
	if not _lent_on():
		return
	var source = event.source if is_instance_valid(event.source) and event.source is Tower else null
	if source == null:
		return
	var enemy = event.enemy
	var is_hit: bool = event.kind == &"hit"
	var id := _next_event()
	_heavy_now = is_hit and (is_heavy(source) or source.tower_data.get_id() == "sprout") \
		and (_rule(SPOTLIGHT) or _rule(HAMMERFALL) or _rule(THUNDERSTRUCK)) and _new_heavy_attack(source)
	_lent_rules(id, event, source, enemy, enemy.health <= 0, is_hit, false, true)

# The nightmares other jumps of event `id` are already queued to (F4: two jumps from one hit go to different nightmares).
func _taken_by(id: int) -> Array:
	var out: Array = []
	for request in _queue:
		if int(request.event) == id and is_instance_valid(request.target):
			out.append(request.target)
	return out

# `skip` plus `taken`, unless that leaves nothing near `at` to jump to (then today's list: _flush keeps the largest).
func _fan_out(at: Vector2, skip: Array, taken: Array) -> Array:
	if not taken.is_empty():
		var found := _near_enemies(at, skip + taken)
		if not found.is_empty():
			return found
	return _near_enemies(at, skip)

# Chain of Lanterns on any Reaction (trait rework 2026-10-15; was Charged Reactions only): on a nightmare a Firefly Warden
# hit in the last 2 s, half of it jumps to the 2 nearest other nightmares near it. Each Firefly Warden, once a second;
# capped at 3 s of that Firefly Warden's damage.
func _chain_more(event) -> void:
	var enemy = event.enemy
	var lit: Array = enemy.get_meta(FF_HIT_META, [])
	if lit.is_empty() or _now() - float(lit[0]) > SPARKS_WINDOW:
		return
	var jar = lit[1].get_ref()
	if not is_instance_valid(jar) or _now() < float(jar.get_meta(CHAIN_META, -INF)):
		return
	var targets: Array = _near_enemies(enemy.global_position, [enemy]).slice(0, CHAIN_TARGETS)
	if targets.is_empty():
		return
	jar.set_meta(CHAIN_META, _now() + CHAIN_EVERY)
	var source = event.source if is_instance_valid(event.source) and event.source is Tower else jar
	var id := _next_event()
	for target in targets:
		_fork(id, source, enemy.global_position, target, event.base * CHAIN_SHARE, _lent_cap(null, jar), {"final": true})

# The most a lent card's jump may deal (never "no cap" for another family: brightness() is never asked with no light).
# A Firefly Warden's own jumps stay uncapped, as the Calling's are; another family's are capped at 3 s of the Firefly
# Warden `jar` (the one near it, or the one that Charged the nightmare), or of a base Firefly Jar when there is none.
func _lent_cap(source, jar) -> float:
	if is_instance_valid(source) and is_firefly(source):
		return INF
	if is_instance_valid(jar) and is_firefly(jar):
		return jar.get_damage() * jar.get_attacks_per_second() * BRIGHTNESS_SECONDS
	return _base_jar_dps * BRIGHTNESS_SECONDS

# Guiding Light (owner ruling 2026-10-12, dream_council_review.md 21): a hit on a fully Exposed nightmare forks to the
# nightmares within 1 cell of it (II: 2 cells), for half. It no longer spreads Exposed stacks.
func _guiding_light(id: int, event, source) -> void:
	var enemy = event.enemy
	if not enemy.statuses.is_exposed():
		return  # Full Exposed: 10 stacks, 20 with Brimming
	var at: Vector2 = enemy.global_position
	var reach: float = GUIDING_CELLS[mini(dream_state.rule_level(GUIDING_LIGHT), GUIDING_CELLS.size() - 1)] * _cell()
	for other in _enemies():
		if other != enemy and other.global_position.distance_to(at) <= reach:
			_fork(id, source, at, other, event.base * GUIDING_SHARE, INF, {"final": true})

# The size a dispel's fork starts from: that Warden's hit, or one second of its damage for a tick, cloud or trail.
func _hit_size(source, is_hit: bool, is_bolt: bool) -> float:
	var hit: float = source.get_damage()
	if is_hit or is_bolt:
		return hit  # A bolt that dispels forks from the Warden's hit, not the bolt
	return hit * source.get_attacks_per_second()

func _class_rules(id: int, event, source, enemy, dispel: bool, is_hit: bool, is_bolt: bool) -> void:
	var at: Vector2 = enemy.global_position
	var sources := _lit_sources(enemy)
	if sources.is_empty():
		return  # Class cards follow the light: the nightmare that was hit must be Lit
	var lights := lights_of(sources)
	var cap := brightness(source, sources)  # Never an empty list here: the nightmare is Lit
	if dispel:
		var size := _hit_size(source, is_hit, is_bolt)
		var jars := jars_at(sources)
		var gold := jars >= 2
		# Lantern Light; on gold path Where Lights Meet replaces it: one fork per Firefly Warden lighting it.
		var count := mini(jars, MEET_MAX) if gold and _rule(WHERE_LIGHTS_MEET) else 1
		var meet_count := count  # Setup credit 2026-10-16: jumps past the first are Where Lights Meet's, past these Bonfire's
		if gold and evo(EVO_BONFIRE):
			count = maxi(count, mini(GOLD_JUMPS, MEET_MAX))  # Bonfire: 2 jumps on gold path (TD fix 15: never past MEET_MAX)
		var targets := nearest_lit(at, [enemy], count)
		if class_on():  # The Calling's own payoff: the first pick only
			for t in targets.size():
				var opts := {"origin": enemy, "calling": true}  # (F1: the Calling's jump)
				if t >= meet_count:
					opts["credit"] = EVO_BONFIRE
				elif t >= 1:
					opts["credit"] = WHERE_LIGHTS_MEET
				_fork(id, source, at, targets[t], size * CALLING_SHARE, cap, opts)
			if targets.is_empty():
				_wait(lights, source, size * CALLING_SHARE, cap)
			else:
				_credit_light(sources, at)
				if gold and targets.size() >= 2 and evo(EVO_BONFIRE):
					credit(EVO_BONFIRE, at, source)
		if evo(EVO_TORCH):  # Hard cards 2026-10-16: the nearest Lit nightmare ahead (Torchbearers wins over Signal Fires)
			# Its own event, skipping the Calling's targets, so _flush never drops the throw (council full_review 2026-10-17)
			_torch(_next_event(), source, at, _step_of(enemy), size * RELAY_SHARE, cap, {}, enemy, [enemy] + targets)
		elif _rule(SIGNAL_FIRES):  # (Retired class card: an old save keeps its light-to-light rule)
			_signal(id, source, at, _step_of(enemy), lights, size * SIGNAL_SHARE, cap, {}, enemy)
		if gold and evo(EVO_EMBERS):
			_drop_ember(enemy, source, size * EMBER_SHARE, cap)
		if _rule(LAST_SPARK) and enemy.statuses.has(EnemyStatuses.STATIC):
			var charge: float = enemy.statuses.stored_bolt_damage()
			var spark_to := nearest_lit(at, [enemy])
			if charge > 0.0 and not spark_to.is_empty():
				_fork(_next_event(), enemy.statuses.source(EnemyStatuses.STATIC), at, spark_to[0], charge, INF, {"final": true, "credit": LAST_SPARK})
	if is_bolt:
		if _rule(LANTERNWAY):
			var step := _step_of(enemy)
			var seen := lights.duplicate()
			var from := at
			for i in LANTERNWAY_LIGHTS:
				var next := next_light(step, seen)
				if int(next[0]) < 0:
					break
				seen.append(next[0])
				step = int(next[1])
				var front = front_in(int(next[0]))
				if front != null:
					_fork(id, source, from, front, event.base * LANTERNWAY_SHARE, cap, {"credit": LANTERNWAY})
					from = front.global_position
	if is_hit and _evolved():
		if evo(EVO_BORROWED) and is_other(source):
			_borrowed_light(id, event, source, enemy, at, cap)
		if evo(EVO_SIGHT):
			_sightline(event, source, enemy, at, sources)
	if is_hit:
		if _heavy_now and is_heavy(source) and _rule(SPOTLIGHT):  # (Spotlight: retired 2026-10-14; an old save keeps it)
			for light in lights:
				if front_in(light) != enemy:
					continue
				var others: Array = _enemies().filter(func(e) -> bool:
					return e != enemy and lights_of(sources_at(e.global_position)).has(light))
				var fan: Array = others.slice(0, SPOTLIGHT_MAX)
				for other in fan:  # The cap covers the whole fan (council, new_lent_td.md)
					_fork(id, source, at, other, minf(event.base * SPOTLIGHT_SHARE, cap / maxf(fan.size(), 1.0)), cap, {"heavy": true})
				break
		if _rule(AMBUSH):
			var ambushed: Dictionary = enemy.get_meta(AMBUSH_META, {})
			var fresh := false
			for light in lights:
				if not ambushed.has(light):
					ambushed[light] = true
					fresh = true
			if fresh:
				enemy.set_meta(AMBUSH_META, ambushed)
				var targets := nearest_lit(at, [enemy])
				if not targets.is_empty():
					_fork(id, source, at, targets[0], event.base * AMBUSH_SHARE, cap)

# One fork per heavy attack: the first hit after most of its attack time has passed starts a new one.
func _new_heavy_attack(source) -> bool:
	var now := _now()
	if now < float(source.get_meta(HEAVY_META, -INF)):
		return false
	source.set_meta(HEAVY_META, now + HEAVY_ATTACK_SHARE / maxf(source.get_attacks_per_second(), 0.05))
	return true

# Signal Fires: a dispel in one light also forks to the front nightmare in the next light ahead, once per light a second.
# (Torchbearers and Bale-fires used this until hard cards 2026-10-16; they now go through _torch. The relay branch below
# stays for the parent/relay options a Signal Fires throw may carry.)
func _signal(id: int, source, at: Vector2, step: int, lights: Array, amount: float, cap: float, parent: Dictionary = {},
		origin = null) -> void:
	var now := _now()
	for light in lights:
		if now < float(_signal_next.get(light, -INF)):
			return
	var next := next_light(step, lights)
	if int(next[0]) < 0:
		return
	var front = front_in(int(next[0]))
	if front == null:
		return
	for light in lights:
		_signal_next[light] = now + SIGNAL_EVERY
	var from := at
	var opts := {}
	if evo(EVO_TORCH) or not parent.is_empty():
		var relay := int(parent.get("relay", -1)) + 1
		opts = _hop(parent, {"relay": relay, "color": Palette.HEARTLIGHT}) if not parent.is_empty() \
			else {"relay": 0, "color": Palette.HEARTLIGHT}
		if origin != null:
			opts["origin"] = origin
		elif parent.has("carry"):
			opts["carry"] = parent.carry
		var spot := _light_spot(int(next[0]))
		if spot != Vector2.ZERO:
			_line_fx(at, spot, 2.0, Palette.GLOW)  # The spark flies light to light…
			from = spot  # …and the next light throws it
		credit(EVO_BALE if relay > 0 else EVO_TORCH, front.global_position)
	_fork(id, source, from, front, amount, cap, opts)

# --- Hit bonuses: Struck Twice, Bonfire, Strung Lights (self-sufficiency audit 2026-10-18) ---------------------------

# Whether any hit bonus here is on (DreamState.batch_damage_multiplier asks once a frame before calling damage_multiplier).
func wants_damage_hook() -> bool:
	return _rule(STRUCK_TWICE) or evo(EVO_BONFIRE) or evo(EVO_STRUNG)

# Struck Twice (DreamState.note_jump, every jump from any card or Warden): the nightmare a jump lands on waits for one
# boosted hit for STRUCK_TIME s. A new jump refreshes the one mark (never stacks). A small spark shows it.
func mark_struck(source, to) -> void:
	if not _living(to):
		return
	var old: Array = to.get_meta(STRUCK_META, [])
	var spark = old[3].get_ref() if old.size() > 3 and old[3] != null else null
	if not is_instance_valid(spark) or spark.is_queued_for_deletion():
		spark = null
		var world := Reactions._world(self)
		if world != null:
			spark = StruckSpark.new(to, self)
			world.add_child(spark)  # Never under %EnemyContainer (its children are all nightmares)
	to.set_meta(STRUCK_META, [_now(), Engine.get_process_frames(), source.get_instance_id() if is_instance_valid(source) else 0,
		weakref(spark) if spark != null else null])

# Whether `enemy` still waits for its Struck Twice hit (the spark asks each frame).
func is_struck(enemy) -> bool:
	if not _living(enemy) or not enemy.has_meta(STRUCK_META):
		return false
	return _now() - float(enemy.get_meta(STRUCK_META)[0]) <= STRUCK_TIME

# The hit bonuses, for hits only (tag ""; never jumps or bolts): Struck Twice (a Firefly Warden or a Warden near one; a
# Warden counts as near itself), Bonfire (a Firefly Warden's hit on gold path), Strung Lights (a Firefly Warden's hit, per
# glow the nightmare entered). Each one notes its card bonus (DamageLog) and credits itself with the Warden.
func damage_multiplier(enemy, source, tag: StringName = &"") -> float:
	var calling: bool = DamageLog.calling_now != &"" and String(DamageLog.calling_now) != FAMILY  # F1: another family's Calling output is a hit
	if (tag != &"" and not calling) or not (source is Tower) or not is_instance_valid(source) or not is_instance_valid(enemy):
		return 1.0
	var multiplier := 1.0
	var own := is_firefly(source)
	if _rule(STRUCK_TWICE) and enemy.has_meta(STRUCK_META):
		var mark: Array = enemy.get_meta(STRUCK_META)
		if _now() - float(mark[0]) > STRUCK_TIME:
			enemy.remove_meta(STRUCK_META)  # Faded
		elif (own or firefly_near(source) != null) \
				and not (int(mark[1]) == Engine.get_process_frames() and int(mark[2]) == source.get_instance_id()):
			# (A chain Warden's hop is a jump and its hit in the same frame: it never spends the mark it just made)
			enemy.remove_meta(STRUCK_META)
			multiplier *= STRUCK_BONUS
			DamageLog.note_card_bonus(String(STRUCK_TWICE), STRUCK_BONUS)
			credit(STRUCK_TWICE, enemy.global_position, source)
	if not own or not _evolved() or tag != &"":
		return multiplier
	if evo(EVO_BONFIRE) and jars_at(_lit_sources(enemy)) >= 2:
		multiplier *= BONFIRE_BONUS
		DamageLog.note_card_bonus(String(EVO_BONFIRE), BONFIRE_BONUS)
		credit(EVO_BONFIRE, enemy.global_position, source)
	if evo(EVO_STRUNG):
		var glows := (enemy.get_meta(GLOWS_META, {}) as Dictionary).size()
		if glows > 0:
			var strung := 1.0 + minf(STRUNG_PER_GLOW * glows, STRUNG_MAX)
			multiplier *= strung
			DamageLog.note_card_bonus(String(EVO_STRUNG), strung)
			credit(EVO_STRUNG, enemy.global_position, source)
	return multiplier

# Struck Twice's mark: a small warm spark over the nightmare until its boosted hit lands or the mark fades.
class StruckSpark extends Node2D:
	var _enemy: WeakRef
	var _lights: WeakRef

	func _init(enemy: Node2D, lights: Node) -> void:
		_enemy = weakref(enemy)
		_lights = weakref(lights)
		z_index = 20  # Over the nightmares
		global_position = enemy.global_position

	func _process(_delta: float) -> void:
		var enemy = _enemy.get_ref()
		var lights = _lights.get_ref()
		if lights == null or not lights.is_struck(enemy):
			queue_free()
			return
		global_position = enemy.global_position

	func _draw() -> void:
		draw_circle(Vector2(12, -30), 3.0, Color(Palette.HEARTLIGHT, 0.6))
		draw_circle(Vector2(12, -30), 1.5, Palette.HEARTLIGHT)

# --- Calling evolutions: the helpers --------------------------------------------------------------------------------

# The options of a recursive hop from `request`: same chain, one more hop (TD correction 3: never a new event id).
func _hop(request: Dictionary, extra: Dictionary) -> Dictionary:
	var opts := {"hops": int(request.get("hops", 0)) + 1}
	if request.has("pyre"):
		opts["pyre"] = request.pyre
	if request.has("calling"):
		opts["calling"] = request.calling  # F1: a Calling jump's hop is one too
	opts.merge(extra, true)
	return opts

# Whether `request` may hop again (a chain is never longer than EVENT_MAX).
func _can_hop(request: Dictionary) -> bool:
	return int(request.get("hops", 0)) + 1 < EVENT_MAX

# Lantern Wake: the statuses a jump from `enemy` carries (never Rooted; up to WAKE_STATUSES).
func _carry_of(enemy) -> Array:
	var out: Array = []
	if not is_instance_valid(enemy) or enemy.get("statuses") == null:
		return out
	for status in enemy.statuses.active_ids():
		if status != EnemyStatuses.HELD:
			out.append(status)
			if out.size() >= WAKE_STATUSES:
				break
	return out

# Lantern Wake: the carried stacks go onto the same statuses already on the nightmare (the quiet add: never starts one,
# runs no Reaction check, Charged stops one short of a bolt; TD: the Reaction loop through Chain of Lanterns is closed).
func _wake(target, carry: Array, from: Vector2) -> void:
	var first := &""
	for status in carry:
		if not _living(target):
			return
		var woke: int = target.statuses.add_quiet(status, WAKE_STACKS)
		SETUP.note(target, EVO_WAKE, status, float(woke), true)  # (setup credit 2026-10-16)
		if woke > 0 and first == &"":
			first = status
	if first != &"":
		target.flash_status(first)
		_line_fx(from, target.global_position, 2.0, Palette.BLOSSOM)  # Coloured motes ride the jump
		credit(EVO_WAKE, target.global_position)

# Borrowed Light: another Warden's hit on a Lit nightmare (Sprouts count) jumps a third to the nearest other Lit
# nightmare, once a second per Warden. Capped by the light's brightness, except a Sprout's (player review: felt from
# drift 5, and a Sprout's third never comes near the cap anyway).
func _borrowed_light(id: int, event, source, enemy, at: Vector2, cap: float) -> void:
	if _now() < float(source.get_meta(LAMP_META, -INF)):
		return
	var targets := nearest_lit(at, [enemy])
	if targets.is_empty():
		return
	source.set_meta(LAMP_META, _now() + LAMP_EVERY)
	var limit := INF if source.tower_data.get_id() == "sprout" else cap
	_fork(id, source, at, targets[0], event.base * LAMP_SHARE, limit, {"origin": enemy, "color": Palette.GLOW, "width": 2.0, "credit": EVO_BORROWED, "calling": true})
	credit(EVO_BORROWED, targets[0].global_position, source)

# Show the Way (from _evolved_strike): a Borrowed Light jump that landed jumps once more, at half, to another Lit
# nightmare. Same event (a hop: never a nightmare the event already struck, never the one the hit was on, inside
# EVENT_MAX), same cap; the second jump is credited to Show the Way, so it never jumps a third time.
func _show_the_way(request: Dictionary, source, target, at: Vector2, had: Array) -> void:
	var skip: Array = [target]
	var left = request.get("jump_from")
	if is_instance_valid(left):
		skip.append(left)
	var next := _fresh_lit(at, int(request.event), skip)
	if next.is_empty():
		return
	var opts := _hop(request, {"color": Palette.GLOW, "width": 2.0, "credit": EVO_SHOW, "calling": true})
	if not had.is_empty():
		opts["carry"] = had  # Lantern Wake: it carries what the nightmare it leaves had
	_fork(int(request.event), source, at, next[0], float(request.amount) * SHOW_SHARE, float(request.cap), opts)
	credit(EVO_SHOW, next[0].global_position, source)

# Sightline: 3 different Wardens hit one Lit nightmare within 2 s: a quarter of each hit jumps to the nearest other Lit
# nightmare. Each Warden's jump is its own event, so all of them land on that one nightmare (three beams meet; and
# Constellation counts them). Then not on this nightmare for SIGHT_LOCK.
func _sightline(event, source, enemy, at: Vector2, sources: Array) -> void:
	var now := _now()
	if now < float(enemy.get_meta(SIGHT_NEXT_META, -INF)):
		return
	var roster: Dictionary = enemy.get_meta(SIGHT_META, {})
	roster[source.get_instance_id()] = [now, weakref(source), event.base]
	for key in roster.keys():
		if now - float(roster[key][0]) > SIGHT_WINDOW:
			roster.erase(key)
	enemy.set_meta(SIGHT_META, roster)
	if roster.size() < SIGHT_WARDENS:
		return
	var targets := nearest_lit(at, [enemy])
	if targets.is_empty():
		return  # Kept: it fires once there is somewhere to jump
	enemy.set_meta(SIGHT_NEXT_META, now + SIGHT_LOCK)
	enemy.remove_meta(SIGHT_META)
	var rows: Array = roster.values()
	rows.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	for row in rows.slice(0, SIGHT_MAX):
		var tower = row[1].get_ref()
		if not is_instance_valid(tower):
			continue
		Reactions._segment(&"light_thread", tower.global_position, at, self, 0.4)  # Three beams meet
		_fork(_next_event(), tower, at, targets[0], float(row[2]) * SIGHT_SHARE, brightness(tower, sources), {"origin": enemy, "credit": EVO_SIGHT, "calling": true})
	credit(EVO_SIGHT, at, source)

# F1 (f1_spec.md): Moth to Flame's and Constellation's Exposed is an application by its Warden for the other families'
# lent cards (Sporeling's stack cards first, then who hears it). Only while Lantern Light is the Calling.
func _calling_stacks(tower, enemy, status: StringName, stacks: int) -> int:
	if not class_on() or not (tower is Tower) or not _living(enemy):
		return stacks
	return dream_state.calling_stacks(FAMILY, tower, enemy, status, stacks)

func _calling_status(tower, enemy, status: StringName, stacks: int, applied_before: int) -> void:
	if class_on() and tower is Tower and _living(enemy) and enemy.statuses.applications > applied_before:
		dream_state.calling_status(FAMILY, tower, enemy, status, stacks)

# Constellation: jumps from 3 different Wardens within 3 s make a nightmare fully Exposed (bosses half), once in 8 s.
func _constellation(target, source, at: Vector2) -> void:
	var now := _now()
	if now < float(target.get_meta(CONST_NEXT_META, -INF)):
		return
	var roster: Dictionary = target.get_meta(CONST_META, {})
	roster[source.get_instance_id()] = [now, weakref(source)]
	for key in roster.keys():
		if now - float(roster[key][0]) > CONST_WINDOW:
			roster.erase(key)
	target.set_meta(CONST_META, roster)
	if roster.size() < CONST_WARDENS:
		return
	target.set_meta(CONST_NEXT_META, now + CONST_EVERY)
	target.remove_meta(CONST_META)
	var statuses = target.statuses
	var want := ceili(float(statuses.get_max_stacks(EnemyStatuses.MARKED)) * (CONST_BOSS_SHARE if statuses.is_boss else 1.0))
	var add: int = want - statuses.stacks(EnemyStatuses.MARKED)
	if add > 0:
		add = _calling_stacks(source, target, EnemyStatuses.MARKED, add)  # F1: an Exposed application by its Warden
		var applied_before: int = statuses.applications
		SETUP.apply(target, EVO_CONSTELLATION, EnemyStatuses.MARKED, add, 0.0, source.get_damage(), 0, source.tower_data.line, source)  # (setup credit 2026-10-16)
		_calling_status(source, target, EnemyStatuses.MARKED, add, applied_before)
	for row in roster.values():
		var tower = row[1].get_ref()
		if is_instance_valid(tower):
			_line_fx(tower.global_position, at, 1.5, Palette.GLOW)  # The stars link over it
	Reactions._effect(&"exposed_complete", at, self)
	credit(EVO_CONSTELLATION, at, source)

# Embers: a dispel on gold path leaves an ember on its step for EMBER_TIME. Witchfire: an ember within HEARTH_JOIN steps
# of a pile joins it (up to HEARTH_MAX). At most EMBER_MAX piles.
func _drop_ember(enemy, source, amount: float, cap: float) -> void:
	var step := _step_of(enemy)
	if step < 0 or amount <= 0.0:
		return
	var until := _now() + EMBER_TIME
	if evo(EVO_WITCHFIRE):
		for s in _embers:
			if absi(int(s) - step) <= HEARTH_JOIN:
				var pile: Dictionary = _embers[s]
				if int(pile.count) < HEARTH_MAX:
					pile.count = int(pile.count) + 1
					pile.amount = float(pile.amount) + amount
					pile.cap = float(pile.cap) + cap
					pile.source = weakref(source)
				pile.until = until
				queue_redraw()
				return
	elif _embers.has(step):
		var pile: Dictionary = _embers[step]
		if amount > float(pile.amount):
			pile.amount = amount
			pile.cap = cap
			pile.source = weakref(source)
		pile.until = until
		return
	if _embers.size() >= EMBER_MAX:
		return
	_embers[step] = {"amount": amount, "cap": cap, "source": weakref(source), "until": until, "count": 1}
	queue_redraw()

# Embers (polled): the next nightmare to reach an ember takes it (half the dispelling hit); with Witchfire the pile
# bursts on the nightmares within 1 cell. Bosses take half (_strike), so this is Lantern Light's answer to a boss.
func _ember_poll(now: float) -> void:
	var reach := EMBER_REACH * _cell()
	for step in _embers.keys():
		var pile: Dictionary = _embers[step]
		if now > float(pile.until) or not _step_px.has(int(step)):
			_embers.erase(step)
			queue_redraw()
			continue
		var at: Vector2 = _step_px[int(step)]
		var near: Array = Tower.nightmares_near(get_tree(), at, reach).filter(func(e) -> bool:
			return _living(e) and e.global_position.distance_to(at) <= reach)
		if near.is_empty():
			continue
		_embers.erase(step)
		queue_redraw()
		var source = pile.source.get_ref()
		var id := _next_event()
		var amount: float = minf(float(pile.amount), float(pile.cap))
		var targets: Array = near.slice(0, 1)
		if evo(EVO_WITCHFIRE):
			var burst := HEARTH_CELLS * _cell()
			targets = Tower.nightmares_near(get_tree(), at, burst).filter(func(e) -> bool:
				return _living(e) and e.global_position.distance_to(at) <= burst)
			targets.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
			targets = targets.slice(0, HEARTH_TARGETS)
			Reactions._effect(&"spark_burst", at, self, 0.7 + 0.2 * float(pile.count))
			credit(EVO_WITCHFIRE, at)
		else:
			Reactions._effect(&"hit_light", at, self)
			credit(EVO_EMBERS, at)
		for target in targets:
			_strike({"event": id, "source": source, "from": at, "target": target, "amount": amount, "cap": float(pile.cap),
				"final": true, "color": Palette.EMBER, "credit": EVO_WITCHFIRE if evo(EVO_WITCHFIRE) else EVO_EMBERS, "calling": true})

# After a jump struck (the Firefly start with any evolution): Moth to Flame, Constellation, Pyre, Bale-fires, Swarm Night.
# `before`: the sources lighting the target before the hit; `had`: its statuses before it (Lantern Wake on the next hop).
func _evolved_strike(request: Dictionary, source, target, at: Vector2, before: Array, step: int, had: Array) -> void:
	var dead := not _living(target)
	var gold := jars_at(before) >= 2
	if not before.is_empty():
		_credit_light(before, at)
	var warden: bool = source is Tower and is_instance_valid(source)
	if not dead and warden:
		if gold and evo(EVO_MOTH):
			var stacks := maxi(int(MOTH_EXPOSED * 0.5), 1) if target.statuses.is_boss else MOTH_EXPOSED
			stacks = _calling_stacks(source, target, EnemyStatuses.MARKED, stacks)  # F1: an Exposed application by its Warden
			var applied_before: int = target.statuses.applications
			SETUP.apply(target, EVO_MOTH, EnemyStatuses.MARKED, stacks, 0.0, source.get_damage(), 0, source.tower_data.line, source)  # (setup credit 2026-10-16)
			_calling_status(source, target, EnemyStatuses.MARKED, stacks, applied_before)
			if _living(target):
				target.flash_status(EnemyStatuses.MARKED)
			credit(EVO_MOTH, at, source)
		if _living(target) and evo(EVO_CONSTELLATION):
			_constellation(target, source, at)
	if not _can_hop(request):
		return
	var event: int = request.event
	if evo(EVO_SHOW) and request.get("credit", &"") == EVO_BORROWED:
		_show_the_way(request, source, target, at, had)
	if dead and gold and evo(EVO_PYRE) and int(request.get("pyre", 0)) < PYRE_HOPS:
		var next := _fresh_lit(at, event, [target])
		if not next.is_empty():
			var opts := _hop(request, {"pyre": int(request.get("pyre", 0)) + 1, "color": Palette.EMBER, "credit": EVO_PYRE, "calling": true})
			if not had.is_empty():
				opts["carry"] = had
			_fork(event, source, at, next[0], float(request.amount), float(request.cap), opts)
			Reactions._effect(&"spark_burst", at, self, 0.6)  # Flame arcs on
			credit(EVO_PYRE, at, source)
	if dead and request.has("relay") and evo(EVO_BALE) and int(request.relay) < BALE_HOPS:
		var parent := request.duplicate()
		parent.erase("target")
		if not had.is_empty():
			parent["carry"] = had
		_torch(event, source, at, step, float(request.amount), float(request.cap), parent, null, [target])  # Hard cards 2026-10-16
	if evo(EVO_SWARM) and _lit_count >= SWARM_AT and not request.get("swarm", false) and not request.get("final", false):
		var next := _fresh_lit(at, event, [target])
		if not next.is_empty():
			var opts := _hop(request, {"swarm": true, "color": Palette.HEARTLIGHT, "credit": EVO_SWARM, "calling": true})
			if not had.is_empty():
				opts["carry"] = had
			_fork(event, source, at, next[0], float(request.amount) * SWARM_SHARE, float(request.cap), opts)
			credit(EVO_SWARM, next[0].global_position, source)

# Waiting Spark: a fork with nowhere to go waits in its light.
func _wait(lights: Array, source, amount: float, cap: float) -> void:
	if not _rule(WAITING_SPARK) or lights.is_empty() or amount <= 0.0:
		return
	var light: int = lights[0]
	var waiting: Array = _sparks.get(light, [])
	if waiting.size() >= SPARK_MAX:
		return
	waiting.append({"amount": amount, "source": weakref(source), "until": _now() + SPARK_TIME, "cap": cap})
	_sparks[light] = waiting
	queue_redraw()

# --- The lent cards: "near a Firefly Warden", no Lit and no lights ------------------------------------------------

# The strongest Firefly Warden near `tower` (within NEAR_CELLS on both axes), or null.
func firefly_near(tower):
	var near := NEAR_CELLS * _cell()
	var best = null
	var best_dps := -1.0
	for source in _sources:
		var jar = source.tower
		if source.sprout or not is_instance_valid(jar) or jar == tower:
			continue
		if absf(jar.global_position.x - tower.global_position.x) > near or absf(jar.global_position.y - tower.global_position.y) > near:
			continue
		var dps: float = jar.get_damage() * jar.get_attacks_per_second()
		if dps > best_dps:
			best_dps = dps
			best = jar
	return best

func _near_enemies(at: Vector2, skip: Array) -> Array:
	var near := NEAR_CELLS * _cell()
	var found: Array = _enemies().filter(func(e) -> bool:
		return not skip.has(e) and absf(e.global_position.x - at.x) <= near and absf(e.global_position.y - at.y) <= near)
	found.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
	return found

func _lent_rules(id: int, event, source, enemy, dispel: bool, is_hit: bool, is_bolt: bool, calling: bool = false) -> void:
	var at: Vector2 = enemy.global_position
	var now := _now()
	if is_bolt:
		return  # Chain of Lanterns' bolt half is gone (hard cards 2026-10-16): only Reactions jump (_chain_more)
	var prev: Array = enemy.get_meta(FF_HIT_META, [])  # The Firefly hit before this one: Sparks Fly reads it, so a Jar's hit counts after another Jar's
	if is_firefly(source) and event.kind == &"hit" and (_rule(SPARKS_FLY) or _rule(CHAIN_OF_LANTERNS) or _rule(BRUSHFIRE)):
		enemy.set_meta(FF_HIT_META, [now, weakref(source)])  # Hit by a Firefly Warden (any form) just now: Sparks Fly, Chain of Lanterns, Brushfire
	if not calling and _rule(BRUSHFIRE) and event.tag in BRUSH_TAGS and _firefly_hit_recently(enemy, now):
		_brush_add(event, source, enemy)
	var taken := _taken_by(id) if not _queue.is_empty() else []  # F4 (f1_spec.md): built once, before any lent card queues
	if is_hit:
		if _rule(LENT_CROSSFIRE) and not calling:
			_crossfire(id, event, source, enemy, at, now)
		if _rule(NOTHING_WASTED):
			_nothing_wasted(id, event, source, enemy, at, taken)
		if _rule(FLASHOVER) and not calling:
			_flash_note(event, source, enemy)
		if _rule(SPARKS_FLY):  # Any Warden but the Firefly Warden that started the 2 s (own family too, owner 2026-10-15)
			_sparks_fly(id, event, source, enemy, at, now, prev, taken)
	if _heavy_now:
		# Hammerfall: another family's heavy Warden, or a Sprout, near a Firefly Warden jumps half of each attack
		if _rule(HAMMERFALL) and (is_other_family(source) and is_heavy(source) or source.tower_data.get_id() == "sprout"):
			var jar = firefly_near(source)
			var targets := _fan_out(at, [enemy], taken) if jar != null else []
			if not targets.is_empty():
				_fork(id, source, at, targets[0], event.base * HAMMER_SHARE, _lent_cap(source, jar), {"heavy": true, "credit": HAMMERFALL})  # Sprouts too. No re-jump on a dispel (owner 2026-10-17: Bale-fires / Pyre's verb); an old save holding Knock-On keeps it
		# Thunderstruck: another family's heavy Warden near a Firefly Warden: its hit on a nightmare with a status fans a quarter
		# to up to 4 near it with a status (any family's; trait rework 2026-10-15, was Charged only), 1.5 s of that Firefly's damage at most
		var thunder_jar = null  # A Firefly heavy form is its own Firefly Warden (own family too, owner 2026-10-15)
		# Keyword chips 2026-10-16: any heavy hit (the target needs no status); the fan still goes only to nightmares with one
		if _rule(THUNDERSTRUCK) and is_heavy(source) and (is_firefly(source) or is_other_family(source)):
			thunder_jar = source if is_firefly(source) else firefly_near(source)
		if thunder_jar != null:
			var cap_fan: float = thunder_jar.get_damage() * thunder_jar.get_attacks_per_second() * THUNDER_CAP_SECONDS
			var fan: Array = _with_status(_near_enemies(at, [enemy] + taken)) if not taken.is_empty() else []  # F4: others first
			if fan.is_empty():
				fan = _with_status(_near_enemies(at, [enemy]))
			fan = fan.slice(0, THUNDER_MAX)
			for other in fan:  # The cap covers the whole fan
				_fork(id, source, at, other, minf(event.base * THUNDER_SHARE, cap_fan / maxf(fan.size(), 1.0)), cap_fan, {"heavy": true, "final": true, "credit": THUNDERSTRUCK})  # final: Hammerfall never re-jumps it (council full_review 2026-10-17)
				if _living(other) and not other.statuses.is_boss:
					# Each jump adds 1 Charged, from the Firefly Warden (its bolt, never the heavy Warden's: card pass 2026-10-16)
					SETUP.begin(StringName(SETUP.rule_card(dream_state, THUNDERSTRUCK)))  # Setup credit 2026-10-16
					thunder_jar._apply_one_status(other, EnemyStatuses.STATIC, THUNDER_STATIC, thunder_jar.get_damage(), false)
					SETUP.end()
	# Live Wire and Like to Like: retired (2026-10-13 / earlier); an old save keeps them
	if calling or not is_other_family(source):
		return
	var jar = firefly_near(source)
	if jar == null:
		return
	var cap: float = jar.get_damage() * jar.get_attacks_per_second() * BRIGHTNESS_SECONDS
	if dispel and _rule(LENT_LIVE_WIRE) and not (class_on() and is_lit(enemy)):  # On a Firefly start it replaces the Calling's jump, never adds one
		var targets := _near_enemies(at, [enemy])
		if not targets.is_empty():
			_fork(id, source, at, targets[0], _hit_size(source, is_hit, false) * LIVE_WIRE_SHARE, cap)
			return  # One fork per hit across the three lent cards
	if _rule(LIKE_TO_LIKE) and enemy.statuses.has(EnemyStatuses.STATIC):
		var amount: float = event.base
		if not is_hit:
			if now < float(enemy.get_meta(LIKE_META, -INF)):
				return
			enemy.set_meta(LIKE_META, now + LIKE_TICK_EVERY)
			amount = source.get_damage() * source.get_attacks_per_second()  # That second's damage
		elif not _new_like_hit(source, now):
			return  # A pulse or splash forks once
		for other in _near_enemies(at, [enemy]):
			if other.statuses.has(EnemyStatuses.STATIC):
				_fork(id, source, at, other, amount * LIKE_SHARE, cap)
				break

# Nothing Wasted: the damage a nightmare's shell (the blight coat) soaks up from a hit, by a Firefly Warden or a Warden
# near one, jumps to the nearest nightmare near it without a shell. (Resistances are gone, enemy_design.md ed6f573b:
# it read the resisted part before.)
func _with_status(list: Array) -> Array:
	return list.filter(func(e) -> bool: return e.statuses.count() > 0)

func _nothing_wasted(id: int, event, source, enemy, at: Vector2, taken: Array = []) -> void:
	if event.coat_soaked <= 0.0:
		return
	var jar = source if is_firefly(source) else firefly_near(source)
	if jar == null:
		return
	var others: Array = _near_enemies(at, [enemy] + taken).filter(func(e) -> bool: return float(e.coat) <= 0.0) if not taken.is_empty() else []
	for other in (others if not others.is_empty() else _near_enemies(at, [enemy])):  # F4: other jumps' targets last
		if float(other.coat) <= 0.0:
			_fork(id, source, at, other, event.coat_soaked, _lent_cap(source, jar))
			return

# Sparks Fly: every 3rd hit a Warden (any but the Firefly Warden that started the 2 s; Sprouts and other Firefly Wardens
# count) lands on a nightmare a Firefly Warden hit in the last 2 s jumps on at half. Counted per Warden and nightmare; an
# area attack counts once. `lit` = the Firefly hit before this one (read before _lent_rules records this hit).
func _sparks_fly(id: int, event, source, enemy, at: Vector2, now: float, lit: Array, taken: Array = []) -> void:
	if lit.is_empty() or now - float(lit[0]) > SPARKS_WINDOW or lit[1].get_ref() == source:
		return
	if int(source.get_meta(SPARKS_FRAME_META, -1)) == Engine.get_process_frames():
		return
	source.set_meta(SPARKS_FRAME_META, Engine.get_process_frames())
	var counts: Dictionary = enemy.get_meta(SPARKS_META, {})
	var n := int(counts.get(source.get_instance_id(), 0)) + 1
	counts[source.get_instance_id()] = n % SPARKS_EVERY_HIT
	enemy.set_meta(SPARKS_META, counts)
	if n < SPARKS_EVERY_HIT:
		return
	var targets := _fan_out(at, [enemy], taken)  # F4
	if not targets.is_empty():
		_fork(id, source, at, targets[0], event.base * SPARKS_SHARE, _lent_cap(null, lit[1].get_ref()))  # Capped even from a Firefly Warden, as Chain of Lanterns (council full_review 2026-10-17)

# Flashover: one attack's hits are gathered by Warden and frame; the next frame, an area attack that hit 2 or more
# jumps half (of the largest hit) to the nearest nightmare it missed. Another family's Warden near a Firefly Warden;
# Sparkler and Starburst near another Firefly Warden.
func _flash_note(event, source, enemy) -> void:
	var sid: int = source.get_instance_id()
	var frame := Engine.get_process_frames()
	var entry: Dictionary = _flashes.get(sid, {})
	if entry.is_empty() or int(entry.frame) != frame:
		if not entry.is_empty():
			return  # The last attack's hits are still waiting (struck next frame)
		if is_firefly(source) and not SPARKLERS.has(source.tower_data.get_id()):
			return
		if not is_other(source) and not is_firefly(source):
			return
		entry = {"frame": frame, "source": weakref(source), "hits": [], "base": 0.0}
		_flashes[sid] = entry
	entry.hits.append(weakref(enemy))
	entry.base = maxf(float(entry.base), event.base)

func _flash_over() -> void:
	var frame := Engine.get_process_frames()
	for sid in _flashes.keys():
		var entry: Dictionary = _flashes[sid]
		if int(entry.frame) >= frame:
			continue
		_flashes.erase(sid)
		var source = entry.source.get_ref()
		if not is_instance_valid(source) or entry.hits.size() < FLASHOVER_MIN:
			continue
		var jar = firefly_near(source)
		if jar == null:
			continue
		var hit: Array = []
		var centre := Vector2.ZERO
		for ref in entry.hits:
			var e = ref.get_ref()
			if is_instance_valid(e):
				hit.append(e)
				centre += e.global_position
		if hit.is_empty():
			continue
		centre /= hit.size()
		var targets := _near_enemies(centre, hit)
		if not targets.is_empty():
			_fork(_next_event(), source, centre, targets[0], float(entry.base) * FLASHOVER_SHARE, _lent_cap(null, jar), {"final": true})  # Always capped (council full_review 2026-10-17)

# Brushfire: a Charged nightmare's damage over time this second, by its source.
func _brush_add(event, source, enemy) -> void:
	var key: int = enemy.get_instance_id()
	var entry: Dictionary = _brush.get(key, {"enemy": weakref(enemy), "source": weakref(source), "amount": 0.0})
	entry.amount = float(entry.amount) + event.amount
	_brush[key] = entry

func _brush_fire() -> void:
	var entries := _brush.values()
	_brush.clear()
	for entry in entries:
		var enemy = entry.enemy.get_ref()
		var source = entry.source.get_ref()
		if not _living(enemy) or not is_instance_valid(source):
			continue
		var targets := _near_enemies(enemy.global_position, [enemy])
		if not targets.is_empty():
			var lit: Array = enemy.get_meta(FF_HIT_META, [])
			var cap := _lent_cap(source, lit[1].get_ref() if not lit.is_empty() else null)
			if is_firefly(source):
				cap = _lent_cap(null, source)  # Damage over time is never a Firefly hit: always capped
			_fork(_next_event(), source, enemy.global_position, targets[0], float(entry.amount) * BRUSH_SHARE, cap, {"final": true})

# Whether a Firefly Warden hit `enemy` in the last 2 s (Brushfire).
func _firefly_hit_recently(enemy, now: float) -> bool:
	var lit: Array = enemy.get_meta(FF_HIT_META, [])
	return not lit.is_empty() and now - float(lit[0]) <= SPARKS_WINDOW

func _new_like_hit(source, now: float) -> bool:
	if int(source.get_meta(&"ff_like_frame", -1)) == Engine.get_process_frames():
		return false
	source.set_meta(&"ff_like_frame", Engine.get_process_frames())
	return true

# Crossfire, reworked: a Firefly Warden and another family's Warden near it hit one nightmare within a second.
func _crossfire(id: int, event, source, enemy, at: Vector2, now: float) -> void:
	var firefly := is_firefly(source)
	if not firefly and not is_other_family(source):
		return
	var last: Dictionary = enemy.get_meta(CROSS_META, {})
	if now < float(last.get("wait", -INF)):
		return
	var other = last.get("source").get_ref() if last.has("source") else null
	if is_instance_valid(other) and other != source and now - float(last.at) <= CROSSFIRE_WINDOW and is_firefly(other) != firefly:
		var jar = source if firefly else other
		var partner = other if firefly else source
		var near := NEAR_CELLS * _cell()
		if absf(jar.global_position.x - partner.global_position.x) <= near and absf(jar.global_position.y - partner.global_position.y) <= near:
			var step := _step_of(enemy)
			var behind: Array = _enemies().filter(func(e) -> bool: return e != enemy and _step_of(e) >= 0 and _step_of(e) <= step)
			behind.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
			var amount: float = minf(event.base, float(last.base)) * CROSSFIRE_SHARE
			var cap: float = jar.get_damage() * jar.get_attacks_per_second() * BRIGHTNESS_SECONDS
			for target in behind.slice(0, CROSSFIRE_TARGETS):
				_fork(id, partner, at, target, amount, cap)
			enemy.set_meta(CROSS_META, {"wait": now + CROSSFIRE_WAIT})
			return
	enemy.set_meta(CROSS_META, {"source": weakref(source), "at": now, "base": event.base})  # Stored before defences

# --- Forks ------------------------------------------------------------------------------------------------------

# Queues a fork of `amount` from `from` to `target` for event `id`. `cap`: brightness (INF = none).
func _fork(id: int, source, from: Vector2, target, amount: float, cap: float, opts: Dictionary = {}) -> void:
	if amount <= 0.0 or not _living(target):
		return
	var request := {"event": id, "source": source, "from": from, "target": target, "amount": minf(amount, cap), "cap": cap,
		"heavy": opts.get("heavy", false), "final": opts.get("final", false)}
	for key in opts:  # Evolutions: hops, pyre, relay, swarm, carry, color, width
		if key != "origin":
			request[key] = opts[key]
	if opts.has("origin") and not request.has("carry") and evo(EVO_WAKE):
		request["carry"] = _carry_of(opts.origin)  # Read now: the nightmare it left may be gone by the strike
	if not request.has("jump_from"):  # Keyword chips 2026-10-16: the nightmare it leaves, for DreamState.note_jump
		request["jump_from"] = opts.origin if opts.has("origin") else _nightmare_at(from, target)
	_queue.append(request)

# The nightmare standing at `at` (within half a cell), not `skip`: where a jump leaves from (null if none).
func _nightmare_at(at: Vector2, skip) -> Node2D:
	var best: Node2D = null
	var best_sq := pow(_cell() * 0.5, 2.0)
	for enemy in Tower.nightmares_near(get_tree(), at, _cell() * 0.5):
		if enemy == skip or not is_instance_valid(enemy):
			continue
		var sq: float = enemy.global_position.distance_squared_to(at)
		if sq <= best_sq:
			best_sq = sq
			best = enemy
	return best

# Gathering Storm's count on `target` (DreamState.note_jump): each jump a nightmare takes makes the next one on it 25%
# stronger, up to GATHER_MAX; resets after GATHER_RESET s without one. Returns this jump's multiplier.
static func gather(target: Node2D, now: float) -> float:
	var gathered: Array = target.get_meta(GATHER_META, [0, -INF])
	var taken := int(gathered[0]) if now - float(gathered[1]) <= GATHER_RESET else 0
	target.set_meta(GATHER_META, [taken + 1, now])
	return minf(1.0 + GATHER_STEP * taken, GATHER_MAX)

# One fork per nightmare per event (the largest wins), at most EVENT_MAX per event. A recursive hop (a frame later, same
# event) never strikes a nightmare its event already struck, and the event's total stays within EVENT_MAX.
func _flush() -> void:
	if _queue.is_empty():
		return
	var queue := _queue
	_queue = []
	var by_event := {}
	for request in queue:
		var per_target: Dictionary = by_event.get_or_add(request.event, {})
		var key: int = request.target.get_instance_id() if is_instance_valid(request.target) else 0
		if not per_target.has(key) or per_target[key].amount < request.amount:
			per_target[key] = request
	for id in by_event:
		var requests: Array = by_event[id].values()
		requests.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.amount > b.amount)
		var seen: Dictionary = _event_seen.get_or_add(id, {})
		for request in requests:
			if seen.size() >= EVENT_MAX:
				break
			var key: int = request.target.get_instance_id() if is_instance_valid(request.target) else 0
			if seen.has(key):
				continue
			seen[key] = true
			_strike(request)
	if _event_seen.size() > EVENT_MEMORY:
		for id in _event_seen.keys():
			if int(id) < _event - (EVENT_MEMORY >> 1):
				_event_seen.erase(id)

func _strike(request: Dictionary) -> void:
	var target = request.target
	if not _living(target):
		return
	var source = request.source if is_instance_valid(request.source) else null
	var amount: float = request.amount
	# Keyword chips 2026-10-16: every jump goes through DreamState.note_jump (Gathering Storm's count, Shared Spark). Card
	# pass 2026-10-16 (player review 4.2): Gathering Storm multiplies after the jump's own cap; hard cards 2026-10-16
	# (owner: +200%): the cap stretches with the bonus, never past GATHER_MAX times its value
	var from_enemy = request.get("jump_from")
	var gather_mult: float = dream_state.note_jump(source, from_enemy if is_instance_valid(from_enemy) else null, target, amount) \
		if dream_state != null else 1.0
	if gather_mult > 1.0:
		amount = minf(amount * gather_mult, float(request.cap) * gather_mult)
		var taken := roundi((gather_mult - 1.0) / GATHER_STEP)
		request["width"] = maxf(float(request.get("width", 4.0)), 4.0 + GATHER_WIDTH_STEP * mini(taken, GATHER_WIDTH_MAX))
	if not _living(target):
		return  # (Shared Spark's stack can complete a Reaction that dispels it)
	if target.enemy_data != null and target.enemy_data.is_boss:
		amount *= BOSS_SHARE
	var at: Vector2 = target.global_position
	var bolt := ChainBolt.new(PackedVector2Array([request.from, at]), request.get("color", Palette.GOLD), float(request.get("width", 4.0)))
	Reactions._world(self).add_child(bolt)
	forks_thrown += 1
	var evolved := _evolved()
	var before: Array = _lit_sources(target) if evolved else []  # Read before the hit: a dispelled nightmare leaves the light
	var step := _step_of(target) if evolved else -1
	var had: Array = _carry_of(target) if evolved and evo(EVO_WAKE) else []
	var own: StringName = request.get("credit", &"")  # Setup credit 2026-10-16: the evolution or card this jump is (its own damage)
	if own != &"" and dream_state != null:
		dream_state.begin_own_hit(own, target)
	if request.get("calling", false) and class_on():
		DamageLog.calling_next = StringName(FAMILY)  # F1 (f1_spec.md): armed just before; take_damage takes it on entry
	target.take_damage(amount, source.tower_data.line if source is Tower else LINE, false, false, source, FORK_TAG)
	DamageLog.calling_next = &""
	if own != &"" and dream_state != null:
		dream_state.end_own_hit()
	if own == EVO_TORCH or own == EVO_BALE:
		credit(own, at, source)  # The callout once the throw has landed (council full_review 2026-10-17)
	var carry: Array = request.get("carry", [])
	if not carry.is_empty() and _living(target):
		_wake(target, carry, request.from)
	if evolved:
		_evolved_strike(request, source, target, at, before, step, had)
	# A nightmare dispelled by a fork gives no fork. Knock-On is the one exception: a heavy Warden's fork, one more hop.
	if request.get("heavy", false) and not request.get("final", false) and _rule(KNOCK_ON) and not _living(target):
		var next := _near_enemies(at, [target]).slice(0, 1)
		if not next.is_empty():
			var hop := request.duplicate()
			hop.from = at
			hop["jump_from"] = target  # Keyword chips 2026-10-16: it leaves the nightmare just struck
			hop["credit"] = KNOCK_ON  # Setup credit 2026-10-16
			hop["calling"] = false  # (F1: a lent card's hop is never a Calling output)
			hop.target = next[0]
			hop.final = true  # The second fork never forks again and takes no leftover
			_strike(hop)

# --- Fireflies in the Grass: the Sprouts the player chose to glow (the Warden panel's button) ---------------------

# "" = this Sprout can be made to glow now; else why not.
func lit_sprout_blocker(sprout) -> String:
	if not class_on() or not _rule(LIT_SPROUTS):
		return "needs Fireflies in the Grass"
	if not (sprout is Tower) or sprout.tower_data.get_id() != "sprout":
		return "only a Sprout can glow"
	if not _resting():
		return "choose at a rest"  # Never mid-drift: a light moved to chase a pack (dream_council_review.md 26, fix 12)
	if sprout.get_meta(LIT_SPROUT_META, false):
		return ""
	var jars := 0
	var lit := 0
	for tower in _towers():
		if is_firefly(tower):
			jars += 1
			if tower.global_position.distance_to(sprout.global_position) <= glow_reach(tower):
				return "already inside a Firefly Warden's glow"
		elif tower.get_meta(LIT_SPROUT_META, false):
			lit += 1
	if lit >= jars:
		return "one glowing Sprout for each Firefly Warden"
	return ""

func _resting() -> bool:
	return dream_state == null or dream_state.get("drift_director") == null or dream_state.drift_director.resting

func set_lit_sprout(sprout, on: bool) -> bool:
	if on and lit_sprout_blocker(sprout) != "":
		return false
	if not on and not _resting():
		return false  # Chosen at a rest only, either way
	if on:
		sprout.set_meta(LIT_SPROUT_META, true)
	elif sprout.has_meta(LIT_SPROUT_META):
		sprout.remove_meta(LIT_SPROUT_META)
	_rebuild()
	return true

# Saved with the run (DreamState.to_save): the cells of the glowing Sprouts.
func to_save() -> Array:
	var cells: Array = []
	for tower in _towers():
		if tower.get_meta(LIT_SPROUT_META, false):
			cells.append([tower.cell.x, tower.cell.y])
	return cells

func load_save(cells: Array) -> void:
	for tower in _towers():
		for saved in cells:
			if saved is Array and saved.size() == 2 and tower.cell.is_equal_approx(Vector2(saved[0], saved[1])) \
					and tower.tower_data.get_id() == "sprout":
				tower.set_meta(LIT_SPROUT_META, true)
	_rebuild_in = 0.0

# --- Drawing: the glow on the path, gold where two Firefly Wardens' glows cross, and waiting sparks ----------------

# The glow is a soft band along the path's own line (user 2026-10-13, "fix the lit area": it was a flat square per lit
# cell, centred on whole cells while the path is a half-cell lane, so pale squares with gaps sat on the grass beside
# it). Each lit stretch of the route is three nested round-jointed lines (GLOW_BANDS: wide and dim to narrow and
# bright), so it fades out in three steps with no grid. Gold path is its own stretch, joined end to end.
# One group, one cap (user, the same day, a 102-Warden maze at drift 35: "large and bright, several cells wide ...
# stepped blocks ... the main thing on screen"): the first version added every band and every stretch on top of the
# others, 80 px wide, so close lanes merged into bright slabs. Now the lines are opaque inside one CanvasGroup (a
# brighter band covers a dimmer one, lanes side by side just meet) and the group is added to the map once at
# GLOW_CAP: nowhere is brighter than one lit path's centre, however the maze winds. The bands hug the path's ribbon
# (~40 px) with a few pixels of soft edge.
const GLOW_BANDS: Array[float] = [52.0, 40.0, 26.0]  # px wide, widest first
const GLOW_SHARES: Array[float] = [0.25, 0.5, 0.75]  # Each band's share of GLOW_CAP: a lit path's centre adds 0.75 × the cap
const GOLD_SHARES: Array[float] = [0.35, 0.7, 1.0]  # Gold path: the full cap at its centre
const GLOW_CAP := 0.55  # The most light the glow ever adds (the group's alpha). Owner 2026-10-14 "too faint": was 0.34 (a lit centre ~0.22, now ~0.41)
const GLOW_SHADER := "shader_type canvas_item;\nrender_mode unshaded, blend_add;\nuniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;\nvoid fragment() {\n\tvec4 c = textureLod(screen_texture, SCREEN_UV, 0.0);\n\tif (c.a > 0.0001) {\n\t\tc.rgb /= c.a;\n\t}\n\tCOLOR *= c;\n}\n"
var _glow_lines: Array[Line2D] = []
var _glow_group: CanvasGroup  # Every glow line, flattened, then added to the map once (kept on this node, never static)

func _draw() -> void:
	_lay_glow.call_deferred()  # Lines are nodes: laid after the draw, whenever anything here asked for a redraw
	if not _lit_on():
		return
	for light in _sparks:
		var spot := _light_spot(int(light))
		for i in _sparks[light].size():
			draw_circle(to_local(spot) + Vector2(-10 + 10 * i, -14), 3.0, Color(Palette.HEARTLIGHT, 0.9))
	# Embers / Witchfire: glowing coals on the path, one per ember in the pile
	for step in _embers:
		if not _step_px.has(int(step)):
			continue
		var coal := to_local(_step_px[int(step)])
		var count := int(_embers[step].count)
		for i in count:
			var offset := Vector2(-6.0 * (count - 1) + 12.0 * i, 0.0)
			draw_circle(coal + offset, 6.0, Color(Palette.EMBER, 0.85))
			draw_circle(coal + offset, 3.0, Color(Palette.GOLD, 0.95))
	# Glowworms: a lantern spark at the foot of each glowing Sprout
	for source in _sources:
		if source.get("worm", false) and is_instance_valid(source.tower):
			draw_circle(to_local(source.tower.global_position) + Vector2(14, 18), 4.0, Color(Palette.GLOW, 0.9))

func _exit_tree() -> void:
	if is_instance_valid(_glow_group):
		_glow_group.queue_free()
	_glow_group = null
	_glow_lines.clear()

func _lay_glow() -> void:
	for line in _glow_lines:
		if is_instance_valid(line):
			line.queue_free()
	_glow_lines.clear()
	if not _lit_on() or _glow.is_empty() or dream_state.get("map_generator") == null:
		if is_instance_valid(_glow_group):
			_glow_group.visible = false
		return
	var map: Node2D = dream_state.map_generator
	if not is_instance_valid(_glow_group):
		_glow_group = CanvasGroup.new()
		_glow_group.name = "FireflyGlow"
		_glow_group.fit_margin = 32.0
		_glow_group.clear_margin = 32.0
		var shader := Shader.new()
		shader.code = GLOW_SHADER
		var material := ShaderMaterial.new()
		material.shader = shader
		_glow_group.material = material
		_glow_group.self_modulate = Color(1, 1, 1, GLOW_CAP)  # multiplier: the cap on the added light
		map.path_layer.add_child(_glow_group)  # On the path layer: over the path's ribbon, under everything else
	_glow_group.visible = true
	var ground: Node2D = _glow_group
	var runs: Array = []  # [points, bright, joins_before, joins_after] per lit stretch
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var gold := _rule(WHERE_LIGHTS_MEET) or evo(EVO_BONFIRE)
	var states := PackedInt32Array()  # Per route point: 0 dark, 1 glow, 2 gold path
	for point in route:
		var state := 0
		for cell in dream_state.route_cells(point):
			if _glow.has(cell):
				state = maxi(state, 2 if gold and int(_glow[cell].jars) >= 2 else 1)
		states.append(state)
	var from := 0
	while from < route.size():
		if states[from] == 0:
			from += 1
			continue
		var to := from
		while to + 1 < route.size() and states[to + 1] == states[from]:
			to += 1
		# Where the glow goes on as gold (or the other way), the stretches share the point between them: no gap, no cap
		var joins_before := from > 0 and states[from - 1] != 0
		var joins_after := to + 1 < route.size() and states[to + 1] != 0
		var points := PackedVector2Array()
		for i in range(from, mini(to + 1 if joins_after else to, route.size() - 1) + 1):
			points.append(ground.to_local(map.to_global(Tower.MAP_GRID.calculate_map_position(route[i]))))
		if points.size() == 1:
			points.append(points[0] + Vector2(0.5, 0.0))  # One lit point: a round spot
		runs.append([points, states[from] == 2, joins_before, joins_after])
		from = to + 1
	# Band by band over every stretch, dimmest first: a lane's bright centre is never covered by its neighbour's edge
	for band in GLOW_BANDS.size():
		for run: Array in runs:
			var share: float = GOLD_SHARES[band] if run[1] else GLOW_SHARES[band]
			var base: Color = Palette.GOLD if run[1] else Palette.GLOW
			var line := Line2D.new()
			line.points = run[0]
			line.width = GLOW_BANDS[band]
			line.default_color = Color(base.r * share, base.g * share, base.b * share, 1.0)  # multiplier: the band's share of the light (opaque in the group)
			line.joint_mode = Line2D.LINE_JOINT_ROUND
			line.begin_cap_mode = Line2D.LINE_CAP_NONE if run[2] else Line2D.LINE_CAP_ROUND
			line.end_cap_mode = Line2D.LINE_CAP_NONE if run[3] else Line2D.LINE_CAP_ROUND
			line.round_precision = 6
			line.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			ground.add_child(line)
			_glow_lines.append(line)

func _light_spot(light: int) -> Vector2:
	for source in _sources:
		if int(source.light) == light and is_instance_valid(source.tower):
			return source.tower.global_position
	return Vector2.ZERO
