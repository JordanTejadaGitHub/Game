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
