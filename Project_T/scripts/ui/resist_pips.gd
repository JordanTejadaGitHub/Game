extends Node2D
class_name ResistPips

# Resistances on the map, in context (screens_ui.md "Nightmare info", added 2026-09-28): while
# placing a Warden or with Wardens selected, nightmares that resist that Warden's family get a small
# grey shield pip right of their health bar, those weak to it a warm spark pip. Nothing otherwise,
# unless the setting "resist_pips" (always show) is on: then against every attacking Warden planted.
# Also the immune flash: when a status is refused (EnemyContainer.status_refused), the crossed status
# icon pops once over the nightmare. Made by the HUD, drawn in the world over the nightmares.

const SETTING := "resist_pips"
const PIP_SIZE := 4.5
# Enemy.gd's health bar (it has no class_name): centre offset and size.
const BAR_OFFSET := Vector2(0, -38)
const BAR_WIDTH := 40.0
const FLASH_TIME := 0.9
const MAX_FLASHES := 8  # On screen at once (a Warden spraying an immune crowd stays readable)
const FLASH_GAP := 0.6  # Seconds between two flashes on the same nightmare

var tower_placer: Node = null
var tower_seller: Node = null
var tower_container: Node = null
var _lines: Array[String] = []
var _flashes: Array = []  # [[enemy, status id, time left], …]
var _last_flash := {}  # enemy instance id -> Time of its last flash (seconds)
var _always := false
var _settings_check := 0.0

func _ready() -> void:
	z_index = 8
	process_mode = Node.PROCESS_MODE_ALWAYS  # Placing works while paused
	var main := get_parent()
	tower_placer = main.get_node_or_null("%TowerPlacer")
	tower_seller = main.get_node_or_null("%TowerSeller")
	tower_container = main.get_node_or_null("%TowerContainer")
	var spawner := main.get_node_or_null("%EnemyContainer")
	if spawner != null and spawner.has_signal("status_refused"):
		spawner.status_refused.connect(flash_refused)
	_always = always_on()

static func always_on() -> bool:
	return bool(Fx.setting(SETTING, false))  # Cached, refreshed every few seconds

# The damage lines (Warden families) the pips compare against right now; empty = no pips.
func get_lines() -> Array[String]:
	var lines: Array[String] = []
	if tower_placer != null and tower_placer.build_mode and tower_placer.tower_data != null:
		_add_line(lines, tower_placer.tower_data)
	elif tower_seller != null and not tower_seller.selection.is_empty():
		for tower in tower_seller.selection:
			if is_instance_valid(tower):
				_add_line(lines, tower.get("attack_data") if tower.get("attack_data") != null else tower.tower_data)
	elif _always and tower_container != null:
		for tower in tower_container.get_children():
			if tower is Tower and tower.tower_data.can_attack:
				_add_line(lines, tower.tower_data)
	return lines

func _add_line(lines: Array[String], data: TowerData) -> void:
	if data != null and NightmareIcons.LINE_WARDENS.has(data.line) and not lines.has(data.line):
		lines.append(data.line)

# -1 = resists one of `lines`, 1 = weak to one, 2 = both (mixed selection), 0 = neither.
static func pip_for(data: EnemyData, lines: Array[String]) -> int:
	var d := data.get_defences()
	var resisted := false
	var weak := false
	for line in lines:
		resisted = resisted or d.get("resists", []).has(line)
		weak = weak or d.get("weak_to", []).has(line)
	return 2 if resisted and weak else (-1 if resisted else (1 if weak else 0))

# The immune flash (EnemyContainer.status_refused): throttled per nightmare and on screen.
func flash_refused(enemy: Node2D, status: StringName) -> void:
	if not is_instance_valid(enemy) or _flashes.size() >= MAX_FLASHES:
		return
	var now := Time.get_ticks_msec() / 1000.0
	var key := enemy.get_instance_id()
	if now - float(_last_flash.get(key, -100.0)) < FLASH_GAP:
		return
	_last_flash[key] = now
	_flashes.append([enemy, status, FLASH_TIME])

func _process(delta: float) -> void:
	_settings_check -= delta
	if _settings_check <= 0.0:  # The setting can change in the pause menu
		_settings_check = 1.0
		_always = always_on()
	_lines = get_lines()
	var game_delta := 0.0 if get_tree().paused else delta
	for flash in _flashes:
		flash[2] -= game_delta / maxf(Engine.time_scale, 0.001)
	_flashes = _flashes.filter(func(f: Array) -> bool: return f[2] > 0.0 and is_instance_valid(f[0]))
	queue_redraw()

func _draw() -> void:
	if not _lines.is_empty():
		for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
			if enemy.get("enemy_data") == null or (enemy.has_method("is_hidden") and enemy.is_hidden()):
				continue
			var pip := pip_for(enemy.enemy_data, _lines)
			if pip == 0:
				continue
			var at: Vector2 = enemy.global_position + BAR_OFFSET + Vector2(BAR_WIDTH / 2.0 + 7.0, 0)
			if pip == -1 or pip == 2:
				_draw_shield(at)
				at.x += PIP_SIZE * 2.4
			if pip == 1 or pip == 2:
				_draw_spark(at)
	for flash in _flashes:
		var enemy: Node2D = flash[0]
		var t: float = flash[2] / FLASH_TIME  # 1 -> 0
		var at: Vector2 = enemy.global_position + BAR_OFFSET + Vector2(0, -26.0 - 10.0 * (1.0 - t))
		_draw_crossed(at, StringName(flash[1]), minf(t * 2.5, 1.0))

func _draw_shield(at: Vector2) -> void:
	var s := PIP_SIZE
	var shield := PackedVector2Array([at + Vector2(-s, -s), at + Vector2(s, -s), at + Vector2(s, 0.15 * s),
		at + Vector2(0, s * 1.2), at + Vector2(-s, 0.15 * s)])
	draw_colored_polygon(shield, NightmareIcons.RESIST_COLOR)
	draw_polyline(shield + PackedVector2Array([shield[0]]), Palette.DREAD, 1.0)

func _draw_spark(at: Vector2) -> void:
	var s := PIP_SIZE * 1.2
	draw_circle(at, s * 0.8, Color(Palette.ROOT, 0.85))
	var spark := PackedVector2Array()
	for i in 8:
		spark.append(at + Vector2.from_angle(TAU * i / 8.0 - PI / 2.0) * (s if i % 2 == 0 else s * 0.35))
	draw_colored_polygon(spark, NightmareIcons.WEAK_COLOR)

func _draw_crossed(at: Vector2, status: StringName, alpha: float) -> void:
	draw_circle(at, 11.0, Color(Palette.DREAD, 0.85 * alpha))
	var art := IconInfo.icon(status)
	if art != null:
		draw_texture_rect(art, Rect2(at - Vector2(8, 8), Vector2(16, 16)), false, Color(1, 1, 1, alpha))
	else:
		draw_circle(at, 5.0, Color(EnemyStatuses.COLORS.get(status, UiStyle.INK), alpha))
	var d := Vector2(7.5, 7.5)
	draw_line(at - d, at + d, Color(NightmareIcons.IMMUNE_COLOR, alpha), 2.5, true)
	draw_arc(at, 11.0, 0.0, TAU, 20, Color(NightmareIcons.IMMUNE_COLOR, alpha), 1.5, true)
