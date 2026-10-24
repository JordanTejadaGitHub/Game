# Enemy Design Council review

Skill: `.claude/skills/enemy-design-council`. Seat reports per round in `documentation/enemy_council/<date>/`. Newest round first; earlier rulings that still hold stay.

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
