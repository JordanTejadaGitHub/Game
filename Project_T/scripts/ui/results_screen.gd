extends Control
class_name ResultsScreen

# End of a run (win or lose): the Seeds breakdown, banked into HeartwoodMemory, then New run /
# Title. In the demo (project setting game/demo), a win shows the demo ending: the mist beyond the
# Deep Wood, Memory 1, the sleeping Memory Grove with the banked Seeds, and a Wishlist button
# (demo_scope.md). Built in code.

const DEMO_SETTING := "game/demo"
const WISHLIST_SETTING := "game/wishlist_url"
const TITLE_SCENE := "res://scenes/title.tscn"
const MEMORY_1 := "Before the Heartwood, there were two trees, side by side."

@onready var run_state: RunState = %RunState
@onready var drift_director: DriftDirector = %DriftDirector

var breakdown: Array = []  # [[label, seeds], …, ["Total", n]] of the finished run
var banked := 0  # Seeds banked after this run
var bank_in_tests := false  # Tests that point HeartwoodMemory.file_path at a temp file can bank

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	run_state.run_ended.connect(_on_run_ended)

static func is_demo() -> bool:
	return ProjectSettings.get_setting(DEMO_SETTING, false)

func _on_run_ended(won: bool) -> void:
	var first_run := HeartwoodMemory.is_first_run()
	breakdown = run_state.get_seed_breakdown(drift_director.drifts_cleared, drift_director.bosses_cleansed, first_run)
	if get_tree().current_scene == owner or bank_in_tests:
		banked = HeartwoodMemory.record_run(breakdown[-1][1], won, drift_director.drifts_started)
	else:  # A test's run: show what would be banked without touching the player's profile
		banked = HeartwoodMemory.load_data().seeds + breakdown[-1][1]
	_build(won)
	visible = true

func _build(won: bool) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.05, 0.06, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.custom_minimum_size = Vector2(460, 0)
	panel.add_child(box)

	var demo_end := won and is_demo()
	var title := "The mist thickens beyond the Deep Wood…" if demo_end \
		else ("The Heartwood is safe" if won else "The Heartwood goes dormant")
	_label(box, title, 28, Color(0.9, 1.0, 0.85))
	if not won:
		_label(box, "The Heartwood sleeps. A seed falls, and remembers.", 16, Color(0.8, 0.85, 0.8), true)
	if demo_end:
		_label(box, "“%s”" % MEMORY_1, 16, Color(0.85, 0.8, 1.0), true)

	box.add_child(HSeparator.new())
	for line in breakdown:
		var row := HBoxContainer.new()
		var name_label := _label(row, line[0], 16, Color.WHITE)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_label(row, "+%d Seeds" % line[1] if line[0] != "Total" else "%d Seeds" % line[1], 16,
			Color(0.75, 0.95, 0.6))
		box.add_child(row)
	box.add_child(HSeparator.new())

	if is_demo():
		# The Memory Grove teaser: asleep in the demo, waiting in the full game.
		_label(box, "The Memory Grove sleeps.", 18, Color(0.6, 0.65, 0.6))
		_label(box, "In the full game, every run grows your Memory Grove. Your %d Seeds will be waiting." % banked,
			15, Color(0.7, 0.75, 0.7), true)
	else:
		_label(box, "Seeds banked: %d" % banked, 16, Color(0.75, 0.95, 0.6))

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	if is_demo():
		var wishlist := _button(buttons, "Wishlist on Steam")
		var url: String = ProjectSettings.get_setting(WISHLIST_SETTING, "")
		wishlist.disabled = url == ""
		wishlist.tooltip_text = "Store page coming soon" if url == "" else url
		wishlist.pressed.connect(func() -> void: OS.shell_open(url))
	_button(buttons, "New run").pressed.connect(func() -> void: get_tree().reload_current_scene())
	_button(buttons, "Title").pressed.connect(func() -> void: get_tree().change_scene_to_file(TITLE_SCENE))

func _label(parent: Control, text: String, font_size: int, color: Color, wrap: bool = false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if parent is VBoxContainer else HORIZONTAL_ALIGNMENT_LEFT
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func _button(parent: Control, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(150, 40)
	parent.add_child(button)
	return button
