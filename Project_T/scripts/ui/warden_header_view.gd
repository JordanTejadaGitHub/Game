class_name WardenHeaderView
extends VBoxContainer

# The top half of the Warden panel as one shared view (screens_ui.md, the bullets above "Readable
# tooltips"): portrait + name, damage type, the description with links, stats with this run's Dream
# bonuses, the status it applies and its Potency, and optionally "Grows into". The Warden panel, the
# Warden bar's hover card and the Codex Families page all build it, so they never disagree.
#   WardenHeaderView.build(data)          an unplanted Warden: its base plus this run's run-wide bonuses
#   WardenHeaderView.build(data, tower)   a planted one: exactly what the panel shows
# No buttons. Add it to the tree (it finds DreamState by group) or pass `dreams`.

const PORTRAIT_SIZE := 48.0
const WIDTH := 280.0

var title := Label.new()
var portrait := TextureRect.new()  # The Warden's idle art (the panel animates it)
var portrait_atlas := AtlasTexture.new()
var damage_type := HBoxContainer.new()  # The small line under the name (the panel's rank); was the damage type
var desc: RichTextLabel  # What it does, with its status words as links (StatusLinks)
var keywords := VBoxContainer.new()  # Its keyword chips (_show_keywords)
var stats := VBoxContainer.new()  # Stat rows: each stat explains itself on hover and tap (IconInfo)
var growth := VBoxContainer.new()  # "Grows into" (the hover card and Codex; the panel has its Grow buttons)

const LOCKED_FORM_TIP := "Unlock it with Dreamlight, then grow it with Dew."  # A form not unlocked this run (no stats, no preview)

# A form's unlock blocker as the line shows it: "in the Memory Grove", "needs Stormcap", "from drift 51".
static func blocker_text(blocker: String) -> String:
	return "in the Memory Grove" if blocker == "Memory Grove" else blocker

var compact := false  # The Warden panel (light pass): name + damage type on one line, a short description, no Dreams rows (set_compact)
var brief := false  # Compact with many actions: the description's opening only (the panel sets it before show_warden)
var full_description := ""  # Compact: the description in full when the short one left some out (the panel's Details), else ""
var detail_lines: Array[String] = []  # Compact: stat lines left for the panel's Details ("Soak: water hits +24%")

var _tower: Tower = null  # The planted Warden shown, or a probe carrying this run's bonuses (never in the tree)
var _probe: Tower = null
var _bowl_label: Label

# A ready view for `data` (and `tower` when it's planted). `with_growth` adds "Grows into".
static func build(data: TowerData, tower: Tower = null, dreams: DreamState = null, with_growth := true) -> WardenHeaderView:
	var view := WardenHeaderView.new()
	view.show_warden(data, tower, dreams, with_growth)
	return view

func _init() -> void:
	add_theme_constant_override("separation", 6)
	UiStyle.title(title, UiStyle.TITLE_SIZE)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	portrait.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.texture = portrait_atlas
	header.add_child(portrait)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	add_child(header)
	damage_type.add_theme_constant_override("separation", 4)
	damage_type.add_child(Label.new())
	add_child(damage_type)
	desc = StatusLinks.make_label("", 16)
	desc.custom_minimum_size = Vector2(WIDTH, 0)
	add_child(desc)
	keywords.name = "Keywords"
	add_child(keywords)  # What it makes, as keyword chips (KeywordRow), under the description
	stats.add_theme_constant_override("separation", 2)
	add_child(stats)
	growth.add_theme_constant_override("separation", 2)
	add_child(growth)

# The Warden panel's compact header (light pass, story chat 2026-10-05: "Warden panel is too large"): a 32 px
# emblem, the damage type on the name's line, the description at its first sentence (the rest in Details).
func set_compact(width: float) -> void:
	compact = true
	portrait.custom_minimum_size = Vector2(32, 32)
	UiStyle.title(title, 20)
	# The name and, under it, the damage type (small): beside the 32 px emblem, never cut (story chat 2026-10-05).
	var header := title.get_parent()
	var names := VBoxContainer.new()
	names.name = "Names"
	names.add_theme_constant_override("separation", -2)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(names)
	header.remove_child(title)
	names.add_child(title)
	damage_type.get_parent().remove_child(damage_type)
	names.add_child(damage_type)
	(damage_type.get_child(0) as Label).add_theme_font_size_override("font_size", 14)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # A very long name wraps rather than widening the panel
	desc.custom_minimum_size = Vector2(width, 0)

# A control at the right end of the name's line (the Warden panel's targeting chip); null clears it.
func set_corner(control: Control) -> void:
	var header := portrait.get_parent()
	for old in header.get_children():
		if old.has_meta(&"corner"):  # Tagged, not renamed: the control keeps its own name (TargetChip)
			header.remove_child(old)
			old.queue_free()
	if control != null:
		control.set_meta(&"corner", true)
		control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		header.add_child(control)

# The description's opening for the compact header: the first sentence, the second too while both stay short.
const SHORT_CHARS := 70  # Two lines of the compact panel's description (84 wrapped to 3 with underlined links)

# A Warden of the Calling's family names the rule under its description (screens_ui.md "Where to recheck your
# Calling"): "Calling · Lantern Ring", the rule in its tip. Nothing for other families or a run with no Calling.
var _calling_line: Label = null

# Keyword chips (2026-10-16; Roguelite Code b4ff3d08): what this Warden makes (its roles' keywords and its statuses);
# a planted one reads its attack (a Graftling's copy). Shared by the Warden panel, the bar's hover card (what the build
# ghost plants) and the Codex.
func _show_keywords(data: TowerData, tower: Tower) -> void:
	for child in keywords.get_children():
		keywords.remove_child(child)
		child.queue_free()
	var chips: Array = DreamState.KEYWORDS.chips_for_tower(tower) if is_instance_valid(tower) else DreamState.KEYWORDS.chips_for_warden(data)
	# The quiet card chip (owner, phone screenshot 2026-10-17: "doesn't look like the ones on the card"): a thin gold
	# frame, the word in INK_DIM at the card's 12 px (DreamScreen CARD_CHIP_TEXT); Wardens have no rarity, so gold.
	var row := KeywordRow.make(chips, UiStyle.CHIP_ICON, UiStyle.GOLD, 12)
	if row != null:
		keywords.add_child(row)
	keywords.visible = row != null

func _show_calling(data: TowerData) -> void:
	if _calling_line != null and is_instance_valid(_calling_line):
		_calling_line.queue_free()
	_calling_line = null
	var dreams: DreamState = _tower._dream_state if is_instance_valid(_tower) else null
	if dreams == null or data == null or dreams.calling == "" or dreams.calling_title() == "" \
			or DreamState.CALLINGS.line_of(dreams.calling) != data.line:
		return
	_calling_line = Label.new()
	_calling_line.name = "Calling"
	_calling_line.text = "Calling · %s" % dreams.calling_title()
	UiStyle.caps(_calling_line, 13, UiStyle.GOLD)
	_calling_line.mouse_filter = Control.MOUSE_FILTER_STOP
	TapTip.attach(_calling_line, IconInfo.format(DreamState.CALLINGS.tooltip(dreams.calling)))
	desc.get_parent().add_child(_calling_line)
	desc.get_parent().move_child(_calling_line, desc.get_index() + 1)

static func short_description(text: String) -> String:
	var sentences := text.split(". ")
	var short := text
	if sentences.size() >= 2:
		short = sentences[0] + "."
		if short.length() < 48 and short.length() + sentences[1].length() < 96:
			short = sentences[0] + ". " + sentences[1] + ("." if sentences.size() > 2 else "")
	return _cut_words(short, SHORT_CHARS)

# `text` cut at a word to at most `limit` shown characters ({tokens} count as their word), with "…"; never inside
# an open bracket.
static func _cut_words(text: String, limit: int) -> String:
	if _shown_length(text) <= limit:
		return text
	var out := ""
	for word in text.split(" "):
		var longer := word if out == "" else out + " " + word
		if _shown_length(longer) > limit - 1:
			break
		out = longer
	if out.count("(") > out.count(")"):
		out = out.left(out.rfind("(")).strip_edges()
	return out.rstrip(",;:—– ") + "…"

static func _shown_length(text: String) -> int:
	return text.replace("{", "").replace("}", "").length()

func _exit_tree() -> void:
	_free_probe()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		_free_probe()

func _free_probe() -> void:
	if is_instance_valid(_probe):
		_probe.free()
	_probe = null

# Fills the view. Returns the panel's notes that aren't stats ("A wall: no attack.", "Copying …").
func show_warden(data: TowerData, tower: Tower = null, dreams: DreamState = null, with_growth := true) -> Array[String]:
	if dreams == null and is_inside_tree():
		dreams = get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	_tower = tower if is_instance_valid(tower) else _probe_for(data, dreams)
	var notes: Array[String] = []
	_bowl_label = null
	title.text = data.display_name
	portrait_atlas.atlas = data.texture
	portrait_atlas.region = WardenIcon.visible_region(data)  # Centred by its drawn pixels (user, via UI Asset)
	portrait.visible = data.texture != null
	_show_damage_type(data)
	desc.text = StatusLinks.bbcode(data.description)  # {damp}-style tokens and plain names both work
	full_description = ""
	if compact and brief:  # Many actions below (story chat: the description gives way first): its opening, the rest in Details
		var opening := short_description(data.description)
		if opening != data.description:
			desc.text = StatusLinks.bbcode(opening)
			full_description = data.description
	detail_lines.clear()
	# Compact: the description whole, wrapping (user: "The description also cuts off"); short_description stays for
	# callers that want an opening line.
	if is_instance_valid(tower) and tower.legacy_data != null:
		# An Ascended form still makes its final form's attack.
		if compact:
			full_description = (full_description if full_description != "" else data.description) \
				+ "\nStill %s: %s" % [tower.legacy_data.display_name, tower.legacy_data.description]
		else:
			desc.text += "\n[i]Still %s: %s[/i]" % [tower.legacy_data.display_name, StatusLinks.bbcode(tower.legacy_data.description)]
	desc.visible = desc.text != ""
	_show_calling(data)
	_show_keywords(data, tower)
	for child in stats.get_children():
		child.queue_free()
	var attack := _tower.attack_data
	if data.attack_kind == TowerData.AttackKind.AURA:
		_stat_row([["Aura", &""], ["range %.2f" % _tower.get_range_cells(), &"range"]])
	elif data.attack_kind == TowerData.AttackKind.COPY and (not is_instance_valid(tower) or tower.get_copied() == null):
		notes.append("Copies its strongest neighbour at %d%%." % roundi(data.copy_share * 100) if not is_instance_valid(tower)
			else "Nothing to copy: plant it beside an attacking Warden.")
	elif data.can_attack:
		if is_instance_valid(tower) and tower.get_copied() != null:
			notes.append("Copying %s at %d%%" % [attack.display_name, roundi(data.copy_share * 100)])
		# Light pass (user-approved): one icon row, values only (the icon says which; its tip names it): damage, speed,
		# range, crit, the status it applies. Rarer numbers (crit damage, Potency, status strength) on a second row.
		var range_text := "%.1f" % _tower.get_range_cells()
		if attack.min_range > 0.0:
			range_text = "%.1f–%.1f" % [attack.min_range, _tower.get_range_cells()]
		var main_row: Array = [[BossDossier.thousands(roundi(_tower.get_damage())), &"damage"],
			["%.1f/s" % _tower.get_attacks_per_second(), &"attack_speed"], [range_text, &"range"]]
		var reach := BranchKit.ability_reach(_tower) if is_instance_valid(tower) else 0.0
		if reach > 0.0:  # Groundroot / Earthbind grab flyers beyond their attack range (Tower Code e530a46a)
			main_row.append(["Grab range %.1f" % reach, &"grab_reach"])
		if _tower.get_crit_chance() > 0.0:
			main_row.append(["%d%%" % roundi(_tower.get_crit_chance() * 100), &"crit_chance"])
		var covers := compact and is_instance_valid(tower) and tower.is_inside_tree()
		if covers:  # Coverage in the icon row (story chat: always visible, no extra line; the path icon + N)
			main_row.append([str(_tower.get_coverage()), &"path_length"])
		var second: Array = []  # The status it applies leads the second row (the first stays one line at 280 px)
		# How it attacks: an icon in the first row once UI Asset draws shape_<kind> (the name in its tip; user: the row
		# stays one line); until then its name leads the second row.
		var shape_icon := StringName("shape_" + String(Tower.attack_shape(attack)))
		if IconInfo.icon(shape_icon) != null:
			main_row.append(["", shape_icon])
		else:
			second.append([shape_name(attack), &"attack_shape"])
		_stat_row(main_row, true)
		# The status it applies: its data's, else the one its special applies (Tower.statuses_applied: the Sparkler's Charge).
		var main_status: StringName = attack.applies_status
		if main_status == &"":
			for special_status in BranchKit.SPECIAL_STATUSES.get(attack.special, []):
				main_status = special_status
				break
		if main_status != &"":
			second.append(["%s%s" % [IconInfo.status_name(main_status),
				" ×%d" % attack.status_stacks if attack.status_stacks > 1 and main_status == attack.applies_status else ""], main_status, true])
		if _tower.get_crit_chance() > 0.0:
			second.append(["Crit ×%s" % str(attack.crit_multiplier), &"crit_damage"])
		var potency := _tower.get_potency()
		if not _tower.get_potency_uses().is_empty():  # Shown wherever it does something (user), with what in its tip
			second.append(["Potency %s" % str(snappedf(potency, 0.01)), &"potency"])  # Statuses and effect damage
		# Patient Roots' seconds count in "Roots N s" (Tower Code fc6cb644), so its cap shows before a Deep pick is wasted
		var held_extra: float = _tower.held_card_seconds() if main_status == EnemyStatuses.HELD and _tower.has_method("held_card_seconds") else 0.0
		var strength := status_strength_text(main_status, potency, attack.status_duration, held_extra)
		if strength != "" and compact:
			detail_lines.append(strength)  # The panel's Details
		elif strength != "":
			second.append([strength, main_status, true])  # "Soak: water hits +24%", "Roots 1.2 s"
		# Wardens that Root by an ability, not by their attack's status (Tower Code): Tangleroot / Snugroot's timed
		# hold (hold_time), Rootling's every-Nth-pulse hold (pulse_hold_time). Both go through Tower.hold, so the same
		# Potency stretch, Patient Roots seconds and cap apply. attack_data, so a Graftling's copy is right.
		var hold_seconds: float = attack.hold_time if attack.hold_targets > 0 else (attack.pulse_hold_time if attack.pulse_hold_every > 0 else 0.0)
		if hold_seconds > 0.0 and attack.applies_status != EnemyStatuses.HELD:
			var rooted := status_strength_text(EnemyStatuses.HELD, potency, hold_seconds,
				_tower.held_card_seconds() if _tower.has_method("held_card_seconds") else 0.0)
			if rooted != "" and compact:
				detail_lines.append(rooted)
			elif rooted != "":
				second.append([rooted, EnemyStatuses.HELD, true])
		if not second.is_empty():
			_stat_row(second, true)  # Wraps too: never wider than the card
		if compact:  # The panel keeps 45% of the screen: these go to its Details, like status strength (coverage is in the row)
			detail_lines.append_array(BranchKit.stat_lines(_tower).filter(func(line: String) -> bool: return not line.begins_with("Covers ")))
		else:
			notes.append_array(BranchKit.stat_lines(_tower))  # Jarlink's arc, live (Tower Code)
	else:
		notes.append("A wall: no attack.")
	if data.catch_share > 0.0:
		var share := (data.catch_share + data.catch_per_rank * _tower.get_effective_rank() + DewCatch.DEW_BOWL_STEP * _tower._rule_stacks(&"dew_bowl") + Tower.FOCUS_STRONG_CATCH * _tower.choice_count(Tower.Focus.STRONG)) * Signatures.multiplier(_tower, &"catch")
		_economy_line("Catch +%d%% · range %.1f" % [roundi(share * 100), _tower.get_catch_radius()], IconInfo.format("Catches part of the Dew from nightmares dispelled in range. Only the strongest catcher in range counts. Nightmares with {damp} give more."))
		if is_instance_valid(tower):
			_bowl_label = _economy_line("Caught %.1f Dew" % tower.bowl, "Paid to you at the next rest.")
	if data.rest_interest > 0.0:
		var rate := data.rest_interest + Tower.KINDRED_INTEREST * _tower.choice_count(Tower.Focus.KINDRED)
		var cap := data.rest_interest_max + (DewCatch.DEEP_WELL_CAP if dreams != null and dreams.has_rule(&"deep_well") else 0) + NurtureChoices.WELL_CAP_KINDRED * _tower.choice_count(Tower.Focus.KINDRED)
		_economy_line("Interest %d%% · cap %d" % [roundi(rate * 100), cap], "Paid on the Dew you hold, at the rest. All Wellsprings together pay at most %s a rest." % UiStyle.dew_amount(DewCatch.INTEREST_CAP))
	if dreams != null and not compact:  # Compact: the panel puts them in Details
		stats.add_child(DreamBonusView.make_rows(_tower) if is_instance_valid(tower)
			else DreamBonusView.make_rows_at(data, _tower.cell))  # "Dreams on this Warden"
	_fill_growth(data, dreams if with_growth else null)
	return notes

# "Grows into": each next form with its Dew, or what unlocking it takes (Dreamlight).
func _fill_growth(data: TowerData, dreams: DreamState) -> void:
	for child in growth.get_children():
		child.queue_free()
	growth.visible = false
	if dreams == null:
		return
	var options := Tower.grow_options(dreams, data)
	if options.is_empty():
		return
	growth.visible = true
	var head := Label.new()
	head.text = "Grows into"
	UiStyle.caps(head, 14)
	growth.add_child(head)
	for option in options:
		var next: TowerData = option[0]
		var line := Label.new()
		var tip := LOCKED_FORM_TIP  # Locked (story chat 2026-10-01): only where it's unlocked; Grove-locked: "???"
		if option[1]:
			var cost: int = tower_grow_cost(next, dreams)
			line.text = "%s · %s" % [next.display_name, UiStyle.dew_amount(cost)]
			# Unlocked: its name and key changes ("Thunderhead: damage 30 → 48, chains 3 → 5, range 3.0 → 3.5").
			tip = IconInfo.format(next.description)
			if is_instance_valid(_tower):
				tip = TowerPlacer.describe_growth(_tower, next, dreams) + "\n\n" + tip
		elif dreams.has_method("get_unlock_cost"):
			var blocker: String = dreams.get_unlock_blocker(next) if dreams.has_method("get_unlock_blocker") else ""
			if blocker == "Memory Grove":  # Can't be unlocked in a run: no name, no Unlock wording
				line.text = "%s · %s" % [RememberScreen.UNKNOWN_NAME, blocker_text(blocker)]
				tip = RememberScreen.UNKNOWN_NAME
			else:
				line.text = "Unlock %s · %s" % [next.display_name, blocker_text(blocker) if blocker != "" else UiStyle.dreamlight_amount(dreams.get_unlock_price(next)) if dreams.get_unlock_price(next) > 0 else "free"]
			line.add_theme_color_override("font_color", UiStyle.INK_DIM)
		else:
			line.text = "%s · needs a Dream" % next.display_name
			line.add_theme_color_override("font_color", UiStyle.INK_DIM)
		TapTip.attach(line, tip)  # Hover or tap
		_grow_preview_on(line, next, option[1])
		growth.add_child(line)
	var hidden := Tower.not_in_dream(dreams, data)  # Branch expansion: called back on Remember, not listed
	if not hidden.is_empty():
		var more := Label.new()
		more.text = "%d more not in this run" % hidden.size()
		more.add_theme_color_override("font_color", UiStyle.INK_DIM)
		TapTip.attach(more, "%s: call one back on Remember." % ", ".join(hidden.map(func(form: TowerData) -> String: return form.display_name)))
		growth.add_child(more)

# A planted Warden's "Grows into" line, pointed at: the map preview (ring + ghost) of an unlocked form, as the
# panel's Grow buttons do. The hover card for the bar's unplanted Wardens has no Warden to preview on.
func _grow_preview_on(line: Label, next: TowerData, unlocked: bool) -> void:
	if not unlocked or not is_instance_valid(_tower) or _tower == _probe or not _tower.is_inside_tree():
		return
	var placer: TowerPlacer = Tower.placer_ref.get_ref() if Tower.placer_ref != null else null
	if placer == null:
		return
	var tower := _tower
	line.mouse_filter = Control.MOUSE_FILTER_STOP
	var hide := func() -> void:
		if is_instance_valid(placer):
			placer.hide_grow_preview()
	line.mouse_entered.connect(func() -> void:
		if is_instance_valid(placer) and is_instance_valid(tower):
			placer.show_grow_preview([[tower, next]]))
	line.mouse_exited.connect(hide)
	line.tree_exiting.connect(hide)

func tower_grow_cost(next: TowerData, dreams: DreamState) -> int:
	return _tower.get_grow_cost(next).total if is_instance_valid(_tower) and _tower != _probe else dreams.get_evolve_cost(next)

# The small line under the name: the form's role tags (owner 2026-10-16: so players see which Dream cards a form wakes;
# WardenRoles, card pass), "Heavy · Area", hidden when it has none; the Warden panel adds its rank after them. (It held
# the damage type until Nightmare Kinds, enemy_design.md ed6f573b.)
const ROLE_TAG_NAMES := {WardenRoles.HEAVY: "Heavy", WardenRoles.AREA: "Area", WardenRoles.CHAIN: "Chain",
	WardenRoles.BEAM: "Beam", WardenRoles.TRAP: "Trap", WardenRoles.PULL: "Pull", WardenRoles.HOLD: "Hold",
	WardenRoles.SNIPER: "Long range", WardenRoles.SUPPORT: "Support"}
const ROLE_TAGS_TIP := "Its jobs. Some Dream cards wake only once you have grown a Warden with one of them."

static func role_tags(data: TowerData) -> Array[String]:
	var out: Array[String] = []
	for role in WardenRoles.roles(data):
		out.append(String(ROLE_TAG_NAMES.get(role, String(role).capitalize())))
	return out

func _show_damage_type(data: TowerData) -> void:
	var label := damage_type.get_child(0) as Label
	label.text = " · ".join(role_tags(data))
	label.add_theme_color_override("font_color", UiStyle.INK_DIM)
	damage_type.visible = label.text != ""
	if label.tooltip_text == "":
		TapTip.attach(label, ROLE_TAGS_TIP)  # Hover or tap

# An unplanted Warden's stats: a Tower that never enters the tree, reading this run's Dreams.
func _probe_for(data: TowerData, dreams: DreamState) -> Tower:
	if not is_instance_valid(_probe):
		_probe = Tower.new()
	_probe.tower_data = data
	_probe.attack_data = data
	_probe.cell = Vector2(-100, -100)  # Off the board: no position cards
	_probe._dream_state = dreams
	_probe.clear_dream_cache()
	return _probe

# One row of stats. Each stat (its icon and value) is one hover / tap target, so its tip sits over the stat
# pointed at, and the tip says what it means for this Warden: "Attack speed: 1.24 attacks a second (base 1.10,
# Swift +13%)", with the Dream / Nurture breakdown and the local buffs (auras, Kinships) that changed it.
# `icons`: the light pass's icon row (no " · " between parts, a 14 px gap; each value named "Value_<id>" for tests).
func _stat_row(parts: Array, icons := false) -> void:
	var row: Container = HFlowContainer.new() if icons else HBoxContainer.new()  # The icon row wraps on a narrow card
	row.add_theme_constant_override("h_separation" if icons else "separation", 14 if icons else 0)
	for i in parts.size():
		var part: Array = parts[i]
		if i > 0 and not icons:
			var dot := Label.new()
			dot.text = " · "
			row.add_child(dot)
		var id: StringName = part[1]
		var is_status: bool = part.size() > 2 and part[2]
		var target := HBoxContainer.new()  # The icon and its value: one tip
		target.add_theme_constant_override("separation", 3)
		var art: Texture2D = IconInfo.icon(id) if id != &"" else null
		if art != null:
			var icon := TextureRect.new()
			icon.texture = art
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(16, 16)
			icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			target.add_child(icon)
		var label := Label.new()
		label.text = part[0]
		if icons:
			label.name = "Value_%s" % id
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not is_status and id != &"" and is_instance_valid(_tower) and _tower != _probe and DreamBonusView.is_boosted(_tower, id):
			# Boosted: gold, and its tip says by what (no "↑": user, Jarlink's panel, an unexplained glyph)
			label.add_theme_color_override("font_color", DreamBonusView.BOOSTED_COLOR)
		target.add_child(label)
		var tip := IconInfo.status_tooltip(id) if is_status else stat_tip(id)
		if tip != "":
			TapTip.attach(target, tip)
		row.add_child(target)
	stats.add_child(row)

# What this Warden's status does at its Potency (tower_design.md "Potency: effect damage and status strength"),
# with the same caps as EnemyStatuses: "Soak: water hits +24%", "Exposure: +30% damage taken",
# "Sleep −9% speed a stack", "Roots 1.2 s" (IconInfo names). "" for Poison / Charge (their damage is in the hit) or with
# status Potency off.
static func status_strength_text(status: StringName, potency: float, duration: float = 0.0, held_extra: float = 0.0) -> String:
	if not Tower.status_potency_on:
		return ""
	match status:
		EnemyStatuses.DAMP:
			return "%s: water hits +%d%%" % [IconInfo.status_name(status), roundi(minf(EnemyStatuses.DAMP_WATER_BONUS * potency,
				maxf(EnemyStatuses.SOAKED_CAP, EnemyStatuses.DAMP_WATER_BONUS)) * 100)]
		EnemyStatuses.MARKED:
			return "%s: +%d%% damage taken at full stacks" % [IconInfo.status_name(status), roundi(minf(EnemyStatuses.MARKED_EXTRA * potency,
				maxf(EnemyStatuses.EXPOSED_CAP, EnemyStatuses.MARKED_EXTRA)) * 100)]
		EnemyStatuses.DROWSY:
			return "%s −%d%% speed a stack" % [IconInfo.status_name(status), roundi(EnemyStatuses.DROWSY_SLOW_PER_STACK * 100)]
		EnemyStatuses.HELD:
			var base := (duration if duration > 0.0 else float(EnemyStatuses.DEFAULT_DURATION[EnemyStatuses.HELD])) + held_extra  # + Patient Roots, before the cap
			var held := minf(base * maxf(potency, 1.0), maxf(EnemyStatuses.HELD_POTENCY_CAP, base))
			return "%s %s s" % [IconInfo.status_name(status), str(snappedf(held, 0.1))]
	return ""

# How it attacks (user: "can't tell if something is an aura attack or not"; Tower Code 6fa3e5ce Tower.attack_shape):
# a chip in the icon row, the tooltip saying what the shape means. Also the Remember side panel's line.
const SHAPE_TIPS := {&"single": "hits one nightmare at a time", &"splash": "hits one nightmare and splashes the ones beside it",
	&"area": "hits everything in range at once", &"chain": "jumps from nightmare to nightmare", &"cloud": "leaves a cloud on the path",
	&"trap": "sets traps on the path", &"beam": "a beam that grows stronger the longer it holds", &"birds": "sends birds out to strike",
	&"seed": "a seed that flies out and back", &"patrol": "flies a patrol over the path", &"copy": "copies the strongest Warden beside it",
	&"light": "lights cells of path that hurt nightmares", &"pull": "pulls nightmares back along the path",
	&"spread": "spreads statuses between nightmares", &"aura": "boosts the Wardens in range", &"none": "doesn't attack: a wall"}

static func shape_name(data: TowerData) -> String:
	return String(Tower.ATTACK_SHAPE_NAMES.get(Tower.attack_shape(data), ""))

# The Potency tip for one Warden (user, 2026-10-07: "Potency hover over Wardens should describe what it does for that
# Warden"): "Potency 1.3 (why)", "On this Warden: Rooted lasts longer.", then the general line. `uses` = Tower Code's
# Tower.potency_uses / get_potency_uses ({token} lines; empty = Potency does nothing here, the stat is hidden).
static func potency_tip(potency: float, uses: Array[String], why := "") -> String:
	var lines: Array = uses.map(func(use: String) -> String: return IconInfo.format(use))
	var on_it := "; ".join(lines)
	return "Potency %s%s\nOn this Warden: %s.\nHigher Potency strengthens its statuses and effects." % [
		str(snappedf(potency, 0.01)), " (%s)" % why if why != "" else "", on_it.left(1).to_upper() + on_it.substr(1)]

static func shape_tip(data: TowerData) -> String:
	var shape := Tower.attack_shape(data)
	return "%s: %s." % [Tower.ATTACK_SHAPE_NAMES.get(shape, "Attack"), SHAPE_TIPS.get(shape, "")]

const LOCAL_BUFF_STATS :={&"damage": "damage", &"attack_speed": "attack_speed", &"range": "range"}

# What `stat` means for the shown Warden, then what made it ("base 24 · Nurture II +20% · Acorn +5%").
func stat_tip(stat: StringName) -> String:
	if not is_instance_valid(_tower):
		return IconInfo.stat_tooltip(stat)
	var attack := _tower.attack_data
	var meaning := ""
	match stat:
		&"damage":
			meaning = "Damage: %s per hit" % BossDossier.thousands(roundi(_tower.get_damage()))
		&"attack_speed":
			meaning = "Attack speed: %.2f attacks a second" % _tower.get_attacks_per_second()
		&"range":
			meaning = ("Range: %.1f–%.1f cells" % [attack.min_range, _tower.get_range_cells()]) if attack.min_range > 0.0 \
				else "Range: %.1f cells" % _tower.get_range_cells()
		&"attack_shape":
			return shape_tip(attack)
		_ when String(stat).begins_with("shape_"):
			return shape_tip(attack)
		&"grab_reach":
			return "Grab range: %.1f cells. It pulls flyers down from this far, beyond its attack range (%.1f)." % [BranchKit.ability_reach(_tower), _tower.get_range_cells()]
		&"crit_chance":
			meaning = "Crit chance: %d%% of its hits are critical" % roundi(_tower.get_crit_chance() * 100)
		&"crit_damage":
			meaning = "Critical hits deal ×%s damage" % str(attack.crit_multiplier)
		&"path_length":  # Coverage (maze_feel.md #1: grow where it covers the most route)
			return "Covers %d cells of path, counted once per pass." % _tower.get_coverage()
		&"potency":
			var breakdown := DreamBonusView.stat_breakdown(_tower, stat) if _tower != _probe else ""
			return potency_tip(_tower.get_potency(), _tower.get_potency_uses(),
				breakdown.split(": ", true, 1)[1] if breakdown.contains(": ") else "")
		_:
			return IconInfo.stat_tooltip(stat)
	var why: Array[String] = []
	if _tower != _probe:
		var breakdown := DreamBonusView.stat_breakdown(_tower, stat)  # "Damage 18 → 27: base 18 · Nurture II +20%"
		if breakdown.contains(": "):
			why.append(breakdown.split(": ", true, 1)[1])
		if LOCAL_BUFF_STATS.has(stat):
			for entry in BuffSources.for_tower(_tower):
				if entry.stat == LOCAL_BUFF_STATS[stat] and BuffSources.LOCAL_KINDS.has(entry.kind):
					var source: String = "Attuned" if entry.get("kindred", false) \
						else (entry.source.tower_data.display_name if entry.source is Tower and is_instance_valid(entry.source) else String(entry.kind).capitalize())
					why.append("%s %s" % [source, BuffSources._signed(entry.amount, stat == &"range")])
	return meaning + (" (%s)" % ", ".join(why) if not why.is_empty() else "")

func _economy_line(text: String, tip: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	TapTip.attach(label, tip)
	stats.add_child(label)
	return label

func _process(_delta: float) -> void:
	if is_visible_in_tree() and is_instance_valid(_bowl_label) and is_instance_valid(_tower) and _tower != _probe:
		_bowl_label.text = "Caught %.1f Dew" % _tower.bowl
