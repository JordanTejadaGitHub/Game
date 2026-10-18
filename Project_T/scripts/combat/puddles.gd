extends "res://scripts/combat/class_kit.gd"
# The Dewdrop class (dream_council_review.md 20 "Dewdrop: water on the path", rulings in 21).
# Calling, Puddles: the path touching your Dewdrops is water. A Dewdrop's hit there ripples: nightmares within 4
# steps in that water are Soaked. (Dewdrops already hit Soaked nightmares harder: the built Soaked rule.)
# A water is one unbroken run of wet route points; it knows its Dewdrops, its bank (other attacking Wardens touching
# it) and its length in steps. A Dewdrop is lone while no other attacking Warden touches any of its waters.
# Water is the first pick's only (place_on, 2026-10-14); the 5 class cards use it. The 10 lent cards never do: they use
# "near a Dewdrop" (2 cells), "a Dewdrop's range" and Soaked, for any Dewdrop owner.
# Every number is a paper starting value.

const GROUP := &"puddles"
const FAMILY := "dewdrop"
const LINE := "water"

const RIPPLE_STEPS := 4  # The ripple, Swell and Wake Ripple run this many steps each way in the water
const RIPPLE_EVERY := 1.0  # …and Soak each nightmare at most once a second
const LEVEE_WALLS := 2  # Levee: a row of up to this many walls between two Dewdrops
const BACKWASH_DEWDROPS := 4
const BREAKWATER_STEPS := 14.0  # Breakwater: water this long or longer…
const BREAKWATER_SECONDS := 3.0  # …this many seconds of the strongest Dewdrop's damage
const BOTH_BANKS_SHARE := 0.5
const RIPTIDE_SECONDS := 2.0  # Pulled under this long…
const RIPTIDE_SLOW := 0.5  # …walking this much slower…
const RIPTIDE_DAMAGE_SECONDS := 3.0  # …taking this many seconds of that Dewdrop's damage over it
const RIPTIDE_TICK := 0.5
const CAUGHT_WARDENS := 3  # Caught Wading
const WASH_AWAY_SHELL := 2.0  # Wash Away: a Soaked nightmare's shell takes this much damage from Wardens near a Dewdrop
const SWELL_SHARE := 0.5
const ACROSS_STEPS := 3  # Across the Water: this many steps further along the water…
const ACROSS_CELLS := 5.0  # …never more than this far from the Warden
const REMEMBERS_SECONDS := 3.0  # The Water Remembers: a status that had ended comes back this long
const SOMETHING_STATUSES := 2  # Something in the Water: at most this many statuses, 1 stack each, once a second per Dewdrop
const SOAKED_THROUGH_WARDENS := 4

# Card rule ids
const LEVEE := &"levee"
const BACKWASH := &"backwash"
const BREAKWATER := &"breakwater"
const THERE_AND_BACK := &"there_and_back"
const BOTH_BANKS := &"both_banks"
const RIPTIDE := &"riptide"
const CAUGHT_WADING := &"caught_wading"
const WAKE_RIPPLE := &"class_wake_ripple"  # (Retired from offers 2026-10-13: Deep Pool took its slot)
const DEEP_POOL := &"deep_pool"
const DEEP_POOL_PER_STATUS := 0.10  # Deep Pool: hits from Wardens touching water deal this much more per status besides Soaked
const RIP_META := &"pd_rip"  # On a nightmare: {until, done: {Warden id: true}} (Riptide: the bank's first hits land double)
const WASH_AWAY := &"wash_away"
const SWELL := &"swell"
const ACROSS := &"across_the_water"
const REMEMBERS := &"the_water_remembers"
const SOMETHING := &"something_in_the_water"  # Lent
const SOAKED_THROUGH := &"lent_soaked_through"  # Lent
const RUN_OFF := &"run_off"  # Lent

# Lent and class, 2026-10-14 (lent_noplace_dewdrop_bellflower.md, expand_dewdrop_bellflower.md, dream_council_review.md 26)
const SHALLOWS := &"shallows"
const SHALLOWS_EVERY := 1.0  # Shallows: each other Warden touching a Dewdrop adds 1 Soaked with a hit, once a second
const KNEE_DEEP := &"knee_deep"
const KNEE_SLOW := 0.1  # Knee-Deep: a Soaked nightmare in a Dewdrop's range walks this much slower…
const KNEE_SLOW_FULL := 0.2  # …this much when fully Soaked…
const KNEE_TIME := 0.25  # …re-applied each poll, so it ends soon after it leaves or dries
const ACROSS_EXTRA_CELLS := 1.0  # Across the Water: Wardens near a Dewdrop reach Soaked nightmares this far past their range
const RETURN_STEPS := 3  # Walking back into a Dewdrop's range: at least this many route steps past where it left (pulls don't count)
const WATERLOGGED := &"waterlogged"
const WATERLOGGED_FACTOR := 1.5  # Waterlogged: other families' statuses on a Soaked nightmare last this much longer (never Drowsy)
const SOAKED_BONE := &"soaked_to_the_bone"  # Class: walking back into a lone Dewdrop's water fills Soaked at once
const RANGE_META := &"pd_range"  # On a nightmare: {Dewdrop key: [inside: bool, exit route index]}
const SHALLOWS_META := &"pd_shallows_next"  # On a Warden

# Statuses linger (owner 2026-10-15, trait_lent_proposal.js): the lent cards carry Dewdrop's trait to every family.
# Everything that adds time after a landing goes through EnemyStatuses.linger (all together at most LINGER_MAX past the
# last landing; Charged LINGER_MAX_STATIC). Never Rooted or Drowsy (EnemyStatuses.can_linger).
const STEEPED := &"steeped"
const STEEPED_SHARE := 0.4  # Steeped: statuses from Wardens touching a Dewdrop (a Dewdrop touches itself), or landing inside two Dewdrops' ranges, last 40% longer (card pass 2026-10-16: absorbs Pooling and Dripping)
const TOPPED_UP := &"topped_up"
const TOPPED_UP_EVERY := 1.0  # Topped Up: a Dewdrop's hit resets every status's time, once a second per nightmare
const TOPPED_META := &"pd_topped_next"  # On a nightmare
const DRIPPING := &"dripping"
const DRIPPING_SECONDS := 2.0  # Dripping: leaving a Dewdrop's range, every status keeps this much longer
const EBB := &"ebb"
const EBB_SECONDS := 3.0  # Ebb: a status running out in a Dewdrop's range comes back at half its most stacks for this long
const EBB_META := &"pd_ebb"  # On a nightmare: true once its ran-out signal is hooked
const POOLING := &"pooling"
const POOLING_SHARE := 0.5  # Pooling: in two Dewdrops' ranges at once, statuses landing last 50% longer
const HIGH_TIDE := &"high_tide"
const HIGH_TIDE_SHARE := 0.75  # (Unused since keyword chips 2026-10-16: every status counts now)
const HIGH_TIDE_PER := 0.10  # High Tide: each status on the nightmare adds 10% to hits from Wardens near a Dewdrop…
const HIGH_TIDE_MAX := 0.30  # …up to +30% (keyword chips 2026-10-16, TD: was +40% with only fresh statuses)
const OLD_RAIN := &"old_rain"
const OLD_RAIN_AGE := 4.0  # (Unused since keyword chips 2026-10-16: Old Rain reads EnemyStatuses.is_lingering, not age)
const OLD_RAIN_BONUS := 1.4  # …deals 40% more (its burst; damage over time after it is unchanged)
const NEVER_DRY := &"never_quite_dry"
const NEVER_DRY_EVERY := 3.0  # Never Quite Dry: a Reaction near a Dewdrop leaves the statuses it spent at half, once per nightmare in 3 s
const NEVER_DRY_META := &"pd_never_dry_next"  # On a nightmare
var _old_rain := false  # True while a boosted Reaction check runs (damage_multiplier reads it)
var _rain_ids: Array = []  # Old Rain: the lingering statuses on the nightmare that check runs for (keyword chips 2026-10-16)

# Old Rain (keyword chips 2026-10-16): the statuses on `statuses` that a card is making last longer.
func _lingering_ids(statuses: EnemyStatuses) -> Array:
	var out: Array = []
	for id in statuses.active_ids():
		if statuses.is_lingering(id):
			out.append(id)
	return out

# Whether Reaction burst `tag` spends one of `ids` (its base Reaction's statuses; a tag without data: any of them).
func _rain_spends(tag: StringName, ids: Array) -> bool:
	if ids.is_empty():
		return false
	var data: ReactionData = Reactions.get_data(Reactions.CROWNED_BASE.get(tag, tag))
	if data == null:
		return true
	for id in ids:
		if data.statuses.has(id) or data.alternatives.has(id):
			return true
	return false
const WATER_META := &"pd_water"  # On a nightmare: the water it stands in (-1 none)
const SEEN_META := &"pd_seen"  # On a nightmare: {Dewdrop cell key: true}: it has walked this Dewdrop's water
const LEFT_META := &"pd_left"  # On a nightmare: {Dewdrop id: {status: [stacks, potency, line, WeakRef]}} (The Water Remembers)
const ONCE_META := &"pd_once"  # On a nightmare: {"card:key": true}
const RIPPLE_META := &"pd_ripple"  # On a nightmare: when the ripple may Soak it again
const CARRY_META := &"pd_carry"  # On a nightmare: when a carried stack may reach it again (Wake Ripple)
const SOMETHING_META := &"pd_something"  # On a Dewdrop: when it may add again

var waters: Array = []  # [{id, first, last, points: {index: true}, dewdrops: Array, bank: Array, steps: float}]
var _water_at := {}  # Route index -> index into `waters`
var _lone := {}  # Dewdrop instance id -> true
var _waters_of := {}  # Warden instance id -> Array of indices into `waters` (Dewdrops and bank Wardens)
var _across := {}  # Warden instance id -> {route index: true}: where it reaches along the water (unused since 2026-10-14)
var _near_dew := {}  # Warden instance id -> the strongest Dewdrop near it, or null (cleared with the board)
var _riptides: Array = []  # [{enemy: WeakRef, tower: WeakRef, amount, ticks, wait}]
var ripples := 0  # This run (tests and the owner's eye)

# --- Calling evolutions (scripts/combat/calling_paths.gd; council calling_evolution_*.md, owner 2026-10-16) -----------
# Read with evo(id) (implies the Calling). Every number is a paper starting value (Balancing). Each one shows itself (a
# flash along the water, a thread, a splash, the drawn current / pond / footprints) and credits its id (credit()).
# Pulls never move bosses or flyers; Holds are halved on bosses; flyers are never in water (index_of is -1 for them).
const EVO_STREAM := &"dw_stream"  # Spread
const FLOW_STEPS := 4  # Stream: water flows this many steps past each water's downstream end (joining a water it reaches)
const EVO_MILLRACE := &"dw_millrace"
const MILL_STATUSES := 3  # Millrace: a ripple carries up to this many of the hit nightmare's other statuses…
const MILL_STACKS := 1  # …this many stacks each, to every nightmare it soaks (never Soaked, Drowsy or Held)
const EVO_FLOOD := &"dw_flood"
const FLOOD_STEPS := 24  # Flood: a ripple runs its whole water, at most this many steps each way
const EVO_LAPPING := &"dw_lapping_water"
const LAP_STEPS := 2  # Lapping Water: a bank Warden's hit on a Soaked nightmare in its water ripples this many steps…
const LAP_EVERY := 1.0  # …once a second per Warden
const LAP_META := &"pd_lap_next"  # On a Warden
const EVO_SPRING := &"dw_spring_flood"
const SPRING_EVERY := 10.0  # Spring Flood: drift time between floods (paused at rests)…
const SPRING_MAX := 8  # …up to this many nightmares in the longest water with one in it…
const SPRING_SLOW := 0.25  # …fully Soaked and this much slower (bosses half)…
const SPRING_SECONDS := 2.0  # …for this long
const EVO_POND := &"dw_black_pond"  # Focus
const POND_DEWDROPS := 2  # Black Pond: water touching this many Dewdrops is a pond…
const POND_SLOW := 0.25  # …nightmares in it walk this much slower (bosses half)…
const POND_STEPS := 8  # …and its ripple runs this many steps
const POND_TIME := 0.25  # The pond's slow, re-applied each poll (it ends soon after it walks out)
const EVO_WHIRLPOOL := &"dw_whirlpool"
const PULL_STEPS := 2  # Whirlpool: a fully Soaked nightmare in a pond is pulled back this many steps, once per pond (never bosses or flyers)
const EVO_DEEP := &"dw_drowning_deep"
const DEEP_CELLS := 1.0  # Drowning Deep: a Whirlpool pull drags the nightmares within this many cells…
const DEEP_MAX := 4  # …up to this many (never bosses or flyers); Wardens touching the pond each hit the pulled one once, free
const EVO_STAGNANT := &"dw_stagnant_water"
# Stagnant Water (owner 2026-10-17: Dewdrop's own trait, Duration): statuses on a nightmare in a pond don't run down
# while it stays there. Each poll gives back the time a status lost since the last one, through EnemyStatuses.linger
# (so the shared LINGER_MAX cap past the last landing, Charged LINGER_MAX_STATIC; never above the time it had: never
# longer than its own duration; never Rooted or Drowsy). Bosses get back only this share: they run down at half speed.
const STILL_BOSS_SHARE := 0.5
const STILL_META := &"pd_still"  # On a nightmare in a pond: {status: time left at the last poll}
const STILL_FX_EVERY := 1.0  # The held cue (a ripple on the nightmare): once a second per nightmare
const STILL_FX_META := &"pd_still_fx"  # On a nightmare
const EVO_HANDS := &"dw_drowned_hands"
const HANDS_STATUSES := 4  # Drowned Hands: a nightmare carrying this many statuses in a pond…
const HANDS_HOLD := 1.0  # …is Held this long by the pond's strongest Dewdrop (bosses half), once per pond
const EVO_RIVERSIDE := &"dw_riverside"  # Support
const SIDE_SECONDS := 2.0  # Riverside (owner 2026-10-17: Duration, was +1 stack): a status a Warden touching water adds to a nightmare in that water lasts this much longer (EnemyStatuses.linger: the shared cap; never Rooted or Drowsy)
const SIDE_FX_EVERY := 0.5  # Its cue (a thread and a puff): once in this long per nightmare
const SIDE_FX_META := &"pd_side_fx"  # On a nightmare
const EVO_RAIN := &"dw_rain_on_the_bank"
const RAIN_WARDENS := 3  # Rain on the Bank: a ripple gives every nightmare it soaks the status of up to this many bank Wardens…
const RAIN_STACKS := 1  # …this many stacks each (never Drowsy or Held)
const EVO_DOWNPOUR := &"dw_downpour"
const BURST_SOAKED := 4  # Downpour: a ripple that soaks this many nightmares…
const BURST_EVERY := 4.0  # …makes every bank Warden attack one of them at once, each Warden once in this long
const BURST_META := &"pd_burst_next"  # On a Warden
const EVO_WET := &"dw_wet_footprints"
const WET_SECONDS := 3.0  # Wet Footprints: a Soaked nightmare leaving water leaves wet steps that count as water this long…
const WET_STEPS := 6  # …at most this many steps per nightmare (only real water leaves footprints: wet steps never do)
const FOOT_META := &"pd_foot"  # On a nightmare: [water, route points left, last index wetted]
const REAL_META := &"pd_real"  # On a nightmare: the real water it stood in last poll (-1 none)
const EVO_REFLECTION := &"dw_reflection"
const MIRROR_SHARE := 0.5  # Reflection: a bank Warden's hit on a Soaked nightmare in water lands this share (before defences) on the last one in it…
const MIRROR_EVERY := 1.0  # …once a second per Warden
const MIRROR_META := &"pd_mirror_next"  # On a Warden
const MIRROR_TAG := &"both_banks"  # A class tag (class_kit.CLASS_TAGS): the mirrored hit never sets a card off again
var _flowed := {}  # Route index -> true: water a Stream carried on (drawn as a current)
var _wet := {}  # Route index -> [until, water index]: Wet Footprints
var _wet_touch := {}  # Route index -> Array of attacking Wardens touching that wet step (they are on its water's bank)
var _spring_in := SPRING_EVERY

func _family() -> String:
	return FAMILY

func _line() -> String:
	return LINE

# Lent cards never give the Calling's setup (owner 2026-10-14, dream_council_review.md 25-26): water, lone water and the
# ripple are the first pick's only (place_on). The lent cards work from Dewdrops, where Wardens stand ("near a Dewdrop":
# 2 cells; "a Dewdrop's range": its attack range) and Soaked.
func _lent_rules() -> Array:
	return [STEEPED, TOPPED_UP, DRIPPING, EBB, REMEMBERS, POOLING, WATERLOGGED, HIGH_TIDE, OLD_RAIN, NEVER_DRY,
		CAUGHT_WADING, SHALLOWS, KNEE_DEEP, ACROSS, DEEP_POOL, RUN_OFF, WASH_AWAY, RIPTIDE,
		SOMETHING, SOAKED_THROUGH]  # (From Caught Wading on: retired 2026-10-15 or before, need no water; old saves keep them)

# Wake Ripple (retired) carried statuses along the water: an old save holding it keeps the water on Continue.
func _legacy_rules() -> Array:
	return [WAKE_RIPPLE]

func _ready() -> void:
	super._ready()
	add_to_group(GROUP)

# --- The water map ----------------------------------------------------------------------------------------------------

func on_board() -> void:
	waters.clear()
	_water_at.clear()
	_lone.clear()
	_waters_of.clear()
	_across.clear()
	_near_dew.clear()
	_flowed.clear()
	_wet.clear()
	_wet_touch.clear()
	if not place_on():  # Water is the Calling's (the first pick, or an old save's Wake Ripple)
		queue_redraw()
		return
	var dewdrops := own_towers()
	var touch := {}  # Warden id -> Array of route indices it touches
	var wet := {}
	for tower in dewdrops:
		touch[tower.get_instance_id()] = points_touching(tower)
		for i in touch[tower.get_instance_id()]:
			wet[i] = true
	if rule(LEVEE):
		for i in _levee_points(dewdrops):
			wet[i] = true
	if evo(EVO_STREAM):
		_flow(wet)
	var indices: Array = wet.keys()
	indices.sort()
	var run: Array = []
	for i in indices:
		if not run.is_empty() and int(i) - int(run[-1]) > 1:
			_add_water(run)
			run = []
		run.append(i)
	if not run.is_empty():
		_add_water(run)
	var all := towers()
	for w in waters.size():
		var water: Dictionary = waters[w]
		for tower in all:
			if not tower.tower_data.can_attack:
				continue
			var touches := false
			for i in water.points:
				if touches_point(tower, _route_px[int(i)]):
					touches = true
					break
			if not touches:
				continue
			(water.dewdrops if is_own(tower) else water.bank).append(tower)
			var mine: Array = _waters_of.get(tower.get_instance_id(), [])
			mine.append(w)
			_waters_of[tower.get_instance_id()] = mine
	# Lone: only walls touch its water (every water it touches has it alone and an empty bank)
	for tower in dewdrops:
		var lone := true
		for w in _waters_of.get(tower.get_instance_id(), []):
			if waters[int(w)].dewdrops.size() != 1 or not waters[int(w)].bank.is_empty():
				lone = false
		if lone and not _waters_of.get(tower.get_instance_id(), []).is_empty():
			_lone[tower.get_instance_id()] = true
	queue_redraw()

func _add_water(run: Array) -> void:
	var points := {}
	for i in run:
		points[i] = true
		_water_at[i] = waters.size()
	waters.append({"id": int(run[0]), "first": int(run[0]), "last": int(run[-1]), "points": points, "dewdrops": [], "bank": [],
		"steps": run.size() / 2.0})

# Stream: each water flows on FLOW_STEPS steps toward the Heartwood, stopping where it meets another water (they join).
func _flow(wet: Dictionary) -> void:
	var ends: Array = []
	for i in wet:
		if not wet.has(int(i) + 1):
			ends.append(int(i))
	for e in ends:
		for k in range(1, FLOW_STEPS * 2 + 1):
			var j: int = int(e) + k
			if j >= _route_px.size() or wet.has(j):
				break
			wet[j] = true
			_flowed[j] = true

# Levee: a row of up to 2 walls, each touching the next, with a Dewdrop touching each end, carries their water along
# the path beside it. Sprouts are not walls.
func _levee_points(dewdrops: Array) -> Array:
	var walls: Array = towers().filter(is_wall)
	var found := {}
	for first in walls:
		var ends: Array = dewdrops.filter(func(d) -> bool: return touching(d, first))
		if ends.is_empty():
			continue
		if ends.size() >= 2:
			for i in points_touching(first):
				found[i] = true
			continue
		if LEVEE_WALLS < 2:
			continue
		for second in walls:
			if second == first or not touching(first, second):
				continue
			if dewdrops.any(func(d) -> bool: return d != ends[0] and touching(d, second)):
				for i in points_touching(first) + points_touching(second):
					found[i] = true
	return found.keys()

# A Dewdrop's key for "once for each nightmare and Dewdrop" records: its cell, so selling and replanting it on the
# same spot does not pay again (council, lent_td.md).
func _key(tower) -> String:
	return "%d,%d" % [roundi(tower.cell.x * 2.0), roundi(tower.cell.y * 2.0)]

# The strongest hit among a water's Dewdrops (Caught Wading's cap).
func _dewdrop_hit(dewdrops: Array) -> float:
	var best := 0.0
	for tower in dewdrops:
		if is_instance_valid(tower):
			best = maxf(best, tower.get_damage())
	return best

# A water's stable key: the smallest cell key among its Dewdrops.
func _water_key(water: Dictionary) -> String:
	var keys: Array = []
	for tower in water.dewdrops:
		if is_instance_valid(tower):
			keys.append(_key(tower))
	keys.sort()
	return keys[0] if not keys.is_empty() else str(water.id)

func water_of(enemy) -> int:
	var i := index_of(enemy)
	return _water_at_i(i) if i >= 0 else -1

# The water at route index `i` (-1 none): real water, or a wet step (Wet Footprints) that has not dried.
func _water_at_i(i: int) -> int:
	var w := int(_water_at.get(i, -1))
	if w >= 0 or _wet.is_empty() or not _wet.has(i):
		return w
	var row: Array = _wet[i]
	return int(row[1]) if float(row[0]) > now() and int(row[1]) < waters.size() else -1

func is_lone(tower) -> bool:
	return _lone.has(tower.get_instance_id())

func touches_water(tower, w: int) -> bool:
	if w < 0:
		return false
	if _waters_of.get(tower.get_instance_id(), []).has(w):
		return true
	for i in _wet:  # Wet Footprints: a Warden touching a wet step is on that water's bank while it lasts
		var row: Array = _wet[i]
		if int(row[1]) == w and float(row[0]) > now() and (_wet_touch.get(i, []) as Array).has(tower):
			return true
	return false

# A water's bank: the attacking Wardens of other families (Sprouts too) touching it, wet steps included.
func _bank_of(w: int) -> Array:
	if w < 0 or w >= waters.size():
		return []
	var out: Array = (waters[w].bank as Array).filter(_tower_ok)
	for i in _wet:
		var row: Array = _wet[i]
		if int(row[1]) != w or float(row[0]) <= now():
			continue
		for tower in _wet_touch.get(i, []):
			if _tower_ok(tower) and not is_own(tower) and not out.has(tower):
				out.append(tower)
	return out

# The strongest (damage a second) valid Warden in `list`, or null.
func _strongest(list: Array):
	var best = null
	for tower in list:
		if _tower_ok(tower) and (best == null or second_of(tower) > second_of(best)):
			best = tower
	return best

func _is_pond(w: int) -> bool:
	return w >= 0 and w < waters.size() and (waters[w].dewdrops as Array).filter(_tower_ok).size() >= POND_DEWDROPS

# The living nightmares in water `w` within `steps` of route index `from` (not `skip`), nearest first.
func _in_water(w: int, from: int, steps: int, skip = null) -> Array:
	var found: Array = []
	for enemy in enemies():
		if enemy == skip:
			continue
		var i := index_of(enemy)
		if i >= 0 and _water_at_i(i) == w and absi(i - from) <= steps * 2:
			found.append(enemy)
	found.sort_custom(func(a, b) -> bool: return absi(index_of(a) - from) < absi(index_of(b) - from))
	return found

func _once(enemy, key: String) -> bool:
	var done: Dictionary = enemy.get_meta(ONCE_META, {})
	if done.has(key):
		return false
	done[key] = true
	enemy.set_meta(ONCE_META, done)
	return true

func _soaked(enemy) -> bool:
	return enemy.statuses.has(EnemyStatuses.DAMP)

func _fully_soaked(enemy) -> bool:
	return _soaked(enemy) and enemy.statuses.stacks(EnemyStatuses.DAMP) >= enemy.statuses.get_max_stacks(EnemyStatuses.DAMP)

# --- Damage events ----------------------------------------------------------------------------------------------------

# The strongest Dewdrop near `tower` (2 cells on both axes; a Dewdrop is near itself), or null. Cached per board.
func dewdrop_near(tower):
	var id: int = tower.get_instance_id()
	if _near_dew.has(id) and (_near_dew[id] == null or is_instance_valid(_near_dew[id])):
		return _near_dew[id]
	var found = strongest_near(tower.global_position, is_own)
	_near_dew[id] = found
	return found

func on_damage(event, source, enemy, is_hit: bool, dispel: bool, tagged: bool) -> void:
	if dispel and rule(RUN_OFF):
		_run_off(enemy)
	if tagged or source == null or not is_hit:
		return
	if rule(SOMETHING) and is_own(source) and living(enemy):
		_something(source, enemy)
	if rule(SHALLOWS) and is_other(source) and living(enemy):
		_shallows(source, enemy)
	if rule(TOPPED_UP) and is_own(source) and living(enemy) and now() >= float(enemy.get_meta(TOPPED_META, -INF)):
		# Topped Up: a Dewdrop's hit puts every status back to its time at landing (never longer). Once a second per nightmare
		enemy.set_meta(TOPPED_META, now() + TOPPED_UP_EVERY)
		for id in enemy.statuses.active_ids():
			var left_before := SETUP.time_left(enemy, id)  # (setup credit 2026-10-16: the seconds given back, as Linger)
			enemy.statuses.top_up(id)
			SETUP.note_linger(enemy, card_id(TOPPED_UP), id, SETUP.time_left(enemy, id) - left_before)
	if not place_on():
		return
	if not is_own(source):
		if class_on() and not dream_state.calling_path.is_empty() and living(enemy):
			var bank_w := water_of(enemy)
			if bank_w >= 0:
				_bank_hit(event, source, enemy, bank_w)  # Lapping Water, Reflection
		return
	var w := water_of(enemy)
	if w < 0 or not touches_water(source, w):
		return
	var from := index_of(enemy)
	# The Calling's ripple (the first pick only): nightmares within 4 steps in that water are Soaked (Black Pond: 8;
	# Flood: the whole water)
	if class_on():
		ripples += 1
	var soaked: Array = []
	for other in (_in_water(w, from, _ripple_steps(w), enemy) if class_on() else []):
		if now() >= float(other.get_meta(RIPPLE_META, -INF)):
			other.set_meta(RIPPLE_META, now() + RIPPLE_EVERY)
			source._apply_one_status(other, EnemyStatuses.DAMP, 1, source.get_damage(), false)
			soaked.append(other)
	if class_on() and not dream_state.calling_path.is_empty():
		_ripple_shown(enemy, w, from, soaked)
		_ripple_extras(enemy, w, soaked)
	# Swell: the splash spreads through that water, up to 4 steps each way, at half outside its own circle
	if rule(SWELL):
		var circle: float = source.get_splash_cells() * cell()
		for other in _in_water(w, from, RIPPLE_STEPS, enemy):
			if other.global_position.distance_to(enemy.global_position) > circle:
				strike(source, other, event.base * SWELL_SHARE, &"swell", true)
	# Both Banks: a lone Dewdrop with water on two sides: each splash also lands on the front nightmare in its other
	# water, at half, with its Soaked
	if rule(BOTH_BANKS) and is_lone(source):
		for other_w in _waters_of.get(source.get_instance_id(), []):
			if int(other_w) == w:
				continue
			var front = _front_in(int(other_w))
			if front != null:
				_line_fx(source.global_position, front.global_position, 2.0, Palette.DEWLIGHT)
				strike(source, front, event.base * BOTH_BANKS_SHARE, &"both_banks")
				if living(front):
					source._apply_one_status(front, EnemyStatuses.DAMP, maxi(int(source.attack_data.status_stacks), 1), source.get_damage(), false)

# Shallows: a hit from another Warden touching a Dewdrop that Soaks adds 1 Soaked, the Dewdrop's own application (not
# native: it never counts as a Dewdrop Soaking it). Each Warden, once a second; the main target only.
func _shallows(source, enemy) -> void:
	if now() < float(source.get_meta(SHALLOWS_META, -INF)):
		return
	var dewdrop = null
	for tower in own_towers():
		if status_of(tower) == EnemyStatuses.DAMP and touching(tower, source) and (dewdrop == null or second_of(tower) > second_of(dewdrop)):
			dewdrop = tower
	if dewdrop == null:
		return
	source.set_meta(SHALLOWS_META, now() + SHALLOWS_EVERY)
	dewdrop._apply_one_status(enemy, EnemyStatuses.DAMP, 1, dewdrop.get_damage(), false)

func _front_in(w: int):
	var front = null
	var best := -1
	for enemy in enemies():
		var i := index_of(enemy)
		if i > best and _water_at_i(i) == w:
			best = i
			front = enemy
	return front

# The last nightmare in water `w` (furthest from the Heartwood), not `skip`, or null (Reflection).
func _back_in(w: int, skip):
	var back = null
	var best := 1 << 30
	for enemy in enemies():
		if enemy == skip:
			continue
		var i := index_of(enemy)
		if i >= 0 and i < best and _water_at_i(i) == w:
			best = i
			back = enemy
	return back

# --- The poll: who walks in, who walks out ------------------------------------------------------------------------------

func on_poll() -> void:
	if rule(SOAKED_THROUGH):
		for enemy in enemies():
			_soaked_through(enemy)
	if rule(EBB):
		for enemy in enemies():
			if not enemy.has_meta(EBB_META):
				enemy.set_meta(EBB_META, true)
				enemy.statuses.status_ran_out.connect(_ebb.bind(enemy))
	if rule(WATERLOGGED):
		for enemy in enemies():
			_slow_to_dry(enemy)
	var ranges := rule(REMEMBERS) or rule(RIPTIDE) or rule(DRIPPING)
	var knee := rule(KNEE_DEEP)
	if ranges or knee:
		var dewdrops := own_towers()
		for enemy in enemies():
			if enemy.is_flying():
				continue  # Flyers never walk back in, and Knee-Deep never slows them
			if ranges:
				_track_ranges(enemy, dewdrops)
			if knee and _soaked(enemy):
				for tower in dewdrops:
					if tower.global_position.distance_to(enemy.global_position) <= tower.get_range_pixels():
						HelperCommons.slow(enemy, KNEE_SLOW_FULL if _fully_soaked(enemy) else KNEE_SLOW, KNEE_TIME)
						control_slow(KNEE_DEEP, KNEE_SLOW_FULL if _fully_soaked(enemy) else KNEE_SLOW, POLL)  # (setup credit 2026-10-16: the poll's time)
						break
	_tick_riptides()
	if not place_on():
		return
	# The water (the first pick only): walking in and out (Breakwater, Soaked to the Bone, Both Banks' lanes)
	for enemy in enemies():
		if enemy.is_flying():
			continue
		var w := water_of(enemy)
		var was := int(enemy.get_meta(WATER_META, -1))
		var was_water: Dictionary = waters[was] if was >= 0 and was < waters.size() else {}
		if w != was:
			enemy.set_meta(WATER_META, w)
			if not was_water.is_empty():
				_left(enemy, was_water)
			if w >= 0:
				_entered(enemy, waters[w])
	_evolutions_poll()

func on_rest() -> void:
	if not _wet.is_empty():  # Nothing waits through a rest: footprints dry at once
		_wet.clear()
		_wet_touch.clear()
		queue_redraw()

# Each Dewdrop's range, per walking nightmare: leaving it records where; coming back in at least 3 route steps further
# along is "walking back in" (a pull back into the same range never counts). The Water Remembers and Riptide.
func _track_ranges(enemy, dewdrops: Array) -> void:
	var i := index_of(enemy)
	if i < 0:
		return
	var seen: Dictionary = enemy.get_meta(RANGE_META, {})
	for tower in dewdrops:
		var key := _key(tower)
		var inside: bool = tower.global_position.distance_to(enemy.global_position) <= tower.get_range_pixels()
		var row: Array = seen.get(key, [false, -1])
		if inside == bool(row[0]):
			continue
		if not inside:
			seen[key] = [false, i]  # It left: where, and what it carried
			var left: Dictionary = enemy.get_meta(LEFT_META, {})
			left[key] = _other_statuses(enemy)
			enemy.set_meta(LEFT_META, left)
			if rule(DRIPPING) and bool(row[0]) and living(enemy):
				_drip(enemy)
			continue
		seen[key] = [true, int(row[1])]
		if int(row[1]) >= 0 and i - int(row[1]) >= RETURN_STEPS * 2 and living(enemy):
			_walked_back(enemy, tower, key)
	enemy.set_meta(RANGE_META, seen)

func _walked_back(enemy, tower, key: String) -> void:
	if rule(REMEMBERS) and _once(enemy, "remembers:" + key):
		_remember(enemy, key)
	if rule(RIPTIDE) and _soaked(enemy) and _once(enemy, "riptide:" + key):
		# Riptide: it wades at half speed for 2 s (a slow, never Rooted), and each Warden near that Dewdrop lands its first
		# hit on it double in those 2 s
		HelperCommons.slow(enemy, RIPTIDE_SLOW, RIPTIDE_SECONDS)
		control_slow(RIPTIDE, RIPTIDE_SLOW, RIPTIDE_SECONDS)  # (setup credit 2026-10-16)
		enemy.set_meta(RIP_META, {"until": now() + RIPTIDE_SECONDS, "at": tower.global_position, "done": {}})

func _left(enemy, water: Dictionary) -> void:
	var seen: Dictionary = enemy.get_meta(SEEN_META, {})
	var left: Dictionary = enemy.get_meta(LEFT_META, {})
	var snapshot := _other_statuses(enemy)
	for tower in water.dewdrops:
		if is_instance_valid(tower):
			seen[_key(tower)] = true
			left[_key(tower)] = snapshot
	enemy.set_meta(SEEN_META, seen)
	enemy.set_meta(LEFT_META, left)
	if not living(enemy):
		return
	# Backwash: a Soaked nightmare leaving water is hit once, free, by each Dewdrop touching that water (up to 4)
	if rule(BACKWASH) and _soaked(enemy):
		var fired := 0
		for tower in water.dewdrops:
			if fired >= BACKWASH_DEWDROPS:
				break
			if is_instance_valid(tower) and free_hit(tower, enemy, 1.0, FREE_HIT_TAG, INF, BACKWASH):  # (own: setup credit 2026-10-16)
				fired += 1
	# Breakwater: a fully Soaked nightmare leaving water 14 or more steps long takes a wave
	if rule(BREAKWATER) and float(water.steps) >= BREAKWATER_STEPS and _fully_soaked(enemy) and living(enemy) \
			and _once(enemy, "breakwater:%d" % int(water.id)):
		var best = null
		for tower in water.dewdrops:
			if is_instance_valid(tower) and (best == null or second_of(tower) > second_of(best)):
				best = tower
		if best != null:
			Reactions._effect(&"landing_dust", enemy.global_position, self, 1.5)
			strike(best, enemy, second_of(best) * BREAKWATER_SECONDS, &"breakwater")

func _entered(enemy, water: Dictionary) -> void:
	var seen: Dictionary = enemy.get_meta(SEEN_META, {})
	for tower in water.dewdrops:
		if not is_instance_valid(tower) or not seen.has(_key(tower)) or not living(enemy):
			continue
		# It walks back into this Dewdrop's water (The Water Remembers and Riptide read the Dewdrop's range now: _walked_back)
		if not is_lone(tower):
			continue
		if rule(SOAKED_BONE) and _once(enemy, "bone:" + _key(tower)):
			# Soaked to the Bone (class): fully Soaked at once, the Dewdrop's own application up to the limit
			var room: int = enemy.statuses.get_max_stacks(EnemyStatuses.DAMP) - enemy.statuses.stacks(EnemyStatuses.DAMP)  # (The application's own cap clamps it)
			if room > 0:
				Reactions._effect(&"landing_dust", enemy.global_position, self, 0.8)
				setup_apply(SOAKED_BONE, tower, enemy, EnemyStatuses.DAMP, room, tower.get_damage())  # (setup credit 2026-10-16)
		if rule(THERE_AND_BACK):
			free_hit(tower, enemy, 1.0, FREE_HIT_TAG, INF, THERE_AND_BACK)  # There and Back: hit once, free, by that lone Dewdrop

func _tick_riptides() -> void:
	for i in range(_riptides.size() - 1, -1, -1):
		var rip: Dictionary = _riptides[i]
		var enemy = rip.enemy.get_ref()
		var tower = rip.tower.get_ref()
		if not living(enemy) or int(rip.ticks) <= 0:
			_riptides.remove_at(i)
			continue
		rip.wait = float(rip.wait) - POLL
		if float(rip.wait) <= 0.0:
			rip.wait = RIPTIDE_TICK
			rip.ticks = int(rip.ticks) - 1
			strike(tower, enemy, float(rip.amount), &"riptide")

# --- Calling evolutions -------------------------------------------------------------------------------------------------

# How many steps each way a Dewdrop's ripple runs in water `w` (Black Pond, Flood).
func _ripple_steps(w: int) -> int:
	var steps := RIPPLE_STEPS
	if evo(EVO_POND) and _is_pond(w):
		steps = maxi(steps, POND_STEPS)
	if evo(EVO_FLOOD) and w >= 0 and w < waters.size():
		steps = maxi(steps, mini(ceili(float(waters[w].steps)), FLOOD_STEPS))
	return steps

# A flash along water `w` from route index `a` to `b` (Flood, Black Pond, Spring Flood): the ripple running.
func _water_fx(w: int, a: int, b: int, width: float = 1.0) -> void:
	var points := PackedVector2Array()
	for i in range(maxi(a, 0), mini(b, _route_px.size() - 1) + 1):
		if _water_at_i(i) == w:
			points.append(_route_px[i])
	var world := Reactions._world(self)
	if world != null and points.size() >= 2:
		world.add_child(ChainBolt.new(points, Palette.DEWLIGHT, width))

# What a ripple shows and credits once it soaked `soaked` (a long ripple flashes along the water).
func _ripple_shown(enemy, w: int, from: int, soaked: Array) -> void:
	if soaked.is_empty():
		return
	var far := 0
	var flowed := false
	for other in soaked:
		var i := index_of(other)
		if i < 0:
			continue
		far = maxi(far, absi(i - from))
		if _flowed.has(i):
			flowed = true
	if flowed and evo(EVO_STREAM):
		credit(EVO_STREAM, enemy.global_position)  # It reached a nightmare on water the Stream carried (drawn as a current)
	if far > RIPPLE_STEPS * 2:
		_water_fx(w, from - far, from + far)
		var by_pond: bool = evo(EVO_POND) and _is_pond(w) and far <= POND_STEPS * 2
		credit(EVO_POND if by_pond else EVO_FLOOD, enemy.global_position)

# Everything an evolution adds to a ripple (a Dewdrop's, or Lapping Water's from a bank Warden).
func _ripple_extras(enemy, w: int, soaked: Array) -> void:
	if soaked.is_empty() or not living(enemy):
		return
	if evo(EVO_MILLRACE):
		_millrace(enemy, soaked)
	if evo(EVO_RAIN):
		_rain(w, soaked)
	if evo(EVO_DOWNPOUR) and soaked.size() >= BURST_SOAKED:
		_downpour(enemy, w, soaked)

# Puts `stacks` of `id` on `other`: quietly onto a status it has, or started as `source`'s own (not native) application.
# Charged never fills to a bolt. True when it landed.
# `credit_id` (setup credit 2026-10-16): the evolution whose carry this is, for the ledger.
func _carry(other, id: StringName, stacks: int, source, credit_id: StringName = &"") -> bool:
	if not living(other) or id == EnemyStatuses.HELD or stacks <= 0:
		return false
	if other.statuses.has(id):
		var added: int = other.statuses.add_quiet(id, stacks)
		setup_quiet(other, credit_id, id, added)
		return added > 0
	if not (source is Tower) or not is_instance_valid(source):
		return false
	if id == EnemyStatuses.STATIC and stacks >= other.statuses.get_max_stacks(id) - 1:
		return false
	setup_apply(credit_id, source, other, id, stacks, source.get_damage())
	return living(other) and other.statuses.has(id)

# Millrace: the ripple carries 1 stack of up to 3 of the hit nightmare's other statuses to every nightmare it soaks.
func _millrace(enemy, soaked: Array) -> void:
	var carried: Array = []
	for id in enemy.statuses.active_ids():
		if carried.size() >= MILL_STATUSES:
			break
		if id == EnemyStatuses.DAMP or id == EnemyStatuses.HELD or id == EnemyStatuses.DROWSY:
			continue
		carried.append([id, enemy.statuses.source(id)])
	if carried.is_empty():
		return
	var given := 0
	for other in soaked:
		var landed := false
		for row in carried:
			if _carry(other, row[0], MILL_STACKS, row[1], EVO_MILLRACE):
				landed = true
		if landed:
			given += 1
			_line_fx(enemy.global_position, other.global_position, 1.0, Palette.DEWLIGHT)
	if given > 0:
		Reactions._effect(&"landing_dust", enemy.global_position, self, 0.5)
		credit(EVO_MILLRACE, enemy.global_position)

# Rain on the Bank: every nightmare the ripple soaks takes 1 of each of up to 3 bank Wardens' statuses (their own application).
func _rain(w: int, soaked: Array) -> void:
	var bank: Array = _bank_of(w).filter(func(t) -> bool: return status_of(t) != &"" and status_of(t) != EnemyStatuses.DROWSY)
	if bank.is_empty():
		return
	bank.sort_custom(func(a, b) -> bool: return second_of(a) > second_of(b))
	bank = bank.slice(0, RAIN_WARDENS)
	var rained := false
	for other in soaked:
		var wet_one := false
		for tower in bank:
			if _carry(other, status_of(tower), RAIN_STACKS, tower, EVO_RAIN):
				wet_one = true
		if wet_one:
			rained = true
			Reactions._effect(&"landing_dust", other.global_position, self, 0.35)
	if rained:
		for tower in bank:
			_line_fx(tower.global_position, soaked[0].global_position, 1.0, Palette.DEWLIGHT)
		credit(EVO_RAIN, soaked[0].global_position)

# Downpour: a ripple soaking 4 or more makes every bank Warden attack one of them at once (each Warden once in 4 s).
func _downpour(enemy, w: int, soaked: Array) -> void:
	var fired := 0
	for tower in _bank_of(w):
		if not tower.tower_data.can_attack or now() < float(tower.get_meta(BURST_META, -INF)):
			continue
		var target = soaked[fired % soaked.size()]
		if not living(target):
			continue
		tower.set_meta(BURST_META, now() + BURST_EVERY)
		tower.volley_now(target)
		_line_fx(tower.global_position, target.global_position, 2.0, Palette.DEWLIGHT)
		fired += 1
	if fired > 0:
		Reactions._effect(&"landing_dust", enemy.global_position, self, 1.6)
		credit(EVO_DOWNPOUR, enemy.global_position)

# A bank Warden's own hit on a Soaked nightmare in water it touches (Lapping Water, Reflection).
func _bank_hit(event, source, enemy, w: int) -> void:
	if not _soaked(enemy) or not touches_water(source, w):
		return
	if evo(EVO_LAPPING) and now() >= float(source.get_meta(LAP_META, -INF)) and w < waters.size():
		var dewdrop = _strongest(waters[w].dewdrops)
		if dewdrop != null:
			var soaked: Array = []
			for other in _in_water(w, index_of(enemy), LAP_STEPS, enemy):
				if now() >= float(other.get_meta(RIPPLE_META, -INF)):
					other.set_meta(RIPPLE_META, now() + RIPPLE_EVERY)
					setup_apply(EVO_LAPPING, dewdrop, other, EnemyStatuses.DAMP, 1, dewdrop.get_damage())  # (setup credit 2026-10-16)
					soaked.append(other)
			if not soaked.is_empty():
				source.set_meta(LAP_META, now() + LAP_EVERY)
				Reactions._effect(&"landing_dust", enemy.global_position, self, 0.6)
				for other in soaked:
					_line_fx(enemy.global_position, other.global_position, 1.0, Palette.DEWLIGHT)
				credit(EVO_LAPPING, enemy.global_position, source)
				_ripple_extras(enemy, w, soaked)
	if evo(EVO_REFLECTION) and living(enemy) and now() >= float(source.get_meta(MIRROR_META, -INF)):
		var last = _back_in(w, enemy)
		if last != null:
			source.set_meta(MIRROR_META, now() + MIRROR_EVERY)
			_line_fx(enemy.global_position, last.global_position, 2.0, Palette.DEWLIGHT)
			Reactions._effect(&"landing_dust", last.global_position, self, 0.5)
			strike(source, last, float(event.base) * MIRROR_SHARE, MIRROR_TAG, false, EVO_REFLECTION)  # (own: setup credit 2026-10-16)
			credit(EVO_REFLECTION, last.global_position, source)

# A Warden's own accepted status on a nightmare in water (Riverside): the status it just added lasts 2 s longer.
# Owner 2026-10-17: Dewdrop's own trait (Duration), was +1 stack. Every landing; the linger cap bounds it.
func _evo_status(tower, enemy, status: StringName) -> void:
	var w := water_of(enemy)
	if w < 0 or not EnemyStatuses.can_linger(status):
		return
	if evo(EVO_RIVERSIDE) and (is_own(tower) or is_other_family(tower)) and touches_water(tower, w):
		var side: float = enemy.statuses.linger(status, SIDE_SECONDS)
		SETUP.note_linger(enemy, card_id(EVO_RIVERSIDE), status, side)  # (setup credit 2026-10-16)
		if side > 0.0 and now() >= float(enemy.get_meta(SIDE_FX_META, -INF)):
			enemy.set_meta(SIDE_FX_META, now() + SIDE_FX_EVERY)
			_line_fx(tower.global_position, enemy.global_position, 1.5, Palette.DEWLIGHT)
			Reactions._effect(&"landing_dust", enemy.global_position, self, 0.35)
			credit(EVO_RIVERSIDE, enemy.global_position, tower)

# Stagnant Water (from _in_pond, each poll): every status gets back the time it lost since the last poll while the
# nightmare stays in a pond (bosses half). Leaving the pond forgets the record, so time lost outside never comes back.
func _stagnant(enemy) -> void:
	var statuses: EnemyStatuses = enemy.statuses
	var was: Dictionary = enemy.get_meta(STILL_META, {})
	var now_left := {}
	var share := STILL_BOSS_SHARE if statuses.is_boss else 1.0
	var held := false
	for id in statuses.active_ids():
		if not EnemyStatuses.can_linger(id):
			continue
		var left: float = statuses.time_left(id)
		if was.has(id):
			var lost: float = float(was[id]) - left  # Negative after a fresh landing: nothing to give back
			if lost > 0.0:
				var back: float = statuses.linger(id, lost * share)
				if back > 0.0:
					SETUP.note_linger(enemy, card_id(EVO_STAGNANT), id, back)  # (setup credit 2026-10-16)
					held = true
					left = statuses.time_left(id)
		now_left[id] = left
	enemy.set_meta(STILL_META, now_left)
	if held and now() >= float(enemy.get_meta(STILL_FX_META, -INF)):
		enemy.set_meta(STILL_FX_META, now() + STILL_FX_EVERY)
		Reactions._effect(&"landing_dust", enemy.global_position, self, 0.4)  # The still water's ripple
		credit(EVO_STAGNANT, enemy.global_position)

# The evolutions' poll: wet steps, the pond (slow, Whirlpool, Drowned Hands), Spring Flood.
func _evolutions_poll() -> void:
	if not class_on() or dream_state.calling_path.is_empty():
		return
	_dry_wet()
	var wet_on := evo(EVO_WET)
	var pond_on := evo(EVO_POND)
	if wet_on or pond_on:
		for enemy in enemies():
			if enemy.is_flying():
				continue  # Flyers are never in water
			if wet_on:
				_footprints(enemy, index_of(enemy))
			if pond_on and living(enemy):
				_in_pond(enemy)
	if evo(EVO_SPRING):
		_spring_tick()

# Black Pond's slow, and what happens in it (Whirlpool, Drowned Hands).
func _in_pond(enemy) -> void:
	var w := water_of(enemy)
	if not _is_pond(w):
		if enemy.has_meta(STILL_META):
			enemy.remove_meta(STILL_META)  # Stagnant Water: out of the pond, its statuses run down again
		return
	var boss: bool = enemy.statuses.is_boss
	var key := _water_key(waters[w])
	if evo(EVO_STAGNANT):
		_stagnant(enemy)
	HelperCommons.slow(enemy, POND_SLOW * (0.5 if boss else 1.0), POND_TIME)
	control_slow(EVO_POND, POND_SLOW * (0.5 if boss else 1.0), POLL)  # (setup credit 2026-10-16: the poll's time in the pond)
	if _once(enemy, "pond:" + key):
		Reactions._effect(&"landing_dust", enemy.global_position, self, 0.5)
		credit(EVO_POND, enemy.global_position)
	if evo(EVO_WHIRLPOOL) and not boss and _fully_soaked(enemy) and not enemy.get_meta(ONCE_META, {}).has("whirl:" + key):
		_whirlpool(enemy, w, key)
	if evo(EVO_HANDS) and living(enemy) and _status_count(enemy) >= HANDS_STATUSES \
			and not enemy.get_meta(ONCE_META, {}).has("hands:" + key):
		_drowned_hands(enemy, w, key)

func _status_count(enemy) -> int:
	var found := 0
	for id in enemy.statuses.active_ids():
		if id != EnemyStatuses.HELD:
			found += 1
	return found

# Whirlpool: pulled back 2 steps (never bosses or flyers: the caller checks). Drowning Deep drags its neighbours too.
func _whirlpool(enemy, w: int, key: String) -> void:
	var pixels := PULL_STEPS * cell()
	var pulled: float = enemy.push_back(pixels)
	if pulled <= 0.0:
		return  # Nothing moved: the pond's once is kept for a later try (council full_review 2026-10-17)
	_once(enemy, "whirl:" + key)
	SETUP.control_pull(dream_state, card_id(EVO_WHIRLPOOL), enemy, pulled)  # (setup credit 2026-10-16)
	Reactions._effect(&"landing_dust", enemy.global_position, self, 1.0)
	credit(EVO_WHIRLPOOL, enemy.global_position)
	dream_state.role_cards.pulled_back(null, enemy)  # Homesick hears this pull too (it counts as the pull role, 0104c4d7)
	if evo(EVO_DEEP):
		_drowning_deep(enemy, w, pixels)

# Drowning Deep: up to 4 nightmares within 1 cell are dragged with it (never bosses or flyers), and every Warden touching
# the pond hits the pulled one once, free (the one free-hit rule: once a second per Warden).
func _drowning_deep(enemy, w: int, pixels: float) -> void:
	var reach := DEEP_CELLS * cell()
	var dragged := 0
	for other in Tower.nightmares_near(get_tree(), enemy.global_position, reach):
		if dragged >= DEEP_MAX:
			break
		if other == enemy or not living(other) or other.statuses.is_boss or other.is_flying() \
				or other.global_position.distance_to(enemy.global_position) > reach:
			continue
		var dragged_px: float = other.push_back(pixels)
		if dragged_px > 0.0:
			SETUP.control_pull(dream_state, card_id(EVO_DEEP), other, dragged_px)  # (setup credit 2026-10-16)
			dragged += 1
			dream_state.role_cards.pulled_back(null, other)  # (Homesick)
			_line_fx(enemy.global_position, other.global_position, 2.0, Palette.DEWLIGHT)
	var hits := 0
	for tower in (waters[w].dewdrops as Array) + _bank_of(w):
		if _tower_ok(tower) and free_hit(tower, enemy, 1.0, FREE_HIT_TAG, INF, EVO_DEEP):  # (own: setup credit 2026-10-16)
			hits += 1
	if dragged > 0 or hits > 0:
		Reactions._effect(&"landing_dust", enemy.global_position, self, 1.6)
		credit(EVO_DEEP, enemy.global_position)

# Drowned Hands: Held by the pond's strongest Dewdrop (bosses half), once per pond (only spent when it holds).
func _drowned_hands(enemy, w: int, key: String) -> void:
	var dewdrop = _strongest(waters[w].dewdrops)
	if dewdrop == null:
		return
	var boss: bool = enemy.statuses.is_boss
	dewdrop.hold(enemy, HANDS_HOLD * (0.5 if boss else 1.0))
	if living(enemy) and enemy.statuses.is_held():
		control(EVO_HANDS, HANDS_HOLD * (0.5 if boss else 1.0))  # (setup credit 2026-10-16)
		_once(enemy, "hands:" + key)
		Reactions._effect(&"landing_dust", enemy.global_position, self, 1.2)
		credit(EVO_HANDS, enemy.global_position)

# Wet Footprints: a Soaked nightmare walking out of real water wets the next steps it walks (6 at most) for 3 s.
func _footprints(enemy, i: int) -> void:
	var real := int(_water_at.get(i, -1)) if i >= 0 else -1
	var prev := int(enemy.get_meta(REAL_META, -1))
	enemy.set_meta(REAL_META, real)
	if real >= 0:
		if enemy.has_meta(FOOT_META):
			enemy.remove_meta(FOOT_META)
		return
	if i < 0:
		return
	if prev >= 0 and prev < waters.size() and _soaked(enemy):
		enemy.set_meta(FOOT_META, [prev, WET_STEPS * 2, i - 1])
		credit(EVO_WET, enemy.global_position)
	if not enemy.has_meta(FOOT_META):
		return
	var foot: Array = enemy.get_meta(FOOT_META)
	var left := int(foot[1])
	var last := int(foot[2])
	var laid := false
	for j in range(last + 1, i + 1):
		if left <= 0:
			break
		if j >= _route_px.size() or _water_at.has(j):
			continue
		_wet[j] = [now() + WET_SECONDS, int(foot[0])]
		_wet_touch[j] = _attackers_touching(_route_px[j])
		left -= 1
		laid = true
	if left <= 0:
		enemy.remove_meta(FOOT_META)
	else:
		enemy.set_meta(FOOT_META, [int(foot[0]), left, maxi(last, i)])
	if laid:
		queue_redraw()

func _attackers_touching(at: Vector2) -> Array:
	var found: Array = []
	for tower in towers():
		if tower.tower_data.can_attack and touches_point(tower, at):
			found.append(tower)
	return found

# Wet steps dry after WET_SECONDS.
func _dry_wet() -> void:
	if _wet.is_empty():
		return
	var dried := false
	for i in _wet.keys():
		if float(_wet[i][0]) <= now():
			_wet.erase(i)
			_wet_touch.erase(i)
			dried = true
	if dried:
		queue_redraw()

# Spring Flood: every 10 s of drift time the longest water with a nightmare in it floods: up to 8 in it are fully Soaked
# (by its strongest Dewdrop) and walk 25% slower for 2 s (bosses half). With nobody in water it waits for the first one.
func _spring_tick() -> void:
	if resting():
		return
	_spring_in -= POLL
	if _spring_in > 0.0:
		return
	var inside := {}  # Water -> nightmares in it
	for enemy in enemies():
		var w := water_of(enemy)
		if w >= 0 and int(_water_at.get(index_of(enemy), -1)) == w:  # Real water only (wet steps aren't a water's length)
			if not inside.has(w):
				inside[w] = []
			inside[w].append(enemy)
	var best := -1
	for w in inside:
		if best < 0 or float(waters[int(w)].steps) > float(waters[best].steps):
			best = int(w)
	if best < 0:
		_spring_in = 0.0
		return
	_spring_in = SPRING_EVERY
	var dewdrop = _strongest(waters[best].dewdrops)
	var targets: Array = inside[best]
	targets.sort_custom(func(a, b) -> bool: return index_of(a) > index_of(b))
	for enemy in targets.slice(0, SPRING_MAX):
		var room: int = enemy.statuses.get_max_stacks(EnemyStatuses.DAMP) - enemy.statuses.stacks(EnemyStatuses.DAMP)
		if room > 0 and dewdrop != null:
			setup_apply(EVO_SPRING, dewdrop, enemy, EnemyStatuses.DAMP, room, dewdrop.get_damage())  # (setup credit 2026-10-16)
		if living(enemy):
			var boss: bool = enemy.statuses.is_boss
			HelperCommons.slow(enemy, SPRING_SLOW * (0.5 if boss else 1.0), SPRING_SECONDS)
			control_slow(EVO_SPRING, SPRING_SLOW * (0.5 if boss else 1.0), SPRING_SECONDS)
			Reactions._effect(&"landing_dust", enemy.global_position, self, 0.6)
	_water_fx(best, int(waters[best].first), int(waters[best].last), 2.0)
	credit(EVO_SPRING, _route_px[int(waters[best].first)])

# --- Statuses from another family's Wardens -----------------------------------------------------------------------------

# {status: [stacks, potency, line, WeakRef]} for every status on `enemy` whose Warden is another family's (never
# Soaked, never Rooted).
func _other_statuses(enemy) -> Dictionary:
	var out := {}
	var statuses: EnemyStatuses = enemy.statuses
	for id in statuses.active_ids():
		if id == EnemyStatuses.DAMP or id == EnemyStatuses.HELD:
			continue
		var source = statuses.source(id)
		if is_other_family(source):
			out[id] = [statuses.stacks(id), statuses.potency(id), source.tower_data.line, weakref(source), statuses.time_left(id)]
	return out

# Puts `stacks` of `id` on `enemy` (a carried status: not a native application, never above the limit, Charged one
# short of a bolt). A status that is there gains quietly; one that ended comes back for `seconds`.
func _give(enemy, id: StringName, stacks: int, row: Array, seconds: float) -> void:
	if stacks <= 0 or not living(enemy) or id == EnemyStatuses.HELD:
		return
	var statuses: EnemyStatuses = enemy.statuses
	if statuses.has(id):
		statuses.add_quiet(id, stacks)
		return
	var cap: int = statuses.get_max_stacks(id)
	if id == EnemyStatuses.STATIC:
		cap -= 1
	stacks = mini(stacks, cap)
	if stacks <= 0:
		return
	var source = row[3].get_ref() if row[3] is WeakRef else null
	enemy.apply_status(id, stacks, seconds, float(row[1]), 0, String(row[2]), source if is_instance_valid(source) else null)

# The Water Remembers: every status from another family's Warden that wore off since it left comes back (never above
# what it carried when it left; one that had ended comes back with 3 s).
func _remember(enemy, dewdrop_id: String) -> void:
	var left: Dictionary = enemy.get_meta(LEFT_META, {})
	var snapshot: Dictionary = left.get(dewdrop_id, {})
	var any := false
	for id in snapshot:
		var lost: int = int(snapshot[id][0]) - enemy.statuses.stacks(id)
		if lost > 0:
			_give(enemy, id, lost, snapshot[id], REMEMBERS_SECONDS)
			any = true
	if any:
		Reactions._effect(&"landing_dust", enemy.global_position, self, 0.6)

# Wake Ripple (DreamState.class_status tells us): another family's Warden touching water added its status to a
# nightmare in it: the ripple carries 1 stack to the others within 4 steps in that water (that Warden's own
# application of 1, once a second for each receiver; Charged stops one short of a bolt).
func status_applied(tower, enemy, status: StringName, _stacks: int) -> void:
	if rule(CAUGHT_WADING) and status == EnemyStatuses.DAMP and is_own(tower) and living(enemy):
		_caught_wading(tower, enemy)
	if class_on() and not dream_state.calling_path.is_empty() and status != EnemyStatuses.HELD and living(enemy):
		_evo_status(tower, enemy, status)  # Riverside, Stagnant Water
	if not place_on() or not rule(WAKE_RIPPLE) or not is_other_family(tower) or status == EnemyStatuses.HELD or not living(enemy):
		return
	var w := water_of(enemy)
	if w < 0 or not touches_water(tower, w):
		return
	for other in _in_water(w, index_of(enemy), RIPPLE_STEPS, enemy):
		if now() < float(other.get_meta(CARRY_META, -INF)):
			continue
		var statuses: EnemyStatuses = other.statuses
		if status == EnemyStatuses.STATIC and statuses.stacks(status) >= statuses.get_max_stacks(status) - 1:
			continue
		other.set_meta(CARRY_META, now() + RIPPLE_EVERY)
		tower._apply_one_status(other, status, 1, tower.get_damage(), false)

# Caught Wading: when a Dewdrop first Soaks a nightmare, up to 3 other Wardens near that Dewdrop hit it once, free; again
# when it is fully Soaked. Never more than the Dewdrop's own hit; once each per nightmare.
func _caught_wading(dewdrop, enemy) -> void:
	var full := _fully_soaked(enemy)
	if not _once(enemy, "wading_full" if full else "wading"):
		return
	if full:
		_once(enemy, "wading")  # Full at the first touch: the first half is spent too
	var fired := 0
	for tower in towers():
		if fired >= CAUGHT_WARDENS:
			break
		if tower != dewdrop and is_other(tower) and near(tower.global_position, dewdrop.global_position) \
				and free_hit(tower, enemy, 1.0, FREE_HIT_TAG, dewdrop.get_damage(), CAUGHT_WADING):  # (own: setup credit 2026-10-16)
			fired += 1

# Steeped and Pooling (DreamState.class_duration, from Enemy.apply_status: every application counts, carried ones too):
# how much longer this landing lasts. Steeped: +30% from a Warden touching a Dewdrop (a Dewdrop touches itself).
# Pooling: +50% on a nightmare inside two Dewdrops' ranges at once. They add; the extra is at most LINGER_MAX (Charged
# LINGER_MAX_STATIC), never on Rooted or Drowsy. `duration` 0 = the status's default.
# (Waterlogged's old x1.5 at landing is Slow to Dry's poll now: _slow_to_dry.)
func status_duration(source, enemy, status: StringName, duration: float) -> float:
	if not EnemyStatuses.can_linger(status) or not living(enemy):
		return duration
	var share := 0.0
	var steeped: bool = rule(STEEPED) and ((source is Tower and is_instance_valid(source) and source.tower_data.can_attack \
			and (is_own(source) or own_towers().any(func(d) -> bool: return touching(d, source)))) or _ranges_holding(enemy, 2) >= 2)
	if steeped:
		share += STEEPED_SHARE  # One 40%, whichever way it qualifies (Pooling folded in)
	elif rule(POOLING) and _ranges_holding(enemy, 2) >= 2:
		share += POOLING_SHARE  # (Retired 2026-10-16; an old save keeps it)
	if share <= 0.0:
		return duration
	var base := duration if duration > 0.0 else float(EnemyStatuses.DEFAULT_DURATION.get(status, 0.0))
	var extra := minf(base * share, EnemyStatuses.LINGER_MAX_STATIC if status == EnemyStatuses.STATIC else EnemyStatuses.LINGER_MAX)
	if extra <= 0.0:
		return duration
	enemy.statuses.pending_linger[status] = extra  # The badge's lingering look (EnemyStatuses.apply books it)
	# Setup credit 2026-10-16 (Linger, stack-equivalent): the stacks it has (at least 1) x the extra seconds / its default
	SETUP.note(enemy, card_id(STEEPED if steeped else POOLING), status,
		float(maxi(enemy.statuses.stacks(status), 1)) * extra / maxf(float(EnemyStatuses.DEFAULT_DURATION.get(status, 1.0)), 0.1))
	return base + extra

# How many Dewdrops have `enemy` inside their range (stops counting at `enough`).
func _ranges_holding(enemy, enough: int) -> int:
	var found := 0
	for tower in own_towers():
		if tower.global_position.distance_to(enemy.global_position) <= tower.get_range_pixels():
			found += 1
			if found >= enough:
				break
	return found

# Dripping: a nightmare leaving a Dewdrop's range keeps every status it carries 2 s longer (within the linger cap).
func _drip(enemy) -> void:
	var any := false
	for id in enemy.statuses.active_ids():
		var dripped: float = enemy.statuses.linger(id, DRIPPING_SECONDS)
		SETUP.note_linger(enemy, card_id(DRIPPING), id, dripped)  # (setup credit 2026-10-16)
		if dripped > 0.0:
			any = true
	if any:
		Reactions._effect(&"landing_dust", enemy.global_position, self, 0.5)

# Ebb (EnemyStatuses.status_ran_out, hooked in on_poll): a status that runs out of time on a nightmare in a Dewdrop's
# range comes back at half its most stacks for 3 s. Once per status and nightmare; never Rooted, Drowsy or Soaked;
# Charged stops one short of a bolt. Spent statuses (a Reaction, a bolt) never ran out, so they never ebb.
func _ebb(id: StringName, peak: int, source: Node, potency: float, line: String, enemy) -> void:
	if not rule(EBB) or not living(enemy) or not EnemyStatuses.can_linger(id) or _ranges_holding(enemy, 1) < 1:
		return
	if not _once(enemy, "ebb:" + String(id)):
		return
	var stacks := maxi(peak / 2, 1)
	if id == EnemyStatuses.STATIC:
		stacks = mini(stacks, enemy.statuses.get_max_stacks(id) - 1)
	if stacks <= 0:
		return
	SETUP.apply(enemy, card_id(EBB), id, stacks, EBB_SECONDS, potency, 0, line, source if is_instance_valid(source) else null)  # (setup credit 2026-10-16)
	if living(enemy):
		enemy.statuses.note_stretched(id, EBB_SECONDS)  # Keyword chips 2026-10-16: a status brought back is Linger (is_lingering)

# Slow to Dry (rule id waterlogged): on a Soaked nightmare near a Dewdrop, another family's status can't run out before
# its Soaked does (it lingers to match, within the linger cap). Polled.
func _slow_to_dry(enemy) -> void:
	if not _soaked(enemy) or strongest_near(enemy.global_position, is_own) == null:
		return
	var statuses: EnemyStatuses = enemy.statuses
	var soaked_left := statuses.time_left(EnemyStatuses.DAMP)
	for id in statuses.active_ids():
		if not EnemyStatuses.can_linger(id) or not is_other_family(statuses.source(id)):
			continue
		var short := soaked_left - statuses.time_left(id)
		if short > POLL:
			SETUP.note_linger(enemy, card_id(WATERLOGGED), id, statuses.linger(id, short))  # (setup credit 2026-10-16)

# Old Rain and Never Quite Dry (DreamState.class_reaction, from Enemy.apply_status): the Reaction check, wrapped.
func around_reaction(enemy, id: StringName, source) -> void:
	if not living(enemy) or enemy.statuses.count() < 2 or strongest_near(enemy.global_position, is_own) == null:
		Reactions.on_status(enemy, id, source)
		return
	var statuses: EnemyStatuses = enemy.statuses
	# Old Rain: the statuses a card is making last longer, read before this check spends them (keyword chips 2026-10-16)
	var was_raining := _old_rain  # (A Reaction's own statuses can run a check inside this one)
	var was_rain_ids := _rain_ids
	if rule(OLD_RAIN):
		_rain_ids = _lingering_ids(statuses)
		_old_rain = was_raining or not _rain_ids.is_empty()
	var before := {}
	if rule(NEVER_DRY) and now() >= float(enemy.get_meta(NEVER_DRY_META, -INF)):
		for status in statuses.active_ids():
			if status != EnemyStatuses.HELD:
				before[status] = [statuses.stacks(status), statuses.potency(status), String(statuses._active[status].get("line", "")),
					statuses.source(status), statuses.time_left(status)]
	Reactions.on_status(enemy, id, source)
	_old_rain = was_raining
	_rain_ids = was_rain_ids
	if before.is_empty() or not living(enemy):
		return
	# Never Quite Dry: the statuses a Reaction spent come back at half the stacks they had (quietly: no new check)
	var back := false
	for status in before:
		var row: Array = before[status]
		var lost: int = int(row[0]) - statuses.stacks(status)
		if lost <= 0:
			continue
		var stacks := maxi(int(row[0]) / 2 - statuses.stacks(status), 0)
		if status == EnemyStatuses.STATIC:
			stacks = mini(stacks, statuses.get_max_stacks(status) - 1 - statuses.stacks(status))
		if stacks <= 0:
			continue
		if statuses.has(status):
			statuses.add_quiet(status, stacks)
		else:
			statuses.apply(status, stacks, maxf(float(row[4]), 1.0), float(row[1]), 0, String(row[2]), row[3] if is_instance_valid(row[3]) else null)
		back = true
	if back:
		enemy.set_meta(NEVER_DRY_META, now() + NEVER_DRY_EVERY)
		Reactions._effect(&"landing_dust", enemy.global_position, self, 0.6)

# Something in the Water (lent): a Dewdrop's splash adds 1, quietly, to each status another family's Warden near it has
# put on that nightmare (at most two statuses; once a second for each Dewdrop; it never starts a status).
func _something(dewdrop, enemy) -> void:
	if now() < float(dewdrop.get_meta(SOMETHING_META, -INF)):
		return
	var added := 0
	var statuses: EnemyStatuses = enemy.statuses
	for id in statuses.active_ids():
		if added >= SOMETHING_STATUSES:
			break
		if id == EnemyStatuses.DAMP or id == EnemyStatuses.HELD:
			continue
		var source = statuses.source(id)
		if is_other_family(source) and near(source.global_position, dewdrop.global_position):
			var got: int = statuses.add_quiet(id, 1)
			setup_quiet(enemy, SOMETHING, id, got)  # (setup credit 2026-10-16)
			if got > 0:
				added += 1
	if added > 0:
		dewdrop.set_meta(SOMETHING_META, now() + 1.0)

# Soaked Through (lent): when a nightmare near a Dewdrop becomes fully Soaked, each Warden of another family near that
# Dewdrop hits it once, free (up to 4; once for each nightmare).
func _soaked_through(enemy) -> void:
	if not _fully_soaked(enemy) or enemy.get_meta(ONCE_META, {}).has("through"):
		return
	var dewdrop = strongest_near(enemy.global_position, is_own)
	if dewdrop == null:
		return
	_once(enemy, "through")
	var fired := 0
	for tower in towers():
		if fired >= SOAKED_THROUGH_WARDENS:
			break
		if is_other_family(tower) and near(tower.global_position, dewdrop.global_position) and free_hit(tower, enemy, 1.0, FREE_HIT_TAG, dewdrop.get_damage(), SOAKED_THROUGH):
			fired += 1

# Run-Off (lent): when a Soaked nightmare is dispelled near a Dewdrop, the statuses on it from another family's Wardens
# wash onto the nearest Soaked nightmare within 2 cells (moved, not copied; it keeps the longer clock).
func _run_off(enemy) -> void:
	if not is_instance_valid(enemy) or not _soaked(enemy) or strongest_near(enemy.global_position, is_own) == null:
		return
	var carried := _other_statuses(enemy)
	if carried.is_empty():
		return
	var at: Vector2 = enemy.global_position
	var target = null
	var best := INF
	for other in enemies():
		if other != enemy and _soaked(other) and near(other.global_position, at) and other.global_position.distance_squared_to(at) < best:
			best = other.global_position.distance_squared_to(at)
			target = other
	if target == null:
		return
	_line_fx(at, target.global_position, 2.0, Palette.DEWLIGHT)
	for id in carried:
		var row: Array = carried[id]
		var statuses: EnemyStatuses = target.statuses
		if statuses.has(id):
			statuses.add_quiet(id, int(row[0]))
		else:
			_give(target, id, int(row[0]), row, maxf(float(row[4]), 0.5))
		enemy.statuses.remove(id)

# --- What the other systems ask (through DreamState) --------------------------------------------------------------------

# Wash Away: a Soaked nightmare in water loses half its family resistance to every Warden touching that water (x0.5
# becomes x0.75). Not bosses. Status length, immunities, the blight coat and shape multipliers stay.
func damage_multiplier(enemy, source, tag: StringName = &"") -> float:
	if not active():
		return 1.0
	var multiplier := 1.0
	# Old Rain (keyword chips 2026-10-16, keyword_chips_td.md 4: reads EnemyStatuses.is_lingering, not age): a Reaction near
	# a Dewdrop that spends a status a card made last longer deals 40% more (its burst). Shatter and Lightning Rod never pass
	# a landing: they read the statuses still on it.
	if tag in REACTION_BURSTS and rule(OLD_RAIN):
		var rain_ids: Array = _rain_ids if _old_rain else _lingering_ids(enemy.statuses)
		if _rain_spends(tag, rain_ids) and (_old_rain or strongest_near(enemy.global_position, is_own) != null):
			multiplier *= OLD_RAIN_BONUS
			DamageLog.note_card_bonus("old_rain", OLD_RAIN_BONUS)  # Card credit (Main Merger df7010bb)
	if not (source is Tower) or not is_instance_valid(source):
		return multiplier
	if rule(HIGH_TIDE) and tag == &"" and dewdrop_near(source) != null:
		# High Tide (keyword chips 2026-10-16: every status counts, cap +30%): hits from Wardens near a Dewdrop deal 10% more
		# for each status on the nightmare
		var tide := 1.0 + minf(HIGH_TIDE_PER * enemy.statuses.count(), HIGH_TIDE_MAX)
		multiplier *= tide
		DamageLog.note_card_bonus("high_tide", tide)
	if not _soaked(enemy):
		return multiplier  # The older Dewdrop damage cards (retired) read a Soaked nightmare
	if tag == &"" and enemy.has_meta(RIP_META):  # Riptide: each Warden near that Dewdrop, its first hit while it wades
		var rip: Dictionary = enemy.get_meta(RIP_META)
		if now() <= float(rip.until) and not rip.done.has(source.get_instance_id()) and near(source.global_position, rip.at):
			rip.done[source.get_instance_id()] = true
			multiplier *= 2.0
			DamageLog.note_card_bonus("riptide", 2.0)
	if not rule(DEEP_POOL) or dewdrop_near(source) == null:
		return multiplier
	if rule(DEEP_POOL) and tag == &"":  # Deep Pool: hits deal +10% for each status it carries besides Soaked (never Rooted)
		var others := 0
		for id in enemy.statuses.active_ids():
			if id != EnemyStatuses.DAMP and id != EnemyStatuses.HELD:
				others += 1
		multiplier *= 1.0 + DEEP_POOL_PER_STATUS * others
		DamageLog.note_card_bonus("deep_pool", 1.0 + DEEP_POOL_PER_STATUS * others)
	return multiplier

# Wash Away (Enemy.take_damage asks through DreamState.shell_multiplier): a Soaked nightmare's shell (the blight coat)
# takes double damage from Wardens near a Dewdrop. Not bosses. (Resistances are gone, enemy_design.md ed6f573b.)
func shell_multiplier(enemy, source) -> float:
	if not active() or not rule(WASH_AWAY) or not (source is Tower) or not is_instance_valid(source):
		return 1.0
	if enemy.statuses.is_boss or not _soaked(enemy) or dewdrop_near(source) == null:
		return 1.0
	return WASH_AWAY_SHELL

# Across the Water: any Warden touching water also reaches Soaked nightmares up to 3 steps further along that water
# (never more than 5 cells from it). Adds them to its target list.
func extra_targets(tower, candidates: Array[Node2D]) -> Array[Node2D]:
	if not active() or not rule(ACROSS) or not tower.tower_data.can_attack or dewdrop_near(tower) == null:
		return candidates
	# Across the Water: Wardens near a Dewdrop reach Soaked nightmares up to 1 cell past their range
	var reach: float = tower.get_range_pixels() + ACROSS_EXTRA_CELLS * cell()
	for enemy in Tower.nightmares_near(get_tree(), tower.global_position, reach):
		if not candidates.has(enemy) and living(enemy) and _soaked(enemy) and tower.global_position.distance_to(enemy.global_position) <= reach:
			candidates.append(enemy)
	return candidates

# --- Drawing: the water ---------------------------------------------------------------------------------------------------

func _draw() -> void:
	if not place_on():
		return
	# Soft overlapping pools along the wet path (not squares): a deep body, a lighter centre, a glint
	var r := cell() * 0.42
	for water in waters:
		for i in water.points:
			var at: Vector2 = _route_px[int(i)]
			draw_circle(at, r, Color(Palette.POOL, 0.28))
		for i in water.points:
			var at: Vector2 = _route_px[int(i)]
			draw_circle(at, r * 0.55, Color(Palette.DEW, 0.18))
			if int(i) % 3 == 0:
				draw_circle(at + Vector2(-r * 0.3, -r * 0.25), 1.5, Color(Palette.DEWLIGHT, 0.6))
		if float(water.steps) >= BREAKWATER_STEPS and rule(BREAKWATER):
			draw_circle(_route_px[int(water.last)], 6.0, Color(Palette.DEWLIGHT, 0.8))  # Deep water: a wave waits at its end
	if not class_on() or dream_state.calling_path.is_empty():
		return
	# Black Pond: darker, still water
	if evo(EVO_POND):
		for w in waters.size():
			if _is_pond(w):
				for i in waters[w].points:
					draw_circle(_route_px[int(i)], r * 0.8, Color(Palette.POOL, 0.4))
	# Stream: a current on the water it carried on, pointing to the Heartwood
	for i in _flowed:
		var at: Vector2 = _route_px[int(i)]
		if int(i) % 2 != 0 or int(i) + 1 >= _route_px.size():
			continue
		var dir: Vector2 = (_route_px[int(i) + 1] - at).normalized()
		var side := Vector2(-dir.y, dir.x) * r * 0.3
		draw_line(at - dir * r * 0.3 + side, at, Color(Palette.DEWLIGHT, 0.55), 1.5)
		draw_line(at - dir * r * 0.3 - side, at, Color(Palette.DEWLIGHT, 0.55), 1.5)
	# Wet Footprints: small wet prints on the steps that count as water for now
	for i in _wet:
		var at: Vector2 = _route_px[int(i)]
		draw_circle(at + Vector2(-r * 0.2, 0.0), r * 0.16, Color(Palette.DEW, 0.45))
		draw_circle(at + Vector2(r * 0.2, -r * 0.15), r * 0.16, Color(Palette.DEW, 0.45))
