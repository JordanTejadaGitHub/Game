# Environment Assets

The original environment art that replaces the Foozle Spire tileset (`demo_scope.md`: "all art is
original"). Style: **Waystone pixel** (`art_style_options.md`). Direction: `art_direction.md`
(warm centre, cold edge; ground < obstacles < path in value). Created 2026-09-27 from the concept
page (https://claude.ai/artifact/DhTsE8rJXJwU3UgYEL73ym), seed 1207.

**In the game** (2026-09-27): `scripts/map/environment_tiles.gd` (`EnvironmentTiles`) builds one
TileSet from these sheets (one atlas source per file) that the ground, path and object layers share,
and swaps every sheet to the next act's folder at act breaks (`Seasons` → `MapGenerator.set_act`).
The Heartwood is `scripts/map/heartwood.gd`. Waystone, Dew Pool and Blight Patch have tiles in the
TileSet but aren't placed on maps (their rules are still proposals).

Lighting (the tiles stay unlit): `environment_lighting.gd` (a cold multiply toward the map's edges,
a warm additive glow per attacking Warden, all drawn by one canvas item), `heartwood.gd` (a warm light plus an additive glow over
the multiply, dimming as leaves are lost) and `environment_ambience.gd` (nightmare fog along every
edge; per act: warm motes, cold wisps, fog banks and embers, snow).

## Folders

One folder per act, same file names in each, so swapping acts means swapping the folder:

| Folder | Act | Season / mood |
|---|---|---|
| `assets/environment/forest_edge/` | 1. Forest's Edge | spring dusk |
| `assets/environment/deep_wood/` | 2. Deep Wood | summer night |
| `assets/environment/misty_hollow/` | 3. Misty Hollow | autumn fog |
| `assets/environment/heartwood_glade/` | 4. Heartwood Glade | winter dark |

Lighting is **not** baked in: the tiles are the unlit night palette. The warm centre and cold edges
come from a `CanvasModulate` plus `PointLight2D`s (`art_direction.md`).

## Sheets

All cells are 64×64 unless noted. Frames run left to right; animated sheets are 4 frames at 4 fps.
In game every animated tile starts at a random point per cell, and each dead-tree type runs at its
own speed with uneven frame timing (`EnvironmentTiles.TREE_SPEEDS` / `TREE_FRAME_WEIGHTS`), so no
two trees pulse in step.

| File | Size | Layout | Use |
|---|---|---|---|
| `grass.png` | 512×64 | 8 variants: 0 plain, 1/4/6 tufts, 2 flowers, 3 clover, 5 pebbles, 7 fallen twig | ground; any variant tiles with any other. Flat ground with a few hand-placed tufts and low moss clumps, no speckle (the AI-look audit, 2026-10-04: a random grain read as generated), through the calm detail pass. Shares: `GroundGenerator.GRASS_WEIGHTS` |
| `path.png` | 1024×64 | 16 tiles, **column = neighbour mask** (N=1, E=2, S=4, W=8) | the creature path; e.g. column 5 = N+S straight, 15 = crossroads. Flat Path earth, a crisp wobbly Loam bank, a few pebbles and dark specks, the odd tuft over the bank (`paintPath`, shared with `path_rim` and `path_dual`; the AI-look audit replaced the speckle and the dithered edge) |
| `path_dual.png` | 608×32 | **19 tiles of 32×32 in one row: 0–15 = corner mask** (the half cells at the tile's corners that are path: TL=1, TR=2, BR=4, BL=8), **16–18 = 3 more full tiles** (mask 15) to vary long stretches | the half-cell path (environment_assets.md "Half-cell grid"): a dual-grid autotile drawn on a layer offset 16 px from the half-cell grid. The path edge lies on each tile's midlines, outer and inner corners round off, a half-step jog bends softly; tiles join without seams. The same look as `path.png`, transparent outside the path |
| `path_rim.png` | 1024×64 | 16 tiles, **column = neighbour mask** like `path.png` | the path on the start and goal cells, which sit in the rim ring: the same path, transparent outside it (no grass border). Draw it over the matching `island_edge` tile so the rim's earth runs up to the path |
| `border_wall.png` | 128×64 | 2 variants, seamless | the map's stone border |
| `withered_tree.png` | 384×1152 | **96×128 cells** (bigger since 2026-09-30): the bottom 64 px rows, centred, are the cell (trunk base and shadow); the rest overhangs the cell above (64 px) and the sides (16 px each). Drawn from the 64 px designs with heights × 1.7 and widths × 1.3. 9 dead trees (rows) × 4 frames: 0–2 gnarled Withered Tree, 3 split trunk, 4 broken hollow snag (eyes glint), 5 weeping dead willow (strands sway), 6 dead pine, 7 dead birch, 8 thorn tree | obstacle, "Tend"; all 9 are in `tree.tres` |
| `fallen_log.png` | 384×64 | 6 pieces of 64×64: **W end, E–W middle, E end, N end, N–S middle, S end** | a dead tree lying along a straight line of cells (the map's log feature, the Fallen Giant gift): the dead trees' cool bark, moss on its back, a broken branch stub on each middle piece, pale splintered ends. Pieces join seamlessly (outline never on a cell edge, grain wraps every 64 px); the N–S pieces are the E–W ones turned |
| `log_furrow.png` | 384×64 | the same 6 pieces as `fallen_log.png` (W end, E–W middle, E end, N end, N–S middle, S end) | the walkable mark a Tended fallen log leaves (the log is Tended as one unit): a shallow rotted trench of dark peat with a faint lit lip, bark chips in the log's colours, pale splinters and moss creeping back; lines up with the log cell for cell |
| `tended_stump.png` | 64×64 | 1 | walkable mark left after Tend |
| `mossy_boulder.png` | 576×64 | 9 rocks, each about 68% of their first size (low in the cell with a shadow, clearly smaller than the trees): 0–1 Mossy Boulder, 2 slab stone, 3 cairn, 4 rock cluster, 5 split boulder, 6 lichen boulder, 7 carved boulder, 8 dream-crystal boulder | obstacle, "Move"; all 9 are in `rock.tres` |
| `moved_hollow.png` | 64×64 | 1 | walkable mark left after Move |
| `waystone.png` | 256×64 | 4 frames | proposed bonus build spot |
| `dew_pool.png` | 256×64 | 4 frames (frozen in winter) | proposed special tile |
| `pond.png` | 1024×256 | **column = neighbour mask** of pond cells (N=1, E=2, S=4, W=8, like `path.png`), **row = animation frame** (4 frames). Transparent outside the banks | the pond feature (2×2 to 3×3 cells of still water): earth-and-moss banks on its outer edges, teal water darkening toward the middle (depth = distance to the shore, so cells join into one body), moonlight glints that shimmer over the frames, the odd lily pad; ice with cracks in Heartwood Glade. Assumes a rectangle: where two sides join, the diagonal cell is pond too (no inner corners) |
| `pond_inner.png` | 256×64 | 4 overlay tiles, columns **NE, SE, SW, NW**; static, transparent except one corner | for ponds that aren't rectangles: draw over the pond tile of a cell whose two neighbours on that corner's sides are pond but whose diagonal isn't (1–2 per cell). A small rounded point of land with its bank (lines up with the two neighbouring cells' banks) and shallows round it; ice in Heartwood Glade |
| `blight_patch.png` | 256×64 | 4 frames | proposed special tile |
| `edge_mist.png` | 256×64 | 4 frames, transparent overlay | start cell / map edge mist |
| `tree_round.png`, `tree_pine.png`, `tree_flowering.png` | 64×64 | 1 each | scenery on cells the maze never uses |
| `ground_details.png` | 768×64 | 12 variants: the 4 kinds (column % 4: mushrooms, ferns, pebbles, leaf litter), each at 3 spots in the cell so a scatter never lines up on the grid | walkable decoration on about 30% of the cells in the noise's detail band (`DETAIL_SHARE`) |
| `island_edge.png` | 1024×256 | 16 tiles, **column = neighbour mask** (N=1, E=2, S=4, W=8: which neighbours are island), **row = variant** (4; they all meet at the tile ends, the middle bulges and bites differently; the generator picks one per rim cell by a hash of the cell). The grass creeps over the inner lip in uneven tongues and the outline wobbles, so the edge never runs straight or repeats | the map's unbuildable rim (screens_ui.md): **no grass**, a sunken ledge of crumbled dark earth (value below the ground's; the pipeline checks it) whose open sides crumble and fade into the void, roots hanging off the lip, and a shadow step with overhanging grass where it meets the buildable ground; the south lip meets the cliff tops. Assumes a convex (blocky) island: no inner-corner tiles |
| `cliff.png` | 256×256 | columns: bit 1 = the cell to the west also has cliff, bit 2 = the east does; rows: 4 variants | cliff face under island cells whose south neighbour is void; transparent below its ragged, dripping underside |
| `heartwood.png` | 512×2688 | 128×128 frames: **row = leaves lost (0–20)**, 4 frames per row; the Memory Grove's Heartwood (twisted trunk, gold-rimmed mossy bark, the Hollow's light): rot spreads through the crown, a dream-fruit darkens per 4 leaves, the rim turns ember and the Hollow fades by 20 | the goal; anchor its bottom centre about 8 px below the goal cell's bottom centre, so it overhangs the cells around it |
| `heartwood_stage_0.png` … `heartwood_stage_3.png` | 512×2688 each | like `heartwood.png`: 128×128 frames, **row = leaves lost (0–20)**, 4 frames per row | the in-run Heartwood that mirrors the player's Memory Grove (meta_design.md "Carried into the run"): canopy stages matching `assets/meta/grove/grove_canopy_0..3.png` (young → fuller → broad → great old tree), the same 128 px frame (later stages are fuller and broader, never bigger). The Grove's crown palette in every act, shaded in 2 px blocks; Bark-to-Root wood; warm halo rim and golden Hollow. **No dream-fruit or twinkles**: the game draws a fruit per Memory and a glint per planted node. Fruit vines hang to the fruit anchors. Leaf loss: rot spreads through the crown, black leaves fall, the rim turns ember and the Hollow fades |
| `heartwood_stages.json` | text | `frame`, `fruit_sheet`, and per stage `crown` [x0, y0, x1, y1], `fruit` (10 anchors in fill order: the fruit's centre in the 128 px frame; under the crown's belly first, centre out, then nestled in the crown) and `glints` (the lit 2 px blocks where a glint may twinkle) | read by the game to place the fruit and glints over the stage sheet. Copied as is by `process_environment.gd` |
| `dream_fruit.png` | 48×24 | 12×12 cells, centre (6, 6). Row 0: lit, 4 frames of its breathing halo; row 1: dark (4 equal frames), for a fruit whose leaves are lost | one dream-fruit = one Memory, drawn by the game at the stage's fruit anchors |

### The dream's outer layer (shared, `assets/environment/dream/`)

The map as an island of dream adrift in a starry void (from concept direction C, drawn in the
Waystone pixel style). Not act-specific. **In the game:** the border cells are `island_edge` rim tiles
(grass only inside the rim), `cliff` tiles hang under the bottom row, a `rope_bridge` leads 3 cells
out from the start to an islet, and `scripts/map/dream_void.gd` (`DreamVoid`) puts `void_sky` /
`void_stars` behind the map as `Parallax2D` layers and scatters `void_islets`. `border_wall` and the
healthy trees are no longer used.

| File | Size | Layout | Use |
|---|---|---|---|
| `void_sky.png` | 256×256 | seamless | back parallax layer: indigo with nebula bands and faint stars |
| `void_stars.png` | 256×256 | seamless, transparent | front parallax layer: brighter stars |
| `void_islets.png` | 256×64 | 4 small floating islands | scatter in the void |
| `rope_bridge.png` | 128×64 | 2 tiles: east–west, north–south; repeat along the bridge | where nightmares cross from the void to the start cell |
| `cloud_shadows.png` | 1536×128 | 6 cloud shadows, 256×128 each, transparent | cloud shadows seen from above (lobed, denser in the middle, wisps on the downwind side; 3 banded alpha steps of Dread). `EnvironmentAmbience` draws them drifting round the map edges and a few (`crossing_clouds`) across the whole map with `cloud_wind` |
| `mist_banks.png` | 256×256 | seamless tile, transparent; dithered fog in the title's fog ramp (Pool, Slate, Stone, Mist) | the title and Grove screens' teal-grey mist: `EnvironmentAmbience` drifts two layers of it over the island (stretched 2× wide, 32 px bands, at the cloud shadows' z), thickest at the back of the map, a little at the front and down the sides, thin over the middle (`mist_strength`) |
| `route_mist.png` | 64×24 | a strip that tiles left ↔ right, forward = +x; transparent top and bottom | the route's cold mist (screens_ui.md "Route mist"; v2 2026-10-01 for play zoom): a pale Mist core (0.75) inside Slate, inside a broken, dithered cold Shade edge, so it reads both on the pale path (the cold edge) and on dark grass (the pale core); its thickness swells and pinches like fog. Soft broken 2 px strands of Moonlight / Wraithlight drift through it (a sharp continuous violet line read as lightning). Tiled along a Line2D (width = 24) by the run-start route and the build preview |
| `route_mist_start.png`, `route_mist_end.png` | 32×24 each | caps for the strip's two ends | sampled from the strip's own pattern (start = its last 32 px, end = its first 32), so start cap + strips + end cap join without seams: the start thin and fading in, the end fading out with a curl reaching forward |
| `route_wisp.png` | 144×24 | 6 frames of 24×24, facing right (+x), centre (15, 12) | a brighter wisp drifting along the route at the run start: Heartlight / Moonlight core, banded Wraithlight glow with a thin cold Shade rim (reads on the pale path), a soft swaying 2 px tail |

## Map layouts

User report (via the design chat, 2026-10-01): "it feels like the map generates the same layout most
of the time". Every map used to run from (1, 0) to the opposite corner, so ridges always alternated the
same way. Now each map rolls a layout, ridges that follow it, and one feature.

### Spec (Environment Discussion, 2026-10-01)

1. **Layout per seed**, rolled from the map rng (a save rebuilds it). Map 23×18.
   - **Corner → opposite corner** (~40%): all 4 mirrors.
   - **Side → opposite side** (~35%): left↔right (long axis) or top↔bottom (short axis, with an extra
     ridge so its route stays in band).
   - **Inlet** (~25%): start and Heartwood on the same edge, so the run is a U.
   - Start and end are jittered along their edge (never exact corners or midpoints). The rope bridge,
     the edge mist and the bridge-end islet follow the start's edge outward. Cliffs stay under the south
     row: a south start's bridge crosses out over them, a north Heartwood overhangs the void.
2. **Ridges follow the layout**: across the main direction, 2–3 of varying length, keeping the taper
   (root / middle / tip / strays) and the guaranteed bend. Inlet: one long spine ridge from the shared
   edge between the start and the Heartwood (the U), plus 0–1 more. Blight 9's extra ridge applies.
3. **One feature per map**: a pond (2×2–3×3 water: unwalkable, unbuildable, never cleared; the route
   bends round it), a ruin (a ring of stones with a gap, cleared with Move), a dense grove, or a
   fallen log (`fallen_log.png`, one obstacle over 3–4 cells, Tended as a unit; it first tries to lie across the
   opening route, `LOG_ACROSS_TRIES`, so Tending it is a shortcut). At least 2 cells from the
   start and end; counted in the obstacle budget.
4. **Guards**: the route is always guaranteed; the starting route length and buildable-cell count stay
   within ±25% of the old medians for every layout; the first-run camera glide follows the actual route;
   RunSaver VERSION bumped.
5. **Preview**: a sheet of ~12 seeds covering every layout and feature, labelled, route drawn.

### As built

- `scripts/map/map_layout.gd` (`MapLayout`): `roll(rng, size)` is the first thing drawn from the map
  rng. Kinds `CORNER` / `SIDE` (`short_side`) / `INLET`, `start`, `end`, `ridge_axis` (ridges run along
  x or y), `feature`. Over 2,000 seeds: 39% corner, 35% side (half each axis), 26% inlet. Corners sit
  1–4 cells in from the corner along a top/bottom or left/right edge; side ends ±3 from the middle;
  inlet ends at about ¼ and ¾ of their edge, ±2.
- `MapGenerator` sets `startPath` / `endPath` from it before anything reads them (every system reads
  them live). `force_layout` / `force_short` / `force_feature` are for tests.
- `EnvironmentObjectGenerator` builds ridges in a frame where u runs along the ridge and v across it
  (`_cell(u, v)`), so one ridge routine (`_ridge`) serves both axes:
  - **Corner / side**: `_crossing_ridges`: 2 ridges (3 on the short axis, +1 at Blight 9) from
    alternating walls, the first on the start's side and nearest the start. The bend rule: the second
    ridge has no gaps, the two always overlap, and the first only gaps `BEND_DEPTH` (4) cells inside
    the second's reach. Side layouts start mid-edge, so both their ridges are gap-free and longer
    (`side_ridge_length_*`, `short_side_ridge_length_*`); the short axis also thins its trees
    (`short_side_tree_scale`).
  - **Inlet**: `_inlet_ridges`: a gap-free spine (`spine_length_*` of the way across) from the shared
    edge, halfway between start and Heartwood, plus 0–1 ridges from the far wall (+1 at Blight 9).
- **Features** (`_place_feature`, after the ridges): `feature_cells`; ponds are also `pond_cells`,
  which are blocked in pathing but aren't obstacles (no Tend / Move, no build: the build hatch shows
  them) and are only placed if the route survives with every ridge standing. A ruin uses the standing
  stone, cairn and ruined waystone rocks; a grove is a tight tree cluster; a log is one obstacle over a
  3–4 cell line (`fallen_log.tres`, `EnvironmentTiles.FALLEN_LOG` pieces by `log_piece`; `MapGenerator.get_obstacle_cells`
  gives its cells: one Tend clears all of them for a tree's cost per cell (`ObstacleClearer.get_clear_cost_at`), counts as
  one clear, previews the route with all cells open, leaves `log_furrow.png` piece for piece; carving breaks it whole;
  `tests/test_fallen_log.gd`). Feature cells keep `feature_clearance` (3, chessboard) from the start and end. Ponds draw
  `pond.png` by neighbour mask (animated down its column).
- **Follow-ups** (2026-10-01, after the first sheet): the opening route is the **straightest of the
  shortest** (`MapGenerator._straightest_route`: per cell and heading, the fewest turns along shortest
  paths, handed to `PathGenerator.prefer_route` so the first draw and the sticky re-routes start from
  it; lengths unchanged). One-tile steps on the 12 sheet seeds 68 → 12 (turns 174 → 88), over 50 seeds
  270 → 47 (700 → 364). **Ponds** are organic: half are blobs (2×3, 3×2, 3×3, 2×2; `POND_SIZES`), the rest
  a 3×3 with 1–2 corners dropped or an occasional L; `pond_inner.png` covers their inside corners
  (`pond_corners`, drawn as small sprites by `MapGenerator._draw_pond_corners`, season-swapped). **Ponds and ruins shape the opening**: their first
  `NEAR_ROUTE_TRIES` (50) placements must come within `NEAR_ROUTE` (2) cells of the route as the ridges
  leave it (`_provisional_route`), then anywhere as before; 8 of 8 test seeds each land near the route.
- **Carving** keeps ridges and the feature whole if it can, breaks the feature next, and ridges only as
  a last resort (`_find_carve_route(level)`).
- **Tests**: `tests/test_map_density.gd` checks 50 random seeds at Blight 0 and 9, then forces each
  layout over 20 seeds (route length and buildable cells within ±25% of the old medians 46 / 275,
  the bend, the obstacle floor, a median within 44–88) and each feature (placed, clear of the ends,
  ponds block without being obstacles, ruins are stone). `tests/test_environment.gd -- --layouts=<png>`
  renders the sheet; `-- --seed=N --preview=<png>` renders one map with the void and lighting.
- **Guard**: a starting route over `max_route_length` (57) is trimmed back under it (`_trim_route_if_long`):
  plain obstacles first, then a ridge cell as a last resort, each time the cell that brings it just
  under the cap. Never the feature.
- Measured (2026-10-01, 20 seeds per layout; bands 35–57 route, 206–344 buildable):

  | Layout | Route | Buildable | Obstacles (median) |
  |---|---|---|---|
  | Corner | 39–57 (median 46) | 257–289 | 47–79 (66) |
  | Side, long axis | 37–49 (43) | 255–289 | 47–77 (69) |
  | Side, short axis | 37–56 (42) | 243–262 | 70–93 (80) |
  | Inlet | 36–52 (45) | 267–305 | 31–68 (51) |

  50 random seeds: 36–91 obstacles (mean 62) at Blight 0, 35–100 (69) at Blight 9. Every route bends.

### Inland Heartwood (spec, Environment Discussion, 2026-10-01)

User (via the design chat): "move the Heartwood out of the outer edges, put it in the outer half from
where the start is, in a random position." The start stays on the island's edge; the Heartwood moves
inland. This replaces the Heartwood half of the layouts above.

1. **Layouts describe only the start.** Two kinds remain, about 50/50: **corner start** (1–4 cells in
   from a corner, any of the 4 corners, along either edge) and **side start** (mid-edge ±3, any of the
   4 edges). **Inlet goes away**, because the Heartwood is never on an edge any more. Rename
   `MapLayout.end` as `heartwood` (or keep `end` with a comment) and drop the end-edge logic.
2. **Heartwood placement**, random per seed, rolled from the map rng right after the start:
   - **Far half:** split the map by the line through its centre perpendicular to start→centre, and keep
     the half without the start.
   - **Inland:** at least 2 cells from every edge (x 2–20, y 2–15 on the 23×18 map).
   - **Far enough:** straight-line distance from the start of at least **50% of the map's diagonal**
     (about 14.6 cells). 50% rather than 55%, because from a mid-edge start on the short axis 55% leaves
     only the two far corners. If no cell qualifies, take the farthest candidates.
   - Pick uniformly among the cells that qualify, so it really lands in different spots.
3. **The glade:** the 8 cells around the Heartwood (chessboard 1) never get obstacles, ridges or a
   feature. Wardens can be built there, so the player can wall it in on some sides and make nightmares
   walk round to an open one. That approach from several sides is the new tactical layer. The
   existing rule still stands: never fully cut off the route.
4. **Generation order:** start → Heartwood → glade → ridges → feature → scatter. Ridges run across the
   start→Heartwood direction (the axis they use now). The guaranteed bend, the carve and trim guards,
   `max_route_length` and the opening-route band (35–57) must still hold. Features keep
   `feature_clearance` from both ends and never touch the glade.
5. **The island:** the rim is now closed everywhere except the start (no open rim cell for the end).
   Cliffs, the bridge and the mist are unchanged.
6. **Visuals:**
   - **The canopy:** the 128×128 Heartwood sits on its cell and its canopy overhangs the row above and
     half a cell on each side. With the y-sort, anything on the 3 cells above it is drawn behind the
     canopy. When a Warden or nightmare is behind it, fade the canopy to about 50% so it stays visible.
     A tap on a cell behind the canopy selects that cell, not the Heartwood (touch-friendly).
   - **Light:** check that the warm light, the leaf-loss stages and the close-call glow still read
     against open grass. The warm centre and cold edge of art_direction.md fit better now.
   - **Pointers:** `CloseCalls`, `LeakEffect`, `BossDossier`'s "at the Heartwood",
     `EnvironmentAmbience.heartwood_position`, the H hotkey, the opening camera framing and the
     Whispers glide must all follow the new position.
7. **Checks:**
   - `test_map_density` per start kind: route band, buildable band, bend, obstacle floor.
   - New: the Heartwood is inland, in the far half and far enough, and its glade is clear.
   - Bump RunSaver VERSION.
   - Re-render `tools/previews/map_layouts.png` with the Heartwood marked.
8. **Balance:** routes no longer end at an edge, and nightmares can arrive from several sides. Tell
   Balancing Discussion when it lands.

### Inland Heartwood (as built, 2026-10-01)

- `MapLayout` now only places the start: `CORNER` / `SIDE` (50/50, any edge; `short_side` = the start
  is on the top or bottom edge), then `_pick_heartwood` rolls `end` (the Heartwood) from the same rng:
  inland (`EDGE_MARGIN` 2), the far half, at least `MIN_DISTANCE_SHARE` 0.5 of the diagonal away, else
  one of the `FALLBACK_COUNT` (6) farthest (`heartwood_fallback`; no test seed needed it). Inlet and its
  spine are gone. `ridge_axis` follows start→Heartwood (ridges across the larger of the two
  directions).
- Ridges sit on rows between the start's and the Heartwood's (`RIDGE_END_GAP` 3 from each, so none
  reaches the glade), up to 3 (+1 at Blight 9) as fit, the first nearest the start; the bend rule is
  unchanged. Tree groves are thinner (density 0.08–0.16) to pay for the third ridge.
- `MapGenerator.get_glade_cells()`: the 8 around the Heartwood join the generation skip list, so no
  ridge, feature, tree or rock lands there (Wardens can). The rim is closed except the start (the rim
  under the start only; the Heartwood stands on a plain path tile on grass).
- **Route floor** (`_extend_route_if_short`, `min_route_length` 35): an inland Heartwood can sit
  close, so a short opening route gets a plain tree or rock (clearable) on the route cell whose
  blocking lengthens it most, staying under 57 and keeping a way through; never the start, the
  Heartwood or the glade. With `_trim_route_if_long` the band is held both ways.
- `Heartwood`: fades (`self_modulate`, so not its light) to 50% when a Warden or nightmare is on the 3
  cells behind it (`is_something_behind`); it takes no input, so taps there pick the cell. CloseCalls,
  LeakEffect, the H hotkey, the Whispers glide, `EnvironmentAmbience.heartwood_position` and the lights
  already read the Heartwood's live position; `GameCameraNode` now opens framed halfway between the
  start and the Heartwood. BossDossier only has text ("at the Heartwood").
- Ponds and ruins get up to 120 of 160 placements near the route (a ruin is a bulky ring).
- Measured (20 seeds per start kind; bands 35–57 route, 206–344 buildable):

  | Start | Route | Buildable | Obstacles (median) |
  |---|---|---|---|
  | Corner | 36–51 (median 39) | 260–294 | 41–75 (61) |
  | Side | 36–54 (median 44) | 240–283 | 52–95 (76) |

  50 random seeds: 48–94 obstacles (mean 69) at Blight 0; every Heartwood inland, far half, far
  enough, glade clear; every route bends. Ponds near the route on 7 of 8 seeds, ruins 6 of 8.
  RunSaver VERSION 9.


### Heartwood's Gifts (experiment/spire-difficulty, heartwood_gifts.md)

Map pieces the act-break gifts place, one set per act folder like the rest.

| File | Size | Layout | Use |
|---|---|---|---|
| `lightning_tree.png` | 384×128 | 4 frames of 96×128, the Withered Tree format (bottom 64 px rows centred on the cell) | Lightning Tree (an obstacle): a split, scorched dead tree with a charred cleft and Wraithlight static in its bark that flickers; a spark jumps between its tops on frame 2 |
| `moonwell.png` | 256×64 | 4 frames of 64×64 | Moonwell (an unbuildable lit cell): a waystone ring with still water holding the moon's wobbling reflection, moonlight motes rising |
| `bell_stone.png` | 256×64 | 4 frames of 64×64 | Bell Stone: a standing stone with a bronze bell in its hollow, a rune that glows gold as it sings, a ring of sound spreading beside it |
| `mushroom_ring.png` | 768×192 | 4 frames of 192×192 (one 3×3 patch), transparent but the ring | Mushroom Ring (a ground patch under Wardens): a fairy ring of lush moss with 15 toadstools whose caps breathe a glow out of step |
| `heartwood_roots.png` | 1024×64 | 16 columns = the path's neighbour mask, transparent overlay | Heartwood Roots: two gnarled warm root strands per path side meeting in a knot, glints of gold sap; drawn over the path tile, joins across cells |
| `bog_path.png` | 1024×64 | 16 columns = neighbour mask, replaces `path.png` on its cells | Mire: the path's shape turned to dark peat with still puddles, reeds and a wet dark edge |
| `ancient_stump.png` | 192×64 | 3 variants of 64×64 | Ancient Stump: a broad cut stump with its year rings, roots and a little moss, flat enough to plant a Warden on |

## Half-cell grid: environment plan (Environment Discussion, 2026-10-04)

For half-cell placement (`half_cells.md`; experiment/half-cells → main once the user confirms). The pathing grid
becomes 32 px (46×36). Wardens take a 2×2 half-cell footprint at any half offset. Nightmares fit through a corridor of
one half cell (since 04c10c33). **Rule of thumb: only the player's Wardens (and so the route) live on the half grid. Everything
the world places stays on whole 64 px cells.**

### 1. Path art: a dual-grid autotile at 32 px
The prototype's soft ribbon is a stand-in. The final path is drawn with the **dual-grid** method, because a
neighbour-mask tile per cell can't draw half-step corners and staggered edges:
- **Data:** every 32 px half cell is *path* or *not*. ~~The 2×2 body at each route point~~ **Update 2026-10-04
  (half_cells.md 04c10c33): nightmares fit through one-half (32 px) gaps.** The drawn path is the route's **body
  where there's room, narrowing to a one-half ribbon only where the walls squeeze it**. For each route point, the
  2×2 body block is path if all 4 of its half cells are walkable; otherwise only the route's own half cells are. So
  open ground shows the usual broad path, and a pinch between staggered Wardens visibly narrows: the art tells the
  player "they squeeze through here". Wear-away (`wear_away`) erases decorations on every whole cell a path half
  touches.
- **The art must work at both widths:** a broad path, a **one-half-wide ribbon** (masks 3/6/12/9 on both sides of a
  32 px strip, which need edge art thin enough to leave visible earth in the middle), single-half jogs, a single
  isolated half (the 4 single-corner tiles 1/2/4/8 together form a small round patch), and the diagonal masks 5 and
  10 drawn as **two separate corners**, never a bridge (nightmares don't move diagonally).
- **Display:** a second layer offset by 16 px (half a half cell). Each display tile looks at its 4 corner half cells
  (path or not) and picks 1 of **16 tiles** (marching squares). Corners round off, half steps get a soft jog, and
  staggered edges join with no seams. The path stays the palest thing on the map.
- **Art (Environment Assets): `path_dual.png`**, 16 tiles of 32×32 in mask order (TL=1, TR=2, BR=4, BL=8), plus 3 extra
  variants of the full tile (mask 15) so long stretches don't repeat. The same moonlit earth, worn grass edge and
  pebbles as `path.png`, for all 4 act folders. `bog_path` (Mire) and `heartwood_roots` (overlay) get dual versions
  too: `bog_path_dual.png` and `heartwood_roots_dual.png`. `path.png` stays for the rope-bridge join at the start.
- **Code (Environment Code):** `PathGenerator.draw()` fills a 46×36 path mask and draws the dual layer (one
  TileMapLayer at 32 px with a 16 px offset, z −1 as now). The route mist, route arrows and previews keep following
  the route's points. The ghost's "+N path" and route previews draw the same way.

### 2. Map generation: whole cells
Obstacles, ridges, features (pond, ruin, grove, log), the start, the Heartwood and its glade stay on 64 px cells.
- **Why:** variety now comes from the player's staggered walls. Half-offset obstacles would leave 1-half-cell gaps
  ("too narrow") all over the map, which would make the guaranteed-route, bend and trim rules fiddly. The 64 px
  obstacle art and clearing marks also fit whole cells.
- **Checks:** generation measures the route in whole cells (as `test_map_density` already does on the branch). Full-cell
  obstacles always leave corridors at least 2 half cells wide.

### 3. Gift terrain: whole cells
Sow a Ridge, Fallen Giant, Glade / Deeper Glade, Shift Stones, Mire, Spring, Mushroom Ring, Lightning Tree, Moonwell,
Bell Stone, Ancient Stump and Heartwood Roots all place on whole cells, with their art unchanged.
- **The ghost snaps to whole cells,** unlike a Warden's half snap, which also tells the player "this is land, not a
  Warden".
- **Overlaps:** a gift cell is blocked if any Warden half cell overlaps it. A Warden at a half offset may stand
  half-on a lit or rooted cell (Moonwell, Mushroom Ring, Ancient Stump); it counts as on it if its **centre's whole
  cell** is that cell (the same rule as ranges and auras, `Tower.cell`).

### 4. Tall sprites, fades and the glade
- **Y-sort:** a Warden sorts by its footprint centre, which can sit on a half row. Trees and the Heartwood sort by their
  cell centre. That works as it is.
- **Fades:** `TallObstacleFade`, the Heartwood's canopy fade and tall Wardens count "something behind" when **any of a
  Warden's 4 half cells** (`Tower.get_halves`), a nightmare's position, the ghost or the hover falls in the overhang
  cells. A Warden half under a canopy fades it.
- **Glade:** still the 8 whole cells around the Heartwood, kept free of obstacles and gift terrain. Wardens may stand in
  it at any half offset, so the player can wall it in more tightly.
- **Kept:** the 50% fade, touch selection by the cell or half cell tapped, and the Heartwood never takes input.

### Order
Art can start now (it doesn't depend on the merge). The code starts after half cells reach main. Then re-render
`map_layouts.png` and a half-cell preview with staggered walls.
## Notes

- Colours (2026-09-30, to fit the title and Memory Grove screens): the ground is night-indigo with a moss grain (act 1–2 moss/teal, act 3 violet with rust, act 4 frost), the dead trees are cool night bark with a teal lit side and moss flecks (the Grove trunks), rocks stay lavender stone. Warmth is only the path, the Heartwood and the Wardens.
- The Heartwood uses the same warm moss-gold in every act; only its surroundings change.
- Sprites (trees, obstacles, Heartwood) include their own soft ground shadow.
- **Regenerating** (`tools/environment_art/`): `powershell -File tools/environment_art/export.ps1`
  from the project folder, then Godot `--import`. It runs the generator (`heartwood_grounds.html`,
  fixed seed 1207, with `export_tail.js`) in headless Chrome, then `process_environment.gd` puts every
  sheet through Theme Code's `DetailPass` and `HeartwoodPalette` (`tools/art/`) into
  `assets/environment/`: ground tiles in the pass's calm mode with no added grain (the AI-look audit,
  2026-10-04; it was 0.3 on most ground tiles), full detail on obstacles, 96×128 tree cells, palette snap only for mist, void,
  cloud shadows and the Heartwood (drawn with its own rim and banded glow; redrawn 2026-09-30 to
  match the Memory Grove's Heartwood). It prints the value order per act and fails if it breaks. A run
  on unchanged sources reproduces the committed sheets byte for byte. Only PNGs are written (UIDs stay).
  To change the art, change the generator, re-run, and keep this table in sync.
