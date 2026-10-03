extends Control
class_name NightmareIntro

# New nightmare introduction (screens_ui.md "New nightmare introduction", 2026-09-28: "new enemies
# should have a display window in the middle like bosses"): the first time ever a nightmare kind is
# about to appear, the rest before its block opens a centred card, the boss dossier's style but
# smaller: animated portrait, name, its trait line, what it does (EnemyData.get_intro_lines()), its
# resist / weak / immune icons, and one hint (EnemyData.hint). Several new kinds: one card each, with
# "Next" (a kind's split / follower kinds right after it). After the Dream / Omen, before the boss
# dossier. Dismissed by the button, a tap outside or Esc; reopened from its portrait in the Coming
# strip (open_for), or by clicking / tapping the nightmare on the map (paused; bosses open the dossier;
# the card adds its live health, statuses and Restless). A kind that first appears mid-block without
# a card (a Mourner's Sobs) pauses on its card too (it was a 2-second name plate). Block 1's kinds are
# introduced at the run's opening rest. Once ever per kind, per account (profile "intros_seen", dev
# runs included; tests: this session only). Always on (user, 2026-09-29), not tied to the whispers.
# One centred card at a time: every nightmare portrait and click opens this card, replacing the one
# up; it stops the game while it's up. Made by the HUD.

const GROUP := &"nightmare_intro"
const SEEN_KEY := "intros_seen"
const WIDTH := 460.0
const OPEN_DELAY := 0.35
const NEW_COLOR := UiStyle.GOLD  # Glow

static var session_seen := {}  # Kind -> true: shown this session (dev runs, tests)
# Headless scripts (tests, balance sims) never pause on a mid-drift card (a drift would stall), unless
# a test turns it on, like ComboFeedback.pause_in_tests.
static var pause_in_tests := false

# Cards open by themselves (a rest's new kinds, the opening rest, a mid-block newcomer) only in the game, or in a test
# that turns pause_in_tests on: on a fresh test profile every kind is new, and the cards paused every timing test
# (Tower Code, 2026-10-01, with the suite's isolated user://).
static func auto_open_ok() -> bool:
	return pause_in_tests or not OS.get_cmdline_args().has("--script")

var drift_director: DriftDirector
var queue: Array = []  # EnemyData still to show, in order
var shown: EnemyData = null
var _drift := 0
var _pending: Array = []  # Kinds waiting for the rest's other screens
var _wait := 0.0
var _paused_it := false
var _panel := PanelContainer.new()
var _content := VBoxContainer.new()
var _next := Button.new()
var peek: ChoicePeek  # Minimise to look at the map; the Return pill mid-screen
var _met := {}  # Kinds met before or introduced this run (no name plate for them)

# Opens the card for `kinds` (in order), e.g. from a Coming strip portrait.
static func open_for(tree: SceneTree, kinds: Array, drift: int = 0) -> void:
	var intro := tree.get_first_node_in_group(GROUP) as NightmareIntro
	if intro != null:
		intro.open(kinds, drift)

func _init(director: DriftDirector = null) -> void:
	drift_director = director

func _ready() -> void:
	add_to_group(GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Offsets too: exactly the screen
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var shade := ColorRect.new()
	shade.color = Color(UiStyle.FOG, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Offsets too: exactly the screen
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Offsets too: exactly the screen
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	var solid := UiStyle.panel(18.0, 14.0)  # Solid: a paused card never shows another screen through it (user)
	solid.center_alpha = UiStyle.TIP_ALPHA
	solid.edge_alpha = UiStyle.TIP_ALPHA
	_panel.add_theme_stylebox_override("panel", solid)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	centre.add_child(_panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	_panel.add_child(outer)
	var top := HBoxContainer.new()  # ✕ in the corner (tap-sized)
	top.alignment = BoxContainer.ALIGNMENT_END
	var cross := Button.new()
	cross.text = "✕"
	cross.flat = true
	cross.focus_mode = Control.FOCUS_NONE
	cross.custom_minimum_size = Vector2(44, 44)
	cross.tooltip_text = "Close (Esc)"
	cross.pressed.connect(close)
	top.add_child(cross)
	outer.add_child(top)
	_content.custom_minimum_size = Vector2(WIDTH, 0)
	_content.add_theme_constant_override("separation", 8)
	outer.add_child(_content)
	_next.focus_mode = Control.FOCUS_NONE
	_next.custom_minimum_size = Vector2(180, 44)
	_next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UiStyle.primary(_next)
	_next.pressed.connect(advance)
	# Peek at the map (pausing cards, user: "just put the placement in the middle for paused things like that"): the
	# card goes, a solid "Return to …" pill waits mid-screen; the game stays paused.
	peek = ChoicePeek.new(self, [shade, centre], "Return")
	peek.place_back_centre()
	peek.changed.connect(func(on: bool) -> void:
		if on:
			peek.back_button().text = return_text())
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	buttons.add_child(peek.make_peek_button())
	buttons.add_child(_next)
	outer.add_child(buttons)
	for kind in HeartwoodMemory.load_data().get("nightmares_seen", []):
		_met[kind] = true
	if drift_director != null:
		drift_director.rest_started.connect(_on_rest_started)
		_on_opening_rest.call_deferred()  # The run starts resting: block 1's new kinds too
		var spawner := drift_director.get_node_or_null("%EnemyContainer")
		if spawner != null:
			spawner.child_entered_tree.connect(_on_spawned)

func _gui_input(event: InputEvent) -> void:
	# A tap outside the card dismisses it (the whole queue).
	if event is InputEventMouseButton and event.pressed and not _panel.get_global_rect().has_point(event.global_position):
		close()
		accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("cancel_build"):
		close()
		get_viewport().set_input_as_handled()
		return
	# Click / tap a nightmare on the map (screens_ui.md "New nightmare introduction"): its centred
	# card, paused (a boss: the dossier). A click, not a drag; build mode, a Warden selection and the
	# Clear tool keep their own click.
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or visible:
		return
	if event.pressed:
		_press_at = event.position
		_press_free = _map_click_free()
		return
	if not _press_free or event.position.distance_to(_press_at) > CLICK_SLOP:
		return
	var enemy := nightmare_at(event.position)
	if enemy == null:
		return
	if enemy.enemy_data.is_boss:
		BossDossier.open_for(get_tree())
	else:
		open([enemy.enemy_data], 0, enemy)
	get_viewport().set_input_as_handled()

const CLICK_RADIUS := 30.0  # World px around a nightmare that count as clicking it
const CLICK_SLOP := 8.0  # Screen px a click may move (more = a drag box)
var _press_at := Vector2.ZERO
var _press_free := false
var live: Node2D = null  # The clicked nightmare (its health, statuses and Restless on the card)
var _live_label: Label = null

# Nothing else owns a map click right now.
func _map_click_free() -> bool:
	var placer = drift_director.get_node_or_null("%TowerPlacer")
	var seller = drift_director.get_node_or_null("%TowerSeller")
	var clearer = drift_director.get_node_or_null("%ObstacleClearer")
	if placer != null and placer.build_mode:
		return false
	if seller != null and not seller.selection.is_empty():
		return false
	return not (clearer != null and clearer.has_method("is_tool_active") and clearer.is_tool_active())

# The nightmare under screen point `screen_at` (nearest within CLICK_RADIUS), or null. Hidden ones
# can't be picked.
func nightmare_at(screen_at: Vector2) -> Node2D:
	var world := get_viewport().get_canvas_transform().affine_inverse() * screen_at
	var best: Node2D = null
	var best_distance := CLICK_RADIUS
	for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		if enemy.get("enemy_data") == null or enemy.is_cleansed or (enemy.has_method("is_hidden") and enemy.is_hidden()):
			continue
		var distance: float = enemy.global_position.distance_to(world)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best

# --- Which kinds, when ---------------------------------------------------------------------------

static func enabled() -> bool:
	return true  # Always (user, 2026-09-29): a never-seen kind stops the game on its card, whispers or not

static func kind_of(data: EnemyData) -> String:
	return data.resource_path.get_file().get_basename()

# Never introduced before (this profile, or this session in dev runs and tests).
func is_unseen(data: EnemyData) -> bool:
	var kind := kind_of(data)
	if session_seen.has(kind):
		return false
	var profile := HeartwoodMemory.load_data()
	return not profile.get(SEEN_KEY, []).has(kind) and not profile.get("nightmares_seen", []).has(kind)

# The new kinds of block `block`, each followed by the kinds it splits into / brings.
func new_kinds_in_block(block: int) -> Array:
	var out: Array = []
	for pair in ComingStrip.kinds_in_block(drift_director, block):
		var data: EnemyData = pair[0]
		if data.is_boss:
			continue
		for kind in [data, data.split_into, data.followers]:
			if kind != null and not out.has(kind) and is_unseen(kind):
				out.append(kind)
	return out

func _on_rest_started(block: int, _boss: bool, _bonus: int, _perfect: bool) -> void:
	if not enabled() or not drift_director.has_next_drift() or not auto_open_ok():
		return
	var kinds := new_kinds_in_block(block + 1)
	if not kinds.is_empty():
		_pending = kinds
		_drift = block * drift_director.drifts_per_block + 1
		_wait = OPEN_DELAY

# The rest's earlier screens (family pick, Dream, Omen, pause, results) are done.
func screens_clear() -> bool:
	return RestScreens.clear_for(self, drift_director)  # After the gift and the boss dossier (user: one screen at a time)

# The boss dossier waits while a card is open or about to open.
func is_busy() -> bool:
	return visible or not _pending.is_empty()

func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.001)
	if visible:
		_update_live()
	if _pending.is_empty():
		return
	if not drift_director.is_resting():
		_pending = []
		return
	var dossier := get_tree().get_first_node_in_group(BossDossier.GROUP) as BossDossier
	if dossier != null and dossier.is_waiting():
		dossier.add_whats_coming(_pending)  # An act's start: listed under the boss on "What's coming", no page of its own
		_pending = []
		return
	_wait -= real
	if _wait <= 0.0 and screens_clear():
		var kinds := _pending
		_pending = []
		open_list(kinds, _drift)  # One page for the block's new kinds (user, 2026-10-03)

# --- Open / next / close -------------------------------------------------------------------------

# `enemy`: a nightmare clicked on the map; its card adds its live health, statuses and Restless.
# One card at a time: a click (`replace`) swaps the card showing for this one, while new kinds found
# mid-drift queue behind it (Next). Either way the pause state carries over. The card always stops
# the game while it's up (at a rest too, so Enter can't start a drift under it).
func open(kinds: Array, drift: int = 0, enemy: Node2D = null, replace := true) -> void:
	if kinds.is_empty():
		return
	if visible and not replace:
		for kind in kinds:
			if not queue.has(kind) and kind != shown:
				queue.append(kind)
		_next.text = "Next"
		return
	queue = kinds.duplicate()
	_drift = drift
	live = enemy
	_show_next()
	var speed := drift_director.get_node_or_null("%GameSpeed") as GameSpeed if drift_director else null
	if speed != null and not speed.paused:
		_paused_it = true
		speed.set_paused(true)

func advance() -> void:
	if queue.is_empty():
		close()
	else:
		_show_next()

# The minimised card's pill: "Return to the Phantom" for one, "Return (2)" with more waiting behind it.
func return_text() -> String:
	if not queue.is_empty():
		return "Return (%d)" % (queue.size() + 1)
	return "Return to %s" % (IconInfo.the_name(shown.display_name) if shown != null else "the card")

func _show_next() -> void:
	if peek != null:
		peek.set_peeking(false)
	shown = queue.pop_front()
	_remember(shown)
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	_build(shown)
	_next.text = "Next" if not queue.is_empty() else "Got it"
	visible = true

func close() -> void:
	visible = false
	queue.clear()
	shown = null
	live = null
	_live_label = null
	if _paused_it:
		_paused_it = false
		var speed := drift_director.get_node_or_null("%GameSpeed") as GameSpeed
		if speed != null:
			speed.set_paused(false)

# Once ever: the profile in the real game, the session otherwise (dev runs, tests).
func _remember(data: EnemyData) -> void:
	var kind := kind_of(data)
	session_seen[kind] = true
	_met[kind] = true
	var main := drift_director.owner if drift_director else null
	if main == null or get_tree().current_scene != main:  # Per account, dev runs included (never tests)
		return
	var profile := HeartwoodMemory.load_data()
	var seen: Array = profile.get(SEEN_KEY, [])
	if not seen.has(kind):
		seen.append(kind)
		profile[SEEN_KEY] = seen
		HeartwoodMemory.save_data(profile)

func _build(data: EnemyData) -> void:
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	head.add_child(BossDossier.BossPortrait.new(data, 76.0))
	var titles := VBoxContainer.new()
	titles.alignment = BoxContainer.ALIGNMENT_CENTER
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tag := Label.new()
	tag.text = "A new nightmare"
	UiStyle.caps(tag, 13, NEW_COLOR)
	titles.add_child(tag)
	var name := Label.new()
	name.text = data.display_name
	UiStyle.title(name, 24)
	titles.add_child(name)
	if data.trait_text != "":
		titles.add_child(StatusLinks.make_label(data.trait_text, 15, UiStyle.INK_DIM))
	head.add_child(titles)
	_content.add_child(head)
	var lines: Array = data.get_intro_lines() if data.has_method("get_intro_lines") else []
	if not lines.is_empty():
		_content.add_child(StatusLinks.make_label("\n".join(lines), 16, UiStyle.INK))
	var rows := NightmareIcons.make_rows(data, 30.0)
	if rows.get_child_count() > 0:
		_content.add_child(rows)
	var hint := String(data.get("hint")) if data.get("hint") != null else ""
	if hint != "":
		var tip := StatusLinks.make_label("", 15, UiStyle.WHISPER)
		tip.text = BossDossier._links_keep_tags("[i]%s[/i]" % hint)
		_content.add_child(tip)
	if _drift > 0:
		var when := Label.new()
		when.text = "Arrives in drift %d" % _drift
		UiStyle.caps(when, 13)
		_content.add_child(when)
	_live_label = null
	if is_instance_valid(live) and live.enemy_data == data:  # Clicked on the map: this one, right now
		_live_label = Label.new()
		_live_label.name = "Live"
		_live_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UiStyle.number(_live_label, 15, UiStyle.GOLD)
		_content.add_child(_live_label)
		_update_live()

# --- "New this block" (user, 2026-10-03: one page per rest, not a card per kind) ---------------------------------

# One new nightmare as a short row: portrait, name, its trait in a word, its tip. Tapping it opens the full card in
# place (intro lines and resists below the row), so no second screen ever opens on top. Shared with the boss dossier's
# "What's coming".
static func make_row(data: EnemyData) -> Control:
	var row := VBoxContainer.new()
	row.name = "New_" + kind_of(data)
	row.add_theme_constant_override("separation", 4)
	var head := Button.new()
	head.name = "Head"
	head.flat = true
	head.focus_mode = Control.FOCUS_NONE
	head.tooltip_text = "Tap for its full card"
	row.add_child(head)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(line)
	var portrait := BossDossier.BossPortrait.new(data, 48.0)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(portrait)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 0)
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(words)
	var name := Label.new()
	var verb := String(RuleBreakers.VERBS.get(data.trait_kind, ""))
	name.text = data.display_name + ((" · " + verb) if verb != "" else "")
	UiStyle.title(name, 18)
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	words.add_child(name)
	var hint := String(data.get("hint")) if data.get("hint") != null else ""
	if hint != "":
		var tip := Label.new()
		tip.text = IconInfo.format(hint)
		tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tip.add_theme_font_size_override("font_size", 14)
		tip.add_theme_color_override("font_color", UiStyle.WHISPER)
		tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		words.add_child(tip)
	var details := VBoxContainer.new()  # The full card, opened by a tap
	details.name = "Details"
	details.visible = false
	details.add_theme_constant_override("separation", 6)
	var lines: Array = data.get_intro_lines() if data.has_method("get_intro_lines") else []
	if not lines.is_empty():
		details.add_child(StatusLinks.make_label("\n".join(lines), 15, UiStyle.INK))
	elif data.trait_text != "":
		details.add_child(StatusLinks.make_label(data.trait_text, 15, UiStyle.INK))
	var resists := NightmareIcons.make_rows(data, 24.0)
	if resists.get_child_count() > 0:
		details.add_child(resists)
	else:
		resists.free()
	row.add_child(details)
	head.pressed.connect(func() -> void: details.visible = not details.visible)
	var fit := func() -> void:  # The button grows with its row (a Button doesn't size to its children)
		if is_instance_valid(head) and is_instance_valid(line):
			head.custom_minimum_size.y = maxf(52.0, line.get_combined_minimum_size().y + 4.0)
	line.minimum_size_changed.connect(fit)
	fit.call_deferred()
	return row

# The rest's page: every new kind of the coming block as a row, one Continue.
func open_list(kinds: Array, drift: int = 0) -> void:
	if kinds.is_empty():
		return
	queue.clear()
	shown = null
	live = null
	_live_label = null
	_drift = drift
	if peek != null:
		peek.set_peeking(false)
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()
	var head := Label.new()
	head.name = "ListHead"
	head.text = "New this block"
	UiStyle.caps(head, 15, NEW_COLOR)
	_content.add_child(head)
	if drift > 0:
		var when := Label.new()
		when.text = "From drift %d" % drift
		UiStyle.caps(when, 13)
		_content.add_child(when)
	for data in kinds:
		_content.add_child(make_row(data))
		_remember(data)
	_next.text = "Continue"
	visible = true
	var speed := drift_director.get_node_or_null("%GameSpeed") as GameSpeed if drift_director else null
	if speed != null and not speed.paused:
		_paused_it = true
		speed.set_paused(true)

# "Health 180 / 240 · Soaked ×2 8s · Restless ×1", or "Dispelled" once it's gone.
func live_text() -> String:
	if not is_instance_valid(live) or live.is_cleansed:
		return "Dispelled"
	var parts: Array[String] = ["Health %d / %d" % [live.health, live.max_health]]
	for id in live.statuses.active_ids():
		var stacks: int = live.statuses.stacks(id)
		parts.append("%s%s %.0fs" % [IconInfo.status_name(id), " ×%d" % stacks if stacks > 1 else "", live.statuses.time_left(id)])
	var restless: String = load("res://scripts/ui/nightmare_info.gd").restless_text(live)
	if restless != "":
		parts.append(restless)
	return " · ".join(parts)

func _update_live() -> void:
	if _live_label != null and is_instance_valid(_live_label):
		var text := live_text()
		if text != _live_label.text:
			_live_label.text = text

# A kind that first shows up mid-block without a card (a split, a summon, an Omen extra): the game
# pauses on its centred card (screens_ui.md; it was a 2-second name plate).
func _on_spawned(node: Node) -> void:
	var data = node.get("enemy_data")
	if data == null or data.is_boss or not enabled():
		return
	var kind := kind_of(data)
	if _met.has(kind) or session_seen.has(kind):
		return
	_met[kind] = true
	if not auto_open_ok():
		return
	open.call_deferred([data], 0, node, false)  # Paused, centred: meet it now (queues behind a card)

# The run's opening rest has no rest_started: introduce block 1's never-seen kinds there (not on a
# resumed run, which starts mid-way).
func _on_opening_rest() -> void:
	if drift_director == null or drift_director.drifts_started != 0 or not drift_director.is_resting() or not auto_open_ok():
		return
	var kinds := new_kinds_in_block(1)
	if not kinds.is_empty():
		_pending = kinds
		_drift = 1
		_wait = OPEN_DELAY
