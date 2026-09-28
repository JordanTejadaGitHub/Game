# Meta Design: Seeds, the Memory Grove, Blight Levels, the Hollow's story

Phase 3 of `design_plan.md`. Numbers are starting points for tuning.

## Decisions

| Question | Decision |
|---|---|
| Time to unlock everything | **~15–20 hours** (≈ 12–15 runs of 1–2 hours; revised for 100-drift runs) |
| What meta gives | **Both new options and some permanent power**; power perks are capped |
| Difficulty ladder | **Slay the Spire style**: Blight Levels 1–10, each adds one modifier on top of the previous ones |
| Story delivery | **Memory fragments** revealed through progression, leading to a true ending |

## Seeds (earned every run, win or lose)

Revised for 100-drift runs (`run_design.md`).

| Source | Seeds |
|---|---|
| Every 2 drifts survived | 1 (max 50) |
| Nightmares dispelled | 1 per **20** (~75 in a full run) |
| Each boss dispelled | **20** |
| Each obstacle tended | 1 (see `run_design.md`) |
| Winning | **+120** |
| Blight Level | +10% per level (Level 10 = double) |

Examples: a loss around drift 20 ≈ **30 Seeds**; a loss at drift 60 ≈ **120**; a win ≈ **350**.
Averaging ~280 across a player's first runs, the full tech tree (**~5,960 Seeds** as built:
Perks ~2,090, Families ~2,470 incl. Ascension, Cards ~1,400) takes **~21 runs ≈ 30 hours** (confirmed as the target, 2026-09-28).
(Raised twice on 2026-09-27 as the Grove grew; the first unlocks still come every run, and a full
Grove is a long-term goal next to Blight Levels.)

**Every run should buy something early on**: the cheapest unlocks cost 20–25, so even a bad first
run grows the Grove. Losing early in a long run is also cushioned by the mid-run save: players can
stop at any rest and come back.

## Seeds from the demo

The demo has no Grove (`demo_scope.md`), but **every Seed earned in the demo is saved**. When the
player owns the full game, those Seeds are waiting in their Grove on first launch: *"The forest
remembered you."* This works if the demo and full game share the save format and location (same
project name, so the same `user://` folder); the full game reads the demo's saved Seeds once and
marks them as imported.

## The Memory Grove: a tech tree

Redesigned 2026-09-27 (user decision): the Grove is a **tech tree** growing up from the Heartwood's
roots, with **three sections**. Each node costs Seeds and needs its parent node(s). About 55 nodes,
~3,100 Seeds in total.

```
                 FAMILIES (middle limb)
   PERKS (left limb)     |      CARDS (right limb)
            \            |            /
             \           |           /
                  [ the Heartwood ]
```

**How it looks and works: the tree *is* the Heartwood** (user decision 2026-09-27;
`screens_ui.md`, meta screens):
- The screen shows **the Heartwood itself**, at night, from its roots up. Its three great limbs are
  the three sections (Perks left, Families middle, Cards right). Every node is a spot on a branch.
- **Locked nodes** are bare twigs with a closed bud (cost shown). **Affordable nodes** (parents
  owned, enough Seeds) glow faintly.
- **Planting a node grows the branch** out to it with a short animation, and **a flower blooms**
  there, its colour by section (e.g. gold for Perks, green for Families, violet for Cards). Owned
  nodes stay in bloom, so **the more you unlock, the fuller and brighter the Heartwood gets**.
- **The canopy fills in** behind the branches in four stages as the share of owned nodes grows, so
  the whole tree gets fuller, not just its flowers (`meta_assets.md`).
- **The perk loadout slots are five waystones at the Heartwood's roots**: you "carry" perks by
  setting them on the stones (the same waystones the Wardens sleep on; Memory 8).
- **Memories hang as dream-fruit** (the glowing fruit from the Heartwood's art): a new fruit appears
  every 3 nodes planted; tapping it plays that Memory.
- Tap or click a node for its card and a **Plant** button (no hover needed). Pan and zoom like the
  map. A Seeds counter top left; **Start run** opens the loadout (below) first.
- **Carried into the run** (optional, cosmetic): the in-run Heartwood sprite shows a few of the
  player's flowers and dream-fruit, so the tree on the map reflects their progress.

### Section 1: Perks (bring into the game)

Perks are **unlocked** in the tree, then **equipped** in a small **loadout** before each run
("Carry into the dream"). You own many but carry few, so the loadout is a choice every run.

- **Loadout slots: up to 5** (user decision 2026-09-27): **1** at the start; the tree adds slot 2
  (40), 3 (80), 4 (140) and 5 (220). Growing this limb = **more perks to choose from and more
  room to carry them**.
- A perk with levels (e.g. Morning Stores I–III) takes one slot at its highest owned level.
- Loadout is kept between runs; change it any time before starting.

**Economy perks**

| Perk | Levels | Cost per level | Effect (at max) | Needs |
|---|---|---|---|---|
| Morning Stores | 3 | 20 / 40 / 60 | **+30 starting Dew** (+10 per level) | — |
| Rich Dew | 3 | 30 / 60 / 90 | **+15% Dew** from dispelled nightmares (+5% per level) | Morning Stores I |
| Rested Roots | 2 | 40 / 80 | rest bonus **+20%** (+10% per level) | Rich Dew I |
| Seed Pouch | 1 | 100 | +10% Seeds at run end | — |

**Starting-advantage perks**

| Perk | Levels | Cost | Effect | Needs |
|---|---|---|---|---|
| Clear Sight | 1 | 80 | start the run holding **Cleared Ground** (so clearing trees and rocks is unlocked from drift 1, and cheaper) | — |
| Sprout Bed | 1 | 60 | start with **2 free Sprouts** to place | Morning Stores I |
| Kindling | 1 | 90 | start with **a random Common Dream** already taken | — |
| Early Bloom | 1 | 80 | the first family pick offers **every** unlocked family | — |
| Early Light | 1 | 120 | **+1 Dreamlight** at run start | Early Bloom |
| First Care | 1 | 70 | your **first 3 Nurture ranks** each run are free | — |

**Survival and choice perks**

| Perk | Levels | Cost per level | Effect (at max) | Needs |
|---|---|---|---|---|
| Deep Taproot | 3 | 25 / 50 / 75 | **+3 max leaves** | — |
| Second Thoughts | 2 | 50 / 100 | 2 Dream rerolls per run | — |
| Let Go | 1 | 60 | banish 1 card per run | Second Thoughts I |
| Omen Reader | 1 | 80 | Omen rests offer 3 Omens instead of 2 | — |
| Wider Dreams | 1 | 150 | 4 cards per Dream instead of 3 | Second Thoughts II |

| Slot node | Cost | Needs |
|---|---|---|
| Loadout slot 2 / 3 / 4 / 5 | 40 / 80 / 140 / 220 | each needs the previous |

**Power budget:** 15 perks, carry at most 5. A full economy loadout (Morning Stores III, Rich Dew
III, Rested Roots II, Sprout Bed, Clear Sight) makes the early game noticeably smoother, which is
why **Blight Levels** exist: each level takes back some of that power. Caps: starting Dew +30,
Dew gain +15%, leaves +3, rerolls 2.

### Section 2: Families and family upgrades

The starting families (Sporeling, Firefly Jar, Dewdrop) sit at the base of this limb, already grown.
Each family has three nodes stacked above it: **the family** (joins the family picks, with its
branches), **its final forms**, **its hidden branch**.

| Family | Family node | Final forms node | Hidden branch node |
|---|---|---|---|
| Sporeling | *(start)* | 50 (Puffball, Dreamshroom) | 40 (Fairy Ring + Elf Circle) |
| Firefly Jar | *(start)* | 50 (Thunderhead, Beacon) | *milestone:* Sunpetal |
| Dewdrop | *(start)* | 50 (Monsoon, Morning Fog) | 40 (Frostfern + Hoarfrost) |
| Pebbling | 50 (branches: Mossback, **Standing Stone**) | 50 (Boulderback, Moonstone) | 50 (Cairn + Rockslide) |
| Rootling | 50 | 50 | 40 (Rootlight + Starcave) |
| Bellflower | 60 (needs Pebbling or Rootling) | 50 (Lullaby Bell, Great Dreamcatcher) | 60 (Echo Hollow + Whispering Hollow) |
| Acorn | 70 (needs Pebbling or Rootling) | 50 | 60 (Graftling + Grafted Elder) |
| Nestling | 120 (needs 2 of Pebbling / Rootling / Bellflower / Acorn) | 60 | 80 (Hummingbird Bower + Jewelwing Court; brings the on-hit cards) |
| Whirligig | 120 (needs 2 of Pebbling / Rootling / Bellflower / Acorn) | 60 | 80 (Samara + Autumn Gale; brings the boomerang cards) |

**Unlock order, by design:** the 3 starting families are the easiest to read (spores, water,
light). Pebbling and Rootling come next (plain roles: hit hard, control). Bellflower and Acorn need
one of those first, because sleep payoffs and support are better once you know the basics.
Nestling and Whirligig are the full-game families, and **every hidden branch is a late node**
above its family's final forms, so veterans keep finding new playstyles. Reviewed 2026-09-27
(`tower_design.md`, "Family design rules").

- The Grove decides which forms **exist** in your runs; **Dreamlight** decides which you unlock
  **this run** (`run_design.md`). A final form not yet grown here shows as *"Memory Grove"* on the
  Remember screen.
- A family's own Dream cards (`dream_design.md`, "Cards for the new Wardens") come with its family
  or hidden-branch node automatically.
- **Ascension nodes** (added 2026-09-27): each family gets one more node at the top of its stack,
  **Ascension (120 Seeds)**, after its hidden branch (or its final forms where a family has no
  hidden-branch node). It makes that family's **Ascended** endgame Warden exist in runs
  (`tower_design.md`); in-run it still needs 3 Dreamlight and 400 Dew. 9 nodes, ≈ 1,080 Seeds.
  **Firefly Jar exception:** its hidden branch (Sunpetal) comes from a milestone, so **Stormheart's
  Ascension needs the Firefly Jar final-forms node** instead, never a milestone.
- **Memory Wardens** aren't bought: dispelling a boss for the first time grows its Memory Warden as a
  free bloom on this limb, and it's offered after that boss in later runs.
- Total ≈ 1,390 Seeds (was ≈ 1,100 before Bellflower and the Nestling/Whirligig hidden nodes;
  re-check the tree's ~3,100 total and the hours estimate).
- Each hidden-branch node needs its family's final-forms node, so hidden branches really are late.

### Section 3: Cards (Dream pool unlocks)

Revised 2026-09-27. Cards come in **themed bundles** (one node = a set of Grove cards joining the
Dream pool). The limb splits into **one branch per build style**; each branch grows from cheap
bundles near the trunk to **a Legendary flower at its tip**. So the tree also shows which build
styles a player has grown into.

| Branch | Node 1 (near the trunk) | Node 2 | Tip: Legendary |
|---|---|---|---|
| **Storm** | *Storm Lore*: Charged Bloom, Charged Field (40) | *Guiding Lights*: Guiding Light, Starlit Aim (60) | — (Storm builds share the Reactions tip) |
| **Spores and Reactions** | *Spore Lore*: Twin Puff, Chain Bloom (40) | *Reactions*: Wildfire Spores, Deep Water, Quick Reactions, Kin and Kindling (70) | **Dawnbreak** (120) |
| **Woven** (Crowned Reactions) | *Woven Dreams I*: Eye of the Tempest, Deep Stillness, Fever Pitch, Falling Stars (90; needs *Reactions*) | *Woven Dreams II*: Mountain's Fall, Prism Heart, Endless Night, Ring of Rings (90) | — (Crowned Reactions always work; these cards strengthen them) |
| **Keen Edges** (crit) | *Sharpened*: Still Target, Shattering Blow (50) | *Reckless*: Reckless Bloom (40) | **Full Moon** (120) |
| **Deep Poison** (Potency) | *Seeping* (50) | *Venom*: Venom Bloom (40) | **Nightshade** (120) |
| **Kinship** (going deep) | *Kin Lore*: Close Kin, Old Friends (50) | *Deep Bonds*: Rooted Bond, Extended Family (70) | **Grove of Kin** (120) |
| **Tending** (nurture, tall) | *Tending Hands*: Sunlit Rest, Deeper Rings (60) | *Nursery*: Nursery, Chosen Few (70) | **The Old Ones** + **Endless Rings** (150) |
| **Overgrowth** (wide) | *Seedbed*: Seedling Gift, Canopy (60) | *Wild Planting*: Overgrowth (50) | **Rootbound** (100) |
| **Lone Lantern** (narrow) | *One Line*: Monoculture (80) | — | **The Last Light** (120) |
| **The Long Way** (maze, clearing) | *Dead Wood*: Burn Back the Dead Wood (40) | — | **The Long Walk** (100) |
| **Bittersweet** | *Bittersweet Dreams*: Deep Sleep, Borrowed Dew, Wild Growth, Overgrown, Restless Dreams, Hungry Roots, Borrowed Memory, Blood Is Thicker (60; needs any 2 other nodes) | — | — |

- Each node needs the one before it on its branch; a tip needs both nodes below it (or the one,
  where a branch has a single node).
- **Family-specific cards** (Skipping Stones, Deep Frost, Sweet Scent, etc.) aren't here: they come
  with their family or hidden-branch node on the Families limb.
- **Start-pool cards** (the basic stat, economy and first build cards) are always available, so a
  new player already has a full Dream pool; this limb adds depth and big payoffs.
- Total ≈ 1,300 Seeds. New cards join an existing branch's bundle or start a new branch.

**Families before the Grove fills in:** a new player has only 3 families (Sporeling, Firefly Jar,
Dewdrop), but a run offers family picks at drift 1 and at the 25/50/75 bosses. When there are
fewer than 3 new families to offer, the empty slots become **Family Blessings**: a strong boon for
a family you already own (e.g. *"Sporeling Blessing: Sporeling family +25% soothe, evolutions 25%
cheaper"*). So early runs deepen few families; unlocking Pebbling, Rootling, Bellflower and Acorn widens later
runs, which makes those Grove purchases feel big.

### Later: Forests

New biomes (e.g. **Misty Marsh**, **Autumn Hollow**) will be a small fourth limb or nodes at the top
of the Perks limb once they're designed (`design_plan.md` topic 9); not in the first version.

### Memories and the tree

A Memory fragment appears **every 3 nodes planted** (plus the milestone ones below), as a
**dream-fruit** hanging from the Heartwood's branches. About 55 nodes, so all 10 Memories arrive well before the tree is complete.

## Milestones (free unlocks; double as Steam achievements)

| Milestone | Reward |
|---|---|
| Dispel your first boss | Memory fragment |
| Win a run | Memory fragment + Blight Levels open |
| Dispel 500 Shades | Sunpetal (hidden Firefly Jar branch) |
| Build a 300-tile path | The Long Walk card, free |
| Win without losing a leaf | Golden Leaf (cosmetic Heartwood) |
| Tend 100 obstacles (total) | Memory fragment |
| Win with only one Warden line | Monoculture card, free |
| Reach Blight Level 5 | Memory fragment |
| Win at Blight Level 10 | Blossom cosmetic for all Wardens |
| Discover every combo (Codex, `screens_ui.md`) | Memory fragment + a Codex cosmetic (gilded pages) |

Free unlocks that duplicate a Grove purchase refund its Seeds if already bought.

## Blight Levels (unlocked by the first win)

Pick a level before a run; each level includes all the ones below it. **+10% Seeds per level.**

| Level | Adds |
|---|---|
| 1 | Nightmares +10% health |
| 2 | **The first family pick gives no Dreamlight** (was "starting Dew −20", which made drift 1 unwinnable after the opening test) |
| 3 | Bosses +25% health |
| 4 | Drift-clear bonus −25% |
| 5 | One nightmare per drift is **Deeply Blighted** (×3 health, costs 2 leaves; see `acts_1_2.md`) |
| 6 | **No leaves regrow at act breaks** (the normal rule is +1 since difficulty pass v1) |
| 7 | Nightmares +10% speed |
| 8 | Dream offers lean Common; *Let it pass* gives no Dew |
| 9 | Obstacles cost twice as much to tend; maps get one extra ridge |
| 10 | **The Hollow Oak remembers**: it gains a second phase |

The highest level won is shown on the title screen, as a small blossom per level on the Heartwood.

## The Hollow's story: 10 Memories

Memories appear as short illustrated fragments in the Grove (one screen each, a few lines). Most
come from Grove progress (**one every 3 unlocks**); the rest from milestones (above). Read in
order, they tell where the nightmares come from (revised 2026-09-27 for the nightmare theme):

1. *Before the Heartwood, there were two trees, and both of them dreamed.* (after your first run,
   always)
2. The Heartwood and the Hollow shared their roots, and one dream grew between them: the forest.
3. A long drought came. The Heartwood's roots went deep; the Hollow's couldn't reach.
4. The forest's creatures followed the Heartwood's shade. The Hollow was left alone, still dreaming.
5. The Hollow tried to keep the last creatures inside its dream, and closed it around them. The
   dream broke. (why *a dream can bend, but never close*)
6. Its leaves fell, one by one, and nobody came.
7. It dreamed alone in the dark for so long that its dreams turned: **the first nightmares**.
8. The creatures once carved **waystones** to mark the path between the two trees. (the stones the
   Wardens sleep on)
9. The Heartwood remembers it promised to come back.
10. *The path to the Hollow is still there, under the nightmares.*

### True ending: The Long Walk Out

With all 10 Memories and at least one win, a special run unlocks. The goal flips: the path leads
**away** from the Heartwood, into the Hollow's nightmares. Same acts, and the final drift is the
Hollow itself, the one enemy that is **not dispelled**: the Wardens surround it with light until its
grief breaks and it blooms again. Then the ending and credits.

After the ending: the Grove grows a sapling of the Hollow beside the Heartwood (cosmetic), and
Blight Levels carry on as the endgame.

## Data

- `HeartwoodMemory` autoload: Seeds, owned unlocks (ids), milestone progress and counters,
  Memories seen, highest Blight Level won, settings. Saved to `user://` (Steam Auto-Cloud),
  versioned.
- `UnlockData` resources (tree nodes): id, **section** (perks / families / cards), cost per level,
  levels, **parents** (ids), **tree position**, effect (adds families/forms/cards to the pools, or a
  perk). Perks also have `loadout: true`.
- `HeartwoodMemory` also stores the **perk loadout** (equipped perk ids) and the number of slots.
- `MemoryData` resources: order, text, art, trigger (unlock count or milestone id).
- `BlightLevelData` resources (or one list): level, description, modifiers.
