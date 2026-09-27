extends SceneTree

# Headless test for the combat effects player (scripts/fx/fx.gd): every sheet in effects.json
# plays and frees itself, loops last their `seconds`, segments stretch, the ~6/s budget and
# reduce-flashes swap in _lite sheets, and chains show the badge, surge and Dawnburst and restore
# the game speed after the hitstop. Run:
#   godot --headless --path . --script res://tests/test_fx.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	_use_settings({"reduce_flashes": false, "hitstop": true, "reduced_motion": true})

	# --- Every sheet plays, one-shots free themselves ---
	var index: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Fx.INDEX_PATH)).effects
	_check(index.size() >= 25, "effects.json lists the sheets (%d)" % index.size())
	var one_shots: Array = []
	for effect: String in index:
		var entry: Dictionary = index[effect]
		if entry.kind in ["segment", "font", "overlay"]:
			continue
		var node := Fx.play(StringName(effect), Vector2(100, 100), world, 1.0, false, 0.5)
		_check(node != null, "plays %s" % effect)
		if node != null and not entry.loop:
			one_shots.append(node)
	await _wait(3.0)
	_check(one_shots.all(func(n): return not is_instance_valid(n)), "one-shot effects free themselves")
	_check(world.get_child_count() == 0, "timed loops free themselves too (%d left)" % world.get_child_count())

	# --- Anchors: lightning_rod lands on its impact point ---
	var rod := Fx.play(&"lightning_rod", Vector2(200, 300), world, 1.0, false)
	_check(rod.global_position == Vector2(200, 300), "effects sit at the given point (anchor handled in drawing)")
	rod.queue_free()

	# --- Segments ---
	var arc := Fx.segment(&"thunderclap_arc", Vector2(0, 0), Vector2(150, 0), world, 0.3)
	_check(arc != null and is_equal_approx(arc._length, 150.0), "segments stretch to the distance")
	var drag := Fx.segment(&"long_way_home_drag", Vector2(0, 0), Vector2(0, 90), world)
	_check(is_equal_approx(drag.rotation, PI / 2.0), "segments point from start to end")
	_check(Fx.segment(&"light_thread", Vector2.ONE, Vector2.ONE, world) == null, "a zero-length segment is skipped")

	# --- Status flash rows and crit ---
	var flash := Fx.status_flash(&"static", Vector2(50, 50), world)
	var rows: Array = index.status_flash.rows
	_check(flash.row == rows.find("static"), "status_flash picks the status's row")
	_check(Fx.crit(Vector2(10, 10), world) != null, "crit flare plays")

	# --- Budget: after 6 full Reactions in a second, the lite sheets take over ---
	Fx._full_times.clear()
	var shown: Array = []
	for i in 8:
		shown.append(Fx.reaction(&"thunderclap", Vector2(64 * i, 0), world).effect)
	_check(shown.slice(0, 6).all(func(n): return n == &"thunderclap"), "the first 6 Thunderclaps are full")
	_check(shown.slice(6).all(func(n): return n == &"thunderclap_lite"), "the rest use thunderclap_lite")
	_check(Fx.play(&"shatter", Vector2.ZERO, world).effect == &"shatter", "effects without a lite sheet always play")

	# --- Reduce flashes: lite everywhere, no surge ---
	_use_settings({"reduce_flashes": true, "hitstop": false, "reduced_motion": true})
	Fx._full_times.clear()
	_check(Fx.play(&"ignite", Vector2.ZERO, world).effect == &"ignite_lite", "reduce flashes always uses lite")
	var layers_before := _canvas_layers()
	Fx.chain(5, Vector2(300, 300), world)
	_check(_canvas_layers() == layers_before, "no surge with reduce flashes")
	_use_settings({"reduce_flashes": false, "hitstop": true, "reduced_motion": true})

	# --- Reaction callout and light threads ---
	var warden := Node2D.new()
	world.add_child(warden)
	warden.global_position = Vector2(400, 400)
	Fx._callout_cooldown.clear()
	Fx._callouts_alive.clear()
	var before := world.get_child_count()
	Fx.reaction(&"ignite", Vector2(500, 400), world, [warden])
	_check(world.get_child_count() == before + 3, "a Reaction adds its effect, a callout and a light thread")

	# --- Chains ---
	Fx.reset_run()
	_use_settings({"reduce_flashes": false, "hitstop": true, "reduced_motion": true})
	if is_instance_valid(Fx._badge):
		Fx._badge.free()
	Fx.chain(1, Vector2.ZERO, world)
	_check(not is_instance_valid(Fx._badge), "no badge for a single Reaction")
	Fx.chain(2, Vector2(100, 100), world)
	_check(is_instance_valid(Fx._badge) and Fx._badge._text == "x2", "x2 shows the badge")
	Engine.time_scale = 1.0
	layers_before = _canvas_layers()
	Fx.chain(5, Vector2(100, 100), world)
	_check(Engine.time_scale < 0.1, "x5 hitstops")
	_check(_canvas_layers() == layers_before + 1, "x5 surges the screen")
	await create_timer(0.3, true, false, true).timeout
	_check(is_equal_approx(Engine.time_scale, 1.0), "the game speed comes back after the hitstop")
	await create_timer(0.6, true, false, true).timeout
	_check(_canvas_layers() == layers_before, "the surge clears itself")
	Fx.chain(10, Vector2(100, 100), world, [warden])
	_check(world.get_children().any(func(n): return n is Fx.FxSprite and n.effect == &"dawnburst"), "x10 plays the Dawnburst")
	await create_timer(0.3, true, false, true).timeout
	_check(Fx.longest_chain == 10, "the run's longest chain is tracked")
	Engine.time_scale = 1.0

	# --- Monsoon rain ---
	_check(Fx.rain_sweep(Vector2(200, 200), 150.0, world) != null, "Monsoon's rain sweep plays")

	print("fx test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _use_settings(settings: Dictionary) -> void:
	Fx._settings = settings
	Fx._settings_at = Time.get_ticks_msec() + 3600000  # Don't reload from disk during the test

func _canvas_layers() -> int:
	return root.get_children().filter(func(n): return n is CanvasLayer).size()

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _wait(seconds: float) -> void:
	await create_timer(seconds, true, false, true).timeout
