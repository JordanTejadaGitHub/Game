extends Control
class_name ComboFeedback

# Combos in play (screens_ui.md "The Codex: Glossary and Combos"): the 7 synergies and the 8
# Reactions (CodexData.combos()). Discovered the first time each one fires, ever: the game pauses on
# the moment (the nightmare ringed) with a card near the top ("Combo discovered: Thunderclap",
# ingredients, one line, "Added to the Codex"; Continue / Open in Codex); several queue behind one
# pause, and it waits while a choice screen or the pause menu is open. With the Gameplay setting
# "Pause on new combos" off, the old 5 s slide-in card instead. Saved in the profile
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
var _crown_corners := Control.new()  # Gold corners, shown on Crowned discovery cards
var _buttons := HBoxContainer.new()  # Continue / Open in Codex (pausing cards)
var _pausing := false  # A pausing discovery is holding the game
var _was_paused := false  # Whether the game was paused before it
var _enemies := {}  # Combo id -> the nightmare it was discovered on (for the ring)
var _ring: Node2D = null

const PAUSE_SETTING := "pause_on_combo"

const CROWN_ACCENT := preload("res://assets/effects/crowned_card_accent.png")

# Reports combo `id` (e.g. &"set_off") firing, from anywhere in the run's scene; pass the nightmare
# it happened on, if known, so a first discovery can ring it.
static func report(id: StringName, near: Node, enemy: Node2D = null) -> void:
	if near == null or not near.is_inside_tree():
		return
	var feedback := near.get_tree().get_first_node_in_group(GROUP) as ComboFeedback
	if feedback != null:
		feedback.record(id, enemy)

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
	var card_box := VBoxContainer.new()
	card_box.add_theme_constant_override("separation", 10)
	_card.add_child(card_box)
	card_box.add_child(_card_label)
	# Pausing cards: Continue (also Space / Enter / a tap on the card) and Open in Codex.
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 12)
	card_box.add_child(_buttons)
	for pair in [["Continue", continue_on], ["Open in Codex", _continue_to_codex]]:
		var button := Button.new()
		button.text = pair[0]
		button.focus_mode = Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(150, 48)
		button.pressed.connect(pair[1])
		_buttons.add_child(button)
	# Crowned Reactions get gold corners (effects.json crowned_card_accent: the top-left corner,
	# mirrored for the others).
	_crown_corners.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(_crown_corners)
	for corner in [[Control.PRESET_TOP_LEFT, false, false], [Control.PRESET_TOP_RIGHT, true, false],
			[Control.PRESET_BOTTOM_LEFT, false, true], [Control.PRESET_BOTTOM_RIGHT, true, true]]:
		var piece := TextureRect.new()
		piece.texture = CROWN_ACCENT
		piece.flip_h = corner[1]
		piece.flip_v = corner[2]
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		piece.set_anchors_and_offsets_preset(corner[0], Control.PRESET_MODE_MINSIZE)
		_crown_corners.add_child(piece)
	_card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if _pausing:
				continue_on()  # A tap on a pausing card continues
			else:
				_open_in_codex(_card_id))  # A tap on the slide-in card opens its entry
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
			record(tag, event.enemy)

func _on_reaction(id: StringName, enemy: Node2D, chain: int, _towers: Array) -> void:
	block_counts[id] = block_counts.get(id, 0) + 1
	block_longest_chain = maxi(block_longest_chain, chain)
	record(id, enemy)

# One firing of combo `id` (on `enemy`, if known): counted, and discovered if it's the first time ever.
func record(id: StringName, enemy: Node2D = null) -> void:
	run_counts[id] = run_counts.get(id, 0) + 1
	_unsaved[id] = _unsaved.get(id, 0) + 1
	if _seen.has(String(id)) or CodexData.get_any(id).is_empty():
		return
	_seen.append(String(id))
	block_new.append(id)
	_remember_discovery()
	combo_discovered.emit(id)
	_queue.append(id)
	_enemies[id] = enemy
	if not _card.visible:
		_try_show()

# --- Pausing discoveries (screens_ui.md "Combos (discovered in play)") -----------------------------
# A discovery freezes the world on the moment (the nightmare ringed), with the card near the top and
# the map visible. Continue resumes at the previous speed (already paused stays paused); several
# queue behind one pause. While a choice screen or the pause menu is open, it waits. The Gameplay
# setting "Pause on new combos" (pause_on_combo, default on) off = the old 5 s slide-in card.

# Headless test scripts never pause on a discovery (a drift would stall mid-test) unless a test
# turns it on with `pause_in_tests`.
static var pause_in_tests := false

static func pause_setting() -> bool:
	if OS.get_cmdline_args().has("--script"):
		return pause_in_tests
	return bool(HeartwoodMemory.get_settings().get(PAUSE_SETTING, true))

func _try_show() -> void:
	if _queue.is_empty() or _card.visible:
		return
	if pause_setting() and _blocked():
		return  # _process tries again once the screen closes
	_show_next()

# A choice screen, the pause menu or the results are up: the discovery waits.
func _blocked() -> bool:
	for path in ["%PauseMenu", "%FamilyPickScreen", "%RememberScreen", "%ResultsScreen"]:
		var node := get_node_or_null(path) as Control
		if node != null and node.visible:
			return true
	var dreams = get_node_or_null("%DreamState")
	if dreams != null and dreams.is_offering():
		return true
	var omens := get_tree().get_first_node_in_group(&"omens")
	return omens != null and omens.has_method("is_offering") and omens.is_offering()

func _process(_delta: float) -> void:
	if not _queue.is_empty() and not _card.visible:
		_try_show()

func _unhandled_input(event: InputEvent) -> void:
	if not (_card.visible and _pausing):
		return
	if event.is_action_pressed("pause_game") or event.is_action_pressed("start_drift") or event.is_action_pressed("ui_accept"):
		continue_on()
		get_viewport().set_input_as_handled()

# Continue: the next queued discovery, or the end of the pause (back to the previous speed).
func continue_on() -> void:
	_clear_highlight()
	if not _queue.is_empty():
		_show_next()
		return
	_card.visible = false
	if _pausing:
		_pausing = false
		var speed = get_node_or_null("%GameSpeed")
		if speed != null:
			speed.set_paused(_was_paused)

func _continue_to_codex() -> void:
	var id := _card_id
	_queue.clear()  # Straight to the book; the rest are in it too
	continue_on()
	_open_in_codex(id)

func _highlight(enemy: Node2D) -> void:
	_clear_highlight()
	if is_instance_valid(enemy) and enemy.is_inside_tree():
		_ring = ComboRing.new()
		enemy.add_child(_ring)

func _clear_highlight() -> void:
	if is_instance_valid(_ring):
		_ring.queue_free()
	_ring = null

# A pulsing ring round the nightmare a combo was discovered on (runs while the tree is paused).
class ComboRing extends Node2D:
	var _time := 0.0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		z_index = 20

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(_time * 4.0)
		draw_arc(Vector2.ZERO, 26.0 + pulse * 4.0, 0.0, TAU, 40, Color(1.0, 0.95, 0.6, 0.9), 3.0, true)
		draw_arc(Vector2.ZERO, 36.0 + pulse * 6.0, 0.0, TAU, 40, Color(1.0, 0.95, 0.6, 0.35 * (1.0 - pulse)), 2.0, true)

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
	_crown_corners.visible = CodexData.CROWNED.has(_card_id)
	var pausing := pause_setting()
	_buttons.visible = pausing
	if pausing and not _pausing:  # The first of a queue freezes the world; the last Continue thaws it
		_pausing = true
		var speed = get_node_or_null("%GameSpeed")
		if speed != null:
			_was_paused = speed.paused
			speed.set_paused(true)
	if pausing:
		_highlight(_enemies.get(_card_id))
	_enemies.erase(_card_id)
	_card.visible = true
	_card.reset_size()
	_card.offset_left = -_card.size.x / 2.0
	_card.offset_right = _card.size.x / 2.0
	_card.modulate.a = 0.0
	if _card_tween:
		_card_tween.kill()
	_card_tween = create_tween()
	_card_tween.tween_property(_card, "modulate:a", 1.0, 0.3)
	if pausing:
		return  # Stays until Continue
	_card_tween.tween_interval(CARD_TIME)  # Setting off: the old slide-in card, for 5 s
	_card_tween.tween_property(_card, "modulate:a", 0.0, 0.5)
	_card_tween.tween_callback(_show_next)

func _open_in_codex(id: StringName) -> void:
	var pause := get_node_or_null("%PauseMenu")
	if pause != null and pause.has_method("open_codex"):
		pause.open_codex(&"combos", String(id))

# "Thunderclap 12 · Ignite 3" for `counts`, plus " · longest chain: N" from 2 up ("" = none). Chains
# always read as a count ("Chain 10"), never "×10", which looks like a damage multiplier.
static func summary(counts: Dictionary, longest_chain: int) -> String:
	var ids := counts.keys()
	ids.sort_custom(func(a, b) -> bool: return counts[a] > counts[b])
	var parts: Array[String] = []
	for id in ids:
		var combo := CodexData.get_any(id)
		parts.append("%s %d" % [combo.name if not combo.is_empty() else String(id), counts[id]])
	var text := " · ".join(parts)
	if longest_chain >= 2:
		text += " · longest chain: %d" % longest_chain
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
