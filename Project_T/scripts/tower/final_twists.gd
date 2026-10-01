class_name FinalTwists
extends RefCounted

# Signature twists for the flat final forms (tower_design.md "Signature twists for the other finals",
# 2026-09-30): each gets a small new rule inside its family's job. Tower calls in at a few hooks
# (update, landing, neighbours, attack start, beam tick, freeze, rings, cloud ticks); a Warden's own
# state lives in Tower._twist_state. Holds are the Held status; bosses get the boss Held rule (halved).
# Placeholder visuals (FxRing / effects already in the sheet) until Tower Assets' art lands.
# Logjam (Snugroot) and the heal half of Veil (Morning Fog) need Enemy Code's hooks: see
# LOGJAM_META and EnemyStatuses.veil_time.

const TWISTS := {
	"snugroot": &"logjam", "dreamshroom": &"dream_spores", "boulderback": &"landslide",
	"lullaby_bell": &"chorus", "morning_fog": &"veil", "hoarfrost": &"shatter_chain", "beacon": &"flare",
	"midsummer": &"solstice", "starcave": &"starlit_snare", "great_dreamcatcher": &"mended_leaves",
	"grafted_elder": &"double_graft", "starling_murmuration": &"dark_swirl", "zephyr": &"gale_lane",
	"windmill": &"momentum", "elf_circle": &"fairy_dance"}

const DREAM_SPORES_EVERY := 1.0  # Dreamshroom: each sleeper breathes 1 Spored a second…
const DREAM_SPORES_REACH := 1.0  # …onto nightmares within 1 cell
const LANDSLIDE_EVERY := 4  # Boulderback: every 4th hit…
const LANDSLIDE_TILES := 2  # …rolls a boulder 2 path tiles back toward the start…
const LANDSLIDE_SHARE := 0.6  # …hitting everything on them for 60% of the hit
const CHORUS_PER := 0.1  # Lullaby Bell: +10% per other Bellflower-family Warden…
const CHORUS_MAX := 0.4  # …up to +40%…
const CHORUS_REACH := 3.0  # …within 3 cells
const SHATTER_REACH := 1.0  # Hoarfrost: a frozen nightmare dispelled freezes those within 1 cell…
const SHATTER_FREEZE := 0.5  # …for 0.5 s (shard-frozen ones don't chain)
const FLARE_EVERY := 8.0  # Beacon: every 8 s…
const FLARE_REVEAL := 2.0  # …the whole map is revealed for 2 s…
const FLARE_MARKS := 5  # …and the 5 nightmares furthest along, anywhere, are Marked
const SOLSTICE_TIME := 2.0  # Midsummer: at full ramp the beam forks onto a second target for 2 s
const SNARE_HOLD := 0.5  # Starcave: each lit tile Holds its first walker each drift for 0.5 s
const SNARE_CHECK := 0.1
const MENDED_EVERY := 25  # Great Dreamcatcher: every 25 Caught dispels (bosses count 5)…
const MENDED_BOSS := 5
const MENDED_MAX := 3  # …restore 1 leaf, at most 3 a run
const SWIRL_EVERY := 6.0  # Starling Murmuration: every 6 s a swirl on the busiest path tile in range…
const SWIRL_TIME := 2.0  # …for 2 s…
const SWIRL_REACH := 0.5  # …1 cell across…
const SWIRL_HOLD := 0.5  # …stops each Phantom (flyer) gliding through it for 0.5 s (a pause, not Held), once each
const GALE_EVERY := 10.0  # Zephyr: every 10 s a gust sweeps 3 path tiles in range…
const GALE_TILES := 3  # …copying the most afflicted nightmare's statuses (half stacks) onto everything there
const MOMENTUM_PER_SECOND := 0.05  # Windmill: +5% attack speed a second with nightmares in reach…
const MOMENTUM_MAX := 0.5  # …up to +50%…
const MOMENTUM_IDLE := 2.0  # …back to 0 after 2 s with nothing in reach
const DANCE_RINGS := 3  # Elf Circle: a nightmare setting off 3 of its rings in one walk…
const DANCE_HOLD := 1.0  # …is Held 1 s (once per nightmare)
const LOGJAM_META := &"logjam"  # Snugroot: set on the nightmares it Holds (Enemy Code's spawner jams their cell)

const SWIRL_COLOR := Color(Palette.SHADE, 0.7)
const GOLD := Palette.GLOW

static func twist_of(data: TowerData) -> StringName:
	return TWISTS.get(data.get_id(), &"") if data != null else &""

# Every frame for a Warden with a twist (after its legacy / ability updates).
static func update(tower: Tower, delta: float) -> void:
	var state: Dictionary = tower._twist_state
	match tower._twist:
		&"dream_spores":
			if _tick(state, &"spores", delta, DREAM_SPORES_EVERY):
				_dream_spores(tower)
		&"flare":
			if _tick(state, &"flare", delta, FLARE_EVERY, true):
				flare(tower)
		&"dark_swirl":
			if _tick(state, &"swirl", delta, SWIRL_EVERY, true):
				_start_swirl(tower)
			_update_swirl(tower, state, delta)
		&"gale_lane":
			if _tick(state, &"gale", delta, GALE_EVERY, true):
				gale(tower)
		&"momentum":
			_update_momentum(tower, state, delta)
			_update_momentum_art(tower, state.get(&"momentum", 0.0))
		&"chorus":
			if not state.has(&"notes") and tower.has_signal("attack_released"):
				state[&"notes"] = true
				tower.attack_released.connect(tower._twist_released)  # A note per voice on each pulse
		&"double_graft":
			_update_graft_glows(tower)
		&"starlit_snare":
			if _tick(state, &"snare", delta, SNARE_CHECK):
				_starlit_snare(tower, state)
		&"solstice":
			state[&"solstice"] = maxf(state.get(&"solstice", 0.0) - delta, 0.0)
		&"mended_leaves", &"shatter_chain":
			_listen_for_dispels(tower, state)

# Counts `key` down; true (and resets to `every`) when it runs out. `need_targets`: waits while nothing
# is in range (the first one goes as soon as something is).
static func _tick(state: Dictionary, key: StringName, delta: float, every: float, need_targets := false) -> bool:
	var left: float = state.get(key, 0.0) - delta
	if left > 0.0:
		state[key] = left
		return false
	state[key] = every
	return true

# Every nightmare on the field, hidden ones too (the spawner's children).
static func _field(tower: Tower) -> Array:
	var container: Node = tower._dream_state.get_node_or_null("%EnemyContainer") if tower._dream_state else null
	if container == null:
		return tower.get_tree().get_nodes_in_group(Tower.ENEMY_GROUP)
	return container.get_children().filter(func(e: Node) -> bool:
		return e.has_method("take_damage") and not e.is_cleansed and not e.is_queued_for_deletion())

static func _hold(tower: Tower, enemy: Node2D, seconds: float) -> void:
	if not is_instance_valid(enemy) or enemy.is_cleansed or Reactions.cant_be_held(enemy):
		return
	tower.hold(enemy, seconds * (0.5 if enemy.enemy_data.is_boss else 1.0))  # The boss Held rule

# Plays twist art `effect` at `at` (Tower Assets' sheets, effects.json kind "signature"); a ring in
# `colour` if the sheet is missing. `seconds` > 0 keeps a looping sheet that long; `tint` modulates it.
static func _fx(tower: Tower, effect: StringName, at: Vector2, colour: Color, seconds := 0.0, tint := Color.WHITE) -> Node2D:
	var parent := Reactions._world(tower)
	var node: Node2D = Fx.play(effect, at, parent, 1.0, true, seconds) if parent != null and not Fx.info(effect).is_empty() else null
	if node == null:
		_ring(tower, at, colour, 40.0, maxf(seconds, 0.5))
		return null
	node.z_index = Fx.Z
	node.modulate = tint
	return node

static func _ring(tower: Tower, at: Vector2, colour: Color, grow := 60.0, life := 0.6) -> void:
	var parent := Reactions._world(tower)
	if parent == null or tower.get_tree() == null:
		return
	var ring := Fx.FxRing.new(colour, 12.0, grow, life)
	ring.z_index = Fx.Z
	parent.add_child(ring)
	ring.global_position = at

# --- Dreamshroom: Dream spores ------------------------------------------------------------------------

static func _dream_spores(tower: Tower) -> void:
	var reach := DREAM_SPORES_REACH * Tower.MAP_GRID.cell_size.x
	for sleeper in tower.get_enemies_in_range():
		if not sleeper.statuses.is_asleep():
			continue
		for other in Tower.nightmares_near(tower.get_tree(), sleeper.global_position, reach):
			if other != sleeper and not other.is_cleansed and other.global_position.distance_to(sleeper.global_position) <= reach:
				tower._apply_one_status(other, EnemyStatuses.SPORED, 1, tower.get_damage())
		_fx(tower, &"dream_spore_puff", sleeper.global_position, Color(Palette.BLOSSOM, 0.5), DREAM_SPORES_EVERY)  # Pink on purpose

# --- Boulderback: Landslide ---------------------------------------------------------------------------

# After a landing on `target`: every 4th rolls a boulder along the 2 path tiles behind it.
static func landslide(tower: Tower, target: Node2D) -> void:
	var state := tower._twist_state
	state[&"hits"] = int(state.get(&"hits", 0)) + 1
	if state[&"hits"] % LANDSLIDE_EVERY != 0 or not is_instance_valid(target):
		return
	var route: PackedVector2Array = tower._route()
	var at: Vector2 = target.get_current_cell()
	var index := route.find(at)
	if index < 0:
		return
	var tiles: Array[Vector2] = []
	for step in range(1, LANDSLIDE_TILES + 1):
		if index - step >= 0:
			tiles.append(route[index - step])  # Toward the start
	for enemy in tower.get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		if enemy != target and tiles.has(enemy.get_current_cell()):
			tower.hit(enemy, LANDSLIDE_SHARE, true, Tower.NO_CRIT)
	if not tiles.is_empty():  # A boulder rolls back along the path, dust trailing behind it
		var from := target.global_position
		var to := Tower.MAP_GRID.calculate_map_position(tiles[-1])
		Fx.segment(&"landslide_dust", from, to, Reactions._world(tower), 0.5)
		var boulder := _fx(tower, &"landslide_boulder", from, Color(Palette.DEADWOOD, 0.7), 0.5)
		if boulder != null:
			boulder.create_tween().tween_property(boulder, "global_position", to, 0.45)
	state[&"landslides"] = int(state.get(&"landslides", 0)) + 1

# --- Lullaby Bell: Chorus -----------------------------------------------------------------------------

# Its damage bonus from the other Bellflower-family Wardens within 3 cells (read by _refresh_neighbours).
static func chorus_bonus(tower: Tower, voices: int) -> float:
	return minf(CHORUS_PER * voices, CHORUS_MAX) if tower._twist == &"chorus" else 0.0

# --- Hoarfrost: Shatter chain / Great Dreamcatcher: Mended leaves ----------------------------------------

# Hoarfrost froze `enemy` (a real freeze: it can chain).
static func frozen(tower: Tower, enemy: Node2D) -> void:
	if tower._twist == &"shatter_chain" and is_instance_valid(enemy):
		enemy.set_meta(&"hoar_frozen", true)

static func _listen_for_dispels(tower: Tower, state: Dictionary) -> void:
	if state.has(&"listening"):
		return
	var container: Node = tower._dream_state.get_node_or_null("%EnemyContainer") if tower._dream_state else null
	if container == null or not container.has_signal("enemy_cleansed"):
		return
	state[&"listening"] = true
	container.enemy_cleansed.connect(tower._twist_dispelled)  # A Warden method: disconnects when it goes

# A nightmare was dispelled (Hoarfrost and the Great Dreamcatcher listen).
static func dispelled(tower: Tower, enemy: Node2D) -> void:
	if not is_instance_valid(enemy):
		return
	match tower._twist:
		&"shatter_chain":
			if not enemy.get_meta(&"hoar_frozen", false) or not enemy.statuses.is_held():
				return
			var reach := SHATTER_REACH * Tower.MAP_GRID.cell_size.x
			for other in Tower.nightmares_near(tower.get_tree(), enemy.global_position, reach):
				if other != enemy and not other.is_cleansed and other.global_position.distance_to(enemy.global_position) <= reach:
					other.set_meta(&"hoar_frozen", false)  # Shard-frozen: doesn't chain again
					_hold(tower, other, SHATTER_FREEZE)
			_fx(tower, &"shatter_chain_burst", enemy.global_position, Color(Palette.DEWLIGHT, 0.8))
		&"mended_leaves":
			if not enemy.statuses.is_caught() or enemy.global_position.distance_to(tower.global_position) \
					> tower.get_range_cells() * Tower.MAP_GRID.cell_size.x:
				return
			var run_state = tower._dream_state.run_state if tower._dream_state else null
			if run_state == null:
				return
			var count: int = int(run_state.get_meta(&"mended_count", 0)) + (MENDED_BOSS if enemy.enemy_data.is_boss else 1)
			var mended: int = run_state.get_meta(&"mended_leaves", 0)
			while count >= MENDED_EVERY and mended < MENDED_MAX:
				count -= MENDED_EVERY
				mended += 1
				run_state.regrow_leaves(1)  # The only leaf healing outside act breaks
				_mended_leaf(tower)
			run_state.set_meta(&"mended_count", count)
			run_state.set_meta(&"mended_leaves", mended)

# --- Beacon: Flare ------------------------------------------------------------------------------------

static func flare(tower: Tower) -> void:
	var field := _field(tower)
	if field.is_empty():
		tower._twist_state[&"flare"] = 0.0  # Nothing out there yet: flare as soon as there is
		return
	for enemy in field:
		enemy.reveal_for(FLARE_REVEAL)
	field.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.get_remaining_distance() < b.get_remaining_distance())
	for enemy in field.slice(0, FLARE_MARKS):
		tower._apply_one_status(enemy, EnemyStatuses.MARKED, 1, tower.get_damage())
		if is_instance_valid(enemy) and enemy.statuses.has(EnemyStatuses.MARKED):
			enemy.statuses.marked_extra = maxf(enemy.statuses.marked_extra, tower.attack_data.marked_bonus)
	_fx(tower, &"beacon_flare", tower.global_position, GOLD)
	_beacon_pulse(tower)

# --- Midsummer: Solstice ------------------------------------------------------------------------------

# Each beam tick (after the main hit): at full ramp, 2 s on a second target (the ramp stays).
static func solstice_tick(tower: Tower, share: float) -> void:
	var state := tower._twist_state
	var at_full: bool = tower._beam_ramp >= tower.attack_data.beam_ramp_max - 0.001
	if at_full and state.get(&"solstice", 0.0) <= 0.0 and not state.get(&"solstice_spent", false):
		state[&"solstice"] = SOLSTICE_TIME
		state[&"solstice_spent"] = true  # Once per full ramp: a new ramp (a new target) can fork again
		if is_instance_valid(tower._beam_target):
			var fork := _fx(tower, &"solstice_fork", tower._beam_target.global_position, GOLD)
			if fork != null:
				fork.rotation = tower.global_position.angle_to_point(tower._beam_target.global_position)
	if not at_full:
		state[&"solstice_spent"] = false
	if state.get(&"solstice", 0.0) <= 0.0:
		return
	var second: Node2D = null
	for enemy in tower.get_enemies_in_range():
		if enemy != tower._beam_target and (second == null or enemy.get_remaining_distance() < second.get_remaining_distance()):
			second = enemy
	state[&"fork"] = second
	if second != null:
		tower.hit(second, share)

# --- Starcave: Starlit snare --------------------------------------------------------------------------

static func _starlit_snare(tower: Tower, state: Dictionary) -> void:
	var drift: int = tower._dream_state.drift_director.drifts_started if tower._dream_state and tower._dream_state.drift_director else 0
	if state.get(&"snare_drift", -1) != drift:
		state[&"snare_drift"] = drift
		state[&"snared"] = {}
	var snared: Dictionary = state[&"snared"]
	for enemy in tower.get_enemies_in_range():
		if enemy.is_flying():
			continue
		var at: Vector2 = enemy.get_current_cell()
		if tower._lit_cells.has(at) and not snared.has(at):
			snared[at] = true
			_hold(tower, enemy, SNARE_HOLD)
			_fx(tower, &"starlit_snare", Tower.MAP_GRID.calculate_map_position(at), GOLD)

# --- Grafted Elder: Double graft ----------------------------------------------------------------------

# Before each attack: the next of its two borrowed attacks.
static func next_graft(tower: Tower) -> void:
	var pair: Array = tower._twist_state.get(&"graft_pair", [])
	if pair.size() < 2:
		return
	var index: int = (int(tower._twist_state.get(&"graft_turn", 0)) + 1) % 2
	tower._twist_state[&"graft_turn"] = index
	var next: TowerData = pair[index]
	if next != tower.attack_data:
		tower._stop_beam()
		tower.attack_data = next

# --- Starling Murmuration: Dark swirl -----------------------------------------------------------------

static func _start_swirl(tower: Tower) -> void:
	var best := Vector2(-1, -1)
	var best_count := 0
	var reach := 0.75 * Tower.MAP_GRID.cell_size.x  # Its own tile (not the neighbours')
	for at in tower._route():
		if not tower._is_cell_in_range(at):
			continue
		var centre := Tower.MAP_GRID.calculate_map_position(at)
		var count := 0
		for enemy in tower.get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
			if enemy.global_position.distance_to(centre) <= reach:
				count += 1
		if count > best_count:
			best_count = count
			best = at
	if best_count == 0:
		tower._twist_state[&"swirl"] = 0.0  # Try again next frame
		return
	tower._twist_state[&"swirl_at"] = Tower.MAP_GRID.calculate_map_position(best)
	tower._twist_state[&"swirl_left"] = SWIRL_TIME
	_fx(tower, &"dark_swirl", tower._twist_state[&"swirl_at"], SWIRL_COLOR, SWIRL_TIME)

static func _update_swirl(tower: Tower, state: Dictionary, delta: float) -> void:
	var left: float = state.get(&"swirl_left", 0.0)
	if left <= 0.0:
		return
	state[&"swirl_left"] = left - delta
	var at: Vector2 = state[&"swirl_at"]
	var reach := SWIRL_REACH * Tower.MAP_GRID.cell_size.x
	for enemy in tower.get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		if enemy.is_flying() and not enemy.has_meta(&"swirled") and enemy.global_position.distance_to(at) <= reach:
			enemy.set_meta(&"swirled", true)
			# Swept up in the flock: a plain pause, not Held (Phantoms stay immune to Held; no Reactions).
			enemy.hold_time = maxf(enemy.hold_time, SWIRL_HOLD * (0.5 if enemy.enemy_data.is_boss else 1.0))

# --- Zephyr: Gale lane --------------------------------------------------------------------------------

static func gale(tower: Tower) -> void:
	var in_range := tower.get_enemies_in_range()
	var source: Node2D = null
	for enemy in in_range:
		if source == null or enemy.statuses.total_stacks() > source.statuses.total_stacks():
			source = enemy
	if source == null or source.statuses.total_stacks() == 0:
		tower._twist_state[&"gale"] = 0.0  # Nothing to carry yet: try again next frame
		return
	# The 3 path tiles in range nearest the Heartwood (route order).
	var tiles: Array[Vector2] = []
	var route: PackedVector2Array = tower._route()
	for i in range(route.size() - 1, -1, -1):
		if tower._is_cell_in_range(route[i]):
			tiles.append(route[i])
			if tiles.size() >= GALE_TILES:
				break
	var copied: Array = source.statuses.snapshot()
	for enemy in tower.get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
		if enemy == source or not tiles.has(enemy.get_current_cell()):
			continue
		for status in copied:
			enemy.apply_status(status.id, maxi(ceili(status.stacks / 2.0), 1), status.time, status.potency, 0,
				status.line, status.source)
	if tiles.size() >= 2:  # A gust streaks along the lane
		var streak := Fx.segment(&"gale_lane", Tower.MAP_GRID.calculate_map_position(tiles[-1]),
			Tower.MAP_GRID.calculate_map_position(tiles[0]), Reactions._world(tower), 0.6)
		if streak != null:
			streak.modulate = Color(Palette.MIST, 0.8)
			streak.z_index = Fx.Z
	tower._twist_state[&"gales"] = int(tower._twist_state.get(&"gales", 0)) + 1

# --- Windmill: Momentum -------------------------------------------------------------------------------

static func _update_momentum(tower: Tower, state: Dictionary, delta: float) -> void:
	var busy := not tower.get_enemies_in_range().is_empty()
	var idle: float = 0.0 if busy else state.get(&"idle", 0.0) + delta
	state[&"idle"] = idle
	var momentum: float = state.get(&"momentum", 0.0)
	if busy:
		momentum = minf(momentum + MOMENTUM_PER_SECOND * delta, MOMENTUM_MAX)
	elif idle >= MOMENTUM_IDLE:
		momentum = 0.0
	state[&"momentum"] = momentum

static func momentum(tower: Tower) -> float:
	return tower._twist_state.get(&"momentum", 0.0) if tower._twist == &"momentum" else 0.0

# --- Elf Circle: Fairy dance --------------------------------------------------------------------------

# `enemy` set off one of `tower`'s rings.
static func ring_stepped(tower: Tower, enemy: Node2D) -> void:
	if tower._twist != &"fairy_dance" or not is_instance_valid(enemy) or enemy.has_meta(&"danced"):
		return
	var steps: int = int(enemy.get_meta(&"rings_stepped", 0)) + 1
	enemy.set_meta(&"rings_stepped", steps)
	if steps >= DANCE_RINGS:
		enemy.set_meta(&"danced", true)
		_hold(tower, enemy, DANCE_HOLD)
		_fx(tower, &"fairy_dance", enemy.global_position, Color(Palette.BLOSSOM, 0.8), DANCE_HOLD)

# --- Morning Fog: Veil --------------------------------------------------------------------------------

# Each fog tick: nothing inside can hide (Lurkers are revealed) or be healed (EnemyStatuses.veil_time,
# read by Enemy.heal).
static func veil(cloud: Node2D, radius: float, seconds: float) -> void:
	var tower: Tower = cloud._tower
	if not is_instance_valid(tower) or tower._twist != &"veil":
		return
	for enemy in _field(tower):
		if enemy.global_position.distance_to(cloud.global_position) <= radius:
			if enemy.is_hidden():
				enemy.reveal_for(seconds)
				_veil_glint(tower, enemy.global_position)
			enemy.statuses.veil_time = maxf(enemy.statuses.veil_time, seconds)

# --- Snugroot: Logjam ---------------------------------------------------------------------------------

# Snugroot Held `enemy`: a maze walker it holds jams its cell (Enemy Code's spawner reads the meta).
static func jammed(tower: Tower, enemy: Node2D) -> void:
	if tower._twist == &"logjam" and is_instance_valid(enemy) and not enemy.is_flying():
		enemy.set_meta(LOGJAM_META, true)
		_logjam_knot(tower, enemy)


# --- Visible moments (Tower Assets' art, cdd37305) ----------------------------------------------------

# Great Dreamcatcher: a leaf drifts from the dreamcatcher to the Heartwood.
static func _mended_leaf(tower: Tower) -> void:
	var map = tower._dream_state.map_generator if tower._dream_state else null
	var heart: Vector2 = Tower.MAP_GRID.calculate_map_position(map.endPath) if map else tower.global_position
	var leaf := _fx(tower, &"mended_leaf", tower.global_position, Color(Palette.LEAF, 0.8), 1.2)
	if leaf != null:
		leaf.create_tween().tween_property(leaf, "global_position", heart, 1.1).set_trans(Tween.TRANS_SINE)

# Beacon: one radial wash over the whole map, in fast (0.2 s) and out slow (1 s).
static func _beacon_pulse(tower: Tower) -> void:
	if Fx.reduce_flashes():
		return
	var centre := Vector2(Tower.MAP_GRID.size) * Tower.MAP_GRID.cell_size / 2.0
	var wash: Node2D = Fx.play(&"beacon_pulse", centre, Reactions._world(tower),
		maxf(Tower.MAP_GRID.size.x, Tower.MAP_GRID.size.y) * Tower.MAP_GRID.cell_size.x / 64.0, true, 1.2)
	if wash == null:
		return
	wash.z_index = Fx.Z
	wash.modulate.a = 0.0
	var tween := wash.create_tween()
	tween.tween_property(wash, "modulate:a", 1.0, 0.2)
	tween.tween_property(wash, "modulate:a", 0.0, 1.0)

# Snugroot: a root knot under the jammed nightmare for the Hold.
static func _logjam_knot(tower: Tower, enemy: Node2D) -> void:
	var seconds: float = enemy.statuses.time_left(EnemyStatuses.HELD)
	var knot := _fx(tower, &"logjam_knot", enemy.global_position, Color(Palette.BARK, 0.7), maxf(seconds, 0.3))
	if knot != null:
		knot.z_index = -1  # On the ground, under the nightmare

# Lullaby Bell: a note per voice around the pulse.
static func _chorus_notes(tower: Tower) -> void:
	var voices := roundi(tower._chorus / CHORUS_PER)
	for i in voices:
		var at := tower.global_position + Vector2.from_angle(TAU * i / maxf(voices, 1) - PI / 2.0) * 26.0
		_fx(tower, &"chorus_note", at, Color(Palette.GLOW, 0.8), 0.6, Palette.GLOW)

# Grafted Elder: two glows in its borrowed attacks' colours, breathing opposite each other.
static func _update_graft_glows(tower: Tower) -> void:
	var pair: Array = tower._twist_state.get(&"graft_pair", [])
	for side in ["a", "b"]:
		var glow := tower.get_node_or_null("GraftGlow_" + side) as Node2D
		if pair.size() < 2:
			if glow:
				glow.queue_free()
			continue
		if glow == null:
			glow = Fx.play(StringName("double_graft_glow_" + side), tower.global_position, tower, 1.0, false)
			if glow == null:
				continue
			glow.name = "GraftGlow_" + side
			glow.z_index = 1
		var colour: Color = pair[0 if side == "a" else 1].projectile_color
		glow.modulate = Color(colour, 0.9 if (tower.attack_data == pair[0]) == (side == "a") else 0.5)

# Windmill: the sails spin up, three levels by the ramp (frames 0-3, 4-7, 8-11).
static func _update_momentum_art(tower: Tower, momentum: float) -> void:
	var art := tower.get_node_or_null("Momentum") as Sprite2D
	if momentum <= 0.0:
		if art:
			art.visible = false
		return
	var entry := Fx.info(&"windmill_momentum")
	if art == null:
		var tex := Fx.texture(&"windmill_momentum")
		if tex == null or entry.is_empty():
			return
		art = Sprite2D.new()
		art.name = "Momentum"
		art.texture = tex
		art.hframes = int(entry.frames)
		art.centered = false
		art.offset = -Vector2(entry.anchor[0], entry.anchor[1])
		art.position = Vector2(9, 19) - Vector2(32, 32) + tower.tower_data.sprite_offset  # The sail hub
		art.modulate = Color(Palette.MOONLIGHT, 0.85)
		tower.add_child(art)
	art.visible = true
	var level := 0 if momentum < MOMENTUM_MAX / 3.0 else (1 if momentum < MOMENTUM_MAX * 2.0 / 3.0 else 2)
	art.frame = level * 4 + int(tower._anim_time * float(entry.get("fps", 12.0))) % 4

# Morning Fog: a glint where the fog cancels something (a Lurker revealed).
static func _veil_glint(tower: Tower, at: Vector2) -> void:
	_fx(tower, &"veil_glint", at, Color(Palette.GLOW, 0.7), 0.0, Color(1, 1, 1, 0.7))  # multiplier
