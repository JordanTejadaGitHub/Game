extends RefCounted
class_name EnemyStatuses

# Status effects on one creature (numbers: documentation/dream_design.md, "Status effect numbers").
# Wardens apply statuses; other Wardens and Dreams pay them off by reading them here.
# Strength scales with the applying Warden's soothe (`potency`), so statuses keep up with health.
#
#   damp    −10% speed, 4 s                           (no stacks)
#   drowsy  −8% speed per stack, 3 s, up to 5         (bosses: up to 3)
#   spored  soothe/s per stack = potency, 5 s, up to 8 (Driftspore raises the cap)
#   marked  +25% soothe taken from everything, 5 s    (no stacks)
#   static  charges; at 5 (bosses 8) a free bolt of 3× potency, then reset; −1 stack per 2 s
#   held    can't move (Frostfern's freeze), 1 s                  (no stacks)

const DAMP := &"damp"
const DROWSY := &"drowsy"
const SPORED := &"spored"
const MARKED := &"marked"
const STATIC := &"static"
const HELD := &"held"
const ALL: Array[StringName] = [DAMP, DROWSY, SPORED, MARKED, STATIC, HELD]

const DEFAULT_DURATION := {DAMP: 4.0, DROWSY: 3.0, SPORED: 5.0, MARKED: 5.0, STATIC: 2.0, HELD: 1.0}
const DEFAULT_MAX_STACKS := {DAMP: 1, DROWSY: 5, SPORED: 8, MARKED: 1, STATIC: 5, HELD: 1}
const BOSS_MAX_STACKS := {DROWSY: 3, STATIC: 8}
const COLORS := {  # Marks the Wardens put on nightmares, so they keep the Wardens' colours (one each)
	DAMP: Palette.DEWLIGHT, DROWSY: Palette.BLOSSOM, SPORED: Palette.SPRIG,
	MARKED: Palette.GOLD, STATIC: Palette.GLOW, HELD: Palette.MOONLIGHT,
}
# The White Stag's aura (a Memory Warden): nightmares inside are slower and take more damage.
const STAG_SLOW := 0.15
const STAG_EXTRA := 0.15

const DAMP_WATER_BONUS := 0.20  # Damp (Soaked) conducts: water (Dewdrop-family) hits +20% (Enemy.take_damage)
const WAKE_HIT_SHARE := 0.10  # One hit dealing this share of max health wakes a sleeper (not effect ticks)
const FOG_STATIC_BONUS := 0.25  # Static bolts +25% in fog (Morning Fog: "Static ticks +25% inside")
const CAUGHT_GREAT_TICK_BONUS := 0.25  # Great Dreamcatcher: Caught statuses tick +25%
const DROWSY_SLOW_PER_STACK := 0.08
const MARKED_EXTRA := 0.25
const STATIC_BOLT_MULTIPLIER := 3.0
const STATIC_DECAY_TIME := 2.0  # Seconds per lost Static stack
const SPORE_TICK := 0.5  # Spored soothes in ticks this long
const FOG_SPORE_BONUS := 0.5  # Spored ticks +50% while in fog (Mistveil)

var is_boss := false
var ignores_slows := false  # Drowned One: statuses still apply, they just don't slow it
# From EnemyData: statuses that don't take, and {status id: duration multiplier}.
var immune: Array[StringName] = []
var duration_multipliers := {}
# Every status's duration on this creature (Omens: Stubborn Blight halves them).
var duration_multiplier_all := 1.0
# {id: {"stacks": int, "time": float (seconds left), "potency": float}}
var _active := {}
var _spore_timer := 0.0
var _fog_time := 0.0
var _stag_time := 0.0  # Seconds left inside the White Stag's aura

# Reactions (tower_design.md "Reactions"; rules in Reactions). Per nightmare:
const MUSHROOM_SPORE_BONUS := 0.5  # Mushrooming: Spored ticks +50%
const SMOTHER_SPORE_RATE := 3.0  # Smother: Spored ticks this much faster while Held
var reaction_cooldowns := {}  # Reaction id -> seconds before it can fire here again
# The latest Reaction whose output touched this nightmare, while it can still start a chain.
var chain_count := 0
var chain_time := 0.0
var chain_towers: Array = []  # Wardens that took part in that chain so far
var pinned := false  # Pinned: the next Warden hit is a guaranteed ×3 crit
var drowned := 0  # Times Drown made it sleep (once per nightmare; Deep Water II: twice)
var mushroom_time := 0.0  # Mushrooming: Spored ticks harder while > 0
var burn_time := 0.0  # Ignite (status jobs, 2026-09-29): Spored ticks burn_rate x as fast while > 0 (Reactions.burn)
var burn_rate := 3.0
# Bumped whenever a status comes, goes or changes stacks: the status icons redraw only then.
var changes := 0
var sleep_locked_time := 0.0  # Nightbloom: while > 0, sleep neither breaks on a big hit nor ends (Enemy's wake rule reads it)
var slow_time := 0.0  # Drown on bosses (and Held-immune nightmares): an extra slow instead of sleep
var slow_amount := 0.0
var smothering := false  # Held + Spored right now (Spored ticks faster)

# Sleep (Drown; Great Dreamcatcher lengthens it): can't move while > 0. Not a status (no icon, no
# Reactions of its own), but it counts as asleep for Pinned and Caught.
var sleep_time := 0.0
var sleep_extended := false  # Great Dreamcatcher's +1 s happened already
var dreamshroom_slept := false  # Dreamshroom puts each nightmare to sleep once
var held_bonus := 0.0  # World Root: +damage taken while Held (set when it Holds this nightmare)
# Crowned Reactions (Reactions): the Tempest cap, Storm Front (a Gust just copied statuses here), a
# Prismstorm Shatter about to throw its shards, and Smother having just ended (Fever Dream).
var tempest_time := 0.0
var gust_time := 0.0
var prism_pending := false
var smother_ended := false
var veil_time := 0.0  # Morning Fog's Veil (FinalTwists): while > 0 it can't be healed (Enemy.heal reads it)
var marked_extra := 0.0  # Beacon: its Marked is stronger (+35% instead of +25%) until Marked ends
var marked_bonus := 0.0  # Bright Marks (Dream): added to either (the nightmare sets it each frame)
# Hunter's Moon / Eternal Charge (Legendary rules): Marked / Static on this nightmare never run out.
var marked_forever := false
var static_forever := false
# Caught (Dreamcatcher): asleep or at max Drowsy inside a Dreamcatcher's range; takes more damage.
var caught_time := 0.0
var caught_bonus := 0.0
var caught_shard := false  # Caught by a Great Dreamcatcher: dispelling it drops a Dreamlight shard
var caught_shard_tower: Node = null  # That Great Dreamcatcher (for its shard_dropped signal)
var bad_dreams_timer := 0.0  # Bad Dreams: Drowsy per second while Caught
# Thousand Cuts: hits within 2 s of each other stack +2% damage taken (max +60%).
const CUT_BONUS := 0.02
const CUT_MAX := 30
const CUT_WINDOW := 2.0
var cut_stacks := 0
var cut_time := 0.0
# Heavy Eyelids: extra Drowsy cap (set by the nightmare from the Dream before Drowsy lands).
var drowsy_cap_bonus := 0

func is_asleep() -> bool:
	return sleep_time > 0.0

func is_caught() -> bool:
	return caught_time > 0.0

# Caught by a Great Dreamcatcher (the one that drops shards): its statuses tick +25% (Spored ticks,
# Static bolts). A plain Dreamcatcher only preserves them. `caught_bonus` is no longer read.
func get_caught_tick_bonus() -> float:
	return CAUGHT_GREAT_TICK_BONUS if is_caught() and caught_shard else 0.0

# A single hit this big (share of max health) wakes a sleeper, unless Nightbloom locks the sleep.
func can_wake_from_hit() -> bool:
	return sleep_time > 0.0 and sleep_locked_time <= 0.0

# Asleep or at full Drowsy (bosses: their cap of 3 counts): what Dreamcatchers catch.
func is_catchable() -> bool:
	return is_asleep() or (has(DROWSY) and stacks(DROWSY) >= get_max_stacks(DROWSY))

func add_cut() -> void:
	cut_stacks = mini(cut_stacks + 1, CUT_MAX)
	cut_time = CUT_WINDOW

# Marks this nightmare as touched by a Reaction's output, so a Reaction here within `window` s counts
# as the chain's next link.
func mark_chain(count: int, towers: Array, window: float = 1.0) -> void:
	if count > chain_count or chain_time <= 0.0:
		chain_count = count
		chain_towers = towers
	chain_time = maxf(chain_time, window)

func is_on_cooldown(reaction: StringName) -> bool:
	return reaction_cooldowns.get(reaction, 0.0) > 0.0

func start_cooldown(reaction: StringName, seconds: float) -> void:
	reaction_cooldowns[reaction] = seconds

# Adds `stacks` of `id` (up to `max_stacks`, 0 = default cap) and refreshes its duration.
# `line` is the applying Warden's family; Spored ticks count as that family's soothe. `source` is
# the applying Warden (damage attribution: Spored ticks and Static bolts are credited to it).
# Returns the soothe of a Static bolt if this application set one off, else 0.
func apply(id: StringName, stacks: int = 1, duration: float = 0.0, potency: float = 0.0,
		max_stacks: int = 0, line: String = "", source: Node = null) -> float:
	if id in immune:
		return 0.0
	var cap := get_max_stacks(id, max_stacks)
	var status: Dictionary = _active.get(id, {"stacks": 0, "time": 0.0, "potency": 0.0})
	status.stacks = mini(status.stacks + stacks, cap)
	var length: float = (duration if duration > 0.0 else DEFAULT_DURATION[id]) * duration_multipliers.get(id, 1.0) \
		* duration_multiplier_all
	if length >= status.time:
		status["full"] = length  # A fresh timer: the badge's rim arc drains from full again
	status.time = maxf(status.time, length)
	if potency >= status.potency:
		status["line"] = line  # The strongest applier's family sets the ticks' family
		status["source"] = source  # …and gets the credit for them
	status.potency = maxf(status.potency, potency)
	# Driftspore's higher cap sticks once reached, even if a Sporeling hits next.
	status["cap"] = maxi(status.get("cap", 0), cap)
	_active[id] = status
	changes += 1
	# On a Damp nightmare Thunderclap goes off at 3 Static first (Reactions), so no bolt here then.
	if id == STATIC and status.stacks >= cap and not has(DAMP):
		_active.erase(STATIC)
		changes += 1
		if static_forever and potency > 0.0:
			return potency * STATIC_BOLT_MULTIPLIER * _static_tick_multiplier()  # Eternal Charge: the Warden that added the last charge
		return status.potency * STATIC_BOLT_MULTIPLIER * _static_tick_multiplier()
	return 0.0

func get_max_stacks(id: StringName, override: int = 0) -> int:
	var cap: int = override if override > 0 else DEFAULT_MAX_STACKS[id]
	if is_boss and BOSS_MAX_STACKS.has(id):
		cap = BOSS_MAX_STACKS[id] if id == DROWSY else maxi(cap, BOSS_MAX_STACKS[id])
	if id == DROWSY:
		cap += drowsy_cap_bonus
	return maxi(cap, _active.get(id, {}).get("cap", 0))

func has(id: StringName) -> bool:
	return _active.has(id)

func stacks(id: StringName) -> int:
	return _active[id].stacks if _active.has(id) else 0

# Family of the Warden behind the current Spored ("" if none).
func spore_line() -> String:
	return _active[SPORED].get("line", "") if _active.has(SPORED) else ""

# The Warden credited for `id` (its strongest applier), or null if unknown or gone.
func source(id: StringName) -> Node:
	var who = _active[id].get("source") if _active.has(id) else null
	return who if is_instance_valid(who) else null

func potency(id: StringName) -> float:
	return _active[id].potency if _active.has(id) else 0.0

func time_left(id: StringName) -> float:
	return _active[id].time if _active.has(id) else 0.0

# Share of its timer left, 1 → 0 (the status badge's draining rim arc).
func time_share(id: StringName) -> float:
	if not _active.has(id):
		return 0.0
	var status: Dictionary = _active[id]
	return clampf(status.time / maxf(status.get("full", status.time), 0.001), 0.0, 1.0)

# One status for the nightmare info panel: "Charged 4/5 · 2.1 s" (stacks only when it can stack).
func describe(id: StringName) -> String:
	var cap := get_max_stacks(id)
	var count := " %d/%d" % [stacks(id), cap] if cap > 1 else ""
	return "%s%s · %.1f s" % [IconInfo.status_name(id), count, time_left(id)]

func remove(id: StringName) -> void:
	if _active.erase(id):
		changes += 1

# How many statuses it carries (no array built: Tangled and the redraw check ask every frame).
func count() -> int:
	return _active.size()

func active_ids() -> Array:
	return _active.keys()

# Total stacks of every status (how "afflicted" a nightmare is, for Gust).
func total_stacks() -> int:
	var total := 0
	for id in _active:
		total += _active[id].stacks
	return total

# Every active status as [{id, stacks, time, potency, line, source}] (Gust copies them to other
# nightmares; Inspect shows them).
func snapshot() -> Array:
	var result := []
	for id in _active:
		var status: Dictionary = _active[id]
		result.append({"id": id, "stacks": status.stacks, "time": status.time, "potency": status.potency,
			"line": status.get("line", ""), "source": source(id)})
	return result

# Keeps the creature "in fog" (Mistveil) for `seconds`.
func set_in_fog(seconds: float) -> void:
	_fog_time = maxf(_fog_time, seconds)

func is_in_fog() -> bool:
	return _fog_time > 0.0

# Keeps the creature inside the White Stag's aura for `seconds`.
func set_in_stag_aura(seconds: float) -> void:
	_stag_time = maxf(_stag_time, seconds)

func is_in_stag_aura() -> bool:
	return _stag_time > 0.0

# Held nightmares stand still (they're easy targets for area effects).
func is_held() -> bool:
	return has(HELD)

# Movement speed multiplier from slows.
# `extra_slow` adds slows that aren't statuses (none right now; the Tangled Dream was cut).
func get_speed_multiplier(extra_slow: float = 0.0) -> float:
	if ignores_slows:
		return 1.0
	# Slowing belongs to Drowsy (status jobs, 2026-09-29): Damp conducts instead (Enemy.take_damage).
	var slow := extra_slow
	slow += DROWSY_SLOW_PER_STACK * stacks(DROWSY)
	if is_in_stag_aura():
		slow += STAG_SLOW
	if slow_time > 0.0:
		slow += slow_amount
	return maxf(1.0 - slow, 0.1)

# Soothe taken multiplier (Marked, and the White Stag's aura).
func get_damage_taken_multiplier() -> float:
	var multiplier := 1.0
	if has(MARKED):
		multiplier += maxf(MARKED_EXTRA, marked_extra) + marked_bonus  # Bright Marks on top (Beacon too)
	if is_in_stag_aura():
		multiplier += STAG_EXTRA
	if cut_stacks > 0:
		multiplier *= 1.0 + CUT_BONUS * cut_stacks
	if held_bonus > 0.0 and is_held():
		multiplier *= 1.0 + held_bonus  # World Root: Held nightmares take more from everything
	return multiplier

# Advances timers. Returns the Spored soothe to deal this frame (already fog-boosted).
func tick(delta: float) -> float:
	var was_smothering := smothering
	# Most timers sit at 0 on most nightmares: only count down the running ones (this runs every
	# frame for every nightmare).
	if tempest_time > 0.0:
		tempest_time = maxf(tempest_time - delta, 0.0)
	if gust_time > 0.0:
		gust_time = maxf(gust_time - delta, 0.0)
	if _fog_time > 0.0:
		_fog_time = maxf(_fog_time - delta, 0.0)
	if _stag_time > 0.0:
		_stag_time = maxf(_stag_time - delta, 0.0)
	if chain_time > 0.0:
		chain_time = maxf(chain_time - delta, 0.0)
	if mushroom_time > 0.0:
		mushroom_time = maxf(mushroom_time - delta, 0.0)
	if burn_time > 0.0:
		burn_time = maxf(burn_time - delta, 0.0)
	if sleep_locked_time > 0.0:
		sleep_locked_time = maxf(sleep_locked_time - delta, 0.0)
	if slow_time > 0.0:
		slow_time = maxf(slow_time - delta, 0.0)
	if veil_time > 0.0:
		veil_time = maxf(veil_time - delta, 0.0)
	if sleep_time > 0.0:
		if is_boss:
			sleep_time = 0.0  # Bosses never sleep
		elif sleep_locked_time <= 0.0:
			sleep_time = maxf(sleep_time - delta, 0.0)  # Nightbloom's lock: sleep doesn't end
	if caught_time > 0.0:
		caught_time = maxf(caught_time - delta, 0.0)
	if cut_time > 0.0:
		cut_time = maxf(cut_time - delta, 0.0)
		if cut_time <= 0.0:
			cut_stacks = 0
	for reaction in (reaction_cooldowns.keys() if not reaction_cooldowns.is_empty() else []):
		reaction_cooldowns[reaction] -= delta
		if reaction_cooldowns[reaction] <= 0.0:
			reaction_cooldowns.erase(reaction)
	var spore_damage := 0.0
	if has(SPORED):
		smothering = has(HELD)
		_spore_timer += delta * (SMOTHER_SPORE_RATE if smothering else 1.0) * (burn_rate if burn_time > 0.0 else 1.0)
		while _spore_timer >= SPORE_TICK:
			_spore_timer -= SPORE_TICK
			var per_tick: float = _active[SPORED].stacks * _active[SPORED].potency * SPORE_TICK
			var bonus := (FOG_SPORE_BONUS if is_in_fog() else 0.0) + (MUSHROOM_SPORE_BONUS if mushroom_time > 0.0 else 0.0) \
				+ get_caught_tick_bonus()
			spore_damage += per_tick * (1.0 + bonus)
	else:
		_spore_timer = 0.0
		smothering = false
	smother_ended = was_smothering and not smothering

	# Caught: statuses stop wearing off (Static doesn't bleed, timers pause); Spored still ticks.
	# (Iterates the dictionary itself, no keys() copy: this runs for every nightmare every frame.)
	if not _active.is_empty() and caught_time <= 0.0:
		var expired: Array = []
		for id in _active:
			var status: Dictionary = _active[id]
			status.time -= delta
			if status.time > 0.0:
				continue
			if (id == MARKED and marked_forever) or (id == STATIC and static_forever):
				status.time = 1.0  # Never expires, never bleeds off
				status["full"] = 1.0
				continue
			if id == STATIC and status.stacks > 1:
				status.stacks -= 1  # Static bleeds off one charge at a time
				changes += 1
				status.time = STATIC_DECAY_TIME
				status["full"] = STATIC_DECAY_TIME
			else:
				expired.append(id)
		for id in expired:
			_active.erase(id)
			changes += 1
	if marked_extra != 0.0 and not has(MARKED):
		marked_extra = 0.0
	return spore_damage

# Static bolts in fog (Morning Fog) and on a nightmare Caught by a Great Dreamcatcher hit harder.
func _static_tick_multiplier() -> float:
	return 1.0 + (FOG_STATIC_BONUS if is_in_fog() else 0.0) + get_caught_tick_bonus()
