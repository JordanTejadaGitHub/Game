extends PanelContainer
class_name CodexPanel

# The Codex (screens_ui.md "The Codex: Glossary and Combos"), from the pause menu, the title, the
# Memory Grove and the HUD "?" button. Two tabs:
# - Glossary: every term (CodexData.GLOSSARY), grouped and searchable, with "see also" links that
#   jump (to another term, or to a combo); bosses and late nightmares appear once met
#   (profile nightmares_seen).
# - Combos: all 15 (CodexData.combos()); locked ones are "???" with their ingredient icons as a hint;
#   discovered ones (ComboFeedback, profile combos_seen) show what they do, which of your Wardens
#   apply each ingredient, and how often you've set them off. "N / 15 combos discovered".
# Everything is tap-based. Built in code.

const TOWER_DIR := "res://resource/tower/"
const ENEMY_DIR := "res://resource/enemy/"
const START_FAMILIES := ["sporeling", "firefly_jar", "dewdrop"]
const LOCKED_COLOR := Color(0.5, 0.52, 0.56)
const TERM_COLOR := Color(0.95, 0.9, 0.7)
const HIGHLIGHT := Color(1.0, 0.95, 0.6, 0.18)

var tabs := TabContainer.new()
var _search := LineEdit.new()
var _glossary := VBoxContainer.new()
var _glossary_scroll := ScrollContainer.new()
var _combos := VBoxContainer.new()
var _combos_scroll := ScrollContainer.new()
var _combo_count := Label.new()
var _entries := {}  # Term or combo id -> its Control (for jumps)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.custom_minimum_size = Vector2(560, 520)
	add_child(box)
	var title := Label.new()
	title.text = "Codex"
	title.add_theme_font_size_override("font_size", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(tabs)

	var glossary_page := VBoxContainer.new()
	glossary_page.name = "Glossary"
	tabs.add_child(glossary_page)
	_search.placeholder_text = "Search terms…"
	_search.custom_minimum_size = Vector2(0, 40)
	_search.text_changed.connect(func(_t: String) -> void: _build_glossary())
	glossary_page.add_child(_search)
	_glossary_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_glossary_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_glossary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_glossary_scroll.add_child(_glossary)
	glossary_page.add_child(_glossary_scroll)

	var combos_page := VBoxContainer.new()
	combos_page.name = "Combos"
	tabs.add_child(combos_page)
	_combo_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combos_page.add_child(_combo_count)
	_combos_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_combos_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_combos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_combos.add_theme_constant_override("separation", 10)
	_combos_scroll.add_child(_combos)
	combos_page.add_child(_combos_scroll)

	var close := Button.new()
	close.text = "Close"
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(0, 48)
	close.pressed.connect(func() -> void: visible = false)
	box.add_child(close)

# Opens the Codex, optionally on a tab (&"glossary" / &"combos") and an entry (term or combo id).
func open(tab: StringName = &"", entry: String = "") -> void:
	_build_glossary()
	_build_combos()
	visible = true
	if tab == &"combos":
		tabs.current_tab = 1
	elif tab == &"glossary":
		tabs.current_tab = 0
	if entry != "":
		jump.call_deferred(entry)

# Shows `name` (a glossary term, or a combo's id or name), switching tabs if needed.
func jump(name: String) -> void:
	var combo := _find_combo(name)
	if not combo.is_empty():
		tabs.current_tab = 1
		_focus.call_deferred(_combos_scroll, _entries.get(String(combo.id)))
		return
	if not _entries.has(name):
		_search.text = ""
		_build_glossary()
	tabs.current_tab = 0
	_focus.call_deferred(_glossary_scroll, _entries.get(name))

func _focus(scroll: ScrollContainer, target: Control) -> void:
	if target == null:
		return
	scroll.ensure_control_visible(target)
	var tween := target.create_tween()
	target.modulate = Color(1.6, 1.5, 1.1)
	tween.tween_property(target, "modulate", Color.WHITE, 0.8)

func _find_combo(name: String) -> Dictionary:
	for combo in CodexData.combos():
		if String(combo.id) == name or combo.name == name:
			return combo
	return {}

# --- Glossary ------------------------------------------------------------------------------------

func _build_glossary() -> void:
	for child in _glossary.get_children():
		child.queue_free()
	for key in _entries.keys():
		if _find_combo(key).is_empty():
			_entries.erase(key)
	var groups := {}
	for found in CodexData.search(_search.text):
		groups.get_or_add(found[0], []).append(found[1])
	for group in CodexData.GLOSSARY:
		if groups.has(group[0]):
			_add_group(group[0], groups[group[0]])
	var met := get_met_nightmares()
	var query := _search.text.strip_edges().to_lower()
	if query != "":
		met = met.filter(func(e: Array) -> bool: return e[0].to_lower().contains(query) or e[1].to_lower().contains(query))
	if not met.is_empty():
		_add_group("Nightmares you've met", met)
	if _glossary.get_child_count() == 0:
		var none := Label.new()
		none.text = "Nothing matches \"%s\"." % _search.text
		_glossary.add_child(none)

func _add_group(title: String, entries: Array) -> void:
	var header := Label.new()
	header.text = title
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color(0.75, 0.9, 0.75))
	_glossary.add_child(header)
	for entry in entries:
		var card := VBoxContainer.new()
		card.add_theme_constant_override("separation", 2)
		var term := Label.new()
		term.text = entry[0]
		term.add_theme_font_size_override("font_size", 17)
		term.add_theme_color_override("font_color", TERM_COLOR)
		card.add_child(term)
		var text := Label.new()
		text.text = entry[1]
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.add_theme_font_size_override("font_size", 15)
		card.add_child(text)
		if entry.size() > 2 and not entry[2].is_empty():
			var links := HFlowContainer.new()
			var see := Label.new()
			see.text = "See also:"
			see.add_theme_font_size_override("font_size", 13)
			links.add_child(see)
			for other in entry[2]:
				var link := LinkButton.new()
				link.text = other
				link.focus_mode = Control.FOCUS_NONE
				link.pressed.connect(jump.bind(other))
				links.add_child(link)
			card.add_child(links)
		_glossary.add_child(card)
		_entries[entry[0]] = card

# [[name, what it does]] for every nightmare kind met in any run (bosses and late nightmares only
# show once met), from the profile's nightmares_seen.
static func get_met_nightmares() -> Array:
	var list: Array = []
	for kind in HeartwoodMemory.load_data().get("nightmares_seen", []):
		var path := ENEMY_DIR + String(kind) + ".tres"
		if not ResourceLoader.exists(path):
			continue
		var data := load(path) as EnemyData
		if data != null:
			list.append([data.display_name, data.trait_text if data.trait_text != "" else "A nightmare of the Hollow.", []])
	list.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	return list

# --- Combos ----------------------------------------------------------------------------------------

func _build_combos() -> void:
	for child in _combos.get_children():
		child.queue_free()
	var seen := ComboFeedback.load_seen()
	var counts: Dictionary = HeartwoodMemory.load_data().get(ComboFeedback.COUNTS_KEY, {})
	var live := get_tree().get_first_node_in_group(ComboFeedback.GROUP) as ComboFeedback if is_inside_tree() else null
	var all := CodexData.combos()
	var found := 0
	for combo in all:
		var discovered := seen.has(String(combo.id))
		if discovered:
			found += 1
		var times := int(counts.get(String(combo.id), 0)) + (int(live._unsaved.get(combo.id, 0)) if live else 0)
		var card := _combo_card(combo, discovered, times)
		_combos.add_child(card)
		_entries[String(combo.id)] = card
	_combo_count.text = "%d / %d combos discovered" % [found, all.size()]
	tabs.set_tab_title(1, "Combos %d / %d" % [found, all.size()])

func _combo_card(combo: Dictionary, discovered: bool, times: int) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.15, 0.95) if discovered else Color(0.06, 0.07, 0.09, 0.95)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	panel.add_child(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	for status in combo.statuses:
		row.add_child(StatusIcon.new(status, not discovered))
	var name := Label.new()
	name.text = "%s  ·  %s" % [combo.name, combo.kind] if discovered else "???"
	name.add_theme_font_size_override("font_size", 18)
	var reaction := Reactions.get_data(combo.id)
	name.add_theme_color_override("font_color", (reaction.callout_color if reaction else TERM_COLOR) if discovered else LOCKED_COLOR)
	row.add_child(name)
	var ingredients := Label.new()
	ingredients.text = CodexData.ingredients_text(combo)
	ingredients.add_theme_font_size_override("font_size", 14)
	ingredients.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0) if discovered else LOCKED_COLOR)
	box.add_child(ingredients)
	if not discovered:
		return panel
	var text := Label.new()
	text.text = combo.text
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_size_override("font_size", 15)
	box.add_child(text)
	var by := Label.new()
	by.text = get_sources_text(combo)
	by.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	by.add_theme_font_size_override("font_size", 13)
	by.add_theme_color_override("font_color", Color(0.75, 0.9, 0.75))
	box.add_child(by)
	var count := Label.new()
	count.text = "Set off %d time%s" % [times, "" if times == 1 else "s"]
	count.add_theme_font_size_override("font_size", 13)
	box.add_child(count)
	return panel

# "Set off by: Stormcap" (synergies), or per ingredient which of your Wardens apply it:
# "Damp: Dewdrop, Rain Lily · Static: Firefly Jar" (Reactions).
static func get_sources_text(combo: Dictionary) -> String:
	if combo.get("by", "") != "":
		return "Set off by: " + combo.by
	var parts: Array[String] = []
	var done: Array = []
	for status in combo.statuses:
		if done.has(status):
			continue
		done.append(status)
		var names: Array[String] = []
		for data in get_player_wardens():
			if (data.applies_status == status or data.extra_status == status) and names.size() < 4:
				names.append(data.display_name)
		parts.append("%s: %s" % [CodexData.STATUS_NAMES.get(status, String(status)), ", ".join(names) if not names.is_empty() else "none of your Wardens yet"])
	return " · ".join(parts)

static var _wardens: Array[TowerData] = []

# Every Warden of the families this profile can pick (the starting 3 + Grove-grown families).
static func get_player_wardens() -> Array[TowerData]:
	if _wardens.is_empty():
		for file in ResourceLoader.list_directory(TOWER_DIR):
			if file.ends_with(".tres"):
				var data := load(TOWER_DIR + file) as TowerData
				if data != null:
					_wardens.append(data)
	var families: Array = START_FAMILIES.duplicate()
	var memory := HeartwoodMemory.load_data()
	for unlock in HeartwoodMemory.load_grove():
		if HeartwoodMemory.unlock_level(memory, unlock.id) > 0:
			families.append_array(unlock.families)
	var lines := {}
	for data in _wardens:
		if data.tier == 1 and families.has(data.get_id()):
			lines[data.line] = true
	var result: Array[TowerData] = []
	for data in _wardens:
		if lines.has(data.line) and data.tier >= 1:
			result.append(data)
	return result
