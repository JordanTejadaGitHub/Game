extends Node2D
class_name CardBloom

# Feeling the cards (dream_design.md 2026-10-01): when a Dream is taken, every Warden it affects pulses once in the
# card's rarity colour with the card's gem above it, staggered over about a second (DreamState.card_chosen, Roguelite
# Code: the Wardens and the impact line; the HUD toasts the line). Reduced motion: one soft highlight on all of them at
# once, no rising gem. Real time (the rest may be paused), never takes input. Made by the HUD, in the world.

const STAGGER_TOTAL := 1.0  # Seconds from the first pulse to the last
const STAGGER_MAX := 0.12  # Between two pulses at most (a few Wardens don't wait long)
const PULSE_TIME := 0.6  # UiStyle.draw_bloom runs t 0 → 1 over this
const STILL_T := 0.35  # Reduced motion: one soft highlight, held

var pulses: Array = []  # {pos (world), at (msec), colour, card}
var _still := false

func _ready() -> void:
	name = "CardBloom"
	z_index = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dreams := get_tree().get_first_node_in_group(DreamState.GROUP)
	if dreams != null and dreams.has_signal("card_chosen"):
		dreams.card_chosen.connect(func(card: UpgradeData, towers: Array, _impact: String) -> void: bloom(card, towers))

func bloom(card: UpgradeData, towers: Array) -> void:
	_still = bool(Fx.setting("reduced_motion", false))
	var live: Array = towers.filter(func(t) -> bool: return is_instance_valid(t) and t is Node2D)
	var heart := _heartwood_position()
	var now := Time.get_ticks_msec()
	if live.is_empty():
		# A rule card (screens_ui.md "Dream" ecbea61a): what it changes pulses instead: the Heartwood, and the Dew
		# counter for an economy card. No numbers anywhere.
		if heart != Vector2.INF:
			pulses.append({"pos": heart, "at": now, "colour": UiStyle.rarity_color(card.rarity), "card": card})
		var dreams := get_tree().get_first_node_in_group(DreamState.GROUP)
		if dreams != null and dreams.has_method("preview_card_impact") and dreams.preview_card_impact(card).get("kind") == &"economy":
			_pulse_counter("%DewLabel")
		queue_redraw()
		return
	if heart != Vector2.INF:  # Staggered from the Heartwood out (screens_ui.md "Dream")
		live.sort_custom(func(a: Node2D, b: Node2D) -> bool:
			return a.global_position.distance_squared_to(heart) < b.global_position.distance_squared_to(heart))
	var step := 0.0 if _still else minf(STAGGER_MAX, STAGGER_TOTAL / live.size())
	for i in live.size():
		pulses.append({"pos": (live[i] as Node2D).global_position, "at": now + roundi(i * step * 1000.0),
			"colour": UiStyle.rarity_color(card.rarity), "card": card})
	queue_redraw()

func _heartwood_position() -> Vector2:
	var heart := get_tree().root.find_child("Heartwood", true, false) as Node2D
	return heart.global_position if heart != null else Vector2.INF

# A HUD counter's once-over: a warm swell (reduced motion: the same, no scale).
func _pulse_counter(path: String) -> void:
	var counter := get_parent().get_node_or_null(path) as Control if get_parent() != null else null
	if counter == null:
		return
	counter.pivot_offset = counter.size / 2.0
	var tween := counter.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(counter, "modulate", Color(1.4, 1.3, 1.05, 1.0), 0.15)  # multiplier: the swell
	if not _still:
		tween.tween_property(counter, "scale", Vector2(1.15, 1.15), 0.15)
	tween.chain().set_parallel(true)
	tween.tween_property(counter, "modulate", Color.WHITE, 0.35)
	tween.tween_property(counter, "scale", Vector2.ONE, 0.35)

func _process(_delta: float) -> void:
	if pulses.is_empty():
		return
	var now := Time.get_ticks_msec()
	pulses = pulses.filter(func(p: Dictionary) -> bool: return now - int(p.at) < PULSE_TIME * 1000.0)
	queue_redraw()

func _draw() -> void:
	var now := Time.get_ticks_msec()
	for p in pulses:
		var t: float = (now - int(p.at)) / (PULSE_TIME * 1000.0)
		if t < 0.0:
			continue
		# UI Code's look (UiStyle.draw_bloom): the ring at the base, the gem rising. Reduced motion: held at 0.35.
		UiStyle.draw_bloom(self, to_local(p.pos), STILL_T if _still else t, p.card.rarity, UiStyle.dream_glyph(p.card))
