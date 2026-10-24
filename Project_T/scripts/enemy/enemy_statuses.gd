extends RefCounted
class_name EnemyStatuses

# Status effects on one creature (numbers: documentation/dream_design.md, "Status effect numbers").
# Wardens apply statuses; other Wardens and Dreams pay them off by reading them here.
# Strength scales with the applying Warden's soothe (`potency`), so statuses keep up with health.
#
#   damp    (Soaked) conducts: water hits +20%, 4 s; no slow    (reaction buildup counted)
#   drowsy  −2% speed per stack, 3 s, up to 20        (bosses: up to 12)
#   spored  (Poisoned) 20% of the applier's hit damage per stack per second, independent 5 s applications, up to 32 (Driftspore raises the cap)
#   marked  (Exposed) builds to 10 stacks, then +25% damage taken, 5 s (20 with Brimming)
#   static  (Charged) charges; at 20 (bosses 30) a free bolt of 16× the charge potency, then reset; −1 stack per 2 s
#   held    (Rooted) can't move (Frostfern's freeze), 1 s       (reaction buildup counted)
# All slows together stop at SLOW_FLOOR of a nightmare's speed (elites / bosses higher); sleep and Hold
# have cooldowns. Potency (the applier's) multiplies only effect damage (Poisoned ticks, Charged bolts,
# Reactions: Reactions.EFFECT_TAGS in Enemy.take_damage); Soaked, Drowsy, Exposed and Rooted deal none.

const DAMP := &"damp"
const DROWSY := &"drowsy"
const SPORED := &"spored"
const MARKED := &"marked"
const STATIC := &"static"
const HELD := &"held"
const ALL: Array[StringName] = [DAMP, DROWSY, SPORED, MARKED, STATIC, HELD]

const DEFAULT_DURATION := {DAMP: 4.0, DROWSY: 3.0, SPORED: 5.0, MARKED: 5.0, STATIC: 2.0, HELD: 1.0}
const DEFAULT_MAX_STACKS := {DAMP: 8, DROWSY: 20, SPORED: 32, MARKED: 10, STATIC: 20, HELD: 4}
const BOSS_MAX_STACKS := {DROWSY: 12, STATIC: 30}
const COLORS := {  # Marks the Wardens put on nightmares, so they keep the Wardens' colours (one each)
	DAMP: Palette.DEWLIGHT, DROWSY: Palette.BLOSSOM, &"asleep": Palette.BLOSSOM, SPORED: Palette.SPRIG,
	MARKED: Palette.GOLD, STATIC: Palette.GLOW, HELD: Palette.MOONLIGHT,
}
# The White Stag's aura (a Memory Warden): nightmares inside are slower and take more damage.
const STAG_SLOW := 0.15
const STAG_EXTRA := 0.15

const DAMP_WATER_BONUS := 0.20  # Damp (Soaked) conducts: water (Dewdrop-family) hits +20% (Enemy.take_damage)
const WAKE_HIT_SHARE := 0.10  # One hit dealing this share of max health wakes a sleeper (not effect ticks)
const FOG_STATIC_BONUS := 0.25  # Static bolts +25% in fog (Morning Fog: "Static ticks +25% inside")
const CAUGHT_GREAT_TICK_BONUS := 0.25  # Great Dreamcatcher: Caught statuses tick +25%
const DROWSY_SLOW_PER_STACK := 0.02
const MARKED_EXTRA := 0.25
const _EMPTY: Array = []  # Read-only (a const array): tick() starts its expired list here, copying on the first expiry
const STATIC_BOLT_MULTIPLIER := 16.0
const STATIC_DECAY_TIME := 2.0  # Seconds per lost Static stack
# Seconds per lost stack once a status's timer runs out (balance_simulation.md "Statuses vanish whole: drain one stack
# at a time"; owner playtest 2026-10-13). The others (Poisoned's own batches, Rooted) end as before. Lasting Dreams,
# Deep ranks and Potency lengthen the timer only, never the drain.
const DECAY_TIME := {DAMP: 0.5, DROWSY: 0.5, MARKED: 1.0, STATIC: STATIC_DECAY_TIME}
const SPORE_TICK := 0.5  # Spored soothes in ticks this long
const FOG_SPORE_BONUS := 0.5  # Spored ticks +50% while in fog (Mistveil)

var is_boss := false
var is_elite := false  # Deeply Blighted (Enemy sets it with is_boss): its own slow floor and Poisoned cap
# Balancing 2026-10-24 (balance_simulation.md "Drift shapes: numbers"): a Deeply Blighted nightmare's Poisoned cap is x3
# (Few and tough drifts put half their health in 3-5 elites; a capped damage-over-time board lost about half there).
# Only Poisoned: other caps, Charged / Exposed needs and control statuses are unchanged.
const ELITE_POISON_CAP_MULT := 3.0
var hud_dirty := false  # Something the nightmare's HUD shows changed here (it clears it): slow_capped, awake
var slow_capped := false:  # All slows together hit the floor ("Slowed to the limit" in the status UI)
	set(value):
		if value != slow_capped:
			hud_dirty = true
		slow_capped = value
var sleep_cooldown := 0.0:  # After waking, seconds before it can fall Asleep again
	set(value):
		if (value > 0.0) != (sleep_cooldown > 0.0):
			hud_dirty = true  # The HUD's "awake" ring comes or goes
		sleep_cooldown = value
		if value > 0.0:
			_timers_live = true
var dream_spores_cooldown := 0.0:  # Dreamshroom's Dream Spores: this sleeper puffed; no Dreamshroom makes it puff again yet (shared)
	set(value):
		dream_spores_cooldown = value
		if value > 0.0:
			_timers_live = true
var hold_cooldown := 0.0:  # After a Hold ends, seconds before it can be Held again
	set(value):
		hold_cooldown = value
		if value > 0.0:
			_timers_live = true
var _hold_just_ended := false  # The frame a Hold ran out (Snare's release-pull Hold may follow)
const SLOW_FLOOR := 0.5
const SLOW_FLOOR_ELITE := 0.6
const SLOW_FLOOR_BOSS := 0.7
const SLEEP_COOLDOWN := 4.0
const SLEEP_COOLDOWN_BOSS := 8.0
const HOLD_COOLDOWN := 1.5
const HOLD_COOLDOWN_BOSS := 3.0
var ignores_slows := false  # Drowned One: statuses still apply, they just don't slow it
# From EnemyData: statuses that don't take, and {status id: duration multiplier}.
var immune: Array[StringName] = []
var duration_multipliers := {}
# Every status's duration on this creature (Omens: Stubborn Blight halves them).
var duration_multiplier_all := 1.0
# {id: {"stacks": int, "time": float (seconds left), "potency": float}}
# Perf (mobile_plan.md): true while any countdown timer below may be running. Their setters set it on any
# positive write (from here or outside: BranchKit, Reactions, MapGifts…); tick() counts them down only then.
var _timers_live := false
var _active := {}
var _spore_timer := 0.0
# Bounded application batches: [seconds remaining, stacks, contributing Warden].
var _spore_batches: Array = []
# Damage is delivered after timers expire: retain the returned tick's attribution.
var spore_tick_source: Node = null
var spore_tick_line := ""
var spore_tick_credit: Array = []
var delivering_spore_tick := false
var _fog_time := 0.0:
	set(value):
		_fog_time = value
		if value > 0.0:
			_timers_live = true
var fog_source: Node = null  # The Warden whose fog it's in (credit for the fog-boosted part of Spored ticks)
var _spore_by := {}  # Spored credit: applier instance id -> [applier, stacks it added] (DamageLog splits ticks by it)
var _stag_time := 0.0:  # Seconds left inside the White Stag's aura
	set(value):
		_stag_time = value
		if value > 0.0:
			_timers_live = true

# Reactions (tower_design.md "Reactions"; rules in Reactions). Per nightmare:
# (owner 2026-10-17, council reactions_unique.md: Mushrooming's +50% Poisoned and Smother's x3 ticks are gone. Mushrooming is
# a zone now (mushroom_time below, read by Reactions.effect_multiplier); Smother stores its Poisoned while Rooted and
# Reactions.on_smother_ended bursts it.)
var reaction_cooldowns := {}  # Reaction id -> seconds before it can fire here again
# Late crown (owner 2026-10-22, dream_council_review.md 29): base Reaction id -> {"t": seconds left, …} after it fired
# here, while its Crowned one can still form (Reactions.CROWN_WINDOW; Reactions opens and reads it). Gone at the Waymark.
var crown_window := {}
var crowned_late := 0  # Late crowns on this nightmare (Reactions: once, a boss once per 25% health)
# The latest Reaction whose output touched this nightmare, while it can still start a chain.
var chain_count := 0
var chain_time := 0.0:
	set(value):
		chain_time = value
		if value > 0.0:
			_timers_live = true
var chain_towers: Array = []  # Wardens that took part in that chain so far
var pinned := false:  # Pinned: the next Warden hit is a guaranteed ×3 crit
	set(value):
		if value and not pinned:
			start_cooldown(&"pin_wait", Reactions.PIN_WAIT)  # (council rx review 2026-10-17) Night Terror waits this long at most
		pinned = value
var star_pinned := false  # Falling Stars (owner 2026-10-17, council reactions_unique.md): this Pin came from a star: a x2 crit, no pierce
var star_pin_hit := false  # (council rx review 2026-10-17) The Pin hit being dealt is a star's: Enemy credits it at x STAR_PIN_CRIT
var sleepwalked := 0  # (council rx review 2026-10-17) Sleepwalks it has started (Reactions.SLEEPWALK_TIMES; bosses SLEEPWALK_BOSS_TIMES)
var scree_given := 0  # (council rx review 2026-10-17) Avalanche scree Rooted given since its last &"scree" rest, from any patch
var mushroom_payoff := 1.0  # (council rx review 2026-10-17) The Brimming payoff of the Mushrooming cloud it stands in
var skip_reaction_wait := false  # Card pass 2026-10-16, Called from Afar: its next Reaction skips its wait (Reactions._fire spends it)
var bound_pause := false  # Card pass 2026-10-16, Bound and Burning (owned): while Rooted, its other statuses don't run down
var drowned := 0  # Times Drown made it sleep (once per nightmare; Deep Water II: twice)
var mushroom_time := 0.0:  # Inside a Mushrooming cloud while > 0: effect damage +30% (owner 2026-10-17, council reactions_unique.md)
	set(value):
		mushroom_time = value
		if value > 0.0:
			_timers_live = true
var burn_time := 0.0:  # Ignite (status jobs, 2026-09-29): Spored ticks burn_rate x as fast while > 0 (Reactions.burn)
	set(value):
		burn_time = value
		if value > 0.0:
			_timers_live = true
var burn_rate := 3.0
# Bumped whenever a status comes, goes or changes stacks: the status icons redraw only then.
var changes := 0
var applications := 0  # Accepted applications, including statuses immediately consumed by a Reaction/bolt.
var sleep_locked_time := 0.0:  # Nightbloom: while > 0, sleep neither breaks on a big hit nor ends (Enemy's wake rule reads it)
	set(value):
		sleep_locked_time = value
		if value > 0.0:
			_timers_live = true
var slow_time := 0.0:  # Drown on bosses (and Held-immune nightmares): an extra slow instead of sleep
	set(value):
		slow_time = value
		if value > 0.0:
			_timers_live = true
var slow_amount := 0.0
# Timed slows that each keep their own expiry (HelperCommons.slow; dream_council_review.md 26, fix 7): a small slow
# re-applied every poll (Knee-Deep) can no longer keep an earlier, bigger one (Riptide, Drown) alive. [[amount, left]]
var timed_slows: Array = []
var ground_taken := 0.0  # Heartwood Roots (MapGifts): extra soothe taken while on the marked cells
var ground_taken_time := 0.0:  # Refreshed by MapGifts while the nightmare stands there
	set(value):
		ground_taken_time = value
		if value > 0.0:
			_timers_live = true
var smothering := false  # Held + Spored right now (its Poisoned is stored, not ticking)
# Smother (owner 2026-10-17, council reactions_unique.md): while smothering, each Poisoned tick swells this store instead of
# landing; Reactions.on_smother_ended bursts it (x Reactions.SMOTHER_BURST) when the Root breaks. Credit: the tick's own.
var smother_stored := 0.0
var smother_source: Node = null
var smother_line := ""
var smother_credit := {}  # (council rx review 2026-10-17) Applier -> what its Poisoned ticks stored (the burst's credit split)

# (council rx review 2026-10-17) The stored burst's credit as spore_tick_credit takes it: [[applier, share], …].
func smother_credit_list() -> Array:
	var total := 0.0
	for who in smother_credit:
		if is_instance_valid(who):
			total += float(smother_credit[who])
	var out := []
	if total <= 0.0:
		return out
	for who in smother_credit:
		if is_instance_valid(who):
			out.append([who, float(smother_credit[who]) / total])
	return out

# Sleep (Drown; Great Dreamcatcher lengthens it): can't move while > 0. Not a status (no icon, no
# Reactions of its own), but it counts as asleep for Pinned and Caught.
var sleep_time := 0.0:
	set(value):
		sleep_time = value
		if value > 0.0:
			_timers_live = true
var sleep_extended := false  # Great Dreamcatcher's +1 s happened already
var dreamshroom_slept := false  # Dreamshroom puts each nightmare to sleep once
var held_bonus := 0.0  # World Root: +damage taken while Held (set when it Holds this nightmare)
# Crowned Reactions (Reactions): the Tempest cap, Storm Front (a Gust just copied statuses here), a
# Prismstorm Shatter about to throw its shards, and Smother having just ended (Fever Dream).
var tempest_time := 0.0:
	set(value):
		tempest_time = value
		if value > 0.0:
			_timers_live = true
var gust_time := 0.0:
	set(value):
		gust_time = value
		if value > 0.0:
			_timers_live = true
var prism_pending := false
var smother_ended := false
# The Warden whose charge the last bolt from apply() was (the strongest Static applier, whose potency it used),
# not whoever added the final stack (story chat: a spore Warden's carried Static took Live Wire bolts' credit).
var bolt_source: Node = null
var every_hits := {}  # Warden instance id -> hits on this nightmare (TowerData.status_every counts per nightmare)
var veil_time := 0.0:  # Morning Fog's Veil (FinalTwists): while > 0 it can't be healed (Enemy.heal reads it)
	set(value):
		veil_time = value
		if value > 0.0:
			_timers_live = true
var silence_time := 0.0:  # Hushbell (BranchKit.silence): while > 0 it uses no abilities (Enemy._update_presence reads it)
	set(value):
		silence_time = value
		if value > 0.0:
			_timers_live = true
# Silence as a status badge (Main 2421cbd6): SILENCED is its id (not in _active); silence_full is the
# longest it was set to this silence (for the time bar), and starting or ending it bumps `changes`.
const SILENCED := &"silenced"
# Asleep as a status badge (screens_ui.md "Status row: Reaction-ready marks and falling asleep"): ASLEEP is its id (not in
# _active, no stacks); sleep_full is the longest this sleep was set to (its draining ring). Enemy swaps it in for Drowsy.
const ASLEEP := &"asleep"
var sleep_full := 0.0
var silence_full := 0.0
var _silence_last := 0.0
var marked_extra := 0.0  # Beacon: its Marked is stronger (+35% instead of +25%) until Marked ends
var marked_bonus := 0.0  # Bright Marks (Dream): added to either (the nightmare sets it each frame)
# Hunter's Moon / Eternal Charge (Legendary rules): Marked / Static on this nightmare never run out.
var marked_forever := false
var static_forever := false
# Caught (Dreamcatcher): asleep or at max Drowsy inside a Dreamcatcher's range; takes more damage.
var caught_time := 0.0:
	set(value):
		caught_time = value
		if value > 0.0:
			_timers_live = true
var caught_bonus := 0.0
var caught_shard := false  # Caught by a Great Dreamcatcher: dispelling it drops a Dreamlight shard
var caught_shard_tower: Node = null  # That Great Dreamcatcher (for its shard_dropped signal)
var bad_dreams_timer := 0.0  # Bad Dreams: Drowsy per second while Caught
# Thousand Cuts: hits within 2 s of each other stack +2% damage taken (max +60%).
const CUT_BONUS := 0.02
const CUT_MAX := 30
const CUT_WINDOW := 2.0
var cut_stacks := 0
var cut_time := 0.0:
	set(value):
		cut_time = value
		if value > 0.0:
			_timers_live = true
# Heavy Eyelids: extra Drowsy cap (set by the nightmare from the Dream before Drowsy lands).
var drowsy_cap_bonus := 0

func is_asleep() -> bool:
	return sleep_time > 0.0

func is_caught() -> bool:
	return caught_time > 0.0

# Caught by a Great Dreamcatcher (the one that drops shards): its statuses tick +25% (Spored ticks,
# Static bolts). A plain Dreamcatcher only preserves them. `caught_bonus` is no longer read.
func get_caught_tick_bonus() -> float:
	if not is_caught():
		return 0.0
	return (CAUGHT_GREAT_TICK_BONUS if caught_shard else 0.0) + caught_strong

# Strong on the Dreamcatcher that caught it (Tower Code, Nurture audit b6f44fac): +10% tick per rank, adds to Great's.
var caught_strong := 0.0

# A single hit this big (share of max health) wakes a sleeper, unless Nightbloom locks the sleep.
func can_wake_from_hit() -> bool:
	return sleep_time > 0.0 and sleep_locked_time <= 0.0

# Asleep or at full Drowsy (bosses: their cap of 3 counts): what Dreamcatchers catch.
func is_catchable() -> bool:
	return is_asleep() or (has(DROWSY) and stacks(DROWSY) >= get_max_stacks(DROWSY))

func add_cut() -> void:
	cut_stacks = mini(cut_stacks + 1, CUT_MAX)
	cut_time = CUT_WINDOW

# Marks this nightmare as touched by a Reaction's output, so a Reaction here within `window` s counts
# as the chain's next link.
func mark_chain(count: int, towers: Array, window: float = 1.0) -> void:
	if count > chain_count or chain_time <= 0.0:
		chain_count = count
		chain_towers = towers
	chain_time = maxf(chain_time, window)

# One more hit from the Warden `key` (its instance id); returns how many it has landed on this nightmare.
func count_hit(key: int) -> int:
	every_hits[key] = int(every_hits.get(key, 0)) + 1
	return every_hits[key]

func is_on_cooldown(reaction: StringName) -> bool:
	return reaction_cooldowns.get(reaction, 0.0) > 0.0

func start_cooldown(reaction: StringName, seconds: float) -> void:
	reaction_cooldowns[reaction] = seconds

# Adds stacks up to the cap (0 = default). Poisoned applications expire independently; other statuses refresh.
# `line` is the applying Warden's family; Spored ticks count as that family's soothe. `source` is
# the applying Warden (damage attribution: Spored ticks and Static bolts are credited to it).
# Returns the soothe of a Static bolt if this application set one off, else 0.
func apply(id: StringName, stacks: int = 1, duration: float = 0.0, potency: float = 0.0,
		max_stacks: int = 0, line: String = "", source: Node = null) -> float:
	if id in immune:
		return 0.0
	if id == HELD and hold_cooldown > 0.0 and not has(HELD) and not _hold_just_ended:
		return 0.0  # Just shook off a Hold (an ongoing Hold can still be stretched; Snare's release-pull Hold, in
		# the very frame the Hold ended, is the designed hold -> pull -> hold cycle and still lands)
	var fresh := not has(id)
	if fresh:
		_lifecycle[id] = lifecycle_serial(id) + 1
	var cap := get_max_stacks(id, max_stacks)
	var status: Dictionary = _active.get(id, {"stacks": 0, "time": 0.0, "potency": 0.0})
	var was_stacks := int(status.stacks)  # A status reaching its most is a moment (status_filled)
	status.stacks = mini(status.stacks + stacks, cap)

	var strength := _applier_potency(source)
	var length: float = (duration if duration > 0.0 else DEFAULT_DURATION[id]) * duration_multipliers.get(id, 1.0) \
		* duration_multiplier_all * _potency_stretch(id, strength)  # Rule 3: Potency past a cap lengthens it
	if length >= status.time:
		status["full"] = length  # A fresh timer: the badge's rim arc drains from full again
		# …and the linger cap counts from this landing (it bounds how long a status outlives it). Hard cards 2026-10-16 (TD):
		# Steeped's stretch spends the same room, so every Dewdrop card shares the 4 s cap
		status["lingered"] = float(pending_linger.get(id, 0.0))
		status["calling_lingered"] = 0.0  # (F2 lent × Calling, owner 2026-10-18; f1_spec.md) the Calling's own cap starts over too
		status["landed"] = length  # Topped Up puts it back to this, never more
		status["stretched"] = float(pending_linger.get(id, 0.0))  # Steeped / Pooling / High Tide made this landing longer
	status.time = maxf(status.time, length)
	if id == SPORED:
		_add_spore_batch(mini(stacks, cap), length, source, cap)
		status.time = _spore_remaining()
	if potency >= status.potency:
		status["line"] = line  # The strongest applier's family sets the ticks' family
		status["source"] = source  # …and gets the credit for them
	status.potency = maxf(status.potency, potency)
	# Status strength (tower_design.md "Potency: effect damage and status strength"): the strongest applier's
	# Potency while the status lasts (never a sum). Rooted's length scales with it here, capped. (`strength` is read
	# above, before the length.)
	status["strength"] = maxf(status.get("strength", 0.0), strength)
	if id == HELD and Tower.status_potency_on and strength > 1.0:
		var held := minf(length * strength, maxf(HELD_POTENCY_CAP, length))
		status.time = maxf(status.time, held)
		status["full"] = maxf(status.get("full", 0.0), held)
	# Driftspore's higher cap sticks once reached, even if a Sporeling hits next.
	status["cap"] = maxi(status.get("cap", 0), cap)
	status["peak"] = maxi(int(status.get("peak", 0)), int(status.stacks))  # Ebb brings half of this back
	pending_linger.erase(id)
	_active[id] = status
	if was_stacks < cap and int(status.stacks) >= cap and id != STATIC:
		status_filled.emit(id)  # (Charged at its most is a bolt instead)
	applications += 1
	changes += 1
	if fresh and status.stacks > 0:
		_grand_tour_new_status(id, source)
	# When both buildup gates are met, Thunderclap goes first (Reactions), so no bolt here then.
	if id == STATIC and status.stacks >= cap and (DreamState.undiluted_on or not (self.stacks(DAMP) >= Reactions.need(Reactions.SOAKED_NEEDED) and Reactions.grown(self, [DAMP, STATIC]))):  # (Undiluted: no Thunderclap to wait for, so it bolts)
		static_lingered = is_lingering(STATIC)  # Keyword chips 2026-10-16: the bolt below reads it (Slow Burn)
		_active.erase(STATIC)
		changes += 1
		if static_forever and potency > 0.0:
			bolt_source = source
			return potency * STATIC_BOLT_MULTIPLIER * _static_tick_multiplier()  # Eternal Charge: the Warden that added the last charge
		bolt_source = status.get("source")  # The bolt is the strongest applier's charge: its credit too
		return status.potency * STATIC_BOLT_MULTIPLIER * _static_tick_multiplier()
	return 0.0

# Caps on what Potency can make of a status (Balancing Discussion, 2026-10-01). A cap never lowers a
# status below its base (a card that already pushes it past the cap keeps its value).
const SOAKED_CAP := 0.40  # Water hits on a Soaked nightmare: at most +40%
const EXPOSED_CAP := 0.40  # Damage taken while Exposed: at most +40% (Beacon's bonus inside it)
const HELD_POTENCY_CAP := 2.25  # Seconds: the longest Potency makes a Hold (signature audit a09297af: 2.0 capped Deep at rank IV)

func _applier_potency(source: Node) -> float:
	return source.get_potency() if source is Tower and is_instance_valid(source) else 1.0

# Rule 3 (Tower Discussion, warden_stats.md b6f44fac; Balancing: duration × max(1, Potency / the Potency that reaches the
# cap)): past a strength cap, the rest of the applier's Potency lengthens the status. Drowsy: its length scales with
# Potency (its slow no longer does). Tower Code, reviewed by Enemy Code.
func _potency_stretch(id: StringName, strength: float) -> float:
	if not Tower.status_potency_on or strength <= 1.0:
		return 1.0
	match id:
		DROWSY:
			return strength
		MARKED:
			var base := maxf(MARKED_EXTRA, marked_extra) + marked_bonus
			return maxf(1.0, strength / maxf(EXPOSED_CAP / maxf(base, 0.001), 1.0))
		DAMP:
			return maxf(1.0, strength / maxf(SOAKED_CAP / DAMP_WATER_BONUS, 1.0))
	return 1.0

# The strength multiplier of status `id`: its strongest applier's Potency (1.0 with the switch off,
# Tower.status_potency_on, or with no Warden behind it).
func strength(id: StringName) -> float:
	if not Tower.status_potency_on:
		return 1.0
	return float(_active.get(id, {}).get("strength", 1.0))

# Soaked's water-hit bonus with its strength (Enemy.take_damage), from `base` (+20%, more with cards).
func soaked_bonus(base: float) -> float:
	return minf(base * strength(DAMP), maxf(SOAKED_CAP, base))

static var _cap_frame := -1
static var _cap_multiplier := 1

# Brimming's multiplier on caps above 1 (DreamState.status_cap_multiplier), looked up once a frame: every
# status application asks.
static func cap_multiplier() -> int:
	var frame := Engine.get_process_frames()
	if frame != _cap_frame:
		_cap_frame = frame
		var tree := Engine.get_main_loop() as SceneTree
		var dreams: DreamState = tree.get_first_node_in_group(DreamState.GROUP) as DreamState if tree != null else null
		_cap_multiplier = dreams.status_cap_multiplier() if dreams != null else 1
	return _cap_multiplier

func get_max_stacks(id: StringName, override: int = 0) -> int:
	if not DEFAULT_MAX_STACKS.has(id) and override <= 0:
		return 1  # Silenced (and any other timer shown as a badge): no stacks
	var cap: int = override if override > 0 else DEFAULT_MAX_STACKS[id]
	if is_boss and BOSS_MAX_STACKS.has(id):
		cap = BOSS_MAX_STACKS[id] if id == DROWSY else maxi(cap, BOSS_MAX_STACKS[id])
	if id == SPORED and is_elite:
		cap = roundi(cap * ELITE_POISON_CAP_MULT)  # Deeply Blighted: 32 / 48 / 64 / 80 -> 96 / 144 / 192 / 240 (Brimming doubles on top)
	if id in ALL:
		cap *= cap_multiplier()  # Brimming doubles buildup caps; Charged receives a larger discharge payoff
	if id == DROWSY:
		cap += drowsy_cap_bonus  # Heavy Eyelids after the doubling
	return maxi(cap, _active.get(id, {}).get("cap", 0))

func has(id: StringName) -> bool:
	return _active.has(id)

# Fresh status generations invalidate cooperation history across removal/reapplication.
var _lifecycle := {}
func lifecycle_serial(id: StringName) -> int:
	return int(_lifecycle.get(id, 0))

func stacks(id: StringName) -> int:
	return _active[id].stacks if _active.has(id) else 0

# Family of the Warden behind the current Spored ("" if none).
func spore_line() -> String:
	return _active[SPORED].get("line", "") if _active.has(SPORED) else ""

# The Warden credited for `id` (its strongest applier), or null if unknown or gone.
func source(id: StringName) -> Node:
	var who = _active[id].get("source") if _active.has(id) else null
	return who if is_instance_valid(who) else null

func potency(id: StringName) -> float:
	return _active[id].potency if _active.has(id) else 0.0

func time_left(id: StringName) -> float:
	if id == ASLEEP:
		return sleep_time
	if id == SILENCED:
		return silence_time
	return _active[id].time if _active.has(id) else 0.0

# Share of its timer left, 1 → 0 (the status badge's draining rim arc).
func time_share(id: StringName) -> float:
	if id == ASLEEP:
		return clampf(sleep_time / maxf(sleep_full, 0.001), 0.0, 1.0)
	if id == SILENCED:
		return clampf(silence_time / maxf(silence_full, 0.001), 0.0, 1.0)
	if not _active.has(id):
		return 0.0
	var status: Dictionary = _active[id]
	return clampf(status.time / maxf(status.get("full", status.time), 0.001), 0.0, 1.0)

# One status for the nightmare info panel: "Charged 4/5 · 2.1 s" (stacks only when it can stack).
func describe(id: StringName) -> String:
	var cap := get_max_stacks(id)
	var count := " %d/%d" % [stacks(id), cap] if cap > 1 else ""
	return "%s%s · %.1f s" % [IconInfo.status_name(id), count, time_left(id)]

# Starlit Aim spends half the completion threshold without refreshing the timer
# or losing the strongest applier's potency, source and Beacon bonus.
func spend_exposed_crit() -> void:
	if not is_exposed():
		return
	_active[MARKED].stacks -= ceili(float(get_max_stacks(MARKED)) / 2.0)
	changes += 1

func remove(id: StringName) -> void:
	if id == STATIC:
		static_lingered = is_lingering(STATIC)  # Keyword chips 2026-10-16: read by the bolt this removal is for (Slow Burn)
	if id == SPORED:
		_spore_batches.clear()
		_spore_by.clear()
	if _active.erase(id):
		changes += 1

# Waymark (Legendary Dream, owner 2026-10-21): the nightmare reached the stone and loses every status and buildup, the
# "never fades" ones too (Eternal Charge, Rooted Nightmares): the stone wins. Sleep, Hold, Caught, slows, stored poison
# and Pinned go with them. Returns how many statuses it shed.
func shed_all() -> int:
	var shed := _active.size()
	for id in _active.keys():
		remove(id)
	pending_linger.clear()
	crown_window.clear()  # (Late crown: a shed nightmare starts over)
	marked_forever = false
	static_forever = false
	marked_extra = 0.0
	pinned = false
	star_pinned = false
	smothering = false
	smother_stored = 0.0
	smother_source = null
	smother_credit.clear()
	if sleep_time > 0.0:
		sleep_time = 0.0
	if caught_time > 0.0:
		caught_time = 0.0
	caught_bonus = 0.0
	caught_shard = false
	bad_dreams_timer = 0.0
	if slow_time > 0.0:
		slow_time = 0.0
	slow_amount = 0.0
	timed_slows.clear()
	if cut_time > 0.0:
		cut_time = 0.0
	cut_stacks = 0
	if burn_time > 0.0:
		burn_time = 0.0
	chain_count = 0
	held_bonus = 0.0
	changes += 1
	hud_dirty = true
	return shed

# How many statuses it carries (no array built: Tangled and the redraw check ask every frame).
func count() -> int:
	return _active.size()

func active_ids() -> Array:
	return _active.keys()

# Total stacks of every status (how "afflicted" a nightmare is, for Gust).
func total_stacks() -> int:
	var total := 0
	for id in _active:
		total += _active[id].stacks
	return total

# Every active status as [{id, stacks, time, potency, line, source}] (Gust copies them to other
# nightmares; Inspect shows them).
func snapshot() -> Array:
	var result := []
	for id in _active:
		var status: Dictionary = _active[id]
		result.append({"id": id, "stacks": status.stacks, "time": copy_duration(id), "potency": status.potency,
			"line": status.get("line", ""), "source": source(id)})
	return result

# Keeps the creature "in fog" (Mistveil) for `seconds`.
func set_in_fog(seconds: float, from: Node = null) -> void:
	_fog_time = maxf(_fog_time, seconds)
	if from != null:
		fog_source = from  # Credited with the fog part of Spored ticks (DamageLog)

func is_in_fog() -> bool:
	return _fog_time > 0.0

# Keeps the creature inside the White Stag's aura for `seconds`.
func set_in_stag_aura(seconds: float) -> void:
	_stag_time = maxf(_stag_time, seconds)

func is_in_stag_aura() -> bool:
	return _stag_time > 0.0

# Held nightmares stand still (they're easy targets for area effects).
func is_held() -> bool:
	return has(HELD)

# A slow of `amount` for `seconds` with its own expiry (one entry per amount: the same slow again only refreshes it).
func add_slow(amount: float, seconds: float) -> void:
	if amount <= 0.0 or seconds <= 0.0:
		return
	for timed in timed_slows:
		if is_equal_approx(float(timed[0]), amount):
			timed[1] = maxf(float(timed[1]), seconds)
			_timers_live = true
			return
	timed_slows.append([amount, seconds])
	_timers_live = true
	changes += 1  # Speed is read again

# The largest timed slow running and its time left (0, 0 = none).
func timed_slow() -> float:
	var best := 0.0
	for timed in timed_slows:
		best = maxf(best, float(timed[0]))
	return best

func timed_slow_left(amount: float) -> float:
	for timed in timed_slows:
		if is_equal_approx(float(timed[0]), amount):
			return float(timed[1])
	return 0.0

# Movement speed multiplier from slows.
# `extra_slow` adds slows that aren't statuses (none right now; the Tangled Dream was cut).
func get_speed_multiplier(extra_slow: float = 0.0) -> float:
	if ignores_slows:
		return 1.0
	# Slowing belongs to Drowsy (status jobs, 2026-09-29): Damp conducts instead (Enemy.take_damage).
	var slow := extra_slow
	slow += DROWSY_SLOW_PER_STACK * stacks(DROWSY)  # Rule 3: Potency lengthens Drowsy instead (the floor bound almost at once)
	if is_in_stag_aura():
		slow += STAG_SLOW
	var extra := slow_amount if slow_time > 0.0 else 0.0
	for timed in timed_slows:  # Slows never add up: the largest running one counts, as with slow_amount
		extra = maxf(extra, float(timed[0]))
	slow += extra
	# Slow and sleep have limits (tower_design.md, 2026-10-01): all slows together never take a nightmare below
	# SLOW_FLOOR of its speed (bosses / elites higher). Full stops (Held, Asleep) are separate.
	var floor_share := SLOW_FLOOR_BOSS if is_boss else (SLOW_FLOOR_ELITE if is_elite else SLOW_FLOOR)
	slow_capped = 1.0 - slow < floor_share
	return maxf(1.0 - slow, floor_share)

# Soothe taken multiplier (Marked, and the White Stag's aura).
func is_exposed() -> bool:
	return has(MARKED) and stacks(MARKED) >= get_max_stacks(MARKED)

# Bright Marks' part of the damage taken (DamageLog.note_card_bonus: the Dream damage panel and DreamState.boost_tier read
# it; Roguelite 451495cb): the taken multiplier with its bonus over the one without, the rest cancelling. 1.0 when it
# adds nothing (not Exposed, or no Bright Marks).
func bright_marks_multiplier() -> float:
	if marked_bonus <= 0.0 or not is_exposed():
		return 1.0
	var s := strength(MARKED)
	var plain := maxf(MARKED_EXTRA, marked_extra)
	var stag := STAG_EXTRA if is_in_stag_aura() else 0.0
	var with_bonus := 1.0 + minf((plain + marked_bonus) * s, maxf(EXPOSED_CAP, plain + marked_bonus)) + stag
	var without := 1.0 + minf(plain * s, maxf(EXPOSED_CAP, plain)) + stag
	return with_bonus / without

func get_damage_taken_multiplier() -> float:
	var multiplier := 1.0
	if is_exposed():
		var extra := maxf(MARKED_EXTRA, marked_extra) + marked_bonus  # Bright Marks on top (Beacon too)
		multiplier += minf(extra * strength(MARKED), maxf(EXPOSED_CAP, extra))  # Potency, capped
	if is_in_stag_aura():
		multiplier += STAG_EXTRA
	if cut_stacks > 0:
		multiplier *= 1.0 + CUT_BONUS * cut_stacks
	if ground_taken_time > 0.0:
		multiplier *= 1.0 + ground_taken  # Heartwood Roots (MapGifts)
	if held_bonus > 0.0 and is_held():
		multiplier *= 1.0 + held_bonus  # World Root: Held nightmares take more from everything
	return multiplier

# Advances timers. Returns the Spored soothe to deal this frame (already fog-boosted).
# Perf (mobile_plan.md): the countdown timers, only while one may be running (_timers_live; their setters
# set it). Clears the flag first: any timer still running sets it again as it is counted down.
func _tick_timers(delta: float) -> void:
	_timers_live = false
	# Most timers sit at 0 on most nightmares: only count down the running ones (this runs every
	# frame for every nightmare).
	if tempest_time > 0.0:
		tempest_time = maxf(tempest_time - delta, 0.0)
	if ground_taken_time > 0.0:
		ground_taken_time = maxf(ground_taken_time - delta, 0.0)
	if gust_time > 0.0:
		gust_time = maxf(gust_time - delta, 0.0)
	if _fog_time > 0.0:
		_fog_time = maxf(_fog_time - delta, 0.0)
	if _stag_time > 0.0:
		_stag_time = maxf(_stag_time - delta, 0.0)
	if chain_time > 0.0:
		chain_time = maxf(chain_time - delta, 0.0)
	if mushroom_time > 0.0:
		mushroom_time = maxf(mushroom_time - delta, 0.0)
	if burn_time > 0.0:
		burn_time = maxf(burn_time - delta, 0.0)
	if sleep_locked_time > 0.0:
		sleep_locked_time = maxf(sleep_locked_time - delta, 0.0)
	if slow_time > 0.0:
		slow_time = maxf(slow_time - delta, 0.0)
	if not timed_slows.is_empty():
		for i in range(timed_slows.size() - 1, -1, -1):
			timed_slows[i][1] = float(timed_slows[i][1]) - delta
			if float(timed_slows[i][1]) <= 0.0:
				timed_slows.remove_at(i)
		if not timed_slows.is_empty():
			_timers_live = true
	if silence_time > _silence_last + 0.0001:  # Silenced (again): BranchKit sets silence_time directly
		silence_full = silence_time
		if _silence_last <= 0.0:
			changes += 1  # A badge appears
	if silence_time > 0.0:
		silence_time = maxf(silence_time - delta, 0.0)
		if silence_time <= 0.0:
			changes += 1  # Its badge goes
	_silence_last = silence_time
	if veil_time > 0.0:
		veil_time = maxf(veil_time - delta, 0.0)
	if sleep_cooldown > 0.0:
		sleep_cooldown = maxf(sleep_cooldown - delta, 0.0)
	if dream_spores_cooldown > 0.0:
		dream_spores_cooldown = maxf(dream_spores_cooldown - delta, 0.0)
	if hold_cooldown > 0.0:
		hold_cooldown = maxf(hold_cooldown - delta, 0.0)
	if sleep_time > 0.0:
		if is_boss:
			sleep_time = 0.0  # Bosses never sleep
		elif sleep_locked_time <= 0.0:
			sleep_time = maxf(sleep_time - delta, 0.0)  # Nightbloom's lock: sleep doesn't end
			if sleep_time <= 0.0:
				sleep_cooldown = SLEEP_COOLDOWN_BOSS if is_boss else SLEEP_COOLDOWN  # Awake: a breather first
	if caught_time > 0.0:
		caught_time = maxf(caught_time - delta, 0.0)
	if cut_time > 0.0:
		cut_time = maxf(cut_time - delta, 0.0)
		if cut_time <= 0.0:
			cut_stacks = 0

func tick(delta: float) -> float:
	var was_smothering := smothering
	_hold_just_ended = false
	if _timers_live:
		_tick_timers(delta)
	if not reaction_cooldowns.is_empty():  # (No empty array made every frame for the many without any)
		for reaction in reaction_cooldowns.keys():
			reaction_cooldowns[reaction] -= delta
			if reaction_cooldowns[reaction] <= 0.0:
				reaction_cooldowns.erase(reaction)
	if not crown_window.is_empty():
		for base in crown_window.keys():
			crown_window[base].t -= delta
			if crown_window[base].t <= 0.0:
				crown_window.erase(base)
	var spore_damage := 0.0
	spore_tick_source = null
	spore_tick_line = ""
	spore_tick_credit = _EMPTY
	if has(SPORED):
		smothering = stacks(HELD) >= Reactions.need(Reactions.ROOTED_NEEDED) and stacks(SPORED) >= Reactions.need(Reactions.SMOTHER_MIN_SPORES) and Reactions.grown(self, [HELD, SPORED])
		_spore_timer += delta * (burn_rate if burn_time > 0.0 else 1.0)  # (Smother no longer speeds it up: owner 2026-10-17)
		if _spore_timer >= SPORE_TICK:
			spore_tick_source = source(SPORED)
			spore_tick_line = spore_line()
			spore_tick_credit = spore_credit()
		while _spore_timer >= SPORE_TICK:
			_spore_timer -= SPORE_TICK
			var per_tick: float = _active[SPORED].stacks * _active[SPORED].potency * SPORE_TICK
			var bonus := (FOG_SPORE_BONUS if is_in_fog() else 0.0) + get_caught_tick_bonus()
			if smothering:  # Smother (owner 2026-10-17, council reactions_unique.md): the tick swells the store instead
				smother_stored += per_tick * (1.0 + bonus)
				smother_source = spore_tick_source
				smother_line = spore_tick_line
				for part in spore_tick_credit:  # (council rx review 2026-10-17) each applier's share, for the burst's credit
					if is_instance_valid(part[0]):
						smother_credit[part[0]] = float(smother_credit.get(part[0], 0.0)) + per_tick * (1.0 + bonus) * float(part[1])
			else:
				spore_damage += per_tick * (1.0 + bonus)
	else:
		_spore_timer = 0.0
		smothering = false
	smother_ended = was_smothering and not smothering

	# Caught: statuses stop wearing off (Static doesn't bleed, timers pause); Spored still ticks.
	# (Iterates the dictionary itself, no keys() copy: this runs for every nightmare every frame.)
	if not _active.is_empty() and caught_time <= 0.0:
		var expired: Array = _EMPTY  # Shared until something expires (perf: no new array every frame)
		var bound_now := bound_pause and _active.has(HELD)  # Card pass 2026-10-16, Bound and Burning
		for id in _active:
			var status: Dictionary = _active[id]
			status["age"] = float(status.get("age", 0.0)) + delta  # Old Rain
			if bound_now and id != HELD:
				if can_linger(id):
					status["stretched"] = float(status.get("stretched", 0.0)) + delta  # Keyword chips 2026-10-16: the pause is Linger (is_lingering)
				continue  # Bound and Burning: while Rooted its other statuses don't run down (Rooted itself still does)
			if id == SPORED:
				_tick_spore_batches(delta)
				status.stacks = _spore_count()
				status.time = _spore_remaining()
				if status.stacks > 0:
					continue
			status.time -= delta
			if status.time > 0.0:
				continue
			if (id == MARKED and marked_forever) or (id == STATIC and static_forever):
				status.time = 1.0  # Never expires, never bleeds off
				status["full"] = 1.0
				continue
			if status.stacks > 1 and DECAY_TIME.has(id):
				status.stacks -= 1  # Drains one stack at a time (never starts a sleep: only an application does)
				changes += 1
				var drain: float = DECAY_TIME[id]
				status.time = drain
				status["full"] = drain  # The badge's rim and counter tick down with the drain
			else:
				if expired.is_empty():
					expired = []
				expired.append(id)
		var ran_out: Array = []
		for id in expired:
			var gone: Dictionary = _active.get(id, {})
			if not gone.is_empty():
				ran_out.append([id, int(gone.get("peak", gone.get("stacks", 1))), gone.get("source"), float(gone.get("potency", 0.0)), String(gone.get("line", ""))])
			remove(id)
			if id == HELD:
				hold_cooldown = HOLD_COOLDOWN_BOSS if is_boss else HOLD_COOLDOWN  # A Hold ran out: a breather first
				_hold_just_ended = true
		for row in ran_out:  # After the loop: a listener may put the status back (Ebb)
			status_ran_out.emit(row[0], row[1], row[2] if is_instance_valid(row[2]) else null, row[3], row[4])
	if marked_extra != 0.0 and not has(MARKED):
		marked_extra = 0.0
	return spore_damage

# Refresh only the oldest replaced stacks at capacity; other applications retain their age.
func _add_spore_batch(amount: int, duration: float, applier: Node, cap: int) -> void:
	if amount <= 0:
		return
	var overflow := maxi(_spore_count() + amount - cap, 0)
	while overflow > 0 and not _spore_batches.is_empty():
		var batch: Array = _spore_batches[0]
		var removed := mini(int(batch[1]), overflow)
		batch[1] -= removed
		overflow -= removed
		if batch[1] <= 0:
			_spore_batches.remove_at(0)
	_spore_batches.append([duration, amount, applier])
	_share_spore_clock()
	_rebuild_spore_credit()

# Poisoned lasts until it wears off (owner 2026-10-15: "Poison shouldn't tick down, should last until it wears off"):
# the whole pile shares one clock. Every application refreshes it, and every stack goes at once when nothing has
# poisoned the nightmare for that long. The batches stay (who applied which stacks: credit, Knell, the cap).
# (Replaces the 2026-10-09 rule "each application expires on its own".)
func _share_spore_clock() -> void:
	var longest := 0.0
	for batch in _spore_batches:
		longest = maxf(longest, float(batch[0]))
	for batch in _spore_batches:
		batch[0] = longest

func _tick_spore_batches(delta: float) -> void:
	var expired := false
	for i in range(_spore_batches.size() - 1, -1, -1):
		_spore_batches[i][0] -= delta
		if _spore_batches[i][0] <= 0.00001:
			_spore_batches.remove_at(i)
			expired = true
	if expired:
		changes += 1
		_rebuild_spore_credit()

func _spore_count() -> int:
	var total := 0
	for batch in _spore_batches:
		total += int(batch[1])
	return total

func _spore_remaining() -> float:
	var remaining := 0.0
	for batch in _spore_batches:
		remaining = maxf(remaining, batch[0])
	return remaining

# Copies conservatively use the shortest remaining application lifetime, never rejuvenating old stacks.
func copy_duration(id: StringName) -> float:
	if id != SPORED or _spore_batches.is_empty():
		return time_left(id)
	var remaining := INF
	for batch in _spore_batches:
		remaining = minf(remaining, batch[0])
	return remaining

func _rebuild_spore_credit() -> void:
	_spore_by.clear()
	for batch in _spore_batches:
		if is_instance_valid(batch[2]):
			_note_spores(batch[2], int(batch[1]), false)

# Static bolts in fog (Morning Fog) and on a nightmare Caught by a Great Dreamcatcher hit harder.
func _static_tick_multiplier() -> float:
	return (1.0 + (FOG_STATIC_BONUS if is_in_fog() else 0.0) + get_caught_tick_bonus()) * charged_payoff_multiplier()

# Early discharge specialists get the energy accumulated, not a full bolt from one charge.
func stored_bolt_damage() -> float:
	return potency(STATIC) * STATIC_BOLT_MULTIPLIER * float(stacks(STATIC)) / maxf(get_max_stacks(STATIC), 1.0) * _static_tick_multiplier()

# Brimming and Reactions (owner 2026-10-16, option A; balance_simulation.md "Human run 41"): a Reaction needs its normal
# amounts, and hits x2.2 only if, when it fired, this nightmare carried twice the normal need of every status it needs
# (Reactions._decide_payoff writes it here by Reaction id and by its base Reaction). x1 without Brimming.
var brim_payoff := {}
func reaction_payoff(id: StringName) -> float:
	if cap_multiplier() <= 1:
		return 1.0
	return float(brim_payoff.get(id, 1.0))

# Status `id`'s cap without Brimming's doubling (a Reaction's "full Drowsy"): bosses their own cap, Heavy Eyelids added.
func normal_cap(id: StringName) -> int:
	var full := get_max_stacks(id)
	var mult := cap_multiplier()
	if mult <= 1:
		return full
	var bonus := drowsy_cap_bonus if id == DROWSY else 0
	return maxi(ceili(float(full - bonus) / mult) + bonus, 1)

static func charged_payoff_multiplier() -> float:
	return 2.2 if cap_multiplier() > 1 else 1.0

# Spored credit (balance_simulation.md "Human run 2"): every applier's share of the stacks it added.
# The damage rule doesn't change (all stacks tick at the strongest applier's potency); only who gets
# the credit. `fresh`: the first stacks after Spored had worn off start the count over.
func _note_spores(source: Node, added: int, fresh: bool) -> void:
	if fresh:
		_spore_by.clear()
	if added <= 0:
		return
	var key := source.get_instance_id()
	var entry: Array = _spore_by.get(key, [source, 0])
	entry[1] += added
	_spore_by[key] = entry

# [[applier, share], …] of the Spored stacks (shares add up to 1), or [] when unknown.
func spore_credit() -> Array:
	if not has(SPORED):
		return []
	var total := 0
	for key in _spore_by:
		if is_instance_valid(_spore_by[key][0]):
			total += _spore_by[key][1]
	if total <= 0:
		return []
	var out := []
	for key in _spore_by:
		var entry: Array = _spore_by[key]
		if is_instance_valid(entry[0]):
			out.append([entry[0], float(entry[1]) / total])
	return out

# The quiet add (dream_council_review.md 20 "New shared code"): stacks go up to the normal limit; the clock, strength and
# source do not change; it never starts a status that is not there; Poisoned joins its oldest live batch; never Rooted.
# Charged stops one short of a bolt. Returns the stacks added. (Roguelite Code; the class and lent cards use it.)
func add_quiet(id: StringName, amount: int) -> int:
	if amount <= 0 or id == HELD or not has(id):
		return 0
	var status: Dictionary = _active[id]
	var cap := get_max_stacks(id)
	if id == STATIC:
		cap -= 1
	var added := clampi(cap - int(status.stacks), 0, amount)
	if added <= 0:
		return 0
	status.stacks = int(status.stacks) + added
	if int(status.stacks) >= get_max_stacks(id):
		status_filled.emit(id)
	if id == SPORED and not _spore_batches.is_empty():
		_spore_batches[0][1] = int(_spore_batches[0][1]) + added
		_rebuild_spore_credit()
	changes += 1
	return added

# A dose never raises a nightmare's Poisoned limit (dream_council_review.md 20: "the limit unchanged"): after one lands,
# put the limit back to `cap` and drop the oldest stacks over it. (Roguelite Code: a dose credited to a bigger spore
# form raised a full 32 to 64, and the badge showed half.)
func keep_spore_cap(cap: int) -> void:
	if not has(SPORED) or cap <= 0:
		return
	_active[SPORED]["cap"] = cap
	var over := _spore_count() - cap
	while over > 0 and not _spore_batches.is_empty():
		var batch: Array = _spore_batches[0]
		var removed := mini(int(batch[1]), over)
		batch[1] -= removed
		over -= removed
		if batch[1] <= 0:
			_spore_batches.remove_at(0)
	_active[SPORED].stacks = _spore_count()
	_rebuild_spore_credit()
	changes += 1

# Knell: Poisoned's oldest batch is used up (its stacks go; the status ends with its last batch).
func drop_oldest_spore_batch() -> void:
	if not has(SPORED) or _spore_batches.is_empty():
		return
	_spore_batches.remove_at(0)
	var left := _spore_count()
	if left <= 0:
		remove(SPORED)
		return
	_active[SPORED].stacks = left
	_active[SPORED].time = _spore_remaining()
	_rebuild_spore_credit()
	changes += 1

# Puts it to sleep for `seconds` (longest wins), unless it woke less than SLEEP_COOLDOWN ago (or is a
# boss). Every sleep source goes through here. Returns whether it's asleep now.
func sleep(seconds: float) -> bool:
	if is_boss or (sleep_cooldown > 0.0 and sleep_time <= 0.0):
		return sleep_time > 0.0
	sleep_full = seconds if sleep_time <= 0.0 else maxf(sleep_full, seconds)  # (The Asleep badge's ring)
	sleep_time = maxf(sleep_time, seconds)
	return true

# Each finite status lifetime receives at most one second in total.
func preserve_other_statuses(new_id: StringName) -> void:
	for id in _active:
		if id == new_id or id == HELD or (id == MARKED and marked_forever) or (id == STATIC and static_forever):
			continue
		var status: Dictionary = _active[id]
		var extra := 1.0 - float(status.get("tour_extension", 0.0))
		if extra <= 0.0:
			continue
		if id == SPORED:
			for batch in _spore_batches:
				batch[0] += extra
			status.time = _spore_remaining()
		else:
			status.time += extra
		status["tour_extension"] = 1.0
		status["full"] = maxf(float(status.get("full", status.time)), status.time)
		changes += 1

# --- Lingering (Dewdrop's lent cards, owner 2026-10-15: "statuses linger") ---------------------------------------------
# Every Dewdrop card that makes a status last longer goes through linger(), the Calling and its evolutions (Wet Footprints
# included) through linger_calling(): all of them together add at most LINGER_MAX s past the status's last landing
# (LINGER_MAX_STATIC for Charged), so nothing stays up for ever (linger_room). Never Rooted or Drowsy.
const LINGER_MAX := 6.0  # Balancing 2026-10-23: one total for every source (was 4 s for the lent cards + 4 s for the Calling)
const LINGER_MAX_STATIC := 3.0  # Balancing 2026-10-23: Charged's total (was 2 s + 2 s)

# The seconds `id` may still linger, every source together (the lent cards' "lingered" and the Calling's "calling_lingered").
func linger_room(id: StringName) -> float:
	if not _active.has(id):
		return 0.0
	var status: Dictionary = _active[id]
	return (LINGER_MAX_STATIC if id == STATIC else LINGER_MAX) - float(status.get("lingered", 0.0)) - float(status.get("calling_lingered", 0.0))
signal status_ran_out(id: StringName, peak: int, source: Node, potency: float, line: String)  # Ran out of time (not spent)
# A status just reached its most stacks (owner 2026-10-16: "make these dream cards more noticeable"): the nightmare flashes
# it, so every card that stacks or keeps statuses shows its payoff.
signal status_filled(id: StringName)

static func can_linger(id: StringName) -> bool:
	return id != HELD and id != DROWSY  # Soaked lingers too: a Dewdrop build keeps its own Thunderclap and Drown setups (owner 2026-10-15: "with its own family")

# Adds up to `seconds` to `id`'s time left, within the cap. Returns the seconds added.
func linger(id: StringName, seconds: float) -> float:
	if seconds <= 0.0 or not can_linger(id) or not _active.has(id) or (id == MARKED and marked_forever) or (id == STATIC and static_forever):
		return 0.0
	var status: Dictionary = _active[id]
	var room: float = linger_room(id)
	var added := minf(seconds, room)
	if added <= 0.0:
		return 0.0
	status["lingered"] = float(status.get("lingered", 0.0)) + added
	if id == SPORED:
		for batch in _spore_batches:
			batch[0] += added
		status.time = _spore_remaining()
	else:
		status.time += added
	status["full"] = maxf(float(status.get("full", status.time)), status.time)
	changes += 1
	return added

# (F2 lent × Calling, owner 2026-10-18; f1_spec.md) The Calling's own linger (Riverside, Stagnant Water): as linger(), but
# with its own cap past the last landing (CALLING_LINGER_MAX; Charged CALLING_LINGER_MAX_STATIC), inside the one total
# (linger_room: LINGER_MAX past landing for every source together, Charged LINGER_MAX_STATIC; Balancing 2026-10-23).
const CALLING_LINGER_MAX := 4.0
const CALLING_LINGER_MAX_STATIC := 2.0

func linger_calling(id: StringName, seconds: float) -> float:
	if seconds <= 0.0 or not can_linger(id) or not _active.has(id) or (id == MARKED and marked_forever) or (id == STATIC and static_forever):
		return 0.0
	var status: Dictionary = _active[id]
	var room: float = minf((CALLING_LINGER_MAX_STATIC if id == STATIC else CALLING_LINGER_MAX) - float(status.get("calling_lingered", 0.0)),
		linger_room(id))
	var added := minf(seconds, room)
	if added <= 0.0:
		return 0.0
	status["calling_lingered"] = float(status.get("calling_lingered", 0.0)) + added
	if id == SPORED:
		for batch in _spore_batches:
			batch[0] += added
		status.time = _spore_remaining()
	else:
		status.time += added
	status["full"] = maxf(float(status.get("full", status.time)), status.time)
	changes += 1
	return added

# Topped Up: `id`'s time back to what it had when it last landed (never longer). The time given back counts toward the
# linger cap, so a Dewdrop hitting every second can't keep a status up for ever (council 2026-10-15).
func top_up(id: StringName) -> void:
	if not can_linger(id) or not _active.has(id):
		return
	var status: Dictionary = _active[id]
	var landed: float = float(status.get("landed", status.get("full", status.time)))
	if landed > status.time:
		linger(id, landed - status.time)

# Seconds a Dewdrop card added to the landing about to happen (DreamState.class_duration, at most LINGER_MAX), by
# status: apply() books them as "stretched" (the badge's lingering look; a landing's own length, so not the cap).
var pending_linger := {}

# Keyword chips 2026-10-16 (keyword_chips_td.md 2, Linger): a card that brings a status back after it ended (Ebb, Second
# Verse) books those seconds as lingering, so is_lingering stays the one source of truth. Not the linger cap: a landing's
# own length, like "stretched".
var static_lingered := false  # Whether the Charged the last bolt spent was lingering (remove / the bolt in apply set it)

func note_stretched(id: StringName, seconds: float) -> void:
	if seconds <= 0.0 or not can_linger(id) or not _active.has(id):
		return
	_active[id]["stretched"] = maxf(float(_active[id].get("stretched", 0.0)), seconds)
	changes += 1

# Whether `id` lasts longer than it would have (the lingering look on its badge).
func is_lingering(id: StringName) -> bool:
	return _active.has(id) and (float(_active[id].get("lingered", 0.0)) > 0.0 or float(_active[id].get("stretched", 0.0)) > 0.0 \
		or float(_active[id].get("calling_lingered", 0.0)) > 0.0)  # (F2: the Calling's own linger counts too)

# Overtime (evo_shared_spec.md 8, Low Tide): `id` is past its normal time, its time left no more than what the lent cards
# and the Calling added (is_lingering is true as soon as any time was added).
func is_overtime(id: StringName) -> bool:
	if not _active.has(id):
		return false
	var status: Dictionary = _active[id]
	var added := float(status.get("lingered", 0.0)) + float(status.get("calling_lingered", 0.0)) + float(status.get("stretched", 0.0))
	return added > 0.0 and float(status.time) <= added

# Kept (evo_fixed_dewdrop.md "Kept"): a Dewdrop Support row stopped or slowed `id` running down this poll (mark_kept), or
# it is in overtime. Low Tide, Slow Burn and the kept bar read it, never is_lingering.
const KEPT_FOR := 0.15  # Seconds a mark_kept holds (a class poll is 0.1 s)
func mark_kept(id: StringName, seconds: float = KEPT_FOR) -> void:
	if _active.has(id):
		_active[id]["kept_until"] = float(_active[id].get("age", 0.0)) + seconds  # On the status's own age (game time)

func is_kept(id: StringName) -> bool:
	if not _active.has(id):
		return false
	return float(_active[id].get("age", 0.0)) <= float(_active[id].get("kept_until", -1.0)) or is_overtime(id)

# How long `id` has been on the nightmare without wearing off, and the most stacks it has had in that time.
func age(id: StringName) -> float:
	return float(_active[id].get("age", 0.0)) if _active.has(id) else 0.0

func peak(id: StringName) -> int:
	return int(_active[id].get("peak", _active[id].stacks)) if _active.has(id) else 0

func oldest_age() -> float:
	var best := 0.0
	for id in _active:
		best = maxf(best, float(_active[id].get("age", 0.0)))
	return best

# Old Rain: the oldest status's age just before a Reaction spent it (Enemy.apply_status stamps it; same frame only).
var reaction_age := 0.0
var reaction_age_frame := -1

# Grand Tour was reworked (card_review_2026-10-12.md 10): it no longer extends other statuses. It is hit damage now
# (DreamState.on_hit_multiplier). Kept as a no-op for its callers.
func _grand_tour_new_status(id: StringName, applier: Node) -> void:
	pass

func pin_steadfast() -> bool:
	if is_boss or HELD in immune or is_on_cooldown(&"steadfast_pin") or has(HELD) or hold_cooldown > 0.0:
		return false
	_lifecycle[HELD] = lifecycle_serial(HELD) + 1
	_active[HELD] = {"stacks": 1, "time": 0.4, "full": 0.4, "potency": 0.0}
	start_cooldown(&"steadfast_pin", 4.0)
	applications += 1
	changes += 1
	return true

# Move native cohorts, retaining their clocks and contributors without refreshing either side.
func transfer_spores_to(other: EnemyStatuses, max_stacks: int = 3) -> int:
	if other == null or other == self or not has(SPORED) or SPORED in other.immune:
		return 0
	var donor: Dictionary = _active[SPORED]
	var receiver: Dictionary = other._active.get(SPORED, {"stacks": 0, "time": 0.0, "potency": 0.0})
	var moved := mini(mini(maxi(max_stacks, 0), _spore_count()), maxi(0, other.get_max_stacks(SPORED) - int(receiver.stacks)))
	if moved <= 0:
		return 0
	var fresh := not other.has(SPORED)
	var remaining := moved
	while remaining > 0 and not _spore_batches.is_empty():
		var batch: Array = _spore_batches[0]
		var amount := mini(remaining, int(batch[1]))
		other._spore_batches.append([batch[0], amount, batch[2]])
		batch[1] -= amount
		remaining -= amount
		if batch[1] <= 0:
			_spore_batches.remove_at(0)
	# Keep cohort expiry order for later native capacity replacements, then the moved stacks join the pile's one clock.
	other._spore_batches.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	other._share_spore_clock()
	receiver.stacks = other._spore_count()
	receiver.time = other._spore_remaining()
	receiver["full"] = maxf(float(receiver.get("full", 0.0)), receiver.time)
	if donor.potency >= receiver.potency:
		for key in ["potency", "line", "source", "strength"]:
			if donor.has(key):
				receiver[key] = donor[key]
	other._active[SPORED] = receiver
	if fresh:
		other._lifecycle[SPORED] = other.lifecycle_serial(SPORED) + 1
	other._rebuild_spore_credit()
	_rebuild_spore_credit()
	donor.stacks = _spore_count()
	donor.time = _spore_remaining()
	if donor.stacks <= 0:
		remove(SPORED)
	other.applications += 1
	other.changes += 1
	if fresh:
		other._grand_tour_new_status(SPORED, receiver.get("source"))
	changes += 1
	return moved
