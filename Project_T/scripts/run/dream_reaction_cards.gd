extends RefCounted
# Card pass slice 4, part B (owner 2026-10-16; council card_pass_draft.md 3 / 4b / 4d, card_pass_td.md 3a, card_pass_player.md
# 1, 3 and 6): the Reaction scalers (Ember Count, Afterglow, Spent Light, Witching Bend, Grand Design, Unbroken Chain), the
# form payoffs (Graft of Dreams, Crown of Leaves, Old Heart) and the reworks that read Reactions (The Long Walk, the Crowned
# Woven cards' +50%), plus Deep Sleep's and Thin Bark's new rules. DreamState holds one (`reaction_cards`); Reactions, Tower
# and DreamEffects call in behind one cached flag each. Every number is a starting value for Balancing and lives here
# (the Crowned bonus is Reactions.CROWNED_CARD_BONUS, read by the Reaction code too).
#
# Shared rules: every Reaction multiplier here multiplies (the synergy lane, DreamState.get_reaction_card_multiplier); Deep
# Sleep and Thin Bark are plain (Tower.plain_hit_factor / a plain Dream row). Stacks these cards add are non-native
# (Enemy.apply_status, or Tower._apply_one_status with native = false), so no Calling hears them. Every effect credits its
# card with DreamState.note_card (throttled) and shows a moment.
# This node also counts Reactions for the run (saved: the ReactionTracker's counts are not) and for the block: the Needs
# `requires_reactions_seen` / `requires_reaction_kinds` (UpgradeData) read them.

const DREAM_BURST := preload("res://scripts/fx/dream_burst.gd")
const DREAM_TRANSFER := preload("res://scripts/fx/dream_transfer.gd")
const CELL := 64.0

# --- Rule ids (= card ids) -----------------------------------------------------------------------------------------
const EMBER_COUNT := &"ember_count"
const AFTERGLOW := &"afterglow"  # The draft's "Ripple of Light", renamed: it clashed with the Common "Ripples"
const SPENT_LIGHT := &"spent_light"
const WITCHING_BEND := &"witching_bend"
const GRAND_DESIGN := &"grand_design"
const UNBROKEN_CHAIN := &"unbroken_chain"
const GRAFT_OF_DREAMS := &"graft_of_dreams"
const CROWN_OF_LEAVES := &"crown_of_leaves"
const OLD_HEART := &"old_heart"
const LONG_WALK := &"the_long_walk"
const DEEP_SLEEP := &"deep_sleep"
const THIN_BARK := &"thin_bark"
const DAWNBREAK := &"dawnbreak"
# The Woven Crowned cards whose Crowned Reaction deals damage: +CROWNED_CARD_BONUS through the Reaction hook. (Deep
# Stillness, Endless Night, Ring of Rings and Fever Pitch get a bigger / longer effect instead, in Reactions.)
# (Owner 2026-10-17, council reactions_unique.md: none any more; Tempest's Reach, Falling Stars, Mountain's Fall and Prism
# Heart each give their Crowned Reaction a new rule instead of +50% damage. Kept, empty, for anything that reads it.)
const CROWNED_DAMAGE := {}
const RULES: Array[StringName] = [EMBER_COUNT, AFTERGLOW, SPENT_LIGHT, WITCHING_BEND, GRAND_DESIGN, UNBROKEN_CHAIN,
	GRAFT_OF_DREAMS, CROWN_OF_LEAVES, OLD_HEART, LONG_WALK, DEEP_SLEEP, THIN_BARK,
	&"eye_of_the_tempest", &"falling_stars", &"mountains_fall", &"prism_heart"]

# --- Numbers (starting values for Balancing) -------------------------------------------------------------------------
const EMBER_PER := 0.01  # Ember Count: every Reaction this block makes Reactions this much stronger…
const EMBER_MAX := 0.60  # …up to this (counted per block: drifts overlap; no leaf clause, player review 2)
const EMBER_CALLOUT_STEP := 0.10  # A callout each time the bonus passes another step of this much
const AFTERGLOW_EVERY := 5  # Afterglow: every this-many-th link of a Reaction chain…
const AFTERGLOW_STACKS := 2  # …gives nightmares within…
const AFTERGLOW_RADIUS := 2.0  # …this many cells this many stacks of each status in that Reaction (never Rooted)
const AFTERGLOW_WAIT := 0.5  # At most once every this many seconds, field-wide (its stacks never continue the chain)
const SPENT_SECONDS := 4.0  # Spent Light (keyword chips 2026-10-16, TD 4): any Reaction leaves its statuses on its cell this long…
const SPENT_STACKS := 1  # …and each nightmare stepping there gets this many stacks of each (once per stain; never Rooted or Drowsy; was 2)
const SPENT_WINDOW := 0.5  # (Unused since keyword chips 2026-10-16: no longer only Reactions that dispel)
const SPENT_MAX := 6  # Stains on the map at once (the oldest goes; was 12)
const SPENT_CELL_WAIT := 4.0  # Each cell gets a new stain at most once every this many seconds
const WITCHING_BEND_BONUS := 0.40  # (Unused since keyword chips 2026-10-16: the +40% on a bend is gone)
const WITCHING_BEND_WAIT := 5.0  # Witching Bend (keyword chips 2026-10-16, TD 4): a nightmare rounding a bend sets off a Reaction at half
const WITCHING_BEND_BOSS_WAIT := 10.0  # need (half its burst), once every this many seconds per nightmare (bosses the second)
const WITCHING_BEND_POLL := 0.1  # Seconds between looks at who is rounding a bend
const GRAND_DESIGN_PER := 0.10  # Grand Design: every different Reaction set off this block makes all Reactions this much stronger…
const GRAND_DESIGN_MAX := 0.80  # …up to this
const UNBROKEN_FROM := 12  # Unbroken Chain: Reaction chains lose strength only from this link (Reactions.CHAIN_FALLOFF_FROM: 6)
const UNBROKEN_NEED_CHAIN := 10  # Its Need: Dawnbreak, or a chain this long seen this run
const GRAFT_STACKS := 1  # Graft of Dreams: a Warden touching a final form adds this many stacks of its status with each hit…
const GRAFT_MAX_SOURCES := 2  # …from at most this many final forms (never Rooted)
const GRAFT_MIN_TIER := 3
const GRAFT_THREAD_EVERY := 1.0  # Seconds between the vine threads one Warden shows
const CROWN_FINAL := 0.30  # Crown of Leaves: Reactions a final form took part in deal this much more…
const CROWN_ASCENDED := 0.60  # …an Ascended form's this much more
const CROWN_FINAL_TIER := 3
const CROWN_ASCENDED_TIER := 4
const OLD_HEART_TIER := 4  # Old Heart: an Ascended Warden's hit lets its target's next Reaction skip its wait…
const OLD_HEART_WAIT := 4.0  # …once every this many seconds per nightmare…
const OLD_HEART_REFIRE := 1.0  # …and when that skip is used, the Warden attacks again at once (Tower.skip_wait), once per this long
const LONG_WALK_STEPS := 4.0  # The Long Walk: Reactions on a nightmare deal LONG_WALK_PER more for every this many cells…
const LONG_WALK_PER := 0.02  # …it has walked inside an attacking Warden's range…
const LONG_WALK_MAX := 0.25  # …up to this (flyers: none). Power budget 2026-10-16: was 0.80 (the maze is a skill, not a free multiplier)
const LONG_WALK_CALLOUT_MIN := 0.20  # A callout from this bonus up…
const LONG_WALK_CALLOUT_EVERY := 1.5  # …at most this often
const DEEP_SLEEP_BONUS := 0.80  # Deep Sleep (rework): Warden hits on a nightmare carrying…
const DEEP_SLEEP_MIN_STATUSES := 2  # …at least this many statuses deal this much more (plain: clamped by Tower.plain_hit_factor)
const THIN_BARK_BONUS := 1.00  # Thin Bark (rework, player review 3): final and Ascended Wardens deal this much more…
const THIN_BARK_MIN_TIER := 3
const THIN_BARK_PENALTY := 0.30  # …and base Wardens, branches and Sprouts this much less (a plain Dream row)
const CREDIT_EVERY := 0.5  # note_card at most this often per card (the times in between are added up)
const BURST_EVERY := 0.4  # A card's burst on the field at most this often

var dreams  # The DreamState that owns this (set in _init)

func _init(state = null) -> void:
	dreams = state

# DreamState._ready: a new run never inherits Unbroken Chain's falloff; the block counters reset at each rest.
func ready() -> void:
	Reactions.chain_falloff_from = Reactions.CHAIN_FALLOFF_FROM
	_unbroken_set = false
	if dreams == null:
		return
	dreams.drift_director.rest_started.connect(_on_rest_started.unbind(4))
	dreams.spawner.enemy_cleansed.connect(_on_cleansed)

# --- Which cards are owned (cached like dream_role_cards.gd) ------------------------------------------------------
var _on := {}
var _stamp := [-1, -1, -1]
var _reaction_live := false
var _hit_live := false
var _plain_live := false
var _unbroken_set := false

func _refresh() -> void:
	var d = dreams
	if d == null:
		return
	if d.rules_stamp == _stamp[0] and d.stacks.size() == _stamp[1] and d.pool.size() == _stamp[2]:
		return
	_stamp = [d.rules_stamp, d.stacks.size(), d.pool.size()]
	_on.clear()
	for rule in RULES:
		if d.has_rule(rule):
			_on[rule] = true
	_reaction_live = _on.has(EMBER_COUNT) or _on.has(GRAND_DESIGN) or _on.has(WITCHING_BEND) or _on.has(LONG_WALK) \
		or _on.has(CROWN_OF_LEAVES) or CROWNED_DAMAGE.values().any(func(r: StringName) -> bool: return _on.has(r))
	_hit_live = _on.has(GRAFT_OF_DREAMS) or _on.has(OLD_HEART)
	_plain_live = _on.has(DEEP_SLEEP)
	# Unbroken Chain moves the static falloff start while held (and puts it back if it ever stops being held).
	if _on.has(UNBROKEN_CHAIN):
		Reactions.chain_falloff_from = UNBROKEN_FROM
		_unbroken_set = true
	elif _unbroken_set:
		Reactions.chain_falloff_from = Reactions.CHAIN_FALLOFF_FROM
		_unbroken_set = false

func on(rule: StringName) -> bool:
	_refresh()
	return _on.has(rule)

func reaction_live() -> bool:
	_refresh()
	return _reaction_live

func hit_live() -> bool:
	_refresh()
	return _hit_live

# --- Reaction counts (run and block) and the Needs that read them -------------------------------------------------
var run_counts := {}  # Reaction id -> times it fired this run (saved)
var longest_chain := 0  # Longest chain this run (saved)
var _block_count := 0  # Reactions this block (Ember Count)
var _block_kinds := {}  # Reaction id -> true: different Reactions this block (Grand Design)

func to_save() -> Dictionary:
	return {"counts": run_counts.duplicate(), "longest": longest_chain}

func load_save(data: Dictionary) -> void:
	run_counts.clear()
	var counts: Dictionary = data.get("counts", {})
	for id in counts:
		run_counts[StringName(id)] = int(counts[id])  # JSON gives floats and Strings
	longest_chain = int(data.get("longest", 0))
	_block_count = 0
	_block_kinds.clear()

func total_seen() -> int:
	var sum := 0
	for id in run_counts:
		sum += int(run_counts[id])
	return sum

# Different Reactions set off at least `each` times this run.
func kinds_seen(each: int) -> int:
	var kinds := 0
	for id in run_counts:
		if int(run_counts[id]) >= maxi(each, 1):
			kinds += 1
	return kinds

func _on_rest_started() -> void:
	_block_count = 0
	_block_kinds.clear()
	_ember_step = 0

# DreamState._meets_needs: the Reaction Needs (data fields) and Unbroken Chain's.
func needs_met_for(card: UpgradeData) -> bool:
	if dreams == null or dreams.unlock_everything:
		return true
	if card.requires_reaction_kinds > 0:
		if kinds_seen(card.requires_reactions_seen) < card.requires_reaction_kinds:
			return false
	elif card.requires_reactions_seen > 0 and total_seen() < card.requires_reactions_seen:
		return false
	if card.rule_id == UNBROKEN_CHAIN and not dreams.has_rule(DAWNBREAK) and longest_chain < UNBROKEN_NEED_CHAIN:
		return false
	return true

# DreamState.needs_note: what is still missing, in the player's own numbers ("" = nothing).
func need_text_for(card: UpgradeData) -> String:
	if needs_met_for(card):
		return ""
	if card.requires_reaction_kinds > 0:
		return "%d different Reactions set off %d times each (you: %d)" % [card.requires_reaction_kinds,
			card.requires_reactions_seen, kinds_seen(card.requires_reactions_seen)]
	if card.requires_reactions_seen > 0 and total_seen() < card.requires_reactions_seen:
		return "a Reaction set off %d times this run (you: %d)" % [card.requires_reactions_seen, total_seen()]
	if card.rule_id == UNBROKEN_CHAIN:
		return "Dawnbreak, or a Reaction chain of %d this run (yours: %d)" % [UNBROKEN_NEED_CHAIN, longest_chain]
	return ""

# --- Reactions._fire ----------------------------------------------------------------------------------------------
var _ember_step := 0  # Ember Count: callout steps already shown this block
var _afterglow_next := -1.0
var _reacted := {}  # Spent Light: nightmare instance id -> the clock its last Reaction fired
var _long_walk_next := -1.0

# Reaction `id` went off on `enemy` as link `chain` (it counts as `links` links); `towers` = the Wardens that took part.
func reaction_fired(enemy, id: StringName, chain: int, links: int, towers: Array) -> void:
	run_counts[id] = int(run_counts.get(id, 0)) + 1
	longest_chain = maxi(longest_chain, chain)
	_block_count += 1
	var new_kind := not _block_kinds.has(id)
	_block_kinds[id] = true
	_refresh()
	if _on.is_empty() or not is_instance_valid(enemy):
		return
	var at: Vector2 = enemy.global_position
	var world := Reactions._world(enemy)
	if _on.has(EMBER_COUNT):
		var step := floori(minf(EMBER_PER * _block_count, EMBER_MAX) / EMBER_CALLOUT_STEP + 0.0001)
		if step > _ember_step:
			_ember_step = step
			if world != null:
				Fx.callout("Ember Count +%d%%" % roundi(minf(EMBER_PER * _block_count, EMBER_MAX) * 100.0), Palette.EMBER, at, world, EMBER_COUNT)
	if _on.has(GRAND_DESIGN) and new_kind and world != null:
		Fx.callout("Grand Design +%d%%" % roundi(_grand_design() * 100.0), Palette.GLOW, at, world, GRAND_DESIGN)
		_credit(GRAND_DESIGN, at)
	if _on.has(LONG_WALK) and _clock() >= _long_walk_next:
		var walk := _long_walk_bonus(enemy)
		if walk >= LONG_WALK_CALLOUT_MIN and world != null:
			_long_walk_next = _clock() + LONG_WALK_CALLOUT_EVERY
			Fx.callout("The Long Walk +%d%%" % roundi(walk * 100.0), Palette.GLOW, at, world, LONG_WALK)
	if _on.has(CROWN_OF_LEAVES) and _crown_tier(towers, null) >= CROWN_FINAL_TIER:
		_burst(CROWN_OF_LEAVES, at, 22.0, world)  # A leaf crown over the Reaction
		_credit(CROWN_OF_LEAVES, at)
	var woven: StringName = Reactions.WOVEN_RULE.get(id, &"")
	if woven != &"" and dreams.has_rule(woven):
		_credit(woven, at)  # The Crowned Woven cards: their Reaction went off (bigger / +50%)
	if _on.has(UNBROKEN_CHAIN) and chain >= Reactions.CHAIN_FALLOFF_FROM and chain < UNBROKEN_FROM and world != null:
		Fx.callout("Unbroken ×%d" % chain, Palette.GOLD, at, world, UNBROKEN_CHAIN)  # A link that would have weakened
		_credit(UNBROKEN_CHAIN, at)
	if _on.has(SPENT_LIGHT):
		_spent_light(enemy, id)
	if _on.has(AFTERGLOW) and floori(float(chain - links) / AFTERGLOW_EVERY) < floori(float(chain) / AFTERGLOW_EVERY) \
			and _clock() >= _afterglow_next:
		_afterglow_next = _clock() + AFTERGLOW_WAIT
		var gifts := _snapshot(enemy, id)
		if not gifts.is_empty():
			_afterglow.call_deferred(enemy.get_instance_id(), at, gifts)

# The Reaction cards' part of Reaction damage (DreamState.get_reaction_card_multiplier; multiplies with role_cards').
func reaction_multiplier(enemy, id: StringName, tower) -> float:
	var m := 1.0
	if _on.has(EMBER_COUNT) and _block_count > 0:
		var ember := 1.0 + minf(EMBER_PER * _block_count, EMBER_MAX)
		m *= ember
		_note_bonus(EMBER_COUNT, ember)
		_quiet_credit(EMBER_COUNT)
	if _on.has(GRAND_DESIGN) and not _block_kinds.is_empty():
		m *= 1.0 + _grand_design()
		_note_bonus(GRAND_DESIGN, 1.0 + _grand_design())
		_quiet_credit(GRAND_DESIGN)
	var crowned: StringName = CROWNED_DAMAGE.get(id, &"")
	if crowned != &"" and _on.has(crowned):
		m *= 1.0 + Reactions.CROWNED_CARD_BONUS
		_note_bonus(crowned, 1.0 + Reactions.CROWNED_CARD_BONUS)
	if enemy == null or not is_instance_valid(enemy):
		return m
	if _on.has(LONG_WALK):
		var walk := _long_walk_bonus(enemy)
		if walk > 0.0:
			m *= 1.0 + walk
			_note_bonus(LONG_WALK, 1.0 + walk)
			_quiet_credit(LONG_WALK)
	if _on.has(CROWN_OF_LEAVES):
		var tier := _crown_tier(enemy.statuses.chain_towers, tower)
		if tier >= CROWN_ASCENDED_TIER:
			m *= 1.0 + CROWN_ASCENDED
			_note_bonus(CROWN_OF_LEAVES, 1.0 + CROWN_ASCENDED)
		elif tier >= CROWN_FINAL_TIER:
			m *= 1.0 + CROWN_FINAL
			_note_bonus(CROWN_OF_LEAVES, 1.0 + CROWN_FINAL)
	return m

# Card credit (Main Merger df7010bb): what a card's multiplier really added, by its card id (rule id -> card id).
func _note_bonus(rule: StringName, multiplier: float) -> void:
	var by_rule: Dictionary = dreams._credit_rule_map() if dreams != null else {}
	DamageLog.note_card_bonus(String(by_rule.get(rule, String(rule))), multiplier)

func _grand_design() -> float:
	return minf(GRAND_DESIGN_PER * _block_kinds.size(), GRAND_DESIGN_MAX)

# The highest tier among the Wardens that took part (and the one whose hit set it off).
static func _crown_tier(towers: Array, tower) -> int:
	var best := 0
	for t in towers:
		if is_instance_valid(t) and t is Tower:
			best = maxi(best, t.tower_data.tier)
	if tower != null and is_instance_valid(tower) and tower is Tower:
		best = maxi(best, tower.tower_data.tier)
	return best

# Reactions._fire spent a "skip the wait" token: true if it was Old Heart's (else Called from Afar credits it).
var _old_heart := {}  # Nightmare instance id -> WeakRef of the Ascended Warden that set the token
var _old_heart_refire := {}  # Warden instance id -> the clock it may refire again

func wait_skipped(enemy) -> bool:
	if not is_instance_valid(enemy):
		return false
	var eid: int = enemy.get_instance_id()
	if not _old_heart.has(eid):
		return false
	var ref: WeakRef = _old_heart[eid]
	_old_heart.erase(eid)
	var tower = ref.get_ref()
	_credit(OLD_HEART, enemy.global_position)
	if is_instance_valid(tower) and tower is Tower and tower.is_inside_tree():
		_burst(OLD_HEART, tower.global_position, 28.0, tower)  # The Ascended Warden flares
		var tid: int = tower.get_instance_id()
		if _clock() >= float(_old_heart_refire.get(tid, -1.0)):
			_old_heart_refire[tid] = _clock() + OLD_HEART_REFIRE
			tower.skip_wait(1)  # …and attacks again at once
	return true

# --- Afterglow -------------------------------------------------------------------------------------------------------
# The statuses of Reaction `id` that `enemy` carries now (before the Reaction uses them up): [id, potency, source, line].
static func _snapshot(enemy, id: StringName) -> Array:
	var data: ReactionData = Reactions.get_data(id)
	var gifts: Array = []
	if data == null:
		return gifts
	var s: EnemyStatuses = enemy.statuses
	var wanted: Array[StringName] = []
	wanted.append_array(data.statuses)
	wanted.append_array(data.alternatives)
	for status in wanted:
		if status == EnemyStatuses.HELD or not status in EnemyStatuses.ALL or not s.has(status):
			continue
		var source: Node = s.source(status)
		var line: String = s.spore_line() if status == EnemyStatuses.SPORED else (source.tower_data.line if source is Tower else "")
		gifts.append([status, s.potency(status), weakref(source) if source != null else null, line])
	return gifts

# Deferred from reaction_fired: a ring of light; the nightmares within reach get the Reaction's statuses. Those stacks
# never continue the chain (TD 3a): a Reaction they set off starts at link 1, and one they don't leaves its old link.
func _afterglow(skip_id: int, at: Vector2, gifts: Array) -> void:
	if dreams == null or not dreams.is_inside_tree():
		return
	var reach := AFTERGLOW_RADIUS * CELL
	var any := false
	for other in Tower.nightmares_near(dreams.get_tree(), at, reach):
		if not is_instance_valid(other) or other.is_cleansed or other.get_instance_id() == skip_id \
				or other.global_position.distance_to(at) > reach:
			continue
		var s: EnemyStatuses = other.statuses
		var keep := [s.chain_count, s.chain_time, s.chain_towers]
		s.chain_time = 0.0
		s.chain_count = 0
		_give(other, gifts, AFTERGLOW_STACKS)
		if is_instance_valid(other) and s.chain_time <= 0.0:
			s.chain_count = int(keep[0])
			s.chain_time = float(keep[1])
			s.chain_towers = keep[2]
		any = true
	if any:
		DREAM_BURST.play(AFTERGLOW, at, reach, Reactions._world(dreams))  # The light ring
		_credit(AFTERGLOW, at)

static func _give(other, gifts: Array, stacks: int) -> void:
	for gift in gifts:
		if not is_instance_valid(other) or other.is_cleansed:
			return
		var ref = gift[2]
		var source: Node = ref.get_ref() if ref != null else null
		other.apply_status(gift[0], stacks, 0.0, float(gift[1]), 0, String(gift[3]), source if is_instance_valid(source) else null)

# --- Spent Light ------------------------------------------------------------------------------------------------------
var _stains: Array = []

func _prune_reacted() -> void:
	var now := _clock()
	for key in _reacted.keys():
		if now - float(_reacted[key]) > SPENT_WINDOW:
			_reacted.erase(key)

# EnemyContainer.enemy_cleansed: a nightmare a Reaction dispelled (its last damage a Reaction's, or a Reaction on it
# within SPENT_WINDOW) leaves its statuses on its cell for SPENT_SECONDS.
func _on_cleansed(_enemy: Node2D) -> void:
	pass  # (Keyword chips 2026-10-16: Spent Light no longer waits for a dispel; see _spent_light)

var _stain_cells := {}  # Cell -> the clock it may get a new stain

# Spent Light (keyword chips 2026-10-16): Reaction `id` went off on `enemy`; the statuses it needs (never Rooted or
# Drowsy) stay on its cell for SPENT_SECONDS. Each cell once every SPENT_CELL_WAIT s, SPENT_MAX stains at once.
func _spent_light(enemy, id: StringName) -> void:
	if not is_instance_valid(enemy) or enemy.is_flying():
		return
	var cell: Vector2 = enemy.get_current_cell()
	if _clock() < float(_stain_cells.get(cell, -1.0)):
		return
	var gifts: Array = _snapshot(enemy, id).filter(func(gift) -> bool: return gift[0] != EnemyStatuses.DROWSY)
	var world := Reactions._world(enemy)
	if gifts.is_empty() or world == null:
		return
	_stain_cells[cell] = _clock() + SPENT_CELL_WAIT
	if _stain_cells.size() > 256:
		_stain_cells.clear()
		_stain_cells[cell] = _clock() + SPENT_CELL_WAIT
	_stains = _stains.filter(func(n) -> bool: return is_instance_valid(n) and not n.is_queued_for_deletion())
	while _stains.size() >= SPENT_MAX:
		var oldest = _stains.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	var stain := SpentStain.new(enemy.get_current_cell(), gifts, self)
	world.add_child(stain)
	stain.global_position = Tower.MAP_GRID.calculate_map_position(enemy.get_current_cell())
	_stains.append(stain)
	_credit(SPENT_LIGHT, stain.global_position)

# A glowing stain on one path cell: each nightmare that steps on it gets the Reaction's statuses (once per stain).
class SpentStain extends Node2D:
	const TICK := 0.1
	var cell: Vector2
	var gifts: Array
	var cards  # The helper (credit)
	var _age := 0.0
	var _tick := 0.0
	var _seen := {}

	func _init(at_cell: Vector2, statuses: Array, owner_cards) -> void:
		cell = at_cell
		gifts = statuses
		cards = owner_cards
		z_index = -1  # On the ground, under the nightmares

	func _process(delta: float) -> void:
		_age += delta
		var life: float = SPENT_SECONDS
		if _age >= life:
			queue_free()
			return
		queue_redraw()
		_tick -= delta
		if _tick > 0.0:
			return
		_tick = TICK
		for enemy in Tower.nightmares_near(get_tree(), global_position, CELL):
			if not is_instance_valid(enemy) or enemy.is_cleansed or enemy.is_flying() or _seen.has(enemy.get_instance_id()):
				continue
			if enemy.get_current_cell() != cell:
				continue
			_seen[enemy.get_instance_id()] = true
			for gift in gifts:  # (As the outer _give: an inner class can't call it)
				if not is_instance_valid(enemy) or enemy.is_cleansed:
					break
				var ref = gift[2]
				var source: Node = ref.get_ref() if ref != null else null
				enemy.apply_status(gift[0], SPENT_STACKS, 0.0, float(gift[1]), 0, String(gift[3]), source if is_instance_valid(source) else null)
			if cards != null:
				cards._credit(SPENT_LIGHT, global_position)

	func _draw() -> void:
		var fade := 1.0 - clampf(_age / SPENT_SECONDS, 0.0, 1.0)
		draw_circle(Vector2.ZERO, 20.0, Color(Palette.GLOW, 0.22 * fade))
		draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 32, Color(Palette.HEARTLIGHT, 0.45 * fade), 1.5)

# --- Tower.hit: Graft of Dreams, Old Heart -----------------------------------------------------------------------------
var _graft_board := -1
var _graft := {}  # Warden instance id -> the final forms touching it that apply a status (per board_version)
var _graft_thread := {}  # Warden instance id -> the clock it may show a vine thread again

# After a Warden's hit and its own statuses (Tower.hit; never effect ticks).
func after_hit(tower, enemy, effect_tick: bool) -> void:
	if effect_tick or not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	if _on.has(GRAFT_OF_DREAMS):
		_graft_hit(tower, enemy)
	if _on.has(OLD_HEART) and tower.tower_data.tier >= OLD_HEART_TIER and is_instance_valid(enemy) and not enemy.is_cleansed:
		var s: EnemyStatuses = enemy.statuses
		if not s.skip_reaction_wait and not s.is_on_cooldown(OLD_HEART):
			s.skip_reaction_wait = true
			s.start_cooldown(OLD_HEART, OLD_HEART_WAIT)
			_old_heart[enemy.get_instance_id()] = weakref(tower)
			if _old_heart.size() > 512:
				_old_heart.clear()
				_old_heart[enemy.get_instance_id()] = weakref(tower)
			Reactions.on_status(enemy, OLD_HEART, tower)  # Sets off whatever it is ready for (a key no status check used)

func _graft_hit(tower, enemy) -> void:
	var finals: Array = _graft_sources(tower)
	if finals.is_empty():
		return
	var showed := false
	for form in finals:
		if not is_instance_valid(form) or not is_instance_valid(enemy) or enemy.is_cleansed:
			continue
		var status: StringName = Tower.first_status(form.attack_data)  # (A special's status too: Tower Code, keyword audit)
		form._apply_one_status(enemy, status, GRAFT_STACKS, form.get_damage(), false)  # Non-native: no Calling hears it
		var key: int = tower.get_instance_id()
		if not showed and _clock() >= float(_graft_thread.get(key, -1.0)) and is_instance_valid(enemy):
			showed = true
			_graft_thread[key] = _clock() + GRAFT_THREAD_EVERY
			if _graft_thread.size() > 256:
				_graft_thread.clear()
			DREAM_TRANSFER.play(Reactions._world(tower), form.global_position, enemy.global_position, status)  # The vine
	if showed:
		_credit(GRAFT_OF_DREAMS, tower.global_position)

func _graft_sources(tower) -> Array:
	if dreams.board_version != _graft_board:
		_graft_board = dreams.board_version
		_graft.clear()
	var key: int = tower.get_instance_id()
	if not _graft.has(key):
		var list: Array = []
		if is_instance_valid(dreams.tower_container):
			for other in dreams._touching(tower):
				var status: StringName = Tower.first_status(other.attack_data)  # (A special's status too)
				if other.tower_data.tier >= GRAFT_MIN_TIER and status != &"" and status != EnemyStatuses.HELD \
						and status in EnemyStatuses.ALL and list.size() < GRAFT_MAX_SOURCES:
					list.append(other)
		_graft[key] = list
	return _graft[key]

# --- Deep Sleep (plain, per hit: Tower._commons_hit_multiplier, clamped by plain_hit_factor) ---------------------------
func plain_hit_multiplier(tower, enemy) -> float:
	_refresh()
	if not _plain_live or not is_instance_valid(enemy) or enemy.statuses.count() < DEEP_SLEEP_MIN_STATUSES:
		return 1.0
	_burst(DEEP_SLEEP, enemy.global_position, 14.0, tower)  # A soft flash on the hit
	_credit(DEEP_SLEEP, enemy.global_position)
	return 1.0 + DEEP_SLEEP_BONUS

# --- Dream rows (DreamEffects reporters: Thin Bark, Deep Sleep, The Long Walk) ------------------------------------------
func thin_bark_row(data: TowerData) -> Dictionary:
	if data == null or not data.can_attack:
		return {}
	if data.tier >= THIN_BARK_MIN_TIER:
		return {"active": true, "damage": THIN_BARK_BONUS, "effect": "deals %d%% more damage (a final or Ascended form)" % roundi(THIN_BARK_BONUS * 100)}
	return {"active": true, "damage": -THIN_BARK_PENALTY, "effect": "-%d%% damage (not a final form)" % roundi(THIN_BARK_PENALTY * 100)}

func deep_sleep_row(data: TowerData) -> Dictionary:
	if data == null or not data.can_attack:
		return {}
	return {"effect": "hits deal %d%% more to nightmares carrying %d or more statuses" % [roundi(DEEP_SLEEP_BONUS * 100), DEEP_SLEEP_MIN_STATUSES]}

func long_walk_row() -> Dictionary:
	_walk_cover()
	var covered: float = _walk_cov[_walk_cov.size() - 1] if not _walk_cov.is_empty() else 0.0
	var most := minf(floorf(covered / LONG_WALK_STEPS) * LONG_WALK_PER, LONG_WALK_MAX)
	return {"run_wide": true, "active": true,
		"effect": "Reactions +%d%% per %d cells a nightmare walked in range (up to +%d%%)" % [roundi(LONG_WALK_PER * 100), roundi(LONG_WALK_STEPS), roundi(LONG_WALK_MAX * 100)],
		"note": "your Wardens cover %d cells of the route: up to +%d%% by the Heartwood" % [roundi(covered), roundi(most * 100)]}

# DreamState._note_grown: Thin Bark's moment (a Warden grew into a final form while it is held).
func grown(tower) -> void:
	if not on(THIN_BARK) or not is_instance_valid(tower) or tower.tower_data.tier < THIN_BARK_MIN_TIER or not tower.is_inside_tree():
		return
	_burst(THIN_BARK, tower.global_position, 30.0, tower)
	_credit(THIN_BARK, tower.global_position)

# The Dreams row's live value ("" = none).
func live_text(card: UpgradeData) -> String:
	match card.rule_id:
		EMBER_COUNT:
			return "+%d%%" % roundi(minf(EMBER_PER * _block_count, EMBER_MAX) * 100.0)
		GRAND_DESIGN:
			return "+%d%%" % roundi(_grand_design() * 100.0)
		UNBROKEN_CHAIN:
			return "to ×%d" % (UNBROKEN_FROM - 1)
	return ""

# --- The route: bends and covered cells (cached per route and board) -------------------------------------------------
var _route_key := -1
var _index := {}  # Route point -> its index
var _bend_zone := {}  # Route index -> true: a bend's point and the points either side
var _walk_key := [-1, -1]  # [board_version, route serial] the coverage was built for
var _walk_cov := PackedFloat32Array()  # Route index -> cells of route up to it inside an attacking Warden's range

func _route() -> PackedVector2Array:
	var map = dreams.map_generator
	return map.get_path_from(map.startPath)

func _index_route() -> void:
	var serial: int = dreams.batch.route_serial
	if serial == _route_key:
		return
	_route_key = serial
	_index.clear()
	_bend_zone.clear()
	var path := _route()
	for i in path.size():
		_index[path[i]] = i
	for b in DreamState.BATCH.bend_indices(path):
		for i in [b - 1, b, b + 1]:
			_bend_zone[i] = true

func _route_index(enemy) -> int:
	_index_route()
	return int(_index.get(enemy.get_target_cell(), -1))

# Witching Bend (keyword chips 2026-10-16): DreamState._process calls this. A nightmare rounding a bend (a point either
# side of it) with two or more statuses gets Reactions.check_at_half at HALF_SET_OFF_DAMAGE; the wait starts only when
# one went off. Flyers never round a bend.
var _bend_next := 0.0

func bend_poll() -> void:
	if not on(WITCHING_BEND) or dreams.spawner == null or _clock() < _bend_next:
		return
	_bend_next = _clock() + WITCHING_BEND_POLL
	for enemy in dreams.spawner.get_enemies():
		if not is_instance_valid(enemy) or enemy.is_cleansed or enemy.statuses.count() < 2:
			continue
		var s: EnemyStatuses = enemy.statuses
		if s.is_on_cooldown(WITCHING_BEND) or not _at_bend(enemy):
			continue
		var setter: Node = null  # The Warden credited: an applier of one of its statuses
		for id in s.active_ids():
			if s.source(id) is Tower:
				setter = s.source(id)
				break
		var before := _block_count
		Reactions.check_at_half(enemy, setter, Reactions.HALF_SET_OFF_DAMAGE)
		if _block_count == before or not is_instance_valid(enemy):
			continue
		s.start_cooldown(WITCHING_BEND, WITCHING_BEND_BOSS_WAIT if s.is_boss else WITCHING_BEND_WAIT)
		_burst(WITCHING_BEND, enemy.global_position, 20.0, Reactions._world(enemy))  # The bend flares where it went off
		_credit(WITCHING_BEND, enemy.global_position)

func _at_bend(enemy) -> bool:
	if enemy.is_flying():
		return false
	var i := _route_index(enemy)
	return i >= 0 and _bend_zone.has(i)

func _walk_cover() -> void:
	_index_route()
	var key := [int(dreams.board_version), int(dreams.batch.route_serial)]
	if key[0] == _walk_key[0] and key[1] == _walk_key[1]:
		return
	_walk_key = key
	var path := _route()
	var grid = dreams.map_generator.MAP_GRID
	var cell_px: float = grid.cell_size.x
	var attackers: Array = []
	for tower in dreams._towers():
		if tower.tower_data.can_attack and tower.tower_data.line != "wall":
			attackers.append([tower.global_position, tower.get_range_pixels(), tower.attack_data.min_range * cell_px])
	_walk_cov.resize(path.size())
	var total := 0.0
	for i in path.size():
		if i > 0:
			var at: Vector2 = grid.calculate_map_position(path[i])
			for a in attackers:
				var d: float = at.distance_to(a[0])
				if d <= float(a[1]) and d >= float(a[2]):
					total += path[i].distance_to(path[i - 1])  # Cells (half-cell steps: 0.5)
					break
		_walk_cov[i] = total

func _long_walk_bonus(enemy) -> float:
	if enemy.is_flying():
		return 0.0
	_walk_cover()
	if _walk_cov.is_empty():
		return 0.0
	var i := _route_index(enemy)
	if i < 0:  # Off the main route (re-routed this moment): its share of the route walked
		i = roundi(dreams.batch.route_share(enemy) * float(_walk_cov.size() - 1))
	i = clampi(i, 0, _walk_cov.size() - 1)
	return minf(floorf(_walk_cov[i] / LONG_WALK_STEPS) * LONG_WALK_PER, LONG_WALK_MAX)

# --- Helpers ---------------------------------------------------------------------------------------------------------
func _clock() -> float:
	return float(dreams._game_clock) if dreams != null else 0.0

var _credits := {}  # Card id -> [clock of the last note_card, times since]

func _credit(id: StringName, at: Vector2) -> void:
	if dreams == null:
		return
	var now := _clock()
	var entry: Array = _credits.get(id, [-1000.0, 0])
	entry[1] = int(entry[1]) + 1
	if now - float(entry[0]) >= CREDIT_EVERY:
		dreams.note_card(id, at, int(entry[1]))
		entry = [now, 0]
	_credits[id] = entry

# Credit for a multiplier that applied (no place on the field: the Reaction itself is the moment).
func _quiet_credit(id: StringName) -> void:
	_credit(id, Vector2.INF)

var _bursts := {}  # Card id -> the clock its burst may show again

# `near`: the world, or any node in it (the world is looked up only when the burst will show).
func _burst(id: StringName, at: Vector2, radius: float, near: Node) -> void:
	if near == null or not is_instance_valid(near) or _clock() < float(_bursts.get(id, -1.0)):
		return
	_bursts[id] = _clock() + BURST_EVERY
	var world := Reactions._world(near)
	if world != null:
		DREAM_BURST.play(id, at, radius, world)
