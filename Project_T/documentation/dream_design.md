# Dream Design: the in-run upgrade pool

Phase 2 of `design_plan.md`. Covers the first-playable scope from `tower_design.md` (Sprout,
Thornwall, Sporeling, Firefly Jar, Dewdrop, their branches, and Thunderhead). Timing: 8 Dreams per
run, after drifts 1, 3, 5★, 7, 9, 10★, 12, 14 (see `run_design.md`). Numbers are starting points.

## Goals

- **Builds come together.** With 8 Dreams you can't have everything, so each run leans one way.
  The pool must make at least one full build reachable in most runs (checked below for Storm Grid).
- **Every card is a real choice.** Stat cards are safe; rule cards are exciting; unlock cards open
  a direction. An offer should usually mix kinds.
- **Maze matters.** Several cards reward how you build the maze (corners, walls, path length), not
  just damage.

## How offers work

- **3 cards per Dream.** No duplicates within an offer.
- **Drift 1 Dream:** always the 3 base Wardens (Sporeling, Firefly Jar, Dewdrop); pick 1. Later,
  the other bases appear as Common cards.
- **Rarity weights by act:**

  | Act | Common | Uncommon | Rare | Legendary |
  |---|---|---|---|---|
  | 1 | 65 | 28 | 7 | 0 |
  | 2 | 50 | 32 | 15 | 3 |
  | 3 | 38 | 34 | 22 | 6 |

- **Boss Dreams** (after drifts 5 and 10): at least one card is Rare or better.
- **Pity:** 3 Dreams in a row without a Rare+ card → the next offer includes one.
- **Tag weighting:** cards tagged with a line you've unlocked are **2× as likely**. Builds converge
  without being forced.
- **Prerequisites:** a card never appears if it can't do anything yet (e.g. Stormcap cards need
  Firefly Jar).
- **Stacking:** stat cards (Commons 1–7) **stack without limit** (shown as "II", "III", …);
  everything else once. Stacks add, not multiply (3× Quickened Sap = +30%, not +33.1%), so power
  grows in a straight line. In practice 8 Dreams per run caps it (+80% at the extreme), and Grove
  perks that add Dreams or rerolls are what push it further; watch those in balancing.
- **Let it pass:** you may skip a Dream for +15 Dew. A cozy escape hatch when nothing fits.
- **Target:** a deliberate dream build (e.g. Storm Grid) completes in about **1 run in 3**.
- **Reroll / banish:** not in the base game; Memory Grove perks add them (see `game_design.md`).

## What an unlock card says

Unlock cards explain the Sprout rule on the card, e.g. *"Sporeling: Sprouts can now grow into
Sporelings (15 Dew), or plant one directly (25 Dew)."* Branch cards: *"Stormcap: Firefly Jars can
now grow into Stormcaps (45 Dew)."*

## The pool (36 cards)

**Start** = in the pool from the very first run. **Grove** = unlocked in the Memory Grove (meta).

### Common: steady growth

| # | Card | Effect | Tags | Pool |
|---|---|---|---|---|
| 1 | **Quickened Sap** | all Wardens +10% attack speed | — | Start |
| 2 | **Deeper Calm** | all Wardens +10% soothe | — | Start |
| 3 | **Longer Roots** | all Wardens +0.25 range | — | Start |
| 4 | **Sprout Surge** | Sprouts +30% soothe, +0.5 range | sprout | Start |
| 5 | **Soft Spores** | Spored +25% strength | spore | Start |
| 6 | **Brighter Jars** | Firefly line +15% attack speed | light | Start |
| 7 | **Heavy Dew** | Dewdrop line +25% splash radius, Damp +1 s | water | Start |
| 8 | **Cheap Hedges** | Thornwalls cost 2 (once) | wall | Start |
| 9 | **Morning Dew** | +20 Dew now, +5 on every drift clear | economy | Start |
| 10 | **Deep Roots** | +2 max leaves, regrow 2 now | leaves | Start |
| 11–13 | **Sporeling / Firefly Jar / Dewdrop** | unlock that base Warden | its line | Start |

### Uncommon: new directions and small rules

| # | Card | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|
| 14 | **Driftspore** | unlock branch | spore | Sporeling | Start |
| 15 | **Bloomcap** | unlock branch | spore, sleep | Sporeling | Start |
| 16 | **Stormcap** | unlock branch | light, storm | Firefly Jar | Start |
| 17 | **Lanternmoth** | unlock branch | light, mark | Firefly Jar | Start |
| 18 | **Rain Lily** | unlock branch | water | Dewdrop | Start |
| 19 | **Mistveil** | unlock branch | water, fog | Dewdrop | Start |
| 20 | **Bramble** | Thornwalls can grow into Brambles (+10 Dew each) | wall | — | Start |
| 21 | **Cozy Corners** | Wardens beside a bend in the path +15% soothe | maze | — | Start |
| 22 | **Hedge Maze** | +1% soothe per 5 Thornwalls you have (max +20%) | wall, maze | — | Start |
| 23 | **Evergreen** | evolving costs 25% less Dew | economy | — | Start |
| 24 | **Lingering Spores** | Spored lasts 3 s longer | spore | Sporeling | Start |
| 25 | **Soaked Through** | Damp lasts twice as long | water | Dewdrop | Start |
| 26 | **Static Bloom** | Stormcap chains also apply 1 Drowsy | storm, sleep | Stormcap | Grove |
| 27 | **Twin Puff** | every 3rd Sporeling attack fires twice | spore | Sporeling | Grove |

### Rare: combo enablers and final forms

| # | Card | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|
| 28 | **Thunderhead** | Stormcaps can grow into Thunderheads (90 Dew) | storm | Stormcap | Start |
| 29 | **Conductive Soil** | lightning jumps to *every* Damp creature in range | storm, water | Firefly Jar + Dewdrop | Start |
| 30 | **Spore Cascade** | a cleansed creature's Spored stacks spread to the 2 nearest creatures | spore | Sporeling | Start |
| 31 | **Static Field** | Static bolts also hit creatures within 1 tile | storm | Firefly Jar | Grove |
| 32 | **Guiding Light** | Marked spreads to creatures within 1 tile of the target | mark | Lanternmoth | Grove |
| 33 | **Seedling Gift** | after every drift, plant a free Sprout | sprout, economy | — | Grove |

### Legendary: changes how you play (act 2+ only)

| # | Card | Effect | Tags | Pool |
|---|---|---|---|---|
| 34 | **The Long Walk** | +1% soothe per 4 path tiles | maze | Grove |
| 35 | **Rootbound** | Wardens touching 3+ other Wardens attack twice | maze | Grove |
| 36 | **Monoculture** | if all your attacking Wardens are one line: +60% soothe | — | Grove |

*Bittersweet cards* (big upside, gentle cost, e.g. **Deep Sleep**: +40% soothe, lose 2 leaves)
are parked for later; they're only worth it once leaves are tuned.

## Reachability check: Storm Grid

Storm Grid = Dewdrop/Rain Lily + Firefly Jar/Stormcap/Thunderhead + *Conductive Soil*.
Needs: 2 bases, 2 branches, Thunderhead, Conductive Soil = **6 of 8 Dreams**.

- Drift 1 gives a base for free; the second base is a tag-weighted Common.
- Branch cards are 2× likely once their base is owned; the boss Dreams guarantee a Rare, and
  both Thunderhead and Conductive Soil are Rares with matching tags.
- Estimate: the full build lands in roughly **1 run in 3** if you aim for it, and a partial
  version (without Thunderhead) in most runs. **That's the agreed target**: the dream build is a
  highlight, not a given. Verify with a quick offer simulation once `UpgradeData` exists, and tune
  tag weighting (2×) up or down to hit it.

## Status effect numbers

Status strength **scales with the Warden that applies it** (a % of its soothe), so statuses keep
up with creature health and benefit from stat Dreams and evolutions.

| Status | Effect | Duration | Stacks | Notes |
|---|---|---|---|---|
| **Damp** | −10% speed | 4 s, refreshed on reapply | no | Rain Lily 6 s; Mistveil fog keeps it on |
| **Drowsy** | −8% speed per stack | 3 s, refreshed | up to 5 (−40%) | Dreamshroom: at 5 stacks, sleep 1.5 s, once per creature |
| **Spored** | soothe per second per stack = 25% of the applier's soothe | 5 s, refreshed | up to 8 (Driftspore 12) | Puffball pops at 10+ |
| **Marked** | +25% soothe taken from all sources | 5 s | no | Beacon +35% |
| **Static** | a charge; at 5 stacks, a free bolt worth 3× the applier's soothe, then reset | loses 1 stack per 2 s | up to 5 | |
| **Held** | can't move | 1 s | no | not in first-playable scope (Rootling line) |

**Bosses:** Drowsy cap 3, Held duration halved, Static bolts at 8 stacks instead of 5.

## Data (`UpgradeData`)

`id`, `display_name`, `description`, `rarity`, `kind` (unlock_warden / unlock_evolution / stat /
rule / economy), `tags: Array[String]`, `requires: Array[String]` (ids of Wardens or cards),
`max_stacks` (0 = unlimited for stat cards, else 1), `min_act` (Legendary = 2), `in_start_pool: bool`,
plus effect parameters (stat modifiers: target line + stat + amount; or a `rule_id` the game
checks for).
