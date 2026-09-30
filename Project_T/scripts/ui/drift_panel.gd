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
var _remember_button := Button.new()
var _sapling_button := Button.new()
var _start_button := Button.new()
var _auto_toggle := Button.new()  # A toggle: on = the primary look (ui_style.md)
var _pause_button := Button.new()
var _speed_buttons: Array[Button] = []

func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_END
	add_theme_constant_override("separation", 8)  # The status line keeps clear of Start
	# Status line, with the Remember button (run_design.md "Dreamlight") beside it during rests.
	var status_row := HBoxContainer.new()
	add_child(status_row)
	_remember_button.text = "Remember"
	_remember_button.tooltip_text = "Spend Dreamlight on branches and final forms of your families."
	_remember_button.focus_mode = Control.FOCUS_NONE
	_remember_button.custom_minimum_size = Vector2(0, UiStyle.HUD_BUTTON_H)
	_remember_button.theme_type_variation = &"HudButton"
	_remember_button.pressed.connect(func() -> void: dream_state.open_remember())
	status_row.add_child(_remember_button)
	# The Heartwood Sapling (run_design.md): plant it later if it was declined, or place it if taken.
	_sapling_button.text = "Sapling"
	_sapling_button.tooltip_text = "Plant the Heartwood Sapling: free, 2×2, rooted; yields Dew after every drift."
	_sapling_button.focus_mode = Control.FOCUS_NONE
	_sapling_button.custom_minimum_size = Vector2(0, UiStyle.HUD_BUTTON_H)
	_sapling_button.theme_type_variation = &"HudButton"
	_sapling_button.visible = false
	_sapling_button.pressed.connect(plant_sapling)
	status_row.add_child(_sapling_button)
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_color_override("font_outline_color", UiStyle.FOG)
	_status_label.add_theme_constant_override("outline_size", 5)
	_status_label.add_theme_font_size_override("font_size", 15)
	_status_label.add_theme_color_override("font_color", UiStyle.INK_DIM)
	status_row.add_child(_status_label)
	var edge := Control.new()  # A little room between the status text and the panel's right edge
	edge.custom_minimum_size = Vector2(6, 0)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_row.add_child(edge)

	_start_button.focus_mode = Control.FOCUS_NONE
	# One HUD scale (ui_style.md): the same height and text as every HUD button, in the primary look.
	_start_button.custom_minimum_size = Vector2(272, UiStyle.HUD_BUTTON_H)
	_start_button.theme_type_variation = &"HudPrimary"
	_start_button.pressed.connect(_on_start_pressed)
	add_child(_start_button)

	# Kept compact (screens_ui.md principle 5): Auto-drift shares the speed row.
	var speed_row := HBoxContainer.new()
	speed_row.alignment = BoxContainer.ALIGNMENT_END
	speed_row.add_theme_constant_override("separation", 6)
	add_child(speed_row)
	_auto_toggle.text = "Auto"
	_auto_toggle.toggle_mode = true
	_auto_toggle.custom_minimum_size = Vector2(64, UiStyle.HUD_BUTTON_H)
	_auto_toggle.theme_type_variation = &"HudButton"
	_auto_toggle.tooltip_text = "Auto-drift: drifts in a block start by themselves a few seconds after the last one arrived."
	_auto_toggle.focus_mode = Control.FOCUS_NONE
	_auto_toggle.button_pressed = drift_director.auto_drift
	_auto_toggle.toggled.connect(drift_director.set_auto_drift)
	speed_row.add_child(_auto_toggle)
	_pause_button.text = "II"
	_pause_button.tooltip_text = "Pause (Space). You can still build while paused."
	_pause_button.pressed.connect(game_speed.toggle_pause)
	_add_speed_button(speed_row, _pause_button)
	for speed in game_speed.speeds:
		var button := Button.new()
		button.text = "%d×" % speed
		button.tooltip_text = "Speed %d× (Tab cycles)" % speed
		button.pressed.connect(game_speed.set_speed.bind(speed))
		_add_speed_button(speed_row, button)
		_speed_buttons.append(button)

	game_speed.changed.connect(_on_speed_changed)
	_on_speed_changed(game_speed.paused, game_speed.speed)
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
	row.add_child(button)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("start_drift"):
		_on_start_pressed()  # A waiting choice reopens instead (the director refuses the drift anyway)
		get_viewport().set_input_as_handled()

# The call-early bonus changes every frame as creatures walk, so refresh continuously.
func _process(_delta: float) -> void:
	var latest := drift_director.drifts_started
	var next := latest + 1

	_start_button.disabled = not drift_director.can_start_next_drift()
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
		_status_label.text = "Resting · %d%% refunds" % roundi(tower_seller.build_phase_refund * 100)
		var boss := " · boss" if drift_director.is_boss_drift(next) else ""
		_start_button.text = "Start drift %d%s (Enter)" % [next, boss]
	elif drift_director.can_start_next_drift():
		var countdown := drift_director.get_auto_countdown()
		_status_label.text = "Drift %d in %d s" % [next, ceili(countdown)] if countdown >= 0.0 \
			else "Rest after drift %d" % block_end
		var bonus := drift_director.get_call_early_bonus()
		_start_button.text = "Call drift %d early · +%d Dew" % [next, bonus] if bonus > 0 \
			else "Start drift %d now" % next
	else:
		_status_label.text = "Rest once the field is clear"
		_start_button.text = "Rest after drift %d" % block_end
	# A choice waits (open, or minimised to peek at the map): the button names it and reopens it.
	var pending := drift_director.pending_choice()
	if pending != &"" and not run_state.is_over:
		_start_button.text = PENDING_TEXT[pending]
		var omens := get_tree().get_first_node_in_group(&"omens")
		if pending == &"omen" and omens != null and bool(omens.get("faced")):
			_start_button.text = "Choose an Omen"  # "Face an Omen" was picked: one of its Omens must be chosen
		_start_button.disabled = false

# Screens_ui.md "Choice screens": what the Start button says while a choice waits.
const PENDING_TEXT := {&"family": "Pick a family", &"dream": "Choose a Dream", &"omen": "Face an Omen or Clear Skies"}
const PENDING_SCREENS := {&"family": "FamilyPickScreen", &"dream": "DreamScreen", &"omen": "OmenScreen"}

func _on_start_pressed() -> void:
	var pending := drift_director.pending_choice()
	if pending == &"":
		drift_director.start_next_drift()
		return
	reopen_choice(pending)

# Brings the waiting choice screen back (out of its peek); Enter does the same.
func reopen_choice(pending: StringName) -> void:
	var screen_name := String(PENDING_SCREENS[pending])
	if pending == &"dream" and not dream_state.is_offering():
		screen_name = "RememberScreen"  # A boss rest: the Dream waits behind the Remember screen
	var screen := get_parent().get_node_or_null(screen_name) if get_parent() != null else null
	if screen == null:
		return
	var peek = screen.get("peek")
	if peek != null and peek.peeking:
		peek.set_peeking(false)

func _on_speed_changed(paused: bool, speed: float) -> void:
	_pause_button.set_pressed_no_signal(paused)
	for i in _speed_buttons.size():
		_speed_buttons[i].set_pressed_no_signal(not paused and game_speed.speeds[i] == speed)

