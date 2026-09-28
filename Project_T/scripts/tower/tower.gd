extends Node2D
class_name Tower

# A Warden. Plays its idle loop, and when a nightmare is in range winds up its attack animation and
# releases on the release frame: a projectile (optionally splashing or swooping back), a pulse, chain
# lightning, a lingering cloud, a trap ring, a sweep of birds, a status-spreading gust, spinning
# blades, a grab, or lit path tiles. Beams and auras work continuously instead. Hits can crit and
# apply the Warden's status. Stats go through DreamState (group "dream_state") so Dreams can modify
# them. Kinds and their numbers: documentation/tower_design.md and warden_stats.md.

signal evolved(tower: Tower)
# The Warden gained a Nurture rank (`rank` is the new one).
signal nurtured(tower: Tower)
# The attack's release frame: the shot / pulse / chain / cloud happens (sound hooks listen).
signal attack_released(tower: Tower)
# A hit from this Warden was a critical hit (sound: a sharp chime).
signal crit_landed(tower: Tower, enemy: Node2D)
# A hit from this Warden landed on `enemy` (sound: the impact). Every attack kind goes through hit().
signal hit_landed(tower: Tower, enemy: Node2D, is_area: bool, is_crit: bool)
# A Puffball popped `enemy`'s `stacks` Spored stacks (sound, and the "Popped!" callout).
signal popped(tower: Tower, enemy: Node2D, stacks: int)
# A beam (Sunpetal line) hit its target; `ramp` is its current damage multiplier.
signal beam_ticked(tower: Tower, ramp: float)
# Sound hooks for the Warden sound sheet (audio_direction.md); SoundHooks connects to these.
signal cloud_formed(tower: Tower, where: Vector2, duration: float)  # Bloomcap / Dreamshroom / Mistveil
signal trap_set(tower: Tower, where: Vector2)  # Fairy Ring planted a ring
signal trap_triggered(tower: Tower, where: Vector2)  # A ring went off
signal seed_caught(tower: Tower)  # Samara / Autumn Gale caught a seed
signal echoed(tower: Tower, reaction: StringName, where: Vector2)  # Echo Hollow repeated a Reaction
signal put_to_sleep(tower: Tower, enemy: Node2D)  # A nightmare fell asleep because of this Warden
signal shard_dropped(tower: Tower, where: Vector2)  # A Great Dreamcatcher's Caught nightmare left a shard
signal grab_finished(tower: Tower, enemy: Node2D)  # The Pond Keeper's drag ended
signal ascended(tower: Tower)  # Grew into an Ascended form (tier 4)
signal ascended_event(tower: Tower, where: Vector2, targets: int)  # One per Ascended pulse / chain
signal sap_yielded(tower: Tower, dew: int)  # The Sapling / Grandmother Oak paid out at a drift's end
signal dreamlight_ripened(tower: Tower)  # The Sapling gave a Dreamlight
signal withered(tower: Tower)  # A leaf lost withered the Sapling's yield
signal statics_set_off(tower: Tower, where: Vector2, count: int)  # An Ascended pulse (the Great Bell) set off Static charges

@export var tower_data: TowerData
@onready var sprite: Sprite2D = $Sprite2D

const MAP_GRID = preload("res://resource/map/map_grid.tres")
const ENEMY_GROUP := "enemies"
const SPORE_POTENCY := 0.25  # Spored soothes this share of the Warden's soothe per second per stack
const CHAIN_DAMP_EXTRA_JUMPS := 2
const CHAIN_DAMP_EXTRA_RANGE := 1.0  # Cells
const POP_SPREAD_RANGE := 1.5  # Cells: how far a Puffball pop's spores drift on
const LOOSE_STONE_SHARE := 0.35  # Loose Stones: each of the 3 fragments
const HUSH_RADIUS := 0.15  # Hush: Bellflower-line pulses +15% radius per stack (max 3)
const BEAM_TICK := 0.25  # Seconds between beam hits
const BEAM_RAMP_FAST := 2.0  # Beams ramp this much faster on Drowsy or Held nightmares
const AURA_TICK := 0.25  # Seconds between aura refreshes (White Stag)
const AURA_PULSE_EVERY := 2.5  # Seconds between the White Stag's pulse animations
const NEIGHBOUR_REFRESH := 0.5  # Seconds between looks at neighbouring Wardens (copy, auras)
const TONGUE_COLOR := Color(0.95, 0.55, 0.6)
const WIND_COLOR := Color(0.85, 0.95, 1.0)
const LIGHT_COLOR := Color(1.0, 0.9, 0.5)
# Nurture ranks (warden_stats.md "Nurture v2"). Costs are base × tier multiplier (at purchase) × Dreams.
const RANK_MAX := 5  # Without Dreams (Deeper Rings: VII)
const RANK_COSTS: Array[int] = [25, 40, 60, 90, 135]  # Base Dew for ranks I-V (economy pass v2)
const RANK_DAMAGE := 0.10
const RANK_SPEED := 0.04
const RANK_RANGE := 0.1  # Cells
const RANK_NAMES: Array[String] = ["", "I", "II", "III", "IV", "V", "VI", "VII"]

# The forms `data` can grow into, as the Warden panel lists them (screens_ui.md "Grow into"): a Sprout
# lists only the families picked this run (unpicked ones are hidden, not greyed); every other Warden
# lists all its forms, locked or not. [[TowerData, unlocked], …]
static func grow_options(dreams: DreamState, data: TowerData) -> Array:
	var options: Array = dreams.get_evolutions(data)
	if data.line != "sprout" or dreams.unlock_everything:
		return options
	return options.filter(func(option: Array) -> bool: return option[1])

const NO_FAMILY_YET := "Pick a family after the first drift to grow Sprouts."

const GROUP := &"wardens"
const BADGE_COLORS: Array[Color] = [Color(0.85, 0.85, 0.8), Color(0.55, 0.9, 0.6), Color(0.5, 0.75, 1.0), Color(1.0, 0.8, 0.35)]  # Common … Legendary

# Card badges (screens_ui.md "Dream bonuses on Wardens", On the map): a Warden with an active position
# card shows a small badge at its base while in build mode or while Wardens are selected.
static var _badge_reasons := {}
var _badge_cards: Array = []  # Its active position cards (rows), refreshed with its neighbours

static func set_badges_visible(reason: StringName, on: bool) -> void:
	if on == _badge_reasons.has(reason):
		return
	if on:
		_badge_reasons[reason] = true
	else:
		_badge_reasons.erase(reason)
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		for tower in tree.get_nodes_in_group(GROUP):
			tower.queue_redraw()

static func badges_visible() -> bool:
	return not _badge_reasons.is_empty()

# The active position cards on this Warden ([] = no badge).
func get_badge_cards() -> Array:
	return _badge_cards

func _refresh_badge() -> void:
	var cards := []
	if _dream_state and _dream_state.has_method("get_card_effects") and is_inside_tree():
		for row in _dream_state.get_card_effects(tower_data, cell, self):
			if row.get("positional", false) and row.active:
				cards.append(row)
	if cards.size() != _badge_cards.size():
		queue_redraw()
	_badge_cards = cards

# "IV", "XII"…: rank names past VII (Endless Rings) are worked out.
static func rank_name(value: int) -> String:
	if value < RANK_NAMES.size():
		return RANK_NAMES[maxi(value, 0)]
	var out := ""
	for pair in [[90, "XC"], [50, "L"], [40, "XL"], [10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]:
		while value >= pair[0]:
			out += pair[1]
			value -= pair[0]
	return out
const FOCUS_RANK := 3  # The rank that asks for a Focus; its bonus counts from here on
const FOCUS_TOP_RANK := 5  # The Focus bonus stops here (Endless Rings: ranks past it only add damage)
const STAT_TOP_RANK := 7  # Attack speed and range from ranks stop at VII (Endless Rings: VIII+ is damage only)
enum Focus { NONE, POWER, SWIFT, REACH, DEEP }
const FOCUS_NAMES := {Focus.POWER: "Power", Focus.SWIFT: "Swift", Focus.REACH: "Reach", Focus.DEEP: "Deep"}
const FOCUS_TEXT := {Focus.POWER: "+8% damage", Focus.SWIFT: "+6% attack speed", Focus.REACH: "+0.2 range",
	Focus.DEEP: "+10% status strength and duration"}
const FOCUS_COLORS := {Focus.POWER: Color(1.0, 0.5, 0.35), Focus.SWIFT: Color(0.6, 1.0, 0.55),
	Focus.REACH: Color(0.55, 0.8, 1.0), Focus.DEEP: Color(0.8, 0.6, 1.0)}
const FOCUS_POWER := 0.08
const FOCUS_SWIFT := 0.06
const FOCUS_REACH := 0.2
const FOCUS_DEEP := 0.10
const PIP_COLOR := Color(1.0, 0.85, 0.45)
const RANK_ART := "res://assets/towers/ranks/rank_%d_%s.png"
const RANK_UP_ART := preload("res://assets/towers/ranks/rank_up.png")
const RANK_UP_FPS := 16.0
# Crit argument for hit(): roll the dice, or force it (a burst or splash uses its main hit's roll).
const ROLL_CRIT := -1
const NO_CRIT := 0
const CRIT := 1

# The grid cell this tower occupies (set by TowerPlacer).
var cell: Vector2
# All Dew put into this Warden (build cost, evolutions, ranks). Selling refunds a share of it.
var invested_dew := 0
# Nurture rank 0-5 (7 with Deeper Rings): each rank +10% damage, +4% attack speed, +0.1 range, and
# from rank III the Focus bonus. Kept through evolution, like the Focus (chosen at rank III, fixed).
# Setting it from outside (Dream cards, the save) refreshes the rank art and pips too.
var rank := 0:
	set(value):
		rank = value
		_update_rank_art()
		queue_redraw()
var focus: Focus = Focus.NONE:
	set(value):
		focus = value
		queue_redraw()
# What the attack does: `tower_data` itself, or for a Graftling the neighbour it copies.
var attack_data: TowerData
# Who snipers shoot at (the player can change it in the Warden panel).
var target_mode: TowerData.TargetMode = TowerData.TargetMode.FIRST

var _cooldown := 0.0  # Seconds until the tower can attack again
var _anim_time := 0.0
var _attack_time := -1.0  # Seconds into the attack animation; negative while idling
var _attack_fps := 0.0
var _released := false  # The current attack's shot / pulse has happened
var _attack_count := 0  # For "every Nth attack" effects (Thunderhead)
var _damage_share := 1.0  # Graftling: share of the copied Warden's damage
var _dream_state: DreamState
var _hit_before := {}  # Nightmare instance ids already hit (Moonstone's first-hit crit)
var _rings: Array[FairyRing] = []
var _beam_target: Node2D = null
var _beam_behind: Node2D = null
var _beam_ramp := 1.0
var _beam_tick := 0.0
var _aura_tick := 0.0
var _neighbour_timer := 0.0
var _aura_crit := 0.0  # From a White Stag in range
var _aura_range := 0.0  # From a Moon Moth nearby
var _aura_damage := 0.0  # From a Grandmother Oak nearby
var _aura_speed := 0.0
# Grafted Harmony (a Crowned delivery rule): a Graftling touching Wardens of 2+ status families also
# applies each of their statuses at half strength. Status id -> stacks; its two-tone glow.
var _harmony := {}
var _harmony_glow: Array = []
var _lit_cells: Array[Vector2] = []  # Rootlight: path tiles it lights
var _out: Array = []  # Hummingbirds / seeds that are away (the next attack waits for them)
var _catch_tick := 0.0
var _pecks_landed := 0  # Jewelwing Court's Flurry: every Nth peck crits
var _throws := 0  # Seed Storm: every 5th throw
var _catch_streak := 0.0  # Autumn Gale: +damage on the next throw from catches
var _seeds_thrown := 0
var _seeds_home := 0
var _throw_hit := false
var focus_strongest := false  # Jewelwing Court's toggle: all birds on the strongest nightmare
var _echo_tracker: ReactionTracker = null
var _patrol: PatrolFlight = null
var _aura_count := 0  # Other Wardens inside this Warden's aura (Grove Heart)
var _hits_landed := 0  # Eternal Charge / Rooted Nightmares count this Warden's hits
var _hunted := {}  # Hunter's Moon: nightmares this Warden has hit (instance ids)
const ETERNAL_STATIC_EVERY := 4
const ROOTED_NIGHTMARES_EVERY := 8
const ROOTED_TIME := 1.0
const ROOTED_BOSS_TIME := 0.5
var _ability_timer := 0.0  # Rootcurl / Tangleroot / Beacon: seconds until the timed ability
const INTEREST_CAP := 80  # Wellspring: all Wellsprings together pay at most this per rest
var _drifts_yielded := 0  # Sapling: drifts since planted (Dreamlight every N)
var _wither := 0  # Sapling: leaves lost since the last rest (−5% yield each)
var _last_leaves := -1
var _crit_dew_drift := -1  # Magpie's Hoard: drift the crit-Dew count belongs to
var _crit_dew_given := 0

func _ready() -> void:
	_dream_state = get_tree().get_first_node_in_group(DreamState.GROUP) as DreamState
	add_to_group(GROUP)
	_apply_data()
	# Start each tower at a random point in its idle loop so neighbours don't breathe in sync.
	_anim_time = randf() * tower_data.frame_count / tower_data.animation_fps

func _apply_data() -> void:
	attack_data = tower_data
	_damage_share = 1.0
	if not tower_data.has_target_priority:
		target_mode = tower_data.target_mode
	_attack_time = -1.0
	_stop_beam()
	sprite.offset = tower_data.sprite_offset
	_show_idle()
	_update_withered()
	_refresh_neighbours()
	_connect_echo.call_deferred()  # Echo Hollow listens for Reactions (after entering the tree)
	_connect_yield.call_deferred()  # Grandmother Oak / the Sapling pay out after each drift
	if is_instance_valid(_patrol) and attack_data.attack_kind != TowerData.AttackKind.PATROL:
		_patrol.queue_free()
	queue_redraw()

# Grows into `data` in place (the cell and path don't change). `cost` is added to invested Dew.
func evolve(data: TowerData, cost: int) -> void:
	tower_data = data
	invested_dew += cost
	_apply_data()
	evolved.emit(self)
	if data.tier >= 4:
		ascended.emit(self)

func _process(delta: float) -> void:
	_anim_time += delta
	_neighbour_timer -= delta
	if _neighbour_timer <= 0.0:
		_refresh_neighbours()
	if _attack_time >= 0.0:
		_advance_attack(delta)
	elif _beam_target == null:
		sprite.frame = int(_anim_time * tower_data.animation_fps) % tower_data.frame_count
	if tower_data.withered_texture != null and has_node("Withered"):
		(get_node("Withered") as Sprite2D).frame = sprite.frame % tower_data.frame_count
	if rank > 0:
		var art_frame := int(_anim_time * tower_data.animation_fps) % 8
		for art in [get_node_or_null("RankUnder"), get_node_or_null("RankOver")]:
			if art:
				art.frame = art_frame
	if not tower_data.can_attack:
		return
	if tower_data.caught_bonus > 0.0:
		_update_catch(delta)  # Dreamcatchers catch sleepy nightmares whether or not they're shooting
	if attack_data.ability_every > 0.0:
		_update_ability(delta)
	match attack_data.attack_kind:
		TowerData.AttackKind.AURA:
			_update_aura(delta)
			return
		TowerData.AttackKind.PATROL:
			if not is_instance_valid(_patrol):
				_patrol = PatrolFlight.new(self)  # Dawnwing's bird / The Whirlwind's cyclone
				add_child(_patrol)
			if attack_data.patrol_idle_texture != null:
				# Dawnwing: the perch is empty while the bird is out.
				sprite.texture = attack_data.patrol_idle_texture if _patrol.is_out() else tower_data.texture
			return
		TowerData.AttackKind.BEAM:
			_update_beam(delta)
			return
		TowerData.AttackKind.COPY:
			return  # A Graftling with nothing to copy
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown > 0.0 or _attack_time >= 0.0 or not _has_work():
		return
	_start_attack()

# Whether an attack now would do anything.
func _has_work() -> bool:
	match attack_data.attack_kind:
		TowerData.AttackKind.TRAP:
			# Untyped lambda + assign(): a freed ring can't be passed to a typed parameter, and filter()
			# returns an untyped Array (the old line errored every frame once a ring had gone).
			_rings.assign(_rings.filter(func(r) -> bool: return is_instance_valid(r) and not r.is_spent()))
			return _rings.size() < attack_data.trap_max and not _free_trap_cells().is_empty()
		TowerData.AttackKind.SPIN:
			return not _enemies_on_adjacent_tiles().is_empty()
		TowerData.AttackKind.PECK, TowerData.AttackKind.BOOMERANG:
			# Hummingbirds and seeds must come home before the next attack.
			_out = _out.filter(func(n) -> bool: return is_instance_valid(n))
			if not _out.is_empty():
				return false
	return find_target() != null


# --- Effective stats (base × Dreams) ----------------------------------------------------------------

func get_damage() -> float:
	return attack_data.damage * _damage_share * get_rank_damage_multiplier() * (1.0 + _aura_damage) \
		* (_dream_state.get_soothe_multiplier(self) if _dream_state else 1.0)

func get_attacks_per_second() -> float:
	var ranks := mini(get_effective_rank(), STAT_TOP_RANK)
	var speed := 1.0 + RANK_SPEED * (ranks + get_court_ranks()) + (FOCUS_SWIFT * _focus_ranks(ranks) if focus == Focus.SWIFT else 0.0)
	var dreams := 1.0
	if _dream_state:
		dreams = _dream_state.get_attack_speed_multiplier(tower_data)
		if _dream_state.has_method("get_tower_attack_speed_bonus"):
			dreams += _dream_state.get_tower_attack_speed_bonus(self)  # Sprout Chorus, The Last Light
	return attack_data.attacks_per_second * speed * dreams * (1.0 + _aura_speed)

func get_range_cells() -> float:
	var ranks := mini(get_effective_rank(), STAT_TOP_RANK)
	var reach := RANK_RANGE * (ranks + get_court_ranks()) + (FOCUS_REACH * _focus_ranks(ranks) if focus == Focus.REACH else 0.0)
	if _dream_state and _dream_state.has_method("get_tower_range_bonus"):
		reach += _dream_state.get_tower_range_bonus(self)  # Solitude
	var total := get_range_for(attack_data, _dream_state) + _aura_range + reach
	if tower_data.line == "song" and attack_data.attack_kind == TowerData.AttackKind.PULSE:
		total *= 1.0 + HUSH_RADIUS * _rule_stacks(&"hush")  # Hush: wider song pulses
	return total


# --- Nurture ranks -------------------------------------------------------------------------------------

# The rank that counts for stats (The Old Ones can lift it by one next to a rank V+ Warden).
func get_effective_rank() -> int:
	if _dream_state and _dream_state.has_method("get_effective_rank"):
		return _dream_state.get_effective_rank(self)
	return rank

# Ranks from III up (the ones that carry the Focus bonus).
static func _focus_ranks(ranks: int) -> int:
	return maxi(mini(ranks, FOCUS_TOP_RANK) - FOCUS_RANK + 1, 0)  # Focus stops at V

# Damage multiplier from ranks: +10% each (+ Warm Hands), + Power's +8% from rank III.
func get_rank_damage_multiplier() -> float:
	var ranks := get_effective_rank()
	var per_rank := RANK_DAMAGE
	if _dream_state and _dream_state.has_method("get_rank_damage_bonus"):
		per_rank += _dream_state.get_rank_damage_bonus()
	return 1.0 + per_rank * (ranks + get_court_ranks()) + (FOCUS_POWER * _focus_ranks(ranks) if focus == Focus.POWER else 0.0)

# Court of the Eldest: rank-equivalents from touching the Eldest (25% of its rank). They count for the
# per-rank damage, attack speed and range, never the Focus.
func get_court_ranks() -> float:
	if _dream_state and _dream_state.has_method("get_court_rank_share"):
		return _dream_state.get_court_rank_share(self)
	return 0.0

# Potency: the multiplier on this Warden's effect damage (Spored, Static bolts, clouds, pops, Reactions
# it completes, echoes). The Warden's own (100% by default) + Dreams (Bitter Sap, Venom Bloom,
# Nightshade) + the Deep Focus (+10% per rank III–V).
func get_potency() -> float:
	var total := attack_data.potency
	if _dream_state and _dream_state.has_method("get_potency_bonus"):
		total += _dream_state.get_potency_bonus(tower_data)
	if focus == Focus.DEEP:
		total += FOCUS_DEEP * _focus_ranks(get_effective_rank())
	return total

# Deep Focus: status strength and duration multiplier.
func get_status_focus_multiplier() -> float:
	return 1.0 + FOCUS_DEEP * _focus_ranks(get_effective_rank()) if focus == Focus.DEEP else 1.0

func get_max_rank() -> int:
	if _dream_state and _dream_state.has_method("get_max_rank_for"):
		return _dream_state.get_max_rank_for(self)  # Past V only for the Eldest
	if _dream_state and _dream_state.has_method("get_max_rank"):
		return _dream_state.get_max_rank()
	return RANK_MAX

# Attacking Wardens can be nurtured (not walls or wall growths, not the White Stag's aura).
func can_be_nurtured() -> bool:
	if tower_data.dew_per_rank > 0:
		return true  # The Heartwood Sapling: ranks raise its yield
	return tower_data.can_attack and tower_data.line != "wall" \
		and tower_data.attack_kind != TowerData.AttackKind.AURA

func can_nurture() -> bool:
	return can_be_nurtured() and rank < get_max_rank()

# The next rank asks for a Focus first (rank II -> III, no Focus yet).
func needs_focus() -> bool:
	return can_nurture() and tower_data.can_attack and rank + 1 >= FOCUS_RANK and focus == Focus.NONE

# Cost multiplier from the Warden's tier right now: Sprout ×0.5, base ×1, branch ×2, final ×3,
# Memory Warden ×2.
func get_tier_cost_multiplier() -> float:
	if tower_data.nurture_cost_multiplier > 0.0:
		return tower_data.nurture_cost_multiplier  # The Heartwood Sapling ranks at the final-form price
	if tower_data.tier >= 4:
		return 4.0  # Ascended
	if tower_data.is_unique:
		return 2.0
	match tower_data.tier:
		0:
			return 0.5
		1:
			return 1.0
		2:
			return 2.0
	return 3.0

# Dew for the next rank (0 when it can't be nurtured further).
func get_nurture_cost() -> int:
	if not can_nurture():
		return 0
	if free_nurtures_left() > 0:
		return 0  # First Care: the run's first few ranks are free
	return get_nurture_price()

# First Care (a Grove perk): free Nurture ranks left this run (RunState.free_nurtures).
func free_nurtures_left() -> int:
	var run_state = _dream_state.run_state if _dream_state else null
	return run_state.free_nurtures if run_state and "free_nurtures" in run_state else 0

# Dew for the next rank at its normal price (ignoring First Care's free ranks).
func get_nurture_price() -> int:
	if not can_nurture():
		return 0
	var next := rank + 1
	var base: float = RANK_COSTS[rank] if rank < RANK_COSTS.size() else 0.0
	if next > RANK_COSTS.size() and _dream_state and _dream_state.has_method("get_extra_rank_cost"):
		base = _dream_state.get_extra_rank_cost(next)  # Deeper Rings: VI and VII
	var multiplier := get_tier_cost_multiplier()
	if _dream_state and _dream_state.has_method("get_nurture_cost_multiplier"):
		multiplier *= _dream_state.get_nurture_cost_multiplier(self)  # Nursery: Sprouts at half price
	return maxi(roundi(base * multiplier), 1)

# Raises the rank by one; `cost` is added to invested Dew (TowerPlacer.nurture charges it).
# `chosen` sets the Focus when this is the rank that asks for one.
func nurture(cost: int, chosen: Focus = Focus.NONE) -> void:
	if focus == Focus.NONE and chosen != Focus.NONE:
		focus = chosen
	rank = mini(rank + 1, get_max_rank())
	invested_dew += cost
	_play_rank_up()
	queue_redraw()
	nurtured.emit(self)

# The rank's slab art: a halo under the sprite, and a looping overlay on the slab's rim over it.
func _update_rank_art() -> void:
	var under := get_node_or_null("RankUnder") as Sprite2D
	var over := get_node_or_null("RankOver") as Sprite2D
	var art_rank := mini(rank, 7)
	if tower_data.rank_overlay_texture != null:
		# The Sapling has its own rank art: one overlay frame per rank, drawn over it.
		var overlay := get_node_or_null("RankOverlay") as Sprite2D
		if art_rank <= 0:
			if overlay:
				overlay.queue_free()
			return
		if overlay == null:
			overlay = Sprite2D.new()
			overlay.name = "RankOverlay"
			add_child(overlay)
		overlay.texture = tower_data.rank_overlay_texture
		overlay.hframes = tower_data.rank_overlay_frames
		overlay.frame = mini(art_rank, tower_data.rank_overlay_frames) - 1
		overlay.offset = tower_data.sprite_offset
		return
	if art_rank <= 0:
		for node in [under, over]:
			if node:
				node.queue_free()
		return
	if under == null:
		under = Sprite2D.new()
		under.name = "RankUnder"
		under.hframes = 8
		add_child(under)
		move_child(under, 0)  # Drawn before (under) the Warden's sprite
	if over == null:
		over = Sprite2D.new()
		over.name = "RankOver"
		over.hframes = 8
		add_child(over)
	under.texture = load(RANK_ART % [art_rank, "under"])
	over.texture = load(RANK_ART % [art_rank, "over"])

func _play_rank_up() -> void:
	if not is_inside_tree():
		return
	var burst := Sprite2D.new()
	burst.texture = RANK_UP_ART
	burst.hframes = 8
	burst.z_index = 2
	add_child(burst)
	var tween := burst.create_tween()
	tween.tween_property(burst, "frame", 7, 7.0 / RANK_UP_FPS)
	tween.tween_callback(burst.queue_free)

func get_splash_cells() -> float:
	return attack_data.splash_radius * (_dream_state.get_splash_multiplier(tower_data) if _dream_state else 1.0)

func get_crit_chance(enemy: Node2D = null) -> float:
	return minf(get_raw_crit_chance(enemy), 1.0)

# Crit chance before the 100% cap (Full Moon turns what's above 100% into crit damage).
func get_raw_crit_chance(enemy: Node2D = null) -> float:
	var chance := attack_data.crit_chance + _aura_crit
	if _dream_state and _dream_state.has_method("get_rank_crit_bonus"):
		chance += _dream_state.get_rank_crit_bonus() * get_effective_rank()  # The Old Ones
	if _dream_state and _dream_state.has_method("get_crit_chance_bonus"):
		chance += _dream_state.get_crit_chance_bonus(self, enemy)  # Still Target, Starlit Aim, Full Moon…
	if enemy != null and enemy.statuses.is_held():
		chance += attack_data.crit_bonus_vs_held
	return chance

# Range in cells for `data` including Dreams (shared with the build ghost).
static func get_range_for(data: TowerData, dream_state: DreamState) -> float:
	return data.attack_range + (dream_state.get_range_bonus(data) if dream_state else 0.0)


# --- Neighbours and auras -----------------------------------------------------------------------------

# Other Wardens on the map (the tower's siblings).
func _other_towers() -> Array:
	if get_parent() == null:
		return []
	return get_parent().get_children().filter(func(t: Node) -> bool:
		return t is Tower and t != self and not t.is_queued_for_deletion())

# How far this Warden's aura reaches, in cells (aura_radius, or its attack range).
func get_aura_reach() -> float:
	return tower_data.aura_radius if tower_data.aura_radius > 0.0 else tower_data.attack_range

# Grove Heart: +aura_per_warden for each Warden in its radius, keeping the total under aura_max.
func get_aura_extra() -> float:
	if tower_data.aura_per_warden <= 0.0:
		return 0.0
	var base := maxf(tower_data.aura_damage_bonus, tower_data.aura_speed_bonus)
	return clampf(tower_data.aura_per_warden * _aura_count, 0.0, maxf(tower_data.aura_max - base, 0.0))

# Refreshes what depends on nearby Wardens: the copied attack (Graftling) and aura bonuses.
func _refresh_neighbours() -> void:
	_neighbour_timer = NEIGHBOUR_REFRESH
	_aura_crit = 0.0
	_aura_range = 0.0
	_aura_damage = 0.0
	_aura_speed = 0.0
	var aura_count := 0
	var harmony := {}
	var best: Tower = null
	var best_dps := 0.0
	for other in _other_towers():
		var distance: float = other.global_position.distance_to(global_position) / MAP_GRID.cell_size.x
		var data: TowerData = other.tower_data
		if data.aura_crit_bonus > 0.0 and distance <= data.attack_range:
			_aura_crit = maxf(_aura_crit, data.aura_crit_bonus)  # Auras don't stack with themselves
		if (data.aura_damage_bonus > 0.0 or data.aura_speed_bonus > 0.0) and distance <= other.get_aura_reach():
			# Acorn, Elder Stump, Grove Heart, Grandmother Oak. Auras don't stack: the strongest counts.
			var extra: float = other.get_aura_extra()
			if data.aura_damage_bonus > 0.0:
				_aura_damage = maxf(_aura_damage, data.aura_damage_bonus + extra)
			if data.aura_speed_bonus > 0.0:
				_aura_speed = maxf(_aura_speed, data.aura_speed_bonus + extra)
		if (tower_data.aura_damage_bonus > 0.0 or tower_data.aura_speed_bonus > 0.0) and distance <= get_aura_reach():
			aura_count += 1
		if data.range_aura_bonus > 0.0 and distance <= data.range_aura_radius:
			_aura_range = maxf(_aura_range, data.range_aura_bonus)
		if tower_data.attack_kind == TowerData.AttackKind.COPY and data.applies_status != &"" \
				and absf(other.cell.x - cell.x) <= 1 and absf(other.cell.y - cell.y) <= 1:
			harmony[data.applies_status] = maxi(harmony.get(data.applies_status, 0), data.status_stacks)
		if tower_data.attack_kind == TowerData.AttackKind.COPY and _can_copy(other) \
				and absf(other.cell.x - cell.x) <= 1 and absf(other.cell.y - cell.y) <= 1:
			var dps: float = other.get_damage() * other.get_attacks_per_second()
			if dps > best_dps:
				best_dps = dps
				best = other
	_aura_count = aura_count
	_set_harmony(harmony if harmony.size() >= 2 else {})
	_refresh_badge()
	if tower_data.attack_kind != TowerData.AttackKind.COPY:
		return
	var copied: TowerData = best.tower_data if best != null else tower_data
	if copied != attack_data:
		_stop_beam()
		attack_data = copied
	_damage_share = tower_data.copy_share if best != null else 1.0

# Graftlings copy attacking, non-unique Wardens, and never other Graftlings.
static func _can_copy(other: Tower) -> bool:
	var data := other.tower_data
	return data.can_attack and not data.is_unique and data.attack_kind != TowerData.AttackKind.COPY \
		and data.attack_kind != TowerData.AttackKind.AURA

# The Warden this Graftling is copying right now (null = none). For the Warden panel.
func get_copied() -> TowerData:
	return attack_data if tower_data.attack_kind == TowerData.AttackKind.COPY and attack_data != tower_data else null


# --- Attacking ----------------------------------------------------------------------------------------

# Winds up the attack animation; the shot / pulse happens on its release frame.
func _start_attack() -> void:
	_cooldown = 1.0 / get_attacks_per_second()
	if tower_data.attack_texture == null:
		_release()
		return
	# Play the attack faster if it wouldn't finish before the next one is due.
	_attack_fps = maxf(tower_data.attack_animation_fps, tower_data.attack_frame_count * get_attacks_per_second())
	_attack_time = 0.0
	_released = false
	sprite.texture = tower_data.attack_texture
	sprite.hframes = tower_data.attack_frame_count
	sprite.frame = 0

func _advance_attack(delta: float) -> void:
	_attack_time += delta
	var frame := int(_attack_time * _attack_fps)
	if not _released and frame >= tower_data.attack_release_frame:
		_released = true
		_release()
	if frame >= tower_data.attack_frame_count:
		_attack_time = -1.0
		_show_idle()
		return
	sprite.frame = frame

func _show_idle() -> void:
	sprite.texture = tower_data.texture
	sprite.hframes = tower_data.frame_count
	sprite.frame = int(_anim_time * tower_data.animation_fps) % tower_data.frame_count

# Holds the attack pose (the release frame) while beaming.
func _show_attack_pose() -> void:
	if tower_data.attack_texture == null:
		return
	sprite.texture = tower_data.attack_texture
	sprite.hframes = tower_data.attack_frame_count
	sprite.frame = tower_data.attack_release_frame

# The attack lands. A target that left range during the wind-up wastes a projectile/chain/cloud.
func _release() -> void:
	_attack_count += 1
	attack_released.emit(self)
	match attack_data.attack_kind:
		TowerData.AttackKind.PULSE:
			var in_range := get_enemies_in_range()
			var statics := 0
			if attack_data.rain:
				var world := Reactions._world(self)
				if world:
					Fx.rain_sweep(global_position, get_range_pixels(), world)  # Monsoon's sheet of rain
			if attack_data.tier >= 4:
				ascended_event.emit(self, global_position, in_range.size())
			for enemy in in_range:
				if attack_data.hit_effect_texture != null:  # Tidecaller's wave, World Root's grasp
					play_sheet(attack_data.hit_effect_texture, attack_data.hit_effect_frames,
						attack_data.hit_effect_anchor, enemy.global_position,
						enemy.global_position.x < global_position.x)
				hit(enemy, 1.0, true)
				_push(enemy)
				if _set_off_static(enemy):
					statics += 1
			if statics > 0 and attack_data.tier >= 4:
				statics_set_off.emit(self, global_position, statics)  # The Great Bell's toll
		TowerData.AttackKind.CHAIN:
			var target := find_target()
			if target != null:
				_chain_strike(target)
		TowerData.AttackKind.CLOUD:
			var target := find_target()
			if target != null:
				_drop_cloud(target)
		TowerData.AttackKind.TRAP:
			_plant_ring()
		TowerData.AttackKind.PECK:
			_send_hummingbirds()
		TowerData.AttackKind.BOOMERANG:
			_throw_seeds()
		TowerData.AttackKind.SPREAD:
			_spread()
		TowerData.AttackKind.SPIN:
			_spin()
		TowerData.AttackKind.PULL:
			var target := find_target()
			if target != null:
				_grab(target)
		TowerData.AttackKind.LIGHT:
			_light()
		TowerData.AttackKind.AURA:
			pass  # The White Stag's pulse is only its animation; the aura works in _update_aura
		_:
			# Starling Murmuration swoops at several different nightmares at once.
			for target in find_targets(attack_data.multi_targets):
				fire_at(target)
				if _twin_puff():
					fire_at(target)  # Twin Puff: this Sporeling attack fires twice

# Soothes `enemy` and applies this Warden's status. `is_area`: splash, pulse and cloud hits (creatures
# with an attack-shape resistance, like the Bee Swarm, take these differently). `crit`: ROLL_CRIT,
# NO_CRIT or CRIT. The creature's family resistance or weakness to this Warden's line is applied in
# Enemy.take_damage. `combo`: a DamageLog combo tag this hit owes itself to (&"conducted").
# Returns whether it was a crit.
func hit(enemy: Node2D, soothe_multiplier: float = 1.0, is_area: bool = false, crit: int = ROLL_CRIT,
		combo: StringName = &"") -> bool:
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return false
	var is_crit := roll_crit(enemy) if crit == ROLL_CRIT else crit == CRIT
	if attack_data.dew_mark:
		enemy.bonus_dew = maxi(enemy.bonus_dew, 1)  # Before the hit, so a dispelling hit counts
	var soothe := get_damage() * soothe_multiplier * _damage_against(enemy)
	if _dream_state and _dream_state.has_method("get_hit_damage_multiplier"):
		soothe *= _dream_state.get_hit_damage_multiplier()  # Venom Bloom: hits weaker, effects stronger
	# Reactions that change a hit: Pinned (a guaranteed ×3 crit) and Shatter (×2.5, shards).
	var reaction := Reactions.before_hit(enemy, self, is_crit)
	is_crit = reaction.crit
	var crit_multiplier: float = reaction.crit_multiplier
	if is_crit and _dream_state and _dream_state.has_method("get_crit_overflow_multiplier"):
		crit_multiplier += _dream_state.get_crit_overflow_multiplier(get_raw_crit_chance(enemy))  # Full Moon
	var non_crit := 1.0
	if not is_crit and _dream_state and _dream_state.has_method("get_non_crit_multiplier"):
		non_crit = _dream_state.get_non_crit_multiplier()  # Reckless Bloom
	var dealt: float = soothe * (crit_multiplier if is_crit else non_crit) * reaction.multiplier
	if reaction.tag != &"":
		combo = reaction.tag
	enemy.take_damage(dealt, tower_data.line, is_area, is_crit, self, combo)
	if reaction.shatter:
		Reactions.shatter_splash(enemy, self, dealt)
	if is_crit:
		_shattering_blow(enemy, dealt)
	if _dream_state and _dream_state.has_rule(&"thousand_cuts") and is_instance_valid(enemy):
		enemy.statuses.add_cut()  # Every hit within 2 s: +2% damage taken from everyone (max +60%)
	hit_landed.emit(self, enemy, is_area, is_crit)
	apply_status_to(enemy, soothe)
	_after_hit(enemy, is_crit)
	_legendary_hit_rules(enemy, soothe)
	if is_crit:
		crit_landed.emit(self, enemy)
	if attack_data.pop_at_stacks > 0 and is_instance_valid(enemy) and not enemy.is_cleansed \
			and enemy.statuses.stacks(EnemyStatuses.SPORED) >= attack_data.pop_at_stacks:
		pop(enemy)
	return is_crit

# Hit rules of the new Legendaries (dream_design.md "New Legendaries"), read by rule id:
# Hunter's Moon (a Warden's first hit on a nightmare Exposes it, and that never runs out), Eternal
# Static (every 4th hit adds a Charge, and Charge never decays), Rooted Nightmares (every 8th hit Roots
# it for 1 s, bosses 0.5 s).
func _legendary_hit_rules(enemy: Node2D, soothe: float) -> void:
	if _dream_state == null or not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	_hits_landed += 1
	var s: EnemyStatuses = enemy.statuses
	if _dream_state.has_rule(&"hunters_moon"):
		s.marked_forever = true
		var id := enemy.get_instance_id()
		if not _hunted.has(id):
			_hunted[id] = true
			if _hunted.size() > 512:
				_hunted.clear()  # Forget long-gone nightmares now and then
			_apply_one_status(enemy, EnemyStatuses.MARKED, 1, soothe)
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	if _dream_state.has_rule(&"eternal_static"):
		s.static_forever = true
		if _hits_landed % ETERNAL_STATIC_EVERY == 0:
			enemy.apply_status(EnemyStatuses.STATIC, 1, 0.0, soothe, 0, "light", self)
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	if _dream_state.has_rule(&"rooted_nightmares") and _hits_landed % ROOTED_NIGHTMARES_EVERY == 0:
		var time := ROOTED_BOSS_TIME if s.is_boss else ROOTED_TIME
		enemy.apply_status(EnemyStatuses.HELD, 1, time, 0.0, 0, tower_data.line, self)

# Puffball: `enemy`'s Spored stacks burst. Pop damage (6 × stacks, Dreams included) hits it and every
# nightmare within pop_radius as an area spore hit that never crits, logged as a "popped" combo.
# Its stacks are used up and half of them drift on to the nearest few nightmares, still credited to
# the Warden that applied them. With the Chain Bloom rule, a nightmare those spores bring to the
# threshold pops too (each nightmare at most once per chain).
func pop(enemy: Node2D, chain: Dictionary = {}) -> void:
	var statuses: EnemyStatuses = enemy.statuses
	var stacks := statuses.stacks(EnemyStatuses.SPORED)
	if stacks <= 0 or chain.has(enemy.get_instance_id()):
		return
	chain[enemy.get_instance_id()] = true
	var potency := statuses.potency(EnemyStatuses.SPORED)
	var duration := statuses.time_left(EnemyStatuses.SPORED)
	var line := statuses.spore_line()
	var applier := statuses.source(EnemyStatuses.SPORED)
	statuses.remove(EnemyStatuses.SPORED)
	var at := enemy.global_position
	var damage := attack_data.pop_damage_per_stack * stacks * get_rank_damage_multiplier() \
		* (_dream_state.get_soothe_multiplier(self) if _dream_state else 1.0)
	var reach := attack_data.pop_radius * MAP_GRID.cell_size.x
	for other in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if other.global_position.distance_to(at) <= reach:
			other.take_damage(damage, tower_data.line, true, false, self, &"popped")
	# Final-form signature: a big bloom of light (the plain burst without the effects player).
	if Reactions._effect(&"puffball_bloom", at, self) == null:
		add_child(SporePop.new(at, reach))
	popped.emit(self, enemy, stacks)

	# Half the spores drift on to the nearest nightmares (not back onto the one that popped).
	var spread := stacks / 2
	if spread <= 0:
		return
	var others := get_tree().get_nodes_in_group(ENEMY_GROUP).filter(func(e: Node2D) -> bool:
		return e != enemy and e.global_position.distance_to(at) <= POP_SPREAD_RANGE * MAP_GRID.cell_size.x)
	others.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
	var chain_bloom := _dream_state != null and _dream_state.has_rule(&"chain_bloom")
	for i in mini(attack_data.pop_spread_targets, others.size()):
		var other: Node2D = others[i]
		other.apply_status(EnemyStatuses.SPORED, spread, duration, potency, attack_data.status_max_stacks,
			line, applier)
		if chain_bloom and is_instance_valid(other) and not other.is_cleansed \
				and other.statuses.stacks(EnemyStatuses.SPORED) >= attack_data.pop_at_stacks:
			pop(other, chain)

# Twin Puff: every 3rd Sporeling attack (II: every 2nd) fires twice.
func _twin_puff() -> bool:
	if tower_data.get_id() != "sporeling" or _dream_state == null or not _dream_state.has_rule(&"twin_puff"):
		return false
	var every := 2 if _dream_state.rule_level(&"twin_puff") > 0 else 3
	return _attack_count % every == 0

# Shattering Blow: a crit splashes 50% of its damage within 1 cell (II: 75% within 1.5). The splash
# is area damage and never crits itself.
func _shattering_blow(enemy: Node2D, dealt: float) -> void:
	if _dream_state == null or not _dream_state.has_rule(&"shattering_blow"):
		return
	var deep := _dream_state.rule_level(&"shattering_blow") > 0
	var share := 0.75 if deep else 0.5
	var reach := (1.5 if deep else 1.0) * MAP_GRID.cell_size.x
	var at := enemy.global_position
	for other in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if other != enemy and other.global_position.distance_to(at) <= reach:
			other.take_damage(dealt * share, tower_data.line, true, false, self, &"shattering_blow")

# Rolls for a crit on `enemy` (Moonstone: the first hit on each nightmare always crits).
func roll_crit(enemy: Node2D) -> bool:
	if not is_instance_valid(enemy):
		return false
	var id := enemy.get_instance_id()
	var first := not _hit_before.has(id)
	_hit_before[id] = true
	if attack_data.first_hit_crits and first:
		Reactions._effect(&"moonstone_beam", enemy.global_position, self)  # Signature: a moonbeam from above
		return true
	if attack_data.crits_vs_drowsy and enemy.statuses.has(EnemyStatuses.DROWSY):
		return true  # Boulderback: a guaranteed crit on Drowsy, no roll
	if attack_data.crits_vs_held and enemy.statuses.is_held():
		return true  # Old Mountain: and on Held
	var chance := get_crit_chance(enemy)
	return chance > 0.0 and randf() < chance

# Damage multiplier for this Warden against `enemy`: sniper distance bonus, favoured prey.
func _damage_against(enemy: Node2D) -> float:
	var multiplier := 1.0
	if attack_data.distance_bonus_per_cell > 0.0:
		var cells := global_position.distance_to(enemy.global_position) / MAP_GRID.cell_size.x
		multiplier += clampf((cells - attack_data.distance_bonus_from) * attack_data.distance_bonus_per_cell,
			0.0, attack_data.distance_bonus_max)
	if attack_data.bonus_vs_multiplier != 1.0:
		var kind: String = enemy.enemy_data.resource_path.get_file().get_basename()
		if kind in attack_data.bonus_vs_enemies or (attack_data.bonus_vs_sprinting and enemy.rolling):
			multiplier *= attack_data.bonus_vs_multiplier
	# Mossback / Boulderback cash in Marked: double damage (Codex: Marked Blow).
	if attack_data.marked_multiplier != 1.0 and enemy.statuses.has(EnemyStatuses.MARKED):
		multiplier *= attack_data.marked_multiplier
		ComboFeedback.report(&"marked_blow", self)
	return multiplier

# On-hit rules: freeze (Frostfern), Dew from crits (Magpie's Hoard).
func _after_hit(enemy: Node2D, is_crit: bool) -> void:
	if attack_data.freeze_duration > 0.0 and enemy.freeze_cooldown <= 0.0 and not enemy.is_cleansed \
			and (attack_data.freeze_needs == &"" or enemy.statuses.has(attack_data.freeze_needs)):
		enemy.freeze_cooldown = attack_data.freeze_cooldown
		enemy.apply_status(EnemyStatuses.HELD, 1, attack_data.freeze_duration)
		if attack_data.held_damage_bonus > 0.0:
			enemy.statuses.held_bonus = maxf(enemy.statuses.held_bonus, attack_data.held_damage_bonus)  # World Root
	if is_crit and attack_data.crit_dew > 0:
		_give_crit_dew(enemy.global_position)

# Magpie's Hoard: +Dew per crit, capped per drift.
func _give_crit_dew(where: Vector2) -> void:
	if _dream_state == null:
		return
	var drift: int = _dream_state.drift_director.drifts_started
	if drift != _crit_dew_drift:
		_crit_dew_drift = drift
		_crit_dew_given = 0
	if _crit_dew_given >= attack_data.crit_dew_per_drift:
		return
	_crit_dew_given += 1
	_dream_state.run_state.earn_dew_at(attack_data.crit_dew, where)

func apply_status_to(enemy: Node2D, soothe: float) -> void:
	# Bellflower: its Drowsy only comes with every Nth pulse.
	if attack_data.status_every <= 1 or _attack_count % attack_data.status_every == 0:
		_apply_one_status(enemy, attack_data.applies_status, attack_data.status_stacks, soothe)
	if attack_data.extra_status != &"":
		_apply_one_status(enemy, attack_data.extra_status, attack_data.extra_status_stacks, soothe)  # Lullaby Bell
	for status in _harmony:  # Grafted Harmony: each neighbour family's status at half strength
		_apply_one_status(enemy, status, maxi(_harmony[status] / 2, 1), soothe * 0.5)
	_put_to_sleep(enemy)

# Grafted Harmony turns on or off (a Graftling touching Wardens of 2+ status families), with a glow
# whose left and right halves are tinted with two of the statuses' colours.
func _set_harmony(harmony: Dictionary) -> void:
	if harmony.keys() == _harmony.keys():
		return
	_harmony = harmony
	for glow in _harmony_glow:
		if is_instance_valid(glow):
			glow.queue_free()
	_harmony_glow.clear()
	if _harmony.is_empty() or not is_inside_tree():
		return
	var ids: Array = _harmony.keys()
	for i in 2:
		var glow := Fx.play([&"grafted_harmony_a", &"grafted_harmony_b"][i], global_position, self, 1.0, false, 1e6)
		if glow != null:
			glow.modulate = EnemyStatuses.COLORS.get(ids[i], Color.WHITE)
			_harmony_glow.append(glow)

# Dreamshroom: a nightmare at full Drowsy falls asleep (once each; bosses never sleep, their cap is 3).
func _put_to_sleep(enemy: Node2D) -> void:
	if attack_data.sleep_at_max_drowsy <= 0.0 or not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	var s: EnemyStatuses = enemy.statuses
	if s.is_boss or s.dreamshroom_slept or not s.has(EnemyStatuses.DROWSY) \
			or s.stacks(EnemyStatuses.DROWSY) < s.get_max_stacks(EnemyStatuses.DROWSY):
		return
	s.dreamshroom_slept = true
	var was_asleep := s.is_asleep()
	s.sleep_time = maxf(s.sleep_time, attack_data.sleep_at_max_drowsy)
	ComboFeedback.report(&"asleep", self)  # Codex: Asleep
	if not was_asleep:
		put_to_sleep.emit(self, enemy)

func _apply_one_status(enemy: Node2D, status: StringName, stacks: int, soothe: float) -> void:
	if status == &"" or not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	var potency := soothe
	if status == EnemyStatuses.SPORED:
		potency = soothe * SPORE_POTENCY
	elif status == EnemyStatuses.DAMP:
		potency = 1.0  # Damp's potency is its slow strength, not soothe
	var duration := attack_data.status_duration
	var max_stacks := attack_data.status_max_stacks
	if _dream_state:
		potency *= _dream_state.get_status_strength_multiplier(status)
		duration = _dream_state.get_status_duration(attack_data, status)
		max_stacks = _dream_state.get_status_max_stacks(attack_data, status)
	var deep := get_status_focus_multiplier()  # Deep Focus: stronger and longer
	if deep != 1.0:
		if duration <= 0.0:
			duration = EnemyStatuses.DEFAULT_DURATION[status]
		duration *= deep  # Its strength side is Potency (get_potency)
	var at: Vector2 = enemy.global_position
	enemy.apply_status(status, stacks, duration, potency, max_stacks, tower_data.line, self)
	# Guiding Light: Marked spreads to nightmares within 1 tile of the target (II: 2 tiles).
	if status == EnemyStatuses.MARKED and _dream_state and _dream_state.has_rule(&"guiding_light"):
		var reach := (2.0 if _dream_state.rule_level(&"guiding_light") > 0 else 1.0) * MAP_GRID.cell_size.x
		for other in get_tree().get_nodes_in_group(ENEMY_GROUP):
			if other != enemy and other.global_position.distance_to(at) <= reach:
				other.apply_status(status, stacks, duration, potency, max_stacks, tower_data.line, self)

# Projectile landed at `where` (on `target` if it's still there): soothe it, or everything in the
# splash radius (the splash shares the main hit's crit roll).
func projectile_landed(target: Node2D, where: Vector2) -> void:
	var splash := get_splash_cells() * MAP_GRID.cell_size.x
	if splash <= 0.0:
		hit(target)
		# Sharp Beaks: Wren's Nest's wrens strike again (+1 per stack).
		if tower_data.get_id() == "wrens_nest":
			for i in _rule_stacks(&"sharp_beaks"):
				hit(target)
		return
	var crit := CRIT if target != null and is_instance_valid(target) and roll_crit(target) else NO_CRIT
	if attack_data.splash_share < 1.0 and target != null and is_instance_valid(target):
		# Boulderback: the full hit on its target, a share of it to everything else nearby.
		hit(target, 1.0, false, crit)
		for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
			if enemy != target and enemy.global_position.distance_to(where) <= splash:
				hit(enemy, attack_data.splash_share, true, crit)
	else:
		_splash(where, splash, 1.0, crit)
	if attack_data.lob:
		_lob_landed(where, splash)
	if attack_data.impact_texture != null:  # Old Mountain's crush
		play_sheet(attack_data.impact_texture, attack_data.impact_frames, attack_data.impact_anchor, where)

func _splash(where: Vector2, radius: float, share: float, crit: int) -> void:
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if enemy.global_position.distance_to(where) <= radius:
			hit(enemy, share, true, crit)

# Cairn / Rockslide: a lobbed stone came down. Loose Stones breaks it into 3 smaller splashes nearby;
# Rockslide leaves rubble on the path tiles it hit.
func _lob_landed(where: Vector2, splash: float) -> void:
	Reactions._effect(&"landing_dust", where, self, splash / MAP_GRID.cell_size.x)
	var hit_spots: Array[Vector2] = [where]
	if _dream_state and _dream_state.has_rule(&"loose_stones"):
		for i in 3:
			var spot := where + Vector2.from_angle(randf() * TAU) * randf_range(0.5, 1.5) * MAP_GRID.cell_size.x
			spot = MAP_GRID.calculate_map_position(MAP_GRID.calculate_grid_coordinates(spot))  # A tile centre
			_splash(spot, MAP_GRID.cell_size.x * 0.5, LOOSE_STONE_SHARE, NO_CRIT)
			Reactions._effect(&"crit_flare", spot, self, 0.6)
			hit_spots.append(spot)
	if attack_data.rubble_slow <= 0.0:
		return
	var route := _route()
	var cells: Array[Vector2] = []
	for spot in hit_spots:
		for at in route:
			if not cells.has(at) and MAP_GRID.calculate_map_position(at).distance_to(spot) <= splash:
				cells.append(at)
	if not cells.is_empty():
		var rubble := RubblePatch.new(cells, attack_data.rubble_slow, attack_data.rubble_time)
		var world := Reactions._world(self)
		var any_nightmare := get_tree().get_first_node_in_group(Tower.ENEMY_GROUP)
		world.add_child(rubble)
		if any_nightmare:  # On the ground: just before the nightmares' container, so it draws under them
			world.move_child(rubble, any_nightmare.get_parent().get_index())

func fire_at(target: Node2D) -> void:
	var projectile := Projectile.new(target, attack_data, projectile_landed)
	add_child(projectile)
	projectile.global_position = global_position + tower_data.get_attack_origin()

# Whirligig: pulses nudge nightmares back a little (each at most once per push_cooldown).
# The timed ability (warden_stats.md, Rootling and Firefly Jar families): every ability_every seconds
# while a nightmare is in range. Rootcurl / Long Way Home pull the one furthest along back along its
# route, Tangleroot / Snugroot Hold the ones furthest along, Beacon Marks everything in range.
func _update_ability(delta: float) -> void:
	_ability_timer -= delta
	if _ability_timer > 0.0:
		return
	var in_range := get_enemies_in_range()
	if in_range.is_empty():
		return
	_ability_timer = attack_data.ability_every
	in_range.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.get_remaining_distance() < b.get_remaining_distance())  # Furthest along first
	if attack_data.mark_all:
		for enemy in in_range:
			_apply_one_status(enemy, EnemyStatuses.MARKED, 1, get_damage())
			if is_instance_valid(enemy) and enemy.statuses.has(EnemyStatuses.MARKED):
				enemy.statuses.marked_extra = maxf(enemy.statuses.marked_extra, attack_data.marked_bonus)
		Reactions._effect(&"pinned", global_position, self, 0.6)  # A flare of light from the Beacon
	if attack_data.pull_tiles > 0.0:
		for enemy in in_range:
			if attack_data.pull_once and enemy.has_meta(&"pulled_home"):
				continue
			var tiles: float = attack_data.pull_boss_tiles if enemy.enemy_data.is_boss else attack_data.pull_tiles
			var before: Vector2 = enemy.global_position
			enemy.push_back(tiles * MAP_GRID.cell_size.x)
			if attack_data.pull_once:
				enemy.set_meta(&"pulled_home", true)
			var world := Reactions._world(self)
			if world:
				Fx.segment(&"long_way_home_drag", before, enemy.global_position, world, 0.4)
			break  # One nightmare per pull
	if attack_data.hold_targets > 0:
		for enemy in in_range.slice(0, attack_data.hold_targets):
			enemy.apply_status(EnemyStatuses.HELD, 1, attack_data.hold_time, 0.0, 0, tower_data.line, self)

# Wellspring: at every rest, a share of your banked Dew (per Wellspring and for all of them together).
func _on_rest_interest(block: int, _boss: bool, _bonus: int, _perfect: bool) -> void:
	if not is_inside_tree() or is_queued_for_deletion() or tower_data.rest_interest <= 0.0:
		return
	var run_state: RunState = _dream_state.run_state
	if run_state.get_meta(&"interest_block", -1) != block:
		run_state.set_meta(&"interest_block", block)
		run_state.set_meta(&"interest_paid", 0)
	var paid: int = run_state.get_meta(&"interest_paid", 0)
	var dew := mini(floori(run_state.dew * tower_data.rest_interest), tower_data.rest_interest_max)
	dew = mini(dew, INTEREST_CAP - paid)
	if dew <= 0:
		return
	run_state.set_meta(&"interest_paid", paid + dew)
	run_state.earn_dew_at(dew, global_position)
	sap_yielded.emit(self, dew)

func _push(enemy: Node2D) -> void:
	if attack_data.push_back_tiles <= 0.0 or not is_instance_valid(enemy) or enemy.is_cleansed \
			or enemy.push_cooldown > 0.0:
		return
	enemy.push_cooldown = attack_data.push_cooldown
	enemy.push_back(attack_data.push_back_tiles * MAP_GRID.cell_size.x)

# Lightning: jumps from creature to creature (further between Damp ones). Thunderhead's every Nth
# strike and the Conductive Soil Dream also hit every Damp creature in range.
func _chain_strike(first: Node2D) -> void:
	var hits: Array[Node2D] = [first]
	var max_hits := attack_data.chain_targets
	if first.statuses.has(EnemyStatuses.DAMP):
		max_hits += CHAIN_DAMP_EXTRA_JUMPS
	while hits.size() < max_hits:
		var next := _nearest_jump(hits)
		if next == null:
			break
		hits.append(next)
	if attack_data.chain_all_in_range:
		# Stormheart: the chain goes on until every nightmare in range is struck.
		for enemy in get_enemies_in_range():
			if not hits.has(enemy):
				hits.append(enemy)

	var storm := attack_data.storm_every > 0 and _attack_count % attack_data.storm_every == 0
	if storm:
		Reactions._effect(&"thunderhead_strike", first.global_position, self)  # Signature: a bolt from the sky
	if storm or (_dream_state and _dream_state.has_rule(&"conductive_soil")):
		for enemy in get_enemies_in_range():
			if enemy.statuses.has(EnemyStatuses.DAMP) and not hits.has(enemy):
				hits.append(enemy)

	# Jumps past the normal count only happened through Damp (DamageLog: "conducted").
	var points := PackedVector2Array([global_position + tower_data.get_attack_origin()])
	# Static Bloom: every nightmare the chain strikes also gets Drowsy (II: 2 stacks).
	var bloom := 0
	if _dream_state and _dream_state.has_rule(&"static_bloom"):
		bloom = 2 if _dream_state.rule_level(&"static_bloom") > 0 else 1
	for i in hits.size():
		var enemy := hits[i]
		points.append(enemy.global_position)
		var falloff := maxf(1.0 - attack_data.chain_falloff * i, 0.1)  # Stormheart: −15% per jump
		hit(enemy, falloff, false, ROLL_CRIT, &"conducted" if i >= attack_data.chain_targets and not attack_data.chain_all_in_range else &"")
		if bloom > 0 and is_instance_valid(enemy) and not enemy.is_cleansed:
			enemy.apply_status(EnemyStatuses.DROWSY, bloom, 0.0, 0.0, 0, tower_data.line, self)
	if attack_data.tier >= 4:
		ascended_event.emit(self, first.global_position, hits.size())
	var bolt := ChainBolt.new(points)
	add_child(bolt)

# The unstruck creature closest to any creature already struck, within jump range (longer between
# two Damp creatures). Lightning spreads through a group rather than running off in one direction.
func _nearest_jump(struck: Array[Node2D]) -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if struck.has(enemy):
			continue
		for from in struck:
			var reach := attack_data.chain_jump_range
			if from.statuses.has(EnemyStatuses.DAMP) and enemy.statuses.has(EnemyStatuses.DAMP):
				reach += CHAIN_DAMP_EXTRA_RANGE
			var distance := from.global_position.distance_to(enemy.global_position)
			if distance <= reach * MAP_GRID.cell_size.x and distance < best_distance:
				best_distance = distance
				best = enemy
	return best

# A lingering cloud on the path tile the target is walking through.
func _drop_cloud(target: Node2D) -> void:
	var center: Vector2 = MAP_GRID.calculate_map_position(target.get_current_cell())
	var cloud := PathCloud.new(self, center)
	add_child(cloud)
	cloud_formed.emit(self, center, attack_data.cloud_duration)


# --- New kinds -------------------------------------------------------------------------------------------

# The route nightmares walk from the start (empty without a map, e.g. in isolated tests).
func _route() -> PackedVector2Array:
	if _dream_state == null or _dream_state.map_generator == null:
		return PackedVector2Array()
	var map = _dream_state.map_generator
	return map.get_path_from(map.startPath)

func _is_cell_in_range(at: Vector2) -> bool:
	var distance := global_position.distance_to(MAP_GRID.calculate_map_position(at))
	return distance <= get_range_pixels() and distance >= attack_data.min_range * MAP_GRID.cell_size.x

# Fairy Ring: route tiles in range without a ring on them.
func _free_trap_cells() -> Array[Vector2]:
	var taken := {}
	for ring in _rings:
		if is_instance_valid(ring):
			taken[ring.cell] = true
	var free: Array[Vector2] = []
	for at in _route():
		if not taken.has(at) and _is_cell_in_range(at):
			free.append(at)
	return free

func _plant_ring() -> void:
	var free := _free_trap_cells()
	if free.is_empty():
		return
	var ring := FairyRing.new(self, free[randi() % free.size()])
	add_child(ring)
	_rings.append(ring)
	trap_set.emit(self, ring.global_position)

# --- Bellflower family (song and sleep) -----------------------------------------------------------------

# Chime Stone / Lullaby Bell: a pulse sets off a Static bolt on nightmares carrying enough charge.
# Returns whether it set one off.
func _set_off_static(enemy: Node2D) -> bool:
	var at := attack_data.sets_off_static_at
	if at <= 0 or not is_instance_valid(enemy) or enemy.is_cleansed:
		return false
	var s: EnemyStatuses = enemy.statuses
	if s.stacks(EnemyStatuses.STATIC) < at:
		return false
	var bolt := s.potency(EnemyStatuses.STATIC) * EnemyStatuses.STATIC_BOLT_MULTIPLIER
	var source := s.source(EnemyStatuses.STATIC)
	s.remove(EnemyStatuses.STATIC)
	Reactions.strike_bolt(enemy, bolt, source if source else self, &"static")
	ComboFeedback.report(&"set_off", self)  # Codex: a pulse set off Static
	return true

# Dreamcatcher: every AURA_TICK, nightmares in range that are asleep or at full Drowsy are Caught
# (+damage taken). Great Dreamcatcher also lengthens sleep once per nightmare and marks them for
# Dreamlight shards; Bad Dreams keeps Caught nightmares Drowsy.
func _update_catch(delta: float) -> void:
	_catch_tick -= delta
	if _catch_tick > 0.0:
		return
	_catch_tick = AURA_TICK
	var bad_dreams := 0
	if _dream_state and _dream_state.has_rule(&"bad_dreams"):
		bad_dreams = 2 if _dream_state.rule_level(&"bad_dreams") > 0 else 1
	for enemy in get_enemies_in_range():
		var s: EnemyStatuses = enemy.statuses
		if tower_data.sleep_extend > 0.0 and s.is_asleep() and not s.sleep_extended:
			s.sleep_extended = true
			s.sleep_time += tower_data.sleep_extend
		if not s.is_catchable():
			continue
		if not s.is_caught():
			Reactions._effect(&"caught", enemy.global_position, self, 1.0, 0.8)  # The dreamcatcher glyph
			ComboFeedback.report(&"caught", self)  # Codex: a nightmare is Caught
		s.caught_time = AURA_TICK * 1.6
		s.caught_bonus = maxf(s.caught_bonus if s.is_caught() else 0.0, tower_data.caught_bonus)
		if tower_data.caught_shards:
			s.caught_shard = true
			s.caught_shard_tower = self  # Told when the shard drops (shard_dropped)
		if bad_dreams > 0:
			s.bad_dreams_timer += AURA_TICK
			while s.bad_dreams_timer >= 1.0:
				s.bad_dreams_timer -= 1.0
				enemy.apply_status(EnemyStatuses.DROWSY, bad_dreams, 0.0, 0.0, 0, tower_data.line, self)

# Echo Hollow: listens for Reactions; one within range repeats 1 s later on the same spot.
func _connect_echo() -> void:
	if _echo_tracker and _echo_tracker.reaction_fired.is_connected(_on_reaction_nearby):
		_echo_tracker.reaction_fired.disconnect(_on_reaction_nearby)
	_echo_tracker = null
	if tower_data.echo_share <= 0.0 or not is_inside_tree():
		return
	_echo_tracker = ReactionTracker.find(self)
	if _echo_tracker:
		_echo_tracker.reaction_fired.connect(_on_reaction_nearby)

func _on_reaction_nearby(id: StringName, enemy: Node2D, chain: int, towers: Array) -> void:
	if not is_instance_valid(enemy) or tower_data.echo_share <= 0.0:
		return
	var depth := _echo_tracker.echo_depth
	var encore := _dream_state != null and _dream_state.has_rule(&"encore")
	if depth > 0 and not (encore and depth == 1):
		return  # Echoes don't echo (Encore: once more, at half strength)
	var spot := enemy.global_position
	if spot.distance_to(global_position) > get_range_pixels():
		return
	var share := tower_data.echo_share * (0.5 if depth == 1 else 1.0)
	var applier: Tower = null
	for t in towers:
		if is_instance_valid(t) and t is Tower:
			applier = t
			break
	var as_link := tower_data.echo_is_chain_link
	get_tree().create_timer(1.0, false).timeout.connect(func() -> void:
		Reactions.echo(id, spot, share, self, applier, chain, as_link, depth + 1))


# --- Yields (Grandmother Oak, the Heartwood Sapling) ---------------------------------------------------

const WITHER_PER_LEAF := 0.05  # Sapling: each leaf lost since the last rest

func _connect_yield() -> void:
	if _dream_state == null or not is_inside_tree():
		return
	if _dream_state.has_signal("eldest_changed") and not _dream_state.eldest_changed.is_connected(_on_eldest_changed):
		_dream_state.eldest_changed.connect(_on_eldest_changed)
	var director: DriftDirector = _dream_state.drift_director
	if tower_data.rest_interest > 0.0 and not director.rest_started.is_connected(_on_rest_interest):
		director.rest_started.connect(_on_rest_interest)  # Wellspring
	if tower_data.dew_per_drift <= 0:
		return
	if not director.drift_cleared.is_connected(_on_drift_cleared):
		director.drift_cleared.connect(_on_drift_cleared)
		director.rest_started.connect(func(_b, _boss, _bonus, _perfect) -> void:
			_wither = 0
			_update_withered())
		var run_state: RunState = _dream_state.run_state
		_last_leaves = run_state.leaves
		run_state.leaves_changed.connect(_on_leaves_changed)

func _on_eldest_changed(_eldest) -> void:
	queue_redraw()  # The crown moves

func _on_leaves_changed(leaves: int, _max_leaves: int) -> void:
	if tower_data.rooted and _last_leaves >= 0 and leaves < _last_leaves:
		_wither += _last_leaves - leaves  # Leaks wither the Sapling until the next rest
		withered.emit(self)
		_update_withered()
	_last_leaves = leaves

# Dew (and for the Sapling, a Dreamlight every few drifts) at the end of each drift.
func _on_drift_cleared(_number: int, _bonus: int, _perfect: bool) -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	var dew := get_drift_yield()
	if dew > 0:
		_dream_state.run_state.earn_dew_at(dew, global_position)
		sap_yielded.emit(self, dew)
		_play_ripen()
	if tower_data.dreamlight_every > 0:
		_drifts_yielded += 1
		var every := tower_data.dreamlight_every
		if rank >= FOCUS_RANK and tower_data.dreamlight_every_ranked > 0:
			every = tower_data.dreamlight_every_ranked
		if _drifts_yielded % every == 0:
			_dream_state.add_dreamlight(1)  # The Sapling ripens
			dreamlight_ripened.emit(self)

# Dew this Warden yields at the end of a drift right now.
func get_drift_yield() -> int:
	var dew := tower_data.dew_per_drift + tower_data.dew_per_rank * rank
	return roundi(dew * maxf(1.0 - WITHER_PER_LEAF * _wither, 0.0))

# Plays one pass of a sheet (a row of `frames`) with its `anchor` pixel on `at`, in the world (never
# under the Warden or nightmare containers). Ascended effects: tide wave, root grasp, the crush.
func play_sheet(texture: Texture2D, frames: int, anchor: Vector2, at: Vector2, flip: bool = false,
		fps: float = 12.0) -> void:
	var world := Reactions._world(self)
	if world == null and get_parent() != null:
		world = get_parent().get_parent()
	if world == null:
		return
	var sheet := Sprite2D.new()
	sheet.texture = texture
	sheet.hframes = frames
	sheet.centered = false
	sheet.offset = -anchor
	sheet.flip_h = flip
	sheet.z_index = 5
	world.add_child(sheet)
	sheet.global_position = at
	var tween := sheet.create_tween()
	tween.tween_property(sheet, "frame", frames - 1, (frames - 1) / fps)
	tween.tween_interval(1.0 / fps)
	tween.tween_callback(sheet.queue_free)

# The Sapling's withered overlay: crossfaded over the idle by how many leaves were lost since the rest.
func _update_withered() -> void:
	var overlay := get_node_or_null("Withered") as Sprite2D
	if tower_data.withered_texture == null:
		if overlay:
			overlay.queue_free()
		return
	if overlay == null:
		overlay = Sprite2D.new()
		overlay.name = "Withered"
		add_child(overlay)
		move_child(overlay, sprite.get_index() + 1)
	overlay.texture = tower_data.withered_texture
	overlay.hframes = tower_data.frame_count
	overlay.offset = tower_data.sprite_offset
	overlay.modulate.a = clampf(WITHER_PER_LEAF * _wither * 4.0, 0.0, 1.0)  # 5 leaves = fully withered
	overlay.visible = overlay.modulate.a > 0.0

# The Sapling ripens when it yields: a glow, a Dew drop and a Dreamlight mote rise.
func _play_ripen() -> void:
	if tower_data.ripen_texture == null or not is_inside_tree():
		return
	var ripen := Sprite2D.new()
	ripen.texture = tower_data.ripen_texture
	ripen.hframes = tower_data.ripen_frames
	ripen.offset = tower_data.sprite_offset
	ripen.z_index = 1
	add_child(ripen)
	var tween := ripen.create_tween()
	tween.tween_property(ripen, "frame", tower_data.ripen_frames - 1, (tower_data.ripen_frames - 1) / 10.0)
	tween.tween_interval(0.1)
	tween.tween_callback(ripen.queue_free)

# The cells this Warden stands on (the Sapling covers 2×2 from `cell`).
func get_cells() -> Array[Vector2]:
	return footprint_cells(cell, tower_data.footprint)

static func footprint_cells(origin: Vector2, size: int) -> Array[Vector2]:
	var cells: Array[Vector2] = []
	for dy in size:
		for dx in size:
			cells.append(origin + Vector2(dx, dy))
	return cells

# Where a Warden of `size` cells per side sits when its top-left cell is `origin`.
static func footprint_centre(origin: Vector2, size: int) -> Vector2:
	return MAP_GRID.calculate_map_position(origin) + MAP_GRID.cell_size * (size - 1) / 2.0


# --- Birds and seeds --------------------------------------------------------------------------------

# Up to `count` different nightmares in range, best first by this Warden's target mode.
func find_targets(count: int) -> Array:
	if count <= 1:
		var one := find_target()
		return [one] if one != null else []
	var mode := target_mode if tower_data.has_target_priority else attack_data.target_mode
	var ranked := get_enemies_in_range()
	ranked.sort_custom(func(a: Node2D, b: Node2D) -> bool: return _target_score(a, mode) > _target_score(b, mode))
	return ranked.slice(0, count)

# Hummingbird Bower / Jewelwing Court: birds fly out and peck; each peck is a full hit.
func _send_hummingbirds() -> void:
	var birds := attack_data.peck_birds
	# Spread: each bird takes a different nightmare (doubling up when there are fewer). Focus
	# (Jewelwing Court's toggle): every bird on the strongest.
	var chosen: Array
	if focus_strongest:
		var all := get_enemies_in_range()
		all.sort_custom(func(a: Node2D, b: Node2D) -> bool: return a.health > b.health)
		chosen = all.slice(0, 1)
	else:
		chosen = find_targets(birds)
	if chosen.is_empty():
		return
	var targets := []
	for i in birds:
		targets.append(chosen[i % chosen.size()])
	var pecks := attack_data.pecks + _rule_stacks(&"sharp_beaks")
	for target in targets:
		var bird := PeckingBird.new(self, target, pecks, attack_data.peck_time)
		add_child(bird)
		bird.global_position = global_position + tower_data.get_attack_origin()
		_out.append(bird)

# One peck from a hummingbird (PeckingBird calls this). Jewelwing's Flurry makes every Nth crit;
# Needle Point pierces the dread shell; Charged Feathers / Pollen Beaks add a status per peck.
func peck(enemy: Node2D) -> void:
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	_pecks_landed += 1
	var crit := ROLL_CRIT
	if attack_data.flurry_every > 0 and _pecks_landed % attack_data.flurry_every == 0:
		crit = CRIT
	if _dream_state and _dream_state.has_rule(&"needle_point"):
		enemy.pierce_coat_once = true
	Reactions._effect(&"peck_spark", enemy.global_position + Vector2(randf_range(-6, 6), -14), self)
	hit(enemy, 1.0, false, crit)
	if not is_instance_valid(enemy) or enemy.is_cleansed or _dream_state == null:
		return
	if _dream_state.has_rule(&"charged_feathers"):
		enemy.apply_status(EnemyStatuses.STATIC, 1, 0.0, get_damage(), 0, "light", self)
	if _dream_state.has_rule(&"pollen_beaks"):
		enemy.apply_status(EnemyStatuses.SPORED, 1, 0.0, get_damage() * SPORE_POTENCY, 0, "spore", self)

# Samara / Autumn Gale: seeds fly out along a straight line and back through everything.
func _throw_seeds() -> void:
	var target := find_target()
	if target == null:
		return
	_throws += 1
	var length := (attack_data.boomerang_length + _rule_stacks(&"longer_flight")) * MAP_GRID.cell_size.x
	var from := global_position + tower_data.get_attack_origin()
	var directions: Array[Vector2] = []
	if attack_data.boomerang_seeds > 1:
		directions = _busiest_lines(from, length, attack_data.boomerang_seeds)
	else:
		directions = [from.direction_to(target.global_position)]
	if _dream_state and _dream_state.has_rule(&"seed_storm") and _throws % 5 == 0:
		# Seed Storm: every 5th throw bursts into 5 seeds in a fan around the first line.
		var centre := directions[0]
		directions = []
		for i in 5:
			directions.append(centre.rotated(deg_to_rad(-40.0 + 20.0 * i)))
	var bonus := _catch_streak
	var world := Reactions._world(self)  # Never the TowerContainer: its children are all Wardens
	_seeds_thrown = directions.size()
	_seeds_home = 0
	_throw_hit = false
	for direction in directions:
		var seed := SeedBoomerang.new(self, from, direction, length, 1.0 + bonus)
		world.add_child(seed)  # Flies over the maze in world space
		_out.append(seed)

# A seed came home. Once every seed of a throw is back, Autumn Gale's catch rhythm counts the throw:
# +10% on the next one if any seed hit something, back to nothing if none did.
func catch_seed(hit_anything: bool) -> void:
	seed_caught.emit(self)
	_throw_hit = _throw_hit or hit_anything
	_seeds_home += 1
	if _seeds_home < _seeds_thrown:
		return
	if attack_data.catch_bonus > 0.0:
		if _throw_hit:
			_catch_streak = minf(_catch_streak + attack_data.catch_bonus, attack_data.catch_bonus_max)
		else:
			_catch_streak = 0.0
	_seeds_home = 0
	_throw_hit = false

# The `count` directions from `from` whose `length`-long lines cross the most nightmares.
func _busiest_lines(from: Vector2, length: float, count: int) -> Array[Vector2]:
	var candidates: Array[Vector2] = []
	for enemy in get_enemies_in_range():
		candidates.append(from.direction_to(enemy.global_position))
	var scored := candidates.map(func(d: Vector2) -> Array:
		var on_line := 0
		for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
			var p: Vector2 = enemy.global_position - from
			var along := p.dot(d)
			if along >= 0.0 and along <= length and absf(p.cross(d)) <= SeedBoomerang.HIT_RADIUS:
				on_line += 1
		return [on_line, d])
	scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var result: Array[Vector2] = []
	for entry in scored:
		var d: Vector2 = entry[1]
		if result.any(func(r: Vector2) -> bool: return r.angle_to(d) < 0.15 and r.angle_to(d) > -0.15):
			continue  # Two seeds down the same line is a waste
		result.append(d)
		if result.size() >= count:
			break
	return result

func _rule_stacks(rule: StringName) -> int:
	if _dream_state == null or not _dream_state.has_method("rule_stacks"):
		return 0
	return mini(_dream_state.rule_stacks(rule), 3)

# Gust: soothes everything in range a little, then copies the statuses of the most-afflicted
# nightmare onto up to `spread_targets` others near it (half stacks, full duration).
func _spread() -> void:
	var in_range := get_enemies_in_range()
	var source: Node2D = null
	for enemy in in_range:
		if source == null or enemy.statuses.total_stacks() > source.statuses.total_stacks():
			source = enemy
	for enemy in in_range:
		hit(enemy, 1.0, true)
	if source == null or not is_instance_valid(source) or source.is_cleansed or source.statuses.total_stacks() == 0:
		return
	var reach := attack_data.spread_radius * MAP_GRID.cell_size.x
	var others := get_tree().get_nodes_in_group(ENEMY_GROUP).filter(func(e: Node2D) -> bool:
		return e != source and e.global_position.distance_to(source.global_position) <= reach)
	others.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.global_position.distance_squared_to(source.global_position) \
			< b.global_position.distance_squared_to(source.global_position))
	var copied: Array = source.statuses.snapshot()
	var points := PackedVector2Array()
	for i in mini(attack_data.spread_targets, others.size()):
		others[i].statuses.gust_time = 0.5  # Storm Front: a Reaction these statuses complete reaches further
		for status in copied:
			others[i].apply_status(status.id, maxi(ceili(status.stacks / 2.0), 1), status.time,
				status.potency, 0, status.line, status.source)
		points.append(source.global_position)
		points.append(others[i].global_position)
	for i in range(0, points.size(), 2):
		add_child(ChainBolt.new(PackedVector2Array([points[i], points[i + 1]]), WIND_COLOR, 3.0))

# Pinwheel: blades hit every nightmare on the 8 tiles around it, harder the more of those tiles are path.
func _spin() -> void:
	var path_tiles := 0
	var route := _route()
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if (dx != 0 or dy != 0) and route.has(cell + Vector2(dx, dy)):
				path_tiles += 1
	var bonus := clampf((path_tiles - attack_data.spin_free_path_tiles) * attack_data.spin_bonus,
		0.0, attack_data.spin_bonus_max)
	for enemy in _enemies_on_adjacent_tiles():
		hit(enemy, 1.0 + bonus, true)

func _enemies_on_adjacent_tiles() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		var at: Vector2 = enemy.get_current_cell()
		if absf(at.x - cell.x) <= 1 and absf(at.y - cell.y) <= 1:
			result.append(enemy)
	return result

# Pond Keeper: its tongue grabs the target, soothes it and makes it Damp, then drags it back to the
# path tile nearest the pond (bosses only go back a couple of tiles).
func _grab(target: Node2D) -> void:
	var from := global_position + tower_data.get_attack_origin()
	add_child(ChainBolt.new(PackedVector2Array([from, target.global_position]), TONGUE_COLOR, 0.0))
	hit(target)
	if not is_instance_valid(target) or target.is_cleansed:
		return
	if target.enemy_data.is_boss:
		target.push_back(attack_data.pull_boss_tiles * MAP_GRID.cell_size.x)
		grab_finished.emit(self, target)
		return
	var behind: PackedVector2Array = target.get_cells_behind()
	var best := -1
	var best_distance := INF
	for i in behind.size():
		var distance := behind[i].distance_squared_to(cell)
		if distance < best_distance:
			best_distance = distance
			best = i
	if best >= 0:
		target.pull_back_to(best)
	grab_finished.emit(self, target)  # The drag is instant: it ends right away

# Rootlight: glowing roots light the path tiles in range; nightmares there are soothed and Marked.
func _light() -> void:
	_lit_cells.clear()
	for at in _route():
		if _is_cell_in_range(at):
			_lit_cells.append(at)
	queue_redraw()
	for enemy in get_enemies_in_range():
		hit(enemy, 1.0, true)

# Sunpetal: a beam on one target that ramps up the longer it holds (faster on Drowsy or Held).
func _update_beam(delta: float) -> void:
	var target := find_target()
	if target != _beam_target:
		_beam_ramp = 1.0
		_beam_tick = 0.0
		_beam_target = target
		if target == null:
			_stop_beam()
			return
		_show_attack_pose()
	if _beam_target == null:
		return
	var fast: bool = _beam_target.statuses.has(EnemyStatuses.DROWSY) or _beam_target.statuses.is_held()
	var rate := attack_data.beam_ramp_per_second * (BEAM_RAMP_FAST if fast else 1.0)
	_beam_ramp = minf(_beam_ramp + rate * delta, attack_data.beam_ramp_max)
	_beam_behind = _find_behind(_beam_target) if attack_data.beam_behind_share > 0.0 else null
	_beam_tick += delta
	while _beam_tick >= BEAM_TICK and is_instance_valid(_beam_target):
		_beam_tick -= BEAM_TICK
		var share := get_attacks_per_second() * BEAM_TICK * _beam_ramp
		hit(_beam_target, share)
		beam_ticked.emit(self, _beam_ramp)
		if is_instance_valid(_beam_behind):
			hit(_beam_behind, share * attack_data.beam_behind_share)
	if not is_instance_valid(_beam_target) or _beam_target.is_cleansed:
		_beam_target = null
	queue_redraw()

func _stop_beam() -> void:
	var was_beaming := _beam_target != null
	_beam_target = null
	_beam_behind = null
	_beam_ramp = 1.0
	if was_beaming and is_node_ready():
		_show_idle()
	queue_redraw()

# The nightmare right behind `target` on the path (Midsummer's beam carries through to it).
func _find_behind(target: Node2D) -> Node2D:
	var best: Node2D = null
	var best_remaining := INF
	var target_remaining: float = target.get_remaining_distance()
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if enemy == target or enemy.global_position.distance_to(target.global_position) > 1.5 * MAP_GRID.cell_size.x:
			continue
		var remaining: float = enemy.get_remaining_distance()
		if remaining > target_remaining and remaining < best_remaining:
			best_remaining = remaining
			best = enemy
	return best

# The White Stag: nightmares in range are slower and take more damage (Wardens in range get crit
# chance, see _refresh_neighbours).
func _update_aura(delta: float) -> void:
	_aura_tick -= delta
	if _aura_tick > 0.0:
		return
	_aura_tick = AURA_TICK
	var inside := get_enemies_in_range()
	if tower_data.slows_in_aura:  # The White Stag (Grandmother Oak's aura is for Wardens only)
		for enemy in inside:
			enemy.statuses.set_in_stag_aura(AURA_TICK * 1.6)
	# Its pulse animation plays every few seconds while nightmares are inside.
	_cooldown = maxf(_cooldown - AURA_TICK, 0.0)
	if not inside.is_empty() and tower_data.attack_texture != null and _cooldown <= 0.0 and _attack_time < 0.0:
		_start_attack()
		_cooldown = AURA_PULSE_EVERY


# --- Drawing and targeting ------------------------------------------------------------------------------

func _draw() -> void:
	if tower_data.texture == null:
		draw_placeholder(self, tower_data.placeholder_color)
	_draw_rank_pips()
	for at in _lit_cells:
		var centre := to_local(MAP_GRID.calculate_map_position(at))
		var half := MAP_GRID.cell_size / 2.0 - Vector2(6, 6)
		draw_rect(Rect2(centre - half, half * 2.0), Color(LIGHT_COLOR, 0.12))
	if is_instance_valid(_beam_target):
		var from := tower_data.get_attack_origin()
		var width := 2.0 + 2.0 * _beam_ramp
		for target in [_beam_target, _beam_behind]:
			if not is_instance_valid(target):
				continue
			var to := to_local(target.global_position)
			draw_line(from, to, Color(attack_data.beam_color, 0.35), width * 2.0)
			draw_line(from, to, Color(1.0, 1.0, 0.9, 0.9), maxf(width * 0.5, 1.5))
			from = to  # Midsummer's beam carries on from the target to the one behind it
	if attack_data != null and attack_data.attack_kind == TowerData.AttackKind.AURA:
		draw_arc(Vector2.ZERO, get_range_pixels(), 0.0, TAU, 64, Color(0.85, 0.9, 1.0, 0.12), 3.0)
	if badges_visible() and not _badge_cards.is_empty():
		# A small card badge at the base per active position card (its rarity's colour): Solitude is on.
		var x := -(_badge_cards.size() - 1) * 7.0
		for row in _badge_cards:
			var rarity: int = row.card.rarity if row.get("card") != null else 0
			var colour: Color = BADGE_COLORS[clampi(rarity, 0, BADGE_COLORS.size() - 1)]
			var at := Vector2(x, MAP_GRID.cell_size.y / 2.0 - 7.0)
			var diamond := PackedVector2Array([at + Vector2(0, -5), at + Vector2(5, 0), at + Vector2(0, 5), at + Vector2(-5, 0)])
			draw_colored_polygon(diamond, colour)
			draw_polyline(diamond + PackedVector2Array([diamond[0]]), Color(0.1, 0.08, 0.05, 0.8), 1.0)
			x += 14.0
	if _dream_state and _dream_state.has_method("is_eldest") and _dream_state.is_eldest(self):
		# The Eldest: a small crown of three golden rings over the slab.
		var top := Vector2(0, -MAP_GRID.cell_size.y * 0.5 - 4.0) + tower_data.sprite_offset
		for i in 3:
			draw_arc(top + Vector2((i - 1) * 7.0, -absf(i - 1) * -2.0), 3.5, 0.0, TAU, 12, Color(1.0, 0.85, 0.4, 0.95), 1.5)

# Small warm pips along the bottom of the tile, one per Nurture rank, with the Focus icon after them.
# Drawn on a child so they sit over the sprite.
func _draw_rank_pips() -> void:
	var pips := get_node_or_null("RankPips") as Node2D
	if rank <= 0:
		if pips:
			pips.queue_redraw()
		return
	if pips == null:
		pips = Node2D.new()
		pips.name = "RankPips"
		pips.z_index = 1
		pips.draw.connect(func() -> void:
			if rank <= 0:
				return
			var step := 7.0 if rank <= 5 else 6.0
			var icon_space := 9.0 if focus != Focus.NONE else 0.0
			var left := -((rank - 1) * step + icon_space) / 2.0
			for i in rank:
				var at := Vector2(left + i * step, 27.0)
				pips.draw_circle(at, 3.2, Color(0.1, 0.08, 0.05, 0.85))
				pips.draw_circle(at, 2.2, PIP_COLOR)
			if focus != Focus.NONE:
				draw_focus_icon(pips, Vector2(left + (rank - 1) * step + icon_space, 27.0), focus))
		add_child(pips)
	pips.queue_redraw()

# A tiny Focus glyph: Power an upward flame, Swift a double chevron, Reach a ring, Deep a drop.
# Shared with the Warden panel.
static func draw_focus_icon(canvas: CanvasItem, at: Vector2, which: Focus, size: float = 1.0) -> void:
	var color: Color = FOCUS_COLORS.get(which, Color.WHITE)
	var dark := Color(0.1, 0.08, 0.05, 0.9)
	canvas.draw_circle(at, 4.6 * size, dark)
	match which:
		Focus.POWER:
			var flame := PackedVector2Array([at + Vector2(0, -3.5) * size, at + Vector2(3, 2.5) * size,
				at + Vector2(-3, 2.5) * size])
			canvas.draw_colored_polygon(flame, color)
		Focus.SWIFT:
			for dx in [-1.5, 1.5]:
				canvas.draw_polyline(PackedVector2Array([at + Vector2(dx - 1.5, -2.5) * size,
					at + Vector2(dx + 1.0, 0) * size, at + Vector2(dx - 1.5, 2.5) * size]), color, 1.2 * size)
		Focus.REACH:
			canvas.draw_arc(at, 2.8 * size, 0.0, TAU, 12, color, 1.3 * size)
			canvas.draw_circle(at, 0.9 * size, color)
		Focus.DEEP:
			canvas.draw_circle(at + Vector2(0, 1) * size, 2.3 * size, color)
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -3.5) * size,
				at + Vector2(2.1, 0.3) * size, at + Vector2(-2.1, 0.3) * size]), color)

# Attack reach in pixels.
func get_range_pixels() -> float:
	return range_to_pixels(get_range_cells())

# The nightmare in range this Warden should attack, or null. Most Wardens pick the one furthest
# along the path; snipers let the player choose, and Wren's Nest hunts the fastest.
func find_target() -> Node2D:
	var mode := target_mode if tower_data.has_target_priority else attack_data.target_mode
	var best: Node2D = null
	var best_score := -INF
	for enemy in get_enemies_in_range():
		var score := _target_score(enemy, mode)
		if score > best_score:
			best_score = score
			best = enemy
	return best

# How much this Warden wants to shoot `enemy` under `mode` (higher = sooner).
static func _target_score(enemy: Node2D, mode: TowerData.TargetMode) -> float:
	match mode:
		TowerData.TargetMode.STRONGEST:
			return enemy.health
		TowerData.TargetMode.BOSSES:
			return -enemy.get_remaining_distance() + (1e9 if enemy.enemy_data.is_boss else 0.0)
		TowerData.TargetMode.FASTEST:
			return enemy.get_move_speed()
	return -enemy.get_remaining_distance()

# Blighted enemies within attack range (and outside a sniper's minimum range).
func get_enemies_in_range() -> Array[Node2D]:
	var range_squared := get_range_pixels() ** 2
	var min_squared := (attack_data.min_range * MAP_GRID.cell_size.x) ** 2
	var result: Array[Node2D] = []
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		var distance_squared := global_position.distance_squared_to(enemy.global_position)
		if distance_squared <= range_squared and distance_squared >= min_squared:
			result.append(enemy)
	return result

# Converts a range in cells to pixels. Shared with the build-mode ghost preview.
static func range_to_pixels(range_cells: float) -> float:
	return range_cells * MAP_GRID.cell_size.x

# Draws a simple stone block centred on the origin. Shared with the build-mode ghost preview.
static func draw_placeholder(canvas: CanvasItem, color: Color) -> void:
	var block := Rect2(-24, -24, 48, 48)
	canvas.draw_rect(block, color.darkened(0.45))
	canvas.draw_rect(block.grow(-4), color)
	canvas.draw_circle(Vector2.ZERO, 10, color.lightened(0.35))
