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

	# Thunderstruck (non-status builds 2026-10-19): another family's heavy Warden near a Firefly Warden: its hit fans
	# THUNDER_SHARE to up to THUNDER_MAX near it that a Warden hit in the last THUNDER_RECENT s (was: carrying a status), the
	# whole fan at most THUNDER_CAP_SECONDS of the Firefly Warden's damage.
	dreams.stacks.clear()
	_take("thunderstruck")
	jar = _plant("firefly_jar", far)
	var t_rock := _plant("pebbling", far + Vector2(CELL, 0))
	await _frames(2)
	var struck = _spawn(far + Vector2(CELL * 2, 0))
	var soaked = _spawn(far + Vector2(CELL * 2, CELL))
	_spawn(far + Vector2(CELL * 2, -CELL))  # Not hit lately: the fan skips it (one fork, not two)
	soaked.set_meta(lights.THUNDER_HIT_META, lights._now())  # Hit just now (any Warden)
	thrown = lights.forks_thrown
	t_rock.hit(struck, 1.0, false, Tower.NO_CRIT)
	await _frames(2)
	_check(lights.forks_thrown == thrown + 1, "Thunderstruck: a heavy hit fans only to the nightmare hit lately (no status needed)")
	soaked.set_meta(lights.THUNDER_HIT_META, lights._now())
	t_rock.remove_meta(lights.HEAVY_META)  # A new heavy attack
	thrown = lights.forks_thrown
	var soaked_before: float = soaked.health
	t_rock.hit(struck, 1.0, false, Tower.NO_CRIT)
	await _frames(2)
	var fan_cap: float = jar.get_damage() * jar.get_attacks_per_second() * lights.THUNDER_CAP_SECONDS
	_check(lights.forks_thrown == thrown + 1 and soaked.health < soaked_before, "...a second heavy attack fans to it again (%d)" % (lights.forks_thrown - thrown))
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
	await _f1_checks(far)

	print("test_class_firefly: %d failures" % failures)
	quit(failures)

# Every damage event's [tag, calling] while `on` (F1 checks).
var _seen_events: Array = []

func _note_event(event) -> void:
	_seen_events.append([event.tag, event.calling, event.enemy])

# One Lantern jump struck at once (firefly_lights._strike), marked as a Calling output or not.
func _jump(source, target, amount: float, calling: bool) -> float:
	var was: float = target.health
	lights._strike({"event": lights._next_event(), "source": source, "from": source.global_position, "target": target,
		"amount": amount, "cap": INF, "calling": calling})
	return was - float(target.health)

# F1 lent × Calling and F4 (owner 2026-10-18; D:\Projects\logs\dream_council\f1_spec.md).
func _f1_checks(far: Vector2) -> void:
	dreams.stacks.clear()
	dreams.calling = "firefly_jar"
	dreams.calling_path.clear()
	# F1: a Lantern jump counts as a hit by its Warden for Dewdrop's High Tide…
	_take("high_tide")
	var jar := _plant("firefly_jar", far)
	_plant("dewdrop", far + Vector2(CELL, 0))  # Near the Jar
	await _frames(3)
	var e = _spawn(far + Vector2(CELL * 2, 0))
	e.apply_status(EnemyStatuses.DAMP, 1, 20.0, 1.0, 0, "water", null)
	e.apply_status(EnemyStatuses.MARKED, 1, 20.0, 1.0, 0, "light", null)
	var tide: float = 1.0 + minf(dreams.puddles.HIGH_TIDE_PER * e.statuses.count(), dreams.puddles.HIGH_TIDE_MAX)
	var plain := _jump(jar, e, 100.0, false)
	await process_frame
	var marked := _jump(jar, e, 100.0, true)
	_check(plain > 0.0 and absf(marked - plain * tide) <= 1.01, "F1: a Lantern jump gets High Tide like the Jar's hit (%.0f vs %.0f, x%.2f)" % [marked, plain, tide])
	_check(DamageLog.calling_next == &"" and DamageLog.calling_now == &"", "F1: nothing stays armed after the jump")
	await _clean()

	# …and for Bellflower's In Time (a Jar touching a bell); its own family's Struck Twice never reads it as a hit
	dreams.stacks.clear()
	_take("in_time")
	_take("struck_twice")
	jar = _plant("firefly_jar", far)
	_plant("bellflower", far + Vector2(CELL, 0))  # Touching the Jar
	await _frames(3)
	var t = _spawn(far + Vector2(CELL * 2, 0))
	var kt = dreams.keeping_time
	_jump(jar, t, 10.0, false)
	await process_frame
	_check(int(t.get_meta(kt.IN_TIME_META, {}).get(jar.get_instance_id(), 0)) == 0, "(an unmarked jump never counts for In Time)")
	_jump(jar, t, 10.0, true)
	await process_frame
	_check(int(t.get_meta(kt.IN_TIME_META, {}).get(jar.get_instance_id(), 0)) == 1, "F1: a Lantern jump counts as the Jar's hit for In Time")
	t.set_meta(lights.STRUCK_META, [dreams._game_clock, -1, 0, null])
	DamageLog.calling_now = &"firefly_jar"
	var own_family: float = lights.damage_multiplier(t, jar, &"fork")
	DamageLog.calling_now = &"bellflower"
	var other_family: float = lights.damage_multiplier(t, jar, &"toll")
	DamageLog.calling_now = &""
	_check(is_equal_approx(own_family, 1.0), "F1: never for its own family (Struck Twice ignores the Lantern jump)")
	_check(is_equal_approx(other_family, lights.STRUCK_BONUS), "F1: another family's Calling output (a Toll) spends Struck Twice like a hit")
	await _clean()

	# Never chains: Refrain's repeat inside a Calling jump's dispatch is not marked
	dreams.stacks.clear()
	_take("refrain")
	jar = _plant("firefly_jar", far)
	var bell := _plant("bellflower", far + Vector2(CELL * 3, 0))
	await _frames(3)
	var r = _spawn(far + Vector2(CELL * 2, 0))
	bell.hit(r, 1.0, false, Tower.NO_CRIT)  # The bell's hit readies Refrain
	await process_frame
	_seen_events.clear()
	DamageLog.instance.damage_dealt.connect(_note_event)
	_jump(jar, r, 10.0, true)
	DamageLog.instance.damage_dealt.disconnect(_note_event)
	var jump_calling := _seen_events.filter(func(row) -> bool: return row[0] == &"fork" and row[1] == &"firefly_jar")
	var repeats := _seen_events.filter(func(row) -> bool: return row[0] == &"refrain")
	_check(jump_calling.size() == 1, "F1: the jump is marked as Lantern Light's output")
	_check(repeats.size() == 1 and repeats.all(func(row) -> bool: return row[1] == &""), "F1: Refrain answers it, and its repeat is never marked (%s)" % [repeats])
	await _clean()

	# F4: Borrowed Light's jump and Hammerfall's from one hit go to different nightmares
	dreams.stacks.clear()
	dreams.calling_path.append(&"lf_borrowed_light")
	_take("hammerfall")
	jar = _plant("firefly_jar", far)
	var rock := _plant("pebbling", far + Vector2(CELL * 2, 0))  # Another family's heavy Warden near the Jar
	await _frames(3)
	var hit = _spawn(far + Vector2(CELL, 0))
	var nearest = _spawn(far + Vector2(CELL, CELL))  # The nearest Lit nightmare to the hit one
	var second = _spawn(far + Vector2(0, CELL))
	_check(lights.is_lit(hit) and lights.is_lit(nearest) and lights.is_lit(second), "(the three nightmares are Lit)")
	var n0: float = nearest.health
	var s0: float = second.health
	var thrown: int = lights.forks_thrown
	rock.hit(hit, 1.0, false, Tower.NO_CRIT)
	await _frames(3)
	_check(lights.forks_thrown == thrown + 2 and nearest.health < n0 and second.health < s0,
		"F4: Borrowed Light and Hammerfall fan out to two nightmares (%d jumps)" % (lights.forks_thrown - thrown))
	_check(String(DreamState.CALLING_PATHS.PATHS[&"lf_borrowed_light"].tip).contains("go to different nightmares"), "F4: Borrowed Light's tip says so")
	dreams.calling_path.clear()
	dreams.stacks.clear()
	await _clean()

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
	_check(nw.description.contains("from {family:firefly_jar} Wardens and Wardens {near} them"), "Nothing Wasted: the approved face")
	var st: UpgradeData = load("res://resource/dream/struck_twice.tres")
	_check(st != null and st.rarity == UpgradeData.Rarity.COMMON and st.min_act == 1 and st.in_start_pool, "Struck Twice: a Common from act 1, in the start pool")
	_check(st.description.contains("{family:firefly_jar} Wardens or Wardens {near} them deals 30% more"), "Struck Twice: the approved face")
	_check(st.uses.has(&"jump") and st.makes.size() + st.uses.size() <= 2, "Struck Twice: uses jump, at most 2 chips")
	var paths: Dictionary = DreamState.CALLING_PATHS.PATHS
	_check(String(paths[&"lf_bonfire"].text).contains("makes another Warden's next direct hit on that nightmare crit"), "Bonfire: the waiting-crit line (rebuilt 2026-10-23)")
	_check(String(paths[&"lf_strung_lights"].text).contains("4% more damage for each glow it has entered, up to +20%"), "Strung Lights: the route-length line (rebuilt 2026-10-23)")
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

	# --- Calling evolutions rebuilt 2026-10-23 (dream_council_review.md 33; evo_fixed_firefly.md) -------------------------
	await _rebuilt_rows(far)

# The path set by hand (tests skip the Dream screen): the statics Tower reads are rebuilt as _choose_calling does.
func _path(ids: Array) -> void:
	dreams.calling = "firefly_jar"
	dreams.calling_path.assign(ids)
	dreams._rebuild_calling_flags()

func _rebuilt_rows(far: Vector2) -> void:
	var thrown: int = 0
	dreams.stacks.clear()  # (No lent card from the checks above)
	var cells: Array = dreams._path_index.keys()
	cells.sort_custom(func(a, b) -> bool: return int(dreams._path_index[a]) < int(dreams._path_index[b]))
	var mid: Vector2 = Tower.MAP_GRID.calculate_map_position(cells[cells.size() / 2])  # On the route: gold cells are route cells
	var paths: Dictionary = DreamState.CALLING_PATHS.PATHS
	var lf_live: Array = []
	for id in paths:
		if String(id).begins_with("lf_") and DreamState.CALLING_PATHS.is_live(id):
			lf_live.append(id)
	_check(lf_live.size() == 21, "Lantern Light: 21 live rows (%d)" % lf_live.size())
	for id in [&"lf_torchbearers", &"lf_bale_fires", &"lf_glowworms", &"lf_swarm_night", &"lf_embers", &"lf_witchfire"]:
		_check(paths.has(id) and not DreamState.CALLING_PATHS.is_live(id), "%s is kept, retired (old saves)" % id)
	for id in lf_live:
		var words := (String(paths[id].text) + " " + String(paths[id].tip)).to_lower()
		_check(not words.contains("silver") and not words.contains("set off") and not words.contains("go off"), "%s: 'pale path', 'trigger'" % id)
	_check(int(paths[&"lf_parting_light"].tier) == DreamState.CALLING_PATHS.DEEPEN and int(paths[&"lf_banked_fire"].tier) == DreamState.CALLING_PATHS.DEEPEN,
		"Deepens are DEEPEN rows")
	_check(Array(paths[&"lf_borrowed_light"].keeps_out) == [&"sparks_fly", &"hammerfall"] and Array(paths[&"lf_pyre"].keeps_out) == [&"old_hand"],
		"keeps_out: Borrowed Light keeps Sparks Fly and Hammerfall out, Pyre Old Hand")
	_path([&"lf_bonfire"])
	_check(DreamState.calling_crit_on and not DreamState.calling_mult_on, "Bonfire turns the forced-crit hook on")
	_check(dreams.calling_keeps_out(load("res://resource/dream/sparks_fly.tres")) == false, "(Sparks Fly offered without Borrowed Light)")
	_path([&"lf_borrowed_light"])
	_check(dreams.calling_keeps_out(load("res://resource/dream/sparks_fly.tres")), "Borrowed Light keeps Sparks Fly out of the offers")
	_path([&"lf_strung_lights"])
	_check(DreamState.calling_mult_on and not DreamState.calling_crit_on, "Strung Lights turns the Calling hit multiplier on")

	# Strung Lights (kept id, new meaning): any Warden's direct hit on a nightmare inside a Firefly glow, 4% per glow, +20% at
	# most. Old effect gone: no Firefly-only bonus in damage_multiplier and no joined gaps.
	var jar := _plant("firefly_jar", far)
	var sprout := _plant("sprout", far + Vector2(CELL, CELL))
	await _frames(2)
	var inside = _spawn(far + Vector2(CELL, 0))
	var outside = _spawn(far + Vector2(CELL * 6, 0))
	lights._entered(inside, 1)
	lights._entered(inside, 2)
	lights._entered(inside, 2)
	lights._entered(outside, 1)
	_check(is_equal_approx(lights.damage_multiplier(inside, jar, &""), 1.0), "Strung Lights: old effect gone (no Firefly bonus in damage_multiplier)")
	_check(not lights.has_method("_string_lights") and lights._strung.is_empty(), "...and no joined gaps")
	_check(is_equal_approx(lights.hit_multiplier(jar, inside, false, false, &""), 1.0 + 2.0 * lights.STRUNG_PER_GLOW), "...2 glows entered: 8% more")
	_check(is_equal_approx(lights.hit_multiplier(sprout, inside, false, false, &""), 1.0 + 2.0 * lights.STRUNG_PER_GLOW), "...any Warden's direct hit")
	_check(is_equal_approx(lights.hit_multiplier(jar, outside, false, false, &""), 1.0), "...only inside a Firefly glow")
	_check(is_equal_approx(lights.hit_multiplier(jar, inside, false, false, &"conducted"), 1.0), "...not jumps")
	for light in range(3, 12):
		lights._entered(inside, light)
	_check(is_equal_approx(lights.hit_multiplier(jar, inside, false, false, &""), 1.0 + lights.STRUNG_MAX), "...up to +20%")
	_check(is_equal_approx(dreams._calling_hit_multiplier(jar, inside, false, false, &""), 1.0 + lights.STRUNG_MAX), "...through DreamState's Calling branch")
	await _clean()

	# Far Lights (kept id, new meaning): a far entry is a flare, never 2 glows for Strung (old effect gone). Off the route a
	# nightmare has no steps, like a flyer: every glow is far. Flares: at most one second of the Firefly's damage, one a second.
	_path([&"lf_strung_lights", &"lf_far_lights"])
	jar = _plant("firefly_jar", far)
	await _frames(2)
	var walker = _spawn(far + Vector2(CELL, 0))
	var was: float = walker.health
	var light := _light_of(jar)
	lights._entered(walker, light)
	var flare: float = was - float(walker.health)
	var top: float = minf(jar.get_damage(), jar.get_damage() * jar.get_attacks_per_second()) * jar._form_hit_multiplier()
	_check(flare > 0.0, "Far Lights: a far glow flares the nightmare")
	_check((walker.get_meta(lights.GLOWS_META, {}) as Dictionary).size() == 1, "...and counts as one glow (old effect gone)")
	was = walker.health
	lights._left(walker, light)
	lights._entered(walker, light)
	_check(is_equal_approx(float(walker.health), was), "...each Firefly flares once a second")
	_check(flare <= top * 4.0 + 1.0, "...a flare is at most one second of the Firefly's hit (x the card cap)")
	await _clean()

	# Lantern Road: from the 4th glow every entry flares at double; Parting Light flares on the way out at half (own clock).
	_path([&"lf_strung_lights", &"lf_far_lights", &"lf_lantern_road", &"lf_parting_light"])
	jar = _plant("firefly_jar", far)
	await _frames(2)
	walker = _spawn(far + Vector2(CELL, 0))
	walker.set_meta(lights.GLOWS_META, {1: [1, 0], 2: [1, 0], 3: [1, 0]})
	light = _light_of(jar)
	was = walker.health
	lights._entered(walker, light)
	var road: float = was - float(walker.health)
	was = walker.health
	lights._left(walker, light)
	var parting: float = was - float(walker.health)
	_check(road > 0.0 and parting > 0.0 and parting < road, "Lantern Road flares the 4th glow at double; Parting Light flares the exit at half (%.1f / %.1f)" % [road, parting])
	await _clean()

	# Bonfire (kept id, new meaning): a Firefly's hit on gold readies another Warden's next direct hit as a crit. Old effect
	# gone: no +25% on gold, no 2 jumps from a dispel there.
	_path([&"lf_bonfire"])
	jar = _plant("firefly_jar", far)
	_plant("firefly_jar", far + Vector2(CELL, 0))
	var rock := _plant("pebbling", far + Vector2(0, CELL))
	await _frames(3)
	var gold = _spawn(far + Vector2(CELL * 0.5, CELL * 0.5))
	_check(lights.gold_level(gold) >= 1, "(the nightmare stands on gold path)")
	_check(is_equal_approx(lights.damage_multiplier(gold, jar, &""), 1.0), "Bonfire: old effect gone (no +25% on gold)")
	_check(not lights.calling_crit(rock, gold), "...no waiting crit before a Firefly's hit")
	_hit_loss(jar, gold)
	await process_frame
	_check(gold.has_meta(lights.WAIT_META), "...a Firefly's hit on gold readies a waiting crit")
	_check(not lights.calling_crit(jar, gold), "...never for the Firefly that readied it")
	_check(lights.calling_crit(rock, gold) and not gold.has_meta(lights.WAIT_META), "...another Warden's next direct hit crits and spends it")
	_check(not lights.calling_crit(rock, gold), "...one waiting crit per nightmare")
	var g1 = _spawn(far + Vector2(CELL * 0.5, -CELL * 0.5))
	var g2 = _spawn(far + Vector2(-CELL * 0.5, CELL * 0.5))
	var g3 = _spawn(far + Vector2(-CELL * 0.5, -CELL * 0.5))
	g1.health = 1
	thrown = lights.forks_thrown
	jar.hit(g1, 1.0, false, Tower.NO_CRIT)
	await _frames(3)
	_check(lights.forks_thrown - thrown <= 1, "...a dispel on gold jumps once, as the Calling (old 2 jumps gone: %d)" % (lights.forks_thrown - thrown))
	g2.queue_free()
	g3.queue_free()
	await _clean()

	# Moth to Flame (kept id, new meaning): no Exposed from jumps on gold (old effect gone); the highest-rank Warden over the
	# gold gets its own kept crit, +50% after 4 other hits; the shared waiting crit still goes to anyone.
	_path([&"lf_bonfire", &"lf_moth_to_flame"])
	jar = _plant("firefly_jar", mid)
	_plant("firefly_jar", mid + Vector2(CELL, 0))
	var tall := _plant("pebbling", mid + Vector2(0, CELL))
	tall.rank = 3
	rock = _plant("pebbling", mid + Vector2(CELL, CELL))
	await _frames(3)
	gold = _spawn(mid + Vector2(CELL * 0.5, CELL * 0.5))
	lights._strike({"event": lights._next_event(), "source": jar, "from": jar.global_position, "target": gold, "amount": 5.0, "cap": INF})
	_check(gold.statuses.stacks(EnemyStatuses.MARKED) == 0, "Moth to Flame: old effect gone (a jump on gold adds no Exposed)")
	_hit_loss(jar, gold)
	await process_frame
	_check(gold.has_meta(lights.MOTH_META) and int(gold.get_meta(lights.MOTH_META)[0]) == tall.get_instance_id(), "...a Firefly's hit keeps a crit for the highest-rank Warden")
	_check(lights.calling_crit(rock, gold) and gold.has_meta(lights.MOTH_META), "...another Warden takes only the shared waiting crit")
	for i in lights.MOTH_HITS:
		_hit_loss(rock, gold)
		await process_frame
	_check(lights.calling_crit(tall, gold), "...the holder's next direct hit crits")
	_check(is_equal_approx(lights.hit_multiplier(tall, gold, false, true, &""), lights.MOTH_BONUS), "...for 50% more after 4 other hits")
	await _clean()

	# Pyre (kept id, new meaning): no re-jump from a jump that dispels on gold (old effect gone); on white path every 2nd
	# direct hit from a rank V+ Warden crits.
	_path([&"lf_bonfire", &"lf_moth_to_flame", &"lf_pyre"])
	jar = _plant("firefly_jar", far)
	_plant("firefly_jar", far + Vector2(CELL, 0))
	_plant("firefly_jar", far + Vector2(0, CELL))
	tall = _plant("pebbling", far + Vector2(CELL, CELL))
	await _frames(3)
	var white = _spawn(far + Vector2(CELL * 0.5, CELL * 0.5))
	_check(lights.gold_level(white) == 2, "(the nightmare stands on white path)")
	_check(not lights.calling_crit(tall, white) and not lights.calling_crit(tall, white), "Pyre: a Warden below rank V never crits")
	tall.rank = 5
	var beats := [lights.calling_crit(tall, white), lights.calling_crit(tall, white), lights.calling_crit(tall, white), lights.calling_crit(tall, white)]
	_check(beats == [false, true, false, true], "...rank V: every 2nd direct hit on white crits (%s)" % [beats])
	var frail_w = _spawn(far + Vector2(CELL * 0.5, CELL * 0.6))
	frail_w.health = 1
	_spawn(far + Vector2(CELL * 0.6, CELL * 0.5))
	thrown = lights.forks_thrown
	lights._strike({"event": lights._next_event(), "source": jar, "from": jar.global_position, "target": frail_w, "amount": 50.0, "cap": INF})
	await _frames(3)
	_check(lights.forks_thrown - thrown == 1, "...old effect gone: a jump that dispels on gold jumps no further (%d)" % (lights.forks_thrown - thrown))
	await _clean()

	# Flint and Steel: a crit on gold passes to the touching Warden with gold in range; its next direct hit there crits.
	_path([&"lf_bonfire", &"lf_spreading_flame", &"lf_flint_and_steel"])
	_plant("firefly_jar", mid)
	_plant("firefly_jar", mid + Vector2(CELL, 0))
	var first := _plant("pebbling", mid + Vector2(0, CELL * 2))  # Two cells from the Fireflies: only the partner touches it
	var partner := _plant("pebbling", mid + Vector2(CELL, CELL * 2))
	await _frames(3)
	gold = _spawn(mid + Vector2(CELL * 0.5, CELL * 0.5))
	first.hit(gold, 1.0, false, Tower.CRIT)  # A real crit on gold
	await process_frame
	_check(partner.has_meta(lights.PASS_META), "Flint and Steel: a crit on gold passes to the touching Warden")
	_check(lights.calling_crit(partner, gold) and not partner.has_meta(lights.PASS_META), "...its next direct hit on gold crits")
	await _clean()

	# Lantern Wake (kept id, new meaning): other families' Wardens touching a Firefly glow too; old effect gone (no carried statuses).
	_path([&"lf_borrowed_light", &"lf_lantern_wake"])
	jar = _plant("firefly_jar", far)
	var hugger := _plant("sporeling", far + Vector2(CELL, 0))
	await _frames(3)
	_check(lights._wake_ids.has(hugger.get_instance_id()), "Lantern Wake: a Warden touching the Firefly glows")
	var by_hugger = _spawn(far + Vector2(CELL * 2.2, 0))
	_check(lights.is_lit(by_hugger) and lights.jars_at(lights._lit_sources(by_hugger)) == 0, "...the path touching it is Lit (not a Firefly's own glow)")
	var wake_light: int = lights._wake_ids[hugger.get_instance_id()].light if lights._wake_ids.has(hugger.get_instance_id()) else -1
	_check(wake_light == _light_of(jar), "...with the Firefly's own light id")
	_check(not lights._reveals(lights._lit_sources(by_hugger)), "...it never reveals hidden nightmares")
	_check(not lights.has_method("_carry_of"), "...old effect gone: jumps carry no statuses")
	await _clean()

	# Full Glow: a nightmare hit by a glowing Warden stays Lit for 3 s wherever it walks (never revealing hidden ones).
	_path([&"lf_borrowed_light", &"lf_lantern_wake", &"lf_show_the_way", &"lf_full_glow"])
	jar = _plant("firefly_jar", far)
	hugger = _plant("sporeling", far + Vector2(CELL, 0))
	await _frames(3)
	var away = _spawn(far + Vector2(CELL * 6, 0))
	_check(not lights.is_lit(away), "(a nightmare far from every light)")
	hugger.hit(away, 1.0, false, Tower.NO_CRIT)
	await process_frame
	_check(lights.is_lit(away) and not lights._reveals(lights._lit_sources(away)), "Full Glow: hit by a glowing Warden, it stays Lit off the light")
	await _clean()

	# Sightline / Constellation (kept ids, new meaning): pale path; old effects gone (no 3-hit quarter jumps, no Exposed fill).
	_path([&"lf_borrowed_light", &"lf_sightline", &"lf_constellation"])
	jar = _plant("firefly_jar", far)
	var hitters: Array = [_plant("sprout", far + Vector2(CELL * 3, 0)), _plant("sprout", far + Vector2(CELL * 3, CELL)),
		_plant("sprout", far + Vector2(CELL * 3, -CELL))]
	await _frames(3)
	var target = _spawn(far + Vector2(CELL, 0))
	var other = _spawn(far + Vector2(CELL, CELL))
	_check(not lights.is_pale(target), "(off the route: no pale path)")
	for h in hitters:
		h.hit(target, 1.0, false, Tower.NO_CRIT)
		await process_frame
	_check(not target.has_meta(lights.STAR_META) and target.statuses.stacks(EnemyStatuses.MARKED) == 0, "Constellation: old effect gone (no Exposed); off pale path no star")
	lights._pale[target.get_current_cell()] = true
	target.remove_meta(lights.STAR_ROSTER_META)
	for h in hitters:
		lights._pale[target.get_current_cell()] = true  # (Set again each time: the light map's rebuild clears it)
		h.remove_meta(lights.LAMP_META)
		h.hit(target, 1.0, false, Tower.NO_CRIT)
		await process_frame
	_check(int(target.get_meta(lights.STAR_META, 0)) == lights.STAR_HITS, "...3 Wardens on pale path within 2 s light a star (3 full jumps)")
	var before_other: float = other.health
	hitters[0].remove_meta(lights.LAMP_META)
	hitters[0].hit(target, 1.0, false, Tower.NO_CRIT)
	await _frames(2)
	_check(other.health < before_other and int(target.get_meta(lights.STAR_META, 0)) == lights.STAR_HITS - 1, "...a hit under the star jumps and spends one")
	await _clean()
	dreams.calling_path.clear()
	dreams._rebuild_calling_flags()
	_check(not DreamState.calling_crit_on and not DreamState.calling_mult_on, "(the statics are off again)")

# A Firefly Warden's light id (DreamState.firefly_lights._sources), -1 when it has none.
func _light_of(jar) -> int:
	for source in lights._sources:
		if source.tower == jar and not source.sprout:
			return int(source.light)
	return -1
