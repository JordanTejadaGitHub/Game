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
var damage_type := HBoxContainer.new()  # The damage type name in its colour (no icon: user, 2026-09-30)
var desc: RichTextLabel  # What it does, with its status words as links (StatusLinks)
var stats := VBoxContainer.new()  # Stat rows: each stat explains itself on hover and tap (IconInfo)
var growth := VBoxContainer.new()  # "Grows into" (the hover card and Codex; the panel has its Grow buttons)

const LOCKED_FORM_TIP := "Unlock it with Dreamlight, then grow it with Dew."  # A form not unlocked this run (no stats, no preview)

# A form's unlock blocker as the line shows it: "in the Memory Grove", "needs Stormcap", "from drift 51".
static func blocker_text(blocker: String) -> String:
	return "in the Memory Grove" if blocker == "Memory Grove" else blocker

var compact := false  # The Warden panel (light pass): name + damage type on one line, a short description, no Dreams rows (set_compact)
var brief := false  # Compact with many actions: the description's opening only (the panel sets it before show_warden)
var full_description := ""  # Compact: the description in full when the short one left some out (the panel's Details), else ""
var detail_lines: Array[String] = []  # Compact: stat lines left for the panel's Details ("Soaked: water hits +24%")

var _tower: Tower = null  # The planted Warden shown, or a probe carrying this run's bonuses (never in the tree)
var _probe: Tower = null

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
	var old := header.get_node_or_null("Corner")
	if old != null:
		header.remove_child(old)
		old.queue_free()
	if control != null:
		control.name = "Corner"
		control.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		header.add_child(control)

# The description's opening for the compact header: the first sentence, the second too while both stay short.
const SHORT_CHARS := 70  # Two lines of the compact panel's description (84 wrapped to 3 with underlined links)

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
		if _tower.get_crit_chance() > 0.0:
			main_row.append(["%d%%" % roundi(_tower.get_crit_chance() * 100), &"crit_chance"])
		var covers := compact and is_instance_valid(tower) and tower.is_inside_tree()
		if covers:  # Coverage in the icon row (story chat: always visible, no extra line; the path icon + N)
			main_row.append([str(_tower.get_coverage()), &"path_length"])
		_stat_row(main_row, true)
		var second: Array = []  # The status it applies leads the second row (the first stays one line at 280 px)
		if attack.applies_status != &"":
			second.append(["%s%s" % [IconInfo.status_name(attack.applies_status),
				" ×%d" % attack.status_stacks if attack.status_stacks > 1 else ""], attack.applies_status, true])
		if _tower.get_crit_chance() > 0.0:
			second.append(["Crit ×%s" % str(attack.crit_multiplier), &"crit_damage"])
		var potency := _tower.get_potency()
		if not is_equal_approx(potency, 1.0):
			second.append(["Potency %d%%" % roundi(potency * 100), &"potency"])  # Statuses and effect damage
		var strength := status_strength_text(attack.applies_status, potency, attack.status_duration)
		if strength != "" and compact:
			detail_lines.append(strength)  # The panel's Details
		elif strength != "":
			second.append([strength, attack.applies_status, true])  # "Soaked: water hits +24%", "Rooted 1.2 s"
		if not second.is_empty():
			_stat_row(second, true)  # Wraps too: never wider than the card
		if compact:  # The panel keeps 45% of the screen: these go to its Details, like status strength (coverage is in the row)
			detail_lines.append_array(BranchKit.stat_lines(_tower).filter(func(line: String) -> bool: return not line.begins_with("Covers ")))
		else:
			notes.append_array(BranchKit.stat_lines(_tower))  # Jarlink's arc, live (Tower Code)
	else:
		notes.append("A wall: no attack.")
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
			line.text = "%s · %d Dew" % [next.display_name, cost]
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
				line.text = "Unlock %s · %s" % [next.display_name, blocker_text(blocker) if blocker != "" else ("%d Dreamlight" % dreams.get_unlock_price(next)) if dreams.get_unlock_price(next) > 0 else "free"]
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
		more.text = "%d more not in this dream" % hidden.size()
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

func _show_damage_type(data: TowerData) -> void:
	damage_type.visible = data.can_attack
	if not data.can_attack:
		return
	var label := damage_type.get_child(0) as Label
	label.text = IconInfo.damage_type_text(data.line)
	label.add_theme_color_override("font_color", IconInfo.damage_type_color(data.line))
	if label.tooltip_text == "":
		TapTip.attach(label, "Nightmares can resist or be weak to a damage type.")  # Hover or tap

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
# with the same caps as EnemyStatuses: "Soaked: water hits +24%", "Exposed: +30% damage taken",
# "Drowsy −9% speed a stack", "Rooted 1.2 s". "" for Poisoned / Charged (their damage is in the hit) or with
# status Potency off.
static func status_strength_text(status: StringName, potency: float, duration: float = 0.0) -> String:
	if not Tower.status_potency_on:
		return ""
	match status:
		EnemyStatuses.DAMP:
			return "Soaked: water hits +%d%%" % roundi(minf(EnemyStatuses.DAMP_WATER_BONUS * potency,
				maxf(EnemyStatuses.SOAKED_CAP, EnemyStatuses.DAMP_WATER_BONUS)) * 100)
		EnemyStatuses.MARKED:
			return "Exposed: +%d%% damage taken" % roundi(minf(EnemyStatuses.MARKED_EXTRA * potency,
				maxf(EnemyStatuses.EXPOSED_CAP, EnemyStatuses.MARKED_EXTRA)) * 100)
		EnemyStatuses.DROWSY:
			return "Drowsy −%d%% speed a stack" % roundi(EnemyStatuses.DROWSY_SLOW_PER_STACK * potency * 100)
		EnemyStatuses.HELD:
			var base := duration if duration > 0.0 else float(EnemyStatuses.DEFAULT_DURATION[EnemyStatuses.HELD])
			var held := minf(base * maxf(potency, 1.0), maxf(EnemyStatuses.HELD_POTENCY_CAP, base))
			return "Rooted %s s" % str(snappedf(held, 0.1))
	return ""

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
		&"crit_chance":
			meaning = "Crit chance: %d%% of its hits are critical" % roundi(_tower.get_crit_chance() * 100)
		&"crit_damage":
			meaning = "Critical hits deal ×%s damage" % str(attack.crit_multiplier)
		&"path_length":  # Coverage (maze_feel.md #1: grow where it covers the most route)
			return "Covers %d path tiles, counted once per pass." % _tower.get_coverage()
		&"potency":
			var p := _tower.get_potency()
			if Tower.status_potency_on:
				meaning = "Potency ×%s: its statuses and effects are %d%% %s" % [str(snappedf(p, 0.01)), roundi(absf(p - 1.0) * 100), "stronger" if p >= 1.0 else "weaker"]
			else:
				meaning = "Potency ×%s: its effects (Poisoned ticks, Charged bolts, clouds, Reactions) deal %d%%" % [str(snappedf(p, 0.01)), roundi(p * 100)]
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
					var source: String = "Kindred" if entry.get("kindred", false) \
						else (entry.source.tower_data.display_name if entry.source is Tower and is_instance_valid(entry.source) else String(entry.kind).capitalize())
					why.append("%s %s" % [source, BuffSources._signed(entry.amount, stat == &"range")])
	return meaning + (" (%s)" % ", ".join(why) if not why.is_empty() else "")
