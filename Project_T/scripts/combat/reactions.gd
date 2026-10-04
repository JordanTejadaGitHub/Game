extends RefCounted
class_name Reactions

# Reactions (tower_design.md "Reactions: combos you can see"; numbers in dream_design.md "Reaction
# numbers"): when two statuses meet on one nightmare, a named event goes off. Enemy.apply_status calls
# on_status() after every status lands; Tower.hit calls before_hit() (Shatter, Pinned); Static bolts
# go through strike_bolt() (Lightning Rod). Reaction damage scales with the applier's damage, counts
# as its family, and never crits. Each type fires on a nightmare at most once per cooldown.
#
# Chains: a Reaction's output (damage, statuses, clouds) marks the nightmares it touches; a Reaction
# on a marked nightmare within CHAIN_WINDOW is the chain's next link. ReactionTracker counts them and
# tells the UI; the visuals are played through scripts/fx/fx.gd when it exists.

const DIR := "res://resource/reaction/"
const CELL := 64.0
const CHAIN_WINDOW := 1.0

const DAMP := &"damp"
const DROWSY := &"drowsy"
const SPORED := &"spored"
const MARKED := &"marked"
const STATIC := &"static"
const HELD := &"held"

const THUNDERCLAP_STATIC := 3
const THUNDERCLAP_STATIC_BOSS := 5
const THUNDERCLAP_DAMAGE := 4.0  # × the applier's damage, to the nightmare that discharges
const THUNDERCLAP_ARC_DAMAGE := 2.0  # × the applier's damage, to each wet nightmare it arcs to
const THUNDERCLAP_MAX_ARCS := 8
const ROLLING_THUNDER_ARCS := 3  # Rolling Thunder: its longer arcs strike at most this many
const THUNDERCLAP_REACH: Array[float] = [2.5, 3.5, 4.5]  # Cells: base, Rolling Thunder, Rolling Thunder II
const THUNDERCLAP_ARC_STATIC: Array[int] = [1, 1, 2]
const IGNITE_MIN_SPORES := 3
const BURN_TIME := 3.0  # Ignite: seconds the spores burn
const BURN_SPORE_RATE := 3.0  # Spored ticks this many times as fast while burning
const IGNITE_SPREAD: Array[int] = [1, 2]  # Stacks: base, Wildfire Spores
const IGNITE_REACH: Array[float] = [1.0, 1.5]
const MUSHROOM_MIN_SPORES := 3
const MUSHROOM_TIME := 4.0
const MUSHROOM_CLOUD_RADIUS := 0.6  # Cells
const MUSHROOM_CLOUD_TIME := 4.0
const MUSHROOM_RAIN_TIME := 0.5  # Mushroom Rain: half the duration…
const MUSHROOM_RAIN_RADIUS := 1.5  # …and the 3×3 around its tile (cells from the centre, reaching the corners' middles)
const SHATTER_MULTIPLIER := 2.5
const SHATTER_SPLASH := 0.5  # Share of the hit the shards deal within 1 cell
const PULL_UNDER_TIME: Array[float] = [3.0, 4.0]  # Drown: seconds pulled under (base, Deep Water)
const PULL_UNDER_SLOW := 0.6
const PULL_UNDER_BOSS_SLOW: Array[float] = [0.3, 0.4]  # Bosses (base, Deep Water)
const PULL_UNDER_STEP := 0.5  # Drowning damage in second n: n × this × the applier's damage
const DEEP_WATER_GROWTH := 1.5  # Deep Water: the damage grows 50% faster
const DROWN_TIMES: Array[int] = [1, 1, 2]  # Per nightmare: base, Deep Water, Deep Water II
const DEEP_WATER_REACH := 5.0  # Cells from the Heartwood (straight line) where Deep Water works
const PINNED_MULTIPLIER := 3.0
const ROD_REACH := 3.0  # Cells
const ROD_MULTIPLIER := 2.0
const QUICK_COOLDOWN := 0.75  # Quick Reactions
const DAWNBURST_CHAIN := 10
const DAWNBREAK_SHARE := 0.10  # Of max health, to every nightmare within DAWNBREAK_REACH
const DAWNBREAK_BOSS_SHARE := 0.02
const DAWNBREAK_REACH := 4.0

# Crowned Reactions (tower_design.md "Crowned Reactions", dream_design.md "Crowned Reaction numbers"):
# a Reaction on a nightmare that already carries a third status is replaced by a bigger one. It
# shares the base Reaction's cooldown and counts as 2 chain links. [base, Woven card] pairs.
const CROWNED_LINKS := 2
const TEMPEST_LOCK := 2.0  # A nightmare hit by a Tempest can't start another for this long
const TEMPEST_EXTRA_REACH := 1.0  # Eye of the Tempest: cells
const STILL_POOL_TIME: Array[float] = [5.0, 8.0]  # Deep Stillness
const STILL_POOL_SLEEP: Array[float] = [1.0, 1.5]
const FEVER_SLEEP := 2.0  # Fever Dream: seconds Asleep
const FEVER_SPORED := 3
const FEVER_DROWSY := 2
const FEVER_BOSS_DROWSY_CAP := 3
const FEVER_REACH: Array[float] = [1.0, 1.5]  # Fever Pitch
const STARFALL_REACH: Array[float] = [3.0, 5.0]  # Falling Stars
const STARFALL_BOLT := 2.0  # Each pulled bolt ×2, and a crit
const STARFALL_BOSS_BOLT := 1.5
const PRISM_STATIC: Array[int] = [2, 3]  # Prism Heart
const PRISM_REACH: Array[float] = [1.0, 1.5]
const NIGHTBLOOM_TIME: Array[float] = [4.0, 7.0]  # Endless Night
const NIGHTBLOOM_WIDTH: Array[float] = [1.0, 1.5]
const FAIRY_RING_TIME := 6.0
const FAIRY_RING_MAX := 8  # Ring of Rings: rings last until stepped on, at most this many
const STORM_FRONT_REACH := 1.0  # Cells added to a Reaction a Gust-copied status completed
const STORM_FRONT_SECONDS := 0.8  # How long the swirl shows
const CARRIED_SHARE := 0.5  # Carried Storm: a Samara seed repeats a Reaction it passes through at 50%
const CARRIED_WINDOW := 0.5  # Seconds after the Reaction
const CARRIED_REACH := 0.75  # Cells from the Reaction's spot
# The base Reaction each Crowned one replaces (the Codex, sounds and cooldowns use it).
const CROWNED_BASE := {&"tempest": &"thunderclap", &"still_pool": &"drown", &"fever_dream": &"smother",
	&"starfall": &"pinned", &"avalanche": &"shatter", &"prismstorm": &"shatter", &"nightbloom": &"mushrooming",
	&"fairy_circle": &"mushrooming"}
# Each Crowned Reaction's Woven card (its cost: that Crowned Reaction's cooldown ×WOVEN_COOLDOWN).
const WOVEN_RULE := {&"tempest": &"eye_of_the_tempest", &"still_pool": &"deep_stillness", &"fever_dream": &"fever_pitch",
	&"starfall": &"falling_stars", &"avalanche": &"mountains_fall", &"prismstorm": &"prism_heart", &"nightbloom": &"endless_night",
	&"fairy_circle": &"ring_of_rings"}
const WOVEN_COOLDOWN := 2.0

# Reaction id -> its resource path (not the resource: a static holding Resources at exit can crash the
# engine's teardown, the exit-crash hunt). load() hits ResourceLoader's cache after the first time.
static var _data := {}


# --- Data -------------------------------------------------------------------------------------------

static func get_data(id: StringName) -> ReactionData:
	_load()
	return load(_data[id]) as ReactionData if _data.has(id) else null

# The base Reactions (the Crowned ones are separate: crowned()).
static func all() -> Array[ReactionData]:
	_load()
	var list: Array[ReactionData] = []
	for id in _data:
		if not is_crowned(id):
			list.append(load(_data[id]) as ReactionData)
	return list

# The Crowned Reactions (resource/reaction/crowned/).
static func crowned() -> Array[ReactionData]:
	_load()
	var list: Array[ReactionData] = []
	for id in _data:
		if is_crowned(id):
			list.append(load(_data[id]) as ReactionData)
	return list

static func _load() -> void:
	if not _data.is_empty():
		return
	for dir in [DIR, DIR + "crowned/"]:
		for file in ResourceLoader.list_directory(dir):
			if file.ends_with(".tres") or file.ends_with(".res"):
				var data := load(dir + file) as ReactionData
				if data != null:
					_data[data.id] = data.resource_path


# --- Triggers ---------------------------------------------------------------------------------------

# A status just landed on `enemy` (applied by `source`, a Warden or null). Checks every Reaction.
# Performance (platforms.md budget at 1x): area statuses (Mushrooming clouds, pulses) call this for every
# nightmare they touch, 200-300 times in one frame. Every Reaction needs two statuses, so a nightmare with
# fewer can't set one off; and within a frame a nightmare with the same status at the same stacks gives
# the same answer, so repeats are skipped.
static var _checked_frame := -1
static var _checked := {}  # "enemy id:status:stacks" -> true, this frame

# Reactions need a grown Warden (tower_design.md "Reactions"): at least one of a Reaction's statuses must
# come from a branch or final form (tier 2+). Base Wardens still apply statuses but never react. A status
# whose source isn't a Warden (a Dream, another Reaction) doesn't block it. Crowned follow their base.
static func grown(s: EnemyStatuses, ids: Array) -> bool:
	for id in ids:
		if not s.has(id) and not (id == HELD and s.is_held()):
			continue
		var who: Node = s.source(id)
		if not (who is Tower) or who.tower_data.tier >= 2:
			return true
	return false

static func on_status(enemy: Node2D, _id: StringName, source: Node) -> void:
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	var s: EnemyStatuses = enemy.statuses
	if s.count() < 2:
		return
	var frame := Engine.get_process_frames()
	if frame != _checked_frame:
		_checked_frame = frame
		_checked.clear()
	var key := "%d:%s:%d:%d" % [enemy.get_instance_id(), _id, s.stacks(_id), s.count()]
	if _checked.has(key):
		return
	_checked[key] = true
	var static_needed := THUNDERCLAP_STATIC_BOSS if s.is_boss else THUNDERCLAP_STATIC
	if s.has(DAMP) and s.stacks(STATIC) >= static_needed and grown(s, [DAMP, STATIC]):
		_thunderclap(enemy, source)
	if enemy.is_cleansed:
		return
	if s.stacks(SPORED) >= IGNITE_MIN_SPORES and s.has(STATIC) and grown(s, [SPORED, STATIC]):
		_ignite(enemy, source)
	if enemy.is_cleansed:
		return
	if s.stacks(SPORED) >= MUSHROOM_MIN_SPORES and s.has(DAMP) and grown(s, [SPORED, DAMP]):
		_mushrooming(enemy, source)
	if s.has(DAMP) and s.has(DROWSY) and s.stacks(DROWSY) >= s.get_max_stacks(DROWSY) and grown(s, [DAMP, DROWSY]):
		_drown(enemy, source)
	if s.has(MARKED) and (s.is_held() or is_asleep(enemy) \
			or (s.has(DROWSY) and s.stacks(DROWSY) >= s.get_max_stacks(DROWSY))) and grown(s, [MARKED, HELD, DROWSY]):
		_pinned(enemy, source)
	if s.is_held() and s.has(SPORED) and grown(s, [HELD, SPORED]):
		_smother(enemy, source)

# --- Potency (tower_design.md "Potency: effect damage") ---------------------------------------------

# Damage tags that are effects, not hits: they scale with the source Warden's Potency (and Seeping),
# never with crit (except Nightshade). Shatter's own hit is a hit; its spreads are effects.
const EFFECT_TAGS: Array[StringName] = [&"spored", &"static", &"thunderclap", &"ignite", &"lightning_rod",
	&"popped", &"echo", &"carried_storm", &"avalanche", &"starfall", &"fever_dream", &"fog", &"cloud", &"harmony", &"last_breath", &"drown",
	&"lingering_splash", &"thorns", &"rain"]  # thorns: Thorncoil; rain: Cloudlet / Nimbus (BranchKit)

static func is_effect(tag: StringName) -> bool:
	return tag in EFFECT_TAGS

# Chain falloff (tower_design.md "Chain falloff", 2026-09-30): from the 6th link of a chain, each
# Reaction deals 15% less than the one before (6th ×0.85, 7th ×0.70 …), never below 25%. Read off the
# nightmare's chain mark (_fire sets it before the Reaction deals its damage). Chain counts, discoveries
# and Dawnbreak still count every link; Dawnbreak's own damage isn't reduced. Enemy.take_damage asks.
const CHAIN_FALLOFF_FROM := 6
const CHAIN_FALLOFF_STEP := 0.15
const CHAIN_FALLOFF_FLOOR := 0.25
const CHAIN_FALLOFF_TAGS: Array[StringName] = [&"thunderclap", &"ignite", &"shatter", &"pinned", &"lightning_rod",
	&"echo", &"carried_storm", &"avalanche", &"starfall", &"fever_dream", &"drown"]

static var chain_falloff_on := true  # Balance sims: --no-falloff measures without it

static func chain_falloff(enemy: Node2D, tag: StringName) -> float:
	if not chain_falloff_on or not tag in CHAIN_FALLOFF_TAGS:
		return 1.0
	var s: EnemyStatuses = enemy.statuses
	return chain_falloff_at(s.chain_count if s.chain_time > 0.0 else 1)

# The falloff for link `chain` of a chain (1.0 up to the 5th).
static func chain_falloff_at(chain: int) -> float:
	if chain < CHAIN_FALLOFF_FROM:
		return 1.0
	return maxf(1.0 - CHAIN_FALLOFF_STEP * (chain - CHAIN_FALLOFF_FROM + 1), CHAIN_FALLOFF_FLOOR)

# Effect damage × the source's Potency × Seeping (1 + 5% per status the nightmare carries).
static func effect_multiplier(enemy: Node2D, source: Tower) -> float:
	var multiplier := source.get_potency()
	var dreams := _dreams(enemy)
	if dreams and dreams.has_method("get_effect_bonus"):
		multiplier *= 1.0 + dreams.get_effect_bonus(enemy) + nightshade_bonus(enemy)  # Seeping + Nightshade add
	elif dreams:
		multiplier *= 1.0 + nightshade_bonus(enemy)
	return multiplier

# Nightshade (Legendary #112): effect damage +20% for every status the nightmare carries (one per
# status, not per stack; every status counts, the one dealing the damage too; no cap). Adds with
# Seeping. 0 without the card. Also shown on the nightmare's info card.
const NIGHTSHADE_PER_STATUS := 0.20

static func nightshade_bonus(enemy: Node2D) -> float:
	var dreams := _dreams(enemy)
	if dreams == null or not dreams.has_rule(&"nightshade"):
		return 0.0
	return NIGHTSHADE_PER_STATUS * enemy.statuses.active_ids().size()

static func is_crowned(id: StringName) -> bool:
	return CROWNED_BASE.has(id)

# Fever Dream: Smother just ended on a nightmare at full Drowsy. Its remaining Spored damage resolves
# at once, and adjacent nightmares get Spored + Drowsy (a sleep plague).
static func on_smother_ended(enemy: Node2D) -> void:
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	var s: EnemyStatuses = enemy.statuses
	if not s.has(SPORED) or not s.has(DROWSY) or s.stacks(DROWSY) < s.get_max_stacks(DROWSY):
		return
	var spore_source := s.source(SPORED)
	var chain := _fire(enemy, &"fever_dream", _towers(spore_source, s.source(DROWSY)), false, CROWNED_LINKS)
	if chain <= 0:
		return
	var potency := s.potency(SPORED)
	var line := s.spore_line()
	var dreams := _dreams(enemy)
	var level := 1 if dreams and dreams.has_rule(&"fever_pitch") else 0
	var neighbours := _others_within(enemy, FEVER_REACH[level] + _storm_front(enemy))
	# Status jobs (2026-09-29): no detonation. The nightmare falls Asleep (not bosses); its neighbours
	# catch the fever.
	if not s.is_boss:
		var was_asleep := s.is_asleep()
		s.sleep(FEVER_SLEEP)
		var singer := _tower_of(s.source(DROWSY), spore_source)
		if singer != null and not was_asleep:
			singer.put_to_sleep.emit(singer, enemy)  # Sound: the sleep drone
	for other in neighbours:
		if not is_instance_valid(other) or other.is_cleansed:
			continue
		_touch(other, chain, _towers(spore_source))
		other.apply_status(SPORED, FEVER_SPORED, 0.0, potency, 0, line, spore_source)
		if is_instance_valid(other) and not other.is_cleansed:
			var cap := FEVER_BOSS_DROWSY_CAP if other.statuses.is_boss else 0
			other.apply_status(DROWSY, FEVER_DROWSY, 0.0, 0.0, cap, "song", s.source(DROWSY))

# True if `enemy` can't be Held right now: immune, or a Night Hound sprinting (Enemy.apply_status refuses
# HELD then). Drown, Still Pool and Carried Storm slow it instead.
static func cant_be_held(enemy: Node2D) -> bool:
	if HELD in enemy.statuses.immune:
		return true
	return enemy.rolling and HELD in enemy.enemy_data.immune_while_sprinting

static func is_asleep(enemy: Node2D) -> bool:
	return enemy.statuses.is_asleep()

# Heavy Eyelids: Drowsy cap +2 (Heavy Eyelids II: +3), bosses +1.
# Heartwood's Gift Bramble Verge: +1 more for a nightmare touching a Thornwall (GiftGround).
static func drowsy_cap_bonus(enemy: Node2D) -> int:
	var gifts := GiftGround.active_for(enemy)
	var gift := gifts.drowsy_cap_bonus(enemy) if gifts else 0
	var dreams := _dreams(enemy)
	if dreams == null or not dreams.has_rule(&"heavy_eyelids"):
		return gift
	if enemy.enemy_data.is_boss:
		return 1 + gift
	return (3 if dreams.rule_level(&"heavy_eyelids") > 0 else 2) + gift

# Before a Warden's hit: Pinned turns it into a ×3 crit, and Shatter (Held + Damp, hit by a crit or
# a heavy hitter) makes it ×2.5. Returns {"crit", "crit_multiplier", "multiplier", "shatter", "tag"}.
static func before_hit(enemy: Node2D, tower: Tower, is_crit: bool) -> Dictionary:
	var result := {"crit": is_crit, "crit_multiplier": tower.attack_data.crit_multiplier, "multiplier": 1.0,
		"shatter": false, "tag": &""}
	var s: EnemyStatuses = enemy.statuses
	if s.pinned:
		s.pinned = false
		result.crit = true
		result.crit_multiplier = maxf(PINNED_MULTIPLIER, tower.attack_data.crit_multiplier)
		result.tag = &"pinned"
		if s.has(STATIC):
			_starfall(enemy, tower)
	var heavy: bool = tower.tower_data.line == "stone" or tower.attack_data.has_target_priority
	if s.is_held() and s.has(DAMP) and (result.crit or heavy) and grown(s, [HELD, DAMP]):
		# Crowned: a lob's Shatter becomes an Avalanche, a charged one a Prismstorm.
		var id := &"shatter"
		if tower.attack_data.lob:
			id = &"avalanche"
		elif s.has(STATIC):
			id = &"prismstorm"
		var crowned := id != &"shatter"
		if _fire(enemy, id, [tower], false, CROWNED_LINKS if crowned else 1, &"shatter") > 0:
			s.remove(HELD)
			result.multiplier = SHATTER_MULTIPLIER
			result.shatter = true
			result.tag = &"shatter"
			s.prism_pending = id == &"prismstorm"
			if id == &"avalanche" and not s.is_boss:
				_avalanche(enemy, tower)
	return result

# Starfall (Pinned + Static): Static bolts from nightmares within 3 cells (the Pinned one too) all fall
# into it at once, each ×2 and a crit, using up their Static.
static func _starfall(enemy: Node2D, tower: Tower) -> void:
	var s: EnemyStatuses = enemy.statuses
	var chain := _fire(enemy, &"starfall", _towers(tower, s.source(STATIC)), false, CROWNED_LINKS)
	if chain <= 0:
		return
	var dreams := _dreams(enemy)
	var level := 1 if dreams and dreams.has_rule(&"falling_stars") else 0
	var reach := (STARFALL_REACH[level] + _storm_front(enemy)) * CELL
	var multiplier := STARFALL_BOSS_BOLT if s.is_boss else STARFALL_BOLT
	var charged := _field(enemy).filter(func(e: Node2D) -> bool:
		return e.statuses.has(STATIC) and e.global_position.distance_to(enemy.global_position) <= reach)
	for other in charged:
		var bolt: float = other.statuses.potency(STATIC) * EnemyStatuses.STATIC_BOLT_MULTIPLIER * multiplier
		var applier := _tower_of(other.statuses.source(STATIC), tower)
		other.statuses.remove(STATIC)
		if other != enemy:
			_segment(&"thunderclap_arc", other.global_position, enemy.global_position, enemy, 0.3)
		if is_instance_valid(enemy) and not enemy.is_cleansed:
			enemy.take_damage(_rx(enemy, bolt), "light", false, true, applier, &"starfall")

# Avalanche (a lob's Shatter): every Damp + Held nightmare under the lob Shatters too (×2.5 of the
# lobber's hit). Mountain's Fall: rubble where each spread Shatter lands.
static func _avalanche(enemy: Node2D, tower: Tower) -> void:
	var reach := maxf(tower.get_splash_cells(), 1.0) * CELL
	var dreams := _dreams(enemy)
	var rubble: Array[Vector2] = []
	for other in _field(enemy):
		if other == enemy or other.global_position.distance_to(enemy.global_position) > reach:
			continue
		var o: EnemyStatuses = other.statuses
		if not (o.is_held() and o.has(DAMP)):
			continue
		o.remove(HELD)
		_touch(other, o.chain_count if o.chain_time > 0.0 else 1, [tower])
		_effect(&"shatter", other.global_position, enemy)
		other.take_damage(_rx(other, tower.get_damage() * SHATTER_MULTIPLIER), tower.tower_data.line, true, false, tower,
			&"avalanche")
		if is_instance_valid(other):
			rubble.append(Tower.MAP_GRID.calculate_grid_coordinates(other.global_position))
	if dreams and dreams.has_rule(&"mountains_fall") and not rubble.is_empty():
		var world := _world(enemy)
		if world:
			world.add_child(RubblePatch.new(rubble, 0.25, 3.0))

# After a Shatter hit that dealt `dealt`: ice shards deal half of it to nightmares within 1 cell.
static func shatter_splash(enemy: Node2D, tower: Tower, dealt: float) -> void:
	var chain: int = enemy.statuses.chain_count if enemy.statuses.chain_time > 0.0 else 1
	# Prismstorm: the shards carry lightning (2 Static each; Prism Heart: 3, and 0.5 cells further).
	var prism: bool = enemy.statuses.prism_pending
	enemy.statuses.prism_pending = false
	var dreams := _dreams(enemy)
	var level := 1 if prism and dreams and dreams.has_rule(&"prism_heart") else 0
	var reach := (PRISM_REACH[level] if prism else 1.0) + _storm_front(enemy)
	for other in _others_within(enemy, reach):
		_touch(other, chain, [tower])
		other.take_damage(_rx(other, dealt * SHATTER_SPLASH), tower.tower_data.line, true, false, tower, &"shatter")
		if prism and is_instance_valid(other) and not other.is_cleansed:
			other.apply_status(STATIC, PRISM_STATIC[level], 0.0, tower.get_damage(), 0, "light", tower)

# A Static bolt worth `damage` goes off on `target` (a 5-stack bolt, or a Thunderclap arc). A Marked,
# charged nightmare within 3 cells takes it instead at ×2 (Lightning Rod). Returns who was struck.
static func strike_bolt(target: Node2D, damage: float, tower: Node, tag: StringName = &"static") -> Node2D:
	if tag == &"static":
		var dreams := _dreams(target)
		if dreams != null and dreams.has_method("get_bolt_multiplier"):
			damage *= dreams.get_bolt_multiplier()  # Live Wire (Dream): Charged bolts +15% per stack
		var gifts := GiftGround.active_for(target)
		if gifts:
			damage *= gifts.bolt_multiplier(target.global_position)  # Heartwood's Gift Lightning Tree: +25% within 2 cells
	var rod := _find_rod(target)
	if rod == null:
		var at := target.global_position
		var tracker := ReactionTracker.find(target) if tag == &"static" else null  # Found first: the bolt may dispel it
		target.take_damage(damage if tag == &"static" else _rx(target, damage), "light", false, false, tower, tag)  # A Charged bolt isn't a Reaction
		if tag == &"static" and is_instance_valid(target) and target.has_meta(BranchKit.LINK_META):
			BranchKit.share_bolt(target, damage, tower)  # Maelstrom: the bolt travels the current
		if tag == &"static":
			var reach := _static_field(target, at, damage, tower)
			_bolt_seen(target, at, damage, reach, tracker)
		return target
	_fire(rod, &"lightning_rod", [tower] if tower else [], true)
	rod.take_damage(_rx(rod, damage * ROD_MULTIPLIER), "light", false, false, tower, &"lightning_rod")
	return rod

# A Charged bolt struck at `at` (screens_ui.md "Charged bolt"): the bolt and spark burst (ChargedBolt, budgeted),
# the Charged pips empty with a pop, and ReactionTracker.bolt_struck for Sound. `reach` = Static Field's ring.
static func _bolt_seen(target: Node2D, at: Vector2, damage: float, reach: float, tracker: ReactionTracker) -> void:
	if tracker == null or not is_instance_valid(tracker):
		return
	tracker.bolt_struck.emit(at, damage)
	ChargedBolt.strike(at, tracker.get_parent(), reach)
	if is_instance_valid(target) and not target.is_cleansed and target.has_method("flash_status"):
		target.flash_status(STATIC)

# Static Field: a Static bolt also hits nightmares within 1 tile of where it struck (II: 1.5 tiles,
# and they gain 1 Static, which can set off their own bolt). Returns its reach in pixels (0 = no Static Field).
static func _static_field(struck: Node2D, at: Vector2, damage: float, tower: Node) -> float:
	var dreams := _dreams(struck)
	if dreams == null or not dreams.has_rule(&"static_field"):
		return 0.0
	var deep := dreams.rule_level(&"static_field") > 0
	var reach := (1.5 if deep else 1.0) * CELL
	var potency := damage / EnemyStatuses.STATIC_BOLT_MULTIPLIER
	var nearby := _field(struck).filter(func(e: Node2D) -> bool:
		return e != struck and e.global_position.distance_to(at) <= reach)
	for other in nearby:
		if not is_instance_valid(other) or other.is_cleansed:
			continue
		other.take_damage(damage, "light", true, false, tower, &"static")
		if deep and is_instance_valid(other) and not other.is_cleansed:
			other.apply_status(STATIC, 1, 0.0, potency, 0, "light", tower)
	return reach

static func _find_rod(near: Node2D) -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for other in _field(near):
		if not other.statuses.has(MARKED) or not other.statuses.has(STATIC) or not grown(other.statuses, [MARKED, STATIC]):
			continue
		var distance: float = other.global_position.distance_to(near.global_position)
		if distance <= ROD_REACH * CELL and distance < best_distance:
			best_distance = distance
			best = other
	return best


# --- The Reactions ----------------------------------------------------------------------------------

# Damp + 3 Static: discharges for 4× the applier's damage and arcs to every Damp nightmare nearby for
# 2×, each arc adding Static (so wet crowds chain). Uses up the Static.
static func _thunderclap(enemy: Node2D, source: Node) -> void:
	var s: EnemyStatuses = enemy.statuses
	var tower := _tower_of(source, s.source(STATIC))
	# Crowned: a Spored nightmare's Thunderclap is a Tempest (not again within 2 s of the last one).
	var tempest := s.has(SPORED) and s.tempest_time <= 0.0
	var chain := _fire(enemy, &"tempest" if tempest else &"thunderclap", _towers(tower, s.source(DAMP)), false,
		CROWNED_LINKS if tempest else 1, &"thunderclap")
	if chain <= 0:
		return
	if tempest:
		s.tempest_time = TEMPEST_LOCK
	var base := _applier_damage(tower, s.potency(STATIC))
	var potency := s.potency(STATIC)
	s.remove(STATIC)
	var dreams := _dreams(enemy)
	var level := 0
	if dreams and dreams.has_rule(&"rolling_thunder"):
		level = 1 + dreams.rule_level(&"rolling_thunder")
	var eye := tempest and dreams != null and dreams.has_rule(&"eye_of_the_tempest")
	var reach: float = (THUNDERCLAP_REACH[level] + _storm_front(enemy) + (TEMPEST_EXTRA_REACH if eye else 0.0)) * CELL
	if dreams and dreams.has_rule(&"conductive_soil") and tower:
		reach = maxf(reach, tower.get_range_pixels())  # The Storm Grid capstone
	var arcs: Array = []
	for other in Tower.nightmares_near(enemy.get_tree(), enemy.global_position, reach):
		if other != enemy and is_instance_valid(other) and not other.is_cleansed and other.statuses.has(DAMP) and other.global_position.distance_to(enemy.global_position) <= reach:
			arcs.append(other)
	# At most the THUNDERCLAP_MAX_ARCS nearest Soaked nightmares per clap (design chat; also bounds a
	# chain's cost). Chains still continue from those.
	# Rolling Thunder's cost (dream_design.md 83c40cd7): its longer arcs strike at most ROLLING_THUNDER_ARCS nightmares.
	var max_arcs := ROLLING_THUNDER_ARCS if level > 0 else THUNDERCLAP_MAX_ARCS
	if arcs.size() > max_arcs:
		var at: Vector2 = enemy.global_position
		arcs.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
		arcs = arcs.slice(0, max_arcs)
	enemy.take_damage(_rx(enemy, base * THUNDERCLAP_DAMAGE), _line(tower, "light"), false, false, tower, &"thunderclap")
	for other in arcs:
		if not is_instance_valid(other) or other.is_cleansed:
			continue
		_segment(&"thunderclap_arc", enemy.global_position, other.global_position, enemy, 0.25)
		_touch(other, chain, _towers(tower))
		var struck := strike_bolt(other, base * THUNDERCLAP_ARC_DAMAGE, tower, &"thunderclap")
		if is_instance_valid(other) and dreams and dreams.has_rule(&"conductive_soil"):
			other.statuses.remove(DAMP)  # Conductive Soil's cost: each jump uses up that nightmare's Soaked
		if is_instance_valid(struck) and not struck.is_cleansed:
			struck.apply_status(STATIC, THUNDERCLAP_ARC_STATIC[level], 0.0, potency, 0, "light", tower)
		# Tempest: every arc also sets off Ignite on a Spored target (not bosses), whose spread spores
		# carry Static, so wet neighbours Thunderclap in turn.
		if tempest and is_instance_valid(other) and not other.is_cleansed and other.statuses.has(SPORED) \
				and not other.statuses.is_boss:
			other.statuses.tempest_time = TEMPEST_LOCK
			_ignite(other, tower, potency, 2 if eye else 0)

# 3+ Spored + any Static: every Spored stack goes off at once (×1.5 of what it had left) and a stack
# spreads to neighbours, who may Ignite in turn. Uses up the Spored.
static func _ignite(enemy: Node2D, source: Node, carry_static: float = 0.0, spread: int = 0) -> void:
	var s: EnemyStatuses = enemy.statuses
	var spore_source := s.source(SPORED)
	var chain := _fire(enemy, &"ignite", _towers(spore_source, _tower_of(source, s.source(STATIC))))
	if chain <= 0:
		return
	# Status jobs (2026-09-29): no detonation. The spores burn for BURN_TIME s (Spored ticks
	# BURN_SPORE_RATE x as fast) and each second a stack spreads to nightmares nearby (who may start
	# burning in turn). Uses up the Static, not the Spored.
	var static_source: Node = s.source(STATIC)  # Tempest's carried Static stays its charger's (bolts, Live Wire)
	if static_source == null:
		static_source = source
	s.remove(STATIC)
	burn(enemy, spore_source, chain, carry_static, spread, static_source)

# Sets `enemy` burning (Ignite; Tempest's arcs): its Spored ticks faster, and a BurnTicker spreads a stack
# each second while it burns. Sparking Spores (card 170, get_ignite_multiplier) makes it burn faster.
static func burn(enemy: Node2D, spore_source: Node, chain: int = 1, carry_static: float = 0.0, spread: int = 0,
		static_source: Node = null) -> void:
	var s: EnemyStatuses = enemy.statuses
	var dreams := _dreams(enemy)
	var sparking: float = dreams.get_ignite_multiplier(enemy) if dreams and dreams.has_method("get_ignite_multiplier") else 1.0  # Sparking Spores: from 5 Poisoned (read before anything spends them)
	s.burn_rate = BURN_SPORE_RATE * sparking
	var already := s.burn_time > 0.0
	s.burn_time = maxf(s.burn_time, BURN_TIME)
	var world := _world(enemy)
	if not already and world:
		world.add_child(BurnTicker.new(enemy, spore_source, chain, carry_static, spread, static_source))

# One burning nightmare: every second, 1 Spored stack (Wildfire Spores: 2) to each nightmare within reach,
# at its Spored's strength; Tempest's burns also carry 1 Static. Frees itself when the burn ends.
class BurnTicker extends Node:
	var enemy: Node2D
	var source: Node
	var charger: Node  # Tempest: whose Static the burn carries (credited with it, not the spores)
	var chain := 1
	var carry_static := 0.0
	var spread := 0
	var _next := 1.0

	func _init(target: Node2D, spore_source: Node, chain_count: int, static_carry: float, stacks: int, static_source: Node = null) -> void:
		enemy = target
		source = spore_source
		chain = chain_count
		carry_static = static_carry
		spread = stacks
		charger = static_source

	func _process(delta: float) -> void:
		if not is_instance_valid(enemy) or enemy.is_cleansed or enemy.statuses.burn_time <= 0.0:
			queue_free()
			return
		_next -= delta
		if _next > 0.0:
			return
		_next += 1.0
		Reactions._burn_spread(enemy, source if is_instance_valid(source) else null, chain, carry_static, spread,
			charger if is_instance_valid(charger) else null)

static func _burn_spread(enemy: Node2D, spore_source: Node, chain: int, carry_static: float, spread: int,
		static_source: Node = null) -> void:
	var s: EnemyStatuses = enemy.statuses
	if not s.has(SPORED):
		return
	var dreams := _dreams(enemy)
	var level := 1 if dreams and dreams.has_rule(&"wildfire_spores") else 0
	var stacks: int = spread if spread > 0 else IGNITE_SPREAD[level]
	var potency := s.potency(SPORED)
	var line := s.spore_line()
	var spread_any := false
	for other in _others_within(enemy, IGNITE_REACH[level] + _storm_front(enemy)):
		if not is_instance_valid(other) or other.is_cleansed:
			continue
		_touch(other, chain, _towers(spore_source))
		if carry_static > 0.0:
			other.apply_status(STATIC, 1, 0.0, carry_static, 0, "light", static_source if static_source else spore_source)  # Tempest: burns carry Static (its charger's)
		if is_instance_valid(other) and not other.is_cleansed:
			other.apply_status(SPORED, stacks, 0.0, potency, 0, line, spore_source)
			spread_any = true
	if level > 0 and spread_any and is_instance_valid(enemy) and not enemy.is_cleansed:
		s.remove(SPORED)  # Wildfire Spores' cost (dream_design.md 83c40cd7): spreading 2 burns away its own Poisoned

# 3+ Spored + Damp: the Spored ticks +50% for 4 s and a spore cloud grows on the tile. Uses up Damp.
static func _mushrooming(enemy: Node2D, source: Node) -> void:
	var s: EnemyStatuses = enemy.statuses
	var spore_source := s.source(SPORED)
	# Crowned: on a Held nightmare it's a Fairy Circle, at full Drowsy a Nightbloom.
	var id := &"mushrooming"
	if s.is_held():
		id = &"fairy_circle"
	elif s.has(DROWSY) and s.stacks(DROWSY) >= s.get_max_stacks(DROWSY):
		id = &"nightbloom"
	var crowned := id != &"mushrooming"
	var chain := _fire(enemy, id, _towers(spore_source, _tower_of(source, s.source(DAMP))), false,
		CROWNED_LINKS if crowned else 1, &"mushrooming")
	if chain <= 0:
		return
	s.remove(DAMP)
	s.mushroom_time = MUSHROOM_TIME
	var cell: Vector2 = enemy.get_current_cell()
	var dreams := _dreams(enemy)
	var ground_parent := _world(enemy)  # Ground effects: in the world at z -1 (under the y-sorted map)
	if id == &"fairy_circle":
		# Mushroom rings on the path tiles among the 8 around it, instead of the one cloud.
		var ring_of_rings := dreams != null and dreams.has_rule(&"ring_of_rings")
		var route: Array = _route_cells(enemy)
		var cells: Array[Vector2] = []
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				var c := cell + Vector2(dx, dy)
				if c != cell and route.has(c) and cells.size() < FAIRY_RING_MAX:
					cells.append(c)
		var rings := CrownedGround.new(CrownedGround.Kind.FAIRY_RING, cells, FAIRY_RING_TIME)
		rings.until_stepped = ring_of_rings
		rings.potency = s.potency(SPORED)
		rings.line = s.spore_line()
		rings.source = spore_source
		rings.chain = chain
		ground_parent.add_child(rings)
		return
	if id == &"nightbloom":
		var level := 1 if dreams and dreams.has_rule(&"endless_night") else 0
		var bloom := CrownedGround.new(CrownedGround.Kind.NIGHTBLOOM, [], NIGHTBLOOM_TIME[level],
			Tower.MAP_GRID.calculate_map_position(cell),
			(MUSHROOM_CLOUD_RADIUS * NIGHTBLOOM_WIDTH[level] + _storm_front(enemy)) * CELL)
		ground_parent.add_child(bloom)
	var wide := 1.0
	var time := MUSHROOM_CLOUD_TIME
	if id == &"nightbloom" and dreams and dreams.has_rule(&"endless_night"):
		wide = NIGHTBLOOM_WIDTH[1]
		time = NIGHTBLOOM_TIME[1]
	var radius := (MUSHROOM_CLOUD_RADIUS * wide + _storm_front(enemy)) * CELL
	if dreams and dreams.has_rule(&"mushroom_rain"):
		# Mushroom Rain (card 134; dream_design.md 83c40cd7): the cloud covers the 8 tiles around it but lasts half as long.
		time *= MUSHROOM_RAIN_TIME
		radius = maxf(radius, MUSHROOM_RAIN_RADIUS * CELL)
	var cloud := ReactionCloud.new(Tower.MAP_GRID.calculate_map_position(cell), radius, time, s.potency(SPORED),
		s.spore_line(), spore_source, chain)
	# In the world at z -1 (ReactionCloud), so it draws on the ground under the y-sorted map (never in the
	# nightmares' container: its children are all nightmares).
	_world(enemy).add_child(cloud)

# Damp + full Drowsy: falls asleep for 2 s, once per nightmare (bosses and nightmares that can't be

# Whether `enemy` is within `cells` (straight line) of the Heartwood.
static func _near_heartwood(enemy: Node2D, dreams: DreamState, cells: float) -> bool:
	var map = dreams.map_generator if dreams else null
	if map == null:
		return true
	return enemy.global_position.distance_to(Tower.MAP_GRID.calculate_map_position(map.endPath)) <= cells * CELL
# held are slowed instead). Uses up the Drowsy.
static func _drown(enemy: Node2D, source: Node) -> void:
	var s: EnemyStatuses = enemy.statuses
	var dreams := _dreams(enemy)
	var level := 0
	# Deep Water's cost (dream_design.md 83c40cd7): only for Drowns within DEEP_WATER_REACH cells (straight line) of the Heartwood.
	if dreams and dreams.has_rule(&"deep_water") and _near_heartwood(enemy, dreams, DEEP_WATER_REACH):
		level = 1 + dreams.rule_level(&"deep_water")
	if s.drowned >= DROWN_TIMES[level]:
		return
	var applier := _tower_of(source, s.source(DROWSY))
	# Crowned: a Held nightmare's Drown is a Still Pool (it sinks, and a pool stays on its tile).
	var still := s.is_held()
	if _fire(enemy, &"still_pool" if still else &"drown", _towers(applier, s.source(DAMP)), false,
			CROWNED_LINKS if still else 1, &"drown") <= 0:
		return
	s.remove(DROWSY)
	s.drowned += 1
	if still:
		var deep_still := 1 if dreams and dreams.has_rule(&"deep_stillness") else 0
		var cells: Array[Vector2] = [enemy.get_current_cell()]
		var pool := CrownedGround.new(CrownedGround.Kind.STILL_POOL, cells, STILL_POOL_TIME[deep_still])
		pool.sleep_seconds = STILL_POOL_SLEEP[deep_still]  # Now: seconds a walker entering is pulled under
		pool.source = applier
		_world(enemy).add_child(pool)  # z -1: on the ground, under the y-sorted map
	# Status jobs (2026-09-29): no sleep. Pulled under: slowed and drowning for a few seconds.
	pull_under(enemy, applier, PULL_UNDER_TIME[1 if level > 0 else 0], level > 0)

# Drown (and a Still Pool's walkers): for `seconds`, −60% speed (bosses −30%, Deep Water −40%; Heavy Air
# makes it stronger) and drowning damage each second rising 0.5×, 1×, 1.5× the applier's damage (Deep
# Water: 50% faster). Effect damage, tag "drown".
static func pull_under(enemy: Node2D, applier: Node, seconds: float, deep: bool = false) -> void:
	var world := _world(enemy)
	if world == null or not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	world.add_child(PullUnder.new(enemy, applier, seconds, deep))

class PullUnder extends Node:
	var enemy: Node2D
	var applier: Node
	var seconds := 3.0
	var deep := false
	var _age := 0.0
	var _next := 1.0
	var _second := 0

	func _init(target: Node2D, by: Node, time: float, deep_water: bool) -> void:
		enemy = target
		applier = by
		seconds = time
		deep = deep_water

	func _process(delta: float) -> void:
		if not is_instance_valid(enemy) or enemy.is_cleansed or _age >= seconds:
			queue_free()
			return
		_age += delta
		var s: EnemyStatuses = enemy.statuses
		var slow: float = (Reactions.PULL_UNDER_BOSS_SLOW[1 if deep else 0] if s.is_boss else Reactions.PULL_UNDER_SLOW)
		if is_instance_valid(applier) and applier is Tower:
			slow *= applier.get_slow_multiplier()  # Heavy Air
		s.slow_time = maxf(s.slow_time, 0.2)
		s.slow_amount = maxf(s.slow_amount, minf(slow, 0.9))
		_next -= delta
		if _next > 0.0 or not (is_instance_valid(applier) and applier is Tower):
			return
		_next += 1.0
		_second += 1
		var step: float = Reactions.PULL_UNDER_STEP * (Reactions.DEEP_WATER_GROWTH if deep else 1.0)
		enemy.take_damage(Reactions._rx(enemy, applier.get_damage() * step * _second), applier.tower_data.line, true, false, applier, &"drown")

# Marked + (Held or asleep or full Drowsy): the next Warden hit is a guaranteed ×3 crit. Uses up Marked.
static func _pinned(enemy: Node2D, source: Node) -> void:
	var s: EnemyStatuses = enemy.statuses
	if s.pinned:
		return
	if _fire(enemy, &"pinned", _towers(s.source(MARKED), _tower_of(source, s.source(HELD)))) <= 0:
		return
	s.remove(MARKED)
	s.pinned = true

# Held + Spored: Spored ticks 3× as fast while held (EnemyStatuses.tick). Only the event is here.
static func _smother(enemy: Node2D, source: Node) -> void:
	var s: EnemyStatuses = enemy.statuses
	_fire(enemy, &"smother", _towers(s.source(SPORED), _tower_of(source, s.source(HELD))))


# --- Echoes (Echo Hollow) ---------------------------------------------------------------------------

# Rough strength of each Reaction's burst, × the applier's damage, for echoes (the originals scale
# with what the nightmare had built up, which an echo on an empty spot can't).
const ECHO_DAMAGE := {&"thunderclap": 4.0, &"ignite": 3.0, &"shatter": 2.5, &"lightning_rod": 6.0}
const ECHO_REACH := 1.0  # Cells around the spot

# Reaction `id` repeats at `spot` at `share` strength (Echo Hollow's echo, 1 s after the original).
# `echo_tower` is the Hollow, `applier` the Warden behind the original. With `as_chain_link`
# (Whispering Hollow) the echo is recorded as the chain's next link. `depth` = 1 for an echo, 2 for
# Encore's echo of an echo; the tracker's echo_depth tells Hollows not to echo echoes.
static func echo(id: StringName, spot: Vector2, share: float, echo_tower: Tower, applier: Tower, chain: int,
		as_chain_link: bool, depth: int = 1) -> void:
	if not is_instance_valid(echo_tower) or not echo_tower.is_inside_tree():
		return
	var tracker := ReactionTracker.find(echo_tower)
	var world := _world(echo_tower)
	var nearby := echo_tower.get_tree().get_nodes_in_group(Tower.ENEMY_GROUP).filter(func(e: Node2D) -> bool:
		return e.global_position.distance_to(spot) <= ECHO_REACH * CELL)
	tracker.echo_depth = depth
	echo_tower.echoed.emit(echo_tower, id, spot)
	if world:
		Fx.play(&"echo", spot, world)  # Lilac rings, then the Reaction's own effect again
		Fx.reaction(id, spot, world, [echo_tower])
	var strength: float = ECHO_DAMAGE.get(id, 0.0) * (applier.get_damage() if is_instance_valid(applier) else echo_tower.get_damage())
	for enemy in nearby:
		if not is_instance_valid(enemy) or enemy.is_cleansed:
			continue
		var s: EnemyStatuses = enemy.statuses
		match id:
			&"drown":
				pull_under(enemy, applier if is_instance_valid(applier) else echo_tower, PULL_UNDER_TIME[0] * share)
			&"pinned":
				s.pinned = true
			_:
				if strength > 0.0:
					enemy.take_damage(_rx(enemy, strength * share), _line(applier, echo_tower.tower_data.line), true, false,
						echo_tower, &"echo")
		if is_instance_valid(enemy) and not enemy.is_cleansed:
			echo_tower.resonant_set_off(enemy)  # Resonant Hollow: the echo rings like a chime
	if id == &"mushrooming" and not nearby.is_empty():
		var first: Node2D = nearby[0]
		var cloud := ReactionCloud.new(spot, MUSHROOM_CLOUD_RADIUS * CELL, MUSHROOM_CLOUD_TIME * share,
			first.statuses.potency(SPORED), first.statuses.spore_line(), applier, chain)
		_world(first).add_child(cloud)  # z -1: on the ground, under the y-sorted map
	if as_chain_link and not nearby.is_empty() and tracker:
		var link: Node2D = nearby[0]
		link.statuses.mark_chain(chain + 1, [echo_tower], CHAIN_WINDOW)
		tracker.record(id, link, chain + 1, [echo_tower])
	tracker.echo_depth = 0


# --- Firing, chains and output ---------------------------------------------------------------------

# Fires Reaction `id` on `enemy` unless it's cooling down there. Returns its chain link (1 = not
# caused by another Reaction), or 0 if it didn't fire. `ignore_cooldown`: the rule still applies
# (Lightning Rod redirects every bolt) but only the first in a cooldown shows.
# `links`: chain links it counts as (Crowned Reactions: 2). `cooldown_id`: the cooldown it shares (a
# Crowned Reaction uses its base Reaction's).
static func _fire(enemy: Node2D, id: StringName, towers: Array, ignore_cooldown: bool = false, links: int = 1,
		cooldown_id: StringName = &"") -> int:
	var s: EnemyStatuses = enemy.statuses
	var key := cooldown_id if cooldown_id != &"" else id
	if s.is_on_cooldown(key):
		return 1 if ignore_cooldown else 0
	var data := get_data(key)
	var dreams := _dreams(enemy)
	var cooldown: float = data.cooldown if data else 1.5
	if dreams and dreams.has_rule(&"quick_reactions"):
		cooldown = minf(cooldown, QUICK_COOLDOWN)
	if dreams and WOVEN_RULE.has(id) and dreams.has_rule(WOVEN_RULE[id]):
		cooldown *= WOVEN_COOLDOWN  # A Woven card's cost (dream_design.md 83c40cd7): its Crowned Reaction fires half as often
	s.start_cooldown(key, cooldown)
	# Storm Front: a Reaction a Gust-copied status completed counts one more link.
	var storm_front := s.gust_time > 0.0
	if storm_front:
		links += 1
	var chain := links
	var all_towers := towers.duplicate()
	if s.chain_time > 0.0:
		chain = s.chain_count + links
		for t in s.chain_towers:
			if is_instance_valid(t) and not all_towers.has(t):
				all_towers.append(t)
	all_towers = all_towers.filter(func(t) -> bool: return is_instance_valid(t) and t is Tower)
	# Its own output marks this nightmare too, so a second Reaction here right away links on.
	s.mark_chain(chain, all_towers, CHAIN_WINDOW)
	# The effect, its callout, a light thread from each Warden that set it up, and a small shake.
	var world := _world(enemy)
	if world != null:
		var node := Fx.reaction(id, enemy.global_position, world,
			towers.filter(func(t) -> bool: return is_instance_valid(t) and t is Tower))
		if id == &"smother" and node != null:
			enemy.set_meta(&"smother_fx", node)  # Loops while held; the nightmare frees it after
		if storm_front:
			Fx.play(&"storm_front", enemy.global_position, world, 1.0, true, STORM_FRONT_SECONDS)  # A wind swirl (it loops: give it a life)
	var tracker := ReactionTracker.find(enemy)
	if tracker:
		tracker.record(id, enemy, chain, all_towers)
		tracker.note_spot(id, enemy.global_position, _tower_of(towers[0] if not towers.is_empty() else null, null))
	if chain - links < DAWNBURST_CHAIN and chain >= DAWNBURST_CHAIN:
		_dawnburst(enemy)
	return chain

# A Reaction's output reached `other`: a Reaction there soon counts as the chain's next link.
static func _touch(other: Node2D, chain: int, towers: Array) -> void:
	if is_instance_valid(other) and not other.is_cleansed:
		other.statuses.mark_chain(chain, towers, CHAIN_WINDOW)

# ×10 chain with the Dawnbreak Legendary: 10% of max health to every nightmare within 4 cells.
static func _dawnburst(enemy: Node2D) -> void:
	var dreams := _dreams(enemy)
	if dreams == null or not dreams.has_rule(&"dawnbreak"):
		return
	var at: Vector2 = enemy.global_position
	for other in _field(enemy):
		if other.global_position.distance_to(at) <= DAWNBREAK_REACH * CELL:
			var share := DAWNBREAK_BOSS_SHARE if other.enemy_data.is_boss else DAWNBREAK_SHARE
			other.take_damage(_rx(other, other.max_health * share), "", true, false, null, &"dawnbreak")


# --- Helpers ----------------------------------------------------------------------------------------

# Storm Front: +1 cell of reach for a Reaction a Gust-copied status completed on `enemy`.
static func _storm_front(enemy: Node2D) -> float:
	return STORM_FRONT_REACH if enemy.statuses.gust_time > 0.0 else 0.0

# The path tiles nightmares walk (Fairy Circle's rings grow only on those).
static func _route_cells(near: Node2D) -> Array:
	var dreams := _dreams(near)
	if dreams == null or dreams.map_generator == null:
		return []
	var map = dreams.map_generator
	return Array(Tower.route_cells(map.get_path_from(map.startPath)))  # Whole cells (half-step routes)

# Carried Storm: a Samara / Autumn Gale seed passing through the spot of Reaction `id` repeats it at
# 50% on a nightmare it hits after (damage Reactions as a burst, Drown as a short sleep, Pinned as a
# Pin). The seed's Warden gets the credit.
static func carry(id: StringName, enemy: Node2D, seed_tower: Tower, applier: Tower) -> void:
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	var s: EnemyStatuses = enemy.statuses
	var base: StringName = CROWNED_BASE.get(id, id)
	match base:
		&"drown":
			pull_under(enemy, applier if is_instance_valid(applier) else seed_tower, PULL_UNDER_TIME[0] * CARRIED_SHARE)
		&"pinned":
			s.pinned = true
		_:
			var strength: float = ECHO_DAMAGE.get(base, 2.0)
			var damage := (applier.get_damage() if is_instance_valid(applier) else seed_tower.get_damage())
			enemy.take_damage(_rx(enemy, strength * damage * CARRIED_SHARE), _line(applier if is_instance_valid(applier) else seed_tower,
				seed_tower.tower_data.line), true, false, seed_tower, &"carried_storm")

static func _field(near: Node2D) -> Array:
	return near.get_tree().get_nodes_in_group(Tower.ENEMY_GROUP)

static func _others_within(enemy: Node2D, cells: float) -> Array:
	# Performance: only the nightmares bucketed near it (Tower.nightmares_near), not the whole field.
	return Tower.nightmares_near(enemy.get_tree(), enemy.global_position, cells * CELL).filter(func(e) -> bool:
		return is_instance_valid(e) and not e.is_cleansed and e != enemy and e.global_position.distance_to(enemy.global_position) <= cells * CELL)

static func _tower_of(first, fallback) -> Tower:
	if is_instance_valid(first) and first is Tower:
		return first
	if is_instance_valid(fallback) and fallback is Tower:
		return fallback
	return null

static func _towers(a = null, b = null) -> Array:
	var list := []
	for t in [a, b]:
		if is_instance_valid(t) and t is Tower and not list.has(t):
			list.append(t)
	return list

# Reaction damage after Quick Reactions' cut (DreamState.get_reaction_damage_multiplier: 0.65 with the card, Balancing;
# dream_design.md 83c40cd7). Every Reaction's damage goes through it; Charged bolts and Static Field don't (not Reactions).
static func _rx(near: Node, amount: float) -> float:
	var dreams := _dreams(near)
	return amount * (dreams.get_reaction_damage_multiplier() if dreams and dreams.has_method("get_reaction_damage_multiplier") else 1.0)

static func _applier_damage(tower: Tower, fallback: float) -> float:
	return tower.get_damage() if tower != null else fallback

static func _line(tower: Tower, fallback: String) -> String:
	return tower.tower_data.line if tower != null else fallback

static func _dreams(near: Node) -> DreamState:
	return near.get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState if near.is_inside_tree() else null

# Visuals go through Fx (scripts/fx/fx.gd, the effects player). They're added to the world (the
# scene the nightmares are in), never to the nightmares' container.
static func _world(near: Node) -> Node:
	var tracker := ReactionTracker.find(near)
	return tracker.get_parent() if tracker else null

static func _effect(effect: StringName, at: Vector2, near: Node, scale: float = 1.0, seconds: float = 0.0) -> Node2D:
	var world := _world(near)
	if effect == &"" or world == null:
		return null
	return Fx.play(effect, at, world, scale, true, seconds)

static func _segment(effect: StringName, from: Vector2, to: Vector2, near: Node, seconds: float) -> void:
	var world := _world(near)
	if world != null:
		Fx.segment(effect, from, to, world, seconds)
