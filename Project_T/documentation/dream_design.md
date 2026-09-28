# Dream Design: the in-run upgrade pool

Phase 2 of `design_plan.md`. Revised 2026-09-27 for **100-drift runs** (`run_design.md`): a
Dream after every 5th drift (**19 per run**), and Warden families come from the first pick and the
bosses, not from Dreams. Covers the first-playable scope from `tower_design.md` (Sprout,
Thornwall, Sporeling, Firefly Jar, Dewdrop, their branches, and Thunderhead). Numbers are starting
points.

## Goals

- **Builds come together.** Families are limited (4 of 6 per run), so each run leans a different
  way; Dreams then shape those families into a build (checked below for Storm Grid).
- **Every card is a real choice.** Stat cards are safe; rule cards are exciting; branch cards open
  a direction. An offer should usually mix kinds.
- **Maze matters.** Several cards reward how you build the maze (corners, walls, path length), not
  just damage.
- **Cards never gate a combo** (user rule, 2026-09-27). If you own the Wardens, their combo works on
  its own (e.g. Rain Lily's Damp already gives Stormcap +2 jumps and longer jumps). Combo cards like
  Conductive Soil, Charged Bloom, Chain Bloom and Spore Cascade only **amplify** a combo or **add a
  new twist**. Any new card must follow this.

## Where Warden families come from (not Dreams)

- **After drift 1:** pick 1 of 3 base Wardens, drawn **at random from every family you've
  unlocked** (the starting 3 plus any unlocked in the Memory Grove: Pebbling, Rootling, Acorn,
  Nestling, Whirligig). Not always the same 3: a Grove unlock can turn up from drift 1.
- **Bosses at drifts 25, 50, 75:** pick 1 of 3 from the unlocked families you don't have yet (Family
  Blessings fill empty slots, `meta_design.md`).
- Draws avoid repeating the previous run's first-pick offer exactly, so runs start differently.
- Family cards explain the Sprout rule, e.g. *"Sporeling: Sprouts can now grow into Sporelings
  (15 Dew), or plant one directly (25 Dew)."*

## How Dream offers work

- **3 cards per Dream**, after drifts 5, 10, … 95. No duplicates within an offer.
- **Rarity weights by act:**

  | Act | Common | Uncommon | Rare | Legendary |
  |---|---|---|---|---|
  | 1 (drifts 1–25) | 65 | 28 | 7 | 0 |
  | 2 (26–50) | 50 | 32 | 15 | 3 |
  | 3 (51–75) | 42 | 33 | 20 | 5 |
  | 4 (76–100) | 35 | 33 | 24 | 8 |

- **Boss Dreams** (after drifts 25, 50, 75, alongside the family pick): at least one card is Rare
  or better.
- **Pity:** 3 Dreams in a row without a Rare+ card → the next offer includes one.
- **Branches and final forms are no longer Dream cards** (2026-09-27, user decision): they're
  unlocked with **Dreamlight**, a currency earned from bosses (`run_design.md`, "Dreamlight"). The
  **growth slot is removed**, and so are all branch / final-form unlock cards (including Thunderhead,
  Puffball and the Honeysuckle/Bramble wall growths, which become Dreamlight unlocks too). Dreams are
  now purely stats, rules, combos and economy. Build paths are a **choice**, not luck. (History: the
  growth slot had reached 92–95% of runs with a cross-family combo by the act 1 boss; Dreamlight
  makes that deterministic.)
- **Tag weighting:** cards tagged with a family you own are **2× as likely**. Builds converge
  without being forced.
- **Prerequisites:** a card never appears if it can't do anything yet (e.g. Stormcap cards need
  Firefly Jar). Full rules in *Card requirements* below.

### Card requirements (the "Needs" column)

Clarified 2026-09-27 (user rule: cards that need other cards work like the clearing cards). Every
card lists its **Needs**; it is **never offered until all of them are met**. There are three kinds:

| Kind | Meaning | Example | Data |
|---|---|---|---|
| **Warden** | you own that Warden (built or unlocked) | Soft Spores needs Sporeling | `requires` (Warden id) |
| **Card** | you've taken that card, or *any* card with a tag | Thunderhead needs Stormcap; Sunlit Rest needs any `nurture` card | `requires` (card id) / `requires_tag` (new) |
| **Run state** | something on the map or in your run is true | clearing cards need 8+ obstacles; Deeper Rings needs a rank V Warden | `min_obstacles`, `min_rank_dew` (new), `min_rank_owned` (new) |

**Opener cards and follow-up cards.** Some directions are *locked mechanics*: clearing is off until you
take a clearing card, so **every clearing card is an opener** (taking any one turns clearing on).
Directions that are always available but need investment (Nurture) have **openers** (need only the
run-state check) and **follow-ups** (need an opener card too). So the pool grows with your build
instead of offering payoff cards for a direction you never started.

- **Deepened cards** always need their base card.
- **Entwined cards** need all their ingredients (and are then guaranteed once).
- **Grove cards** also need their Grove unlock (outside the run).
- A requirement that is **lost** (e.g. you sell your last rank V Warden) doesn't remove a card you
  took; it only stops new offers of cards that need it.
- **Stacking:** stat cards (Commons 1–7) **stack without limit** (shown as "II", "III", …);
  everything else once. Stacks add, not multiply (3× Quickened Sap = +30%, not +33.1%). With 19
  Dreams the extreme is +190% in one stat, which is fine: creatures reach ×30 health by drift 100,
  and a player who puts everything into one stat gives up branches and rules. Watch Grove perks
  that add Dreams or rerolls.
- **Let it pass:** you may skip a Dream for +15 Dew. An escape hatch when nothing fits.
- **Reroll / banish:** not in the base game; Memory Grove perks add them (`meta_design.md`).
- **Branch cards** say what they allow, e.g. *"Stormcap: Firefly Jars can now grow into
  Stormcaps (45 Dew)."*

## Pool size over 100 drifts

19 Dreams from the first-playable pool (33 cards) will repeat within a run. Stacking commons soften
that, but the **full game should grow the pool to ~70 cards**: roughly 6–8 cards per family (its
branches, finals and family-specific rules) plus ~20 general cards. Each new family added (Pebbling,
Rootling, Acorn) brings its own cards.

## The pool (33 cards)

**Start** = in the pool from the very first run. **Grove** = unlocked in the Memory Grove (meta).

### Common: steady growth

| # | Card | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|
| 1 | **Quickened Sap** | all Wardens +10% attack speed | — | — | Start |
| 2 | **Deeper Calm** | all Wardens +10% soothe | — | — | Start |
| 3 | **Longer Roots** | all Wardens +0.25 range | — | — | Start |
| 4 | **Sprout Surge** | Sprouts +30% soothe, +0.5 range | sprout | — | Start |
| 5 | **Soft Spores** | Spored +25% strength | spore | Sporeling | Start |
| 6 | **Brighter Jars** | Firefly line +15% attack speed | light | Firefly Jar | Start |
| 7 | **Heavy Dew** | Dewdrop line +25% splash radius, Damp +1 s | water | Dewdrop | Start |
| 8 | **Cheap Hedges** | Thornwalls cost 2 (once) | wall | — | Start |
| 9 | **Morning Dew** | +20 Dew now, +10 at every rest | economy | — | Start |
| 10 | **Deep Roots** | +2 max leaves, regrow 2 now | leaves | — | Start |

*(Numbers 11–13 were base Warden unlocks; those now come from the first pick and bosses.)*

### Uncommon: new directions and small rules

| # | Card | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|
| 14 | **Driftspore** | unlock branch | spore | Sporeling | Start |
| 15 | **Bloomcap** | unlock branch | spore, sleep | Sporeling | Start |
| 16 | **Stormcap** | unlock branch | light, storm | Firefly Jar | Start |
| 17 | **Lanternmoth** | unlock branch | light, mark | Firefly Jar | Start |
| 18 | **Rain Lily** | unlock branch | water | Dewdrop | Start |
| 19 | **Mistveil** | unlock branch | water, fog | Dewdrop | Start |
| 20 | **Bramble** | Thornwalls can grow into Brambles (+10 Dew each) | wall | — | Start |
| 21 | **Cozy Corners** | Wardens beside a bend in the path +15% soothe | maze | — | Start |
| 22 | **Hedge Maze** | +1% soothe per 5 Thornwalls you have (max +20%) | wall, maze | — | Start |
| 23 | **Evergreen** | evolving costs 25% less Dew | economy | — | Start |
| 24 | **Lingering Spores** | Spored lasts 3 s longer | spore | Sporeling | Start |
| 25 | **Soaked Through** | Damp lasts twice as long | water | Dewdrop | Start |
| 26 | **Charged Bloom** | Stormcap chains also apply 1 Drowsy | storm, sleep | Stormcap | Grove |
| 27 | **Twin Puff** | every 3rd Sporeling attack fires twice | spore | Sporeling | Grove |

### Rare: combo enablers and final forms

| # | Card | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|
| 28 | **Thunderhead** | Stormcaps can grow into Thunderheads (90 Dew) | storm | Stormcap | Start |
| 29 | **Conductive Soil** | lightning jumps to *every* Damp creature in range | storm, water | Entwined: Stormcap + Rain Lily | Start |
| 30 | **Spore Cascade** | a dispelled nightmare's Spored stacks spread to the 2 nearest nightmares | spore | Sporeling | Start |
| 31 | **Charged Field** | Static bolts also hit creatures within 1 tile | storm | Firefly Jar | Grove |
| 32 | **Guiding Light** | Marked spreads to creatures within 1 tile of the target | mark | Lanternmoth | Grove |
| 33 | **Seedling Gift** | at every rest, gain **1 free Sprout** (a charge; you plant it) | sprout, economy | — | Grove |

**Seedling Gift details** (settled 2026-09-27): the free Sprout is a **charge**, not an automatic
planting, so it never blocks or reshapes the maze on its own. Charges show next to the Sprout button
in the Warden bar (a small seed badge with the count) and are **used before Dew** when you plant a
Sprout, like Heartwood's Reach's free clears. Unused charges last all run and are kept in the save.
A Sprout planted with a charge has 0 invested Dew, so selling it refunds nothing. With **Nursery**,
a Sprout planted from a charge starts at **rank II** (its rank Dew counts as 0 too). **Deepened II:**
at every rest, choose a free Sprout charge **or** a free growth charge (the next Sprout → base
Warden growth costs 0).

### Legendary: changes how you play (act 2+ only)

**Legendary rules** (user, 2026-09-28): *Legendaries are cards you build around; most other cards
enhance a build.*
- **A Legendary starts a build.** It changes what you build or where, gives you a shape or
  condition to aim for, and drives your next choices. No flat stat cards.
- **No card Needs.** A Legendary never requires other cards (or a count of them, or a board state):
  it can turn up in any act 2+ offer and you pivot toward it. Commons, Uncommons and Rares are the
  **enhancers**; they keep their Needs, because they deepen a build you already have.
- **It works on its own.** If a Legendary is about a mechanic, it brings that mechanic with it
  (e.g. a Marked Legendary makes your Wardens apply Marked), so it's never a dead card in a run
  without the right Warden family.
- **One archetype.** It belongs to a single archetype (nurture, crit, potency, maze, narrow, wide, a
  status, walls…) and never mixes in another's mechanic. Mixing is what Entwined (Rare) cards do.
- **After you take one,** its archetype counts as an owned family for tag weighting (2×), so the
  enhancers for it start to show up.
- **Cards that enhance one Warden or one combo aren't Legendary.** Thousand Cuts, Seed Storm and
  the Woven cards moved to Rare (2026-09-28).

| # | Card | Effect | Tags | Pool |
|---|---|---|---|---|
| 34 | **The Long Walk** | +1% soothe per 4 path tiles | maze | Grove |
| 35 | **Rootbound** | Wardens touching 3+ other Wardens attack twice | maze | Grove |
| 36 | **Monoculture** | if all your attacking Wardens are one line: +60% soothe | — | Grove |

### New Legendaries: builds to play around (2026-09-28)

User-approved set, written to the Legendary rules above: no card Needs, each brings its own
mechanic, one archetype each. All act 2+ (`min_act` 2), max 1. **Pool: Start for now** so they can
be playtested; where each sits in the Memory Grove is for `meta_design.md` to decide later.
"Touching" = the 8 cells around a Warden, as for Rootbound.

| # | Card | Archetype (tag) | Effect | You build around |
|---|---|---|---|---|
| 113 | **Crossroads** | maze | a Warden touching **two path tiles at least 6 steps apart along the route** gets **+40% damage** | hairpin mazes that fold back past the same Wardens |
| 114 | **Briar Crown** | wall | when a nightmare walks onto a path tile beside a Thornwall, it takes **25% of the damage of the strongest attacking Warden touching that Thornwall** (once per wall per nightmare per second) | corridors lined with walls, with Wardens behind them |
| 115 | **Menagerie** | variety | all Wardens **+8% damage per different attacking Warden kind** on the map (max +80%) | one of everything; the opposite of Monoculture |
| 116 | **Restless Night** | tempo | **+8% damage for each drift you call early** this block (max +40%); resets at each rest | calling every drift early |
| 117 | **Last Leaf** | leaves | all Wardens **+6% damage per leaf below your max** (max +60%) | playing close to losing |
| 118 | **Lucid Dreaming** | dreams | Dream offers show **4 cards and you take 2**; **Commons are no longer offered** | drafting two halves of a combo at once |
| 119 | **Court of the Eldest** | nurture | your highest-rank Warden becomes **the Eldest** now (ties: nearest the Heartwood; if nothing is ranked, the next Warden you nurture). Wardens touching the Eldest get **25% of its rank bonuses** | a ring of Wardens around one great one |
| 120 | **Hunter's Moon** | mark | each Warden's **first hit on a nightmare Marks it**; Marked **never expires**; when a Marked nightmare is dispelled, the **2 nearest within 3 cells** become Marked | marking at the maze's entrance, damage behind |
| 121 | **Eternal Charge** | storm | **every 4th hit** from any Warden adds **1 Static**; Static **never decays** | long mazes that build charge on every nightmare |
| 122 | **Rooted Nightmares** | held | **every 8th hit** from a Warden **Holds** for 1 s (bosses 0.5 s); a Held nightmare **blocks its cell**: other walkers re-route around it, or wait if there's no way round | a maze that grows while it runs |
| 123 | **Wildwood Reclaimed** | clearing | **unlocks clearing** (counts as a clearing card); Wardens on cells you've cleared get **+30% damage, +2% per obstacle cleared this run** (max +60%) | clearing exactly where your best Wardens will stand |

- **Crossroads:** "steps apart" = the difference between the two tiles' positions along the current
  route. Live: recomputed on `path_changed`, and the Warden's panel shows "Crossroads: +40%".
- **Briar Crown:** the damage uses that Warden's line (resists / weak apply), counts as area, never
  crits. With no attacking Warden touching the wall, it does nothing. It fires on flyers only if
  they pass over the tile.
- **Menagerie:** counts kinds by Warden id (a Stormcap and a Thunderhead are two kinds); Thornwalls
  don't count.
- **Restless Night:** only a real call early counts (the next drift started while the previous one
  was still arriving). The bonus shows on the Dreams row icon.
- **Last Leaf:** live; regrowing leaves lowers it again. The max is +60% at 10 leaves down.
- **Lucid Dreaming:** if fewer than 4 cards qualify, show what there is. Both picks count as Dreams
  taken; "Let it pass" still skips the whole offer. Growth-slot and Entwined guarantees still apply
  to one of the 4.
- **Court of the Eldest:** it **names** the Eldest (the rules in *The Eldest* apply) but doesn't
  raise the rank cap; Deeper Rings / Endless Rings do. "Rank bonuses" = the per-rank damage, attack
  speed and range, not the Focus.
- **Hunter's Moon:** the Marked it applies is normal Marked (+25%; Beacon's +35% still wins).
  Bosses are Marked too.
- **Eternal Charge:** the free bolt uses the soothe of the Warden that added the 5th stack. Bosses
  still bolt at 8.
- **Rooted Nightmares:** flyers ignore blocked cells. Waiting walkers never stack in one cell; if a
  Held nightmare would trap one, it waits (no damage to the rule that a path always exists). Held
  still halves on bosses.
- **Wildwood Reclaimed:** Seeds for clears are unchanged; Reclaimed Earth's fertile discount stacks
  with it.

## Crit cards

Added 2026-09-27 with the crit mechanic (`tower_design.md`, "Critical hits"). Crit chance stacks
additively like other stats.

| # | Card | Rarity | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|---|
| 37 | **Glinting Dew** | Common | all Wardens +4% crit chance (stacks) | crit | — | Start |
| 38 | **Heavy Stones** | Common | Pebbling line +8% crit chance (stacks) | stone, crit | Pebbling | Start |
| 39 | **Sharpened Light** | Uncommon | all Wardens +0.5 crit multiplier | crit | — | Start |
| 40 | **Still Target** | Uncommon | +15% crit chance vs Drowsy, Held or frozen nightmares | crit, sleep | a Warden that applies Drowsy, Held or frost (Bloomcap, Rootling line, Frostfern, Honeysuckle) | Grove |
| 41 | **Shattering Blow** | Rare | crits splash 50% of their damage to nightmares within 1 cell | crit | — | Grove |
| 42 | **Starlit Aim** | Rare, **Entwined** (Standing Stone + Lanternmoth) | Marked nightmares take +25% crit chance from every Warden | crit, mark | — | Grove |
| 43 | **Full Moon** | Legendary | all Wardens +10% crit chance; crit chance **above 100%** becomes crit damage (each 1% over = +1% crit multiplier) | crit | — | Grove |
| 44 | **Reckless Bloom** | Uncommon, **Bittersweet** | all Wardens +20% crit chance. **Cost:** hits that don't crit do −15% damage | crit, bittersweet | — | Grove |

Deepened: **Sharpened Light II** +1.0 multiplier; **Still Target II** +25%; **Shattering Blow II**
splash 75% within 1.5 cells.

## Potency cards: effect damage

Added 2026-09-27 with Potency (`tower_design.md`, "Potency: effect damage"). The mirror of the crit
cards: crit cards grow hits, these grow effects (Spored, Static bolts, clouds, fog, Reactions).

| # | Card | Rarity | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|---|
| 109 | **Bitter Sap** | Common | all Wardens +8% Potency (stacks) | potency | — | Start |
| 110 | **Seeping** | Uncommon | effects deal **+5% per status** the nightmare carries (max +30%) | potency, reaction | any 2 status families | Grove |
| 111 | **Venom Bloom** | Uncommon, **Bittersweet** | all Wardens +30% Potency. **Cost:** hits do −15% damage | potency, bittersweet | — | Grove |
| 112 | **Nightshade** | Legendary | effects deal **+20% damage for every status** the nightmare carries (**no cap**) | potency | — | Grove |

Deepened: **Seeping II** +7% per status (max +42%).

**Nightshade** (reworked twice on 2026-09-28; user-approved). The Legendary version of Seeping: the
build is "load every nightmare with as many statuses as you can, then let effects do the work".
- **Effects** = effect damage as defined above: Poisoned ticks, Charged bolts, clouds, fog and
  Reactions. Hits aren't effects, so hits get nothing.
- **Every status counts**, damaging or not (Soaked, Drowsy, Marked, Held, Poisoned, Charged, …),
  including the one that's dealing the damage. One count per status, not per stack.
- **No cap:** it's naturally limited by how many statuses exist (all of them at once ≈ +140%).
- **Stacks with Seeping** (both add: 4 statuses = +80% + 20%).
- Shown live on the nightmare's info card ("Nightshade +60%").
- *History:* first "+15% Potency, effect ticks can crit" (mixed in crit); then "effects tick
  together" (only Poisoned and Charged tick, so it became a two-status card).

## Cards for the new Wardens

Each hidden branch, final form and full-game family brings its own cards (the "6–8 per family"
target in *Pool size*). Branch and final-form unlock cards follow the usual pattern (Uncommon
branch, Rare final); only the extra cards are listed here.

| # | Card | Rarity | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|---|
| 45 | **Skipping Stones** | Uncommon | Pebbling-line shots bounce once to another nightmare in a straight line behind the target (60%) | stone, maze | Pebbling | Grove |
| 46 | **Long Shadows** | Uncommon | Wardens with range 5+ get +2 range | range | Standing Stone or Lanternmoth | Grove |
| 47 | **Patient Aim** | Uncommon | +15% damage per second a Warden hasn't fired (max +60%) | crit, stone | Standing Stone | Grove |
| 48 | **Ring Dance** | Rare, **Entwined** (Fairy Ring + Driftspore) | a Fairy Ring burst sets off any ring within 2 tiles | spore, trap | — | Grove |
| 49 | **Deep Frost** | Uncommon | frozen nightmares take +20% damage | water, crit | Frostfern | Grove |
| 50 | **Carried on the Wind** | Rare, **Entwined** (Gust + any status branch) | Gust and Zephyr copy **full** stacks | wind | — | Grove |
| 51 | **Sweet Scent** | Uncommon | Honeysuckle Drowsy also applies to nightmares 2 tiles away | wall, sleep | Honeysuckle | Grove |
| 52 | **Shiny Things** | Uncommon | Magpie Wardens' Dew caps +10 per drift | wing, economy | Magpie Perch | Grove |
| 53 | **Hairpin Winds** | Uncommon | Pinwheel and Windmill +1 max adjacent path tile bonus (to +120%) | wind, maze | Pinwheel | Grove |

**Honeysuckle** unlock card: Uncommon, like Bramble (*"Thornwalls can grow into Honeysuckle
(+10 Dew each)"*), Start pool.

| 59 | **Chain Bloom** | Rare, **Entwined** (Puffball + Mistveil) | spores spread by a Puffball pop can **pop their new host too** if that pushes it to 10+ stacks (each nightmare pops once per chain). The Spore Bomb build's key card (`tower_design.md`) | spore | Grove |

*(Chain Bloom's rule hook, `rule_id = "chain_bloom"`, is already in the code since the Puffball pop,
commit 56634f8.)*

## Cards from the family review (2026-09-27)

Cards for Bellflower (new family), Cairn, Hummingbird Bower and Samara (`tower_design.md`). Per
the Grove rules, family-specific cards come with their family or hidden-branch node.

**Bellflower (song and sleep)**

| # | Card | Rarity | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|---|
| 84 | **Hush** | Common | Bellflower-line pulses +15% radius (stacks, max +45%) | song, sleep | Bellflower | family |
| 85 | **Heavy Eyelids** | Uncommon | Drowsy cap +2 for all nightmares (bosses +1) | song, sleep | any Drowsy Warden | family |
| 86 | **Bad Dreams** | Uncommon | Caught nightmares also take 1 Drowsy per second, so they stay Caught | song, sleep | Dreamcatcher | family |
| 87 | **Encore** | Rare, **Entwined** (Echo Hollow + any Reaction card) | an echo can echo once more, at half strength | song, reaction | — | hidden node |

**Pebbling (Cairn)**

| # | Card | Rarity | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|---|
| 88 | **Loose Stones** | Uncommon | Cairn and Rockslide stones break into 3 on landing: 35% each onto random tiles within 1.5 cells | stone | Cairn | hidden node |

**On-hit (Hummingbird Bower; also helps Wren's Nest, Samara and any Warden that hits often)**

| # | Card | Rarity | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|---|
| 89 | **Sharp Beaks** | Common | multi-hit Wardens (Hummingbird, Wren's Nest) +1 hit per attack (stacks, max +3) | wing, on-hit | Hummingbird Bower or Wren's Nest | hidden node |
| 90 | **Needle Point** | Uncommon | multi-hit Wardens' hits **ignore dread shell** reduction | wing, on-hit | Hummingbird Bower | hidden node |
| 91 | **Charged Feathers** | Rare, **Entwined** (Hummingbird Bower + Firefly Jar) | each peck applies **1 Static** | wing, storm, on-hit | — | hidden node |
| 92 | **Pollen Beaks** | Rare, **Entwined** (Hummingbird Bower + Sporeling) | each peck applies **1 Spored** | wing, spore, on-hit | — | hidden node |
| 93 | **Thousand Cuts** | Rare *(was Legendary; enhances one Warden, 2026-09-28)* | every hit on the same nightmare within 2 s gives **all Wardens** +2% damage against it (max +60%) | on-hit | Hummingbird Bower | hidden node |

**Boomerang (Samara)**

| # | Card | Rarity | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|---|
| 94 | **Longer Flight** | Common | Samara line +1 cell (stacks, max +3) | wind, maze | Samara | hidden node |
| 95 | **Backspin** | Uncommon | the **return pass** gets +25% crit chance | wind, crit | Samara | hidden node |
| 96 | **Ricochet** | Uncommon | at the end of its line the seed **turns 90° once** toward the nearest nightmare before returning (rewards L-shaped corners) | wind, maze | Samara | hidden node |
| 97 | **Heavy Seed** | Uncommon | each pass knocks nightmares back 0.25 tiles (once per throw) | wind | Samara | hidden node |
| 98 | **Windborne Rain** | Rare, **Entwined** (Samara + Rain Lily) | every pass applies **Damp**, so the line becomes a Thunderclap corridor | wind, water, reaction | — | hidden node |
| 99 | **Seed Storm** | Rare *(was Legendary; enhances one Warden, 2026-09-28)* | every 5th throw bursts into **5 seeds in a fan** | wind | Samara | hidden node |

Deepened: **Heavy Eyelids II** cap +3 (bosses +1); **Ricochet II** turns twice; **Bad Dreams II**
2 Drowsy per second.

As built (a9ba4b6): Ricochet's turned leg is **half the line's length**; Sharp Beaks on Wren's Nest
adds extra hits per swoop.

## Clearing cards: removing obstacles

Added 2026-09-27. Obstacles (Withered Trees, Mossy Boulders, later Blight Patches) are the dream's
dead places; clearing them costs Dew, gives +1 Seed each at run end (`run_design.md`) and frees
building space, but often **opens shortcuts for the nightmares**. These cards make clearing a real
build direction with that trade-off intact.

**Clearing is locked until you take one of these cards** (decided 2026-09-27). Until then,
obstacles are fixed terrain you plan around. **Taking any clearing card (54–58) unlocks clearing
for the rest of the run**, at the normal cost (5 / 8 Dew) plus that card's effect. To keep the
option reachable, clearing cards get **2× weight until you own one** (on maps with 8+ obstacles),
and **all of them are Common except Burn Back** (user decision, 2026-09-27), so clearing shows up
early and often.

| # | Card | Rarity | Effect | Tags | Pool |
|---|---|---|---|---|---|
| 54 | **Cleared Ground** | Common | clearing obstacles costs **40% less** Dew (stacks, minimum 1 Dew) | clearing, economy | Start |
| 55 | **Heartwood's Reach** | Common | gain **4 free clears**; use them any time (a charge counter on the HUD; unused charges last all run). Deepened II: 7 | clearing | Start |
| 56 | **Reclaimed Earth** | Common | each obstacle you clear gives **+8 Dew**, and the cell is left **fertile**: the first Warden planted there costs 50% less | clearing, economy | Start |
| 57 | **Tended Forest** | Common | **+1% damage for every obstacle cleared this run** (max +25%; clears from before the card count) | clearing, maze | Start |
| 58 | **Burn Back the Dead Wood** | Rare, **Bittersweet** | clear **every Withered Tree** on the map right now. **Cost:** nightmares +10% speed for the rest of the run | clearing, bittersweet | Grove |

- **Offered only when it matters:** clearing cards need at least **8 obstacles** left on the map
  (Burn Back needs 8 Withered Trees). They lean toward early Dreams, when the map is still full.
- **Seeds:** free clears (Heartwood's Reach) still give +1 Seed each. **Burn Back doesn't**: clearing
  dozens of trees at once would otherwise flood the meta with Seeds.
- **Burn Back and the other cards:** its clears **don't trigger Reclaimed Earth** (no +8 Dew, no
  fertile cells), for the same reason. They **do count for Tended Forest** (it's capped at +25%, so
  that combo is a fair payoff).
- **Heartwood's Reach II** brings the total to **7 charges** (+3 when taken), not +7: Deepened
  replaces the base effect.
- **Settled in implementation:** Cleared Ground stacks add (−40%, −80%, then the 1 Dew minimum);
  free clears are used before Dew; Burn Back's speed cost applies to bosses too; Burn Back is act 2+
  like other Bittersweet cards.
- **Path rule:** clearing only ever opens routes, so every card is always safe; the preview line
  shows the new route before a clear, as now.
- **Pairs well with:** Hedge Maze and Thornwalls (clear the forest, then build your own walls where
  you want them), The Long Walk (more space for a longer maze), Cozy Corners.
- **Data:** `RunState` gets a `free_clears` counter and a set of fertile cells; clear cost goes
  through one function so Cleared Ground stacks apply everywhere; `Burn Back` is a one-shot effect
  + a permanent nightmare speed modifier.

## Nurture cards: growing tall

Added 2026-09-27, for Nurture ranks (`warden_stats.md`, "Ranks: Nurture"; **Nurture v2**: rank I–V,
15 / 25 / 40 / 60 / 90 Dew × the Warden's tier multiplier, each rank +10% damage, +4% attack speed,
+0.1 range, a Focus at rank III, kept through evolution).
Nurture is the "tall" direction, putting Dew into few Wardens instead of more space. These cards
make it a build choice without breaking its rule: **ranks stay less Dew-efficient than evolving**.
Evolving is still the better buy when a Dream allows it; Nurture cards make ranks the better buy
**when the map is full or growth Dreams haven't come**.

| # | Card | Rarity | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|---|
| 60 | **Tender Care** | Common | Nurturing costs **15% less** Dew (stacks, max −45%) | nurture, economy | *opener:* 30+ Dew spent on ranks | Start |
| 61 | **Warm Hands** | Common | each Nurture rank gives **+3% more damage** (10% → 13%; stacks) | nurture | *opener:* 30+ Dew spent on ranks | Start |
| 62 | **Kindred Roots** | Uncommon | each Warden gets **+2% damage per rank of the Wardens touching it** (max +30%) | nurture, maze | any `nurture` card + 2 ranked Wardens | Start |
| 63 | **Remembered Care** | Uncommon | selling a ranked Warden leaves a **memory seed** on the HUD; the next Warden you plant starts at that rank (one seed at a time, the highest one is kept) | nurture | any `nurture` card + a rank III+ Warden | Start |
| 64 | **Sunlit Rest** | Uncommon | at every rest, your ranked Warden **nearest the Heartwood** that isn't at max rank gains a free rank | nurture | any `nurture` card | Grove |
| 65 | **Deeper Rings** | Rare | **one Warden, the Eldest,** can grow past V to rank **VII**: VI costs 130, VII costs 180 (same gains per rank) | nurture | any `nurture` card + a rank V Warden | Grove |
| 66 | **Nursery** | Rare, **Entwined** | Seedling Gift's free Sprouts arrive at **rank II**, and Sprouts nurture for half price | nurture, sprout | Tender Care + Seedling Gift | Grove |
| 67 | **The Old Ones** | Legendary | rank V+ Wardens make the Wardens touching them count **one rank higher** (doesn't stack with itself). *(2026-09-28: the "+2% crit chance per rank" half was removed: one archetype per Legendary)* | nurture | — | Grove |
| 68 | **Chosen Few** | Rare, **Bittersweet** | rank V+ Wardens **+50% damage**. **Cost:** Wardens below rank III do −15% damage | nurture, bittersweet | a rank V Warden | Grove |
| 108 | **Endless Rings** | Legendary | **the Eldest has no max rank.** Past VII, each rank costs **×1.2** the one before (VIII 216, IX 259, X 311, … × tier) and gives **+10% damage** | nurture | — (taking it makes the Eldest available, like Deeper Rings) | Grove |

**Endless Rings** (added 2026-09-27, user idea: "infinite Nurture once you reach rank VI"). The tall
build's capstone and the run's last Dew sink.
- **Damage only past VII.** Attack speed and range stop at VII (endless range would cover the whole
  23×18 map, and endless speed breaks attack animations); the Focus bonus stops at V as always.
- **Soft cap by design:** each rank adds a flat +10% damage, while its cost grows 20%. Ranks VIII–XII
  on a base Warden cost ~1,600 Dew for +50% damage, so you stop when another Warden or growth is the
  better buy, and there's always *something* to put late Dew into.
- **Free ranks stop at VII:** Sunlit Rest, Nursery and The Old Ones' neighbour bonus never give a
  rank above VII. Only Dew buys endless ranks.
- **Shown as** the rank VII art plus a Roman numeral ("XII") on the Warden, and in its panel.
- **Grove:** joins The Old Ones at the tip of the Tending branch (`meta_design.md`).

**The Eldest** (user decision, 2026-09-28: "only one tower can have them, to make it fair"). Ranks
above V belong to **one Warden per run**, the Eldest:
- The **first Warden you nurture to rank VI** becomes the Eldest. Its panel asks you to confirm
  ("Make this the Eldest? Only one Warden can grow past rank V"), since the choice is lasting.
- While the Eldest lives, every other Warden stops at rank V; their panels say "Only the Eldest
  grows further".
- **Kept through evolution** (a rank VI Stormcap growing into a Thunderhead stays the Eldest).
- **If you sell the Eldest,** the title is free again and the next Warden nurtured to VI takes it.
  Its ranks above V are lost; with Remembered Care the seed holds at most rank V.
- **Shown as** a small crown of rings on the Warden and "Eldest" in its panel.
- **Why:** rank VII or endless ranks on every Warden would make every late run a Nurture run. One
  Eldest makes it a build: you pick the Warden, the spot and the line, and shape the maze around it
  (Cozy Corners bends, Kindred Roots neighbours, Marked nightmares fed to it). The Old Ones'
  neighbour bonus and Chosen Few still work on every rank V Warden.

- **Openers and follow-ups** (see *Card requirements*): Tender Care and Warm Hands are the
  **openers**, offered once you've **spent 30+ Dew on ranks** this run (a "you've tried it" gate,
  like the 8-obstacle rule for clearing cards). Everything else is a **follow-up** that also needs an
  opener (or any other `nurture` card) plus the rank it pays off. Chosen Few is the exception: a
  Bittersweet card can tempt you into the direction, so it only needs the rank V Warden.
- Once you own any `nurture` card, the tag counts as an owned family for tag weighting (2×).
- **Walls and auras** can't be nurtured, so none of these cards touch them. Kindred Roots counts
  the ranks of neighbours that *have* ranks; a Thornwall neighbour gives 0.
- **Dew-efficiency check (Nurture v2):** rank V on a base Warden with 3× Tender Care costs 127 for
  ~1.8×; on a final form, 380. A branch costs 45 for ~2×. Evolving still wins on Dew; ranks win on
  space. Deeper Rings (VI and VII, also × tier) is a late-run Dew sink on purpose.
- **Remembered Care** makes rearranging the maze painless for a tall build: sell a rank V to move
  it and the next plant is rank V again (it still costs the plant's normal Dew). **The rank Dew goes
  into the seed, not back to you** (fix, 2026-09-27): selling a ranked Warden while Remembered Care
  makes a seed refunds only its build and growth Dew. Otherwise sell + replant is a Dew machine (a
  rank V refunds ~170 Dew at a rest, then comes back for free). If the seed is later replaced by a
  higher one, that Dew is lost. The seed survives
  the run save. It's shown as a small glowing seed next to the Dew counter.
- **Sunlit Rest** picks the Warden nearest the Heartwood by path distance (the same order as group
  Nurture). If none is ranked, nothing happens (you need to nurture once first).
- **The Old Ones' neighbour bonus** counts for stats only (not for Deeper Rings' cap, not for Chosen
  Few's rank V check), so it can't chain.
- **Deepened:** **Kindred Roots II** +3% per rank (max +45%); **Remembered Care II** keeps two seeds;
  **Sunlit Rest II** two Wardens per rest.
- **Data:** `DreamState` gets `get_nurture_cost_multiplier()`, `get_rank_damage_bonus()`,
  `get_max_rank()`. `Tower.get_nurture_cost()` / `RANK_MAX` read those instead of constants.
  `RunState` holds the memory seeds.

## Wide and narrow: many Wardens or few

Added 2026-09-27 (user request): two build directions defined by **how many** Wardens you have.
They pair with the Nurture cards above: *wide* spends Dew on count, *narrow* spends it on ranks.
Only **attacking** Wardens count; Thornwalls never do, so a narrow build still gets a long maze
from walls (Hedge Maze, Bramble).

**Wide: the Overgrowth** (flood the maze with cheap Wardens)

| # | Card | Rarity | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|---|
| 69 | **Seedfall** | Common | Sprouts cost **6** Dew (was 10) | sprout, wide | — | Start |
| 70 | **Many Hands** | Uncommon | all Wardens **+1% damage per 4 attacking Wardens** you have (max +25%) | wide | 15+ attacking Wardens | Start |
| 71 | **Sprout Chorus** | Uncommon | Sprouts **+5% attack speed per other Sprout within 2 cells** (max +40%) | sprout, wide | 6+ Sprouts | Start |
| 72 | **Canopy** | Rare | when you reach **20, 30 and 40** attacking Wardens (planted this run), every Warden gets **+8% damage** permanently, each time | wide | 15+ attacking Wardens | Grove |
| 73 | **Overgrowth** | Rare, **Bittersweet** | planting any Warden costs **30% less**. **Cost:** Wardens can't be nurtured past rank I | wide, bittersweet | — | Grove |

**Narrow: the Lone Lantern** (a few Wardens, very strong)

| # | Card | Rarity | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|---|
| 74 | **Solitude** | Uncommon | a Warden with **no other attacking Warden within 2 cells** gets **+30% damage and +0.5 range** | narrow, maze | — | Start |
| 75 | **Few and Mighty** | Rare | all Wardens **+8% damage for each attacking Warden below 12** you have (7 Wardens = +40%; max +80%) | narrow | 12 or fewer attacking Wardens when offered | Start |
| 76 | **The Last Light** | Legendary | if you have **5 or fewer** attacking Wardens, they **attack twice as fast** | narrow | — | Grove |

- **Once you own a wide or narrow card, its tag counts as an owned family** for tag weighting (2×),
  so the direction you start tends to come together. Owning one direction makes the other's cards
  **half as likely** (they'd work against each other), but never impossible.
- **Few and Mighty and The Last Light** are live values: selling or planting changes the bonus
  immediately (shown on the card icon in the Dreams row).
- **Pairs with:** narrow + Nurture (Chosen Few, Deeper Rings) + Standing Stone snipers + Hedge Maze;
  wide + Seedling Gift, Nursery, Rootbound, Grove Heart, Elder Stump.
- **Balance check:** wide should out-damage narrow early (cheap Dew-efficiency) and narrow should
  catch up late (ranks + multipliers, and it saves map space for walls). Compare both in the Test
  Grove with the damage meter at drifts 25 and 50.

## Dreamlight cards

Added 2026-09-27 with Dreamlight (`run_design.md`). Cards may *add* Dreamlight, never replace it.

| # | Card | Rarity | Effect | Tags | Pool |
|---|---|---|---|---|---|
| 77 | **Sudden Insight** | Uncommon | **+1 Dreamlight** now | dreamlight | Start |
| 78 | **Borrowed Memory** | Rare, **Bittersweet** | **+2 Dreamlight** now. **Cost:** −2 max leaves | dreamlight, bittersweet | Grove |

## Deepened cards: repeats become upgrades

Added 2026-09-27. With 19 Dreams from a 33-card pool, repeats are common. Stat cards already
stack; now **rule cards** can come back too, as a stronger **Deepened** version ("II").

- A Deepened card can only be offered if you own the base card. Same rarity and weight as the base.
  Each card deepens **once** (no III).
- Taking it replaces the base effect with the Deepened one. It's not a new slot.
- Branch cards, final-form cards and Legendaries don't deepen. They're a direction, not a number.

| Card | Base | Deepened (II) |
|---|---|---|
| Cozy Corners | +15% soothe beside a bend | +25%, and bends up to 2 tiles away count |
| Hedge Maze | +1% per 5 Thornwalls (max 20%) | +1% per 4 Thornwalls (max 30%) |
| Evergreen | evolving −25% Dew | evolving −40% Dew |
| Lingering Spores | Spored +3 s | Spored +5 s, and max stacks +2 |
| Soaked Through | Damp lasts ×2 | Damp lasts ×3 and slows −15% instead of −10% |
| Twin Puff | every 3rd Sporeling attack fires twice | every 2nd |
| Charged Bloom | Stormcap chains apply 1 Drowsy | apply 2 Drowsy |
| Spore Cascade | spreads to the 2 nearest | spreads to the 3 nearest |
| Charged Field | bolts also hit within 1 tile | within 1.5 tiles, and splashed creatures gain 1 Static |
| Guiding Light | Marked spreads within 1 tile | within 2 tiles |
| Seedling Gift | a free Sprout at every rest | a free Sprout, or a free Sprout → base growth, at every rest |

## Entwined cards: combos that come together

Added 2026-09-27. Some Rares are **Entwined**: they list 2 ingredients (cards or Wardens), and
**once you own every ingredient, the Entwined card is guaranteed in your next Dream offer** (one
slot; if you pass on it, it goes back to normal weight). This is the main lever for build
reachability (Storm Grid sims at ~6–10% vs the 33% target). It replaces the plain "Needs"
prerequisite on these cards.

| Entwined card | Ingredients | Replaces "Needs" |
|---|---|---|
| **Conductive Soil** | Stormcap + Rain Lily | Firefly Jar + Dewdrop |
| **Charged Bloom** | Stormcap + Bloomcap | Stormcap |
| **Spore Cascade** | Driftspore + Lingering Spores | Sporeling |
| **Guiding Light** | Lanternmoth + Cozy Corners | Lanternmoth |

- The card UI shows the ingredients (small icons) so players can plan toward a combo.
- An Entwined card shows up in the offer with a vine border and "Entwined" under its name.
- **Re-run the Storm Grid simulation** (`tests/test_dreams.gd`) with this rule. If it overshoots
  33%, loosen "guaranteed" to "2× weight"; if it's still short, also make Entwined ingredients get
  1.5× weight once you own one of the two.
- New families (Pebbling, Rootling, Acorn) should each bring at least one Entwined card that crosses
  into an existing family.

## Bittersweet cards

Un-parked 2026-09-27, but **only enter the pool once leaves are tuned** (`run_design.md`, "To check
in playtests"). Big upside, a real cost that lasts all run. Tag `bittersweet`, 1 each, Uncommon or
Rare, act 2+ (`min_act` 2). At most one bittersweet card per offer. The cost is always shown in
its own line on the card, in a muted plum colour.

| Card | Rarity | Upside | Cost |
|---|---|---|---|
| **Deep Sleep** | Rare | all Wardens +40% soothe | −4 max leaves (and lose them now) |
| **Borrowed Dew** | Uncommon | +150 Dew now | rest bonus −15 for the rest of the run |
| **Wild Growth** | Uncommon | evolving −40% Dew | creatures +10% health |
| **Overgrown** | Rare | all Wardens +1 range | no selling while creatures are walking |
| **Restless Dreams** | Rare | the next 3 Dreams each include a Rare+ card | *Let it pass* is gone for the run |
| **Hungry Roots** | Uncommon | all Wardens +25% attack speed | Thornwalls cost 6 |

Bittersweet cards are also the natural home for Blight-Level rewards (a Level could add "every
boss Dream includes one bittersweet card").

## Reachability check: Storm Grid

Storm Grid = Dewdrop/Rain Lily + Firefly Jar/Stormcap/Thunderhead + *Conductive Soil*.
Needs: **2 families** (Dewdrop, Firefly Jar) + **4 Dreams** (Rain Lily, Stormcap, Thunderhead,
Conductive Soil) out of 19.

- **Families are now the bottleneck.** With all 6 families in the game, the first pick offers 3 of
  6 and each boss 3 of the rest, so getting both specific families by drift 50 happens in roughly
  **70%** of runs if you aim for it.
- **The Dreams are easy** with 19 of them, tag weighting, and guaranteed Rares at bosses. Conductive
  Soil is now Entwined (Stormcap + Rain Lily), so it's guaranteed once both are owned.
- **Target (restated for 100 drifts):** a deliberate dream build is **complete by the act 2 boss
  (drift 50) in about 1 run in 3**, and most runs finish *some* complete build by act 4. The
  original "1 in 3" goal now describes the mid-run; long runs naturally let more builds finish.
  Verify with an offer simulation once `UpgradeData` exists; tune tag weighting (2×) and the family
  offers to hit it.

## Status effect numbers

Status strength **scales with the Warden that applies it** (a % of its soothe), so statuses keep
up with creature health and benefit from stat Dreams and evolutions.

| Status | Effect | Duration | Stacks | Notes |
|---|---|---|---|---|
| **Damp** | −10% speed | 4 s, refreshed on reapply | no | Rain Lily 6 s; Mistveil fog keeps it on |
| **Drowsy** | −8% speed per stack | 3 s, refreshed | up to 5 (−40%) | Dreamshroom: at 5 stacks, sleep 1.5 s, once per creature |
| **Spored** | soothe per second per stack = 25% of the applier's soothe | 5 s, refreshed | up to 8 (Driftspore 12) | Puffball pops at 10+ |
| **Marked** | +25% soothe taken from all sources | 5 s | no | Beacon +35% |
| **Static** | a charge; at 5 stacks, a free bolt worth 3× the applier's soothe, then reset | loses 1 stack per 2 s | up to 5 | |
| **Held** | can't move | 1 s | no | not in first-playable scope (Rootling line) |

**Bosses:** Drowsy cap 3, Held duration halved, Static bolts at 8 stacks instead of 5.

## Reaction numbers

Design and effects: `tower_design.md`, "Reactions". Starting points for tuning.

**Rules**
- A Reaction fires the moment a nightmare has **both** statuses (either order) at the listed
  threshold.
- **"Applier"** = the Warden whose status or hit completed the Reaction. Reaction damage scales with
  its damage, so Reactions keep up with the ×30 health of act 4 and benefit from stat Dreams.
- Reaction damage counts as the **applier's family** for resist/weak, and Marked applies. Reactions
  themselves **don't crit** (they're status damage); Shatter and Pinned change a *hit*, and that
  hit can.
- **Cooldown:** each Reaction type can fire on the same nightmare at most once per **1.5 s**.
- **Bosses** take full Reaction damage but get reduced control (below).

| Reaction | Trigger | Effect | Uses up | Bosses |
|---|---|---|---|---|
| **Thunderclap** | Damp + 3 Static | 4× applier damage to the target; arcs to every Damp nightmare within **2.5 cells** for 2×, each arc adds **1 Static** | all Static | Static threshold 5 |
| **Ignite** | 3+ Spored + any Static | deals the target's **remaining Spored damage ×1.5** at once; 1 Spored stack to nightmares within 1 cell | all Spored | same |
| **Mushrooming** | 3+ Spored + Damp | the target's Spored ticks +50% for 4 s; a spore cloud (radius 0.6, 4 s) on its tile gives 1 Spored per second | Damp | same |
| **Shatter** | Held (incl. frozen) + Damp, then a crit or a hit from the Pebbling line or a sniper | that hit ×2.5; shards deal 50% of it to nightmares within 1 cell | Held | same (Held is already halved) |
| **Drown** | Damp + 5 Drowsy | sleeps **2 s**, once per nightmare | all Drowsy | no sleep: −30% speed for 2 s instead |
| **Pinned** | Marked + (Held or 5 Drowsy) | the next hit is a guaranteed crit at **×3** (or the hitter's multiplier if higher) | Marked | same |
| **Smother** | Held + 1+ Spored | Spored ticks 3× as fast while Held | — (ends with Held) | same |
| **Lightning Rod** | Marked + 1+ Static | Static bolts (5-stack bolts and Thunderclap arcs) within **3 cells** strike the Marked nightmare instead, at ×2 | — (while Marked) | same |

- On a Damp nightmare, Static never reaches its normal 5-stack bolt: Thunderclap fires at 3 first.
- **Chains:** a Reaction caused by another Reaction's output within 1 s adds +1 to the chain. So
  does a different Reaction on the **same nightmare** within 1 s (e.g. Drown → Pinned = ×2), as
  built.
  Chains are visual and tracked; they add no damage of their own (the Legendary *Dawnbreak* below
  changes that).
- **Performance:** at most ~6 full Reaction effects per second; the rest use the `_lite` sheets.
  Rules always apply in full; only visuals are capped.

## Reaction cards

| # | Card | Rarity | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|---|
| 79 | **Rolling Thunder** | Uncommon | Thunderclap arcs reach 3.5 cells | storm, water, reaction | Stormcap + any Dewdrop | Start |
| 80 | **Wildfire Spores** | Uncommon | Ignite spreads 2 stacks, within 1.5 cells | spore, storm, reaction | Sporeling + Firefly Jar | Grove |
| 81 | **Deep Water** | Uncommon | Drown sleeps 3 s; bosses −40% speed | water, sleep, reaction | Dewdrop | Grove |
| 82 | **Quick Reactions** | Rare | Reaction cooldowns 1.5 s → 0.75 s | reaction | own 2 Reaction pairs | Grove |
| 83 | **Dawnbreak** | Legendary | a **×10 chain** Dawnburst deals 10% of max health to every nightmare within 4 cells (bosses 2%) | reaction | — | Grove |

- *Conductive Soil* (Entwined, Rare) now also means **Thunderclap arcs reach every Damp nightmare
  in the Warden's range**, not just 2.5 cells. It's the Storm Grid capstone.
- Deepened: **Rolling Thunder II** arcs 4.5 cells and add 2 Static; **Deep Water II** Drown can
  happen twice per nightmare.

## Crowned Reaction numbers

Design: `tower_design.md`, "Crowned Reactions". A Crowned Reaction **replaces** its base Reaction
when the third status is present (same trigger, same cooldown, uses up the same statuses). Damage
scales with the applier, as for Reactions. Each counts as **2 chain links**.

| Crowned | Effect | Bosses |
|---|---|---|
| **Tempest** | Thunderclap as normal; each arc also fires **Ignite** on Spored targets (normal Ignite numbers); Ignite's spread stacks carry **1 Static** each. A nightmare hit by a Tempest can't start another Tempest for **2 s** | arcs don't Ignite bosses; they still take the Thunderclap |
| **Still Pool** | Drown (2 s sleep) + a pool on its tile, **5 s**: each walker entering it the first time sleeps **1 s** | no sleep: −30% speed while in the pool |
| **Fever Dream** | the nightmare's remaining Spored damage resolves at once (×1.0); adjacent nightmares get **3 Spored + 2 Drowsy** | same (Drowsy capped at 3) |
| **Starfall** | the Pinned ×3 crit; Static bolts from nightmares within **3 cells** fire at once into it (each ×2 and a crit); uses up their Static | same, bolts count as crits at ×1.5 |
| **Avalanche** | the lob's Shatter (×2.5) also Shatters every Damp + Held nightmare within the lob's splash | bosses take the ×2.5 hit, no spread from them |
| **Prismstorm** | Shatter as normal; each nightmare hit by shards gains **2 Static** | same |
| **Nightbloom** | Mushrooming's cloud (4 s) also keeps nightmares inside **unable to wake** (sleep and max Drowsy don't end while inside, and the Watcher's wake-up does nothing there) | bosses don't sleep; they keep max Drowsy while inside |
| **Fairy Circle** | instead of one cloud: mushroom rings on the **path tiles among the 8 around** the nightmare, **6 s**; each ring tile gives the first walker **2 Spored + Damp** | same |

**Priority when two crowns fit (as built, ae816ed):** Mushrooming on a nightmare that is both Held
and at full Drowsy becomes **Fairy Circle** (not Nightbloom); a Shatter from a Cairn/Rockslide lob
on a nightmare with Static becomes **Avalanche** (not Prismstorm). Fever Dream fires when Smother
ends because the Held ran out, on a nightmare at full Drowsy.

**Delivery rules**

| Rule | Numbers |
|---|---|
| **Grafted Harmony** | a Graftling adjacent to Wardens of 2+ different status families also applies each of their statuses at **half** stacks/duration on its hits (it still copies the strongest attack) |
| **Storm Front** | a Reaction completed by a Gust-copied status counts **+1 chain link** and its radius/reach **+1 tile** |
| **Carried Storm** | a Samara/Autumn Gale seed passing through a Reaction's spot within 0.5 s repeats that Reaction at **50%** on each nightmare it hits for the rest of that throw (once per nightmare per throw) |

## Woven cards: three-family Rares

A **Woven** card is an Entwined card with a third vine: **3 ingredients** (Wardens or statuses you
own), **guaranteed** in the next offer once all 3 are owned (one slot; passing returns it to normal
weight). All **Rare** (was Legendary until 2026-09-28: they enhance a combo, they don't start a build), Grove bundle *Woven Dreams* (see `meta_design.md`).

| # | Card | Ingredients | Effect |
|---|---|---|---|
| 100 | **Eye of the Tempest** | Stormcap + Rain Lily + Driftspore | Tempest arcs reach +1 cell and its Ignites spread 2 stacks |
| 101 | **Deep Stillness** | Rain Lily + Tangleroot + Bellflower | Still Pools last 8 s and their sleep is 1.5 s |
| 102 | **Fever Pitch** | Driftspore + Tangleroot + Bellflower | Fever Dream spreads to nightmares within 1.5 cells, not just adjacent |
| 103 | **Falling Stars** | Firefly Jar + Tangleroot + Chime Stone or Bellflower | Starfall pulls bolts from 5 cells |
| 104 | **Mountain's Fall** | Cairn + Frostfern + Tangleroot | Avalanche also leaves rubble where each spread Shatter lands |
| 105 | **Prism Heart** | Frostfern + Tangleroot + Stormcap | Prismstorm shards add 3 Static and fly 0.5 cells further |
| 106 | **Endless Night** | Bloomcap + Rain Lily + Bellflower | Nightbloom clouds last 7 s and 1.5× as wide |
| 107 | **Ring of Rings** | Fairy Ring + Rain Lily + Tangleroot | Fairy Circle rings last until stepped on (max 8 per Circle) |

- If Quick Reactions shortens cooldowns, the Tempest cap stays 2 s.
- **Watch in playtests:** Crowned Reactions counting as 2 links make ×10 Dawnburst (and
  *Dawnbreak*) much easier to reach. If every late drift ends in Dawnburst, drop them to 1 link or
  raise Dawnburst to ×12.

## Data (`UpgradeData`)

`id`, `display_name`, `description`, `rarity`, `kind` (stat / rule / economy; evolutions are
unlocked with Dreamlight, not cards;
family unlocks are a separate pick, not a Dream card), `tags: Array[String]`, `requires: Array[String]` (ids of Wardens or cards),
`max_stacks` (0 = unlimited for stat cards, else 1), `min_act` (Legendary = 2), `in_start_pool: bool`,
requirement fields (*Card requirements*): `requires_tag` + `requires_tag_count` (e.g. "nurture", 1;
"crit", 2), `requires_any` (Wardens where any one is enough, e.g. Still Target's sources),
`min_obstacles`, `min_rank_dew` (Dew spent on ranks this run), `min_rank_owned` + `min_rank_count`
(e.g. rank V, 1; any rank, 2),
plus effect parameters (stat modifiers: target line + stat + amount; or a `rule_id` the game
checks for).
