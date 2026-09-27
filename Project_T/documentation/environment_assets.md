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
a warm PointLight2D per attacking Warden), `heartwood.gd` (a warm light plus an additive glow over
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

| File | Size | Layout | Use |
|---|---|---|---|
| `grass.png` | 256×64 | 4 variants | ground; any variant tiles with any other |
| `path.png` | 1024×64 | 16 tiles, **column = neighbour mask** (N=1, E=2, S=4, W=8) | the creature path; e.g. column 5 = N+S straight, 15 = crossroads |
| `border_wall.png` | 128×64 | 2 variants, seamless | the map's stone border |
| `withered_tree.png` | 256×576 | 9 dead trees (rows) × 4 frames: 0–2 gnarled Withered Tree, 3 split trunk, 4 broken hollow snag (eyes glint), 5 weeping dead willow (strands sway), 6 dead pine, 7 dead birch, 8 thorn tree | obstacle, "Tend"; all 9 are in `tree.tres` |
| `tended_stump.png` | 64×64 | 1 | walkable mark left after Tend |
| `mossy_boulder.png` | 576×64 | 9 rocks: 0–1 Mossy Boulder, 2 standing stone, 3 cairn, 4 rock cluster, 5 split boulder with dead roots, 6 lichen boulder, 7 ruined waystone, 8 dream-crystal boulder | obstacle, "Move"; all 9 are in `rock.tres` |
| `moved_hollow.png` | 64×64 | 1 | walkable mark left after Move |
| `waystone.png` | 256×64 | 4 frames | proposed bonus build spot |
| `dew_pool.png` | 256×64 | 4 frames (frozen in winter) | proposed special tile |
| `blight_patch.png` | 256×64 | 4 frames | proposed special tile |
| `edge_mist.png` | 256×64 | 4 frames, transparent overlay | start cell / map edge mist |
| `tree_round.png`, `tree_pine.png`, `tree_flowering.png` | 64×64 | 1 each | scenery on cells the maze never uses |
| `ground_details.png` | 256×64 | 4 variants: mushrooms, ferns, pebbles, leaf litter | walkable decoration |
| `island_edge.png` | 1024×64 | 16 tiles, **column = neighbour mask** (N=1, E=2, S=4, W=8: which neighbours are island) | the dream's outer layer: the island's rim; transparent where the void shows. Assumes a convex (blocky) island: no inner-corner tiles |
| `cliff.png` | 256×256 | columns: bit 1 = the cell to the west also has cliff, bit 2 = the east does; rows: 4 variants | cliff face under island cells whose south neighbour is void; transparent below its ragged, dripping underside |
| `heartwood.png` | 512×2688 | 128×128 frames: **row = leaves lost (0–20)**, 4 frames per row | the goal; anchor its bottom centre about 8 px below the goal cell's bottom centre, so it overhangs the cells around it |

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

## Notes

- The Heartwood uses the same warm moss-gold in every act; only its surroundings change.
- Sprites (trees, obstacles, Heartwood) include their own soft ground shadow.
- Regenerating: the drawing code lives in the concept page; the files were exported from it with a
  fixed seed. To change the art, change the page, re-export, and keep this table in sync.
