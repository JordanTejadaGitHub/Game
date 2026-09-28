# Art Direction

Phase 4, topic 12 of `design_plan.md`. **Draft, started 2026-09-27** from the dark fairytale retheme
(`story.md`). Covers the visual rules every art session follows; audio direction is still to do.

## The one rule: warm vs cold

**The dream is warm; the nightmares are cold.** Wardens and the Heartwood carry warm light (gold,
moss green, amber); nightmares and the forest's edges are cold dark (blue-black, violet, mist).
Every screen should show that contrast, even in a thumbnail. Unsettling, never gory: no blood,
bodies or skulls-and-gore horror.

## Rendering style

Six candidate styles are compared in **`art_style_options.md`** (Waystone pixel, Storybook chunky,
Papercut, Woodcut ink, Lantern 16, Stained glass), each switchable on the concept page.

### Decision (2026-09-28): Waystone pixel, detailed 64

**Final.** We keep the current Waystone pixel look at **64×64 per cell** and add more detail within
those 64 pixels. We don't redraw at 128. The comparison page
(https://claude.ai/artifact/L3HVzecXZZLdogJKHtkuvy) showed that with the whole map on a 1080p
screen a cell is about 58 screen px, so 128 px art gets shrunk and its detail is lost. Going to 128
would also mean redrawing every sheet and using 4× the texture memory, which hurts the mobile port.
Detail added at 64 shows at every screen size.

**The detail pass.** Every art chat applies it to its generator; the page's "Detailed · 64" column
is the reference (made automatically; hand-tuned generator art should do better).

- **Light from the upper left.** Each material gets at least three tones: light, base and shadow.
  Add a **1 px rim of light** on the upper-left inside edge: warm gold on Wardens and the Heartwood,
  violet on nightmares, pale on obstacles. Keep the dark outline.
- **Dithered shading.** Where two shading bands meet across a large flat area, add a 1 px checker
  seam between them. Don't dither small parts; they turn to noise.
- **Material texture, used sparingly** (about 1 pixel in 10 at most): moss and leaf clumps with a
  shadow under each, vertical bark grain, stone speckle and hairline cracks, pebbles on the path,
  grass blades.
- **Banded glow.** Warm lights glow gold (lanterns, fireflies, the Heartwood's hollow and fruit), and
  nightmare eyes and cores glow cold. The glow is a 1–2 px halo in 2–3 alpha steps, never a soft blur.
- **Nightmares:** a few cold motes inside the dark body, and a ragged, smoky lower edge where the
  silhouette allows it.
- **Readability comes first.** The value order below (dark ground < pale obstacles < palest path)
  and each silhouette must survive the pass. If detail muddies a sprite at 58 px, remove it.

**Exceptions:** the Heartwood stays 128×128 (2×2 cells). The Steam capsule, key art and trailer
close-ups are separate showcase art and can be drawn at a higher resolution.

### Decision (2026-09-28): the Heartwood 32 palette

**Final.** Every piece of game art uses only these 32 colours: Wardens, nightmares, effects, tiles,
meta art and UI. Art comes from several chats, and one shared palette is what makes it match.
Reference page, applied to all 108 existing Warden and nightmare sprites:
https://claude.ai/artifact/BbGHs9cDsKvm8kZEDH1Bra

| Ramp (dark → light) | Colours | Used for |
|---|---|---|
| Ink | Void `#05050d`, Night `#24243c`, Dusk `#3c3c5c`, Slate `#5c5a78` | outlines, shadows, the night sky |
| Nightmare | Dread `#140f26`, Shade `#2c2444`, Bruise `#4c3c74`, Wraithlight `#9a84e8` | nightmare bodies, rims, cold glow |
| Stone & moon | Stone `#8c8cac`, Mist `#b4b0c8`, Moonlight `#dce8f4` | boulders, mist, cold highlights, eyes |
| Moss | Deepmoss `#1c3c2c`, Moss `#34643c`, Leaf `#5c944c`, Sprig `#9cc46c`, Newleaf `#d4ec9c` | ground, leaves, the canopy |
| Bark | Root `#241c14`, Bark `#5c3c24`, Oak `#8c5c34`, Deadwood `#bca48c` | trunks, roots, dead trees |
| Path | Loam `#6c5c5c`, Path `#b4a494`, Moonpath `#dccdb2` | the path; Moonpath is the palest ground |
| Warm light | Ember `#b8662c`, Gold `#e9a83c`, Glow `#fcd47c`, Heartlight `#fff4dc` | attacks, the hollow, dream-fruit, fireflies |
| Blossom | Orchid `#bc44dc`, Blossom `#ec9cf4` | Sporeling and flower Wardens |
| Dew | Pool `#2c4c5c`, Dew `#4c8ca4`, Dewlight `#9cd4fc` | water Wardens, jars, dew pools |

- **Pick colours by name, never raw hex.** Generators read the shared palette file (once it
  exists) and snap every pixel they write to the nearest palette colour (OKLab distance).
- **Nightmares use only the cold ramps:** Ink, Nightmare, Stone & moon and Dew. No warm colour
  ever lands on a nightmare.
- **Glow and translucency** use palette colours with alpha steps (Gold, Glow, Wraithlight).
- **The value order holds:** Deepmoss ground < Stone obstacles < Moonpath.
- **The acts' seasons** come from the lighting pass (`Seasons` / `EnvironmentLighting` tinting),
  not from extra colours. If an act later needs its own ground colours, it can add at most 4 and
  record them here.
- **UI (Moonlit Thread)** uses the same Ink, Moonlight and Gold ramps.
- **Exempt:** the Steam capsule, key art and trailer (showcase art), and third-party packs that
  aren't used in the game.

## Environment

Concept reference: the Environment Assets session's artifact page
(https://claude.ai/artifact/DhTsE8rJXJwU3UgYEL73ym). **Sheets now exist** (Waystone pixel, one
folder per act, 16 sheets each): `assets/environment/<act>/`, with layouts in
**`environment_assets.md`** (e.g. `path.png` columns = neighbour mask, `heartwood.png` rows = leaves
lost 0–20). They're wired into the map (`EnvironmentTiles`), with the lighting pass below (`EnvironmentLighting`, `EnvironmentAmbience`, the Heartwood's glow).

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
- **The Heartwood** (redesigned 2026-09-27 on the concept page): a slowly twisting trunk with bark
  grooves and moss on its lit side; roots curling over a ring of moss; the hollow is an **arched
  doorway full of golden light**. A layered canopy (a darker back layer, front clusters of small
  leaf clumps) with twinkling dream-leaves; **vines hang from beneath it, each ending in a glowing
  dream-fruit**; the whole tree sits in a soft warm halo. The canopy stays warm moss-gold in every
  act.
- **Damage shows on the tree** as **leaves lost (0–20)**: ragged violet-black rot patches with ash
  flecks spread across the canopy and black leaves fall, the **dream-fruit darken one by one**, and the halo and the hollow's
  light dim. The player should feel the damage by looking at the tree, not just the counter.

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

- ~~Audio direction~~: done in `audio_direction.md`.
- ~~UI style~~: decided 2026-09-28, **Moonlit Thread** (fog panels, a 1 px gold thread with a
  hollow diamond, Cormorant Garamond / Cormorant SC / Alegreya Sans, pixel icons scaled by whole
  numbers). The spec is in `ui_style.md` (owned by the UI Asset chat); icons keep the shape-based
  language in `screens_ui.md`. UI colours come from Heartwood 32 (Ink, Moonlight and Gold ramps).
- **Accessibility pass:** make sure warm vs cold never relies on colour alone.
