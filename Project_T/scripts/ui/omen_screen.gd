extends Control

# The Omen screen at a rest (run_design.md "Commit blind, then the Omen is revealed"): a face-down
# "Face an Omen" card and Clear Skies (the default: nothing changes, no reward). Facing it flips to
# the drawn Omens (twist + reward) to pick one from; no going back. Esc / right-click = Clear Skies. Pauses and peeks like the Dream screen. Also shows the
# active Omen in a small tag under the toast, and toasts when one starts and when its reward is paid.
# Built in code.

const CARD_SIZE := Vector2(380, 220)  # Wide enough that the 16–18 px lines don't wrap much (user: "can barely read this")
const CARD_PAD := Vector2(18, 16)  # Inner padding on every side (x: left and right, y: top and bottom)
const REWARD_SIZE := 16  # The reward line (screens_ui.md readable text: 16 px+ body)
const FRONT_BODY_SIZE := 18  # Face an Omen and Clear Skies: the Dream card body size (user: "a bit bigger")
const EMBLEM_SCALE := 2  # The 16 px icons drawn x2 (32 px), nearest: the fallback until the card emblems exist (x3+ read as a skull: user)
const CARD_EMBLEM_SHEET := "res://assets/ui/omen_cards.png"  # UI Asset's 32 px card emblems (omen_cards.json)
const CARD_EMBLEMS := {&"omen": 0, &"clear_skies": 1}  # Frame per emblem: omen_card, clear_skies_card
const CARD_EMBLEM_SIZE := 32.0
const CARD_EMBLEM_SCALE := 2.0  # Shown x2 (64 px), nearest
const FLAVOR_SIZE := 17  # The whisper face runs large; this sits level with the 18 px body
const SECONDARY_MIN_SIZE := 16  # Lines never shrink below the readable floor (screens_ui.md); the card grows instead
const SCREEN_MARGIN := 240.0  # Title, buttons and gaps around the cards
const OMEN_COLOR := UiStyle.BUTTON_GOLD  # Heartwood 32 "Gold"
const REWARD_COLOR := UiStyle.GOLD  # Heartwood 32 "Glow": the reward in gold (run_design.md)
const CLEAR_SKIES_COLOR := UiStyle.MOONLIGHT  # A calm moonlit card: Moonlight thread and title
const CLEAR_SKIES_GLOW := Color("3c3c5c")  # Dusk: a cooler, lighter middle than an Omen's Night

@onready var omens: OmenDirector = %OmenDirector
@onready var drift_director: DriftDirector = %DriftDirector
@onready var game_speed: GameSpeed = %GameSpeed

var _was_paused := false
var _title := Label.new()
var _cards := HBoxContainer.new()
var _active_tag := Label.new()
var peek: ChoicePeek  # Minimise to look at the map (screens_ui.md "Choice screens")

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(UiStyle.FOG, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.display(_title, 28)
	_title.add_theme_color_override("font_color", OMEN_COLOR)
	box.add_child(_title)
	_cards.add_theme_constant_override("separation", 16)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_cards)
	peek = ChoicePeek.new(self, [dim, center], "Back to the Omens")
	box.add_child(peek.make_peek_button())
	visible = false

	# The active-Omen tag lives on the HUD, outside this (usually hidden) screen.
	_active_tag.name = "ActiveOmen"  # ComingStrip stacks under it (top centre)
	_active_tag.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_active_tag.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_active_tag.offset_top = 64
	_active_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_active_tag.add_theme_color_override("font_color", OMEN_COLOR)
	_active_tag.add_theme_color_override("font_outline_color", Palette.DREAD)
	_active_tag.add_theme_constant_override("outline_size", 6)
	_active_tag.visible = false
	# The Omen's icon inline at the start of the first line ("[icon] Omen: Stubborn Blight · drifts 11–15"), placed by
	# _place_tag_icon after layout (user: the old one floated off into the void).
	_tag_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tag_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_tag_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tag_icon.name = "OmenIcon"
	_active_tag.add_child(_tag_icon)
	_active_tag.mouse_filter = Control.MOUSE_FILTER_PASS  # Its tooltip says where the reward stands
	_active_tag.resized.connect(_place_tag_icon)
	get_parent().add_child.call_deferred(_active_tag)

	omens.offer_ready.connect(_show_offer)
	omens.offer_closed.connect(_on_closed)
	omens.omen_started.connect(_on_omen_started)
	omens.omen_rewarded.connect(_on_omen_rewarded)
	var run_state := get_node_or_null("%RunState")
	if run_state:
		run_state.leaves_changed.connect(func(_l: int, _m: int) -> void: _refresh_tag())  # The reward line follows the block's losses

# Commit blind (run_design.md "Commit blind, then the Omen is revealed"): a face-down "Face an Omen"
# card and Clear Skies. Facing it flips to the drawn Omens (2; Omen Reader 3): pick one, no going back.
# A forced Omen (Blight), or a save made after facing, shows the Omens at once.
func _show_offer(_offer: Array[OmenData], block: int) -> void:
	if not visible:
		_was_paused = game_speed.paused
	game_speed.set_paused(true)
	_drifts = omens.get_block_range(block)
	_title.text = "The wind stirs · drifts %d–%d" % [_drifts.x, _drifts.y]
	_clear_cards()
	visible = true
	if omens.forced or omens.faced:
		if omens.forced:
			_title.text = "An Omen must be faced · drifts %d–%d" % [_drifts.x, _drifts.y]
		_reveal(omens.face(), null)
		return
	var back := _make_face_down_card()
	_cards.add_child(back)
	_cards.add_child(_make_clear_skies_card())

var _drifts := Vector2i.ZERO

func _clear_cards() -> void:
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()

# The face-down card: a wind swirl and "An unknown twist for the next block. Survive it for a reward."
func _make_face_down_card() -> Button:
	var button := Button.new()
	button.name = "FaceAnOmen"
	button.custom_minimum_size = CARD_SIZE
	button.focus_mode = Control.FOCUS_NONE
	UiStyle.card_button(button, OMEN_COLOR)
	var box := _card_box(button)
	UiStyle.title(_add_line(box, "Face an Omen", UiStyle.INK, 22), UiStyle.CARD_NAME_SIZE)
	_add_flavor(box, "Something stirs out in the dark.")
	var body := _add_line(box, "A twist for the next block. Face it for a reward.", UiStyle.INK, FRONT_BODY_SIZE)
	box.add_child(_emblem(&"omen", true))  # A moth before the moon (the wind swirl until UI Asset's icon exists)
	_fit_card(button, box, [body])
	button.pressed.connect(func() -> void: _reveal(omens.face(), button))
	return button

# A card's emblem (run_design.md "How an Omen looks"): the icon from assets/ui/icons.png drawn x4 (64 px, nearest)
# on a soft glow (`glow`), centred in the card's spare space; without the icon, the old wind swirl (`swirl`) or an
# empty space.
func _emblem(id: StringName, swirl: bool, glow: Color = OMEN_COLOR) -> Control:
	var icon: Texture2D = _card_emblem(id)  # UI Asset's 32 px card emblem, x2
	var side := CARD_EMBLEM_SIZE * CARD_EMBLEM_SCALE
	if icon == null:
		icon = IconInfo.icon(id)  # Until then the 16 px icon, x2 (x3 read as a skull: user)
		side = 16.0 * EMBLEM_SCALE
	if icon != null:
		var canvas := Control.new()
		canvas.custom_minimum_size = Vector2(side, side + 12)
		canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
		canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
		canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		canvas.name = "Emblem"
		canvas.draw.connect(func() -> void:
			var centre := canvas.size / 2.0
			for i in 6:  # A soft round glow, faint at the edge
				canvas.draw_circle(centre, side * (0.95 - i * 0.1), Color(glow, 0.05 + i * 0.02))
			canvas.draw_texture_rect(icon, Rect2(centre - Vector2(side, side) / 2.0, Vector2(side, side)), false))
		return canvas
	var canvas := Control.new()
	canvas.custom_minimum_size = Vector2(0, 64 if swirl else 0)
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if swirl:
		canvas.draw.connect(func() -> void: _draw_swirl(canvas))
	return canvas

# The 32 px card emblem for `id` from UI Asset's sheet (null until it's there). Kept on the instance, not static.
var _emblem_sheet: Texture2D = null

func _card_emblem(id: StringName) -> Texture2D:
	if not CARD_EMBLEMS.has(id) or not ResourceLoader.exists(CARD_EMBLEM_SHEET):
		return null
	if _emblem_sheet == null:
		_emblem_sheet = load(CARD_EMBLEM_SHEET)
	var atlas := AtlasTexture.new()
	atlas.atlas = _emblem_sheet
	atlas.region = Rect2(CARD_EMBLEMS[id] * CARD_EMBLEM_SIZE, 0, CARD_EMBLEM_SIZE, CARD_EMBLEM_SIZE)
	return atlas

# Three nested wind arcs.
func _draw_swirl(canvas: Control) -> void:
	var centre := canvas.size / 2.0
	for i in 3:
		var r := 10.0 + i * 8.0
		canvas.draw_arc(centre, r, i * 1.2, i * 1.2 + PI * 1.4, 24, Color(OMEN_COLOR, 0.9 - i * 0.2), 3.0, true)

# Flips `from` (the face-down card; null = none) to the revealed Omens; Clear Skies goes.
func _reveal(offer: Array[OmenData], from: Button) -> void:
	if offer.is_empty():
		omens.choose(null)
		return
	var act := drift_director.get_act(_drifts.y)
	var fronts: Array[Button] = []
	for omen in offer:
		var front := _make_card(omen, act)
		front.name = "Omen_" + omen.id
		fronts.append(front)
	for child in _cards.get_children():
		if child != from:
			_cards.remove_child(child)
			child.queue_free()  # Clear Skies goes: no backing out
	if not omens.forced:
		_title.text = "Choose the Omen · drifts %d–%d" % [_drifts.x, _drifts.y]
	if from != null and not HeartwoodMemory.get_settings().get("reduced_motion", false):  # The flip
		from.pivot_offset = from.size / 2.0
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(from, "scale:x", 0.0, 0.18)
		tween.tween_callback(func() -> void:
			_cards.remove_child(from)
			from.queue_free()
			for front in fronts:
				_cards.add_child(front)
				front.pivot_offset = CARD_SIZE / 2.0
				front.scale.x = 0.0
				front.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).tween_property(front, "scale:x", 1.0, 0.18))
	else:
		if from != null:
			_cards.remove_child(from)
			from.queue_free()
		for front in fronts:
			_cards.add_child(front)

func _card_box(button: Button) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = CARD_PAD.x
	box.offset_top = CARD_PAD.y
	box.offset_right = -CARD_PAD.x
	box.offset_bottom = -CARD_PAD.y
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	return box

# Grows the card to fit its text (like DreamScreen._fit_card); if that would outgrow the screen, the
# secondary lines shrink first. Nothing touches or crosses the border.
func _fit_card(button: Button, box: Control, secondary: Array) -> void:
	var fit := func() -> void:
		if not is_instance_valid(button):
			return
		var needed := box.get_combined_minimum_size().y + CARD_PAD.y * 2.0
		if needed > get_viewport_rect().size.y - SCREEN_MARGIN:
			for label in secondary:
				var key := "normal_font_size" if label is RichTextLabel else "font_size"
				if label.get_theme_font_size(key) > SECONDARY_MIN_SIZE:
					label.add_theme_font_size_override(key, SECONDARY_MIN_SIZE)  # Refits via minimum_size_changed
		button.custom_minimum_size = Vector2(CARD_SIZE.x, maxf(CARD_SIZE.y, needed))
	box.minimum_size_changed.connect(fit)
	fit.call_deferred()

# A revealed Omen: the twist and its reward; a click picks it.
func _make_card(omen: OmenData, act: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(omens.choose.bind(omen))
	UiStyle.card_button(button, OMEN_COLOR)  # Moonlit Thread card (ui_style.md)
	var box := _card_box(button)
	UiStyle.title(_add_line(box, omen.display_name, UiStyle.INK, 22), UiStyle.CARD_NAME_SIZE)
	# Name, flavour (whisper), the twist, a thin divider, the reward right under it (run_design.md "Omen voice")
	var flavor: Label = null
	if omen.flavor != "":
		flavor = _add_flavor(box, omen.flavor)
	var twist := StatusLinks.make_label(omen.description, FRONT_BODY_SIZE, UiStyle.INK)  # Status words as links
	twist.mouse_filter = Control.MOUSE_FILTER_PASS  # A click still picks the Omen
	box.add_child(twist)
	var divider := HSeparator.new()
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(divider)
	var reward := omens.describe_reward(omen, act)
	if reward != "" and omen.kind != OmenData.Kind.DOUBLE_EDGED:
		reward += " · 25% less per leaf lost"  # Omens with teeth: the block decides the reward
	var reward_line := _add_line(box, "Reward · " + (reward if reward != "" else "the twist itself (double-edged)"), REWARD_COLOR, REWARD_SIZE)
	reward_line.name = "Reward"
	var spare := Control.new()  # No emblem on a revealed Omen (user: "just the beginning"); its spare height still goes here
	spare.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spare.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(spare)
	var secondary: Array = [twist, reward_line]
	if flavor != null:
		secondary.push_front(flavor)
	_fit_card(button, box, secondary)
	return button

# An Omen's flavour line: the whisper face, no quote marks (run_design.md "Omen voice").
func _add_flavor(box: VBoxContainer, text: String) -> Label:
	var label := _add_line(box, text, UiStyle.WHISPER, FLAVOR_SIZE)
	UiStyle.whisper(label, FLAVOR_SIZE)
	label.name = "Flavor"
	return label

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
	_clear_cards()
	visible = false
	game_speed.set_paused(_was_paused)

func _on_omen_started(omen: OmenData, first_drift: int, last_drift: int) -> void:
	_tag_title = "Omen: %s · drifts %d–%d" % [omen.display_name, first_drift, last_drift]
	_tag_twist = IconInfo.format(omen.description)
	var own := IconInfo.icon(StringName(omen.id))  # The Omen's own icon if it has one, else the generic one
	_tag_icon.texture = own if own != null else IconInfo.icon(&"omen")
	_active_tag.visible = true
	_refresh_tag()
	_toast("Omen faced: %s" % omen.display_name)

# The tag: "[icon] Omen: <name> · drifts 11–15", the twist, then the plain reward line ("Reward: +1 Dreamlight, less
# for each leaf lost"; none for double-edged Omens). Where the reward stands now is only in the tooltip.
var _tag_title := ""
var _tag_twist := ""
var _tag_icon := TextureRect.new()

func _refresh_tag() -> void:
	if not _active_tag.visible or omens.active == null:
		return
	var reward := omens.get_reward_line()
	_active_tag.text = "%s\n%s%s" % [_tag_title, _tag_twist, ("\n" + reward) if reward != "" else ""]
	_active_tag.tooltip_text = omens.get_reward_status()
	_place_tag_icon.call_deferred()

# The icon sits just left of the (centred) first line, one text line tall (16 px ×1, or ×2 for big text).
func _place_tag_icon() -> void:
	if _tag_icon.texture == null:
		_tag_icon.visible = false
		return
	var font := _active_tag.get_theme_font("font")
	var font_size := _active_tag.get_theme_font_size("font_size")
	var line_height := font.get_height(font_size)
	var side := 32.0 if line_height >= 28.0 else 16.0
	var width := font.get_string_size(_tag_title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_tag_icon.size = Vector2(side, side)
	_tag_icon.position = Vector2((_active_tag.size.x - width) / 2.0 - side - 6.0, (line_height - side) / 2.0)
	_tag_icon.visible = true

func _on_omen_rewarded(omen: OmenData, summary: String) -> void:
	_active_tag.visible = false
	_toast("%s passes: %s" % [omen.display_name, summary])

func _toast(text: String) -> void:
	var hud := get_parent()
	if hud.has_method("show_toast"):
		hud.show_toast(text)


# Esc / right-click = Clear Skies (not once faced, nor when an Omen must be faced: then pick one).
func _unhandled_input(event: InputEvent) -> void:
	if not visible or omens.forced or omens.faced or peek.peeking:
		return
	var right_click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT
	if event.is_action_pressed("ui_cancel") or right_click:
		omens.choose(null)
		get_viewport().set_input_as_handled()

# The third card: Clear Skies, the default (highlighted). "Nothing changes. No reward."
func _make_clear_skies_card() -> Button:
	var button := Button.new()
	button.custom_minimum_size = CARD_SIZE
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(omens.choose.bind(null))
	UiStyle.card_button(button, CLEAR_SKIES_COLOR)
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var style := button.get_theme_stylebox(state) as MoonStyleBox
		style.glow_color = CLEAR_SKIES_GLOW.lightened(0.08) if state.begins_with("hover") else CLEAR_SKIES_GLOW
	var box := _card_box(button)
	UiStyle.title(_add_line(box, "Clear Skies", CLEAR_SKIES_COLOR, 22), UiStyle.CARD_NAME_SIZE, CLEAR_SKIES_COLOR)
	_add_flavor(box, "The night stays still.")
	var calm := _add_line(box, "Nothing changes. No reward.", UiStyle.INK, FRONT_BODY_SIZE)  # The same rules spot as Face an Omen's
	box.add_child(_emblem(&"clear_skies", false, CLEAR_SKIES_COLOR))  # The moon and stars (an empty space until the icon exists)
	UiStyle.caps(_add_line(box, "The default", UiStyle.INK_DIM, 13), 14)
	_fit_card(button, box, [calm])
	return button
