extends RichTextLabel

# The Heartwood's voice (onboarding.md "Whisper hints removed", user 2026-10-12: "remove the whisper hints, they're
# redundant with the tutorial popups"): one-line italic lines at the top of the screen. The teaching whispers are
# gone (the Lessons, LessonCard, are the only teaching). What stays is not a tutorial:
# - story beats: the run's first line during the opening camera glide (once per profile), a boss arriving, being
#   dispelled or taking its toll, and the first leaf lost in a run (each once per run);
# - the rule-breaker warning before a flyer / sprinter / burrower block: every time, never "once per profile";
# - the blocked-placement refusal, as a toast ("A dream can bend, but never close.").
# The "Hints" setting no longer switches these (it switches Lessons): set_enabled is kept for its callers and does
# nothing. The profile's whispers_seen list is still read and written (old profiles load as they are).

const TEXT := {
	&"start": "Something moves at the edge of the dream.",
	&"again": "I'm dreaming again. Good.",
	&"leaf": "It fed. A leaf blackens and falls.",
	&"boss": "Something old has found the dream.",
	&"after_boss": "It's gone, and something I'd forgotten came back.",
	&"boss_toll": "It took its toll, and went back into the dark.",  # A boss reached the Heartwood
	&"rule_breaker": "This one doesn't keep to the path. Watch for it.",  # The rule-breaker warning (RuleBreakers)
}
const EACH_RUN: Array[StringName] = [&"leaf", &"boss", &"after_boss", &"boss_toll"]  # Story beats: once a run
const EVERY_TIME: Array[StringName] = [&"rule_breaker"]  # A warning: whenever it applies
const REFUSAL := "Leave nightmares a way to the Heartwood. A dream can bend, but never close."  # The blocked-placement toast
const REFUSAL_EVERY := 3000  # ms between two refusal toasts

@onready var run_state: RunState = %RunState
@onready var drift_director: DriftDirector = %DriftDirector
@onready var tower_placer: TowerPlacer = %TowerPlacer

# A line is shown now (after any queued ahead of it). SoundHooks listens.
signal whispered(id: StringName)

var enabled := true  # Always on: these lines are story and warnings, not Hints
var term := ""  # The Codex term the showing line mentions ("" = none): tapping opens it
var plain := ""  # The showing line's text without link markup
var shown: Array[StringName] = []  # Every line shown this run, in order (tests)
var _seen: Array = []  # The profile's list (once-per-profile lines; old ids stay in it)
var _run_seen := {}  # EACH_RUN ids shown this run
var _showing: StringName = &""  # The queue's head is on screen
var _refused_at := -REFUSAL_EVERY

# Kept for the pause menu and the settings: Hints switch Lessons now, never these lines.
func set_enabled(_on: bool) -> void:
	pass

# Tests only (a run never sets it): no lines at all, the queue dropped and the line on screen ended. Tests that waited
# out the onboarding lines used set_enabled(false), which no longer switches them (the Hints change, 2026-10-12).
var muted := false

func mute() -> void:
	muted = true
	_queue.clear()
	_finish()

var _queue: Array[StringName] = []
var _tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	StatusLinks.hook(self)  # Status names in a line are links
	_style()
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # On only while a line with links or a term shows
	var memory := HeartwoodMemory.load_data()
	_seen = memory.get("whispers_seen", [])
	modulate.a = 0.0
	if not _seen.has("start") and not memory.settings.get("reduced_motion", false):
		_glide_along_path.call_deferred()  # After the camera is ready
	if memory.runs_played > 0:
		whisper(&"again")
	whisper(&"start")
	# A boss dispelled (the family pick it brings), a boss coming, a boss's toll.
	drift_director.family_pick_requested.connect(func(reason: StringName) -> void:
		if reason != &"first":
			whisper(&"after_boss"))
	drift_director.rest_started.connect(func(_block: int, _boss: bool, _bonus: int, _perfect: bool) -> void:
		if drift_director.is_boss_drift(drift_director.drifts_started + drift_director.drifts_per_block):
			whisper(&"boss")
		if not RuleBreakers.coming(drift_director).is_empty():
			whisper(&"rule_breaker"))  # The warning, as the Coming strip and DriftPanel show it: every time
	run_state.leaves_changed.connect(func(leaves: int, _max: int) -> void:
		if leaves < run_state.max_leaves:
			whisper(&"leaf"))
	%EnemyContainer.enemy_reached_goal.connect(func(enemy: Node2D) -> void:
		var data = enemy.get("enemy_data")
		if data is EnemyData and data.is_boss:
			whisper(&"boss_toll"))  # Acts 1–3: a flat leaf toll, then it leaves
	# A placement that would close the path: the refusal toast.
	tower_placer.build_rejected.connect(func(_cell: Vector2) -> void:
		if _choice_open() or not tower_placer.hover_breaks_path() or Time.get_ticks_msec() - _refused_at < REFUSAL_EVERY:
			return
		_refused_at = Time.get_ticks_msec()
		var hud := owner.get_node_or_null("HUD") if owner != null else null
		if hud != null and hud.has_method("show_toast"):
			hud.show_toast(REFUSAL))

# First run: the camera glides from the forest's edge to the Heartwood along the path.
func _glide_along_path() -> void:
	var camera := get_tree().get_first_node_in_group(&"game_camera")
	if camera == null:
		return
	var map_generator = %MapGenerator
	var cells: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	var points := PackedVector2Array()
	for cell in cells:  # Every cell: the camera paces itself by distance (GameCameraNode.glide_route)
		points.append(map_generator.MAP_GRID.calculate_map_position(cell))
	camera.glide_route(points)  # No glide when the whole route already fits on screen

# Queues `id` behind whatever is showing: once per profile, once per run (EACH_RUN) or every time (EVERY_TIME). An id
# with no line (a removed teaching whisper: GrowHints and old callers may still ask) is ignored. `_args` is unused now.
func whisper(id: StringName, _args: Array = []) -> void:
	if muted or not TEXT.has(id) or _queue.has(id):
		return
	if EACH_RUN.has(id):
		if _run_seen.has(id):
			return
	elif not EVERY_TIME.has(id) and _seen.has(String(id)):
		return
	_queue.append(id)
	if _queue.size() == 1:
		_show_next()

# The Heartwood's voice at the top of the screen (user, 2026-10-02: "go back to how it was before, but more readable,
# and lasting a bit longer no matter the speed"): the italic whisper face at HINT_SIZE in the whisper colour, a dark
# outline and a soft shadow, and only a faint feathered mist behind the line (no box) so it reads on the pale path and
# on effects. On screen for show_time() in REAL time (game speed and pause don't shorten it), with a slow fade;
# hovering or tapping holds it, tapping again dismisses it (a hint naming a Codex term opens it instead); one at a time.
const HINT_SIZE := 26
const HINT_MAX_WIDTH := 760.0
const TOP := 214.0  # Under the drift banner and the Coming strip (as before)
const MIN_TIME := 7.0
const BASE_TIME := 3.0
const PER_CHAR := 0.07
const FADE_OUT := 1.5
var held := false  # Tapped (or hovered): stays until dismissed

# Real seconds a hint stays: at least MIN_TIME, longer for long lines.
static func show_time(line: String) -> float:
	return maxf(MIN_TIME, BASE_TIME + PER_CHAR * line.length())

func _style() -> void:
	UiStyle.whisper(self, HINT_SIZE)  # Cormorant italic (ui_style.md)
	# The Heartwood's gold, not cream: cream sat on the pale path's own colour (user: "the text colour is a bit too close")
	add_theme_color_override("default_color", UiStyle.GOLD)
	add_theme_color_override("font_outline_color", Palette.DREAD)
	add_theme_constant_override("outline_size", 6)  # 3 px each side (scales with the UI)
	add_theme_color_override("font_shadow_color", Color(Palette.VOID, 0.7))
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 2)
	add_theme_constant_override("shadow_outline_size", 8)
	var mist := UiStyle.fog_patch(28.0, 8.0)  # Feathered: fades to nothing at its edges, no hard box
	mist.center_alpha = 0.7  # Dark enough behind the line to read on the path and on effects
	mist.edge_alpha = 0.0
	add_theme_stylebox_override("normal", mist)
	fit_content = true
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mouse_entered.connect(func() -> void:
		if _tween and modulate.a > 0.0:
			_tween.pause())
	mouse_exited.connect(func() -> void:
		if _tween and not held:
			_tween.play())

# Top centre (as before), as wide as the line needs.
func _place() -> void:
	var font := UiStyle.whisper_font()
	var width := clampf(font.get_string_size(plain, HORIZONTAL_ALIGNMENT_LEFT, -1, HINT_SIZE).x + 80.0, 280.0, HINT_MAX_WIDTH)
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	offset_left = -width / 2.0
	offset_right = width / 2.0
	var top := _clear_top()
	offset_top = top
	offset_bottom = top
	custom_minimum_size = Vector2(width, 0)

# Under the drift banner, the Coming strip and the boss reminder whatever their height this rest (user screenshot: a
# hint across the Coming strip): TOP, or lower when one of them reaches past it.
func _clear_top() -> float:
	var hud := get_parent() as Control
	if hud == null:
		return TOP
	var top := TOP
	for node in hud.get_children():
		if not (node is Control) or not node.visible or node == self:
			continue
		if node is ComingStrip or node.name == "DriftBanner":
			top = maxf(top, _lowest(node) - hud.global_position.y + 8.0)
	var reminder := hud.find_child("BossReminder", true, false) as Control
	if reminder != null and reminder.is_visible_in_tree():
		top = maxf(top, _lowest(reminder) - hud.global_position.y + 8.0)
	return top

# The real bottom of `node`'s visible contents: the Coming strip's lead entry and its trait label hang below the strip's
# own rect (user screenshot: a hint over "Flies").
static func _lowest(node: Control) -> float:
	var bottom := node.get_global_rect().end.y
	for child in node.find_children("*", "Control", true, false):
		if child.is_visible_in_tree() and child.size.y > 0.0:
			bottom = maxf(bottom, child.get_global_rect().end.y)
	return bottom

# A choice screen (family pick, Dream, gift, Omen) is open: lines wait behind it (user screenshot: a hint across the
# family cards). One already showing pauses, hidden, and goes on after.
var _hidden_for_choice := false

func _choice_open() -> bool:
	var lesson := get_tree().get_first_node_in_group(LessonCard.GROUP) as Control  # A Lesson card is up (user 2026-10-13:
	if lesson != null and lesson.visible:  # story lines and warnings never show over or behind a card or a choice)
		return true
	var discovery := get_tree().get_first_node_in_group(ComboFeedback.GROUP)  # A discovery card is a paused card too
	if discovery != null and discovery.has_method("showing") and discovery.showing():
		return true
	var pause := get_node_or_null("%PauseMenu") as Control  # The pause menu and its Codex cover the screen too
	if pause != null and pause.visible:
		return true
	return drift_director != null and (drift_director.pending_choice() != &"" or drift_director.awaiting_family_pick or RestScreens.any_open(self, drift_director))

func _show_next() -> void:
	if _queue.is_empty():
		return
	var id: StringName = _queue[0]
	if _choice_open():
		return  # _process shows it once the choice closes
	_showing = id
	shown.append(id)
	if EACH_RUN.has(id):
		_run_seen[id] = true
	elif not EVERY_TIME.has(id) and not _seen.has(String(id)):
		_seen.append(String(id))
		_remember()
	var raw: String = TEXT.get(id, "")
	plain = IconInfo.format(raw)  # {damp} … become today's status names
	var linked := StatusLinks.bbcode(raw)  # From the tokens: game terms become links too
	text = "[center]%s[/center]" % linked
	whispered.emit(id)
	# Status names are links of their own (hover / tap: their definition). A whisper without one is
	# tappable as a whole when it names a Codex term (screens_ui.md "The Codex").
	var has_links := linked != plain.replace("[", "[lb]")
	term = "" if has_links else CodexData.find_term(plain)
	mouse_filter = Control.MOUSE_FILTER_STOP  # Hover / tap hold it
	tooltip_text = "%s in the Codex" % term if term != "" else ""
	held = false
	_place()
	_place.call_deferred()  # Again once the text has its height
	if _tween:
		_tween.kill()
	_tween = UiTime.tween(self, false)  # Real time: 3× speed doesn't cut it short (and the node runs while paused)
	_tween.tween_property(self, "modulate:a", 1.0, 0.3)  # A fade only: nothing moves (reduced motion too)
	_tween.tween_interval(show_time(plain))
	_tween.tween_property(self, "modulate:a", 0.0, FADE_OUT)
	_tween.tween_callback(_finish)

# The showing hint ends (its time ran out, or a tap dismissed it); the next queued one follows.
func _finish() -> void:
	if _tween:
		_tween.kill()
	modulate.a = 0.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	term = ""
	held = false
	if not _queue.is_empty() and _showing != &"":
		_queue.pop_front()
	_showing = &""
	_show_next()

func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	accept_event()
	if term != "":
		var pause := get_node_or_null("%PauseMenu")
		if pause != null and pause.has_method("open_codex"):
			pause.open_codex(&"glossary", term)
		_finish()
	elif held:
		_finish()  # The second tap dismisses it
	else:
		held = true  # The first tap holds it
		if _tween:
			_tween.pause()

func _process(_delta: float) -> void:
	var showing := not _queue.is_empty() and _showing == _queue[0]
	if showing and visible:
		var top := _clear_top()  # The strip can grow while a hint shows (a rest's Coming strip, the boss reminder)
		if not is_equal_approx(top, offset_top):
			offset_top = top
			offset_bottom = top
	var choice := _choice_open()
	if choice and showing and not _hidden_for_choice:
		_hidden_for_choice = true  # Paused behind the choice screen
		visible = false
		if _tween:
			_tween.pause()
	elif not choice and _hidden_for_choice:
		_hidden_for_choice = false
		visible = true
		if _tween and not held:
			_tween.play()
	elif not choice and not showing and not _queue.is_empty():
		_show_next()  # One waited for the choice to close

# Remembered in the player's profile, except in tests (the scene isn't the running game there).
func _remember() -> void:
	if get_tree().current_scene != owner or MetaRun.is_dev_run():
		return
	var memory := HeartwoodMemory.load_data()
	memory["whispers_seen"] = _seen
	HeartwoodMemory.save_data(memory)
