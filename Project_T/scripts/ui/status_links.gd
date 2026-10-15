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
const NIGHTMARE_PREFIX := "nightmare:"  # Nightmares ({nightmare:shellbound}): portrait, name, trait; a click opens its NightmareCard; ??? until met
const COMBO_PREFIX := "combo:"  # Combos ({combo:thunderclap}): name, statuses, what it does, times set off; ??? until found
const CARD_PREFIX := "card:"  # Dream cards named in text ({card:flurry}): name, rarity gem, description. Never a status link (text_pass.md "Card names in text are links")
const OMEN_PREFIX := "omen:"  # Omens ({omen:static_sky}): name and what it does
const WARDEN_PREFIX := "warden:"  # Wardens ({warden:graftling}): portrait, name, role line and description
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
var _is_nightmare := false  # _status is a nightmare kind
var _more := LinkButton.new()  # "More in the Codex" (not for nightmares: a click on the word opens its card)
var _host: Control = null  # The label the popup belongs to (it draws on the tip layer)
var _hide_in := -1.0
var _gem := Control.new()  # A card link's rarity gem (drawn; hidden for everything else)
var _gem_rarity := 0
var _shown_meta := ""  # The link the popup shows (a tap on the same card link closes it)
# Phones (TouchBuild.is_touch(); Mobile UI, user 2026-10-15 "make sure touch works with underlined words"): no hover, a
# touch anywhere outside the tip closes it; when that touch was on the word it shows, its tap must not open it again.
const TOUCH_REOPEN_MS := 700
var _touch_closed_meta := ""
var _touch_closed_ms := 0

# `text` with every status name (and {damp}-style token) and every term token ({block}, {Drifts} …)
# as a [url] link, other "[" escaped.
static func bbcode(text: String) -> String:
	_seen.clear()  # A keyword is a link the first time it appears in a block (text_pass.md "Keywords are always links")
	# Term tokens first, as placeholders (no letters: the status pattern never matches inside them).
	var terms: Array = []
	if text.contains("{"):
		for token in IconInfo.term_tokens():
			while text.contains(token[0]):
				text = text.replace(token[0], "\u0001%d\u0001" % terms.size())
				terms.append(token[2] if _own(token[1]) else _once(TERM_PREFIX + String(token[1]), token[2]))
		for found in IconInfo.family_pattern().search_all(text):  # {family:dewdrop}
			var id := found.get_string(1)
			var data := IconInfo.family_data(id)
			text = text.replace(found.get_string(), "\u0001%d\u0001" % terms.size())
			terms.append(_once(FAMILY_PREFIX + id, data.display_name if data != null else id.capitalize()))
		for found in IconInfo.card_pattern().search_all(text):  # {card:charged_feathers}, {omen:static_sky}: plain, never a status link
			text = text.replace(found.get_string(), "\u0001%d\u0001" % terms.size())
			terms.append(_once(found.get_string(1) + ":" + found.get_string(2), IconInfo.card_name(found.get_string(2), found.get_string(1)).replace("[", "[lb]")))
		for found in _combo_pattern().search_all(text):  # {combo:thunderclap}: its name, or ??? until found
			text = text.replace(found.get_string(), "\u0001%d\u0001" % terms.size())
			terms.append(combo_link(StringName(found.get_string(1)), found.get_string().begins_with("{named_")))
	# Terms written as plain words (user: "Potency in cards doesn't have the underline"): whole word, any case, singular
	# or plural, linked as written ("A dread shell", "Dread shells").
	for id in auto_terms():  # Longest word first: a shorter keyword never links inside a longer one ("Crowned Reaction")
		if _own(id) or text.findn(String(IconInfo.TERMS[id][0])) < 0:
			continue  # Its own glossary entry, or not in this text
		var linked := ""
		var at := 0
		for found in _plain_pattern(id).search_all(text):
			var before := text.substr(0, found.get_start())
			if (LONGER_TERMS.get(id, []) as Array).any(func(lead: String) -> bool: return before.to_lower().ends_with(lead.to_lower())):
				continue  # Part of a longer term, which is its own entry
			linked += text.substr(at, found.get_start() - at) + "\u0001%d\u0001" % terms.size()
			terms.append(_once(TERM_PREFIX + String(id), found.get_string()))
			at = found.get_end()
		text = linked + text.substr(at)
	if text.contains("{nightmare:"):  # {nightmare:shellbound}: its name, ??? until met; a click opens its card
		for found in IconInfo.nightmare_pattern().search_all(text):
			var kind := found.get_string(1)
			text = text.replace(found.get_string(), "\u0001%d\u0001" % terms.size())
			terms.append(_once(NIGHTMARE_PREFIX + kind, IconInfo.nightmare_name(kind)))
	text = _statuses(IconInfo.format(text).replace("[", "[lb]"), true)
	for i in terms.size():
		text = text.replace("\u0001%d\u0001" % i, terms[i])
	return text

# Keywords linked wherever their word appears, token or not (text_pass.md "Keywords are always links"): IconInfo.TERMS
# ids. Only words that mean one thing in this game: a keyword that is also an ordinary word (full, grow, act, stack,
# family, branch, node, gift, interest, Warden, nightmare…) links through its token only.
const PLAIN_TERMS: Array[StringName] = [&"potency", &"dread_shell", &"reaction", &"crowned_reaction", &"chain", &"calling",
	&"nurture_choice", &"nurture", &"signature", &"mastery", &"all_rounder", &"attuned", &"ascended", &"final_form",
	&"grove_branch", &"sprout", &"thornwall", &"eldest", &"dream", &"legendary", &"bittersweet", &"woven", &"banish",
	&"omen", &"maze_bonus", &"catcher", &"aura", &"crit", &"critical_hit", &"flyer", &"restless", &"remember",
	&"memory_grove", &"perk", &"blight_level"]
const NOT_BEFORE := {&"calling": " early"}  # "Calling early" is the verb, not the Calling
static var _seen := {}  # Link metas already linked in the block being built
static var _auto_order: Array[StringName] = []

# PLAIN_TERMS, longest word first.
static func auto_terms() -> Array[StringName]:
	if _auto_order.is_empty():
		_auto_order.assign(PLAIN_TERMS)
		_auto_order.sort_custom(func(a: StringName, b: StringName) -> bool: return String(IconInfo.TERMS[a][0]).length() > String(IconInfo.TERMS[b][0]).length())
	return _auto_order

# The link the first time `meta` appears in the block, the plain word after that.
static func _once(meta: String, word: String) -> String:
	if _seen.has(meta):
		return word
	_seen[meta] = true
	return _link(meta, word)

# The block being built is this term's own glossary entry: its word stays plain there.
static func _own(id: StringName) -> bool:
	return own_term != "" and IconInfo.TERMS.has(id) and String(IconInfo.TERMS[id][2]) == own_term

static var _plain_regex := {}  # Term id -> RegEx for its word
static var own_term := ""  # Set by a glossary entry while it builds its own text: that word isn't linked there (plain data)
const LONGER_TERMS := {&"reaction": ["Crowned "]}  # A plain term isn't linked as the tail of a longer one ("Crowned Reaction")

static func _plain_pattern(id: StringName) -> RegEx:
	if not _plain_regex.has(id):
		if _plain_regex.is_empty():
			UiStyle.release_at_exit(func() -> void: _plain_regex.clear())
		var regex := RegEx.new()
		# The word or its plural, whole. A capitalised keyword (Chain, Calling, Dream) only as written ("chain" is a
		# word), and never as the first word of a name ("Dream Oak", "Chain Bloom").
		var word := String(IconInfo.TERMS[id][0])
		var forms := _escape(String(IconInfo.TERMS[id][1])) + "|" + _escape(word)
		var capital := word.left(1) != word.left(1).to_lower()
		var not_before := "(?!%s)" % _escape(String(NOT_BEFORE[id])) if NOT_BEFORE.has(id) else ""
		regex.compile(("" if capital else "(?i)") + "\\b(?:" + forms + ")\\b" + ("(?! [A-Z])" if capital else "") + not_before)
		_plain_regex[id] = regex
	return _plain_regex[id]

static var _combo_regex: RegEx = null
static func _combo_pattern() -> RegEx:
	if _combo_regex == null:
		UiStyle.release_at_exit(func() -> void: _combo_regex = null)
		_combo_regex = RegEx.create_from_string("\\{(?:named_)?combo:([a-z_]+)\\}")  # {named_combo:x}: always named (Dream cards)
	return _combo_regex

# A combo as a link (screens_ui.md: every combo link everywhere works the same): its name, or "???"
# until discovered; hover / tap shows its tip, a second tap or a click opens it in the Codex.
static func combo_link(id: StringName, named: bool = false) -> String:
	var combo := CodexData.get_any(id)
	var found := named or CodexData.is_discovered(id)  # named: {named_combo:x} on a Dream card always shows its name
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

static func _statuses(text: String, once: bool = false) -> String:
	if _pattern == null:
		var names: Array = []
		for id in IconInfo.STATUSES:
			names.append(_escape(IconInfo.STATUSES[id][0]))
		names.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
		UiStyle.release_at_exit(func() -> void: _pattern = null)
		_pattern = RegEx.new()
		_pattern.compile("\\b(" + "|".join(names) + ")\\b")
	var out := ""
	var at := 0
	for found in _pattern.search_all(text):
		var id := IconInfo.status_id(found.get_string())
		out += text.substr(at, found.get_start() - at)
		out += _once(META_PREFIX + String(id), found.get_string()) if once else _link(META_PREFIX + String(id), found.get_string())
		at = found.get_end()
	return out + text.substr(at)

# Role lines (TowerData.role_line, test_role_lines' vocabulary) link their glossary words (user, 2026-10-07: "make sure
# for Silences, it has the underline of what it means"): word -> IconInfo STATUSES / STATS id. A vocabulary word not
# here, or an id with no entry, stays plain.
const ROLE_TERMS := {"silences": &"silenced", "exposes": &"marked", "roots": &"held", "soaks": &"damp",
	"charges": &"static", "poisons": &"spored", "drowses": &"drowsy", "freezes": &"frozen", "reveals hidden": &"hidden",
	"crits": &"crit_chance", "puts to sleep": &"asleep"}  # Tower Discussion cae6d300: "Stuns" became "Puts to sleep"
static var _role_pattern: RegEx = null

# `role` as bbcode: its ROLE_TERMS words (any case, whole words) as links, other "[" escaped.
static func role_bbcode(role: String) -> String:
	if _role_pattern == null:
		var words: Array = ROLE_TERMS.keys()
		words.sort_custom(func(a: String, b: String) -> bool: return a.length() > b.length())
		UiStyle.release_at_exit(func() -> void: _role_pattern = null)
		_role_pattern = RegEx.create_from_string("(?i)\\b(" + "|".join(words.map(func(w: String) -> String: return _escape(w))) + ")\\b")
	role = role.replace("[", "[lb]")
	var out := ""
	var at := 0
	for found in _role_pattern.search_all(role):
		var id: StringName = ROLE_TERMS[found.get_string().to_lower()]
		out += role.substr(at, found.get_start() - at)
		var known := IconInfo.STATUSES.has(id) or IconInfo.STATS.has(id)
		out += _link(META_PREFIX + String(id), found.get_string()) if known else found.get_string()
		at = found.get_end()
	return out + role.substr(at)

# A role line as bbcode points (user: "point form"): "• Long range" one per line, glossary words linked.
static func role_points_bbcode(role: String) -> String:
	return "\n".join(IconInfo.role_terms(role).map(func(t: String) -> String: return IconInfo.ROLE_BULLET + " " + role_bbcode(t)))

# Inline, where space is tight: "Long range · Charges", glossary words linked.
static func role_inline_bbcode(role: String) -> String:
	return " · ".join(IconInfo.role_terms(role).map(func(t: String) -> String: return role_bbcode(t)))

# A RichTextLabel showing a role line as points (one per line), its glossary words as links (hover / tap), sized to its
# content. `inline` = one wrapping run of " · " instead.
static func make_role_label(role: String, font_size: int = 11, colour: Color = UiStyle.GOLD, inline := false) -> RichTextLabel:
	var label := make_label("", font_size, colour)
	label.text = role_inline_bbcode(role) if inline else role_points_bbcode(role)
	return label

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
	label.meta_hover_started.connect(popup._on_hover_started.bind(label))
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
	_gem.custom_minimum_size = Vector2(22, 22)
	_gem.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_gem.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gem.visible = false
	_gem.draw.connect(func() -> void: UiStyle.draw_gem(_gem, _gem.size / 2.0, 9.0, _gem_rarity))
	row.add_child(_gem)
	var box := VBoxContainer.new()
	row.add_child(box)
	UiStyle.tip_name(_name, LINK_COLOR)  # Tip sizes (screens_ui.md playtest fixes 2026-09-30)
	box.add_child(_name)
	UiStyle.tip_body(_text)
	box.add_child(_text)
	_more.text = "More in the Codex"
	_more.focus_mode = Control.FOCUS_NONE
	_more.pressed.connect(_open_codex)
	box.add_child(_more)
	mouse_entered.connect(func() -> void: _hide_in = -1.0)
	mouse_exited.connect(_hide_soon)

# Hover (PC). A phone has no hover: its emulated mouse can report one just before the tap, which then read as "the same
# word again" and closed the tip it had just opened.
func _on_hover_started(meta: Variant, label: RichTextLabel) -> void:
	if TouchBuild.is_touch():
		return
	_show_for(String(meta), label, false)

# Phones: a touch outside the tip closes it (the word's own tap, if it lands on the word, then stays closed).
func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventScreenTouch) or not event.pressed or not TouchBuild.is_touch():
		return
	if get_global_rect().has_point((event as InputEventScreenTouch).position):
		return  # On the tip itself (its "More in the Codex")
	_touch_closed_meta = _shown_meta
	_touch_closed_ms = Time.get_ticks_msec()
	visible = false

# Whether this tap is the one that just closed the tip on the same word (phones): it stays closed.
func _closed_by_this_tap(meta: String, tapped: bool) -> bool:
	if not tapped or meta != _touch_closed_meta or Time.get_ticks_msec() - _touch_closed_ms > TOUCH_REOPEN_MS:
		return false
	_touch_closed_meta = ""
	return true

func _show_for(meta: String, host: Control, tapped: bool) -> void:
	if _closed_by_this_tap(meta, tapped):
		return
	var is_term := meta.begins_with(TERM_PREFIX)
	var is_family := meta.begins_with(FAMILY_PREFIX)
	var is_combo := meta.begins_with(COMBO_PREFIX)
	var is_nightmare := meta.begins_with(NIGHTMARE_PREFIX)
	var is_card := meta.begins_with(CARD_PREFIX) or meta.begins_with(OMEN_PREFIX) or meta.begins_with(WARDEN_PREFIX)
	if is_card:
		_show_card(meta, host, tapped)
		return
	_gem.visible = false
	_name.add_theme_color_override("font_color", LINK_COLOR)
	if not meta.begins_with(META_PREFIX) and not is_term and not is_family and not is_combo and not is_nightmare:
		return
	var id := StringName(meta.get_slice(":", 1))
	if is_nightmare and tapped and IconInfo.nightmare_met(String(id)):
		visible = false
		_open_nightmare_card(String(id), host)  # Met: its full card (health, speed, resists); ??? kinds keep the popup
		return
	if tapped and visible and id == _status and _is_term == is_term and _is_family == is_family and _is_combo == is_combo \
			and _is_nightmare == is_nightmare:
		if is_combo and CodexData.is_discovered(id):
			_open_codex()  # A combo: the second tap (or a click after hovering) opens it in the Codex
		else:
			visible = false  # Tapping the same word again closes it
		return
	_status = id
	_shown_meta = meta
	_host = host
	_is_term = is_term
	_is_family = is_family
	_is_combo = is_combo
	_is_nightmare = is_nightmare
	_more.visible = not is_nightmare
	if is_nightmare:  # A nightmare: its portrait, name and trait once met; ??? and a hint until then
		var kind := String(id)
		var data := IconInfo.nightmare_data(kind)
		var met := data != null and IconInfo.nightmare_met(kind)
		_icon.texture = NightmareCard.portrait(data) if met else null
		_icon.visible = _icon.texture != null
		_name.text = IconInfo.nightmare_name(kind)
		_text.text = (IconInfo.format(data.trait_text) + "\nClick for its card.") if met else "Not met yet. It shows itself in a run."
	elif is_combo:  # A combo: its name (??? until found), its statuses, what it does, times set off
		var combo := CodexData.get_any(id)
		var found := CodexData.is_discovered(id) and not combo.is_empty()
		var statuses: Array = combo.get("statuses", [])
		var own := IconInfo.icon(id) if found else null  # Its Reaction icon (UI Asset; known ones only), else its first status
		_icon.texture = own if own != null else (IconInfo.icon(statuses[0]) if found and not statuses.is_empty() else null)
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
		var carried := CodexData.nightmares_line(term_name(id))  # "Worn by Shellbound." (names here; links in the Codex)
		if carried != "":
			_text.text += "\n" + IconInfo.format(carried)
	else:
		_icon.texture = IconInfo.icon(id)
		_icon.visible = _icon.texture != null
		var entry: Array = IconInfo.STATUSES.get(id, IconInfo.STATS.get(id, []))  # A role line's "Crits" links a stat
		_name.text = entry[0] if not entry.is_empty() else IconInfo.status_name(id)
		_text.text = IconInfo.format(entry[1]) if not entry.is_empty() else ""
	var mouse := host.get_global_mouse_position()
	UiStyle.lift_tip(self, host)  # Above every panel and screen (screens_ui.md "tips are opaque")
	visible = true
	reset_size()
	# Above-right of the pointer, flipped at the edges: never over the word or the line being read.
	global_position = UiStyle.tip_position(mouse, size, get_viewport_rect().size)
	_place_beside_panel(host, mouse)
	_hide_in = -1.0

# The card (or Omen) a card link names: {name, rarity (-1 for an Omen), text}, or {} when there is none. A retired
# card is still a file, so it still shows.
static func card_tip(meta: String) -> Dictionary:
	if meta.begins_with(WARDEN_PREFIX):  # A Warden: what it is for (its role line), then what it does
		var form := IconInfo.family_data(meta.get_slice(":", 1))
		if form == null:
			return {}
		var role := IconInfo.role_text(form)
		return {"name": form.display_name, "rarity": -1, "icon": WardenIcon.make(form),
			"text": (role + "\n" if role != "" else "") + IconInfo.format(form.description)}
	var omen := meta.begins_with(OMEN_PREFIX)
	var id := meta.get_slice(":", 1)
	var path := ("res://resource/omen/%s.tres" if omen else "res://resource/dream/%s.tres") % id
	if not ResourceLoader.exists(path):
		return {}
	var data = load(path)
	if data is OmenData:
		return {"name": data.display_name, "rarity": -1, "text": "Omen\n" + IconInfo.format(data.description)}
	if not (data is UpgradeData):
		return {}
	var text: String = UpgradeData.rarity_name(data.rarity) + "\n" + IconInfo.format(data.description)
	if data.cost_description != "":
		text += "\n" + IconInfo.format(data.cost_description)
	return {"name": data.display_name, "rarity": int(data.rarity), "text": text}

# A card link's tip: the gem, the name in its rarity colour, the rarity and the description (tokens resolved, plain:
# no links inside a tip). A tap on the same link again closes it.
func _show_card(meta: String, host: Control, tapped: bool) -> void:
	var tip := card_tip(meta)
	if tip.is_empty():
		return
	if tapped and visible and meta == _shown_meta:
		visible = false
		return
	_shown_meta = meta
	_status = StringName(meta.get_slice(":", 1))
	_host = host
	_is_term = false
	_is_family = false
	_is_combo = false
	_is_nightmare = false
	_more.visible = false
	_icon.texture = tip.get("icon")
	_icon.visible = _icon.texture != null
	_gem_rarity = maxi(int(tip.rarity), 0)
	_gem.visible = int(tip.rarity) >= 0
	_gem.queue_redraw()
	_name.text = tip.name
	_name.add_theme_color_override("font_color", UiStyle.rarity_color(int(tip.rarity)) if int(tip.rarity) >= 0 else LINK_COLOR)
	_text.text = tip.text
	var mouse := host.get_global_mouse_position()
	UiStyle.lift_tip(self, host)
	visible = true
	reset_size()
	global_position = UiStyle.tip_position(mouse, size, get_viewport_rect().size)
	_place_beside_panel(host, mouse)
	_hide_in = -1.0

# A met nightmare's NightmareCard over the word's label (one per label; the same word again closes it).
func _open_nightmare_card(kind: String, host: Control) -> void:
	var data := IconInfo.nightmare_data(kind)
	if data == null or not is_instance_valid(host):
		return
	var card := host.get_meta(&"nightmare_card") as NightmareCard if host.has_meta(&"nightmare_card") else null
	if card == null or not is_instance_valid(card):
		card = NightmareCard.new()
		host.add_child(card)
		host.set_meta(&"nightmare_card", card)
	var run := get_tree().current_scene  # In a run: health as it'd arrive next; elsewhere (title, Grove) its base numbers
	var director := run.get_node_or_null("%DriftDirector") as DriftDirector if run != null else null
	card.toggle_for(data, director.drifts_started + 1 if director != null else 1, director, host)

# A word inside a panel that asks for it (meta "tips_beside": the Warden panel) opens its tip beside the panel, to its
# right, or above it when there's no room, never over the text being read (user, Lichenling: "Poisoned" covered the
# description).
func _place_beside_panel(host: Control, mouse: Vector2) -> void:
	var node: Node = host
	while node != null and not (node is Control and node.has_meta(&"tips_beside")):
		node = node.get_parent()
	if node == null:
		return
	var panel := (node as Control).get_global_rect()
	var screen := get_viewport_rect().size
	if panel.end.x + 8.0 + size.x <= screen.x - 4.0:
		global_position = Vector2(panel.end.x + 8.0, clampf(mouse.y - size.y / 2.0, 4.0, screen.y - size.y - 4.0))
	else:
		global_position = Vector2(clampf(panel.position.x, 4.0, screen.x - size.x - 4.0), maxf(4.0, panel.position.y - size.y - 8.0))

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
