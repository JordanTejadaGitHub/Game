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
const INTRO_IDS := [&"intro_heartwood", &"intro_maze"]  # The opening cards, before drift 1 (wording review 2026-10-13: no Dew card before a nightmare has paid any)
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
var _centre: CenterContainer
var _panel: PanelContainer
var _spot_layer := Control.new()  # The spotlight's ring, badge pulse and thread

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
	_spot_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_spot_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spot_layer.draw.connect(_draw_spot)
	add_child(_spot_layer)  # Over the shade, under the card
	_centre = CenterContainer.new()
	var centre := _centre
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	_panel = PanelContainer.new()
	var panel := _panel
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
	_skip.text = "Skip lessons"
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
			# Rests, then Dew and the Maze bonus, one after the other at the first rest (wording review 2026-10-13, teaching order).
			lesson(&"rests", &"dew", "Rests", "The forest is resting. Nothing moves until you press Start, and selling a Warden gives %s. After this, a rest comes every %d drifts." % [
				"all its Dew back" if tower_seller == null or tower_seller.build_phase_refund >= 1.0 else "%d%% of its Dew back" % roundi(tower_seller.build_phase_refund * 100.0),
				drift_director.drifts_per_block])
			lesson(&"dew_maze", &"dew", "Dew and the Maze bonus", "Dispelling nightmares earns Dew. Spend it to plant more Wardens. A longer path also pays a Maze bonus at each rest: the small number beside your Dew shows how much."))
		drift_director.drift_started.connect(func(_number: int) -> void:  # Speed and pause: as the first drift starts
			var keys := "%s pauses, %s changes speed. You can plant while paused." % [InputMode.key(&"pause_game", "Space"), InputMode.key(&"cycle_speed", "Tab")]
			lesson(&"speed_pause", &"rank", "Speed and pause", InputMode.text(keys, "The pause and speed buttons are beside Start. You can plant while paused.")))
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
					"Dreamlight unlocks new forms for your Wardens. Press Remember, at the top right, to spend it."))
	var spawner := main.get_node_or_null("%EnemyContainer")
	if spawner != null and spawner.has_signal("nightmare_restless"):
		spawner.nightmare_restless.connect(func(_enemy: Node2D, _stacks: int) -> void:
			lesson(&"restless", &"nightmare", "Turned around",
				"Re-routing nightmares mid-walk makes them restless: they speed up. Keep doing it and they ignore the new path."))
	if spawner != null and spawner.has_signal("enemy_reached_goal"):  # The first leaf lost to a flyer
		spawner.enemy_reached_goal.connect(func(enemy: Node2D) -> void:
			if is_instance_valid(enemy) and enemy.has_method("is_flying") and enemy.is_flying():
				discovery(&"flyer"))

# What the removed whispers used to notice by looking. Four times a second:
# - a status on a nightmare for the first time: its status Lesson;
# - a Warden at rank IV: the rank V rules.
var _watch_left := 0.0

func _watch_field(delta: float) -> void:
	if not enabled or drift_director == null:
		return
	_watch_left -= delta / maxf(Engine.time_scale, 0.001)
	if _watch_left > 0.0:
		return
	_watch_left = 0.25
	# A status Lesson opens the moment its status is on a nightmare the player can see (onboarding.md "Status Lessons
	# point at the nightmare"): never queued (the nightmare would be gone by the time it showed), so one that lands off
	# screen, or while another card is up, waits for the next visible one.
	if visible or not can_show():
		return
	if not seen.has("rank_rules") and tower_placer != null and tower_placer.tower_container != null:  # The rank V rules, once a Warden is one rank away
		for tower in tower_placer.tower_container.get_children():
			if tower is Tower and tower.rank >= RANK_RULES_AT:
				lesson(&"rank_rules", &"rank", "Rank V", RANK_TEXT)
				break
	for id in EnemyStatuses.ALL:
		if seen.has("discover_" + String(id)):
			continue
		for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
			if enemy.statuses.has(id) and on_screen(enemy):
				var entry := [StringName("discover_" + String(id)), id, IconInfo.status_name(id), status_text(id, enemy), enemy]
				if seen.has("statuses_stack"):
					_show(entry)
				else:  # Once, before the first status Lesson: what a status and a stack are; its own Lesson follows on Got it
					_after = entry
					_show([&"statuses_stack", id, "Statuses stack", STACK_TEXT, enemy])
				return

# --- Status Lessons point at the nightmare (onboarding.md, user 2026-10-12) ----------------------------------------
# One plain sentence per status: live numbers, the Reactions link, no internals (the exact figures stay in the status
# tooltip and the Codex).
const STACK_TEXT := "Some Wardens leave a status on nightmares. Each hit adds a stack; the icon above a nightmare shows how many. Two full statuses on one nightmare set off a {reaction}. Blue corner brackets round a status: enough stacks for a Reaction."
const RANK_RULES_AT := 4  # Rank IV: the next rank is the one the rules are about
var _after: Array = []  # The status Lesson that follows "Statuses stack"
const STATUS_LINES := {
	&"damp": "Water hits deal 20% more damage to it. At {stacks:need_damp} stacks it can set off {reactions}.",
	&"drowsy": "It walks 2% slower per stack. At {stacks:cap_drowsy} stacks ({stacks:bosscap_drowsy} on bosses) it can fall {asleep} and set off {reactions}.",
	&"spored": "It takes damage every second, more per stack. Each stack lasts 5 s, so keep hitting it. At {stacks:need_spored} stacks it can set off {reactions}.",
	&"marked": "Nothing until {stacks:need_marked} stacks; then it takes 25% more damage from every Warden and can set off {reactions}.",
	&"static": "At {stacks:cap_static} stacks ({stacks:bosscap_static} on bosses) it is struck by a bolt for heavy damage. Other statuses can set it off early as a {reaction}.",
	&"held": "It cannot move for a moment. At {stacks:need_held} stacks it can set off {reactions}.",
}
const SPOT_MARGIN := [48.0, 96.0, 48.0, 150.0]  # Left, top, right, bottom: inside the HUD's banner and bars
const SPOT_GAP := 56.0  # Between the nightmare and the card
const SPOT_EDGE := 16.0  # The card stays this far inside the screen
var _spot_enemy: Node2D = null  # The nightmare the shown status Lesson points at
var _spot_status: StringName = &""
var _spot_clock := 0.0

# The card's text: who did it (the live Warden name, the status as a link), then the status's line.
static func status_text(id: StringName, enemy: Node2D = null) -> String:
	var source = enemy.statuses.source(id) if enemy != null and is_instance_valid(enemy) else null
	var warden := "A Warden is"
	if source is Tower and source.tower_data != null:
		warden = "Your %s is" % source.tower_data.display_name
	return "%s adding {%s} to %s. Each hit adds one stack.\n\n%s" % [warden, id, "this nightmare" if enemy != null else "a nightmare", STATUS_LINES.get(id, "")]

# Where the nightmare is on screen (this card's own space: the HUD's canvas).
func _spot_at(enemy: Node2D, local := Vector2.ZERO) -> Vector2:
	return enemy.get_global_transform_with_canvas() * local

# The player can see it: inside the view, clear of the HUD's bars, and not under an open panel or screen.
func on_screen(enemy: Node2D) -> bool:
	if not is_instance_valid(enemy) or not enemy.is_inside_tree() or not enemy.is_visible_in_tree():
		return false
	var view := Rect2(Vector2.ZERO, size).grow_individual(-SPOT_MARGIN[0], -SPOT_MARGIN[1], -SPOT_MARGIN[2], -SPOT_MARGIN[3])
	return view.has_point(_spot_at(enemy)) and not WorldLabel.covered(enemy, Rect2(-16.0, -28.0, 32.0, 44.0))

# The status's badge above the nightmare (Enemy draws them in a row), or just above its head.
func _badge_at(enemy: Node2D) -> Vector2:
	var ids = enemy.get("_hud_ids")
	if ids is Array and ids.has(_spot_status) and enemy.has_method("_badge_centre"):
		return _spot_at(enemy, enemy._badge_centre(ids.find(_spot_status)))
	return _spot_at(enemy, Vector2(0.0, -30.0))

# Beside the nightmare, on the side with more room, never over it, and inside the screen: the CenterContainer's rect
# becomes that strip (the card centres itself in it). Each frame while it shows: the card's height settles a frame late.
func _place_beside(at: Vector2 = Vector2.INF, gap: float = SPOT_GAP) -> void:
	if at == Vector2.INF:
		at = _spot_at(_spot_enemy)
	var card := _panel.size
	var right := at.x < size.x / 2.0
	var from := at.x + gap if right else SPOT_EDGE
	var to := size.x - SPOT_EDGE if right else at.x - gap
	if to - from < card.x:  # A screen too narrow for a side strip: keep it whole, against the far edge
		from = size.x - SPOT_EDGE - card.x if right else SPOT_EDGE
		to = from + card.x
	var middle := clampf(at.y, SPOT_EDGE + card.y / 2.0, maxf(size.y - SPOT_EDGE - card.y / 2.0, SPOT_EDGE + card.y / 2.0))
	_centre.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_centre.position = Vector2(from, middle - card.y / 2.0)
	_centre.size = Vector2(to - from, card.y)

# --- Lessons point at the control they name (user 2026-10-13: "the tutorial card for Remember should have a line
# pointing to the top right") -----------------------------------------------------------------------------------
# While the card is open a thin thread runs from it to each control (or Warden) the Lesson names, and the control
# glows; the card sits beside the first one, so the thread is short and starts at the card's edge, never across
# its text. Reduced motion: no pulse, the thread and a steady glow stay. Gone on Got it.
var _point_nodes: Array = []  # Controls (HUD) or Node2Ds (a Warden) the shown Lesson points at

# What `id`'s Lesson points at now: only what is on screen (a hidden Warden bar: its arrow instead).
func point_targets(id: StringName, entry: Array = []) -> Array:
	var hud := get_parent()
	if hud == null:
		return []
	var found: Array = []
	var drift_panel := hud.find_child("DriftPanel", true, false)
	match id:
		&"dreamlight":
			found = [hud.get("remember_button")]
		&"intro_maze":
			var slots = hud.get("_tower_buttons")
			var slot = slots[0] if slots is Array and not slots.is_empty() else null  # The Sprout: the bar's first slot
			if not (slot is Control and slot.is_visible_in_tree()):
				slot = hud.get("_bar_toggle")  # The bar is tucked away: its arrow brings it back
			found = [slot, drift_panel.get("_start_button") if drift_panel != null else null]
		&"speed_pause":
			if drift_panel != null:
				found = [drift_panel.get("_pause_button")]
				var speeds = drift_panel.get("_speed_buttons")
				if speeds is Array and not speeds.is_empty():
					found.append(speeds[-1])
		&"dew_maze":
			found = [hud.get_node_or_null("MazeDewLabel")]
		&"discover_nurture":
			found = [hud.find_child("NurtureHeading", true, false)]
		&"guide_catch":
			found = [entry[4] if entry.size() > 4 else null]  # The catcher just planted
	return found.filter(func(node) -> bool:
		return node != null and is_instance_valid(node) and (node is Control or node is Node2D) and node.is_visible_in_tree())

# Where a pointed-at node is on screen.
func _point_rect(node) -> Rect2:
	if node is Control:
		return (node as Control).get_global_rect()
	var half := maxf(32.0 * (node as Node2D).get_global_transform_with_canvas().get_scale().x, 24.0)
	return Rect2(_spot_at(node) - Vector2(half, half), Vector2(half, half) * 2.0)

# The card beside the first control: left, right, above or below it, whichever is nearest while staying on screen and
# off every control it points at. None fits: the card stays centred.
const POINT_GAP := 28.0

func _place_near() -> void:
	var rects: Array[Rect2] = []
	for node in _point_nodes:
		var rect := _point_rect(node)
		rect.position -= global_position
		rects.append(rect)
	var card := _panel.size
	var target := rects[0]
	var middle := target.get_center()
	var best := Vector2.INF
	var best_score := INF
	for spot in [Vector2(target.position.x - POINT_GAP - card.x, middle.y - card.y / 2.0), Vector2(target.end.x + POINT_GAP, middle.y - card.y / 2.0),
			Vector2(middle.x - card.x / 2.0, target.position.y - POINT_GAP - card.y), Vector2(middle.x - card.x / 2.0, target.end.y + POINT_GAP)]:
		var at := Vector2(clampf(spot.x, SPOT_EDGE, maxf(size.x - card.x - SPOT_EDGE, SPOT_EDGE)), clampf(spot.y, SPOT_EDGE, maxf(size.y - card.y - SPOT_EDGE, SPOT_EDGE)))
		var placed := Rect2(at, card)
		if rects.any(func(r: Rect2) -> bool: return r.grow(8.0).intersects(placed)):
			continue  # It would cover a control it points at
		var score := placed.get_center().distance_to(middle)
		if score < best_score:
			best_score = score
			best = at
	if best == Vector2.INF:
		_centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		return
	_centre.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_centre.position = best
	_centre.size = card

func _draw_points() -> void:
	var still := bool(Fx.setting("reduced_motion", false))
	var beat := 0.5 if still else 0.5 + 0.5 * sin(_spot_clock * 4.0)
	var card := _panel.get_global_rect()
	for node in _point_nodes:
		if not is_instance_valid(node) or not node.is_visible_in_tree():
			continue
		var rect := _point_rect(node).grow(4.0)
		rect.position -= global_position
		_spot_layer.draw_rect(rect, Color(UiStyle.GOLD, 0.10 + 0.08 * beat))  # The glow, over the shade
		_spot_layer.draw_rect(rect.grow(1.0 + 2.0 * beat), Color(UiStyle.GOLD, 0.9 - 0.4 * beat), false, 2.0)
		var centre := rect.get_center() + global_position
		var from := Vector2(clampf(centre.x, card.position.x, card.end.x), clampf(centre.y, card.position.y, card.end.y))  # On the card's edge, nearest the control
		var to := Vector2(clampf(from.x, rect.position.x + global_position.x, rect.end.x + global_position.x), clampf(from.y, rect.position.y + global_position.y, rect.end.y + global_position.y))
		if from.distance_to(to) > 4.0:
			_spot_layer.draw_line(from - global_position, to - global_position, Color(UiStyle.GOLD, 0.7), 1.0, true)

func _end_spot() -> void:
	if _spot_enemy == null and _spot_status == &"" and _point_nodes.is_empty():
		return
	_point_nodes = []
	_spot_enemy = null
	_spot_status = &""
	_centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_spot_layer.queue_redraw()

# A soft ring round the nightmare, a pulse on its new badge, a thin thread from the card to the badge. Reduced motion:
# nothing pulses, the ring stays.
func _draw_spot() -> void:
	if not visible:
		return
	_draw_points()
	if not is_instance_valid(_spot_enemy):
		return
	var still := bool(Fx.setting("reduced_motion", false))
	var at := _spot_at(_spot_enemy)
	var zoom := _spot_enemy.get_global_transform_with_canvas().get_scale().x
	var radius := maxf(34.0 * zoom, 26.0)
	for i in 4:  # Soft: a few rings fading outwards
		_spot_layer.draw_arc(at, radius + i * 3.0, 0.0, TAU, 48, Color(UiStyle.GOLD, 0.55 - 0.13 * i), 2.0, true)
	var badge := _badge_at(_spot_enemy)
	var beat := 0.5 if still else 0.5 + 0.5 * sin(_spot_clock * 5.0)
	_spot_layer.draw_arc(badge, maxf(9.0 * zoom, 8.0) + 4.0 * beat, 0.0, TAU, 24, Color(Palette.HEARTLIGHT, 0.95 - 0.5 * beat), 2.0, true)
	var card := _panel.get_global_rect()
	var from := Vector2(card.position.x if card.position.x > at.x else card.end.x, clampf(badge.y, card.position.y + 12.0, card.end.y - 12.0))
	_spot_layer.draw_line(from - global_position, badge, Color(UiStyle.GOLD, 0.7), 1.0, true)

func set_enabled(on: bool) -> void:
	enabled = on
	if not on:
		queue.clear()
		_after = []
		close()

func start_intro() -> void:
	if not enabled or drift_director == null or drift_director.drifts_started != 0:
		return
	lesson(&"intro_heartwood", &"leaves", "Protect the Heartwood", "Nightmares enter at the forest edge and follow the path to the Heartwood. Dispel them before they arrive: each one that reaches the Heartwood costs leaves.")
	var on_pc := "Wardens are walls. Pick a Sprout from the bar below and click the ground to plant it; Thornwalls make the path longer. Press Start (%s) to let in the first wave, called a drift." % InputMode.key(&"start_drift", "Enter")
	lesson(&"intro_maze", &"path_length", "Plant and start", InputMode.text(on_pc, "Wardens are walls. Pick a Sprout from the bar below and tap the ground to plant it; Thornwalls make the path longer. Tap Start to let in the first wave, called a drift."))

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
			lesson(&"discover_grow", &"rank", "Grow your Wardens", "Select a Warden and choose a form in its panel. Growing costs Dew and changes what it does.")
		&"nurture":
			lesson(&"discover_nurture", &"rank", "Nurture your Wardens", InputMode.text(
				"Select a Warden and press Nurture (%s) to make it stronger for Dew. Each rank lets you choose one improvement. Hover a choice to read it." % InputMode.key(&"nurture_warden", "N"),
				"Select a Warden and tap Nurture to make it stronger for Dew. Each rank lets you choose one improvement. Tap a choice to read it."))
		&"dream":
			lesson(&"discover_dream", &"dreamlight", "A Dream", "Pick one card. You don't have to take one. Dreams last the whole run.")
		&"damp", &"drowsy", &"spored", &"marked", &"static", &"held":
			lesson(StringName("discover_" + String(id)), id, IconInfo.status_name(id), status_text(id))  # Asked for by name (tests, replays): no nightmare to point at
		&"flyer":
			lesson(&"discover_flyer", &"nightmare", "Flyers", "Flyers ignore your maze and go straight for the Heartwood. Keep attacking Wardens near it, and check which nightmares are coming before each block.")

# --- Triggers ---------------------------------------------------------------------------------------------------

func _on_built(tower: Tower) -> void:
	if not is_instance_valid(tower) or tower.tower_data == null:
		return
	if tower_placer.build_mode:
		_plants_in_mode += 1
		if _plants_in_mode >= 2:
			lesson(&"build_mode", &"rank", "Build mode",
				InputMode.text("Build mode stays on. Right-click or Esc to stop planting.",
					"Build mode stays on. Tap Done to stop planting."))
	var data := tower.tower_data
	if data.catch_share > 0.0:
		if enabled and not seen.has("guide_catch") and shown_id != &"guide_catch" and not queue.any(func(q: Array) -> bool: return q[0] == &"guide_catch"):
			queue.append([&"guide_catch", &"dew", "Catchers", CATCH_TEXT, tower])  # With the Warden, for the pointer
	if tower.get_meta(&"gift_sprout", false):
		return
	if data.get_id() == "sprout":  # The first time the Sprout price steps up (onboarding.md a599a72d)
		var per_step := tower_placer.sprout_per_step()
		var paid := tower_placer.count_paid_sprouts()
		if per_step > 0 and paid >= per_step:  # The first crossing (a drag can plant past an exact multiple)
			lesson(&"sprouts_cost_more", &"dew", "Sprouts cost more",
				"Every %d Sprouts on the map, the next one costs %s more. Growing or selling one lowers it." % [per_step, dew_text(tower_placer.sprout_step_dew())])
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
	if visible and not _point_nodes.is_empty() and _spot_status == &"":  # Beside the control it names
		_point_nodes = _point_nodes.filter(func(node) -> bool: return is_instance_valid(node) and node.is_visible_in_tree())
		if _point_nodes.is_empty():
			_end_spot()
		else:
			_spot_clock += _delta / maxf(Engine.time_scale, 0.001)
			_place_near()
			_spot_layer.queue_redraw()
	if visible and _spot_status != &"":
		if is_instance_valid(_spot_enemy):
			_spot_clock += _delta / maxf(Engine.time_scale, 0.001)
			_place_beside()
			_spot_layer.queue_redraw()
		else:
			_end_spot()  # It went (a test freed it): the card stays, centred
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
			return [id, &"rank", "Wake a family", "Choose one Warden family. Your Sprouts can grow into it, or you can plant it directly.\n\n"
				+ "Your first family also brings a Calling, a rule that lasts all run, shown on its card."]
		&"discover_dream":
			var pass_dew: int = dream_state.skip_dew if dream_state != null else 0
			return [id, &"dreamlight", "A Dream", "Pick one card. You don't have to take one: Let it pass gives %s instead. Dreams last the whole run.\n\nA card that needs a Warden you don't have says so." % (
				dew_text(pass_dew) if pass_dew > 0 else "nothing")]
	return [id, &"nightmare", "Face an Omen", "An Omen makes the next %d drifts harder and pays a reward at the rest after them. You can skip it: nothing changes, no reward." % (drift_director.drifts_per_block if drift_director != null else 5)]

# Keys stop at a choice Lesson (Enter / Esc close it, below): none reaches the choice screen under it.
func _input(event: InputEvent) -> void:
	if visible and _over_choice != null and event is InputEventKey and not event.is_action("ui_cancel") and not event.is_action("ui_accept"):
		get_viewport().set_input_as_handled()

func _show(entry: Array) -> void:
	if _resume_pending:
		_paused_it = true
		_resume_pending = false
	shown_id = entry[0]
	_end_spot()
	_point_nodes = point_targets(shown_id, entry) if not _replaying and _over_choice == null else []
	if entry.size() > 4 and is_instance_valid(entry[4]) and EnemyStatuses.ALL.has(entry[1]):  # A status Lesson with its nightmare: the spotlight
		_spot_enemy = entry[4]
		_spot_status = entry[1]
		_spot_clock = 0.0
	_icon.texture = IconInfo.icon(entry[1])
	_icon.visible = _icon.texture != null
	_title.text = entry[2]
	_skip.visible = not _replaying and INTRO_IDS.has(shown_id)
	_ok.text = "Next" if (_replaying and not queue.is_empty()) or (_skip.visible and shown_id != INTRO_IDS[-1]) else "Got it"
	_body.text = StatusLinks.bbcode(entry[3])  # Status names and glossary terms ({reactions} …) as links
	_demo.topic = &"nurture" if shown_id == &"rank_rules" else (&"maze" if shown_id == &"dew_maze" else (&"catch" if shown_id == &"guide_catch" and _replaying else &""))
	_demo.clock = 0.0
	_demo.visible = _demo.topic != &""
	visible = true
	_last_drift = drift_director.drifts_started
	if not _replaying:
		seen.append(String(shown_id))
		_remember()
	if game_speed != null and not game_speed.paused:
		# Not paused when it opened, so this card owns the pause, a choice Lesson too (its screen normally holds the pause
		# already and this line isn't reached; if it didn't, close() resumes once every rest screen has closed).
		_paused_it = true
		game_speed.set_paused(true)
	lesson_shown.emit(shown_id)

func close() -> void:
	if not visible:
		return
	if not _after.is_empty():  # "Statuses stack" hands over to the status's own Lesson, on the same nightmare
		var following := _after
		_after = []
		if following.size() > 4 and is_instance_valid(following[4]):
			_show(following)
			return
	if (_replaying or INTRO_IDS.has(shown_id)) and not queue.is_empty() and (_replaying or INTRO_IDS.has(queue[0][0])):
		_show(queue.pop_front())
		return
	visible = false
	_replaying = false
	shown_id = &""
	_end_spot()
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
const CATCH_TEXT := "This Warden catches extra Dew when a nightmare is dispelled in its range. It is paid to you at the next rest."
const RANK_TEXT := "At rank V a Warden earns a mark. Four ranks of the same choice give a signature, a special rule. Any other mix gives All-Rounder: 20% better at what it does."

func replay_guides() -> void:
	if main == null or game_speed == null:
		return
	_replaying = true
	queue.clear()
	queue.append([&"rank_rules", &"rank", "Rank V", RANK_TEXT])
	queue.append([&"dew_maze", &"path_length", "Maze bonus", "Every %d cells your walls add to the path earn +1 Maze bonus, counted while nightmares walk. The number beside your Dew shows what the rest ending this block will pay." % DriftDirector.MAZE_ECONOMY.CELLS_PER_DEW])
	queue.append([&"guide_catch", &"dew", "Catchers", CATCH_TEXT])
	_show(queue.pop_front())
