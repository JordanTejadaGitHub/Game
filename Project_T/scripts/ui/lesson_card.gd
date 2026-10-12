class_name LessonCard
extends Control

# Lessons (onboarding.md "Lessons", 570cb7f5; user: "learning new things should pause and put a text up"): a rule the
# player can't guess and that costs them if missed pauses the game under a small centred card (the new-nightmare card's
# look: icon, title, one or two sentences, "Got it"; Esc / Enter close it). Each fires once per profile (SEEN_KEY, real
# game only, like the whispers), the Hints setting turns them off, never over a choice or rest screen (it waits for the
# map; RestScreens lists it so they wait for it too), and at most one per drift (the rest queue). Texts read live
# numbers. Made by the HUD.

const GROUP := &"lesson_card"
const SEEN_KEY := "lessons_seen"
const WIDTH := 420.0
const INTRO_IDS := [&"intro_heartwood", &"intro_maze", &"intro_dew"]
signal lesson_shown(id: StringName)

var enabled := true  # The Hints setting ("whispers")
var one_per_drift := true  # Tests turn it off to see each trigger
var seen: Array = []  # Lesson ids shown on this profile
var queue: Array = []  # [id, icon, title, text] waiting for the map
var shown_id: StringName = &""
var _last_drift := -1  # drifts_started when the last Lesson showed
var _plants_in_mode := 0  # Placements since build mode came on (the "Build mode" Lesson at the second)
var _paused_it := false
var _resume_pending := false
var _replaying := false

var main: Node
var drift_director: DriftDirector
var tower_placer: TowerPlacer
var tower_seller: TowerSeller
var dream_state: DreamState
var game_speed: GameSpeed
var _icon := TextureRect.new()
var _title := Label.new()
var _body: RichTextLabel = StatusLinks.make_label("", 16)  # Glossary words are links here too (user 2026-10-12: the Soaked card's "Reactions"): hover or tap for the tip
var _ok := Button.new()
var _skip := Button.new()
var _demo: LessonDemo

func _ready() -> void:
	add_to_group(GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	WorldLabel.cover_while_visible(self, &"lesson_card")
	var shade := ColorRect.new()
	shade.color = Color(UiStyle.FOG, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	var panel := PanelContainer.new()
	panel.name = "Card"
	var solid := UiStyle.panel(18.0, 18.0)  # Solid, like every paused card
	solid.center_alpha = UiStyle.TIP_ALPHA
	solid.edge_alpha = UiStyle.TIP_ALPHA
	panel.add_theme_stylebox_override("panel", solid)
	centre.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	box.add_child(head)
	_icon.custom_minimum_size = Vector2(32, 32)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	head.add_child(_icon)
	_title.name = "Title"
	UiStyle.title(_title, 24)
	head.add_child(_title)
	_body.name = "Body"
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(WIDTH, 0)
	box.add_child(_body)
	_demo = LessonDemo.new()
	_demo.visible = false
	box.add_child(_demo)
	_ok.name = "GotIt"
	_ok.text = "Got it"
	_ok.focus_mode = Control.FOCUS_NONE
	_ok.custom_minimum_size = Vector2(160, UiStyle.HUD_BUTTON_H)
	_ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UiStyle.primary(_ok)
	_ok.pressed.connect(close)
	box.add_child(_ok)
	_skip.name = "SkipTutorial"
	_skip.text = "Skip tutorial"
	_skip.focus_mode = Control.FOCUS_NONE
	_skip.custom_minimum_size = Vector2(160, UiStyle.HUD_BUTTON_H)
	_skip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_skip.pressed.connect(skip_intro)
	_skip.visible = false
	box.add_child(_skip)
	var memory := HeartwoodMemory.load_data()
	enabled = bool(memory.settings.get("whispers", true))
	seen = memory.get(SEEN_KEY, []).duplicate()
	_hook.call_deferred()

func _hook() -> void:
	main = get_parent().owner if get_parent() != null else null
	if main == null:
		return
	if get_tree().current_scene != main:
		enabled = false  # Tests build and play without Lessons pausing them (test_lessons turns them on)
	drift_director = main.get_node_or_null("%DriftDirector")
	tower_placer = main.get_node_or_null("%TowerPlacer")
	tower_seller = main.get_node_or_null("%TowerSeller")
	dream_state = main.get_node_or_null("%DreamState")
	game_speed = main.get_node_or_null("%GameSpeed")
	if game_speed != null:
		game_speed.changed.connect(func(on: bool, _speed: float) -> void:
			if visible and not on:
				game_speed.set_paused(true))
	if enabled and get_tree().current_scene == main and HeartwoodMemory.is_first_run() and drift_director.drifts_started == 0:
		start_intro()
	# The teaching whispers are gone (onboarding.md "Whisper hints removed", user 2026-10-12): the status and flyer
	# Lessons, which their whispers used to set off, watch the field themselves (_watch_field, below), and two Lessons
	# cover what only a whisper taught: "Rests" (the first rest) and "Speed and pause" (_watch_field).
	if drift_director != null:
		drift_director.rest_started.connect(func(_block: int, _boss: bool, _bonus: int, _perfect: bool) -> void:
			lesson(&"rests", &"dew", "Rests", "Between blocks the forest rests. Selling returns more here, and nothing moves until you start the next drift."))
	if tower_placer != null:
		tower_placer.tower_built.connect(_on_built)
		if tower_placer.has_signal("build_mode_changed"):
			tower_placer.build_mode_changed.connect(func(_on: bool) -> void: _plants_in_mode = 0)
	if tower_seller != null:
		tower_seller.tower_sold.connect(_on_sold)
		tower_seller.selection_changed.connect(func(towers: Array[Tower]) -> void:
			if not drift_director.is_resting():
				return
			var run := main.get_node("%RunState") as RunState
			for tower in towers:
				if tower.can_nurture() and run.can_afford(tower.get_nurture_cost()):
					discovery(&"nurture")
				for option in Tower.grow_options(dream_state, tower.tower_data):
					if option[1] and run.can_afford(tower.get_grow_cost(option[0]).total):
						discovery(&"grow"))
	if dream_state != null:
		# (The Dream Lesson opens over the first offer now: a choice Lesson, _check_choice_lessons. It used to queue here
		# and only showed after the pick, which taught nothing.)
		dream_state.dreamlight_earned.connect(func(amount: int, _source: StringName) -> void:
			if amount > 0:
				lesson(&"dreamlight", &"dreamlight", "Dreamlight",
					"Dreamlight unlocks new forms on the Remember screen. Spend it at a rest."))
	var spawner := main.get_node_or_null("%EnemyContainer")
	if spawner != null and spawner.has_signal("nightmare_restless"):
		spawner.nightmare_restless.connect(func(_enemy: Node2D, _stacks: int) -> void:
			lesson(&"restless", &"nightmare", "Turned around",
				"Changing the route under them makes them restless and faster. Do it too often and they stop listening."))
	if spawner != null and spawner.has_signal("enemy_reached_goal"):  # The first leaf lost to a flyer
		spawner.enemy_reached_goal.connect(func(enemy: Node2D) -> void:
			if is_instance_valid(enemy) and enemy.has_method("is_flying") and enemy.is_flying():
				discovery(&"flyer"))

# What the removed whispers used to notice by looking. Four times a second:
# - a status on a nightmare for the first time: its status Lesson;
# - a drift that has run longer than SPEED_LESSON_AFTER seconds (game time, not while paused): "Speed and pause".
const SPEED_LESSON_AFTER := 20.0
var _watch_left := 0.0
var _drift_time := 0.0
var _drift_watched := -1  # drifts_started the timer counts for

func _watch_field(delta: float) -> void:
	if not enabled or drift_director == null:
		return
	if drift_director.is_resting():
		_drift_time = 0.0
	elif not get_tree().paused:
		if drift_director.drifts_started != _drift_watched:
			_drift_watched = drift_director.drifts_started
			_drift_time = 0.0
		_drift_time += delta
		if _drift_time > SPEED_LESSON_AFTER and not seen.has("speed_pause"):
			lesson(&"speed_pause", &"rank", "Speed and pause", InputMode.text(
				"%s pauses, %s changes speed. You can build while paused." % [InputMode.key(&"pause_game", "Space"), InputMode.key(&"cycle_speed", "Tab")],
				"The pause and speed buttons are beside Start. You can build while paused."))
	_watch_left -= delta / maxf(Engine.time_scale, 0.001)
	if _watch_left > 0.0:
		return
	_watch_left = 0.25
	for id in EnemyStatuses.ALL:
		if seen.has("discover_" + String(id)):
			continue
		for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
			if enemy.statuses.has(id):
				discovery(id)
				break

func set_enabled(on: bool) -> void:
	enabled = on
	if not on:
		queue.clear()
		close()

func start_intro() -> void:
	if not enabled or drift_director == null or drift_director.drifts_started != 0:
		return
	lesson(&"intro_heartwood", &"leaves", "Protect the Heartwood", "Nightmares enter at the forest edge and follow the road to the Heartwood. Dispel them before they arrive: each one that gets through costs leaves.")
	lesson(&"intro_maze", &"path_length", "Build your maze", "Wardens are walls. Plant Sprouts to attack and Thornwalls to make the road longer. Keep a route to the Heartwood open, then start the drift when you are ready.")
	lesson(&"intro_dew", &"dew", "Earn Dew", "Dispelling nightmares earns Dew to build, grow and nurture Wardens. A longer road also earns maze Dew at rests: +1 per %d cells your route is longer than the forest's own path. The number after your Dew total forecasts the next rest." % DriftDirector.MAZE_ECONOMY.CELLS_PER_DEW)

func skip_intro() -> void:
	if not INTRO_IDS.has(shown_id):
		return
	for id in INTRO_IDS:
		if not seen.has(String(id)):
			seen.append(String(id))
	queue = queue.filter(func(entry: Array) -> bool: return not INTRO_IDS.has(entry[0]))
	_remember()
	close()

func discovery(id: StringName) -> void:
	match id:
		&"grow":
			lesson(&"discover_grow", &"rank", "Grow your Wardens", "Select a Warden and choose an unlocked form in its panel. Growing changes its abilities and costs Dew. Some forms must first be unlocked through Remember or the Memory Grove.")
		&"nurture":
			lesson(&"discover_nurture", &"rank", "Nurture your Wardens", "Select a Warden, then choose Nurture and the improvement you want. Each rank costs Dew and strengthens its current form. " + InputMode.text("Hover", "Tap") + " a choice to read its exact effect. At rank V, four matching picks earn a signature or mastery; mixed picks earn All-Rounder, +20% to its main job.")
		&"dream":
			lesson(&"discover_dream", &"dreamlight", "Choose a Dream", "Dreams change your run. Offers are random: pick a card that supports your Wardens, or experiment with a new build. Some cards pay off after you add more towers or combine statuses.")
		&"damp", &"drowsy", &"spored", &"marked", &"static", &"held":
			lesson(StringName("discover_" + String(id)), id, IconInfo.status_name(id), IconInfo.status_tooltip(id))
		&"flyer":
			lesson(&"discover_flyer", &"nightmare", "Flying nightmares", "Flying nightmares ignore your maze. Keep attackers covering the approach to the Heartwood, and watch the coming-nightmare warnings.")

# --- Triggers ---------------------------------------------------------------------------------------------------

func _on_built(tower: Tower) -> void:
	if not is_instance_valid(tower) or tower.tower_data == null:
		return
	if tower_placer.build_mode:
		_plants_in_mode += 1
		if _plants_in_mode >= 2:
			lesson(&"build_mode", &"rank", "Build mode",
				InputMode.text("Build mode stays on. Right-click or Esc to stop building.",
					"Build mode stays on. Tap Done to stop building."))
	var data := tower.tower_data
	if data.catch_share > 0.0:
		lesson(&"guide_catch", &"dew", "Catcher income", "The strongest catcher in reach collects extra Dew in its bowl when a nightmare is dispelled. At a rest, bowls pour into the bank first; Wellsprings then pay capped interest.")
	if tower.get_meta(&"gift_sprout", false):
		return
	if data.get_id() == "sprout":  # The first time the Sprout price steps up (onboarding.md a599a72d)
		var per_step := tower_placer.sprout_per_step()
		var paid := tower_placer.count_paid_sprouts()
		if per_step > 0 and paid >= per_step:  # The first crossing (a drag can plant past an exact multiple)
			lesson(&"sprouts_cost_more", &"dew", "Sprouts cost more",
				"Every %d Sprouts you plant, the next one costs %s more. Growing them doesn't lower it; selling one does." % [per_step, dew_text(tower_placer.sprout_step_dew())])
		return
	if not is_family_warden(data):
		return
	var name := data.display_name
	lesson(&"planted_directly", &"rank", "Sprout or %s?" % name,
		"Planting a %s directly costs the same as growing a Sprout into one. A Sprout lets you choose later." % name)
	if tower_placer.count_copies(data) >= 2:
		lesson(&"copies", &"dew", "Copies cost more",
			"Each %s you plant costs a little more than the last. Every kind of Warden counts on its own, so mixing them keeps prices low. Walls never get pricier." % name)

func _on_sold(_tower: Tower, _refund: int) -> void:
	if drift_director == null or drift_director.is_build_phase():
		return
	lesson(&"sell_mid_drift", &"dew", "Selling mid-drift",
		"Selling during a drift returns %d%%; at a rest, %d%%." % [roundi(tower_seller.drift_refund * 100.0),
			roundi(tower_seller.build_phase_refund * 100.0)])

# A Warden of a family, planted at a price that copies raise (no Sprout, no wall).
static func is_family_warden(data: TowerData) -> bool:
	return data != null and data.buildable_directly and data.line != "wall" and data.get_id() != "sprout"

# The Dew glyph and the number (UI Code's font, 99d0b3f1).
static func dew_text(amount: int) -> String:
	return UiStyle.dew_amount(amount)

# --- Showing ------------------------------------------------------------------------------------------------------

func lesson(id: StringName, icon: StringName, title: String, text: String) -> void:
	if not enabled or seen.has(String(id)) or id == shown_id or queue.any(func(q: Array) -> bool: return q[0] == id):
		return
	queue.append([id, icon, title, text])

func can_show() -> bool:
	if not enabled or drift_director == null or not is_inside_tree():
		return false
	if one_per_drift and drift_director.drifts_started == _last_drift and not drift_director.is_resting():  # Rests: one after another
		return false
	var run_state := main.get_node_or_null("%RunState")
	if run_state != null and run_state.is_over:
		return false
	return drift_director.pending_choice() == &"" and not RestScreens.any_open(self, drift_director)

func _process(_delta: float) -> void:
	if _resume_pending and not visible and not RestScreens.any_open(self, drift_director):
		_resume_pending = false
		if game_speed != null:
			game_speed.set_paused(false)
	if visible and _over_choice != null and (not is_instance_valid(_over_choice) or not _over_choice.visible):
		close()  # Its choice screen went away
	_watch_field(_delta)
	_check_choice_lessons()
	if not visible and not queue.is_empty() and can_show():
		_show(queue.pop_front())

# --- Choice Lessons (onboarding.md "Choice Lessons: shown on top of the choice they explain", user 2026-10-12) ------
# The one exception to "never over a choice screen": a Lesson that explains a choice opens OVER that screen the first
# time it appears with an offer, before the player can pick. The cards stay visible behind the shade and take no input
# until "Got it" (this card is raised above the screen and stops the mouse; keys stop here too). It closes back onto
# the screen and never unpauses: the choice screen holds the pause. Once per profile, off with Hints.
const CHOICE_SCREENS := {&"choice_family": "FamilyPickScreen", &"discover_dream": "DreamScreen", &"choice_omen": "OmenScreen"}
var _over_choice: Control = null  # The choice screen the shown Lesson explains
var _index_before := -1  # This card's place among the HUD's children, restored when it closes

# True while a choice Lesson covers `screen` (the screens refuse picks meanwhile).
static func covering(screen: Node) -> bool:
	if screen == null or not screen.is_inside_tree():
		return false
	var card := screen.get_tree().get_first_node_in_group(GROUP) as LessonCard
	return card != null and card.visible and card._over_choice == screen

func _check_choice_lessons() -> void:
	if not enabled or visible or main == null or get_parent() == null:
		return
	for id in CHOICE_SCREENS:
		if seen.has(String(id)):
			continue
		var screen := get_parent().get_node_or_null(CHOICE_SCREENS[id]) as Control
		if screen == null or not screen.visible or not _choice_offered(id, screen):
			continue
		_over_choice = screen
		_index_before = get_index()
		get_parent().move_child(self, get_parent().get_child_count() - 1)  # Above its screen, for drawing and for input
		_show(_choice_entry(id))
		return

# The screen is really offering its choice (not just made visible): the first family pick, a Dream offer, an Omen offer.
func _choice_offered(id: StringName, screen: Control) -> bool:
	match id:
		&"choice_family":
			var offer = screen.get("offer")
			return screen.get("_reason") == &"first" and offer is Array and not offer.is_empty()
		&"discover_dream":
			return dream_state != null and dream_state.is_offering()
		&"choice_omen":
			var omens := main.get_node_or_null("%OmenDirector")
			return omens != null and not omens.current_offer.is_empty()
	return false

func _choice_entry(id: StringName) -> Array:
	match id:
		&"choice_family":
			return [id, &"rank", "Wake a family", "Choose one of these Warden families. Your Sprouts can grow into it, and you can plant it directly.\n\n"
				+ "Your first family is also your Calling: its special rule lasts the whole run. It's shown on each card.\n\n"
				+ "Each card lists the forms that family can grow into this run.\n\n"
				+ InputMode.text("\"Peek at the map\" shows the board first.", "Tap \"Peek at the map\" to look at the board first.")]
		&"discover_dream":
			var pass_dew: int = dream_state.skip_dew if dream_state != null else 0
			return [id, &"dreamlight", "A Dream", "Pick one card, or let it pass for %s. Dreams last the whole run.\n\nA card that needs a Warden you don't have says so." % (
				dew_text(pass_dew) if pass_dew > 0 else "nothing")]
	return [id, &"nightmare", "An Omen", "An Omen makes the next block harder and pays you at the rest after it. Clear Skies skips it."]

# Keys stop at a choice Lesson (Enter / Esc close it, below): none reaches the choice screen under it.
func _input(event: InputEvent) -> void:
	if visible and _over_choice != null and event is InputEventKey and not event.is_action("ui_cancel") and not event.is_action("ui_accept"):
		get_viewport().set_input_as_handled()

func _show(entry: Array) -> void:
	if _resume_pending:
		_paused_it = true
		_resume_pending = false
	shown_id = entry[0]
	_icon.texture = IconInfo.icon(entry[1])
	_icon.visible = _icon.texture != null
	_title.text = entry[2]
	_skip.visible = not _replaying and INTRO_IDS.has(shown_id)
	_ok.text = "Next" if (_replaying and not queue.is_empty()) or (_skip.visible and shown_id != INTRO_IDS[-1]) else "Got it"
	_body.text = StatusLinks.bbcode(entry[3])  # Status names and glossary terms ({reactions} …) as links
	_demo.topic = &"nurture" if shown_id == &"discover_nurture" else (&"maze" if shown_id == &"intro_maze" else (&"catch" if shown_id == &"guide_catch" else &""))
	_demo.clock = 0.0
	_demo.visible = _demo.topic != &""
	visible = true
	_last_drift = drift_director.drifts_started
	if not _replaying:
		seen.append(String(shown_id))
		_remember()
	if game_speed != null and not game_speed.paused:
		_paused_it = _over_choice == null  # A choice Lesson never owns the pause: its screen does, and keeps it
		game_speed.set_paused(true)
	lesson_shown.emit(shown_id)

func close() -> void:
	if not visible:
		return
	if (_replaying or INTRO_IDS.has(shown_id)) and not queue.is_empty() and (_replaying or INTRO_IDS.has(queue[0][0])):
		_show(queue.pop_front())
		return
	visible = false
	_replaying = false
	shown_id = &""
	if _over_choice != null:  # A choice Lesson: back to its own place under the screens (their pause stays theirs)
		_over_choice = null
		if get_parent() != null and _index_before >= 0:
			get_parent().move_child(self, mini(_index_before, get_parent().get_child_count() - 1))
		_index_before = -1
	if _paused_it and game_speed != null:
		if RestScreens.any_open(self, drift_director):
			_resume_pending = true
		else:
			game_speed.set_paused(false)
	_paused_it = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept")):
		close()
		get_viewport().set_input_as_handled()

# The profile remembers them, never in tests (the scene isn't the running game there) or dev runs.
func _remember() -> void:
	if main == null or get_tree().current_scene != main or MetaRun.is_dev_run():
		return
	var memory := HeartwoodMemory.load_data()
	memory[SEEN_KEY] = seen
	HeartwoodMemory.save_data(memory)

# Explicit replay bypasses first-time/profile limits; it still owns and releases its pause.
func replay_guides() -> void:
	if main == null or game_speed == null:
		return
	_replaying = true
	queue.clear()
	queue.append([&"discover_nurture", &"rank", "Rank-V bonuses", "Four matching picks among your first five earn a signature or mastery. Other rank-V builds earn All-Rounder: +20% to their main job. Shared Training needs four matching picks on both bonded rank-IV kin."])
	queue.append([&"intro_maze", &"path_length", "Maze Dew", "Every %d cells your walls add to the road earn +1 maze Dew, counted while nightmares walk. The forecast beside your Dew shows the next rest's reward." % DriftDirector.MAZE_ECONOMY.CELLS_PER_DEW])
	queue.append([&"guide_catch", &"dew", "Catcher income", "The strongest catcher in reach collects extra Dew in its bowl when a nightmare is dispelled. At a rest, bowls pour into the bank first; Wellsprings then pay capped interest."])
	_show(queue.pop_front())