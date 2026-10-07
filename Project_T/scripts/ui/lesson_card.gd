class_name LessonCard
extends Control

# Lessons (onboarding.md "Lessons", 570cb7f5; user: "learning new things should pause and put a text up"): a rule the
# player can't guess and that costs them if missed pauses the game under a small centred card (the new-nightmare card's
# look: icon, title, one or two sentences, "Got it"; Esc / Enter close it). Each fires once per profile (SEEN_KEY, real
# game only, like the whispers), the Hints setting turns them off, never over a choice or rest screen (it waits for the
# map; RestScreens lists it so they wait for it too), and at most one per drift (the rest queue). Texts read live
# numbers. Made by the HUD.

const GROUP := &"lesson_card"
const SEEN_KEY := "lessons_seen"
const WIDTH := 420.0
signal lesson_shown(id: StringName)

var enabled := true  # The Hints setting ("whispers")
var one_per_drift := true  # Tests turn it off to see each trigger
var seen: Array = []  # Lesson ids shown on this profile
var queue: Array = []  # [id, icon, title, text] waiting for the map
var shown_id: StringName = &""
var _last_drift := -1  # drifts_started when the last Lesson showed
var _plants_in_mode := 0  # Placements since build mode came on (the "Build mode" Lesson at the second)
var _paused_it := false

var main: Node
var drift_director: DriftDirector
var tower_placer: TowerPlacer
var tower_seller: TowerSeller
var dream_state: DreamState
var game_speed: GameSpeed
var _icon := TextureRect.new()
var _title := Label.new()
var _body := Label.new()
var _ok := Button.new()

func _ready() -> void:
	add_to_group(GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	WorldLabel.cover_while_visible(self, &"lesson_card")
	var shade := ColorRect.new()
	shade.color = Color(UiStyle.FOG, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	var panel := PanelContainer.new()
	panel.name = "Card"
	var solid := UiStyle.panel(18.0, 18.0)  # Solid, like every paused card
	solid.center_alpha = UiStyle.TIP_ALPHA
	solid.edge_alpha = UiStyle.TIP_ALPHA
	panel.add_theme_stylebox_override("panel", solid)
	centre.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	box.add_child(head)
	_icon.custom_minimum_size = Vector2(32, 32)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	head.add_child(_icon)
	_title.name = "Title"
	UiStyle.title(_title, 24)
	head.add_child(_title)
	_body.name = "Body"
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(WIDTH, 0)
	box.add_child(_body)
	_ok.name = "GotIt"
	_ok.text = "Got it"
	_ok.focus_mode = Control.FOCUS_NONE
	_ok.custom_minimum_size = Vector2(160, UiStyle.HUD_BUTTON_H)
	_ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UiStyle.primary(_ok)
	_ok.pressed.connect(close)
	box.add_child(_ok)
	var memory := HeartwoodMemory.load_data()
	enabled = bool(memory.settings.get("whispers", true))
	seen = memory.get(SEEN_KEY, []).duplicate()
	_hook.call_deferred()

func _hook() -> void:
	main = get_parent().owner if get_parent() != null else null
	if main == null:
		return
	if get_tree().current_scene != main:
		enabled = false  # Tests build and play without Lessons pausing them (test_lessons turns them on)
	drift_director = main.get_node_or_null("%DriftDirector")
	tower_placer = main.get_node_or_null("%TowerPlacer")
	tower_seller = main.get_node_or_null("%TowerSeller")
	dream_state = main.get_node_or_null("%DreamState")
	game_speed = main.get_node_or_null("%GameSpeed")
	if tower_placer != null:
		tower_placer.tower_built.connect(_on_built)
		if tower_placer.has_signal("build_mode_changed"):
			tower_placer.build_mode_changed.connect(func(_on: bool) -> void: _plants_in_mode = 0)
	if tower_seller != null:
		tower_seller.tower_sold.connect(_on_sold)
	if dream_state != null:
		dream_state.dreamlight_earned.connect(func(amount: int, _source: StringName) -> void:
			if amount > 0:
				lesson(&"dreamlight", &"dreamlight", "Dreamlight",
					"Dreamlight unlocks new forms on the Remember screen. Spend it at a rest."))
	var spawner := main.get_node_or_null("%EnemyContainer")
	if spawner != null and spawner.has_signal("nightmare_restless"):
		spawner.nightmare_restless.connect(func(_enemy: Node2D, _stacks: int) -> void:
			lesson(&"restless", &"nightmare", "Turned around",
				"Changing the route under them makes them restless and faster. Do it too often and they stop listening."))

# --- Triggers ---------------------------------------------------------------------------------------------------

func _on_built(tower: Tower) -> void:
	if not is_instance_valid(tower) or tower.tower_data == null:
		return
	if tower_placer.build_mode:
		_plants_in_mode += 1
		if _plants_in_mode >= 2:
			lesson(&"build_mode", &"rank", "Build mode",
				"Build mode stays on. Right-click or Esc to stop building (touch: Done).")
	var data := tower.tower_data
	if not is_family_warden(data) or tower.get_meta(&"gift_sprout", false):
		return
	var name := data.display_name
	lesson(&"planted_directly", &"rank", "Sprout or %s?" % name,
		"Planting a %s directly costs the same as growing a Sprout into one. A Sprout lets you choose later." % name)
	var copies := tower_placer.count_copies(data)
	if copies >= 2:
		lesson(&"copies", &"dew", "Copies cost more",
			"Each %s you plant costs a little more than the last (%s, the next %s). Mixing Wardens keeps prices low."
			% [name, dew_text(tower.invested_dew), dew_text(tower_placer.get_cost(data))])
	if copies >= 5:
		lesson(&"copies_five", &"dew", "Five %ss" % name,
			"Five %ss: each new one now costs %s. Sprouts and walls never get pricier." % [name, dew_text(tower_placer.get_cost(data))])

func _on_sold(_tower: Tower, _refund: int) -> void:
	if drift_director == null or drift_director.is_build_phase():
		return
	lesson(&"sell_mid_drift", &"dew", "Selling mid-drift",
		"Selling during a drift returns %d%%; at a rest, %d%%." % [roundi(tower_seller.drift_refund * 100.0),
			roundi(tower_seller.build_phase_refund * 100.0)])

# A Warden of a family, planted at a price that copies raise (no Sprout, no wall).
static func is_family_warden(data: TowerData) -> bool:
	return data != null and data.buildable_directly and data.line != "wall" and data.get_id() != "sprout"

# "15 Dew" (the Dew glyph once UiStyle has it: UI Code's amount helper).
static func dew_text(amount: int) -> String:
	return "%d Dew" % amount

# --- Showing ------------------------------------------------------------------------------------------------------

func lesson(id: StringName, icon: StringName, title: String, text: String) -> void:
	if not enabled or seen.has(String(id)) or id == shown_id or queue.any(func(q: Array) -> bool: return q[0] == id):
		return
	queue.append([id, icon, title, text])

func can_show() -> bool:
	if drift_director == null or not is_inside_tree():
		return false
	if one_per_drift and drift_director.drifts_started == _last_drift:
		return false
	var run_state := main.get_node_or_null("%RunState")
	if run_state != null and run_state.is_over:
		return false
	return drift_director.pending_choice() == &"" and not RestScreens.any_open(self, drift_director)

func _process(_delta: float) -> void:
	if not visible and not queue.is_empty() and can_show():
		_show(queue.pop_front())

func _show(entry: Array) -> void:
	shown_id = entry[0]
	_icon.texture = IconInfo.icon(entry[1])
	_icon.visible = _icon.texture != null
	_title.text = entry[2]
	_body.text = entry[3]
	visible = true
	_last_drift = drift_director.drifts_started
	seen.append(String(shown_id))
	_remember()
	if game_speed != null and not game_speed.paused:
		_paused_it = true
		game_speed.set_paused(true)
	lesson_shown.emit(shown_id)

func close() -> void:
	if not visible:
		return
	visible = false
	shown_id = &""
	if _paused_it and game_speed != null:
		game_speed.set_paused(false)
	_paused_it = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept")):
		close()
		get_viewport().set_input_as_handled()

# The profile remembers them, never in tests (the scene isn't the running game there) or dev runs.
func _remember() -> void:
	if main == null or get_tree().current_scene != main or MetaRun.is_dev_run():
		return
	var memory := HeartwoodMemory.load_data()
	memory[SEEN_KEY] = seen
	HeartwoodMemory.save_data(memory)
