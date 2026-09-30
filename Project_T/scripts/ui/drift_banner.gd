extends Control

# Top-centre drift display (screens_ui.md "The run HUD"): act and drift, 5 pips for the current
# block, and the countdown to the next boss. During a boss drift the countdown becomes the boss's
# health bar, with a marker where an ability starts (50%; the Oak 67% / 33%). Drawn in code.

const WIDTH := 460.0
const PIP_RADIUS := 5.0
const TEXT_COLOR := UiStyle.INK
const DIM_COLOR := Palette.PATH
const BOSS_COLOR := UiStyle.BOSS  # Heartwood 32 (ui_style.md)
const FONT_SIZE := 22
const SMALL_FONT_SIZE := 16
const BOSS_FONT_SIZE := 20  # The next-boss line: gold and larger than the rest
const DISC_RADIUS := 15.0  # Its portrait's moon disc
const BOSS_GAP := 22.0  # Between the pips and the boss

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

# Redrawn when what it shows changes (3× perf pass: it was every frame), and at least every
# SAFETY_REDRAW s for anything the key misses (pip states).
const SAFETY_REDRAW := 0.5
var _shown_key := ""
var _since_redraw := 0.0

func _process(delta: float) -> void:
	_since_redraw += delta / maxf(Engine.time_scale, 0.001)
	var boss_health := int(_boss.health) if is_instance_valid(_boss) and not _boss.is_cleansed else -1
	var key := "%s|%d|%s|%d|%s" % [get_drift_text(), drift_director.drifts_started, drift_director.is_resting(), boss_health, size]
	if key == _shown_key and _since_redraw < SAFETY_REDRAW:
		return
	_shown_key = key
	_since_redraw = 0.0
	queue_redraw()

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
	# The second row, centred as a whole: the block's pips, then the next boss (portrait on its disc +
	# "The Hollow Stag · drift 25 (in 20)" in gold, larger: screens_ui.md playtest fixes 2026-09-30).
	var block := drift_director.get_block(shown)
	var first := (block - 1) * drift_director.drifts_per_block + 1
	var step := PIP_RADIUS * 3.0
	var pips_width := (drift_director.drifts_per_block - 1) * step + PIP_RADIUS * 2.0
	var boss_text := _next_boss_text(latest)
	var boss_data := _next_boss_data(latest)
	var text_width := font.get_string_size(boss_text, HORIZONTAL_ALIGNMENT_LEFT, -1, BOSS_FONT_SIZE).x if boss_text != "" else 0.0
	var boss_width := (BOSS_GAP + DISC_RADIUS * 2.0 + 8.0 + text_width) if boss_text != "" else 0.0
	var row_y := 48.0
	var x := center_x - (pips_width + boss_width) / 2.0 + PIP_RADIUS
	for i in drift_director.drifts_per_block:
		var number := first + i
		var at := Vector2(x + i * step, row_y)
		var colour := BOSS_COLOR if drift_director.is_boss_drift(number) else TEXT_COLOR
		if number <= latest:  # Filled once it has started
			draw_circle(at, PIP_RADIUS, colour)
		else:
			draw_arc(at, PIP_RADIUS, 0.0, TAU, 16, Color(colour, 0.7), 1.5)
	_markers = []
	if boss_text == "":
		_countdown_rect = Rect2()
		return
	var left := x - PIP_RADIUS + pips_width + BOSS_GAP
	var disc := Vector2(left + DISC_RADIUS, row_y)
	UiStyle.draw_moon_disc(self, disc, DISC_RADIUS, BOSS_COLOR)
	if boss_data != null:
		var side := DISC_RADIUS * 1.6
		draw_texture_rect(NightmareCard.portrait(boss_data), Rect2(disc - Vector2(side, side) / 2.0, Vector2(side, side)),
			false, boss_data.tint)
	var text_x := disc.x + DISC_RADIUS + 8.0
	var base := row_y + BOSS_FONT_SIZE * 0.35
	draw_string_outline(font, Vector2(text_x, base), boss_text, HORIZONTAL_ALIGNMENT_LEFT, -1, BOSS_FONT_SIZE, 6, Palette.DREAD)
	draw_string(font, Vector2(text_x, base), boss_text, HORIZONTAL_ALIGNMENT_LEFT, -1, BOSS_FONT_SIZE, UiStyle.GOLD)
	# Underlined: it (and the portrait) opens the dossier.
	draw_line(Vector2(text_x, base + 4), Vector2(text_x + text_width, base + 4), Color(UiStyle.GOLD, 0.5), 1.0)
	_countdown_rect = Rect2(left - 4.0, row_y - DISC_RADIUS - 4.0, text_x + text_width - left + 8.0, DISC_RADIUS * 2.0 + 8.0)

func _draw_boss_bar(font: Font, center_x: float) -> void:
	var bar := Rect2(center_x - WIDTH / 2.0, 34, WIDTH, 10)
	var fraction := float(_boss.health) / maxf(_boss.max_health, 1.0)
	draw_rect(bar.grow(2), Color(Palette.DREAD, 0.85))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * fraction, bar.size.y)), BOSS_COLOR)
	# A marker (with a knob: it's tappable) at every health share an ability starts at.
	_markers = []
	var lines := marker_lines()
	for share in lines:
		var x := bar.position.x + bar.size.x * float(share)
		draw_line(Vector2(x, bar.position.y - 3), Vector2(x, bar.end.y + 3), UiStyle.INK, 2.0)
		draw_circle(Vector2(x, bar.position.y - 5), 3.0, UiStyle.INK)
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
	var data := _next_boss_data(drift_director.drifts_started)
	if data == null or not _countdown_rect.has_point(at):
		return ""
	return "About %s" % IconInfo.name_in_sentence(data.display_name)

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

# "Drift 7" (no total: playtest fixes 2026-09-30), or "Ready · Drift 1" before the first drift.
func get_drift_text() -> String:
	var latest := drift_director.drifts_started
	return "Ready · Drift 1" if latest == 0 else "Drift %d" % latest

# "The Hollow Stag · drift 25 (in 18)" for the next boss drift after `latest`, or "".
func _next_boss_text(latest: int) -> String:
	var number := _next_boss_drift(latest)
	if number == 0:
		return ""
	var data := _boss_of(number)
	return "%s · drift %d (in %d)" % [data.display_name if data != null else "Boss", number, number - latest]

func _next_boss_data(latest: int) -> EnemyData:
	var number := _next_boss_drift(latest)
	return _boss_of(number) if number > 0 else null

func _next_boss_drift(latest: int) -> int:
	for number in range(latest + 1, drift_director.get_total_drifts() + 1):
		if drift_director.is_boss_drift(number):
			return number
	return 0

var _bosses := {}  # Drift number -> its boss EnemyData (schedules are costly to rebuild each frame)

func _boss_of(number: int) -> EnemyData:
	var boss_drift: DriftData = drift_director.drifts[number - 1]
	if not _bosses.has(number) or _bosses[number][0] != boss_drift:
		var found: EnemyData = null
		for group in boss_drift.groups:
			for entry in group.entries:
				if entry.enemy != null and entry.enemy.is_boss:
					found = entry.enemy
		_bosses[number] = [boss_drift, found]
	return _bosses[number][1]

func _draw_centered(font: Font, text: String, at: Vector2, font_size: int, colour: Color) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var origin := Vector2(at.x - width / 2.0, at.y)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 6, Palette.DREAD)
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)
