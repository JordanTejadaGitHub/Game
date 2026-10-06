extends Control
class_name SeedPicker

# Remembered Seed (Grove Perks node, meta_design.md 952b986e; full game only): once planted, starting a run asks which
# map: a new random one, a past run's (its seed rebuilds the same layout, from the run history), or a typed seed. The
# run plays and banks Seeds normally. Touch-friendly: every choice is a 48 px button.
#   SeedPicker.ask(parent, start)   start.call() at once without the node; otherwise after the choice
# The chosen seed reaches the run through RunSaver.next_map_seed (applied before MapGenerator builds the map).

const NODE_ID := "remembered_seed"
const PAST_RUNS := 8  # Most recent distinct maps listed
const WIDTH := 460.0

var _start: Callable
var _list := VBoxContainer.new()
var _typed := LineEdit.new()
var _typed_go := Button.new()

# Whether the run-start choice applies: the full game, with the node planted.
static func available() -> bool:
	if ResultsScreen.is_demo():
		return false
	var unlock := HeartwoodMemory.get_unlock(NODE_ID)
	return unlock != null and HeartwoodMemory.node_level(HeartwoodMemory.load_data(), unlock) > 0

# Starts a run through the choice when Remembered Seed is planted, else at once. `start` launches the run scene.
static func ask(parent: Node, start: Callable) -> void:
	RunSaver.next_map_seed = 0
	if not available():
		start.call()
		return
	var picker := SeedPicker.new()
	picker._start = start
	parent.add_child(picker)

# Past runs' maps, newest first, one per seed: [{seed, date, result, survived}].
static func past_maps(limit: int = PAST_RUNS) -> Array:
	var maps: Array = []
	var seen := {}
	for record in RunHistory.load_runs():
		var map_seed := int(record.get("seed", 0))
		if map_seed == 0 or seen.has(map_seed) or bool(record.get("demo", false)):
			continue
		seen[map_seed] = true
		maps.append({"seed": map_seed, "date": String(record.get("date", "")), "result": String(record.get("result", "")),
			"survived": int(record.get("survived", 0))})
		if maps.size() >= limit:
			break
	return maps

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(UiStyle.FOG, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var panel := PanelContainer.new()
	centre.add_child(panel)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = WIDTH
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var title := Label.new()
	title.text = "Which dream?"
	UiStyle.display(title, 30)
	box.add_child(title)
	var fresh := _button(box, "A new map")
	fresh.name = "NewMap"
	UiStyle.primary(fresh)
	fresh.pressed.connect(_choose.bind(0))
	# A map you've played: the run history's maps, each a row (date, how far it went).
	var maps := past_maps()
	var head := Label.new()
	head.text = "A map you've played"
	UiStyle.caps(head, 14)
	box.add_child(head)
	_list.name = "PastMaps"
	_list.add_theme_constant_override("separation", 0)
	box.add_child(_list)
	if maps.is_empty():
		var none := Label.new()
		none.text = "No past runs yet."
		none.add_theme_color_override("font_color", UiStyle.INK_DIM)
		_list.add_child(none)
	for map in maps:
		var row := _button(_list, "%s   drift %d, %s" % [String(map.date).replace("T", " ").left(16), map.survived, map.result])
		row.name = "Map_%d" % map.seed
		row.tooltip_text = "Seed %d" % map.seed  # Framed: each a real choice (button rule)
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.pressed.connect(_choose.bind(int(map.seed)))
	# A typed seed (digits; any whole number from 1 up).
	var typed_head := Label.new()
	typed_head.text = "A seed"
	UiStyle.caps(typed_head, 14)
	box.add_child(typed_head)
	var typed_row := HBoxContainer.new()
	typed_row.add_theme_constant_override("separation", 8)
	box.add_child(typed_row)
	_typed.name = "TypedSeed"
	_typed.placeholder_text = "Type a seed"
	_typed.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_NUMBER  # Touch: the number pad
	_typed.custom_minimum_size.y = UiStyle.HUD_BUTTON_H
	_typed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_typed.text_changed.connect(func(_t: String) -> void: _typed_go.disabled = typed_seed() == 0)
	_typed.text_submitted.connect(func(_t: String) -> void:
		if typed_seed() != 0:
			_choose(typed_seed()))
	typed_row.add_child(_typed)
	_typed_go.text = "Dream it"
	_typed_go.name = "TypedGo"
	_typed_go.disabled = true
	_typed_go.focus_mode = Control.FOCUS_NONE
	_typed_go.custom_minimum_size = Vector2(120, UiStyle.HUD_BUTTON_H)
	_typed_go.pressed.connect(func() -> void: _choose(typed_seed()))
	typed_row.add_child(_typed_go)
	var back := _button(box, "Back")  # Framed secondary
	back.pressed.connect(queue_free)

# The typed seed as a whole number from 1 (0 = nothing usable typed).
func typed_seed() -> int:
	var text := _typed.text.strip_edges()
	if not text.is_valid_int():
		return 0
	return clampi(text.to_int(), 0, 2147483646)

# 0 = a new random map.
func _choose(map_seed: int) -> void:
	RunSaver.next_map_seed = map_seed
	var start := _start
	queue_free()
	start.call()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()

func _button(parent: Control, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.y = UiStyle.HUD_BUTTON_H
	parent.add_child(button)
	return button
