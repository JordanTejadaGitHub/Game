# Game Design — *The Heartwood Remembers*

The overview. Each section summarises a detailed doc; **the detailed doc wins** if they disagree.
Goal: commercial release on Steam, all art original (the Foozle packs in `assets/` are
placeholders).

| Doc | Covers |
|---|---|
| `pitch.md` | hook, tagline, store page, capsule and trailer concepts |
| `story.md` | tone, premise, the Hollow, naming (Wardens, Dew, leaves, drifts) |
| `run_design.md` | run structure, drifts, rests, rules, economy, scaling |
| `tower_design.md` | Warden families, evolutions, status effects, synergies, build archetypes |
| `warden_stats.md` | numbers for every Warden, new mechanics the unbuilt ones need |
| `enemy_design.md` | nightmares: roster, traits, resistances, stats, bosses |
| `acts_3_4.md` | drifts 51–100, the Moth Queen and the Hollow Oak, act 3–4 nightmare intros |
| `acts_1_2.md` | creature and boss stats, special drifts, the drift-by-drift plan for drifts 1–50 |
| `dream_design.md` | in-run upgrade pool, offer rules, status numbers |
| `meta_design.md` | Seeds, Memory Grove, milestones, Blight Levels, Memories, true ending |
| `art_direction.md` | warm vs cold, environment, Warden and nightmare look (audio to do) |
| `audio_direction.md` | music (adaptive layers), nightmare signature sounds, dispel, mix, demo list |
| `platforms.md` | PC first, mobile port later: touch-friendly rules and the touch control map |
| `art_style_options.md` | six candidate rendering styles compared; leaning Waystone pixel |
| `meta_assets.md` | Memory Grove art: tree segments, node states, dream-fruit, loadout, icons, Memories |
| `environment_assets.md` | environment sprite-sheet layouts per act |
| `onboarding.md` | teaching across the first runs |
| `screens_ui.md` | screen flow, HUD layout, panels, choice screens, settings, controls |
| `demo_scope.md` | what's in the demo, timeline, success measures |
| `design_plan.md` | what's designed and what still needs fleshing out |

## Hook

**Your towers are the maze, and nightmares are hunting the dream.** A dark fairytale: charming
Warden spirits hold a dreaming forest against cold, hungry nightmares. Proposed tagline: *Grow a
living maze. Hold back the nightmares.* (`pitch.md`, `story.md`)

## Core loop

**A run** (1–2 hours, 100 drifts, saved at every rest):

```
New run (new random forest) → only Sprout + Thornwall
  → drift 1 → pick your first Warden family (1 of 3), +1 Dreamlight
  → drifts flow in blocks of 5 → rest: Dream (pick 1 of 3), Omen, rebuild at a 75% refund
  → … every 25th drift is a boss → dispel it → new Warden family, +3 Dreamlight, a Rare-or-better Dream
  → drift 100: The Hollow Oak → win   (or all leaves fall → the Heartwood goes dormant)
  → Results (Seeds earned) → Memory Grove (spend Seeds, unlock Memories) → next run
```

- **Drifts** (waves): nightmares hunt their way from the forest edge to the Heartwood. Within a
  block of 5 they flow into each other (Auto-drift can be turned off).
- **Dispel**: at 0 health a nightmare shrieks, cracks with light and bursts into motes that become
  **Dew**.
- **Leaves**: each nightmare reaching the Heartwood feeds on the dream: a leaf blackens and falls
  (bosses: 5). 0 leaves = the Heartwood sinks into dreamless sleep, run over.
- **Rests** after every 5th drift: time pauses, a Dream (and an Omen from drift 10), rearranging at a
  75% refund, spending Dreamlight on the Remember screen, autosave.

## Run structure (`run_design.md`)

| Act | Drifts | Boss |
|---|---|---|
| 1. Forest's Edge | 1–25 | The Hollow Stag |
| 2. Deep Wood | 26–50 | The Mire Hag or The Moth Queen |
| 3. Misty Hollow | 51–75 | the other one |
| 4. Heartwood Glade | 76–100 | The Hollow Oak (always) |

One map per run. Act breaks: the season changes, 1 leaf regrows. Nightmare health grows ×1.045 per
drift (×1.055 in act 2; ≈ ×11 by drift 50, ×100 by drift 100), plus more nightmares, elites in every
drift from 26 (two from 76) and tougher kinds.

## Rules

| Rule | Decision |
|---|---|
| Building | any time, during drifts and rests; the path must always stay open |
| Selling | 75% refund during a rest, half while nightmares are walking |
| Speed | pause, 1×, 2×, 3×; building works while paused |
| Call early | start the next drift sooner for a small Dew bonus |
| Saving | autosave at every rest; Save & Quit any time (resumes from the last rest) |

## Resources

| Resource | Source | Spent on |
|---|---|---|
| **Dew** (in-run) | dispelled nightmares, rest bonus, perfect blocks, bosses; start with 60 | Wardens, evolutions, Nurture ranks, tending obstacles |
| **Dreamlight** (in-run) | 1 with the first family pick, 3 from each boss (25, 50, 75) | unlocking branches (1) and final forms (2) |
| **Leaves** (in-run) | start with 15, +1 per act break | lost when nightmares reach the Heartwood |
| **Seeds** (meta) | end of every run, win or lose | Memory Grove unlocks |

Per-run state lives in `RunState` (`%RunState`); starting values are read from one place so meta
perks can modify them.

## The forest (map)

- **A new random forest every run**: wobbly **ridges** of rocks and trees from alternating walls
  make the starting route zig-zag; tree groves and rock clusters vary per map.
- **Obstacles**: **Withered Trees** ("Tend", 5 Dew) and **Mossy Boulders** ("Move", 8 Dew) block
  nightmares and building. **Clearing is locked until you take a clearing Dream card**; after that,
  tending one opens space (and often a shortcut) and adds **+1 Seed** at
  run end: in-run power vs long-term progress.
- Routes are always the shortest path, and re-routes stay local when there's a tie (routes are
  "sticky"), so small changes don't send creatures across the map.
- Later: more biomes ("New forests" in the Grove), special tiles (`design_plan.md` topic 9).

## Wardens (towers) — `tower_design.md`

**Towers are walls, so builds should care about the maze.** Every run starts with the **Sprout**
and **Thornwall** (a cheap plain wall). **Warden families** come from the pick after drift 1 and
from the bosses at 25, 50 and 75: **4 families per run** out of Sporeling, Dewdrop, Firefly Jar,
Pebbling, Rootling, **Bellflower** (song and sleep) and Acorn; the full game adds Nestling and
Whirligig. Each family has one clear role, 2 branches and a final form per branch, plus a
**hidden 3rd branch** unlocked late in the Memory Grove (e.g. the Cairn mortar, the Samara
boomerang, the multi-hit Hummingbird).

- **Crits**: every attacking Warden has a crit chance (default 5%, ×2); snipers and heavy hitters
  more. Crit cards in the Dream pool support crit builds.
- **Memory Wardens**: after a boss, the reward can be that boss's unique Memory Warden instead of a
  family (the White Stag, the Pond Keeper, the Moon Moth).

- **Dreamlight unlocks, Dew pays**: spending Dreamlight (from bosses) makes a branch or final form
  available; evolving a specific Warden costs Dew. Evolving happens in place, so the path never
  changes. Wardens also grow through **Nurture ranks** (Dew, rank I–V, a Focus at III).
- Wardens combo **through status effects** on creatures (Damp, Drowsy, Spored, Marked, Static,
  Held) and **through placement** (path length, clusters, chokepoints, wall count).
- When fewer than 3 new families are available (early in the meta), empty pick slots become
  **Family Blessings** for a family you own.

## Dreams (in-run upgrades) — `dream_design.md`

**A Dream after every 5th drift (19 per run)**: pick 1 of 3, or *Let it pass* for +15 Dew.

| Rarity | Feel | Examples |
|---|---|---|
| Common | stat growth, stacks without limit | Quickened Sap +10% attack speed |
| Uncommon | branches, small rules | Stormcap; *Cozy Corners*: Wardens beside a bend +15% soothe |
| Rare | final forms, combo enablers | Thunderhead; *Conductive Soil* |
| Legendary (act 2+) | changes how you play | *The Long Walk*: +1% soothe per 4 path tiles |

Rarity shifts toward Rare/Legendary each act; boss Dreams guarantee a Rare; pity after 3 Dreams
without one; cards for families you own are 2× as likely. Target: a deliberate dream build is
complete by drift 50 in about 1 run in 3. The full game's pool should grow to ~70 cards.

## Nightmares (enemies) — `enemy_design.md`

**Nightmares** (evil spirits, ghosts and shadow things) should **test the maze, not just the
damage**: basics (Shade, Husk, Lurker), maze testers (Phantom through walls, Gravecrawler, Night
Hound, Procession, Sleepwalker), status testers (Barrow Wight, Drowned One, Watcher, Ash Crawler,
Will-o'-Wisp), support/swarm (Mourner, Widow, Shellbound, Whisper Swarm, Dream Thief, Weeper) and
bosses (The Hollow Stag, The Mire Hag, The Moth Queen, The Hollow Oak). Resistances by Warden
family give each run's picks weight. Dark, cold and unsettling, never gory. Over 100
drifts, every block should feel different (a new creature, a special drift, a mini-boss).

## Drifts (data)

`DriftData` resources: groups of creatures (type, count, spacing, delay). A run is an ordered list
of 100 drifts in blocks of 5; hand-written for act 1 (`run_design.md`), then composed from rules
and the health scaling for later acts.

## Meta-progression — `meta_design.md`

- **Seeds** every run (drifts survived, nightmares dispelled, bosses, obstacles tended, win bonus;
  more at higher Blight Levels). The full Grove takes ~15–20 hours.
- **Memory Grove**: 4 roots: **Wardens** (Pebbling, Rootling, Acorn families; final forms),
  **Dreams** (locked cards incl. Legendaries), **Perks** (capped power: starting Dew, leaves,
  rerolls, banish, 4-card Dreams), **Forests** (new biomes).
- **Milestones** (free unlocks, also Steam achievements) and **Blight Levels 1–10** (Slay the
  Spire style, unlocked by the first win, +10% Seeds each).
- **The Hollow's story in 10 Memories**, one every 3 Grove unlocks plus milestones, leading to the
  true ending run, **The Long Walk Out**.
- **Design rule:** unlocks mostly widen options; power perks stay small and capped.

Tech: `HeartwoodMemory` autoload, save file in `user://` (Steam Auto-Cloud), versioned;
`UnlockData`, `MemoryData` resources.

## Onboarding and demo

- **Onboarding** (`onboarding.md`): no tutorial mode; one-line "Heartwood whispers" teach each
  thing the first time it matters, mostly in act 1 of the first run.
- **Demo** (`demo_scope.md`): drifts 1–50 (the Hollow Stag and the Mire Hag), 2 family picks, 9 Dreams,
  **no meta progression**, replay freely; Seeds are saved and carry into the full game; a Grove
  teaser and a Wishlist button at the end.

## Build order

1. ~~Combat & dispel~~ (done; restyle the cleanse effect as a dispel for the nightmare theme).
2. Stakes & economy: ~~Dew, tower cost~~ (done); leaves, lose condition.
3. Drifts: `DriftData`, blocks of 5, rests, Auto-drift, call early, family picks, mid-run save
   (replaces the temporary spawner).
4. Dreams: `UpgradeData`, the offer rules, the Dream screen.
5. Run end: win/lose, results screen with Seeds earned.
6. Title screen & scene flow (Continue for saved runs).
7. Meta: `HeartwoodMemory`, save/load, `UnlockData`, Memory Grove screen, Memories.
8. Content: act 1–2 creatures and bosses (demo), then acts 3–4, milestones, Blight Levels.

Current code status lives in `CLAUDE.md`.

**Release prep** (parallel): Steam page early for wishlists (`pitch.md`), original art replacing
the Foozle placeholders, settings menu, controller/Steam Deck support, localization-ready text,
credits (Godot MIT notice), then the demo plan in `demo_scope.md`.
