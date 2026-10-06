extends SceneTree

# Family picks offer only real new families (meta_design.md "Replaced 2026-09-30"): no Blessing
# filler; with none left, a boss pick is skipped for +2 Dreamlight. A fresh profile that picked
# Sporeling first sees the rest one by one (the starting four since 2026-10-01: 2 a pick, then 1, then none).

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_family_pick_rule_%d.json" % OS.get_process_id()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var family = main.get_node("%FamilyPickScreen")
	var dreams: DreamState = main.get_node("%DreamState")
	family.show_pick(&"first")
	_check(family.offer.size() == mini(family.families.size(), family.cards_per_pick) and family.offer.all(func(o) -> bool: return o is TowerData),
		"the first pick offers the starting families (%s)" % [family._ids(family.offer)])
	_check(family.arm != null and not family.arm.is_armed() and family.arm.visible,
		"the cards arm first: a press in the first moment can't pick (ChoiceArm)")
	var first = family.offer[0]  # Any of them: the first pick is 3 random of the 4 starting families (Sporeling may not be there)
	family.choose(first)
	await process_frame
	var left: int = family.families.size() - 1  # Starting families not picked yet
	while left > 0:
		var expected := mini(left, family.cards_per_pick)
		left -= 1
		family.show_pick(&"boss")
		_check(family.offer.size() == expected and family.offer.all(func(o) -> bool: return o is TowerData),
			"a boss pick shows only the %d new famil%s left, no Blessings (%s)" % [expected, "y" if expected == 1 else "ies", family._ids(family.offer)])
		if not family.offer.is_empty():
			family.choose(family.offer[0])
		await process_frame
	var before := dreams.dreamlight
	family.show_pick(&"boss")
	_check(family.offer.is_empty() and not family.visible, "with no new family left the boss pick is skipped")
	_check(dreams.dreamlight == before + 2, "…for +2 Dreamlight (%d -> %d)" % [before, dreams.dreamlight])

	# Picks show 2, 3 with Wider Choice, and never only support families (user 2026-10-06, meta_design.md e0c02e54).
	var fps = family.get_script()  # No class_name: the statics through the script
	var acorn: TowerData = load("res://resource/tower/acorn.tres")
	var pebbling: TowerData = load("res://resource/tower/pebbling.tres")
	var rootling: TowerData = load("res://resource/tower/rootling.tres")
	_check(family.cards_per_pick == 2 and family.pick_count() == 2, "a pick shows 2 families")
	fps.force_wider_choice = true
	_check(family.pick_count() == 3, "Wider Choice: 3")
	family.families.assign([acorn, pebbling, rootling])
	family.show_pick(&"boss")
	_check(family.offer.size() == 3, "Wider Choice shows 3 when 3 are left (%s)" % [family._ids(family.offer)])
	fps.force_wider_choice = false
	family.visible = false
	var only_support := 0
	for i in 40:
		var pool: Array = [acorn, pebbling, rootling]
		pool.shuffle()
		fps._keep_an_attacker(pool, 1)
		if fps.is_support_family(pool[0]):
			only_support += 1
	_check(only_support == 0 and fps.is_support_family(acorn) and not fps.is_support_family(pebbling),
		"a pick never holds only support families (Acorn alone in 1 slot: %d of 40)" % only_support)
	var lone: Array = [acorn]
	fps._keep_an_attacker(lone, 2)
	_check(lone == [acorn], "with only a support family left, it's still shown")
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("family pick rule test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
