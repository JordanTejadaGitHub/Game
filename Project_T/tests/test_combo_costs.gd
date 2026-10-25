extends SceneTree

# Headless test for "Combo cards are choices, not musts" (dream_design.md 83c40cd7): the costs Tower Code builds.
# Rolling Thunder (3 arcs), Charged Bloom (one fewer jump), Conductive Soil (jumps use up Soaked), Wildfire Spores
# (spreading burns away its own Poisoned), Mushroom Rain (half as long), Deep Water (near the Heartwood only), Kin and
# Kindling (statuses, no damage), Carried on the Wind (one nightmare), Windborne Rain (seeds 25% less), the Woven
# cards (their Crowned Reaction's cooldown ×2), Starlit Aim (a crit spends half the required Exposed stacks), Rain on Glass (light dries Soaked).
#   godot --headless --path . --script res://tests/test_combo_costs.gd --fixed-fps 60

const CELL := 64.0

var failures := 0
var main: Node
var spawner
var placer: TowerPlacer
var container: Node
var dreams: DreamState

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
	dreams = main.get_node("%DreamState")
	dreams.unlock_everything = true
	for child in spawner.get_children():
		child.queue_free()
	await process_frame

	# Charged Bloom: a Stormcap chain jumps one fewer time.
	var storm := _plant("stormcap", Vector2(4, 4))
	var row := []
	for i in 6:
		row.append(_spawn(Vector2(6, 2 + i)))
	storm._chain_strike(row[0])
	var plain_hits: int = row.filter(func(e) -> bool: return e.health < e.max_health).size()
	await _clean()
	_take("static_bloom")
	storm = _plant("stormcap", Vector2(4, 4))
	row = []
	for i in 6:
		row.append(_spawn(Vector2(6, 2 + i)))
	storm._chain_strike(row[0])
	var bloom_hits: int = row.filter(func(e) -> bool: return e.health < e.max_health).size()
	_check(bloom_hits == plain_hits - 1, "Charged Bloom: the chain jumps one fewer time (%d vs %d)" % [bloom_hits, plain_hits])
	await _clean()

	# Conductive Soil (section 35, Tower Code's capped jump): a Firefly Warden's direct hit on a Soaked nightmare jumps to the
	# Soaked nightmares within 2 cells (at most 4, half damage, once a second per Warden); each jump uses up its Soaked.
	_take("conductive_soil")
	var soil_jar := _plant("firefly_jar", Vector2(4, 4))
	var lead = _spawn(Vector2(6, 4))
	var wet = _spawn(Vector2(6, 5))
	lead.apply_status(EnemyStatuses.DAMP, 8)
	wet.apply_status(EnemyStatuses.DAMP, 8)
	soil_jar.hit(lead, 1.0, false, Tower.NO_CRIT)
	_check(wet.health < wet.max_health and not wet.statuses.has(EnemyStatuses.DAMP), "Conductive Soil: a jump uses up the Soaked it jumped through")
	await _clean()

	# Buildup Dreams reward supporting Wardens without changing attack frequency.
	_take("fireflies_in_the_grass")
	var helper := _plant("sprout", Vector2(3, 3))
	helper._touch_lines["light"] = true
	var sparks = _spawn(Vector2(5, 3))
	helper._catalogue_hit(sparks)
	helper._catalogue_hit(sparks)
	_check(sparks.statuses.stacks(EnemyStatuses.STATIC) == 0, "Fireflies still waits until the third hit")
	helper._catalogue_hit(sparks)
	# (Fireflies in the Grass is retired from offers since the Firefly class prototype: lit Sprouts, no charges.)
	await _clean()
	# Thunder Chimes (section 35): every Bellflower Warden's direct hit adds 1 Charged, once a second per nightmare per Warden
	_take("resonance")
	var chimes := _plant("bellflower", Vector2(3, 3))
	var chime_target = _spawn(Vector2(5, 3))
	chimes.hit(chime_target, 1.0, false, Tower.NO_CRIT)
	_check(chime_target.statuses.stacks(EnemyStatuses.STATIC) == 1, "Thunder Chimes: a Bellflower hit adds 1 Charged (%d)" % chime_target.statuses.stacks(EnemyStatuses.STATIC))
	chimes.hit(chime_target, 1.0, false, Tower.NO_CRIT)
	_check(chime_target.statuses.stacks(EnemyStatuses.STATIC) == 1, "…once a second per nightmare for each Warden")
	await _clean()
	# Rolling Thunder (section 36): the usual arc cap (no 3-arc cap); its cost: nightmares its arcs strike lose their Soaked.
	_take("rolling_thunder")
	var jar := _plant("firefly_jar", Vector2(2, 2))
	var clap = _spawn(Vector2(8, 8))
	var soaked := []
	for i in 6:
		var e = _spawn(Vector2(7 + (i % 3), 9 + i / 3))
		e.apply_status(EnemyStatuses.DAMP, 8)
		soaked.append(e)
	clap.apply_status(EnemyStatuses.DAMP, 8)
	clap.apply_status(EnemyStatuses.STATIC, 10, 0.0, jar.get_damage(), 0, "light", jar)
	var struck: int = soaked.filter(func(e) -> bool: return e.health < e.max_health).size()
	_check(struck == mini(soaked.size(), Reactions.THUNDERCLAP_ARCS_BY_LEVEL[1]), "Rolling Thunder: the nearest Soaked nightmares in reach are struck, up to its cap of 5 (%d)" % struck)
	_check(soaked.filter(func(e) -> bool: return e.statuses.stacks(EnemyStatuses.STATIC) == 2).size() == struck, "Rolling Thunder adds two charges to each arc target")
	_check(soaked.filter(func(e) -> bool: return e.statuses.stacks(EnemyStatuses.DAMP) == 0).size() == struck, "Rolling Thunder's cost: its arc targets lose their Soaked")
	_check(Reactions.THUNDERCLAP_ARC_STATIC[2] == 3, "deepened Rolling Thunder adds three charges")
	await _clean()

	# Wildfire Spores: when Ignite spreads, the burning nightmare loses its own Poisoned.
	_take("wildfire_spores")
	var spore := _plant("sporeling", Vector2(2, 4))
	var burning = _spawn(Vector2(8, 6))
	var beside = _spawn(Vector2(8.5, 6))
	burning.apply_status(EnemyStatuses.SPORED, 16, 0.0, 10.0, 0, "spore", spore)
	Reactions._burn_spread(burning, spore, 1, 0.0, 0)
	_check(beside.statuses.has(EnemyStatuses.SPORED) and not burning.statuses.has(EnemyStatuses.SPORED),
		"Wildfire Spores: spreading 2 Poisoned burns away the burning one's own")
	await _clean()

	# Mushroom Rain: the cloud lasts half as long (and covers the 8 tiles around).
	_take("mushroom_rain")
	spore = _plant("sporeling", Vector2(2, 4))
	var damp = _spawn(Vector2(8, 6))
	damp.apply_status(EnemyStatuses.SPORED, 12, 0.0, 10.0, 0, "spore", spore)
	damp.apply_status(EnemyStatuses.DAMP, 8)  # Mushrooming
	var clouds := main.get_children().filter(func(n) -> bool: return n is ReactionCloud)
	_check(not clouds.is_empty() and is_equal_approx(clouds[0]._duration, Reactions.MUSHROOM_CLOUD_TIME * 0.5)
		and clouds[0]._radius >= Reactions.MUSHROOM_RAIN_RADIUS * CELL - 0.1, "Mushroom Rain: a wide cloud for half as long")
	await _clean()

	# Deep Water: only near the Heartwood (straight line, 5 cells).
	_take("deep_water")
	var map = main.get_node("%MapGenerator")
	var near = _spawn(map.endPath + Vector2(0, -2))
	var far = _spawn(map.endPath + Vector2(0, -9))
	_check(Reactions._near_heartwood(near, dreams, Reactions.DEEP_WATER_REACH) and not Reactions._near_heartwood(far, dreams, Reactions.DEEP_WATER_REACH),
		"Deep Water: works within 5 cells of the Heartwood, not further")
	await _clean()

	# Kin and Kindling: the Harmony strike applies both statuses instead of dealing damage.
	_take("kin_and_kindling")
	var a := _plant("stormcap", Vector2(4, 2))
	var b := _plant("lanternmoth", Vector2(5, 2))
	await process_frame
	var kin := Kinships.find(main)
	kin.refresh()
	var target = _spawn(Vector2(6, 4))
	var before: int = target.health
	kin.note_hit(a, target, 10.0)
	kin.note_hit(b, target, 10.0)
	_check(kin.harmony_run > 0 and target.health == before and target.statuses.has(EnemyStatuses.STATIC),
		"Kin and Kindling: the Harmony strike applies the statuses and deals no damage")
	await _clean()
	kin.refresh()

	# Carried on the Wind: Gust copies full stacks, to one nightmare only.
	_take("carried_on_the_wind")
	var gust := _plant("gust", Vector2(6, 6))
	var marked = _spawn(Vector2(7, 6))
	marked.apply_status(EnemyStatuses.SPORED, 24, 0.0, 10.0, 0, "spore", gust)
	var others := [_spawn(Vector2(7, 7)), _spawn(Vector2(6, 7)), _spawn(Vector2(5, 7))]
	gust._spread()
	var copied: Array = others.filter(func(e) -> bool: return e.statuses.has(EnemyStatuses.SPORED))
	_check(copied.size() == 1 and copied[0].statuses.stacks(EnemyStatuses.SPORED) >= 6, "Carried on the Wind: full stacks, to one nightmare (%d)" % copied.size())
	await _clean()

	# Windborne Rain: Samara seeds deal 25% less.
	_check(is_equal_approx(SeedBoomerang.WINDBORNE_RAIN_DAMAGE, 0.75), "Windborne Rain: seeds deal 25% less")

	# The Woven cards: their Crowned Reaction's cooldown doubles.
	_take("eye_of_the_tempest")
	var crowned = _spawn(Vector2(8, 8))
	Reactions._fire(crowned, &"tempest", [], false, Reactions.CROWNED_LINKS, &"thunderclap")
	var base: float = Reactions.get_data(&"thunderclap").cooldown
	_check(is_equal_approx(crowned.statuses.reaction_cooldowns.get(&"thunderclap", 0.0), base * Reactions.WOVEN_COOLDOWN),
		"Eye of the Tempest: Tempest fires half as often (cooldown %.2f of %.2f)" % [crowned.statuses.reaction_cooldowns.get(&"thunderclap", 0.0), base])
	await _clean()

	# Starlit Aim (section 35): a Heavy Warden's crit on a nightmare with a full status (3/4 of its base cap) uses up half of
	# that status's stacks; a status below full is untouched, and a non-heavy Warden's crit spends nothing
	_take("starlit_aim")
	var heavy := _plant("cairn", Vector2(2, 4))
	spore = _plant("sporeling", Vector2(2, 8))
	var star = _spawn(Vector2(4, 4))
	var full_poison := ceili(star.statuses.base_cap(EnemyStatuses.SPORED) * EnemyStatuses.FULL_SHARE)
	star.apply_status(EnemyStatuses.SPORED, full_poison, 0.0, 1.0, 0, "spore", spore)
	spore.hit(star, 1.0, false, Tower.CRIT)
	_check(star.statuses.stacks(EnemyStatuses.SPORED) >= full_poison, "Starlit Aim: a non-heavy Warden's crit spends nothing")
	heavy.hit(star, 1.0, false, Tower.CRIT)
	_check(star.statuses.stacks(EnemyStatuses.SPORED) <= ceili(full_poison / 2.0), "Starlit Aim: a Heavy crit uses up half of the full status (%d left)" % star.statuses.stacks(EnemyStatuses.SPORED))
	var partial = _spawn(Vector2(4, 6))
	partial.apply_status(EnemyStatuses.SPORED, 4, 0.0, 1.0, 0, "spore", spore)
	heavy.hit(partial, 1.0, false, Tower.CRIT)
	_check(partial.statuses.stacks(EnemyStatuses.SPORED) >= 4, "Starlit Aim: a status below full is not spent")
	await _clean()

	# Rain on Glass: a light Warden's hit dries a Soaked nightmare; other families' don't.
	_take("rain_on_glass")
	var light := _plant("firefly_jar", Vector2(2, 2))
	var other := _plant("sporeling", Vector2(2, 6))
	var glass = _spawn(Vector2(4, 2))
	var puddle = _spawn(Vector2(4, 6))
	glass.apply_status(EnemyStatuses.DAMP, 8)
	puddle.apply_status(EnemyStatuses.DAMP, 8)
	light.hit(glass, 1.0, false, Tower.NO_CRIT)
	other.hit(puddle, 1.0, false, Tower.NO_CRIT)
	_check(not glass.statuses.has(EnemyStatuses.DAMP) and puddle.statuses.has(EnemyStatuses.DAMP), "Rain on Glass: light hits dry the Soaked, others don't")
	await _clean()

	# Sparking Spores (Roguelite e328fb55): Ignite burns hotter only from 20 Poisoned.
	_take("sparking_spores")
	var lighter := _plant("sporeling", Vector2(2, 4))
	var four = _spawn(Vector2(6, 10))
	var five = _spawn(Vector2(10, 10))
	four.apply_status(EnemyStatuses.SPORED, 16, 0.0, 10.0, 0, "spore", lighter)
	five.apply_status(EnemyStatuses.SPORED, 20, 0.0, 10.0, 0, "spore", lighter)
	Reactions.burn(four, lighter)
	Reactions.burn(five, lighter)
	_check(five.statuses.burn_rate > four.statuses.burn_rate + 1.0,  # Reaction cards scale both burns (Reactions._rx_cards)
		"Sparking Spores: hotter from 20 Poisoned, not at 16 (%.2f / %.2f)" % [four.statuses.burn_rate, five.statuses.burn_rate])
	await _clean()

	# Quick Reactions (Roguelite e328fb55): Reactions deal 35% less; a Charged bolt isn't a Reaction.
	var plain_clap := Reactions._rx(main, 100.0)
	_take("quick_reactions")
	_check(is_equal_approx(plain_clap, 100.0) and is_equal_approx(Reactions._rx(main, 100.0), 100.0 * dreams.get_reaction_damage_multiplier())
		and dreams.get_reaction_damage_multiplier() < 1.0, "Quick Reactions: Reaction damage ×%.2f" % dreams.get_reaction_damage_multiplier())
	var bolted = _spawn(Vector2(12, 4))
	Reactions.strike_bolt(bolted, 100.0, null)
	_check(bolted.max_health - bolted.health >= 99, "…a Charged bolt keeps its full damage (%d)" % (bolted.max_health - bolted.health))
	await _clean()

	_take("brimming")
	spore = _plant("sporeling", Vector2(2, 4))
	var brim_heavy := _plant("cairn", Vector2(2, 6))  # Section 35: only a Heavy Warden's crit spends
	var brim_star = _spawn(Vector2(5, 4))
	brim_star.apply_status(EnemyStatuses.MARKED, 20, 0.0, 0.0, 0, "light", spore)
	brim_heavy.hit(brim_star, 1.0, false, Tower.CRIT)
	_check(brim_star.statuses.stacks(EnemyStatuses.MARKED) == 10, "Starlit Aim: Brimming crit leaves ten stacks")
	await _clean()

	print("combo costs test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	Kinships.force_full = false
	main.queue_free()
	await process_frame
	quit(failures)

func _take(card_id: String) -> void:
	for card in dreams.pool:
		if card.id == card_id:
			dreams.take(card)
			return
	_check(false, "(setup) card %s exists" % card_id)

func _plant(id: String, cell: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = cell
	tower.position = Tower.MAP_GRID.calculate_map_position(cell)
	container.add_child(tower)
	tower.set_process(false)
	return tower

func _spawn(cell: Vector2):
	var enemy: Node2D = spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
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
		if node is ReactionCloud:
			node.queue_free()
	await process_frame

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
