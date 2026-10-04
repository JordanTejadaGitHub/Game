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
	&"deeper_glade": [".....O.\n....OO.\nSPPPPPH\n....OO.\n.....O.", ".......\n.......\nSPPPPPH\n.......\n.......", {},
		"The Heartwood's glade grows, and one more leaf."],
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
	row.add_child(_pass)
	peek = ChoicePeek.new(self, [_dim, centre], "Back to the gifts")
	row.add_child(peek.make_peek_button())
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
	_pass.text = "Let them pass · +%d Dew" % gifts.pass_dew()
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

const CARD_SIZE := Vector2(250, 180)  # Grows with its text; short enough that the screen fits 720 under the banner

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
	box.offset_left = 14
	box.offset_top = 12
	box.offset_right = -14
	box.offset_bottom = -12
	box.add_theme_constant_override("separation", 4)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	var icon := TextureRect.new()
	icon.name = "Emblem"
	var emblem := _gift_emblem(id)  # UI Asset's gift emblem (7220e5fa), else the category's glyph tinted
	icon.texture = emblem if emblem != null else IconInfo.icon(style[0])
	icon.custom_minimum_size = Vector2(32, 32)  # Emblems are drawn at 32 (×1); the 16 px glyphs at ×2
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if emblem == null:
		icon.modulate = colour  # multiplier: the category's colour on the glyph
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	var title := Label.new()
	title.name = "Name"
	title.text = gift.name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.display(title, 20)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)
	var group := Label.new()
	group.name = "Category"
	group.text = gift.group
	group.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.caps(group, 13, colour)
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(group)
	var text := StatusLinks.make_label(gift.text, 15, UiStyle.INK)  # {spored}, Kinship… become links
	text.name = "Text"
	text.mouse_filter = Control.MOUSE_FILTER_PASS  # Status words hover; a click still picks the card
	box.add_child(text)
	box.minimum_size_changed.connect(func() -> void:
		button.custom_minimum_size = Vector2(CARD_SIZE.x, maxf(CARD_SIZE.y, box.get_combined_minimum_size().y + 24.0)))
	return button

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
		_route_now = map.get_path_from(map.startPath).size() if map != null else 0

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
				var route: PackedVector2Array = map.get_path_from(map.startPath)
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
				var change := _path_if_cleared(cells).size() - _route_now if not cells.is_empty() else 0
				return "%d of %d%s" % [cells.size(), int(size),
					(" · %+d path" % change) if change != 0 else ""] + ("" if not cells.is_empty() else " · " + hint % int(size))
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
		return map.get_path_if_blocked_cells(all).size()

	func _refresh_route() -> void:
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
		for c in draw_cells:
			draw_rect(Rect2(map.MAP_GRID.calculate_map_position(c) - half, half * 2.0), Color(Palette.SPRIG, 0.4))
		if not is_complete():
			var ok: bool = _cell_ok(hover) or (kind == &"move" and map.obstacles.has(hover)) or kind == &"warden" or kind == &"kinship"
			var hover_cells: Array = _area(hover) if kind == &"area" else [hover]
			for c in hover_cells:
				draw_rect(Rect2(map.MAP_GRID.calculate_map_position(c) - half, half * 2.0),
					Color(Palette.SPRIG if ok else Palette.EMBER, 0.25), false, 2.0)
