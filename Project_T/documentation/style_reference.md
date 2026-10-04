# Style reference: the detail pass done by hand

These are reference sprites for the art decisions in `art_direction.md` → "Rendering style" (Waystone
pixel, **detailed 64**, the **Heartwood 32** palette). Each one was redrawn pixel by pixel from its
current sprite and uses only the 32 palette colours, plus the alpha steps the palette allows. Every art
chat should match these when it applies the detail pass to its generator. The automatic "Detailed · 64"
column on https://claude.ai/artifact/L3HVzecXZZLdogJKHtkuvy is the baseline these are meant to beat.

Files are in `assets/style_reference/`. A `.gdignore` keeps the folder out of the game build.

## Update 2026-10-04: the game as it is now, and avoiding the "AI look"

The user worries that players dislike games that look AI-made. This update is specified in
`art_direction.md` "Style references (updated 2026-10-04)". The sheets now show the game as it is,
and seven do / don't sheets name the usual tells. Wherever a "don't" side could come from a real
sprite, it does. All sheets are built from the committed art, at whole-number scales.

### Current state

| Sheet | What it shows |
|---|---|
| `current_warden_night.png` | Six base Wardens as they are in game: idle sheets one shade down (Warden Night), with the attack (frame 3) keeping its full warm light. |
| `silhouette_rule.png` | Lanternmoth → Beacon, the pair that started the rule: in colour, then as grey 32 px shapes. Beacon is one of the 10 tall 64×96 finals; the last panel shows its rise fading to 50% over a Shade. |
| `branch_pair_phase2.png` | Rootling and its two Phase 2 branches, Groundroot and Deeproot: same family colours, a new stance and crown each. In colour and as 32 px grey shapes. |
| `emblems_sheet.png` | Emblems at 3×: family and other (`assets/ui/emblems`), branch, and Heartwood's Gift (`assets/ui/gifts`). The first 8 of each, A–Z. |
| `route_mist_sheet.png` | The route mist on the pale path and on dark ground, plus the two mist textures at 4×. |
| `heartwood_stages.png` | The inland Heartwood's four Grove stages in the same 128 px frame (frame 0, no leaves lost), at 2×. |
| `act_palettes.png` | The current act ground and path, acts 1–4: night-indigo ground with moss (acts 1–2), violet with rust (act 3), frost (act 4). |
| `sporeling_night_ref.png` | **Refreshed:** the hand-tuned Sporeling reference through the Warden Night map. It replaces `sporeling.png` as the Warden reference. |

**What is now superseded.** The 2026-09-28 `grass.png`, `path_ns.png` and their sheets show the old
green ground; the act tiles have moved on to night-indigo, violet and frost (`act_palettes.png`).
They are kept for their technique: tufts with a shadow pixel, the worn path centre, banks that
wobble but meet the tile edge. Don't copy their colours. `sporeling.png` is replaced by
`sporeling_night_ref.png`. The Shade and Mossy Boulder references still match the game.

### Avoiding the AI look: one sheet per row of the table

| Sheet | Don't (where it comes from) | Do |
|---|---|---|
| `dodont_grain.png` | Speckle spread evenly over the Sporeling's flat body: **the current sprite**. | The same frame after removing lone specks on flat areas with a 3×3 majority pass (for illustration; a hand pass is better). Texture stays where materials change. |
| `dodont_glow.png` | A soft halo round the idle Acorn "for mood": **the current sprite** (Gold at 20–59% alpha all round). | No idle halo; the glow comes with the attack (attack frame 3). |
| `dodont_poses.png` | Sporeling, Bloomcap, Elf Circle and Fairy Ring as 32 px grey shapes: **current sprites**, one body template with a different hat. | Rootling, Groundroot and Deeproot: a new stance and crown per form. |
| `dodont_quirks.png` | The Warden Night Sporeling reference: clean, symmetric, nothing out of place. | The same sprite with hand-placed quirks: a crooked smile, one bent sprout on the crown, a moss patch on one shoulder only, a chipped plinth corner. |
| `dodont_light.png` | **The Sporeling before 2026-09-28**, lit from the right. | Light from the upper left, a Night outline, the rim on at most half the edge. |
| `dodont_sheen.png` | **The Dreamshroom before Warden Night**: a violet body with gold sparkles, the purple-gold "magic" sheen. | The current Dreamshroom in Nightbloom: bluer and darker, so no Warden reads as a nightmare. |
| `dodont_pixels.png` | An illustration (no current sprite does this): 1.5× scale, a 7° rotation and smoothing, giving mixed pixel sizes and blur. | A whole-number scale (3×), hard edges, no rotation. |

**Tells spotted while building these sheets.** Each is a job for the owning chat:
- The path tiles in every act carry dense, evenly spread grain (`act_palettes.png`), the same tell as row 1.
- Several Wardens have an idle halo: Acorn and Rootling.
- The Firefly Jar plinth uses a regular gold checker.
- The Heartwood's canopy shows a regular Bayer checker and evenly spaced gold fruit along its edge.

## Hand-polish list (art_direction.md), and what each sprite most needs

These are the most-seen sprites, where a human touch-up matters most. Keep the size, palette and
silhouette; add the quirks and fix anything that reads as generated.

| # | Sprite | What it most needs |
|---|---|---|
| 1 | **Sporeling** (the mascot) | Calm the speckle on the body and plinth top (row 1). Add one or two quirks (`dodont_quirks.png`). Give it a face of its own; it shares its eyes and mouth with most base Wardens. |
| 1 | **Firefly Jar** | Replace the regular gold checker on the plinth with a hand-placed glow. Keep the sparkles inside the jar only, a few and uneven, not spread over the body. |
| 1 | **Dewdrop** | Calm the body grain. Give it a different expression from the Sporeling, and one asymmetric detail (a drip running down one side). |
| 1 | **Their branches** | They pass the silhouette rule. Polish faces and props so each looks drawn, not stamped from the base template. |
| 1 | **Sprout and Thornwall** (on the map every run) | Thornwall: irregular, hand-placed thorns instead of evenly spaced spikes, and no halo dots. Sprout: break the regular stripes on its soil plinth. |
| 2 | **The Hollow Stag** (act 1 boss) | Hand-draw the antlers: asymmetric, one chipped tine. A clean boss silhouette at full size, with the dark cold body and pinprick eyes. |
| 2 | **The Shade** (most common nightmare) | Keep it dark. Vary the ragged smoky edge from frame to frame (the Shade reference) so the walk doesn't look looped from one frame. |
| 3 | **The Heartwood** (4 Grove stages + damage rows) | Break the Bayer checker in the canopy into hand-made leaf clumps. Space the dream-fruit unevenly. Make the rot patches in the damage rows ragged and different from row to row. |
| 4 | **The title Warden** (`c5468b4d`) | The cracks repeat like an even cobble pattern; hand-place fewer, larger cracks. Gather the moss into clumps that follow the form. |

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
