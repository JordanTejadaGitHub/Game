# Seat W (Warden roster keeper), round 2026-10-24d: all 38 nightmares

**Verdict: feels good with fixes.** Every starting family answers every flyer from its base Warden up, and most
Kinds point at real Warden tags. Three Kind answers are not true in code, though: the Gravecrawler's Hidden, the
Whisper Swarm's Swarm, and Fast's "Soaked". Two support kinds also become a one-family wall when they pack: Ash
Crawler packs or leads against Sporeling, and mutual Weeper healing against single-target boards. Bellflower has no
reveal form at all.

## Flyers vs "Can't hit flyers" (the count the lead asked for)

Forms that can't hit flyers, out of 14 each (base, 5 branches and finals, hidden, Ascended): **Sporeling 4** (Fairy
Ring / Elf Circle, the hidden line; Brood Cap / Hatchery, expansion), **Dewdrop 2** (Undercurrent / Maelstrom,
expansion), **Firefly Jar 0**, **Bellflower 0**. All four base Wardens hit flyers. Projectiles, pulses and path
clouds don't filter flyers (`path_cloud.gd` has no `is_flying` check; `tower.gd` targeting only widens range for them,
5963). In the demo (original branches, no draw) only the hidden Fairy Ring / Elf Circle can't. No starting family is
left without an answer to any flyer:
- **Crow / Night Kite:** route flyers, so every flyer-hitting Warden along the maze gets its turn. Fine.
- **Phantom:** the base Wardens near the Heartwood answer it. Lightning Fence (Firefly) is the only line that
  touches it in passing. Fine.
- **Gloamwing:** Dewdrop (Soaked) and Bellflower (Drowsy every 2nd ring; Sporeling's Bloomcap / Dreamshroom too)
  bring it down. Firefly shoots it. Once it is down, the six can't-hit forms work again. This is the best "gift for
  control" in the roster.
- **Pall:** shared blows reach it from any Warden that hits the walker it covers (`enemy.gd` 3583-3588, after the
  shell). Fairy Ring and Undercurrent keep half their value. Only a Pall with nothing to cover is out of their reach.
  Fine.
- **Moth Queen:** route flyer. Fine. Her Eclipse is a reveal question (see Bellflower below).

## Failures

| Nightmare | Standard | What's wrong | Fix (one meaning) | Owner |
|---|---|---|---|---|
| **Gravecrawler** | B1, A2 | Its Kind is Hidden. The badge says "can't be targeted until a Warden reveals it" (`enemy_data.gd` 26), and the Kinds table lists Reveals Hidden as the answer. But revealing does nothing to it: `_is_revealed` only covers `enemy_data.hidden` / the Eclipse (`enemy.gd` 3239), and `_try_burrow` only stops on Rootlight's lit cells or Rampart stone (3064, 3072). Brood Cap, Quaker, Lanternmoth, Beacon and Morning Fog all promise an answer they don't give. No starting family has a form that stops the burrow. | Make the Kind true: a Gravecrawler inside the range of a Warden that reveals (`marker_towers`, Reveals Hidden forms, Morning Fog's veil) can't start a burrow, like a lit cell. This gives Firefly (Lanternmoth), Sporeling (Brood Cap) and Dewdrop (Morning Fog) an answer. The maze answer (two walls deep) stays. | Enemy Code (+ Tower Code for the reveal list) |
| **Whisper Swarm** | B1, A1, D2 | It is one 180-health body (`whisper_swarm.tres`: no split, no followers). Once the ×0.5 single-target rule was removed, nothing makes area hits better against it. Its badge ("a crowd of small bodies; area attacks catch them all"), its trait_text and its hint ("hits every whisper at once") are all false. It is a Shade with more health. `acts_3_4.md` line 30 still says "single-target damage halved". | Give it real bodies: spawn as **5 motes of 36 health** in one tight cluster (Dew split across them; it counts as one arrival for the flyer and pack math), drawn as one cloud. Or, if the owner doesn't want that, make it Plain and retire it from rolls. | Enemy Code, Enemy Assets (owner call below) |
| **Fast Kind** (Night Hound, Sleepwalker) | B1 | The Kinds table answers Fast with "slows and holds (**Soaked**, Drowsy, Rooted)", but Soaked has no slow (`enemy_statuses.gd` 8: "no slow"). On the four starting families, a slow or hold comes only from Bellflower's Drowsy, Sporeling's Bloomcap line and Dewdrop's Frostfern / Tidecaller. Firefly Jar has none. The badge line "slows and holds keep it in reach" sends a Firefly or base-Dewdrop player looking for a tag they don't have, while corners (which every family has) are the real answer. | Kind line: "Fast: it outruns a thin maze; corners, slows and holds keep it in reach." Drop Soaked from the enemy_design.md Kinds table. | Enemy Code (KIND_LINES), Enemy types design chat (doc) |
| **Ash Crawler** | D2, D1, C3 | It is tagged `heavy` with trait NONE, so it can (a) lead Single file, (b) lead Few and tough as 3-5 Deeply Blighted (`drift_roller.gd` 570-573) and (c) fill a one-kind pack half a cell apart (`drift_shapes.gd` 310). Its ash strips Poisoned from every *other* nightmare on its cells, other Ash Crawlers included (`enemy.gd` 3268-3272). In all three shapes, every body but the front one walks on ash. That turns off a Sporeling board's main damage and Spore Print's mushroom doses for the whole drift: a dead build, rolled from the seed. Its roster counter is "Pebbling line", which no starting family has. | Make it a loose kind: never packed and never a Single file / Few and tough lead (the same rule as the Pall's Few and tough exclusion). It keeps `special` and stays a share of Streams. Fix its roster Counter to "dispel it early; its own {spored} stays on it" (true: `other != self`). | Enemy Code |
| **Weeper** | D2, A6 | It is packable (trait NONE). In a pack of 6-8 half a cell apart, each Weeper is healed by every other one within 1.5 cells: 5-7 × 2% = **10-14% of max health a second** on every member (`enemy.gd` 3265-3267, `_others_within` excludes only itself). Single-target boards (Sporeling base / Driftspore, Firefly base / Lanternmoth) can't break that. Only area burst, Hushbell (1 of 5 Bellflower branches) or Morning Fog's veil can. No starting family can pick a target (`has_target_priority` is only on Standing Stone / Moonstone). | Menders don't mend menders: a Weeper's mending skips other nightmares with `mend_radius > 0`. Packs of Weepers stay possible and read as "a pack that heals other packs". Seat S should confirm how often Weeper packs roll at 86+. | Enemy Code |

## Near-misses

- **Bellflower has no reveal form** among its 14 (no `detection` counter tag anywhere in the song line). Its only
  answer to the Lurker (52) and the Moth Queen's Eclipse is the 1.5-cell "Warden beside it" rule
  (`enemy.gd` 541). That works because the base pulse has range 2, but the smart draw's detection weight ×3
  (`dream_state.gd` 1522) has nothing to offer a Bellflower-first run. It's acceptable while a second family comes
  at drift 10. Watch it if Lurker packs prove leaky in Bellflower + Firefly-less runs.
- **Dewdrop's reveal is invisible to the smart draw:** only the final, Morning Fog, has `detection`; its branch,
  Mistveil, has no tag, and the draw reads branches only (`dream_state.gd` 1493). Tower Code: tag Mistveil
  `detection`, or have the draw read a branch's finals.
- **Status testers fall unevenly, and most of them land in act 3.** Bellflower: the Drowned One (61, Drowsy immune),
  Barrow Wight (63, Drowsy ×0.5), Watcher (66, Drowsy immune, wakes others), and the Barrow King's shrug in the act 3
  pool. That's three everyday kinds inside 6 drifts. Sporeling: Ash Crawler (68), shells, the shrug. Firefly Jar has
  almost no tester: a Static bolt is one big hit that passes the dread shell, and the Drowned One is a gift. Firefly is
  the "answers everything" risk of D2. Balancing should compare leaves lost by first family in act 3.
- **Armoured from the base Warden up:** no starting base Warden is `heavy`. Firefly answers through bolts. Sporeling's
  only heavy form is Deliquescent (an expansion final), and its armour breaker is Lichenling (expansion). In the demo,
  Sporeling and Bellflower have **no** tagged answer to the Husk (6, act 1, and the near-only Single file lead in an
  act where Single file is 89%). The shell only absorbs damage (`enemy.gd` 3569), so this is never hopeless.
  Balancing: measure Sporeling-only and Bellflower-only dispel times on act 1 Husk-led Single file drifts.
- **Watcher:** Hushbell's silence stops its waking (`enemy.gd` 3257), and the Weeper's card says the same of
  healing ("A {silenced} Weeper can't heal"), but the Watcher's card doesn't. As a fact line: "A {silenced} Watcher
  wakes no one." Its roster row still says "resists song" (an old damage type).
- **"Dispel it first"** (Watcher, Weeper, Lantern Bearer, Huntsman) asks for a target choice that no starting-family
  Warden can make (see the Weeper row). The answers that do exist are area hits and silence. Wording seat: either
  keep the line as a goal or word it as the fact.
- **Gloamwing's intro** says "a splash and two tolls are enough". A "Toll" is Keeping Time's Calling term. A plain
  Bellflower gives Drowsy every 2nd ring, so it needs four rings. Wording seat: "a splash and two {drowsy}".
- **Gloamwing after it drops** still shows the Flying badge ("only Wardens that hit flyers can reach it"), which is
  wrong once it walks. A small Enemy Code / UI fix: show Plain when it is down.
- **Dream Thief** (speed 120, tagged `fast`) is Plain while the Sleepwalker (110) is Fast. That's fine under "its own
  ability decides", but its hint, "Fast single hits catch it", leans on single target, and Bellflower has none until
  Dreamcatcher / Silver Bell.
- **Barrow King** clears Static "without a bolt" every 10 s. Firefly bolts at 8 stacks on bosses (about 5 s for one
  Jar), so this is fine. Sporeling's Poisoned ramp loses the most to it.

## Wardens that shine / suffer

Shine: Lanternmoth / Beacon (Lurker, Eclipse, and the Gravecrawler once fixed), Hushbell / Silence (Watcher, Weeper,
bosses), Bellflower and Dewdrop bases (Gloamwing), Stormcap / Thunderhead (the Drowned One, swarms), Cloudlet / Nimbus
(flyers), Morning Fog (Weeper, Lurker).
Suffer: Fairy Ring / Elf Circle (the Phantom and every route flyer; Gloamwing is their one comeback), Undercurrent /
Maelstrom (likewise), Sporemother / Puffball (Ash Crawler packs, until fixed), Frostfern / Hoarfrost freeze (Held
immunes: Wight, King, Drowned One, Phantom, Moth Queen; their heavy hit still lands). No Warden loses its reason to
exist.

## Owner calls

1. **Whisper Swarm:** real bodies (5 motes, area-answerable) or retire it to Plain. W recommends bodies: it is the
   only Swarm that arrives as a crowd *before* anything breaks.
2. **Gravecrawler:** keep it Hidden and make reveal stop the burrow (W's pick: it gives three starting families an
   answer), or make it Plain and let the maze be its only answer.
3. **Bellflower and reveal:** is the adjacency rule enough, or should one Bellflower branch (e.g. Hushbell: "a
   silenced nightmare can't hide") count as `detection`?
