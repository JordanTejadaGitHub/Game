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
| `grass.png` | 512×64 | 8 variants: 0 plain, 1/4/6 tufts, 2 flowers, 3 clover, 5 pebbles, 7 fallen twig | ground; any variant tiles with any other. Each has its own grain (the sheet goes through the detail pass as one image with no added grain: texture 0, the user's pick), so the ground doesn't repeat. Shares: `GroundGenerator.GRASS_WEIGHTS` |
| `path.png` | 1024×64 | 16 tiles, **column = neighbour mask** (N=1, E=2, S=4, W=8) | the creature path; e.g. column 5 = N+S straight, 15 = crossroads |
| `path_rim.png` | 1024×64 | 16 tiles, **column = neighbour mask** like `path.png` | the path on the start and goal cells, which sit in the rim ring: the same path, transparent outside it (no grass border). Draw it over the matching `island_edge` tile so the rim's earth runs up to the path |
| `border_wall.png` | 128×64 | 2 variants, seamless | the map's stone border |
| `withered_tree.png` | 384×1152 | **96×128 cells** (bigger since 2026-09-30): the bottom 64 px rows, centred, are the cell (trunk base and shadow); the rest overhangs the cell above (64 px) and the sides (16 px each). Drawn from the 64 px designs with heights × 1.7 and widths × 1.3. 9 dead trees (rows) × 4 frames: 0–2 gnarled Withered Tree, 3 split trunk, 4 broken hollow snag (eyes glint), 5 weeping dead willow (strands sway), 6 dead pine, 7 dead birch, 8 thorn tree | obstacle, "Tend"; all 9 are in `tree.tres` |
| `tended_stump.png` | 64×64 | 1 | walkable mark left after Tend |
| `mossy_boulder.png` | 576×64 | 9 rocks, each about 68% of their first size (low in the cell with a shadow, clearly smaller than the trees): 0–1 Mossy Boulder, 2 slab stone, 3 cairn, 4 rock cluster, 5 split boulder, 6 lichen boulder, 7 carved boulder, 8 dream-crystal boulder | obstacle, "Move"; all 9 are in `rock.tres` |
| `moved_hollow.png` | 64×64 | 1 | walkable mark left after Move |
| `waystone.png` | 256×64 | 4 frames | proposed bonus build spot |
| `dew_pool.png` | 256×64 | 4 frames (frozen in winter) | proposed special tile |
| `blight_patch.png` | 256×64 | 4 frames | proposed special tile |
| `edge_mist.png` | 256×64 | 4 frames, transparent overlay | start cell / map edge mist |
| `tree_round.png`, `tree_pine.png`, `tree_flowering.png` | 64×64 | 1 each | scenery on cells the maze never uses |
| `ground_details.png` | 768×64 | 12 variants: the 4 kinds (column % 4: mushrooms, ferns, pebbles, leaf litter), each at 3 spots in the cell so a scatter never lines up on the grid | walkable decoration on about 30% of the cells in the noise's detail band (`DETAIL_SHARE`) |
| `island_edge.png` | 1024×64 | 16 tiles, **column = neighbour mask** (N=1, E=2, S=4, W=8: which neighbours are island) | the map's unbuildable rim (screens_ui.md): **no grass**, a sunken ledge of crumbled dark earth (value below the ground's; the pipeline checks it) whose open sides crumble and fade into the void, roots hanging off the lip, and a shadow step with overhanging grass where it meets the buildable ground; the south lip meets the cliff tops. Assumes a convex (blocky) island: no inner-corner tiles |
| `cliff.png` | 256×256 | columns: bit 1 = the cell to the west also has cliff, bit 2 = the east does; rows: 4 variants | cliff face under island cells whose south neighbour is void; transparent below its ragged, dripping underside |
| `heartwood.png` | 512×2688 | 128×128 frames: **row = leaves lost (0–20)**, 4 frames per row; the Memory Grove's Heartwood (twisted trunk, gold-rimmed mossy bark, the Hollow's light): rot spreads through the crown, a dream-fruit darkens per 4 leaves, the rim turns ember and the Hollow fades by 20 | the goal; anchor its bottom centre about 8 px below the goal cell's bottom centre, so it overhangs the cells around it |

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

## Notes

- Colours (2026-09-30, to fit the title and Memory Grove screens): the ground is night-indigo with a moss grain (act 1–2 moss/teal, act 3 violet with rust, act 4 frost), the dead trees are cool night bark with a teal lit side and moss flecks (the Grove trunks), rocks stay lavender stone. Warmth is only the path, the Heartwood and the Wardens.
- The Heartwood uses the same warm moss-gold in every act; only its surroundings change.
- Sprites (trees, obstacles, Heartwood) include their own soft ground shadow.
- **Regenerating** (`tools/environment_art/`): `powershell -File tools/environment_art/export.ps1`
  from the project folder, then Godot `--import`. It runs the generator (`heartwood_grounds.html`,
  fixed seed 1207, with `export_tail.js`) in headless Chrome, then `process_environment.gd` puts every
  sheet through Theme Code's `DetailPass` and `HeartwoodPalette` (`tools/art/`) into
  `assets/environment/`: no added grain on grass / island rim / dew pool / blight patch, 0.3 on the
  other ground tiles, full detail on obstacles, 96×128 tree cells, palette snap only for mist, void,
  cloud shadows and the Heartwood (drawn with its own rim and banded glow; redrawn 2026-09-30 to
  match the Memory Grove's Heartwood). It prints the value order per act and fails if it breaks. A run
  on unchanged sources reproduces the committed sheets byte for byte. Only PNGs are written (UIDs stay).
  To change the art, change the generator, re-run, and keep this table in sync.
