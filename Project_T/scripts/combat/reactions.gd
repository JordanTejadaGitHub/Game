extends RefCounted
class_name Reactions

const DREAM_BURST := preload("res://scripts/fx/dream_burst.gd")

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

const SOAKED_NEEDED := 8
const EXPOSED_NEEDED := 10
const ROOTED_NEEDED := 4
const IGNITE_MIN_STATIC := 8
const SMOTHER_MIN_SPORES := 12
const CROWNED_MIN_STATIC := 8
const CROWNED_MIN_SPORES := 6
const THUNDERCLAP_STATIC := 10
const THUNDERCLAP_STATIC_BOSS := 15
const THUNDERCLAP_DAMAGE := 12.0  # × the applier's damage, to the nightmare that discharges
const THUNDERCLAP_ARC_DAMAGE := 6.0  # × the applier's damage, to each wet nightmare it arcs to
const THUNDERCLAP_MAX_ARCS := 8
const ROLLING_THUNDER_ARCS := 3  # Rolling Thunder: its longer arcs strike at most this many
const THUNDERCLAP_REACH: Array[float] = [2.5, 3.5, 3.5]  # Cells: base, Rolling Thunder, Rolling Thunder II
const THUNDERCLAP_ARC_STATIC: Array[int] = [1, 2, 3]
const IGNITE_MIN_SPORES := 12
const BURN_TIME := 3.0  # Ignite: seconds the spores burn
const BURN_SPORE_RATE := 4.0  # Spored ticks this many times as fast while burning
const IGNITE_SPREAD: Array[int] = [1, 2]  # Stacks: base, Wildfire Spores
const IGNITE_REACH: Array[float] = [1.0, 1.5]
const MUSHROOM_MIN_SPORES := 12
const MUSHROOM_TIME := 4.0  # Heavy Heart's copy of a Mushrooming: this long inside "the zone" (the cloud is MUSHROOM_CLOUD_TIME)
# Mushrooming is a zone (owner 2026-10-17, council reactions_unique.md): nightmares inside its cloud take this much more
# effect damage (Poisoned, bolts, Drown, every EFFECT_TAGS tag; effect_multiplier); the cloud no longer adds Poisoned.
const MUSHROOM_ZONE_BONUS := 0.30
const MUSHROOM_ZONE_HOLD := 1.0  # Seconds the zone's mark outlasts leaving the cloud (refreshed every ReactionCloud.TICK; council rx review 2026-10-17: was 0.25)
# Smother is a stored burst (owner 2026-10-17, council reactions_unique.md): while Rooted its Poisoned stops ticking and
# swells (EnemyStatuses.smother_stored); when the Root breaks it all lands at once, this many times over.
const SMOTHER_BURST := 2.0
const MUSHROOM_CLOUD_RADIUS := 0.6  # Cells
const MUSHROOM_CLOUD_TIME := 4.0
const MUSHROOM_RAIN_TIME := 0.5  # Mushroom Rain: half the duration…
const MUSHROOM_RAIN_RADIUS := 1.5  # …and the 3×3 around its tile (cells from the centre, reaching the corners' middles)
const SHATTER_MULTIPLIER := 4.0
const SHATTER_SPLASH := 0.5  # Share of the hit the shards deal within 1 cell
const PULL_UNDER_TIME: Array[float] = [3.0, 4.0]  # Drown: seconds pulled under (base, Deep Water)
const PULL_UNDER_SLOW := 0.6
const PULL_UNDER_BOSS_SLOW: Array[float] = [0.3, 0.4]  # Bosses (base, Deep Water)
const PULL_UNDER_STEP := 0.5  # Drowning damage in second n: n × this × the applier's damage
const DEEP_WATER_GROWTH := 1.5  # Deep Water: the damage grows 50% faster
const DROWN_TIMES: Array[int] = [1, 1, 2]  # Per nightmare: base, Deep Water, Deep Water II
const DEEP_WATER_REACH := 5.0  # Cells from the Heartwood (straight line) where Deep Water works
# Pinned is a pierce (owner 2026-10-17, council reactions_unique.md): the next hit is a x3 crit that also hits every
# nightmare in a line PIN_PIERCE_CELLS long behind the target (away from the Warden) at PIN_PIERCE_SHARE of it.
const PINNED_MULTIPLIER := 3.0
const PIN_PIERCE_CELLS := 3.0
const PIN_PIERCE_SHARE := 0.5
const PIN_PIERCE_WIDTH := 0.5  # Cells either side of the line
const ROD_REACH := 3.0  # Cells
const ROD_MULTIPLIER := 2.0
const QUICK_COOLDOWN := 0.75  # Quick Reactions
# Sleepwalk / Night Terror (Roguelite Code for the owner, 2026-10-17: Drowsy had no Reaction with Poisoned or Charged;
# council uniqueness review, same day: no spore spread, no x2 bolt).
# Sleepwalk = full Drowsy + need(IGNITE_MIN_SPORES) Poisoned: it walks back up its route, and turns round who it bumps.
const SLEEPWALK_TIME := 2.0  # Seconds it walks back (bosses SLEEPWALK_BOSS_TIME)
const SLEEPWALK_BOSS_TIME := 1.0
const SLEEPWALK_SPEED := 0.5  # Share of its speed while walking back (the bumped ones too)
const SLEEPWALK_TURN_TIME := 0.5  # Seconds each nightmare it touches walks back too (once per sleepwalk; never bosses, flyers)
const SLEEPWALK_REACH := 1.0  # Cells: "touches"
const SLEEPWALK_TRAIL_EVERY := 0.25  # Seconds between the spore puffs left behind it
# (council rx review 2026-10-17) Sleepwalk can't repeat forever: at most SLEEPWALK_TIMES walks per nightmare (bosses
# SLEEPWALK_BOSS_TIMES; echoes, Carried Storm and Heavy Heart copies count too), and its cooldown starts when the walk ends.
const SLEEPWALK_TIMES := 2
const SLEEPWALK_BOSS_TIMES := 1
const SLEEPWALKER_EXTRA_LIFE := 3.0  # A Sleepwalker node frees itself this long after the walk's own time at the latest
const SLEEPWALK_SEARCH_EVERY := 0.1  # Seconds between its searches for nightmares to bump (performance)
const PIN_WAIT := 2.0  # (council rx review 2026-10-17) Night Terror waits for a Pin's Starfall at most this long
# Night Terror = full Drowsy + need(IGNITE_MIN_STATIC) Charged: it wakes screaming, its Charged goes off as a normal bolt,
# and every other nightmare within NIGHT_TERROR_RADIUS is Rooted in fear (and gains NIGHT_TERROR_ROOT_STACKS Rooted).
const NIGHT_TERROR_RADIUS := 2.0  # Cells
const NIGHT_TERROR_ROOT := 1.0  # Seconds Rooted (bosses NIGHT_TERROR_BOSS_ROOT)
const NIGHT_TERROR_BOSS_ROOT := 0.5
const NIGHT_TERROR_ROOT_STACKS := 2  # Rooted stacks it gains (the normal accepted-status path: caps and immunity apply; never x Brimming: council rx review 2026-10-17)
const DAWNBURST_CHAIN := 10
const DAWNBREAK_SHARE := 0.10  # Of max health, to every nightmare within DAWNBREAK_REACH
const DAWNBREAK_BOSS_SHARE := 0.02
const DAWNBREAK_REACH := 4.0
const DAWNBREAK_WAIT := 3.0  # Card pass 2026-10-16: a Dawnburst every 10th link, each nightmare once every this many seconds
const CROWNED_CARD_BONUS := 0.50  # Ring of Rings' +50% Poisoned per trap. (Owner 2026-10-17, council reactions_unique.md:
# the other Woven cards no longer add damage or numbers; each gives its Crowned Reaction a new rule, see the constants above.)

# Crowned Reactions (tower_design.md "Crowned Reactions", dream_design.md "Crowned Reaction numbers"):
# a Reaction on a nightmare that already carries a third status is replaced by a bigger one. It
# shares the base Reaction's cooldown and counts as 2 chain links. [base, Woven card] pairs.
const CROWNED_LINKS := 2
const TEMPEST_LOCK := 2.0  # A nightmare hit by a Tempest can't start another for this long
# (owner 2026-10-17, council reactions_unique.md: the number-only Woven cards became new rules; numbers below.)
const TEMPEST_SOAK := 1  # Tempest's Reach: a Tempest's burn also spreads this many Soaked a second (the arcs never run dry)
const STILL_POOL_TIME := 5.0
const STILL_POOL_SLEEP := 1.0
const STILL_POOL_MAX_CELLS := 4  # Deep Stillness: each nightmare pulled under widens the pool onto the next path cell, up to this
const FEVER_SLEEP := 2.0  # Fever Dream: seconds Asleep
const FEVER_SPORED := 3
const FEVER_DROWSY := 2
const FEVER_BOSS_DROWSY_CAP := 12
const FEVER_REACH := 1.0
const FEVER_PITCH_SLEEP := 1.0  # Fever Pitch: each neighbour who catches the fever falls Asleep this long (once each, not bosses)
# Starfall is a crit fan-out (owner 2026-10-17): the Pinned crit splits into stars. Each Exposed nightmare (at the
# Reaction need) within STARFALL_REACH is struck by a crit for STARFALL_SHARE of the hit. No bolts (council rx review
# 2026-10-17: setting off bolts is Prismstorm's). Falling Stars: each one a star hits is Pinned too, its next hit a
# STAR_PIN_CRIT crit.
const STARFALL_REACH := 3.0
const STARFALL_SHARE := 0.5
const STAR_PIN_CRIT := 2.0
# Prismstorm (owner 2026-10-17): each shard that hits a nightmare with CROWNED_MIN_STATIC Charged sets off its bolt at
# once (no Charged spread). Prism Heart: the shards fly along the path, PRISM_ROUTE_CELLS ahead and behind.
const PRISM_ROUTE_CELLS := 3.0
# Avalanche is scree (owner 2026-10-17): the lob Shatters its target and leaves scree on the path cells under the stone
# for SCREE_TIME s: walkers are SCREE_SLOW slower and gain 1 Rooted every SCREE_ROOT_EVERY s, up to SCREE_ROOT_MAX each.
# Mountain's Fall: the scree also Soaks walkers, SCREE_SOAK a second.
# (council rx review 2026-10-17) The count is kept on the nightmare, not the patch: overlapping patches share the
# &"scree_step" pace, and a walker that reached SCREE_ROOT_MAX gets no scree Rooted for SCREE_TIME + its Hold breather
# (&"scree" cooldown), so scree never stacks into an endless hold.
const SCREE_TIME := 4.0
const SCREE_SLOW := 0.30
const SCREE_ROOT_EVERY := 0.5
const SCREE_ROOT_MAX := 4
const SCREE_ROOT_TIME := 0.6  # Each Rooted it adds holds this long (longer than SCREE_ROOT_EVERY, so the stacks build)
const SCREE_SOAK := 1
const NIGHTBLOOM_TIME := 4.0
const ENDLESS_NIGHT_GENERATIONS := 1  # (council rx review 2026-10-17) Endless Night grows one new cloud from a cloud; that one grows none
const NIGHTBLOOM_WIDTH := 1.0
# Changeling (Crowned Sleepwalk on an Exposed nightmare; owner 2026-10-17): before it sleepwalks it trades places with
# the nightmare furthest along the path within CHANGELING_REACH route cells ahead on its own route (council rx review
# 2026-10-17: by route, never across walls; never a boss either side, never a flyer). Stolen Away: the one it traded
# with sleepwalks back STOLEN_WALK s too.
const CHANGELING_REACH := 3.0
const STOLEN_WALK := 1.0
# Wide Awake (Crowned Night Terror on a Rooted nightmare; owner 2026-10-17): the scream wakes your Wardens: every Warden
# within WIDE_AWAKE_REACH attacks WIDE_AWAKE_SPEED faster for WIDE_AWAKE_TIME s (Tower.reaction_haste; outside the Dream
# cap). Alarm Bells: every Warden touching a woken one wakes too.
const WIDE_AWAKE_REACH := 3.0
const WIDE_AWAKE_SPEED := 0.40
const WIDE_AWAKE_TIME := 3.0
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
	&"fairy_circle": &"mushrooming",
	&"changeling": &"sleepwalk", &"wide_awake": &"night_terror"}  # (owner 2026-10-17, council reactions_unique.md)
# Each Crowned Reaction's Woven card (its cost: that Crowned Reaction's cooldown ×WOVEN_COOLDOWN).
const WOVEN_RULE := {&"tempest": &"eye_of_the_tempest", &"still_pool": &"deep_stillness", &"fever_dream": &"fever_pitch",
	&"starfall": &"falling_stars", &"avalanche": &"mountains_fall", &"prismstorm": &"prism_heart", &"nightbloom": &"endless_night",
	&"fairy_circle": &"ring_of_rings", &"changeling": &"stolen_away", &"wide_awake": &"alarm_bells"}
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
	if _half_need:  # Clashing Notes' half need is for its own nightmare only: a status landing elsewhere checks in full
		_half_need = false
		var share := _half_share  # (Keyword chips 2026-10-16: …and at full damage)
		_half_share = 1.0
		_on_status(enemy, _id, source)
		_half_need = true
		_half_share = share
		return
	_on_status(enemy, _id, source)

static func _on_status(enemy: Node2D, _id: StringName, source: Node) -> void:
	if _id == MARKED:
		Fx.exposed_check(enemy)  # Exposed just filled: its flare, mark and callout (screens_ui.md, last section)
	var s: EnemyStatuses = enemy.statuses
	if s.count() < 2:
		return
	var frame := Engine.get_process_frames()
	if frame != _checked_frame:
		_checked_frame = frame
		_checked.clear()
	# An int key (performance: the formatted string was built on every status landing); mixes the nightmare, the status,
	# its stacks and the status count, as the string did.
	var key: int = ((enemy.get_instance_id() * 31 + _id.hash()) * 131 + s.stacks(_id)) * 17 + s.count()
	if _checked.has(key):
		return
	_checked[key] = true
	var crowned_first := _crowned_waiting(enemy)  # Read before anything here spends a status (Crowned precedence, below)
	var static_needed := thunderclap_threshold(s)
	if s.stacks(DAMP) >= need(SOAKED_NEEDED) and s.stacks(STATIC) >= static_needed and grown(s, [DAMP, STATIC]):
		_thunderclap(enemy, source)
	if enemy.is_cleansed:
		return
	if s.stacks(SPORED) >= need(IGNITE_MIN_SPORES) and s.stacks(STATIC) >= need(IGNITE_MIN_STATIC) and grown(s, [SPORED, STATIC]):
		_ignite(enemy, source)
	if enemy.is_cleansed:
		return
	if s.stacks(SPORED) >= need(MUSHROOM_MIN_SPORES) and s.stacks(DAMP) >= need(SOAKED_NEEDED) and grown(s, [SPORED, DAMP]):
		_mushrooming(enemy, source)
	if s.stacks(DAMP) >= need(SOAKED_NEEDED) and s.has(DROWSY) and s.stacks(DROWSY) >= s.normal_cap(DROWSY) and grown(s, [DAMP, DROWSY]):
		_drown(enemy, source)
	# One full Drowsy, one Reaction (owner 2026-10-17): Drown, Night Terror, Sleepwalk and Pinned's Drowsy option each use
	# the Drowsy up when they fire, so only the first ready one in this fixed order goes off (which status reached its need
	# first isn't tracked): Drown, Night Terror, Sleepwalk, Pinned.
	_check_drowsy_pairs(enemy, source, crowned_first)
	if enemy.is_cleansed:
		return  # (Night Terror's bolt may dispel it)
	if s.stacks(MARKED) >= need(EXPOSED_NEEDED) and (s.stacks(HELD) >= need(ROOTED_NEEDED) or is_asleep(enemy) \
			or (s.has(DROWSY) and s.stacks(DROWSY) >= s.normal_cap(DROWSY))) and grown(s, [MARKED, HELD, DROWSY]):
		_pinned(enemy, source)
	if s.stacks(HELD) >= need(ROOTED_NEEDED) and s.stacks(SPORED) >= need(SMOTHER_MIN_SPORES) and grown(s, [HELD, SPORED]):
		_smother(enemy, source)

# Sleepwalk / Night Terror (Roguelite Code for the owner, 2026-10-17): both need full Drowsy (as Drown) and use it up.
# `waiting`: _crowned_waiting's answer, read before this status check spent anything.
static func _check_drowsy_pairs(enemy: Node2D, source: Node, waiting: Dictionary = {}) -> void:
	if enemy.is_cleansed:
		return
	var s: EnemyStatuses = enemy.statuses
	if not s.has(DROWSY) or s.stacks(DROWSY) < s.normal_cap(DROWSY):
		return
	# (council rx review 2026-10-17) Sleep and Catch come first: a Warden's own sleep step (Dreamshroom's
	# sleep_at_max_drowsy) lands before these spend the Drowsy, and Sleepwalk / Night Terror wait (the Drowsy stays) while
	# the nightmare is Asleep or inside a Dreamcatcher's range, so the sleep runs out and the Catch works first.
	for sleeper in _towers(source, s.source(DROWSY)):
		if sleeper.attack_data.sleep_at_max_drowsy > 0.0:
			sleeper._put_to_sleep(enemy)
	if s.is_asleep() or near_dreamcatcher(enemy):
		return
	if s.stacks(STATIC) >= need(IGNITE_MIN_STATIC) and grown(s, [STATIC, DROWSY]) and not waiting.has(&"night_terror"):
		_night_terror(enemy, source)
	if not enemy.is_cleansed and s.has(DROWSY) and s.stacks(DROWSY) >= s.normal_cap(DROWSY) \
			and s.stacks(SPORED) >= need(IGNITE_MIN_SPORES) and grown(s, [SPORED, DROWSY]) and not waiting.has(&"sleepwalk"):
		_sleepwalk(enemy, source)

# Crowned precedence (owner 2026-10-17, council reactions_unique.md): a nightmare carrying every status of a Crowned
# Reaction at its need gets that Crowned one, never a base Reaction built from two of its statuses that would spend a
# shared status first. Most Crowned are already checked inside their base (Tempest in Thunderclap…); only two base
# Reactions can get in the way, so the rule is kept to them. Returns {base Reaction id that waits: the Crowned it waits for}.
# - Sleepwalk (Poisoned + Drowsy) waits for Nightbloom (Mushrooming + full Drowsy) when Soaked is there too.
# - Night Terror (Charged + Drowsy) waits for Starfall (a Pinned hit with Charged): Exposed there too (Pinned's Drowsy route).
# A Crowned one on its cooldown doesn't hold the base back.
static func _crowned_waiting(enemy: Node2D) -> Dictionary:
	var s: EnemyStatuses = enemy.statuses
	var waiting := {}
	if s.stacks(SPORED) >= need(MUSHROOM_MIN_SPORES) and s.stacks(DAMP) >= need(SOAKED_NEEDED) and not s.is_on_cooldown(&"mushrooming") \
			and grown(s, [SPORED, DAMP]):
		waiting[&"sleepwalk"] = &"nightbloom"
	# (council rx review 2026-10-17) A Pin waits for its Starfall at most PIN_WAIT s (&"pin_wait", set when Pinned), and
	# only while a Warden can reach it; Fever Dream: no Sleepwalk while a Smother runs or is ready (Rooted + Poisoned).
	if s.stacks(STATIC) >= need(CROWNED_MIN_STATIC) and ((s.pinned and s.is_on_cooldown(&"pin_wait") and _warden_reaches(enemy))
			or (not s.pinned and s.stacks(MARKED) >= need(EXPOSED_NEEDED) and not s.is_on_cooldown(&"pinned")
			and grown(s, [MARKED, HELD, DROWSY]))):
		waiting[&"night_terror"] = &"starfall"
	if s.smothering or (s.stacks(HELD) >= need(ROOTED_NEEDED) and s.stacks(SPORED) >= need(SMOTHER_MIN_SPORES)):
		waiting[&"sleepwalk"] = &"fever_dream"
	return waiting

# (council rx review 2026-10-17) True if an attacking Warden has `enemy` in range (Night Terror's wait for a Starfall).
static func _warden_reaches(enemy: Node2D) -> bool:
	for tower in enemy.get_tree().get_nodes_in_group(Tower.GROUP):
		if tower is Tower and tower.tower_data.can_attack and tower.global_position.distance_to(enemy.global_position) <= tower.get_range_pixels():
			return true
	return false

# (council rx review 2026-10-17) True if `enemy` stands in a Dreamcatcher's range (Sleepwalk and Night Terror wait there,
# so the Catch works).
static func near_dreamcatcher(enemy: Node2D) -> bool:
	for tower in enemy.get_tree().get_nodes_in_group(Tower.GROUP):
		if tower is Tower and (tower.tower_data.caught_bonus > 0.0 or tower.tower_data.caught_shards) \
				and tower.global_position.distance_to(enemy.global_position) <= tower.get_range_pixels():
			return true
	return false

# A Reaction's need of a status (owner 2026-10-16, option A): the normal amount, Brimming or not (Clashing Notes: half).
static func need(base: int) -> int:
	return ceili(base / 2.0) if _half_need and base in HALF_NEED_BASES else base

# The stacks of status `id` from which some Reaction can count it: the lowest of its Reactions' needs, through need()
# (Brimming never raises a Reaction's need, owner 2026-10-16), 0 when no Reaction uses `id`; Sleep counts only full.
# For the status row's Reaction-ready frame (screens_ui.md "Status row: Reaction-ready marks and falling asleep";
# Enemy Code 2026-10-18). Keep it in step when a Reaction's threshold changes.
static func ready_need(id: StringName, s: EnemyStatuses) -> int:
	match id:
		EnemyStatuses.DAMP:
			return need(SOAKED_NEEDED)
		EnemyStatuses.HELD:
			return need(ROOTED_NEEDED)
		EnemyStatuses.MARKED:
			return need(EXPOSED_NEEDED)
		EnemyStatuses.STATIC:
			return need(IGNITE_MIN_STATIC)  # Ignite, Night Terror (Thunderclap's own is higher)
		EnemyStatuses.SPORED:
			return need(mini(IGNITE_MIN_SPORES, mini(SMOTHER_MIN_SPORES, MUSHROOM_MIN_SPORES)))  # (Sleepwalk too)
		EnemyStatuses.DROWSY:
			return s.normal_cap(EnemyStatuses.DROWSY)  # Full Sleep (its normal cap, as the checks read it): Drown, Pinned, Sleepwalk, Night Terror
	return 0

# Brimming's doubled count, for what still doubles: card and Warden payoffs that read it (not Reactions).
static func buildup_threshold(base: int) -> int:
	if _half_need and base in HALF_NEED_BASES:
		return ceili(base * EnemyStatuses.cap_multiplier() / 2.0)
	return base * EnemyStatuses.cap_multiplier()

static func thunderclap_threshold(statuses: EnemyStatuses) -> int:
	var need: int = THUNDERCLAP_STATIC_BOSS if statuses.is_boss else THUNDERCLAP_STATIC  # The normal need, Brimming or not
	return ceili(need / 2.0) if _half_need else need

# Clashing Notes (Bellflower lent card, Roguelite Code 2026-10-14; dream_council_review.md 26): a bell's hit on a Drowsy
# nightmare sets off any Reaction it is halfway to. Poisoned, Charged and Soaked count at half their need; Drowsy and
# Exposed must still be full; never Pinned, Shatter or Smother (Rooted). Grown, cooldowns and Crowned are unchanged.
# The half need holds only while this nightmare's own check runs (on_status for any other nightmare clears it).
static var _half_need := false
const HALF_NEED_BASES: Array[int] = [SOAKED_NEEDED, IGNITE_MIN_STATIC, IGNITE_MIN_SPORES, MUSHROOM_MIN_SPORES]

# Keyword chips 2026-10-16 (TD 4): Heavy Heart and Witching Bend set Reactions off at half need too, but such a half
# set-off deals HALF_SET_OFF_DAMAGE of its burst (`damage_share`; Clashing Notes keeps 1.0), so Brimming's cost stays.
const HALF_SET_OFF_DAMAGE := 0.5
static var _half_share := 1.0

static func check_at_half(enemy: Node2D, source: Node, damage_share: float = 1.0) -> void:
	if not is_instance_valid(enemy) or enemy.is_cleansed or enemy.statuses.count() < 2:
		return
	var s: EnemyStatuses = enemy.statuses
	_half_need = true
	var waiting := _crowned_waiting(enemy)  # Crowned precedence (owner 2026-10-17), at the half need too
	var share_before := _half_share
	_half_share = damage_share
	if s.stacks(DAMP) >= need(SOAKED_NEEDED) and s.stacks(STATIC) >= thunderclap_threshold(s) and grown(s, [DAMP, STATIC]):
		_thunderclap(enemy, source)
	if not enemy.is_cleansed and s.stacks(SPORED) >= need(IGNITE_MIN_SPORES) and s.stacks(STATIC) >= need(IGNITE_MIN_STATIC) \
			and grown(s, [SPORED, STATIC]):
		_ignite(enemy, source)
	if not enemy.is_cleansed and s.stacks(SPORED) >= need(MUSHROOM_MIN_SPORES) and s.stacks(DAMP) >= need(SOAKED_NEEDED) \
			and grown(s, [SPORED, DAMP]):
		_mushrooming(enemy, source)
	if not enemy.is_cleansed and s.stacks(DAMP) >= need(SOAKED_NEEDED) and s.has(DROWSY) and s.stacks(DROWSY) >= s.normal_cap(DROWSY) \
			and grown(s, [DAMP, DROWSY]):
		_drown(enemy, source)
	_check_drowsy_pairs(enemy, source, waiting)  # Sleepwalk / Night Terror: Poisoned / Charged at half, Drowsy still full
	_half_need = false
	_half_share = share_before

# --- Potency (tower_design.md "Potency: effect damage") ---------------------------------------------

# Damage tags that are effects, not hits: they scale with the source Warden's Potency (and Seeping),
# never with crit (except Nightshade). Shatter's own hit is a hit; its spreads are effects.
const EFFECT_TAGS: Array[StringName] = [&"spored", &"static", &"thunderclap", &"ignite", &"lightning_rod",
	&"popped", &"echo", &"carried_storm", &"avalanche", &"starfall", &"fever_dream", &"smother", &"fog", &"cloud", &"harmony", &"last_breath", &"drown",
	&"lingering_splash", &"thorns", &"rain", &"sap", &"stone_relay", &"stored_rain", &"fifth_beat", &"crossfire"]  # thorns: Thorncoil; rain: Cloudlet / Nimbus (BranchKit); sap: Sap Rising (ShapeCards)

static func is_effect(tag: StringName) -> bool:
	return tag in EFFECT_TAGS

# Chain falloff (tower_design.md "Chain falloff", 2026-09-30): from the 6th link of a chain, each
# Reaction deals 15% less than the one before (6th ×0.85, 7th ×0.70 …), never below 25%. Read off the
# nightmare's chain mark (_fire sets it before the Reaction deals its damage). Chain counts, discoveries
# and Dawnbreak still count every link; Dawnbreak's own damage isn't reduced. Enemy.take_damage asks.
const CHAIN_FALLOFF_FROM := 6  # The default start…
static var chain_falloff_from: int = CHAIN_FALLOFF_FROM  # …the live one (card pass 1f: Unbroken Chain moves it; whoever sets it resets it at run start)
const CHAIN_FALLOFF_STEP := 0.15
const CHAIN_FALLOFF_FLOOR := 0.25
const CHAIN_FALLOFF_TAGS: Array[StringName] = [&"thunderclap", &"ignite", &"shatter", &"pinned", &"lightning_rod",
	&"echo", &"carried_storm", &"avalanche", &"starfall", &"fever_dream", &"drown", &"smother"]  # smother: its burst (2026-10-17)

static var chain_falloff_on := true  # Balance sims: --no-falloff measures without it

static func chain_falloff(enemy: Node2D, tag: StringName) -> float:
	if not chain_falloff_on or not tag in CHAIN_FALLOFF_TAGS:
		return 1.0
	var s: EnemyStatuses = enemy.statuses
	return chain_falloff_at(s.chain_count if s.chain_time > 0.0 else 1)

# The falloff for link `chain` of a chain (1.0 up to the 5th).
static func chain_falloff_at(chain: int) -> float:
	if chain < chain_falloff_from:
		return 1.0
	return maxf(1.0 - CHAIN_FALLOFF_STEP * (chain - chain_falloff_from + 1), CHAIN_FALLOFF_FLOOR)

# Effect damage × the source's Potency × Seeping (1 + 5% per status the nightmare carries).
static func effect_multiplier(enemy: Node2D, source: Tower) -> float:
	var multiplier := source.get_potency()
	var dreams := _dreams(enemy)
	if dreams and dreams.has_method("get_effect_bonus"):
		multiplier *= 1.0 + dreams.get_effect_bonus(enemy)  # Seeping
	multiplier *= 1.0 + nightshade_bonus(enemy)  # Nightshade multiplies with Potency and Seeping (Balancing 738088c3)
	if enemy.statuses.mushroom_time > 0.0:  # Inside a Mushrooming cloud (owner 2026-10-17, council reactions_unique.md)
		multiplier *= 1.0 + MUSHROOM_ZONE_BONUS * enemy.statuses.mushroom_payoff  # The cloud's own Brimming payoff (council rx review 2026-10-17)
	return multiplier

# Nightshade (Legendary #112; dream_design.md e1e39b56): effect damage ×2 on a nightmare carrying 4 or more statuses
# (one per status, not per stack; the one dealing the damage counts too). Multiplies with Potency and Seeping. The
# bonus part (1.0 = ×2), 0 without the card or under 4 statuses. Also shown on the nightmare's info card.
const NIGHTSHADE_MIN_STATUSES := 4
const NIGHTSHADE_MULTIPLIER := 2.0

static func nightshade_bonus(enemy: Node2D) -> float:
	var dreams := _dreams(enemy)
	if dreams == null or not dreams.has_rule(&"nightshade"):
		return 0.0
	return NIGHTSHADE_MULTIPLIER - 1.0 if enemy.statuses.active_ids().size() >= NIGHTSHADE_MIN_STATUSES else 0.0

static func is_crowned(id: StringName) -> bool:
	return CROWNED_BASE.has(id)

# Fever Dream: Smother just ended on a nightmare at full Drowsy. Its remaining Spored damage resolves
# at once, and adjacent nightmares get Spored + Drowsy (a sleep plague).
static func on_smother_ended(enemy: Node2D) -> void:
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	_smother_burst(enemy)
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	var s: EnemyStatuses = enemy.statuses
	if s.stacks(SPORED) < need(SMOTHER_MIN_SPORES) or not s.has(DROWSY) or s.stacks(DROWSY) < s.normal_cap(DROWSY):
		return
	var spore_source := s.source(SPORED)
	var chain := _fire(enemy, &"fever_dream", _towers(spore_source, s.source(DROWSY)), false, CROWNED_LINKS)
	if chain <= 0:
		return
	var potency := s.potency(SPORED)
	var line := s.spore_line()
	var dreams := _dreams(enemy)
	var pitch := dreams != null and dreams.has_rule(&"fever_pitch")
	var neighbours := _others_within(enemy, FEVER_REACH + _storm_front(enemy))
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
		# Fever Pitch (owner 2026-10-17, council reactions_unique.md; was bigger stacks): the neighbours who catch the
		# fever fall Asleep FEVER_PITCH_SLEEP s too (once each per Fever Dream; never bosses).
		if pitch and is_instance_valid(other) and not other.is_cleansed and not other.statuses.is_boss:
			other.statuses.sleep(FEVER_PITCH_SLEEP)

# Smother's burst (owner 2026-10-17, council reactions_unique.md): when Smother ends (the Root broke, or its Poisoned fell
# below the need), every Poisoned tick it stored while Rooted (EnemyStatuses.smother_stored) lands at once, x SMOTHER_BURST,
# credited to the Warden whose ticks they were. An effect (tag "smother": Potency, Seeping and the Mushrooming zone count).
static func _smother_burst(enemy: Node2D) -> void:
	var s: EnemyStatuses = enemy.statuses
	var stored := s.smother_stored
	var source: Node = s.smother_source if is_instance_valid(s.smother_source) else null
	var line := s.smother_line
	var credit := s.smother_credit_list()  # (council rx review 2026-10-17) each applier's share of what it stored
	s.smother_stored = 0.0
	s.smother_source = null
	s.smother_credit.clear()
	if stored <= 0.0:
		return
	var world := _world(enemy)
	if world != null:
		_effect(&"hit_spore", enemy.global_position, enemy, 1.75)  # Stand-in for a burst sheet (open item for Fx)
		var data := get_data(&"smother")
		var ring := Fx.FxRing.new(data.callout_color if data else Palette.SPRIG, 10.0, 44.0, 0.4)
		world.add_child(ring)
		ring.global_position = enemy.global_position
	# (council rx review 2026-10-17) The burst goes through the normal Poisoned tick hooks: Soaked Rot, Lichenling and the
	# cohort credit split (DamageLog reads spore_tick_credit while delivering_spore_tick); only its x SMOTHER_BURST bonus
	# counts as Reaction damage (Enemy.REACTION_BONUS_ONLY).
	var amount := _rx(enemy, stored * SMOTHER_BURST, &"smother")
	var dreams := _dreams(enemy)
	if dreams != null:
		amount *= dreams.get_spored_tick_multiplier(enemy)  # Soaked Rot
	BranchKit.on_spore_tick(enemy)  # Lichenling
	s.spore_tick_credit = credit
	s.delivering_spore_tick = true
	enemy.take_damage(amount, line, true, false, source, &"smother")
	s.delivering_spore_tick = false

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
		return 4 + gift
	return (12 if dreams.rule_level(&"heavy_eyelids") > 0 else 8) + gift

# Before a Warden's hit: Pinned turns it into a ×4 crit, and Shatter (Held + Damp, hit by a crit or
# a heavy hitter) makes it ×4. Returns {"crit", "crit_multiplier", "multiplier", "shatter", "tag"}.
static func before_hit(enemy: Node2D, tower: Tower, is_crit: bool) -> Dictionary:
	var result := {"crit": is_crit, "crit_multiplier": tower.attack_data.crit_multiplier, "multiplier": 1.0,
		"shatter": false, "tag": &"", "pierce": false, "starfall": false}
	var s: EnemyStatuses = enemy.statuses
	if s.pinned:
		var star := s.star_pinned  # Falling Stars' Pin: a x2 crit, no pierce (owner 2026-10-17)
		s.pinned = false
		s.star_pinned = false
		result.crit = true
		var pin_payoff := 1.0 if star else s.reaction_payoff(&"pinned")
		var pin_power := STAR_PIN_CRIT if star else PINNED_MULTIPLIER * pin_payoff
		var pinned_crit := maxf(pin_power, tower.attack_data.crit_multiplier)
		result.crit_multiplier = 1.0 + (pinned_crit - 1.0) * _rx_cards(enemy, &"pinned", tower)  # The bonus part only (the hit lands anyway)
		result.tag = &"pinned"
		result.pin_payoff = pin_payoff  # (council rx review 2026-10-17) Starfall's stars swap this for Starfall's own
		s.star_pin_hit = star  # (council rx review 2026-10-17) Enemy credits a star-Pin crit at x STAR_PIN_CRIT, not x3
		# Pinned's pierce and Starfall's stars land after the hit, from its damage (Tower.hit -> after_pinned_hit).
		result.pierce = not star
		result.at = enemy.global_position
		if s.stacks(STATIC) >= need(CROWNED_MIN_STATIC):
			result.starfall = _starfall(enemy, tower)
	# One "heavy" (card pass 2026-10-16, card_pass_td.md 1d): the heavy cards' role (TowerData.heavy) or Shatter's old
	# rule (the stone line, a target-priority sniper), so no Warden that Shattered before stops, and every heavy card's Warden can.
	var heavy: bool = WardenRoles.has_role(tower.attack_data, WardenRoles.HEAVY) or tower.tower_data.line == "stone" or tower.attack_data.has_target_priority
	if s.stacks(HELD) >= need(ROOTED_NEEDED) and s.stacks(DAMP) >= need(SOAKED_NEEDED) and (result.crit or heavy) and grown(s, [HELD, DAMP]):
		# Crowned: a lob's Shatter becomes an Avalanche, a charged one a Prismstorm.
		var id := &"shatter"
		if tower.attack_data.lob:
			id = &"avalanche"
		elif s.stacks(STATIC) >= need(CROWNED_MIN_STATIC):
			id = &"prismstorm"
		var crowned := id != &"shatter"
		if _fire(enemy, id, [tower], false, CROWNED_LINKS if crowned else 1, &"shatter") > 0:
			s.remove(HELD)
			result.multiplier = 1.0 + (SHATTER_MULTIPLIER * s.reaction_payoff(id) - 1.0) * _rx_cards(enemy, id, tower)  # Bonus part (Shatter / Prismstorm / Avalanche)
			result.shatter = true
			result.tag = &"shatter"
			s.prism_pending = id == &"prismstorm"
			if id == &"avalanche":
				_avalanche(enemy, tower)  # (owner 2026-10-17: scree, bosses' cells too; was more Shatters)
	return result

# Starfall (Pinned + Static), owner 2026-10-17, council reactions_unique.md: the event fires with the Pinned hit; its
# stars fall after the hit, from that hit's damage (after_pinned_hit). True if it fired.
static func _starfall(enemy: Node2D, tower: Tower) -> bool:
	var s: EnemyStatuses = enemy.statuses
	return _fire(enemy, &"starfall", _towers(tower, s.source(STATIC)), false, CROWNED_LINKS) > 0

# After a Pinned hit that dealt `dealt` (Tower.hit, owner 2026-10-17, council reactions_unique.md):
# - Pinned's pierce: every nightmare in a PIN_PIERCE_CELLS line behind the target, away from the Warden, takes
#   PIN_PIERCE_SHARE of the hit (straight corridors pay). Not for a Falling Stars Pin.
# - Starfall's stars: each nightmare with Exposed at the Reaction need within STARFALL_REACH of the target is struck by a
#   crit for STARFALL_SHARE of the hit (no bolts: council rx review 2026-10-17, that verb is Prismstorm's). Falling
#   Stars: each one a star hits is Pinned too (its next hit a STAR_PIN_CRIT crit, no pierce).
# (council rx review 2026-10-17) `dealt` already carries the Reaction cards and the build multiplier (the crit's bonus
# part, before_hit), so the pierce and the stars go through _rx_spill (no second build multiplier); the stars swap the
# Pin's Brimming payoff for Starfall's own (one id).
static func after_pinned_hit(enemy: Node2D, tower: Tower, dealt: float, reaction: Dictionary) -> void:
	if dealt <= 0.0 or not is_instance_valid(tower) or not tower.is_inside_tree():
		return
	var at: Vector2 = reaction.get("at", enemy.global_position if is_instance_valid(enemy) else tower.global_position)
	var chain: int = enemy.statuses.chain_count if is_instance_valid(enemy) and enemy.statuses.chain_time > 0.0 else 1
	if reaction.get("pierce", false):
		var direction := (at - tower.global_position).normalized()
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT
		var length := PIN_PIERCE_CELLS * CELL
		var pierced := 0
		for other in Tower.nightmares_near(tower.get_tree(), at + direction * length * 0.5, length * 0.5 + PIN_PIERCE_WIDTH * CELL):
			if other == enemy or not is_instance_valid(other) or other.is_cleansed:
				continue
			var offset: Vector2 = other.global_position - at
			var along := offset.dot(direction)
			if along <= 0.0 or along > length or absf(offset.cross(direction)) > PIN_PIERCE_WIDTH * CELL:
				continue
			_touch(other, chain, [tower])
			other.take_damage(_rx_spill(other, dealt * PIN_PIERCE_SHARE), tower.tower_data.line, true, false, tower, &"pinned")
			pierced += 1
		if pierced > 0:
			_segment(&"thunderclap_arc", at, at + direction * length, tower, 0.25)  # Stand-in for a spear line (open item for Fx)
	if not reaction.get("starfall", false):
		return
	var dreams := _dreams(tower)
	var pins := dreams != null and dreams.has_rule(&"falling_stars")
	var star_payoff: float = enemy.statuses.reaction_payoff(&"starfall") if is_instance_valid(enemy) else 1.0
	var star_damage: float = dealt * STARFALL_SHARE / maxf(float(reaction.get("pin_payoff", 1.0)), 0.001) * star_payoff
	var reach := (STARFALL_REACH + (_storm_front(enemy) if is_instance_valid(enemy) else 0.0)) * CELL
	for other in Tower.nightmares_near(tower.get_tree(), at, reach):
		if other == enemy or not is_instance_valid(other) or other.is_cleansed or other.global_position.distance_to(at) > reach:
			continue
		if other.statuses.stacks(MARKED) < need(EXPOSED_NEEDED):
			continue  # Exposed at a Reaction's need (as Pinned); Charged alone draws no star
		_segment(&"thunderclap_arc", at, other.global_position, tower, 0.3)  # A star falls on it
		_touch(other, chain, [tower])
		other.take_damage(_rx_spill(other, star_damage), "light", false, true, tower, &"starfall")
		if pins and is_instance_valid(other) and not other.is_cleansed and not other.statuses.pinned:
			other.statuses.pinned = true
			other.statuses.star_pinned = true

# Avalanche (a lob's Shatter), owner 2026-10-17, council reactions_unique.md: the target Shatters as usual, and scree
# covers the path cells under the stone for SCREE_TIME s (RubblePatch): walkers are SCREE_SLOW slower and gain 1 Rooted
# every SCREE_ROOT_EVERY s, up to SCREE_ROOT_MAX each (setting up the next Shatter). Mountain's Fall: it Soaks them too.
static func _avalanche(enemy: Node2D, tower: Tower) -> void:
	var reach := maxf(tower.get_splash_cells(), 1.0)
	var centre: Vector2 = Tower.MAP_GRID.calculate_grid_coordinates(enemy.global_position)
	var route := _route_cells(enemy)
	var cells: Array[Vector2] = []
	var span := ceili(reach)
	for dy in range(-span, span + 1):
		for dx in range(-span, span + 1):
			var c := centre + Vector2(dx, dy)
			if Vector2(dx, dy).length() <= reach + 0.01 and (route.is_empty() or route.has(c)):
				cells.append(c)
	if not cells.has(centre):
		cells.append(centre)
	var world := _world(enemy)
	if world == null:
		return
	var dreams := _dreams(enemy)
	var scree := RubblePatch.new(cells, SCREE_SLOW, SCREE_TIME)
	scree.rooted_every = SCREE_ROOT_EVERY
	scree.rooted_max = SCREE_ROOT_MAX
	scree.rooted_time = SCREE_ROOT_TIME
	scree.soak_every = 1.0 if dreams != null and dreams.has_rule(&"mountains_fall") else 0.0
	scree.soak_stacks = SCREE_SOAK
	scree.source = tower
	world.add_child(scree)

# After a Shatter hit that dealt `dealt`: ice shards deal half of it to nightmares within 1 cell.
static func shatter_splash(enemy: Node2D, tower: Tower, dealt: float) -> void:
	var chain: int = enemy.statuses.chain_count if enemy.statuses.chain_time > 0.0 else 1
	# Prismstorm (owner 2026-10-17, council reactions_unique.md): each shard that hits a nightmare with CROWNED_MIN_STATIC
	# Charged sets off its bolt at once (no Charged spread). Prism Heart: the shards fly along the path instead, to the
	# nightmares on the path cells PRISM_ROUTE_CELLS ahead of and behind it.
	var prism: bool = enemy.statuses.prism_pending
	enemy.statuses.prism_pending = false
	var dreams := _dreams(enemy)
	var targets: Array = []
	if prism and dreams and dreams.has_rule(&"prism_heart"):
		targets = _along_route(enemy, PRISM_ROUTE_CELLS + _storm_front(enemy))
	else:
		targets = _others_within(enemy, 1.0 + _storm_front(enemy))
	for other in targets:
		_touch(other, chain, [tower])
		# (council rx review 2026-10-17) `dealt` already carries the cards, build multiplier and payoff: no second _rx.
		other.take_damage(_rx_spill(other, dealt * SHATTER_SPLASH), tower.tower_data.line, true, false, tower, &"shatter")
		if prism and is_instance_valid(other) and not other.is_cleansed and other.statuses.stacks(STATIC) >= need(CROWNED_MIN_STATIC):
			var bolt: float = other.statuses.stored_bolt_damage()
			var charger: Node = other.statuses.source(STATIC) if is_instance_valid(other.statuses.source(STATIC)) else tower
			other.statuses.remove(STATIC)
			strike_bolt(other, bolt, charger, &"static")  # The shard sparks its bolt

# (council rx review 2026-10-17) The first whole path cell ahead of `enemy` on its route that isn't `cell` (`cell` if none:
# a flyer, or the route's end). Mushrooming's zone reaches it.
static func _next_path_cell(enemy: Node2D, cell: Vector2) -> Vector2:
	if enemy.is_flying() or not enemy.has_method("get_cells_ahead"):
		return cell
	var grid := Tower.MAP_GRID
	for point in enemy.get_cells_ahead(6):
		var next: Vector2 = grid.calculate_grid_coordinates(grid.calculate_map_position(point))
		if next != cell:
			return next
	return cell

# Prism Heart: the other nightmares standing on the path cells within `cells` ahead of or behind `enemy` on its route.
static func _along_route(enemy: Node2D, cells: float) -> Array:
	var points: PackedVector2Array = PackedVector2Array()
	if enemy.has_method("get_cells_ahead"):
		var step: float = enemy._step_cells(enemy._path_index)
		var count := ceili(cells / maxf(step, 0.25))
		points.append_array(enemy.get_cells_ahead(count))
		var behind: PackedVector2Array = enemy.get_cells_behind()
		points.append_array(behind.slice(maxi(behind.size() - count, 0)))
	var grid := Tower.MAP_GRID
	var whole := {}
	for p in points:
		whole[grid.calculate_grid_coordinates(grid.calculate_map_position(p))] = true  # Route points (half cells) to whole cells
	whole[grid.calculate_grid_coordinates(enemy.global_position)] = true
	var list: Array = []
	for other in Tower.nightmares_near(enemy.get_tree(), enemy.global_position, (cells + 1.0) * CELL):
		if other != enemy and is_instance_valid(other) and not other.is_cleansed and not other.is_flying() \
				and whole.has(grid.calculate_grid_coordinates(other.global_position)):
			list.append(other)
	return list

# A Static bolt worth `damage` goes off on `target` (a 5-stack bolt, or a Thunderclap arc). A Marked,
# charged nightmare within 3 cells takes it instead at ×2 (Lightning Rod). Returns who was struck.
static func strike_bolt(target: Node2D, damage: float, tower: Node, tag: StringName = &"static", rx_id: StringName = &"") -> Node2D:  # rx_id: the Reaction for the damage hook (Tempest arcs; card pass 2026-10-16)
	if tag == &"static":
		var dreams := _dreams(target)
		if dreams != null and dreams.has_method("get_bolt_multiplier"):
			damage *= dreams.get_bolt_multiplier()  # Live Wire (Dream): Charged bolts +15% per stack
	var rod := _find_rod(target)
	if rod == null:
		var at := target.global_position
		var tracker := ReactionTracker.find(target) if tag == &"static" else null  # Found first: the bolt may dispel it
		target.take_damage(damage if tag == &"static" else _rx(target, damage, rx_id if rx_id != &"" else tag), "light", false, false, tower, tag)  # A Charged bolt isn't a Reaction
		if tag == &"static" and is_instance_valid(target) and target.has_meta(BranchKit.LINK_META):
			BranchKit.share_bolt(target, damage, tower)  # Maelstrom: the bolt travels the current
		if tag == &"static":
			var reach := _static_field(target, at, damage, tower)
			_bolt_seen(target, at, damage, reach, tracker)
			_live_wire(target, at, damage, tower)
		return target
	_fire(rod, &"lightning_rod", [tower] if tower else [], true)
	rod.take_damage(_rx(rod, damage * ROD_MULTIPLIER / (EnemyStatuses.charged_payoff_multiplier() if tag == &"static" else 1.0), &"lightning_rod"), "light", false, false, tower, &"lightning_rod")
	return rod

# Live Wire ("Fewer, bigger cards" de439ea8; Balancing: full damage): a Charged bolt jumps once to the nearest other
# nightmare within LIVE_WIRE_REACH, at the same damage. A plain hit, so it never sets off more bolts or Reactions.
const LIVE_WIRE_REACH := 2.0  # Cells
static func _live_wire(target: Node2D, at: Vector2, damage: float, tower: Node) -> void:
	var dreams := _dreams(target) if is_instance_valid(target) else null
	if dreams == null or not dreams.has_rule(&"live_wire") or damage <= 0.0:
		return
	var reach := LIVE_WIRE_REACH * Tower.MAP_GRID.cell_size.x
	var next: Node2D = null
	var best := INF
	for other in Tower.nightmares_near(dreams.get_tree(), at, reach):
		if other == target or not is_instance_valid(other) or other.is_cleansed:
			continue
		var d: float = other.global_position.distance_to(at)
		if d <= reach and d < best:
			best = d
			next = other
	if next == null:
		return
	var points := PackedVector2Array([at, next.global_position])
	var world := _world(tower if is_instance_valid(tower) else next)
	if world != null and not Fx.reduce_flashes():
		var bolt := ChainBolt.new(points)
		world.add_child(bolt)
	next.take_damage(damage, "light", false, false, tower, &"static")

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
		if other.statuses.stacks(MARKED) < need(EXPOSED_NEEDED) or other.statuses.stacks(STATIC) < thunderclap_threshold(other.statuses) or not grown(other.statuses, [MARKED, STATIC]):
			continue
		var distance: float = other.global_position.distance_to(near.global_position)
		if distance <= ROD_REACH * CELL and distance < best_distance:
			best_distance = distance
			best = other
	return best


# --- The Reactions ----------------------------------------------------------------------------------

# 8 Damp + 10 Static (15 bosses): discharges for 12× the applier's damage and arcs to every Damp nightmare nearby for
# 6×, each arc adding Static (so wet crowds chain). Uses up the Static.
static func _thunderclap(enemy: Node2D, source: Node) -> void:
	var s: EnemyStatuses = enemy.statuses
	var tower := _tower_of(source, s.source(STATIC))
	# Crowned: a Spored nightmare's Thunderclap is a Tempest (not again within 2 s of the last one).
	var tempest := s.stacks(SPORED) >= need(CROWNED_MIN_SPORES) and s.tempest_time <= 0.0
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
	# (Tempest's Reach no longer widens the arcs: owner 2026-10-17; its burns spread Soaked instead, _burn_spread.)
	var reach: float = (THUNDERCLAP_REACH[level] + _storm_front(enemy)) * CELL
	if dreams and dreams.has_rule(&"conductive_soil") and tower:
		reach = maxf(reach, tower.get_range_pixels())  # The Storm Grid capstone
	var arcs: Array = []
	for other in Tower.nightmares_near(enemy.get_tree(), enemy.global_position, reach):
		if other != enemy and is_instance_valid(other) and not other.is_cleansed and other.statuses.stacks(DAMP) >= need(SOAKED_NEEDED) and other.global_position.distance_to(enemy.global_position) <= reach:
			arcs.append(other)
	# At most the THUNDERCLAP_MAX_ARCS nearest Soaked nightmares per clap (design chat; also bounds a
	# chain's cost). Chains still continue from those.
	# Rolling Thunder's cost (dream_design.md 83c40cd7): its longer arcs strike at most ROLLING_THUNDER_ARCS nightmares.
	var max_arcs := ROLLING_THUNDER_ARCS if level > 0 else THUNDERCLAP_MAX_ARCS
	if arcs.size() > max_arcs:
		var at: Vector2 = enemy.global_position
		arcs.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
		arcs = arcs.slice(0, max_arcs)
	enemy.take_damage(_rx(enemy, base * THUNDERCLAP_DAMAGE, &"tempest" if tempest else &"thunderclap"), _line(tower, "light"), false, false, tower, &"thunderclap")
	for other in arcs:
		if not is_instance_valid(other) or other.is_cleansed:
			continue
		_segment(&"thunderclap_arc", enemy.global_position, other.global_position, enemy, 0.25)
		_touch(other, chain, _towers(tower))
		var struck := strike_bolt(other, base * THUNDERCLAP_ARC_DAMAGE, tower, &"thunderclap", &"tempest" if tempest else &"")
		if is_instance_valid(other) and dreams and dreams.has_rule(&"conductive_soil"):
			other.statuses.remove(DAMP)  # Conductive Soil's cost: each jump uses up that nightmare's Soaked
		if is_instance_valid(struck) and not struck.is_cleansed:
			struck.apply_status(STATIC, THUNDERCLAP_ARC_STATIC[level], 0.0, potency, 0, "light", tower)
		# Tempest: every arc also sets off Ignite on a Spored target (not bosses), whose spread spores
		# carry Static, so wet neighbours Thunderclap in turn.
		if tempest and is_instance_valid(other) and not other.is_cleansed and other.statuses.stacks(SPORED) >= need(IGNITE_MIN_SPORES) \
				and not other.statuses.is_boss:
			other.statuses.tempest_time = TEMPEST_LOCK
			_ignite(other, tower, potency)

# 3+ Spored + any Static: every Spored stack goes off at once (×1.5 of what it had left) and a stack
# spreads to neighbours, who may Ignite in turn. Uses up the Spored.
static func _ignite(enemy: Node2D, source: Node, carry_static: float = 0.0, spread: int = 0) -> void:
	var s: EnemyStatuses = enemy.statuses
	if s.stacks(SPORED) < need(IGNITE_MIN_SPORES) or s.stacks(STATIC) < need(IGNITE_MIN_STATIC):
		return
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
	var rate := BURN_SPORE_RATE * sparking * _payoff(enemy, &"tempest" if carry_static > 0.0 else &"ignite")
	s.burn_rate = 1.0 + (rate - 1.0) * _rx_cards(enemy, &"tempest" if carry_static > 0.0 else &"ignite", static_source)  # The bonus part (Ignite / Tempest)
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
	# Tempest's Reach (owner 2026-10-17, council reactions_unique.md): a Tempest's burns also spread Soaked, so the arcs never run dry.
	var soak := carry_static > 0.0 and dreams != null and dreams.has_rule(&"eye_of_the_tempest")
	for other in _others_within(enemy, IGNITE_REACH[level] + _storm_front(enemy)):
		if not is_instance_valid(other) or other.is_cleansed:
			continue
		_touch(other, chain, _towers(spore_source))
		if soak:
			other.apply_status(DAMP, TEMPEST_SOAK, 0.0, 0.0, 0, "water", static_source if static_source else spore_source)
		if not is_instance_valid(other) or other.is_cleansed:
			continue
		if carry_static > 0.0:
			other.apply_status(STATIC, 1, 0.0, carry_static, 0, "light", static_source if static_source else spore_source)  # Tempest: burns carry Static (its charger's)
		if is_instance_valid(other) and not other.is_cleansed:
			other.apply_status(SPORED, stacks, 0.0, potency, 0, line, spore_source)
			spread_any = true
	if level > 0 and spread_any and is_instance_valid(enemy) and not enemy.is_cleansed:
		s.remove(SPORED)  # Wildfire Spores' cost (dream_design.md 83c40cd7): spreading 2 burns away its own Poisoned

# 12 Spored + 8 Damp: a spore cloud grows on the tile for 4 s; nightmares inside take MUSHROOM_ZONE_BONUS more effect
# damage (owner 2026-10-17, council reactions_unique.md; was +50% Poisoned, and the cloud added Poisoned). Uses up Damp.
static func _mushrooming(enemy: Node2D, source: Node) -> void:
	var s: EnemyStatuses = enemy.statuses
	var spore_source := s.source(SPORED)
	# Crowned: on a Held nightmare it's a Fairy Circle, at full Drowsy a Nightbloom.
	var id := &"mushrooming"
	if s.stacks(HELD) >= need(ROOTED_NEEDED):
		id = &"fairy_circle"
	elif s.has(DROWSY) and s.stacks(DROWSY) >= s.normal_cap(DROWSY):
		id = &"nightbloom"
	var crowned := id != &"mushrooming"
	var chain := _fire(enemy, id, _towers(spore_source, _tower_of(source, s.source(DAMP))), false,
		CROWNED_LINKS if crowned else 1, &"mushrooming")
	if chain <= 0:
		return
	s.remove(DAMP)
	var zone_payoff := _payoff(enemy, id)  # (council rx review 2026-10-17) the cloud carries this Mushrooming's own payoff
	s.mushroom_time = maxf(s.mushroom_time, MUSHROOM_ZONE_HOLD)  # It stands in the cloud's zone (owner 2026-10-17; the cloud keeps it)
	s.mushroom_payoff = zone_payoff
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
		if ring_of_rings:
			rings.ring_stacks = ceili(CrownedGround.RING_STACKS * (1.0 + CROWNED_CARD_BONUS))  # Ring of Rings: +50% Poisoned (card pass 2026-10-16)
		rings.potency = s.potency(SPORED)
		rings.line = s.spore_line()
		rings.source = spore_source
		rings.chain = chain
		ground_parent.add_child(rings)
		return
	if id == &"nightbloom":
		# Endless Night (owner 2026-10-17, council reactions_unique.md; was longer and wider): a sleeper dispelled inside
		# leaves a new Nightbloom on its cell, once per cloud (CrownedGround.chains).
		var bloom := CrownedGround.new(CrownedGround.Kind.NIGHTBLOOM, [], NIGHTBLOOM_TIME,
			Tower.MAP_GRID.calculate_map_position(cell),
			(MUSHROOM_CLOUD_RADIUS * NIGHTBLOOM_WIDTH + _storm_front(enemy)) * CELL)
		bloom.chains = dreams != null and dreams.has_rule(&"endless_night")
		ground_parent.add_child(bloom)
		# Crowned precedence (owner 2026-10-17): the cloud holds it asleep, so no Sleepwalk on it while the cloud lasts.
		s.start_cooldown(&"sleepwalk", maxf(NIGHTBLOOM_TIME, float(s.reaction_cooldowns.get(&"sleepwalk", 0.0))))
	var time := MUSHROOM_CLOUD_TIME
	var radius := (MUSHROOM_CLOUD_RADIUS + _storm_front(enemy)) * CELL
	if dreams and dreams.has_rule(&"mushroom_rain"):
		# Mushroom Rain (card 134; dream_design.md 83c40cd7): the cloud covers the 8 tiles around it but lasts half as long.
		time *= MUSHROOM_RAIN_TIME
		radius = maxf(radius, MUSHROOM_RAIN_RADIUS * CELL)
	var cloud := ReactionCloud.new(Tower.MAP_GRID.calculate_map_position(cell), radius, time, s.potency(SPORED),
		s.spore_line(), spore_source, chain, zone_payoff)
	# (council rx review 2026-10-17) The zone also covers the next path cell ahead, so a walker spends about two cells in it.
	var next := _next_path_cell(enemy, cell)
	if next != cell:
		cloud.add_spot(Tower.MAP_GRID.calculate_map_position(next))
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
	var still := s.stacks(HELD) >= need(ROOTED_NEEDED)
	if _fire(enemy, &"still_pool" if still else &"drown", _towers(applier, s.source(DAMP)), false,
			CROWNED_LINKS if still else 1, &"drown") <= 0:
		return
	s.remove(DROWSY)
	s.drowned += 1
	if still:
		var cells: Array[Vector2] = [enemy.get_current_cell()]
		var pool := CrownedGround.new(CrownedGround.Kind.STILL_POOL, cells, STILL_POOL_TIME)
		pool.sleep_seconds = STILL_POOL_SLEEP  # Seconds a walker entering is pulled under
		# Deep Stillness (owner 2026-10-17, council reactions_unique.md; was longer pools): each nightmare pulled under
		# widens the pool onto the next path cell, up to STILL_POOL_MAX_CELLS (CrownedGround.grows).
		pool.grows = dreams != null and dreams.has_rule(&"deep_stillness")
		pool.route = _route_cells(enemy) if pool.grows else []
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
		enemy.take_damage(Reactions._rx(enemy, applier.get_damage() * step * _second, &"drown"), applier.tower_data.line, true, false, applier, &"drown")

# Marked + (Held or asleep or full Drowsy): the next Warden hit is a guaranteed ×3 crit. Uses up Marked.
# (2026-10-17, one full Drowsy, one Reaction: when the full Drowsy was what let it fire, it uses that up too.)
static func _pinned(enemy: Node2D, source: Node) -> void:
	var s: EnemyStatuses = enemy.statuses
	if s.pinned:
		return
	var by_drowsy := s.stacks(HELD) < need(ROOTED_NEEDED) and not is_asleep(enemy)
	if _fire(enemy, &"pinned", _towers(s.source(MARKED), _tower_of(source, s.source(HELD)))) <= 0:
		return
	s.remove(MARKED)
	if by_drowsy:
		s.remove(DROWSY)
	s.pinned = true

# Held + Spored: while held its Spored stops ticking and swells (EnemyStatuses.tick stores it), and bursts x2 when the
# Root breaks (_smother_burst, from on_smother_ended; owner 2026-10-17, council reactions_unique.md). Only the event is here.
static func _smother(enemy: Node2D, source: Node) -> void:
	var s: EnemyStatuses = enemy.statuses
	_fire(enemy, &"smother", _towers(s.source(SPORED), _tower_of(source, s.source(HELD))))

# --- Sleepwalk / Night Terror (Roguelite Code for the owner, 2026-10-17) -------------------------------------------------

# Poisoned + full Drowsy: it turns and walks back up its route for SLEEPWALK_TIME s (bosses SLEEPWALK_BOSS_TIME) at
# SLEEPWALK_SPEED of its speed (Enemy.sleepwalk), then carries on; each nightmare within SLEEPWALK_REACH while it walks
# turns round too, for SLEEPWALK_TURN_TIME s (once per sleepwalk; never bosses or flyers; x Brimming's payoff). Never a
# flyer itself (flyers don't walk the path), nor a Rooted / sinking one (it can't walk). Uses up the Drowsy.
static func _sleepwalk(enemy: Node2D, source: Node) -> void:
	var s: EnemyStatuses = enemy.statuses
	if not can_sleepwalk_again(enemy):
		return  # (council rx review 2026-10-17) Out of walks, or at the Heartwood / on the bridge: the Drowsy stays
	# Crowned (owner 2026-10-17, council reactions_unique.md): on an Exposed nightmare it is a Changeling (_changeling).
	# Never on a boss (council rx review 2026-10-17): a boss only Sleepwalks.
	var changeling := not s.is_boss and s.stacks(MARKED) >= need(EXPOSED_NEEDED)
	var chain := _fire(enemy, &"changeling" if changeling else &"sleepwalk", _towers(s.source(SPORED), _tower_of(source, s.source(DROWSY))),
		false, CROWNED_LINKS if changeling else 1, &"sleepwalk")
	if chain <= 0:
		return
	s.remove(DROWSY)
	if changeling:
		_changeling(enemy, chain, _tower_of(s.source(MARKED), source))
	start_sleepwalk(enemy, chain)

# Changeling (Crowned Sleepwalk on an Exposed nightmare; owner 2026-10-17, design in this chat's report): before it
# sleepwalks it trades places with the nightmare furthest along the path within CHANGELING_REACH (a walker: never a boss,
# a flyer, a leaping, dragged, Rooted or sleepwalking one). The Exposed one now leads, so every Warden aiming at the
# nightmare closest to the Heartwood turns on it; the leader is sent back to where it stood. Stolen Away (its Woven
# card): the one it traded with sleepwalks back STOLEN_WALK s too. Uses no status beyond Sleepwalk's Drowsy.
static func _changeling(enemy: Node2D, chain: int, applier: Node) -> void:
	var best: Node2D = null
	var best_left: float = enemy.get_remaining_distance()
	# (council rx review 2026-10-17) By route, never across walls: the partner must stand on one of this nightmare's own
	# route points within CHANGELING_REACH cells ahead (half-cell routes: twice as many points).
	var ahead := {}
	var step: float = enemy._step_cells(enemy._path_index)
	for point in enemy.get_cells_ahead(ceili(CHANGELING_REACH / maxf(step, 0.25)) + 1):
		ahead[point] = true
	for other in _others_within(enemy, CHANGELING_REACH):
		if other.statuses.is_boss or not can_sleepwalk(other) or other.is_dragged():
			continue
		if not ahead.has(other.get_route_point()) and not ahead.has(other.get_target_cell()):
			continue  # Not on this nightmare's route ahead (another corridor, or behind it)
		var left: float = other.get_remaining_distance()
		if left < best_left:
			best_left = left
			best = other
	if best == null or not enemy.has_method("trade_places"):
		return
	var from := enemy.global_position
	var to := best.global_position
	if not enemy.trade_places(best):
		return
	_touch(best, chain, _towers(applier))
	_effect(&"puffball_bloom", from, enemy, 0.75)  # Stand-ins (open item for Fx): a puff where each one vanishes…
	_effect(&"puffball_bloom", to, enemy, 0.75)
	_segment(&"thunderclap_arc", from, to, enemy, 0.3)  # …and the thread between them
	var dreams := _dreams(enemy)
	if dreams != null and dreams.has_rule(&"stolen_away"):
		best.sleepwalk(STOLEN_WALK, SLEEPWALK_SPEED)

static func can_sleepwalk(enemy: Node2D) -> bool:
	return enemy.has_method("sleepwalk") and not enemy.is_flying() and not enemy.is_sleepwalking() \
		and not enemy.statuses.is_held() and not enemy._leaping and enemy.can_walk_back()

# (council rx review 2026-10-17) can_sleepwalk, and it still has a walk left (SLEEPWALK_TIMES, bosses SLEEPWALK_BOSS_TIMES).
static func can_sleepwalk_again(enemy: Node2D) -> bool:
	var s: EnemyStatuses = enemy.statuses
	return can_sleepwalk(enemy) and s.sleepwalked < (SLEEPWALK_BOSS_TIMES if s.is_boss else SLEEPWALK_TIMES)

# The walk itself (also Heavy Heart's copy, Echo Hollow's echo and Carried Storm, at `share` of the time). Each counts
# toward the nightmare's SLEEPWALK_TIMES, and Sleepwalk's cooldown starts when it ends (council rx review 2026-10-17).
static func start_sleepwalk(enemy: Node2D, chain: int = 1, share: float = 1.0) -> void:
	if not is_instance_valid(enemy) or enemy.is_cleansed or not can_sleepwalk_again(enemy):
		return
	var s: EnemyStatuses = enemy.statuses
	var seconds := (SLEEPWALK_BOSS_TIME if s.is_boss else SLEEPWALK_TIME) * share
	var data := get_data(&"sleepwalk")
	enemy.sleepwalk(seconds, SLEEPWALK_SPEED, data.cooldown if data else 1.5)
	if not enemy.is_sleepwalking():
		return
	s.sleepwalked += 1
	var world := _world(enemy)
	if world != null:
		var towers: Array = s.chain_towers if s.chain_time > 0.0 else []
		world.add_child(Sleepwalker.new(enemy, SLEEPWALK_TURN_TIME * _payoff(enemy, &"sleepwalk"), chain, towers, seconds + SLEEPWALKER_EXTRA_LIFE))

# One sleepwalk: the spore trail behind it, and who it bumps turning round; frees itself when the walk ends.
class Sleepwalker extends Node:
	var enemy: Node2D
	var turn := 0.5
	var chain := 1
	var towers: Array = []
	var _touched := {}  # Instance id -> true: each nightmare is turned once per sleepwalk
	var _trail := 0.0
	# (council rx review 2026-10-17) A hard lifetime (it never outlives the walk by more than SLEEPWALKER_EXTRA_LIFE), a
	# search every SLEEPWALK_SEARCH_EVERY s, and it bumps only after it actually moved (a held / asleep sleepwalker standing
	# still is no turning post).
	var _life := 5.0
	var _search := 0.0
	var _last_at := Vector2.INF

	func _init(target: Node2D, turn_seconds: float, chain_count: int, chain_towers: Array, life: float = 5.0) -> void:
		enemy = target
		turn = turn_seconds
		chain = chain_count
		towers = chain_towers.duplicate()
		_life = life
		_touched[target.get_instance_id()] = true

	func _process(delta: float) -> void:
		_life -= delta
		if not is_instance_valid(enemy) or enemy.is_cleansed or not enemy.is_sleepwalking() or _life <= 0.0:
			queue_free()
			return
		_search -= delta
		if _search > 0.0:
			return
		_search = Reactions.SLEEPWALK_SEARCH_EVERY
		var moved: bool = _last_at != Vector2.INF and enemy.global_position.distance_squared_to(_last_at) > 0.25
		_last_at = enemy.global_position
		if not moved:
			return
		_trail -= Reactions.SLEEPWALK_SEARCH_EVERY
		if _trail <= 0.0:
			_trail = Reactions.SLEEPWALK_TRAIL_EVERY
			Reactions._effect(&"hit_spore", enemy.global_position, enemy, 0.75)  # The spore trail behind it
		for other in Reactions._others_within(enemy, Reactions.SLEEPWALK_REACH):
			var key: int = other.get_instance_id()
			if _touched.has(key):
				continue
			_touched[key] = true
			if other.statuses.is_boss or not Reactions.can_sleepwalk(other):
				continue  # Bosses are never turned; flyers, Rooted and sleepwalking ones neither
			Reactions._touch(other, chain, towers.filter(func(t) -> bool: return is_instance_valid(t)))
			other.sleepwalk(turn, Reactions.SLEEPWALK_SPEED)

# Charged + full Drowsy: it wakes screaming (Asleep ends, unless Nightbloom's lock holds it; the Drowsy is used up), its
# Charged goes off at once as a normal Charged bolt (strike_bolt: spent as usual, a Lightning Rod may take it), and every
# other nightmare within NIGHT_TERROR_RADIUS freezes in fear: Rooted for NIGHT_TERROR_ROOT s (bosses
# NIGHT_TERROR_BOSS_ROOT) with NIGHT_TERROR_ROOT_STACKS Rooted stacks (x Brimming's payoff), through Enemy.apply_status (a
# boss or sprinter immune to Rooted stays immune; the caps hold).
static func _night_terror(enemy: Node2D, source: Node) -> void:
	var s: EnemyStatuses = enemy.statuses
	var applier := _tower_of(s.source(STATIC), source)
	# Crowned (owner 2026-10-17, council reactions_unique.md): on a Rooted nightmare it is Wide Awake (_wide_awake).
	var awake := s.stacks(HELD) >= need(ROOTED_NEEDED)
	var chain := _fire(enemy, &"wide_awake" if awake else &"night_terror", _towers(applier, s.source(DROWSY)), false,
		CROWNED_LINKS if awake else 1, &"night_terror")
	if chain <= 0:
		return
	if awake:
		_wide_awake(enemy)
	var bolt := s.stored_bolt_damage()
	var charger: Node = s.source(STATIC) if is_instance_valid(s.source(STATIC)) else applier
	s.remove(STATIC)
	s.remove(DROWSY)
	if s.can_wake_from_hit():
		s.sleep_time = 0.0
		s.sleep_cooldown = EnemyStatuses.SLEEP_COOLDOWN_BOSS if s.is_boss else EnemyStatuses.SLEEP_COOLDOWN
	night_terror_fear(enemy, applier, chain)
	if is_instance_valid(enemy) and not enemy.is_cleansed and bolt > 0.0:
		strike_bolt(enemy, bolt, charger, &"static")  # A normal Charged bolt (council 2026-10-17: no x2)

# The scream: the ring and every other nightmare within NIGHT_TERROR_RADIUS of `enemy` Rooted in fear (also Heavy
# Heart's copy; `share` scales the time for echoes and Carried Storm).
static func night_terror_fear(enemy: Node2D, applier: Node, chain: int = 1, share: float = 1.0) -> void:
	var world := _world(enemy)
	if world != null:
		var data := get_data(&"night_terror")
		var ring := Fx.FxRing.new(data.callout_color if data else Palette.WRAITHLIGHT, 12.0, NIGHT_TERROR_RADIUS * CELL - 12.0, 0.5)
		world.add_child(ring)  # The scream ring, out to the fear's reach
		ring.global_position = enemy.global_position
	for other in _others_within(enemy, NIGHT_TERROR_RADIUS):
		terror_root(other, applier, chain, share)  # (council rx review 2026-10-17: no Brimming payoff on the fear)

static func terror_root(other: Node2D, applier: Node, chain: int = 1, share: float = 1.0) -> void:
	if not is_instance_valid(other) or other.is_cleansed:
		return
	_touch(other, chain, _towers(applier))
	var seconds := (NIGHT_TERROR_BOSS_ROOT if other.statuses.is_boss else NIGHT_TERROR_ROOT) * share
	other.apply_status(HELD, NIGHT_TERROR_ROOT_STACKS, seconds, 0.0, 0, "", applier if is_instance_valid(applier) else null)

# Wide Awake (Crowned Night Terror on a Rooted nightmare; owner 2026-10-17, design in this chat's report): the scream
# wakes your Wardens. Every Warden within WIDE_AWAKE_REACH of it attacks WIDE_AWAKE_SPEED faster for WIDE_AWAKE_TIME s
# (Tower.reaction_haste: a Reaction's, outside the Dream speed cap; a newer wake refreshes it, never stacks). Alarm
# Bells (its Woven card): every Warden touching a woken one wakes too (one step, not a chain). Sprouts and walls count
# only if they attack.
static func _wide_awake(enemy: Node2D) -> void:
	var world := _world(enemy)
	if world == null:
		return
	var at := enemy.global_position
	var reach := (WIDE_AWAKE_REACH + _storm_front(enemy)) * CELL
	var woken: Array = []
	for tower in enemy.get_tree().get_nodes_in_group(Tower.GROUP):
		if tower is Tower and is_instance_valid(tower) and tower.tower_data.can_attack and tower.global_position.distance_to(at) <= reach:
			woken.append(tower)
	var dreams := _dreams(enemy)
	if dreams != null and dreams.has_rule(&"alarm_bells"):
		var more: Array = []
		for tower in enemy.get_tree().get_nodes_in_group(Tower.GROUP):
			if not (tower is Tower) or woken.has(tower) or not tower.tower_data.can_attack:
				continue
			for near in woken:
				if tower.global_position.distance_to(near.global_position) <= 1.5 * CELL:  # Touching: the 8 around
					more.append(tower)
					break
		woken.append_array(more)
	var speed := WIDE_AWAKE_SPEED  # Never x Brimming, never above 40% (council rx review 2026-10-17); WardenWake keeps the max, refresh only
	for tower in woken:
		world.add_child(WardenWake.new(tower, speed, WIDE_AWAKE_TIME))

# One Warden woken by Wide Awake: its haste for a while, a gold ring when it wakes and a soft swirl while it lasts.
class WardenWake extends Node:
	const SERIAL_META := &"wide_awake_serial"
	var tower: Tower
	var left := 3.0
	var serial := 0

	func _init(target: Tower, speed: float, seconds: float) -> void:
		tower = target
		left = seconds
		serial = int(target.get_meta(SERIAL_META, 0)) + 1
		target.set_meta(SERIAL_META, serial)
		target.reaction_haste = minf(maxf(target.reaction_haste, speed), Reactions.WIDE_AWAKE_SPEED)  # Capped (council rx review 2026-10-17)

	func _ready() -> void:
		if not is_instance_valid(tower):
			return
		var ring := Fx.FxRing.new(Palette.GLOW, 14.0, 26.0, 0.45)
		get_parent().add_child(ring)
		ring.global_position = tower.global_position
		Fx.play(&"storm_front", tower.global_position, get_parent(), 0.6, true, left)  # Stand-in swirl (open item for Fx)

	func _process(delta: float) -> void:
		left -= delta
		if left > 0.0 and is_instance_valid(tower):
			return
		if is_instance_valid(tower) and int(tower.get_meta(SERIAL_META, 0)) == serial:
			tower.reaction_haste = 0.0  # Only the latest wake ends it
		queue_free()


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
			&"sleepwalk", &"changeling":
				start_sleepwalk(enemy, chain, share)  # Sleepwalk (2026-10-17): a shorter walk back (Changeling's echo: the walk, no trade)
			&"night_terror", &"wide_awake":
				terror_root(enemy, applier if is_instance_valid(applier) else echo_tower, chain, share)  # Night Terror (2026-10-17): the fear
			_:
				if strength > 0.0:
					enemy.take_damage(_rx(enemy, strength * share, &"echo"), _line(applier, echo_tower.tower_data.line), true, false,
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
		if ignore_cooldown or not s.skip_reaction_wait:
			return 1 if ignore_cooldown else 0
		s.skip_reaction_wait = false  # Card pass 2026-10-16, Called from Afar: a far hit lets this one skip its wait
		var afar := _dreams(enemy)
		if afar != null and not afar.reaction_cards.wait_skipped(enemy):  # (Old Heart's own skip credits Old Heart)
			afar.role_cards.afar_spent(enemy)
	var data := get_data(key)
	var dreams := _dreams(enemy)
	var cooldown: float = data.cooldown if data else 1.5
	if dreams and dreams.has_rule(&"quick_reactions"):
		cooldown = minf(cooldown, QUICK_COOLDOWN)
	if dreams and WOVEN_RULE.has(id) and dreams.has_rule(WOVEN_RULE[id]):
		cooldown *= WOVEN_COOLDOWN  # A Woven card's cost (dream_design.md 83c40cd7): its Crowned Reaction fires half as often
	s.start_cooldown(key, cooldown)
	_decide_payoff(enemy, id)
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
	if dreams:
		dreams.reaction_cards.reaction_fired(enemy, id, chain, links, all_towers)  # Card pass 2026-10-16 (4 B): counts, scalers, Afterglow
	if dreams and dreams.role_cards.fire_live():
		dreams.role_cards.reaction_fired(enemy, id, key, towers)  # Card pass 2026-10-16: Heavy Heart's copies, Homesick's window
	if floori(float(chain - links) / DAWNBURST_CHAIN) < floori(float(chain) / DAWNBURST_CHAIN):
		_dawnburst(enemy)  # Card pass 2026-10-16: every 10th link (10, 20, 30…), not only the first
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
	var s: EnemyStatuses = enemy.statuses
	if s.is_on_cooldown(&"dawnbreak"):
		return  # Card pass 2026-10-16: each nightmare sets one off at most once every DAWNBREAK_WAIT s
	s.start_cooldown(&"dawnbreak", DAWNBREAK_WAIT)
	var at: Vector2 = enemy.global_position
	dreams.note_card(&"dawnbreak", at)
	var shown := false
	for other in _field(enemy):
		if other.global_position.distance_to(at) <= DAWNBREAK_REACH * CELL:
			if not shown:
				DREAM_BURST.play(&"dawnbreak", at, DAWNBREAK_REACH * CELL, _world(enemy))
				shown = true
			var share := DAWNBREAK_BOSS_SHARE if other.enemy_data.is_boss else DAWNBREAK_SHARE
			other.take_damage(_rx(other, other.max_health * share, &"dawnbreak"), "", true, false, null, &"dawnbreak")


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
		&"sleepwalk":
			start_sleepwalk(enemy, 1, CARRIED_SHARE)  # Sleepwalk (2026-10-17): half the walk back
		&"night_terror":
			terror_root(enemy, applier if is_instance_valid(applier) else seed_tower, 1, CARRIED_SHARE)  # Night Terror (2026-10-17): a shorter fear
		_:
			var strength: float = ECHO_DAMAGE.get(base, 2.0)
			var damage := (applier.get_damage() if is_instance_valid(applier) else seed_tower.get_damage())
			enemy.take_damage(_rx(enemy, strength * damage * CARRIED_SHARE, &"carried_storm"), _line(applier if is_instance_valid(applier) else seed_tower,
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
# The one Reaction damage hook (card pass 2026-10-16, card_pass_td.md 1b): DreamState.get_reaction_damage_multiplier(enemy,
# id, tower) = Quick Reactions' cut x the Reaction cards' part (none yet: x1); the Wardens that took part are the
# nightmare's statuses.chain_towers (set by _fire before the damage). Dawnbreak (% of max health) takes only Quick
# Reactions' cut, never the cards'; a Charged bolt (tag static) never comes here.
static func _rx(near: Node, amount: float, id: StringName = &"", tower: Node = null) -> float:
	var dreams := _dreams(near)
	return amount * _payoff(near, id) * _half_share * (dreams.get_reaction_damage_multiplier(near as Node2D, id, tower) * _build(dreams, id) if dreams != null else 1.0)

# The Reaction cards' part alone (no Quick Reactions' cut): for the bonus parts of hits that land anyway (Pinned's crit,
# Shatter's main hit) and the Ignite / Tempest burn, so those sites stay as they were until a card says otherwise.
# Brimming's x2.2 for Reaction `id` on `near`: what _decide_payoff wrote when it fired there; for a nightmare it only
# reached (Thunderclap's arcs, Shatter's shards), the payoff of the last such Reaction fired. x1 without Brimming.
static var _last_payoff := {}
static func _payoff(near: Node, id: StringName) -> float:
	if EnemyStatuses.cap_multiplier() <= 1:
		return 1.0
	if near != null and is_instance_valid(near) and "statuses" in near and near.statuses.brim_payoff.has(id):
		return near.statuses.brim_payoff[id]
	return float(_last_payoff.get(id, 1.0))

# A Reaction fires on `enemy` (owner 2026-10-16, option A): with Brimming, x2.2 if it carries twice the normal need of
# every status this Reaction needs (full Drowsy: Brimming's doubled cap; asleep counts as met), else x1. Kept on the
# nightmare by id and by its base Reaction (a Crowned one's damage reads either).
static func _decide_payoff(enemy: Node2D, id: StringName) -> void:
	var s: EnemyStatuses = enemy.statuses
	if EnemyStatuses.cap_multiplier() <= 1:
		return
	var doubled := _carries_double(enemy, id)
	var payoff := EnemyStatuses.charged_payoff_multiplier() if doubled else 1.0
	s.brim_payoff[id] = payoff
	_last_payoff[id] = payoff
	var base: StringName = CROWNED_BASE.get(id, id)
	if base != id:
		s.brim_payoff[base] = payoff
		_last_payoff[base] = payoff
	if id == &"avalanche" or id == &"prismstorm":
		s.brim_payoff[&"shatter"] = payoff
		_last_payoff[&"shatter"] = payoff

static func _carries_double(enemy: Node2D, id: StringName) -> bool:
	var s: EnemyStatuses = enemy.statuses
	var full_drowsy := s.has(DROWSY) and s.stacks(DROWSY) >= s.get_max_stacks(DROWSY)  # Brimming's doubled cap
	var held := s.stacks(HELD) >= ROOTED_NEEDED * 2
	var soaked := s.stacks(DAMP) >= SOAKED_NEEDED * 2
	match id:
		&"thunderclap":
			return soaked and s.stacks(STATIC) >= thunderclap_threshold(s) * 2
		&"tempest":
			return soaked and s.stacks(STATIC) >= thunderclap_threshold(s) * 2 and s.stacks(SPORED) >= CROWNED_MIN_SPORES * 2
		&"ignite":
			return s.stacks(SPORED) >= IGNITE_MIN_SPORES * 2 and s.stacks(STATIC) >= IGNITE_MIN_STATIC * 2
		&"mushrooming":
			return s.stacks(SPORED) >= MUSHROOM_MIN_SPORES * 2 and soaked
		&"fairy_circle":
			return s.stacks(SPORED) >= MUSHROOM_MIN_SPORES * 2 and soaked and held
		&"nightbloom":
			return s.stacks(SPORED) >= MUSHROOM_MIN_SPORES * 2 and soaked and full_drowsy
		&"drown":
			return soaked and full_drowsy
		&"still_pool":
			return soaked and full_drowsy and held
		&"pinned":
			return s.stacks(MARKED) >= EXPOSED_NEEDED * 2 and (held or is_asleep(enemy) or full_drowsy)
		&"starfall":
			return s.stacks(MARKED) >= EXPOSED_NEEDED * 2 and s.stacks(STATIC) >= CROWNED_MIN_STATIC * 2
		&"smother":
			return held and s.stacks(SPORED) >= SMOTHER_MIN_SPORES * 2
		&"fever_dream":
			return s.stacks(SPORED) >= SMOTHER_MIN_SPORES * 2 and full_drowsy
		&"shatter", &"avalanche":
			return held and soaked
		&"prismstorm":
			return held and soaked and s.stacks(STATIC) >= CROWNED_MIN_STATIC * 2
		&"lightning_rod":
			return s.stacks(MARKED) >= EXPOSED_NEEDED * 2 and s.stacks(STATIC) >= thunderclap_threshold(s) * 2
		&"sleepwalk":  # (2026-10-17)
			return s.stacks(SPORED) >= IGNITE_MIN_SPORES * 2 and full_drowsy
		&"night_terror":
			return s.stacks(STATIC) >= IGNITE_MIN_STATIC * 2 and full_drowsy
		&"changeling":  # (owner 2026-10-17)
			return s.stacks(SPORED) >= IGNITE_MIN_SPORES * 2 and full_drowsy and s.stacks(MARKED) >= EXPOSED_NEEDED * 2
		&"wide_awake":
			return s.stacks(STATIC) >= IGNITE_MIN_STATIC * 2 and full_drowsy and held
	return false

# The statuses each Reaction (base and Crowned) is made of, for the build multiplier (what the held cards feeding them add).
const REACTION_STATUSES := {&"thunderclap": [DAMP, STATIC], &"tempest": [DAMP, STATIC, SPORED], &"ignite": [SPORED, STATIC],
	&"mushrooming": [SPORED, DAMP], &"fairy_circle": [SPORED, DAMP, HELD], &"nightbloom": [SPORED, DAMP, DROWSY],
	&"drown": [DAMP, DROWSY], &"still_pool": [DAMP, DROWSY, HELD], &"pinned": [MARKED, HELD, DROWSY], &"starfall": [MARKED, HELD, STATIC],
	&"smother": [HELD, SPORED], &"fever_dream": [HELD, SPORED, DROWSY], &"shatter": [HELD, DAMP], &"avalanche": [HELD, DAMP],
	&"prismstorm": [HELD, DAMP, STATIC], &"lightning_rod": [MARKED, STATIC],
	&"sleepwalk": [SPORED, DROWSY], &"night_terror": [STATIC, DROWSY],  # (2026-10-17)
	&"changeling": [SPORED, DROWSY, MARKED], &"wide_awake": [STATIC, DROWSY, HELD]}  # (owner 2026-10-17, council reactions_unique.md)

# Power budget (Balancing Discussion, owner review 2026-10-16): Reaction damage x DreamState.reaction_build_multiplier (the
# product of what the held cards feeding this Reaction's statuses add, capped there). Only the Reactions above (base and
# Crowned); Echo, Carried Storm and Dawnbreak stay x1. Per Reaction per frame.
static var _build_frame := -1
static var _build_cache := {}
static func _build(dreams: DreamState, id: StringName) -> float:
	if not REACTION_STATUSES.has(id) or not dreams.has_method("reaction_build_multiplier"):
		return 1.0
	var frame := Engine.get_process_frames()
	if frame != _build_frame:
		_build_frame = frame
		_build_cache.clear()
	if not _build_cache.has(id):
		_build_cache[id] = dreams.reaction_build_multiplier(id, REACTION_STATUSES[id])
	return _build_cache[id]

# (council rx review 2026-10-17) A spill of a hit that already went through _rx_cards (Pinned's pierce, Starfall's
# stars, Shatter / Prismstorm shards): only Quick Reactions' cut (get_reaction_damage_multiplier's dawnbreak case) and a
# half set-off's share, never the cards, the build multiplier or the Brimming payoff a second time.
static func _rx_spill(near: Node, amount: float) -> float:
	var dreams := _dreams(near)
	return amount * _half_share * (dreams.get_reaction_damage_multiplier(near as Node2D, &"dawnbreak") if dreams != null else 1.0)

static func _rx_cards(near: Node, id: StringName, tower: Node = null) -> float:
	var dreams := _dreams(near)
	return dreams.get_reaction_card_multiplier(near as Node2D, id, tower) * _build(dreams, id) if dreams != null else 1.0

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
