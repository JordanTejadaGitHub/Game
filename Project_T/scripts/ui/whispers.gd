extends RichTextLabel

# Heartwood whispers (onboarding.md): one-line italic hints at the top of the screen, in the story's
# voice, each shown the first time it matters and then never again (remembered in HeartwoodMemory).
# Off when the "Hints" setting is off (player-facing "Hints" since 2026-10-01; the code keeps "whispers").
# Mostly polls simple conditions each frame, so it
# needs no hooks in the systems it teaches.

const TEXT := {
	&"start": "Something moves at the edge of the dream.",
	&"plant": "Plant a Warden near the path.",
	&"first_cleanse": "Nightmares. They're coming for the dream. Don't let them reach me.",
	&"walls": "Wardens are walls. Make them take the long way.",
	&"flow": "They don't stop. They come in {drifts}, like fog.",
	&"speed": "Pause if you need to think. They'll wait.",
	&"rest": "Rest here. Rearrange the forest while they're gone.",  # (Rests refund 75%, not everything: onboarding.md)
	&"save": "The forest will wait for you.",
	&"cage": "A dream can bend, but never close.",
	&"grow": "That %s could grow. Click it.",  # The Warden's name (GrowHints, the first rest one can grow)
	&"grow_more": "Your Wardens can become much more than this.",  # Drift 15, nothing grown or ranked yet (GrowHints)
	&"kin": "Two of one family, planted close, learn from each other.",
	&"unbound": "Turn them too often, and they stop listening.",
	&"dead_wood": "Dead wood. I can't move it… yet.",
	&"tend": "Tend the forest, and it will remember you.",
	&"chain": "One reaction set off another: a chain. Reach 10 for a Dawnburst.",
	&"leaf": "It fed. A leaf blackens and falls.",
	&"flyer": "Some of them don't walk. Guard the ground near the Heartwood.",
	&"sell": "Selling gives back most of it during a {rest}, and half while nightmares walk.",  # 75% / 50% (TowerSeller)
	&"boss": "Something old has found the dream.",
	&"after_boss": "It's gone, and something I'd forgotten came back.",
	&"again": "The Heartwood dreams again.",
	&"damp": "{damp}: water hits it harder, and lightning loves it.",  # Soaked no longer slows (IconInfo)
	&"drowsy": "{drowsy}: heavy-eyed and slow.",
	&"spored": "{spored}: the poison keeps eating at it.",
	&"marked": "{marked}: every Warden hits it harder.",
	&"static": "{static}: five charges, and a bolt.",
	&"held": "{held}: it can't move. Now's the time.",
	# Approved 2026-10-02 (story chat, user: "Players will get used to it."):
	&"omen": "Face it, or let the sky stay clear.",  # The first Omen offer
	&"dreamlight": "Dreamlight remembers what your Wardens could become.",  # The first Dreamlight earned
	&"boss_toll": "It took its toll, and went back into the dark.",  # The first boss to reach the Heartwood
	&"rule_breaker": "This one doesn't keep to the path. Watch for it.",  # The first rule-breaker warning (RuleBreakers)
	&"nurture": "Tend it, and it grows deeper roots.",  # The first rank
	&"let_pass": "Not every dream is yours to keep. You can let one pass.",  # The first Dream offer that can be let pass
}

@onready var run_state: RunState = %RunState
@onready var drift_director: DriftDirector = %DriftDirector
@onready var tower_placer: TowerPlacer = %TowerPlacer
@onready var obstacle_clearer: ObstacleClearer = %ObstacleClearer
@onready var tower_container: Node2D = %TowerContainer
@onready var dream_state: DreamState = %DreamState

# A whisper is shown now (after any queued ahead of it; never for ones already seen). SoundHooks
# gives the first chain's whisper the Dream-screen breath-in (audio_direction.md).
signal whispered(id: StringName)

var enabled := true
var term := ""  # The Codex term the showing whisper mentions ("" = none): tapping opens it
var plain := ""  # The showing whisper's text without link markup
var _seen: Array = []

# The pause menu's toggle. Turning off hides the current whisper and drops the queue.
func set_enabled(on: bool) -> void:
	enabled = on
	set_process(on)
	if not on:
		_queue.clear()
		if _tween:
			_tween.kill()
		modulate.a = 0.0
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		term = ""
var _queue: Array[StringName] = []
var _tween: Tween

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	StatusLinks.hook(self)  # Status names in whispers are links
	_style()  # The body face on a fog patch above the Warden bar (was Cormorant italic, top centre: hard to read)
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # On only while a whisper with links or a term shows
	var memory := HeartwoodMemory.load_data()
	enabled = memory.settings.whispers
	_seen = memory.get("whispers_seen", [])
	modulate.a = 0.0
	# The Clear tool lights up with the first clearing Dream (screens_ui.md "The Clear tool").
	# Connected even while whispers are off: whisper() checks `enabled` itself.
	obstacle_clearer.lock_changed.connect(func(locked: bool) -> void:
		if not locked:
			whisper(&"tend"))
	# The first chain ever (tower_design.md "Chains"). ReactionTracker joins the run with the first
	# Reaction, so catch it when it arrives.
	owner.child_entered_tree.connect(func(node: Node) -> void:
		if node is ReactionTracker:
			node.chain_reached.connect(func(_count: int, _where: Vector2, _towers: Array) -> void: whisper(&"chain")))
	# The first Unbound ever (run_design.md "No maze juggling"); connected even while whispers are off.
	var unbound_source = %EnemyContainer
	if unbound_source.has_signal("nightmare_unbound"):
		unbound_source.nightmare_unbound.connect(func(_e: Node2D) -> void: whisper(&"unbound"))
	if not enabled:
		set_process(false)
		return
	if not _seen.has("start") and not memory.settings.get("reduced_motion", false):
		_glide_along_path.call_deferred()  # After the camera is ready
	if memory.runs_played > 0:
		whisper(&"again")
	whisper(&"start")
	whisper(&"plant")
	var spawner = %EnemyContainer
	spawner.enemy_cleansed.connect(func(_e: Node2D) -> void: whisper(&"first_cleanse"), CONNECT_ONE_SHOT)
	drift_director.family_pick_requested.connect(func(reason: StringName) -> void:
		if reason != &"first":
			whisper(&"after_boss"))
	# "Wardens are walls" once the first pick closes (the pick screen hid it when it came as the pick opened).
	%FamilyPickScreen.family_chosen.connect(func(_offered: Array, _chosen: Resource) -> void:
		if drift_director.drifts_started <= 1:
			whisper(&"walls"))
	# The approved lines (2026-10-02): the first Omen offer, Dreamlight, a boss's toll, a rule-breaker, a rank, Let it pass.
	%OmenDirector.offer_ready.connect(func(_omens: Array[OmenData], _block: int) -> void: whisper(&"omen"))
	dream_state.dreamlight_earned.connect(func(amount: int, _source: StringName) -> void:
		if amount > 0:
			whisper(&"dreamlight"))
	dream_state.offer_ready.connect(func(_cards: Array[UpgradeData], _drift: int) -> void:
		if dream_state.can_skip():
			whisper(&"let_pass"))
	tower_container.child_entered_tree.connect(func(node: Node) -> void:
		if node is Tower and not node.nurtured.is_connected(_on_nurtured):
			node.nurtured.connect(_on_nurtured))
	drift_director.drift_started.connect(func(number: int) -> void:
		if number == 2:
			whisper(&"flow")
			whisper(&"speed"))
	drift_director.rest_started.connect(func(_block: int, _boss: bool, _bonus: int, _perfect: bool) -> void:
		whisper(&"rest")
		whisper(&"save")
		if drift_director.is_boss_drift(drift_director.drifts_started + drift_director.drifts_per_block):
			whisper(&"boss")
		if not RuleBreakers.coming(drift_director).is_empty():
			whisper(&"rule_breaker"))  # As the Coming strip and DriftPanel warn of it
	run_state.leaves_changed.connect(func(leaves: int, _max: int) -> void:
		if leaves < run_state.max_leaves:
			whisper(&"leaf"))
	# The first leaf lost to a flyer (a Phantom): it never walked the maze (onboarding.md).
	%EnemyContainer.enemy_reached_goal.connect(func(enemy: Node2D) -> void:
		if enemy.has_method("is_flying") and enemy.is_flying():
			whisper(&"flyer")
		var data = enemy.get("enemy_data")
		if data is EnemyData and data.is_boss:
			whisper(&"boss_toll"))  # Acts 1–3: a flat leaf toll, then it leaves
	%TowerSeller.tower_sold.connect(func(_t: Tower, _refund: int) -> void: whisper(&"sell"), CONNECT_ONE_SHOT)

func _on_nurtured(_tower: Tower) -> void:
	whisper(&"nurture")

# First run: the camera glides from the forest's edge to the Heartwood along the path.
func _glide_along_path() -> void:
	var camera := get_tree().get_first_node_in_group(&"game_camera")
	if camera == null:
		return
	var map_generator = %MapGenerator
	var cells: PackedVector2Array = map_generator.get_path_from(map_generator.startPath)
	var points := PackedVector2Array()
	for i in range(0, cells.size(), maxi(cells.size() / 12, 1)):
		points.append(map_generator.MAP_GRID.calculate_map_position(cells[i]))
	points.append(map_generator.MAP_GRID.calculate_map_position(cells[-1]))
	camera.glide(points, 6.0)

# Shows `id` once ever (queued behind whatever is showing).
var _args := {}  # Whisper id -> the words for its %s (the grow whisper's Warden name)

# `args` fill the text's %s ("That %s could grow." + ["Sporeling"]).
func whisper(id: StringName, args: Array = []) -> void:
	if not enabled or _seen.has(String(id)) or _queue.has(id):
		return
	if not args.is_empty():
		_args[id] = args
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
	UiStyle.whisper(self, HINT_SIZE)  # Cormorant italic in the whisper colour (ui_style.md)
	add_theme_color_override("font_outline_color", Palette.DREAD)
	add_theme_constant_override("outline_size", 4)  # About 2 px each side
	add_theme_color_override("font_shadow_color", Color(Palette.VOID, 0.7))
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 2)
	add_theme_constant_override("shadow_outline_size", 6)
	var mist := UiStyle.fog_patch(28.0, 8.0)  # Feathered: fades to nothing at its edges, no hard box
	mist.center_alpha = 0.4
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
	offset_top = TOP
	offset_bottom = TOP
	custom_minimum_size = Vector2(width, 0)

func _show_next() -> void:
	if _queue.is_empty():
		return
	var id: StringName = _queue[0]
	_seen.append(String(id))
	_remember()
	var raw: String = TEXT.get(id, "")
	if _args.has(id):
		raw = raw % _args[id]
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
	_tween = create_tween()
	_tween.set_ignore_time_scale(true)  # Real time: 3× speed doesn't cut it short (and the node runs while paused)
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
	if not _queue.is_empty():
		_queue.pop_front()
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

# Conditions that are easiest to notice by looking.
func _process(_delta: float) -> void:
	if tower_placer.hover_breaks_path():
		whisper(&"cage")
	# Obstacles can't be cleared until the run's first clearing Dream (run_design.md).
	if obstacle_clearer._hover_obstacle != null and obstacle_clearer.is_locked():
		whisper(&"dead_wood")
	for id in EnemyStatuses.ALL:
		if not _seen.has(String(id)) and _any_creature_has(id):
			whisper(id)
	# Kinships (screens_ui.md "Kinship feedback", playtest fix): two branches of one family planted.
	if not _seen.has("kin") and RestReport.two_branch_family(tower_container.get_children()) != "":
		whisper(&"kin")
	# "That Sporeling could grow. Click it." comes from GrowHints at the first rest a Warden can grow.

func _any_creature_has(id: StringName) -> bool:
	for enemy in get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		if enemy.statuses.has(id):
			return true
	return false

# Remembered in the player's profile, except in tests (the scene isn't the running game there).
func _remember() -> void:
	if get_tree().current_scene != owner or MetaRun.is_dev_run():
		return
	var memory := HeartwoodMemory.load_data()
	memory["whispers_seen"] = _seen
	HeartwoodMemory.save_data(memory)
