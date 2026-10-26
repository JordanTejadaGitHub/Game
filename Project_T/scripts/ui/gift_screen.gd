extends Control
class_name GiftScreen

signal piece_placed(at: Vector2)  # A gift piece put down on the map (world position): SoundHooks' plant sound

# The gift screen (heartwood_gifts.md): at an act break, after the Dream and the family pick and before the Omen, the
# three gifts HeartwoodGifts drew as cards, or "Let them pass" (+30 Dew × the act). A map gift is placed on the screen
# itself (GiftPlacer, in the world): a ghost of its cells, the route mist showing the new route, "+N path", and cells
# refused like a Warden's (never closing the route, never on the start, a Warden, an obstacle or the Heartwood's
# glade). Esc / Back returns to the cards. Holds Start (DriftDirector.pending_choice() == &"gift"); Peek; the arm
# delay. Made by the HUD.

const BLOCKING: Array[StringName] = [&"sow_ridge", &"fallen_giant", &"spring", &"lightning_tree", &"moonwell",
	&"bell_stone", &"shift_stones"]  # Placed as obstacles / terrain the route can't cross
const HINTS := {
	&"chain": "Click cells side by side (%d–%d), then Plant.",
	&"line": "Click where it starts, then where it ends (%d–%d cells, straight).",
	&"cell": "Click a cell.",
	&"cells": "Click %d cells.",
	&"path": "Click %d connected cells of the path.",
	&"area": "Click where it goes (%d×%d).",
	&"move": "Click an obstacle, then where it goes (up to %d).",
	&"warden": "Click one of your Wardens.",
	&"kinship": "Click a Warden in a Kinship.",
	&"obstacles": "Click obstacles to clear (up to %d), again to unselect.",
	&"rim": "Click a new start on the rim, or the old one to keep it.",
}

# Each gift's living mini-scene (heartwood_gifts.md "an animated mini-scene like the placement Dream cards"): Roguelite
# Code's CardScene.show_scene(before, after, effect, caption), 7×5 rows in UpgradeData.diagram's legend plus the gift
# letters (L log, ~ pond, m moonwell, b bell stone, z lightning tree, u stump, R a Warden on a stump, k mushroom ring,
# B bog, r roots, M thick mist, f a locked form). Each scene shows the gift's payoff, not just the placement (user,
# 2026-10-07): the effect's gold numbers, chips and keys (CardScene's header lists them).
const SCENES := {
	&"sow_ridge": [".......\n.......\nSPPPPPH\n..a....\n.......", ".......\n.PPPPP.\nSP.O.PH\n..WO...\n...O...",
		{"text": "+30%", "damage": 1.3}, "A ridge: they take the long way round, and Wardens touching it deal 30% more damage."],
	&"fallen_giant": [".......\n.......\nSPPPPPH\n...a...\n.......", ".......\n.PPPPP.\nSPLLLPH\n...W...\n.......",
		{"crit": "Crit"}, "A fallen giant nothing can trample: Wardens touching it can crit, whatever their family."],
	&"glade": [".OO....\n.OO.O..\nSPPPPPH\n....O..\n.......", ".OO....\n.......\nSPPPPPH\n.......\n.......",
		{"cleared": "free · tended"}, "The obstacles you pick are cleared for free, and each counts as tended."],
	&"shift_stones": ["....OO.\n.......\nSPPPPPH\n.......\n.O.....", ".......\n.PPPPP.\nSP.O.PH\n...O...\n...O...",
		{"cleared": UiStyle.DEW_GLYPH + "+30"}, "The stones move where you need a wall, and each one pays Dew."],
	&"mire": [".......\n...a...\nSPPPPPH\n.......\n.......", ".......\n...a...\nSBBBBBH\n.......\n.......",
		{"bog": "35% slower"}, "Bog underfoot: they walk 35% slower, and {held} lasts twice as long there."],
	&"spring": [".......\n...a...\n.......\nSPPPPPH\n.......", ".......\n.~~W...\n.~~....\nSPPPPPH\n.......",
		{"zone": {"letters": "~", "cells": 2.0, "word": "", "every": 0.0}, "text": "+25% speed", "speed": 1.25}, "Wardens near the Spring attack faster, whatever their family."],
	&"mushroom_ring": [".......\n....a..\nSPPPPPH\n.......\n.......", ".......\n.kkkW..\nSPPPPPH\n.kkk...\n.......",
		{"zone": {"letters": "k", "cells": 1.0, "word": "+50% stacks", "every": 0.0}}, "Any status put on a nightmare standing in the ring lands with more stacks."],
	&"lightning_tree": [".......\n....a..\nSPPPPPH\n.......\n.......", ".......\n..z.W..\nSPPPPPH\n.......\n.......",
		{"zone": {"letters": "z", "cells": 3.0, "word": "struck", "every": 1.6}}, "The Lightning Tree strikes the strongest nightmare near it, again and again."],
	&"moonwell": [".......\n....a..\nSPPPPPH\n.......\n.......", ".......\n...mW..\nSPPPPPH\n.......\n.......",
		{"zone": {"letters": "m", "cells": 2.0, "word": "", "every": 0.0}, "text": "+1.5 range", "range": 1.5}, "Wardens near the Moonwell reach further and see Hidden nightmares."],
	&"bell_stone": [".......\n....a..\nSPPPPPH\n.......\n.......", ".......\n...bW..\nSPPPPPH\n.......\n.......",
		{"zone": {"letters": "b", "cells": 3.0, "word": "30% slower", "every": 1.6}}, "The Bell Stone rings: nightmares near it walk slower for a moment."],
	&"ancient_stump": [".......\n...a...\nSPPPPPH\n.......\n.......", ".......\n.u.R.u.\nSPPPPPH\n.......\n.......",
		{"text": "Nurture rank II", "damage": 1.2}, "Plant on a stump: the Warden gets 2 free Nurture ranks."],
	&"heartwood_roots": [".......\n....a..\nSPPPPPH\n.......\n.......", ".......\n....W..\nSPrrrrH\n.......\n.......",
		{"text": "+30% taken", "damage": 1.3}, "Roots before the Heartwood: nightmares gain {held} on entering and take more damage there."],
	&"reshape": ["....OO.\n.......\nSPPPPPH\n....O..\n.O.....", ".......\n.PPPPP.\nSP.O.PH\n...O...\n...O...",
		{"cleared": UiStyle.DEW_GLYPH + "+30"}, "Move the obstacles into a wall, or clear them away; each one pays Dew."],
	&"bramble_verge": [".......\n.T.T.T.\nSPPPPPH\n.......\n.......", ".......\n.X.X.X.\nSPPPPPH\n.......\n.......",
		{"proc": "20% slower"}, "Thornwalls grow into Bramble free; Brambles slow the nightmares beside them."],
	&"old_kin": [".......\n..aa...\nSPPPPPH\n.......\n.......", ".......\n..WW...\nSPPPPPH\n.......\n.......",
		{"text": "kin +1 stage", "damage": 1.1, "kin": true}, "A Kinship deepens a stage at once."],  # The bond drawn (CardScene 4e14a81c)
	&"shifting_mist": [".......\n.......\nSPPPPPH\n.......\n.......", "...S...\n...P...\n...PPPH\n.......\n.......",
		{"chip": UiStyle.DEW_GLYPH + " +25%"}, "The start moves: a new way in, and this act's drifts give 25% more Dew."],
	&"waking_root": [".......\n...f...\n.......\nSPPPPPH\n.......", ".......\n...f...\n.......\nSPPPPPH\n.......",
		{"unlock": true, "price_from": 2, "price_to": 0}, "The next form you unlock is free."],
	&"memory_seed": [".......\n.a.....\nSPPPPPH\n.......\n.......", ".......\n.....W.\nSPPPPPH\n.......\n.......",
		{"text": "keeps its Nurture ranks"}, "This act, a Warden you sell and plant again keeps its Nurture ranks and its Kinship."],
}

var drift_director: DriftDirector
var gifts: HeartwoodGifts
var preview: CardScene  # The hovered (else the first) gift's mini-scene, above the cards
var placer: GiftPlacer
var peek: ChoicePeek
var arm: ChoiceArm
var placing: StringName = &""  # The gift being placed (the cards hidden)
var _cards := HBoxContainer.new()
var _pass := Button.new()
var _choose: Control  # The cards' page (dim + centre)
var _dim := ColorRect.new()
var _place_bar := PanelContainer.new()
var _place_label := Label.new()
var _plant := Button.new()
var _undo := Button.new()  # Touch only (PC: right-click)
var _clear := Button.new()
# Phones (UiStyle.is_phone()): the Dream screen's layout (PhoneChoice: header with Peek, the cards filling the view, the
# bottom row with Skip the gifts, the hint and Take); a tap looks at a card and plays its scene beside it, Take or a
# second tap picks it. The PC is unchanged.
const PhoneChoice := preload("res://scripts/ui/phone_choice.gd")
var _layout: PhoneChoice = null
var _count := 3  # Cards in the row (phones: their width)

func _init(director: DriftDirector = null, gift_node: HeartwoodGifts = null) -> void:
	drift_director = director
	gifts = gift_node

func _ready() -> void:
	WorldLabel.cover_while_visible(self, &"gift_screen")  # No world tags (DPS, hover names) over a full-screen screen
	name = "GiftScreen"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_dim.color = Color(UiStyle.FOG, 0.72)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	var title := Label.new()
	title.text = "The Heartwood offers a gift"
	preview = CardScene.new()  # Always there (touch: no hover needed); hovering a card plays its scene
	preview.name = "GiftScene"
	_pass.focus_mode = Control.FOCUS_NONE
	_pass.custom_minimum_size = Vector2(240, 48)
	_pass.pressed.connect(func() -> void:
		gifts.let_pass()
		_close())
	_pass.icon = IconInfo.icon(&"dew")  # "Let them pass, +30 [Dew]": the secondary frame
	_pass.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_pass.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if UiStyle.is_phone():
		var subtitle := Label.new()
		subtitle.name = "Subtitle"
		subtitle.text = PhoneChoice.sentence("take one, or skip them")
		_layout = PhoneChoice.new(self, title, subtitle, _cards)
		_layout.add_left(_pass)
		_pass.clip_text = false  # "Skip the gifts, +60" and its Dew glyph: grows rather than trims
		# The scene plays beside the looked card (as the Dream diagram), over the dimmed others; on the dim, so a peek
		# or placing hides it too.
		preview.z_index = 10
		_dim.add_child(preview)
		peek = ChoicePeek.new(self, [_dim, _layout.margin], "Back to the gifts")
		_layout.add_peek(peek.make_peek_button())
		_choose = _layout.margin
	else:
		var centre := CenterContainer.new()
		centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(centre)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 18)
		centre.add_child(box)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiStyle.display(title, 28)
		box.add_child(title)
		preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(preview)
		_cards.add_theme_constant_override("separation", 16)
		_cards.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_child(_cards)
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 12)
		box.add_child(row)
		row.add_child(_pass)
		peek = ChoicePeek.new(self, [_dim, centre], "Back to the gifts")
		var peek_button := peek.make_peek_button()
		if peek_button is Button:
			UiStyle.quiet(peek_button)  # Light pass: quiet; the cards hold the choice
		row.add_child(peek_button)
		_choose = centre
	arm = ChoiceArm.attach(self, _cards)
	# Placing: the cards go, a bar at the bottom says what to do; the world takes the clicks.
	_place_bar.visible = false
	_place_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_place_bar.offset_top = -190
	_place_bar.offset_bottom = -120
	_place_bar.offset_left = -320
	_place_bar.offset_right = 320
	_place_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(_place_bar)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	_place_bar.add_child(bar)
	_place_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_place_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bar.add_child(_place_label)
	# Three ways out of placing (heartwood_gifts.md 42f5da78): Undo (right-click; touch: this button) and Clear (quiet
	# utilities: still placing), Back (secondary: the three cards again, nothing spent), Plant it (the primary: commits).
	_undo.name = "Undo"
	_undo.text = "Undo"
	_undo.pressed.connect(func() -> void: if placer != null: placer.undo())
	_clear.name = "ClearPicks"
	_clear.text = "Clear"
	_clear.pressed.connect(func() -> void: if placer != null: placer.clear())
	for utility in [_undo, _clear]:
		utility.focus_mode = Control.FOCUS_NONE
		utility.custom_minimum_size = Vector2(80, 44)
		UiStyle.quiet(utility)
		bar.add_child(utility)
	var back := Button.new()
	back.name = "Back"
	back.text = "Back"
	back.focus_mode = Control.FOCUS_NONE
	back.custom_minimum_size = Vector2(100, 44)
	back.pressed.connect(cancel_placing)
	bar.add_child(back)
	_plant.text = "Plant it"
	_plant.focus_mode = Control.FOCUS_NONE
	_plant.custom_minimum_size = Vector2(120, 44)
	UiStyle.primary(_plant)
	_plant.pressed.connect(confirm_placing)
	bar.add_child(_plant)
	if _layout != null:  # Phones: 48 px tap targets, as on the cards' screen
		for button in [_undo, _clear, back, _plant]:
			button.custom_minimum_size.y = UiStyle.HUD_BUTTON_H
	_hook_landmarks.call_deferred()  # After the map has made its gifts node
	gifts.offer_closed.connect(func() -> void:
		if visible:
			_close())

# --- A landmark arrives, and grows (heartwood_gifts.md "Gifts as landmarks" 5 and 3) -------------------------------
# The arrival: the camera follows the Heartwood's roots to the spot (Environment Code's MapGifts.gift_arriving /
# gift_arrived), holds a moment, then goes back where it was. Moving the view yourself ends it (the camera drops a
# glide on any pan), and then it doesn't go back. None under reduced motion.
const ARRIVAL_HOLD := 0.8
const ARRIVAL_BACK := 1.0
var _arrival_home := Vector2.INF  # Where the view was before the glide

func _hook_landmarks() -> void:
	var map := drift_director.get_node_or_null("%MapGenerator") if drift_director != null else null
	var map_gifts = map.get("gifts") if map != null else null
	if map_gifts != null and map_gifts.has_signal("gift_arriving"):
		map_gifts.gift_arriving.connect(_on_gift_arriving)
		map_gifts.gift_arrived.connect(_on_gift_arrived)
	if gifts != null and gifts.has_signal("gift_grew"):
		gifts.gift_grew.connect(_on_gift_grew)

func _camera() -> Node:
	return get_tree().get_first_node_in_group(&"game_camera")

func _on_gift_arriving(_id: StringName, from: Vector2, to: Vector2, seconds: float) -> void:
	var camera := _camera()
	var view := get_viewport().get_camera_2d()
	if camera == null or view == null or not camera.has_method("glide") or bool(Fx.setting("reduced_motion", false)):
		return
	_arrival_home = view.get_screen_center_position()
	camera.glide(PackedVector2Array([_arrival_home, from, to]), maxf(seconds, 0.6))

func _on_gift_arrived(_id: StringName, at: Vector2) -> void:
	if _arrival_home == Vector2.INF:
		return
	var home := _arrival_home
	_arrival_home = Vector2.INF
	await get_tree().create_timer(ARRIVAL_HOLD, true, false, true).timeout
	var camera := _camera()
	var view := get_viewport().get_camera_2d() if is_inside_tree() else null
	if camera == null or view == null or view.get_screen_center_position().distance_to(at) > 96.0:
		return  # The player moved the view meanwhile: it stays where they put it
	camera.glide(PackedVector2Array([at, home]), ARRIVAL_BACK)

# A landmark grew a step at an act break: one short line each, in one toast.
var _grew: Array[String] = []

func _on_gift_grew(id: StringName, step: int, _placement: Dictionary) -> void:
	_grew.append(growth_line(id, step))
	if _grew.size() == 1:
		_show_growth.call_deferred()

func _show_growth() -> void:
	var hud := get_parent()
	if hud != null and hud.has_method("show_toast") and not _grew.is_empty():
		hud.show_toast("\n".join(_grew))
	_grew.clear()

# "The Spring grows: it now Soaks 3 stacks a second." Numbers from HeartwoodGifts at the new step.
static func growth_line(id: StringName, step: int) -> String:
	var gift_name: String = HeartwoodGifts.POOL[id].name if HeartwoodGifts.POOL.has(id) else String(id).capitalize()
	var head := "The %s gets stronger" % gift_name if not gift_name.ends_with("s") else "The %s get stronger" % gift_name
	match id:
		&"spring":
			return "%s: Wardens near it now attack %d%% faster." % [head, roundi(HeartwoodGifts.stat(id, "attack_speed", step) * 100.0)]
		&"lightning_tree":
			return "%s: it now strikes every %s s, and harder." % [head, str(snappedf(HeartwoodGifts.stat(id, "strike_every", step), 0.1))]
		&"bell_stone":
			return "%s: its ring now slows nightmares by %d%% for %s s." % [head, roundi(HeartwoodGifts.stat(id, "slow", step) * 100.0), str(snappedf(HeartwoodGifts.stat(id, "slow_seconds", step), 0.1))]
		&"mushroom_ring":
			return "%s: statuses put on nightmares inside it now land with %d%% more stacks." % [head, roundi(HeartwoodGifts.stat(id, "status_stacks_share", step) * 100.0)]
		&"moonwell":
			return "%s: Wardens near it now get +%s range." % [head, str(snappedf(HeartwoodGifts.stat(id, "range", step), 0.01))]
		&"heartwood_roots":
			return "%s: they now cover %d cells of path, and nightmares there take %d%% more damage." % [head,
				roundi(HeartwoodGifts.stat(id, "path_cells", step)), roundi(HeartwoodGifts.stat(id, "damage_taken", step) * 100.0)]
	return "%s (step %s)." % [head, HeartwoodGifts.STEP_NAMES[clampi(step, 0, HeartwoodGifts.STEP_NAMES.size() - 1)]]

# Opens once the Dream (and the family pick) are done: DriftDirector.pending_choice() names the gift.
func _process(_delta: float) -> void:
	if gifts.waiting and not visible and drift_director.pending_choice() == &"gift" and not RestScreens.any_open(self, drift_director):
		open()  # Its turn, and nothing else on screen (one paused screen at a time)
	if placing != &"" and placer != null:
		_plant.disabled = not placer.is_complete()
		_undo.visible = InputMode.touch()
		_place_label.text = "%s: %s\n%s" % [HeartwoodGifts.POOL[placing].name, placer.status(),
			InputMode.text("Right-click undoes the last pick, Esc goes back to the gifts.", "Undo takes back the last pick, Back returns to the gifts.")]

func open() -> void:
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	_count = maxi(gifts.current_offer.size(), 1)
	if _layout != null:
		_layout.reset()
		preview.stop()  # Phones: no scene until a card is looked at
	for id in gifts.current_offer:
		_cards.add_child(_card(id))
	_pass.text = "Skip the gifts, +%d" % gifts.pass_dew()  # The Dew glyph after it (no " · ")
	if _layout != null:
		_layout.fit_choices()  # Skip and Take the same width (the wider one's)
	if not gifts.current_offer.is_empty() and _layout == null:
		show_scene(gifts.current_offer[0])
	visible = true
	_show_cards(true)
	arm.arm()

# A gift card styled like the Dream cards (user: plain centred text looked unfinished): its emblem (UI Asset's gift
# icon "gift_<id>" once drawn, else its category's glyph), the name in the display font, the category in small caps
# in its colour, and the text in the body font with status words linked. Solid, like every paused card.
# The three kinds an offer holds (heartwood_gifts.md "Gifts as landmarks"): the small label on each card, its glyph
# and colour.
const KIND_LABELS := {&"land": "Shape the land", &"landmark": "Landmark", &"boon": "Boon"}
const KIND_STYLE := {&"land": [&"stone", Palette.MOONLIGHT], &"landmark": [&"root", Palette.SPRIG], &"boon": [&"leaves", UiStyle.GOLD]}
const GROUP_STYLE := {
	"Shape the land": [&"stone", Palette.MOONLIGHT],
	"Living ground": [&"root", Palette.SPRIG],
	"The nightmares' way": [&"path_length", Palette.DEWLIGHT],
	"Heartwood and kin": [&"leaves", UiStyle.GOLD],
}
# The gifts' emblem sheet (UI Asset): {id: [x, y, w, h]} in gifts.json. The texture lives on this instance (a Texture in
# a static crashes the exit).
const EMBLEM_SHEET := "res://assets/ui/gifts/gifts.png"
const EMBLEM_MAP := "res://assets/ui/gifts/gifts.json"
var _emblem_map := {}
var _emblem_sheet: Texture2D = null

func _gift_emblem(id: StringName) -> Texture2D:
	if _emblem_map.is_empty() and FileAccess.file_exists(EMBLEM_MAP):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(EMBLEM_MAP))
		_emblem_map = parsed if parsed is Dictionary else {}
		_emblem_sheet = load(EMBLEM_SHEET) if ResourceLoader.exists(EMBLEM_SHEET) else null
	var rect = _emblem_map.get(String(id))
	if _emblem_sheet == null or not (rect is Array) or rect.size() < 4:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = _emblem_sheet
	atlas.region = Rect2(rect[0], rect[1], rect[2], rect[3])
	return atlas

const CARD_SIZE := Vector2(300, 220)  # Light pass: 300 wide, grows with its text; the screen still fits 720 under the banner

func _card(id: StringName) -> Button:
	var gift: Dictionary = HeartwoodGifts.POOL[id]
	var kind: StringName = HeartwoodGifts.kind_of(id)
	var style: Array = KIND_STYLE.get(kind, GROUP_STYLE.get(gift.group, [&"leaves", UiStyle.GOLD]))
	var colour: Color = style[1]
	var button := Button.new()
	button.name = String(id)
	button.custom_minimum_size = _card_size()
	button.focus_mode = Control.FOCUS_NONE
	UiStyle.card_button(button, colour)
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var box := button.get_theme_stylebox(state) as MoonStyleBox
		if box != null:
			box.center_alpha = UiStyle.TIP_ALPHA  # Solid: no screen shows through a paused card (user)
			box.edge_alpha = UiStyle.TIP_ALPHA
	button.pressed.connect(func() -> void: _press(button, id, "Take %s" % gift.name))
	if _layout == null:
		button.mouse_entered.connect(show_scene.bind(id))  # Phones: the look plays it
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 18
	box.offset_top = 18
	box.offset_right = -18
	box.offset_bottom = -14
	if _layout != null:  # The Dream card's padding
		box.offset_left = PhoneChoice.CARD_PAD.x
		box.offset_top = PhoneChoice.CARD_PAD.y
		box.offset_right = -PhoneChoice.CARD_PAD.z
		box.offset_bottom = -PhoneChoice.CARD_PAD.w
	box.add_theme_constant_override("separation", 8)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	# Light pass (UI Asset's last page): the emblem beside the name and its category; what it is in one line, what it
	# does as bullets; the framed "Plant it" at the foot (drawn: the whole card is the hit area).
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(header)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 2)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	icon.name = "Emblem"
	var emblem := _gift_emblem(id)  # UI Asset's gift emblem (7220e5fa), else the category's glyph tinted
	icon.texture = emblem if emblem != null else IconInfo.icon(style[0])
	icon.custom_minimum_size = Vector2(48, 48)  # The 32 px emblem at 1.5×, the 16 px glyphs at 3×
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if emblem == null:
		icon.modulate = colour  # multiplier: the category's colour on the glyph
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(icon)
	header.add_child(names)
	var title := Label.new()
	title.name = "Name"
	title.text = gift.name
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.title(title, _sz(24, PhoneChoice.NAME_SIZE))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.add_child(title)
	var group := Label.new()
	group.name = "Category"
	group.text = KIND_LABELS.get(kind, gift.group)
	UiStyle.caps(group, _sz(13, PhoneChoice.LABEL_CAPS), colour)
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.add_child(group)
	# What it is (the first sentence), then what it does, a bullet per sentence. Status words stay links.
	var sentences := String(gift.text).split(". ", false)
	var text := StatusLinks.make_label(sentences[0] + ("." if sentences.size() > 1 else ""), _sz(15, PhoneChoice.BODY_SIZE), UiStyle.INK)
	text.name = "Text"
	text.mouse_filter = Control.MOUSE_FILTER_PASS  # Status words hover; a click still picks the card
	box.add_child(text)
	for i in range(1, sentences.size()):
		var line := String(sentences[i]).trim_suffix(".")
		box.add_child(_bullet(line))
	if kind == HeartwoodGifts.KIND_LANDMARK:  # That it grows (no family line: every gift is generic, heartwood_gifts.md "Amendment")
		var grows := StatusLinks.make_label(HeartwoodGifts.GROWS_LINE, _sz(14, PhoneChoice.SMALL_SIZE), UiStyle.INK_DIM)
		grows.name = "Grows"
		grows.mouse_filter = Control.MOUSE_FILTER_PASS
		box.add_child(grows)
	var spare := Control.new()
	spare.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spare.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(spare)
	if _layout == null:  # Phones: the bottom row's Take names it (as on the Dream cards: no button on the card)
		var plant := Button.new()
		plant.name = "PlantIt"
		plant.text = "Plant it"
		plant.focus_mode = Control.FOCUS_NONE
		plant.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plant.custom_minimum_size.y = UiStyle.HUD_BUTTON_H
		# Secondary, like the Dream cards: no card is the default (story chat)
		ChoiceCard.link_cue(plant)  # Lights with the card (hover, press)
		box.add_child(plant)
	else:
		_layout.fill(button)  # The column's width; the row shares the tallest's height
		_layout.watch_links(button)
		PhoneChoice.card_thread(button, colour)  # One sprout per screen: Take's
	box.minimum_size_changed.connect(func() -> void:
		button.custom_minimum_size = Vector2(_card_size().x, maxf(_card_size().y, box.get_combined_minimum_size().y + box.offset_top - box.offset_bottom)))
	return button

# The PC size, or the phone size (PhoneChoice: the Dream card's text sizes).
func _sz(pc: int, phone: int) -> int:
	return phone if _layout != null else pc

# CARD_SIZE on the PC; phones: an equal column of the view's width, at least the Dream card's height.
func _card_size() -> Vector2:
	if _layout == null:
		return CARD_SIZE
	return Vector2(_layout.card_width(_count), PhoneChoice.CARD_MIN_H)

# A card's press: phones look first (its scene plays beside it; Take, or a second tap, picks it); the PC picks at once.
func _press(button: Button, id: StringName, take_text: String) -> void:
	if _layout != null and _layout.tap(button, take_text):
		show_scene(id)
		return
	pick(id)

# One point of what a gift does: a small gold diamond, then the words (status words linked), wrapping under themselves.
func _bullet(text: String) -> Control:
	var row := HBoxContainer.new()
	row.name = "Point"
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var diamond := Control.new()
	diamond.custom_minimum_size = Vector2(9, 0)
	diamond.size_flags_vertical = Control.SIZE_FILL
	diamond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	diamond.draw.connect(func() -> void:
		var c := Vector2(diamond.size.x / 2.0, 10.0)
		diamond.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -3.5), c + Vector2(3.5, 0), c + Vector2(0, 3.5), c + Vector2(-3.5, 0)]), UiStyle.GOLD))
	row.add_child(diamond)
	var label := StatusLinks.make_label(text, _sz(14, PhoneChoice.SMALL_SIZE), UiStyle.INK_DIM)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(label)
	return row

# Plays gift `id`'s before → after mini-scene in the preview (a still after-diagram under reduced motion).
# A gift's scene with its numbers read from HeartwoodGifts at the step the player's landmark has reached (step I on
# the offer): [before, after, effect, caption].
func scene_for(id: StringName) -> Array:
	var scene: Array = (SCENES[id] as Array).duplicate(true)
	var step := maxi(gifts.step_of(id), 1) if gifts != null else 1
	var effect: Dictionary = scene[2]
	if effect.get("zone") is Dictionary and HeartwoodGifts.zone_cells(id) > 0.0:
		effect.zone["cells"] = HeartwoodGifts.zone_cells(id)
	match id:
		&"spring":
			effect["speed"] = 1.0 + HeartwoodGifts.stat(id, "attack_speed", step)
			effect["text"] = "+%d%% speed" % roundi(HeartwoodGifts.stat(id, "attack_speed", step) * 100.0)
		&"bell_stone":
			effect.zone["word"] = "%d%% slower" % roundi(HeartwoodGifts.stat(id, "slow", step) * 100.0)
		&"mushroom_ring":
			effect.zone["word"] = "+%d%% stacks" % roundi(HeartwoodGifts.stat(id, "status_stacks_share", step) * 100.0)
		&"moonwell":
			effect["range"] = HeartwoodGifts.stat(id, "range", step)
			effect["text"] = "+%s range" % str(snappedf(HeartwoodGifts.stat(id, "range", step), 0.01))
		&"heartwood_roots":
			effect["damage"] = 1.0 + HeartwoodGifts.stat(id, "damage_taken", step)
			effect["text"] = "+%d%% taken" % roundi(HeartwoodGifts.stat(id, "damage_taken", step) * 100.0)
	return scene

func show_scene(id: StringName) -> void:
	if not SCENES.has(id) or preview == null:
		return
	var looked: Button = null
	if _layout != null:  # Phones: only the looked card's scene, beside it
		looked = _layout.looked if _layout.looked != null and is_instance_valid(_layout.looked) else null
		if looked == null:
			preview.stop()
			return
		if looked.name != String(id):
			return  # A tap on another card's underlined word: the looked card's scene stays
	var scene: Array = scene_for(id)
	preview.show_scene(scene[0], scene[1], scene[2], scene[3])
	preview.set_meta(&"gift", id)
	if looked != null:
		_place_preview(looked)

# Phones: the scene beside the looked card (right of it, or left when there's no room), kept on screen (as the Dream
# screen's diagram).
func _place_preview(card: Control) -> void:
	await get_tree().process_frame
	if not is_instance_valid(card) or not preview.visible:
		return
	var view := get_viewport_rect().size
	var rect := card.get_global_rect()
	var size := preview.get_combined_minimum_size()
	var x := rect.end.x + 8.0
	if x + size.x > view.x - 8.0:
		x = rect.position.x - size.x - 8.0
	var y := clampf(rect.position.y + 24.0, 8.0, view.y - size.y - 8.0)
	preview.global_position = Vector2(maxf(x, 8.0), y)

# A card: placed first (map gifts), else taken now.
func pick(id: StringName) -> void:
	if not HeartwoodGifts.needs_placing(id):
		gifts.choose(id)
		_close()
		return
	placing = id
	_show_cards(false)
	if preview != null:
		preview.stop()  # Hidden while placing: nothing runs
	placer = GiftPlacer.new(drift_director, id, BLOCKING.has(id))
	placer.on_placed = piece_placed.emit  # Each piece put down: SoundHooks plays the Warden plant sound
	drift_director.owner.add_child(placer)
	_plant.text = "Clear them" if placer.kind == &"obstacles" else "Plant it"
	_clear.text = "Unpick all" if placer.kind == &"obstacles" else "Clear"  # Glade's commit is "Clear them"

func cancel_placing() -> void:
	var was := placing
	if placer != null:
		placer.queue_free()
		placer = null
	placing = &""
	_show_cards(true)
	if was != &"":
		show_scene(was)

func confirm_placing() -> void:
	if placer == null or not placer.is_complete():
		return
	var placement := placer.placement()
	var id := placing
	cancel_placing()
	gifts.choose(id, placement)
	_close()

func _show_cards(on: bool) -> void:
	_choose.visible = on
	_dim.visible = on
	_place_bar.visible = not on
	mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE  # Placing: the world takes clicks

func _close() -> void:
	if placer != null:
		placer.queue_free()
		placer = null
	placing = &""
	if preview != null:
		preview.stop()
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if placing == &"":
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()  # Right-click: undo the last pick (heartwood_gifts.md 42f5da78)
		if placer != null:
			placer.undo()
	elif event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.is_action_pressed("cancel_build")):
		get_viewport().set_input_as_handled()  # Esc: back to the three gifts, nothing spent
		cancel_placing()


# The ghost of a gift being placed, in the world: the cells picked (and the one under the pointer), valid or refused,
# the route it would leave (route mist) and its "+N path". Builds the placement HeartwoodGifts stores.
class GiftPlacer extends Node2D:
	var director: DriftDirector
	var map: Node
	var seller: TowerSeller
	var id: StringName
	var kind: StringName
	var size
	var blocking := false
	var cells: Array[Vector2] = []  # Picked (move: the targets)
	var froms: Array[Vector2] = []  # Move: the obstacles picked up
	var tower: Tower = null
	var hover := Vector2(-1, -1)
	var route_line := Line2D.new()
	var _route_now := 0
	var options: Array[Vector2] = []  # Rim: the new start spots on offer (the current start = keep)

	func _init(drift_director: DriftDirector, gift_id: StringName, blocks: bool) -> void:
		director = drift_director
		id = gift_id
		kind = HeartwoodGifts.POOL[id].place
		size = HeartwoodGifts.POOL[id].size
		blocking = blocks

	func _ready() -> void:
		name = "GiftPlacer"
		z_index = 20
		process_mode = Node.PROCESS_MODE_ALWAYS
		map = director.get_node_or_null("%MapGenerator")
		seller = director.get_node_or_null("%TowerSeller")
		add_child(route_line)
		_route_now = map.route_length(map.get_path_from(map.startPath)) if map != null else 0  # Full cells
		if kind == &"rim" and map != null and map.get("gifts") != null and map.gifts.has_method("start_options"):
			options.assign(map.gifts.start_options(int(size)))

	func _process(_delta: float) -> void:
		var cell := _hover_at(map.get_local_mouse_position())
		if cell != hover:
			hover = cell
			_refresh_route()
			queue_redraw()

	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			click(hover)
			get_viewport().set_input_as_handled()

	# Takes back the last pick (heartwood_gifts.md 42f5da78 "Three ways out of placing"): a line's start (or the whole
	# line), a chain's last piece, the last cell or stone; a held stone goes back first. Nothing picked: nothing.
	func undo() -> void:
		match kind:
			&"line", &"rim":
				cells.clear()
			&"warden", &"kinship":
				tower = null
			&"move":
				if froms.size() > cells.size():
					froms.pop_back()
				elif not cells.is_empty():
					cells.pop_back()
			_:
				if not cells.is_empty():
					cells.pop_back()
		_refresh_route()
		queue_redraw()

	# Empties every pick; still placing the same gift.
	func clear() -> void:
		cells.clear()
		froms.clear()
		tower = null
		_refresh_route()
		queue_redraw()

	# One click on `cell` (this kind's units, see _hover_at), by kind (tests call it too). A piece put down plays the
	# Warden build sound; a click that couldn't place plays the refusal.
	func click(cell: Vector2) -> void:
		var before := cells.size()
		var toggling := cells.has(cell)
		_click(cell)
		var places := PIECE_KINDS.has(kind) or kind == &"path"
		if places and kind == &"move" and froms.size() > before and cells.size() == before:
			places = false  # Picked a stone up, nothing put down yet
		if places and cells.size() > before:
			_placed(cells[-1] if cells[-1] != Vector2(-99, -99) else cells[0])
		elif places and not toggling and cells.size() <= before and not (kind == &"line" and before == 2):
			_refused(cell)
		_refresh_route()
		queue_redraw()

	func _click(cell: Vector2) -> void:
		match kind:
			&"chain":
				if cells.has(cell):
					cells.assign(cells.slice(0, cells.find(cell)))  # Click back on the chain: shorten it there
				elif cells.size() < size[1] and _cell_ok(cell) and (cells.is_empty() or _adjacent(cells[-1], cell)) and _route_ok(cells + [cell]):
					cells.append(cell)
			&"line":
				if cells.size() >= 1 and cells.size() < 2:
					var line := _line_fit(cells[0], cell)  # Past the limit: up to it (heartwood_gifts.md 52d11575)
					if line.size() >= size[0] and line.all(_cell_ok) and _route_ok(line):
						cells.assign(line)
						cells.append(Vector2(-99, -99))  # Marker: done (removed in placement())
				else:
					cells.clear()
					if _cell_ok(cell):
						cells.append(cell)
			&"cell":
				cells.clear()
				if _cell_ok(cell) and _route_ok([cell]):
					cells.append(cell)
			&"cells":
				if cells.has(cell):
					cells.erase(cell)
				elif cells.size() < int(size) and _cell_ok(cell):
					cells.append(cell)
			&"path":  # Route halves, connected (Mire: `size` cells of route = twice as many halves)
				if cells.has(cell):
					cells.erase(cell)
				elif cells.size() < int(size) * 2 and _route_half_ok(cell) \
						and (cells.is_empty() or cells.any(func(c: Vector2) -> bool: return _adjacent(c, cell))):
					cells.append(cell)
			&"area":
				var area := _area(cell)
				cells.clear()
				if area.all(_cell_ok) and (not blocking or _route_ok(area)):
					cells.assign(area)
			&"move":
				if froms.size() > cells.size():  # An obstacle in hand: put it down
					if _cell_ok(cell) and _route_ok(cells + [cell], froms):
						cells.append(cell)
				elif froms.size() < int(size) and map.obstacles.has(cell) and not froms.has(cell):
					froms.append(cell)
			&"warden", &"kinship":
				var picked := seller.get_tower_at(cell) if seller != null else null
				tower = picked if picked != null and (kind == &"warden" or _in_kinship(picked)) else null
			&"rim":  # Shifting Mist: one of the offered spots, or the old start (keep)
				if options.has(cell) or cell == map.startPath:
					cells.assign([cell])
			&"obstacles":  # Glade (user: "no control and no preview"): pick each obstacle, again to unselect
				var at := _picked_obstacle(cell)
				if at != Vector2(-1, -1):
					cells.erase(at)
				elif cells.size() < int(size) and map.obstacles.has(cell):
					cells.append(cell)
		_refresh_route()
		queue_redraw()

	# The picked obstacle `cell` belongs to (a log covers several cells), else (-1, -1).
	func _picked_obstacle(cell: Vector2) -> Vector2:
		for at in cells:
			if at == cell or map.get_obstacle_cells(at).has(cell):
				return at
		return Vector2(-1, -1)

	# The route with `picked` obstacles (and their whole logs) cleared, as MapGenerator.get_path_if_cleared for one.
	func _path_if_cleared(picked: Array) -> PackedVector2Array:
		var opened: Array[Vector2] = []
		for at in picked:
			for c in map.get_obstacle_cells(at):
				if not opened.has(c):
					opened.append(c)
		for c in opened:
			map.path_layer.set_cell_blocked(c, false)
		var path: PackedVector2Array = map.path_layer.find_path_from(map.startPath)
		for c in opened:
			map.path_layer.set_cell_blocked(c, true)
		return path

	func is_complete() -> bool:
		match kind:
			&"chain":
				return cells.size() >= size[0]
			&"line":
				return cells.size() >= 2 and cells[-1] == Vector2(-99, -99)
			&"cell":
				return cells.size() == 1
			&"cells":
				return cells.size() == int(size)
			&"path":
				return cells.size() == int(size) * 2
			&"area":
				return not cells.is_empty()
			&"move":
				return not cells.is_empty() and cells.size() == froms.size()
			&"warden", &"kinship":
				return tower != null
			&"obstacles":
				return not cells.is_empty()  # Up to `size`: any number from one
			&"rim":
				return cells.size() == 1
		return true

	func status() -> String:
		var hint: String = GiftScreen.HINTS.get(kind, "")
		match kind:
			&"chain", &"line":
				hint = hint % [size[0], size[1]]
			&"cells", &"path", &"move":
				hint = hint % int(size)
			&"area":
				hint = hint % [size.x, size.y]
			&"obstacles":
				var change: int = map.route_length(_path_if_cleared(cells)) - _route_now if not cells.is_empty() else 0
				return "%d of %d%s" % [cells.size(), int(size),
					(" · %+d path" % change) if change != 0 else ""] + ("" if not cells.is_empty() else " · " + hint % int(size))
		if kind == &"rim":
			var spot: Vector2 = cells[0] if not cells.is_empty() else hover
			if spot == map.startPath:
				return "Keep the start where it is · route %d cells" % _route_now
			if options.has(spot):
				return "New start · route %d cells (now %d)" % [map.route_length(_rim_route(spot)), _route_now]
			return hint
		var added := _route_len() - _route_now
		return hint + (" · +%d path" % added if blocking and added > 0 else "")

	func placement() -> Dictionary:
		var picked: Array[Vector2] = []
		picked.assign(cells.filter(func(c: Vector2) -> bool: return c != Vector2(-99, -99)))
		var out := {"cells": picked}
		if PIECE_KINDS.has(kind):  # Warden-style half origins (MapGifts reads these; "cells" stays for old readers)
			out["pieces"] = picked.map(func(c: Vector2) -> Vector2: return c * 2.0)
		if kind == &"move":
			out["from"] = froms.map(func(c: Vector2) -> Vector2: return c * 2.0)  # Obstacle keys × 2
		if kind == &"path":  # Route halves; "cells" = the cells they lie in
			out["halves"] = picked
			var homes: Array[Vector2] = []
			for h in picked:
				if not homes.has((h / 2.0).floor()):
					homes.append((h / 2.0).floor())
			out["cells"] = homes
		if tower != null:
			out["cells"] = [tower.cell]
		return out

	# A piece a Warden could stand on here (MapGifts: every half free, off the glade; for a blocking gift alone, the
	# route still open).
	func _cell_ok(cell: Vector2) -> bool:
		return map != null and map.get("gifts") != null and map.gifts.can_place(id, [cell * 2.0])

	# All the pieces together: free, not overlapping, and a blocking gift leaves every nightmare a way through (moving
	# obstacles also frees their old halves, which only opens more: checking the new ones alone is the safe side).
	func _route_ok(blocked: Array, _freed: Array = []) -> bool:
		var all := blocked.filter(func(c) -> bool: return c != Vector2(-99, -99)).map(func(c: Vector2) -> Vector2: return c * 2.0)
		return map.get("gifts") != null and map.gifts.can_place(id, all)

	func _route_len() -> int:
		var all: Array = placement().cells.duplicate()
		if all.is_empty() or not blocking:
			return _route_now
		return map.route_length(map.get_path_if_blocked_halves(_halves_of(all)))

	# The route from a new start (Environment's preview), empty if the map can't say.
	func _rim_route(spot: Vector2) -> PackedVector2Array:
		if map.get("gifts") != null and map.gifts.has_method("route_from_start"):
			return map.gifts.route_from_start(spot)
		return PackedVector2Array()

	func _refresh_route() -> void:
		if kind == &"rim" and map != null:  # The picked (or hovered) spot's route, against today's
			var spot: Vector2 = cells[0] if not cells.is_empty() else hover
			var route: PackedVector2Array = _rim_route(spot) if options.has(spot) else PackedVector2Array()
			if route.is_empty():
				RouteLine.clear(route_line)
			else:
				RouteLine.draw_route(route_line, route, Color(UiStyle.GOLD, 0.6), 6.0, map.get_path_from(map.startPath))
			return
		if kind == &"obstacles" and map != null:  # The route once the picked (and hovered) obstacles are gone, live
			var preview: Array = cells.duplicate()
			if map.obstacles.has(hover) and _picked_obstacle(hover) == Vector2(-1, -1) and cells.size() < int(size):
				preview.append(hover)
			var opened: PackedVector2Array = _path_if_cleared(preview) if not preview.is_empty() else PackedVector2Array()
			var now: PackedVector2Array = map.get_path_from(map.startPath)
			if opened.is_empty() or opened == now:
				RouteLine.clear(route_line)
			else:
				RouteLine.draw_route(route_line, opened, Color(UiStyle.GOLD, 0.6), 6.0, now)
			return
		if not blocking or map == null:
			RouteLine.clear(route_line)
			return
		var preview: Array = placement().cells.duplicate()
		if not is_complete() and _cell_ok(hover) and kind != &"move" and kind != &"line":
			preview.append(hover)
		var route: PackedVector2Array = map.get_path_if_blocked_halves(_halves_of(preview)) if not preview.is_empty() else PackedVector2Array()
		if route.is_empty():
			RouteLine.clear(route_line)
		else:
			RouteLine.draw_route(route_line, route, Color(UiStyle.GOLD, 0.6), 6.0, map.get_path_from(map.startPath))

	# --- Half cells (heartwood_gifts.md 2554c638, user: "should be going by half a cell like Wardens") ---------------
	# A piece is a Warden's 2×2 halves, snapped like TowerPlacer (half_origin_at). Pieces are kept as "virtual cells":
	# origin / 2 (x.5 when half-offset), so neighbours are 1 apart, a line steps by 1 and the ghost art keeps its cell
	# maths; placement() hands MapGifts the origins ("pieces"). Mire / Roots ("path") keep route halves instead.
	const PIECE_KINDS: Array[StringName] = [&"chain", &"line", &"cell", &"cells", &"area", &"move"]
	var on_placed: Callable  # GiftScreen.piece_placed (Sound: the Warden plant sound)

	# What the pointer is over, in this kind's units: a piece's virtual cell, an obstacle's key, a route half or a cell.
	func _hover_at(local: Vector2) -> Vector2:
		match kind:
			&"chain", &"line", &"cell", &"cells", &"area":
				return TowerPlacer.half_origin_at(local) / 2.0
			&"move":  # Picking a stone up by the half under the pointer; putting it down as a piece
				return TowerPlacer.half_origin_at(local) / 2.0 if froms.size() > cells.size() else map.obstacle_key_at(map.pixels_to_half(local))
			&"obstacles":
				return map.obstacle_key_at(map.pixels_to_half(local))
			&"path":
				return map.pixels_to_half(local)
		return map.MAP_GRID.calculate_grid_coordinates(local)

	# Every half the pieces at these virtual cells cover.
	func _halves_of(pieces: Array) -> Array[Vector2]:
		var out: Array[Vector2] = []
		for c in pieces:
			if c != Vector2(-99, -99):
				out.append_array(MapGifts.piece_halves(c * 2.0))
		return out

	# A route half Mire / Roots may take: on the drawn route, not in the start's or the Heartwood's cell.
	func _route_half_ok(h: Vector2) -> bool:
		var home := (h / 2.0).floor()
		return home != map.startPath and home != map.endPath and map.get("gifts") != null and map.gifts.can_place(id, [h])

	# The Warden build sound for a placed piece, the refusal sound for a click that couldn't place (SoundHooks).
	func _placed(c: Vector2) -> void:
		if on_placed.is_valid():
			on_placed.call(map.to_global(map.MAP_GRID.calculate_map_position(c) if kind != &"path" else (c + Vector2(0.5, 0.5)) * map.MAP_GRID.cell_size / 2.0))

	func _refused(c: Vector2) -> void:
		var placer := director.get_node_or_null("%TowerPlacer") as TowerPlacer
		if placer != null:
			placer.build_rejected.emit((c if kind != &"path" else c / 2.0).floor())

	static func _adjacent(a: Vector2, b: Vector2) -> bool:
		return absf(a.x - b.x) + absf(a.y - b.y) == 1.0

	# The pieces from `from` to `to` in a straight line, one piece apart; empty unless they share a row or column and lie
	# a whole number of pieces apart (half-cell hovers can be half a piece off: the old step-until-equal loop never met
	# `to` and grew until memory ran out, the user's Fallen Giant crash). Never longer than MAX_LINE.
	const MAX_LINE := 64

	func _line(from: Vector2, to: Vector2) -> Array[Vector2]:
		# Along the pointer's main direction, whole pieces from `from` (user: the log "doesn't plant half cells and the
		# image disappears" when the pointer sat half a piece off the start's row or pitch).
		var out: Array[Vector2] = []
		var d := to - from
		var along_x := absf(d.x) >= absf(d.y)
		var steps := mini(roundi(absf(d.x if along_x else d.y)), MAX_LINE)
		var step := Vector2(signf(d.x), 0.0) if along_x else Vector2(0.0, signf(d.y))
		for i in steps + 1:
			out.append(from + step * i)
		return out

	# The line the next click would plant: at most size[1] pieces (a click past the limit plants up to it).
	func _line_fit(from: Vector2, to: Vector2) -> Array[Vector2]:
		var full := _line(from, to)
		return full.slice(0, int(size[1])) if full.size() > int(size[1]) else full

	func _area(origin: Vector2) -> Array[Vector2]:
		var out: Array[Vector2] = []
		for y in size.y:
			for x in size.x:
				out.append(origin + Vector2(x, y))
		return out

	func _in_kinship(picked: Tower) -> bool:
		var kin = Kinships.find(director)
		return kin != null and kin.has_method("get_pairs") and not kin.get_pairs(picked).is_empty()

	func _draw() -> void:
		var half: Vector2 = map.MAP_GRID.cell_size / 2.0
		if kind == &"path":  # Route halves: each picked half, and the hovered one (green if it can be taken)
			for h in cells:
				draw_rect(Rect2(h * half, half).grow(-1), Color(Palette.SPRIG, 0.45))
			if not is_complete() and not cells.has(hover):
				var ok := _route_half_ok(hover) and (cells.is_empty() or cells.any(func(c: Vector2) -> bool: return _adjacent(c, hover)))
				draw_rect(Rect2(hover * half, half).grow(-1), Color(Palette.SPRIG if ok else Palette.EMBER, 0.35), false, 2.0)
			return
		if kind == &"rim":  # Each offered spot a ring (gold when picked), the old start a dim ring
			var gifts = map.get("gifts")
			if gifts != null and gifts.has_method("draw_start_ghost"):  # Environment's mist + bridge at each new spot
				for spot in options:
					gifts.draw_start_ghost(self, spot, 0.85 if cells.has(spot) or spot == hover else 0.5)
			for spot in options + [map.startPath]:
				var picked: bool = cells.has(spot)
				var at: Vector2 = map.MAP_GRID.calculate_map_position(spot)
				var colour := Color(UiStyle.GOLD, 0.95) if picked else (Color(Palette.SPRIG, 0.8) if spot == hover else Color(UiStyle.FOG, 0.7))
				if spot == map.startPath and not picked:
					colour.a = 0.4
				draw_arc(at, half.x - 4.0, 0.0, TAU, 32, colour, 3.0 if picked else 2.0)
			return
		if kind == &"obstacles":  # Each picked obstacle: a gold outline and an "×"; the hovered one outlined
			for at in cells:
				for c in map.get_obstacle_cells(at):
					var rect := Rect2(map.MAP_GRID.calculate_map_position(c) - half, half * 2.0).grow(-3)
					draw_rect(rect, Color(UiStyle.GOLD, 0.95), false, 2.5)
					draw_line(rect.position + Vector2(10, 10), rect.end - Vector2(10, 10), Color(UiStyle.GOLD, 0.9), 3.0)
					draw_line(Vector2(rect.end.x - 10, rect.position.y + 10), Vector2(rect.position.x + 10, rect.end.y - 10), Color(UiStyle.GOLD, 0.9), 3.0)
			if map.obstacles.has(hover):
				var free := cells.size() < int(size) or _picked_obstacle(hover) != Vector2(-1, -1)
				for c in map.get_obstacle_cells(hover):
					draw_rect(Rect2(map.MAP_GRID.calculate_map_position(c) - half, half * 2.0).grow(-3),
						Color(Palette.SPRIG if free else Palette.EMBER, 0.6), false, 2.0)
			return
		var draw_cells: Array = placement().cells.duplicate()
		for c in froms:
			draw_rect(Rect2(map.MAP_GRID.calculate_map_position(c) - half, half * 2.0), Color(Palette.EMBER, 0.35))
		var preview: Array = draw_cells if is_complete() else _ghost_preview(draw_cells)
		if not _draw_ghost(preview):  # No art for this gift: the plain marks
			for c in draw_cells:
				draw_rect(Rect2(map.MAP_GRID.calculate_map_position(c) - half, half * 2.0), Color(Palette.SPRIG, 0.4))
		if not is_complete():
			var ok: bool = _cell_ok(hover) or (kind == &"move" and map.obstacles.has(hover)) or kind == &"warden" or kind == &"kinship"
			var hover_cells: Array = _area(hover) if kind == &"area" else [hover]
			for c in hover_cells:
				draw_rect(Rect2(map.MAP_GRID.calculate_map_position(c) - half, half * 2.0),
					Color(Palette.SPRIG if ok else Palette.EMBER, 0.25), false, 2.0)
			_draw_length(half)

	# Length feedback (heartwood_gifts.md 52d11575, user: "no feedback on the log when it's past the limit"): a line's
	# pieces past the limit are a red "too far" stretch, a blocked piece is red on its own cell, and a tag at the pointer
	# counts against the limit ("4 / 4 · max", "1 / 2 · 1 more") with the reason a piece is refused.
	const REFUSALS := {&"occupied": "blocked", &"closes": "would close the route", &"off_route": "off the route"}

	func length_tag() -> String:
		var count := 0
		var reason := ""
		var past := false
		match kind:
			&"line":
				if cells.size() != 1:
					return ""
				var full := _line(cells[0], hover)
				var fit := _line_fit(cells[0], hover)
				count = fit.size()
				past = full.size() > fit.size()
				for c in fit:
					if not _cell_ok(c):
						reason = REFUSALS.get(map.gifts.refusal(), "blocked") if map.get("gifts") != null else "blocked"
						break
			&"chain":
				count = cells.size()
			_:
				return ""
		var low := int(size[0])
		var high := int(size[1])
		var text := "%d / %d" % [count, high]
		if past or count >= high:
			text += " · max"
		elif count < low:
			text += " · %d more" % (low - count)
		return text + (" · " + reason if reason != "" else "")

	func _draw_length(half: Vector2) -> void:
		var tag := length_tag()
		if tag == "":
			return
		if kind == &"line" and cells.size() == 1:
			var full := _line(cells[0], hover)
			var fit := _line_fit(cells[0], hover)
			for c in full.slice(fit.size()):  # Too far: past the limit
				draw_rect(Rect2(map.MAP_GRID.calculate_map_position(c) - half, half * 2.0).grow(-3), Color(Palette.EMBER, 0.3))
			for c in fit:  # A blocked piece, red on its own cell
				if not _cell_ok(c):
					draw_rect(Rect2(map.MAP_GRID.calculate_map_position(c) - half, half * 2.0).grow(-3), Color(Palette.EMBER, 0.5), false, 2.5)
		var at: Vector2 = map.MAP_GRID.calculate_map_position(hover)
		WorldLabel.draw_tag(self, at.x, at.y - half.y * 2.0 - 6.0, tag, Palette.EMBER if tag.contains("blocked") or tag.contains("route") else UiStyle.GOLD)

	# --- The ghost (user: "you don't see the moonwell you're placing") ---------------------------------------
	# The real art MapGifts will put down (its own sheets and tiles, so the preview always matches), see-through on the
	# picked cells plus the hovered next step, a thin footprint outline, and the effect's reach as a dashed square.
	const GHOST_ALPHA := 0.6
	# (The reach is the landmark's zone: HeartwoodGifts.zone_cells(id), cells from the footprint's edge.)

	# The picked cells plus what the next click would add.
	func _ghost_preview(picked: Array) -> Array:
		var out: Array = picked.duplicate()
		match kind:
			&"line":
				if cells.size() == 1:
					var line := _line_fit(cells[0], hover)
					if line.size() >= 1:
						out.assign(line)
			&"area":
				out.assign(_area(hover))
			&"cell":
				out = [hover]
			&"chain", &"cells", &"path":
				if not out.has(hover):
					out.append(hover)
		return out

	# Draws the ghost of `ghost` cells; false when this gift has no art to show (the caller draws plain marks).
	func _draw_ghost(ghost: Array) -> bool:
		_draw_zone(ghost)  # Before the art, and also when this gift has none to show
		var gifts = map.get("gifts")
		if gifts == null or ghost.is_empty() or not gifts.get("_sheets") is Dictionary:
			return false
		var tint := Color(1, 1, 1, GHOST_ALPHA)  # multiplier
		var cell_size := Vector2(map.MAP_GRID.cell_size)
		var sheets: Dictionary = gifts._sheets
		var drew := true
		match id:
			&"sow_ridge":
				var tree: ObstacleData = MapGifts.TREE_DATA
				var source := map.environment_object_layer.tile_set.get_source(tree.source_id) as TileSetAtlasSource
				drew = source != null and not tree.tiles.is_empty()
				if drew:
					for c in ghost:
						var tile: Vector2i = tree.tiles[EnvironmentTiles.cell_variant(Vector2i(c), tree.tiles.size())]
						_tall(source.texture, Rect2(source.get_tile_texture_region(tile)), c, tint)
			&"fallen_giant":
				drew = sheets.has("fallen_log")
				for c in ghost if drew else []:
					var piece := MapGifts._log_piece(c, ghost)
					_tall(sheets.fallen_log, gifts.frame_region("fallen_log", piece if piece >= 0 else 1), c, tint)
			&"spring":
				var pond := map.environment_object_layer.tile_set.get_source(EnvironmentTiles.POND) as TileSetAtlasSource
				drew = pond != null
				for c in ghost if drew else []:
					var mask := MapGifts._mask(c, func(o: Vector2) -> bool: return ghost.has(o))
					draw_texture_rect_region(pond.texture, Rect2(map.MAP_GRID.calculate_map_position(c) - cell_size / 2.0, cell_size),
						Rect2(pond.get_tile_texture_region(Vector2i(mask, 0))), tint)
			&"mushroom_ring":
				drew = sheets.has("mushroom_ring")
				if drew:
					var top := Vector2(MapGifts._min_x(ghost), MapGifts._min_y(ghost))
					draw_texture_rect_region(sheets.mushroom_ring, Rect2(map.MAP_GRID.calculate_map_position(top) - cell_size / 2.0,
						cell_size * 3), gifts.frame_region("mushroom_ring", 0), tint)
			&"lightning_tree", &"moonwell", &"bell_stone":
				drew = sheets.has(String(id))
				for c in ghost if drew else []:
					_tall(sheets[String(id)], gifts.frame_region(String(id), 0), c, tint)
			&"ancient_stump":
				drew = sheets.has("ancient_stump")
				for c in ghost if drew else []:
					draw_texture_rect_region(sheets.ancient_stump, Rect2(map.MAP_GRID.calculate_map_position(c) - cell_size / 2.0, cell_size),
						gifts.frame_region("ancient_stump", EnvironmentTiles.cell_variant(Vector2i(c), 3)), tint)
			&"mire":
				drew = sheets.has("bog_path")
				var path_cells: PackedVector2Array = map.path_layer.current_path
				for c in ghost if drew else []:
					var mask := MapGifts._mask(c, func(o: Vector2) -> bool: return path_cells.has(o) or ghost.has(o))
					draw_texture_rect_region(sheets.bog_path, Rect2(map.MAP_GRID.calculate_map_position(c) - cell_size / 2.0, cell_size),
						gifts.frame_region("bog_path", mask), tint)
			_:
				drew = false
		if not drew:
			return false
		var ok: bool = ghost.all(func(c: Vector2) -> bool: return cells.has(c) or _cell_ok(c) or kind == &"path")
		for c in ghost:  # The footprint: a thin outline, the cold tint when it can't go there
			draw_rect(Rect2(map.MAP_GRID.calculate_map_position(c) - cell_size / 2.0, cell_size).grow(-2),
				Color(Palette.SPRIG if ok else Palette.EMBER, 0.7), false, 1.5)
		return true

	# The zone a landmark will hold, round the ghost: its reach, the path cells and the planted Wardens inside it.
	func _draw_zone(ghost: Array) -> void:
		if ghost.is_empty() or map == null:
			return
		var cell_size := Vector2(map.MAP_GRID.cell_size)
		var zone := HeartwoodGifts.zone_cells(id)
		if zone > 0.0:  # The zone it will hold, and what falls inside it: your Wardens and the path
			var box := Rect2(map.MAP_GRID.calculate_map_position(ghost[0]) - cell_size / 2.0, cell_size)
			for c in ghost:
				box = box.merge(Rect2(map.MAP_GRID.calculate_map_position(c) - cell_size / 2.0, cell_size))
			var reach := box.grow(cell_size.x * zone)
			draw_rect(reach, Color(Palette.SPRIG, 0.07))
			_dashed_rect(reach, Color(Palette.SPRIG, 0.55))
			var inside := zone_contents(reach)
			for point in inside.path:  # Cells of path in the zone: a small dot each
				draw_circle(point, 4.0, Color(Palette.SPRIG, 0.8))
			for tower in inside.wardens:  # Planted Wardens in the zone: ringed
				draw_arc(to_local(tower.global_position), cell_size.x * 0.46, 0.0, TAU, 24, Color(UiStyle.GOLD, 0.9), 2.0, true)
			var label_at := Vector2(reach.get_center().x, reach.position.y - 8.0)
			WorldLabel.draw_tag(self, label_at.x, label_at.y, "%d Wardens · %d cells of path in its zone" % [inside.wardens.size(), inside.path.size()], Palette.SPRIG)

	# What a zone (a rect in this node's space) holds: {wardens: planted Wardens, path: the centres of its path cells}.
	func zone_contents(reach: Rect2) -> Dictionary:
		var wardens: Array = []
		var container := director.get_node_or_null("%TowerContainer")
		for tower in (container.get_children() if container != null else []):
			if tower is Tower and reach.has_point(to_local(tower.global_position)):
				wardens.append(tower)
		var path: Array[Vector2] = []
		for cell in Tower.route_cells(map.get_path_from(map.startPath)):
			var at: Vector2 = map.MAP_GRID.calculate_map_position(cell)
			if reach.has_point(at):
				path.append(at)
		return {"wardens": wardens, "path": path}

	# A sprite whose bottom 64 px sit on `cell` (tall art overhangs the cells above), as MapGifts' props and trees.
	func _tall(texture: Texture2D, region: Rect2, cell: Vector2, tint: Color) -> void:
		var at: Vector2 = map.MAP_GRID.calculate_map_position(cell) + Vector2(-region.size.x / 2.0, 32.0 - region.size.y)
		draw_texture_rect_region(texture, Rect2(at, region.size), region, tint)

	func _dashed_rect(rect: Rect2, colour: Color) -> void:
		var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
		for i in 4:
			draw_dashed_line(corners[i], corners[(i + 1) % 4], colour, 1.5, 6.0)
