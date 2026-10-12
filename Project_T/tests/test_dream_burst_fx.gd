extends SceneTree
const BURST := preload("res://scripts/fx/dream_burst.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	var old_auto := Fx.auto_reduced
	Fx.auto_reduced = true
	var first := BURST.play(&"spillover", Vector2.ZERO, 64.0, world)
	check(first != null, "First cue spawns")
	first.set_process(false)
	first._process(0.2)
	var same := BURST.play(&"spillover", Vector2(10, 0), 64.0, world)
	check(same == first and first._age == 0.2, "Nearby same-radius burst coalesces without refreshing lifetime")
	var distinct := BURST.play(&"last_breath", Vector2.ZERO, 64.0, world)
	check(distinct != first, "Different Dream signatures remain distinct")
	BURST.play(&"dawnbreak", Vector2(100, 0), 64.0, world)
	BURST.play(&"shattering_blow", Vector2(200, 0), 64.0, world)
	check(BURST.play(&"spillover", Vector2(300, 0), 64.0, world) == null, "Reduced budget caps concurrent cues")
	first._process(BURST.LIFE)
	check(first.is_queued_for_deletion(), "Cue lifetime is bounded")
	check(BURST.play(&"spillover", Vector2.ZERO, 0.0, world) == null, "Invalid footprint is skipped")
	world.queue_free()
	await process_frame
	Fx.auto_reduced = old_auto
	print("Dream burst lifecycle and budget: %d failures" % failures)
	quit(failures)
