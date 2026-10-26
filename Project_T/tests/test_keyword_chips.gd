extends SceneTree
# Keyword chips (owner 2026-10-16; council D:\Projects\logs\dream_council\keyword_chips_decisions.md): the Makes / Uses
# data on Dream cards and Calling evolutions, scripts/run/dream_keywords.gd's lookups, and the one-event-per-keyword
# hooks (Repeat -> Tower.note_repeat_hit, Jump -> DreamState.note_jump, Linger -> EnemyStatuses.is_lingering).
var failures := 0
var main: Node
var spawner
var placer: TowerPlacer
var container: Node
var dreams: DreamState
const CELL := 64.0
const KW := preload("res://scripts/run/dream_keywords.gd")
const PATHS := preload("res://scripts/combat/calling_paths.gd")

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

# --- Data ----------------------------------------------------------------------------------------------------------

func _cards() -> Array[UpgradeData]:
	var out: Array[UpgradeData] = []
	var dir := DirAccess.open("res://resource/dream")
	for file in dir.get_files():
		var name := file.trim_suffix(".remap")
		if name.ends_with(".tres"):
			var card := load("res://resource/dream/" + name) as UpgradeData
			if card != null:
				out.append(card)
	return out

static func _is_power(card: UpgradeData) -> bool:
	return card.kind != UpgradeData.Kind.UNLOCK_WARDEN and card.kind != UpgradeData.Kind.UNLOCK_EVOLUTION

func _check_chip_list(where: String, chips: Array) -> void:
	_check(chips.size() <= KW.MAX_CHIPS, "%s has at most %d chips (%d)" % [where, KW.MAX_CHIPS, chips.size()])
	var made := {}
	var used := {}
	for chip in chips:
		_check(KW.is_known(chip.id), "%s: chip id %s is a known keyword or status word" % [where, chip.id])
		_check(chip.kind == KW.MAKES or chip.kind == KW.USES, "%s: chip kind is makes or uses" % where)
		_check(String(chip.label) != "", "%s: chip %s has a label" % [where, chip.id])
		if chip.kind == KW.MAKES:
			made[chip.id] = true
		else:
			used[chip.id] = true
	for id in made:
		_check(not used.has(id), "%s: %s is not on both sides" % [where, id])

func _data_checks() -> void:
	var makers := {}  # keyword -> where
	var users := {}
	var live := 0
	for card in _cards():
		if card.retired or not _is_power(card):
			_check(card.makes.is_empty() and card.uses.is_empty(), "%s (retired or a Warden unlock) carries no chips" % card.id)
			continue
		live += 1
		var chips := KW.chips_for_card(card)
		_check_chip_list(card.id, chips)
		var derived := KW.derived_uses(card)
		for id in derived:
			_check(not card.uses.has(id), "%s: derived Uses %s is not written by hand too" % [card.id, id])
			_check(chips.any(func(c) -> bool: return c.id == id and c.kind == KW.USES), "%s shows its derived Uses %s" % [card.id, id])
		if card.requires_role != &"" and KW.ROLE_USES.has(card.requires_role):
			_check(derived.has(KW.ROLE_USES[card.requires_role]), "%s: requires_role %s gives Uses %s" % [card.id, card.requires_role, KW.ROLE_USES[card.requires_role]])
		if card.requires_status != &"":
			_check(derived.has(KW.word_for_status(card.requires_status)), "%s: requires_status gives its Uses chip" % card.id)
		for chip in chips:
			if chip.kind == KW.MAKES:
				makers[chip.id] = card.id
			else:
				users[chip.id] = card.id
	_check(live >= 220, "the live power cards are read (%d)" % live)  # Section 35 retired 19 (2026-10-24); sections 36-37 retired more (Deep Frost, the woven Crowned Rares, …: 225 on 2026-10-25)
	var rows := 0
	for id in PATHS.PATHS:
		var row: Dictionary = PATHS.PATHS[id]
		_check(row.has("makes") and row.has("uses"), "Calling row %s has makes and uses keys" % id)
		var chips := KW.chips_for_calling(id)
		_check_chip_list(String(id), chips)
		for chip in chips:
			if chip.kind == KW.MAKES:
				makers[chip.id] = String(id)
			else:
				users[chip.id] = String(id)
		rows += 1
	_check(rows == 137, "137 Calling evolution rows (%d)" % rows)  # Section 33: Finale (Deepen) and cross-over rows; final pass 2026-10-24: 22 new ids
	# Warden roles and statuses count as makers.
	var dir := DirAccess.open("res://resource/tower")
	for file in dir.get_files():
		var name := file.trim_suffix(".remap")
		if not name.ends_with(".tres"):
			continue
		var data := load("res://resource/tower/" + name) as TowerData
		if data == null:
			continue
		for chip in KW.chips_for_warden(data):
			_check(chip.kind == KW.MAKES and KW.is_known(chip.id), "Warden %s chip %s is a known Makes chip" % [name, chip.id])
			makers[chip.id] = name
	for id in KW.WORDS:
		var made := makers.has(id)
		var used := users.has(id)
		for member in KW.MEMBERS.get(id, []):
			made = made or makers.has(member)
			used = used or users.has(member)  # Slow: its users name the exact state (decisions: "Uses Rooted", "Uses Asleep")
		_check(made or id in [&"age", &"order"], "keyword %s has a maker (cards, evolutions or Warden roles)" % id)  # age, order: uses-only words (a Warden's age, its place along the path)
		_check(used or id in [&"potency", &"frost"], "keyword %s has a user" % id)  # Potency: a stat every effect reads, so no card "uses" it (Host Grove makes it); Frost: no Frost-only Dream cards (section 37)
	for id in KW.WORDS:
		var words := String(KW.glossary(id).text).split(" ", false).size()
		_check(words > 0 and words <= 12, "glossary %s is 1-12 words (%d)" % [id, words])
	_check(KW.chips_for_card(load("res://resource/dream/knell.tres")).map(func(c) -> String: return "%s:%s" % [c.kind, c.id]) \
		== ["uses:layered", "makes:repeat"], "Knell: Uses Layered, Makes Repeat (its live rule)")
	# Owner 2026-10-18, bell_lent_review.md: Da Capo is a bell's attack twice on a clock: no Need, no card named, no chips.
	var da_capo: UpgradeData = load("res://resource/dream/da_capo.tres")
	_check(not String(da_capo.description).contains("{card:") and not DreamState.CARD_NEEDS.has("da_capo"), "Da Capo needs no other card")
	_check(KW.chips_for_card(da_capo).is_empty(), "Da Capo carries no chips (a real attack, not a repeated hit)")
	_check(KW.chips_for_card(load("res://resource/dream/rude_awakening.tres")).map(func(c) -> String: return "%s:%s" % [c.kind, c.id]) \
		== ["uses:slow", "makes:repeat"], "Rude Awakening: Uses Slow (Asleep and Root), Makes Repeat")
	# Owner 2026-10-17: four evolutions use their own family's trait (was Sporeling's +1 stack); Shared Spark retired.
	var trait_rows := {&"dw_riverside": &"linger", &"dw_stagnant_water": &"linger", &"lf_show_the_way": &"jump", &"kt_evo_chime_of_many": &"repeat"}
	for id in trait_rows:
		var row: Dictionary = PATHS.PATHS[id]
		_check(row.makes == [trait_rows[id]] and not String(row.text).contains("{stack"), "%s makes %s, never stacks" % [id, trait_rows[id]])
	var spark: UpgradeData = load("res://resource/dream/shared_spark.tres")
	_check(spark.retired and spark.makes.is_empty() and spark.uses.is_empty(), "Shared Spark is retired and carries no chips")
	_check(not String(load("res://resource/dream/hammerfall.tres").description).contains("again"), "Hammerfall's face has no re-jump")

# --- Hooks ---------------------------------------------------------------------------------------------------------

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

func _clean() -> void:
	for child in spawner.get_children():
		child.queue_free()
	for child in container.get_children():
		child.queue_free()
	await process_frame
	dreams.bump_board()

func _hook_checks() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	spawner = main.get_node("%EnemyContainer")
	placer = main.get_node("%TowerPlacer")
	container = main.get_node("%TowerContainer")
	dreams = main.get_node("%DreamState")

	# Repeat: a bell's repeat (keeping_time._again) and the Fifth Beat echo reach the hit-counting Legendary rules.
	var bell := _plant("bellflower", Vector2(5.5, 5.5) * CELL)
	var target := _spawn(Vector2(6.5, 5.5) * CELL)
	_check(dreams.keeping_time != null, "the Keeping Time node exists")
	if dreams.keeping_time != null:
		var before: int = bell._hits_landed
		dreams.keeping_time._again(bell, target, 5.0, &"refrain")
		_check(bell._hits_landed == before + 1, "a bell repeat counts as a hit for Eternal Static / Rooted Nightmares")
	var rules = DreamBuildRules_find(bell)
	if rules != null:
		var before_echo: int = bell._hits_landed
		rules.echoes.append({"at": rules.clock, "target": weakref(target), "source": weakref(bell), "damage": 1.0})
		await process_frame
		await process_frame
		_check(bell._hits_landed == before_echo + 1, "the Fifth Beat echo counts as a hit too")
	await _clean()

	# Jump: chain hops and Firefly forks both reach DreamState.note_jump; Shared Spark (retired from offers 2026-10-17, its rule
	# still runs for an old save) and Gathering Storm read it.
	_take("shared_spark")
	_take("gathering_storm")
	var storm := _plant("stormcap", Vector2(5.5, 5.5) * CELL)
	var a := _spawn(Vector2(6.5, 5.5) * CELL)
	var b := _spawn(Vector2(7.0, 5.5) * CELL)
	a.apply_status(EnemyStatuses.SPORED, 4, 0.0, 1.0, 0, "spore", null)
	var jumps := dreams.jumps_noted
	storm._chain_strike(a)
	_check(dreams.jumps_noted > jumps, "a chain Warden's hop is a Jump (note_jump)")
	_check(b.statuses.has(EnemyStatuses.SPORED), "Shared Spark: the hop carried Poisoned from the first nightmare")
	await _clean()
	var jar := _plant("firefly_jar", Vector2(5.5, 5.5) * CELL)
	var c := _spawn(Vector2(6.5, 5.5) * CELL)
	var d := _spawn(Vector2(7.0, 5.5) * CELL)
	c.apply_status(EnemyStatuses.DAMP, 3, 0.0, 1.0, 0, "water", null)
	var lights = dreams.firefly_lights
	if lights != null:
		jumps = dreams.jumps_noted
		lights._fork(lights._next_event(), jar, c.global_position, d, 5.0, INF)
		lights._flush()
		_check(dreams.jumps_noted == jumps + 1, "a Firefly jump is a Jump (note_jump)")
		_check(d.statuses.has(EnemyStatuses.DAMP), "Shared Spark: the Firefly jump carried Soaked from the nightmare it left")
		var gathered := dreams.note_jump(jar, null, d, 1.0)
		_check(gathered > 1.0, "Gathering Storm reads note_jump: the next jump on that nightmare is stronger (%.2f)" % gathered)
	await _clean()

	# Linger: every Makes Linger path ends in is_lingering; Slow Burn and Old Rain read it.
	var e := _spawn(Vector2(6.5, 5.5) * CELL)
	var s: EnemyStatuses = e.statuses
	e.apply_status(EnemyStatuses.SPORED, 3, 0.0, 1.0, 0, "spore", null)
	_check(not s.is_lingering(EnemyStatuses.SPORED), "a plain landing is not lingering")
	s.linger(EnemyStatuses.SPORED, 1.0)
	_check(s.is_lingering(EnemyStatuses.SPORED), "linger() (Steeped's room, Waterlogged, Homesick, Topped Up) makes it lingering")
	e.apply_status(EnemyStatuses.DAMP, 2, 0.0, 1.0, 0, "water", null)
	s.note_stretched(EnemyStatuses.DAMP, 3.0)
	_check(s.is_lingering(EnemyStatuses.DAMP), "note_stretched() (Ebb) makes it lingering")
	_take("slow_burn")
	# Slow Burn reads the status's age since section 36 (4 s on with no gap), never is_lingering or is_kept
	_check(is_equal_approx(dreams.slow_burn_multiplier(e, &"spored"), 1.0), "Slow Burn: a young Poisoned pays nothing, even lingering")
	s.mark_kept(EnemyStatuses.SPORED)
	_check(is_equal_approx(dreams.slow_burn_multiplier(e, &"spored"), 1.0), "Slow Burn: kept but young still pays nothing")
	s._active[EnemyStatuses.SPORED]["age"] = DreamState.SLOW_BURN_AGE
	_check(is_equal_approx(dreams.slow_burn_multiplier(e, &"spored"), 1.0 + DreamState.SLOW_BURN_BONUS), "Slow Burn: a Poisoned carried 4 s deals more")
	s.static_age_at_bolt = DreamState.SLOW_BURN_AGE_CHARGED - 0.5
	_check(is_equal_approx(dreams.slow_burn_multiplier(e, &"static"), 1.0), "Slow Burn: a bolt from young Charged pays nothing")
	s.static_age_at_bolt = DreamState.SLOW_BURN_AGE_CHARGED
	_check(is_equal_approx(dreams.slow_burn_multiplier(e, &"static"), 1.0 + DreamState.SLOW_BURN_BONUS), "Slow Burn: a bolt from 1.5 s old Charged deals more")
	_check(is_equal_approx(dreams.slow_burn_multiplier(e, &""), 1.0), "Slow Burn: a plain hit does not")
	if dreams.puddles != null:
		_check(dreams.puddles._rain_spends(&"thunderclap", [EnemyStatuses.DAMP]), "Old Rain: Thunderclap spends a lingering Soaked")
		_check(not dreams.puddles._rain_spends(&"thunderclap", [EnemyStatuses.DROWSY]), "Old Rain: …but not a lingering Drowsy")
	var f := _spawn(Vector2(8.5, 5.5) * CELL)
	_take("bound_and_burning")
	f.apply_status(EnemyStatuses.HELD, 1, 2.0, 1.0, 0, "root", null)
	f.apply_status(EnemyStatuses.MARKED, 2, 0.0, 1.0, 0, "light", null)
	f.statuses.tick(0.1)
	_check(f.statuses.is_lingering(EnemyStatuses.MARKED), "Bound and Burning's pause is Linger")
	await _clean()

	# Half set-offs (Heavy Heart, Witching Bend) restore the Reaction damage share.
	_check(is_equal_approx(Reactions._half_share, 1.0), "Reactions deal full damage outside a half set-off")

static func DreamBuildRules_find(near: Node) -> Node:
	var script := load("res://scripts/tower/dream_build_rules.gd")
	return script.find(near)

func _run() -> void:
	_data_checks()
	await _hook_checks()
	if main != null:
		main.queue_free()
	await process_frame
	print("test_keyword_chips: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(failures)
