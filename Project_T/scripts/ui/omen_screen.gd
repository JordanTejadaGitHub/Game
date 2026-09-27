extends Control

# Omen choice at a rest (after the Dream): 2 Omen cards (the twist + its reward) or Clear Skies.
# Pauses while open, like the Dream screen. Also shows the active Omen in a small tag under the
# toast, and toasts when one starts and when its reward is paid. Built in code.

const CARD_SIZE := Vector2(270, 200)
const OMEN_COLOR := Color(0.95, 0.75, 0.45)
const TWIST_COLOR := Color(1.0, 0.7, 0.6)
const REWARD_COLOR := Color(0.65, 0.9, 0.6)

@onready var omens: OmenDirector = %OmenDirector
@onready var drift_director: DriftDirector = %DriftDirector
@onready var game_speed: GameSpeed = %GameSpeed

var _was_paused := false
var _title := Label.new()
var _cards := HBoxContainer.new()
var _clear_skies := Button.new()
var _active_tag := Label.new()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.05, 0.03, 0.72)
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
	_title.add_theme_color_override("font_color", OMEN_COLOR)
	box.add_child(_title)
	_cards.add_theme_constant_override("separation", 16)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_cards)
	_clear_skies.text = "Clear Skies  (nothing changes)"
	_clear_skies.focus_mode = Control.FOCUS_NONE
	_clear_skies.pressed.connect(omens.choose.bind(null))
	var skip_row := CenterContainer.new()
	skip_row.add_child(_clear_skies)
	box.add_child(skip_row)
	visible = false

	# The active-Omen tag lives on the HUD, outside this (usually hidden) screen.
	_active_tag.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_active_tag.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_active_tag.offset_top = 64
	_active_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_active_tag.add_theme_color_override("font_color", OMEN_COLOR)
	_active_tag.add_theme_color_override("font_outline_color", Color(0.08, 0.1, 0.14))
	_active_tag.add_theme_constant_override("outline_size", 6)
	_active_tag.visible = false
	get_parent().add_child.call_deferred(_active_tag)

	omens.offer_ready.connect(_show_offer)
	omens.offer_closed.connect(_on_closed)
	omens.omen_started.connect(_on_omen_started)
	omens.omen_rewarded.connect(_on_omen_rewarded)

func _show_offer(offer: Array[OmenData], block: int) -> void:
	if not visible:
		_was_paused = game_speed.paused
	game_speed.set_paused(true)
	var drifts := omens.get_block_range(block)
	_title.text = "The wind brings Omens for drifts %d–%d" % [drifts.x, drifts.y]
	for child in _cards.get_children():
		child.queue_free()
	var act := drift_director.get_act(drifts.y)
	for omen in offer:
		_cards.add_child(_make_card(omen, act))
	visible = true

func _make_card(omen: OmenData, act: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(omens.choose.bind(omen))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.13, 0.12, 0.95)
	style.border_color = OMEN_COLOR
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.24, 0.2, 0.17, 0.98)
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
	_add_line(box, omen.display_name, Color(0.95, 0.93, 0.9), 22)
	_add_line(box, omen.description, TWIST_COLOR, 16).size_flags_vertical = Control.SIZE_EXPAND_FILL
	_add_line(box, "Reward: " + omens.describe_reward(omen, act), REWARD_COLOR, 15)
	return button

func _add_line(box: VBoxContainer, text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	return label

func _on_closed() -> void:
	visible = false
	game_speed.set_paused(_was_paused)

func _on_omen_started(omen: OmenData, first_drift: int, last_drift: int) -> void:
	_active_tag.text = "Omen: %s (drifts %d–%d) · %s" % [omen.display_name, first_drift, last_drift, omen.description]
	_active_tag.visible = true
	_toast("Omen chosen: %s" % omen.display_name)

func _on_omen_rewarded(omen: OmenData, summary: String) -> void:
	_active_tag.visible = false
	_toast("%s passes: %s" % [omen.display_name, summary])

func _toast(text: String) -> void:
	var hud := get_parent()
	if hud.has_method("show_toast"):
		hud.show_toast(text)
