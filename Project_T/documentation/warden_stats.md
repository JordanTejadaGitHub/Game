# Warden Stats

Numbers for every Warden. What each one *does* and why it exists is in `tower_design.md`; status
rules are in `dream_design.md`. Rows marked **✓** are already in the game (`resource/tower/*.tres`)
and their values here are copied from there; the rest are proposals for the coding chat. Everything
is a starting point for playtesting.

## Principles

**Cost tiers (economy pass v2, 2026-09-27):** Sprout 10 → base 25–30 (Sprout + 15–20) → branch
**+80** (was 45) → final form **+200** (was 90) → **Ascended +400** (new, `tower_design.md`). A final
form costs ~310 Dew in total. **Power per tier goes up to match:** branch ≈ **2.5×** its base (was
2×), final form ≈ **3×** its branch (was 2×), Ascended ≈ 3× a final form. Existing Warden numbers
below are the pre-pass values; scale branch and final-form damage by ×1.25 and ×1.5 respectively
when applying the pass. **Nurture base costs** rise to **25 / 40 / 60 / 90 / 135** (× tier:
Sprout 0.5, base 1, branch 2, final 3, Ascended 4, Memory Warden 2).

**Dew-efficiency falls, space-efficiency rises.** Each tier is roughly **2× as strong per cell**
as the one before, but costs ~2.3× as much. Early on, Dew is what limits you, so cheap Wardens are
best; later, **space on the map** is what limits you (every Warden is a wall in the maze), so
evolving is how you keep growing. That tension is the long-run economy.

**Reference power:** a Sprout soothes 10 per second for 10 Dew. "DPS" below = soothe per second
against one creature, before statuses, auras and Dreams. Area and status effects are worth extra;
single-target Wardens get higher raw numbers to compensate.

**Ranks: Nurture** (added 2026-09-27, user request). Every attacking Warden (not Thornwall) can be
**Nurtured** up to **rank V** with Dew, from the Warden panel (group Nurture works with
multi-select; hotkey **R**).

**Nurture v2** (2026-09-27, after a playtest where "upgrading without thought" won the mid-game):
costs scale with the Warden's tier, gains per rank are smaller, and **rank III asks for a choice**.

| Rank | Base cost | Each rank adds |
|---|---|---|
| I | 15 | **+10% damage**, **+4% attack speed**, **+0.1 range** |
| II | 25 | the same again |
| III | 40 | the same again, **and choose a Focus** (below) |
| IV | 60 | the same again + the Focus bonus |
| V | 90 | the same again + the Focus bonus (230 base in total) |

**Cost × tier:** Sprout **×0.5** (115 to rank V), base **×1** (230), branch **×2** (460), final form
**×3** (690), Memory Warden **×2**. The cost is set by the Warden's tier *when you buy the rank*, so
ranking a Sprout before it evolves is cheap (ranks still carry through evolution) and ranking a
final form is a big, deliberate spend.

**Focus (chosen at rank III, kept through evolution, can't be changed):**

| Focus | Ranks III, IV and V each add | At rank V (on top of the base gains) |
|---|---|---|
| **Power** | +8% damage | +24% damage |
| **Swift** | +6% attack speed | +18% attack speed |
| **Reach** | +0.2 range | +0.6 range |
| **Deep** | +10% status strength and duration | +30% |

- At rank V without Focus: +50% damage, +20% attack speed, +0.5 range ≈ **1.8× damage per second**;
  with Power ≈ 2.1×. Two identical Wardens can end up doing different jobs (a Reach Lanternmoth
  marking far ahead, a Deep Rain Lily keeping everything soaked).
- **Ranks carry through evolution:** a rank III Sporeling that grows into a Driftspore is a rank III
  Driftspore, with the same Focus.
- Ranks are **less Dew-efficient than evolving** (a branch costs 45 for ~2×; rank V on a base
  Warden costs 230 for ~1.8×), so evolving stays the better buy when a Dream allows it.
- Ranks multiply with Dream bonuses (Deeper Calm etc.). Status potency uses the ranked damage.
- Selling refunds rank Dew like any other Dew spent on the Warden.
- Shown as small pips under the Warden and in its panel ("Rank III").

**Auras don't stack with themselves:** a Warden next to two Elder Stumps gets the bonus once (the
highest one applies). Different aura types do stack.

**Crits** (rules in `tower_design.md`): every attacking Warden has **5% crit chance, ×2** unless
listed below. Average damage with crits = DPS × (1 + chance × (multiplier − 1)), so the default
adds +5%. Clouds, fog, Spored, Static bolts and Puffball pops never crit.

| Warden | Crit chance | Multiplier | Notes |
|---|---|---|---|
| Pebbling | 8% | ×2 | |
| Mossback | 10% | ×2 | |
| Boulderback | 12% | ×2 | always crits on Drowsy (guaranteed, no roll) |
| Lanternmoth, Beacon | 10% | ×2 | |
| ✓ Midsummer | 8% | ×2 | per beam tick |
| ✓ Hoarfrost | 5% | ×2 | +20% chance vs Held (frozen) nightmares |
| **Standing Stone** | **20%** | **×2.5** | |
| **Moonstone** | **25%** | **×3** | first hit on each nightmare always crits |
| Cairn, Rockslide | 8%, 10% | ×2 | |
| Hummingbird Bower, Jewelwing Court | 5% | ×2 | rolls **per peck**; Jewelwing's every 6th peck is guaranteed |
| Samara, Autumn Gale | 5% | ×2 | rolls per pass (twice per nightmare per throw) |
| ✓ Wren's Nest | 15% | ×2 | |
| ✓ Magpie Perch | 10% | ×2 | |
| ✓ Magpie's Hoard | 15% | ×2 | each crit +1 Dew, max 15 per drift |
| Bloomcap, Dreamshroom, Mistveil, Morning Fog | — | — | clouds and fog can't crit |

## Always available

| Warden | Cost | Range | Soothe × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|
| ✓ Sprout | 10 | 2.5 | 10 × 1.0 | 10 | projectile | none |
| ✓ Thornwall | 3 | — | — | — | wall | no attack |
| ✓ Bramble | +10 | 1.25 | 6 × 1.5 | 9 (area) | pulse | soothes creatures walking beside it; **×2 vs Held** (proposed) |
| ✓ Honeysuckle | +10 | 1.25 | — | — | aura | nightmares beside it gain **1 Drowsy per 1.5 s** (no damage) |

## Sporeling family (spore)

| Warden | Tier | Cost | Range | Soothe × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Sporeling | base | 25 (+15) | 2.5 | 7 × 2.0 | 14 | projectile | Spored 1 per hit (cap 8) |
| ✓ Driftspore | branch | +45 | 2.5 | 8 × 2.0 | 16 | projectile | Spored **2** per hit, cap **12** |
| Puffball | final | +90 | 2.5 | 12 × 2.0 | 24 | projectile | Spored 2 per hit, cap 12. At **10+ stacks** the target **pops**: soothes it and creatures within 1 cell for **6 × stacks**, and half its stacks spread to up to 3 nearby creatures |
| ✓ Bloomcap | branch | +45 | 2.5 | 10 × 0.5 | cloud | cloud | leaves a sleepy cloud on the path (radius 0.75, 3 s): Drowsy |
| Dreamshroom | final | +90 | 2.5 | 14 × 0.6 | cloud | cloud | bigger cloud (radius 1.0, 4 s), **2 Drowsy** per tick; at 5 Drowsy a creature **sleeps 1.5 s** (once each; bosses cap at 3 Drowsy, so they never sleep) |
| ✓ Fairy Ring *(hidden)* | branch | +45 | 2.5 | 35 per burst | trap | trap | every 2 s plants a ring on a random path tile in range (max 4, last 10 s); stepping on one: 35 damage within 0.6 cells + **Spored 2** |
| ✓ Elf Circle *(hidden)* | final | +90 | 3 | 60 per burst | trap | trap | every 1.5 s, max 6 rings, **rings last until stepped on**; Spored 3 |

## Dewdrop family (water)

| Warden | Tier | Cost | Range | Soothe × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Dewdrop | base | 25 (+15) | 2.5 | 15 × 1.2 | 18 | projectile | splash 0.6; Damp |
| ✓ Rain Lily | branch | +45 | 2.75 | 18 × 1.2 | 22 | projectile | splash **1.0**; Damp **6 s** |
| Monsoon | final | +90 | 3 | 40 every 3 s | 13 to **each** creature in range | rain | soothes **every** creature in range + Damp 6 s |
| ✓ Mistveil | branch | +45 | 2.5 | 8 × 0.5 | cloud | cloud (fog) | fog on the path (radius 0.9, 4 s): Damp, and **Spored ticks +50%** inside (proposed value) |
| Morning Fog | final | +90 | 3 | 10 × 0.5 | cloud | cloud (fog) | fog radius **1.25**, 5 s: Damp, slows 15%, **1 Drowsy per second** inside |
| ✓ Frostfern *(hidden)* | branch | +45 | 2.5 | 16 × 1.0 | 16 | projectile | hits on **Damp** nightmares **freeze** them (Held 0.75 s; once per 4 s per nightmare) |
| ✓ Hoarfrost *(hidden)* | final | +90 | 3 | 26 × 1.0 | 26 | projectile | splash 0.75; freeze **1 s**; +20% crit chance vs Held |

## Firefly Jar family (light)

| Warden | Tier | Cost | Range | Soothe × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Firefly Jar | base | 30 (+20) | 3 | 12 × 1.5 | 18 | projectile | Static 1 |
| ✓ Stormcap | branch | +45 | 3 | 14 × 1.2 | 17 × up to 3 | chain | chains to 3 (jump 1.5); vs Damp: **+2 jumps**, jump 2.5 |
| ✓ Thunderhead | final | +90 | 3.5 | 20 × 1.3 | 26 × up to 4 | chain | every **5th** attack strikes **every Damp creature** in range. **Proposed:** chain 4 (currently the default 3) |
| ✓ Lanternmoth | branch | +45 | 4.5 | 12 × 1.0 | 12 | projectile | Marked; **reveals** fog-hidden creatures in range |
| Beacon | final | +90 | 5 | 16 × 1.0 | 16 | projectile + pulse | every 2 s, **Marks everything** in range; its Marked is **+35%** |
| ✓ Sunpetal *(hidden)* | branch | +45 | 3.5 | 12/s, ramping | 12 → 48 | beam | ramps +25% per second on one target (max ×4); ramps **2× as fast** on Drowsy or Held |
| ✓ Midsummer *(hidden)* | final | +90 | 4 | 18/s, ramping | 18 → 90 | beam | ramps +35%/s (max ×5), 2× on Drowsy/Held; beam **also hits the nightmare right behind** its target at 50% |

## Pebbling family (stone) — heavy hits: close, far, area

| Warden | Tier | Cost | Range | Soothe × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Pebbling | base | 30 (+20) | 2 | 40 × 0.5 | 20 | projectile | heavy, slow |
| Mossback | branch | +45 | 1.75 | 110 × 0.4 | 44 | projectile | **×2 vs Marked** |
| Boulderback | final | +90 | 1.75 | 220 × 0.35 | 77 | projectile | splashes 50% to creatures within 1 cell; **always crits (×2) on Drowsy** |
| ✓ Standing Stone | branch | +45 | **8** (min 2) | 100 every 3 s | 33 | projectile | **+10% damage per cell** of distance beyond 3 (max +50%); crit 20% ×2.5; target priority. With crits and full distance ≈ 65 DPS. *(Was hidden; now branch B, 2026-09-27 review.)* |
| ✓ Moonstone | final | +90 | **10** (min 2) | 220 every 3.5 s | 63 | projectile | distance bonus as above; crit 25% **×3**; **first hit on each nightmare always crits**. Full distance + crits ≈ 140 DPS |
| Cairn *(hidden)* | branch | +45 | **6** (min 2) | 60 every 2.5 s | 24 (area) | lob | lobs over walls onto the target's tile: 60 to everything within **1 cell**; crit 8% ×2 |
| Rockslide *(hidden)* | final | +90 | 7 (min 2) | 110 every 2.5 s | 44 (area) | lob | splash **1.25 cells**; the path tiles hit get **rubble**: −25% speed for 3 s; crit 10% |

## Bellflower family (song) — new 2026-09-27

Owns **Drowsy**. Chime Stone and Lullaby Bell moved here from Pebbling (numbers unchanged).

| Warden | Tier | Cost | Range | Damage × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| Bellflower | base | 25 (+15) | 2 | 10 × 1.0 | 10 (area) | pulse | every 2nd pulse: **1 Drowsy** to everything in range |
| Chime Stone | branch | +45 | 2 | 22 × 0.8 | 18 (area) | pulse | Static 1; each pulse **sets off** a Static bolt on nightmares with 3+ stacks |
| Lullaby Bell | final | +90 | 2.5 | 40 × 0.8 | 32 (area) | pulse | Static 1 + **Drowsy 1** per pulse; sets off Static like Chime Stone |
| Dreamcatcher | branch | +45 | 2.5 | 10 × 1.0 | 10 | projectile | nightmares in range that are **asleep or at max Drowsy** are **Caught**: +40% damage taken from all sources |
| Great Dreamcatcher | final | +90 | 3 | 16 × 1.0 | 16 | projectile | Caught +60%; sleep in range lasts **+1 s** (once per nightmare); each Caught nightmare dispelled drops a **Dreamlight shard** (10 shards = 1 Dreamlight; max 2 Dreamlight per run from shards) |
| Echo Hollow *(hidden)* | branch | +45 | 2.5 | 8 × 1.0 | 8 (area) | echo | a Reaction within range **repeats 1 s later at 50%** on the same spot (echoes don't echo) |
| Whispering Hollow *(hidden)* | final | +90 | 3.5 | 12 × 1.0 | 12 (area) | echo | echoes at **75%**; each echo **counts as a chain link** |

**Echoes, as built (a9ba4b6):** an echo is a burst at the Reaction's spot, sized from the applier's
damage × a per-Reaction factor (Thunderclap 4, Ignite 3, Shatter 2.5, Lightning Rod 6) × 50% (Echo
Hollow) or 75% (Whispering Hollow). Drown echoes as a shorter sleep, Pinned re-primes its guaranteed
crit, Mushrooming grows a shorter cloud, and **Smother doesn't echo**.

Caught and Marked stack multiplicatively (a Caught, Marked nightmare takes ×1.4 × ×1.25). Bosses
never sleep, but their Drowsy cap is 3, and **3 counts as max for them**, so bosses can be Caught.
Caught bosses give no Dreamlight shards.

## Rootling family (root)

| Warden | Tier | Cost | Range | Soothe × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Rootling | base | 25 (+15) | 2 | 12 × 1.0 | 12 (area) | pulse | **proposed:** pulses slow 10% for 1 s (the "roots nip at feet" in the design) |
| Rootcurl | branch | +45 | 2 | 14 × 1.0 | 14 (area) | pulse + pull | every **4 s**, pulls the creature furthest along (in range) **back 1 tile** |
| Long Way Home | final | +90 | 2.5 | 18 × 1.0 | 18 (area) | pulse + pull | every **5 s**, pulls back **3 tiles**; each creature only once (bosses: 1 tile) |
| Tangleroot | branch | +45 | 2 | 14 × 1.0 | 14 (area) | pulse + hold | every **3 s**, **Holds** the creature furthest along for 1 s |
| Snugroot | final | +90 | 2.5 | 20 × 1.0 | 20 (area) | pulse + hold | every 3 s, Holds **up to 3** creatures for 1 s |
| ✓ Rootlight *(hidden)* | branch | +45 | 3 | 10 × 1.0 | 10 (area) | pulse + light | lights path tiles in range: **reveals Lurkers**, **Gravecrawlers can't burrow** on lit tiles, nightmares on lit tiles are **Marked** |
| ✓ Starcave *(hidden)* | final | +90 | 4 | 16 × 1.0 | 16 (area) | pulse + light | as Rootlight; Marked **lingers 2 s** after leaving the light |

## Acorn family (support, economy)

| Warden | Tier | Cost | Range | Soothe × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Acorn | base | 25 (+15) | 2 | 8 × 1.0 | 8 (area) | pulse | **aura:** the 8 surrounding Wardens +5% soothe |
| Elder Stump | branch | +45 | 2 | 10 × 1.0 | 10 (area) | pulse | **aura:** the 8 surrounding Wardens **+20% attack speed** |
| Grove Heart | final | +90 | 2 | 14 × 1.0 | 14 (area) | pulse | **aura, radius 2:** +15% soothe and attack speed, **+3% more per Warden** in the radius (max +30%) |
| Dewcatcher | branch | +45 | 2 | 8 × 1.0 | 8 (area) | pulse | **+3 Dew per drift** (+15 per block; pays itself back in ~15 drifts) |
| Wellspring | final | +90 | 2 | 10 × 1.0 | 10 (area) | pulse | at every rest, **+5% of your banked Dew** (max +40 per Wellspring; all Wellsprings together max +80 per rest) |
| ✓ Graftling *(hidden)* | branch | +45 | as copied | 60% of copied | — | copied | copies the attack (kind, range, statuses, crit) of the **highest-DPS adjacent** attacking Warden; not Memory Wardens or other Graftlings |
| ✓ Grafted Elder *(hidden)* | final | +90 | as copied | 85% of copied | — | copied | as Graftling |

## Nestling family (wing) — full game

| Warden | Tier | Cost | Range | Damage × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Nestling | base | 25 (+15) | 3 | 14 × 1.2 | 17 | swoop | bird flies out and back; ×1.25 vs Phantoms |
| ✓ Wren's Nest | branch | +45 | 3.5 | 8 × 3.0 | 24 | swoop | targets the **fastest** nightmare in range; ×1.5 vs Phantoms and sprinting Night Hounds; crit 15% |
| ✓ Starling Murmuration | final | +90 | 4 | 3 birds × 10 × 1.5 | 45 (split) | swoop | **changed 2026-09-27:** 3 starlings each hunt one of the **3 fastest** nightmares in range; ×1.5 vs Phantoms and sprinting Night Hounds; crit 15%. (Was: sweeps the 5 busiest path tiles) |
| ✓ Magpie Perch | branch | +45 | 3 | 12 × 1.0 | 12 | swoop | nightmares it hits drop **+1 Dew** when dispelled; crit 10% |
| ✓ Magpie's Hoard | final | +90 | 3.5 | 20 × 1.0 | 20 | swoop | as Magpie Perch; **each crit +1 Dew** (max 15 per drift); crit 15% |
| Hummingbird Bower *(hidden)* | branch | +45 | 3 | 6 pecks × 4, every 1.5 s | 16 | multi-hit | pecks one nightmare 6 times in 1 s, returns in 0.5 s; **each peck is a full hit** (crit roll, Marked, on-hit cards) |
| Jewelwing Court *(hidden)* | final | +90 | 3.5 | 3 birds × 8 pecks × 6, every 1.5 s | 96 (split) | multi-hit | birds spread over targets or all focus the strongest (toggle); **every 6th peck crits** |

## Whirligig family (wind) — full game

| Warden | Tier | Cost | Range | Damage × /s | DPS | Kind | Effect |
|---|---|---|---|---|---|---|---|
| ✓ Whirligig | base | 25 (+15) | 2 | 10 × 1.0 | 10 (area) | pulse | nudges nightmares **back 0.25 tiles** (each at most once per 3 s) |
| ✓ Gust | branch | +45 | 2.5 | 10 × 0.5 | 5 (area) | gust | every 2 s, copies all statuses of the **most-afflicted** nightmare in range onto **2** others within 1.5 cells (**half stacks**, full duration) |
| ✓ Zephyr | final | +90 | 3 | 16 × 0.5 | 8 (area) | gust | as Gust, onto **up to 5** |
| ✓ Pinwheel | branch | +45 | 1 (adjacent tiles) | 12 × 2.0 | 24 (area) | blades | hits every nightmare on the 8 tiles around it; **+20% damage per adjacent path tile beyond 2** (max +100%) |
| ✓ Windmill | final | +90 | 1 | 18 × 2.5 | 45 (area) | blades | as Pinwheel |
| Samara *(hidden)* | branch | +45 | 4 (line) | 20 per pass, ~1 throw / 1.6 s | ~25 to **each** in the line | boomerang | straight out and back through everything; each nightmare hit twice; carries the first-hit nightmare's statuses (half stacks) down the line |
| Autumn Gale *(hidden)* | final | +90 | 5 (line) | 2 seeds × 35 per pass, ~1 throw / 1.6 s | ~44 to each, two lines | boomerang | aims along the 2 lines with most nightmares; each catch +10% next-throw damage (max +50%; resets if a throw hits nothing) |

As built: Samara aims its line at its **first target**; Autumn Gale picks the **two lines through the
most nightmares**. The catch rhythm counts **per throw** (+10% if any seed hit, reset if none did),
not per seed.

## Memory Wardens (unique, from bosses)

Free, one of each per run, can't evolve or be sold for Dew (selling returns the memory: it can be
placed again at the next rest).

| Warden | Range | Damage × /s | Kind | Effect |
|---|---|---|---|---|
| ✓ The White Stag | 4 (aura) | — | aura | nightmares in range −15% speed, **+15% damage taken**; Wardens in range **+5% crit chance** |
| ✓ The Pond Keeper | 3 | 40 per grab | grab | every 4 s, pulls the nightmare **furthest along** back to the path tile nearest the pond (bosses: back 2 tiles) and makes it Damp |
| ✓ The Moon Moth | 6 | 30 × 0.8 | projectile | reveals **every Lurker on the map**; Marks what it hits; Wardens within 3 cells **+1 range** |

## New mechanics the unbuilt Wardens need

For the coding chat, in rough order of need:
0. **2026-09-27 review:** Bellflower family (`song` line; Chime Stone and Lullaby Bell move from
   Pebbling), Dreamcatcher's **Caught** state and Dreamlight shards, Echo Hollow's **Reaction
   echo**, Cairn's **lob** over walls with rubble tiles, Hummingbird's **multi-hit** (each peck a
   full hit), Samara's **boomerang** (line out and back, catch, status carry), Standing Stone and
   Moonstone no longer hidden, Starling Murmuration hunts the 3 fastest.
1. **Pulse with an effect**: slow (Rootling), Static set-off (Chime Stone), extra statuses.
2. **Pull back along the path** (Rootcurl, Long Way Home): move a creature back N cells on its
   current route; once-per-creature memory.
3. **Hold** (Tangleroot, Snugroot): the Held status (`dream_design.md`).
4. **Auras** (Acorn, Elder Stump, Grove Heart): neighbour lookup on the grid; highest-of-type rule.
5. **Economy hooks** (Dewcatcher, Wellspring): per-drift and per-rest Dew.
6. **Pop / burst** (Puffball), **sleep** (Dreamshroom), **rain** (Monsoon), **mark-all pulse**
   (Beacon), **ramping beam** (Sunpetal).
7. **Crits**: roll per hit in `Tower`, pass `is_crit` to `Enemy.take_damage`, crit flare/number.
   Cheap and cross-cutting, so it can go in early.
8. Hidden and full-game Wardens: **min range + distance bonus + target priority** (snipers),
   **traps** (Fairy Ring), **freeze** (Frostfern, reuses Held), **lit tiles** that block burrowing
   (Rootlight), **attack copying** (Graftling), **swoop** projectiles that return, **status
   copying** (Gust), **adjacent-tile blades** (Pinwheel), **unique** Memory Wardens.

## To check in playtests

- Is each family roughly as strong as the others at the same Dew? (Compare Dew spent vs creatures
  dispelled per family.)
- Do players evolve when space runs out, as intended, or hoard cheap Wardens?
- Pull and Hold on bosses: fun, or trivialising? (Bosses get reduced effects.)
- Economy Wardens: does Dewcatcher pay back fast enough to be picked, without being mandatory?
