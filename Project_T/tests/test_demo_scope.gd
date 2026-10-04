extends SceneTree

# Headless test for the demo's Warden scope (demo_scope.md "Wardens", 838c091): a demo run (not a
# dev run) only ever meets Sporeling, Firefly Jar and Dewdrop (+ Sprout, Thornwall): family picks,
# Dream cards, the Remember screen and the Codex's combos / Kinships. The dev toggle (Unlock all
# families) still shows everything.
#   godot --headless --path . --script res://tests/test_demo_scope.gd --fixed-fps 60

const OTHER_FAMILIES := ["bellflower", "pebbling", "rootling", "acorn", "nestling", "whirligig"]

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	ResultsScreen.demo_override = 1
	MetaRun.force_all_families = false
	TestGrove.force_on = false
	_check(CodexData.demo_limited(), "a demo run, not a dev run")
	_check(NightmareIcons.in_build("spore") and not NightmareIcons.in_build("stone"), "demo nightmare icons show only the demo families' resistances")

	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var family = main.get_node("%FamilyPickScreen")
	var dreams: DreamState = main.get_node("%DreamState")
	var demo_wardens := _tree_ids(CodexData.DEMO_FAMILIES)
	var other_wardens := _tree_ids(OTHER_FAMILIES)

	# Family picks: the drift 1 pick offers the three, nothing else is ever pickable.
	var ids: Array = family.families.map(func(d: TowerData) -> String: return d.get_id())
	ids.sort()
	var expected := CodexData.DEMO_FAMILIES.duplicate()
	expected.sort()
	_check(ids == expected, "the demo's family roster is the three (%s)" % str(ids))
	family.show_pick(&"first")
	var offered: Array = family.offer.filter(func(d) -> bool: return d is TowerData).map(func(d: TowerData) -> String: return d.get_id())
	_check(offered.size() == 3 and offered.all(func(id: String) -> bool: return CodexData.DEMO_FAMILIES.has(id)),
		"the drift 1 pick offers the three (%s)" % str(offered))
	family.visible = false

	# Own every demo Warden (all three trees), then no Dream card can lead to another family.
	for id in demo_wardens:
		dreams.unlocked[id] = true
	var leaks: Array[String] = []
	for card in dreams.pool:
		if not dreams.can_offer(card, 4):
			continue
		var needs: Array = Array(card.requires) + Array(card.requires_any)
		if needs.any(func(id: String) -> bool: return other_wardens.has(id)):
			leaks.append(card.id)
	_check(leaks.is_empty(), "no offerable Dream card needs another family (%s)" % str(leaks))
	for i in 30:
		for card in dreams.make_offer(60):
			var needs: Array = Array(card.requires) + Array(card.requires_any)
			if needs.any(func(id: String) -> bool: return other_wardens.has(id)) and not leaks.has(card.id):
				leaks.append(card.id)
	_check(leaks.is_empty(), "30 offers at drift 60 never show another family's card (%s)" % str(leaks))

	# Remember: only the demo trees (and Thornwall's walls).
	var roots: Array = dreams.get_remember_trees().map(func(tree: Array) -> String: return tree[0].get_id())
	_check(roots.all(func(id: String) -> bool: return demo_wardens.has(id) or id == "thornwall"),
		"the Remember screen shows only demo families (%s)" % str(roots))

	# Codex: combos and Kinships the demo can't make aren't listed.
	var codex := CodexPanel.new()
	root.add_child(codex)
	codex.open(&"combos")
	for id in ["marked_blow"]:  # Pebbling's (set_off and caught are Bellflower's: a starting family since 2026-10-01)
		_check(not codex._entries.has(id), "the demo Codex leaves out %s (another family's combo)" % id)
	for id in ["set_off", "caught"]:
		_check(codex._entries.has(id), "the demo Codex lists %s (Bellflower's combo)" % id)
	_check(codex._entries.has("conducted") and codex._entries.has("thunderclap"), "…and keeps the demo's own combos")
	var kin_listed := CodexData.kinships().filter(func(k: Dictionary) -> bool: return codex._entries.has(String(k.id)))
	_check(kin_listed.all(func(k: Dictionary) -> bool: return Kinships.is_available(k.id)) and kin_listed.size() < CodexData.kinships().size(),
		"only the demo's Kinships (%d listed)" % kin_listed.size())
	codex.queue_free()
	main.queue_free()
	await process_frame
	await process_frame

	# The dev toggle still shows everything.
	MetaRun.force_all_families = true
	_check(not CodexData.demo_limited(), "Unlock all families isn't demo-limited")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	family = main.get_node("%FamilyPickScreen")
	_check(family.families.size() > 3, "Unlock all families adds the other families to the picks (%d)" % family.families.size())
	codex = CodexPanel.new()
	root.add_child(codex)
	codex.open(&"combos")
	_check(codex._entries.has("set_off") and codex._entries.has("marked_blow"), "the dev Codex lists every combo")
	codex.queue_free()
	main.queue_free()
	MetaRun.force_all_families = false
	ResultsScreen.demo_override = -1
	await process_frame
	print("demo scope test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# Every Warden id in the trees of these families (base, branches, finals, Ascended).
func _tree_ids(families: Array) -> Array:
	var ids: Array = []
	var todo: Array = families.map(func(id: String) -> Resource: return load(CodexData.TOWER_DIR + id + ".tres"))
	while not todo.is_empty():
		var data := todo.pop_back() as TowerData
		if data == null or ids.has(data.get_id()):
			continue
		ids.append(data.get_id())
		todo.append_array(data.evolves_to)
	return ids

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
