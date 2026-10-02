extends SceneTree

# Headless test for spire_difficulty.md Phases 2 and 3 (DreamState): a block finale cleared clean earns one Rare+
# slot in the next Dream (a leaf lost on it doesn't; nor a normal drift or a boss drift; drift 5 is before the
# finales), kept through a reroll and the run save. (The Phase 3 rest choices were replaced by Heartwood's Gifts.)
#   godot --headless --path . --script res://tests/test_spire_dreams.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var real_profile := HeartwoodMemory.file_path
	HeartwoodMemory.file_path = "user://test_spire_dreams_%d.json" % OS.get_process_id()  # Per process
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 51515
	root.add_child(main)
	for i in 3:
		await process_frame
	var dreams: DreamState = main.get_node("%DreamState")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var run_state: RunState = main.get_node("%RunState")
	dreams.unlock_everything = true

	# Drift 10, the first finale, cleared clean: the rest after it has the reward pending
	_play(director, dreams, 10)
	_check(dreams.finale_cleared_clean(10), "no leaf lost on the finale so far: clean")
	_rest(director)
	_check(dreams.has_rare_slot_pending() and dreams.finale_reward_pending(), "a clean finale earns a Rare+ slot")
	var result := dreams.finale_result(2)
	_check(result.finale == 10 and result.clean and result.leaves_lost == 0, "finale_result(block 2): %s" % result)
	# The slot is one Rare+ card in the next offer (sampled over seeds: always at least one Rare+), then it's used
	var rare_every_time := true
	for i in 30:
		dreams._finale_rare_next = 1
		dreams._dreams_without_rare = 0
		var offer := dreams.make_offer(11)
		if not offer.any(func(c: UpgradeData) -> bool: return c.is_rare_or_better()):
			rare_every_time = false
	_check(rare_every_time, "the next offer always has a Rare+")
	_check(not dreams.has_rare_slot_pending(), "…and the slot is used by that offer")
	# A reroll keeps it (the offer counters roll back, the slot with them)
	dreams._finale_rare_next = 1
	dreams._before_offer = dreams._offer_counters()
	dreams.make_offer(11)
	dreams._restore_offer_counters(dreams._before_offer)
	_check(dreams.has_rare_slot_pending(), "a reroll keeps the Rare+ slot")
	dreams._finale_rare_next = 0

	# Drift 15 with a leaf lost: no reward, the result says how many
	_play(director, dreams, 15)
	run_state.leaves_lost += 1
	_check(not dreams.finale_cleared_clean(15), "a leaf lost on the finale: not clean")
	_rest(director)
	result = dreams.finale_result(3)
	_check(not dreams.has_rare_slot_pending() and result.finale == 15 and not result.clean and result.leaves_lost == 1,
		"…no Rare+ slot (%s)" % result)

	# Not finales: a mid-block drift, a boss drift, drift 5 (before finales start)
	for drift in [12, 25, 5]:
		_play(director, dreams, drift)
		_rest(director)
		_check(not dreams.has_rare_slot_pending() and not dreams.finale_results.has(drift), "drift %d is no finale" % drift)

	# Judged once even if Main's rest report reads before DreamState's own rest handler
	_play(director, dreams, 20)
	director.resting = true
	_check(dreams.finale_result(4).clean and dreams.has_rare_slot_pending(), "a getter at the rest judges the finale")
	director.rest_started.emit(4, false, 0, false)
	_check(dreams._finale_rare_next == 1, "…once (%d slot)" % dreams._finale_rare_next)

	# Saved with the run
	var saved := JSON.parse_string(JSON.stringify(dreams.to_save())) as Dictionary
	dreams._finale_rare_next = 0
	dreams.finale_results.clear()
	dreams.load_save(saved)
	_check(dreams.has_rare_slot_pending() and dreams.finale_result(4).finale == 20 and dreams.finale_result(3).leaves_lost == 1,
		"the slot and the results survive the run save")
	dreams._finale_rare_next = 0

	# Heartwood's Gifts, Waking Root: the next form unlocked on the Remember screen costs 1 less Dreamlight, once
	dreams.unlock_everything = false
	var branch: TowerData = null
	for file in DirAccess.get_files_at("res://resource/tower/"):
		var parent = load("res://resource/tower/" + file.trim_suffix(".remap"))
		if not (parent is TowerData) or not parent.buildable_directly:
			continue
		for form in parent.evolves_to:
			if branch == null and form is TowerData and form.tier == 2:
				dreams.unlocked[parent.get_id()] = true
				dreams.unlocked.erase(form.get_id())
				if dreams.get_unlock_blocker(form) == "":
					branch = form
	_check(branch != null, "a branch form to unlock")
	if branch != null:
		var full := dreams.get_unlock_cost(branch)
		dreams.add_unlock_discount(1)
		_check(dreams.get_unlock_price(branch) == maxi(full - 1, 0) and dreams.get_unlock_cost(branch) == full,
			"Waking Root: %d Dreamlight → %d (the cost stays the \"0 = owned\" answer)" % [full, dreams.get_unlock_price(branch)])
		saved = JSON.parse_string(JSON.stringify(dreams.to_save())) as Dictionary
		dreams.unlock_discounts = 0
		dreams.load_save(saved)
		_check(dreams.unlock_discounts == 1, "…saved with the run")
		dreams.dreamlight = 5
		_check(dreams.unlock_with_dreamlight(branch) and dreams.dreamlight == 5 - maxi(full - 1, 0), "…and the unlock pays the lower price")
		_check(dreams.unlock_discounts == 0, "…one use")

	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	HeartwoodMemory.file_path = real_profile
	print("spire dreams test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

# Drift `number` starts (its nightmares on the field).
func _play(director: DriftDirector, dreams: DreamState, number: int) -> void:
	director.resting = false
	director.drifts_started = number
	dreams._finale_on_drift(number)

# Its rest begins (the field is clear).
func _rest(director: DriftDirector) -> void:
	director.resting = true
	var block := ceili(director.drifts_started / float(director.drifts_per_block))
	director.rest_started.emit(block, false, 0, false)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
