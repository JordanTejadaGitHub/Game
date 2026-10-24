extends SceneTree

# Headless test for DriftShapes (enemy_design.md "Drift shapes"): apply keeps every arrival and the first
# and last times, packs are one kind, sized, spaced and never flyers, elites sit where the shape puts them,
# no crowd of more than 8 inside 3 s, bosses untouched, same rng = same result, and the pack leak cap.
#   godot --headless --path . --script res://tests/test_drift_shapes.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var shade: EnemyData = load("res://resource/enemy/leaf_bug.tres")
	var husk: EnemyData = load("res://resource/enemy/bark_beetle.tres")
	var wisp: EnemyData = load("res://resource/enemy/will_o_wisp.tres")
	var crow: EnemyData = load("res://resource/enemy/crow.tres")  # A flyer
	var hare: EnemyData = load("res://resource/enemy/wandering_hare.tres")  # Wander
	var boss: EnemyData = load("res://resource/enemy/old_stag.tres")

	# Packs, act 3: 16 Shades, 8 Husks, 6 Wisps, 3 Crows and a Hare over 30 s, one elite Husk
	var kinds := []
	for i in 16:
		kinds.append(shade)
	for i in 8:
		kinds.append(husk)
	for i in 6:
		kinds.append(wisp)
	for i in 3:
		kinds.append(crow)
	kinds.append(hare)
	var schedule := _even(kinds, 30.0)
	schedule[20][2] = true  # A Husk
	var rng := DriftShapes.drift_rng(1234, 60)
	var shaped := schedule.duplicate(true)
	DriftShapes.apply(shaped, DriftShapes.PACKS, rng, 3)
	_check(shaped.size() == schedule.size(), "packs keep every arrival")
	_check(is_equal_approx(shaped[0][0], 0.0) and is_equal_approx(shaped[-1][0], 30.0), "packs keep the first and last times")
	_check(_sorted(shaped), "the shaped schedule is in time order")
	var packs := {}
	for arrival in shaped:
		var pack := DriftShapes.pack_of(arrival)
		if pack >= 0:
			packs.get_or_add(pack, []).append(arrival)
			_check(DriftShapes.is_packable(arrival[1]), "no flyer / Wander kind in a pack (%s)" % arrival[1].resource_path.get_file())
	_check(packs.size() >= 2, "a Packs drift has packs (%d)" % packs.size())
	var pack_times := []
	for pack in packs:
		var members: Array = packs[pack]
		_check(members.all(func(a: Array) -> bool: return a[1] == members[0][1]), "pack %d is one kind" % pack)
		_check(members.size() <= 8 and members.size() <= ceili(schedule.size() / 3.0), "pack %d: at most 8 and a third of the drift" % pack)
		var gap: float = DriftShapes.PACK_CELLS * DriftShapes.CELL_PX / members[0][1].speed
		for i in range(1, members.size()):
			_check(absf(members[i][0] - members[i - 1][0] - maxf(gap, DriftShapes.PACK_GAP_FLOOR)) < 0.001, "pack %d: half a cell apart" % pack)
		pack_times.append(Vector2(members[0][0], members[-1][0]))
	pack_times.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	for i in range(1, pack_times.size()):
		_check(pack_times[i].x - pack_times[i - 1].y >= DriftShapes.PACK_GAP - 0.001, "at least 5 s between packs")
	_check(not DriftShapes._crowded(shaped), "never more than 8 inside 3 s")
	var elite_pack := -1
	for arrival in shaped:
		if arrival[2]:
			elite_pack = DriftShapes.pack_of(arrival)
	_check(elite_pack >= 0 and absf(_order_of(pack_times, packs, elite_pack) - (packs.size() - 1) / 2.0) <= 0.5,
		"the Deeply Blighted Husk rides in the middle pack")
	var again := schedule.duplicate(true)
	DriftShapes.apply(again, DriftShapes.PACKS, DriftShapes.drift_rng(1234, 60), 3)
	_check(_same(again, shaped), "same seed and drift = same packs")
	var facts := DriftShapes.describe(shaped, DriftShapes.PACKS)
	_check(facts.packs == packs.size() and facts.elites == 1 and facts.elite_place == "pack" and facts.gap_s >= 5.0,
		"describe: %s" % [facts])

	# Act 1: packs of 4–5
	var act1 := _even(kinds.slice(0, 16) + kinds.slice(16, 24), 25.0)
	DriftShapes.apply(act1, DriftShapes.PACKS, DriftShapes.drift_rng(5, 12), 1)
	var act1_sizes := {}
	for arrival in act1:
		if DriftShapes.pack_of(arrival) >= 0:
			act1_sizes[DriftShapes.pack_of(arrival)] = act1_sizes.get(DriftShapes.pack_of(arrival), 0) + 1
	_check(not act1_sizes.is_empty() and act1_sizes.values().all(func(n: int) -> bool: return n >= 3 and n <= 5),
		"act 1 packs hold 4–5 (%s)" % [act1_sizes])

	# Omens: Crowded Paths fills packs to 8; Restless Wind shortens the gaps between packs
	var crowded := _even(kinds.slice(0, 16) + kinds.slice(16, 24), 40.0)
	DriftShapes.apply(crowded, DriftShapes.PACKS, DriftShapes.drift_rng(5, 40), 3, {"pack_fill": 8})
	_check(DriftShapes.describe(crowded, DriftShapes.PACKS).pack_size == 8, "pack_fill 8: packs of 8")
	var tight := _even(kinds.slice(0, 24), 18.0)
	var tight_shaped := tight.duplicate(true)
	DriftShapes.apply(tight_shaped, DriftShapes.PACKS, DriftShapes.drift_rng(5, 41), 3)
	var windy := tight.duplicate(true)
	DriftShapes.apply(windy, DriftShapes.PACKS, DriftShapes.drift_rng(5, 41), 3, {"pack_gap": 0.5})
	_check(DriftShapes.describe(windy, DriftShapes.PACKS).packs >= DriftShapes.describe(tight_shaped, DriftShapes.PACKS).packs,
		"pack_gap 0.5 lets packs sit closer (more of them fit)")

	# Too short a window: a Stream, unchanged
	var cramped := _even(kinds.slice(0, 24), 6.0)
	var cramped_shaped := cramped.duplicate(true)
	DriftShapes.apply(cramped_shaped, DriftShapes.PACKS, DriftShapes.drift_rng(5, 42), 3)
	_check(cramped_shaped.all(func(a: Array) -> bool: return DriftShapes.pack_of(a) < 0) and _same_times(cramped_shaped, cramped),
		"packs that can't fit leave a Stream")

	# Single file: no kind twice in a row, the elite last, even spacing
	var file_kinds := []
	for i in 8:
		file_kinds.append(husk)
	for i in 5:
		file_kinds.append(wisp)
	var single := _even(file_kinds, 24.0)
	single[3][2] = true
	DriftShapes.apply(single, DriftShapes.SINGLE_FILE, DriftShapes.drift_rng(7, 30), 2)
	var repeats := 0
	for i in range(1, single.size() - 1):  # The elite (last) may follow its own kind
		if single[i][1] == single[i - 1][1]:
			repeats += 1
	_check(repeats <= 8 - 5 - 1 + 1, "single file: a kind twice in a row only when the mix forces it (%d)" % repeats)
	_check(single[-1][2], "single file: the Deeply Blighted comes last")
	_check(is_equal_approx(single[0][0], 0.0) and is_equal_approx(single[-1][0], 24.0), "single file keeps the window")
	_check(DriftShapes.describe(single, DriftShapes.SINGLE_FILE).elite_place == "last", "describe: last in line")

	# Few and tough: elites first
	var few := _even([husk, husk, husk, husk, wisp, wisp, wisp, husk, husk], 20.0)
	few[7][2] = true
	few[8][2] = true
	few[0][2] = true
	DriftShapes.apply(few, DriftShapes.FEW_AND_TOUGH, DriftShapes.drift_rng(7, 31), 2)
	_check(few[0][2] and few[1][2] and few[2][2] and not few[3][2], "few and tough: the Deeply Blighted come first")
	_check(DriftShapes.describe(few, DriftShapes.FEW_AND_TOUGH).elite_place == "first", "describe: first")

	# A boss drift is left alone
	var boss_drift := _even([boss, shade, shade, shade, shade, shade, shade], 10.0)
	var boss_copy := boss_drift.duplicate(true)
	DriftShapes.apply(boss_drift, DriftShapes.PACKS, DriftShapes.drift_rng(7, 25), 1)
	_check(_same_times(boss_drift, boss_copy) and boss_drift.all(func(a: Array) -> bool: return DriftShapes.pack_of(a) < 0),
		"a boss drift keeps its schedule")

	# The pack leak cap: 3 leaves a pack in all
	var charged := {}
	var a := Node.new()
	var b := Node.new()
	var loose := Node.new()
	a.set_meta(DriftShapes.PACK_META, DriftShapes.pack_key(60, 1))
	b.set_meta(DriftShapes.PACK_META, DriftShapes.pack_key(60, 1))
	var lost := DriftShapes.cap_pack_leak(a, 2, charged) + DriftShapes.cap_pack_leak(b, 2, charged) + DriftShapes.cap_pack_leak(b, 1, charged)
	_check(lost == 3, "a leaked pack costs at most 3 leaves (%d)" % lost)
	_check(DriftShapes.cap_pack_leak(loose, 2, charged) == 2, "outside a pack a leak costs its full price")
	for node in [a, b, loose]:
		node.free()
	_check(DriftShapes.display_name(&"") == "Stream" and DriftShapes.display_name(DriftShapes.FEW_AND_TOUGH) == "Few and tough",
		"display names")

	if failures == 0:
		print("PASS test_drift_shapes")
	quit(failures)

func _even(kinds: Array, window: float) -> Array:
	var schedule := []
	for i in kinds.size():
		schedule.append([window * i / maxf(kinds.size() - 1, 1), kinds[i], false])
	return schedule

func _sorted(schedule: Array) -> bool:
	for i in range(1, schedule.size()):
		if schedule[i][0] < schedule[i - 1][0]:
			return false
	return true

func _same(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if not is_equal_approx(a[i][0], b[i][0]) or a[i][1] != b[i][1] or a[i][2] != b[i][2] or DriftShapes.pack_of(a[i]) != DriftShapes.pack_of(b[i]):
			return false
	return true

func _same_times(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if not is_equal_approx(a[i][0], b[i][0]) or a[i][1] != b[i][1]:
			return false
	return true

# The place (0, 1, …) in time order of pack `pack`.
func _order_of(pack_times: Array, packs: Dictionary, pack: int) -> int:
	var start: float = packs[pack][0][0]
	for i in pack_times.size():
		if is_equal_approx(pack_times[i].x, start):
			return i
	return -1

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
