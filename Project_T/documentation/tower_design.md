# Tower Design — Wardens

Overview and run loop: see `game_design.md`. Enemies: see `enemy_design.md`. Story: `story.md`.

Design pillar: **towers are walls, so builds should care about the maze**: path length,
adjacency, corners, wall count. That's what no other tower defense roguelite can do.

## Evolution tree

Every run starts with only the **Sprout** (plus Thornwall). Sprouts grow into the base Wardens
(6 families, 8 in the full game),
bases grow into branches, branches into final forms. **Base families come from family picks**
(after drift 1 and from the bosses at 25, 50, 75; 4 per run, see `run_design.md`); branches and
final forms come from Dreams.

```
								SPROUT (weak spore puffs)
   ┌────────────┬────────────┬──────┴─────┬────────────┬────────────┐
Sporeling    Pebbling     Dewdrop     Firefly Jar   Rootling      Acorn        ← family picks
 (2 branches each, then a final form per branch — see table)                   ← Dew / Rare Dreams
```

| Base | Identity | Branch A → final | Branch B → final | Hidden branch → final |
|---|---|---|---|---|
| **Sporeling** | damage over time | Driftspore → Puffball | Bloomcap → Dreamshroom | Fairy Ring → Elf Circle |
| **Pebbling** | heavy hits | Mossback → Boulderback | Chime Stone → Lullaby Bell | Standing Stone → Moonstone |
| **Dewdrop** | water, splash | Rain Lily → Monsoon | Mistveil → Morning Fog | Frostfern → Hoarfrost |
| **Firefly Jar** | light and spark | Stormcap → Thunderhead | Lanternmoth → Beacon | Sunpetal → Midsummer |
| **Rootling** | crowd control | Rootcurl → Long Way Home | Tangleroot → Snugroot | Rootlight → Starcave |
| **Acorn** | support, economy | Elder Stump → Grove Heart | Dewcatcher → Wellspring | Graftling → Grafted Elder |
| **Nestling** *(full game)* | birds: mobile, fast | Wren's Nest → Starling Murmuration | Magpie Perch → Magpie's Hoard | — |
| **Whirligig** *(full game)* | wind: spreads statuses | Gust → Zephyr | Pinwheel → Windmill | — |

- **Hidden branches** are Memory Grove unlocks (Sunpetal from a milestone). Once unlocked they join
  the Dream pool like any branch. Each one opens a *different playstyle* for its family, not a
  stronger version of an existing branch.
- **Nestling and Whirligig** are Grove unlocks for the full game (not in the demo). A run still
  gets **4 families**; more families means more variety between runs.
- **Memory Wardens** (below) are unique Wardens freed from the act bosses.

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

**Pebbling line**

| Tier | Warden | Does | Applies | Loves |
|---|---|---|---|---|
| Base | Pebbling | slow, heavy pebble | — | Marked |
| A | Mossback | huge single hit, short range; double damage vs Marked | — | Marked, Drowsy |
| A+ | Boulderback | hit splashes to nearby tiles; guaranteed crit on Drowsy | — | Marked, Drowsy |
| B | Chime Stone | weak pulse hitting everything around it; pulses set off Static | Static ×1 | Static, Held |
| B+ | Lullaby Bell | bigger pulse that also applies Drowsy | Drowsy | Static, Held |
| Hidden | Standing Stone | **sniper**: range 8, one slow heavy shot; more damage the further the target; can't hit nightmares right beside it (minimum range 2) | — | distance, Marked, Held |
| Hidden+ | Moonstone | range 10; its **first hit on each nightmare is always a crit** | — | distance, Marked, Held |

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
| A+ | Starling Murmuration | a flock sweeps a stretch of path, hitting everything on it | — | long straights |
| B | Magpie Perch | nightmares it hits drop +1 Dew when dispelled | — | economy |
| B+ | Magpie's Hoard | **each crit it lands gives +1 Dew** (capped per drift) | — | crits |

**Whirligig line** *(full game)*: maple-seed spinners. An **amplifier** with no status of its own;
it makes every other family's statuses go further.

| Tier | Warden | Does | Applies | Loves |
|---|---|---|---|---|
| Base | Whirligig | gusts nudge nightmares back a little | — | — |
| A | Gust | copies the statuses of the most-afflicted nightmare in range onto 2 nearby ones (half stacks) | copied | any status |
| A+ | Zephyr | spreads to up to 5 | copied | any status |
| B | Pinwheel | spinning blades hit every path tile next to it; stronger the more path tiles it touches | — | corners, hairpin bends |
| B+ | Windmill | bigger, faster blades | — | hairpin bends |

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
| **Drowsy** | strong slow, stacks to a cap | Bloomcap, Lullaby Bell, Morning Fog | Mossback, Boulderback, Dreamshroom, Sunpetal | crits, full sleep, faster beam ramp |
| **Spored** | damage over time, stacks | Sporeling, Driftspore, Fairy Ring | Puffball, Mistveil, Rootcurl, Long Way Home | bursts, harder ticks; pulled nightmares walk the spores again |
| **Marked** | takes extra damage | Lanternmoth, Beacon, Rootlight, Moon Moth | Mossback, Boulderback, Standing Stone | double damage on Marked |
| **Static** | builds charge; at 5 stacks, a free bolt | Firefly Jar, Stormcap, Chime Stone | Chime Stone, Lullaby Bell | pulses set off Static bolts |
| **Held** | can't move for a moment | Tangleroot, Snugroot, Frostfern (freeze) | Bloomcap, Mistveil, Chime Stone, Bramble, Sunpetal, Hoarfrost, Standing Stone | held nightmares sit inside area effects and are easy targets |

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

| | Damp (Dewdrop) | Static (Firefly Jar, Chime Stone) | Spored (Sporeling) | Marked (Lanternmoth, Rootlight) | Held (Rootling, Frostfern) | Drowsy (Bloomcap, Lullaby Bell) |
|---|---|---|---|---|---|---|
| **Damp** | | Thunderclap | Mushrooming | | Shatter | Drown |
| **Static** | | | Ignite | Lightning Rod | | |
| **Spored** | | | | | Smother | |
| **Marked** | | | | | Pinned | Pinned |

Damp is the most-connected status on purpose: Dewdrop is the "combo family" that makes other
families react. Whirligig's Gust spreads statuses, so it sets up Reactions across a whole group.

### Chains

Reactions can set off Reactions: Thunderclap arcs add Static to wet nightmares (more
Thunderclaps), Ignite spreads spores onto charged ones (more Ignites), Mushrooming clouds spread
Spored into Damp crowds. When a Reaction is caused by another within **1 s**, it's a **chain**:

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
- **Straights vs bends:** Starling Murmuration wants long straight stretches; Pinwheel and Windmill
  want hairpin bends wrapped around them. Everything else mostly wants bends.
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
| **Sleepy Hollow** | Lullaby Bell + Morning Fog + Dreamshroom (+ Sunpetal) | *Heavy Eyelids* (Drowsy cap +2) | nothing ever wakes up |
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

## First playable scope

Sprout, Thornwall, Sporeling, Firefly Jar, Dewdrop; 2 branches each; one final form
(Thunderhead) to test the Rare-Dream unlock. Enough to prove Storm Grid end to end. Then
Pebbling and Rootling; Acorn last (support/economy is easier to balance once damage lines exist).

Art budget: final forms can reuse the branch sprite with additions (bigger, glowing, flowering).

## Data

`TowerData` resources (cost, range, damage, attack speed, texture, **tags**, **attack
behavior**: projectile / chain / beam / pulse / trap / none, `evolves_to: Array[TowerData]`,
`crit_chance: float = 0.05`, `crit_multiplier: float = 2.0`, `min_range: float = 0.0`,
`has_target_priority: bool`, `is_unique: bool` for Memory Wardens, `hidden: bool` for Grove-gated
branches). Crits are rolled by the Warden and passed on:
`Enemy.take_damage(amount, line, is_area, is_crit)` so the enemy can show the crit flare.
`StatusEffect` resources (id, duration, max stacks) + a status handler on `Enemy`.
`ReactionData` resources (id, the two statuses + thresholds, which it consumes, effect id from
`assets/effects/effects.json`, callout text and colour, cooldown, boss rule), checked by the
status handler whenever a status is added, so a new Reaction is mostly data. A small
`ChainTracker` (in the run) counts Reactions caused by Reactions within 1 s.
