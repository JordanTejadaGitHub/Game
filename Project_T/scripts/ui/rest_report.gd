extends PanelContainer
class_name RestReport

# Rest report (screens_ui.md "Combat feedback"): at every rest, a small card with the top 3 Wardens
# by damage this block and the combos triggered ("Lightning through Damp: 124 times"). Hides when
# the next block starts or on click. Built in code.

const COMBO_LINES := {&"conducted": "Lightning through Damp", &"popped": "Spore pops", &"asleep": "Put to sleep",
	&"crit": "Critical hits", &"weak": "Hits on weaknesses", &"marked": "Hits on Marked", &"fog": "Spores in fog",
	&"static": "Static bolts"}
# Reaction damage tags that aren't a Reaction's own id (Echo Hollow's repeats): kept off the combo
# lines like the Reactions themselves.
const REACTION_TAGS: Array[StringName] = [&"echo", &"lightning_rod", &"dawnbreak"]

@onready var drift_director: DriftDirector = %DriftDirector

var _label := Label.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(260, 0)
	add_child(_label)
	visible = false
	drift_director.rest_started.connect(func(block: int, _boss: bool, _bonus: int, _perfect: bool) -> void: show_report(block))
	drift_director.rest_ended.connect(func(_block: int) -> void: visible = false)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		visible = false

func show_report(block: int) -> void:
	var log := DamageLog.instance
	if log == null:
		return
	var reactions := get_node_or_null("%ReactionFeedback") as ReactionFeedback
	_label.text = get_report_text(log, "block", log.combo_counts_block, "Block %d" % block,
		reactions.block_counts if reactions else {}, reactions.block_longest_chain if reactions else 0)
	visible = true

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
		lines.append("%s: %d times" % [COMBO_LINES.get(tag, String(tag)), counts[tag]])
	if not reactions.is_empty():
		lines.append("Reactions: " + ReactionFeedback.summary(reactions, longest_chain))
	return "\n".join(lines)
