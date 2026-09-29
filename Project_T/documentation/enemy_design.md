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
| **Watcher** | a cluster of unblinking eyes | immune to Drowsy; **wakes** nearby Drowsy nightmares; resists song | target priority; the natural counter to Bellflower builds | high single-target damage, Beacon |
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

### Bosses: a pool of 3 per act (added 2026-09-29, like Slay the Spire)

Acts 1–3 each have a **pool of 3 great nightmares**; each run draws **one per act**. Act 4 is always
**the Hollow Oak**, the story's climax, but in **one of 3 variations** (Thorned, Withering,
Remembering), drawn the same way. This replaces
"the Mire Hag or the Moth Queen at 50, the other at 75": the Hag is now an act 2 boss and the
Queen an act 3 boss.

**Rules**
- **Drawn at run start and shown from the act's first drift**, not just at the rest before the
  boss: the DriftBanner shows the boss's portrait ("Boss in N"), and its dossier can be opened any
  time. That's the strategy layer: you know what's coming for 25 drifts, so you build for it and
  choose your family pick with it in mind (the pick after a boss already knows the next act's boss).
- **The three bosses in a pool test different things**, so they're never interchangeable: a maze
  that beats one can lose to another.
- **Each boss has one weakness**, and within an act they're weak to different damage types, so every
  family has a good matchup somewhere. **Act 1 bosses are each weak to one of the three starting
  families' types (Spore, Water, Light) and resist none of them** (act 1 fairness: a boss is most
  of its drift's health).
- **First run ever: act 1 is always the Hollow Stag** (onboarding's whispers and first boss fight are
  written for it). After that, random, weighted against the boss you met in that act last run.
- **Memory Wardens are parked** (cut for now, 2026-09-29, `tower_design.md`); the per-boss memories
  below are kept for a possible return.
- **Each boss wears a stolen dream** (`story.md`), so each has a **Memory Warden**; a new boss's
  memory is the kind version of its curse. 9 bosses = 9 Memory Wardens (the Oak has none).
- Escorts belong to the boss (listed below), not to the drift.
- Blight Levels, Omens and "boss health ×1.5" apply to every boss the same way.

| Act | Boss | Looks like | Trait | Tests | Resists | Weak to |
|---|---|---|---|---|---|---|
| 1 | **The Hollow Stag** | a gaunt stag of bark and bone, ghost-fire in its antlers | huge health; tramples Thornwalls as it passes (never blocks the path); charges at half health (`acts_1_2.md`) | maze redundancy | stone, root | water |
| 1 | **The Night Mare** *(new)* | a black horse of smoke, hooves that never touch the ground, eyes like cold coals | fast, less health; **it doesn't stop at the Heartwood**: each time it reaches it, it takes 3 leaves and gallops back to the start to run the maze again, 20% faster | maze length and sustained damage (every lap is another pass through the whole maze) | root | light |
| 1 | **The Scarecrow** *(new)* | a sack-headed scarecrow on a crooked pole, stitched grin, crows under its coat | walks slowly; **every 20% health lost, a flock of 5 Crows bursts out** and runs ahead along the path (fast, 1 leaf each) | area damage near the boss, and Wardens further down the maze to catch the crows | stone, talon | spore |
| 2 | **The Mire Hag** | a bent bog witch wrapped in reeds | every few seconds **sinks into the mire and rises 3 tiles ahead** along its path; each surfacing soaks nightmares nearby (Damp) | damage spread along the whole maze | water | root |
| 2 | **The Huntsman** *(new)* | a tall antlered rider without a face, a bone horn at his hip | leads **4 Night Hounds**; **while any hound lives he takes half damage** (the pack shields him); every 12 s he blows his horn and a new hound joins (up to 4) | target priority and area damage; the hounds sprint on straights, so corners matter | spore | stone |
| 2 | **The Lamplighter** *(new)* | a thin, stooped ghost with a pole of cold blue flame | every 8 s it **lights a cold lantern** on an empty tile beside the path; **Wardens within 1.5 tiles of a lantern attack 40% slower** until it burns out (16 s) or the player clicks it to snuff it | **don't put everything in one kill zone**: the first boss that fights your Wardens, not your maze | light, song | water |
| 3 | **The Moth Queen** | a vast moth with a skull-like face on its wings | flies along the route above it, dropping Lurkers; Eclipse at half health (`acts_3_4.md`) | detection + a long maze | spore, talon | light |
| 3 | **The Barrow King** *(new)* | a crowned, mail-clad corpse-king, very tall, dragging a rusted sword | **Iron Will:** never slowed below 70% speed, can't be Held; every 10 s he **shrugs off every status** on himself and nightmares within 2 tiles (Static discharges harmlessly) | status-heavy builds: raw damage and Marked-style burst between shrugs | song, water | root |
| 3 | **The Mourning Mother** *(new)* | a vast veiled figure weeping black tears, Weepers clinging to her skirts | **Sorrow:** when no Warden has hit her for 1.5 s, she **mends 2% of her max health per second** (and mends nightmares within 2 tiles like a Weeper) | **gaps in the maze**: stretches with no Warden coverage let her heal back | stone, light | song |
| 4 | **The Hollow Oak: Thorned** | the Hollow's corrupted heart walking on its roots, bristling with black thorns | walks slowly, planting thorn-saplings on empty tiles next to the path; saplings are obstacles that re-route nightmares; Grief rings of Mourners | adapting to a changing maze | light, song | spore |
| 4 | **The Hollow Oak: Withering** *(new)* | bare, grey and cracked, its roots dragging through dead leaves | every 10 s a root surfaces under a Warden near it and **withers** it (no attacks for 6 s) | redundant coverage: no single Warden the maze can't do without | root, stone | water |
| 4 | **The Hollow Oak: Remembering** *(new)* | hung with pale faces in the bark, one for every great nightmare | at 75 / 50 / 25% health, an **echo of a boss you dispelled this run** rises beside it | a final exam of your own run | spore, water | light |

**Weakness spread:** act 1 water / light / spore (the three starting families); act 2 root / stone /
water; act 3 light / root / song; act 4 spore / water / light. Bosses are tallied **separately** from the regular
nightmares' family tally below (they're one fight each, not a drift's worth of health).

**New bosses in detail** (escort, phases, Memory Warden; numbers are starting points)

- **The Night Mare** (act 1). *Laps:* reaching the Heartwood costs 3 leaves (not 5), then it
  reappears at the start at +20% speed (stacking). It keeps its damage taken, so every lap is
  progress. *Bolt* (at half health): 3 s of +50% speed, once. Escort: 10 Shades ahead, 4 Husks
  behind. Dispelled: *"The Night Mare is gone. The hoofbeats fade, and the dream is still."*
  Memory: **The Carousel Horse**, a painted wooden horse from a child's dream; nightmares passing it
  slow down as if caught on the carousel.
- **The Scarecrow** (act 1). *Crows:* 5 at 80/60/40/20% health (and 5 more when dispelled): 40
  health each (× drift growth), speed 150, walk the maze from where the Scarecrow is. *Stitched:*
  below 40% it walks 25% faster. Escort: 8 Shades, then the Scarecrow, then 3 Mourners. Dispelled:
  *"The Scarecrow falls. The crows scatter, and they don't come back."* Memory: **The Harvest Doll**,
  a little corn doll that birds love; Talon damage from the crows nesting in it.
- **The Huntsman** (act 2). *Pack:* 4 Night Hounds walk around him (they count as normal Night Hounds
  and sprint on straights). The half-damage shield shows as a faint ring linking him to each hound.
  *The Kill* (at half health): he blows three times and all missing hounds return at once, then no
  more horns. Escort: 6 Night Hounds ahead, 2 Processions behind. Dispelled: *"The horn falls
  silent. The hunt is over."* Memory: **The Old Hound**, a faithful grey dog spirit that runs down
  the nightmare closest to the Heartwood.
- **The Lamplighter** (act 2). *Lanterns* (as built 2026-09-29): up to 4 at once, on empty cells
  beside its route, never on the route or a Warden (they don't block at all, they're a light). Each
  **burns out after 16 s**, goes out when the Lamplighter is dispelled, or is **snuffed by clicking
  it (+2 Dew)**. Lanterns having health for Wardens to shoot would need Warden targeting to change;
  revisit after playtests. *Long Night* (all lanterns flare, −60% for 5 s at half health) is not
  built yet. Escort: 10 Lurkers ahead (the cold light doesn't reveal them), then the Lamplighter, then
  4 Husks. Dispelled: *"The cold lanterns go out, one by one."* Memory: **The Warm Lamplighter**:
  its lanterns make Wardens near them attack faster: the curse turned around.
- **The Barrow King** (act 3). *Shrug:* a visible pulse of grave-dust; statuses are cleared, not
  resisted (they can be put back straight away). Static stacks are lost without a bolt. *Crown of
  the Dead* (at half health): 4 Barrow Wights rise around him. Escort: 2 Barrow Wights, 6 Husks,
  then the King. Dispelled: *"The Barrow King lies down again, and this time he sleeps."* Memory:
  **The Sleeping King**, an old stone king who lengthens every status on nightmares near him.
- **The Mourning Mother** (act 3). *Sorrow* shows as black tears falling while she heals, stopping
  the moment she's hit. Healing is capped at 25% of her max health in all (she doesn't lap). *Her
  Children* (at two-thirds and one-third health): 3 Weepers rise from her skirts. Escort: 4
  Weepers and 6 Mourners. Dispelled: *"She stops weeping. For the first time, the Hollow is
  quiet."* Memory: **The Cradle Song**, a lullaby spirit: the Heartwood regrows 1 leaf at every rest
  while it stands.

**The Hollow Oak's three variations** (act 4, drift 100)

The Hollow's heart takes the shape of its grief: **Thorned** keeps everyone out, **Withering** lets
everything die, **Remembering** can't let go. All three are the Hollow Oak: same silhouette (a
walking oak on its roots), same slow walk (35), same finale (*"The Hollow Oak is still. Somewhere
beyond the dream, the Hollow remembers."*), no Memory Warden. Drawn at run start like the other
bosses and shown from drift 76; **a player's first act 4 is always Thorned** (the story's version,
described in `acts_3_4.md`). **Blight Level 10** ("The Hollow Oak remembers") works for every
variation: it rises once more at half health with its trait twice as fast.

- **Thorned** (the original, `acts_3_4.md`): thorn-saplings every 8 s re-route the nightmares;
  *Grief* at two-thirds and one-third health raises a ring of 6 Mourners. Escort: 3 Processions, 8
  Mourners, 4 Weepers. 30,000 health. Tests adapting to a changing maze.
- **Withering**: every 10 s a root surfaces under a Warden within 3 tiles of it (the strongest one:
  highest damage × attack speed, never the same one twice in a row) and **withers** it for 6 s: grey,
  no attacks, no auras. It comes back on its own, unharmed. *Drought* (at two-thirds and one-third
  health): withers 3 Wardens at once. (The dead-leaf trail slowing projectiles is not built.) Escort: 4 Barrow Wights, 8 Husks, 4 Ash Crawlers.
  30,000 health. Tests redundant coverage: a maze that leans on one great Warden stalls for 6 s at
  a time; a maze with every stretch covered twice doesn't notice. Weak to water (rain wakes what it
  withers).
- **Remembering**: at 75 / 50 / 25% health an **echo** of each boss you dispelled this run (act 1,
  then 2, then 3) rises beside it: translucent, **20% of that boss's drift-100 health**, with its full
  trait (a Night Mare echo laps, a Lamplighter echo lights lanterns, a Huntsman echo brings its
  hounds). A run that lost no boss faces all three. Escort: 2 Processions, 6 Mourners, 4 Watchers.
  26,000 health (the echoes carry the rest). Tests the whole run: the bosses you've already beaten,
  at once, with your final maze. Weak to light (the faces fade in the light).

Each variation's weakness is one of the starting three types (Spore / Water / Light), so the family
you drafted first always has a variation it's good against.

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
- **Act 1 is fair to one family** (2026-09-28): before the drift 25 pick most players have one family, so **no act 1 drift may have more than ~40% of its health resistant to one damage type** (rolled drifts count every family; the hand-made reference tables were checked against only the starting three families' types; Plain never counts) (the old Wake, all Mourners, broke single-family spore boards).
- **Spread them out.** Each family is resisted and favoured by roughly the same number of
  nightmares (see the tally below). Drift composition mixes resistances so no drift hard-counters
  a single family.
- **Readable.** Each nightmare shows its resistance and weakness icons on hover and on its
  first-appearance card. Resisted hits make a small grey puff; weak hits flare brightly.
- **In the fiction**, a resistance is part of what the nightmare *is* ("stone passes through a
  Phantom like smoke"; "wind only fans the Ash Crawler's embers").

### Kinds

**1. Damage-type resistance / weakness** (damage multipliers by the Warden's **damage type**; renamed 2026-09-28, see "Damage types" below)

| | Multiplier | Applies to |
|---|---|---|
| **Resists** | **×0.5** damage (was ×0.65; mid-game rework 2026-09-27) | every hit from that family, including its Spored ticks, Static bolts, clouds and pulses |
| **Weak to** | **×1.5** damage (was ×1.35) | same |

Families: **spore** (Sporeling line), **stone** (Pebbling), **water** (Dewdrop), **light**
(Firefly Jar), **root** (Rootling), later **song** (Bellflower: Chime Stone and Lullaby Bell moved here from stone), and in the
full game **wing** (Nestling) and **wind** (Whirligig). Sprout, Thornwall/Bramble and Acorn are neutral: they're
never resisted, so a Sprout is always a safe answer. Statuses still apply at full strength;
only the damage changes. Stacks multiplicatively with Marked
(`damage × family × shape × Marked`, then dread shell).

#### Damage types (2026-09-28, user: "resistant not to the specific Warden but the Warden's type")

Nightmares resist or fear a **damage type**, and **every Warden shows its damage type**. The type
is a property of the Warden (`TowerData.line`), not of a named Warden: by default each family
deals one type, but a branch or hidden form may deal another where it fits the fiction, so a
type can span families.

| Type | Icon (`damage_type` group, 1e4017c: a warm symbol on a small gold-rimmed badge, so types never read as statuses) | Default family | Fiction |
|---|---|---|---|
| **Spore** | a puff of spores | Sporeling | rot and spores |
| **Stone** | a cracked pebble | Pebbling | weight and impact |
| **Water** | a droplet | Dewdrop | rain, tide, mist |
| **Light** | a spark | Firefly Jar | lantern light and lightning |
| **Root** | a curling root | Rootling | grasping roots |
| **Song** | a bell / note | Bellflower | sound, lullabies |
| **Talon** | a feather claw | Nestling | beaks and claws (was "wing") |
| **Wind** | a swirl | Whirligig | gusts and blades |
| **Plain** | none (a plain dot) | Sprout, Thornwall, Bramble, Acorn, Memory Wardens | never resisted, never weak |

- **Effect damage keeps its source's type:** Poisoned ticks deal the type of the Warden that applied
  them (usually Spore), Charged bolts deal **Light**, clouds / rings / seeds the type of the Warden
  that made them. Reactions deal the type of the Warden that set them off.
- **Shown everywhere with the type icon, never a Warden's face:** the Warden panel and build
  tooltip ("Light damage"), the Warden bar tooltip, nightmare info ("Resists Stone ×0.5"), the boss
  dossier, the map's shield / spark pips, the Codex glossary ("Damage types" page).
- The rules above (at most one resistance and one weakness, spread evenly) now count **types**.

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

Resists: spore 3 · stone 3 · water 3 · light 3 · root 3 · wing 3 · wind 3 · song 3.
Weak to: spore 3 · stone 3 · water 3 · light 3 · root 3 · wing 2 · wind 2 · song 3.
Re-check this whenever a nightmare is added or changed. There are 22 weakness slots for 8
families, so two families sit at 2: wing and wind, the full-game families (Whirligig is an
amplifier, so it leans on weaknesses least).

**Families added later** (wing and wind are full-game Grove families, song a base-game Grove
family; none is in the demo, so the demo nightmares keep their entries and only non-demo
nightmares moved to make room):

- *Weak to wing*: the Lurker (birds see what eyes can't), the Dream Thief (magpies steal the
  stolen light back).
- *Resist wing*: the Gravecrawler (no beak reaches under the earth), the Widow (no bird goes near
  her web), the Moth Queen (she flies higher than any bird).
- *Weak to wind*: the Will-o'-Wisp (blown out like a candle), the Whisper Swarm (the wind scatters
  its motes).
- *Resist wind*: the Barrow Wight (too ancient to be moved), the Shellbound (wind breaks on its
  shell), the Ash Crawler (wind only fans its embers).
- *Weak to song*: the Sleepwalker (already half asleep), the Gravecrawler (a buried thing, lulled
  back into its grave), the Widow (the bells sing her still in her own web).
- *Resist song*: the **Watcher** (it never sleeps: with its Drowsy immunity it's the natural
  counter to Bellflower builds), the Drowned One (no song carries under black water), the Hollow
  Oak (the Hollow's heart has never slept).
- Moved to make room (vs the five-family version): Lurker lost light weakness, Sleepwalker lost
  spore weakness, Widow lost spore resistance and water weakness, Dream Thief lost root weakness,
  Gravecrawler lost root resistance and stone weakness, Watcher lost spore resistance, Barrow Wight
  lost stone resistance, Ash Crawler lost light resistance, Drowned One lost water resistance, the
  Hollow Oak lost root resistance; the Shellbound gained root weakness (roots pry its shell apart).
  Lurker, Sleepwalker and Widow have `.tres` files: update their `resists` / `weak_to` when these
  families exist in code.
## Stats

Drift 1 values; health then grows per drift (×1.045, ×1.055 from drift 26, ×1.045 from 51; bosses fixed per act × 1.5; see `run_design.md`).
Speed in px/s (64 px = 1 cell; Shade 100 ≈ 1.6 cells/s). Dew ≈ 3 per 100 health, a little more
for nightmares with a nasty trait. Values already in the game (`.tres`, under their old file names)
are marked ✓; the rest are proposals to tune.

| Nightmare (old name) | Health | Speed | Dew | Leaves | Resists | Weak to | Other |
|---|---|---|---|---|---|---|---|
| Shade (Leaf Bug) ✓ | 100 | 100 | 3 | 1 | — | — | baseline |
| Husk (Bark Beetle) ✓ | 300 | 58 | 8 | 2 | stone | spore | |
| Lurker (Dusk Moth) ✓ | 70 | 140 | 4 | 1 | spore | wing | hidden in fog |
| Phantom (Dandelion Seed) ✓ | 50 | 70 | 3 | 1 | root | water | glides through walls to the goal |
| Gravecrawler (Mole) | 180 | 75 | 5 | 1 | wing | song | burrows under 1 Warden per trip |
| Night Hound (Hedgehog) ✓ | 160 | 80 (sprinting 200) | 5 | 1 | stone | water | sprints after 3 straight tiles |
| Lantern Bearer (Mother Duck) | 200 | 85 | 6 | 1 | water | root | 4 Wraiths follow it |
| Wraith (Duckling) | 40 | 85 | 1 | 1 | — | — | |
| Sleepwalker (Wandering Hare) ✓ | 110 | 110 | 4 | 1 | root | song | wrong turns into dead ends |
| Barrow Wight (Tortoise) | 600 | 40 | 15 | 2 | wind | spore | see status table |
| Drowned One (Newt) | 120 | 95 | 4 | 1 | song | light | always Damp, no slows |
| Watcher (Owl) | 200 | 80 | 6 | 1 | song | stone | wakes Drowsy neighbours |
| Ash Crawler (Snail) | 250 | 45 | 7 | 1 | wind | stone | clears Spored on its trail |
| Will-o'-Wisp (Glowworm) | 60 | 70 | 2 | 1 | light | wind | reveals Lurkers within 2 cells |
| Mourner (Puffcap) ✓ | 150 | 83 | 4 | 1 | spore | stone | breaks into 3 Sobs |
| Sob (Puffcaplet) ✓ | 30 | 115 | 1 | 1 | — | — | |
| Widow (Mother Spider) ✓ | 220 | 75 | 6 | 1 | wing | song | bursts into 6 Creeps |
| Creep (Spiderling) ✓ | 20 | 140 | 1 | 1 | — | — | |
| Shellbound (Badger) | 250 | 70 | 8 | 2 | wind | root | dread shell: −6 per hit, soaks 100 |
| Whisper Swarm (Bee Swarm) | 180 | 105 | 5 | 1 | — | wind | single-target ×0.5 (its shape resistance is its trait) |
| Dream Thief (Squirrel) | 90 | 120 | 3 (×2) | 1 | light | wing | steals 5 Dew if it reaches the Heartwood |
| Weeper (Mossling) | 160 | 70 | 5 | 1 | water | light | mends nightmares within 1.5 cells for 2% of their max health/s |
| **The Hollow Stag** (Old Stag) ✓ | 3,000 | 51 | 40 | 5 | stone, root | water | tramples Thornwalls |
| **The Mire Hag** (Great Toad) | 8,000 | 55 (+ rises ahead) | 60 | 5 | water | root | surfaces 3 tiles ahead every 6 s |
| **The Moth Queen** (Mother Moth) | 16,000 | 65 | 80 | 5 | spore, wing | light | flies; drops a Lurker every 4 s |
| **The Hollow Oak: Thorned** | 30,000 | 35 | 100 | 5 | light, song | spore | plants a thorn-sapling every 8 s |
| **The Hollow Oak: Withering** | 30,000 | 35 | 100 | 5 | root, stone | water | withers a Warden every 10 s |
| **The Hollow Oak: Remembering** | 26,000 | 35 | 100 | 5 | spore, water | light | echoes of this run's bosses at 75/50/25% |
| **The Night Mare** *(act 1)* | 2,000 | 110 (+20% per lap) | 40 | 3 per lap | root | light | laps the maze until dispelled |
| **The Scarecrow** *(act 1)* | 2,600 | 45 | 40 | 5 | stone, talon | spore | Crows at every 20% |
| Crow (Scarecrow) | 40 | 150 | 1 | 1 | — | — | |
| **The Huntsman** *(act 2)* | 6,500 | 65 | 60 | 5 | spore | stone | half damage while a hound lives |
| **The Lamplighter** *(act 2)* | 7,000 | 55 | 60 | 5 | light, song | water | cold lanterns slow Wardens |
| **The Barrow King** *(act 3)* | 16,000 | 40 | 80 | 5 | song, water | root | shrugs off statuses every 10 s |
| **The Mourning Mother** *(act 3)* | 14,000 | 45 | 80 | 5 | stone, light | song | heals when unhit for 1.5 s |

New boss health is set against its act's base (3,000 / 8,000 / 16,000) for how much the trait
multiplies it: the Night Mare's laps and the Huntsman's shield make their real health much higher,
the Mourning Mother's healing too, so their listed health is lower. All × 1.5 in play like every
boss. Tune in the balance simulation (`balance_simulation.md`): each pool's three bosses should take
about the same time to dispel for an average maze of that act.

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
    (spore, stone, water, light, root, song, wing, wind). Multipliers are constants (0.5 / 1.5) in one place so
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

**Boss pools** (2026-09-29): a `BossData` resource per boss (the boss's `EnemyData`, its escort as
`DriftGroup`s, act, Memory Warden, dossier text, dispel line) and a pool per act
(`resource/boss/act_1/*.tres` … `act_4/` holds the Oak's 3 variations as 3 `BossData`). The run draws one per act at start (seeded with the map; first
run ever: act 1 = Hollow Stag; weighted against last run's boss, profile `last_bosses`) and keeps
the draw in the run save. The boss drift files (25 / 50 / 75) hold a **boss slot** instead of a
named boss; the director fills it from the draw. The DriftBanner and dossier read the drawn boss.
New boss mechanics: laps (Night Mare), spawn-on-health-threshold (Scarecrow, and the Hollow Oak's
Grief already), linked shield (Huntsman), Warden-debuff objects with health (Lamplighter's
lanterns), status shrug (Barrow King), out-of-combat regen (Mourning Mother), Warden wither (Withering Oak),
echoes (Remembering Oak: spawns this run's dispelled bosses from the draw at a health fraction).

## Build order

1. Husk (tank) and Phantom (through walls): covers quick / sturdy / ignores the maze.
2. Mourner and Widow (splitters): tests area damage.
3. Night Hound and Sleepwalker: make the maze itself part of the strategy.
4. Status testers (Barrow Wight, Watcher, Drowned One) once statuses exist.
5. Bosses, starting with the Hollow Stag.
6. Boss pools: the draw and boss slot first (Stag, Hag and Queen already give acts 1–3 one
   each), then the new bosses act by act: Night Mare and Scarecrow, then Huntsman and
   Lamplighter, then Barrow King and Mourning Mother.
