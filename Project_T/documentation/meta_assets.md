# Meta Assets

Art for the meta game: the **Memory Grove** (the Heartwood as a tech tree), the perk loadout, node
icons and the 10 Memories. Design: `meta_design.md` ("The Memory Grove: a tech tree", "The
Hollow's story: 10 Memories"); look: `art_direction.md` (warm dream vs cold night), style
**Waystone pixel** like the environment (`environment_assets.md`). Created 2026-09-27, drawn from code
with a fixed seed. **Generator:** `tools/meta_art/` (`grove_*.js` sources, `grove_gen.html`; `powershell -File tools/meta_art/export.ps1 [-Rebuild]` rewrites `assets/meta/`, then `--import`).

**In the game:** `scenes/grove.tscn` draws all of it (`scripts/meta/grove_tree_view.gd`, `loadout_panel.gd`; see CLAUDE.md "Meta"). Node ids here = the `UnlockData` ids in `resource/meta/grove/`.

All under `assets/meta/`. Frames run left to right. Sprites include their own glow and outline.

## The Grove (`grove/`)

Tree space is **1280×960 px** (native pixels; the screen pans and zooms). Every position in
`grove_layout.json` is in that space.

| File | Size | Layout | Use |
|---|---|---|---|
| `grove_sky.png` | 1280×960 | 1 | back layer: night sky with stars, the moon (`moon` in the layout) and its halo, a warm glow behind the trunk, two layers of distant forest with fog between |
| `grove_canopy_0.png` … `_3.png` | 1280×960 each | 1, transparent | **the crown**: one shared mass of cauliflower foliage clumps (each a cluster of bubbles lit from the top left, with creases under each bump, leaf texture, and a dark gap where a lower clump sits in front; the crown darkens toward its underside) over all three limbs, so the tree reads as one crown, not three horns. Stage 0 is the core over the limbs (always shown); each stage fills out the edges (about 55 / 70 / 85 / 100% of the clumps) with more lit dream-leaves. Show the stage for the share of nodes owned (e.g. 0–24% → 0), crossfading when it changes |
| `grove_tree.png` | 1280×960 | 1, transparent | the Heartwood, always shown: ridged roots with pale mushrooms, a twisted three-strand trunk (each strand a shaded cylinder with a lit band and bark lines along it) with ivy, knots and the lit hollow, the three great limbs (Perks left, Families middle, Cards right) as twisted strands running up into the crown, a moonlit rim, a **glowing sigil at the base of each limb** (gold ring = Perks, green sprig = Families, violet card = Cards), and **five waystones at the roots** (`loadout_stones`: the loadout slots in the world) |
| `branches/<node_id>.png` | per node | **5 frames**: 0 bare twig (locked), 1–3 the branch growing 25/50/75%, 4 grown | one per node (79); draw at `branch.offset`; planting plays 1→4 |
| `grove_nodes.png` | 352×96 | 32×32; **rows**: 0 Perks (gold), 1 Families (green), 2 Cards (violet); **columns**: 0 locked bud, 1–4 affordable glow (loop), 5–8 bud opening (play once), 9–10 bloomed (loop) | node sprite, centred on `pos` |
| `grove_legendary.png` | 528×48 | 48×48, same 11 columns, violet | Legendary tips (Dawnbreak, Full Moon, The Old Ones, Rootbound, The Last Light, The Long Walk) |
| `dream_fruit.png` | 432×48 | 48×48: 0–3 idle glow (loop), 4–7 opening (play once), 8 opened | Memories; the **vine's top is the sprite's top centre**, hang it at a `fruit_spots` point |
| `grove_layout.json` | | see below | positions and parents for everything above |

### `grove_layout.json`

- `size`: [1280, 960].
- `nodes`: one entry per node (79), in `meta_design.md` order: `id`, `section` (`perks` /
  `families` / `cards`), `name`, `pos` (flower centre), `parent` (node id) **or** `from` (the point on
  a great limb it grows from), `levels` (Morning Stores 3, Rich Dew 3, Rested Roots 2, Deep Taproot 3,
  Second Thoughts 2; the game shows pips), `start` (Sporeling, Firefly Jar, Dewdrop: grown from the
  start), `legendary`, and `branch` (`offset` = where to draw its branch sheet's frame, `frame_size`,
  `frames` = 5).
- Family ids: `<family>`, `<family>_final`, `<family>_hidden`, `<family>_ascension` (e.g. `pebbling_final`).
- Loadout slots are Perks nodes `slot_2` … `slot_5`.
- `fruit_spots`: 10 points under the Perks and Cards limbs, in the order fruit appear (one per 3
  nodes planted).
- `loadout_stones`: the centres of the 5 waystones at the roots, slot 1 to 5 left to right (light the
  ones the player has unlocked, set a perk icon glowing on each filled one).
- `moon`: the moon's centre (for a light or a parallax offset).

### How the states fit together

| Node state | Branch frame | Node sprite |
|---|---|---|
| Locked (parent not owned) | 0 (bare twig) | column 0 |
| Affordable (parent owned, enough Seeds) | 0 | columns 1–4, looping |
| Planting | 1 → 4 (about 0.1 s each) | then columns 5–8 once |
| Owned | 4 | columns 9–10, looping |

Draw order: sky, tree, **canopy stage (in front of the limbs)**, branches (parents before children), fruit, nodes. Nice to have
in the scene: a slow parallax on the sky, fireflies and dream motes as particles, a warm light on
the hollow.

## Loadout (`ui/`)

| File | Size | Layout | Use |
|---|---|---|---|
| `loadout_slots.png` | 256×64 | 64×64: 0 locked (sealed by a vine), 1 empty socket, 2 filled (gold rim), 3 filled and selected | "Carry into the dream": draw a 32×32 perk icon centred on a filled slot |

## Icons (`icons/`, 32×32)

| File | Order |
|---|---|
| `perk_icons.png` (480×32) | Morning Stores, Rich Dew, Rested Roots, Seed Pouch, Clear Sight, Sprout Bed, Kindling, Early Bloom, Early Light, First Care, Deep Taproot, Second Thoughts, Let Go, Omen Reader, Wider Dreams |
| `family_icons.png` (288×32) | Sporeling, Firefly Jar, Dewdrop, Pebbling, Rootling, Bellflower, Acorn, Nestling, Whirligig |
| `card_bundle_icons.png` (320×32) | Storm, Spores and Reactions, Keen Edges, Tending, Overgrowth, Lone Lantern, The Long Way, Bittersweet, Woven, Deep Poison (a small stack of Dream cards with the branch's emblem) |

Family nodes can also show the Warden's own sprite (`assets/towers/<warden>.png`, frame 0) on the
node card; the icons are for small spots where a 64 px Warden won't fit. Bellflower, Nestling and
Whirligig have no Warden art yet.

## Memories (`memories/`)

`memory_01.png` … `memory_10.png`, **320×180** each, in story order (`meta_design.md`): two trees
dreaming; shared roots and the forest between; the drought; the creatures leaving; the dream closing
and breaking; the leaves falling; the first nightmares; the waystones; the promise; the path under
the nightmares. The Heartwood is always warm moss-gold, the Hollow cool teal and then grey and bare.

These are simple first versions, good enough to build the screen with. They're the pieces most worth
repainting by hand before release.
