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
# Phase 2 (tower_design.md "The new branches": Pebbling, Rootling, Acorn).
const WHETSTONE := &"whetstone"
const RAMPART := &"rampart"
const QUAKER := &"quaker"
const GROUNDROOT := &"groundroot"
const DEEPROOT := &"deeproot"
const THORNCOIL := &"thorncoil"
const SEEDBEARER := &"seedbearer"
const NURSE_LOG := &"nurse_log"
const DREAM_OAK := &"dream_oak"

# Named Kinships (Phase 1), side "a" = the first branch.
const CRUSTED_BROOD := &"crusted_brood"  # Lichenling + Brood Cap
const EYE_OF_THE_STORM := &"eye_of_the_storm"  # Cloudlet + Undercurrent
const FIREWORKS_FENCE := &"fireworks_fence"  # Jarlink + Sparkler
const VESPERS := &"vespers"  # Silver Bell + Hushbell
# Named Kinships (Phase 2).
const FAULT_LINE := &"fault_line"  # Rampart + Quaker
const BRAMBLE_BED := &"bramble_bed"  # Groundroot + Thorncoil
const NURSERY := &"nursery_bond"  # Seed Cradle: Seedbearer + Nurse Log (not &"nursery": that's a Dream card's rule)
const KIN_TRAIT := 0.20  # Each trait is worth about +20% of the pair's effect at full stage (Balancing)

const CELL := 64.0

static func p(tower: Tower, key: String, fallback: float) -> float:
	return float(tower.attack_data.special_params.get(key, fallback))

# Yield (Nurture rework): the extra sprites / Sprouts a Warden's Yield ranks buy (one per NurtureChoices.YIELD_PER ranks).
static func yield_ranks(tower: Tower) -> int:
	return tower.choice_count(Tower.Focus.YIELD) / NurtureChoices.YIELD_PER

# Jarlink's link range (cells): its own, + Reach ranks.
static func link_range(tower: Tower) -> float:
	return p(tower, "link_range", 4.0) + tower.area_bonus()

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
			_update_fence(tower, delta * tower.get_cycle_multiplier())  # Swift: the arc ticks faster
		HUSH:
			_update_silence(tower, delta)
		CLOUD:
			if is_final(tower):
				_update_cloud_drift(tower, delta * tower.get_cycle_multiplier())
		RAMPART:
			if is_final(tower):
				_update_rockfall(tower, delta * tower.get_cycle_multiplier())
		GROUNDROOT:
			_update_grounding(tower, delta * tower.get_cycle_multiplier())
		DEEPROOT:
			_update_goal_guard(tower, delta)
		THORNCOIL:
			_update_thorns(tower, delta * tower.get_cycle_multiplier())
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
		QUAKER:
			_quake(tower)
			return false  # Its pulse lands the hits
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
		QUAKER:
			if enemy.has_method("stop_speed_boosts"):
				enemy.stop_speed_boosts()  # A sprinting Night Hound stops sprinting, a charge ends
		RAMPART:
			var fault := tower.kin_share(FAULT_LINE, "a")
			if fault > 0.0 and not enemy.is_flying():
				crack(tower, enemy.get_current_cell(), CRACK_TIME * fault)  # Fault Line (a): its blows crack the path

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
		if Kinships._distance(tower, other) <= p(other, "aura_radius", 1.5) + NurtureChoices.WIDE_STEP * other.choice_count(Tower.Focus.WIDE):
			best = maxf(best, p(other, "crit_aura", 0.10) + NurtureChoices.STRONG_CRIT_AURA * other.choice_count(Tower.Focus.STRONG))
	return best

# Prism Jar's aura, crit damage: the strongest Prism within reach adds this to crit damage (Balancing: +25%).
static func crit_damage_aura(tower: Tower) -> float:
	if not tower.is_inside_tree():
		return 0.0
	var best := 0.0
	for other in tower.get_tree().get_nodes_in_group(Tower.GROUP):
		if other == tower or not (other is Tower) or other.attack_data == null or other.attack_data.special != PRISM:
			continue
		if Kinships._distance(tower, other) <= p(other, "aura_radius", 1.5) + NurtureChoices.WIDE_STEP * other.choice_count(Tower.Focus.WIDE):
			best = maxf(best, p(other, "crit_damage_aura", 0.0))
	return best

# --- Brood Cap / Hatchery: spore-sprites walk up the path ------------------------------------------------------

static func _hatch(tower: Tower) -> void:
	var count := tower.get_meta(&"brood_count", 0) as int + 1
	tower.set_meta(&"brood_count", count)
	var big := is_final(tower) and count % int(p(tower, "big_every", 5)) == 0
	BroodSprite.spawn(tower, big)

# --- Cloudlet / Nimbus: a rain cloud over a 3×3 anywhere in range ------------------------------------------------

# The busiest spot in range: the cell of the nightmare with the most others within 1.5 cells (null if none).
static func _densest(tower: Tower):
	var targets := tower.get_enemies_in_range()
	if targets.is_empty():
		return null
	var best: Node2D = targets[0]
	var most := -1
	for e in targets:
		var n := targets.filter(func(o) -> bool: return o.global_position.distance_to(e.global_position) <= CELL * 1.5).size()
		if n > most:
			most = n
			best = e
	return Tower.MAP_GRID.calculate_map_position(Tower.MAP_GRID.calculate_grid_coordinates(best.global_position))

static func _rain(tower: Tower) -> void:
	var at = _densest(tower)
	if at == null:
		return
	var zone := GroundZone.new(tower, &"rain", at, (1.5 + tower.area_bonus()) * CELL, p(tower, "cloud_time", 4.0), 0.5)
	zone.square = true
	zone.hits_flyers = true
	zone.damage_per_second = p(tower, "dps", 12.0)
	zone.status = EnemyStatuses.DAMP
	# Eye of the Storm (a): nightmares under its cloud are linked at 10% (tower_design.md "Branch review").
	var eye := tower.kin_share(EYE_OF_THE_STORM, "a")
	if eye > 0.0:
		zone.link_share = 0.10 * eye
		zone.link_max = 6
	world(tower).add_child(zone)

# Nimbus (tower_design.md "Branch review"): every 4 s its clouds drift to the densest 3×3 in range, the Cloudburst
# sweeping along the way and Soaking what they pass.
static func _update_cloud_drift(tower: Tower, delta: float) -> void:
	var left := float(tower.get_meta(&"cloud_drift", p(tower, "drift_every", 4.0))) - delta
	if left > 0.0:
		tower.set_meta(&"cloud_drift", left)
		return
	tower.set_meta(&"cloud_drift", p(tower, "drift_every", 4.0))
	var to = _densest(tower)
	if to == null:
		return
	for zone in world(tower).get_children():
		if zone is GroundZone and zone.tower == tower and zone.kind == &"rain" and not zone.is_queued_for_deletion():
			zone.drift_to(to)

# --- Undercurrent / Maelstrom: a whirlpool that links ------------------------------------------------------------

# The whirlpool (tower_design.md "Branch review"): every nightmare in it is linked, and a share of any hit on one
# reaches each other linked one. Maelstrom's also Soaks, and a Charged bolt on a linked one travels the current.
static func _whirl(tower: Tower) -> void:
	var route := tower._route()
	var best := Vector2(-1, -1)
	var most := 0
	var radius := p(tower, "radius", 1.5) + tower.area_bonus()
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
	zone.damage_per_second = p(tower, "dps", 14.0)
	zone.link_share = p(tower, "link_share", 0.25)
	zone.link_max = int(p(tower, "link_max", 6))
	if is_final(tower):
		zone.bolt_share = p(tower, "bolt_share", 0.5)
	# Maelstrom Soaks; Eye of the Storm (b): the whirlpool is rained on.
	if is_final(tower) or tower.kin_share(EYE_OF_THE_STORM, "b") > 0.0:
		zone.status = EnemyStatuses.DAMP
	world(tower).add_child(zone)

const LINK_META := &"tide_link"  # On a linked nightmare: the GroundZone that links it

# Tower.hit, after `dealt` landed on `enemy`: a linked nightmare shares it with the others in its current. Effect
# damage: no crit, no on-hit, never shared again, never a Reaction.
static func share_hit(enemy: Node2D, dealt: float, tower: Tower) -> void:
	var zone = enemy.get_meta(LINK_META) if enemy.has_meta(LINK_META) else null  # (get_meta with a null default still errors when missing)
	if not is_instance_valid(zone) or not zone.linked.has(enemy) or zone.link_share <= 0.0:
		return
	# Deep on the Undercurrent: its link share × its Potency, up to LINK_SHARE_CAP.
	var share: float = zone.link_share
	if is_instance_valid(zone.tower) and zone.tower.attack_data != null and zone.tower.attack_data.special == WHIRLPOOL:
		share = minf(share * zone.tower.get_potency(), maxf(share, NurtureChoices.LINK_SHARE_CAP))
	zone.share(enemy, dealt * share, tower.tower_data.line, tower)

# Reactions.strike_bolt: Maelstrom's current carries a Charged bolt to every other linked nightmare at half.
static func share_bolt(enemy: Node2D, damage: float, source: Node) -> void:
	var zone = enemy.get_meta(LINK_META) if is_instance_valid(enemy) and enemy.has_meta(LINK_META) else null
	if not is_instance_valid(zone) or not zone.linked.has(enemy) or zone.bolt_share <= 0.0:
		return
	zone.share(enemy, damage * zone.bolt_share, "light", source)

# --- Jetreed / Torrent: erosion -----------------------------------------------------------------------------------

# A jet (tower_design.md "Branch review"): its target takes the small hit plus a share of its max health (bosses
# less); the jet carries on down the line with the small hit only. Torrent's Flood trail as before.
static func _jet(tower: Tower) -> void:
	var target := tower.find_target()
	if target == null:
		return
	var from := tower.global_position
	var dir := (target.global_position - from).normalized()
	var length := (p(tower, "length", 6.0) + tower.area_bonus()) * CELL
	var share := p(tower, "erosion_boss", 0.005) if target.enemy_data.is_boss else p(tower, "erosion", 0.02)
	# Capped at erosion_cap × the hit's base damage (Balancing: Torrent reached 7–11× its base at drift 61).
	var erosion := minf(float(target.max_health) * share, p(tower, "erosion_cap", 4.0) * tower.get_damage())
	tower.hit(target, 1.0 + erosion / maxf(tower.get_damage(), 1.0))  # The small hit plus the erosion
	for e in targetable(tower):
		if e == target or e.is_flying():
			continue
		var rel: Vector2 = e.global_position - from
		var along := rel.dot(dir)
		if along < 0.0 or along > length or absf(rel.cross(dir)) > CELL * 0.45:
			continue
		tower.hit(e, 1.0)  # Down the line: the small hit only
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

# The arc (tower_design.md de57a7c6; Balancing's numbers): a damaging line. Every nightmare touching a cell of it
# takes arc_dps a second (tagged "fence", the pair taking turns so both jars are credited) and 1 Charged a second; a
# flyer crossing it takes 3 Charged at once. Only the Lightning Fence touches Phantoms gliding through.
const FENCE_TICK := 0.25

static func _update_fence(tower: Tower, delta: float) -> void:
	var partner := _fence_partner(tower)
	if partner == null or partner.get_instance_id() < tower.get_instance_id():
		return  # One side of each pair does the work (the lower id)
	FenceLayer.find(tower).note(tower, partner)
	var left := float(tower.get_meta(&"fence_tick", 0.0)) - delta
	if left > 0.0:
		tower.set_meta(&"fence_tick", left)
		return
	tower.set_meta(&"fence_tick", left + FENCE_TICK)
	var cells := _arc_cells(tower.cell, partner.cell)
	var final := is_final(tower) or is_final(partner)
	var id := tower.get_instance_id()
	for e in targetable(tower):
		var inside := "fence_in_%d" % id
		if not cells.has(Tower.MAP_GRID.calculate_grid_coordinates(e.global_position)):
			if e.has_meta(inside):
				e.remove_meta(inside)  # Left the arc: a flyer can be charged again on its next crossing
			continue
		var phantom: bool = e.is_flying() and e.enemy_data.flying_icon == &"through_walls"
		if phantom and not final:
			continue
		var turn := tower.get_meta(&"fence_turn", 0) as int
		tower.set_meta(&"fence_turn", turn + 1)
		var striker: Tower = tower if turn % 2 == 0 else partner
		var dps := p(striker, "arc_dps", 60.0)
		striker.hit(e, dps * FENCE_TICK / maxf(float(striker.attack_data.damage), 1.0), true, Tower.ROLL_CRIT, &"fence")
		if not is_instance_valid(e) or e.is_cleansed:
			continue
		if e.is_flying() and not e.has_meta(inside):
			e.apply_status(EnemyStatuses.STATIC, int(p(striker, "flyer_charge", 3)), 0.0, striker.get_damage(), 0, "light", striker)
		e.set_meta(inside, true)
		var charge_key := "fence_charge_%d" % id
		var charge := float(e.get_meta(charge_key, p(striker, "charge_every", 1.0))) + FENCE_TICK  # The first on contact
		if charge >= p(striker, "charge_every", 1.0):
			charge = 0.0
			e.apply_status(EnemyStatuses.STATIC, 1, 0.0, striker.get_damage(), 0, "light", striker)
		e.set_meta(charge_key, charge)
		# Fireworks Fence (a): every 2 s a nightmare on the fence sets off a 2-spark burst at half spark damage.
		var spark_key := "fence_spark_%d" % id
		var spark := float(e.get_meta(spark_key, 0.0)) + FENCE_TICK
		if spark >= 2.0:
			spark = 0.0
			for side in [tower, partner]:
				var share: float = side.kin_share(FIREWORKS_FENCE, "a")
				var sparkler: Tower = side._kin_partner()
				if share > 0.0 and is_instance_valid(sparkler) and is_instance_valid(e) and not e.is_cleansed:
					_spark_burst_at(side, e.global_position, 2, float(sparkler.attack_data.damage) * 0.5 * share, false)
		if is_instance_valid(e):
			e.set_meta(spark_key, spark)

# The cells an arc from cell `a` to cell `b` passes over (the jars' own cells left out).
static func _arc_cells(a: Vector2, b: Vector2) -> Dictionary:
	var cells := {}
	var steps := int(ceilf(a.distance_to(b) * 4.0))
	for i in range(1, steps):
		var c := a.lerp(b, float(i) / steps).round()
		if c != a and c != b:
			cells[c] = true
	return cells

# Bonds are sticky (Tower Discussion, as Kinships): a jar keeps its partner while both stand, stay in range and still
# make an arc; only an unbonded jar looks for one, and it never takes a jar that's already linked to another.
const FENCE_BOND := &"fence_bond"

static func _fence_partner(tower: Tower) -> Tower:
	var reach := link_range(tower)
	var held = tower.get_meta(FENCE_BOND) if tower.has_meta(FENCE_BOND) else null
	if _bond_holds(tower, held, reach):
		return held
	var partner := fence_partner_at(tower, tower.cell, reach, tower)
	if partner != null:
		tower.set_meta(FENCE_BOND, partner)
		partner.set_meta(FENCE_BOND, tower)
	elif tower.has_meta(FENCE_BOND):
		tower.remove_meta(FENCE_BOND)
	return partner

static func _bond_holds(tower: Tower, other, reach: float) -> bool:
	return is_instance_valid(other) and other is Tower and other.is_inside_tree() and not other.is_queued_for_deletion() \
		and other.attack_data != null and other.attack_data.special == JARLINK \
		and Kinships._cheb(tower.cell, other.cell) <= reach and not _arc_cells(tower.cell, other.cell).is_empty()

# Whether `jar` is linked to a jar other than `except` (its bond still holding).
static func _bonded_elsewhere(jar: Tower, except: Node) -> bool:
	if not jar.has_meta(FENCE_BOND):
		return false
	var other = jar.get_meta(FENCE_BOND)
	return other != except and _bond_holds(jar, other, link_range(jar))

# The Jarlink a jar on `cell` would link to: the nearest unbonded one within `reach` whose arc would cover at least one
# cell (side by side jars make no arc: Balancing, a second pair planted beside the first cross-linked into nothing).
# `skip`: the jar itself. Also the build ghost's preview (TowerPlacer).
static func fence_partner_at(near: Node, cell: Vector2, reach: float, skip: Node = null) -> Tower:
	var best: Tower = null
	var best_d := INF
	for other in near.get_tree().get_nodes_in_group(Tower.GROUP):
		if other == skip or not (other is Tower) or other.attack_data == null or other.attack_data.special != JARLINK:
			continue
		if _bonded_elsewhere(other, skip):
			continue  # Sticky: never steals a jar from its arc
		var d := Kinships._cheb(cell, other.cell)
		if d <= reach and d < best_d and not _arc_cells(cell, other.cell).is_empty():
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
	var radius := (p(tower, "burst_radius", 1.5) + tower.area_bonus()) * CELL
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
	var reach := (p(tower, "radius", 2.0) + tower.area_bonus()) * CELL
	var hold := SILENCE_TICK * 1.5 + (p(tower, "linger", 2.0) * tower.get_potency() if is_final(tower) else 0.0)
	for e in field(tower):
		if e.global_position.distance_to(tower.global_position) <= reach:
			silence(e, hold, tower)

# Silences `enemy` for `seconds` (no abilities: the Watcher can't wake, Weepers can't mend, boss timers wait).
# Vespers (b): a nightmare a Hushbell silences gains 1 Drowsy.
static func silence(enemy: Node2D, seconds: float, by: Tower) -> void:
	var was: bool = enemy.statuses.silence_time > 0.0
	enemy.statuses.silence_time = maxf(enemy.statuses.silence_time, seconds)
	# Deep on a Hushbell: a silenced boss's timers run slower (Enemy.BOSS_SILENCE_SPEED ÷ Potency, floor 0.35).
	# Enemy reads the meta when it's set (the slowest silencer wins while the silence lasts).
	if is_instance_valid(by) and enemy.enemy_data.is_boss:
		var slow := maxf(0.5 / maxf(by.get_potency(), 1.0), NurtureChoices.BOSS_SILENCE_FLOOR)
		enemy.set_meta(&"silence_boss_speed", minf(slow, float(enemy.get_meta(&"silence_boss_speed", 0.5)) if enemy.has_meta(&"silence_boss_speed") else slow))
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
# --- Phase 2: Whetstone / Edgestone, the finisher --------------------------------------------------------------------

const SIDES: Array[Vector2] = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

# Phase 2's effects play once Tower Assets' art is in effects.json (until then, silently nothing).
static func _fx(effect: StringName, at: Vector2, parent: Node, scale: float = 1.0, seconds: float = 0.0) -> void:
	if parent != null and not Fx.info(effect).is_empty():
		Fx.play(effect, at, parent, scale, true, seconds)

# A segment effect from `from` to `to` (Edgestone's spill, Crown's thorns), or a plain flash before its art.
static func _fx_segment(effect: StringName, from: Vector2, to: Vector2, parent: Node, colour: Color) -> void:
	if parent == null:
		return
	if not Fx.info(effect).is_empty():
		Fx.segment(effect, from, to, parent, 0.3)
	else:
		parent.add_child(LineFlash.new(from, to, colour, 0.25))

const CRACK_TIME := 3.0  # Earthshaker's cracked path, and Fault Line's (× its share)

# Tower.hit: Whetstone's hits on a worn-down nightmare land harder.
static func hit_multiplier(tower: Tower, enemy: Node2D) -> float:
	if tower.attack_data.special != WHETSTONE or enemy.max_health <= 0:
		return 1.0
	if float(enemy.health) >= enemy.max_health * p(tower, "finish_below", 0.3):
		return 1.0
	return p(tower, "finish_boss", 1.5) if enemy.enemy_data.is_boss else p(tower, "finish", 2.5)

# Tower.hit, when its hit dispelled `enemy`: Edgestone's Clean cut spills the overkill onto the nearest nightmare.
static func on_finish(tower: Tower, enemy: Node2D, overkill: float) -> void:
	if tower.attack_data.special != WHETSTONE or not is_final(tower) or overkill <= 0.0:
		return
	var reach := p(tower, "spill_reach", 2.0) * CELL
	var best: Node2D = null
	var best_distance := INF
	for e in targetable(tower):
		var distance: float = e.global_position.distance_to(enemy.global_position)
		if e != enemy and distance <= reach and distance < best_distance:
			best = e
			best_distance = distance
	if best == null:
		return
	_fx_segment(&"clean_spill", enemy.global_position, best.global_position, world(tower), Palette.MOONLIGHT)
	_fx(&"clean_cut", best.global_position, world(tower))
	best.take_damage(overkill * p(tower, "spill", 1.0), tower.tower_data.line, false, false, tower, &"clean_cut")

# --- Phase 2: Rampart / Bastion, stone among stone ---------------------------------------------------------------

# The walls (Thornwall line) on the four sides of `tower`.
static func walls_touching(tower: Tower) -> Array:
	var out := []
	for other in tower._other_towers():
		if other.tower_data.line == "wall" and SIDES.has(other.cell - tower.cell):
			out.append(other)
	return out

# Tower._compute_damage: +15% per wall touching a Rampart (up to 4).
static func damage_multiplier(tower: Tower) -> float:
	if tower.has_meta(&"seeded_by"):
		# Kindred on a Seedbearer: its Sprouts deal 6% more damage per rank.
		var seedbearer = instance_from_id(int(tower.get_meta(&"seeded_by")))
		if seedbearer is Tower and is_instance_valid(seedbearer):
			return 1.0 + NurtureChoices.SEED_KINDRED * seedbearer.choice_count(Tower.Focus.KINDRED)
		return 1.0
	if tower.attack_data.special != RAMPART:
		return 1.0
	return 1.0 + p(tower, "per_wall", 0.15) * mini(walls_touching(tower).size(), int(p(tower, "max_walls", 4)))

# A wall touching a Rampart is stone: it can't be trampled or burrowed under (EnemySpawner / Enemy ask).
static func is_stone(wall: Node) -> bool:
	if not (wall is Tower) or wall.tower_data.line != "wall":
		return false
	for other in wall._other_towers():
		if other.attack_data != null and other.attack_data.special == RAMPART and SIDES.has(other.cell - wall.cell):
			return true
	return false

const STONE_WALL_PATH := "res://assets/towers/%s_stone.png"  # <wall id>_stone.png: Thornwall, Bramble, Honeysuckle (Tower Assets 56c89f99); same layout as the normal sheet

# Tower._show_idle, for a wall gone to stone: its stone sheet (if it has one).
static func idle_texture(tower: Tower) -> Texture2D:
	var path := STONE_WALL_PATH % tower.tower_data.get_id()
	if tower.get_meta(&"stone", false) and ResourceLoader.exists(path):
		return load(path)
	return tower.tower_data.texture

# Tower._refresh_neighbours: a wall turning to stone (a Rampart beside it) or back swaps its sheet, with the
# stone veil rising as it hardens.
static func refresh_stone(tower: Tower) -> void:
	if tower.tower_data.line != "wall":
		return
	var stone := is_stone(tower)
	if stone == bool(tower.get_meta(&"stone", false)):
		return
	tower.set_meta(&"stone", stone)
	if stone and tower.is_inside_tree():
		_fx(&"stone_up", tower.global_position, world(tower))
	tower._show_idle()

static func is_stone_cell(near: Node, cell: Vector2) -> bool:
	for t in near.get_tree().get_nodes_in_group(Tower.GROUP):
		if t is Tower and t.tower_data.line == "wall" and t.cell == cell:
			return is_stone(t)
	return false

# Bastion's Rockfall: every 6 s each stone wall touching it drops a rock on its busiest path tile.
static func _update_rockfall(tower: Tower, delta: float) -> void:
	var left := float(tower.get_meta(&"rock_left", p(tower, "rock_every", 6.0))) - delta
	if left > 0.0:
		tower.set_meta(&"rock_left", left)
		return
	var route := Tower.route_cells(tower._route())  # Whole cells (beside the walls)
	var dropped := false
	for wall in walls_touching(tower):
		var best := Vector2(-1, -1)
		var most := 0
		for side in SIDES:
			var at: Vector2 = wall.cell + side
			if not route.has(at):
				continue
			var count := _count_near(tower, Tower.MAP_GRID.calculate_map_position(at), p(tower, "rock_radius", 1.0) * CELL)
			if count > most:
				most = count
				best = at
		if most > 0:
			_drop_rock(tower, best)
			dropped = true
	tower.set_meta(&"rock_left", p(tower, "rock_every", 6.0) if dropped else 0.25)  # Nothing near: look again soon

static func _count_near(tower: Tower, at: Vector2, reach: float) -> int:
	return targetable(tower).filter(func(e) -> bool: return not e.is_flying() and e.global_position.distance_to(at) <= reach).size()

static func _drop_rock(tower: Tower, cell: Vector2) -> void:
	var at := Tower.MAP_GRID.calculate_map_position(cell)
	_fx(&"rockfall", at, world(tower))
	var share := p(tower, "rock", 150.0) / maxf(float(tower.attack_data.damage), 1.0)  # Scales with ranks and Dreams
	var reach := p(tower, "rock_radius", 1.0) * CELL
	for e in targetable(tower):
		if not e.is_flying() and e.global_position.distance_to(at) <= reach:
			tower.hit(e, share, true)
	var fault := tower.kin_share(FAULT_LINE, "a")
	if fault > 0.0:
		crack(tower, cell, CRACK_TIME * fault)  # Fault Line (a): the rock cracks the path

# --- Phase 2: Quaker / Earthshaker, the interrupt ----------------------------------------------------------------

# The slam (its pulse lands the hits; on_hit stops the sprints): Earthshaker cracks the path in reach for 3 s;
# Fault Line (b) runs the slam along the stone walls touching its Rampart.
static func _quake(tower: Tower) -> void:
	_fx(&"ground_slam", tower.global_position, world(tower), tower.get_range_cells() / 1.5)
	# The slam shakes hidden nightmares loose (Lurkers): revealed 3 s, as Lanternmoth / Rootlight do (doc 219a7a9c).
	var shake := tower.get_range_pixels()
	for e in field(tower):
		if e.has_method("is_hidden") and e.is_hidden() and e.has_method("reveal_for") \
				and e.global_position.distance_to(tower.global_position) <= shake:
			e.reveal_for(p(tower, "reveal_time", 3.0) * tower.get_potency())
	if is_final(tower):
		var reach := tower.get_range_pixels()
		for cell in Tower.route_cells(tower._route()):  # Whole cells: a crack is a path tile
			if Tower.MAP_GRID.calculate_map_position(cell).distance_to(tower.global_position) <= reach:
				crack(tower, cell, p(tower, "crack_time", CRACK_TIME) * tower.get_potency())
	var fault := tower.kin_share(FAULT_LINE, "b")
	var rampart := tower._kin_partner()
	if fault <= 0.0 or not is_instance_valid(rampart):
		return
	var route := Tower.route_cells(tower._route())  # Whole cells (beside the walls)
	var struck := {}
	for wall in walls_touching(rampart):
		for side in SIDES:
			var at: Vector2 = wall.cell + side
			if not route.has(at):
				continue
			for e in targetable(tower):
				if not e.is_flying() and not struck.has(e) and e.get_current_cell() == at:
					struck[e] = true
					tower.hit(e, 0.5 * fault, true)
	if not struck.is_empty():
		tower._kin_fired(FAULT_LINE)

# Cracked path: no new sprints there (Enemy asks is_cracked when a sprint or charge would start).
static func crack(near: Node, cell: Vector2, seconds: float) -> void:
	var field := CrackField.find(near, true)
	if field:
		field.crack(cell, seconds)

static func is_cracked(near: Node, cell: Vector2) -> bool:
	var field := CrackField.find(near, false)
	return field != null and field.cells.has(cell)

# --- Phase 2: Groundroot / Earthbind, anti-air -------------------------------------------------------------------

static func _update_grounding(tower: Tower, delta: float) -> void:
	var left := float(tower.get_meta(&"ground_left", 0.0)) - delta
	if left > 0.0:
		tower.set_meta(&"ground_left", left)
		return
	var reach := (p(tower, "ground_reach", 3.5) + tower.area_bonus()) * CELL
	var flyers := targetable(tower).filter(func(e) -> bool:
		return e.is_flying() and not e.enemy_data.is_boss and e.global_position.distance_to(tower.global_position) <= reach)
	if flyers.is_empty():
		tower.set_meta(&"ground_left", 0.25)
		return
	tower.set_meta(&"ground_left", p(tower, "ground_every", 4.0))
	flyers.sort_custom(func(a, b) -> bool: return a.get_remaining_distance() < b.get_remaining_distance())
	for e in flyers.slice(0, int(p(tower, "ground_max", 2))):
		ground(tower, e)

static func ground(tower: Tower, e: Node2D) -> void:
	if not e.has_method("ground"):
		return  # Enemy's side not in yet
	e.ground(minf(p(tower, "ground_time", 3.0) * tower.get_potency(), NurtureChoices.GROUND_CAP))  # Deep: longer, up to 5 s
	_fx(&"flyer_grab", e.global_position, world(tower))
	if is_final(tower):
		_land_hold(tower, e, p(tower, "land_hold", 0.5))  # Earthbind: Rooted when it lands
	var thorns := tower.kin_share(BRAMBLE_BED, "a")
	var coil := tower._kin_partner()
	if thorns > 0.0 and is_instance_valid(coil) and is_instance_valid(e) and not e.is_cleansed:
		_thorn(coil, e, thorn_per_second(coil) * thorns)  # Bramble Bed (a): it lands in thorns, one tick
		tower._kin_fired(BRAMBLE_BED)

# Rooted, or for a nightmare that can't be Held (Phantoms), a plain pause.
static func _land_hold(tower: Tower, e: Node2D, seconds: float) -> void:
	tower.hold(e, seconds)
	if is_instance_valid(e) and not e.statuses.is_held() and e.has_method("pause"):
		e.pause(seconds)

# --- Phase 2: Deeproot / Heartroot, the goalkeeper ---------------------------------------------------------------

static func _update_goal_guard(tower: Tower, delta: float) -> void:
	var left := float(tower.get_meta(&"guard_tick", 0.0)) - delta
	if left > 0.0:
		tower.set_meta(&"guard_tick", left)
		return
	tower.set_meta(&"guard_tick", 0.25)
	var heart := _heartwood_at(tower)
	if heart == Vector2.INF:
		return
	var reach := (p(tower, "goal_reach", 3.0) + tower.area_bonus(NurtureChoices.REACH_GUARD)) * CELL
	for e in targetable(tower):
		if not e.has_meta(&"deeproot_held") and e.global_position.distance_to(heart) <= reach:
			e.set_meta(&"deeproot_held", true)  # Once each, whichever Deeproot got there first
			_land_hold(tower, e, p(tower, "goal_hold", 1.0))
			_fx(&"goal_hold", e.global_position, world(tower))

static func _heartwood_at(near: Node) -> Vector2:
	var map = world(near).get_node_or_null("%MapGenerator") if world(near) else null
	return Tower.MAP_GRID.calculate_map_position(map.endPath) if map != null else Vector2.INF

# Enemy, as it would reach the Heartwood: Heartroot's "Not yet" drags the drift's first non-boss leak back 4 tiles.
# True = it was dragged back (no leak).
static func before_goal(enemy: Node2D) -> bool:
	if enemy.enemy_data.is_boss or enemy.is_echo:
		return false
	for t in enemy.get_tree().get_nodes_in_group(Tower.GROUP):
		if not (t is Tower) or t.attack_data == null or t.attack_data.special != DEEPROOT or not is_final(t):
			continue
		var drift := _drift_number(t)
		if int(t.get_meta(&"not_yet_drift", -1)) == drift:
			continue
		t.pull(enemy, p(t, "not_yet_tiles", 4.0))
		if enemy.is_dragged():
			t.set_meta(&"not_yet_drift", drift)
			return true
	return false

static func _drift_number(tower: Tower) -> int:
	var dreams = tower._dream_state
	return dreams.drift_director.drifts_started if dreams != null and dreams.drift_director != null else 0

# --- Phase 2: Thorncoil / Crown of Thorns, the payoff for holds --------------------------------------------------

const THORN_TICK := 0.25

static func thorn_per_second(tower: Tower) -> float:
	return p(tower, "thorn_dps", 30.0) * tower.get_damage() / maxf(float(tower.attack_data.damage), 1.0)

static func _thorn(tower: Tower, e: Node2D, amount: float) -> void:
	if amount > 0.0 and is_instance_valid(e) and not e.is_cleansed:
		e.take_damage(amount, tower.tower_data.line, true, false, tower, &"thorns")

static func _update_thorns(tower: Tower, delta: float) -> void:
	var left := float(tower.get_meta(&"thorn_tick", 0.0)) - delta
	if left > 0.0:
		tower.set_meta(&"thorn_tick", left)
		return
	tower.set_meta(&"thorn_tick", THORN_TICK)
	var amount := thorn_per_second(tower) * THORN_TICK
	var reach := tower.get_range_pixels()
	var flyers := tower.kin_share(BRAMBLE_BED, "b")  # Bramble Bed (b): its thorns reach flyers passing over
	var held: Array = []
	for e in targetable(tower):
		if e.global_position.distance_to(tower.global_position) > reach:
			continue
		if e.statuses.is_held():
			held.append(e)
			_thorn(tower, e, amount)
			if _fx_due(e, &"thorn_fx_at", 1.0):
				_fx(&"thorns", e.global_position, e, 1.0, 1.0)  # A loop on its feet while the thorns bite
		elif flyers > 0.0 and e.is_flying():
			_thorn(tower, e, amount * 0.5 * flyers)
	if not is_final(tower) or held.is_empty():
		return
	var spread := amount * p(tower, "spread", 0.5)  # Crown of Thorns: to the nightmares beside a held one
	for e in targetable(tower):
		if held.has(e) or e.is_flying():
			continue
		for h in held:
			if is_instance_valid(h) and e.global_position.distance_to(h.global_position) <= CELL * 1.2:
				_thorn(tower, e, spread)
				if _fx_due(e, &"thorn_spread_at", 0.75):
					_fx_segment(&"thorn_spread", h.global_position, e.global_position, world(tower), Palette.BLOSSOM)
				break

# Throttle for a looping / repeated effect on one nightmare: true once per `every` seconds (meta `key`).
static func _fx_due(e: Node, key: StringName, every: float) -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if e.has_meta(key) and now < float(e.get_meta(key)):
		return false
	e.set_meta(key, now + every)
	return true

# --- Phase 2: Acorn's three economies -------------------------------------------------------------------------------

const LOG_GROUP := &"branch_nurse_logs"  # Nurse / Mother Logs (Tower._apply_data): cost checks look only at them

static func logs(tower: Tower) -> Array:
	return tower.get_tree().get_nodes_in_group(LOG_GROUP).filter(func(t) -> bool:
		return t != tower and is_instance_valid(t) and not t.is_queued_for_deletion()) if tower.is_inside_tree() else []

static func join_groups(tower: Tower) -> void:
	if tower.attack_data != null and tower.attack_data.special == NURSE_LOG:
		tower.add_to_group(LOG_GROUP)
	elif tower.is_in_group(LOG_GROUP):
		tower.remove_from_group(LOG_GROUP)

# Nurse Log: Wardens within 1.5 cells Nurture 25% cheaper (the best log counts; not itself). Tower.get_nurture_price.
static func nurture_multiplier(tower: Tower) -> float:
	var best := 0.0
	for other in logs(tower):
		if other.attack_data != null and other.attack_data.special == NURSE_LOG \
				and Kinships._distance(tower, other) <= p(other, "nurse_radius", 1.5) + NurtureChoices.WIDE_STEP * other.choice_count(Tower.Focus.WIDE):
			best = maxf(best, p(other, "nurture_discount", 0.25) + NurtureChoices.NURSE_STRONG * other.choice_count(Tower.Focus.STRONG))
	return 1.0 - minf(best, NurtureChoices.NURSE_CAP)

# Nursery (b): Wardens beside the Nurse Log also grow 10% cheaper. Tower.get_grow_cost (the base part).
static func grow_multiplier(tower: Tower) -> float:
	var best := 0.0
	for other in logs(tower):
		if other.attack_data != null and other.attack_data.special == NURSE_LOG \
				and absf(other.cell.x - tower.cell.x) <= 1 and absf(other.cell.y - tower.cell.y) <= 1:
			best = maxf(best, 0.10 * other.kin_share(NURSERY, "b"))
	# Kindred on a Nurse Log: Wardens in its reach grow 2% cheaper per rank.
	for other in logs(tower):
		if Kinships._distance(tower, other) <= p(other, "nurse_radius", 1.5) + NurtureChoices.WIDE_STEP * other.choice_count(Tower.Focus.WIDE):
			best = maxf(best, NurtureChoices.NURSE_KINDRED * other.choice_count(Tower.Focus.KINDRED))
	return 1.0 - best

# Mother Log's Remembered rings: a Warden sold in its reach leaves its rank for the next one planted on that cell.
static func remember_rank(sold: Tower) -> void:
	if sold.rank <= 0:
		return
	for other in logs(sold):
		if other.attack_data != null and other.attack_data.special == NURSE_LOG and is_final(other) \
				and Kinships._distance(sold, other) <= p(other, "nurse_radius", 1.5) + NurtureChoices.WIDE_STEP * other.choice_count(Tower.Focus.WIDE):
			var rings: Dictionary = other.get_meta(&"rings", {})
			rings[sold.cell] = [sold.rank, Array(sold.rank_choices)]
			other.set_meta(&"rings", rings)
			return

# TowerPlacer, a Warden just planted: a Mother Log's remembered rank for its cell (once per cell per rest).
static func on_planted(tower: Tower) -> void:
	for other in logs(tower):
		if other.attack_data == null or other.attack_data.special != NURSE_LOG or not other.has_meta(&"rings"):
			continue
		var rings: Dictionary = other.get_meta(&"rings")
		if not rings.has(tower.cell):
			continue
		var ring: Array = rings[tower.cell]
		rings.erase(tower.cell)
		_grant_ranks(tower, int(ring[0]), ring[1])
		return

static func _grant_ranks(tower: Tower, ranks: int, choices: Array = []) -> void:
	for i in mini(ranks, tower.get_max_rank()) - tower.rank:
		var options: Array = tower.focus_options()
		var wanted: int = choices[tower.rank] if tower.rank < choices.size() else -1
		tower.nurture(0, wanted if options.has(wanted) else (options[0] if not options.is_empty() else Tower.Focus.NONE))

# Seedbearer and Dream Oak count drifts (Tower connects drift_cleared / rest_started for them).
static func on_drift_cleared(tower: Tower) -> void:
	match tower.attack_data.special:
		SEEDBEARER:
			var drifts := float(tower.get_meta(&"seed_drifts", 0.0)) + 1.0
			# Swift: a seed sooner (−0.3 drifts per rank, never under 1 drift); fractions carry to the next seed.
			var every := maxf(p(tower, "seed_every", 3.0) - NurtureChoices.SEED_SWIFT * tower.choice_count(Tower.Focus.SWIFT),
				NurtureChoices.SEED_MIN)
			if drifts >= every:
				drifts -= every
				if seeds_alive(tower) + int(tower.get_meta(&"seeds_ready", 0)) < int(p(tower, "seed_max", 3.0)) + yield_ranks(tower) * NurtureChoices.YIELD_SPROUTS:
					tower.set_meta(&"seeds_ready", int(tower.get_meta(&"seeds_ready", 0)) + 1)
					tower.queue_redraw()
			tower.set_meta(&"seed_drifts", drifts)
		DREAM_OAK:
			var shards := 1 + mini(_families_near(tower, p(tower, "family_reach", 2.0) + NurtureChoices.WIDE_STEP * tower.choice_count(Tower.Focus.WIDE)), int(p(tower, "family_max", 3.0)))
			# Yield: +0.5 shard a drift per rank (the fraction carries).
			var extra := float(tower.get_meta(&"yield_carry", 0.0)) + NurtureChoices.YIELD_SHARDS * tower.choice_count(Tower.Focus.YIELD)
			shards += int(extra)
			tower.set_meta(&"yield_carry", extra - int(extra))
			tower.set_meta(&"block_shards", int(tower.get_meta(&"block_shards", 0)) + shards)
			_add_shards(tower, shards)

static func on_rest(tower: Tower, perfect: bool) -> void:
	if tower.attack_data.special == DREAM_OAK:
		if perfect and is_final(tower):
			_add_shards(tower, int(tower.get_meta(&"block_shards", 0)))  # Dreamroot: doubled on a perfect block
		tower.set_meta(&"block_shards", 0)
	elif tower.attack_data.special == NURSE_LOG:
		tower.remove_meta(&"rings")  # Remembered rings last one rest

static func _families_near(tower: Tower, reach: float) -> int:
	var lines := {}
	for other in tower._other_towers():
		if Kinships._distance(tower, other) <= reach and not (other.tower_data.line in ["wall", "sprout", "heartwood", "memory", ""]):
			lines[other.tower_data.line] = true
	return lines.size()

# Dream Oak's shards: 10 = 1 Dreamlight, up to 4 Dreamlight a run from the Oaks (DreamState keeps the count, saved).
static func _add_shards(tower: Tower, shards: int) -> void:
	var dreams = tower._dream_state
	if dreams == null or shards <= 0:
		return
	_fx(&"shard_rise", tower.global_position + Vector2(0, -40), world(tower))
	if dreams.has_method("add_source_shards"):
		dreams.add_source_shards(&"dream_oak", shards, int(p(tower, "dreamlight_max", 4.0)))
	else:
		for i in shards:
			dreams.add_dreamlight_shard()

# Seedbearer's Sprouts on the map now (planted from its seeds).
static func seeds_alive(tower: Tower) -> int:
	var id := tower.get_instance_id()
	return tower._other_towers().filter(func(t) -> bool: return int(t.get_meta(&"seeded_by", 0)) == id).size()

# Tower._draw: a Seedbearer with seeds ready shows a golden seed (with the count past one) at its top right.
static func draw_seed_badge(tower: Tower) -> void:
	var ready := seeds_ready(tower)
	if ready <= 0:
		return
	var at := Vector2(CELL / 2.0 - 10.0, -CELL / 2.0 + 4.0)
	tower.draw_circle(at, 7.0, Color(Palette.ROOT, 0.8))
	tower.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -5), at + Vector2(4, 1), at + Vector2(0, 5), at + Vector2(-4, 1)]), Palette.GOLD)
	if ready > 1:
		tower.draw_string(ThemeDB.fallback_font, at + Vector2(6, 4), str(ready), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Palette.GLOW)

static func seeds_ready(tower: Tower) -> int:
	return int(tower.get_meta(&"seeds_ready", 0)) if tower.attack_data.special == SEEDBEARER else 0

# The cells beside a Seedbearer where its Sprout can go (TowerPlacer checks the path rule).
static func seed_cells(tower: Tower) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx != 0 or dy != 0:
				out.append(tower.cell + Vector2(dx, dy))
	return out

# TowerPlacer planted a Seedbearer's Sprout: it's its own, Grove Keeper's arrive at rank II, Nursery (a) beside the
# Nurse Log at rank I.
static func seed_planted(seedbearer: Tower, sprout: Tower) -> void:
	seedbearer.set_meta(&"seeds_ready", maxi(seeds_ready(seedbearer) - 1, 0))
	sprout.set_meta(&"seeded_by", seedbearer.get_instance_id())
	var ranks := int(p(seedbearer, "seed_rank", 0.0))
	var nursery := seedbearer.kin_share(NURSERY, "a")
	var log := seedbearer._kin_partner()
	if nursery > 0.0 and is_instance_valid(log) and absf(log.cell.x - sprout.cell.x) <= 1 and absf(log.cell.y - sprout.cell.y) <= 1 \
			and Tower._kin_roll(nursery):
		ranks = maxi(ranks, 1)
		seedbearer._kin_fired(NURSERY)
	_grant_ranks(sprout, ranks)
	_fx(&"sprout_puff", sprout.global_position, world(seedbearer))
	seedbearer.queue_redraw()

class CrackField extends Node2D:
	var cells := {}  # Cell -> seconds left

	static func find(near: Node, make: bool) -> CrackField:
		var scene := BranchKit.world(near)
		if scene == null:
			return null
		var found: CrackField = scene.get_node_or_null("CrackField")
		if found == null and make:
			found = CrackField.new()
			found.name = "CrackField"
			found.z_index = -1  # On the ground
			scene.add_child(found)
		return found

	var ages := {}  # Cell -> seconds since it cracked (the sheet forms up, then holds its last frame)
	var _sheet: Texture2D  # path_crack (Tower Assets a4ef4015); on the instance, never static (exit crash)

	func crack(cell: Vector2, seconds: float) -> void:
		if seconds <= 0.0:
			return
		if not cells.has(cell):
			ages[cell] = 0.0
		cells[cell] = maxf(float(cells.get(cell, 0.0)), seconds)
		queue_redraw()

	func _process(delta: float) -> void:
		if cells.is_empty():
			return
		for cell in cells.keys():
			cells[cell] -= delta
			ages[cell] = float(ages.get(cell, 0.0)) + delta
			if cells[cell] <= 0.0:
				cells.erase(cell)
				ages.erase(cell)
		queue_redraw()  # Forming up and fading out

	func _draw() -> void:
		if _sheet == null:
			_sheet = Fx.texture(&"path_crack")
		var info := Fx.info(&"path_crack")
		var frames := int(info.get("frames", 4))
		var fps := float(info.get("fps", 12.0))
		for cell in cells:
			var at := Tower.MAP_GRID.calculate_map_position(cell)
			var fade := clampf(float(cells[cell]) / 0.3, 0.0, 1.0)  # Fades over its last 0.3 s
			if _sheet != null:
				var frame := mini(int(float(ages.get(cell, 0.0)) * fps), frames - 1)
				var size := Vector2(_sheet.get_width() / float(frames), _sheet.get_height())
				draw_texture_rect_region(_sheet, Rect2(at - size / 2.0, size), Rect2(Vector2(size.x * frame, 0), size),
					Color(1, 1, 1, fade))  # A fade (modulate), not a colour
				continue
			var colour := Color(Palette.ROOT, 0.7 * fade)  # No art: a few dark cracks across the tile
			draw_polyline(PackedVector2Array([at + Vector2(-24, -6), at + Vector2(-6, 2), at + Vector2(4, -8), at + Vector2(22, 4)]), colour, 2.0)
			draw_polyline(PackedVector2Array([at + Vector2(-6, 2), at + Vector2(-2, 18)]), colour, 2.0)

# --- Brood Cap's reach (user: "show where it places its sprites… and where it ends") ---------------------------------
# A sprite hatches on the route point nearest the Warden and walks back toward the start at sprite_speed cells/s for
# SPRITE_LIFE s, so it gives up after speed × life cells (3 × 8 = 24) or at the route's start, whichever is first.
const SPRITE_LIFE := 8.0
const BROOD_PATH := Color(Palette.NEWLEAF, 0.22)
const BROOD_END := Color(Palette.SPRIG, 0.75)

static func brood_spawn_index(route: PackedVector2Array, at: Vector2) -> int:
	var best := 0
	var best_d := INF
	for i in route.size():
		var d := Tower.MAP_GRID.calculate_map_position(route[i]).distance_to(at)
		if d < best_d:
			best_d = d
			best = i
	return best

# The walk in world points, from the hatch spot to where it gives up (cut mid-step at the exact distance).
static func brood_walk(route: PackedVector2Array, at: Vector2, speed_cells: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if route.is_empty():
		return out
	var i := brood_spawn_index(route, at)
	var left := speed_cells * SPRITE_LIFE * CELL
	var here := Tower.MAP_GRID.calculate_map_position(route[i])
	out.append(here)
	while i > 0 and left > 0.0:
		var next := Tower.MAP_GRID.calculate_map_position(route[i - 1])
		var step := here.distance_to(next)
		if step >= left:
			out.append(here.move_toward(next, left))
			break
		left -= step
		here = next
		out.append(here)
		i -= 1
	return out

# Draws the walk on `canvas` (`walk` already in its local space): the stretch faint when `stretch`, and the end mark
# (Tower Assets' brood_end when it exists, else a ring with a small cap). `alpha` scales it (subtle while sprites walk).
static func draw_brood_walk(canvas: CanvasItem, walk: PackedVector2Array, stretch: bool, alpha: float = 1.0) -> void:
	if walk.size() < 2:
		return
	if stretch:
		canvas.draw_polyline(walk, Color(BROOD_PATH, BROOD_PATH.a * alpha), 6.0)
	var end: Vector2 = walk[-1]
	var tex := Fx.texture(&"brood_end") if not Fx.info(&"brood_end").is_empty() else null
	if tex != null:
		var size := Vector2(tex.get_width(), tex.get_height())
		canvas.draw_texture_rect(tex, Rect2(end - size / 2.0, size), false, Color(1, 1, 1, alpha))  # A fade (modulate), not a colour
		return
	var colour := Color(BROOD_END, BROOD_END.a * alpha)
	canvas.draw_arc(end, 9.0, 0.0, TAU, 20, colour, 1.5)
	canvas.draw_colored_polygon(PackedVector2Array([end + Vector2(-5, 1), end + Vector2(0, -5), end + Vector2(5, 1)]), colour)

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
		var best := BranchKit.brood_spawn_index(path, t.global_position)  # The route point nearest the Warden
		var spot := Tower.MAP_GRID.calculate_map_position(path[best])
		# Where it drops (on the attack's release frame): Tower Assets' hatch puff, and the spore arc from the attack
		# origin when its art exists (Fx keeps budget / lite / reduced motion).
		BranchKit._fx(&"brood_hatch", spot, BranchKit.world(t))
		if not Fx.info(&"spore_arc").is_empty():
			Fx.segment(&"spore_arc", t.global_position + t.tower_data.get_attack_origin(), spot, BranchKit.world(t), 0.35)
		t.queue_redraw()  # Its end marker shows while sprites are out
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
		tower.hit(enemy, 1.0 + NurtureChoices.YIELD_BROOD_DAMAGE * tower.choice_count(Tower.Focus.YIELD), true)  # Yield: harder bursts
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

	func _exit_tree() -> void:
		if is_instance_valid(tower):
			tower.queue_redraw()  # The last sprite gone: its end marker goes

	const SHEET := "res://assets/towers/projectiles/spore_sprite.png"  # 4 walk frames drawn walking right (any size)
	var _tex: Texture2D = load(SHEET) if ResourceLoader.exists(SHEET) else null  # Per sprite (cached): never a static
	var _age := 0.0
	var _left_facing := false

	func _draw() -> void:
		if _tex == null:
			var r := 7.0 if big else 4.5
			draw_circle(Vector2.ZERO, r, Color(Palette.NEWLEAF, 0.9))
			draw_circle(Vector2(0, -r * 0.4), r * 0.45, Color(Palette.SPRIG, 0.9))
			return
		var frame_size := Vector2(_tex.get_width() / 4.0, _tex.get_height())  # 4 walk frames, whatever their size
		var size := frame_size * (1.5 if big else 1.0)  # Hatchery's big one, scaled up
		var frame := int(_age * 8.0) % 4
		var region := Rect2(frame * frame_size.x, 0, frame_size.x, frame_size.y)
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
	# The current (tower_design.md "Branch review"): the nightmares inside are linked (up to link_max, nearest the
	# centre first); link_share of a hit on one reaches each other one (BranchKit.share_hit), bolt_share of a Charged
	# bolt (Maelstrom). Water threads join them, pulsing when a hit is shared.
	var link_share := 0.0
	var link_max := 6
	var bolt_share := 0.0
	var linked: Array = []
	var _pulse := 0.0
	# Nimbus: the cloud drifts to a new spot (drift_to), Soaking what it passes.
	var _drift_from := Vector2.ZERO
	var _drift_to := Vector2.ZERO
	var _drift_t := -1.0
	const DRIFT_TIME := 0.6
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
		if _drift_t >= 0.0:
			_drift_t = minf(_drift_t + delta / DRIFT_TIME, 1.0)
			global_position = _drift_from.lerp(_drift_to, 1.0 - pow(1.0 - _drift_t, 2.0))
			if _drift_t >= 1.0:
				_drift_t = -1.0
		_pulse = maxf(_pulse - delta, 0.0)
		_next -= delta
		if _next <= 0.0:
			_next += tick
			_tick()
		queue_redraw()

	func _exit_tree() -> void:
		for e in linked:
			if is_instance_valid(e) and e.has_meta(BranchKit.LINK_META) and e.get_meta(BranchKit.LINK_META) == self:
				e.remove_meta(BranchKit.LINK_META)
		linked = []

	# Nimbus: drift to `to` (the Cloudburst sweeping along, Soaking every nightmare within a cell of the way).
	func drift_to(to: Vector2) -> void:
		if to.distance_to(global_position) < 1.0:
			return
		_drift_from = global_position
		_drift_to = to
		_drift_t = 0.0
		var seg := to - global_position
		for e in BranchKit.targetable(tower):
			var t := clampf((e.global_position - global_position).dot(seg) / maxf(seg.length_squared(), 1.0), 0.0, 1.0)
			if e.global_position.distance_to(global_position + seg * t) <= CELL:
				tower._apply_one_status(e, EnemyStatuses.DAMP, 1, tower.get_damage())
		for i in 3:
			Fx.play(&"rain_sweep", global_position + seg * (i / 2.0), get_parent(), 1.0)

	# Shares `amount` from `from` with every other linked nightmare (effect damage, tagged "linked").
	func share(from: Node2D, amount: float, line: String, source: Node) -> void:
		if amount <= 0.0:
			return
		_pulse = 0.3
		for other in linked:
			if other != from and is_instance_valid(other) and not other.is_cleansed:
				other.take_damage(amount, line, true, false, source, &"linked")

	func _inside(e: Node2D) -> bool:
		var d: Vector2 = (e.global_position - global_position).abs()
		return (maxf(d.x, d.y) <= radius) if square else (e.global_position.distance_to(global_position) <= radius)

	func _tick() -> void:
		if link_share > 0.0:
			_relink()
		for e in BranchKit.targetable(tower):
			if (e.is_flying() and not hits_flyers) or not _inside(e):
				continue
			if damage_per_second > 0.0 and kind == &"rain":
				# Rain is effect damage (tag "rain": Potency and Deep scale it), with the Warden's damage multipliers.
				e.take_damage(damage_per_second * tick * tower.get_damage() / maxf(float(tower.attack_data.damage), 1.0),
					tower.tower_data.line, true, false, tower, &"rain")
			elif damage_per_second > 0.0:
				tower.hit(e, damage_per_second * tick / maxf(float(tower.attack_data.damage), 1.0), true)
			if not is_instance_valid(e) or e.is_cleansed:
				continue
			if status != &"":
				tower._apply_one_status(e, status, status_stacks, tower.get_damage())

	# The nightmares inside now (walkers; flyers too under a rain cloud), nearest the centre first, up to link_max.
	func _relink() -> void:
		var inside := BranchKit.targetable(tower).filter(func(e) -> bool:
			return (hits_flyers or not e.is_flying()) and _inside(e))
		inside.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(global_position) < b.global_position.distance_squared_to(global_position))
		var now := inside.slice(0, link_max)
		for e in linked:
			if is_instance_valid(e) and not now.has(e) and e.has_meta(BranchKit.LINK_META) and e.get_meta(BranchKit.LINK_META) == self:
				e.remove_meta(BranchKit.LINK_META)
		for e in now:
			e.set_meta(BranchKit.LINK_META, self)
		linked = now

	func _draw() -> void:
		# Water threads between linked nightmares, brighter while a hit is shared.
		if linked.size() > 1:
			var thread := Color(Palette.DEWLIGHT, 0.35 + 0.5 * (_pulse / 0.3))
			for i in range(1, linked.size()):
				if is_instance_valid(linked[i - 1]) and is_instance_valid(linked[i]):
					draw_line(linked[i - 1].global_position - global_position, linked[i].global_position - global_position, thread, 1.5)
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
		if not leaders.has(leader.get_instance_id()):
			_dark_art(leader, true)  # Its lantern goes dark (Enemy Assets' <kind>_silenced frames)
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
			_dark_art(leader, false)
			leaders.erase(id)

	# The lantern-off look while silenced: `<frames>_silenced.tres` beside the nightmare's own frames, swapped 1:1.
	func _dark_art(leader: Node2D, dark: bool) -> void:
		var own: SpriteFrames = leader.enemy_data.sprite_frames
		if own == null or not leader.has_method("_swap_frames"):
			return
		if not dark:
			leader._swap_frames(own)
			return
		var path := own.resource_path.get_basename() + "_silenced.tres"
		var dark_frames: SpriteFrames = load(path) if ResourceLoader.exists(path) else null
		if dark_frames != null:
			leader._swap_frames(dark_frames)

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
