extends PanelContainer
class_name DriftMeter

# Damage that means something (screens_ui.md, 7ffdf3d; Tower Code's WardenMeter has the numbers):
# a collapsible drift meter on the right edge. The header always shows "Maze 1,240 DPS · ↑12% vs last
# drift" ("· needs ~980" in dev runs only) and "Last drift 62 DPS"; open, a row per Warden: portrait,
# DPS, % of damage, colour by rank on the board (top ~20% gold, bottom ~20% dim; carrying / underused
# with the reason in the tooltip), ↑↓ vs its last drift and a star on the most improved. Sort by DPS or
# % of damage. Clicking a row selects that Warden and glides the camera to it; the wheel over the panel
# never reaches the map. During a drift it shows the drift; at a rest, the block. Made by the HUD.
# The shared helpers below (colours, ↑↓, the benchmark sentence, select-and-glide) are also used by
# the DPS tags and the rest report.

const WIDTH := 300.0
const REFRESH := 0.5
# Heartwood 32 (ui_style.md). Ratings: Glow / Heartlight / Stone; benchmark: Sprig / Gold / Ember (the
# palette has no red; the words say it too).
const CARRYING_COLOR := UiStyle.GOLD
const FINE_COLOR := UiStyle.INK
const UNDERUSED_COLOR := UiStyle.OFF
const GOOD := Color("9cc46c")  # Sprig
const CLOSE := UiStyle.BUTTON_GOLD
const SHORT := UiStyle.POOR
const OPEN_SETTING := "meter_open"

var drift_director: DriftDirector
var sort_by_share := false
const TOP_ROWS := 5  # The Wardens tab lists the top 5 (screens_ui.md, user playtest)
const UP_COLOR := UiStyle.GOLD  # A row's change vs its own last drift: up gold, down dim
var _more := Label.new()  # "and N more"
var block_summary := false  # The "Last block" tab is showing (not the Wardens)
var _wardens_tab := Button.new()
var _block_tab := Button.new()
var _summary := StatusLinks.make_label("", UiStyle.TIP_SIZE)  # The last block's summary (RestReport's text)
var _header := Button.new()
var _sort := Button.new()
var _rows := VBoxContainer.new()
var _scroll := ScrollContainer.new()  # The rows scroll when they'd reach the DriftPanel
var _body := VBoxContainer.new()
var _clock := 0.0
var _last := Label.new()  # "Last drift 62 DPS" (moved here from beside Start: playtest fixes 2026-09-30)

# --- Shared helpers ------------------------------------------------------------------------------

static func rating_color(label: StringName) -> Color:
	match label:
		&"carrying": return CARRYING_COLOR
		&"underused": return UNDERUSED_COLOR
	return FINE_COLOR

# Colour by rank on this board (playtest fixes 2026-09-30: the strongest reads strongest): the top
# ~20% gold, the middle white, the bottom ~20% dim. `index` 0 = the highest DPS, of `count` shown.
static func rank_color(index: int, count: int) -> Color:
	if index < maxi(ceili(count * 0.2), 1):
		return CARRYING_COLOR
	if count >= 5 and index >= count - floori(count * 0.2):
		return UNDERUSED_COLOR
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
	grow_vertical = Control.GROW_DIRECTION_END  # Down from offset_top (set by _fit)
	offset_right = -16.0
	offset_left = offset_right - WIDTH
	offset_top = BASE_TOP  # _fit moves it below the nightmare info while that shows
	custom_minimum_size = Vector2(WIDTH, 0)
	add_theme_stylebox_override("panel", UiStyle.panel(10.0, 8.0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	_header.flat = true
	_header.focus_mode = Control.FOCUS_NONE
	_header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_header.custom_minimum_size = Vector2(0, 36)
	UiStyle.caps(_header, 16, UiStyle.INK)
	_header.tooltip_text = "Drift meter: tap to open or close"
	_header.pressed.connect(func() -> void: set_open(not _body.visible))
	box.add_child(_header)
	_last.name = "LastDrift"
	UiStyle.number(_last, 15, UiStyle.INK_DIM)
	_last.visible = false
	box.add_child(_last)
	_body.add_theme_constant_override("separation", 2)
	box.add_child(_body)
	_sort.text = "Sort: DPS"
	_sort.flat = true
	_sort.focus_mode = Control.FOCUS_NONE
	_sort.custom_minimum_size = Vector2(0, 32)
	_sort.add_theme_font_override("font", UiStyle.caps_font())
	_sort.add_theme_font_size_override("font_size", 14)
	_sort.add_theme_color_override("font_color", UiStyle.INK_DIM)
	_sort.pressed.connect(func() -> void:
		sort_by_share = not sort_by_share
		_sort.text = "Sort: % of damage" if sort_by_share else "Sort: DPS"
		refresh())
	# Two views (screens_ui.md "No automatic rest report"): the Wardens, and "Last block": the block
	# summary that used to pop up at every rest (top Wardens, most improved, combos and Reactions,
	# close calls, Kinships formed …), opened on demand.
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	for pair in [[_wardens_tab, "Wardens", false], [_block_tab, "Last block", true]]:
		var tab: Button = pair[0]
		tab.text = pair[1]
		tab.toggle_mode = true
		tab.flat = false  # The theme's selected (gold border) / hover (filled) looks
		tab.focus_mode = Control.FOCUS_NONE
		tab.mouse_force_pass_scroll_events = false
		tab.custom_minimum_size = Vector2(0, 32)
		UiStyle.caps(tab, 14, UiStyle.INK)
		var summary: bool = pair[2]
		tab.pressed.connect(func() -> void: show_block_summary(summary))
		tabs.add_child(tab)
	_wardens_tab.set_pressed_no_signal(true)
	_body.add_child(tabs)
	_body.add_child(_sort)
	# The Wardens tab: the top TOP_ROWS by the current sort, no scrolling (user: the scroll bar didn't
	# work), then "and N more". Only the Last block summary scrolls.
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(_rows)
	_more.name = "More"
	UiStyle.caps(_more, 14)
	_more.visible = false
	_body.add_child(_more)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_summary.name = "BlockSummary"
	UiStyle.tip_body(_summary, WIDTH - 36.0)
	_scroll.add_child(_summary)
	_scroll.visible = false
	_body.add_child(_scroll)
	_body.visible = bool(HeartwoodMemory.get_settings().get(OPEN_SETTING, false))
	visible = false
	# The wheel over the panel scrolls its rows, never the map: scroll events a child passes up
	# (Buttons do by default) stop here instead of reaching the camera's zoom.
	for control in [self, _scroll, _rows, _body, _header, _sort]:
		control.mouse_force_pass_scroll_events = false
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN,
			MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]) or event is InputEventPanGesture or event is InputEventMagnifyGesture:
		accept_event()  # Never reaches the map

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
	_fit()
	_clock -= delta / maxf(Engine.time_scale, 0.001)
	if _clock > 0.0:
		return
	_clock = REFRESH
	refresh()

# Never crowd the neighbours (UI Code measured it at 1280×800): the meter sits below the nightmare
# info when that's showing, and its rows scroll instead of reaching the DriftPanel.
const GAP := 8.0
const BASE_TOP := 40.0  # Offset from the vertical centre, as anchored
func _fit() -> void:
	var hud := get_parent()
	if hud == null:
		return
	var screen_mid := get_viewport_rect().size.y / 2.0
	var top := screen_mid + BASE_TOP
	var info := hud.get_node_or_null("NightmareInfo") as Control
	if info != null and info.visible:
		top = maxf(top, info.get_global_rect().end.y + GAP)
	offset_top = top - screen_mid
	var panel := hud.get_node_or_null("DriftPanel") as Control
	var bottom := panel.get_global_rect().position.y - GAP if panel != null else get_viewport_rect().size.y - 16.0
	var used := _header.size.y + _last.size.y + 32.0 + 28.0  # Header, last drift, tabs, margins (the summary scrolls)
	var room := maxf(bottom - top - used, 72.0)  # At least two rows
	var wanted := _summary.get_combined_minimum_size().y if block_summary else 0.0
	_scroll.custom_minimum_size = Vector2(0, minf(wanted, room))
	# No refresh here: rebuilding the rows every frame swallowed row clicks (the press and the release
	# landed on different buttons). The rows refresh on the clock, in place.

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
	var estimate := show_estimate() and float(b.get("needed_dps", 0.0)) > 0.0
	if estimate:
		head += " · needs ~%s" % fmt(b.needed_dps)
	_header.text = ("▾ " if _body.visible else "▸ ") + head
	_header.add_theme_color_override("font_color", ratio_color(float(b.get("ratio", 1.0))) if estimate else FINE_COLOR)
	# The drift just played: at a rest WardenMeter still holds it as "drift" ("last_drift" rolls when
	# the next one starts); during a drift it's "last_drift".
	var last := m.get_maze_dps("drift" if drift_director.is_resting() else "last_drift")
	_last.visible = last > 0.0
	_last.text = "Last drift %s DPS" % fmt(last)
	if not _body.visible:
		return
	_update_view()
	if block_summary:
		return
	var rows: Array = m.get_meter_rows(period())
	var by_dps := rows.duplicate()
	by_dps.sort_custom(func(a: Dictionary, c: Dictionary) -> bool: return a.dps > c.dps)
	for i in by_dps.size():
		by_dps[i]["rank_color"] = rank_color(i, by_dps.size())
	if sort_by_share:
		rows.sort_custom(func(a: Dictionary, c: Dictionary) -> bool: return a.share > c.share)
	else:
		rows = by_dps
	var more := maxi(rows.size() - TOP_ROWS, 0)
	rows = rows.slice(0, TOP_ROWS)
	_more.visible = more > 0
	_more.text = "and %d more" % more
	# Same Wardens in the same order: update the rows in place (a click mid-refresh still lands).
	var same := _rows.get_child_count() == rows.size()
	for i in rows.size() if same else 0:
		if _rows.get_child(i).get_meta(&"tower", null) != rows[i].tower:
			same = false
			break
	if not same:
		for child in _rows.get_children():
			_rows.remove_child(child)
			child.queue_free()
		for r in rows:
			var button := Button.new()
			_rows.add_child(button)
			_setup_row(button, r)
	for i in rows.size():
		_fill_row(_rows.get_child(i), rows[i])

# Switches between the Wardens and the "Last block" summary (opening the panel if it's closed).
func show_block_summary(on: bool) -> void:
	block_summary = on
	_wardens_tab.set_pressed_no_signal(not on)
	_block_tab.set_pressed_no_signal(on)
	if not _body.visible:
		set_open(true)
	else:
		refresh()
	_update_view()

# Shows the Wardens or the summary (the summary's text is rebuilt only when it changes, so its links
# stay clickable).
func _update_view() -> void:
	_sort.visible = not block_summary
	_rows.visible = not block_summary
	if block_summary:
		_more.visible = false
	_scroll.visible = block_summary
	_summary.visible = block_summary
	if block_summary:
		var text := block_summary_text()
		if _summary.get_meta(&"source", "") != text:
			_summary.set_meta(&"source", text)
			_summary.text = StatusLinks.bbcode(text)

# The last block's summary (RestReport builds it at every rest), or a line saying it comes at the first rest.
func block_summary_text() -> String:
	var report := drift_director.get_node_or_null("%RestReport") as RestReport if drift_director != null else null
	if report == null or report.last_block_text == "":
		return "The block's summary appears here at the first rest."
	return report.last_block_text

# The needed-DPS estimate is a rough balance number: developers only (dev runs; playtest fixes 2026-09-30).
static func show_estimate() -> bool:
	return MetaRun.is_dev_run()

func _setup_row(button: Button, r: Dictionary) -> void:
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_force_pass_scroll_events = false
	button.custom_minimum_size = Vector2(0, 34)
	button.name = "Row"
	var tower = r.tower
	button.set_meta(&"tower", tower)
	if is_instance_valid(tower):
		button.icon = WardenIcon.make(tower.tower_data)
	button.expand_icon = false
	button.add_theme_constant_override("icon_max_width", 26)
	button.add_theme_font_override("font", UiStyle.body_font())  # Data rows: the body face reads best small
	button.add_theme_font_size_override("font_size", 15)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(func() -> void: focus_tower(tower))
	# Its change against its own last drift, at the row's right end.
	var change := Label.new()
	change.name = "Change"
	change.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	change.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	change.offset_right = -6.0
	change.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.number(change, 15, UP_COLOR)
	button.add_child(change)

# "↑12%" (gold) / "↓8%" (dim) against that Warden's own last drift, or "new" if it didn't fight then.
static func row_change(r: Dictionary) -> Array:
	if float(r.get("last_dps", 0.0)) <= 0.0:
		return ["new", FINE_COLOR]
	var change = r.get("change")
	var text := change_text(change)
	if text == "":
		return ["", FINE_COLOR]
	return [text, UP_COLOR if float(change) > 0.0 else UNDERUSED_COLOR]

func _fill_row(button: Button, r: Dictionary) -> void:
	var star := " ★" if r.get("most_improved", false) else ""
	# The Warden's current form (the meter's row keeps the name it was planted with: a grown Sprout
	# read "Sprout" beside its Frostfern icon).
	var tower = r.tower
	var name: String = tower.tower_data.display_name if is_instance_valid(tower) else String(r.name)
	if is_instance_valid(tower) and button.get_meta(&"form", null) != tower.tower_data:
		button.set_meta(&"form", tower.tower_data)
		button.icon = WardenIcon.make(tower.tower_data)
	button.text = "%s  %s DPS · %d%%%s" % [name, fmt(r.dps), roundi(float(r.share) * 100.0), star]
	var change: Array = row_change(r)
	var change_label := button.get_node_or_null("Change") as Label
	if change_label != null:
		change_label.text = change[0]
		change_label.add_theme_color_override("font_color", change[1])
	var colour: Color = r.get("rank_color", FINE_COLOR)  # By rank on the board, like the DPS tags
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, colour)
	var tip := "%s: %s DPS, %d%% of the maze, %s Dew invested" % [name, fmt(r.dps), roundi(float(r.share) * 100.0), fmt(r.dew_invested)]
	if r.get("rating_label", &"") == &"carrying":
		tip += "\nCarrying: far more than its cost."
	elif r.get("rating_label", &"") == &"underused":
		tip += "\nUnderused" + (": " + String(r.reason) if String(r.get("reason", "")) != "" else ".")
	if r.get("most_improved", false):
		tip += "\n★ Most improved"
	button.tooltip_text = tip
