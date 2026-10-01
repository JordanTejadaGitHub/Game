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
	world.queue_free()
	await process_frame
	print("fx caps test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
