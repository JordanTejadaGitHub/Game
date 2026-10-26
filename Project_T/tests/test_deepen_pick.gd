extends SceneTree

# The drift 60 pick deepens a family (owner 2026-10-22, dream_council_review.md section 31). Written before the build:
# it names the API Roguelite Code builds to (DriftDirector.family_pick_kind, FamilyPickScreen.show_pick(&"deepen"),
# DreamState.DEEPEN_DREAMLIGHT / DEEPEN_FINAL_DREAMLIGHT / deepen_family / is_deepen_open).
# - Drift 60's pick is &"deepen", not a new family; 10 and 40 still bring families.
# - Its cards are the run's own families that have a branch "not in this dream"; a family with none gets no card.
# - Taking one gives +1 Dreamlight, adds no family, sets no Calling.
# - That family's misty branches call back at the branch price (1), even after the once-per-family call-back.
# - Calling one back unlocks the branch but not its final; then the deepen call is spent.
# - Not calling keeps the Dreamlight and the open call, through a save.
# - The drift 75 rest gives 2 more Dreamlight than the drift 50 one.
#   godot --headless --fixed-fps 60 --path . --script res://tests/test_deepen_pick.gd

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_deepen_pick_%d.json" % OS.get_process_id()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	await process_frame
	var family = main.get_node("%FamilyPickScreen")
	var dreams: DreamState = main.get_node("%DreamState")
	var dd: DriftDirector = main.get_node("%DriftDirector")

	# Which pick each drift brings
	_check(dd.family_pick_kind(dd.second_family_pick_drift) != &"deepen" and dd.family_pick_kind(dd.third_family_pick_drift) != &"deepen",
		"drifts %d and %d still bring a new family" % [dd.second_family_pick_drift, dd.third_family_pick_drift])
	_check(dd.family_pick_kind(dd.fourth_family_pick_drift) == &"deepen", "drift %d's pick deepens a family" % dd.fourth_family_pick_drift)

	# Three families: the first pick and two more
	family.show_pick(&"first")
	family.choose(family.offer[0])
	await process_frame
	for i in 2:
		family.show_pick(&"second")
		if not family.offer.is_empty():
			family.choose(family.offer[0])
		await process_frame
	var owned := _owned_bases(dreams)
	var calling := dreams.calling

	# One card per owned family with a misty branch, and only those
	family.show_pick(&"deepen")
	var offered: Array = family.offer.filter(func(o) -> bool: return o is TowerData)
	_check(offered.size() == family.offer.size(), "the deepen pick shows only families, no Blessings (%s)" % [family._ids(family.offer)])
	var with_misty: Array = owned.filter(func(b: TowerData) -> bool: return not dreams.not_offered_branches(b).is_empty())
	_check(offered.size() == with_misty.size() and offered.all(func(b: TowerData) -> bool: return with_misty.has(b)),
		"one card per owned family with a branch not in this dream (%s of %s)" % [family._ids(offered), family._ids(with_misty)])
	if offered.is_empty():
		_finish()
		return
	var base: TowerData = offered[0]
	var misty := dreams.not_offered_branches(base)
	_check(misty.size() >= 1 and misty.size() <= 3, "the card lists up to three misty branches (%d)" % misty.size())

	# Mark the family's normal call-back as used: the deepen call must not care
	dreams.called_families[base.get_id()] = "used"
	var before := dreams.dreamlight
	family.choose(base)
	await process_frame
	_check(dreams.dreamlight == before + dreams.DEEPEN_DREAMLIGHT and dreams.DEEPEN_DREAMLIGHT == 1,
		"taking it gives 1 Dreamlight (%d -> %d)" % [before, dreams.dreamlight])
	_check(_owned_bases(dreams).size() == owned.size(), "no new family joins the run")
	_check(dreams.calling == calling, "the Calling is unchanged")
	_check(dreams.deepen_family == base.get_id() and dreams.is_deepen_open(base), "the deepen call is open for %s" % base.get_id())
	_check(dreams.call_back_cost(base) == dreams.BRANCH_DREAMLIGHT, "its misty branches cost the branch price (%d)" % dreams.call_back_cost(base))
	_check(dreams.call_back_problem(misty[0]) == "", "callable even after the family's normal call-back: %s" % dreams.call_back_problem(misty[0]))
	var other: TowerData = null
	for b in owned:
		if b != base and not dreams.not_offered_branches(b).is_empty():
			other = b
	if other != null:
		_check(dreams.call_back_cost(other) > dreams.BRANCH_DREAMLIGHT, "another family's call-back keeps its normal price (%d)" % dreams.call_back_cost(other))

	# Not calling yet: kept through a save
	var saved: Dictionary = dreams.to_save()
	dreams.load_save(saved)
	_check(dreams.is_deepen_open(base) and dreams.dreamlight == before + 1, "the open call and the Dreamlight survive a save")

	# Calling one back: the branch, not its final; the call is spent
	var spent_before := dreams.dreamlight
	_check(dreams.call_back(misty[0]), "the misty branch calls back")
	_check(dreams.dreamlight == spent_before - dreams.BRANCH_DREAMLIGHT, "it cost 1 Dreamlight")
	_check(dreams.is_unlocked(misty[0].get_id()), "the branch is unlocked")
	for f in misty[0].evolves_to:
		if f is TowerData and f.tier == 3:
			_check(not dreams.is_unlocked(f.get_id()), "its final %s stays locked" % f.get_id())
	_check(not dreams.is_deepen_open(base), "the deepen call is spent")
	if misty.size() > 1:
		dreams.add_dreamlight(5)
		_check(dreams.call_back_problem(misty[1]) != "", "a second misty branch can't be called through it")

	# Drift 75's rest: 2 more Dreamlight than drift 50's
	var none := func(_offer: Array) -> UpgradeData: return null
	var d0 := dreams.dreamlight
	dreams.sim_rest(50, none)
	var at_50 := dreams.dreamlight - d0
	var d1 := dreams.dreamlight
	dreams.sim_rest(75, none)
	var at_75 := dreams.dreamlight - d1
	_check(dreams.DEEPEN_FINAL_DREAMLIGHT == 2 and at_75 == at_50 + 2, "drift 75's rest gives 2 more Dreamlight (50: %d, 75: %d)" % [at_50, at_75])
	_finish()

func _owned_bases(dreams: DreamState) -> Array:
	var out: Array = []
	for b in dreams._roster():
		if b is TowerData and b.tier == 1 and b.buildable_directly and b.line != "wall" and dreams.is_unlocked(b.get_id()):
			out.append(b)
	return out

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok   ", what)
	else:
		failures += 1
		print("  FAIL ", what)

func _finish() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("test_deepen_pick: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)
