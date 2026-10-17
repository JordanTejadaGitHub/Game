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

# id -> {makes, uses, calling, tier, parent, name, text, tip}. Tips name where a style leads (players hate blind trees).
# makes / uses: keyword chips (keyword chips 2026-10-16; scripts/run/dream_keywords.gd), at most 2 in all.
const PATHS := {
	# --- Spore Print (Sporeling) ---------------------------------------------------------------------------------------
	&"sp_windblown": {"makes": [&"poisoned"], "uses": [&"maze"], "calling": "sporeling", "tier": STYLE, "parent": &"", "name": "Windblown", "style": "Spread",
		"text": "Your {mushrooms} spread down the path: each time a {mushroom} gives a {dose}, a new {mushroom} grows 3 {steps} further on.",
		"tip": "Planted {mushrooms} don't plant again, and are the first to go when there are too many. Leads to: Spore Season, Witch Ring."},
	&"sp_drifting": {"makes": [&"stacks"], "uses": [], "calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_windblown", "name": "Drifting Spores",
		"text": "A {dose} also adds 2 {stacks} to each other status the nightmare already has.",
		"tip": "A status it fills flashes. Never starts a status. Never {held}. Leads to: Spore Season."},
	&"sp_season": {"makes": [&"stacks"], "uses": [], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_drifting", "name": "Spore Season",
		"text": "While 15 or more {mushrooms} are growing, every {dose} is 50% bigger.",
		"tip": "{Mushrooms} planted by Windblown don't count. The {mushrooms} glow while it is on."},
	&"sp_fairy_path": {"makes": [], "uses": [&"cluster"], "calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_windblown", "name": "Fairy Path",
		"text": "{Mushrooms} {touching} 2 or more attacking Wardens grow back 8 s after they are used.",
		"tip": "The clock only runs during a {drift}. These {mushrooms} are all back when a {rest} starts. Leads to: Witch Ring."},
	&"sp_witch_ring": {"makes": [&"rooted"], "uses": [], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_fairy_path", "name": "Witch Ring",
		"text": "A nightmare that steps on 3 {mushrooms} within 4 s is {held} for 1 s (bosses 0.5 s).",
		"tip": "Each nightmare once every 10 s."},
	&"sp_clump": {"makes": [&"stacks"], "uses": [], "calling": "sporeling", "tier": STYLE, "parent": &"", "name": "Clump", "style": "Focus",
		"text": "Your {mushrooms} grow in clumps: a new {mushroom} joins one within 3 {steps}, up to 4 together. Stepping on a clump gives a {dose} for each {mushroom} in it, then the clump loses one.",
		"tip": "Clump: {mushrooms} grown together on one {step}. Clumps form where your {spored} nightmares fall. Leads to: Mire-Mouth, Rotburst."},
	&"sp_sticky": {"makes": [&"slow"], "uses": [], "calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_clump", "name": "Sticky Caps",
		"text": "A nightmare that steps on a clump walks at half speed: 1 s for each {mushroom} in the clump, up to 3 s.",
		"tip": "Bosses half as long. Each clump once per nightmare. Leads to: Mire-Mouth."},
	&"sp_mire_mouth": {"makes": [&"slow"], "uses": [], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_sticky", "name": "Mire-Mouth",
		"text": "When Sticky Caps slows a nightmare, the 2 nearest nightmares behind it (within 2 cells) are slowed too, for half as long.",
		"tip": "Behind: no further along the path. Never bosses or flyers."},
	&"sp_rot": {"makes": [&"stacks"], "uses": [&"layered"], "calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_clump", "name": "Rot",
		"text": "A clump's {dose} also adds 2 {stacks} for each {mushroom} in it to each other status the nightmare already has.",
		"tip": "A status it fills flashes. Never starts a status. Never {held}. Leads to: Rotburst."},
	&"sp_rotburst": {"makes": [&"layered"], "uses": [], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_rot", "name": "Rotburst",
		"text": "When a clump's last {mushroom} is used, it bursts: up to 6 nightmares within 1.5 cells take a {dose} and 2 {stacks} of each status the stepper had.",
		"tip": "Only a clump that once held 2 or more {mushrooms} bursts. Never {drowsy} or {held}."},
	&"sp_borrowed": {"makes": [&"layered"], "uses": [&"cluster"], "calling": "sporeling", "tier": STYLE, "parent": &"", "name": "Borrowed Spores", "style": "Support",
		"text": "Your other Wardens feed the {mushrooms}: a {mushroom} {touching} a Warden also gives 2 {stacks} of that Warden's status, and 2 more {spored} if a Sprout touches it.",
		"tip": "Leads to: Outbreak, Mother Spore. Grows stronger with a second family."},
	&"sp_catching": {"makes": [&"poisoned"], "uses": [], "calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_borrowed", "name": "Catching",
		"text": "A nightmare that takes a {dose} passes half of it to the first nightmare it bumps into within 2 s.",
		"tip": "Once per {dose}. Leads to: Outbreak. Grows stronger with a second family."},
	&"sp_outbreak": {"makes": [&"poisoned"], "uses": [], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_catching", "name": "Outbreak",
		"text": "A passed-on {dose} can pass on again, up to 3 times, halving each time.",
		"tip": "It stops at 1 {stack}. Grows stronger with a second family."},
	&"sp_feeding": {"makes": [&"stacks"], "uses": [], "calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_borrowed", "name": "Feeding Ground",
		"text": "For 4 s after a nightmare takes a {dose}, Wardens {touching} that {step} add 1 extra {stack} with each status hit on it.",
		"tip": "Each Warden once per nightmare. Leads to: Mother Spore. Grows stronger with a second family."},
	&"sp_mother": {"makes": [&"layered"], "uses": [], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_feeding", "name": "Mother Spore",
		"text": "A {mushroom} left by a {dispel} keeps up to 4 of that nightmare's statuses. The next nightmare to step on it gets 2 {stacks} of each.",
		"tip": "Its cap is speckled. Never {drowsy} or {held}. Grows stronger with a second family."},
	# --- Lantern Light (Firefly Jar) -----------------------------------------------------------------------------------
	&"lf_strung_lights": {"makes": [], "uses": [&"maze"], "calling": "firefly_jar", "tier": STYLE, "parent": &"", "name": "Strung Lights", "style": "Spread",
		"text": "Your glows join up: the path between two glows up to 4 {steps} apart glows too, so more nightmares are {lit}.",
		"tip": "Nightmares there are {lit}. This light never reveals {kind_hidden} nightmares. Leads to: Bale-fires, Swarm Night."},
	&"lf_torchbearers": {"makes": [&"jump"], "uses": [], "calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_strung_lights", "name": "Torchbearers",
		"text": "When a {lit} nightmare is dispelled, half the killing hit {jumps} to the nearest {lit} nightmare ahead of it on the path.",  # Hard cards 2026-10-16
		"tip": "Further along: at most 8 {steps} ahead. Bosses take half. Leads to: Bale-fires."},
	&"lf_bale_fires": {"makes": [&"repeat"], "uses": [&"jump"], "calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_torchbearers", "name": "Bale-fires",
		"text": "If a Torchbearers {jump} dispels its target, it {jumps} again to the next {lit} nightmare ahead, up to 4 more times.",  # Hard cards 2026-10-16
		"tip": "Bosses take half."},
	&"lf_glowworms": {"makes": [], "uses": [&"cluster"], "calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_strung_lights", "name": "Glowworms",
		"text": "Up to 2 Sprouts {touching} each Firefly Warden glow too, so the path next to them is {lit}.",
		"tip": "The Sprouts nearest the Heartwood glow first. Sprout light never reveals {kind_hidden} nightmares. Leads to: Swarm Night."},
	&"lf_swarm_night": {"makes": [], "uses": [&"jump"], "calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_glowworms", "name": "Swarm Night",
		"text": "While 6 or more nightmares are {lit}, every {jump} {jumps} one extra time.",
		"tip": "The extra {jump} is as strong as the first and goes to the nearest {lit} nightmare it hasn't hit. Bosses take half."},
	&"lf_bonfire": {"makes": [&"jump"], "uses": [], "calling": "firefly_jar", "tier": STYLE, "parent": &"", "name": "Bonfire", "style": "Focus",
		"text": "Overlap your Firefly Wardens: path inside 2 of their glows turns gold. A {dispel} on gold path {jumps} to 2 {lit} nightmares instead of 1.",
		"tip": "Leads to: Pyre, Witchfire."},
	&"lf_moth_to_flame": {"makes": [&"exposed"], "uses": [&"jump"], "calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_bonfire", "name": "Moth to Flame",
		"text": "A {jump} that lands on a nightmare on gold path adds 2 {stacks} of {marked}.",
		"tip": "{marked} only works from {stacks:need_marked} {stacks}: watch it build. Bosses get 1. Leads to: Pyre."},
	&"lf_pyre": {"makes": [], "uses": [&"jump"], "calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_moth_to_flame", "name": "Pyre",
		"text": "If a {jump} dispels a nightmare on gold path, it {jumps} again at full strength, up to 3 times.",
		"tip": "A boss's summons count too. Bosses take half."},
	&"lf_embers": {"makes": [&"repeat"], "uses": [], "calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_bonfire", "name": "Embers",
		"text": "A nightmare dispelled on gold path leaves an ember for 4 s. The next nightmare to walk over it takes half the killing hit.",
		"tip": "At most 8 embers at once. They go out when a {rest} starts. Bosses take half. Leads to: Witchfire."},
	&"lf_witchfire": {"makes": [], "uses": [], "calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_embers", "name": "Witchfire",
		"text": "Embers within 2 {steps} of each other gather into a pile, up to 3. When a nightmare reaches the pile, it hits every nightmare within 1 cell.",
		"tip": "A pile hits with all its embers at once. At most 6 nightmares. Bosses take half."},
	&"lf_borrowed_light": {"makes": [&"jump"], "uses": [], "calling": "firefly_jar", "tier": STYLE, "parent": &"", "name": "Borrowed Light", "style": "Support",
		"text": "Your other families join in: when a Warden that is not a Firefly Warden hits a {lit} nightmare, a third of the hit {jumps} to the nearest other {lit} nightmare.",
		"tip": "Sprouts count. Each Warden once a second. Leads to: Lantern Wake, Constellation. Grows stronger with a second family."},
	&"lf_show_the_way": {"makes": [&"stacks"], "uses": [], "calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_borrowed_light", "name": "Show the Way",
		"text": "Wardens standing in a Firefly Warden's glow add 1 extra {stack} with each status hit on a {lit} nightmare.",
		"tip": "Never starts a status. Never {drowsy}. Each Warden once a second. Leads to: Lantern Wake. Grows stronger with a second family."},
	&"lf_lantern_wake": {"makes": [&"layered"], "uses": [&"jump"], "calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_show_the_way", "name": "Lantern Wake",
		"text": "A {jump} carries statuses with it: the nightmare it lands on gets 1 {stack} of each status the first one had.",
		"tip": "At most 4 statuses. Never starts a status. Never {held}. Grows stronger with a second family."},
	&"lf_sightline": {"makes": [&"jump"], "uses": [], "calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_borrowed_light", "name": "Sightline",
		"text": "When 3 different Wardens hit the same {lit} nightmare within 2 s, a quarter of each hit {jumps} to the nearest other {lit} nightmare.",
		"tip": "Sprouts count. At most 4 Wardens. Each nightmare once every 4 s. Leads to: Constellation. Grows stronger with a second family."},
	&"lf_constellation": {"makes": [&"exposed"], "uses": [&"jump"], "calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_sightline", "name": "Constellation",
		"text": "When {jumps} from 3 different Wardens hit one nightmare within 3 s, it becomes {full} {marked}.",
		"tip": "Bosses get half the {stacks}. Each nightmare once every 8 s. Grows stronger with a second family."},
	# --- Keeping Time (Bellflower) -------------------------------------------------------------------------------------
	&"kt_evo_carrying_tune": {"makes": [], "uses": [&"maze"], "calling": "bellflower", "tier": STYLE, "parent": &"", "name": "Carrying Tune", "style": "Spread",
		"text": "Your bells ring further: each ring also lands, at half damage, on nightmares up to 4 {steps} further down the path, and fills their pips too.",
		"tip": "Starts past a pulsing bell's range or a shooting bell's target; stops at the next bell's range. A shot carries to up to 4 nightmares. Leads to: Peal, Night Choir."},
	&"kt_evo_hand_to_hand": {"makes": [], "uses": [&"maze"], "calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_carrying_tune", "name": "Hand to Hand",
		"text": "When a nightmare reaches a new bell, that bell's first ring on it fills 2 pips instead of 1.",
		"tip": "Pips stay lit between bells. Once for each Warden and nightmare. Leads to: Peal."},
	&"kt_evo_peal": {"makes": [], "uses": [], "calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_hand_to_hand", "name": "Peal",
		"text": "A {toll} fills 1 pip on every nightmare within 4 {steps}, but never their last pip.",
		"tip": "Only a bell's ring can make the {toll}. At most 8 nightmares."},
	&"kt_evo_lingering_note": {"makes": [&"repeat"], "uses": [], "calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_carrying_tune", "name": "Lingering Note",
		"text": "A {toll} leaves a note on the path for 2 s. Every nightmare that walks through it is rung once.",
		"tip": "One note for each bell; its next {toll} moves it. Leads to: Night Choir."},
	&"kt_evo_night_choir": {"makes": [&"repeat"], "uses": [], "calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_lingering_note", "name": "Night Choir",
		"text": "A note {touching} a Warden also repeats that Warden's last hit, at half damage, on each nightmare walking through it.",
		"tip": "At most 3 Wardens for each note, the strongest first. Never more than 1 s of that Warden's damage."},
	&"kt_evo_steady_beat": {"makes": [], "uses": [&"cluster"], "calling": "bellflower", "tier": STYLE, "parent": &"", "name": "Steady Beat", "style": "Focus",
		"text": "Overlap your bells: nightmares in range of 2 or more bells start with 3 pips filled instead of 2, and their {tolls} hit at full damage instead of half.",
		"tip": "Where bells overlap, the path shows a double ring. Leads to: Midnight Bell, Sleeping Hall."},
	&"kt_evo_crescendo": {"makes": [], "uses": [], "calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_steady_beat", "name": "Crescendo",
		"text": "Each {toll} on a nightmare makes its next {toll} 25% stronger, up to +100%.",
		"tip": "Its pips grow bigger and brighter. Leads to: Midnight Bell."},
	&"kt_evo_midnight_bell": {"makes": [], "uses": [&"layered"], "calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_crescendo", "name": "Midnight Bell",
		"text": "The 12th ring on a nightmare is a Midnight Toll: every damaging status on it deals its damage at once, and the statuses stay.",
		"tip": "{spored} ticks once, {static} bolts, {damp} calls up to 2 {warden:dewdrop}s {near} it for a {free_hit}. A dial counts the rings. Once per nightmare. Bosses take half."},
	&"kt_evo_hush_a_bye": {"makes": [&"drowsy", &"asleep"], "uses": [], "calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_steady_beat", "name": "Hush-a-bye",
		"text": "Each {toll} adds 2 {stacks} of {drowsy}. A nightmare that takes 3 {tolls} within 6 s falls {asleep} for 1 s.",
		"tip": "Never bosses or a nightmare already {asleep}. Each nightmare once every 8 s. Leads to: Sleeping Hall."},
	&"kt_evo_sleeping_hall": {"makes": [], "uses": [&"asleep"], "calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_hush_a_bye", "name": "Sleeping Hall",
		"text": "When a Hush-a-bye sleep ends, the nightmare's next {toll} within 3 s also hits up to 4 nightmares touching it, at half damage.",
		"tip": "Only that one {toll} spreads."},
	&"kt_evo_accompaniment": {"makes": [&"repeat"], "uses": [&"cluster"], "calling": "bellflower", "tier": STYLE, "parent": &"", "name": "Accompaniment", "style": "Support",
		"text": "Wardens {touching} a bell join the song: their hits fill pips too, and their {tolls} repeat that Warden's hit and status.",
		"tip": "Other Wardens fill a pip once a second; a Sprout fills one with every hit. Their pips glow pink. Leads to: Symphony, Last Chord. Grows stronger with a second family."},
	&"kt_evo_counterpoint": {"makes": [&"repeat"], "uses": [], "calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_accompaniment", "name": "Counterpoint",
		"text": "When a Warden that is not a bell makes a {toll}, the nearest bell within 4 cells rings that nightmare too.",
		"tip": "The ring is a {free_hit} and fills a pip. Each bell once a second. Leads to: Symphony. Grows stronger with a second family."},
	&"kt_evo_symphony": {"makes": [&"repeat"], "uses": [&"cluster"], "calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_counterpoint", "name": "Symphony",
		"text": "When 4 different Wardens filled a nightmare's pips, its {toll} repeats each one's last hit, at half damage.",
		"tip": "Counts from a nightmare's second {toll}: its 2 starting pips belong to no Warden. Each nightmare once every 6 s. Grows stronger with a second family."},
	&"kt_evo_chime_of_many": {"makes": [&"stacks"], "uses": [], "calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_accompaniment", "name": "Chime of Many",
		"text": "A {toll} adds 1 {stack} to each status on the nightmare, and on up to 4 nightmares touching it.",
		"tip": "Each status it adds to flashes. Never starts a status. Never {drowsy} or {held}. Leads to: Last Chord. Grows stronger with a second family."},
	&"kt_evo_last_chord": {"makes": [&"reaction"], "uses": [&"layered"], "calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_chime_of_many", "name": "Last Chord",
		"text": "A {toll} on a nightmare with 3 or more statuses sets off any {reaction} that nightmare is halfway to.",
		"tip": "Each nightmare once every 8 s, counted only when a {reaction} goes off. Grows stronger with a second family."},
	# --- Puddles (Dewdrop) -----------------------------------------------------------------------------------------------
	&"dw_stream": {"makes": [], "uses": [&"maze"], "calling": "dewdrop", "tier": STYLE, "parent": &"", "name": "Stream", "style": "Spread",
		"text": "Your {water} reaches further: the 4 {steps} of path after each {water} are {water} too.",
		"tip": "It flows toward the Heartwood and joins the next {water} it reaches. Leads to: Flood, Spring Flood."},
	&"dw_millrace": {"makes": [&"layered"], "uses": [], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_stream", "name": "Millrace",
		"text": "A {warden:dewdrop}'s splash also spreads 1 {stack} of up to 3 other statuses from the nightmare it hit to every nightmare it reaches.",
		"tip": "A thread shows each carry. Never {drowsy} or {held}; {static} stops 1 short of a bolt. Leads to: Flood."},
	&"dw_flood": {"makes": [], "uses": [&"maze"], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_millrace", "name": "Flood",
		"text": "A {warden:dewdrop}'s splash runs the whole length of its {water}, up to 24 {steps} each way instead of 4.",
		"tip": "A long splash flashes along the {water}."},
	&"dw_lapping_water": {"makes": [], "uses": [&"soaked"], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_stream", "name": "Lapping Water",
		"text": "When a Warden {touching} {water} hits a {damp} nightmare in it, nightmares within 2 {steps} of it in that {water} become {damp} too.",
		"tip": "{warden:dewdrop}s don't count. Sprouts count. Each Warden once a second. Leads to: Spring Flood."},
	&"dw_spring_flood": {"makes": [&"soaked"], "uses": [], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_lapping_water", "name": "Spring Flood",
		"text": "Every 10 s, up to 8 nightmares in your longest {water} become {full} {damp} and walk 25% slower for 2 s.",
		"tip": "The clock only runs during a {drift}. Bosses are slowed half as much."},
	&"dw_black_pond": {"makes": [], "uses": [&"cluster"], "calling": "dewdrop", "tier": STYLE, "parent": &"", "name": "Black Pond", "style": "Focus",
		"text": "Group your {warden:dewdrop}s: {water} {touching} 2 or more of them is a pond. Nightmares in a pond walk 25% slower, and a {warden:dewdrop}'s splash there reaches 8 {steps} instead of 4.",
		"tip": "Ponds are drawn darker. Bosses are slowed half as much. Leads to: Drowning Deep, Drowned Hands."},
	&"dw_whirlpool": {"makes": [&"slow"], "uses": [&"soaked"], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_black_pond", "name": "Whirlpool",
		"text": "A nightmare in a pond that becomes {full} {damp} is pulled back 2 {steps}. Once for each pond and nightmare.",
		"tip": "Never bosses or flyers. Leads to: Drowning Deep."},
	&"dw_drowning_deep": {"makes": [&"slow"], "uses": [], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_whirlpool", "name": "Drowning Deep",
		"text": "A Whirlpool pull drags up to 4 nightmares within 1 cell back with it, and every Warden {touching} the pond gets a {free_hit} on the pulled nightmare.",
		"tip": "Never drags bosses or flyers. Free hits: each Warden once a second."},
	&"dw_stagnant_water": {"makes": [&"stacks"], "uses": [], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_black_pond", "name": "Stagnant Water",
		"text": "Statuses added to nightmares in a pond get 1 extra {stack}.",
		"tip": "A splash shows each extra {stack}. Never {drowsy} or {held}. Each Warden once a second. Leads to: Drowned Hands."},
	&"dw_drowned_hands": {"makes": [&"rooted"], "uses": [&"layered"], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_stagnant_water", "name": "Drowned Hands",
		"text": "A nightmare in a pond with 4 or more statuses is {held} for 1 s (bosses 0.5 s). Once for each pond and nightmare.",
		"tip": "The pond's strongest {warden:dewdrop} makes it {held}."},
	&"dw_riverside": {"makes": [&"stacks"], "uses": [], "calling": "dewdrop", "tier": STYLE, "parent": &"", "name": "Riverside", "style": "Support",
		"text": "Your other Wardens use the {water}: a Warden {touching} {water} adds 1 extra {stack} with its first status hit on each nightmare in that {water}.",
		"tip": "{warden:dewdrop}s count. Sprouts don't count. A splash shows each extra {stack}. Leads to: Downpour, Reflection. Grows stronger with a second family."},
	&"dw_rain_on_the_bank": {"makes": [&"layered"], "uses": [], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_riverside", "name": "Rain on the Bank",
		"text": "A {warden:dewdrop}'s splash also gives each nightmare it reaches 1 {stack} of the status of each other Warden {touching} that {water}.",
		"tip": "At most 3 Wardens, the strongest first. Never {drowsy} or {held}. Leads to: Downpour. Grows stronger with a second family."},
	&"dw_downpour": {"makes": [&"repeat"], "uses": [], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_rain_on_the_bank", "name": "Downpour",
		"text": "When a {warden:dewdrop}'s splash reaches 4 or more nightmares, every other Warden {touching} that {water} attacks one of them at once.",
		"tip": "Each Warden once every 4 s. Grows stronger with a second family."},
	&"dw_wet_footprints": {"makes": [&"maze"], "uses": [&"soaked"], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_riverside", "name": "Wet Footprints",
		"text": "A {damp} nightmare leaving {water} leaves wet {steps} behind it for 3 s. Wet {steps} count as {water}.",
		"tip": "At most 6 {steps} for each nightmare. Wet {steps} never leave more. Leads to: Reflection. Grows stronger with a second family."},
	&"dw_reflection": {"makes": [], "uses": [&"soaked"], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_wet_footprints", "name": "Reflection",
		"text": "When a Warden {touching} {water} hits a {damp} nightmare there, half the hit also lands on the nightmare furthest back in that {water}.",
		"tip": "{warden:dewdrop}s don't count. Half of the hit before defences. Each Warden once a second. Grows stronger with a second family."},
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
	# No style or "Leads to" on the card or its tip (owner 2026-10-17: no direction, the player finds the path).
	var tip := RegEx.create_from_string(" ?Leads to: [^.]*\\.").sub(String(row.tip), "", true)
	out.tip = tip.strip_edges()
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
