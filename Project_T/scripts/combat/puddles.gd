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

func _family() -> String:
	return FAMILY

func _line() -> String:
	return LINE

# Lent cards never give the Calling's setup (owner 2026-10-14, dream_council_review.md 25-26): water, lone water and the
# ripple are the first pick's only (place_on). The lent cards work from Dewdrops, where Wardens stand ("near a Dewdrop":
# 2 cells; "a Dewdrop's range": its attack range) and Soaked.
func _lent_rules() -> Array:
	return [CAUGHT_WADING, SHALLOWS, KNEE_DEEP, ACROSS, DEEP_POOL, REMEMBERS, RUN_OFF, WASH_AWAY, RIPTIDE, WATERLOGGED,
		SOMETHING, SOAKED_THROUGH]  # (Something in the Water, Soaked Through: retired, need no water; old saves keep them)

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
	return int(_water_at.get(i, -1)) if i >= 0 else -1

func is_lone(tower) -> bool:
	return _lone.has(tower.get_instance_id())

func touches_water(tower, w: int) -> bool:
	return w >= 0 and _waters_of.get(tower.get_instance_id(), []).has(w)

# The living nightmares in water `w` within `steps` of route index `from` (not `skip`), nearest first.
func _in_water(w: int, from: int, steps: int, skip = null) -> Array:
	var found: Array = []
	for enemy in enemies():
		if enemy == skip:
			continue
		var i := index_of(enemy)
		if i >= 0 and int(_water_at.get(i, -1)) == w and absi(i - from) <= steps * 2:
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
	if not place_on() or not is_own(source):
		return
	var w := water_of(enemy)
	if w < 0 or not touches_water(source, w):
		return
	var from := index_of(enemy)
	# The Calling's ripple (the first pick only): nightmares within 4 steps in that water are Soaked
	if class_on():
		ripples += 1
	for other in (_in_water(w, from, RIPPLE_STEPS, enemy) if class_on() else []):
		if now() >= float(other.get_meta(RIPPLE_META, -INF)):
			other.set_meta(RIPPLE_META, now() + RIPPLE_EVERY)
			source._apply_one_status(other, EnemyStatuses.DAMP, 1, source.get_damage(), false)
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
		if i > best and int(_water_at.get(i, -1)) == w:
			best = i
			front = enemy
	return front

# --- The poll: who walks in, who walks out ------------------------------------------------------------------------------

func on_poll() -> void:
	if rule(SOAKED_THROUGH):
		for enemy in enemies():
			_soaked_through(enemy)
	var ranges := rule(REMEMBERS) or rule(RIPTIDE)
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
			if is_instance_valid(tower) and free_hit(tower, enemy):
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
				tower._apply_one_status(enemy, EnemyStatuses.DAMP, room, tower.get_damage(), false)
		if rule(THERE_AND_BACK):
			free_hit(tower, enemy)  # There and Back: hit once, free, by that lone Dewdrop

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
				and free_hit(tower, enemy, 1.0, FREE_HIT_TAG, dewdrop.get_damage()):
			fired += 1

# Waterlogged (DreamState.class_duration, from Enemy.apply_status: every application counts): another family's status
# from a Warden near a Dewdrop, on a nightmare Soaked at that moment, lasts half again as long. Never Soaked, Drowsy or
# Rooted. `duration` 0 = the status's default.
func status_duration(source, enemy, status: StringName, duration: float) -> float:
	if status == EnemyStatuses.DAMP or status == EnemyStatuses.DROWSY or status == EnemyStatuses.HELD:
		return duration
	if not (source is Tower) or not is_instance_valid(source) or not is_other(source) or not _soaked(enemy) or dewdrop_near(source) == null:
		return duration
	if duration <= 0.0:
		duration = float(EnemyStatuses.DEFAULT_DURATION.get(status, 0.0))
	return duration * WATERLOGGED_FACTOR

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
		if is_other_family(source) and near(source.global_position, dewdrop.global_position) and statuses.add_quiet(id, 1) > 0:
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
		if is_other_family(tower) and near(tower.global_position, dewdrop.global_position) and free_hit(tower, enemy, 1.0, FREE_HIT_TAG, dewdrop.get_damage()):
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
	if not active() or not (source is Tower) or not is_instance_valid(source) or not _soaked(enemy):
		return 1.0  # Every Dewdrop damage card reads a Soaked nightmare
	var multiplier := 1.0
	if tag == &"" and enemy.has_meta(RIP_META):  # Riptide: each Warden near that Dewdrop, its first hit while it wades
		var rip: Dictionary = enemy.get_meta(RIP_META)
		if now() <= float(rip.until) and not rip.done.has(source.get_instance_id()) and near(source.global_position, rip.at):
			rip.done[source.get_instance_id()] = true
			multiplier *= 2.0
	if not rule(DEEP_POOL) or dewdrop_near(source) == null:
		return multiplier
	if rule(DEEP_POOL) and tag == &"":  # Deep Pool: hits deal +10% for each status it carries besides Soaked (never Rooted)
		var others := 0
		for id in enemy.statuses.active_ids():
			if id != EnemyStatuses.DAMP and id != EnemyStatuses.HELD:
				others += 1
		multiplier *= 1.0 + DEEP_POOL_PER_STATUS * others
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
