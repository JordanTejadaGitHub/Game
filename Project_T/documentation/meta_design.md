# Meta Design: Seeds, the Memory Grove, Blight Levels, the Hollow's story

Phase 3 of `design_plan.md`. Numbers are starting points for tuning.

## Decisions

| Question | Decision |
|---|---|
| Time to unlock everything | **~35 hours** (≈ 26–28 runs; user 2026-10-06, was ~30 h, first 15–20 h) |
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
Perks ~2,090, Families ~2,470 incl. Ascension, Cards ~1,400) takes **~21 runs ≈ 30 hours** (confirmed as the target, 2026-09-28). **2026-09-29:** discovery unlocks removed 6 fully covered Cards nodes (Reactions, Woven Dreams I–II, Kin Lore, Deep Bonds; `dream_design.md` "Grove overlap"), the cards now come from discovering combos and Kinships in play. **As built (763f228): 5 nodes removed; the tree is 6,722 Seeds** (Families 2,470, Cards 2,162, Perks 2,090; the earlier 5,960 predates the Seeds and Quiet Ones rows and the Ascension nodes), about **24 runs ≈ 34 hours** at ~280 Seeds per run, a little over the 30-hour target. **2026-09-29:** slot_2 / slot_3 removed (−120): **6,602 Seeds ≈ 24 runs ≈ 33 hours**. The user confirmed ~30 hours is right, so no cuts. **2026-09-30:** Reckless and Wild Planting removed (−90, refunded to old saves): **6,512 Seeds**. **2026-09-30:** the 9 final-forms nodes removed (≈ −470, refunded): **≈ 6,040 Seeds ≈ 22 runs ≈ 30 hours**, right on the target, so the freed Seeds are not re-spent (no rebalancing). **2026-09-30 (later):** the Cards limb swap (≈ 6,140) and the lean starting pool (+1,200): **≈ 7,340 Seeds ≈ 26 runs ≈ 33–36 hours**.
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
roots, with **three sections**. Each node costs Seeds and needs its parent node(s). 84 nodes,
**≈ 7,340 Seeds** in total (2026-09-30, after the lean starting pool moved build cards onto the Cards limb; see Seeds above).

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
- **Bloom levels show depth on the green and purple limbs** (user 2026-09-30, visual only, no
  balance change): a node's bloom uses the level art for **how far up its branch it sits**: a
  Cards branch's first bundle = level 1, its second = level 2, **its Legendary = level 3**; a
  family node = level 1, its hidden branch = level 2, **its Ascension (the Ascended Warden) =
  level 3**. Perks keep showing their real purchase levels.
- **The canopy fills in** behind the branches in four stages as the share of owned nodes grows, so
  the whole tree gets fuller, not just its flowers (`meta_assets.md`).
- **The perk loadout slots are five waystones at the Heartwood's roots** (3 open from the start;
  a hidden sixth rises once the whole tree is grown): you "carry" perks by
  setting them on the stones (the same waystones the Wardens sleep on; Memory 8).
- **Memories hang as dream-fruit** (the glowing fruit from the Heartwood's art): a new fruit appears
  every 3 nodes planted; tapping it plays that Memory.
- Tap or click a node for its card and a **Plant** button (no hover needed). Pan and zoom like the
  map. A Seeds counter top left; **Start run** opens the loadout (below) first.
- **Carried into the run: the Heartwood you defend is your Grove** (user idea via the design hub,
  2026-10-01; cosmetic only, no gameplay). The in-run Heartwood matches the Grove screen's tree:
  - **Canopy stage:** it follows the Grove's canopy stages by `HeartwoodMemory.grown_share()`
    (about 4: young → fuller → broad → great old tree), with the same silhouette, palette and
    blossoms as the Grove art, so it reads as the same tree.
  - **Lit nodes** (user: *"the amount of nodes unlocked with colour should match the one in game"*):
    every planted Grove node shows as a **tiny 1–2 px glint** on the in-run
    Heartwood, in the **same relative place** as on the Grove tree (`grove_layout.json` positions
    scaled onto the in-run canopy and roots), coloured by limb as on the Grove screen (Families
    green, Cards violet, Perks gold). Unplanted nodes are absent. A full tree is fully lit, so a
    glance at the tree you defend shows your Grove.
  - **Dream-fruit = Memories** (user via Environment Discussion, 2026-10-01): one fruit hangs on the
    in-run Heartwood per unlocked Memory (0–10, as on the Grove tree), and darkens with leaf loss.
  - **Readability first:** leaf loss stays just as readable at every stage (leaves dim and fall
    **over** the blossoms), and the lights stay subtle under the Heartwood's leaf-loss dimming and
    the close-call glow. It stays 128 px (later stages get fuller, not bigger) and keeps its fade when something is
    behind it.
  - **Cost:** built once at run start (one baked texture or a handful of sprites), nothing per
    frame.
  - **Scope:** full game only; the demo keeps a fixed tree (stage 0, 3 fruit, no glints). Dev runs (Dev Grove, Test Grove,
    "Unlock all families") show their preset's tree. A Grove change shows from the next run.
  - **Who builds what:** the ~4 canopy stages (in-run size) are Environment Assets' art, checked
    against `assets/meta/` by Meta Game Asset so both trees match; the stage pick and the node lights
    are Environment Code's (`heartwood.gd`), reading `HeartwoodMemory` (`grown_share()`,
    `node_level()`) and `grove_layout.json`; Meta Game Code adds a helper if one is needed
    (e.g. planted nodes with their limb and layout position).

### Section 1: Perks (bring into the game)

Perks are **unlocked** in the tree, then **equipped** in a small **loadout** before each run
("Carry into the dream"). You own many but carry few, so the loadout is a choice every run.

- **Loadout slots: 3 at the start, up to 5, plus a secret 6th** (user decision 2026-09-29; was 1
  at the start): slots 1–3 are open from the first run. Slots **4 (140)** and **5 (220)** are
  Perks nodes. Growing this limb = **more perks to choose from and more room to carry them**.
- **The secret 6th slot:** not shown anywhere (no waystone, no node, no Codex hint) until the
  player owns **every Grove node at its max level**, then the node **The Heartwood's Crown** (250 Seeds) appears (a bought node since 2026-10-04).
  Planting it raises a sixth waystone at the roots (a Steam achievement; was the milestone *"The Heartwood in full
  bloom"*). It's a trophy for completing the tree, so its power doesn't matter
  for balance: by then everything else is owned.
- A perk with levels (e.g. Morning Stores I–III) takes one slot at its highest owned level.
- Loadout is kept between runs; change it any time before starting.

**Three paths** (user decision 2026-09-29; was loose nodes that read like a shop): the limb grows
from the trunk as **Economy**, **Survival** and **Choice** paths, each in a clear order, and the
two slot nodes sit **where the paths meet**, so more room to carry comes from growing the limb.
Costs are unchanged (~30 h total stays). A levelled parent counts from its level I. The paths are
**rules, not a layout**: the Grove keeps its natural spread of branches (user 2026-09-29: three
visibly separate paths look too neat, not like a real tree).

**Economy path** (more Dew, more Seeds)

| # | Perk | Levels | Cost per level | Effect (at max) | Needs |
|---|---|---|---|---|---|
| 1 | Morning Stores | 3 | 20 / 40 / 60 | **+30 starting Dew** (+10 per level) | — (trunk) |
| 2 | Rich Dew | 3 | 30 / 60 / 90 | **+15% Dew** from each drift's Dew pot (+5% per level; `run_design.md` "The Dew pot") | Morning Stores |
| 3 | Rested Roots | 2 | 40 / 80 | rest bonus **+20%** (+10% per level) | Rich Dew |
| 4 | Seed Pouch | 1 | 100 | +10% Seeds at run end | Rested Roots |
| side | Sprout Bed | 1 | 60 | start with **2 free Sprouts** to place | Morning Stores |

**Survival path** (leaves and a stronger start)

| # | Perk | Levels | Cost per level | Effect (at max) | Needs |
|---|---|---|---|---|---|
| 1 | Deep Taproot | 3 | 25 / 50 / 75 | **+3 max leaves** | — (trunk) |
| 2 | First Care | 1 | 70 | your **first 3 Nurture ranks** each run are free | Deep Taproot |
| 3 | Clear Sight | 1 | 80 | start the run holding **Heartwood's Reach** (cheaper clearing plus half-price clears from drift 1; it absorbed Cleared Ground on 2026-09-30) | First Care |

**Choice path** (Dreams, families, Omens)

| # | Perk | Levels | Cost per level | Effect (at max) | Needs |
|---|---|---|---|---|---|
| 1 | Second Thoughts | 3 | 50 / 100 / 150 | 3 Dream rerolls per run (level III added 2026-10-04: the reroll the "Dream of everything" milestone used to give) | — (trunk) |
| 2 | Let Go | 1 | 60 | banish 1 card per run | Second Thoughts |
| 3 | Omen Reader | 1 | 80 | after choosing **Face an Omen**, pick from **3** Omens instead of 2 (2026-09-30, see `run_design.md` Omens) | Let Go |
| 4 | Wider Dreams | 1 | 150 | 4 cards per Dream instead of 3 | Omen Reader + Second Thoughts II |
| side 1 | **Wider Choice** *(new 2026-10-06)* | 1 | 80 | every family pick shows **3** families instead of 2 | Second Thoughts |
| side 2 | Early Bloom | 1 | 80 | the first family pick offers **every** unlocked family | Wider Choice |
| side 2 | Early Light | 1 | 120 | **+1 Dreamlight** at run start | Early Bloom |
| side 3 | Kindling | 1 | 90 | start with **a random Common Dream** already taken | Early Light |

**Slots, where the paths meet**

| Slot node | Cost | Needs |
|---|---|---|
| Loadout slot 4 | 140 | the **2nd node of any path** (Rich Dew, First Care or Let Go) |
| Loadout slot 5 | 220 | slot 4 + the **3rd node of two paths** (2 of Rested Roots, Clear Sight, Omen Reader) |
| *(secret)* The Heartwood's Crown (slot 6) | 250 | every other Grove node owned at max level (a bought node since 2026-10-04) |

Slot nodes 2 and 3 are gone (2026-09-29), so the tree is 120 Seeds cheaper. Seed Pouch now sits at
the end of the Economy path, so it can't be rushed first for faster Seeds.


**Keepsakes (cosmetics) live on a shelf, not the tree** (user 2026-10-05). Anything cosmetic is a
milestone achievement unlock, never bought, and isn't a Grove node: the four Keepsakes sit on a
**Keepsakes shelf** opened from a "Keepsakes" button in the Grove footer, each with its on/off toggle
once earned (also in Settings → Display → Keepsakes). Unearned ones show greyed with their milestone
("Win without losing a leaf"). Each milestone also pays its Seed bonus.

| Keepsake | Earned by | What it does |
|---|---|---|
| Golden Leaf | Win without losing a leaf (`flawless_win`) | the in-run Heartwood's leaves turn gold |
| Blossoms | Win at Blight Level 10 (`blight_10_win`) | every Warden wears a small blossom |
| Gilded Pages | Discover every combo (`all_combos`) | the Codex pages get gilded edges |
| Starlit Card Backs | See every Dream card (`all_dreams`) | Dream offer cards get the night-sky frame |

**New bought nodes instead** (user 2026-10-05): options, not power; no loadout slot, always
on once planted. Placement by limb colour (user: *"should be the orange seed, all the card ones
should be purple"*): the non-card ones are **orange Perks nodes on the Perks limb, the left side of the tree** (user: *"the orange seeds are the left side of the Grove tree"*), among the other perks, not a separate twig;
the card one is **purple**, on the Cards limb (the right side).

| Node | Limb | Cost | What it adds | Designed by |
|---|---|---|---|---|
| **Restless Omens** | Cards limb (purple, right), with Strange Dreams | 40 | 4 new double-edged Omens join the Omen pool | the design hub (`run_design.md` Omens) |
| **Remembered Seed** | Perks limb (orange, left) | 30 | start a run on any map from your run history, or type a seed | Main Merger (run start) |
| **Strange Dreams** | Cards limb (purple, right), a small branch with Restless Omens | 50 | a bundle of gamble Dream cards (odd, swingy effects) joins the pool | Roguelite Mechanic Discussion |
| **Chosen Hunt** | Perks limb (orange, left) | 80 | when an act begins, see its 3 possible bosses and pick which one comes (the act 4 Hollow Oak picks its variation) | Enemy Code (boss pools) + Main (the choice screen) |
| **Leaf or Dew** | Perks limb (orange, left) | 40 | before the run, a −3…+3 step: give up to 3 leaves (max and current) for +15 Dew each, or pay 15 Dew per extra leaf (max and current) up to +3. Leaves traded away don't regrow | Meta Game Code (run start) |
| **Kin Foretold** | Perks limb (orange, left), on the run-options path | 60 | at every family pick, also see the families the **next** boss pick will offer, so you can plan which to combine (was pitched as "Family Ties", renamed: a Dream card already has that name) | Main Merger (FamilyPickScreen; the next offer is drawn ahead and kept) |

- **Rule (user 2026-10-05): anything card-like (Dreams, Omens) goes on the right side, purple; the left side, orange, holds run and loadout options.** These count toward the Heartwood's Crown like any bought node. +300 Seeds. (Second Look, a map reroll, was dropped 2026-10-05 as a duplicate of Remembered Seed; Waystone Swap was declined.) (Wanderer's Map, a new map layout, was dropped 2026-10-05: user "Removing it".)
- Each node waits for its content; until then it isn't on the tree.

**Power budget:** 15 perks, carry 3 at the start, up to 5 (6 once the whole tree is grown). A full economy loadout (Morning Stores III, Rich Dew
III, Rested Roots II, Sprout Bed, Clear Sight) makes the early game noticeably smoother, which is
why **Blight Levels** exist: each level takes back some of that power. Caps: starting Dew +30,
Dew gain +15%, leaves +3, rerolls 3 (options, not power).

### Section 2: Families and family upgrades

The **4 starting families** (Sporeling, Firefly Jar, Dewdrop and, since 2026-10-01, **Bellflower**) sit at the base of this limb, already grown. **Bellflower became a starting family** (user via Balancing Discussion, 2026-10-01): with 3, a fresh account's picks at drifts 1 / 25 / 50 used them all and the drift 75 pick fell back to +2 Dreamlight. Bellflower combos with all three starters (Drowsy, Static) and is mid-strength, so the stronger families stay Grove goals. Its node is a `start` node (never bought, its 60 Seeds gone); the first pick offers 3 of the 4. The demo starts with the same 4.
Each family has three nodes stacked above it: **the family** (joins the family picks, with its
branches), **its final forms**, **its hidden branch**.

| Family | Family node | Final forms node | Hidden branch node |
|---|---|---|---|
| Sporeling | *(start)* | 50 (Puffball, Dreamshroom) | 40 (Fairy Ring + Elf Circle) |
| Firefly Jar | *(start)* | 50 (Thunderhead, Beacon) | 60 (Sunpetal; was a milestone until 2026-10-04) |
| Dewdrop | *(start)* | 50 (Monsoon, Morning Fog) | 40 (Frostfern + Hoarfrost) |
| Pebbling | 50 (branches: Mossback, **Standing Stone**) | 50 (Boulderback, Moonstone) | 50 (Cairn + Rockslide) |
| Rootling | 50 | 50 | 40 (Rootlight + Starcave) |
| Bellflower | *(start, since 2026-10-01)* | 50 (Lullaby Bell, Great Dreamcatcher) | 60 (Echo Hollow + Whispering Hollow) |
| Acorn | 70 (needs Pebbling or Rootling) | 50 | 60 (Graftling + Grafted Elder) |
| Nestling | 120 (needs 2 of Pebbling / Rootling / Acorn; Bellflower dropped from the list when it became a starter, so these stay late) | 60 | 80 (Hummingbird Bower + Jewelwing Court; brings the on-hit cards) |
| Whirligig | 120 (needs 2 of Pebbling / Rootling / Acorn) | 60 | 80 (Samara + Autumn Gale; brings the boomerang cards) |

**Unlock order, by design:** the starting families are the easiest to read (spores, water,
light, and Bellflower's sleep since 2026-10-01). Pebbling and Rootling come next (plain roles: hit hard, control). Acorn needs
one of those first, because support is better once you know the basics.
Nestling and Whirligig are the full-game families, and **every hidden branch is a late node**
above its family's final forms, so veterans keep finding new playstyles. Reviewed 2026-09-27
(`tower_design.md`, "Family design rules").

- The Grove decides which forms **exist** in your runs; **Dreamlight** decides which you unlock
  **this run** (`run_design.md`). A final form not yet grown here shows as *"Memory Grove"* on the
  Remember screen.
- A family's own Dream cards (`dream_design.md`, "Cards for the new Wardens") come with its family
  or hidden-branch node automatically: **every family gets at least 2–3 of its own cards** with its family node (or the start pool). Checked 2026-10-01: only Acorn fell short (just Warm Hearth), so **Acorn Cache and Dew Trail (+ II) moved to the Acorn family node** (2026-10-06: Acorn Cache was folded into Warm Hearth, so the node brings Dew Trail; with Warm Hearth Acorn still has 2) and the empty Catchers node was removed (−50 Seeds). Build-defining support cards (Grandfather Stump, Overflowing Well, Hedgerow Roots, Golden Harvest…) stay on The Quiet Ones / Seeds.
- **Ascension nodes** (added 2026-09-27): each family gets one more node at the top of its stack,
  **Ascension (120 Seeds)**, after its hidden branch (or its final forms where a family has no
  hidden-branch node). It makes that family's **Ascended** endgame Warden exist in runs
  (`tower_design.md`); in-run it still needs 3 Dreamlight and 400 Dew. 9 nodes, ≈ 1,080 Seeds.
  **Firefly Jar:** since 2026-10-04 Sunpetal is a normal node (60 Seeds), so **Stormheart's
  Ascension needs Sunpetal**, like the others.
- **Memory Wardens: parked 2026-09-29** (cut for now, `tower_design.md`). While parked, dispelling a
  boss grows no Memory bloom on this limb and the family pick offers no Memory Warden card.
  (Was: a free bloom on the first dispel, then offered after that boss in later runs.)
- Total ≈ 2,000 Seeds incl. Ascension (2026-09-30, final-forms nodes gone; whole tree ≈ 6,040, see Seeds above).
- Each hidden-branch node needs only its family node (since the final-forms nodes left, 2026-09-30).
- **Final-forms nodes removed (user, 2026-09-30).** A family's regular final forms exist as soon as
  you have the family: owning a family in a run gives its base; its branches cost 1 Dreamlight and its final
  forms cost Dreamlight (`run_design.md`, "Dreamlight"). New players always have something to spend
  Dreamlight on, and the starting families' finals (Thunderhead, Beacon, Puffball, …) are there
  from the first run. So:
  - The **Final forms node** column above is gone (9 nodes, ~470 Seeds). **Hidden-branch nodes now
    need only their family** (the family node, or nothing for the starting four).
  - **Stormheart's Ascension** (the Firefly Jar exception) needs Sunpetal (2026-10-04; was Seeds only).
  - The Seeds this frees should go to the other roots or lower the tree's total; the meta chat
    rebalances (`meta_design.md` Seeds totals, Grove node data).

### Branch expansion in the Grove (APPROVED by the user 2026-10-02)

For `tower_design.md` "Branch expansion" (5 regular branches + 1 hidden per family, **2 of the 5
offered per run** on the Remember screen, the Dreamlight call-back for 3, *Remembered Path*).
Full game only; the demo is unchanged.

- **A family node brings all 5 regular branches into the run's draw.** Planting a family (or owning
  a starting family) puts its 5 branches and their finals in the pool the run draws its 2 from.
  No per-branch nodes: buying branches one by one would let a veteran strip the pool down to their
  favourites, which is exactly what the expansion stops.
- **The hidden branch stays its own node** (as now, 40–80 Seeds after the family): owned = offered
  every run **on top of** the 2.
- **The family node's card** lists its 5 branches with their one-line jobs and finals, and says
  *"In your dreams: 2 a run."* The hidden-branch node's card is as now. Families not expanded yet
  (Pebbling, Rootling, Acorn; the sky merge) list their current branches until their phase lands.
- **Sky merge (Phase 3, later):** Nestling and Whirligig become one family node, the Whirligig
  hidden node goes (Samara is regular), and the two Ascension nodes become one (`tower_design.md`).
- **One new perk** (Choice path, after Omen Reader; an option, not raw power):
  **Wider Roots** (120): the family you take at the first family pick (its card previews 3 branches) offers **3 of its 5**
  this run, but the Dreamlight call-back costs **4** instead of 3. It's a sidegrade in Hades mode
  as well, so the Grove power cap holds.
- **Rejected: a "pin" (always offer one chosen branch).** It brings back the same build every run,
  the problem the expansion solves. Steering stays paid for in the run (call-back, Remembered Path).
- **Codex Families page and the Grove directory** list each family's 5 branches + hidden with
  their roles (Main Merger).
- **Art:** the Grove draws families, not branches, so no new node art except the Wider Roots icon;
  the node cards use the branches' tower portraits. Meta Game Asset updates the gallery.

### Section 3: Cards (Dream pool unlocks)

Revised 2026-09-27. Cards come in **themed bundles** (one node = a set of Grove cards joining the
Dream pool). The limb splits into **one branch per build style**; each branch grows from cheap
bundles near the trunk to **a Legendary flower at its tip**. So the tree also shows which build
styles a player has grown into.

**No combo cards in the Grove** (user, 2026-09-30: *"combo cards shouldn't be locked behind the
Grove; other generic cards that help with builds or can define builds should be"*). The Cards limb
holds only **generic build cards**: ones that help or define a build style, not ones that pay off
two systems together.
- **Combo cards unlock by discovering their combo in play** (like the Reactions, Woven and Kinship
  cards since 2026-09-29, `dream_design.md` "Grove overlap"): **Dawnbreak** (a ×10 Reaction chain),
  **Grove of Kin** (a Kinship), **Static Bloom** (Storm + Sleep), **Chain Bloom** (Puffball in
  Mistveil's fog), **Starlit Aim** (Marked + crit).
- **Family cards** left over (Static Field, Twin Puff, Guiding Light) come with their family; all
  three are starting families, so they're always in the pool.
- So the **Storm**, **Spores and Reactions** and **Kinship** branches are gone (Storm Lore 40,
  Guiding Lights 60, Spore Lore 40, Dawnbreak 120, Grove of Kin 120 = −380, refunded to old saves).
- Two **new build branches** take their place (+480): **Swift** (attack speed) and **Wide Reach**
  (area / splash). Cards to be designed by Roguelite Mechanic Discussion; each tip is a
  build-defining Legendary. Tree ≈ **6,140 Seeds**, still ~30 hours.

**Lean starting pool** (2026-09-30, user "implement" via the design hub; `dream_design.md` "The
starting Dream pool"): a fresh profile starts with **65 cards (25 C / 30 U / 10 R / 0 L)**. Every
build-defining card, most Rares and **all Legendaries** now live on these nodes, **one build
direction per branch**, so each purchase deliberately widens one build. Combo cards (incl. the
**Kinship** cards Rooted Bond, Extended Family, Blood Is Thicker) are **never** here: they unlock by
discovery in play. Branches may **fork** into two tips (each tip needs the node below it).

| Branch (direction) | Node 1 (near the trunk) | Node 2 | Tip(s): Legendary |
|---|---|---|---|
| **Swift** (attack speed) | *Quickening*: Hunt's Rush (the card Quickening, renamed in the card pass) (30) | *Light Feet*: Restless Roots, Hummingheart (60) | **Whirlwind Heart** (120) |
| **Wide Reach** (area, splash) | *Broad Strokes*: Lingering Splash (30) | *Far Reach*: Far Reach, Spillover (70) | **Great Ripple** (120) |
| **Keen Edges** (precision, crit) | *Sharpened*: Still Target, Shattering Blow, **Hunter's Patience**, **Sharpened Light** (50) | — | **Full Moon** (120) · **Hunter's Moon** (80) |
| **Deep Poison** (affliction, effects) | *Seeping* (50) | *Venom*: Venom Bloom (40) | **Nightshade** (120) · **Eternal Charge** (80) |
| **Daring** (low leaves, tempo) *(new)* | *Scarred Bark*: Scarred Bark, Thin Bark (40) | *Last Stand*: Desperate Bloom, Second Wind, Last Stand (50) | **Last Leaf** (80) · **Restless Night** (80) |
| **Tending** (nurture, tall) | *Tending Hands*: Deeper Rings (50; Sunlit Rest moved to the start pool 2026-10-06 as Tall's third door) | *Nursery*: Nursery, Chosen Few (70) → *Elders*: Elder Kin, Few and Mighty (40) | **The Old Ones** + **Endless Rings** (150; needs Elders) |
| **Lone Lantern** (narrow) | *One Line*: Monoculture (80) | — | **The Last Light** (120) |
| **Overgrowth** (wide) | *Seedbed*: Seedling Gift, Canopy (60) | *Mixed Company*: Mixed Grove, Grand Tour (40) | **Rootbound** (100; needs Seedbed) · **Menagerie** (80; needs Mixed Company) |
| *(2026-10-05: Momentum, Drumbeat, Overlap, Crowd Breaker, Solitude and Odd One Out moved back to the start pool as Uncommons, `dream_design.md` "Fewer family boosters, more build shapes"; their nodes cost 10 less, except Seeping, back to its original 50.)* | | | |
| *(2026-10-06, "Fewer, bigger cards", `dream_design.md` de439ea8: Flurry moved to the start pool, Broad Splash folded into Far Reach, Acorn Cache into Warm Hearth; Quickening and Broad Strokes now 30.)* | | | |
| **The Long Way** (path length) | *Dead Wood*: Burn Back the Dead Wood (40) | *Winding Roads*: Forest's Edge (50) | **The Long Walk** (100; needs Dead Wood) · **Crossroads** (80; needs Winding Roads) |
| **Hedgerows** (walls, holding) *(new)* | *Bitter Hedges*: Bitter Hedges, **Thornheart** (40) | — | **Briar Crown** (80) · **Rooted Nightmares** (80) |
| **Reclaiming** (clearing) *(new)* | *Reclaimed Earth*: Reclaimed Earth, Tended Stumps, Hollow Ground (50; the "where you clear" payoffs first) | *Thorn and Bramble*: Tended Forest, Thorn Snare, Bramble Oath (70) | **Wildwood Reclaimed** (80) |
| **The Quiet Ones** (support Wardens) | *Old Wood*: Overflowing Well, Hedgerow Roots, Grandfather Stump, Living Walls, **Scented Hedge**, Many Threads (70) | — (*Catchers* removed 2026-10-01: Dew Trail and Acorn Cache moved to the Acorn family node) | **The Quiet Ones** (120; needs Old Wood) |
| **Seeds** (support and economy bets) | *Planted Promises*: Dew Bowl, Harvest Moon, Kind Canopy, Patient Roots (50) | *Deep Promises*: Deep Well, Shared Light (70) | **Golden Harvest** (120) |
| **Bittersweet** | *Bittersweet Dreams*: Deep Sleep, Restless Dreams (60; needs any 2 other nodes) | — | **Lucid Dreaming** (80; the "dreams" Legendary: 4 cards, take 2, no Commons) |

- **Costs:** the new tips and nodes are cheaper (tips 80, nodes 40–50) than the original ones, so a
  direction is reachable in 2–3 runs. **+1,200 Seeds**: the tree is **≈ 7,340 Seeds ≈ 26 runs ≈
  33–36 hours**, a little over the ~30-hour target (as it was at 6,722); fine, since every early
  run still buys something.
- **Old saves:** no special handling (user 2026-09-30: *"this game isn't out yet, so don't worry
  about players"*). Owned nodes that still exist stay owned; there are no free grants (the v8 / v9
  grants were removed, 016ca4ec).
- **Rule from now on (until release):** Grove changes come **without** player-protecting
  migrations (no refunds, no free grants) unless the user asks for one. Revisit at launch, when
  real players' saves matter.

Removed over time: Reactions, Woven Dreams I–II, Kin Lore, Deep Bonds (2026-09-29, discovery
unlocks); Reckless, Wild Planting (2026-09-30, pool trim); Storm Lore, Guiding Lights, Spore Lore,
Dawnbreak, Grove of Kin (2026-09-30, no combo cards in the Grove).

- Each node needs the one before it on its branch; a tip needs both nodes below it (or the one,
  where a branch has a single node).
- **Family-specific cards** (Skipping Stones, Deep Frost, Sweet Scent, etc.) aren't here: they come
  with their family or hidden-branch node on the Families limb.
- **Start-pool cards** (65 since 2026-09-30: basics, the starting families' cards, one or two tasters per build) are always available, so a
  new player already has a full Dream pool; this limb adds depth and big payoffs.
- Total ≈ 3,370 Seeds as of 2026-09-30 (lean starting pool). New cards join an existing branch's bundle or start a new branch; **combo cards never go here**.
**Family picks show 2, the Grove widens them** (user 2026-10-06): every family pick (drift 1 and the
25 / 50 / 75 bosses) shows **2** families, so new players have fewer choices and a run takes what the
forest gives more often. The Perks node **Wider Choice** (80, Choice path) raises every pick to 3;
**Early Bloom** (after it) makes the first pick show every owned family.
- **At least one attacking family in every pick:** a pick never offers only support families
  (today: Acorn), so a run can't start with no real damage.
- Fewer than 2 new families left: show what's left (1 card); none left: +2 Dreamlight as before.
- Kin Foretold previews 2 (3 with Wider Choice). Wider Roots is unchanged.


**Families before the Grove fills in:** a new player has only 4 families (Sporeling, Firefly Jar,
Dewdrop, Bellflower; was 3 until 2026-10-01), but a run offers family picks at drift 1 and at the 25/50/75 bosses. When there are
fewer than 3 new families to offer, the empty slots become **Family Blessings**: a strong boon for
a family you already own (e.g. *"Sporeling Blessing: Sporeling family +25% soothe, evolutions 25%
cheaper"*). So early runs deepen few families; unlocking Pebbling, Rootling, Bellflower and Acorn widens later
runs, which makes those Grove purchases feel big.

**Replaced 2026-09-30** (user: *"not a fan of the Blessing here, you get it every time if you have no
family unlocked"*): with only the 3 starting families, a Blessing filled a slot at **every** boss pick,
so it was predictable, not a choice.
- **The family pick shows only real families:** 3 when there are 3+ new families, otherwise **2 or 1
  cards**. No filler slots.
- **When no new family is left**, there is no family pick at that boss: the Heartwood gives **+2
  Dreamlight** instead (*"The Heartwood remembers deeper."*), for finals and Ascended forms.
- **Blessings move into the Dream pool** as **Rare** cards (one per family, all 9 including Bellflower: +25% damage and 25% cheaper growth for that family; Needs: that family; one each, no stacking, no Deepened; from act 2, like their old boss-pick timing), offered
  like any other card, so they turn up now and then as a real choice instead of every boss.
- Unlocking families in the Grove still widens later runs, and a full Grove never needs any of this.

### Later: Forests

New biomes (e.g. **Misty Marsh**, **Autumn Hollow**) will be a small fourth limb or nodes at the top
of the Perks limb once they're designed (`design_plan.md` topic 9); not in the first version.

### Memories and the tree

A Memory fragment appears **every 3 nodes planted** (plus the milestone ones below), as a
**dream-fruit** hanging from the Heartwood's branches. About 55 nodes, so all 10 Memories arrive well before the tree is complete.

## Milestones (bonus Seeds; double as Steam achievements)

**Milestones only give bonus Seeds** (user, 2026-10-04; replaces the free unlocks). A milestone
never grows a gameplay node, refunds a purchase or unlocks a Memory: **every gameplay node is bought
with Seeds**; the only exception is cosmetic (four milestones also earn a Keepsake on the Keepsakes shelf, Section 1, user 2026-10-05). Each milestone pays a **one-time Seed bonus** at the run end it's reached, as its own
results line (*"Milestone · Dispel 3,000 Shades · +25 Seeds"*), scaled by how hard it is. Steam
achievements still map to the milestone ids. Dev runs record none (as before).

| Milestone (id) | Bonus | Was |
|---|---|---|
| Dispel your first boss (`first_boss`) | +20 | Memory fragment |
| Win a run (`first_win`) | +60 | Memory fragment (Blight Levels still open with the first win: a rule, not a reward) |
| Dispel **3,000** Shades, total (`shades_500`, id kept) | +25 | Sunpetal; 500 now happens in one run (a good run dispels ~700) |
| Build a **130-tile** path (`path_300`, id kept) | +30 | The Long Walk card; 300 can't fit on a 23×18 map |
| Tend **120** obstacles, total (`tend_100`, id kept) | +25 | Memory fragment; was 100 |
| Win without losing a leaf (`flawless_win`) | +100 | Golden Leaf cosmetic |
| Win with only one Warden family (`one_line_win`) | +80 | Monoculture card |
| Reach Blight Level 5 (`blight_5`) | +50 | Memory fragment |
| Win at Blight Level 10 (`blight_10_win`) | +150 | Blossom cosmetic |
| Discover every combo (`all_combos`) | +60 | Memory fragment + gilded pages |
| See every Dream card (`all_dreams`) | +60 | starlit card backs + 1 reroll |
| Meet every nightmare (`all_nightmares`) | +40 | — |

- **Thresholds** set by Balancing Discussion 2026-10-04 from the user's records (3,000 Shades ≈ 4–5 good runs; 130 tiles = a genuinely long maze; 120 tends);
  they may retune them, e.g. once `longest_path` is in the run history.
- **Memories** now come only from the first run and Grove growth (one per 3 levels planted); 10
  arrive well before the tree is complete.
- **Cosmetics** (Golden Leaf, Blossoms, gilded pages, starlit backs) are Keepsakes on a shelf, earned by their milestone
  (Section 1; flawless win, Blight 10 win, every combo, every Dream card); the extra reroll is Second Thoughts III (bought).
- **Sunpetal** (Firefly Jar's hidden branch) is a normal node: **60 Seeds, needs Firefly Jar**, like
  the other hidden branches. **Stormheart's Ascension** now needs Sunpetal, like every other
  Ascension needs its hidden branch.
- **The secret 6th slot becomes a node:** **The Heartwood's Crown** (Perks limb, **250 Seeds**,
  needs every other node at max level). It stays hidden (no node, no waystone) until its
  requirement is met, then the sixth waystone rises and the node can be planted. Its Steam
  achievement fires on planting it. (Was the `full_bloom` milestone.)
- **Pre-release:** no migration. A node a milestone already grew on a profile (Sunpetal) is
  **reset**: buy it again. Milestones already recorded don't pay retroactively.



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
come from Grove progress (**one every 3 unlocks**, plus one after the first run; milestones no longer give Memories since 2026-10-04). Read in
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
