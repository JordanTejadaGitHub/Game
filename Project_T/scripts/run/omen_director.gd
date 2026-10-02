extends Node
class_name OmenDirector

# Omens (documentation/run_design.md): at every rest from drift `first_rest_drift` on, after the
# Dream: face an Omen blind or keep Clear Skies (run_design.md "Commit blind, then the Omen is
# revealed"). Facing it reveals `omens_per_offer` Omens (2; Omen Reader 3) for the next block (5 drifts);
# pick one (no going back to Clear Skies) for its reward; Clear Skies changes nothing. The reward is paid at the rest after that block
# (or when the run is won during it), as long as the Heartwood is still standing.
# DriftDirector asks this node for the active Omen's multipliers; bosses ignore them.

const GROUP := &"omens"
const OMEN_DIR := "res://resource/omen/"
const ACT_REWARD_SCALE := [1.0, 1.5, 2.0, 2.5]  # Dew and Seed rewards, by act
const TREE := preload("res://resource/obstacle/tree.tres")  # Shifting Ground's sprouts
const RENAMED := {"harvest_moon": "bountiful_night"}  # Old Omen ids in saved runs

# The Omens for block `block` (drifts first..last) are ready; the Omen screen pauses and shows them.
signal offer_ready(omens: Array[OmenData], block: int)
signal offer_closed
signal omen_started(omen: OmenData, first_drift: int, last_drift: int)
# `summary`: what the reward gave, e.g. "+60 Dew, regrow 2 leaves".
signal omen_rewarded(omen: OmenData, summary: String)
# Second Path crumbled a Thornwall (Fx / Sound / toast).
signal thornwall_crumbled(position: Vector2, refund: int)

@export var pool: Array[OmenData] = []  # Empty = every Omen in res://resource/omen/
@export var first_rest_drift: int = 10
@export var omens_per_offer: int = 2  # Omens revealed on facing (Omen Reader: +1, MetaRun)

const MODE_SETTING := "omens"  # Settings > Gameplay: "ask" (default) or "never"
var force_omen := false  # Blight Levels that force an Omen: only the two Omen cards, no Clear Skies
var mode_override := ""  # Tests and tools: "ask" / "never" instead of the player's setting
var showing := false  # The Omen screen is open
var forced := false  # The open offer can't be declined ("An Omen must be faced")
var faced := false  # Face an Omen was chosen: its Omens are shown, one must be picked (saved)

var active: OmenData = null
var active_block := 0  # The block `active` twists
var current_offer: Array[OmenData] = []
var current_offer_block := 0

var _offer_waiting := false  # An offer is ready but waits for the Dream screen to close
var _last_offer_ids: Array[String] = []  # The previous rest's Omens (never offered twice in a row)
var tree_seed_bonus := 0  # Shifting Ground's reward: extra Seeds per Withered Tree cleared
var _sprouted_block := 0  # The block Shifting Ground already sprouted its trees in
var _crumbled_block := 0  # The block Second Path already crumbled its Thornwall in
var locked_cells: Array[Vector2] = []  # Second Path: no planting here until the next rest (TowerPlacer asks is_cell_locked)
var _leaves_lost_at_start := 0  # RunState.leaves_lost when the active Omen was picked (the reward scales with the block's losses)
var _rng := RandomNumberGenerator.new()

@onready var drift_director: DriftDirector = %DriftDirector
@onready var run_state: RunState = %RunState
@onready var dream_state: DreamState = %DreamState

func _ready() -> void:
	add_to_group(GROUP)
	_rng.randomize()
	if pool.is_empty():
		pool = load_pool()
	drift_director.rest_started.connect(_on_rest_started)
	dream_state.offer_closed.connect(_try_show.call_deferred)
	run_state.run_ended.connect(_on_run_ended)
	drift_director.drift_started.connect(_on_drift_started)
	var map_generator = get_node_or_null("%MapGenerator")
	if map_generator:
		map_generator.obstacle_cleared.connect(_on_obstacle_cleared)

static func load_pool() -> Array[OmenData]:
	var omens: Array[OmenData] = []
	for file in ResourceLoader.list_directory(OMEN_DIR):
		if file.ends_with(".tres") or file.ends_with(".res"):
			var omen := load(OMEN_DIR + file) as OmenData
			if omen != null:
				omens.append(omen)
	return omens


# --- Queries (DriftDirector, UI) -------------------------------------------------------------------

# The Omen screen is open (after the Dream, like it: two Omens and Clear Skies; pauses).
func is_offering() -> bool:
	return showing and not current_offer.is_empty()

# An offer is drawn and waits for the Dream screen to close (DriftDirector.pending_choice: Start waits).
func has_pending_offer() -> bool:
	return _offer_waiting and not current_offer.is_empty()

# "ask" (the Omen screen each Omen rest, the default) or "never" (always Clear Skies, no screen).
func get_mode() -> String:
	if mode_override != "":
		return mode_override
	return str(HeartwoodMemory.get_settings().get(MODE_SETTING, "ask"))

func _show_cards() -> void:
	showing = true
	offer_ready.emit(current_offer, current_offer_block)

# First and last drift of block `block`.
func get_block_range(block: int) -> Vector2i:
	var per_block := drift_director.drifts_per_block
	return Vector2i((block - 1) * per_block + 1, mini(block * per_block, drift_director.get_total_drifts()))

func is_active_for(drift_number: int) -> bool:
	return active != null and drift_director.get_block(drift_number) == active_block

# One of OmenData's next-block multipliers (by property name) for drift `drift_number`.
func get_multiplier(drift_number: int, property: String) -> float:
	return float(active.get(property)) if is_active_for(drift_number) else 1.0

func get_schedule_modifiers(drift_number: int) -> Dictionary:
	if not is_active_for(drift_number):
		return {}
	return {"count": active.count_multiplier, "flyers": active.flyer_count_multiplier,
		"spacing": active.arrival_spacing_multiplier}

# The Dew pot (run_design.md "The Dew pot"): the active Omen multiplies drift `number`'s pot (Bountiful Night ×2,
# Blood Moon ×1.75, Dry Spell ×0). Added nightmares (Crowded Paths, Elder Night…) share the pot, so they add nothing.
func get_dew_pot_multiplier(number: int) -> float:
	return pot_factor(active, number) if is_active_for(number) else 1.0

# How much `omen` multiplies drift `number`'s pot. Bosses ignore Omens, so on a boss drift only the escorts' half of the
# pot (DriftDirector.POT_BOSS_SHARE to the boss) is touched.
func pot_factor(omen: OmenData, number: int) -> float:
	var m := omen.creature_dew_multiplier
	if drift_director.is_boss_drift(number):
		return 1.0 + (m - 1.0) * (1.0 - DriftDirector.POT_BOSS_SHARE)
	return m

# The block's pot with the player's own multipliers (Rich Dew, Morning Dew, Blight; never the Omen) and with the Omen
# on top: [without, with]. Drifts already started use what they really had (called early or not).
func block_pots(omen: OmenData, block: int) -> Array:
	var without := 0.0
	var with := 0.0
	var drifts := get_block_range(block)
	for number in range(drifts.x, drifts.y + 1):
		var base: float = _player_pot.get(number, drift_director.get_dew_pot(number) * drift_director.get_dew_pot_multiplier(number, false, false))
		without += base
		with += base * pot_factor(omen, number)
	return [without, with]

# Blood Moon / Bountiful Night: the extra Dew over the block (user: "should calculate how much Dew would come from the
# Omen"), rounded to the nearest 5.
func estimate_extra_dew(omen: OmenData, block: int) -> int:
	if block <= 0:
		return 0
	var pots := block_pots(omen, block)
	return roundi((pots[1] - pots[0]) / 5.0) * 5

# The extra Dew the active Omen's block has paid so far: the pot dispelled this block, less what it'd be without it.
func extra_dew_so_far() -> int:
	if active == null or active_block <= 0:
		return 0
	var pots := block_pots(active, active_block)
	if pots[1] <= 0.0:
		return 0
	return floori(run_state.pot_earned_block * (1.0 - pots[0] / pots[1]))

var _player_pot := {}  # Drift number -> its pot with the player's own multipliers, recorded as it starts (saved)

func all_omens() -> Array[OmenData]:
	return pool

# Per-creature multipliers (see Enemy.modifiers). Callers leave bosses out.
func get_spawn_modifiers(drift_number: int) -> Dictionary:
	if not is_active_for(drift_number):
		return {}
	var modifiers := {"speed": active.speed_multiplier, "omen_speed": active.speed_multiplier, "coat": active.coat_multiplier,
		"status_duration": active.status_duration_multiplier}  # Dew: the pot (get_dew_pot_multiplier), never per nightmare
	# omen_speed: the Omen's share of "speed" (DriftDirector folds Dreams and Blight into it); Magpies strip it.
	if not active.status_immune.is_empty():
		modifiers["status_immune"] = active.status_immune  # Sleepless (Enemy Code adds them)
	if active.always_status != &"":
		modifiers["always_status"] = active.always_status  # Heavy Rain: always Soaked (Enemy Code)
	if active.trample_thornwall:
		modifiers["tramples_thornwall"] = true  # Tramplers (Enemy Code): ask claim_trample() before trampling
	if active.burrow_tiles > 0:
		modifiers["burrow_tiles"] = active.burrow_tiles  # Burrowers (Enemy Code): at every bend, untargetable for burrow_time
		modifiers["burrow_time"] = active.burrow_time
	return modifiers

# Tramplers: only the first nightmare each drift tramples a Thornwall. True once per drift (the caller tramples).
var _trampled_drift := 0

func claim_trample(drift_number: int) -> bool:
	if not is_active_for(drift_number) or not active.trample_thornwall or _trampled_drift == drift_number:
		return false
	_trampled_drift = drift_number
	return true

# The reward line for `omen` when paid in `act`, e.g. "+60 Dew · next Dream offers 4 cards".
# `rest_bonus` >= 0: the rest bonus it multiplies is known, so show the extra Dew instead of "×2".
# `lost` >= 0: what a block with that many leaves lost paid (scaled, with why); -1: the full promise.
func describe_reward(omen: OmenData, act: int, rest_bonus: int = -1, lost: int = -1, block: int = 0) -> String:
	var parts: Array[String] = []
	var scale := _act_scale(act)
	var share := 1.0
	var dreams := true
	if lost >= 0 and not is_dew_prize(omen):
		share = clampf(1.0 - REWARD_CUT_PER_LEAF * lost, 0.0, 1.0)
		dreams = lost <= DREAM_REWARD_MAX_LOST
	var dew := floori((roundi(omen.reward_dew * scale) + get_pot_reward(omen, block)) * share)
	if dew > 0:
		parts.append("+%d Dew" % dew)
	elif omen.reward_pot_multiplier > 0.0 and block <= 0:  # Dry Spell before its block is known
		parts.append("the block's Dew back, and a quarter more")
	var seeds := floori(roundi(omen.reward_seeds * scale) * share)
	if seeds > 0:
		parts.append("+%d Seeds" % seeds)
	var max_leaves := floori(omen.reward_max_leaves * share)
	if max_leaves > 0:
		parts.append("+%d max %s" % [max_leaves, "leaf" if max_leaves == 1 else "leaves"])
	if omen.reward_rare_dreams > 0 and dreams:
		parts.append("a Rare+ card in the next Dream")
	if omen.reward_extra_dream_cards > 0 and dreams:
		parts.append("next Dream offers %d cards" % maxi(dream_state.cards_per_offer,
			mini(dream_state.cards_per_offer + omen.reward_extra_dream_cards, DreamState.MAX_OFFER_CARDS)))
	if omen.reward_rest_bonus_multiplier > 1.0:
		if rest_bonus >= 0:
			var extra := floori(_extra_rest_bonus(omen, rest_bonus) * share)
			if extra > 0:
				parts.append("rest bonus +%d Dew" % extra)
		else:
			parts.append("rest bonus ×%s" % str(omen.reward_rest_bonus_multiplier).trim_suffix(".0"))
	var dreamlight := floori(floori(omen.reward_dreamlight * scale) * share)  # By act: +1 / +1 / +2 / +2
	if dreamlight > 0:
		parts.append("+%d Dreamlight" % dreamlight)
	if omen.reward_legendary and dreams:
		parts.append("next Dream includes a Legendary")
	var tree_seeds := floori(omen.reward_tree_seeds * share)
	if tree_seeds > 0:
		parts.append("Withered Trees you clear this run give %d Seeds (not 1)" % (1 + tree_seeds))
	var text := " · ".join(parts)
	if lost > 0 and not is_dew_prize(omen):  # Why it's less (the rest report and toast show it)
		var why := "%d %s lost" % [lost, "leaf" if lost == 1 else "leaves"]
		text = ("%s (%d%%: %s)" % [text, roundi(share * 100), why]) if text != "" else "nothing (%s)" % why
	return text

# Plain words for the reward (user: "what does 25% less per leaf lost mean"), shared by the Omen card, the active
# tag and (paid_sentence) the rest report: "Reward: +40 Dew. Each leaf you lose in these drifts takes a quarter of
# it." / "Reward: your next Dream offers 5 cards, if you lose at most 1 leaf in these drifts." / double-edged "No
# other reward: the extra Dew is the prize." REWARD_RULE is the full rule (the line's hover / tap).
const REWARD_RULE := "Lose no leaf in the Omen's drifts and its reward is yours in full. Each leaf lost takes a quarter of its Dew and Seeds away (4 leaves: nothing). A Dream reward stays only if you lose at most 1 leaf."
const DOUBLE_EDGED_LINE := "No other reward: the extra Dew is the prize."

# An Omen whose only prize is the extra Dew from its nightmares (Blood Moon, Bountiful Night: creature Dew above ×1 and no
# reward of its own). Their twist is the reward: no reward bullets, never cut by leaves. A double-edged Omen with its own
# reward (Heavy Rain's +45 Dew) lists and cuts it like any other.
static func is_dew_prize(omen: OmenData) -> bool:
	if omen == null or omen.creature_dew_multiplier <= 1.0:
		return false
	return omen.reward_dew <= 0 and omen.reward_seeds <= 0 and omen.reward_tree_seeds <= 0 and omen.reward_rare_dreams <= 0 \
		and omen.reward_extra_dream_cards <= 0 and not omen.reward_legendary and omen.reward_pot_multiplier <= 0.0 \
		and omen.reward_rest_bonus_multiplier <= 1.0 and omen.reward_dreamlight <= 0 and omen.reward_max_leaves <= 0

func reward_sentence(omen: OmenData, act: int, block: int = 0) -> String:
	if is_dew_prize(omen):
		return ("Reward: about +%d extra Dew over these drifts." % estimate_extra_dew(omen, block)) if block > 0 else DOUBLE_EDGED_LINE
	var parts := _reward_parts(omen, act, block, 1.0, true)
	var scaled: Array = parts[0]
	var dream: Array = parts[1]
	if scaled.is_empty() and dream.is_empty():
		return ""
	var minus := per_leaf_text(omen, act, block)  # "minus 10" (user: the concrete number, not "a quarter")
	var cut := ("%s for each leaf you lose" % minus) if minus != "" else "less for each leaf you lose"
	if dream.is_empty():
		return "Reward: %s, %s in these drifts." % [_and(scaled), cut]
	if scaled.is_empty():
		return "Reward: %s, if you lose at most 1 leaf in these drifts." % _and(dream)
	return "Reward: %s, %s, and %s if you lose at most 1 leaf." % [_and(scaled), cut, _and(dream)]

# "minus 10" (Dew only), "minus 10 Dew and 1 Seed" (both): a quarter of the act-scaled reward, rounded down; "" when
# there's no number to cut (Dry Spell before its block is known, tree Seeds only).
func per_leaf_text(omen: OmenData, act: int, block: int = 0) -> String:
	var scale := _act_scale(act)
	var dew := floori((roundi(omen.reward_dew * scale) + get_pot_reward(omen, block)) * REWARD_CUT_PER_LEAF)
	var seeds := floori(roundi(omen.reward_seeds * scale) * REWARD_CUT_PER_LEAF)
	if dew > 0 and seeds > 0:
		return "minus %d Dew and %d %s" % [dew, seeds, "Seed" if seeds == 1 else "Seeds"]
	if dew > 0:
		return "minus %d" % dew
	if seeds > 0:
		return "minus %d" % seeds
	return ""

# The Omen card's reward bullets (user: "point form for each different reward given on the single card"), each with
# its own condition: "+40 Dew, minus 10 for each leaf you lose", "Next Dream offers 4 cards, if you lose at most 1
# leaf", "A Rare+ card in your next Dream, if you lose at most 1 leaf"; double-edged: "The extra Dew is the prize".
func reward_bullets(omen: OmenData, act: int, block: int = 0) -> Array[String]:
	var bullets: Array[String] = []
	if is_dew_prize(omen):  # The computed extra Dew (user: "should calculate how much Dew would come from the Omen")
		bullets.append("About +%d extra Dew over these drifts" % estimate_extra_dew(omen, block) if block > 0 else "Extra Dew from every nightmare")
		return bullets
	var scale := _act_scale(act)
	var keep := ", if you lose at most 1 leaf"
	var dew := roundi(omen.reward_dew * scale) + get_pot_reward(omen, block)
	if dew > 0:
		var cut := floori(dew * REWARD_CUT_PER_LEAF)
		bullets.append("+%d Dew%s, %s for each leaf you lose" % [dew, " at the rest" if omen.reward_pot_multiplier > 0.0 else "",
			"minus %d" % cut if cut > 0 else "less"])
	elif omen.reward_pot_multiplier > 0.0:
		bullets.append("The block's Dew back, and a quarter more, less for each leaf you lose")
	var seeds := roundi(omen.reward_seeds * scale)
	if seeds > 0:
		var seed_cut := floori(seeds * REWARD_CUT_PER_LEAF)
		bullets.append("+%d Seeds, %s for each leaf you lose" % [seeds, "minus %d" % seed_cut if seed_cut > 0 else "less"])
	if omen.reward_tree_seeds > 0:
		bullets.append("%d Seeds for every Withered Tree you clear this run, less for each leaf you lose" % (1 + omen.reward_tree_seeds))
	var cards := maxi(dream_state.cards_per_offer, mini(dream_state.cards_per_offer + omen.reward_extra_dream_cards, DreamState.MAX_OFFER_CARDS))
	if omen.reward_extra_dream_cards > 0:
		bullets.append("Next Dream offers %d cards%s%s" % [cards, ", one of them Rare+" if omen.reward_rare_dreams > 0 else "", keep])
	elif omen.reward_rare_dreams > 0:
		bullets.append("A Rare+ card in your next Dream" + keep)
	if omen.reward_legendary:
		bullets.append("A Legendary in your next Dream" + keep)
	return bullets

# The live amount for the compact tag ("+30 Dew"), "" when the reward has no amount (Dream rewards, double-edged).
func live_reward_text() -> String:
	if active == null:
		return ""
	if is_dew_prize(active):  # "+120 of ~310": the extra Dew earned so far, of the estimate
		return "+%d of ~%d" % [extra_dew_so_far(), estimate_extra_dew(active, active_block)]
	var parts := _reward_parts(active, drift_director.get_act(maxi(drift_director.drifts_started, 1)), active_block,
		get_reward_share(), true)
	var scaled: Array = parts[0]
	return scaled[0] if not scaled.is_empty() and String(scaled[0]).begins_with("+") else ""

# What a block with `lost` leaves lost paid, in the same words (the rest report and the toast): "Reward: +30 Dew
# (1 leaf lost).", "No reward: 4 leaves lost.", "… The Dream reward is gone."
func paid_sentence(omen: OmenData, act: int, rest_bonus: int, lost: int, block: int) -> String:
	if is_dew_prize(omen):  # What the block really paid on top (the pot earned, less what it'd be without the Omen)
		var pots := block_pots(omen, block)
		var extra := floori(run_state.pot_earned_block * (1.0 - pots[0] / pots[1])) if pots[1] > 0.0 else 0
		return "+%d extra Dew" % extra
	var share := clampf(1.0 - REWARD_CUT_PER_LEAF * lost, 0.0, 1.0)
	var parts := _reward_parts(omen, act, block, share, lost <= DREAM_REWARD_MAX_LOST, rest_bonus)
	var got: Array = parts[0] + parts[1]
	var why := "%d %s lost" % [lost, "leaf" if lost == 1 else "leaves"]
	var lost_dream: bool = not parts[2].is_empty() and lost > DREAM_REWARD_MAX_LOST
	if got.is_empty():
		return "No reward: %s." % why if lost > 0 else "No reward."
	var text := "Reward: %s%s." % [_and(got), (" (%s)" % why) if lost > 0 else ""]
	if lost_dream:
		text += " The Dream reward is gone."
	return text

static func _taken(share: float) -> String:
	match roundi((1.0 - share) * 4.0):
		1: return "a quarter"
		2: return "half"
		3: return "three quarters"
	return "all of it"

static func _and(items: Array) -> String:
	if items.size() <= 1:
		return "".join(items)
	return ", ".join(items.slice(0, items.size() - 1)) + " and " + items[-1]

# [scaled parts (Dew, Seeds…), Dream parts kept, Dream parts promised, nothing scaled to cut] in plain words.
func _reward_parts(omen: OmenData, act: int, block: int, share: float, dreams: bool, rest_bonus: int = -1) -> Array:
	var scale := _act_scale(act)
	var scaled: Array = []
	var dream_all: Array = []
	var dew := floori((roundi(omen.reward_dew * scale) + get_pot_reward(omen, block)
		+ (_extra_rest_bonus(omen, rest_bonus) if rest_bonus >= 0 and omen.reward_rest_bonus_multiplier > 1.0 else 0)) * share)
	if dew > 0:
		scaled.append("+%d Dew" % dew)
	elif omen.reward_pot_multiplier > 0.0 and block <= 0:
		scaled.append("the block's Dew back, and a quarter more")
	var seeds := floori(roundi(omen.reward_seeds * scale) * share)
	if seeds > 0:
		scaled.append("+%d Seeds" % seeds)
	var tree_seeds := floori(omen.reward_tree_seeds * share)
	if tree_seeds > 0:
		scaled.append("%d Seeds for every Withered Tree you clear this run (not 1)" % (1 + tree_seeds))
	var cards := maxi(dream_state.cards_per_offer, mini(dream_state.cards_per_offer + omen.reward_extra_dream_cards, DreamState.MAX_OFFER_CARDS))
	if omen.reward_extra_dream_cards > 0 and omen.reward_rare_dreams > 0:
		dream_all.append("your next Dream offers %d cards, one of them Rare+" % cards)
	elif omen.reward_extra_dream_cards > 0:
		dream_all.append("your next Dream offers %d cards" % cards)
	elif omen.reward_rare_dreams > 0:
		dream_all.append("a Rare+ card in your next Dream")
	if omen.reward_legendary:
		dream_all.append("a Legendary in your next Dream")
	var nothing_scaled := omen.reward_dew <= 0 and omen.reward_seeds <= 0 and omen.reward_tree_seeds <= 0 \
		and omen.reward_pot_multiplier <= 0.0 and omen.reward_rest_bonus_multiplier <= 1.0
	return [scaled, dream_all if dreams else [], dream_all, nothing_scaled]

func _extra_rest_bonus(omen: OmenData, rest_bonus: int) -> int:
	return roundi(rest_bonus * (omen.reward_rest_bonus_multiplier - 1.0))


# --- Offers ----------------------------------------------------------------------------------------

# The Omens drawn for block `block`: `omens_per_offer` random ones that make sense there (hidden until
# faced).
# Never an Omen from the previous rest, and the Omens are of different kinds (run_design.md
# "More Omens"; if there aren't enough kinds, the rest fill in).
func make_offer(block: int) -> Array[OmenData]:
	var drifts := get_block_range(block)
	var eligible: Array[OmenData] = []
	for omen in pool:
		if omen.waiting_for_hook or omen.min_drift > drifts.x or _last_offer_ids.has(omen.id):
			continue
		if omen.requires_flyers and not _block_has_flyers(drifts):
			continue
		if omen.requires_coat and not _block_has_coat(drifts):
			continue
		if omen.requires_legendary and not dream_state.has_legendary_left():
			continue
		if omen.requires_clearing and not dream_state.can_clear():
			continue
		if omen.never_before_boss and range(drifts.x, drifts.y + 1).any(func(n: int) -> bool: return drift_director.is_boss_drift(n)):
			continue  # Leaf Fall: never the block with a boss in it
		if omen.needs_free_cells > 0 and get_free_cells(omen.sprouts_beside_path).size() < omen.needs_free_cells:
			continue
		if omen.crumble_thornwall and second_path_target() == null:
			continue  # Second Path needs a Thornwall that lengthens the route
		eligible.append(omen)
	# Shuffle with our own RNG so a resumed run offers the same Omens.
	for i in range(eligible.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var swap := eligible[i]
		eligible[i] = eligible[j]
		eligible[j] = swap
	var offer: Array[OmenData] = []
	var kinds := {}
	for omen in eligible:
		if offer.size() < omens_per_offer and not kinds.has(omen.kind):
			offer.append(omen)
			kinds[omen.kind] = true
	for omen in eligible:
		if offer.size() < omens_per_offer and not offer.has(omen):
			offer.append(omen)
	_last_offer_ids.assign(offer.map(func(o: OmenData) -> String: return o.id))
	return offer

# --- Next-block rules other scripts ask (Tower, TowerPlacer, RunState, DriftDirector) --------------

# The Omen twisting the drift being played now (null = none).
func current() -> OmenData:
	return active if is_active_for(drift_director.drifts_started) else null

# Fog Bank: range added to every Warden (Tower keeps at least 1).
func get_warden_range_add() -> float:
	var omen := current()
	return omen.warden_range_add if omen else 0.0

# Wilting: every Warden's attack speed ×.
func get_warden_speed_multiplier() -> float:
	var omen := current()
	return omen.warden_attack_speed_multiplier if omen else 1.0

# Frozen Ground: no planting or growing while a drift is on (rests are fine).
func blocks_building() -> bool:
	var omen := current()
	return omen != null and omen.no_build_during_drift and not drift_director.resting

# Leaf Fall: leaks cost this many times the leaves (bosses too).
func get_leak_multiplier() -> float:
	var omen := current()
	return omen.leak_multiplier if omen else 1.0

# Elder Night and Hollow Wind reshape a drift's schedule ([[time, EnemyData, elite], …]); DriftDirector
# calls this when the drift starts. Bosses are never touched.
func shape_schedule(schedule: Array, number: int) -> void:
	if not is_active_for(number):
		return
	var first := get_block_range(active_block).x
	if active.all_flyer_drifts > 0 and number - first < active.all_flyer_drifts:
		var flyers := _block_flyers(get_block_range(active_block))
		if not flyers.is_empty():
			for arrival in schedule:
				if not arrival[1].is_boss and arrival[1].trait_kind != EnemyData.Trait.FLYING:
					arrival[1] = flyers[_rng.randi_range(0, flyers.size() - 1)]
	for n in active.extra_elites:
		var candidates: Array = []
		for i in schedule.size():
			if not schedule[i][1].is_boss and not (schedule[i].size() > 2 and schedule[i][2]):
				candidates.append(i)
		if candidates.is_empty():
			break
		var index: int = candidates[_rng.randi_range(0, candidates.size() - 1)]
		if schedule[index].size() > 2:
			schedule[index][2] = true
		else:
			schedule[index].append(true)

# Cells a tree could sprout on: buildable, no obstacle or Warden, and nothing of the route in the 8
# around it (so a sprout never changes the route). `beside_path` (Shifting Ground): right beside the route
# too, never on it; the sprout still checks can_block.
func get_free_cells(beside_path: bool = false) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var map_generator = get_node_or_null("%MapGenerator")
	if map_generator == null:
		return result
	var route := {}
	for cell in map_generator.get_path_from(map_generator.startPath):
		route[cell] = true
	var seller = get_node_or_null("%TowerSeller")
	var size: Vector2 = map_generator.MAP_GRID.size
	for x in range(1, int(size.x) - 1):
		for y in range(1, int(size.y) - 1):
			var cell := Vector2(x, y)
			if not map_generator.is_buildable(cell) or map_generator.obstacles.has(cell):
				continue
			if seller and seller.get_tower_at(cell) != null:
				continue
			if beside_path:
				if not route.has(cell):
					result.append(cell)
				continue
			var near_route := false
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					if route.has(cell + Vector2(dx, dy)):
						near_route = true
			if not near_route:
				result.append(cell)
	return result

# Second Path: the Thornwall whose removal shortens the route most (null = none shortens it).
func second_path_target() -> Tower:
	var map_generator = get_node_or_null("%MapGenerator")
	var towers = get_node_or_null("%TowerContainer")
	if map_generator == null or towers == null:
		return null
	var best: Tower = null
	var best_length: int = map_generator.get_path_from(map_generator.startPath).size()
	for tower in towers.get_children():
		if not (tower is Tower) or tower.is_queued_for_deletion() or tower.tower_data.get_id() != "thornwall":
			continue
		var length: int = map_generator.get_path_if_cleared(tower.cell).size()
		if length > 0 and length < best_length:
			best_length = length
			best = tower
	return best

# Second Path: no planting on these cells until the next rest (TowerPlacer asks).
func is_cell_locked(cell: Vector2) -> bool:
	return locked_cells.has(cell)

# Second Path at the block's start: the Thornwall crumbles, its Dew comes back in full, its cell locks.
func _crumble_thornwall() -> void:
	var tower := second_path_target()
	if tower == null:
		return
	var map_generator = get_node("%MapGenerator")
	var seller = get_node_or_null("%TowerSeller")
	var refund: int = tower.invested_dew
	var cells: Array = tower.get_cells()
	tower.get_parent().remove_child(tower)
	tower.queue_free()
	for c in cells:
		map_generator.unblock_cell(c)  # Re-routes the nightmares
		locked_cells.append(c)
	run_state.earn_dew_at(refund, tower.position)
	if seller:
		seller.tower_sold.emit(tower, refund)  # Selection, RunHistory and Sound see it as a sale
	thornwall_crumbled.emit(tower.position, refund)

# Shifting Ground: Withered Trees sprout on free cells at the start of its block (once).
# Second Path: its Thornwall crumbles at the start of its block (once).
func _on_drift_started(number: int) -> void:
	if is_active_for(number) and active.reward_pot_multiplier > 0.0:
		# Only what Dry Spell held back (a boss's half of its pot is never touched)
		_withheld[number] = drift_director.get_dew_pot(number) \
			* drift_director.get_dew_pot_multiplier(number, drift_director.is_calling_early(), false) * (1.0 - pot_factor(active, number))
	if is_active_for(number):
		_player_pot[number] = drift_director.get_dew_pot(number) * drift_director.get_dew_pot_multiplier(number, drift_director.is_calling_early(), false)
	if is_active_for(number) and active.crumble_thornwall and _crumbled_block != active_block:
		_crumbled_block = active_block
		_crumble_thornwall()
	if not is_active_for(number) or active.sprout_obstacles <= 0 or _sprouted_block == active_block:
		return
	_sprouted_block = active_block
	var map_generator = get_node_or_null("%MapGenerator")
	var cells := get_free_cells(active.sprouts_beside_path)
	for i in active.sprout_obstacles:
		while not cells.is_empty():
			var cell: Vector2 = cells.pop_at(_rng.randi_range(0, cells.size() - 1))
			if map_generator.can_block(cell):
				map_generator.place_obstacle(cell, TREE)
				break

# Shifting Ground's reward: every Withered Tree cleared from then on gives extra Seeds (not Burn Back's).
func _on_obstacle_cleared(_cell: Vector2, data: ObstacleData) -> void:
	if tree_seed_bonus > 0 and data == TREE and not run_state.clearing_without_seeds:
		run_state.omen_seeds += tree_seed_bonus

# Face an Omen: the drawn Omens are revealed and one must be picked (no going back to Clear Skies).
# Returns them ([] = nothing drawn).
func face() -> Array[OmenData]:
	if current_offer.is_empty():
		return []
	faced = true
	return current_offer

# Picks `omen` (one of the revealed Omens) for the offered block, or null = Clear Skies (its card,
# Esc, right-click; never once faced or when an Omen is forced). Tests and sims pick directly.
func choose(omen: OmenData) -> void:
	if current_offer.is_empty() or (omen != null and not current_offer.has(omen)) or (omen == null and (forced or faced)):
		return
	if omen != null:
		active = omen
		active_block = current_offer_block
		_leaves_lost_at_start = run_state.leaves_lost
		_withheld.clear()
		_player_pot.clear()
		var drifts := get_block_range(active_block)
		omen_started.emit(omen, drifts.x, drifts.y)
	current_offer = []
	faced = false
	var was_showing := showing
	showing = false
	forced = false
	if was_showing:
		offer_closed.emit()

func _on_rest_started(block: int, _is_boss_rest: bool, bonus: int, _perfect: bool) -> void:
	locked_cells.clear()  # Second Path: the rest settles its ground
	# Pay first, so "next Dream" rewards count for this rest's Dream (its offer is built deferred).
	if active != null and active_block == block:
		_pay_reward(bonus)
	if drift_director.drifts_started < first_rest_drift or not drift_director.has_next_drift() or run_state.is_over:
		return
	var offer := make_offer(block + 1)
	if offer.is_empty():
		return
	current_offer = offer
	current_offer_block = block + 1
	_offer_waiting = true
	_try_show.call_deferred()

# The Omen screen comes after the Dream.
func _try_show() -> void:
	if not _offer_waiting or dream_state.is_offering() or dream_state.has_pending_offer():
		return
	_offer_waiting = false
	if force_omen:  # A Blight Level: the cards at once, and one must be taken
		forced = true
		_show_cards()
	elif get_mode() == "never":
		current_offer = []  # Always Clear Skies, no screen
	else:
		_show_cards()  # Face an Omen (face-down) or Clear Skies

# Omens with teeth (run_design.md): the reward depends on the block. A clean block (no leaf lost in the Omen's
# drifts) pays it all, each leaf lost cuts it by 25%, 4+ pays nothing; Dream rewards (Rare+, extra cards,
# a Legendary) stay with at most 1 leaf lost. Double-edged Omens are their own reward (unchanged).
const REWARD_CUT_PER_LEAF := 0.25
const DREAM_REWARD_MAX_LOST := 1

# Leaves lost since the active Omen was picked (a boss leak counts as its leaves; 0 with no Omen).
func leaves_lost_in_block() -> int:
	return maxi(run_state.leaves_lost - _leaves_lost_at_start, 0) if active != null else 0

# The share of the active Omen's reward a rest now would pay: 1.0, 0.75, 0.5, 0.25, then 0.
func get_reward_share(lost: int = -1) -> float:
	if active != null and is_dew_prize(active):
		return 1.0
	if lost < 0:
		lost = leaves_lost_in_block()
	return clampf(1.0 - REWARD_CUT_PER_LEAF * lost, 0.0, 1.0)

func keeps_dream_reward(lost: int = -1) -> bool:
	if active != null and is_dew_prize(active):
		return true
	return (leaves_lost_in_block() if lost < 0 else lost) <= DREAM_REWARD_MAX_LOST

# Where the active Omen's reward stands now, for the tag's tooltip ("" with no Omen or a double-edged one):
# "You'd get it all right now." / "You'd get 75% right now: 1 leaf lost." (+ "The Dream reward is gone.")
func get_reward_status() -> String:
	if active == null or is_dew_prize(active):
		return ""
	var lost := leaves_lost_in_block()
	if lost == 0:
		return "You'd get it all right now."
	var share := get_reward_share(lost)
	var why := "%d %s lost" % [lost, "leaf" if lost == 1 else "leaves"]
	var text := ("You'd get nothing right now: %s." % why) if share <= 0.0 else ("You'd get %d%% right now: %s." % [roundi(share * 100), why])
	if not keeps_dream_reward(lost) and _has_dream_reward(active):
		text += " The Dream reward is gone."
	return text

# The tag's plain reward line: "Reward: +1 Dreamlight, less for each leaf lost" ("" for a double-edged Omen).
func get_reward_line() -> String:
	if active == null:
		return ""
	return reward_sentence(active, drift_director.get_act(maxi(drift_director.drifts_started, 1)), active_block)

static func _has_dream_reward(omen: OmenData) -> bool:
	return omen.reward_rare_dreams > 0 or omen.reward_extra_dream_cards > 0 or omen.reward_legendary

# This run's Omen tally (balance sim, run report): blocks paid, the reward shares they paid, leaves lost in
# Omen blocks and Dew paid.
var stats := {"paid": 0, "share": 0.0, "leaves_lost": 0, "dew": 0}

# Dry Spell: the block's base Dew pot (the drifts' pots before any multiplier) × reward_pot_multiplier, 0 for other
# Omens or an unknown block. The leaves-lost share is applied by the caller.
func get_pot_reward(omen: OmenData, block: int) -> int:
	if omen.reward_pot_multiplier <= 0.0 or block <= 0:
		return 0
	var drifts := get_block_range(block)
	var pot := 0.0
	for number in range(drifts.x, drifts.y + 1):
		# Started: what it would really have paid (the player's own multipliers, called early or not); still to come:
		# today's multipliers, not called early. Never Dry Spell's own ×0.
		pot += _withheld.get(number, drift_director.get_dew_pot(number) * drift_director.get_dew_pot_multiplier(number, false, false)
			* (1.0 - pot_factor(omen, number)))  # What it holds back (a boss's half never)
	return roundi(pot * omen.reward_pot_multiplier)

# Dry Spell: each of its drifts' real pot without the Omen (Rich Dew, Morning Dew, Call of the Wild if called early,
# Blight), recorded as the drift starts. {drift number: pot}; saved.
var _withheld := {}

func _pay_reward(rest_bonus: int) -> void:
	var lost := leaves_lost_in_block()
	var share := get_reward_share(lost)
	var dreams := keeps_dream_reward(lost)
	var omen := active
	var block := active_block
	active = null
	stats.leaves_lost += lost
	if run_state.is_over and not run_state.won:
		return
	stats.paid += 1
	stats.share += share
	var act := drift_director.get_act(drift_director.drifts_started)
	var scale := _act_scale(act)
	var dew := floori((roundi(omen.reward_dew * scale) + _extra_rest_bonus(omen, rest_bonus) + get_pot_reward(omen, block)) * share)
	run_state.add_dew(dew)
	stats.dew += dew
	if omen.rest_bonus_multiplier < 1.0:  # Lean Season: this rest's bonus shrinks (the twist, never scaled)
		var gone := mini(roundi(rest_bonus * (1.0 - omen.rest_bonus_multiplier)), run_state.dew)
		if gone > 0:
			run_state.spend_dew(gone)
	var dreamlight := floori(floori(omen.reward_dreamlight * scale) * share)  # By act: +1 / +1 / +2 / +2
	if dreamlight > 0:
		dream_state.add_dreamlight(dreamlight, &"omen")
	if omen.reward_legendary and dreams:
		dream_state.add_legendary_dreams(1)
	tree_seed_bonus += floori(omen.reward_tree_seeds * share)
	run_state.omen_seeds += floori(roundi(omen.reward_seeds * scale) * share)
	var max_leaves := floori(omen.reward_max_leaves * share)
	if max_leaves > 0:
		run_state.max_leaves += max_leaves
	if max_leaves > 0:
		run_state.regrow_leaves(max_leaves)  # The new leaves grow in (no Omen heals lost ones: run_design.md)
	if dreams:
		dream_state.add_rare_dreams(omen.reward_rare_dreams)
		dream_state.add_extra_cards(omen.reward_extra_dream_cards)
	omen_rewarded.emit(omen, paid_sentence(omen, act, rest_bonus, lost, block))

# The run was won during an Omen's block: there's no rest after it, so pay now (Seeds still count).
func _on_run_ended(won: bool) -> void:
	showing = false
	forced = false
	current_offer = []
	_offer_waiting = false
	if won and active != null:
		_pay_reward(0)

func _act_scale(act: int) -> float:
	return ACT_REWARD_SCALE[clampi(act, 1, ACT_REWARD_SCALE.size()) - 1]

func _block_has_flyers(drifts: Vector2i) -> bool:
	return not _block_flyers(drifts).is_empty()

# Hard Bark: a nightmare with a blight coat in drifts `drifts.x`..`drifts.y` (not a boss: bosses ignore Omens).
func _block_has_coat(drifts: Vector2i) -> bool:
	for number in range(drifts.x, drifts.y + 1):
		if number - 1 >= drift_director.drifts.size():
			break
		for group in drift_director.drifts[number - 1].groups:
			for entry in group.entries:
				if entry.enemy != null and entry.enemy.coat_total > 0 and not entry.enemy.is_boss:
					return true
	return false

# The flying nightmares scheduled in drifts `drifts.x`..`drifts.y` (Hollow Wind turns others into them).
func _block_flyers(drifts: Vector2i) -> Array[EnemyData]:
	var flyers: Array[EnemyData] = []
	for number in range(drifts.x, drifts.y + 1):
		if number - 1 >= drift_director.drifts.size():
			break
		for group in drift_director.drifts[number - 1].groups:
			for entry in group.entries:
				if entry.enemy != null and entry.enemy.trait_kind == EnemyData.Trait.FLYING and not flyers.has(entry.enemy):
					flyers.append(entry.enemy)
	return flyers


# --- Save ------------------------------------------------------------------------------------------

func to_save() -> Dictionary:
	return {"active": active.id if active != null else "", "active_block": active_block,
		"last_offer": _last_offer_ids.duplicate(), "tree_seed_bonus": tree_seed_bonus, "sprouted_block": _sprouted_block,
		"crumbled_block": _crumbled_block, "locked_cells": locked_cells.map(func(c: Vector2) -> Array: return [c.x, c.y]),
		"leaves_lost_at_start": _leaves_lost_at_start, "trampled_drift": _trampled_drift,
		"withheld": _withheld.keys().map(func(k: int) -> Array: return [k, _withheld[k]]),
		"player_pot": _player_pot.keys().map(func(k: int) -> Array: return [k, _player_pot[k]]),
		"offer": current_offer.map(func(o: OmenData) -> String: return o.id), "offer_block": current_offer_block,
		"faced": faced,
		"rng_state": str(_rng.state)}

func load_save(data: Dictionary) -> void:
	active = null
	active_block = int(data.get("active_block", 0))
	_last_offer_ids.assign(Array(data.get("last_offer", [])).map(func(i: String) -> String: return RENAMED.get(i, i)))
	tree_seed_bonus = int(data.get("tree_seed_bonus", 0))
	_sprouted_block = int(data.get("sprouted_block", 0))
	_crumbled_block = int(data.get("crumbled_block", 0))
	locked_cells.assign(Array(data.get("locked_cells", [])).map(func(c: Array) -> Vector2: return Vector2(c[0], c[1])))
	_leaves_lost_at_start = int(data.get("leaves_lost_at_start", 0))
	_trampled_drift = int(data.get("trampled_drift", 0))
	_withheld.clear()
	for pair in data.get("withheld", []):
		_withheld[int(pair[0])] = float(pair[1])
	_player_pot.clear()
	for pair in data.get("player_pot", []):
		_player_pot[int(pair[0])] = float(pair[1])
	# An offer still open at a save comes back as the Omen screen
	current_offer = []
	showing = false
	for offered_id in data.get("offer", []):
		for omen in pool:
			if omen.id == RENAMED.get(offered_id, offered_id):
				current_offer.append(omen)
	current_offer_block = int(data.get("offer_block", 0))
	faced = bool(data.get("faced", false)) and not current_offer.is_empty()
	if not current_offer.is_empty():
		_offer_waiting = true
		_try_show.call_deferred()
	var id: String = RENAMED.get(data.get("active", ""), data.get("active", ""))
	for omen in pool:
		if omen.id == id:
			active = omen
	if data.has("rng_state"):
		_rng.state = str(data.rng_state).to_int()
