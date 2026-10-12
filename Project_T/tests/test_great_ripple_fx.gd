extends SceneTree
const EFFECT := preload("res://scripts/fx/great_ripple.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var cue := EFFECT.new(128.0, 1.0)
	root.add_child(cue)
	cue.set_process(false)
	cue._process(0.95)
	check(not cue._released and not cue.is_queued_for_deletion(), "Cue must wait for the actual damage timer")
	cue.release()
	check(cue._released and cue._age == 0.0, "Actual hit starts the aftershock lifetime")
	cue._process(EFFECT.AFTERSHOCK_TIME - 0.01)
	check(not cue.is_queued_for_deletion(), "Aftershock remains visible until its lifetime")
	cue._process(0.02)
	check(cue.is_queued_for_deletion(), "Aftershock must expire")
	var orphan := EFFECT.new(128.0, 1.0)
	root.add_child(orphan)
	orphan.set_process(false)
	orphan._process(1.0 + EFFECT.SAFETY_MARGIN + 0.01)
	check(orphan.is_queued_for_deletion(), "Unreleased cue must have a bounded lifetime")
	await process_frame
	var world := Node2D.new()
	root.add_child(world)
	var old_reduced := Fx.auto_reduced
	Fx.auto_reduced = true
	for i in EFFECT.REDUCED_MAX_ACTIVE:
		check(EFFECT.play(128.0, 1.0, Vector2(i * 30, 0), world) != null, "Reduced ripple cue fills available budget")
	check(EFFECT.play(128.0, 1.0, Vector2.ZERO, world) == null, "Reduced ripple cue cap skips presentation")
	world.queue_free()
	await process_frame
	Fx.auto_reduced = old_reduced
	print("Great Ripple effect lifecycle: %d failures" % failures)
	quit(failures)
