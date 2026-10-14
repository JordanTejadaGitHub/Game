# Heartwood's Gifts (experiment/spire-difficulty)

Owner: design hub (story chat). Replaces the per-rest "rest choices" (Rest / Tend / Dream) of
`spire_difficulty.md` Phase 3 (user, 2026-10-02: *"don't want it to be exactly like Slay the Spire"*;
*"I do like the gift options that change the map after an act. We need more options though"*).

## The rule

- **When:** once per act break: the rests after the bosses at 25, 50 and 75 (3 gifts a run). After the
  Dream and the family pick, before the Omen.
- **The offer:** 3 gifts drawn from the pool below, **at least 2 that change the map**. **Every gift gives something** (user, 2026-10-06: "not have any that just only places trees and logs, everything would give buffs or more resources"): a map gift always comes with a buff or a resource, never terrain alone. Never the same
  gift twice in a run. Pick 1, or let them pass for a small Dew sum (like a Dream).
- **Placing:** map gifts are placed on the gift screen itself, with a ghost preview: the route mist shows the
  new route, the "+N path" tag updates, and invalid cells are refused exactly like Warden placement (never
  closing the route, never on the start or the Heartwood glade's inner ring, never on a Warden). Esc goes
  back to the three cards.
  **Three ways out of placing** (user, 2026-10-07): **Undo / right-click** takes back the last piece (a line's
  start point, a chain's last tree), and when nothing is picked it does nothing, so you're never kicked out by
  accident. A **"Clear"** button empties what you've picked and keeps you placing the same gift. **Back** (and Esc)
  drops the placement and returns to the three gift cards, with nothing spent. **Plant it** commits: the gift is
  placed and taken, and there's no going back to the choice. Plant it stays greyed until the placement is valid
  (enough pieces, route open).
  **Length feedback** (user, 2026-10-07: "no feedback on the log when it's past the limit"): for line and chain
  gifts, the ghost shows the pieces that fit as valid, plus a red "too far" stretch from the last fitting piece
  to the pointer. A tag at the pointer reads the count against the limit ("4 / 4 · max"; "1 / 2 · 1 more" when
  too short). A click past the limit plants up to the max, it isn't refused. A refused piece (blocked, closes
  the route) is red on its own cell, with the reason in the tag.
  **Half cells, like Wardens** (user, 2026-10-07: "should be going by half a cells like wardens"): every placed
  piece (a tree, a log segment, a stone, a stump, a pond, a well) takes a Warden's footprint (2×2 halves) and snaps
  to the half grid with the same ghost and grid lines as Warden placement; a piece one half off a Warden is fine as
  long as the route stays open (nightmares fit one-half gaps). "Adjacent" / "straight" / "connected" are measured
  in pieces, so a ridge or log reads the same as before. Mire and Heartwood Roots pick route halves (the cells the
  drawn route covers). Placing a piece plays the Warden build sound and its plant pop; a refused piece plays
  `build_rejected`.
- **Why it's ours, not Slay the Spire's:** every gift is about the forest and the maze: terrain, routes,
  living ground that feeds Wardens. No heal, no flat upgrade.
- **Demo:** off (the demo stays on main's rules).

## The pool (18)

### Shape the land (route and space)
| Gift | What it does |
|---|---|
| **Sow a Ridge** | Draw a ridge of 3–5 Withered Trees, cell by cell (adjacent cells). **Sheltered:** Wardens touching the ridge deal +10% damage. Each of its trees gives **+2 Seeds** when tended (instead of 1). Clearable at the normal cost (the bonus goes with the tree). |
| **Fallen Giant** | Lay a fallen log 2–4 cells long, straight, where you choose; it can't be cleared this run. **Lookout:** attacking Wardens touching the log get +15% crit chance. (2026-10-06: was +0.5 range and a 15% slow, which overlapped Moonwell and Mire.) |
| **Glade** | Clear **up to 5 obstacles of your choice**, free; each still counts as tended (+1 Seed). Pick them one by one on the gift screen (gold outline + ×, click again to unselect; counter "3 of 5 · −6 path"; the route mist previews live); "Clear them" confirms. (Revised 2026-10-03, user: the radius version "didn't feel right and was unintuitive"; as built 3ab8abee.) |
| **Shift the Stones** | Move up to 3 obstacles to new empty cells. Each one moved pays **+30 Dew × act**. (The fertile half-price spot was dropped 2026-10-06: it overlapped Ancient Stump.) |
| **Mire** | Pick 3 connected path cells: the ground turns to bog, and nightmares move 20% slower there. |

### Living ground (terrain that feeds Wardens)
| Gift | What it does |
|---|---|
| **Spring** | A 2×2 pond where you choose (unbuildable). Water Wardens next to it deal +20%, and Soaked lasts 1 s longer on nightmares within 2 cells. |
| **Mushroom Ring** | A ring of toadstools on a 3×3 patch. Spore Wardens planted touching it get +2 Poisoned cap. |
| **Lightning Tree** | A dead tree you place (an obstacle). Charged bolts within 2 cells of it deal +25%. |
| **Moonwell** | A lit stone cell (unbuildable). Wardens within 1 cell get +1 range. |
| **Bell Stone** | A singing stone. Song Wardens within 1 cell pulse 15% faster. |
| **Ancient Stump** | 3 stumps you place: a Warden planted on a stump gets a free rank, banked: the player picks its focus (2026-10-07: granted ranks are banked, never auto-applied). |

### The nightmares' way
| Gift | What it does |
|---|---|
| **Heartwood Roots** | Roots grow over the last 4 path cells before the Heartwood: nightmares there take +15% damage. |
| **Thick Mist** | For the next act, nightmares leave the start mist 25% further apart. |
| **Bramble Verge** | Thornwalls grow into **Bramble for free** this run (no Dew; Bramble unlocked if it wasn't), and nightmares touching a Bramble gain +1 Drowsy cap. (2026-10-06: was "Thornwalls cost half", which overlapped the Weathered Walls card.) |

### Heartwood and kin
| Gift | What it does |
|---|---|
| **Old Kin** | One Kinship you choose jumps a stage, and new bonds start one stage up for the next act. |
| **Shifting Mist** | The start mist moves. 3 spots on the island's rim are offered (the MapLayout rules: on the rim, far enough from the Heartwood), each previewed with its route mist and path length; pick one, or keep the old start. Nightmares arrive from there for the rest of the run, so your maze faces a new way. Bridge and mist move with it. **Fresh ground:** this act's Dew pots are +10%. (Replaces Deeper Glade, 2026-10-04, user: "seems useless".) |
| **Waking Root** | The next form you unlock on the Remember screen costs 1 less Dreamlight. |
| **Memory Seed** | Choose a Warden: this act, selling and replanting it keeps its ranks and Kinship age (move it freely at rests). |

## Notes for the code chats
- New terrain uses existing systems where it can: ponds and logs (Environment's features), obstacles
  (`ObstacleData`), path modifiers via `MapGenerator` (route rules unchanged).
- New art: Lightning Tree, Moonwell, Bell Stone, Mushroom Ring, Heartwood Roots, bog path, Ancient Stump
  (Environment Assets; Heartwood 32, the act's sheets).
- Everything saved in the run save. Each gift is a card on the gift screen (Moonlit Thread), with an
  animated mini-scene like the placement Dream cards.
- Numbers are starting points; Balancing Discussion tunes them.

## Overlap check (2026-10-06, user: "isn't there a gift that increases range, check all the other gifts so they don't overlap")
Each gift now owns one kind of payoff:
| Payoff | Gift |
|---|---|
| range | Moonwell only |
| damage near terrain | Sow a Ridge (any Warden, +10%), Spring (water Wardens), Heartwood Roots (damage taken, at the end of the path) |
| crit | Fallen Giant (Lookout) |
| slow on the path | Mire only |
| status strength | Mushroom Ring (Poisoned cap), Lightning Tree (Charged bolts), Bramble Verge (Drowsy cap) |
| attack speed | Bell Stone (song Wardens) |
| a head start on a Warden | Ancient Stump (a free banked rank) |
| Dew | Shift the Stones (per stone), Shifting Mist (the act's pots) |
| clears / Seeds | Glade (5 free clears), Sow a Ridge (+2 Seeds a tree) |
| arrival pacing | Thick Mist |
| Dreamlight / growth | Waking Root, Bramble Verge (free Bramble) |
| Kinships | Old Kin (jumps a stage), Memory Seed (keeps age when moved) |
Cards vs gifts: no gift repeats a Dream card's effect (Weathered Walls owns cheap Thornwalls).

## Gifts as landmarks (approved by the user 2026-10-13; replaces the pool table above where they differ)
User: *"gifts feel whatever right now."* Why: a gift comes after a boss, three times a run, yet most give a small
bonus to the two or three Wardens touching one cell (+10% damage, +15% crit, +1 range on four sides), and several
were left behind by the status rework (+2 Poisoned when the cap is 32, +1 Drowsy when it is 20, Soaked +1 s). A
Dream card taken at any rest does more.

**Idea: a gift is a landmark.** It is big, it does something on its own, it defines a part of the map to build
around, and it grows.
1. **Each landmark acts by itself**, not only as a bonus to neighbours: the Spring Soaks what walks past, the Bell
   Stone rings, the Lightning Tree strikes.
2. **A zone, not a cell:** effects reach 2–3 cells, shown as a standing glow on the ground, so a whole corner of the
   maze is built around it.
3. **Landmarks grow:** at every later act break each landmark you own grows one step (II, III): about +50% of its
   numbers and a bigger look. The act 1 gift matters most by act 4.
4. **The offer is three kinds:** one that reshapes the land, one landmark that fits a family you own (never one for a
   family you lack), one boon for the run.
5. **It is an event:** the Heartwood's roots run across the map to the spot, the landmark rises, the camera follows,
   it has its own sound; at each rest the report says what it did ("Spring: Soaked 212 nightmares").

| Gift | Now | Proposed (step I; numbers for Balancing) |
|---|---|---|
| **Spring** | Water Wardens touching +20%; Soaked +1 s nearby | A pond that **Soaks every nightmare passing within 2 cells** (2 stacks a second). Water Wardens touching it deal 40% more. |
| **Lightning Tree** | Bolts within 2 cells +25% | **Every Charged bolt within 3 cells strikes twice** (the second at half), and the tree throws a bolt of its own every 6 s. |
| **Bell Stone** | Song Wardens touching pulse 15% faster | **Rings every 5 s: nightmares within 3 cells gain 4 Drowsy.** Song Wardens touching it pulse 30% faster. |
| **Mushroom Ring** | Spore Wardens touching: +2 Poisoned cap | **Nightmares crossing the ring are Poisoned** (6 stacks). Spore Wardens touching it can stack half again as much. |
| **Moonwell** | Wardens on its 4 sides +1 range | **Wardens within 2 cells get +1.5 range and see Hidden nightmares.** |
| **Heartwood Roots** | Last 4 path cells: +15% damage taken | Last 6 cells: **nightmares are Rooted for 1 s on entering and take 30% more damage** there. |
| **Sow a Ridge** | 3–5 trees; touching Wardens +10% | 4–7 trees; **touching Wardens deal 30% more**; its trees pay 2 Seeds when cleared. |
| **Fallen Giant** | Log 2–4; touching Wardens +15% crit | Log 3–5 that nothing can trample or burrow under; **touching Wardens +30% crit chance and crits hit harder**. |
| **Mire** | 3 path cells, 20% slower | **5 path cells, 35% slower**, and Rooted lasts twice as long in it. |
| **Reshape** (Glade + Shift the Stones, merged) | 5 free clears / move 3 for Dew | **Move or clear up to 6 obstacles; each pays 30 Dew × the act.** |
| **Elder Stumps** (Ancient Stump) | 3 stumps: 1 free rank each | 3 stumps: a Warden planted on one gets **2 free ranks**. |
| **Shifting Mist** | New start; +10% Dew this act | New start; **+25% Dew this act**. |
| **Bramble Verge** | Free Bramble growth; +1 Drowsy cap | Free Bramble growth; **Brambles make nightmares Drowsy twice as fast**. |
| **Old Kin** | One bond +1 stage | Keep. |
| **Memory Seed** | One Warden keeps ranks when moved, this act | **Any Warden** keeps its ranks and bond when moved, this act. |
| **Waking Root** | Next unlock costs 1 less Dreamlight | **The next form you unlock is free**, and +1 Dreamlight. |
| **Thick Mist** | Nightmares arrive 25% further apart for an act | **Retire** (nothing to see or build around). |
Control stays bounded: the Bell Stone and Roots don't stack with themselves, bosses take half.

**Build order and owners (approved 2026-10-13).** Roguelite Code first (the pool, kinds, growth steps, ids and a
short API note at the end of this file); then in parallel: Tower Code (the effects in `gift_ground.gd`),
Environment Code (placing, zones, drawing, the arrival), Environment Assets (art in three growth steps), Main Merger
(the gift screen, card scenes, rest report lines). Sound Code adds the arrival and the landmark sounds after.
Balancing sets the final numbers when sims are back; until then the table's numbers stand.

## API for the gift code (Roguelite Code, 2026-10-13; `scripts/run/heartwood_gifts.gd` is the one source)
Read the numbers from `HeartwoodGifts`; never copy them. `HeartwoodGifts.find(node)` gives the run's gifts node.

**Ids, kinds, families, placing**
| Id | Name | Kind | Family | `place` / `size` |
|---|---|---|---|---|
| `sow_ridge` | Sow a Ridge | land | any | chain, 4–7 |
| `fallen_giant` | Fallen Giant | land | any | line, 3–5 |
| `mire` | Mire | land | any | path, 5 |
| `reshape` | Reshape | land | any | **reshape**, 6 (new mode: move or clear; placement `from` / `to` for the moved, `cells` for the cleared) |
| `ancient_stump` | Elder Stumps | land | any | cells, 3 |
| `shifting_mist` | Shifting Mist | land | any | rim, 3 |
| `spring` | Spring | landmark | `dewdrop` | area 2×2 |
| `lightning_tree` | Lightning Tree | landmark | `firefly_jar` | cell |
| `bell_stone` | Bell Stone | landmark | `bellflower` | cell |
| `mushroom_ring` | Mushroom Ring | landmark | `sporeling` | area 3×3 |
| `moonwell` | Moonwell | landmark | any | cell |
| `heartwood_roots` | Heartwood Roots | landmark | any | none (the path's last cells) |
| `bramble_verge` | Bramble Verge | boon | any | none |
| `old_kin` | Old Kin | boon | any | kinship |
| `memory_seed` | Memory Seed | boon | any | none (was a Warden pick: now every Warden) |
| `waking_root` | Waking Root | boon | any | none |
Retired, still in `POOL` with `retired = true` so saved runs load and their effects keep working: `glade`,
`shift_stones`, `thick_mist`. Keep their registered effects.

**The offer:** `draw(act)` gives one gift of each kind, in the order land, landmark, boon. `can_offer(id)` is the rule:
it has a registered effect, isn't retired, wasn't taken this run, and a landmark's family is the player's (or "any").
A kind with nothing to offer hands its slot to another kind. A gift only enters the offer once its effect is
registered (`HeartwoodGifts.register(id, callable)`), so **`reshape` is not offered until its effect and placer exist**.

**Numbers by step** (`HeartwoodGifts.stat(id, key, step)`; for the player's gift at the step it has reached:
`gifts.value(id, key)`; `gifts.step_of(id)` is 1–3, 0 = not taken). Landmarks grow; the rest have one value.
| Id | Key | I | II | III |
|---|---|---|---|---|
| `spring` | `soak_stacks_per_second` | 2 | 3 | 4 |
| `spring` | `water_damage` | 0.40 | 0.60 | 0.80 |
| `lightning_tree` | `second_strike_share` | 0.50 | 0.75 | 1.00 |
| `lightning_tree` | `bolt_every` (s) | 6 | 4.5 | 3 |
| `bell_stone` | `drowsy_stacks` | 4 | 6 | 8 |
| `bell_stone` | `song_pulse_speed` | 0.30 | 0.45 | 0.60 |
| `bell_stone` | `ring_every` (s), `boss_share` | 5, 0.5 | same | same |
| `mushroom_ring` | `spored_stacks` | 6 | 9 | 12 |
| `mushroom_ring` | `spore_cap_share` | 0.50 | 0.75 | 1.00 |
| `moonwell` | `range` | 1.5 | 2.25 | 3.0 |
| `moonwell` | `reveals_hidden` | 1 | 1 | 1 |
| `heartwood_roots` | `path_cells` | 6 | 8 | 10 |
| `heartwood_roots` | `damage_taken` | 0.30 | 0.45 | 0.60 |
| `heartwood_roots` | `root_time` (s), `boss_share` | 1.0, 0.5 | same | same |
One value: `sow_ridge` `damage` 0.30, `tree_seeds` 2 · `fallen_giant` `crit_chance` 0.30, `crit_damage` 0.25 ·
`mire` `slow` 0.35, `rooted_multiplier` 2 · `reshape` `dew_per_obstacle` 60 (× the act; paid here, in `_payoff`) ·
`ancient_stump` `free_ranks` 2 · `shifting_mist` `dew` 0.25 (applied here, `get_dew_pot_multiplier`) ·
`bramble_verge` `drowsy_rate` 2 · `waking_root` `free_unlocks` 1, `dreamlight` 1 (applied in `DreamState`).
`crit_damage` 0.25 is my starting number: the table says only "crits hit harder".

**Zone radius** (`HeartwoodGifts.zone_cells(id)`, cells from the gift's edge; the standing glow is this big):
`spring` 2 · `lightning_tree` 3 · `bell_stone` 3 · `moonwell` 2 · `mushroom_ring` 0 (its own 3×3 patch) ·
`heartwood_roots` 0 (its path cells). The radius does not grow with the step.

**Signals** (on the gifts node)
- `gift_placed(id, placement, step)`: a gift was taken and applied; `step` is 1. (`gift_taken(id, placement)` still fires.)
- `gift_grew(id, step, placement)`: a landmark gained a step. It fires at each act break after the one the gift was
  taken at, before that break's offer, up to step III. Rebuild your numbers and the look from `step`.
- The registered effect callable also gets `placement["step"]` (and `placement["restoring"]` on a resumed run), so a
  resumed run rebuilds a landmark at the step it had. The step is saved with the gift's record.

**Who does what next:** Tower Code: the effects in `gift_ground.gd` from the numbers above (Memory Seed now covers every
Warden; Elder Stumps bank 2 ranks). Environment Code: the `reshape` placer mode and effect, zones, drawing, growth
looks. Main Merger: the gift screen (kinds, the `GROWS_LINE` under landmarks, step names `STEP_NAMES`), a scene for
`reshape`, rest report lines. Card texts in `POOL` are the step I texts.

### Amendment: every gift is generic (user, 2026-10-13: "make sure the new gifts are generic so they help all families")
No gift names a family or needs one. This replaces the four family landmarks in the table above and the offer rule
"a landmark that fits a family you own": the offer is simply one land gift, one landmark, one boon.
| Gift | Proposed above | Now (helps every build) |
|---|---|---|
| **Spring** | Soaks passers-by; water Wardens +40% | **Wardens within 2 cells attack 25% faster.** |
| **Lightning Tree** | Charged bolts strike twice; its own bolt | **Strikes the strongest nightmare within 3 cells every 4 s** for heavy damage that grows with the act. No status needed. |
| **Bell Stone** | Rings Drowsy; song Wardens faster | **Rings every 6 s: nightmares within 3 cells are slowed by 30% for 2 s** (bosses 15%). A plain slow, not a status. |
| **Mushroom Ring** | Poisons crossers; spore Wardens' cap | **Any status a Warden puts on a nightmare inside the ring lands with half again as many stacks.** Whatever your families apply. |
| **Fallen Giant** | Touching Wardens +30% crit chance | **Touching Wardens have a 20% chance to crit** (or +20% if they already can), so it works for families with no crit. |
| **Bramble Verge** | Brambles make nightmares Drowsy faster | Free Bramble growth, and **Brambles slow nightmares beside them by 20%** (a plain slow). |
| **Old Kin** | One bond grows a step | Only offered when the map has a Kinship; otherwise it is not in the offer. |
Unchanged and already generic: Moonwell, Heartwood Roots, Sow a Ridge, Mire, Reshape, Elder Stumps, Shifting Mist,
Memory Seed, Waking Root. Check on every gift: its text names no family, no family status, and no Warden.
