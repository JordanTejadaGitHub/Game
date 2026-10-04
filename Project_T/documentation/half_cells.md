# Half-cell placement (approved for main; built on `experiment/half-cells`)

Owner: design hub (story chat). User, 2026-10-04: *"update the grid placing to be half placing cells. Make more unique
mazes"* → *"Wardens can be placed at half cell offsets."* Built on an experiment branch first. **Approved, 2026-10-04:**
*"I wanted the placed cells in the maze and update all the assets and marketing with it."* It goes to main once the
user confirms the merge in Main Merger's session. The "later work" below is now the to-do list.

## The rule
- The **pathing grid becomes 32 px** (half cells): the 23×18 map is 46×36 half cells.
- A **Warden still takes a 64 px footprint** (2×2 half cells) and can be placed at **any half-cell position**, so walls can
  be staggered by half a cell. Obstacles, the start, the Heartwood and its glade keep their full-cell positions.
- **Nightmares need a corridor at least 2 half cells (one full cell) wide.** A placement that would leave a 1-half-cell gap
  anywhere on the route is refused like a blocking one ("too narrow for them to pass"). Nightmares walk the half-cell grid
  (smoother diagonal-ish zig-zags around staggered walls).
- Flyers unchanged (straight line).

## What stays the same for the prototype
- Ranges, auras and "within N cells" keep meaning full cells (64 px); they're measured from the Warden's centre.
- The path art: draw the walkable half cells with the existing tiles at half scale, or a plain soft path fill: a look
  good enough to judge play, not final.
- Map generation, obstacles and gifts keep full cells.

## What to judge in play
- Do half offsets make mazes more varied and interesting, or just fiddly?
- Is placement clear (ghost snapping, the "+N path" tag) with the mouse? (Touch is checked later.)
- Performance at late drifts (4× the path nodes).

## Going to main: the work and who owns it
| Work | Owner |
|---|---|
| Merge into main, drop the experiment plumbing, full suite (fix test_family_finals "two pulls = one drag" first) | Main Merger, Environment Code |
| Final path art for the half grid (replaces the soft fill), route mist aligned to it, in every act's sheets | Environment Discussion → Environment Assets / Code |
| Map features and gifts that place terrain (Sow a Ridge, Fallen Giant, Spring…): full or half cells | Environment Discussion |
| Every cell-based number re-checked: route lengths, "+N path", auras, Kinship reach, gift sizes, boss targets | Balancing Discussion / Balancing Code |
| Touch placement: a bigger snap or hold-to-nudge (mobile port) | Main Merger (later) |
| Codex, hints and card text: "cells" still means full cells; explain staggered walls in one hint | design hub |
| Capsule map and marketing captures show staggered mazes | Theme Asset, Main Merger (marketing.md) |
