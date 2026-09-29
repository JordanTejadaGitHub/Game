extends Node2D
class_name PathCloud

const HOAR_FOG_STAY := 2.0  # Hoar Fog (Kinship): seconds in the fog before it freezes…
const HOAR_FOG_FREEZE := 0.75  # …for this long (Frostfern's freeze), x the bond's share

# A lingering cloud on a path tile (Bloomcap's sleepy cloud, Mistveil's fog). Every TICK seconds
# it soothes the creatures inside a little and applies the Warden's status; fog clouds also make
# Spored tick harder. Script-only node, a child of the Warden that dropped it.

const TICK := 0.5
# Pixel-art puffs and fog strands (tools/effect_art_generator.gd), near-white so the Warden's
# projectile_color tints them. Variants side by side, not animation frames.
const PUFFS := preload("res://assets/effects/cloud_puffs.png")
const PUFF_SIZE := Vector2(48, 32)
const PUFF_ANCHOR := Vector2(24, 20)
const WISPS := preload("res://assets/effects/fog_wisps.png")
const WISP_SIZE := Vector2(56, 14)

var _tower: Tower
var _data: TowerData
var _boost := 1.0
var _radius: float
var _duration: float
var _fog: bool
var _color: Color
var _age := 0.0
var _tick_timer := 0.0
var _drowsy_time := {}  # Morning Fog: nightmare instance id -> seconds inside since its last Drowsy
var _seen := {}  # Nightmares that have been inside (instance ids): "entering" for Rainfog
var _stay := {}  # Hoar Fog: nightmare instance id -> seconds inside
var _frozen := {}  # Hoar Fog: nightmares this cloud froze

func _init(tower: Tower, center: Vector2) -> void:
	_tower = tower
	_data = tower.attack_data  # What it was made with (a legacy attack, a Graftling's copy)
	_boost = tower._hit_boost  # Sudden Bloom / Watchful Rest
	# attack_data: a Graftling copying a Bloomcap drops the Bloomcap's cloud.
	_radius = _data.cloud_radius * Tower.MAP_GRID.cell_size.x
	_duration = _data.cloud_duration
	_fog = _data.cloud_fog
	_color = _data.projectile_color
	top_level = true
	z_index = 4
	position = center

func _ready() -> void:
	_tick()

func _process(delta: float) -> void:
	_age += delta
	if _age >= _duration:
		queue_free()
		return
	_tick_timer += delta
	while _tick_timer >= TICK:
		_tick_timer -= TICK
		_tick()
	queue_redraw()

func _tick() -> void:
	for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		if enemy.global_position.distance_to(global_position) > _radius:
			continue
		if _fog:
			enemy.statuses.set_in_fog(TICK * 1.5)
		var data: TowerData = _data if is_instance_valid(_tower) else null
		if data and data.cloud_slow > 0.0:
			enemy.statuses.slow_time = maxf(enemy.statuses.slow_time, TICK * 1.6)
			enemy.statuses.slow_amount = maxf(enemy.statuses.slow_amount, data.cloud_slow * _tower.get_slow_multiplier())  # Heavy Air
		if data and data.cloud_drowsy_per_second > 0.0:
			var id: int = enemy.get_instance_id()
			_drowsy_time[id] = _drowsy_time.get(id, 0.0) + TICK
			if _drowsy_time[id] >= 1.0 / data.cloud_drowsy_per_second:
				_drowsy_time[id] = 0.0
				enemy.apply_status(EnemyStatuses.DROWSY, 1, 0.0, 0.0, 0, data.line, _tower)
		# Hoar Fog B: a Mistveil's fog freezes a nightmare that stays in it 2 s (once per cloud).
		if _fog and is_instance_valid(_tower) and not _frozen.has(enemy.get_instance_id()):
			var stay: float = _stay.get(enemy.get_instance_id(), 0.0) + TICK
			_stay[enemy.get_instance_id()] = stay
			var hoar := _tower.kin_share(&"hoar_fog", "b")
			if hoar > 0.0 and stay >= HOAR_FOG_STAY:
				_frozen[enemy.get_instance_id()] = true
				_tower.hold(enemy, HOAR_FOG_FREEZE * hoar)
				_tower._kin_fired(&"hoar_fog")
		# Kinships: Slumber Rot adds Spored per tick, Rainfog's fog hits nightmares entering it.
		var entered := not _seen.has(enemy.get_instance_id())
		_seen[enemy.get_instance_id()] = true
		_tower.kin_cloud_tick(enemy, entered)
		if not is_instance_valid(enemy) or enemy.is_cleansed:
			continue
		# A cloud's soothe per tick is a share of one attack, spread over its lifetime.
		_tower.run_as(_data, _boost, func() -> void: _tower.hit(enemy, TICK / _duration, true, Tower.NO_CRIT, &"cloud"))  # Clouds never crit; an effect (Potency)

func _draw() -> void:
	var fade := minf(1.0, (_duration - _age) / 0.5) * minf(1.0, _age / 0.2 + 0.3)
	var tint := _color.lerp(Color.WHITE, 0.25)
	# A ring of puffs turning slowly round the middle, bobbing, back ones drawn first.
	var n := 4 + roundi(_radius / 24.0)
	var puffs: Array = [[Vector2(0, -3), n % 4]]
	for i in n:
		var angle := TAU * i / n + _age * 0.25
		var bob := Vector2(0, sin(_age * 1.3 + i * 1.7) * 1.5)
		puffs.append([Vector2.from_angle(angle) * Vector2(_radius * 0.55, _radius * 0.4) + bob, i % 4])
	puffs.sort_custom(func(a: Array, b: Array) -> bool: return (a[0] as Vector2).y < (b[0] as Vector2).y)
	for p: Array in puffs:
		var at := ((p[0] as Vector2) - PUFF_ANCHOR).round()
		draw_texture_rect_region(PUFFS, Rect2(at, PUFF_SIZE), Rect2(Vector2(int(p[1]) * PUFF_SIZE.x, 0), PUFF_SIZE), Color(tint, 0.62 * fade))
	if _fog:
		# Fog strands drifting across, fading in and out at the cloud's edges.
		var span := _radius * 2.2
		for i in 3:
			var x := fposmod(_age * 14.0 + i * 37.0, span) - span / 2.0
			var edge := 1.0 - absf(x) / (span / 2.0)
			var at := (Vector2(x, (i - 1) * _radius * 0.35) - WISP_SIZE / 2.0).round()
			draw_texture_rect_region(WISPS, Rect2(at, WISP_SIZE), Rect2(Vector2(i * WISP_SIZE.x, 0), WISP_SIZE), Color(tint, 0.7 * fade * edge))
