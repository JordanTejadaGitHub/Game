extends Node
class_name SoundHooks

# Connects the run's signals to the Sound autoload (audio_direction.md), so gameplay scripts never
# know about audio, and drives the adaptive music layers from what's on the field:
# base always · dread1 while nightmares are in the dream · dread2 when many, or any in the last
# third of the path · heartbeat at 5 leaves or fewer · boss drums while a boss walks.
# Does nothing if the autoload is missing (e.g. a test run without it).

const MAP_GRID = preload("res://resource/map/map_grid.tres")
# EnemyData file name -> the nightmare's signature sound (played when one enters the dream).
const SIGNATURES := {
	"leaf_bug": &"sig_shade", "bark_beetle": &"sig_husk", "dusk_moth": &"sig_lurker",
	"dandelion_seed": &"sig_phantom", "hedgehog": &"sig_hound", "mother_duck": &"sig_procession",
	"wandering_hare": &"sig_sleepwalker", "puffcap": &"sig_mourner", "mother_spider": &"sig_widow",
	"old_stag": &"sig_stag", "great_toad": &"sig_hag",
}
const SIGNATURE_INTERVAL_MS := 2500  # One signature per nightmare type this often at most
const DREAD2_COUNT := 12
const LOW_LEAVES := 5
const QUIET_LINES := ["wall"]  # Wardens that never attack
# Attacks (audio_direction.md "Wardens"): a quiet launch when the Warden fires, the impact on the hit.
const LAUNCH_DB := -15.0
const HIT_DB := -3.0  # ~6 dB above the first placeholder attacks
const EVENT_DB := -4.0  # Warden events (clouds, traps, storms, catches, echoes...)
const CHAIN_STEP_PITCH := 0.97  # Each chain jump also a little lower
const PECK_RATE := 6.0  # Hummingbird pecks per second (for loudness × rate)
const BEAM_HOLD := 0.5  # Seconds a loop stays up after its last tick
const LIT_HOLD := 2.0
const SPIN_HOLD := 1.0
const FIRST_BREATH_DELAY := 0.6  # Evolve bloom, then the new form's hit
const PLOP_DELAY := 0.25
const SLEEP_INTERVAL_MS := 1500
# Pulse Wardens whose sound should stay rare (ms between two).
const PULSE_THROTTLE_MS := {"bramble": 800, "honeysuckle": 3000, "acorn": 5000}
# Sound id prefixes a Warden can have (warden_sounds, tests).
const EVENT_PREFIXES := ["attack_", "hit_", "drowsy_", "pop_", "cloud_", "fog_", "sleep_", "trap_", "trigger_",
	"crit_", "storm_", "loop_", "echo_", "shard_", "place_", "plop_", "dew_", "turn_", "catch_"]
const HIT_FAMILIES := ["stone", "root", "water", "light", "spore", "sprout"]  # Others sound like sprout
const HIT_GROUP_MS := 90  # A pulse or splash hitting many nightmares at once is one impact
const CHAIN_STEP_DB := -4.0  # Each jump of a chain ripples a little quieter
const CLOUD_HIT_MS := 400  # A cloud's lingering ticks are silent; only its landing hits
const RESISTED_DB := -3.0
const WEAK_DB := 2.0
const DEW_DB := -6.0  # Lump sums of Dew (rest bonus, Omen rewards): a soft, low rustle of light
# Ambience (audio_direction.md "Ambience"): thins out with the field, swells at rests.
const AMBIENCE_THIN_DB := -8.0  # At AMBIENCE_THIN_COUNT nightmares or more
const AMBIENCE_THIN_COUNT := 15
const AMBIENCE_REST_DB := 3.0

@onready var sound: Node = get_node_or_null("/root/Sound")
@onready var run_state = %RunState
@onready var map_generator = %MapGenerator
@onready var enemy_container = %EnemyContainer
@onready var tower_container: Node2D = %TowerContainer
@onready var tower_placer = %TowerPlacer
@onready var tower_seller = %TowerSeller
@onready var drift_director = %DriftDirector
@onready var dream_state = %DreamState
@onready var omen_director = %OmenDirector

var _last_signature := {}  # sound id -> msec
var _path_pixels := 1.0
var _choice_screens: Array[Control] = []
var _hit_groups := {}  # Tower instance id -> [first hit msec, hits since]
var _released_at := {}  # Tower instance id -> msec of its last attack release
var _attack_counts := {}  # Tower instance id -> attacks released (storms, sleepier bells)
var _loop_until := {}  # loop id -> [until msec, level]
var _slept_at := {}  # Warden id -> msec of its last sleep drone

func _ready() -> void:
	if sound == null:
		set_process(false)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	for path in ["HUD/FamilyPickScreen", "HUD/DreamScreen", "HUD/OmenScreen", "HUD/PauseMenu", "HUD/ResultsScreen"]:
		var screen := owner.get_node_or_null(path) as Control
		if screen:
			_choice_screens.append(screen)

	enemy_container.child_entered_tree.connect(_on_enemy_added)
	enemy_container.enemy_cleansed.connect(func(enemy: Node2D) -> void:
		sound.play_dispel(enemy.global_position, enemy.enemy_data.is_boss))
	enemy_container.enemy_reached_goal.connect(func(_enemy: Node2D) -> void:
		sound.duck(8.0, 1.0)
		sound.play(&"leaf_lost", null, 0.0, 1.0, 0.03))
	enemy_container.enemy_split.connect(func(parent: Node2D, child: Node2D) -> void:
		if parent.is_cleansed:  # Followers (Wraiths) also come through here; only real splits crack
			sound.play(&"split", child.global_position, -4.0))
	enemy_container.wall_trampled.connect(func(cell: Vector2, _by: Node2D) -> void:
		sound.duck(8.0, 1.0)
		sound.play(&"trample", MAP_GRID.calculate_map_position(cell), 2.0))

	tower_container.child_entered_tree.connect(_on_tower_added)
	tower_placer.tower_built.connect(func(tower: Tower) -> void:
		sound.play(&"plant", tower.global_position)
		_event("place_", tower, tower.global_position))  # The White Stag arriving
	tower_placer.build_rejected.connect(func(_cell: Vector2) -> void: sound.ui(&"invalid"))
	tower_seller.tower_sold.connect(func(tower: Tower, _refund: int) -> void:
		sound.play(&"sell", MAP_GRID.calculate_map_position(tower.cell)))
	map_generator.obstacle_cleared.connect(func(cell: Vector2, data: ObstacleData) -> void:
		var id := &"move" if data.resource_path.get_file().begins_with("rock") else &"tend"
		sound.play(id, MAP_GRID.calculate_map_position(cell)))
	map_generator.path_changed.connect(_on_path_changed)

	run_state.dew_short.connect(func(_cost: int) -> void: sound.ui(&"invalid"))
	# No Dew sound per kill (third listen: kills sounded like coins); only lump sums make one.
	run_state.run_ended.connect(_on_run_ended)

	drift_director.drift_started.connect(func(_number: int) -> void: sound.play(&"drift_start", null, -4.0, 1.0, 0.0))
	drift_director.rest_started.connect(func(_block: int, _boss: bool, bonus: int, _perfect: bool) -> void:
		sound.play(&"rest", null, -2.0, 1.0, 0.0)
		if bonus > 0:
			sound.play(&"dew", null, DEW_DB, 1.0, 0.0))
	omen_director.omen_rewarded.connect(func(_omen: OmenData, _summary: String) -> void:
		sound.play(&"dew", null, DEW_DB, 1.0, 0.0))
	drift_director.act_started.connect(func(_act: int, _regrown: int) -> void: sound.play(&"act_swell", null, 0.0, 1.0, 0.0))
	drift_director.family_pick_requested.connect(func(_reason: StringName) -> void:
		sound.play(&"family_bell", null, 0.0, 1.0, 0.0, &"UI"))
	dream_state.offer_ready.connect(func(_cards: Array[UpgradeData], _drift: int) -> void:
		sound.play(&"dream_open", null, -2.0, 1.0, 0.0, &"UI"))
	dream_state.card_taken.connect(func(card: UpgradeData) -> void:
		sound.play(StringName("dream_take_%d" % clampi(int(card.rarity), 0, 2)), null, 0.0, 1.0, 0.0, &"UI"))
	omen_director.offer_ready.connect(func(_omens: Array[OmenData], _block: int) -> void:
		sound.play(&"omen_wind", null, -2.0, 1.0, 0.0, &"UI"))
	# The Codex: a combo fired for the first time ever (its card slides in).
	var combo_feedback := owner.get_node_or_null("%ComboFeedback")
	if combo_feedback != null and combo_feedback.has_signal("combo_discovered"):
		combo_feedback.combo_discovered.connect(func(_id: StringName) -> void:
			sound.play(&"combo_found", null, -3.0, 1.0, 0.0, &"UI"))

	sound.play_music(&"act1", [&"base"])
	sound.play_ambience(&"act1")
	_on_path_changed()

func _exit_tree() -> void:
	if sound != null:
		sound.set_muffled(false)
		sound.set_drifting(false)
		sound.set_ambience_trim(0.0)
		sound.stop_ambience()
		sound.stop_loops()

func _process(_delta: float) -> void:
	var enemies: Array = enemy_container.get_enemies()
	var near := false
	var boss := false
	for enemy in enemies:
		boss = boss or enemy.enemy_data.is_boss
		near = near or enemy.get_remaining_distance() < _path_pixels / 3.0
	sound.set_layer(&"dread1", not enemies.is_empty())
	sound.set_layer(&"dread2", enemies.size() >= DREAD2_COUNT or near)
	sound.set_layer(&"heartbeat", run_state.leaves <= LOW_LEAVES and not run_state.is_over)
	sound.set_layer(&"boss", boss)
	sound.set_muffled(_choice_screens.any(func(screen: Control) -> bool: return screen.visible))
	var resting: bool = drift_director.is_build_phase()
	sound.set_drifting(not resting)
	if resting:
		sound.set_ambience_trim(AMBIENCE_REST_DB)
	else:
		sound.set_ambience_trim(AMBIENCE_THIN_DB * minf(float(enemies.size()) / AMBIENCE_THIN_COUNT, 1.0))
	_update_loops()

func _on_enemy_added(enemy: Node) -> void:
	# Its position is set right after it enters the tree, so wait a frame.
	_play_signature.call_deferred(enemy)
	if enemy.has_signal("leaped"):
		enemy.leaped.connect(func(e: Node2D) -> void:
			if e.enemy_data.is_boss:
				sound.duck(8.0, 1.0)
			sound.play(&"hag_rise", e.global_position))

# Untyped on purpose: the nightmare may be freed before this deferred call runs.
func _play_signature(enemy) -> void:
	if not is_instance_valid(enemy) or enemy.enemy_data == null:
		return
	var id: StringName = SIGNATURES.get(enemy.enemy_data.resource_path.get_file().get_basename(), &"")
	if id == &"":
		return
	var now := Time.get_ticks_msec()
	if now - int(_last_signature.get(id, -100000)) < SIGNATURE_INTERVAL_MS:
		return
	_last_signature[id] = now
	if enemy.enemy_data.is_boss:
		sound.duck(8.0, 1.0)
	# Deeply Blighted: the same sound, pitched down.
	sound.play(id, enemy.global_position, 2.0 if enemy.enemy_data.is_boss else -3.0, 0.8 if enemy.elite else 1.0)

# --- Wardens (audio_direction.md "Warden sound sheet") ---------------------------------------------
# Every Warden looks up its own sounds by its file name: attack_<id> (launch), hit_<id>, events
# (<event>_<id>) and loops (loop_<id>), falling back to its family's attack_<line> / hit_<line>.
# Sprout and Firefly Jar are their families' sounds. A Graftling plays the Warden it copies, muffled
# through bark. Loudness × rate stays even: fast Wardens are quieter per shot (`_rate_db`).

static func warden_id(data: TowerData) -> String:
	return data.resource_path.get_file().get_basename()

# Every sound a Warden can make that exists (tests check each built Warden has at least one).
static func warden_sounds(snd: Node, data: TowerData) -> Array[StringName]:
	var found: Array[StringName] = []
	for prefix in EVENT_PREFIXES:
		for id in [prefix + warden_id(data), prefix + data.line]:
			if snd.has_sound(StringName(id)) and not found.has(StringName(id)):
				found.append(StringName(id))
	return found

func _sound_for(prefix: String, data: TowerData) -> StringName:
	for id in [prefix + warden_id(data), prefix + data.line]:
		if sound.has_sound(StringName(id)):
			return StringName(id)
	return &""

# Plays `<prefix><warden id>` (no family fallback: events belong to one Warden) if it exists.
func _event(prefix: String, tower: Tower, at: Vector2, volume_db := EVENT_DB) -> void:
	var id := StringName(prefix + warden_id(tower.attack_data))
	if sound.has_sound(id):
		sound.play(id, at, volume_db, 1.0, 0.03, _bus_for(tower))

func _bus_for(tower: Tower) -> StringName:
	if tower.get_copied() == null:
		return &"SFX"
	return &"SFXBark" if warden_id(tower.tower_data) == "grafted_elder" else &"SFXMuffled"

# Loudness × rate stays even: −7 dB per tenfold rate, clamped (a 6/s peck is near-subliminal, a
# 1-per-3-s Standing Stone lands full).
static func _rate_db(rate: float) -> float:
	return clampf(-7.0 * log(maxf(rate, 0.05)) / log(10.0), -9.0, 3.0)

static func _hit_rate(data: TowerData) -> float:
	return PECK_RATE if data.attack_kind == TowerData.AttackKind.PECK else data.attacks_per_second

# Keeps loop `id` at `level` for `hold` more seconds (SoundHooks._process fades it out after).
func _touch_loop(id: String, level: float, hold: float) -> void:
	_loop_until[StringName(id)] = [Time.get_ticks_msec() + int(hold * 1000.0), level]

func _update_loops() -> void:
	var now := Time.get_ticks_msec()
	for tower in tower_container.get_children():
		if tower is Tower and tower.attack_data.attack_kind == TowerData.AttackKind.AURA:
			# The White Stag: a faint breathing presence, fuller while nightmares walk.
			_touch_loop("loop_" + warden_id(tower.attack_data), 1.0 if not enemy_container.get_enemies().is_empty() else 0.35, 0.2)
	for id in _loop_until.keys():
		var entry: Array = _loop_until[id]
		var active: bool = now < int(entry[0])
		sound.set_loop(id, float(entry[1]) if active else 0.0)
		if not active:
			_loop_until.erase(id)

func _on_tower_added(node: Node) -> void:
	var tower := node as Tower
	if tower == null or tower.attack_released.is_connected(_on_attack):
		return
	tower.attack_released.connect(_on_attack)
	tower.hit_landed.connect(_on_hit)
	# Evolving: the bloom, then the new form's hit once as a "first breath".
	tower.evolved.connect(func(t: Tower) -> void:
		sound.play(&"evolve", t.global_position)
		get_tree().create_timer(FIRST_BREATH_DELAY).timeout.connect(func() -> void:
			if is_instance_valid(t):
				var id := _sound_for("hit_", t.attack_data)
				if id != &"":
					sound.play(id, t.global_position, HIT_DB, 1.0, 0.03, _bus_for(t))))
	# The hit's own sound plays too. Most crits add a low punch and a soft, low bell; some Wardens
	# have their own (Moonstone's bell-stone, Jewelwing's fuller tap), Magpie's Hoard adds its trinkets.
	tower.crit_landed.connect(func(t: Tower, enemy: Node2D) -> void:
		var own := StringName("crit_" + warden_id(t.attack_data))
		if sound.has_sound(own):
			sound.play(own, enemy.global_position, EVENT_DB, 1.0, 0.03, _bus_for(t))
		else:
			sound.play(&"crit", enemy.global_position, -6.0)
			sound.play(&"crit_punch", enemy.global_position, -4.0)
		if t.attack_data.crit_dew > 0:
			_event("dew_", t, enemy.global_position, EVENT_DB - 3.0))
	tower.popped.connect(func(t: Tower, enemy: Node2D, _stacks: int) -> void:
		_event("pop_", t, enemy.global_position))
	# Beams (Sunpetal / Midsummer): one warm loop per Warden type, swelling with the ramp (1 -> 4 or 5).
	tower.beam_ticked.connect(func(t: Tower, ramp: float) -> void:
		_touch_loop("loop_" + warden_id(t.attack_data), 0.5 + 0.5 * clampf((ramp - 1.0) / 3.0, 0.0, 1.0), BEAM_HOLD))
	# Events from Tower Code (abbc0f9); connected only if present.
	if tower.has_signal("cloud_formed"):
		tower.cloud_formed.connect(func(t: Tower, where: Vector2, duration: float) -> void:
			_on_cloud(t, where, duration))
	if tower.has_signal("trap_set"):
		tower.trap_set.connect(func(t: Tower, where: Vector2) -> void: _event("trap_", t, where, EVENT_DB - 3.0))
	if tower.has_signal("trap_triggered"):
		tower.trap_triggered.connect(func(t: Tower, where: Vector2) -> void: _event("trigger_", t, where))
	if tower.has_signal("seed_caught"):
		tower.seed_caught.connect(func(t: Tower) -> void: _event("catch_", t, t.global_position, EVENT_DB - 3.0))
	if tower.has_signal("echoed"):
		tower.echoed.connect(func(t: Tower, _reaction: StringName, where: Vector2) -> void: _event("echo_", t, where))
	if tower.has_signal("put_to_sleep"):
		tower.put_to_sleep.connect(func(t: Tower, enemy: Node2D) -> void:
			var now := Time.get_ticks_msec()
			var key := warden_id(t.attack_data)
			if now - int(_slept_at.get(key, -100000)) >= SLEEP_INTERVAL_MS:
				_slept_at[key] = now
				_event("sleep_", t, enemy.global_position))
	if tower.has_signal("shard_dropped"):
		tower.shard_dropped.connect(func(t: Tower, where: Vector2) -> void: _event("shard_", t, where))
	if tower.has_signal("grab_finished"):
		tower.grab_finished.connect(func(t: Tower, enemy: Node2D) -> void:
			var at: Vector2 = enemy.global_position if is_instance_valid(enemy) else t.global_position
			get_tree().create_timer(PLOP_DELAY).timeout.connect(func() -> void:
				if is_instance_valid(t):
					_event("plop_", t, at)))
	var id := tower.get_instance_id()
	tower.tree_exiting.connect(func() -> void:
		_hit_groups.erase(id)
		_released_at.erase(id)
		_attack_counts.erase(id))

func _on_cloud(tower: Tower, where: Vector2, duration: float) -> void:
	if tower.attack_data.cloud_fog:
		_event("fog_", tower, where)
		_touch_loop("loop_" + warden_id(tower.attack_data), 1.0, duration)
	else:
		_event("cloud_", tower, where)

# The launch: quiet, and by kind the start of something continuous (lit tiles, blades) or an event
# (a Thunderhead's storm strike, a Windmill's turn). Pulses have none (the pulse is the hit).
func _on_attack(tower: Tower) -> void:
	var data: TowerData = tower.attack_data
	var key := tower.get_instance_id()
	_released_at[key] = Time.get_ticks_msec()
	var count: int = _attack_counts.get(key, 0) + 1
	_attack_counts[key] = count
	var wid := warden_id(data)
	match data.attack_kind:
		TowerData.AttackKind.BEAM, TowerData.AttackKind.AURA, TowerData.AttackKind.PULSE:
			return
		TowerData.AttackKind.LIGHT:
			_touch_loop("loop_" + wid, 1.0, LIT_HOLD)
		TowerData.AttackKind.SPIN:
			_touch_loop("loop_" + wid, 1.0, SPIN_HOLD)
			_event("turn_", tower, tower.global_position, EVENT_DB - 3.0)
		TowerData.AttackKind.CHAIN:
			if data.storm_every > 0 and count % data.storm_every == 0:
				_event("storm_", tower, tower.global_position)
		TowerData.AttackKind.CLOUD:
			if not tower.has_signal("cloud_formed"):
				_on_cloud(tower, tower.global_position, data.cloud_duration)
		TowerData.AttackKind.TRAP:
			if not tower.has_signal("trap_set"):
				_event("trap_", tower, tower.global_position, EVENT_DB - 3.0)
			return
	if QUIET_LINES.has(tower.tower_data.line):
		return
	var id := _sound_for("attack_", data)
	if id != &"":
		sound.play(id, tower.global_position, LAUNCH_DB + _rate_db(data.attacks_per_second), 1.0, 0.05, _bus_for(tower))

# The impact, where the attack lands: the Warden's hit, pitched lower on big or tanky nightmares
# (not the tonal song family), muffled when resisted, fuller and louder when the nightmare is weak.
func _on_hit(tower: Tower, enemy: Node2D, _is_area: bool, _is_crit: bool) -> void:
	if not is_instance_valid(enemy):
		return
	var data: TowerData = tower.attack_data
	var kind := data.attack_kind
	var key := tower.get_instance_id()
	var now := Time.get_ticks_msec()
	match kind:
		TowerData.AttackKind.BEAM:
			if data.beam_behind_share > 0.0 and enemy != tower.get("_beam_target"):
				_touch_loop("loop_%s_behind" % warden_id(data), 1.0, BEAM_HOLD)  # Midsummer's signature layer
			return
		TowerData.AttackKind.LIGHT, TowerData.AttackKind.AURA:
			return
		TowerData.AttackKind.CLOUD:  # The cloud's forming is the sound; its ticks are silent
			if tower.has_signal("cloud_formed") or now - int(_released_at.get(key, -100000)) > CLOUD_HIT_MS:
				return
		TowerData.AttackKind.TRAP:
			if tower.has_signal("trap_triggered"):
				return
	var wid := warden_id(data)
	var group: Array = _hit_groups.get(key, [-100000, 0])
	var hits_before := 0
	if now - int(group[0]) < HIT_GROUP_MS:
		hits_before = group[1] + 1
		group[1] = hits_before
	else:
		if now - int(group[0]) < int(PULSE_THROTTLE_MS.get(wid, 0)):
			return  # Bramble scrapes, Honeysuckle sighs and Acorn knocks stay rare
		group = [now, 0]
	_hit_groups[key] = group
	if hits_before > 0 and kind != TowerData.AttackKind.CHAIN:
		return

	var id := _sound_for("hit_", data)
	if kind == TowerData.AttackKind.PULSE and sound.has_sound(StringName("drowsy_" + wid)) \
			and int(_attack_counts.get(key, 0)) % 2 == 1:
		id = StringName("drowsy_" + wid)  # Bellflower: every 2nd pulse a sleepier, lower bell
	_attack_counts[key] = int(_attack_counts.get(key, 0)) + (1 if kind == TowerData.AttackKind.PULSE else 0)
	if id == &"":
		return
	var line: String = tower.tower_data.line  # The line Enemy.take_damage resists by
	var resisted: bool = line in enemy.enemy_data.resists
	var weak: bool = not resisted and line in enemy.enemy_data.weak_to
	var at: Vector2 = tower.global_position if kind == TowerData.AttackKind.PULSE else enemy.global_position
	var tonal := data.line == "song"
	var pitch := 1.0 if tonal else _weight_pitch(enemy) * pow(CHAIN_STEP_PITCH, hits_before)
	var volume := HIT_DB + _rate_db(_hit_rate(data)) + CHAIN_STEP_DB * hits_before \
		+ (RESISTED_DB if resisted else WEAK_DB if weak else 0.0)
	var bus := _bus_for(tower)
	if resisted:
		var dull := StringName("%s_dull" % id)
		if sound.has_sound(dull):
			id = dull
		else:
			bus = &"SFXMuffled"
	sound.play(id, at, volume, pitch, 0.0 if tonal else 0.05, bus)
	if weak:  # Fuller and louder, never brighter: an extra low body under the hit
		sound.play(&"hit_full", at, HIT_DB - 2.0 + _rate_db(_hit_rate(data)), _weight_pitch(enemy), 0.05, bus)

# Hits on big or tanky nightmares land lower and fuller, on small ones lighter and higher.
static func _weight_pitch(enemy: Node2D) -> float:
	return _weight_pitch_for(enemy.enemy_data.health, enemy.elite, enemy.enemy_data.is_boss)

static func _weight_pitch_for(base_health: int, elite: bool, boss: bool) -> float:
	if boss:
		return 0.8
	var health := float(base_health) * (3.0 if elite else 1.0)  # Deeply Blighted: ×3 health
	return clampf(1.0 - 0.12 * log(maxf(health, 1.0) / 100.0) / log(2.0), 0.82, 1.15)

func _on_path_changed() -> void:
	_path_pixels = maxf(map_generator.get_path_from(map_generator.startPath).size() * MAP_GRID.cell_size.x, 1.0)
	if is_node_ready() and tower_container.get_child_count() > 0:
		sound.play(&"path_shimmer", null, -10.0, 1.0, 0.0)

func _on_run_ended(won: bool) -> void:
	sound.stop_music()
	sound.play(&"win" if won else &"loss", null, 0.0, 1.0, 0.0, &"UI")
