extends PanelContainer
class_name SettingsPanel

# Settings (screens_ui.md "Settings"): tabs Audio, Display (fullscreen, window size, V-sync, UI
# scale), Gameplay, Accessibility (reduced motion, flashes, hit-stop, high-contrast route line),
# Controls (rebinding) and, in debug builds, Developer. Used by the title screen and the pause menu.
# Apply and Cancel (screens_ui.md "Settings", 2026-10-01): changes preview live (HeartwoodMemory.preview_settings)
# but save only on Apply; Cancel drops them and closes, Defaults resets the current tab (still needs Apply).
# A gold dot marks a changed setting and its tab; closing with unapplied changes asks first. Display changes
# that could lock the player out (RISKY) ask "Keep these settings?" after Apply and revert on no answer.

signal closed

# Rebindable keyboard actions and their labels.
const REBINDABLE := [
	["move_camera_up", "Camera up"], ["move_camera_down", "Camera down"],
	["move_camera_left", "Camera left"], ["move_camera_right", "Camera right"],
	["toggle_build_mode", "Build mode"], ["start_drift", "Start / next drift"],
	["pause_game", "Pause"], ["cycle_speed", "Change speed"], ["sell_tower", "Sell Warden"],
	["grow_warden", "Grow selected Warden"], ["nurture_warden", "Nurture selected Warden"],
	["clear_tool", "Clear tool"],
	["grow_option_1", "Grow into 1st option"], ["grow_option_2", "Grow into 2nd option"],
	["grow_option_3", "Grow into 3rd option"],
	["buff_lens", "Buff lens"],
	["cycle_target", "Cycle targeting"],
	["center_heartwood", "Center on the Heartwood"],
	["center_start", "Center on the start"],
]

const TITLE_SCENE := "res://scenes/title.tscn"
const EFFECTS_SETTING := "effects_quality"  # 0 Full (default), 1 Reduced

# Effects quality set to Reduced (read through Fx.setting: cached). Fx's own frame-time step-down is Tower's.
static func effects_reduced() -> bool:
	return int(Fx.setting(EFFECTS_SETTING, 0)) == 1
const VSYNC_SETTING := "vsync"
const WINDOW_SIZE_SETTING := "window_size"  # Index into WINDOW_SIZES (windowed mode)
const WINDOW_SIZES: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1280, 800), Vector2i(1600, 900),
	Vector2i(1920, 1080), Vector2i(2560, 1440)]

static var _display_applied := false  # The window size is set once at startup, then on request

const RISKY := ["fullscreen", WINDOW_SIZE_SETTING, "ui_scale", VSYNC_SETTING]  # Apply asks to keep these
const KEEP_TEXT := "Keep these settings? Reverting in %d s"
# Fullscreen is borderless at the screen's own resolution (Godot never switches the monitor's mode), so the window size
# only applies windowed: greyed with this tip while fullscreen (story chat 2026-10-02: "no silent no-op").
const SIZE_FULLSCREEN_TIP := "Fullscreen uses your screen's resolution; switch to Windowed to choose a size."

var tabs := TabContainer.new()
var revert_seconds := 10.0  # The keep prompt's countdown (tests shorten it)
var apply_button: Button
var cancel_button: Button
var defaults_button: Button
var conflict_label: Label  # Keybind conflicts, shown before Apply
var close_prompt: Control  # "Apply your changes?" Apply · Discard · Keep editing
var keep_prompt: Control  # "Keep these settings?" Keep · Revert
var _settings: Dictionary  # The working copy: previewed, saved on Apply
var _saved: Dictionary  # As saved (when the panel opened, or the last Apply)
var _defaults := {}  # key -> its control's default (for keys HeartwoodMemory.defaults() doesn't list)
var _refreshers := {}  # key -> Callable showing the working value on its control
var _dots := {}  # key -> the gold "changed" dot
var _key_dots := {}  # action -> its dot
var _tab_keys := {}  # tab name -> keys on it
var _building_tab := ""
var _content: Control
var _keep_label: Label
var window_size_pick: OptionButton  # Greyed while fullscreen (SIZE_FULLSCREEN_TIP)
var _revert_to := {}  # The risky keys' values before the Apply the keep prompt asks about
var _revert_at := 0  # Ticks (msec) when the keep prompt reverts; 0 = not counting
var _close_after_keep := false
var _previewed_keys = null  # The keybinds InputMap holds now (null = the saved ones)
var _waiting_action := ""  # Action waiting for a key press
var _key_buttons := {}  # action -> Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	HeartwoodMemory.preview_settings = {}
	_settings = HeartwoodMemory.get_settings()
	custom_minimum_size = Vector2(760, 0)  # All six tabs on one row (user: only 3 showed at 1280×720 virtual)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	add_child(outer)
	_content = outer
	var title := Label.new()
	title.text = "Settings"
	UiStyle.display(title, 24)
	outer.add_child(title)
	# Tabs as in screens_ui.md "Settings" (Language comes with translations).
	tabs.custom_minimum_size = Vector2(0, 380)  # Fits 720 virtual with the title and Back row
	outer.add_child(tabs)

	var audio := _tab("Audio")
	_slider(audio, "Volume", "master_volume")
	_slider(audio, "Music", "music_volume")
	_slider(audio, "Sounds", "sfx_volume")
	_toggle(audio, "Softer nightmares", "softer_nightmares", false, "Quieter shrieks and whispers.")

	var display := _tab("Display")
	_toggle(display, "Fullscreen", "fullscreen")
	window_size_pick = _choice(display, "Window size", WINDOW_SIZE_SETTING,
		WINDOW_SIZES.map(func(s: Vector2i) -> String: return "%d × %d" % [s.x, s.y]), 0)
	_toggle(display, "V-sync", VSYNC_SETTING, true)
	# UI size: a share of the largest scale that fits this window (UiStyle.apply_ui_scale). Largest = as
	# big as the layout allows (1.5× at 1920×1080); the map never zooms with it. A dropdown of presets
	# (UiStyle.UI_SIZES; user, 2026-10-01), not a slider.
	_choice_nearest(display, "UI size", "ui_scale", UiStyle.UI_SIZES, 1.0)
	# Effects quality (platforms.md thinning ladder as a switch; the story chat 2026-10-01: performance shouldn't need the
	# accessibility toggles): Reduced thins particles, bursts, damage numbers, callouts, Kinship pulses and off-screen idle
	# animation. Fx can also step down by itself when frames run long (Tower Code).
	_choice(display, "Effects quality", EFFECTS_SETTING, ["Full", "Reduced"], 0)
	# Placement grid in build mode (Tower Code 0bc2b870, half_cells.md "Placement feel"): whole-cell lines over buildable
	# ground, half lines near the ghost.
	_choice(display, "Placement grid", "placement_grid", ["On", "Near cursor", "Off"], 0)
	_keepsake_toggles(display)

	var gameplay := _tab("Gameplay")
	# Hints (user, 2026-10-01: "update it to hints"; were "Heartwood whispers"): the Heartwood's lines the first time
	# something happens, and under them the Growth marks (GrowHints), so hints live in one place.
	_toggle(gameplay, "Hints", "whispers", true, "The Heartwood's short hints, the first time something happens.")
	var growth_marks := _toggle(gameplay, "Growth marks", GrowHints.SETTING, true, "At rests, a bud on Wardens that can grow now and a dewdrop when a rank is affordable.")
	growth_marks.get_parent().get_child(0).custom_minimum_size.x = 36  # Indented under Hints (its dot holds the space)
	_toggle(gameplay, "Auto-drift on by default", "auto_drift")
	_choice(gameplay, "Damage numbers", "damage_numbers", ["Off", "Big hits", "All"], 0)
	_choice(gameplay, "Warden DPS tags", DpsTags.SETTING, ["Rests only", "Always", "Off"], 0)
	_choice(gameplay, "Rest summary", RestReport.SETTING, ["Off", "On"], 0)  # The block card at rests (else: the meter's Last block tab)
	_toggle(gameplay, "Confirm selling several Wardens during a drift", "confirm_sell", true)
	_toggle(gameplay, "Pause on new combos", ComboFeedback.PAUSE_SETTING, true)
	_toggle(gameplay, "Always show resist / weak pips on nightmares", ResistPips.SETTING, false)
	_choice(gameplay, "Kinship effects", "kinship_effects", ["Full", "Subtle", "Off"], 0)
	# Omens (run_design.md "Ask first"): "ask" at each Omen rest, or "never" = always Clear Skies.
	_choice_values(gameplay, "Omens", OmenDirector.MODE_SETTING, ["Ask each rest", "Never"], ["ask", "never"], "ask")
	_choice(gameplay, "Health bars", "health_bars", ["On hit", "Always"], 0)

	var box := _tab("Accessibility")
	_toggle(box, "Reduced motion", "reduced_motion")
	_toggle(box, "Reduce flashes", "reduce_flashes")
	_toggle(box, "Hit-stop on big hits", "hitstop")
	_toggle(box, "High-contrast route line", RouteLine.SETTING, false)
	_toggle(box, "Outline Deeply Blighted nightmares", "blight_outline", false, "Marks them by shape, not by color alone.")

	var controls := _tab("Controls")
	if TestGrove.is_available():  # Debug builds only; never in the demo or release
		box = _tab("Developer")  # Waits for Apply like every tab (user, 2026-10-01); Demo mode / Dev Grove act then
		_toggle(box, "Test Grove: every Warden unlocked (from the next run)", TestGrove.SETTING)
		_toggle(box, "Unlock all families: normal runs, every family in the picks (no Seeds banked)", MetaRun.ALL_FAMILIES_SETTING,
			false, "As if the Memory Grove's Warden root were fully grown, for this and later runs while on.\nYour real Grove unlocks are not changed.")
		_toggle(box, "Secret 6th loadout slot", MetaRun.SIXTH_SLOT_SETTING,  # meta_design.md: the secret 6th loadout slot, for testing
			false, "For testing: The Heartwood's Crown isn't planted and no Seeds are banked.")
		_toggle(box, "Keep balance snapshots (a copy of each rest's save)", RunSaver.SNAPSHOT_SETTING,
			false, "For Balancing's --from-save: writes to D:\\Projects\\logs\\balancing\\snapshots, the newest 40.\nYour run save is not changed.")
		# Demo mode (demo_scope.md): overrides game/demo in this build (-1 project setting, 0 full, 1 demo); applying a
		# change goes back to the title.
		var demo_row := HBoxContainer.new()
		_dots[ResultsScreen.DEMO_MODE_SETTING] = _dot(demo_row)
		var demo := CheckButton.new()
		demo.text = "Demo mode (off: the full game on your real profile)"  # Short: the switch sits inline, as on every tab
		demo.tooltip_text = "Off = the FULL GAME: the Memory Grove, Blight Levels, and Seeds spent from your real profile.\nOverrides the project's game/demo setting in this debug build only; exported builds always use the project setting.\nApplying a switch returns to the title screen."
		demo.focus_mode = Control.FOCUS_NONE
		demo.toggled.connect(func(on: bool) -> void: _set_value(ResultsScreen.DEMO_MODE_SETTING, 1 if on else 0))
		demo_row.add_child(demo)
		box.add_child(demo_row)
		_register(ResultsScreen.DEMO_MODE_SETTING, -1, func() -> void:
			var mode := int(_value(ResultsScreen.DEMO_MODE_SETTING))
			demo.set_pressed_no_signal(mode == 1 or (mode == -1 and ProjectSettings.get_setting("game/demo", false))))
		# Dev Grove (demo_scope.md): runs and the Memory Grove on a preset profile, never the real one.
		var levels: Array = DevGrove.LEVELS.map(func(level: StringName) -> String: return String(level))
		_choice_values(box, "Dev Grove", DevGrove.SETTING, levels.map(func(level: String) -> String: return level.capitalize()),
			levels, "off")
		var dev_note := Label.new()  # Shown, not a tooltip (touch)
		dev_note.text = "Plays runs and the Memory Grove with that much of the tree unlocked (dev profile; nothing saved to your real profile). The full game while on; applies at the title screen."
		dev_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dev_note.add_theme_font_size_override("font_size", 13)
		dev_note.modulate = Color(1, 1, 1, 0.7)
		box.add_child(dev_note)
		# Grove perks as trade-offs (MetaRun.sidegrade_active): Sidegrade by default since the Spire merge, Power for testing.
		_choice(box, "Perk style", MetaRun.PERK_STYLE_SETTING, ["Power", "Sidegrade"], 1)
		# Capture mode (marketing.md §3): clean frames for recording; scripted scenes use -- --capture=<file>.
		_choice(box, "Capture mode (hides dev tools, DPS tags, damage meter)", CaptureDirector.SETTING, ["Off", "Clean HUD", "No HUD"], 0)
		box.add_child(HSeparator.new())
		box.add_child(_profile_reset_box())

	var keys_title := Label.new()
	keys_title.text = "Keys"
	keys_title.tooltip_text = "Click a key, then press the new one."
	keys_title.mouse_filter = Control.MOUSE_FILTER_PASS
	controls.add_child(keys_title)
	var grid := GridContainer.new()
	grid.columns = 2
	controls.add_child(grid)
	_tab_keys["Controls"] = ["keybinds"]
	_defaults["keybinds"] = {}
	for pair in REBINDABLE:
		var name_row := HBoxContainer.new()
		name_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_key_dots[pair[0]] = _dot(name_row)
		var label := Label.new()
		label.text = pair[1]
		name_row.add_child(label)
		grid.add_child(name_row)
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(140, 0)
		button.pressed.connect(_listen.bind(pair[0]))
		grid.add_child(button)
		_key_buttons[pair[0]] = button
	_refreshers["keybinds"] = _refresh_keys

	conflict_label = Label.new()
	conflict_label.name = "Conflicts"
	conflict_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	conflict_label.add_theme_color_override("font_color", UiStyle.POOR)
	conflict_label.visible = false
	outer.add_child(conflict_label)
	# Footer, always on screen (touch, controller), light pass (UI Asset's last page): "Reset this tab" quiet on the left;
	# Cancel quiet and "Apply and close" the one primary on the right (Esc still asks first when something is unapplied).
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	outer.add_child(row)
	defaults_button = _footer_button(row, "Reset this tab", reset_tab)
	defaults_button.name = "Defaults"
	defaults_button.tooltip_text = "This tab's defaults (Apply to keep them)."
	UiStyle.quiet(defaults_button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	cancel_button = _footer_button(row, "Cancel", cancel)
	cancel_button.tooltip_text = "Closes without saving the changes."
	UiStyle.quiet(cancel_button)
	apply_button = _footer_button(row, "Apply and close", _close_apply)
	apply_button.name = "Apply"
	apply_button.custom_minimum_size.x = 200
	UiStyle.primary(apply_button)
	tabs.tab_changed.connect(func(_index: int) -> void: _mark())

	close_prompt = _prompt("ClosePrompt", "Apply your changes?",
		[["Apply", _close_apply, true], ["Discard", _close_discard, false], ["Keep editing", _hide_prompts, false]])
	keep_prompt = _prompt("KeepPrompt", KEEP_TEXT % int(revert_seconds), [["Keep", keep, true], ["Revert", revert, false]])
	_keep_label = keep_prompt.find_child("Text", true, false)
	visibility_changed.connect(func() -> void:
		if visible:
			_open()
		else:
			_closing())
	_open()

# --- Start over as a new profile (demo_scope.md "Reset to a new profile"; Developer, debug builds) ---

const RESET_WARNING := "This resets your Memory Grove, Seeds, records, discoveries and Codex. Your settings and run history stay."

# The profile becomes a first launch: HeartwoodMemory backs it up, then writes a fresh one with the
# settings kept; the saved run goes too (it belongs to the old profile). Run history and builds stay.
static func start_over() -> void:
	HeartwoodMemory.reset_profile(true)
	if FileAccess.file_exists(RunSaver.file_path):
		DirAccess.remove_absolute(RunSaver.file_path)
	NightmareIntro.session_seen.clear()

# Puts the newest backup back (the current profile is backed up first, so this can be undone too).
static func restore_last() -> bool:
	var path := HeartwoodMemory.latest_backup()
	if path == "":
		return false
	HeartwoodMemory.backup_profile()
	return HeartwoodMemory.restore_backup(path)

func _profile_reset_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = "ProfileReset"
	var start := Button.new()
	start.name = "StartOver"
	start.text = "Start over as a new profile"
	start.focus_mode = Control.FOCUS_NONE
	box.add_child(start)
	var confirm := VBoxContainer.new()  # Step two, in the panel (no pop-up)
	confirm.name = "Confirm"
	confirm.visible = false
	var warning := Label.new()
	warning.text = RESET_WARNING
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirm.add_child(warning)
	var row := HBoxContainer.new()
	var reset := Button.new()
	reset.name = "Reset"
	reset.text = "Reset"
	reset.focus_mode = Control.FOCUS_NONE
	UiStyle.primary(reset)
	row.add_child(reset)
	var cancel := Button.new()
	cancel.name = "Cancel"
	cancel.text = "Cancel"
	cancel.focus_mode = Control.FOCUS_NONE
	row.add_child(cancel)
	confirm.add_child(row)
	box.add_child(confirm)
	var restore := Button.new()
	restore.name = "Restore"
	restore.text = "Restore last backup"
	restore.focus_mode = Control.FOCUS_NONE
	var latest := HeartwoodMemory.latest_backup()
	restore.disabled = latest == ""
	restore.tooltip_text = latest.get_file() if latest != "" else "No backup yet."
	box.add_child(restore)
	start.pressed.connect(func() -> void:
		start.visible = false
		confirm.visible = true)
	cancel.pressed.connect(func() -> void:
		confirm.visible = false
		start.visible = true)
	reset.pressed.connect(func() -> void:
		start_over()
		_to_title())
	restore.pressed.connect(func() -> void:
		if restore_last():
			_to_title())
	return box

# Back to the title, which reads the (new) profile as it starts.
func _to_title() -> void:
	HeartwoodMemory.preview_settings = {}
	RouteLine.reload()
	HeartwoodMemory.apply_settings()
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(TITLE_SCENE)

# A scrollable tab page.
func _tab(title: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = title
	_building_tab = title
	_tab_keys[title] = []
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 8)
	scroll.add_child(page)
	return page

# V-sync, and the window size (windowed only) when `resize` or the first time; also run from
# HeartwoodMemory.apply_settings, which is called on every change, so it only resizes when asked.
static func apply_display(settings: Dictionary, resize: bool = true) -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.get(VSYNC_SETTING, true)
		else DisplayServer.VSYNC_DISABLED)
	resize = resize or not _display_applied
	_display_applied = true
	if resize and not settings.get("fullscreen", false):
		var index := clampi(int(settings.get(WINDOW_SIZE_SETTING, 0)), 0, WINDOW_SIZES.size() - 1)
		var size: Vector2i = WINDOW_SIZES[index]
		var screen := DisplayServer.screen_get_size()
		if screen.x > 0:
			size = size.min(screen)
		DisplayServer.window_set_size(size)
		DisplayServer.window_set_position(DisplayServer.screen_get_position()
			+ (DisplayServer.screen_get_size() - size) / 2)

# --- Controls: each registers its key (tab, default, refresher) and gets a gold "changed" dot ---

func _register(key: String, default, refresh: Callable) -> void:
	_defaults[key] = default
	_refreshers[key] = refresh
	if _building_tab != "":
		_tab_keys[_building_tab].append(key)

# A row with the dot and the setting's name.
func _label_row(text: String, key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = UiStyle.HUD_BUTTON_H  # Light pass: 48 px rows (touch)
	row.add_theme_constant_override("separation", 16)
	_dots[key] = _dot(row)
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(140, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	return row

# The gold dot of a changed setting: always there (no layout jump), shown by its alpha.
func _dot(parent: Control) -> Label:
	var dot := Label.new()
	dot.name = "Dot"
	dot.text = "•"
	dot.custom_minimum_size = Vector2(12, 0)
	dot.add_theme_color_override("font_color", UiStyle.GOLD)
	dot.modulate.a = 0.0  # multiplier
	dot.tooltip_text = "Changed: Apply to keep it."
	parent.add_child(dot)
	return dot

func _choice(box: VBoxContainer, text: String, key: String, options: Array, default: int = 1) -> OptionButton:
	var row := _label_row(text, key)
	var pick := OptionButton.new()
	for option in options:
		pick.add_item(option)
	pick.focus_mode = Control.FOCUS_NONE
	pick.item_selected.connect(func(index: int) -> void: _set_value(key, index))
	row.add_child(pick)
	box.add_child(row)
	_register(key, default, func() -> void: pick.selected = int(_value(key)))
	return pick

func _slider(box: VBoxContainer, text: String, key: String, min_value: float = 0.0,
		max_value: float = 1.0, step: float = 0.05) -> void:
	var row := _label_row(text, key)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Level with its label in the 48 px row
	slider.focus_mode = Control.FOCUS_NONE
	slider.value_changed.connect(func(value: float) -> void: _set_value(key, value))
	row.add_child(slider)
	var shown := Label.new()  # The value on the right, in the number font (a 0–1 slider as 0–100)
	shown.name = "Value"
	shown.custom_minimum_size.x = 44
	shown.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	shown.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiStyle.number(shown, 16)
	row.add_child(shown)
	var show_value := func(value: float) -> void:
		shown.text = str(roundi(value * 100.0)) if max_value <= 1.0 else String.num(value, 2 if step < 1.0 else 0)
	slider.value_changed.connect(show_value)
	box.add_child(row)
	_register(key, max_value, func() -> void:
		slider.set_value_no_signal(float(_value(key)))
		show_value.call(float(_value(key))))

# Keepsakes (meta_design.md, MetaRun.KEEPSAKES): one switch per OWNED keepsake; the setting lists the hidden ones.
# Nothing shows until one is planted in the Memory Grove.
func _keepsake_toggles(box: VBoxContainer) -> void:
	var owned: Array = Array(MetaRun.KEEPSAKES).filter(func(id: String) -> bool: return MetaRun.keepsake_owned(id))
	if owned.is_empty():
		return
	var key := MetaRun.KEEPSAKES_HIDDEN_SETTING
	var heading_row := HBoxContainer.new()
	_dots[key] = _dot(heading_row)
	var heading := Label.new()
	heading.text = "Keepsakes"
	UiStyle.caps(heading, 15)
	heading_row.add_child(heading)
	box.add_child(heading_row)
	var checks := {}
	for id in owned:
		var row := HBoxContainer.new()
		var check := CheckButton.new()
		var unlock := HeartwoodMemory.get_unlock(id)
		check.text = unlock.display_name if unlock != null else String(id).capitalize()
		check.tooltip_text = unlock.description if unlock != null else ""
		check.focus_mode = Control.FOCUS_NONE
		check.toggled.connect(func(on: bool) -> void:
			var hidden: Array = (_value(key) as Array).duplicate()
			hidden.erase(id)
			if not on:
				hidden.append(id)
			_set_value(key, hidden))
		row.add_child(check)
		box.add_child(row)
		checks[id] = check
	_register(key, [], func() -> void:
		for id in checks:
			checks[id].set_pressed_no_signal(not (_value(key) as Array).has(id)))

func _toggle(box: VBoxContainer, text: String, key: String, default: bool = false, tip: String = "") -> CheckButton:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = UiStyle.HUD_BUTTON_H  # Light pass: 48 px rows (touch)
	row.add_theme_constant_override("separation", 12)
	_dots[key] = _dot(row)
	var check := CheckButton.new()
	check.text = text
	check.tooltip_text = tip
	check.focus_mode = Control.FOCUS_NONE
	check.toggled.connect(func(on: bool) -> void: _set_value(key, on))
	row.add_child(check)
	if tip != "" and tip.length() <= 70:  # A short tip reads beside the switch, quiet (a long one stays the tooltip)
		var note := Label.new()
		note.name = "Note"
		note.text = tip
		note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.add_theme_font_size_override("font_size", 13)
		note.add_theme_color_override("font_color", UiStyle.INK_DIM)
		row.add_child(note)
	box.add_child(row)
	_register(key, default, func() -> void: check.set_pressed_no_signal(bool(_value(key))))
	return check
# A dropdown of [name, number] presets for a number setting; the saved value selects the nearest one
# (older saves can hold any number, e.g. from the old slider).
func _choice_nearest(box: VBoxContainer, text: String, key: String, presets: Array, default: float) -> void:
	var row := _label_row(text, key)
	var pick := OptionButton.new()
	for preset in presets:
		pick.add_item(preset[0])
	pick.focus_mode = Control.FOCUS_NONE
	pick.item_selected.connect(func(index: int) -> void: _set_value(key, float(presets[index][1])))
	row.add_child(pick)
	box.add_child(row)
	_register(key, default, func() -> void:
		var saved := float(_value(key))
		var best := 0
		for i in presets.size():
			if absf(float(presets[i][1]) - saved) < absf(float(presets[best][1]) - saved):
				best = i
		pick.selected = best)

# Like _choice, but saves `values[index]` (a string) instead of the index.
func _choice_values(box: VBoxContainer, text: String, key: String, options: Array, values: Array, default: String) -> void:
	var row := _label_row(text, key)
	var pick := OptionButton.new()
	for option in options:
		pick.add_item(option)
	pick.focus_mode = Control.FOCUS_NONE
	pick.item_selected.connect(func(index: int) -> void: _set_value(key, values[index]))
	row.add_child(pick)
	box.add_child(row)
	_register(key, default, func() -> void: pick.selected = maxi(values.find(str(_value(key))), 0))

func _footer_button(row: HBoxContainer, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = text.replace(" ", "")
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(96, UiStyle.HUD_BUTTON_H)
	button.pressed.connect(action)
	row.add_child(button)
	return button

# A question over the panel (no pop-up window): text and a row of [text, action, primary] buttons.
func _prompt(prompt_name: String, text: String, buttons: Array) -> Control:
	var center := CenterContainer.new()
	center.name = prompt_name
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	center.visible = false
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var label := Label.new()
	label.name = "Text"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.display(label, 20)
	box.add_child(label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)
	for spec in buttons:
		var button := _footer_button(row, spec[0], spec[1])
		button.custom_minimum_size = Vector2(120, 48)
		if spec[2]:
			UiStyle.primary(button)
	add_child(center)
	return center

# --- Working copy, preview, Apply / Cancel / Defaults ---

func _value(key: String):
	return _settings.get(key, _default_of(key))

func _default_of(key: String):
	var base: Dictionary = HeartwoodMemory.defaults().settings
	return base[key] if base.has(key) else _defaults.get(key)

# Equal as settings: numbers loosely (JSON reads ints back as floats), arrays and dictionaries by content.
static func same(a, b) -> bool:
	var numbers := [TYPE_INT, TYPE_FLOAT]
	if typeof(a) in numbers and typeof(b) in numbers:
		return is_equal_approx(float(a), float(b))
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for i in a.size():
			if not same(a[i], b[i]):
				return false
		return true
	if a is Dictionary and b is Dictionary:
		for k in a.keys() + b.keys():
			if not same(a.get(k), b.get(k)):
				return false
		return true
	return typeof(a) == typeof(b) and a == b

func is_changed(key: String) -> bool:
	return not same(_settings.get(key, _default_of(key)), _saved.get(key, _default_of(key)))

# Every key with an unapplied change.
func get_changes() -> Array[String]:
	var keys: Array[String] = []
	for key in _refreshers:
		if is_changed(key):
			keys.append(key)
	return keys

func has_changes() -> bool:
	return not get_changes().is_empty()

func _set_value(key: String, value) -> void:
	_settings[key] = value
	_preview(key)
	_mark()

# The working copy goes live everywhere (HeartwoodMemory.get_settings readers, buses, UI scale, keys) unsaved.
func _preview(key: String = "") -> void:
	HeartwoodMemory.preview_settings = _settings.duplicate(true) if has_changes() else {}
	var binds = _settings.get("keybinds", {})
	if _previewed_keys == null or not same(binds, _previewed_keys):
		InputMap.load_from_project_settings()  # Drops rebinds the working copy no longer has
		_previewed_keys = binds.duplicate(true)
	HeartwoodMemory.apply_settings(_settings)
	RouteLine.reload()
	if key == "" or key in [VSYNC_SETTING, WINDOW_SIZE_SETTING, "fullscreen"]:
		apply_display(_settings)
	_refresh_keys()

# Saves the working copy. A risky display change then asks to be kept (and reverts on no answer).
func apply() -> void:
	if not has_changes():
		return
	var before := {}
	for key in RISKY:
		if is_changed(key):
			before[key] = _saved.get(key, _default_of(key))
	var demo_switched := is_changed(ResultsScreen.DEMO_MODE_SETTING)
	var dev_grove_switched := is_changed(DevGrove.SETTING)
	_saved = _settings.duplicate(true)
	HeartwoodMemory.save_settings(_saved.duplicate(true))
	HeartwoodMemory.preview_settings = {}
	_mark()
	if demo_switched:  # Demo mode: back to the title, which starts as the other build
		get_tree().paused = false
		get_tree().change_scene_to_file.call_deferred(TITLE_SCENE)
		return
	if dev_grove_switched:  # On the title it rebuilds on the new profile; mid-run it waits for the title
		var title_node := get_tree().get_first_node_in_group(&"title_screen")
		if title_node and get_tree().current_scene == title_node:
			title_node.refresh()
	if not before.is_empty():
		_ask_keep(before)

# Cancel: drops the unapplied changes and closes (no question: Cancel means discard).
func cancel() -> void:
	_discard()
	_hide_prompts()
	closed.emit()

# Puts back the saved settings.
func _discard() -> void:
	_waiting_action = ""
	_settings = _saved.duplicate(true)
	_preview()
	_refresh_all()
	_mark()

# The current tab's defaults, previewed (Apply keeps them).
func reset_tab() -> void:
	var tab_name := String(tabs.get_current_tab_control().name)
	for key in _tab_keys.get(tab_name, []):
		_settings[key] = _default_of(key)
	_preview()
	_refresh_all()
	_mark()

# Back, Esc: asks first when something is unapplied.
func request_close() -> void:
	if keep_prompt.visible:
		revert()  # No "Keep" given
		return
	_waiting_action = ""
	if has_changes():
		_hide_prompts()
		close_prompt.visible = true
		_content.modulate.a = 0.35  # multiplier
		return
	closed.emit()

func _close_apply() -> void:
	_hide_prompts()
	apply()
	if keep_prompt.visible:
		_close_after_keep = true  # Closes once kept or reverted
	else:
		closed.emit()

func _close_discard() -> void:
	_hide_prompts()
	_discard()
	closed.emit()

func _hide_prompts() -> void:
	close_prompt.visible = false
	keep_prompt.visible = false
	_content.modulate.a = 1.0

func _ask_keep(before: Dictionary) -> void:
	_revert_to = before
	_revert_at = Time.get_ticks_msec() + int(revert_seconds * 1000.0)
	_hide_prompts()
	keep_prompt.visible = true
	_content.modulate.a = 0.35  # multiplier
	_keep_label.text = KEEP_TEXT % ceili(revert_seconds)

func keep() -> void:
	_revert_at = 0
	_revert_to = {}
	_hide_prompts()
	_after_keep()

# The risky keys go back to their values before that Apply (the rest of it stays).
func revert() -> void:
	_revert_at = 0
	for key in _revert_to:
		_saved[key] = _revert_to[key]
		_settings[key] = _revert_to[key]
	_revert_to = {}
	HeartwoodMemory.save_settings(_saved.duplicate(true))
	HeartwoodMemory.preview_settings = {}
	_preview()
	_refresh_all()
	_mark()
	_hide_prompts()
	_after_keep()

func _after_keep() -> void:
	if _close_after_keep:
		_close_after_keep = false
		closed.emit()

func _process(_delta: float) -> void:
	if _revert_at == 0:
		return
	var left := _revert_at - Time.get_ticks_msec()  # Real time: the game may be paused or sped up
	if left <= 0:
		revert()
	else:
		_keep_label.text = KEEP_TEXT % ceili(left / 1000.0)

# Opening: the saved settings, nothing changed.
func _open() -> void:
	HeartwoodMemory.preview_settings = {}
	_saved = HeartwoodMemory.get_settings()
	_settings = _saved.duplicate(true)
	_previewed_keys = null
	_hide_prompts()
	_refresh_all()
	_mark()

# Hidden some other way (the pause menu closing): unapplied changes are dropped, a pending keep reverts.
func _closing() -> void:
	_waiting_action = ""
	if _revert_at != 0:
		revert()
	if has_changes():
		_discard()
	_hide_prompts()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and not _saved.is_empty():
		if _revert_at != 0 or has_changes():
			HeartwoodMemory.preview_settings = {}
			HeartwoodMemory.apply_settings()  # Freed mid-preview (a scene change): the saved settings again
			RouteLine.reload()

func _refresh_all() -> void:
	for key in _refreshers:
		_refreshers[key].call()

# The dots, the tab names' dots, the footer's state and keybind conflicts.
func _mark() -> void:
	if apply_button == null:
		return  # Still building
	for key in _dots:
		_dots[key].modulate.a = 1.0 if is_changed(key) else 0.0  # multiplier
	var saved_binds: Dictionary = _saved.get("keybinds", {})
	var binds: Dictionary = _settings.get("keybinds", {})
	for action in _key_dots:
		_key_dots[action].modulate.a = 0.0 if same(binds.get(action), saved_binds.get(action)) else 1.0  # multiplier
	for i in tabs.get_tab_count():
		var tab_name := String(tabs.get_tab_control(i).name)
		var dirty: bool = _tab_keys.get(tab_name, []).any(func(key: String) -> bool: return is_changed(key))
		tabs.set_tab_title(i, tab_name + (" •" if dirty else ""))
	var fullscreen := bool(_value("fullscreen"))
	window_size_pick.disabled = fullscreen
	window_size_pick.tooltip_text = SIZE_FULLSCREEN_TIP if fullscreen else ""
	var changes := has_changes()
	apply_button.disabled = not changes
	cancel_button.disabled = false  # Cancel always closes
	var current := tabs.get_current_tab_control()
	defaults_button.disabled = current == null or _tab_keys.get(String(current.name), []).is_empty()
	var lines := get_conflict_lines()
	conflict_label.text = "\n".join(lines)
	conflict_label.visible = not lines.is_empty()

# --- Keys ---

func _listen(action: String) -> void:
	_waiting_action = action
	_key_buttons[action].text = "Press a key…"

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if _waiting_action == "":
		# Esc / controller Back closes through the question (before the pause menu sees it).
		if event.is_action_pressed("ui_cancel") or (InputMap.has_action("open_menu") and event.is_action_pressed("open_menu")):
			get_viewport().set_input_as_handled()
			if close_prompt.visible:
				_hide_prompts()  # Esc on the question = Keep editing
			else:
				request_close()
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	get_viewport().set_input_as_handled()
	if key.physical_keycode != KEY_ESCAPE:  # Esc cancels the rebind
		var binds: Dictionary = _settings.get("keybinds", {}).duplicate(true)
		binds[_waiting_action] = [key.physical_keycode]
		_waiting_action = ""
		_set_value("keybinds", binds)
	_waiting_action = ""
	_refresh_keys()

func _refresh_keys() -> void:
	var clashing := {}
	for pair in get_conflicts():
		for action in pair[1]:
			clashing[action] = true
	for action in _key_buttons:
		var names: Array[String] = []
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				names.append(OS.get_keycode_string(_keycode(event)))
		var button: Button = _key_buttons[action]
		if action != _waiting_action:
			button.text = ", ".join(names) if not names.is_empty() else "—"
		if clashing.has(action):
			button.add_theme_color_override("font_color", UiStyle.POOR)
		else:
			button.remove_theme_color_override("font_color")

static func _keycode(event: InputEventKey) -> Key:
	return event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode

# Keys a rebound action shares with another action: [[keycode, [actions]], …] (the project's own shared
# keys, like Esc for cancel and the menu, only count once the player rebinds one of them).
func get_conflicts() -> Array:
	var binds: Dictionary = _settings.get("keybinds", {})
	var by_key := {}
	for action in InputMap.get_actions():
		if String(action).begins_with("ui_"):
			continue
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				var code := _keycode(event)
				if not by_key.has(code):
					by_key[code] = []
				if not by_key[code].has(String(action)):
					by_key[code].append(String(action))
	var found := []
	for code in by_key:
		var actions: Array = by_key[code]
		if actions.size() > 1 and actions.any(func(a: String) -> bool: return binds.has(a)):
			found.append([code, actions])
	return found

func get_conflict_lines() -> Array[String]:
	var lines: Array[String] = []
	for pair in get_conflicts():
		var names: Array[String] = []
		for action in pair[1]:
			names.append(_action_label(action))
		lines.append("%s is used by %s." % [OS.get_keycode_string(pair[0]), " and ".join(names)])
	return lines

static func _action_label(action: String) -> String:
	for pair in REBINDABLE:
		if pair[0] == action:
			return pair[1]
	return action.capitalize()
