extends PanelContainer
class_name RestReport

# Rest report (screens_ui.md "Combat feedback"): at every rest, a small card with the top 3 Wardens
# by damage this block and the combos triggered ("Lightning through Damp: 124 times"). Hides when
# the next block starts or on click. Built in code.

const COMBO_LINES := {&"conducted": "Lightning through Damp", &"popped": "Spore pops", &"asleep": "Put to sleep",
	&"crit": "Critical hits", &"weak": "Hits on weaknesses", &"marked": "Hits on Marked", &"fog": "Spores in fog",
	&"static": "Static bolts"}

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
	_label.text = get_report_text(log, "block", log.combo_counts_block, "Block %d" % block)
	visible = true

# Shared with the results screen (the whole run).
static func get_report_text(log: DamageLog, period: String, counts: Dictionary, heading: String) -> String:
	var lines: Array[String] = [heading]
	var top := log.get_top_towers(period, 3)
	if top.is_empty():
		lines.append("No damage dealt.")
	for i in top.size():
		lines.append("%d. %s — %d" % [i + 1, top[i].name, roundi(top[i].amount)])
	var tags := counts.keys()
	tags.sort_custom(func(a: StringName, b: StringName) -> bool: return counts[a] > counts[b])
	for tag in tags.slice(0, 3):
		lines.append("%s: %d times" % [COMBO_LINES.get(tag, String(tag)), counts[tag]])
	return "\n".join(lines)
