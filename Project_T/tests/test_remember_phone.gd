extends SceneTree

# Headless test for the Remember screen's phone layout (mobile only; Mobile chat, user 2026-10-06: "the remember tech
# tree needs a new mobile rework"): full screen, one top bar, a swiping row of family tabs, the tree scaled into the
# room beside the detail panel, the Unlock button pinned at the panel's foot. Checked at a 20:9 and a 16:9 phone and
# the smallest view. Never touches the player's saves.
#   godot --headless --path . --script res://tests/test_remember_phone.gd --fixed-fps 60

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	TouchBuild.force_mobile = true  # Built for phones from _ready on
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 424242
	root.add_child(main)
	await process_frame
	var dreams: DreamState = main.get_node("%DreamState")
	var screen := main.get_node("%RememberScreen") as RememberScreen
	dreams.unlock_everything = false
	dreams.unlocked = {"sprout": true, "thornwall": true, "sporeling": true}
	dreams.add_dreamlight(3 - dreams.dreamlight)
	_check(RememberScreen.phone_layout() and screen.find_child("TopBar", true, false) != null and screen._action_box != null,
		"phones build the phone layout")
	_check(screen._tabs is HBoxContainer and screen._tabs.get_parent() is ScrollContainer, "the families are one row that swipes")

	var sporeling: TowerData = load("res://resource/tower/sporeling.tres")
	for view in [Vector2i(1600, 720), Vector2i(1280, 720), Vector2i(1200, 540)]:
		root.size = view
		screen.open(sporeling)
		for i in 4:
			await process_frame
		var rect := Rect2(Vector2.ZERO, Vector2(view))
		var done := screen.find_child("DoneButton", true, false) as Control
		_check(done != null and rect.encloses(done.get_global_rect()), "%s: Done on screen" % view)
		var branch: TowerData = sporeling.evolves_to.filter(func(b) -> bool: return b is TowerData and dreams.is_branch_offered(b) and dreams.get_unlock_blocker(b) == "")[0]
		screen._select(branch)
		await process_frame
		await process_frame
		var unlock := screen._action_box.find_child("UnlockButton", false, false) as Button
		_check(unlock != null and rect.encloses(unlock.get_global_rect()) and unlock.size.y >= RememberScreen.PHONE_ACTION_H,
			"%s: Unlock pinned at the panel's foot, on screen and %d tall" % [view, unlock.size.y if unlock != null else 0])
		var node: Control = screen._canvas.nodes.get(branch)
		var node_rect := node.get_global_rect() if node != null else Rect2()
		_check(node != null and rect.encloses(node_rect) and node_rect.size.x >= 60.0 - 0.5,  # The global rect includes the tree's scale
			"%s: tree nodes on screen and at least 60 px (scale %.2f)" % [view, screen._canvas.scale.x])
		var side_rect: Rect2 = screen._side.get_global_rect()
		_check(rect.encloses(side_rect) and side_rect.position.x >= screen._tree_holder.get_global_rect().end.x - 0.5,
			"%s: the detail panel beside the tree, on screen" % view)
		screen.close()
		await process_frame

	# Tapping a node selects it; Unlock works from the pinned button; the ? tip carries the offer line
	root.size = Vector2i(1600, 720)
	screen.open(sporeling)
	await process_frame
	var target: TowerData = sporeling.evolves_to.filter(func(b) -> bool: return b is TowerData and dreams.is_branch_offered(b) and dreams.get_unlock_blocker(b) == "")[0]
	(screen._canvas.nodes[target] as Button).pressed.emit()
	await process_frame
	_check(screen.selected == target, "a tap on a tree node selects it")
	var pinned := screen._action_box.find_child("UnlockButton", false, false) as Button
	pinned.pressed.emit()
	await process_frame
	_check(dreams.is_unlocked(target.get_id()), "the pinned Unlock unlocks it")
	var tip_text: String = screen._info_tip._label.text
	_check(tip_text.contains("Dreamlight unlocks") and (screen.offer_line(sporeling) == "" or tip_text.contains(screen.offer_line(sporeling))),
		"the ? tip explains Dreamlight and the branch offer")
	_check(not screen._offer_line.visible, "no offer line in the layout (it's in the tip)")
	screen.close()

	TouchBuild.force_mobile = false
	main.queue_free()
	await process_frame
	print("FAILURES: %d" % failures if failures > 0 else "PASS")
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   " + label)
	else:
		print("  FAIL " + label)
		failures += 1
