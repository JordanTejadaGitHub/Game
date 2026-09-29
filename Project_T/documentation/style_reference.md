# Style reference: the detail pass done by hand

These are reference sprites for the art decisions in `art_direction.md` → "Rendering style" (Waystone
pixel, **detailed 64**, the **Heartwood 32** palette). Each one was redrawn pixel by pixel from its
current sprite and uses only the 32 palette colours, plus the alpha steps the palette allows. Every art
chat should match these when it applies the detail pass to its generator. The automatic "Detailed · 64"
column on https://claude.ai/artifact/L3HVzecXZZLdogJKHtkuvy is the baseline these are meant to beat.

Files are in `assets/style_reference/`. A `.gdignore` keeps the folder out of the game build.

| Example | Reference (64×64) | Sheet | Source |
|---|---|---|---|
| Warden: Sporeling (the mascot) | `sporeling.png` | `sporeling_sheet.png` | `towers/sporeling.png`, idle frame 0 |
| Nightmare: Shade | `shade.png` | `shade_sheet.png` | `creatures/leaf_bug.png`, walk-side frame 0 |
| Obstacle: Mossy Boulder | `mossy_boulder.png` | `mossy_boulder_sheet.png` | `environment/forest_edge/mossy_boulder.png`, rock 0 |
| Grass tile | `grass.png` | `grass_sheet.png` | `environment/forest_edge/grass.png`, variant 0 |
| Path tile (N+S straight, mask 5) | `path_ns.png` | `path_ns_sheet.png` | `environment/forest_edge/path.png`, column 5 |

**How to read a sheet:** each sheet has three columns: **the current sprite**, then the same sprite
**snapped to the palette with no other changes**, then **the hand-tuned reference**. The top row is at
4×; the bottom row is 1×, true size. `tiles_sheet.png` shows a 3×3 patch of tiles (grass | path |
grass) in the same three versions, so you can check the seams and the value order.

## What was done, per example

### Sporeling (Warden)
- **The light was flipped.** The old sprite was lit from the right. Now the upper-left of every form
  is lit: head, torso, arm, fist, feet and the two rocks.
- **Pink ramp:** Blossom base, Orchid shadow, Bruise only in the deepest creases (armpit, under the
  fist, under the feet). A **1 px Glow rim** runs round the upper-left edges and stops halfway down
  the torso. Running it the full length made a yellow outline. A 3 px **Heartlight** specular sits on
  the head.
- **A dither seam that follows the form:** the Blossom → Orchid boundary on the torso steps down
  diagonally, with a 2 px checker. A straight vertical seam read as a separate panel.
- **Face:** 2×3 px eyes with a Heartlight catchlight, Orchid blush, and a 4 px smile. It is still
  readable at 58 px.
- **Motes:** the pink spores are now warm sunlit motes: a Glow core with a Gold 30% halo (banded, no
  blur).
- **Plinth:** a Night outline all round, and a **Moonlight bevel** along the top face's front-left
  edge. The top face has softer Stone speckle and one Slate hairline crack. The upper slab's side is
  Stone and the lower tier is Slate, so the step reads. The right face has a Slate band under its
  top edge, dithered into Dusk. Moss clumps are lit Sprig / Newleaf with a Moss/Deepmoss underside.
  The old Wraithlight flower was **replaced with Blossom + Glow**, because violet belongs to the
  nightmares.

### Shade (nightmare)
- **It stays dark.** The body is Shade on top and Dread below. Violet appears only in the **rim** (a
  few Wraithlight pixels round the upper-left corner), the **eyes** and **three single-pixel motes**.
  A first attempt with a Bruise band across the back, plus a full-length rim, made the Shade look lit
  and friendly, so it was cut.
- **Eyes:** Moonlight pinpricks with Bruise glow pixels inside the head, plus a Wraithlight 55% → 30%
  halo outside the silhouette.
- **A ragged, smoky lower edge** (Dread with Shade/Void alpha) replaces the hard bottom outline. The
  plume off the back is thinner and trails away in alpha steps.
- **The Shade→Dread seam is irregular on purpose.** A regular checker across that 13 px band read as
  a row of teeth.
- **Ground shadow:** Void 45%, under the legs.
- The same rules apply to the Weeper and every other dark nightmare: keep the mass in Dread/Shade and
  never let a highlight band cross the body.

### Mossy Boulder (obstacle)
- **Moss cap:** Newleaf highlight upper-left, then Sprig, Leaf and Moss toward the lower right. Small
  clumps each have a darker pixel under them.
- **The moss lip hangs in lobes.** Each lobe drops a Stone shadow onto the rock, and a drip runs down
  the front. A ruler-straight moss line was the weakest part of the first pass.
- **Stone:** a Moonlight rim on the upper-left, a Mist lit face, and dithered seams into Stone and
  then Slate toward the lower right. Stone speckle and a hairline crack. The old sprite shaded the
  wrong side, and its "highlight" was Moonpath (a path colour), which has been replaced.
- Grass tufts at the foot, and a Void 45% contact shadow. **Value check:** the boulder is clearly
  paler than the Deepmoss ground and darker than the Moonpath path.

### Grass + path tiles
- **Grass:** Deepmoss ground. The old sprite's subtle variation snapped away to flat Deepmoss, so the
  texture is now drawn in on purpose: hand-placed tufts (Sprig tip, Leaf blade, Moss base) and four
  moss clumps, each with a Night shadow. That is about 3% of the pixels. Everything stays clear of
  the tile edge, so the four variants tile in any order.
- **Path:** Path base with a **Moonpath worn centre** that wanders ±2 px, with 3 px dither seams, so
  the path is the palest thing on the map. The left bank casts a Loam shadow line, dithered, and the
  right inner edge catches a Moonpath highlight. Both banks wobble by 1–2 px inside the tile but meet
  the tile edge exactly where the old tile did, so neighbouring path tiles still line up. Pebbles are
  Mist/Stone with a Loam shadow, plus sparse Loam grit and grass blades leaning over the banks. The
  old tile's heavy speckle was replaced by this.

## Rules of thumb these examples settle
1. **Rim ≤ half the edge.** Put it round the upper-left curve, then let it fade. A full-length rim
   becomes a second outline.
2. **Seams follow the form.** A diagonal or stepped seam reads as volume; a straight one reads as a
   panel. Break the checker up where it would line up into teeth.
3. **Texture ≤ 1 pixel in 10, and each clump gets a shadow pixel.** A highlight without its shadow is
   noise.
4. **Keep materials in their own ramps.** No Moonpath on stone, no Wraithlight on Wardens or flowers,
   no warm colour on nightmares.
5. **Check at 1×.** Each sheet's bottom row is true size; if a detail muddies there, remove it.
