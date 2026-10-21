extends Node2D
class_name LegendaryCrests

# A Legendary held shows on the map all run (owner 2026-10-21, dream_council_review.md 28: Legendaries "should feel like a
# new build by itself"): one crest per Legendary card held, a Legendary gem with the card's glyph (UiStyle.draw_gem), in a
# small arc over the Heartwood. Always visible, nothing to hover; a new one grows in (reduced motion: it just appears).
# Made by the HUD (world). Reads DreamState.get_taken_cards() on a pick and when a saved run resumes.

const RADIUS := 8.0  # World px per gem
const LIFT := 92.0  # Above the Heartwood's cell centre, over its canopy
const SPACING := 22.0
const ARC := 6.0  # The ends of the row sit this much lower
const GROW_TIME := 0.5

var _cards: Array[UpgradeData] = []
var _born := {}  # Card id -> the msec its crest appeared (the grow)
var _dreams: Node = null
var _heart: Node2D = null
var _first := true  # The first refresh (a new or resumed run) shows held crests without the grow

func _ready() -> void:
	z_index = 7  # Over the Heartwood, its light and the edge fog
	set_process(false)
	_connect.call_deferred()

func _connect() -> void:
	_dreams = get_tree().get_first_node_in_group(DreamState.GROUP)
	var map := get_parent().get_node_or_null("%MapGenerator") if get_parent() != null else null  # The run's scene root
	if map == null:
		map = get_tree().root.find_child("MapGenerator", true, false)
	_heart = map.get("heartwood") as Node2D if map != null else null
	if _dreams != null and _dreams.has_signal("card_taken"):
		_dreams.card_taken.connect(func(_card: UpgradeData) -> void: refresh.call_deferred())
	refresh()

func refresh() -> void:
	if _dreams == null or not _dreams.has_method("get_taken_cards"):
		return
	var held: Array[UpgradeData] = []
	for card: UpgradeData in _dreams.get_taken_cards():
		if card != null and card.rarity == UpgradeData.Rarity.LEGENDARY and not held.has(card):
			held.append(card)
	var still := bool(Fx.setting("reduced_motion", false))
	for card in held:
		if not _born.has(card.id):
			_born[card.id] = -1000000 if still or _first else Time.get_ticks_msec()  # A resumed run: already there
	_first = false
	_cards = held
	set_process(not still and not _cards.is_empty())
	queue_redraw()

func _process(_delta: float) -> void:
	var growing := false
	for card in _cards:
		growing = growing or Time.get_ticks_msec() - int(_born.get(card.id, 0)) < int(GROW_TIME * 1000.0)
	queue_redraw()
	if not growing:
		set_process(false)

func _draw() -> void:
	if _cards.is_empty() or not is_instance_valid(_heart):
		return
	var centre := to_local(_heart.global_position) + Vector2(0, -LIFT)
	var n := _cards.size()
	for i in n:
		var card := _cards[i]
		var t := float(i) - (n - 1) / 2.0  # -… 0 …+
		var at := centre + Vector2(t * SPACING, absf(t) * ARC)
		var grow := clampf(float(Time.get_ticks_msec() - int(_born.get(card.id, 0))) / (GROW_TIME * 1000.0), 0.0, 1.0)
		if grow <= 0.0:
			continue
		var s := ease(grow, 0.4)
		draw_set_transform(at, 0.0, Vector2(s, s))
		draw_circle(Vector2.ZERO, RADIUS + 5.0, Color(Palette.GLOW, 0.18))  # A soft warm halo
		UiStyle.draw_gem(self, Vector2.ZERO, RADIUS, card.rarity, UiStyle.dream_glyph(card))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
