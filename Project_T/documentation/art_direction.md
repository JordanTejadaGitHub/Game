# Art Direction

Phase 4, topic 12 of `design_plan.md`. **Draft, started 2026-09-27** from the dark fairytale retheme
(`story.md`). Covers the visual rules every art session follows; audio direction is still to do.

## The one rule: warm vs cold

**The dream is warm; the nightmares are cold.** Wardens and the Heartwood carry warm light (gold,
moss green, amber); nightmares and the forest's edges are cold dark (blue-black, violet, mist).
Every screen should show that contrast, even in a thumbnail. Unsettling, never gory: no blood,
bodies or skulls-and-gore horror.

## Environment

Concept reference: the Environment Assets session's artifact page
(https://claude.ai/artifact/DhTsE8rJXJwU3UgYEL73ym). Not in the repo yet; tiles get made from it.

- **Warm centre, cold edge.** Darker, cooler night palettes on the tiles, then a lighting pass: a
  cold multiply toward the map edges, warm light on the Heartwood, a small warm light on each Warden.
  In Godot: a `CanvasModulate` plus `PointLight2D`s.
- **One palette per act** (the season changes at each act break, `run_design.md`):

  | Act | Season / mood |
  |---|---|
  | 1. Forest's Edge | spring dusk |
  | 2. Deep Wood | summer night |
  | 3. Misty Hollow | autumn fog |
  | 4. Heartwood Glade | winter dark |

- **Readability order (value):** dark ground < pale obstacles < **palest path**. The path is pale,
  moonlit earth and must always be the most readable thing on the map.
- **Obstacles:** the **Withered Tree** is pale dead bark with dark smoke at its roots and two
  knot-holes that sometimes glint like eyes. **Blight Patch** is violet-black rot. The **Mossy
  Boulder** stays a readable pale shape.
- **The start:** mist at the start cell, with pale eyes that open now and then. Dark fog drifts
  along every map edge.
- **The Heartwood:** a fixed warm moss-gold canopy in every act. It shows **leaves lost (0–20)**:
  each lost leaf blackens a patch of canopy, black leaves fall, and its hollow and warm light dim.
  The player should feel the damage by looking at the tree, not just the counter.

## Wardens

- **Cute and charming**, built on the user's golem mock (`tools/tower_art_generator.gd`; 64×64,
  thick stepped base, outline, banded shading, 8-frame idle, 6-frame attack).
- **Attacks glow warmly:** golden glow on every projectile and attack; lightning is gold, rain and
  fog are warm-lit, spores sunlit, pulse rings have a warm inner band. They read as *light pushing
  back the dark*.
- **The Sporeling is the mascot** (capsule art, first run).

## Nightmares

Full brief per nightmare in `enemy_design.md` ("Art direction" and the "Looks like" column).

- **Dark, cold, partly translucent**, with a violet rim and glow only in the eyes or core.
- **One strong silhouette per nightmare**, tied to its trait.
- **Wrong movement:** gliding, twitching, stop-start, heads turning.
- **Dispel:** cracks of light, then a burst of motes that drift up as Dew.
- **The darkness is in the art, not a filter.** Nightmare sprites (committed 2026-09-27; files still
  use the old names, e.g. `leaf_bug` = Shade) are drawn dark. The shader must **not recolour or
  darken** them (that flattens their shading to black); it only adds partial translucency, a subtle
  shimmer, and the dispel effect.

## Still to do

- **Audio direction:** music per phase (build, drift with dread building, boss, Grove, title),
  nightmare whispers and a signature sound per type, the dispel sound, the leaf-lost sound.
- **UI style:** frames, cards, fonts, icons (the shape-based icon language in `screens_ui.md`).
- **Accessibility pass:** make sure warm vs cold never relies on colour alone.
