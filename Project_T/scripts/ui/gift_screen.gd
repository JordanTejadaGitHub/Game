extends Control
class_name GiftScreen

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
	&"path": "Click %d connected cells of the route.",
	&"area": "Click where it goes (%d×%d).",
	&"move": "Click an obstacle, then where it goes (up to %d).",
	&"warden": "Click one of your Wardens.",
	&"kinship": "Click a Warden in a Kinship.",
	&"obstacles": "Click obstacles to clear (up to %d), again to unselect.",
	&"rim": "Click a new start on the rim, or the old one to keep it.",
}

# Each gift's living mini-scene (heartwood_gifts.md "an animated mini-scene like the placement Dream cards"): Roguelite
# Code's CardScene.show_scene(before, after, effect, caption), 7×5 rows in UpgradeData.diagram's legend plus the gift
# letters (L log, ~ pond, m moonwell, b bell stone, z lightning tree, u stump, k mushroom ring, B bog, r roots).
const SCENES := {
	&"sow_ridge": [".......\n.......\nSPPPPPH\n.......\n.......", ".......\n.PPPPP.\nSP.O.PH\n...O...\n...O...", {},
		"A ridge across the way: they take the long road."],
	&"fallen_giant": [".......\n.......\nSPPPPPH\n.......\n.......", ".......\n.PPPPP.\nSPLLLPH\n.......\n.......", {},
		"A fallen giant they must walk around, for good."],
	&"glade": [".OO....\n.OO.O..\nSPPPPPH\n....O..\n.......", ".OO....\n.......\nSPPPPPH\n.......\n.......", {},
		"The obstacles you pick are cleared for free, and each counts as tended."],
	&"shift_stones": ["OO.....\n.......\nSPPPPPH\n.......\n.O.....", ".......\n.PPPPP.\nSP.O.PH\n...O...\n...O...", {},
		"The stones move where you need a wall."],
	&"mire": [".......\n...a...\nSPPPPPH\n.......\n.......", ".......\n...a...\nSPBBBPH\n.......\n.......", {},
		"Bog underfoot: they slow to 80%."],
	&"spring": [".......\n...a...\n.......\nSPPPPPH\n.......", ".......\n.~~W...\n.~~....\nSPPPPPH\n.......",
		{"text": "+20%", "damage": 1.2}, "Water Wardens beside the spring hit harder."],
	&"mushroom_ring": [".......\n....a..\nSPPPPPH\n.......\n.......", ".......\n.kkkW..\nSPPPPPH\n.kkk...\n.......",
		{"text": "+2 Poisoned cap"}, "Spore Wardens touching the ring poison deeper."],
	&"lightning_tree": [".......\n....a..\nSPPPPPH\n.......\n.......", ".......\n..z.W..\nSPPPPPH\n.......\n.......",
		{"text": "+25% bolts", "damage": 1.25}, "Bolts near the dead tree strike harder."],
	&"moonwell": [".......\n....a..\nSPPPPPH\n.......\n.......", ".......\n...mW..\nSPPPPPH\n.......\n.......",
		{"text": "+1 range", "range": 1.0}, "Wardens beside the moonwell see further."],
	&"bell_stone": [".......\n....a..\nSPPPPPH\n.......\n.......", ".......\n...bW..\nSPPPPPH\n.......\n.......",
		{"text": "+15% speed", "speed": 1.15}, "Song Wardens beside the stone pulse faster."],
	&"ancient_stump": [".......\n.......\nSPPPPPH\n.......\n.......", ".......\n.u.u.u.\nSPPPPPH\n.......\n.......", {},
		"Plant on a stump: the Warden starts at rank I."],
	&"heartwood_roots": [".......\n....a..\nSPPPPPH\n.......\n.......", ".......\n....W..\nSPrrrrH\n.......\n.......",
		{"text": "+15% taken", "damage": 1.15}, "Roots before the Heartwood: they take more there."],
	&"thick_mist": [".......\n...a...\nSPPPPPH\n.......\n.......", ".......\n...a...\nSPPPPPH\n.......\n.......", {},
		"Next act, they leave the mist further apart."],
	&"bramble_verge": [".......\n.T.T.T.\nSPPPPPH\n.......\n.......", ".......\n.X.X.X.\nSPPPPPH\n.......\n.......",
		{"proc": "+1 Drowsy cap"}, "Thornwalls for half, and they make nightmares drowsy."],
	&"old_kin": [".......\n..aa...\nSPPPPPH\n.......\n.......", ".......\n..WW...\nSPPPPPH\n.......\n.......",
		{"text": "kin +1 stage", "damage": 1.1, "kin": true}, "A Kinship grows a stage at once."],  # The bond drawn (CardScene 4e14a81c)
	&"shifting_mist": [".......\n.......\nSPPPPPH\n.......\n.......", "...S...\n...P...\n...PPPH\n.......\n.......", {},
		"The start mist moves; they come a new way."],
	&"waking_root": [".......\n...a...\nSPPPPPH\n.......\n.......", ".......\n...W...\nSPPPPPH\n.......\n.......",
		{"text": "-1 Dreamlight"}, "The next form you unlock costs less."],
	&"memory_seed": [".......\n.a.....\nSPPPPPH\n.......\n.......", ".......\n.....W.\nSPPPPPH\n.......\n.......",
		{"text": "keeps its ranks"}, "Move a Warden this act: it keeps its ranks and kin."],
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
var _choose := Control.new()  # The cards' page (dim + centre)
var _dim := ColorRect.new()
var _place_bar := PanelContainer.new()
var _place_label := Label.new()
var _plant := Button.new()

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
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	centre.add_child(box)
	var title := Label.new()
	title.text = "The Heartwood offers a gift"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.display(title, 28)
	box.add_child(title)
	preview = CardScene.new()  # Always there (touch: no hover needed); hovering a card plays its scene
	preview.name = "GiftScene"
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(preview)
	_cards.add_theme_constant_override("separation", 16)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_cards)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	_pass.focus_mode = Control.FOCUS_NONE
	_pass.custom_minimum_size = Vector2(240, 48)
	_pass.pressed.connect(func() -> void:
		gifts.let_pass()
		_close())
	_pass.icon = IconInfo.icon(&"dew")  # "Let them pass, +30 [Dew]": the secondary frame
	_pass.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_pass.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(_pass)
	peek = ChoicePeek.new(self, [_dim, centre], "Back to the gifts")
	var peek_button := peek.make_peek_button()
	if peek_button is Button:
		UiStyle.quiet(peek_button)  # Light pass: quiet; the cards hold the choice
	row.add_child(peek_button)
	arm = ChoiceArm.attach(self, _cards)
	_choose = centre
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
	var back := Button.new()
	back.text = "Back"
	back.focus_mode = Control.FOCUS_NONE
	back.custom_minimum_size = Vector2(100, 44)
	back.pressed.connect(cancel_placing)
	bar.add_child(back)
	_plant.text = "Plant"
	_plant.focus_mode = Control.FOCUS_NONE
	_plant.custom_minimum_size = Vector2(120, 44)
	UiStyle.primary(_plant)
	_plant.pressed.connect(confirm_placing)
	bar.add_child(_plant)
	gifts.offer_closed.connect(func() -> void:
		if visible:
			_close())

# Opens once the Dream (and the family pick) are done: DriftDirector.pending_choice() names the gift.
func _process(_delta: float) -> void:
	if gifts.waiting and not visible and drift_director.pending_choice() == &"gift" and not RestScreens.any_open(self, drift_director):
		open()  # Its turn, and nothing else on screen (one paused screen at a time)
	if placing != &"" and placer != null:
		_plant.disabled = not placer.is_complete()
		_place_label.text = "%s: %s" % [HeartwoodGifts.POOL[placing].name, placer.status()]

func open() -> void:
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	for id in gifts.current_offer:
		_cards.add_child(_card(id))
	_pass.text = "Let them pass, +%d" % gifts.pass_dew()  # The Dew glyph after it (no " · ")
	if not gifts.current_offer.is_empty():
		show_scene(gifts.current_offer[0])
	visible = true
	_show_cards(true)
	arm.arm()

# A gift card styled like the Dream cards (user: plain centred text looked unfinished): its emblem (UI Asset's gift
# icon "gift_<id>" once drawn, else its category's glyph), the name in the display font, the category in small caps
# in its colour, and the text in the body font with status words linked. Solid, like every paused card.
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
	var style: Array = GROUP_STYLE.get(gift.group, [&"leaves", UiStyle.GOLD])
	var colour: Color = style[1]
	var button := Button.new()
	button.name = String(id)
	button.custom_minimum_size = CARD_SIZE
	button.focus_mode = Control.FOCUS_NONE
	UiStyle.card_button(button, colour)
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var box := button.get_theme_stylebox(state) as MoonStyleBox
		if box != null:
			box.center_alpha = UiStyle.TIP_ALPHA  # Solid: no screen shows through a paused card (user)
			box.edge_alpha = UiStyle.TIP_ALPHA
	button.pressed.connect(pick.bind(id))
	button.mouse_entered.connect(show_scene.bind(id))
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 18
	box.offset_top = 18
	box.offset_right = -18
	box.offset_bottom = -14
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
	UiStyle.title(title, 24)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.add_child(title)
	var group := Label.new()
	group.name = "Category"
	group.text = gift.group
	UiStyle.caps(group, 13, colour)
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.add_child(group)
	# What it is (the first sentence), then what it does, a bullet per sentence. Status words stay links.
	var sentences := String(gift.text).split(". ", false)
	var text := StatusLinks.make_label(sentences[0] + ("." if sentences.size() > 1 else ""), 15, UiStyle.INK)
	text.name = "Text"
	text.mouse_filter = Control.MOUSE_FILTER_PASS  # Status words hover; a click still picks the card
	box.add_child(text)
	for i in range(1, sentences.size()):
		var line := String(sentences[i]).trim_suffix(".")
		box.add_child(_bullet(line))
	var spare := Control.new()
	spare.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spare.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(spare)
	var plant := Button.new()
	plant.name = "PlantIt"
	plant.text = "Plant it"
	plant.focus_mode = Control.FOCUS_NONE
	plant.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plant.custom_minimum_size.y = UiStyle.HUD_BUTTON_H
	UiStyle.primary(plant)
	ChoiceCard.link_cue(plant)  # Lights with the card (hover, press)
	box.add_child(plant)
	box.minimum_size_changed.connect(func() -> void:
		button.custom_minimum_size = Vector2(CARD_SIZE.x, maxf(CARD_SIZE.y, box.get_combined_minimum_size().y + 32.0)))
	return button

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
	var label := StatusLinks.make_label(text, 14, UiStyle.INK_DIM)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_child(label)
	return row

# Plays gift `id`'s before → after mini-scene in the preview (a still after-diagram under reduced motion).
func show_scene(id: StringName) -> void:
	if not SCENES.has(id) or preview == null:
		return
	var scene: Array = SCENES[id]
	preview.show_scene(scene[0], scene[1], scene[2], scene[3])
	preview.set_meta(&"gift", id)

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
	drift_director.owner.add_child(placer)
	_plant.text = "Clear them" if placer.kind == &"obstacles" else "Plant"

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
	if placing != &"" and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("cancel_build")):
		get_viewport().set_input_as_handled()
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
		var cell: Vector2 = map.MAP_GRID.calculate_grid_coordinates(map.get_local_mouse_position())
		if cell != hover:
			hover = cell
			_refresh_route()
			queue_redraw()

	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			click(hover)
			get_viewport().set_input_as_handled()

	# One click on `cell`, by kind (tests call it too).
	func click(cell: Vector2) -> void:
		match kind:
			&"chain":
				if cells.has(cell):
					cells.assign(cells.slice(0, cells.find(cell)))  # Click back on the chain: shorten it there
				elif cells.size() < size[1] and _cell_ok(cell) and (cells.is_empty() or _adjacent(cells[-1], cell)) and _route_ok(cells + [cell]):
					cells.append(cell)
			&"line":
				if cells.size() >= 1 and cells.size() < 2:
					var line := _line(cells[0], cell)
					if line.size() >= size[0] and line.size() <= size[1] and line.all(_cell_ok) and _route_ok(line):
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
			&"path":
				var route := {}  # The full cells the route covers (half-cell points: the cell each lies in)
				for point in map.get_path_from(map.startPath):
					for c in DreamState.route_cells(point):
						route[c] = true
				if cells.has(cell):
					cells.erase(cell)
				elif cells.size() < int(size) and route.has(cell) and cell != map.startPath and cell != map.endPath \
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
			&"cells", &"path":
				return cells.size() == int(size)
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
		if kind == &"move":
			out["from"] = froms
		if tower != null:
			out["cells"] = [tower.cell]
		return out

	# Empty ground a Warden could stand on, not in the Heartwood's glade (the glade is the Heartwood's).
	func _cell_ok(cell: Vector2) -> bool:
		if map == null or not map.is_buildable(cell):
			return false
		if map.has_method("get_glade_cells") and Array(map.get_glade_cells()).has(cell):
			return false
		return true

	# A blocking gift must leave the start a way to the Heartwood. (Moving obstacles also frees their old cells, which
	# only opens more: checking the new cells alone is the safe side.)
	func _route_ok(blocked: Array, _freed: Array = []) -> bool:
		if not blocking:
			return true
		var all := blocked.filter(func(c) -> bool: return c != Vector2(-99, -99))
		return map.get_path_if_blocked_cells(all).size() > 0

	func _route_len() -> int:
		var all: Array = placement().cells.duplicate()
		if all.is_empty() or not blocking:
			return _route_now
		return map.route_length(map.get_path_if_blocked_cells(all))

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
		var route: PackedVector2Array = map.get_path_if_blocked_cells(preview) if not preview.is_empty() else PackedVector2Array()
		if route.is_empty():
			RouteLine.clear(route_line)
		else:
			RouteLine.draw_route(route_line, route, Color(UiStyle.GOLD, 0.6), 6.0, map.get_path_from(map.startPath))

	static func _adjacent(a: Vector2, b: Vector2) -> bool:
		return absf(a.x - b.x) + absf(a.y - b.y) == 1.0

	func _line(from: Vector2, to: Vector2) -> Array[Vector2]:
		var out: Array[Vector2] = []
		if from.x != to.x and from.y != to.y:
			return out
		var step := (to - from).sign()
		var at := from
		out.append(at)
		while at != to:
			at += step
			out.append(at)
		return out

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

	# --- The ghost (user: "you don't see the moonwell you're placing") ---------------------------------------
	# The real art MapGifts will put down (its own sheets and tiles, so the preview always matches), see-through on the
	# picked cells plus the hovered next step, a thin footprint outline, and the effect's reach as a dashed square.
	const GHOST_ALPHA := 0.6
	const REACH := {&"moonwell": 1, &"bell_stone": 1, &"lightning_tree": 2, &"spring": 2}  # Cells around the footprint

	# The picked cells plus what the next click would add.
	func _ghost_preview(picked: Array) -> Array:
		var out: Array = picked.duplicate()
		match kind:
			&"line":
				if cells.size() == 1:
					var line := _line(cells[0], hover)
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
		if REACH.has(id):
			var box := Rect2(map.MAP_GRID.calculate_map_position(ghost[0]) - cell_size / 2.0, cell_size)
			for c in ghost:
				box = box.merge(Rect2(map.MAP_GRID.calculate_map_position(c) - cell_size / 2.0, cell_size))
			_dashed_rect(box.grow(cell_size.x * REACH[id]), Color(Palette.SPRIG, 0.55))
		return true

	# A sprite whose bottom 64 px sit on `cell` (tall art overhangs the cells above), as MapGifts' props and trees.
	func _tall(texture: Texture2D, region: Rect2, cell: Vector2, tint: Color) -> void:
		var at: Vector2 = map.MAP_GRID.calculate_map_position(cell) + Vector2(-region.size.x / 2.0, 32.0 - region.size.y)
		draw_texture_rect_region(texture, Rect2(at, region.size), region, tint)

	func _dashed_rect(rect: Rect2, colour: Color) -> void:
		var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
		for i in 4:
			draw_dashed_line(corners[i], corners[(i + 1) % 4], colour, 1.5, 6.0)
