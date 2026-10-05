extends Node
class_name CaptureDirector

# Marketing captures (marketing.md §3), debug builds only.
# - Capture mode (Developer setting "capture_mode": 0 off, 1 clean HUD, 2 no HUD): hides the dev tools (Test Grove dock
#   and damage meter), DPS tags, the perf overlay and the Dev Grove tag; "no HUD" hides the whole HUD too.
# - Scripted capture scenes: `-- --capture=res://capture/short_01.json` (the title hands over; see begin()) plays a
#   scene file and quits at its end. Run it with Godot's Movie Maker (`--write-movie out.avi --fixed-fps 60`) so heavy
#   fights still render smoothly; tools/marketing/capture.ps1 does that. A capture writes only to its own profile.
#
# Scene file (JSON): {
#   "seed": 4242, "drift": 20, "dew": 999, "leaves": 15, "invulnerable": true, "omen": "<omen id>",
#   "dreams": ["<card id>", …], "hud": "none" | "clean" | "full", "length": 25.0, "speed": 1.0,
#   "bosses": ["<boss id>", …] (default: each act's default boss), "families": ["sporeling", …] (the Warden bar shows
#   only these, Sprout and Thornwall; planting still takes any Warden),
#   "game_music": false (the game's Music bus is muted: the export adds the music bed),
#   "timeline": [ {"t": 0.0, <one action>}, … ] }
# Actions (t = seconds of the clip, unaffected by slow motion):
#   {"plant": "<warden id or form>", "at": [hx, hy] (half cells: the 2×2 footprint's top-left) | "auto": "maze" | "cover",
#    "rank": 0, "tag": true}            a form is grown from its root; "maze" picks the spot that lengthens the route most,
#                                       "cover" the spot that covers most of the route ("+N path" tags float up)
#   {"plant_each": 0.5, "count": 20, "plant": "thornwall", "auto": "maze"}   one every 0.5 s (also with "spots": [[hx, hy], …])
#   {"grow": [hx, hy], "into": "<form>"}  grows the Warden planted there in place (through any forms between)
#   {"dream_offer": true, "rare": false}  a Dream offer now, as at a rest (with "quiet": false; pick it with pick_dream)
#   {"start": true}                      starts the next drift (the scene's "drift" first)
#   {"speed": 0.25}                      game speed (slow motion < 1)
#   {"spawn": "<enemy id>", "count": 1, "elite": false}
#   {"leaves": 1} / {"dew": 500}
#   {"gift": "<gift id>", "cells": [[x, y], …]}   a Heartwood's Gift, applied as if picked (the effect's placement);
#                                       "auto": "detour" instead of cells lays it where it lengthens the route most
# Dry runs print a progress line every 5 s (route, field, drift, boss hp, furthest), chains, gifts, boss dispels, leaks.
#   {"dossier": true | false}            open / close the boss dossier ("What's coming")
#   {"camera": "hold", "at": [x, y] | "start" | "heartwood" | "centre", "zoom": 1.2}
#   {"camera": "glide", "duration": 8.0, "zoom": 1.4}          along the route, start → Heartwood
#   {"camera": "push", "at": …, "zoom": 2.0, "duration": 4.0}  a slow push-in (or out) onto a spot
#   {"camera": "follow", "target": "boss" | "furthest" | "<enemy id>", "zoom": 1.6}
# Dry runs: `--map` after the scene flag (or "map": true) prints the board in half cells after setup and at the end.

enum Hud { FULL, CLEAN, NONE }

const SETTING := "capture_mode"
const FLAG := "--capture="
const PROFILE := "user://capture_heartwood.json"
const GAME_SCENE := "res://scenes/main.tscn"
const GROVE_SCENE := "res://scenes/grove.tscn"
const SILHOUETTE := Color(0.05, 0.05, 0.09)  # multiplier: a planted Warden drawn as a dark shape (a tease)
const TAG_LIFE := 1.4  # Seconds a "+N path" tag floats
const TAG_RISE := 36.0

static var scene := {}  # The scene being captured (empty = capture mode only)
static var quiet := false  # Screens that open by themselves (dossier, nightmare intros, Dreams, Omens, gifts) stay shut

var clip_time := 0.0
var _main: Node
var _events: Array = []
var _next := 0
var _scale := 1.0  # Engine.time_scale this frame's delta was scaled by
var _camera: Node
var _cam := {}  # The active camera move
var _followed: Node2D = null
var _tags: Array = []  # [world position, text, age]
var _tag_layer: Node2D
var _towers := {}  # id -> TowerData
var _started := false
var _tracker: Node = null  # ReactionTracker, hooked once it exists (chain slow motion)
var _slow_left := 0.0  # Real seconds of chain slow motion left
var _speed_before := 1.0
var _rng := RandomNumberGenerator.new()  # Auto spots break ties with this (seeded per scene), never the global RNG
var _frame := 0
var _silhouettes := {}  # Half-cell origin -> true: Wardens drawn dark (kept through grows)
var _grove: Node = null  # The Memory Grove screen, in a "scene": "grove" capture
var _grove_cam := {}

# --- Launch ------------------------------------------------------------------------------------------

static func is_available() -> bool:
	return OS.is_debug_build()

# A scripted capture is playing (never in a normal run).
static func capturing() -> bool:
	return not scene.is_empty()

static func launch_path() -> String:
	if not is_available():
		return ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(FLAG):
			return arg.trim_prefix(FLAG)
	return ""

static func hud_mode() -> int:
	if not is_available():
		return Hud.FULL
	if not scene.is_empty():
		return {"full": Hud.FULL, "clean": Hud.CLEAN, "none": Hud.NONE}.get(String(scene.get("hud", "none")), Hud.NONE)  # A {"hud": …} action changes it
	return clampi(int(HeartwoodMemory.get_settings().get(SETTING, 0)), 0, 2)

static func load_scene(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var data = JSON.parse_string(file.get_as_text())
	return data if data is Dictionary else {}

# Called first thing by the title: with --capture=, switches to a fresh capture profile (never the player's), makes
# it a dev run in the full game, and starts the run on the scene's seed. True if it took over.
static func begin(tree: SceneTree) -> bool:
	var path := launch_path()
	if path == "":
		return false
	scene = load_scene(path)
	if scene.is_empty():
		push_error("Capture: can't read the scene file %s" % path)
		tree.quit(1)
		return true
	for file in [PROFILE, PROFILE + ".bak"]:
		if FileAccess.file_exists(file):
			DirAccess.remove_absolute(file)
	HeartwoodMemory.file_path = PROFILE
	HeartwoodMemory.real_settings_path = ""
	if is_grove():  # The Memory Grove on a preset tree (GrovePresets), written to the capture profile, Seeds to spare
		GrovePresets.load_preset(StringName(scene.get("grove", "early")), PROFILE)
		var data := HeartwoodMemory.load_data()
		data.seeds = 1000000
		HeartwoodMemory.save_data(data)
	RunSaver.file_path = "user://capture_run.json"
	RunHistory.file_path = "user://capture_run_history.json"
	var settings := HeartwoodMemory.get_settings()
	settings.whispers = false
	settings.damage_numbers = int(scene.get("damage_numbers", 0))
	settings.ui_scale = 1.0
	settings.fullscreen = false
	settings[SETTING] = 0
	settings[ComboFeedback.PAUSE_SETTING] = false  # A fresh profile discovers every combo: never freeze the clip on one
	HeartwoodMemory.save_settings(settings)
	HeartwoodMemory.apply_settings()
	# The frame is the project's viewport size (capture.ps1 writes it to override.cfg with stretch mode "viewport", so
	# Movie Maker renders it whole even on a smaller screen): world zoom 1 = one art pixel per video pixel.
	if DisplayServer.get_name() != "headless":
		tree.root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		tree.root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		tree.root.content_scale_size = Vector2i(int(ProjectSettings.get_setting("display/window/size/viewport_width", 1920)),
			int(ProjectSettings.get_setting("display/window/size/viewport_height", 1080)))
		tree.root.content_scale_factor = 1.0
	ResultsScreen.demo_override = 0  # The full game
	TestGrove.force_on = true  # Every Warden plantable; a dev run (no Seeds, no records)
	quiet = true
	if is_grove():
		var grove: Node = load(GROVE_SCENE).instantiate()
		grove.add_child(CaptureDirector.new())  # The Grove has no Main to make it
		tree.change_scene_to_node.call_deferred(grove)
		return true
	var main: Node = load(GAME_SCENE).instantiate()
	main.get_node("%MapGenerator").map_seed = int(scene.get("seed", 4242))
	tree.change_scene_to_node.call_deferred(main)
	return true

# A Memory Grove scene ("scene": "grove") rather than a run.
static func is_grove() -> bool:
	return String(scene.get("scene", "")) == "grove"

# Made by Main when capture mode is on or a scene is playing.
static func wanted() -> bool:
	return is_available() and (not scene.is_empty() or hud_mode() != Hud.FULL)

# --- Running -----------------------------------------------------------------------------------------

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = -1000  # Before every other node each frame (the per-frame RNG seed)
	_main = get_parent()
	_camera = get_tree().get_first_node_in_group(&"game_camera")
	get_tree().process_frame.connect(func() -> void: _scale = Engine.time_scale)
	if scene.is_empty():
		return
	if is_grove():
		_grove = _main
		get_viewport().gui_disable_input = true
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		_events = _expand(scene.get("timeline", []))
		_setup_grove.call_deferred()
		return
	_tag_layer = Node2D.new()
	_tag_layer.z_index = 30
	_tag_layer.draw.connect(_draw_tags)
	_main.add_child.call_deferred(_tag_layer)
	get_viewport().gui_disable_input = true  # The mouse over the render window changes nothing
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_events = _expand(scene.get("timeline", []))
	if _camera != null:
		_camera.camera_zoom_in_max = 8.0  # Close-ups at whole zooms (3, 4…); the player's limit (2.5) clamped them each frame
	# Bosses: each act's default (the Hollow Stag first) unless the scene names them ("bosses": [boss ids]); set now,
	# before DriftDirector's deferred draw (a dev run would draw at random).
	var director: DriftDirector = _main.get_node("%DriftDirector")
	director.preset_bosses = scene.get("bosses", BossPool.ids(BossPool.draw(int(scene.get("seed", 4242)), true)))
	_setup.call_deferred()

func _setup() -> void:
	# The same clip on every run, dry or rendered: our own tie-break RNG, the Dream and Omen RNGs, and the global RNG
	# reseeded at the start of every frame (_process runs first: process_priority), so effects that a wall-clock
	# throttle shows or skips can't shift later frames' draws.
	_rng.seed = int(scene.get("seed", 4242))
	for node in [_main.get_node("%DreamState"), _main.get_node("%OmenDirector")]:
		if node.get("_rng") is RandomNumberGenerator:
			node._rng.seed = int(scene.get("seed", 4242)) + 1
	seed(int(scene.get("seed", 4242)))
	var director: DriftDirector = _main.get_node("%DriftDirector")
	var run_state: RunState = _main.get_node("%RunState")
	run_state.invulnerable = bool(scene.get("invulnerable", true))
	run_state.dew = int(scene.get("dew", 999))
	run_state.dew_changed.emit(run_state.dew)
	if scene.has("leaves"):
		run_state.leaves = int(scene.leaves)
		run_state.leaves_changed.emit(run_state.leaves, run_state.max_leaves)
	var drift := int(scene.get("drift", 1))
	if drift > 1:
		director.drifts_started = drift - 1
		director.drifts_cleared = drift - 1
		var act := director.get_act(drift)
		_main.get_node("%MapGenerator").set_act(act)
		var seasons := _main.get_node_or_null("Seasons")
		if seasons != null:
			seasons.set_act(act, false)
	var dreams: DreamState = _main.get_node("%DreamState")
	for id in scene.get("dreams", []):
		for card in dreams.pool:
			if card.id == StringName(id):
				dreams.take(card)
	if scene.has("omen"):
		var omens = _main.get_node("%OmenDirector")
		for omen in omens.all_omens():
			if omen.resource_path.get_file().get_basename() == String(scene.omen):
				omens.active = omen
				omens.active_block = director.get_block(drift)
	if scene.has("obstacles"):  # "none": an open island; "edge" or a number: keep only those near the rim (cells)
		var keep := -1
		if String(scene.obstacles) == "edge":
			keep = 2
		elif scene.obstacles is float or scene.obstacles is int:
			keep = int(scene.obstacles)
		var map = _main.get_node("%MapGenerator")
		var size: Vector2 = Vector2(map.MAP_GRID.size)
		var cleared := 0
		for cell in map.obstacles.keys():
			var rim: float = minf(minf(cell.x, cell.y), minf(size.x - 1 - cell.x, size.y - 1 - cell.y))
			if map.obstacles.has(cell) and rim > keep:
				map._remove_obstacle(cell, false)  # No stump: as if it never grew
				cleared += 1
		map.path_layer.draw()
		map.path_changed.emit()
		print("Capture: cleared %d obstacles, %d left" % [cleared, map.obstacles.size()])
	if scene.has("families"):  # A real-looking Warden bar: Sprout, Thornwall and these families, not all of them
		dreams.unlock_everything = false
		dreams.unlocked = {"sprout": true, "thornwall": true}
		for id in scene.families:
			dreams.unlocked[String(id)] = true
		dreams.unlocks_changed.emit()
	for layer in _main.find_children("*", "Parallax2D", true, false):  # The void's sky reaches a tall, zoomed-out frame
		layer.repeat_times = maxi(layer.repeat_times, 32)
	_main.get_node("%GameSpeed").set_speed(float(scene.get("speed", 1.0)))
	if not bool(scene.get("game_music", false)):
		var music := AudioServer.get_bus_index("Music")
		if music >= 0:
			AudioServer.set_bus_mute(music, true)
	# For tuning a board on a headless dry run: where bosses and elites were dispelled, and any leak.
	var spawner = _main.get_node("%EnemyContainer")
	spawner.enemy_cleansed.connect(func(enemy: Node2D) -> void:
		if enemy.enemy_data != null and (enemy.enemy_data.is_boss or enemy.elite):
			print("Capture: %s dispelled at %.1f s, %.1f cells from the Heartwood" % [enemy.enemy_data.resource_path.get_file().get_basename(),
				clip_time, enemy.get_remaining_distance() / 64.0]))
	spawner.enemy_reached_goal.connect(func(enemy: Node2D) -> void:
		print("Capture: %s reached the Heartwood at %.1f s" % [enemy.enemy_data.resource_path.get_file().get_basename() if enemy.enemy_data else "?", clip_time]))
	if _wants_map():
		print_map("after setup")
	_started = true
	print("Capture: playing %s (%.0f s), bosses %s" % [scene.get("title", ""), float(scene.get("length", 20.0)), BossPool.ids(director.bosses)])

func _process(delta: float) -> void:
	if _grove != null:
		_process_grove(delta)
		return
	_apply_hud()
	if scene.is_empty() or not _started:
		return
	_apply_silhouettes()
	_frame += 1
	seed(hash([int(scene.get("seed", 4242)), _frame]))
	clip_time += delta / maxf(_scale, 0.0001)
	if quiet:
		_shut_screens()
	while _next < _events.size() and float(_events[_next].get("t", 0.0)) <= clip_time:
		_run(_events[_next])
		_next += 1
	_update_camera(delta / maxf(_scale, 0.0001))
	_age_tags(delta / maxf(_scale, 0.0001))
	_update_slow_motion(delta / maxf(_scale, 0.0001))
	_update_filter()
	if clip_time >= _next_report:
		_next_report += REPORT_EVERY
		_report()
	if clip_time >= float(scene.get("length", 20.0)):
		set_process(false)
		var map = _main.get_node("%MapGenerator")
		if _wants_map():
			print_map("at the end")
		print("Capture: done, %d Wardens, route %d cells" % [_main.get_node("%TowerContainer").get_child_count(),
			map.route_length(map.get_path_from(map.startPath))])
		get_tree().quit()

# Every REPORT_EVERY clip seconds (for tuning on dry runs): the route, the field, the boss and the furthest nightmare.
const REPORT_EVERY := 5.0
var _next_report := REPORT_EVERY
var _spot_ms := 0  # Time spent picking auto spots (they cost a route search per candidate)

func _report() -> void:
	var map = _main.get_node("%MapGenerator")
	var parts: Array[String] = ["t=%.1f" % clip_time, "route %d" % map.route_length(map.get_path_from(map.startPath))]
	var walking: Array = _main.get_node("%EnemyContainer").get_enemies().filter(func(e: Node) -> bool: return not e.is_cleansed)
	parts.append("%d on the field" % walking.size())
	var director: DriftDirector = _main.get_node("%DriftDirector")
	parts.append("drift %d%s%s" % [director.drifts_started, " (resting)" if director.is_resting() else "",
		" PAUSED: %s" % director.pending_choice() if get_tree().paused else ""])
	var furthest: Node2D = _pick("furthest")
	var boss: Node2D = _pick("boss")
	if boss != null:
		parts.append("boss %d%% hp, %.1f cells left" % [roundi(100.0 * boss.health / maxf(boss.max_health, 1.0)), boss.get_remaining_distance() / 64.0])
	if furthest != null:
		parts.append("furthest %s %.1f cells left" % [furthest.enemy_data.resource_path.get_file().get_basename() if furthest.enemy_data else "?",
			furthest.get_remaining_distance() / 64.0])
	if _spot_ms > 0:
		parts.append("spot search %.1f s so far" % (_spot_ms / 1000.0))
	print("Capture: " + " / ".join(parts))

# Hides what a marketing shot never shows.
func _apply_hud() -> void:
	var mode := hud_mode()
	if mode == Hud.FULL:
		return
	for node in _main.get_children():
		if node is DpsTags or node is PerfOverlay or node is TestGrove:
			node.visible = false
	var hud := _main.get_node_or_null("HUD")
	if hud == null:
		return
	for node in hud.get_children():
		if node is DriftMeter:  # The damage meter (its dev line says "needs ~N")
			node.visible = false
	var dev_tag := hud.get_node_or_null("DevGroveTag")
	if dev_tag != null:
		dev_tag.visible = false
	hud.visible = mode != Hud.NONE

# Rest screens a scene didn't ask for are passed over (a clip that crosses a rest keeps flowing).
func _shut_screens() -> void:
	var dreams: DreamState = _main.get_node("%DreamState")
	if dreams.is_offering():
		dreams.skip()
	var omens = _main.get_node("%OmenDirector")
	if omens.is_offering():
		omens.choose(null)
	var gifts := HeartwoodGifts.find(_main)
	if gifts != null and gifts.waiting:
		gifts.let_pass()
	if get_tree().paused:  # Anything else that paused the run (a discovery card…): the clip keeps playing
		print("Capture: something paused the game at %.1f s; unpaused" % clip_time)
		_main.get_node("%GameSpeed").set_paused(false)

# plant_each → one plant per step.
func _expand(timeline: Array) -> Array:
	var out: Array = []
	for event in timeline:
		if not event is Dictionary:
			continue
		if event.has("plant_each"):
			var spots: Array = event.get("spots", [])
			var count := spots.size() if not spots.is_empty() else int(event.get("count", 1))
			for i in count:
				var one: Dictionary = event.duplicate()
				one.erase("plant_each")
				one.erase("spots")
				one.t = float(event.get("t", 0.0)) + i * float(event.plant_each)
				if not spots.is_empty():
					one.at = spots[i]
				out.append(one)
		else:
			out.append(event)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("t", 0.0)) < float(b.get("t", 0.0)))
	return out

func _run(event: Dictionary) -> void:
	var run_state: RunState = _main.get_node("%RunState")
	if event.has("plant"):
		plant(String(event.plant), event.get("at", null), String(event.get("auto", "")), int(event.get("rank", 0)), bool(event.get("tag", true)))
	if event.has("start"):
		_main.get_node("%DriftDirector").start_next_drift()
	if event.has("speed"):
		_main.get_node("%GameSpeed").set_speed(float(event.speed))
	if event.has("spawn"):
		var data := load("res://resource/enemy/%s.tres" % event.spawn) as EnemyData
		var director: DriftDirector = _main.get_node("%DriftDirector")
		var map = _main.get_node("%MapGenerator")
		var route: PackedVector2Array = map.get_path_from(map.startPath)
		for i in int(event.get("count", 1)):
			var enemy: Node2D = _main.get_node("%EnemyContainer").spawn_enemy(data, director.get_health_multiplier(data, maxi(director.drifts_started, 1)),
				{}, bool(event.get("elite", false)))
			# Mid-route ("progress" 0..1 along the live route, or "cells_left" from the Heartwood), as if it walked
			# in; several stand "spread" cells apart (default 1), the first furthest along.
			if enemy == null or route.size() < 2 or not (event.has("progress") or event.has("cells_left")):
				continue
			var at := int(float(event.get("progress", 0.0)) * (route.size() - 1))
			if event.has("cells_left"):
				at = route.size() - 1 - int(float(event.cells_left) * 2.0)  # Route points step half a cell
			at = clampi(at - int(float(event.get("spread", 1.0)) * 2.0 * i), 0, route.size() - 2)
			enemy.position = map.MAP_GRID.calculate_map_position(route[at])
			enemy.set_path(route.slice(at))
	if event.has("leaves"):
		run_state.leaves = int(event.leaves)
		run_state.leaves_changed.emit(run_state.leaves, run_state.max_leaves)
	if event.has("dew"):
		run_state.dew = int(event.dew)
		run_state.dew_changed.emit(run_state.dew)
	if event.has("gift"):
		var gifts := HeartwoodGifts.find(_main)
		if gifts != null:
			gifts.waiting = true
			gifts.current_offer = [StringName(event.gift)]
			var cells: Array = []
			for c in event.get("cells", []):
				cells.append(Vector2(float(c[0]), float(c[1])))
			if String(event.get("auto", "")) == "detour":
				cells = detour_cells(StringName(event.gift))
				print("Capture: %s laid on %s" % [event.gift, cells])
			var map = _main.get_node("%MapGenerator")
			var before: int = map.route_length(map.get_path_from(map.startPath))
			gifts.choose(StringName(event.gift), {"cells": cells})
			print("Capture: %s at %.1f s, route %d -> %d cells" % [event.gift, clip_time, before, map.route_length(map.get_path_from(map.startPath))])
	if event.has("dossier"):
		if bool(event.dossier):
			BossDossier.open_for(get_tree(), int(event.get("drift", 0)))
		else:
			var dossier := get_tree().get_first_node_in_group(&"boss_dossier")
			if dossier != null:
				dossier.close_dossier()
	if event.has("hud"):
		scene.hud = String(event.hud)
	if event.has("quiet"):
		quiet = bool(event.quiet)
	if event.has("grow"):  # Grows the Warden planted at half-cell origin "grow" [hx, hy] into "into" (a form id), in place
		var grew := grow_at(Vector2(float(event.grow[0]), float(event.grow[1])), String(event.get("into", "")))
		print("Capture: grew %s into %s at %.1f s: %s" % [event.grow, event.get("into", ""), clip_time, "ok" if grew else "FAILED"])
	if event.has("silhouette"):  # {"silhouette": [hx, hy], "on": true}: that Warden as a dark shape, through later grows
		var spot := Vector2(float(event.silhouette[0]), float(event.silhouette[1]))
		if bool(event.get("on", true)):
			_silhouettes[spot] = true
		else:
			_silhouettes.erase(spot)
			var tower := _tower_near(spot)
			if tower != null:
				tower.modulate = Color.WHITE  # multiplier
	if event.has("dream_offer"):  # A Dream offer now, as at a rest ("rare": true = a boss rest's, Rare and up); set
		# "quiet": false first or it's passed over at once
		var dreams: DreamState = _main.get_node("%DreamState")
		var director: DriftDirector = _main.get_node("%DriftDirector")
		var act_boss: int = director.get_act(maxi(director.drifts_started, 1)) * director.drifts_per_act
		dreams._pending_drifts.append(act_boss if bool(event.get("rare", false)) else director.drifts_started)
		dreams._show_next_offer()
		print("Capture: Dream offer at %.1f s: %s" % [clip_time, dreams.current_offer.map(func(c: UpgradeData) -> String: return String(c.id))])
	if event.has("pick_dream"):  # Takes the offer's Nth card (screens shown with "quiet": false)
		var dreams: DreamState = _main.get_node("%DreamState")
		if dreams.is_offering() and int(event.pick_dream) < dreams.current_offer.size():
			print("Capture: picked %s at %.1f s" % [dreams.current_offer[int(event.pick_dream)].id, clip_time])
			dreams.choose(dreams.current_offer[int(event.pick_dream)])
	if event.has("camera"):
		_cam = event.duplicate()
		_cam.started = clip_time
		_cam.from_zoom = _camera.target_zoom.x if _camera != null else 1.0
		_cam.from_pos = _camera.target_position if _camera != null else Vector2.ZERO
		_followed = null
		if String(event.camera) == "glide" and _camera != null:
			_camera.glide(_route_pixels(), float(event.get("duration", 6.0)))

# --- Silhouettes ------------------------------------------------------------------------------------

# The Warden standing on half-cell origin `spot`: the nearest one to its centre (a grown 2×2 form's centre moves).
func _tower_near(spot: Vector2) -> Tower:
	var at := Tower.half_centre(spot)
	var best: Tower = null
	var best_distance := 80.0
	for child in _main.get_node("%TowerContainer").get_children():
		if child is Tower and (child as Tower).position.distance_to(at) < best_distance:
			best = child
			best_distance = (child as Tower).position.distance_to(at)
	return best

# Every frame: a grow may replace the art (or the node), so the dark modulate is put back each time.
func _apply_silhouettes() -> void:
	for spot in _silhouettes:
		var tower := _tower_near(spot)
		if tower != null:
			tower.modulate = SILHOUETTE

# --- The Memory Grove ("scene": "grove") -------------------------------------------------------------
# Timeline actions: {"plant": "<unlock id>"} (as the Plant button: the branch grows, the bud opens),
# {"camera": "fit"}, {"camera": "focus", "node": "<unlock id>" | "at": [x, y] (tree px), "zoom": z, "duration": s}.
# "grove_ui": true keeps the header, card and footer (default: only the tree).

func _setup_grove() -> void:
	if not bool(scene.get("grove_ui", false)):
		for child in _grove.get_children():
			if child != self and child != _grove.tree_view and not (child is ColorRect and child.get_index() == 0):
				child.visible = false
	_grove.tree_view.fit()
	_started = true
	print("Capture: playing %s (%.0f s) in the Memory Grove (%s)" % [scene.get("title", ""), float(scene.get("length", 20.0)), scene.get("grove", "early")])

func _process_grove(delta: float) -> void:
	if not _started:
		return
	clip_time += delta
	while _next < _events.size() and float(_events[_next].get("t", 0.0)) <= clip_time:
		_run_grove(_events[_next])
		_next += 1
	if not _grove_cam.is_empty():
		var view = _grove.tree_view
		var t := clampf((clip_time - float(_grove_cam.started)) / maxf(float(_grove_cam.duration), 0.001), 0.0, 1.0)
		var eased := t * t * (3.0 - 2.0 * t)
		var zoom: float = lerpf(float(_grove_cam.from_zoom), float(_grove_cam.to_zoom), eased)
		view.zoom_by(zoom / maxf(view.zoom, 0.0001))
		view.focus_on((_grove_cam.from_at as Vector2).lerp(_grove_cam.to_at, eased))
	if clip_time >= float(scene.get("length", 20.0)):
		set_process(false)
		get_tree().quit()

func _run_grove(event: Dictionary) -> void:
	var view = _grove.tree_view
	if event.has("plant"):
		var unlock = HeartwoodMemory.get_unlock(String(event.plant))
		if unlock == null:
			push_error("Capture: no Grove node %s" % event.plant)
		else:
			_grove._select(unlock)
			_grove._plant_selected()
			print("Capture: planted %s at %.1f s (level %d)" % [event.plant, clip_time,
				HeartwoodMemory.unlock_level(HeartwoodMemory.load_data(), String(event.plant))])
	if event.has("camera"):
		var centre: Vector2 = view.to_tree(view.size / 2.0)
		if String(event.camera) == "fit":
			_grove_cam = {}
			view.fit()
			return
		var to_at := centre
		if event.has("node"):
			to_at = view.to_tree(view.node_screen_position(String(event.node)))
		elif event.has("at"):
			to_at = Vector2(float(event.at[0]), float(event.at[1]))
		_grove_cam = {"started": clip_time, "duration": float(event.get("duration", 0.0)), "from_zoom": view.zoom,
			"to_zoom": float(event.get("zoom", view.zoom)), "from_at": centre, "to_at": to_at}

# --- Planting ----------------------------------------------------------------------------------------

# Grows the Warden whose footprint starts at half-cell `origin` into `into` (its next form, or a later one through the
# forms between), paid from a loan like planting. True if it grew.
func grow_at(origin: Vector2, into: String) -> bool:
	var target := _tower(into)
	var placer = _main.get_node("%TowerPlacer")
	var tower: Tower = null
	for child in placer.tower_container.get_children():
		if child is Tower and child.half_cell == origin:
			tower = child
	if tower == null or target == null:
		push_error("Capture: nothing to grow at %s into %s" % [origin, into])
		return false
	var chain := _grow_path(tower.tower_data, target)  # Forward from this form: an Ascended form follows every final
	var start := 0
	if chain.is_empty():
		push_error("Capture: %s doesn't grow into %s" % [tower.tower_data.get_id(), into])
		return false
	var run_state: RunState = _main.get_node("%RunState")
	var dreams: DreamState = _main.get_node("%DreamState")
	var shown := run_state.dew
	var limited := not dreams.unlock_everything
	dreams.unlock_everything = true
	run_state.dew = 1000000
	for form in chain.slice(start + 1):
		placer.evolve(tower, form)
	run_state.dew = shown
	run_state.dew_changed.emit(run_state.dew)
	dreams.unlock_everything = not limited
	return tower.tower_data == target

# The forms from `from` to `target` along evolves_to (both included; empty if it never gets there), shortest first.
func _grow_path(from: TowerData, target: TowerData) -> Array[TowerData]:
	var came := {from: null}
	var queue: Array[TowerData] = [from]
	while not queue.is_empty():
		var data: TowerData = queue.pop_front()
		if data == target:
			var path: Array[TowerData] = []
			while data != null:
				path.push_front(data)
				data = came[data]
			return path
		for next in data.evolves_to:
			if next is TowerData and not came.has(next):
				came[next] = data
				queue.append(next)
	return []

func _tower(id: String) -> TowerData:
	if _towers.is_empty():
		for file in DirAccess.get_files_at("res://resource/tower/"):
			if file.ends_with(".tres"):
				var data := load("res://resource/tower/" + file) as TowerData
				if data != null:
					_towers[data.get_id()] = data
	return _towers.get(id)

# The forms from a plantable root up to `target` (root first).
func _chain(target: TowerData) -> Array[TowerData]:
	var chain: Array[TowerData] = [target]
	while not chain[0].buildable_directly:
		var parent: TowerData = null
		for data in _towers.values():
			if data.evolves_to.has(chain[0]):
				parent = data
				break
		if parent == null:
			break
		chain.push_front(parent)
	return chain

# Plants `id` (grown from its root when it's a branch or final form) at half-cell origin `at`, or the spot `auto`
# picks. True if it stands.
func plant(id: String, at, auto: String = "", rank: int = 0, tag: bool = true) -> bool:
	var target := _tower(id)
	if target == null:
		push_error("Capture: no Warden %s" % id)
		return false
	var chain := _chain(target)
	var map = _main.get_node("%MapGenerator")
	var placer = _main.get_node("%TowerPlacer")
	var run_state: RunState = _main.get_node("%RunState")
	var origin := Vector2(-1, -1)
	if at is Array and at.size() == 2:
		origin = Vector2(float(at[0]), float(at[1]))
	else:
		var started := Time.get_ticks_msec()
		origin = best_spot(chain[-1], auto if auto != "" else ("cover" if chain[-1].can_attack else "maze"))
		_spot_ms += Time.get_ticks_msec() - started
	if origin.x < 0:
		return false
	var before: int = map.route_length(map.get_path_from(map.startPath))
	var shown := run_state.dew  # The scene's Dew stays what it shows: planting and growing are paid from a loan
	var dreams: DreamState = _main.get_node("%DreamState")
	var limited := not dreams.unlock_everything  # "families": the bar shows the run's families; planting may use any
	dreams.unlock_everything = true
	run_state.dew = 1000000
	placer.select_tower(chain[0])
	var planted: bool = placer._try_build_half(origin)
	placer.set_build_mode(false)
	var tower: Tower = null
	for child in placer.tower_container.get_children():
		if planted and child is Tower and child.half_cell == origin:
			tower = child
	if tower != null:
		for form in chain.slice(1):
			placer.evolve(tower, form)
		for i in rank:
			placer.nurture(tower, Tower.Focus.POWER)
	run_state.dew = shown
	dreams.unlock_everything = not limited
	run_state.dew_changed.emit(run_state.dew)
	if tower == null:
		return false
	var after: int = map.route_length(map.get_path_from(map.startPath))
	if tag and after > before:
		_tags.append([Tower.half_centre(origin), "+%d path" % (after - before), 0.0])
	return true

# "maze": the free spot that lengthens the route most; "cover": the spot whose range covers most route points (and
# never shortens the route). Only spots next to the route are tried.
func best_spot(data: TowerData, how: String) -> Vector2:
	var map = _main.get_node("%MapGenerator")
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var length: int = map.route_length(route)
	var tried := {}
	var best := Vector2(-1, -1)
	var best_score := -INF
	var reach: float = (data.attack_range + 0.5) * map.MAP_GRID.cell_size.x
	for point in route:
		var centre_half: Vector2 = (point * 2.0).floor()
		for dx in range(-3, 3):
			for dy in range(-3, 3):
				var origin := centre_half + Vector2(dx, dy)
				if tried.has(origin):
					continue
				tried[origin] = true
				var halves: Array = map.halves_of(origin)
				if not halves.all(func(h: Vector2) -> bool: return map.is_buildable_half(h)):
					continue
				var path: PackedVector2Array = map.get_path_if_blocked_halves(halves)
				if path.is_empty():
					continue
				var new_length: int = map.route_length(path)
				var score := 0.0
				if how == "maze":
					# Ties go to a half-cell offset (an odd origin): on an open island many spots gain the same, and
					# whole-cell walls hide the stagger that half cells allow ("stagger": 0 turns it off)
					var staggered := int(origin.x) % 2 != 0 or int(origin.y) % 2 != 0
					score = new_length - length + _rng.randf() * 0.01 + (float(scene.get("stagger", 0.5)) if staggered else 0.0)
					# …and toward spots touching a wall already there, so Wardens join into walls rather than dots
					# ("join": the bonus per touching half cell, default 0 (off: it costs route length), up to 4)
					var touching := 0
					for rx in range(-1, 3):
						for ry in range(-1, 3):
							if (rx < 0 or rx > 1 or ry < 0 or ry > 1) and map.path_layer.is_half_blocked(origin + Vector2(rx, ry)):
								touching += 1
					score += float(scene.get("join", 0.0)) * mini(touching, 4)
				else:
					if new_length < length:
						continue
					var centre := Tower.half_centre(origin)
					for p in path:
						if map.MAP_GRID.calculate_map_position(p).distance_to(centre) <= reach:
							score += 1.0
					score += (new_length - length) * 0.5
				if score > best_score:
					best_score = score
					best = origin
	return best

# A blocking gift laid where it lengthens the route most, keeping it open: "chain" and "line" gifts as a straight
# run of their largest size across cells the gift screen would allow (free, not the glade); "cell" one cell.
func detour_cells(id: StringName) -> Array:
	var info: Dictionary = HeartwoodGifts.POOL.get(id, {})
	var place: StringName = info.get("place", &"cell")
	var size: int = 1
	if info.get("size") is Array:
		size = int(info.size[-1])
	elif info.get("size") is int:
		size = int(info.size)
	if place == &"cell":
		size = 1
	var map = _main.get_node("%MapGenerator")
	var glade: Array = Array(map.get_glade_cells()) if map.has_method("get_glade_cells") else []
	var ok := func(cell: Vector2) -> bool: return map.is_buildable(cell) and not glade.has(cell)
	var length: int = map.route_length(map.get_path_from(map.startPath))
	var best: Array = []
	var best_gain := -INF
	var tried := {}
	for point in map.get_path_from(map.startPath):
		for cell in DreamState.route_cells(point):
			for dir in [Vector2.RIGHT, Vector2.DOWN]:
				for shift in size:  # Every run of `size` cells through this route cell
					var start: Vector2 = cell - dir * shift
					var key := "%s/%s" % [start, dir]
					if tried.has(key):
						continue
					tried[key] = true
					var run: Array = []
					for i in size:
						run.append(start + dir * i)
					if not run.all(ok):
						continue
					var path: PackedVector2Array = map.get_path_if_blocked_cells(run)
					if path.is_empty():
						continue
					var gain: float = map.route_length(path) - length + _rng.randf() * 0.01
					if gain > best_gain:
						best_gain = gain
						best = run
	return best

# --- Camera ------------------------------------------------------------------------------------------

func _route_pixels() -> PackedVector2Array:
	var map = _main.get_node("%MapGenerator")
	var points := PackedVector2Array()
	for p in map.get_path_from(map.startPath):
		points.append(map.MAP_GRID.calculate_map_position(p))
	return points

func _spot(at) -> Vector2:
	var map = _main.get_node("%MapGenerator")
	if at is Array and at.size() == 2:
		return map.MAP_GRID.calculate_map_position(Vector2(float(at[0]), float(at[1])))
	match String(at):
		"start":
			return map.MAP_GRID.calculate_map_position(map.startPath)
		"heartwood":
			return map.MAP_GRID.calculate_map_position(map.endPath)
	return Vector2(map.MAP_GRID.size) * map.MAP_GRID.cell_size / 2.0

func _update_camera(_real_delta: float) -> void:
	if _camera == null or _cam.is_empty():
		return
	var kind := String(_cam.camera)
	var zoom := float(_cam.get("zoom", _cam.from_zoom))
	var duration := maxf(float(_cam.get("duration", 0.0)), 0.001)
	var t := clampf((clip_time - float(_cam.started)) / duration, 0.0, 1.0)
	var eased := t * t * (3.0 - 2.0 * t)
	match kind:
		"hold":
			_camera.target_position = _spot(_cam.get("at", "centre"))
			_camera.target_zoom = Vector2.ONE * zoom
		"push":
			_camera.target_position = (_cam.from_pos as Vector2).lerp(_spot(_cam.get("at", "centre")), eased)
			_camera.target_zoom = Vector2.ONE * lerpf(float(_cam.from_zoom), zoom, eased)
		"glide":
			_camera.target_zoom = Vector2.ONE * lerpf(float(_cam.from_zoom), zoom, eased)
		"follow":
			if not is_instance_valid(_followed) or _followed.is_cleansed:
				_followed = _pick(String(_cam.get("target", "furthest")))
			if _followed != null:
				_camera.target_position = _followed.global_position
			_camera.target_zoom = Vector2.ONE * zoom

func _pick(target: String) -> Node2D:
	var best: Node2D = null
	var best_left := INF
	for enemy in _main.get_node("%EnemyContainer").get_enemies():
		if enemy.is_cleansed:
			continue
		var id: String = enemy.enemy_data.resource_path.get_file().get_basename() if enemy.enemy_data else ""
		if target == "boss" and not (enemy.enemy_data and enemy.enemy_data.is_boss):
			continue
		if target not in ["boss", "furthest"] and id != target:
			continue
		var left: float = enemy.get_remaining_distance()
		if left < best_left:
			best_left = left
			best = enemy
	return best

# --- Chain slow motion, filtering ------------------------------------------------------------------------

# "slow_chain": {"at": 8, "speed": 0.3, "hold": 2.0}: when a Reaction chain reaches `at`, the game slows for `hold`
# real seconds (and the camera looks there unless it follows a nightmare).
func _update_slow_motion(real_delta: float) -> void:
	if _tracker == null:  # Hooked in every scene: dry runs log chains even without slow motion
		_tracker = get_tree().get_first_node_in_group(&"reaction_tracker")
		if _tracker != null:
			_tracker.chain_reached.connect(_on_chain)
	if _slow_left > 0.0:
		_slow_left -= real_delta
		if _slow_left <= 0.0:
			_main.get_node("%GameSpeed").set_speed(_speed_before)

func _on_chain(count: int, where: Vector2, _towers_in: Array) -> void:
	print("Capture: chain ×%d at %.1f s" % [count, clip_time])
	if not scene.has("slow_chain"):
		return
	var slow: Dictionary = scene.slow_chain
	if count < int(slow.get("at", 8)) or _slow_left > 0.0:
		return
	_speed_before = _main.get_node("%GameSpeed").speed
	_main.get_node("%GameSpeed").set_speed(float(slow.get("speed", 0.3)))
	_slow_left = float(slow.get("hold", 2.0))
	if _camera != null and String(_cam.get("camera", "")) != "follow":
		_camera.target_position = where

# Art drawn at a whole-number zoom keeps its hard pixels; at any other zoom it's filtered, so it doesn't shimmer.
func _update_filter() -> void:
	if _camera == null:
		return
	var zoom: float = _camera.camera_2d.zoom.x
	var whole := zoom >= 0.99 and absf(zoom - roundf(zoom)) < 0.02
	get_viewport().canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST if whole \
		else Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR

# --- "+N path" tags --------------------------------------------------------------------------------------

func _age_tags(real_delta: float) -> void:
	if _tags.is_empty() or _tag_layer == null:
		return
	for tag in _tags:
		tag[2] += real_delta
	_tags = _tags.filter(func(tag: Array) -> bool: return tag[2] < TAG_LIFE)
	_tag_layer.queue_redraw()

# Drawn TAG_SIZE video pixels tall whatever the zoom (a phone screen), gold on a dark pill.
const TAG_SIZE := 34.0

func _draw_tags() -> void:
	var zoom: float = _camera.camera_2d.zoom.x if _camera != null else 1.0
	var font := UiStyle.body_font()
	var size := int(TAG_SIZE / maxf(zoom, 0.1))
	for tag in _tags:
		var share: float = tag[2] / TAG_LIFE
		var fade := 1.0 - share * share
		var text: String = tag[1]
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		var pos: Vector2 = tag[0] - Vector2(width / 2.0, (40.0 + TAG_RISE * share) / zoom)
		var pad := 8.0 / zoom
		_tag_layer.draw_rect(Rect2(pos + Vector2(-pad, -size * 0.85 - pad * 0.5), Vector2(width + pad * 2.0, size + pad)), Color(Palette.VOID, 0.7 * fade))
		_tag_layer.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(Palette.GOLD, fade))

# --- Map dump (dry runs: -- --capture=… --map, or "map": true in the scene) -----------------------------

func _wants_map() -> bool:
	return bool(scene.get("map", false)) or OS.get_cmdline_user_args().has("--map")

# The board in half cells (what "spots" take: a Warden's 2×2 footprint has its top-left half there):
# # rim, T obstacle, S start, H Heartwood, g glade (unbuildable), W Warden, * the route (its centre line), . free.
func print_map(when: String) -> void:
	var map = _main.get_node("%MapGenerator")
	var halves: Vector2i = Vector2i(map.MAP_GRID.size) * 2
	var route := {}
	for point in map.get_path_from(map.startPath):
		for h in map.body_halves(point):
			route[h] = true
	var glade: Array = Array(map.get_glade_cells()) if map.has_method("get_glade_cells") else []
	var lines: Array[String] = ["Capture: map %s (half cells %d×%d; x across, y down)" % [when, halves.x, halves.y]]
	var tens := "    "
	var ones := "    "
	for x in halves.x:
		tens += str(x / 10) if x % 10 == 0 else " "
		ones += str(x % 10)
	lines.append(tens)
	lines.append(ones)
	for y in halves.y:
		var row := "%3d " % y
		for x in halves.x:
			var h := Vector2(x, y)
			var cell := (h / 2.0).floor()
			var mark := "."
			if cell == map.startPath:
				mark = "S"
			elif cell == map.endPath:
				mark = "H"
			elif map.obstacles.has(cell):
				mark = "T"
			elif cell.x <= 0 or cell.y <= 0 or cell.x >= map.MAP_GRID.size.x - 1 or cell.y >= map.MAP_GRID.size.y - 1:
				mark = "#"
			elif map.path_layer.is_half_blocked(h):
				mark = "W"
			elif route.has(h):
				mark = "*"
			elif glade.has(cell):
				mark = "g"
			row += mark
		lines.append(row)
	print("\n".join(lines))
