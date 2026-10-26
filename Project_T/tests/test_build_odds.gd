extends SceneTree

# "Right build by drift N" offer test (card council 2026-10-22; D:\Projects\logs\dream_council\build_sheet.md / .json,
# reviews build_sheet_roguelite.md and build_sheet_td.md). For each of the 16 builds in res://tests/data/build_sheet.json
# it plays the Dream offers of many fresh-profile runs through the real DreamState (sim_rest / sim_family_pick) with a
# player chasing that build, and prints how often the build is complete by drift 25 / 50 / 75.
# Asserts structure only (drift 20 is the Calling style pick, the new family's lent slot, at most two family cards per
# offer, every counting card offered at least once); the percentages are printed, never banded.
#   godot --headless --fixed-fps 60 --path . --script res://tests/test_build_odds.gd [-- --runs=200 --finale | --finale-only --builds=a,b]
# Known biases: an empty board (no Wardens planted: board-gated and soft-Need generics in the other slots behave
# differently), forms never grown, no Reactions or discoveries seen.

# Second tier "optimal" (res://tests/data/optimal_tier.json, D:\Projects\logs\dream_council\optimal_tier.md): online plus a
# defining card, `needed` distinct counting cards (1 generic counts at most), the drift 45 follow-up in `follow_up` ([] =
# any); cross builds 3 second-family cards with a defining one + 2 of the start build's. The simulated player tries for it.
const SHEET_PATH := "res://tests/data/build_sheet.json"
const OPTIMAL_PATH := "res://tests/data/optimal_tier.json"
const TARGET := "council target (optimal, forced start family): 5-10% by 50, 15-25% by 75; no build above 35% or below 5% by 75"
const SUITE_RUNS := 20  # Runs per build in the suite (about 0.95 s a run: ~5 min in all; common seeds across builds); --runs=N for more
const FINALE_IN_SUITE := false  # The clean-finale Rare+ variant: off in the suite; --finale adds it, --finale-only runs only it
const DRIFTS := [10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75]  # Rests with a Dream (the Calling steps at 20 / 45 / 60 / 75 come with theirs)
const PICK_DRIFTS := [10, 40, 60]  # Family picks, before that rest's Dream
const STARTERS := ["sporeling", "firefly_jar", "dewdrop", "bellflower"]
const NEVER := 999

var failures := 0
var main: Node
var d: DreamState
var dd: DriftDirector
var map_gen: Node
var run_state: Node
var cards_by_id := {}
var generic_ids := {}
var profile_path := ""
var optimal := {}  # build id -> its optimal_tier.json entry

# Structure counters
var lent_checks := 0
var lent_missing := 0
var family_over := 0
var offers_total := 0
var offer_ms := 0.0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	profile_path = "user://test_build_odds_%d.json" % OS.get_process_id()
	HeartwoodMemory.file_path = profile_path  # Before main.tscn: never the real profile, Grove or dev settings
	var sheet := _load_sheet()
	if sheet.is_empty():
		_finish()
		return
	var runs := SUITE_RUNS
	var finale := FINALE_IN_SUITE
	var finale_only := false
	var only: Array = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--runs="):
			runs = maxi(int(arg.trim_prefix("--runs=")), 1)
		elif arg == "--finale":
			finale = true
		elif arg == "--finale-only":
			finale_only = true
		elif arg.begins_with("--builds="):
			only = arg.trim_prefix("--builds=").split(",")
	main = load("res://scenes/main.tscn").instantiate()
	map_gen = main.get_node("MapGenerator")
	map_gen.map_seed = 424242  # One map for every run (Heartwood's Reach reads its obstacles)
	root.add_child(main)
	await process_frame
	d = main.get_node("%DreamState")
	dd = main.get_node("%DriftDirector")
	run_state = main.get_node("%RunState")
	d.run_pool_forced = true
	_check_profile()
	for card in d.pool:
		cards_by_id[card.id] = card
	for id in sheet.get("generic_cards", []):
		generic_ids[String(id)] = true
	var builds: Array = sheet.builds
	var by_id := {}
	for b in builds:
		by_id[b.id] = b
	_check_ids(builds)
	_load_optimal(builds, by_id)
	print("build odds: %d runs per build, seeds 7919 * (run + 1), map seed 424242, fresh profile, run pool sampling on" % runs)
	print("  by 25 = Dreams 10..20, by 50 = Dreams 10..45, by 75 = Dreams 10..70; <=75 also counts the drift 75 Dream")
	print("  known bias: empty board (no real maze, no Wardens planted), forms never grown, no Reactions or discoveries")
	print("  real = forced x the real fresh first pick showing the start family (simulated per run, 2 of 4)")
	var started := Time.get_ticks_msec()
	var offered_anywhere := {}
	var rows: Array = []
	var variants: Array = [true] if finale_only else ([false, true] if finale else [false])
	for variant in variants:
		if variant:
			print("\n--- variant: clean-finale Rare+ slot before every non-boss Dream from 15 (an upper bound) ---")
		else:
			print("\n--- baseline: clean-finale Rare+ slot off ---")
		print("%-16s %6s %6s %6s %6s | %6s %6s | %8s %8s | %5s %6s %6s" % ["build", "by25", "by50", "by75", "<=75",
			"real50", "real75", "median", "med(ok)", "dead", "streak", "capout"])
		var vrows: Array = []
		for b in builds:
			if not only.is_empty() and not only.has(b.id):
				continue
			var result: Dictionary = await _measure(b, by_id, runs, variant)
			for id in result.offered_ids:
				offered_anywhere[id] = true
			_print_row(b, result, runs)
			vrows.append([b, result])
			if variant == variants[0]:
				rows.append([b, result])
		print("\n--- optimal tier (%s), same runs; online repeated for comparison ---" % ("finale variant" if variant else "baseline"))
		print(TARGET)
		print("  at25 = Dreams 10..25 (the follow-up comes at drift 45 since 2026-10-25) (optimal needs it, so 'by 25' is always 0); by50 / by75 / <=75 as online")
		print("  def50 / def75 = runs where a defining card was offered by 50 / by 75; fu ok = runs whose drift 45 follow-up qualifies")
		print("%-16s %6s %6s | %6s %6s %6s %6s | %6s %6s | %8s %8s | %5s %5s %5s | %s" % ["build", "on50", "on75", "at25",
			"by50", "by75", "<=75", "real50", "real75", "median", "med(ok)", "def50", "def75", "fu ok", "vs target by 75"])
		for row in vrows:
			_print_optimal(row[0], row[1])
	print("\n--- per card (%s): offered by 50 / offered by 75 / taken by 75, share of runs; * = core ---" % ("finale variant" if variants[0] else "baseline"))
	for row in rows:
		_print_cards(row[0], row[1], runs, by_id)
	for row in rows:
		var b: Dictionary = row[0]
		for id in _counting(b, by_id):
			_check(offered_anywhere.has(id), "%s: counting card %s offered at least once over all runs" % [b.id, id])
	_check(lent_missing == 0, "the new family's lent card is in the Dream after its pick when one can show (%d missing of %d)" % [lent_missing, lent_checks])
	_check(family_over == 0, "at most two family cards per offer (%d offers over)" % family_over)
	var seconds := (Time.get_ticks_msec() - started) / 1000.0
	print("\nstructure: lent slot %d/%d, offers with 3+ family cards %d of %d; %.1f ms per Dream; %.1f s in all" % [
		lent_checks - lent_missing, lent_checks, family_over, offers_total, offer_ms / maxi(offers_total, 1), seconds])
	_finish()

func _finish() -> void:
	if profile_path != "" and FileAccess.file_exists(profile_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(profile_path))
	print("build odds test: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(failures)

func _load_sheet() -> Dictionary:
	var text := FileAccess.get_file_as_string(SHEET_PATH)
	var data = JSON.parse_string(text)
	_check(data is Dictionary and data.has("builds"), "build sheet loads from %s" % SHEET_PATH)
	return data if data is Dictionary else {}

# The optimal tier per build, with structure checks: every build has an entry, defining cards are on its own list,
# follow-ups are children of its style, `needed` fits the list under the 1-generic cap.
func _load_optimal(builds: Array, by_id: Dictionary) -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(OPTIMAL_PATH))
	_check(data is Dictionary and data.has("optimal"), "optimal tier loads from %s" % OPTIMAL_PATH)
	if not data is Dictionary or not data.has("optimal"):
		return
	optimal = data.optimal
	for b in builds:
		_check(optimal.has(b.id), "%s: has an optimal tier entry" % b.id)
		if not optimal.has(b.id):
			continue
		var opt: Dictionary = optimal[b.id]
		_check(not opt.defining.is_empty(), "%s: optimal has a defining card" % b.id)
		for id in opt.defining:
			_check(b.cards.has(id), "%s: defining card %s is on the build's own list" % [b.id, id])
		var children: Array = DreamState.CALLING_PATHS.children(StringName(b.style)).map(func(s: StringName) -> String: return String(s))
		for id in opt.follow_up:
			_check(children.has(id), "%s: follow-up %s is a child of %s (%s)" % [b.id, id, b.style, children])
		var reach := 0
		var gen := 0
		for id in _counting(b, by_id):
			if generic_ids.has(id):
				gen += 1
			else:
				reach += 1
		reach += mini(gen, 1)
		_check(int(opt.needed) <= reach, "%s: optimal needs %d, the list reaches %d" % [b.id, int(opt.needed), reach])
		if b.get("second_family") != null:
			_check(int(opt.second_family_needed) <= b.cards.size(), "%s: second_family_needed fits" % b.id)

# Card steps still missing for the optimal tier (the follow-up and the online tier are checked in _optimal).
func _opt_deficit(b: Dictionary, by_id: Dictionary, opt: Dictionary, taken: Dictionary) -> int:
	var defining: Array = opt.defining
	var def_need := 0 if taken.keys().any(func(id: String) -> bool: return defining.has(id)) else 1
	var fam := 0
	var gen := 0
	var second := 0
	for id in taken:
		var on_list: bool = b.cards.has(id)
		var on_start: bool = b.get("start_from") != null and by_id[b.start_from].cards.has(id)
		if not on_list and not on_start:
			continue
		if generic_ids.has(id):
			gen += 1
		elif on_list and b.get("second_family") != null:
			second += 1
		else:
			fam += 1
	if b.get("second_family") != null:
		var second_need := maxi(int(opt.second_family_needed) - second, 0)
		var start_need := maxi(int(opt.needed) - int(opt.second_family_needed) - fam - mini(gen, 1), 0)
		return maxi(second_need, def_need) + start_need
	return maxi(maxi(int(opt.needed) - fam - mini(gen, 1), 0), def_need)

func _optimal(b: Dictionary, by_id: Dictionary, opt: Dictionary, taken: Dictionary) -> bool:
	if not _complete(b, by_id, taken) or d.calling_path.size() < 2:
		return false
	if not _follow_up_ok(opt):
		return false
	return _opt_deficit(b, by_id, opt, taken) == 0

func _follow_up_ok(opt: Dictionary) -> bool:
	if d.calling_path.size() < 2:
		return false
	var fu: Array = opt.follow_up
	return fu.is_empty() or fu.has(String(d.calling_path[1]))

# A fresh profile: the four starters, only the Bellflower start node's Grove cards, no dev run, no Blight.
func _check_profile() -> void:
	var screen = main.get_node("%FamilyPickScreen")
	var roster: Array = screen.families.map(func(t: TowerData) -> String: return t.get_id())
	roster.sort()
	var want := STARTERS.duplicate()
	want.sort()
	_check(roster == want, "the family roster is the four starters (%s)" % [roster])
	var grove := Array(d.grove_cards)
	grove.sort()
	print("grove cards on the temp profile: %s" % [grove])
	_check(grove.size() <= 4, "a fresh profile carries only the start nodes' Grove cards (%s)" % [grove])
	_check(d.fresh_grove_cards.is_empty(), "no freshly planted Grove cards")
	_check(MetaRun.blight_level == 0 and not d.lean_common and not d.allow_bittersweet, "no Blight, Lean Common or Bittersweet")
	_check(not MetaRun.is_dev_run(), "not a dev run (the real settings were not read)")
	_check(d.rerolls_left == 0 and d.banishes_left == 0, "no rerolls or banishes on a fresh profile")

func _check_ids(builds: Array) -> void:
	for b in builds:
		for key in ["cards", "core", "pair_cards", "grown_cards"]:
			for id in b.get(key, []):
				var card: UpgradeData = cards_by_id.get(id)
				_check(card != null and not card.retired, "%s: %s is a live card" % [b.id, id])
				if card != null:
					_check(generic_ids.has(id) == (not d.is_family_card(card)), "%s: %s generic flag matches the code" % [b.id, id])

# The ids that count for build `b` (cross builds: the second family's plus the start build's).
func _counting(b: Dictionary, by_id: Dictionary) -> Array:
	var out: Array = b.cards.duplicate()
	if b.get("start_from") != null:
		for id in by_id[b.start_from].cards:
			if not out.has(id):
				out.append(id)
	return out

# Steps still missing (0 = the cards are there; a cross build also needs its family held).
func _deficit(b: Dictionary, by_id: Dictionary, taken: Dictionary) -> int:
	if b.get("second_family") != null:
		var second := 0
		var start := 0
		for id in taken:
			if b.cards.has(id):
				second += 1
			elif by_id[b.start_from].cards.has(id):
				start += 1
		return maxi(int(b.needed_second) - second, 0) + maxi(int(b.needed_start) - start, 0)
	var fam := 0
	var gen := 0
	var core := false
	for id in taken:
		if not b.cards.has(id):
			continue
		if generic_ids.has(id):
			gen += 1
		else:
			fam += 1
		core = core or b.core.has(id)
	var need := maxi(int(b.needed) - fam - mini(gen, 1), 0)
	var core_need := 0 if (b.core.is_empty() or core) else 1
	return maxi(need, core_need)

func _complete(b: Dictionary, by_id: Dictionary, taken: Dictionary) -> bool:
	if b.get("second_family") != null and not d.is_unlocked(b.second_family):
		return false
	return _deficit(b, by_id, taken) == 0

func _reset_run(s: int) -> void:
	d.load_save({"unlocked": ["sprout", "thornwall"]})  # Clears stacks, run pool, passed-over, new family, calling, finale...
	d.grown_wardens.clear()
	d._built_this_run.clear()
	d._events_this_run.clear()
	d._profile_discovery.clear()
	d._calling_offered.clear()
	d._dream_first_shown.clear()
	d._pending_drifts.clear()
	d.current_offer.clear()
	d.offering_calling = false
	d.current_stray = null
	d.picks_left = 0
	d._taken_this_offer.clear()
	d._offer_drift = 0
	d._finale_rare_next = 0
	d.discovery_profile = {"seen": [], DreamState.WARDENS_BUILT_KEY: [], DreamState.BEST_CHAIN_KEY: 0, DreamState.EVENTS_KEY: []}
	run_state.free_clears = 0
	map_gen.map_seed = s  # Seeds the run pool's samples (the map itself stays)
	d._rng.seed = s
	seed(s)
	d.bump_board()

func _mark_built(root_id: String) -> void:
	d.grown_wardens[root_id] = true
	d._built_this_run[root_id] = true
	d.bump_board()

func _rarity_first(cards: Array, rng: RandomNumberGenerator) -> UpgradeData:
	var best: Array = []
	var top := -1
	for c in cards:
		if c.rarity > top:
			top = c.rarity
			best = [c]
		elif c.rarity == top:
			best.append(c)
	return best[rng.randi_range(0, best.size() - 1)]

func _any(cards: Array, rng: RandomNumberGenerator) -> UpgradeData:
	return cards[rng.randi_range(0, cards.size() - 1)]

func _measure(b: Dictionary, by_id: Dictionary, runs: int, finale: bool) -> Dictionary:
	var counting := _counting(b, by_id)
	var reported: Array = counting.duplicate()
	for id in b.get("pair_cards", []) + b.get("grown_cards", []):
		if not reported.has(id):
			reported.append(id)
	var firsts: Array = []
	var real_firsts: Array = []
	var offered50 := {}
	var offered75 := {}
	var taken75 := {}
	var dead := 0
	var dreams := 0
	var streak_sum := 0
	var cap_out := 0
	var offered_ids := {}
	var start: String = b.start_family
	var opt: Dictionary = optimal.get(b.id, {"defining": [], "needed": 0, "follow_up": [], "second_family_needed": 0})
	var opt_firsts: Array = []
	var opt_real: Array = []
	var def50 := 0
	var def75 := 0
	var fu_ok := 0
	for run in runs:
		var s := 7919 * (run + 1)
		var rng := RandomNumberGenerator.new()
		rng.seed = s + 17
		_reset_run(s)
		dd.drifts_started = 1
		# The real fresh first pick (2 of 4): only whether it shows the start family; the run then forces the start
		var shown: Array = []
		d.sim_family_pick(&"first", func(ids: Array) -> StringName: return _note_shown(shown, ids))
		d.unlocked[start] = true
		var other := ""
		for id in shown:
			if id != start:
				other = id
		if not shown.has(start) or other == "":
			var rest := STARTERS.filter(func(id: String) -> bool: return id != start)
			other = rest[rng.randi_range(0, rest.size() - 1)]
		d.note_family_pick([start, other], start)
		d.set_calling(start)
		_mark_built(start)
		_check(d._calling_offer_for(5).is_empty(), "%s: drift 5 has no Calling offer (owner playtest 2026-10-25: style at 20)" % b.id)
		var first := NEVER
		var opt_first := NEVER
		var seen_run := {}
		var seen50 := {}
		var streak := 0
		var longest := 0
		for drift in DRIFTS:
			dd.drifts_started = drift
			var got := &""
			if PICK_DRIFTS.has(drift):
				seed(s * 31 + drift)  # The pick's shuffle
				got = d.sim_family_pick(&"second", func(ids: Array) -> StringName: return _choose_family(b, ids, rng))
			if drift == 20:  # The Calling style pick, before that rest's Dream (owner playtest 2026-10-25: was drift 5)
				var styles: Array = d._calling_offer_for(20).map(func(c: UpgradeData) -> String: return c.id)
				_check(styles.size() == 3 and styles.has(b.style), "%s: drift 20 offers the Calling's three styles (%s)" % [b.id, styles])
				d.calling_path.append(StringName(b.style))
				d._calling_offered[20] = true
				d.bump_board()
			elif drift == 45 or drift == 60:  # The follow-up and the capstone come before the Dream
				_grow_calling(drift, rng, opt.follow_up)
			var boss := dd.is_boss_drift(drift)
			if finale and drift >= 15 and not boss:
				d._finale_rare_next = 1
			var act := dd.get_act(drift + 1 if boss else drift)
			var lent_possible := false
			if got != &"" and String(got) != d.calling:
				lent_possible = _lent_can_show(String(got), act)
			var info := {"first": true}
			var t0 := Time.get_ticks_usec()
			d.sim_rest(drift, _pick.bind(b, by_id, counting, rng, info, drift, act, String(got), lent_possible, opt))
			offer_ms += (Time.get_ticks_usec() - t0) / 1000.0
			offers_total += 1
			if drift == 75:  # The Dream comes first at the boss rest, then the Deepen / Cross over
				_grow_calling(drift, rng, opt.follow_up)
			if got != &"":
				_mark_built(String(got))  # Built only after its pick rest's Dream
			for id in info.get("counting_offered", []):
				seen_run[id] = true
				offered_ids[id] = true
				if drift < 50:
					seen50[id] = true
			for id in info.get("reported_offered", []):
				seen_run[id] = true
				if drift < 50:
					seen50[id] = true
			dreams += 1
			if info.get("dead", false):
				dead += 1
				streak += 1
				longest = maxi(longest, streak)
			else:
				streak = 0
			if info.get("cap_out", false):
				cap_out += 1
			if first == NEVER and _complete(b, by_id, _taken(counting)):
				first = drift
			if opt_first == NEVER and _optimal(b, by_id, opt, _taken(counting)):
				opt_first = drift
		await process_frame  # Let queued frees and deferred UI calls run: one frame of thousands of offers overflows the message queue
		streak_sum += longest
		firsts.append(first)
		opt_firsts.append(opt_first)
		opt_real.append(opt_first if shown.has(start) else NEVER)
		if opt.defining.any(func(id: String) -> bool: return seen50.has(id)):
			def50 += 1
		if opt.defining.any(func(id: String) -> bool: return seen_run.has(id)):
			def75 += 1
		if _follow_up_ok(opt):
			fu_ok += 1
		real_firsts.append(first if shown.has(start) else NEVER)
		for id in reported:
			if seen50.has(id):
				offered50[id] = int(offered50.get(id, 0)) + 1
			if seen_run.has(id):
				offered75[id] = int(offered75.get(id, 0)) + 1
			if d.card_stacks(id) > 0:
				taken75[id] = int(taken75.get(id, 0)) + 1
	return {"firsts": firsts, "real": real_firsts, "offered50": offered50, "offered75": offered75, "taken75": taken75,
		"dead": dead, "dreams": dreams, "streak": float(streak_sum) / runs, "cap_out": cap_out, "offered_ids": offered_ids,
		"reported": reported, "opt_firsts": opt_firsts, "opt_real": opt_real, "def50": 100.0 * def50 / runs,
		"def75": 100.0 * def75 / runs, "fu_ok": 100.0 * fu_ok / runs}

func _note_shown(shown: Array, ids: Array) -> StringName:
	shown.append_array(ids)
	return &""  # Take none here: the run forces the start family

func _choose_family(b: Dictionary, ids: Array, rng: RandomNumberGenerator) -> StringName:
	if b.get("second_family") != null and ids.has(b.second_family):
		return StringName(b.second_family)
	return StringName(ids[rng.randi_range(0, ids.size() - 1)])

# The drift 45 follow-up: one on the build's optimal list when offered (both children always are), else random.
# The random draw is made either way, so the rng stream matches the old player's.
func _grow_calling(drift: int, rng: RandomNumberGenerator, prefer: Array = []) -> void:
	var next: Array = DreamState.CALLING_PATHS.next_ids(d.calling, d.calling_path)
	if next.is_empty():
		return
	var pick: StringName = next[rng.randi_range(0, next.size() - 1)]
	if drift == 45 and not prefer.is_empty() and not prefer.has(String(pick)):
		for id in next:
			if prefer.has(String(id)):
				pick = id
				break
	d.calling_path.append(pick)
	d._calling_offered[drift] = true
	d.bump_board()

func _lent_can_show(family: String, act: int) -> bool:
	for card in d.pool:
		if card.calling == "" and card.tags.has(DreamState.LENT_TAG) and card.requires.has(family) and d._new_family_can_show(card, act):
			return true
	return false

func _taken(counting: Array) -> Dictionary:
	var out := {}
	for id in counting:
		if d.card_stacks(id) > 0:
			out[id] = true
	return out

# sim_rest's pick (bound): the offer comes first.
func _pick(offer: Array, b: Dictionary, by_id: Dictionary, counting: Array, rng: RandomNumberGenerator, info: Dictionary,
		drift: int, act: int, got: String, lent_possible: bool, opt: Dictionary) -> UpgradeData:
	if info.first:  # The offer as built (Lucid Dreaming calls again with what is left)
		info.first = false
		var ids: Array = offer.map(func(c: UpgradeData) -> String: return c.id)
		var fam := offer.filter(func(c: UpgradeData) -> bool: return d.is_family_card(c)).size()
		if fam > 2:
			family_over += 1
			printerr("  %s drift %d: %d family cards %s" % [b.id, drift, fam, ids])
		if lent_possible:
			lent_checks += 1
			var has_lent := offer.any(func(c: UpgradeData) -> bool: return c.tags.has(DreamState.LENT_TAG) and c.requires.has(got))
			if not has_lent:
				lent_missing += 1
				printerr("  %s drift %d: no %s lent card after its pick %s" % [b.id, drift, got, ids])
		info["counting_offered"] = ids.filter(func(id: String) -> bool: return counting.has(id))
		info["reported_offered"] = ids.filter(func(id: String) -> bool: return b.get("pair_cards", []).has(id) or b.get("grown_cards", []).has(id))
		info["dead"] = info.counting_offered.is_empty()
		# The family cap may have pushed a counting card out: 2 family cards and a non-family one shown, while a counting
		# family card that would still help was eligible and not shown.
		if fam == 2 and offer.size() > 2:
			var taken := _taken(counting)
			var before := _deficit(b, by_id, taken)
			for id in counting:
				var card: UpgradeData = cards_by_id.get(id)
				if card == null or ids.has(id) or taken.has(id) or not d.is_family_card(card) or not d.can_offer(card, act):
					continue
				var with := taken.duplicate()
				with[id] = true
				if _deficit(b, by_id, with) < before:
					info["cap_out"] = true
					break
	var taken_now := _taken(counting)
	var deficit := _deficit(b, by_id, taken_now)
	# Trying for optimal: a defining card first, then what the online tier still needs, then what the optimal tier
	# still needs, then other new counting cards, then stacks of held ones; rarest first in each, 1 counting generic.
	var opt_deficit := _opt_deficit(b, by_id, opt, taken_now)
	var defining: Array = []
	var useful: Array = []
	var opt_useful: Array = []
	var fresh: Array = []
	var restack: Array = []
	var generic_held := taken_now.keys().any(func(id: String) -> bool: return generic_ids.has(id))
	for c in offer:
		if not counting.has(c.id):
			continue
		var with := taken_now.duplicate()
		with[c.id] = true
		if opt.defining.has(c.id) and not taken_now.has(c.id):
			defining.append(c)
		elif _deficit(b, by_id, with) < deficit:
			useful.append(c)
		elif _opt_deficit(b, by_id, opt, with) < opt_deficit:
			opt_useful.append(c)
		elif generic_ids.has(c.id) and generic_held:
			continue
		elif not taken_now.has(c.id):
			fresh.append(c)
		else:
			restack.append(c)
	for group in [defining, useful, opt_useful, fresh, restack]:
		if not group.is_empty():
			return _rarity_first(group, rng)
	var plain := offer.filter(_plain_ok.bind(generic_held, counting))
	if not plain.is_empty():
		return _any(plain, rng)
	var rest := offer.filter(func(c: UpgradeData) -> bool: return c.id != "lucid_dream")
	return _any(rest, rng) if not rest.is_empty() else offer[0]

# A filler pick: not a family card, not Lucid Dreaming, never a second counting generic (the 1-generic cap).
func _plain_ok(c: UpgradeData, generic_held: bool, counting: Array) -> bool:
	if d.is_family_card(c) or c.id == "lucid_dream":
		return false
	return not (generic_held and generic_ids.has(c.id) and counting.has(c.id))

func _print_optimal(b: Dictionary, r: Dictionary) -> void:
	var by75 := _share(r.opt_firsts, 75)
	var verdict := "inside"
	if by75 > 35.0:
		verdict = "ABOVE 35% cap"
	elif by75 < 5.0:
		verdict = "BELOW 5% floor"
	elif by75 > 25.0:
		verdict = "above band"
	elif by75 < 15.0:
		verdict = "below band"
	var by50 := _share(r.opt_firsts, 50)
	var band50 := "in 5-10" if by50 >= 5.0 and by50 <= 10.0 else ("50 high" if by50 > 10.0 else "50 low")
	print("%-16s %5.1f%% %5.1f%% | %5.1f%% %5.1f%% %5.1f%% %5.1f%% | %5.1f%% %5.1f%% | %8s %8s | %4.0f%% %4.0f%% %4.0f%% | %s, %s" % [
		b.id, _share(r.firsts, 50), _share(r.firsts, 75), _share(r.opt_firsts, 26), by50, by75, _share(r.opt_firsts, 76),
		_share(r.opt_real, 50), _share(r.opt_real, 75), _median(r.opt_firsts, false), _median(r.opt_firsts, true),
		r.def50, r.def75, r.fu_ok, verdict, band50])

func _share(firsts: Array, before: int) -> float:
	var n := 0
	for f in firsts:
		if f < before:
			n += 1
	return 100.0 * n / maxi(firsts.size(), 1)

func _median(firsts: Array, completed_only: bool) -> String:
	var list: Array = firsts.filter(func(f: int) -> bool: return f != NEVER) if completed_only else firsts.duplicate()
	if list.is_empty():
		return "-"
	list.sort()
	var m: int = list[list.size() / 2]
	return ">75" if m == NEVER else str(m)

func _print_row(b: Dictionary, r: Dictionary, _runs: int) -> void:
	var gap := " (no core)" if b.get("second_family") == null and b.core.is_empty() else ""
	print("%-16s %5.1f%% %5.1f%% %5.1f%% %5.1f%% | %5.1f%% %5.1f%% | %8s %8s | %4.0f%% %6.1f %5.1f%%%s" % [b.id,
		_share(r.firsts, 25), _share(r.firsts, 50), _share(r.firsts, 75), _share(r.firsts, 76),
		_share(r.real, 50), _share(r.real, 75), _median(r.firsts, false), _median(r.firsts, true),
		100.0 * r.dead / maxi(r.dreams, 1), r.streak, 100.0 * r.cap_out / maxi(r.dreams, 1), gap])

func _print_cards(b: Dictionary, r: Dictionary, runs: int, _by_id: Dictionary) -> void:
	var parts: Array = []
	for id in r.reported:
		var tag := ""
		if b.core.has(id):
			tag = "*"
		elif b.get("pair_cards", []).has(id):
			tag = " (pair)"
		elif b.get("grown_cards", []).has(id):
			tag = " (needs a grown form)"
		elif b.get("start_from") != null and not b.cards.has(id):
			tag = " (start)"
		parts.append("%s%s %d/%d/%d" % [id, tag, roundi(100.0 * r.offered50.get(id, 0) / runs),
			roundi(100.0 * r.offered75.get(id, 0) / runs), roundi(100.0 * r.taken75.get(id, 0) / runs)])
	print("%-16s %s" % [b.id, ", ".join(parts)])

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + label)
