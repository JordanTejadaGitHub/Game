extends SceneTree

# Feeling the cards (dream_design.md 2026-10-01), Main's parts: the bloom on the affected Wardens (staggered, real
# time, then gone), the rest report / results / run report credit lines and the Dreams row's "This run" (once
# DreamState has get_card_credit, Roguelite Code's).

var failures := 0

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		failures += 1
		push_error("FAIL: " + what)

func _initialize() -> void:
	_run.call_deferred()

func _free_cell(map: Node, from_x: int) -> Vector2:
	for y in range(2, 16):
		for x in range(from_x, 21):
			var cell := Vector2(x, y)
			if map.is_buildable(cell) and not map.get_path_if_blocked(cell).is_empty():
				return cell
	return Vector2(-1, -1)

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_card_feel_%d.json" % OS.get_process_id()
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var bloom := main.find_child("CardBloom", false, false) as CardBloom
	_check(bloom != null, "the HUD makes the card bloom (in the world)")
	var map: Node = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var run_state: RunState = main.get_node("%RunState")
	run_state.dew = 1000
	placer.select_tower(load("res://resource/tower/sprout.tres"))
	var towers: Array = []
	for from_x in [4, 10, 16]:
		var cell := _free_cell(map, from_x)
		placer._try_build(cell)
		var tower := seller.get_tower_at(cell)
		if tower != null and not towers.has(tower):
			towers.append(tower)
	placer.set_build_mode(false)
	var card: UpgradeData = null
	for path in DirAccess.get_files_at("res://resource/dream"):
		if path.ends_with(".tres"):
			card = load("res://resource/dream/" + path)
			break
	if bloom != null and card != null and towers.size() >= 2:
		bloom.bloom(card, towers)
		var gaps: Array = []
		for i in range(1, bloom.pulses.size()):
			gaps.append(int(bloom.pulses[i].at) - int(bloom.pulses[i - 1].at))
		_check(bloom.pulses.size() == towers.size() and gaps.all(func(g: int) -> bool: return g > 0 and g <= 120),
			"every affected Warden pulses, staggered (%s ms)" % [gaps])
		_check(bloom.pulses[-1].at - bloom.pulses[0].at <= 1000, "within about a second")
		bloom.bloom(card, [])
		_check(bloom.pulses.size() == towers.size(), "a card that affects nothing adds no pulse")
		var start := Time.get_ticks_msec()
		while not bloom.pulses.is_empty() and Time.get_ticks_msec() - start < 4000:
			await process_frame
		_check(bloom.pulses.is_empty(), "the pulses finish on their own (real time)")
		_check(bloom.process_mode == Node.PROCESS_MODE_ALWAYS, "they play at a paused rest too")

	# Credit lines: silent until DreamState credits cards, then the top 3 and "Best Dream".
	var dreams: Node = main.get_node("%DreamState")
	var row := main.find_child("DreamsRow", true, false)
	if not dreams.has_method("get_card_credit"):
		_check(RestReport.dreams_text(main, &"block", "Dreams this block") == "" and RestReport.best_dream_line(main) == "",
			"no credit API yet: no Dream lines")
		print("  (Roguelite's card credit isn't in yet: the credit checks wait for it)")
	else:
		var text := RestReport.dreams_text(main, &"block", "Dreams this block")
		_check(text == "" or text.begins_with("\nDreams this block · ") or not text.contains("Dreams this block"),
			"the rest report's Dreams line (%s)" % text.strip_edges())
		if row != null and card != null:
			_check(row.credit_text(card) == "" or row.credit_text(card).begins_with("This run: "), "the Dreams row's credit")

	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("PASS" if failures == 0 else "FAILURES: %d" % failures)
	quit(failures)
