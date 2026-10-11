extends SceneTree
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)
func _run() -> void:
	var unlock: UnlockData = load("res://resource/meta/grove/menagerie.tres")
	var data := HeartwoodMemory.defaults()
	data.seeds = 10000
	data.unlocks["mixed_company"] = 1
	_check(GroveCardList.cards_of(unlock).is_empty(), "retired Dreams are absent from Grove reward list")
	_check(GroveCardList.load_card("menagerie") != null, "legacy card ID stays loadable")
	_check(HeartwoodMemory.buy_problem(data, unlock) == "Dreams being reworked", "retired-only node cannot consume Seeds")
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
	_check(HeartwoodMemory.requirements_met(route_data, whirlwind), "retained Whirlwind build bypasses only dormant Light Feet connector")
	print("Dream prototype Grove: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)
