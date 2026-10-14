extends "res://scripts/combat/class_kit.gd"
# The Sporeling class (dream_council_review.md 20 "Sporeling: spores pile on fast", rulings in 21).
# Calling, Spore Print: a Poisoned nightmare dispelled by any Warden leaves a mushroom on the path; the next walking
# nightmare to step on it takes a dose (3 Poisoned at once). Mushrooms are objects on route points: one per step, no
# timer, they survive rests (saved with the run), 40 on the map at most. The 12 class cards grow mushrooms and hand
# out doses; the 3 lent cards (Mycelium, Hothouse, Overnight) need no mushroom and work for any Sporeling owner.
# Every number is a paper starting value.

const GROUP := &"spore_print"
const FAMILY := "sporeling"
const LINE := "spore"

const DOSE := 3  # Poisoned a dose adds
const MUSHROOM_MAX := 40  # On the map; over that the oldest goes, mushrooms no card regrows first
const FALL_CELLS := 1.0  # A nightmare that falls further than this from the route leaves no mushroom
const STEP_CELLS := 0.3  # A walker's centre this close to a mushroom's point has stepped on it
const BED_EVERY := 5.0  # Mushroom Bed: a step touching 2 spore Wardens grows one this long after it is emptied
const BED_WARDENS := 2
const KEPT_EVERY := 6.0  # Kept Ground: a mushroom touching only one spore Warden grows back
const SIDE_EVERY := 3.0  # Side by Side: a step touching a spore Warden and another family's Warden
const TWIN_CAPS := 2  # Twin Caps: doses per mushroom…
const TWIN_SLOWER := 2.0  # …and every regrow this much slower
const OPEN_SEASON_EVERY := 2.0  # Open Season: once per Warden and nightmare
const OPEN_SEASON_WINDOW := 4.0  # …and the dose waits this long for that Warden's next attack
const HAZE_MUSHROOMS := 4  # Spore Haze: mushrooms near a single-target spore Warden
const HAZE_OTHERS := 4
const KICKED_OTHERS := 4  # Kicked Up
const GROWS_MAX := 6  # It Grows on You: a dose is at most this big
const HELPING_STACKS := 3  # Second Helping: the partner's next status application adds this many
const EVERYTHING_STACKS := 3  # Everything Grows
const HOTHOUSE_AT := 6  # Hothouse: at this much Poisoned (Brimming does not change it)…
const HOTHOUSE_ADD := 5  # …each other status gains this many, quietly, once per nightmare
const OVERNIGHT_STACKS := 3  # Overnight: a spore Warden's attack adds this many to a nightmare carrying another family's status
const OVERNIGHT_EVERY := 1.0
const SINGLE_TARGET := ["sporeling", "driftspore", "inkcap", "lichenling", "old_lichen", "deliquescent"]  # Spore Haze

# Card rule ids
const MUSHROOM_BED := &"mushroom_bed"
const OPEN_SEASON := &"open_season"
const SPORE_HAZE := &"spore_haze"
const KEPT_GROUND := &"kept_ground"
const KICKED_UP := &"kicked_up"
const IT_GROWS := &"it_grows_on_you"
const PASS_IT_ROUND := &"pass_it_round"
const SECOND_HELPING := &"second_helping"
const EVERYTHING_GROWS := &"everything_grows"
const TWIN := &"twin_caps"
const SIDE_BY_SIDE := &"side_by_side"
const LEAF_LITTER := &"leaf_litter"
const HOTHOUSE := &"hothouse"  # Lent
const OVERNIGHT := &"overnight"  # Lent
# Stack cards (lent, 2026-10-13; sporeling_stack_cards.md with the council's fixes, new_lent_td.md)
const NARROWS := &"narrows"
const NARROWS_EXTRA := 2  # Narrows: a status hit adds this many more (3 at once for a 1-stack hit)…
const NARROWS_SMALL := 1  # …only this many on Charged and Exposed (more made bolts 3x as often / Exposed near-permanent)
const SEEPING_IN := &"seeping_in"
const SEEP_STEPS := 6.0  # Seeping In: every this many steps walked in a spore Warden's range…
const SEEP_STACKS := 3  # …each status it carries gains this many (quietly: never starts one)
const MIXED_COMPANY := &"mixed_company"
const MIXED_OTHERS := 2  # Mixed Company: Poisoned and this many other statuses, from any Warden
const STACK_EVERY := 1.0  # Narrows and Mixed Company: once a second per Warden each
const NARROWS_META := &"sp_narrows_next"  # On a Warden
const MIXED_META := &"sp_mixed_next"  # On a Warden
const SEEP_META := &"sp_seep"  # On a nightmare: [furthest route index counted, steps so far]

const DOSES_META := &"sp_doses"  # On a nightmare: doses it stepped on (It Grows on You)
const OPEN_META := &"sp_open"  # On a nightmare: until when each spore Warden's next attack is a dose
const OPEN_BY_META := &"sp_open_by"  # On a nightmare: {Warden id: next time}
const HELPING_META := &"sp_helping"  # On a nightmare: the dose serial a partner may answer
const HELPED_META := &"sp_helped"  # On a nightmare: {Warden id: dose serial}
const KINDS_META := &"sp_kinds"  # On a nightmare: {Warden form id: true} (Pass It Round)
const HOT_META := &"sp_hothouse"
const NIGHT_META := &"sp_overnight"  # On a nightmare: {Warden id: next time}

# Mushrooms: route point -> {tower: WeakRef (whose dose), caps: int, grown: bool (a card regrows it), age: int,
# last: int (the last nightmare dosed: Twin Caps doses two different ones), colour: WeakRef (Everything Grows)}
var mushrooms := {}
var _regrow := {}  # Route point -> seconds left (Kept Ground, Mushroom Bed, Side by Side), run only during a drift
var _bed := {}  # Route point -> regrow seconds (the steps Mushroom Bed / Side by Side grow on), rebuilt with the board
var _touch_one := {}  # Route point -> true: touching exactly one spore Warden (Kept Ground)
var _age := 0
var _dose_serial := 0
var _haze := {}  # Warden id -> true: Spore Haze is on (counted each second)
var _haze_in := 0.0
var saved: Array = []  # From the run save; applied once the route is known
var doses_given := 0  # This run (tests and the owner's eye)

func _family() -> String:
	return FAMILY

func _line() -> String:
	return LINE

# More lent cards than class cards (the owner and the council, 2026-10-13, lent_consolidated.md): mushrooms and doses
# belong to every owner holding one of these lent cards; only the Calling (a mushroom from every Poisoned dispel)
# stays with the first pick. A later owner's mushrooms come from Leaf Litter and Side by Side.
func _lent_rules() -> Array:
	return [HOTHOUSE, OVERNIGHT, PASS_IT_ROUND, LEAF_LITTER, SIDE_BY_SIDE, SECOND_HELPING, EVERYTHING_GROWS, NARROWS, SEEPING_IN, MIXED_COMPANY]

func _ready() -> void:
	super._ready()
	add_to_group(GROUP)

func _caps() -> int:
	return TWIN_CAPS if rule(TWIN) else 1

func _slower() -> float:
	return TWIN_SLOWER if rule(TWIN) else 0.0

# --- The board: which steps grow, which are kept --------------------------------------------------------------------

func on_board() -> void:
	_bed.clear()
	_touch_one.clear()
	if not active():
		return
	if not saved.is_empty():
		_load_saved()
	var spores := own_towers()
	var others: Array = towers().filter(is_other_family)
	for i in _route.size():
		var at: Vector2 = _route_px[i]
		var count := 0
		for tower in spores:
			if touches_point(tower, at):
				count += 1
		if count == 1:
			_touch_one[_route[i]] = true
		var every := INF
		if count >= BED_WARDENS and rule(MUSHROOM_BED):
			every = BED_EVERY
		if count >= 1 and rule(SIDE_BY_SIDE) and others.any(func(t) -> bool: return touches_point(t, at)):
			every = minf(every, SIDE_EVERY)  # A step that qualifies for both grows one mushroom on the faster clock
		if every < INF:
			_bed[_route[i]] = every
	# A mushroom goes when its step leaves the route (a Warden planted on it re-routes the path)
	for point in mushrooms.keys():
		if not _index.has(point):
			mushrooms.erase(point)
	for point in _regrow.keys():
		if not _index.has(point):
			_regrow.erase(point)
	# Bed steps with no mushroom and no clock start one (regrow clocks start empty: nothing for selling and replanting)
	for point in _bed:
		if not mushrooms.has(point) and not _regrow.has(point):
			_regrow[point] = float(_bed[point]) + _slower()
	queue_redraw()

# Nothing grows by waiting (owner ruling, section 21): when a rest starts, every step that can grow a mushroom is
# filled at once; the clocks only run during a drift.
func on_rest() -> void:
	if not active():
		return
	for point in _regrow.keys():
		_grow(point, true)
	_regrow.clear()
	for point in _bed:
		if not mushrooms.has(point):
			_grow(point, true)
	queue_redraw()

func _owner_for(at: Vector2):
	var best = null
	var best_d := INF
	for tower in own_towers():
		var d: float = tower.global_position.distance_squared_to(at)
		if d < best_d:
			best_d = d
			best = tower
	return best

func _grow(point: Vector2, grown: bool, tower = null) -> void:
	if not _index.has(point):
		return
	if tower == null:
		tower = _owner_for(_route_px[int(_index[point])])
	if tower == null:
		return  # With no spore Warden left it withers
	_age += 1
	mushrooms[point] = {"tower": weakref(tower), "caps": _caps(), "grown": grown, "age": _age, "last": 0}
	_evict()
	queue_redraw()

func _evict() -> void:
	while mushrooms.size() > MUSHROOM_MAX:
		var oldest = null
		for point in mushrooms:
			var m: Dictionary = mushrooms[point]
			if oldest == null or (not m.grown and mushrooms[oldest].grown) \
					or (m.grown == mushrooms[oldest].grown and int(m.age) < int(mushrooms[oldest].age)):
				oldest = point
		mushrooms.erase(oldest)

# Leaves a mushroom on the step nearest where a nightmare fell (none further than 1 cell from the route).
func leave_mushroom(at: Vector2, tower = null) -> bool:
	var i := nearest_point(at, FALL_CELLS)
	if i < 0 or mushrooms.has(_route[i]):
		return false
	_grow(_route[i], false, tower if is_own(tower) else null)
	return mushrooms.has(_route[i])

# --- Damage events --------------------------------------------------------------------------------------------------

func on_damage(event, source, enemy, is_hit: bool, dispel: bool, _tagged: bool) -> void:
	if active():
		if dispel:
			_fell(enemy)
		elif is_hit:
			if rule(PASS_IT_ROUND):
				_pass_it_round(source, enemy)
			if rule(SPORE_HAZE) and _haze.has(source.get_instance_id()):
				_haze_hit(event, source, enemy)

func _fell(enemy) -> void:
	if enemy.is_flying() and nearest_point(enemy.global_position, FALL_CELLS) < 0:
		return
	var poisoned: bool = enemy.statuses.has(EnemyStatuses.SPORED)
	var at: Vector2 = enemy.global_position
	if poisoned and class_on():  # The Calling: the first pick only
		leave_mushroom(at, enemy.statuses.source(EnemyStatuses.SPORED))  # Mycelium Sprouts' Poisoned counts too
	elif rule(LEAF_LITTER) and strongest_near(at, is_own) != null:
		leave_mushroom(at)  # Leaf Litter: dispelled near a spore Warden, Poisoned or not

# Pass It Round: each different kind of attacking Warden touching a spore Warden gives a dose with its first hit on
# each nightmare (one per kind per nightmare; spore forms and walls don't count; needs no mushroom, so flyers too).
func _pass_it_round(source, enemy) -> void:
	if not is_other(source) or not living(enemy):
		return
	var kinds: Dictionary = enemy.get_meta(KINDS_META, {})
	var kind: String = source.tower_data.get_id()
	if kinds.has(kind):
		return
	var spore = null
	for tower in own_towers():
		if touching(tower, source):
			spore = tower
			break
	if spore == null:
		return
	kinds[kind] = true
	enemy.set_meta(KINDS_META, kinds)
	_line_fx(spore.global_position, source.global_position, 2.0, Palette.MOSS)
	_apply_dose(spore, enemy, DOSE)
	_dose_serial += 1
	if rule(SECOND_HELPING):
		enemy.set_meta(HELPING_META, _dose_serial)  # A Pass It Round dose is a dose too (council, built_td.md)

# Spore Haze: a single-target spore Warden with 4 mushrooms near it attacks in clouds: stacks and puff damage also
# land on up to 4 nightmares touching its target.
func _haze_hit(event, source, enemy) -> void:
	for other in nightmares_touching(enemy, HAZE_OTHERS):
		strike(source, other, event.base, &"spore_haze", true)
		if living(other):
			source._apply_one_status(other, EnemyStatuses.SPORED, maxi(int(source.attack_data.status_stacks), 1), source.get_damage(), false)

# --- Doses ----------------------------------------------------------------------------------------------------------

# One dose: an ordinary Poisoned application from `tower` (one batch, the normal clock, the normal limit).
func _apply_dose(tower, enemy, amount: int) -> void:
	if not is_instance_valid(tower) or not living(enemy):
		return
	doses_given += 1
	var statuses: EnemyStatuses = enemy.statuses
	var cap: int = statuses.get_max_stacks(EnemyStatuses.SPORED) if statuses.has(EnemyStatuses.SPORED) else 0
	tower._apply_one_status(enemy, EnemyStatuses.SPORED, amount, tower.get_damage(), false)
	if cap > 0 and living(enemy):
		statuses.keep_spore_cap(cap)  # A dose never raises the limit: a full nightmare stays full

func _stepped(point: Vector2, enemy) -> void:
	var m: Dictionary = mushrooms[point]
	if int(m.last) == enemy.get_instance_id():
		return  # Twin Caps: two different nightmares
	var tower = m.tower.get_ref()
	if not is_own(tower) or not is_instance_valid(tower):
		mushrooms.erase(point)  # Its Warden is gone: it withers (council, lent_td.md: no inheriting a sold bed)
		queue_redraw()
		return
	var amount := DOSE
	if rule(IT_GROWS):  # Each dose a nightmare steps on is 1 bigger than its last, up to 6
		var taken := int(enemy.get_meta(DOSES_META, 0))
		amount = mini(DOSE + taken, GROWS_MAX)
		enemy.set_meta(DOSES_META, taken + 1)
	_apply_dose(tower, enemy, amount)
	_dose_serial += 1
	if rule(KICKED_UP):  # Up to 4 touching it take a fresh dose of 3; a received dose counts for nothing else
		for other in nightmares_touching(enemy, KICKED_OTHERS):
			_apply_dose(tower, other, DOSE)
	if rule(OPEN_SEASON):
		enemy.set_meta(OPEN_META, now() + OPEN_SEASON_WINDOW)
	if rule(SECOND_HELPING):
		enemy.set_meta(HELPING_META, _dose_serial)
	if rule(EVERYTHING_GROWS):  # The nearest other-family Warden touching the mushroom adds 3 of its own status
		var at: Vector2 = _route_px[int(_index[point])]
		var partner = null
		var best := INF
		for other in towers():
			if is_other_family(other) and status_of(other) != &"" and touches_point(other, at) \
					and other.global_position.distance_squared_to(at) < best:
				best = other.global_position.distance_squared_to(at)
				partner = other
		if partner != null and living(enemy):
			partner._apply_one_status(enemy, status_of(partner), EVERYTHING_STACKS, partner.get_damage(), false)
	m.last = enemy.get_instance_id()
	m.caps = int(m.caps) - 1
	if int(m.caps) > 0:
		queue_redraw()
		return
	mushrooms.erase(point)
	# Grows back: a bed step on its clock; Kept Ground where only one spore Warden touches the step
	if _bed.has(point):
		_regrow[point] = float(_bed[point]) + _slower()
	elif rule(KEPT_GROUND) and _touch_one.has(point):
		_regrow[point] = KEPT_EVERY + _slower()
	queue_redraw()

# --- The poll -------------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	super._process(delta)
	if dream_state == null or not active() or get_tree().paused:
		return
	# The regrow clocks run only during a drift
	if not resting() and not _regrow.is_empty():
		for point in _regrow.keys():
			_regrow[point] = float(_regrow[point]) - delta
			if float(_regrow[point]) <= 0.0:
				_regrow.erase(point)
				if not mushrooms.has(point):
					_grow(point, true)
	# Steps: a walker's centre reaching a mushroom's route point (every frame: a fast nightmare must not skip one)
	if mushrooms.is_empty():
		return
	var reach := (STEP_CELLS * cell()) ** 2
	for enemy in enemies():
		if enemy.is_flying():
			continue
		var point: Vector2 = enemy.get_target_cell()
		if mushrooms.has(point) and enemy.global_position.distance_squared_to(_route_px[int(_index[point])]) <= reach:
			_stepped(point, enemy)

func on_poll() -> void:
	if rule(SPORE_HAZE):
		_haze_in -= POLL
		if _haze_in <= 0.0:
			_haze_in = 1.0  # Counted each second
			_haze.clear()
			for tower in own_towers():
				if not SINGLE_TARGET.has(tower.tower_data.get_id()):
					continue
				var count := 0
				for point in mushrooms:
					if near(tower.global_position, _route_px[int(_index[point])]):
						count += 1
				if count >= HAZE_MUSHROOMS:
					_haze[tower.get_instance_id()] = true
	if rule(HOTHOUSE):
		for enemy in enemies():
			_hothouse(enemy)
	if rule(SEEPING_IN):
		for enemy in enemies():
			_seep(enemy)

# Hothouse (lent, a bet): when a nightmare's Poisoned reaches 6, each other status on it gains 5 at once, quietly
# (no clock, strength or source change; never starts a status; never Rooted). Once per nightmare.
func _hothouse(enemy) -> void:
	var statuses: EnemyStatuses = enemy.statuses
	if enemy.has_meta(HOT_META) or statuses.stacks(EnemyStatuses.SPORED) < HOTHOUSE_AT:
		return
	var any := false
	for id in statuses.active_ids():
		if id != EnemyStatuses.SPORED and statuses.add_quiet(id, HOTHOUSE_ADD) > 0:
			any = true
	if any:
		enemy.set_meta(HOT_META, true)
		Reactions._effect(&"landing_dust", enemy.global_position, self, 0.6)

# --- A Warden's own next application (Tower._apply_one_status asks through DreamState.class_stacks) ------------------

# The stacks `tower`'s own application of `status` adds to `enemy` (never fewer than `stacks`).
func own_stacks(tower, enemy, status: StringName, stacks: int) -> int:
	if stacks <= 0 or not living(enemy) or status == EnemyStatuses.HELD:
		return stacks
	var id: int = tower.get_instance_id()
	if is_own(tower) and status == EnemyStatuses.SPORED:
		# Open Season: after a nightmare steps on a mushroom, each spore Warden's next attack on it is a dose too
		if rule(OPEN_SEASON) and now() <= float(enemy.get_meta(OPEN_META, -INF)):
			var by: Dictionary = enemy.get_meta(OPEN_BY_META, {})
			if now() >= float(by.get(id, -INF)):
				by[id] = now() + OPEN_SEASON_EVERY
				enemy.set_meta(OPEN_BY_META, by)
				stacks = maxi(stacks, DOSE)
		# Overnight (lent): 3 at once on a nightmare carrying another family's status, once a second each
		if rule(OVERNIGHT) and stacks < OVERNIGHT_STACKS and _carries_other(enemy):
			var next: Dictionary = enemy.get_meta(NIGHT_META, {})
			if now() >= float(next.get(id, -INF)):
				next[id] = now() + OVERNIGHT_EVERY
				enemy.set_meta(NIGHT_META, next)
				stacks = OVERNIGHT_STACKS
	elif rule(SECOND_HELPING) and is_other_family(tower) and enemy.has_meta(HELPING_META):
		# Second Helping: after a dose, a partner touching a spore Warden adds 3 of its own status, once per dose
		var serial := int(enemy.get_meta(HELPING_META))
		var helped: Dictionary = enemy.get_meta(HELPED_META, {})
		if int(helped.get(id, -1)) != serial and own_towers().any(func(t) -> bool: return touching(t, tower)):
			helped[id] = serial
			enemy.set_meta(HELPED_META, helped)
			stacks = maxi(stacks, HELPING_STACKS)
	return _stack_cards(tower, enemy, status, stacks)

# Narrows and Mixed Company: a Warden's own status hit adds more (never Rooted; Charged stops one short of a bolt).
func _stack_cards(tower, enemy, status: StringName, base: int) -> int:
	var extra := 0
	if rule(NARROWS) and now() >= float(tower.get_meta(NARROWS_META, -INF)) and _in_narrows(tower, enemy):
		tower.set_meta(NARROWS_META, now() + STACK_EVERY)
		extra += NARROWS_SMALL if status == EnemyStatuses.STATIC or status == EnemyStatuses.MARKED else NARROWS_EXTRA
	if rule(MIXED_COMPANY) and status != EnemyStatuses.DROWSY and now() >= float(tower.get_meta(MIXED_META, -INF)) and _mixed(enemy):
		tower.set_meta(MIXED_META, now() + STACK_EVERY)
		extra += base  # Twice the hit's own stacks: never other cards' bonuses, never Drowsy (it would double sleep)
	if extra <= 0:
		return base
	if status == EnemyStatuses.STATIC:
		var room: int = enemy.statuses.get_max_stacks(status) - 1 - enemy.statuses.stacks(status) - base
		extra = clampi(extra, 0, maxi(room, 0))
	return base + extra

# Narrows: the nightmare is touching a spore Warden and another kind of attacking Warden (Sprouts count; a second
# spore Warden does not).
func _in_narrows(_tower, enemy) -> bool:
	var at: Vector2 = enemy.global_position
	var spore := false
	var other := false
	for warden in towers():
		if not warden.tower_data.can_attack or not touches_point(warden, at):
			continue
		if is_own(warden):
			spore = true
		elif is_other(warden):
			other = true
	return spore and other

# Mixed Company: Poisoned and 2 other statuses, from any Warden (never Rooted).
func _mixed(enemy) -> bool:
	var statuses: EnemyStatuses = enemy.statuses
	if not statuses.has(EnemyStatuses.SPORED):
		return false
	var others := 0
	for id in statuses.active_ids():
		if id != EnemyStatuses.SPORED and id != EnemyStatuses.HELD:
			others += 1
	return others >= MIXED_OTHERS

# Seeping In: steps walked inside a spore Warden's range, counted forward only (a pull-back or push never counts twice).
func _seep(enemy) -> void:
	var i := index_of(enemy)
	if i < 0:
		return
	var seep: Array = enemy.get_meta(SEEP_META, [i, 0.0])
	if i <= int(seep[0]):
		return
	var inside := false
	for tower in own_towers():
		if tower.global_position.distance_to(enemy.global_position) <= tower.get_range_pixels():
			inside = true
			break
	var steps: float = float(seep[1]) + ((i - int(seep[0])) * 0.5 if inside else 0.0)
	while steps >= SEEP_STEPS:
		steps -= SEEP_STEPS
		for id in enemy.statuses.active_ids():
			if id != EnemyStatuses.HELD:
				enemy.statuses.add_quiet(id, SEEP_STACKS)
	enemy.set_meta(SEEP_META, [i, steps])

func _carries_other(enemy) -> bool:
	var statuses: EnemyStatuses = enemy.statuses
	for id in statuses.active_ids():
		if id != EnemyStatuses.SPORED and id != EnemyStatuses.HELD and is_other_family(statuses.source(id)):
			return true
	return false

# --- Save (mushrooms survive rests) -----------------------------------------------------------------------------------

func to_save() -> Array:
	var out: Array = []
	for point in mushrooms:
		out.append([point.x, point.y, int(mushrooms[point].caps), bool(mushrooms[point].grown)])
	return out

func _load_saved() -> void:
	var rows := saved
	saved = []
	for row in rows:
		if not (row is Array) or row.size() < 2:
			continue
		var point := Vector2(float(row[0]), float(row[1]))
		_grow(point, bool(row[3]) if row.size() > 3 else false)
		if mushrooms.has(point) and row.size() > 2:
			mushrooms[point].caps = clampi(int(row[2]), 1, TWIN_CAPS)

# --- Drawing: mushrooms are objects you can count, never a tint on the path -------------------------------------------

func _draw() -> void:
	if not active():
		return
	for point in mushrooms:
		if not _index.has(point):
			continue
		var at: Vector2 = _route_px[int(_index[point])]
		var caps := int(mushrooms[point].caps)
		for k in caps:
			var offset := Vector2((k - (caps - 1) / 2.0) * MUSHROOM_PAIR_GAP, 0.0)
			_draw_mushroom(at + offset, 1.0 if caps == 1 else MUSHROOM_PAIR_SCALE, 1.0, (int(point.x * 2.0) + k) % 2 == 1)
	for point in _regrow:  # A small, faint one where a mushroom is growing back
		if _index.has(point) and not mushrooms.has(point):
			_draw_mushroom(_route_px[int(_index[point])], MUSHROOM_SPROUT_SCALE, 0.5, false)

# The mushroom art: the first frame of the spore sprite sheet (the Brood Cap's walking mushrooms, Tower Assets), standing
# with its stem on the route point. The plain shape is only the fallback when the sheet is missing.
const MUSHROOM_SHEET := "res://assets/towers/projectiles/spore_sprite.png"  # 4 frames side by side
const MUSHROOM_FRAMES := 4
const MUSHROOM_PAIR_GAP := 11.0  # Twin Caps: px between the two
const MUSHROOM_PAIR_SCALE := 0.8
const MUSHROOM_SPROUT_SCALE := 0.45
var _mushroom_tex: Texture2D = load(MUSHROOM_SHEET) if ResourceLoader.exists(MUSHROOM_SHEET) else null  # Per node, never static

func _draw_mushroom(at: Vector2, scale: float, alpha: float, flip: bool) -> void:
	if _mushroom_tex == null:
		draw_circle(at + Vector2(0.0, -4.0) * scale, 5.0 * scale, Color(Palette.BLOSSOM, alpha))
		return
	var w: float = _mushroom_tex.get_width() / float(MUSHROOM_FRAMES)
	var h: float = _mushroom_tex.get_height()
	var size := Vector2(w, h) * scale
	var rect := Rect2(at - Vector2(size.x / 2.0, size.y * 0.85), size)  # Stem on the point
	if flip:
		rect = Rect2(rect.position + Vector2(size.x, 0.0), Vector2(-size.x, size.y))
	draw_texture_rect_region(_mushroom_tex, rect, Rect2(0.0, 0.0, w, h), Color(1.0, 1.0, 1.0, alpha))  # multiplier
