extends SceneTree

var failures := 0
var main: Node
var made: Array[Node] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var charge := EnemyStatuses.new()
	_check(charge.get_max_stacks(EnemyStatuses.STATIC) == 20, "normal bolts need twenty charges")
	var damage := 0.0
	for i in 19:
		damage += charge.apply(EnemyStatuses.STATIC, 1, 0.0, 2.0)
	_check(damage == 0.0 and charge.stacks(EnemyStatuses.STATIC) == 19, "nineteen charges cannot discharge")
	damage = charge.apply(EnemyStatuses.STATIC, 1, 0.0, 2.0)
	_check(is_equal_approx(damage, 32.0) and not charge.has(EnemyStatuses.STATIC), "twentieth charge pays off at sixteen times potency")
	var boss := EnemyStatuses.new()
	boss.is_boss = true
	_check(boss.get_max_stacks(EnemyStatuses.STATIC) == 30, "bosses need thirty charges")
	var sleepy := EnemyStatuses.new()
	sleepy.apply(EnemyStatuses.DROWSY, 5)
	_check(not sleepy.is_catchable() and is_equal_approx(sleepy.get_speed_multiplier(), 0.9), "five Drowsy provides light control, not a full payoff")
	sleepy.apply(EnemyStatuses.DROWSY, 15)
	_check(sleepy.is_catchable() and is_equal_approx(sleepy.get_speed_multiplier(), 0.6), "twenty Drowsy retains bounded forty percent slow")
	_check(EnemyStatuses.DEFAULT_MAX_STACKS[EnemyStatuses.SPORED] == 32, "Poisoned has room for several appliers")
	for id in [EnemyStatuses.DAMP, EnemyStatuses.HELD]:
		var s := EnemyStatuses.new()
		s.apply(id)
		_check(s.has(id) and s.get_max_stacks(id) > 1, "basic %s works immediately with buildup headroom" % id)

	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var tower: Tower = main.get_node("%TowerPlacer").tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/driftspore.tres")
	tower.cell = Vector2(2, 2)
	main.get_node("%TowerContainer").add_child(tower)
	tower.set_process(false)
	var mushroom := _enemy(Vector2(12, 8))
	mushroom.apply_status(EnemyStatuses.SPORED, 11, 0.0, 2.0, 0, "spore", tower)
	mushroom.apply_status(EnemyStatuses.DAMP, 8, 0.0, 0.0, 0, "water", tower)
	_check(mushroom.statuses.mushroom_time == 0.0, "eleven poison stacks cannot trigger Mushrooming")
	mushroom.apply_status(EnemyStatuses.SPORED, 1, 0.0, 2.0, 0, "spore", tower)
	_check(mushroom.statuses.mushroom_time > 0.0, "twelve poison and eight Soaked trigger Mushrooming")
	var low_water := _enemy(Vector2(17, 8))
	low_water.apply_status(EnemyStatuses.SPORED, 12, 0.0, 2.0, 0, "spore", tower)
	low_water.apply_status(EnemyStatuses.DAMP, 1, 0.0, 0.0, 0, "water", tower)
	_check(low_water.statuses.mushroom_time == 0.0, "one Soaked application cannot bypass buildup")
	var ignite := _enemy(Vector2(22, 8))
	ignite.apply_status(EnemyStatuses.SPORED, 12, 0.0, 2.0, 0, "spore", tower)
	ignite.apply_status(EnemyStatuses.STATIC, 1, 0.0, 2.0, 0, "light", tower)
	_check(ignite.statuses.burn_time == 0.0, "one charge cannot trigger Ignite")
	ignite.apply_status(EnemyStatuses.STATIC, 7, 0.0, 2.0, 0, "light", tower)
	_check(ignite.statuses.burn_time > 0.0, "eight charges and twelve poison trigger Ignite")
	var smother := _enemy(Vector2(27, 8))
	smother.apply_status(EnemyStatuses.SPORED, 12, 0.0, 2.0, 0, "spore", tower)
	smother.apply_status(EnemyStatuses.HELD, 1, 3.0, 0.0, 0, "root", tower)
	_check(is_equal_approx(smother.statuses.tick(0.5), 12.0), "one Rooted stack cannot accelerate poison below the Smother gate")
	smother.apply_status(EnemyStatuses.HELD, 3, 3.0, 0.0, 0, "root", tower)
	# Smother stores its Poisoned while Rooted (owner 2026-10-17, council reactions_unique.md; was x3 ticks)
	_check(is_equal_approx(smother.statuses.tick(0.5), 0.0) and is_equal_approx(smother.statuses.smother_stored, 12.0),
		"four Rooted and twelve poison: Smother stores the tick instead (%.1f stored)" % smother.statuses.smother_stored)
	var shatter := _enemy(Vector2(32, 8))
	shatter.apply_status(EnemyStatuses.DAMP, 8, 0.0, 0.0, 0, "water", tower)
	shatter.apply_status(EnemyStatuses.HELD, 1, 3.0, 0.0, 0, "root", tower)
	_check(not Reactions.before_hit(shatter, tower, true).shatter, "one Rooted stack cannot unlock Shatter")
	shatter.apply_status(EnemyStatuses.HELD, 3, 3.0, 0.0, 0, "root", tower)
	_check(Reactions.before_hit(shatter, tower, true).shatter, "four Rooted and eight Soaked unlock Shatter")
	var tempest := _enemy(Vector2(37, 8))
	tempest.apply_status(EnemyStatuses.DAMP, 8, 0.0, 0.0, 0, "water", tower)
	tempest.apply_status(EnemyStatuses.SPORED, 6, 0.0, 2.0, 0, "spore", tower)
	tempest.apply_status(EnemyStatuses.STATIC, 10, 0.0, 2.0, 0, "light", tower)
	_check(tempest.statuses.tempest_time > 0.0, "Tempest's third-status gate is reachable before Mushrooming consumes Soaked")
	var partial := EnemyStatuses.new()
	partial.apply(EnemyStatuses.STATIC, 8, 0.0, 2.0)
	_check(is_equal_approx(partial.stored_bolt_damage(), 12.8), "early releases scale with eight of twenty stored charges")
	var drown := _enemy(Vector2(12, 15))
	drown.apply_status(EnemyStatuses.DAMP, 7, 0.0, 0.0, 0, "water", tower)
	drown.apply_status(EnemyStatuses.DROWSY, 20, 0.0, 0.0, 0, "song", tower)
	_check(drown.statuses.drowned == 0, "seven Soaked cannot trigger Drown even with full Drowsy")
	drown.apply_status(EnemyStatuses.DAMP, 1, 0.0, 0.0, 0, "water", tower)
	_check(drown.statuses.drowned == 1, "eight Soaked and full Drowsy trigger Drown")
	var pinned := _enemy(Vector2(17, 15))
	pinned.apply_status(EnemyStatuses.MARKED, 9, 0.0, 0.0, 0, "light", tower)
	pinned.apply_status(EnemyStatuses.HELD, 4, 3.0, 0.0, 0, "root", tower)
	_check(not pinned.statuses.pinned, "nine Exposed cannot unlock Pinned")
	pinned.apply_status(EnemyStatuses.MARKED, 1, 0.0, 0.0, 0, "light", tower)
	_check(pinned.statuses.pinned, "ten Exposed and four Rooted unlock Pinned")
	var still := _enemy(Vector2(22, 15))
	still.apply_status(EnemyStatuses.HELD, 1, 3.0, 0.0, 0, "root", tower)
	still.apply_status(EnemyStatuses.DAMP, 8, 0.0, 0.0, 0, "water", tower)
	var pools_before := main.get_children().filter(func(n: Node) -> bool: return n is CrownedGround and n.kind == CrownedGround.Kind.STILL_POOL).size()
	still.apply_status(EnemyStatuses.DROWSY, 20, 0.0, 0.0, 0, "song", tower)
	var pools_after := main.get_children().filter(func(n: Node) -> bool: return n is CrownedGround and n.kind == CrownedGround.Kind.STILL_POOL).size()
	_check(still.statuses.drowned == 1 and pools_after == pools_before, "one Rooted permits Drown but cannot upgrade it to Still Pool")
	var dreams: DreamState = main.get_node("%DreamState")
	dreams.take(load("res://resource/dream/brimming.tres"))
	await process_frame
	var brim := EnemyStatuses.new()
	_check(brim.get_max_stacks(EnemyStatuses.STATIC) == 40, "Brimming doubles Charged buildup")
	_check(brim.get_max_stacks(EnemyStatuses.DAMP) == 16 and brim.get_max_stacks(EnemyStatuses.MARKED) == 20 and brim.get_max_stacks(EnemyStatuses.HELD) == 8, "Brimming doubles all six buildup caps")
	# Brimming no longer doubles what a Reaction needs (owner 2026-10-16, option A; balance_simulation.md "Human run 41"):
	# every Reaction fires at its normal need, and hits x2.2 only when the nightmare carries twice the normal need of every
	# status it needs (full Drowsy: the doubled cap); otherwise x1.
	var brim_mushroom := _enemy(Vector2(30, 20))
	brim_mushroom.apply_status(EnemyStatuses.SPORED, 12, 0.0, 2.0, 0, "spore", tower)
	brim_mushroom.apply_status(EnemyStatuses.DAMP, 8, 0.0, 0.0, 0, "water", tower)
	_check(brim_mushroom.statuses.mushroom_time > 0.0 and is_equal_approx(brim_mushroom.statuses.reaction_payoff(&"mushrooming"), 1.0),
		"Brimming: Mushrooming fires at its normal need, without the payoff")
	var big_mushroom := _enemy(Vector2(32, 20))
	big_mushroom.apply_status(EnemyStatuses.SPORED, 24, 0.0, 2.0, 0, "spore", tower)
	big_mushroom.apply_status(EnemyStatuses.DAMP, 16, 0.0, 0.0, 0, "water", tower)
	_check(big_mushroom.statuses.mushroom_time > 0.0 and is_equal_approx(big_mushroom.statuses.reaction_payoff(&"mushrooming"), 2.2),
		"…at twice every need it hits x2.2")
	# Mushrooming is a zone (owner 2026-10-17, council reactions_unique.md): no faster Poisoned, +30% effect damage inside
	var mushroom_probe := EnemyStatuses.new()
	mushroom_probe.apply(EnemyStatuses.SPORED, 24, 5.0, 2.0)
	mushroom_probe.mushroom_time = 4.0
	_check(is_equal_approx(mushroom_probe.tick(0.5), 24.0), "the zone no longer speeds Poisoned ticks")
	var no_zone := _enemy(Vector2(34, 22))
	var plain_effect := Reactions.effect_multiplier(no_zone, tower)
	_check(brim_mushroom.statuses.mushroom_time > 0.0 and is_equal_approx(Reactions.effect_multiplier(brim_mushroom, tower), plain_effect * (1.0 + Reactions.MUSHROOM_ZONE_BONUS)),
		"a Mushrooming fired below twice its needs: +30% effect damage inside, without the 2.2")
	_check(is_equal_approx(Reactions.effect_multiplier(big_mushroom, tower), plain_effect * (1.0 + Reactions.MUSHROOM_ZONE_BONUS * 2.2)),
		"one fired at twice its needs scales the zone's bonus by 2.2")
	_check(is_equal_approx(Reactions._rx(big_mushroom, 10.0, &"mushrooming"), 22.0) and is_equal_approx(Reactions._rx(brim_mushroom, 10.0, &"mushrooming"), 10.0),
		"Reaction damage: x2.2 where it was earned, x1 where not")
	var brim_clap := _enemy(Vector2(35, 20))
	brim_clap.apply_status(EnemyStatuses.DAMP, 8, 0.0, 0.0, 0, "water", tower)
	brim_clap.apply_status(EnemyStatuses.STATIC, 20, 0.0, 2.0, 0, "light", tower)
	_check(not brim_clap.statuses.has(EnemyStatuses.STATIC), "Brimming: eight Soaked and ten Charged set off a Thunderclap")
	var plain_clap := Reactions.THUNDERCLAP_DAMAGE * tower.get_damage() * tower.get_potency()
	_check(absf((brim_clap.max_health - brim_clap.health) - plain_clap) <= 1.0, "…x1: it had eight Soaked, not sixteen")
	var big_clap := _enemy(Vector2(37, 20))
	big_clap.apply_status(EnemyStatuses.DAMP, 16, 0.0, 0.0, 0, "water", tower)
	big_clap.apply_status(EnemyStatuses.STATIC, 20, 0.0, 2.0, 0, "light", tower)
	var expected_clap := Reactions.THUNDERCLAP_DAMAGE * tower.get_damage() * 2.2 * tower.get_potency()
	_check(absf((big_clap.max_health - big_clap.health) - expected_clap) <= 1.0, "sixteen Soaked and twenty Charged: the 2.2x payoff, once")
	var brim_pin := _enemy(Vector2(10, 25))
	brim_pin.apply_status(EnemyStatuses.MARKED, 20, 0.0, 0.0, 0, "light", tower)
	brim_pin.apply_status(EnemyStatuses.HELD, 4, 3.0, 0.0, 0, "root", tower)
	_check(brim_pin.statuses.pinned, "Brimming: Pinned needs only its normal four Rooted")
	_check(is_equal_approx(Reactions.before_hit(brim_pin, tower, false).crit_multiplier, Reactions.PINNED_MULTIPLIER), "…x1 (four Rooted, not eight)")
	var big_pin := _enemy(Vector2(12, 25))
	big_pin.apply_status(EnemyStatuses.HELD, 8, 3.0, 0.0, 0, "root", tower)
	big_pin.apply_status(EnemyStatuses.MARKED, 20, 0.0, 0.0, 0, "light", tower)
	_check(big_pin.statuses.pinned and is_equal_approx(Reactions.before_hit(big_pin, tower, false).crit_multiplier, Reactions.PINNED_MULTIPLIER * 2.2),
		"twenty Exposed and eight Rooted: Pinned's stronger payoff")
	var brim_exposed := EnemyStatuses.new()
	brim_exposed.apply(EnemyStatuses.MARKED, 19)
	_check(is_equal_approx(brim_exposed.get_damage_taken_multiplier(), 1.0), "Brimming Exposed gives no bonus at nineteen stacks")
	brim_exposed.apply(EnemyStatuses.MARKED, 1)
	_check(is_equal_approx(brim_exposed.get_damage_taken_multiplier(), 1.25), "Brimming Exposed activates at twenty stacks")
	var burst := brim.apply(EnemyStatuses.STATIC, 40, 0.0, 2.0)
	_check(is_equal_approx(burst, 70.4), "Brimming's longer wait gives a 2.2x discharge")
	print("status buildup test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _enemy(cell: Vector2) -> Node2D:
	var spawner = main.get_node("%EnemyContainer")
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"), 1.0)
	var enemy: Node2D = spawner.get_child(spawner.get_child_count() - 1)
	enemy.global_position = cell * 64.0 + Vector2(32, 32)
	enemy.set_process(false)
	enemy.max_health = 1000000
	enemy.health = 1000000
	return enemy

func _check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + label)