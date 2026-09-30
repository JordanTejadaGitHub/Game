extends PanelContainer
class_name LoadoutPanel

# "Carry into the dream" (meta_design.md, Section 1: Perks): the perk loadout. Slots 1–3 are open
# from the start, the Perks limb grows 4–5, and a secret 6th appears with "The Heartwood in full bloom";
# every owned perk is listed and a tap carries it or puts
# it back. A perk with levels is carried at its highest owned level. The loadout is saved in the
# profile and kept between runs. Opened by Start run (then its button starts the run) or by tapping
# the waystones at the Heartwood's roots.

signal closed(start: bool)  # start = the player pressed Start run

const SLOTS_TEXTURE := preload("res://assets/meta/ui/loadout_slots.png")
const SLOT_6_TEXTURE := preload("res://assets/meta/ui/loadout_slot_6.png")  # The secret 6th
const SLOT := 64
const MAX_SLOTS := 5

var starting := false  # Opened by Start run
var _memory: Dictionary = {}
var _carried: Array[String] = []
var _slots_row := HBoxContainer.new()
var _perks := GridContainer.new()
var _hint := Label.new()
var _go := Button.new()
var _tree: GroveTreeView

func _init(tree_view: GroveTreeView) -> void:
	_tree = tree_view
	visible = false
	custom_minimum_size = Vector2(560, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.08, 0.06, 0.96)
	style.border_color = Color(0.95, 0.8, 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(16)
	add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var title := Label.new()
	title.text = "Carry into the dream"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55))
	box.add_child(title)
	_slots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_slots_row.add_theme_constant_override("separation", 8)
	box.add_child(_slots_row)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_color_override("font_color", Color(0.8, 0.78, 0.7))
	box.add_child(_hint)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 260)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_perks.columns = 2
	_perks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_perks.add_theme_constant_override("h_separation", 8)
	_perks.add_theme_constant_override("v_separation", 6)
	scroll.add_child(_perks)
	box.add_child(scroll)
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 12)
	box.add_child(footer)
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(140, 48)
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(close.bind(false))
	footer.add_child(back)
	_go.custom_minimum_size = Vector2(160, 48)
	_go.focus_mode = Control.FOCUS_NONE
	_go.pressed.connect(func() -> void: close(starting))
	footer.add_child(_go)

func open(memory: Dictionary, start_run: bool) -> void:
	_memory = memory
	starting = start_run
	_carried = HeartwoodMemory.get_loadout(memory)
	_go.text = "Start run" if start_run else "Done"
	_rebuild()
	visible = true

func close(start: bool) -> void:
	visible = false
	closed.emit(start)

func get_carried() -> Array[String]:
	return _carried

# Carries `id` in the first free slot, or puts it back if it's carried. Saves the loadout.
func toggle(id: String) -> void:
	if _carried.has(id):
		_carried.erase(id)
	elif _carried.size() < HeartwoodMemory.loadout_slots(_memory):
		_carried.append(id)
	else:
		return
	HeartwoodMemory.save_loadout(_carried)
	_memory = HeartwoodMemory.load_data()
	_rebuild()

func _owned_perks() -> Array[UnlockData]:
	var result: Array[UnlockData] = []
	for unlock in HeartwoodMemory.load_grove():
		if unlock.is_perk() and HeartwoodMemory.node_level(_memory, unlock) > 0:
			result.append(unlock)
	return result

func _rebuild() -> void:
	for child in _slots_row.get_children():
		child.queue_free()
	for child in _perks.get_children():
		child.queue_free()
	var slots := HeartwoodMemory.loadout_slots(_memory)
	var sixth := HeartwoodMemory.has_sixth_slot(_memory)
	var normal := slots - (1 if sixth else 0)  # Slots 1–5 (3 open, 4–5 grown on the Perks limb)
	for i in MAX_SLOTS:
		_slots_row.add_child(_slot(i, i < normal, i if i < normal else -1, false))
	if sixth:  # The secret 6th ("The Heartwood in full bloom"): never shown before it has risen
		_slots_row.add_child(_slot(MAX_SLOTS, true, normal, true))
	var owned := _owned_perks()
	if owned.is_empty():
		_hint.text = "Plant perks on the Perks limb to carry them."
	elif _carried.size() >= slots:
		_hint.text = "Every slot is full"
	else:
		_hint.text = "Carrying %d of %d" % [_carried.size(), slots]
	for unlock in owned:
		_perks.add_child(_perk_button(unlock))

# One slot at position `index`: `open` or sealed; `carried_index` is which carried perk sits in it (-1 =
# none); `sixth` = the secret slot's own art (loadout_slot_6.png: 0 empty, 1 filled).
func _slot(index: int, open: bool, carried_index: int, sixth: bool) -> Control:
	var button := Button.new()
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(SLOT, SLOT)
	var filled := carried_index >= 0 and carried_index < _carried.size()
	var atlas := AtlasTexture.new()
	atlas.atlas = SLOT_6_TEXTURE if sixth else SLOTS_TEXTURE
	var frame := (1 if filled else 0) if sixth else (0 if not open else (2 if filled else 1))
	atlas.region = Rect2(frame * SLOT, 0, SLOT, SLOT)
	var art := TextureRect.new()
	art.texture = atlas
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_child(art)
	if filled:
		var unlock := HeartwoodMemory.get_unlock(_carried[carried_index])
		var icon := TextureRect.new()
		icon.texture = _tree.get_icon(unlock)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.position = Vector2(16, 16)
		icon.size = Vector2(32, 32)
		button.add_child(icon)
		button.tooltip_text = unlock.display_name
		button.pressed.connect(toggle.bind(unlock.id))
	elif not open:
		button.tooltip_text = "Loadout slot %d grows on the Perks limb" % (index + 1)
	return button

func _perk_button(unlock: UnlockData) -> Button:
	var level := HeartwoodMemory.node_level(_memory, unlock)
	var carried := _carried.has(unlock.id)
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.toggle_mode = true
	button.button_pressed = carried
	button.custom_minimum_size = Vector2(260, 64)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 13)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.icon = _tree.get_icon(unlock)
	button.expand_icon = false
	var roman := ["", " I", " II", " III"]
	var level_text: String = roman[level] if unlock.get_levels() > 1 and level < roman.size() else ""
	button.text = "%s%s\n%s" % [unlock.display_name, level_text, IconInfo.format(unlock.description)]  # No hover needed (touch)
	button.disabled = not carried and _carried.size() >= HeartwoodMemory.loadout_slots(_memory)
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.88, 0.5))
	button.pressed.connect(toggle.bind(unlock.id))
	return button
