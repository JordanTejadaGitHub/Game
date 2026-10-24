# Seat T: Tower defense veteran (maze and fairness), round 2026-10-24

Read-only. Paths from D:\Projects\Game\Project_T. Nothing run.

## 1. Verdict
**Feels good with fixes.** Shapes give the maze a second job (packs reward switchbacks and corners, single file
rewards length) without touching the route, and route flyers keep the maze relevant where the Phantom skipped it.
But four things would make the game look like it cheated: grounded route flyers rise and fly **straight** to the
Heartwood, lanes draw bodies into stone in half-cell gaps, the 3-leaf pack cap makes Packs the *cheapest* shape to
leak (with Headlong and Leaf Fall holes), and the Pall's rules are vague enough to read as a teleport and halve the
one walker that matters most.

## 2. What works (keep)
- **Shapes never touch routes** (enemy_design.md "Drift shapes", Order): the route rule holds, and the maze gets a
  new read. A pack at 0.5 cell spacing is 3-4 cells long, so a switchback lets a pulse or cloud hit it on both legs.
  That is Kingdom Rush / BTD6 "chokepoint" value with no new rule.
- **Seeded mix, first/last arrival kept**: replays are fair and call-early Dew, Auto-drift and the meter don't move.
- **Shapes start at drift 11, Streams at 24/49/74/99, no Few and tough in act 1**: no cliff before the second family.
- **Coming strip with the whole next block plus a timeline**: real foresight, the Legion TD 2 "see the next wave"
  standard, facts only. Do this, not just the glyph.
- **Route flyers, not straight flyers.** A flyer that takes the route length is exposed to every anti-air Warden
  along it, so a longer maze still helps. That is the right lesson from "Phantoms stay rare" (53 of 101 leaves).
  The 6-flyer cap and the `special` tag are right.
- **Gloamwing**: the player's own status brings it into the maze. Player-caused, visible, good.
- **Lanes are visual only** and projectiles aim at the drawn body (commit 1fffbb01). Kingdom Rush has walked
  enemies abreast for years; it reads well.

## 3. Problems, ranked

**1. A grounded route flyer flies straight to the Heartwood when it rises.** The player feels: "I grounded the
Night Kite and it skipped my whole maze." This is already live for Crows. Groundroot is listed as a Night Kite
counter, and Snag uses the same call, so the listed counter becomes a trap.
Cause: `Enemy._rise_from_ground` sets the path to `[current cell, endPath]` whatever `flies_along_route` says
(`scripts/enemy/enemy.gd:2083-2088`). `ground()` also sets `passed_waymark = true` (`:2075`), so a flyer grounded
before the stone walks straight past it. And it lands on the nearest cell of the *whole* route (`:2056-2063`), which in
a tight serpentine can be a later corridor.
Fix: a route flyer (`flies_along_route`) rises back onto its route from the nearest route point **at or behind its
progress** and keeps flying it. It keeps its own `passed_waymark` (`get_path_from(cell, passed_waymark)`). Landing
looks for a cell only within 1 cell of its route index. Gloamwing's permanent drop uses the same landing rule.
Owner: **Enemy Code**. Must ship before any new route flyer.

**2. Lanes draw nightmares into walls in a one-half gap.** The player feels: "it walked through my Warden." A half
gap is 32 px and the lane is ±19 px. `_update_lane` scales the offset only by `open` and `get_lane_width()`
(`enemy.gd:1966-1972`). The narrow-gap squeeze (`SQUEEZE_WIDTH 0.8`, `:86`, `_update_squeeze :1675-1687`) narrows
the sprite but never pulls the lane in.
Fix: multiply the lane offset by the gap state: 0 inside a one-half gap (`_gap_answer`), eased with the squeeze, and
at most ±0.1 cell where the corridor beside the walker is half-blocked on one side. One meaning: **a drawn body never
leaves open ground.** Owner: **Enemy Code**. Please also ask the user to Play one half-cell maze with a Packs drift.

**3. The 3-leaf pack cap makes Packs the cheapest shape to leak, and it has holes.** A Stream of Shades that leaks 7
costs 7 leaves. A pack of 7 Shades costs 3, and a pack of 7 Husks (14 leaves) also costs 3. The shape built to test
the player punishes failure least. Few and tough's elites cost `max(leaf_cost, 2)` each (`shapes_td.md` §1), so the
Stream ends up the harshest shape per point of health. Two holes need one meaning before build:
- **Headlong**: `_compress` runs after the shape, so a Headlong Packs drift keeps its pack ids. It is paid up front
  and its leaks are capped: the safe gamble.
- **Leaf Fall / Giants' Walk** (`omen_director.gd:552-560`, leak multiplier and add): is the cap applied before or
  after? If after, these Omens are free on Packs.
Fix (for Balancing): cap = **max(3, ceil(half the pack's leaf total))**, so 7 Shades cost 4 and 7 Husks cost 7.
Apply it **before** the Omen multiplier and add, and clear pack ids on a Headlong-compressed drift. Show the leak as a
fact at the Heartwood ("Pack: −4 leaves, 7 reached") so the rule is seen, not guessed. Owners: **Balancing
Discussion** (number), **Enemy Code** (cap order, Headlong ids), **Main Merger** (leak text).

**4. The Pall needs exact rules, or it reads as a cheat.** "Settles over the nearest walker ahead of it" and "follows
its walker" read as a jump forward. It also halves the front walker, the one about to leak, and in Few and tough it
would halve a Deeply Blighted that carries 40-70% of the budget. That is a cliff for Focus builds (Seat B's builds).
Fix, one meaning each:
- it settles only on a walker it **reaches** (within 0.5 cell) at its own 72 speed, and never jumps;
- when its walker is dispelled it flies on at 72;
- **never over a boss or a Deeply Blighted**;
- "half damage" = all damage (hits, effects, Reactions), applied **after** the dread shell, so heavy hits keep
  breaking Husk shells (drift 92 is "Palls over 12 Husks");
- the covered walker's bar shows the existing "½" glyph (`NightmareIcons`) and the cloth.
Owner: **Enemy Code**; numbers **Balancing Discussion**.

**5. Hollow Wind can blow past both flyer caps.** `shape_schedule` turns every non-boss arrival into a random flyer
from the block (`omen_director.gd:568-573`). That flyer pool includes the Phantom (straight, cap 4) and would include
the Pall (useless with no walkers). The player opted in, so the Omen is fair, but a 30-Phantom drift is the leaf drain
again. Fix: Hollow Wind swaps only into **route** flyers that aren't the Pall (Crow, Night Kite, Gloamwing). Phantoms
keep the cap of 4 inside it. Owner: **Roguelite Code**.

**6. Route flyers ignore mid-drift rebuilds.** `_on_path_changed` re-routes only `get_maze_walkers()`
(`enemy_spawner.gd:246-249, 661-666`), so a route flyer keeps its spawn route. It is mostly harmless, since it flies
over walls. But a Gloamwing that drops onto a spawn-route cell that is now a Warden slides sideways to the current
route, and that looks like a teleport. Fix: covered by #1's landing rule. Make the drop tween a visible glide of at
most 1 cell, and if no route cell is within 1 cell, land on the nearest route cell behind it. Owner: **Enemy Code**.

**7. Readability and the phone.**
- In the Coming strip and its timeline, flyers need their own dot (a wing outline) and the fact line needs a count:
  "Stream: 30 (6 flying)". The player plans anti-air from a count, not a portrait.
- Lanes ±0.3 near a range ring: a body drawn inside a pulse's ring may not be hit (logic is on the centre line).
  That is acceptable at 0.3. **Never widen it**, and keep flyers at ±0.15.
- The Night Kite next to the Crow on a phone: give the Night Kite a long tail so it reads by shape, not colour.
- Teaching drift 41 "6 Night Kites, 2 s apart, then 16 Shades" is good: alone first, 6 leaves at most.

## 4. Builds and Wardens that shine or suffer (maze view)
- **Shine:** area Wardens at switchbacks on Packs (Puffball, Monsoon, Chime Stone, Breaking Wave / spill builds);
  long mazes with Passing Thread / Gauntlet on Single file; Dewdrop and Bellflower control builds that drop
  Gloamwings into the maze (Soaked / 3 Drowsy).
- **Suffer (fairly):** chokepoint single-target boards on Packs; an anti-air Warden at one spot vs the Night Kite (the
  intended lesson).
- **Suffer (unfairly, until fixed):** Groundroot / Earthbind and the Snag card vs route flyers (#1); Waymark builds
  when a flyer is grounded before the stone (#1); Focus builds against a Pall on a Deeply Blighted (#4); every
  half-cell maze visually (#2).
- **Starting families vs route flyers** (Seat W counts in full): the "Can't hit flyers" forms in the starting four are
  Sporeling's Fairy Ring / Elf Circle / Brood Cap / Hatchery and Dewdrop's Undercurrent / Maelstrom
  (`resource/tower/*.tres` role lines). Groundroot and Earthbind are Rootling (root line), which is not a starting
  family, so the Night Kite's listed "Groundroot" counter is out of reach for most demo boards. The Gloamwing's
  Soaked / Drowsy answer gives Dewdrop and Bellflower a second way in.

## 5. Open questions for the owner
1. **Pack leak cap:** a flat 3, or max(3, half the pack's leaves)? And confirm the cap applies before Leaf Fall /
   Giants' Walk and not on Headlong drifts.
2. **Grounded route flyers:** rise back onto the route (my recommendation) or keep flying straight? Straight makes
   Groundroot a trap against every route flyer, Crows included.
3. **The Pall over Deeply Blighted and bosses:** never (my recommendation), or allowed as the act 4 test?
4. **Hollow Wind:** limit it to route flyers?
