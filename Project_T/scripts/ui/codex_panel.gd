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
var _dev_note := Label.new()
var _profile_seen: Array = []  # Discoveries saved in the profile (the rest are this session's dev ones)
const DEV_COLOR := Color(0.95, 0.7, 0.4)
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
	# Developer runs keep discoveries for the session only (screens_ui.md "Saved in the profile").
	_dev_note.text = "Developer run: discoveries aren't saved"
	_dev_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dev_note.add_theme_font_size_override("font_size", 13)
	_dev_note.add_theme_color_override("font_color", DEV_COLOR)
	_dev_note.visible = false
	box.add_child(_dev_note)
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
	_profile_seen = ComboFeedback.profile_seen()
	_dev_note.visible = MetaRun.is_dev_run()
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
	header.text = "Crowned Reactions  %d / %d" % [crowned_found, crowned.size()]
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

# Adds a combo / Crowned / Kinship card; one found only in a developer run this session gets a small
# "dev" mark in its top-right corner (not saved: screens_ui.md "Saved in the profile").
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
	if discovered and ComboFeedback.is_dev_discovery(id, _profile_seen):
		var mark := Label.new()
		mark.name = "DevMark"
		mark.text = "dev"
		mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mark.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		mark.add_theme_font_size_override("font_size", 12)
		mark.add_theme_color_override("font_color", DEV_COLOR)
		mark.tooltip_text = "Found in a developer run: kept until the game closes, never saved."
		mark.mouse_filter = Control.MOUSE_FILTER_PASS
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
		unknown.add_theme_font_size_override("font_size", 18)
		unknown.add_theme_color_override("font_color", LOCKED_COLOR)
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
