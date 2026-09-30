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
	var combo_names: Array = []
	for n in screen._side_box.find_children("*", "", true, false):
		if n is LinkButton or (n is Label and n.get_parent() is HFlowContainer):
			combo_names.append(n.text)
	var seen := ComboFeedback.load_seen()
	for combo in CodexData.combos():
		if combo_names.has(combo.name):
			_check(CodexData.is_discovered(StringName(combo.id), seen), "only discovered combos show their name (%s)" % combo.name)
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

	# open_remember(form) (Tower Code's Grow button for a form not unlocked yet): on that form, selected.
	if final != null:
		dreams.open_remember(final)
		await process_frame
		_check(screen.visible and screen.selected == final and screen._canvas.nodes.has(final), "open_remember(form) opens on that form")
		screen.close()
	# …also a final form whose branch isn't unlocked yet
	var other: TowerData = sporeling.evolves_to[1] if sporeling.evolves_to.size() > 1 else null
	if other != null and not other.evolves_to.is_empty() and not dreams.is_unlocked(other.get_id()):
		var locked_final: TowerData = other.evolves_to[0]
		dreams.open_remember(locked_final)
		await process_frame
		_check(screen.visible and screen.selected == locked_final and screen._canvas.nodes.has(locked_final),
			"…and on a final form whose branch is still locked")
		screen.close()
	# Playtest fixes: an Ascended node is the same size as the others, its whole art in the disc.
	var mother: TowerData = load("res://resource/tower/sporemother.tres")
	var node := RememberScreen.FormNode.new(screen, mother)
	_check(node.size == RememberScreen.NODE_SIZE and node.portrait._atlas.region.size == mother.get_frame_rect(0).size,
		"the Ascended node: normal size, its whole frame scaled in")
	node.free()

	# Playtest fixes (run_design.md 2026-09-30): an unplanted lane shows only its branch, as a silhouette.
	var hidden: TowerData = null
	for next in sporeling.evolves_to:
		if dreams.get_unlock_blocker(next) == "Memory Grove":
			hidden = next
	_check(hidden != null, "Sporeling has a lane the Grove hasn't planted")
	if hidden != null:
		screen.open(sporeling)
		await process_frame
		nodes = screen._canvas.nodes
		_check(nodes.has(hidden) and screen.state_of(hidden) == RememberScreen.State.GROVE, "the unplanted branch shows as the Grove silhouette")
		_check(not hidden.evolves_to.any(func(f: TowerData) -> bool: return nodes.has(f)), "…its final form is hidden")
		_check(not screen._canvas.edges.any(func(e: Array) -> bool: return e[0] == hidden), "…and so is the line up to it")
		screen._select(hidden)
		var side: Array = screen._side_box.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
		_check(side == ["Plant it in the Memory Grove"], "its side panel only says to plant it (%s)" % " | ".join(side))
		screen.close()

	# The Ascended crown: hidden until its Grove node is planted and drift 51 is reached.
	var director: DriftDirector = main.get_node("%DriftDirector")
	var crown := func() -> TowerData:
		for tree in dreams.get_remember_trees():
			if tree[0] == sporeling:
				return tree[2]
		return null
	var mother_card := "dream_sporemother"
	dreams.grove_cards.append(mother_card)  # Planted, as in an "Unlock all families" / Dev Grove run
	director.drifts_started = 0
	_check(crown.call() == null, "drift 1: no Ascended crown, even with its Grove node planted")
	screen.open(sporeling)
	await process_frame
	_check(not screen._canvas.nodes.has(mother) and not screen._canvas.edges.any(func(e: Array) -> bool: return e[1] == mother),
		"…no node and no line to it on the tree")
	screen.close()
	director.drifts_started = 50
	_check(crown.call() == mother, "drift 51 with the node planted: the crown appears")
	dreams.grove_cards.erase(mother_card)
	_check(crown.call() == null, "drift 51 without the Grove node: still hidden")
	director.drifts_started = 0
	dreams.unlock_everything = true
	_check(crown.call() == mother, "Test Grove still shows everything")
	dreams.unlock_everything = false
	print("remember screen test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
