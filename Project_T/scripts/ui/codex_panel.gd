extends PanelContainer
class_name CodexPanel

# The Codex (screens_ui.md "The Codex: Glossary and Combos"), from the pause menu, the title, the
# Memory Grove and the HUD "?" button. Two tabs:
# - Glossary: every term (CodexData.glossary()), grouped and searchable, with "see also" links that
#   jump (to another term, or to a combo); bosses and late nightmares appear once met
#   (profile nightmares_seen).
# - Combos: all 15 (CodexData.combos()); locked ones are just "???" (no icons: they would give it away);
#   discovered ones (ComboFeedback, profile combos_seen) show what they do, which of your Wardens
#   apply each ingredient, and how often you've set them off. "N / 15 combos discovered".
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

func _build_combos() -> void:
	for child in _combos.get_children():
		child.queue_free()
	var seen := ComboFeedback.load_seen()
	_profile_seen = ComboFeedback.profile_seen()
	_dev_note.visible = MetaRun.is_dev_run()
	var counts: Dictionary = HeartwoodMemory.load_data().get(ComboFeedback.COUNTS_KEY, {})
	var live := get_tree().get_first_node_in_group(ComboFeedback.GROUP) as ComboFeedback if is_inside_tree() else null
	var all := CodexData.combos().filter(CodexData.in_build)  # The demo: only what its 3 families can make
	var found := 0
	for combo in all:
		var discovered := seen.has(String(combo.id))
		if discovered:
			found += 1
		var times := int(counts.get(String(combo.id), 0)) + (int(live._unsaved.get(combo.id, 0)) if live else 0)
		var card := _combo_card(combo, discovered, times)
		_add_card(card, combo.id, discovered)
		_entries[String(combo.id)] = card
	_combo_count.text = "%d / %d combos discovered" % [found, all.size()]
	tabs.set_tab_title(1, "Combos %d / %d" % [found, all.size()])
	_build_kinships(seen, counts, live)
	# Crowned Reactions: hidden ("???" in a gold crown frame) until found; full game only.
	if ResultsScreen.is_demo():
		return
	var crowned := CodexData.crowned().filter(CodexData.in_build)
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

# Adds a combo / Crowned / Kinship card; one found only in a developer run this session gets a small
# "dev" mark in its top-right corner (not saved: screens_ui.md "Saved in the profile").
func _add_card(card: Control, id: StringName, discovered: bool) -> void:
	_combos.add_child(card)
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
func _build_kinships(seen: Array, counts: Dictionary, live: ComboFeedback) -> void:
	var kin := CodexData.kinships().filter(CodexData.in_build)
	if kin.is_empty():
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
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.08, 0.95)
	style.border_color = KIN_COLOR
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
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
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.11, 0.07, 0.95) if discovered else Color(0.06, 0.06, 0.07, 0.95)
	style.border_color = CROWN_COLOR if discovered else Color(0.25, 0.23, 0.18)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
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
