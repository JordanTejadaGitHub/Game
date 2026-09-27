extends Control

# Warden family pick (run_design.md, "Warden families"): after drift 1 and after each boss, pick 1
# of up to 3 base Wardens you don't have yet. The pick unlocks it (Sprouts can grow into it, or
# plant it directly). Pauses the game while open. Built in code.

const CARD_SIZE := Vector2(250, 230)
const TITLES := {
	&"first": "The Heartwood stirs, and remembers an old friend…",
	&"boss": "The Heartwood remembers another friend.",
}

# Families that can be offered (demo: the first-playable three; the full game adds Pebbling,
# Rootling and Acorn once the Memory Grove unlocks them).
@export var families: Array[TowerData] = [
	preload("res://resource/tower/sporeling.tres"),
	preload("res://resource/tower/firefly_jar.tres"),
	preload("res://resource/tower/dewdrop.tres"),
]
@export var cards_per_pick: int = 3

@onready var dream_state: DreamState = %DreamState
@onready var drift_director: DriftDirector = %DriftDirector
@onready var game_speed: GameSpeed = %GameSpeed

var offer: Array[TowerData] = []
var _was_paused := false
var _title := Label.new()
var _cards := HBoxContainer.new()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.06, 0.05, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	box.add_child(_title)
	_cards.add_theme_constant_override("separation", 16)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_cards)
	visible = false
	drift_director.family_pick_requested.connect(show_pick)

# Families not unlocked yet, in roster order.
func get_available() -> Array[TowerData]:
	var result: Array[TowerData] = []
	for data in families:
		if not dream_state.is_unlocked(data.get_id()):
			result.append(data)
	return result

func show_pick(reason: StringName = &"first") -> void:
	var available := get_available()
	available.shuffle()
	offer = available.slice(0, cards_per_pick)
	if offer.is_empty():
		drift_director.family_picked()  # Nothing left to offer
		return
	if not visible:
		_was_paused = game_speed.paused
	game_speed.set_paused(true)
	_title.text = TITLES.get(reason, TITLES[&"first"])
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	for data in offer:
		_cards.add_child(_make_card(data))
	visible = true

func choose(data: TowerData) -> void:
	if not offer.has(data):
		return
	offer = []
	dream_state.unlocked[data.get_id()] = true
	dream_state.unlocks_changed.emit()
	visible = false
	game_speed.set_paused(_was_paused)
	drift_director.family_picked()

func _make_card(data: TowerData) -> Button:
	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(choose.bind(data))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.16, 0.13, 0.95)
	style.border_color = Color(0.55, 0.85, 0.55)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.15, 0.24, 0.18, 0.98)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 14
	box.offset_top = 12
	box.offset_right = -14
	box.offset_bottom = -12
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	if data.texture != null:
		var icon := TextureRect.new()
		var atlas := AtlasTexture.new()
		atlas.atlas = data.texture
		atlas.region = data.get_frame_rect(0)
		icon.texture = atlas
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(icon)
	var sprout_cost := dream_state.get_evolve_cost(data)
	for line in [[data.display_name, 22, Color.WHITE], [data.description, 15, Color(0.9, 0.95, 0.9)],
			["Sprouts can grow into it (%d Dew), or plant one directly (%d Dew)." % [sprout_cost, data.cost], 13, Color(0.7, 0.9, 0.7)]]:
		var label := Label.new()
		label.text = line[0]
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", line[1])
		label.add_theme_color_override("font_color", line[2])
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(label)
	return button
