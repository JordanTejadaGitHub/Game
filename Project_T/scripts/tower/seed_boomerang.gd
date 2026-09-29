extends Node2D
class_name SeedBoomerang

# Samara's spinning maple seed: flies in a straight line (over walls, through everything) and back.
# Each pass hits every nightmare it crosses once (out and back = twice). The statuses of the first
# nightmare it hits are carried down the line at half stacks. Cards: Backspin (+25% crit on the way
# back), Ricochet (turns 90° toward the nearest nightmare at the end; II: twice), Heavy Seed (knocks
# back 0.25 tiles once per throw), Windborne Rain (every pass applies Damp). Script-only, world space.

const SPEED := 420.0  # Pixels per second
const HIT_RADIUS := 26.0  # Pixels either side of the line
const BACKSPIN_CRIT := 0.25
const ANIMATION_FPS := 14.0

var _tower: Tower
var _data: TowerData
var _boost := 1.0
var _points: Array[Vector2] = []  # The way out: start, end (and any ricochet turns)
var _leg := 0  # Heading toward _points[_leg + 1] on the way out, back down the list on the way home
var _returning := false
var _damage_multiplier := 1.0
var _hit_this_pass := {}
var _carried: Array = []  # Statuses picked up from the first nightmare hit
var _hit_anything := false
var _anim := 0.0
var _turns_left := 0
var _storm := {}  # Carried Storm: the Reaction this seed passed through ({id, applier, colour})
var _stormed := {}  # Nightmares it already repeated on this throw

func _init(tower: Tower, from: Vector2, direction: Vector2, length: float, damage_multiplier: float) -> void:
	_tower = tower
	_data = tower.attack_data  # What it was made with (a legacy attack, a Graftling's copy)
	_boost = tower._hit_boost  # Sudden Bloom / Watchful Rest
	_damage_multiplier = damage_multiplier
	_points = [from, from + direction.normalized() * length]
	top_level = true
	z_index = 5
	position = from
	var dreams: DreamState = tower._dream_state
	if dreams and dreams.has_rule(&"ricochet"):
		_turns_left = 2 if dreams.rule_level(&"ricochet") > 0 else 1

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()
	if not is_instance_valid(_tower):
		queue_free()
		return
	var step := SPEED * delta
	var goal: Vector2 = _points[_leg + 1] if not _returning else _points[_leg]
	var before := global_position
	global_position = global_position.move_toward(goal, step)
	_carry_storm(before)
	_hit_along(before, global_position)
	if global_position.distance_to(goal) > 0.5:
		return
	if not _returning:
		if _leg + 1 < _points.size() - 1:
			_leg += 1
		elif _turns_left > 0 and _ricochet():
			_turns_left -= 1
			_leg += 1
		else:
			_returning = true  # The return pass: everything can be hit once more
			_hit_this_pass.clear()
			_leg = _points.size() - 2
	else:
		if _leg > 0:
			_leg -= 1
		else:
			_tower.catch_seed(_hit_anything)
			queue_free()

# Carried Storm (a delivery rule): passing through a Reaction's spot within 0.5 s, the seed carries it
# down the rest of its line, repeating it at 50% on each nightmare it hits after (once each per throw).
func _carry_storm(before: Vector2) -> void:
	var tracker := ReactionTracker.find(_tower)
	if tracker == null:
		return
	if _storm.is_empty():
		var spot := tracker.spot_near(global_position, Reactions.CARRIED_REACH * Tower.MAP_GRID.cell_size.x)
		if spot.is_empty():
			return
		var data := Reactions.get_data(Reactions.CROWNED_BASE.get(spot.id, spot.id))
		_storm = {"id": spot.id, "applier": spot.applier, "colour": data.callout_color if data else Color.WHITE}
		return
	var trail := Fx.segment(&"carried_storm", before, global_position, tracker.get_parent(), 0.3)
	if trail != null:
		trail.modulate = _storm.colour  # The seed trails the Reaction's colour

# Ricochet: a 90° turn toward the nearest nightmare, half the line's length.
func _ricochet() -> bool:
	var here: Vector2 = _points[-1]
	var direction: Vector2 = (_points[-1] - _points[-2]).normalized()
	var nearest: Node2D = null
	for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		if nearest == null or enemy.global_position.distance_to(here) < nearest.global_position.distance_to(here):
			nearest = enemy
	if nearest == null:
		return false
	var side := direction.orthogonal()
	if side.dot(nearest.global_position - here) < 0.0:
		side = -side
	_points.append(here + side * (_points[1].distance_to(_points[0]) * 0.5))
	return true

func _hit_along(from: Vector2, to: Vector2) -> void:
	var dreams: DreamState = _tower._dream_state
	for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		var id: int = enemy.get_instance_id()
		if _hit_this_pass.has(id):
			continue
		var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, from, to)
		if closest.distance_to(enemy.global_position) > HIT_RADIUS:
			continue
		_hit_this_pass[id] = true
		_hit_anything = true
		if _carried.is_empty() and not _returning:
			_carried = enemy.statuses.snapshot()  # The first nightmare's statuses ride the seed
		elif not _carried.is_empty():
			var full := Tower._kin_roll(_tower.kin_share(&"tailwind", "a")) if is_instance_valid(_tower) else false  # Tailwind: full stacks
			for status in _carried:
				enemy.apply_status(status.id, status.stacks if full else maxi(ceili(status.stacks / 2.0), 1), status.time, status.potency, 0,
					status.line, status.get("source"))
		var crit := Tower.ROLL_CRIT
		if _returning and dreams and dreams.has_rule(&"backspin") \
				and randf() < _tower.get_crit_chance(enemy) + BACKSPIN_CRIT:
			crit = Tower.CRIT
		# Heavy Seed (card): the return pass hits for double (status jobs review: no knockback any more).
		var pass_multiplier := _damage_multiplier * (2.0 if _returning and dreams and dreams.has_rule(&"heavy_seed") else 1.0)
		_tower.run_as(_data, _boost, func() -> void: _tower.hit(enemy, pass_multiplier, false, crit))
		if not _storm.is_empty() and not _stormed.has(id) and is_instance_valid(enemy) and not enemy.is_cleansed:
			_stormed[id] = true
			Reactions.carry(_storm.id, enemy, _tower, _storm.applier if is_instance_valid(_storm.applier) else null)
		if not is_instance_valid(enemy) or enemy.is_cleansed:
			continue
		if dreams and dreams.has_rule(&"windborne_rain"):
			enemy.apply_status(EnemyStatuses.DAMP, 1, 0.0, 1.0, 0, "water", _tower)

func _draw() -> void:
	var texture: Texture2D = _data.projectile_texture if is_instance_valid(_tower) else null
	var spin := _anim * 18.0
	if texture == null:
		# A maple seed: a round seed and one long wing, spinning.
		var wing := Vector2.from_angle(spin) * 11.0
		draw_line(Vector2.ZERO, wing, Color(0.85, 0.6, 0.3), 4.0)
		draw_circle(Vector2.ZERO, 3.5, Color(0.6, 0.4, 0.2))
		return
	draw_set_transform(Vector2.ZERO, spin)
	var frames: int = _data.projectile_frames
	var size := Vector2(texture.get_width() / float(frames), texture.get_height())
	var frame := int(_anim * ANIMATION_FPS) % frames
	draw_texture_rect_region(texture, Rect2(-size / 2.0, size), Rect2(Vector2(size.x * frame, 0), size))
	draw_set_transform(Vector2.ZERO)
