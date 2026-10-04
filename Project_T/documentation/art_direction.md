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

**Final** (extended to 35 for Warden idle sheets on 2026-09-30, see Warden Night below). Every piece of game art uses only these 32 colours: Wardens, nightmares, effects, tiles,
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
  ever lands on a nightmare, with **one exception: stolen Heartwood light.** The Dream Thief's orb
  may be warm (Gold / Glow / Heartlight), kept small and composited after the detail pass. It reads
  as "that's ours, take it back". Nothing else qualifies: fire and embers on nightmares are cold
  ghost-fire (Wraithlight, Dewlight, Moonlight), e.g. the Ash Crawler's smoulder. Decided
  2026-09-28.
- **Glow and translucency** use palette colours with alpha steps (Gold, Glow, Wraithlight).
- **The value order holds:** Deepmoss ground < Stone obstacles < Moonpath.
- **The acts' seasons** come from the lighting pass (`Seasons` / `EnvironmentLighting` tinting),
  not from extra colours. If an act later needs its own ground colours, it can add at most 4 and
  record them here.
- **UI (Moonlit Thread)** uses the same Ink, Moonlight and Gold ramps.
- **Exempt:** the Steam capsule, key art and trailer (showcase art), and third-party packs that
  aren't used in the game.

### Enforcement (2026-09-30)

Everything in the game now uses the palette. All art in `assets/` is on it (no file more than 5% off;
the largest is the Dream Thief's allowed orb). Every colour set in code is too: `scripts/palette.gd`
(`Palette`) for game code, `UiStyle` tokens for UI. **`tests/test_palette.gd` fails** on any
off-palette colour literal in `scripts/`, `resource/`, or stored in scenes and resources.

- **Allowed outside the palette:** multipliers (modulate / self_modulate tints, the season and
  lighting tints, flashes, `EnemyData.tint`), the accessibility high-contrast route yellow (marked
  "Accessibility"), and the palette blends `UiStyle` generates in `assets/ui/ui_theme.tres`.
- **No red.** Warnings ("can't afford", invalid, penalty, Bittersweet, immune) use Ember. If
  playtesting shows they're too easy to miss, fix it with shape or motion before adding a colour.
- **Identifier sets** (statuses, families, Focus, rarity, damage types) each keep one distinct
  palette colour.

### Decision (2026-09-30): Warden Night, palette grows to 35

**Final** (the user confirmed it). The Wardens move **one shade darker inside their own ramp**, so they sit
in the fog instead of glowing on top of it. Each keeps its colour family: Sporeling stays pink,
Dewdrop blue, Acorn amber. The palette gains three colours that **only Warden idle sheets use**:

| Colour | Hex | Replaces | Why |
|---|---|---|---|
| Rosedust | `#b27aae` | Blossom | a dusty pink; the mascot stays pink but calmer |
| Plum | `#7a4a82` | Orchid | the matching shadow, less saturated |
| Nightbloom | `#6b6fb0` | Wraithlight | a bluer violet, so no Warden reads as a nightmare |

- **The full map, rules and files** are in `warden_night.md` and `assets/style_reference/warden_night/`
  (map json, 35-colour .gpl, all 70 Wardens before/after). Page:
  https://claude.ai/artifact/969uR9QxNS9D71h8gCDqdh
- **Idle sheets only.** Attack sheets, projectiles and glows keep full warm light: attacks are light
  pushing back the dark.
- **Nothing else uses the new three.** The Heartwood, nightmares, tiles and UI stay on the original 32.
  So does the **Heartwood Sapling**: it's a piece of the Heartwood and keeps its full glow (user,
  2026-09-30).
- **No more additions.** If the step down merges two lines a Warden needs, fix it by hand. The
  per-act ground allowance above is separate and still unused.
- Owners: Tower Assets applies the map to the Warden sheets. Theme Code adds the three colours to
  `HeartwoodPalette` and the palette export (a Warden-only set, so snapping other art never picks them).
- The Mistwood environment it was made to match is still a preview only, not adopted
  (https://claude.ai/artifact/R3v9xg1JhCoRXkRpob3twd).

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

  | Act | Season / mood | Ground (colour pass, 2026-09-30) |
  |---|---|---|
  | 1. Forest's Edge | spring dusk | night-indigo with moss grain |
  | 2. Deep Wood | summer night | night-indigo with moss / teal |
  | 3. Misty Hollow | autumn fog | violet with rust |
  | 4. Heartwood Glade | winter dark | frost |

- **Colour pass (2026-09-30, Environment Assets, 5d222a19):** the map now matches the title and
  Grove screens. The ground is night-indigo instead of saturated green. **Warmth on the map is only
  the path, the Heartwood and the Wardens.** All sheets are on Heartwood 32; no per-act colours
  were added.
- **Readability order (value):** dark ground < pale obstacles < **palest path**, and the island rim
  < the ground. The path is pale, moonlit earth and must always be the most readable thing on the
  map. Checked in every act after the colour pass.
- **Obstacles:** the **Withered Tree** is cool night bark with a teal lit side and moss flecks (like
  the Grove trunks), dark smoke at its roots, and two knot-holes that sometimes glint like eyes. It's
  drawn **96×128 px**, overhanging its 64 px cell like the Heartwood does; the cell and gameplay
  stay 64. **Blight Patch** is violet-black rot. The **Mossy Boulder** stays a readable pale
  lavender stone.
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
- **Every form must read apart from the one before it** (rule from 2026-10-01, after the user
  couldn't tell Lanternmoth and Beacon apart; Tower Assets fixed 25 branch → final pairs). The test:
  a grey silhouette at 32 px, side by side with its previous form. They must separate.
  - **First choice: a stronger 64×64 silhouette:** a new stance, crown or prop.
  - **Tall 64×96 finals are allowed but kept few.** There are 10 now: Beacon, Thunderhead,
    Wellspring, Elf Circle, Starcave, Snugroot, Grafted Elder, Midsummer, Puffball and Monsoon. The
    rise is narrow, about Beacon's width, and the top fades to 50% when the cell above holds a
    nightmare or the cursor, so the maze stays readable.
  - **New forms follow the same test**, Ascended included.

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

## Style references (updated 2026-10-04)

The hand-tuned references live in `assets/style_reference/` (notes in `style_reference.md`, made by
Theme Asset). Update requested by the user on 2026-10-04: players dislike games that look AI-made, so
the references show the game **as it is now** and steer every generator away from the usual tells.

### What the reference sheets must show (current state)

- **Warden Night:** Wardens one shade down their ramp; attacks and glows keep full warm light.
- **The silhouette rule:** a branch and its final side by side at 32 px in grey, including one of the
  10 tall 64×96 finals and its rise fading over a nightmare.
- **The new branch forms** (Phase 1 + 2): one pair per family as an example of "same family, new
  shape".
- **Emblems:** the family, branch and gift emblems (32 px art, shown at whole-number scales).
- **The route mist:** a pale Mist core inside Slate, a broken cold edge, soft strands. It reads on the
  pale path and on dark ground.
- **The inland Heartwood** with its four Grove stages (young → great old tree) in the same 128 px
  frame.
- **The act palettes:** night-indigo ground with moss (acts 1–2), violet with rust (act 3), frost
  (act 4); warmth only on the path, the Heartwood and the Wardens.

### Avoiding the "AI look"

| Do | Don't |
|---|---|
| **Readability first:** calm large flat areas and let shapes read; put texture where a material changes. | Grain or speckle spread evenly over everything. Calm the detail-pass grain on big flat areas (plinth tops, bodies, ground). |
| **Glow only as a signal:** an attack, a dispel, the Heartwood, a nightmare's eyes, something you can use now. | A soft glow on everything, or a halo round every sprite "for mood". |
| **Each form its own shape and pose:** stance, crown, prop, held differently (the silhouette rule). | One body template with a recolour and a hat; mirrored, perfectly symmetric poses. |
| **A few hand-made quirks on hero sprites:** a crooked smile, one ear bent, an asymmetric prop, a patch, a chipped plinth corner. | Flawless, evenly finished sprites where nothing is out of place. |
| **One light, one outline rule everywhere:** light from the upper left, a Night/Void outline, the rim at most half the edge, the same in every generator. | Light from different sides on different sheets; outlines that change weight or colour between chats. |
| **Colour from the palette with a purpose:** warm = dream, cold = nightmare, every material in its own ramp. | A generic purple-to-gold "magic" sheen, rainbow gradients, or violet on Wardens. |
| **Pixel-art discipline:** whole-number scales, no blur, no sub-pixel rotation, hard alpha steps. | Smooth gradients, mixed pixel sizes, anti-aliased edges on pixel sprites. |

### Hand-polish list

The most-seen sprites, where a human touch-up (commissioned or edited by the user) matters most.
Keep the size, palette and silhouette; add the quirks and fix anything that reads as generated.

1. **The starting Wardens:** Sporeling (the mascot), Firefly Jar and Dewdrop with their branches, plus
   Sprout and Thornwall (on the map every run).
2. **The act 1 boss**, the Hollow Stag, and the Shade, the most common nightmare.
3. **The Heartwood**, all four Grove stages and the damage rows.
4. **The title Warden** (the relit stone Warden, `c5468b4d`).

### AI-look audit (2026-10-04)

Checked against the do / don't table above. Every asset area was measured: share of noisy isolated
pixels ("grain"), partial-alpha levels, light direction, mirror symmetry, and the palette. The
most-seen sprites were then checked by eye. **What passed everywhere:** the palette (0 files off),
light from the upper left (lit the wrong way only in a few effects and Grove icons), no symmetric
"generated" poses on sprites, and no blur or smoothing inside sprites. **The main tell is uniform
grain and checker dither from the detail pass**, plus one design-level item.

Ranked by how often players see it:

| # | Where | What fails | Owner |
|---|---|---|---|
| 1 | **Ground tiles** (grass, path), every act | Grain soup: random speckle over the whole grass tile; the path is speckled too, and its edge is a soft dithered blob instead of a crisp, wobbly bank. | Environment Assets |
| 2 | **Wardens, idle and attack** | Checker dither across large flat body areas and plinth tops (screen-door look); stray colour patches (e.g. a blue patch on the Sporeling's right side); attack sheets are the grainiest of all (grain 0.19). Beacon and Thunderhead have big glow halos all the time; glow should mark the attack. | Tower Assets |
| 3 | **Design-level: the shared golem body** | The base Wardens and early branches are the same seated body, recoloured, with a hat. That's the strongest "template" tell. **Decided by the user (2026-10-04): one new golem pose per family**, after hearing the design chat, Tower Discussion and Tower Assets. It stays the golem look on the waystone plinth: the user had already rejected separate creatures ("still look like pre evolutions" → "keep the warden look all around but make it epic"). Bases and branches take their family's pose; finals keep their epic layer; Sprout stays the plain seated golem, the seed every family grows from. Each pose says the family's job: Pebbling squat and heavy, Sporeling round and hunched with its cap over the shoulders, Firefly Jar tall holding the jar up, Dewdrop leaning forward, Bellflower upright with its head bowed like a bell, Rootling low and wide with its feet rooted, Acorn broad and seated with its arms open, Nestling perched on the plinth's edge. Keep attack origins aligned (attacks.json). This comes after the calm-mode regeneration. | Tower Assets |
| 4 | **The in-run Heartwood** | Checker dither over the whole canopy and a dithered ground skirt. | Environment Assets |
| 5 | **The title Warden** (seen on every launch) | Screen-door dither on the dark body, camouflage-like moss blotches, scattered white dots, a dithered fuzzy base. | Title Screen |
| 6 | **The Memory Grove canopy** | Halftone dither over large areas; the same leaf clump stamped over and over; evenly spaced, identical hanging roots and vines. | Meta Game Asset |
| 7 | **Nightmares** (mostly good) | The Weeper's violet motes are too dense and read as blotches. The Lurker and Whisper Swarm are noisy by design (a swarm); keep that. | Enemy Assets |
| 8 | **Effects** (mostly good) | A few have many soft alpha levels (surge, carried storm, route mist end), closer to a blur than to hard steps. A few are lit from the lower right. Burst symmetry is fine for effects. | Tower Assets, Environment Assets (route mist) |
| — | **UI and emblems, obstacles, the Hollow Stag** | Pass: clean shapes, consistent light. | — |

**Root cause and first fix:** the detail pass (`tools/art/detail_pass.gd`, Theme Code) adds grain
and checker seams evenly. It gets a calmer mode first: grain only where materials change, no
checker seams across large flat areas, and fewer, harder alpha steps. Then each owner regenerates
and hand-fixes its items above, re-checks with the audit, and republishes its gallery.

### Brief for a human artist: Steam capsule and logo

Showcase art, exempt from the palette, but it must feel like the game.

**For now it's made in-house** (user, 2026-10-04: "Leave it AI for now, then I'll decide later").
Theme Asset makes the final capsule A in all 7 sizes and the logo to this brief and the "AI look"
rules. The brief stays here in case the user hires an artist later.

- **Concept: draft A, "the watchful Warden"** (the user's pick, 2026-10-04, over B and the A+B
  hybrid). The relit stone Warden from the title art, large, menacing rather than cute, lit warm
  against the cold dark, with the logo on the dark side. Nightmares (dark shapes, pinprick eyes) can
  press in from the cold edges. The maze hook is left to the screenshots and trailer.
- **One idea, big shapes:** it must read at 231×87 (small capsule). Warm centre, cold edges.
- **The logo:** hand-lettered or hand-drawn, not a stock fantasy font. It sits in the dark part of
  the image, and also works alone on a transparent background (library logo, at most 1280×720).
- **Deliverables:** every Steam size (header, small, main, vertical, library hero without text,
  library logo), plus a layered source file.
- **Avoid** all the "AI look" items above, and in particular a purple-gold glow over everything, a
  symmetrical hero pose, and over-rendered texture.
- **References:** Theme Asset's drafts on its gallery (https://claude.ai/artifact/1Mq111zHWpf3EbgsWwF6d8,
  "Steam capsule drafts"), `pitch.md` "Capsule art concept", and the title screen art.

## Still to do

- ~~Audio direction~~: done in `audio_direction.md`.
- ~~UI style~~: decided 2026-09-28, **Moonlit Thread** (fog panels, a 1 px gold thread with a
  hollow diamond, Cormorant Garamond / Cormorant SC / Alegreya Sans, pixel icons scaled by whole
  numbers). The spec is in `ui_style.md` (owned by the UI Asset chat); icons keep the shape-based
  language in `screens_ui.md`. UI colours come from Heartwood 32 (Ink, Moonlight and Gold ramps).
- **Accessibility pass:** make sure warm vs cold never relies on colour alone.
