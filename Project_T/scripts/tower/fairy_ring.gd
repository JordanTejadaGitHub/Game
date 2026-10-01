extends Node2D
class_name FairyRing

# A mushroom ring planted on a path tile by a Fairy Ring / Elf Circle. The first walking nightmare
# to step onto its tile sets off a spore burst: the Warden hits every nightmare within
# `trap_radius` (one crit roll for the burst) and applies its Spored. Rings with a lifetime fade
# away unstepped; Elf Circle rings (lifetime 0) wait forever. Script-only node, a child of the
# Warden that planted it.

const SCALE := 2.0  # The 16x16 ring sprite drawn at 32x32 on the 64px tile
const ANIMATION_FPS := 6.0
const BURST_TIME := 0.3
const GROUP := &"fairy_rings"

var cell: Vector2
var _tower: Tower
var _data: TowerData
var _boost := 1.0
var _lifetime: float
var _age := 0.0
var _burst := -1.0  # Seconds into the burst effect; negative until triggered

# `data` / `strength`: a ring planted with another Warden's ring (Spore Nursery: a Driftspore's puff plants
# its Fairy Ring kin's ring, at the bond's share).
func _init(tower: Tower, at_cell: Vector2, data: TowerData = null, strength: float = 1.0) -> void:
	_tower = tower
	_data = data if data != null else tower.attack_data  # What it was made with (a legacy attack, a Graftling's copy)
	_boost = tower._hit_boost * strength  # Sudden Bloom / Watchful Rest
	cell = at_cell
	_lifetime = _data.trap_lifetime
	add_to_group(GROUP)
	top_level = true
	z_index = -1  # On the path (after the ground and path layers), under the y-sorted nightmares
	position = Tower.MAP_GRID.calculate_map_position(at_cell)

func is_spent() -> bool:
	return _burst >= 0.0 or is_queued_for_deletion()

func _process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _burst >= 0.0:
		_burst += delta
		if _burst >= BURST_TIME:
			queue_free()
		return
	if _lifetime > 0.0 and _age >= _lifetime:
		queue_free()
		return
	for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		if not enemy.is_flying() and enemy.get_current_cell() == cell:
			_set_off(enemy)
			return

# `stepper`: the nightmare that stepped on it (Elf Circle's Fairy dance counts it); null when set off
# by another ring (Ring Dance).
func _set_off(stepper: Node2D = null) -> void:
	_burst = 0.0
	if not is_instance_valid(_tower):
		return
	if stepper != null:
		FinalTwists.ring_stepped(_tower, stepper)
	_tower.trap_triggered.emit(_tower, global_position)
	var reach := _data.trap_radius * Tower.MAP_GRID.cell_size.x
	var caught: Array[Node2D] = []
	for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		if enemy.global_position.distance_to(global_position) <= reach:
			caught.append(enemy)
	var crit := _tower.roll_crit(caught[0]) if not caught.is_empty() else false
	_tower._area_count = caught.size()  # Crowd Breaker
	for enemy in caught:
		_tower.run_as(_data, _boost, func() -> void: _tower.hit(enemy, 1.0, true, Tower.CRIT if crit else Tower.NO_CRIT))
	# Ring Dance (Entwined Dream): the burst sets off every ring within RING_DANCE_TILES.
	var dreams := _tower._dream_state
	if dreams != null and dreams.has_rule(&"ring_dance"):
		var dance := DreamState.RING_DANCE_TILES * dreams.rule_power(&"ring_dance") * Tower.MAP_GRID.cell_size.x
		for ring in get_tree().get_nodes_in_group(GROUP):
			if ring != self and not ring.is_spent() and ring.global_position.distance_to(global_position) <= dance:
				ring._set_off()

func _draw() -> void:
	if _burst >= 0.0:
		var t := _burst / BURST_TIME
		var color := Color(Palette.NEWLEAF, 1.0 - t)
		draw_circle(Vector2.ZERO, 12.0 + 26.0 * t, Color(color, 0.35 * (1.0 - t)))
		for i in 8:
			var dir := Vector2.from_angle(TAU * i / 8.0)
			draw_circle(dir * (8.0 + 22.0 * t), 3.0, color)
		return
	var texture: Texture2D = _data.trap_texture if is_instance_valid(_tower) else null
	# Fade in when planted and out in the last second of a limited lifetime.
	var alpha := minf(_age / 0.3, 1.0)
	if _lifetime > 0.0:
		alpha = minf(alpha, (_lifetime - _age) / 1.0)
	if texture == null:
		draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 16, Color(Palette.NEWLEAF, alpha), 3.0)
		return
	var frames: int = _data.trap_frames
	var size := Vector2(texture.get_width() / float(frames), texture.get_height())
	var frame := int(_age * ANIMATION_FPS) % frames
	draw_texture_rect_region(texture, Rect2(-size * SCALE / 2.0, size * SCALE),
		Rect2(Vector2(size.x * frame, 0), size), Color(1, 1, 1, alpha))
