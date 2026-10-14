extends "res://scripts/combat/class_kit.gd"
# The Bellflower class (dream_council_review.md 20 "Bellflower: every fourth ring happens again", rulings in 21).
# Calling, Keeping Time: every 4th ring on a nightmare is a Toll: it lands again, at half. Each nightmare starts with
# 2 of its 4 pips filled. A ring is a hit from one of your bells (any form of the song line). The count lives on the
# nightmare; rings closer than half a second count as one; one Toll a second for each nightmare.
# The 3 lent cards (Struck Bell, Chorus, Knell) carry "every 4th ring" themselves, with the same count, so they work
# for any Bellflower owner. Every number is a paper starting value.

const GROUP := &"keeping_time"
const FAMILY := "bellflower"
const LINE := "song"

const TOLL_EVERY := 4  # Every 4th ring…
const PIPS_FILLED := 2  # …and each nightmare starts with this many pips filled
const TOLL_SHARE := 0.5  # The Toll lands again at half
const RING_MERGE := 0.5  # Rings closer than this count as one
const TOLL_WAIT := 1.0  # One Toll a second for each nightmare
const CARRY_STEPS := 4  # Sound Carries, Rounds, Call and Answer: this many steps down the path
const CARRY_SHARE := 0.5
const ROUNDS_SHARE := 0.5
const JOIN_EVERY := 1.0  # Join In, Struck Bell: each Warden's hit counts once a second
const RUDE_MULTIPLIER := 2.0  # Rude Awakening: the next hit on a nightmare waking from any sleep…
const RUDE_WINDOW := 2.0  # …within this long of waking (the hit that wakes it counts)
const VOICE_STEP := 0.5  # Full Voice: cells of reach per pulse that Tolls…
const VOICE_MAX_CELLS := 4.0  # …up to this reach in all
const OVERTURE_SECONDS := 8.0
const RISING_STEP := 0.25  # Rising Song: each pulse that Tolls adds this to the Toll's landing…
const RISING_MAX := 2.0  # …from a half up to double
const SLEEP_NO_MORE_OTHERS := 6
const NOTE_SECONDS := 2.0  # Hanging Note
const NOTE_CELLS := 0.5  # …about 1 cell wide
const REFRAIN_SECONDS := 2.0  # Refrain: a Tolled nightmare rings on this long…
const REFRAIN_EVERY := 2.0  # …each Warden once per this long
const CHORUS_SHARE := 0.5  # Chorus: the stored hit again at half…
const CHORUS_SECONDS := 0.5  # …never more than this many seconds of that Warden's damage
const KNELL_DEWDROPS := 2  # Knell on Soaked: up to this many Dewdrops near it hit it once, free

# Card rule ids
const SOUND_CARRIES := &"sound_carries"
const ROUNDS := &"rounds"
const CALL_AND_ANSWER := &"call_and_answer"
const JOIN_IN := &"join_in"
const NOD_OFF := &"nod_off"
const RUDE_AWAKENING := &"rude_awakening"
const FULL_VOICE := &"full_voice"
const OVERTURE := &"overture"
const RISING_SONG := &"class_rising_song"
const SLEEP_NO_MORE := &"sleep_no_more"
const HANGING_NOTE := &"hanging_note"
const REFRAIN := &"refrain"
const STRUCK_BELL := &"struck_bell"  # Lent
const CHORUS := &"lent_chorus"  # Lent
const KNELL := &"knell"  # Lent
const ON_THE_BEAT := &"on_the_beat"  # Lent (took Sound Carries' slot, 2026-10-13)
const BEAT_EVERY := 2.0  # On the Beat: each Warden once every 2 s…
const BEAT_HALFWAY := 0.5  # …and only if it is at least this far to its next attack (so slow Wardens never double)
const BEAT_META := &"kt_beat_next"  # On a Warden
const BEAT_FRAME_META := &"kt_beat_frame"  # On a bell: the frame it last set the beat
const RUDE_NEXT_META := &"kt_rude_next"  # On a bell: Rude Awakening, one doubled waking hit per bell a second

const PIPS_META := &"kt_pips"  # On a nightmare: pips filled
const RING_META := &"kt_ring_at"  # On a nightmare: its last counted ring
const TOLL_META := &"kt_toll_next"  # On a nightmare: when it may Toll again
const TOLLED_META := &"kt_tolled"  # On a nightmare: it has Tolled (Nod Off: the first one)
const ROUNDS_META := &"kt_rounds"  # On a nightmare: {bell: id, index, amount}
const ANSWER_META := &"kt_answer"  # On a nightmare: {bell: id, index}
const REFRAIN_META := &"kt_refrain"  # On a nightmare: until when the next partner hit lands again
const LAST_HIT_META := &"kt_last_hit"  # On a nightmare: {source: WeakRef, base} (Chorus)
const ASLEEP_META := &"kt_asleep"  # On a nightmare: asleep at the last poll
const WOKE_META := &"kt_woke"  # On a nightmare: when it woke
const SLEEP_META := &"kt_sleep"  # On a nightmare: its sleep count
const RUDE_META := &"kt_rude"  # On a nightmare: the sleep Rude Awakening paid for
const BURST_META := &"kt_burst"  # On a nightmare: the sleep Sleep No More paid for
const JOIN_META := &"kt_join_next"  # On a Warden: when its hit may count as a ring again
const REFRAIN_NEXT_META := &"kt_refrain_next"  # On a Warden
const VOICE_META := &"kt_voice"  # On a bell: Full Voice steps
const RISING_META := &"kt_rising"  # On a bell: Rising Song steps
const OVERTURE_META := &"kt_overture"  # On a bell: until when every ring is a Toll
const OVERTURE_DRIFT_META := &"kt_overture_drift"  # On a bell: the drift it last played its Overture in
const STEP_META := &"kt_step_frame"  # On a bell: the frame its pulse last grew Full Voice / Rising Song
const PULSE_META := &"kt_pulse_frame"  # On a bell: the frame of its last pulse (Sound Carries: once per pulse)
const SLEEPER_META := &"kt_sleeper"  # On a bell: WeakRef to the nightmare it put to sleep (one sleeper for each bell)

var _reach := {}  # Bell instance id -> {route index: true}
var _carry := {}  # Bell instance id -> Array of route indices past its reach (Sound Carries)
var _exit := {}  # Bell instance id -> the last route index inside its reach
var _notes: Array = []  # Hanging notes: [{at: Vector2, until, amount, bell: WeakRef, struck: {id: true}}]
var tolls := 0  # This run (tests and the owner's eye)

func _family() -> String:
	return FAMILY

func _line() -> String:
	return LINE

# More lent cards than class cards (the owner and the council, 2026-10-13, lent_consolidated.md): every owner holding
# one of these counts rings and Tolls on every 4th; only the Calling's head start (2 of 4 pips filled, so the first
# Toll is ring 2) stays with the first pick. Rising Song, Overture and Rounds stay class cards.
func _lent_rules() -> Array:
	return [STRUCK_BELL, CHORUS, KNELL, SOUND_CARRIES, JOIN_IN, NOD_OFF, RUDE_AWAKENING, SLEEP_NO_MORE, REFRAIN, ON_THE_BEAT]

# Tolls for a later owner come only with the cards that talk about rings or Tolls (owner 2026-10-13): Rude Awakening
# and Sleep No More do only what they say. Struck Bell and Chorus ride in on Join In and Refrain (extra_rules).
const TOLL_RULES: Array[StringName] = [JOIN_IN, NOD_OFF, REFRAIN, KNELL, SOUND_CARRIES, STRUCK_BELL, CHORUS]  # (On the Beat is about the bell's ring, not Tolls)

func tolls_on() -> bool:
	if class_on():
		return true
	for id in TOLL_RULES:
		if rule(id):
			return true
	return false

func _start_pips() -> int:
	return PIPS_FILLED if class_on() else 0

func _ready() -> void:
	super._ready()
	add_to_group(GROUP)

static func is_pulsing(tower) -> bool:
	return tower is Tower and tower.attack_data != null and tower.attack_data.attack_kind == TowerData.AttackKind.PULSE

func bells() -> Array:
	return own_towers()

# --- The board: each bell's reach along the path -------------------------------------------------------------------------

func on_board() -> void:
	_reach.clear()
	_carry.clear()
	_exit.clear()
	var all := bells()
	for bell in all:
		var mine := {}
		var last := -1
		for i in points_in_reach(bell):
			mine[i] = true
			last = maxi(last, int(i))
		_reach[bell.get_instance_id()] = mine
		_exit[bell.get_instance_id()] = last
	for bell in all:
		var id: int = bell.get_instance_id()
		var carried: Array = []
		for i in range(int(_exit[id]) + 1, mini(int(_exit[id]) + CARRY_STEPS * 2, _route.size() - 1) + 1):
			if _bell_at(i, bell) != null:
				break  # It stops at the next bell's reach
			carried.append(i)
		_carry[id] = carried

# A bell whose reach holds route index `i` (not `skip`), or null.
func _bell_at(i: int, skip = null):
	for bell in bells():
		if bell != skip and _reach.get(bell.get_instance_id(), {}).has(i):
			return bell
	return null

func _in_reach(bell, enemy) -> bool:
	return is_instance_valid(bell) and bell.global_position.distance_to(enemy.global_position) <= bell.get_range_pixels()

# --- Rings and Tolls ------------------------------------------------------------------------------------------------------

# One ring on `enemy` from `bell` (its own hit, a carried ring, or another Warden's counted hit). `amount`: the ring's
# damage, before the nightmare's defences: what a Toll lands again.
# `counted`: another Warden's hit counted as a ring (Join In, Struck Bell): its Toll never grows Full Voice or Rising Song.
func ring(enemy, bell, amount: float, counted: bool = false) -> void:
	if not living(enemy) or not is_instance_valid(bell) or not tolls_on():
		return
	var pips := int(enemy.get_meta(PIPS_META, _start_pips()))
	var answered := false
	if rule(CALL_AND_ANSWER) and enemy.has_meta(ANSWER_META):
		# Call and Answer: after a Toll, the next bell down the path, within 4 steps, Tolls it on its first ring
		var answer: Dictionary = enemy.get_meta(ANSWER_META)
		var i := index_of(enemy)
		if int(answer.bell) != bell.get_instance_id() and i >= 0 and i - int(answer.index) <= CARRY_STEPS * 2 + _reach_width(bell):
			answered = true
			enemy.remove_meta(ANSWER_META)
	var overture: bool = rule(OVERTURE) and now() < float(bell.get_meta(OVERTURE_META, -INF))
	if not answered and not overture:
		if now() - float(enemy.get_meta(RING_META, -INF)) < RING_MERGE:
			return  # Rings closer than half a second count as one
		pips += 1
	enemy.set_meta(RING_META, now())
	if pips < TOLL_EVERY and not answered and not overture:
		enemy.set_meta(PIPS_META, pips)
		return
	if now() < float(enemy.get_meta(TOLL_META, -INF)):
		enemy.set_meta(PIPS_META, mini(pips, TOLL_EVERY - 1))  # It waits a pip short: one Toll a second
		return
	enemy.set_meta(PIPS_META, 0)
	enemy.set_meta(TOLL_META, now() + TOLL_WAIT)
	_toll(enemy, bell, amount, overture, counted)

func _reach_width(bell) -> int:
	return _reach.get(bell.get_instance_id(), {}).size()

func _toll(enemy, bell, amount: float, overture: bool, counted: bool = false) -> void:
	tolls += 1
	var on := active()
	var pulsing := is_pulsing(bell)
	var share := TOLL_SHARE
	if on and pulsing and not overture and rule(RISING_SONG):
		share = minf(TOLL_SHARE + RISING_STEP * int(bell.get_meta(RISING_META, 0)), RISING_MAX)  # Overture's Tolls always land at half
	var landing := amount * share
	var first: bool = not enemy.has_meta(TOLLED_META)
	enemy.set_meta(TOLLED_META, true)
	Reactions._effect(&"landing_dust", enemy.global_position, self, 0.5)
	strike(bell, enemy, landing, &"toll", true)
	if on:
		_grow(bell, pulsing and not counted)  # Growth is per pulse of the bell itself, never per counted hit
		var i := index_of(enemy)
		if rule(ROUNDS):
			enemy.set_meta(ROUNDS_META, {"bell": bell.get_instance_id(), "index": i, "amount": amount * ROUNDS_SHARE})
		if rule(CALL_AND_ANSWER):
			enemy.set_meta(ANSWER_META, {"bell": bell.get_instance_id(), "index": i})
		if rule(REFRAIN):
			enemy.set_meta(REFRAIN_META, now() + REFRAIN_SECONDS)
		if rule(HANGING_NOTE) and pulsing:
			_hang_note(bell, enemy.global_position, landing)
		if rule(NOD_OFF) and first and living(enemy):
			var sleeper = bell.get_meta(SLEEPER_META).get_ref() if bell.has_meta(SLEEPER_META) else null
			if not (living(sleeper) and sleeper.statuses.is_asleep()) and nap(enemy):  # One sleeper for each bell
				bell.set_meta(SLEEPER_META, weakref(enemy))
	if not living(enemy):
		return
	if rule(CHORUS):
		_chorus(enemy, bell)
	if rule(KNELL):
		_knell(enemy, bell)

# Full Voice and Rising Song: one step per pulse that Tolls, however many nightmares that pulse Tolled.
func _grow(bell, pulsing: bool) -> void:
	if not pulsing or int(bell.get_meta(STEP_META, -1)) == Engine.get_process_frames():
		return
	bell.set_meta(STEP_META, Engine.get_process_frames())
	if rule(RISING_SONG):
		bell.set_meta(RISING_META, int(bell.get_meta(RISING_META, 0)) + 1)
	if rule(FULL_VOICE):
		bell.set_meta(VOICE_META, int(bell.get_meta(VOICE_META, 0)) + 1)
		dream_state.bump_board()  # Its reach grew (DreamEffects' Full Voice row reads voice_cells)

# Full Voice: the cells of reach a pulsing bell has grown (DreamEffects asks; 4 cells in all, everything else included).
func voice_cells(bell, base_range: float) -> float:
	if not rule(FULL_VOICE) or not is_instance_valid(bell):
		return 0.0
	return clampf(VOICE_STEP * int(bell.get_meta(VOICE_META, 0)), 0.0, maxf(VOICE_MAX_CELLS - base_range, 0.0))

func _hang_note(bell, at: Vector2, amount: float) -> void:
	for i in range(_notes.size() - 1, -1, -1):
		if _notes[i].bell.get_ref() == bell:
			_notes.remove_at(i)  # One per bell
	_notes.append({"at": at, "until": now() + NOTE_SECONDS, "amount": amount, "bell": weakref(bell), "struck": {}})
	queue_redraw()

# Chorus (lent): on a Toll the bell also repeats the last hit another family's Warden near it landed there, at half
# (never more than half a second of that Warden's damage); its status comes with it as a quiet add.
func _chorus(enemy, bell) -> void:
	if not enemy.has_meta(LAST_HIT_META):
		return
	var last: Dictionary = enemy.get_meta(LAST_HIT_META)
	enemy.remove_meta(LAST_HIT_META)  # Each hit is repeated once, by Chorus or by Refrain, never both
	var partner = last.source.get_ref()
	if not is_other_family(partner) or not near(partner.global_position, bell.global_position):
		return
	_line_fx(bell.global_position, enemy.global_position, 3.0, Palette.BLOSSOM)
	strike(partner, enemy, minf(float(last.base) * CHORUS_SHARE, second_of(partner) * CHORUS_SECONDS), &"chorus_repeat")
	var status := status_of(partner)
	if status != &"" and living(enemy):
		enemy.statuses.add_quiet(status, 1)

# Knell (lent): a Toll sets off one status from another family's Warden, the fullest first: it pays out at once and is
# used up. Never Rooted, Exposed or Drowsy.
func _knell(enemy, _bell) -> void:
	var statuses: EnemyStatuses = enemy.statuses
	var chosen := &""
	var fullest := -1.0
	for id in [EnemyStatuses.SPORED, EnemyStatuses.STATIC, EnemyStatuses.DAMP]:
		if not statuses.has(id) or not is_other_family(statuses.source(id)):
			continue
		var share: float = float(statuses.stacks(id)) / maxf(statuses.get_max_stacks(id), 1.0)
		if id == EnemyStatuses.DAMP and share < 1.0:
			continue  # Soaked must be full
		if share > fullest:
			fullest = share
			chosen = id
	var source = statuses.source(chosen) if chosen != &"" else null
	match chosen:
		EnemyStatuses.SPORED:  # It ticks once more, at once; its oldest batch is gone
			strike(source, enemy, statuses.stacks(chosen) * statuses.potency(chosen) * EnemyStatuses.SPORE_TICK, &"knell", true)
			if living(enemy):
				statuses.drop_oldest_spore_batch()
		EnemyStatuses.STATIC:  # It goes off as a bolt for the charge it has; all its Charged is used
			var bolt: float = statuses.stored_bolt_damage()
			statuses.remove(chosen)
			strike(source, enemy, bolt, &"knell")
		EnemyStatuses.DAMP:  # Up to 2 Dewdrops near it hit it once, free; it is wrung dry
			var fired := 0
			for tower in towers():
				if fired >= KNELL_DEWDROPS:
					break
				if tower.tower_data.line == "water" and tower.tower_data.can_attack and near(tower.global_position, enemy.global_position) \
						and free_hit(tower, enemy):
					fired += 1
			if living(enemy):
				statuses.remove(chosen)

# --- Damage events ------------------------------------------------------------------------------------------------------

func on_damage(event, source, enemy, is_hit: bool, _dispel: bool, tagged: bool) -> void:
	if tagged or source == null or not is_hit or not living(enemy):
		return
	var on := active()
	if is_own(source):
		if rule(ON_THE_BEAT) and int(source.get_meta(BEAT_FRAME_META, -1)) != Engine.get_process_frames():
			source.set_meta(BEAT_FRAME_META, Engine.get_process_frames())
			_beat(source)
		if on and is_pulsing(source) and int(source.get_meta(PULSE_META, -1)) != Engine.get_process_frames():
			source.set_meta(PULSE_META, Engine.get_process_frames())
			if rule(SOUND_CARRIES):
				_carry_ring(source, event.base)
		ring(enemy, source, event.base)
		return
	# Another Warden's hit
	if on and rule(SLEEP_NO_MORE):
		_sleep_no_more(event, source, enemy)
	if on and rule(REFRAIN) and is_other_family(source) and now() < float(enemy.get_meta(REFRAIN_META, -INF)) \
			and now() >= float(source.get_meta(REFRAIN_NEXT_META, -INF)):
		# Refrain: a Tolled nightmare rings on: the next hit from another family's Warden lands again, in full
		enemy.remove_meta(REFRAIN_META)
		enemy.remove_meta(LAST_HIT_META)
		if free_hit(source, enemy, 1.0, &"refrain"):
			source.set_meta(REFRAIN_NEXT_META, now() + REFRAIN_EVERY)
		return
	if not is_other(source):
		return
	var counted = null
	for bell in bells():
		if not _in_reach(bell, enemy):
			continue
		if on and rule(JOIN_IN) and touching(source, bell):
			counted = bell  # Join In: any other Warden touching a bell (Sprouts count)
			break
		if rule(STRUCK_BELL) and is_other_family(source) and near(source.global_position, bell.global_position):
			counted = bell  # Struck Bell: another family's Warden near a bell
			break
	if rule(CHORUS) and is_other_family(source) and strongest_near(source.global_position, is_own) != null:
		enemy.set_meta(LAST_HIT_META, {"source": weakref(source), "base": event.base})  # Stored before defences
	if counted != null and now() >= float(source.get_meta(JOIN_META, -INF)):
		source.set_meta(JOIN_META, now() + JOIN_EVERY)
		_line_fx(source.global_position, counted.global_position, 1.5, Palette.BLOSSOM)
		ring(enemy, counted, counted.get_damage(), true)  # The Toll is always the bell's own ring; a counted hit is not a pulse

# On the Beat: when a bell rings, each attacking Warden touching it (not another bell) that is at least halfway to its
# next attack attacks now. Each Warden once every 2 s. Only the bell's own ring counts, so it never loops with Join In.
func _beat(bell) -> void:
	for tower in towers():
		if tower == bell or is_own(tower) or not tower.tower_data.can_attack or not touching(tower, bell):
			continue
		if now() < float(tower.get_meta(BEAT_META, -INF)):
			continue
		var period: float = 1.0 / maxf(tower.get_attacks_per_second(), 0.01)
		if tower._cooldown > period * BEAT_HALFWAY:
			continue  # Not halfway yet: a slow Warden is never doubled
		tower.set_meta(BEAT_META, now() + BEAT_EVERY)
		tower._cooldown = 0.0
		_line_fx(bell.global_position, tower.global_position, 1.5, Palette.BLOSSOM)

# Sound Carries: a pulsing bell's ring carries 4 steps down the path past its reach, at half, stopping at the next
# bell's reach. Carried rings count; each nightmare takes one per pulse.
func _carry_ring(bell, base: float) -> void:
	var carried: Array = _carry.get(bell.get_instance_id(), [])
	if carried.is_empty():
		return
	for enemy in enemies():
		if carried.has(index_of(enemy)) and not _in_reach(bell, enemy):
			strike(bell, enemy, base * CARRY_SHARE, &"carried_ring", true)
			ring(enemy, bell, base * CARRY_SHARE)

# Sleep No More: the hit that wakes a sleeping nightmare lands in full on every nightmare touching it too (up to 6;
# never more than one second of that Warden's damage).
func _sleep_no_more(event, source, enemy) -> void:
	if not enemy.get_meta(ASLEEP_META, false) or enemy.statuses.is_asleep():
		return
	var sleep := int(enemy.get_meta(SLEEP_META, 0))
	if int(enemy.get_meta(BURST_META, -1)) == sleep:
		return
	enemy.set_meta(BURST_META, sleep)
	Reactions._effect(&"landing_dust", enemy.global_position, self, 1.0)
	for other in nightmares_touching(enemy, SLEEP_NO_MORE_OTHERS):
		strike(source, other, minf(event.base, second_of(source)), &"sleep_no_more", true)

# --- The poll: sleepers, busy bells, Rounds, hanging notes -------------------------------------------------------------------

func on_poll() -> void:
	if not active():
		return
	var all := bells()
	var drift: int = dream_state.drift_director.drifts_started if dream_state.drift_director != null else 0
	var busy := {}
	for enemy in enemies():
		var asleep: bool = enemy.statuses.is_asleep()
		if asleep and not enemy.get_meta(ASLEEP_META, false):
			enemy.set_meta(SLEEP_META, int(enemy.get_meta(SLEEP_META, 0)) + 1)
		elif not asleep and enemy.get_meta(ASLEEP_META, false):
			enemy.set_meta(WOKE_META, now())
		enemy.set_meta(ASLEEP_META, asleep)
		for bell in all:
			if _in_reach(bell, enemy):
				busy[bell.get_instance_id()] = true
				# Rounds: a Toll is heard again when that nightmare walks into the next bell's reach, within 4 steps
				if enemy.has_meta(ROUNDS_META):
					var rounds: Dictionary = enemy.get_meta(ROUNDS_META)
					if int(rounds.bell) != bell.get_instance_id():
						enemy.remove_meta(ROUNDS_META)
						var i := index_of(enemy)
						if i >= 0 and i - int(rounds.index) <= CARRY_STEPS * 2 + _reach_width(bell):
							strike(bell, enemy, float(rounds.amount), &"rounds", true)  # Not a ring; never repeated again
	for bell in all:
		if not is_pulsing(bell):
			continue
		var id: int = bell.get_instance_id()
		if busy.has(id):
			# Overture: when a drift's first nightmare enters its reach, every ring is a Toll until that reach is empty
			if rule(OVERTURE) and not resting() and int(bell.get_meta(OVERTURE_DRIFT_META, -1)) != drift:
				bell.set_meta(OVERTURE_DRIFT_META, drift)
				bell.set_meta(OVERTURE_META, now() + OVERTURE_SECONDS)
			continue
		# Its reach is empty: Full Voice and Rising Song reset, the Overture ends
		bell.set_meta(OVERTURE_META, -INF)
		bell.set_meta(RISING_META, 0)
		if int(bell.get_meta(VOICE_META, 0)) != 0:
			bell.set_meta(VOICE_META, 0)
			dream_state.bump_board()
	_tick_notes()

# Hanging Note: nightmares walking into the note are struck, at half, once each. Not a ring.
func _tick_notes() -> void:
	if _notes.is_empty():
		return
	var reach := NOTE_CELLS * cell()
	for i in range(_notes.size() - 1, -1, -1):
		var note: Dictionary = _notes[i]
		var bell = note.bell.get_ref()
		if now() >= float(note.until) or not is_instance_valid(bell):
			_notes.remove_at(i)
			queue_redraw()
			continue
		for enemy in Tower.nightmares_near(get_tree(), note.at, reach):
			if living(enemy) and not note.struck.has(enemy.get_instance_id()) and enemy.global_position.distance_to(note.at) <= reach:
				note.struck[enemy.get_instance_id()] = true
				strike(bell, enemy, float(note.amount), &"hanging_note", true)

func on_rest() -> void:
	_notes.clear()
	queue_redraw()

# --- What the other systems ask (through DreamState) --------------------------------------------------------------------

# Rude Awakening: the next hit on a nightmare waking from any sleep, from any Warden, deals double (the hit that wakes
# it counts; within 2 s of waking; once per sleep).
func damage_multiplier(enemy, source, tag: StringName) -> float:
	if not rule(RUDE_AWAKENING) or not (source is Tower) or tag != &"":
		return 1.0
	var asleep: bool = enemy.statuses.is_asleep()
	if not asleep and now() - float(enemy.get_meta(WOKE_META, -INF)) > RUDE_WINDOW:
		return 1.0
	var sleep := int(enemy.get_meta(SLEEP_META, 0)) + (1 if asleep and not enemy.get_meta(ASLEEP_META, false) else 0)
	if int(enemy.get_meta(RUDE_META, -1)) == sleep:
		return 1.0
	# One doubled waking hit per bell a second (the nearest bell answers for it), so it grows with the cards, not
	# with how many cheap bells stand on the map
	var bell = null
	var best := INF
	for other in bells():
		var d: float = other.global_position.distance_squared_to(enemy.global_position)
		if d < best:
			best = d
			bell = other
	if bell == null or now() < float(bell.get_meta(RUDE_NEXT_META, -INF)):
		return 1.0
	bell.set_meta(RUDE_NEXT_META, now() + 1.0)
	enemy.set_meta(RUDE_META, sleep)
	return RUDE_MULTIPLIER

# --- Drawing: the hanging notes ---------------------------------------------------------------------------------------------

func _draw() -> void:
	for note in _notes:
		draw_circle(note.at, NOTE_CELLS * cell(), Color(Palette.BLOSSOM, 0.25))
		draw_arc(note.at, NOTE_CELLS * cell(), 0.0, TAU, 24, Color(Palette.BLOSSOM, 0.8), 2.0)
