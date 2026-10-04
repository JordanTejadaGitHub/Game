# Half-cell placement (on main since b8305630, full game + demo)

Owner: design hub (story chat). User, 2026-10-04: *"update the grid placing to be half placing cells. Make more unique
mazes"* → *"Wardens can be placed at half cell offsets."* Built on an experiment branch first. **Approved, 2026-10-04:**
*"I wanted the placed cells in the maze and update all the assets and marketing with it."* Merged into main
2026-10-04 as b8305630 (user, in Main Merger: "Merge, full game + demo"). The work list below is the to-do list.

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

## Placement feel (user, 2026-10-04: "doesn't feel as snappy anymore. Also add grids when placing")
- **Snappy again:** the ghost moves the same frame the mouse crosses a half-cell line; the route preview and "+N path"
  may follow a frame later, but never hold the ghost back. Profile hover and placement on a late, busy field. Re-check
  only when the hovered half changes, cache the last result, and run the route search for the ghost off the input frame
  if it's over ~2 ms. A placement click lands instantly: the Warden appears that frame.
- **No jitter:** a small dead zone (about 4 px) before the ghost leaves its half, so a resting hand doesn't flicker
  between two offsets.
- **Grid while placing** (build mode only, fades in over 0.15 s, off outside it):
  - faint whole-cell lines over the buildable ground, in the moonlit ink at about 12%
  - half-cell lines only in a soft circle about 3 cells around the cursor, fainter still, so the offsets show where
    you're aiming without covering the map in a fine mesh
  - the ghost's 2×2 footprint outlined in gold, refused halves in the cold "can't" colour
  - none on obstacles, the void or the HUD. A setting "Placement grid: On / Near cursor / Off" (default On). Reduced
    motion: no fade.

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
