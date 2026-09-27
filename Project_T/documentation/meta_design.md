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
| Each boss dispelled | 10 |
| Each obstacle tended | 1 (see `run_design.md`) |
| Winning | +50 |
| Blight Level | +10% per level (Level 10 = double) |

Examples: a loss around drift 20 ≈ **25 Seeds**; a loss at drift 60 ≈ **80**; a win ≈ **220**.
Averaging ~170 across a player's first runs, the Grove below (~2,300 Seeds) takes **~13–14 runs
≈ 18–20 hours**.

**Every run should buy something early on**: the cheapest unlocks cost 20–25, so even a bad first
run grows the Grove. Losing early in a long run is also cushioned by the mid-run save: players can
stop at any rest and come back.

## Seeds from the demo

The demo has no Grove (`demo_scope.md`), but **every Seed earned in the demo is saved**. When the
player owns the full game, those Seeds are waiting in their Grove on first launch: *"The forest
remembered you."* This works if the demo and full game share the save format and location (same
project name, so the same `user://` folder); the full game reads the demo's saved Seeds once and
marks them as imported.

## The Memory Grove

A garden screen between runs. Each unlock grows as a plant on one of **4 roots**; later unlocks on a
root need earlier ones. Costs rise along a root, so early choices are cheap and fast.

### Wardens root: new lines and forms (~680)

| Unlock | Cost | Needs |
|---|---|---|
| Pebbling line (joins the family picks; its branches and cards join the Dream pool) | 50 | — |
| Rootling line | 50 | — |
| Acorn line | 70 | Pebbling or Rootling |
| Beacon (Firefly final, Lanternmoth side) | 50 | — |
| Sporeling finals (Puffball, Dreamshroom) | 80 | — |
| Dewdrop finals (Monsoon, Morning Fog) | 80 | — |
| Pebbling finals (Boulderback, Lullaby Bell) | 100 | Pebbling line |
| Rootling finals (Long Way Home, Snugroot) | 100 | Rootling line |
| Acorn finals (Grove Heart, Wellspring) | 100 | Acorn line |

Final forms still need their Rare Dream in-run; the Grove only puts them in the pool.

**Families before the Grove fills in:** a new player has only 3 families (Sporeling, Firefly Jar,
Dewdrop), but a run offers family picks at drift 1 and at the 25/50/75 bosses. When there are
fewer than 3 new families to offer, the empty slots become **Family Blessings**: a strong boon for
a family you already own (e.g. *"Sporeling Blessing: Sporeling family +25% soothe, evolutions 25%
cheaper"*). So early runs deepen few families; unlocking Pebbling, Rootling and Acorn widens later
runs, which makes those Grove purchases feel big.

### Dreams root: new cards (~510)

The "Grove" cards in `dream_design.md`: Static Bloom 25, Twin Puff 25, Static Field 50,
Guiding Light 50, Seedling Gift 60, then the Legendaries (The Long Walk, Rootbound, Monoculture)
at 100 each.

### Perks root: permanent power, capped (~810)

| Perk | Levels | Cost per level | Effect at max |
|---|---|---|---|
| Morning Stores | 3 | 20 / 40 / 60 | +30 starting Dew (+50%) |
| Deep Taproot | 3 | 25 / 50 / 75 | +3 max leaves |
| Early Bloom | 1 | 80 | the first family pick (after drift 1) offers all 6 families instead of 3 random |
| Second Thoughts | 2 | 50 / 100 | 2 Dream rerolls per run |
| Let Go | 1 | 60 | banish 1 card per run (it never appears again that run) |
| Seed Pouch | 1 | 100 | +10% Seeds |
| Wider Dreams | 1 | 150 | 4 cards per Dream instead of 3 |

**Power caps:** starting Dew +50%, leaves +3, rerolls 2. Power perks make runs smoother but never
replace good building. Watch Wider Dreams + rerolls together with unlimited stat stacking.

### Forests root: new biomes (~320, after first playable)

Two extra forests (e.g. **Misty Marsh**, **Autumn Hollow**) with their own obstacles, look and a
rule twist; 120 and 200 Seeds. Designed in Phase 4 (`design_plan.md` topic 9).

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
| 1 | Creatures +10% health |
| 2 | Starting Dew −20 |
| 3 | Bosses +25% health |
| 4 | Drift-clear bonus −25% |
| 5 | One nightmare per drift is **Deeply Blighted** (×3 health, costs 2 leaves; see `acts_1_2.md`) |
| 6 | The Heartwood regrows only 1 leaf per act break (instead of 3) |
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
- `UnlockData` resources: id, root, cost per level, levels, prerequisites, effect (adds ids to the
  Dream pool, modifies a starting value, or unlocks a biome).
- `MemoryData` resources: order, text, art, trigger (unlock count or milestone id).
- `BlightLevelData` resources (or one list): level, description, modifiers.
