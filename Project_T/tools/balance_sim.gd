extends SceneTree

# Balance simulation runner (documentation/balance_simulation.md): a bot plays one whole run (drifts
# 1-100, fought for real, leaves and all) on the real game, buying everything from the Dew the run
# earns. Roguelite Code's DreamSimPolicy makes the Dream, family-pick and Dreamlight choices (Omens:
# Clear Skies); this runner owns the maze and spending bot and writes a CSV per run.
#
#   godot --headless --path . --script res://tools/balance_sim.gd --fixed-fps 60 -- --seed=1 \
#       [--profile=fresh] [--style=balanced] [--speed=8] [--last=100] [--out=user://balance_out]
#
# Output: <out>/<profile>_<style>_seed<N>.csv (one row per cleared drift) and a line appended to
# <out>/runs.csv (the run's summary; tools/balance_summary.gd turns those into the batch table and the
# pass/fail checks).
#
# Bot (shared rules, "Bot rules" in the spec): the planned maze grows with the run (attackers and
# Thornwalls); Thornwalls go where they add the most path, attackers where the most path is in range
# (plus what they add); then grow the Warden with the most path in range, then Nurture (per style).
# Spends at each rest and mid-drift whenever the next item is affordable; keeps nothing in reserve;
# never sells.

const NO_CELL := Vector2(-1, -1)
const SPEND_EVERY := 2.0  # Game seconds between mid-drift spending checks
const SAVE_REST_BONUSES := 6  # Saves up for a growth costing up to this many rest bonuses (finals with ranks: 300+)
const MAX_FAMILIES := 2  # Mixed styles build their first two families deep
const SPEND_DOWN_BEFORE := [25, 30]  # Rests before drifts 26 and 31: spend down to one rest bonus (grove10)
const MIXED_SPROUTS := 0.4  # Mixed: the share of attackers kept as Sprouts
const SAVER_DRIFTS := 5  # Saver: holds Dew at most this many drifts for a growth
const APPROACH_EVERY := 0.25  # Game seconds between closest-approach samples
const CLOSE_CALL := 0.85  # A drift where a nightmare got this far along the route
const COVER_HEARTWOOD_FROM := 18  # From this drift one attacker keeps the Heartwood in range (a boss that gets through stays there; humans cover it)
const LAST_STRETCH := 8  # Route tiles before the Heartwood a covering Warden should also reach
const AURA_WEIGHT := 2.0  # Aura placement: path tiles a Warden in (or under) an aura is worth (balance_simulation.md: path coverage still dominates)
const AURA_COUNT_MAX := 5  # …counting at most this many Wardens per cell (a bonus of up to 10 tiles; a cell covers ~8-20 path tiles)
const KIN_WEIGHT := 2.0  # Kinship placement: path tiles per unbonded kin of the same family within Kinships reach (at most AURA_COUNT_MAX)
const FENCE_WEIGHT := 3.0  # Jarlink growth: path tiles per route tile on the line to a partner jar 2-4 cells away (a Jarlink full, a Firefly Jar that can still become one half)
var _saving_for_final := false  # The cheapest open growth is a final form (saves longer for it)
const STYLES := {"balanced": 0, "wide": 1, "narrow": 2, "combo": 3, "sleep": 4, "sprout": 5, "grove": 3, "mixed": 6}  # DreamSimPolicy.Style; grove = the hand-written Grove player (Combo cards, --families); mixed = Style.MIXED
const COLUMNS := ["drift", "act", "seconds", "health_spawned", "damage", "leaks", "leaves_lost", "leaves_left",
	"dew_rest", "dew_other", "spent_plant", "spent_walls", "spent_grow", "spent_nurture", "banked",
	"attackers", "walls", "tier1", "tier2", "tier3", "tier4", "avg_rank", "route", "families", "cards",
	"dreamlight", "top_warden", "top_share", "asleep_share", "reaction_share", "crit_share", "restless", "trampled", "approach", "chain_share", "longest_chain", "combo_amount_share", "status_share", "hit_share", "combo_damage", "reaction_damage", "status_damage", "combo_share", "leaked_health"]

# Per style: [attacker room at drift 0, + per drift, cap], walls per attacker, nurture weight.
const STYLE_PLAN := {
	"balanced": {"room": [5, 1.0 / 3.0, 16], "walls": 1.0},  # 5 Sprouts: the opening rule (test_opening)
	"wide": {"room": [6, 0.5, 24], "walls": 2.0},
	"narrow": {"room": [4, 0.15, 8], "walls": 0.5},
	"combo": {"room": [5, 1.0 / 3.0, 16], "walls": 1.0},
	"sleep": {"room": [5, 1.0 / 3.0, 16], "walls": 1.0},
	# Mixed opening: a family plus about 40% Sprouts, Thornwall walls, Sprout cards (the policy's Sprout scores).
	"mixed": {"room": [5, 1.0 / 3.0, 16], "walls": 1.0},
	# Sprout spam (a build): Sprouts are the walls and the attackers, planted where they add the most path.
	"sprout": {"room": [8, 3.0, 150], "walls": 0.0, "plant": "sprout", "growth_weight": 1.5},
}

var map_seed := 1
var profile := "fresh"
var style := "balanced"
var speed := 8.0
var last_drift := 100
var out_dir := "user://balance_out"  # Outside res://: Godot would import the CSVs as translations
var start_cards: Array[String] = []
var forced_families: Array[String] = []
var hand_drifts := false  # --hand-drifts: the hand-made drift files instead of rolled ones (DriftDirector.random_drifts)
var save_mode := ""  # --save=spender (never saves up) or saver (holds Dew up to SAVER_DRIFTS drifts for a growth)
var omen_mode := ""  # --omens=face (every Omen, the lower-risk one) | clear | always | clean (DreamSimPolicy.omen_mode); default: no Omens drawn
var all_families := false  # --all-families: the developer "Unlock all families" run (MetaRun.force_all_families)
var favored: Array[String] = []  # --favor=many_hands,seedfall: these Dream cards score highest (a player's build)
var dream_mode := "balanced"  # --dreams=skip|random|balanced (dream_design.md "Dreams must matter")
var director_overrides := {}  # --director=act1_boss_health_multiplier=3.0 (repeatable): DriftDirector exports for tuning sweeps
var enemy_overrides := {}  # --enemy=id.field=value (repeatable): EnemyData fields for sweeps
var _keep: Array = []  # The edited EnemyData, held so the cache keeps them
var act1_boss := ""  # --boss=night_mare: act 1's boss forced (DriftDirector.preset_bosses); "" = the default draw
var aura_placement := true  # --no-aura: place and grow aura Wardens (Acorn, Elder Stump, Grove Heart, Moon Moth) by path only
var empty_loadout := false
var sidegrade := -1
var carry_pref := true  # --no-carry-pref: act 1 growth and Dreamlight don't prefer the carry branch (DreamState.is_carry), the bot before 2026-10-02
var fence_pref := true  # --no-fence-pref: Jarlink growth ignores where its arc would fall (the bot before 2026-10-02)
var half_pref := true  # --no-half-pref: full cells only on the half grid (the bot before 2026-10-04)
var pair_search := true  # --no-pair-search: the half-grid wall search weighs single walls only (greedy, the bot of 0596eb94)
const PAIR_FIRSTS := 40  # Pair lookahead: the best single walls tried as a pair's first
const PAIR_REACH := 2  # …and its second wall within this many halves of the first's footprint
const NUDGE_TOP := 3  # Half cells: the best full cells whose 8 half-offset nudges _build tries
var _top: Array = []  # [[score, cell], …] best first, from the last _best_cell
var _last_args: Array = []  # That call's reach, growth weight, cover_heart, data, route, walker cells
var half_spots := [0, 0, 0, 0, 0]  # Attackers weighed with half nudges, built at a half offset, refused there; walls planted by the half search, of them built as the first of a better pair
var route_open := -1  # Route length in full cells after the opening spend, and as drifts 24 / 45 start
var route_base := -1  # The empty map's route in full cells, before the opening spend (the corridor rule alone)
var old_growth := false  # --old-growth: DreamState's growth prices from before f9fd8526 (branch / final ×1.0, ranks 25/40/60/90/135), the A/B
var node_sets := []  # --set=%Node.prop=value (repeatable): an export on a scene-unique node, set after _ready (e.g. %TowerPlacer.copy_cost_step=0)
var start_at := 0  # --start-at=51|76 (balance_simulation.md "Acts 3–4 coverage"): skip to that rest with a typical holding (_synthetic_start), build there, play on
var start_dreamlight := -1  # --start-dreamlight=N: override the human-run mean (START_DREAMLIGHT)
var start_leaves := -1  # --start-leaves=N: override START_LEAVES
var start_dew := 0  # What _synthetic_start gave (start_dew column)
var start_dl := -1  # Dreamlight earned by the start (start_dreamlight column)
var from_save := ""  # --from-save=<run.json>: resume that RunSaver board (a copy in a scratch user:// file, never the original) and play on
var save_at: Array[int] = []  # --save-at=N (repeatable): after the bot's spending at the rest after drift N, write a RunSaver snapshot into --out
var _save_copy := ""
var resumed_at := -1  # The drift the resumed save was resting after (resumed_at column)
var _finals_first := false  # _grow prefers the highest tier (the --start-at build)
var extra_spend := ""  # --extra-spend=plant|grow|final|rank|none (balance_simulation.md a8c0365c "Plant vs grow vs rank"): at the resumed rest, X extra Dew spent only that way
var extra_dew := 0  # --extra-dew=X
var extra_spent := 0
var base_kind := ""  # The family base Warden most on the map at the start, and its copies (copy number N)
var copies_at_start := -1
var _grow_only_tier := 0  # _grow only into this tier (2 = a branch, 3 = a final); 0 = any
var path_added := {"plant": [0, 0], "wall": [0, 0]}  # Route cells added by the bot's placements: [sum, placements]
const START_ATTACKERS := {51: 50, 76: 46}  # Human run history (non-dev runs, 2026-10-05): mean "attackers" of runs that ended at 50 (42, 75, 46, 38); at 75, the three runs past it prorated by drift (31@80, 58@100, 88@100)
const START_PLANT_SHARE := 0.25  # (a) at most this share of the start Dew on planting + walls
const START_GROW_SHARE := 0.52  # (b) growth up to about the human share by 50; (c) ranks take the rest
var start_counts := ""  # start_build column: attackers / walls planted, Dew on plant / grow / rank
const START_DREAMLIGHT := {51: 9, 76: 20}  # Mean Dreamlight earned by that drift in the human run history (non-dev runs, 2026-10-05; runs past it prorated by drift)
const START_LEAVES := {51: 10, 76: 8}  # Of 15 (Balancing 584f9521)
const START_POT_SHARE := 0.9  # Share of each skipped drift's Dew pot a typical player catches
var grow_count := 0  # Growth purchases (balance_simulation.md growth costs A/B): all, and as drift 25 starts
var grows_25 := -1
var first_grow := -1  # The drift of the first growth into a tier 2+ form
var route_at := {}
var narrow_at := {}  # Route halves in a one-half corridor (both opposite neighbours blocked), as drifts 24 / 45 start
var demo_run := false  # --demo: game/demo stays true (DEMO_RULES, demo bosses and Kinships), for the demo sanity check
var kin_placement := true  # --no-kin: no Kinship placement, and growth takes the first open form in evolves_to (the old bot)
var focus_mode := ""  # --focus=deep: Nurture picks Deep where it's offered and Potency cards score high (a committed Deep build)
var kin_pairs := {}  # Drift -> Kinships on the map as it starts (kin_pairs_24 / kin_pairs_50 columns: as drifts 25 / 51 start)
var dream_share := {}  # Drift -> the share of the maze's damage per second that the taken Dreams add (20, 25, 50, 75)
var dreams_20 := ""  # The Dreams taken by drift 20 ("a+b")
var omens: OmenDirector
var omens_faced: Array[String] = []
var gifts_log: Array[String] = []  # Heartwood's Gifts at each act break: "<drift>:<id>" or "<drift>:pass" (gifts column)
var dreamlight_by_source := {}  # DreamState.dreamlight_earned totals per source (omen_dreamlight column)
var omen_pot_dew := 0.0  # Dew the active Omen's pot multiplier added (or took) vs the unmodified pot, assuming the whole pot is dispelled
var omen_by_act := {}  # Act -> {dew, pot, share, lost, paid}: Omen rewards by the act their rest falls in (the rest after drift 25 is act 1)
var _omen_seen := {"dew": 0, "share": 0.0, "leaves_lost": 0, "paid": 0}  # OmenDirector.stats already put in an act
var omen_blocks: Array[String] = []  # Per paid Omen: "id:reward Dew:pot part:plain pot:leaves lost" (omen_blocks column)
var _block_pot := Vector2.ZERO  # The current Omen block's pot part (x) and its plain pot (y)
var _save_since := -1  # The drift the saver started holding Dew at
var _approach_timer := 0.0
var bosses := {}  # Instance id -> a boss fight: drift, kind, health, route and Heartwood seconds and damage (bosses column)
var dream_offers := {"offers": 0, "pool": 0, "pool_5": -1, "cards": 0, "matched": 0, "generic": 0, "off": 0}  # Dream pool / build relevance (dream_* columns)
var dream_off_ids := {}  # Off-build card id -> times offered (dream_off_ids column)
const CARD_LINES := ["spore", "water", "wind", "song", "acorn", "wing", "root", "light", "stone", "wall"]  # Warden lines a card tag can name (the 9 families + Thornwall)
var wardens_24 := ""  # The Wardens on the map as drift 25 starts ("id:n+…", wardens_24 column)
var auras_24 := -1  # Attackers under at least one aura Warden as drift 25 starts (auras_24 column)
var heart_cover_24 := -1  # Attackers with the Heartwood cell in range as drift 25 starts (heart_cover_24 column)
var damage_by_tag := {}  # Damage tag (or kind for plain hits) -> soothe dealt over the run (dmg_tags column)
var damage_by_form := {}  # Warden form id -> {total, hit, cloud, status, combo, asleep} over the run (forms column)
var run_parts := {"damage_total": 0.0, "combo_damage": 0.0, "reaction_damage": 0.0, "status_damage": 0.0}  # RunHistory's run totals
var status_samples := {}  # Status id -> {"n", "cap", "strengths": []}: every active status on every nightmare, 4x per game second (status_* columns)

var main: Node
var map
var placer: TowerPlacer
var dreams: DreamState
var run_state: RunState
var director: DriftDirector
var spawner
var container: Node
var policy
var reaction_tags := {}

var game_time := 0.0
var _spend_timer := 0.0
var _busy := false  # A family pick / rest is being handled
var rows: Array = []
var d := {}  # The current drift window's counters
var run := {"sprout_cards_25": -1, "first_leak": 0, "boss_drained": 0, "lost_by": {25: -1, 50: -1, 75: -1}, "banked_at_act": {}, "rest_banked": [],
	"rest_bonus": [], "top_wardens": {}, "max_top_share": 0.0, "max_top_warden": "", "max_asleep": 0.0}
var _last_dew := 0
var _spent_now := 0
const SPROUT_CARDS := ["seedfall", "sprout_surge", "sprout_chorus", "root_network", "root_network_ii", "seedling_gift", "nursery"]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		var value := arg.get_slice("=", 1)
		match arg.get_slice("=", 0):
			"--seed": map_seed = int(value)
			"--profile": profile = value
			"--style": style = value
			"--speed": speed = float(value)
			"--last": last_drift = int(value)
			"--out": out_dir = value if value != "" else out_dir  # An empty --out keeps the default (it wrote into the project root)
			"--card": start_cards.append(value)  # e.g. --card=seedfall: taken at the start of the run
			"--families": forced_families.assign(value.split(","))  # e.g. firefly_jar,dewdrop: the family picks, in order; later picks take none
			"--hand-drifts": hand_drifts = true
			"--save": save_mode = value
			"--omens": omen_mode = value
			"--all-families": all_families = true
			"--demo": demo_run = true
			"--no-carry-pref": carry_pref = false
			"--no-fence-pref": fence_pref = false
			"--no-half-pref": half_pref = false
			"--no-pair-search": pair_search = false
			"--old-growth": old_growth = true
			"--set": node_sets.append(arg.substr(arg.find("=") + 1))
			"--start-at": start_at = int(value)
			"--start-dreamlight": start_dreamlight = int(value)
			"--start-leaves": start_leaves = int(value)
			"--from-save": from_save = arg.substr(arg.find("=") + 1)
			"--save-at": save_at.append(int(value))
			"--extra-spend": extra_spend = value
			"--extra-dew": extra_dew = int(value)
			"--favor": favored.assign(value.split(","))
			"--dreams": dream_mode = value
			"--boss": act1_boss = value
			"--boss-draw": BossPool.force_draw = true  # The real per-seed boss draw (sims otherwise meet the defaults, like tests)
			"--loadout": empty_loadout = value == "none"  # --loadout=none: the profile carries no perks (the Grove cap A/B)
			"--sidegrade": sidegrade = int(value)  # MetaRun.force_sidegrade (Spire branch): 0 Power perks, 1 Sidegrades
			"--no-aura": aura_placement = false
			"--no-kin": kin_placement = false
			"--focus": focus_mode = value
			"--no-status-potency": Tower.status_potency_on = false  # The old status rules (87fb47fb A/B)
			"--no-falloff": Reactions.chain_falloff_on = false  # Measure without chain falloff
			"--director":
				var setting := arg.substr(arg.find("=") + 1)
				director_overrides[setting.get_slice("=", 0)] = float(setting.get_slice("=", 1))
			"--enemy":  # --enemy=night_mare.lap_leaves=4 (repeatable): an EnemyData field for this run (the loaded resource)
				var setting := arg.substr(arg.find("=") + 1)
				var target := setting.get_slice("=", 0)
				var data: EnemyData = load("res://resource/enemy/%s.tres" % target.get_slice(".", 0))
				var field := target.get_slice(".", 1)
				var current: Variant = data.get(field) if data else null
				if current == null:
					printerr("--enemy: no field %s" % target)
					quit(1)
					return
				data.set(field, int(setting.get_slice("=", 1)) if current is int else float(setting.get_slice("=", 1)))
				enemy_overrides[target] = setting.get_slice("=", 1)
				_keep.append(data)
	ProjectSettings.set_setting("game/demo", demo_run)  # Sims are the full game unless --demo, fresh too (it was the demo before 2026-10-02: fixed act 1-2 bosses, demo Kinships)
	if profile != "fresh":
		var meta: Script = load("res://scripts/meta/meta_run.gd")
		if not meta.get_script_method_list().any(func(m: Dictionary) -> bool: return m.name == "load_preset"):
			printerr("profile %s needs MetaRun.load_preset (Meta Game Code's presets)" % profile)
			quit(1)
			return
		var presets: Script = load("res://scripts/meta/grove_presets.gd")
		if presets.get("file_path") != null:  # A profile per process: parallel sims with different loadouts must not share one file
			presets.set("file_path", "user://sim_heartwood_%d.json" % OS.get_process_id())
		meta.call("load_preset", StringName(profile))
		if empty_loadout:  # Same Grove, nothing carried
			var data: Dictionary = HeartwoodMemory.load_data()
			data["loadout"] = []
			HeartwoodMemory.save_data(data)
	if sidegrade >= 0:
		load("res://scripts/meta/meta_run.gd").set("force_sidegrade", sidegrade)  # Only on builds that have it (the Spire branch)
	if all_families:
		load("res://scripts/meta/meta_run.gd").set("force_all_families", true)
	if from_save != "":
		# A copy in a scratch user:// file (per process): the original is only read, and RunSaver never writes here
		# (autosave is off outside the real game). RunSaver._ready restores the map seed, Blight and bosses from it.
		if not FileAccess.file_exists(from_save):
			printerr("--from-save: no file %s" % from_save)
			quit(1)
			return
		_save_copy = "user://sim_run_%d.json" % OS.get_process_id()
		var copy := FileAccess.open(_save_copy, FileAccess.WRITE)
		copy.store_string(FileAccess.get_file_as_string(from_save))
		copy.close()
		RunSaver.file_path = _save_copy
		RunSaver.resume_next = true
	main = load("res://scenes/main.tscn").instantiate()
	main.get_node("%MapGenerator").map_seed = map_seed
	if hand_drifts:
		main.get_node("%DriftDirector").set("random_drifts", false)
	if act1_boss != "":
		main.get_node("%DriftDirector").preset_bosses = [act1_boss]
	for key in director_overrides:
		main.get_node("%DriftDirector").set(key, director_overrides[key])
	root.add_child(main)
	await process_frame
	if from_save != "":
		await process_frame  # RunSaver._restore is deferred
		RunSaver.file_path = RunSaver.PATH
		resumed_at = main.get_node("%DriftDirector").drifts_started
		if resumed_at <= 0:
			printerr("--from-save: the save didn't restore (wrong version or unreadable): %s" % from_save)
			quit(1)
			return
	map = main.get_node("%MapGenerator")
	placer = main.get_node("%TowerPlacer")
	dreams = main.get_node("%DreamState")
	if old_growth:  # Set after _ready (it resets the statics from its exports); the setters write them
		for key in ["branch_cost_multiplier", "final_cost_multiplier", "ascended_cost_multiplier"]:
			if dreams.get(key) == null:
				printerr("--old-growth: DreamState has no %s" % key)
				quit(1)
				return
			dreams.set(key, 1.0)
		var old_ranks: Array[int] = [25, 40, 60, 90, 135]
		dreams.set("rank_costs", old_ranks)
	for s in node_sets:  # --set: after _ready, like --old-growth
		var target: String = s.get_slice("=", 0)
		var node := main.get_node_or_null(target.get_slice(".", 0))
		var prop := target.get_slice(".", 1)
		if node == null or node.get(prop) == null:
			printerr("--set: no %s" % target)
			quit(1)
			return
		var raw: String = s.get_slice("=", 1)
		node.set(prop, int(raw) if node.get(prop) is int else float(raw))
	dreams.dreamlight_earned.connect(func(amount: int, source: StringName) -> void: dreamlight_by_source[source] = dreamlight_by_source.get(source, 0) + amount)
	run_state = main.get_node("%RunState")
	director = main.get_node("%DriftDirector")
	spawner = main.get_node("%EnemyContainer")
	container = main.get_node("%TowerContainer")
	dreams._rng.seed = map_seed
	for card in dreams.pool:
		if start_cards.has(card.id):
			dreams.take(card)
	policy = FavorPolicy.new(dreams, STYLES.get(style, 0))
	policy.favored = favored
	policy.on_offer = _note_offer
	policy.on_pick = _log_pick
	policy.branches_first = kin_placement
	policy.carry_first = carry_pref
	policy.deep = focus_mode == "deep"
	policy.mode = dream_mode
	policy.rng.seed = map_seed
	omens = main.get_node_or_null("%OmenDirector")
	if _facing() and omens:
		policy.face_omens = omen_mode == "face"
		policy.omen_mode = "" if omen_mode == "face" else omen_mode  # clear / always / clean (DreamSimPolicy.pick_omen)
		omens.mode_override = "ask"
		director.drift_started.connect(_note_omen_pot)
		omens.omen_rewarded.connect(func(omen, _summary) -> void: _on_omen_rewarded(omen))
	for r in Reactions.all() + Reactions.crowned():
		reaction_tags[r.id] = true
	_take_over_choices()
	director.set_auto_drift(true)  # Drifts in a block flow (the HUD applies the player's own default)
	_hook_stats()
	_new_window()
	_last_dew = run_state.dew
	route_base = _route_cells(map.get_path_from(map.startPath))
	if start_at > 1:
		_synthetic_start()
	if extra_spend != "":
		_extra_spend()  # Instead of the opening spend: every arm (the control too) keeps the saved board as it was
	else:
		_spend()  # The opening (with --start-at: the whole board, built in that one rest)
	route_open = _route_cells(map.get_path_from(map.startPath))
	Engine.time_scale = speed
	var frames := 0
	# Effects in lite mode and no hitstops (they slow time); nothing else may change the sim's speed.
	Fx._settings = {"hitstop": false, "reduce_flashes": true, "reduced_motion": true}
	Fx._settings_at = Time.get_ticks_msec() + 3600000 * 24
	while not run_state.is_over and director.drifts_cleared < last_drift and frames < 60 * 60 * 60 * 3:
		paused = false
		Engine.time_scale = speed
		if not _busy and director.is_resting() and not director.awaiting_family_pick:
			director.start_next_block()
		await process_frame
		frames += 1
		game_time += speed / 60.0
		_spend_timer -= speed / 60.0
		_approach_timer -= speed / 60.0
		if _approach_timer <= 0.0:
			_approach_timer = APPROACH_EVERY
			_sample_approach()
		if director.drifts_started >= 25 and wardens_24 == "":
			wardens_24 = _warden_counts()
			auras_24 = _attackers().filter(func(t: Tower) -> bool: return _covered_by_aura(t)).size()
			heart_cover_24 = _attackers().filter(func(t: Tower) -> bool: return t.cell.distance_to(map.endPath) <= t.get_range_cells()).size()
		if director.drifts_started >= 25 and grows_25 < 0:
			grows_25 = grow_count
		for mark in [24, 45]:
			if director.drifts_started >= mark and not route_at.has(mark):
				route_at[mark] = _route_cells(map.get_path_from(map.startPath))
				narrow_at[mark] = _narrow_halves()
		for mark in [25, 51]:
			if director.drifts_started >= mark and not kin_pairs.has(mark):
				kin_pairs[mark] = Kinships.count_on_map(main)
		if director.drifts_started in [20, 25, 35, 50, 75] and not dream_share.has(director.drifts_started):
			dream_share[director.drifts_started] = _dream_share()
			if director.drifts_started == 20:
				dreams_20 = "+".join(dreams._taken_cards().map(func(c: UpgradeData) -> String: return c.id))
		if _spend_timer <= 0.0 and not _busy:
			_spend_timer = SPEND_EVERY
			_spend()
	Engine.time_scale = 1.0
	_finish()
	if profile != "fresh" and ResourceLoader.exists("res://scripts/meta/grove_presets.gd"):
		load("res://scripts/meta/grove_presets.gd").call("unload")  # Back to the real profile path
		var sim_profile := ProjectSettings.globalize_path("user://sim_heartwood_%d.json" % OS.get_process_id())
		for path in [sim_profile, sim_profile + ".bak"]:  # save_data keeps a .bak of the last write
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(path)
	if _save_copy != "" and FileAccess.file_exists(_save_copy):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_save_copy))  # --from-save's scratch copy
	quit(0)

# The real rest and family pick open screens and offers; the bot answers them through the policy
# instead (DreamSimPolicy wraps sim_rest / sim_family_pick, which do the rest rules and Dreamlight).
func _take_over_choices() -> void:
	for c in director.rest_started.get_connections():
		var target: Object = c.callable.get_object()
		if target == dreams or (target is OmenDirector and not _facing()):  # Facing: it draws and pays Omens
			director.rest_started.disconnect(c.callable)
	for c in director.family_pick_requested.get_connections():
		var target: Object = c.callable.get_object()
		if target == dreams or (target is Node and target.name == "FamilyPickScreen"):
			director.family_pick_requested.disconnect(c.callable)
	director.rest_started.connect(func(_block: int, _boss: bool, bonus: int, perfect: bool) -> void:
		d.dew_rest += bonus
		_on_rest.call_deferred(perfect))
	director.family_pick_requested.connect(func(kind: StringName) -> void: _on_family_pick.call_deferred(kind))

func _on_family_pick(kind: StringName) -> void:
	_busy = true
	if forced_families.is_empty():
		policy.family_pick(kind)
	else:
		_forced_family_pick(kind)
	paused = false
	director.family_picked()
	_busy = false

# Heartwood's Gifts (act breaks, main since bebfb22c): the bot takes the first gift that needs no placing on the map,
# else lets them pass for the Dew. Without an answer the next drift never starts (pending_choice() == &"gift").
func _answer_gifts(n: int) -> void:
	var gifts := main.get_tree().get_first_node_in_group(&"heartwood_gifts")
	if gifts == null or not gifts.is_offering():
		return
	for id in gifts.current_offer:
		if not gifts.needs_placing(id):
			gifts.choose(id)
			gifts_log.append("%d:%s" % [n, id])
			return
	gifts.let_pass()
	gifts_log.append("%d:pass" % n)

func _on_rest(perfect: bool) -> void:
	_busy = true
	var n := director.drifts_started
	policy.rest(n, perfect)
	_answer_gifts(n)
	if _facing() and omens and not omens.current_offer.is_empty():
		omens._offer_waiting = false  # The bot answers instead of the screen
		var omen: OmenData = policy.pick_omen(omens.current_offer)
		omens.choose(omen)
		if omen:
			omens_faced.append("%d:%s" % [n + 1, omen.id])
	paused = false
	var bonus := director.get_rest_bonus(director.get_block(n))
	run.rest_banked.append(run_state.dew)
	run.rest_bonus.append(bonus)
	if n % director.drifts_per_act == 0:
		run.banked_at_act[n / director.drifts_per_act + 1] = run_state.dew
	_spend()
	if save_at.has(n):
		_write_snapshot(n)
	_busy = false

# --save-at: the board as it stands after this rest's spending, as a RunSaver run.json (for --from-save and the
# snapshot library). Written into --out; RunSaver's own path is put back right away.
func _write_snapshot(n: int) -> void:
	var saver: Node = main.get_node_or_null("%RunSaver")
	if saver == null:
		return
	var dest := out_dir.path_join("snapshot_%s_%s_seed%d_d%d.json" % [profile, style, map_seed, n])
	var old_path: String = RunSaver.file_path
	RunSaver.file_path = dest
	var ok: bool = saver.save_now()
	RunSaver.file_path = old_path
	print("SNAPSHOT %s %s" % ["written" if ok else "refused (a choice is open)", dest])

# --- Spending ------------------------------------------------------------------------------------------

# --start-at (balance_simulation.md 584f9521 "Acts 3–4 coverage"): the run as a typical player would hold it at the rest
# before `start_at`. Walks the skipped drifts with the director's counters set to each: the first family pick, a Dream
# offer per rest by the bot's normal logic (boss rests Rare+: make_offer), the boss family picks; Dew = what the run
# already has (starting Dew, Grove) + each skipped drift's pot × its multiplier × START_POT_SHARE + each base rest bonus;
# Dreamlight topped up to the human-run mean; leaves set to START_LEAVES. The opening _spend() then builds the board.
func _synthetic_start() -> void:
	var rest_drift := start_at - 1
	if rest_drift % director.drifts_per_block != 0 or rest_drift >= director.get_total_drifts():
		printerr("--start-at=%d: must be one past a rest (51, 76, …)" % start_at)
		quit(1)
		return
	var dew := float(run_state.dew)
	for r in range(1, start_at):
		director.drifts_started = r
		director.drifts_cleared = r
		if r == 1:
			_pick_family_now(&"first")
		dew += director.get_dew_pot(r) * director.get_dew_pot_multiplier(r, false, false) * START_POT_SHARE
		if r % director.drifts_per_block == 0:
			if director.is_boss_drift(r):
				_pick_family_now(&"boss")
			dew += director.get_rest_bonus(director.get_block(r))
			policy.rest(r, true)
	director.blocks_rested = rest_drift / director.drifts_per_block
	var target: int = start_dreamlight if start_dreamlight >= 0 else int(START_DREAMLIGHT.get(start_at, 0))
	var earned := 0
	for amount in dreamlight_by_source.values():
		earned += int(amount)
	if target > earned:
		dreams.add_dreamlight(target - earned, &"start_at")
	start_dl = maxi(target, earned)
	policy.spend_dreamlight()
	run_state.dew = roundi(dew)
	start_dew = run_state.dew
	run_state.leaves = mini(start_leaves if start_leaves >= 0 else int(START_LEAVES.get(start_at, run_state.max_leaves)), run_state.max_leaves)
	director.act_started.emit(director.get_act(start_at), 0)  # The act's look (Seasons) and HUD
	_late_build()

# The --start-at board (Balancing, after the first arms: the bot's room cap built 16-26 attackers where people field
# 42-88): (a) plant up to START_ATTACKERS, walls in the style's proportion, on at most START_PLANT_SHARE of the Dew;
# (b) grow, finals first, up to START_GROW_SHARE; (c) Nurture with the rest. Live prices (copy cost included).
func _late_build() -> void:
	var dew0 := float(run_state.dew)
	var plan: Dictionary = STYLE_PLAN.get(style, STYLE_PLAN.balanced)
	var target := int(START_ATTACKERS.get(start_at, 0))
	var plant_cap := dew0 * START_PLANT_SHARE
	var spent := {"plant": 0.0, "grow": 0.0, "rank": 0.0}
	var walls_planted := 0
	for guard in 400:
		if _attackers().size() >= target or spent.plant >= plant_cap:
			break
		var before := run_state.dew
		var planted := _plant_attacker()
		spent.plant += before - run_state.dew
		while _walls().size() < int(_attackers().size() * float(plan.walls)) and spent.plant < plant_cap:
			var before_wall := run_state.dew
			if not _plant_wall():
				break
			walls_planted += 1
			spent.plant += before_wall - run_state.dew
		if not planted:
			break
	_finals_first = true
	for guard in 400:
		if spent.grow >= dew0 * START_GROW_SHARE:
			break
		var before := run_state.dew
		if not _grow():
			break
		spent.grow += before - run_state.dew
	_finals_first = false
	for guard in 800:
		var before := run_state.dew
		if not _nurture():
			break
		spent.rank += before - run_state.dew
	start_counts = "attackers %d of %d, walls %d (+%d planted), Dew plant %d / grow %d / rank %d of %d" % [_attackers().size(), target,
		_walls().size(), walls_planted, roundi(spent.plant), roundi(spent.grow), roundi(spent.rank), roundi(dew0)]
	print("START BUILD " + start_counts)

# --extra-spend (balance_simulation.md a8c0365c "Plant vs grow vs rank"), at the rest a --from-save run resumes on:
# `extra_dew` more Dew spent only one way, the unspent part taken back, then normal play. plant = copies of the
# family base most on the map; grow = one base → branch; final = one branch → final; rank = Nurture on the bot's
# usual targets; none = the control.
func _extra_spend() -> void:
	var counts := {}
	for t in _attackers():
		var d: TowerData = t.tower_data
		if d.tier == 1 and d.buildable_directly and d.get_id() != "sprout" and dreams.family_of(d.get_id()) != "":
			counts[d.get_id()] = int(counts.get(d.get_id(), 0)) + 1
	for id in counts:
		if base_kind == "" or counts[id] > counts[base_kind]:
			base_kind = id
	copies_at_start = int(counts.get(base_kind, 0))
	var before := run_state.dew
	run_state.dew += extra_dew
	match extra_spend:
		"plant":
			var base: TowerData = load("res://resource/tower/%s.tres" % base_kind) if base_kind != "" else null
			for guard in 200:
				if base == null or run_state.dew - before <= 0 or not run_state.can_afford(placer.get_cost(base)):
					break
				var cell := _best_cell(base.attack_range, 0.5, false, base)
				if cell == NO_CELL or not _build(base, cell):
					break
		"grow", "final":
			_grow_only_tier = 2 if extra_spend == "grow" else 3
			_grow()
			_grow_only_tier = 0
		"rank":
			for guard in 200:
				if run_state.dew - before <= 0 or not _nurture():
					break
	extra_spent = before + extra_dew - run_state.dew
	run_state.dew = mini(run_state.dew, before)  # The unspent extra goes back
	print("EXTRA %s: %d of %d spent (base %s ×%d)" % [extra_spend, extra_spent, extra_dew, base_kind, copies_at_start])

func _pick_family_now(kind: StringName) -> void:
	if forced_families.is_empty():
		policy.family_pick(kind)
	else:
		_forced_family_pick(kind)

func _spend() -> void:
	for guard in 60:
		var dew := run_state.dew
		var kind := _next_buy()
		if kind == "":
			return
		_spent_now = dew - run_state.dew
		d["spent_" + kind] += maxi(_spent_now, 0)
		if kind == "grow":
			grow_count += 1
			if first_grow < 0 and _attackers().any(func(t: Tower) -> bool: return t.tower_data.tier >= 2):
				first_grow = maxi(director.drifts_started, 0)

# One purchase by the plan's order; returns what it bought ("plant", "walls", "grow", "nurture") or "".
func _next_buy() -> String:
	var plan: Dictionary = STYLE_PLAN.get(style, STYLE_PLAN.balanced)
	var room: Array = plan.room
	var attackers := _attackers().size()
	var target := mini(int(room[2]), int(room[0] + room[1] * director.drifts_started))
	var walls := _walls().size()
	# Grow into the family first: a Sprout that can become the family's base Warden grows before more
	# Sprouts are planted (players don't sit on five Sprouts while drift 3 walks in).
	if style != "sprout" and _grow_sprout_into_family():
		return "grow"
	if director.drifts_started >= COVER_HEARTWOOD_FROM and not _heartwood_covered() and _plant_attacker(true):
		return "plant"  # Cover the Heartwood (past the planned room)
	if attackers < target and _plant_attacker():
		return "plant"
	if walls < int(attackers * plan.walls) and _plant_wall():
		return "walls"
	if _grow():
		_save_since = -1  # The saver got its growth
		return "grow"
	# A sensible player saves up for an unlocked growth (a branch is 80 Dew, a final 200 plus the ranks it
	# carries) instead of spending every Dew on ranks; Narrow nurtures anyway.
	var saving := _cheapest_growth()
	var bonus := director.get_rest_bonus(director.get_block(maxi(director.drifts_started, 1)))
	# Spender (balance_simulation.md grove10): the next growth when affordable (above), else more coverage,
	# ranks only after that.
	if save_mode == "spender" and _plant_attacker():
		return "plant"
	# Before the act break and the elite from drift 31, nobody sits on more than one rest bonus.
	var spend_down := director.drifts_started in SPEND_DOWN_BEFORE and run_state.dew > bonus
	if save_mode == "saver" and saving > 0:
		# Saver: holds Dew for a growth (a branch, the first final) up to SAVER_DRIFTS drifts, leaks or not.
		if _save_since < 0:
			_save_since = director.drifts_started
		if director.drifts_started - _save_since < SAVER_DRIFTS:
			return ""
	elif save_mode != "spender" and style != "narrow" and saving > 0 and not _leaked_last_drift() and not spend_down \
			and (_saving_for_final or saving <= 3 * bonus):
		return ""  # Finals come before ranks (any price); cheaper growths only while within 3 rest bonuses
	if _nurture():
		return "nurture"
	# Keep nothing in reserve (the spec): nothing else to buy (ranks capped at II without a Nurture
	# Dream, growths locked), so plant one more attacker past the planned room.
	if run_state.dew >= 2 * director.get_rest_bonus(director.get_block(maxi(director.drifts_started, 1))) \
			and _plant_attacker():
		return "plant"
	return ""

# Dew for the cheapest growth open to a Warden on the map (0 = none).
func _cheapest_growth() -> int:
	var cheapest := 0
	_saving_for_final = false
	for tower in _attackers():
		if style == "sprout" and tower.tower_data.get_id() == "sprout":
			continue
		for form in tower.tower_data.evolves_to:
			if form is TowerData and dreams.is_unlocked(form.get_id()) and placer.ascended_blocker(form) == "" \
					and (form.footprint <= tower.get_footprint() or not placer.get_grow_squares(tower, form).is_empty()):
				var cost: int = tower.get_grow_cost(form).total
				if cheapest == 0 or cost < cheapest:
					cheapest = cost
					_saving_for_final = form.tier >= 3
	return cheapest

func _attackers() -> Array:
	return container.get_children().filter(func(t) -> bool:
		return t is Tower and not t.is_queued_for_deletion() and t.tower_data.can_attack)

func _walls() -> Array:
	return container.get_children().filter(func(t) -> bool:
		return t is Tower and not t.is_queued_for_deletion() and not t.tower_data.can_attack)

# `cover_heart`: only cells with the Heartwood in range, scored by the last stretch they also reach.
func _plant_attacker(cover_heart := false) -> bool:
	var plan: Dictionary = STYLE_PLAN.get(style, STYLE_PLAN.balanced)
	if plan.has("plant"):
		var only: TowerData = load("res://resource/tower/%s.tres" % plan.plant)
		if not run_state.can_afford(placer.get_cost(only)):
			return false
		var at := _best_cell(only.attack_range, plan.get("growth_weight", 0.5), cover_heart, only)
		return at != NO_CELL and _build(only, at)
	if style == "mixed" and _sprout_share() < MIXED_SPROUTS:
		var sprout: TowerData = load("res://resource/tower/sprout.tres")
		if run_state.can_afford(placer.get_cost(sprout)):
			var at := _best_cell(sprout.attack_range, 0.5, cover_heart, sprout)
			if at != NO_CELL and _build(sprout, at):
				return true
	var options: Array = placer.get_buildable_towers().filter(func(t: TowerData) -> bool:
		return t.can_attack and t.buildable_directly and t.get_id() != "sprout" and t.footprint == 1 and not t.is_unique)
	if options.is_empty():
		options = [load("res://resource/tower/sprout.tres")]
	# Stick to the first MAX_FAMILIES families on the map (a player builds a family deep, not every family
	# thin); within them, the one with fewer Wardens.
	var main := _main_families()
	if main.size() >= MAX_FAMILIES:
		var focused := options.filter(func(t: TowerData) -> bool: return main.has(t.line))
		if not focused.is_empty():
			options = focused
	options.sort_custom(func(a: TowerData, b: TowerData) -> bool: return _family_count(a) < _family_count(b))
	var data: TowerData = options[0]
	if not run_state.can_afford(placer.get_cost(data)):
		return false
	var cell := _best_cell(data.attack_range, 0.5, cover_heart, data)
	return cell != NO_CELL and _build(data, cell)

func _plant_wall() -> bool:
	var wall: TowerData = load("res://resource/tower/thornwall.tres")
	if not run_state.can_afford(placer.get_cost(wall)):
		return false
	if _half_mode():
		placer.tower_data = wall
		if placer.half_placement():
			return _plant_half_wall()
	var cell := _best_cell(0.0, 1.0)
	return cell != NO_CELL and _build(wall, cell)

# A half origin a Thornwall could stand on now: every half buildable, not settling / Omen-locked / under a nightmare.
func _half_wall_open(origin: Vector2) -> bool:
	var halves: Array[Vector2] = map.halves_of(origin)
	if not halves.all(func(h: Vector2) -> bool: return map.is_buildable_half(h)):
		return false
	var touched := Tower.cells_of_halves(halves)
	return not (placer.settling_left(touched) > 0.0 or placer.omen_locked(touched) or placer._halves_occupied(halves))

# Half cells: a Thornwall on the half origin beside the route that adds the most path (staggered walls). Every origin
# whose footprint touches the halves within one of a route point's body is weighed: the cheap way to cover the half
# grid, since a wall off the route never lengthens it.
func _plant_half_wall() -> bool:
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var origins := {}
	for point in route:
		for h in map.body_halves(point):
			for dy in range(-3, 3):
				for dx in range(-3, 3):
					origins[h + Vector2(dx, dy)] = true
	var walkers := placer._walker_points()
	var best := Vector2(-1, -1)
	var best_growth := 0
	var singles: Array = []  # [growth, origin] of every wall that may stand alone (pair search seeds)
	for origin in origins:
		if not _half_wall_open(origin):
			continue
		var halves: Array[Vector2] = map.halves_of(origin)
		var new_route: PackedVector2Array = map.get_path_if_blocked_halves(halves)
		if new_route.is_empty():
			continue
		var growth := new_route.size() - route.size()
		if pair_search:
			singles.append([growth, origin])
		if growth <= best_growth or not map.can_block_halves(halves, walkers):
			continue
		best_growth = growth
		best = origin
	# Pair lookahead (one-half gaps, half_cells.md 04c10c33): a lone wall that leaves a one-half gap diverts no one,
	# so the best PAIR_FIRSTS single walls each try every second wall within PAIR_REACH halves. When a pair adds more
	# than the best single wall, its first wall is built now (the second scores as a single next time).
	if pair_search and not singles.is_empty():
		singles.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
		var pair_best := best_growth
		var pair_first := Vector2(-1, -1)
		for entry in singles.slice(0, PAIR_FIRSTS):
			var first: Vector2 = entry[1]
			var first_halves: Array[Vector2] = map.halves_of(first)
			for dy in range(-PAIR_REACH - 1, PAIR_REACH + 2):
				for dx in range(-PAIR_REACH - 1, PAIR_REACH + 2):
					var second: Vector2 = first + Vector2(dx, dy)
					if absi(dx) < 2 and absi(dy) < 2:
						continue  # Overlaps the first wall's footprint
					if not _half_wall_open(second):
						continue
					var both: Array = first_halves + map.halves_of(second)
					var new_route: PackedVector2Array = map.get_path_if_blocked_halves(both)
					var growth := new_route.size() - route.size()
					if new_route.is_empty() or growth <= pair_best or not map.can_block_halves(both, walkers):
						continue
					pair_best = growth
					pair_first = first
		if pair_first != Vector2(-1, -1) and map.can_block_halves(map.halves_of(pair_first), walkers):
			best = pair_first
			half_spots[4] += 1
	if best == Vector2(-1, -1):
		return false
	half_spots[3] += 1
	var before := _route_cells(map.get_path_from(map.startPath))
	var built: bool = placer._try_build_half(best)
	if built:
		_note_path(before, true)
	return built

# Builds and notes the route cells the placement added (path_per_plant / path_per_wall columns).
func _build(data: TowerData, cell: Vector2) -> bool:
	var before := _route_cells(map.get_path_from(map.startPath))
	var built := _build_inner(data, cell)
	if built:
		_note_path(before, not data.can_attack)
	return built

func _note_path(before: int, wall: bool) -> void:
	var entry: Array = path_added["wall" if wall else "plant"]
	entry[0] += _route_cells(map.get_path_from(map.startPath)) - before
	entry[1] += 1

func _build_inner(data: TowerData, cell: Vector2) -> bool:
	placer.tower_data = data
	if not _half_mode() or _top.is_empty() or not placer.half_placement():
		return placer._try_build(cell)
	# Half cells (half_cells.md): the 8 half-offset nudges around each of the NUDGE_TOP best full cells, scored the
	# same way; a full cell keeps its own score. The best spot is built (full cells through _try_build).
	var reach: float = _last_args[0]
	var growth_weight: float = _last_args[1]
	var cover_heart: bool = _last_args[2]
	var route: PackedVector2Array = _last_args[4]
	var enemy_cells: PackedVector2Array = _last_args[5]
	var best_origin: Vector2 = cell * 2.0
	var best_score: float = _top[0][0]
	for entry in _top:
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				if dx == 0 and dy == 0:
					continue
				var origin: Vector2 = entry[1] * 2.0 + Vector2(dx, dy)
				var halves: Array[Vector2] = map.halves_of(origin)
				if not halves.all(func(h: Vector2) -> bool: return map.is_buildable_half(h)):
					continue
				var touched := Tower.cells_of_halves(halves)
				if placer.settling_left(touched) > 0.0 or placer.omen_locked(touched) or placer._halves_occupied(halves):
					continue
				var centre := origin / 2.0  # The footprint's centre in full-cell units (route points are x.0 / x.5)
				if cover_heart and centre.distance_to(map.endPath) > reach:
					continue
				if not map.can_block_halves(halves, enemy_cells):
					continue
				var new_route: PackedVector2Array = map.get_path_if_blocked_halves(halves)
				if new_route.is_empty():
					continue
				var score := _spot_score(centre, Tower.half_home_cell(origin), new_route, route, reach, growth_weight, cover_heart, _last_args[3])
				if score > best_score:
					best_score = score
					best_origin = origin
	half_spots[0] += 1
	_top = []
	if best_origin == cell * 2.0:
		return placer._try_build(cell)
	half_spots[1] += 1
	if placer._try_build_half(best_origin):
		return true
	half_spots[2] += 1  # Refused at the half offset: the full cell instead
	return placer._try_build(cell)

# Half cells are on (MapGenerator.halves_of, main since b8305630) and the bot may use them (--no-half-pref: full
# cells only, the bot before 2026-10-04).
func _half_mode() -> bool:
	return half_pref and map.has_method("halves_of")

# Route points per full cell: 2 on the half grid (points step by half a cell), else 1.
func _route_step() -> int:
	return 2 if map.has_method("halves_of") else 1

# A route's length in full cells (MapGenerator.route_length on the half grid).
func _route_cells(route: PackedVector2Array) -> int:
	return map.route_length(route) if map.has_method("route_length") else route.size()

# Route halves squeezed into a one-half corridor (half_cells.md 04c10c33: a nightmare fits through one half): both
# left and right, or both above and below, are blocked. -1 before the one-half rule (FindPath.is_whole_cell).
func _narrow_halves() -> int:
	var finder: Script = FindPath
	if not finder.get_script_method_list().any(func(m: Dictionary) -> bool: return m.name == "is_whole_cell") \
			or not map.path_layer.has_method("is_half_blocked"):
		return -1
	var count := 0
	for p in map.get_path_from(map.startPath):
		if finder.call("is_whole_cell", p):  # Called by name: older builds lack these
			continue
		var h := Vector2(finder.call("point_to_node", p))
		var blocked := func(at: Vector2) -> bool: return map.path_layer.is_half_blocked(at)
		if (blocked.call(h + Vector2.LEFT) and blocked.call(h + Vector2.RIGHT)) or (blocked.call(h + Vector2.UP) and blocked.call(h + Vector2.DOWN)):
			count += 1
	return count

# A spot's score: route points within `reach` of `centre` (the last LAST_STRETCH cells double with `cover_heart`) +
# `growth_weight` × the points it adds + aura / Kinship bonuses at `anchor` (the full cell they measure from).
func _spot_score(centre: Vector2, anchor: Vector2, new_route: PackedVector2Array, route: PackedVector2Array, reach: float,
		growth_weight: float, cover_heart: bool, data: TowerData) -> float:
	var cover := 0
	var stretch := LAST_STRETCH * _route_step()
	if reach > 0.0:
		for i in new_route.size():
			if new_route[i].distance_to(centre) <= reach:
				cover += 2 if cover_heart and i >= new_route.size() - stretch else 1
	return cover + growth_weight * (new_route.size() - route.size()) + (_aura_bonus(anchor, data) + _kin_bonus(anchor, data) if data != null else 0.0)

# The open cell scoring best: path cells within `reach` + `growth_weight` × the path it adds. Walls
# (reach 0) only count if they add path. `cover_heart`: only cells reaching the Heartwood, the last
# LAST_STRETCH route tiles counting double. Keeps the NUDGE_TOP best in _top for _build's half-cell nudges.
func _best_cell(reach: float, growth_weight: float, cover_heart := false, data: TowerData = null) -> Vector2:
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var enemy_cells := PackedVector2Array()
	for enemy in spawner.get_maze_walkers():
		enemy_cells.append(enemy.get_target_cell())
	var best := NO_CELL
	var best_score := 0.0 if reach <= 0.0 else -INF
	var scored: Array = []
	for y in Tower.MAP_GRID.size.y:
		for x in Tower.MAP_GRID.size.x:
			var cell := Vector2(x, y)
			if not map.is_buildable(cell) or placer.settling_left([cell]) > 0.0 or placer._cells_occupied([cell]):
				continue
			if cover_heart and cell.distance_to(map.endPath) > reach:
				continue
			var new_route: PackedVector2Array = map.get_path_if_blocked_cells([cell])
			if new_route.is_empty() or not map.can_block_cells([cell], enemy_cells):
				continue
			var score := _spot_score(cell, cell, new_route, route, reach, growth_weight, cover_heart, data)
			if score > (0.0 if reach <= 0.0 else -INF):
				scored.append([score, cell])  # Walls only when they add path
			if score > best_score:
				best_score = score
				best = cell
	scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	_top = scored.slice(0, NUDGE_TOP)
	_last_args = [reach, growth_weight, cover_heart, data, route, enemy_cells]
	return best

func _coverage(tower: Tower) -> int:
	var reach := tower.get_range_cells()
	var count := 0
	for at in map.get_path_from(map.startPath):
		if at.distance_to(tower.cell) <= reach:
			count += 1
	return count

# Grow the Warden with the most path in range (spec), into its first unlocked form it can afford.
func _grow() -> bool:
	var best: Array = []
	for tower in _attackers():
		if style == "sprout" and tower.tower_data.get_id() == "sprout":
			continue  # The swarm stays Sprouts
		if style == "mixed" and tower.tower_data.get_id() == "sprout" and _sprout_share() <= MIXED_SPROUTS:
			continue  # Mixed keeps about 40% Sprouts
		# The form: the first open one in evolves_to (--no-kin, the old bot); with Kinship placement the one
		# that bonds with the most unbonded kin nearby, then the branch with fewer on the map (both branches seen).
		var pick: TowerData = null
		var pick_score := -INF
		for form in tower.tower_data.evolves_to:
			if not (form is TowerData) or not dreams.is_unlocked(form.get_id()) or placer.ascended_blocker(form) != "":
				continue
			if _grow_only_tier > 0 and form.tier != _grow_only_tier:
				continue  # --extra-spend grow / final: only that step
			if form.footprint > tower.get_footprint() and placer.get_grow_squares(tower, form).is_empty():
				continue
			if tower.get_grow_cost(form).total > run_state.dew:
				continue
			if not kin_placement:
				pick = form
				break
			var form_score := 100.0 * _kin_bonus(tower.cell, form, tower) - _count_on_map(form.get_id())
			if carry_pref and director.drifts_started <= director.drifts_per_act and DreamState.is_carry(form):
				form_score += 1000.0  # Act 1: the carry branch over its partner (Bloomcap beside Driftspore was "the one with fewer on the map")
			if form_score > pick_score:
				pick_score = form_score
				pick = form
		if pick != null:
			# Growing into an aura Warden: the Wardens around it count; into a kin branch: its unbonded kin.
			var cover := _coverage(tower) + _aura_bonus(tower.cell, pick, tower, false) + _kin_bonus(tower.cell, pick, tower)
			if _finals_first:
				cover += 1000.0 * pick.tier  # The late-start build: finals before new branches
			if fence_pref and pick.special == &"jarlink":
				cover += _fence_bonus(tower)  # The arc must cross the route (the probe's --pairs rule)
				if cover < 0.0:
					continue  # Its arc would cover no route tile: not here
			if best.is_empty() or cover > best[0]:
				best = [cover, tower, pick]
	return not best.is_empty() and placer.evolve(best[1], best[2])

# Balanced: the lowest rank first, most path in range among those; Narrow the same but it plants few.
func _nurture() -> bool:
	var towers := _attackers().filter(func(t) -> bool: return t.can_nurture() and t.get_nurture_cost() <= run_state.dew and not _waits_for_final(t) and not _sprout_waits(t))
	if towers.is_empty():
		return false
	towers.sort_custom(func(a, b) -> bool:
		return a.rank < b.rank or (a.rank == b.rank and _coverage(a) > _coverage(b)))
	var tower: Tower = towers[0]
	if focus_mode == "deep" and tower.needs_focus() and tower.focus_options().has(Tower.Focus.DEEP):
		return placer.nurture(tower, Tower.Focus.DEEP)  # --focus=deep
	return placer.nurture(tower, tower.focus_options()[0] if tower.needs_focus() else Tower.Focus.NONE)  # Power; support Wardens Wide

func _family_count(base: TowerData) -> int:
	return _attackers().filter(func(t) -> bool: return t.tower_data.line == base.line).size()

# --- Recording -----------------------------------------------------------------------------------------

func _hook_stats() -> void:
	if DamageLog.instance:
		DamageLog.instance.damage_dealt.connect(_on_damage)
	spawner.child_entered_tree.connect(func(n) -> void:
		if n.has_method("take_damage"):
			(func() -> void: d.health_spawned += n.max_health).call_deferred())
	spawner.enemy_reached_goal.connect(func(e) -> void:
		d.leaks += 1
		if is_instance_valid(e):
			d.leaked_health += e.health  # Health that got through (dispelled share = 1 - leaked / spawned)
		if is_instance_valid(e) and e.enemy_data.is_boss:  # An act boss bites (8 / 10 / 12 leaves) and leaves (bfc33e75)
			_boss_leaked(e)
		if run.first_leak == 0:
			run.first_leak = maxi(director.drifts_started, 1))
	if spawner.has_signal("boss_drained"):  # A boss at the Heartwood drains leaves (no enemy_reached_goal)
		spawner.boss_drained.connect(func(e, leaves: int) -> void:
			run.boss_drained += leaves
			if is_instance_valid(e):
				_boss_fight(e).drained += leaves)
	if spawner.has_signal("nightmare_restless"):
		spawner.nightmare_restless.connect(func(_e, _stacks) -> void: d.restless += 1)
	if spawner.has_signal("wall_trampled"):
		spawner.wall_trampled.connect(func(_cell, _by) -> void: d.trampled += 1)
	run_state.leaves_changed.connect(func(leaves: int, _max: int) -> void: d.leaves_left = leaves)
	run_state.dew_changed.connect(func(dew: int) -> void:
		var delta := dew - _last_dew
		_last_dew = dew
		if delta > 0:
			d.dew_other += delta)  # Rest bonuses are moved out of this in _close_window
	director.drift_cleared.connect(func(n, _b, _p) -> void: _close_window(n))

func _new_window() -> void:
	d = {"start": game_time, "health_spawned": 0.0, "damage": 0.0, "chain_deep": 0.0, "leaks": 0, "leaves_left": run_state.leaves,
		"leaves_before": run_state.leaves, "dew_rest": 0, "dew_other": 0, "spent_plant": 0, "spent_walls": 0,
		"spent_grow": 0, "spent_nurture": 0, "by_tower": {}, "asleep": 0.0, "reaction": 0.0, "crit": 0.0,
		"restless": 0, "trampled": 0, "approach": 0.0, "combo": 0.0, "status": 0.0, "hit": 0.0, "combo_damage": 0.0, "reaction_damage": 0.0, "status_damage": 0.0, "leaked_health": 0.0}

func _on_damage(event) -> void:
	d.damage += event.amount
	var tag := String(event.tag) if event.tag != &"" else String(event.kind)
	damage_by_tag[tag] = float(damage_by_tag.get(tag, 0.0)) + event.amount
	_note_form_damage(event)
	if is_instance_valid(event.enemy) and event.enemy.enemy_data.is_boss:
		_note_boss_hit(event.enemy, event.amount)
	# Per Warden (instance), not per kind: twenty Sporelings are twenty Wardens for the "one Warden" check.
	var key: String = "%s#%d" % [event.source_name, event.source.get_instance_id()] if is_instance_valid(event.source) else event.source_name
	d.by_tower[key] = d.by_tower.get(key, 0.0) + event.amount
	d.combo += clampf(event.combo_amount, 0.0, event.amount)  # Overlaps the three below (a combo rides on a hit, tick or Reaction)
	# RunHistory's split (731537b5), the same formula so bot and human compare: combo = combo_amount; reaction = a Reaction
	# tag's damage less its combo part; status = non-hit damage with no combo and no Reaction.
	var rh_reaction: float = maxf(event.amount - event.combo_amount, 0.0) if reaction_tags.has(event.tag) else 0.0
	var rh_status: float = event.amount if event.kind != &"hit" and event.combos.is_empty() and rh_reaction == 0.0 else 0.0
	d.combo_damage += event.combo_amount
	d.reaction_damage += rh_reaction
	d.status_damage += rh_status
	run_parts.damage_total += event.amount
	run_parts.combo_damage += event.combo_amount
	run_parts.reaction_damage += rh_reaction
	run_parts.status_damage += rh_status
	if reaction_tags.has(event.tag):
		pass  # Counted below as reaction
	elif event.kind == &"status" or event.kind == &"bolt":
		d.status += event.amount
	else:
		d.hit += event.amount
	if reaction_tags.has(event.tag):
		d.reaction += event.amount
		var hit_enemy = event.enemy
		if is_instance_valid(hit_enemy) and hit_enemy.statuses.chain_time > 0.0 and hit_enemy.statuses.chain_count >= Reactions.CHAIN_FALLOFF_FROM:
			d.chain_deep += event.amount  # Reactions from the 6th link on (where chain falloff bites)
	if event.crit_multiplier > 1.0:
		d.crit += event.amount
	var e = event.enemy
	if is_instance_valid(e) and (e.statuses.is_asleep() or (e.statuses.has(EnemyStatuses.DROWSY)
			and e.statuses.stacks(EnemyStatuses.DROWSY) >= e.statuses.get_max_stacks(EnemyStatuses.DROWSY))):
		d.asleep += event.amount

func _close_window(n: int) -> void:
	var tiers := [0, 0, 0, 0, 0]
	var ranks := 0
	var lines := {}
	for t in _attackers():
		tiers[clampi(t.tower_data.tier, 0, 4)] += 1
		ranks += t.rank
		lines[t.tower_data.line] = true
	var top := ""
	var top_amount := 0.0
	for name in d.by_tower:
		if d.by_tower[name] > top_amount:
			top_amount = d.by_tower[name]
			top = name.get_slice("#", 0)
	var damage := maxf(d.damage, 1.0)

	var row := {"drift": n, "act": director.get_act(n), "seconds": snappedf(game_time - d.start, 0.1),
		"health_spawned": roundi(d.health_spawned), "damage": roundi(d.damage), "leaks": d.leaks,
		"leaves_lost": run_state.leaves_lost, "leaves_left": run_state.leaves,
		"dew_rest": d.dew_rest, "dew_other": maxi(d.dew_other - d.dew_rest, 0),
		"spent_plant": d.spent_plant, "spent_walls": d.spent_walls, "spent_grow": d.spent_grow,
		"spent_nurture": d.spent_nurture, "banked": run_state.dew, "attackers": _attackers().size(),
		"walls": _walls().size(), "tier1": tiers[1], "tier2": tiers[2], "tier3": tiers[3], "tier4": tiers[4],
		"avg_rank": snappedf(float(ranks) / maxf(_attackers().size(), 1), 0.1),
		"route": _route_cells(map.get_path_from(map.startPath)), "families": lines.size(), "cards": dreams.stacks.size(),
		"dreamlight": dreams.dreamlight, "top_warden": top, "top_share": snappedf(top_amount / damage, 0.001),
		"asleep_share": snappedf(d.asleep / damage, 0.001), "reaction_share": snappedf(d.reaction / damage, 0.001), "chain_share": snappedf(d.chain_deep / damage, 0.001), "combo_amount_share": snappedf(d.combo / damage, 0.001), "status_share": snappedf(d.status / damage, 0.001), "hit_share": snappedf(d.hit / damage, 0.001), "combo_damage": roundi(d.combo_damage), "reaction_damage": roundi(d.reaction_damage), "status_damage": roundi(d.status_damage), "combo_share": snappedf((d.combo_damage + d.reaction_damage) / damage, 0.001), "longest_chain": _longest_chain(), "leaked_health": roundi(d.leaked_health),
		"crit_share": snappedf(d.crit / damage, 0.001), "restless": d.restless, "trampled": d.trampled,
		"approach": snappedf(d.approach, 0.01)}
	rows.append(row)
	if n == 25:
		run.sprout_cards_25 = SPROUT_CARDS.filter(func(id: String) -> bool: return dreams.stacks.has(id)).size()
	for mark in run.lost_by:
		if n == mark:
			run.lost_by[mark] = row.leaves_lost
	if n >= 10 and top != "":
		run.top_wardens[top] = run.top_wardens.get(top, 0) + 1
		if row.top_share > run.max_top_share:
			run.max_top_share = row.top_share
			run.max_top_warden = top
	if n >= 10:
		run.max_asleep = maxf(run.max_asleep, row.asleep_share)
	_new_window()

# The share of the maze's damage per second the taken Dreams add: each attacker's DPS against what it
# would be without its Dream damage and attack speed parts (DreamState.get_stat_parts). Rule cards
# (Reactions, statuses, economy) aren't in it, so it's a floor.
func _dream_share() -> float:
	var total := 0.0
	var without := 0.0
	for tower in _attackers():
		var dps: float = tower.get_damage() * tower.get_attacks_per_second()
		var damage := 0.0
		var speed := 0.0
		for part in dreams.get_stat_parts(tower.tower_data, tower.cell, "damage", tower).parts:
			damage += part.amount
		for part in dreams.get_stat_parts(tower.tower_data, tower.cell, "attack_speed", tower).parts:
			speed += part.amount
		total += dps
		without += dps / maxf((1.0 + damage) * (1.0 + speed), 0.01)
	return snappedf(1.0 - without / total, 0.001) if total > 0.0 else 0.0

# The Grove perks carried into the run ("dewdrop_pouch+early_light"), "" at Fresh.
func _loadout() -> String:
	var ids: Array[String] = []
	for id in HeartwoodMemory.get_loadout(HeartwoodMemory.load_data()) if profile != "fresh" else []:
		ids.append(str(id))
	return "+".join(ids)

func _finish() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var name := "%s_%s%s_seed%d" % [profile, style, ("_" + "+".join(start_cards)) if not start_cards.is_empty() else "", map_seed]
	var file := FileAccess.open(out_dir.path_join(name + ".csv"), FileAccess.WRITE)
	file.store_line(",".join(COLUMNS))
	for row in rows:
		file.store_line(",".join(COLUMNS.map(func(c: String) -> String: return str(row.get(c, "")))))
	file.close()
	var survived := director.drifts_cleared
	var won := survived >= 100 and run_state.leaves > 0
	var top := ""
	for w in run.top_wardens:
		if top == "" or run.top_wardens[w] > run.top_wardens[top]:
			top = w
	var hoard := 0.0
	var count := 0
	for i in run.rest_banked.size():
		if i >= 5:  # After act 1 (rests 25+)
			hoard += float(run.rest_banked[i]) / maxf(run.rest_bonus[i], 1.0)
			count += 1
	var summary := {"profile": profile, "style": style, "seed": map_seed, "survived": survived, "won": won,
		"first_leak": run.first_leak, "lost_25": run.lost_by[25], "lost_50": run.lost_by[50], "lost_75": run.lost_by[75],
		"bank_act2": run.banked_at_act.get(2, -1), "bank_act3": run.banked_at_act.get(3, -1), "bank_act4": run.banked_at_act.get(4, -1),
		"hoard_rests": snappedf(hoard / maxf(count, 1), 0.01), "top_warden": top, "max_top_share": run.max_top_share,
		"max_top_warden": run.max_top_warden, "max_asleep": snappedf(run.max_asleep, 0.001), "cards": dreams.stacks.size(),
		"sprout_cards_25": run.sprout_cards_25,
		"sprouts_end": _attackers().filter(func(t) -> bool: return t.tower_data.get_id() == "sprout").size(), "cards_start": "+".join(start_cards),
		"loadout": _loadout(), "all_families": all_families, "dreams": dream_mode, "boss": act1_boss, "boss_draw": BossPool.force_draw, "director": ";".join(director_overrides.keys().map(func(k) -> String: return "%s=%s" % [k, director_overrides[k]])), "enemy": ";".join(enemy_overrides.keys().map(func(k) -> String: return "%s=%s" % [k, enemy_overrides[k]])), "boss_drained": run.boss_drained, "dream_share_20": dream_share.get(20, -1.0), "dream_share_25": dream_share.get(25, -1.0), "dreams_20": dreams_20, "dream_share_35": dream_share.get(35, -1.0), "dream_share_50": dream_share.get(50, -1.0), "dream_share_75": dream_share.get(75, -1.0), "favored": "+".join(favored), "save": save_mode, "omens": omen_mode, "omens_faced": "+".join(omens_faced), "omen_paid": _omen_stat("paid"), "omen_share": _omen_stat("share"), "omen_leaves_lost": _omen_stat("leaves_lost"), "omen_dew": (_omen_stat("dew") + roundi(omen_pot_dew)) if omens != null and _facing() else -1, "omen_pot_dew": roundi(omen_pot_dew), "omen_dreamlight": dreamlight_by_source.get(&"omen", 0) if omen_mode != "" else -1, "families_forced": "+".join(forced_families), "hand_drifts": hand_drifts,
		"close_calls": rows.filter(func(r) -> bool: return r.approach > CLOSE_CALL).size(),
		"approach_max": snappedf(rows.reduce(func(m, r) -> float: return maxf(m, r.approach), 0.0), 0.01),
		"seconds": snappedf(game_time, 1.0)}
	summary.merge(_omen_act_columns())
	summary.omen_blocks = ";".join(omen_blocks)
	summary.bosses = ";".join(bosses.values().map(_boss_text))
	for key in ["offers", "pool_5", "cards", "matched", "generic", "off"]:
		summary["dream_" + key] = dream_offers[key]
	summary.wardens_24 = wardens_24
	summary.auras_24 = auras_24
	summary.heart_cover_24 = heart_cover_24
	summary.status_potency = Tower.status_potency_on
	summary.focus = focus_mode
	summary.sidegrade = sidegrade
	summary.empty_loadout = empty_loadout
	summary.demo = ResultsScreen.is_demo()  # The demo build applies no Grove (MetaRun inert)
	var meta_run = main.get_node_or_null("%MetaRun")
	summary.meta_active = meta_run.get("active") if meta_run != null else null
	summary.merge(_status_columns())
	summary.forms = _form_column()
	for key in run_parts:
		summary[key] = roundi(run_parts[key])
	summary.combo_share = snappedf((run_parts.combo_damage + run_parts.reaction_damage) / maxf(run_parts.damage_total, 1.0), 0.001)
	summary.merge(_route_columns())
	summary.kin_pairs_24 = kin_pairs.get(25, -1)
	summary.kin_pairs_50 = kin_pairs.get(51, -1)
	summary.dream_off_ids = "+".join(dream_off_ids.keys().map(func(id) -> String: return "%s:%d" % [id, dream_off_ids[id]]))
	summary.dream_pool_mean = snappedf(float(dream_offers.pool) / maxf(dream_offers.offers, 1.0), 0.1)
	summary.gifts = "+".join(gifts_log)
	summary.half_spots = "%d/%d/%d" % [half_spots[1] - half_spots[2], half_spots[0], half_spots[2]]  # Attackers: at a half offset / weighed / refused there
	summary.half_walls = half_spots[3]
	summary.pair_walls = half_spots[4]  # Of them, built as the first wall of a better pair
	summary.route_base = route_base
	summary.grows = grow_count
	summary.grows_25 = grows_25
	summary.first_grow = first_grow
	summary.sets = ";".join(node_sets)
	summary.start_at = start_at  # 0 = a full run; never mix these rows with full runs
	summary.start_dew = start_dew
	summary.start_dreamlight = start_dl
	summary.start_leaves = START_LEAVES.get(start_at, -1) if start_leaves < 0 else start_leaves
	summary.start_build = start_counts.replace(",", ";")
	summary.from_save = from_save.get_file()
	summary.resumed_at = resumed_at
	summary.extra_spend = extra_spend
	summary.extra_dew = extra_dew
	summary.extra_spent = extra_spent
	summary.base_kind = base_kind
	summary.copies_at_start = copies_at_start
	summary.path_per_plant = snappedf(float(path_added.plant[0]) / maxf(path_added.plant[1], 1.0), 0.01)
	summary.path_per_wall = snappedf(float(path_added.wall[0]) / maxf(path_added.wall[1], 1.0), 0.01)
	summary.placements = "%d/%d" % [path_added.plant[1], path_added.wall[1]]
	summary.growth_costs = "%s/%s/%s/%s" % [dreams.get("branch_cost_multiplier"), dreams.get("final_cost_multiplier"), dreams.get("ascended_cost_multiplier"), dreams.get("rank_costs")]
	summary.route_open = route_open
	summary.route_24 = route_at.get(24, -1)
	summary.route_45 = route_at.get(45, -1)
	summary.narrow_24 = narrow_at.get(24, -1)
	summary.narrow_45 = narrow_at.get(45, -1)
	summary.narrow_end = _narrow_halves()
	summary.jarlinks = _jarlink_text()
	summary.branch_offers = ";".join(dreams.branch_offers.keys().map(func(id) -> String: return "%s:%s" % [id, "/".join(dreams.branch_offers[id].map(func(t) -> String: return t.get_id() if t is TowerData else str(t)))]))
	summary.dreamlight_unlocks = "+".join(policy.choices.filter(func(c: String) -> bool: return c.begins_with("Dreamlight: ")).map(func(c: String) -> String: return c.substr(12)))
	var runs_path := out_dir.path_join("runs.csv")
	var keys := summary.keys()
	var new_file := not FileAccess.file_exists(runs_path)
	var runs := FileAccess.open(runs_path, FileAccess.READ_WRITE if not new_file else FileAccess.WRITE)
	if new_file:
		runs.store_line(",".join(keys))
	runs.seek_end()
	runs.store_line(",".join(keys.map(func(k) -> String: return str(summary[k]))))
	runs.close()
	print("RUN %s" % JSON.stringify(summary))
	print("CHOICES %s" % " | ".join(policy.choices))

# The families the bot builds (Balanced and the other mixed styles): the first MAX_FAMILIES lines on the
# map, in the order they were planted.
func _main_families() -> Array:
	var lines := []
	for tower in _attackers():
		var line: String = tower.tower_data.line
		if line != "sprout" and line != "wall" and not lines.has(line):
			lines.append(line)
	return lines.slice(0, MAX_FAMILIES)

# The first growth open to `tower` (unlocked, room to grow), or null. A Warden with one waits for it
# instead of being nurtured: ranks raise what growing costs (Tower.get_grow_cost pays the ranks).
func _open_growth(tower: Tower) -> TowerData:
	if style == "sprout" and tower.tower_data.get_id() == "sprout":
		return null
	for form in tower.tower_data.evolves_to:
		if form is TowerData and dreams.is_unlocked(form.get_id()) and placer.ascended_blocker(form) == "" \
				and (form.footprint <= tower.get_footprint() or not placer.get_grow_squares(tower, form).is_empty()):
			return form
	return null

# A Warden whose next growth is a final form or beyond waits for it instead of taking ranks (ranks raise
# what the growth costs); base -> branch growths are cheap and don't hold nurturing back.
func _waits_for_final(tower: Tower) -> bool:
	var form := _open_growth(tower)
	return form != null and form.tier >= 3

# Whether the last finished drift leaked: the bot spends instead of saving up then.
func _leaked_last_drift() -> bool:
	return not rows.is_empty() and int(rows.back().get("leaks", 0)) > 0

# --families: the picks go to these families in order (the family is unlocked as a pick would); once the
# list is used up, a pick takes nothing (a fixed pair stays a pair).
func _forced_family_pick(kind: StringName) -> void:
	if kind == &"first":
		dreams.add_dreamlight(dreams.sim_dreamlight_for(&"first"))
	var chosen := ""
	for id in forced_families:
		if not dreams.is_unlocked(id):
			chosen = id
			break
	if chosen != "":
		dreams.unlocked[chosen] = true
		dreams.unlocks_changed.emit()
	policy.choices.append("family pick (%s): %s" % [kind, chosen if chosen != "" else "none (fixed families)"])
	policy.spend_dreamlight()

# A Sprout on the map grows into an unlocked family base Warden, if one is affordable (the one with the
# most path in range).
func _grow_sprout_into_family() -> bool:
	var best: Array = []
	if style == "mixed" and _sprout_share() <= MIXED_SPROUTS:
		return false
	for tower in _attackers():
		if tower.tower_data.get_id() != "sprout":
			continue
		for form in tower.tower_data.evolves_to:
			if form is TowerData and form.tier == 1 and dreams.is_unlocked(form.get_id()) \
					and tower.get_grow_cost(form).total <= run_state.dew:
				var cover := _coverage(tower)
				if best.is_empty() or cover > best[0]:
					best = [cover, tower, form]
				break
	return not best.is_empty() and placer.evolve(best[1], best[2])

# The share of attackers that are Sprouts (Mixed keeps about MIXED_SPROUTS).
func _sprout_share() -> float:
	var attackers := _attackers()
	if attackers.is_empty():
		return 1.0
	return float(attackers.filter(func(t) -> bool: return t.tower_data.get_id() == "sprout").size()) / attackers.size()

# Closest approach (balance_simulation.md "Spend or save"): how far along the route the furthest
# nightmare is right now (0 at the start, 1 at the Heartwood); the drift window keeps the maximum.
func _sample_approach() -> void:
	var route_px := maxf((map.get_path_from(map.startPath).size() - 1) * Tower.MAP_GRID.cell_size.x / _route_step(), 1.0)  # Half grid: points step by half a cell
	for enemy in spawner.get_enemies():
		if is_instance_valid(enemy) and enemy.enemy_data.is_boss:
			_watch_boss(enemy)
		if is_instance_valid(enemy) and not enemy.is_cleansed:
			_sample_statuses(enemy.statuses)
		if is_instance_valid(enemy) and not enemy.is_cleansed:
			d.approach = maxf(d.approach, clampf(1.0 - enemy.get_remaining_distance() / route_px, 0.0, 1.0))

# A Sprout that will grow into the family isn't nurtured (ranks raise what the growth costs): before the
# first family pick, or while a family base form is open to it. The Sprout build keeps its Sprouts, and
# Mixed may nurture its kept Sprouts once it's down to its MIXED_SPROUTS share.
func _sprout_waits(tower: Tower) -> bool:
	if style == "sprout" or tower.tower_data.get_id() != "sprout":
		return false
	if style == "mixed" and _sprout_share() <= MIXED_SPROUTS:
		return false
	for form in tower.tower_data.evolves_to:
		if form is TowerData and form.tier == 1 and dreams.is_unlocked(form.get_id()):
			return true
	return director.drifts_started <= 1  # The family pick comes after drift 1

# --favor: the named Dream cards come first (then the style's own scoring).
class FavorPolicy extends DreamSimPolicy:
	const FAVOR := 1000.0
	var favored: Array[String] = []
	var mode := "balanced"  # --dreams: "skip" lets every offer pass, "random" takes any card, "balanced" the style's pick; "damage":
	# damage, attack speed and Potency cards first, economy last (act 1 "damage-first")
	var rng := RandomNumberGenerator.new()
	var on_offer: Callable  # The runner logs each offer (Dream pool size, build relevance)
	var deep := false  # --focus=deep: Potency cards first

	func score(card: UpgradeData) -> float:
		var value := super.score(card) + (FAVOR if favored.has(card.id) else 0.0)
		if deep and (card.potency_bonus > 0.0 or card.tags.has("potency")):
			value += 500.0  # A committed Deep build takes its Potency cards
		if mode == "damage":
			value += 1000.0 * (card.soothe_bonus + card.attack_speed_bonus + card.potency_bonus + 0.5 * card.status_strength_bonus)
			if card.dew_now > 0 or card.rest_bonus_add > 0 or card.dew_per_clear > 0 or card.evolve_discount > 0.0 or card.set_cost > 0:
				value -= 500.0  # Economy last
		return value

	var on_pick: Callable  # The runner logs each offer with the card taken (offers.csv)

	func pick_dream(offer: Array) -> UpgradeData:
		if on_offer.is_valid():
			on_offer.call(offer)
		var pick: UpgradeData = null
		match mode:
			"skip":
				pick = null  # Let it pass (DreamState.sim_rest skips)
			"random":
				pick = offer[rng.randi_range(0, offer.size() - 1)] if not offer.is_empty() else null
			_:
				pick = super.pick_dream(offer)
		if on_pick.is_valid():
			on_pick.call(offer, pick)
		return pick

# The run's longest Reaction chain so far (ReactionTracker; 0 before the first Reaction).
func _longest_chain() -> int:
	var tracker := main.get_tree().get_first_node_in_group(ReactionTracker.GROUP) as ReactionTracker
	return tracker.longest_chain if tracker else 0

# Whether the bot answers Omen offers (any --omens mode); without one the OmenDirector is cut off.
func _facing() -> bool:
	return omen_mode in ["face", "clear", "always", "clean"]

# OmenDirector.stats (Roguelite 7477d9ba: paid, share, leaves_lost, dew for the run), -1 without Omens.
func _omen_stat(key: String) -> Variant:
	if omens == null or not "stats" in omens or typeof(omens.stats) != TYPE_DICTIONARY:
		return -1
	return omens.stats.get(key, -1)

# omen_dew's pot part (Bountiful Night, Blood Moon, Dry Spell): drift `n`'s pot with the Omen's multiplier
# minus the same pot without it. The Omen's fixed reward comes from OmenDirector.stats.
func _note_omen_pot(n: int) -> void:
	var omen_multiplier: float = omens.get_dew_pot_multiplier(n)
	if is_equal_approx(omen_multiplier, 1.0):
		return
	var plain := director.get_dew_pot(n) * (1.0 + run_state.dew_gain_bonus) * director.blight_dew_multiplier
	if dreams.has_method("get_dew_pot_multiplier"):
		plain *= dreams.get_dew_pot_multiplier(n, false)
	var extra := plain * (omen_multiplier - 1.0)
	omen_pot_dew += extra
	_block_pot += Vector2(extra, plain)
	_omen_act(director.get_act(n)).pot += extra

func _omen_act(act: int) -> Dictionary:
	return omen_by_act.get_or_add(act, {"dew": 0, "pot": 0.0, "share": 0.0, "lost": 0, "paid": 0})

# Puts what OmenDirector.stats gained since the last call into `act` (a reward just paid, or at the end the
# block a lost run died in: its leaves count, with no reward).
func _book_omen_stats(act: int) -> void:
	if omens == null or typeof(omens.get("stats")) != TYPE_DICTIONARY:
		return
	var bucket := _omen_act(act)
	bucket.dew += int(omens.stats.dew) - _omen_seen.dew
	bucket.share += float(omens.stats.share) - _omen_seen.share
	bucket.lost += int(omens.stats.leaves_lost) - _omen_seen.leaves_lost
	bucket.paid += int(omens.stats.paid) - _omen_seen.paid
	_omen_seen = {"dew": int(omens.stats.dew), "share": float(omens.stats.share), "leaves_lost": int(omens.stats.leaves_lost),
		"paid": int(omens.stats.paid)}

# runs.csv columns omen_<key>_a1..a4 (omen_dew_aN = reward + pot part, as omen_dew).
func _omen_act_columns() -> Dictionary:
	var columns := {}
	var on := omens != null and _facing()
	if on:
		_book_omen_stats(director.get_act(maxi(director.drifts_started, 1)))
	for act in range(1, 5):
		var bucket := _omen_act(act)
		columns["omen_dew_a%d" % act] = bucket.dew + roundi(bucket.pot) if on else -1  # Same keys every run (runs.csv rows line up)
		columns["omen_pot_a%d" % act] = roundi(bucket.pot) if on else -1
		columns["omen_share_a%d" % act] = snappedf(bucket.share, 0.01) if on else -1.0
		columns["omen_lost_a%d" % act] = bucket.lost if on else -1
		columns["omen_paid_a%d" % act] = bucket.paid if on else -1
	return columns

func _on_omen_rewarded(omen: OmenData) -> void:
	var before: Dictionary = _omen_seen.duplicate()
	_book_omen_stats(director.get_act(maxi(director.drifts_started, 1)))
	omen_blocks.append("%s:%d:%d:%d:%d" % [omen.id, int(_omen_seen.dew) - int(before.dew), roundi(_block_pot.x), roundi(_block_pot.y),
		int(_omen_seen.leaves_lost) - int(before.leaves_lost)])
	_block_pot = Vector2.ZERO

# --- Boss fights (the "Stag wall" probe) --------------------------------------------------------------
# Per boss: health at spawn, seconds on the route, health left when it reached the Heartwood, damage dealt
# on the route and at the Heartwood, seconds it stayed there, Wardens in range of it there, how it ended.
func _boss_fight(enemy: Node2D) -> Dictionary:
	var id := enemy.get_instance_id()
	if not bosses.has(id):
		bosses[id] = {"drift": director.drifts_started, "kind": enemy.enemy_data.resource_path.get_file().get_basename(),
			"health": enemy.max_health, "spawn": game_time, "arrive": -1.0, "hp_arrive": -1, "route_damage": 0.0,
			"heart_damage": 0.0, "in_range": -1, "end": -1.0, "leaked": false, "visits": 0, "hp_visits": [], "there": false, "drained": 0, "echo": bool(enemy.get("is_echo"))}
	return bosses[id]

func _note_boss_hit(enemy: Node2D, amount: float) -> void:
	var fight := _boss_fight(enemy)
	fight["heart_damage" if enemy.at_heartwood else "route_damage"] += amount

func _watch_boss(enemy: Node2D) -> void:
	var fight := _boss_fight(enemy)
	if enemy.at_heartwood and not fight.there:  # A new visit (the Night Mare laps: several)
		fight.visits += 1
		fight.hp_visits.append(enemy.health)
	fight.there = enemy.at_heartwood
	if enemy.at_heartwood and fight.arrive < 0.0:
		fight.arrive = game_time
		fight.hp_arrive = enemy.health
		fight.in_range = _attackers().filter(func(t: Tower) -> bool:
			return t.global_position.distance_to(enemy.global_position) <= t.get_range_cells() * Tower.MAP_GRID.cell_size.x).size()
	if not enemy.is_cleansed:
		fight.end = game_time

# drift:kind:health:route s:health at the Heartwood (-1 = never got there):route damage:Heartwood damage:
# Heartwood s:Wardens in range there:dispelled 1/0 (:leaked = an act boss that bit and left), then
# :v=visits to the Heartwood:hp=health at each visit (a/b/…):dr=leaves it drained there
func _boss_text(fight: Dictionary) -> String:
	var arrived: bool = fight.arrive >= 0.0
	var route_s: float = (fight.arrive if arrived else fight.end) - fight.spawn
	var heart_s: float = fight.end - fight.arrive if arrived else 0.0
	var dispelled: bool = fight.route_damage + fight.heart_damage >= fight.health * 0.999
	return "%d:%s%s:%d:%.0f:%d:%.0f:%.0f:%.0f:%d:%d%s" % [fight.drift, fight.kind, "(echo)" if fight.echo else "", fight.health,
		route_s, fight.hp_arrive, fight.route_damage, fight.heart_damage, heart_s, fight.in_range, 1 if dispelled else 0,
		":leaked" if fight.leaked else ""] + ":v=%d:hp=%s:dr=%d" % [fight.visits, "/".join(fight.hp_visits.map(func(h) -> String: return str(h))), fight.drained]

# An attacker has the Heartwood cell in range (a boss that gets through stays there, draining leaves).
func _heartwood_covered() -> bool:
	for tower in _attackers():
		if tower.cell.distance_to(map.endPath) <= tower.get_range_cells():
			return true
	return false

# An act boss that got through takes its bite and is gone: it "arrives" with the health it has left.
func _boss_leaked(enemy: Node2D) -> void:
	var fight := _boss_fight(enemy)
	if fight.arrive < 0.0:
		fight.arrive = game_time
		fight.hp_arrive = enemy.health
	fight.end = game_time
	fight.leaked = true

# --- Dream pool and build relevance (Grove control: does a big Grove pool dilute the Dreams?) -----------
# Per offer: the drawable pool (DreamState.can_offer now) and each offered card as matched (its Warden-line
# tags / stat line / stat Warden belong to a line on the map), generic (no Warden line; style tags don't count)
# or off (only other lines').
func _note_offer(offer: Array) -> void:
	var act := director.get_act(maxi(director.drifts_started, 1))
	var pool_size := dreams.pool.filter(func(c: UpgradeData) -> bool: return dreams.can_offer(c, act)).size()
	dream_offers.offers += 1
	dream_offers.pool += pool_size
	if dream_offers.pool_5 < 0:
		dream_offers.pool_5 = pool_size
	var lines := {}
	var families := {}
	for tower in container.get_children():
		if tower is Tower and not tower.is_queued_for_deletion():
			lines[tower.tower_data.line] = true
			families[dreams.family_of(tower.tower_data.get_id())] = true
	for card in offer:
		dream_offers.cards += 1
		# Only Warden lines count (tags also hold style tags: maze, reaction, economy…, which are generic).
		var own: Array = card.tags.filter(func(t: String) -> bool: return CARD_LINES.has(t))
		if card.stat_line != "":
			own.append(card.stat_line)
		if own.is_empty() and card.stat_warden == "":
			dream_offers.generic += 1
		elif own.any(func(t: String) -> bool: return lines.has(t)) \
				or (card.stat_warden != "" and families.has(dreams.family_of(card.stat_warden))):
			dream_offers.matched += 1
		else:
			dream_offers.off += 1
			dream_off_ids[card.id] = int(dream_off_ids.get(card.id, 0)) + 1

# "id:count+…" of every Warden on the map, most first.
func _warden_counts() -> String:
	var counts := {}
	for tower in container.get_children():
		if tower is Tower and not tower.is_queued_for_deletion():
			var id: String = tower.tower_data.get_id()
			counts[id] = int(counts.get(id, 0)) + 1
	var ids := counts.keys()
	ids.sort_custom(func(a, b) -> bool: return counts[a] > counts[b])
	return "+".join(ids.map(func(id) -> String: return "%s:%d" % [id, counts[id]]))

# --- Aura-aware placement (Acorn, Elder Stump, Grove Heart; Moon Moth's range aura) ---------------------
# The cells an aura Warden of `data` reaches (0 = it has no aura).
func _aura_reach(data: TowerData) -> float:
	var reach := 0.0
	if data.aura_damage_bonus > 0.0 or data.aura_speed_bonus > 0.0 or data.aura_per_warden > 0.0:
		reach = data.aura_radius if data.aura_radius > 0.0 else data.attack_range
	if data.range_aura_bonus > 0.0:
		reach = maxf(reach, data.range_aura_radius)
	return reach

# Path-tile bonus for a Warden of `data` at `cell`: AURA_WEIGHT per attacker its aura would cover, and (when
# `receive` and it attacks) per aura Warden whose aura covers the cell; at most AURA_COUNT_MAX Wardens.
func _aura_bonus(cell: Vector2, data: TowerData, exclude: Tower = null, receive := true) -> float:
	if not aura_placement or data == null:
		return 0.0
	var count := 0
	var reach := _aura_reach(data)
	for tower in container.get_children():
		if not (tower is Tower) or tower == exclude or tower.is_queued_for_deletion():
			continue
		var distance: float = tower.cell.distance_to(cell)
		if reach > 0.0 and tower.tower_data.can_attack and distance <= reach:
			count += 1
		elif receive and data.can_attack:
			var theirs := _aura_reach(tower.tower_data)
			if theirs > 0.0 and distance <= theirs:
				count += 1
	return AURA_WEIGHT * mini(count, AURA_COUNT_MAX)

func _covered_by_aura(target: Tower) -> bool:
	for tower in container.get_children():
		if tower is Tower and tower != target and not tower.is_queued_for_deletion():
			var reach := _aura_reach(tower.tower_data)
			if reach > 0.0 and tower.cell.distance_to(target.cell) <= reach:
				return true
	return false

# --- Kinship-aware placement (tower_design.md "Kinships") ----------------------------------------------
# Path-tile bonus for a Warden of `data` at `cell`: KIN_WEIGHT per unbonded Warden of the same family within
# Kinships reach that it bonds with (a branch: its Kinship partner branch; a base Warden: any branch of its
# family, which it can grow to meet). Bonded Wardens never count (bonds are sticky).
# jarlinks column: each Jarlink at the end as cell>partner cell:route tiles under the arc (partner "-" = none), so a
# fence share of 0 can be told apart: no pair, or an arc off the route.
func _jarlink_text() -> String:
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var out: Array[String] = []
	for t in _attackers():
		if t.tower_data.special != &"jarlink":
			continue
		var partner = BranchKit._fence_partner(t)
		var on_route := 0
		if partner != null:
			for c in BranchKit._arc_cells(t.cell, partner.cell):
				if route.has(c):
					on_route += 1
		out.append("%d/%d>%s:%d" % [t.cell.x, t.cell.y, "-" if partner == null else "%d/%d" % [partner.cell.x, partner.cell.y], on_route])
	return " ".join(out)
# A Jarlink bonds with the nearest unbonded Jarlink within 4 cells, and the bond sticks (BranchKit.fence_partner_at).
# Growing `tower` into one: the partner the game would give it and the route tiles under that arc (FENCE_WEIGHT each);
# an arc over no route tile (side by side or off the path) costs FENCE_DEAD, so the bot grows elsewhere. With no
# partner yet: half the route tiles toward the best Firefly Jar 2-4 cells away (a Jarlink to be).
const FENCE_DEAD := -1000.0

func _fence_bonus(tower: Tower) -> float:
	var route: PackedVector2Array = map.get_path_from(map.startPath)
	var partner: Tower = BranchKit.fence_partner_at(tower, tower.cell, 4.0, tower)
	if partner != null:
		var tiles := 0
		for c in BranchKit._arc_cells(tower.cell, partner.cell):
			if route.has(c):
				tiles += 1
		return FENCE_WEIGHT * tiles if tiles > 0 else FENCE_DEAD
	var best := 0.0
	for other in _attackers():
		if other == tower or other.tower_data.get_id() != "firefly_jar":
			continue
		if Kinships._cheb(tower.cell, other.cell) > 4.0:
			continue
		var tiles := 0
		for c in BranchKit._arc_cells(tower.cell, other.cell):
			if route.has(c):
				tiles += 1
		best = maxf(best, 0.5 * tiles)
	return FENCE_WEIGHT * best

func _kin_bonus(cell: Vector2, data: TowerData, exclude: Tower = null) -> float:
	if not kin_placement or data == null or not data.can_attack:
		return 0.0
	var kin := Kinships.find(main)
	var reach := kin.get_reach() if kin else Kinships.REACH
	var mine := Kinships.branch_of(data)
	var count := 0
	for tower in _attackers():
		if tower == exclude or tower.tower_data.line != data.line:
			continue
		var theirs := Kinships.branch_for(tower)
		if theirs == "" or theirs == mine or (kin and not kin.get_pairs(tower).is_empty()):
			continue
		if Kinships._distance_to_cell(tower, cell) > reach:
			continue
		if mine == "" or Kinships.kinship_for(mine, theirs) != &"":
			count += 1
	return KIN_WEIGHT * mini(count, AURA_COUNT_MAX)

func _count_on_map(id: String) -> int:
	return _attackers().filter(func(t: Tower) -> bool: return t.tower_data.get_id() == id).size()

# --- Status strength and caps (Potency scales statuses, 87fb47fb) -------------------------------------
# One sample per active status: its strength (the strongest applier's Potency; 1.0 with the switch off)
# and whether its cap binds right now: Soaked's water bonus or Exposed's extra damage past +40%, a Hold
# lengthened to the 2 s cap. Shares are of sampled status-time, not of applications.
func _sample_statuses(statuses: EnemyStatuses) -> void:
	for id in [EnemyStatuses.DAMP, EnemyStatuses.MARKED, EnemyStatuses.DROWSY, EnemyStatuses.HELD, EnemyStatuses.SPORED, EnemyStatuses.STATIC]:
		if not statuses.has(id):
			continue
		var strength := statuses.strength(id)
		var capped := false
		match id:
			EnemyStatuses.DAMP:
				var base := EnemyStatuses.DAMP_WATER_BONUS * maxf(1.0, statuses.potency(EnemyStatuses.DAMP))
				capped = base * strength > maxf(EnemyStatuses.SOAKED_CAP, base)
			EnemyStatuses.MARKED:
				var extra := maxf(EnemyStatuses.MARKED_EXTRA, statuses.marked_extra) + statuses.marked_bonus
				capped = extra * strength > maxf(EnemyStatuses.EXPOSED_CAP, extra)
			EnemyStatuses.HELD:
				capped = Tower.status_potency_on and float(statuses._active.get(id, {}).get("full", 0.0)) >= EnemyStatuses.HELD_POTENCY_CAP - 0.001
		var bucket: Dictionary = status_samples.get_or_add(String(id), {"n": 0, "cap": 0, "strengths": []})
		bucket.n += 1
		if capped:
			bucket.cap += 1
		if bucket.strengths.size() < 20000:
			bucket.strengths.append(snappedf(strength, 0.01))

# status_<id>_n (samples), _cap (share at the cap), _med / _max (strength); dmg_tags ("tag:share+…", top 12).
func _status_columns() -> Dictionary:
	var columns := {}
	for id in ["damp", "marked", "drowsy", "held", "spored", "static"]:
		var bucket: Dictionary = status_samples.get(id, {"n": 0, "cap": 0, "strengths": []})
		var strengths: Array = bucket.strengths.duplicate()
		strengths.sort()
		columns["status_%s_n" % id] = bucket.n
		columns["status_%s_cap" % id] = snappedf(float(bucket.cap) / maxf(bucket.n, 1.0), 0.001)
		columns["status_%s_med" % id] = strengths[strengths.size() / 2] if not strengths.is_empty() else -1.0
		columns["status_%s_max" % id] = strengths[-1] if not strengths.is_empty() else -1.0
	var total := 0.0
	for tag in damage_by_tag:
		total += damage_by_tag[tag]
	var tags := damage_by_tag.keys()
	tags.sort_custom(func(a, b) -> bool: return damage_by_tag[a] > damage_by_tag[b])
	columns.dmg_tags = "+".join(tags.slice(0, 12).map(func(t) -> String: return "%s:%.3f" % [t, damage_by_tag[t] / maxf(total, 1.0)]))
	return columns

# --- Damage per Warden form (is a final an outlier per Warden, or just its family's strongest?) ------
# Split: combo = the part combos added; of the rest, cloud (tag "cloud"), status (status ticks and Static
# bolts) or hit. asleep = all damage onto a nightmare asleep at that moment.
func _note_form_damage(event) -> void:
	if not (is_instance_valid(event.source) and event.source is Tower):
		return
	var id: String = event.source.tower_data.get_id()
	var form: Dictionary = damage_by_form.get_or_add(id, {"total": 0.0, "hit": 0.0, "cloud": 0.0, "status": 0.0, "combo": 0.0, "asleep": 0.0})
	var amount: float = event.amount
	var combo := clampf(event.combo_amount, 0.0, amount)
	form.total += amount
	form.combo += combo
	if event.tag == &"cloud":
		form.cloud += amount - combo
	elif event.kind == &"status" or event.kind == &"bolt":
		form.status += amount - combo
	else:
		form.hit += amount - combo
	if is_instance_valid(event.enemy) and event.enemy.statuses.is_asleep():
		form.asleep += amount

# "id:share:count:hit:cloud:status:combo:asleep;…" by total damage: share of the run's Warden damage, the
# form's Wardens on the map at the end (0 = grown away / sold), then each part as a share of its own total.
func _form_column() -> String:
	var total := 0.0
	for id in damage_by_form:
		total += damage_by_form[id].total
	var ids := damage_by_form.keys()
	ids.sort_custom(func(a, b) -> bool: return damage_by_form[a].total > damage_by_form[b].total)
	var parts := []
	for id in ids:
		var form: Dictionary = damage_by_form[id]
		var t := maxf(form.total, 1.0)
		parts.append("%s:%.3f:%d:%.2f:%.2f:%.2f:%.2f:%.2f" % [id, form.total / maxf(total, 1.0), _count_on_map(id),
			form.hit / t, form.cloud / t, form.status / t, form.combo / t, form.asleep / t])
	return ";".join(parts)

# --- Route profiles (RunHistory d8010456: where nightmares die, where the Dew sits) -----------------
# Read from the run's own RunHistory node, so bot and human use the same code. Per block, ";"-separated:
# route_dispels "block:d0/…/d9:leaked", route_health "block:h0/…/h9:leaked_health",
# route_invested "block:i0/…/i9:off_route:heart_share" (bins = tenths of route progress, start → Heartwood).
func _route_columns() -> Dictionary:
	var history := main.get_tree().get_first_node_in_group(RunHistory.GROUP)
	var blocks: Array = history.run.get("route_blocks", []) if history != null and history.get("run") is Dictionary else []
	var join := func(values: Array) -> String: return "/".join(values.map(func(v) -> String: return str(v)))
	return {
		"route_dispels": ";".join(blocks.map(func(b) -> String: return "%d:%s:%d" % [b.block, join.call(b.dispels), b.leaked])),
		"route_health": ";".join(blocks.map(func(b) -> String: return "%d:%s:%d" % [b.block, join.call(b.dispel_health), b.leaked_health])),
		"route_invested": ";".join(blocks.map(func(b) -> String: return "%d:%s:%d:%.2f" % [b.block, join.call(b.invested), b.off_route, b.heart_share])),
	}

# One line per Dream offer in <out>/offers.csv: run, drift, each card offered as id:rarity, the card taken
# ("-" = let it pass) and the Entwined guaranteed card of the offer ("" = none; always "" since e328fb55 removed the slot, kept so before/after files line up). For pick-rate-when-offered.
func _log_pick(offer: Array, pick) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var path := out_dir.path_join("offers.csv")
	var new_file := not FileAccess.file_exists(path)
	var file := FileAccess.open(path, FileAccess.READ_WRITE if not new_file else FileAccess.WRITE)
	if file == null:
		return
	if new_file:
		file.store_line("profile,style,dreams,seed,drift,offered,taken,guaranteed")
	file.seek_end()
	var cards := "+".join(offer.map(func(c: UpgradeData) -> String: return "%s:%d" % [c.id, c.rarity]))
	file.store_line("%s,%s,%s,%d,%d,%s,%s,%s" % [profile, style, dream_mode, map_seed, director.drifts_started, cards,
		pick.id if pick != null else "-", str(dreams.get("_guaranteed_id")) if dreams.get("_guaranteed_id") != null else ""])
	file.close()
