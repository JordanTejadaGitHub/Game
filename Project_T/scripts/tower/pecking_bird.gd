extends Node2D
class_name PeckingBird

# A hummingbird (Hummingbird Bower / Jewelwing Court): darts to its nightmare, hovers pecking it
# `pecks` times over `peck_time` seconds (each peck is a full Warden hit, see Tower.peck), then flies
# home. If the nightmare is dispelled or gone, it flies home early. Script-only, world space.

const SPEED := 520.0  # Pixels per second out and home
const HOVER := Vector2(10, -18)  # Where it hovers, relative to the nightmare
const ANIMATION_FPS := 18.0

var _tower: Tower
var _data: TowerData
var _boost := 1.0
var _target: Node2D
var _pecks_left: int
var _peck_every: float
var _peck_timer := 0.0
var _state := 0  # 0 out, 1 pecking, 2 home
var _anim := 0.0

func _init(tower: Tower, target: Node2D, pecks: int, peck_time: float) -> void:
	_tower = tower
	_data = tower.attack_data  # What it was made with (a legacy attack, a Graftling's copy)
	_boost = tower._hit_boost  # Sudden Bloom / Watchful Rest
	_target = target
	_pecks_left = pecks
	_peck_every = peck_time / maxf(pecks, 1)
	top_level = true
	z_index = 5

func _process(delta: float) -> void:
	_anim += delta
	queue_redraw()
	if not is_instance_valid(_tower):
		queue_free()
		return
	delta *= _tower.get_cycle_multiplier()  # Swift: faster flight and pecks (Nurture rework)
	var target_alive: bool = is_instance_valid(_target) and not _target.is_cleansed
	if _state < 2 and not target_alive:
		_state = 2
	match _state:
		0:
			var to: Vector2 = _target.global_position + HOVER
			global_position = global_position.move_toward(to, SPEED * delta)
			if global_position.distance_to(to) < 2.0:
				_state = 1
		1:
			global_position = _target.global_position + HOVER
			_peck_timer += delta
			while _peck_timer >= _peck_every and _pecks_left > 0:
				_peck_timer -= _peck_every
				_pecks_left -= 1
				_tower.run_as(_data, _boost, _tower.peck.bind(_target))
			if _pecks_left <= 0:
				_state = 2
		2:
			var home: Vector2 = _tower.global_position + _tower.tower_data.get_attack_origin()
			global_position = global_position.move_toward(home, SPEED * delta)
			if global_position.distance_to(home) < 2.0:
				queue_free()

func _draw() -> void:
	var texture: Texture2D = _data.projectile_texture if is_instance_valid(_tower) else null
	var bob := Vector2(0, sin(_anim * 30.0) * 1.5)
	if texture == null:
		# A tiny bright bird: body and a blur of wings.
		draw_circle(bob, 3.5, Palette.SPRIG)
		draw_circle(bob + Vector2(-3, -2), 3.0, Color(Palette.HEARTLIGHT, 0.35))
		draw_line(bob + Vector2(3, 0), bob + Vector2(8, 1), Palette.DEEPMOSS, 1.0)
		return
	var frames: int = _data.projectile_frames
	var size := Vector2(texture.get_width() / float(frames), texture.get_height())
	var frame := int(_anim * ANIMATION_FPS) % frames
	draw_texture_rect_region(texture, Rect2(bob - size / 2.0, size), Rect2(Vector2(size.x * frame, 0), size))
