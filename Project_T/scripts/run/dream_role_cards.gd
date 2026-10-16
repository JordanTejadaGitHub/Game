extends RefCounted
# Card pass slice 4, part A (owner 2026-10-16; council card_pass_draft.md 4a / 4c, card_pass_td.md 3a, card_pass_player.md
# 2 and 4): the branch-role payoff cards, the two Nurture-choice cards and Towering. DreamState holds one (`role_cards`);
# Tower, Enemy, Reactions and FairyRing call in behind one cached flag each, so a run without these cards pays almost
# nothing. Rules by card id (rule_id = id). Every number is a starting value for Balancing and lives here.
#
# Shared rules (TD 3a): every stack these cards add is a NON-native application (Enemy.apply_status directly, or
# EnemyStatuses.add_quiet), so it never reaches DreamState.class_status and never wakes a Calling rule; a Warden's own
# extra stacks (Mother's Hand, One Bough, Deep Grain) ride its own application but are left out of what the Calling hears.
# Conditional damage bonuses here multiply (the "synergy" bucket: Tower.hit applies them outside plain_hit_factor).
# Every effect credits its card with DreamState.note_card (throttled) and shows a moment (a burst, a thread, a flash).

const DREAM_BURST := preload("res://scripts/fx/dream_burst.gd")
const DREAM_TRANSFER := preload("res://scripts/fx/dream_transfer.gd")
const CELL := 64.0

# --- Rule ids (= card ids) -----------------------------------------------------------------------------------------
const MILLSTONE := &"millstone"  # The draft's "Crushing Weight", renamed: it clashed with the stone Signature "Crushing"
const HEAVY_HEART := &"heavy_heart"
const SHARED_FEVER := &"shared_fever"
const TANGLED_LIGHTNING := &"tangled_lightning"
const MOTHERS_HAND := &"mothers_hand"
const HOMESICK := &"homesick"
const BOUND_AND_BURNING := &"bound_and_burning"
const CALLED_FROM_AFAR := &"called_from_afar"
const KINDLED_GAZE := &"kindled_gaze"
const SNARE_LINE := &"snare_line"
const ONE_BOUGH := &"one_bough"
const DEEP_GRAIN := &"deep_grain"
const OLD_HAND := &"old_hand"
const TOWERING := &"towering"
const RULES: Array[StringName] = [MILLSTONE, HEAVY_HEART, SHARED_FEVER, TANGLED_LIGHTNING, MOTHERS_HAND, HOMESICK,
	BOUND_AND_BURNING, CALLED_FROM_AFAR, KINDLED_GAZE, SNARE_LINE, ONE_BOUGH, DEEP_GRAIN, OLD_HAND, TOWERING]

# --- Numbers (starting values for Balancing) -------------------------------------------------------------------------
const MILLSTONE_FULL_BONUS := 0.60  # A heavy Warden's hit on a nightmare with a full status: +60% (synergy)…
const MILLSTONE_SPLASH := 0.40  # …and this share of it lands on nightmares within…
const MILLSTONE_RADIUS := 1.0  # …this many cells (area damage, tag "millstone": on-hit rules skip it)
const HEAVY_HEART_COPIES := 2  # Heavy Heart: the Reaction also goes off on this many nightmares…
const HEAVY_HEART_REACH := 3.0  # …the nearest within this many cells that carry one of its statuses
const SHARED_FEVER_MIN := 3  # Shared Fever: an area hit on at least this many nightmares…
const SHARED_FEVER_STATUSES := 2  # …shares up to this many of the worst-hit one's statuses…
const SHARED_FEVER_STACKS := 1  # …this many stacks each…
const SHARED_FEVER_WAIT := 2.0  # …once every this many seconds per Warden (never Drowsy or Rooted)
const TANGLED_EXTRA_JUMPS := 2  # Tangled Lightning: chain attacks jump this many more times (statused nightmares only)…
const TANGLED_STACK := 1  # …and each of those jumps adds this many stacks of a status it already has
const MOTHERS_HAND_STACK := 1  # Mother's Hand: a Warden touching a support Warden adds this many more stacks…
const MOTHERS_HAND_REACTION := 0.25  # …and the Reactions it sets off deal this much more (synergy)
const HOMESICK_WINDOW := 3.0  # Homesick: seconds after a pull in which the next Reaction on it…
const HOMESICK_REACTION := 2.0  # …deals this many times as much
const BOUND_EXTRA_STACKS := 2  # Bound and Burning: every status added to a Rooted nightmare lands this many more stacks
const AFAR_MIN_CELLS := 4.0  # Called from Afar: a hit from at least this many cells away…
const AFAR_WAIT := 3.0  # …gives its target a skip of its next Reaction wait, once every this many seconds per nightmare
const KINDLED_RAMP := 2.0  # Kindled Gaze: beams ramp this many times as fast…
const KINDLED_MIN_STATUSES := 2  # …on a nightmare carrying at least this many statuses
const SNARE_STACKS := 3  # Snare Line: a trap going off gives nightmares within…
const SNARE_RADIUS := 1.0  # …this many cells this many stacks of each of the stepper's statuses (never Rooted)
const ONE_BOUGH_COUNT := 3  # One Bough: at least this many grown Wardens of one family, all the same branch…
const ONE_BOUGH_SPEED := 0.20  # …attack this much faster (inside the Dream speed cap)…
const ONE_BOUGH_STACK := 1  # …and add this many more stacks with each status
const DEEP_GRAIN_STACK := 1  # Deep Grain: each Deep rank choice adds this many more stacks…
const DEEP_GRAIN_MAX := 3  # …counting at most this many Deep ranks
const OLD_HAND_RANK := 3  # Old Hand: from this rank, every OLD_HAND_III-th hit on a nightmare with a full status crits…
const OLD_HAND_III := 6
const OLD_HAND_FAST_RANK := 5  # …and from this rank every OLD_HAND_V-th (counted per attack, never per target)
const OLD_HAND_V := 4
const TOWERING_COUNT := 3  # Towering: the Wardens with the highest ranks (ties: the higher form, then the older)…
const TOWERING_BONUS := 0.50  # …deal this much more (synergy)…
const TOWERING_REACH := 3.0  # …and a dispel's leftover lands on the nearest nightmare within this many cells (at most that hit)
const TOWERING_MIN_TIER := 3  # Its Need: a final form (tier 3+)…
const TOWERING_MIN_RANK := 4  # …at rank IV or higher, on the map
const TOWERING_REFRESH := 0.5  # Seconds between looks at who the highest-ranked Wardens are
const CREDIT_EVERY := 0.5  # note_card at most this often per card (the times in between are added up)

var dreams  # The DreamState that owns this (set in _init)

func _init(state = null) -> void:
	dreams = state

# --- Which cards are owned (cached like Tower._rule_entry: rules_stamp, stacks and pool sizes) -----------------------
var _on := {}
var _stamp := [-1, -1, -1]
var _hit_live := false
var _fire_live := false
var _reaction_live := false
var _stack_live := false

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
	_hit_live = _on.has(MILLSTONE) or _on.has(TOWERING) or _on.has(CALLED_FROM_AFAR) or _on.has(OLD_HAND) or _on.has(HEAVY_HEART)
	_fire_live = _on.has(HEAVY_HEART) or _on.has(HOMESICK)
	_reaction_live = _on.has(MOTHERS_HAND) or _on.has(HOMESICK)
	_stack_live = _on.has(MOTHERS_HAND) or _on.has(ONE_BOUGH) or _on.has(DEEP_GRAIN)

func on(rule: StringName) -> bool:
	_refresh()
	return _on.has(rule)

func hit_live() -> bool:
	_refresh()
	return _hit_live

func fire_live() -> bool:
	_refresh()
	return _fire_live

func reaction_live() -> bool:
	_refresh()
	return _reaction_live

func stack_live() -> bool:
	_refresh()
	return _stack_live

# --- Offer Needs that aren't data fields (DreamState._meets_needs / needs_note) -------------------------------------
func has_need(rule: StringName) -> bool:
	return rule == ONE_BOUGH or rule == DEEP_GRAIN or rule == TOWERING

func needs_met(rule: StringName) -> bool:
	if dreams == null or dreams.unlock_everything:
		return true
	match rule:
		ONE_BOUGH:
			return not _one_bough_set(true).is_empty()
		DEEP_GRAIN:
			for tower in _towers():
				if tower.choice_count(Tower.Focus.DEEP) > 0:
					return true
			return false
		TOWERING:
			for tower in _towers():
				if tower.tower_data.tier >= TOWERING_MIN_TIER and tower.rank >= TOWERING_MIN_RANK:
					return true
			return false
	return true

func need_text(rule: StringName) -> String:
	match rule:
		ONE_BOUGH:
			return "%d grown Wardens of one family, all the same branch" % ONE_BOUGH_COUNT
		DEEP_GRAIN:
			return "a Warden with a Deep rank"
		TOWERING:
			return "a final form at rank %s or higher" % Tower.rank_name(TOWERING_MIN_RANK)
	return ""

# --- Tower.hit ---------------------------------------------------------------------------------------------------------
var _hit_tower = null  # Heavy Heart: the Warden whose hit is landing (begin_hit / end_hit), and its target
var _hit_target = null

# Old Hand: whether this hit is the beat's crit (before the crit roll is used). One count per attack (a pulse on 20
# nightmares counts once), only for hits on a nightmare with a full status; beams (ticks, no attacks) never count.
var _old_hand := {}  # Warden instance id -> [the attack counted last, hits counted]

func old_hand(tower, enemy) -> bool:
	if not _on.has(OLD_HAND) or tower.rank < OLD_HAND_RANK or tower.attack_data.attack_kind == TowerData.AttackKind.BEAM:
		return false
	if full_status(enemy.statuses) == &"":
		return false
	var key: int = tower.get_instance_id()
	var entry: Array = _old_hand.get(key, [-1, 0])
	if int(entry[0]) == tower._attack_count:
		return false
	entry[0] = tower._attack_count
	entry[1] = int(entry[1]) + 1
	_old_hand[key] = entry
	var every := OLD_HAND_V if tower.rank >= OLD_HAND_FAST_RANK else OLD_HAND_III
	if int(entry[1]) % every != 0:
		return false
	_credit(OLD_HAND, enemy.global_position)
	return true

# The synergy part of a hit: [multiplier, Millstone's splash due, Towering's carry due].
func hit_multiplier(tower, enemy, effect_tick: bool) -> Array:
	var m := 1.0
	var millstone := false
	if _on.has(MILLSTONE) and not effect_tick and WardenRoles.has_role(tower.attack_data, WardenRoles.HEAVY):
		var full := full_status(enemy.statuses)
		if full != &"":
			m *= 1.0 + MILLSTONE_FULL_BONUS
			millstone = true
			enemy.flash_status(full)  # The full status flashes as the weight lands
	var towering := _on.has(TOWERING) and _towering_set().has(tower.get_instance_id())
	if towering:
		m *= 1.0 + TOWERING_BONUS
	return [m, millstone, towering]

func begin_hit(tower, enemy) -> Array:
	var previous := [_hit_tower, _hit_target]
	_hit_tower = tower
	_hit_target = enemy
	return previous

func end_hit(previous: Array) -> void:
	_hit_tower = previous[0]
	_hit_target = previous[1]

# After the hit's damage: Millstone's splash, Towering's carry, Called from Afar's token.
func after_hit(tower, enemy, dealt: float, health_before: int, line: String, effect_tick: bool, role_hit: Array) -> void:
	if not is_instance_valid(enemy) or not tower.is_inside_tree():
		return
	var at: Vector2 = enemy.global_position
	if bool(role_hit[1]) and dealt > 0.0:
		var reach := MILLSTONE_RADIUS * CELL
		for other in Tower.nightmares_near(tower.get_tree(), at, reach):
			if other != enemy and is_instance_valid(other) and not other.is_cleansed and other.global_position.distance_to(at) <= reach:
				other.take_damage(dealt * MILLSTONE_SPLASH, line, true, false, tower, MILLSTONE)
		DREAM_BURST.play(MILLSTONE, at, reach, Reactions._world(tower))  # A dust ring
		_credit(MILLSTONE, at)
	if bool(role_hit[2]) and enemy.is_cleansed and dealt > 0.0:
		var leftover := clampf(dealt - float(health_before), 0.0, dealt)  # Never more than the hit itself
		var next := _nearest(tower, enemy, at, TOWERING_REACH)
		if leftover > 0.0 and next != null:
			var world := Reactions._world(tower)
			if world != null:
				Fx.segment(&"thunderclap_arc", at, next.global_position, world, 0.25)  # The leftover jumps
			next.take_damage(leftover, line, false, false, tower, TOWERING)
			_credit(TOWERING, at)
	if _on.has(CALLED_FROM_AFAR) and not effect_tick and not enemy.is_cleansed:
		var s: EnemyStatuses = enemy.statuses
		if not s.skip_reaction_wait and not s.is_on_cooldown(CALLED_FROM_AFAR) \
				and tower.global_position.distance_to(at) >= AFAR_MIN_CELLS * CELL:
			s.skip_reaction_wait = true
			s.start_cooldown(CALLED_FROM_AFAR, AFAR_WAIT)
			DREAM_BURST.play(CALLED_FROM_AFAR, at, 14.0, Reactions._world(tower))  # A star glint on the target

# Called from Afar: Reactions._fire spent the token (a Reaction went off without waiting).
func afar_spent(enemy) -> void:
	if is_instance_valid(enemy):
		_credit(CALLED_FROM_AFAR, enemy.global_position)

# --- Reactions ---------------------------------------------------------------------------------------------------------
var _copying := false
var _homesick := {}  # Nightmare instance id -> the clock its window ends
var _homesick_now := {}  # Nightmare instance id -> the frame its doubled Reaction fired

# Reactions._fire: Reaction `id` (cooldown key `key`) went off on `enemy`.
func reaction_fired(enemy, id: StringName, key: StringName, towers: Array) -> void:
	_refresh()
	var eid: int = enemy.get_instance_id()
	if _on.has(HOMESICK) and _homesick.has(eid):
		if float(_homesick[eid]) >= _clock():
			_homesick_now[eid] = Engine.get_process_frames()
			if _homesick_now.size() > 256:
				_homesick_now.clear()
				_homesick_now[eid] = Engine.get_process_frames()
			var world := Reactions._world(enemy)
			if world != null:
				Fx.callout("Homesick", Palette.GOLD, enemy.global_position, world, HOMESICK)
			_credit(HOMESICK, enemy.global_position)
		_homesick.erase(eid)
	if _on.has(HEAVY_HEART) and not _copying and enemy == _hit_target and is_instance_valid(_hit_tower) \
			and WardenRoles.has_role(_hit_tower.attack_data, WardenRoles.HEAVY):
		_heavy_heart(enemy, id, key, towers)

# The Reaction cards' part of Reaction damage (DreamState.get_reaction_card_multiplier).
func reaction_multiplier(enemy, _id: StringName, tower) -> float:
	var m := 1.0
	if _on.has(HOMESICK) and enemy != null and is_instance_valid(enemy) \
			and int(_homesick_now.get(enemy.get_instance_id(), -1)) == Engine.get_process_frames():
		m *= HOMESICK_REACTION
	if _on.has(MOTHERS_HAND) and tower != null and is_instance_valid(tower) and tower is Tower and _touches_support(tower):
		m *= 1.0 + MOTHERS_HAND_REACTION
	return m

# Heavy Heart: the same Reaction on the nearest nightmares that carry one of its statuses; each waits its own cooldown
# (Reactions._fire) and uses up what the Reaction uses up; a copy never copies (TD 3a).
const SPENDS := {&"thunderclap": EnemyStatuses.STATIC, &"ignite": EnemyStatuses.STATIC, &"lightning_rod": EnemyStatuses.STATIC,
	&"mushrooming": EnemyStatuses.DAMP, &"drown": EnemyStatuses.DROWSY, &"pinned": EnemyStatuses.MARKED, &"shatter": EnemyStatuses.HELD}

func _heavy_heart(enemy, id: StringName, key: StringName, towers: Array) -> void:
	var data: ReactionData = Reactions.get_data(id)
	if data == null:
		data = Reactions.get_data(key)
	if data == null:
		return
	var needs: Array[StringName] = []
	needs.append_array(data.statuses)
	needs.append_array(data.alternatives)
	var at: Vector2 = enemy.global_position
	var picks: Array = []
	for other in Reactions._others_within(enemy, HEAVY_HEART_REACH):
		for status in needs:
			if other.statuses.has(status) or (status == EnemyStatuses.HELD and other.statuses.is_held()):
				picks.append(other)
				break
	picks.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
	var tower = _hit_tower
	var base: StringName = Reactions.CROWNED_BASE.get(id, id)
	_copying = true
	for other in picks.slice(0, HEAVY_HEART_COPIES):
		if not is_instance_valid(other) or other.is_cleansed:
			continue
		if Reactions._fire(other, id, towers, false, 1, key) <= 0:
			continue  # Its own Reaction wait
		_copy_effect(other, id, base, tower)
		if is_instance_valid(other) and not other.is_cleansed and SPENDS.has(base):
			other.statuses.remove(SPENDS[base])
		_credit(HEAVY_HEART, other.global_position)
	_copying = false

func _copy_effect(other, id: StringName, base: StringName, tower) -> void:
	var s: EnemyStatuses = other.statuses
	match base:
		&"drown":
			Reactions.pull_under(other, tower, Reactions.PULL_UNDER_TIME[0])
		&"pinned":
			s.pinned = true
		&"mushrooming":
			s.mushroom_time = maxf(s.mushroom_time, Reactions.MUSHROOM_TIME)
		&"smother":
			pass  # Smother is its Held + Poisoned ticking faster: the copy is the event itself
		_:
			var strength: float = float(Reactions.ECHO_DAMAGE.get(base, 2.0)) * (tower.get_damage() if is_instance_valid(tower) else 0.0)
			if strength > 0.0:
				other.take_damage(Reactions._rx(other, strength, id, tower), tower.tower_data.line, true, false, tower, &"echo")

# --- Pulls (Homesick) --------------------------------------------------------------------------------------------------
# A Warden whose job is pulling pulled `enemy` back (Tower's ability pull and the Pond Keeper's grab; never Tangled Release).
func pulled_back(tower, enemy) -> void:
	if not on(HOMESICK) or not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	var s: EnemyStatuses = enemy.statuses
	for id in s.active_ids():
		s.top_up(id)  # Back to full time (within the linger cap)
		enemy.flash_status(id)
	_homesick[enemy.get_instance_id()] = _clock() + HOMESICK_WINDOW
	if _homesick.size() > 512:
		_prune_homesick()

func _prune_homesick() -> void:
	var now := _clock()
	for key in _homesick.keys():
		if float(_homesick[key]) < now:
			_homesick.erase(key)

# --- Status stacks -----------------------------------------------------------------------------------------------------
# Extra stacks on a Warden's own (native) application of `status`: Mother's Hand, One Bough, Deep Grain. Never Rooted
# and never on walls (their Drowsy can't put a nightmare to sleep alone). Tower._apply_one_status adds them to the
# application only; the Calling hooks hear the Warden's own count.
func extra_stacks(tower, status: StringName) -> int:
	if status == EnemyStatuses.HELD or tower.tower_data.line == "wall":
		return 0
	var extra := 0
	if _on.has(MOTHERS_HAND) and _touches_support(tower):
		extra += MOTHERS_HAND_STACK
		_credit(MOTHERS_HAND, tower.global_position)
	if _on.has(ONE_BOUGH) and _one_bough_set(false).has(tower.get_instance_id()):
		extra += ONE_BOUGH_STACK
		_credit(ONE_BOUGH, tower.global_position)
	if _on.has(DEEP_GRAIN):
		var deep: int = mini(tower.choice_count(Tower.Focus.DEEP), DEEP_GRAIN_MAX)
		if deep > 0:
			extra += deep * DEEP_GRAIN_STACK
			_credit(DEEP_GRAIN, tower.global_position)
	return extra

# Bound and Burning (Enemy.apply_status, any application): extra stacks while the nightmare is Rooted; also switches on
# the timer pause (EnemyStatuses.bound_pause). Never Drowsy or Rooted itself.
func bound_stacks(enemy, id: StringName) -> int:
	if not on(BOUND_AND_BURNING):
		return 0
	var s: EnemyStatuses = enemy.statuses
	s.bound_pause = true
	if id == EnemyStatuses.DROWSY or id == EnemyStatuses.HELD or not s.is_held():
		return 0
	_credit(BOUND_AND_BURNING, enemy.global_position)
	return BOUND_EXTRA_STACKS

# One Bough's speed (Tower.get_attacks_per_second, inside the Dream speed cap).
func speed_bonus(tower) -> float:
	if not on(ONE_BOUGH):
		return 0.0
	return ONE_BOUGH_SPEED if _one_bough_set(false).has(tower.get_instance_id()) else 0.0

# --- Area, chain, beam and trap hooks ---------------------------------------------------------------------------------
var _fever_next := {}  # Warden instance id -> the clock it may share again

# Shared Fever: an area hit on SHARED_FEVER_MIN+ nightmares (`hit`) gives them the worst-hit one's statuses.
func area_attack(tower, hit: Array) -> void:
	if not on(SHARED_FEVER) or hit.size() < SHARED_FEVER_MIN:
		return
	var key: int = tower.get_instance_id()
	var now := _clock()
	if now < float(_fever_next.get(key, -1.0)):
		return
	var worst = null
	var most := 0
	for enemy in hit:
		if is_instance_valid(enemy) and not enemy.is_cleansed and enemy.statuses.total_stacks() > most:
			most = enemy.statuses.total_stacks()
			worst = enemy
	if worst == null:
		return
	var ws: EnemyStatuses = worst.statuses
	var ids: Array = []
	for id in ws.active_ids():
		if id in EnemyStatuses.ALL and id != EnemyStatuses.DROWSY and id != EnemyStatuses.HELD:
			ids.append(id)
	if ids.is_empty():
		return
	ids.sort_custom(func(a, b) -> bool: return ws.stacks(a) > ws.stacks(b))
	ids = ids.slice(0, SHARED_FEVER_STATUSES)
	_fever_next[key] = now + SHARED_FEVER_WAIT
	if _fever_next.size() > 256:
		_fever_next.clear()
		_fever_next[key] = now + SHARED_FEVER_WAIT
	var world := Reactions._world(tower)
	var from: Vector2 = worst.global_position
	for other in hit:
		if other == worst or not is_instance_valid(other) or other.is_cleansed:
			continue
		for id in ids:
			_give(other, ws, id, SHARED_FEVER_STACKS)
		DREAM_TRANSFER.play(world, from, other.global_position, ids[0])  # A thread from the worst-hit one
	_credit(SHARED_FEVER, from)

# Tangled Lightning: up to TANGLED_EXTRA_JUMPS more jumps, onto nightmares carrying a status. Appends them to `hits`;
# returns how many it added (Tower._chain_strike calls tangled_hit on each).
func tangle(tower, hits: Array[Node2D]) -> int:
	if not on(TANGLED_LIGHTNING) or hits.is_empty():
		return 0
	var added := 0
	for n in TANGLED_EXTRA_JUMPS:
		var best: Node2D = null
		var best_distance := INF
		for enemy in tower.get_tree().get_nodes_in_group(Tower.ENEMY_GROUP):
			if hits.has(enemy) or enemy.is_cleansed or enemy.statuses.count() == 0:
				continue
			for from in hits:
				var reach: float = tower.attack_data.chain_jump_range + tower.area_bonus()
				if from.statuses.has(EnemyStatuses.DAMP) and enemy.statuses.has(EnemyStatuses.DAMP):
					reach += Tower.CHAIN_DAMP_EXTRA_RANGE
				var distance: float = from.global_position.distance_to(enemy.global_position)
				if distance <= reach * CELL and distance < best_distance:
					best_distance = distance
					best = enemy
		if best == null:
			break
		hits.append(best)
		added += 1
	return added

# One of Tangled Lightning's jumps landed: 1 stack of a status it already has (a quiet add: never starts one, never
# Rooted; then the Reaction check, so it can complete one).
func tangled_hit(tower, enemy) -> void:
	if not is_instance_valid(enemy) or enemy.is_cleansed:
		return
	var s: EnemyStatuses = enemy.statuses
	var ids: Array = []
	for id in s.active_ids():
		if id in EnemyStatuses.ALL and id != EnemyStatuses.HELD:
			ids.append(id)
	if ids.is_empty():
		return
	var id: StringName = ids[randi() % ids.size()]
	if s.add_quiet(id, TANGLED_STACK) > 0:
		enemy.flash_status(id)  # The arc takes the status's colour
		Reactions.on_status(enemy, id, tower)
		_credit(TANGLED_LIGHTNING, enemy.global_position)

# Kindled Gaze: the beam's ramp multiplier on `enemy`.
func kindled(enemy) -> float:
	if not on(KINDLED_GAZE) or not is_instance_valid(enemy) or enemy.statuses.count() < KINDLED_MIN_STATUSES:
		return 1.0
	return KINDLED_RAMP

func note_kindled(at: Vector2) -> void:
	_credit(KINDLED_GAZE, at)

# Snare Line: a trap set off by `stepper` gives the nightmares within SNARE_RADIUS its statuses (before the burst hits).
func snare_line(tower, stepper) -> void:
	if not on(SNARE_LINE) or not is_instance_valid(stepper) or stepper.is_cleansed:
		return
	var s: EnemyStatuses = stepper.statuses
	var ids: Array = []
	for id in s.active_ids():
		if id in EnemyStatuses.ALL and id != EnemyStatuses.HELD:
			ids.append(id)
	if ids.is_empty():
		return
	var at: Vector2 = stepper.global_position
	var reach := SNARE_RADIUS * CELL
	var world := Reactions._world(tower)
	var any := false
	for other in Tower.nightmares_near(tower.get_tree(), at, reach):
		if other == stepper or not is_instance_valid(other) or other.is_cleansed or other.global_position.distance_to(at) > reach:
			continue
		for id in ids:
			_give(other, s, id, SNARE_STACKS)
		DREAM_TRANSFER.play(world, at, other.global_position, ids[0])
		any = true
	if any:
		DREAM_BURST.play(SNARE_LINE, at, reach, world)  # A ring of motes
		_credit(SNARE_LINE, at)

# A non-native application of `from`'s status `id` (its strength, family and source) on `other`.
func _give(other, from: EnemyStatuses, id: StringName, stacks: int) -> void:
	if not is_instance_valid(other) or other.is_cleansed:
		return
	var source: Node = from.source(id)
	var line: String = from.spore_line() if id == EnemyStatuses.SPORED else (source.tower_data.line if source is Tower else "")
	other.apply_status(id, stacks, 0.0, from.potency(id), 0, line, source)

# --- Caches --------------------------------------------------------------------------------------------------------------
var _support_board := -1
var _support := {}  # Warden instance id -> touches a support Warden (per board_version)

func _touches_support(tower) -> bool:
	if dreams.board_version != _support_board:
		_support_board = dreams.board_version
		_support.clear()
	var key: int = tower.get_instance_id()
	if not _support.has(key):
		var touching := false
		if is_instance_valid(dreams.tower_container):
			for other in dreams._touching(tower):
				if WardenRoles.has_role(other.attack_data, WardenRoles.SUPPORT):
					touching = true
					break
		_support[key] = touching
	return _support[key]

var _bough_board := -1
var _bough := {}  # Warden instance id -> true: One Bough's Wardens (per board_version)

func _one_bough_set(fresh: bool) -> Dictionary:
	if dreams.board_version == _bough_board and not fresh:
		return _bough
	_bough_board = dreams.board_version
	var before := _bough
	_bough = {}
	var by_line := {}
	for tower in _towers():
		var line: String = tower.tower_data.line
		if tower.tower_data.tier < 2 or line == "" or line == "wall":
			continue
		if not by_line.has(line):
			by_line[line] = []
		by_line[line].append(tower)
	for line in by_line:
		var list: Array = by_line[line]
		if list.size() < ONE_BOUGH_COUNT:
			continue
		var branch := Kinships.branch_for(list[0])
		if branch == "":
			continue
		var same := true
		for tower in list:
			if Kinships.branch_for(tower) != branch:
				same = false
				break
		if same:
			for tower in list:
				_bough[tower.get_instance_id()] = true
	if on(ONE_BOUGH):
		for tower in _towers():
			if _bough.has(tower.get_instance_id()) and not before.has(tower.get_instance_id()):
				DREAM_BURST.play(ONE_BOUGH, tower.global_position, 20.0, Reactions._world(tower))  # Matching leaves at its feet
	return _bough

var _towering := {}  # Warden instance id -> true: Towering's highest-ranked Wardens
var _towering_next := -1.0
var _towering_board := -1

func _towering_set() -> Dictionary:
	var now := _clock()
	if now < _towering_next and dreams.board_version == _towering_board:
		return _towering
	_towering_next = now + TOWERING_REFRESH
	_towering_board = dreams.board_version
	var ranked: Array = []
	for tower in _towers():
		if tower.tower_data.can_attack and tower.rank > 0:
			ranked.append(tower)
	ranked.sort_custom(_towering_order)
	var chosen := {}
	for tower in ranked.slice(0, TOWERING_COUNT):
		chosen[tower.get_instance_id()] = true
		if not _towering.has(tower.get_instance_id()):
			DREAM_BURST.play(TOWERING, tower.global_position, 24.0, Reactions._world(tower))  # Its crown of light
	_towering = chosen
	return _towering

static func _towering_order(a, b) -> bool:
	if a.rank != b.rank:
		return a.rank > b.rank
	if a.tower_data.tier != b.tower_data.tier:
		return a.tower_data.tier > b.tower_data.tier
	return a.get_instance_id() < b.get_instance_id()

# --- Helpers ---------------------------------------------------------------------------------------------------------------
# The first status at its most on these statuses (&"" if none). Charged at its most is a bolt, so it never counts.
static func full_status(s: EnemyStatuses) -> StringName:
	for id in s.active_ids():
		if id in EnemyStatuses.ALL and s.stacks(id) >= s.get_max_stacks(id):
			return id
	return &""

func _nearest(tower, skip, at: Vector2, cells: float) -> Node2D:
	var best: Node2D = null
	var best_distance := cells * CELL
	for other in Tower.nightmares_near(tower.get_tree(), at, cells * CELL):
		if other == skip or not is_instance_valid(other) or other.is_cleansed:
			continue
		var distance: float = other.global_position.distance_to(at)
		if distance <= best_distance:
			best_distance = distance
			best = other
	return best

func _towers() -> Array:
	if dreams == null or not is_instance_valid(dreams.tower_container):
		return []
	return dreams._towers()

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
