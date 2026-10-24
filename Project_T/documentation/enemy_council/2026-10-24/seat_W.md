# Seat W (Warden roster keeper): drift shapes, walking lanes, new flyers

## 1. Verdict
**Feels good with fixes.** Every one of the four starting families has a flying answer from its base Warden
up, and route flyers make every Warden along the maze count (unlike the Phantom). But the anti-air Wardens
the doc names as the answer (Groundroot / Earthbind, plus the Snag card) currently turn a route flyer into a
straight-line Phantom, and the Pall as written has no answer the starting families can aim. Fix those two
and the change is a net win for the roster.

## 2. What works (keep)
- **Flyer coverage by family** (all forms in `resource/tower/*.tres`; "can't hit flyers" is the
  `role_line` hard limit, checked by `tests/test_role_lines.gd:79-80`: TRAP attacks plus specials `brood`,
  `whirlpool`):

  | Family | Forms | Hit flyers | Can't | Tagged anti-air |
  |---|---|---|---|---|
  | Sporeling | 14 | 10 | Fairy Ring, Elf Circle, Brood Cap, Hatchery | none |
  | Firefly Jar | 14 | 14 | none | Lightning Fence |
  | Dewdrop | 14 | 12 | Undercurrent, Maelstrom | Cloudlet, Nimbus |
  | Bellflower | 14 | 14 (Dreamcatchers are support-shaped) | none | none |
  | Rootling (demo Grove) | 14 | 12 attackers (Rootlight / Starcave are support) | none | Groundroot, Earthbind |
  | Sprout, Bramble, Honeysuckle | | yes | | |

  No starting family is left without an answer: all four base Wardens and the Sprout hit flyers, and only
  six forms in the whole roster are ground-only. The demo's 2-branch families keep their base answer.
- **Route flyers, not straight flyers.** Because Night Kite / Gloamwing / Pall fly the route
  (`EnemyData.flies_along_route`, spawner `enemy_spawner.gd:137`), short-range pulses (Chime Stone,
  Bellflower, Rootling, Pinwheel / Windmill) and the maze length still matter against them. This is the
  right lesson from the Phantom.
- **Gloamwing gives control families a second answer.** Soaked (any Dewdrop form, Cloudlet / Nimbus rain)
  and Drowsy (Bellflower line, Bloomcap / Dreamshroom, Honeysuckle) bring it down into the maze, where
  Puddles' water, Spore Print's mushrooms and ground traps (Fairy Ring) reach it again. A control build
  converting a flyer into a walker is exactly "my choice visibly mattered".
- **Cards that gain a reason to exist:** Skyward Gaze (`dream_state.gd:4712`), Snag
  (`dream_batch_rules.gd:552-568`) once fixed (below), Flyer warning UI already reads `Trait.FLYING`.
- **Drift shapes spread the roster's love around.** Packs: Puffball, Sparkler / Starburst, Rain Lily,
  Monsoon, Bellflower pulses, Undercurrent / Maelstrom links, Fairy Ring / Elf Circle traps. Few and tough:
  Jetreed / Torrent (max-health share), Sunpetal / Midsummer beams, Lichenling / Old Lichen (breaks
  armour), Silver / Vesper Bell, Lanternmoth / Beacon (Exposed 10 stacks completes on few bodies),
  Dreamcatchers (Caught). Single file: Driftspore, Prism Jar, Hummingbird-type single targets, the maze
  Wardens. No Warden family loses on all three.
- **Walking lanes are harmless to the roster:** logic stays on the centre line (enemy_design.md "Walking
  lanes"), ±0.3 cell keeps a body inside its route tile, so Fairy Ring tiles, rubble and the whirlpool's
  radius read correctly; aim follows `get_visual_position()` (1fffbb01).

## 3. Problems, ranked

**P1. Grounding a route flyer makes it skip the maze.**
- *Player feels:* "I built Groundroot (or took Snag) to answer Night Kites, and now they fly straight to my
  Heartwood." The named counter becomes a trap, and leaks feel like the game cheated.
- *Cause:* `Enemy._rise_from_ground()` (`scripts/enemy/enemy.gd:2088-2094`) always sets
  `[current cell, endPath]`: written for Phantoms. `Enemy.ground()` (`enemy.gd:2047-2080`) also sets
  `passed_waymark = true`, so a grounded route flyer skips the stone leg, against the Flyers rule "route
  flyers take the route they spawned with, two legs if a stone stands". This already hits today's Crows
  (`resource/enemy/crow.tres:16`) under Groundroot (`branch_kit.gd:1198`) and Snag.
- *Fix:* if `enemy_data.flies_along_route`, rising resumes the route: `set_path(map.get_path_from(current
  cell, passed_waymark))` and keeps the real `passed_waymark` (set it only if the grounded cell is past the
  stone). Straight-line rise only for `is_through_walls()` flyers. Gloamwing's drop must reuse the walker
  path call, never `ground()`'s Waymark flag.
- *Owner:* Enemy Code.

**P2. The Pall has no aimable answer in the starting families, and it stacks with the dread shell.**
- *Player feels:* "My Wardens keep shooting the covered Husk for half damage and I can't tell them to shoot
  the cloth." The doc's counter is "target priority", but only Standing Stone and Moonstone have
  `has_target_priority` (both Pebbling, not a starting family). Default targeting is furthest along
  (`tower.gd:4078`, `get_remaining_distance`); a Pall sitting on its walker ties with it, so who gets shot is
  arbitrary.
- *Also:* half damage multiplies before the shell (CLAUDE.md: multipliers "then the blight coat"). Teaching
  drift 92 is "3 Palls over a line of 12 Husks" (Armoured): a 10-damage Poisoned tick becomes 5, then the
  flat shell takes most of it. Spore Print's ticks, Firefly's Charged bolts and Bellflower's small pulse
  hits all count as hits against the shell, so chip builds go near zero on that drift: a build dead, not
  weaker.
- *Fix (one meaning):* (a) while covering, the Pall is **in front**: targeting picks it before its walker
  (count it 0.5 cell further along); area hits reach both. (b) the half applies **after** the shell, to
  health only. (c) teaching drift 92 covers Shades or Wraiths, not Husks. (d) never covers a boss or the
  Hollow Oak's escort; never rolled into a Few and tough drift (Deeply Blighted at half damage there is
  a Focus-line wall).
- *Owner:* Enemy Code (rules), Main Merger (drift 92 row), Balancing Discussion (numbers).

**P3. Calling ground setups ignore flyers.** Not a bug, but the owner should know what the player feels.
`class_kit.index_of()` returns -1 for every flyer (`scripts/combat/class_kit.gd:364-366`), so Puddles' water
and evolutions (`puddles.gd:858, 873, 1418` "Flyers are never in water"), Spore Print's mushrooms and doses
(`spore_print.gd:1020, 1036, 1679`) and Keeping Time's primes (`keeping_time.gd:1086, 1123`) never touch a
Night Kite or Pall. Lantern Light is fine: Lit is by distance (`firefly_lights.gd:906-919`). With the
6-flyer cap that is a weaker drift, not a dead one, and Gloamwing gives Puddles / Spore Print a way back.
- *Fix:* keep the cap at 6 (Phantoms 4 within it) and add that **flyers are at most a third of a rolled
  drift's arrivals** outside a Special lead, so a Puddles or Spore Print board is tested, not idle.
- *Owner:* Enemy Code (roller), Balancing Discussion (the share).

**P4. Gloamwing's Soaked drop is one hit; Drowsy needs three.** Soaked is a single state, not a stack
(`enemy_statuses.gd:18, 37`), so one Dewdrop or Rain Lily splash at the route's start drops every Gloamwing
for the whole maze, while Bellflower needs three accepted Drowsy. Dewdrop shining here is fine; one cheap
splash erasing the flyer is not a test.
- *Fix:* drop at **Soaked for 2 s** (or 2 Soaked hits) or 3 Drowsy; say it on the card as a fact
  ("lands when Soaked 2 s or 3 Drowsy").
- *Owner:* Enemy Code, Balancing Discussion.

**P5. Ground-only forms against flyers.** The six "can't hit flyers" forms are concentrated in Sporeling
(two whole branch lines: Fairy Ring → Elf Circle, Brood Cap → Hatchery) and Dewdrop (Undercurrent →
Maelstrom). A Sporeling offer of exactly Fairy Ring + Brood Cap would leave base Sporelings as the family's
only anti-air; with the second family at drift 10 the run is fine by drift 41, but the Phase 1 smart draw
(tower_design.md "per-run offer", anti-air 83%) should never offer that pair. Under a Pall these forms deal
half damage and can never remove the cloth: acceptable with the cap and P2(a).
- *Owner:* Roguelite Code (smart draw rule), Balancing Discussion.

**P6. Maelstrom / Undercurrent on Few and tough.** Their value is the link (`special_params link_share`
0.25 / 0.45 within radius 1.5 / 2) between bodies in the whirlpool. Few and tough's 3–5 evenly spaced
Deeply Blighted rarely put two bodies in the radius, so these fall to their small base dps, likely under the
60–70% gate.
- *Fix:* Balancing sims a Maelstrom-led board on Few and tough; if under 60%, let the link also share to the
  whirlpool's own target at a floor (e.g. 15% bonus when alone). Tower Code's call.
- *Owner:* Balancing Code (sim), Tower Code.

**P7. Walking lanes at range edges (minor).** A body drawn 19 px inside a range ring may go unshot (or shot
while drawn outside). With ranges of 1.5+ cells this is rare; only short-range "hits all around it" forms
(Rampart, Bastion, Pinwheel, Windmill) and Chime Stone notice. Keep ±0.3; draw range rings slightly soft.
Owner: Enemy Assets / Main Merger, only if playtests notice.

## 4. Builds or Wardens that shine / suffer
- **Shine:** Cloudlet / Nimbus (rain on flyers, Soaked drops Gloamwings); Lightning Fence; Bellflower pulse
  line (hits flyers, Drowsy drops Gloamwings, area hits both Pall and walker); Lanternmoth / Beacon /
  Silver Bell / Vesper Bell (long-range single target to pick off Kites); Puffball / Starburst / Sparkler on
  Packs; Jetreed / Torrent, Lichenling, Sunpetal on Few and tough; Snag and Skyward Gaze once P1 is fixed;
  Puddles once Gloamwings walk into its water.
- **Suffer:** Groundroot / Earthbind and Snag (trap until P1); Fairy Ring / Elf Circle, Brood Cap /
  Hatchery, Undercurrent / Maelstrom against flyers and Palls; Maelstrom on Few and tough; Spore Print and
  Puddles ground setups on flyer-heavy drifts; every chip build on drift 92 as written.
- **No Warden loses its reason to exist** after the fixes; every family still answers each new flyer.

## 5. Open questions for the owner
1. Pall: should it be **targeted first while covering** (P2a), or should target priority be the intended
   answer (then the starting families need a priority button on one form each)?
2. Gloamwing: one Soaked hit, or Soaked for 2 s, to land it?
3. Flyer share: keep only the 6-flyer cap, or also cap flyers at a third of a rolled drift (P3)?
