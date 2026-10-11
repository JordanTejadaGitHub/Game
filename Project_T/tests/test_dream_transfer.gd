extends SceneTree
const Transfer = preload("res://scripts/fx/dream_transfer.gd")
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		printerr("FAIL: " + message)
func _run() -> void:
	var world := Node2D.new()
	root.add_child(world)
	Fx._settings = {"effects_quality": 0, "reduced_motion": true}
	Fx._settings_at = Time.get_ticks_msec()
	Fx.auto_reduced = false
	Fx.view_rect = Rect2(0, 0, 900, 600)
	check(not Transfer.play(world, Vector2(-100, -100), Vector2(-40, -40), EnemyStatuses.MARKED), "offscreen skipped")
	check(Transfer.play(world, Vector2(100, 100), Vector2(200, 100), EnemyStatuses.MARKED), "first link accepted")
	check(not Transfer.play(world, Vector2(100, 100), Vector2(200, 100), EnemyStatuses.DAMP), "same transfer coalesces statuses")
	var effect = world.get_node(Transfer.NODE_NAME)
	check(effect.links[0].still, "reduced motion uses still endpoints")
	for i in range(1, Transfer.MAX_LINKS):
		check(Transfer.play(world, Vector2(100, 100 + i * 15), Vector2(200, 100 + i * 15), EnemyStatuses.DAMP), "budget link accepted")
	check(not Transfer.play(world, Vector2(300, 300), Vector2(400, 300), EnemyStatuses.DAMP), "budget bounded")
	effect._process(Transfer.LIFE + 0.01)
	check(effect.links.is_empty() and not effect.is_processing(), "expired links clear and stop processing")
	Fx._settings.effects_quality = 1
	for i in Transfer.REDUCED_LINKS:
		check(effect.add_transfer(Vector2(100, i * 15), Vector2(200, i * 15), EnemyStatuses.SPORED), "reduced link accepted")
	check(not effect.add_transfer(Vector2(400, 400), Vector2(500, 400), EnemyStatuses.SPORED), "reduced budget bounded")
	world.queue_free()
	await process_frame
	print("dream transfer test: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(failures)
