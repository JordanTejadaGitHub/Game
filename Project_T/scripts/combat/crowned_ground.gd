extends Node2D
class_name CrownedGround

# Ground left by a Crowned Reaction (tower_design.md "Crowned Reactions", numbers in dream_design.md):
# - STILL_POOL: a pool on the drowned nightmare's tile; the first time each walker enters it, it
#   sleeps (bosses and nightmares that can't be held are slowed while inside instead).
# - NIGHTBLOOM: Mushrooming's cloud glowing violet; nothing inside can wake (sleep and full Drowsy
#   don't run out while inside; bosses keep full Drowsy).
# - FAIRY_RING: mushroom rings on path tiles; the first walker on each ring tile gets Spored + Damp.
# Script-only, drawn on the ground under the nightmares; the loops come from Fx.

enum Kind { STILL_POOL, NIGHTBLOOM, FAIRY_RING }

const TICK := 0.1
const POOL_BOSS_SLOW := 0.3
const RING_STACKS := 2
const RING_LIFETIME_MAX := 60.0  # Ring of Rings: rings stay until stepped on, but not forever

var kind: Kind
var _cells: Array[Vector2] = []  # STILL_POOL / FAIRY_RING tiles
var _radius := 0.0  # NIGHTBLOOM, pixels
var _duration := 0.0
var _age := 0.0
var _tick := 0.0
var sleep_seconds := 1.0  # STILL_POOL: sleep on first entry (Deep Stillness: 1.5)
var until_stepped := false  # FAIRY_RING: Ring of Rings
var potency := 0.0  # FAIRY_RING: the Spored it gives, credited to…
var line := ""
var source: Node = null  # …this Warden
var chain := 1
var _visited := {}  # STILL_POOL: nightmare instance id -> true
var _effects := {}  # FAIRY_RING: cell -> its loop, freed when used

func _init(ground_kind: Kind, cells: Array[Vector2], duration: float, at: Vector2 = Vector2.ZERO,
		radius: float = 0.0) -> void:
	kind = ground_kind
	_cells = cells
	_duration = duration
	_radius = radius
	position = at
	z_index = -1  # Under the nightmares

func _ready() -> void:
	match kind:
		Kind.STILL_POOL:
			for cell in _cells:
				Fx.play(&"still_pool", _local(cell), self, 1.0, true, _duration)
		Kind.NIGHTBLOOM:
			Fx.play(&"nightbloom_cloud", global_position, self, maxf(_radius / 32.0, 1.0), true, _duration)
		Kind.FAIRY_RING:
			var life := RING_LIFETIME_MAX if until_stepped else _duration
			for cell in _cells:
				_effects[cell] = Fx.play(&"fairy_circle_ring", _local(cell), self, 1.0, true, life)

func _local(cell: Vector2) -> Vector2:
	return Tower.MAP_GRID.calculate_map_position(cell)

func _process(delta: float) -> void:
	_age += delta
	var life := RING_LIFETIME_MAX if kind == Kind.FAIRY_RING and until_stepped else _duration
	if _age >= life or (kind == Kind.FAIRY_RING and _cells.is_empty()):
		queue_free()
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = TICK
	for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		if not is_instance_valid(enemy) or enemy.is_cleansed:
			continue
		if kind != Kind.NIGHTBLOOM and enemy.is_flying():
			continue  # The pool and the rings are on the ground: flyers pass over (Nightbloom is a cloud)
		match kind:
			Kind.STILL_POOL:
				_pool(enemy)
			Kind.NIGHTBLOOM:
				_nightbloom(enemy)
			Kind.FAIRY_RING:
				_ring(enemy)

func _pool(enemy: Node2D) -> void:
	if not _cells.has(enemy.get_current_cell()):
		return
	var s: EnemyStatuses = enemy.statuses
	if s.is_boss or Reactions.cant_be_held(enemy):
		s.slow_time = maxf(s.slow_time, TICK * 1.6)
		s.slow_amount = maxf(s.slow_amount, POOL_BOSS_SLOW)
		return
	var id := enemy.get_instance_id()
	if _visited.has(id):
		return
	_visited[id] = true
	s.sleep_time = maxf(s.sleep_time, sleep_seconds)

func _nightbloom(enemy: Node2D) -> void:
	if enemy.global_position.distance_to(global_position) > _radius:
		return
	var s: EnemyStatuses = enemy.statuses
	var full := s.has(EnemyStatuses.DROWSY) and s.stacks(EnemyStatuses.DROWSY) >= s.get_max_stacks(EnemyStatuses.DROWSY)
	if full:
		s.apply(EnemyStatuses.DROWSY, 1)  # Refreshes it; it can't run out in here
	if not s.is_boss and s.is_asleep():
		s.sleep_time = maxf(s.sleep_time, TICK * 2.0)

func _ring(enemy: Node2D) -> void:
	var cell: Vector2 = enemy.get_current_cell()
	if not _cells.has(cell):
		return
	_cells.erase(cell)
	var effect = _effects.get(cell)
	if is_instance_valid(effect):
		effect.queue_free()
	_effects.erase(cell)
	Reactions._touch(enemy, chain, [source] if is_instance_valid(source) else [])
	enemy.apply_status(EnemyStatuses.SPORED, RING_STACKS, 0.0, potency, 0, line,
		source if is_instance_valid(source) else null)
	if is_instance_valid(enemy) and not enemy.is_cleansed:
		enemy.apply_status(EnemyStatuses.DAMP, 1, 0.0, 0.0, 0, "water", source if is_instance_valid(source) else null)
