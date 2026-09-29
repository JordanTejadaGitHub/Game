extends Control
class_name NightmareIntro

# New nightmare introduction (screens_ui.md "New nightmare introduction", 2026-09-28: "new enemies
# should have a display window in the middle like bosses"): the first time ever a nightmare kind is
# about to appear, the rest before its block opens a centred card, the boss dossier's style but
# smaller: animated portrait, name, its trait line, what it does (EnemyData.get_intro_lines()), its
# resist / weak / immune icons, and one hint (EnemyData.hint). Several new kinds: one card each, with
# "Next" (a kind's split / follower kinds right after it). After the Dream / Omen, before the boss
# dossier. Dismissed by the button, a tap outside or Esc; reopened from its portrait in the Coming
# strip (open_for). A kind that first appears mid-block without a card (a Mourner's Sobs) gets a
# 2-second name plate when the first one spawns. Once ever per kind (profile "intros_seen"; dev runs
# and tests: this session only). Off with the "Heartwood whispers" setting. Made by the HUD.

const GROUP := &"nightmare_intro"
const SEEN_KEY := "intros_seen"
const WIDTH := 460.0
const OPEN_DELAY := 0.35
const PLATE_TIME := 2.0
const NEW_COLOR := UiStyle.GOLD  # Glow

static var session_seen := {}  # Kind -> true: shown this session (dev runs, tests)

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
var _plate := Label.new()
var _plate_time := 0.0
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
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var shade := ColorRect.new()
	shade.color = Color(UiStyle.FOG, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	_panel.add_theme_stylebox_override("panel", UiStyle.panel(18.0, 14.0))
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	centre.add_child(_panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	_panel.add_child(outer)
	_content.custom_minimum_size = Vector2(WIDTH, 0)
	_content.add_theme_constant_override("separation", 8)
	outer.add_child(_content)
	_next.focus_mode = Control.FOCUS_NONE
	_next.custom_minimum_size = Vector2(180, 44)
	_next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UiStyle.primary(_next)
	_next.pressed.connect(advance)
	outer.add_child(_next)
	# The mid-block name plate (screen space, top centre, under the strip).
	_plate.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_plate.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_plate.offset_top = 150.0
	_plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiStyle.title(_plate, 22, NEW_COLOR)
	_plate.add_theme_color_override("font_outline_color", UiStyle.FOG)
	_plate.add_theme_constant_override("outline_size", 8)
	_plate.visible = false
	get_parent().add_child.call_deferred(_plate)
	for kind in HeartwoodMemory.load_data().get("nightmares_seen", []):
		_met[kind] = true
	if drift_director != null:
		drift_director.rest_started.connect(_on_rest_started)
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

# --- Which kinds, when ---------------------------------------------------------------------------

static func enabled() -> bool:
	return bool(HeartwoodMemory.get_settings().get("whispers", true))

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
	if not enabled() or not drift_director.has_next_drift():
		return
	var kinds := new_kinds_in_block(block + 1)
	if not kinds.is_empty():
		_pending = kinds
		_drift = block * drift_director.drifts_per_block + 1
		_wait = OPEN_DELAY

# The rest's earlier screens (family pick, Dream, Omen, pause, results) are done.
func screens_clear() -> bool:
	var main := drift_director.owner
	for path in ["HUD/FamilyPickScreen", "HUD/DreamScreen", "HUD/OmenScreen", "HUD/RememberScreen", "HUD/PauseMenu", "HUD/ResultsScreen"]:
		var screen := main.get_node_or_null(path) as CanvasItem if main != null else null
		if screen != null and screen.visible:
			return false
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	if dreams != null and (dreams.is_offering() or dreams.has_pending_offer()):
		return false
	var omens := get_tree().get_first_node_in_group(OmenDirector.GROUP) as OmenDirector
	if omens != null and omens.is_offering():
		return false
	return not drift_director.awaiting_family_pick

# The boss dossier waits while a card is open or about to open.
func is_busy() -> bool:
	return visible or not _pending.is_empty()

func _process(delta: float) -> void:
	var real := delta / maxf(Engine.time_scale, 0.001)
	if _plate_time > 0.0:
		_plate_time -= real
		_plate.modulate.a = clampf(_plate_time / 0.4, 0.0, 1.0)
		_plate.visible = _plate_time > 0.0
	if _pending.is_empty():
		return
	if not drift_director.is_resting():
		_pending = []
		return
	_wait -= real
	if _wait <= 0.0 and screens_clear():
		var kinds := _pending
		_pending = []
		open(kinds, _drift)

# --- Open / next / close -------------------------------------------------------------------------

func open(kinds: Array, drift: int = 0) -> void:
	if kinds.is_empty():
		return
	queue = kinds.duplicate()
	_drift = drift
	_show_next()
	var speed := drift_director.get_node_or_null("%GameSpeed") as GameSpeed if drift_director else null
	_paused_it = speed != null and not drift_director.is_resting() and not speed.paused
	if _paused_it:
		speed.set_paused(true)

func advance() -> void:
	if queue.is_empty():
		close()
	else:
		_show_next()

func _show_next() -> void:
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
	if main == null or get_tree().current_scene != main or MetaRun.is_dev_run():
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

# A kind that first shows up mid-block without a card (a split or follower): its name for 2 s.
func _on_spawned(node: Node) -> void:
	var data = node.get("enemy_data")
	if data == null or data.is_boss or not enabled():
		return
	var kind := kind_of(data)
	if _met.has(kind) or session_seen.has(kind):
		return
	_met[kind] = true
	_plate.text = "New nightmare: %s" % data.display_name
	_plate_time = PLATE_TIME
	_plate.modulate.a = 1.0
	_plate.visible = true
