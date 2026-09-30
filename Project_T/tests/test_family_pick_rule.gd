extends SceneTree

# Family picks offer only real new families (meta_design.md "Replaced 2026-09-30"): no Blessing
# filler; with none left, a boss pick is skipped for +2 Dreamlight. A fresh profile that picked
# Sporeling first sees 2 cards at drift 25, 1 at 50 and none at 75.

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
	_check(family.offer.size() == 3 and family.offer.all(func(o) -> bool: return o is TowerData),
		"the first pick offers the starting three (%s)" % [family._ids(family.offer)])
	var sporeling = family.offer.filter(func(o) -> bool: return o.get_id() == "sporeling").front()
	family.choose(sporeling)
	await process_frame
	for expected in [2, 1]:
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
	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("family pick rule test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
