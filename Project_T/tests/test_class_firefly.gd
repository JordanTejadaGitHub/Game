extends SceneTree
# The Firefly Jar class after "lent cards never give the Calling's abilities" (owner 2026-10-14,
# documentation/dream_council_review.md 25-26). Written 2026-10-14 and NOT RUN: the owner runs tests only when asked.
# A later owner gets no glow, no Lit and no lights; the lent cards jump from Firefly Wardens, where Wardens stand and
# Charged, and another family's jumps are always capped. Numbers come from firefly_lights.gd's constants.
var failures := 0
var main: Node
var spawner
var placer: TowerPlacer
var container: Node
var dreams: DreamState
var lights  # DreamState.firefly_lights
const CELL := 64.0
const CLASS := ["where_lights_meet", "fireflies_in_the_grass", "signal_fires", "last_spark", "lanternway"]
const LENT := ["hammerfall", "sparks_fly", "flashover", "chain_of_lanterns", "nothing_wasted", "crossfire",  # Knock-On folded into Hammerfall (2026-10-16)
	"thunderstruck", "brushfire", "gathering_storm"]
const SETUP_WORDS := ["{lit}", " lit ", "light ", "lights", "glow", "water", "lone", "{toll}", "toll", " ring", "pip", "mushroom", "dose"]

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _plant(id: String, at: Vector2) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = (at / CELL).floor()
	tower.position = at
	container.add_child(tower)
	tower.set_process(false)
	dreams.bump_board()
	return tower

func _spawn(at: Vector2) -> Node2D:
	spawner.spawn_enemy(load("res://resource/enemy/leaf_bug.tres"))
	var enemy = spawner.get_child(spawner.get_child_count() - 1)
	enemy.set_process(false)
	enemy.global_position = at
	enemy.max_health = 1000000
	enemy.health = 1000000
	enemy.coat = 0.0
	return enemy

func _take(id: String) -> void:
	dreams.take(load("res://resource/dream/%s.tres" % id))

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _clean() -> void:
	for child in spawner.get_children():
		child.queue_free()
	for child in container.get_children():
		child.queue_free()
	await process_frame
	dreams.bump_board()

func _setup() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	spawner = main.get_node("%EnemyContainer")
	placer = main.get_node("%TowerPlacer")
	container = main.get_node("%TowerContainer")
	dreams = main.get_node("%DreamState")
	lights = dreams.firefly_lights

func _run() -> void:
	await _setup()
	_check(lights != null, "the Firefly node is made")

	# 5 class-only and 10 lent (owner 2026-10-14); no lent text or tip names the Calling's setup.
	for id in CLASS:
		var card: UpgradeData = load("res://resource/dream/%s.tres" % id)
		_check(card.calling == "firefly_jar" and card.retired and not card.tags.has(DreamState.LENT_TAG), "%s is a retired class card (the Calling evolves instead, 2026-10-16)" % id)
	for id in LENT:
		var card: UpgradeData = load("res://resource/dream/%s.tres" % id)
		_check(card.tags.has(DreamState.LENT_TAG) and card.calling == "" and card.requires.has("firefly_jar") and not card.retired, "%s is a lent Firefly card" % id)
		_check(lights.LENT_RULES.has(card.rule_id), "%s's rule (%s) is one firefly_lights.gd reads" % [id, card.rule_id])
		var words := (" " + card.description + " " + card.tip + " ").to_lower()
		for word in SETUP_WORDS:
			_check(not words.contains(word), "%s never names the Calling's setup (%s)" % [id, word.strip_edges()])
	_check(load("res://resource/dream/spotlight.tres").retired, "Spotlight is retired (Thunderstruck took its slot)")
	_check(load("res://resource/dream/last_spark.tres").rarity == UpgradeData.Rarity.UNCOMMON, "Last Spark is Uncommon")

	# A later owner holding every lent card: no glow, nothing Lit.
	dreams.calling = "sporeling"
	for id in LENT:
		_take(id)
	var far := Vector2(CELL * 30, CELL * 30)
	var jar := _plant("firefly_jar", far)
	await _frames(3)
	var a = _spawn(far + Vector2(CELL, 0))
	_check(not lights._lit_on() and lights._glow.is_empty() and not lights.is_lit(a), "a later owner: no glow, nothing Lit")
	await _clean()

	# Hammerfall: another family's heavy Warden near a Firefly Warden jumps half of each attack, capped.
	dreams.stacks.clear()
	_take("hammerfall")
	jar = _plant("firefly_jar", far)
	var rock := _plant("pebbling", far + Vector2(CELL, 0))
	await _frames(2)
	var hit = _spawn(far + Vector2(CELL * 2, 0))
	var next = _spawn(far + Vector2(CELL * 2, CELL))
	var before: float = next.health
	var thrown: int = lights.forks_thrown
	rock.hit(hit, 1.0, false, Tower.NO_CRIT)
	await _frames(2)
	var cap: float = jar.get_damage() * jar.get_attacks_per_second() * lights.BRIGHTNESS_SECONDS
	_check(lights.forks_thrown == thrown + 1 and next.health < before, "Hammerfall: the heavy hit jumps to the nearest other nightmare")
	_check(before - next.health <= cap + 1.0, "...never more than 3 s of the Firefly Warden near it")
	await _clean()

	# ...a Firefly Warden's own heavy form does not count.
	dreams.stacks.clear()
	_take("hammerfall")
	var moth := _plant("lanternmoth", far)
	_plant("firefly_jar", far + Vector2(CELL, 0))
	await _frames(2)
	var m1 = _spawn(far + Vector2(CELL * 2, 0))
	_spawn(far + Vector2(CELL * 2, CELL))
	thrown = lights.forks_thrown
	moth.hit(m1, 1.0, false, Tower.NO_CRIT)
	await _frames(2)
	_check(lights.forks_thrown == thrown, "Hammerfall: Lanternmoth (Firefly's own heavy form) jumps nothing")
	await _clean()

	# Sparks Fly: every 3rd hit on a nightmare a Firefly Warden hit in the last 2 s.
	dreams.stacks.clear()
	_take("sparks_fly")
	jar = _plant("firefly_jar", far)
	var sprout := _plant("sprout", far + Vector2(CELL * 4, 0))
	await _frames(2)
	var s1 = _spawn(far + Vector2(CELL * 2, 0))
	_spawn(far + Vector2(CELL * 2, CELL))
	thrown = lights.forks_thrown
	for i in 3:
		sprout.hit(s1, 1.0, false, Tower.NO_CRIT)
		await process_frame
	_check(lights.forks_thrown == thrown, "Sparks Fly: nothing on a nightmare no Firefly Warden hit")
	jar.hit(s1, 1.0, false, Tower.NO_CRIT)
	await process_frame
	thrown = lights.forks_thrown
	for i in 3:
		sprout.hit(s1, 1.0, false, Tower.NO_CRIT)
		await process_frame
	await _frames(1)
	_check(lights.forks_thrown == thrown + 1, "...after a Firefly Warden's hit, the 3rd hit jumps (%d)" % (lights.forks_thrown - thrown))
	await _clean()

	# Thunderstruck (trait rework 2026-10-15): another family's heavy Warden near a Firefly Warden: its hit on a nightmare
	# carrying ANY status (not only Charged) fans THUNDER_SHARE to up to THUNDER_MAX near it that carry a status, the whole
	# fan at most THUNDER_CAP_SECONDS of the Firefly Warden's damage.
	dreams.stacks.clear()
	_take("thunderstruck")
	jar = _plant("firefly_jar", far)
	var t_rock := _plant("pebbling", far + Vector2(CELL, 0))
	await _frames(2)
	var struck = _spawn(far + Vector2(CELL * 2, 0))
	var soaked = _spawn(far + Vector2(CELL * 2, CELL))
	_spawn(far + Vector2(CELL * 2, -CELL))  # No status: the fan skips it (one fork, not two)
	soaked.apply_status(EnemyStatuses.DAMP, 1, 4.0, 1.0, 0, "water", null)
	thrown = lights.forks_thrown
	t_rock.hit(struck, 1.0, false, Tower.NO_CRIT)
	await _frames(2)
	_check(lights.forks_thrown == thrown, "Thunderstruck: nothing when the struck nightmare carries no status")
	struck.apply_status(EnemyStatuses.DAMP, 1, 4.0, 1.0, 0, "water", null)  # Soaked, not Charged
	t_rock.remove_meta(lights.HEAVY_META)  # A new heavy attack
	thrown = lights.forks_thrown
	var soaked_before: float = soaked.health
	t_rock.hit(struck, 1.0, false, Tower.NO_CRIT)
	await _frames(2)
	var fan_cap: float = jar.get_damage() * jar.get_attacks_per_second() * lights.THUNDER_CAP_SECONDS
	_check(lights.forks_thrown == thrown + 1 and soaked.health < soaked_before, "...a Soaked nightmare fans to the one near it with a status (%d)" % (lights.forks_thrown - thrown))
	_check(soaked_before - soaked.health <= fan_cap + 1.0, "...never more than %.1f s of the Firefly Warden" % lights.THUNDER_CAP_SECONDS)
	await _clean()

	# Fireflies in the Grass: chosen at a rest only (fix 12).
	dreams.stacks.clear()
	dreams.calling = "firefly_jar"
	_take("fireflies_in_the_grass")
	_plant("firefly_jar", far)
	var glow_sprout := _plant("sprout", far + Vector2(CELL * 8, 0))
	await _frames(2)
	var director = dreams.drift_director
	var was_resting: bool = director.resting
	director.resting = false
	_check(lights.lit_sprout_blocker(glow_sprout) == "choose at a rest", "Fireflies in the Grass: not mid-drift")
	director.resting = true
	_check(lights.lit_sprout_blocker(glow_sprout) == "", "...at a rest it can glow")
	director.resting = was_resting
	await _clean()

	print("test_class_firefly: %d failures" % failures)
	quit(failures)
