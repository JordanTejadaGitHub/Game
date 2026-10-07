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
const NAME_MIN_SIZE := 11  # A long name shrinks to this, then wraps onto two lines
const NAME_FLOOR_SIZE := 9  # …and a still-too-wide line shrinks down to this (never cut)
const EMBLEM_BADGE := 20.0  # A branch emblem badge on a tree node (BranchEmblem, when UI Asset's art exists)
const PORTRAIT := 56.0
const PORTRAIT_NUDGE := 6.0  # The Warden sits this much below the disc's centre, its plinth low (UI Asset)
const TREE_SIZE := Vector2(560, 380)  # Shorter for the "Not in this dream" strip under it and the offer line above (fits 1280×800)
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
var _tabs: Container = HFlowContainer.new()  # Wraps to a second row with every family (it ran off the side at the largest UI size); phones: one swiping row
var _body: BoxContainer
var _canvas: TreeCanvas
var _side := PanelContainer.new()
var _side_box := VBoxContainer.new()
var _misty := VBoxContainer.new()  # "Not in this dream": the family's branches not offered this run
var _offer_line := Label.new()  # "This dream offers 2 of 5 branches, different each run. …"
var _dev_free := CheckButton.new()  # "Dev: unlock free" (dev runs of debug builds)

func _ready() -> void:
	WorldLabel.cover_while_visible(self, &"remember_screen")  # No world tags (DPS, hover names) over a full-screen screen
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if phone_layout():
		_build_phone()
		return
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
	_offer_line.name = "OfferLine"  # Branch expansion: the branches are random each run (story chat, user)
	_offer_line.add_theme_color_override("font_color", UiStyle.INK)
	box.add_child(_offer_line)

	_tabs.add_theme_constant_override("h_separation", 6)
	_tabs.add_theme_constant_override("v_separation", 6)
	_tabs.custom_minimum_size.x = TREE_SIZE.x + SIDE_WIDTH + 14.0  # Wraps at the panel's width
	box.add_child(_tabs)
	_frame = frame
	_middle.name = "Middle"
	_middle.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(_middle)
	_middle_box.add_theme_constant_override("separation", 10)
	_middle_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_middle.add_child(_middle_box)
	_middle_box.minimum_size_changed.connect(_fit_middle, CONNECT_DEFERRED)
	get_viewport().size_changed.connect(_fit_middle, CONNECT_DEFERRED)
	visibility_changed.connect(_fit_middle, CONNECT_DEFERRED)
	_body = HBoxContainer.new()
	_body.add_theme_constant_override("separation", 14)
	_middle_box.add_child(_body)
	_canvas = TreeCanvas.new(self)
	_body.add_child(_canvas)
	_side.add_theme_stylebox_override("panel", UiStyle.panel_in(UiStyle.GOLD, 12, 12))
	_side.custom_minimum_size = Vector2(SIDE_WIDTH, 0)
	_side_box.add_theme_constant_override("separation", 6)
	_side.add_child(_side_box)
	_body.add_child(_side)
	_misty.name = "NotInDream"  # Branch expansion: this family's branches not in this run, apart from the tree
	_misty.add_theme_constant_override("separation", 4)
	_middle_box.add_child(_misty)

	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 12)
	box.add_child(footer)
	var done := Button.new()
	done.text = "Done"
	done.focus_mode = Control.FOCUS_NONE
	done.custom_minimum_size = Vector2(160, 48)
	done.pressed.connect(close)
	# A framed secondary (user: "why are all the buttons different?"); Peek stays quiet (a utility); Unlock is the primary
	footer.add_child(done)
	_dev_free.text = "Dev: unlock free"
	_dev_free.focus_mode = Control.FOCUS_NONE
	_dev_free.toggled.connect(func(_on: bool) -> void: _fill_side(selected))
	footer.add_child(_dev_free)
	peek = ChoicePeek.new(self, [dim, center], "Back to Remember")
	var peek_button := peek.make_peek_button()
	if peek_button is Button:
		UiStyle.quiet(peek_button)
	footer.add_child(peek_button)
	visible = false
	_connect_dream_state()

func _connect_dream_state() -> void:
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
	_dev_free.visible = DreamState.dev_tools_on() and not CaptureDirector.capturing()  # Never in marketing captures
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

# --- Phones ---------------------------------------------------------------------------------------------

# mobile_plan.md "Phone layouts" (Mobile chat; user 2026-10-06: "the remember tech tree needs a new mobile rework"):
# full screen instead of a floating panel. One top bar (Remember, Dreamlight, ?, Peek, Done), the families as one
# row of tabs that swipes, then the tree (scaled to the room left) beside the detail panel, which scrolls on its own
# and keeps its Unlock / Call in button pinned at its bottom right, under the thumb. The offer line and the "Not in
# this dream" explanation move into the ? tip (tooltips don't exist on touch). Mobile only: PC keeps its panel.
const PHONE_MARGIN := 16.0
const PHONE_TITLE_SIZE := 26
const PHONE_SIDE_SHARE := 0.4  # Of the screen's width
const PHONE_SIDE_MIN := 320.0
const PHONE_SIDE_MAX := 480.0
const PHONE_TREE_SCALE_MIN := 0.8  # Tree nodes stay at least ~60 px
const PHONE_TREE_SCALE_MAX := 1.4
const PHONE_TAB_H := 56.0
const PHONE_ACTION_H := 56.0
const PHONE_TEXT_BUMP := 2  # Panel text a little larger on a phone

var _action_box: VBoxContainer = null  # Phones: the panel's button, under its scroll
var _tree_holder: Control = null
var _margin: MarginContainer = null
var _side_scroll: ScrollContainer = null
var _info_tip: TapTip = null

# The phone layout: Android / iOS builds (and TouchBuild.force_mobile / `-- --mobile` for testing on a PC).
static func phone_layout() -> bool:
	return TouchBuild.mobile_controls()

func _phone_bump() -> int:
	return PHONE_TEXT_BUMP if phone_layout() else 0

# How wide the detail panel's text wraps.
func _text_width() -> float:
	if not phone_layout():
		return SIDE_WIDTH - 30
	return maxf(_side.custom_minimum_size.x - 44.0, 200.0)

func _build_phone() -> void:
	var dim := ColorRect.new()
	dim.color = Color(UiStyle.FOG, 0.94)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_margin = MarginContainer.new()
	_margin.name = "PhoneMargin"
	_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_margin)
	var frame := PanelContainer.new()
	var frame_style := UiStyle.panel(14, 10)
	frame_style.edge_alpha = ChoiceCard.EDGE_ALPHA
	frame_style.center_alpha = ChoiceCard.CENTER_ALPHA
	frame.add_theme_stylebox_override("panel", frame_style)
	_margin.add_child(frame)
	_frame = frame
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	frame.add_child(box)

	# The top bar: Remember, Dreamlight, ?, then Peek and Done at the right
	var bar := HBoxContainer.new()
	bar.name = "TopBar"
	bar.add_theme_constant_override("separation", 14)
	box.add_child(bar)
	UiStyle.title(_title, PHONE_TITLE_SIZE, HEADER_COLOR)
	_title.text = "Remember"
	_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(_title)
	UiStyle.number(_light_line, 22)
	_light_line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_child(_light_line)
	var info := Button.new()
	info.name = "InfoButton"
	info.text = "?"
	info.focus_mode = Control.FOCUS_NONE
	info.custom_minimum_size = Vector2(48, 48)
	UiStyle.quiet(info)
	bar.add_child(info)
	_info_tip = TapTip.attach(info, "Dreamlight unlocks, Dew grows.")
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)
	_dev_free.text = "Dev: unlock free"
	_dev_free.focus_mode = Control.FOCUS_NONE
	_dev_free.toggled.connect(func(_on: bool) -> void: _fill_side(selected))
	bar.add_child(_dev_free)
	peek = ChoicePeek.new(self, [dim, _margin], "Back to Remember")
	var peek_button := peek.make_peek_button()
	if peek_button is Button:
		UiStyle.quiet(peek_button)
	bar.add_child(peek_button)
	var done := Button.new()
	done.name = "DoneButton"
	done.text = "Done"
	done.focus_mode = Control.FOCUS_NONE
	done.custom_minimum_size = Vector2(120, 48)
	done.pressed.connect(close)
	bar.add_child(done)

	# The families: one row that swipes sideways
	var tab_scroll := ScrollContainer.new()
	tab_scroll.name = "TabScroll"
	tab_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tab_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	tab_scroll.custom_minimum_size.y = PHONE_TAB_H
	box.add_child(tab_scroll)
	_tabs.free()  # The PC's wrapping tabs, never in the tree here
	_tabs = HBoxContainer.new()
	_tabs.name = "Tabs"
	_tabs.add_theme_constant_override("separation", 8)
	tab_scroll.add_child(_tabs)
	_offer_line.name = "OfferLine"
	_offer_line.visible = false  # In the ? tip on phones
	box.add_child(_offer_line)

	# The body: the tree (and "Not in this dream" under it) beside the detail panel
	_body = HBoxContainer.new()
	_body.add_theme_constant_override("separation", 12)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_body)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	_body.add_child(left)
	_tree_holder = Control.new()
	_tree_holder.name = "TreeHolder"
	_tree_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tree_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree_holder.custom_minimum_size = TREE_SIZE * PHONE_TREE_SCALE_MIN
	_tree_holder.mouse_filter = Control.MOUSE_FILTER_PASS
	left.add_child(_tree_holder)
	_canvas = TreeCanvas.new(self)
	_tree_holder.add_child(_canvas)
	_tree_holder.resized.connect(_fit_tree)
	var misty_scroll := ScrollContainer.new()
	misty_scroll.name = "MistyScroll"
	misty_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	misty_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	left.add_child(misty_scroll)
	_misty.name = "NotInDream"
	_misty.add_theme_constant_override("separation", 4)
	misty_scroll.add_child(_misty)
	_misty.minimum_size_changed.connect(_fit_misty_scroll.bind(misty_scroll))
	_misty.visibility_changed.connect(_fit_misty_scroll.bind(misty_scroll))

	_side.add_theme_stylebox_override("panel", UiStyle.panel_in(UiStyle.GOLD, 12, 12))
	_side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_side.add_child(column)
	_side_scroll = ScrollContainer.new()
	_side_scroll.name = "SideScroll"
	_side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_side_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(_side_scroll)
	_side_box.add_theme_constant_override("separation", 6)
	_side_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_side_scroll.add_child(_side_box)
	_action_box = VBoxContainer.new()
	_action_box.name = "ActionBox"
	column.add_child(_action_box)
	_body.add_child(_side)

	visible = false
	_middle_box.free()  # The PC layout's scrolling middle: unused on phones
	_middle.free()
	get_viewport().size_changed.connect(_fit_phone, CONNECT_DEFERRED)
	_connect_dream_state()

# The strip's scroll is as tall as the strip (a ScrollContainer doesn't grow with its content by itself), 0 when hidden.
func _fit_misty_scroll(scroll: ScrollContainer) -> void:
	scroll.custom_minimum_size.y = _misty.get_combined_minimum_size().y if _misty.visible else 0.0

# The margins (the notch and rounded corners on a phone) and the detail panel's width for this screen.
func _fit_phone() -> void:
	if _margin == null or not is_inside_tree():
		return
	var view := get_viewport_rect().size
	var inset := _safe_insets(view)
	_margin.add_theme_constant_override("margin_left", int(PHONE_MARGIN + inset.position.x))
	_margin.add_theme_constant_override("margin_top", int(PHONE_MARGIN + inset.position.y))
	_margin.add_theme_constant_override("margin_right", int(PHONE_MARGIN + inset.size.x))
	_margin.add_theme_constant_override("margin_bottom", int(PHONE_MARGIN + inset.size.y))
	_side.custom_minimum_size.x = clampf(view.x * PHONE_SIDE_SHARE, PHONE_SIDE_MIN, PHONE_SIDE_MAX)
	_fit_tree()

# The screen's unsafe edges in view units: left / top in `position`, right / bottom in `size`. Only on a real phone.
func _safe_insets(view: Vector2) -> Rect2:
	if not OS.has_feature("mobile"):
		return Rect2()
	var screen := Vector2(DisplayServer.screen_get_size())
	var safe := DisplayServer.get_display_safe_area()
	if screen.x <= 0.0 or safe.size.x <= 0:
		return Rect2()
	var k := view.x / screen.x
	return Rect2(Vector2(safe.position) * k, (screen - Vector2(safe.end)) * k)

# The tree scales to the room beside the panel (never so small its nodes drop under ~60 px), centred.
func _fit_tree() -> void:
	if _tree_holder == null:
		return
	var room := _tree_holder.size
	var s := clampf(minf(room.x / TREE_SIZE.x, room.y / TREE_SIZE.y), PHONE_TREE_SCALE_MIN, PHONE_TREE_SCALE_MAX)
	_canvas.scale = Vector2(s, s)
	_canvas.position = ((room - TREE_SIZE * s) / 2.0).max(Vector2.ZERO)

# Phones: the panel's Unlock / Call in button leaves the scroll and sits at the panel's foot, full width.
func _pin_action() -> void:
	for button_name in ["UnlockButton", "CallBackButton", "DevUnlockButton"]:
		var button := _side_box.find_child(button_name, false, false) as Button
		if button == null:
			continue
		_side_box.remove_child(button)
		button.custom_minimum_size.y = PHONE_ACTION_H
		_action_box.add_child(button)

# The ? tip: this family's offer line, what Dreamlight and Dew do, and why some branches are missing.
func _update_info(root: TowerData) -> void:
	if _info_tip == null:
		return
	var parts: Array[String] = ["Dreamlight unlocks, Dew grows."]
	var offer := offer_line(root)
	if offer != "":
		parts.push_front(offer)
	if root != null and root.tier == 1 and not dream_state.not_offered_branches(root).is_empty():
		parts.append(MISTY_TIP)
	var text := "\n\n".join(parts)
	_info_tip._label.text = text
	(_info_tip.get_parent() as Control).tooltip_text = text

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
	_offer_line.text = offer_line(shown[0])
	_offer_line.visible = _offer_line.text != "" and not phone_layout()  # Phones: in the ? tip
	if phone_layout():
		_update_info(shown[0])

# The line above the tree (user: players should be told the branches are random): "This dream offers 2 of 5
# branches, different each run. Call others in with Dreamlight." ("" outside the branch expansion, or for a family
# offering all it has). "Branches", not "paths": a path is the maze's route (text_style.md).
func offer_line(root: TowerData) -> String:
	if root == null or root.tier != 1 or dream_state.not_offered_branches(root).is_empty():
		return ""
	return "This dream offers %d of %d branches, different each run. Call others in with Dreamlight." % [  # As the family pick
		dream_state.branch_offer_size(root), dream_state.regular_branches(root).size()]

const MISTY_TIP := "Each run the dream offers only some of a family's branches, at random. These weren't drawn this time: call one in for Dreamlight (once per family), or find the Borrowed Branch card. The Heartwood may offer them next run."
const GROVE_HINT := "One more branch grows in the Memory Grove."

# A strip emblem's tip (user: "hovering emblems gives me repeated explanations of the branch"): this branch's name and
# what it does, never the strip's general explanation (that's on the header, once).
func branch_tip(form: TowerData) -> String:
	var does := IconInfo.format(form.description) if form.description != "" else ""
	return form.display_name + ("\n" + does if does != "" else "")

# The strip under the tree (story chat: the not-offered branches beside the base read as its siblings): each
# branch of `root`'s family not in this run, a faint silhouette with its name and "Call in · 3 Dreamlight" (once per
# family; free with Borrowed Branch; greyed after use). A tap on one shows it in the side panel too.
const MISTY_PORTRAIT := 40.0
const MISTY_EMBLEM := 32.0  # UI Asset's emblems are 32 px art (nearest)

func _fill_misty(root: TowerData) -> void:
	for child in _misty.get_children():
		_misty.remove_child(child)
		child.queue_free()
	var forms: Array[TowerData] = dream_state.not_offered_branches(root) if root.tier == 1 else ([] as Array[TowerData])
	# An unplanted hidden branch isn't a lane in the tree any more (user: "only show 2 branch options unless we unlocked
	# 3"): one line here says it exists
	var grove_left := root.tier == 1 and root.evolves_to.any(func(f) -> bool:
		return f is TowerData and f.tier == 2 and dream_state.get_unlock_blocker(f) == "Memory Grove")
	_misty.visible = not forms.is_empty() or grove_left
	var top := HBoxContainer.new()  # The header and the Grove hint share one row (the screen must fit 1280×800)
	top.add_theme_constant_override("separation", 16)
	_misty.add_child(top)
	if not forms.is_empty():
		var head := Label.new()
		head.text = "Not in this dream"
		UiStyle.caps(head, 15)
		head.add_theme_color_override("font_color", UiStyle.INK_DIM)
		head.tooltip_text = MISTY_TIP  # Hover or tap: why these aren't in the tree
		head.mouse_filter = Control.MOUSE_FILTER_PASS
		top.add_child(head)
	if grove_left:
		var grove := Label.new()
		grove.name = "GroveHint"
		grove.text = GROVE_HINT
		grove.add_theme_color_override("font_color", UiStyle.INK_DIM)
		grove.add_theme_font_size_override("font_size", 14)
		top.add_child(grove)
	if forms.is_empty():
		return
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
		look.tooltip_text = branch_tip(form)  # About this branch only: the strip's header explains "not in this dream" once
		look.draw.connect(func() -> void:  # The moonlit disc behind the silhouette (as on the tree), faint
			UiStyle.draw_moon_disc(look, look.size / 2.0, MISTY_PORTRAIT / 2.0 - 1))
		look.modulate = Color(1, 1, 1, 0.6)  # multiplier: the mist
		var portrait := Portrait.new(form, MISTY_PORTRAIT)  # The Warden itself, in the mist (user: "the look of the Warden instead of the icon")
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
		call.text = "Call in, free" if free else "Call in  %d" % dream_state.call_back_cost(root)  # The Dreamlight glyph after it (no " · ")
		if not free:
			call.icon = IconInfo.icon(&"dreamlight")
			call.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			call.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
	tab.custom_minimum_size = Vector2(0, PHONE_TAB_H if phone_layout() else 48.0)
	tab.pressed.connect(func() -> void:
		_tab_root = root
		selected = null
		_rebuild())
	return tab

# Fits the viewport at every UI scale (user, the largest UI size: Done and Peek fell off the bottom): the header and the
# footer stay; the middle (the tree, the side panel, "Not in this dream") is as tall as it can be and scrolls past that.
var _frame: PanelContainer = null
var _middle := ScrollContainer.new()
var _middle_box := VBoxContainer.new()
const VIEW_MARGIN := 24.0  # Kept free above and below the panel

func _fit_middle() -> void:
	if _frame == null or not is_inside_tree() or phone_layout():
		return  # Phones: the full-screen layout gives the middle the room itself (_fit_phone)
	var content := _middle_box.get_combined_minimum_size().y
	var rest := _frame.get_combined_minimum_size().y - _middle.custom_minimum_size.y  # Header, tabs, footer, padding
	var room := get_viewport_rect().size.y - VIEW_MARGIN * 2.0 - rest
	var height := clampf(room, 120.0, content)
	if not is_equal_approx(_middle.custom_minimum_size.y, height):
		_middle.custom_minimum_size.y = height

# Phones: the side panel goes under the tree (and slides up on selecting) instead of beside it.
func _layout_for_screen() -> void:
	if phone_layout():
		_fit_phone()  # Landscape phones: tree and detail panel side by side, always
		return
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
	if _action_box != null:
		for child in _action_box.get_children():
			_action_box.remove_child(child)
			child.queue_free()
	_fill_side_content(data)
	if _action_box != null:
		_pin_action()

func _fill_side_content(data: TowerData) -> void:
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
	_header_names(head, data)
	_description_and_stats(data)
	var statuses: Array[String] = []
	for status in [data.applies_status, data.extra_status]:
		if status != &"":
			statuses.append(IconInfo.status_name(status))
	if not statuses.is_empty():
		_line("Applies " + " and ".join(statuses), STATUS_LINE_COLOR, 14)
	_line(WardenHeaderView.shape_tip(data), UiStyle.INK_DIM, 14).name = "AttackShape"  # How it attacks (aura or not)
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

# The header beside the portrait (the Warden panel's): the name, then its form and damage type stacked under it.
func _header_names(head: HBoxContainer, data: TowerData) -> void:
	var names := VBoxContainer.new()
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(names)
	var name_label := Label.new()
	name_label.text = data.display_name
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiStyle.display(name_label, 22)
	names.add_child(name_label)
	var kind := HBoxContainer.new()
	kind.add_theme_constant_override("separation", 10)  # Two words, no " · " (light pass)
	names.add_child(kind)
	var tier := Label.new()
	tier.text = _tier_name(data)
	tier.add_theme_color_override("font_color", UiStyle.INK_DIM)
	kind.add_child(tier)
	var damage_kind := Label.new()
	damage_kind.text = "%s damage" % IconInfo.damage_type_name(data.line)  # No icon (user): the damage type in its colour
	damage_kind.add_theme_color_override("font_color", IconInfo.damage_type_color(data.line))
	kind.add_child(damage_kind)

# What it does (linked) and its stats as one icon row, as the Warden panel (light pass).
func _description_and_stats(data: TowerData) -> void:
	if data.description != "":
		var what := StatusLinks.make_label(data.description, 15 + _phone_bump(), UiStyle.INK)
		what.custom_minimum_size = Vector2(_text_width(), 0)
		_side_box.add_child(what)
	if data.can_attack:
		var stats: Array = [[&"damage", str(data.damage)], [&"attack_speed", "%.1f/s" % data.attacks_per_second],
			[&"range", "%.1f" % data.attack_range]]
		if data.potency != 1.0:
			stats.append([&"potency", "%d%%" % roundi(data.potency * 100)])
		_side_box.add_child(_icon_stats(stats))

# Stats as icons with their values (the Warden panel's row): [[icon id, value], …]; each icon's tip names it.
func _icon_stats(stats: Array) -> HFlowContainer:
	var row := HFlowContainer.new()
	row.name = "Stats"
	row.add_theme_constant_override("h_separation", 14)
	for stat in stats:
		var pair := HBoxContainer.new()
		pair.add_theme_constant_override("separation", 3)
		var icon := TextureRect.new()
		icon.texture = IconInfo.icon(stat[0])
		icon.custom_minimum_size = Vector2(16, 16)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		pair.add_child(icon)
		var value := Label.new()
		value.name = "Value_%s" % stat[0]
		value.text = stat[1]
		value.add_theme_font_size_override("font_size", 14)
		pair.add_child(value)
		pair.tooltip_text = IconInfo.stat_tooltip(stat[0])
		pair.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_child(pair)
	return row

func _line(text: String, colour: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(_text_width(), 0)
	label.add_theme_color_override("font_color", colour)
	label.add_theme_font_size_override("font_size", font_size + _phone_bump())
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
	links.custom_minimum_size = Vector2(_text_width(), 0)
	_side_box.add_child(links)

# Branch expansion: a branch not in this run. Its silhouette and name, the line, what it does (to judge a call),
# and the call-back: CALL_BACK_DREAMLIGHT once per family, or free with Borrowed Branch.
const NOT_IN_DREAM_LINE := "Not in this dream. The Heartwood may remember it next time."

func _fill_not_in_dream(data: TowerData) -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	_side_box.add_child(head)
	# Known and callable (user, Inkcap: "fix"): its real sprite, centred by its drawn pixels, and the Warden panel's
	# header, description and stats, so it can be judged before spending Dreamlight. Silhouettes stay for Grove-locked forms.
	head.add_child(Portrait.new(data, 72.0, false))
	_header_names(head, data)
	_line(NOT_IN_DREAM_LINE, UiStyle.INK_DIM, 14)
	_description_and_stats(data)
	_add_call_back(data)

func _add_call_back(data: TowerData) -> void:
	var button := Button.new()
	button.name = "CallBackButton"
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 48)
	var free := dream_state.free_calls > 0
	var problem := dream_state.call_back_problem(data)
	var cost := dream_state.call_back_cost(dream_state._parent_in_tree(data))  # 3; Wider Roots' family 4
	UiStyle.primary(button)
	var gap := Control.new()  # The text never touches the primary's thread (user, Inkcap)
	gap.custom_minimum_size.y = 12
	_side_box.add_child(gap)
	_side_box.add_child(button)
	var short := problem == "Not enough Dreamlight"
	# "Call into this dream", then [Dreamlight] 3 at the right in GOLD, POOR when short (no " · "; user, Inkcap)
	button.text = "Call into this dream, free (Borrowed Branch)" if free else "Call into this dream"
	if not free:
		_cost_on(button, cost, short)
	if short:  # Dimmed, a press refuses (as Unlock)
		for state in ["font_color", "font_hover_color", "font_pressed_color"]:
			button.add_theme_color_override(state, UiStyle.INK_DIM)
		button.set_meta(&"cant_afford", true)  # CantAfford.is_shown
		button.tooltip_text = IconInfo.format(SHORT_TIP)
		button.pressed.connect(_refuse_call_back.bind(button, cost))
		return
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

# The Dreamlight price at a button's right: the glyph and the number, GOLD or POOR; the label keeps clear of it.
func _cost_on(button: Button, cost: int, short: bool) -> void:
	var price := HBoxContainer.new()
	price.name = "Cost"
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price.add_theme_constant_override("separation", 3)
	price.anchor_left = 1.0  # The button's full height at its right edge, the glyph and number centred in it
	price.anchor_right = 1.0
	price.anchor_top = 0.0
	price.anchor_bottom = 1.0
	price.offset_top = 0
	price.offset_bottom = 0
	price.offset_right = -14
	price.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var glyph := TextureRect.new()
	glyph.texture = IconInfo.icon(&"dreamlight")
	glyph.custom_minimum_size = Vector2(16, 16)
	glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glyph.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glyph.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price.add_child(glyph)
	var number := Label.new()
	number.name = "Amount"
	number.text = str(cost)
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiStyle.number(number, 18, UiStyle.POOR if short else UiStyle.GOLD)
	price.add_child(number)
	button.add_child(price)

func _refuse_call_back(button: Button, cost: int) -> void:
	CantAfford.shake(button)
	var hud := get_parent()
	if hud != null and hud.has_method("show_toast"):
		hud.show_toast("Not enough Dreamlight")
	dream_state.dreamlight_short.emit(cost)

func _add_unlock(data: TowerData) -> void:
	var cost := dream_state.get_unlock_cost(data)
	if cost == 0:
		return
	if _dev_free.button_pressed and not data.buildable_directly:
		var free := Button.new()
		free.name = "DevUnlockButton"
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
	# The one detail-panel button (user, Bramble: "Dreamlight is not centred"; as Call into this dream, b5735f56): 12 px
	# under the text, "Unlock" centred, the Dreamlight glyph and its cost at the right in GOLD, POOR when short; no " · ".
	var gap := Control.new()
	gap.custom_minimum_size.y = 12
	_side_box.add_child(gap)
	var button := Button.new()
	button.name = "UnlockButton"
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 48)
	var price := dream_state.get_unlock_price(data)  # Waking Root (Heartwood's Gifts): 1 less, once
	var short := price - dream_state.dreamlight  # > 0: can't afford
	button.disabled = blocker != ""  # Locked for another reason: a plain disabled button (the line says why)
	UiStyle.primary(button)
	_side_box.add_child(button)
	button.text = "Unlock" if price > 0 else "Unlock, free"
	if price > 0:
		_cost_on(button, price, blocker == "" and short > 0)
	if price < cost:
		button.tooltip_text = "Waking Root: 1 Dreamlight less, once."
	if blocker == "" and short > 0:  # Can't afford yet: dimmed, the cost in POOR, no count (user); a press refuses
		for state in ["font_color", "font_hover_color", "font_pressed_color"]:
			button.add_theme_color_override(state, UiStyle.INK_DIM)
		button.set_meta(&"cant_afford", true)  # CantAfford.is_shown
		button.tooltip_text = IconInfo.format(SHORT_TIP)
		button.pressed.connect(_refuse_unlock.bind(data, button))
	else:
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
	if _side_scroll != null:
		_side_scroll.scroll_vertical = 0  # Phones: a new form's details start at the top
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
				continue  # Not planted: no phantom 3rd lane (user: "only show 2 unless we unlocked 3"); the strip hints at it
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
			if screen.is_veiled(edge[1]):  # To a shadow: 1 px of Mist, not the path
				draw_line(a, b, Color(UiStyle.MOON_MIST, 0.16), 1.0, true)
				continue
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
		var veiled := screen.is_veiled(data)
		portrait = Portrait.new(data, PORTRAIT, state == State.GROVE or state == State.NOT_IN_DREAM or veiled)  # Silhouettes: not planted, not in this dream, or not revealed yet
		if state != State.GROVE and not RememberScreen.is_unlocked_state(state):
			portrait.modulate = Color.WHITE.darkened(0.2)  # Grove-available, not unlocked this run: its real colours, ~80%
		portrait.position = Vector2((NODE_SIZE.x - PORTRAIT) / 2.0, 4 + PORTRAIT_NUDGE)  # The plinth a little below centre
		add_child(portrait)
		var emblem := BranchEmblem.texture(data) if data.tier >= 2 and not screen.is_veiled(data) and state != State.GROVE else null  # Never on an unknown (???) form
		if emblem != null:  # A small branch badge on the portrait's shoulder (the portrait stays: story chat)
			var badge := TextureRect.new()
			badge.name = "Emblem"
			badge.texture = emblem
			badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			badge.size = Vector2(EMBLEM_BADGE, EMBLEM_BADGE)
			badge.position = Vector2((NODE_SIZE.x + PORTRAIT) / 2.0 - EMBLEM_BADGE + 2, 2)
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(badge)
		tooltip_text = UNKNOWN_NAME + " · Plant it in the Memory Grove" if state == State.GROVE else data.display_name  # Grove-locked: no name (user), the hint
		if state != State.GROVE and data.tier == 2 and screen.dream_state.is_hidden_branch(data):
			tooltip_text = data.display_name + " · from your Memory Grove: in every dream, beside the branches drawn"
		if state == State.NOT_IN_DREAM:  # Branch expansion: a faint, misty silhouette
			modulate = Color(1, 1, 1, 0.5)  # multiplier: the mist
			tooltip_text = data.display_name + " · not in this dream"
		if veiled:  # A final not revealed yet: its dark silhouette only (user: "show the silhouette still"): no name, cost or button
			portrait.modulate = Color(1, 1, 1, 0.85)  # multiplier: the shadow at .85
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
		if screen.is_veiled(data):  # Not revealed yet: the disc at ~62% (UI Asset's Remember mock v4)
			draw_circle(centre, PORTRAIT / 2.0 - 1, Color(Palette.VOID, 0.25))  # ~75%: the shadow still reads as a Warden
		if screen.selected == data:
			draw_arc(centre, PORTRAIT / 2.0 + 3, 0.0, TAU, 40, UiStyle.GOLD, 2.0, true)
		if screen.is_veiled(data):  # Not revealed yet: only its shadow, no name, cost or glow
			return
		if state == State.CAN_UNLOCK:
			var glow := 0.35 + 0.25 * sin(_pulse * 3.0)
			draw_arc(centre, PORTRAIT / 2.0 + 1, 0.0, TAU, 40, Color(UiStyle.GOLD, glow), 3.0, true)
		var text := ""
		var colour := UiStyle.INK
		match state:
			State.GROWN:  # Its name in gold (yours this run) above how many stand on the map
				_caption(data.display_name, UiStyle.body_font(), NAME_SIZE, UiStyle.GOLD, NODE_SIZE.y - 19, 1)  # One line: the count sits under it
				text = "×%d" % screen.count_on_map(data)
			State.UNLOCKED:  # Its name in gold: unlocked this run, none planted yet
				_caption(data.display_name, UiStyle.body_font(), NAME_SIZE, UiStyle.GOLD, NODE_SIZE.y - 6)
			State.CAN_UNLOCK, State.NEEDS_LIGHT:
				_caption(data.display_name, UiStyle.body_font(), NAME_SIZE, UiStyle.INK_DIM, NODE_SIZE.y - 19, 1)  # Its name above the motes, one line
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
		if state != State.GROVE and data.tier == 2 and screen.dream_state.is_hidden_branch(data):
			# A planted hidden branch: the Grove's own lane, outside the 2 drawn (user: it read as one of the chosen)
			_draw_leaf(centre + Vector2(-PORTRAIT / 2.0 + 8, -PORTRAIT / 2.0 + 8))
		if text != "":
			# Counts and motes in the number face; names in the body font, readable (story chat: small caps were tiny)
			var words := state == State.LOCKED or state == State.GROVE or state == State.NOT_IN_DREAM
			var font := UiStyle.body_font() if words else UiStyle.number_font()
			var font_size := NAME_SIZE if words else 16
			_caption(text, font, font_size, colour, NODE_SIZE.y - 6)

	# The name this node shows: "???" for a form the Memory Grove hasn't planted (user), else its own.
	func name_shown() -> String:
		return UNKNOWN_NAME if screen.state_of(data) == State.GROVE else data.display_name

	# A name under the portrait, centred and inside the node, never cut (story chat: "Hummingbird …" was): it shrinks to
	# NAME_MIN_SIZE, then wraps onto two lines at the space nearest its middle (the first line above `baseline`), then
	# shrinks further (to NAME_FLOOR_SIZE) if a line is still too wide.
	func _caption(text: String, font: Font, font_size: int, colour: Color, baseline: float, max_lines: int = 2) -> void:
		var room := NODE_SIZE.x - 4
		var fits := func(line: String, size_px: int) -> bool: return font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x <= room
		while font_size > NAME_MIN_SIZE and not fits.call(text, font_size):
			font_size -= 1
		var lines: Array[String] = [text]
		if max_lines > 1 and not fits.call(text, font_size) and text.contains(" "):
			var best := -1
			for i in text.length():  # The space nearest the middle
				if text[i] == " " and (best < 0 or absi(i - text.length() / 2) < absi(best - text.length() / 2)):
					best = i
			lines = [text.left(best), text.substr(best + 1)]
		while font_size > NAME_FLOOR_SIZE and not lines.all(func(line: String) -> bool: return fits.call(line, font_size)):
			font_size -= 1
		for i in lines.size():
			var width := font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var y := baseline - (lines.size() - 1 - i) * (font_size + 1)
			draw_string(font, Vector2((NODE_SIZE.x - width) / 2.0, y), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, colour)


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
	const FIT_SHARE := 0.82  # The drawn art fills this much of the disc at most

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
			UiStyle.release_at_exit(func() -> void: _silhouette = null)  # Resources in a static var crash the exit (exit 139)
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
			# Inside the disc: the drawn art fits FIT_SHARE of the box (a transparent margin around it), 1:1 when it
			# already fits (never scaled up), centred either way.
			var drawn := _atlas.region.size
			var box := maxf(maxf(drawn.x, drawn.y) / FIT_SHARE, 1.0)
			_atlas.margin = Rect2((Vector2(box, box) - drawn) / 2.0, Vector2(box, box) - drawn)
			if box <= side:
				stretch_mode = TextureRect.STRETCH_KEEP_CENTERED  # Fits: 1:1, crisp
		if silhouette:  # Not unlocked this run: a dark silhouette (FormNode draws the moonlit disc behind it)
			material = silhouette_material()

	# An Ascended form (tier 4) is taller than 64 px: its whole frame, crown and all, scaled into the
	# disc like the others (screens_ui.md "Playtest fixes"); the rest show their bottom 64 px.
	func _crop() -> Rect2:
		return WardenIcon.visible_region(data)  # Centred by its drawn pixels, not its canvas (user, via UI Asset)

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
