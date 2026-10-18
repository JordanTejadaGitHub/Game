extends SceneTree
# Visual feedback spec (owner 2026-10-18; D:\Projects\logs\dream_council\visual_feedback_spec.md B1 / B5 / C): the card ->
# cue table covers every live card, its cue ids are the spec's 10, the boost tier steps at +20% / +60% / +150%, and
# note_card with a source Warden carries it through card_fired, card_cue and the throttled card_badge_pop.
# Never touches the player's saves: main.tscn is added under root by hand (not the current scene).
const CUES := preload("res://scripts/run/card_cues.gd")
const VISUALS := preload("res://scripts/run/dream_visuals.gd")
const CELL := 64.0

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _run() -> void:
	_check_table()
	_check_tiers()
	_check_note_card()
	await _check_boost_tier()
	print("test_card_cues: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(failures)

# Every live card: in CUES, an unlock card, or listed as needing no field cue. Every cue id is one of the 10.
func _check_table() -> void:
	_check(CUES.CUE_IDS.size() == 10, "10 shared cues (spec C1)")
	var live := {}
	var dir := DirAccess.open("res://resource/dream/")
	for file in dir.get_files():
		if not file.ends_with(".tres"):
			continue
		var card: UpgradeData = load("res://resource/dream/" + file.trim_suffix(".remap")) as UpgradeData
		if card == null or card.retired:
			continue
		live[StringName(card.id)] = true
		if card.unlocks != null:
			continue  # Unlock cards show as the new Warden and its grow button
		var id := StringName(card.id)
		_check(CUES.CUES.has(id) or CUES.needs_no_cue(id), "%s has a cue or is listed as needing none" % card.id)
		_check(not (CUES.CUES.has(id) and CUES.needs_no_cue(id)), "%s is not both cued and cue-free" % card.id)
	_check(live.size() > 300, "the live cards were read (%d)" % live.size())
	for id in CUES.CUES:
		_check(live.has(id), "CUES names a live card: %s" % id)
		_check(CUES.CUE_IDS.has(CUES.CUES[id]), "%s's cue is a valid id" % id)
	for id in CUES.EXTRA_CUES:
		_check(live.has(id), "EXTRA_CUES names a live card: %s" % id)
		for cue in CUES.EXTRA_CUES[id]:
			_check(CUES.CUE_IDS.has(cue), "%s's extra cue is a valid id" % id)
	for list in [CUES.NATURAL, CUES.OFFER_ONLY, CUES.LINGER]:
		for id in list:
			_check(live.has(id), "a cue list names a live card: %s" % id)
	for id in CUES.LINGER:
		_check(CUES.cues_for(id).has(CUES.STATUS_POP), "%s (linger) shows the status pop" % id)
	_check(CUES.cue_for(&"first_light") == CUES.DREAM_FLECK and CUES.cue_for(&"great_ripple") == &"", "cue_for")
	_check(CUES.cue_for(&"last_light") == CUES.DREAM_GLOW, "a rule id alias finds its card's cue")

func _check_tiers() -> void:
	var rows := [[0.0, 0], [0.19, 0], [0.20, 1], [0.59, 1], [0.60, 2], [1.49, 2], [1.50, 3], [6.0, 3], [-0.5, 0]]
	for row in rows:
		_check(VISUALS.tier_for_power(row[0]) == row[1], "power %.2f -> tier %d (got %d)" % [row[0], row[1],
			VISUALS.tier_for_power(row[0])])
	_check(VISUALS.tier_with(1, true, false) == 2, "a surge raises the tier by 1")
	_check(VISUALS.tier_with(3, true, false) == 3, "never past tier 3")
	_check(VISUALS.tier_with(0, false, true) == 3, "a hit past the card line shows tier 3")
	_check(VISUALS.tier_with(3, true, true, true) == 1, "Sprouts: tier 1 at most")

func _check_note_card() -> void:
	var dreams := DreamState.new()
	var tower := Tower.new()
	var fired: Array = []
	var cues: Array = []
	var pops: Array = []
	dreams.card_fired.connect(func(id: StringName, at: Vector2, source: Node) -> void: fired.append([id, at, source]))
	dreams.card_cue.connect(func(id: StringName, cue: StringName, at: Vector2, source: Node) -> void: cues.append([id, cue, source]))
	dreams.card_badge_pop.connect(func(id: StringName, source: Node) -> void: pops.append([id, source]))
	dreams.note_card(&"first_light", Vector2(3, 4), 1, tower)
	_check(fired.size() == 1 and fired[0][2] == tower and fired[0][1] == Vector2(3, 4), "card_fired carries the source")
	_check(cues.size() == 1 and cues[0][1] == CUES.DREAM_FLECK and cues[0][2] == tower, "card_cue: First Light's fleck")
	_check(pops.size() == 1 and pops[0][1] == tower, "the badge pops on the Warden")
	dreams.note_card(&"first_light", Vector2.INF, 1, tower)
	_check(pops.size() == 1, "no second pop within 4 s")
	dreams._game_clock += VISUALS.BADGE_POP_EVERY + 0.1
	dreams.note_card(&"first_light", Vector2.INF, 1, tower)
	_check(pops.size() == 2, "pops again after 4 s")
	dreams.note_card(&"thousand_cuts", Vector2.INF)
	_check(fired[-1][2] == null, "no source: null (old callers)")
	_check(cues.size() == 5 and cues[-2][1] == CUES.DREAM_FLECK and cues[-1][1] == CUES.STATUS_POP, "a main cue then its extra")
	_check(pops.size() == 2, "no source: no pop")
	dreams.note_card(&"great_ripple", Vector2.INF, 1, tower)
	_check(cues.size() == 5, "a card that shows by nature has no cue")
	_check(int(dreams.card_counts_run.get(&"first_light", 0)) == 3, "the counts still add up")
	tower.free()
	dreams.free()

func _check_boost_tier() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var dreams: DreamState = main.get_node("%DreamState")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var container: Node = main.get_node("%TowerContainer")
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/sporeling.tres")
	tower.cell = Vector2(3, 3)
	tower.position = Vector2(3.5, 3.5) * CELL
	container.add_child(tower)
	tower.set_process(false)
	var tiers := [[0.10, 0], [0.30, 1], [0.70, 2], [1.60, 3]]
	var base := dreams.dream_power(tower)
	_check(absf(base) < 0.0001 and dreams.boost_tier(tower) == 0, "no cards: tier 0 (power %.3f)" % base)
	for row in tiers:
		await _power_card(dreams, row[0])
		_check(absf(dreams.dream_power(tower) - row[0]) < 0.0001, "power follows the card: %.2f (got %.3f)" % [row[0],
			dreams.dream_power(tower)])
		_check(dreams.boost_tier(tower) == row[1], "+%d%% -> tier %d (got %d)" % [roundi(row[0] * 100), row[1],
			dreams.boost_tier(tower)])
	await _power_card(dreams, 0.30)
	dreams.note_surge(tower, 2.0)
	_check(dreams.boost_tier(tower) == 2, "a timed card: tier +1 while on")
	dreams._game_clock += 2.5
	_check(dreams.boost_tier(tower) == 1, "…and off after")
	dreams.visuals.note_past_cap(dreams, tower)
	_check(dreams.boost_tier(tower) == 3, "a hit past the card line: tier 3")
	var sprout: Tower = placer.tower_scene.instantiate()
	sprout.tower_data = load("res://resource/tower/sprout.tres")
	sprout.cell = Vector2(5, 3)
	sprout.position = Vector2(5.5, 3.5) * CELL
	container.add_child(sprout)
	sprout.set_process(false)
	await _power_card(dreams, 1.60)
	_check(dreams.boost_tier(sprout) <= 1, "a Sprout shows tier 1 at most")
	_check(dreams.boost_tier(null) == 0, "no Warden: tier 0")
	main.queue_free()
	await process_frame

# A stat card giving every Warden `soothe` (a fresh card each time: the stat sums are cached per card set).
var _power_cards := 0

func _power_card(dreams: DreamState, soothe: float) -> void:
	dreams.stacks.erase("test_card_cues_power_%d" % _power_cards)
	_power_cards += 1
	var card := UpgradeData.new()
	card.id = "test_card_cues_power_%d" % _power_cards
	card.soothe_bonus = soothe
	dreams.pool.append(card)
	dreams.stacks[card.id] = 1
	dreams.bump_board()
	await process_frame
