extends Control

# Top-centre drift display (screens_ui.md "The run HUD"): act and drift, 5 pips for the current
# block, and the countdown to the next boss. During a boss drift the countdown becomes the boss's
# health bar, with a marker at 50% (where its behaviour changes). Drawn in code.

const WIDTH := 460.0
const PIP_RADIUS := 5.0
const TEXT_COLOR := Color(0.9, 0.92, 0.85)
const DIM_COLOR := Color(0.55, 0.6, 0.55)
const BOSS_COLOR := Color(0.95, 0.45, 0.4)
const FONT_SIZE := 18
const SMALL_FONT_SIZE := 14

@onready var drift_director: DriftDirector = %DriftDirector

var _boss: Node2D = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var spawner = %EnemyContainer
	spawner.child_entered_tree.connect(func(node: Node) -> void:
		if node.get("enemy_data") != null and node.enemy_data.is_boss:
			_boss = node)

func _process(_delta: float) -> void:
	queue_redraw()  # Cheap; the numbers change every frame during a boss drift

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var center_x := size.x / 2.0
	var latest := drift_director.drifts_started
	var total := drift_director.get_total_drifts()
	var shown := mini(latest + 1 if drift_director.is_resting() else maxi(latest, 1), total)
	var act := drift_director.get_act(shown)
	var top := "Act %d · %s      Drift %d / %d" % [act, drift_director.get_act_name(act), latest, total]
	_draw_centered(font, top, Vector2(center_x, 20), FONT_SIZE, TEXT_COLOR)

	if is_instance_valid(_boss) and not _boss.is_cleansed:
		_draw_boss_bar(font, center_x)
		return
	# Pips: one per drift in the current block, filled once it has started.
	var block := drift_director.get_block(shown)
	var first := (block - 1) * drift_director.drifts_per_block + 1
	var pips_width := drift_director.drifts_per_block * PIP_RADIUS * 3.0
	var x := center_x - 120.0 - pips_width / 2.0
	for i in drift_director.drifts_per_block:
		var number := first + i
		var filled := number <= latest
		var at := Vector2(x + i * PIP_RADIUS * 3.0, 40)
		var colour := BOSS_COLOR if drift_director.is_boss_drift(number) else TEXT_COLOR
		if filled:
			draw_circle(at, PIP_RADIUS, colour)
		else:
			draw_arc(at, PIP_RADIUS, 0.0, TAU, 16, Color(colour, 0.7), 1.5)
	var boss_text := _next_boss_text(latest)
	if boss_text != "":
		_draw_centered(font, boss_text, Vector2(center_x + 40.0, 45), SMALL_FONT_SIZE, BOSS_COLOR.lightened(0.2))

func _draw_boss_bar(font: Font, center_x: float) -> void:
	var bar := Rect2(center_x - WIDTH / 2.0, 34, WIDTH, 10)
	var fraction := float(_boss.health) / maxf(_boss.max_health, 1.0)
	draw_rect(bar.grow(2), Color(0.05, 0.05, 0.08, 0.85))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * fraction, bar.size.y)), BOSS_COLOR)
	var half_x := bar.position.x + bar.size.x * 0.5
	draw_line(Vector2(half_x, bar.position.y - 3), Vector2(half_x, bar.end.y + 3), Color.WHITE, 2.0)
	_draw_centered(font, _boss.enemy_data.display_name, Vector2(center_x, bar.end.y + 16), SMALL_FONT_SIZE, BOSS_COLOR.lightened(0.3))

# "The Hollow Stag in 18" for the next boss drift after `latest`, or "".
func _next_boss_text(latest: int) -> String:
	for number in range(latest + 1, drift_director.get_total_drifts() + 1):
		if drift_director.is_boss_drift(number):
			var name := _boss_name(number)
			return "%s in %d" % [name, number - latest] if name != "" else "Boss in %d" % (number - latest)
	return ""

var _boss_names := {}  # Drift number -> boss display name (schedules are costly to rebuild each frame)

func _boss_name(number: int) -> String:
	if not _boss_names.has(number):
		_boss_names[number] = ""
		for group in drift_director.drifts[number - 1].groups:
			for entry in group.entries:
				if entry.enemy != null and entry.enemy.is_boss:
					_boss_names[number] = entry.enemy.display_name
	return _boss_names[number]

func _draw_centered(font: Font, text: String, at: Vector2, font_size: int, colour: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin := Vector2(at.x - width / 2.0, at.y)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Color(0.05, 0.06, 0.08))
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)
