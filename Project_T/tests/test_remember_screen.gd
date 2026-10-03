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
	# The branch expansion offers 2 of 5 per run: the first branch this run draws (offered ones have a node).
	var branch: TowerData = sporeling.evolves_to.filter(func(b) -> bool: return dreams.is_branch_offered(b) and b.tier == 2 and dreams.get_unlock_blocker(b) == "")[0]
	_check(nodes.has(branch) and screen.state_of(branch) == RememberScreen.State.CAN_UNLOCK,
		"a branch can be unlocked with 1 Dreamlight")
	var final: TowerData = branch.evolves_to[0] if not branch.evolves_to.is_empty() else null
	if final != null:
		_check(nodes.has(final) and screen.state_of(final) == RememberScreen.State.LOCKED, "its final form is locked behind it")
		# Hidden until its branch is unlocked (user: "hide the final evolution until you unlock the first one")
		_check(screen.is_veiled(final) and not nodes[final].portrait.visible and nodes[final].tooltip_text.contains("Unlock %s" % branch.display_name),
			"…veiled: no portrait, \"%s\"" % nodes[final].tooltip_text)
		screen._select(final)
		var veiled_texts: Array = screen._side_box.get_children().filter(func(c: Node) -> bool: return c is Label).map(func(l: Label) -> String: return l.text)
		_check(veiled_texts.has("?") and screen._side_box.find_child("UnlockButton", true, false) == null, "…its panel shows only \"?\" and the hint, no cost")
	_check(nodes[sporeling].portrait.material == null, "an owned form is full colour")
	_check(nodes[sporeling].position.y > nodes[branch].position.y, "the root sits below its branches")

	# The side panel and unlocking
	screen._select(branch)
	var texts: Array = screen._side_box.get_children().filter(func(c: Node) -> bool: return c is Label).map(func(l: Label) -> String: return l.text)
	_check(texts.any(func(t: String) -> bool: return t.begins_with("Grow from Sporeling")), "the side panel shows the Dew to grow (%s)" % " | ".join(texts))
	# Combos are {combo:<id>} links (user: "hovering over combos doesn't do anything"): hovering one shows its tip
	var combos_label: RichTextLabel = screen._side_box.find_child("Combos", true, false)
	if combos_label != null:
		var first_id := combos_label.text.get_slice("[url=combo:", 1).get_slice("]", 0)
		_check(first_id != "", "the combos are links (%s)" % combos_label.text)
		combos_label.meta_hover_started.emit("combo:" + first_id)
		var combo_popup: StatusLinks = combos_label.get_meta(&"status_popup")
		_check(combo_popup != null and combo_popup.visible and combo_popup._text.text != "", "hovering a combo in the Remember panel shows its tip")
		combo_popup.visible = false
	else:
		_check(false, "Sporeling's branch lists its combos")
	_check(screen.unlock(branch) and dreams.is_unlocked(branch.get_id()) and dreams.dreamlight == 0,
		"Unlock spends Dreamlight and unlocks the branch")
	_check(screen.state_of(branch) == RememberScreen.State.UNLOCKED and not screen._canvas._bloom_edge.is_empty(),
		"…it blooms along the tree line")
	if final != null:
		var revealed: Dictionary = screen._canvas.nodes
		_check(not screen.is_veiled(final) and revealed.has(final) and revealed[final].portrait.visible
			and revealed[final].portrait.modulate == Color.WHITE.darkened(0.2), "…and its final reveals: its real portrait, dimmed to ~80%")

	# Can't afford (CantAfford, user): the final form costs more than the 0 Dreamlight left. The button stays enabled
	# in the dim style with only the missing amount in POOR; a press refuses out loud; it turns normal once affordable.
	if final != null and dreams.get_unlock_blocker(final) == "":
		screen._select(final)
		await process_frame
		var buy: Button = screen._side_box.find_child("UnlockButton", true, false)
		var cost := dreams.get_unlock_cost(final)
		_check(buy != null and not buy.disabled and CantAfford.is_shown(buy), "short of Dreamlight: the dim can't-afford button, still pressable")
		if buy != null:
			var rich: RichTextLabel = buy.get_node_or_null(CantAfford.TEXT_NODE)
			_check(rich != null and rich.get_parsed_text().strip_edges() == "Unlock · %d Dreamlight" % cost and not rich.get_parsed_text().contains("needed")
				and rich.text.contains(UiStyle.POOR.to_html(false)), "…\"Unlock · %d Dreamlight\", the cost in POOR, no count" % cost)
			_check(buy.tooltip_text.begins_with("Not enough Dreamlight") and not buy.tooltip_text.contains(str(cost)), "…its hover says where Dreamlight comes from, no count (%s)" % buy.tooltip_text)
			var refused := []
			screen.unlock_rejected.connect(func(d: TowerData) -> void: refused.append(d), CONNECT_ONE_SHOT)
			buy.pressed.emit()
			_check(refused == [final] and not dreams.is_unlocked(final.get_id()), "…pressing it refuses (signal for Sound, nothing unlocked)")
		dreams.add_dreamlight(cost)
		await process_frame
		var buy_now: Button = screen._side_box.find_child("UnlockButton", true, false)
		_check(buy_now != null and not CantAfford.is_shown(buy_now) and buy_now.text == "Unlock · %d Dreamlight" % cost,
			"…and the normal button the moment it's affordable")
		dreams.add_dreamlight(-cost)
		screen._select(branch)

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
	var offered: Array = sporeling.evolves_to.filter(func(b) -> bool: return dreams.is_branch_offered(b) and b.tier == 2 and b != branch and dreams.get_unlock_blocker(b) == "")
	var other: TowerData = offered[0] if not offered.is_empty() else null  # Another branch this run offers
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
		_check(side.size() == 3 and side[0] == "???" and side[1].to_lower() == "locked" and side[2] == "Plant it in the Memory Grove",
			"its side panel: \"???\" (no name), \"Locked\" and to plant it, nothing else (%s)" % " | ".join(side))
		var grove_node: Control = nodes[hidden]
		_check(grove_node.portrait.material == RememberScreen.Portrait.silhouette_material(),
			"a Grove form is a silhouette (on the moonlit disc)")
		var side_portrait: Array = screen._side_box.find_children("*", "TextureRect", true, false)
		_check(not side_portrait.is_empty() and side_portrait[0].material == RememberScreen.Portrait.silhouette_material(), "…and its silhouette, not the picture")
		_check(grove_node.tooltip_text.begins_with("???") and not grove_node.tooltip_text.contains(hidden.display_name) and grove_node.name_shown() == "???",
			"…and unnamed: \"???\" under it and in its tooltip (%s)" % grove_node.name_shown())
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
