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
const DEEPEN := 3  # Drift 75: a second capstone for the line (parent: a CAPSTONE). The other choice there is a Cross over
# (the style's other FOLLOW_UP). Rows may also carry "retired": true (never offered) and "keeps_out": [card ids].

# id -> {makes, uses, calling, tier, parent, name, text, tip}. No style, "Leads to" or other direction on a card or its tip
# (owner 2026-10-17: no hand-holding; the player finds the path).
# makes / uses: keyword chips (keyword chips 2026-10-16; scripts/run/dream_keywords.gd), at most 2 in all.
const PATHS := {
	# --- Spore Print (Sporeling) ---------------------------------------------------------------------------------------
	# Rebuilt 2026-10-23 (owner, dream_council_review.md 33; D:\Projects\logs\dream_council\evo_fixed_sporeling.md):
	# Spread = the trail wears them down (Poisoned grows with the steps walked), Focus = extra free hits (class_kit.calling_hit,
	# damage only), Support = other families' statuses stack faster, plus Host Grove's Potency. Never Held, slow, area, crit,
	# pierce, knock-on or status spreading. Every Deepen adds a new trigger or place, never a bigger number.
	&"sp_windblown": {"makes": [&"poisoned"], "uses": [&"maze"], "calling": "sporeling", "tier": STYLE, "parent": &"", "name": "Windblown", "style": "Spread",
		"text": "Each {dose} is 1 {stack} bigger than the last {dose} that nightmare took, up to 6, and grows a new {mushroom} 3 {steps} further down the path.",
		"tip": "{Mushrooms} grown this way don't grow more, and are the first to go when the {mushroom} limit is reached. A {dose} never takes {spored} past its most {stacks}."},
	&"sp_drifting": {"makes": [&"poisoned"], "uses": [&"maze"], "calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_windblown", "name": "Drifting Spores",
		"text": "A {mushroom} grown by a {dose} grows one more, 3 {steps} further down the path. The {mushroom} limit becomes 1 per 2 {steps} of path, from 40 up to 80.",
		"tip": "Those {mushrooms} go first when the limit is reached."},
	&"sp_season": {"makes": [&"poisoned"], "uses": [&"maze"], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_drifting", "name": "Spore Season",
		"text": "While 15 or more {mushrooms} grow, a nightmare's {spored} deals 1% more damage for each {step} it has walked since its first {dose}, up to +60%.",
		"tip": "Bosses up to +30%. Never flyers. A nightmare that starts its route again starts counting again."},
	&"sp_thick_haze": {"makes": [&"poisoned"], "uses": [&"maze"], "calling": "sporeling", "tier": DEEPEN, "parent": &"sp_season", "name": "Thick Haze", "retired": true,  # Owner 2026-10-23: back to the designer; code kept
		"text": "A nightmare at Spore Season's limit takes 1 s of its {spored} damage at once for every 10 {steps} it walks after that.",
		"tip": "Bosses at their +30% limit, and take half. Its {spored} keeps ticking. Damage only: no {stacks}."},
	&"sp_fairy_path": {"makes": [], "uses": [&"cluster"], "calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_windblown", "name": "Fairy Path",
		"text": "Each Sprout grows a {mushroom} on the nearest {step} {touching} it, and grows it again 10 s after it is eaten.",
		"tip": "Only while that Warden stays a Sprout. The {dose} comes from your nearest {family:sporeling} Warden; with none left, the {mushroom} withers. The 10 s only count during a {drift}; these {mushrooms} are all back when a {rest} starts."},
	&"sp_deathcap": {"makes": [&"poisoned"], "uses": [], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_fairy_path", "name": "Deathcap",
		"text": "A nightmare with {spored} stepping on a {mushroom} takes 2 s of its {spored} damage at once, before the {dose}.",
		"tip": "Its {spored} keeps ticking. Each nightmare once a second. Bosses take half. Damage only: no {stacks}."},
	&"sp_witch_ground": {"makes": [&"poisoned"], "uses": [&"cluster"], "calling": "sporeling", "tier": DEEPEN, "parent": &"sp_deathcap", "name": "Rot Ground",
		"text": "A Fairy Path {step} whose {mushroom} is regrowing still bursts: a nightmare with {spored} stepping there takes Deathcap's 2 s of its {spored} damage at once. No {dose}.",
		"tip": "Shares Deathcap's once a second for each nightmare. Only while the Warden that grew it stays a Sprout. Bosses take half."},
	&"sp_clump": {"makes": [&"hit"], "uses": [&"cluster"], "calling": "sporeling", "tier": STYLE, "parent": &"", "name": "Clump", "style": "Focus",
		"text": "{Mushrooms} gather in clumps of up to 4. A nightmare stepping on a clump takes a {free_hit} from each attacking Warden {touching} that clump.",
		"tip": "A new {mushroom} joins the nearest clump with room within 3 {steps}. Each nightmare stepping on a clump eats 1 {mushroom}. At most 3 Wardens, the strongest first, each once a second. Bosses take half. Damage only: no status. The {dose} still lands."},
	&"sp_trampled": {"makes": [&"hit"], "uses": [&"rank"], "calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_clump", "name": "Trampled Ground",
		"text": "A {rank} III+ Warden {touching} a clump gives 2 {free_hits} to each nightmare stepping on it. The second deals half.",
		"tip": "Each such Warden gives up to 2 {free_hits} a second."},
	&"sp_pile_on": {"makes": [&"hit"], "uses": [&"rank"], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_trampled", "name": "Pile-On",
		"text": "Each direct hit by a {rank} III+ Warden on a nightmare within 2 {steps} of a clump that Warden is {touching} calls a {free_hit} from each other {rank} III+ Warden {touching} that clump.",
		"tip": "Counts toward Trampled Ground's 2 a second. A {free_hit} never calls another. Bosses take half."},
	&"sp_trodden": {"makes": [&"hit"], "uses": [], "calling": "sporeling", "tier": DEEPEN, "parent": &"sp_pile_on", "name": "Trodden Path",
		"text": "Stepping on the {step} just before or after a clump counts as stepping on the clump. There, each Warden {touching} it also gives 1 more {free_hit}, once a second.",
		"tip": "No {mushroom} is eaten and no {dose} lands there. Each side of a clump counts once for each nightmare."},
	&"sp_throne": {"makes": [&"hit"], "uses": [&"rank"], "calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_clump", "name": "Toadstool Throne",
		"text": "Each final form makes one clump it is {touching} a throne: the throne's last {mushroom} is never eaten.",
		"tip": "The fullest clump, then the nearest. A throne still takes new {mushrooms}, up to 4."},
	&"sp_elder_cap": {"makes": [&"hit"], "uses": [&"rank"], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_throne", "name": "Elder Cap",
		"text": "A throne's final form gives its {free_hit} to a nightmare stepping on that throne once for each of its own attacks, not once a second.",
		"tip": "Bosses take half."},
	&"sp_retinue": {"makes": [&"hit"], "uses": [&"rank"], "calling": "sporeling", "tier": DEEPEN, "parent": &"sp_elder_cap", "name": "Retinue",
		"text": "Up to 2 {rank} V+ Wardens that aren't final forms, {touching} a throne, give a nightmare stepping on it a {free_hit} at half their hit, once for each of their own attacks.",
		"tip": "Bosses take half."},
	&"sp_borrowed": {"makes": [&"stacks"], "uses": [&"cluster"], "calling": "sporeling", "tier": STYLE, "parent": &"", "name": "Shared Caps", "style": "Support",
		"text": "When a nightmare takes a {dose}, the highest-rank Warden of another family {touching} that {mushroom} adds 2 {stacks} to the status it already put on that nightmare.",
		"tip": "Sprouts count; theirs adds to the {spored} the {dose} just put on. {static} and {marked}: 1. Never {held}. {drowsy} never goes past its most {stacks}.",
		"keeps_out": [&"breathe_it_in", &"mycelium", &"overnight"]},  # Its lent twins (section 33 card-pool sweep)
	&"sp_feeding": {"makes": [&"stacks"], "uses": [], "calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_borrowed", "name": "Feeding Ground",
		"text": "Each {dose} turns the next 6 {steps} into fed ground for 8 s. Other families' status hits on nightmares there add 1 more {stack}.",
		"tip": "Any Warden of another family, anywhere. A Sprout's hit adds 1 {spored}. {static} and {marked}: at most 1 extra a second for each Warden. With Host Trees, one hit adds at most 2.",
		"keeps_out": [&"overnight"]},
	&"sp_windfall": {"makes": [&"stacks"], "uses": [], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_feeding", "name": "Windfall",
		"text": "A nightmare dispelled on fed ground leaves a {mushroom} where it fell, even without {spored}.",
		"tip": "It counts toward the {mushroom} limit and goes first when the limit is reached. It looks pale."},
	&"sp_sporefall": {"makes": [&"stacks"], "uses": [], "calling": "sporeling", "tier": DEEPEN, "parent": &"sp_windfall", "name": "Sporefall",
		"text": "When another family's Warden makes a status {full} on a nightmare on fed ground, a {mushroom} grows 3 {steps} ahead of that nightmare.",
		"tip": "Sprouts count. Once for each status on each nightmare. It counts toward the {mushroom} limit and goes first when the limit is reached."},
	&"sp_host_trees": {"makes": [&"stacks"], "uses": [&"cluster"], "calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_borrowed", "name": "Host Trees",
		"text": "A Warden of another family {touching} a {mushroom} wears a cap until 8 s after it stops touching any. Its status hits add 1 more {stack}.",
		"tip": "Sprouts wear caps too; their hits add 1 {spored}. With Feeding Ground, one hit adds at most 2.",
		"keeps_out": [&"pass_it_round"]},
	# Host Grove "makes potency" in the design: no Potency keyword chip exists (dream_keywords.gd), so it shows none.
	&"sp_host_grove": {"makes": [&"potency"], "uses": [&"cluster"], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_host_trees", "name": "Host Grove",
		"text": "While 3 or more Wardens of other families wear caps, their statuses deal 30% more damage.",
		"tip": "Sprouts count. Only {spored} and {static} damage. Never {reaction} damage; doesn't add with Undiluted: the larger counts. Doesn't make statuses last longer."},
	&"sp_spreading_caps": {"makes": [&"stacks"], "uses": [&"cluster"], "calling": "sporeling", "tier": DEEPEN, "parent": &"sp_host_grove", "name": "Spreading Caps",
		"text": "A Warden of another family {touching} a capped Warden wears a cap too. Caps passed this way don't pass on.",
		"tip": "Sprouts count. A passed cap lasts as long as the cap it came from."},
	# Retired 2026-10-23 (never offered; spore_print.gd keeps their code for an old save's path)
	&"sp_witch_ring": {"makes": [&"rooted"], "uses": [], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_fairy_path", "name": "Witch Ring", "retired": true,
		"text": "A nightmare that steps on 3 {mushrooms} within 4 s gains 1 {held}: it can't move for 1 s (bosses 0.5 s).",
		"tip": "Each nightmare once every 10 s."},
	&"sp_sticky": {"makes": [&"slow"], "uses": [], "calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_clump", "name": "Sticky Caps", "retired": true,
		"text": "A nightmare that steps on a clump walks at half speed: 1 s for each {mushroom} in the clump, up to 3 s.",
		"tip": "Bosses half as long. Each clump once per nightmare."},
	&"sp_mire_mouth": {"makes": [&"slow"], "uses": [], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_sticky", "name": "Mire-Mouth", "retired": true,
		"text": "When Sticky Caps slows a nightmare, the 2 nearest nightmares behind it are slowed too, for half as long.",
		"tip": "Behind: no further along the path, within 2 cells. Never bosses or flyers."},
	&"sp_rot": {"makes": [&"stacks"], "uses": [&"layered"], "calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_clump", "name": "Rot", "retired": true,
		"text": "A clump's {dose} also adds 2 {stacks} for each {mushroom} in it to each other status the nightmare already has.",
		"tip": "A status it makes {full} flashes. Never starts a status. Doesn't add {held}."},
	&"sp_rotburst": {"makes": [&"layered"], "uses": [], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_rot", "name": "Rotburst", "retired": true,
		"text": "When a clump's last {mushroom} is used, it bursts: nightmares within 1.5 cells take a {dose} and 2 {stacks} of each status the stepper had.",
		"tip": "Only a clump that once had 2 or more {mushrooms} bursts. At most 6 nightmares. Doesn't add {drowsy} or {held}."},
	# Non-status builds (owner 2026-10-19; council nonstatus_*.md): Stomping Ground / Second Crop replaced Catching / Outbreak
	# (spore_print keeps their code for an old save). Retired 2026-10-23 with the rebuild.
	&"sp_stomping": {"makes": [], "uses": [&"cluster"], "calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_borrowed", "name": "Stomping Ground", "retired": true,
		"text": "A nightmare that steps on a {mushroom} takes a {free_hit} from each attacking Warden {touching} that {step}.",
		"tip": "At most 3 Wardens, the strongest first. Each Warden once a second. Bosses take half. The {dose} still lands."},
	&"sp_second_crop": {"makes": [], "uses": [], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_stomping", "name": "Second Crop", "retired": true,
		"text": "Any nightmare dispelled within 2 {steps} of a {mushroom} leaves a new {mushroom}, even if it had no {spored}.",
		"tip": "It grows where the nightmare fell, and counts toward the 40 {mushrooms}. Its cap is pale."},
	&"sp_mother": {"makes": [&"layered"], "uses": [], "calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_feeding", "name": "Mother Spore", "retired": true,
		"text": "A {mushroom} left by a {dispel} keeps that nightmare's statuses. The next nightmare to step on it gets 2 {stacks} of each.",
		"tip": "Its cap is speckled. At most 4 statuses. Doesn't add {drowsy} or {held}."},
	# --- Lantern Light (Firefly Jar) -----------------------------------------------------------------------------------
	# Rebuilt 2026-10-23 (owner, dream_council_review.md 33; D:\Projects\logs\dream_council\evo_fixed_firefly.md):
	# Spread = damage per glow entered (a % or a flare), Focus = forced crits only, Support = jumps. Never slow, held, pierce,
	# area, status spreading, repeat, tempo, extra free hits or range. A flare: a damage-only Calling hit (class_kit.calling_hit).
	&"lf_strung_lights": {"makes": [], "uses": [&"maze"], "calling": "firefly_jar", "tier": STYLE, "parent": &"", "name": "Strung Lights", "style": "Spread",
		"text": "Direct hits on a nightmare inside a Firefly glow deal 4% more damage for each glow it has entered, up to +20%.",
		"tip": "Overlapping glows count as one. Each glow counts once. Not {jumps}, bolts, Firefly flares or statuses."},
	&"lf_far_lights": {"makes": [], "uses": [&"maze"], "calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_strung_lights", "name": "Far Lights",
		"text": "A nightmare entering a glow 6 or more {steps} after it left its last glow takes a flare: one hit from that glow's Firefly, damage only.",
		"tip": "Its first glow counts from the start of the path. Flyers count every glow as far. Each Firefly flares once a second. Bosses take half."},
	&"lf_lantern_road": {"makes": [], "uses": [&"maze"], "calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_far_lights", "name": "Lantern Road",
		"text": "Once a nightmare has entered 4 different glows, every glow it enters flares it, near or far, at double damage.",
		"tip": "Each Firefly flares once a second, shared with Far Lights, Marsh Lights and Circling Light. Bosses take half."},
	&"lf_parting_light": {"makes": [], "uses": [&"maze"], "calling": "firefly_jar", "tier": DEEPEN, "parent": &"lf_lantern_road", "name": "Parting Light",
		"text": "Once a nightmare has entered 4 different glows, it also takes a flare at half damage each time it leaves a glow.",
		"tip": "Each Firefly once a second, on a clock of its own. Bosses take half."},
	&"lf_marsh_lights": {"makes": [], "uses": [&"maze"], "calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_strung_lights", "name": "Marsh Lights",
		"text": "A nightmare walking back into a glow it left 4 or more {steps} earlier takes a flare: one hit from that glow's Firefly, damage only.",
		"tip": "Only steps forward count: a nightmare pulled back never walks back in. Each glow at most 4 times per nightmare. Each Firefly flares once a second. Not flyers. Bosses take half."},
	&"lf_circling_light": {"makes": [], "uses": [&"maze"], "calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_marsh_lights", "name": "Circling Light",
		"text": "Each time Marsh Lights counts a nightmare walking back into a glow, every other Firefly whose glow that nightmare has entered flares it too.",
		"tip": "Each Firefly once a second. Not flyers. Bosses take half."},
	&"lf_drawn_in": {"makes": [], "uses": [&"cluster"], "calling": "firefly_jar", "tier": DEEPEN, "parent": &"lf_circling_light", "name": "Drawn In",
		"text": "When a Firefly flares a nightmare, each attacking Warden {touching} that Firefly flares the nightmare too, for a quarter of that Warden's hit.",
		"tip": "Sprouts count; walls don't. Each Warden once a second. Drawn In's flares never call more. Bosses take half."},
	&"lf_bonfire": {"makes": [&"crit"], "uses": [&"hit"], "calling": "firefly_jar", "tier": STYLE, "parent": &"", "name": "Bonfire", "style": "Focus",
		"text": "Where 2 Fireflies' glows overlap, the path turns gold. A Firefly's direct hit there makes another Warden's next direct hit on that nightmare crit.",
		"tip": "A crit deals the Warden's crit damage, at least double. One waiting crit per nightmare; a crit from it never readies another. Other Fireflies can take it. Other cards don't count it as a crit."},
	&"lf_moth_to_flame": {"makes": [&"crit"], "uses": [&"rank"], "calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_bonfire", "name": "Moth to Flame",
		"text": "A Firefly's direct hit on gold path readies a crit for your highest-{rank} Warden with gold in range. After 4 direct hits on that nightmare by others, it deals 50% more.",
		"tip": "Bonfire's waiting crit still works. Ties go to the higher form. Walls never count; an area attack counts once. Other cards don't count it as a crit."},
	&"lf_pyre": {"makes": [&"crit"], "uses": [&"rank"], "calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_moth_to_flame", "name": "Pyre",
		"text": "Path inside 3 or more Fireflies' glows burns white. There, every 2nd direct hit (bosses every 3rd) from a {rank} V+ Warden crits.",
		"tip": "Counted per Warden. A waiting crit is still used, with its bonus. Other cards don't count it as a crit.",
		"keeps_out": [&"old_hand"]},
	&"lf_banked_fire": {"makes": [&"crit"], "uses": [&"rank"], "calling": "firefly_jar", "tier": DEEPEN, "parent": &"lf_pyre", "name": "Banked Fire",
		"text": "Pyre works on gold path too: there, every 3rd direct hit (bosses every 4th) from a {rank} V+ Warden crits.",
		"tip": "White path keeps every 2nd hit."},
	&"lf_spreading_flame": {"makes": [&"crit"], "uses": [&"hit"], "calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_bonfire", "name": "Spreading Flame",
		"text": "When a crit on gold path dispels a nightmare, that stretch of gold path grows 1 {step} longer at each end for 20 s, up to 4 {steps}.",
		"tip": "Another one grows it 1 more and restarts the 20 s. Grown gold counts as gold for every card. Never white."},
	&"lf_flint_and_steel": {"makes": [&"crit"], "uses": [&"cluster"], "calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_spreading_flame", "name": "Flint and Steel",
		"text": "When a Warden crits on gold path, the nearest Warden {touching} that Warden with gold path in range crits on its next direct hit on gold path.",
		"tip": "A passed crit never passes on. Each Warden holds one passed crit at a time. Sprouts count; walls don't."},
	&"lf_tinderbox": {"makes": [&"crit"], "uses": [&"cluster"], "calling": "firefly_jar", "tier": DEEPEN, "parent": &"lf_flint_and_steel", "name": "Tinderbox",
		"text": "A passed crit passes once more, to a third Warden {touching} the second, with gold path in range.",
		"tip": "Never back to a Warden it came from. It never passes to a fourth Warden."},
	&"lf_borrowed_light": {"makes": [&"jump"], "uses": [], "calling": "firefly_jar", "tier": STYLE, "parent": &"", "name": "Borrowed Light", "style": "Support",
		"text": "When a Warden that is not a Firefly lands a direct hit on a {lit} nightmare, a third of the hit {jumps} to the nearest other {lit} nightmare.",
		"tip": "Sprouts count. Each Warden once a second. A {jump} deals at most 3 s of the lighting Firefly's damage; a Sprout's has no cap. Bosses take half. It and another card's {jump} from one hit go to different nightmares.",  # F4 (owner 2026-10-18)
		"keeps_out": [&"sparks_fly", &"hammerfall"]},  # Its lent twins (section 33 card-pool sweep; Crossfire is retired)
	&"lf_lantern_wake": {"makes": [], "uses": [&"cluster"], "calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_borrowed_light", "name": "Lantern Wake",
		"text": "Each Firefly shares its glow with up to 2 Wardens of other families {touching} it: the path {touching} those Wardens is {lit}.",
		"tip": "Sprouts count; walls don't. Their light counts as that Firefly's glow. It never reveals {kind_hidden} nightmares. If more are {touching}, the 2 nearest the Heartwood."},
	&"lf_show_the_way": {"makes": [&"jump"], "uses": [&"cluster"], "calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_lantern_wake", "name": "Show the Way",
		"text": "Each Borrowed Light {jump} {jumps} once more, at half, to another {lit} nightmare; in full from a Warden that Lantern Wake made glow.",
		"tip": "Never to a nightmare the hit or {jump} already reached. Never a third time. Not star {jumps}. Bosses take half."},
	&"lf_full_glow": {"makes": [&"jump"], "uses": [&"cluster"], "calling": "firefly_jar", "tier": DEEPEN, "parent": &"lf_show_the_way", "name": "Full Glow",
		"text": "A nightmare hit directly by a Warden that Lantern Wake made glow stays {lit} for 3 s wherever it walks.",
		"tip": "It never reveals {kind_hidden} nightmares. A new hit starts the 3 s again."},
	&"lf_sightline": {"makes": [&"jump"], "uses": [], "calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_borrowed_light", "name": "Sightline",
		"text": "{lit} path in range of 3 or more Wardens that aren't Fireflies shines pale. There, Borrowed Light {jumps} half of a hit, not a third.",
		"tip": "Sprouts count; walls don't. Each Warden still once a second. Bosses take half."},
	&"lf_constellation": {"makes": [&"jump"], "uses": [], "calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_sightline", "name": "Constellation",
		"text": "When 3 different Wardens hit one nightmare on pale path within 2 s, a star lights over it: the next 3 hits on it from any Warden {jump} in full.",
		"tip": "Each nightmare once every 4 s. Each Warden still once a second. A {jump} from a Warden that isn't a Firefly still deals at most 3 s of the lighting Firefly's damage. Bosses take half."},
	&"lf_north_star": {"makes": [&"jump"], "uses": [], "calling": "firefly_jar", "tier": DEEPEN, "parent": &"lf_constellation", "name": "North Star",
		"text": "A star also lights over a boss or a {deeply_blighted} nightmare on any {lit} path when 2 different Wardens hit it within 2 s.",
		"tip": "Each nightmare once every 4 s, as usual."},
	# Retired 2026-10-23 (never offered; firefly_lights.gd keeps their code for an old save's path)
	&"lf_torchbearers": {"makes": [&"jump"], "uses": [], "calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_strung_lights", "name": "Torchbearers", "retired": true,
		"text": "When a {lit} nightmare is dispelled, half the hit that dispelled it {jumps} to the nearest {lit} nightmare ahead of it on the path.",  # Hard cards 2026-10-16
		"tip": "Ahead: at most 8 {steps} further along the path. Bosses take half."},
	&"lf_bale_fires": {"makes": [&"repeat"], "uses": [&"jump"], "calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_torchbearers", "name": "Bale-fires", "retired": true,
		"text": "If a Torchbearers {jump} dispels its target, it {jumps} again to the next {lit} nightmare ahead, up to 4 more times.",  # Hard cards 2026-10-16
		"tip": "Bosses take half."},
	&"lf_glowworms": {"makes": [], "uses": [&"cluster"], "calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_strung_lights", "name": "Glowworms", "retired": true,
		"text": "Up to 2 Sprouts {touching} each Firefly glow too, so the path next to them is {lit}.",
		"tip": "The Sprouts nearest the Heartwood glow first. Sprout light never reveals {kind_hidden} nightmares."},
	&"lf_swarm_night": {"makes": [], "uses": [&"jump"], "calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_glowworms", "name": "Swarm Night", "retired": true,
		"text": "While 6 or more nightmares are {lit}, every {jump} {jumps} one extra time.",
		"tip": "The extra {jump} is as strong as the first and goes to the nearest {lit} nightmare it hasn't hit. Bosses take half."},
	&"lf_embers": {"makes": [&"repeat"], "uses": [], "calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_bonfire", "name": "Embers", "retired": true,
		"text": "A nightmare dispelled on gold path leaves an ember for 4 s. The next nightmare over it takes half the hit that dispelled it.",
		"tip": "At most 8 embers at once. They go out when a {rest} starts. Bosses take half."},
	&"lf_witchfire": {"makes": [], "uses": [], "calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_embers", "name": "Witchfire", "retired": true,
		"text": "Embers within 2 {steps} of each other gather into a pile. When a nightmare reaches the pile, it hits every nightmare within 1 cell.",
		"tip": "A pile hits with all its embers at once. At most 3 embers to a pile. At most 6 nightmares. Bosses take half."},
	# --- Keeping Time (Bellflower) -------------------------------------------------------------------------------------
	# Rebuilt 2026-10-23 (owner, dream_council_review.md 33; D:\Projects\logs\dream_council\evo_fixed_bellflower.md):
	# Spread = rings cascade along the route, Focus = tempo, Support = repeats. Never slow, crit, jump, status or Reactions.
	&"kt_evo_carrying_tune": {"makes": [], "uses": [&"maze"], "calling": "bellflower", "tier": STYLE, "parent": &"", "name": "Carrying Tune", "style": "Spread",
		"text": "Your bells ring further: each ring also rings nightmares up to 6 {steps} further down the path. Carried rings deal no damage; a {toll} they make does.",  # Balancing 2026-10-23: 6 steps
		"tip": "A shot carries to up to 4 nightmares. Carried rings can make a {toll}; it lands like any other."},
	&"kt_evo_humming_walls": {"makes": [], "uses": [&"maze"], "calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_carrying_tune", "name": "Humming Walls",
		"text": "Every 4 {steps} a nightmare walks beside Thornwalls counts as 1 ring: no damage, never the ring that makes its {toll}, once between {tolls}.",
		"tip": "Not flyers."},
	&"kt_evo_down_the_line": {"makes": [], "uses": [&"maze"], "calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_humming_walls", "name": "Down the Line",
		"text": "A {toll} primes the nightmare behind it, within 2 {steps}: its next ring counts as 2. When that one {tolls}, it primes the next, up to 3 in a row.",
		"tip": "Behind: closer to the start, on the path. Never flyers."},
	&"kt_evo_both_ways": {"makes": [], "uses": [&"maze"], "calling": "bellflower", "tier": DEEPEN, "parent": &"kt_evo_down_the_line", "name": "Both Ways",
		"text": "A {toll} also primes the nightmare ahead of it, within 2 {steps}, the same way, up to 3 in a row.",
		"tip": ""},
	&"kt_evo_hand_to_hand": {"makes": [], "uses": [&"maze"], "calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_carrying_tune", "name": "Hand to Hand",
		"text": "When a nightmare reaches a new bell, that bell's first hit on it counts as 2 rings instead of 1.",
		"tip": "Rings stay between bells. Once for each Warden and nightmare."},
	&"kt_evo_peal": {"makes": [], "uses": [&"maze"], "calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_hand_to_hand", "name": "Peal",
		"text": "A {toll} adds 1 ring to every nightmare within 4 {steps}, but never makes their {toll}.",
		"tip": "At most 8 nightmares."},
	&"kt_evo_change_ringing": {"makes": [], "uses": [&"maze"], "calling": "bellflower", "tier": DEEPEN, "parent": &"kt_evo_peal", "name": "Change Ringing",
		"text": "When a Peal reaches a nightmare in another bell's range, that bell rings it too, at half its hit. Each bell once a second.",
		"tip": "Walls are never bells."},
	&"kt_evo_steady_beat": {"makes": [&"hit"], "uses": [&"cluster"], "calling": "bellflower", "tier": STYLE, "parent": &"", "name": "Steady Beat", "style": "Focus",
		"text": "If one bell, or one group of {touching} bells, has done all the ringing on a nightmare since its last {toll}, it {tolls} every 3rd ring instead of every 4th, in full instead of at half.",
		"tip": "Nightmares start with 2 rings filled, so a group's first ring on one {tolls}. Walls aren't bells."},
	&"kt_evo_crescendo": {"makes": [&"hit"], "uses": [&"cluster"], "calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_steady_beat", "name": "Crescendo",
		"text": "Each {toll} on a nightmare makes its next {toll} 25% stronger, up to +100%.",
		"tip": "Its ring marks grow bigger and brighter."},
	&"kt_evo_midnight_bell": {"makes": [&"hit"], "uses": [&"cluster"], "calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_crescendo", "name": "Midnight Bell",
		"text": "The 12th ring on a nightmare is a Midnight {toll}: the bell hits it for triple damage. Once per nightmare.",
		"tip": "Crescendo makes it stronger too. Starting rings don't count. Bosses take half."},
	&"kt_evo_twelfth_hour": {"makes": [&"hit"], "uses": [&"cluster"], "calling": "bellflower", "tier": DEEPEN, "parent": &"kt_evo_midnight_bell", "name": "Twelfth Hour",
		"text": "When Midnight strikes, up to 3 other nightmares in that bell's range with 6 or more rings strike their own Midnight too.",  # Balancing 2026-10-23: 3 nightmares
		"tip": "Each nightmare still has one Midnight. Bosses take half."},
	&"kt_evo_deep_tone": {"makes": [], "uses": [&"rank"], "calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_steady_beat", "name": "Deep Tone",
		"text": "Hits from a bell of rank III or higher count as 2 rings.",
		"tip": "Two rings on one nightmare within half a second count as one ring, doubled or not."},
	&"kt_evo_double_time": {"makes": [], "uses": [&"rank"], "calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_deep_tone", "name": "Double Time",
		"text": "A {toll} from a bell of rank IV or higher leaves the nightmare 2 rings into its next {toll}, not back at the start.",
		"tip": ""},
	&"kt_evo_allegro": {"makes": [], "uses": [&"rank"], "calling": "bellflower", "tier": DEEPEN, "parent": &"kt_evo_double_time", "name": "Allegro",
		"text": "A nightmare can {toll} only once a second. When that stops a rank V+ bell's {toll}, the bell keeps it (up to 3) and spends it on the next ready nightmare it hits.",
		"tip": "Kept {tolls} are lost when the drift ends."},
	&"kt_evo_accompaniment": {"makes": [&"repeat"], "uses": [&"cluster"], "calling": "bellflower", "tier": STYLE, "parent": &"", "name": "Accompaniment", "style": "Support",
		"text": "Other Wardens {touching} a bell join its song: their hits ring nightmares. When one of them makes a {toll}, the bell's {toll} lands and that Warden's hit repeats at half.",
		"tip": "Sprouts count. Each Warden rings once a second; a Sprout with every hit. Damage only: statuses don't repeat.",
		"keeps_out": [&"in_time", &"refrain"]},
	&"kt_evo_counterpoint": {"makes": [&"repeat"], "uses": [&"cluster"], "calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_accompaniment", "name": "Counterpoint",
		"text": "Each joined Warden that rings a nightmare hangs its note on it. A {toll} also repeats, at half, the hit of one other Warden with a note there.",
		"tip": "Bells don't hang notes. Each Warden once a second."},
	&"kt_evo_symphony": {"makes": [&"repeat"], "uses": [&"cluster"], "calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_counterpoint", "name": "Symphony",
		"text": "When 4 different Wardens have added rings to a nightmare, its {toll} repeats each one's last hit, at half damage.",
		"tip": "Counts from a nightmare's second {toll}: its 2 starting rings belong to no Warden. Each nightmare once every 6 s.",
		"keeps_out": [&"rude_awakening"]},
	&"kt_evo_coda": {"makes": [&"repeat"], "uses": [], "calling": "bellflower", "tier": DEEPEN, "parent": &"kt_evo_symphony", "name": "Coda",
		"text": "After a Symphony, each Warden in it has its next hit within 4 s, on any nightmare, land again at half.",
		"tip": "Once per Warden per Symphony.",
		"keeps_out": [&"refrain"]},
	&"kt_evo_tenor_bell": {"makes": [&"repeat"], "uses": [], "calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_accompaniment", "name": "Tenor Bell",
		"text": "A joined Warden whose form attacks once a second or slower repeats its hit in full instead of half.",
		"tip": "Its form's speed: Dreams that quicken it don't take this away."},
	&"kt_evo_ensemble": {"makes": [&"repeat"], "uses": [&"cluster"], "calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_tenor_bell", "name": "Ensemble",
		"text": "Around a bell {touching} Wardens of 2 or more other families, those Wardens' repeats land again 1 s later, at half.",
		"tip": "Sprouts count as one family. Bells and walls don't count.",
		"keeps_out": [&"reprise"]},
	&"kt_evo_sounding_board": {"makes": [&"repeat"], "uses": [], "calling": "bellflower", "tier": DEEPEN, "parent": &"kt_evo_ensemble", "name": "Sounding Board",
		"text": "Other Wardens {touching} a joined Warden join that bell's song too.",
		"tip": "They don't count as families for Ensemble."},
	# Retired 2026-10-23 (never offered; keeping_time.gd keeps their code for an old save's path)
	&"kt_evo_lingering_note": {"makes": [&"repeat"], "uses": [], "calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_carrying_tune", "name": "Lingering Note", "retired": true,
		"text": "A {toll} leaves a note on the path for 2 s. Every nightmare that walks through it is rung once.",
		"tip": "One note for each bell; its next {toll} moves it."},
	&"kt_evo_night_choir": {"makes": [&"repeat"], "uses": [], "calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_lingering_note", "name": "Night Choir", "retired": true,
		"text": "A note {touching} a Warden also repeats that Warden's last hit, at half damage, on each nightmare walking through it.",
		"tip": "At most 3 Wardens for each note, the strongest first. Never more than 1 s of that Warden's damage."},
	&"kt_evo_hush_a_bye": {"makes": [&"drowsy", &"asleep"], "uses": [], "calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_steady_beat", "name": "Hush-a-bye", "retired": true,
		"text": "Each {toll} adds 2 {stacks} of {drowsy}. A nightmare that takes 3 {tolls} within 6 s falls {asleep} for 1 s.",
		"tip": "Never bosses or a nightmare already {asleep}. Each nightmare once every 8 s."},
	&"kt_evo_sleeping_hall": {"makes": [], "uses": [&"asleep"], "calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_hush_a_bye", "name": "Sleeping Hall", "retired": true,
		"text": "When a nightmare put {asleep} by Hush-a-bye wakes, its next {toll} within 3 s also hits up to 4 nightmares {touching} it, at half damage.",
		"tip": "Only that one {toll} spreads."},
	&"kt_evo_chime_of_many": {"makes": [&"repeat"], "uses": [], "calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_accompaniment", "name": "Chime of Many", "retired": true,
		"text": "A {toll} also repeats the nightmare's last status hit on up to 4 nightmares {touching} it.",
		"tip": "The same Warden's status and {stacks} again: caps and immunities apply. Each nightmare once per {toll}. Doesn't add {drowsy} or {held}."},
	&"kt_evo_last_chord": {"makes": [&"reaction"], "uses": [&"layered"], "calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_chime_of_many", "name": "Last Chord", "retired": true,
		"text": "A {toll} on a nightmare with 3 or more statuses triggers any {reaction} that nightmare is halfway to.",
		"tip": "Each nightmare once every 8 s, counted only when a {reaction} triggers."},
	# --- Puddles (Dewdrop) -----------------------------------------------------------------------------------------------
	# Rebuilt 2026-10-23 (owner, dream_council_review.md 33; D:\Projects\logs\dream_council\evo_fixed_dewdrop.md):
	# Spread = the one capped Calling slow (class_kit.calling_slow; its amount only from Stream 15% and the capstones 30%, the
	# other rows grow where or how long), Focus = area damage across one pond (class_kit.calling_hit, damage only), Support =
	# other families' statuses linger by the water (EnemyStatuses.linger_calling, mark_kept). Every Deepen adds a new trigger
	# or place, never a bigger number.
	&"dw_stream": {"makes": [&"slow"], "uses": [&"maze"], "calling": "dewdrop", "tier": STYLE, "parent": &"", "name": "Stream", "style": "Spread",
		"text": "{Water} runs 4 {steps} further toward the Heartwood, and nightmares in it walk 15% slower.",
		"tip": "Bosses are slowed half as much. Flyers never walk in {water}. Timed slows don't add: the strongest counts. {drowsy} still adds."},
	&"dw_reed_bed": {"makes": [], "uses": [&"maze"], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_stream", "name": "Reed Bed",
		"text": "From each end of a {water}, {water} spreads along path with a Thornwall or Sprout beside it, up to 12 more {steps} for each {water}.",
		"tip": "Counted in {steps} of path."},
	&"dw_flash_flood": {"makes": [&"slow"], "uses": [&"maze"], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_reed_bed", "name": "Flash Flood",
		"text": "A {family:dewdrop} Warden's {dew_splash} runs down its whole {water}, up to 24 {steps} each way: nightmares it reaches walk 30% slower (bosses 15%) for 2 s.",
		"tip": "{damp} still reaches only 4 {steps}. Another splash restarts the 2 s. Each nightmare once a second."},
	&"dw_long_current": {"makes": [&"slow"], "uses": [&"maze"], "calling": "dewdrop", "tier": DEEPEN, "parent": &"dw_flash_flood", "name": "Long Current",
		"text": "Nightmares leaving {water} stay as slow as they were in it for 6 more {steps}.",
		"tip": "Bosses keep their halved slow. Never flyers."},
	&"dw_backwaters": {"makes": [], "uses": [&"maze"], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_stream", "name": "Backwaters",
		"text": "Where the path passes the same {family:dewdrop} Warden twice, making two {waters}, path up to 6 {steps} long between them is {water} too.",
		"tip": "Counted in {steps} of path."},
	&"dw_mudflats": {"makes": [&"slow"], "uses": [&"maze"], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_backwaters", "name": "Mudflats",
		"text": "Path between two {waters} up to 4 {steps} apart turns to mud. In {water} and on mud, nightmares walk 30% slower instead of 15% (bosses 15%).",
		"tip": "Mud isn't {water}. Mud never covers more {steps} than all your {water}: the shortest gaps turn first. Never flyers."},
	&"dw_sinking_mud": {"makes": [&"slow"], "uses": [&"maze"], "calling": "dewdrop", "tier": DEEPEN, "parent": &"dw_mudflats", "name": "Sinking Mud",
		"text": "Flyers crossing mud or {water} are slowed too: 30% (bosses 15%) for 2 s.",
		"tip": ""},
	&"dw_black_pond": {"makes": [&"area"], "uses": [&"rank"], "calling": "dewdrop", "tier": STYLE, "parent": &"", "name": "Black Pond", "style": "Focus",
		"text": "The pond is your highest-{rank} {family:dewdrop} Warden's {water}. That Warden's direct hits in the pond also spill 25% of their damage onto up to 4 other nightmares there.",
		"tip": "Damage only: no statuses. Once per attack. Ties: the higher form, then the first planted. The pond is drawn darker."},
	&"dw_deep_end": {"makes": [&"area"], "uses": [&"rank"], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_black_pond", "name": "Deep End",
		"text": "The pond's spill is 25% of the damage, +3% for each {rank} of the pond's Warden (46% at {rank} VII).",
		"tip": ""},
	&"dw_breaking_wave": {"makes": [&"area"], "uses": [&"rank"], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_deep_end", "name": "Breaking Wave",
		"text": "When 4 or more nightmares are in the pond and its Warden is {rank} V or higher, a wave breaks: that Warden hits each of them for full damage.",
		"tip": "Damage only. The pond breaks at most once every 4 s, on up to 6 nightmares, furthest along first."},
	&"dw_king_tide": {"makes": [&"area"], "uses": [&"rank"], "calling": "dewdrop", "tier": DEEPEN, "parent": &"dw_breaking_wave", "name": "King Tide",
		"text": "A boss in the pond counts as 4 nightmares for Breaking Wave. Breaking Wave ignores the {dread_shell} of every nightmare except bosses.",
		"tip": ""},
	&"dw_twin_springs": {"makes": [&"area"], "uses": [&"cluster"], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_black_pond", "name": "Twin Springs",
		"text": "One other {family:dewdrop} Warden {touching} the pond's Warden joins the pond: its {water} becomes pond too, and its direct hits there spill as well.",
		"tip": "Only one joins: the highest-{rank} one {touching}."},
	# Churning Water: the fix file's code column (at most 4 half hits a churn, ~0.67 hits a second) wins over its face's "each of
	# them hits up to 4", so the face says the churn's 4 (Roguelite Code 2026-10-23).
	&"dw_churning_water": {"makes": [&"area"], "uses": [&"cluster"], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_twin_springs", "name": "Churning Water",
		"text": "While 2 {family:dewdrop} Wardens share the pond, it churns every 3 s: between them, they hit up to 4 nightmares in the pond for half their damage.",
		"tip": "Damage only. The clock only runs during a {drift}."},
	&"dw_three_springs": {"makes": [&"area"], "uses": [&"cluster"], "calling": "dewdrop", "tier": DEEPEN, "parent": &"dw_churning_water", "name": "Three Springs",
		"text": "A third {family:dewdrop} Warden {touching} either pond Warden joins the pond: its {water} becomes pond too and its direct hits there spill. Churns still come from the two highest-{rank} only.",
		"tip": ""},
	&"dw_riverside": {"makes": [&"linger"], "uses": [], "calling": "dewdrop", "tier": STYLE, "parent": &"", "name": "Riverside", "style": "Support",
		"text": "Another family's Warden {touching} {water}: its statuses on nightmares in that {water} last 2 s longer. A Sprout's hit there: +1 s to each status.",
		"tip": "Sprouts count; {family:dewdrop} Wardens don't. Each Sprout once a second per nightmare. Up to 4 s past landing in all ({static} 2 s). Never {drowsy} or {held}.",
		"keeps_out": [&"steeped"]},  # Its lent twin (section 33 card-pool sweep)
	&"dw_open_water": {"makes": [&"linger"], "uses": [], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_riverside", "name": "Open Water",
		"text": "Statuses that other families' Wardens put on nightmares in {water} last 2 s longer, wherever the Warden stands.",
		"tip": "Up to 4 s past landing in all ({static} 2 s). Never {drowsy} or {held}."},
	&"dw_still_water": {"makes": [&"linger"], "uses": [], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_open_water", "name": "Still Water",
		"text": "While 3 or more other-family Wardens are {touching} a {water}, statuses from other families on nightmares in it stop wearing off, up to 4 s past landing ({static} 2 s).",
		"tip": "Sprouts count; {family:dewdrop} Wardens don't. Never {drowsy} or {held}. Bosses' statuses wear off at half speed.",
		"keeps_out": [&"topped_up"]},
	&"dw_wide_banks": {"makes": [&"linger"], "uses": [&"cluster"], "calling": "dewdrop", "tier": DEEPEN, "parent": &"dw_still_water", "name": "Wide Banks",
		"text": "Wardens within 2 cells of a {water} count as {touching} it for Riverside and Still Water.",
		"tip": ""},
	# Wet Footprints: the owner's ruling keeps Poisoned and Exposed at the 4 s room (one room for the Calling and the lent
	# cards, EnemyStatuses.SHARED_LINGER_ROOM), so the fix file's "own 2 s room" tip would be untrue: the tip says the shared room.
	&"dw_wet_footprints": {"makes": [&"linger"], "uses": [], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_riverside", "name": "Wet Footprints",
		"text": "For 2 s after a nightmare leaves {water}, its statuses from other families don't wear off, up to 4 s past landing in all ({static} 2 s).",
		"tip": "These 2 s share that room with Riverside and Open Water's extra time. Never {drowsy} or {held}."},
	&"dw_low_tide": {"makes": [], "uses": [&"linger"], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_wet_footprints", "name": "Low Tide",
		"text": "Other families' Wardens' direct hits deal 10% more damage for each status the {water} is keeping on the nightmare, up to +30%.",
		"tip": "Kept: a status the {water} stops or slows from wearing off, or one past its normal time. Its time bar turns Dew-light.",
		"keeps_out": [&"high_tide"]},
	&"dw_outflow": {"makes": [], "uses": [&"linger"], "calling": "dewdrop", "tier": DEEPEN, "parent": &"dw_low_tide", "name": "Outflow",
		"text": "After a nightmare leaves {water}, the first direct hit on it from another family's Warden deals 20% more damage for each status still kept, up to +60%.",
		"tip": "Each nightmare once for each {water} it leaves. On that hit, it replaces Low Tide's bonus."},
	# Retired 2026-10-23 (never offered; puddles.gd keeps their code for an old save's path)
	&"dw_millrace": {"makes": [&"layered"], "uses": [], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_stream", "name": "Millrace", "retired": true,
		"text": "A {dew_splash} also spreads 1 {stack} of up to 3 other statuses from the nightmare it hit to every nightmare it reaches.",
		"tip": "A thread shows each carry. Doesn't add {drowsy} or {held}; {static} stops 1 short of a bolt."},
	&"dw_flood": {"makes": [], "uses": [&"maze"], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_millrace", "name": "Flood", "retired": true,
		"text": "A Dewdrop's {dew_splash} runs the whole length of its {water}, up to 24 {steps} each way instead of 4.",
		"tip": "A long {dew_splash} flashes along the {water}."},
	&"dw_lapping_water": {"makes": [], "uses": [&"soaked"], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_stream", "name": "Lapping Water", "retired": true,
		"text": "When a Warden {touching} {water} hits a nightmare with {damp} there, nightmares within 2 {steps} of it in that {water} get {damp} too.",
		"tip": "Dewdrops don't count. Sprouts count. Each Warden once a second."},
	&"dw_spring_flood": {"makes": [&"soaked"], "uses": [], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_lapping_water", "name": "Spring Flood", "retired": true,
		"text": "Every 10 s, up to 8 nightmares in the longest {water} with nightmares in it reach {full} {damp} and walk 25% slower for 2 s.",
		"tip": "The clock only runs during a {drift}. Bosses are slowed half as much."},
	&"dw_whirlpool": {"makes": [&"slow"], "uses": [], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_black_pond", "name": "Whirlpool", "retired": true,
		"text": "A Dewdrop's 3rd hit on a nightmare in a pond pulls it back 2 {steps}. Once for each pond and nightmare.",
		"tip": "Never bosses or flyers."},
	&"dw_drowning_deep": {"makes": [&"slow"], "uses": [], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_whirlpool", "name": "Drowning Deep", "retired": true,
		"text": "A Whirlpool pull drags nightmares within 1 cell back with it, and every Warden {touching} the pond gets a {free_hit} on the pulled nightmare.",
		"tip": "Drags at most 4 nightmares, never bosses or flyers. Free hits: each Warden once a second."},
	&"dw_stagnant_water": {"makes": [&"linger"], "uses": [], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_black_pond", "name": "Stagnant Water", "retired": true,
		"text": "Statuses on nightmares in a pond don't run down while they stay in it.",
		"tip": "Doesn't lengthen {drowsy} or {held}. Bosses' statuses fade at half speed. Up to 4 s past landing ({static} 2 s), on top of cards that do the same."},  # F2 (tip kept within 30 words)
	&"dw_drowned_hands": {"makes": [&"rooted"], "uses": [&"layered"], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_stagnant_water", "name": "Drowned Hands", "retired": true,
		"text": "A nightmare in a pond with 4 or more statuses gains 1 {held}: it can't move for 1 s (bosses 0.5 s).",
		"tip": "The pond's strongest Dewdrop adds the {held}. Once for each pond and nightmare."},
	&"dw_rain_on_the_bank": {"makes": [&"layered"], "uses": [], "calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_riverside", "name": "Rain on the Bank", "retired": true,
		"text": "A {dew_splash} also gives each nightmare it reaches 1 {stack} of the status of each Warden {touching} that {water}, Dewdrops too.",
		"tip": "At most 3 Wardens, the strongest first. {drowsy} stops 1 short of {full}. Doesn't add {held}."},  # F5
	&"dw_downpour": {"makes": [&"repeat"], "uses": [], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_rain_on_the_bank", "name": "Downpour", "retired": true,
		"text": "When a {dew_splash} reaches 4 or more nightmares, every other Warden {touching} that {water} attacks one of them at once.",
		"tip": "Each Warden once every 4 s."},
	&"dw_reflection": {"makes": [], "uses": [&"soaked"], "calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_wet_footprints", "name": "Reflection", "retired": true,
		"text": "When a Warden {touching} {water} hits a nightmare with {damp} there, half the hit also lands on the nightmare furthest back in that {water}.",
		"tip": "Dewdrops don't count. Half of the hit before defences. Each Warden once a second."},
}

static func has_paths(calling: String) -> bool:
	for id in PATHS:
		if PATHS[id].calling == calling and is_live(id):
			return true
	return false

static func stage_of(drift: int) -> int:
	return DRIFTS.find(drift)

# A row that can still be offered: in PATHS and not "retired" (a retired row's code stays for old saves).
static func is_live(id: StringName) -> bool:
	return PATHS.has(id) and not bool(PATHS[id].get("retired", false))

# Card ids a live row keeps out of the Dream offers while it is held (its lent twins; never retroactive).
static func keeps_out(id: StringName) -> Array:
	return Array(PATHS[id].get("keeps_out", [])) if is_live(id) else []

# The ids offered at `stage` (0 style, 1 follow-up, 2 capstone, 3 Deepen or Cross over) for `calling` after `path` (the ids
# taken so far, in order), or []. A missed or repeated stage, or a retired or unknown id in the path, offers nothing
# (evo_shared_spec.md 1). `stage` left out: the path's length (old callers).
static func next_ids(calling: String, path: Array, stage: int = -99) -> Array[StringName]:
	var out: Array[StringName] = []
	if stage == -99:
		stage = path.size()
	if stage < 0 or path.size() != stage:
		return out
	for id in path:
		if not is_live(StringName(id)):
			return out
	match stage:
		STYLE:
			for id in PATHS:
				if PATHS[id].calling == calling and int(PATHS[id].tier) == STYLE and is_live(id):
					out.append(id)
		FOLLOW_UP:
			out = _children_of_tier(path[0], FOLLOW_UP)
		CAPSTONE:
			out = _children_of_tier(path[1], CAPSTONE)
		DEEPEN:  # Drift 75: the capstone's Deepen first, then the style's other follow-up (Cross over)
			out = _children_of_tier(path[2], DEEPEN)
			for id in _children_of_tier(path[0], FOLLOW_UP):
				if not path.has(id):
					out.append(id)
	return out

# Live rows whose parent is `parent`.
static func children(parent: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in PATHS:
		if PATHS[id].parent == parent and is_live(id):
			out.append(id)
	return out

static func _children_of_tier(parent: StringName, tier: int) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in children(parent):
		if int(PATHS[id].tier) == tier:
			out.append(id)
	return out

static func display_name(id: StringName) -> String:
	return String(PATHS[id].name) if PATHS.has(id) else String(id)

# The card the Dream screen shows for evolution `id` (built fresh; never in the Dream pool, never taken as a card).
static func card(id: StringName, stage: int = -1) -> UpgradeData:
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
	if int(row.tier) == DEEPEN:
		out.tags.append("deepen")  # The Dream screen labels stage 3: Deepen or Cross over
	elif int(row.tier) == FOLLOW_UP and stage == DEEPEN:
		out.tags.append("cross_over")
	return out

# "Spore Print → Clump → Sticky Caps" for the badge and the Dreams panel.
static func path_text(calling_title: String, path: Array) -> String:
	var parts: Array[String] = [calling_title]
	for id in path:
		if PATHS.has(id):  # An unknown id (a retired placeholder from an old save) is left out
			parts.append(display_name(id))
	return " → ".join(parts)
