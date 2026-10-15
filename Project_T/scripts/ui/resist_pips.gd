extends Node2D
class_name ResistPips

# The immune flash (screens_ui.md "Nightmare info"): when a status is refused (EnemyContainer.status_refused), the
# crossed status icon pops once over the nightmare. Made by the HUD, drawn in the world over the nightmares.
# (The resist / weak pips and their "always show" setting went with damage types: Nightmare Kinds, enemy_design.md
# ed6f573b. The class keeps its name so the HUD and tests find it.)

# Enemy.gd's health bar (it has no class_name): its centre offset.
const BAR_OFFSET := Vector2(0, -38)
const FLASH_TIME := 0.9
const MAX_FLASHES := 8  # On screen at once (a Warden spraying an immune crowd stays readable)
const FLASH_GAP := 0.6  # Seconds between two flashes on the same nightmare

var _flashes: Array = []  # [[enemy, status id, time left], …]
var _last_flash := {}  # enemy instance id -> Time of its last flash (seconds)
var _drawn := false  # Flashes were on screen last frame

func _ready() -> void:
	z_index = 8
	process_mode = Node.PROCESS_MODE_ALWAYS  # Placing works while paused
	var spawner := get_parent().get_node_or_null("%EnemyContainer")
	if spawner != null and spawner.has_signal("status_refused"):
		spawner.status_refused.connect(flash_refused)

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
	if _flashes.is_empty() and not _drawn:
		return
	var game_delta := 0.0 if get_tree().paused else delta
	for flash in _flashes:
		flash[2] -= game_delta / maxf(Engine.time_scale, 0.001)
	_flashes = _flashes.filter(func(f: Array) -> bool: return f[2] > 0.0 and is_instance_valid(f[0]))
	_drawn = not _flashes.is_empty()  # Once more after the last flash goes, then idle
	queue_redraw()

func _draw() -> void:
	for flash in _flashes:
		var enemy: Node2D = flash[0]
		var t: float = flash[2] / FLASH_TIME  # 1 -> 0
		var at: Vector2 = enemy.global_position + BAR_OFFSET + Vector2(0, -26.0 - 10.0 * (1.0 - t))
		_draw_crossed(at, StringName(flash[1]), minf(t * 2.5, 1.0))

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
