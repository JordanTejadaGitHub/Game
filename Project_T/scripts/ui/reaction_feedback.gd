extends Control
class_name ReactionFeedback

# Reactions in the HUD (screens_ui.md "Reactions"; the callouts and effects are Fx's): counts per
# block for the rest report, and the discovery card the first time a Reaction ever fires
# ("Reaction discovered: Thunderclap. Damp + Static."), remembered in the profile's
# `reactions_seen` (real game only, never tests or developer runs), which fills the Codex.
# ReactionTracker only exists once the first Reaction fires, so this waits for it to join the run.

const CARD_TIME := 4.0
const SETTING := "reactions_seen"

@onready var drift_director: DriftDirector = %DriftDirector

var block_counts := {}  # Reaction id -> times this block
var block_longest_chain := 0
var _seen: Array = []
var _card := PanelContainer.new()
var _card_label := Label.new()
var _card_tween: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_seen = HeartwoodMemory.load_data().get(SETTING, []).duplicate()
	_card.visible = false
	_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_label.custom_minimum_size = Vector2(300, 0)
	_card_label.add_theme_font_size_override("font_size", 16)
	_card.add_child(_card_label)
	_card.gui_input.connect(func(event: InputEvent) -> void:  # Tap to dismiss
		if event is InputEventMouseButton and event.pressed:
			_card.visible = false)
	add_child(_card)
	drift_director.rest_ended.connect(func(_block: int) -> void:
		block_counts.clear()
		block_longest_chain = 0)
	owner.child_entered_tree.connect(_on_child_entered)
	var tracker := get_tree().get_first_node_in_group(ReactionTracker.GROUP)
	if tracker != null:
		_hook(tracker)

func _on_child_entered(node: Node) -> void:
	if node is ReactionTracker:
		_hook(node)

func _hook(tracker: ReactionTracker) -> void:
	if not tracker.reaction_fired.is_connected(_on_reaction):
		tracker.reaction_fired.connect(_on_reaction)

func _on_reaction(id: StringName, _enemy: Node2D, chain: int, _towers: Array) -> void:
	block_counts[id] = block_counts.get(id, 0) + 1
	block_longest_chain = maxi(block_longest_chain, chain)
	if not _seen.has(String(id)):
		_seen.append(String(id))
		_remember()
		show_discovery(id)

static func discovery_text(id: StringName) -> String:
	var data := Reactions.get_data(id)
	if data == null:
		return ""
	return "Reaction discovered: %s\n%s\n%s" % [data.display_name, pair_text(data), data.description]

# "Damp + Static": the two statuses that make it.
static func pair_text(data: ReactionData) -> String:
	var names: Array[String] = []
	for status in data.statuses:
		names.append(String(status).capitalize())
	return " + ".join(names)

func show_discovery(id: StringName) -> void:
	var data := Reactions.get_data(id)
	if data == null:
		return
	_card_label.text = discovery_text(id)
	_card_label.add_theme_color_override("font_color", data.callout_color)
	_card.visible = true
	_card.position = Vector2(16, size.y * 0.3)
	_card.modulate.a = 0.0
	if _card_tween:
		_card_tween.kill()
	_card_tween = create_tween()
	_card_tween.tween_property(_card, "modulate:a", 1.0, 0.3)
	_card_tween.tween_interval(CARD_TIME)
	_card_tween.tween_property(_card, "modulate:a", 0.0, 0.6)
	_card_tween.tween_callback(func() -> void: _card.visible = false)

# "Thunderclap 12 · Ignite 3" for `counts`, plus " · longest chain ×N" from 2 up ("" = none).
static func summary(counts: Dictionary, longest_chain: int) -> String:
	var ids := counts.keys()
	ids.sort_custom(func(a, b) -> bool: return counts[a] > counts[b])
	var parts: Array[String] = []
	for id in ids:
		var data := Reactions.get_data(id)
		parts.append("%s %d" % [data.display_name if data != null else String(id), counts[id]])
	var text := " · ".join(parts)
	if longest_chain >= 2:
		text += " · longest chain ×%d" % longest_chain
	return text

func _remember() -> void:
	if get_tree().current_scene != owner or MetaRun.is_dev_run():
		return
	var memory := HeartwoodMemory.load_data()
	memory[SETTING] = _seen
	HeartwoodMemory.save_data(memory)
