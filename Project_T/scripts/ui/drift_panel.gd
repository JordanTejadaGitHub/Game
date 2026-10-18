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
var finale_label := Label.new()  # Spire: "Finale (drift 10): clear it clean for a Rare dream" (tests)
var impatient_label := Label.new()  # Live early-call overlap; no repeated combat particles.
var moonflip_label := Label.new()  # Strange Dreams' Moonflip: "Moonflip +25%" for the block (Roguelite's moonflip_text)
var _warning_key := ""
var _remember_button := Button.new()
var _sapling_button := Button.new()
var _start_button := Button.new()
var _auto_toggle := Button.new()  # A toggle: on = the toggled-on look, as the active speed (never the primary; Start is)
var _pause_button := Button.new()
var _speed_buttons: Array[Button] = []

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
	UiStyle.caps(warning_label, 14, UiStyle.GOLD)
	warning_label.add_theme_color_override("font_outline_color", UiStyle.FOG)
	warning_label.add_theme_constant_override("outline_size", 5)
	add_child(warning_label)
	# Block finales (spire_difficulty.md Phase 2): the block's last drift brings elites; cleared without a leaf lost, a
	# Rare dream waits at the rest. Said before it comes (while resting before the block, and during it).
	finale_label.name = "FinaleLine"
	finale_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	finale_label.visible = false
	UiStyle.caps(finale_label, 14, UiStyle.GOLD)
	finale_label.add_theme_color_override("font_outline_color", UiStyle.FOG)
	finale_label.add_theme_constant_override("outline_size", 5)
	add_child(finale_label)
	moonflip_label.name = "MoonflipLine"
	moonflip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	moonflip_label.visible = false
	UiStyle.caps(moonflip_label, 14, UiStyle.GOLD)
	moonflip_label.add_theme_color_override("font_outline_color", UiStyle.FOG)
	moonflip_label.add_theme_constant_override("outline_size", 5)
	add_child(moonflip_label)
	impatient_label.name = "ImpatientNightLine"
	impatient_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	impatient_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	impatient_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.caps(impatient_label, 14, UiStyle.GOLD)
	impatient_label.add_theme_color_override("font_outline_color", UiStyle.FOG)
	impatient_label.add_theme_constant_override("outline_size", 5)
	add_child(impatient_label)
	drift_director.early_overlap_changed.connect(_refresh_impatient)
	dream_state.card_chosen.connect(func(_card: UpgradeData, _towers: Array, _impact: String) -> void: _refresh_impatient())
	run_state.run_ended.connect(func(_won: bool) -> void: _refresh_impatient())
	_refresh_impatient()
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
	_status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_color_override("font_outline_color", UiStyle.FOG)
	_status_label.add_theme_constant_override("outline_size", 5)
	_status_label.add_theme_font_size_override("font_size", 15)
	_status_label.add_theme_color_override("font_color", UiStyle.INK_DIM)
	_status_label.mouse_filter = Control.MOUSE_FILTER_PASS  # Its tooltip: the next drift's Dew pot
	if UiStyle.is_phone():  # The rest notes on a fog patch at body size, not tiny Mist bare on the map (UI Asset review)
		_status_label.add_theme_font_size_override("font_size", 16)
		_status_label.add_theme_color_override("font_color", UiStyle.INK)
		_status_label.add_theme_stylebox_override("normal", UiStyle.fog_patch(10.0, 4.0))
	status_row.add_child(_status_label)
	var edge := Control.new()  # A little room between the status text and the panel's right edge
	edge.custom_minimum_size = Vector2(6, 0)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_row.add_child(edge)

	_start_button.focus_mode = Control.FOCUS_NONE
	# One HUD scale (ui_style.md): the same height and text as every HUD button, in the primary look.
	_start_button.custom_minimum_size = Vector2(0, UiStyle.HUD_BUTTON_H)  # As wide as the speed row (user): _fit_start
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
	_pause_button.tooltip_text = "Pause%s. You can still build while paused." % UiStyle.key_suffix(InputMode.key(&"pause_game", "Space"))
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
	# Start drift exactly as wide as the Auto / II / speed row, both on the panel's right edge (user: it stuck out)
	_start_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	speed_row.size_flags_horizontal = Control.SIZE_SHRINK_END
	var fit_start := func() -> void: _start_button.custom_minimum_size.x = maxf(speed_row.get_combined_minimum_size().x, _start_min_x if _speed_hidden else 0.0)
	speed_row.minimum_size_changed.connect(fit_start)
	fit_start.call()
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
	# While a choice screen peeks at the map, its Return pill is the one glow: Start steps down to the plain look
	var look := &"HudButton" if ChoicePeek.any_peeking() else &"HudPrimary"
	if _start_button.theme_type_variation != look:
		_start_button.theme_type_variation = look
	_update_warning()
	_update_finale()
	_update_moonflip()
	_status_label.tooltip_text = ""
	var latest := drift_director.drifts_started
	var next := latest + 1

	_start_button.disabled = not drift_director.can_start_next_drift()
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
		_start_button.text = ("Start boss drift %d" if drift_director.is_boss_drift(next) else "Start drift %d") % next + UiStyle.key_suffix("Enter")
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
		_status_label.visible = not _phone_panel_open()
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
		_start_button.disabled = false
	# Paused mid-drift (user: "it should resume instead of bringing the next drift wave in"): the button only resumes.
	if game_speed.paused and pending == &"" and not drift_director.is_resting() and not run_state.is_over:
		_start_button.text = "Resume" + UiStyle.key_suffix("Enter")
		_start_button.disabled = false

	# Phones: no Maze bonus line here; the HUD shows the forecast by Dew. The tooltip below still explains the bonus.
	var maze_line: bool = not UiStyle.is_phone()  # Phones: the "+N at rest" sits by the Dew counter, top right, as on PC (user 2026-10-17)
	if not run_state.is_over and maze_line:
		_status_label.text += "\nMaze bonus: %s at rest" % UiStyle.dew_amount(drift_director.get_maze_reward_projection(), true)
	if not run_state.is_over:
		_status_label.tooltip_text += "\nMaze bonus: %s at each block's rest for every %d cells your path is longer than the starting path. Counted while nightmares walk." % [
			UiStyle.dew_amount(1, true), DriftDirector.MAZE_ECONOMY.CELLS_PER_DEW]

var _hidden_for_drawer := false  # Phones: hidden only because the Warden drawer is open

# Phones (user 2026-10-17: "remove the pause and play while in build mode"): the II and speed buttons hide while
# building (Auto and Start stay); Start keeps the full row's width so it doesn't shrink to Auto's.
var _speed_hidden := false
var _start_min_x := 0.0

func _hide_speed_while_building(building: bool) -> void:
	if building == _speed_hidden:
		return
	if building:
		_start_min_x = _start_button.custom_minimum_size.x
	_speed_hidden = building
	_pause_button.visible = not building
	for button in _speed_buttons:
		button.visible = not building

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
const PENDING_TEXT := {&"family": "Pick a family", &"dream": "Choose a Dream", &"omen": "Face an Omen or Clear Skies",
	&"gift": "Choose a gift"}  # Heartwood's Gifts (Spire)
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
	for node in get_tree().get_nodes_in_group(group):
		if node is CanvasItem and node.is_visible_in_tree():
			return true
	return false

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


const FINALE_TEXT := "Finale (drift %d): clear it clean for a Rare dream"

# The finale drift ahead in this block (resting: the next block's), or 0 when there's none / it has begun its rest.
static func coming_finale(director: DriftDirector) -> int:
	var at := director.drifts_started + (1 if director.is_resting() else 0)
	var last := director.get_block(maxi(at, 1)) * director.drifts_per_block
	if last < at or not director.has_method("get_block_finale_elites") or director.get_block_finale_elites(last) <= 0:
		return 0
	return last

func _update_finale() -> void:
	var finale := coming_finale(drift_director) if not run_state.is_over else 0
	finale_label.visible = finale > 0
	if finale > 0:
		finale_label.text = FINALE_TEXT % finale

# Moonflip (dream_design.md, Strange Dreams): the block's roll, "" without the card; seeded per block, changes at a rest.
func _update_moonflip() -> void:
	var text: String = dream_state.moonflip_text() if dream_state.has_method("moonflip_text") and not run_state.is_over else ""
	moonflip_label.visible = text != ""
	if text != "":
		moonflip_label.text = text.replace(" · ", "  ").to_lower()  # Light pass: no " · "; small caps lower it anyway

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
	impatient_label.text = "Impatient Night +%d%% · early calls overlap" % roundi(DreamState.IMPATIENT_OVERLAP_DAMAGE * 100.0)
