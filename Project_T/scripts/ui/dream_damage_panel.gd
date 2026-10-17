extends PanelContainer
# Dream damage (developer, owner 2026-10-17: "a tab for developer so I can see the damage the Dreams have done for the
# block"). A small panel on the left listing each Dream card and Calling evolution with what it did: damage (its own
# share plus what it set up, DreamState card credit, setup credit 2026-10-16), else Dew, leaves saved or clears.
# Tabs: This block (since the block began), Last block (snapshot at the rest), Run. Debug builds only, shown while the
# Developer setting SETTING is on (polled, so Apply in Settings takes effect without a restart). The header folds it.
# Made by the HUD; reads only DreamState (no gameplay effect). No class_name: the HUD preloads it.

const SETTING := "dream_damage_panel"
const POLL := 0.5  # Seconds between refreshes (and setting checks)
const ROWS := 14  # Cards listed at most
const WIDTH := 300.0
const TABS: Array[Array] = [[&"block", "This block"], [&"last_block", "Last block"], [&"run", "Run"]]

var dream_state: DreamState
var _period: StringName = &"block"
var _last_block := {}  # card id -> credit row, copied when a block's rest starts
var _folded := false
var _poll := 0.0
var _body: VBoxContainer
var _list: VBoxContainer
var _total: Label
var _header: Button
var _tab_buttons := {}

func setup(state: DreamState) -> void:
	dream_state = state

func _ready() -> void:
	name = "DreamDamagePanel"
	process_mode = Node.PROCESS_MODE_ALWAYS  # Readable while paused at a rest
	visible = false
	custom_minimum_size = Vector2(WIDTH, 0.0)
	set_anchors_preset(Control.PRESET_CENTER_LEFT)
	position = Vector2(16.0, 0.0)
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	_header = Button.new()
	_header.flat = true
	_header.focus_mode = Control.FOCUS_NONE
	_header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_header.add_theme_font_size_override("font_size", 15)
	_header.pressed.connect(func() -> void:
		_folded = not _folded
		_refresh())
	box.add_child(_header)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 3)
	box.add_child(_body)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	_body.add_child(tabs)
	for tab in TABS:
		var button := Button.new()
		button.text = tab[1]
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 13)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var period: StringName = tab[0]
		button.pressed.connect(func() -> void:
			_period = period
			_refresh())
		tabs.add_child(button)
		_tab_buttons[period] = button
	_total = Label.new()
	_total.add_theme_font_size_override("font_size", 13)
	_body.add_child(_total)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 1)
	_body.add_child(_list)
	if dream_state != null and dream_state.drift_director != null:
		dream_state.drift_director.rest_started.connect(_snapshot_block.unbind(4))
	_check_setting()

func _process(delta: float) -> void:
	_poll -= delta / maxf(Engine.time_scale, 0.01)  # Real seconds, at any game speed
	if _poll > 0.0:
		return
	_poll = POLL
	_check_setting()
	if visible:
		_refresh()

func _check_setting() -> void:
	visible = TestGrove.is_available() and dream_state != null \
		and bool(HeartwoodMemory.get_settings().get(SETTING, false))

# The block just played, kept for the Last block tab (DreamState empties "block" when the next block starts).
func _snapshot_block() -> void:
	if dream_state != null:
		_last_block = dream_state.get_card_credit_table(&"block").duplicate(true)

func _refresh() -> void:
	if dream_state == null:
		return
	_header.text = "Dream damage (tap to show)" if _folded else "Dream damage (tap to hide)"
	_body.visible = not _folded
	if _folded:
		return
	for period in _tab_buttons:
		_tab_buttons[period].set_pressed_no_signal(period == _period)
	var table: Dictionary = _last_block if _period == &"last_block" else dream_state.get_card_credit_table(_period)
	var rows: Array = []
	var total_damage := 0.0
	for id in table:
		var row: Dictionary = table[id]
		var own := float(row.get("damage", 0.0))
		var setup := float(row.get("setup", 0.0))
		total_damage += own + setup
		rows.append({"id": String(id), "row": row, "damage": own + setup})
	rows.sort_custom(_sooner)
	_total.text = "All Dreams: %s damage · %d cards" % [_thousands(roundi(total_damage)), rows.size()]
	for child in _list.get_children():
		child.queue_free()
	if rows.is_empty():
		_list.add_child(_line("Nothing yet this %s." % ("run" if _period == &"run" else "block"), true))
		return
	for entry in rows.slice(0, ROWS):
		_list.add_child(_line(_row_text(entry, total_damage), false))
	if rows.size() > ROWS:
		_list.add_child(_line("…and %d more" % (rows.size() - ROWS), true))

static func _sooner(a: Dictionary, b: Dictionary) -> bool:
	if a.damage != b.damage:
		return a.damage > b.damage
	return a.id < b.id

func _row_text(entry: Dictionary, total_damage: float) -> String:
	var row: Dictionary = entry.row
	var name := _name(entry.id)
	if entry.damage > 0.0:
		var share: float = 100.0 * entry.damage / total_damage if total_damage > 0.0 else 0.0
		var text := "%s · %s (%d%%)" % [name, _thousands(roundi(entry.damage)), roundi(share)]
		if float(row.get("setup", 0.0)) > 0.0:
			text += " · set up %s" % _thousands(roundi(float(row.setup)))
		return text
	for key in ["dew", "leaves", "clears", "control", "maze"]:
		var amount := float(row.get(key, 0.0))
		if amount > 0.0:
			return "%s · %s %s" % [name, _thousands(roundi(amount)), {"dew": "Dew", "leaves": "leaves saved", "clears": "clears",
				"control": "control", "maze": "maze"}[key]]
	return "%s · nothing yet" % name

func _name(id: String) -> String:
	if DreamState.CALLING_PATHS.PATHS.has(StringName(id)):
		return String(DreamState.CALLING_PATHS.PATHS[StringName(id)].name)
	return dream_state.get_display_name(id)

func _line(text: String, dim: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 13)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(WIDTH - 24.0, 0.0)
	if dim:
		label.modulate = Color(1, 1, 1, 0.6)  # multiplier
	return label

static func _thousands(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out
