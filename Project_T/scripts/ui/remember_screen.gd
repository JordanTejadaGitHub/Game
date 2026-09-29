extends Control
class_name RememberScreen

# Remember (run_design.md "The Remember screen, fleshed out"): one tab per owned family (its base
# Warden's portrait on the tab) plus Thornwall's growths. Each tab is a tree of idle-animated
# portraits: the base at the root, its two branches above, each branch's final form above that, the
# hidden branch (Memory Grove) in a third lane, and the Ascended form at the crown. Node states:
# grown on the map (×N), unlocked, can unlock (cost in motes, pulsing), locked (needs its branch
# first: dim, chained), Memory Grove (silhouette). Selecting a node opens a side panel (on phones it
# slides up from the bottom) with its stats, Dew to grow, Kinship, combos and the Unlock button; an
# unlock blooms along the tree line. Opens from the HUD's Remember button (any time; pauses) and
# after each boss's family pick. Built in code.

const MOTE := "✦"  # Dreamlight
const NODE_SIZE := Vector2(76, 92)  # 48 px+ for touch
const PORTRAIT := 56.0
const TREE_SIZE := Vector2(560, 440)
const SIDE_WIDTH := 300.0
const NARROW_WIDTH := 900.0  # Below this the side panel sits under the tree and slides up
const FRAME_TIME := 0.16  # Idle animation
# Heartwood 32 (ui_style.md): lines in Gold, locked ones in Slate, the bloom in Glow.
const LINE_COLOR := Color(UiStyle.BUTTON_GOLD, 0.6)
const LINE_LOCKED := Color(Color("5c5a78"), 0.5)  # Slate
const BLOOM_COLOR := UiStyle.GOLD
const HEADER_COLOR := UiStyle.INK
const STATUS_LINE_COLOR := Color("9cd4fc")  # Dewlight
const WAYSTONE_COLOR := Color(UiStyle.CARD_BG, 0.95)  # Night
const WAYSTONE_RIM := Color("3c3c5c")  # Dusk

enum State { GROWN, UNLOCKED, CAN_UNLOCK, NEEDS_LIGHT, LOCKED, GROVE }

@onready var dream_state: DreamState = %DreamState
@onready var game_speed: GameSpeed = %GameSpeed

var focus: TowerData = null
var peek: ChoicePeek  # Minimise to look at the map (screens_ui.md "Choice screens")
var selected: TowerData = null
var _tab_root: TowerData = null  # The tree shown
var _was_paused := false
var _title := Label.new()
var _light_line := Label.new()
var _tabs := HBoxContainer.new()
var _body: BoxContainer
var _canvas: TreeCanvas
var _side := PanelContainer.new()
var _side_box := VBoxContainer.new()
var _dev_free := CheckButton.new()  # "Dev: unlock free" (dev runs of debug builds)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(UiStyle.FOG, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", UiStyle.panel(18, 14))
	center.add_child(frame)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	frame.add_child(box)

	# Header: "Remember", "Dreamlight 3 ✦ · unspent carries over", "Dreamlight unlocks, Dew grows."
	UiStyle.title(_title, UiStyle.CHOICE_TITLE_SIZE, HEADER_COLOR)
	_title.text = "Remember"
	box.add_child(_title)
	UiStyle.number(_light_line, 20)
	box.add_child(_light_line)
	var hint := Label.new()
	hint.text = "Dreamlight unlocks, Dew grows."
	hint.add_theme_color_override("font_color", UiStyle.INK_DIM)
	box.add_child(hint)

	_tabs.add_theme_constant_override("separation", 6)
	box.add_child(_tabs)
	_body = HBoxContainer.new()
	_body.add_theme_constant_override("separation", 14)
	box.add_child(_body)
	_canvas = TreeCanvas.new(self)
	_body.add_child(_canvas)
	_side.add_theme_stylebox_override("panel", UiStyle.panel_in(UiStyle.GOLD, 12, 12))
	_side.custom_minimum_size = Vector2(SIDE_WIDTH, 0)
	_side_box.add_theme_constant_override("separation", 6)
	_side.add_child(_side_box)
	_body.add_child(_side)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 12)
	box.add_child(footer)
	var done := Button.new()
	done.text = "Done"
	done.focus_mode = Control.FOCUS_NONE
	done.custom_minimum_size = Vector2(160, 48)
	done.pressed.connect(close)
	footer.add_child(done)
	_dev_free.text = "Dev: unlock free"
	_dev_free.focus_mode = Control.FOCUS_NONE
	_dev_free.toggled.connect(func(_on: bool) -> void: _fill_side(selected))
	footer.add_child(_dev_free)
	peek = ChoicePeek.new(self, [dim, center], "Back to Remember")
	footer.add_child(peek.make_peek_button())
	visible = false

	dream_state.remember_requested.connect(open)
	dream_state.dreamlight_changed.connect(func(_n: int) -> void:
		if visible:
			_rebuild())
	dream_state.unlocks_changed.connect(func() -> void:
		if visible:
			_rebuild())

# Opens on `focus_form`'s tree (null = the last tree shown). Pauses, and close() restores the pause
# state from before it opened.
func open(focus_form: TowerData = null) -> void:
	focus = focus_form
	if not visible:
		_was_paused = game_speed.paused
	game_speed.set_paused(true)
	visible = true
	selected = focus
	if focus != null:
		_tab_root = _root_of(focus)
	_layout_for_screen()
	_dev_free.visible = DreamState.dev_tools_on()
	if not _dev_free.visible:
		_dev_free.button_pressed = false
	_rebuild()

func close() -> void:
	visible = false
	game_speed.set_paused(_was_paused)
	dream_state.remember_closed()

# Unlocks `data` (the side panel's button). Returns whether it worked; blooms along the tree line.
func unlock(data: TowerData) -> bool:
	if not dream_state.unlock_with_dreamlight(data):
		return false
	selected = data
	if visible:
		_rebuild()
		_canvas.bloom(data)
	return true

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

# --- Building -------------------------------------------------------------------------------------------

func _trees() -> Array:
	return dream_state.get_remember_trees()

func _root_of(data: TowerData) -> TowerData:
	for tree in _trees():
		if _forms_of(tree).has(data):
			return tree[0]
	return null

func _forms_of(tree: Array) -> Array[TowerData]:
	var forms: Array[TowerData] = [tree[0]]
	for branch in tree[1]:
		forms.append(branch[0])
		for final in branch[1]:
			forms.append(final)
	if tree.size() > 2 and tree[2] != null:
		forms.append(tree[2])
	return forms

func _rebuild() -> void:
	_light_line.text = "Dreamlight %d %s · unspent carries over" % [dream_state.dreamlight, MOTE]
	var trees := _trees()
	for child in _tabs.get_children():
		_tabs.remove_child(child)
		child.queue_free()
	if trees.is_empty():
		_canvas.show_tree([])
		_fill_side(null)
		return
	if _tab_root == null or not trees.any(func(t: Array) -> bool: return t[0] == _tab_root):
		_tab_root = trees[0][0]
	for tree in trees:
		_tabs.add_child(_make_tab(tree[0]))
	var shown: Array = trees.filter(func(t: Array) -> bool: return t[0] == _tab_root)[0]
	if selected == null or not _forms_of(shown).has(selected):
		selected = _first_to_unlock(shown)
	_canvas.show_tree(shown)
	_fill_side(selected)

# The form to show first: one that can be unlocked now, else the base.
func _first_to_unlock(tree: Array) -> TowerData:
	for form in _forms_of(tree):
		if dream_state.can_unlock(form):
			return form
	return tree[0]

func _make_tab(root: TowerData) -> Button:
	var tab := Button.new()
	tab.text = "Thornwall" if root.line == "wall" else root.display_name
	tab.icon = WardenIcon.make(root)
	tab.toggle_mode = true
	tab.button_pressed = root == _tab_root
	tab.focus_mode = Control.FOCUS_NONE
	tab.custom_minimum_size = Vector2(0, 48)
	tab.pressed.connect(func() -> void:
		_tab_root = root
		selected = null
		_rebuild())
	return tab

# Phones: the side panel goes under the tree (and slides up on selecting) instead of beside it.
func _layout_for_screen() -> void:
	var want_vertical := get_viewport_rect().size.x < NARROW_WIDTH
	if (_body is VBoxContainer) == want_vertical:
		return
	var fresh: BoxContainer = VBoxContainer.new() if want_vertical else HBoxContainer.new()
	fresh.add_theme_constant_override("separation", 14)
	var parent := _body.get_parent()
	var index := _body.get_index()
	for child in [_canvas, _side]:
		_body.remove_child(child)
		fresh.add_child(child)
	parent.remove_child(_body)
	_body.queue_free()
	_body = fresh
	parent.add_child(_body)
	parent.move_child(_body, index)

func state_of(data: TowerData) -> State:
	var cost := dream_state.get_unlock_cost(data)
	var blocker := dream_state.get_unlock_blocker(data)
	if blocker == "Memory Grove":
		return State.GROVE
	if cost == 0:
		return State.GROWN if count_on_map(data) > 0 else State.UNLOCKED
	if blocker != "":
		return State.LOCKED
	return State.CAN_UNLOCK if cost <= dream_state.dreamlight else State.NEEDS_LIGHT

func count_on_map(data: TowerData) -> int:
	return dream_state.count_wardens(data.get_id())

# --- Side panel -----------------------------------------------------------------------------------------

func _fill_side(data: TowerData) -> void:
	for child in _side_box.get_children():
		_side_box.remove_child(child)
		child.queue_free()
	if data == null:
		_line("No family to remember yet.", UiStyle.INK_DIM, 15)
		return
	var grove := state_of(data) == State.GROVE
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	_side_box.add_child(head)
	head.add_child(Portrait.new(data, 72.0, grove))
	var names := VBoxContainer.new()
	head.add_child(names)
	var name_label := Label.new()
	name_label.text = "???" if grove else data.display_name
	UiStyle.display(name_label, 22)
	names.add_child(name_label)
	var kind := HBoxContainer.new()
	kind.add_theme_constant_override("separation", 6)
	names.add_child(kind)
	var type_icon := TextureRect.new()
	type_icon.texture = IconInfo.damage_type_icon(data.line)
	type_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	kind.add_child(type_icon)
	var tier := Label.new()
	tier.text = "%s · %s" % [_tier_name(data), IconInfo.damage_type_name(data.line)]
	tier.add_theme_color_override("font_color", IconInfo.damage_type_color(data.line))
	kind.add_child(tier)
	if grove:
		_line("A form the Memory Grove hasn't grown yet.", UiStyle.INK_DIM, 15)
		if _dev_free.button_pressed:
			_add_unlock(data)  # Dev: even Grove-hidden forms
		return
	var what := StatusLinks.make_label(data.description, 15, UiStyle.INK)
	what.custom_minimum_size = Vector2(SIDE_WIDTH - 30, 0)
	_side_box.add_child(what)
	if data.can_attack:
		var parts: Array[String] = ["%d damage" % data.damage, "%.2f attacks/s" % data.attacks_per_second,
			"range %.1f" % data.attack_range]
		if data.potency != 1.0:
			parts.append("potency %d%%" % roundi(data.potency * 100))
		_line(" · ".join(parts), UiStyle.INK_DIM, 14)
	var statuses: Array[String] = []
	for status in [data.applies_status, data.extra_status]:
		if status != &"":
			statuses.append(IconInfo.status_name(status))
	if not statuses.is_empty():
		_line("Applies " + " and ".join(statuses), STATUS_LINE_COLOR, 14)
	# Dew to grow into it (from its parent), or to plant the base
	if data.buildable_directly:
		_line("Plant: %d Dew" % data.cost, UiStyle.GOLD, 14)
	elif data.tier >= DreamState.ASCENDED_TIER:
		_line("Grow from its final form: %d Dew" % dream_state.get_evolve_cost(data), UiStyle.GOLD, 14)
	else:
		var parent := dream_state.get_parent_form(data)
		if parent != null:
			_line("Grow from %s: %d Dew" % [parent.display_name, dream_state.get_evolve_cost(data)], UiStyle.GOLD, 14)
	var count := count_on_map(data)
	if count > 0:
		_line("On your map: ×%d" % count, UiStyle.INK_DIM, 14)
	var kin := _kinship_line(data)
	if kin != "":
		_line(kin, UiStyle.LIVE, 14)
	_add_combos(data)
	_add_unlock(data)

func _line(text: String, colour: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(SIDE_WIDTH - 30, 0)
	label.add_theme_color_override("font_color", colour)
	label.add_theme_font_size_override("font_size", font_size)
	_side_box.add_child(label)
	return label

static func _tier_name(data: TowerData) -> String:
	match data.tier:
		1:
			return "Wall" if data.line == "wall" else "Base"
		2:
			return "Wall growth" if data.line == "wall" else "Branch"
		3:
			return "Final form"
	return "Ascended"

# "Kin: Chime Stone · Night Chimes" (its Kinship partner and the Kinship's name).
func _kinship_line(data: TowerData) -> String:
	var branch := Kinships.branch_of(data)
	if branch == "":
		return ""
	for id in Kinships.KINSHIPS:
		if not Kinships.is_available(id):
			continue
		var row: Array = Kinships.KINSHIPS[id]
		var partner := ""
		if row[2] == branch:
			partner = row[3]
		elif row[3] == branch:
			partner = row[2]
		if partner != "":
			return "Kin: %s · %s" % [CodexData._warden_name(partner), row[0]]
	return ""

# The combos this form is part of, as links to the Codex.
func _add_combos(data: TowerData) -> void:
	var statuses := {}
	for status in [data.applies_status, data.extra_status]:
		if status != &"":
			statuses[status] = true
	var found: Array = []
	for combo in CodexData.combos():
		var by := String(combo.get("by", ""))
		var takes_part: bool = false
		if by != "":
			takes_part = Array(by.split(", ")).has(data.display_name)
		else:
			takes_part = combo.statuses.any(func(s: StringName) -> bool: return statuses.has(s))
		if takes_part:
			found.append(combo)
	if found.is_empty():
		return
	UiStyle.caps(_line("Combos", UiStyle.INK_DIM, 13), 15)  # A small-caps section label
	var flow := HFlowContainer.new()
	flow.custom_minimum_size = Vector2(SIDE_WIDTH - 30, 0)
	_side_box.add_child(flow)
	for combo in found.slice(0, 6):
		var link := LinkButton.new()
		link.text = combo.name
		link.focus_mode = Control.FOCUS_NONE
		link.pressed.connect(_open_in_codex.bind(StringName(combo.id)))
		flow.add_child(link)

func _open_in_codex(id: StringName) -> void:
	var pause := get_node_or_null("%PauseMenu")
	if pause != null and pause.has_method("open_codex"):
		close()
		pause.open_codex(&"combos", String(id))

func _add_unlock(data: TowerData) -> void:
	var cost := dream_state.get_unlock_cost(data)
	if cost == 0:
		return
	if _dev_free.button_pressed and not data.buildable_directly:
		var free := Button.new()
		free.text = "Unlock free (dev)"
		free.focus_mode = Control.FOCUS_NONE
		free.custom_minimum_size = Vector2(0, 48)
		free.pressed.connect(func() -> void:
			if dream_state.dev_unlock(data):
				selected = data
				_rebuild()
				_canvas.bloom(data))
		_side_box.add_child(free)
		return
	var blocker := dream_state.get_unlock_blocker(data)
	if blocker != "":
		_line("Locked: " + blocker, UiStyle.INK_DIM, 13)
	elif cost > dream_state.dreamlight:
		_line("Needs %d more %s" % [cost - dream_state.dreamlight, MOTE], UiStyle.INK_DIM, 13)
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 48)
	button.text = "Unlock (%d %s)" % [cost, MOTE]
	button.disabled = not dream_state.can_unlock(data)
	UiStyle.primary(button)
	button.pressed.connect(unlock.bind(data))
	_side_box.add_child(button)

func _select(data: TowerData) -> void:
	selected = data
	_canvas.queue_redraw()
	for node in _canvas.nodes.values():
		node.queue_redraw()
	_fill_side(data)
	if _body is VBoxContainer:  # Phones: the panel slides up into view
		_side.modulate.a = 0.0
		var tween := create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(_side, "modulate:a", 1.0, 0.18)


# --- The tree -------------------------------------------------------------------------------------------

# Lays out one family's forms (root at the bottom, branch lanes above, finals above them, the hidden
# branch in a third lane, Ascended at the crown) and draws the lines between them.
class TreeCanvas extends Control:
	var screen: RememberScreen
	var nodes := {}  # TowerData -> FormNode
	var edges: Array = []  # [parent TowerData, child TowerData]
	var _bloom_edge: Array = []
	var _bloom_t := 0.0

	func _init(owner_screen: RememberScreen) -> void:
		screen = owner_screen
		custom_minimum_size = TREE_SIZE
		mouse_filter = Control.MOUSE_FILTER_PASS

	func show_tree(tree: Array) -> void:
		for node in nodes.values():
			remove_child(node)
			node.queue_free()
		nodes.clear()
		edges.clear()
		if tree.is_empty():
			queue_redraw()
			return
		var root: TowerData = tree[0]
		var shown: Array = []  # [branch, finals]; the Grove-hidden ones last (the third lane)
		var hidden: Array = []
		for branch in tree[1]:
			if screen.dream_state.get_unlock_blocker(branch[0]) == "Memory Grove":
				hidden.append(branch)
			else:
				shown.append(branch)
		shown.append_array(hidden)
		var lanes := maxi(shown.size(), 1)
		var ascended: TowerData = tree[2] if tree.size() > 2 else null
		var rows := 4 if ascended != null else 3
		_place(root, Vector2(TREE_SIZE.x / 2.0, _row_y(0, rows)))
		for i in shown.size():
			var lane_x := TREE_SIZE.x * (i + 1) / float(lanes + 1)
			var branch: TowerData = shown[i][0]
			_place(branch, Vector2(lane_x, _row_y(1, rows)))
			edges.append([root, branch])
			var finals: Array = shown[i][1]
			for j in finals.size():
				var spread := (j - (finals.size() - 1) / 2.0) * (NODE_SIZE.x + 6)
				_place(finals[j], Vector2(lane_x + spread, _row_y(2, rows)))
				edges.append([branch, finals[j]])
				if ascended != null and finals[j].evolves_to.has(ascended):
					edges.append([finals[j], ascended])
		if ascended != null:
			_place(ascended, Vector2(TREE_SIZE.x / 2.0, _row_y(3, rows)))
		queue_redraw()

	# Top of row `row` (0 = the root, at the bottom).
	func _row_y(row: int, rows: int) -> float:
		var span := TREE_SIZE.y - NODE_SIZE.y
		return span - row * span / float(maxi(rows - 1, 1))

	func _place(data: TowerData, centre_top: Vector2) -> void:
		var node := FormNode.new(screen, data)
		node.position = Vector2(centre_top.x - NODE_SIZE.x / 2.0, centre_top.y)
		add_child(node)
		nodes[data] = node

	func _centre(data: TowerData) -> Vector2:
		var node: Control = nodes[data]
		return node.position + Vector2(NODE_SIZE.x / 2.0, PORTRAIT / 2.0 + 4)

	# An unlock: light runs from the parent to the new form.
	func bloom(data: TowerData) -> void:
		for edge in edges:
			if edge[1] == data:
				_bloom_edge = edge
				_bloom_t = 0.0
				var tween := create_tween()
				tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
				tween.tween_method(func(t: float) -> void:
					_bloom_t = t
					queue_redraw(), 0.0, 1.0, 0.6)
				tween.tween_callback(func() -> void:
					_bloom_edge = []
					queue_redraw())
				return

	func _draw() -> void:
		for edge in edges:
			if not nodes.has(edge[0]) or not nodes.has(edge[1]):
				continue
			var a := _centre(edge[0])
			var b := _centre(edge[1])
			var child_state: int = screen.state_of(edge[1])
			var faint := child_state == State.LOCKED or child_state == State.GROVE
			draw_line(a, b, LINE_LOCKED if faint else LINE_COLOR, 3.0, true)
			if child_state == State.LOCKED:  # A thin chain: little links along the line
				var steps := int(a.distance_to(b) / 10.0)
				for k in steps:
					draw_circle(a.lerp(b, (k + 0.5) / float(steps)), 2.0, Color(LINE_LOCKED, 0.8))
		if not _bloom_edge.is_empty() and nodes.has(_bloom_edge[0]) and nodes.has(_bloom_edge[1]):
			var a := _centre(_bloom_edge[0])
			var b := _centre(_bloom_edge[1])
			draw_line(a, a.lerp(b, _bloom_t), BLOOM_COLOR, 5.0, true)
			draw_circle(a.lerp(b, _bloom_t), 8.0 * (1.0 - _bloom_t * 0.5), Color(BLOOM_COLOR, 0.8))


# One form on its waystone: the idle-animated portrait, its state, "×3" or the cost in motes.
class FormNode extends Button:
	var screen: RememberScreen
	var data: TowerData
	var portrait: Portrait
	var _pulse := 0.0

	func _init(owner_screen: RememberScreen, form: TowerData) -> void:
		screen = owner_screen
		data = form
		custom_minimum_size = NODE_SIZE
		size = NODE_SIZE
		flat = true
		focus_mode = Control.FOCUS_NONE
		process_mode = Node.PROCESS_MODE_ALWAYS
		var state := screen.state_of(data)
		portrait = Portrait.new(data, PORTRAIT, state == State.GROVE)
		portrait.position = Vector2((NODE_SIZE.x - PORTRAIT) / 2.0, 4)
		add_child(portrait)
		if state == State.LOCKED:
			portrait.modulate = Color(1, 1, 1, 0.5)
		elif state == State.CAN_UNLOCK or state == State.NEEDS_LIGHT:
			portrait.modulate = Color(1, 1, 1, 0.75)
		tooltip_text = "Memory Grove" if state == State.GROVE else data.display_name
		pressed.connect(func() -> void: screen._select(data))

	func _process(delta: float) -> void:
		if screen.state_of(data) == State.CAN_UNLOCK:
			_pulse += delta
			queue_redraw()

	func _draw() -> void:
		var state := screen.state_of(data)
		var centre := Vector2(NODE_SIZE.x / 2.0, 4 + PORTRAIT / 2.0)
		# The waystone under the portrait
		var stone := centre + Vector2(0, PORTRAIT / 2.0 - 2)
		draw_circle(stone, PORTRAIT / 2.0 - 6, WAYSTONE_COLOR)
		draw_arc(stone, PORTRAIT / 2.0 - 6.5, 0.0, TAU, 40, WAYSTONE_RIM, 1.0, true)
		if screen.selected == data:
			draw_arc(centre, PORTRAIT / 2.0 + 3, 0.0, TAU, 40, UiStyle.GOLD, 2.0, true)
		if state == State.CAN_UNLOCK:
			var glow := 0.35 + 0.25 * sin(_pulse * 3.0)
			draw_arc(centre, PORTRAIT / 2.0 + 1, 0.0, TAU, 40, Color(UiStyle.GOLD, glow), 3.0, true)
		var text := ""
		var colour := UiStyle.INK
		match state:
			State.GROWN:
				text = "×%d" % screen.count_on_map(data)
			State.CAN_UNLOCK, State.NEEDS_LIGHT:
				text = MOTE.repeat(screen.dream_state.get_unlock_cost(data))
				colour = UiStyle.GOLD if state == State.CAN_UNLOCK else UiStyle.INK_DIM
			State.LOCKED:
				text = "locked"
				colour = UiStyle.INK_DIM
			State.GROVE:
				text = "Grove"
				colour = UiStyle.INK_DIM
		if text != "":
			# Counts and motes in the number face; "locked" / "Grove" as small-caps labels.
			var words := state == State.LOCKED or state == State.GROVE
			var font := UiStyle.caps_font() if words else UiStyle.number_font()
			var font_size := 14 if words else 16
			var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			draw_string(font, Vector2((NODE_SIZE.x - width) / 2.0, NODE_SIZE.y - 6), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)


# A Warden's idle loop in a box (its TowerData sheet: `frame_count` frames in a row); black for a
# form the Memory Grove hasn't grown (a silhouette).
class Portrait extends TextureRect:
	var data: TowerData
	var _atlas := AtlasTexture.new()
	var _frame := 0
	var _clock := 0.0

	func _init(form: TowerData, side: float, silhouette: bool = false) -> void:
		data = form
		custom_minimum_size = Vector2(side, side)
		size = Vector2(side, side)
		expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		process_mode = Node.PROCESS_MODE_ALWAYS
		if data.texture != null:
			_atlas.atlas = data.texture
			_atlas.region = WardenIcon.region(data)
			texture = _atlas
		if silhouette:
			self_modulate = Color(0, 0, 0, 0.85)

	func _process(delta: float) -> void:
		if data.texture == null or data.frame_count <= 1:
			return
		_clock += delta
		if _clock < FRAME_TIME:
			return
		_clock = 0.0
		_frame = (_frame + 1) % data.frame_count
		var crop := WardenIcon.region(data)
		var offset := data.get_frame_rect(_frame).position - data.get_frame_rect(0).position
		_atlas.region = Rect2(crop.position + offset, crop.size)
