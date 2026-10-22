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
var hidden_by_player := false
var arrow_hidden := false:  # Phones: the HUD's Damage button opens and closes the meter, so its side handle goes (Mobile UI)
	set(value):
		arrow_hidden = value
		if is_instance_valid(_hide_arrow) and value:
			_hide_arrow.visible = false
var _hide_arrow := Button.new()

var drift_director: DriftDirector
var sort_by_share := false
const TOP_ROWS := 5  # The Wardens tab lists the top 5 (screens_ui.md, user playtest)
const UP_COLOR := UiStyle.GOLD  # A row's change vs its own last drift: up gold, down dim
var _more := Label.new()  # "and N more"
var block_summary := false  # The "Last block" tab is showing (not the Wardens)
var _wardens_tab := Button.new()
var _block_tab := Button.new()
var _summary := StatusLinks.make_label("", UiStyle.TIP_SIZE)  # The last block's summary (RestReport's text)
var _ribbon := StrengthRibbon.new()  # The strength gauge's ribbon over it (RestReport.last_gauge)
var _header := Button.new()
var _sort := Button.new()
var _rows := VBoxContainer.new()
var _scroll := ScrollContainer.new()  # The rows scroll when they'd reach the DriftPanel
var _body := VBoxContainer.new()
var _clock := 0.0
var _last := Label.new()  # "Last drift 62 DPS" (moved here from beside Start: playtest fixes 2026-09-30)
var _head_change := Label.new()  # "↑18%" at the header's right
var _vs := Label.new()  # Open: "↑18% vs last drift (45)"
const HEAD_SIZE := 20
const ROW_PORTRAIT := 20
var _was_resting := true  # The meter opens itself at a rest and folds to its one-line plate when a drift starts

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
		return "Last drift %s DPS, drift %d needs ~%s (%d%%)" % [fmt(b.maze_dps), int(b.drift), fmt(b.needed_dps), pct]
	return "Your maze %s DPS, this drift needs ~%s (%d%%)" % [fmt(b.maze_dps), fmt(b.needed_dps), pct]

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
	_hide_arrow.name = "MeterToggle"
	_hide_arrow.focus_mode = Control.FOCUS_NONE
	_hide_arrow.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_hide_arrow.custom_minimum_size = Vector2(HANDLE_TOUCH, HANDLE_TOUCH)
	_hide_arrow.flat = true  # A small handle, not a HUD button (user 2026-10-12): its frame is drawn, 28 px inside a 44 px touch target
	_hide_arrow.draw.connect(_draw_hide_arrow)
	_hide_arrow.mouse_entered.connect(_hide_arrow.queue_redraw)  # Its frame lights on hover
	_hide_arrow.mouse_exited.connect(_hide_arrow.queue_redraw)
	_hide_arrow.pressed.connect(func() -> void: set_hidden(not hidden_by_player))
	get_parent().add_child.call_deferred(_hide_arrow)
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
	# Moon-glass meter (UI Asset fc82d5e8): "Maze 53 DPS" in Vollkorn Medium with the change arrow at its right (Sprig up,
	# Ember down); open, the change on a Mist line under it ("↑18% vs last drift (45)").
	UiStyle.number(_header, HEAD_SIZE, UiStyle.INK)
	_header.tooltip_text = "Drift meter"
	_header.pressed.connect(func() -> void: set_open(not _user_open))
	_head_change.name = "HeadChange"
	_head_change.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	_head_change.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_head_change.offset_right = -4.0
	_head_change.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.number(_head_change, 14, GOOD)
	_header.add_child(_head_change)
	box.add_child(_header)
	_vs.name = "VsLastDrift"
	_vs.add_theme_font_size_override("font_size", 14)
	_vs.add_theme_color_override("font_color", UiStyle.INK_DIM)
	_vs.visible = false
	box.add_child(_vs)
	_last.name = "LastDrift"
	UiStyle.number(_last, 15, UiStyle.INK_DIM)
	_last.visible = false
	box.add_child(_last)
	_body.add_theme_constant_override("separation", 2)
	box.add_child(_body)
	_sort.text = "Sort: DPS"
	_sort.focus_mode = Control.FOCUS_NONE
	_sort.custom_minimum_size = Vector2(0, 32)
	_sort.size_flags_horizontal = Control.SIZE_SHRINK_END
	for state in ["normal", "hover", "pressed", "hover_pressed"]:  # A control: a small plate chip with a ▾ (Moon-glass)
		var chip := UiStyle.plate_box(4.0, 2.0, &"plate_hover" if state == "hover" else &"plate")
		chip.content_margin_right = 14.0  # Room for the ▾
		_sort.add_theme_stylebox_override(state, chip)
	_sort.draw.connect(func() -> void:
		var c := Vector2(_sort.size.x - 8.0, _sort.size.y / 2.0 + 1.0)
		_sort.draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -2), c + Vector2(4, -2), c + Vector2(0, 3)]), UiStyle.INK_DIM))
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
	tabs.add_theme_constant_override("separation", 2)
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
		if UiStyle.is_phone():  # The active tab is a Glow underline, never a framed (primary-looking) box (UI Asset review)
			tab.flat = true
			tab.custom_minimum_size.y = UiStyle.HUD_BUTTON_H
			tab.draw.connect(_draw_tab_underline.bind(tab))
			tab.toggled.connect(func(_on: bool) -> void: tab.queue_redraw())
		if not UiStyle.is_phone():  # Tight side padding: both tabs and the Sort chip fit the meter's WIDTH (opening never widens it)
			tab.ready.connect(func() -> void:
				for state in ["normal", "hover", "pressed", "hover_pressed"]:
					var tight := tab.get_theme_stylebox(state).duplicate() as StyleBox
					tight.content_margin_left = 4.0
					tight.content_margin_right = 4.0
					tab.add_theme_stylebox_override(state, tight))
		tabs.add_child(tab)
	_wardens_tab.set_pressed_no_signal(true)
	var spread := Control.new()  # Sort sits at the tab row's right end
	spread.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(spread)
	tabs.add_child(_sort)
	_body.add_child(tabs)
	# The Wardens tab: the top TOP_ROWS by the current sort, no scrolling (user: the scroll bar didn't
	# work), then "and N more". Only the Last block summary scrolls.
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_child(_rows)
	_more.name = "More"
	_more.add_theme_font_size_override("font_size", 13)  # The normal small style, not caps (story chat)
	_more.add_theme_color_override("font_color", UiStyle.INK_DIM)
	_more.visible = false
	_body.add_child(_more)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_summary.name = "BlockSummary"
	UiStyle.tip_body(_summary, WIDTH - 36.0)
	var summary_box := VBoxContainer.new()  # The strength ribbon, then the summary text (both scroll)
	summary_box.name = "BlockSummaryBox"
	summary_box.add_child(_ribbon)
	summary_box.add_child(_summary)
	_scroll.add_child(summary_box)
	_scroll.visible = false
	_body.add_child(_scroll)
	_user_open = bool(HeartwoodMemory.get_settings().get(OPEN_SETTING, false))
	_body.visible = _user_open
	visible = false
	# The wheel over the panel scrolls its rows, never the map: scroll events a child passes up
	# (Buttons do by default) stop here instead of reaching the camera's zoom.
	for control in [self, _scroll, _rows, _body, _header, _sort]:
		control.mouse_force_pass_scroll_events = false
	mouse_filter = Control.MOUSE_FILTER_STOP

# Phones: the active tab's Glow underline, 2 px, 4 px in from its ends.
func _draw_tab_underline(tab: Button) -> void:
	if tab.button_pressed:
		tab.draw_rect(Rect2(4.0, tab.size.y - 4.0, tab.size.x - 8.0, 2.0), UiStyle.GOLD)

func set_hidden(hidden: bool) -> void:
	hidden_by_player = hidden
	refresh()
	_fit_hide_arrow()

# The hide arrow: a small handle (user 2026-10-12: about 60% of the 48 px HUD button, a lighter frame), HANDLE_SIZE
# drawn in the middle of a HANDLE_TOUCH target (invisible padding, platforms.md). A thin frame and a drawn chevron
# (no font glyph) pointing along its "arrow" meta. The Warden bar's is the same (hud.gd _draw_hide_arrow).
const HANDLE_SIZE := 28.0
const HANDLE_TOUCH := 44.0
func _draw_hide_arrow() -> void:
	var along: Vector2 = _hide_arrow.get_meta(&"arrow", Vector2.RIGHT)
	var centre := (_hide_arrow.size / 2.0).round()
	var frame := Rect2(centre - Vector2(HANDLE_SIZE, HANDLE_SIZE) / 2.0, Vector2(HANDLE_SIZE, HANDLE_SIZE))
	UiStyle.draw_handle(_hide_arrow, frame, along, UiStyle.button_lit(_hide_arrow), UiStyle.button_down(_hide_arrow))  # Moon-glass

func _fit_hide_arrow() -> void:
	if not is_instance_valid(_hide_arrow):
		return
	var arrow := Vector2.LEFT if hidden_by_player else Vector2.RIGHT  # Points where the meter goes
	if _hide_arrow.get_meta(&"arrow", Vector2.ZERO) != arrow:
		_hide_arrow.set_meta(&"arrow", arrow)
		_hide_arrow.tooltip_text = "Show damage meter" if hidden_by_player else "Hide damage meter"
		_hide_arrow.queue_redraw()
	# Beside the meter's left edge, level with its header, never on top: the drawn handle ends HANDLE_GAP (8 px) from the card
	# (its invisible padding may overlap). Hidden meter: at the screen's right edge.
	var pad := (HANDLE_TOUCH - HANDLE_SIZE) / 2.0
	_hide_arrow.offset_right = (-16.0 if hidden_by_player else offset_left - UiStyle.HANDLE_GAP) + pad  # 8 px outside the card
	_hide_arrow.offset_left = _hide_arrow.offset_right - HANDLE_TOUCH
	_hide_arrow.offset_top = offset_top + (36.0 - HANDLE_TOUCH) / 2.0  # Centred on the 36 px header line
	_hide_arrow.offset_bottom = _hide_arrow.offset_top + HANDLE_TOUCH

func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN,
			MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]) or event is InputEventPanGesture or event is InputEventMagnifyGesture:
		accept_event()  # Never reaches the map

func set_open(open: bool) -> void:
	_user_open = open
	if drift_director != null:
		_was_resting = drift_director.is_resting()  # A tap is the choice until the next drift starts or rest begins
	_body.visible = open and not collapsed
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
	_fit_hide_arrow()
	_clock -= delta / maxf(Engine.time_scale, 0.001)
	if _clock > 0.0:
		return
	_clock = REFRESH
	refresh()

# Never crowd the neighbours (UI Code measured it at 1280×800): the meter sits below the nightmare
# info when that's showing, and its rows scroll instead of reaching the DriftPanel.
const GAP := 8.0
const ROW_GUESS := 28.0  # A Warden row's height when none is listed to measure
const BASE_TOP := 40.0  # Offset from the vertical centre, as anchored
const TOP_LIMIT := 200.0  # Highest it may move up to (clear of the resources and the top-right buttons)
const PHONE_STATUS_ROOM := 8.0  # Phones: the drift panel shows no status lines any more (2026-10-18), only a gap
const OPEN_RESERVE := 408.0  # The open card's height with TOP_ROWS rows, "Last drift" and "and N more" (404 at 1280×800)
var _max_rows := TOP_ROWS  # Fewer when the screen is short (_fit)
var _user_open := false  # The player's open / closed choice (the header toggles it)
var collapsed := false  # Header only while the nightmare info shows (tests)
func _fit() -> void:
	var hud := get_parent()
	if hud == null:
		return
	# The nightmare info never closes the meter (user 2026-10-06: "hovering over nightmares closes the DPS meter"): the
	# meter moves below the info and lists fewer rows (the rest in "and N more"), never over the DriftPanel. `collapsed`
	# stays false (it was the header-only fold).
	var collapse := false
	if collapse != collapsed:
		collapsed = collapse
		_body.visible = _user_open and not collapsed
		if collapsed:
			_last.visible = false
		refresh.call_deferred()
	var screen_mid := get_viewport_rect().size.y / 2.0
	var panel := hud.get_node_or_null("DriftPanel") as Control
	var bottom := panel.get_global_rect().position.y - GAP if panel != null else get_viewport_rect().size.y - 16.0
	# The header keeps one place, open or closed (user 2026-10-12: "first clicking the maze DPS bugs out": closed, it
	# sat at the centre line, and opening moved the whole card up to fit its rows, so the header left the pointer).
	# It sits where the open card needs it: OPEN_RESERVE above the DriftPanel, never above TOP_LIMIT or below the
	# old centre line.
	var top := minf(maxf(bottom - OPEN_RESERVE, TOP_LIMIT), screen_mid + BASE_TOP)
	# Phones (arrow_hidden: the HUD's Damage button opens it): it drops down right under that button, and ends above the
	# drift panel's status lines too (user screenshot 2026-10-15: "and N more" sat on "Resting: selling refunds").
	var phone_top := -1.0
	if arrow_hidden:
		var button := hud.get_node_or_null("DamageButton") as Control
		if button != null and button.is_visible_in_tree():
			phone_top = button.get_global_rect().end.y + GAP
			top = phone_top
		bottom -= PHONE_STATUS_ROOM
	var info := hud.get_node_or_null("NightmareInfo") as Control
	if info != null and info.visible:
		top = maxf(top, info.get_global_rect().end.y + GAP)
	offset_top = top - screen_mid
	var used := _header.size.y + _last.size.y + 32.0 + 28.0  # Header, last drift, tabs, margins (the summary scrolls)
	var room := maxf(bottom - top - used, 0.0 if info != null and info.visible else 72.0)  # Two rows, or as few as fit under the info
	var wanted: float = (_summary.get_parent() as Control).get_combined_minimum_size().y if block_summary else 0.0  # The ribbon and the text
	_scroll.custom_minimum_size = Vector2(0, minf(wanted, room))
	# Never over the DriftPanel (user: "maze dps shouldn't go over the call drift"): the whole card
	# (header, tabs, rows, "and N more") moves up into the room above, down to TOP_LIMIT; if it still
	# doesn't fit, it lists fewer Warden rows (the rest go into "and N more").
	var height := get_combined_minimum_size().y
	var info_open := info != null and info.visible
	if not info_open and _max_rows < 1:
		_max_rows = 1  # Rows hidden under the nightmare info come back when it closes (user: "doesn't show the Warden")
	if get_viewport_rect().size.y < UiStyle.LAYOUT_MIN.y * 0.5:
		return  # No real screen (headless stand-in window): nothing to fit into
	if top + height > bottom:
		var highest := phone_top if phone_top >= 0.0 else TOP_LIMIT
		if info != null and info.visible:
			highest = maxf(highest, info.get_global_rect().end.y + GAP)
		top = maxf(bottom - height, highest)
		offset_top = top - screen_mid
		if collapsed and top + height > bottom:  # A tall info box: the header line still stays above the DriftPanel
			top = bottom - height
			offset_top = top - screen_mid
	var row_count := _rows.get_child_count()
	# With no rows listed (all squeezed out under the info) a row's height is guessed, so they can grow back.
	if not block_summary and arrow_hidden and row_count > 0:
		# Phones (user 2026-10-21: "goes from 1 Warden to 5 then back to 1"): the rows that fit, worked out at once from
		# a steady row height and the room the rest of the card leaves (no step up / step down chasing a lagging size).
		var row_h := maxf((_rows.get_child(0) as Control).get_combined_minimum_size().y + float(_rows.get_theme_constant("separation")), 1.0)
		var chrome := height - _rows.get_combined_minimum_size().y
		if not _more.visible:
			chrome += _more.get_combined_minimum_size().y + 4.0  # Counted either way, so "and N more" appearing can't flip the count
		var fit_rows := clampi(floori((bottom - top - chrome) / row_h), 0 if info_open else 1, TOP_ROWS)
		if fit_rows != _max_rows:
			_max_rows = fit_rows
	elif not block_summary and (row_count > 0 or _max_rows < TOP_ROWS):
		var row_h := _rows.size.y / row_count if row_count > 0 else ROW_GUESS
		var spare := bottom - (top + height)
		if spare < 0.0:
			_max_rows = maxi(_max_rows - ceili(-spare / maxf(row_h, 1.0)), 0 if info != null and info.visible else 1)
		elif _max_rows < TOP_ROWS and spare > row_h + 4.0:
			_max_rows += 1
	# No refresh here: rebuilding the rows every frame swallowed row clicks (the press and the release
	# landed on different buttons). The rows refresh on the clock, in place.

func refresh() -> void:
	var m := meter()
	# Never in capture mode (marketing captures): the director hides it each frame, but a refresh after its turn
	# showed it for one frame (Short Form Video).
	var available := m != null and drift_director.drifts_started > 0 and CaptureDirector.hud_mode() == CaptureDirector.Hud.FULL
	# Not while a screen covers the HUD (the family pick, a Dream, Pause…): the HUD hides it each frame, and showing it on
	# the clock here made it blink there (user 2026-10-22: "the maze dps keeps blinking in choosing a family").
	var hud := get_parent()
	if hud != null and hud.has_method("_phone_choice_open") and hud.call("_phone_choice_open"):
		available = false
	_hide_arrow.visible = available and not arrow_hidden
	visible = available and not hidden_by_player
	if not visible:
		return
	# Folded to its one-line plate while a drift walks, open by itself at a rest; a tap opens / folds it in between
	# (UI Asset fc82d5e8).
	var resting := drift_director.is_resting()
	if resting != _was_resting:
		_was_resting = resting
		_user_open = resting
		_body.visible = resting and not collapsed
	var b := m.get_benchmark()
	var head := "Maze %s DPS" % fmt(m.get_maze_dps(period()))
	var estimate := show_estimate() and float(b.get("needed_dps", 0.0)) > 0.0
	if estimate:
		head += "   needs ~%s" % fmt(b.needed_dps)  # Dev runs only
	_header.text = head
	_header.add_theme_color_override("font_color", ratio_color(float(b.get("ratio", 1.0))) if estimate else FINE_COLOR)
	var change = b.get("change")
	var change_line := change_text(change)
	_head_change.text = change_line
	_head_change.add_theme_color_override("font_color", GOOD if change != null and float(change) > 0.0 else SHORT)
	# The drift just played: at a rest WardenMeter still holds it as "drift" ("last_drift" rolls when
	# the next one starts); during a drift it's "last_drift".
	var last := m.get_maze_dps("drift" if drift_director.is_resting() else "last_drift")
	_last.visible = last > 0.0 and not collapsed and _body.visible
	_last.text = "Last drift %s DPS" % fmt(last)
	_vs.visible = change_line != "" and _body.visible and not resting
	_vs.text = "%s vs last drift (%s)" % [change_line, fmt(last)]
	# One box in both looks (folded it is one line of it): swapping boxes moved the header under the pointer, the bug the
	# user hit before ("first clicking the maze DPS bugs out").
	if not _body.visible:
		return
	_update_view()
	if block_summary:
		return
	var rows: Array = m.get_meter_rows(period())
	var by_dps := rows.duplicate()
	by_dps.sort_custom(func(a: Dictionary, c: Dictionary) -> bool: return a.dps > c.dps)
	for i in by_dps.size():
		by_dps[i]["rank_color"] = CARRYING_COLOR if i == 0 else FINE_COLOR  # Only the top Warden is gold (UI Asset fc82d5e8)
		by_dps[i]["top"] = i == 0
	if sort_by_share:
		rows.sort_custom(func(a: Dictionary, c: Dictionary) -> bool: return a.share > c.share)
	else:
		rows = by_dps
	var more := maxi(rows.size() - _max_rows, 0)
	rows = rows.slice(0, _max_rows)
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
			var report := drift_director.get_node_or_null("%RestReport") as RestReport if drift_director != null else null
			_ribbon.set_gauge(report.last_gauge if report != null else {})

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
	button.pressed.connect(func() -> void: focus_tower(tower))
	# Columns (UI Asset fc82d5e8): portrait 20 px, the name (Vollkorn, Moonlight), the DPS right-aligned (tabular), the
	# change arrow small (Sprig up, Ember down); a thin share bar under them (Stone; the top Warden's Glow).
	var cols := HBoxContainer.new()
	cols.name = "Cols"
	cols.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cols.offset_left = 4.0
	cols.offset_right = -4.0
	cols.offset_bottom = -4.0
	cols.add_theme_constant_override("separation", 6)
	cols.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(cols)
	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.custom_minimum_size = Vector2(ROW_PORTRAIT, ROW_PORTRAIT)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(tower):
		portrait.texture = WardenIcon.make(tower.tower_data)
	cols.add_child(portrait)
	var name_label := Label.new()
	name_label.name = "Name"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cols.add_child(name_label)
	var dps := Label.new()
	dps.name = "Dps"
	dps.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dps.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dps.custom_minimum_size.x = 52.0
	dps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.number(dps, 15, UiStyle.INK)
	cols.add_child(dps)
	var change := Label.new()
	change.name = "Change"
	change.custom_minimum_size.x = 40.0
	change.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	change.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	change.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.number(change, 12, GOOD)
	cols.add_child(change)
	var bar := Control.new()
	bar.name = "Share"
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -3.0
	bar.offset_bottom = -1.0
	bar.offset_left = 4.0 + ROW_PORTRAIT + 6.0
	bar.offset_right = -4.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.draw.connect(func() -> void:
		var share := clampf(float(button.get_meta(&"share", 0.0)), 0.0, 1.0)
		bar.draw_rect(Rect2(Vector2.ZERO, bar.size), Color(Palette.DUSK, 0.6))
		bar.draw_rect(Rect2(Vector2.ZERO, Vector2(bar.size.x * share, bar.size.y)),
			Palette.GLOW if button.get_meta(&"top", false) else Palette.STONE))
	button.add_child(bar)

# "↑12%" (gold) / "↓8%" (dim) against that Warden's own last drift, or "new" if it didn't fight then.
static func row_change(r: Dictionary) -> Array:
	if float(r.get("last_dps", 0.0)) <= 0.0:
		return ["new", FINE_COLOR]
	var change = r.get("change")
	var text := change_text(change)
	if text == "":
		return ["", FINE_COLOR]
	return [text, GOOD if float(change) > 0.0 else SHORT]  # Sprig up, Ember down (UI Asset fc82d5e8)

func _fill_row(button: Button, r: Dictionary) -> void:
	var star := " ★" if r.get("most_improved", false) else ""
	# The Warden's current form (the meter's row keeps the name it was planted with: a grown Sprout
	# read "Sprout" beside its Frostfern icon).
	var tower = r.tower
	var name: String = tower.tower_data.display_name if is_instance_valid(tower) else String(r.name)
	var portrait := button.find_child("Portrait", true, false) as TextureRect
	if is_instance_valid(tower) and (not button.has_meta(&"form") or button.get_meta(&"form") != tower.tower_data):  # A null default still warns
		button.set_meta(&"form", tower.tower_data)
		if portrait != null:
			portrait.texture = WardenIcon.make(tower.tower_data)
	var colour: Color = r.get("rank_color", FINE_COLOR)  # Only the top Warden is gold
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, colour)
	var name_label := button.find_child("Name", true, false) as Label
	if name_label != null:
		name_label.text = name + star
		name_label.add_theme_color_override("font_color", colour)
	var dps_label := button.find_child("Dps", true, false) as Label
	if dps_label != null:
		dps_label.text = fmt(r.dps)
		dps_label.add_theme_color_override("font_color", colour)
	var change: Array = row_change(r)
	var change_label := button.find_child("Change", true, false) as Label
	if change_label != null:
		change_label.text = change[0]
		change_label.add_theme_color_override("font_color", change[1])
	button.set_meta(&"share", float(r.share))
	button.set_meta(&"top", bool(r.get("top", false)))
	var bar := button.find_child("Share", true, false) as Control
	if bar != null:
		bar.queue_redraw()
	var tip := "%s: %s DPS, %d%% of the maze, %s invested" % [name, fmt(r.dps), roundi(float(r.share) * 100.0), UiStyle.DEW_GLYPH + fmt(r.dew_invested)]
	if r.get("rating_label", &"") == &"carrying":
		tip += "\nCarrying: far more than its cost."
	elif r.get("rating_label", &"") == &"underused":
		tip += "\nUnderused" + (": " + String(r.reason) if String(r.get("reason", "")) != "" else ".")
	if r.get("most_improved", false):
		tip += "\n★ Most improved"
	button.tooltip_text = tip
