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
		"text": "A mushroom that gives a dose seeds a new one 3 steps further down the path, for the next nightmare.",
		"tip": "Seeded mushrooms don't seed again, and go first when there are too many. Leads to: Spore Season, Witch Ring."},
	&"sp_drifting": {"calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_windblown", "name": "Drifting Spores",
		"text": "A dose also adds 2 stacks to every other status the nightmare carries.",
		"tip": "Never starts a status, never Rooted. A status it fills flashes. Leads to: Spore Season."},
	&"sp_season": {"calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_drifting", "name": "Spore Season",
		"text": "While 15 or more mushrooms grow, every dose is half again as big and the mushrooms glow.",
		"tip": "Seeded mushrooms don't count toward the 15."},
	&"sp_fairy_path": {"calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_windblown", "name": "Fairy Path",
		"text": "A step touching a spore Warden and another attacking Warden grows its mushroom back 8 s after it is used.",
		"tip": "The clock only runs during a drift; every such step is full again when a rest starts. Leads to: Witch Ring."},
	&"sp_witch_ring": {"calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_fairy_path", "name": "Witch Ring",
		"text": "A nightmare that steps on 3 mushrooms within 4 s is Held for 1 s.",
		"tip": "Bosses 0.5 s. Each nightmare once every 10 s."},
	&"sp_clump": {"calling": "sporeling", "tier": STYLE, "parent": &"", "name": "Clump", "style": "Focus",
		"text": "New mushrooms join one within 3 steps, up to 4. Stepping on a clump gives a dose for each mushroom in it, then one is eaten.",
		"tip": "Clumps form where your Poisoned nightmares fall. Leads to: Mire-Mouth, Rotburst."},
	&"sp_sticky": {"calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_clump", "name": "Sticky Caps",
		"text": "A nightmare stepping on a clump walks at half speed, 1 s for each mushroom in it (up to 3 s).",
		"tip": "Bosses half as long. Leads to: Mire-Mouth."},
	&"sp_mire_mouth": {"calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_sticky", "name": "Mire-Mouth",
		"text": "When a nightmare gets stuck, the 2 nightmares behind it within 2 cells are stuck too, half as long.",
		"tip": "Never pulls in a boss."},
	&"sp_rot": {"calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_clump", "name": "Rot",
		"text": "A clump's dose adds 2 stacks to each other status the nightmare carries, for each mushroom in it.",
		"tip": "Never starts a status, never Rooted. A status it fills flashes. Leads to: Rotburst."},
	&"sp_rotburst": {"calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_rot", "name": "Rotburst",
		"text": "When a clump's last mushroom is eaten it bursts: up to 6 nightmares within 1.5 cells take a dose and 2 of each status the eater had.",
		"tip": "Only a mushroom that was ever a clump of 2 or more bursts. Never Drowsy or Rooted."},
	&"sp_borrowed": {"calling": "sporeling", "tier": STYLE, "parent": &"", "name": "Borrowed Spores", "style": "Support",
		"text": "A mushroom touching one of your Wardens also gives 2 stacks of that Warden's status. A Sprout touching it adds 2 more Poisoned.",
		"tip": "Grows stronger with a second family. Leads to: Outbreak, Mother Spore."},
	&"sp_catching": {"calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_borrowed", "name": "Catching",
		"text": "A nightmare that took a dose passes half of it to the first nightmare it touches within 2 s.",
		"tip": "Once per dose. Leads to: Outbreak."},
	&"sp_outbreak": {"calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_catching", "name": "Outbreak",
		"text": "A passed dose can be passed on again, up to 3 times, halving each time.",
		"tip": "It stops at 1 stack."},
	&"sp_feeding": {"calling": "sporeling", "tier": FOLLOW_UP, "parent": &"sp_borrowed", "name": "Feeding Ground",
		"text": "Wardens touching a mushroom's step add 1 more stack of their status to a nightmare that took a dose there.",
		"tip": "For 4 s after the dose; each Warden once per nightmare. Leads to: Mother Spore."},
	&"sp_mother": {"calling": "sporeling", "tier": CAPSTONE, "parent": &"sp_feeding", "name": "Mother Spore",
		"text": "A mushroom left by a dispel remembers up to 4 of the nightmare's statuses. Its dose gives 2 of each.",
		"tip": "Speckled caps. Never Drowsy or Rooted."},
	# --- Lantern Light (Firefly Jar) -----------------------------------------------------------------------------------
	&"lf_strung_lights": {"calling": "firefly_jar", "tier": STYLE, "parent": &"", "name": "Strung Lights", "style": "Spread",
		"text": "Glows within 4 steps of each other join up: the path between them is lit too.",
		"tip": "The joined path is Lit, but never shows hidden nightmares. Leads to: Bale-fires, Swarm Night."},
	&"lf_torchbearers": {"calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_strung_lights", "name": "Torchbearers",
		"text": "When a Lit nightmare is dispelled, the next light down the path throws half that hit at its front nightmare.",
		"tip": "Each light throws once a second. The next light is at most 8 steps ahead. Leads to: Bale-fires."},
	&"lf_bale_fires": {"calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_torchbearers", "name": "Bale-fires",
		"text": "A throw that dispels is thrown on again from the next light, up to 4 more lights toward the Heartwood.",
		"tip": "Each light still throws once a second. Bosses take half."},
	&"lf_glowworms": {"calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_strung_lights", "name": "Glowworms",
		"text": "Up to 2 Sprouts touching each Firefly Warden glow by themselves: the path they touch is lit.",
		"tip": "The Sprouts nearest the Heartwood glow first. Sprout light never shows hidden nightmares. Leads to: Swarm Night."},
	&"lf_swarm_night": {"calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_glowworms", "name": "Swarm Night",
		"text": "While 10 or more nightmares are Lit, every jump jumps once more.",
		"tip": "The extra jump is as strong as the first and goes to the nearest Lit nightmare it hasn't hit. Bosses take half."},
	&"lf_bonfire": {"calling": "firefly_jar", "tier": STYLE, "parent": &"", "name": "Bonfire", "style": "Focus",
		"text": "Path inside two Firefly Wardens' glows burns gold. A dispel there jumps to 2 Lit nightmares instead of 1.",
		"tip": "Leads to: Pyre, Witchfire."},
	&"lf_moth_to_flame": {"calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_bonfire", "name": "Moth to Flame",
		"text": "A jump that lands on gold path adds 2 Exposed.",
		"tip": "Exposed works at 10 stacks (20 with Brimming): watch it build. Bosses take 1. Leads to: Pyre."},
	&"lf_pyre": {"calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_moth_to_flame", "name": "Pyre",
		"text": "A jump that dispels a nightmare on gold path jumps again at the same strength, up to 3 times.",
		"tip": "A boss's summons count too. Bosses take half."},
	&"lf_embers": {"calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_bonfire", "name": "Embers",
		"text": "A nightmare dispelled on gold path leaves an ember for 4 s. The next nightmare to reach it takes half the dispelling hit.",
		"tip": "Up to 8 embers at once; they go out when a rest starts. Bosses take half. Leads to: Witchfire."},
	&"lf_witchfire": {"calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_embers", "name": "Witchfire",
		"text": "Embers within 2 steps pile up, up to 3. A pile bursts on every nightmare within 1 cell.",
		"tip": "A pile hits with all its embers at once, on up to 6 nightmares. Bosses take half."},
	&"lf_borrowed_light": {"calling": "firefly_jar", "tier": STYLE, "parent": &"", "name": "Borrowed Light", "style": "Support",
		"text": "Hits on Lit nightmares from Wardens that aren't Firefly Wardens jump a third to the nearest other Lit nightmare.",
		"tip": "Sprouts count. Once a second for each Warden. Leads to: Lantern Wake, Constellation. Grows stronger with a second family."},
	&"lf_show_the_way": {"calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_borrowed_light", "name": "Show the Way",
		"text": "Wardens within a Firefly Warden's glow add 1 more stack with their status hits on Lit nightmares.",
		"tip": "Once a second for each Warden. Never starts a status, never Drowsy. Leads to: Lantern Wake. Grows stronger with a second family."},
	&"lf_lantern_wake": {"calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_show_the_way", "name": "Lantern Wake",
		"text": "A jump carries 1 stack of each status its nightmare had onto the same statuses on the one it lands on.",
		"tip": "Up to 4 statuses. Never starts a status, never Rooted. Grows stronger with a second family."},
	&"lf_sightline": {"calling": "firefly_jar", "tier": FOLLOW_UP, "parent": &"lf_borrowed_light", "name": "Sightline",
		"text": "When 3 different Wardens hit the same Lit nightmare within 2 s, a quarter of each hit jumps to the nearest other Lit nightmare.",
		"tip": "Sprouts count. Each nightmare once every 4 s. Leads to: Constellation. Grows stronger with a second family."},
	&"lf_constellation": {"calling": "firefly_jar", "tier": CAPSTONE, "parent": &"lf_sightline", "name": "Constellation",
		"text": "A nightmare struck by jumps from 3 different Wardens within 3 s becomes fully Exposed.",
		"tip": "Each nightmare once every 8 s. Bosses fill only half. Grows stronger with a second family."},
	# --- Keeping Time (Bellflower) -------------------------------------------------------------------------------------
	&"kt_evo_carrying_tune": {"calling": "bellflower", "tier": STYLE, "parent": &"", "name": "Carrying Tune", "style": "Spread",
		"text": "A bell's ring carries 4 steps down the path, at half: past a pulsing bell's reach, or past a shooting bell's target. Carried rings fill pips.",
		"tip": "It stops at the next bell's reach. A shot carries to up to 4 nightmares. Leads to: Peal, Night Choir."},
	&"kt_evo_hand_to_hand": {"calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_carrying_tune", "name": "Hand to Hand",
		"text": "When a nightmare reaches a new bell, that bell's first ring on it fills 2 pips.",
		"tip": "Pips always stay lit between bells. Once for each bell. Leads to: Peal."},
	&"kt_evo_peal": {"calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_hand_to_hand", "name": "Peal",
		"text": "A Toll fills 1 pip on every nightmare within 4 steps of it, but never its last pip.",
		"tip": "Up to 8 nightmares. A ring still has to make the Toll."},
	&"kt_evo_lingering_note": {"calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_carrying_tune", "name": "Lingering Note",
		"text": "A Toll leaves a note on the path for 2 s. Each nightmare walking through it rings once.",
		"tip": "One note for each bell; its next Toll moves it. Leads to: Night Choir."},
	&"kt_evo_night_choir": {"calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_lingering_note", "name": "Night Choir",
		"text": "A note beside a Warden also lands that Warden's last hit again, at half, on each nightmare walking through.",
		"tip": "Up to 3 Wardens per note, the strongest first. Never more than a second of that Warden's damage."},
	&"kt_evo_steady_beat": {"calling": "bellflower", "tier": STYLE, "parent": &"", "name": "Steady Beat", "style": "Focus",
		"text": "Nightmares in reach of 2 or more bells start with 3 pips filled, and their Tolls land in full.",
		"tip": "Where bells overlap, the path shows a double ring. Leads to: Midnight Bell, Sleeping Hall."},
	&"kt_evo_crescendo": {"calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_steady_beat", "name": "Crescendo",
		"text": "Each Toll on a nightmare makes its next Toll 25% stronger, up to double.",
		"tip": "Its pips grow bigger and brighter. Leads to: Midnight Bell."},
	&"kt_evo_midnight_bell": {"calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_crescendo", "name": "Midnight Bell",
		"text": "The 12th ring on a nightmare is a Midnight Toll: every status on it that deals damage pays out at once, and stays.",
		"tip": "Poisoned ticks, Charged bolts, Soaked calls up to 2 Dewdrops near it. Once per nightmare; a dial over it counts to 12. Bosses take half."},
	&"kt_evo_hush_a_bye": {"calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_steady_beat", "name": "Hush-a-bye",
		"text": "A Toll adds 2 Drowsy. Three Tolls within 6 s and the nightmare naps for 1 s.",
		"tip": "Never bosses or a sleeper; each nightmare naps once every 8 s. Leads to: Sleeping Hall."},
	&"kt_evo_sleeping_hall": {"calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_hush_a_bye", "name": "Sleeping Hall",
		"text": "When a Hush-a-bye nap ends, the nightmare's next Toll also lands on every nightmare touching it, up to 4, at half.",
		"tip": "Within 3 s of waking."},
	&"kt_evo_accompaniment": {"calling": "bellflower", "tier": STYLE, "parent": &"", "name": "Accompaniment", "style": "Support",
		"text": "Hits from Wardens touching a bell fill pips too, and their Tolls repeat that Warden's hit and status. A Sprout touching a bell fills a pip with every hit.",
		"tip": "Other Wardens once a second; their pips glow pink. Leads to: Symphony, Last Chord. Grows stronger with a second family."},
	&"kt_evo_counterpoint": {"calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_accompaniment", "name": "Counterpoint",
		"text": "When a Warden that isn't a bell lands a Toll, the nearest bell within 4 cells rings that nightmare too.",
		"tip": "Each bell once a second; its ring is a free hit and fills a pip. Leads to: Symphony. Grows stronger with a second family."},
	&"kt_evo_symphony": {"calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_counterpoint", "name": "Symphony",
		"text": "A Toll filled by 4 different Wardens rings for all of them: each one's last hit lands again, at half.",
		"tip": "From a nightmare's second Toll on (its 2 starting pips belong to no one). Each nightmare once every 6 s. Grows stronger with a second family."},
	&"kt_evo_chime_of_many": {"calling": "bellflower", "tier": FOLLOW_UP, "parent": &"kt_evo_accompaniment", "name": "Chime of Many",
		"text": "A Toll adds 1 stack to each status on the nightmare and on up to 4 nightmares touching it.",
		"tip": "Never starts a status, never Drowsy or Rooted. Each status it adds to flashes. Leads to: Last Chord. Grows stronger with a second family."},
	&"kt_evo_last_chord": {"calling": "bellflower", "tier": CAPSTONE, "parent": &"kt_evo_chime_of_many", "name": "Last Chord",
		"text": "A Toll on a nightmare carrying 3 or more statuses sets off any Reaction it is halfway to.",
		"tip": "Each nightmare once every 8 s, counted only when one goes off. Grows stronger with a second family."},
	# --- Puddles (Dewdrop) -----------------------------------------------------------------------------------------------
	&"dw_stream": {"calling": "dewdrop", "tier": STYLE, "parent": &"", "name": "Stream", "style": "Spread",
		"text": "Water flows on: 4 steps of path past the end of each water are water too.",
		"tip": "It flows toward the Heartwood and joins the next water it reaches. Leads to: Flood, Spring Flood."},
	&"dw_millrace": {"calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_stream", "name": "Millrace",
		"text": "A ripple also carries 1 stack of up to 3 other statuses on the hit nightmare to every nightmare it soaks.",
		"tip": "Never Drowsy or Held; Charged never fills to a bolt. A thread shows each carry. Leads to: Flood."},
	&"dw_flood": {"calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_millrace", "name": "Flood",
		"text": "A ripple runs the whole length of its water, up to 24 steps each way.",
		"tip": "A long ripple flashes along the water."},
	&"dw_lapping_water": {"calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_stream", "name": "Lapping Water",
		"text": "A hit from any other Warden touching water on a Soaked nightmare in it ripples 2 steps.",
		"tip": "Sprouts count. Each Warden once a second. Leads to: Spring Flood."},
	&"dw_spring_flood": {"calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_lapping_water", "name": "Spring Flood",
		"text": "Every 10 s the longest water with a nightmare in it floods: up to 8 nightmares in it are fully Soaked and walk 25% slower for 2 s.",
		"tip": "The clock only runs during a drift. Bosses are slowed half as much."},
	&"dw_black_pond": {"calling": "dewdrop", "tier": STYLE, "parent": &"", "name": "Black Pond", "style": "Focus",
		"text": "Water touching 2 or more Dewdrops is a pond: nightmares in it walk 25% slower and its ripple runs 8 steps.",
		"tip": "Ponds are drawn darker. Bosses are slowed half as much. Leads to: Drowning Deep, Drowned Hands."},
	&"dw_whirlpool": {"calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_black_pond", "name": "Whirlpool",
		"text": "A fully Soaked nightmare in a pond is pulled back 2 steps, once per pond.",
		"tip": "Never bosses or flyers. Leads to: Drowning Deep."},
	&"dw_drowning_deep": {"calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_whirlpool", "name": "Drowning Deep",
		"text": "A Whirlpool pull drags up to 4 nightmares within 1 cell with it, and every Warden touching the pond hits the pulled one once, free.",
		"tip": "Never drags bosses or flyers. Each Warden gives one free hit a second at most."},
	&"dw_stagnant_water": {"calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_black_pond", "name": "Stagnant Water",
		"text": "Statuses landing on nightmares in a pond get 1 more stack.",
		"tip": "Each Warden once a second. Never Drowsy. A splash shows each extra stack. Leads to: Drowned Hands."},
	&"dw_drowned_hands": {"calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_stagnant_water", "name": "Drowned Hands",
		"text": "A nightmare carrying 4 statuses in a pond is grabbed and Held for 1 s, once per pond.",
		"tip": "Held by the pond's strongest Dewdrop. Bosses 0.5 s."},
	&"dw_riverside": {"calling": "dewdrop", "tier": STYLE, "parent": &"", "name": "Riverside", "style": "Support",
		"text": "Wardens touching water add 1 more stack with their first status hit on each nightmare in that water.",
		"tip": "Dewdrops count, Sprouts don't. A splash shows each extra stack. Leads to: Downpour, Reflection. Grows stronger with a second family."},
	&"dw_rain_on_the_bank": {"calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_riverside", "name": "Rain on the Bank",
		"text": "A ripple gives every nightmare it soaks 1 stack of the status of each other Warden touching that water (up to 3).",
		"tip": "The strongest 3 Wardens. Never Drowsy. Leads to: Downpour. Grows stronger with a second family."},
	&"dw_downpour": {"calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_rain_on_the_bank", "name": "Downpour",
		"text": "A ripple that soaks 4 or more nightmares makes every other Warden touching that water attack one of them at once.",
		"tip": "Each Warden once every 4 s. Grows stronger with a second family."},
	&"dw_wet_footprints": {"calling": "dewdrop", "tier": FOLLOW_UP, "parent": &"dw_riverside", "name": "Wet Footprints",
		"text": "A Soaked nightmare leaving water leaves wet steps behind it for 3 s. Wet steps count as water.",
		"tip": "Up to 6 steps per nightmare; wet steps never leave more. Leads to: Reflection. Grows stronger with a second family."},
	&"dw_reflection": {"calling": "dewdrop", "tier": CAPSTONE, "parent": &"dw_wet_footprints", "name": "Reflection",
		"text": "A hit from another Warden touching water on a Soaked nightmare in it is mirrored: half lands on the last nightmare in that water.",
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
