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
	await _test_finals()
	await _test_named_pairs()

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

	# Undercurrent (tower_design.md "Branch review"): the whirlpool links the nightmares in it; 25% of a hit on one
	# reaches each other one (effect damage, never shared again); nightmares outside aren't linked.
	var pool := _plant("undercurrent", _route_cell(9) + Vector2(0, 1))
	var route := pool._route()
	var struck = _spawn(route[9])
	var partner = _spawn(route[9])
	var outside = _spawn(route[16])
	BranchKit.release(pool)  # It opens where the nightmares are
	for i in 20:
		await process_frame
	var partner_before: int = partner.health
	var outside_before: int = outside.health
	var probe := _plant("sporeling", Vector2(2, 2))
	await process_frame
	probe.hit(struck, 10.0, false, Tower.NO_CRIT)
	var shared: int = partner_before - partner.health
	_check(shared > 0 and outside.health == outside_before, "Undercurrent: a hit on a linked nightmare is shared with the other (%d), not outside" % shared)
	var zone = struck.get_meta(BranchKit.LINK_META) if struck.has_meta(BranchKit.LINK_META) else null
	_check(zone != null and zone.linked.size() == 2 and is_equal_approx(zone.link_share, 0.25), "the whirlpool links the 2 inside at 25%")
	await _clean()

	# A silenced Lantern Bearer's Wraiths are lost; they find the way when the silence ends.
	var hush := _plant("hushbell", Vector2(6, 10))
	var bearer: Node2D = spawner.spawn_enemy(load("res://resource/enemy/mother_duck.tres"))
	bearer.set_process(false)
	await process_frame
	var wraiths: Array = bearer.dew_followers.filter(func(w) -> bool: return is_instance_valid(w))
	for w in wraiths:
		w.set_process(false)
	BranchKit.silence(bearer, 1.0, hush)
	_check(not wraiths.is_empty() and wraiths.all(func(w) -> bool: return w.lost), "a silenced Lantern Bearer's Wraiths are lost (%d)" % wraiths.size())
	_check(bearer.sprite.sprite_frames.resource_path.ends_with("_silenced.tres"), "…and its lantern goes dark (the silenced frames)")
	bearer.statuses.silence_time = 0.0
	for i in 30:
		await process_frame
	_check(wraiths.all(func(w) -> bool: return not w.lost), "…and find the way again when the silence ends")
	_check(bearer.sprite.sprite_frames == bearer.enemy_data.sprite_frames, "…its lantern lit again")
	await _clean()


	# Jetreed (tower_design.md "Branch review"): erosion: its target loses 2% of its max health per hit on top of the
	# small hit; the jet carries on down the line with the small hit only.
	var jet := _plant("jetreed", Vector2(4, 12))
	var aim = _spawn(Vector2(6, 12))
	var beyond = _spawn(Vector2(7, 12))
	jet.target_chosen = true
	jet.target_mode = TowerData.TargetMode.CLOSEST
	BranchKit.release(jet)
	var aim_lost: int = aim.max_health - aim.health
	var beyond_lost: int = beyond.max_health - beyond.health
	var cap := 4.0 * jet.get_damage()  # The erosion is at most 4× the hit
	_check(beyond_lost > 0 and aim_lost > beyond_lost * 2 and aim_lost <= beyond_lost + int(cap) + 2,
		"Jetreed: the target loses a share of its max health, capped at 4× the hit; the line only the small hit (%d vs %d)" % [aim_lost, beyond_lost])
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

	# Jarlinks across the route (Balancing: partners there read ~0.03×): a nightmare walking between them is struck by
	# the arc, the hit tagged "fence".
	var map = main.get_node("%MapGenerator")
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var k := 8
	var along: Vector2 = (route[k + 1] - route[k]).normalized()
	var across := Vector2(along.y, -along.x)
	var left := _plant("jarlink", route[k] + across * 2)
	var right := _plant("jarlink", route[k] - across * 2)
	left.set_process(true)
	right.set_process(true)
	var walker = _spawn(route[k - 2])
	walker.set_path(route)
	walker._path_index = k - 1
	walker.set_process(true)
	var fence_hits := []
	var walker_id: int = walker.get_instance_id()
	var on_damage := func(event) -> void:
		if is_instance_valid(event.enemy) and event.enemy.get_instance_id() == walker_id and event.tag == &"fence":
			fence_hits.append(event.tag)
	var log := DamageLog.instance
	if log:
		log.damage_dealt.connect(on_damage)
	for i in 180:
		await process_frame
		if not fence_hits.is_empty():
			break
	_check(not fence_hits.is_empty(), "a nightmare walking between two Jarlinks across the route is struck by the arc (tagged fence)")
	if log:
		log.damage_dealt.disconnect(on_damage)
	await _clean()

	# Prism Jar: Wardens within 1.5 cells +10% crit; not further away.
	var prism := _plant("prism_jar", Vector2(6, 10))
	var near := _plant("sporeling", Vector2(7, 10))
	var far := _plant("sporeling", Vector2(12, 10))
	_check(is_equal_approx(near.get_crit_chance() - far.get_crit_chance(), BranchKit.p(prism, "crit_aura", 0.15)) and is_equal_approx(BranchKit.crit_damage_aura(near), BranchKit.p(prism, "crit_damage_aura", 0.25)) and BranchKit.crit_damage_aura(far) == 0.0,
		"Prism Jar: more crit chance and crit damage beside it (%.2f vs %.2f)" % [near.get_crit_chance(), far.get_crit_chance()])
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

# --- The finals' twists ---------------------------------------------------------------------------------------------

func _test_finals() -> void:
	# Hatchery: every 5th sprite is big and splits into 3 when it bursts.
	var hatch := _plant("hatchery", _route_cell(10) + Vector2(0, 1))
	for i in 5:
		BranchKit._hatch(hatch)
	var sprites := root.find_children("*", "Node2D", true, false).filter(func(n) -> bool: return n is BranchKit.BroodSprite)
	_check(sprites.filter(func(s) -> bool: return s.big).size() == 1, "Hatchery: the 5th sprite is big")
	await _clean()

	# Deliquescent: a Poisoned nightmare it marked melts into an ink pool when dispelled.
	var deli := _plant("deliquescent", Vector2(6, 6))
	var melting = _spawn(Vector2(7, 6))
	deli.hit(melting, 1.0, false, Tower.NO_CRIT)
	var field := BranchKit.InkField.find(deli)
	var cell: Vector2 = melting.get_current_cell()
	field._on_dispelled(melting)
	_check(field.ink_at(cell), "Deliquescent: a dispelled Poisoned nightmare leaves an ink pool")
	await _clean()

	# Nimbus (tower_design.md "Branch review"): every 4 s its clouds drift to the busiest spot in range, leaving
	# what they pass Soaked.
	var nimbus := _plant("nimbus", Vector2(6, 10))
	var crowd_a = _spawn(Vector2(8, 10))
	BranchKit.release(nimbus)
	var cloud = main.get_children().filter(func(n) -> bool: return n is BranchKit.GroundZone and n.kind == &"rain").front()
	var start: Vector2 = cloud.global_position
	crowd_a.queue_free()
	await process_frame
	var crowd := [_spawn(Vector2(6, 13)), _spawn(Vector2(6, 13)), _spawn(Vector2(6, 13))]
	var passed = _spawn(Vector2(7, 11.5))
	nimbus.set_meta(&"cloud_drift", 0.01)
	BranchKit.process(nimbus, 0.1)
	for i in 50:
		await process_frame
	_check(cloud.global_position.distance_to(start) > 32.0, "Nimbus: the cloud drifts to the busiest spot")
	_check(passed.statuses.has(EnemyStatuses.DAMP), "…Soaking what it passes")
	await _clean()

	# Torrent: the jet leaves a wet trail on the path.
	var torrent := _plant("torrent", _route_cell(8) + Vector2(0, 1))
	var route := torrent._route()
	var in_line = _spawn(route[8])
	BranchKit.release(torrent)
	var trails := main.get_children().filter(func(n) -> bool: return n is BranchKit.GroundZone and n.kind == &"wet")
	_check(not trails.is_empty(), "Torrent: the jet leaves a wet trail (%d tiles)" % trails.size())
	await _clean()

	# Lightning Fence: catches flyers crossing it; a Jarlink fence doesn't.
	var a := _plant("lightning_fence", Vector2(5, 12))
	var b := _plant("lightning_fence", Vector2(8, 12))
	var crow = _spawn(Vector2(6.5, 12), "res://resource/enemy/crow.tres")
	BranchKit.process(a, 0.016)
	_check(crow.health < crow.max_health and crow.statuses.stacks(EnemyStatuses.STATIC) >= 3, "Lightning Fence: a gliding flyer on it is hit and takes 3 Charged at once")
	await _clean()
	# Side-by-side jars make no arc, so a jar links past them to one that does (Balancing: a second pair planted
	# beside the first cross-linked into nothing).
	var j1 := _plant("jarlink", Vector2(5, 3))
	var j2 := _plant("jarlink", Vector2(6, 3))
	var j3 := _plant("jarlink", Vector2(9, 3))
	_check(BranchKit._fence_partner(j1) == j3 and BranchKit._fence_partner(j2) == null,
		"a jar skips its side-by-side neighbour and links to the one that makes an arc; the other can't take a linked jar")
	# The build ghost previews the arc to the jar it would link with.
	placer.tower_data = load("res://resource/tower/jarlink.tres")
	placer.set_build_mode(true)
	placer._hover_cell = Vector2(12, 3)
	placer.queue_redraw()
	await process_frame
	await process_frame
	var j4 := _plant("jarlink", Vector2(15, 3))
	_check(BranchKit.fence_partner_at(placer, Vector2(12, 3), 4.0) == j4, "the ghost on (12, 3) would link to the free jar, not the linked one")
	# Sticky (Tower Discussion): a new jar planted nearer never steals a held arc.
	var thief := _plant("jarlink", Vector2(7, 5))
	_check(BranchKit._fence_partner(j1) == j3 and BranchKit._fence_partner(thief) != j1 and BranchKit._fence_partner(thief) != j3,
		"a jar planted nearer doesn't steal an existing arc")
	placer.set_build_mode(false)
	await _clean()
	# A plain Jarlink's arc doesn't touch a Phantom gliding through (only the Lightning Fence does).
	var c := _plant("jarlink", Vector2(5, 12))
	var d := _plant("jarlink", Vector2(8, 12))
	var phantom = _spawn(Vector2(6.5, 12), "res://resource/enemy/dandelion_seed.tres")
	BranchKit.process(c, 0.3)
	_check(phantom.health == phantom.max_health, "a Jarlink's arc lets a Phantom glide through")
	await _clean()

	# Rainbow Prism: its shot splits into 3 beams at half.
	var prism := _plant("rainbow_prism", Vector2(6, 6))
	var targets := [_spawn(Vector2(7, 6)), _spawn(Vector2(7, 7)), _spawn(Vector2(6, 7))]
	BranchKit.release(prism)
	_check(targets.all(func(e) -> bool: return e.health < e.max_health), "Rainbow Prism: 3 beams, one on each nightmare")
	await _clean()

	# Starburst: every 4th burst is a double (12 sparks).
	var star := _plant("starburst", Vector2(6, 10))
	star.set_meta(&"bursts", 3)
	var lone = _spawn(Vector2(8, 10))
	BranchKit.release(star)
	var spark_damage := float(star.attack_data.damage)
	_check(lone.max_health - lone.health >= int(spark_damage * 11), "Starburst: the 4th burst is a double (%d)" % (lone.max_health - lone.health))
	await _clean()

	# Vesper Bell: the toll echoes to the next-strongest at half.
	var vesper := _plant("vesper_bell", Vector2(4, 6))
	var first = _spawn(Vector2(6, 6))
	var second = _spawn(Vector2(7, 6))
	first.max_health = 900000
	first.health = 900000
	BranchKit.release(vesper)
	_check(second.health < second.max_health and second.statuses.has(EnemyStatuses.DROWSY), "Vesper Bell: the toll echoes to the next-strongest")
	await _clean()

	# Silence: the silence lingers after they leave.
	var quiet := _plant("silence", Vector2(6, 10))
	var leaving = _spawn(Vector2(7, 10))
	BranchKit.process(quiet, 0.3)
	_check(leaving.statuses.silence_time > 2.0, "Silence: lingers 2 s (%.2f)" % leaving.statuses.silence_time)
	await _clean()

	# Resonance: the cone widens for each Drowsy nightmare in it.
	var reso := _plant("resonance", Vector2(4, 12))
	reso.target_chosen = true
	reso.target_mode = TowerData.TargetMode.STRONGEST
	var ahead = _spawn(Vector2(6, 12))
	ahead.max_health = 900000
	ahead.health = 900000
	var sleepers := [_spawn(Vector2(5.8, 12.4)), _spawn(Vector2(5.8, 11.6))]
	for s in sleepers:
		s.apply_status(EnemyStatuses.DROWSY)
	var side = _spawn(Vector2(5.0, 13.4))  # ~55° off the aim: outside the 90° cone (45° each side), inside 60° once 2 Drowsy widen it
	BranchKit.release(reso)
	_check(side.health < side.max_health, "Resonance: two Drowsy in the cone widen it to reach the side")
	await _clean()

# --- The four named Kinships (Phase 1) --------------------------------------------------------------------------------

func _test_named_pairs() -> void:
	for row in [["lichenling", "brood_cap", &"crusted_brood"], ["cloudlet", "undercurrent", &"eye_of_the_storm"],
			["jarlink", "sparkler", &"fireworks_fence"], ["silver_bell", "hushbell", &"vespers"]]:
		var a := _plant(row[0], Vector2(6, 6))
		var b := _plant(row[1], Vector2(7, 6))
		await process_frame  # (Wardens find the run's Kinships deferred)
		var kin := Kinships.find(main)
		kin.refresh()
		var pairs: Array = kin.get_pairs(a)
		_check(pairs.size() == 1 and pairs[0].id == row[2], "%s + %s form %s" % [row[0], row[1], row[2]])
		if pairs.size() == 1:
			kin.ages[pairs[0].key] = 99  # Full stage
		_check(is_equal_approx(a.kin_share(row[2], "a"), 1.0) and is_equal_approx(b.kin_share(row[2], "b"), 1.0),
			"%s: both learn their trait at full stage" % row[2])
		if row[2] == &"vespers":
			var target = _spawn(Vector2(9, 6))
			BranchKit.release(a)
			_check(target.statuses.silence_time > 0.0, "Vespers (a): the toll also silences its target")
		await _clean()
		kin.refresh()

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
