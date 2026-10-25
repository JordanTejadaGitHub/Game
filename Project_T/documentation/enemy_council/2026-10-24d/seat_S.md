# Seat S (systems and code keeper): round 2026-10-24d, all 38 nightmares

**Verdict: feels good with fixes.** The code holds today's rules well: no damage types are read
(`enemy_data.gd:226-233`, `get_soothe_multiplier` returns 1 at `:400-402`), every Armoured kind has a shell plus a
cracked sheet, all 38 have their own SpriteFrames and sheet (no `tint` / `sprite_scale` anywhere: F3 passes), flyer
caps, the Pall's exclusions and the grounding fix are built as ruled. The failures are a **leaf-bite number the
standards and docs have wrong**, **two Kinds that don't match what the nightmare does**, **one boss with a second
damage reduction**, **stale text and doc tables**, and **one stacking heal that packs turn into a cliff**.

Checked: all 38 `.tres` (via roster.md, spot-opened), `enemy_data.gd`, `enemy.gd` (leaf cost, grounding, Gloamwing,
Pall, presence/mend/reveal), `enemy_spawner.gd`, `drift_shapes.gd`, `drift_roller.gd` (lead rules),
`drift_director.gd` (elites, shaping order, pot), `run_state.gd` (leak cap), `nightmare_info.gd`, the drift files
41 / 69 / 92 / 96, `tools/drift_generator.gd`, `animation/enemy/*.tres`, enemy_design.md, acts tables.

## Failures

| # | Nightmare | Std | What's wrong (file / field) | Fix (one meaning) | Owner |
|---|---|---|---|---|---|
| 1 | Act 1-3 bosses (8) | C1 | Code bites **6 / 8 / 10** (`enemy_spawner.gd:49` `boss_bite_leaves`, owner decision human run 53, balance_simulation.md:1971). standards.md C1, enemy_design.md:192, CLAUDE.md "Boss pools" and the comment at `enemy.gd:1885` still say 10 / 10 / 12 (or 8 / 10 / 12). | Code is right. Change C1, enemy_design.md:192, CLAUDE.md and the comment to 6 / 8 / 10. | Lead (standards, enemy_design.md); Main Merger (CLAUDE.md); Enemy Code (comment) |
| 2 | Night Mare, Hollow Oak x3 | C1 / E4 | `leaf_cost` 3 / 5 is never charged (laps and stays drain every 2 s, `enemy.gd:954-958`, `HEARTWOOD_DRAIN_EVERY` :83). But `get_leaf_cost()` returns it (`enemy.gd:1883-1886` skips the bite for `laps()` / `stays_at_heartwood`), so the hover panel prints "Leaves 3" / "Leaves 5" (`nightmare_info.gd:107`). | For a lapping or staying boss the panel shows "Drains 1 leaf / 2 s" instead of a number. | Main Merger (nightmare_info), Enemy Code (a `drains()` helper) |
| 3 | Whisper Swarm | B1, A1, E4 | One 180-HP body with no mechanic left (the x0.5 single-target rule was removed; `whisper_swarm.tres` has no split / followers). Kind Swarm, the title "Wardens that hit an area catch many at once", the intro "by the dozen" and the hint "hits every whisper at once" all describe something the code doesn't do. | Give it a real crowd: arrives as **8 Whispers** of ~22 HP (a new `whisper.tres` child as `followers`, `follower_spacing` 0.1, roll cost unchanged at ~180) so the text becomes true. If the owner won't add a child: Kind Plain and rewrite the three lines. | Enemy Code (data), Enemy Assets (a single-mote sheet) |
| 4 | Gravecrawler | B1 | Kind Hidden (`gravecrawler.tres` kind 2) but `hidden` is false: it is targetable all trip except the moment underground, and nothing "reveals" it. The Kind line "can't be targeted until a Warden reveals it" (`enemy_data.gd:26`) is false for it; its real answers are layered walls and Rootlight's lit tiles (`enemy.gd:3064`). | Kind Plain (like the Mire Hag, who also sinks), its burrow stays its own ability. | Enemy Code |
| 5 | The Huntsman | B2 | `pack_shield` 0.5 is a second damage reduction ("takes half damage while a hound is near"), which B2 forbids (the Whisper Swarm's x0.5 was cut for the same reason). | Owner call (below). Least change if it must go: hits on him while a hound is within 3 cells are **shared half and half with the nearest hound** (the Pall's rule, `PALL_SHARE`), so nothing is reduced. | Enemy Code |
| 6 | Hollow Stag | E4 / B2 | Tip 3 "Rain douses the ghost-fire in its antlers" is the old water weakness; nothing in code reads rain on it (no match for douse in `scripts/`). | Drop tip 3 (2 tips + its proverb rule moves to tip 2, or keep 2 tips only). | Enemy Code (text from the Lead) |
| 7 | Weeper (and in a pack) | C4 / A6 | Mends stack with no cap: each Weeper heals every nightmare within 1.5 cells 2%/s (`enemy.gd:3265-3267`, `heal()` :3451 adds). Weepers are packable (no loose trait), so a pack of 7-8 Weepers heals each member ~12-14%/s: a pack no crowd build can wipe. | A nightmare takes mending from **one** source at a time (the highest rate in reach), not the sum. | Enemy Code |
| 8 | enemy_design.md tables | B2, data | The boss table still has Resists / Weak-to columns (:172-186), the "each boss has one weakness" rule (:159-162), "Weakness spread" (:208-210), Oak weakness lines (:269, :276, :278), Stats table's Resists / Weak-to columns (:503-539), and the "Resistances" section's family tally (:378-495) are live-looking text. | Strike the columns and paragraphs; keep only status resistances and the dread shell. | Lead (enemy_design.md) |
| 9 | Stats table vs `.tres` | data | Doc vs data: Shade speed 100 / 102.4; **Husk leaves 2 / `leaf_cost` 1** (also acts_1_2.md:13, run_design.md:146 say 2; the `.tres` has been 1 since 18d3e766); Phantom 50 HP 70 / 60 HP 64; Night Hound 160 / 80 vs 200 / 76.8; Lantern Bearer 200 / 85 vs 250 / 70.4; Wraith 40 / 85 vs 50 / 70.4; Mourner speed 83 / 76.8; Sob 115 / 128; Shellbound "-6 per hit, soaks 100" vs 15 / 150; Hollow Stag speed 51 / 44.8; Mire Hag 55 / 38.4; Night Mare 2,000 / 3,430; Barrow King 16,000 / 14,400 (+1,600 shell). Bosses "Leaves 10 / 12". | Regenerate the Stats table from the `.tres` (the data is what plays). Husk's 1 vs 2 leaves is a real decision: Balancing picks. | Lead (doc); Balancing Discussion (Husk leaves) |
| 10 | CLAUDE.md | B2 | "Resistances (enemy_design.md): soothe x family (`resists` / `weak_to` ... x0.5 / x1.5)" and "Grey puff = resisted, sparkle = weak" in "Dreams and Wardens" describe the removed system. | Replace with: no damage types; dread shell, Pall share, status resistances. | Main Merger |

## Near-misses

- **Gloamwing after it drops** keeps Kind Flying and its "only Wardens that hit flyers can reach it" line on the
  hover card; `is_flying()` already returns false once `dropped` (`enemy.gd:2246`), `nightmare_info.gd` never reads
  it. Add "Down: walking" on the card. Main Merger.
- **Blight elites aren't seeded:** `_add_blight_elites` uses `candidates.shuffle()` (`drift_director.gd:772`), the
  global rng, so the Coming strip's preview and the drift place them differently (the comment at :616 admits it) and a
  replay of a seed differs. Use the drift's `rng`. Enemy Code.
- **Flyer elite hand-off** (`drift_shapes.gd:221-229`) moves the flag to a random walker, which in a Few and tough
  drift can be a Shade outside the tough lead (and outside TOUGH_LEAVES' book). Give it to the lead kind when the
  shape is Few and tough. Enemy Code.
- **Act 2 Few and tough and Single file always lead with Husks:** `heavy` is only on Husk (6), Barrow Wight (63),
  Ash Crawler (68), Shellbound (79) (`drift_roller.gd:570-573`). Drifts 26-62 have one possible lead, so the
  shape's test never varies there. Balancing call: `heavy` on the Lantern Bearer (250 HP, 36) or move the Wight's
  intro earlier.
- **Cheap leads of leak streams (C3):** Lurker (70 HP, `fast` + `small`, Hidden) and Dream Thief (90 HP, `fast`)
  can lead Fast / Swarm templates; a Dream Thief pack's Dew theft has no cap (`enemy_spawner.gd:811-815`, only
  leaves are capped). Suggest `drift_max` 10 for the Lurker and 6 for the Dream Thief, the Phantom's pattern.
  Balancing / Enemy Code.
- **Dream Thief "drops double Dew"**: there is no doubling now; it gets a pot share by `dew_reward` 6 vs a Shade's 3
  (`drift_director.gd:890`). True only against a Shade; say "a big share of the drift's {dew}" or drop it. Lead text.
- **Ability icons reuse Kind / status glyphs:** the Huntsman's "The Pack" and the Lamplighter's "Cold Light" use
  `&"hidden"`, the Mourning Mother's "Black Tears" (a heal) uses `&"damp"`, the Lamplighter's lanterns use
  `&"sapling"`. Players read them as Hidden / Soaked. Enemy Code, with Main Merger for new glyphs.
- **Kinds doc names the wrong revealers:** "Reveals Hidden (Brood Cap, Quaker)" (enemy_design.md:353); in data the
  tag is on Rootlight and Starcave (`role_line`), and reveals come from close Wardens, Marked appliers (Beacon,
  Lanternmoth) and Wisps (`enemy.gd:3404-3438`). Lead, with Seat W.
- **Remembering echoes leak at `leaf_cost` 5** (`enemy.gd:1883` sends `is_echo` to the plain path) while the boss
  they copy bit 6-10; a Night Mare echo laps and drains. Fine by "echoes leak normally", but the dossier should
  say 5. Main Merger.
- **"Big" lanes never fire for non-bosses:** `_is_big_for_lanes` keys on `sprite_scale >= 1.4` (`enemy.gd:2157`),
  no `.tres` sets it and every sheet is 64x64, so Barrow Wights walk at +-0.2 like Shades. Harmless today; if the
  Wight is meant to be big, key it on a tag. Enemy Code.
- **Stale comments:** `run_state.gd:273` "PACK_LEAVES (3)" and `drift_director.gd:783` "the 3-leaf pack cap"
  (it is 6, `drift_shapes.gd:39`); `enemy_data.gd:9` "bosses 5"; `enemy_data.gd:207` "Omens that add flyers still
  can (Moth Night)" (`cap_flyers` now catches them after the Omens, `drift_shapes.gd:137`). Enemy Code.
- **`tools/drift_generator.gd:16-25`** has no `NK` though acts_3_4.md:124 lists it; rerunning it on a table with
  Night Kites would fail. Add `"NK": ["night_kite", ""]`. Enemy Code.
- **Phone cost:** `_others_within` builds a filtered array with a lambda every presence tick (`enemy.gd:3445`) for
  each Weeper, Watcher and the Mourning Mother; and during the Moth Queen's Eclipse every eclipsed nightmare runs
  `_is_revealed` (25 cell lookups + every Marked Warden's `get_range_pixels()`) 10 times a second, up to
  `max_field_handheld` 110. Fine at today's counts; reuse one array and cache ranges per frame if a profile shows
  it. Enemy Code.

## Checked and fine (no action)
Intro drifts match acts tables (41 / 69 / 92 files hold 4 NK, 4 GW, 3 PL as written). Flyers: all route flyers
`flies_along_route`, only the Phantom straight, all `special`, caps 4/5/6 + a third + Phantom 4 after Omens
(`drift_shapes.gd:191-232`), never elites; grounding rises onto its own route, Waymark leg kept
(`enemy.gd:2319-2413`). Gloamwing drops at Soaked + Drowsy >= `drop_stacks` 3, not raised by Brimming (:2415-2420).
Pall skips bosses, elites and pack members (:2484-2488), never rolled into Few and tough (`drift_roller.gd:320-322`).
LOOSE_TRAITS keep the Night Hound, Sleepwalker, Gravecrawler, Mire Hag and flyers out of packs. Few and tough leads
are heavy non-splitters. Splitters and followers count in roll cost and leaves (`enemy_data.gd:355-379`) and in
pack weight. Every Armoured kind has `coat_*` + `cracked_frames`; no other kind has a shell. Every non-boss has a
hint. All art final by F3's test.

## Owner calls
1. **The Huntsman's half-damage pack shield** breaks "the dread shell is the only damage reduction". Keep it as a
   boss exception (it is visible: a ring to each hound), or change it to shared blows with the nearest hound (row 5)?
2. **The route rule vs two bosses:** the Hollow Stag knocks Thornwalls down for good and the Thorned Oak plants
   Thorn-Saplings that "bend the path" (`hollow_oak.tres` abilities). Both re-route the maze on their own, which the
   brief's owner rule forbids for "no enemy or card"; the Gravestones ruling was about cards. Exempt bosses, or
   redesign (Seat T's area)?
3. **Whisper Swarm:** make it a real crowd of small bodies (row 3) or demote it to Plain?
4. **Husk leaves:** 1 (data since the start) or 2 (every doc)?
