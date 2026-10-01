extends RefCounted
class_name DreamBonusView

# "Dream bonuses on Wardens" (screens_ui.md, 2a93fa6): shows which Dream cards act on a Warden, for
# Tower Code's Warden panel and build ghost. Built on Roguelite's DreamState API:
#   get_card_effects(data, cell, tower) -> [{card, name, active, reason, effect, note, conditional,
#     positional, run_wide, …}]; get_stat_parts(data, cell, stat, tower) -> {base, final, parts}
# (Dream parts only; Nurture and Focus come from the Warden itself). If the API is missing, it shows
# no rows and plain stat text.
#
#   make_rows(tower) / make_rows_at(data, cell)            "Dreams on this Warden" rows (a Control)
#   stat_breakdown(tower, stat) / stat_breakdown_at(…)     "Damage 18 → 27: base 18 · Nurture II +20% · …"
#   is_boosted(tower, stat)                                for the warm tint and up-arrow
#   group_summary(towers)                                  ["Solitude: 3 of 5", …] for a multi-selection
# Breakdowns cover damage, attack_speed, range and cost; other stats read as just their name.

const ACTIVE_COLOR := UiStyle.INK
const OFF_COLOR := UiStyle.OFF
const RUN_WIDE_COLOR := UiStyle.MOONLIGHT
const BOOSTED_COLOR := UiStyle.GOLD  # The warm tint for a boosted stat
const ICON_SCRIPT := preload("res://scripts/ui/dreams_row.gd")

# --- Rows -------------------------------------------------------------------------------------------

static func make_rows(tower: Tower) -> Control:
	return make_rows_at(tower.tower_data, tower.cell, tower)

# The rows for `data` at `cell` (a hypothetical Warden when `tower` is null: the build ghost).
static func make_rows_at(data: TowerData, cell: Vector2, tower: Tower = null) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	var dreams := get_dreams(data, cell, tower)
	if dreams.is_empty():
		return box
	var title := Label.new()
	title.text = "Dreams on this Warden"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Palette.DEWLIGHT)
	box.add_child(title)
	# Compact (screens_ui.md "The Warden panel never fills the screen"): the active cards as one row of
	# gems (rarity shape + stacks; hover / tap = its line), the rest collapsed to one muted line.
	var merged := merge_by_card(dreams)
	merged.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _rank(a) < _rank(b))
	var gems := HFlowContainer.new()
	gems.add_theme_constant_override("h_separation", 6)
	gems.add_theme_constant_override("v_separation", 4)
	var off: Array[String] = []
	var states := _dream_state()
	for entry in merged:
		var card: UpgradeData = entry.card
		if not entry.get("active", false):
			off.append("%s: %s" % [card.display_name, String(entry.get("reason", "it doesn't apply here"))])
			continue
		var icon = ICON_SCRIPT.DreamIcon.new()  # The Dreams row's rarity-shaped card icon
		icon.card = card
		icon.stacks = states.card_stacks(card.id) if states != null else 1
		icon.custom_minimum_size = Vector2(30, 30)
		var line := get_line(entry)
		TapTip.attach(icon, IconInfo.format("%s: %s" % [card.display_name, line if line != "" else card.description]))
		gems.add_child(icon)
	if gems.get_child_count() > 0:
		box.add_child(gems)
	if not off.is_empty():
		var more := Label.new()
		more.text = "%d more don't apply here" % off.size() if off.size() != 1 else "1 more doesn't apply here"
		more.add_theme_font_size_override("font_size", 14)
		more.add_theme_color_override("font_color", OFF_COLOR)
		TapTip.attach(more, IconInfo.format("\n".join(off)))
		box.add_child(more)
	return box

# One entry per card: a card with extra rules (Hunter's Patience + its Skyward Gaze rule) reports one
# effect per rule; they merge here (its lines joined), so it's listed once under its own name.
static func merge_by_card(entries: Array) -> Array:
	var by_card := {}
	var order: Array = []
	for entry in entries:
		var card: UpgradeData = entry.card
		if not by_card.has(card):
			by_card[card] = entry.duplicate()
			order.append(card)
			continue
		var merged: Dictionary = by_card[card]
		var line := get_line(entry)
		if entry.get("active", false):
			if not merged.get("active", false):  # An active rule wins over an inactive one
				by_card[card] = entry.duplicate()
			elif line != "" and not String(merged.get("effect", "")).contains(line):
				merged["effect"] = "%s · %s" % [String(merged.get("effect", "")), line] if String(merged.get("effect", "")) != "" else line
	return order.map(func(c: UpgradeData) -> Dictionary: return by_card[c])

static func _rank(entry: Dictionary) -> int:
	if not entry.get("active", false):
		return 2
	return 1 if entry.get("run_wide", false) else 0

static func _row(entry: Dictionary) -> Control:
	var card: UpgradeData = entry.card
	var active: bool = entry.get("active", false)
	var run_wide: bool = entry.get("run_wide", false)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var icon = ICON_SCRIPT.DreamIcon.new()  # The Dreams row's rarity-shaped card icon
	icon.card = card
	icon.custom_minimum_size = Vector2(30, 30)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	# The card's name, underlined: hover or tap shows its text.
	var name := RichTextLabel.new()
	name.bbcode_enabled = true
	name.fit_content = true
	name.scroll_active = false
	name.autowrap_mode = TextServer.AUTOWRAP_OFF
	name.text = "[u]%s[/u]" % card.display_name.replace("[", "[lb]")
	name.add_theme_color_override("default_color", _colour(active, run_wide))
	name.add_theme_font_size_override("normal_font_size", 14)
	TapTip.attach(name, IconInfo.format("%s: %s" % [card.display_name, card.description]))
	text.add_child(name)
	var line := get_line(entry)
	if line != "":
		text.add_child(StatusLinks.make_label(line, 13, _colour(active, run_wide)))
	if not active:
		icon.modulate = Color(1, 1, 1, 0.45)
	return row

static func _colour(active: bool, run_wide: bool) -> Color:
	if not active:
		return OFF_COLOR
	return RUN_WIDE_COLOR if run_wide else ACTIVE_COLOR

# The row's second line: what it gives ("+30% damage"), or why it's off ("off: Rain Lily is 1
# cell away").
static func get_line(entry: Dictionary) -> String:
	if not entry.get("active", false):
		var reason: String = entry.get("reason", "")
		return "Off: " + reason if reason != "" else "Off"  # (The panel collapses these into "N more don't apply here")
	if entry.get("run_wide", false) and String(entry.get("note", "")) != "":
		return entry.note  # A run-wide card's live value
	return entry.get("effect", "")

# --- Chips (the build ghost) ------------------------------------------------------------------------------

# One compact line per card for the ghost: "Solitude ✓ +30% damage" / "Solitude ✗ Rain Lily is 1 cell
# away" (status names filled in). Draw them with your own chip drawer.
static func chip_text(entry: Dictionary) -> String:
	var name: String = entry.card.display_name
	if entry.get("active", false):
		var effect: String = entry.get("effect", "")
		return IconInfo.format("%s ✓ %s" % [name, effect] if effect != "" else "%s ✓" % name)
	var reason: String = entry.get("reason", "")
	return IconInfo.format("%s ✗ %s" % [name, reason] if reason != "" else "%s ✗" % name)

# Whether a card depends on where the Warden stands (neighbours, distance, counts): the ghost's chips
# that change as it moves. Run-wide cards don't.
static func is_positional(entry: Dictionary) -> bool:
	if entry.has("positional"):
		return bool(entry.positional)
	return entry.get("conditional", false) and not entry.get("run_wide", false)

# The chips for a hypothetical Warden at `cell`: [[text, active, positional], …], active first.
static func chips_at(data: TowerData, cell: Vector2) -> Array:
	var dreams := get_dreams(data, cell)
	dreams.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _rank(a) < _rank(b))
	return dreams.map(func(e: Dictionary) -> Array: return [chip_text(e), e.get("active", false), is_positional(e)])

# --- Stats --------------------------------------------------------------------------------------------

static func stat_breakdown(tower: Tower, stat: StringName) -> String:
	return stat_breakdown_at(tower.tower_data, tower.cell, stat, tower)

# "Damage 18 → 27: base 18 · Nurture II +20% · Solitude +30%", or "Damage 18" with nothing changing it.
static func stat_breakdown_at(data: TowerData, cell: Vector2, stat: StringName, tower: Tower = null) -> String:
	return format_breakdown(stat, get_stat_parts(data, cell, stat, tower))

# The breakdown text for a get_stat_parts() result ({base, final, parts: [[label, text], …]}).
static func format_breakdown(stat: StringName, parts: Dictionary) -> String:
	var name: String = IconInfo.STATS.get(stat, [String(stat).capitalize()])[0]
	if parts.is_empty():
		return name
	var base: float = parts.get("base", 0.0)
	var final: float = parts.get("final", base)
	var pieces: Array = parts.get("parts", [])
	if pieces.is_empty() or is_equal_approx(base, final):
		return "%s %s" % [name, _number(stat, final)]
	var text := "%s %s → %s: base %s" % [name, _number(stat, base), _number(stat, final), _number(stat, base)]
	for piece in pieces:
		text += " · %s %s" % [piece[0], piece[1]]
	return text

static func is_boosted(tower: Tower, stat: StringName) -> bool:
	var parts := get_stat_parts(tower.tower_data, tower.cell, stat, tower)
	return not parts.is_empty() and float(parts.get("final", 0.0)) > float(parts.get("base", 0.0)) + 0.0001

# A stat value as players read it: whole numbers, one decimal for range, two for rates.
static func _number(stat: StringName, value: float) -> String:
	match stat:
		&"range":
			return "%.1f" % value
		&"attack_speed":
			return "%.2f" % value
		&"crit_chance":
			return "%d%%" % roundi(value * 100.0) if value <= 1.0 else "%d%%" % roundi(value)
		_:
			return str(roundi(value)) if is_equal_approx(value, roundf(value)) else "%.1f" % value

# --- Several Wardens -----------------------------------------------------------------------------------

# One line per conditional card among `towers`: "Solitude: 3 of 5" (active on 3 of the 5 it can
# affect). Cards that apply to all of them alike (run-wide) aren't counted.
static func group_summary(towers: Array) -> Array[String]:
	var counts := {}  # Card name -> [active, total]
	var order: Array[String] = []
	for tower in towers:
		if not is_instance_valid(tower):
			continue
		for entry in get_dreams(tower.tower_data, tower.cell, tower):
			if entry.get("run_wide", false):
				continue
			var name: String = entry.card.display_name
			if not counts.has(name):
				counts[name] = [0, 0]
				order.append(name)
			counts[name][1] += 1
			if entry.get("active", false):
				counts[name][0] += 1
	var lines: Array[String] = []
	for name in order:
		lines.append("%s: %d of %d" % [name, counts[name][0], counts[name][1]])
	return lines

# --- The query (Roguelite's DreamState) ----------------------------------------------------------------

# Roguelite's rows for `data` at `cell` (tower = the planted one, or null for the ghost):
# DreamState.get_card_effects -> [{card, name, active, reason, effect, note, conditional, positional,
# run_wide, damage, speed, range, cost, radius}].
static func get_dreams(data: TowerData, cell: Vector2, tower: Tower = null) -> Array:
	var dreams = _dream_state()  # Untyped so this still loads if the API moves
	if dreams == null or not dreams.has_method("get_card_effects"):
		return []
	return dreams.get_card_effects(data, cell, tower).filter(func(e) -> bool:
		return e is Dictionary and e.get("card") is UpgradeData)

# {base, final, parts: [[label, text], …]} for one stat. DreamState gives the Dream parts (amounts:
# fractions for damage / speed, cells for range, Dew for cost; base = the TowerData value). For a
# planted Warden the final value is its real getter (so it matches combat), and whatever Nurture and
# Focus (and its court) add becomes one "Nurture II" part.
static func get_stat_parts(data: TowerData, cell: Vector2, stat: StringName, tower: Tower = null) -> Dictionary:
	var dreams = _dream_state()
	if dreams == null or not dreams.has_method("get_stat_parts") or not DREAM_STATS.has(stat):
		return {}
	var raw = dreams.get_stat_parts(data, cell, String(stat), tower)
	if not raw is Dictionary:
		return {}
	var base := float(raw.get("base", 0.0))
	var final := float(raw.get("final", base))
	var parts: Array = []
	for part in raw.get("parts", []):
		parts.append([String(part.get("name", "")), _amount_text(stat, float(part.get("amount", 0.0)))])
	if tower != null and stat != &"cost":
		var actual := _actual(tower, stat)
		if not is_equal_approx(actual, final) and final != 0.0:
			var label := "Nurture %s" % Tower.rank_name(tower.rank) if tower.rank > 0 else "Other"
			var extra := actual - final if stat == &"range" else actual / final - 1.0
			parts.push_front([label, _amount_text(stat, extra)])
			final = actual
	return {"base": base, "final": final, "parts": parts}

const DREAM_STATS: Array[StringName] = [&"damage", &"attack_speed", &"range", &"cost"]

static func _actual(tower: Tower, stat: StringName) -> float:
	match stat:
		&"damage":
			return tower.get_damage()
		&"attack_speed":
			return tower.get_attacks_per_second()
		&"range":
			return tower.get_range_cells()
	return 0.0

# "+30%" (damage, speed), "+0.5" (range, cells), "−10 Dew" (cost).
static func _amount_text(stat: StringName, amount: float) -> String:
	match stat:
		&"range":
			return "%+.1f" % amount
		&"cost":
			return "%+d Dew" % roundi(amount)
		_:
			return "%+d%%" % roundi(amount * 100.0)

static func _dream_state() -> DreamState:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.get_first_node_in_group(DreamState.GROUP) as DreamState if tree else null
