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
const BEAM_DB := -9.0
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
	tower_placer.tower_built.connect(func(tower: Tower) -> void: sound.play(&"plant", tower.global_position))
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

	sound.play_music(&"act1", [&"base"])
	sound.play_ambience(&"act1")
	_on_path_changed()

func _exit_tree() -> void:
	if sound != null:
		sound.set_muffled(false)
		sound.set_drifting(false)
		sound.set_ambience_trim(0.0)
		sound.stop_ambience()

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

func _on_tower_added(node: Node) -> void:
	var tower := node as Tower
	if tower == null:
		return
	if not tower.attack_released.is_connected(_on_attack):
		tower.attack_released.connect(_on_attack)
		tower.hit_landed.connect(_on_hit)
		tower.evolved.connect(func(t: Tower) -> void: sound.play(&"evolve", t.global_position))
		# The hit's own sound plays too; the crit adds a low punch and a soft, low bell.
		tower.crit_landed.connect(func(_t: Tower, enemy: Node2D) -> void:
			sound.play(&"crit", enemy.global_position, -6.0)
			sound.play(&"crit_punch", enemy.global_position, -4.0))
		# Sunpetal / Midsummer: the hum climbs as the beam ramps up (ramp 1 -> 4 or 5).
		tower.beam_ticked.connect(func(t: Tower, ramp: float) -> void:
			sound.play(&"beam", t.global_position, BEAM_DB, 1.0 + (ramp - 1.0) * 0.08, 0.0))
		var id := tower.get_instance_id()
		tower.tree_exiting.connect(func() -> void:
			_hit_groups.erase(id)
			_released_at.erase(id))

# The launch: quiet. Pulses have none (the pulse is the hit).
func _on_attack(tower: Tower) -> void:
	_released_at[tower.get_instance_id()] = Time.get_ticks_msec()
	var line: String = tower.tower_data.line
	if QUIET_LINES.has(line) or tower.attack_data.attack_kind == TowerData.AttackKind.PULSE:
		return
	var id := StringName("attack_" + line)
	if not sound.has_sound(id):
		id = &"attack_sprout"
	sound.play(id, tower.global_position, LAUNCH_DB)

# The impact, where the attack lands (audio_direction.md "Wardens"): the family's hit, pitched lower
# on big or tanky nightmares, dulled when resisted, fuller and louder when the nightmare is weak to it.
func _on_hit(tower: Tower, enemy: Node2D, _is_area: bool, _is_crit: bool) -> void:
	if not is_instance_valid(enemy):
		return
	var kind := tower.attack_data.attack_kind
	if kind == TowerData.AttackKind.BEAM:
		return  # Beams have their own hum
	var key := tower.get_instance_id()
	var now := Time.get_ticks_msec()
	if kind == TowerData.AttackKind.CLOUD and now - int(_released_at.get(key, -100000)) > CLOUD_HIT_MS:
		return
	var group: Array = _hit_groups.get(key, [-100000, 0])
	var hits_before := 0
	if now - int(group[0]) < HIT_GROUP_MS:
		hits_before = group[1] + 1
		group[1] = hits_before
	else:
		group = [now, 0]
	_hit_groups[key] = group
	if hits_before > 0 and kind != TowerData.AttackKind.CHAIN:
		return

	var line: String = tower.tower_data.line  # The line Enemy.take_damage resists by
	var family: String = tower.attack_data.line  # How it sounds (a Graftling sounds like its copy)
	if not HIT_FAMILIES.has(family):
		family = "sprout"
	var resisted: bool = line in enemy.enemy_data.resists
	var weak: bool = not resisted and line in enemy.enemy_data.weak_to
	var at: Vector2 = tower.global_position if kind == TowerData.AttackKind.PULSE else enemy.global_position
	var volume := HIT_DB + CHAIN_STEP_DB * hits_before + (RESISTED_DB if resisted else WEAK_DB if weak else 0.0)
	sound.play(StringName("hit_%s%s" % [family, "_dull" if resisted else ""]), at, volume, _weight_pitch(enemy))
	if weak:  # Fuller and louder, never brighter: an extra low body under the hit
		sound.play(&"hit_full", at, HIT_DB - 2.0, _weight_pitch(enemy))

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
