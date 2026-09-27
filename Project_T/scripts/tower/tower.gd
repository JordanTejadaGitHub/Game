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
# A Puffball popped `enemy`'s `stacks` Spored stacks (sound, and the "Popped!" callout).
signal popped(tower: Tower, enemy: Node2D, stacks: int)
# A beam (Sunpetal line) hit its target; `ramp` is its current damage multiplier.
signal beam_ticked(tower: Tower, ramp: float)

@export var tower_data: TowerData
@onready var sprite: Sprite2D = $Sprite2D

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const ENEMY_GROUP := "enemies"
const SPORE_POTENCY := 0.25  # Spored soothes this share of the Warden's soothe per second per stack
const CHAIN_DAMP_EXTRA_JUMPS := 2
const CHAIN_DAMP_EXTRA_RANGE := 1.0  # Cells
const POP_SPREAD_RANGE := 1.5  # Cells: how far a Puffball pop's spores drift on
const BEAM_TICK := 0.25  # Seconds between beam hits
const BEAM_RAMP_FAST := 2.0  # Beams ramp this much faster on Drowsy or Held nightmares
const AURA_TICK := 0.25  # Seconds between aura refreshes (White Stag)
const AURA_PULSE_EVERY := 2.5  # Seconds between the White Stag's pulse animations
const NEIGHBOUR_REFRESH := 0.5  # Seconds between looks at neighbouring Wardens (copy, auras)
const TONGUE_COLOR := Color(0.95, 0.55, 0.6)
const WIND_COLOR := Color(0.85, 0.95, 1.0)
const LIGHT_COLOR := Color(1.0, 0.9, 0.5)
# Nurture ranks (warden_stats.md "Nurture v2"). Costs are base × tier multiplier (at purchase) × Dreams.
const RANK_MAX := 5  # Without Dreams (Deeper Rings: VII)
const RANK_COSTS: Array[int] = [15, 25, 40, 60, 90]  # Base Dew for ranks I-V
const RANK_DAMAGE := 0.10
const RANK_SPEED := 0.04
const RANK_RANGE := 0.1  # Cells
const RANK_NAMES: Array[String] = ["", "I", "II", "III", "IV", "V", "VI", "VII"]
const FOCUS_RANK := 3  # The rank that asks for a Focus; its bonus counts from here on
enum Focus { NONE, POWER, SWIFT, REACH, DEEP }
const FOCUS_NAMES := {Focus.POWER: "Power", Focus.SWIFT: "Swift", Focus.REACH: "Reach", Focus.DEEP: "Deep"}
const FOCUS_TEXT := {Focus.POWER: "+8% damage", Focus.SWIFT: "+6% attack speed", Focus.REACH: "+0.2 range",
	Focus.DEEP: "+10% status strength and duration"}
const FOCUS_COLORS := {Focus.POWER: Color(1.0, 0.5, 0.35), Focus.SWIFT: Color(0.6, 1.0, 0.55),
	Focus.REACH: Color(0.55, 0.8, 1.0), Focus.DEEP: Color(0.8, 0.6, 1.0)}
const FOCUS_POWER := 0.08
const FOCUS_SWIFT := 0.06
const FOCUS_REACH := 0.2
const FOCUS_DEEP := 0.10
const PIP_COLOR := Color(1.0, 0.85, 0.45)
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
# What the attack does: `tower_data` itself, or for a Graftling the neighbour it copies.
var attack_data: TowerData
# Who snipers shoot at (the player can change it in the Warden panel).
var target_mode: TowerData.TargetMode = TowerData.TargetMode.FIRST

var _cooldown := 0.0  # Seconds until the tower can attack again
var _anim_time := 0.0
var _attack_time := -1.0  # Seconds into the attack animation; negative while idling
var _attack_fps := 0.0
var _released := false  # The current attack's shot / pulse has happened
var _attack_count := 0  # For "every Nth attack" effects (Thunderhead)
var _damage_share := 1.0  # Graftling: share of the copied Warden's damage
var _dream_state: DreamState
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
var _lit_cells: Array[Vector2] = []  # Rootlight: path tiles it lights
var _crit_dew_drift := -1  # Magpie's Hoard: drift the crit-Dew count belongs to
var _crit_dew_given := 0

func _ready() -> void:
	_dream_state = get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	_apply_data()
	# Start each tower at a random point in its idle loop so neighbours don't breathe in sync.
	_anim_time = randf() * tower_data.frame_count / tower_data.animation_fps

func _apply_data() -> void:
	attack_data = tower_data
	_damage_share = 1.0
	if not tower_data.has_target_priority:
		target_mode = tower_data.target_mode
	_attack_time = -1.0
	_stop_beam()
	_show_idle()
	_refresh_neighbours()
	queue_redraw()

# Grows into `data` in place (the cell and path don't change). `cost` is added to invested Dew.
func evolve(data: TowerData, cost: int) -> void:
	tower_data = data
	invested_dew += cost
	_apply_data()
	evolved.emit(self)

func _process(delta: float) -> void:
	_anim_time += delta
	_neighbour_timer -= delta
	if _neighbour_timer <= 0.0:
		_refresh_neighbours()
	if _attack_time >= 0.0:
		_advance_attack(delta)
	elif _beam_target == null:
		sprite.frame = int(_anim_time * tower_data.animation_fps) % tower_data.frame_count
	if rank > 0:
		var art_frame := int(_anim_time * tower_data.animation_fps) % 8
		for art in [get_node_or_null("RankUnder"), get_node_or_null("RankOver")]:
			if art:
				art.frame = art_frame
	if not tower_data.can_attack:
		return
	match attack_data.attack_kind:
		TowerData.AttackKind.AURA:
			_update_aura(delta)
			return
		TowerData.AttackKind.BEAM:
			_update_beam(delta)
			return
		TowerData.AttackKind.COPY:
			return  # A Graftling with nothing to copy
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown > 0.0 or _attack_time >= 0.0 or not _has_work():
		return
	_start_attack()

# Whether an attack now would do anything.
func _has_work() -> bool:
	match attack_data.attack_kind:
		TowerData.AttackKind.TRAP:
			_rings = _rings.filter(func(r: FairyRing) -> bool: return is_instance_valid(r) and not r.is_spent())
			return _rings.size() < attack_data.trap_max and not _free_trap_cells().is_empty()
		TowerData.AttackKind.SPIN:
			return not _enemies_on_adjacent_tiles().is_empty()
	return find_target() != null


# --- Effective stats (base × Dreams) ----------------------------------------------------------------

func get_damage() -> float:
	return attack_data.damage * _damage_share * get_rank_damage_multiplier() \
		* (_dream_state.get_soothe_multiplier(self) if _dream_state else 1.0)

func get_attacks_per_second() -> float:
	var ranks := get_effective_rank()
	var speed := 1.0 + RANK_SPEED * ranks + (FOCUS_SWIFT * _focus_ranks(ranks) if focus == Focus.SWIFT else 0.0)
	var dreams := 1.0
	if _dream_state:
		dreams = _dream_state.get_attack_speed_multiplier(tower_data)
		if _dream_state.has_method("get_tower_attack_speed_bonus"):
			dreams += _dream_state.get_tower_attack_speed_bonus(self)  # Sprout Chorus, The Last Light
	return attack_data.attacks_per_second * speed * dreams

func get_range_cells() -> float:
	var ranks := get_effective_rank()
	var reach := RANK_RANGE * ranks + (FOCUS_REACH * _focus_ranks(ranks) if focus == Focus.REACH else 0.0)
	if _dream_state and _dream_state.has_method("get_tower_range_bonus"):
		reach += _dream_state.get_tower_range_bonus(self)  # Solitude
	return get_range_for(attack_data, _dream_state) + _aura_range + reach


# --- Nurture ranks -------------------------------------------------------------------------------------

# The rank that counts for stats (The Old Ones can lift it by one next to a rank V+ Warden).
func get_effective_rank() -> int:
	if _dream_state and _dream_state.has_method("get_effective_rank"):
		return _dream_state.get_effective_rank(self)
	return rank

# Ranks from III up (the ones that carry the Focus bonus).
static func _focus_ranks(ranks: int) -> int:
	return maxi(ranks - FOCUS_RANK + 1, 0)

# Damage multiplier from ranks: +10% each (+ Warm Hands), + Power's +8% from rank III.
func get_rank_damage_multiplier() -> float:
	var ranks := get_effective_rank()
	var per_rank := RANK_DAMAGE
	if _dream_state and _dream_state.has_method("get_rank_damage_bonus"):
		per_rank += _dream_state.get_rank_damage_bonus()
	return 1.0 + per_rank * ranks + (FOCUS_POWER * _focus_ranks(ranks) if focus == Focus.POWER else 0.0)

# Deep Focus: status strength and duration multiplier.
func get_status_focus_multiplier() -> float:
	return 1.0 + FOCUS_DEEP * _focus_ranks(get_effective_rank()) if focus == Focus.DEEP else 1.0

func get_max_rank() -> int:
	if _dream_state and _dream_state.has_method("get_max_rank"):
		return _dream_state.get_max_rank()
	return RANK_MAX

# Attacking Wardens can be nurtured (not walls or wall growths, not the White Stag's aura).
func can_be_nurtured() -> bool:
	return tower_data.can_attack and tower_data.line != "wall" \
		and tower_data.attack_kind != TowerData.AttackKind.AURA

func can_nurture() -> bool:
	return can_be_nurtured() and rank < get_max_rank()

# The next rank asks for a Focus first (rank II -> III, no Focus yet).
func needs_focus() -> bool:
	return can_nurture() and rank + 1 >= FOCUS_RANK and focus == Focus.NONE

# Cost multiplier from the Warden's tier right now: Sprout ×0.5, base ×1, branch ×2, final ×3,
# Memory Warden ×2.
func get_tier_cost_multiplier() -> float:
	if tower_data.is_unique:
		return 2.0
	match tower_data.tier:
		0:
			return 0.5
		1:
			return 1.0
		2:
			return 2.0
	return 3.0

# Dew for the next rank (0 when it can't be nurtured further).
func get_nurture_cost() -> int:
	if not can_nurture():
		return 0
	var next := rank + 1
	var base: float = RANK_COSTS[rank] if rank < RANK_COSTS.size() else 0.0
	if next > RANK_COSTS.size() and _dream_state and _dream_state.has_method("get_extra_rank_cost"):
		base = _dream_state.get_extra_rank_cost(next)  # Deeper Rings: VI and VII
	var multiplier := get_tier_cost_multiplier()
	if _dream_state and _dream_state.has_method("get_nurture_cost_multiplier"):
		multiplier *= _dream_state.get_nurture_cost_multiplier()
	return maxi(roundi(base * multiplier), 1)

# Raises the rank by one; `cost` is added to invested Dew (TowerPlacer.nurture charges it).
# `chosen` sets the Focus when this is the rank that asks for one.
func nurture(cost: int, chosen: Focus = Focus.NONE) -> void:
	if focus == Focus.NONE and chosen != Focus.NONE:
		focus = chosen
	rank = mini(rank + 1, get_max_rank())
	invested_dew += cost
	_play_rank_up()
	queue_redraw()
	nurtured.emit(self)

# The rank's slab art: a halo under the sprite, and a looping overlay on the slab's rim over it.
func _update_rank_art() -> void:
	var under := get_node_or_null("RankUnder") as Sprite2D
	var over := get_node_or_null("RankOver") as Sprite2D
	var art_rank := mini(rank, 7)
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
	return attack_data.splash_radius * (_dream_state.get_splash_multiplier(tower_data) if _dream_state else 1.0)

func get_crit_chance(enemy: Node2D = null) -> float:
	var chance := attack_data.crit_chance + _aura_crit
	if _dream_state and _dream_state.has_method("get_rank_crit_bonus"):
		chance += _dream_state.get_rank_crit_bonus() * get_effective_rank()  # The Old Ones
	if enemy != null and enemy.statuses.is_held():
		chance += attack_data.crit_bonus_vs_held
	return minf(chance, 1.0)

# Range in cells for `data` including Dreams (shared with the build ghost).
static func get_range_for(data: TowerData, dream_state: DreamState) -> float:
	return data.attack_range + (dream_state.get_range_bonus(data) if dream_state else 0.0)


# --- Neighbours and auras -----------------------------------------------------------------------------

# Other Wardens on the map (the tower's siblings).
func _other_towers() -> Array:
	if get_parent() == null:
		return []
	return get_parent().get_children().filter(func(t: Node) -> bool:
		return t is Tower and t != self and not t.is_queued_for_deletion())

# Refreshes what depends on nearby Wardens: the copied attack (Graftling) and aura bonuses.
func _refresh_neighbours() -> void:
	_neighbour_timer = NEIGHBOUR_REFRESH
	_aura_crit = 0.0
	_aura_range = 0.0
	var best: Tower = null
	var best_dps := 0.0
	for other in _other_towers():
		var distance: float = other.global_position.distance_to(global_position) / MAP_GRID.cell_size.x
		var data: TowerData = other.tower_data
		if data.aura_crit_bonus > 0.0 and distance <= data.attack_range:
			_aura_crit = maxf(_aura_crit, data.aura_crit_bonus)  # Auras don't stack with themselves
		if data.range_aura_bonus > 0.0 and distance <= data.range_aura_radius:
			_aura_range = maxf(_aura_range, data.range_aura_bonus)
		if tower_data.attack_kind == TowerData.AttackKind.COPY and _can_copy(other) \
				and absf(other.cell.x - cell.x) <= 1 and absf(other.cell.y - cell.y) <= 1:
			var dps: float = other.get_damage() * other.get_attacks_per_second()
			if dps > best_dps:
				best_dps = dps
				best = other
	if tower_data.attack_kind != TowerData.AttackKind.COPY:
		return
	var copied: TowerData = best.tower_data if best != null else tower_data
	if copied != attack_data:
		_stop_beam()
		attack_data = copied
	_damage_share = tower_data.copy_share if best != null else 1.0

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
	_cooldown = 1.0 / get_attacks_per_second()
	if tower_data.attack_texture == null:
		_release()
		return
	# Play the attack faster if it wouldn't finish before the next one is due.
	_attack_fps = maxf(tower_data.attack_animation_fps, tower_data.attack_frame_count * get_attacks_per_second())
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
		_release()
	if frame >= tower_data.attack_frame_count:
		_attack_time = -1.0
		_show_idle()
		return
	sprite.frame = frame

func _show_idle() -> void:
	sprite.texture = tower_data.texture
	sprite.hframes = tower_data.frame_count
	sprite.frame = int(_anim_time * tower_data.animation_fps) % tower_data.frame_count

# Holds the attack pose (the release frame) while beaming.
func _show_attack_pose() -> void:
	if tower_data.attack_texture == null:
		return
	sprite.texture = tower_data.attack_texture
	sprite.hframes = tower_data.attack_frame_count
	sprite.frame = tower_data.attack_release_frame

# The attack lands. A target that left range during the wind-up wastes a projectile/chain/cloud.
func _release() -> void:
	_attack_count += 1
	attack_released.emit(self)
	match attack_data.attack_kind:
		TowerData.AttackKind.PULSE:
			for enemy in get_enemies_in_range():
				hit(enemy, 1.0, true)
				_push(enemy)
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
		TowerData.AttackKind.SWEEP:
			_sweep()
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
			var target := find_target()
			if target != null:
				fire_at(target)

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
	if attack_data.dew_mark:
		enemy.bonus_dew = maxi(enemy.bonus_dew, 1)  # Before the hit, so a dispelling hit counts
	var soothe := get_damage() * soothe_multiplier * _damage_against(enemy)
	# Reactions that change a hit: Pinned (a guaranteed ×3 crit) and Shatter (×2.5, shards).
	var reaction := Reactions.before_hit(enemy, self, is_crit)
	is_crit = reaction.crit
	var dealt: float = soothe * (reaction.crit_multiplier if is_crit else 1.0) * reaction.multiplier
	if reaction.tag != &"":
		combo = reaction.tag
	enemy.take_damage(dealt, tower_data.line, is_area, is_crit, self, combo)
	if reaction.shatter:
		Reactions.shatter_splash(enemy, self, dealt)
	hit_landed.emit(self, enemy, is_area, is_crit)
	apply_status_to(enemy, soothe)
	_after_hit(enemy, is_crit)
	if is_crit:
		crit_landed.emit(self, enemy)
	if attack_data.pop_at_stacks > 0 and is_instance_valid(enemy) and not enemy.is_cleansed \
			and enemy.statuses.stacks(EnemyStatuses.SPORED) >= attack_data.pop_at_stacks:
		pop(enemy)
	return is_crit

# Puffball: `enemy`'s Spored stacks burst. Pop damage (6 × stacks, Dreams included) hits it and every
# nightmare within pop_radius as an area spore hit that never crits, logged as a "popped" combo.
# Its stacks are used up and half of them drift on to the nearest few nightmares, still credited to
# the Warden that applied them. With the Chain Bloom rule, a nightmare those spores bring to the
# threshold pops too (each nightmare at most once per chain).
func pop(enemy: Node2D, chain: Dictionary = {}) -> void:
	var statuses: EnemyStatuses = enemy.statuses
	var stacks := statuses.stacks(EnemyStatuses.SPORED)
	if stacks <= 0 or chain.has(enemy.get_instance_id()):
		return
	chain[enemy.get_instance_id()] = true
	var potency := statuses.potency(EnemyStatuses.SPORED)
	var duration := statuses.time_left(EnemyStatuses.SPORED)
	var line := statuses.spore_line()
	var applier := statuses.source(EnemyStatuses.SPORED)
	statuses.remove(EnemyStatuses.SPORED)
	var at := enemy.global_position
	var damage := attack_data.pop_damage_per_stack * stacks * get_rank_damage_multiplier() \
		* (_dream_state.get_soothe_multiplier(self) if _dream_state else 1.0)
	var reach := attack_data.pop_radius * MAP_GRID.cell_size.x
	for other in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if other.global_position.distance_to(at) <= reach:
			other.take_damage(damage, tower_data.line, true, false, self, &"popped")
	# Final-form signature: a big bloom of light (the plain burst without the effects player).
	if Reactions._effect(&"puffball_bloom", at, self) == null:
		add_child(SporePop.new(at, reach))
	popped.emit(self, enemy, stacks)

	# Half the spores drift on to the nearest nightmares (not back onto the one that popped).
	var spread := stacks / 2
	if spread <= 0:
		return
	var others := get_tree().get_nodes_in_group(ENEMY_GROUP).filter(func(e: Node2D) -> bool:
		return e != enemy and e.global_position.distance_to(at) <= POP_SPREAD_RANGE * MAP_GRID.cell_size.x)
	others.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
	var chain_bloom := _dream_state != null and _dream_state.has_rule(&"chain_bloom")
	for i in mini(attack_data.pop_spread_targets, others.size()):
		var other: Node2D = others[i]
		other.apply_status(EnemyStatuses.SPORED, spread, duration, potency, attack_data.status_max_stacks,
			line, applier)
		if chain_bloom and is_instance_valid(other) and not other.is_cleansed \
				and other.statuses.stacks(EnemyStatuses.SPORED) >= attack_data.pop_at_stacks:
			pop(other, chain)

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
	return multiplier

# On-hit rules: freeze (Frostfern), Dew from crits (Magpie's Hoard).
func _after_hit(enemy: Node2D, is_crit: bool) -> void:
	if attack_data.freeze_duration > 0.0 and enemy.freeze_cooldown <= 0.0 and not enemy.is_cleansed \
			and (attack_data.freeze_needs == &"" or enemy.statuses.has(attack_data.freeze_needs)):
		enemy.freeze_cooldown = attack_data.freeze_cooldown
		enemy.apply_status(EnemyStatuses.HELD, 1, attack_data.freeze_duration)
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
	var status := attack_data.applies_status
	if status == &"" or not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	var potency := soothe
	if status == EnemyStatuses.SPORED:
		potency = soothe * SPORE_POTENCY
	elif status == EnemyStatuses.DAMP:
		potency = 1.0  # Damp's potency is its slow strength, not soothe
	var duration := attack_data.status_duration
	var max_stacks := attack_data.status_max_stacks
	if _dream_state:
		potency *= _dream_state.get_status_strength_multiplier(status)
		duration = _dream_state.get_status_duration(attack_data, status)
		max_stacks = _dream_state.get_status_max_stacks(attack_data, status)
	var deep := get_status_focus_multiplier()  # Deep Focus: stronger and longer
	if deep != 1.0:
		if duration <= 0.0:
			duration = EnemyStatuses.DEFAULT_DURATION[status]
		duration *= deep
		potency *= deep
	enemy.apply_status(status, attack_data.status_stacks, duration, potency, max_stacks, tower_data.line, self)

# Projectile landed at `where` (on `target` if it's still there): soothe it, or everything in the
# splash radius (the splash shares the main hit's crit roll).
func projectile_landed(target: Node2D, where: Vector2) -> void:
	var splash := get_splash_cells() * MAP_GRID.cell_size.x
	if splash <= 0.0:
		hit(target)
		return
	var crit := CRIT if target != null and roll_crit(target) else NO_CRIT
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if enemy.global_position.distance_to(where) <= splash:
			hit(enemy, 1.0, true, crit)

func fire_at(target: Node2D) -> void:
	var projectile := Projectile.new(target, attack_data, projectile_landed)
	add_child(projectile)
	projectile.global_position = global_position + tower_data.get_attack_origin()

# Whirligig: pulses nudge nightmares back a little (each at most once per push_cooldown).
func _push(enemy: Node2D) -> void:
	if attack_data.push_back_tiles <= 0.0 or not is_instance_valid(enemy) or enemy.is_cleansed \
			or enemy.push_cooldown > 0.0:
		return
	enemy.push_cooldown = attack_data.push_cooldown
	enemy.push_back(attack_data.push_back_tiles * MAP_GRID.cell_size.x)

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

	var storm := attack_data.storm_every > 0 and _attack_count % attack_data.storm_every == 0
	if storm:
		Reactions._effect(&"thunderhead_strike", first.global_position, self)  # Signature: a bolt from the sky
	if storm or (_dream_state and _dream_state.has_rule(&"conductive_soil")):
		for enemy in get_enemies_in_range():
			if enemy.statuses.has(EnemyStatuses.DAMP) and not hits.has(enemy):
				hits.append(enemy)

	# Jumps past the normal count only happened through Damp (DamageLog: "conducted").
	var points := PackedVector2Array([global_position + tower_data.get_attack_origin()])
	for i in hits.size():
		var enemy := hits[i]
		points.append(enemy.global_position)
		hit(enemy, 1.0, false, ROLL_CRIT, &"conducted" if i >= attack_data.chain_targets else &"")
	var bolt := ChainBolt.new(points)
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
	add_child(cloud)


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

# Starling Murmuration: the flock sweeps the stretch of `sweep_tiles` route tiles in range with the
# most nightmares on it, hitting all of them.
func _sweep() -> void:
	var route := _route()
	var counts := {}
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		var at: Vector2 = enemy.get_current_cell()
		counts[at] = counts.get(at, 0) + 1
	var best_start := -1
	var best_count := 0
	var size := attack_data.sweep_tiles
	for start in range(0, route.size() - size + 1):
		var count := 0
		var in_range := true
		for i in size:
			if not _is_cell_in_range(route[start + i]):
				in_range = false
				break
			count += counts.get(route[start + i], 0)
		if in_range and count > best_count:
			best_count = count
			best_start = start
	var stretch: Array[Vector2] = []
	if best_start >= 0:
		for i in size:
			stretch.append(route[best_start + i])
	else:
		# Short stretches in range (or a re-routed target): sweep around the target instead.
		var target := find_target()
		if target == null:
			return
		stretch.append(target.get_current_cell())
	var points := PackedVector2Array([global_position + tower_data.get_attack_origin()])
	for at in stretch:
		points.append(MAP_GRID.calculate_map_position(at))
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if stretch.has(enemy.get_current_cell()):
			hit(enemy, 1.0, true)
	add_child(FlockSweep.new(points, attack_data.projectile_texture, attack_data.projectile_frames))

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
	var reach := attack_data.spread_radius * MAP_GRID.cell_size.x
	var others := get_tree().get_nodes_in_group(ENEMY_GROUP).filter(func(e: Node2D) -> bool:
		return e != source and e.global_position.distance_to(source.global_position) <= reach)
	others.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.global_position.distance_squared_to(source.global_position) \
			< b.global_position.distance_squared_to(source.global_position))
	var copied: Array = source.statuses.snapshot()
	var points := PackedVector2Array()
	for i in mini(attack_data.spread_targets, others.size()):
		for status in copied:
			others[i].apply_status(status.id, maxi(ceili(status.stacks / 2.0), 1), status.time,
				status.potency, 0, status.line, status.source)
		points.append(source.global_position)
		points.append(others[i].global_position)
	for i in range(0, points.size(), 2):
		add_child(ChainBolt.new(PackedVector2Array([points[i], points[i + 1]]), WIND_COLOR, 3.0))

# Pinwheel: blades hit every nightmare on the 8 tiles around it, harder the more of those tiles are path.
func _spin() -> void:
	var path_tiles := 0
	var route := _route()
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if (dx != 0 or dy != 0) and route.has(cell + Vector2(dx, dy)):
				path_tiles += 1
	var bonus := clampf((path_tiles - attack_data.spin_free_path_tiles) * attack_data.spin_bonus,
		0.0, attack_data.spin_bonus_max)
	for enemy in _enemies_on_adjacent_tiles():
		hit(enemy, 1.0 + bonus, true)

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
		target.push_back(attack_data.pull_boss_tiles * MAP_GRID.cell_size.x)
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

# Rootlight: glowing roots light the path tiles in range; nightmares there are soothed and Marked.
func _light() -> void:
	_lit_cells.clear()
	for at in _route():
		if _is_cell_in_range(at):
			_lit_cells.append(at)
	queue_redraw()
	for enemy in get_enemies_in_range():
		hit(enemy, 1.0, true)

# Sunpetal: a beam on one target that ramps up the longer it holds (faster on Drowsy or Held).
func _update_beam(delta: float) -> void:
	var target := find_target()
	if target != _beam_target:
		_beam_ramp = 1.0
		_beam_tick = 0.0
		_beam_target = target
		if target == null:
			_stop_beam()
			return
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
		if is_instance_valid(_beam_behind):
			hit(_beam_behind, share * attack_data.beam_behind_share)
	if not is_instance_valid(_beam_target) or _beam_target.is_cleansed:
		_beam_target = null
	queue_redraw()

func _stop_beam() -> void:
	var was_beaming := _beam_target != null
	_beam_target = null
	_beam_behind = null
	_beam_ramp = 1.0
	if was_beaming and is_node_ready():
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
	for enemy in inside:
		enemy.statuses.set_in_stag_aura(AURA_TICK * 1.6)
	# Its pulse animation plays every few seconds while nightmares are inside.
	_cooldown = maxf(_cooldown - AURA_TICK, 0.0)
	if not inside.is_empty() and tower_data.attack_texture != null and _cooldown <= 0.0 and _attack_time < 0.0:
		_start_attack()
		_cooldown = AURA_PULSE_EVERY


# --- Drawing and targeting ------------------------------------------------------------------------------

func _draw() -> void:
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
			draw_line(from, to, Color(attack_data.beam_color, 0.35), width * 2.0)
			draw_line(from, to, Color(1.0, 1.0, 0.9, 0.9), maxf(width * 0.5, 1.5))
			from = to  # Midsummer's beam carries on from the target to the one behind it
	if attack_data != null and attack_data.attack_kind == TowerData.AttackKind.AURA:
		draw_arc(Vector2.ZERO, get_range_pixels(), 0.0, TAU, 64, Color(0.85, 0.9, 1.0, 0.12), 3.0)

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
			var step := 7.0 if rank <= 5 else 6.0
			var icon_space := 9.0 if focus != Focus.NONE else 0.0
			var left := -((rank - 1) * step + icon_space) / 2.0
			for i in rank:
				var at := Vector2(left + i * step, 27.0)
				pips.draw_circle(at, 3.2, Color(0.1, 0.08, 0.05, 0.85))
				pips.draw_circle(at, 2.2, PIP_COLOR)
			if focus != Focus.NONE:
				draw_focus_icon(pips, Vector2(left + (rank - 1) * step + icon_space, 27.0), focus))
		add_child(pips)
	pips.queue_redraw()

# A tiny Focus glyph: Power an upward flame, Swift a double chevron, Reach a ring, Deep a drop.
# Shared with the Warden panel.
static func draw_focus_icon(canvas: CanvasItem, at: Vector2, which: Focus, size: float = 1.0) -> void:
	var color: Color = FOCUS_COLORS.get(which, Color.WHITE)
	var dark := Color(0.1, 0.08, 0.05, 0.9)
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

# The nightmare in range this Warden should attack, or null. Most Wardens pick the one furthest
# along the path; snipers let the player choose, and Wren's Nest hunts the fastest.
func find_target() -> Node2D:
	var mode := target_mode if tower_data.has_target_priority else attack_data.target_mode
	var best: Node2D = null
	var best_score := -INF
	for enemy in get_enemies_in_range():
		var score: float = -enemy.get_remaining_distance()
		match mode:
			TowerData.TargetMode.STRONGEST:
				score = enemy.health
			TowerData.TargetMode.BOSSES:
				score = -enemy.get_remaining_distance() + (1e9 if enemy.enemy_data.is_boss else 0.0)
			TowerData.TargetMode.FASTEST:
				score = enemy.get_move_speed()
		if score > best_score:
			best_score = score
			best = enemy
	return best

# Blighted enemies within attack range (and outside a sniper's minimum range).
func get_enemies_in_range() -> Array[Node2D]:
	var range_squared := get_range_pixels() ** 2
	var min_squared := (attack_data.min_range * MAP_GRID.cell_size.x) ** 2
	var result: Array[Node2D] = []
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		var distance_squared := global_position.distance_squared_to(enemy.global_position)
		if distance_squared <= range_squared and distance_squared >= min_squared:
			result.append(enemy)
	return result

# Converts a range in cells to pixels. Shared with the build-mode ghost preview.
static func range_to_pixels(range_cells: float) -> float:
	return range_cells * MAP_GRID.cell_size.x

# Draws a simple stone block centred on the origin. Shared with the build-mode ghost preview.
static func draw_placeholder(canvas: CanvasItem, color: Color) -> void:
	var block := Rect2(-24, -24, 48, 48)
	canvas.draw_rect(block, color.darkened(0.45))
	canvas.draw_rect(block.grow(-4), color)
	canvas.draw_circle(Vector2.ZERO, 10, color.lightened(0.35))
