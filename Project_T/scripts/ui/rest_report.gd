extends PanelContainer
class_name RestReport

# Rest report (screens_ui.md "Combat feedback"): at every rest, a small card with the top 3 Wardens
# by damage this block and the combos triggered ("Lightning through Damp: 124 times"). Hides when
# the next block starts or on click. Built in code.

# ({damp} … are filled in with today's status names by IconInfo.format.)
const COMBO_LINES := {&"conducted": "Lightning through {damp}", &"popped": "Poison pops", &"asleep": "Put to sleep",
	&"crit": "Critical hits", &"weak": "Hits on weaknesses", &"marked": "Hits on {marked}", &"fog": "{spored} in fog",
	&"static": "{static} bolts"}
# Reaction damage tags that aren't a Reaction's own id (Echo Hollow's repeats): kept off the combo
# lines like the Reactions themselves.
const REACTION_TAGS: Array[StringName] = [&"echo", &"lightning_rod", &"dawnbreak"]

@onready var drift_director: DriftDirector = %DriftDirector

var _label := StatusLinks.make_label("", 15)  # Status names are links
var unbound_block := 0  # Nightmares that turned Unbound this block ("Unbound: N")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_label.custom_minimum_size = Vector2(260, 0)
	_label.mouse_filter = Control.MOUSE_FILTER_PASS  # Clicks reach the card (dismiss) too
	add_child(_label)
	visible = false
	# Deferred: the Harvest pours on rest_started too, so its totals are in by then.
	drift_director.rest_started.connect(func(block: int, _boss: bool, _bonus: int, _perfect: bool) -> void: show_report.call_deferred(block))
	drift_director.rest_ended.connect(func(_block: int) -> void:
		visible = false
		unbound_block = 0)
	var spawner := get_node_or_null("%EnemyContainer")
	if spawner != null and spawner.has_signal("nightmare_unbound"):  # No maze juggling (run_design.md)
		spawner.nightmare_unbound.connect(func(_e: Node2D) -> void: unbound_block += 1)

func _gui_input(event: InputEvent) -> void:
	# A click dismisses the card, unless it just opened a status link's popup.
	if event is InputEventMouseButton and event.pressed and not _link_open():
		visible = false

func show_report(block: int) -> void:
	var log := DamageLog.instance
	if log == null:
		return
	var combos := get_node_or_null("%ComboFeedback") as ComboFeedback
	var text := get_report_text(log, "block", log.combo_counts_block, "Block %d" % block,
		combos.block_counts if combos else {}, combos.block_longest_chain if combos else 0)
	# The maze line first, under the heading (screens_ui.md "Damage that means something").
	var meter_lines := meter_text(self)
	if meter_lines != "":
		var at := text.find("\n")
		text = (text + meter_lines) if at < 0 else text.substr(0, at) + meter_lines + text.substr(at)
	if combos and not combos.block_new.is_empty():  # screens_ui.md "The Codex": "New combos: …"
		var names: Array[String] = []
		for id in combos.block_new:
			names.append(CodexData.get_any(id).get("name", String(id)))
		text += "\nNew combos: " + ", ".join(names)
	if combos:
		# A line per Kinship formed this block (screens_ui.md "Kinship feedback", playtest fix).
		for kin in combos.kin_names_block:
			text += "\nKinship: " + kin
		text += kinship_text(0 if not combos.kin_names_block.is_empty() else combos.kin_formed_block,
			combos.harmony_block, combos.whole_block)
	text += _kin_hint()
	text += support_text(self, "block")
	text += templates_text(drift_director, block)
	var close_calls := CloseCalls.find(self)
	if close_calls != null and close_calls.block_count > 0:
		text += "\nClose calls: %d" % close_calls.block_count
	if unbound_block > 0:
		text += "\nUnbound: %d" % unbound_block
	_label.text = StatusLinks.bbcode(text)
	visible = true

# Random drifts (run_design.md): the block's rolled shapes, "This block: Swarm, Mixed, Heavy…" ("" when
# none of its drifts were rolled: block 1, a boss, the hand-made ones with random drifts off).
static func templates_text(director: DriftDirector, block: int) -> String:
	if director == null:
		return ""
	var names: Array[String] = []
	var first := (block - 1) * director.drifts_per_block + 1
	for number in range(first, mini(first + director.drifts_per_block, director.get_total_drifts() + 1)):
		var name := DriftRoller.template_name(director, number)
		if name != "":
			names.append(name)
	return "" if names.is_empty() else "\nThis block: " +", ".join(names)

# Support and economy (screens_ui.md "Support and economy feedback", Tower Code's SupportLog): the
# Harvest, the top supporter, what the walls and the control Wardens did. "block" for the rest
# report, "run" for the results ("Best supporter"). "" when there's nothing.
static func support_text(near: Node, period: String) -> String:
	var support = SupportLog.find(near)
	if support == null:
		return ""
	var lines: Array[String] = []
	var totals: Dictionary = support.get_totals(period)
	if period == "block" and int(totals.get("dew_paid", 0)) > 0:
		lines.append("Harvest +%d Dew" % int(totals.dew_paid))
	var top: Dictionary = support.get_top_support(period)
	if not top.is_empty():
		lines.append("%s: %s" % ["Top support" if period == "block" else "Best supporter", top.get("text", "")])
	if period == "block" and int(totals.get("path_tiles", 0)) > 0:
		lines.append("Your walls added %d path tiles" % int(totals.path_tiles))
	var held := float(totals.get("held_seconds", 0.0))
	var pulled := int(totals.get("tiles_pulled", 0))
	if held >= 1.0 or pulled > 0:
		var parts: Array[String] = []
		if held >= 1.0:
			parts.append("Held for %d s" % roundi(held))
		if pulled > 0:
			parts.append("pulled back %d tiles" % pulled)
		lines.append(" · ".join(parts))
	return "" if lines.is_empty() else "\n" + "\n".join(lines)

# Kinships (screens_ui.md "Kinship feedback"): "Kinships formed: 2 · Harmony strikes: 84" and "The
# Sporeling line is whole." ("" when there's nothing). Shared with the results screen (the run).
static func kinship_text(formed: int, harmony: int, whole: Array) -> String:
	var text := ""
	var parts: Array[String] = []
	if formed > 0:
		parts.append("Kinships formed: %d" % formed)
	if harmony > 0:
		parts.append("Harmony strikes: %d" % harmony)
	if not parts.is_empty():
		text += "\n" + " · ".join(parts)
	for line in whole:  # Kinships pass the line ("spore"); the report names the family
		var family: String = CodexData.LINE_FAMILIES.get(String(line), String(line))
		text += "\nThe %s line is whole." % CodexData.FAMILY_NAMES.get(family, family.capitalize())
	return text

var _kin_hint_shown := false

# Once per run, at the first rest where two branches of one family are planted but no Kinship has
# formed: how Kinships work (screens_ui.md "Kinship feedback", playtest fix).
func _kin_hint() -> String:
	if _kin_hint_shown:
		return ""
	var towers := get_node("%TowerContainer").get_children()
	if two_branch_family(towers) == "" or Kinships.count_on_map(self) > 0:
		return ""
	_kin_hint_shown = true
	return "\nNo Kinships yet: two branches of one family within 2 cells"

# A family (damage line) with Wardens from two of its branches planted, or "" (Kinships.branch_of).
static func two_branch_family(towers: Array) -> String:
	var branches := {}  # line -> {branch: true}
	for tower in towers:
		if not tower is Tower:
			continue
		var branch := Kinships.branch_of(tower.tower_data)
		if branch == "":
			continue
		var line: String = tower.tower_data.line
		if not branches.has(line):
			branches[line] = {}
		branches[line][branch] = true
		if branches[line].size() >= 2:
			return line
	return ""

func _link_open() -> bool:
	return _label.get_children().any(func(c: Node) -> bool: return c is StatusLinks and c.visible)

# Shared with the results screen (the whole run). `reactions` {id: n} and `longest_chain` add a
# Reactions line (screens_ui.md "Reactions": per type and the longest chain).
static func get_report_text(log: DamageLog, period: String, counts: Dictionary, heading: String,
		reactions: Dictionary = {}, longest_chain: int = 0) -> String:
	var lines: Array[String] = [heading]
	var top := log.get_top_towers(period, 3)
	if top.is_empty():
		lines.append("No damage dealt.")
	for i in top.size():
		lines.append("%d. %s — %d" % [i + 1, top[i].name, roundi(top[i].amount)])
	# Reaction damage is tagged too (thunderclap, ignite, …); those are counted on the Reactions line.
	var tags := counts.keys().filter(func(tag: StringName) -> bool:
		return Reactions.get_data(tag) == null and not REACTION_TAGS.has(tag))
	tags.sort_custom(func(a: StringName, b: StringName) -> bool: return counts[a] > counts[b])
	for tag in tags.slice(0, 3):
		lines.append("%s: %d times" % [IconInfo.format(COMBO_LINES.get(tag, String(tag))), counts[tag]])
	if not reactions.is_empty():
		lines.append("Reactions: " + ComboFeedback.summary(reactions, longest_chain))
	return "\n".join(lines)

# The block against the next drift (Tower Code's WardenMeter.get_block_summary): "Maze 1,240 DPS ·
# ↑12% vs last block · next drift needs ~980", then Carrying / Underused (with the reason) / Most
# improved. "" before there's a meter.
static func meter_text(near: Node) -> String:
	var meter := WardenMeter.find(near)
	if meter == null:
		return ""
	var s: Dictionary = meter.get_block_summary()
	if float(s.get("maze_dps", 0.0)) <= 0.0:
		return ""
	var line := "Maze %s DPS" % DriftMeter.fmt(s.maze_dps)
	var change := DriftMeter.change_text(s.get("change"))
	if change != "":
		line += " · %s vs last block" % change
	if DriftMeter.show_estimate() and float(s.get("needed_dps", 0.0)) > 0.0:  # Dev-only (playtest fixes 2026-09-30)
		line += " · next drift needs ~%s" % DriftMeter.fmt(s.needed_dps)
	var lines: Array[String] = [line]
	var carrying: Array = s.get("carrying", [])
	if not carrying.is_empty():
		lines.append("Carrying: " + ", ".join(carrying.map(func(r: Dictionary) -> String: return r.name)))
	for r in s.get("underused", []):
		lines.append("Underused: %s%s" % [r.name, " (%s)" % r.reason if String(r.get("reason", "")) != "" else ""])
	var improved: Dictionary = s.get("most_improved", {})
	if not improved.is_empty():
		lines.append("Most improved: %s %s" % [improved.name, DriftMeter.change_text(improved.get("change"))])
	return "\n" + "\n".join(lines)
