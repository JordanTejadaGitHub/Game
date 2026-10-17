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
const KNELL_EVERY := 6.0  # Hard cards 2026-10-16 (was 8): each nightmare once every 6 s
const KNELL_REPEATS_MAX := 3  # Knell: a bell's hit lands again once per other-family status on the nightmare, up to 3 times…
const KNELL_REPEAT_GAP := 0.2  # …0.2 s apart…
const KNELL_REPEAT_SHARE := 1.0  # …each the whole hit (a shooting bell)…
const KNELL_PULSE_SHARE := 0.5  # …or half of it from a pulsing bell (it hits a crowd at once; TD)
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

# --- Calling evolutions (scripts/combat/calling_paths.gd; council calling_evolution_*.md, owner 2026-10-16) -----------
# Read with evo(id) (class_kit: only the Calling's own run has them, so they imply class_on() and Tolls). Every number is a
# paper starting value (Balancing). Each one shows itself on screen (a ring, a thread, a note, a dial, a flash) and credits
# its id (DreamState.note_card). Damage they deal reuses Bellflower tags already in class_kit.CLASS_TAGS, so nothing they
# deal sets a card or the Calling off again.
const EVO_CARRYING := &"kt_evo_carrying_tune"  # Spread
const TUNE_STEPS := CARRY_STEPS  # Carrying Tune: a ring carries this many steps down the path (a pulse: past its reach; a shot: past its target)…
const TUNE_SHARE := 0.5  # …at half; carried rings fill pips…
const TUNE_MAX := 4  # …a shot's carry reaches up to this many nightmares (a pulse's covers its stretch, as Sound Carries)
const TUNE_FRAME_META := &"kt_evo_tune_frame"  # On a bell: the frame its shot last carried (one carry per attack)
const EVO_HAND := &"kt_evo_hand_to_hand"
const HAND_PIPS := 2  # Hand to Hand: a new bell's first ring on a nightmare fills this many pips
const HAND_META := &"kt_evo_hand"  # On a nightmare: {bell id: true}: bells that took it hand to hand
const EVO_PEAL := &"kt_evo_peal"
const PEAL_STEPS := 4  # Peal: a Toll fills 1 pip on every nightmare within this many steps…
const PEAL_MAX := 8  # …up to this many, never the last pip (TD fix 2: only a real ring Tolls, so a pack can't Toll itself)
const EVO_NOTE := &"kt_evo_lingering_note"
const LINGER_SECONDS := 2.0  # Lingering Note: a Toll's note stays this long; each nightmare walking through rings once
const EVO_CHOIR := &"kt_evo_night_choir"
const CHOIR_WARDENS := 3  # Night Choir: up to this many Wardens touching the note, strongest first…
const CHOIR_SHARE := 0.5  # …land their last hit (stored before defences) again at half…
const CHOIR_CAP_SECONDS := 1.0  # …never more than this many seconds of that Warden's damage
const EVO_STEADY := &"kt_evo_steady_beat"  # Focus
const STEADY_BELLS := 2  # Steady Beat: in reach of this many bells (read at its first ring)…
const STEADY_PIPS := 3  # …a nightmare starts with this many pips…
const STEADY_SHARE := 1.0  # …and its Tolls there land in full
const EVO_CRESCENDO := &"kt_evo_crescendo"
const CRESC_STEP := 0.25  # Crescendo: each Toll on a nightmare makes its next one this much stronger…
const CRESC_MAX := 2.0  # …up to double
const CRESC_GLOW_STEPS := 4  # (CRESC_MAX - 1) / CRESC_STEP: the pips are brightest from here
const CRESC_META := &"kt_evo_cresc"  # On a nightmare: its Tolls so far
const EVO_MIDNIGHT := &"kt_evo_midnight_bell"
const MIDNIGHT_RINGS := 12  # Midnight Bell: the 12th ring on a nightmare (once each)…
const MIDNIGHT_BOSS := 0.5  # …bosses take this share
const MIDNIGHT_SECONDS := 1.5  # The clock face shows this long
const RINGS_META := &"kt_evo_rings"  # On a nightmare: its rings so far (a dial over the pips counts them)
const MIDNIGHT_META := &"kt_evo_midnight"  # On a nightmare: its Midnight Toll has rung
const EVO_HUSH := &"kt_evo_hush_a_bye"
const HUSH_DROWSY := 2  # Hush-a-bye: a Toll adds this much Drowsy (the bell's application, never native)…
const HUSH_TOLLS := 3  # …this many Tolls…
const HUSH_WINDOW := 6.0  # …within this long and it naps (class_kit.nap: 1 s, never bosses or a sleeper)…
const HUSH_EVERY := 8.0  # …each nightmare once in this long
const HUSH_META := &"kt_evo_hush"  # On a nightmare: [its recent Toll times]
const HUSH_NEXT_META := &"kt_evo_hush_next"
const HUSHED_META := &"kt_evo_hushed"  # On a nightmare: asleep from Hush-a-bye (Sleeping Hall reads its waking)
const EVO_HALL := &"kt_evo_sleeping_hall"
const HALL_WINDOW := 3.0  # Sleeping Hall (TD SLEEP_WINDOW): within this long of a Hush-a-bye nap ending, its next Toll…
const HALL_OTHERS := 4  # …also lands on up to this many nightmares touching it…
const HALL_SHARE := 0.5  # …at half
const HALL_META := &"kt_evo_hall"  # On a nightmare: until when its next Toll spreads
const EVO_ACCOMP := &"kt_evo_accompaniment"  # Support
const ACCOMP_EVERY := 1.0  # Accompaniment: another Warden touching a bell fills a pip once a second (a Sprout: every hit)
const EVO_COUNTER := &"kt_evo_counterpoint"
const COUNTER_CELLS := 4.0  # Counterpoint: the nearest bell within this many cells answers another Warden's Toll…
const COUNTER_EVERY := 1.0  # …each bell once in this long (its ring is its free hit, and fills a pip)
const COUNTER_META := &"kt_evo_counter_next"  # On a bell
const EVO_SYMPHONY := &"kt_evo_symphony"
const SYMPHONY_WARDENS := 4  # Symphony: a Toll whose pips this many different Wardens filled…
const SYMPHONY_SHARE := 0.5  # …lands each one's last hit again at half (never more than a second of its damage)…
const SYMPHONY_EVERY := 6.0  # …each nightmare once in this long
const SYMPHONY_META := &"kt_evo_symphony_next"
const EVO_CHIME := &"kt_evo_chime_of_many"
# Chime of Many (owner 2026-10-17: Bellflower's own trait, Repeats; was +1 stack): a Toll repeats the nightmare's last
# status hit (its Warden's status and stacks, a real application from that Warden: caps and immunity apply) on up to
# CHIME_OTHERS nightmares touching it, each once per Toll. Never Drowsy or Rooted (control stays bounded).
const CHIME_OTHERS := 4
const CHIME_META := &"kt_evo_chime_last"  # On a nightmare: [WeakRef Warden, status, stacks] its last accepted status hit
const EVO_CHORD := &"kt_evo_last_chord"
const CHORD_STATUSES := 3  # Last Chord: a Toll on a nightmare carrying this many statuses sets off what's halfway there…
const CHORD_EVERY := 8.0  # …each nightmare once in this long (spent only when one goes off)
const CHORD_META := &"kt_evo_chord_next"
const FILLERS_META := &"kt_evo_fillers"  # On a nightmare (Accompaniment on): [[Warden id (0 = none), another Warden's: bool]] per pip
var _last_hit_of := {}  # Warden id -> its last hit, before defences (Night Choir, Symphony)
var _clocks: Array = []  # Midnight Bell's clock faces: [{enemy: WeakRef, at, until}]
var _overlap := {}  # Steady Beat: route index -> true where 2 or more bells reach (drawn as a gold band)

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

# The pips a nightmare starts with at its first ring (Steady Beat: 3 where 2 or more bells reach).
func _start_for(enemy) -> int:
	if evo(EVO_STEADY) and _bells_reaching(enemy) >= STEADY_BELLS:
		return STEADY_PIPS
	return _start_pips()

func _bells_reaching(enemy) -> int:
	var count := 0
	for bell in bells():
		if _in_reach(bell, enemy):
			count += 1
			if count >= STEADY_BELLS:
				break
	return count

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
const RING_CORE := 1.5  # Rings over the nightmare: the clapper dot,
const RING_FIRST := 4.0  # the innermost ring's radius,
const RING_STEP := 3.0  # the gap between rings,
const RING_WIDTH := 1.5  # a lit ring's width,
const RING_TRIM := 0.45  # and how much of each upper half-arc is cut at the ends (radians)
const TOLL_FLASH := 0.4  # A Toll: the rings flash and burst outward for this long (owner 2026-10-17: "the toll should have a visual effect when filled")
const TOLL_FLASH_GROW := 1.6  # How far the rings spread by the end of it (x their radius)
var _toll_flashes: Array = []  # [{enemy: WeakRef, at: Vector2, start: float}]
var _pip_layer: Node2D
var _pips_shown := false

func _process(delta: float) -> void:
	super._process(delta)
	if not _ears.is_empty():
		_ears_flush()
	if dream_state != null and not _clocks.is_empty():
		_clocks = _clocks.filter(func(c) -> bool: return now() < float(c.until))
	if dream_state != null and not _toll_flashes.is_empty():
		_toll_flashes = _toll_flashes.filter(func(f) -> bool: return now() - float(f.start) < TOLL_FLASH)
	if _pip_layer != null and (tolls_on() or _pips_shown):
		_pips_shown = tolls_on()
		_pip_layer.queue_redraw()  # Only while Tolls are on (and once more to clear them)

func _draw_pips() -> void:
	if dream_state == null or not tolls_on():
		return
	var start := _start_pips()
	var colours := evo(EVO_ACCOMP)  # Accompaniment: pips another Warden filled are pink
	var cresc := evo(EVO_CRESCENDO)  # Crescendo: the pips grow bigger and brighter
	var midnight := evo(EVO_MIDNIGHT)  # Midnight Bell: a dial over the pips counts to 12
	for enemy in enemies():
		if not enemy.has_meta(PIPS_META) and start <= 0:
			continue
		# Shown from the start (owner 2026-10-15: "feels like the pip starts at 3"): the 2 filled ones were only drawn
		# after the first ring, which had already made them 3
		var filled := int(enemy.get_meta(PIPS_META, start))
		# Rings, not dots (owner 2026-10-17: "make it seem like rings filling"): TOLL_EVERY sound-wave arcs rising over
		# the nightmare, lit from the inside out; the outermost is the Toll.
		var at: Vector2 = enemy.global_position + PIP_OFFSET
		var roster: Array = enemy.get_meta(FILLERS_META, []) if colours else []
		var swell := mini(int(enemy.get_meta(CRESC_META, 0)), CRESC_GLOW_STEPS) if cresc else 0
		_pip_layer.draw_circle(at, RING_CORE, Color(Palette.MOONLIGHT, 0.6))  # The clapper the rings spread from
		for k in TOLL_EVERY:
			var radius := RING_FIRST + RING_STEP * k
			if k < filled:
				var colour: Color = Palette.GOLD
				if k < roster.size() and bool(roster[k][1]):
					colour = Palette.BLOSSOM
				elif swell >= CRESC_GLOW_STEPS:
					colour = Palette.GLOW
				_pip_layer.draw_arc(at, radius, PI + RING_TRIM, TAU - RING_TRIM, 12, colour, RING_WIDTH + 0.25 * swell, true)
			else:
				_pip_layer.draw_arc(at, radius, PI + RING_TRIM, TAU - RING_TRIM, 12, Color(Palette.MOONLIGHT, 0.3), 1.0, true)
		if midnight and enemy.has_meta(RINGS_META) and not enemy.has_meta(MIDNIGHT_META):
			var share := clampf(float(enemy.get_meta(RINGS_META)) / MIDNIGHT_RINGS, 0.0, 1.0)
			var dial: Vector2 = enemy.global_position + PIP_OFFSET + Vector2(0.0, -18.0)  # Above the outermost ring
			_pip_layer.draw_arc(dial, 4.0, -PI / 2.0, -PI / 2.0 + TAU * share, 16, Color(Palette.MOONLIGHT, 0.7), 1.0)
	for f in _toll_flashes:  # A Toll: the four rings light gold and burst outward, fading
		var age := clampf((now() - float(f.start)) / TOLL_FLASH, 0.0, 1.0)
		var who = f.enemy.get_ref()
		var centre: Vector2 = (who.global_position if is_instance_valid(who) else f.at) + PIP_OFFSET
		var grow := 1.0 + (TOLL_FLASH_GROW - 1.0) * age
		var colour := Color(Palette.GLOW, 1.0 - age)
		for k in TOLL_EVERY:
			_pip_layer.draw_arc(centre, (RING_FIRST + RING_STEP * k) * grow, PI + RING_TRIM, TAU - RING_TRIM, 12, colour, RING_WIDTH + 1.0, true)
	for c in _clocks:  # Midnight Bell: a clock face at midnight over the nightmare
		var who = c.enemy.get_ref()
		var centre: Vector2 = (who.global_position if is_instance_valid(who) else c.at) + PIP_OFFSET + Vector2(0.0, -24.0)
		_pip_layer.draw_circle(centre, 8.0, Color(Palette.NIGHT, 0.7))
		_pip_layer.draw_arc(centre, 8.0, 0.0, TAU, 24, Palette.GOLD, 1.5)
		_pip_layer.draw_line(centre, centre + Vector2(0.0, -6.0), Palette.HEARTLIGHT, 1.5)
		_pip_layer.draw_line(centre, centre + Vector2(0.0, -4.0), Palette.GOLD, 2.0)

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
	# Steady Beat: the stretches 2 or more bells reach, drawn as a gold band on the path (_draw_overlap)
	_overlap.clear()
	if evo(EVO_STEADY):
		var count := {}
		for id in _reach:
			for i in _reach[id]:
				count[i] = int(count.get(i, 0)) + 1
		for i in count:
			if int(count[i]) >= STEADY_BELLS:
				_overlap[i] = true
	queue_redraw()

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
# `filler`: Accompaniment's Warden whose hit this ring is (its Toll repeats that Warden's hit and status), or null.
func ring(enemy, bell, amount: float, counted: bool = false, filler = null) -> void:
	if not living(enemy) or not is_instance_valid(bell) or not tolls_on():
		return
	var fresh: bool = not enemy.has_meta(PIPS_META)
	var pips := _start_for(enemy) if fresh else int(enemy.get_meta(PIPS_META))
	if fresh and pips > _start_pips():
		Reactions._effect(&"toll_ring", enemy.global_position, self, 0.5)  # Steady Beat: it starts a pip ahead
	var handed_from := -1  # Hand to Hand: the bell that rang it before this one (-1: none)
	if not counted:
		if evo(EVO_HAND):
			handed_from = _handed_from(enemy, bell)
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
		var add := 1
		if handed_from != -1:
			add = HAND_PIPS
			_hand_to_hand(enemy, bell, handed_from)
		pips += add
		if evo(EVO_ACCOMP):
			_fill(enemy, pips - add, add, filler if is_instance_valid(filler) else bell, is_instance_valid(filler))
		if evo(EVO_MIDNIGHT) and _count_rings(enemy, add):
			_midnight(enemy)
			if not living(enemy):
				return
	enemy.set_meta(RING_META, now())
	if pips < TOLL_EVERY and not answered and not overture:
		enemy.set_meta(PIPS_META, pips)
		return
	if now() < float(enemy.get_meta(TOLL_META, -INF)):
		enemy.set_meta(PIPS_META, mini(pips, TOLL_EVERY - 1))  # It waits a pip short: one Toll a second
		return
	enemy.set_meta(PIPS_META, 0)
	enemy.set_meta(TOLL_META, now() + TOLL_WAIT)
	_toll(enemy, bell, amount, overture, counted, filler)

func _reach_width(bell) -> int:
	return _reach.get(bell.get_instance_id(), {}).size()

func _toll(enemy, bell, amount: float, overture: bool, counted: bool = false, filler = null) -> void:
	tolls += 1
	var on := active()
	var pulsing := is_pulsing(bell)
	var share := TOLL_SHARE
	if on and pulsing and not overture and rule(RISING_SONG):
		share = minf(TOLL_SHARE + RISING_STEP * int(bell.get_meta(RISING_META, 0)), RISING_MAX)  # Overture's Tolls always land at half
	var at: Vector2 = enemy.global_position
	var evolved: bool = class_on() and not dream_state.calling_path.is_empty()
	var roster: Array = []
	var full := false
	var swell := 1.0
	if evolved:
		roster = enemy.get_meta(FILLERS_META, [])
		enemy.remove_meta(FILLERS_META)
		if evo(EVO_STEADY) and _bells_reaching(enemy) >= STEADY_BELLS:
			share = maxf(share, STEADY_SHARE)  # Steady Beat: in full
			full = true
		if evo(EVO_CRESCENDO):
			var n := int(enemy.get_meta(CRESC_META, 0))
			swell = minf(1.0 + CRESC_STEP * n, CRESC_MAX)
			enemy.set_meta(CRESC_META, n + 1)
	# Accompaniment: another Warden's Toll is that Warden's hit again (its own status comes with it, below)
	var striker = filler if evolved and is_instance_valid(filler) else bell
	var landing := amount * share * swell
	enemy.set_meta(TOLLED_META, true)
	Reactions._effect(&"landing_dust", at, self, 0.5)
	_toll_flashes.append({"enemy": weakref(enemy), "at": at, "start": now()})  # The rings burst (drawn in _draw_pips)
	# Setup credit 2026-10-16: what Rising Song, Steady Beat and Crescendo add to the Toll is their own damage (multipliers)
	if share > TOLL_SHARE:
		if full:
			DamageLog.note_card_bonus(String(EVO_STEADY), share / TOLL_SHARE)
		else:
			DamageLog.note_card_bonus(card_id(RISING_SONG), share / TOLL_SHARE)
	if swell > 1.0:
		DamageLog.note_card_bonus(String(EVO_CRESCENDO), swell)
	strike(striker, enemy, landing, &"toll", true)
	if full:
		Reactions._effect(&"toll_ring", at, self, 0.8)
		credit(EVO_STEADY, at)
	if swell > 1.0:
		credit(EVO_CRESCENDO, at)
	if striker != bell:
		_accompanied(striker, enemy, at)
	if evolved:
		_evolved_toll(enemy, bell, at, landing, amount, roster, striker != bell)
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

# `rings`: Lingering Note's note (nightmares walking through ring once; `amount` is the hit a Toll would land again);
# otherwise Hanging Note's (they are struck for `amount`). `skip`: the Tolled nightmare standing in it.
func _hang_note(bell, at: Vector2, amount: float, rings: bool = false, skip = null) -> void:
	for i in range(_notes.size() - 1, -1, -1):
		if _notes[i].bell.get_ref() == bell:
			_notes.remove_at(i)  # One per bell
	var struck := {}
	if is_instance_valid(skip):
		struck[skip.get_instance_id()] = true
	var choir: Array = []
	if rings and evo(EVO_CHOIR):  # Night Choir: the Wardens touching the note, strongest first
		var beside: Array = towers().filter(func(t) -> bool: return t.tower_data.can_attack and touches_point(t, at))
		beside.sort_custom(func(a, b) -> bool: return second_of(a) > second_of(b))
		for tower in beside.slice(0, CHOIR_WARDENS):
			choir.append(weakref(tower))
	_notes.append({"at": at, "until": now() + (LINGER_SECONDS if rings else NOTE_SECONDS), "amount": amount, "bell": weakref(bell),
		"struck": struck, "rings": rings, "choir": choir})
	queue_redraw()

# --- Calling evolutions: what a ring and a Toll add (see the EVO_ constants) ----------------------------------------------

# Everything an evolution adds to a Toll, after it landed. `at`: where it was; `landing`: what it dealt; `amount`: the
# ring's hit; `roster`: who filled its pips; `partner`: another Warden's Toll (Accompaniment).
func _evolved_toll(enemy, bell, at: Vector2, landing: float, amount: float, roster: Array, partner: bool) -> void:
	if evo(EVO_PEAL):
		_peal(enemy, at)
	if evo(EVO_NOTE):
		_hang_note(bell, at, amount, true, enemy)
		Reactions._effect(&"chorus_note", at, self, 0.6)
	if not living(enemy):
		return
	if evo(EVO_HALL) and now() < float(enemy.get_meta(HALL_META, -INF)):
		_hall(enemy, bell, at, landing)
	if evo(EVO_SYMPHONY):
		_symphony(enemy, roster, at)
	if evo(EVO_HUSH) and living(enemy):
		_hushabye(enemy, bell)
	if evo(EVO_COUNTER) and partner and living(enemy):
		_counterpoint(enemy, at)
	if evo(EVO_CHIME) and living(enemy):
		_chime(enemy, at)
	if evo(EVO_CHORD) and living(enemy):
		_last_chord(enemy, bell)

# Accompaniment: who filled each pip, in order (0 = no Warden: a starting pip, Peal's). The pips show it, Symphony counts it.
func _fill(enemy, before: int, add: int, who, other: bool) -> void:
	var roster: Array = (enemy.get_meta(FILLERS_META, []) as Array).slice(0, maxi(before, 0))
	while roster.size() < before:
		roster.append([0, false])
	var id: int = who.get_instance_id() if is_instance_valid(who) else 0
	for k in add:
		roster.append([id, other])
	enemy.set_meta(FILLERS_META, roster)

# Fills one pip without a ring (Peal, Counterpoint): never the last one, so only a real ring Tolls.
func _add_pip(enemy, who = null) -> bool:
	var pips := int(enemy.get_meta(PIPS_META)) if enemy.has_meta(PIPS_META) else _start_for(enemy)
	if pips >= TOLL_EVERY - 1:
		return false
	if evo(EVO_ACCOMP):
		_fill(enemy, pips, 1, who, false)
	enemy.set_meta(PIPS_META, pips + 1)
	return true

# Up to `limit` living nightmares within a cell of `at` (not `skip`), nearest first.
func _touching_at(at: Vector2, skip, limit: int) -> Array:
	var reach := TOUCH_CELLS * cell()
	var found: Array = []
	for other in Tower.nightmares_near(get_tree(), at, reach):
		if other != skip and living(other) and other.global_position.distance_to(at) <= reach:
			found.append(other)
	found.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
	return found.slice(0, limit)

# Adds `stacks` to `id` quietly (never starts it; Charged stops one short of a bolt).
func _quiet(enemy, id: StringName, stacks: int) -> int:
	if id == EnemyStatuses.STATIC:
		stacks = mini(stacks, enemy.statuses.get_max_stacks(id) - 1 - enemy.statuses.stacks(id))
	return enemy.statuses.add_quiet(id, stacks) if stacks > 0 else 0

# Carrying Tune for a shooting bell: the ring carries 4 steps down the path from its target, at half, to up to 4
# nightmares, stopping at the next bell's reach. Carried rings fill pips.
func _carry_from(bell, target, base: float) -> void:
	var i0 := index_of(target)
	if i0 < 0:
		return
	var last := mini(i0 + TUNE_STEPS * 2, _route.size() - 1)
	for k in range(i0 + 1, last + 1):
		if _bell_at(k, bell) != null:
			last = k - 1  # It stops at the next bell's reach
			break
	if last <= i0:
		return
	var found: Array = []
	for enemy in Tower.nightmares_near(get_tree(), target.global_position, TUNE_STEPS * cell()):
		if enemy == target or not living(enemy):
			continue
		var j := index_of(enemy)
		if j > i0 and j <= last:
			found.append([j, enemy])
	found.sort_custom(func(a, b) -> bool: return int(a[0]) < int(b[0]))
	var from: Vector2 = target.global_position
	var carried := 0
	for row in found.slice(0, TUNE_MAX):
		var enemy = row[1]
		if not living(enemy):
			continue
		_line_fx(from, enemy.global_position, 1.0, Palette.BLOSSOM)
		strike(bell, enemy, base * TUNE_SHARE, &"carried_ring", true, EVO_CARRYING)  # (own: setup credit 2026-10-16)
		ring(enemy, bell, base * TUNE_SHARE)
		carried += 1
	if carried > 0:
		credit(EVO_CARRYING, from)

# Hand to Hand: the bell that rang this nightmare before `bell`, if `bell` hasn't taken it hand to hand yet (-1: none).
func _handed_from(enemy, bell) -> int:
	if not enemy.has_meta(LAST_RINGER_META):
		return -1
	var last := int(enemy.get_meta(LAST_RINGER_META))
	if last == bell.get_instance_id() or (enemy.get_meta(HAND_META, {}) as Dictionary).has(bell.get_instance_id()):
		return -1
	return last

func _hand_to_hand(enemy, bell, from_id: int) -> void:
	var done: Dictionary = enemy.get_meta(HAND_META, {})
	done[bell.get_instance_id()] = true
	enemy.set_meta(HAND_META, done)
	var before = instance_from_id(from_id) if is_instance_id_valid(from_id) else null
	if before is Node2D:
		_line_fx(before.global_position, enemy.global_position, 1.5, Palette.GOLD)  # Handed from the last bell
	Reactions._effect(&"toll_ring", enemy.global_position, self, 0.4)
	credit(EVO_HAND, enemy.global_position)

# Peal: a Toll fills 1 pip on every nightmare within 4 steps (up to 8), never its last pip.
func _peal(enemy, at: Vector2) -> void:
	var i0 := index_of(enemy) if living(enemy) else nearest_point(at, 1.0)
	var filled := 0
	for other in Tower.nightmares_near(get_tree(), at, PEAL_STEPS * cell()):
		if filled >= PEAL_MAX:
			break
		if other == enemy or not living(other):
			continue
		var j := index_of(other) if i0 >= 0 else -1
		if j >= 0:
			if absi(j - i0) > PEAL_STEPS * 2:
				continue
		elif other.global_position.distance_to(at) > PEAL_STEPS * cell():
			continue
		if _add_pip(other):
			filled += 1
			_line_fx(at, other.global_position, 1.0, Palette.GOLD)
	if filled > 0:
		Reactions._effect(&"toll_ring", at, self, 1.2)
		credit(EVO_PEAL, at)

# Lingering Note / Night Choir: a nightmare walked into a ringing note.
func _note_heard(note: Dictionary, enemy) -> void:
	var bell = note.bell.get_ref()
	if not is_instance_valid(bell) or not living(enemy):
		return
	var sang := 0
	for ref in note.choir:
		var tower = ref.get_ref()
		if not is_instance_valid(tower) or not _last_hit_of.has(tower.get_instance_id()) or not living(enemy):
			continue
		var hit := minf(float(_last_hit_of[tower.get_instance_id()]) * CHOIR_SHARE, second_of(tower) * CHOIR_CAP_SECONDS)
		_line_fx(tower.global_position, enemy.global_position, 1.5, Palette.HEARTLIGHT)
		strike(tower, enemy, hit, &"chorus_repeat", false, EVO_CHOIR)  # (own: setup credit 2026-10-16)
		sang += 1
	if sang > 0:
		credit(EVO_CHOIR, note.at)
	Reactions._effect(&"chorus_note", note.at, self, 0.5)
	credit(EVO_NOTE, note.at)
	ring(enemy, bell, float(note.amount))

# Midnight Bell: the 12th ring on a nightmare (once each). True when this ring reached it.
func _count_rings(enemy, add: int) -> bool:
	if enemy.has_meta(MIDNIGHT_META):
		return false
	var n := int(enemy.get_meta(RINGS_META, 0)) + add
	enemy.set_meta(RINGS_META, n)
	if n < MIDNIGHT_RINGS:
		return false
	enemy.set_meta(MIDNIGHT_META, true)
	return true

# The Midnight Toll: every status on it that deals damage pays out at once and stays (Knell's maths, nothing used up):
# Poisoned ticks once, Charged bolts for the charge it has, Soaked calls up to 2 Dewdrops near it for a free hit. Bosses half.
func _midnight(enemy) -> void:
	var s: EnemyStatuses = enemy.statuses
	var scale := MIDNIGHT_BOSS if s.is_boss else 1.0
	var at: Vector2 = enemy.global_position
	_clocks.append({"enemy": weakref(enemy), "at": at, "until": now() + MIDNIGHT_SECONDS})
	Reactions._effect(&"toll_ring", at, self, 1.4)
	credit(EVO_MIDNIGHT, at)
	if s.has(EnemyStatuses.SPORED):
		enemy.flash_status(EnemyStatuses.SPORED)
		strike(s.source(EnemyStatuses.SPORED), enemy, s.stacks(EnemyStatuses.SPORED) * s.potency(EnemyStatuses.SPORED) * EnemyStatuses.SPORE_TICK * scale,
			&"knell", true, EVO_MIDNIGHT)  # (own: setup credit 2026-10-16)
	if living(enemy) and s.has(EnemyStatuses.STATIC):
		enemy.flash_status(EnemyStatuses.STATIC)
		strike(s.source(EnemyStatuses.STATIC), enemy, s.stored_bolt_damage() * scale, &"knell", false, EVO_MIDNIGHT)
	if living(enemy) and s.has(EnemyStatuses.DAMP):
		enemy.flash_status(EnemyStatuses.DAMP)
		var fired := 0
		for tower in towers():
			if fired >= KNELL_DEWDROPS:
				break
			if tower.tower_data.line == "water" and tower.tower_data.can_attack and near(tower.global_position, at) \
					and free_hit(tower, enemy, scale, FREE_HIT_TAG, INF, EVO_MIDNIGHT):
				fired += 1

# Hush-a-bye: a Toll adds 2 Drowsy (the bell's, never native: no lent card reads it); 3 Tolls within 6 s and it naps.
func _hushabye(enemy, bell) -> void:
	var at: Vector2 = enemy.global_position
	setup_apply(EVO_HUSH, bell, enemy, EnemyStatuses.DROWSY, HUSH_DROWSY, bell.get_damage())  # (setup credit 2026-10-16)
	if not living(enemy):
		return
	if enemy.statuses.has(EnemyStatuses.DROWSY):
		enemy.flash_status(EnemyStatuses.DROWSY)
		credit(EVO_HUSH, at)
	var times: Array = (enemy.get_meta(HUSH_META, []) as Array).filter(func(t) -> bool: return now() - float(t) <= HUSH_WINDOW)
	times.append(now())
	if times.size() >= HUSH_TOLLS and now() >= float(enemy.get_meta(HUSH_NEXT_META, -INF)) and nap(enemy):
		enemy.set_meta(HUSH_NEXT_META, now() + HUSH_EVERY)
		enemy.set_meta(HUSHED_META, true)
		control(EVO_HUSH, NAP_SECONDS)  # (setup credit 2026-10-16)
		times.clear()
		Reactions._effect(&"chorus_note", at, self, 1.0)
		credit(EVO_HUSH, at)
	enemy.set_meta(HUSH_META, times)

# Sleeping Hall: the first Toll within 3 s of a Hush-a-bye nap ending also lands on up to 4 nightmares touching it, at half.
func _hall(enemy, bell, at: Vector2, landing: float) -> void:
	enemy.remove_meta(HALL_META)
	var hit := 0
	for other in _touching_at(at, enemy, HALL_OTHERS):
		_line_fx(at, other.global_position, 2.0, Palette.BLOSSOM)
		strike(bell, other, landing * HALL_SHARE, &"toll", true, EVO_HALL)  # (own: setup credit 2026-10-16)
		hit += 1
	if hit > 0:
		Reactions._effect(&"toll_ring", at, self, 1.3)
		credit(EVO_HALL, at)

# Accompaniment: another Warden's Toll brings its status again (its own application, never native, so no lent card or
# Calling rule reads it again).
func _accompanied(partner, enemy, at: Vector2) -> void:
	_line_fx(partner.global_position, at, 2.0, Palette.BLOSSOM)
	credit(EVO_ACCOMP, at)
	var status := status_of(partner)
	if status == &"" or not living(enemy):
		return
	setup_apply(EVO_ACCOMP, partner, enemy, status, maxi(int(partner.attack_data.status_stacks), 1), partner.get_damage())  # (setup credit 2026-10-16)
	if living(enemy) and enemy.statuses.has(status):
		enemy.flash_status(status)

# Accompaniment: a hit from another Warden touching a bell fills a pip (once a second; a Sprout's every hit). True when
# the Warden touches a bell (the old Join In then stays quiet).
func _accompany(source, enemy, base: float) -> bool:
	var bell = null
	var best := INF
	for other in bells():
		if touching(other, source):
			var d: float = other.global_position.distance_squared_to(source.global_position)
			if d < best:
				best = d
				bell = other
	if bell == null:
		return false
	if source.tower_data.get_id() != "sprout":
		if now() < float(source.get_meta(JOIN_META, -INF)):
			return true
		source.set_meta(JOIN_META, now() + ACCOMP_EVERY)
	_line_fx(source.global_position, bell.global_position, 1.0, Palette.BLOSSOM)
	ring(enemy, bell, base, true, source)
	return true

# Counterpoint: another Warden's Toll: the nearest ready bell within 4 cells rings it too (its free hit, and a pip).
func _counterpoint(enemy, at: Vector2) -> void:
	var bell = null
	var best := (COUNTER_CELLS * cell()) ** 2
	for other in bells():
		var d: float = other.global_position.distance_squared_to(at)
		if d <= best and now() >= float(other.get_meta(COUNTER_META, -INF)):
			best = d
			bell = other
	if bell == null:
		return
	bell.set_meta(COUNTER_META, now() + COUNTER_EVERY)
	if not free_hit(bell, enemy, 1.0, FREE_HIT_TAG, INF, EVO_COUNTER):  # (own: setup credit 2026-10-16)
		return
	if living(enemy):
		_add_pip(enemy, bell)
	Reactions._effect(&"toll_ring", at, self, 0.6)
	credit(EVO_COUNTER, at)

# Symphony: a Toll whose pips 4 different Wardens filled: each one's last hit lands again at half (once in 6 s each).
func _symphony(enemy, roster: Array, at: Vector2) -> void:
	if now() < float(enemy.get_meta(SYMPHONY_META, -INF)):
		return
	var ids := {}
	for row in roster:
		if int(row[0]) != 0:
			ids[int(row[0])] = true
	if ids.size() < SYMPHONY_WARDENS:
		return
	enemy.set_meta(SYMPHONY_META, now() + SYMPHONY_EVERY)
	var sang := 0
	for id in ids:
		if not living(enemy):
			break
		if not is_instance_id_valid(id) or not _last_hit_of.has(id):
			continue
		var tower = instance_from_id(id)
		if not (tower is Tower):
			continue
		_line_fx(tower.global_position, at, 1.5, Palette.HEARTLIGHT)
		strike(tower, enemy, minf(float(_last_hit_of[id]) * SYMPHONY_SHARE, second_of(tower)), &"chorus_repeat", false, EVO_SYMPHONY)  # (own: setup credit 2026-10-16)
		sang += 1
	if sang > 0:
		Reactions._effect(&"chorus_note", at, self, 1.2)
		credit(EVO_SYMPHONY, at)

# Chime of Many: a Toll repeats the nightmare's last status hit on up to 4 nightmares touching it (each once).
func _chime(enemy, at: Vector2) -> void:
	var last: Array = enemy.get_meta(CHIME_META, [])
	if last.size() < 3:
		return
	var tower = (last[0] as WeakRef).get_ref()
	var status: StringName = last[1]
	if not (tower is Tower) or not is_instance_valid(tower) or status == EnemyStatuses.HELD or status == EnemyStatuses.DROWSY:
		return
	var rung := 0
	for target in _touching_at(at, enemy, CHIME_OTHERS):
		if not living(target):
			continue
		var before: int = target.statuses.applications
		setup_apply(EVO_CHIME, tower, target, status, int(last[2]), tower.get_damage())  # (setup credit 2026-10-16)
		if living(target) and target.statuses.applications > before:
			rung += 1
			target.flash_status(status)
			_line_fx(at, target.global_position, 1.5, Palette.BLOSSOM)
	if rung > 0:
		Reactions._effect(&"toll_ring", at, self, 1.0)
		credit(EVO_CHIME, at)

# Last Chord: a Toll on a nightmare carrying 3 statuses sets off any Reaction it is halfway to (Clashing Notes' check).
# The 8 s wait is spent only when one goes off.
func _last_chord(enemy, bell) -> void:
	if now() < float(enemy.get_meta(CHORD_META, -INF)):
		return
	var count := 0
	for id in enemy.statuses.active_ids():
		if id != EnemyStatuses.HELD:
			count += 1
	if count < CHORD_STATUSES:
		return
	var at: Vector2 = enemy.global_position
	var health: float = enemy.health
	var changes: int = enemy.statuses.changes
	Reactions.check_at_half(enemy, bell)
	if living(enemy) and enemy.health >= health and enemy.statuses.changes == changes:
		return  # Nothing went off
	enemy.set_meta(CHORD_META, now() + CHORD_EVERY)
	Reactions._effect(&"chorus_note", at, self, 1.4)
	credit(EVO_CHORD, at)

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
		setup_quiet(enemy, CHORUS, status, enemy.statuses.add_quiet(status, 1))  # (setup credit 2026-10-16)

# Knell (lent; hard cards 2026-10-16, one rule for every status): a bell's hit lands again once for each status other
# families put on the nightmare ({held} never counts), up to KNELL_REPEATS_MAX, KNELL_REPEAT_GAP s apart, each adding 1
# of the bell's own status (not native: no class / cooperation / role extras). Repeats are tagged `knell` (a class tag:
# they never set In Time, Refrain or Knell off again); Da Capo may add its third. Nothing is used up. The repeats queued.
func _knell(enemy, bell, base: float) -> int:
	var statuses: EnemyStatuses = enemy.statuses
	var count := 0
	for id in statuses.active_ids():
		if id != EnemyStatuses.HELD and is_other_family(statuses.source(id)):
			count += 1
	count = mini(count, KNELL_REPEATS_MAX)
	if count <= 0:
		return 0
	var share := KNELL_PULSE_SHARE if is_pulsing(bell) else KNELL_REPEAT_SHARE
	for k in range(1, count + 1):
		_later.append({"at": now() + KNELL_REPEAT_GAP * k, "tower": weakref(bell), "enemy": weakref(enemy),
			"amount": base * share, "tag": &"knell", "again": true, "status": status_of(bell)})
	credit(KNELL, enemy.global_position)
	return count

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
	setup_apply(HUM_ALONG, bell, enemy, EnemyStatuses.DROWSY, 1, bell.get_damage())  # (setup credit 2026-10-16)

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
				SETUP.begin(StringName(card_id(RINGING_EARS)))  # (setup credit 2026-10-16: a native application, in Ringing Ears' name)
				bell._apply_one_status(enemy, EnemyStatuses.DROWSY, 1, bell.get_damage(), true)
				SETUP.end()

# A Warden's own accepted status application (DreamState.class_status): a bell making a nightmare Drowsy (Nod Off,
# Refrain), another family's status (Second Verse remembers the last one).
func status_applied(tower, enemy, status: StringName, stacks: int) -> void:
	if not living(enemy):
		return
	if evo(EVO_CHIME) and status != EnemyStatuses.DROWSY and status != EnemyStatuses.HELD and stacks > 0:
		enemy.set_meta(CHIME_META, [weakref(tower), status, stacks])  # Chime of Many: the last status hit, for its next Toll
	if is_own(tower) and status == EnemyStatuses.DROWSY:
		if rule(NOD_OFF) and not enemy.has_meta(DROWSED_META):
			# Nod Off: the first time a bell makes it Drowsy, it naps 1 s (one sleeper for each bell; never bosses)
			var sleeper = tower.get_meta(SLEEPER_META).get_ref() if tower.has_meta(SLEEPER_META) else null
			if not (living(sleeper) and sleeper.statuses.is_asleep()) and nap(enemy):
				tower.set_meta(SLEEPER_META, weakref(enemy))
				control(NOD_OFF, NAP_SECONDS)  # (setup credit 2026-10-16)
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
	if is_hit and not tagged and source != null and (evo(EVO_CHOIR) or evo(EVO_SYMPHONY)):
		_last_hit_of[source.get_instance_id()] = float(event.base)  # Night Choir, Symphony: each Warden's last hit, before defences
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
		# Knell (hard cards 2026-10-16): a bell's hit lands again once per other-family status on it, up to 3. Each
		# nightmare once every 6 s
		if rule(KNELL) and now() >= float(enemy.get_meta(KNELL_NEXT_META, -INF)) and _knell(enemy, source, event.base) > 0:
			enemy.set_meta(KNELL_NEXT_META, now() + KNELL_EVERY)
		if rule(CLASHING_NOTES) and living(enemy) and enemy.statuses.has(EnemyStatuses.DROWSY) and _carries_other(enemy) \
				and now() >= float(enemy.get_meta(CLASH_NEXT_META, -INF)):
			enemy.set_meta(CLASH_NEXT_META, now() + CLASH_EVERY)  # (Retired 2026-10-15; an old save keeps it)
			Reactions.check_at_half(enemy, source)
		if not living(enemy) or not tolls_on():
			return
		if is_pulsing(source):
			if int(source.get_meta(PULSE_META, -1)) != Engine.get_process_frames():
				source.set_meta(PULSE_META, Engine.get_process_frames())
				if rule(SOUND_CARRIES) or evo(EVO_CARRYING):
					_carry_ring(source, event.base)
		elif evo(EVO_CARRYING) and int(source.get_meta(TUNE_FRAME_META, -1)) != Engine.get_process_frames():
			source.set_meta(TUNE_FRAME_META, Engine.get_process_frames())  # Carrying Tune: a shooting bell carries from its target
			_carry_from(source, enemy, event.base)
		ring(enemy, source, event.base)
		return
	# Another Warden's hit
	if not is_other(source):
		return
	if rule(HUM_ALONG) and now() >= float(source.get_meta(HUM_META, -INF)):
		_hum_along(source, enemy)
	if not tolls_on():
		return
	if evo(EVO_ACCOMP) and _accompany(source, enemy, event.base):
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
	if tower is Tower and living(enemy):
		tower.note_repeat_hit(enemy)  # Keyword chips 2026-10-16: a repeat counts for Eternal Static / Rooted Nightmares
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
		var row_status: StringName = row.get("status", &"")  # Knell's repeats add 1 of the bell's status (hard cards 2026-10-16)
		if row_status != &"" and is_instance_valid(tower) and living(enemy):
			setup_apply(KNELL if row.tag == &"knell" else &"", tower, enemy, row_status, 1, tower.get_damage())  # (setup credit 2026-10-16)

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
	var pending: Array = enemy.get_meta(REFRAIN_META) if enemy.has_meta(REFRAIN_META) and enemy.get_meta(REFRAIN_META) is Array else []
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
	if bell != null and now() < float(bell.get_meta(RUDE_NEXT_META, -INF)):
		return  # Once a second for each bell (with no bell on the map, each sleep or Hold still replays once)
	if bell != null:
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
	var tune := evo(EVO_CARRYING)  # Carrying Tune: the same carry, shown as sound running down the path
	var share := TUNE_SHARE if tune else CARRY_SHARE
	var exit := clampi(int(_exit.get(bell.get_instance_id(), int(carried[0]))), 0, maxi(_route_px.size() - 1, 0))
	var from: Vector2 = _route_px[exit] if exit < _route_px.size() else bell.global_position
	var heard := 0
	for enemy in enemies():
		if carried.has(index_of(enemy)) and not _in_reach(bell, enemy):
			if tune:
				_line_fx(from, enemy.global_position, 1.0, Palette.BLOSSOM)
			strike(bell, enemy, base * share, &"carried_ring", true, EVO_CARRYING if tune else &"")  # (own: setup credit 2026-10-16)
			ring(enemy, bell, base * share)
			heard += 1
	if tune and heard > 0:
		credit(EVO_CARRYING, from)

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
	var verse: int = enemy.statuses.add_quiet(StringName(last[0]), int(last[1]))
	setup_quiet(enemy, SECOND_VERSE, StringName(last[0]), verse)  # (setup credit 2026-10-16)
	if verse > 0:
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
			if enemy.has_meta(HUSHED_META):  # Sleeping Hall: a Hush-a-bye nap ended: its next Toll within 3 s spreads
				enemy.remove_meta(HUSHED_META)
				if evo(EVO_HALL) and living(enemy):
					enemy.set_meta(HALL_META, now() + HALL_WINDOW)
					Reactions._effect(&"chorus_note", enemy.global_position, self, 0.5)
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
	var heard: Array = []  # Lingering Note: [note, nightmare], rung after the walk (a ring may Toll and move the note)
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
				if bool(note.get("rings", false)):
					heard.append([note, enemy])
				else:
					strike(bell, enemy, float(note.amount), &"hanging_note", true)
	for row in heard:
		_note_heard(row[0], row[1])

func on_rest() -> void:
	_notes.clear()
	_later.clear()
	_clocks.clear()
	_last_hit_of.clear()
	queue_redraw()

# --- What the other systems ask (through DreamState) --------------------------------------------------------------------

# Rude Awakening: the next hit on a nightmare waking from any sleep, or let go from a Hold, from any Warden, deals
# double (the hit that wakes it counts; within 2 s; once per sleep or Hold).
func damage_multiplier(enemy, source, tag: StringName) -> float:
	return 1.0  # (Trait rework 2026-10-15: Rude Awakening replays hits now, _rude_awakening; this was its doubled hit)

# --- Drawing: the hanging notes ---------------------------------------------------------------------------------------------

# Steady Beat: one gold band along each stretch of path 2 or more bells reach (owner 2026-10-17: the old faint double
# rings on every step were "barely visible" on the sand path). A dark ember edge under a warm glow reads on sand and grass.
const OVERLAP_EDGE := 0.5  # Band widths, in cells
const OVERLAP_BODY := 0.34

func _draw_overlap() -> void:
	if _overlap.is_empty():
		return
	var indices: Array = _overlap.keys()
	indices.sort()
	var run := PackedVector2Array()
	var last := -2
	for i in indices:
		var n := int(i)
		if n >= _route_px.size():
			continue
		if n != last + 1:
			_draw_band(run)
			run = PackedVector2Array()
		run.append(_route_px[n])
		last = n
	_draw_band(run)

func _draw_band(run: PackedVector2Array) -> void:
	if run.is_empty():
		return
	if run.size() == 1:
		draw_circle(run[0], cell() * OVERLAP_EDGE / 2.0, Color(Palette.EMBER, 0.55))
		draw_circle(run[0], cell() * OVERLAP_BODY / 2.0, Color(Palette.GLOW, 0.5))
		return
	draw_polyline(run, Color(Palette.EMBER, 0.55), cell() * OVERLAP_EDGE, true)
	draw_polyline(run, Color(Palette.GLOW, 0.5), cell() * OVERLAP_BODY, true)
	draw_polyline(run, Color(Palette.HEARTLIGHT, 0.6), 2.0, true)

func _draw() -> void:
	_draw_overlap()
	for note in _notes:
		if bool(note.get("rings", false)):  # Lingering Note: a note glyph (Night Choir's glows pale when Wardens sing in it)
			var tint: Color = Palette.HEARTLIGHT if not (note.choir as Array).is_empty() else Palette.GOLD
			draw_arc(note.at, NOTE_CELLS * cell(), 0.0, TAU, 24, Color(tint, 0.5), 1.5)
			draw_circle(note.at + Vector2(-3.0, 4.0), 3.5, tint)
			draw_line(note.at + Vector2(0.5, 4.0), note.at + Vector2(0.5, -8.0), tint, 1.5)
			draw_line(note.at + Vector2(0.5, -8.0), note.at + Vector2(5.0, -5.0), tint, 1.5)
			continue
		draw_circle(note.at, NOTE_CELLS * cell(), Color(Palette.BLOSSOM, 0.25))
		draw_arc(note.at, NOTE_CELLS * cell(), 0.0, TAU, 24, Color(Palette.BLOSSOM, 0.8), 2.0)
