# Tower Design — Wardens

Overview and run loop: see `game_design.md`. Enemies: see `enemy_design.md`. Story: `story.md`.

Design pillar: **towers are walls, so builds should care about the maze**: path length,
adjacency, corners, wall count. That's what no other tower defense roguelite can do.

## Evolution tree

Every run starts with only the **Sprout** (plus Thornwall). Sprouts grow into the base Wardens
(7 families, 9 in the full game),
bases grow into branches, branches into final forms. **Base families come from family picks**
(after drift 1 and from the bosses at 25, 50, 75; 4 per run, see `run_design.md`); branches and
final forms come from Dreams.

```
								SPROUT (weak spore puffs)
   ┌────────────┬────────────┬──────┴─────┬────────────┬────────────┐
Sporeling  Dewdrop  Firefly Jar  Pebbling  Rootling  Bellflower  Acorn  (+ Nestling, Whirligig)  ← family picks
 (2 branches each, then a final form per branch — see table)                   ← Dew / Rare Dreams
```

| Base | Role | Owns | Branch A → final | Branch B → final | Hidden (late) → final |
|---|---|---|---|---|---|
| **Sporeling** | damage over time | Spored | Driftspore → Puffball | Bloomcap → Dreamshroom | Fairy Ring → Elf Circle |
| **Dewdrop** | water: splash, fog, ice | Damp | Rain Lily → Monsoon | Mistveil → Morning Fog | Frostfern → Hoarfrost |
| **Firefly Jar** | light: lightning, marking, beams | Static, Marked | Stormcap → Thunderhead | Lanternmoth → Beacon | Sunpetal → Midsummer |
| **Pebbling** | heavy hits | — (payoff family) | Mossback → Boulderback | Standing Stone → Moonstone | Cairn → Rockslide |
| **Rootling** | crowd control | Held | Rootcurl → Long Way Home | Tangleroot → Snugroot | Rootlight → Starcave |
| **Bellflower** | song and sleep | Drowsy | Chime Stone → Lullaby Bell | Dreamcatcher → Great Dreamcatcher | Echo Hollow → Whispering Hollow |
| **Acorn** | support, economy | — | Elder Stump → Grove Heart | Dewcatcher → Wellspring | Graftling → Grafted Elder |
| **Nestling** *(full game)* | birds: fast hunters | — | Wren's Nest → Starling Murmuration | Magpie Perch → Magpie's Hoard | Hummingbird Bower → Jewelwing Court |
| **Whirligig** *(full game)* | wind: spreads statuses | copies | Gust → Zephyr | Pinwheel → Windmill | Samara → Autumn Gale |

- **Hidden branches** are late Memory Grove unlocks (Sunpetal from a milestone). Once unlocked,
  they can be chosen with Dreamlight like any branch.
- **Nestling and Whirligig** are Grove unlocks for the full game (not in the demo). A run still
  gets **4 families**; more families means more variety between runs.
- **Memory Wardens** (below) are unique Wardens freed from the act bosses.

### Family design rules (reviewed 2026-09-27)

Every family was checked against these rules. Changes from the review are listed after them.

1. **One role per family, in one sentence.** A player should be able to say "Pebbling hits hard"
   or "Bellflower puts them to sleep" after one run.
2. **Each family owns at most one or two statuses** (applies them best), and every status has an
   owner: Spored (Sporeling), Damp (Dewdrop), Static and Marked (Firefly Jar), Held (Rootling),
   Drowsy (Bellflower). Other families may touch a status in one branch, which creates combos inside
   a family (e.g. Bloomcap's sleepy spores).
3. **Branches are different playstyles, not bigger numbers.** Branch A is usually the family's
   plain version; branch B bends it in another direction.
4. **Hidden branches are late unlocks for experienced players.** They're often **combo engines**
   (Fairy Ring traps, Frostfern freezes, Echo Hollow repeats Reactions, Hummingbird multi-hits,
   Samara carries statuses) or an unusual shape (Cairn mortar, Graftling copies).
5. **A final form is its branch's idea, bigger**, plus one signature moment. It never changes what
   the branch does.
6. **Every family has an answer to at least one nightmare trait** (Lurkers: Lanternmoth, Rootlight;
   Phantoms: snipers, Wren's Nest; Shellbound: Pebbling; swarms: area Wardens), so no family is a
   dead pick against a given drift.

**Changes from the review:**
- **New family: Bellflower (song and sleep).** Nobody owned Drowsy, even though sleep is the heart
  of a game about dreams, and the story says Wardens *sing* nightmares away. Chime Stone and Lullaby
  Bell move here from Pebbling (they were a sleep/song branch inside the heavy-hit family). New:
  Bellflower, Dreamcatcher, Great Dreamcatcher, Echo Hollow, Whispering Hollow.
- **Pebbling is now only heavy hits:** Mossback (close), **Standing Stone (sniper), moved from
  hidden to branch B** to fill Chime Stone's slot, and a new hidden **Cairn → Rockslide**
  (mortar: lobbed area shots over the maze). Close, far and area: three kinds of heavy.
- **Starling Murmuration** now hunts the **3 fastest** nightmares instead of sweeping straights.
  It matches Wren's Nest (its branch) and leaves straight corridors to Samara.
- **Nestling and Whirligig get hidden branches:** Hummingbird Bower (multi-hit) and Samara
  (boomerang), both late unlocks.

## Every Warden

**Applies** = effect it puts on nightmares. **Loves** = what it gets a bonus from. Synergy happens
where one Warden's *applies* matches another's *loves*. Numbers are starting points for tuning.

**Sprout**: weak spore puff, no effects. The only attacker at run start.

**Sporeling line**

| Tier | Warden | Does | Applies | Loves |
|---|---|---|---|---|
| Base | Sporeling | puffs that linger | Spored ×1 | long paths |
| A | Driftspore | 2 stacks per puff, higher stack cap | Spored ×2 | long paths, pulls |
| A+ | Puffball | at 10+ stacks, pops them all for a burst of damage; half the stacks spread to nearby nightmares | Spored | crowds |
| B | Bloomcap | leaves a sleepy cloud on path tiles | Drowsy | chokepoints, Held |
| B+ | Dreamshroom | nightmares at max Drowsy fall asleep for 1.5 s (once each) | Drowsy | Held |
| Hidden | Fairy Ring | **trap tower**: plants mushroom rings on path tiles in range; a nightmare stepping on one sets off a spore burst | Spored | chokepoints, long paths |
| Hidden+ | Elf Circle | more rings, and they stay until stepped on | Spored | chokepoints |

**Pebbling line**: heavy hits in three shapes: close (Mossback), far (Standing Stone), area (Cairn). Applies nothing;
it's the family that **cashes in** Marked, Held and Drowsy, and the answer to the Shellbound.

| Tier | Warden | Does | Applies | Loves |
|---|---|---|---|---|
| Base | Pebbling | slow, heavy pebble | — | Marked |
| A | Mossback | huge single hit, short range; double damage vs Marked | — | Marked, Drowsy |
| A+ | Boulderback | hit splashes to nearby tiles; guaranteed crit on Drowsy | — | Marked, Drowsy |
| B | Standing Stone | **sniper**: range 8, one slow heavy shot; more damage the further the target; can't hit nightmares right beside it (minimum range 2) | — | distance, Marked, Held |
| B+ | Moonstone | range 10; its **first hit on each nightmare is always a crit** | — | distance, Marked, Held |
| Hidden | Cairn | **mortar**: a golem beside a stone cairn lobs the top stone over the maze onto a tile up to 6 cells away, splashing everything there | — | crowds, chokepoints, Held |
| Hidden+ | Rockslide | bigger splash; leaves **rubble** on the path that slows for 3 s | — | crowds, chokepoints, Held |

**Dewdrop line**

| Tier | Warden | Does | Applies | Loves |
|---|---|---|---|---|
| Base | Dewdrop | small splash | Damp | groups |
| A | Rain Lily | bigger splash, longer Damp | Damp | groups |
| A+ | Monsoon | rains on everything in range every few seconds | Damp | — |
| B | Mistveil | fog on path tiles: slows, keeps nightmares Damp; Spored ticks harder in fog | Damp | Spored, Held |
| B+ | Morning Fog | fog covers a longer stretch of path, also applies Drowsy | Damp, Drowsy | Spored, Held |
| Hidden | Frostfern | hits on **Damp** nightmares freeze them briefly (counts as Held) | Held | Damp |
| Hidden+ | Hoarfrost | splash, longer freeze; hits on Held nightmares get +20% crit chance | Held | Damp, Held |

**Firefly Jar line**

| Tier | Warden | Does | Applies | Loves |
|---|---|---|---|---|
| Base | Firefly Jar | small spark | Static ×1 | Damp |
| A | Stormcap | chains to 3 nightmares; +2 jumps and longer jumps between Damp nightmares | Static | Damp |
| A+ | Thunderhead | every 5th attack strikes every Damp nightmare in range | Static | Damp |
| B | Lanternmoth | long range, reveals Lurkers hidden in fog | Marked | — |
| B+ | Beacon | marks everything in range; Marked take extra damage from every source | Marked | — |
| Hidden | Sunpetal | beam that ramps the longer it holds one target; ramps 2× on Drowsy/Held | — | Drowsy, Held |
| Hidden+ | Midsummer | ramps higher, and the beam also hits the nightmare behind its target | — | Drowsy, Held |

**Rootling line**

| Tier | Warden | Does | Applies | Loves |
|---|---|---|---|---|
| Base | Rootling | roots nip at feet (slight slow) | — | long paths |
| A | Rootcurl | pulls a nightmare back 1 tile every few seconds | — | Spored, long paths |
| A+ | Long Way Home | pulls back 3 tiles; can't pull the same nightmare twice | — | Spored, long paths |
| B | Tangleroot | holds a nightmare in place for 1 s | Held | area effects |
| B+ | Snugroot | holds up to 3 nightmares at once | Held | area effects |
| Hidden | Rootlight | glowing roots light up path tiles in range: **reveals Lurkers**, **Gravecrawlers can't burrow** there, nightmares on lit tiles are Marked | Marked | long paths |
| Hidden+ | Starcave | bigger lit area; Marked from it lingers 2 s after leaving the light | Marked | long paths |

**Bellflower line**: song and sleep. Bell-flower spirits that ring, hum and sing nightmares to
sleep, then make sleep dangerous. Owns **Drowsy**.

| Tier | Warden | Does | Applies | Loves |
|---|---|---|---|---|
| Base | Bellflower | a soft ringing pulse around it; every 2nd pulse adds Drowsy | Drowsy | chokepoints |
| A | Chime Stone | weak pulse hitting everything around it; pulses set off Static | Static ×1 | Static, Held |
| A+ | Lullaby Bell | bigger pulse that also applies Drowsy | Drowsy | Static, Held |
| B | Dreamcatcher | hangs a dreamcatcher over the path: **sleeping or max-Drowsy nightmares in range are Caught** and take +40% damage from everything | — | Drowsy, sleep |
| B+ | Great Dreamcatcher | +60%; sleep in its range lasts 1 s longer; Caught nightmares that are dispelled drop **Dreamlight shards** | — | Drowsy, sleep |
| Hidden | Echo Hollow | a hollow log that **echoes Reactions**: a Reaction nearby repeats 1 s later at 50% | — | Reactions |
| Hidden+ | Whispering Hollow | 75%, bigger radius; **echoes count as chain links** | — | Reactions, chains |

**Acorn line**

| Tier | Warden | Does | Applies | Loves |
|---|---|---|---|---|
| Base | Acorn | +5% damage to adjacent Wardens | — | neighbours |
| A | Elder Stump | adjacent Wardens attack 20% faster | — | tight clusters |
| A+ | Grove Heart | radius 2; bonus grows per nearby Warden | — | tight clusters |
| B | Dewcatcher | +Dew each drift | — | time |
| B+ | Wellspring | interest on saved Dew (capped) | — | saving Dew |
| Hidden | Graftling | **copies the attack of its strongest adjacent Warden** at 60% (including its statuses) | copied | clusters |
| Hidden+ | Grafted Elder | copies at 85% | copied | clusters |

**Nestling line** *(full game)*: birds that swoop out and back. The family for fast and
wall-ignoring nightmares.

| Tier | Warden | Does | Applies | Loves |
|---|---|---|---|---|
| Base | Nestling | a bird swoops at a nightmare and returns | — | fast nightmares |
| A | Wren's Nest | quick wrens hunt the **fastest** nightmare in range; bonus vs Phantoms and sprinting Night Hounds | — | fast, gliding |
| A+ | Starling Murmuration | a flock of starlings hunts the **3 fastest** nightmares in range at once | — | fast, gliding |
| B | Magpie Perch | nightmares it hits drop +1 Dew when dispelled | — | economy |
| B+ | Magpie's Hoard | **each crit it lands gives +1 Dew** (capped per drift) | — | crits |
| Hidden | Hummingbird Bower | **multi-hit**: a hummingbird pecks one nightmare **6 times in 1 s**, then returns. Every peck is a full hit (crit roll, Marked, on-hit effects) | — | crits, Marked, on-hit cards |
| Hidden+ | Jewelwing Court | 3 hummingbirds, 8 pecks each; **Flurry**: every 6th peck is a guaranteed crit | — | crits, Marked, on-hit cards |

Hummingbirds are weak against the Shellbound's dread shell (small pecks bounce off) and the Whisper
Swarm (single-target), and one peck uses up Pinned's ×3 crit. The *Needle Point* card fixes the
first.

**Whirligig line** *(full game)*: maple-seed spinners. An **amplifier** with no status of its own;
it makes every other family's statuses go further.

| Tier | Warden | Does | Applies | Loves |
|---|---|---|---|---|
| Base | Whirligig | gusts nudge nightmares back a little | — | — |
| A | Gust | copies the statuses of the most-afflicted nightmare in range onto 2 nearby ones (half stacks) | copied | any status |
| A+ | Zephyr | spreads to up to 5 | copied | any status |
| B | Pinwheel | spinning blades hit every path tile next to it; stronger the more path tiles it touches | — | corners, hairpin bends |
| B+ | Windmill | bigger, faster blades | — | hairpin bends |
| Hidden | Samara | **boomerang**: throws a spinning maple seed in a **straight line** (4 cells) that passes through everything and **flies back**, hitting each nightmare twice. It **carries the statuses** of the first nightmare it hits down the whole line and back. Can't throw again until it catches the seed | copied | **straight corridors**, slows |
| Hidden+ | Autumn Gale | **2 seeds** along the two lines with the most nightmares (5 cells); **catch rhythm**: each catch +10% damage on the next throw (max +50%, resets on a miss) | copied | straight corridors, attack speed |

Samara is the Warden that wants **straights**, which is where Night Hounds sprint. Building for it
means answering Hounds on the throwing line (Tangleroot, Honeysuckle).

**Thornwall**: cheap plain wall, no attack, always available. Two growths:
- **Bramble**: damages nightmares walking next to it; loves long walls and Held nightmares. Lets
  players build long mazes cheaply and enables maze-as-weapon builds.
- **Honeysuckle**: its sweet scent makes nightmares walking past it slowly Drowsy. Walls that set up
  combos instead of dealing damage.

### Memory Wardens (from bosses)

Each great nightmare wore a memory it stole from the dream. Dispelling it frees that memory as a
**unique Warden**. After a boss, the reward is **1 of 3 families *or* that boss's Memory Warden**
(once you've unlocked it, see `meta_design.md`). Memory Wardens are free, **one per run each**,
take 1 cell and can't evolve.

| Boss | Memory Warden | Does |
|---|---|---|
| The Hollow Stag | **The White Stag** | large aura (radius 4): nightmares in it are 15% slower and take +15% damage; Wardens in it +5% crit chance |
| The Mire Hag | **The Pond Keeper** (an old toad spirit) | every 4 s its tongue grabs the nightmare furthest along in range 3 and pulls it back beside the pond, Damp (bosses: back 2 tiles) |
| The Moth Queen | **The Moon Moth** | reveals every Lurker on the map; Wardens within 3 cells +1 range; long-range shots that Mark |

The Hollow Oak ends the run, so it has no Memory Warden (its memory is the true ending).

## Evolution rules

- **Dreamlight unlocks, Dew pays** (was "Dreams unlock"; changed 2026-09-27). Spending
  **Dreamlight** (earned from bosses, `run_design.md`) makes a branch or final form *available* this
  run; evolving a specific tower costs Dew. Branch 1 Dreamlight, final form 2.
- **Per tower:** each tower evolves separately (one Sprout can become a Stormcap, the next a Rain
  Lily).
- **In place:** evolving keeps the tower on its cell, so the path never changes.
- Once a base is unlocked it can also be **built directly** on a fresh cell, costing about the same
  as Sprout + evolution. Sprouts stay useful as placeholders: place now, decide later.
- Final forms need **2 Dreamlight** (and their branch unlocked) before Dew can evolve into them.

## Status effects

Towers interact **through the nightmare**: one Warden applies an effect, another gets a bonus
against it. Towers never reference each other, so every new tower combos automatically. Keep the
set small. (Nightmares that resist or exploit these: see `enemy_design.md`.)

| Effect | What it does | Applied by | Paid off by | Why it works |
|---|---|---|---|---|
| **Damp** | slight slow | Dewdrop line | Stormcap, Thunderhead | lightning jumps further and more often |
| **Drowsy** | strong slow, stacks to a cap | **Bellflower line**; also Bloomcap, Morning Fog, Honeysuckle | Mossback, Boulderback, Dreamshroom, Dreamcatcher, Sunpetal | crits, full sleep, Caught, faster beam ramp |
| **Spored** | damage over time, stacks | Sporeling, Driftspore, Fairy Ring | Puffball, Mistveil, Rootcurl, Long Way Home | bursts, harder ticks; pulled nightmares walk the spores again |
| **Marked** | takes extra damage | Lanternmoth, Beacon, Rootlight, Moon Moth | Mossback, Boulderback, Standing Stone | double damage on Marked |
| **Static** | builds charge; at 5 stacks, a free bolt | Firefly Jar, Stormcap, Chime Stone | Chime Stone, Lullaby Bell | pulses set off Static bolts |
| **Held** | can't move for a moment | Tangleroot, Snugroot, Frostfern (freeze) | Bloomcap, Mistveil, Chime Stone, Bramble, Sunpetal, Hoarfrost, Standing Stone, Cairn | held nightmares sit inside area effects and are easy targets |

Towers also interact **through placement** and **through Dreams** (rule changes that link lines).

## Reactions: combos you can see

Added 2026-09-27. The bonuses above are quiet: they make numbers bigger. **Reactions** are the
loud layer: when two specific statuses meet on one nightmare, a named event goes off with its own
effect, sound and callout. Every Reaction is **warm light breaking cold shadow**, the game's core
look. Any Warden can set one up (the rule that towers never reference each other still holds), and
the bigger the combo, the more of the screen fills with the Heartwood's light.

| Reaction | Statuses | What happens | Effect (`assets/effects/`) |
|---|---|---|---|
| **Thunderclap** | Damp + 3 Static | discharges and **arcs to every Damp nightmare within 2.5 cells**; each arc adds Static, so wet crowds chain | `thunderclap`, `thunderclap_arc` |
| **Ignite** | Spored + Static | all Spored stacks **detonate at once**; 1 stack spreads to neighbours (which may Ignite too) | `ignite` |
| **Mushrooming** | Spored + Damp | mushrooms burst out of the nightmare and leave a **spore cloud** on the tile that spreads Spored | `overgrowth`, `overgrowth_cloud` |
| **Shatter** | frozen/Held + Damp, then a crit or heavy hit | that hit does ×2.5 and ice shards splash nearby; the freeze ends | `shatter` |
| **Drown** | Damp + max Drowsy | falls asleep for 2 s, **no Dreamshroom needed** | `drown` |
| **Pinned** | Marked + (Held or max Drowsy) | the next hit is a **guaranteed ×3 crit** | `pinned` |
| **Smother** | Held + Spored | Spored ticks 3× as fast while Held | `smother` (loops) |
| **Lightning Rod** | Marked + Static | Static bolts nearby **redirect** to the Marked nightmare at ×2 | `lightning_rod` |

Numbers, cooldowns and boss rules: `dream_design.md` ("Reaction numbers").

**Which families make which Reactions** (a quick guide for family picks and Dream design):

| | Damp (Dewdrop) | Static (Firefly Jar, Chime Stone) | Spored (Sporeling) | Marked (Lanternmoth, Rootlight) | Held (Rootling, Frostfern) | Drowsy (Bellflower, Bloomcap) |
|---|---|---|---|---|---|---|
| **Damp** | | Thunderclap | Mushrooming | | Shatter | Drown |
| **Static** | | | Ignite | Lightning Rod | | |
| **Spored** | | | | | Smother | |
| **Marked** | | | | | Pinned | Pinned |

Damp is the most-connected status on purpose: Dewdrop is the "combo family" that makes other
families react. Whirligig's Gust spreads statuses, so it sets up Reactions across a whole group,
and Samara carries them down a whole corridor. Bellflower's Echo Hollow repeats Reactions, and
Hummingbird's pecks apply on-hit statuses six times per attack, so both families feed chains.

### Chains

Reactions can set off Reactions: Thunderclap arcs add Static to wet nightmares (more
Thunderclaps), Ignite spreads spores onto charged ones (more Ignites), Mushrooming clouds spread
Spored into Damp crowds. When a Reaction is caused by another within **1 s**, or a different
Reaction hits the same nightmare within 1 s, it's a **chain**:

- **Chain badge** over the latest Reaction: *×2, ×3, ×4…* with a rising chime (`chain_badge`,
  `chain_digits`).
- **×5**: a short hitstop and a warm colour surge over the screen (`surge`).
- **×10: Dawnburst.** A big radial flare (`dawnburst`), every Warden that took part flares, every
  nightmare dispelled in the chain cracks with extra light, and a short music stinger. This is the
  screenshot and trailer moment.
- Chains are tracked per run (longest chain, shown on the results screen).

### Final-form signatures

Final forms get one unmistakable moment each, so reaching one feels like a reward:

| Final form | Signature | Effect |
|---|---|---|
| Thunderhead | every 5th strike is a **bolt from the sky** with a screen flash | `thunderhead_strike` |
| Monsoon | a **sheet of rain** sweeps across its range | `monsoon_sweep` |
| Moonstone | its first shot on each nightmare is a **moonbeam from above** | `moonstone_beam` |
| Puffball | each pop is a **big bloom of light** | `puffball_bloom` |
| Long Way Home | you see the **roots drag** the nightmare back along the path | `long_way_home_drag` |

How Reactions are shown (impact tiers, light threads, discovery cards, settings): `screens_ui.md`,
"Combat feedback".

## Critical hits

Every attacking Warden has a **crit chance** and a **crit multiplier**. A crit is a hit that does
extra damage, with a bright flare, a bigger gold number and a sharp chime.

- **Defaults:** 5% chance, ×2 damage. Heavy-hit Wardens (Pebbling line, snipers) have more; area
  Wardens usually keep the default. Exact values per Warden: `warden_stats.md`.
- **What can crit:** Warden **attacks**: projectile hits, each chain jump, each pulse hit, each beam
  tick, trap bursts. Splash uses the main hit's roll.
- **What can't:** **statuses and ground effects**: Spored ticks, Static bolts, clouds, fog, Puffball
  pops. This keeps status builds and crit builds separate (Dreams can bridge them).
- **Guaranteed crits** exist as Warden rules (Boulderback on Drowsy, Moonstone's first hit) and roll
  no dice.
- **Cap:** crit chance caps at 100%. The Legendary *Full Moon* turns chance above 100% into extra
  crit damage.
- **Order:** `damage × crit × family resist/weak × attack shape × Marked`, then dread shell.
  Crits help break the Shellbound's shell, a small reason to bring them.
- **Shown** in the Warden tooltip (e.g. "Crit 20% · ×2.5"), with Dream bonuses included.

Crit synergies: **Held and sleeping nightmares** (Hoarfrost bonus, *Still Target* Dream), **Marked**
(*Starlit Aim*), **Magpie's Hoard** (Dew from crits), **White Stag** aura, and the crit cards in
`dream_design.md`.

## Target priority

Most Wardens target the nightmare **furthest along** the path. **Standing Stone and Moonstone** let
the player choose (click the Warden): *Furthest along* (default), *Strongest*, or *Bosses first*.
Only snipers get this, since that's where the choice matters most and it keeps everything else
simple.

## Maze and placement synergies

- **Long path:** Driftspore, Rootcurl, Bramble and Mistveil all get better the longer nightmares walk.
- **Clusters:** Elder Stump and Grove Heart want Wardens packed together, which competes with
  building a long maze for the same space. That trade-off is intentional.
- **Chokepoints:** Bloomcap clouds, Mistveil fog and Tangleroot want nightmares funnelled through a
  single tile.
- **Wall count:** Bramble builds want lots of cheap Thornwalls.
- **Distance:** Standing Stone and Moonstone want to be *far* from the path, deep in dead space inside
  the maze that no other Warden wants.
- **Straights vs bends:** Samara and Autumn Gale want long straight corridors to throw down (where
  Night Hounds sprint); Pinwheel and Windmill want hairpin bends wrapped around them. Everything
  else mostly wants bends.
- **Over the maze:** Cairn and Rockslide lob over walls, so they can sit anywhere and hit the
  densest bend, like snipers but for crowds.
- **Traps:** Fairy Ring rewards knowing exactly which tiles nightmares will step on.

## Build archetypes (targets for Dream design)

| Build | Wardens | Key Dream | How it plays |
|---|---|---|---|
| **Storm Grid** | Rain Lily/Monsoon + Stormcap/Thunderhead | *Conductive Soil* | soak the path, then Thunderclap chains race through the whole drift |
| **The Long Walk** | Thornwalls + Driftspore + Long Way Home | *The Long Walk* | huge maze, stacking damage over time, nightmares dragged back past it all |
| **Spore Bomb** | Puffball + Mistveil + Tangleroot | *Chain Bloom* (Puffball bursts set off each other) | hold nightmares in fog, stack spores, bursts cascade |
| **Sniper's Rest** | Beacon + Moonstone (+ Boulderback) | *Starlit Aim* | a few Wardens deep inside the maze, enormous crits; boss and Phantom killer |
| **Full Moon** | Moonstone + Hoarfrost + Magpie's Hoard | *Full Moon* | stack crit chance past 100%; freeze, crit, get paid |
| **Gale** | Gust/Zephyr + any status family | *Carried on the Wind* | one Warden applies it, the wind spreads it to the whole drift |
| **Fairy Mines** | Elf Circle + Honeysuckle + Tangleroot | *Ring Dance* | slow them onto the rings, hold them there, spores go off everywhere |
| **Hairpin Mill** | Windmill + Thornwalls + Cozy Corners | *Rootbound* | wrap tight switchbacks around each Windmill |
| **Sleepy Hollow** | Lullaby Bell + Great Dreamcatcher + Dreamshroom (+ Boulderback) | *Heavy Eyelids* (Drowsy cap +2) | sing them to sleep, catch them, and every hit lands harder; Dreamlight shards on the side |
| **Storm Corridor** | Rain Lily + Samara + Stormcap | *Windborne Rain* | the seed soaks a whole straight, then Thunderclaps chain down it |
| **Thousand Cuts** | Jewelwing Court + Firefly Jar/Rain Lily + Beacon | *Charged Feathers*, *Thousand Cuts* | every flurry charges a wet, marked nightmare into a Thunderclap |
| **Encore** | Whispering Hollow + any two Reaction families | *Quick Reactions* | every Reaction goes off twice; the easiest road to Dawnburst |
| **Rockfall** | Rockslide + Snugroot + Bloomcap | *Shattering Blow* | hold a crowd in a sleepy cloud and drop stones on it |
| **Thunder Chimes** | Stormcap + Chime Stone | *Resonance* (pulses count as lightning) | Static bolts go off constantly |
| **Bramble Maze** | mostly Thornwalls (Bramble) + Snugroot | *Thornheart* (+damage per wall) | the maze itself is the weapon |
| **The Grove** | Grove Heart surrounded by any Wardens | *Rootbound* | one tight fortress at a chokepoint |
| **Greedy Gardener** | Dewcatcher → Wellspring early, then anything | *Overflowing Well* | weak early, strongest by far late |

Every tower must be useful alone; combos are the payoff, not a requirement.

## Open questions for the new Wardens

- **Resistances:** Nestling (`wing`) and Whirligig (`wind`) need resist/weak entries in
  `enemy_design.md` before they're built, keeping the family tally even (Phantoms and Night Hounds
  are natural *weak to wing* candidates, but each already has a weakness, so this needs a pass).
- **Reachability:** 8 families lowers the odds of drafting a specific pair (Storm Grid). Since
  Nestling and Whirligig are Grove unlocks, early runs are unaffected; re-run the Dream simulation
  once they exist. An option is a Grove perk to *leave a family out* of your picks.
- **Gust / Zephyr strength:** copying statuses multiplies every other family. Watch it with
  Spored and Static in particular; half stacks is the starting guard.
- **Graftling copying a Memory Warden or another Graftling:** not allowed (copies attacking,
  non-unique Wardens only).
- **Bellflower resistances:** done in `enemy_design.md` (f45cee0). *Weak to song*: Sleepwalker,
  Gravecrawler, Widow. *Resist song*: Watcher (the natural counter to Bellflower builds), Drowned
  One, Hollow Oak. Chime Stone and Lullaby Bell change line from `stone` to `song`.
- **Migration (for the code chats):** Chime Stone and Lullaby Bell move to Bellflower; Standing
  Stone and Moonstone stop being hidden (`hidden = false`); Starling Murmuration's behaviour
  changes from sweep to "hunt the 3 fastest". Art exists for all of these; new art is needed for
  Bellflower, Dreamcatcher, Great Dreamcatcher, Echo Hollow, Whispering Hollow, Cairn, Rockslide,
  Hummingbird Bower, Jewelwing Court, Samara and Autumn Gale.
- **9 families, 4 per run:** reachability for a specific pair drops. The Grove unlocks families
  gradually, so a new player sees 3, and *Early Bloom* shows all unlocked families at the first
  pick. Re-run the Dream/family simulation once Bellflower exists.

## First playable scope

Sprout, Thornwall, Sporeling, Firefly Jar, Dewdrop; 2 branches each; one final form
(Thunderhead) to test the Rare-Dream unlock. Enough to prove Storm Grid end to end. Then
Pebbling and Rootling; Acorn last (support/economy is easier to balance once damage lines exist).

Art budget: final forms can reuse the branch sprite with additions (bigger, glowing, flowering).

## Data

`TowerData` resources (cost, range, damage, attack speed, texture, **tags**, **attack
behavior**: projectile / chain / beam / pulse / trap / lob (Cairn) / boomerang (Samara) /
multi-hit (Hummingbird) / catch (Dreamcatcher) / echo (Echo Hollow) / none, `evolves_to: Array[TowerData]`,
`crit_chance: float = 0.05`, `crit_multiplier: float = 2.0`, `min_range: float = 0.0`,
`has_target_priority: bool`, `is_unique: bool` for Memory Wardens, `hidden: bool` for Grove-gated
branches). Crits are rolled by the Warden and passed on:
`Enemy.take_damage(amount, line, is_area, is_crit)` so the enemy can show the crit flare.
`StatusEffect` resources (id, duration, max stacks) + a status handler on `Enemy`.
`ReactionData` resources (id, the two statuses + thresholds, which it consumes, effect id from
`assets/effects/effects.json`, callout text and colour, cooldown, boss rule), checked by the
status handler whenever a status is added, so a new Reaction is mostly data. A small
`ChainTracker` (in the run) counts Reactions caused by Reactions within 1 s.
