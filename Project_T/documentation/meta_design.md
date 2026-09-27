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
| Nightmares dispelled | 1 per 25 (~60 in a full run) |
| Each boss dispelled | **15** (was 10) |
| Each obstacle tended | 1 (see `run_design.md`) |
| Winning | **+80** (was 50) |
| Blight Level | +10% per level (Level 10 = double) |

Examples: a loss around drift 20 ≈ **25 Seeds**; a loss at drift 60 ≈ **95**; a win ≈ **270**.
Averaging ~220 across a player's first runs, the tech tree below (~3,100 Seeds) takes **~14 runs
≈ 20 hours**. (Raised 2026-09-27 when the Grove grew into the tech tree.)

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

**How it looks and works** (`screens_ui.md`, meta screens): the Heartwood at the bottom, the three
limbs branching up. Each node is a bud (locked, cost shown), a glowing bud (affordable, parents
owned) or a bloom (owned). Tap or click a node for its card and a **Plant** button. Pan and zoom
like the map. A Seeds counter top left; a **Memories** shelf; **Start run** opens the loadout
(below) first.

### Section 1: Perks (bring into the game)

Perks are **unlocked** in the tree, then **equipped** in a small **loadout** before each run
("Carry into the dream"). You own many but carry few, so the loadout is a choice every run.

- **Loadout slots: maximum 3 for now** (user decision 2026-09-27): 1 at the start; the tree adds a
  2nd (40) and a 3rd (100).
- A perk with levels (e.g. Morning Stores I–III) takes one slot at its highest owned level.
- Loadout is kept between runs; change it any time before starting.

| Node | Levels | Cost per level | Effect (at max) | Needs |
|---|---|---|---|---|
| Morning Stores | 3 | 20 / 40 / 60 | +30 starting Dew | — |
| Deep Taproot | 3 | 25 / 50 / 75 | +3 max leaves | — |
| Sprout Bed | 1 | 60 | start with 2 free Sprouts to place | Morning Stores I |
| Clear Sight | 1 | 80 | clearing is unlocked from the start (no clearing card needed) | — |
| Early Bloom | 1 | 80 | the first family pick offers every unlocked family | — |
| Early Light | 1 | 120 | +1 Dreamlight at run start | Early Bloom |
| Second Thoughts | 2 | 50 / 100 | 2 Dream rerolls per run | — |
| Let Go | 1 | 60 | banish 1 card per run | Second Thoughts I |
| Omen Reader | 1 | 80 | Omen rests offer 3 Omens instead of 2 | — |
| Seed Pouch | 1 | 100 | +10% Seeds | — |
| Wider Dreams | 1 | 150 | 4 cards per Dream instead of 3 | Second Thoughts II |
| Loadout slot 2 / 3 | — | 40 / 100 | carry one more perk (max 3) | slot 2 → 3 |

**Power caps stay:** starting Dew +30, leaves +3, rerolls 2. With 3 slots at most, a player picks
3 of ~11 perks each run: never everything at once.

### Section 2: Families and family upgrades

The starting families (Sporeling, Firefly Jar, Dewdrop) sit at the base of this limb, already grown.
Each family has three nodes stacked above it: **the family** (joins the family picks, with its
branches), **its final forms**, **its hidden branch**.

| Family | Family node | Final forms node | Hidden branch node |
|---|---|---|---|
| Sporeling | *(start)* | 50 (Puffball, Dreamshroom) | 40 (Fairy Ring + Elf Circle) |
| Firefly Jar | *(start)* | 50 (Thunderhead, Beacon) | *milestone:* Sunpetal |
| Dewdrop | *(start)* | 50 (Monsoon, Morning Fog) | 40 (Frostfern + Hoarfrost) |
| Pebbling | 50 | 50 | 40 (Standing Stone + Moonstone) |
| Rootling | 50 | 50 | 40 (Rootlight + Starcave) |
| Acorn | 70 (needs Pebbling or Rootling) | 50 | 60 (Graftling + Grafted Elder) |
| Nestling | 120 (needs 2 of Pebbling / Rootling / Acorn) | 60 | — |
| Whirligig | 120 (needs 2 of Pebbling / Rootling / Acorn) | 60 | — |

- The Grove decides which forms **exist** in your runs; **Dreamlight** decides which you unlock
  **this run** (`run_design.md`). A final form not yet grown here shows as *"Memory Grove"* on the
  Remember screen.
- A family's own Dream cards (`dream_design.md`, "Cards for the new Wardens") come with its family
  or hidden-branch node automatically.
- **Memory Wardens** aren't bought: dispelling a boss for the first time grows its Memory Warden as a
  free bloom on this limb, and it's offered after that boss in later runs.
- Total ≈ 1,100 Seeds.

### Section 3: Cards (Dream pool unlocks)

Cards come in **themed bundles** (one node = a set of Grove cards joining the Dream pool), so the
limb stays readable and each purchase feels big. The Legendaries sit at the top.

| Node | Cards it adds | Cost | Needs |
|---|---|---|---|
| Storm Lore | Static Bloom, Static Field | 40 | — |
| Spore Lore | Twin Puff, Chain Bloom | 40 | — |
| Guiding Lights | Guiding Light, Starlit Aim | 50 | Storm Lore |
| Keen Edges (crit) | Still Target, Shattering Blow, Reckless Bloom | 70 | — |
| Tending Hands (nurture) | Sunlit Rest, Deeper Rings, Nursery, The Old Ones, Chosen Few | 90 | — |
| Overgrowth (wide) | Seedling Gift, Canopy, Overgrowth | 70 | — |
| Lone Lantern (narrow) | The Last Light | 70 | — |
| Dead Wood (clearing) | Burn Back the Dead Wood | 40 | — |
| Bittersweet Dreams | Wild Growth, Borrowed Memory, Deep Sleep and the other Bittersweet Grove cards | 60 | any 2 bundles |
| **The Long Walk** | Legendary | 100 | any 3 bundles |
| **Rootbound** | Legendary | 100 | any 3 bundles |
| **Monoculture** | Legendary | 100 | any 3 bundles |
| **Full Moon** | Legendary | 120 | Keen Edges |

Total ≈ 900 Seeds. Cards added later go into an existing bundle or a new one.

**Families before the Grove fills in:** a new player has only 3 families (Sporeling, Firefly Jar,
Dewdrop), but a run offers family picks at drift 1 and at the 25/50/75 bosses. When there are
fewer than 3 new families to offer, the empty slots become **Family Blessings**: a strong boon for
a family you already own (e.g. *"Sporeling Blessing: Sporeling family +25% soothe, evolutions 25%
cheaper"*). So early runs deepen few families; unlocking Pebbling, Rootling and Acorn widens later
runs, which makes those Grove purchases feel big.

### Later: Forests

New biomes (e.g. **Misty Marsh**, **Autumn Hollow**) will be a small fourth limb or nodes at the top
of the Perks limb once they're designed (`design_plan.md` topic 9); not in the first version.

### Memories and the tree

A Memory fragment blooms **every 3 nodes planted** (plus the milestone ones below), shown as a leaf
on the Memories shelf. About 55 nodes, so all 10 Memories arrive well before the tree is complete.

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
