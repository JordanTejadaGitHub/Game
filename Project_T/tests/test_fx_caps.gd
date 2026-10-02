extends SceneTree

# Headless test for the effect caps (user: "a flash in the middle of my screen", "pretty laggy"): no Fx
# effect is drawn wider than Fx.MAX_EFFECT_PX (the x10 Dawnburst was 512 px), bright flashes are limited
# to Fx.MAX_BRIGHT_PER_SECOND a second, and effect sheets stay loaded for the run (FxCache) instead of
# being reloaded from disk mid-fight.
#   godot --headless --path . --script res://tests/test_fx_caps.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_fx_caps_%d.json" % OS.get_process_id()  # Not the player's settings
	Fx.reset_run()
	var world := Node2D.new()
	root.add_child(world)
	await process_frame
	var burst := Fx.play(&"dawnburst", Vector2(400, 300), world, Fx.DAWNBURST_SCALE, false)
	_check(burst != null and 256.0 * burst._scale <= Fx.MAX_EFFECT_PX + 0.01,
		"the Dawnburst is at most %d px across (%.0f)" % [Fx.MAX_EFFECT_PX, 256.0 * burst._scale if burst else -1.0])
	var small := Fx.play(&"crit_flare", Vector2(0, 0), world)
	_check(small != null and small._scale > 0.0, "a small effect keeps its own size")
	await create_timer(1.1).timeout  # A fresh one-second window
	var allowed := 0
	for i in 10:
		if Fx.bright_flash_ok():
			allowed += 1
	_check(allowed == Fx.MAX_BRIGHT_PER_SECOND, "at most %d bright flashes a second (%d)" % [Fx.MAX_BRIGHT_PER_SECOND, allowed])
	var cache := FxCache.find(world)
	_check(cache != null and cache.textures.size() >= 50, "the run's FxCache holds the effect sheets (%d)" % (cache.textures.size() if cache else 0))
	_check(Fx.texture(&"dawnburst") == cache.textures.get(&"dawnburst"), "Fx reads them from the cache")
	# Effects quality: Reduced (the setting or the automatic step-down on long frames) thins Reaction sheets.
	Fx.auto_reduced = true
	_check(Fx.reduced(), "long frames step effects down")
	Fx._full_times.clear()
	var shown := []
	for i in 4:
		shown.append(Fx._pick(&"thunderclap", true))
	_check(shown.count(&"thunderclap") == Fx.REDUCED_FULL_PER_SECOND, "reduced: only %d full Reactions a second (%s)" % [Fx.REDUCED_FULL_PER_SECOND, shown])
	Fx.auto_reduced = false
	Fx.view_rect = Rect2(0, 0, 1000, 800)
	_check(Fx.on_screen(Vector2(50, 50)) and not Fx.on_screen(Vector2(2000, 2000)), "on_screen reads the visible rect")
	Fx.view_rect = Rect2(0, 0, 64, 64)
	_check(Fx.on_screen(Vector2(2000, 2000)), "a headless / tiny viewport never calls the map off-screen")
	Fx.view_rect = Rect2()
	# Callouts stack instead of overlapping (user: "Lightning Rod!" over "Thunderclap!").
	var first := Fx.callout("Thunderclap!", Palette.GLOW, Vector2(300, 300), world, &"t1")
	var second := Fx.callout("Lightning Rod!", Palette.GLOW, Vector2(305, 302), world, &"t2")
	_check(first != null and second != null and absf(first.global_position.y - second.global_position.y) >= Fx.CALLOUT_CLEAR.y,
		"a second callout on the same spot stacks a line up")
	world.queue_free()
	await process_frame
	print("fx caps test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
