extends Control

# Esc menu during a run (screens_ui.md "Pause"): Resume, Settings, Codex and Quit…, a Heartwood hints toggle, and a run
# summary on the side (drift, Dreams, families, active Omen, time played). Pauses the game while open. Quit… (and the
# window's close button during a run) opens one dialog: Quit to title, Quit to desktop, Cancel, and "Abandon this run…"
# behind a second confirm (Seeds still banked); it says what's saved: right now at a rest, else the last rest's save
# (run_design.md "Mid-run save").
# Esc still cancels build mode / a selection first. Built in code.

const TITLE_SCENE := "res://scenes/title.tscn"
const FAMILY_TIER := 1  # Base Wardens are the families

@onready var game_speed: GameSpeed = %GameSpeed
@onready var run_saver: RunSaver = %RunSaver
@onready var tower_placer: TowerPlacer = %TowerPlacer
@onready var tower_seller: TowerSeller = %TowerSeller
@onready var run_state: RunState = %RunState
@onready var drift_director: DriftDirector = %DriftDirector
@onready var dream_state: DreamState = %DreamState

var _was_paused := false
var _menu := VBoxContainer.new()
var _panel := PanelContainer.new()
var _summary := Label.new()  # The run summary as text (kept for tests and screen readers; hidden)
var _facts := GridContainer.new()  # "This run" as icon rows (light pass): drift, Dreams, Omen, time
var _families := HBoxContainer.new()  # The run's families as their emblems
var _settings: SettingsPanel
var codex: CodexPanel  # The Reaction Codex (screens_ui.md "Reactions")
var _save_button: Button
var _whispers_toggle := CheckButton.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(StatusLinks.CODEX_HOST_GROUP)  # Status links' "More in the Codex"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(UiStyle.FOG, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	if UiStyle.is_phone():
		_build_phone()  # A rail and a page (phones only; the PC keeps the panel below)
		add_to_group(GROUP)
		WorldLabel.cover_while_visible(self, &"pause_menu")
		visible = false
		return
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	center.add_child(row)
	codex = CodexPanel.new()
	codex.visibility_changed.connect(func() -> void:
		if not codex.visible:
			row.visible = true)
	center.add_child(codex)
	# Light pass (UI Asset's second page, user-approved): one panel, two columns. Left: the title, Resume the one
	# primary (Esc), Settings / Codex / Quit… (its dialog holds every way out). Right: "this run"
	# as icon rows, the families' emblems, and the Hints switch at the bottom.
	row.add_child(_panel)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	_panel.add_child(columns)
	_menu.add_theme_constant_override("separation", 8)
	_menu.custom_minimum_size = Vector2(250, 0)
	columns.add_child(_menu)
	var title := Label.new()
	title.text = "Paused"
	UiStyle.display(title, 32)
	_menu.add_child(title)
	var resume := _add_button("Resume", close)
	UiStyle.primary(resume)
	var esc := UiStyle.key_chip("Esc")
	esc.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	esc.offset_left = -44
	esc.offset_right = -14
	resume.add_child(esc)
	_add_button("Settings", _show_settings)
	_add_button("Codex", func() -> void:
		row.visible = false
		codex.open())
	# One way out (user: "Save and quit and Quit game seem similar, also Abandon run"): Quit… asks where to, says what's
	# saved, and keeps Abandon a step further in.
	_save_button = _add_button("Quit…", ask_quit)
	_save_button.name = "Quit"

	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(240, 0)
	side.add_theme_constant_override("separation", 12)
	columns.add_child(side)
	_fill_run_side(side)

	_settings = SettingsPanel.new()
	_settings.visible = false
	_settings.closed.connect(func() -> void:
		_settings.visible = false
		row.visible = true)
	center.add_child(_settings)
	_settings.set_meta("row", row)

	_build_quit_box(center, row)
	add_to_group(GROUP)
	WorldLabel.cover_while_visible(self, &"pause_menu")  # No world tags over the menu
	visible = false

# "This run" (icon rows, the families' emblems), the Lessons switch and Replay lessons: the PC panel's right column, the
# phone menu's first page.
func _fill_run_side(side: VBoxContainer) -> void:
	var head := Label.new()
	head.text = "This run"
	UiStyle.caps(head, 14)
	side.add_child(head)
	_facts.columns = 2
	_facts.add_theme_constant_override("h_separation", 12)
	_facts.add_theme_constant_override("v_separation", 10)
	side.add_child(_facts)
	_families.add_theme_constant_override("separation", 6)
	side.add_child(_families)
	_summary.visible = false
	side.add_child(_summary)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(spacer)
	var hints := HBoxContainer.new()
	hints.custom_minimum_size.y = UiStyle.HUD_BUTTON_H
	var hints_label := Label.new()
	hints_label.text = "Lessons"  # The paused cards (were "Hints", before that "Heartwood whispers")
	hints_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hints_label.add_theme_color_override("font_color", UiStyle.INK_DIM)
	hints.add_child(hints_label)
	_whispers_toggle.focus_mode = Control.FOCUS_NONE
	_whispers_toggle.tooltip_text = "Short lessons the first time a rule matters."
	_whispers_toggle.toggled.connect(_set_whispers)
	hints.add_child(_whispers_toggle)
	side.add_child(hints)
	var guides := Button.new()
	guides.name = "ReplayGuides"
	guides.text = "Replay lessons"
	guides.custom_minimum_size.y = UiStyle.HUD_BUTTON_H
	guides.focus_mode = Control.FOCUS_NONE
	guides.pressed.connect(_replay_guides)
	side.add_child(guides)

func _replay_guides() -> void:
	visible = false
	game_speed.set_paused(_was_paused)
	var lesson := get_tree().get_first_node_in_group(LessonCard.GROUP) as LessonCard
	if lesson != null:
		lesson.replay_guides()

# --- Phones (mobile only; mobile_ui_proto Options.dc.html) ---------------------------------------------------------
# A full-height rail on the left: "Paused", "Drift N of 100 · N leaves", Resume (the primary), the pages This run / Codex
# / Settings as toggles, Save & quit… (the Quit dialog), and "Abandon run…" apart at the foot in ember. The chosen page
# fills the rest: This run (facts, families, Lessons, Replay lessons), the Codex or Settings, each in one solid pane.
const PHONE_RAIL_W := 200.0  # (250 left the Codex's Families tree, 790 wide, past a 1100-wide phone view)
const PHONE_MARGIN := 16
var _phone := false
var _phone_root: HBoxContainer
var _status_line := Label.new()
var _run_page := VBoxContainer.new()
var _pane_buttons := {}  # Page -> its rail toggle
var _pane := &"run"
var _pending_pane := &""  # Settings asked "Apply your changes?" first: the page to show once it closes

func _build_phone() -> void:
	_phone = true
	var margin := MarginContainer.new()
	margin.name = "PhoneLayout"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, PHONE_MARGIN)
	add_child(margin)
	_phone_root = HBoxContainer.new()
	_phone_root.add_theme_constant_override("separation", 12)
	margin.add_child(_phone_root)

	var rail := PanelContainer.new()
	rail.name = "Rail"
	rail.custom_minimum_size.x = PHONE_RAIL_W
	_solid(rail)
	_phone_root.add_child(rail)
	var rail_scroll := ScrollContainer.new()  # Short phones: the rail scrolls rather than leave the screen
	rail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rail.add_child(rail_scroll)
	_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_menu.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_menu.add_theme_constant_override("separation", 8)
	rail_scroll.add_child(_menu)
	var title := Label.new()
	title.text = "Paused"
	UiStyle.display(title, 30)
	_menu.add_child(title)
	_status_line.name = "Status"
	_status_line.add_theme_font_size_override("font_size", 15)
	_status_line.add_theme_color_override("font_color", UiStyle.INK_DIM)
	_menu.add_child(_status_line)
	UiStyle.primary(_add_button("Resume", close))
	for pane in [[&"run", "This run"], [&"codex", "Codex"], [&"settings", "Settings"]]:
		var toggle := _add_button(pane[1], _show_pane.bind(pane[0]))
		toggle.name = "Page" + String(pane[1]).replace(" ", "")
		toggle.toggle_mode = true
		_pane_buttons[pane[0]] = toggle
	_save_button = _add_button("Save & quit…", ask_quit)
	_save_button.name = "Quit"
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_menu.add_child(spacer)
	var abandon := _add_button("Abandon run…", _ask_abandon)
	abandon.name = "AbandonRun"
	_danger(abandon)

	var pane_box := PanelContainer.new()
	pane_box.name = "Pane"
	pane_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_solid(pane_box)
	_phone_root.add_child(pane_box)
	var run_scroll := ScrollContainer.new()
	run_scroll.name = "RunPage"
	run_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pane_box.add_child(run_scroll)
	_run_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_run_page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_run_page.add_theme_constant_override("separation", 12)
	run_scroll.add_child(_run_page)
	_fill_run_side(_run_page)
	codex = CodexPanel.new()
	codex.embedded = true
	pane_box.add_child(codex)
	codex.add_theme_stylebox_override("panel", StyleBoxEmpty.new())  # The pane draws the frame
	codex.visibility_changed.connect(_on_phone_codex_visibility)
	_settings = SettingsPanel.new()
	_settings.visible = false
	pane_box.add_child(_settings)
	_settings.fill_pane()
	_settings.closed.connect(_on_phone_settings_closed)
	_settings.set_meta("row", _phone_root)

	var center := CenterContainer.new()  # The Quit dialog, over everything
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_build_quit_box(center, _phone_root)
	_show_pane(&"run")

# Phones: one page in the pane. Leaving Settings with unapplied changes asks first (Apply / Discard / Keep editing).
func _show_pane(pane: StringName) -> void:
	if _pane == &"settings" and pane != &"settings" and _settings.visible and _settings.has_changes():
		_pending_pane = pane
		_settings.request_close()
		_sync_pane_buttons()
		return
	_pane = pane
	_run_page.get_parent().visible = pane == &"run"
	_settings.visible = pane == &"settings"
	if pane == &"codex":
		if not codex.visible:
			codex.open()
	else:
		codex.visible = false
	_sync_pane_buttons()

func _sync_pane_buttons() -> void:
	for id in _pane_buttons:
		(_pane_buttons[id] as Button).set_pressed_no_signal(id == _pane)

# The Codex's ✕ on a phone: back to This run.
func _on_phone_codex_visibility() -> void:
	if visible and not codex.visible and _pane == &"codex":
		_show_pane(&"run")

func _on_phone_settings_closed() -> void:
	var target := _pending_pane if _pending_pane != &"" else &"run"
	_pending_pane = &""
	_pane = &"run"  # Closed: nothing left to ask about
	_show_pane(target)

func _phone_status() -> String:
	return "Drift %d of %d · %d leaves" % [drift_director.drifts_started, drift_director.get_total_drifts(), run_state.leaves]

# Phones: "Abandon run…" in the rail goes straight to the dialog's second page (still a confirm).
func _ask_abandon() -> void:
	ask_quit()
	_show_abandon()

# --- Quit… (roguelite standard: one dialog for every way out) ----------------------------------------------------
const GROUP := &"pause_menu"
var _quit_box := PanelContainer.new()
var _quit_page := VBoxContainer.new()
var _abandon_page := VBoxContainer.new()
var _quit_body := Label.new()

func _build_quit_box(center: Control, row: Control) -> void:
	_quit_box.name = "QuitBox"
	_quit_box.visible = false
	_quit_box.custom_minimum_size = Vector2(420, 0)
	center.add_child(_quit_box)
	_solid(_quit_box)  # Solid behind the text, like Settings
	_quit_box.set_meta("row", row)
	var pages := VBoxContainer.new()
	_quit_box.add_child(pages)
	for page in [_quit_page, _abandon_page]:
		page.add_theme_constant_override("separation", 10)
		pages.add_child(page)
	var title := Label.new()
	title.text = "Leave the dream?"
	UiStyle.display(title, 28)
	_quit_page.add_child(title)
	_quit_body.name = "Body"
	_quit_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quit_body.custom_minimum_size.x = 380
	_quit_body.add_theme_color_override("font_color", UiStyle.INK_DIM)
	_quit_page.add_child(_quit_body)
	_gap(_quit_page)  # The text never touches the primary's thread
	var to_title := _dialog_button(_quit_page, "Quit to title", _quit_to.bind(false))
	to_title.name = "QuitToTitle"
	UiStyle.primary(to_title)
	_dialog_button(_quit_page, "Quit to desktop", _quit_to.bind(true)).name = "QuitToDesktop"
	var cancel := _dialog_button(_quit_page, "Cancel", cancel_quit)
	cancel.name = "Cancel"
	_key_chip_on(cancel, "Esc")  # Inside its frame, like every key chip
	_quit_page.add_child(HSeparator.new())  # The dangerous one apart
	var abandon_link := _dialog_button(_quit_page, "Abandon this run…", _show_abandon)
	abandon_link.name = "AbandonLink"
	abandon_link.custom_minimum_size.y = 40  # Smaller, framed in POOR
	abandon_link.add_theme_font_size_override("font_size", 14)
	_danger(abandon_link)
	var sure := Label.new()
	sure.text = "End this run?"
	UiStyle.display(sure, 28)
	_abandon_page.add_child(sure)
	var seeds := Label.new()
	seeds.text = "The dream goes dark. The Seeds earned so far are banked."
	seeds.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	seeds.custom_minimum_size.x = 380
	seeds.add_theme_color_override("font_color", UiStyle.INK_DIM)
	_abandon_page.add_child(seeds)
	_gap(_abandon_page)
	var keep := _dialog_button(_abandon_page, "Keep playing", cancel_quit)  # The default: the primary
	keep.name = "KeepPlaying"
	UiStyle.primary(keep)
	var abandon := _dialog_button(_abandon_page, "Abandon", _abandon)
	abandon.name = "Abandon"
	_danger(abandon)

# Dialogs (user: "why are all the buttons different?"): every choice a framed button of one size and font, the default
# the primary, the rest the plain frame; the dangerous one framed in POOR. A 12 px gap under the text, a solid fill.
func _gap(page: Control, height: float = 12.0) -> void:
	var gap := Control.new()
	gap.custom_minimum_size.y = height
	page.add_child(gap)

static func _danger(button: Button) -> void:
	for state in ["normal", "hover", "pressed"]:
		var box := button.get_theme_stylebox(state)
		if box is MoonStyleBox:
			box = (box as MoonStyleBox).duplicate()
			(box as MoonStyleBox).frame_color = Color(UiStyle.POOR, 0.85 if state == "normal" else 1.0)
			button.add_theme_stylebox_override(state, box)
	for state in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, UiStyle.POOR)

static func _solid(panel: PanelContainer) -> void:
	var fill := panel.get_theme_stylebox("panel")
	if fill is MoonStyleBox:
		var solid := (fill as MoonStyleBox).duplicate() as MoonStyleBox
		solid.center_alpha = UiStyle.TIP_ALPHA
		solid.edge_alpha = UiStyle.TIP_ALPHA
		panel.add_theme_stylebox_override("panel", solid)

func _dialog_button(page: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, UiStyle.HUD_BUTTON_H)
	button.pressed.connect(action)
	page.add_child(button)
	return button

func _key_chip_on(button: Button, key: String) -> void:
	var chip := UiStyle.key_chip(key)
	chip.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	chip.offset_left = -44
	chip.offset_right = -14
	button.add_child(chip)

# What leaving keeps: saved right now (at a rest with nothing open), else the last rest's save and what's lost.
func quit_body() -> String:
	if run_saver.can_save_now():
		return "Your run will be saved before you leave. You'll continue from here."
	var drift := RunSaver.saved_drift()
	if drift <= 0:
		return "This run hasn't been saved yet: leaving now loses it."
	return "Your run is saved at the last rest, before drift %d. You'll continue from there; what happened since is lost." % drift

# Quit… (or the window's close button during a run): the dialog over the paused game.
func ask_quit() -> void:
	if not visible:
		open()
	(_quit_box.get_meta("row") as Control).visible = false
	if not _phone:  # Phones: the page stays as it was under the dialog (Cancel comes back to it)
		_settings.visible = false
		codex.visible = false
	_quit_body.text = quit_body()
	_quit_page.visible = true
	_abandon_page.visible = false
	_quit_box.visible = true

func is_asking_quit() -> bool:
	return visible and _quit_box.visible

func cancel_quit() -> void:
	_quit_box.visible = false
	(_quit_box.get_meta("row") as Control).visible = true

func _show_abandon() -> void:
	_quit_page.visible = false
	_abandon_page.visible = true

# Saves first when it can (at a rest with nothing open), then the title or the desktop.
func _quit_to(desktop: bool) -> void:
	if run_saver.can_save_now() and run_saver.autosave:
		if not run_saver.save_now():
			ask_quit()
			_quit_body.text = "The run could not be saved. You're still here. Check that the save folder is writable and has free space, then try again."
			return
	if desktop:
		RunSaver.safe_quit(get_tree())
	else:
		get_tree().change_scene_to_file(TITLE_SCENE)

func _add_button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, UiStyle.HUD_BUTTON_H)  # 48: every button a tap target
	button.pressed.connect(action)
	_menu.add_child(button)
	return button

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("open_menu"):
		return
	if visible and _quit_box.visible:
		cancel_quit()  # Esc = Cancel: back to the menu
	elif visible:
		close()
	elif tower_placer.build_mode or tower_seller.selected != null or run_state.is_over:
		return  # Esc cancels building / deselects first (they handle it)
	else:
		open()
	get_viewport().set_input_as_handled()

func open() -> void:
	_was_paused = game_speed.paused
	game_speed.set_paused(true)
	_whispers_toggle.set_pressed_no_signal(HeartwoodMemory.get_settings().whispers)
	_summary.text = get_run_summary()
	_fill_facts()
	if _phone:
		_status_line.text = _phone_status()
		_phone_root.visible = true
		_show_pane(&"run")
	visible = true

# "This run" (light pass): icon, label, value per row; the families as emblems (their names when there's no art).
func _fill_facts() -> void:
	for child in _facts.get_children() + _families.get_children():
		child.get_parent().remove_child(child)
		child.queue_free()
	var dreams := 0
	for id in dream_state.stacks:
		dreams += dream_state.stacks[id]
	_fact(&"path_length", "drift", "%d of %d" % [drift_director.drifts_started, drift_director.get_total_drifts()])
	_fact(&"rank", "dreams", str(dreams))
	if calling_line() != "":
		_fact(&"", "calling", calling_line())
	var omens := get_tree().get_first_node_in_group(&"omens")
	if omens != null and omens.get("active") != null:
		_fact(&"omen", "omen", omens.active.display_name)
	var seconds := int(run_state.play_time)
	_fact(&"", "time", "%d:%02d:%02d" % [seconds / 3600, seconds / 60 % 60, seconds % 60])
	for data in tower_placer.towers:
		if data.tier == FAMILY_TIER and dream_state.is_unlocked(data.get_id()):
			var art := BranchEmblem.family(data)
			if art == null:
				art = data.texture  # No emblem yet: the base Warden's frame
			var emblem := TextureRect.new()
			if art == data.texture and data.texture != null:
				var frame := AtlasTexture.new()
				frame.atlas = data.texture
				frame.region = data.get_frame_rect(0)
				art = frame
			emblem.texture = art
			emblem.custom_minimum_size = Vector2(32, 32)
			emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			emblem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			emblem.tooltip_text = data.display_name
			_families.add_child(emblem)

func _fact(icon_id: StringName, label: String, value: String) -> void:
	var left := HBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	var art: Texture2D = IconInfo.icon(icon_id) if icon_id != &"" else null
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(16, 16)
	icon.texture = art
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	left.add_child(icon)
	var name_label := Label.new()
	name_label.text = label
	name_label.add_theme_color_override("font_color", UiStyle.INK_DIM)
	left.add_child(name_label)
	_facts.add_child(left)
	var value_label := Label.new()
	value_label.name = "Fact_" + label
	value_label.text = value
	UiStyle.number(value_label, 18)
	_facts.add_child(value_label)

# Opens the pause menu straight on the Codex (the HUD "?" button, a tapped discovery card),
# optionally on a tab and entry (CodexPanel.open).
func open_codex(tab: StringName = &"", entry: String = "") -> void:
	if not visible:
		open()
	if _phone:  # The Codex page beside the rail
		_pane = &"codex"
		_run_page.get_parent().visible = false
		_settings.visible = false
		codex.open(tab, entry)
		_sync_pane_buttons()
		return
	(_settings.get_meta("row") as Control).visible = false
	codex.open(tab, entry)

func close() -> void:
	visible = false
	_settings.visible = false
	_quit_box.visible = false
	codex.visible = false
	(_settings.get_meta("row") as Control).visible = true
	game_speed.set_paused(_was_paused)

# "Lantern Ring (Firefly Jar)": the run's Calling and its family (screens_ui.md "Where to recheck your Calling"), or ""
# when the run has none (dev runs, old saves).
func calling_line() -> String:
	if dream_state == null or dream_state.calling == "" or dream_state.calling_title() == "":
		return ""
	var family := IconInfo.family_data(dream_state.calling)
	return "%s (%s)" % [dream_state.calling_title(), family.display_name if family != null else dream_state.calling.capitalize()]

# Drift, Dreams, families, active Omen and time played, for the side panel.
func get_run_summary() -> String:
	var lines: Array[String] = ["This run"]
	lines.append("Drift %d / %d" % [drift_director.drifts_started, drift_director.get_total_drifts()])
	var dreams := 0
	for id in dream_state.stacks:
		dreams += dream_state.stacks[id]
	lines.append("Dreams taken: %d" % dreams)
	var families: Array[String] = []
	for data in tower_placer.towers:
		if data.tier == FAMILY_TIER and dream_state.is_unlocked(data.get_id()):
			families.append(data.display_name)
	lines.append("Families: %s" % (", ".join(families) if not families.is_empty() else "none yet"))
	if calling_line() != "":
		lines.append("Calling: " + calling_line())
	var omens := get_tree().get_first_node_in_group(&"omens")
	if omens != null and omens.get("active") != null:
		lines.append("Omen: %s" % omens.active.display_name)
	var seconds := int(run_state.play_time)
	lines.append("Time: %d:%02d:%02d" % [seconds / 3600, seconds / 60 % 60, seconds % 60])
	return "\n".join(lines)

func _show_settings() -> void:
	if _phone:
		_show_pane(&"settings")
		return
	(_settings.get_meta("row") as Control).visible = false
	_settings.visible = true

func _set_whispers(on: bool) -> void:
	var settings := HeartwoodMemory.get_settings()
	settings.whispers = on
	HeartwoodMemory.save_settings(settings)
	var whispers := get_node_or_null("%Whispers")
	if whispers != null:
		whispers.set_enabled(on)
	for lesson in get_tree().get_nodes_in_group(LessonCard.GROUP):
		lesson.set_enabled(on)

# Ends the run as a loss (Seeds are still earned: the results screen banks them).
func _abandon() -> void:
	close()
	run_state.abandoned = true
	run_state.end_run(false)
