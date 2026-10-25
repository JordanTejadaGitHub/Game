class_name GroveRules
extends RefCounted

const DREAM_BURST := preload("res://scripts/fx/dream_burst.gd")
const RIPPLE_EFFECT := preload("res://scripts/fx/great_ripple.gd")

# Grove build branches "Swift" and "Wide Reach" (dream_design.md; Roguelite Code's cards, 8a17671c): the
# per-hit parts, read by rule id. DreamState carries the numbers. A Warden's own state lives in
# Tower._grove. Restless Roots and Far Reach are DreamEffects rows (already in the Warden's stats).

# --- Swift --------------------------------------------------------------------------------------------

# Attack speed from Momentum (a streak on one nightmare) and Quickening (a dispel in range), on top of
# the Warden's stats.
static func speed_bonus(tower: Tower) -> float:
	var bonus := 0.0
	var dreams := tower._dream_state
	if dreams == null:
		return 0.0
	if tower._has_rule(&"momentum"):
		var step: Vector2 = dreams.momentum_step()
		var streak := minf(step.x * tower._grove.get(&"streak", 0), step.y)
		# The fade (Grove card council 2026-10-20): a switch drains the old bonus over MOMENTUM_FADE s while the new streak builds
		var left := 1.0 - (tower._anim_time - float(tower._grove.get(&"fade_at", -INF))) / MOMENTUM_FADE
		bonus += maxf(streak, float(tower._grove.get(&"fade_from", 0.0)) * clampf(left, 0.0, 1.0))
	if tower._has_rule(&"quickening") and tower._grove.get(&"quick_until", -1.0) > tower._anim_time:
		if dreams.rule_level(&"quickening") > 0:  # Hunt's Rush II: the rush builds with each dispel while it runs
			var n := int(tower._grove.get(&"quick_n", 1))
			bonus += minf(DreamState.QUICKENING_SPEED + DreamState.QUICKENING_STEP_II * (n - 1), DreamState.QUICKENING_MAX_II)
		else:
			bonus += DreamState.QUICKENING_SPEED
	return bonus

# Momentum's fade: seconds the old bonus takes to drain after a switch (a kill too), so a stream never drops it to nothing at once.
const MOMENTUM_FADE := 1.0

# A single-target hit on `enemy`: the Momentum streak goes on, or starts over on a new nightmare (the old bonus fades).
static func note_hit(tower: Tower, enemy: Node2D) -> void:
	var id := enemy.get_instance_id()
	if tower._grove.get(&"streak_on", 0) == id:
		tower._grove[&"streak"] = int(tower._grove.get(&"streak", 0)) + 1
	else:
		if tower._dream_state != null and tower._has_rule(&"momentum") and int(tower._grove.get(&"streak", 0)) > 0:
			var step: Vector2 = tower._dream_state.momentum_step()
			var left := 1.0 - (tower._anim_time - float(tower._grove.get(&"fade_at", -INF))) / MOMENTUM_FADE
			var now_bonus := maxf(minf(step.x * tower._grove.get(&"streak", 0), step.y), float(tower._grove.get(&"fade_from", 0.0)) * clampf(left, 0.0, 1.0))
			tower._grove[&"fade_from"] = now_bonus
			tower._grove[&"fade_at"] = tower._anim_time
		tower._grove[&"streak_on"] = id
		tower._grove[&"streak"] = 1

# Quickening: a nightmare dispelled in range gives every Warden reaching it +30% for 4 s.
static func quicken_near(tree: SceneTree, at: Vector2) -> void:
	for tower in tree.get_nodes_in_group(Tower.GROUP):
		if tower is Tower and tower.tower_data.can_attack and tower._has_rule(&"quickening") \
				and tower.global_position.distance_to(at) <= tower.get_range_pixels():
			var deep: bool = tower._dream_state != null and tower._dream_state.rule_level(&"quickening") > 0
			if deep and float(tower._grove.get(&"quick_until", -1.0)) > tower._anim_time:
				tower._grove[&"quick_n"] = int(tower._grove.get(&"quick_n", 1)) + 1  # Hunt's Rush II: one more dispel in the rush
			else:
				tower._grove[&"quick_n"] = 1
			tower._grove[&"quick_until"] = tower._anim_time + (DreamState.QUICKENING_TIME_II if deep else DreamState.QUICKENING_TIME)

# Hummingheart: damage from the Warden's bonus attack speed (its speed over its data's).
static func hummingheart(tower: Tower, speed: float) -> float:
	if tower._dream_state == null or not tower._has_rule(&"hummingheart") or tower.attack_data.attacks_per_second <= 0.0:
		return 0.0
	return tower._dream_state.hummingheart_bonus(speed / tower.attack_data.attacks_per_second - 1.0)

# Whirlwind Heart: the bonus part of an attack speed multiplier counts double (the base doesn't).
static func whirlwind(tower: Tower, multiplier: float) -> float:
	if tower._dream_state == null or multiplier <= 1.0:
		return multiplier
	return 1.0 + (multiplier - 1.0) * tower._dream_state.attack_speed_bonus_factor()

# --- Wide Reach ---------------------------------------------------------------------------------------

# An area attack went off at `where` with `radius` px for `share` of a hit: Lingering Splash's patch
# every Nth, Great Ripple's aftershock a second later (never from an aftershock). `splash` (section 37): the origin was a
# splash, so the aftershock follows it: damage only (a pulse's aftershock keeps its status).
static func area_attack(tower: Tower, where: Vector2, radius: float, share: float, splash: bool = false) -> void:
	var dreams := tower._dream_state
	if dreams == null or tower._grove.get(&"rippling", false):
		return
	var every: int = dreams.lingering_splash_every()
	if every > 0:
		tower._grove[&"areas"] = int(tower._grove.get(&"areas", 0)) + 1
		# With Hailfall (section 37), one live patch per Warden at a time: every Warden splashes then.
		var live_patch = tower._grove.get(&"patch")
		var held: bool = tower._has_rule(Tower.HAILFALL) and live_patch is WeakRef and is_instance_valid(live_patch.get_ref())
		if tower._grove[&"areas"] % every == 0 and not held:
			var patch := LingeringPatch.new(tower, tower.get_damage() * share * DreamState.LINGERING_SPLASH_SHARE)
			var world := Reactions._world(tower)
			if world != null:
				world.add_child(patch)
				patch.global_position = where
				tower._grove[&"patch"] = weakref(patch)
	if tower._has_rule(&"great_ripple"):
		var wider := radius + DreamState.GREAT_RIPPLE_WIDER * Tower.MAP_GRID.cell_size.x
		var ripple: Node2D = null
		var world := Reactions._world(tower)
		if world != null:
			ripple = RIPPLE_EFFECT.play(wider, DreamState.GREAT_RIPPLE_DELAY, where, world)
		tower.get_tree().create_timer(DreamState.GREAT_RIPPLE_DELAY, false).timeout.connect(func() -> void:
			if not is_instance_valid(tower) or tower.is_queued_for_deletion():
				if is_instance_valid(ripple):
					ripple.queue_free()
				return
			if is_instance_valid(ripple):
				ripple.release()
			tower._grove[&"rippling"] = true  # The aftershock never sets off another
			for enemy in tower.get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
				if enemy.global_position.distance_to(where) <= wider:
					tower.hit(enemy, share * DreamState.GREAT_RIPPLE_SHARE, true, Tower.NO_CRIT, &"great_ripple", true, -1, not splash)
			tower._grove[&"rippling"] = false)

# Spillover: an area hit that dispelled `enemy` splashes the `leftover` damage onto nightmares within
# 1 cell (never off its own splash).
static func spillover(tower: Tower, enemy: Node2D, leftover: float) -> void:
	if leftover <= 0.0:
		return
	var reach := DreamState.SPILLOVER_CELLS * Tower.MAP_GRID.cell_size.x
	var at: Vector2 = enemy.global_position
	var shown := false
	for other in Tower.nightmares_near(tower.get_tree(), at, reach):
		if other != enemy and not other.is_cleansed and other.global_position.distance_to(at) <= reach:
			if not shown:
				DREAM_BURST.play(&"spillover", at, reach, Reactions._world(tower))
				shown = true
			other.take_damage(leftover, tower.tower_data.line, true, false, tower, &"spillover")
			tower.spatter(other, true)  # Spattered: a card's splash gives 1 stack (section 37)

# Lingering Splash's patch: 1 cell, LINGERING_SPLASH_TIME s, `per_second` effect damage to what's inside.
class LingeringPatch extends Node2D:
	const TICK := 0.5
	var _tower: Tower
	var _per_second: float
	var _duration: float = DreamState.LINGERING_SPLASH_TIME
	var _age := 0.0
	var _tick := 0.0

	func _init(tower: Tower, per_second: float) -> void:
		_tower = tower
		_per_second = per_second
		_duration = ShapeCards.ground_time(DreamState.LINGERING_SPLASH_TIME)  # Lingering Ground: x1.5
		top_level = true
		z_index = -1  # On the ground

	func _process(delta: float) -> void:
		_age += delta
		_tick += delta
		if _age >= _duration or not is_instance_valid(_tower):
			queue_free()
			return
		while _tick >= TICK:
			_tick -= TICK
			var reach := Tower.MAP_GRID.cell_size.x * 0.5
			for enemy in Tower.nightmares_near(get_tree(), global_position, reach):
				if not enemy.is_cleansed and enemy.global_position.distance_to(global_position) <= reach:
					enemy.take_damage(_per_second * TICK, _tower.tower_data.line, true, false, _tower, &"lingering_splash")
		queue_redraw()

	func _draw() -> void:
		var fade := 1.0 - _age / _duration
		draw_circle(Vector2.ZERO, Tower.MAP_GRID.cell_size.x * 0.5, Color(Palette.DEADWOOD, 0.25 * fade))

# Quickening listens to dispels once per run scene (Tower._ready asks; cheap after the first).
static var _listening := 0  # The EnemyContainer it's connected to (instance id)
static var _listening_log := 0  # The DamageLog Shared Light listens to (instance id)

static func listen(tower: Tower) -> void:
	var spawner: Node = tower._dream_state.get_node_or_null("%EnemyContainer") if tower._dream_state else null
	if spawner == null or not spawner.has_signal("enemy_cleansed") or _listening == spawner.get_instance_id():
		return
	_listening = spawner.get_instance_id()
	var dreams := tower._dream_state
	spawner.enemy_cleansed.connect(func(enemy: Node2D) -> void:
		if is_instance_valid(dreams) and dreams.has_rule(&"quickening") and is_instance_valid(enemy):
			quicken_near(enemy.get_tree(), enemy.global_position))
	var log: Node = dreams.get_node_or_null("%DamageLog")
	if log != null and log.has_signal("damage_dealt") and _listening_log != log.get_instance_id():
		_listening_log = log.get_instance_id()
		log.damage_dealt.connect(_on_damage.bind(dreams))

# Shared Light's trigger: a plain hit by a Warden that left the nightmare at 0 health.
static func _on_damage(event, dreams) -> void:
	if not is_instance_valid(dreams) or not dreams.has_rule(&"shared_light") or event.kind != &"hit" or event.tag != &"":
		return
	if is_instance_valid(event.source) and event.source is Tower and is_instance_valid(event.enemy) and event.enemy.health <= 0:
		share_light(event.source)

# Shared Light (reworked, Grove card council 2026-10-20; was +4% per touching Warden, near-flat): a Warden's hit that
# dispels a nightmare gives every attacking Warden touching it +SHARED_LIGHT_BONUS damage for SHARED_LIGHT_TIME s (no stacking).
static func share_light(killer: Tower) -> void:
	var reach := Tower.MAP_GRID.cell_size.x + 1.0  # Touching: the 8 around, on both axes
	for tower in killer.get_tree().get_nodes_in_group(Tower.GROUP):
		if not (tower is Tower) or tower == killer or not tower.tower_data.can_attack or tower.is_queued_for_deletion():
			continue
		var d: Vector2 = (tower.global_position - killer.global_position).abs()
		if d.x <= reach and d.y <= reach:
			tower._grove[&"shared_until"] = tower._anim_time + DreamState.SHARED_LIGHT_TIME
			if tower._dream_state != null:
				tower._dream_state.note_card(&"shared_light", tower.global_position, 1, tower)

# Shared Light's damage multiplier for `tower`'s hits (1.0 when off).
static func shared_light_multiplier(tower) -> float:
	if not (tower is Tower) or not is_instance_valid(tower) or float(tower._grove.get(&"shared_until", -1.0)) <= tower._anim_time:
		return 1.0
	return 1.0 + DreamState.SHARED_LIGHT_BONUS
