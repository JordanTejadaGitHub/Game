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
const LOCKED_COLOR := UiStyle.OFF
const TERM_COLOR := UiStyle.LIVE
const HIGHLIGHT := Color(UiStyle.LIVE, 0.18)
const CROWN_COLOR := UiStyle.GOLD  # Crowned Reactions: the gold tier
const CROWN_SILHOUETTE := preload("res://assets/effects/crowned_codex_silhouette.png")
const KIN_COLOR := UiStyle.LIVE  # Kinships: green-gold, the forest growing between Wardens
const KIN_FRAME := preload("res://assets/effects/kin_codex_frame.png")
const KIN_LEAF := preload("res://assets/effects/kin_leaf_icon.png")

var tabs := TabContainer.new()
var _search := LineEdit.new()
var _glossary := VBoxContainer.new()
var _glossary_scroll := ScrollContainer.new()
var _group_list := VBoxContainer.new()  # The glossary's groups (left pane)
var _group := ""  # The glossary group shown ("" = the first)
const GROUP_LIST_WIDTH := 230.0
const CARD_ICON := 32.0
const WIDE_CODEX := 1100.0  # Viewport width from which the entry cards sit in two columns
# Each glossary group's icon in the left pane (assets/ui/icons.png ids).
const GROUP_ICONS := {"Resources": &"dew", "The run": &"path_length", "Combat": &"crit_chance", "Wardens": &"rank",
	"Nightmares": &"nightmare", "Statuses": &"damp", "Damage types": &"damage_type", "Dreams": &"dreamlight",
	"The Memory Grove": &"seeds", "Combat callouts": &"crit_damage", "Nightmares you've met": &"nightmare"}
# Terms with an icon of their own (the rest use their group's).
const TERM_ICONS := {"Dew": &"dew", "Dreamlight": &"dreamlight", "Dreamlight shard": &"dreamlight", "Leaves": &"leaves",
	"Seeds": &"seeds", "Rank": &"rank", "Nurture": &"rank", "Potency": &"potency", "Crit": &"crit_chance",
	"Deeply Blighted": &"deeply_blighted", "Hidden": &"hidden", "Flying": &"flying", "Dread shell": &"dread_shell",
	"Omen": &"omen", "Damage type": &"damage_type", "Plain damage": &"plain", "Talon": &"wing",
	"Nurture choice": &"focus_power", "Clear tool": &"dew_cost", "Close call": &"leaves"}
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
	box.custom_minimum_size = Vector2(900, 560)  # Two panes and a two-column card grid
	add_child(box)
	var title := Label.new()
	title.text = "Codex"
	UiStyle.display(title, 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(tabs)

	# The glossary in two panes (screens_ui.md "Glossary and Families, revised"): the groups down the
	# left with an icon each and the search on top; the right pane shows the group's entry cards.
	var glossary_page := HBoxContainer.new()
	glossary_page.name = "Glossary"
	glossary_page.add_theme_constant_override("separation", 12)
	tabs.add_child(glossary_page)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(GROUP_LIST_WIDTH, 0)
	left.add_theme_constant_override("separation", 6)
	glossary_page.add_child(left)
	_search.placeholder_text = "Search terms…"
	_search.custom_minimum_size = Vector2(0, 40)
	_search.text_changed.connect(func(_t: String) -> void: _build_glossary())
	left.add_child(_search)
	var groups_scroll := ScrollContainer.new()
	groups_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	groups_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_group_list.add_theme_constant_override("separation", 4)
	_group_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	groups_scroll.add_child(_group_list)
	left.add_child(groups_scroll)
	_glossary_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_glossary_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_glossary_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_glossary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_glossary.add_theme_constant_override("separation", 10)
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
	_setup_past_runs_page()

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
	_build_past_runs()
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
	if name.begins_with(ComboFeedback.CHAIN_PREFIX) and _entries.has(name):  # A chain tier
		tabs.current_tab = 1
		_focus.call_deferred(_combos_scroll, _entries[name])
		return
	var combo := _find_combo(name)
	if not combo.is_empty():
		tabs.current_tab = 1
		_focus.call_deferred(_combos_scroll, _entries.get(String(combo.id)))
		return
	var group := _group_of(name)
	if not _entries.has(name) or (group != "" and group != _group and _search.text == ""):
		if group != "":
			_group = group
		_search.text = ""
		_build_glossary()
	tabs.current_tab = 0
	_focus.call_deferred(_glossary_scroll, _entries.get(name))

func _focus(scroll: ScrollContainer, target: Control) -> void:
	if not is_instance_valid(target) or not scroll.is_ancestor_of(target):
		return  # Rebuilt since the jump was asked for (the page reopened in the same frame)
	scroll.ensure_control_visible(target)
	var tween := target.create_tween()
	target.modulate = Color(1.6, 1.5, 1.1)  # A multiplier (flash), not a colour
	tween.tween_property(target, "modulate", Color.WHITE, 0.8)

func _find_combo(name: String) -> Dictionary:
	for combo in CodexData.combos() + CodexData.crowned() + CodexData.kinships():
		if String(combo.id) == name or combo.name == name:
			return combo
	return {}

# --- Glossary ------------------------------------------------------------------------------------

# The left pane's group list, and the right pane: the chosen group's cards (or, while searching, every
# match under its group's header). Jumps pick the group holding the term.
func _build_glossary() -> void:
	for child in _glossary.get_children():
		child.queue_free()
	for key in _entries.keys():
		if _find_combo(key).is_empty():
			_entries.erase(key)
	var all_groups: Array = CodexData.glossary()
	var met := get_met_nightmares()
	if not met.is_empty():
		all_groups = all_groups + [["Nightmares you've met", met]]
	if _group == "" or not all_groups.any(func(g: Array) -> bool: return g[0] == _group):
		_group = all_groups[0][0]
	_build_group_list(all_groups)
	var query := _search.text.strip_edges().to_lower()
	if query == "":
		for group in all_groups:
			if group[0] == _group:
				_add_group(group[0], group[1])
		return
	var groups := {}
	for found in CodexData.search(_search.text):
		groups.get_or_add(found[0], []).append(found[1])
	for group in CodexData.glossary():
		if groups.has(group[0]):
			_add_group(group[0], groups[group[0]])
	met = met.filter(func(e: Array) -> bool: return e[0].to_lower().contains(query) or e[1].to_lower().contains(query))
	if not met.is_empty():
		_add_group("Nightmares you've met", met)
	if _glossary.get_child_count() == 0:
		var none := Label.new()
		none.text = "Nothing matches \"%s\"." % _search.text
		_glossary.add_child(none)

# The group containing `term`, or "".
func _group_of(term: String) -> String:
	for group in CodexData.glossary() + [["Nightmares you've met", get_met_nightmares()]]:
		for entry in group[1]:
			if entry[0] == term:
				return group[0]
	return ""

func _build_group_list(all_groups: Array) -> void:
	for child in _group_list.get_children():
		_group_list.remove_child(child)
		child.queue_free()
	for group in all_groups:
		var button := Button.new()
		button.text = "%s  %d" % [group[0], group[1].size()]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = group[0] == _group and _search.text.strip_edges() == ""
		button.focus_mode = Control.FOCUS_NONE
		button.icon = IconInfo.icon(GROUP_ICONS.get(group[0], &"note"))
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.add_theme_constant_override("icon_max_width", 24)
		button.theme_type_variation = &"HudButton"
		button.custom_minimum_size = Vector2(0, 40)
		var name: String = group[0]
		button.pressed.connect(func() -> void:
			_group = name
			if _search.text != "":
				_search.text = ""  # text_changed rebuilds with the group shown
			else:
				_build_glossary())
		_group_list.add_child(button)

# A group's header (the gold thread divider) and its cards in a grid: 2 columns on wide screens.
func _add_group(title: String, entries: Array) -> void:
	var header := Label.new()
	header.text = title
	UiStyle.caps(header, 18, UiStyle.GOLD)
	_glossary.add_child(header)
	_glossary.add_child(HSeparator.new())  # The theme draws it as the MoonDivider thread
	var grid := GridContainer.new()
	grid.columns = 2 if get_viewport_rect().size.x >= WIDE_CODEX else 1
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_glossary.add_child(grid)
	for entry in entries:
		var card := _entry_card(title, entry)
		grid.add_child(card)
		_entries[entry[0]] = card

# One glossary entry as a card: a 32 px icon, the term in the display font, the definition, one muted
# example line, "See also" as gold chips; statuses and damage types add their own lines.
func _entry_card(group: String, entry: Array) -> Control:
	var term: String = entry[0]
	var status := _status_of(term) if group == "Statuses" else &""
	var line := _damage_line_of(term) if group == "Damage types" else ""
	var rim := UiStyle.MOONLIGHT
	if status != &"":
		rim = EnemyStatuses.COLORS.get(status, rim)
	elif line != "":
		rim = IconInfo.damage_type_color(line)
	var card := PanelContainer.new()
	var style := UiStyle.card(rim)
	style.shadow_size = 0  # Many cards in a grid: no drop shadow (as the Dreams tab)
	card.add_theme_stylebox_override("panel", style)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var icon := TextureRect.new()
	icon.texture = _term_icon(group, term, status, line)
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(CARD_ICON, CARD_ICON)
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(icon)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 3)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(body)
	var name := Label.new()
	name.text = term
	UiStyle.display(name, 20)
	name.add_theme_color_override("font_color", TERM_COLOR)
	body.add_child(name)
	var text := StatusLinks.make_label(entry[1], 15)  # Status names are links
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(text)
	var example: String = entry[3] if entry.size() > 3 else ""
	if example != "":
		var muted := Label.new()
		muted.text = example
		muted.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		muted.add_theme_font_size_override("font_size", 15)
		muted.add_theme_color_override("font_color", UiStyle.INK_DIM)
		body.add_child(muted)
	if status != &"":
		_status_extras(body, status)
	if line != "":
		_damage_extras(body, line)
	if entry.size() > 2 and not entry[2].is_empty():
		var links := HFlowContainer.new()
		links.add_theme_constant_override("h_separation", 6)
		for other in entry[2]:
			var combo := _find_combo(other)
			if not combo.is_empty() and not CodexData.is_discovered(combo.id):
				continue  # An undiscovered combo isn't named anywhere (screens_ui.md)
			links.add_child(_chip(other, jump.bind(other)))
		if links.get_child_count() > 0:
			body.add_child(links)
	return card

# A small gold link chip (disabled with no action: a "???" combo).
func _chip(text: String, on_press: Callable = Callable()) -> Button:
	var chip := Button.new()
	chip.text = text
	chip.focus_mode = Control.FOCUS_NONE
	chip.theme_type_variation = &"HudButton"
	chip.add_theme_font_size_override("font_size", 15)
	chip.add_theme_color_override("font_color", UiStyle.GOLD)
	chip.custom_minimum_size = Vector2(0, 40)  # Tappable (ui_style.md small-button minimum)
	if on_press.is_valid():
		chip.pressed.connect(on_press)
	else:
		chip.disabled = true
	return chip

func _status_of(term: String) -> StringName:
	for id in IconInfo.STATUSES:
		if IconInfo.STATUSES[id][0] == term:
			return id
	return &""

func _damage_line_of(term: String) -> String:
	for line in IconInfo.DAMAGE_TYPES:
		if IconInfo.damage_type_name(line) == term:
			return line
	return ""

func _term_icon(group: String, term: String, status: StringName, line: String) -> Texture2D:
	if status != &"":
		var tex := IconInfo.icon(status)
		if tex != null:
			return tex
	if line != "":
		return IconInfo.damage_type_icon(line)
	if TERM_ICONS.has(term):
		return IconInfo.icon(TERM_ICONS[term])
	return IconInfo.icon(GROUP_ICONS.get(group, &"note"))

# A status card's numbers, who applies it (your families' base Wardens) and its combos (??? until found).
func _status_extras(body: VBoxContainer, status: StringName) -> void:
	var numbers: Array[String] = []
	if EnemyStatuses.DEFAULT_MAX_STACKS.has(status):
		var most: int = EnemyStatuses.DEFAULT_MAX_STACKS[status]
		numbers.append("Up to %d stack%s" % [most, "" if most == 1 else "s"])
	if EnemyStatuses.DEFAULT_DURATION.has(status):
		numbers.append("lasts %s s" % str(EnemyStatuses.DEFAULT_DURATION[status]))
	if not numbers.is_empty():
		var label := Label.new()
		label.text = " · ".join(numbers)
		UiStyle.caps(label, 14, UiStyle.INK_DIM)
		body.add_child(label)
	var who := _families_applying(status)
	if not who.is_empty():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var by := Label.new()
		by.text = "Applied by"
		by.add_theme_font_size_override("font_size", 15)
		by.add_theme_color_override("font_color", UiStyle.INK_DIM)
		row.add_child(by)
		for data in who:
			var face := TextureRect.new()
			face.texture = WardenIcon.make(data)
			face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			face.custom_minimum_size = Vector2(24, 24)
			face.tooltip_text = data.display_name
			row.add_child(face)
		body.add_child(row)
	var combos := HFlowContainer.new()
	combos.add_theme_constant_override("h_separation", 6)
	for combo in CodexData.combos():
		if combo.get("statuses", []).has(status) and CodexData.in_build(combo, _scope):
			var found := CodexData.is_discovered(combo.id)
			var status_chip := _chip(combo.name if found else "???", jump.bind(String(combo.id)) if found else Callable())
			status_chip.tooltip_text = StatusLinks.combo_tip_text(combo.id)  # The combo tip (??? until found)
			combos.add_child(status_chip)
	if combos.get_child_count() > 0:
		body.add_child(combos)

# The base Wardens (families in this Codex's scope) whose family applies `status`.
func _families_applying(status: StringName) -> Array[TowerData]:
	var out: Array[TowerData] = []
	for family in CodexData.FAMILY_NAMES:
		if _scope.has("families") and not _scope.families.has(family):
			continue
		var path := "res://resource/tower/%s.tres" % family
		if not ResourceLoader.exists(path):
			continue
		var root := load(path) as TowerData
		if root != null and _family_applies(root, status):
			out.append(root)
	return out

func _family_applies(root: TowerData, status: StringName) -> bool:
	var seen := {}
	var stack: Array = [root]
	while not stack.is_empty():
		var data := stack.pop_back() as TowerData
		if data == null or seen.has(data.get_id()):
			continue
		seen[data.get_id()] = true
		if data.applies_status == status or data.get("extra_status") == status:
			return true
		for next in data.evolves_to:
			stack.append(next)
	return false

# A damage type card: the nightmares weak to it and resisting it (??? until met).
func _damage_extras(body: VBoxContainer, line: String) -> void:
	var seen := NightmareCodex.seen()
	for side in [["Weak to it", "weak_to"], ["Resist it", "resists"]]:
		var kinds := NightmareCodex.all_kinds().filter(func(d: EnemyData) -> bool: return (d.get(side[1]) as Array).has(line))
		if kinds.is_empty():
			continue
		var row := HFlowContainer.new()
		row.add_theme_constant_override("h_separation", 4)
		var label := Label.new()
		label.text = side[0]
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", UiStyle.INK_DIM)
		row.add_child(label)
		for data in kinds.slice(0, 10):
			if seen.has(NightmareCodex.kind_of(data)):
				var face := TextureRect.new()
				face.texture = NightmareCard.portrait(data)
				face.modulate = data.tint
				face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				face.custom_minimum_size = Vector2(24, 24)
				face.tooltip_text = data.display_name
				row.add_child(face)
			else:
				var unknown := Label.new()
				unknown.text = "???"
				unknown.add_theme_font_size_override("font_size", 15)
				unknown.add_theme_color_override("font_color", LOCKED_COLOR)
				row.add_child(unknown)
		body.add_child(row)

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
const GROVE_COLOR := Palette.SPRIG
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
	# Counters show the real total (screens_ui.md "Counter shows the real total"): every combo in the
	# game; the ones your families can't make yet are "???" under "N more wait in the Memory Grove".
	# The demo counts and lists only its own (its Grove is asleep: nothing "waits" there).
	var counted := all if ResultsScreen.is_demo() else every
	var found := counted.filter(func(c: Dictionary) -> bool: return seen.has(String(c.id))).size()
	for combo in all:
		var discovered := seen.has(String(combo.id))
		var times := int(counts.get(String(combo.id), 0)) + (int(live._unsaved.get(combo.id, 0)) if live else 0)
		var card := _combo_card(combo, discovered, times)
		_add_card(card, combo.id, discovered)
		_entries[String(combo.id)] = card
	_add_waiting(every.size() - all.size())
	_add_locked(every.filter(func(c: Dictionary) -> bool: return not _covered(c)), seen,
		func(c: Dictionary, discovered: bool) -> Control: return _combo_card(c, discovered, int(counts.get(String(c.id), 0))))
	_combo_count.text = "%d / %d combos discovered" % [found, counted.size()]
	tabs.set_tab_title(1, "Combos %d / %d" % [found, counted.size()])
	_build_chains(live)
	_build_kinships(seen, counts, live, kin_all)
	# Crowned Reactions: hidden ("???" in a gold crown frame) until found; full game only.
	if ResultsScreen.is_demo():
		return
	var crowned := crowned_all.filter(_covered)
	var crowned_found := crowned_all.filter(func(c: Dictionary) -> bool: return seen.has(String(c.id))).size()
	var header := Label.new()
	header.text = "Crowned Reactions · %d / %d" % [crowned_found, crowned_all.size()]
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
	_add_locked(crowned_all.filter(func(c: Dictionary) -> bool: return not _covered(c)), seen,
		func(c: Dictionary, discovered: bool) -> Control: return _crowned_card(c, discovered, int(counts.get(String(c.id), 0))))

# The entries your Grove doesn't reach yet, under the "wait in the Memory Grove" line: "???" (shown
# in full if the profile found one anyway, e.g. in a developer run).
func _add_locked(entries: Array, seen: Array, make: Callable) -> void:
	if ResultsScreen.is_demo():
		return
	for entry in entries:
		var discovered := seen.has(String(entry.id))
		var card: Control = make.call(entry, discovered)
		card.set_meta(&"waiting", true)  # Out of the Grove's reach (tests)
		_combos.add_child(card)
		_entries[String(entry.id)] = card

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
	if kin_all.is_empty():
		return
	var kin_counted := kin if ResultsScreen.is_demo() else kin_all
	var found := kin_counted.filter(func(k: Dictionary) -> bool: return seen.has(String(k.id))).size()
	var header := Label.new()
	header.text = "Kinships %d / %d" % [found, kin_counted.size()]  # The real total (screens_ui.md "Counter shows the real total")
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
	_add_locked(kin_all.filter(func(k: Dictionary) -> bool: return not _covered(k)), seen,
		func(k: Dictionary, discovered: bool) -> Control: return _kinship_card(k, discovered, int(counts.get(String(k.id), 0))))

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
	name.text = "%s · Kinship" % k.name
	name.add_theme_font_size_override("font_size", 18)
	name.add_theme_color_override("font_color", KIN_COLOR)
	row.add_child(name)
	inner.add_child(row)
	var pair := Label.new()
	pair.text = "%s + %s" % [k.a, k.b]
	pair.add_theme_font_size_override("font_size", 14)
	pair.add_theme_color_override("font_color", UiStyle.LIVE)
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
	panel.add_theme_stylebox_override("panel", UiStyle.panel_in(CROWN_COLOR if discovered else Palette.DEEPMOSS))
	var box := VBoxContainer.new()
	panel.add_child(box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	box.add_child(row)
	if not discovered:
		row.add_child(_crowned_silhouette(c))  # Only the crown frame while undiscovered
	else:
		var own := IconInfo.icon(StringName(c.id))  # The Crowned Reaction's own icon (UI Asset), ×2
		if own != null:
			var reaction_icon := TextureRect.new()
			reaction_icon.texture = own
			reaction_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			reaction_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			reaction_icon.custom_minimum_size = Vector2(32, 32)
			row.add_child(reaction_icon)
		for family in c.families:
			var icon := TextureRect.new()
			icon.texture = CodexData.family_icon(family)
			icon.custom_minimum_size = Vector2(28, 28)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.tooltip_text = CodexData.FAMILY_NAMES.get(family, family)
			row.add_child(icon)
	var name := Label.new()
	name.text = "%s · Crowned" % c.name if discovered else "???"
	name.add_theme_font_size_override("font_size", 18)
	name.add_theme_color_override("font_color", CROWN_COLOR if discovered else LOCKED_COLOR)
	row.add_child(name)
	var families: Array[String] = []
	for family in c.families:
		families.append(CodexData.FAMILY_NAMES.get(family, family))
	if discovered:  # Locked: the crown frame and "???" only
		var hint := Label.new()
		hint.text = "%s · %s" % [CodexData.crowned_recipe(c), ", ".join(families)]
		hint.add_theme_font_size_override("font_size", 14)
		hint.add_theme_color_override("font_color", UiStyle.WHISPER)
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
		var own := IconInfo.icon(StringName(combo.id))  # A Reaction's own icon (UI Asset), ×2
		if own != null:
			var icon := TextureRect.new()
			icon.texture = own
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.custom_minimum_size = Vector2(32, 32)
			row.add_child(icon)
		for status in combo.statuses:
			row.add_child(StatusIcon.new(status))
	var name := Label.new()
	name.text = "%s · %s" % [combo.name, combo.kind] if discovered else "???"
	name.add_theme_font_size_override("font_size", 18)
	var reaction := Reactions.get_data(combo.id)
	name.add_theme_color_override("font_color", (reaction.callout_color if reaction else TERM_COLOR) if discovered else LOCKED_COLOR)
	row.add_child(name)
	if not discovered:
		return panel  # Just "???" (no ingredients either)
	box.add_child(StatusLinks.make_label(CodexData.ingredients_text(combo), 14, Palette.DEWLIGHT))
	box.add_child(StatusLinks.make_label(combo.text, 15))  # Status names are links
	var by := Label.new()
	by.text = get_sources_text(combo)
	by.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	by.add_theme_font_size_override("font_size", 13)
	by.add_theme_color_override("font_color", UiStyle.LIVE)
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
		UiStyle.release_at_exit(func() -> void: _wardens.clear())
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

const SILHOUETTE := Color(UiStyle.FOG, 0.9)

# The Families page (screens_ui.md "Families page, updated"): one tab per family (the base Warden's
# portrait), then the family: a header (the base Warden large and animated, damage type, its role in
# one line, its statuses, your record), its tree drawn like the Remember screen (tier, Dew to grow,
# Dreamlight to unlock, Grove state; tapping a node shows its card), and under it its Kinships, combos
# and Dream cards. Every number comes from the data (TowerData / DreamState constants).
var _family := ""  # The family shown
var _family_body := VBoxContainer.new()
var _family_card := VBoxContainer.new()  # The tapped node's card, under the tree
const FAMILY_ROLES := {
	"sporeling": "Damage over time: stack {spored} and keep it.",
	"dewdrop": "Water: splash, fog and ice. {damp} nightmares conduct lightning.",
	"firefly_jar": "Light: lightning, marking and beams. {static} builds to free bolts; {marked} nightmares take more.",
	"pebbling": "Heavy hits: slow, powerful shots for the toughest nightmares.",
	"rootling": "Control: {held} nightmares in place, and pull them back.",
	"bellflower": "Song and sleep: sing nightmares {drowsy}, then {asleep}.",
	"acorn": "Support and economy: auras for the Wardens around it, and Dew.",
	"nestling": "Birds: fast hunters for the quickest nightmares.",
	"whirligig": "Wind: spread one nightmare's statuses to the crowd.",
}
const TREE_W := 640.0
const TREE_H := 380.0
const NODE_W := 120.0
const NODE_H := 108.0
const NODE_PORTRAIT := 56.0

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
	var roots: Array[TowerData] = []
	for id in ids:
		var path: String = TOWER_DIR + id + ".tres"
		if ResourceLoader.exists(path):
			roots.append(load(path))
	if roots.is_empty():
		return
	if _family == "" or not roots.any(func(r: TowerData) -> bool: return r.get_id() == _family):
		_family = roots[0].get_id()
	var tab_row := HFlowContainer.new()
	tab_row.add_theme_constant_override("h_separation", 6)
	_families.add_child(tab_row)
	for root in roots:
		var tab := Button.new()
		tab.toggle_mode = true
		tab.button_pressed = root.get_id() == _family
		tab.focus_mode = Control.FOCUS_NONE
		tab.theme_type_variation = &"HudButton"
		tab.icon = WardenIcon.make(root)
		tab.expand_icon = true
		tab.add_theme_constant_override("icon_max_width", 32)
		tab.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tab.text = root.display_name
		tab.custom_minimum_size = Vector2(0, 48)
		var id := root.get_id()
		tab.pressed.connect(func() -> void:
			_family = id
			_build_families())
		tab_row.add_child(tab)
		family_cards[id] = tab
	_families.add_child(HSeparator.new())
	for root in roots:
		if root.get_id() == _family:
			_families.add_child(_family_page(root))

func _family_page(root: TowerData) -> Control:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	page.add_child(_family_header(root))
	var tree := FamilyTree.new(self, root)
	tree.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	page.add_child(tree)
	for child in _family_card.get_children():
		child.queue_free()
	if _family_card.get_parent() != null:
		_family_card.get_parent().remove_child(_family_card)
	page.add_child(_family_card)
	_show_form_card(root)
	page.add_child(_family_links(root))
	return page

func _family_header(root: TowerData) -> Control:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	var portrait := RememberScreen.Portrait.new(root, 112.0)
	head.add_child(portrait)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(box)
	var name := Label.new()
	name.text = "%s family" % root.display_name
	UiStyle.display(name, 28)
	name.add_theme_color_override("font_color", TERM_COLOR)
	box.add_child(name)
	var kind := Label.new()
	kind.text = IconInfo.damage_type_text(root.line)
	UiStyle.caps(kind, 15, IconInfo.damage_type_color(root.line))
	box.add_child(kind)
	var role := StatusLinks.make_label(IconInfo.format(FAMILY_ROLES.get(root.get_id(), root.description)), 16)  # Status words are links
	role.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(role)
	var statuses := _family_statuses(root)
	if not statuses.is_empty():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		for status in statuses:
			row.add_child(IconInfo.make_icon(status, 2))
		box.add_child(row)
	var record := Label.new()
	record.text = _family_record(root.get_id())
	record.add_theme_font_size_override("font_size", 15)
	record.add_theme_color_override("font_color", UiStyle.INK_DIM)
	box.add_child(record)
	return head

# Every status the family applies, in growth order.
func _family_statuses(root: TowerData) -> Array[StringName]:
	var out: Array[StringName] = []
	for data in _family_forms(root):
		for status in [data.applies_status, data.get("extra_status")]:
			if status != null and status != &"" and not out.has(status):
				out.append(status)
	return out

# The root and every form it grows into (each once), breadth first.
func _family_forms(root: TowerData) -> Array[TowerData]:
	var out: Array[TowerData] = []
	var todo: Array = [root]
	var done := {}
	while not todo.is_empty():
		var data := todo.pop_front() as TowerData
		if data == null or done.has(data.get_id()):
			continue
		done[data.get_id()] = true
		out.append(data)
		todo.append_array(data.evolves_to)
	return out

# "Picked in 4 of your last 12 runs · won 1 with it" (RunHistory, normal runs only).
func _family_record(id: String) -> String:
	var runs := RunHistory.load_runs().filter(func(r: Dictionary) -> bool: return String(r.get("dev", "")) == "")
	if runs.is_empty():
		return "No runs recorded yet."
	var picked := 0
	var won := 0
	for run in runs:
		var chose: bool = run.get("family_picks", []).any(func(p: Dictionary) -> bool: return String(p.get("chosen", "")) == id)
		if chose:
			picked += 1
			if run.get("won", false):
				won += 1
	return "Picked in %d of your last %d runs · won %d with it" % [picked, runs.size(), won]

# A form's state for the tree: planted in the Codex's scope, or waiting in the Memory Grove.
func _form_in_scope(data: TowerData) -> bool:
	return _scope.get("all", false) or _scope.get("wardens", []).has(data.get_id())

static func tier_name(data: TowerData) -> String:
	if data.buildable_directly:
		return "Base"
	match data.tier:
		4:
			return "Ascended"
		3:
			return "Final form"
	return "Branch"

# "Branch · 120 Dew · 1 Dreamlight" (from the data).
static func form_costs(data: TowerData) -> String:
	if data.buildable_directly:
		return "Base · %d Dew" % data.cost
	var dreamlight: int = DreamState.ASCENDED_DREAMLIGHT if data.tier >= DreamState.ASCENDED_TIER \
		else (DreamState.FINAL_DREAMLIGHT if data.tier >= 3 else DreamState.BRANCH_DREAMLIGHT)
	return "%s · %d Dew · %d Dreamlight" % [tier_name(data), data.evolve_cost, dreamlight]

# The tapped form's card under the tree (the Warden panel's top half when Tower Code's shared
# builder lands; until then: portrait, name, tier and costs, stats, the description with links).
func _show_form_card(data: TowerData) -> void:
	for child in _family_card.get_children():
		child.queue_free()
	var shown := _form_in_scope(data)
	var panel := PanelContainer.new()
	var style := UiStyle.card(IconInfo.damage_type_color(data.line))
	style.shadow_size = 0
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	if not shown:  # A known form's portrait and name come with its WardenHeaderView
		row.add_child(RememberScreen.Portrait.new(data, 72.0, true))
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 3)
	row.add_child(box)
	if not shown:
		var name := Label.new()
		name.text = "???"
		UiStyle.display(name, 22)
		box.add_child(name)
	var costs := Label.new()
	costs.text = form_costs(data) + ("" if shown else " · in the Memory Grove")
	UiStyle.caps(costs, 14, UiStyle.GOLD if shown else GROVE_COLOR)
	box.add_child(costs)
	if shown:
		# The Warden panel's top half (Tower Code's shared WardenHeaderView): stats, statuses, Potency, Grows into.
		var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState if is_inside_tree() else null
		box.add_child(WardenHeaderView.build(data, null, dreams, true))
	else:
		var wait := Label.new()
		wait.text = "Plant it in the Memory Grove to meet it."
		wait.add_theme_font_size_override("font_size", 15)
		wait.add_theme_color_override("font_color", GROVE_COLOR)
		box.add_child(wait)
	_family_card.add_child(panel)

# Under the tree: its Kinships (pair, bond, stages), its combos as chips (??? until found), and its
# Dream cards (a count, linking to the Dreams tab).
func _family_links(root: TowerData) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	var seen := ComboFeedback.load_seen()
	var kin := CodexData.kinships().filter(func(k: Dictionary) -> bool: return k.line == root.line and _covered(k))
	if not kin.is_empty():
		var header := Label.new()
		header.text = "Kinships"
		UiStyle.caps(header, 16, KIN_COLOR)
		box.add_child(header)
		for k in kin:
			var line := Label.new()
			var found := seen.has(String(k.id))
			line.text = ("%s · %s + %s · Sapling, Blooming, Old Kin" % [k.name, k.a, k.b]) if found else "??? · %s + %s" % [k.a, k.b]
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.add_theme_font_size_override("font_size", 15)
			box.add_child(line)
	var combos := HFlowContainer.new()
	combos.add_theme_constant_override("h_separation", 6)
	var caption := Label.new()
	caption.text = "Combos"
	UiStyle.caps(caption, 16, UiStyle.GOLD)
	box.add_child(caption)
	for entry in family_combos(root):
		if entry.get("kind", "") == "Kinship":
			continue
		var found := CodexData.is_discovered(entry.id, seen)
		var family_chip := _chip(CodexData.combo_name(entry, seen) if found else "???", jump.bind(String(entry.id)) if found else Callable())
		family_chip.tooltip_text = StatusLinks.combo_tip_text(entry.id)  # The combo tip (??? until found)
		combos.add_child(family_chip)
	if combos.get_child_count() == 0:
		var none := Label.new()
		none.text = "None in reach yet."
		none.add_theme_font_size_override("font_size", 15)
		combos.add_child(none)
	box.add_child(combos)
	var cards := _family_dream_count(root)
	if cards > 0:
		box.add_child(_chip("%d Dream card%s for this family" % [cards, "" if cards == 1 else "s"], func() -> void:
			for i in tabs.get_tab_count():
				if tabs.get_tab_control(i).name == "Dreams":
					tabs.current_tab = i))
	return box

# Dream cards that name this family: its damage type or Warden line, a family requirement or call.
func _family_dream_count(root: TowerData) -> int:
	var forms := _family_forms(root).map(func(d: TowerData) -> String: return d.get_id())
	var count := 0
	for card in DreamCodex.all_cards():
		var hit := false
		for field in ["stat_line", "count_line"]:
			if String(card.get(field)) == root.line:
				hit = true
		for field in ["calls_family", "count_warden", "stat_warden", "set_cost_warden"]:
			if forms.has(String(card.get(field))):
				hit = true
		var needs = card.get("requires")
		if needs is Array and needs.any(func(r) -> bool: return forms.has(String(r))):
			hit = true
		if hit:
			count += 1
	return count

# The family's tree, drawn like the Remember screen: the base at the bottom, its branches, their
# finals, then the Ascended form at the top; lines between; each node a portrait on its waystone with
# its name and costs, a silhouette while it waits in the Memory Grove. Tapping one shows its card.
class FamilyTree extends Control:
	var codex: CodexPanel
	var nodes := {}  # TowerData -> Button
	var edges: Array = []

	func _init(owner_codex: CodexPanel, root: TowerData) -> void:
		codex = owner_codex
		custom_minimum_size = Vector2(TREE_W, TREE_H)
		mouse_filter = Control.MOUSE_FILTER_PASS
		var branches: Array = root.evolves_to.filter(func(d) -> bool: return d is TowerData)
		var ascended: TowerData = null
		for branch in branches:
			for final_form in branch.evolves_to:
				for next in final_form.evolves_to:
					if next is TowerData and next.tier >= DreamState.ASCENDED_TIER:
						ascended = next
		var rows := 4 if ascended != null else 3
		_place(root, Vector2(TREE_W / 2.0, _row_y(0, rows)))
		for i in branches.size():
			var lane_x := TREE_W * (i + 1) / float(branches.size() + 1)
			var branch: TowerData = branches[i]
			_place(branch, Vector2(lane_x, _row_y(1, rows)))
			edges.append([root, branch])
			var finals: Array = branch.evolves_to.filter(func(d) -> bool: return d is TowerData and d.tier < DreamState.ASCENDED_TIER)
			for j in finals.size():
				var spread := (j - (finals.size() - 1) / 2.0) * (NODE_W * 0.9)
				_place(finals[j], Vector2(lane_x + spread, _row_y(2, rows)))
				edges.append([branch, finals[j]])
				if ascended != null and finals[j].evolves_to.has(ascended):
					edges.append([finals[j], ascended])
		if ascended != null:
			_place(ascended, Vector2(TREE_W / 2.0, _row_y(3, rows)))

	func _row_y(row: int, rows: int) -> float:
		var span := TREE_H - NODE_H
		return span - row * span / float(maxi(rows - 1, 1))

	func _place(data: TowerData, centre_top: Vector2) -> void:
		if nodes.has(data):
			return
		var shown := codex._form_in_scope(data)
		var node := Button.new()
		node.flat = true
		node.focus_mode = Control.FOCUS_NONE
		node.custom_minimum_size = Vector2(NODE_W, NODE_H)
		node.size = Vector2(NODE_W, NODE_H)
		node.position = Vector2(centre_top.x - NODE_W / 2.0, centre_top.y)
		node.tooltip_text = (data.display_name if shown else "In the Memory Grove") + "\n" + CodexPanel.form_costs(data)
		var portrait := RememberScreen.Portrait.new(data, NODE_PORTRAIT, not shown)
		portrait.position = Vector2((NODE_W - NODE_PORTRAIT) / 2.0, 2.0)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(portrait)
		var name := Label.new()
		name.text = data.display_name if shown else "???"
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.position = Vector2(0, NODE_PORTRAIT + 4.0)
		name.size = Vector2(NODE_W, 20)
		name.add_theme_font_size_override("font_size", 15)
		name.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(name)
		var costs := Label.new()
		costs.text = ("%s · %d" % [CodexPanel.tier_name(data), data.cost]) if data.buildable_directly \
			else ("%d Dew · %d ✦" % [data.evolve_cost, DreamState.ASCENDED_DREAMLIGHT if data.tier >= DreamState.ASCENDED_TIER \
				else (DreamState.FINAL_DREAMLIGHT if data.tier >= 3 else DreamState.BRANCH_DREAMLIGHT)])
		costs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		costs.position = Vector2(0, NODE_PORTRAIT + 24.0)
		costs.size = Vector2(NODE_W, 18)
		costs.add_theme_font_size_override("font_size", 14)
		costs.add_theme_color_override("font_color", UiStyle.GOLD if shown else GROVE_COLOR)
		costs.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.add_child(costs)
		node.pressed.connect(func() -> void: codex._show_form_card(data))
		add_child(node)
		nodes[data] = node

	func _centre(data: TowerData) -> Vector2:
		var node: Control = nodes[data]
		return node.position + Vector2(NODE_W / 2.0, NODE_PORTRAIT / 2.0 + 2.0)

	func _draw() -> void:
		for edge in edges:
			if not nodes.has(edge[0]) or not nodes.has(edge[1]):
				continue
			var lit: bool = codex._form_in_scope(edge[1])
			draw_line(_centre(edge[0]), _centre(edge[1]), Color(UiStyle.GOLD, 0.55) if lit else Color(UiStyle.INK_DIM, 0.35), 3.0, true)
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
	if CardDiagram.has_diagram(card):  # Placement cards show their diagram (dream_design.md)
		box.add_child(CardDiagram.make(card))
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
	if data.is_boss:  # "It must feel like THE boss" (screens_ui.md "Boss dossier"): the same eyebrow
		names.add_child(BossDossier.eyebrow(NightmareCodex.act_of(data), 13))
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
	facts.text = "At drift 1: health %d · speed %.1f tiles/s · leaves %d · Act %d" % [data.health, data.speed / 64.0,
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

# --- Past runs (balance_simulation.md "Run history") ----------------------------------------------
# The saved runs (RunHistory, user://run_history.json), newest first, dev runs marked, each with a
# "Copy run report" button (for the design chat).

var _past_runs := VBoxContainer.new()
var past_run_entries: Array = []  # (tests)

func _setup_past_runs_page() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "Past runs"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_past_runs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_past_runs.add_theme_constant_override("separation", 8)
	scroll.add_child(_past_runs)
	tabs.add_child(scroll)

func _build_past_runs() -> void:
	for child in _past_runs.get_children():
		_past_runs.remove_child(child)
		child.queue_free()
	past_run_entries.clear()
	var runs := RunHistory.load_runs()
	if runs.is_empty():
		var none := Label.new()
		none.text = "No runs yet."
		UiStyle.caps(none, 16)
		_past_runs.add_child(none)
		return
	for record in runs:
		var entry := _past_run_entry(record)
		_past_runs.add_child(entry)
		past_run_entries.append(entry)

func _past_run_entry(record: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var won: bool = record.get("won", false)
	var style := UiStyle.card(UiStyle.GOLD if won else UiStyle.MOONLIGHT)
	style.shadow_size = 0
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	var title := Label.new()
	title.name = "Title"
	var result := String(record.get("result", "")).capitalize()
	title.text = "%s · drift %d · %s" % [result, int(record.get("survived", 0)), RunHistory._time_text(float(record.get("seconds", 0.0)))]
	UiStyle.title(title, 18, UiStyle.GOLD if won else UiStyle.INK)
	head.add_child(title)
	if String(record.get("dev", "")) != "":
		var dev := Label.new()
		dev.name = "Dev"
		dev.text = "dev · %s" % record.dev
		UiStyle.caps(dev, 13, UiStyle.INK_DIM)
		dev.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(dev)
	box.add_child(head)
	var picks: Array = record.get("family_picks", []).map(func(p: Dictionary) -> String: return String(p.chosen).capitalize())
	var top: Array = record.get("top", [])
	var lines: Array[String] = [String(record.get("date", "")).replace("T", " ").left(16)]
	if not picks.is_empty():
		lines.append("Families: " + ", ".join(picks))
	if not top.is_empty():
		lines.append("Top Warden: %s (%d%%)" % [top[0].name, roundi(float(top[0].share) * 100.0)])
	lines.append("Leaves lost: %d · Dreams: %d · Blight %d" % [record.get("leaves_lost_by_act", {}).values().reduce(func(a, b): return a + b, 0),
		record.get("dreams_taken", []).size(), int(record.get("blight", 0))])
	var body := Label.new()
	body.text = "\n".join(lines)
	body.add_theme_font_size_override("font_size", 14)
	box.add_child(body)
	var copy := Button.new()
	copy.name = "Copy"
	copy.text = "Copy run report"
	copy.focus_mode = Control.FOCUS_NONE
	copy.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	copy.pressed.connect(func() -> void:
		DisplayServer.clipboard_set(RunHistory.report_text(record))
		copy.text = "Copied")
	box.add_child(copy)
	return panel

# Chains (screens_ui.md "Combo discovery" → "Chains are discovered too"): the three tiers, "???"
# until reached, and the longest chain ever with its Reactions in order.
func _build_chains(live: ComboFeedback) -> void:
	var seen: Array = ComboFeedback.chains_seen()
	var best: Dictionary = ComboFeedback.chain_best()
	if live != null:
		for tier in live._chains_seen:
			if not seen.has(tier):
				seen.append(tier)
		if int(live._best_this_session.get("links", 0)) > int(best.get("links", 0)):
			best = live._best_this_session
	# One entry, then the longest chain (screens_ui.md "Chains: one discovery, then Dawnbreak": no tier list).
	var header := Label.new()
	header.text = "Chains"
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", TERM_COLOR)
	_combos.add_child(header)
	var card := PanelContainer.new()
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if seen.any(func(s) -> bool: return String(s).is_valid_int()):
		label.text = "Chain\n" + ComboFeedback.CHAIN_LINE
	else:
		label.text = "???"
		label.add_theme_color_override("font_color", LOCKED_COLOR)
	card.add_child(label)
	_combos.add_child(card)
	_entries[ComboFeedback.CHAIN_PREFIX + str(ComboFeedback.CHAIN_TIERS[0])] = card
	var links := int(best.get("links", 0))
	if links >= 2:
		var line := Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var order: Array = best.get("reactions", [])
		line.text = "Longest chain ever: Chain %d%s" % [links, ("\n" + " → ".join(order)) if not order.is_empty() else ""]
		_combos.add_child(line)
