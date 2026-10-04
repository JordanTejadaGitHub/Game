# Half-cell placement (EXPERIMENT, branch `experiment/half-cells`)

Owner: design hub (story chat). User, 2026-10-04: *"update the grid placing to be half placing cells. Make more unique
mazes"* → *"Wardens can be placed at half cell offsets."* Built on an experiment branch first; nothing reaches main until
the user has played it and says yes.

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

## If it's a yes, later work
Path tile art for the half grid, every cell-based number checked, touch placement (bigger snap or a hold-to-nudge),
gifts and map features on the half grid, Kinship reach, the Codex's wording.
