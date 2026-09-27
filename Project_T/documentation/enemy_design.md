# Enemy Design — Nightmares

Overview and run loop: see `game_design.md`. Wardens and status effects: see `tower_design.md`.
Story and the full old→new name table: `story.md`.

**Revised 2026-09-27: the enemies are nightmares**, evil spirits, ghosts and shadow things hunting
the Heartwood's dream, no longer lost forest creatures. Every mechanic, resistance and stat below is
unchanged from the cozy version; only names, fiction and art direction changed.

## Design principles

- **Test the maze, not just the damage.** The best nightmares make the player rethink the maze
  (things that pass through walls, burrow, or run down straight corridors). That's what makes this
  game different from other tower defense games.
- **Every nightmare has a counter the player already owns or can Dream into.** One can be hard for
  one build and a gift for another (e.g. the Drowned One vs Storm Grid).
- **Readable at a glance.** One clear trait per nightmare, visible in its silhouette and movement.
- **Menace, not gore.** Traits come from how the nightmare *hunts* (gliding through walls, sniffing
  out the straight path, leading a procession). They should feel cold, hungry and wrong; dispelling
  one should feel like a small victory.
- **Never break the path rule.** Nightmares that change the maze (Hollow Stag, Hollow Oak) must
  never leave the start without a route to the Heartwood.

## Art direction

- **Dark, cold, partly translucent**; glow only in eyes or cores. Warm Warden light vs cold
  nightmare shadow is the game's core contrast.
- **Wrong movement:** gliding, twitching, stop-start, heads turning to watch Wardens.
- **One strong silhouette per nightmare**, tied to its trait.
- **Dispel:** shriek or hiss, cracks of light, burst into motes that drift up as Dew.
- **Sound:** whispers and low hums as they approach; each type has a signature sound so players can
  hear a Night Hound pack or a Procession coming.

## Roster

**Tests** = what the nightmare asks of the player. **Counter** = Wardens or statuses that answer it.

### Basics

| Nightmare | Looks like | Trait | Tests | Counter |
|---|---|---|---|---|
| **Shade** | a small hunched shadow with two pinprick eyes | common, quick | baseline | anything |
| **Husk** | a hollow shell of dead bark, something moving inside the cracks | slow, lots of health | sustained damage | Spored, Marked, heavy hits |
| **Lurker** | a thin shape that's only half there | fast, hidden in fog (can't be targeted until revealed or close) | detection | Lanternmoth, Will-o'-Wisp, short-range Wardens |

### Maze testers

| Nightmare | Looks like | Trait | Tests | Counter |
|---|---|---|---|---|
| **Phantom** | a floating veiled ghost | glides **through walls** straight toward the Heartwood; low health | defence near the goal | Wardens near the Heartwood, long range. Rare, in its own drifts |
| **Gravecrawler** | a clawed thing that sinks into the earth | burrows under one Warden or wall per trip and surfaces on the other side | a maze depending on one long wall | layered walls; Rootcurl drags it back across the wall |
| **Night Hound** | a long, lean shadow-dog | after 3+ tiles in a straight line it **breaks into a sprint** | long straight corridors | twisty mazes, corners |
| **Procession** | a **Lantern Bearer** (a tall ghost with a cold lantern) leading 4 **Wraiths** in tight single file | if the Lantern Bearer is dispelled first, the Wraiths lose the way and slow down | chokepoints, area damage, target priority | Stormcap chains, Puffball, Chime Stone |
| **Sleepwalker** | a drifting figure with its eyes closed | sometimes takes a wrong turn into a dead end, then comes back | makes dead ends worth building | Wardens covering side pockets |

### Status testers

| Nightmare | Looks like | Trait | Tests | Counter |
|---|---|---|---|---|
| **Barrow Wight** | an ancient crowned figure, very slow | can't be Held; Drowsy lasts half as long; very high health | control-heavy builds | Spored, Marked, raw damage |
| **Drowned One** | a dripping, bloated shape trailing black water | always Damp, immune to slows | slow builds (a gift for Storm Grid) | Stormcap, Thunderhead |
| **Watcher** | a cluster of unblinking eyes | immune to Drowsy; **wakes** nearby Drowsy nightmares | target priority | high single-target damage, Beacon |
| **Ash Crawler** | a smouldering crawler | leaves burning ash that clears Spored from nightmares behind it | spore builds | dispel it early (Pebbling line) |
| **Will-o'-Wisp** | a flickering light | glows, revealing Lurkers near it: a nightmare that betrays its own | a helper, a gift | — |

### Support and swarm

| Nightmare | Looks like | Trait | Tests | Counter |
|---|---|---|---|---|
| **Mourner** | a veiled, weeping ghost | when dispelled, breaks into 3 **Sobs** | area damage | splash, pulses, Puffball |
| **Widow** | a bloated, many-legged shadow | when dispelled, bursts into 6 tiny, fast **Creeps** | area damage near the end of the maze | Chime Stone, Monsoon |
| **Shellbound** | a nightmare armoured in hardened dread | **dread shell**: a shield that must be broken before health (it visibly cracks off) | burst vs chip damage | heavy hits (Pebbling line) |
| **Whisper Swarm** | a cloud of whispering motes | one unit made of many; single-target damage reduced, area damage hits fully | build variety | splash, pulses, fog |
| **Dream Thief** | a quick, grinning shape clutching stolen light | steals Dew; reaching the Heartwood costs Dew + a leaf; dispelling it gives double Dew | risk/reward target priority | fast single-target |
| **Weeper** | a hunched figure crying black tears | mends nearby nightmares | target priority | Beacon, Mossback |

### Bosses (boss drifts, every 25th)

| Boss | Looks like | Trait | Tests |
|---|---|---|---|
| **The Hollow Stag** | a gaunt stag of bark and bone, ghost-fire in its antlers | huge health; tramples Thornwalls as it passes (never blocks the path); charges at half health (`acts_1_2.md`) | maze redundancy |
| **The Mire Hag** | a bent bog witch wrapped in reeds | every few seconds **sinks into the mire and rises 3 tiles ahead** along its path; each surfacing soaks nightmares nearby (Damp) | damage spread along the whole maze |
| **The Moth Queen** | a vast moth with a skull-like face on its wings | flies over the maze, dropping Lurkers as it goes | detection + goal defence |
| **The Hollow Oak** | the Hollow's corrupted heart walking on its roots | walks slowly, planting thorn-saplings on empty tiles next to the path; saplings are obstacles that re-route nightmares | adapting to a changing maze |

Dispelling a boss is a big moment: it shatters with light, extra Dew, and a line of text; the
Heartwood recovers a lost memory (a new Warden family).

## Resistances

Resistances give the 4 family picks per run weight: some nightmares are easy for your families and
some are hard, so every drift plays a little differently. They must never make a build hopeless.

### Rules

- **Never immune to damage.** Every Warden damages every nightmare at least somewhat.
- Regular nightmares have **at most one resistance and one weakness**; bosses up to two
  resistances and one weakness. Shades and the little ones (Sob, Creep, Wraith) have none, so the
  baseline stays readable.
- **Spread them out.** Each family is resisted and favoured by roughly the same number of
  nightmares (see the tally below). Drift composition mixes resistances so no drift hard-counters
  a single family.
- **Readable.** Each nightmare shows its resistance and weakness icons on hover and on its
  first-appearance card. Resisted hits make a small grey puff; weak hits flare brightly.
- **In the fiction**, a resistance is part of what the nightmare *is* ("stone passes through a
  Phantom like smoke"; "the Drowned One is already soaked").

### Kinds

**1. Family resistance / weakness** (damage multipliers by Warden family)

| | Multiplier | Applies to |
|---|---|---|
| **Resists** | **×0.5** damage (was ×0.65; mid-game rework 2026-09-27) | every hit from that family, including its Spored ticks, Static bolts, clouds and pulses |
| **Weak to** | **×1.5** damage (was ×1.35) | same |

Families: **spore** (Sporeling line), **stone** (Pebbling), **water** (Dewdrop), **light**
(Firefly Jar), **root** (Rootling), and in the full game **wing** (Nestling) and **wind**
(Whirligig). Sprout, Thornwall/Bramble and Acorn are neutral: they're
never resisted, so a Sprout is always a safe answer. Statuses still apply at full strength;
only the damage changes. Stacks multiplicatively with Marked
(`damage × family × shape × Marked`, then dread shell).

**2. Attack shape** (rare, one nightmare per shape at most)

| Nightmare | Single-target (projectile, chain) | Area (splash, pulse, cloud, Spored) |
|---|---|---|
| **Whisper Swarm** | ×0.5 | ×1.0 |

**3. Dread shell** (the Shellbound's armour): each hit's damage is reduced by a flat amount
(minimum 1) until the shell has soaked up its total, then it cracks off for good. Spored ticks and
Static bolts count as hits, so chip damage bounces off and heavy hits break it. Both numbers grow
with the nightmare's per-drift health scale.

**4. Status resistance**: immune, shorter duration or a lower stack cap per status.

| Nightmare | Damp | Drowsy | Spored | Marked | Static | Held |
|---|---|---|---|---|---|---|
| Phantom | | | | | | immune (floating), can't be pulled |
| Barrow Wight | | ×0.5 duration | | | | immune |
| Drowned One | always Damp | immune (no slows at all) | | | | immune (slips free) |
| Watcher | | immune; wakes Drowsy nightmares within 1.5 cells | | | | |
| Ash Crawler | | | clears Spored from nightmares on its trail | | | |
| Night Hound (while sprinting) | | | | | | immune |
| Bosses | | cap 3 | | | bolts at 8 stacks | ×0.5 duration |

### Family tally

Resists: spore 4 · stone 3 · water 4 · light 3 · root 4 · wing 3 · wind 3.
Weak to: spore 3 · stone 4 · water 3 · light 3 · root 3 · wing 3 · wind 3.
Re-check this whenever a nightmare is added or changed.

**Wing and wind** (Nestling and Whirligig are full-game Grove families, so the demo nightmares
keep their entries; only full-game nightmares moved to make room):

- *Weak to wing*: the Lurker (birds see what eyes can't), the Widow (birds pick off anything
  many-legged), the Dream Thief (magpies steal the stolen light back).
- *Resist wing*: the Gravecrawler (no beak reaches under the earth), the Watcher (it sees every
  swoop coming), the Moth Queen (she flies higher than any bird).
- *Weak to wind*: the Sleepwalker (gusts push it off course), the Will-o'-Wisp (blown out like a
  candle), the Whisper Swarm (the wind scatters its motes).
- *Resist wind*: the Barrow Wight (too ancient to be moved), the Shellbound (wind breaks on its
  shell), the Ash Crawler (wind only fans its embers).
- Moved to make room: Lurker lost light weakness, Sleepwalker lost spore weakness, Widow lost water
  weakness, Dream Thief lost root weakness, Gravecrawler lost root resistance, Watcher lost spore
  resistance, Barrow Wight lost stone resistance, Ash Crawler lost light resistance; the Shellbound
  gained root weakness (roots pry its shell apart). Lurker, Sleepwalker and Widow have `.tres`
  files: update their `weak_to` when the wing family exists in code.

## Stats

Drift 1 values; health then grows ×1.035 per drift (bosses fixed per act, see `run_design.md`).
Speed in px/s (64 px = 1 cell; Shade 100 ≈ 1.6 cells/s). Dew ≈ 3 per 100 health, a little more
for nightmares with a nasty trait. Values already in the game (`.tres`, under their old file names)
are marked ✓; the rest are proposals to tune.

| Nightmare (old name) | Health | Speed | Dew | Leaves | Resists | Weak to | Other |
|---|---|---|---|---|---|---|---|
| Shade (Leaf Bug) ✓ | 100 | 100 | 3 | 1 | — | — | baseline |
| Husk (Bark Beetle) ✓ | 300 | 58 | 8 | 2 | stone | spore | |
| Lurker (Dusk Moth) ✓ | 70 | 140 | 4 | 1 | spore | wing | hidden in fog |
| Phantom (Dandelion Seed) ✓ | 50 | 70 | 3 | 1 | root | water | glides through walls to the goal |
| Gravecrawler (Mole) | 180 | 75 | 5 | 1 | wing | stone | burrows under 1 Warden per trip |
| Night Hound (Hedgehog) ✓ | 160 | 80 (sprinting 200) | 5 | 1 | stone | water | sprints after 3 straight tiles |
| Lantern Bearer (Mother Duck) | 200 | 85 | 6 | 1 | water | root | 4 Wraiths follow it |
| Wraith (Duckling) | 40 | 85 | 1 | 1 | — | — | |
| Sleepwalker (Wandering Hare) ✓ | 110 | 110 | 4 | 1 | root | wind | wrong turns into dead ends |
| Barrow Wight (Tortoise) | 600 | 40 | 15 | 2 | wind | spore | see status table |
| Drowned One (Newt) | 120 | 95 | 4 | 1 | water | light | always Damp, no slows |
| Watcher (Owl) | 200 | 80 | 6 | 1 | wing | stone | wakes Drowsy neighbours |
| Ash Crawler (Snail) | 250 | 45 | 7 | 1 | wind | stone | clears Spored on its trail |
| Will-o'-Wisp (Glowworm) | 60 | 70 | 2 | 1 | light | wind | reveals Lurkers within 2 cells |
| Mourner (Puffcap) ✓ | 150 | 83 | 4 | 1 | spore | stone | breaks into 3 Sobs |
| Sob (Puffcaplet) ✓ | 30 | 115 | 1 | 1 | — | — | |
| Widow (Mother Spider) ✓ | 220 | 75 | 6 | 1 | spore | wing | bursts into 6 Creeps |
| Creep (Spiderling) ✓ | 20 | 140 | 1 | 1 | — | — | |
| Shellbound (Badger) | 250 | 70 | 8 | 2 | wind | root | dread shell: −6 per hit, soaks 100 |
| Whisper Swarm (Bee Swarm) | 180 | 105 | 5 | 1 | — | wind | single-target ×0.5 (its shape resistance is its trait) |
| Dream Thief (Squirrel) | 90 | 120 | 3 (×2) | 1 | light | wing | steals 5 Dew if it reaches the Heartwood |
| Weeper (Mossling) | 160 | 70 | 5 | 1 | water | light | mends nightmares within 1.5 cells for 2% of their max health/s |
| **The Hollow Stag** (Old Stag) ✓ | 3,000 | 51 | 40 | 5 | stone, root | water | tramples Thornwalls |
| **The Mire Hag** (Great Toad) | 8,000 | 55 (+ rises ahead) | 60 | 5 | water | root | surfaces 3 tiles ahead every 6 s |
| **The Moth Queen** (Mother Moth) | 16,000 | 65 | 80 | 5 | spore, wing | light | flies; drops a Lurker every 4 s |
| **The Hollow Oak** | 30,000 | 35 | 100 | 5 | root, light | spore | plants a thorn-sapling every 8 s |

The Hollow Oak's spore weakness and the Moth Queen's light weakness are deliberate: each boss has
a family that answers it, so a player who drafted that family gets a big moment. The Hollow Stag's
water weakness: rain douses the ghost-fire in its antlers.

## Drift composition

- Early drifts: Shades, then Husks mixed in.
- Introduce **one new nightmare per drift or two**, first alone in a small group so the player can
  read its trait, then mixed in.
- Maze testers (Phantom, Gravecrawler, Night Hound) come mid-run, after the player has built a maze
  worth testing.
- Status testers come after the first Dreams, when the player has statuses to be tested on.
- A boss drift ends each act.

## Art

Final art is original (brief above). Placeholders from the Foozle enemy pack are in use until then;
the old blight shader (grey) should become a **nightmare look** (dark, cold, slightly translucent,
glowing eyes) and dispelling a **crack-of-light burst** (for the enemy art and code sessions).

## Data

`EnemyData` resources (existing: `display_name`, `health`, `speed`, `dew_reward`, `leaf_cost`,
`is_boss`, `sprite_scale`, `split_into` / `split_count`, SpriteFrames). Renaming the `.tres` files
and `display_name`s to the new names is part of the theme change. Add:
- `traits` / `behaviors`: flying, burrow, shield, sprint_on_straights, follow_leader, wander.
- **Resistances** (export group "Resistances"):
  - `resists: Array[String]`, `weak_to: Array[String]`: family ids matching `TowerData.line`
    (spore, stone, water, light, root, wing, wind). Multipliers are constants (0.5 / 1.5) in one place so
    they tune globally.
  - `single_target_multiplier: float = 1.0`, `area_multiplier: float = 1.0`.
  - `coat_per_hit: int = 0`, `coat_total: int = 0` (both × the nightmare's `health_scale`).
  - `status_immune: Array[StringName]`, `status_duration_multipliers: Dictionary`
    ({status id: float}). Boss rules stay in `EnemyStatuses`.
- Damage needs a source: `Enemy.take_damage(amount, line := "", is_area := false)`. Towers pass
  their `TowerData.line` and attack shape; Spored remembers the applier's line so its ticks count
  as that family; Static bolts count as light.

Behaviours as small reusable scripts or strategy resources on `EnemyData`, like the planned tower
attack behaviours, so new nightmares are mostly data.

## Build order

1. Husk (tank) and Phantom (through walls): covers quick / sturdy / ignores the maze.
2. Mourner and Widow (splitters): tests area damage.
3. Night Hound and Sleepwalker: make the maze itself part of the strategy.
4. Status testers (Barrow Wight, Watcher, Drowned One) once statuses exist.
5. Bosses, starting with the Hollow Stag.
