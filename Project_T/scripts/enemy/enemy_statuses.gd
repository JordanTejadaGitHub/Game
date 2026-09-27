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

const DAMP := &"damp"
const DROWSY := &"drowsy"
const SPORED := &"spored"
const MARKED := &"marked"
const STATIC := &"static"
const ALL: Array[StringName] = [DAMP, DROWSY, SPORED, MARKED, STATIC]

const DEFAULT_DURATION := {DAMP: 4.0, DROWSY: 3.0, SPORED: 5.0, MARKED: 5.0, STATIC: 2.0}
const DEFAULT_MAX_STACKS := {DAMP: 1, DROWSY: 5, SPORED: 8, MARKED: 1, STATIC: 5}
const BOSS_MAX_STACKS := {DROWSY: 3, STATIC: 8}
const COLORS := {
	DAMP: Color(0.45, 0.7, 1.0), DROWSY: Color(0.75, 0.6, 1.0), SPORED: Color(0.7, 0.9, 0.4),
	MARKED: Color(1.0, 0.85, 0.3), STATIC: Color(1.0, 1.0, 0.55),
}

const DAMP_SLOW := 0.10
const DROWSY_SLOW_PER_STACK := 0.08
const MARKED_EXTRA := 0.25
const STATIC_BOLT_MULTIPLIER := 3.0
const STATIC_DECAY_TIME := 2.0  # Seconds per lost Static stack
const SPORE_TICK := 0.5  # Spored soothes in ticks this long
const FOG_SPORE_BONUS := 0.5  # Spored ticks +50% while in fog (Mistveil)

var is_boss := false
# {id: {"stacks": int, "time": float (seconds left), "potency": float}}
var _active := {}
var _spore_timer := 0.0
var _fog_time := 0.0

# Adds `stacks` of `id` (up to `max_stacks`, 0 = default cap) and refreshes its duration.
# Returns the soothe of a Static bolt if this application set one off, else 0.
func apply(id: StringName, stacks: int = 1, duration: float = 0.0, potency: float = 0.0,
		max_stacks: int = 0) -> float:
	var cap := get_max_stacks(id, max_stacks)
	var status: Dictionary = _active.get(id, {"stacks": 0, "time": 0.0, "potency": 0.0})
	status.stacks = mini(status.stacks + stacks, cap)
	status.time = maxf(status.time, duration if duration > 0.0 else DEFAULT_DURATION[id])
	status.potency = maxf(status.potency, potency)
	# Driftspore's higher cap sticks once reached, even if a Sporeling hits next.
	status["cap"] = maxi(status.get("cap", 0), cap)
	_active[id] = status
	if id == STATIC and status.stacks >= cap:
		_active.erase(STATIC)
		return status.potency * STATIC_BOLT_MULTIPLIER
	return 0.0

func get_max_stacks(id: StringName, override: int = 0) -> int:
	var cap: int = override if override > 0 else DEFAULT_MAX_STACKS[id]
	if is_boss and BOSS_MAX_STACKS.has(id):
		cap = BOSS_MAX_STACKS[id] if id == DROWSY else maxi(cap, BOSS_MAX_STACKS[id])
	return maxi(cap, _active.get(id, {}).get("cap", 0))

func has(id: StringName) -> bool:
	return _active.has(id)

func stacks(id: StringName) -> int:
	return _active[id].stacks if _active.has(id) else 0

func potency(id: StringName) -> float:
	return _active[id].potency if _active.has(id) else 0.0

func time_left(id: StringName) -> float:
	return _active[id].time if _active.has(id) else 0.0

func remove(id: StringName) -> void:
	_active.erase(id)

func active_ids() -> Array:
	return _active.keys()

# Keeps the creature "in fog" (Mistveil) for `seconds`.
func set_in_fog(seconds: float) -> void:
	_fog_time = maxf(_fog_time, seconds)

func is_in_fog() -> bool:
	return _fog_time > 0.0

# Movement speed multiplier from slows.
func get_speed_multiplier() -> float:
	var slow := 0.0
	if has(DAMP):
		slow += DAMP_SLOW
	slow += DROWSY_SLOW_PER_STACK * stacks(DROWSY)
	return maxf(1.0 - slow, 0.1)

# Soothe taken multiplier (Marked).
func get_damage_taken_multiplier() -> float:
	return 1.0 + MARKED_EXTRA if has(MARKED) else 1.0

# Advances timers. Returns the Spored soothe to deal this frame (already fog-boosted).
func tick(delta: float) -> float:
	_fog_time = maxf(_fog_time - delta, 0.0)
	var spore_damage := 0.0
	if has(SPORED):
		_spore_timer += delta
		while _spore_timer >= SPORE_TICK:
			_spore_timer -= SPORE_TICK
			var per_tick: float = _active[SPORED].stacks * _active[SPORED].potency * SPORE_TICK
			spore_damage += per_tick * (1.0 + FOG_SPORE_BONUS if is_in_fog() else 1.0)
	else:
		_spore_timer = 0.0

	for id in _active.keys():
		var status: Dictionary = _active[id]
		status.time -= delta
		if status.time > 0.0:
			continue
		if id == STATIC and status.stacks > 1:
			status.stacks -= 1  # Static bleeds off one charge at a time
			status.time = STATIC_DECAY_TIME
		else:
			_active.erase(id)
	return spore_damage
