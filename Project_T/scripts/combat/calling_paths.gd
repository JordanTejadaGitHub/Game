extends RefCounted
# Calling evolutions (owner 2026-10-15/16; council D:\Projects\logs\dream_council\calling_evolution_*.md): the Calling (the
# first family's built-in rule) grows through the run by play style, not by family. At the drift 5 rest the player picks
# a style (Spread / Focus / Support), at the drift 25 boss rest one of its two follow-ups, at 50 that follow-up's
# capstone, and at 75 (the slot Heartwood's Gifts left) the Calling also learns the style's other follow-up. Deepen only.
# The picks are shown on the Dream screen as cards built here (no rarity, no reroll, let-go or let-it-pass); the path is
# saved as ids in DreamState.calling_path. Each Calling's node reads it (class_kit.evo). Visible-event rule (owner
# 2026-10-16): every evolution shows what it does on screen, often.
# Preloaded as DreamState.CALLING_PATHS (no class_name). Only Callings listed in PATHS evolve; the others keep the drift 5
# class-card Dream until theirs are built.

const DRIFTS: Array[int] = [5, 25, 50, 75]  # Stage 0 style, 1 follow-up, 2 capstone, 3 the other follow-up

const STYLE := 0
const FOLLOW_UP := 1
const CAPSTONE := 2

# id -> {calling, tier, parent, name, text, tip}. Tips name where a style leads (players hate blind trees).
const PATHS := {
	# --- Spore Print (Sporeling) ---------------------------------------------------------------------------------------
	&"sp_windblown": {"calling": "sporeling", "tier": STYLE, "parent": &"", "name": "Windblown", "style": "Spread",
		"text": "When a {mushroom} gives a {dose}, it plants a new {mushroom} 3 {steps} further down the path.",
		"tip": "Planted {mushrooms} don't plant again, and are the first to go when there are too many. Leads to: Spore Season, Witch Ring."},
	&"sp_drifting": {"calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_windblown", "name": "Drifting Spores",
		"text": "A {dose} also adds 2 {stacks} to every other status the nightmare carries.",
		"tip": "A status it fills flashes. Never starts a status. Never {held}. Leads to: Spore Season."},
	&"sp_season": {"calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_drifting", "name": "Spore Season",
		"text": "While 15 or more {mushrooms} grow, every {dose} is 50% bigger.",
		"tip": "{Mushrooms} planted by Windblown don't count. The {mushrooms} glow while it is on."},
	&"sp_fairy_path": {"calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_windblown", "name": "Fairy Path",
		"text": "A {mushroom} on a {step} {touching} a spore Warden and another attacking Warden grows back 8 s after it is used.",
		"tip": "The clock only runs during a {drift}. These {mushrooms} are all back when a {rest} starts. Leads to: Witch Ring."},
	&"sp_witch_ring": {"calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_fairy_path", "name": "Witch Ring",
		"text": "When a nightmare steps on 3 {mushrooms} within 4 s, it is {held} for 1 s (bosses 0.5 s).",
		"tip": "Each nightmare once every 10 s."},
	&"sp_clump": {"calling": "sporeling", "tier": STYLE, "parent": &"", "name": "Clump", "style": "Focus",
		"text": "A new {mushroom} joins one within 3 {steps}, up to 4 in a clump. A clump gives a {dose} for each {mushroom}, then loses one.",
		"tip": "Clump: {mushrooms} grown together on one {step}. Clumps form where your {spored} nightmares fall. Leads to: Mire-Mouth, Rotburst."},
	&"sp_sticky": {"calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_clump", "name": "Sticky Caps",
		"text": "A nightmare stepping on a clump walks at half speed for 1 s for each {mushroom} in it, up to 3 s.",
		"tip": "Bosses half as long. Each clump once per nightmare. Leads to: Mire-Mouth."},
	&"sp_mire_mouth": {"calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_sticky", "name": "Mire-Mouth",
		"text": "When Sticky Caps slows a nightmare, the 2 nearest nightmares behind it within 2 cells are slowed too, half as long.",
		"tip": "Behind: no further along the path. Never bosses or flyers."},
	&"sp_rot": {"calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_clump", "name": "Rot",
		"text": "A clump's {dose} adds 2 {stacks} to every other status the nightmare carries, for each {mushroom} in the clump.",
		"tip": "A status it fills flashes. Never starts a status. Never {held}. Leads to: Rotburst."},
	&"sp_rotburst": {"calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_rot", "name": "Rotburst",
		"text": "A clump's last {mushroom} bursts when eaten, giving up to 6 nightmares within 1.5 cells a {dose} and 2 {stacks} of the eater's statuses.",
		"tip": "Only a clump that once held 2 or more {mushrooms} bursts. Never {drowsy} or {held}."},
	&"sp_borrowed": {"calling": "sporeling", "tier": STYLE, "parent": &"", "name": "Borrowed Spores", "style": "Support",
		"text": "A {mushroom} {touching} one of your Wardens also gives 2 {stacks} of that Warden's status. A Sprout {touching} it adds 2 more {stacks} of {spored}.",
		"tip": "Leads to: Outbreak, Mother Spore. Grows stronger with a second family."},
	&"sp_catching": {"calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_borrowed", "name": "Catching",
		"text": "When a nightmare takes a {dose}, it passes half of it to the first nightmare it touches within 2 s.",
		"tip": "Once per {dose}. Leads to: Outbreak. Grows stronger with a second family."},
	&"sp_outbreak": {"calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_catching", "name": "Outbreak",
		"text": "A passed {dose} can pass on again, up to 3 times, halving each time.",
		"tip": "It stops at 1 {stack}. Grows stronger with a second family."},
	&"sp_feeding": {"calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_borrowed", "name": "Feeding Ground",
		"text": "For 4 s after a nightmare takes a {dose}, Wardens {touching} that {step} add 1 more {stack} with their status hits on it.",
		"tip": "Each Warden once per nightmare. Leads to: Mother Spore. Grows stronger with a second family."},
	&"sp_mother": {"calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_feeding", "name": "Mother Spore",
		"text": "A {mushroom} left by a {dispel} remembers up to 4 of the nightmare's statuses. Its {dose} gives 2 {stacks} of each.",
		"tip": "Its cap is speckled. Never {drowsy} or {held}. Grows stronger with a second family."},
	# --- Lantern Light (Firefly Jar) -----------------------------------------------------------------------------------
	&"lf_strung_lights": {"calling": "firefly_jar", "tier": STYLE, "parent": &"", "name": "Strung Lights", "style": "Spread",
		"text": "Where two glows on the path are up to 4 {steps} apart, the path between them glows too.",
		"tip": "Nightmares there are {lit}. This light never reveals {kind_hidden} nightmares. Leads to: Bale-fires, Swarm Night."},
	&"lf_torchbearers": {"calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_strung_lights", "name": "Torchbearers",
		"text": "When a {lit} nightmare is dispelled, half that hit {jumps} to the nearest {lit} nightmare further along the path.",  # Hard cards 2026-10-16
		"tip": "Further along: at most 8 {steps} ahead. Bosses take half. Leads to: Bale-fires."},
	&"lf_bale_fires": {"calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_torchbearers", "name": "Bale-fires",
		"text": "When a Torchbearers {jump} dispels, it {jumps} on to the next {lit} nightmare further along, up to 4 more times.",  # Hard cards 2026-10-16
		"tip": "Bosses take half."},
	&"lf_glowworms": {"calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_strung_lights", "name": "Glowworms",
		"text": "Up to 2 Sprouts {touching} each Firefly Warden glow too, lighting the path they touch.",
		"tip": "The Sprouts nearest the Heartwood glow first. Sprout light never reveals {kind_hidden} nightmares. Leads to: Swarm Night."},
	&"lf_swarm_night": {"calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_glowworms", "name": "Swarm Night",
		"text": "While 10 or more nightmares are {lit}, every {jump} {jumps} once more.",
		"tip": "The extra {jump} is as strong as the first and goes to the nearest {lit} nightmare it hasn't hit. Bosses take half."},
	&"lf_bonfire": {"calling": "firefly_jar", "tier": STYLE, "parent": &"", "name": "Bonfire", "style": "Focus",
		"text": "Path inside two Firefly Wardens' glows burns gold. A {dispel} there {jumps} to 2 {lit} nightmares instead of 1.",
		"tip": "Leads to: Pyre, Witchfire."},
	&"lf_moth_to_flame": {"calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_bonfire", "name": "Moth to Flame",
		"text": "A {jump} that lands on gold path adds 2 {stacks} of {marked}.",
		"tip": "{marked} only works from {stacks:need_marked} {stacks}: watch it build. Bosses get 1. Leads to: Pyre."},
	&"lf_pyre": {"calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_moth_to_flame", "name": "Pyre",
		"text": "A {jump} that dispels a nightmare on gold path {jumps} again at the same strength, up to 3 times.",
		"tip": "A boss's summons count too. Bosses take half."},
	&"lf_embers": {"calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_bonfire", "name": "Embers",
		"text": "A nightmare dispelled on gold path leaves an ember for 4 s. The next nightmare to reach it takes half the dispelling hit.",
		"tip": "At most 8 embers at once. They go out when a {rest} starts. Bosses take half. Leads to: Witchfire."},
	&"lf_witchfire": {"calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_embers", "name": "Witchfire",
		"text": "Embers within 2 {steps} of each other pile up, up to 3. A pile bursts on every nightmare within 1 cell.",
		"tip": "A pile hits with all its embers at once. At most 6 nightmares. Bosses take half."},
	&"lf_borrowed_light": {"calling": "firefly_jar", "tier": STYLE, "parent": &"", "name": "Borrowed Light", "style": "Support",
		"text": "When a Warden that isn't a Firefly Warden hits a {lit} nightmare, a third of the hit {jumps} to the nearest other {lit} nightmare.",
		"tip": "Sprouts count. Each Warden once a second. Leads to: Lantern Wake, Constellation. Grows stronger with a second family."},
	&"lf_show_the_way": {"calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_borrowed_light", "name": "Show the Way",
		"text": "Wardens in a Firefly Warden's glow add 1 more {stack} with their status hits on {lit} nightmares.",
		"tip": "Never starts a status. Never {drowsy}. Each Warden once a second. Leads to: Lantern Wake. Grows stronger with a second family."},
	&"lf_lantern_wake": {"calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_show_the_way", "name": "Lantern Wake",
		"text": "A {jump} adds 1 {stack} of each of its nightmare's statuses to the nightmare it lands on.",
		"tip": "At most 4 statuses. Never starts a status. Never {held}. Grows stronger with a second family."},
	&"lf_sightline": {"calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_borrowed_light", "name": "Sightline",
		"text": "When 3 different Wardens hit the same {lit} nightmare within 2 s, a quarter of each hit {jumps} to the nearest other {lit} nightmare.",
		"tip": "Sprouts count. At most 4 Wardens. Each nightmare once every 4 s. Leads to: Constellation. Grows stronger with a second family."},
	&"lf_constellation": {"calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_sightline", "name": "Constellation",
		"text": "When {jumps} from 3 different Wardens hit a nightmare within 3 s, it becomes {full} {marked}.",
		"tip": "Bosses get half the {stacks}. Each nightmare once every 8 s. Grows stronger with a second family."},
	# --- Keeping Time (Bellflower) -------------------------------------------------------------------------------------
	&"kt_evo_carrying_tune": {"calling": "bellflower", "tier": STYLE, "parent": &"", "name": "Carrying Tune", "style": "Spread",
		"text": "A bell's ring also lands at half on nightmares up to 4 {steps} further down the path. These rings fill pips too.",
		"tip": "Starts past a pulsing bell's range or a shooting bell's target; stops at the next bell's range. A shot carries to up to 4 nightmares. Leads to: Peal, Night Choir."},
	&"kt_evo_hand_to_hand": {"calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_carrying_tune", "name": "Hand to Hand",
		"text": "When a nightmare reaches a new bell, that bell's first ring on it fills 2 pips.",
		"tip": "Pips stay lit between bells. Once for each Warden and nightmare. Leads to: Peal."},
	&"kt_evo_peal": {"calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_hand_to_hand", "name": "Peal",
		"text": "A {toll} fills 1 pip on every nightmare within 4 {steps} of it, but never its last pip.",
		"tip": "Only a bell's ring can make the {toll}. At most 8 nightmares."},
	&"kt_evo_lingering_note": {"calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_carrying_tune", "name": "Lingering Note",
		"text": "A {toll} leaves a note on the path for 2 s. Each nightmare walking through it is rung once.",
		"tip": "One note for each bell; its next {toll} moves it. Leads to: Night Choir."},
	&"kt_evo_night_choir": {"calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_lingering_note", "name": "Night Choir",
		"text": "A note {touching} a Warden also lands that Warden's last hit again, at half, on each nightmare walking through it.",
		"tip": "At most 3 Wardens for each note, the strongest first. Never more than 1 s of that Warden's damage."},
	&"kt_evo_steady_beat": {"calling": "bellflower", "tier": STYLE, "parent": &"", "name": "Steady Beat", "style": "Focus",
		"text": "Nightmares in range of 2 or more bells start with 3 pips filled, and their {tolls} land in full.",
		"tip": "Where bells overlap, the path shows a double ring. Leads to: Midnight Bell, Sleeping Hall."},
	&"kt_evo_crescendo": {"calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_steady_beat", "name": "Crescendo",
		"text": "Each {toll} on a nightmare makes its next {toll} 25% stronger, up to +100%.",
		"tip": "Its pips grow bigger and brighter. Leads to: Midnight Bell."},
	&"kt_evo_midnight_bell": {"calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_crescendo", "name": "Midnight Bell",
		"text": "The 12th ring on a nightmare is a Midnight Toll: every damaging status on it pays out at once and stays.",
		"tip": "{spored} ticks once, {static} bolts, {damp} calls up to 2 {warden:dewdrop}s {near} it for a {free_hit}. A dial counts the rings. Once per nightmare. Bosses take half."},
	&"kt_evo_hush_a_bye": {"calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_steady_beat", "name": "Hush-a-bye",
		"text": "A {toll} adds 2 {stacks} of {drowsy}. After 3 {tolls} within 6 s, the nightmare falls {asleep} for 1 s.",
		"tip": "Never bosses or a nightmare already {asleep}. Each nightmare once every 8 s. Leads to: Sleeping Hall."},
	&"kt_evo_sleeping_hall": {"calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_hush_a_bye", "name": "Sleeping Hall",
		"text": "When a Hush-a-bye sleep ends, the nightmare's next {toll} within 3 s also lands at half on up to 4 nightmares touching it.",
		"tip": "Only that one {toll} spreads."},
	&"kt_evo_accompaniment": {"calling": "bellflower", "tier": STYLE, "parent": &"", "name": "Accompaniment", "style": "Support",
		"text": "Hits from Wardens {touching} a bell fill pips too, and their {tolls} repeat that Warden's hit and status.",
		"tip": "Other Wardens fill a pip once a second; a Sprout fills one with every hit. Their pips glow pink. Leads to: Symphony, Last Chord. Grows stronger with a second family."},
	&"kt_evo_counterpoint": {"calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_accompaniment", "name": "Counterpoint",
		"text": "When a Warden that isn't a bell makes a {toll}, the nearest bell within 4 cells rings that nightmare too.",
		"tip": "The ring is a {free_hit} and fills a pip. Each bell once a second. Leads to: Symphony. Grows stronger with a second family."},
	&"kt_evo_symphony": {"calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_counterpoint", "name": "Symphony",
		"text": "When 4 different Wardens filled a nightmare's pips, its {toll} lands each one's last hit again, at half.",
		"tip": "Counts from a nightmare's second {toll}: its 2 starting pips belong to no Warden. Each nightmare once every 6 s. Grows stronger with a second family."},
	&"kt_evo_chime_of_many": {"calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_accompaniment", "name": "Chime of Many",
		"text": "A {toll} adds 1 {stack} to each status on the nightmare and on up to 4 nightmares touching it.",
		"tip": "Each status it adds to flashes. Never starts a status. Never {drowsy} or {held}. Leads to: Last Chord. Grows stronger with a second family."},
	&"kt_evo_last_chord": {"calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_chime_of_many", "name": "Last Chord",
		"text": "A {toll} on a nightmare with 3 or more statuses sets off any {reaction} it is halfway to.",
		"tip": "Each nightmare once every 8 s, counted only when a {reaction} goes off. Grows stronger with a second family."},
	# --- Puddles (Dewdrop) -----------------------------------------------------------------------------------------------
	&"dw_stream": {"calling": "dewdrop", "tier": STYLE, "parent": &"", "name": "Stream", "style": "Spread",
		"text": "{Water} flows on: the 4 {steps} of path past the end of each {water} are {water} too.",
		"tip": "It flows toward the Heartwood and joins the next {water} it reaches. Leads to: Flood, Spring Flood."},
	&"dw_millrace": {"calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_stream", "name": "Millrace",
		"text": "A ripple also carries 1 {stack} of up to 3 other statuses on the hit nightmare to every nightmare it reaches.",
		"tip": "A thread shows each carry. Never {drowsy} or {held}; {static} stops 1 short of a bolt. Leads to: Flood."},
	&"dw_flood": {"calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_millrace", "name": "Flood",
		"text": "A ripple runs the whole length of its {water}, up to 24 {steps} each way.",
		"tip": "A long ripple flashes along the {water}."},
	&"dw_lapping_water": {"calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_stream", "name": "Lapping Water",
		"text": "When a Warden other than a {warden:dewdrop} {touching} {water} hits a {damp} nightmare in it, the hit ripples 2 {steps}.",
		"tip": "Sprouts count. Each Warden once a second. Leads to: Spring Flood."},
	&"dw_spring_flood": {"calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_lapping_water", "name": "Spring Flood",
		"text": "Every 10 s, up to 8 nightmares in the longest {water} become {full} {damp} and walk 25% slower for 2 s.",
		"tip": "The clock only runs during a {drift}. Bosses are slowed half as much."},
	&"dw_black_pond": {"calling": "dewdrop", "tier": STYLE, "parent": &"", "name": "Black Pond", "style": "Focus",
		"text": "{Water} {touching} 2 or more {warden:dewdrop}s is a pond: nightmares in it walk 25% slower, and its ripple runs 8 {steps}.",
		"tip": "Ponds are drawn darker. Bosses are slowed half as much. Leads to: Drowning Deep, Drowned Hands."},
	&"dw_whirlpool": {"calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_black_pond", "name": "Whirlpool",
		"text": "A {full} {damp} nightmare in a pond is pulled back 2 {steps}. Once for each pond and nightmare.",
		"tip": "Never bosses or flyers. Leads to: Drowning Deep."},
	&"dw_drowning_deep": {"calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_whirlpool", "name": "Drowning Deep",
		"text": "A Whirlpool pull drags up to 4 nightmares within 1 cell with it. Every Warden {touching} the pond gets a {free_hit} on the pulled one.",
		"tip": "Never drags bosses or flyers. Free hits: each Warden once a second."},
	&"dw_stagnant_water": {"calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_black_pond", "name": "Stagnant Water",
		"text": "Statuses added to nightmares in a pond get 1 more {stack}.",
		"tip": "A splash shows each extra {stack}. Never {drowsy} or {held}. Each Warden once a second. Leads to: Drowned Hands."},
	&"dw_drowned_hands": {"calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_stagnant_water", "name": "Drowned Hands",
		"text": "A nightmare with 4 or more statuses in a pond is {held} for 1 s (bosses 0.5 s). Once for each pond and nightmare.",
		"tip": "The pond's strongest {warden:dewdrop} makes it {held}."},
	&"dw_riverside": {"calling": "dewdrop", "tier": STYLE, "parent": &"", "name": "Riverside", "style": "Support",
		"text": "Wardens {touching} {water} add 1 more {stack} with their first status hit on each nightmare in that {water}.",
		"tip": "{warden:dewdrop}s count. Sprouts don't count. A splash shows each extra {stack}. Leads to: Downpour, Reflection. Grows stronger with a second family."},
	&"dw_rain_on_the_bank": {"calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_riverside", "name": "Rain on the Bank",
		"text": "A ripple gives every nightmare it reaches 1 {stack} of the status of each other Warden {touching} that {water}.",
		"tip": "At most 3 Wardens, the strongest first. Never {drowsy} or {held}. Leads to: Downpour. Grows stronger with a second family."},
	&"dw_downpour": {"calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_rain_on_the_bank", "name": "Downpour",
		"text": "When a ripple reaches 4 or more nightmares, every other Warden {touching} that {water} attacks one of them at once.",
		"tip": "Each Warden once every 4 s. Grows stronger with a second family."},
	&"dw_wet_footprints": {"calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_riverside", "name": "Wet Footprints",
		"text": "A {damp} nightmare leaving {water} leaves wet {steps} behind it for 3 s. Wet {steps} count as {water}.",
		"tip": "At most 6 {steps} for each nightmare. Wet {steps} never leave more. Leads to: Reflection. Grows stronger with a second family."},
	&"dw_reflection": {"calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_wet_footprints", "name": "Reflection",
		"text": "When another Warden {touching} {water} hits a {damp} nightmare in it, half the hit also lands on the last nightmare in that {water}.",
		"tip": "Half of the hit before defences. Each Warden once a second. Grows stronger with a second family."},
}

static func has_paths(calling: String) -> bool:
	for id in PATHS:
		if PATHS[id].calling == calling:
			return true
	return false

static func stage_of(drift: int) -> int:
	return DRIFTS.find(drift)

# The ids offered next for `calling` after `path` (the ids taken so far, in order), or [].
static func next_ids(calling: String, path: Array) -> Array[StringName]:
	var out: Array[StringName] = []
	if path.is_empty():
		for id in PATHS:
			if PATHS[id].calling == calling and int(PATHS[id].tier) == STYLE:
				out.append(id)
		return out
	if path.size() == 1:
		return children(path[0])
	if path.size() == 2:
		return children(path[1])
	if path.size() == 3:  # Drift 75: the style's other follow-up
		for id in children(path[0]):
			if not path.has(id):
				out.append(id)
	return out

static func children(parent: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in PATHS:
		if PATHS[id].parent == parent:
			out.append(id)
	return out

static func display_name(id: StringName) -> String:
	return String(PATHS[id].name) if PATHS.has(id) else String(id)

# The card the Dream screen shows for evolution `id` (built fresh; never in the Dream pool, never taken as a card).
static func card(id: StringName) -> UpgradeData:
	var row: Dictionary = PATHS[id]
	var out := UpgradeData.new()
	out.id = String(id)
	out.display_name = row.name
	out.description = row.text
	var head := ("%s style. " % row.style) if row.has("style") else ""
	out.tip = head + String(row.tip)
	out.rarity = UpgradeData.Rarity.COMMON
	out.kind = UpgradeData.Kind.RULE
	out.calling = String(row.calling)
	out.max_stacks = 1
	out.tags = ["calling_evolution"]
	return out

# "Spore Print → Clump → Sticky Caps" for the badge and the Dreams panel.
static func path_text(calling_title: String, path: Array) -> String:
	var parts: Array[String] = [calling_title]
	for id in path:
		parts.append(display_name(id))
	return " → ".join(parts)
