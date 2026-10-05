# Half-cell placement (on main since b8305630, full game + demo)

Owner: design hub (story chat). User, 2026-10-04: *"update the grid placing to be half placing cells. Make more unique
mazes"* → *"Wardens can be placed at half cell offsets."* Built on an experiment branch first. **Approved, 2026-10-04:**
*"I wanted the placed cells in the maze and update all the assets and marketing with it."* Merged into main
2026-10-04 as b8305630 (user, in Main Merger: "Merge, full game + demo"). The work list below is the to-do list.

## The rule
- The **pathing grid becomes 32 px** (half cells): the 23×18 map is 46×36 half cells.
- A **Warden still takes a 64 px footprint** (2×2 half cells) and can be placed at **any half-cell position**, so walls can
  be staggered by half a cell. Obstacles, the start, the Heartwood and its glade keep their full-cell positions.
- **Nightmares fit through a gap one half cell wide** (user, 2026-10-04: *"maybe make the path half a cell now"*, the
  half-cell-gaps option). Their pathing body is 1 half cell, so a placement is only refused when it closes the route,
  never for being "too narrow". Tighter, denser mazes; nightmares walk the half-cell grid. (Replaces the old rule: a
  corridor at least one full cell wide and the &"narrow" refusal.)
- **The look in a narrow gap:** nightmares keep their art and y-sort with the Wardens either side. In a one-half gap they
  squeeze, drawn about 80% wide and eased in and out over a few frames, so they read as slipping through, not clipping
  into stone. Bosses and big nightmares too: one route rule for every walker.
- The drawn path follows the walkable halves, so a one-half gap draws a ribbon 32 px wide. The dual-grid path art must
  read at that width.
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

### Half-cell gaps: who does what
- Environment Code: body 1 half (`body_halves`, `can_block_halves`, the corridor check and &"narrow" go), route search, tests.
- Tower Code: the placer's refusal reasons and the ghost text (no "too narrow").
- Enemy Code: the squeeze in one-half gaps; check rounded corners and trample/charge on one-half routes.
- Environment Discussion / Assets: the dual-grid path tiles must work for a one-half-wide path.
- Balancing: re-check route lengths (they get longer) and the act 1 targets.
- Design hub: hints / Codex lines that mention "too narrow".

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
