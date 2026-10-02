extends Control
class_name RestChoiceScreen

# Rest choices (spire_difficulty.md Phase 3, Slay the Spire's campfire; Spire experiment): at every rest, after the
# Dream and the Omen, pick ONE:
# - Rest: regrow 1 leaf (only below max). At full leaves it becomes Clear (one free clear) or, with fewer than
#   MIN_OBSTACLES obstacles left, Forage (+FORAGE_DEW Dew × the act).
# - Tend: one free Nurture rank (RunState.free_nurtures).
# - Dream: one more card in the next Dream offer (Roguelite Code's DreamState.add_next_offer_cards).
# Holds Start like the other choices (DriftDirector.pending_choice() == &"rest"), with Peek at the map and the arm
# delay; saved with the run (RunState.rest_choices, RunSaver) and recorded in the run history. Made by the HUD.

signal chosen(block: int, choice: StringName)

const GROUP := &"rest_choice"
const MIN_OBSTACLES := 3
const FORAGE_DEW := 20
const TEXT := {
	&"rest": ["Rest", "Regrow 1 leaf."],
	&"clear": ["Clear", "One free clear: tend a tree or move a rock for nothing."],
	&"forage": ["Forage", "+%d Dew."],
	&"tend": ["Tend", "One free Nurture rank for a Warden of your choice."],
	&"dream": ["Dream", "One more card in the next Dream."],
}

var drift_director: DriftDirector
var run_state: RunState
var dream_state: DreamState
var map: Node
var offer: Array[StringName] = []
var waiting := false  # A choice is owed at this rest
var peek: ChoicePeek
var arm: ChoiceArm
var _block := 0
var _cards := HBoxContainer.new()

func _init(director: DriftDirector = null) -> void:
	drift_director = director

func _ready() -> void:
	name = "RestChoiceScreen"
	add_to_group(GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	run_state = drift_director.get_node_or_null("%RunState")
	dream_state = drift_director.get_node_or_null("%DreamState")
	map = drift_director.get_node_or_null("%MapGenerator")
	var dim := ColorRect.new()
	dim.color = Color(UiStyle.FOG, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(centre)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	centre.add_child(box)
	var title := Label.new()
	title.text = "The forest rests. Choose one."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiStyle.display(title, 28)
	box.add_child(title)
	_cards.add_theme_constant_override("separation", 16)
	_cards.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(_cards)
	peek = ChoicePeek.new(self, [dim, centre], "Back to the rest")
	box.add_child(peek.make_peek_button())
	arm = ChoiceArm.attach(self, _cards)
	drift_director.rest_started.connect(func(block: int, _boss: bool, _bonus: int, _perfect: bool) -> void:
		if not has_chosen(block):
			_block = block
			waiting = true)
	drift_director.rest_ended.connect(func(_block_number: int) -> void:
		waiting = false
		visible = false)

# A choice is owed at this rest (shown, waiting behind the Dream / Omen, or minimised): Start waits for it.
func is_offering() -> bool:
	return waiting

func has_chosen(block: int) -> bool:
	return run_state.rest_choices.any(func(c: Dictionary) -> bool: return int(c.get("block", -1)) == block)

# Opens once the Dream and the Omen are done (they come first).
func _process(_delta: float) -> void:
	if waiting and not visible and drift_director.pending_choice() == &"rest":
		open()

# The three options for now: the leaf when one is missing, else a clear (or Forage with few obstacles left).
func make_offer() -> Array[StringName]:
	var first := &"rest"
	if run_state.leaves >= run_state.max_leaves:
		first = &"clear" if map != null and map.obstacles.size() >= MIN_OBSTACLES else &"forage"
	var options: Array[StringName] = [first, &"tend", &"dream"]
	return options

func forage_dew() -> int:
	return FORAGE_DEW * maxi(drift_director.get_act(maxi(drift_director.drifts_started, 1)), 1)

func dream_available() -> bool:
	return dream_state != null and dream_state.has_method("add_next_offer_cards")

func open() -> void:
	offer = make_offer()
	for child in _cards.get_children():
		_cards.remove_child(child)
		child.queue_free()
	for id in offer:
		_cards.add_child(_card(id))
	visible = true
	arm.arm()

func _card(id: StringName) -> Button:
	var button := Button.new()
	button.name = String(id).capitalize()
	var words: Array = TEXT[id]
	var body: String = words[1] % forage_dew() if id == &"forage" else words[1]
	button.text = "%s\n%s" % [words[0], body]
	button.custom_minimum_size = Vector2(220, 140)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.focus_mode = Control.FOCUS_NONE
	UiStyle.card_button(button, UiStyle.GOLD)
	if id == &"dream" and not dream_available():
		button.disabled = true
		button.tooltip_text = "Waiting for the Dream side of this (Roguelite Code)."
	button.pressed.connect(choose.bind(id))
	return button

# Applies `id`, records it, closes; the rest goes on.
func choose(id: StringName) -> void:
	if not waiting:
		return
	match id:
		&"rest":
			run_state.regrow_leaves(1)
		&"clear":
			run_state.add_free_clears(1)
		&"forage":
			var at: Vector2 = map.MAP_GRID.calculate_map_position(map.endPath) if map != null else Vector2.ZERO
			run_state.earn_dew_at(forage_dew(), at)
		&"tend":
			run_state.free_nurtures += 1
		&"dream":
			if not dream_available():
				return
			dream_state.add_next_offer_cards(1)
	run_state.rest_choices.append({"block": _block, "choice": String(id)})
	waiting = false
	visible = false
	chosen.emit(_block, id)
