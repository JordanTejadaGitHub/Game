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
const LAST_OTHER_META := &"kt_last_other"  # On a nightmare: [[status, stacks, Warden id, time], ...] its last VERSE_KEEP applications from any Warden (Second Verse)
const VERSE_KEEP := 4  # (owner 2026-10-18, bell_lent_review.md: any Warden but the leaving bell's own, other bells too)
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
# Da Capo (owner 2026-10-18, bell_lent_review.md; was a repeated hit landing a third time at half): every 6 s, a bell's
# next attack happens twice in a row (a whole real attack, statuses too: its wait is reset as Curtain Call does), never
# more often than every 3 of that bell's own attacks. The clock runs only during a drift and starts over at each rest.
const DA_CAPO_EVERY := 6.0
const DA_CAPO_MIN_ATTACKS := 3
const DA_CAPO_BEAT := 0.2  # The two-beat pulse on the bell: the second beat this long after the first
var _drift_clock := 0.0  # Seconds of drift time (Da Capo's clock: it stands still at rests)
var _da_capo_due := {}  # Bell instance id -> the _drift_clock its next attack happens twice at (cleared at each rest)
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
# Carrying Tune (rebuilt 2026-10-23, owner: the ring only): a ring carries this many steps down the path (a pulse: past its
# reach; a shot: past its target) and rings the nightmares there with the bell's whole hit, no damage of its own (only a
# Toll it makes deals damage, at the normal half). Balancing 2026-10-23: 6 steps (was 4).
const TUNE_STEPS := 6
const TUNE_MAX := 4  # …a shot's carry reaches up to this many nightmares (a pulse's covers its stretch, as Sound Carries)
const TUNE_FRAME_META := &"kt_evo_tune_frame"  # On a bell: the frame its shot last carried (one carry per attack)
const EVO_WALLS := &"kt_evo_humming_walls"
const WALL_STEPS := 4  # Humming Walls: each 4 steps walked beside Thornwalls fills one pip (never the last; once per Toll)
const WALL_SEEN_META := &"kt_evo_wall_seen"  # On a nightmare: the furthest route index counted (forward only)
const WALL_COUNT_META := &"kt_evo_wall_count"  # On a nightmare: wall-side route points walked toward the next pip
const WALL_DONE_META := &"kt_evo_wall_done"  # On a nightmare: a wall pip filled since its last Toll
const WALL_PIP_META := &"kt_evo_wall_pip"  # On a nightmare: the ring index the walls filled (kt_humming_pip; drawing only)
const WALL_LAPS_META := &"kt_evo_wall_laps"  # On a nightmare: its laps when last counted (a new lap starts the count over)
const EVO_DOWN := &"kt_evo_down_the_line"
const EVO_BOTH := &"kt_evo_both_ways"
const PRIME_STEPS := 2  # Down the Line / Both Ways: a Toll primes the nightmare behind (ahead) within this many steps…
const PRIME_DEPTH := 3  # …up to this many in a row each way; a primed nightmare's next ring counts 1 more
const PRIMED_META := &"kt_evo_primed"  # On a nightmare: {&"back" / &"ahead": depth} waiting for its next ring
const CHAIN_META := &"kt_evo_chain"  # On a nightmare: {&"back" / &"ahead": depth} its prime was spent; read at its next Toll
const BACK := &"back"
const AHEAD := &"ahead"
const EVO_CHANGE := &"kt_evo_change_ringing"
const CHANGE_SHARE := 0.5  # Change Ringing: another bell rings a Pealed nightmare in its range at half its hit…
const CHANGE_EVERY := 1.0  # …each bell once a second
const CHANGE_META := &"kt_evo_change_next"  # On a bell
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
# Steady Beat (rebuilt 2026-10-23, no range overlap): a nightmare rung only by one group of touching bells since its last
# Toll Tolls every STEADY_NEED-th ring (the 2 starting pips count), in full: the setup half plus STEADY_EXTRA of the bell's hit.
const STEADY_NEED := 3
const STEADY_EXTRA := 0.5
const GROUP_META := &"kt_evo_group"  # On a nightmare: the bell group of every ring since its last Toll (-1: mixed)
const TOLL_NEED_META := &"kt_evo_need"  # On a nightmare: the need its Toll was made at (pip credit shares)
const EVO_DEEP := &"kt_evo_deep_tone"
const DEEP_RANK := 3  # Deep Tone: a bell of rank III or higher…
const DEEP_PIPS := 2  # …rings 2 pips with its own hit
const EVO_DOUBLE := &"kt_evo_double_time"
const DOUBLE_RANK := 4  # Double Time: a Toll from a rank IV+ bell…
const DOUBLE_PIPS := 2  # …leaves the nightmare 2 rings into its next Toll
const EVO_ALLEGRO := &"kt_evo_allegro"
const ALLEGRO_RANK := 5  # Allegro: a rank V+ bell keeps a Toll the 1 s wait stopped…
const ALLEGRO_BANK := 3  # …up to this many, spent on its next ready nightmare (lost at a rest)
const ALLEGRO_META := &"kt_evo_allegro_bank"  # On a bell
const EVO_TWELFTH := &"kt_evo_twelfth_hour"
const TWELFTH_RINGS := 6  # Twelfth Hour: nightmares in the bell's range with this many rings…
const TWELFTH_OTHERS := 3  # …up to this many (Balancing 2026-10-23: 3, was 4), nearest first…
const TWELFTH_GAP := 0.15  # …strike their own Midnight this far apart (one wave: theirs never start another)
const EVO_CRESCENDO := &"kt_evo_crescendo"
const CRESC_STEP := 0.25  # Crescendo: each Toll on a nightmare makes its next one this much stronger…
const CRESC_MAX := 2.0  # …up to double
const CRESC_GLOW_STEPS := 4  # (CRESC_MAX - 1) / CRESC_STEP: the pips are brightest from here
const CRESC_META := &"kt_evo_cresc"  # On a nightmare: its Tolls so far
const EVO_MIDNIGHT := &"kt_evo_midnight_bell"
const MIDNIGHT_RINGS := 12  # Midnight Bell: the 12th ring on a nightmare (once each)…
const MIDNIGHT_BOSS := 0.5  # …bosses take this share
const MIDNIGHT_TRIPLE := 3.0  # …and the bell hits it for this many times its hit, with Crescendo (non-status builds, owner 2026-10-19)
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
const ACCOMP_SHARE := 0.5  # Accompaniment (rebuilt 2026-10-23): the bell's Toll always lands; the filling Warden's hit repeats at half
const EVO_COUNTER := &"kt_evo_counterpoint"
const COUNTER_SHARE := 0.5  # Counterpoint (rebuilt 2026-10-23): a Toll repeats one other noted Warden's hit at half…
const COUNTER_EVERY := 1.0  # …each Warden once a second
const COUNTER_META := &"kt_evo_counter_next"  # On a Warden
const COUNTER_NOTES := 4  # Notes drawn over a nightmare, at most
const EVO_CODA := &"kt_evo_coda"
const CODA_SECONDS := 4.0  # Coda: a Symphony's Wardens keep a note this long; their next hit lands again…
const CODA_SHARE := 0.5  # …at half (never more than a second of that Warden's damage)
const CODA_META := &"kt_evo_coda_until"  # On a Warden
const EVO_TENOR := &"kt_evo_tenor_bell"
const TENOR_RATE := 1.0  # Tenor Bell: a joined Warden whose form's base rate is at most this repeats in full
const EVO_ENSEMBLE := &"kt_evo_ensemble"
const ENSEMBLE_FAMILIES := 2  # Ensemble: a bell touching Wardens of this many other families (Sprouts as one)…
const ENSEMBLE_DELAY := 1.0  # …has its Wardens' repeats land again this long later…
const ENSEMBLE_SHARE := 0.5  # …at half
const EVO_SOUNDING := &"kt_evo_sounding_board"
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
# Damage credit (owner 2026-10-19: "view the damage for the evolutions"): the pips an evolution filled toward the next
# Toll ({evolution id: pips}); the Toll credits each its share of what it dealt (DamageLog.note_card_share).
const PIP_BY_META := &"kt_evo_pip_by"
var _last_hit_of := {}  # Warden id -> its last hit, before defences (Accompaniment's repeats, Symphony, Coda, Night Choir)
var _clocks: Array = []  # Midnight Bell's clock faces: [{enemy: WeakRef, at, until}]
var _groups := {}  # Steady Beat: bell instance id -> its group (touching bells, connected; walls never)
var _wall_side := {}  # Humming Walls: route index -> true where a Thornwall touches the path
var _outer := {}  # Sounding Board: Warden instance id -> the bell its joined neighbour touches
var _families := {}  # Ensemble: bell instance id -> other families (Sprouts as one) touching it

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

# The pips a nightmare starts with at its first ring (Steady Beat's old 3-pip start is gone, 2026-10-23).
func _start_for(_enemy) -> int:
	return _start_pips()

# The rings a Toll needs (evo_shared_spec.md 8): Steady Beat's 3 while one bell group alone has rung it since its last
# Toll, else 4. Read in ring(), the wait clamp, _add_pip, the pip credit (TOLL_NEED_META) and _draw_pips.
func _toll_need(enemy) -> int:
	if evo(EVO_STEADY) and is_instance_valid(enemy) and int(enemy.get_meta(GROUP_META, -1)) >= 0:
		return STEADY_NEED
	return TOLL_EVERY

func _ready() -> void:
	super._ready()
	add_to_group(GROUP)
	_pip_layer = Node2D.new()
	_pip_layer.name = "TollPips"
	_pip_layer.z_index = PIP_Z  # Over the nightmares (this node lies with the ground)
	_pip_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # The Calling evolution marks: 1x crisp pixels
	_pip_layer.draw.connect(_draw_pips)
	add_child(_pip_layer)
	if dream_state != null and dream_state.get("drift_director") != null:
		dream_state.drift_director.drift_cleared.connect(_drift_cleared.unbind(3))

# A drift ended: Allegro's kept Tolls are lost.
func _drift_cleared() -> void:
	for bell in bells():
		bell.remove_meta(ALLEGRO_META)

# The Toll count over each nightmare (council 2026-10-13: "a player won't understand rules they can't see"): 4 small
# pips above it, the filled ones gold. Shown only while Tolls are on and the nightmare has started counting.
const PIP_Z := 8
const PIP_OFFSET := Vector2(0.0, -44.0)  # Above the health bar
const RING_CORE := 1.5  # Rings over the nightmare: the clapper dot,
const RING_FIRST := 3.0  # the innermost ring's radius,
const RING_STEP := 2.5  # the gap between rings,
const RING_WIDTH := 1.5  # a lit ring's width,
const RING_TRIM := 0.45  # and how much of each lower half-arc is cut at the ends (radians)
const RING_ARC_FROM := RING_TRIM  # The rings hang UNDER the health bar, opening downward (owner 2026-10-18: "can't see the
const RING_ARC_TO := PI - RING_TRIM  # bells' rings, should be under the health bar"; above it the status badges hid them)
const RING_GAP := 3.0  # From the health bar's bottom edge to the clapper dot
const BAR_HALF_HEIGHT := 2.5  # Half of enemy.gd HEALTH_BAR_SIZE.y (5)
const TOLL_FLASH := 0.4  # A Toll: the rings flash and burst outward for this long (owner 2026-10-17: "the toll should have a visual effect when filled")
const TOLL_FLASH_GROW := 1.6  # How far the rings spread by the end of it (x their radius)
var _toll_flashes: Array = []  # [{enemy: WeakRef, at: Vector2, start: float}]
var _pip_layer: Node2D
var _pips_shown := false

func _process(delta: float) -> void:
	super._process(delta)
	if dream_state != null and not get_tree().paused and not resting() and rule(DA_CAPO):
		_drift_clock += delta  # Da Capo's clock runs only during a drift (owner 2026-10-18, bell_lent_review.md)
	if not _ears.is_empty():
		_ears_flush()
	if dream_state != null and not _clocks.is_empty():
		_clocks = _clocks.filter(func(c) -> bool: return now() < float(c.until))
	if dream_state != null and not _toll_flashes.is_empty():
		_toll_flashes = _toll_flashes.filter(func(f) -> bool: return now() - float(f.start) < TOLL_FLASH)
	if _pip_layer != null and (tolls_on() or _pips_shown):
		_pips_shown = tolls_on()
		_pip_layer.queue_redraw()  # Only while Tolls are on (and once more to clear them)

# Where a nightmare's rings hang: just under its own health bar (raised over tall art: Enemy._bar_offset).
func _ring_anchor(enemy) -> Vector2:
	var bar = enemy.get("_bar_offset")
	var y: float = (bar.y if bar is Vector2 else PIP_OFFSET.y) + BAR_HALF_HEIGHT + RING_GAP
	return enemy.global_position + Vector2(0.0, y)

func _draw_pips() -> void:
	if dream_state == null or not tolls_on():
		return
	var start := _start_pips()
	var colours := evo(EVO_ACCOMP)  # Accompaniment: pips another Warden filled are pink
	var cresc := evo(EVO_CRESCENDO)  # Crescendo: the pips grow bigger and brighter
	var midnight := evo(EVO_MIDNIGHT)  # Midnight Bell: a dial over the pips counts to 12
	var notes := evo(EVO_COUNTER)  # Counterpoint: each joined Warden's note hangs over the nightmare
	var walls := evo(EVO_WALLS)  # Humming Walls: the wall's ring hums
	for enemy in enemies():
		if not enemy.has_meta(PIPS_META) and start <= 0:
			continue
		# Shown from the start (owner 2026-10-15: "feels like the pip starts at 3"): the 2 filled ones were only drawn
		# after the first ring, which had already made them 3
		var filled := int(enemy.get_meta(PIPS_META, start))
		# Rings, not dots (owner 2026-10-17: "make it seem like rings filling"): `need` sound-wave arcs rising over
		# the nightmare, lit from the inside out; the outermost is the Toll (Steady Beat: 3 bronze ones in a group's hands).
		var need := _toll_need(enemy)
		var steady := need < TOLL_EVERY
		var primed: bool = enemy.has_meta(PRIMED_META)  # Down the Line: a primed nightmare's pips glow bronze
		var at: Vector2 = _ring_anchor(enemy)
		var roster: Array = enemy.get_meta(FILLERS_META, []) if colours else []
		var swell := mini(int(enemy.get_meta(CRESC_META, 0)), CRESC_GLOW_STEPS) if cresc else 0
		var wall_pip := int(enemy.get_meta(WALL_PIP_META, -1)) if walls else -1
		# The clapper the rings spread from; Down the Line / Both Ways: a primed nightmare's bronze bell, its lip on it
		if not (primed and evo_mark(_pip_layer, ART_PRIME, at)):
			_pip_layer.draw_circle(at, RING_CORE, Color(Palette.MOONLIGHT, 0.6))
		for k in need:
			var radius := RING_FIRST + RING_STEP * k
			if k < filled:
				var colour: Color = Palette.GOLD
				if k < roster.size() and bool(roster[k][1]):
					colour = Palette.BLOSSOM
				elif swell >= CRESC_GLOW_STEPS:
					colour = Palette.GLOW
				elif steady or primed:
					colour = BRONZE_RAMP[mini(k, BRONZE_RAMP.size() - 1)]  # Bronze: Oak, Ember, Gold from the inside out
				_pip_layer.draw_arc(at, radius, RING_ARC_FROM, RING_ARC_TO, 12, colour, RING_WIDTH + 0.25 * swell, true)
				if k == wall_pip:  # Humming Walls: the ring the walls filled hums (kt_humming_pip on its lowest point)
					evo_mark(_pip_layer, ART_HUM, at + Vector2(0.0, radius))
			else:
				var empty := Color(Palette.EMBER, 0.6) if steady or primed else Color(Palette.MOONLIGHT, 0.3)
				_pip_layer.draw_arc(at, radius, RING_ARC_FROM, RING_ARC_TO, 12, empty, 1.0, true)
		if notes:
			_draw_notes(enemy, at + Vector2(0.0, RING_FIRST + RING_STEP * need + 3.0))
		if midnight and enemy.has_meta(RINGS_META) and not enemy.has_meta(MIDNIGHT_META):
			var share := clampf(float(enemy.get_meta(RINGS_META)) / MIDNIGHT_RINGS, 0.0, 1.0)
			var dial: Vector2 = at + Vector2(0.0, RING_FIRST + RING_STEP * need + 5.0)  # Under the outermost ring
			_pip_layer.draw_arc(dial, 4.0, -PI / 2.0, -PI / 2.0 + TAU * share, 16, Color(Palette.MOONLIGHT, 0.7), 1.0)
	for f in _toll_flashes:  # A Toll: the four rings light gold and burst outward, fading
		var age := clampf((now() - float(f.start)) / TOLL_FLASH, 0.0, 1.0)
		var who = f.enemy.get_ref()
		var centre: Vector2 = _ring_anchor(who) if is_instance_valid(who) else f.at + Vector2(0.0, PIP_OFFSET.y + 6.0 + BAR_HALF_HEIGHT + RING_GAP)
		var grow := 1.0 + (TOLL_FLASH_GROW - 1.0) * age
		var colour := Color(Palette.GLOW, 1.0 - age)
		for k in TOLL_EVERY:
			_pip_layer.draw_arc(centre, (RING_FIRST + RING_STEP * k) * grow, RING_ARC_FROM, RING_ARC_TO, 12, colour, RING_WIDTH + 1.0, true)
	for c in _clocks:  # Midnight Bell: a clock face at midnight over the nightmare
		var who = c.enemy.get_ref()
		var centre: Vector2 = (who.global_position if is_instance_valid(who) else c.at) + PIP_OFFSET + Vector2(0.0, -24.0)
		_pip_layer.draw_circle(centre, 8.0, Color(Palette.NIGHT, 0.7))
		_pip_layer.draw_arc(centre, 8.0, 0.0, TAU, 24, Palette.GOLD, 1.5)
		_pip_layer.draw_line(centre, centre + Vector2(0.0, -6.0), Palette.HEARTLIGHT, 1.5)
		_pip_layer.draw_line(centre, centre + Vector2(0.0, -4.0), Palette.GOLD, 2.0)
	if evo(EVO_CODA):  # Coda: a pink note floats over each Warden that keeps one
		for tower in towers():
			if now() < float(tower.get_meta(CODA_META, -INF)):
				_draw_note_glyph(tower.global_position + CODA_NOTE_OFFSET, Palette.BLOSSOM)
	if evo(EVO_ALLEGRO):  # Allegro: the kept Tolls circle the bell as bronze notes
		for bell in bells():
			var bank := int(bell.get_meta(ALLEGRO_META, 0))
			for k in bank:
				var angle := TAU * float(k) / float(ALLEGRO_BANK) + now() * ALLEGRO_SPIN
				var note: Vector2 = bell.global_position + CODA_NOTE_OFFSET * 0.5 + Vector2(cos(angle), sin(angle)) * ALLEGRO_ORBIT
				if not evo_mark(_pip_layer, ART_ALLEGRO, note + Vector2(-1.5, 2.0), 1.0, false, -1, k):
					_draw_note_glyph(note, Palette.EMBER)  # (kt_allegro_note: its head where the drawn note's head was)

# Calling evolution marks (assets/effects/calling_evo/, class_kit.evo_mark); each falls back to the drawn shape
const ART_PRIME := &"kt_bronze_prime"
const ART_ALLEGRO := &"kt_allegro_note"
const ART_HUM := &"kt_humming_pip"
const BRONZE_RAMP: Array[Color] = [Palette.OAK, Palette.EMBER, Palette.GOLD]  # Primed / Steady Beat rings, inside out

const NOTE_GAP := 7.0  # Counterpoint's notes over a nightmare, side by side
const CODA_NOTE_OFFSET := Vector2(0.0, -56.0)  # Coda's note over a Warden
const ALLEGRO_ORBIT := 14.0  # Allegro's kept notes circle this far from the bell…
const ALLEGRO_SPIN := 2.0  # …at this many radians a second

# Counterpoint: one small note per distinct joined (non-bell) Warden on the nightmare's pips, in that Warden's status colour.
func _draw_notes(enemy, at: Vector2) -> void:
	var noted := _noted(enemy)
	var x0 := -NOTE_GAP * (noted.size() - 1) / 2.0
	for k in noted.size():
		var tower = instance_from_id(int(noted[k])) if is_instance_id_valid(int(noted[k])) else null
		var colour: Color = EnemyStatuses.COLORS.get(status_of(tower), Palette.BLOSSOM) if tower is Tower else Palette.BLOSSOM
		_draw_note_glyph(at + Vector2(x0 + NOTE_GAP * k, 0.0), colour)

func _draw_note_glyph(at: Vector2, colour: Color) -> void:
	_pip_layer.draw_circle(at + Vector2(-1.5, 2.0), 2.0, colour)
	_pip_layer.draw_line(at + Vector2(0.5, 2.0), at + Vector2(0.5, -5.0), colour, 1.0)
	_pip_layer.draw_line(at + Vector2(0.5, -5.0), at + Vector2(3.0, -3.0), colour, 1.0)

# Counterpoint's notes on a nightmare: distinct joined Wardens (never bells) on its pips, oldest first, up to COUNTER_NOTES.
func _noted(enemy) -> Array:
	return _noted_roster(enemy.get_meta(FILLERS_META, []))

func _noted_roster(roster: Array) -> Array:
	var out: Array = []
	for row in roster:
		if bool(row[1]) and int(row[0]) != 0 and not out.has(int(row[0])):
			out.append(int(row[0]))
	return out.slice(maxi(out.size() - COUNTER_NOTES, 0))

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
	var steps := TUNE_STEPS if evo(EVO_CARRYING) else CARRY_STEPS  # Carrying Tune carries further than Sound Carries
	for bell in all:
		var id: int = bell.get_instance_id()
		var carried: Array = []
		for i in range(int(_exit[id]) + 1, mini(int(_exit[id]) + steps * 2, _route.size() - 1) + 1):
			if _bell_at(i, bell) != null:
				break  # It stops at the next bell's reach
			carried.append(i)
		_carry[id] = carried
	_board_groups(all)
	_board_walls()
	_board_joined(all)
	queue_redraw()

# Steady Beat: connected sets of touching bells (walls are never bells), one number each.
func _board_groups(all: Array) -> void:
	_groups.clear()
	if not evo(EVO_STEADY):
		return
	var next := 0
	for bell in all:
		if _groups.has(bell.get_instance_id()):
			continue
		var queue: Array = [bell]
		_groups[bell.get_instance_id()] = next
		while not queue.is_empty():
			var here = queue.pop_back()
			for other in all:
				if not _groups.has(other.get_instance_id()) and touching(here, other):
					_groups[other.get_instance_id()] = next
					queue.append(other)
		next += 1

# Humming Walls: the route points a Thornwall (twig walls too) touches.
func _board_walls() -> void:
	_wall_side.clear()
	if not evo(EVO_WALLS):
		return
	for tower in towers():
		if is_wall(tower):
			for i in points_touching(tower):
				_wall_side[i] = true

# Sounding Board's outer ring and Ensemble's families. A joined Warden: another Warden (Sprouts too) touching a bell.
func _board_joined(all: Array) -> void:
	_outer.clear()
	_families.clear()
	if not (evo(EVO_SOUNDING) or evo(EVO_ENSEMBLE)):
		return
	var others: Array = towers().filter(is_other)
	var joined := {}  # Warden id -> the bell it touches (the nearest)
	for tower in others:
		var bell = _bell_touching(tower, all)
		if bell != null:
			joined[tower.get_instance_id()] = bell
			var lines: Dictionary = _families.get(bell.get_instance_id(), {})
			lines["sprout" if tower.tower_data.get_id() == "sprout" else tower.tower_data.line] = true
			_families[bell.get_instance_id()] = lines
	if not evo(EVO_SOUNDING):
		return
	for tower in others:
		if joined.has(tower.get_instance_id()):
			continue
		for middle in others:
			if joined.has(middle.get_instance_id()) and touching(tower, middle):
				_outer[tower.get_instance_id()] = joined[middle.get_instance_id()]
				break

# The nearest bell touching `tower`, or null.
func _bell_touching(tower, all: Array):
	var best = null
	var best_d := INF
	for bell in all:
		if touching(bell, tower):
			var d: float = bell.global_position.distance_squared_to(tower.global_position)
			if d < best_d:
				best_d = d
				best = bell
	return best

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
# `by`: the evolution whose ring this is (Lingering Note, Carrying Tune): its pip is credited to it.
func ring(enemy, bell, amount: float, counted: bool = false, filler = null, by: StringName = &"") -> void:
	if not living(enemy) or not is_instance_valid(bell) or not tolls_on():
		return
	var fresh: bool = not enemy.has_meta(PIPS_META)
	var pips := _start_for(enemy) if fresh else int(enemy.get_meta(PIPS_META))
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
			_pip_by(enemy, EVO_HAND, HAND_PIPS - 1)
		if evo(EVO_DEEP) and not counted and by == &"" and int(bell.rank) >= DEEP_RANK and add < DEEP_PIPS:
			_pip_by(enemy, EVO_DEEP, DEEP_PIPS - add)  # Deep Tone: a rank III+ bell's own hit rings twice
			add = DEEP_PIPS
			Reactions._effect(&"toll_ring", enemy.global_position, self, 0.6)
		var real := add  # Midnight counts real rings: never a prime
		if enemy.has_meta(PRIMED_META):  # Down the Line: a primed nightmare's next ring counts 1 more (spent; read at its Toll)
			add += 1
			enemy.set_meta(CHAIN_META, enemy.get_meta(PRIMED_META))
			enemy.remove_meta(PRIMED_META)
			_pip_by(enemy, EVO_DOWN, 1)
		if evo(EVO_STEADY):
			_note_group(enemy, bell)
		if by != &"":
			_pip_by(enemy, by, 1)
		elif evo(EVO_ACCOMP) and is_instance_valid(filler):
			_pip_by(enemy, EVO_ACCOMP, 1)  # Another Warden's hit rang it: Accompaniment's pip
		pips += add
		if evo(EVO_ACCOMP):
			_fill(enemy, pips - add, add, filler if is_instance_valid(filler) else bell, is_instance_valid(filler))
		if evo(EVO_MIDNIGHT) and _count_rings(enemy, real):
			_midnight(enemy, bell)
			if not living(enemy):
				return
	enemy.set_meta(RING_META, now())
	var need := _toll_need(enemy)
	if pips < need and not answered and not overture and not _allegro_spend(enemy, bell, counted):
		enemy.set_meta(PIPS_META, pips)
		return
	if now() < float(enemy.get_meta(TOLL_META, -INF)):
		if not answered and not overture and not counted:
			_allegro_keep(bell)  # Allegro: the wait stopped this bell's Toll: a rank V+ bell keeps it
		enemy.set_meta(PIPS_META, mini(pips, need - 1))  # It waits a pip short: one Toll a second
		return
	enemy.set_meta(TOLL_NEED_META, need)
	enemy.set_meta(PIPS_META, 0)
	enemy.set_meta(TOLL_META, now() + TOLL_WAIT)
	_toll(enemy, bell, amount, overture, counted, filler)
	if living(enemy) and evo(EVO_DOUBLE) and int(bell.rank) >= DOUBLE_RANK:
		enemy.set_meta(PIPS_META, DOUBLE_PIPS)  # Double Time: 2 rings into its next Toll, not back at the start
		_pip_by(enemy, EVO_DOUBLE, DOUBLE_PIPS)
		credit(EVO_DOUBLE, enemy.global_position, bell)

# Steady Beat: the group of every ring since the nightmare's last Toll (-1 once a second group rings it).
func _note_group(enemy, bell) -> void:
	var group := int(_groups.get(bell.get_instance_id(), -1))
	if not enemy.has_meta(GROUP_META):
		enemy.set_meta(GROUP_META, group)
	elif int(enemy.get_meta(GROUP_META)) != group:
		enemy.set_meta(GROUP_META, -1)

# Allegro: the 1 s wait stopped a rank V+ bell's Toll: the bell keeps it (up to ALLEGRO_BANK).
func _allegro_keep(bell) -> void:
	if not evo(EVO_ALLEGRO) or int(bell.rank) < ALLEGRO_RANK:
		return
	var bank := int(bell.get_meta(ALLEGRO_META, 0))
	if bank >= ALLEGRO_BANK:
		return
	bell.set_meta(ALLEGRO_META, bank + 1)
	Reactions._effect(&"chorus_note", bell.global_position, self, 0.5)

# Allegro: a kept Toll spent on a ready nightmare this bell rings that would not Toll on this ring. True: it Tolls now.
func _allegro_spend(enemy, bell, counted: bool) -> bool:
	if counted or not evo(EVO_ALLEGRO) or now() < float(enemy.get_meta(TOLL_META, -INF)):
		return false
	var bank := int(bell.get_meta(ALLEGRO_META, 0))
	if bank <= 0:
		return false
	bell.set_meta(ALLEGRO_META, bank - 1)
	_line_fx(bell.global_position, enemy.global_position, 1.5, Palette.EMBER)
	credit(EVO_ALLEGRO, enemy.global_position, bell)
	return true

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
	var chain: Dictionary = {}
	if evolved:
		roster = enemy.get_meta(FILLERS_META, [])
		enemy.remove_meta(FILLERS_META)
		full = evo(EVO_STEADY) and int(enemy.get_meta(TOLL_NEED_META, TOLL_EVERY)) < TOLL_EVERY  # Steady Beat: in full
		enemy.remove_meta(GROUP_META)
		enemy.remove_meta(WALL_DONE_META)  # Humming Walls: one wall pip between Tolls
		enemy.remove_meta(WALL_PIP_META)
		chain = enemy.get_meta(CHAIN_META, {})
		enemy.remove_meta(CHAIN_META)
		if evo(EVO_CRESCENDO):
			var n := int(enemy.get_meta(CRESC_META, 0))
			swell = minf(1.0 + CRESC_STEP * n, CRESC_MAX)
			enemy.set_meta(CRESC_META, n + 1)
	# The Toll is always the bell's (rebuilt 2026-10-23: Accompaniment's partner no longer strikes it; its hit repeats beside it)
	var partner = filler if evolved and is_instance_valid(filler) and filler != bell else null
	enemy.set_meta(TOLLED_META, true)
	_toll_wave(enemy, at)
	_toll_flashes.append({"enemy": weakref(enemy), "at": at, "start": now()})  # The rings burst (drawn in _draw_pips)
	# Setup credit 2026-10-16: what Rising Song adds to the Toll is its own damage (a multiplier)
	if share > TOLL_SHARE:
		DamageLog.note_card_bonus(card_id(RISING_SONG), share / TOLL_SHARE)
	_note_pip_shares(enemy)  # The pips evolutions filled: their share of this Toll (owner 2026-10-19)
	# evo_shared_spec.md 2-3: the Toll is a Calling hit, damage only (never an F1 output, never a hit for another card).
	# The ring's hit was already final (before defences), so it lands as given; its own throttle is 1 a second per nightmare.
	var landing := calling_hit(bell, enemy, amount * share, &"toll", &"", false, false, &"")
	DamageLog.drop_card_shares()
	var part := TOLL_SHARE  # Steady Beat and Crescendo: their own parts of the Toll, from the bell's hit
	if full and living(enemy):
		landing += calling_hit(bell, enemy, STEADY_EXTRA, &"toll", EVO_STEADY, false, true, &"")
		part += STEADY_EXTRA
		Reactions._effect(&"toll_ring", at, self, 0.8)
	if swell > 1.0 and living(enemy):
		landing += calling_hit(bell, enemy, (swell - 1.0) * part, &"toll", EVO_CRESCENDO, false, true, &"")
	if partner != null:
		_accompanied(partner, enemy, at, bell)
	if evolved:
		_evolved_toll(enemy, bell, at, landing, amount, roster, partner, chain)
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

# A Toll's bell-ring wave (Tower Assets cb907eb6): keeping_toll (64x48, 8 frames, 14 fps one-shot) bursting from the
# nightmare's body centre (anchor (32, 30)), over it. The ring arcs under the health bar and their gold burst stay
# (_toll_flashes). Reduced motion: frame 1 alone. Without the sheet: the old dust puff at its feet.
# (toll_pip.png stays unused: the owner replaced the pips with rings, 2026-10-17/18.)
const TOLL_WAVE := &"keeping_toll"
const TOLL_WAVE_STILL := 1

func _toll_wave(enemy, at: Vector2) -> void:
	if Fx.texture(TOLL_WAVE) == null:
		Reactions._effect(&"landing_dust", at, self, 0.5)
		return
	var body: Vector2 = enemy.get_body_position() if is_instance_valid(enemy) and enemy.has_method("get_body_position") else at
	var node := Reactions._effect(TOLL_WAVE, body, self)
	if node != null and motion_still():
		node.set("still", TOLL_WAVE_STILL)

# --- Calling evolutions: what a ring and a Toll add (see the EVO_ constants) ----------------------------------------------

# Everything an evolution adds to a Toll, after it landed. `at`: where it was; `landing`: what it dealt; `amount`: the
# ring's hit; `roster`: who filled its pips; `partner`: another Warden's Toll (Accompaniment).
func _evolved_toll(enemy, bell, at: Vector2, landing: float, amount: float, roster: Array, partner, chain: Dictionary) -> void:
	if evo(EVO_PEAL):
		_peal(enemy, at, bell)
	if evo(EVO_DOWN):
		_prime(enemy, at, chain)
	if evo(EVO_NOTE):
		_hang_note(bell, at, amount, true, enemy)
		Reactions._effect(&"chorus_note", at, self, 0.6)
	if not living(enemy):
		return
	if evo(EVO_HALL) and now() < float(enemy.get_meta(HALL_META, -INF)):
		_hall(enemy, bell, at, landing)
	if evo(EVO_COUNTER) and living(enemy):
		_counterpoint(enemy, at, roster, partner, bell)
	if evo(EVO_SYMPHONY) and living(enemy):
		_symphony(enemy, roster, at)
	if evo(EVO_HUSH) and living(enemy):
		_hushabye(enemy, bell)
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

# Fills one pip without a ring (Peal, Counterpoint): never the last one, so only a real ring Tolls. `by`: the evolution
# credited with the pip (its share of the Toll it leads to).
func _add_pip(enemy, who = null, by: StringName = &"") -> bool:
	var pips := int(enemy.get_meta(PIPS_META)) if enemy.has_meta(PIPS_META) else _start_for(enemy)
	if pips >= _toll_need(enemy) - 1:
		return false
	if evo(EVO_ACCOMP):
		_fill(enemy, pips, 1, who, false)
	enemy.set_meta(PIPS_META, pips + 1)
	_pip_by(enemy, by, 1)
	return true

# Damage credit (owner 2026-10-19): `count` pips toward the next Toll were evolution `id`'s.
func _pip_by(enemy, id: StringName, count: int) -> void:
	if id == &"" or count <= 0 or not is_instance_valid(enemy):
		return
	var by: Dictionary = enemy.get_meta(PIP_BY_META, {})
	by[id] = int(by.get(id, 0)) + count
	enemy.set_meta(PIP_BY_META, by)

# A Toll: each evolution's pips are that share of it (the need the Toll was made at: 4, Steady Beat's 3); spent with it.
func _note_pip_shares(enemy) -> void:
	if not enemy.has_meta(PIP_BY_META):
		return
	var by: Dictionary = enemy.get_meta(PIP_BY_META)
	enemy.remove_meta(PIP_BY_META)
	var need := maxi(int(enemy.get_meta(TOLL_NEED_META, TOLL_EVERY)), 1)
	for id in by:
		DamageLog.note_card_share(card_id(id), minf(float(by[id]) / float(need), 1.0))

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

# Carrying Tune for a shooting bell: the ring carries TUNE_STEPS down the path from its target to up to TUNE_MAX
# nightmares, stopping at the next bell's reach. Carried rings fill pips and deal nothing (rebuilt 2026-10-23: the
# carried half strike is gone); they pass the bell's whole hit, so a Toll they make lands at the normal half.
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
		ring(enemy, bell, base, false, null, EVO_CARRYING)
		carried += 1
	if carried > 0:
		credit(EVO_CARRYING, from, bell)

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
	credit(EVO_HAND, enemy.global_position, bell)

# Peal: a Toll fills 1 pip on every nightmare within 4 steps (up to 8), never its last pip.
func _peal(enemy, at: Vector2, bell = null) -> void:
	var i0 := index_of(enemy) if living(enemy) else nearest_point(at, 1.0)
	var filled := 0
	var change := evo(EVO_CHANGE)
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
		if _add_pip(other, null, EVO_PEAL):
			filled += 1
			_line_fx(at, other.global_position, 1.0, Palette.GOLD)
		if change:
			_change_ring(other, bell)
	if filled > 0:
		Reactions._effect(&"toll_ring", at, self, 1.2)
		credit(EVO_PEAL, at)

# Change Ringing: a Peal reached `other` in another bell's range: that bell rings it too, at half its hit (each bell once a
# second). Queued for the next tick (_tick_later), never inside the Peal's loop, so Toll -> Peal -> ring -> Toll never
# recurses in one frame.
func _change_ring(other, tolling) -> void:
	for bell in bells():
		if bell == tolling or not _in_reach(bell, other) or now() < float(bell.get_meta(CHANGE_META, -INF)):
			continue
		bell.set_meta(CHANGE_META, now() + CHANGE_EVERY)
		_later.append({"at": now(), "tower": weakref(bell), "enemy": weakref(other), "amount": bell.get_damage() * CHANGE_SHARE,
			"tag": &"toll", "again": false, "own": EVO_CHANGE, "ring": true})
		return

# Down the Line / Both Ways: a Toll primes the nearest walker behind it (Both Ways: and ahead) within PRIME_STEPS on its
# leg; its next ring counts 1 more. A Toll whose own prime it spent continues only that way, PRIME_DEPTH in a row; an
# unprimed Toll starts each way at 1. Forward and back never feed each other. Never flyers.
func _prime(enemy, at: Vector2, chain: Dictionary) -> void:
	if not is_instance_valid(enemy) or enemy.is_flying():
		return
	var i0 := index_of(enemy)
	if i0 < 0:
		return
	var both := evo(EVO_BOTH)
	var ways := {}
	if chain.is_empty():
		ways[BACK] = 1
		if both:
			ways[AHEAD] = 1
	else:
		if chain.has(BACK):
			ways[BACK] = int(chain[BACK]) + 1
		if chain.has(AHEAD) and both:
			ways[AHEAD] = int(chain[AHEAD]) + 1
	var passed := bool(enemy.get("passed_waymark"))
	for way in ways:
		var depth := int(ways[way])
		if depth > PRIME_DEPTH:
			continue
		var target = _next_on_route(enemy, at, i0, passed, way == AHEAD)
		if target == null:
			continue
		var primed: Dictionary = target.get_meta(PRIMED_META, {})
		if primed.has(way):
			continue
		primed[way] = depth
		target.set_meta(PRIMED_META, primed)
		_line_fx(at, target.global_position, 1.5, Palette.EMBER)  # A bronze spark hops down the file
		credit(EVO_BOTH if way == AHEAD else EVO_DOWN, target.global_position)

# The nearest walker on the same leg behind (or ahead of) route index `i0`, within PRIME_STEPS, or null.
func _next_on_route(enemy, at: Vector2, i0: int, passed: bool, ahead: bool):
	var best = null
	var best_gap := PRIME_STEPS * 2 + 1
	for other in Tower.nightmares_near(get_tree(), at, (PRIME_STEPS + 1) * cell()):
		if other == enemy or not living(other) or other.is_flying() or bool(other.get("passed_waymark")) != passed:
			continue
		var j := index_of(other)
		if j < 0:
			continue
		var gap := j - i0 if ahead else i0 - j
		if gap > 0 and gap < best_gap:
			best_gap = gap
			best = other
	return best

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
		calling_strike(tower, enemy, hit, &"chorus_repeat", false, EVO_CHOIR)  # (own: setup credit 2026-10-16)
		sang += 1
	if sang > 0:
		credit(EVO_CHOIR, note.at)
	Reactions._effect(&"chorus_note", note.at, self, 0.5)
	credit(EVO_NOTE, note.at)
	ring(enemy, bell, float(note.amount), false, null, EVO_NOTE)

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
# The Midnight Toll (rebuilt 2026-10-23: the status payoffs and the final-form x5 are gone): the bell hits it for triple,
# with Crescendo, as a Calling hit (form x1.4 inside, capped at 3 x a second of its damage). Bosses half. `wave`: one Twelfth
# Hour started (it never starts another).
func _midnight(enemy, bell, wave: bool = false) -> void:
	var at: Vector2 = enemy.global_position
	var own := EVO_TWELFTH if wave else EVO_MIDNIGHT
	_clocks.append({"enemy": weakref(enemy), "at": at, "until": now() + MIDNIGHT_SECONDS})
	Reactions._effect(&"toll_ring", at, self, 1.4)
	if not (bell is Tower and is_instance_valid(bell)):
		credit(own, at)
		return
	var swell := minf(1.0 + CRESC_STEP * int(enemy.get_meta(CRESC_META, 0)), CRESC_MAX) if evo(EVO_CRESCENDO) else 1.0
	calling_hit(bell, enemy, MIDNIGHT_TRIPLE * swell, &"toll", own, false, true, &"", MIDNIGHT_BOSS)  # Once per nightmare: its own throttle
	if not wave and evo(EVO_TWELFTH):
		_twelfth(enemy, bell)

# Twelfth Hour: up to TWELFTH_OTHERS other nightmares in that bell's range with TWELFTH_RINGS or more rings (and no Midnight
# yet) strike their own Midnight, nearest first, TWELFTH_GAP s apart (queued on _later).
func _twelfth(enemy, bell) -> void:
	var at: Vector2 = enemy.global_position
	var found: Array = []
	for other in enemies():
		if other != enemy and not other.has_meta(MIDNIGHT_META) and int(other.get_meta(RINGS_META, 0)) >= TWELFTH_RINGS \
				and _in_reach(bell, other):
			found.append(other)
	found.sort_custom(func(a, b) -> bool: return a.global_position.distance_squared_to(at) < b.global_position.distance_squared_to(at))
	var k := 0
	for other in found.slice(0, TWELFTH_OTHERS):
		k += 1
		other.set_meta(MIDNIGHT_META, true)  # Each nightmare still has one Midnight
		_later.append({"at": now() + TWELFTH_GAP * k, "tower": weakref(bell), "enemy": weakref(other), "amount": 0.0,
			"tag": &"toll", "again": false, "midnight": true})

# Hush-a-bye: a Toll adds 2 Drowsy (the bell's, never native: no lent card reads it); 3 Tolls within 6 s and it naps.
func _hushabye(enemy, bell) -> void:
	var at: Vector2 = enemy.global_position
	calling_apply(EVO_HUSH, bell, enemy, EnemyStatuses.DROWSY, HUSH_DROWSY, bell.get_damage())  # (setup credit 2026-10-16)
	if not living(enemy):
		return
	if enemy.statuses.has(EnemyStatuses.DROWSY):
		enemy.flash_status(EnemyStatuses.DROWSY)
		credit(EVO_HUSH, at, bell)
	var times: Array = (enemy.get_meta(HUSH_META, []) as Array).filter(func(t) -> bool: return now() - float(t) <= HUSH_WINDOW)
	times.append(now())
	if times.size() >= HUSH_TOLLS and now() >= float(enemy.get_meta(HUSH_NEXT_META, -INF)) and nap(enemy):
		enemy.set_meta(HUSH_NEXT_META, now() + HUSH_EVERY)
		enemy.set_meta(HUSHED_META, true)
		control(EVO_HUSH, NAP_SECONDS)  # (setup credit 2026-10-16)
		times.clear()
		Reactions._effect(&"chorus_note", at, self, 1.0)
		credit(EVO_HUSH, at, bell)
	enemy.set_meta(HUSH_META, times)

# Sleeping Hall: the first Toll within 3 s of a Hush-a-bye nap ending also lands on up to 4 nightmares touching it, at half.
func _hall(enemy, bell, at: Vector2, landing: float) -> void:
	enemy.remove_meta(HALL_META)
	var hit := 0
	for other in _touching_at(at, enemy, HALL_OTHERS):
		_line_fx(at, other.global_position, 2.0, Palette.BLOSSOM)
		calling_strike(bell, other, landing * HALL_SHARE, &"toll", true, EVO_HALL)  # (own: setup credit 2026-10-16)
		hit += 1
	if hit > 0:
		Reactions._effect(&"toll_ring", at, self, 1.3)
		credit(EVO_HALL, at, bell)

# Accompaniment (rebuilt 2026-10-23): another Warden filled the Toll's last pip: the bell's Toll landed, and that Warden's
# hit repeats beside it at half (damage only: its status never comes again). Tenor Bell: in full; Ensemble: once more later.
func _accompanied(partner, enemy, at: Vector2, bell) -> void:
	_line_fx(partner.global_position, at, 2.0, Palette.BLOSSOM)
	var dealt := _repeat(partner, enemy, EVO_ACCOMP, ACCOMP_SHARE)
	if dealt > 0.0:
		credit(EVO_ACCOMP, at, bell)
		_ensemble(partner, enemy, bell, dealt)

# A joined Warden's last hit (before defences) lands again: min(hit, a second of its damage) x `share` (Tenor Bell: in
# full for a form whose base rate is at most once a second). Damage only (chorus_repeat). Returns what it dealt.
func _repeat(tower, enemy, own: StringName, share: float) -> float:
	if not (tower is Tower) or not is_instance_valid(tower) or not living(enemy) or not _last_hit_of.has(tower.get_instance_id()):
		return 0.0
	if evo(EVO_TENOR) and tower.attack_data != null and tower.attack_data.attacks_per_second <= TENOR_RATE:
		share = 1.0  # The form's speed, never get_attacks_per_second(): Dreams that quicken it don't take this away
		own = EVO_TENOR
	var amount := minf(float(_last_hit_of[tower.get_instance_id()]), second_of(tower)) * share
	if amount <= 0.0:
		return 0.0
	strike(tower, enemy, amount, &"chorus_repeat", false, own)
	if own == EVO_TENOR:
		credit(EVO_TENOR, enemy.global_position, tower)
	return amount

# Ensemble: around a bell touching Wardens of ENSEMBLE_FAMILIES other families (Sprouts as one), a repeat of one of those
# touching Wardens lands again ENSEMBLE_DELAY s later at half. Walls, bells and Sounding Board's outer ring never count.
func _ensemble(tower, enemy, bell, dealt: float) -> void:
	if not evo(EVO_ENSEMBLE) or not is_instance_valid(bell) or not touching(tower, bell):
		return
	if (_families.get(bell.get_instance_id(), {}) as Dictionary).size() < ENSEMBLE_FAMILIES:
		return
	_later.append({"at": now() + ENSEMBLE_DELAY, "tower": weakref(tower), "enemy": weakref(enemy), "amount": dealt * ENSEMBLE_SHARE,
		"tag": &"chorus_repeat", "again": false, "own": EVO_ENSEMBLE})

# The base a counted ring carries: the bell's own last hit (Accompaniment's Toll is always the bell's), else its damage.
func _bell_base(bell) -> float:
	return float(_last_hit_of.get(bell.get_instance_id(), bell.get_damage()))

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
	if bell == null and evo(EVO_SOUNDING):  # Sounding Board: a Warden touching a joined Warden joins that bell's song
		var outer = _outer.get(source.get_instance_id())
		if is_instance_valid(outer):
			bell = outer
	if bell == null:
		return false
	if source.tower_data.get_id() != "sprout":
		if now() < float(source.get_meta(JOIN_META, -INF)):
			return true
		source.set_meta(JOIN_META, now() + ACCOMP_EVERY)
	_line_fx(source.global_position, bell.global_position, 1.0, Palette.BLOSSOM)
	ring(enemy, bell, _bell_base(bell), true, source)  # The Toll it makes is the bell's (rebuilt 2026-10-23)
	return true

# Counterpoint (rebuilt 2026-10-23: the old "nearest bell answers" is gone): a Toll also repeats, at half, the hit of the
# newest other noted Warden (not the partner whose hit Accompaniment repeats). Each Warden once a second.
func _counterpoint(enemy, at: Vector2, roster: Array, partner, bell) -> void:
	var skip: int = partner.get_instance_id() if is_instance_valid(partner) else 0
	var noted := _noted_roster(roster)
	for k in range(noted.size() - 1, -1, -1):
		var id := int(noted[k])
		if id == skip or not is_instance_id_valid(id):
			continue
		var tower = instance_from_id(id)
		if not (tower is Tower) or now() < float(tower.get_meta(COUNTER_META, -INF)) or not _last_hit_of.has(id):
			continue
		tower.set_meta(COUNTER_META, now() + COUNTER_EVERY)
		_line_fx(tower.global_position, at, 1.5, Palette.BLOSSOM)
		var dealt := _repeat(tower, enemy, EVO_COUNTER, COUNTER_SHARE)
		if dealt > 0.0:
			credit(EVO_COUNTER, at, bell)
			_ensemble(tower, enemy, bell, dealt)
		return

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
		# evo_shared_spec.md 2: a Calling hit (damage only, no F1 arm); the stored hit is final, so it lands as given
		calling_hit(tower, enemy, minf(float(_last_hit_of[id]) * SYMPHONY_SHARE, second_of(tower)), &"chorus_repeat", EVO_SYMPHONY,
			false, false, &"")
		if evo(EVO_CODA):
			tower.set_meta(CODA_META, now() + CODA_SECONDS)  # Coda: it keeps its note (one per Warden per Symphony)
		sang += 1
	if sang > 0:
		Reactions._effect(&"chorus_note", at, self, 1.2)

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
		calling_apply(EVO_CHIME, tower, target, status, int(last[2]), tower.get_damage())  # (setup credit 2026-10-16)
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
	if DreamState.undiluted_on:
		# Undiluted holds every Reaction back (owner 2026-10-22, dream_council_review.md 30): the quiet Last Chord tops
		# each status it carries back up to its landing time instead, on the same 8 s wait
		for id in enemy.statuses.active_ids():
			enemy.statuses.top_up(id)
		enemy.set_meta(CHORD_META, now() + CHORD_EVERY)
		Reactions._effect(&"chorus_note", at, self, 1.0)
		credit(EVO_CHORD, at, bell)
		return
	var health: float = enemy.health
	var changes: int = enemy.statuses.changes
	Reactions.check_at_half(enemy, bell)
	if living(enemy) and enemy.health >= health and enemy.statuses.changes == changes:
		return  # Nothing went off
	# Damage credit (owner 2026-10-19): what it set off is Last Chord's, the half no feeder takes (setup credit gives the
	# Reaction's feeders the other half: never counted twice)
	var dealt: float = health - maxf(float(enemy.health), 0.0) if is_instance_valid(enemy) else 0.0
	if dealt > 0.0 and dream_state != null:
		dream_state._credit(card_id(EVO_CHORD), "damage", dealt * (1.0 - SETUP.SETUP_SHARE))
	enemy.set_meta(CHORD_META, now() + CHORD_EVERY)
	Reactions._effect(&"chorus_note", at, self, 1.4)
	credit(EVO_CHORD, at, bell)

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

# Knell (lent; hard cards 2026-10-16, one rule for every status): a bell's hit lands again once for each status on the
# nightmare ({held} never counts), up to KNELL_REPEATS_MAX, KNELL_REPEAT_GAP s apart, each adding 1 of the bell's own
# status (not native: no class / cooperation / role extras). Owner 2026-10-18, bell_lent_review.md: every status counts,
# the bell's own too (counted even before this hit's application lands), so a bell alone has its 1. Repeats are tagged
# `knell` (a class tag: they never set In Time, Refrain or Knell off again). Nothing is used up. The repeats queued, each
# showing a chime mark in the colour of one counted status.
func _knell(enemy, bell, base: float) -> int:
	var statuses: EnemyStatuses = enemy.statuses
	var counted: Array = []
	for id in statuses.active_ids():
		if id != EnemyStatuses.HELD:
			counted.append(id)
	var own := status_of(bell)
	if own != &"" and own != EnemyStatuses.HELD and not counted.has(own):
		counted.append(own)
	var count := mini(counted.size(), KNELL_REPEATS_MAX)
	if count <= 0:
		return 0
	var share := KNELL_PULSE_SHARE if is_pulsing(bell) else KNELL_REPEAT_SHARE
	for k in range(1, count + 1):
		_later.append({"at": now() + KNELL_REPEAT_GAP * k, "tower": weakref(bell), "enemy": weakref(enemy),
			"amount": base * share, "tag": &"knell", "again": true, "status": own, "chime": counted[k - 1], "chime_k": k})
	credit(KNELL, enemy.global_position, bell)
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
# Refrain), any Warden's status (Second Verse remembers the last few).
func status_applied(tower, enemy, status: StringName, stacks: int) -> void:
	if not living(enemy):
		return
	if evo(EVO_CHIME) and status != EnemyStatuses.DROWSY and status != EnemyStatuses.HELD and stacks > 0:
		enemy.set_meta(CHIME_META, [weakref(tower), status, stacks])  # Chime of Many: the last status hit, for its next Toll
	if is_own(tower) and status == EnemyStatuses.DROWSY and not _in_calling_event:  # F1: never Nod Off (control stays bounded)
		if rule(NOD_OFF) and not enemy.has_meta(DROWSED_META):
			# Nod Off: the first time a bell makes it Drowsy, it naps 1 s (one sleeper for each bell; never bosses)
			var sleeper = tower.get_meta(SLEEPER_META).get_ref() if tower.has_meta(SLEEPER_META) else null
			if not (living(sleeper) and sleeper.statuses.is_asleep()) and nap(enemy):
				tower.set_meta(SLEEPER_META, weakref(enemy))
				control(NOD_OFF, NAP_SECONDS)  # (setup credit 2026-10-16)
		enemy.set_meta(DROWSED_META, true)
	if rule(SECOND_VERSE) and status != EnemyStatuses.HELD and stacks > 0 and tower is Tower:
		# Second Verse (owner 2026-10-18, bell_lent_review.md): any Warden's status, bells and Drowsy too (was another
		# family's, never Drowsy); each Warden's last application, the newest VERSE_KEEP Wardens, so the leaving bell's own
		# hits never push another Warden's out
		var kept: Array = enemy.get_meta(LAST_OTHER_META) if enemy.has_meta(LAST_OTHER_META) and enemy.get_meta(LAST_OTHER_META) is Array else []
		if not kept.is_empty() and not (kept[0] is Array):
			kept = []  # (An older [status, stacks] entry)
		var id: int = tower.get_instance_id()
		kept = kept.filter(func(row) -> bool: return int(row[2]) != id)
		kept.append([status, stacks, id, now()])
		while kept.size() > VERSE_KEEP:
			kept.remove_at(0)
		enemy.set_meta(LAST_OTHER_META, kept)

# --- Damage events ------------------------------------------------------------------------------------------------------

# Reprise listens to Reactions, which every other class card ignores (class_kit filters them out).
func _on_damage(event) -> void:
	if dream_state != null and rule(REPRISE) and is_instance_valid(event.enemy) and is_reaction_burst(event):
		_reprise(event)
	super._on_damage(event)

func on_damage(event, source, enemy, is_hit: bool, dispel: bool, tagged: bool) -> void:
	if dispel and is_hit and rule(ENCORE) and not _in_calling_event:  # (F1: attack-shaped cards never hear a Calling output)
		_encore(source)  # A hit's dispel only (a status tick's never counts)
	if is_hit and not tagged and source != null and (evo(EVO_ACCOMP) or evo(EVO_CHOIR)):
		_last_hit_of[source.get_instance_id()] = float(event.base)  # Support repeats, Night Choir: each Warden's last hit, before defences
	if tagged or source == null or not is_hit:
		return
	if evo(EVO_CODA) and living(enemy) and now() < float(source.get_meta(CODA_META, -INF)):
		_coda(source, enemy, float(event.base))
	if rule(DA_CAPO) and is_own(source) and not _in_calling_event:  # (F1: attack-shaped, never a Calling output)
		_da_capo(source)  # Its own hit, a dispel too (an area attack's hits in one frame: one attack)
	if not living(enemy):
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
		if rule(ON_THE_BEAT) and not _in_calling_event and int(source.get_meta(BEAT_FRAME_META, -1)) != Engine.get_process_frames():
			source.set_meta(BEAT_FRAME_META, Engine.get_process_frames())
			_beat(source)
		if rule(RINGING_EARS):
			_ears_note(source, enemy)
		# Knell (hard cards 2026-10-16; owner 2026-10-18, bell_lent_review.md): a bell's hit lands again once per status
		# on it, its own too, up to 3. Each nightmare once every 6 s
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

# Coda: a Warden that played in a Symphony keeps its note CODA_SECONDS; its next hit, on any nightmare, lands again at half
# (never more than a second of its damage). Damage only; the note is spent.
func _coda(tower, enemy, base: float) -> void:
	tower.remove_meta(CODA_META)
	var amount := minf(base, second_of(tower)) * CODA_SHARE
	if amount <= 0.0:
		return
	_line_fx(tower.global_position, enemy.global_position, 1.5, Palette.BLOSSOM)
	strike(tower, enemy, amount, &"chorus_repeat", false, EVO_CODA)
	credit(EVO_CODA, enemy.global_position, tower)

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

# A hit lands again now (In Time's delayed repeat, Refrain, Knell, Rude Awakening): damage only. Nothing repeats a repeat
# (owner 2026-10-18, bell_lent_review.md: Da Capo's third hit is gone; every repeat's tag is in CLASS_TAGS). Each card
# looks its own: In Time and Rude Awakening a blossom thread, Refrain a double flash (`look` &"double"), Knell a chime
# mark per counted status (`look` &"none" here; _tick_later shows the chime).
func _again(tower, enemy, amount: float, tag: StringName, look: StringName = &"thread") -> void:
	if not is_instance_valid(tower) or not living(enemy):
		return
	if look == &"thread":
		_line_fx(tower.global_position, enemy.global_position, 1.5, Palette.BLOSSOM)
	elif look == &"double":
		_double_flash(enemy.global_position)
	strike(tower, enemy, amount, tag)
	if tower is Tower and living(enemy):
		tower.note_repeat_hit(enemy)  # Keyword chips 2026-10-16: a repeat counts for Eternal Static / Rooted Nightmares

# Refrain's look: two quick flashes on the partner's hit (owner 2026-10-18, bell_lent_review.md (c)).
const FLASH_GAP := 0.12
func _double_flash(at: Vector2) -> void:
	Reactions._effect(&"echo", at, self, 0.5)
	_fx_after(FLASH_GAP, &"echo", at, 0.5)

# An Fx sheet played `delay` s from now (the second beat of a two-beat look).
func _fx_after(delay: float, effect: StringName, at: Vector2, scale: float) -> void:
	if is_inside_tree():
		get_tree().create_timer(delay, false).timeout.connect(_play_fx.bind(effect, at, scale))

func _play_fx(effect: StringName, at: Vector2, scale: float) -> void:
	if is_inside_tree():
		Reactions._effect(effect, at, self, scale)

# Knell's look: a quick chime mark over the nightmare in the colour of the k-th status it counted (status_flash's rows are
# EnemyStatuses.COLORS), each a little higher than the last.
const CHIME_RISE := Vector2(0.0, -10.0)
const CHIME_BASE := Vector2(0.0, -30.0)
func _knell_chime(enemy, status: StringName, k: int) -> void:
	var world := Reactions._world(self)
	if world != null and living(enemy) and status != &"":
		Fx.status_flash(status, enemy.global_position + CHIME_BASE + CHIME_RISE * float(k - 1), world)

# Da Capo (owner 2026-10-18, bell_lent_review.md): a bell's attack landed; when its clock is due, its next attack comes at
# once (a whole real attack, statuses too; its wait reset as Curtain Call does). Next due: DA_CAPO_EVERY s of drift time,
# or DA_CAPO_MIN_ATTACKS of its own attacks if those take longer. A bell's first attack in a drift starts its clock.
func _da_capo(bell) -> void:
	if resting() or not bell.tower_data.can_attack:
		return
	var id: int = bell.get_instance_id()
	var period: float = 1.0 / maxf(bell.get_attacks_per_second(), 0.01)
	var wait := maxf(DA_CAPO_EVERY, DA_CAPO_MIN_ATTACKS * period)
	if not _da_capo_due.has(id):
		_da_capo_due[id] = _drift_clock + wait
		return
	if _drift_clock < float(_da_capo_due[id]):
		return
	_da_capo_due[id] = _drift_clock + wait
	bell._cooldown = 0.0
	Reactions._effect(&"landing_dust", bell.global_position, self, 0.5)  # The two-beat pulse: dust and a bell glow…
	Reactions._effect(&"area_pulse_song", bell.global_position, self, 0.4)
	_fx_after(DA_CAPO_BEAT, &"area_pulse_song", bell.global_position, 0.4)  # …and the second beat
	credit(DA_CAPO, bell.global_position, bell)

func _tick_later() -> void:
	for i in range(_later.size() - 1, -1, -1):
		var row: Dictionary = _later[i]
		if now() < float(row.at):
			continue
		_later.remove_at(i)
		var tower = row.tower.get_ref()
		var enemy = row.enemy.get_ref()
		if bool(row.get("midnight", false)):  # Twelfth Hour: its own Midnight
			if is_instance_valid(tower) and living(enemy):
				_midnight(enemy, tower, true)
			continue
		var own: StringName = row.get("own", &"")
		if own != &"" and not bool(row.again):  # Change Ringing, Ensemble: an evolution's queued hit (damage only)
			if is_instance_valid(tower) and living(enemy):
				_line_fx(tower.global_position, enemy.global_position, 1.5, Palette.BLOSSOM)
				strike(tower, enemy, float(row.amount), row.tag, false, own)
				credit(own, enemy.global_position, tower)
				if bool(row.get("ring", false)) and living(enemy):
					ring(enemy, tower, tower.get_damage(), false, null, own)  # Change Ringing: then a real ring (it may Toll)
			continue
		if bool(row.again):
			var knell: bool = row.tag == &"knell"
			if knell:
				_knell_chime(enemy, row.get("chime", &""), int(row.get("chime_k", 1)))
			_again(tower, enemy, float(row.amount), row.tag, &"none" if knell else &"thread")
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
		_again(source, enemy, base, &"refrain", &"double")
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
	var tune := evo(EVO_CARRYING)  # Carrying Tune: the same carry (further), shown as sound running down the path
	var exit := clampi(int(_exit.get(bell.get_instance_id(), int(carried[0]))), 0, maxi(_route_px.size() - 1, 0))
	var from: Vector2 = _route_px[exit] if exit < _route_px.size() else bell.global_position
	var heard := 0
	for enemy in enemies():
		if carried.has(index_of(enemy)) and not _in_reach(bell, enemy):
			if tune:
				_line_fx(from, enemy.global_position, 1.0, Palette.BLOSSOM)
				ring(enemy, bell, base, false, null, EVO_CARRYING)  # Carrying Tune: the ring only (rebuilt 2026-10-23)
			else:
				strike(bell, enemy, base * CARRY_SHARE, &"carried_ring", true)  # (Sound Carries: a retired class card)
				ring(enemy, bell, base * CARRY_SHARE)
			heard += 1
	if tune and heard > 0:
		credit(EVO_CARRYING, from, bell)

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

# Second Verse (lent): a nightmare that bell hit, leaving its range, gets the last status another Warden gave it again,
# the same stacks, as a quiet add (never starts one, never above the limit, Charged one short of a bolt; never Rooted).
# Once for each nightmare and bell. Owner 2026-10-18, bell_lent_review.md: another Warden = any but that bell, other
# bells too, so Bellflower alone works with two bells (was another family's status, never Drowsy).
func _second_verse(enemy, bell) -> void:
	if not enemy.get_meta(BELL_HIT_META, {}).has(bell.get_instance_id()) or not enemy.has_meta(LAST_OTHER_META):
		return  # (Trait rework 2026-10-15: that bell has hit it; it no longer needs Drowsy)
	var paid: Dictionary = enemy.get_meta(VERSE_META, {})
	if paid.has(bell.get_instance_id()):
		return
	var kept = enemy.get_meta(LAST_OTHER_META)
	var last: Array = []
	if kept is Array:
		for i in range(kept.size() - 1, -1, -1):
			if kept[i] is Array and kept[i].size() >= 3 and int(kept[i][2]) != bell.get_instance_id():
				last = kept[i]
				break
	if last.is_empty() or StringName(last[0]) == EnemyStatuses.HELD:
		return
	var status := StringName(last[0])
	var verse: int = enemy.statuses.add_quiet(status, int(last[1]))
	setup_quiet(enemy, SECOND_VERSE, status, verse)  # (setup credit 2026-10-16)
	if verse > 0:
		paid[bell.get_instance_id()] = true
		enemy.set_meta(VERSE_META, paid)
		_line_fx(bell.global_position, enemy.global_position, 1.5, Palette.BLOSSOM)
		enemy.flash_status(status)  # A pulse on that status's badge (bell_lent_review.md (c))
		credit(SECOND_VERSE, enemy.global_position, bell)

# --- The poll: sleepers, busy bells, Rounds, hanging notes -------------------------------------------------------------------

func on_poll() -> void:
	if not active():
		return
	var all := bells()
	var drift: int = dream_state.drift_director.drifts_started if dream_state.drift_director != null else 0
	var busy := {}
	var verse := rule(SECOND_VERSE)
	var bell_to_bell := tolls_on() and rule(BELL_TO_BELL)
	var walls := evo(EVO_WALLS) and not _wall_side.is_empty()
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
		if walls and living(enemy):
			_walk_walls(enemy)
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

# Humming Walls: route points walked beside a Thornwall, counted forward only on the walker's own leg (a pull back never
# counts twice; a new lap starts over). Each WALL_STEPS steps fills one pip, never the last, once between its Tolls. Flyers
# never (index_of is -1). No damage, no ring: never Hand to Hand, Midnight's count or Accompaniment's notes.
func _walk_walls(enemy) -> void:
	var i := index_of(enemy)
	if i < 0:
		return
	var laps := int(enemy.get("laps")) if enemy.get("laps") != null else 0
	if not enemy.has_meta(WALL_SEEN_META) or int(enemy.get_meta(WALL_LAPS_META, 0)) != laps:
		enemy.set_meta(WALL_SEEN_META, i)
		enemy.set_meta(WALL_LAPS_META, laps)
		enemy.set_meta(WALL_COUNT_META, 0)
		return
	var seen := int(enemy.get_meta(WALL_SEEN_META))
	if i <= seen:
		return
	enemy.set_meta(WALL_SEEN_META, i)
	if enemy.has_meta(WALL_DONE_META):
		return  # Its wall pip for this Toll is filled: nothing builds toward another
	var count := int(enemy.get_meta(WALL_COUNT_META, 0))
	for k in range(seen + 1, i + 1):
		if _wall_side.has(k):
			count += 1
	var need := WALL_STEPS * 2  # Route points are half steps
	if count >= need and _add_pip(enemy, null, EVO_WALLS):
		count = 0
		enemy.set_meta(WALL_DONE_META, true)
		enemy.set_meta(WALL_PIP_META, int(enemy.get_meta(PIPS_META, 1)) - 1)  # Which ring the wall filled (drawn only)
		Reactions._effect(&"toll_ring", enemy.global_position, self, 0.4)  # The walls hum
		credit(EVO_WALLS, enemy.global_position)
	enemy.set_meta(WALL_COUNT_META, mini(count, need))

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
	for bell in bells():
		bell.remove_meta(ALLEGRO_META)  # Allegro: kept Tolls are lost when the drift ends
	_notes.clear()
	_later.clear()
	_da_capo_due.clear()  # Da Capo: every bell's clock starts over (owner 2026-10-18, bell_lent_review.md)
	_clocks.clear()
	_last_hit_of.clear()
	queue_redraw()

# --- What the other systems ask (through DreamState) --------------------------------------------------------------------

# Rude Awakening: the next hit on a nightmare waking from any sleep, or let go from a Hold, from any Warden, deals
# double (the hit that wakes it counts; within 2 s; once per sleep or Hold).
func damage_multiplier(enemy, source, tag: StringName) -> float:
	return 1.0  # (Trait rework 2026-10-15: Rude Awakening replays hits now, _rude_awakening; this was its doubled hit)

# --- Drawing: the hanging notes ---------------------------------------------------------------------------------------------

# (Steady Beat's old gold overlap band is gone with its overlap rule, 2026-10-23: its look is the 3 bronze rings now.)

func _draw() -> void:
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
