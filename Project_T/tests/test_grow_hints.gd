extends SceneTree

# Grow onboarding (onboarding.md b024ccda): GrowHints' marks at rests (↑ grow now, dot rank affordable), the
# first-grow spotlight + "That Sporeling could grow. Click it." whisper, the Grow / Nurture pulses on selection,
# the drift 15 reminder, the "Growth hints" setting. Temp profile.

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
	HeartwoodMemory.file_path = "user://test_grow_hints_%d.json" % OS.get_process_id()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var hints := main.find_child("GrowHints", false, false) as GrowHints
	_check(hints != null, "the HUD makes the grow hints (world)")
	if hints == null:
		quit(1)
		return
	var director: DriftDirector = main.get_node("%DriftDirector")
	var map: Node = main.get_node("%MapGenerator")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var seller: TowerSeller = main.get_node("%TowerSeller")
	var run_state: RunState = main.get_node("%RunState")
	var dreams: DreamState = main.get_node("%DreamState")
	var whispers = main.get_node("%Whispers")
	whispers.enabled = true
	whispers._seen = []
	dreams.unlock_everything = true  # Every form open: a Sprout can grow
	run_state.dew = 0
	placer.select_tower(load("res://resource/tower/sprout.tres"))
	run_state.dew = 1000
	var sprout_cell := _free_cell(map, 6)
	placer._try_build(sprout_cell)
	placer.select_tower(load("res://resource/tower/sporeling.tres"))
	var spore_cell := _free_cell(map, 14)
	placer._try_build(spore_cell)
	placer.set_build_mode(false)
	var sprout := seller.get_tower_at(sprout_cell)
	var spore := seller.get_tower_at(spore_cell)
	_check(sprout != null and spore != null and director.is_resting(), "a Sprout and a Sporeling, at the run's first rest")

	# Too poor: no marks, no spotlight.
	run_state.dew = 0
	hints.refresh()
	_check(hints.marks.is_empty() and hints.spotlight == null, "no Dew: no marks, no spotlight")
	# Rich: ↑ on Wardens that can grow, a dot where a rank is affordable, and the spotlight once.
	run_state.dew = 2000
	hints.refresh()
	var sprout_mark: Array = hints.marks.filter(func(m: Dictionary) -> bool: return m.tower == sprout)
	_check(not sprout_mark.is_empty() and sprout_mark[0].grow, "the Sprout gets the grow ↑")
	var spore_mark: Array = hints.marks.filter(func(m: Dictionary) -> bool: return m.tower == spore)
	_check(not spore_mark.is_empty() and spore_mark[0].rank, "the Sporeling gets the rank dot")
	_check(hints.spotlight != null and hints._seen.has("spotlight"), "the first rest a Warden can grow: the spotlight")
	_check(whispers._queue.has(&"grow") and String(whispers._args.get(&"grow", [""])[0]) == hints.spotlight.tower_data.display_name,
		"…and the whisper names it (%s)" % [whispers._args.get(&"grow", [])])
	var lit := hints.spotlight
	seller.set_selection([lit])
	await process_frame
	_check(hints.spotlight == null, "selecting it ends the spotlight (the Grow buttons pulse)")
	hints.refresh()
	_check(hints.spotlight == null, "once per profile")
	# The Nurture pulse: the first time a rank is affordable on a selected Warden.
	if lit != spore:
		seller.set_selection([spore])
		await process_frame
	_check(hints._seen.has("nurture"), "a selected Warden with an affordable rank: the Nurture pulse (once)")

	# The setting.
	_check(GrowHints.enabled(), "Growth hints default on")
	HeartwoodMemory.preview_settings = HeartwoodMemory.get_settings().merged({GrowHints.SETTING: false}, true)
	_check(not GrowHints.enabled(), "and can be turned off")
	HeartwoodMemory.preview_settings = {}

	# Drift 15: nothing grown or ranked this run → the reminder (a whisper, once per profile).
	_check(not hints.grown_this_run(), "nothing grown yet")
	hints._on_drift_started(GrowHints.REMIND_DRIFT)
	_check(whispers._queue.has(&"grow_more"), "drift 15: \"Your Wardens can become much more than this.\"")
	spore.rank = 1
	_check(hints.grown_this_run(), "a ranked Warden counts as grown")

	# During a drift: nothing.
	director.start_next_drift()
	await process_frame
	hints._process(0.3)
	_check(hints.marks.is_empty() and hints.spotlight == null, "no marks while nightmares walk")

	main.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("PASS" if failures == 0 else "FAILURES: %d" % failures)
	quit(failures)
