extends Control

# The Omen screen at a rest (run_design.md "Commit blind, then the Omen is revealed"): a face-down
# "Face an Omen" card and Clear Skies (the default: nothing changes, no reward). Facing it flips to
# the drawn Omens (twist + reward) to pick one from; no going back. Esc / right-click = Clear Skies. Pauses and peeks like the Dream screen. Also shows the
# active Omen in a small tag under the toast, and toasts when one starts and when its reward is paid.
# Built in code.

const CARD_SIZE := Vector2(330, 330)  # Light pass (UI Asset's second page): square cards with their action at the foot
const CARD_PAD := Vector2(20, 18)  # Inner padding on every side (x: left and right, y: top and bottom)
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
var _subtitle := Label.new()  # "for drifts 11 to 15" under the title, quiet (light pass)
var _cards := HBoxContainer.new()
var _active_tag := Label.new()
var peek: ChoicePeek  # Minimise to look at the map (screens_ui.md "Choice screens")

func _ready() -> void:
	WorldLabel.cover_while_visible(self, &"omen_screen")  # No world tags (DPS, hover names) over a full-screen screen
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
	UiStyle.display(_title, 34)
	_title.add_theme_color_override("font_color", UiStyle.GOLD)
	box.add_child(_title)
	_subtitle.name = "Subtitle"
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_color_override("font_color", UiStyle.INK_DIM)
	box.add_child(_subtitle)
	_cards.add_theme_constant_override("separation", 26)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_cards)
	peek = ChoicePeek.new(self, [dim, center], "Back to the Omens")
	var peek_button := peek.make_peek_button()
	if peek_button is Button:
		UiStyle.quiet(peek_button)  # Quiet: the cards hold the choice
		peek_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(peek_button)
	arm = ChoiceArm.attach(self, _cards)
	visible = false

	# The active-Omen tag lives on the HUD, outside this (usually hidden) screen.
	_active_tag.name = "ActiveOmen"  # ComingStrip stacks under it (top centre)
	_active_tag.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_active_tag.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_active_tag.offset_top = 64
	_active_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_active_tag.add_theme_color_override("font_color", Color(OMEN_COLOR, 0.0))  # The overlay (_tag_rich) draws the text
	_active_tag.add_theme_constant_override("outline_size", 0)
	_active_tag.add_theme_stylebox_override("normal", UiStyle.fog_patch())  # A backing: reads on the pale path too
	_active_tag.visible = false
	var tag_style := _active_tag.get_theme_stylebox("normal")
	_tag_rich.bbcode_enabled = true
	_tag_rich.fit_content = true
	_tag_rich.scroll_active = false
	_tag_rich.autowrap_mode = TextServer.AUTOWRAP_OFF
	_tag_rich.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tag_rich.name = "TagText"
	_tag_rich.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tag_rich.offset_left = tag_style.get_margin(SIDE_LEFT)
	_tag_rich.offset_top = tag_style.get_margin(SIDE_TOP)
	_tag_rich.offset_right = -tag_style.get_margin(SIDE_RIGHT)
	_tag_rich.offset_bottom = -tag_style.get_margin(SIDE_BOTTOM)
	_tag_rich.add_theme_font_override("normal_font", _active_tag.get_theme_font("font"))
	_tag_rich.add_theme_font_size_override("normal_font_size", _active_tag.get_theme_font_size("font_size"))
	_tag_rich.add_theme_color_override("font_outline_color", Palette.DREAD)
	_tag_rich.add_theme_constant_override("outline_size", 6)
	_active_tag.add_child(_tag_rich)
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
	_title.text = "The wind has turned"
	_subtitle.text = "for drifts %d to %d" % [_drifts.x, _drifts.y]
	_clear_cards()
	visible = true
	arm.arm()
	if omens.forced or omens.faced:
		if omens.forced:
			_title.text = "An Omen must be faced"
		_reveal(omens.face(), null)
		return
	var back := _make_face_down_card()
	_cards.add_child(back)
	_cards.add_child(_make_clear_skies_card())

var _drifts := Vector2i.ZERO
var arm: ChoiceArm  # Cards and Esc / right-click ignore input for a moment as the screen appears

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
	ChoiceCard.solid(button)  # Hides the HUD behind it (user screenshot)
	var box := _card_box(button)
	# Light pass: the emblem beside the name and its whisper, two points, the primary at the foot.
	var top := _card_top(box, &"omen")
	UiStyle.title(_add_line(top, "Face an Omen", UiStyle.INK, 22), UiStyle.CARD_NAME_SIZE)
	_add_flavor(top, "Something's out there, waiting to be asked.")
	var points: Array = [_add_bullet(box, "A twist for the next block", UiStyle.INK, FRONT_BODY_SIZE),
		_add_bullet(box, "A reward if you survive it", UiStyle.INK, FRONT_BODY_SIZE)]
	_card_action(box, "Face it", true)
	_fit_card(button, box, points)
	button.pressed.connect(func() -> void: _reveal(omens.face(), button))
	return button

# The top of a front card: the 64 px emblem, then a column for the name and its whisper (returned).
func _card_top(box: VBoxContainer, id: StringName) -> VBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	var art := _card_emblem(id)
	if art == null:
		art = IconInfo.icon(id)
	if art != null:
		var emblem := TextureRect.new()
		emblem.name = "Emblem"
		emblem.texture = art
		emblem.custom_minimum_size = Vector2.ONE * CARD_EMBLEM_SIZE * CARD_EMBLEM_SCALE
		emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		emblem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
		emblem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(emblem)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)
	return column

# A card's action at its foot, drawn as a button (the whole card is the hit area, so a press anywhere picks it):
# the framed primary, or the plain secondary frame.
func _card_action(box: VBoxContainer, text: String, primary: bool) -> void:
	var spare := Control.new()
	spare.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spare.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(spare)
	var action := Button.new()
	action.name = "Action"
	action.text = text
	action.focus_mode = Control.FOCUS_NONE
	action.mouse_filter = Control.MOUSE_FILTER_IGNORE
	action.custom_minimum_size.y = UiStyle.HUD_BUTTON_H
	if primary:
		UiStyle.primary(action)
	ChoiceCard.link_cue(action)  # Lights with the card (hover, press)
	box.add_child(action)

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
		_title.text = "Choose the Omen"
	_subtitle.text = "for drifts %d to %d, no going back" % [_drifts.x, _drifts.y]
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
	ChoiceCard.solid(button)  # Hides the HUD behind it (user screenshot)
	var box := _card_box(button)
	UiStyle.title(_add_line(box, omen.display_name, UiStyle.INK, 22), UiStyle.CARD_NAME_SIZE)
	# Name, flavour (whisper), the twist, a thin divider, the reward right under it (run_design.md "Omen voice")
	var flavor: Label = null
	if omen.flavor != "":
		flavor = _add_flavor(box, omen.flavor)
	var twist := StatusLinks.make_label(omen.description, FRONT_BODY_SIZE - 2, UiStyle.INK)  # Status words as links
	twist.mouse_filter = Control.MOUSE_FILTER_PASS  # A click still picks the Omen
	box.add_child(twist)
	# The reward in point form (user: "point form for each different reward"): a "Reward" caps header, then a bullet
	# per reward with its own condition (OmenDirector.reward_bullets); hover or tap the header for the whole rule
	var reward_line := _add_line(box, "Reward", REWARD_COLOR, REWARD_SIZE)
	UiStyle.caps(reward_line, REWARD_SIZE, REWARD_COLOR)
	reward_line.name = "Reward"
	reward_line.tooltip_text = omens.reward_rule() if not OmenDirector.is_dew_prize(omen) else ""
	reward_line.mouse_filter = Control.MOUSE_FILTER_PASS  # The tooltip; a click still picks the Omen
	var bullet_labels: Array[Label] = []
	for text in omens.reward_bullets(omen, act, omens.current_offer_block):
		bullet_labels.append(_add_bullet(box, text))
	_card_action(box, "Take this Omen", true)  # No emblem on a revealed Omen (user: "just the beginning")
	var secondary: Array = [twist]
	secondary.append_array(bullet_labels)
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

# One reward bullet: a small gold diamond, then the text, which wraps under itself (not under the diamond).
const BULLET_SIDE := 7.0

func _add_bullet(box: VBoxContainer, text: String, colour: Color = REWARD_COLOR, font_size: int = REWARD_SIZE) -> Label:
	var row := HBoxContainer.new()
	row.name = "RewardBullet"
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var diamond := Control.new()
	diamond.custom_minimum_size = Vector2(BULLET_SIDE + 2.0, 0)
	diamond.size_flags_vertical = Control.SIZE_FILL
	diamond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	diamond.draw.connect(func() -> void:
		var c := Vector2(diamond.size.x / 2.0, font_size * 0.7)  # On the first line's middle
		var r := BULLET_SIDE / 2.0
		diamond.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)]), REWARD_COLOR))
	row.add_child(diamond)
	box.add_child(row)
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", colour)
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
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
	_tag_name = omen.display_name
	_tag_drifts = "drifts %d–%d" % [first_drift, last_drift]
	_tag_title = _tag_name + TAG_DIVIDER + _tag_drifts
	var own := IconInfo.icon(StringName(omen.id))  # The Omen's own icon if it has one, else the generic one
	_tag_icon.texture = own if own != null else IconInfo.icon(&"omen")
	_active_tag.visible = true
	_refresh_tag()
	_toast("Omen faced: %s" % omen.display_name)

# The tag (user: "one compact line"): [icon] "Crowded Paths · 11–15 · +60 Dew". The amount follows the block's
# losses (in POOR once it drops; "Reward gone" at 4+); a Dream reward reads "Reward kept" / "Reward lost"; a double-edged
# Omen shows only its name and drifts. The twist and the plain-words reward are in its tooltip (hover or tap, opaque,
# by the tag). The Label keeps the plain text (layout, ComingStrip, tests); a RichTextLabel over it draws the colours.
var _tag_title := ""
var _tag_name := ""
var _tag_drifts := ""
const TAG_DIVIDER := "  │  "  # Light pass: segments, no " · " (the bar drawn dim gold)
var _tag_icon := TextureRect.new()
var _tag_rich := RichTextLabel.new()
var _tag_tip: TapTip = null

func _refresh_tag() -> void:
	if not _active_tag.visible or omens.active == null:
		return
	var share := tag_share_text()
	_active_tag.text = _icon_pad() + _tag_title + (TAG_DIVIDER + share if share != "" else "")
	var poor := share == "Reward gone" or share == "Reward lost" or omens.get_reward_share() < 1.0
	var bar := "[color=#%s]%s[/color]" % [Color(OMEN_COLOR, 0.3).to_html(true), TAG_DIVIDER]
	_tag_rich.text = "[center]%s[color=#%s]%s[/color]%s[color=#%s]%s[/color]%s[/center]" % [_icon_pad(), UiStyle.GOLD.to_html(false),
		_tag_name, bar, UiStyle.INK_DIM.to_html(false), _tag_drifts,
		(bar + "[color=#%s]%s[/color]" % [(UiStyle.POOR if poor else OMEN_COLOR).to_html(false), share]) if share != "" else ""]
	var tip := IconInfo.format(omens.active.description) + "\n" + omens.reward_sentence(omens.active,
		drift_director.get_act(maxi(drift_director.drifts_started, 1)), omens.active_block)
	var status := omens.get_reward_status()
	if status != "":
		tip += "\n" + status
	if _tag_tip == null:
		_tag_tip = TapTip.attach(_active_tag, tip)
	_active_tag.tooltip_text = tip
	_tag_tip._label.text = tip
	_place_tag_icon.call_deferred()

# The live reward ("+30 Dew", "+5 Seeds"; "Reward 75%" without an amount) or "Reward gone"; Dream-only rewards "Reward kept" /
# "Reward lost"; "" if double-edged.
func tag_share_text() -> String:
	var omen := omens.active
	if omen == null:
		return ""
	if OmenDirector.is_dew_prize(omen):
		return omens.live_reward_text()  # "+120 of ~310": the extra Dew so far
	var dream_only := omen.reward_dew <= 0 and omen.reward_seeds <= 0 and omen.reward_tree_seeds <= 0 \
		and omen.reward_pot_multiplier <= 0.0 and omen.reward_rest_bonus_multiplier <= 1.0
	if dream_only:
		return "Reward kept" if omens.keeps_dream_reward() else "Reward lost"
	var share := omens.get_reward_share()
	if share <= 0.0:
		return "Reward gone"
	var live := omens.live_reward_text()  # "+30 Dew": the live amount (user: "or show the live Dew")
	return live if live != "" else "Reward %d%%" % roundi(share * 100)

# The icon sits in leading spaces at the start of the centred line, clear of the text.
const TAG_ICON_GAP := 8.0

func _tag_icon_side() -> float:
	return 32.0 if _active_tag.get_theme_font("font").get_height(_active_tag.get_theme_font_size("font_size")) >= 28.0 else 16.0

# Spaces wide enough for the icon and its gap ("" without an icon).
func _icon_pad() -> String:
	if _tag_icon.texture == null:
		return ""
	var font := _active_tag.get_theme_font("font")
	var space := maxf(font.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, _active_tag.get_theme_font_size("font_size")).x, 1.0)
	return " ".repeat(ceili((_tag_icon_side() + TAG_ICON_GAP) / space))

func _place_tag_icon() -> void:
	if _tag_icon.texture == null:
		_tag_icon.visible = false
		return
	var font := _active_tag.get_theme_font("font")
	var font_size := _active_tag.get_theme_font_size("font_size")
	var line_height := font.get_height(font_size)
	var side := _tag_icon_side()
	var style := _active_tag.get_theme_stylebox("normal")
	var left := style.get_margin(SIDE_LEFT) if style else 0.0
	var top := style.get_margin(SIDE_TOP) if style else 0.0
	var inner := _active_tag.size.x - left - (style.get_margin(SIDE_RIGHT) if style else 0.0)
	var width := font.get_string_size(_active_tag.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	_tag_icon.size = Vector2(side, side)
	_tag_icon.position = Vector2(left + maxf((inner - width) / 2.0, 0.0), top + (line_height - side) / 2.0)
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
	if not visible or omens.forced or omens.faced or peek.peeking or not arm.is_armed():  # A right-click cancelling build mode isn't Clear Skies
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
	ChoiceCard.solid(button)  # Hides the HUD behind it (user screenshot)
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var style := button.get_theme_stylebox(state) as MoonStyleBox
		style.glow_color = CLEAR_SKIES_GLOW.lightened(0.08) if state.begins_with("hover") else CLEAR_SKIES_GLOW
	var box := _card_box(button)
	var top := _card_top(box, &"clear_skies")  # The moon and stars beside the name
	UiStyle.title(_add_line(top, "Clear Skies", CLEAR_SKIES_COLOR, 22), UiStyle.CARD_NAME_SIZE, CLEAR_SKIES_COLOR)
	_add_flavor(top, "The night stays still.")
	var points: Array = [_add_bullet(box, "Nothing changes", UiStyle.INK_DIM, FRONT_BODY_SIZE),  # The same rules spot as Face an Omen's
		_add_bullet(box, "No reward", UiStyle.INK_DIM, FRONT_BODY_SIZE)]
	UiStyle.caps(_add_line(box, "The default, Esc", UiStyle.INK_DIM, 13), 14)
	_card_action(box, "Keep the night", false)
	_fit_card(button, box, points)
	return button
