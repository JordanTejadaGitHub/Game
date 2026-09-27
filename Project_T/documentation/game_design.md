# Game Design — *The Heartwood Remembers*

Story and tone: see `story.md`. Goal: commercial release on Steam, all art original (the Foozle
packs in `assets/` are placeholders).

## Core loop (one run)

```
Title → New run → [Build phase → Drift → cleanse creatures, earn Dew]
      → every few drifts: Dream (pick 1 of 3) → repeat
      → Win (survive all drifts) or Lose (all leaves fall) → Results (Seeds earned)
      → Memory Grove (spend Seeds) → Title
```

- **Build phase:** place Wardens (towers are walls; path must stay open). Player presses
  **Start Drift** when ready. No timer; this is a relaxed game.
- **Drift:** a wave of blighted creatures walks from start to the Heartwood.
- **Cleanse:** Wardens soothe creatures; at 0 health a creature is cleansed (colour returns, it
  leaves the path) and drops **Dew**.
- **Leaves:** each creature reaching the Heartwood wilts a leaf. 0 leaves = run over.
- **Dream:** every N drifts, choose 1 of 3 random upgrades.

Prototype targets (all data, easy to tune): 10 drifts per run, a Dream every 2 drifts.

## Run resources

| Resource | Source | Spent on |
|---|---|---|
| Dew | cleansed creatures, drift-clear bonus | placing Wardens |
| Leaves | starting value (perks can raise it) | lost when a creature reaches the Heartwood |
| Seeds | end of run (see Meta) | Memory Grove unlocks |

Per-run state lives in a `RunState` node in the main scene (Dew, leaves, current drift, chosen
dreams) and emits signals (`dew_changed`, `leaves_changed`, …). Restarting a run reloads the
scene. Starting values are read from one place so meta perks can modify them.

## Dreams (in-run upgrades)

Kinds:
- **New Warden:** adds a tower type to the build menu.
- **Stat growth:** Quickened Sap (attack speed), Deeper Calm (damage), Longer Roots (range).
  Global or per-Warden-type.
- **Growth path:** a Warden's branch upgrade (e.g. Sporeling → Bloom or Drift).
- **Rarity tiers:** common / rare / (later) legendary.

Data: `UpgradeData` resources. The Dream pool only draws from **unlocked** upgrades (see Meta).

## Wardens (towers)

| Warden | Role | Growths |
|---|---|---|
| Sporeling | basic spore puff | Bloom (slow clouds) / Drift (stacking soothe over time) |
| Mossback | short range, strong single target | — |
| Lanternmoth Roost | long range, reveals fog-hidden creatures | — |
| Rootcurl | pulls creatures back a tile | — |
| Elder Stump (rare) | aura buffs neighbours | — |

Data: `TowerData` resources (cost, range, damage, attack speed, texture).

## Blighted creatures (enemies)

| Creature | Trait |
|---|---|
| Leaf Bug | common, quick |
| Bark Beetle | slow, sturdy |
| Dusk Moth | fast, hidden in fog |
| Puffcap | splits when cleansed |
| Old Stag | boss drift |

Data: `EnemyData` resources. Blighted look = desaturated `modulate`; cleansed = full colour.

## Drifts (waves)

`DriftData` resource: list of groups (creature, count, spacing, delay). A run is an ordered list
of drifts. Clearing a drift grants bonus Dew.

## Meta-progression

**Seeds** are earned every run, win or lose: per drift survived + creatures cleansed + win bonus.

Spent in the **Memory Grove** (between-runs screen; each unlock grows as a plant):

| Kind | Examples |
|---|---|
| New Wardens | unlock Mossback, Lanternmoth… into the Dream pool |
| Better Dreams | rare-tier dreams, Growth paths, stronger versions |
| Perks | +starting Dew, +1 leaf, one Dream reroll per run, 4 Dream choices instead of 3 |
| New forests | new biomes / map types |

**Milestones:** some unlocks come from achievements instead (e.g. cleanse 500 Leaf Bugs →
Rootcurl). These map to Steam achievements later.

**Blight Levels:** after the first win, stackable difficulty modifiers for more Seeds (like
Ascension). The long-term replayability hook.

**Design rule:** unlocks mostly **widen options**; raw-power perks stay small and capped so
early drifts are never trivial.

Tech: `HeartwoodMemory` autoload, save file in `user://` (works with Steam Auto-Cloud),
`UnlockData` resources (id, cost, kind, prerequisites, effect). Save format is versioned.

## Build order

1. Combat & cleanse: tower range, targeting, projectile/puff; enemy health; cleanse on 0.
2. Stakes & economy: leaves, Dew, tower cost, lose condition, HUD.
3. Drifts: `DriftData`, build phase, Start Drift button (replaces the temp spawner).
4. Dreams: pause every N drifts, pick 1 of 3 from `UpgradeData`.
5. Run end: win/lose, results screen with Seeds earned.
6. Title screen & scene flow.
7. Meta: `HeartwoodMemory`, save/load, `UnlockData`, Memory Grove screen.
8. Milestones, Blight Levels, more content.

Release prep (parallel, later): Steam page early for wishlists, settings menu, controller/Steam
Deck support, localization-ready text, credits (Godot MIT notice), Next Fest demo.
