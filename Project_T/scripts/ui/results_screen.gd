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
	WorldLabel.cover_while_visible(self, &"results_screen")  # No world tags (DPS, hover names) over a full-screen screen
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
	# Solid behind the text (story chat: a whisper read through it beside the quote), as the dossier and Settings
	var fill := panel.get_theme_stylebox("panel")
	if fill is MoonStyleBox:
		var solid := (fill as MoonStyleBox).duplicate() as MoonStyleBox
		solid.center_alpha = UiStyle.TIP_ALPHA
		solid.edge_alpha = UiStyle.TIP_ALPHA
		panel.add_theme_stylebox_override("panel", solid)
	var scroll := ScrollContainer.new()  # A short screen: the panel scrolls rather than leaving it
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.custom_minimum_size = Vector2(580, 0)
	scroll.add_child(box)
	var fit := func() -> void:  # The panel's height: its content, at most the screen less a margin
		if is_instance_valid(scroll) and is_inside_tree():
			scroll.custom_minimum_size.y = minf(box.get_combined_minimum_size().y, get_viewport_rect().size.y - 80.0)
	box.minimum_size_changed.connect(fit)
	fit.call_deferred()

	# Light pass (UI Asset's second page, user-approved): the title and its whisper, the run as one icon row, the
	# families' emblems, the Seeds as rows with a total, then one primary (New run) beside the Memory Grove, and
	# Copy run report / Title quiet. The long combat report folds behind "Run report".
	var demo_end := won and is_demo()
	# Runs go to the Hollow Oak at drift 100, in the demo too (demo_scope.md).
	var title := _label(box, "The Hollow Oak is dispelled" if won else "The dream goes dark", 36, UiStyle.INK)
	UiStyle.display(title, 36)
	if not won:
		UiStyle.whisper(_label(box, "“I'm so tired. Here, take a seed. Try again.”", 17, UiStyle.WHISPER, true), 17)
	if demo_end:
		_label(box, "“%s”" % MEMORY_1, 16, Palette.DEWLIGHT, true)

	var stats := HBoxContainer.new()
	stats.name = "RunStats"
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 22)
	box.add_child(stats)
	# Drift reached = the nightmares' mark; the path icon only for the longest path (user: the same icon twice)
	for stat in [[&"swarm", drift_director.drifts_started, "drift reached"], [&"damage", run_state.creatures_cleansed, "dispelled"],
			[&"leaves", run_state.leaves_lost, "leaves lost"], [&"path_length", run_state.longest_path, "longest path"]]:
		stats.add_child(_stat(stat[0], int(stat[1]), stat[2]))
	var families := _family_row()
	if families.get_child_count() > 0:
		box.add_child(families)
	var best := RestReport.best_dream(self)  # Feeling the cards (dream_design.md), in UI Code's credit look
	if not best.is_empty():
		var best_label := RichTextLabel.new()
		best_label.name = "BestDream"
		best_label.bbcode_enabled = true
		best_label.fit_content = true
		best_label.scroll_active = false
		best_label.text = UiStyle.credit_bbcode("Best Dream", [best])
		box.add_child(best_label)
	# The run report (screens_ui.md "Combat feedback"): top Wardens and the most-used combos, folded.
	var tracker := get_tree().get_first_node_in_group(ReactionTracker.GROUP) as ReactionTracker
	if DamageLog.instance != null and not DamageLog.instance.get_top_towers("run", 1).is_empty():
		var combos := get_node_or_null("%ComboFeedback") as ComboFeedback
		var kin := RestReport.kinship_text(combos.kin_formed_run, combos.harmony_run, combos.whole_run) if combos else ""
		var report := StatusLinks.make_label(RestReport.get_report_text(DamageLog.instance, "run",
			DamageLog.instance.combo_counts_run, "Wardens this run", tracker.counts if tracker else {},
			tracker.longest_chain if tracker else 0) + kin + RestReport.dreams_text(self, &"run", "Dreams this run", 0)
			+ support_lines(), 14, UiStyle.MOONLIGHT)
		report.name = "RunReport"
		report.visible = false
		# Its heading line with a small Details link at the right (user: no control floating mid-screen)
		var heading := HBoxContainer.new()
		heading.name = "RunReportHeading"
		var report_title := Label.new()
		report_title.text = "Wardens and combos"
		report_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiStyle.caps(report_title, 14)
		heading.add_child(report_title)
		var toggle := _link(heading, "Details")
		toggle.name = "DetailsToggle"
		toggle.custom_minimum_size.y = 0
		toggle.pressed.connect(func() -> void:
			report.visible = not report.visible
			toggle.text = "Hide" if report.visible else "Details")
		box.add_child(heading)
		box.add_child(report)

	var seeds := VBoxContainer.new()
	seeds.name = "Seeds"
	seeds.add_theme_constant_override("separation", 4)
	box.add_child(seeds)
	for line in breakdown:
		if line[0] == "Total":
			continue
		var row := HBoxContainer.new()
		var name_label := _label(row, line[0], 15, UiStyle.INK_DIM)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UiStyle.number(_label(row, "+%d" % line[1], 17, UiStyle.LIVE), 17, UiStyle.LIVE)
		seeds.add_child(row)
	seeds.add_child(HSeparator.new())
	var total := HBoxContainer.new()
	total.name = "SeedsTotal"
	var total_label := _label(total, "Seeds banked" if not is_demo() else "Seeds earned", 20, UiStyle.INK)
	UiStyle.display(total_label, 20)
	total_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total.add_child(_icon(&"seeds", 24))
	UiStyle.number(_label(total, str(breakdown[-1][1]) if not breakdown.is_empty() else "0", 24, UiStyle.LIVE), 24, UiStyle.LIVE)
	seeds.add_child(total)
	if not is_demo():
		_label(box, "%d in the bank" % banked, 14, UiStyle.INK_DIM).name = "SeedsBanked"
	if not_banked and not CaptureDirector.capturing():  # Captures force Test Grove: no dev line on screen
		_label(box, "%s: nothing was banked." % ("Test Grove" if TestGrove.is_active() else "Developer run"), 15,
			UiStyle.GOLD)
	if is_demo():
		# The Memory Grove teaser: asleep in the demo, waiting in the full game.
		_label(box, "The Memory Grove sleeps.", 18, Palette.PATH)
		var teaser := _grove_teaser()  # A few real nodes by name and icon, tagged "Full game" (user 7938c7b2)
		if teaser.get_child_count() > 0:
			box.add_child(teaser)
		_label(box, "In the full game, every run grows your Memory Grove. Your %d Seeds will be waiting." % banked,
			15, UiStyle.INK_DIM, true)

	var buttons := GridContainer.new()
	buttons.columns = 2
	buttons.add_theme_constant_override("h_separation", 12)
	box.add_child(buttons)
	if is_demo():
		var wishlist := _button(buttons, "Wishlist on Steam")
		var url: String = ProjectSettings.get_setting(WISHLIST_SETTING, "")
		wishlist.disabled = url == ""
		wishlist.tooltip_text = "Store page coming soon" if url == "" else url
		wishlist.pressed.connect(func() -> void: OS.shell_open(url))
	else:  # screens_ui.md: Results → Memory Grove
		_button(buttons, "Memory Grove").pressed.connect(func() -> void:
			get_tree().change_scene_to_file("res://scenes/grove.tscn"))
	for button in buttons.get_children():
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var new_run := _button(buttons, "New run")
	new_run.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiStyle.primary(new_run)  # The one primary
	new_run.pressed.connect(func() -> void: get_tree().reload_current_scene())
	var quiet := HBoxContainer.new()
	quiet.alignment = BoxContainer.ALIGNMENT_CENTER
	quiet.add_theme_constant_override("separation", 12)
	box.add_child(quiet)
	var copy := _small(quiet, "Copy run report")  # For the design chat (RunHistory.report_text)
	copy.name = "CopyReport"
	copy.tooltip_text = "Copies this run's numbers as text."
	copy.pressed.connect(func() -> void:
		var history := get_tree().get_first_node_in_group(RunHistory.GROUP) as RunHistory
		if history != null:
			DisplayServer.clipboard_set(RunHistory.report_text(history.run))
			copy.text = "Copied ✓"  # A flash on the link itself, then back (user: not a separate-looking item)
			get_tree().create_timer(1.5, true).timeout.connect(func() -> void:
				if is_instance_valid(copy):
					copy.text = "Copy run report"))
	var to_title := _small(quiet, "Title")
	to_title.name = "ToTitle"
	to_title.pressed.connect(func() -> void: get_tree().change_scene_to_file(TITLE_SCENE))

# The demo's Grove teaser (demo_scope.md "Show what the full game holds"): one family, one perk and one Legendary Dream
# from the real Memory Grove, by name and icon, each tagged "Full game".
const GROVE_ICON_SHEETS := {"perks": "res://assets/meta/icons/perk_icons.png",
	"families": "res://assets/meta/icons/family_icons.png", "cards": "res://assets/meta/icons/card_bundle_icons.png"}

func _grove_teaser() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "GroveTeaser"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 28)
	var picks: Array = [null, null, null]
	for unlock in HeartwoodMemory.load_grove():
		if unlock.start:
			continue
		if picks[0] == null and not unlock.families.is_empty() and unlock.families.any(func(id: String) -> bool: return not CodexData.DEMO_FAMILIES.has(id)):
			picks[0] = unlock
		elif picks[1] == null and unlock.root == UnlockData.Root.PERKS and unlock.icon >= 0:
			picks[1] = unlock
		elif picks[2] == null and unlock.legendary:
			picks[2] = unlock
	for unlock in picks:
		if unlock == null:
			continue
		var item := VBoxContainer.new()
		item.add_theme_constant_override("separation", 2)
		var icon := TextureRect.new()
		var sheet_path: String = GROVE_ICON_SHEETS.get(unlock.get_section(), "")
		if unlock.icon >= 0 and sheet_path != "" and ResourceLoader.exists(sheet_path):
			var atlas := AtlasTexture.new()
			atlas.atlas = load(sheet_path)
			atlas.region = Rect2(unlock.icon * 32, 0, 32, 32)
			icon.texture = atlas
		icon.custom_minimum_size = Vector2(48, 48)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		item.add_child(icon)
		var name_label := Label.new()
		name_label.text = unlock.display_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 14)
		item.add_child(name_label)
		var tag := Label.new()
		tag.name = "FullGameTag"
		tag.text = "Full game"
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		UiStyle.caps(tag, 12, UiStyle.GOLD)
		item.add_child(tag)
		row.add_child(item)
	return row

# One stat of the run's icon row: the icon and its number, a caps label under them.
func _stat(icon_id: StringName, value: int, caption: String) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 5)
	top.add_child(_icon(icon_id, 24))
	var number := Label.new()
	number.text = BossDossier.thousands(value)
	UiStyle.number(number, 22)
	top.add_child(number)
	column.add_child(top)
	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.caps(label, 13)
	column.add_child(label)
	return column

func _icon(icon_id: StringName, size: float) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = IconInfo.icon(icon_id)
	icon.custom_minimum_size = Vector2(size, size)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return icon

# The run's families as their emblems (the base Warden's frame where there's no emblem yet).
func _family_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Families"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	var dream_state := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	if dream_state == null:
		return row
	for data in (%TowerPlacer as TowerPlacer).towers:
		if data.tier != 1 or not dream_state.is_unlocked(data.get_id()):
			continue
		var art := BranchEmblem.family(data)
		if art == null and data.texture != null:
			var frame := AtlasTexture.new()
			frame.atlas = data.texture
			frame.region = data.get_frame_rect(0)
			art = frame
		var emblem := TextureRect.new()
		emblem.texture = art
		emblem.custom_minimum_size = Vector2(32, 32)
		emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		emblem.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		emblem.tooltip_text = data.display_name
		row.add_child(emblem)
	return row

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

# A small framed secondary (Copy run report, Title; user: "why are all the buttons different?": real choices are
# framed, quiet text only for in-panel utilities like Details).
func _small(parent: Control, text: String) -> Button:
	var button := _button(parent, text)
	button.custom_minimum_size = Vector2(130, 40)
	button.add_theme_font_size_override("font_size", 14)
	return button

# A quiet link (Details, an in-panel utility): one shared look, the light pass's quiet style with an underline on
# hover, so they read as links and not stray labels.
func _link(parent: Control, text: String) -> Button:
	var link := _button(parent, text)
	UiStyle.quiet(link)
	link.custom_minimum_size.x = 0
	link.draw.connect(func() -> void:
		if not link.is_hovered():
			return
		var font := link.get_theme_font("font")
		var font_size := link.get_theme_font_size("font_size")
		var width := font.get_string_size(link.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var y := link.size.y / 2.0 + font_size * 0.5 + 2.0
		var x := (link.size.x - width) / 2.0
		link.draw_line(Vector2(x, y), Vector2(x + width, y), Color(UiStyle.GOLD, 0.7), 1.0))
	link.mouse_entered.connect(link.queue_redraw)
	link.mouse_exited.connect(link.queue_redraw)
	return link

func _button(parent: Control, text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(150, UiStyle.HUD_BUTTON_H)  # 48: a tap target
	parent.add_child(button)
	return button

# screens_ui.md "Support and economy feedback": the run's best supporter (next to the best Wardens)
# and the Dew the catchers harvested.
func support_lines() -> String:
	var text := RestReport.support_text(self, "run")
	if run_state.dew_harvested > 0:
		text += "\nDew harvested: %d" % run_state.dew_harvested
	return text
