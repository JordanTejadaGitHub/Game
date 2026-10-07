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
	# {"kin": true} draws the Kinship bond between neighbouring Wardens (Old Kin's gift card); without it, none
	scene.show_scene(".......\nSPPPPPH\n.......\n..aa...\n.......", ".......\nSPPPPPH\n.......\n..WW...\n.......", {"kin": true}, "")
	await process_frame
	_check(scene._world.get_node_or_null("KinBond") != null, "the kin key draws the Kinship bond")
	scene.show_scene(BEFORE, AFTER, {}, "")
	await process_frame
	_check(scene._world.get_node_or_null("KinBond") == null, "…and only with that key")
	# Every gift scene shows its payoff (user, 2026-10-07: "the Waking Root gift video doesn't show what it does")
	for id in GiftScreen.SCENES:
		var s: Array = GiftScreen.SCENES[id]
		_check(not CardScene.diff_cells(s[0], s[1]).is_empty() or not (s[2] as Dictionary).is_empty(), "%s: the after differs from the before or has an effect" % id)
	var mist: Array = GiftScreen.SCENES[&"thick_mist"]
	_check(not CardScene.diff_cells(mist[0], mist[1]).is_empty() and mist[2].has("spacing"), "Thick Mist's before and after differ, and it spaces the nightmares")
	scene.show_scene(mist[0], mist[1], mist[2], mist[3])
	await process_frame
	var gap_before: float = scene.spacing_gap()
	var line_before := scene._walkers.size()
	scene._phase_left = 0.0
	await process_frame
	await process_frame
	_check(scene._showing_after and line_before > 1 and scene.spacing_gap() > gap_before * 1.2 \
		and scene._world.get_node_or_null("Mist") != null, "…the After line leaves the thick mist further apart (%.0f → %.0f px)" % [gap_before, scene.spacing_gap()])
	var waking: Array = GiftScreen.SCENES[&"waking_root"]
	_check(bool(waking[2].get("unlock", false)), "Waking Root's scene has the unlock effect")
	scene.show_scene(waking[0], waking[1], waking[2], waking[3])
	await process_frame
	_check(scene._unlock != null and scene._unlock_colour.modulate.a == 0.0, "…its locked form starts as a silhouette with its price")
	scene._phase_left = 0.0
	for i in int((CardScene.UNLOCK_AT + CardScene.UNLOCK_FADE) * 60.0) + 10:
		await process_frame
	_check(scene._showing_after and scene._unlock != null and is_equal_approx(scene._unlock_colour.modulate.a, 1.0), "…and fills with colour once the root reaches it")
	if preview != "":
		await _shot(preview + "/gift_waking_root.png")
	# Lookout's crits, the bog's slow tag, the cleared obstacles' tags
	var giant: Array = GiftScreen.SCENES[&"fallen_giant"]
	scene.show_scene(giant[0], giant[1], giant[2], giant[3])
	await process_frame
	var target := {"sprite": Node2D.new(), "hits": 0.0, "fade": -1.0}
	scene._world.add_child(target.sprite)
	for i in 3:
		scene._hit(target, true)
	_check(String(scene._effects[-1].node.text).begins_with("Critical!") and is_equal_approx(target.hits, 4.0), "Fallen Giant: every third favoured hit is a crit")
	var stones: Array = GiftScreen.SCENES[&"shift_stones"]
	scene.show_scene(stones[0], stones[1], stones[2], stones[3])
	await process_frame
	var tags := scene._effects.size()
	scene._phase_left = 0.0
	await process_frame
	_check(scene._effects.size() - tags >= 3, "Shift the Stones: each moved stone pays its Dew (%d tags)" % (scene._effects.size() - tags))
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
