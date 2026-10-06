# Maze feel: Tropical Tower Wars (2026-10-05)

Owner: design hub (story chat). User: *"want the maze building to feel like Tropical Tower Wars from Warcraft 3"* →
*"still like the build animation; the player should prioritise building walls early instead of upgrading to carry their
run, and only upgrade at the right spots where it covers everything. Also the pathing, so you can create crazy mazes like
the game. Fast, snappy building."*

## Goals
1. **Walls first.** Early Dew is best spent on walls that lengthen the route. Growing pays off later, and only on a
   Warden at a spot the route passes many times.
2. **Upgrade where it covers everything.** The game shows how much route a spot covers, so the player can find the
   junction worth growing.
3. **Crazy mazes.** Enough open, buildable ground and fine enough placement (half cells, done) for long serpentine mazes,
   switchbacks and spirals.
4. **Fast, snappy building, animation kept.** A wall blocks the instant it's placed; the grow / plant animation plays
   on top and never delays the block, the route update or the next placement.

## Changes
| # | Change | Owner |
|---|---|---|
| 1 | **Coverage readout:** the build ghost and the Warden panel show "covers N path tiles" (route halves inside its range, counted once per pass, so a junction the route passes 3 times counts 3×). The ghost tints its chip by how good the spot is vs the board's best. | Tower Code (ghost / panel), Environment Code (route halves) |
| 2 | **Walls stay cheap and copy-free:** Thornwall and the wall line are exempt from the per-copy price step, and Thornwall costs about 2 (Balancing confirms). Plain walls never get pricier the more you place. | Balancing Discussion → Tower Code |
| 3 | **Early value check:** with walls cheap and grows pricey, the bot / sims should show "more walls" beating "an early grow" through act 1, and a grow at a high-coverage spot beating one at a low spot. | Balancing Discussion / Code |
| 4 | **Build flow:** Shift keeps the selected Warden armed after placing; drag lays a line of walls (test_drag_build exists: check it handles half cells and refuses only the blocking piece); placements queue while paused; right-click cancels. The animation is visual only. | Tower Code / Main Merger |
| 5 | **Room to maze:** fewer obstacles inside the main build area (keep the ridges and the feature at the edges), so the middle is open ground for switchbacks. Check route search time on a 400+ half-step maze. | Environment Discussion → Environment Code |
| 6 | **Path length front and centre:** the HUD path counter and the ghost's "+N path" stay prominent; consider a short "longest path this run" flourish when a new record is set. | Main Merger |

Unchanged: no juggling (run_design.md "No maze juggling"). The user didn't ask for it, and the Restless / settling-ground
rules stay.
