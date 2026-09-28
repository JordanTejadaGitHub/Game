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

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_label.custom_minimum_size = Vector2(260, 0)
	_label.mouse_filter = Control.MOUSE_FILTER_PASS  # Clicks reach the card (dismiss) too
	add_child(_label)
	visible = false
	drift_director.rest_started.connect(func(block: int, _boss: bool, _bonus: int, _perfect: bool) -> void: show_report(block))
	drift_director.rest_ended.connect(func(_block: int) -> void: visible = false)

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
	if combos and not combos.block_new.is_empty():  # screens_ui.md "The Codex": "New combos: …"
		var names: Array[String] = []
		for id in combos.block_new:
			names.append(CodexData.get_any(id).get("name", String(id)))
		text += "\nNew combos: " + ", ".join(names)
	if combos:
		text += kinship_text(combos.kin_formed_block, combos.harmony_block, combos.whole_block)
	_label.text = StatusLinks.bbcode(text)
	visible = true

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
