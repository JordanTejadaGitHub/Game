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
}

var drift_director: DriftDirector
var gifts: HeartwoodGifts
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
	if gifts.waiting and not visible and drift_director.pending_choice() == &"gift":
		open()
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
	visible = true
	_show_cards(true)
	arm.arm()

func _card(id: StringName) -> Button:
	var gift: Dictionary = HeartwoodGifts.POOL[id]
	var button := Button.new()
	button.name = String(id)
	button.text = "%s\n%s\n\n%s" % [gift.name, gift.group, IconInfo.format(gift.text)]
	button.custom_minimum_size = Vector2(240, 190)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.focus_mode = Control.FOCUS_NONE
	UiStyle.card_button(button, UiStyle.LIVE if gift.map else UiStyle.GOLD)
	button.pressed.connect(pick.bind(id))
	return button

# A card: placed first (map gifts), else taken now.
func pick(id: StringName) -> void:
	if not HeartwoodGifts.needs_placing(id):
		gifts.choose(id)
		_close()
		return
	placing = id
	_show_cards(false)
	placer = GiftPlacer.new(drift_director, id, BLOCKING.has(id))
	drift_director.owner.add_child(placer)

func cancel_placing() -> void:
	if placer != null:
		placer.queue_free()
		placer = null
	placing = &""
	_show_cards(true)

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
		_refresh_route()
		queue_redraw()

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
