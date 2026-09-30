extends PanelContainer
class_name CodexPanel

# The Codex (screens_ui.md "The Codex: Glossary and Combos"), from the pause menu, the title, the
# Memory Grove and the HUD "?" button. Two tabs:
# - Glossary: every term (CodexData.glossary()), grouped and searchable, with "see also" links that
#   jump (to another term, or to a combo); bosses and late nightmares appear once met
#   (profile nightmares_seen).
# - Combos: those the families you can get make (CodexData.scope: the starting three + Grove
#   families; the demo its three; dev runs all), "N more wait in the Memory Grove." for the rest;
#   locked ones are just "???" (no icons: they would give it away); discovered ones (ComboFeedback,
#   profile combos_seen) show what they do, which of your Wardens apply each ingredient, and how often
#   you've set them off. Newly covered ones wear a "New from the Grove" leaf (profile codex_covered).
# - Families: each family in scope, its forms (Grove-kept ones as silhouettes) and its combos.
# Everything is tap-based. Built in code.

const TOWER_DIR := "res://resource/tower/"
const ENEMY_DIR := "res://resource/enemy/"
const START_FAMILIES := ["sporeling", "firefly_jar", "dewdrop"]
const LOCKED_COLOR := Color(0.5, 0.52, 0.56)
const TERM_COLOR := Color(0.95, 0.9, 0.7)
const HIGHLIGHT := Color(1.0, 0.95, 0.6, 0.18)
const CROWN_COLOR := Color(1.0, 0.82, 0.35)  # Crowned Reactions: the gold tier
const CROWN_SILHOUETTE := preload("res://assets/effects/crowned_codex_silhouette.png")
const KIN_COLOR := Color(0.7, 0.9, 0.45)  # Kinships: green-gold, the forest growing between Wardens
const KIN_FRAME := preload("res://assets/effects/kin_codex_frame.png")
const KIN_LEAF := preload("res://assets/effects/kin_leaf_icon.png")

var tabs := TabContainer.new()
var _search := LineEdit.new()
var _glossary := VBoxContainer.new()
var _glossary_scroll := ScrollContainer.new()
var _combos := VBoxContainer.new()
var _combos_scroll := ScrollContainer.new()
var _combo_count := Label.new()
var _entries := {}  # Term or combo id -> its Control (for jumps)
var _families := VBoxContainer.new()  # The Families page
var family_cards := {}  # Family base id -> its section (tests)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.custom_minimum_size = Vector2(560, 520)
	add_child(box)
	var title := Label.new()
	title.text = "Codex"
	UiStyle.display(title, 24)
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

	# Families (screens_ui.md "What the Codex covers"): the families you have, their forms, their combos.
	var families_page := ScrollContainer.new()
	families_page.name = "Families"
	families_page.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_families.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_families.add_theme_constant_override("separation", 14)
	families_page.add_child(_families)
	tabs.add_child(families_page)
	_setup_dreams_page()
	_setup_nightmares_page()

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
	_build_families()
	_build_dreams()
	_build_nightmares()
	visible = true
	if tab == &"combos":
		tabs.current_tab = 1
	elif tab == &"glossary":
		tabs.current_tab = 0
	elif tab == &"families":
		show_families()
	if entry != "":
		jump.call_deferred(entry)

# The Families tab (a family link's "More in the Codex").
func show_families() -> void:
	for i in tabs.get_tab_count():
		if tabs.get_tab_control(i).name == "Families":
			tabs.current_tab = i

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
	if not is_instance_valid(target) or not scroll.is_ancestor_of(target):
		return  # Rebuilt since the jump was asked for (the page reopened in the same frame)
	scroll.ensure_control_visible(target)
	var tween := target.create_tween()
	target.modulate = Color(1.6, 1.5, 1.1)
	tween.tween_property(target, "modulate", Color.WHITE, 0.8)

func _find_combo(name: String) -> Dictionary:
	for combo in CodexData.combos() + CodexData.crowned() + CodexData.kinships():
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
	for group in CodexData.glossary():
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
		card.add_child(StatusLinks.make_label(entry[1], 15))  # Status names are links
		if entry.size() > 2 and not entry[2].is_empty():
			var links := HFlowContainer.new()
			var see := Label.new()
			see.text = "See also:"
			see.add_theme_font_size_override("font_size", 13)
			links.add_child(see)
			for other in entry[2]:
				var combo := _find_combo(other)
				if not combo.is_empty() and not CodexData.is_discovered(combo.id):
					continue  # An undiscovered combo isn't named anywhere (screens_ui.md)
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
			# Traits may name statuses as {tokens}: fill them in, so search finds "Soaked".
			list.append([data.display_name, IconInfo.format(data.trait_text) if data.trait_text != "" else "A nightmare of the Hollow.", []])
	list.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	return list

# --- Combos ----------------------------------------------------------------------------------------
# Only entries the families you can get in a run can make are listed (CodexData.scope / in_build,
# screens_ui.md "What the Codex covers"); each section ends with "N more wait in the Memory Grove."
# for the rest. An entry newly covered since the last look (a Grove family / form was planted) wears a
# small leaf "New from the Grove" mark (profile codex_covered).

const COVERED_KEY := "codex_covered"
const GROVE_COLOR := Color(0.6, 0.85, 0.55)
var _scope := {}
var _fresh := {}  # Entry ids newly covered since the last Codex (the leaf mark)

func _covered(entry: Dictionary) -> bool:
	return CodexData.in_build(entry, _scope)

func _build_combos() -> void:
	for id in _entries.keys():  # Forget the old cards (jumps must find the new ones)
		if is_instance_valid(_entries[id]) and _entries[id].get_parent() == _combos:
			_entries.erase(id)
	for child in _combos.get_children():
		_combos.remove_child(child)  # Gone now, not at the frame's end (rebuilt in place)
		child.queue_free()
	_scope = CodexData.scope()
	var seen := ComboFeedback.load_seen()
	var profile := HeartwoodMemory.load_data()
	var counts: Dictionary = profile.get(ComboFeedback.COUNTS_KEY, {})
	var live := get_tree().get_first_node_in_group(ComboFeedback.GROUP) as ComboFeedback if is_inside_tree() else null
	var every := CodexData.combos()
	var all := every.filter(_covered)
	var crowned_all: Array = [] if ResultsScreen.is_demo() else Array(CodexData.crowned())
	var kin_all := CodexData.kinships()
	_mark_fresh(profile, all + crowned_all.filter(_covered) + kin_all.filter(_covered))
	var found := 0
	for combo in all:
		var discovered := seen.has(String(combo.id))
		if discovered:
			found += 1
		var times := int(counts.get(String(combo.id), 0)) + (int(live._unsaved.get(combo.id, 0)) if live else 0)
		var card := _combo_card(combo, discovered, times)
		_add_card(card, combo.id, discovered)
		_entries[String(combo.id)] = card
	_add_waiting(every.size() - all.size())
	_combo_count.text = "%d / %d combos discovered" % [found, all.size()]
	tabs.set_tab_title(1, "Combos %d / %d" % [found, all.size()])
	_build_kinships(seen, counts, live, kin_all)
	# Crowned Reactions: hidden ("???" in a gold crown frame) until found; full game only.
	if ResultsScreen.is_demo():
		return
	var crowned := crowned_all.filter(_covered)
	var crowned_found := crowned.filter(func(c: Dictionary) -> bool: return seen.has(String(c.id))).size()
	var header := Label.new()
	header.text = "Crowned Reactions · %d / %d" % [crowned_found, crowned.size()]
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", CROWN_COLOR)
	_combos.add_child(header)
	for c in crowned:
		var discovered := seen.has(String(c.id))
		var times := int(counts.get(String(c.id), 0)) + (int(live._unsaved.get(c.id, 0)) if live else 0)
		var card := _crowned_card(c, discovered, times)
		_add_card(card, c.id, discovered)
		_entries[String(c.id)] = card
	_add_waiting(crowned_all.size() - crowned.size())

# "4 more wait in the Memory Grove." (no names, no hints), when a section has hidden entries.
func _add_waiting(hidden: int) -> void:
	if hidden <= 0:
		return
	var line := Label.new()
	line.name = "Waiting"
	line.text = "%d more wait%s in the Memory Grove." % [hidden, "s" if hidden == 1 else ""]
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.add_theme_font_size_override("font_size", 13)
	line.add_theme_color_override("font_color", LOCKED_COLOR)
	_combos.add_child(line)

# Entries covered now but not at the last look get the leaf mark; the covered set is then remembered
# (the real game only: never tests or dev runs). The first look ever marks nothing.
func _mark_fresh(profile: Dictionary, covered: Array) -> void:
	_fresh.clear()
	var ids: Array = covered.map(func(e: Dictionary) -> String: return String(e.id))
	if profile.has(COVERED_KEY):
		for id in ids:
			if not profile[COVERED_KEY].has(id):
				_fresh[id] = true
	if OS.get_cmdline_args().has("--script") or MetaRun.is_dev_run():
		return
	var before: Array = profile.get(COVERED_KEY, [])
	if before.size() == ids.size() and ids.all(func(id: String) -> bool: return before.has(id)):
		return
	profile[COVERED_KEY] = ids
	HeartwoodMemory.save_data(profile)

# Adds a combo / Crowned / Kinship card; one the Grove newly covers gets the leaf mark.
func _add_card(card: Control, id: StringName, discovered: bool) -> void:
	_combos.add_child(card)
	if not discovered and _fresh.has(String(id)):  # Newly covered by the Grove: a leaf mark
		var mark := HBoxContainer.new()
		mark.name = "GroveMark"
		mark.alignment = BoxContainer.ALIGNMENT_END
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var leaf := TextureRect.new()
		leaf.texture = KIN_LEAF
		leaf.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		leaf.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		leaf.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		leaf.custom_minimum_size = Vector2(16, 16)
		leaf.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		mark.add_child(leaf)
		var words := Label.new()
		words.text = "New from the Grove"
		words.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		words.add_theme_font_size_override("font_size", 12)
		words.add_theme_color_override("font_color", GROVE_COLOR)
		mark.add_child(words)
		card.add_child(mark)

# Kinships (screens_ui.md "Kinship feedback"): "???" in a vine frame until the first bond of that kind
# ever, then the pair, what each borrows, and how often it has formed.
func _build_kinships(seen: Array, counts: Dictionary, live: ComboFeedback, kin_all: Array) -> void:
	var kin := kin_all.filter(_covered)
	if kin.is_empty():
		_add_waiting(kin_all.size())
		return
	var found := kin.filter(func(k: Dictionary) -> bool: return seen.has(String(k.id))).size()
	var header := Label.new()
	header.text = "Kinships  %d / %d" % [found, kin.size()]
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", KIN_COLOR)
	_combos.add_child(header)
	if found > 0:  # Any Kinship found lets the Kinship Dreams into the pool (discovery unlocks)
		var holder := VBoxContainer.new()
		_add_dreams_line(holder, {"kind": "Kinship"})
		if holder.get_child_count() > 0:
			_combos.add_child(holder)
		else:
			holder.free()
	for k in kin:
		var discovered := seen.has(String(k.id))
		var times := int(counts.get(String(k.id), 0)) + (int(live._unsaved.get(k.id, 0)) if live else 0)
		var card := _kinship_card(k, discovered, times)
		_add_card(card, k.id, discovered)
		_entries[String(k.id)] = card
	_add_waiting(kin_all.size() - kin.size())

func _kinship_card(k: Dictionary, discovered: bool, times: int) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	if not discovered:
		# The vine-bordered dark panel (effects.json kin_codex_frame, nine-patch margins 14) with "???".
		var frame := NinePatchRect.new()
		frame.texture = KIN_FRAME
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			frame.set_patch_margin(side, 14)
		frame.custom_minimum_size = Vector2(0, 56)
		var unknown := Label.new()
		unknown.text = "???"
		UiStyle.title(unknown, 20, LOCKED_COLOR)
		unknown.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		frame.add_child(unknown)
		box.add_child(frame)
		return box
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.panel_in(KIN_COLOR))
	var inner := VBoxContainer.new()
	panel.add_child(inner)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var leaf := TextureRect.new()
	leaf.texture = KIN_LEAF
	leaf.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	leaf.custom_minimum_size = Vector2(32, 32)
	leaf.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	leaf.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(leaf)
	var name := Label.new()
	name.text = "%s  ·  Kinship" % k.name
	name.add_theme_font_size_override("font_size", 18)
	name.add_theme_color_override("font_color", KIN_COLOR)
	row.add_child(name)
	inner.add_child(row)
	var pair := Label.new()
	pair.text = "%s + %s" % [k.a, k.b]
	pair.add_theme_font_size_override("font_size", 14)
	pair.add_theme_color_override("font_color", Color(0.8, 0.95, 0.75))
	inner.add_child(pair)
	inner.add_child(StatusLinks.make_label(k.text, 15))
	var count := Label.new()
	count.text = "Formed %d time%s" % [times, "" if times == 1 else "s"]
	count.add_theme_font_size_override("font_size", 13)
	inner.add_child(count)
	box.add_child(panel)
	return box

# An undiscovered Crowned Reaction (effects.json crowned_codex_silhouette, 96×96): the gold crown
# frame alone, no family icons.
func _crowned_silhouette(c: Dictionary) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(96, 96)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := TextureRect.new()
	art.texture = CROWN_SILHOUETTE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(art)  # No family icons: they'd give the recipe away (screens_ui.md, user decision)
	return holder

func _crowned_card(c: Dictionary, discovered: bool, times: int) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.panel_in(CROWN_COLOR if discovered else Color(0.25, 0.23, 0.18)))
	var box := VBoxContainer.new()
	panel.add_child(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	if not discovered:
		row.add_child(_crowned_silhouette(c))  # Only the crown frame while undiscovered
	else:
		for family in c.families:
			var icon := TextureRect.new()
			icon.texture = CodexData.family_icon(family)
			icon.custom_minimum_size = Vector2(28, 28)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.tooltip_text = CodexData.FAMILY_NAMES.get(family, family)
			row.add_child(icon)
	var name := Label.new()
	name.text = "%s  ·  Crowned" % c.name if discovered else "???"
	name.add_theme_font_size_override("font_size", 18)
	name.add_theme_color_override("font_color", CROWN_COLOR if discovered else LOCKED_COLOR)
	row.add_child(name)
	var families: Array[String] = []
	for family in c.families:
		families.append(CodexData.FAMILY_NAMES.get(family, family))
	if discovered:  # Locked: the crown frame and "???" only
		var hint := Label.new()
		hint.text = "%s  ·  %s" % [CodexData.crowned_recipe(c), ", ".join(families)]
		hint.add_theme_font_size_override("font_size", 14)
		hint.add_theme_color_override("font_color", Color(0.9, 0.82, 0.6))
		box.add_child(hint)
		box.add_child(StatusLinks.make_label(c.text, 15))  # Status names are links
		var count := Label.new()
		count.text = "Set off %d time%s" % [times, "" if times == 1 else "s"]
		count.add_theme_font_size_override("font_size", 13)
		box.add_child(count)
		_add_dreams_line(box, c)
	return panel

func _combo_card(combo: Dictionary, discovered: bool, times: int) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.panel(10.0, 10.0))
	var box := VBoxContainer.new()
	panel.add_child(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	if discovered:  # Locked combos are just "???": icons would give the answer away (screens_ui.md)
		for status in combo.statuses:
			row.add_child(StatusIcon.new(status))
	var name := Label.new()
	name.text = "%s  ·  %s" % [combo.name, combo.kind] if discovered else "???"
	name.add_theme_font_size_override("font_size", 18)
	var reaction := Reactions.get_data(combo.id)
	name.add_theme_color_override("font_color", (reaction.callout_color if reaction else TERM_COLOR) if discovered else LOCKED_COLOR)
	row.add_child(name)
	if not discovered:
		return panel  # Just "???" (no ingredients either)
	box.add_child(StatusLinks.make_label(CodexData.ingredients_text(combo), 14, Color(0.75, 0.85, 1.0)))
	box.add_child(StatusLinks.make_label(combo.text, 15))  # Status names are links
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
	_add_dreams_line(box, combo)
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
		parts.append("%s: %s" % [IconInfo.status_name(status), ", ".join(names) if not names.is_empty() else "none of your Wardens yet"])
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
		if HeartwoodMemory.node_level(memory, unlock) > 0:
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

# --- Families --------------------------------------------------------------------------------------
# The families you have (CodexData.scope: the starting three + Grove families; every family in dev
# runs): the base Warden, then its branches, final forms and Ascended form. Forms a Grove node still
# keeps are silhouettes ("Memory Grove"); the rest are unlocked in a run with Dreamlight. Below, its
# combos: names once discovered, "???" before; each jumps to its entry.

const SILHOUETTE := Color(0.05, 0.05, 0.07, 0.9)

func _build_families() -> void:
	for child in _families.get_children():
		_families.remove_child(child)
		child.queue_free()
	family_cards.clear()
	var ids: Array = _scope.get("families", [])
	if _scope.get("all", false):
		ids = CodexData.DEMO_FAMILIES.duplicate()
		for unlock in HeartwoodMemory.load_grove():
			for id in unlock.families:
				if not ids.has(id):
					ids.append(id)
	var seen := ComboFeedback.load_seen()
	for id in ids:
		var path: String = TOWER_DIR + id + ".tres"
		if ResourceLoader.exists(path):
			var section := _family_section(load(path), seen)
			_families.add_child(section)
			family_cards[id] = section

func _family_section(root: TowerData, seen: Array) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	head.add_child(_form_icon(root, true, 40.0))
	var name := Label.new()
	name.text = "%s family" % root.display_name
	name.add_theme_font_size_override("font_size", 20)
	name.add_theme_color_override("font_color", TERM_COLOR)
	name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(name)
	box.add_child(head)
	# Its forms, in growth order.
	var forms := HFlowContainer.new()
	forms.add_theme_constant_override("h_separation", 10)
	var todo: Array = root.evolves_to.duplicate()
	var done := {}
	while not todo.is_empty():
		var data := todo.pop_front() as TowerData
		if data == null or done.has(data.get_id()):
			continue
		done[data.get_id()] = true
		var in_scope: bool = _scope.get("all", false) or _scope.wardens.has(data.get_id())
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 0)
		cell.custom_minimum_size = Vector2(92, 0)
		cell.add_child(_form_icon(data, in_scope, 40.0))
		var label := Label.new()
		label.text = data.display_name if in_scope else "???"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 13)
		cell.add_child(label)
		var how := Label.new()
		how.text = "unlock with Dreamlight" if in_scope else "Memory Grove"
		how.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		how.add_theme_font_size_override("font_size", 11)
		how.add_theme_color_override("font_color", LOCKED_COLOR if in_scope else GROVE_COLOR)
		cell.add_child(how)
		forms.add_child(cell)
		todo.append_array(data.evolves_to)
	box.add_child(forms)
	# Its combos (in scope): discovered by name, the rest "???"; each jumps to its entry.
	var links := HFlowContainer.new()
	links.add_theme_constant_override("h_separation", 10)
	var caption := Label.new()
	caption.text = "Combos:"
	caption.add_theme_font_size_override("font_size", 14)
	links.add_child(caption)
	for entry in family_combos(root):
		if not CodexData.is_discovered(entry.id, seen):  # "???": no name, no link (screens_ui.md)
			var unknown := Label.new()
			unknown.text = "???"
			unknown.add_theme_color_override("font_color", LOCKED_COLOR)
			links.add_child(unknown)
			continue
		var link := LinkButton.new()
		link.text = CodexData.combo_name(entry, seen)
		link.focus_mode = Control.FOCUS_NONE
		link.pressed.connect(func() -> void: jump(String(entry.id)))
		links.add_child(link)
	if links.get_child_count() == 1:
		caption.text = "Combos: none yet"
	box.add_child(links)
	return box

# The combos, Crowned and Kinships in scope that `root`'s family takes part in.
func family_combos(root: TowerData) -> Array:
	var names := {}
	var statuses := {}
	var todo: Array = [root]
	while not todo.is_empty():
		var data := todo.pop_back() as TowerData
		if data == null or names.has(data.display_name):
			continue
		names[data.display_name] = true
		for status in [data.applies_status, data.extra_status]:
			if status != &"":
				statuses[status] = true
		todo.append_array(data.evolves_to)
	var out: Array = []
	var crowned: Array = [] if ResultsScreen.is_demo() else Array(CodexData.crowned())
	for entry in CodexData.combos() + crowned + CodexData.kinships():
		if not _covered(entry):
			continue
		var takes_part := false
		match entry.kind:
			"Kinship":
				takes_part = entry.line == root.line
			"Crowned":
				takes_part = entry.families.has(root.get_id())
			_:
				if String(entry.by) != "":
					takes_part = Array(String(entry.by).split(", ")).any(func(n: String) -> bool: return names.has(n))
				else:
					takes_part = entry.statuses.any(func(s: StringName) -> bool: return statuses.has(s))
		if takes_part:
			out.append(entry)
	return out

func _form_icon(data: TowerData, shown: bool, side: float) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = WardenIcon.make(data)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(side, side)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if not shown:
		icon.modulate = SILHOUETTE  # A silhouette: the shape, not the Warden
	return icon

# "Dreams: Rolling Thunder, Rain on Glass": the cards this (discovered) entry let into the Dream pool
# (dream_design.md "Discovery unlocks"). Nothing for synergies or entries without cards.
func _add_dreams_line(box: Control, entry: Dictionary) -> void:
	var names := CodexData.dreams_for(CodexData.discovery_key(entry))
	if names.is_empty():
		return
	var line := Label.new()
	line.name = "Dreams"
	line.text = "Dreams: " + ", ".join(names)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.add_theme_font_size_override("font_size", 13)
	line.add_theme_color_override("font_color", GROVE_COLOR)
	box.add_child(line)

# --- Dreams --------------------------------------------------------------------------------------
# Every Dream card (screens_ui.md, Codex "Dreams"): "???" in a plain frame until first offered on this
# account (DreamCodex, profile dreams_seen), then the full card: gem, name, text with status links,
# tags, its Needs (in a run), its Deepened version once that's seen, times taken and runs won with it,
# and a gold "New" until the Dreams page has been viewed. Grouped like "Dreams this run", with rarity /
# group / family filters and "84 / 180 Dreams seen".

var _dreams := VBoxContainer.new()
var _dreams_count := Label.new()
var _rarity_filter := OptionButton.new()
var _group_filter := OptionButton.new()
var _family_filter := OptionButton.new()
var dream_entries := {}  # Card id -> its entry (tests)
const RARITY_NAMES := ["Common", "Uncommon", "Rare", "Legendary"]

func _setup_dreams_page() -> void:
	var page := VBoxContainer.new()
	page.name = "Dreams"
	tabs.add_child(page)
	_dreams_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.caps(_dreams_count, 16)
	page.add_child(_dreams_count)
	var filters := HFlowContainer.new()
	filters.add_theme_constant_override("h_separation", 6)
	page.add_child(filters)
	_rarity_filter.add_item("Any rarity")
	for rarity_name in RARITY_NAMES:
		_rarity_filter.add_item(rarity_name)
	_group_filter.add_item("Any kind")
	for group in DreamsRow.GROUPS:
		_group_filter.add_item(group)
	_family_filter.add_item("Any family")
	for line in IconInfo.DAMAGE_TYPES:
		_family_filter.add_item(IconInfo.damage_type_name(line))
		_family_filter.set_item_metadata(_family_filter.item_count - 1, line)
	for pick in [_rarity_filter, _group_filter, _family_filter]:
		pick.focus_mode = Control.FOCUS_NONE
		pick.custom_minimum_size = Vector2(0, 40)
		pick.item_selected.connect(func(_i: int) -> void: _build_dreams())
		filters.add_child(pick)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_dreams.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dreams.add_theme_constant_override("separation", 8)
	scroll.add_child(_dreams)
	page.add_child(scroll)
	# Viewing the page clears the gold "New" (next time).
	tabs.tab_changed.connect(func(index: int) -> void:
		if tabs.get_tab_control(index) == page:
			DreamCodex.mark_viewed(DreamCodex.seen()))

func _passes_filters(card: UpgradeData) -> bool:
	if _rarity_filter.selected > 0 and card.rarity != _rarity_filter.selected - 1:
		return false
	if _group_filter.selected > 0 and DreamsRow.group_of(card) != DreamsRow.GROUPS[_group_filter.selected - 1]:
		return false
	if _family_filter.selected > 0 and not card.tags.has(String(_family_filter.get_item_metadata(_family_filter.selected))):
		return false
	return true

func _build_dreams() -> void:
	for child in _dreams.get_children():
		_dreams.remove_child(child)
		child.queue_free()
	dream_entries.clear()
	var profile := HeartwoodMemory.load_data()
	var seen: Array = profile.get(DreamCodex.SEEN_KEY, [])
	var viewed: Array = profile.get(DreamCodex.VIEWED_KEY, [])
	var taken: Dictionary = profile.get(DreamCodex.TAKEN_KEY, {})
	var won: Dictionary = profile.get(DreamCodex.WON_KEY, {})
	var cards := DreamCodex.all_cards()
	var seen_count := cards.filter(func(c: UpgradeData) -> bool: return seen.has(c.id)).size()
	_dreams_count.text = "%d / %d Dreams seen" % [seen_count, cards.size()]
	tabs.set_tab_title(3, "Dreams %d / %d" % [seen_count, cards.size()])
	for group in DreamsRow.GROUPS:
		var in_group := cards.filter(func(c: UpgradeData) -> bool: return DreamsRow.group_of(c) == group and _passes_filters(c))
		if in_group.is_empty():
			continue
		var header := Label.new()
		header.text = group
		header.add_theme_font_size_override("font_size", 18)
		header.add_theme_color_override("font_color", TERM_COLOR)
		_dreams.add_child(header)
		for card in in_group:
			var entry := _dream_entry(card, seen, viewed, taken, won)
			_dreams.add_child(entry)
			dream_entries[card.id] = entry

func _dream_entry(card: UpgradeData, seen: Array, viewed: Array, taken: Dictionary, won: Dictionary) -> Control:
	var panel := PanelContainer.new()
	# Moonlit Thread (ui_style.md): a seen card is a card threaded in its rarity colour; an unseen one a
	# plain fog card with no thread (nothing about it is known yet).
	var style := UiStyle.card(UpgradeData.rarity_color(card.rarity))
	style.shadow_size = 0
	style.set_content_margin_all(10)
	if not seen.has(card.id):
		style.thread = MoonStyleBox.TopLine.NONE
		style.glow_color = Color(0, 0, 0, 0)
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	if not seen.has(card.id):  # Never offered: "???", nothing else (no rarity, text or hints)
		var unknown := Label.new()
		unknown.text = "???"
		UiStyle.title(unknown, 20, LOCKED_COLOR)
		box.add_child(unknown)
		return panel
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var gem := DreamsRow.DreamIcon.new()
	gem.card = card
	gem.custom_minimum_size = DreamsRow.ICON_SIZE
	gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(gem)
	var name := Label.new()
	name.text = card.display_name
	UiStyle.title(name, 20, UpgradeData.rarity_color(card.rarity))
	head.add_child(name)
	if not viewed.has(card.id):
		var fresh := Label.new()
		fresh.name = "New"
		fresh.text = "New"
		UiStyle.caps(fresh, 14, UiStyle.GOLD)
		fresh.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(fresh)
	box.add_child(head)
	box.add_child(StatusLinks.make_label(card.description, 15))
	var facts: Array[String] = [RARITY_NAMES[card.rarity], DreamsRow.group_of(card)]
	for tag in card.tags:
		facts.append(IconInfo.damage_type_name(tag) if IconInfo.DAMAGE_TYPES.has(tag) else tag.capitalize())
	var tags := Label.new()
	tags.text = " · ".join(facts)
	UiStyle.caps(tags, 14)  # Plain small caps separated by " · " (ui_style.md "Dream card")
	box.add_child(tags)
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) if is_inside_tree() else null
	if dreams != null and dreams.has_method("needs_text"):
		var needs: String = dreams.needs_text(card)
		if needs != "":
			box.add_child(StatusLinks.make_label(needs, 14, Color("9cd4fc")))  # Dewlight
	if dreams != null and dreams.has_method("opened_clearing") and dreams.opened_clearing(card):
		var opened := Label.new()  # The card that unlocked clearing this run (Roguelite's DreamState)
		opened.name = "OpenedClearing"
		opened.text = DreamState.OPENED_CLEARING_LINE
		UiStyle.caps(opened, 13, UiStyle.GOLD)  # Small caps (lowercases the text)
		box.add_child(opened)
	for other in DreamCodex.all_cards():  # Its Deepened version, once that's been seen too
		if other.deepens == card.id and seen.has(other.id):
			var deeper := Label.new()
			deeper.text = "Deepens into %s" % other.display_name
			deeper.add_theme_font_size_override("font_size", 13)
			deeper.add_theme_color_override("font_color", GROVE_COLOR)
			box.add_child(deeper)
	var stats := Label.new()
	stats.name = "Stats"
	var times := int(taken.get(card.id, 0))
	var wins := int(won.get(card.id, 0))
	stats.text = "Taken %d time%s · won %d run%s with it" % [times, "" if times == 1 else "s", wins, "" if wins == 1 else "s"]
	stats.add_theme_font_size_override("font_size", 13)
	box.add_child(stats)
	return panel

# --- Nightmares (screens_ui.md "Nightmares") ------------------------------------------------------
# Every nightmare and boss, "???" until first met (profile nightmares_seen); a met one shows its
# portrait on a moon disc, name, trait, intro lines and hint, resist / weak / immune icons, health /
# speed / leaves at drift 1, its act and the times you've dispelled it; a boss adds its dossier
# (abilities) and your record. Grouped by act, bosses last; "23 / 34 nightmares met";
# a gold "New" until the page has been opened.

var _nightmares := VBoxContainer.new()
var _nightmares_count := Label.new()
var nightmare_entries := {}  # Kind -> its entry (tests)
var _nightmares_tab := -1

func _setup_nightmares_page() -> void:
	var page := VBoxContainer.new()
	page.name = "Nightmares"
	tabs.add_child(page)
	_nightmares_tab = tabs.get_tab_count() - 1
	_nightmares_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.caps(_nightmares_count, 16)
	page.add_child(_nightmares_count)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_nightmares.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nightmares.add_theme_constant_override("separation", 8)
	scroll.add_child(_nightmares)
	page.add_child(scroll)
	tabs.tab_changed.connect(func(index: int) -> void:
		if tabs.get_tab_control(index) == page:
			NightmareCodex.mark_viewed(NightmareCodex.seen()))

func _build_nightmares() -> void:
	for child in _nightmares.get_children():
		_nightmares.remove_child(child)
		child.queue_free()
	nightmare_entries.clear()
	var profile := HeartwoodMemory.load_data()
	var met: Array = profile.get("nightmares_seen", [])
	var viewed: Array = profile.get(NightmareCodex.VIEWED_KEY, [])
	var dispels: Dictionary = profile.get(NightmareCodex.DISPELS_KEY, {})
	var records: Dictionary = profile.get(BossDossier.RECORDS_KEY, {})
	var kinds := NightmareCodex.all_kinds()
	var met_count := kinds.filter(func(d: EnemyData) -> bool: return met.has(NightmareCodex.kind_of(d))).size()
	_nightmares_count.text = "%d / %d nightmares met" % [met_count, kinds.size()]
	tabs.set_tab_title(_nightmares_tab, "Nightmares %d / %d" % [met_count, kinds.size()])
	var act_names: Array = ["Forest's Edge", "Deep Wood", "Misty Hollow", "Heartwood Glade"]
	var shown_act := 0
	for data in kinds:
		var act := NightmareCodex.act_of(data)
		if act != shown_act:
			shown_act = act
			var header := Label.new()
			header.text = "Act %d · %s" % [act, act_names[act - 1] if act <= act_names.size() else ""]
			header.add_theme_font_size_override("font_size", 18)
			header.add_theme_color_override("font_color", TERM_COLOR)
			_nightmares.add_child(header)
		var entry := _nightmare_entry(data, met, viewed, dispels, records)
		_nightmares.add_child(entry)
		nightmare_entries[NightmareCodex.kind_of(data)] = entry

func _nightmare_entry(data: EnemyData, met: Array, viewed: Array, dispels: Dictionary, records: Dictionary) -> Control:
	var kind := NightmareCodex.kind_of(data)
	var panel := PanelContainer.new()
	var style := UiStyle.card(UiStyle.BOSS if data.is_boss else UiStyle.MOONLIGHT)
	style.shadow_size = 0
	style.set_content_margin_all(10)
	if not met.has(kind):
		style.thread = MoonStyleBox.TopLine.NONE
		style.glow_color = Color(0, 0, 0, 0)
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	if not met.has(kind):  # Never met: "???" only
		var unknown := Label.new()
		unknown.text = "???"
		UiStyle.title(unknown, 20, LOCKED_COLOR)
		box.add_child(unknown)
		return panel
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var face := TextureRect.new()
	face.texture = NightmareCard.portrait(data)
	face.modulate = data.tint
	face.custom_minimum_size = Vector2(52, 52)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(UiStyle.on_moon_disc(face))
	var names := VBoxContainer.new()
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var name := Label.new()
	name.text = data.display_name
	UiStyle.title(name, 20, UiStyle.BOSS.lightened(0.25) if data.is_boss else UiStyle.INK)
	names.add_child(name)
	if data.title != "":
		var title := Label.new()
		title.text = data.title
		UiStyle.whisper(title, 16)
		names.add_child(title)
	head.add_child(names)
	if not viewed.has(kind):
		var fresh := Label.new()
		fresh.name = "New"
		fresh.text = "New"
		UiStyle.caps(fresh, 14, UiStyle.GOLD)
		fresh.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(fresh)
	box.add_child(head)
	var lines: Array[String] = []
	if data.trait_text != "":
		lines.append(data.trait_text)
	lines.append_array(data.get_intro_lines())
	if not lines.is_empty():
		box.add_child(StatusLinks.make_label("\n".join(lines), UiStyle.TIP_SIZE))
	if data.hint != "":
		var hint := Label.new()
		hint.text = data.format_text(data.hint)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiStyle.whisper(hint, 16)
		box.add_child(hint)
	box.add_child(NightmareIcons.make_rows(data, 22.0))
	var facts := Label.new()
	facts.name = "Facts"
	facts.text = "At drift 1: health %d · speed %.1f tiles/s · leaves %d   ·   Act %d" % [data.health, data.speed / 64.0,
		data.leaf_cost, NightmareCodex.act_of(data)]
	UiStyle.number(facts, 15, UiStyle.INK_DIM)
	box.add_child(facts)
	if data.is_boss:  # Its dossier's abilities (no "What helps": the ability and resist rows say enough)
		for i in data.abilities.size():
			var ability := data.get_ability(i)
			var when := String(ability.get("when", ""))
			box.add_child(StatusLinks.make_label("%s%s: %s" % [ability.get("name", ""), " (" + when + ")" if when != "" else "",
				ability.get("text", "")], 15))
	var stats := Label.new()
	stats.name = "Stats"
	var times := int(dispels.get(kind, 0))
	var text := "Dispelled %d time%s" % [times, "" if times == 1 else "s"]
	var record: Dictionary = records.get(kind, {})
	if data.is_boss and not record.is_empty():
		text = "Dispelled %d time%s" % [int(record.get("dispelled", times)), "" if int(record.get("dispelled", times)) == 1 else "s"]
		if float(record.get("best", 0.0)) > 0.0:
			text += " · best time %d s" % roundi(float(record.best))
	stats.text = text
	stats.add_theme_font_size_override("font_size", 14)
	box.add_child(stats)
	return panel
