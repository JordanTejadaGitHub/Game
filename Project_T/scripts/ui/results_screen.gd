extends Control
class_name ResultsScreen

# End of a run (win or lose): the Seeds breakdown, banked into HeartwoodMemory, then New run /
# Title. A win means the Hollow Oak (drift 100) is dispelled; in the demo (project setting game/demo)
# it also shows Memory 1, the sleeping Memory Grove with the banked Seeds, and a Wishlist button
# (demo_scope.md). Built in code.

const DEMO_SETTING := "game/demo"
const DEMO_MODE_SETTING := "demo_mode"
const WISHLIST_SETTING := "game/wishlist_url"
const TITLE_SCENE := "res://scenes/title.tscn"
const MEMORY_1 := "Before the Heartwood, there were two trees, and both of them dreamed."

@onready var run_state: RunState = %RunState
@onready var drift_director: DriftDirector = %DriftDirector

var breakdown: Array = []  # [[label, seeds], …, ["Total", n]] of the finished run
var banked := 0  # Seeds banked after this run
var bank_in_tests := false  # Tests that point HeartwoodMemory.file_path at a temp file can bank
var not_banked := false  # Developer run: the breakdown is shown but nothing was saved

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	run_state.run_ended.connect(_on_run_ended)

# The demo or the full game. The project setting game/demo decides, except in debug builds where the
# Developer "Demo mode" setting (demo_scope.md "Demo mode toggle", `demo_mode`: -1 = project
# setting, 0 = full game, 1 = demo) can override it. Headless test scripts ignore the override.
# Tests: 0 = full game, 1 = demo, -1 = as configured.
static var demo_override := -1

static func is_demo() -> bool:
	if demo_override >= 0:
		return demo_override == 1
	if OS.is_debug_build() and not OS.get_cmdline_args().has("--script"):
		var override := int(HeartwoodMemory.get_settings().get(DEMO_MODE_SETTING, -1))
		if override >= 0:
			return override == 1
	return ProjectSettings.get_setting(DEMO_SETTING, false)

func _on_run_ended(won: bool) -> void:
	# Test Grove (developer playtests) never banks Seeds or counts as a run, so it can't inflate the
	# real save, and never gets the first-run bonus.
	var test_grove := MetaRun.is_dev_run()  # Test Grove or Unlock all families
	var first_run := HeartwoodMemory.is_first_run() and not test_grove
	breakdown = run_state.get_seed_breakdown(drift_director.drifts_cleared, drift_director.bosses_cleansed, first_run)
	if (get_tree().current_scene == owner or bank_in_tests) and not test_grove:
		banked = HeartwoodMemory.record_run(breakdown[-1][1], won, drift_director.drifts_started)
	else:  # A test's or Test Grove run: show what would be banked without touching the profile
		banked = HeartwoodMemory.load_data().seeds + breakdown[-1][1]
		not_banked = test_grove
	_build(won)
	visible = true

func _build(won: bool) -> void:
	var dim := ColorRect.new()
	dim.color = Color(UiStyle.FOG, 0.8)
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
	# Runs go to the Hollow Oak at drift 100, in the demo too (demo_scope.md).
	var title := "The Hollow Oak is dispelled" if won else "The dream goes dark"
	_label(box, title, 28, UiStyle.INK)
	if not won:
		_label(box, "The Heartwood sinks into dreamless sleep. A seed falls, and remembers.", 16, UiStyle.WHISPER, true)
	if demo_end:
		_label(box, "“%s”" % MEMORY_1, 16, Palette.DEWLIGHT, true)

	box.add_child(HSeparator.new())
	_label(box, get_stats_text(), 15, UiStyle.MOONLIGHT, true)
	var best := RestReport.best_dream(self)  # Feeling the cards (dream_design.md), in UI Code's credit look
	if not best.is_empty():
		var best_label := RichTextLabel.new()
		best_label.name = "BestDream"
		best_label.bbcode_enabled = true
		best_label.fit_content = true
		best_label.scroll_active = false
		best_label.text = UiStyle.credit_bbcode("Best Dream", [best])
		box.add_child(best_label)
	# The run report (screens_ui.md "Combat feedback"): top Wardens and the most-used combos.
	var tracker := get_tree().get_first_node_in_group(ReactionTracker.GROUP) as ReactionTracker
	if DamageLog.instance != null and not DamageLog.instance.get_top_towers("run", 1).is_empty():
		# The run report, with its status names as links (hover / tap).
		var combos := get_node_or_null("%ComboFeedback") as ComboFeedback
		var kin := RestReport.kinship_text(combos.kin_formed_run, combos.harmony_run, combos.whole_run) if combos else ""
		box.add_child(StatusLinks.make_label(RestReport.get_report_text(DamageLog.instance, "run",
			DamageLog.instance.combo_counts_run, "Wardens this run", tracker.counts if tracker else {},
			tracker.longest_chain if tracker else 0) + kin + RestReport.dreams_text(self, &"run", "Dreams this run", 0)
			+ support_lines(), 14, UiStyle.MOONLIGHT))
	box.add_child(HSeparator.new())
	for line in breakdown:
		var row := HBoxContainer.new()
		var name_label := _label(row, line[0], 16, UiStyle.INK)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_label(row, "+%d Seeds" % line[1] if line[0] != "Total" else "%d Seeds" % line[1], 16,
			UiStyle.LIVE)
		box.add_child(row)
	box.add_child(HSeparator.new())
	if not_banked:
		_label(box, "%s: nothing was banked." % ("Test Grove" if TestGrove.is_active() else "Developer run"), 15,
			UiStyle.GOLD)

	if is_demo():
		# The Memory Grove teaser: asleep in the demo, waiting in the full game.
		_label(box, "The Memory Grove sleeps.", 18, Palette.PATH)
		_label(box, "In the full game, every run grows your Memory Grove. Your %d Seeds will be waiting." % banked,
			15, UiStyle.INK_DIM, true)
	else:
		_label(box, "Seeds banked: %d" % banked, 16, UiStyle.LIVE)

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
	if not is_demo():  # screens_ui.md: Results → Memory Grove
		_button(buttons, "Memory Grove").pressed.connect(func() -> void:
			get_tree().change_scene_to_file("res://scenes/grove.tscn"))
	var copy := _button(buttons, "Copy run report")  # For the design chat (RunHistory.report_text)
	copy.tooltip_text = "Copies this run's numbers as text."
	copy.pressed.connect(func() -> void:
		var history := get_tree().get_first_node_in_group(RunHistory.GROUP) as RunHistory
		if history != null:
			DisplayServer.clipboard_set(RunHistory.report_text(history.run))
			copy.text = "Copied")
	_button(buttons, "New run").pressed.connect(func() -> void: get_tree().reload_current_scene())
	_button(buttons, "Title").pressed.connect(func() -> void: get_tree().change_scene_to_file(TITLE_SCENE))

# The run in numbers (screens_ui.md "Results"): drift reached, drifts survived, nightmares
# dispelled, leaves lost, longest path, Dreams taken, families.
func get_stats_text() -> String:
	var dream_state := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	var dreams := 0
	var families: Array[String] = []
	if dream_state != null:
		for id in dream_state.stacks:
			dreams += dream_state.stacks[id]
		for data in (%TowerPlacer as TowerPlacer).towers:
			if data.tier == 1 and dream_state.is_unlocked(data.get_id()):
				families.append(data.display_name)
	return "Drift %d reached · %d survived\nNightmares dispelled: %d · Leaves lost: %d\nLongest path: %d tiles · Dreams: %d\nFamilies: %s" % [
		drift_director.drifts_started, drift_director.drifts_cleared, run_state.creatures_cleansed,
		run_state.leaves_lost, run_state.longest_path, dreams,
		", ".join(families) if not families.is_empty() else "none"]

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

# screens_ui.md "Support and economy feedback": the run's best supporter (next to the best Wardens)
# and the Dew the catchers harvested.
func support_lines() -> String:
	var text := RestReport.support_text(self, "run")
	if run_state.dew_harvested > 0:
		text += "\nDew harvested: %d" % run_state.dew_harvested
	return text
