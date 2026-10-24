# Enemy Design Council review

Skill: `.claude/skills/enemy-design-council`. Seat reports per round in `documentation/enemy_council/<date>/`. Newest round first; earlier rulings that still hold stay.

## Enemy Design Council, round 2026-10-24b: enemy movement

Owner: "Enemy movement looks off." Seats B (build player), W (Warden roster keeper), T (tower defense veteran),
S (systems and code), P (this round: motion and game-feel animator). Reports `seat_<letter>.md`, frames
`seat_<letter>_frames\`. Read-only; nothing run. Footage: `walking_lanes.mp4`, `drift_types_small.mp4` and the
.avi captures (seed 4242). Limit: every capture plants only Thornwalls, so attack and Calling cues were judged
from code (B W).

### Verdict: feels good with fixes (all five)
Packs now read as clumps, not beads, which is the picture crowd builds promise (B T W P). What looks off is three
motion faults, all numbers and easing, plus visual feedback still anchored to the logical position. No game rule
changed and none should (all).

### What looks off (spot-checked by the lead in `enemy.gd`)
1. **Lanes are wider than the drawn path (all five).** The sand band is about 0.55-0.6 cell wide; `LANE_MAX` 0.3
   (`enemy.gd:267`) + a body's half-width puts bodies on the path's edge and over dark grass, where dark
   nightmares lose their contrast (worst on a phone), and over obstacles at inside bends.
2. **Sideways sliding outruns the walk (all five).** A new lane is rolled anywhere in −1..1 (`:1960`) and eased
   at `LANE_EASE` 3 with no cap (`:1961`): slides start at 38-115 px/s while 13 kinds walk 35-58 px/s, facing
   forward. Slow nightmares skate sideways like on ice. This is the main "off" look.
3. **Corners whip (S P).** The sideways axis comes from the next route point (`:1963-1967`) and flips at a
   turn: outer bodies flick ~27 px in 0.3 s, inner ones slide backwards; stair paths zig-zag.
4. **Narrow gaps (T S):** `_update_lane` never reads `_gap_answer` (`:292`, `:1682`), so a squeezed walker in a
   half-cell gap is still drawn up to 19 px off centre, over the Warden beside it.
5. **Jostle (B T S P):** reach 0.4 cell is shorter than one body, so pairs stack into one dark blob (B P); the
   straight-line reach fires at every corner and pushes pairs twice (S); its clamp pins big packs to two rails
   at the path edges (T S).
6. **Feedback still lands on the logical position, up to 19 px beside the body (B W):** damage numbers and combo
   words (`damage_log.gd:425`, `combat_callouts.gd`), the Charged bolt and Live Wire (`reactions.gd:906/938/952`),
   the Lantern Light jump (`firefly_lights.gd:2640`), the Dewdrop splash ring (`tower.gd:3887`), pulse hit sheets
   (`tower.gd:3231`), the crit flare and status flashes (`enemy.gd:3106/965`), Keeping Time's ring pips
   (`keeping_time.gd:396-398`, 463), Calling threads (`class_kit.gd:448`). In a pack a number or a splash reads
   as hitting the neighbour. Projectiles, beams, the main chain, pecks and Reaction sheets are already right
   (`Tower.aim_at` → `get_body_position`, W).

### Rulings (numbers)
| Thing | Now | Ruling | Seats |
|---|---|---|---|
| `LANE_MAX` (Stream, Packs) | 0.3 | **0.2** cell | T .18, B .18, P .22, W .2, S .2 |
| `LANE_BIG` (bosses, big kinds, Few and tough elites) | 0.15 | **0.1** | T .08, B P S .10 |
| Single file | 0.1 | **0.06** | T .05, B P .06 |
| Flyers | 0.15 | **0.15** (no path edge in the air) | B T W S keep |
| New lane target | anywhere in −1..1 | **current ± 0.3-0.7**, clamped to ±1 | T B P S |
| `LANE_WANDER` | 3-6 s | **4-8 s** | B P S (T 5-9) |
| Lane easing | exponential, `LANE_EASE` 3 | **smoothstep, at least 0.8 s a move, sideways speed ≤ 0.25 × the walker's speed** | T .3, B .2, P .25, S .35 |
| Sideways axis | from the next route point, `LANE_TURN_EASE` 5 | **the rounded curve's tangent** (`_corner_curve`); fallback `LANE_TURN_EASE` 10 | S P |
| Near a turn | full lane | **lane × 0.5 within 0.5 cell of the turn's centre** | B (0.4), P |
| Narrow half-cell gap | full lane | **lane → 0** (eased at 14, exempt from the speed cap) | T S |
| `CORNER_ROUNDING` | 0.3 | **0.3** (keep) | T B W keep; P 0.4 |
| Jostle neighbours | same + next cell, straight-line 0.4 | **by route index ±1, along-route reach 0.55 cell, each pair once** | S B P |
| Jostle trigger | lanes < 0.25 cell apart | **< 0.15 cell apart** | T B |
| Jostle push | 1.2 lane units/s, clamped ±1 | **0.8**, through the same speed cap, **never past ±0.85** | B 0.8, T 0.6/±0.8, S ±1 |
| `LANE_SNAP_PX` | 0.25 | **1.0**, offset rounded to whole pixels (no pixel crawl) | S |
| Lane close-out | straight-line distance to the end | **route distance** over the last cell | S |
| Facing | from the node's travel | **keep** (with the slide capped it never needs to turn) | all |
| Y-sort | by node | **keep for now**; at 0.2 the overlap window shrinks; re-judge on the new capture | T S W |

**Where they disagreed:** jostle strength (T weaker, B and P stronger). Ruled: S's structural fixes remove the
corner false triggers and double pushes that caused both the blobs and the rails, so a moderate push (0.8) with a
±0.85 clamp answers both.

**Feedback rule:** anything drawn ON a nightmare (numbers, words, flashes, bolts, jumps, splash rings, pips,
threads) uses its drawn body position (`get_body_position`); anything on the GROUND (puddles, rings, mushrooms,
clouds) stays where the route is. No range, radius or targeting changes (W).

### Open owner calls
1. P's two ideas: a slow drift forward and back along the path (±0.08 cell, every 2-4 s) so Streams don't keep
   even spacing; a pack swaying together (one shared lane target). Lead: neither yet; re-judge on the new capture.
2. Walk-cycle speed following the drawn speed through bends (P, 0.7-1.4×): small polish, later.
3. Big Packs read as a faint smear: that's the art's translucency at density (T), an Enemy Assets question.
4. A re-capture after the fixes with real Wardens (a Firefly Jar, Dewdrop and Bellflower maze) and one Calling
   run, so the next judgement sees hits, numbers and Calling cues (B W).

## Enemy Design Council, round 2026-10-24: drift shapes, walking lanes, new flyers

Seats: B build player, W Warden roster keeper, T tower defense veteran, S systems and code keeper, P pacing and
balance. Reports: `seat_<letter>.md` beside this file. Read-only; nothing was run.

### Verdict: feels good with fixes (all five seats)
Drift shapes give every Calling line a drift it loves and one that tests it, and keep the route the player's plan
(B T P). Walking lanes don't touch builds or pacing (B P W); how they look is reviewed in round 2026-10-24b. Route
flyers are the right fix for the Phantom's lesson (T W), but three live bugs and two loose rules would make the
new flyers feel bad until fixed.

Status found by S: shapes and lanes are **already built** (`scripts/run/drift_shapes.gd`, lane code in
`enemy.gd`; parse-checked, not run); only the three flyers are design-only.

### Fix first (spot-checked by the lead)
1. **Grounded flyers skip the maze (live bug, B T W S agree).** `Enemy.ground()` sets `passed_waymark = true` and
   lands the flyer on the nearest cell of the whole route; `_rise_from_ground()` sets its path to
   `[current cell, endPath]`, a straight line (`enemy.gd:2049-2092`). So Groundroot, Earthbind and Snag turn a
   route flyer (today's Crows) into a Phantom. **Ruling:** a route flyer rises back onto its own route (the route
   index it held, two legs if a Waymark stands), and `passed_waymark` stays what it really was; only through-wall
   flyers (Phantoms) rise straight. Owner: Enemy Code.
2. **Hollow Wind breaks every flyer cap (B T P S agree).** `omen_director.gd:564-573` swaps each non-flyer arrival
   for any flyer of the block, Phantoms included. **Ruling:** Hollow Wind draws route flyers only (Crow, Night Kite,
   Gloamwing; never the Phantom or the Pall), and the flyer cap is checked at schedule time after the Omens.
   Owners: Roguelite Code (Omen), Enemy Code (cap).
3. **The cross-kind flyer cap doesn't exist yet (S).** Only per-kind `drift_max`. **Ruling:** flyers of all kinds
   at most **4 / 5 / 6** in acts 2 / 3 / 4 (P), Phantoms at most 4 within that, applied after Omens; a flyer is never
   chosen as a guaranteed or Blight elite (S). Owner: Enemy Code.
4. **Few and tough is the leaf cliff (P).** Its 3-5 Deeply Blighted cost 2 leaves each and leak together uncapped
   (8-12), while a pack is capped. Confirmed: only packs carry a cap (`run_state.gd:241-249`). Owner call (below).
5. **The Pall needs exact rules before it's built (B W T S P).** Rulings that need no owner call: it never covers a
   boss or a Deeply Blighted; its effect applies after the dread shell; no Palls in Few and tough drifts; its
   teaching drift 92 is Palls over Shades, not Husks (W). Its damage rule and targeting are owner calls.
6. **Doc errors:** Pile-On is a free-hit card at a clump, not a "3+ nightmares" card (B; `calling_paths.gd:70`);
   Groundroot / Earthbind are Rootling, not a starting family, so the Night Kite's listed counter is wrong for most
   boards (T W). Fixed in enemy_design.md.

### Where the seats disagreed, and the ruling
- **Pall damage:** B "shares each blow half and half with the Pall"; W and S "half damage, Wardens target it
  first". Ruling: owner call. The lead recommends **sharing** (no second damage reduction, which the Kinds rule
  forbids; hit cards and Focus lines keep full value; the Pall still dies first under fire).
- **Gloamwing drop:** B "3 Soaked + Drowsy counted together, never raised by Brimming"; W "Soaked for 2 s". Today
  one Dewdrop splash drops it while Bellflower needs 3 Drowsy. Lead recommends **B's version** (fair to both
  families, readable as one counter on its card).
- **Flyer share:** W adds "at most a third of a rolled drift's arrivals" on top of the cap. Lead: adopt it; it
  costs nothing and keeps small drifts from being mostly flyers.

### Builds and Wardens
- **Shine:** Packs for crowd capstones, spill / waves, jumps, Tolls, Reactions; Single file for Spread lines,
  doses, streaks, long mazes; Few and tough for Focus lines, hit cards, boss capstones (Calling hits halve only on
  `is_boss`, `class_kit.gd:499`, so Deeply Blighted get full value: B).
- **Suffer:** dispel-count engines on Few and tough (Wild Growth, Hard-Won Rings); Calling ground setups ignore
  every flyer (`class_kit.index_of` returns -1 for flyers: Puddles' water, Spore Print's mushrooms, Keeping Time's
  primes; Lantern Light is fine: W S); the 6 forms that can't hit flyers (Fairy Ring / Elf Circle, Brood Cap /
  Hatchery, Undercurrent / Maelstrom: W). Every starting family answers flyers from its base Warden up (W).
- Only Moonstone and Standing Stone can pick targets, so "target priority" is no counter for most boards (W S).

### Numbers for Balancing
Flyer cap 4 / 5 / 6 by act, a third of arrivals at most; teaching drifts 41 with 4 Night Kites (not 6); the
gate's leak count to include bodies and health leaked, not only leaves (P); sims: flyers <= 25% of leaves lost
over 41-100, Few and tough worst decile <= 6 leaves, drifts 51-60 per shape, the intros 41 / 69 / 92, Hollow Wind
/ Moth Night / Leaf Fall blocks (P).

### Owner calls
1. **Few and tough leaks:** cap a Few and tough drift's elites at 6 leaves together (lead's pick), or keep 2 each.
2. **Pall:** share damage (lead's pick) or half damage with Wardens aiming at it first.
3. **Gloamwing:** 3 Soaked + Drowsy counted together (lead's pick) or any Soaked for 2 s.
4. **Route flyers and maze / Calling route cards:** count a route flyer on the route it flies over (lead's pick:
   it's above the path, so Passing Thread, Gauntlet and Calling route rules see it), or keep them blind to flyers.
5. **Dispel-count Legendaries:** a Deeply Blighted counts as 3 dispels for Wild Growth and Hard-Won Rings (lead's
   pick), or leave them as they are.
