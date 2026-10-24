extends PanelContainer
class_name DreamsMeter

# What the Dreams did (user 2026-10-24, option C of https://claude.ai/artifact/UYkHaRoBUkM6AB48XPs9ZY: "split by side"):
# the Warden meter (DriftMeter) stays on the right edge, this one hangs on the left under the row of Dream icons it
# explains, in the same look. Shut, one line: "Dreams +2,740 this block"; open, This block / Last block / Run tabs and a
# row per Dream card or Calling evolution that did something (DreamState card credit: damage and set-up, else Dew,
# leaves saved, clears), most first. The fold is remembered (OPEN_SETTING). PC only: phones read the same credit on
# their Dreams page (DreamsRow) and keep one Damage button. Made by the HUD; reads only DreamState.

const WIDTH := 300.0
const GAP := 8.0  # Under the Dream icons, and clear of the Warden drawer below
const REFRESH := 0.5  # Seconds (real time)
const ROWS := 6
const HEAD_SIZE := 20  # As DriftMeter.HEAD_SIZE
const GLYPH := 16.0  # A card's glyph (8 px art at x2) in its rarity colour on a 1 px Dread outline (UI Code, art council 2026-10-24)
const COUNT_W := 40.0  # Fixed columns: "×N" right-aligned and lined up whatever the value says
const VALUE_W := 84.0
const FOOTER_GAP := 4.0  # Above the "Quiet" line
const COUNTS := {&"block": "card_counts_block", &"last_block": "card_counts_last_block", &"run": "card_counts_run"}
const OPEN_SETTING := "dreams_meter_open"
const TABS: Array[Array] = [[&"block", "Block"], [&"last_block", "Last block"], [&"run", "Run"]]
const OTHER_KEYS: Array[Array] = [["dew", "Dew"], ["leaves", "leaves saved"], ["clears", "clears"]]

var dream_state: DreamState
var _period: StringName = &"block"
var _open := false
var _clock := 0.0
var _header := Button.new()
var _body := VBoxContainer.new()
var _rows := VBoxContainer.new()
var _more := Label.new()
var _footer_gap := Control.new()
var _quiet := Label.new()  # The taken cards that neither fired nor earned credit in the period, on one dim line
var _tabs := {}

func _init(state: DreamState = null) -> void:
	dream_state = state

func _ready() -> void:
	name = "DreamsMeter"
	process_mode = Node.PROCESS_MODE_ALWAYS  # Readable while paused at a rest
	visible = false
	custom_minimum_size = Vector2(WIDTH, 0)
	add_theme_stylebox_override("panel", UiStyle.panel(10.0, 8.0))  # The Warden meter's panel
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	add_child(box)
	_header.flat = true
	_header.focus_mode = Control.FOCUS_NONE
	_header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_header.custom_minimum_size = Vector2(0, 36)
	UiStyle.number(_header, HEAD_SIZE, UiStyle.INK)
	_header.tooltip_text = "What your Dreams did. Click to open or fold."
	_header.pressed.connect(func() -> void: set_open(not _open))
	box.add_child(_header)
	_body.add_theme_constant_override("separation", 2)
	box.add_child(_body)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 2)
	for pair in TABS:
		var tab := Button.new()
		tab.text = pair[1]
		tab.toggle_mode = true
		tab.focus_mode = Control.FOCUS_NONE
		tab.custom_minimum_size = Vector2(0, 32)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.clip_text = true
		tab.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		UiStyle.caps(tab, 14, UiStyle.INK)
		tab.ready.connect(func() -> void:  # Tight side padding, as DriftMeter's tabs: the three fit the meter's WIDTH
			for state in ["normal", "hover", "pressed", "hover_pressed"]:
				var tight := tab.get_theme_stylebox(state).duplicate() as StyleBox
				tight.content_margin_left = 4.0
				tight.content_margin_right = 4.0
				tab.add_theme_stylebox_override(state, tight))
		var period: StringName = pair[0]
		tab.size_flags_stretch_ratio = 1.6 if period == &"last_block" else 1.0  # Its longer words, never clipped
		tab.pressed.connect(func() -> void:
			_period = period
			refresh())
		tabs.add_child(tab)
		_tabs[period] = tab
	_body.add_child(tabs)
	_rows.add_theme_constant_override("separation", 0)
	_body.add_child(_rows)
	_more.add_theme_font_size_override("font_size", 13)
	_more.add_theme_color_override("font_color", UiStyle.INK_DIM)
	_body.add_child(_more)
	_footer_gap.custom_minimum_size.y = FOOTER_GAP - 4.0  # (the body adds its 2 px separation on each side)
	_body.add_child(_footer_gap)
	_quiet.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quiet.add_theme_font_size_override("font_size", 13)
	_quiet.add_theme_color_override("font_color", UiStyle.INK_DIM)
	_body.add_child(_quiet)
	_open = bool(HeartwoodMemory.get_settings().get(OPEN_SETTING, false))
	_body.visible = _open

func set_open(open: bool) -> void:
	_open = open
	_body.visible = open
	var settings := HeartwoodMemory.get_settings()
	settings[OPEN_SETTING] = open
	if dream_state != null and dream_state.drift_director != null and get_tree().current_scene == dream_state.drift_director.owner:
		HeartwoodMemory.save_settings(settings)  # The real game only (tests never write)
	refresh()

func _process(delta: float) -> void:
	_place()
	_clock -= delta / maxf(Engine.time_scale, 0.001)
	if _clock > 0.0:
		return
	_clock = REFRESH
	refresh()

# Shown once a Dream has done something this run, unless a screen covers the HUD or the Dream icons' own list is open
# (it drops down in the same spot).
func _wanted() -> bool:
	if dream_state == null or UiStyle.is_phone() or dream_state.get_card_credit_table(&"run").is_empty():
		return false
	var hud := get_parent()
	if hud != null and hud.has_method("_phone_choice_open") and hud.call("_phone_choice_open"):
		return false
	var row := hud.get_node_or_null("DreamsRow") if hud != null else null
	var list = row.get("_list") if row != null else null
	return not (list is CanvasItem and (list as CanvasItem).visible)

func refresh() -> void:
	visible = _wanted()
	if not visible:
		return
	var table: Dictionary = dream_state.get_card_credit_table(_period)
	var block_total := _damage_total(dream_state.get_card_credit_table(&"block"))
	_header.text = "Dreams +%s this block" % _thousands(roundi(block_total))
	if not _open:
		return
	for period in _tabs:
		_tabs[period].set_pressed_no_signal(period == _period)
	var entries: Array = []
	for id in table:
		entries.append({"id": String(id), "row": table[id], "damage": float(table[id].get("damage", 0.0)) + float(table[id].get("setup", 0.0))})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.damage > b.damage if a.damage != b.damage else a.id < b.id)
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	for entry in entries.slice(0, ROWS):
		_rows.add_child(_row(entry))
	_more.visible = entries.size() > ROWS or entries.is_empty()
	_more.text = "and %d more" % (entries.size() - ROWS) if entries.size() > ROWS else "Nothing yet this %s." % ("run" if _period == &"run" else "block")
	_quiet.text = _quiet_line(table)
	_quiet.visible = _quiet.text != ""
	_footer_gap.visible = _quiet.visible

func _row(entry: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 26)
	row.add_theme_constant_override("separation", 8)
	var card := _card(entry.id)
	var glyph := Control.new()  # The card's glyph in its rarity colour (a Calling evolution: its card's)
	glyph.custom_minimum_size = Vector2(GLYPH + 2.0, GLYPH + 2.0)
	glyph.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var rarity: int = card.rarity if card != null else 0
	var texture := UiStyle.dream_glyph_texture(UiStyle.dream_glyph(card) if card != null else &"generic")
	glyph.draw.connect(_draw_glyph.bind(glyph, texture, UpgradeData.rarity_color(rarity), rarity))
	row.add_child(glyph)
	var name := Label.new()
	name.text = _name(entry.id)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.clip_text = true
	name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name.add_theme_font_size_override("font_size", 15)
	name.add_theme_color_override("font_color", UiStyle.INK)  # Moon-pale; only the value is gold
	row.add_child(name)
	var fired := _fired(entry.id)
	var count := Label.new()
	count.text = "×%d" % fired if fired > 0 else ""
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.custom_minimum_size.x = COUNT_W
	UiStyle.number(count, 15, UiStyle.INK_DIM)
	row.add_child(count)
	var value := Label.new()
	value.text = _value(entry)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.custom_minimum_size.x = VALUE_W
	UiStyle.number(value, 15, UiStyle.GOLD)
	row.add_child(value)
	row.tooltip_text = card.description if card != null else ""
	return row

# A white-mask glyph on a 1 px Dread outline, then in `colour` (like the chip icons); the rarity gem when it has none.
static func _draw_glyph(canvas: Control, texture: Texture2D, colour: Color, rarity: int) -> void:
	var at := ((canvas.size - Vector2(GLYPH, GLYPH)) / 2.0).round()
	if texture == null:
		UiStyle.draw_gem(canvas, canvas.size / 2.0, GLYPH / 2.0 - 2.0, rarity)
		return
	for d: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		canvas.draw_texture_rect(texture, Rect2(at + d, Vector2(GLYPH, GLYPH)), false, Palette.DREAD)
	canvas.draw_texture_rect(texture, Rect2(at, Vector2(GLYPH, GLYPH)), false, colour)

# Times `id` fired in the shown period (DreamState.card_counts_*; 0 when it keeps none).
func _fired(id: String) -> int:
	var counts = dream_state.get(COUNTS.get(_period, "card_counts_block"))
	return int((counts as Dictionary).get(id, (counts as Dictionary).get(StringName(id), 0))) if counts is Dictionary else 0

# "Quiet this block: Thick Bark, Quick Step": taken cards with no credit and no fire in the period ("" for none).
func _quiet_line(table: Dictionary) -> String:
	var quiet: Array[String] = []
	for card in dream_state.get_taken_cards():
		if card != null and not table.has(card.id) and not table.has(StringName(card.id)) and _fired(card.id) <= 0:
			quiet.append(_name(card.id))
	if quiet.is_empty():
		return ""
	var when := {&"block": "this block", &"last_block": "last block", &"run": "this run"}
	return "Quiet %s: %s" % [when.get(_period, "this block"), ", ".join(quiet)]

func _value(entry: Dictionary) -> String:
	if entry.damage > 0.0:
		return "+%s" % _thousands(roundi(entry.damage))
	for pair in OTHER_KEYS:
		var amount := float(entry.row.get(pair[0], 0.0))
		if amount > 0.0:
			return "+%s %s" % [_thousands(roundi(amount)), pair[1]]
	return "–"

func _card(id: String) -> UpgradeData:
	if DreamState.CALLING_PATHS.PATHS.has(StringName(id)):
		return DreamState.CALLING_PATHS.card(StringName(id))
	for each in dream_state.pool:
		if each.id == id:
			return each
	return null

func _name(id: String) -> String:
	if DreamState.CALLING_PATHS.PATHS.has(StringName(id)):
		return String(DreamState.CALLING_PATHS.PATHS[StringName(id)].name)
	return dream_state.get_display_name(id)

static func _damage_total(table: Dictionary) -> float:
	var total := 0.0
	for id in table:
		total += float(table[id].get("damage", 0.0)) + float(table[id].get("setup", 0.0))
	return total

# Under the Dream icons on the left edge; while the Warden drawer is open below and would be crossed, only the header.
func _place() -> void:
	var hud := get_parent()
	if hud == null:
		return
	var top := 56.0
	var row := hud.get_node_or_null("DreamsRow") as Control
	if row != null and row.is_visible_in_tree():
		top = row.get_global_rect().end.y + GAP
	position = Vector2(16.0, top)
	var drawer := hud.get_node_or_null("WardenPanel") as Control
	var crossed := drawer != null and drawer.is_visible_in_tree() and top + get_combined_minimum_size().y > drawer.get_global_rect().position.y - GAP
	_body.visible = _open and not crossed
	size = Vector2(WIDTH, 0.0)  # Shrinks to what shows

static func _thousands(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out
