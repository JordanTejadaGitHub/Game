extends RefCounted
class_name BranchKit

# The branch expansion's own mechanics, Phase 1 (tower_design.md "Branch expansion"; numbers spire_difficulty.md
# Phase 6, Balancing Discussion; placeholders until the branch probe). A Warden whose TowerData.special is set runs
# through here: Tower calls process() every frame, release() when its attack lands, has_work() before attacking,
# on_hit() after each of its hits; Enemy calls on_spore_tick() and Tower.get_raw_crit_chance asks crit_aura().
# Numbers live in TowerData.special_params (the keys below, with Balancing's starting values as defaults);
# special_final adds the final form's twist. The four Phase 1 named Kinships' traits are read here by id.
# Ground effects (sprites, ink, clouds, whirlpools, fence arcs) are script-only world nodes, drawn as
# placeholders until Tower Assets' art lands; they go in the world (Reactions._world), never in the
# Warden or nightmare containers.

const LICHEN := &"lichen"
const BROOD := &"brood"
const INKCAP := &"inkcap"
const CLOUD := &"cloud"
const WHIRLPOOL := &"whirlpool"
const JET := &"jet"
const JARLINK := &"jarlink"
const PRISM := &"prism"
const SPARKLER := &"sparkler"
const SILVER_BELL := &"silver_bell"
const HUSH := &"hush"
const THRUM := &"thrum"

# Named Kinships (Phase 1), side "a" = the first branch.
const CRUSTED_BROOD := &"crusted_brood"  # Lichenling + Brood Cap
const EYE_OF_THE_STORM := &"eye_of_the_storm"  # Cloudlet + Undercurrent
const FIREWORKS_FENCE := &"fireworks_fence"  # Jarlink + Sparkler
const VESPERS := &"vespers"  # Silver Bell + Hushbell
const KIN_TRAIT := 0.20  # Each trait is worth about +20% of the pair's effect at full stage (Balancing)

const CELL := 64.0

static func p(tower: Tower, key: String, fallback: float) -> float:
	return float(tower.attack_data.special_params.get(key, fallback))

static func is_final(tower: Tower) -> bool:
	return tower.attack_data.special_final

static func world(tower: Node) -> Node:
	return Reactions._world(tower)

# Every nightmare on the field, hidden ones too (the "enemies" group leaves hidden Lurkers out).
static func field(near: Node) -> Array:
	var scene := world(near)
	var container: Node = scene.get_node_or_null("%EnemyContainer") if scene else null
	if container == null:
		return near.get_tree().get_nodes_in_group(Tower.ENEMY_GROUP)
	return container.get_children().filter(func(e) -> bool: return is_instance_valid(e) and not e.is_cleansed)

static func targetable(near: Node) -> Array:
	return near.get_tree().get_nodes_in_group(Tower.ENEMY_GROUP).filter(func(e) -> bool:
		return is_instance_valid(e) and not e.is_cleansed and not e.is_untouchable())

# --- Tower hooks ---------------------------------------------------------------------------------------------

# Every frame. Returns true when the special replaces the normal attack loop (none do yet: auras and fences run
# beside it).
static func process(tower: Tower, delta: float) -> bool:
	match tower.attack_data.special:
		JARLINK:
			_update_fence(tower, delta)
		HUSH:
			_update_silence(tower, delta)
		CLOUD:
			if is_final(tower):
				_update_cloudburst(tower, delta)
	return false

# Whether an attack now would do anything (null = the normal rule).
static func has_work(tower: Tower):
	match tower.attack_data.special:
		BROOD:
			return BroodSprite.alive_for(tower) < int(p(tower, "max_alive", 4)) and not field(tower).is_empty()
		PRISM:
			return null
	return null

# The attack lands. Returns true when the special did it (the normal release is skipped).
static func release(tower: Tower) -> bool:
	match tower.attack_data.special:
		BROOD:
			_hatch(tower)
		CLOUD:
			_rain(tower)
		WHIRLPOOL:
			_whirl(tower)
		JET:
			_jet(tower)
		SPARKLER:
			_burst_sparks(tower)
		SILVER_BELL:
			_toll(tower)
		THRUM:
			_thrum(tower)
		PRISM:
			if not is_final(tower):
				return false
			_prism_beams(tower)
		_:
			return false
	return true

# After each hit this Warden lands on `enemy`.
static func on_hit(tower: Tower, enemy: Node2D) -> void:
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	match tower.attack_data.special:
		INKCAP:
			InkField.find(tower).mark(enemy, tower)
		LICHEN:
			# Crusted Brood (a): 1 in 4 of its shots also hatches a sprite on the target.
			if Tower._kin_roll(0.25 * tower.kin_share(CRUSTED_BROOD, "a")):
				BroodSprite.burst_at(tower, enemy, 0.5)

# Enemy: a Spored tick on `enemy`. Lichenling's spores strip its dread shell and stop it mending; Old Lichen's
# crack the shell off at 8 stacks.
static func on_spore_tick(enemy: Node2D) -> void:
	var source = enemy.statuses.source(EnemyStatuses.SPORED)
	if not (source is Tower) or source.attack_data.special != LICHEN:
		return
	enemy.statuses.veil_time = maxf(enemy.statuses.veil_time, 1.0)  # Blocks healing (Enemy.heal reads it)
	if enemy.coat > 0.0:
		enemy.coat = maxf(enemy.coat - enemy.coat_max * p(source, "shell_strip", 0.01), 0.0)
		if is_final(source) and enemy.statuses.stacks(EnemyStatuses.SPORED) >= int(p(source, "crack_at", 8)):
			enemy.coat = 0.0  # The shell cracks off at once

# Prism Jar's aura: the crit chance `tower` gets from the strongest Prism within reach (no stacking; not itself).
static func crit_aura(tower: Tower) -> float:
	if not tower.is_inside_tree():
		return 0.0  # A probe (the Warden header for an unplanted form) has no neighbours
	var best := 0.0
	for other in tower.get_tree().get_nodes_in_group(Tower.GROUP):
		if other == tower or not (other is Tower) or other.attack_data == null or other.attack_data.special != PRISM:
			continue
		if Kinships._distance(tower, other) <= p(other, "aura_radius", 1.5):
			best = maxf(best, p(other, "crit_aura", 0.10))
	return best

# --- Brood Cap / Hatchery: spore-sprites walk up the path ------------------------------------------------------

static func _hatch(tower: Tower) -> void:
	var count := tower.get_meta(&"brood_count", 0) as int + 1
	tower.set_meta(&"brood_count", count)
	var big := is_final(tower) and count % int(p(tower, "big_every", 5)) == 0
	BroodSprite.spawn(tower, big)

# --- Cloudlet / Nimbus: a rain cloud over a 3×3 anywhere in range ------------------------------------------------

static func _rain(tower: Tower) -> void:
	var targets := tower.get_enemies_in_range()
	if targets.is_empty():
		return
	# The busiest spot: the nightmare with the most others within 1 cell.
	var best: Node2D = targets[0]
	var most := -1
	for e in targets:
		var n := targets.filter(func(o) -> bool: return o.global_position.distance_to(e.global_position) <= CELL * 1.5).size()
		if n > most:
			most = n
			best = e
	var at := Tower.MAP_GRID.calculate_map_position(Tower.MAP_GRID.calculate_grid_coordinates(best.global_position))
	var zone := GroundZone.new(tower, &"rain", at, 1.5 * CELL, p(tower, "cloud_time", 4.0), 0.5)
	zone.square = true
	zone.hits_flyers = true
	zone.damage_per_second = p(tower, "dps", 12.0)
	zone.status = EnemyStatuses.DAMP
	# Eye of the Storm (a): its rain draws nightmares in gently, a short eddy pause under it (never backward).
	zone.pause = 0.3 * tower.kin_share(EYE_OF_THE_STORM, "a")
	world(tower).add_child(zone)

static func _nearest_index(route: PackedVector2Array, at: Vector2) -> int:
	var best := -1
	var best_d := INF
	for i in route.size():
		var d := Tower.MAP_GRID.calculate_map_position(route[i]).distance_to(at)
		if d < best_d:
			best_d = d
			best = i
	return best

static func _update_cloudburst(tower: Tower, delta: float) -> void:
	var left := float(tower.get_meta(&"cloudburst", p(tower, "cloudburst_every", 10.0))) - delta
	if left > 0.0:
		tower.set_meta(&"cloudburst", left)
		return
	tower.set_meta(&"cloudburst", p(tower, "cloudburst_every", 10.0))
	var reach := p(tower, "cloudburst_range", 4.0) * CELL
	for e in targetable(tower):
		if e.global_position.distance_to(tower.global_position) <= reach:
			tower._apply_one_status(e, EnemyStatuses.DAMP, 1, tower.get_damage())  # Cloudburst: Soaked refreshed
	Fx.play(&"rain_sweep", tower.global_position, world(tower), reach / (1.5 * CELL))  # Cloudburst: rain sweeps out over the range

# --- Undercurrent / Maelstrom: a whirlpool that gathers --------------------------------------------------------

static func _whirl(tower: Tower) -> void:
	var route := tower._route()
	var best := Vector2(-1, -1)
	var most := 0
	var radius := p(tower, "radius", 1.5)
	for cell in route:
		if not tower._is_cell_in_range(cell):
			continue
		var at := Tower.MAP_GRID.calculate_map_position(cell)
		var n := targetable(tower).filter(func(e) -> bool: return not e.is_flying() and e.global_position.distance_to(at) <= radius * CELL).size()
		if n > most:
			most = n
			best = cell
	if best == Vector2(-1, -1):
		return
	var zone := GroundZone.new(tower, &"whirlpool", Tower.MAP_GRID.calculate_map_position(best), radius * CELL,
		p(tower, "duration", 3.0), 0.25)
	zone.damage_per_second = p(tower, "dps", 10.0)
	zone.pause = p(tower, "pause", 0.8)  # Maelstrom: 1.2 s (Balancing)
	# Maelstrom Soaks; Eye of the Storm (b): the whirlpool is rained on.
	if is_final(tower) or tower.kin_share(EYE_OF_THE_STORM, "b") > 0.0:
		zone.status = EnemyStatuses.DAMP
	world(tower).add_child(zone)

# --- Jetreed / Torrent: an instant piercing jet ------------------------------------------------------------------

static func _jet(tower: Tower) -> void:
	var target := tower.find_target()
	if target == null:
		return
	var from := tower.global_position
	var dir := (target.global_position - from).normalized()
	var length := p(tower, "length", 6.0) * CELL
	var soaked_bonus := p(tower, "vs_soaked", 0.5)
	for e in targetable(tower):
		if e.is_flying():
			continue
		var rel: Vector2 = e.global_position - from
		var along := rel.dot(dir)
		if along < 0.0 or along > length or absf(rel.cross(dir)) > CELL * 0.45:
			continue
		var mult := 1.0 + (soaked_bonus if e.statuses.has(EnemyStatuses.DAMP) else 0.0)
		tower.hit(e, mult)
	Fx.segment(&"water_jet", from, from + dir * length, world(tower), 0.25)
	if is_final(tower):  # Flood: a 3-tile wet trail where the jet met the path
		var cells: Array[Vector2] = []
		var route := tower._route()
		for i in route.size():
			var at := Tower.MAP_GRID.calculate_map_position(route[i])
			var rel := at - from
			if rel.dot(dir) >= 0.0 and rel.dot(dir) <= length and absf(rel.cross(dir)) <= CELL * 0.6:
				cells.append(route[i])
				if cells.size() >= int(p(tower, "trail_tiles", 3)):
					break
		for cell in cells:
			var wet := GroundZone.new(tower, &"wet", Tower.MAP_GRID.calculate_map_position(cell), 0.5 * CELL,
				p(tower, "trail_time", 3.0), 0.5)
			wet.square = true
			wet.status = EnemyStatuses.DAMP
			world(tower).add_child(wet)

# --- Jarlink / Lightning Fence: two Jarlinks within 4 cells make an arc ---------------------------------------

static func _update_fence(tower: Tower, delta: float) -> void:
	var partner := _fence_partner(tower)
	if partner == null or partner.get_instance_id() < tower.get_instance_id():
		return  # One side of each pair does the work (the lower id)
	FenceLayer.find(tower).note(tower, partner)
	var a := tower.global_position
	var b := partner.global_position
	var seg := b - a
	var now := Time.get_ticks_msec() / 1000.0
	var final := is_final(tower) or is_final(partner)
	var cooldown := p(tower, "cross_cooldown", 0.5)
	for e in targetable(tower):
		if e.is_flying() and not final:
			continue  # Only the Lightning Fence catches Phantoms gliding through
		var t := clampf((e.global_position - a).dot(seg) / maxf(seg.length_squared(), 1.0), 0.0, 1.0)
		if e.global_position.distance_to(a + seg * t) > CELL * 0.35:
			continue
		var key := "fence_%d" % tower.get_instance_id()
		if now < float(e.get_meta(key, 0.0)):
			continue
		e.set_meta(key, now + cooldown)
		var crossing := p(tower, "cross_damage", 20.0)
		tower.hit(e, crossing / maxf(float(tower.attack_data.damage), 1.0), true)
		if is_instance_valid(e) and not e.is_cleansed:
			e.apply_status(EnemyStatuses.STATIC, 1, 0.0, tower.get_damage(), 0, "light", tower)
		# Fireworks Fence (a): a crossing sets off a small spark burst.
		for side in [tower, partner]:
			var share: float = side.kin_share(FIREWORKS_FENCE, "a")
			if share > 0.0 and is_instance_valid(e) and not e.is_cleansed:
				_spark_burst_at(side, e.global_position, 2, crossing * 0.5 * share, false)

static func _fence_partner(tower: Tower) -> Tower:
	var best: Tower = null
	var best_d := INF
	for other in tower.get_tree().get_nodes_in_group(Tower.GROUP):
		if other == tower or not (other is Tower) or other.attack_data == null or other.attack_data.special != JARLINK:
			continue
		var d := Kinships._distance(tower, other)
		if d <= p(tower, "link_range", 4.0) and d < best_d:
			best_d = d
			best = other
	return best

# A spark landing at `at` near a Jarlink fence (Fireworks Fence b): whether one is within half a cell.
static func _on_fence(near: Node, at: Vector2) -> bool:
	var layer := FenceLayer.find(near)
	return layer != null and layer.touches(at, CELL * 0.5)

# --- Prism Jar / Rainbow Prism -------------------------------------------------------------------------------------

static func _prism_beams(tower: Tower) -> void:
	var share := p(tower, "beam_share", 0.5)
	var colours: Array[Color] = [Palette.BLOSSOM, Palette.GLOW, Palette.DEWLIGHT]  # The white sheet tinted (Tower Assets)
	var targets := tower.find_targets(int(p(tower, "beams", 3)))
	for i in targets.size():
		tower.hit(targets[i], share)
		var beam := Fx.segment(&"prism_beam", tower.global_position, targets[i].global_position, world(tower), 0.2)
		if beam:
			beam.modulate = colours[i % colours.size()]

# --- Sparkler / Starburst: a firework over a crowd ---------------------------------------------------------------

static func _burst_sparks(tower: Tower) -> void:
	var target := tower.find_target()
	if target == null:
		return
	var count := tower.get_meta(&"bursts", 0) as int + 1
	tower.set_meta(&"bursts", count)
	var sparks := int(p(tower, "sparks", 6))
	if is_final(tower) and count % int(p(tower, "double_every", 4)) == 0:
		sparks *= 2
	_spark_burst_at(tower, target.global_position, sparks, float(tower.attack_data.damage), true)

# `sparks` sparks of `each` damage on nightmares within the burst radius of `at`, each adding Charged.
static func _spark_burst_at(tower: Tower, at: Vector2, sparks: int, each: float, may_rebound: bool) -> void:
	var radius := p(tower, "burst_radius", 1.5) * CELL
	var near := targetable(tower).filter(func(e) -> bool: return e.global_position.distance_to(at) <= radius)
	Fx.play(&"spark_burst" if not may_rebound else &"firework_burst", at, world(tower))  # A full burst, or the small spark of a fence crossing
	if near.is_empty():
		return
	var mult := each / maxf(float(tower.attack_data.damage), 1.0)
	for i in sparks:
		var e: Node2D = near[randi() % near.size()]
		if not is_instance_valid(e) or e.is_cleansed:
			continue
		tower.hit(e, mult, true)
		if is_instance_valid(e) and not e.is_cleansed:
			e.apply_status(EnemyStatuses.STATIC, 1, 0.0, tower.get_damage(), 0, "light", tower)
	# Fireworks Fence (b): a burst landing on a fence re-bursts once.
	if may_rebound and _on_fence(tower, at) and Tower._kin_roll(tower.kin_share(FIREWORKS_FENCE, "b")):
		_spark_burst_at(tower, at, sparks, each * 0.5, false)

# --- Silver Bell / Vesper Bell: a long-range toll on the strongest ---------------------------------------------------

static func _toll(tower: Tower) -> void:
	var ranked := tower.get_enemies_in_range()
	ranked.sort_custom(func(x: Node2D, y: Node2D) -> bool: return x.health > y.health)
	if ranked.is_empty():
		return
	_toll_one(tower, ranked[0], 1.0)
	if is_final(tower) and ranked.size() > 1:
		_toll_one(tower, ranked[1], p(tower, "echo_share", 0.5))  # The toll echoes to the next-strongest

static func _toll_one(tower: Tower, enemy: Node2D, share: float) -> void:
	tower.hit(enemy, share)
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	var cap: int = enemy.statuses.get_max_stacks(EnemyStatuses.DROWSY)
	var fill := roundi((cap - enemy.statuses.stacks(EnemyStatuses.DROWSY)) * share)
	if fill > 0:
		tower._apply_one_status(enemy, EnemyStatuses.DROWSY, fill, tower.get_damage())
	# Vespers (a): the toll also silences its target for 2 s.
	var vespers := tower.kin_share(VESPERS, "a")
	if vespers > 0.0 and is_instance_valid(enemy):
		silence(enemy, 2.0 * vespers, tower)
	Fx.play(&"toll_ring", enemy.global_position, world(tower))

# --- Hushbell / Silence ---------------------------------------------------------------------------------------------------

const SILENCE_TICK := 0.25

static func _update_silence(tower: Tower, delta: float) -> void:
	var left := float(tower.get_meta(&"hush_tick", 0.0)) - delta
	if left > 0.0:
		tower.set_meta(&"hush_tick", left)
		return
	tower.set_meta(&"hush_tick", SILENCE_TICK)
	var reach := p(tower, "radius", 2.0) * CELL
	var hold := SILENCE_TICK * 1.5 + (p(tower, "linger", 2.0) if is_final(tower) else 0.0)
	for e in field(tower):
		if e.global_position.distance_to(tower.global_position) <= reach:
			silence(e, hold, tower)

# Silences `enemy` for `seconds` (no abilities: the Watcher can't wake, Weepers can't mend, boss timers wait).
# Vespers (b): a nightmare a Hushbell silences gains 1 Drowsy.
static func silence(enemy: Node2D, seconds: float, by: Tower) -> void:
	var was: bool = enemy.statuses.silence_time > 0.0
	enemy.statuses.silence_time = maxf(enemy.statuses.silence_time, seconds)
	# The Procession's Lantern Bearer (tower_design.md 9fcb8cdf): silenced, its lantern goes dark and its Wraiths
	# are lost, as if it had been dispelled first; they find the way again when the silence ends (SilenceWatch).
	if is_instance_valid(by):
		SilenceWatch.find(by).mark(enemy)  # The silence_mark over its head
	if not was and enemy.enemy_data.followers != null and not enemy.enemy_data.is_boss and is_instance_valid(by):
		SilenceWatch.find(by).darken(enemy)
	if not was and is_instance_valid(by) and by.attack_data.special == HUSH and Tower._kin_roll(by.kin_share(VESPERS, "b")):
		by._apply_one_status(enemy, EnemyStatuses.DROWSY, 1, by.get_damage())

# --- Thrum / Resonance: a cone of sound ---------------------------------------------------------------------------------

static func _thrum(tower: Tower) -> void:
	var target := tower.find_target()
	if target == null:
		return
	var dir := (target.global_position - tower.global_position).normalized()
	var reach := tower.get_range_pixels()
	var in_reach := targetable(tower).filter(func(e) -> bool: return e.global_position.distance_to(tower.global_position) <= reach)
	var half := deg_to_rad(p(tower, "cone", 90.0)) / 2.0
	if is_final(tower):  # The cone widens for each Drowsy nightmare in it
		var cone := half
		var drowsy := in_reach.filter(func(e) -> bool:
			return e.statuses.has(EnemyStatuses.DROWSY) and absf(dir.angle_to(e.global_position - tower.global_position)) <= cone).size()
		half = minf(half + deg_to_rad(p(tower, "widen", 15.0)) / 2.0 * drowsy, deg_to_rad(p(tower, "cone_max", 180.0)) / 2.0)
	var bonus := p(tower, "vs_drowsy", 0.3)
	for e in in_reach:
		if absf(dir.angle_to(e.global_position - tower.global_position)) <= half:
			tower.hit(e, 1.0 + (bonus if e.statuses.has(EnemyStatuses.DROWSY) else 0.0), true)
	world(tower).add_child(ConeFlash.new(tower.global_position, dir, reach, half))  # The cone itself (what it hits)
	var wave := Fx.play(&"sound_cone", tower.global_position, world(tower), reach / 48.0)
	if wave:
		wave.rotation = dir.angle()


# ===== World nodes (script-only, placeholder drawing) ================================================================

# Brood Cap's spore-sprites: walk up the path (toward the start) and burst on the first nightmare they touch, a
# hidden Lurker included (it's revealed).
class BroodSprite extends Node2D:
	var tower: Tower
	var route: PackedVector2Array
	var index := 0
	var speed := 3.0 * CELL
	var big := false
	var life := 8.0

	static func alive_for(t: Tower) -> int:
		var scene := BranchKit.world(t)
		if scene == null:
			return 0
		return scene.get_children().filter(func(n) -> bool: return n is BroodSprite and n.tower == t and not n.is_queued_for_deletion()).size()

	static func spawn(t: Tower, is_big: bool) -> void:
		var path := t._route()
		if path.is_empty():
			return
		# Start on the route cell nearest the Warden.
		var best := 0
		var best_d := INF
		for i in path.size():
			var d := Tower.MAP_GRID.calculate_map_position(path[i]).distance_to(t.global_position)
			if d < best_d:
				best_d = d
				best = i
		var sprite := BroodSprite.new()
		sprite.tower = t
		sprite.route = path
		sprite.index = best
		sprite.big = is_big
		sprite.speed = BranchKit.p(t, "sprite_speed", 3.0) * CELL
		sprite.z_index = 2
		BranchKit.world(t).add_child(sprite)
		sprite.global_position = Tower.MAP_GRID.calculate_map_position(path[best])

	# Crusted Brood (a): a Lichenling shot hatches a sprite right on its target (a burst at `share`).
	static func burst_at(t: Tower, enemy: Node2D, share: float) -> void:
		t.hit(enemy, share, true)
		if is_instance_valid(enemy) and not enemy.is_cleansed:
			enemy.apply_status(EnemyStatuses.SPORED, 1, 0.0, t.get_damage() * Tower.SPORE_POTENCY, 0, "spore", t)

	func _process(delta: float) -> void:
		life -= delta
		if not is_instance_valid(tower) or life <= 0.0 or index <= 0:
			queue_free()
			return
		var goal := Tower.MAP_GRID.calculate_map_position(route[index - 1])
		_age += delta
		if absf(goal.x - global_position.x) > 0.5:
			_left_facing = goal.x < global_position.x
		global_position = global_position.move_toward(goal, speed * delta)
		if global_position.distance_to(goal) < 1.0:
			index -= 1
		for e in BranchKit.field(tower):
			if e.is_flying() or e.global_position.distance_to(global_position) > CELL * 0.45:
				continue
			_burst(e)
			return
		queue_redraw()

	func _burst(enemy: Node2D) -> void:
		if enemy.has_method("is_hidden") and enemy.is_hidden():
			enemy.reveal_for(2.0)  # Bumped into a Lurker: it shows itself
		var stacks := int(BranchKit.p(tower, "spored", 2))
		tower.hit(enemy, 1.0, true)
		if is_instance_valid(enemy) and not enemy.is_cleansed:
			enemy.apply_status(EnemyStatuses.SPORED, stacks, 0.0, tower.get_damage() * Tower.SPORE_POTENCY, 0, "spore", tower)
			# Crusted Brood (b): its sprites also eat dread shell.
			var crust := tower.kin_share(CRUSTED_BROOD, "b")
			if crust > 0.0 and enemy.coat > 0.0:
				enemy.coat = maxf(enemy.coat - enemy.coat_max * 0.05 * crust, 0.0)
		if big:  # Hatchery: every 5th sprite is big and splits into 3
			for i in 3:
				var small := BroodSprite.new()
				small.tower = tower
				small.route = route
				small.index = maxi(index - 1, 1)
				small.speed = speed
				small.life = 3.0
				small.z_index = 2
				get_parent().add_child(small)
				small.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		queue_free()

	const SHEET := "res://assets/towers/projectiles/spore_sprite.png"  # 24×24, 4 walk frames drawn walking right
	var _tex: Texture2D = load(SHEET) if ResourceLoader.exists(SHEET) else null  # Per sprite (cached): never a static
	var _age := 0.0
	var _left_facing := false

	func _draw() -> void:
		if _tex == null:
			var r := 7.0 if big else 4.5
			draw_circle(Vector2.ZERO, r, Color(Palette.NEWLEAF, 0.9))
			draw_circle(Vector2(0, -r * 0.4), r * 0.45, Color(Palette.SPRIG, 0.9))
			return
		var size := Vector2(24, 24) * (1.5 if big else 1.0)  # Hatchery's big one, scaled up
		var frame := int(_age * 8.0) % 4
		var region := Rect2(frame * 24, 0, 24, 24)
		var rect := Rect2(-size / 2.0 - Vector2(0, size.y * 0.3), size)
		if _left_facing:
			rect = Rect2(rect.position + Vector2(rect.size.x, 0), Vector2(-rect.size.x, rect.size.y))
		draw_texture_rect_region(_tex, rect, region)


# A patch of ground with an effect for a while: rain clouds, whirlpools, ink, wet trails. Ticks every `tick` s on the
# nightmares inside (a square or a circle of `radius`).
class GroundZone extends Node2D:
	var tower: Tower
	var kind: StringName
	var radius := 32.0
	var left := 3.0
	var tick := 0.5
	var square := false
	var hits_flyers := false
	var damage_per_second := 0.0
	var status: StringName = &""
	var status_stacks := 1
	# The eddy (tower_design.md 9fcb8cdf): a nightmare reaching it stops for this many seconds, a plain pause (not
	# Held; Enemy.hold_time), once per nightmare per zone, bosses half; the ones behind catch up. Never backward.
	var pause := 0.0
	var _paused := {}  # Enemy instance ids already paused here
	var _next := 0.0
	var _duration := 3.0

	func _init(t: Tower, k: StringName, at: Vector2, r: float, seconds: float, every: float) -> void:
		tower = t
		kind = k
		position = at
		radius = r
		left = seconds
		_duration = seconds
		tick = every
		z_index = -1 if k != &"rain" else 5

	var _art := false  # Tower Assets' sheet shows it (else the drawn stand-in)

	func _ready() -> void:
		match kind:
			&"rain":  # rain_zone tiles seamlessly 3×3
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						_art = Fx.play(&"rain_zone", global_position + Vector2(dx, dy) * CELL, self, 1.0, true, left) != null or _art
			&"whirlpool":
				_art = Fx.play(&"whirlpool", global_position, self, radius * 2.0 / CELL, true, left) != null
			&"wet":  # Torrent's trail: the ink sheet, tinted water-blue
				var trail := Fx.segment(&"ink_trail", global_position - Vector2(CELL / 2.0, 0), global_position + Vector2(CELL / 2.0, 0), self, left)
				if trail:
					trail.modulate = Palette.DEWLIGHT  # multiplier (a tint on the ink sheet)
					_art = true

	func _process(delta: float) -> void:
		left -= delta
		if left <= 0.0 or not is_instance_valid(tower):
			queue_free()
			return
		_next -= delta
		if _next <= 0.0:
			_next += tick
			_tick()
		queue_redraw()

	func _inside(e: Node2D) -> bool:
		var d: Vector2 = (e.global_position - global_position).abs()
		return (maxf(d.x, d.y) <= radius) if square else (e.global_position.distance_to(global_position) <= radius)

	func _tick() -> void:
		for e in BranchKit.targetable(tower):
			if (e.is_flying() and not hits_flyers) or not _inside(e):
				continue
			if damage_per_second > 0.0:
				tower.hit(e, damage_per_second * tick / maxf(float(tower.attack_data.damage), 1.0), true)
			if not is_instance_valid(e) or e.is_cleansed:
				continue
			if status != &"":
				tower._apply_one_status(e, status, status_stacks, tower.get_damage())
			if pause > 0.0 and not e.is_flying() and not _paused.has(e.get_instance_id()):
				_paused[e.get_instance_id()] = true
				e.hold_time = maxf(e.hold_time, pause * (0.5 if e.enemy_data.is_boss else 1.0))  # It spins in the eddy

	func _draw() -> void:
		if _art:
			return  # The sheet shows it
		var fade := clampf(left / 0.5, 0.0, 1.0)
		var colour: Color
		match kind:
			&"rain":
				colour = Palette.DEWLIGHT
			&"whirlpool", &"wet":
				colour = Palette.DEWLIGHT
			_:
				colour = Palette.ORCHID  # Ink
		if square:
			draw_rect(Rect2(-Vector2(radius, radius), Vector2(radius, radius) * 2.0), Color(colour, 0.16 * fade))
		else:
			draw_circle(Vector2.ZERO, radius, Color(colour, 0.14 * fade))
			if kind == &"whirlpool":
				var spin := (_duration - left) * 4.0
				for i in 3:
					draw_arc(Vector2.ZERO, radius * (0.35 + 0.25 * i), spin + i, spin + i + 2.4, 16, Color(colour, 0.6 * fade), 2.0)


# Inkcap / Deliquescent: Poisoned nightmares it hit leave ink on the cells they walk; walkers on ink gain Spored.
# A dispelled one (Deliquescent) melts into a pool.
class InkField extends Node:
	const TICK := 0.25
	var marked := {}  # Enemy instance id -> [enemy, Tower, seconds of trail left]
	var cells := {}  # Cell -> [expires at, Tower, Spored every N s, next tick at]
	var _clock := 0.0
	var _next := 0.0

	static func find(near: Node) -> InkField:
		var scene := BranchKit.world(near)
		var found: InkField = scene.get_node_or_null("InkField") if scene else null
		if found == null and scene:
			found = InkField.new()
			found.name = "InkField"
			scene.add_child(found)
			var container: Node = scene.get_node_or_null("%EnemyContainer")
			if container and container.has_signal("enemy_cleansed"):
				container.enemy_cleansed.connect(found._on_dispelled)
		return found

	func mark(enemy: Node2D, tower: Tower) -> void:
		marked[enemy.get_instance_id()] = [enemy, tower, BranchKit.p(tower, "trail_time", 2.0)]

	func _process(delta: float) -> void:
		_clock += delta
		_next -= delta
		if _next > 0.0:
			return
		_next += TICK
		for id in marked.keys():
			var entry: Array = marked[id]
			var enemy = entry[0]
			if not is_instance_valid(enemy) or enemy.is_cleansed or not enemy.statuses.has(EnemyStatuses.SPORED):
				marked.erase(id)
				continue
			if not enemy.is_flying():
				var cell: Vector2 = enemy.get_current_cell()
				if cells.has(cell):
					cells[cell][0] = maxf(cells[cell][0], _clock + entry[2])  # Fresh ink lasts longer and keeps its tick
				else:
					cells[cell] = [_clock + entry[2], entry[1], 1.0, _clock + 1.0]
					_show(cell, entry[2])
		for cell in cells.keys():
			var ink: Array = cells[cell]
			if _clock >= ink[0] or not is_instance_valid(ink[1]):
				cells.erase(cell)
				continue
			if _clock < ink[3]:
				continue
			ink[3] = _clock + ink[2]
			for e in BranchKit.targetable(ink[1]):
				if not e.is_flying() and e.get_current_cell() == cell:
					e.apply_status(EnemyStatuses.SPORED, 1, 0.0, ink[1].get_damage() * Tower.SPORE_POTENCY, 0, "spore", ink[1])

	# Deliquescent: a dispelled Poisoned nightmare it marked melts into a 2-tile pool.
	func _on_dispelled(enemy: Node2D) -> void:
		var entry: Array = marked.get(enemy.get_instance_id(), [])
		if entry.is_empty() or not is_instance_valid(entry[1]) or not BranchKit.is_final(entry[1]):
			return
		var tower: Tower = entry[1]
		var here: Vector2 = enemy.get_current_cell()
		var pool: Array[Vector2] = [here, enemy.get_target_cell()]
		for cell in pool:
			cells[cell] = [_clock + BranchKit.p(tower, "pool_time", 4.0), tower, BranchKit.p(tower, "pool_every", 0.5), _clock]
			_show(cell, BranchKit.p(tower, "pool_time", 4.0))
		marked.erase(enemy.get_instance_id())

	# The ink on `cell` for `seconds` (Tower Assets' ink_trail across the cell).
	func _show(cell: Vector2, seconds: float) -> void:
		var at := Tower.MAP_GRID.calculate_map_position(cell)
		var ink := Fx.segment(&"ink_trail", at - Vector2(BranchKit.CELL / 2.0, 0), at + Vector2(BranchKit.CELL / 2.0, 0), get_parent(), seconds)
		if ink:
			ink.z_index = -1  # On the ground

	func ink_at(cell: Vector2) -> bool:
		return cells.has(cell) and _clock < cells[cell][0]


# Silenced Lantern Bearers: their Wraiths are lost until the silence ends (a dispel keeps them lost for good).
class SilenceWatch extends Node:
	const TICK := 0.25
	var leaders := {}  # Leader instance id -> [leader, [Wraiths it set lost]]
	var marks := {}  # Silenced nightmare instance id -> [nightmare, its silence_mark over its head]
	var _next := 0.0

	# The silence_mark over a silenced nightmare's head while the silence lasts (it follows the nightmare).
	func mark(enemy: Node2D) -> void:
		var entry: Array = marks.get(enemy.get_instance_id(), [])
		if not entry.is_empty() and is_instance_valid(entry[1]):
			return
		var node := Fx.play(&"silence_mark", enemy.global_position + Vector2(0, -30), enemy, 1.0, true, 0.0)
		if node:
			marks[enemy.get_instance_id()] = [enemy, node]

	static func find(near: Node) -> SilenceWatch:
		var scene := BranchKit.world(near)
		var found: SilenceWatch = scene.get_node_or_null("SilenceWatch") if scene else null
		if found == null and scene:
			found = SilenceWatch.new()
			found.name = "SilenceWatch"
			scene.add_child(found)
		return found

	func darken(leader: Node2D) -> void:
		var lost: Array = leaders.get(leader.get_instance_id(), [leader, []])[1]
		for f in leader.dew_followers:
			if is_instance_valid(f) and not f.is_cleansed and not f.lost:
				f.set_lost()
				lost.append(f)
		leaders[leader.get_instance_id()] = [leader, lost]

	func _process(delta: float) -> void:
		_next -= delta
		if _next > 0.0:
			return
		_next = TICK
		for id in marks.keys():
			var entry: Array = marks[id]
			if not is_instance_valid(entry[0]) or entry[0].is_cleansed or entry[0].statuses.silence_time <= 0.0:
				if is_instance_valid(entry[1]):
					entry[1].queue_free()
				marks.erase(id)
		for id in leaders.keys():
			var leader = leaders[id][0]
			if not is_instance_valid(leader) or leader.is_cleansed:
				leaders.erase(id)  # Dispelled: its Wraiths stay lost (the spawner's rule)
				continue
			if leader.statuses.silence_time > 0.0:
				continue
			for f in leaders[id][1]:
				if is_instance_valid(f) and not f.is_cleansed:
					f.lost = false  # The lantern lights again: they find the way
					f._speed_stale = true
			leaders.erase(id)

	func is_darkened(leader: Node2D) -> bool:
		return leaders.has(leader.get_instance_id())


# Jarlink arcs, drawn in one layer (one per run scene): note() each frame for each linked pair.
class FenceLayer extends Node2D:
	var arcs := {}  # "id:id" -> [jar a, jar b, frame noted, the arc_fence segment]
	const ARC_SECONDS := 36000.0  # Fx.segment frees after this; the arc is replaced or freed long before

	static func find(near: Node) -> FenceLayer:
		var scene := BranchKit.world(near)
		var found: FenceLayer = scene.get_node_or_null("FenceLayer") if scene else null
		if found == null and scene:
			found = FenceLayer.new()
			found.name = "FenceLayer"
			found.z_index = 4
			scene.add_child(found)
		return found

	func note(a: Tower, b: Tower) -> void:
		var key := "%d:%d" % [a.get_instance_id(), b.get_instance_id()]
		var from := a.global_position + a.tower_data.get_attack_origin()  # Jar to jar
		var to := b.global_position + b.tower_data.get_attack_origin()
		var arc: Array = arcs.get(key, [])
		var node = arc[3] if arc.size() > 3 else null
		if arc.is_empty() or not arc[0].is_equal_approx(from) or not arc[1].is_equal_approx(to) or not is_instance_valid(node):
			if is_instance_valid(node):
				node.queue_free()  # A jar moved: a new arc
			node = Fx.segment(&"arc_fence", from, to, self, ARC_SECONDS)  # Tower Assets' looping zigzag, kept alive while linked
		arcs[key] = [from, to, Engine.get_process_frames(), node]

	func touches(at: Vector2, reach: float) -> bool:
		for key in arcs:
			var arc: Array = arcs[key]
			var seg: Vector2 = arc[1] - arc[0]
			var t := clampf((at - arc[0]).dot(seg) / maxf(seg.length_squared(), 1.0), 0.0, 1.0)
			if at.distance_to(arc[0] + seg * t) <= reach:
				return true
		return false

	func _process(_delta: float) -> void:
		var frame := Engine.get_process_frames()
		for key in arcs.keys():
			if frame - int(arcs[key][2]) > 2:
				if arcs[key].size() > 3 and is_instance_valid(arcs[key][3]):
					arcs[key][3].queue_free()
				arcs.erase(key)  # The pair broke (sold, moved apart)
		queue_redraw()

	func _draw() -> void:
		var wobble := sin(Time.get_ticks_msec() / 90.0) * 3.0
		for key in arcs:
			var arc: Array = arcs[key]
			if arc.size() > 3 and is_instance_valid(arc[3]):
				continue  # The sheet shows it
			var mid: Vector2 = (arc[0] + arc[1]) / 2.0 + Vector2(0, -10 + wobble)
			var points := PackedVector2Array([arc[0] - global_position, mid - global_position, arc[1] - global_position])
			draw_polyline(points, Color(Palette.GLOW, 0.85), 2.0)
			draw_polyline(points, Color(Palette.DEWLIGHT, 0.35), 5.0)


# A straight flash (a jet, a beam, a toll line) that fades out.
class LineFlash extends Node2D:
	var a: Vector2
	var b: Vector2
	var colour: Color
	var left := 0.25
	var _total := 0.25

	func _init(from: Vector2, to: Vector2, c: Color, seconds: float) -> void:
		a = from
		b = to
		colour = c
		left = seconds
		_total = seconds
		z_index = 5

	func _process(delta: float) -> void:
		left -= delta
		if left <= 0.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var fade := clampf(left / _total, 0.0, 1.0)
		draw_line(a - global_position, b - global_position, Color(colour, 0.8 * fade), 3.0)


# Thrum's cone of sound, fading out.
class ConeFlash extends Node2D:
	var dir: Vector2
	var reach := 100.0
	var half := 0.8
	var left := 0.3

	func _init(at: Vector2, d: Vector2, r: float, h: float) -> void:
		position = at
		dir = d
		reach = r
		half = h
		z_index = 5

	func _process(delta: float) -> void:
		left -= delta
		if left <= 0.0:
			queue_free()
		queue_redraw()

	func _draw() -> void:
		var fade := clampf(left / 0.3, 0.0, 1.0)
		var base := dir.angle()
		var points := PackedVector2Array([Vector2.ZERO])
		for i in 13:
			var angle := base - half + 2.0 * half * i / 12.0
			points.append(Vector2.from_angle(angle) * reach)
		draw_colored_polygon(points, Color(Palette.BLOSSOM, 0.18 * fade))
