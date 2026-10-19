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
const LENT := ["hammerfall", "sparks_fly", "flashover", "chain_of_lanterns", "nothing_wasted",  # Knock-On folded into Hammerfall (2026-10-16); Crossfire retired (hard cards 2026-10-16)
	"thunderstruck", "brushfire", "gathering_storm", "struck_twice"]  # Struck Twice: self-sufficiency audit 2026-10-18
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

	# ...a Hammerfall jump that dispels does not jump again (owner 2026-10-17: that is Bale-fires / Pyre's verb).
	dreams.stacks.clear()
	_take("hammerfall")
	_check(not dreams.has_rule(&"knock_on"), "Hammerfall no longer carries Knock-On's re-jump")
	jar = _plant("firefly_jar", far)
	rock = _plant("pebbling", far + Vector2(CELL, 0))
	await _frames(2)
	hit = _spawn(far + Vector2(CELL * 2, 0))
	var frail = _spawn(far + Vector2(CELL * 2, CELL))
	frail.health = 1
	var beyond = _spawn(far + Vector2(CELL * 2, CELL * 2))
	var beyond_before: float = beyond.health
	thrown = lights.forks_thrown
	rock.hit(hit, 1.0, false, Tower.NO_CRIT)
	await _frames(3)
	_check(lights.forks_thrown == thrown + 1 and (frail.is_cleansed or frail.health <= 0), "...the jump dispels the nightmare it reached")
	_check(is_equal_approx(beyond.health, beyond_before), "...and jumps no further")
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
	# Keyword chips 2026-10-16: any heavy hit fans (the struck nightmare needs no status); only status carriers are targets
	_check(lights.forks_thrown == thrown + 1, "Thunderstruck: a hit on a nightmare without a status still fans to the one with a status")
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

	# Torchbearers (hard cards 2026-10-16): the nearest Lit nightmare further along the path, at most TORCH_STEPS ahead,
	# skipping one another throw just claimed. Reads the poll's sorted list (filled by hand here).
	var behind_lit = _spawn(Vector2(CELL * 20, CELL * 20))
	var ahead_lit = _spawn(Vector2(CELL * 21, CELL * 20))
	var next_lit = _spawn(Vector2(CELL * 22, CELL * 20))
	var too_far = _spawn(Vector2(CELL * 23, CELL * 20))
	lights._lit_by_step = [[8, behind_lit], [13, ahead_lit], [15, next_lit], [15 + lights.TORCH_STEPS + 1, too_far]]
	_check(lights.next_lit_ahead(10, Vector2.ZERO) == ahead_lit, "Torchbearers: the nearest Lit nightmare ahead, never one behind")
	ahead_lit.set_meta(lights.TORCH_CLAIM_META, dreams._game_clock + 1.0)
	_check(lights.next_lit_ahead(10, Vector2.ZERO) == next_lit, "...a nightmare just jumped to is skipped")
	_check(lights.next_lit_ahead(15, Vector2.ZERO) == null, "...nothing past %d steps ahead" % lights.TORCH_STEPS)
	lights._lit_by_step = []
	await _clean()

	# Show the Way (owner 2026-10-17: Firefly's own trait, was +1 stack): a Borrowed Light jump jumps once more, at half,
	# to another Lit nightmare, and never a third time.
	dreams.stacks.clear()
	dreams.calling = "firefly_jar"
	dreams.calling_path.clear()
	dreams.calling_path.append(&"lf_borrowed_light")
	dreams.calling_path.append(&"lf_show_the_way")
	_plant("firefly_jar", far)
	var lender := _plant("sporeling", far + Vector2(CELL * 4, 0))
	await _frames(3)
	var lit_hit = _spawn(far + Vector2(CELL, 0))
	var others: Array = [_spawn(far + Vector2(0, CELL)), _spawn(far + Vector2(-CELL, 0)), _spawn(far + Vector2(0, -CELL))]
	_check(lights.is_lit(lit_hit) and others.all(func(e) -> bool: return lights.is_lit(e)), "(all four nightmares are Lit)")
	var was: Array = others.map(func(e) -> float: return float(e.health))
	thrown = lights.forks_thrown
	lender.hit(lit_hit, 20.0, false, Tower.NO_CRIT)
	await _frames(4)
	var lost: Array = []
	for i in others.size():
		lost.append(float(was[i]) - float(others[i].health))
	lost.sort()
	_check(lights.forks_thrown == thrown + 2, "Show the Way: the Borrowed Light jump jumps once more, and only once (%d)" % (lights.forks_thrown - thrown))
	_check(is_zero_approx(lost[0]) and lost[2] > 0.0, "...two Lit nightmares hit, the third untouched")
	_check(lost[2] > 0.0 and absf(lost[1] / lost[2] - lights.SHOW_SHARE) < 0.1, "...the second jump at half (%.2f)" % (lost[1] / maxf(lost[2], 0.001)))
	dreams.calling_path.clear()
	await _clean()

	await _self_sufficiency(far)

	print("test_class_firefly: %d failures" % failures)
	quit(failures)

# One plain hit's damage on `enemy` from `tower` (no crit). Health is whole numbers (fractions carry), so checks allow 1.
func _hit_loss(tower: Tower, enemy) -> float:
	var was: float = enemy.health
	tower.hit(enemy, 1.0, false, Tower.NO_CRIT)
	return was - float(enemy.health)

# The Firefly self-sufficiency changes (D:\Projects\logs\dream_council\self_sufficiency_audit.md, owner 2026-10-18).
func _self_sufficiency(far: Vector2) -> void:
	# Texts and gates
	var nw: UpgradeData = load("res://resource/dream/nothing_wasted.tres")
	_check(nw.min_act == 1, "Nothing Wasted is offered from act 1")
	_check(nw.description.contains("from Firefly Wardens and Wardens {near} them"), "Nothing Wasted: the approved face")
	var st: UpgradeData = load("res://resource/dream/struck_twice.tres")
	_check(st != null and st.rarity == UpgradeData.Rarity.COMMON and st.min_act == 1 and st.in_start_pool, "Struck Twice: a Common from act 1, in the start pool")
	_check(st.description.contains("Firefly Wardens or Wardens {near} them deals 30% more"), "Struck Twice: the approved face")
	_check(st.uses.has(&"jump") and st.makes.size() + st.uses.size() <= 2, "Struck Twice: uses jump, at most 2 chips")
	var paths: Dictionary = DreamState.CALLING_PATHS.PATHS
	_check(String(paths[&"lf_bonfire"].text).contains("Firefly Wardens deal 25% more there"), "Bonfire: the tough-target line")
	_check(String(paths[&"lf_strung_lights"].text).contains("5% more to a nightmare for each glow it has entered, up to +25%"), "Strung Lights: the route-length line")
	for id in [&"lf_bonfire", &"lf_strung_lights"]:
		_check(String(paths[id].text).split(" ", false).size() <= 25, "%s: face at most 25 words" % id)
	_check(not load("res://resource/dream/spore_ring.tres").tip.contains("clump"), "Spore Huddle: no 'clump'")

	# Nothing Wasted: a Firefly Jar alone (no other family) jumps what the shell stopped.
	dreams.stacks.clear()
	dreams.calling = "sporeling"  # A later owner: the lent card alone
	_take("nothing_wasted")
	var jar := _plant("firefly_jar", far)
	await _frames(2)
	var shelled = _spawn(far + Vector2(CELL * 2, 0))
	shelled.coat = 1000.0
	shelled.coat_max = 1000.0
	shelled._coat_per_hit = 15.0
	var bare = _spawn(far + Vector2(CELL * 2, CELL))
	var bare_before: float = bare.health
	var thrown: int = lights.forks_thrown
	jar.hit(shelled, 1.0, false, Tower.NO_CRIT)
	await _frames(2)
	_check(lights.forks_thrown == thrown + 1 and bare.health < bare_before, "Nothing Wasted: a lone Firefly Jar's shell-stopped damage jumps to the nightmare without a shell")
	await _clean()

	# Struck Twice: a jump readies the next hit from a Firefly Warden or a Warden near one (30% more, once, 2 s).
	dreams.stacks.clear()
	_take("struck_twice")
	jar = _plant("firefly_jar", far)
	var near_sprout := _plant("sprout", far + Vector2(CELL, CELL))  # A non-Firefly Warden near the Jar
	var far_sprout := _plant("sprout", far + Vector2(CELL * 6, 0))  # Not near any Firefly Warden
	await _frames(3)
	var e = _spawn(far + Vector2(CELL * 2, 0))
	var plain := _hit_loss(jar, e)
	await process_frame
	dreams.note_jump(null, null, e, 10.0)
	_check(e.has_meta(lights.STRUCK_META), "Struck Twice: a jump landing marks the nightmare")
	var mark: Array = e.get_meta(lights.STRUCK_META)
	_check(mark.size() > 3 and mark[3] != null and is_instance_valid(mark[3].get_ref()), "...and a spark shows the mark")
	var boosted := _hit_loss(jar, e)
	_check(absf(boosted - plain * lights.STRUCK_BONUS) <= 1.01, "...a Firefly Jar alone: its next hit deals 30%% more (%.2f)" % (boosted / maxf(plain, 0.001)))
	_check(not e.has_meta(lights.STRUCK_META), "...the mark is spent")
	await process_frame
	var after := _hit_loss(jar, e)
	_check(absf(after - plain) <= 1.01, "...the hit after it is plain again (%.3f / %.3f / %.3f)" % [plain, boosted, after])
	await process_frame
	var sprout_plain := _hit_loss(near_sprout, e)
	await process_frame
	dreams.note_jump(null, null, e, 10.0)
	var far_loss := _hit_loss(far_sprout, e)
	_check(e.has_meta(lights.STRUCK_META) and absf(far_loss - sprout_plain) <= 1.01, "...a Warden not near a Firefly Warden neither gains nor spends the mark")
	var sprout_boosted := _hit_loss(near_sprout, e)
	_check(absf(sprout_boosted - sprout_plain * lights.STRUCK_BONUS) <= 1.01, "...a Sprout near the Firefly Jar gains it (%.2f: %.3f / %.3f / far %.3f)" % [sprout_boosted / maxf(sprout_plain, 0.001), sprout_plain, sprout_boosted, far_loss])
	await process_frame
	dreams.note_jump(null, null, e, 10.0)
	_check(is_equal_approx(lights.damage_multiplier(e, jar, &"fork"), 1.0) and e.has_meta(lights.STRUCK_META), "...jumps never spend it (hits only)")
	await process_frame
	dreams.note_jump(jar, null, e, 10.0)
	_check(is_equal_approx(lights.damage_multiplier(e, jar, &""), 1.0) and e.has_meta(lights.STRUCK_META), "...a chain hop's own hit in the same frame never spends the mark it made")
	mark = e.get_meta(lights.STRUCK_META)
	mark[0] = float(mark[0]) - lights.STRUCK_TIME - 0.1
	e.set_meta(lights.STRUCK_META, mark)
	await process_frame
	_check(is_equal_approx(lights.damage_multiplier(e, jar, &""), 1.0), "...the mark fades after 2 s")
	await _clean()

	# Sparks Fly: another Firefly Warden's hit counts (the bug: a Jar's hit overwrote the last Firefly hit before the check).
	dreams.stacks.clear()
	_take("sparks_fly")
	var jar_a := _plant("firefly_jar", far)
	var jar_b := _plant("firefly_jar", far + Vector2(0, CELL * 2))
	await _frames(2)
	var s1 = _spawn(far + Vector2(CELL * 2, 0))
	_spawn(far + Vector2(CELL * 2, CELL))
	thrown = lights.forks_thrown
	for i in 3:  # A, B, A, B, A, B: Jar B's hits after Jar A's count, and its 3rd jumps
		jar_a.hit(s1, 1.0, false, Tower.NO_CRIT)
		await process_frame
		jar_b.hit(s1, 1.0, false, Tower.NO_CRIT)
		await process_frame
	await _frames(1)
	_check(lights.forks_thrown == thrown + 1, "Sparks Fly: a Firefly Jar's hits after another Jar's count (%d)" % (lights.forks_thrown - thrown))
	await _clean()

	# Bonfire: Firefly Wardens' hits on gold path deal 25% more (hits only; a Sprout doesn't).
	dreams.stacks.clear()
	dreams.calling = "firefly_jar"
	dreams.calling_path.clear()
	dreams.calling_path.append(&"lf_bonfire")
	jar = _plant("firefly_jar", far)
	_plant("firefly_jar", far + Vector2(CELL, 0))
	var lone := _plant("firefly_jar", far + Vector2(CELL * 10, 0))
	var sprout := _plant("sprout", far + Vector2(CELL, CELL))
	await _frames(3)
	var gold = _spawn(far + Vector2(CELL * 0.5, CELL * 0.5))
	var dim = _spawn(far + Vector2(CELL * 10, CELL))
	_check(lights.jars_at(lights._lit_sources(gold)) >= 2, "(the nightmare stands on gold path)")
	_check(is_equal_approx(lights.damage_multiplier(gold, jar, &""), lights.BONFIRE_BONUS), "Bonfire: a Firefly Warden's hit on gold path deals 25% more")
	_check(is_equal_approx(lights.damage_multiplier(dim, lone, &""), 1.0), "...off gold path, nothing")
	_check(is_equal_approx(lights.damage_multiplier(gold, sprout, &""), 1.0), "...a Sprout's hit gets nothing")
	_check(is_equal_approx(lights.damage_multiplier(gold, jar, &"fork"), 1.0), "...jumps get nothing")
	dreams.calling_path.clear()
	await _clean()

	# Strung Lights: +5% per glow entered, up to +25%; the same glow twice counts once.
	dreams.calling_path.append(&"lf_strung_lights")
	jar = _plant("firefly_jar", far)
	sprout = _plant("sprout", far + Vector2(CELL, CELL))
	await _frames(2)
	var walker = _spawn(far + Vector2(CELL * 3, 0))
	_check(is_equal_approx(lights.damage_multiplier(walker, jar, &""), 1.0), "Strung Lights: no glow entered, nothing")
	lights._entered(walker, 1)
	lights._entered(walker, 2)
	lights._entered(walker, 2)
	_check(is_equal_approx(lights.damage_multiplier(walker, jar, &""), 1.0 + 2.0 * lights.STRUNG_PER_GLOW), "...2 glows entered: 10% more")
	_check(is_equal_approx(lights.damage_multiplier(walker, sprout, &""), 1.0), "...Firefly Wardens only")
	for light in range(3, 12):
		lights._entered(walker, light)
	_check(is_equal_approx(lights.damage_multiplier(walker, jar, &""), 1.0 + lights.STRUNG_MAX), "...up to +25%")
	dreams.calling_path.clear()
	await _clean()
