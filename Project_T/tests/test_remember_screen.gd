extends SceneTree

# Headless test for the Remember screen (run_design.md "The Remember screen, fleshed out"): tabs per
# owned family + Thornwall, the portrait tree and its node states, the side panel, unlocking, the
# pause it restores, and fitting 1280×800. Never touches the player's saves.
#   godot --headless --path . --script res://tests/test_remember_screen.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	root.size = Vector2i(1280, 800)
	var dreams: DreamState = main.get_node("%DreamState")
	var speed: GameSpeed = main.get_node("%GameSpeed")
	var screen := main.get_node("%RememberScreen") as RememberScreen
	dreams.unlock_everything = false
	dreams.unlocked = {"sprout": true, "thornwall": true, "sporeling": true}
	dreams.add_dreamlight(1 - dreams.dreamlight)
	speed.set_paused(false)

	var sporeling: TowerData = load("res://resource/tower/sporeling.tres")
	screen.open(sporeling)
	for i in 3:
		await process_frame
	_check(screen.visible and speed.paused, "Remember opens and pauses")
	var tab_names: Array = screen._tabs.get_children().map(func(b: Button) -> String: return b.text)
	_check(tab_names.has("Sporeling") and tab_names.has("Thornwall"), "a tab per owned family plus Thornwall (%s)" % ", ".join(tab_names))
	var nodes: Dictionary = screen._canvas.nodes
	_check(nodes.has(sporeling), "the base Warden at the root")
	var branch: TowerData = sporeling.evolves_to[0]
	_check(nodes.has(branch) and screen.state_of(branch) == RememberScreen.State.CAN_UNLOCK,
		"a branch can be unlocked with 1 Dreamlight")
	var final: TowerData = branch.evolves_to[0] if not branch.evolves_to.is_empty() else null
	if final != null:
		_check(nodes.has(final) and screen.state_of(final) == RememberScreen.State.LOCKED, "its final form is locked behind it")
	_check(nodes[sporeling].position.y > nodes[branch].position.y, "the root sits below its branches")

	# The side panel and unlocking
	screen._select(branch)
	var texts: Array = screen._side_box.get_children().filter(func(c: Node) -> bool: return c is Label).map(func(l: Label) -> String: return l.text)
	_check(texts.any(func(t: String) -> bool: return t.begins_with("Grow from Sporeling")), "the side panel shows the Dew to grow (%s)" % " | ".join(texts))
	_check(screen.unlock(branch) and dreams.is_unlocked(branch.get_id()) and dreams.dreamlight == 0,
		"Unlock spends Dreamlight and unlocks the branch")
	_check(screen.state_of(branch) == RememberScreen.State.UNLOCKED and not screen._canvas._bloom_edge.is_empty(),
		"…it blooms along the tree line")

	# The screen fits 1280×800
	await process_frame
	var frame_rect := (screen.get_child(1).get_child(0) as Control).get_global_rect()
	_check(Rect2(Vector2.ZERO, Vector2(1280, 800)).encloses(frame_rect), "the screen fits 1280×800 (%s)" % frame_rect)

	screen.close()
	_check(not screen.visible and not speed.paused, "closing restores the pause state from before")
	print("remember screen test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
