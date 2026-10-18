extends Node2D
class_name CardBadgePops

# A card fired on a Warden (visual_feedback_spec.md B5, owner 2026-10-18): on DreamState.card_badge_pop (Roguelite
# 451495cb, already throttled to once per card per Warden every 4 s) that card's rarity gem with its glyph pops above
# the Warden, x1.3 to x1 over 0.5 s, then fades. Here: at most 4 alive (1 on Reduced effects), never while the card
# badges already show (build mode, a selection), and only with "Dream effects on attacks: Full" (dream_effects 0;
# Subtle and Off show none). It sits under the gold name callout (CombatCallouts, z 21). Made by the HUD (world).

const LIFE := 0.5
const START_SCALE := 1.3  # 1.0 under reduced motion
const MAX_ALIVE := 4
const REDUCED_MAX_ALIVE := 1
const LIFT := Vector2(0, -58)  # Above the Warden's head
const RADIUS := 9.0
const SETTING := "dream_effects"  # 0 full, 1 subtle, 2 off (Tower Code's setting)

var _dreams: Node = null

func _ready() -> void:
	z_index = 20  # Over the Wardens, under the callouts
	set_process(false)
	_connect.call_deferred()

func _connect() -> void:
	_dreams = get_tree().get_first_node_in_group(DreamState.GROUP)
	if _dreams != null and _dreams.has_signal("card_badge_pop"):
		_dreams.card_badge_pop.connect(_on_badge_pop)

func _on_badge_pop(id: StringName, source: Node) -> void:
	var tower := source as Tower
	if tower == null or not is_instance_valid(tower) or not tower.is_inside_tree() or Tower.badges_visible():
		return
	if int(Fx.setting(SETTING, 0)) != 0 or get_child_count() >= (REDUCED_MAX_ALIVE if Fx.reduced() else MAX_ALIVE):
		return
	var card: UpgradeData = _dreams.call("_card_by_id", String(id)) if _dreams.has_method("_card_by_id") else null
	var rarity := card.rarity if card != null else 0  # A Calling evolution has no card: the Common gem
	var glyph := UiStyle.dream_glyph(card) if card != null else &""
	var pop := Node2D.new()
	pop.global_position = tower.global_position + LIFT
	pop.set_meta(&"age", 0.0)
	pop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pop.draw.connect(func() -> void: UiStyle.draw_gem(pop, Vector2.ZERO, RADIUS, rarity, glyph))
	add_child(pop)
	_place(pop, 0.0)
	set_process(true)

func _process(delta: float) -> void:
	for pop in get_children():
		var age: float = float(pop.get_meta(&"age", 0.0)) + delta
		if age >= LIFE:
			pop.queue_free()
			continue
		pop.set_meta(&"age", age)
		_place(pop, age / LIFE)
	if get_child_count() == 0:
		set_process(false)

# Scale (screen-sized like the world labels) and fade at `t` (0..1) of its life.
func _place(pop: Node2D, t: float) -> void:
	var start := 1.0 if bool(Fx.setting("reduced_motion", false)) else START_SCALE
	var grow := lerpf(start, 1.0, clampf(t * 2.0, 0.0, 1.0))  # Settles in the first half
	pop.scale = Vector2.ONE * grow * WorldLabel.text_scale(pop)
	pop.modulate.a = 1.0 if t < 0.6 else lerpf(1.0, 0.0, (t - 0.6) / 0.4)  # multiplier
