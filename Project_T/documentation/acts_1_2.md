# Acts 1–2: nightmares, bosses and drifts 1–50

The content for the first half of a run, which is also the whole demo (`demo_scope.md`). Revised
2026-09-27 for the **nightmare** theme (`story.md`). Roster, resistances and **stats** live in
`enemy_design.md` (in sync with the game); this doc is about **which nightmares appear when**, how
the two bosses fight, and the drift plan. Numbers are starting points for playtesting.

## Nightmares in acts 1–2

| Nightmare | Trait (short) | First seen |
|---|---|---|
| **Shade** | common, quick | drift 1 |
| **Husk** | slow, tough (costs 2 leaves) | drift 6 |
| **Mourner** → 3 **Sobs** | breaks apart when dispelled | drift 16 |
| **Phantom** | glides **through walls** straight to the Heartwood | drift 27 |
| **Night Hound** | **sprints** after 3 straight tiles | drift 31 |
| **Procession**: Lantern Bearer + 4 Wraiths | Wraiths lose the way (slow down) if the Lantern Bearer is dispelled first | drift 36 |

**Trait notes:**
- **Phantoms** are the maze-breaker, so they're fragile and come in small, telegraphed groups with
  a signature sound. Every Warden can hit them. They teach "defend near the Heartwood too".
- **Night Hounds** punish long straight corridors and reward twisty mazes. The sprint is obvious (the
  Hound drops low and stretches out, a shadow trail behind it) so the player sees why it's fast.
- **Processions** make a target-priority choice: put out the Lantern Bearer first (the Wraiths slow
  down) or catch the whole line with splash and chains at a chokepoint. **Every Wraith costs a
  leaf**, so a whole Procession reaching the Heartwood costs 5: a real threat.

**Full game only** (act 2 extras, after the demo): **Gravecrawler** (burrows under one wall per
trip) and **Sleepwalker** (wanders into dead ends) join act 2 and replace some mixed drifts.

### Deeply Blighted (elites)

Any nightmare can appear **Deeply Blighted**: **×3 health, ×3 Dew, costs 2 leaves** (more if it
already costs more), 20% larger, darker, with a slow black haze and a small swirl icon. They're the
"mini-bosses" that give blocks a finale. First seen at drift 23. (Blight Level 5 uses the same rule:
one Deeply Blighted nightmare per drift.)

## Bosses

Base stats in `enemy_design.md`.

### The Hollow Stag (drift 25)

A gaunt stag of bark and bone, ghost-fire burning in its antlers.

- **Trampling:** every 10 seconds, if a **Thornwall** is next to it, it tramples one (up to 3 per
  trip). **The wall is gone for good** (no refund); nightmares, including the Stag, can use the
  opened cell right away. Trampling can open shortcuts, but the path rule still holds. Tests maze
  redundancy: don't rely on one wall.
- **Enraged:** at half health its antlers flare and it **charges**: +50% speed for 4 seconds, still
  trampling. Burst it down before it charges, or spread damage along the route.
- **Escort:** 12 Shades ahead, then the Stag, then 6 Husks.
- **Dispelled:** its ghost-fire gutters out, the bone cracks with light and it bursts apart. *"The
  Hollow Stag is gone. Something the Heartwood had forgotten comes back to it."* (the new family
  pick follows)

### The Mire Hag (drift 50; the demo's finale)

A bent bog witch wrapped in reeds and black water.

- **Sinking:** every 6 seconds she **sinks into the mire and rises 3 tiles ahead** along her path,
  skipping whatever those tiles would have cost her. Tests damage spread along the whole maze, not
  one kill zone.
- **Bog water:** each time she rises, nightmares within 1 tile become **Damp** (a gift for Storm Grid
  builds).
- **Desperate:** below half health, she sinks every 4 seconds.
- **Escort:** 10 Night Hounds, then the Hag, then 2 Processions.
- **Dispelled:** she shrieks, the mire boils away into light. *"The Mire Hag is gone. The Deep Wood
  is quiet, for now."*

## Drift composition rules

- **Arrival window:** a mixed drift's nightmares arrive spread over ~25 seconds in act 1 and ~30
  seconds in act 2 (spacing = window ÷ count), shuffled so types mix. Intro drifts use their own
  spacing.
- **Introduce, then mix:** each new nightmare appears **alone** first, in a small group, so its trait
  reads; afterwards it's mixed in.
- **Every block has a shape:** four mixed drifts and a **special drift** or finale on its 5th, just
  before the rest.

### Special drifts

| Name | Contents | Tests |
|---|---|---|
| **Swarm** | lots of Shades, very close together | area damage |
| **Deadwood** | mostly Husks | sustained damage |
| **Wake** | Mourners in quick succession | splits: area damage late in the maze |
| **Haunting** | only Phantoms | defence near the Heartwood |
| **The Hunt** | mostly Night Hounds | twisty mazes |
| **Funeral** | Processions back to back | chokepoints and chains |
| **Deeply Blighted** | a few elites + an escort | burst on tough targets |

## Act 1: Forest's Edge (drifts 1–25)

SH = Shade, HU = Husk, MO = Mourner. ★ = elite (Deeply Blighted). **Rest** after every 5th.

| Drift | Contents | Notes |
|---|---|---|
| 1 | 8 SH (1.5 s apart) | then the first family pick |
| 2 | 10 SH | |
| 3 | 12 SH | |
| 4 | 14 SH | |
| 5 | 16 SH | **rest: first Dream** |
| 6 | 3 HU (2.5 s apart) | Husk intro |
| 7 | 12 SH, 2 HU | |
| 8 | 14 SH, 3 HU | |
| 9 | 16 SH, 3 HU | |
| 10 | **Deadwood:** 10 SH, 6 HU | rest |
| 11 | 18 SH, 4 HU | |
| 12 | 20 SH, 4 HU | |
| 13 | 16 SH, 6 HU | |
| 14 | 22 SH, 5 HU | |
| 15 | **Swarm:** 35 SH (0.3 s apart) | rest |
| 16 | 4 MO (2.5 s apart) | Mourner intro |
| 17 | 16 SH, 3 HU, 3 MO | |
| 18 | 18 SH, 4 HU, 4 MO | |
| 19 | 20 SH, 5 HU, 4 MO | |
| 20 | **Wake:** 10 MO (1 s apart) | rest |
| 21 | 22 SH, 5 HU, 5 MO | |
| 22 | 24 SH, 6 HU, 5 MO | |
| 23 | 20 SH, 2 HU★ | first elites |
| 24 | 26 SH, 7 HU, 6 MO | |
| 25 | **The Hollow Stag:** 12 SH, the Stag, 6 HU | **rest: family pick + Rare Dream** |

## Act 2: Deep Wood (drifts 26–50)

PH = Phantom, NH = Night Hound, PR = Procession (Lantern Bearer + 4 Wraiths).

| Drift | Contents | Notes |
|---|---|---|
| 26 | 20 SH, 6 HU, 6 MO | warm-up after the boss |
| 27 | **Haunting:** 6 PH (2 s apart) | Phantom intro |
| 28 | 22 SH, 6 HU, 4 PH | |
| 29 | 24 SH, 7 HU, 6 MO | |
| 30 | 20 SH, 8 HU, 6 PH | rest |
| 31 | 4 NH (3 s apart) | Night Hound intro |
| 32 | 20 SH, 6 HU, 5 NH | |
| 33 | 22 SH, 5 MO, 6 NH | |
| 34 | 24 SH, 8 HU, 4 PH, 4 NH | |
| 35 | **The Hunt:** 12 NH, 3 HU★ | rest |
| 36 | 1 PR | Procession intro |
| 37 | 20 SH, 2 PR | |
| 38 | 24 SH, 8 HU, 6 NH | |
| 39 | 20 SH, 6 MO, 8 PH | |
| 40 | **Funeral:** 4 PR back to back, 10 SH | rest |
| 41 | 28 SH, 8 HU, 6 NH, 1 PR | |
| 42 | 26 SH, 8 MO, 6 PH | |
| 43 | **Haunting:** 20 PH | |
| 44 | 30 SH, 10 HU, 6 NH, 2 PR | |
| 45 | **Deeply Blighted:** 20 SH, 2 NH★, 2 Lantern Bearers★ (with their Wraiths) | rest |
| 46 | 30 SH, 10 HU, 8 MO | |
| 47 | 28 SH, 8 NH, 8 PH, 2 PR | |
| 48 | **Swarm:** 50 SH (0.25 s apart) | |
| 49 | 32 SH, 12 HU, 8 NH, 3 PR, 6 PH | |
| 50 | **The Mire Hag:** 10 NH, the Hag, 2 PR | **demo ends** / full game: family pick + Rare Dream |

## To check in playtests

- Does each intro drift make the nightmare's trait obvious (look, movement, sound)?
- Are Phantoms fair (the player sees and hears them coming and has something near the Heartwood)?
- Do Night Hounds make players build twistier mazes?
- Do the special drifts feel like events, not just "more"?
- Dew totals at drifts 25 and 50 vs the target curve in `run_design.md`.
