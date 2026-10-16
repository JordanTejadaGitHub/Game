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
const REFRAIN_EVERY := 4.0  # …each Warden once per this long (a bell makes a nightmare Drowsy about every 2 s)
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
const BEAT_EVERY := 3.0  # On the Beat: each Warden once every 3 s, and never more often than every 2 of its own attacks…
const BEAT_HALFWAY := 0.25  # …and only with at most this share of its wait left (council 2026-10-15: slow Wardens never double)
const BEAT_META := &"kt_beat_next"  # On a Warden
const BEAT_FRAME_META := &"kt_beat_frame"  # On a bell: the frame it last set the beat
const RUDE_NEXT_META := &"kt_rude_next"  # On a bell: Rude Awakening, one doubled waking hit per bell a second

# Lent and class, 2026-10-14 (lent_noplace_dewdrop_bellflower.md, expand_dewdrop_bellflower.md, dream_council_review.md 26)
const HUM_ALONG := &"hum_along"  # Lent (the old Join In's slot): other Wardens touching a bell add 1 Drowsy with a hit
const HUM_EVERY := 2.0  # …each Warden once every 2 s
const RINGING_EARS := &"ringing_ears"
const EARS_CROWD := 3  # Ringing Ears: a bell's attack on this many nightmares or more adds 1 Drowsy to each…
const EARS_EVERY := 2.0  # …once every 2 s per bell
const SECOND_VERSE := &"second_verse"
const CLASHING_NOTES := &"clashing_notes"
const CLASH_EVERY := 8.0  # Clashing Notes and Knell: each nightmare once every 8 s (fix 9)
const KNELL_EVERY := 8.0
const WAKE_HIT_WINDOW := 1.0  # Sleep No More: the first hit within 1 s of waking
const BELL_TO_BELL := &"bell_to_bell"  # Class: walking into another bell's range fills pips back up to 2
const HUM_META := &"kt_hum_next"  # On a Warden
const EARS_META := &"kt_ears_next"  # On a bell
const DROWSED_META := &"kt_drowsed"  # On a nightmare: a bell has made it Drowsy before (Nod Off: the first time)
const LAST_OTHER_META := &"kt_last_other"  # On a nightmare: [status, stacks] the last application from another family's Warden
const VERSE_META := &"kt_verse"  # On a nightmare: {bell id: true} Second Verse paid
const B2B_META := &"kt_b2b"  # On a nightmare: {bell id: true} Bell to Bell paid
const INSIDE_META := &"kt_inside"  # On a nightmare: {bell id: true} the bells whose range it is in (Second Verse, Bell to Bell)
const KNELL_NEXT_META := &"kt_knell_next"  # On a nightmare
const CLASH_NEXT_META := &"kt_clash_next"  # On a nightmare
const HELD_SEEN_META := &"kt_held"  # On a nightmare: held at the last poll
const FREED_META := &"kt_freed"  # On a nightmare: when its Hold ended
const HOLD_COUNT_META := &"kt_holds"  # On a nightmare: its Hold count
const RUDE_HOLD_META := &"kt_rude_hold"  # On a nightmare: the Hold Rude Awakening paid for
const LAST_RINGER_META := &"kt_last_ringer"  # On a nightmare: the bell that last rang it (Bell to Bell)
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

# Trait rework (owner 2026-10-15, trait_lent_proposal.js): the lent cards make things happen again, in rhythm, for every
# family, bells included ("with its own family"). A repeat is damage only (CLASS_TAGS: it never sets a card off again).
const IN_TIME := &"in_time"
const IN_TIME_EVERY := 5  # In Time: every 5th hit a Warden touching a bell (or a bell) lands on one nightmare… (4th until the council's 2026-10-15 review)
const IN_TIME_DELAY := 0.25  # …lands again this long after
const IN_TIME_META := &"kt_in_time"  # On a nightmare: {Warden id: hits counted}
const IN_TIME_FRAME_META := &"kt_in_time_frame"  # On a Warden: the frame its last hit was counted (an area attack counts once)
const ENCORE := &"curtain_call"  # Curtain Call ("Encore" was taken: Echo Hollow's entwined card)
const ENCORE_EVERY := 3.0  # Encore: a Warden touching a bell (or a bell) that dispels a nightmare attacks again at once, once in 3 s
const ENCORE_META := &"kt_encore_next"  # On a Warden
const REPRISE := &"reprise"
const REPRISE_DELAY := 1.0  # Reprise: a Reaction in a bell's range plays again this long after…
const REPRISE_SHARE := 0.5  # …at half…
const REPRISE_EVERY := 8.0  # …each nightmare once in 8 s
const REPRISE_META := &"kt_reprise_next"  # On a nightmare
const DA_CAPO := &"da_capo"
const DA_CAPO_SHARE := 0.5  # Da Capo: a hit that happens again happens a third time, at half…
const DA_CAPO_EVERY := 4.0  # …each Warden once in 4 s
const DA_CAPO_DELAY := 0.25
const DA_CAPO_META := &"kt_da_capo_next"  # On a Warden
const RUDE_WARDENS := 3  # Rude Awakening: waking or let go, the last hit from up to this many Wardens lands again…
const RUDE_RECENT := 3.0  # …hits from the last 3 s only; one replay per bell a second (the nearest bell answers)
const LAST_HITS_META := &"kt_last_hits"  # On a nightmare: {Warden id: [WeakRef, base, time]}
const BELL_HIT_META := &"kt_bell_hit"  # On a nightmare: {bell id: true}: that bell has hit it (Second Verse)
var _later: Array = []  # Repeats waiting: [{at, tower: WeakRef, enemy: WeakRef, amount, tag, again: bool}]

var _reach := {}  # Bell instance id -> {route index: true}
var _carry := {}  # Bell instance id -> Array of route indices past its reach (Sound Carries)
var _exit := {}  # Bell instance id -> the last route index inside its reach
var _notes: Array = []  # Hanging notes: [{at: Vector2, until, amount, bell: WeakRef, struck: {id: true}}]
var tolls := 0  # This run (tests and the owner's eye)
var _ears := {}  # Ringing Ears: bell id -> {frame, bell: WeakRef, hits: Array of WeakRef}: one attack's hits, next frame

func _family() -> String:
	return FAMILY

func _line() -> String:
	return LINE

# Lent cards never give the Calling's setup (owner 2026-10-14, dream_council_review.md 25-26): the ring count, pips and
# Tolls are the first pick's only (place_on). The lent cards work from bells, where Wardens stand, their attacks and
# Drowsy; none counts rings, fills pips or reads a Toll.
func _lent_rules() -> Array:
	return [ON_THE_BEAT, IN_TIME, NOD_OFF, REFRAIN, SECOND_VERSE, KNELL, ENCORE, REPRISE, RUDE_AWAKENING, DA_CAPO,
		HUM_ALONG, RINGING_EARS, SLEEP_NO_MORE, CLASHING_NOTES]  # (The last four: retired 2026-10-15; old saves keep them)

# Cards retired or moved to class-only that counted rings when a later owner could hold them: an old save holding one
# keeps the Tolls on Continue.
func _legacy_rules() -> Array:
	return [JOIN_IN, SOUND_CARRIES, STRUCK_BELL, CHORUS]

func tolls_on() -> bool:
	return place_on()

func _start_pips() -> int:
	return PIPS_FILLED if class_on() else 0

func _ready() -> void:
	super._ready()
	add_to_group(GROUP)
	_pip_layer = Node2D.new()
	_pip_layer.name = "TollPips"
	_pip_layer.z_index = PIP_Z  # Over the nightmares (this node lies with the ground)
	_pip_layer.draw.connect(_draw_pips)
	add_child(_pip_layer)

# The Toll count over each nightmare (council 2026-10-13: "a player won't understand rules they can't see"): 4 small
# pips above it, the filled ones gold. Shown only while Tolls are on and the nightmare has started counting.
const PIP_Z := 8
const PIP_OFFSET := Vector2(0.0, -44.0)  # Above the health bar
const PIP_GAP := 6.0
const PIP_RADIUS := 2.0
var _pip_layer: Node2D
var _pips_shown := false

func _process(delta: float) -> void:
	super._process(delta)
	if not _ears.is_empty():
		_ears_flush()
	if _pip_layer != null and (tolls_on() or _pips_shown):
		_pips_shown = tolls_on()
		_pip_layer.queue_redraw()  # Only while Tolls are on (and once more to clear them)

func _draw_pips() -> void:
	if dream_state == null or not tolls_on():
		return
	var start := _start_pips()
	for enemy in enemies():
		if not enemy.has_meta(PIPS_META) and start <= 0:
			continue
		# Shown from the start (owner 2026-10-15: "feels like the pip starts at 3"): the 2 filled ones were only drawn
		# after the first ring, which had already made them 3
		var filled := int(enemy.get_meta(PIPS_META, start))
		var at: Vector2 = enemy.global_position + PIP_OFFSET - Vector2(PIP_GAP * (TOLL_EVERY - 1) / 2.0, 0.0)
		for k in TOLL_EVERY:
			var spot := at + Vector2(PIP_GAP * k, 0.0)
			if k < filled:
				_pip_layer.draw_circle(spot, PIP_RADIUS, Palette.GOLD)
			else:
				_pip_layer.draw_circle(spot, PIP_RADIUS, Color(Palette.MOONLIGHT, 0.35))

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
	if not counted:
		enemy.set_meta(LAST_RINGER_META, bell.get_instance_id())  # Bell to Bell: "another bell" is not the one that last rang it
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
		if rule(HANGING_NOTE) and pulsing:
			_hang_note(bell, enemy.global_position, landing)
	# (Nod Off, Refrain and Knell no longer read Tolls: lent cards trigger from a bell's Drowsy, 2026-10-14.)
	if not living(enemy):
		return
	if rule(CHORUS):
		_chorus(enemy, bell)  # (Retired; an old save keeps it)

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

# Knell (lent): a bell's hit on a Drowsy nightmare sets off one status from another family's Warden, the fullest first:
# it pays out at once and is used up. Never Rooted, Exposed or Drowsy. True when one went off.
func _knell(enemy, _bell) -> bool:
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
	return chosen != &""

# Another family's status is on it (Knell and Clashing Notes need one).
func _carries_other(enemy) -> bool:
	var statuses: EnemyStatuses = enemy.statuses
	for id in statuses.active_ids():
		if id != EnemyStatuses.DROWSY and id != EnemyStatuses.HELD and is_other_family(statuses.source(id)):
			return true
	return false

# Hum Along (lent): a hit from another Warden touching a bell that makes Drowsy adds 1 Drowsy, the bell's application
# (not native: it never counts as a bell making it Drowsy, so it cannot set off Nod Off or Refrain or loop).
func _hum_along(source, enemy) -> void:
	var bell = null
	for other in bells():
		if status_of(other) == EnemyStatuses.DROWSY and touching(other, source) and (bell == null or second_of(other) > second_of(bell)):
			bell = other
	if bell == null:
		return
	source.set_meta(HUM_META, now() + HUM_EVERY)
	_line_fx(source.global_position, enemy.global_position, 1.5, Palette.BLOSSOM)
	bell._apply_one_status(enemy, EnemyStatuses.DROWSY, 1, bell.get_damage(), false)

# Ringing Ears (lent): a bell's attack's hits, gathered by frame; the next frame, an attack on 3 or more nightmares adds
# 1 Drowsy to each (the bell's own application), once every 2 s per bell. Any song form that attacks counts.
func _ears_note(bell, enemy) -> void:
	var id: int = bell.get_instance_id()
	var frame := Engine.get_process_frames()
	var entry: Dictionary = _ears.get(id, {})
	if entry.is_empty() or int(entry.frame) != frame:
		if not entry.is_empty() or now() < float(bell.get_meta(EARS_META, -INF)):
			return
		entry = {"frame": frame, "bell": weakref(bell), "hits": []}
		_ears[id] = entry
	entry.hits.append(weakref(enemy))

func _ears_flush() -> void:
	var frame := Engine.get_process_frames()
	for id in _ears.keys():
		var entry: Dictionary = _ears[id]
		if int(entry.frame) >= frame:
			continue
		_ears.erase(id)
		var bell = entry.bell.get_ref()
		if not is_instance_valid(bell) or entry.hits.size() < EARS_CROWD:
			continue
		bell.set_meta(EARS_META, now() + EARS_EVERY)
		for ref in entry.hits:
			var enemy = ref.get_ref()
			if living(enemy):
				bell._apply_one_status(enemy, EnemyStatuses.DROWSY, 1, bell.get_damage(), true)

# A Warden's own accepted status application (DreamState.class_status): a bell making a nightmare Drowsy (Nod Off,
# Refrain), another family's status (Second Verse remembers the last one).
func status_applied(tower, enemy, status: StringName, stacks: int) -> void:
	if not living(enemy):
		return
	if is_own(tower) and status == EnemyStatuses.DROWSY:
		if rule(NOD_OFF) and not enemy.has_meta(DROWSED_META):
			# Nod Off: the first time a bell makes it Drowsy, it naps 1 s (one sleeper for each bell; never bosses)
			var sleeper = tower.get_meta(SLEEPER_META).get_ref() if tower.has_meta(SLEEPER_META) else null
			if not (living(sleeper) and sleeper.statuses.is_asleep()) and nap(enemy):
				tower.set_meta(SLEEPER_META, weakref(enemy))
		enemy.set_meta(DROWSED_META, true)
	elif rule(SECOND_VERSE) and is_other_family(tower) and status != EnemyStatuses.DROWSY and status != EnemyStatuses.HELD:
		enemy.set_meta(LAST_OTHER_META, [status, stacks])

# --- Damage events ------------------------------------------------------------------------------------------------------

# Reprise listens to Reactions, which every other class card ignores (class_kit filters them out).
func _on_damage(event) -> void:
	if dream_state != null and rule(REPRISE) and is_instance_valid(event.enemy) and is_reaction_burst(event):
		_reprise(event)
	super._on_damage(event)

func on_damage(event, source, enemy, is_hit: bool, dispel: bool, tagged: bool) -> void:
	if dispel and is_hit and rule(ENCORE):
		_encore(source)  # A hit's dispel only (a status tick's never counts)
	if tagged or source == null or not is_hit or not living(enemy):
		return
	if rule(SLEEP_NO_MORE):
		_sleep_no_more(event, source, enemy)  # (Retired 2026-10-15; an old save keeps it)
	if rule(RUDE_AWAKENING):
		_note_last_hit(source, enemy, event.base)
	if rule(IN_TIME):
		_in_time(source, enemy, event.base)
	if rule(REFRAIN):
		_refrain(source, enemy, event.base)
	if not living(enemy):
		return
	if is_own(source):
		if rule(SECOND_VERSE):
			var hit: Dictionary = enemy.get_meta(BELL_HIT_META, {})
			hit[source.get_instance_id()] = true
			enemy.set_meta(BELL_HIT_META, hit)
		if rule(ON_THE_BEAT) and int(source.get_meta(BEAT_FRAME_META, -1)) != Engine.get_process_frames():
			source.set_meta(BEAT_FRAME_META, Engine.get_process_frames())
			_beat(source)
		if rule(RINGING_EARS):
			_ears_note(source, enemy)
		# Knell (trait rework; no longer needs Drowsy): a bell's hit sets off one status another family put on it. Each
		# nightmare once every 8 s
		if rule(KNELL) and _carries_other(enemy) and now() >= float(enemy.get_meta(KNELL_NEXT_META, -INF)) and _knell(enemy, source):
			enemy.set_meta(KNELL_NEXT_META, now() + KNELL_EVERY)
		if rule(CLASHING_NOTES) and living(enemy) and enemy.statuses.has(EnemyStatuses.DROWSY) and _carries_other(enemy) \
				and now() >= float(enemy.get_meta(CLASH_NEXT_META, -INF)):
			enemy.set_meta(CLASH_NEXT_META, now() + CLASH_EVERY)  # (Retired 2026-10-15; an old save keeps it)
			Reactions.check_at_half(enemy, source)
		if not living(enemy) or not tolls_on():
			return
		if is_pulsing(source) and int(source.get_meta(PULSE_META, -1)) != Engine.get_process_frames():
			source.set_meta(PULSE_META, Engine.get_process_frames())
			if rule(SOUND_CARRIES):
				_carry_ring(source, event.base)
		ring(enemy, source, event.base)
		return
	# Another Warden's hit
	if not is_other(source):
		return
	if rule(HUM_ALONG) and now() >= float(source.get_meta(HUM_META, -INF)):
		_hum_along(source, enemy)
	if not tolls_on():
		return
	var counted = null
	for bell in bells():
		if not _in_reach(bell, enemy):
			continue
		if rule(JOIN_IN) and touching(source, bell):
			counted = bell  # Join In (class-only since 2026-10-14): any other Warden touching a bell counts as its ring
			break
		if rule(STRUCK_BELL) and is_other_family(source) and near(source.global_position, bell.global_position):
			counted = bell  # Struck Bell (retired): another family's Warden near a bell
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
		if tower == bell or not tower.tower_data.can_attack or not touching(tower, bell):  # Other bells too (own family, 2026-10-15)
			continue
		if now() < float(tower.get_meta(BEAT_META, -INF)):
			continue
		var period: float = 1.0 / maxf(tower.get_attacks_per_second(), 0.01)
		if tower._cooldown > period * BEAT_HALFWAY:
			continue  # Not halfway yet: a slow Warden is never doubled
		tower.set_meta(BEAT_META, now() + maxf(BEAT_EVERY, 2.0 * period))
		tower._cooldown = 0.0
		_line_fx(bell.global_position, tower.global_position, 1.5, Palette.BLOSSOM)

# --- Again, in rhythm (trait rework 2026-10-15) -----------------------------------------------------------------------

# Whether `tower` is a bell or touches one (In Time, Encore).
func _by_a_bell(tower) -> bool:
	return is_own(tower) or bells().any(func(b) -> bool: return touching(b, tower))

# A hit lands again now (In Time's delayed repeat, Refrain, Rude Awakening): damage only. Da Capo: a third time, at half.
func _again(tower, enemy, amount: float, tag: StringName) -> void:
	if not is_instance_valid(tower) or not living(enemy):
		return
	_line_fx(tower.global_position, enemy.global_position, 1.5, Palette.BLOSSOM)
	strike(tower, enemy, amount, tag)
	if rule(DA_CAPO) and living(enemy) and now() >= float(tower.get_meta(DA_CAPO_META, -INF)):
		tower.set_meta(DA_CAPO_META, now() + DA_CAPO_EVERY)
		_later.append({"at": now() + DA_CAPO_DELAY, "tower": weakref(tower), "enemy": weakref(enemy),
			"amount": amount * DA_CAPO_SHARE, "tag": &"da_capo", "again": false})

func _tick_later() -> void:
	for i in range(_later.size() - 1, -1, -1):
		var row: Dictionary = _later[i]
		if now() < float(row.at):
			continue
		_later.remove_at(i)
		var tower = row.tower.get_ref()
		var enemy = row.enemy.get_ref()
		if bool(row.again):
			_again(tower, enemy, float(row.amount), row.tag)
		elif is_instance_valid(tower) and living(enemy):
			strike(tower, enemy, float(row.amount), row.tag)

# In Time: every 4th hit a Warden touching a bell (or a bell) lands on one nightmare lands again a moment later. Counted
# for each Warden and nightmare; an area attack counts once. Sprouts count.
func _in_time(source, enemy, base: float) -> void:
	if not source.tower_data.can_attack or not _by_a_bell(source):
		return
	if int(source.get_meta(IN_TIME_FRAME_META, -1)) == Engine.get_process_frames():
		return
	source.set_meta(IN_TIME_FRAME_META, Engine.get_process_frames())
	var counts: Dictionary = enemy.get_meta(IN_TIME_META, {})
	var n := int(counts.get(source.get_instance_id(), 0)) + 1
	counts[source.get_instance_id()] = n % IN_TIME_EVERY
	enemy.set_meta(IN_TIME_META, counts)
	if n >= IN_TIME_EVERY:
		_later.append({"at": now() + IN_TIME_DELAY, "tower": weakref(source), "enemy": weakref(enemy), "amount": base,
			"tag": &"in_time", "again": true})

# Refrain: after a bell hits a nightmare, the next hit on it from another Warden (another bell too; Sprouts count) within
# 2 s lands twice. Each Warden once every 4 s.
func _refrain(source, enemy, base: float) -> void:
	var pending: Array = enemy.get_meta(REFRAIN_META, []) if enemy.get_meta(REFRAIN_META, null) is Array else []
	if not pending.is_empty() and now() < float(pending[0]) and int(pending[1]) != source.get_instance_id() \
			and now() >= float(source.get_meta(REFRAIN_NEXT_META, -INF)):
		enemy.remove_meta(REFRAIN_META)
		source.set_meta(REFRAIN_NEXT_META, now() + REFRAIN_EVERY)
		_again(source, enemy, base, &"refrain")
	if is_own(source) and living(enemy):
		enemy.set_meta(REFRAIN_META, [now() + REFRAIN_SECONDS, source.get_instance_id()])

# Encore: a Warden touching a bell (or a bell) that dispels a nightmare attacks again at once. Each Warden once in 3 s.
func _encore(source) -> void:
	if not source.tower_data.can_attack or now() < float(source.get_meta(ENCORE_META, -INF)) or not _by_a_bell(source):
		return
	source.set_meta(ENCORE_META, now() + maxf(ENCORE_EVERY, 2.0 / maxf(source.get_attacks_per_second(), 0.01)))  # Never doubles a slow Warden
	source._cooldown = 0.0
	Reactions._effect(&"landing_dust", source.global_position, self, 0.5)

# Reprise: a Reaction on a nightmare in a bell's range plays again 1 s later, at half. Each nightmare once in 8 s; never an
# Echo Hollow echo (that is already a Reaction heard again).
func _reprise(event) -> void:
	var enemy = event.enemy
	if event.tag == &"echo" or event.tag == &"carried_storm" or not living(enemy) or event.base <= 0.0:
		return
	if now() < float(enemy.get_meta(REPRISE_META, -INF)):
		return
	var bell = null
	for other in bells():
		if other.global_position.distance_to(enemy.global_position) <= other.get_range_pixels():
			bell = other
			break
	if bell == null:
		return
	enemy.set_meta(REPRISE_META, now() + REPRISE_EVERY)
	var source = event.source if is_instance_valid(event.source) and event.source is Tower else bell
	_later.append({"at": now() + REPRISE_DELAY, "tower": weakref(source), "enemy": weakref(enemy),
		"amount": event.base * REPRISE_SHARE, "tag": &"reprise", "again": false})

# Rude Awakening: the last hit from each of the last 3 Wardens to hit it, remembered (before defences).
func _note_last_hit(source, enemy, base: float) -> void:
	var hits: Dictionary = enemy.get_meta(LAST_HITS_META, {})
	hits[source.get_instance_id()] = [weakref(source), base, now()]
	if hits.size() > RUDE_WARDENS:
		var oldest = null
		for id in hits:
			if oldest == null or float(hits[id][2]) < float(hits[oldest][2]):
				oldest = id
		hits.erase(oldest)
	enemy.set_meta(LAST_HITS_META, hits)

# Rude Awakening: it woke or was let go: those hits land again (once per sleep or Hold: on_poll sees the change once).
func _rude_awakening(enemy) -> void:
	var hits: Dictionary = enemy.get_meta(LAST_HITS_META, {})
	enemy.remove_meta(LAST_HITS_META)
	var bell = null
	var best := INF
	for other in bells():
		var d: float = other.global_position.distance_squared_to(enemy.global_position)
		if d < best:
			best = d
			bell = other
	if bell == null or now() < float(bell.get_meta(RUDE_NEXT_META, -INF)):
		return
	bell.set_meta(RUDE_NEXT_META, now() + 1.0)
	for id in hits:
		if now() - float(hits[id][2]) <= RUDE_RECENT:
			_again(hits[id][0].get_ref(), enemy, float(hits[id][1]), &"rude_replay")

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

# Sleep No More: the first hit within 1 s of a nightmare waking (any Warden's; the hit that wakes it counts) lands in
# full on every nightmare touching it too (up to 6; never more than one second of that Warden's damage). Once per sleep.
# (Fix 5, 2026-10-14: only a hit of a tenth of its health wakes a sleeper, so "the hit that wakes it" almost never came.)
func _sleep_no_more(event, source, enemy) -> void:
	if enemy.statuses.is_asleep():
		return
	var woke_now: bool = enemy.get_meta(ASLEEP_META, false)  # Asleep at the last poll, awake now: this hit woke it
	if not woke_now and now() - float(enemy.get_meta(WOKE_META, -INF)) > WAKE_HIT_WINDOW:
		return
	var sleep := int(enemy.get_meta(SLEEP_META, 0))
	if int(enemy.get_meta(BURST_META, -1)) == sleep:
		return
	enemy.set_meta(BURST_META, sleep)
	Reactions._effect(&"landing_dust", enemy.global_position, self, 1.0)
	for other in nightmares_touching(enemy, SLEEP_NO_MORE_OTHERS):
		strike(source, other, minf(event.base, second_of(source)), &"sleep_no_more", true)

# Bell to Bell (class): walking into another bell's range fills its pips back up to 2 (only raises; once for each bell).
func _bell_to_bell(enemy, bell) -> void:
	if int(enemy.get_meta(LAST_RINGER_META, -1)) == bell.get_instance_id():
		return
	var done: Dictionary = enemy.get_meta(B2B_META, {})
	if done.has(bell.get_instance_id()):
		return
	done[bell.get_instance_id()] = true
	enemy.set_meta(B2B_META, done)
	if int(enemy.get_meta(PIPS_META, 0)) < PIPS_FILLED:
		enemy.set_meta(PIPS_META, PIPS_FILLED)

# Second Verse (lent): a Drowsy nightmare leaving a bell's range gets the last status another family's Warden gave it
# again, the same stacks, as a quiet add (never starts one, never above the limit, Charged one short of a bolt). Once for
# each nightmare and bell.
func _second_verse(enemy, bell) -> void:
	if not enemy.get_meta(BELL_HIT_META, {}).has(bell.get_instance_id()) or not enemy.has_meta(LAST_OTHER_META):
		return  # (Trait rework 2026-10-15: that bell has hit it; it no longer needs Drowsy)
	var paid: Dictionary = enemy.get_meta(VERSE_META, {})
	if paid.has(bell.get_instance_id()):
		return
	var last: Array = enemy.get_meta(LAST_OTHER_META)
	if enemy.statuses.add_quiet(StringName(last[0]), int(last[1])) > 0:
		paid[bell.get_instance_id()] = true
		enemy.set_meta(VERSE_META, paid)
		_line_fx(bell.global_position, enemy.global_position, 1.5, Palette.BLOSSOM)

# --- The poll: sleepers, busy bells, Rounds, hanging notes -------------------------------------------------------------------

func on_poll() -> void:
	if not active():
		return
	var all := bells()
	var drift: int = dream_state.drift_director.drifts_started if dream_state.drift_director != null else 0
	var busy := {}
	var verse := rule(SECOND_VERSE)
	var bell_to_bell := tolls_on() and rule(BELL_TO_BELL)
	for enemy in enemies():
		var asleep: bool = enemy.statuses.is_asleep()
		if asleep and not enemy.get_meta(ASLEEP_META, false):
			enemy.set_meta(SLEEP_META, int(enemy.get_meta(SLEEP_META, 0)) + 1)
		elif not asleep and enemy.get_meta(ASLEEP_META, false):
			enemy.set_meta(WOKE_META, now())
			if rule(RUDE_AWAKENING) and living(enemy):
				_rude_awakening(enemy)
		enemy.set_meta(ASLEEP_META, asleep)
		var held: bool = enemy.statuses.is_held()  # Rude Awakening counts a Hold ending too (fix 5)
		if held and not enemy.get_meta(HELD_SEEN_META, false):
			enemy.set_meta(HOLD_COUNT_META, int(enemy.get_meta(HOLD_COUNT_META, 0)) + 1)
		elif not held and enemy.get_meta(HELD_SEEN_META, false):
			enemy.set_meta(FREED_META, now())
			if rule(RUDE_AWAKENING) and living(enemy):
				_rude_awakening(enemy)
		enemy.set_meta(HELD_SEEN_META, held)
		var inside: Dictionary = enemy.get_meta(INSIDE_META, {}) if verse or bell_to_bell else {}
		var now_inside := {}
		for bell in all:
			if _in_reach(bell, enemy):
				busy[bell.get_instance_id()] = true
				now_inside[bell.get_instance_id()] = true
				if bell_to_bell and not inside.has(bell.get_instance_id()):
					_bell_to_bell(enemy, bell)
			elif verse and inside.has(bell.get_instance_id()):
				_second_verse(enemy, bell)
		if verse or bell_to_bell:
			enemy.set_meta(INSIDE_META, now_inside)
		for bell in all:
			if _in_reach(bell, enemy):
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
	_tick_later()

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
	_later.clear()
	queue_redraw()

# --- What the other systems ask (through DreamState) --------------------------------------------------------------------

# Rude Awakening: the next hit on a nightmare waking from any sleep, or let go from a Hold, from any Warden, deals
# double (the hit that wakes it counts; within 2 s; once per sleep or Hold).
func damage_multiplier(enemy, source, tag: StringName) -> float:
	return 1.0  # (Trait rework 2026-10-15: Rude Awakening replays hits now, _rude_awakening; this was its doubled hit)

# --- Drawing: the hanging notes ---------------------------------------------------------------------------------------------

func _draw() -> void:
	for note in _notes:
		draw_circle(note.at, NOTE_CELLS * cell(), Color(Palette.BLOSSOM, 0.25))
		draw_arc(note.at, NOTE_CELLS * cell(), 0.0, TAU, 24, Color(Palette.BLOSSOM, 0.8), 2.0)
