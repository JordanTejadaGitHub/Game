extends PanelContainer
class_name DriftMeter

# Damage that means something (screens_ui.md, 7ffdf3d; Tower Code's WardenMeter has the numbers):
# a collapsible drift meter on the right edge. The header always shows "Maze 1,240 DPS · ↑12% vs last
# drift · needs ~980"; open, a row per Warden: portrait, DPS, share %, rating colour (gold carrying,
# white fine, dim blue underused, with the reason in the tooltip), ↑↓ vs its last drift and a star
# on the most improved. Sort by DPS or share. Clicking a row selects that Warden and glides the camera
# to it. During a drift it shows the drift; at a rest, the block. Made by the HUD.
# The shared helpers below (colours, ↑↓, the benchmark sentence, select-and-glide) are also used by
# the DPS tags, the DriftPanel's benchmark line and the rest report.

const WIDTH := 300.0
const REFRESH := 0.5
const CARRYING_COLOR := Color("fcd47c")  # UiStyle.GOLD
const FINE_COLOR := Color("fff4dc")  # UiStyle.INK
const UNDERUSED_COLOR := Color("7f9cc8")  # Dim blue
const GOOD := Color(0.55, 0.9, 0.5)
const CLOSE := Color(1.0, 0.8, 0.35)
const SHORT := Color(0.95, 0.45, 0.4)
const OPEN_SETTING := "meter_open"

var drift_director: DriftDirector
var sort_by_share := false
var _header := Button.new()
var _sort := Button.new()
var _rows := VBoxContainer.new()
var _body := VBoxContainer.new()
var _clock := 0.0

# --- Shared helpers ------------------------------------------------------------------------------

static func rating_color(label: StringName) -> Color:
	match label:
		&"carrying": return CARRYING_COLOR
		&"underused": return UNDERUSED_COLOR
	return FINE_COLOR

# Green at 110% and up, amber 90–110%, red under 90%.
static func ratio_color(ratio: float) -> Color:
	return GOOD if ratio >= 1.1 else (CLOSE if ratio >= 0.9 else SHORT)

# "↑12%" / "↓8%" / "" (no last drift to compare with).
static func change_text(change) -> String:
	if change == null or absf(float(change)) < 0.005:
		return ""
	return ("↑%d%%" if change > 0.0 else "↓%d%%") % roundi(absf(float(change)) * 100.0)

static func fmt(value: float) -> String:
	var text := str(roundi(value))
	var out := ""
	for i in text.length():
		if i > 0 and (text.length() - i) % 3 == 0 and text[i - 1] != "-":
			out += ","
		out += text[i]
	return out

# "Your maze 1,240 DPS · this drift needs ~980 · 127%" (a drift), or at a rest "Last drift 1,240 DPS ·
# drift 12 needs ~980 · 127%" (the forecast). "" before there's anything to compare.
static func benchmark_text(b: Dictionary) -> String:
	if b.is_empty() or float(b.get("needed_dps", 0.0)) <= 0.0:
		return ""
	var pct := roundi(float(b.ratio) * 100.0)
	if b.get("forecast", false):
		return "Last drift %s DPS · drift %d needs ~%s · %d%%" % [fmt(b.maze_dps), int(b.drift), fmt(b.needed_dps), pct]
	return "Your maze %s DPS · this drift needs ~%s · %d%%" % [fmt(b.maze_dps), fmt(b.needed_dps), pct]

# Selects `tower` and glides the camera to it (a meter row, a DPS tag, a hit number).
static func focus_tower(tower: Node) -> void:
	if not is_instance_valid(tower) or not tower.is_inside_tree():
		return
	# Planted Wardens are made in code (no owner): their container belongs to the run's scene.
	var container := tower.get_parent()
	var main: Node = container.owner if container != null and container.owner != null else tower.get_tree().current_scene
	var seller := main.get_node_or_null("%TowerSeller") if main != null else null
	if seller != null and seller.has_method("select"):
		seller.select(tower)
	var camera := main.get_node_or_null("GameCameraNode") if main != null else null
	if camera != null and camera.has_method("glide"):
		var from: Vector2 = camera.get("target_position")
		camera.glide(PackedVector2Array([from, tower.global_position]), 0.4)

# --- The panel -----------------------------------------------------------------------------------

func _init(director: DriftDirector = null) -> void:
	drift_director = director

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	grow_vertical = Control.GROW_DIRECTION_BOTH
	offset_right = -16.0
	offset_left = offset_right - WIDTH
	offset_top = 40.0  # Below the nightmare info's usual spot
	custom_minimum_size = Vector2(WIDTH, 0)
	add_theme_stylebox_override("panel", UiStyle.panel(10.0, 8.0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	_header.flat = true
	_header.focus_mode = Control.FOCUS_NONE
	_header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_header.custom_minimum_size = Vector2(0, 36)
	_header.tooltip_text = "Drift meter: tap to open or close"
	_header.pressed.connect(func() -> void: set_open(not _body.visible))
	box.add_child(_header)
	_body.add_theme_constant_override("separation", 2)
	box.add_child(_body)
	_sort.text = "Sort: DPS"
	_sort.flat = true
	_sort.focus_mode = Control.FOCUS_NONE
	_sort.custom_minimum_size = Vector2(0, 32)
	_sort.pressed.connect(func() -> void:
		sort_by_share = not sort_by_share
		_sort.text = "Sort: share" if sort_by_share else "Sort: DPS"
		refresh())
	_body.add_child(_sort)
	_body.add_child(_rows)
	_body.visible = bool(HeartwoodMemory.get_settings().get(OPEN_SETTING, false))
	visible = false

func set_open(open: bool) -> void:
	_body.visible = open
	var settings := HeartwoodMemory.get_settings()
	settings[OPEN_SETTING] = open
	if get_tree().current_scene == drift_director.owner:  # The real game only (tests never write)
		HeartwoodMemory.save_settings(settings)
	refresh()

func meter() -> WardenMeter:
	return WardenMeter.find(drift_director) if drift_director != null else null

# The drift while one walks; the block just played at a rest.
func period() -> String:
	return "drift" if drift_director != null and not drift_director.is_resting() else "block"

func _process(delta: float) -> void:
	_clock -= delta / maxf(Engine.time_scale, 0.001)
	if _clock > 0.0:
		return
	_clock = REFRESH
	refresh()

func refresh() -> void:
	var m := meter()
	visible = m != null and drift_director.drifts_started > 0
	if not visible:
		return
	var b := m.get_benchmark()
	var head := "Maze %s DPS" % fmt(m.get_maze_dps(period()))
	var change := change_text(b.get("change"))
	if change != "":
		head += " · %s vs last drift" % change
	if float(b.get("needed_dps", 0.0)) > 0.0:
		head += " · needs ~%s" % fmt(b.needed_dps)
	_header.text = ("▾ " if _body.visible else "▸ ") + head
	_header.add_theme_color_override("font_color", ratio_color(float(b.get("ratio", 1.0))) if b.get("needed_dps", 0.0) > 0.0 else FINE_COLOR)
	if not _body.visible:
		return
	var rows: Array = m.get_meter_rows(period())
	if sort_by_share:
		rows.sort_custom(func(a: Dictionary, c: Dictionary) -> bool: return a.share > c.share)
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	for r in rows:
		_rows.add_child(_row(r))

func _row(r: Dictionary) -> Control:
	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 34)
	button.name = "Row"
	var tower = r.tower
	if is_instance_valid(tower):
		button.icon = WardenIcon.make(tower.tower_data)
	button.expand_icon = false
	button.add_theme_constant_override("icon_max_width", 26)
	var star := " ★" if r.get("most_improved", false) else ""
	button.text = "%s  %s DPS · %d%%  %s%s" % [r.name, fmt(r.dps), roundi(float(r.share) * 100.0), change_text(r.get("change")), star]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var colour := rating_color(r.get("rating_label", &""))
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, colour)
	var tip := "%s: %s DPS, %d%% of the maze, %s Dew invested" % [r.name, fmt(r.dps), roundi(float(r.share) * 100.0), fmt(r.dew_invested)]
	if r.get("rating_label", &"") == &"carrying":
		tip += "\nCarrying: far more than its cost."
	elif r.get("rating_label", &"") == &"underused":
		tip += "\nUnderused" + (": " + String(r.reason) if String(r.get("reason", "")) != "" else ".")
	if r.get("most_improved", false):
		tip += "\n★ Most improved"
	button.tooltip_text = tip
	button.pressed.connect(func() -> void: focus_tower(tower))
	return button
