# Art Style Options

Companion to `art_direction.md`. **Draft, 2026-09-27; leaning toward Waystone pixel** (see Decision). Six candidate rendering
styles for the whole game, all shown on the same tiles, Wardens and nightmares on the concept page
(https://claude.ai/artifact/DhTsE8rJXJwU3UgYEL73ym, "Art style" switch above the maze and the
"Six art directions" comparison). This doc is for choosing a direction; nothing here is implemented.

Every option must keep the rules in `art_direction.md`: warm dream vs cold nightmares, value order
dark ground < pale obstacles < **palest path**, unsettling never gory, nightmares dark in the art
itself. All options use a 64×64 cell.

## At a glance

| # | Style | Detail | Tones | Lines | Signature | Redraw needed |
|---|---|---|---|---|---|---|
| 1 | **Waystone pixel** (current) | 64 px | 4–5 per ramp, light dithering | dark outline in the object's darkest shade | clean, detailed pixel art | none |
| 2 | **Storybook chunky** | 32 px shown at 2× | 3 flat | outline in a darker shade of the object's own colour | bold, soft, warm | everything at 32 px |
| 3 | **Papercut** | 64 px | 3 flat | none | light cut edge + small offset shadow, muted paper tint | everything |
| 4 | **Woodcut ink** | 64 px | 3 flat, cross-hatched shadows | heavy 2 px ink | old fairy-tale book engraving | everything |
| 5 | **Lantern 16** | 64 px | whatever the palette allows, dithered | dark outline | one fixed 16-colour palette for the whole game | recolour only |
| 6 | **Stained glass** | 64 px | 3 flat, jewel-toned | dark lead at every colour change | a window lit from behind | everything |

## 1. Waystone pixel (current)

- **Look:** full 64 px detail, 4–5 tone ramps lit from the top left with light ordered dithering,
  outlined in a dark shade of the object's own colour. The look of the existing Wardens and nightmares
  (`tools/tower_art_generator.gd`, the golem mock).
- **Good:** nothing needs redrawing; the most room for detail and animation.
- **Cost:** the busiest option; a crowded maze reads less clearly when zoomed out on a 45×36 map.

## 2. Storybook chunky

- **Look:** art drawn at 32 px and scaled 2×. Three flat tones, no dithering, colours a little
  warmer and softer (saturation ×0.82, lifted slightly toward cream). Each object is outlined in a
  darker shade of its own colour rather than a dark line.
- **Good:** bold shapes that stay readable zoomed out; soft, warm Wardens stand out well against the
  dark.
- **Cost:** Wardens and nightmares must be redrawn at 32 px; less room for fine detail (eyes,
  faces, small effects).

## 3. Papercut

- **Look:** full resolution, flat three-tone shapes, **no outlines**. Each object has a light cut
  edge on its top-left and a small offset shadow (2 px down-right), like layered paper. Colours muted
  (saturation ×0.68) with a warm paper tint.
- **Good:** the calmest and most distinctive; shapes separate by value and shadow instead of lines.
- **Cost:** furthest from pixel art; every character needs redrawing; nightmares rely on their
  shadows to stand out on dark grass.

## 4. Woodcut ink

- **Look:** an engraving in an old fairy-tale book. Colours muted toward cold ink (saturation ×0.5,
  blue-violet tint). Dark areas are **hatched** with diagonal lines, the darkest cross-hatched; light
  areas stay clean. Every object has a heavy **2 px ink outline**. Wardens keep their full warm colour:
  they are the light.
- **Good:** the most dark-fairytale option; hatching makes the edges feel old and sinister with no
  gore, and it holds up in a thumbnail. The clean pale path reads first.
- **Cost:** the darkest style, so warm light has to carry more; hatching can get noisy at high zoom;
  characters need redrawing with hatching and thick lines.

## 5. Lantern 16

- **Look:** every pixel in the game (tiles, Wardens, nightmares, effects) comes from **one fixed
  16-colour palette**, with dithering between neighbouring colours:

  | Group | Colours |
  |---|---|
  | cold darks | `#0c0a12` ink, `#1e1830` deep violet, `#3a2e52` violet, `#2a3a5a` night blue, `#5a5a8a` dusk |
  | greens | `#1c3024` deep moss, `#3a5a34` moss, `#6e8a4c` sage, `#4a8a8a` teal |
  | earth | `#4a3024` bark, `#8a4a2a` rust |
  | warm light | `#e8b84a` gold, `#fff0b0` pale gold |
  | stone and bone | `#8f89a8` stone, `#d8ccb8` bone, `#f4f0ff` moonlight |

- **Good:** guaranteed cohesion; new art can't drift off-palette; gold appears only where the dream
  is. The cheapest way to change the look: existing art is recoloured, not redrawn.
- **Cost:** strict; the four act palettes collapse toward the same colours, so seasons differ less
  (they'd lean on lighting and props instead). Some nuance lost in existing art.

## 6. Stained glass

- **Look:** flat, jewel-toned areas (saturation ×1.3, three tones) separated by dark **lead lines**
  wherever the colour changes, plus lead around every object. No other outlines. The dream as a chapel
  window of the Heartwood, lit from behind.
- **Good:** striking and unlike other tower defence games; warm light makes it glow.
- **Cost:** busy: lead at every colour change adds noise, including inside the path, so path and
  nightmare readability need careful value control. Furthest from the current art; everything needs
  redrawing.

## How to choose

- **Zoom out test:** look at the full map at the smallest zoom. Is the path still the first thing you
  see? Can you pick out a nightmare on dark grass?
- **Thumbnail test:** a Steam capsule-sized screenshot must still show warm vs cold.
- **Cost:** 1 and 5 keep the existing Warden and nightmare art; 2, 3, 4 and 6 need everything redrawn.
- **Mixes are allowed**, e.g. Storybook's 32 px shapes with Woodcut hatching, or any style limited to
  the Lantern 16 palette.

## Decision

**Leaning: 1. Waystone pixel** (2026-09-27, user's preference; not yet final). **2026-09-28:** the user wants to stay with pixel art; six pixel-only looks rendered from the real sprites are compared at https://claude.ai/artifact/SAodZ4uHZR6QcQ4tN3gx2y (Waystone, Hi-bit glow, Chunky 32, Lantern 16, Chunky Lantern, Ink dither; the design chat recommends Waystone plus a ~32-colour master palette). The decision moves to a dedicated **theme chat**. It keeps the existing
Warden and nightmare art, so no redraw is needed. The other five stay here as references in case the
look is revisited. When it's final, record it in `art_direction.md`.
