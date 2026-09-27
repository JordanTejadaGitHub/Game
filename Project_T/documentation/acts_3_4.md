# Acts 3–4: nightmares, bosses and drifts 51–100

The second half of a run (2026-09-27: runs open to all 100 drifts, in the demo too). Follows
`acts_1_2.md` (same rules and abbreviations); roster, resistances and stats in `enemy_design.md`.
Numbers are starting points for playtesting.

## Scaling (continues from act 2)

- **Health growth:** ×1.055 per drift for drifts 26–50 (`run_design.md`), then **×1.045 per drift
  from drift 51**, so the late game doesn't run away: ≈ ×11 at drift 50, ×33 at drift 75, ×100 at
  drift 100 (bosses have their own fixed health).
- **+25% count** on kinds with 3+ in a drift, as before.
- **Elites:** one Deeply Blighted per drift from drift 26; **two per drift from drift 76**.
- **Leaves:** +1 at each act break (so +1 after drift 50 and after drift 75).

## Nightmares introduced

| Drift | Nightmare | Trait (short) | Answer |
|---|---|---|---|
| 52 | **Lurker** | unseen until revealed or close | Lanternmoth, Moon Moth, short range near the path |
| 54 | **Will-o'-Wisp** | a treacherous light that reveals Lurkers near it | dispel it last |
| 56 | **Gravecrawler** | burrows under one Warden or wall per trip | layered walls, Rootcurl |
| 58 | **Sleepwalker** | wanders into dead ends, then back | Wardens covering side pockets |
| 61 | **Drowned One** | always Damp, ignores slows | lightning (a gift for Storm Grid) |
| 63 | **Barrow Wight** | ancient, slow, can't be Held | raw damage, Spored, Marked |
| 66 | **Watcher** | never sleeps; wakes Drowsy nightmares nearby | kill it first, Beacon |
| 68 | **Ash Crawler** | burning ash clears Spored behind it | dispel it early |
| 77 | **Widow** → 6 **Creeps** | bursts into fast Creeps | area damage near the Heartwood |
| 79 | **Shellbound** | dread shell soaks chip damage | heavy hits |
| 81 | **Whisper Swarm** | single-target damage halved | splash, pulses, fog |
| 83 | **Dream Thief** | steals Dew if it gets through; double Dew if dispelled | fast single-target |
| 86 | **Weeper** | mends nearby nightmares | target priority |

## Bosses

### The Moth Queen (drift 75)

A vast moth with a skull-like face on its wings. Health 16,000 × 1.5 = **24,000**; 5 leaves; 80 Dew.

- **Flies** over the maze in a slow, weaving line toward the Heartwood (like a Phantom, ignoring
  walls), so every Warden near her line gets a chance, not just the maze.
- **Brood:** drops a Lurker every 4 seconds; they land on the path and walk the maze.
- **Eclipse** (at half health): her wings close over the dream for 5 seconds: every nightmare on
  the map is hidden (like Lurkers) unless something reveals it (Lanternmoth, Moon Moth,
  Will-o'-Wisp). Detection Wardens pay off here.
- **Escort:** 12 Lurkers ahead, then the Queen, then 6 Night Hounds.
- **Dispelled:** her wings burn white, then scatter into a cloud of moths that fade. *"The Moth
  Queen is gone, and the light comes back."* Memory Warden: **the Moon Moth**.

### The Hollow Oak (drift 100: the run's end)

The Hollow's corrupted heart, walking on its roots. Health 30,000 × 1.5 = **45,000**; 5 leaves; 100
Dew.

- **Walks very slowly** along the maze.
- **Thorn-saplings:** every 8 seconds it plants a sapling on an empty cell beside the path. Saplings
  are obstacles that **re-route** nightmares (never placed where they'd close the path, and never
  on a Warden). They can be cleared like obstacles (if clearing is unlocked) and wither when the Oak
  is dispelled.
- **Grief** (at two-thirds and one-third health): it stops and wails, and a ring of 6 Mourners rises
  around it.
- **Blight Level 10 ("The Hollow Oak remembers"):** after it's dispelled, it rises once more at half
  health with double sapling speed.
- **Escort:** 3 Processions, 8 Mourners and 4 Weepers.
- **Dispelled:** it falls silent; the thorn-saplings crumble; far away, something stirs. *"The
  Hollow Oak is still. Somewhere beyond the dream, the Hollow remembers."* **The run is won.**

## Special drifts (new)

| Name | Contents | Tests |
|---|---|---|
| **Eclipse** | mostly Lurkers | detection |
| **Burial** | mostly Gravecrawlers | layered walls |
| **Drowning** | Drowned Ones + Night Hounds | slows don't work; lightning does |
| **Vigil** | Watchers among many others | kill order with sleep builds |
| **Ashfall** | Ash Crawlers + Shades | spore builds |
| **Brood** | Widows | area damage late in the maze |
| **Thieves' Night** | Dream Thieves + fast escorts | leaks cost Dew |
| **Lament** | Weepers + Mourners + Husks | target priority |
| **Shell Wall** | Shellbound + support | heavy hits |
| **The Long Night** | everything at once | the whole build |

## Act 3: Misty Hollow (drifts 51–75)

SH Shade, HU Husk, MO Mourner, PH Phantom, NH Night Hound, PR Procession, LU Lurker, WW
Will-o'-Wisp, GC Gravecrawler, SW Sleepwalker, DO Drowned One, BW Barrow Wight, WA Watcher, AC Ash
Crawler. One elite per drift is added automatically.

| Drift | Contents | Notes |
|---|---|---|
| 51 | 30 SH, 10 HU, 6 NH, 2 PR | warm-up after the boss |
| 52 | 6 LU (2 s apart) | Lurker intro |
| 53 | 30 SH, 8 HU, 6 LU | |
| 54 | 3 WW, 8 LU | Will-o'-Wisp intro (they reveal the Lurkers) |
| 55 | **Eclipse:** 20 SH, 14 LU, 2 WW | rest |
| 56 | 4 GC (3 s apart) | Gravecrawler intro |
| 57 | 32 SH, 8 HU, 6 GC | |
| 58 | 5 SW (2 s apart) | Sleepwalker intro |
| 59 | 30 SH, 8 NH, 6 SW, 6 PH | |
| 60 | **Burial:** 12 GC, 10 HU, 10 SH | rest |
| 61 | 4 DO (2.5 s apart) | Drowned One intro |
| 62 | 32 SH, 10 HU, 8 DO | |
| 63 | 2 BW (5 s apart) | Barrow Wight intro |
| 64 | 34 SH, 3 BW, 8 MO, 6 LU | |
| 65 | **Drowning:** 16 DO, 8 NH | rest |
| 66 | 3 WA (3 s apart), 10 SH | Watcher intro |
| 67 | 34 SH, 10 HU, 4 WA, 3 PR | |
| 68 | 3 AC (3 s apart) | Ash Crawler intro |
| 69 | 34 SH, 6 AC, 8 MO, 6 GC | |
| 70 | **Vigil:** 6 WA, 24 SH, 8 MO, 4 BW | rest |
| 71 | 36 SH, 12 HU, 8 NH, 6 DO, 4 WA | |
| 72 | 36 SH, 10 LU, 4 WW, 6 GC, 3 PR | |
| 73 | **Ashfall:** 10 AC, 30 SH | |
| 74 | 40 SH, 12 HU, 10 NH, 8 DO, 4 BW, 6 PH | |
| 75 | **The Moth Queen:** 12 LU, the Queen, 6 NH | **rest: family pick + Rare Dream** |

## Act 4: Heartwood Glade (drifts 76–100)

Adds WI Widow, SB Shellbound, WS Whisper Swarm, DT Dream Thief, WE Weeper. Two elites per drift
are added automatically.

| Drift | Contents | Notes |
|---|---|---|
| 76 | 36 SH, 12 HU, 8 DO, 6 LU, 3 PR | warm-up after the boss |
| 77 | 3 WI (3 s apart) | Widow intro |
| 78 | 38 SH, 12 HU, 4 WI, 6 AC | |
| 79 | 3 SB (4 s apart) | Shellbound intro |
| 80 | **Brood:** 8 WI, 12 SH, 4 SB | rest |
| 81 | 2 WS (5 s apart) | Whisper Swarm intro |
| 82 | 38 SH, 4 WS, 10 NH, 6 GC | |
| 83 | 4 DT (2 s apart) | Dream Thief intro |
| 84 | 40 SH, 6 DT, 10 HU, 6 WA | |
| 85 | **Thieves' Night:** 12 DT, 20 SH, 6 NH | rest |
| 86 | 3 WE (3 s apart), 12 SH | Weeper intro |
| 87 | 40 SH, 4 WE, 12 HU, 6 BW | |
| 88 | 40 SH, 6 WI, 6 SB, 8 LU, 4 WW | |
| 89 | 42 SH, 6 WS, 8 DO, 6 AC, 4 PR | |
| 90 | **Lament:** 6 WE, 12 MO, 10 HU | rest |
| 91 | 44 SH, 14 HU, 10 NH, 6 WI, 6 DT | |
| 92 | 44 SH, 8 SB, 6 WE, 6 WA, 8 PH | |
| 93 | 44 SH, 8 WS, 10 DO, 6 GC, 6 SW | |
| 94 | 46 SH, 14 HU, 8 BW, 10 LU, 4 WW, 4 PR | |
| 95 | **Shell Wall:** 10 SB, 4 WI, 6 WE | rest |
| 96 | **The Long Night:** 30 SH, 6 of every other kind | |
| 97 | 48 SH, 16 HU, 10 NH, 8 DT, 8 WS | |
| 98 | **Swarm:** 80 SH (0.2 s apart) | |
| 99 | 50 SH, 12 of MO, NH, LU, DO; 6 of WI, SB, WE, AC; 4 PR | |
| 100 | **The Hollow Oak:** 3 PR, 8 MO, 4 WE, the Oak | **the run is won** |

## To check in playtests

- Is detection (Lurkers, the Eclipse) fair when the player has no Lanternmoth? (Short-range Wardens
  and the Will-o'-Wisps should be enough to survive, not to thrive.)
- Do Gravecrawlers and Sleepwalkers make the maze layout matter again in act 3?
- Is act 4 hard but winnable with a complete build? Time per drift in act 4 (runs must stay ~1–2 h).
- Do the Hollow Oak's saplings create interesting re-routes rather than frustration?
