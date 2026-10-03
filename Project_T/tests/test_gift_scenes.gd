extends SceneTree

# Headless test for CardScene's gift scenes (heartwood_gifts.md, Spire branch): show_scene loops before → after
# (the tag says which, the changed cells glow, walkers keep their places on the new path), the gift letters build
# (props for L / m / b / z, pond tiles for ~, ground for B / r / u / k), bog slows the walkers, a hit on roots shows
# the effect's text, real time at 3× game speed, and reduced motion shows the still after-diagram.
#   godot --headless --path . --script res://tests/test_gift_scenes.gd --fixed-fps 60
# With a window and `-- --preview=<dir>` it saves frames of the loop there.

const BEFORE := """
.......
SPPPPPH
.......
...W...
.......
"""
const AFTER := """
.kkk.m.
SBBrPPH
.kkkLLL
...W.~~
..z.b~~
"""

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var preview := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--preview="):
			preview = arg.trim_prefix("--preview=")
	root.size = Vector2i(400, 330)
	var scene := CardScene.new()
	root.add_child(scene)
	await process_frame
	scene.show_scene(BEFORE, AFTER, {"text": "+15% taken", "damage": 1.15}, "A Mire: nightmares slow on the bog")
	await process_frame
	_check(scene.visible and scene._in_scene and not scene._showing_after and scene._path.size() == 7, "it opens on the before-diagram (path %d)" % scene._path.size())
	_check(CardScene.diff_cells(BEFORE, AFTER).size() == 19, "the diff finds the changed cells (%d)" % CardScene.diff_cells(BEFORE, AFTER).size())
	if preview != "":
		await _shot(preview + "/gift_before.png")
	var walkers_before := 0
	for i in int(CardScene.BEFORE_TIME * 60.0) - 5:
		await process_frame
	walkers_before = scene._walkers.size()
	for i in 10:
		await process_frame
	_check(scene._showing_after, "after %.1f s it swaps to the after-diagram" % CardScene.BEFORE_TIME)
	_check(scene._walkers.size() >= walkers_before and walkers_before > 0, "…the walkers carry over onto the new path (%d → %d)" % [walkers_before, scene._walkers.size()])
	_check(scene._pulse_left > 0.0 and scene._changed.size() == 19, "…and the changed cells glow")
	_check(scene._props.size() == 6, "props: 3 log pieces, a moonwell, a bell stone, a lightning tree (%d)" % scene._props.size())
	_check(scene._path.size() == 7 and scene._letter_at(scene._path[1]) == "B" and scene._letter_at(scene._path[3]) == "r", "bog and roots are walked")
	if preview != "":
		await _shot(preview + "/gift_swap.png")
		for i in 50:
			await process_frame
		await _shot(preview + "/gift_after.png")
	# Bog: slower; roots: the effect's text on a hit
	var walker: Dictionary = scene._walkers[0]
	walker.distance = CardScene.CELL * 1.0  # On the first bog cell
	walker.sprite.position = scene._along(walker.distance)[0]
	scene._move_walkers(0.1)
	_check(is_equal_approx(walker.distance, CardScene.CELL + CardScene.WALK_SPEED * 0.1 * CardScene.BOG_SPEED), "the bog slows the walkers to %.0f%%" % (CardScene.BOG_SPEED * 100))
	walker.distance = CardScene.CELL * 3.0  # On the roots
	scene._move_walkers(0.0)
	var numbers := scene._effects.size()
	scene._hit(walker, false)
	var label = scene._effects[-1].node if scene._effects.size() > numbers else null
	_check(label != null and String(label.text).begins_with("+15% taken"), "a hit on the roots shows the effect (\"%s\")" % (label.text if label else ""))
	# The loop: back to before after AFTER_TIME
	for i in int(CardScene.AFTER_TIME * 60.0) + 5:
		await process_frame
	_check(not scene._showing_after, "after %.1f s it loops back to before" % CardScene.AFTER_TIME)
	# Real time: at 3× the phase lasts the same frames
	Engine.time_scale = 3.0
	scene.show_scene(BEFORE, AFTER, {}, "")
	for i in int(CardScene.BEFORE_TIME * 60.0) - 10:
		await process_frame
	_check(not scene._showing_after, "at 3× game speed the before-phase still takes %.1f real seconds" % CardScene.BEFORE_TIME)
	Engine.time_scale = 1.0
	# Reduced motion: the still after-diagram
	var settings: Dictionary = Fx._settings.duplicate()
	Fx._settings = {"reduced_motion": true}
	Fx._settings_at = Time.get_ticks_msec() + 600000  # Hold the cached setting for the test
	_check(not CardScene.can_show_scene(), "reduced motion: no moving scene")
	scene.show_scene(BEFORE, AFTER, {}, "")
	await process_frame
	_check(scene._showing_after and not scene.is_processing() and scene._walkers.is_empty(), "…a still after-diagram")
	Fx._settings = settings
	Fx._settings_at = -600000  # Re-read next time
	scene.stop()
	scene.queue_free()
	await process_frame
	print("gift scenes test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image != null:
		image.save_png(path)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
