# Acts 1–2: creatures, bosses and drifts 1–50

The content for the first half of a run, which is also the whole demo (`demo_scope.md`). Builds on
the roster in `enemy_design.md` and the structure in `run_design.md`. All numbers are starting
points for playtesting and live in data (`EnemyData`, `DriftData`).

## Units

- **Speed in cells per second** (1 cell = 64 px). Leaf Bug 1.6 cells/s ≈ the current 100 px/s.
- **Health is the drift-1 value**; every creature's health is × **1.035 per drift** (×2.3 at drift
  25, ×5.4 at drift 50). Bosses have fixed health.
- **Dew** ≈ 3 per 100 base health, adjusted for traits. Dew does **not** scale with drift.

## Creatures

| Creature | Health | Speed | Dew | Leaves | Trait | First seen |
|---|---|---|---|---|---|---|
| **Leaf Bug** | 100 | 1.6 | 3 | 1 | — | drift 1 |
| **Bark Beetle** | 300 | 0.9 | 8 | 1 | thick shell (just sturdy) | drift 6 |
| **Puffcap** | 150 | 1.2 | 4 | 1 | when cleansed, splits into 3 Puffcaplets | drift 16 |
| ↳ Puffcaplet | 30 | 2.0 | 1 | 1 | small and quick | — |
| **Dandelion Seed** | 60 | 1.0 | 3 | 1 | **floats** in a straight line to the Heartwood, over walls | drift 27 |
| **Hedgehog** | 200 | 1.2 | 6 | 1 | after 3 straight tiles, **curls up and rolls** at 3.0 until the next turn | drift 31 |
| **Mother Duck** | 250 | 1.1 | 6 | 1 | leads a line of 4 Ducklings | drift 36 |
| ↳ Duckling | 50 | 1.1 | 1 | 1 | follows in tight single file; if Mother is cleansed first, the Ducklings get lost and slow to 0.7 | — |

**Trait notes:**
- **Dandelion Seeds** are the maze-breaker, so they're weak and come in small, telegraphed groups.
  Every Warden can reach them (they float low). They teach "defend near the Heartwood too".
- **Hedgehogs** punish long straight corridors and reward twisty mazes. Rolling is visible (a
  curled-up sprite, a little dust trail) so the player can see why they're fast.
- **Ducklings** make a target-priority choice: cleanse Mother first (the line slows down) or catch
  the whole line with splash and chains at a chokepoint. **Every Duckling costs a leaf**, so a
  whole line reaching the Heartwood costs 5: a real threat, not a parade to watch.

**Full game only** (act 2 extras, after the demo): **Mole** (burrows under one wall per trip) and
**Wandering Hare** (takes wrong turns into dead ends) join act 2 and replace some mixed drifts.

### Deeply Blighted (elites)

Any creature can appear **Deeply Blighted**: **×3 health, ×3 Dew, costs 2 leaves**, drawn 20%
larger and darker with a slow grey haze. They're the "mini-bosses" that give blocks a finale. First
seen at drift 23. (Blight Level 5 uses the same rule: one Deeply Blighted creature per drift.)

## Bosses

### Old Stag (drift 25)

| Health | Speed | Dew | Leaves |
|---|---|---|---|
| 3,000 | 0.7 | 40 | 5 |

- **Trampling:** every 10 seconds, if a **Thornwall** is next to it, it knocks one down (up to 3
  per trip). **The wall is gone for good** (no refund); creatures, including the Stag, can use the
  opened cell right away. Knocking down walls can open shortcuts, but the path rule still holds.
  Tests maze redundancy: don't rely on one wall.
- **Startled:** at half health it charges: +50% speed for 4 seconds, and it can trample during the
  charge. Burst it down before it panics, or have soothe spread along the route.
- **Escort:** 12 Leaf Bugs ahead, then the Stag, then 6 Bark Beetles.
- **Cleansed:** a long colour return; it lifts its head and walks off into the trees. *"The Old
  Stag remembers the way home."*

### Great Toad (drift 50; the demo's finale)

| Health | Speed | Dew | Leaves |
|---|---|---|---|
| 8,000 | 0.6 | 60 | 5 |

- **Leaping:** every 6 seconds it leaps **3 tiles ahead** along its path, skipping whatever those
  tiles would have cost it. Tests soothe spread along the whole maze, not one kill zone.
- **Splash:** each landing makes creatures within 1 tile **Damp** (a gift for Storm Grid builds).
- **Hurry:** below half health, it leaps every 4 seconds.
- **Escort:** 10 Hedgehogs, then the Toad, then 2 Duckling lines.
- **Cleansed:** it settles into a puddle of dew and sings a low, happy croak. *"The Great Toad
  sings, and the Deep Wood listens."*

## Drift composition rules

- **Arrival window:** a mixed drift's creatures arrive spread over ~25 seconds in act 1 and ~30
  seconds in act 2 (spacing = window ÷ count), shuffled so types mix. Intro drifts use their own
  spacing.
- **Introduce, then mix:** each new creature appears **alone** first, in a small group, so its
  trait reads; afterwards it's mixed in.
- **Every block has a shape:** four mixed drifts and a **special drift** or finale on its 5th, just
  before the rest.

### Special drifts

| Name | Contents | Tests |
|---|---|---|
| **Swarm** | lots of Leaf Bugs, very close together | area soothe |
| **Heavy Bark** | mostly Bark Beetles | sustained soothe |
| **Mushroom Ring** | Puffcaps in quick succession | splits: area soothe late in the maze |
| **Thistledown** | only Dandelion Seeds | defence near the Heartwood |
| **Rolling Hills** | mostly Hedgehogs | twisty mazes |
| **Parade** | Duckling lines back to back | chokepoints and chains |
| **Deeply Blighted** | a few elites + an escort | burst on tough targets |

## Act 1: Forest's Edge (drifts 1–25)

LB = Leaf Bug, BB = Bark Beetle, PC = Puffcap. ★ = elite (Deeply Blighted). **Rest** after every 5th.

| Drift | Contents | Notes |
|---|---|---|
| 1 | 8 LB (1.5 s apart) | then the first family pick |
| 2 | 10 LB | |
| 3 | 12 LB | |
| 4 | 14 LB | |
| 5 | 16 LB | **rest: first Dream** |
| 6 | 3 BB (2.5 s apart) | Bark Beetle intro |
| 7 | 12 LB, 2 BB | |
| 8 | 14 LB, 3 BB | |
| 9 | 16 LB, 3 BB | |
| 10 | **Heavy Bark:** 10 LB, 6 BB | rest |
| 11 | 18 LB, 4 BB | |
| 12 | 20 LB, 4 BB | |
| 13 | 16 LB, 6 BB | |
| 14 | 22 LB, 5 BB | |
| 15 | **Swarm:** 35 LB (0.3 s apart) | rest |
| 16 | 4 PC (2.5 s apart) | Puffcap intro |
| 17 | 16 LB, 3 BB, 3 PC | |
| 18 | 18 LB, 4 BB, 4 PC | |
| 19 | 20 LB, 5 BB, 4 PC | |
| 20 | **Mushroom Ring:** 10 PC (1 s apart) | rest |
| 21 | 22 LB, 5 BB, 5 PC | |
| 22 | 24 LB, 6 BB, 5 PC | |
| 23 | 20 LB, 2 BB★ | first elites |
| 24 | 26 LB, 7 BB, 6 PC | |
| 25 | **Old Stag:** 12 LB, Old Stag, 6 BB | **rest: family pick + Rare Dream** |

## Act 2: Deep Wood (drifts 26–50)

DS = Dandelion Seed, HH = Hedgehog, DL = Duckling line (Mother Duck + 4 Ducklings).

| Drift | Contents | Notes |
|---|---|---|
| 26 | 20 LB, 6 BB, 6 PC | warm-up after the boss |
| 27 | **Thistledown:** 6 DS (2 s apart) | Dandelion Seed intro |
| 28 | 22 LB, 6 BB, 4 DS | |
| 29 | 24 LB, 7 BB, 6 PC | |
| 30 | 20 LB, 8 BB, 6 DS | rest |
| 31 | 4 HH (3 s apart) | Hedgehog intro |
| 32 | 20 LB, 6 BB, 5 HH | |
| 33 | 22 LB, 5 PC, 6 HH | |
| 34 | 24 LB, 8 BB, 4 DS, 4 HH | |
| 35 | **Rolling Hills:** 12 HH, 3 BB★ | rest |
| 36 | 1 DL | Duckling intro |
| 37 | 20 LB, 2 DL | |
| 38 | 24 LB, 8 BB, 6 HH | |
| 39 | 20 LB, 6 PC, 8 DS | |
| 40 | **Parade:** 4 DL back to back, 10 LB | rest |
| 41 | 28 LB, 8 BB, 6 HH, 1 DL | |
| 42 | 26 LB, 8 PC, 6 DS | |
| 43 | **Thistledown:** 20 DS | |
| 44 | 30 LB, 10 BB, 6 HH, 2 DL | |
| 45 | **Deeply Blighted:** 20 LB, 2 HH★, 2 Mother Ducks★ (with their lines) | rest |
| 46 | 30 LB, 10 BB, 8 PC | |
| 47 | 28 LB, 8 HH, 8 DS, 2 DL | |
| 48 | **Swarm:** 50 LB (0.25 s apart) | |
| 49 | 32 LB, 12 BB, 8 HH, 3 DL, 6 DS | |
| 50 | **Great Toad:** 10 HH, Great Toad, 2 DL | **demo ends** / full game: family pick + Rare Dream |

## To check in playtests

- Does each intro drift make the creature's trait obvious?
- Are Dandelion Seeds fair (the player sees them coming and has something near the Heartwood)?
- Do Hedgehogs make players build twistier mazes?
- Do the special drifts feel like events, not just "more"?
- Dew totals at drifts 25 and 50 vs the target curve in `run_design.md`.
