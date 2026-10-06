class_name DewCatch
extends RefCounted

# The economy Wardens' catch (warden_stats.md, screens_ui.md "Support and economy feedback", 2026-09-29).
# A nightmare dispelled near a catcher (Dewcatcher, Wellspring, or an Elder Stump with the Old Growth
# Kinship) drops more Dew: the extra goes into the catcher's bowl (a gold pop, a droplet arcing in, the
# bowl filling) and is poured into the Dew counter at the rest, the Harvest, followed by the
# Wellspring's interest. Several catchers never stack on one nightmare: the highest catch applies.
# RunState calls catch() on every dispel; the first catcher on the map hooks the rest (hook()).
# Signals for Sound / UI are on Tower: dew_caught, harvest_poured, interest_paid.

const INTEREST_CAP := 130  # All Wellsprings together pay at most this per rest (Balancing 2026-10-05: one Wellspring at Kindred V reaches 130)
const OLD_GROWTH_CATCH := 0.25  # Elder Stump with the Dewcatcher kin: +25% in its aura (× the bond's share)
const DEW_BOWL_STEP := 0.15  # Dew Bowl (Seed card): +15% catch per stack
const WIDE_BOWL_STEP := 0.5  # Dew Trail (any level): +0.5 cells catch radius (Wide Bowl merged into it)
const DEW_TRAIL := [0.30, 0.50]  # Dew Trail / II: more when the caught nightmare is Damp (dream_audit.md)
const HARVEST_MOON := 0.5  # Harvest Moon (Seed card): the Harvest pays +50%
const DEEP_WELL_CAP := 30  # Deep Well (Seed card): each Wellspring's interest cap +30
const OVERFLOW_PER_SHARD := 50  # Overflowing Well: each 50 Dew of interest over the cap = a Dreamlight shard
const BOWL_FULL := 60.0  # Dew in the bowl that shows it full
const GOLD := Palette.GLOW
const DROPLETS_PER_SECOND := 6  # Catch droplets share the effects budget (below Harmony sparks)
const DROPLET_TIME := 0.45
const HARVEST_DROPLETS := 5
const HARVEST_FLIGHT := 0.8

static var _droplet_times: Array[int] = []
static var _bowl_data := {}

# --- The catch ---------------------------------------------------------------------------------

# The best catch on `enemy` among `towers`: [tower, share], or [] when none reaches it.
static func best_for(enemy: Node2D, towers: Array) -> Array:
	var best: Array = []
	for tower in towers:
		if not tower is Tower or tower.is_queued_for_deletion():
			continue
		var share: float = tower.get_catch_share(enemy)
		if share > 0.0 and (best.is_empty() or share > best[1]):
			best = [tower, share]
	return best

# RunState: `enemy` was dispelled and paid `scaled_dew` (its Dew after act scaling and Dew gain, before
# rounding). Adds the catch to the best catcher's bowl and returns that catcher (null = not caught).
static func catch(enemy: Node2D, scaled_dew: float) -> Tower:
	if enemy == null or not enemy.is_inside_tree() or scaled_dew <= 0.0:
		return null
	var best := best_for(enemy, enemy.get_tree().get_nodes_in_group(Tower.GROUP))
	if best.is_empty():
		return null
	var tower: Tower = best[0]
	var amount: float = scaled_dew * best[1]
	tower.add_to_bowl(amount)
	tower.dew_caught.emit(tower, enemy.global_position, amount)
	var log := SupportLog.find(tower)
	if log:
		log.add(tower, &"dew_caught", amount)
	_droplet(enemy.global_position, tower)
	return tower

# The bowl's surface on `tower`, in world space (attacks.json "bowls"; else the attack point).
static func bowl_point(tower: Tower) -> Vector2:
	var info := bowl_info(tower.tower_data)
	var local: Vector2 = tower.tower_data.get_attack_origin()
	if info.has("point") and info.has("frame"):
		# Bigger art (Tower Assets 2c398d71): x in the frame's width, y from the top of the cell (its bottom 64 rows):
		# relative to the Warden's cell centre, no sprite offset.
		return tower.to_global(Vector2(info.point[0] - info.frame[0] / 2.0, info.point[1] - 32.0))
	if info.has("point"):
		local = Vector2(info.point[0] - 32.0, info.point[1] - 32.0)
	return tower.sprite.to_global(local + tower.sprite.offset) if tower.sprite else tower.global_position + local

# attacks.json "bowls" entry for a catcher ({} if none): point, radius, dy_by_frame.
static func bowl_info(data: TowerData) -> Dictionary:
	var key := data.art_id if data.art_id != "" else data.get_id()
	if not _bowl_data.has(key):
		var entry := {}
		if FileAccess.file_exists(TowerData.ATTACKS_JSON):
			var json = JSON.parse_string(FileAccess.get_file_as_string(TowerData.ATTACKS_JSON))
			if typeof(json) == TYPE_DICTIONARY:
				entry = json.get("bowls", {}).get(key, {})
		_bowl_data[key] = entry
	return _bowl_data[key]

# --- The Harvest -------------------------------------------------------------------------------

# Hooks the rest (the Harvest, then interest), once per run.
static func hook(director: DriftDirector, run_state: RunState) -> void:
	if director == null or run_state == null or director.has_meta(&"dew_catch"):
		return
	director.set_meta(&"dew_catch", true)
	director.rest_started.connect(func(block: int, _boss: bool, _bonus: int, _perfect: bool) -> void:
		pour_all(director, run_state, block))

# At the rest: every bowl pours into the Dew counter (the Harvest), then each Wellspring pays interest.
static func pour_all(director: DriftDirector, run_state: RunState, block: int) -> void:
	if run_state.is_over or run_state.get_meta(&"harvest_block", -1) == block:
		return
	run_state.set_meta(&"harvest_block", block)
	var tree := director.get_tree()
	var dreams := tree.get_first_node_in_group(DreamState.GROUP) as DreamState
	var harvest_multiplier := 1.0 + (HARVEST_MOON if dreams and dreams.has_rule(&"harvest_moon") else 0.0)
	var towers := tree.get_nodes_in_group(Tower.GROUP).filter(func(t: Node) -> bool:
		return t is Tower and not t.is_queued_for_deletion())
	var log := SupportLog.find(director)
	var delay := 0.0
	for tower in towers:
		var dew := floori(tower.bowl * harvest_multiplier + 0.0001)
		tower.empty_bowl()
		if dew <= 0:
			continue
		_pay(run_state, tower, dew, log)
		tower.harvest_poured.emit(tower, dew)
		_pour_effect(tower, dew, delay)
		delay += 0.25
	# Interest (Wellspring) on the banked Dew, harvest included.
	var paid := 0
	for tower in towers:
		var data: TowerData = tower.tower_data
		if data.rest_interest <= 0.0:
			continue
		var rate: float = data.rest_interest + Tower.KINDRED_INTEREST * tower.choice_count(Tower.Focus.KINDRED)  # Kindred Wellspring ranks
		var cap: int = data.rest_interest_max + (DEEP_WELL_CAP if dreams and dreams.has_rule(&"deep_well") else 0) \
			+ NurtureChoices.WELL_CAP_KINDRED * tower.choice_count(Tower.Focus.KINDRED)  # Kindred: a higher cap too (audit b6f44fac)
		var uncapped := run_state.dew * rate
		var dew := mini(mini(floori(uncapped), cap), INTEREST_CAP - paid)
		if dreams and dreams.has_rule(&"overflowing_well") and uncapped > cap:
			for i in floori((uncapped - cap) / OVERFLOW_PER_SHARD):
				dreams.add_dreamlight_shard()  # Capped at 2 Dreamlight a run inside DreamState
		if dew <= 0:
			continue
		paid += dew
		_pay(run_state, tower, dew, log)
		tower.interest_paid.emit(tower, dew)
		tower.sap_yielded.emit(tower, dew)
		_interest_effect(tower, dew, delay)
		delay += 0.25

static func _pay(run_state: RunState, tower: Tower, dew: int, log: SupportLog) -> void:
	run_state.add_dew(dew)
	run_state.dew_harvested += dew
	if log:
		log.add(tower, &"dew_paid", dew)

# --- Looks -------------------------------------------------------------------------------------

# A droplet arcing from the dispel into the catcher's bowl (throttled; none with reduce flashes).
static func _droplet(from: Vector2, tower: Tower) -> void:
	if Fx.reduce_flashes():
		return
	var now := Time.get_ticks_msec()
	while not _droplet_times.is_empty() and now - _droplet_times[0] > 1000:
		_droplet_times.pop_front()
	if _droplet_times.size() >= DROPLETS_PER_SECOND:
		return
	_droplet_times.append(now)
	var world := Reactions._world(tower)
	if world:
		Fx.play(&"dew_pop_gold", from, world)  # Behind the gold "+N Dew"
		Arc.fly(world, from, bowl_point(tower), DROPLET_TIME, 28.0)

static func _pour_effect(tower: Tower, dew: int, delay: float) -> void:
	var world := Reactions._world(tower)
	if world == null:
		return
	var at := bowl_point(tower)
	var popup := DewPopup.new(dew, at, GOLD, "Harvest +%d Dew" % dew)
	popup.process_mode = Node.PROCESS_MODE_ALWAYS  # The rest's Dream screen pauses the game
	world.add_child(popup)
	if Fx.reduce_flashes():
		return  # A simple count-up: the popup and the counter
	var pour := Fx.play(&"harvest_pour", at, world)
	if pour:
		pour.process_mode = Node.PROCESS_MODE_ALWAYS
	var target = _dew_counter_world(tower)
	if target == null:
		return
	for i in HARVEST_DROPLETS:
		var bead := Arc.fly(world, at, target, HARVEST_FLIGHT, 60.0 + 12.0 * i, delay + 0.06 * i,
			&"harvest_splash" if i == HARVEST_DROPLETS - 1 else &"")
		bead.process_mode = Node.PROCESS_MODE_ALWAYS  # Harvest beads play under the rest's pause

static func _interest_effect(tower: Tower, dew: int, delay: float) -> void:
	var world := Reactions._world(tower)
	if world:
		var popup := DewPopup.new(dew, bowl_point(tower) + Vector2(0, -14), GOLD, "Interest +%d Dew" % dew)
		popup.process_mode = Node.PROCESS_MODE_ALWAYS
		world.add_child(popup)

# The HUD's Dew counter, as a world position right now (null without a HUD).
static func _dew_counter_world(near: Node) -> Variant:
	var label := near.get_tree().get_first_node_in_group(&"dew_label") as Control
	if label == null:
		var scene := near.owner if near.owner else near
		label = scene.get_node_or_null("%DewLabel") as Control
	if label == null or not label.is_visible_in_tree():
		return null
	var screen := label.get_global_rect().get_center()
	return near.get_viewport().get_canvas_transform().affine_inverse() * screen

# A dew_catch_droplet flying along an arc from `from` to `to` (world), rotated to its travel; plays
# `land` where it lands. Script-only node, in the world.
class Arc:
	extends Node2D

	var _from: Vector2
	var _to: Vector2
	var _control: Vector2
	var _time: float
	var _age := 0.0
	var _delay: float
	var _land: StringName

	static func fly(world: Node, from: Vector2, to: Vector2, seconds: float, lift: float,
			delay: float = 0.0, land: StringName = &"") -> Arc:
		var arc := Arc.new()
		arc._from = from
		arc._to = to
		arc._control = (from + to) / 2.0 + Vector2(0, -lift - from.distance_to(to) * 0.25)
		arc._time = maxf(seconds, 0.05)
		arc._delay = delay
		arc._land = land
		arc.z_index = 11
		arc.visible = delay <= 0.0
		world.add_child(arc)
		arc.global_position = from
		Fx.play(&"dew_catch_droplet", from, arc)
		return arc

	func _process(delta: float) -> void:
		if _delay > 0.0:
			_delay -= delta
			visible = _delay <= 0.0
			return
		_age += delta
		var t := minf(_age / _time, 1.0)
		var before := global_position
		global_position = _from.lerp(_control, t).lerp(_control.lerp(_to, t), t)
		if global_position != before:
			rotation = before.angle_to_point(global_position)
		if t >= 1.0:
			if _land != &"":
				var splash := Fx.play(_land, global_position, get_parent())
				if splash:
					splash.process_mode = Node.PROCESS_MODE_ALWAYS
			queue_free()
