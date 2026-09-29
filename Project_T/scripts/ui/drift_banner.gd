extends Control

# Top-centre drift display (screens_ui.md "The run HUD"): act and drift, 5 pips for the current
# block, and the countdown to the next boss. During a boss drift the countdown becomes the boss's
# health bar, with a marker where an ability starts (50%; the Oak 67% / 33%). Drawn in code.

const WIDTH := 460.0
const PIP_RADIUS := 5.0
const TEXT_COLOR := UiStyle.INK
const DIM_COLOR := Color(0.55, 0.6, 0.55)
const BOSS_COLOR := Color(0.95, 0.45, 0.4)
const FONT_SIZE := 22
const SMALL_FONT_SIZE := 16

@onready var drift_director: DriftDirector = %DriftDirector

var _boss: Node2D = null
# Tappable spots (screens_ui.md "Boss dossier"): "Boss in N" opens the dossier; during the boss drift
# the bar's markers (50%, or the Oak's 67% / 33%) show the ability that starts there. Everything else lets clicks through.
var _countdown_rect := Rect2()
var _markers: Array = []  # [[Rect2, line], …] on the boss bar
var _marker_tip := TapTip.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP  # Only on the spots above (_has_point)
	add_child(_marker_tip)
	var spawner = %EnemyContainer
	spawner.child_entered_tree.connect(func(node: Node) -> void:
		if node.get("enemy_data") != null and node.enemy_data.is_boss:
			_boss = node)

func _process(_delta: float) -> void:
	queue_redraw()  # Cheap; the numbers change every frame during a boss drift

func _draw() -> void:
	var font := UiStyle.display_font()  # Moonlit Thread (ui_style.md)
	var center_x := size.x / 2.0
	var latest := drift_director.drifts_started
	var total := drift_director.get_total_drifts()
	var shown := mini(latest + 1 if drift_director.is_resting() else maxi(latest, 1), total)
	var act := drift_director.get_act(shown)
	var top := "Act %d · %s      %s" % [act, drift_director.get_act_name(act), get_drift_text()]
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
		var width := font.get_string_size(boss_text, HORIZONTAL_ALIGNMENT_LEFT, -1, SMALL_FONT_SIZE).x
		_countdown_rect = Rect2(center_x + 40.0 - width / 2.0 - 8.0, 28, width + 16.0, 26)
		# Underlined: it opens the dossier.
		draw_line(Vector2(center_x + 40.0 - width / 2.0, 49), Vector2(center_x + 40.0 + width / 2.0, 49),
			Color(BOSS_COLOR, 0.6), 1.0)
	else:
		_countdown_rect = Rect2()
	_markers = []

func _draw_boss_bar(font: Font, center_x: float) -> void:
	var bar := Rect2(center_x - WIDTH / 2.0, 34, WIDTH, 10)
	var fraction := float(_boss.health) / maxf(_boss.max_health, 1.0)
	draw_rect(bar.grow(2), Color(0.05, 0.05, 0.08, 0.85))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * fraction, bar.size.y)), BOSS_COLOR)
	# A marker (with a knob: it's tappable) at every health share an ability starts at.
	_markers = []
	var lines := marker_lines()
	for share in lines:
		var x := bar.position.x + bar.size.x * float(share)
		draw_line(Vector2(x, bar.position.y - 3), Vector2(x, bar.end.y + 3), Color.WHITE, 2.0)
		draw_circle(Vector2(x, bar.position.y - 5), 3.0, Color.WHITE)
		_markers.append([Rect2(x - 14, bar.position.y - 14, 28, 32), lines[share]])
	# The rest of the bar (and the name) opens the dossier too.
	_countdown_rect = Rect2(bar.position.x, bar.position.y - 4, bar.size.x, bar.size.y + 26)
	_draw_centered(font, _boss.enemy_data.display_name, Vector2(center_x, bar.end.y + 16), SMALL_FONT_SIZE, BOSS_COLOR.lightened(0.3))

func _has_point(point: Vector2) -> bool:
	return _marker_at(point) != "" or _countdown_rect.has_point(point)

func _marker_at(point: Vector2) -> String:
	for marker in _markers:
		if marker[0].has_point(point):
			return marker[1]
	return ""

func _get_tooltip(at: Vector2) -> String:
	var line := _marker_at(at)
	if line != "":
		return line
	return "Open the boss dossier" if _countdown_rect.has_point(at) else ""

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var line := _marker_at(event.position)
	if line != "":
		show_marker_tip(line, event.position)
	elif _countdown_rect.has_point(event.position):
		BossDossier.open_for(get_tree())
	accept_event()

# {health share: line} for the boss's abilities that start at a health share (EnemyData abilities
# whose "when" says "at 50% health", "at 67% and 33% health"), e.g. 0.5: "At 50% health · Charge: its
# antlers flare and it runs +50% faster for 4 s." Empty = no markers (never a marker that says nothing).
func marker_lines() -> Dictionary:
	var lines := {}
	if not is_instance_valid(_boss):
		return lines
	var data: EnemyData = _boss.enemy_data
	var percent := RegEx.create_from_string("([0-9]+)%")
	for i in data.abilities.size():
		var ability := data.get_ability(i)
		var when := String(ability.get("when", ""))
		if not when.contains("health"):
			continue
		for found in percent.search_all(when):
			var share := int(found.get_string(1)) / 100.0
			lines[share] = IconInfo.format("At %s health · %s: %s" % [found.get_string(), ability.get("name", ""),
				ability.get("text", "")])
	return lines

# The 50% marker's line ("" if the boss has none).
func half_health_text() -> String:
	return marker_lines().get(0.5, "")

func show_marker_tip(line: String, at: Vector2) -> void:
	_marker_tip._label.text = line
	_marker_tip.visible = false
	_marker_tip.toggle()
	var screen := get_viewport_rect().size
	_marker_tip.global_position = Vector2(clampf(global_position.x + at.x - _marker_tip.size.x / 2.0,
		4, screen.x - _marker_tip.size.x - 4), global_position.y + 70)

# "Drift 7 / 50", or "Ready · Drift 1" before the first drift.
func get_drift_text() -> String:
	var latest := drift_director.drifts_started
	return "Ready · Drift 1" if latest == 0 else "Drift %d / %d" % [latest, drift_director.get_total_drifts()]

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
