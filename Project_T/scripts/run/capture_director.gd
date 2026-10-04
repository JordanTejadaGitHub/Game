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
#   "game_music": false (the game's Music bus is muted: the export adds the music bed),
#   "timeline": [ {"t": 0.0, <one action>}, … ] }
# Actions (t = seconds of the clip, unaffected by slow motion):
#   {"plant": "<warden id or form>", "at": [hx, hy] (half cells: the 2×2 footprint's top-left) | "auto": "maze" | "cover",
#    "rank": 0, "tag": true}            a form is grown from its root; "maze" picks the spot that lengthens the route most,
#                                       "cover" the spot that covers most of the route ("+N path" tags float up)
#   {"plant_each": 0.5, "count": 20, "plant": "thornwall", "auto": "maze"}   one every 0.5 s (also with "spots": [[hx, hy], …])
#   {"start": true}                      starts the next drift (the scene's "drift" first)
#   {"speed": 0.25}                      game speed (slow motion < 1)
#   {"spawn": "<enemy id>", "count": 1, "elite": false}
#   {"leaves": 1} / {"dew": 500}
#   {"gift": "<gift id>", "cells": [[x, y], …]}   a Heartwood's Gift, applied as if picked (the effect's placement)
#   {"dossier": true | false}            open / close the boss dossier ("What's coming")
#   {"camera": "hold", "at": [x, y] | "start" | "heartwood" | "centre", "zoom": 1.2}
#   {"camera": "glide", "duration": 8.0, "zoom": 1.4}          along the route, start → Heartwood
#   {"camera": "push", "at": …, "zoom": 2.0, "duration": 4.0}  a slow push-in (or out) onto a spot
#   {"camera": "follow", "target": "boss" | "furthest" | "<enemy id>", "zoom": 1.6}

enum Hud { FULL, CLEAN, NONE }

const SETTING := "capture_mode"
const FLAG := "--capture="
const PROFILE := "user://capture_heartwood.json"
const GAME_SCENE := "res://scenes/main.tscn"
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

# --- Launch ------------------------------------------------------------------------------------------

static func is_available() -> bool:
	return OS.is_debug_build()

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
	RunSaver.file_path = "user://capture_run.json"
	RunHistory.file_path = "user://capture_run_history.json"
	var settings := HeartwoodMemory.get_settings()
	settings.whispers = false
	settings.damage_numbers = int(scene.get("damage_numbers", 0))
	settings.ui_scale = 1.0
	settings.fullscreen = false
	settings[SETTING] = 0
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
	var main: Node = load(GAME_SCENE).instantiate()
	main.get_node("%MapGenerator").map_seed = int(scene.get("seed", 4242))
	tree.change_scene_to_node.call_deferred(main)
	return true

# Made by Main when capture mode is on or a scene is playing.
static func wanted() -> bool:
	return is_available() and (not scene.is_empty() or hud_mode() != Hud.FULL)

# --- Running -----------------------------------------------------------------------------------------

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_main = get_parent()
	_camera = get_tree().get_first_node_in_group(&"game_camera")
	get_tree().process_frame.connect(func() -> void: _scale = Engine.time_scale)
	if scene.is_empty():
		return
	_tag_layer = Node2D.new()
	_tag_layer.z_index = 30
	_tag_layer.draw.connect(_draw_tags)
	_main.add_child.call_deferred(_tag_layer)
	get_viewport().gui_disable_input = true  # The mouse over the render window changes nothing
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_events = _expand(scene.get("timeline", []))
	_setup.call_deferred()

func _setup() -> void:
	seed(int(scene.get("seed", 4242)))  # The same clip every render (auto spots break ties at random)
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
	_started = true
	print("Capture: playing %s (%.0f s)" % [scene.get("title", ""), float(scene.get("length", 20.0))])

func _process(delta: float) -> void:
	_apply_hud()
	if scene.is_empty() or not _started:
		return
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
	if clip_time >= float(scene.get("length", 20.0)):
		set_process(false)
		var map = _main.get_node("%MapGenerator")
		print("Capture: done, %d Wardens, route %d cells" % [_main.get_node("%TowerContainer").get_child_count(),
			map.route_length(map.get_path_from(map.startPath))])
		get_tree().quit()

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
		for i in int(event.get("count", 1)):
			_main.get_node("%EnemyContainer").spawn_enemy(data, director.get_health_multiplier(data, maxi(director.drifts_started, 1)), {}, bool(event.get("elite", false)))
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
			gifts.choose(StringName(event.gift), {"cells": cells})
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
	if event.has("pick_dream"):  # Takes the offer's Nth card (screens shown with "quiet": false)
		var dreams: DreamState = _main.get_node("%DreamState")
		if dreams.is_offering() and int(event.pick_dream) < dreams.current_offer.size():
			dreams.choose(dreams.current_offer[int(event.pick_dream)])
	if event.has("camera"):
		_cam = event.duplicate()
		_cam.started = clip_time
		_cam.from_zoom = _camera.target_zoom.x if _camera != null else 1.0
		_cam.from_pos = _camera.target_position if _camera != null else Vector2.ZERO
		_followed = null
		if String(event.camera) == "glide" and _camera != null:
			_camera.glide(_route_pixels(), float(event.get("duration", 6.0)))

# --- Planting ----------------------------------------------------------------------------------------

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
		origin = best_spot(chain[-1], auto if auto != "" else ("cover" if chain[-1].can_attack else "maze"))
	if origin.x < 0:
		return false
	var before: int = map.route_length(map.get_path_from(map.startPath))
	var shown := run_state.dew  # The scene's Dew stays what it shows: planting and growing are paid from a loan
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
					score = new_length - length + randf() * 0.01
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
	if not scene.has("slow_chain"):
		return
	if _tracker == null:
		_tracker = get_tree().get_first_node_in_group(&"reaction_tracker")
		if _tracker != null:
			_tracker.chain_reached.connect(_on_chain)
	if _slow_left > 0.0:
		_slow_left -= real_delta
		if _slow_left <= 0.0:
			_main.get_node("%GameSpeed").set_speed(_speed_before)

func _on_chain(count: int, where: Vector2, _towers_in: Array) -> void:
	var slow: Dictionary = scene.slow_chain
	print("Capture: chain ×%d at %.1f s" % [count, clip_time])
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
