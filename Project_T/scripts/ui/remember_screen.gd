extends Control
class_name RememberScreen

# Remember (run_design.md "The Remember screen, fleshed out"): one tab per owned family (its base
# Warden's portrait on the tab) plus Thornwall's growths. Each tab is a tree of idle-animated
# portraits: the base at the root, its two branches above, each branch's final form above that, the
# hidden branch (Memory Grove) in a third lane, and the Ascended form at the crown. Node states:
# grown on the map (×N), unlocked, can unlock (cost in motes, pulsing), locked (needs its branch
# first: chained); not unlocked = its portrait at ~80% on a moonlit disc with its name; Memory Grove = a silhouette with a leaf badge. Selecting a node opens a side panel (on phones it
# slides up from the bottom) with its stats, Dew to grow, Kinship, combos and the Unlock button; an
# unlock blooms along the tree line. Opens from the HUD's Remember button (any time; pauses) and
# after each boss's family pick. Built in code.

# For Sound (SoundHooks connects them if they exist; audio_direction.md "Remember screen").
signal opened
signal closed
signal node_selected(data: TowerData)  # A node tapped
signal unlocked(data: TowerData)  # A successful unlock (Sound reads data.tier)
signal unlock_rejected(data: TowerData)  # Not enough Dreamlight, or still locked

const MOTE := "✦"  # Dreamlight
const UNKNOWN_NAME := "???"  # A form the Memory Grove hasn't planted: no name, on the tree or in the panel (user)
const NODE_SIZE := Vector2(76, 92)  # 48 px+ for touch
const NAME_SIZE := 14  # Form names under the portraits (body font)
const NAME_MIN_SIZE := 11  # A long name shrinks to this, then ends in "…"
const PORTRAIT := 56.0
const TREE_SIZE := Vector2(560, 390)  # Shorter since the "Not in this dream" strip sits under it (fits 1280×800)
const SIDE_WIDTH := 300.0
const NARROW_WIDTH := 900.0  # Below this the side panel sits under the tree and slides up
const FRAME_TIME := 0.16  # Idle animation
# Heartwood 32 (ui_style.md): lines in Gold, locked ones in Slate, the bloom in Glow.
const LINE_LOCKED := Color(Color("5c5a78"), 0.5)  # Slate
const BLOOM_COLOR := UiStyle.GOLD
const PATH_GLOW := UiStyle.GOLD  # Lines to unlocked / grown forms
const HEADER_COLOR := UiStyle.INK
const STATUS_LINE_COLOR := Color("9cd4fc")  # Dewlight

enum State { GROWN, UNLOCKED, CAN_UNLOCK, NEEDS_LIGHT, LOCKED, GROVE, NOT_IN_DREAM }  # NOT_IN_DREAM: branch expansion

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
var _misty := VBoxContainer.new()  # "Not in this dream": the family's branches not offered this run
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
	var frame_style := UiStyle.panel(18, 14)
	frame_style.edge_alpha = ChoiceCard.EDGE_ALPHA  # Solid like the other paused screens: the map's DPS tags showed through
	frame_style.center_alpha = ChoiceCard.CENTER_ALPHA
	frame.add_theme_stylebox_override("panel", frame_style)
	center.add_child(frame)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	frame.add_child(box)

	# Header: "Remember", "Dreamlight 3 ✦", "Dreamlight unlocks, Dew grows."
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
	_misty.name = "NotInDream"  # Branch expansion: this family's branches not in this run, apart from the tree
	_misty.add_theme_constant_override("separation", 4)
	box.add_child(_misty)

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
	var was_open := visible
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
	if not was_open:
		opened.emit()

func close() -> void:
	visible = false
	game_speed.set_paused(_was_paused)
	dream_state.remember_closed()
	closed.emit()

# Unlocks `data` (the side panel's button). Returns whether it worked; blooms along the tree line.
func unlock(data: TowerData) -> bool:
	if not dream_state.unlock_with_dreamlight(data):
		unlock_rejected.emit(data)
		return false
	unlocked.emit(data)
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
	_light_line.text = "Dreamlight %d %s" % [dream_state.dreamlight, MOTE]
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
	_fill_misty(shown[0])

# The strip under the tree (story chat: the not-offered branches beside the base read as its siblings): each
# branch of `root`'s family not in this run, a faint silhouette with its name and "Call in · 3 Dreamlight" (once per
# family; free with Remembered Path; greyed after use). A tap on one shows it in the side panel too.
const MISTY_PORTRAIT := 40.0

func _fill_misty(root: TowerData) -> void:
	for child in _misty.get_children():
		_misty.remove_child(child)
		child.queue_free()
	var forms: Array[TowerData] = dream_state.not_offered_branches(root) if root.tier == 1 else ([] as Array[TowerData])
	_misty.visible = not forms.is_empty()
	if forms.is_empty():
		return
	var head := Label.new()
	head.text = "Not in this dream"
	UiStyle.caps(head, 15)
	head.add_theme_color_override("font_color", UiStyle.INK_DIM)
	_misty.add_child(head)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	_misty.add_child(row)
	for form in forms:
		var item := HBoxContainer.new()
		item.name = "Misty_" + form.get_id()
		item.add_theme_constant_override("separation", 8)
		row.add_child(item)
		var look := Button.new()  # The silhouette: a tap shows it in the side panel
		look.flat = true
		look.focus_mode = Control.FOCUS_NONE
		look.custom_minimum_size = Vector2(MISTY_PORTRAIT, MISTY_PORTRAIT)
		look.tooltip_text = form.display_name + " · not in this dream"
		look.draw.connect(func() -> void:  # The moonlit disc behind the silhouette (as on the tree), faint
			UiStyle.draw_moon_disc(look, look.size / 2.0, MISTY_PORTRAIT / 2.0 - 1))
		look.modulate = Color(1, 1, 1, 0.6)  # multiplier: the mist
		var portrait := Portrait.new(form, MISTY_PORTRAIT, true)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		look.add_child(portrait)
		look.pressed.connect(_select.bind(form))
		item.add_child(look)
		var words := VBoxContainer.new()
		item.add_child(words)
		var name_label := Label.new()
		name_label.text = form.display_name
		name_label.add_theme_font_override("font", UiStyle.body_font())
		name_label.add_theme_font_size_override("font_size", 15)
		name_label.add_theme_color_override("font_color", UiStyle.INK_DIM)
		words.add_child(name_label)
		var call := Button.new()
		call.name = "CallIn"
		call.focus_mode = Control.FOCUS_NONE
		var problem := dream_state.call_back_problem(form)
		var free := dream_state.free_calls > 0
		call.text = "Call in · free" if free else "Call in · %d Dreamlight" % DreamState.CALL_BACK_DREAMLIGHT
		call.disabled = problem != ""
		call.tooltip_text = (problem[0].to_upper() + problem.substr(1) + ".") if problem != "" \
			else "Once per family each run. Its final still costs %d." % DreamState.FINAL_DREAMLIGHT
		call.pressed.connect(func() -> void:
			if dream_state.call_back(form):
				selected = form
				_rebuild()
				_canvas.bloom(form))
		words.add_child(call)

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

# Grown or unlocked this run: full colour; anything else is a silhouette on the moonlit disc.
static func is_unlocked_state(state: State) -> bool:
	return state == State.GROWN or state == State.UNLOCKED

func state_of(data: TowerData) -> State:
	var cost := dream_state.get_unlock_cost(data)
	var blocker := dream_state.get_unlock_blocker(data)
	if blocker == "Memory Grove":
		return State.GROVE
	if blocker == DreamState.NOT_IN_DREAM and cost > 0:
		return State.NOT_IN_DREAM
	if cost == 0:
		return State.GROWN if count_on_map(data) > 0 else State.UNLOCKED
	if blocker != "":
		return State.LOCKED
	return State.CAN_UNLOCK if dream_state.get_unlock_price(data) <= dream_state.dreamlight else State.NEEDS_LIGHT  # Waking Root's discount

func count_on_map(data: TowerData) -> int:
	return dream_state.count_wardens(data.get_id())

# --- Side panel -----------------------------------------------------------------------------------------

# A form whose look stays hidden (user: "hide the final evolution until you unlock the first one"): a final form until
# its branch is unlocked this run (bought or called in), an Ascended form until a final of its family is. Shown as a dim
# "?" with no portrait, stats or cost. Dev "unlock free" shows everything.
func is_veiled(data: TowerData) -> bool:
	if data == null or _dev_free.button_pressed or dream_state.unlock_everything or dream_state.is_unlocked(data.get_id()):
		return false
	if data.tier >= DreamState.ASCENDED_TIER:
		return not dream_state._has_unlocked_final(data)
	if data.tier == 3:
		var branch := dream_state._parent_in_tree(data)
		return branch != null and branch.tier == 2 and not dream_state.is_unlocked(branch.get_id())
	return false

# The step that unveils `data`: "Unlock Stormcap to see what it becomes".
func veil_hint(data: TowerData) -> String:
	if data.tier >= DreamState.ASCENDED_TIER:
		return "Unlock a final form of this family to see what it becomes"
	var branch := dream_state._parent_in_tree(data)
	return "Unlock %s to see what it becomes" % (branch.display_name if branch != null else "its branch")

func _fill_side(data: TowerData) -> void:
	for child in _side_box.get_children():
		_side_box.remove_child(child)
		child.queue_free()
	if data == null:
		_line("No family to remember yet.", UiStyle.INK_DIM, 15)
		return
	if is_veiled(data):  # Only the "?" and how to reveal it
		var mark := Label.new()
		mark.text = "?"
		UiStyle.display(mark, 22)
		mark.add_theme_color_override("font_color", UiStyle.INK_DIM)
		_side_box.add_child(mark)
		_line(veil_hint(data), UiStyle.INK_DIM, 15)
		return
	var grove := state_of(data) == State.GROVE
	if state_of(data) == State.NOT_IN_DREAM:
		_fill_not_in_dream(data)
		return
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	_side_box.add_child(head)
	head.add_child(Portrait.new(data, 72.0, grove))  # A Grove-locked form stays a silhouette here too (user)
	if grove:  # run_design.md: a Grove-locked form shows only its silhouette, "???", "Locked" and the invitation
		var grove_name := Label.new()
		grove_name.text = UNKNOWN_NAME
		UiStyle.display(grove_name, 22)
		head.add_child(grove_name)
		UiStyle.caps(_line("Locked", UiStyle.INK_DIM, 14), 14)  # No description, stats or combos until it's planted
		_line("Plant it in the Memory Grove", UiStyle.INK_DIM, 15)
		if _dev_free.button_pressed:
			_add_unlock(data)  # Dev: even Grove-hidden forms
		return
	var names := VBoxContainer.new()
	head.add_child(names)
	var name_label := Label.new()
	name_label.text = data.display_name
	UiStyle.display(name_label, 22)
	names.add_child(name_label)
	var kind := HBoxContainer.new()
	kind.add_theme_constant_override("separation", 6)
	names.add_child(kind)
	var tier := Label.new()
	tier.text = "%s · %s damage" % [_tier_name(data), IconInfo.damage_type_name(data.line)]  # No icon (user): the damage type in its colour
	tier.add_theme_color_override("font_color", IconInfo.damage_type_color(data.line))
	kind.add_child(tier)
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
	# {combo:<id>} links (Main's StatusLinks, 43acd9f8) for the combos found so far; hover or tap shows the combo tip,
	# a second tap opens it in the Codex (user: "hovering over combos doesn't do anything"). The undiscovered ones are
	# a count, never a row of ??? (story chat: "Combos: ??? · ??? · ???" meant nothing).
	var discovered: Array = found.filter(func(combo: Dictionary) -> bool: return CodexData.is_discovered(StringName(combo.id)))
	var hidden := found.size() - discovered.size()
	var tokens: Array = discovered.slice(0, 6).map(func(combo: Dictionary) -> String: return "{combo:%s}" % combo.id)
	if hidden > 0:
		tokens.append("%d to discover" % hidden)
	var links := StatusLinks.make_label(" · ".join(tokens), 15, UiStyle.INK)
	links.name = "Combos"
	links.custom_minimum_size = Vector2(SIDE_WIDTH - 30, 0)
	_side_box.add_child(links)

# Branch expansion: a branch not in this run. Its silhouette and name, the line, what it does (to judge a call),
# and the call-back: CALL_BACK_DREAMLIGHT once per family, or free with Remembered Path.
const NOT_IN_DREAM_LINE := "Not in this dream. The Heartwood may remember it next time."

func _fill_not_in_dream(data: TowerData) -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	_side_box.add_child(head)
	var portrait := Portrait.new(data, 72.0, true)
	portrait.modulate = Color(1, 1, 1, 0.6)  # multiplier: the mist
	head.add_child(portrait)
	var name_label := Label.new()
	name_label.text = data.display_name
	UiStyle.display(name_label, 22)
	name_label.add_theme_color_override("font_color", UiStyle.INK_DIM)
	head.add_child(name_label)
	_line(NOT_IN_DREAM_LINE, UiStyle.INK_DIM, 15)
	if data.description != "":
		_line(IconInfo.format(data.description), UiStyle.INK_DIM, 13)
	_add_call_back(data)

func _add_call_back(data: TowerData) -> void:
	var button := Button.new()
	button.name = "CallBackButton"
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 48)
	var free := dream_state.free_calls > 0
	var problem := dream_state.call_back_problem(data)
	UiStyle.primary(button)
	_side_box.add_child(button)
	if problem == "Not enough Dreamlight":  # The cost in POOR, a press refuses (as Unlock)
		CantAfford.apply(button, "Call into this dream", "%d Dreamlight" % DreamState.CALL_BACK_DREAMLIGHT, IconInfo.format(SHORT_TIP))
		button.pressed.connect(_refuse_call_back.bind(button))
		return
	button.text = "Call into this dream · free (Remembered Path)" if free else "Call into this dream · %d Dreamlight" % DreamState.CALL_BACK_DREAMLIGHT
	if problem != "":
		button.disabled = true
		_line(problem[0].to_upper() + problem.substr(1) + ".", UiStyle.INK_DIM, 13)
		return
	_line("Once per family each run. Its final still costs %d." % DreamState.FINAL_DREAMLIGHT, UiStyle.INK_DIM, 13)
	button.pressed.connect(func() -> void:
		if dream_state.call_back(data):
			selected = data
			_rebuild()
			_canvas.bloom(data))

func _refuse_call_back(button: Button) -> void:
	CantAfford.shake(button)
	var hud := get_parent()
	if hud != null and hud.has_method("show_toast"):
		hud.show_toast("Not enough Dreamlight")
	dream_state.dreamlight_short.emit(DreamState.CALL_BACK_DREAMLIGHT)

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
	var button := Button.new()
	button.name = "UnlockButton"
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 48)
	var price := dream_state.get_unlock_price(data)  # Waking Root (Heartwood's Gifts): 1 less, once
	var label := ("Unlock · %d Dreamlight" % price) if price > 0 else "Unlock · free"
	if price < cost:
		label += " (Waking Root)"
	var short := price - dream_state.dreamlight  # > 0: can't afford
	button.disabled = blocker != ""  # Locked for another reason: a plain disabled button (the line says why)
	UiStyle.primary(button)
	_side_box.add_child(button)
	if blocker == "" and short > 0:  # Can't afford yet (CantAfford): the cost in POOR, no count (user); a press refuses
		CantAfford.apply(button, "Unlock", "%d Dreamlight" % price, IconInfo.format(SHORT_TIP))
		button.pressed.connect(_refuse_unlock.bind(data, button))
	else:
		button.text = label
		button.pressed.connect(unlock.bind(data))

# The short button's hover / tap: no count (user: "too much hand-holding"), just where Dreamlight comes from.
const SHORT_TIP := "Not enough Dreamlight. It comes at {rests} and from bosses."

# Pressed while short: the shake, the toast, the Dreamlight counter flashing (and Sound's refusal via unlock_rejected).
func _refuse_unlock(data: TowerData, button: Button) -> void:
	unlock_rejected.emit(data)
	CantAfford.shake(button)
	var hud := get_parent()
	if hud != null and hud.has_method("show_toast"):
		hud.show_toast("Not enough Dreamlight")
	dream_state.dreamlight_short.emit(dream_state.get_unlock_price(data))  # The HUD flashes the Dreamlight counter

func _select(data: TowerData) -> void:
	selected = data
	node_selected.emit(data)
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
		var misty: Array[TowerData] = []  # Branch expansion: not in this dream, lower down, no finals or lines
		for branch in tree[1]:
			var blocker := screen.dream_state.get_unlock_blocker(branch[0])
			if blocker == "Memory Grove":
				hidden.append(branch)
			elif blocker == DreamState.NOT_IN_DREAM:
				misty.append(branch[0])
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
			# A lane the Grove hasn't planted shows only its branch (the silhouette): no final, no line up to it
			var finals: Array = [] if hidden.has(shown[i]) else shown[i][1]
			for j in finals.size():
				var spread := (j - (finals.size() - 1) / 2.0) * (NODE_SIZE.x + 6)
				_place(finals[j], Vector2(lane_x + spread, _row_y(2, rows)))
				edges.append([branch, finals[j]])
				if ascended != null and finals[j].evolves_to.has(ascended):
					edges.append([finals[j], ascended])
		if ascended != null:
			_place(ascended, Vector2(TREE_SIZE.x / 2.0, _row_y(3, rows)))
		# The branches not in this dream (misty) aren't in the tree: the strip under it shows them (_fill_misty)
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
			# The chosen path glows gold (screens_ui.md "Playtest fixes"): lines to unlocked or grown
			# forms; every other line stays dim.
			if child_state == State.GROWN or child_state == State.UNLOCKED:
				draw_line(a, b, Color(PATH_GLOW, 0.25), 9.0, true)
				draw_line(a, b, PATH_GLOW, 3.5, true)
			else:
				draw_line(a, b, LINE_LOCKED, 3.0, true)
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
		portrait = Portrait.new(data, PORTRAIT, state == State.GROVE or state == State.NOT_IN_DREAM)  # Silhouettes: not planted, or not in this dream
		if state != State.GROVE and not RememberScreen.is_unlocked_state(state):
			portrait.modulate = Color.WHITE.darkened(0.2)  # Grove-available, not unlocked this run: its real colours, ~80%
		portrait.position = Vector2((NODE_SIZE.x - PORTRAIT) / 2.0, 4)
		add_child(portrait)
		tooltip_text = UNKNOWN_NAME + " · Plant it in the Memory Grove" if state == State.GROVE else data.display_name  # Grove-locked: no name (user), the hint
		if state == State.NOT_IN_DREAM:  # Branch expansion: a faint, misty silhouette
			modulate = Color(1, 1, 1, 0.5)  # multiplier: the mist
			tooltip_text = data.display_name + " · not in this dream"
		if screen.is_veiled(data):  # A final not revealed yet: no portrait, a dim "?"
			portrait.visible = false
			modulate = Color(1, 1, 1, 0.6)  # multiplier: dim
			tooltip_text = "? · " + screen.veil_hint(data)
		pressed.connect(func() -> void: screen._select(data))

	func _process(delta: float) -> void:
		if screen.state_of(data) == State.CAN_UNLOCK:
			_pulse += CardScene.real_delta(delta)  # Real time at any game speed
			queue_redraw()

	func _draw() -> void:
		var state := screen.state_of(data)
		var centre := Vector2(NODE_SIZE.x / 2.0, 4 + PORTRAIT / 2.0)
		# (No waystone disc under the portrait: offset below it, it read as a doubled ghost ring: story chat screenshot)
		UiStyle.draw_moon_disc(self, centre, PORTRAIT / 2.0 - 1)  # The lit backdrop on every node (unlocked ones lost it: story chat)
		if screen.selected == data:
			draw_arc(centre, PORTRAIT / 2.0 + 3, 0.0, TAU, 40, UiStyle.GOLD, 2.0, true)
		if screen.is_veiled(data):  # Not revealed yet: an empty disc labelled "?", no name, cost or glow
			_caption("?", UiStyle.body_font(), NAME_SIZE, UiStyle.INK_DIM, NODE_SIZE.y - 6)
			return
		if state == State.CAN_UNLOCK:
			var glow := 0.35 + 0.25 * sin(_pulse * 3.0)
			draw_arc(centre, PORTRAIT / 2.0 + 1, 0.0, TAU, 40, Color(UiStyle.GOLD, glow), 3.0, true)
		var text := ""
		var colour := UiStyle.INK
		match state:
			State.GROWN:  # Its name in gold (yours this run) above how many stand on the map
				_caption(data.display_name, UiStyle.body_font(), NAME_SIZE, UiStyle.GOLD, NODE_SIZE.y - 19)
				text = "×%d" % screen.count_on_map(data)
			State.UNLOCKED:  # Its name in gold: unlocked this run, none planted yet
				_caption(data.display_name, UiStyle.body_font(), NAME_SIZE, UiStyle.GOLD, NODE_SIZE.y - 6)
			State.CAN_UNLOCK, State.NEEDS_LIGHT:
				_caption(data.display_name, UiStyle.body_font(), NAME_SIZE, UiStyle.INK_DIM, NODE_SIZE.y - 19)  # Its name above the motes
				var price: int = screen.dream_state.get_unlock_price(data)
				text = MOTE.repeat(price) if price > 0 else "free"
				colour = UiStyle.GOLD if state == State.CAN_UNLOCK else UiStyle.INK_DIM
			State.LOCKED:
				text = data.display_name  # The chain on its line says it's locked
				colour = UiStyle.INK_DIM
			State.NOT_IN_DREAM:
				text = data.display_name  # No cost: it isn't unlocked, it's called back (side panel)
				colour = UiStyle.INK_DIM
			State.GROVE:
				text = name_shown()  # "???" under it (user: no name until planted), and a Grove leaf badge on the stone
				colour = UiStyle.INK_DIM
				_draw_leaf(centre + Vector2(PORTRAIT / 2.0 - 8, -PORTRAIT / 2.0 + 8))
		if text != "":
			# Counts and motes in the number face; names in the body font, readable (story chat: small caps were tiny)
			var words := state == State.LOCKED or state == State.GROVE or state == State.NOT_IN_DREAM
			var font := UiStyle.body_font() if words else UiStyle.number_font()
			var font_size := NAME_SIZE if words else 16
			_caption(text, font, font_size, colour, NODE_SIZE.y - 6)

	# The name this node shows: "???" for a form the Memory Grove hasn't planted (user), else its own.
	func name_shown() -> String:
		return UNKNOWN_NAME if screen.state_of(data) == State.GROVE else data.display_name

	# One centred line under the portrait: a long name shrinks (down to NAME_MIN_SIZE), then ends in "…", never past
	# the node ("Undercurrent" overflowed).
	func _caption(text: String, font: Font, font_size: int, colour: Color, baseline: float) -> void:
		var room := NODE_SIZE.x - 4
		while font_size > NAME_MIN_SIZE and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > room:
			font_size -= 1
		while text.length() > 3 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > room:
			text = text.left(text.length() - 2) + "…"
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(font, Vector2((NODE_SIZE.x - width) / 2.0, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)


	# The Memory Grove's leaf: a small two-arc leaf on the portrait's shoulder.
	func _draw_leaf(at: Vector2) -> void:
		var points := PackedVector2Array()
		for i in 9:
			var t := i / 8.0
			points.append(at + Vector2(lerpf(-5.0, 5.0, t), -sin(t * PI) * 3.5).rotated(-0.6))
		for i in range(7, 0, -1):
			var t := i / 8.0
			points.append(at + Vector2(lerpf(-5.0, 5.0, t), sin(t * PI) * 3.5).rotated(-0.6))
		draw_colored_polygon(points, Palette.SPRIG)
		draw_line(at + Vector2(-5, 0).rotated(-0.6), at + Vector2(5, 0).rotated(-0.6), Palette.MOSS, 1.0, true)

# A Warden's idle loop in a box (its TowerData sheet: `frame_count` frames in a row); black for a
# form the Memory Grove hasn't grown (a silhouette).
class Portrait extends TextureRect:
	var data: TowerData
	var _atlas := AtlasTexture.new()
	var _frame := 0
	var _clock := 0.0
	static var _silhouette: ShaderMaterial

	# A form not unlocked this run (run_design.md "Not unlocked = a silhouette on a lit backdrop"): a flat dark
	# silhouette; FormNode draws the pale moonlit disc behind it so it still reads.
	static func silhouette_material() -> ShaderMaterial:
		if _silhouette == null:
			var shader := Shader.new()
			shader.code = """shader_type canvas_item;
uniform vec4 ink : source_color;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	COLOR = vec4(ink.rgb, c.a * COLOR.a);
}
"""
			_silhouette = ShaderMaterial.new()
			_silhouette.shader = shader
			_silhouette.set_shader_parameter("ink", Palette.DREAD)
		return _silhouette

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
			_atlas.region = _crop()
			texture = _atlas
		if silhouette:  # Not unlocked this run: a dark silhouette (FormNode draws the moonlit disc behind it)
			material = silhouette_material()

	# An Ascended form (tier 4) is taller than 64 px: its whole frame, crown and all, scaled into the
	# disc like the others (screens_ui.md "Playtest fixes"); the rest show their bottom 64 px.
	func _crop() -> Rect2:
		return data.get_frame_rect(0) if data.tier >= DreamState.ASCENDED_TIER else WardenIcon.region(data)

	func _process(delta: float) -> void:
		if data.texture == null or data.frame_count <= 1:
			return
		_clock += CardScene.real_delta(delta)  # Real time at any game speed
		if _clock < FRAME_TIME:
			return
		_clock = 0.0
		_frame = (_frame + 1) % data.frame_count
		var crop := _crop()
		var offset := data.get_frame_rect(_frame).position - data.get_frame_rect(0).position
		_atlas.region = Rect2(crop.position + offset, crop.size)
