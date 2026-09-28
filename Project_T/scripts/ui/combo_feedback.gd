extends Control
class_name ComboFeedback

# Combos in play (screens_ui.md "The Codex: Glossary and Combos"): the 7 synergies and the 8
# Reactions (CodexData.combos()). Discovered the first time each one fires, ever: a card slides in
# at the top for ~5 s ("Combo discovered: Thunderclap", ingredients, one line, "Added to the Codex"),
# without pausing; several queue; tapping the card opens its Codex entry. Saved in the profile
# (`combos_seen`, lifetime `combo_counts`; also in the demo; never tests or developer runs), with the
# "all_combos" milestone once all are found. Also counts Reactions per block for the rest report
# (Fx shows their callouts). Sources: DamageLog combo tags (conducted, popped, fog), ReactionTracker
# (Reactions), and ComboFeedback.report(id, near) from game code where a synergy happens (set_off,
# marked_blow, caught, asleep).

signal combo_discovered(id: StringName)  # For a discovery chime (SoundHooks)

const GROUP := &"combo_feedback"
const CARD_TIME := 5.0
const SEEN_KEY := "combos_seen"
const COUNTS_KEY := "combo_counts"
const LEGACY_KEY := "reactions_seen"  # Before synergies were combos
const MILESTONE := "all_combos"
const DAMAGE_TAGS: Array[StringName] = [&"conducted", &"popped", &"fog"]

@onready var drift_director: DriftDirector = %DriftDirector
@onready var run_state: RunState = %RunState

var block_counts := {}  # Reaction id -> times this block (rest report)
var block_longest_chain := 0
var block_new: Array[StringName] = []  # Combos discovered this block
var run_counts := {}  # Combo id -> times this run
var _seen: Array = []  # Combo ids (String) discovered ever
var _unsaved := {}  # Combo id -> count not yet added to the profile's lifetime counts
var _queue: Array[StringName] = []
var _card := PanelContainer.new()
var _card_label := Label.new()
var _card_id: StringName = &""
var _card_tween: Tween

# Reports combo `id` (e.g. &"set_off") firing, from anywhere in the run's scene.
static func report(id: StringName, near: Node) -> void:
	if near == null or not near.is_inside_tree():
		return
	var feedback := near.get_tree().get_first_node_in_group(GROUP) as ComboFeedback
	if feedback != null:
		feedback.record(id)

# Discovered combo ids (from the profile; the old reactions_seen counts too).
static func load_seen() -> Array:
	var memory := HeartwoodMemory.load_data()
	var seen: Array = memory.get(SEEN_KEY, []).duplicate()
	for id in memory.get(LEGACY_KEY, []):
		if not seen.has(String(id)):
			seen.append(String(id))
	return seen

func _ready() -> void:
	add_to_group(GROUP)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_seen = load_seen()
	_card.visible = false
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_card.offset_top = 132  # Under the drift banner and the toasts
	_card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_label.custom_minimum_size = Vector2(380, 0)
	_card_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_label.add_theme_font_size_override("font_size", 16)
	_card.add_child(_card_label)
	_card.gui_input.connect(func(event: InputEvent) -> void:  # Tap: open the entry in the Codex
		if event is InputEventMouseButton and event.pressed:
			_open_in_codex(_card_id))
	add_child(_card)
	drift_director.rest_ended.connect(func(_block: int) -> void:
		block_counts.clear()
		block_longest_chain = 0
		block_new.clear())
	drift_director.rest_started.connect(func(_b: int, _boss: bool, _bonus: int, _perfect: bool) -> void: _save_counts())
	run_state.run_ended.connect(func(_won: bool) -> void: _save_counts())
	owner.child_entered_tree.connect(func(node: Node) -> void:
		if node is ReactionTracker:
			_hook(node))
	var tracker := get_tree().get_first_node_in_group(ReactionTracker.GROUP)
	if tracker != null:
		_hook(tracker)
	_connect_log.call_deferred()  # DamageLog readies later in the scene

func _connect_log() -> void:
	if DamageLog.instance != null and not DamageLog.instance.damage_dealt.is_connected(_on_damage):
		DamageLog.instance.damage_dealt.connect(_on_damage)

func _hook(tracker: ReactionTracker) -> void:
	if not tracker.reaction_fired.is_connected(_on_reaction):
		tracker.reaction_fired.connect(_on_reaction)

func _on_damage(event: DamageLog.Event) -> void:
	for tag in event.combos:
		if DAMAGE_TAGS.has(tag):
			record(tag)

func _on_reaction(id: StringName, _enemy: Node2D, chain: int, _towers: Array) -> void:
	block_counts[id] = block_counts.get(id, 0) + 1
	block_longest_chain = maxi(block_longest_chain, chain)
	record(id)

# One firing of combo `id`: counted, and discovered if it's the first time ever.
func record(id: StringName) -> void:
	run_counts[id] = run_counts.get(id, 0) + 1
	_unsaved[id] = _unsaved.get(id, 0) + 1
	if _seen.has(String(id)) or CodexData.get_any(id).is_empty():
		return
	_seen.append(String(id))
	block_new.append(id)
	_remember_discovery()
	combo_discovered.emit(id)
	_queue.append(id)
	if not _card.visible:
		_show_next()

static func discovery_text(id: StringName) -> String:
	var combo := CodexData.get_any(id)
	if combo.is_empty():
		return ""
	if combo.kind == "Crowned":  # Its own card (tower_design.md "Crowned Reactions", rule 3)
		var families: Array[String] = []
		for family in combo.families:
			families.append(CodexData.FAMILY_NAMES.get(family, family))
		return "Crowned Reaction discovered: %s\n%s  ·  %s\n%s\nAdded to the Codex." % [combo.name,
			CodexData.crowned_recipe(combo), ", ".join(families), combo.text]
	return "Combo discovered: %s\n%s\n%s\nAdded to the Codex." % [combo.name, CodexData.ingredients_text(combo), combo.text]

func _show_next() -> void:
	if _queue.is_empty():
		_card.visible = false
		return
	_card_id = _queue.pop_front()
	_card_label.text = discovery_text(_card_id)
	var reaction := Reactions.get_data(_card_id)
	_card_label.add_theme_color_override("font_color", reaction.callout_color if reaction != null else Color(0.9, 1.0, 0.8))
	_card.visible = true
	_card.reset_size()
	_card.offset_left = -_card.size.x / 2.0
	_card.offset_right = _card.size.x / 2.0
	_card.modulate.a = 0.0
	if _card_tween:
		_card_tween.kill()
	_card_tween = create_tween()
	_card_tween.tween_property(_card, "modulate:a", 1.0, 0.3)
	_card_tween.tween_interval(CARD_TIME)
	_card_tween.tween_property(_card, "modulate:a", 0.0, 0.5)
	_card_tween.tween_callback(_show_next)

func _open_in_codex(id: StringName) -> void:
	var pause := get_node_or_null("%PauseMenu")
	if pause != null and pause.has_method("open_codex"):
		pause.open_codex(&"combos", String(id))

# "Thunderclap 12 · Ignite 3" for `counts`, plus " · longest chain ×N" from 2 up ("" = none).
static func summary(counts: Dictionary, longest_chain: int) -> String:
	var ids := counts.keys()
	ids.sort_custom(func(a, b) -> bool: return counts[a] > counts[b])
	var parts: Array[String] = []
	for id in ids:
		var combo := CodexData.get_any(id)
		parts.append("%s %d" % [combo.name if not combo.is_empty() else String(id), counts[id]])
	var text := " · ".join(parts)
	if longest_chain >= 2:
		text += " · longest chain ×%d" % longest_chain
	return text

# "Damp + Static" for a Reaction (kept for callers from before the Codex).
static func pair_text(data: ReactionData) -> String:
	return CodexData.ingredients_text({"statuses": data.statuses})

func _may_write() -> bool:
	return get_tree().current_scene == owner and not MetaRun.is_dev_run()

func _remember_discovery() -> void:
	if not _may_write():
		return
	var memory := HeartwoodMemory.load_data()
	memory[SEEN_KEY] = _seen.duplicate()
	# The milestone counts the 15 combos only (Crowned Reactions aren't part of it).
	if CodexData.combos().all(func(c: Dictionary) -> bool: return _seen.has(String(c.id))):
		memory.milestones[MILESTONE] = true  # meta_design.md "Discover every combo"
	HeartwoodMemory.save_data(memory)

# Lifetime counts ("times you've set it off") go to the profile at rests and at the run's end.
func _save_counts() -> void:
	if _unsaved.is_empty() or not _may_write():
		_unsaved.clear()
		return
	var memory := HeartwoodMemory.load_data()
	var counts: Dictionary = memory.get(COUNTS_KEY, {})
	for id in _unsaved:
		counts[String(id)] = int(counts.get(String(id), 0)) + _unsaved[id]
	memory[COUNTS_KEY] = counts
	HeartwoodMemory.save_data(memory)
	_unsaved.clear()
