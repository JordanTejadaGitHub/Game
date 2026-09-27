# Environment Assets

The original environment art that replaces the Foozle Spire tileset (`demo_scope.md`: "all art is
original"). Style: **Waystone pixel** (`art_style_options.md`). Direction: `art_direction.md`
(warm centre, cold edge; ground < obstacles < path in value). Created 2026-09-27 from the concept
page (https://claude.ai/artifact/DhTsE8rJXJwU3UgYEL73ym), seed 1207.

**In the game** (2026-09-27): `scripts/map/environment_tiles.gd` (`EnvironmentTiles`) builds one
TileSet from these sheets (one atlas source per file) that the ground, path and object layers share,
and swaps every sheet to the next act's folder at act breaks (`Seasons` → `MapGenerator.set_act`).
The Heartwood is `scripts/map/heartwood.gd`. Waystone, Dew Pool and Blight Patch have tiles in the
TileSet but aren't placed on maps (their rules are still proposals). The lighting pass isn't in yet.

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
| `withered_tree.png` | 256×192 | 3 variants (rows) × 4 frames | obstacle, "Tend" |
| `tended_stump.png` | 64×64 | 1 | walkable mark left after Tend |
| `mossy_boulder.png` | 128×64 | 2 variants | obstacle, "Move" |
| `moved_hollow.png` | 64×64 | 1 | walkable mark left after Move |
| `waystone.png` | 256×64 | 4 frames | proposed bonus build spot |
| `dew_pool.png` | 256×64 | 4 frames (frozen in winter) | proposed special tile |
| `blight_patch.png` | 256×64 | 4 frames | proposed special tile |
| `edge_mist.png` | 256×64 | 4 frames, transparent overlay | start cell / map edge mist |
| `tree_round.png`, `tree_pine.png`, `tree_flowering.png` | 64×64 | 1 each | scenery on cells the maze never uses |
| `ground_details.png` | 256×64 | 4 variants: mushrooms, ferns, pebbles, leaf litter | walkable decoration |
| `heartwood.png` | 512×2688 | 128×128 frames: **row = leaves lost (0–20)**, 4 frames per row | the goal; anchor its bottom centre about 8 px below the goal cell's bottom centre, so it overhangs the cells around it |

## Notes

- The Heartwood uses the same warm moss-gold in every act; only its surroundings change.
- Sprites (trees, obstacles, Heartwood) include their own soft ground shadow.
- Regenerating: the drawing code lives in the concept page; the files were exported from it with a
  fixed seed. To change the art, change the page, re-export, and keep this table in sync.
