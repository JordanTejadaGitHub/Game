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
	if live.is_empty():
		return  # Affects nothing yet: the card just goes to the row
	var step := 0.0 if _still else minf(STAGGER_MAX, STAGGER_TOTAL / live.size())
	var now := Time.get_ticks_msec()
	for i in live.size():
		pulses.append({"pos": (live[i] as Node2D).global_position, "at": now + roundi(i * step * 1000.0),
			"colour": UiStyle.rarity_color(card.rarity), "card": card})
	queue_redraw()

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
