extends PanelContainer
class_name StatusLinks

# Every status word is a link (screens_ui.md "Stat and status icons"): in any text, status names
# (Soaked, Charged, … and {damp}-style tokens) are underlined; hovering (PC) or tapping (touch) one
# shows a small popup with its icon, name and IconInfo definition, and "More in the Codex".
#
# For any screen:
#   var label := StatusLinks.make_label("Applies {damp}. Loves Charged nightmares.")
#   parent.add_child(label)
# or, on your own RichTextLabel: label.text = StatusLinks.bbcode(text); StatusLinks.hook(label).
# "More in the Codex" opens the Codex's glossary on that status: inside the Codex it jumps there,
# elsewhere it calls open_codex(&"glossary", name) on the first node in group "codex_host" (the pause
# menu in a run, the title screen).

const META_PREFIX := "status:"
const TERM_PREFIX := "term:"  # Game terms ({block} …): the popup is the Codex glossary's line
const FAMILY_PREFIX := "family:"  # Family names ({family:dewdrop}): emblem, damage type, identity
const COMBO_PREFIX := "combo:"  # Combos ({combo:thunderclap}): name, statuses, what it does, times set off; ??? until found
const CODEX_HOST_GROUP := &"codex_host"
const HIDE_DELAY := 0.5  # Seconds after the pointer leaves the word (or the popup) before it hides
const LINK_COLOR := UiStyle.INK  # Ink text on a 1 px gold underline (ui_style.md "Links")
const LINK_LINE := Color(UiStyle.GOLD, 0.7)

static var _pattern: RegEx = null

var _icon := TextureRect.new()
var _name := Label.new()
var _text := Label.new()
var _status: StringName = &""
var _is_term := false  # _status is a term id, not a status
var _is_family := false  # _status is a family id
var _is_combo := false  # _status is a combo id
var _host: Control = null  # The label the popup belongs to (it draws on the tip layer)
var _hide_in := -1.0

# `text` with every status name (and {damp}-style token) and every term token ({block}, {Drifts} …)
# as a [url] link, other "[" escaped.
static func bbcode(text: String) -> String:
	# Term tokens first, as placeholders (no letters: the status pattern never matches inside them).
	var terms: Array = []
	if text.contains("{"):
		for token in IconInfo.term_tokens():
			while text.contains(token[0]):
				text = text.replace(token[0], "\u0001%d\u0001" % terms.size())
				terms.append(_link(TERM_PREFIX + String(token[1]), token[2]))
		for found in IconInfo.family_pattern().search_all(text):  # {family:dewdrop}
			var id := found.get_string(1)
			var data := IconInfo.family_data(id)
			text = text.replace(found.get_string(), "\u0001%d\u0001" % terms.size())
			terms.append(_link(FAMILY_PREFIX + id, data.display_name if data != null else id.capitalize()))
		for found in _combo_pattern().search_all(text):  # {combo:thunderclap}: its name, or ??? until found
			text = text.replace(found.get_string(), "\u0001%d\u0001" % terms.size())
			terms.append(combo_link(StringName(found.get_string(1))))
	text = _statuses(IconInfo.format(text).replace("[", "[lb]"))
	for i in terms.size():
		text = text.replace("\u0001%d\u0001" % i, terms[i])
	return text

static var _combo_regex: RegEx = null
static func _combo_pattern() -> RegEx:
	if _combo_regex == null:
		_combo_regex = RegEx.create_from_string("\\{combo:([a-z_]+)\\}")
	return _combo_regex

# A combo as a link (screens_ui.md: every combo link everywhere works the same): its name, or "???"
# until discovered; hover / tap shows its tip, a second tap or a click opens it in the Codex.
static func combo_link(id: StringName) -> String:
	var combo := CodexData.get_any(id)
	var found := CodexData.is_discovered(id)
	return _link(COMBO_PREFIX + String(id), combo.get("name", String(id).capitalize()) if found and not combo.is_empty() else "???")

# The combo tip's text: "Soaked + Charged. Lightning arcs … Set off 12 times." (??? until found).
static func combo_tip_text(id: StringName) -> String:
	var combo := CodexData.get_any(id)
	if combo.is_empty() or not CodexData.is_discovered(id):
		return "Not discovered yet: set it off in a run to learn it."
	var parts: Array[String] = []
	if combo.has("statuses"):
		parts.append(CodexData.ingredients_text(combo) + ".")
	parts.append(IconInfo.format(String(combo.get("text", ""))))
	var times := combo_times(id)
	parts.append("Set off %d time%s." % [times, "" if times == 1 else "s"] if times > 0 else "Not set off yet on this profile.")
	return " ".join(parts)

static func combo_times(id: StringName) -> int:
	var times := int(HeartwoodMemory.load_data().get(ComboFeedback.COUNTS_KEY, {}).get(String(id), 0))
	var tree := Engine.get_main_loop() as SceneTree
	var live := tree.get_first_node_in_group(ComboFeedback.GROUP) as ComboFeedback if tree != null else null
	if live != null:
		times += int(live._unsaved.get(id, 0))
	return times

static func _link(meta: String, word: String) -> String:
	return "[url=%s][u color=#%s][color=#%s]%s[/color][/u][/url]" % [meta, LINK_LINE.to_html(true),
		LINK_COLOR.to_html(false), word]

static func _statuses(text: String) -> String:
	if _pattern == null:
		var names: Array = []
		for id in IconInfo.STATUSES:
			names.append(_escape(IconInfo.STATUSES[id][0]))
		names.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
		_pattern = RegEx.new()
		_pattern.compile("\\b(" + "|".join(names) + ")\\b")
	var out := ""
	var at := 0
	for found in _pattern.search_all(text):
		var id := IconInfo.status_id(found.get_string())
		out += text.substr(at, found.get_start() - at)
		out += _link(META_PREFIX + String(id), found.get_string())
		at = found.get_end()
	return out + text.substr(at)

# A RichTextLabel showing `text` with its status names as links (wraps, sizes to its content).
static func make_label(text: String, font_size: int = 15, colour: Color = UiStyle.INK) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(60, 0)
	label.add_theme_font_size_override("normal_font_size", font_size)
	label.add_theme_color_override("default_color", colour)
	label.text = bbcode(text)
	hook(label)
	return label

# Makes the status links in `label` show their popup on hover and on tap.
static func hook(label: RichTextLabel) -> void:
	label.meta_underlined = false  # bbcode() draws the gold underline itself
	if label.mouse_filter == Control.MOUSE_FILTER_IGNORE:
		label.mouse_filter = Control.MOUSE_FILTER_PASS
	var popup := StatusLinks.new()
	label.add_child(popup)
	label.set_meta(&"status_popup", popup)  # It moves to the tip layer when shown (tests find it here)
	label.meta_clicked.connect(func(meta: Variant) -> void: popup._show_for(String(meta), label, true))
	label.meta_hover_started.connect(func(meta: Variant) -> void: popup._show_for(String(meta), label, false))
	label.meta_hover_ended.connect(func(_meta: Variant) -> void: popup._hide_soon())

static func _escape(s: String) -> String:
	var out := ""
	for c in s:
		out += ("\\" + c) if "\\.^$|?*+()[]{}".contains(c) else c
	return out

func _init() -> void:
	top_level = true
	add_theme_stylebox_override("panel", UiStyle.tip_panel())  # Opaque, the gold thread, a soft shadow
	visible = false
	z_index = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	add_child(row)
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.custom_minimum_size = Vector2(32, 32)
	row.add_child(_icon)
	var box := VBoxContainer.new()
	row.add_child(box)
	UiStyle.tip_name(_name, LINK_COLOR)  # Tip sizes (screens_ui.md playtest fixes 2026-09-30)
	box.add_child(_name)
	UiStyle.tip_body(_text)
	box.add_child(_text)
	var more := LinkButton.new()
	more.text = "More in the Codex"
	more.focus_mode = Control.FOCUS_NONE
	more.pressed.connect(_open_codex)
	box.add_child(more)
	mouse_entered.connect(func() -> void: _hide_in = -1.0)
	mouse_exited.connect(_hide_soon)

func _show_for(meta: String, host: Control, tapped: bool) -> void:
	var is_term := meta.begins_with(TERM_PREFIX)
	var is_family := meta.begins_with(FAMILY_PREFIX)
	var is_combo := meta.begins_with(COMBO_PREFIX)
	if not meta.begins_with(META_PREFIX) and not is_term and not is_family and not is_combo:
		return
	var id := StringName(meta.get_slice(":", 1))
	if tapped and visible and id == _status and _is_term == is_term and _is_family == is_family and _is_combo == is_combo:
		if is_combo and CodexData.is_discovered(id):
			_open_codex()  # A combo: the second tap (or a click after hovering) opens it in the Codex
		else:
			visible = false  # Tapping the same word again closes it
		return
	_status = id
	_host = host
	_is_term = is_term
	_is_family = is_family
	_is_combo = is_combo
	if is_combo:  # A combo: its name (??? until found), its statuses, what it does, times set off
		var combo := CodexData.get_any(id)
		var found := CodexData.is_discovered(id) and not combo.is_empty()
		var statuses: Array = combo.get("statuses", [])
		_icon.texture = IconInfo.icon(statuses[0]) if found and not statuses.is_empty() else null  # Its first status
		_icon.visible = _icon.texture != null
		_name.text = combo.get("name", String(id)) if found else "???"
		_text.text = combo_tip_text(id)
	elif is_family:  # A family: its base Warden's icon, "Dewdrop family", its damage type and identity
		var data := IconInfo.family_data(String(id))
		_icon.texture = WardenIcon.make(data) if data != null else null  # Its base Warden (no family emblems)
		_icon.visible = _icon.texture != null
		_name.text = "%s family" % (data.display_name if data != null else String(id).capitalize())
		_text.text = ("%s. %s" % [IconInfo.damage_type_text(data.line), IconInfo.format(data.description)]) if data != null else ""
	elif is_term:  # A game term: its name and the Codex glossary's line, no icon
		_icon.visible = false
		_name.text = term_name(id)
		_text.text = CodexData.definition(term_name(id))
	else:
		_icon.texture = IconInfo.icon(id)
		_icon.visible = _icon.texture != null
		_name.text = IconInfo.status_name(id)
		_text.text = IconInfo.format(IconInfo.STATUSES.get(id, ["", ""])[1])
	var mouse := host.get_global_mouse_position()
	UiStyle.lift_tip(self, host)  # Above every panel and screen (screens_ui.md "tips are opaque")
	visible = true
	reset_size()
	# Above-right of the pointer, flipped at the edges: never over the word or the line being read.
	global_position = UiStyle.tip_position(mouse, size, get_viewport_rect().size)
	_hide_in = -1.0

func _hide_soon() -> void:
	if visible:
		_hide_in = HIDE_DELAY

func _process(delta: float) -> void:
	if _hide_in < 0.0:
		return
	_hide_in -= delta / maxf(Engine.time_scale, 0.001)
	if _hide_in <= 0.0:
		_hide_in = -1.0
		if not get_global_rect().has_point(get_global_mouse_position()):
			visible = false

# A term's glossary name ("Perfect block").
static func term_name(id: StringName) -> String:
	return IconInfo.TERMS[id][2] if IconInfo.TERMS.has(id) else String(id).capitalize()

func _open_codex() -> void:
	visible = false
	var name := String(_status) if _is_combo else (term_name(_status) if _is_term else IconInfo.status_name(_status))
	var node: Node = _host if is_instance_valid(_host) else get_parent()  # (The popup itself sits on the tip layer)
	while node != null:  # Inside the Codex: just jump there
		if node is CodexPanel:
			if _is_family:
				node.show_families()
			else:
				node.jump(name)
			return
		node = node.get_parent()
	var host := get_tree().get_first_node_in_group(CODEX_HOST_GROUP)
	if host != null and host.has_method("open_codex"):
		var tab := &"families" if _is_family else (&"combos" if _is_combo else &"glossary")
		host.open_codex(tab, "" if _is_family else name)
