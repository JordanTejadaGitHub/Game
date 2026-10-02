extends SceneTree

# Balance probe (not a test): one Warden form compared on a fixed board. Four copies of the candidate take
# the four best spots by the path, then a fixed cast of eight other finals fills in; every Warden is
# bought with real Dew (base, each growth, ranks I-IV with Power) so invested_dew is what a player pays.
# No Dreams. Drifts FIRST..FIRST+COUNT-1 run with the Heartwood invulnerable; prints the candidate's
# damage per Warden and per 100 Dew invested, its split (hit / cloud / status / combo, onto Asleep) and
# the board's leak share.
#   godot --headless --path . --script res://tools/balance_finals.gd --fixed-fps 60 -- --form=dreamshroom \
#       [--drift=45] [--count=5] [--seed=7] [--out=<file.csv>]   (appends one row per run to --out)

const SPEED := 4.0
var rank := 4  # --rank=N: ranks bought for every Warden (Power)
const COPIES := 4
const CAST := ["thunderhead", "boulderback", "moonstone", "rockslide", "starcave", "midsummer", "magpies_hoard", "great_dreamcatcher"]
const CAST_ACT1 := ["sporeling", "firefly_jar", "dewdrop", "bellflower", "pebbling", "acorn", "rootling", "nestling"]  # --cast=act1: base Wardens (an act 1 board)
const CAST_NOCHARGE := ["boulderback", "boulderback", "moonstone", "rockslide", "starcave", "midsummer", "magpies_hoard", "great_dreamcatcher"]  # --cast=nocharge: the finals cast without its only Charged source (Thunderhead -> a 2nd Boulderback)
var cast: Array = CAST
var next_to: Array = []  # --next-to=puffball,lullaby_bell: the cast is planted first and each candidate goes beside one of these
var pairs := false  # --pairs: every second copy goes across the route from the one before it, within 4 cells (Jarlink arcs over the route)

var main: Node
var form_id := "dreamshroom"
var first := 45
var count := 5
var map_seed := 7
var out_path := ""
var candidates: Array[Tower] = []
var by_tower := {}  # instance id -> damage
var split := {"hit": 0.0, "cloud": 0.0, "status": 0.0, "combo": 0.0, "asleep": 0.0}
var by_tag := {}  # "kind/tag" -> the candidates' damage (tags column)
var spore_appliers := {}  # For Spored ticks credited to the candidates: applier form id -> damage share (by stacks added)
var spore_combos := {}  # …and their combo tags -> damage
var spored_burning := 0.0  # The candidates' Spored damage dealt while the nightmare burns (Ignite: ticks 3x as fast)
var total := 0.0
var spawned_health := 0.0
var leaked_health := 0.0
var game_time := 0.0
var boss2 := ""  # --boss2=huntsman: act 2's boss forced (DriftDirector.preset_bosses); run --drift=45 --count=6 to meet it at 50
var boss_fights := {}  # Instance id -> {kind, health, spawn, arrive, hp_arrive, end, dispelled}

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		var value := arg.get_slice("=", 1)
		match arg.get_slice("=", 0):
			"--form": form_id = value
			"--drift": first = int(value)
			"--count": count = int(value)
			"--seed": map_seed = int(value)
			"--out": out_path = value
			"--boss2": boss2 = value
			"--rank": rank = int(value)
			"--cast": cast = {"act1": CAST_ACT1, "nocharge": CAST_NOCHARGE, "finals": CAST}.get(value, Array(value.split(",")))  # or a list: --cast=rain_lily,rain_lily,…
			"--next-to": next_to = Array(value.split(","))
			"--pairs": pairs = true
	ProjectSettings.set_setting("game/demo", false)  # The full game (as the user plays it)
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = map_seed
	if boss2 != "":
		main.get_node("%DriftDirector").preset_bosses = ["hollow_stag", boss2]  # Set before the deferred draw
	root.add_child(main)
	await process_frame
	var dreams: DreamState = main.get_node("%DreamState")
	var run_state: RunState = main.get_node("%RunState")
	var director: DriftDirector = main.get_node("%DriftDirector")
	var placer: TowerPlacer = main.get_node("%TowerPlacer")
	var spawner = main.get_node("%EnemyContainer")
	dreams.unlock_everything = true
	run_state.dew = 10000000
	run_state.invulnerable = true
	var rest: Array = cast.duplicate()
	for i in COPIES:
		var tower: Tower = null
		if pairs and i % 2 == 1:
			tower = _plant(placer, form_id, [form_id], candidates[i - 1], true)  # Across the route from its partner
		elif next_to.is_empty():
			tower = _plant(placer, form_id)
		else:  # Pair by pair: a target from the cast, then a candidate in a free cell touching it; a target
			# hemmed in by obstacles gets another planted next to the route (up to 4 tries; extras stay in the board)
			for attempt in 4:
				var target: String = next_to[(i + attempt) % next_to.size()]
				rest.erase(target)
				var beside := _plant(placer, target)
				tower = _plant(placer, form_id, next_to, beside) if beside != null else null
				if tower != null:
					break
		if tower == null:
			printerr("could not plant %s" % form_id)
			quit(1)
			return
		candidates.append(tower)
	for id in rest:
		_plant(placer, id)
	if DamageLog.instance:
		DamageLog.instance.damage_dealt.connect(_on_damage)
	spawner.child_entered_tree.connect(func(n) -> void:
		if n.has_method("take_damage"):
			(func() -> void: spawned_health += n.max_health).call_deferred())
	spawner.enemy_reached_goal.connect(func(e) -> void:
		leaked_health += e.health
		if is_instance_valid(e) and e.enemy_data.is_boss:
			var fight := _fight(e)
			if fight.arrive < 0.0:
				fight.arrive = game_time
				fight.hp_arrive = e.health)
	spawner.enemy_cleansed.connect(func(e) -> void:
		if is_instance_valid(e) and e.enemy_data.is_boss:
			var fight := _fight(e)
			fight.end = game_time
			fight.dispelled = true)
	director.family_pick_requested.connect(func(_kind) -> void: director.family_picked.call_deferred())  # No new family: the probe's board is fixed
	director.drifts_started = first - 1
	director.drifts_cleared = first - 1
	Engine.time_scale = SPEED
	var frames := 0
	var last := first + count - 1
	while director.drifts_cleared < last and frames < 60 * 60 * 30:
		paused = false
		match director.pending_choice():  # No Dreams, no Omens: every rest's choice lets it pass
			&"dream":
				if dreams.is_offering():
					dreams.skip()
			&"omen":
				var omens = main.get_node_or_null("%OmenDirector")
				if omens and omens.is_offering():
					omens.choose(null)
		if director.is_resting() and director.drifts_started < last:
			director.start_next_block()
		await process_frame
		frames += 1
		game_time += SPEED / 60.0
		if frames % 15 == 0:  # Bosses: first seen, and the health they reach the Heartwood with (a lingering one too)
			for e in spawner.get_enemies():
				if is_instance_valid(e) and e.enemy_data.is_boss:
					var fight := _fight(e)
					if e.get("at_heartwood") and fight.arrive < 0.0:
						fight.arrive = game_time
						fight.hp_arrive = e.health
		if frames % (60 * 60) == 0:  # Watchdog: the director's state every minute of wall time
			print("  t %.0f s: started %d cleared %d resting %s arriving %s awaiting pick %s over %s field %d" % [game_time,
				director.drifts_started, director.drifts_cleared, director.is_resting(), director._arriving.keys(),
				director.awaiting_family_pick, main.get_node("%RunState").is_over, spawner.get_enemies().size()])
	Engine.time_scale = 1.0
	_report(director)
	quit(0)

# Builds the base form on the best open cell next to the path, grows it to `id` and ranks it to `rank`,
# all paid with Dew. Returns the Warden, or null.
# `next_to`: only cells touching (8 around) a planted Warden whose id is in the list (Grafted Elder copies a neighbour).
func _plant(placer: TowerPlacer, id: String, next_to: Array = [], beside: Tower = null, across := false) -> Tower:
	var chain := _chain_to(id)
	if chain.is_empty():
		return null
	var map = main.get_node("%MapGenerator")
	var container: Node = main.get_node("%TowerContainer")
	var path: PackedVector2Array = map.get_path_from(map.startPath)
	placer.tower_data = chain[0]
	var tower: Tower = null
	var spots: Array = []  # [[path index, cell], …] in the order to try
	if next_to.is_empty():
		for i in range(4, path.size() - 2):
			for offset in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
				spots.append(path[i] + offset)
	elif across and beside != null:  # --pairs: across the route from its partner (within 4 cells, the route between them)
		for dist in range(2, 5):
			for dx in range(-dist, dist + 1):
				for dy in range(-dist, dist + 1):
					if maxi(absi(dx), absi(dy)) != dist:
						continue
					var cell: Vector2 = beside.cell + Vector2(dx, dy)
					if path.has(((beside.cell + cell) / 2.0).round()):
						spots.append(cell)
	else:  # Any free cell touching a target Warden (the 8 around), targets in planting order
		for t in container.get_children():
			if t is Tower and (t == beside if beside != null else next_to.has(t.tower_data.get_id())):
				for dx in [-1, 0, 1]:
					for dy in [-1, 0, 1]:
						spots.append(t.cell + Vector2(dx, dy))
	for cell in spots:
		if tower == null:
			if path.has(cell) or not map.can_block(cell):
				continue
			var before := container.get_child_count()
			if placer._try_build(cell):
				tower = container.get_child(before)
		if tower != null:
			break
	if tower == null:
		return null
	for step in chain.slice(1):
		placer.evolve(tower, step)
	for r in rank:
		if not placer.nurture(tower, Tower.Focus.POWER):
			for focus in [Tower.Focus.STRONG, Tower.Focus.WIDE, Tower.Focus.SWIFT]:
				if placer.nurture(tower, focus):
					break
	return tower

# The forms from a buildable base to `id` (base first), from every Warden's evolves_to.
func _chain_to(id: String) -> Array[TowerData]:
	var parent := {}
	var all := {}
	for file in DirAccess.get_files_at("res://resource/tower/"):
		if not file.ends_with(".tres"):
			continue
		var data := load("res://resource/tower/" + file) as TowerData
		if data == null:
			continue
		all[data.get_id()] = data
		for next in data.evolves_to:
			if next is TowerData and not parent.has(next.get_id()):
				parent[next.get_id()] = data
	var chain: Array[TowerData] = []
	var at: TowerData = all.get(id)
	while at != null:
		chain.push_front(at)
		if at.buildable_directly:
			break
		at = parent.get(at.get_id())
	return chain if not chain.is_empty() and chain[0].buildable_directly else ([] as Array[TowerData])

func _on_damage(event) -> void:
	total += event.amount
	if not is_instance_valid(event.source):
		return
	var key: int = event.source.get_instance_id()
	by_tower[key] = by_tower.get(key, 0.0) + event.amount
	if not candidates.has(event.source):
		return
	var combo := clampf(event.combo_amount, 0.0, event.amount)
	split.combo += combo
	var tag_key := "%s/%s" % [event.kind, event.tag if event.tag != &"" else &"-"]
	by_tag[tag_key] = float(by_tag.get(tag_key, 0.0)) + event.amount
	if event.tag == &"spored" and is_instance_valid(event.enemy):
		if event.enemy.statuses.burn_time > 0.0:
			spored_burning += event.amount
		var credit: Array = event.enemy.statuses.spore_credit()
		if credit.is_empty():
			spore_appliers["(none)"] = float(spore_appliers.get("(none)", 0.0)) + event.amount
		for part in credit:
			var who: String = part[0].tower_data.get_id() if is_instance_valid(part[0]) and part[0] is Tower else "(gone)"
			spore_appliers[who] = float(spore_appliers.get(who, 0.0)) + event.amount * part[1]
		for c in event.combos:
			spore_combos[String(c)] = float(spore_combos.get(String(c), 0.0)) + event.amount
	if event.tag == &"cloud":
		split.cloud += event.amount - combo
	elif event.kind == &"status" or event.kind == &"bolt":
		split.status += event.amount - combo
	else:
		split.hit += event.amount - combo
	if is_instance_valid(event.enemy) and event.enemy.statuses.is_asleep():
		split.asleep += event.amount

func _report(director: DriftDirector) -> void:
	var damage := 0.0
	var invested := 0
	for tower in candidates:
		damage += by_tower.get(tower.get_instance_id(), 0.0)
		invested += tower.invested_dew
	var t := maxf(damage, 1.0)
	var row := {"form": form_id, "seed": map_seed, "drift": first, "count": count, "cleared": director.drifts_cleared - first + 1,
		"per_warden": roundi(damage / COPIES), "dew_per_warden": invested / COPIES, "per_100_dew": snappedf(100.0 * damage / maxf(invested, 1), 0.1),
		"share": snappedf(damage / maxf(total, 1.0), 0.001), "rank": candidates[0].rank,
		"hit": snappedf(split.hit / t, 0.01), "cloud": snappedf(split.cloud / t, 0.01), "status": snappedf(split.status / t, 0.01),
		"combo": snappedf(split.combo / t, 0.01), "asleep": snappedf(split.asleep / t, 0.01),
		"leaked": snappedf(leaked_health / maxf(spawned_health, 1.0), 0.001), "status_potency": Tower.status_potency_on, "cast": "act1" if cast == CAST_ACT1 else ("nocharge" if cast == CAST_NOCHARGE else ("finals" if cast == CAST else "+".join(cast))), "next_to": "+".join(next_to), "pairs": pairs, "board_damage": roundi(total),
		"bosses": ";".join(boss_fights.values().map(func(b) -> String: return "%s:%d:%s:%.0f:%d" % [b.kind, b.health, "1" if b.dispelled else "0", (b.end - b.spawn) if b.dispelled else -1.0, b.hp_arrive])),
		"tags": _tag_text(t), "spore_appliers": _share_text(spore_appliers, t), "spore_combos": _share_text(spore_combos, t), "spored_burning": snappedf(spored_burning / t, 0.001)}
	print("FINALS %s" % JSON.stringify(row))
	if out_path != "":
		var exists := FileAccess.file_exists(out_path)
		var file := FileAccess.open(out_path, FileAccess.READ_WRITE if exists else FileAccess.WRITE)
		if not exists:
			file.store_line(",".join(row.keys()))
		file.seek_end()
		file.store_line(",".join(row.keys().map(func(k) -> String: return str(row[k]))))
		file.close()

# "kind/tag:share|…" of the candidates' damage, largest first.
func _tag_text(t: float) -> String:
	var keys := by_tag.keys()
	keys.sort_custom(func(a, b) -> bool: return by_tag[a] > by_tag[b])
	return "|".join(keys.map(func(k) -> String: return "%s:%.3f" % [k, by_tag[k] / t]))

func _share_text(d: Dictionary, t: float) -> String:
	var keys := d.keys()
	keys.sort_custom(func(a, b) -> bool: return d[a] > d[b])
	return "|".join(keys.map(func(k) -> String: return "%s:%.3f" % [k, d[k] / t]))

# A boss fight: kind, health, when first seen, when (and with how much health) it reached the Heartwood,
# whether and when it was dispelled. bosses column: "kind:health:dispelled:seconds to dispel:health at the Heartwood (-1 = never)".
func _fight(enemy: Node2D) -> Dictionary:
	return boss_fights.get_or_add(enemy.get_instance_id(), {"kind": enemy.enemy_data.resource_path.get_file().get_basename(),
		"health": enemy.max_health, "spawn": game_time, "arrive": -1.0, "hp_arrive": -1, "end": -1.0, "dispelled": false})
