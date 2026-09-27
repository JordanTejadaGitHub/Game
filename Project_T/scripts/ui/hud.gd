extends CanvasLayer

const DEW_COLOR := Color(0.7, 0.9, 1.0)
const DEW_SHORT_COLOR := Color(1.0, 0.45, 0.4)
const UNAFFORDABLE_BUTTON_ALPHA := 0.45

@onready var tower_bar: HBoxContainer = %TowerBar
@onready var tower_placer: TowerPlacer = %TowerPlacer
@onready var dew_label: Label = %DewLabel
@onready var leaves_label: Label = %LeavesLabel
@onready var toast_label: Label = %ToastLabel
@onready var run_state: RunState = %RunState
@onready var drift_director: DriftDirector = %DriftDirector

const LEAVES_COLOR := Color(0.6, 0.9, 0.5)
const LEAF_LOST_COLOR := Color(1.0, 0.6, 0.3)
const TOAST_TIME := 2.5

@onready var dream_state: DreamState = %DreamState

# One toggle button per plantable Warden (unlocked this run), in roster order; `_bar_towers` matches.
var _tower_buttons: Array[Button] = []
var _bar_towers: Array[TowerData] = []
var _dew_flash: Tween
var _leaf_flash: Tween
var _toast_tween: Tween

func _ready() -> void:
	_build_tower_bar()
	# New Wardens unlocked by Dreams appear in the bar (and prices can change).
	dream_state.unlocks_changed.connect(_build_tower_bar)
	# Keep the buttons in sync when build mode is toggled with B / cancelled with Esc or right-click.
	tower_placer.build_mode_changed.connect(_sync_buttons.unbind(1))

	run_state.dew_changed.connect(_on_dew_changed)
	run_state.dew_short.connect(_on_dew_short.unbind(1))
	_on_dew_changed(run_state.dew)

	run_state.leaves_changed.connect(_on_leaves_changed)
	_on_leaves_changed(run_state.leaves, run_state.max_leaves)
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
	# Free clears (Heartwood's Reach), under the path length; hidden when there are none.
	var clears_label := path_label.duplicate() as Label
	clears_label.unique_name_in_owner = false
	clears_label.offset_top = path_label.offset_bottom
	clears_label.offset_bottom = path_label.offset_bottom + (path_label.offset_bottom - path_label.offset_top)
	clears_label.tooltip_text = "Free clears: tending a tree or moving a rock costs no Dew."
	add_child(clears_label)
	var update_clears := func(n: int) -> void:
		clears_label.text = "Free clears %d" % n
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
		var button := Button.new()
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.icon = _tower_icon(data)
		button.tooltip_text = "%s (%d)\nCost: %d Dew\n%s" % [data.display_name, i + 1,
			tower_placer.get_cost(data), data.description]
		button.pressed.connect(_on_tower_pressed.bind(data))
		tower_bar.add_child(button)
		_tower_buttons.append(button)
	_sync_buttons()
	_on_dew_changed(run_state.dew)

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
	for i in _tower_buttons.size():
		var affordable := run_state.can_afford(tower_placer.get_cost(_bar_towers[i]))
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

var _shown_leaves := -1

func _on_leaves_changed(leaves: int, max_leaves: int) -> void:
	leaves_label.text = "Leaves %d / %d" % [leaves, max_leaves]
	var lost := _shown_leaves >= 0 and leaves < _shown_leaves
	_shown_leaves = leaves
	if not lost:
		return
	# A creature reached the Heartwood: flash the leaves orange.
	if _leaf_flash:
		_leaf_flash.kill()
	leaves_label.add_theme_color_override("font_color", LEAF_LOST_COLOR)
	_leaf_flash = create_tween()
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
	if data.texture == null:
		return null
	var icon := AtlasTexture.new()
	icon.atlas = data.texture
	icon.region = data.get_frame_rect(0)
	return icon
