extends CanvasLayer

const DEW_COLOR := Color(0.7, 0.9, 1.0)
const DEW_SHORT_COLOR := Color(1.0, 0.45, 0.4)
const UNAFFORDABLE_BUTTON_ALPHA := 0.45
# Warden bar buttons (bottom centre): 13 of them must fit between the Warden panel and the drift
# controls at 1280×800 (screens_ui.md principle 6: buttons at least 48 px tall).
const BUTTON_SIZE := Vector2(46, 60)
const BUTTON_MIN_WIDTH := 32.0
# Half-width taken from each side: the Warden panel (16–316 px) or the drift controls (272 px + 16),
# plus a small gap; the wider of the two, so the centred bar clears both.
const BAR_CLEARANCE := 324.0
const SPROUT_ID := "sprout"
const CLEAR_TOOL_GAP := 10.0
const SEED_COLOR := Color(0.6, 0.85, 0.4)

@onready var tower_bar: HBoxContainer = %TowerBar
@onready var tower_placer: TowerPlacer = %TowerPlacer
@onready var dew_label: Label = %DewLabel
@onready var leaves_label: Label = %LeavesLabel
@onready var toast_label: Label = %ToastLabel
@onready var run_state: RunState = %RunState
@onready var drift_director: DriftDirector = %DriftDirector

const LEAVES_COLOR := Color(0.6, 0.9, 0.5)
const DREAMLIGHT_COLOR := Color(1.0, 0.88, 0.55)
const MENU_BUTTON_RIGHT := -284.0  # Left of the Dreamlight counter and the Dew
const LEAF_LOST_COLOR := Color(1.0, 0.6, 0.3)
const TOAST_TIME := 2.5

@onready var dream_state: DreamState = %DreamState
var bark_shield: DreamMarks.BarkShield = null  # Thick Bark (DreamMarks)

# One toggle button per plantable Warden (unlocked this run), in roster order; `_bar_towers` matches.
var _tower_buttons: Array[Button] = []
var _seed_badge: Control = null  # On the Sprout button
var clear_tool: ClearToolButton  # Left of the Warden bar, CLEAR_TOOL_GAP apart
var _bar_towers: Array[TowerData] = []
var _dew_flash: Tween
var _leaf_flash: Tween
var _toast_tween: Tween

func _ready() -> void:
	# The Clear tool sits at the left end of the Warden bar, set apart (screens_ui.md "The Clear tool").
	# (A sibling of %TowerBar, placed and sized with it in _fit_tower_bar.)
	clear_tool = ClearToolButton.new()
	clear_tool.setup(%ObstacleClearer, run_state, show_toast)
	clear_tool.anchor_left = 0.5
	clear_tool.anchor_right = 0.5
	clear_tool.anchor_top = 1.0
	clear_tool.anchor_bottom = 1.0
	add_child(clear_tool)
	_build_tower_bar()
	get_viewport().size_changed.connect(_fit_tower_bar)
	# New Wardens unlocked by Dreams appear in the bar (and prices can change).
	dream_state.unlocks_changed.connect(_build_tower_bar)
	# Keep the buttons in sync when build mode is toggled with B / cancelled with Esc or right-click.
	tower_placer.build_mode_changed.connect(_sync_buttons.unbind(1))

	run_state.sprout_charges_changed.connect(_update_seed_badge)
	run_state.dew_changed.connect(_on_dew_changed)
	run_state.dew_short.connect(_on_dew_short.unbind(1))
	_on_dew_changed(run_state.dew)

	run_state.leaves_changed.connect(_on_leaves_changed)
	_on_leaves_changed(run_state.leaves, run_state.max_leaves)
	_add_dreamlight_counter()
	_add_menu_button()
	# Boss dossier (screens_ui.md): under the pause menu, above the rest of the HUD.
	var dossier := BossDossier.new(drift_director)
	add_child(dossier)
	move_child(dossier, %PauseMenu.get_index())
	# Resist / weak pips and the immune flash, drawn in the world over the nightmares.
	owner.add_child.call_deferred(ResistPips.new())
	# Touch: Plant / Cancel for a pending drag-to-build stroke, two-finger pan and pinch (TouchBuild).
	add_child(TouchBuild.new(tower_placer, owner.get_node_or_null("GameCameraNode")))
	# Dream card marks: Heart of the Maze's heart (world), Thick Bark's shield by the leaves.
	owner.add_child.call_deferred(DreamMarks.new())
	bark_shield = DreamMarks.BarkShield.new(leaves_label)
	leaves_label.add_child(bark_shield)
	if dream_state.has_signal("bark_changed"):
		dream_state.connect("bark_changed", bark_shield.set_charges)
		bark_shield.set_charges.call_deferred(int(dream_state.get("bark_charges")))
	# Every resource explains itself on hover and tap (screens_ui.md "Stat and status icons").
	TapTip.attach(dew_label, IconInfo.resource_tooltip(&"dew"))
	TapTip.attach(leaves_label, IconInfo.resource_tooltip(&"leaves"))
	TapTip.attach(%PathLabel, IconInfo.resource_tooltip(&"path"))
	dream_state.card_taken.connect(func(card: UpgradeData) -> void: show_toast("Dreamed: %s" % card.display_name))
	drift_director.rest_started.connect(_on_rest_started)
	# Path length ("Wardens are walls: make their walk longer").
	var map_generator = %MapGenerator
	var path_label: Label = %PathLabel
	var update_path := func() -> void:
		path_label.text = "Path %d tiles" % map_generator.get_path_from(map_generator.startPath).size()
	map_generator.path_changed.connect(update_path)
	update_path.call()
	drift_director.act_started.connect(_on_act_started)
	# Half-price clears (Heartwood's Reach; clearing always costs Dew), under the path length; hidden when there are none.
	var clears_label := path_label.duplicate() as Label
	clears_label.unique_name_in_owner = false
	clears_label.offset_top = path_label.offset_bottom
	clears_label.offset_bottom = path_label.offset_bottom + (path_label.offset_bottom - path_label.offset_top)
	clears_label.tooltip_text = "Half-price clears: tending a tree or moving a rock costs half (never less than half its base price)."
	add_child(clears_label)
	var update_clears := func(n: int) -> void:
		clears_label.text = "Half-price clears %d" % n
		clears_label.visible = n > 0
	run_state.free_clears_changed.connect(update_clears)
	update_clears.call(run_state.free_clears)
	var spawner = %EnemyContainer
	spawner.enemy_cleansed.connect(func(enemy: Node2D) -> void:
		if enemy.enemy_data.cleanse_line != "":
			show_toast(enemy.enemy_data.cleanse_line))
	spawner.wall_trampled.connect(func(_cell: Vector2, by: Node2D) -> void:
		show_toast("The %s tramples a Thornwall!" % by.enemy_data.display_name))
	toast_label.modulate.a = 0.0

func _unhandled_input(event: InputEvent) -> void:
	# Number keys 1-9 pick a Warden.
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	var index := key.physical_keycode - KEY_1
	if index >= 0 and index < mini(_tower_buttons.size(), 9):
		_on_tower_pressed(_bar_towers[index])
		get_viewport().set_input_as_handled()

func _build_tower_bar() -> void:
	for button in _tower_buttons:
		tower_bar.remove_child(button)
		button.queue_free()
	_tower_buttons.clear()
	_bar_towers = tower_placer.get_buildable_towers()
	for i in _bar_towers.size():
		var data: TowerData = _bar_towers[i]
		# Icon on top, the Dew cost under it, the hotkey number in the top-left corner.
		var button := Button.new()
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.icon = _tower_icon(data)
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.add_theme_constant_override("icon_max_width", 34)
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_color_override("font_color", DEW_COLOR)
		button.custom_minimum_size = BUTTON_SIZE
		button.tooltip_text = "%s (%s)\nCost: %d Dew\n%s" % [data.display_name, str(i + 1) if i < 9 else "no key",
			tower_placer.get_cost(data), data.description]
		button.pressed.connect(_on_tower_pressed.bind(data))
		if i < 9:
			var hotkey := Label.new()
			hotkey.text = str(i + 1)
			hotkey.position = Vector2(3, 0)
			hotkey.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hotkey.add_theme_font_size_override("font_size", 11)
			hotkey.add_theme_color_override("font_color", Color(0.85, 0.88, 0.8))
			hotkey.add_theme_color_override("font_outline_color", Color(0.08, 0.1, 0.14))
			hotkey.add_theme_constant_override("outline_size", 4)
			button.add_child(hotkey)
		if data.get_id() == SPROUT_ID:
			button.add_child(_make_seed_badge())
		tower_bar.add_child(button)
		_tower_buttons.append(button)
	_sync_buttons()
	_on_dew_changed(run_state.dew)
	_update_seed_badge(run_state.sprout_charges)
	_fit_tower_bar()

# The bar is centred at the bottom and must stay clear of the Warden panel (left) and the drift
# controls (right): buttons shrink from BUTTON_SIZE.x down to BUTTON_MIN_WIDTH as Wardens are added
# or the screen gets narrower (screens_ui.md principle 6: still 60 px tall).
func _fit_tower_bar() -> void:
	if _tower_buttons.is_empty():
		return
	var half := get_viewport().get_visible_rect().size.x / 2.0 - BAR_CLEARANCE
	var gap := tower_bar.get_theme_constant("separation")
	# The Clear tool counts as one more button, plus its gap, to the left of the bar.
	var n := _tower_buttons.size() + 1
	var fixed := CLEAR_TOOL_GAP + gap * (n - 2)  # The gap to the tool and the bar's own separations
	var width := clampf(floorf((half * 2.0 - fixed) / n), BUTTON_MIN_WIDTH, BUTTON_SIZE.x)
	for button in _tower_buttons:
		button.custom_minimum_size = Vector2(width, BUTTON_SIZE.y)
		button.add_theme_constant_override("icon_max_width", int(width) - 12)
		if button == _seed_badge_button():
			_seed_badge.position.x = width - 14
	# Centre the tool + bar from the computed widths (the container only re-sorts its children next
	# frame).
	var total := width * n + fixed
	var left := -total / 2.0
	clear_tool.offset_left = left
	clear_tool.offset_right = left + width
	clear_tool.offset_top = tower_bar.offset_top
	clear_tool.offset_bottom = tower_bar.offset_top + BUTTON_SIZE.y
	tower_bar.offset_left = left + width + CLEAR_TOOL_GAP
	tower_bar.offset_right = total / 2.0

func _seed_badge_button() -> Button:
	return _seed_badge.get_parent() as Button if is_instance_valid(_seed_badge) else null

# Seedling Gift (Roguelite's `RunState.sprout_charges`): free Sprouts, shown as a seed with the
# count in the Sprout button's top-right corner; hidden at 0.
func _make_seed_badge() -> Control:
	_seed_badge = Control.new()
	_seed_badge.name = "SeedBadge"
	_seed_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_seed_badge.position = Vector2(BUTTON_SIZE.x - 14, 2)
	_seed_badge.draw.connect(func() -> void:
		_seed_badge.draw_set_transform(Vector2(0, 7), -0.5, Vector2(0.7, 1.0))
		_seed_badge.draw_circle(Vector2.ZERO, 6.0, Color(0.08, 0.1, 0.12))
		_seed_badge.draw_circle(Vector2.ZERO, 4.5, SEED_COLOR)
		_seed_badge.draw_set_transform(Vector2.ZERO)
		var font := ThemeDB.fallback_font
		var text := str(run_state.sprout_charges)
		_seed_badge.draw_string_outline(font, Vector2(-2, 22), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, 4, Color(0.05, 0.06, 0.08))
		_seed_badge.draw_string(font, Vector2(-2, 22), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, SEED_COLOR.lightened(0.3)))
	return _seed_badge

func _update_seed_badge(charges: int) -> void:
	if is_instance_valid(_seed_badge):
		_seed_badge.visible = charges > 0
		_seed_badge.queue_redraw()

# Selecting the tower that's already being built leaves build mode; any other enters it.
func _on_tower_pressed(data: TowerData) -> void:
	if tower_placer.build_mode and tower_placer.tower_data == data:
		tower_placer.set_build_mode(false)
	else:
		tower_placer.select_tower(data)
	_sync_buttons()

func _sync_buttons() -> void:
	for i in _tower_buttons.size():
		var selected := tower_placer.build_mode and _bar_towers[i] == tower_placer.tower_data
		_tower_buttons[i].set_pressed_no_signal(selected)

func _on_dew_changed(dew: int) -> void:
	dew_label.text = "Dew %d" % dew
	# Fade out Wardens the player can't afford right now (still selectable, the ghost shows red).
	# (Costs can change with Dreams, so the cost text is refreshed here too.)
	for i in _tower_buttons.size():
		var cost := tower_placer.get_cost(_bar_towers[i])
		_tower_buttons[i].text = str(cost)
		var affordable := run_state.can_afford(cost)
		_tower_buttons[i].modulate.a = 1.0 if affordable else UNAFFORDABLE_BUTTON_ALPHA

# Tried to spend Dew we don't have: flash the counter red and give it a little shake.
func _on_dew_short() -> void:
	if _dew_flash:
		_dew_flash.kill()
	dew_label.pivot_offset = dew_label.size / 2
	dew_label.add_theme_color_override("font_color", DEW_SHORT_COLOR)
	_dew_flash = create_tween()
	for offset in [-6.0, 6.0, -4.0, 4.0, 0.0]:
		_dew_flash.tween_property(dew_label, "rotation_degrees", offset * 0.5, 0.04)
	_dew_flash.tween_interval(0.25)
	_dew_flash.tween_callback(dew_label.add_theme_color_override.bind("font_color", DEW_COLOR))

# The pause menu on screen (screens_ui.md "Top right: … Menu"; platforms.md: Esc is only a
# shortcut), left of the resources.
func _add_menu_button() -> void:
	var button := Button.new()
	button.name = "MenuButton"
	button.text = "Menu"
	button.tooltip_text = "Pause menu (Esc)"
	button.focus_mode = Control.FOCUS_NONE
	button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	button.offset_left = MENU_BUTTON_RIGHT - 84
	button.offset_right = MENU_BUTTON_RIGHT
	button.offset_top = 12
	button.offset_bottom = 60
	button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	button.pressed.connect(func() -> void:
		var pause := get_node_or_null("%PauseMenu")
		if pause != null and not pause.visible and not run_state.is_over:
			pause.open())
	add_child(button)
	# The Codex ("?", screens_ui.md "The Codex"), just left of Menu.
	var codex := button.duplicate() as Button
	codex.name = "CodexButton"
	codex.text = "?"
	codex.tooltip_text = "Codex: glossary and combos"
	codex.offset_right = button.offset_left - 8
	codex.offset_left = codex.offset_right - 48
	codex.pressed.connect(func() -> void:
		var pause := get_node_or_null("%PauseMenu")
		if pause != null and not run_state.is_over:
			pause.open_codex())
	add_child(codex)

# Dreamlight (run_design.md "Dreamlight"): a glowing mote and the count, just left of the Dew.
func _add_dreamlight_counter() -> void:
	var label := dew_label.duplicate() as Label
	label.unique_name_in_owner = false
	label.name = "DreamlightLabel"
	label.offset_right = dew_label.offset_right - 150
	label.offset_left = label.offset_right - 110
	label.add_theme_color_override("font_color", DREAMLIGHT_COLOR)
	label.mouse_filter = Control.MOUSE_FILTER_STOP
	label.tooltip_text = IconInfo.resource_tooltip(&"dreamlight")
	# Tap / click says the same as the tooltip (platforms.md: no hover-only information).
	label.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			show_toast("%s (you have %d)" % [IconInfo.resource_tooltip(&"dreamlight"), dream_state.dreamlight]))
	add_child(label)
	var mote := Control.new()
	mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mote.draw.connect(func() -> void:
		mote.draw_circle(Vector2.ZERO, 9.0, Color(DREAMLIGHT_COLOR, 0.25))
		mote.draw_circle(Vector2.ZERO, 5.0, DREAMLIGHT_COLOR)
		mote.draw_circle(Vector2.ZERO, 2.0, Color.WHITE))
	label.add_child(mote)
	var update := func(amount: int) -> void:
		label.text = str(amount)
		var width := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			label.get_theme_font_size("font_size")).x
		mote.position = Vector2(label.size.x - width - 14.0, label.size.y / 2.0)
	dream_state.dreamlight_changed.connect(update)
	label.resized.connect(func() -> void: update.call(dream_state.dreamlight))
	update.call(dream_state.dreamlight)

var _shown_leaves := -1

func _on_leaves_changed(leaves: int, max_leaves: int) -> void:
	leaves_label.text = "Leaves %d / %d" % [leaves, max_leaves]
	if bark_shield != null and bark_shield.visible:
		bark_shield._place.call_deferred()  # The text width changed
	var lost := _shown_leaves >= 0 and leaves < _shown_leaves
	_shown_leaves = leaves
	if not lost:
		return
	# A creature reached the Heartwood: flash the leaves orange.
	if _leaf_flash:
		_leaf_flash.kill()
	leaves_label.add_theme_color_override("font_color", LEAF_LOST_COLOR)
	_leaf_flash = create_tween()
	# The leaves counter shakes as well as flashing (screens_ui.md "Leak"), unless reduced motion.
	if not HeartwoodMemory.get_settings().get("reduced_motion", false):
		leaves_label.pivot_offset = leaves_label.size / 2
		for offset in [-5.0, 5.0, -3.0, 3.0, 0.0]:
			_leaf_flash.tween_property(leaves_label, "rotation_degrees", offset, 0.04)
	_leaf_flash.tween_interval(0.4)
	_leaf_flash.tween_callback(leaves_label.add_theme_color_override.bind("font_color", LEAVES_COLOR))

func _on_rest_started(_block: int, _is_boss_rest: bool, bonus: int, perfect: bool) -> void:
	var text := "Rest.  +%d Dew" % bonus
	if perfect:
		text += "  (perfect block: no leaves lost)"
	show_toast(text)

func _on_act_started(act: int, leaves_regrown: int) -> void:
	var text := "Act %d: %s" % [act, drift_director.get_act_name(act)]
	if leaves_regrown > 0:
		text += "\nThe Heartwood regrows %d leaves" % leaves_regrown
	show_toast(text)

# Shows a message at the top of the screen for a few seconds.
func show_toast(text: String) -> void:
	if _toast_tween:
		_toast_tween.kill()
	toast_label.text = text
	toast_label.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(TOAST_TIME)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.6)

# First idle frame of the tower's sheet.
func _tower_icon(data: TowerData) -> Texture2D:
	return WardenIcon.make(data)  # Big Wardens (the Sapling) cropped to the bottom centre
