extends SceneTree

# Headless test for the Nurture rework (warden_stats.md "Nurture choices that fit every Warden", 02417f32;
# NurtureChoices): each Warden offers only the choices that do something for it; Kindred on aura supports works
# once; Swift speeds a Warden's main cycle (a Tangleroot's holds), Reach its main area (Hushbell's silence), Keen
# adds crit chance, Yield adds sprites, Deep lengthens pulls; Grandmother Oak can be nurtured; group Nurture only
# ranks Wardens that offer the choice; the choice text shows the real change. Run from the project folder:
#   godot --headless --path . --script res://tests/test_nurture_choices.gd --fixed-fps 60

const F := Tower.Focus

var failures := 0
var main: Node
var placer: TowerPlacer
var seller: TowerSeller
var container: Node
var map: Node
var _next_x := 2

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = 42
	root.add_child(main)
	await process_frame
	placer = main.get_node("%TowerPlacer")
	seller = main.get_node("%TowerSeller")
	container = main.get_node("%TowerContainer")
	map = main.get_node("%MapGenerator")
	main.get_node("%DreamState").unlock_everything = true
	await process_frame

	# The lists.
	_check(_plant("sprout").focus_options() == [F.POWER, F.SWIFT, F.REACH], "Sprout: Power · Swift · Reach")
	_check(not _plant("tangleroot").focus_options().has(F.POWER), "Tangleroot (control) has no Power")
	var moss := _plant("mossback")
	_check(moss.focus_options().has(F.KEEN) and not moss.focus_options().has(F.DEEP), "Mossback: Keen instead of Deep")
	_check(not _plant("pinwheel").focus_options().has(F.REACH), "Pinwheel (spinner) hides Reach")
	_check(_plant("brood_cap").focus_options().has(F.YIELD), "Brood Cap has Yield")
	_check(_plant("hushbell").focus_options() == [F.REACH, F.DEEP, F.POWER], "Hushbell: Reach · Deep · Power")
	_check(_plant("sporeling").focus_options() == [F.POWER, F.SWIFT, F.REACH, F.DEEP], "unlisted attackers keep the four")
	var oak := _plant("grandmother_oak")
	_check(oak.can_be_nurtured() and oak.focus_options() == [F.WIDE, F.STRONG, F.KINDRED], "Grandmother Oak gets the support set")

	# Kindred once on aura supports.
	var stump := _plant("elder_stump")
	stump.nurture(0, F.KINDRED)
	_check(stump.choice_count(F.KINDRED) == 1 and not stump.choice_available(F.KINDRED), "Elder Stump: Kindred works once")
	_check(stump.choice_blocker(F.KINDRED).begins_with("Already taken"), "…and says so (%s)" % stump.choice_blocker(F.KINDRED))
	stump.nurture(0, F.KINDRED)
	_check(stump.choice_count(F.KINDRED) == 1, "a second Kindred rank isn't taken (%s)" % [stump.rank_choices])

	# Swift speeds Tangleroot's hold cycle.
	var tangle := _plant("tangleroot", Vector2(16, 15))  # Away from the supports' auras
	tangle._ability_timer = 10.0
	tangle._update_ability(1.0)
	var plain := 10.0 - tangle._ability_timer
	var swift := _plant("tangleroot", Vector2(19, 15))
	for i in 3:
		swift.nurture(0, F.SWIFT)
	swift.clear_dream_cache()
	swift._ability_timer = 10.0
	swift._update_ability(1.0)
	_check(10.0 - swift._ability_timer > plain + 0.1, "Swift: the hold timer runs faster (%.2f vs %.2f s)" % [10.0 - swift._ability_timer, plain])
	_check(swift.focus_text(F.SWIFT).begins_with("holds every"), "Swift's line names the hold (%s)" % swift.focus_text(F.SWIFT))
	var picks := swift.rank_choices.duplicate()
	for which in [F.POWER, F.SWIFT, F.REACH, F.DEEP, F.KEEN]:
		swift.focus_text(which)
	_check(swift.rank_choices == picks and swift.rank == 3, "the choice lines never change the picks (%s)" % [swift.rank_choices])

	# Reach grows Hushbell's silence.
	var hush := _plant("hushbell")
	_check(hush.focus_text(F.REACH).begins_with("silence 2 → 2.3 cells"), "Reach's line: %s" % hush.focus_text(F.REACH))
	_check(hush.focus_text(F.REACH).contains("range 2.0 → 2.3"), "and the range it also grows")
	hush.nurture(0, F.REACH)
	_check(is_equal_approx(hush._main_area()[0], 2.3), "one Reach rank: silence 2.3 cells (%.2f)" % hush._main_area()[0])

	# Keen adds crit chance.
	var stone := _plant("pebbling")
	var before := stone.get_raw_crit_chance()
	stone.nurture(0, F.KEEN)
	stone.clear_dream_cache()
	_check(is_equal_approx(stone.get_raw_crit_chance() - before, NurtureChoices.KEEN_CRIT), "Keen: +%d%% crit (%.3f → %.3f)" % [roundi(NurtureChoices.KEEN_CRIT * 100), before, stone.get_raw_crit_chance()])

	# Yield on a Brood Cap (warden_stats.md 68120c18): +1 sprite alive per rank, and nothing else (Swift hatches faster).
	var brood := _plant("brood_cap", Vector2(16, 13))  # Away from the supports' auras
	var every_before := 1.0 / brood._compute_attacks_per_second()
	var alive_before := BranchKit.brood_max_alive(brood)
	_check(brood.focus_text(F.YIELD) == "sprites alive %d → %d" % [alive_before, alive_before + 1], "Yield's line: %s" % brood.focus_text(F.YIELD))
	brood.nurture(0, F.YIELD)
	brood.nurture(0, F.YIELD)
	_check(BranchKit.brood_max_alive(brood) == alive_before + 2, "two Yield ranks: two more sprites alive (%d)" % BranchKit.brood_max_alive(brood))
	_check(is_equal_approx(1.0 / brood._compute_attacks_per_second(), every_before), "and they don't hatch faster (that's Swift)")
	# Seedbearer: +1 Sprout alive per Yield rank too.
	var bearer := _plant("seedbearer", Vector2(18, 13))
	var sprouts := bearer.focus_text(F.YIELD)
	_check(sprouts.begins_with("Sprouts alive ") and sprouts.ends_with("→ %d" % (int(BranchKit.p(bearer, "seed_max", 3.0)) + 1)), "Seedbearer's Yield: %s" % sprouts)
	_check(stone.focus_text(F.KEEN).contains("crit damage"), "Keen's line names the crit damage (%s)" % stone.focus_text(F.KEEN))

	# Group Nurture: Power skips the control Warden.
	main.get_node("%RunState").add_dew(10000)
	var group: Array = [_plant("sporeling"), _plant("tangleroot")]
	var plan: Array = seller.plan_nurture(group, F.POWER)
	_check(plan[0].size() == 1 and plan[0][0].tower_data.get_id() == "sporeling", "group Power only ranks the Sporeling")

	print("nurture choices test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	main.queue_free()
	await process_frame
	quit(failures)

func _plant(id: String, at: Vector2 = Vector2(-1, -1)) -> Tower:
	var tower: Tower = placer.tower_scene.instantiate()
	tower.tower_data = load("res://resource/tower/%s.tres" % id)
	tower.cell = at if at.x >= 0 else Vector2(_next_x, 1)
	if at.x < 0:
		_next_x += 1
	tower.position = Tower.MAP_GRID.calculate_map_position(tower.cell)
	container.add_child(tower)
	tower.set_process(false)
	return tower

func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: " + what)
