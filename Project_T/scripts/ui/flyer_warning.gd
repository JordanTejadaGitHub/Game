extends Control

# "Flyers next block" (Balancing Discussion, owner 2026-10-22: "don't highlight, just have a UI screen pop up that says
# something about flyers coming next block"; flyers decided 4 of the owner's last 6 runs and text hints get skimmed).
# At the rest before a block whose drifts bring a flyer (EnemyData.Trait.FLYING; a boss's summons count, so the boss
# block's Crows do), one centred card, only before the run's first flyer block: the first flyer's portrait, "Flyers next block", and one line.
# One tap or click anywhere (or Esc) closes it. It pauses like the choice screens (only a running game, and only what it
# paused) and waits for the rest's other screens (family pick, Dream, gift, Omen, the boss dossier, the new-nightmare
# card), so it's the last thing before Start. The Coming strip's line stays. Made by the HUD (name "FlyerWarning", in
# RestScreens.SCREENS).

const TITLE := "Flyers next block"
const LINE := "They fly straight over your maze to the Heartwood."
const ROUTE_LINE := "They fly along your path, above your walls."  # Route flyers (EnemyData.flies_along_route: Crow, Night Kite, Gloamwing, Pall)
const OPEN_DELAY := 0.4

var drift_director: DriftDirector
var _pending_block := 0  # The block to warn about once the rest's screens are done (0 = none)
var _warned := {}  # Block -> true: warned this run
var _wait := 0.0
var _paused_it := false
var _portrait_slot := CenterContainer.new()
var _panel := PanelContainer.new()
var _line: Label = null

func _init(director: DriftDirector = null) -> void:
	drift_director = director

func _ready() -> void:
	name = "FlyerWarning"
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	WorldLabel.cover_while_visible(self, &"flyer_warning")
	var shade := ColorRect.new()
	shade.color = Color(UiStyle.FOG, 0.45)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(centre)
	_panel.add_theme_stylebox_override("panel", UiStyle.panel(22.0, 18.0))
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # A tap anywhere closes it, the card included
	centre.add_child(_panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(box)
	_portrait_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_portrait_slot)
	var title := Label.new()
	title.text = TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.title(title, 28)
	box.add_child(title)
	_line = Label.new()
	var line := _line
	line.text = LINE
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.custom_minimum_size.x = 380.0
	line.add_theme_font_size_override("font_size", 18)
	line.add_theme_color_override("font_color", UiStyle.INK)
	box.add_child(line)
	var hint := Label.new()
	hint.text = "Tap to continue"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.caps(hint, 12, UiStyle.INK_DIM)
	box.add_child(hint)
	if drift_director != null:
		drift_director.rest_started.connect(_on_rest_started)
		_on_opening_rest.call_deferred()

# The first flyer arriving in drifts `first`..`last` (a summon counts: the boss block's Crows), or null.
static func first_flyer(director: DriftDirector, first: int, last: int) -> EnemyData:
	if director == null or first > last:
		return null
	for item in ComingStrip.kinds_in_range(director, first, last):
		var data: EnemyData = item[0]
		if data.trait_kind == EnemyData.Trait.FLYING:
			return data
		for summon in data.get_summons():
			var kind: EnemyData = summon.get("data")
			if kind != null and kind.trait_kind == EnemyData.Trait.FLYING:
				return kind
	return null

func _block_span(block: int) -> Vector2i:
	var per := drift_director.drifts_per_block
	return Vector2i((block - 1) * per + 1, mini(block * per, drift_director.get_total_drifts()))

func _on_rest_started(block: int, _boss: bool, _bonus: int, _perfect: bool) -> void:
	_queue_block(block + 1)

func _on_opening_rest() -> void:
	if drift_director != null and drift_director.drifts_started == 0 and drift_director.is_resting():
		_queue_block(1)

func _queue_block(block: int) -> void:
	if drift_director == null or not drift_director.has_next_drift() or _warned.has(block) \
			or not NightmareIntro.auto_open_ok():
		return
	var span := _block_span(block)
	# Only the run's first flyer block (owner 2026-10-22: "don't have to show me the next flyer block every time, just
	# the first time a flyer would come"): an earlier block that brought one means it was shown (or a Continue skips it)
	if first_flyer(drift_director, 1, span.x - 1) != null:
		return
	if first_flyer(drift_director, span.x, span.y) != null:
		_pending_block = block
		_wait = OPEN_DELAY

func _process(delta: float) -> void:
	if _pending_block == 0:
		return
	if not drift_director.is_resting():
		_pending_block = 0  # The block started without it
		return
	_wait -= delta / maxf(Engine.time_scale, 0.001)
	if _wait > 0.0 or not RestScreens.clear_for(self, drift_director):
		return
	var dossier := get_tree().get_first_node_in_group(BossDossier.GROUP) as BossDossier
	var intro := get_tree().get_first_node_in_group(NightmareIntro.GROUP) as NightmareIntro
	if (dossier != null and dossier.is_waiting()) or (intro != null and intro.is_busy()):
		return  # After the boss dossier and the new-nightmare card: the last thing before Start
	open(_pending_block)

# Shows the warning for `block` (tests can call it straight).
func open(block: int) -> void:
	_pending_block = 0
	var span := _block_span(block)
	var flyer := first_flyer(drift_director, span.x, span.y)
	if flyer == null:
		return
	_warned[block] = true
	for child in _portrait_slot.get_children():
		child.queue_free()
	_portrait_slot.add_child(BossDossier.BossPortrait.new(flyer, 88.0))
	_line.text = ROUTE_LINE if bool(flyer.get("flies_along_route")) else LINE  # Which way the first flyer flies
	visible = true
	var speed := drift_director.get_node_or_null("%GameSpeed") as GameSpeed
	if speed != null and not speed.paused:
		_paused_it = true
		speed.set_paused(true)

func close() -> void:
	visible = false
	if _paused_it:
		_paused_it = false
		var speed := drift_director.get_node_or_null("%GameSpeed") as GameSpeed
		if speed != null:
			speed.set_paused(false)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		accept_event()
		close()

func _input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("cancel_build") or event.is_action_pressed("ui_cancel")
			or event.is_action_pressed("ui_accept") or event.is_action_pressed("start_drift")):
		get_viewport().set_input_as_handled()
		close()
