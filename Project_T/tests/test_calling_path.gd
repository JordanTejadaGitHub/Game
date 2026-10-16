extends SceneTree
# Calling evolutions (scripts/combat/calling_paths.gd, DreamState.calling_path; owner 2026-10-16). Written 2026-10-16 and
# NOT RUN (the owner runs tests on request). The offers at the drift 5 / 25 / 50 / 75 rests, the pick, no reroll or skip,
# the save, and old saves that took class cards.
var failures := 0
var main: Node
var dreams: DreamState
const PATHS := preload("res://scripts/combat/calling_paths.gd")

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	dreams = main.get_node("%DreamState")

	# The table: 3 styles, 2 follow-ups each, a capstone under each follow-up
	var styles := PATHS.next_ids("sporeling", [])
	_check(styles.size() == 3, "Spore Print offers 3 styles (%d)" % styles.size())
	for style in styles:
		var follow := PATHS.children(style)
		_check(follow.size() == 2, "%s has 2 follow-ups" % style)
		for f in follow:
			_check(PATHS.children(f).size() == 1, "%s has 1 capstone" % f)
	for family in ["sporeling", "firefly_jar", "dewdrop", "bellflower"]:
		_check(PATHS.next_ids(family, []).size() == 3, "%s has 3 styles" % family)
	_check(PATHS.next_ids("sporeling", [&"sp_clump", &"sp_rot", &"sp_rotburst"]) == [&"sp_sticky"], "Drift 75: the style's other follow-up")
	_check(PATHS.stage_of(5) == 0 and PATHS.stage_of(75) == 3 and PATHS.stage_of(10) < 0, "Calling drifts are 5, 25, 50, 75")

	# The offer at the drift 5 rest replaces the Dream; at 25 it comes first and the Dream follows
	dreams.calling = "sporeling"
	var offer := dreams._calling_offer_for(5)
	_check(offer.size() == 3 and offer[0].tags.has("calling_evolution"), "Drift 5 offers the 3 styles as cards")
	_check(dreams._calling_offer_for(10).is_empty(), "No Calling offer at drift 10")
	dreams.current_offer = offer
	dreams.offering_calling = true
	_check(not dreams.can_skip() and not dreams.reroll(), "A Calling pick can't be passed or rerolled")
	var stacks_before := dreams.stacks.size()
	dreams.choose(offer[1])
	_check(dreams.calling_path == [StringName(offer[1].id)], "Choosing adds the style to the path")
	_check(dreams.stacks.size() == stacks_before, "An evolution is never taken as a card")
	_check(not dreams.offering_calling, "The Calling offer closed")
	_check(dreams.calling_path_text().begins_with("Spore Print → "), "The path reads 'Spore Print → …'")
	_check(dreams._calling_offer_for(25).size() == 2, "Drift 25 offers the style's 2 follow-ups")

	# The save keeps the path
	var saved: Dictionary = dreams.to_save()
	dreams.calling_path.clear()
	dreams.load_save(saved)
	_check(dreams.calling_path == [StringName(offer[1].id)], "The path survives a save")

	# An old save that took a Sporeling class card keeps it and never evolves
	dreams.calling_path.clear()
	dreams._calling_offered.clear()
	dreams.stacks["mushroom_bed"] = 1
	_check(dreams._calling_offer_for(25).is_empty(), "A run holding class cards never evolves")
	dreams.stacks.erase("mushroom_bed")

	print("test_calling_path: %d failures" % failures)
	quit(failures)
