extends CanvasLayer
class_name TestGrove

# Test Grove (demo_scope.md): a developer playtest mode, never in release builds. A normal run with
# every Warden family in the bar from drift 1 (so the family picks have nothing left to offer),
# every branch / final form / hidden branch / Memory Warden growable without its Dream (Dew still
# applies), plus tools:
#   +500 Dew (F9), skip to drift N at a rest,
#   spawn any nightmare (count, elite), a Target Dummy (slow, unkillable, loops the route),
#   a damage meter (per Warden this drift: total, DPS, status and combo shares, from DamageLog),
#   damage numbers (off / big / all), Inspect (click a nightmare while paused),
#   invulnerable Heartwood, and clear the field,
#   every Dream card in the pool (Grove-only and bittersweet too) and "Take any Dream".
# The tools, meter and Inspect are one dock on the right under the resources (screens_ui.md), which
# F10 collapses. On with the settings "Developer" toggle or the launch flag `-- --test-grove`; only
# in debug builds.

const SETTING := "test_grove"
const LAUNCH_FLAG := "--test-grove"
const DEW_GIFT := 500
const ENEMY_DIR := "res://resource/enemy/"
const SPAWN_SPACING := 0.4  # Seconds between spawned nightmares
const DUMMY_SPEED := 0.35  # × the nightmare's speed
const REFRESH := 0.5  # Real seconds between meter / inspect refreshes
const METER_ROWS := 10
const INSPECT_RADIUS := 32.0  # Pixels from a nightmare that count as clicking it
# Dock: right edge, below the resources and the nightmare info, above the drift controls.
const DOCK_WIDTH := 300.0
const DOCK_TOP := 316.0  # The nightmare info ends at 310 (it moved down for the top-right button row)
const DOCK_BOTTOM_GAP := 152.0
const TEXT_COLOR := Color(0.96, 0.97, 0.94)
const TITLE_COLOR := Color(1.0, 0.8, 0.4)
const DOCK_BG := Color(0.05, 0.06, 0.08, 0.94)

# Tests (and the settings toggle, within one session) can switch it on without the saved setting.
static var force_on := false

@onready var dream_state: DreamState = %DreamState
@onready var drift_director: DriftDirector = %DriftDirector
@onready var run_state: RunState = %RunState
@onready var spawner = %EnemyContainer
@onready var game_speed: GameSpeed = %GameSpeed

var enemy_types: Array[EnemyData] = []
var dummy: Node2D = null
var inspected: Node2D = null

var _skip_to := SpinBox.new()
var _type := OptionButton.new()
var _count := SpinBox.new()
var _elite := CheckBox.new()
var _meter := Label.new()
var _inspect := Label.new()
var _inspect_panel := VBoxContainer.new()
var _dream := OptionButton.new()
var _dream_cards: Array[UpgradeData] = []
var _dock := PanelContainer.new()
var _dock_body := ScrollContainer.new()
var _refresh := 0.0

# Debug builds only: exported release/demo builds never show or allow it.
static func is_available() -> bool:
	return OS.is_debug_build()

static func is_active() -> bool:
	if not is_available():
		return false
	if force_on:
		return true
	# Headless test scripts ignore the developer's saved setting, so every test runs a normal run.
	if OS.get_cmdline_args().has("--script"):
		return false
	return OS.get_cmdline_user_args().has(LAUNCH_FLAG) or bool(HeartwoodMemory.get_settings().get(SETTING, false))

func _ready() -> void:
	if not is_active():
		queue_free()
		return
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	dream_state.unlock_everything = true
	dream_state.unlocks_changed.emit()  # Tower bar shows every family
	# Every Dream card can be offered: Grove-only ones (the Grove isn't built yet) and bittersweet.
	for card in dream_state.pool:
		if not card.in_start_pool:
			dream_state.grove_cards.append(card.id)
	dream_state.allow_bittersweet = true
	dream_state.clearing_open = true  # No clearing Dream needed to tend obstacles
	enemy_types = _load_enemy_types()
	_build_dock()

func _process(delta: float) -> void:
	_fit_dock()
	_refresh -= delta / maxf(Engine.time_scale, 0.001)  # Real time, also while paused
	if _refresh > 0.0:
		return
	_refresh = REFRESH
	_meter.text = get_meter_text()
	if is_instance_valid(inspected) and not inspected.is_cleansed:
		_inspect.text = get_inspect_text(inspected)
	else:
		inspected = null
		_inspect_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_F9:
		give_dew()
		get_viewport().set_input_as_handled()
		return
	if key != null and key.pressed and not key.echo and key.physical_keycode == KEY_F10:
		toggle_dock()
		get_viewport().set_input_as_handled()
		return
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT and game_speed.paused:
		var enemy := nightmare_at(spawner.get_global_mouse_position())
		if enemy != null:
			inspect(enemy)
			get_viewport().set_input_as_handled()


# --- Tools ------------------------------------------------------------------------------------------

func give_dew() -> void:
	run_state.add_dew(DEW_GIFT)

# Jumps ahead so the next Start begins drift `number`. Only at a rest (nothing on the field).
# Skipped drifts pay nothing and offer no Dreams; health scaling follows the new drift number.
func skip_to(number: int) -> bool:
	if not drift_director.is_resting() or drift_director.awaiting_family_pick:
		return false
	number = clampi(number, drift_director.drifts_started + 1, drift_director.get_total_drifts())
	drift_director.drifts_started = number - 1
	drift_director.drifts_cleared = number - 1
	return true

# Spawns `count` of `data` at the forest's edge, one every SPAWN_SPACING seconds, with the current
# drift's health (they don't belong to any drift). Returns the first one.
func spawn(data: EnemyData, count: int = 1, elite: bool = false) -> Node2D:
	var first := _spawn_one(data, elite)
	for i in range(1, count):
		get_tree().create_timer(SPAWN_SPACING * i, false).timeout.connect(_spawn_one.bind(data, elite))
	return first

func _spawn_one(data: EnemyData, elite: bool) -> Node2D:
	var number := maxi(drift_director.drifts_started, 1)
	return spawner.spawn_enemy(data, drift_director.get_health_scale(data, number),
		drift_director.get_spawn_modifiers(data, number), elite)

# The Target Dummy: slow, never dispelled, walks the maze again at the end. Toggles it.
func toggle_dummy(data: EnemyData = null) -> Node2D:
	if is_instance_valid(dummy) and not dummy.is_cleansed:
		dummy.queue_free()
		dummy = null
		return null
	data = data if data != null else _selected_type()
	var modifiers := {"speed": DUMMY_SPEED}
	dummy = spawner.spawn_enemy(data, drift_director.get_health_scale(data, maxi(drift_director.drifts_started, 1)),
		modifiers)
	if dummy != null:
		dummy.unkillable = true
		dummy.loops_route = true
	return dummy

func set_invulnerable(on: bool) -> void:
	run_state.invulnerable = on

# Dispels everything on the field (split-offs too) and removes the dummy.
func clear_field() -> void:
	if is_instance_valid(dummy):
		dummy.queue_free()
		dummy = null
	for pass_number in 10:  # Split-offs appear as their parent is dispelled
		var walking: Array[Node] = spawner.get_enemies()
		if walking.is_empty():
			return
		for enemy in walking:
			if not enemy.is_queued_for_deletion():
				enemy.dispel()

func set_numbers_mode(mode: int) -> void:
	if DamageLog.instance:
		DamageLog.instance.numbers_mode = mode

func nightmare_at(world: Vector2) -> Node2D:
	var best: Node2D = null
	var best_distance := INSPECT_RADIUS
	for enemy in spawner.get_enemies():
		var distance: float = enemy.global_position.distance_to(world)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best

func inspect(enemy: Node2D) -> void:
	inspected = enemy
	_inspect.text = get_inspect_text(enemy)
	_inspect_panel.visible = true
	_dock_body.visible = true  # Show it even if the dock was collapsed

# "Take any Dream": applies `card` right now, as if chosen from an offer (stat cards stack).
func take_dream(card: UpgradeData) -> bool:
	if card == null or (card.max_stacks > 0 and dream_state.card_stacks(card.id) >= card.max_stacks):
		return false
	dream_state.take(card)
	return true

# F10: collapse the dock to its title bar, or open it again.
func toggle_dock() -> void:
	_dock_body.visible = not _dock_body.visible


# --- Readouts ---------------------------------------------------------------------------------------

func get_meter_text() -> String:
	var damage_log := DamageLog.instance
	if damage_log == null:
		return ""
	var lines: Array[String] = ["Damage since drift %d" % damage_log.drift_label]
	var rows := damage_log.get_meter_rows()
	for i in mini(rows.size(), METER_ROWS):
		var row: Dictionary = rows[i]
		var line := "%s  %d  (%.0f/s)" % [row.name, roundi(row.drift), row.dps]
		if row.status_share > 0.01:
			line += "  status %d%%" % roundi(row.status_share * 100)
		if row.combo_share > 0.01:
			var parts: Array[String] = []
			for tag in row.combos:
				if row.combos[tag] > 0.01:
					parts.append("%s %d%%" % [DamageLog.combo_name(tag), roundi(row.combos[tag] * 100)])
			line += "  combos %d%% (%s)" % [roundi(row.combo_share * 100), ", ".join(parts)]
		lines.append(line)
	if rows.is_empty():
		lines.append("(nothing yet)")
	if is_instance_valid(dummy) and not dummy.is_cleansed:
		lines.append("")
		lines.append("Target Dummy: %.0f damage/s" % damage_log.get_dps(null, dummy))
		var by := damage_log.get_dps_by_source(dummy)
		for name in by:
			lines.append("  %s %.0f/s" % [name, by[name]])
	return "\n".join(lines)

func get_inspect_text(enemy: Node2D) -> String:
	var data: EnemyData = enemy.enemy_data
	var lines: Array[String] = ["%s%s  %d / %d" % [data.display_name, " (elite)" if enemy.elite else "",
		enemy.health, enemy.max_health]]
	if enemy.coat > 0.0:
		lines.append("Blight coat %.0f / %.0f" % [enemy.coat, enemy.coat_max])
	if not data.resists.is_empty() or not data.weak_to.is_empty():
		lines.append("Resists %s · weak to %s" % [", ".join(data.resists) if not data.resists.is_empty() else "—",
			", ".join(data.weak_to) if not data.weak_to.is_empty() else "—"])
	lines.append("Taken ×%.2f · speed ×%.2f" % [enemy.statuses.get_damage_taken_multiplier(),
		enemy.statuses.get_speed_multiplier()])
	for status in enemy.statuses.snapshot():
		var who: Node = status.source
		lines.append("%s ×%d  %.1f s  potency %.1f%s" % [String(status.id).capitalize(), status.stacks, status.time,
			status.potency, "  from %s" % who.tower_data.display_name if who is Tower else ""])
	if not enemy.recent_hits.is_empty():
		lines.append("Last hits:")
		for event in enemy.recent_hits:
			lines.append("  " + event.describe())
	return "\n".join(lines)


# --- UI ---------------------------------------------------------------------------------------------

# One dock on the right, under the resources: title bar (F10 collapses the rest), tools, Dreams,
# Inspect (when a nightmare is inspected) and the damage meter. Scrolls if it's taller than the gap.
func _build_dock() -> void:
	_dock.anchor_left = 1.0
	_dock.anchor_right = 1.0
	_dock.anchor_top = 0.0
	_dock.anchor_bottom = 1.0
	_dock.offset_left = -16.0 - DOCK_WIDTH
	_dock.offset_right = -16.0
	_dock.offset_top = DOCK_TOP
	_dock.offset_bottom = -DOCK_BOTTOM_GAP
	_dock.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var style := StyleBoxFlat.new()
	style.bg_color = DOCK_BG
	style.border_color = TITLE_COLOR.darkened(0.4)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	_dock.add_theme_stylebox_override("panel", style)
	_dock.add_theme_color_override("font_color", TEXT_COLOR)
	add_child(_dock)

	var outer := VBoxContainer.new()
	_dock.add_child(outer)
	var title := Button.new()
	title.text = "Test Grove (dev)  ·  F10"
	title.flat = true
	title.alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.focus_mode = Control.FOCUS_NONE
	title.add_theme_color_override("font_color", TITLE_COLOR)
	title.add_theme_color_override("font_hover_color", TITLE_COLOR.lightened(0.2))
	title.pressed.connect(toggle_dock)
	outer.add_child(title)

	_dock_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dock_body.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(_dock_body)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	_dock_body.add_child(box)
	_build_tools(box)
	_build_dreams(box)
	_build_inspect(box)
	box.add_child(HSeparator.new())
	_meter.add_theme_font_size_override("font_size", 13)
	_meter.add_theme_color_override("font_color", TEXT_COLOR)
	_meter.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_meter)

# The drift controls grow upward with their content, so keep the dock's bottom just above them.
func _fit_dock() -> void:
	var drift_panel := get_parent().get_node_or_null("HUD/DriftPanel") as Control
	if drift_panel == null or not drift_panel.visible:
		return
	var height := _dock.get_viewport_rect().size.y
	var gap := maxf(DOCK_BOTTOM_GAP, height - drift_panel.get_global_rect().position.y + 8.0)
	if not is_equal_approx(_dock.offset_bottom, -gap):
		_dock.offset_bottom = -gap

func _build_tools(box: VBoxContainer) -> void:
	_button(box, "+%d Dew  (F9)" % DEW_GIFT, give_dew)
	var skip_row := HBoxContainer.new()
	box.add_child(skip_row)
	_skip_to.min_value = 1
	_skip_to.max_value = maxi(drift_director.get_total_drifts(), 1)
	_skip_to.value = 25
	skip_row.add_child(_skip_to)
	_button(skip_row, "Skip to drift", func() -> void: skip_to(int(_skip_to.value)),
		"At a rest: the next Start begins this drift.")

	box.add_child(_heading("Nightmares"))
	for data in enemy_types:
		_type.add_item(data.display_name)
	_type.focus_mode = Control.FOCUS_NONE
	box.add_child(_type)
	var spawn_row := HBoxContainer.new()
	box.add_child(spawn_row)
	_count.min_value = 1
	_count.max_value = 50
	_count.value = 5
	spawn_row.add_child(_count)
	_elite.text = "Elite"
	_elite.focus_mode = Control.FOCUS_NONE
	_elite.add_theme_color_override("font_color", TEXT_COLOR)
	spawn_row.add_child(_elite)
	_button(spawn_row, "Spawn", func() -> void: spawn(_selected_type(), int(_count.value), _elite.button_pressed))
	_button(box, "Target Dummy (on / off)", func() -> void: toggle_dummy(),
		"A slow, unkillable nightmare that walks the route on a loop.")

	box.add_child(_heading("Field"))
	var numbers := OptionButton.new()
	for label in ["Damage numbers: off", "Damage numbers: big", "Damage numbers: all"]:
		numbers.add_item(label)
	if DamageLog.instance:
		numbers.selected = DamageLog.instance.numbers_mode
	numbers.focus_mode = Control.FOCUS_NONE
	numbers.item_selected.connect(set_numbers_mode)
	box.add_child(numbers)
	var invulnerable := CheckBox.new()
	invulnerable.text = "Invulnerable Heartwood"
	invulnerable.focus_mode = Control.FOCUS_NONE
	invulnerable.add_theme_color_override("font_color", TEXT_COLOR)
	invulnerable.toggled.connect(set_invulnerable)
	box.add_child(invulnerable)
	var field_row := HBoxContainer.new()
	box.add_child(field_row)
	_button(field_row, "Clear the field", clear_field)
	_button(field_row, "Reset meter", func() -> void:
		if DamageLog.instance:
			DamageLog.instance.reset_drift())

# "Take any Dream": every card, taken right away.
func _build_dreams(box: VBoxContainer) -> void:
	box.add_child(_heading("Dreams"))
	_dream_cards = dream_state.pool.duplicate()
	_dream_cards.sort_custom(func(a: UpgradeData, b: UpgradeData) -> bool: return a.display_name < b.display_name)
	for card in _dream_cards:
		_dream.add_item("%s (%s)" % [card.display_name, UpgradeData.rarity_name(card.rarity)])
	_dream.focus_mode = Control.FOCUS_NONE
	_dream.fit_to_longest_item = false
	_dream.clip_text = true
	box.add_child(_dream)
	_button(box, "Open the card grid…", func() -> void:
		var hud := get_parent().get_node_or_null("HUD")  # A screen overlay, not in the world
		DevCardPicker.open(hud if hud else self, dream_state, take_dream))
	_button(box, "Take this Dream now", func() -> void:
		if _dream.selected >= 0:
			take_dream(_dream_cards[_dream.selected]))

func _build_inspect(box: VBoxContainer) -> void:
	_inspect_panel.visible = false
	box.add_child(_inspect_panel)
	_inspect_panel.add_child(HSeparator.new())
	_inspect_panel.add_child(_heading("Inspect"))
	_inspect.add_theme_font_size_override("font_size", 13)
	_inspect.add_theme_color_override("font_color", TEXT_COLOR)
	_inspect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inspect_panel.add_child(_inspect)
	_button(_inspect_panel, "Close", func() -> void:
		inspected = null
		_inspect_panel.visible = false)

func _heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", TITLE_COLOR)
	label.add_theme_font_size_override("font_size", 13)
	return label

func _button(parent: Control, text: String, action: Callable, tooltip: String = "") -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _selected_type() -> EnemyData:
	return enemy_types[maxi(_type.selected, 0)] if not enemy_types.is_empty() else null

static func _load_enemy_types() -> Array[EnemyData]:
	var types: Array[EnemyData] = []
	for file in ResourceLoader.list_directory(ENEMY_DIR):
		if file.ends_with(".tres") or file.ends_with(".res"):
			var data := load(ENEMY_DIR + file) as EnemyData
			if data != null:
				types.append(data)
	types.sort_custom(func(a: EnemyData, b: EnemyData) -> bool: return a.display_name < b.display_name)
	return types
