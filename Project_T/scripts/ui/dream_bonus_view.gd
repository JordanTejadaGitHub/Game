extends RefCounted
class_name DreamBonusView

# "Dream bonuses on Wardens" (screens_ui.md, 2a93fa6): shows which Dream cards act on a Warden, for
# Tower Code's Warden panel and build ghost. Built on DreamState's query (Roguelite Code):
#   get_warden_dreams(data, cell, tower) -> [{card, active, conditional, run_wide, effect, reason}]
#   get_stat_parts(data, cell, stat, tower) -> {base, final, parts: [[label, text], …]}
# Until that query exists everything here degrades quietly (no rows, plain stat text).
#
#   make_rows(tower) / make_rows_at(data, cell)            "Dreams on this Warden" rows (a Control)
#   stat_breakdown(tower, stat) / stat_breakdown_at(…)     "Damage 18 → 27: base 18 · Nurture II +20% · …"
#   is_boosted(tower, stat)                                for the warm tint and up-arrow
#   group_summary(towers)                                  ["Solitude: 3 of 5", …] for a multi-selection
# Stat ids are IconInfo.STATS' (damage, attack_speed, range, crit_chance, crit_damage, potency).

const ACTIVE_COLOR := Color(0.95, 0.93, 0.85)
const OFF_COLOR := Color(0.55, 0.57, 0.6)
const RUN_WIDE_COLOR := Color(0.8, 0.88, 0.95)
const BOOSTED_COLOR := Color(1.0, 0.82, 0.5)  # The warm tint for a boosted stat
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
	title.add_theme_color_override("font_color", Color(0.85, 0.8, 1.0))
	box.add_child(title)
	# Active first, then run-wide, then the ones that are off.
	dreams.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _rank(a) < _rank(b))
	for entry in dreams:
		box.add_child(_row(entry))
	return box

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
		return "off: " + reason if reason != "" else "off"
	return entry.get("effect", "")

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

static func get_dreams(data: TowerData, cell: Vector2, tower: Tower = null) -> Array:
	var dreams = _dream_state()  # Untyped: the query is guarded with has_method until it lands
	if dreams == null or not dreams.has_method("get_warden_dreams"):
		return []
	return dreams.get_warden_dreams(data, cell, tower).filter(func(e) -> bool:
		return e is Dictionary and e.get("card") is UpgradeData)

static func get_stat_parts(data: TowerData, cell: Vector2, stat: StringName, tower: Tower = null) -> Dictionary:
	var dreams = _dream_state()  # Untyped: the query is guarded with has_method until it lands
	if dreams == null or not dreams.has_method("get_stat_parts"):
		return {}
	var parts = dreams.get_stat_parts(data, cell, stat, tower)
	return parts if parts is Dictionary else {}

static func _dream_state() -> DreamState:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.get_first_node_in_group(DreamState.GROUP) as DreamState if tree else null
