extends SceneTree

# The family pick's routes (user, 2026-10-02: "when picking a family, it should show the family routes it can dream
# into"): in the full game each card shows this run's 2 branches (DreamState.preview_branch_offer), never their finals
# ("don't show the final evolution in the card"), the rest as "not in this dream" silhouettes; after the pick, the picked family's offer (what Remember shows) is exactly
# the card's. The demo shows its fixed branches, no silhouettes. Temp profile.

var failures := 0

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  ok: ", what)
	else:
		failures += 1
		push_error("FAIL: " + what)

func _initialize() -> void:
	_run.call_deferred()

# Each offered family -> the branch ids its card shows, in order.
func _card_routes(family: Node) -> Dictionary:
	var out := {}
	for card in family._cards.get_children():
		var lanes: Array = card.find_children("Route_*", "", true, false)
		var data: TowerData = null
		for candidate in family.offer:
			if candidate is TowerData and lanes.any(func(l: Node) -> bool: return candidate.evolves_to.has(l.get_meta(&"branch"))):
				data = candidate
		if data != null:
			out[data] = lanes.map(func(l: Node) -> String: return (l.get_meta(&"branch") as TowerData).get_id())
	return out

func _new_run(demo: int) -> Node:
	ResultsScreen.demo_override = demo
	var main: Node = load("res://scenes/main.tscn").instantiate()
	main.get_node("MapGenerator").map_seed = 4242
	root.add_child(main)
	await process_frame
	await process_frame
	return main

func _run() -> void:
	HeartwoodMemory.file_path = "user://test_family_routes_%d.json" % OS.get_process_id()
	var main := await _new_run(0)
	var family: Node = main.get_node("%FamilyPickScreen")
	var dreams: DreamState = main.get_node("%DreamState")
	family.show_pick(&"first")
	await process_frame
	var shown := _card_routes(family)
	_check(shown.size() == family.offer.filter(func(o) -> bool: return o is TowerData).size(), "every family card has routes (%d)" % shown.size())
	for data: TowerData in shown:
		var regular := dreams.regular_branches(data).size()
		var lanes: Array = shown[data]
		_check(lanes.size() == mini(regular, dreams.branch_offer_size(data)), "%s: this run's %d branches, not all %d (%s)" % [data.display_name, lanes.size(), regular, lanes])
		var card: Node = null
		for c in family._cards.get_children():
			if not c.find_children("Route_" + String(lanes[0]), "", true, false).is_empty():
				card = c
		var missing: Node = card.find_child("NotInDream", true, false) if card != null else null
		_check(regular <= dreams.branch_offer_size(data) or (missing != null and missing.get_child_count() == regular - lanes.size() + 1),
			"%s: the other %d as 'not in this dream' silhouettes" % [data.display_name, regular - lanes.size()])
		for lane in card.find_children("Route_*", "", true, false):
			var branch: TowerData = lane.get_meta(&"branch")
			var final: TowerData = family.final_of(branch)
			var texts: Array = lane.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)
			_check(final == null or (not lane.tooltip_text.contains(final.display_name) and not texts.any(func(t: String) -> bool: return t.contains(final.display_name))
				and lane.find_children("*", "TextureRect", true, false).size() == 1),
				"%s's lane hides its final (%s)" % [branch.display_name, texts])
	var picked: TowerData = shown.keys()[0]
	var card_ids: Array = shown[picked].duplicate()
	family.choose(picked)
	await process_frame
	var offer: Array = dreams.get_branch_offer(picked).duplicate()
	card_ids.sort()
	offer.sort()
	_check(offer == card_ids, "the picked family's offer (what Remember shows) is the card's: %s == %s" % [offer, card_ids])
	# The Codex Families page lists each family's branches from the data (meta_design.md 1f25e66e): Sporeling's 5
	# regular ones + the Grove's hidden one, "2 offered each run".
	var pause: Node = main.get_node("%PauseMenu")
	pause.open_codex(&"families")
	await process_frame
	var codex: Node = pause.codex
	codex._family = "sporeling"
	codex._build_families()
	var list: Node = codex.find_child("BranchList", true, false)
	var rows: Array = list.get_children().map(func(l: Label) -> String: return l.text) if list != null else []
	_check(rows.size() == 7 and String(rows[0]).contains("2 offered each run") and String(rows[-1]).contains("hidden branch"),
		"the Codex lists Sporeling's 5 branches + the hidden one, 2 offered each run (%s)" % [rows])
	pause.close()
	main.queue_free()
	await process_frame

	# The demo: its fixed branches, no silhouettes.
	main = await _new_run(1)
	family = main.get_node("%FamilyPickScreen")
	family.show_pick(&"first")
	await process_frame
	_check(family._cards.find_children("NotInDream", "", true, false).is_empty(), "demo: no 'not in this dream' row")
	for data: TowerData in _card_routes(family):
		_check(_card_routes(family)[data].size() == main.get_node("%DreamState").regular_branches(data).size(), "demo: %s shows its fixed branches" % data.display_name)
	main.queue_free()
	await process_frame
	ResultsScreen.demo_override = -1
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HeartwoodMemory.file_path))
	print("PASS" if failures == 0 else "FAILURES: %d" % failures)
	quit(failures)
