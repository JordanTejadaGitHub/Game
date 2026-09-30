extends SceneTree
# The Omen mist (run_design.md "How an Omen looks"): rolls in when an Omen is picked, lifts at the rest
# that pays it, comes back on a resumed save with an active Omen; Clear Skies = none.
# Run:  Godot --headless --path . --script res://tests/test_omen_mist.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 1207
	root.add_child(main)
	await process_frame
	var map = main.get_node("%MapGenerator")
	var omens: OmenDirector = main.get_node("%OmenDirector")
	var mist: OmenMist = map.omen_mist

	_check(mist.get_blob_count() > 10 and mist.z_index == -1, "the mist lies on the ground, under everything standing on it")
	await _seconds(0.5)
	_check(not mist.visible and mist.strength == 0.0, "no mist without an Omen")

	# Clear Skies: nothing.
	var omen: OmenData = omens.pool[0]
	omens.current_offer = [omen]
	omens.current_offer_block = 1
	omens.choose(null)
	await _seconds(0.5)
	_check(not mist.visible, "Clear Skies brings no mist")

	# An Omen picked: the mist rolls in over ~3 s.
	omens.current_offer = [omen]
	omens.current_offer_block = 1
	omens.choose(omen)
	await _seconds(1.0)
	_check(mist.visible and mist.strength > 0.2 and mist.strength < 0.5, "the mist is rolling in (%.2f after 1 s)" % mist.strength)
	await _seconds(2.5)
	_check(mist.strength == 1.0, "and is fully in after ~3 s")

	# The rest after the block pays the Omen: the mist lifts.
	omens._pay_reward(0)
	await _seconds(3.5)
	_check(not mist.visible and mist.strength == 0.0, "the mist lifts at the rest that pays the Omen")

	# A resumed save with an active Omen brings it back.
	omens.load_save({"active": omen.id, "active_block": 1})
	await _seconds(3.5)
	_check(mist.visible and mist.strength == 1.0, "a resumed save with an active Omen shows the mist")

	print("omen mist test: %d failure(s)" % failures)
	main.free()
	quit(failures)

func _seconds(s: float) -> void:
	for i in int(s * 60):
		await process_frame

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", what)
