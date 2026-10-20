extends RefCounted
# Calling evolutions (owner 2026-10-15/16; council D:\Projects\logs\dream_council\calling_evolution_*.md): the Calling (the
# first family's built-in rule) grows through the run by play style, not by family. At the drift 5 rest the player picks
# a style (Spread / Focus / Support), at the drift 25 boss rest one of its two follow-ups, at 45 that follow-up's
# capstone (was 50; moved 2026-10-19 so the demo, which ends at 50, plays it), and at 75 (the slot Heartwood's Gifts left) the Calling also learns the style's other follow-up. Deepen only.
# The picks are shown on the Dream screen as cards built here (no rarity, no reroll, let-go or let-it-pass); the path is
# saved as ids in DreamState.calling_path. Each Calling's node reads it (class_kit.evo). Visible-event rule (owner
# 2026-10-16): every evolution shows what it does on screen, often.
# Preloaded as DreamState.CALLING_PATHS (no class_name). Only Callings listed in PATHS evolve; the others keep the drift 5
# class-card Dream until theirs are built.

const DRIFTS: Array[int] = [5, 25, 45, 75]  # Stage 0 style, 1 follow-up, 2 capstone, 3 the other follow-up

const STYLE := 0
const FOLLOW_UP := 1
const CAPSTONE := 2

# id -> {makes, uses, calling, tier, parent, name, text, tip}. No style, "Leads to" or other direction on a card or its tip
# (owner 2026-10-17: no hand-holding; the player finds the path).
# makes / uses: keyword chips (keyword chips 2026-10-16; scripts/run/dream_keywords.gd), at most 2 in all.
const PATHS := {
	# --- Spore Print (Sporeling) ---------------------------------------------------------------------------------------
	&"sp_windblown": {"makes": [&"poisoned"], "uses": [&"maze"], "calling": "sporeling", "tier": STYLE, "parent": &"", "name": "Windblown", "style": "Spread",
		"text": "Your {mushrooms} spread down the path: each time a {mushroom} gives a {dose}, a new {mushroom} grows 3 {steps} further on.",
		"tip": "Planted {mushrooms} don't plant again, and are the first to go when there are too many."},
	&"sp_drifting": {"makes": [&"stacks"], "uses": [], "calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_windblown", "name": "Drifting Spores",
		"text": "A {dose} also adds 2 {stacks} to each other status the nightmare already has.",
		"tip": "A status it makes {full} flashes. Never starts a status. Never {held}."},
	&"sp_season": {"makes": [&"stacks"], "uses": [], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_drifting", "name": "Spore Season",
		"text": "While 15 or more {mushrooms} are growing, every {dose} is 50% bigger.",
		"tip": "Windblown's {mushrooms} count too. The {mushrooms} glow while it is on."},
	&"sp_fairy_path": {"makes": [], "uses": [&"cluster"], "calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_windblown", "name": "Fairy Path",
		"text": "A {step} {touching} 2 or more attacking Wardens grows a {mushroom}, and grows it back 8 s after it is used.",
		"tip": "The clock only runs during a {drift}. These {mushrooms} are all back when a {rest} starts."},
	&"sp_witch_ring": {"makes": [&"rooted"], "uses": [], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_fairy_path", "name": "Witch Ring",
		"text": "A nightmare that steps on 3 {mushrooms} within 4 s gains 1 {held}: it can't move for 1 s (bosses 0.5 s).",
		"tip": "Each nightmare once every 10 s."},
	&"sp_clump": {"makes": [&"stacks"], "uses": [], "calling": "sporeling", "tier": STYLE, "parent": &"", "name": "Clump", "style": "Focus",
		"text": "A new {mushroom} joins one within 3 {steps}, up to 4 in a clump. Stepping on a clump gives a {dose} for each of its {mushrooms}.",
		"tip": "Clump: {mushrooms} grown together on one {step}. A clump loses one {mushroom} each time a nightmare steps on it. Clumps form where nightmares with your {spored} fall."},
	&"sp_sticky": {"makes": [&"slow"], "uses": [], "calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_clump", "name": "Sticky Caps",
		"text": "A nightmare that steps on a clump walks at half speed: 1 s for each {mushroom} in the clump, up to 3 s.",
		"tip": "Bosses half as long. Each clump once per nightmare."},
	&"sp_mire_mouth": {"makes": [&"slow"], "uses": [], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_sticky", "name": "Mire-Mouth",
		"text": "When Sticky Caps slows a nightmare, the 2 nearest nightmares behind it are slowed too, for half as long.",
		"tip": "Behind: no further along the path, within 2 cells. Never bosses or flyers."},
	&"sp_rot": {"makes": [&"stacks"], "uses": [&"layered"], "calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_clump", "name": "Rot",
		"text": "A clump's {dose} also adds 2 {stacks} for each {mushroom} in it to each other status the nightmare already has.",
		"tip": "A status it makes {full} flashes. Never starts a status. Never {held}."},
	&"sp_rotburst": {"makes": [&"layered"], "uses": [], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_rot", "name": "Rotburst",
		"text": "When a clump's last {mushroom} is used, it bursts: nightmares within 1.5 cells take a {dose} and 2 {stacks} of each status the stepper had.",
		"tip": "Only a clump that once had 2 or more {mushrooms} bursts. At most 6 nightmares. Never {drowsy} or {held}."},
	&"sp_borrowed": {"makes": [&"layered"], "uses": [&"cluster"], "calling": "sporeling", "tier": STYLE, "parent": &"", "name": "Borrowed Spores", "style": "Support",
		"text": "A {mushroom} also gives 2 {stacks} of the status of the strongest Warden {touching} it, and 2 more {spored} if a Sprout touches it.",
		"tip": ""},
	&"sp_catching": {"makes": [&"poisoned"], "uses": [], "calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_borrowed", "name": "Catching",
		"text": "A nightmare that takes a {dose} passes half of it to the first nightmare it bumps into within 2 s.",
		"tip": "Once per {dose}."},
	&"sp_outbreak": {"makes": [&"poisoned"], "uses": [], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_catching", "name": "Outbreak",
		"text": "A passed-on {dose} can pass on again, up to 3 times, halving each time.",
		"tip": "It stops at 1 {stack}."},
	&"sp_feeding": {"makes": [&"stacks"], "uses": [], "calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_borrowed", "name": "Feeding Ground",
		"text": "For 4 s after a nightmare takes a {dose}, Wardens {touching} that {step} add 1 more {stack} with each status hit on it.",
		"tip": "Each Warden once per nightmare."},
	&"sp_mother": {"makes": [&"layered"], "uses": [], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_feeding", "name": "Mother Spore",
		"text": "A {mushroom} left by a {dispel} keeps that nightmare's statuses. The next nightmare to step on it gets 2 {stacks} of each.",
		"tip": "Its cap is speckled. At most 4 statuses. Never {drowsy} or {held}."},
	# --- Lantern Light (Firefly Jar) -----------------------------------------------------------------------------------
	&"lf_strung_lights": {"makes": [], "uses": [&"maze"], "calling": "firefly_jar", "tier": STYLE, "parent": &"", "name": "Strung Lights", "style": "Spread",
		"text": "Glows up to 4 {steps} apart join up. Firefly Wardens deal 5% more to a nightmare for each glow it has entered, up to +25%.",  # Self-sufficiency audit 2026-10-18
		"tip": "Join up: the path between them glows too, so nightmares there are {lit}. A joined stretch is not a new glow. Hits only. This light never reveals {kind_hidden} nightmares."},
	&"lf_torchbearers": {"makes": [&"jump"], "uses": [], "calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_strung_lights", "name": "Torchbearers",
		"text": "When a {lit} nightmare is dispelled, half the hit that dispelled it {jumps} to the nearest {lit} nightmare ahead of it on the path.",  # Hard cards 2026-10-16
		"tip": "Ahead: at most 8 {steps} further along the path. Bosses take half."},
	&"lf_bale_fires": {"makes": [&"repeat"], "uses": [&"jump"], "calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_torchbearers", "name": "Bale-fires",
		"text": "If a Torchbearers {jump} dispels its target, it {jumps} again to the next {lit} nightmare ahead, up to 4 more times.",  # Hard cards 2026-10-16
		"tip": "Bosses take half."},
	&"lf_glowworms": {"makes": [], "uses": [&"cluster"], "calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_strung_lights", "name": "Glowworms",
		"text": "Up to 2 Sprouts {touching} each Firefly Warden glow too, so the path next to them is {lit}.",
		"tip": "The Sprouts nearest the Heartwood glow first. Sprout light never reveals {kind_hidden} nightmares."},
	&"lf_swarm_night": {"makes": [], "uses": [&"jump"], "calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_glowworms", "name": "Swarm Night",
		"text": "While 6 or more nightmares are {lit}, every {jump} {jumps} one extra time.",
		"tip": "The extra {jump} is as strong as the first and goes to the nearest {lit} nightmare it hasn't hit. Bosses take half."},
	&"lf_bonfire": {"makes": [&"jump"], "uses": [], "calling": "firefly_jar", "tier": STYLE, "parent": &"", "name": "Bonfire", "style": "Focus",
		"text": "Path inside 2 or more Firefly Wardens' glows turns gold. Firefly Wardens deal 25% more there, and a {dispel} there {jumps} to 2 {lit} nightmares.",  # Self-sufficiency audit 2026-10-18
		"tip": "Gold: drawn on the path. Hits only, not {jumps} or bolts. Multiplies with your other Dream damage."},
	&"lf_moth_to_flame": {"makes": [&"exposed"], "uses": [&"jump"], "calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_bonfire", "name": "Moth to Flame",
		"text": "A {jump} that lands on a nightmare on gold path adds 2 {stacks} of {marked}.",
		"tip": "{marked} only works from {stacks:need_marked} {stacks}: watch it build. Ember hits count as {jumps}. Bosses get 1."},
	&"lf_pyre": {"makes": [], "uses": [&"jump"], "calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_moth_to_flame", "name": "Pyre",
		"text": "If a {jump} dispels a nightmare on gold path, it {jumps} again at full strength, up to 3 times.",
		"tip": "A boss's summons count too. Bosses take half."},
	&"lf_embers": {"makes": [&"repeat"], "uses": [], "calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_bonfire", "name": "Embers",
		"text": "A nightmare dispelled on gold path leaves an ember for 4 s. The next nightmare over it takes half the hit that dispelled it.",
		"tip": "At most 8 embers at once. They go out when a {rest} starts. Bosses take half."},
	&"lf_witchfire": {"makes": [], "uses": [], "calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_embers", "name": "Witchfire",
		"text": "Embers within 2 {steps} of each other gather into a pile. When a nightmare reaches the pile, it hits every nightmare within 1 cell.",
		"tip": "A pile hits with all its embers at once. At most 3 embers to a pile. At most 6 nightmares. Bosses take half."},
	&"lf_borrowed_light": {"makes": [&"jump"], "uses": [], "calling": "firefly_jar", "tier": STYLE, "parent": &"", "name": "Borrowed Light", "style": "Support",
		"text": "When a Warden that is not a Firefly Warden hits a {lit} nightmare, a third of the hit {jumps} to the nearest other {lit} nightmare.",
		"tip": "Sprouts count. Each Warden once a second. Its {jump} and another card's {jump} from one hit go to different nightmares."},  # F4 (owner 2026-10-18)
	# F3 (owner 2026-10-18; lent_evolution_builds.md): Lantern Wake is Borrowed Light's follow-up, Show the Way its capstone.
	&"lf_lantern_wake": {"makes": [&"layered"], "uses": [&"jump"], "calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_borrowed_light", "name": "Lantern Wake",
		"text": "A {jump} carries statuses with it: the nightmare it lands on gets 1 more {stack} of each status it shares with the first one.",
		"tip": "At most 4 statuses. Never starts a status. Never {held}."},
	&"lf_show_the_way": {"makes": [&"jump"], "uses": [], "calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_lantern_wake", "name": "Show the Way",
		"text": "A Borrowed Light {jump} {jumps} once more, to another {lit} nightmare, at half.",
		"tip": "Never to a nightmare that hit or {jump} already reached. It never {jumps} a third time. Bosses take half."},
	&"lf_sightline": {"makes": [&"jump"], "uses": [], "calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_borrowed_light", "name": "Sightline",
		"text": "When 3 different Wardens hit the same {lit} nightmare within 2 s, a quarter of each hit {jumps} to the nearest other {lit} nightmare.",
		"tip": "Sprouts count. At most 4 Wardens. Each nightmare once every 4 s."},
	&"lf_constellation": {"makes": [&"exposed"], "uses": [&"jump"], "calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_sightline", "name": "Constellation",
		"text": "When {jumps} from 3 different Wardens hit one nightmare within 3 s, it reaches {full} {marked}.",
		"tip": "Bosses get half the {stacks}. Each nightmare once every 8 s."},
	# --- Keeping Time (Bellflower) -------------------------------------------------------------------------------------
	&"kt_evo_carrying_tune": {"makes": [], "uses": [&"maze"], "calling": "bellflower", "tier": STYLE, "parent": &"", "name": "Carrying Tune", "style": "Spread",
		"text": "Your bells ring further: each ring also lands, at half damage, on nightmares up to 4 {steps} further down the path, ringing them too.",
		"tip": "Starts past a pulsing bell's range or a shooting bell's target; stops at the next bell's range. A shot carries to up to 4 nightmares."},
	&"kt_evo_hand_to_hand": {"makes": [], "uses": [&"maze"], "calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_carrying_tune", "name": "Hand to Hand",
		"text": "When a nightmare reaches a new bell, that bell's first hit on it counts as 2 rings instead of 1.",
		"tip": "Rings stay between bells. Once for each Warden and nightmare."},
	&"kt_evo_peal": {"makes": [], "uses": [], "calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_hand_to_hand", "name": "Peal",
		"text": "A {toll} adds 1 ring to every nightmare within 4 {steps}, but never makes their {toll}.",
		"tip": "Its rings never make a {toll}: a hit has to. At most 8 nightmares."},
	&"kt_evo_lingering_note": {"makes": [&"repeat"], "uses": [], "calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_carrying_tune", "name": "Lingering Note",
		"text": "A {toll} leaves a note on the path for 2 s. Every nightmare that walks through it is rung once.",
		"tip": "One note for each bell; its next {toll} moves it."},
	&"kt_evo_night_choir": {"makes": [&"repeat"], "uses": [], "calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_lingering_note", "name": "Night Choir",
		"text": "A note {touching} a Warden also repeats that Warden's last hit, at half damage, on each nightmare walking through it.",
		"tip": "At most 3 Wardens for each note, the strongest first. Never more than 1 s of that Warden's damage."},
	&"kt_evo_steady_beat": {"makes": [], "uses": [&"cluster"], "calling": "bellflower", "tier": STYLE, "parent": &"", "name": "Steady Beat", "style": "Focus",
		"text": "Nightmares in range of 2 or more bells start with 3 rings instead of 2, and their {tolls} hit at full damage instead of half.",
		"tip": "Where bells overlap, the path glows gold."},
	&"kt_evo_crescendo": {"makes": [], "uses": [], "calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_steady_beat", "name": "Crescendo",
		"text": "Each {toll} on a nightmare makes its next {toll} 25% stronger, up to +100%.",
		"tip": "Its ring marks grow bigger and brighter."},
	&"kt_evo_midnight_bell": {"makes": [], "uses": [&"layered"], "calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_crescendo", "name": "Midnight Bell",
		"text": "The 12th ring on a nightmare is a Midnight Toll: every damaging status on it deals its damage at once, and the statuses stay.",
		"tip": "{spored} ticks once, {static} bolts, {damp} calls up to 2 {warden:dewdrop}s {near} it for a {free_hit}. Starting rings don't count. Once per nightmare. Bosses take half."},
	&"kt_evo_hush_a_bye": {"makes": [&"drowsy", &"asleep"], "uses": [], "calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_steady_beat", "name": "Hush-a-bye",
		"text": "Each {toll} adds 2 {stacks} of {drowsy}. A nightmare that takes 3 {tolls} within 6 s falls {asleep} for 1 s.",
		"tip": "Never bosses or a nightmare already {asleep}. Each nightmare once every 8 s."},
	&"kt_evo_sleeping_hall": {"makes": [], "uses": [&"asleep"], "calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_hush_a_bye", "name": "Sleeping Hall",
		"text": "When a nightmare put {asleep} by Hush-a-bye wakes, its next {toll} within 3 s also hits up to 4 nightmares {touching} it, at half damage.",
		"tip": "Only that one {toll} spreads."},
	&"kt_evo_accompaniment": {"makes": [&"repeat"], "uses": [&"cluster"], "calling": "bellflower", "tier": STYLE, "parent": &"", "name": "Accompaniment", "style": "Support",
		"text": "Wardens {touching} a bell join the song: their hits add rings too, and their {tolls} repeat that Warden's hit and status.",
		"tip": "Other Wardens add a ring once a second; a Sprout adds one with every hit. Their rings glow pink."},
	&"kt_evo_counterpoint": {"makes": [&"repeat"], "uses": [], "calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_accompaniment", "name": "Counterpoint",
		"text": "When a Warden that is not a bell makes a {toll}, the nearest bell within 4 cells rings that nightmare too.",
		"tip": "The bell's hit is a {free_hit} and adds a ring. Each bell once a second."},
	&"kt_evo_symphony": {"makes": [&"repeat"], "uses": [&"cluster"], "calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_counterpoint", "name": "Symphony",
		"text": "When 4 different Wardens have added rings to a nightmare, its {toll} repeats each one's last hit, at half damage.",
		"tip": "Counts from a nightmare's second {toll}: its 2 starting rings belong to no Warden. Each nightmare once every 6 s."},
	&"kt_evo_chime_of_many": {"makes": [&"repeat"], "uses": [], "calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_accompaniment", "name": "Chime of Many",
		"text": "A {toll} also repeats the nightmare's last status hit on up to 4 nightmares {touching} it.",
		"tip": "The same Warden's status and {stacks} again: caps and immunities apply. Each nightmare once per {toll}. Never {drowsy} or {held}."},
	&"kt_evo_last_chord": {"makes": [&"reaction"], "uses": [&"layered"], "calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_chime_of_many", "name": "Last Chord",
		"text": "A {toll} on a nightmare with 3 or more statuses sets off any {reaction} that nightmare is halfway to.",
		"tip": "Each nightmare once every 8 s, counted only when a {reaction} goes off."},
	# --- Puddles (Dewdrop) -----------------------------------------------------------------------------------------------
	&"dw_stream": {"makes": [], "uses": [&"maze"], "calling": "dewdrop", "tier": STYLE, "parent": &"", "name": "Stream", "style": "Spread",
		"text": "{Water} runs 4 {steps} further down the path. A splash reaching 3 or more nightmares makes the {warden:dewdrop}'s next hit deal 30% more.",
		"tip": "It flows toward the Heartwood and joins the next {water} it reaches. The splash flashes brighter when it counts."},
	&"dw_millrace": {"makes": [&"layered"], "uses": [], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_stream", "name": "Millrace",
		"text": "A splash also spreads 1 {stack} of up to 3 other statuses from the nightmare it hit to every nightmare it reaches.",
		"tip": "A thread shows each carry. Never {drowsy} or {held}; {static} stops 1 short of a bolt."},
	&"dw_flood": {"makes": [], "uses": [&"maze"], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_millrace", "name": "Flood",
		"text": "A {warden:dewdrop}'s splash runs the whole length of its {water}, up to 24 {steps} each way instead of 4.",
		"tip": "A long splash flashes along the {water}."},
	&"dw_lapping_water": {"makes": [], "uses": [&"soaked"], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_stream", "name": "Lapping Water",
		"text": "When a Warden {touching} {water} hits a nightmare with {damp} in it, a splash gives {damp} to nightmares within 2 {steps} of it in that {water} too.",
		"tip": "{warden:dewdrop}s don't count. Sprouts count. Each Warden once a second."},
	&"dw_spring_flood": {"makes": [&"soaked"], "uses": [], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_lapping_water", "name": "Spring Flood",
		"text": "Every 10 s, up to 8 nightmares in the longest {water} with a nightmare in it reach {full} {damp} and walk 25% slower for 2 s.",
		"tip": "The clock only runs during a {drift}. Bosses are slowed half as much."},
	&"dw_black_pond": {"makes": [], "uses": [&"cluster"], "calling": "dewdrop", "tier": STYLE, "parent": &"", "name": "Black Pond", "style": "Focus",
		"text": "{Water} {touching} 2 or more {warden:dewdrop}s is a pond. Nightmares in it walk 25% slower and take 25% more from {warden:dewdrop}s.",
		"tip": "Ponds are drawn darker. Bosses are slowed half as much. Hits only."},
	&"dw_whirlpool": {"makes": [&"slow"], "uses": [&"soaked"], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_black_pond", "name": "Whirlpool",
		"text": "A nightmare in a pond that reaches {full} {damp} is pulled back 2 {steps}. Once for each pond and nightmare.",
		"tip": "Never bosses or flyers."},
	&"dw_drowning_deep": {"makes": [&"slow"], "uses": [], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_whirlpool", "name": "Drowning Deep",
		"text": "A Whirlpool pull drags nightmares within 1 cell back with it, and every Warden {touching} the pond gets a {free_hit} on the pulled nightmare.",
		"tip": "Drags at most 4 nightmares, never bosses or flyers. Free hits: each Warden once a second."},
	&"dw_stagnant_water": {"makes": [&"linger"], "uses": [], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_black_pond", "name": "Stagnant Water",
		"text": "Statuses on nightmares in a pond don't run down while they stay in it.",
		"tip": "Skips {drowsy} and {held}. Bosses' statuses run down at half speed. Up to 4 s past landing ({static} 2 s), on top of cards that do the same."},  # F2 (tip kept within 30 words)
	&"dw_drowned_hands": {"makes": [&"rooted"], "uses": [&"layered"], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_stagnant_water", "name": "Drowned Hands",
		"text": "A nightmare in a pond with 4 or more statuses gains 1 {held}: it can't move for 1 s (bosses 0.5 s).",
		"tip": "The pond's strongest {warden:dewdrop} adds the {held}. Once for each pond and nightmare."},
	&"dw_riverside": {"makes": [&"linger"], "uses": [&"soaked"], "calling": "dewdrop", "tier": STYLE, "parent": &"", "name": "Riverside", "style": "Support",
		"text": "Statuses that Wardens {touching} {water} add there last 2 s longer. Sprouts {touching} {water} deal 25% more to nightmares with {damp} in it.",
		"tip": "{warden:dewdrop}s count for time, only Sprouts for damage. Skips {drowsy} and {held}. Up to 4 s past landing ({static} 2 s), on top of cards that do the same."},  # F2
	&"dw_rain_on_the_bank": {"makes": [&"layered"], "uses": [], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_riverside", "name": "Rain on the Bank",
		"text": "A splash also gives each nightmare it reaches 1 {stack} of the status of each other Warden {touching} that {water}.",
		"tip": "At most 3 Wardens, the strongest first. {drowsy} stops 1 short of {full}. Never {held}."},  # F5
	&"dw_downpour": {"makes": [&"repeat"], "uses": [], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_rain_on_the_bank", "name": "Downpour",
		"text": "When a splash reaches 4 or more nightmares, every other Warden {touching} that {water} attacks one of them at once.",
		"tip": "Each Warden once every 4 s."},
	&"dw_wet_footprints": {"makes": [&"maze"], "uses": [&"soaked"], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_riverside", "name": "Wet Footprints",
		"text": "A nightmare with {damp} leaving {water} leaves wet {steps} behind it for 3 s. Wet {steps} count as {water}.",
		"tip": "At most 6 {steps} for each nightmare. Wet {steps} never leave more."},
	&"dw_reflection": {"makes": [], "uses": [&"soaked"], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_wet_footprints", "name": "Reflection",
		"text": "When a Warden {touching} {water} hits a nightmare with {damp} there, half the hit also lands on the nightmare furthest back in that {water}.",
		"tip": "{warden:dewdrop}s don't count. Half of the hit before defences. Each Warden once a second."},
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
	out.tip = String(row.tip)
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
