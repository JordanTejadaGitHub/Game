extends SceneTree

# Headless test for the branch expansion, Phase 1 (tower_design.md "Branch expansion", numbers in
# spire_difficulty.md Phase 6): counter tags, generic Kin and Whole Tree, then each new branch and final.
#   godot --headless --path . --script res://tests/test_branch_expansion.gd --fixed-fps 60

const CELL := 64.0

var failures := 0
var main: Node
var spawner
var placer: TowerPlacer
var container: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	Kinships.force_full = true
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	paused = false
	spawner = main.get_node("%EnemyContainer")
	placer = main.get_node("%TowerPlacer")
	container = main.get_node("%TowerContainer")
	main.get_node("%DreamState").unlock_everything = true
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	await _test_counter_tags()
	await _test_generic_kin()
	await _test_data()
	await _test_sporeling()
	await _test_dewdrop()
	await _test_firefly()
	await _test_bellflower()

	print("branch expansion test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	Kinships.force_full = false
	main.queue_free()
	await process_frame
	quit(failures)

# Every counter tag sits on at least 3 branches across at least 2 families (the coverage table).
func _test_counter_tags() -> void:
	var by_tag := {}
	for file in DirAccess.get_files_at("res://resource/tower/"):
		if not file.ends_with(".tres"):
			continue
		var data := load("res://resource/tower/" + file) as TowerData
		if data == null:
			continue
		for tag in data.counter_tags:
			if not by_tag.has(tag):
				by_tag[tag] = []
			by_tag[tag].append(data)
	for tag in [&"anti_air", &"detection", &"anti_armour", &"anti_swarm", &"anti_tank", &"anti_support", &"boss_abilities"]:
		var list: Array = by_tag.get(tag, [])
		var lines := {}
		for data in list:
			lines[data.line] = true
		if tag in [&"boss_abilities"] and list.size() < 3:
			continue  # Bark Shield and Quaker come with Phase 2 (Acorn, Pebbling)
		_check(list.size() >= 2 and lines.size() >= 2,
			"%s sits on branches of 2+ families (%s)" % [tag, list.map(func(d) -> String: return d.get_id())])

# Any two different branches of one family within 2 cells bond as Kin when they aren't a named pair:
# +10% damage each. Three different branches: Whole Tree.
func _test_generic_kin() -> void:
	var a := _plant("bloomcap", Vector2(6, 6))
	var b := _plant("fairy_ring", Vector2(7, 6))
	var kin := Kinships.find(main)
	kin.refresh()
	var pairs: Array = kin.get_pairs(a)
	_check(pairs.size() == 1 and pairs[0].id == Kinships.GENERIC, "Bloomcap + Fairy Ring (no named pair) bond as Kin (%s)" % [pairs.map(func(p) -> StringName: return p.id)])
	_check(Kinships.name_of(Kinships.GENERIC) == "Kin" and kin.describe(a).contains("Kin"), "the bond is called Kin")
	_check(is_equal_approx(kin.damage_bonus(a) - kin.family_bonus("spore"), Kinships.GENERIC_BONUS),
		"Kin: +10%% damage each (%.2f on top of Kindred %.2f)" % [kin.damage_bonus(a) - kin.family_bonus("spore"), kin.family_bonus("spore")])
	_check(kin.families.get("spore", 0) == 1, "two different branches: Kindred")
	var c := _plant("driftspore", Vector2(14, 6))
	kin.refresh()
	_check(kin.families.get("spore", 0) == 2, "three different branches on the map: Whole Tree")
	for t in [a, b, c]:
		t.queue_free()
	await process_frame
	kin.refresh()

const NEW := {"sporeling": ["lichenling", "brood_cap", "inkcap"], "dewdrop": ["cloudlet", "undercurrent", "jetreed"],
	"firefly_jar": ["jarlink", "prism_jar", "sparkler"], "bellflower": ["silver_bell", "hushbell", "thrum"]}
const FINALS := {"lichenling": "old_lichen", "brood_cap": "hatchery", "inkcap": "deliquescent", "cloudlet": "nimbus",
	"undercurrent": "maelstrom", "jetreed": "torrent", "jarlink": "lightning_fence", "prism_jar": "rainbow_prism",
	"sparkler": "starburst", "silver_bell": "vesper_bell", "hushbell": "silence", "thrum": "resonance"}

# Each new branch: tier 2 for 120 Dew under its base, an unlock card in the start pool; its final tier 3 for 300,
# a card outside it; both expansion_phase 1 with the branch's special.
func _test_data() -> void:
	for base in NEW:
		var base_data: TowerData = load("res://resource/tower/%s.tres" % base)
		for id in NEW[base]:
			var data: TowerData = load("res://resource/tower/%s.tres" % id)
			var final: TowerData = load("res://resource/tower/%s.tres" % FINALS[id])
			var card: UpgradeData = load("res://resource/dream/dream_%s.tres" % id)
			var final_card: UpgradeData = load("res://resource/dream/dream_%s.tres" % FINALS[id])
			_check(base_data.evolves_to.has(data), "%s grows into %s" % [base, id])
			_check(data.tier == 2 and data.evolve_cost == 120 and data.expansion_phase == 1 and data.special != &""
				and data.line == base_data.line and data.evolves_to == [final], "%s: a tier 2 branch for 120 Dew with its special" % id)
			_check(final.tier == 3 and final.evolve_cost == 300 and final.special == data.special and final.special_final,
				"%s: its final for 300 Dew, the same special plus the twist" % FINALS[id])
			_check(card.unlocks == data and card.in_start_pool and card.requires == [base], "%s's unlock card is in the start pool" % id)
			_check(final_card.unlocks == final and not final_card.in_start_pool, "%s's card is not" % FINALS[id])

# --- Sporeling: Lichenling, Brood Cap, Inkcap ---------------------------------------------------------------

func _test_sporeling() -> void:
	# Lichenling: its Spored ticks strip the dread shell and stop mending; Old Lichen cracks it at 8 stacks.
	var lichen := _plant("lichenling", Vector2(6, 6))
	var shelled = _spawn(Vector2(7, 6))
	shelled.coat_max = 1000.0
	shelled.coat = 1000.0
	lichen._apply_one_status(shelled, EnemyStatuses.SPORED, 3, 20.0)
	BranchKit.on_spore_tick(shelled)
	_check(shelled.coat < 1000.0 and shelled.statuses.veil_time > 0.0, "Lichenling's spores strip the shell and block mending (%.0f)" % shelled.coat)
	var old := _plant("old_lichen", Vector2(6, 8))
	var cracked = _spawn(Vector2(7, 8))
	cracked.coat_max = 1000.0
	cracked.coat = 1000.0
	old._apply_one_status(cracked, EnemyStatuses.SPORED, 8, 20.0)
	BranchKit.on_spore_tick(cracked)
	_check(cracked.coat == 0.0, "Old Lichen: at 8 Spored the shell cracks off")
	await _clean()

	# Brood Cap: a sprite walks up the path and bursts on the first nightmare, a hidden one too.
	var brood := _plant("brood_cap", _route_cell(10) + Vector2(0, 1))
	var route := brood._route()
	var walker = _spawn(route[6])
	walker.set_meta(&"test", true)
	BranchKit.release(brood)
	var sprites := root.find_children("*", "Node2D", true, false).filter(func(n) -> bool: return n is BranchKit.BroodSprite)
	_check(sprites.size() == 1, "Brood Cap hatches a sprite (%d)" % sprites.size())
	walker._set_hidden(true)
	var health: int = walker.health
	for i in 150:
		await process_frame
		if walker.health < health:
			break
	_check(walker.health < health and walker.statuses.has(EnemyStatuses.SPORED) and not walker.is_hidden(),
		"the sprite walks up the path and bursts on a hidden nightmare: it's hit, Poisoned and revealed")
	await _clean()

	# Inkcap: a Poisoned nightmare it hit leaves ink; another walking that cell gains Spored.
	var ink := _plant("inkcap", Vector2(6, 10))
	var leader = _spawn(Vector2(7, 10))
	ink.hit(leader, 1.0, false, Tower.NO_CRIT)
	var field := BranchKit.InkField.find(ink)
	for i in 20:
		await process_frame
	_check(field.ink_at(leader.get_current_cell()), "a Poisoned nightmare Inkcap hit leaves ink on its cell")
	var follower = _spawn(Vector2(7, 10))
	for i in 75:
		await process_frame
	_check(follower.statuses.has(EnemyStatuses.SPORED), "a nightmare walking the ink gains Spored")
	await _clean()

# --- Dewdrop: Cloudlet, Undercurrent, Jetreed -----------------------------------------------------------------

func _test_dewdrop() -> void:
	# Cloudlet: a rain cloud over the crowd hits everything under it, flyers too, and Soaks them.
	var cloud := _plant("cloudlet", Vector2(6, 6))
	var under = _spawn(Vector2(8, 6))
	var flyer = _spawn(Vector2(8, 7), "res://resource/enemy/crow.tres")
	var hp: int = under.health
	var fly_hp: int = flyer.health if flyer else 0
	BranchKit.release(cloud)
	for i in 40:
		await process_frame
	_check(under.health < hp and under.statuses.has(EnemyStatuses.DAMP), "Cloudlet's rain hits and Soaks what's under it")
	if flyer:
		_check(flyer.health < fly_hp, "…a flyer over it too")
	await _clean()

	# Undercurrent: a whirlpool draws a nightmare past its centre back toward it, never further.
	var pool := _plant("undercurrent", _route_cell(9) + Vector2(0, 1))
	var route := pool._route()
	var ahead = _spawn(route[10])
	ahead.set_path(route)
	ahead._path_index = 11  # Walked past the whirlpool on its own route
	var zone := BranchKit.GroundZone.new(pool, &"whirlpool", Tower.MAP_GRID.calculate_map_position(route[9]), 1.5 * CELL, 3.0, 0.25)
	zone.gather = 0.6
	zone.route_index = 9
	zone.route_length = route.size()
	main.add_child(zone)
	var before: float = ahead.get_remaining_distance()
	for i in 40:
		await process_frame
	_check(ahead.is_dragged() or ahead.get_remaining_distance() > before, "the whirlpool draws a nightmare past its centre back toward it")
	await _clean()

	# Jetreed: an instant jet through a line, +50% on a Soaked nightmare.
	var jet := _plant("jetreed", Vector2(4, 12))
	var dry = _spawn(Vector2(6, 12))
	var wet = _spawn(Vector2(7, 12))
	wet.apply_status(EnemyStatuses.DAMP)
	BranchKit.release(jet)
	var dry_lost: int = dry.max_health - dry.health
	var wet_lost: int = wet.max_health - wet.health
	_check(dry_lost > 0 and wet_lost > dry_lost, "Jetreed's jet pierces the line, harder on the Soaked one (%d vs %d)" % [wet_lost, dry_lost])
	await _clean()

# --- Firefly Jar: Jarlink, Prism Jar, Sparkler ------------------------------------------------------------------

func _test_firefly() -> void:
	# Jarlink: two within 4 cells make an arc; a nightmare on it takes damage and Charged; a Phantom only with the final.
	var a := _plant("jarlink", Vector2(5, 6))
	var b := _plant("jarlink", Vector2(8, 6))
	var crosser = _spawn(Vector2(6.5, 6))
	BranchKit.process(a, 0.016)
	BranchKit.process(b, 0.016)
	_check(crosser.health < crosser.max_health and crosser.statuses.has(EnemyStatuses.STATIC), "a nightmare crossing the Jarlinks' arc is hit and Charged")
	await _clean()

	# Prism Jar: Wardens within 1.5 cells +10% crit; not further away.
	var prism := _plant("prism_jar", Vector2(6, 10))
	var near := _plant("sporeling", Vector2(7, 10))
	var far := _plant("sporeling", Vector2(12, 10))
	_check(is_equal_approx(near.get_crit_chance() - far.get_crit_chance(), 0.10), "Prism Jar: +10%% crit chance beside it (%.2f vs %.2f)" % [near.get_crit_chance(), far.get_crit_chance()])
	await _clean()

	# Sparkler: a burst of sparks over the crowd, each adding Charged.
	var sparkler := _plant("sparkler", Vector2(6, 12))
	var crowd := [_spawn(Vector2(8, 12)), _spawn(Vector2(8, 13))]
	BranchKit.release(sparkler)
	_check(crowd.any(func(e) -> bool: return e.statuses.has(EnemyStatuses.STATIC)), "Sparkler's sparks hit the crowd and add Charged")
	await _clean()

# --- Bellflower: Silver Bell, Hushbell, Thrum ---------------------------------------------------------------------

func _test_bellflower() -> void:
	# Silver Bell: the toll fills Drowsy on the strongest in range.
	var bell := _plant("silver_bell", Vector2(4, 6))
	var weak = _spawn(Vector2(6, 6))
	var strong = _spawn(Vector2(8, 6))
	strong.max_health = 900000
	strong.health = 900000
	BranchKit.release(bell)
	_check(strong.statuses.stacks(EnemyStatuses.DROWSY) == strong.statuses.get_max_stacks(EnemyStatuses.DROWSY)
		and not weak.statuses.has(EnemyStatuses.DROWSY), "Silver Bell's toll fills the strongest one's Drowsy, only it")
	await _clean()

	# Hushbell: nightmares around it are silenced (a Weeper can't mend).
	var hush := _plant("hushbell", Vector2(6, 10))
	var hushed = _spawn(Vector2(7, 10))
	BranchKit.process(hush, 0.3)
	_check(hushed.statuses.silence_time > 0.0, "Hushbell silences the nightmares around it")
	await _clean()

	# Thrum: a cone in front; +30% against Drowsy.
	var thrum := _plant("thrum", Vector2(4, 12))
	thrum.target_chosen = true
	thrum.target_mode = TowerData.TargetMode.STRONGEST
	var front = _spawn(Vector2(6, 12))
	front.max_health = 900000
	front.health = 900000
	var drowsy = _spawn(Vector2(6.3, 12.3))
	drowsy.apply_status(EnemyStatuses.DROWSY)
	var behind = _spawn(Vector2(2, 12))
	BranchKit.release(thrum)
	_check(front.health < front.max_health and behind.health == behind.max_health, "Thrum's cone hits in front, not behind")
	_check(drowsy.max_health - drowsy.health > front.max_health - front.health, "…harder on the Drowsy one")
	await _clean()

func _route_cell(index: int) -> Vector2:
	var map = main.get_node("%MapGenerator")
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	return route[mini(index, route.size() - 1)]

func _spawn(cell: Vector2, path: String = "res://resource/enemy/leaf_bug.tres"):
	if not ResourceLoader.exists(path):
		return null
	var enemy: Node2D = spawner.spawn_enemy(load(path))
	enemy.set_process(false)
	enemy.global_position = Tower.MAP_GRID.calculate_map_position(cell)
	enemy.max_health = 100000
	enemy.health = 100000
	return enemy

func _clean() -> void:
	for child in spawner.get_children():
		child.queue_free()
	for tower in container.get_children():
		tower.queue_free()
	for node in main.get_children():
		if node is BranchKit.GroundZone or node is BranchKit.BroodSprite or node is BranchKit.LineFlash or node is BranchKit.ConeFlash:
			node.queue_free()
	await process_frame

func _plant(id: String, cell: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = cell
	tower.position = Tower.MAP_GRID.calculate_map_position(cell)
	container.add_child(tower)
	tower.set_process(false)
	return tower

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
