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
| **Dewdrop** | water: splash, fog, ice; the conductor | Damp | Rain Lily → Monsoon | Mistveil → Morning Fog | Frostfern → Hoarfrost |
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
- **Memory Wardens** (below) are **parked** (cut for now, 2026-09-29).
- **Ascended forms** (below): each family's endgame Warden, a 4th tier above the final forms.

### Ascended forms: each family's endgame Warden

Added 2026-09-27 (user request: late game felt easy; wanted an endgame Warden per family). An
Ascended Warden is the family's final word: a huge, unique presence that anchors a late maze.

- **When:** from **drift 51** (act 3). **Unlock:** **3 Dreamlight** (bosses now give 4 each, 2026-09-29, so a run that reaches act 3 can afford one) on the Remember screen, once
  that family has any final form unlocked. **Grow:** from **any final form** of that family, for
  **400 Dew** (the Warden keeps its rank and Focus).
- **One per family per run** (at most 4 in a run, one per family you own). Unique like Memory
  Wardens.
- **Power:** about **5× an average final form in total** (revised 2026-09-28: it now takes 4 cells; the act 3 probe measured The Great Bell at ~7×), plus a family-wide effect. Nurture costs × 4.
- **Size: 2×2 cells** (decided 2026-09-28; playtest: the art is ~2×2 but the Warden took 1 cell, so
  it spilled over its neighbours and the path). Growing into an Ascended form needs room:
  - It takes one of the **four 2×2 squares** that include the Warden's cell. The other 3 cells
    must be **empty buildable ground or your own Thornwalls** (they're absorbed; their Dew is
    refunded in full), never another Warden, an obstacle, the path's start / end or a nightmare's
    cell, and the path rule must still hold (a 2×2 wall is a real maze decision).
  - Pressing Grow shows the valid squares as ghosts (with the route preview for each); tap one to
    confirm. With only one valid square it's preselected.
  - No valid square: the button is disabled with *"Needs room: 3 free cells next to it (2×2)"*.
  - Range and auras are measured from the centre of the 2×2. Selling frees all 4 cells.
  - Reuses the Sapling's footprint support (`footprint` 2, `Tower.get_cells()`, `can_block_cells`).
- **Memory Grove:** each family's limb gets an **Ascension** node above its hidden branch
  (`meta_design.md`); until it's planted the Ascended form shows *"Memory Grove"*.

| Family | Ascended Warden | What it does |
|---|---|---|
| Sporeling | **Sporemother** | a constant spore storm (range 3): every nightmare in it gains 2 Spored per second; any that reach 10 stacks pop like a Puffball |
| Dewdrop | **Tidecaller** | every 6 s a tide rolls along the path in range 4: heavy damage, Damp, and it washes nightmares **back 1 tile** |
| Firefly Jar | **Stormheart** | lightning chains to **every** nightmare in range 4 (each jump −15%), adding 2 Static each |
| Pebbling | **Old Mountain** | every 3 s a boulder crushes a 3×3 area, Holding what it hits for 0.5 s; guaranteed crits on Held or Drowsy nightmares |
| Rootling | **World Root** | every 5 s, roots Hold **every** nightmare in range 3 for 1 s; Held nightmares take +30% damage from everything |
| Bellflower | **The Great Bell** | every 6 s it tolls (range 5): full Drowsy on everything (bosses: 3), and every Static charge in range goes off |
| Acorn | **Grandmother Oak** | aura radius 3: Wardens +40% damage and +20% attack speed; +10 Dew per drift |
| Nestling | **Dawnwing** | a great bird circles a long stretch of the path, striking everything it passes; faster the more nightmares there are |
| Whirligig | **The Whirlwind** | a slow cyclone drifts along the path, carrying every status it touches to every nightmare it passes |

Art: large (a 64 px base with the spirit rising above it, like the bosses' scale), a unique idle
glow; one per family.

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
| B | Mistveil | fog on path tiles: keeps nightmares Damp; Spored ticks harder in fog | Damp | Spored, Held |
| B+ | Morning Fog | fog covers a longer stretch of path; Damp from it lingers 3 s after leaving, and Spored and Static tick +25% inside | Damp | Spored, Static, Held |
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
| Base | Rootling | roots nip at feet: every 4th pulse Holds the nightmare furthest along for 0.3 s (weak damage: a control family) | Held | long paths |
| A | Rootcurl | pulls a nightmare back 1 tile every few seconds | — | Spored, long paths |
| A+ | Long Way Home | pulls back 3 tiles; can't pull the same nightmare twice | — | Spored, long paths |
| B | Tangleroot | holds a nightmare in place for 1 s | Held | area effects |
| B+ | Snugroot | holds up to 3 nightmares at once | Held | area effects |
| Hidden | Rootlight | glowing roots light up path tiles in range: **reveals Lurkers**, **Gravecrawlers can't burrow** there, and **Held lasts 50% longer** on lit tiles | — | Held, long paths |
| Hidden+ | Starcave | bigger lit area; Held lasts **twice as long** on lit tiles | — | Held, long paths |

**Pulls are a drag you can see, not a teleport** (2026-09-30, user: "make it clear when Rootcurl
knocks the enemy back; not teleport back"). Every pull-back (Rootcurl, Long Way Home, the Snare
Kinship's half-tile drag, the Tidecaller's wave) plays in three beats:
1. **Grab** (~0.15 s): roots burst from the ground and wrap the nightmare's feet, timed with the
   Warden's pull animation.
2. **Drag** (~0.45 s for 1 tile, ~0.8 s for 3): the nightmare **slides backward along its route**,
   fast at first then settling, still facing forward with its feet scraping and a small struggle
   wobble. Soil puffs kick up along the way and a **furrow** is left on the path, fading over ~1 s.
3. **Release:** the roots sink back and it walks on.
- During the drag it can't move forward but can still be hit and targeted. The distance pulled is
  unchanged; the drag only replaces the instant jump.
- Bosses: the shorter pull drags slower and heavier (the roots strain).
- With reduced motion, the drag is shortened to ~0.2 s and the soil puffs are dropped; the furrow stays.

**Bellflower line**: song and sleep. Bell-flower spirits that ring, hum and sing nightmares to
sleep, then make sleep dangerous. Owns **Drowsy**.

| Tier | Warden | Does | Applies | Loves |
|---|---|---|---|---|
| Base | Bellflower | a soft ringing pulse around it; every 2nd pulse adds Drowsy | Drowsy | chokepoints |
| A | Chime Stone | weak pulse hitting everything around it; pulses set off Static | Static ×1 | Static, Held |
| A+ | Lullaby Bell | bigger pulse that also applies Drowsy | Drowsy | Static, Held |
| B | Dreamcatcher | hangs a dreamcatcher over the path: **sleeping or max-Drowsy nightmares in range are Caught**: **their statuses stop wearing off** while Caught (Spored keeps ticking, Static doesn't decay, Damp / Marked / Held timers pause). *Reworked 2026-09-29 (overlap review): it was +25–60% damage taken, which duplicated Marked, and measured at 1.5% of damage.* | — | Drowsy, sleep, any status |
| B+ | Great Dreamcatcher | a bigger range, and Caught statuses also tick **+25%**; sleep in its range lasts 1 s longer; Caught nightmares that are dispelled drop **Dreamlight shards** | — | Drowsy, sleep |
| Hidden | Echo Hollow | a hollow log that **echoes Reactions**: a Reaction nearby repeats 1 s later at 50% | — | Reactions |
| Hidden+ | Whispering Hollow | 75%, bigger radius; **echoes count as chain links** | — | Reactions, chains |

**Acorn line**

| Tier | Warden | Does | Applies | Loves |
|---|---|---|---|---|
| Base | Acorn | +5% damage to adjacent Wardens | — | neighbours |
| A | Elder Stump | adjacent Wardens attack 20% faster | — | tight clusters |
| A+ | Grove Heart | radius 2; bonus grows per nearby Warden | — | tight clusters |
| B | Dewcatcher | **catches Dew:** nightmares dispelled nearby drop +40% Dew (plus a little each drift); place it where the most nightmares die | — | kill zones, bends |
| B+ | Wellspring | a bigger catch (+60%), and interest on saved Dew at every rest | — | kill zones, saving Dew |
| Hidden | Graftling | **copies the attack of its strongest adjacent Warden** at 60% (including its statuses) | copied | clusters |
| Hidden+ | Grafted Elder | copies at 85% | copied | clusters |

**Nestling line** *(full game)*: birds that swoop out and back. The family for fast and
wall-ignoring nightmares.

| Tier | Warden | Does | Applies | Loves |
|---|---|---|---|---|
| Base | Nestling | a bird swoops at a nightmare and returns | — | fast nightmares |
| A | Wren's Nest | quick wrens hunt the **fastest** nightmare in range; bonus vs Phantoms and sprinting Night Hounds | — | fast, gliding |
| A+ | Starling Murmuration | a flock of starlings hunts the **3 fastest** nightmares in range at once | — | fast, gliding |
| B | Magpie Perch | **thief**: hits strip nightmare buffs: a double chunk of dread shell, a Weeper's mending stops for 3 s, an Omen's boosts are removed from that nightmare; +1 Dew when a nightmare it stripped is dispelled | — | support nightmares |
| B+ | Magpie's Hoard | steals harder: every hit strips, and **each crit it lands gives +1 Dew** (capped per drift) | — | crits, support nightmares |
| Hidden | Hummingbird Bower | **multi-hit**: a hummingbird pecks one nightmare **6 times in 1 s**, then returns. Every peck is a full hit (crit roll, Marked, on-hit effects) | — | crits, Marked, on-hit cards |
| Hidden+ | Jewelwing Court | 3 hummingbirds, 8 pecks each; **Flurry**: every 6th peck is a guaranteed crit | — | crits, Marked, on-hit cards |

Hummingbirds are weak against the Shellbound's dread shell (small pecks bounce off) and the Whisper
Swarm (single-target), and one peck uses up Pinned's ×3 crit. The *Needle Point* card fixes the
first.

**Whirligig line** *(full game)*: maple-seed spinners. An **amplifier** with no status of its own;
it makes every other family's statuses go further.

| Tier | Warden | Does | Applies | Loves |
|---|---|---|---|---|
| Base | Whirligig | every 3 s copies one status (half stacks) from the most-afflicted nightmare in range onto one neighbour | copied | any status |
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

### Memory Wardens (from bosses): PARKED

> **Parked (2026-09-29, user decision): Memory Wardens are cut for now** and may return later. They
> overlapped with the family pick (both were the boss reward) and, being free, involved no decision.
> Nothing here is in the game: no Memory Warden card in the family pick, no Grove bloom. The design,
> art and code stay so they can come back (a proposed return: a separate "patch a gap" Warden
> costing 1 Dreamlight + Dew, not part of the family pick). The boss reward is the family pick +
> Dreamlight.

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
| **Damp** | **Soaked**: no slow. Water (Dewdrop-family) hits +20%, and it **conducts**: lightning jumps further, ice freezes, spores sprout | Dewdrop line | Dewdrop line, Stormcap, Thunderhead, Frostfern | the conductor for Thunderclap, Shatter, Mushrooming and Drown |
| **Drowsy** | **the slow**: stacks to a cap, and full Drowsy leads to sleep | **Bellflower line**; also Bloomcap, Honeysuckle | Mossback, Boulderback, Dreamshroom, Dreamcatcher, Sunpetal | crits, full sleep, Caught, faster beam ramp |
| **Spored** | damage over time, stacks | Sporeling, Driftspore, Fairy Ring | Puffball, Mistveil, Rootcurl, Long Way Home | bursts, harder ticks; pulled nightmares walk the spores again |
| **Marked** | **exposed**: the only "takes extra damage" status | Lanternmoth, Beacon | Mossback, Boulderback, Standing Stone | double damage on Marked |
| **Static** | builds charge; at 5 stacks, a free bolt | Firefly Jar, Stormcap, Chime Stone | Chime Stone, Lullaby Bell | pulses set off Static bolts |
| **Held** | **stopped**: can't move, short and firm (nothing breaks it) | Tangleroot, Snugroot, Frostfern (freeze) | Bloomcap, Mistveil, Chime Stone, Bramble, Sunpetal, Hoarfrost, Standing Stone, Cairn | held nightmares sit inside area effects and are easy targets |

Towers also interact **through placement** and **through Dreams** (rule changes that link lines).

### Spores don't pop (2026-09-30)

User: *"spores shouldn't pop, they should just stack poison; [popping and poison] fill similar
roles."* Poisoned (the old Spored) is the Sporeling family's one job: **stack it, keep it, spread
it**. No burst at a stack count anywhere:
- **Puffball** (final): its puff **bursts on landing over 1 tile**, giving **2 Poisoned to every
  nightmare there**, and nightmares it hits can hold **16 Poisoned** (the usual cap is 8, Driftspore
  12). The area poisoner, next to Driftspore's single-target stacking. No pop.
- **Sporemother** (Ascended): her storm gives 2 Poisoned per second to everything in range, and
  **Poisoned never wears off while a nightmare is in her range**. No pop.
- **Chain Bloom** (Entwined Puffball + Mistveil) is reworked: *"Puffball's puffs cover 2 tiles
  inside Mistveil's fog."* (Roguelite rewrites the card.)
- "Popped!" callouts and the pop effect go; Fever Dream and Ignite stay as they are (sleep and burn,
  not pops). The Spore Bomb build becomes stack-and-fog (Tower Discussion renames it).

### Slow and sleep have limits (2026-10-01)

User, a fresh-profile run at drift 28: *"builds feel super strong already with a new profile, slowing them by a lot as well"* (Bloomcap clouds, Drowsy stacks, Honeysuckles: nightmares crawled or slept through the maze). Rules:
- **Combined slow floor:** however many slows stack (Drowsy, Soaked + Frostfern, Heavy Air, rubble, fog, Omens), a nightmare never moves slower than **50% of its speed** (bosses **70%**, elites **60%**). Held / Rooted (a full stop) and Asleep are separate.
- **Sleep has a cooldown:** after a nightmare wakes up it can't fall **Asleep** again for **4 s** (bosses 8 s); Drowsy stacks still build meanwhile. Shown as a faint "awake" ring.
- **Hold has a cooldown too:** after a hold ends, 1.5 s before it can be Held again (bosses 3 s).
- The status badges and the nightmare info show the floor ("Slowed to the limit").

### Status jobs (overlap review, 2026-09-29)

Several statuses and Wardens did the same thing (many slows, four kinds of "takes more damage",
Asleep and Held both "stops"). After this review **each status has one job**:

| Status | Job | Owner |
|---|---|---|
| **Damp** | conducts (and water hits +20%) | Dewdrop |
| **Drowsy** | slows, and leads to sleep | Bellflower |
| **Spored** | poisons | Sporeling |
| **Static** | charges | Firefly Jar |
| **Marked** | exposes (the only +damage-taken status) | Firefly Jar |
| **Held** | stops, short and firm | Rootling |
| **Asleep** | stops, long but fragile: **breaks when a single hit deals 10%+ of max health** (effect ticks don't break it) | Dreamshroom, Fever Dream |
| **Caught** | preserves: statuses stop wearing off | Dreamcatcher |

- **Slowing belongs to Drowsy.** Damp, Mistveil's fog and Rootling's nip no longer slow. Exceptions
  that stay on purpose: Drown's pull-under, rubble (terrain), the White Stag (a Memory Warden).
- **Pulling back belongs to Rootling.** Whirligig's base copies a status instead of nudging; the
  *Heavy Seed* card became a double-strength return pass. The Pond Keeper and Tidecaller stay
  (a unique Warden and an Ascended form may overlap).
- **Spore bursts:** Puffball's pop is *the* burst. Ignite now **burns** (faster ticks and spread),
  and Fever Dream **puts to sleep and spreads** instead of detonating.
- **Sleep vs Drown:** Dreamshroom owns sleep (3 s, breaks on big hits); Drown is **pulled under**
  (a heavy slow plus drowning damage).
- **Marked belongs to Firefly Jar:** Rootlight is now the Held and burrower specialist.
- **Magpies became thieves** of nightmare buffs (shell, mending, Omen boosts), so Nestling doesn't
  copy Acorn's economy.
- **Support and control base pulses** (Acorn, Rootling) deal half damage, so those families don't
  read as weak attackers. Morning Fog no longer applies Drowsy (that blurred Dewdrop into
  Bellflower). Old Mountain's stun is now Held.
- Fine by design, unchanged: Crowned Reactions are bigger versions of their base Reaction, Ascended
  forms do their family's job at map scale, and a Kinship may recreate a Reaction.

**Damp alone is still strong:** Dewdrop has the best base damage (18/s, splash), and the +20%
water bonus on Damp makes it about 21.6/s against groups: the best early answer to swarms (Sobs,
Creeps, Wraiths). Control returns late through Frostfern and the Tidecaller. Watch Dewdrop's pick
rate.

## Reactions: combos you can see

**Reactions need a grown Warden** (2026-09-30, user: the starting three discovered all 7 of their
combos and a Crowned Reaction in the first run with base Wardens; *"shouldn't be able to unlock that
many"*). A Reaction fires only when **at least one of its two statuses was applied by a branch or
final form** (tier 2+). Base Wardens still apply their statuses (Soaked still slows, Charged still
bolts), they just don't react on their own. So a fresh run discovers combos as it grows Wardens, over
several runs. Crowned Reactions follow their base Reaction (so also need a grown Warden). Kinships
already need two branches. Codex hints stay "???".

Added 2026-09-27. The bonuses above are quiet: they make numbers bigger. **Reactions** are the
loud layer: when two specific statuses meet on one nightmare, a named event goes off with its own
effect, sound and callout. Every Reaction is **warm light breaking cold shadow**, the game's core
look. Any Warden can set one up (the rule that towers never reference each other still holds), and
the bigger the combo, the more of the screen fills with the Heartwood's light.

| Reaction | Statuses | What happens | Effect (`assets/effects/`) |
|---|---|---|---|
| **Thunderclap** | Damp + 3 Static | discharges and **arcs to every Damp nightmare within 2.5 cells**; each arc adds Static, so wet crowds chain | `thunderclap`, `thunderclap_arc` |
| **Ignite** | Spored + Static | the spores **burn** for 3 s: Spored ticks 3× as fast, and a stack spreads to each neighbour every second (which may start burning too). Puffball's pop is the burst; Ignite is acceleration | `ignite` |
| **Mushrooming** | Spored + Damp | mushrooms burst out of the nightmare and leave a **spore cloud** on the tile that spreads Spored | `overgrowth`, `overgrowth_cloud` |
| **Shatter** | frozen/Held + Damp, then a crit or heavy hit | that hit does ×2.5 and ice shards splash nearby; the freeze ends | `shatter` |
| **Drown** | Damp + max Drowsy | **pulled under** for 3 s: −60% speed and drowning damage that grows each second (no sleep: Dreamshroom owns sleep) | `drown` |
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

**Chain falloff** (2026-09-30, user: *"everything was good until mid act 2 in terms of difficulty"*; their drift 68 screenshot showed **Chain 120** and nightmares dying at the very start of a long maze): from the **6th link** of a chain, each Reaction in it deals **15% less** than the one before (links 1–5 full; 6th ×0.85, 7th ×0.70 …), **never below 25%**. Short chains keep their full punch; a hundred-link chain stops wiping a drift on its own. Chain *counts*, discoveries and Dawnbreak still count every link. If acts 2–4 are still easy after this, the health curve steepens from drift 38 (act 2 to ×3.0, acts 3–4 to ×4.5), never before.
Reactions can set off Reactions: Thunderclap arcs add Static to wet nightmares (more
Thunderclaps), Ignite spreads spores onto charged ones (more Ignites), Mushrooming clouds spread
Spored into Damp crowds. When a Reaction is caused by another within **1 s**, or a different
Reaction hits the same nightmare within 1 s, it's a **chain**:

- **Chain badge** over the latest Reaction: *"Chain 2", "Chain 3"…* with a small chain-link icon and
  a warm swell that builds link by link, fuller and never higher, no rising chime (audio_direction.md "Chains") (`chain_badge`, `chain_digits`). **Never "×N"**: "×" means a damage multiplier
  everywhere else (crit ×2, Pinned ×3), and a playtest read "×5" as five times the damage. A chain
  count is a celebration, not a multiplier; only the *Dawnbreak* card turns it into damage.
- **First chain ever:** a one-time whisper, *"One reaction set off another: a chain. Reach 10 for a
  Dawnburst."*, and the Codex entry "Chain" unlocks its details.
- **Chain 5**: a short hitstop and a warm colour surge over the screen (`surge`).
- **Chain 10: Dawnburst.** A big radial flare (`dawnburst`), every Warden that took part flares, every
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

**Signature twists for the other finals** (added 2026-09-30, user: "do all the Wardens feel fleshed
out and unique?"). Only 5 of 27 finals had a signature; the rest were "more of the same" (more
targets, more rings, a higher %), which doesn't feel worth ~310 Dew and 2 Dreamlight. Each flat
final now gets a **small new rule plus a visible moment**, inside its family's job. Finals that
already had a twist keep it: Rockslide (rubble), Jewelwing Court (Flurry), Autumn Gale (catch
rhythm), Magpie's Hoard (crit Dew), Whispering Hollow (echoes as chain links), Wellspring (the
Harvest), Grove Heart (grows per Warden). Numbers are starting points.

| Final | Twist | Rule | Visible moment |
|---|---|---|---|
| **Snugroot** | **Logjam** | a nightmare it Holds **blocks the path cell** for the Hold: nightmares behind it stop and queue (they don't path around; the route is unchanged), bunching a crowd for area damage. Flyers and Phantoms ignore it; bosses aren't Held long enough to jam | the queue visibly bunches; a small root knot under the held one |
| **Dreamshroom** | **Dream spores** | an **asleep** nightmare breathes out spores: **1 Spored per second** to nightmares within 1 cell (the sleeper's applier's Potency) | slow violet spore puffs rise from sleepers |
| **Boulderback** | **Landslide** | every **4th hit** rolls a boulder **2 tiles along the path** from the target (toward the start), hitting everything it passes for 60% of the hit | a rolling boulder with a dust trail |
| **Lullaby Bell** | **Chorus** | its pulse is **+10% per other Bellflower-family Warden within 3 cells** (max +40%) | its pulse ring shimmers with a note for each voice in the chorus |
| **Morning Fog** | **Veil** | nothing inside its fog can **hide** (Lurkers are revealed) or be **healed** (a Weeper's mending does nothing there) | the fog glows faintly gold where it cancels something |
| **Hoarfrost** | **Shatter chain** | a **frozen** nightmare that's dispelled bursts into shards that **freeze** nightmares within 1 cell for **0.5 s** (shard-frozen nightmares don't chain again) | an ice burst with shards flying out |
| **Beacon** | **Flare** | every **8 s** a flare reveals the **whole map** for 2 s and **Marks the 5 nightmares furthest along**, anywhere | a flare arcs up from the Beacon and lights the map |
| **Midsummer** | **Solstice** | at **full ramp** the beam **splits onto a second target** for 2 s (it keeps its ramp) | the beam forks with a bright flash |
| **Starcave** | **Starlit snare** | each lit tile **Holds the first nightmare to step on it each drift** for 0.5 s | a star-glint pops on the tile |
| **Great Dreamcatcher** | **Mended leaves** | every **25** Caught nightmares dispelled **restores 1 leaf** (max **3 per run**; the only leaf healing outside act breaks). If that's too strong: shards count double instead | a leaf drifts from the dreamcatcher to the Heartwood |
| **Grafted Elder** | **Double graft** | copies its **two** strongest neighbours and **alternates** between their attacks | its graft glows in the two borrowed colours, swapping |
| **Starling Murmuration** | **Dark swirl** | every **6 s** the flock forms a swirl (1 cell) over the busiest path tile for 2 s; **Phantoms gliding through it are swept up: a 0.5 s pause** (once each; a non-status pause, since Phantoms are immune to Held and "immune" should stay trustworthy) | a spinning swirl of starlings |
| **Zephyr** | **Gale lane** | every **10 s** a gust sweeps **3 path tiles** in range, copying statuses (half stacks) onto everything on them | a gust streak along the path |
| **Windmill** | **Momentum** | attack speed ramps **+5% per second** while nightmares are in reach (max **+50%**), and drops back after 2 s idle | the blades visibly spin up |
| **Elf Circle** | **Fairy dance** | a nightmare that steps on **3 rings in one walk** is caught dancing: **Held 1 s** (once per nightmare) | a little ring of lights spins around it |

- These follow the status jobs: Holds are Held (Rootling-style), Marked is Firefly's, nobody else
  slows or adds "+damage taken".
- Bosses: Logjam, Fairy dance, Starlit snare and Dark swirl use the boss Held rule (halved); Mended
  leaves counts boss dispels as 5.
- **Watch in playtests:** Logjam (it changes crowd flow), Mended leaves (the lose condition) and
  Momentum (Windmill could outscale).

### Crowned Reactions: three families at once

Added 2026-09-27 (proposed by the Tower Assets chat, set chosen by the user). A **Crowned
Reaction** is an existing Reaction going off on a nightmare that **already carries a third
status**. It's a bigger, named version of that Reaction. Like Reactions, it reads **statuses, never
Wardens**, so side sources count (Bloomcap's Drowsy, Frostfern's freeze, Chime Stone's Static), and
three families are reachable with 4 per run.

| Crowned | Reaction + 3rd status | Families | What happens | Effect (`assets/effects/`) |
|---|---|---|---|---|
| **Tempest** | Thunderclap + Spored | Dewdrop, Firefly Jar, Sporeling | every arc sets Spored targets **burning** (Ignite); the burning spores carry Static onto wet nightmares, so new Thunderclaps follow. The strongest chain engine | `crowned_tempest` |
| **Still Pool** | Drown + Held | Dewdrop, Bellflower, Rootling | the nightmare sinks and leaves a **still pool** on its tile for 5 s: the first time each walker enters, it's **pulled under** for 1 s | `crowned_still_pool`, `still_pool` (ground loop) |
| **Fever Dream** | Smother ends + max Drowsy | Sporeling, Rootling, Bellflower | the nightmare **falls asleep** (2 s) and passes Spored + Drowsy to adjacent nightmares: a sleep plague | `crowned_fever_dream` |
| **Starfall** | Pinned + Static | Firefly Jar, Rootling or Bellflower | the ×3 crit **pulls every Static bolt within 3 cells** into it, each bolt also crits, and a column of light falls. The boss killer | `crowned_starfall` |
| **Avalanche** | Shatter set off by a Cairn/Rockslide lob | Dewdrop, Rootling, Pebbling (Cairn) | the Shatter spreads to **every Damp + Held nightmare under the lob** | `crowned_avalanche` |
| **Prismstorm** | Shatter + Static | Dewdrop (Frostfern), Rootling, Firefly Jar | the ice shards carry lightning: each shard adds **2 Static** to what it hits, so wet neighbours Thunderclap | `crowned_prismstorm` |
| **Nightbloom** | Mushrooming + max Drowsy | Sporeling, Dewdrop, Bellflower | the spore cloud glows violet: sleep inside **doesn't end and doesn't break from hits**, and the Watcher can't wake anything there (the Bellflower counter's counter) | `crowned_nightbloom`, `nightbloom_cloud` (ground loop) |
| **Fairy Circle** | Mushrooming + Held | Sporeling, Dewdrop, Rootling | a **ring of mushrooms** sprouts around the held nightmare (the 8 tiles around it, path tiles only, 6 s): the first walker crossing each ring tile gets Spored + Damp, so more Mushrooming follows | `crowned_fairy_circle`, `fairy_circle_ring` (ground loop) |

**Delivery rules** (so families that apply no status can take part):

| Rule | Family | What happens | Effect |
|---|---|---|---|
| **Grafted Harmony** | Acorn (Graftling) | a Graftling touching Wardens of **two different status families** applies both statuses at half strength, so it's a Reaction source by itself. A placement puzzle, since Wardens are walls | `grafted_harmony_a` + `_b` (left and right halves of a glow, each tinted with one status colour) |
| **Storm Front** | Whirligig (Gust) | when a status Gust copied completes a Reaction on its new host, that Reaction **counts as a chain link and reaches one tile further** | `storm_front` (a wind swirl wrapped around the Reaction) |
| **Carried Storm** | Whirligig (Samara) | a Samara seed passing through a Reaction **carries it down the rest of its line**: the Reaction fires again (50%) on everything the seed hits after | `carried_storm` (the seed trails the Reaction's colour) |

**Rules**
1. **Every pair still works.** The third status only upgrades a Reaction; it's never required.
2. **Woven cards:** each Crowned Reaction has a **Woven** Legendary (an Entwined card with a third
   vine, 3 ingredients), guaranteed in the next offer once all 3 are owned (`dream_design.md`).
   Crowned Reactions work without their Woven card; the card makes them stronger.
3. A Crowned Reaction **counts as 2 chain links**, uses the **gold impact tier** (a crown mark on the
   callout, gold-edged effect) and has its own first-time discovery card.
4. **Bosses** get a reduced version (numbers in `dream_design.md`).
5. **Tempest cap:** a nightmare hit by a Tempest can't start another Tempest for 2 s, so the loop
   (Thunderclap → Ignite → Static → Thunderclap) always burns out.
6. **Discovery:** Crowned Reactions are **hidden in the Codex** until found, shown as silhouettes
   with their three family icons as hints.
7. **Not in the demo** (it has only 2 family picks). Tempest is a full-game reason to buy and a
   trailer moment; the demo's big moment stays a Thunderclap chain into Dawnburst.

**Later (post-launch ideas):** Rooted Storm (Thunderclap + Held: a grounded pylon), Undertow (Drown
+ Marked: dragged back, every hit crits), Flare (Ignite + Marked: the burst Marks and reveals).

## Kinships: two branches of one family
**Bonds are sticky** (2026-10-01, user: *"it seems like building new Wardens restarts the Kinship"*): a bond, once formed, is **kept until one of its two Wardens is sold or moved**. A newly planted or grown Warden **never takes over an existing bond**, even if it's nearer; it only bonds with kin that are still unbonded. Pairing nearest-first applies only among unbonded Wardens. Growing either partner keeps the bond and its age.


Added 2026-09-28 (user decision). Reactions reward going **wide** (2–3 families); Kinships reward
going **deep** in one. The two are kept visibly different:

| | Reactions | Kinships |
|---|---|---|
| Triggered by | two **statuses** meeting on a nightmare | two **Wardens** of one family standing close |
| What changes | the **nightmare** (a burst, sleep, a crit) | the **Wardens** (how they attack) |
| When | an **event**, with cooldowns and chains | **always on** while they stand together |
| Looks like | light bursting on the nightmare | the forest growing between Wardens: vines, petals |
| Chains | yes | no, but Kinships can set up Reactions |

**The rule:** a Warden from one branch and a Warden from a **different branch of the same family**
(branch or final form), within **2 cells** of each other, form a Kinship. **Each borrows one trait
from the other** ("they teach each other"), so one Kinship explains them all. Each Warden is in at
most one Kinship; if several kin are in reach, it bonds with the nearest.

**The bond grows** the longer the pair stands together (Wardens can't be moved, so **selling
either one** resets it, unless the *Rooted Bond* card is owned;
evolving keeps it):

| Stage | When | Borrowed traits | Look |
|---|---|---|---|
| **Sapling** | when formed | 50% | a thin vine on the ground |
| **Blooming** | 5 drifts together | 75% | the vine thickens and leafs |
| **Old Kin** | 10 drifts together | 100% | the vine flowers, both share a glow; Harmony strikes ×1.5 |

**Harmony strike:** when both kin hit the same nightmare within 1 s, two petals in their colours
spiral in and burst for bonus damage (1× the weaker Warden's hit; ×1.5 at Old Kin). It's effect
damage (Potency applies, no crit), 2 s cooldown per pair, and **never counts toward Reaction
chains** (it has its own counter).

**Family depth bonus:**
- **Kindred:** Wardens from **two** branches of a family on the map → that family +10% damage.
- **Whole Tree:** Wardens from **all three** branches (the hidden one included) → +20% damage
  (replaces Kindred) and a family perk: +1 stack cap on its status (Spored 9, Damp duration +1 s,
  Static bolts at 4, Held +0.25 s, Drowsy 6), or for status-less families: Pebbling +10% crit
  chance, Acorn +1 aura radius, Nestling +10% crit chance, Whirligig Gust copies onto +1. Stacks
  with *Monoculture*. Celebrated once per family per run.

### The 9 Kinships (build first)

Borrowed traits at full strength (Old Kin); Sapling 50%, Blooming 75%.

**As built (Tower Code, 2026-09-28):** below Old Kin, **per-hit traits fire as a chance** equal to
the share (Slumber Rot's Drowsy, Storm Beacon's Static, Flock Together's theft (was Dew until 2026-09-29), Dust Devil's status
copy: 50% or 75% of hits); durations and bonuses scale by the share instead. **Rainfog's** fog deals
the Rain Lily kin's splash damage × share to each nightmare entering the Mistveil's cloud, once per
cloud. A Warden's branch comes from its tier-2 form (so finals keep their branch). The 9 hidden
Kinships are built too (6ba79b8). Whole Tree family perks: check with Tower Code (the +20% damage is in).

| Family | Pair | Kinship | A borrows from B | B borrows from A |
|---|---|---|---|---|
| Sporeling | Driftspore + Bloomcap | **Slumber Rot** | puffs add 1 Drowsy | clouds add 1 Spored per tick |
| Dewdrop | Rain Lily + Mistveil | **Rainfog** | splashes leave a fog patch (1 tile, 2 s) | the fog deals Rain Lily's splash damage to nightmares entering it |
| Firefly Jar | Stormcap + Lanternmoth | **Storm Beacon** | chain jumps Mark for 2 s | shots add 1 Static |
| Pebbling | Mossback + Standing Stone | **Hammer and Anvil** | +10% crit chance at ×2.5 (the sniper's eye) | ×2 damage vs Marked (Mossback's weight) |
| Rootling | Rootcurl + Tangleroot | **Snare** | a pull ends in a 0.5 s hold | a hold drags the nightmare back half a tile |
| Bellflower | Chime Stone + Dreamcatcher | **Night Chimes** | pulses Catch full-Drowsy nightmares, as if a Dreamcatcher were there | threads set off Static at 3 stacks, like a chime |
| Acorn | Elder Stump + Dewcatcher | **Old Growth** | nightmares dispelled inside its aura drop +25% Dew (was +2 Dew per drift) | gains a small aura: neighbours +10% attack speed |
| Nestling | Wren's Nest + Magpie Perch | **Flock Together** | hits strip nightmare buffs (the magpie's theft) | hunts the fastest nightmare, +25% vs Phantoms |
| Whirligig | Gust + Pinwheel | **Dust Devil** | each copy also deals one blade hit | blades copy statuses (half stacks) onto what they hit |

### The 9 hidden Kinships (built 6ba79b8; need the hidden branch)

| Family | Pair | Kinship | Hidden borrows | Its kin borrows |
|---|---|---|---|---|
| Sporeling | Fairy Ring + Driftspore | **Spore Nursery** | rings apply 2 Spored (double) | puffs plant a mushroom ring where they land (one at a time) |
| Dewdrop | Frostfern + Mistveil | **Hoar Fog** | shots leave a fog puff (1 tile) | the fog freezes nightmares that stay 2 s |
| Firefly Jar | Sunpetal + Lanternmoth | **Sunspot** | the beam Marks its target | shots ramp +10% per hit on the same target (max +50%) |
| Pebbling | Cairn + Standing Stone | **Spotter** | lobs at the sniper's target; the landing crits | shots splash 30% within 0.75 cells |
| Rootling | Rootlight + Tangleroot | **Lantern Roots** | lit tiles hold a nightmare entering them for 0.3 s (once) | its holds reveal hidden nightmares and stop burrowing |
| Bellflower | Echo Hollow + Chime Stone | **Resonant Hollow** | echoes set off Static like a chime | pulses echo once at 30% |
| Acorn | Graftling + Elder Stump | **True Graft** | copies at 100% | the aura adds the strongest neighbour's status to its pulse |
| Nestling | Hummingbird Bower + Magpie Perch | **Jewel Thieves** | every 6th peck strips a nightmare buff (+1 Dew if there's none) | pecks twice per swoop |
| Whirligig | Samara + Gust | **Tailwind** | the seed carries full stacks | copies reach nightmares up to 3 cells away in a line |

**In the demo:** Slumber Rot, Rainfog and Storm Beacon (the starting families) and Kindred. They
give demo players a second layer of combos, since Crowned Reactions need 3 families. Whole Tree
needs a hidden branch, so it's full game only.

**Watch in playtests:** a Kinship can give one family two statuses (Storm Beacon: Marked + Static,
which is Lightning Rod). That's intended, but check that deep one-family runs don't match wide ones.

**Feedback and clutter:** loud moments happen at **rests**; in combat Kinships are nearly invisible
(dim vines, a tiny Harmony spark). Details: `screens_ui.md`, "Kinship feedback".

**Kinships you can see in combat** (added 2026-09-29, user request: make Kinships more visually
impactful without clutter). The impact goes **on the Wardens and the vine**, not on extra screen
effects:
1. **Borrowed looks:** a kin Warden's attacks carry its sibling's colour and a hint of the borrowed
   trait (Slumber Rot: Driftspore's puffs trail a lilac sleep-swirl, Bloomcap's clouds get green
   spore flecks; Storm Beacon: Stormcap's lightning gets a lantern-gold edge, Lanternmoth's shots
   crackle; Snare: Rootcurl's pull ends in a small root-wrap). You can tell who's bonded by watching
   them fight.
2. **Light along the vine:** when a borrowed trait fires, a small bead of light runs along the
   vine from the teacher to the learner. Vines stay dim but visibly *work*.
3. **Breathing together:** bonded Wardens' idle animations sync. At **Old Kin** the pair also grows
   a small **flowering arch** over them, so a mature bond reads at a glance.
4. **Harmony strikes grow with the bond:** Sapling = the tiny spark; Blooming = petals spiral in
   from both Wardens; **Old Kin = two beams of light leave both Wardens and meet on the nightmare**,
   bursting into petals (still on the 2 s cooldown, so occasional).

Not added (the user's call): *Kin Surge*, a synchronized free attack every 10 Harmony strikes.

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

## Potency: effect damage

Added 2026-09-27 (user request). Crit scales **hits**; **Potency** scales **effects**, the damage
that isn't a hit. Spored is the game's poison, and Potency is what makes poison builds grow. So
every Warden has two damage axes, and builds lean one way:

| | Hit builds | Effect builds |
|---|---|---|
| Damage from | projectile hits, chain jumps, pulses, beams, pecks, trap bursts | Spored ticks, Static bolts, clouds and fog, Puffball pops, rubble, **Reactions, Crowned Reactions, echoes** |
| Scales with | crit chance and multiplier | **Potency** |
| Signature Wardens | Pebbling, snipers, Hummingbird | Driftspore/Puffball, Mistveil, Thunderhead, Echo Hollow |

- **Potency** is a % on each Warden, **100% by default**. It multiplies the effect damage of the
  statuses *that Warden* applied (the applier's Potency is stored with the status, like its damage).
- **Reactions** use the Potency of the Warden that completed them (the "applier" in
  `dream_design.md`), so Potency is the main way to make Reactions hit harder late in a run.
- **What it doesn't touch:** hits, status *duration* and stacks (those have their own cards and the
  Deep focus), slows and control.
- **Order:** `effect damage × Potency × family resist/weak × Marked` (no crit, no attack shape
  except the Whisper Swarm's area rule, as before).
- **Sources:** a few Wardens start above 100% (`warden_stats.md`), the Nurture **Deep** focus
  (+10% Potency and duration per rank III–V), and the Potency cards in `dream_design.md`.
- **Shown** in the Warden tooltip next to crit (e.g. "Crit 5% · ×2 · Potency 130%"). Effect damage
  numbers use the status's colour, so a poison build *looks* different from a crit build.
- *Nightshade* (Legendary) bridges the two: effect ticks can crit.

## Target priority

Most Wardens target the nightmare **furthest along** the path by default. Since 2026-09-28 every
attacking Warden that picks a target has a switch (`screens_ui.md` "Targeting"): **First**
(default), **Last** (furthest back, the newest arrival; added 2026-09-30), **Strongest** and
**Closest**; snipers keep *Bosses first* as well. **Last** pairs with status Wardens near the start
(Driftspore, Lanternmoth, Firefly Jar tagging nightmares so they carry the status through the whole
maze).

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
| **Deep Poison** | Puffball + Mistveil + Echo Hollow (+ Deep-focus Wardens) | *Seeping*, *Nightshade* | no big hits at all: stacked spores in fog, Potency on everything, and every Reaction echoes |
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
