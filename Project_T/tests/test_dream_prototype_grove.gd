extends SceneTree
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func _run() -> void:
	# The three retired-only nodes are gone from the tree (card_review_2026-10-12.md 11 E); their card ids stay loadable.
	for id in ["golden_harvest", "menagerie", "light_feet"]:
		_check(HeartwoodMemory.get_unlock(id) == null, "%s is no longer a Grove node" % id)
	_check(GroveCardList.load_card("menagerie") != null, "legacy card ID stays loadable")
	for node in HeartwoodMemory.load_grove():
		_check(not (node.root == UnlockData.Root.DREAMS and not node.dream_cards.is_empty() and GroveCardList.cards_of(node).is_empty()),
			"%s still gives a live card (no retired-only node left)" % node.id)
	var live: UnlockData = load("res://resource/meta/grove/bitter_hedges.tres")
	var cards := GroveCardList.cards_of(live)
	_check(cards.any(func(c: UpgradeData) -> bool: return c.id == "bitter_hedges"), "mixed node retains live Grove-exclusive card")
	_check(not cards.any(func(c: UpgradeData) -> bool: return c.retired), "mixed node omits retired companions")
	var crown_data := HeartwoodMemory.defaults()
	for node in HeartwoodMemory.load_grove():
		if not (node.root == UnlockData.Root.DREAMS and not node.dream_cards.is_empty() and GroveCardList.cards_of(node).is_empty()):
			crown_data.unlocks[node.id] = node.get_levels()
	_check(HeartwoodMemory.tree_complete(crown_data), "dormant nodes cannot block Grove completion")
	var whirlwind: UnlockData = load("res://resource/meta/grove/whirlwind_heart.tres")
	var route_data := HeartwoodMemory.defaults()
	route_data.unlocks["quickening"] = 1
	_check(HeartwoodMemory.requirements_met(route_data, whirlwind), "Whirlwind Heart grows off Quickening (Light Feet is gone)")
	print("Dream prototype Grove: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)
