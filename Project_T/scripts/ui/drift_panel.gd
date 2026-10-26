extends VBoxContainer

# Bottom-right run controls: a status line (resting / next drift in N s / rest ahead) with the
# Remember button during rests (Dreamlight: DreamState.open_remember), the Start /
# call-early button (Enter), the Auto-drift toggle, and pause / 1× / 2× / 3× buttons (Space pauses,
# Tab cycles speed). The act / drift line is the top-centre DriftBanner.


@onready var drift_director: DriftDirector = %DriftDirector
@onready var game_speed: GameSpeed = %GameSpeed
@onready var run_state: RunState = %RunState
@onready var tower_seller: TowerSeller = %TowerSeller
@onready var tower_placer = %TowerPlacer  # Untyped: the Sapling API is guarded with has_method

@onready var dream_state: DreamState = %DreamState

var _status_label := Label.new()
var warning_label := Label.new()  # "Flyers in drift 31: they ignore your maze" (tests)
var finale_label := Label.new()  # Spire: "Closing drift (drift 10): clear it clean for a Rare Dream" (tests)
var impatient_label := Label.new()  # Live early-call overlap; no repeated combat particles.
var moonflip_label := Label.new()  # Strange Dreams' Moonflip: "Moonflip +25%" for the block (Roguelite's moonflip_text)
var _warning_key := ""
var _remember_button := Button.new()
var _sapling_button := Button.new()
var _rush_toggle := Button.new()  # Headlong (Legendary): rush the next drift (Roguelite Code's DriftDirector.can_rush / set_rush)
var _start_button := Button.new()
var _start_chip: Label = null  # Its "Enter" chip (UiStyle.key_chip_on, UI council round 3: one hotkey style), at a rest and on Resume
var _speed_row: Control = null
var _key_room := 0.0  # The chip's room last fitted (UiStyle "key_room")
var _auto_toggle := Button.new()  # A toggle: on = the toggled-on look, as the active speed (never the primary; Start is)
var _pause_button := Button.new()
var _speed_buttons: Array[Button] = []
const PHONE_SPEED_SIDE := 60.0  # Phones: II and the speed cycle (a 48 dp target at 1200 x 540 is ~63 px)
const PHONE_SPEED_TEXT := 22
const PHONE_AUTO_TEXT := 15  # (The 13 px phone floor holds)

func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_END
	add_theme_constant_override("separation", 8)  # The status line keeps clear of Start
	# Status line, with the Remember button (run_design.md "Dreamlight") beside it during rests.
	var status_row := HBoxContainer.new()
	add_child(status_row)
	# New rule-breakers in the next block (RuleBreakers): one warning line under the status, at rests
	warning_label.name = "RuleBreakerWarning"
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_label.visible = false
	UiStyle.plain(warning_label, 14, UiStyle.GOLD)
	warning_label.add_theme_color_override("font_outline_color", UiStyle.FOG)
	warning_label.add_theme_constant_override("outline_size", 5)
	add_child(warning_label)
	# Block finales (spire_difficulty.md Phase 2): the block's last drift brings elites; cleared without a leaf lost, a
	# Rare dream waits at the rest. Said before it comes (while resting before the block, and during it).
	finale_label.name = "FinaleLine"
	finale_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	finale_label.visible = false
	UiStyle.plain(finale_label, 14, UiStyle.GOLD)
	finale_label.add_theme_color_override("font_outline_color", UiStyle.FOG)
	finale_label.add_theme_constant_override("outline_size", 5)
	add_child(finale_label)
	moonflip_label.name = "MoonflipLine"
	moonflip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	moonflip_label.visible = false
	UiStyle.plain(moonflip_label, 14, UiStyle.GOLD)
	moonflip_label.add_theme_color_override("font_outline_color", UiStyle.FOG)
	moonflip_label.add_theme_constant_override("outline_size", 5)
	add_child(moonflip_label)
	impatient_label.name = "ImpatientNightLine"
	impatient_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	impatient_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	impatient_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.plain(impatient_label, 14, UiStyle.GOLD)
	impatient_label.add_theme_color_override("font_outline_color", UiStyle.FOG)
	impatient_label.add_theme_constant_override("outline_size", 5)
	add_child(impatient_label)
	drift_director.early_overlap_changed.connect(_refresh_impatient)
	dream_state.card_chosen.connect(func(_card: UpgradeData, _towers: Array, _impact: String) -> void: _refresh_impatient())
	run_state.run_ended.connect(func(_won: bool) -> void: _refresh_impatient())
	_refresh_impatient()
	# No notes over the map (UI Asset fc82d5e8, user 2026-10-21): the finale, Moonflip, warning and Restless Night lines
	# keep working, held in a hidden node (tests still read them); their text is the Start button's tip (_fold_notes).
	_notes_holder.name = "NotesHolder"
	_notes_holder.visible = false
	add_child(_notes_holder)
	for note: Control in [finale_label, moonflip_label, warning_label, impatient_label]:
		note.reparent(_notes_holder, false)
	_remember_button.text = "Remember"
	_remember_button.tooltip_text = "Spend Dreamlight on branches and final forms of your families."
	_remember_button.focus_mode = Control.FOCUS_NONE
	_remember_button.custom_minimum_size = Vector2(0, UiStyle.HUD_BUTTON_H)
	_remember_button.theme_type_variation = &"HudButton"
	_remember_button.pressed.connect(func() -> void: dream_state.open_remember())
	status_row.add_child(_remember_button)
	# The Heartwood Sapling (run_design.md): plant it later if it was declined, or place it if taken.
	_sapling_button.text = "Sapling"
	_sapling_button.tooltip_text = "Plant the Heartwood Sapling: free, 2×2, rooted for good; yields Dew after every drift."
	_sapling_button.focus_mode = Control.FOCUS_NONE
	_sapling_button.custom_minimum_size = Vector2(0, UiStyle.HUD_BUTTON_H)
	_sapling_button.theme_type_variation = &"HudButton"
	_sapling_button.visible = false
	_sapling_button.pressed.connect(plant_sapling)
	status_row.add_child(_sapling_button)
	# Headlong (owner 2026-10-25, dream_council_review.md 36): a per-drift choice, not every drift. On, the next non-boss
	# drift comes in one rush (its shape squeezed to a third of its time) and pays its Dew pot as it starts. The director
	# owns the rule (can_rush, rush_armed, set_rush); the button only arms it and says so.
	_rush_toggle.name = "RushToggle"
	_rush_toggle.text = "Rush"
	_rush_toggle.toggle_mode = true
	_rush_toggle.tooltip_text = "Headlong: the next drift arrives in a third of its time and gives all its Dew as it starts. Not boss drifts."
	_rush_toggle.focus_mode = Control.FOCUS_NONE
	_rush_toggle.custom_minimum_size = Vector2(0, UiStyle.HUD_BUTTON_H)
	_rush_toggle.theme_type_variation = &"HudButton"
	_rush_toggle.visible = false
	_rush_toggle.toggled.connect(_on_rush_toggled)
	_on_look(_rush_toggle)
	status_row.add_child(_rush_toggle)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_color_override("font_outline_color", UiStyle.FOG)
	_status_label.add_theme_constant_override("outline_size", 5)
	_status_label.add_theme_font_size_override("font_size", 15)
	_status_label.add_theme_color_override("font_color", UiStyle.INK_DIM)
	_status_label.mouse_filter = Control.MOUSE_FILTER_PASS  # Its tooltip: the next drift's Dew pot
	if UiStyle.is_phone():  # Body size in Heartlight, not tiny Mist bare on the map (UI Asset review). No fog patch: the
		# label fills the row with its text at the right, so the patch drew a long dark streak left of it (user 2026-10-18)
		_status_label.add_theme_font_size_override("font_size", 16)
		_status_label.add_theme_color_override("font_color", UiStyle.INK)
	status_row.add_child(_status_label)
	var edge := Control.new()  # A little room between the status text and the panel's right edge
	edge.custom_minimum_size = Vector2(6, 0)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_row.add_child(edge)

	_start_button.focus_mode = Control.FOCUS_NONE
	# One HUD scale (ui_style.md): the same height and text as every HUD button, in the primary look.
	_start_button.custom_minimum_size = Vector2(0, UiStyle.HUD_BUTTON_H)  # As wide as the speed row (user): _fit_start
	_start_button.theme_type_variation = &"HudPrimary"
	if UiStyle.is_phone():  # Phones (user 2026-10-21: "too big compared to the pause and Auto"): their face and size, still the primary plate
		_start_button.add_theme_font_override("font", UiStyle.caps_font())
		_start_button.add_theme_font_size_override("font_size", UiStyle.HUD_TEXT_SIZE)
	_start_button.pressed.connect(_on_start_pressed)
	add_child(_start_button)
	_start_chip = UiStyle.key_chip_on(_start_button, "Enter", false)  # _fit_start widens for it

	# Kept compact (screens_ui.md principle 5): Auto-drift shares the speed row.
	var speed_row := HBoxContainer.new()
	speed_row.alignment = BoxContainer.ALIGNMENT_END
	speed_row.add_theme_constant_override("separation", 8 if UiStyle.is_phone() else 6)  # Phones: 8 px between taps
	add_child(speed_row)
	_auto_toggle.text = "Auto-drift"
	_auto_toggle.toggle_mode = true
	_auto_toggle.custom_minimum_size = Vector2(64, UiStyle.HUD_BUTTON_H)
	_auto_toggle.theme_type_variation = &"HudButton"
	_auto_toggle.tooltip_text = "Auto-drift: drifts in a block start by themselves a few seconds after the last one arrived."
	_auto_toggle.focus_mode = Control.FOCUS_NONE
	_auto_toggle.button_pressed = drift_director.auto_drift
	_auto_toggle.toggled.connect(drift_director.set_auto_drift)
	# Says whether it is on, not by colour alone (UI council 2026-10-22: "is Auto on?")
	_auto_toggle.toggled.connect(func(on: bool) -> void: _auto_toggle.text = "Auto-drift on" if on else "Auto-drift")
	_auto_toggle.text = "Auto-drift on" if drift_director.auto_drift else "Auto-drift"
	_on_look(_auto_toggle)
	speed_row.add_child(_auto_toggle)
	_pause_button.text = "II"
	_pause_button.tooltip_text = "Pause%s. You can still build while paused." % UiStyle.key_suffix(InputMode.key(&"pause_game", "Space"))
	_pause_button.pressed.connect(game_speed.toggle_pause)
	_add_speed_button(speed_row, _pause_button)
	if UiStyle.is_phone():  # Phones (user 2026-10-18, the right side congested): one speed button that cycles 1× → 2× → 3×
		_phone_speed = Button.new()
		_phone_speed.tooltip_text = "Speed: tap to cycle 1×, 2×, 3×."
		_phone_speed.pressed.connect(_on_phone_speed)
		_add_speed_button(speed_row, _phone_speed)
	for speed in ([] if UiStyle.is_phone() else game_speed.speeds):
		var button := Button.new()
		button.text = "%d×" % speed
		button.tooltip_text = "Speed %d× (Tab cycles)" % speed
		button.pressed.connect(game_speed.set_speed.bind(speed))
		_add_speed_button(speed_row, button)
		_speed_buttons.append(button)

	if UiStyle.is_phone():
		# Phones (owner 2026-10-26: "pause and speed buttons should be bigger than the auto button"): II and the speed
		# cycle are PHONE_SPEED_SIDE squares in bigger type; Auto stays a HUD_BUTTON_H plate at the row's foot, its words short
		for button in [_pause_button, _phone_speed]:
			button.custom_minimum_size = Vector2(PHONE_SPEED_SIDE, PHONE_SPEED_SIDE)
			button.add_theme_font_size_override("font_size", PHONE_SPEED_TEXT)
		_auto_toggle.size_flags_vertical = Control.SIZE_SHRINK_END
		_auto_toggle.add_theme_font_size_override("font_size", PHONE_AUTO_TEXT)  # Its full words ("Auto-drift on"), a step smaller
		speed_row.add_theme_constant_override("separation", 10)  # Apart enough for thumbs (council: 8 px or more)
	game_speed.changed.connect(_on_speed_changed)
	_on_speed_changed(game_speed.paused, game_speed.speed)
	# Start drift exactly as wide as the Auto / II / speed row, both on the panel's right edge (user: it stuck out)
	_start_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	speed_row.size_flags_horizontal = Control.SIZE_SHRINK_END
	_speed_row = speed_row
	speed_row.minimum_size_changed.connect(_fit_start)
	_fit_start()
	run_state.run_ended.connect(func(_won: bool) -> void: _start_button.visible = false)

# The Sapling was declined (still takeable) or taken but not planted yet.
func _sapling_waiting() -> bool:
	if not tower_placer.has_method("can_take_sapling"):
		return false
	return tower_placer.can_take_sapling() or tower_placer.has_unplanted_sapling()

# Takes the Sapling if it was declined, then selects it to place (TowerPlacer's Sapling API).
func plant_sapling() -> void:
	if tower_placer.can_take_sapling():
		tower_placer.take_sapling()  # Selects it too
	elif tower_placer.has_unplanted_sapling():
		tower_placer.select_tower(tower_placer.sapling)

func _add_speed_button(row: HBoxContainer, button: Button) -> void:
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(44, UiStyle.HUD_BUTTON_H)
	button.theme_type_variation = &"HudButton"
	_on_look(button)
	row.add_child(button)

# A toggle that is on (Auto, the chosen speed, pause): a brass rim with pale text and no glow, so only the next action
# (Start / Call early) is gold and glowing (UI council 2026-10-22: Auto, 1x and Start were three golds side by side).
func _on_look(button: Button) -> void:
	for state in [&"pressed", &"hover_pressed"]:
		button.add_theme_stylebox_override(state, UiStyle.plate_box(10.0, 6.0, &"plate_yours"))
	for state in [&"font_pressed_color", &"font_hover_pressed_color"]:
		button.add_theme_color_override(state, UiStyle.INK)
	# A shape, not only the rim's colour (UI council round 3, accessibility): a short bar under the label while on.
	button.draw.connect(func() -> void: _draw_on_mark(button))
	button.toggled.connect(func(_on: bool) -> void: button.queue_redraw())

func _draw_on_mark(button: Button) -> void:
	if not button.button_pressed:
		return
	var width := minf(18.0, button.size.x - 16.0)
	var y := button.size.y - 9.0
	button.draw_line(Vector2((button.size.x - width) / 2.0, y), Vector2((button.size.x + width) / 2.0, y), UiStyle.GOLD, 2.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start_drift"):
		_on_start_pressed()  # A waiting choice reopens instead (the director refuses the drift anyway)
		get_viewport().set_input_as_handled()

# The call-early bonus changes every frame as creatures walk, so refresh continuously.
func _process(_delta: float) -> void:
	# While a choice screen peeks at the map, its Return pill is the one glow: Start steps down to the plain look
	var look := &"HudButton" if ChoicePeek.any_peeking() or (UiStyle.is_phone() and _start_button.disabled) else &"HudPrimary"  # Phones: a waiting button is plain (council 2026-10-25)
	if _start_button.theme_type_variation != look:
		_start_button.theme_type_variation = look
	_update_warning()
	_update_finale()
	_update_moonflip()
	_update_rush()
	_status_label.tooltip_text = ""
	var latest := drift_director.drifts_started
	var next := latest + 1
	var key_shown := false  # Enter starts the drift (at a rest) or resumes: its chip shows

	# Worked out first and set once at the end (owner 2026-10-26: "Pressing resume when it's paused doesn't resume"): setting
	# disabled true, even for part of a frame, cancels a press in progress, so a tap on Resume or a waiting choice never fired.
	var start_disabled := not drift_director.can_start_next_drift()
	_start_button.tooltip_text = MIST_FULL if drift_director.is_mist_full() else ""
	# Remember moved to the top right (HUD RememberButton, run_design.md); this one stays hidden.
	_remember_button.visible = false
	_sapling_button.visible = drift_director.is_resting() and not drift_director.awaiting_family_pick \
		and latest > 0 and not run_state.is_over and _sapling_waiting()
	var block_end := drift_director.get_block(maxi(latest, 1)) * drift_director.drifts_per_block
	if drift_director.awaiting_family_pick:
		_status_label.text = "Choose a Warden family…"
		_start_button.text = "Start drift %d" % next
	elif not drift_director.has_next_drift():
		_status_label.text = "The last drift is walking"
		_start_button.text = "Final drift"
	elif drift_director.is_resting():
		# Light pass (user-approved): "Resting, 75% refunds"; the drift's Dew pot (run_design.md) moved to the tooltip.
		_status_label.text = "Resting: selling refunds %d%%" % roundi(tower_seller.build_phase_refund * 100)
		_status_label.tooltip_text = "Drift %d pays %s, shared among its nightmares." % [next, UiStyle.dew_amount(roundi(drift_director.get_effective_pot(next)))]
		_start_button.text = ("Start boss drift %d" if drift_director.is_boss_drift(next) else "Start drift %d") % next
		key_shown = true
	elif drift_director.can_start_next_drift():
		var countdown := drift_director.get_auto_countdown()
		_status_label.text = "Drift %d in %d s" % [next, ceili(countdown)] if countdown >= 0.0 \
			else "Rest after drift %d" % block_end
		var bonus := drift_director.get_call_early_bonus()
		_start_button.text = "Call drift %d early, %s" % [next, UiStyle.dew_amount(bonus, true)] if bonus > 0 \
			else "Start drift %d" % next
	elif drift_director.is_mist_full() and drift_director.get_block(next) == drift_director.get_block(latest):
		_status_label.text = "Nightmares still arriving"  # Calling early waits until the queue is out
		_start_button.text = "Start drift %d" % next
	else:
		_status_label.text = "Rest once the field is clear"
		_start_button.text = "Rest after drift %d" % block_end
	if _unconfirmed_wardens():
		_start_button.text = "Confirm your Wardens first"
	if UiStyle.is_phone():  # The status notes step aside while the damage meter or the Warden drawer is open (UI Asset review)
		_status_label.visible = false  # Phones: the big button already says it (user 2026-10-18: "a lot of clutter on the right side")
		_hide_speed_while_building(bool(tower_placer.get("build_mode")))
		# The Warden drawer reaches down over this panel: it steps away while the drawer is open (UI Asset 2026-10-17).
		var drawer := get_parent().get_node_or_null("WardenPanel") as CanvasItem if get_parent() != null else null
		var drawer_open := drawer != null and drawer.visible
		if drawer_open and visible:
			visible = false
			_hidden_for_drawer = true
		elif not drawer_open and _hidden_for_drawer:
			visible = true
			_hidden_for_drawer = false
	# A choice waits (open, or minimised to peek at the map): the button names it and reopens it.
	var pending := drift_director.pending_choice()
	if pending != &"" and not run_state.is_over:
		_start_button.text = PENDING_TEXT[pending]
		var omens := get_tree().get_first_node_in_group(&"omens")
		if pending == &"omen" and omens != null and bool(omens.get("faced")):
			_start_button.text = "Choose an Omen"  # "Face an Omen" was picked: one of its Omens must be chosen
		start_disabled = false
	# Paused mid-drift (user: "it should resume instead of bringing the next drift wave in"): the button only resumes.
	if game_speed.paused and pending == &"" and not drift_director.is_resting() and not run_state.is_over:
		_start_button.text = "Resume"
		start_disabled = false
		key_shown = true
	if _start_button.disabled != start_disabled:
		_start_button.disabled = start_disabled
	if _start_chip != null:
		_start_chip.visible = key_shown and not InputMode.touch()
		if not key_shown:
			_start_button.set_meta(&"key_room", 0.0)
		if not is_equal_approx(float(_start_button.get_meta(&"key_room", 0.0)), _key_room):
			_fit_start()

	# Phones: no Maze bonus line here; the HUD shows the forecast by Dew. The tooltip below still explains the bonus.
	var maze_line: bool = not UiStyle.is_phone()  # Phones: the "+N at rest" sits by the Dew counter, top right, as on PC (user 2026-10-17)
	var maze_percent: int = drift_director.get_maze_pot_percent()  # The maze grows every pot (maze_economy.md 8353f6cc)
	if not run_state.is_over and maze_line and maze_percent > 0:
		_status_label.text += "\nMaze bonus: %s+%d%% a drift" % [UiStyle.DEW_GLYPH, maze_percent]
	if not run_state.is_over:
		_status_label.tooltip_text += "\nMaze bonus: every drift pays +1%% Dew for every %d cells your path is longer than the starting path, up to +%d%%." % [
			DriftDirector.MAZE_ECONOMY.POT_CELLS_PER_PERCENT, roundi(DriftDirector.MAZE_ECONOMY.POT_SHARE_CAP * 100.0)]
	_fold_notes()
	if UiStyle.is_phone():
		_fit_phone_start_text()  # After every text above ("Choose a Dream", "Resume"…)
		_start_button.add_theme_color_override("font_disabled_color", UiStyle.INK_DIM)

# The drift panel holds only Start / Call early and the speed row (UI Asset fc82d5e8): the status line ("Rest after drift
# N", "Resting: selling refunds 75%", "Maze bonus: +N at rest") never shows; the next drift's Dew pot, the maze bonus
# and the held notes (finale, Moonflip, warnings, Restless Night) go into the Start button's tip. The Dew counter's
# "+N at rest" and Sell's tip say the rest.
var _notes_holder := Control.new()
func _fold_notes() -> void:
	_status_label.visible = false
	var lines: Array[String] = []
	if _start_button.tooltip_text != "":
		lines.append(_start_button.tooltip_text)
	for note: Label in [finale_label, moonflip_label, warning_label, impatient_label]:
		if note.visible and note.text.strip_edges() != "":
			lines.append(note.text.strip_edges())
	var about := _status_label.tooltip_text.strip_edges()  # The pot and the maze bonus
	if about != "":
		lines.append(about)
	var tip := "\n\n".join(lines)
	if _start_button.tooltip_text != tip:
		_start_button.tooltip_text = tip

var _hidden_for_drawer := false  # Phones: hidden only because the Warden drawer is open

# Phones (user 2026-10-17: "remove the pause and play while in build mode"): the II and speed buttons hide while
# building (Auto and Start stay); Start keeps the full row's width so it doesn't shrink to Auto's.
var _speed_hidden := false
var _start_min_x := 0.0

# Phones (user 2026-10-21: "the button for calling the drift early should keep the same length… never longer than the
# Auto button to the speed"): the text never widens the button past the Auto / pause / speed row; a long line ("Call
# drift 14 early, +4") steps its size down to START_MIN_SIZE, then clips.
const START_MIN_SIZE := 12
const PAUSE_MENU := preload("res://scripts/ui/pause_menu.gd")  # (No class_name: its dismiss_lessons)

# Phones (user 2026-10-21 screenshot: "Call drift 20 early," lost its Dew; "Rest after drift" its number): the button's
# short wording; the drift number is on the banner above.
static func phone_short(text: String) -> String:
	if text.begins_with("Call drift ") and text.contains(" early, "):
		text = "Call early, " + text.get_slice(" early, ", 1)
	for pair in [["Start boss drift ", "Boss drift "],
			["Confirm your Wardens first", "Confirm Wardens"], ["Choose an Omen", "Omen"]]:
		text = text.replace(pair[0], pair[1])
	return text
var _start_fitted := ""

func _fit_phone_start_text() -> void:
	_start_button.text = phone_short(_start_button.text)
	var key := "%s|%d" % [_start_button.text, int(_start_button.custom_minimum_size.x)]
	if key == _start_fitted:
		return
	_start_fitted = key
	_start_button.clip_text = true  # Its minimum width is the row's, never the text's
	var font := _start_button.get_theme_font("font")
	var box := _start_button.get_theme_stylebox("normal")
	var room := _start_button.custom_minimum_size.x - (box.get_margin(SIDE_LEFT) + box.get_margin(SIDE_RIGHT) if box != null else 16.0)
	var size := UiStyle.HUD_TEXT_SIZE
	while size > START_MIN_SIZE and font.get_string_size(_start_button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > room:
		size -= 1
	_start_button.add_theme_font_size_override("font_size", size)

# Start as wide as the speed row, or what its label and Enter chip need when that is wider.
func _fit_start() -> void:
	_key_room = float(_start_button.get_meta(&"key_room", 0.0))
	var row := _speed_row.get_combined_minimum_size().x if _speed_row != null else 0.0
	_start_button.custom_minimum_size.x = maxf(maxf(row, _start_min_x if _speed_hidden else 0.0), _key_room)

func _hide_speed_while_building(building: bool) -> void:
	if building == _speed_hidden:
		return
	if building:
		_start_min_x = _start_button.custom_minimum_size.x
	_speed_hidden = building
	_pause_button.visible = not building
	for button in _speed_buttons:
		button.visible = not building
	if _phone_speed != null:
		_phone_speed.visible = not building
	# Auto and the drift button too (user 2026-10-17: "still see the auto button and drift button"): building is its own
	# moment; Done (or Confirm) brings them back.
	_auto_toggle.visible = not building
	_start_button.visible = not building and not run_state.is_over

func _phone_panel_open() -> bool:
	var hud := get_parent()
	if hud == null:
		return false
	for panel_name in ["DriftMeter", "WardenPanel"]:
		var panel := hud.get_node_or_null(panel_name) as CanvasItem
		if panel != null and panel.visible:
			return true
	return false

const MIST_FULL := "Nightmares still arriving: the mist holds them back until there is room on the path. You can call the next drift early once they are out."

# Screens_ui.md "Choice screens": what the Start button says while a choice waits.
const PENDING_TEXT := {&"family": "Choose a family", &"dream": "Choose a Dream", &"omen": "Choose an Omen",
	&"gift": "Choose a gift", &"waymark": "Place the Waymark", &"boulders": "Place the boulders"}  # Heartwood's Gifts (Spire); Waymark (Legendary Dream); Forest Floor
const PENDING_SCREENS := {&"family": "FamilyPickScreen", &"dream": "DreamScreen", &"omen": "OmenScreen", &"gift": "GiftScreen"}

# Phones (tap to place, Mobile UI; user 2026-10-15): ghost Wardens waiting for Confirm hold the drift back. Starting one
# now would leave them unplanted (or plant them mid-drift by surprise), so Start asks for Confirm or Cancel first.
func _unconfirmed_wardens() -> bool:
	return bool(tower_placer.get("tap_to_place")) and bool(tower_placer.get("stroking"))

# Start / call early also ends the player's pause (user 2026-10-16: "pausing the game then pressing next drift should
# resume the game"; replaces "paused mid-drift: Resume only"), through GameSpeed so the II button and the pause stay in
# step, at the speed they had (1× / 2× / 3×). The pause menu open: Start does nothing. A choice screen or a Lesson keeps
# its own pause (a waiting choice reopens instead).
func _on_start_pressed() -> void:
	# The button reads "Resume" (paused mid-drift, nothing pending): it only resumes, first, before any other check
	# (user 2026-10-17, phone: "pressing Resume on a pause doesn't resume it": a stale Lesson or ghost Wardens stopped it).
	# No drift start, no ghost check (ghosts stay ghosts); only an open choice screen blocks it.
	if game_speed.paused and drift_director.pending_choice() == &"" and not drift_director.is_resting() and not run_state.is_over:
		if not _choice_screen_open():
			PAUSE_MENU.dismiss_lessons(get_tree())  # An open Lesson is taken as "Got it" (it held the pause: user 2026-10-21)
			game_speed.set_paused(false)
		return
	if _overlay_open(&"pause_menu") or _overlay_open(LessonCard.GROUP):  # (PauseMenu has no class_name: its GROUP)
		return
	if _unconfirmed_wardens():
		var hud := get_parent()
		if hud != null and hud.has_method("show_toast"):
			hud.show_toast("Confirm or cancel your Wardens before the drift starts.")
		return
	var pending := drift_director.pending_choice()
	if pending == &"":
		var was_paused := game_speed.paused
		drift_director.start_next_drift()  # Or a call early mid-drift (the director refuses what it can't start)
		if was_paused:
			game_speed.set_paused(false)
		return
	reopen_choice(pending)

func _overlay_open(group: StringName) -> bool:
	for node in get_tree().get_nodes_in_group(group):  # Only one really on screen (a hidden or dying Lesson doesn't count)
		if node is CanvasItem and is_instance_valid(node) and not node.is_queued_for_deletion() and node.is_visible_in_tree():
			return true
	return false

# A choice screen (Dream / Calling, Omen, family pick, gift) is open on screen.
func _choice_screen_open() -> bool:
	var hud := get_parent()
	for screen_name in PENDING_SCREENS.values():
		var screen := hud.get_node_or_null(String(screen_name)) as CanvasItem if hud != null else null
		if screen != null and screen.is_visible_in_tree():
			return true
	return false

# Brings the waiting choice screen back (out of its peek); Enter does the same.
func reopen_choice(pending: StringName) -> void:
	if pending == &"waymark":  # No screen: the stone's placement on the map opens again
		var stone = drift_director.owner.get_node_or_null("MapGenerator/WaymarkStone") if drift_director.owner != null else null
		if stone != null:
			stone.reopen()
		return
	if pending == &"boulders":  # Forest Floor: no screen either, the boulders' placement opens again
		var boulders = drift_director.owner.get_node_or_null("MapGenerator/BoulderPlacement") if drift_director.owner != null else null
		if boulders != null:
			boulders.reopen()
		return
	var screen_name := String(PENDING_SCREENS[pending])
	if pending == &"dream" and not dream_state.is_offering():
		screen_name = "RememberScreen"  # A boss rest: the Dream waits behind the Remember screen
	var screen := get_parent().get_node_or_null(screen_name) if get_parent() != null else null
	if screen == null:
		return
	var peek = screen.get("peek")
	if peek != null and peek.peeking:
		peek.set_peeking(false)

var _phone_speed: Button = null  # Phones: the one speed button (null on PC)

# Paused: the first tap resumes at the speed shown; running: the next speed.
func _on_phone_speed() -> void:
	if game_speed.paused:
		game_speed.set_speed(game_speed.speed)
	else:
		game_speed.cycle_speed()

func _on_speed_changed(paused: bool, speed: float) -> void:
	if _phone_speed != null:
		_phone_speed.text = "%d×" % roundi(speed)
		_phone_speed.set_pressed_no_signal(not paused)
	_pause_button.set_pressed_no_signal(paused)
	_pause_button.queue_redraw()
	for i in _speed_buttons.size():
		_speed_buttons[i].set_pressed_no_signal(not paused and game_speed.speeds[i] == speed)
		_speed_buttons[i].queue_redraw()  # Its on-mark (_draw_on_mark)


const FINALE_TEXT := "Closing drift (drift %d): clear it clean for a Rare Dream"  # Not "Last drift": that is the previous drift (drift meter, card lines)

# The finale drift ahead in this block (resting: the next block's), or 0 when there's none / it has begun its rest.
static func coming_finale(director: DriftDirector) -> int:
	var at := director.drifts_started + (1 if director.is_resting() else 0)
	var last := director.get_block(maxi(at, 1)) * director.drifts_per_block
	if last < at or not director.has_method("get_block_finale_elites") or director.get_block_finale_elites(last) <= 0:
		return 0
	return last

# Headlong's Rush: shown while the next drift can be rushed (Headlong held, not a boss drift, not started yet); pressed
# while it is armed (the director clears it once that drift starts).
func _update_rush() -> void:
	var can: bool = drift_director.has_method("can_rush") and drift_director.can_rush() and not run_state.is_over
	_rush_toggle.visible = can
	var armed: bool = can and bool(drift_director.get("rush_armed"))
	if _rush_toggle.button_pressed != armed:
		_rush_toggle.set_pressed_no_signal(armed)
		_rush_toggle.queue_redraw()  # Its on-mark
	_rush_toggle.text = "Rush: on" if armed else "Rush"  # Says whether it is on, not by colour alone (as Auto-drift)

func _on_rush_toggled(on: bool) -> void:
	if drift_director.has_method("set_rush"):
		drift_director.set_rush(on)
	_update_rush()

func _update_finale() -> void:
	var finale := coming_finale(drift_director) if not run_state.is_over else 0
	finale_label.visible = finale > 0
	if finale > 0:
		finale_label.text = FINALE_TEXT % finale
		if UiStyle.is_phone():
			finale_label.text = "Clear drift %d clean: Rare Dream" % finale  # Phones: one short line (user 2026-10-18)

# Moonflip (dream_design.md, Strange Dreams): the block's roll, "" without the card; seeded per block, changes at a rest.
func _update_moonflip() -> void:
	var text: String = dream_state.moonflip_text() if dream_state.has_method("moonflip_text") and not run_state.is_over else ""
	moonflip_label.visible = text != ""
	if text != "":
		moonflip_label.text = text.replace(" · ", ", ")  # No " · " (ui_style.md); as written, plain Vollkorn now

# The rule-breaker warning (screens_ui.md "New rule-breaker warning"): rebuilt only when the drift count or
# the rest changes (the scan reads the drift tables).
func _update_warning() -> void:
	var key := "%d:%s:%s" % [drift_director.drifts_started, drift_director.is_resting(), drift_director.awaiting_family_pick]
	if key == _warning_key:
		return
	_warning_key = key
	var lines: Array[String] = []
	if not drift_director.awaiting_family_pick:
		for item in RuleBreakers.coming(drift_director):
			lines.append(RuleBreakers.warning_line(item[0], item[1]))
	warning_label.text = "\n".join(lines)
	warning_label.visible = not lines.is_empty()

# Driven by actual arrivals/resolutions, including split children; no scheduled-only activation.
func _refresh_impatient() -> void:
	impatient_label.visible = not run_state.is_over and dream_state.has_rule(&"restless_night") and drift_director.early_drifts_on_field() >= 2
	impatient_label.text = "Impatient Night +%d%%, early calls overlap" % roundi(DreamState.IMPATIENT_OVERLAP_DAMAGE * 100.0)
	if UiStyle.is_phone():
		impatient_label.text = "Impatient Night +%d%%" % roundi(DreamState.IMPATIENT_OVERLAP_DAMAGE * 100.0)  # Phones: short, no " · "
