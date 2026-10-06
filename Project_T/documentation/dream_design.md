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

## Placement cards show a diagram (2026-09-30)

**Revised: a living mini-scene, not a static diagram** (2026-10-01, user: *"the visual tool isn't really helpful when hovering; can it be like a mini video of gameplay?"*). The hover panel plays a **looping 4–6 s mini-scene with the real sprites** in a small SubViewport, built from the card's existing `diagram` layout (no recorded video, so it follows art and balance changes and costs no file size): nightmares walk the diagram's path, the **qualifying Warden** attacks with its **boosted damage numbers in gold** (e.g. "×2" for Heart of the Maze), the non-qualifying one attacks normally in white, and the caption names the difference. Statuses and Reactions show with their real effects where the card is about them. Stops when the hover ends; reduced motion = the still diagram. Placement cards first, then status / Reaction cards.
User: *"confusing cards like Crossroads should have a diagram of what that looks like when you
hover."* Cards whose condition is about **where** a Warden stands get a small map picture:
- **Shown on hover** of the card (Dream offer, Dreams this run, Codex) and on **long-press** on touch,
  as a panel beside the card: a mini grid of **7×5 tiles** (path tiles sandy, grass dark, walls,
  obstacles, the Heartwood or start where relevant), **one Warden that qualifies, glowing**, the
  tiles that make it qualify **outlined in gold** (and numbered steps for Crossroads), and one
  short caption (*"Touches the path twice, 6+ steps apart: +40%"*). A second, dimmed Warden that
  doesn't qualify where that helps ("✗ only touches it once").
- **Data, not art:** each card carries a small ASCII layout (`diagram` field on `UpgradeData`, e.g.
  `"..P.P..\n..PWP..\n..PPP.."` with a legend: P path, W qualifying Warden, w non-qualifying, T
  Thornwall, O obstacle, H Heartwood, S start, * highlighted), drawn by one shared `CardDiagram`
  view in the Moonlit style. Same view later for the glossary and the Codex.
- **First set:** Crossroads, Cozy Corners / II, Straightaway / II, Shelter of Stones, Solitude, Rootbound,
  Kind Canopy, Shared Light, Heart of the Maze, Cliffside, Forest's Edge, Last Stand, Hedgerow Roots,
  Bitter Hedges, Briar Crown, Root Network / II, Sprout Chorus, Wildwood Reclaimed, Short Roots.

## Dreams must matter (2026-09-30)

User: *"cards aren't impactful enough to a run; I can play and beat it without choosing optimal
cards."* (Their drift-100 win was an all-families Sprout swarm.) Two problems, both to fix:
the **base game is strong enough without Dreams**, and **many cards are small** (+8%, +10% attack
speed, −4 Dew) so a wrong pick costs little.

**Targets** (Balanced bot and the run history, same Grove level):

| Dream choices | Where the run should end |
|---|---|
| **Let it pass every time** | **never past act 1**: dies by the drift 25 boss (user, 2026-09-30) |
| **Random card every time** | act 3 (~55–70) |
| **Sensible picks** (Balanced bot) | act 3–4, wins sometimes |
| **A build that comes together** (tags stacked, combos, Entwined) | wins |

What "never past act 1" means: only **4 Dreams** come before the drift 25 boss (after 5, 10, 15,
20), so those early cards must carry real weight. With sensible picks a fresh player still beats the
first boss ~75% (`run_design.md`); with none, the boss (or act 1's last block) should stop them.
Act 1's nightmare health rises to match as the cards grow, never before.

By act 3, **Dreams should be about half of a run's damage** (measured: damage with vs without the
taken cards' bonuses, `DamageLog`).

**Step 1, measure (now):** the same seeds with the three policies above (skip all / random / Balanced)
to 100, Fresh and Full, all families on and off. If "skip all" lands near Balanced, cards don't
matter, confirmed.

**Step 2, levers** (chosen after step 1; recommendation in order):
1. **Fewer, bigger cards.** Cut or merge Commons under ~15% of a Warden's power; a Common is +20–30%
   to its target or a clear rule. Rares change how you build (rule-changers, Entwined), Legendaries
   define the run. Every card gets a **power budget** by rarity, checked in the sim.
2. **Move power from the base into the Dreams.** Raise nightmare health from act 2 on while cards grow
   to match, so a run without Dreams falls where the table says, and a run with good ones doesn't
   get harder.
3. **Builds pay off:** a card's value grows with the cards of its tag you already own (e.g. every
   2nd card of a tag adds a small bonus to all of them), so committing beats picking the biggest
   number.
4. ~~"Let it pass" pays less~~ **Rejected** (user: "keep skipping if we're making the cards more powerful"): Let it pass stays +15 Dew. Skipping is punished by the missing card, not by the reward.

## Combo cards are choices, not musts (2026-10-02, user-approved)

User: *"I don't want the combo cards to feel like a must when you see them."* There are 32 combo or
Entwined cards. Most say "+X to a combo you already run", so when one shows up beside an unrelated
card, it's an automatic pick. The user's run history (15 real runs; it records takes, not offers)
shows the pattern: Kin and Kindling taken 4 times, Quick Reactions 3, Charged Bloom 3, Dawnbreak and
Sparking Spores 2 each. Balancing Code is measuring the bot's pick rates (before), and Main is adding
offered cards to the run history.

**Rules:**
1. **No guaranteed slot.** Entwined cards are offered at **normal odds** once their ingredients are
   owned (they used to take a guaranteed slot in the next offer, which read as "take this"). They
   remain Rare, still need all their ingredients, and are still discovery-gated where they were.
2. **Every combo card is a trade, a new shape, or a condition**, never just a bigger number for the
   combo you already run. Taking it changes how you play the combo; turning it down is sensible.
3. **Power stays within budget** (`dream_audit.md`): no combo card above its rarity's budget.
4. **Target:** the Balanced bot's pick rate for combo cards is about the same as other cards of
   their rarity (not ~100%), and with a strong combo running, a different card is a competitive pick.

**The 32 cards** (✎ = changed; = = kept, already a shape or condition):

| Card | Was | Now | Kind |
|---|---|---|---|
| ✎ Soaked Rot (C) | Poisoned ticks on Soaked +50% | Poisoned ticks on Soaked +50%, **but Soaked no longer boosts water hits on them** | trade: poison vs water |
| ✎ Rain on Glass (C) | light Wardens +35% vs Soaked | light Wardens +35% vs Soaked, **and their hits dry the nightmare (Soaked ends)** | trade: fights Thunderclap |
| ✎ Sparking Spores (C) | Ignite +50% | Ignite +50%, **only on nightmares with 5+ Poisoned** | condition |
| ✎ Rolling Thunder (U) | Thunderclap arcs reach 3.5 cells | arcs reach 3.5 cells **but strike at most 3 nightmares** | shape: long and few |
| ✎ Wildfire Spores (U) | Ignite spreads 2 Poisoned within 1.5 cells | spreads 2 Poisoned within 1.5 cells, **and the burning nightmare loses its own Poisoned** | trade: spread vs depth |
| ✎ Mushroom Rain (U) | Mushrooming cloud ×2 duration and the 8 tiles around | covers the 8 tiles around, **but lasts half as long** | shape: wide vs long |
| ✎ Deep Water (U) | Drown 4 s, damage +50% faster | Drown 4 s, damage +50% faster, **only within 5 cells of the Heartwood** | condition: last stand |
| ✎ Quick Reactions (R) | Reaction cooldowns 1.5 → 0.75 s | cooldowns 0.75 s, **but Reactions deal 35% less** (was 25%: Balancing Discussion, 2× as often × 0.75 was still +50% output; × 0.65 ≈ +30%) | trade: often vs big |
| ✎ Conductive Soil (R) | lightning jumps to every Soaked nightmare in range | jumps to every Soaked nightmare, **and each jump uses up that nightmare's Soaked** | trade: one burst vs steady |
| ✎ Charged Bloom (R) | Stormcap chains add 1 Drowsy | chains add 1 Drowsy, **but jump 1 fewer time** | trade: sleep vs reach |
| ✎ Starlit Aim (R) | Marked: +25% crit chance from every Warden | +25% crit chance on Marked, **and a crit uses up the Mark** | trade: burst vs sustain |
| ✎ Kin and Kindling (R) | Harmony strikes also apply both statuses | Harmony strikes apply both statuses **instead of dealing damage** | trade: setup vs damage |
| ✎ Carried on the Wind (R) | Gust copies full stacks | copies full stacks **to one nightmare** instead of all in range | trade: depth vs spread |
| ✎ Charged Feathers / Pollen Beaks (R) | pecks apply 1 Charged / 1 Poisoned | same, but **taking one removes the other from the run** | exclusive pair: pick a lane |
| ✎ Windborne Rain (R) | Samara seeds apply Soaked out and back | seeds apply Soaked, **but deal 25% less** | trade |
| ✎ The 8 Woven cards (R) | each makes its Crowned Reaction bigger | each still makes it bigger, **and its cooldown doubles** (bigger but rarer) | trade: one rule for all 8 |
| = Chain Bloom, Spore Cascade, Guiding Light, Ring Dance, Encore, Seeping | — | kept: each adds a new shape (spread, chain, echo) or scales with your setup | shape |
| = Nursery (R) | — | kept (a Sprout economy card, not a combo payoff) | — |
| = Dawnbreak (L) | — | kept (a Legendary defines a run) | — |

- **Numbers** stay where they are; the trades and conditions are the change. Balancing Discussion
  checks them with the pick-rate sim before and after.
- **Text:** these go through the card text audit (same pass), with the trade on its own line like a
  Bittersweet cost, so it's readable at a glance.
- **Status:** **approved by the user** (via the design hub, 2026-10-02); routed to Roguelite Code (data, offers,
  the exclusive pair) and Tower Code (the reaction and hit rules). **Built:** e328fb55, c9fa2491, 51dbf8e3.
- **Measured** (Balancing Code, Balanced bot, seeds 1–20, fresh + full, before 9b1a73ee vs after
  d99ec0a6): the guaranteed slot was taken **4/4** before (now gone). Common combo cards went from
  **.38 → .19** pick rate (other Commons .22) ✓; Uncommon .29 → .33 (others .33) ✓; Rare .21 → .25
  (others .49) ✓. Combo cards taken overall 20/53 → 12/47; Sparking Spores 5/12 → 2/12. Target met:
  combo cards are now picked about as often as other cards of their rarity. Thin samples (the bot
  dies in act 2); the user's own runs now log every offer, so their next runs are the real check.

## Feeling the cards (2026-10-01)

User: *"is there a way to make cards feel more meaningful and noticeable?"* → "let's try that". The
power pass made cards bigger; this makes them **visible**: you see what a card will do before you
take it, where it lands when you do, and what it did at the rest. Three parts, built together:

**1. Impact preview on the Dream card.** Under the effect, one line in gold showing what the card
would do to **your board right now**:
- **Stat cards** (damage, attack speed, range): *"On your board · +22% damage on 7 Wardens"*:
  computed by adding the card to a copy of your taken cards and comparing each Warden's stats
  (`DreamState.get_card_effects`, the same rows the build ghost uses). The % is the DPS-weighted
  average over the Wardens it changes.
- **Position and condition cards** (Cozy Corners, Tended Stumps, Drumbeat, Solitude…): *"4 of your
  Wardens qualify"*, from the same per-Warden checks.
- **Trigger cards** (First Light, Last Breath, Flurry…): *"Triggers on all 12 attackers"* or *"on
  your 3 area Wardens"*.
- **Economy cards:** the number at your board now (*"+14 Dew per rest at your 140-tile path"*).
- **Nothing yet:** *"None of your Wardens yet"* in dim ink (a card for later is still a fair pick;
  the line just says so).
- Cheap: computed once when the offer opens, not live. Mobile: on the card face, no hover needed.

**2. The bloom when you take it.** The chosen card shrinks into its slot in the Dreams row, and
**every Warden it affects pulses once** in the card's rarity colour with the card's icon above it
(staggered, ~1 s total), with a toast repeating the impact line (*"Cozy Corners · 6 Wardens +30%"*).
A card that affects nothing yet just goes to the row. Reduced motion: no fly, one soft highlight.
Never blocks input; the rest continues at once.

**3. Credit at the rest and the end.**
- **Damage per card:** `DamageLog` credits each card for the **extra** damage it adds (on a hit
  boosted by several cards, the bonus part is split between them in proportion to their bonuses).
  Trigger cards are credited with the damage they cause (Last Breath's burst, Flurry's second shot).
- **Rest report:** one line *"Dreams this block · Lingering Spores +1,840 · Cozy Corners +920 ·
  Flurry +610"* (top 3).
- **Non-damage cards** get their own credit where it matters: *"Morning Dew · +60 Dew"*, *"Thick
  Bark · saved 2 leaves"*, *"Heartwood's Reach · 3 half-price clears"*.
- **Results screen:** *"Best Dream: Lingering Spores · 18% of your damage"*, and the run report lists
  each taken card's total.
- **Dreams row:** tapping a card's icon shows its total so far this run.

**Later, if these land well:** trigger cards flash an icon spark when they fire (throttled);
Legendaries leave a visible signature on the map (Briar Crown's thorns glow, Nightshade tints
poisoned nightmares violet); offered cards say *"Works with Lingering Spores"* when they combo with
one you hold.

**Owners:** Roguelite Code (the impact preview data and the card credit model in DreamState /
DamageLog), Main (the Dream screen line, the bloom, the rest report and results lines), UI Code (the
look: gold line, pulse, toast), Tower Code (the Warden pulse hook, if `Tower` needs one beyond the
existing badges).

## Where Warden families come from (not Dreams)

- **After drift 1:** pick 1 of 3 base Wardens, drawn **at random from every family you've
  unlocked** (the starting 3 plus any unlocked in the Memory Grove: Pebbling, Rootling, Acorn,
  Nestling, Whirligig). Not always the same 3: a Grove unlock can turn up from drift 1.
  (Acorn stays in the first pick: a 2026-10-02 proposal to exclude it, since it has no damage branch,
  was withdrawn when Balancing found Acorn-first runs beat the act 1 boss every time, carried by its
  auras on Sprouts. If a re-check disagrees, Balancing tunes the base Acorn instead.)
- **Bosses at drifts 25, 50, 75:** pick 1 of 3 from the unlocked families you don't have yet (Family
  Blessings fill empty slots, `meta_design.md`).
- Draws avoid repeating the previous run's first-pick offer exactly, so runs start differently.
- Family cards explain the Sprout rule, e.g. *"Sporeling: Sprouts can now grow into Sporelings
  (15 Dew), or plant one directly (25 Dew)."*

## How Dream offers work

**Each run draws its own pool, and it follows your build** (2026-09-30, user: *"doesn't a lean starting pool create optimal builds though?"* → *"yes, depending on the build you're going for"*). With ~55 cards against ~57 offers a run, a fixed pool shows almost everything every run and the best picks become a solved routine. So:
- **At run start** the run draws its **Dream pool**: the **core** (basic stat cards and the cards of the families you hold) plus a **random ~60%** of everything else you have available (seeded with the map).
- ~~The pool follows your build~~ **Removed (user, same day: "I want the player to be able to change their build depending on the random cards they get, not send them down a path").** Taking a card adds nothing to the pool: the run's random draw is the run, and the player adapts to it.
- **New families** (family picks at 25 / 50 / 75) add their family cards to the core when picked.
- The Grove grows what can be drawn, so meta progress means **more varied runs**, not just stronger ones.
- Owner: Roguelite Mechanic Discussion (rules), Roguelite Code (DreamState). The offer weights, fade and pity rules work inside the run's pool. Codex "Dreams" keeps showing every card.
- **Exact rules (Roguelite design chat, 2026-09-30):**
  - **Available** = every card this profile could be offered (start pool + Grove unlocks +
    discoveries), before in-run Needs.
  - **Core** (always in the run's pool):
    - the **basics**: Quickened Sap, Deeper Calm, Longer Roots, Deep Roots, Thick Bark, Evergreen,
      Morning Dew (stacking, untagged cards that every build uses);
    - ~~family cards of every family you hold~~ **Removed 2026-10-01** (user, after a drift-35 Dream
      of 3 family cards out of 4: *"there shouldn't always be a family card in the pool"*). Held
      families' cards (Needs name the family or one of its Wardens, and its Blessing) are now
      **sampled at 60% like the rest**: a family pick adds a seeded 60% of that family's cards.
      Why: with 3–4 families held, ~10 guaranteed cards each outnumbered the 60%-sampled general
      cards, so offers filled with family cards. Not steering (tag weighting is off, and tag
      resonance only changed a taken card's power, never the odds; Resonance itself was removed 2026-10-02).
      If offers still lean family-heavy, the next step is an offer rule (at least 1 general card
      per offer), not more weighting. **Measured (cdbcbe64, drift 35, 3 families, 100 seeds):** family
      cards are 22% of the eligible pool on a fresh profile (12% with a full Grove), **0.72 / 0.38 per
      3-card offer**: well under the 1.5 line, so no offer rule is needed;
    - **the clearing opener** (Heartwood's Reach) on maps with 8+ obstacles, so clearing is always
      reachable.
  - **The rest** (generic and direction cards, combo cards, Legendaries) is sampled at **60%**,
    seeded with the map seed (same map, same pool), **per rarity** so the split doesn't skew, with
    **floors**: at least **12 Common, 12 Uncommon, 6 Rare** and (if available) **3 Legendary** from
    the rest. If fewer exist, take them all.
  - **Starvation check:** a run has 19 Dreams (up to ~28 offers with Lucid Dreaming, rerolls and
    Grove perks), 3–4 cards each.
    - **New account:** ~55 available → core ~14 + rest ~40 sampled to the floors ≈ **~45 cards**.
      Stat cards stack, the fade lets a passed card return after a gap, and every rarity has its
      floor: offers always fill.
    - **Full Grove:** ~200 available → **~120 cards**: very varied runs, still far more than offers.
    - The boss and pity Rare+ guarantee: with ≥ 6 Rares in the run's pool plus the family Rares,
      a forced Rare+ offer finds a card. If none is eligible, the existing fall-through applies.
  - ~~**The pool follows your build:** taking an archetype-tagged card pulls that archetype's
    remaining cards into the run's pool.~~ **Removed** (user, 2026-09-30: *"I want the player to be
    able to change their build depending on the random cards they get, not send them down a
    path."*). The run's pool is fixed at run start; only family picks and discoveries add to it.
  - **Discovery mid-run** adds the discovered cards to this run's pool right away (you just did the
    thing; the half-dreamed rule still applies).
  - **Unaffected:** Entwined guaranteed slots (their card joins the pool when due), Seed cards'
    "calls", Banish (removes from the run's pool), the Stray slot (draws from the run's pool, outside
    your tags).
  - **Shown:** nothing new on screen. The Codex lists every card; the "Dreams this run" panel could
    later show "dreams in reach this run" (optional).
  - **Tests:** two map seeds give different pools (same seed, same pool); the floors hold on a fresh
    profile; taking a tagged card adds **nothing** to the pool; a family pick adds a seeded 60% of its family cards (never all of them);
    19 offers on a fresh profile never show fewer than 3 cards.
  - **Targets (design hub, 2026-09-30):** a **decent build** (3+ of a package by drift 50) in
    **~50%** of runs; the **full dream build** (5+ by drift 100) in **~5%** with a full Grove and
    **close to 0%** on a fresh profile.
  - **Measured (09a9a069: lean pool, Grove nodes, 60% run pool, steering off):** decent build **57%**
    fresh / **52%** full (mixed picker; broad spread at full) ✓; dream build ~0% fresh (except Kinship
    12, Affliction 8, Precision 7) / **~5%** full (Tall 5, Overgrowth 6, Daring 4, Precision 9,
    Affliction 8, Maze 8, Tending 4, Kinship 4, Swift 0, Wide Reach 0) ✓; Adapt 95–96% ✓; every
    offer fills. **The 60% share stays.** Optional later: one more card each for Swift and Wide Reach,
    so their dream build is possible at all.
- **3 cards per Dream**, after drifts 5, 10, … 95. No duplicates within an offer.
- **Passed-over cards fade** (added 2026-09-28; playtest: Few and Mighty was offered ~5 times by
  drift 35 to a player not going narrow). A card that was offered and **not taken**:
  - **never appears in the next offer** (unless nothing else of the rolled rarity is eligible);
  - and its draw weight is **×0.6 per time passed this run** (1 pass ×0.6, 2 ×0.36, 3 ×0.22, 4
    ×0.13; floor ×0.1). Weights are relative, so this means **cards you've seen less come first**:
    an unseen card is ~5× as likely as one you've skipped three times. (Revised the same day: a
    flat ×0.5 / ×0.25 faded every unchosen card equally, so after act 2 it changed nothing.)
  - **Taking** a card resets its count to 0 (stackable cards you like keep coming).
  - A reroll counts as passing over every card it replaced. The Entwined guaranteed slot never
    fades and never counts as passed. Rerolls, Banish and Let it pass work as before.
  - Measure: in a test run that skips the same card at every offer, it should turn up in at most
    ~1 offer in 4 after its second skip.
  - **The fade crosses rarities** (added the same day; simulation c64183a: Few and Mighty was often
    the *only* eligible Rare, so every Rare roll landed on it, ~50% of offers, fade or not). When
    every eligible card of the rolled rarity is faded, keep that rarity only with a chance equal to
    their best weight; otherwise re-roll among the other rarities (a forced Rare+ offer falls through
    to Legendary **only where Legendaries can appear (act 2+)**; in act 1 it falls to Uncommon and
    the pity counter isn't reset, so the next offer tries for a Rare again). A forced offer rolls
    the faded-rarity chance **once per offer** (first slot only), not once per slot. A card that's alone in its rarity therefore fades like any other, and the
    next-offer exclusion holds unless the offer can't be filled at all.
  - **Content gap:** the Rare tier is thin for many boards (in that simulation Few and Mighty was the
    only Rare eligible in act 1). The pool needs more Rares with loose Needs; see the design todo in
    `design_plan.md`.
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
- **Tag weighting:** cards tagged with a family you own are **2× as likely** (1.4× for a while, back to 2× once the pool grew by 27 generic cards; see
  *Adapt, don't get handed* below). Builds lean together without being forced.
- **Prerequisites:** a card never appears if it can't do anything yet (e.g. Stormcap cards need
  Firefly Jar). Full rules in *Card requirements* below. **Exception: Seed cards** (tag `seed`,
  "Seed cards: plant now, grow later") are offered without their Wardens, on purpose.

### Adapt, don't get handed (2026-09-28)

**Playtest:** *"When I'm playing a build, the cards give me the build I'm building most of the
time."* Measured (Roguelite Code, 400 seeded offers): ~35% of offered cards came from the player's own
family cards (6–8 cards weighted 2×), 0% from other families, and the other ~65% "general" cards
were mostly gated by Needs that read the board (few attackers → narrow cards, ranks → nurture cards,
statuses → Reaction cards). The Dreams **recognised** the build instead of **tempting** the player
with good things they'd have to adapt to. The genre's tension is the second one.

**Goal:** most offers still have something for your build, but **most offers also hold one real
alternative**: a strong card you can use now if you bend the plan.

1. **Tag weighting 2× → 1.4× → 2.4×** (`tag_weight`; raised to 2.4 on 2026-09-28 (measured, 15f07aa) after cards 142–168 grew the generic pool and own-family cards fell to 16–18%; the target is the **share**, ~22–25%, not the number), for owned families, directions (wide / narrow /
   nurture) and Legendary archetypes alike. Wide vs narrow opposition (×0.5) stays.
   **Superseded 2026-09-30** (*Your Dreams steer your Dreams*, under "Build packages"): families no
   longer boost weighting at all; only tags of cards you've taken do, at ~1.6×.
2. **Soft Needs.** A Need is *hard* if the card would do nothing without it, *soft* if it only
   checks what you've built so far:
   - **Hard (still gate):** owning a Warden or family, card Needs (follow-ups need their opener,
     Deepened, Entwined, `requires_tag`), status Needs (`requires_status`, `min_owned_statuses`,
     Reaction pairs), clearing's obstacles left, leaf safety, Grove unlocks.
   - **Soft (now a weight, ×0.4 when unmet):** attacker counts (wide / narrow cards), Nurture
     openers' rank checks (`min_rank_dew`, `min_rank_count`), Warden counts (`count_warden`). So a
     narrow card can turn up in a wide maze (0.4 × 0.5 opposition = rare) and a Nurture opener can
     tempt a player who never nurtured.
3. **The Stray Dream: one wildcard slot per offer** (from the rest after drift 10; not at boss
   rests, which stay Rare+ as they are). One slot draws with the weighting **turned around**: cards
   sharing any tag with your build (owned families, directions, Legendary archetypes) ×0.25, the
   rest ×1, soft Needs ignored, hard Needs still apply (it's always usable). **No tag on the card**
   (2026-09-30, user: the "Stray" tag and its line confused more than they explained; it's one of
   the normal cards, just drawn from outside your build). Rarity is rolled as
   normal; the skip fade applies. With Entwined due, the offer is Entwined + Stray + one normal.
4. **No pivot cards** (user decision 2026-09-28): families still come **only from the family picks**
   (after drift 1 and each boss).
5. **Half-dreamed combo cards** (user idea, 2026-09-28): a combo card that crosses two families can
   be offered once you own **one** of them, as a reason to take the other at the next family pick.
   Example: you have Firefly Jar; *Rolling Thunder* (Thunderclap, Charged + Soaked) or *Conductive
   Soil* can turn up before you have Dewdrop.
   - **Which cards:** cards whose Needs name Wardens from **two or more families** (the Reaction
     cards such as Rolling Thunder and Wildfire Spores, and cross-family Entwined cards such as
     Conductive Soil).
   - **When:** you own at least one of those families, and each missing family is still **pickable**
     this run: unlocked, not owned, and a family pick is still ahead (never after the drift 75 pick).
     Needs on a specific form (Stormcap) count as its family for this check; the form itself is still
     unlocked with Dreamlight as usual.
   - **Weight ×1.0** while half-dreamed (×0.6 → ×0.8 → ×1.0 as the generic Rares and cards 142–168 thinned it; target 0.4–0.8 per run before drift 25), so it's an occasional temptation, not a flood. Normal
     rarity; the skip fade applies.
   - **Timing (playtest fix, 2026-09-28):** only offered when the next family pick is **at most 20
     drifts away** (so not in the rest right after a pick, when it would sleep 25 drifts), and
     **never in a guaranteed Rare slot** (boss rests, pity, owed Rares): a guaranteed reward must
     work now.
   - **Declined:** if a family pick offered the missing family and the player took another, that
     family's half-dreamed cards drop to **×0.3** until the next pick (they said no once).
   - **Picks stay pure** (user, 2026-10-03, with the Seed removal): taking a half-dreamed card does
     **not** put its missing family into the next family pick (the code did, as an "owed" family).
     The card is a real gamble: it sleeps until a pick happens to offer that family and you take it,
     which may never happen.
   - **Coverage:** every pair of starting families has at least one combo card in the start pool:
     Firefly Jar + Dewdrop (Rolling Thunder, Conductive Soil), Sporeling + Firefly Jar (Wildfire
     Spores), Sporeling + Dewdrop (Mushroom Rain, 134). New families should bring one per pair.
   - **Common combo cards** (added 2026-09-28: after cards 142–168 and `tag_weight` 2.4, Sporeling
     and Dewdrop starts fell to ~0.35 half-dreamed offers before drift 25, because each pair's combos
     were Uncommon or Rare and lost the Common-heavy rarity roll). One small, stackable **Common** per
     starting pair, Start pool; they only amplify:

     | # | Card | Rarity | Effect | Tags | Needs |
     |---|---|---|---|---|---|
     | 189 | **Soaked Rot** | Common, stacks (max 3) | Poisoned ticks on **Soaked** nightmares deal **+20%** | spore, water, reaction | Sporeling + Dewdrop |
     | 190 | **Sparking Spores** | Common, stacks (max 3) | **Ignite** detonations deal **+20%** | spore, storm, reaction | Sporeling + Firefly Jar |
     | 191 | **Rain on Glass** | Common, stacks (max 3) | light Wardens deal **+12%** to **Soaked** nightmares | water, storm, reaction | Dewdrop + Firefly Jar |

     Target after these: **≥ 0.4** per starting family before drift 25 (guard back to 0.4), with the
     half-dreamed weight left at ×1.0.
   - **As built (2c1612b, with the generic Rares and real family picks):** **0.5–0.8 offers per run
     before the drift 25 pick** (Sporeling 0.53, Firefly Jar 0.76, Dewdrop 0.68), ~1 through drift 70.
     **Accepted** (2026-09-28): a temptation should be occasional, so no stronger weight (it would
     become a lure). The number grows naturally as the pool gets more cross-family combo cards
     (`design_plan.md`, Dream pool to ~70).
   - **Card face** (simplified 2026-09-30, user: "remove the 'half dream' from cards"): **no
     "Half-dreamed" tag or label and no "sleeps until then"**. Only one short muted line under the
     effect: *"Needs Dewdrop"* (the family is a linked term to its family pick). "Half-dreamed" stays
     an internal name for the mechanic. The card's effect works only once everything it needs is
     owned. In "Dreams this run" such a card is dimmed with the same "Needs Dewdrop" line.
   - **No "Entwined" label on the card** (2026-09-30, user: *"still don't know what Entwined
     is"*): like "Half-dreamed", it's an internal name. The vine border stays (it says "this joins
     two of your families"), and the card's text names both Wardens. **The "Needs" line appears only
     when something is still missing**; an Entwined card offered because you own both shows none.
   - **Named by damage type** (2026-09-30, user: "Needs Whirligig … should be the type of damage"):
     the line reads **"Needs Wind"** (the family's damage type, linked; no emblem since the emblems were removed), not the
     family's name. When the card needs a specific form (Windborne Rain needs Samara), the tooltip on
     that line names it: *"Samara, a Wind Warden"*.
   - **Taking one makes the next family pick offer the missing family** as one of its 3 choices
     (if several are missing, one of them). The player still chooses; it's never auto-picked.
   - Entwined's guaranteed slot is unchanged (it still fires once all ingredients are owned).
     A half-dreamed Entwined card you already took simply isn't offered again.

**Targets (offer simulation):** own-family cards ≈ **25%** of offered cards (was 35%); **≥1 card
outside the current build in ~70% of offers**. Storm Grid is unaffected: its Wardens now come from
family picks and Dreamlight, and Conductive Soil keeps its Entwined slot.

**As built (65bbe5c, 400 seeded offers per case, `tests/test_dreams.gd`):** own-family share
22–25% from drift 15 (31% at drift 5, before the Stray slot; was ~35%); an out-of-build card in
90–95% of offers (high early partly because no direction is picked yet). Half-dreamed cards: in
progress.

### Card requirements (the "Needs" column)

Clarified 2026-09-27 (user rule: cards that need other cards work like the clearing cards). Every
card lists its **Needs**; it is **never offered until all of its hard Needs are met** (soft Needs only lower its weight since 2026-09-28: see *Adapt, don't get handed*). There are three kinds:

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

**How Needs are shown on a card** (user rule, 2026-09-29): a card never shows the name of a Warden
you don't have. The Needs line says *what the card works with*, not which Warden to find:
- **Combo cards** (Reaction cards, half-dreamed cards, Entwined / Woven cards built on statuses) show
  the **statuses** the combo needs, as status icons + names: *"Needs: Soaked + Charged"*
  (Thunderclap: Rolling Thunder, Rain on Glass, Conductive Soil), *"Poisoned + Charged"* (Ignite:
  Wildfire Spores, Sparking Spores), *"Poisoned + Soaked"* (Mushrooming: Mushroom Rain, Soaked Rot),
  *"Soaked + Drowsy"* (Drown: Deep Water). A status you can already apply is lit; a missing one is
  dim. Woven cards show their Crowned Reaction's three statuses.
- **Warden cards** (cards whose Needs name a Warden: Soft Spores, Shiny Things, Heavy Stones, branch
  and final-form unlocks…) show only the **family**, with its icon: *"Needs: Nestling family"*, never
  "Magpie Perch".
- **Card ingredients** (Nursery: Tender Care + Seedling Gift; Spore Cascade: Lingering Spores; Deepened
  bases) are shown by name: cards aren't spoilers.
- **Entwined cards whose ingredients are two Wardens without a status combo** (e.g. Starlit Aim:
  Standing Stone + Lanternmoth) show the two **families**: *"Pebbling + Firefly Jar families"*.
- The same rule applies to the other card lines that named Wardens: the **half-dreamed** line
  (*"Needs Charged: a family that brings it may come at the next pick"* instead of naming the
  family's Warden), the **Seed** "Grows with" line (the family, e.g. *"Grows with the Acorn line"*),
  and the Codex's card list.
- **Data:** `UpgradeData.shows_statuses` (e.g. `["soaked", "charged"]`) for combo cards; Warden
  Needs are turned into families with `DreamState.family_of()`. The card's **effect text** keeps its
  wording; with discovery unlocks you've already met any Warden a card's text names.

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

### Discovery unlocks: you dream of what you've seen (2026-09-29)

User decision. **Cards named after a combo, a Kinship or a Warden only enter the Dream pool once you
have discovered that thing**, and then they stay in the pool **for good** (every future run; saved in
the profile like the Codex). The forest dreams of what it has seen.

| Discovery | When it counts | Cards it unlocks |
|---|---|---|
| **A Reaction** | the first time that Reaction fires, ever (profile `reactions_seen`) | cards that name that Reaction: Thunderclap → Rolling Thunder, Rain on Glass, Conductive Soil; Ignite → Wildfire Spores, Sparking Spores; Mushrooming → Mushroom Rain, Soaked Rot; Drown → Deep Water. **Any 2 Reactions** → Quick Reactions |
| **A Crowned Reaction** | the first time it fires | its Woven card (Tempest → Eye of the Tempest, Still Pool → Deep Stillness, …) |
| **A ×10 chain** | the first ×10 Reaction chain, ever (profile `best_chain`) | **Dawnbreak** (Legendary; moved out of the Grove 2026-09-30) |
| **A first Kinship** | the first time any Kinship forms (same as the row below) | also **Grove of Kin** (Legendary; moved out of the Grove 2026-09-30) |
| **Charged + Drowsy** | the first time one nightmare carries Charged and Drowsy together | **Charged Bloom** (id `static_bloom`) |
| **Puffball in the fog** | the first Puffball pop on a nightmare inside Mistveil's fog | **Chain Bloom** |
| **A crit on a Marked nightmare** | the first crit that lands on a Marked nightmare | **Starlit Aim** |
| **A Kinship** | the first time **any** Kinship forms | the Kinship cards (124–133) |
| **A Warden** | the first time you **build or grow into** that Warden | cards whose Needs name it (Soft Spores → Sporeling, Shiny Things → Magpie Perch, Heavy Stones → Pebbling, Twin Puff → Sporeling, …) and its branch / final-form unlock cards |

- **It counts at once:** a discovery puts its cards in the pool **from that moment**, including the
  rest of the current run (so the next Dream can already offer them). The card's normal Needs still
  apply on top (e.g. you still need to own Stormcap for Rolling Thunder this run).
- **Shown:** the discovery card that already appears on a first Reaction / Kinship adds a line
  *"New Dreams: Rolling Thunder, Rain on Glass"*. A **discovered** Codex entry lists its Dreams;
  an undiscovered one stays **"???" and names no cards** (the user's "??? everywhere" rule wins;
  the earlier "greyed until discovered" idea is dropped, 2026-09-29). A first build of a Warden
  shows a small toast with its new Dreams.
- **Cards never gate a combo** still holds: Reactions, Kinships and Wardens all work without any
  card, so discovery always comes from playing, never from the pool.
- **Grove overlap:** where a discovery card was also sold on a Memory Grove node (Wildfire Spores,
  Deep Water, Quick Reactions, Dawnbreak, the Woven cards, Close Kin …), **discovery gives it for
  free**; the node keeps its other contents and its price drops by that card's share. The meta
  chat should rebalance `meta_design.md`'s node list.
  - **Resolved 2026-09-29** (Meta Game Code's audit: 8 nodes, 700 Seeds, were *fully* covered):
    **Legendaries are never discovery-gated**, so **Dawnbreak** and **Grove of Kin** drop
    `discovered_by` and stay **Grove tips** (bought, as before). The **5 other fully covered nodes
    are removed**: Reactions, Woven Dreams I and II, Kin Lore, Deep Bonds (and the Reactions →
    Dawnbreak link: Dawnbreak now hangs off Spore Lore; Grove of Kin off the nearest remaining Cards
    node). **Bittersweet Dreams** loses Blood Is Thicker and costs 52. Cards that are only
    implicitly Warden-gated (Acorn Cache, Twin Puff, …) stay on their nodes. The tree (as built, 763f228) is
    **6,722 Seeds** (~34 h; the earlier 5,960 figure was out of date), and those cards now come from
    playing instead.
- **Half-dreamed cards** (see *Adapt, don't get handed*) still need their Reaction discovered first.
  So in a player's first runs they won't tempt toward a combo they've never seen; finding combos
  by experimenting (the Codex's "???" entries) does that job instead. **They skip the Warden gate** (ruling 2026-09-29): the Reaction is the
  discovery that matters, and their Needs line shows statuses, not Wardens. Otherwise Conductive
  Soil would stay hidden for a player who found Thunderclap with a plain Firefly Jar but never grew
  a Stormcap, which defeats a card meant to tempt toward the other family.
- **Not covered** (stay as they are): generic cards, stat cards, Legendaries (they start builds and
  need no discovery), clearing and Nurture cards (their openers already read the run).
  **Exception (2026-09-30, "no combo cards in the Grove", `meta_design.md` Section 3):** the two
  *combo* Legendaries, **Dawnbreak** and **Grove of Kin**, now unlock by discovery (rows above)
  instead of being Grove tips; this replaces the 2026-09-29 "Resolved" note for them. Discovery is
  a profile unlock like the Grove, not an in-run Need, so the Legendary rules still hold (no card
  Needs in a run). **Static Field, Twin Puff and Guiding Light** come with their starting families
  and are in the pool from the first run.
- **Demo:** nothing is saved, so discoveries count **for the current run only**. **Dev modes** (Test
  Grove, Unlock all families) treat everything as discovered.
- **Data:** `UpgradeData.discovered_by` (a list: `reaction:<id>`, `crowned:<id>`, `chain:5`,
  `kinship:any`, `warden:<id>`, `reactions:2`); `HeartwoodMemory` keeps `reactions_seen` (exists),
  `crowned_seen`, `kinships_seen`, `wardens_built`, `best_chain`. A card with a non-empty
  `discovered_by` is offered only when every entry is met. `test_dreams` checks a fresh profile
  never sees them and a discovery adds them mid-run.

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
| 21 | **Cozy Corners** | Wardens beside a bend in the path +15% damage. "Beside" = any of the **8 cells around** the Warden, diagonals included (clarified 2026-09-28: the inside of a U-turn is diagonal to its corners) | maze | — | Start |
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
Sprout, like Heartwood's Reach's clear charges. Unused charges last all run and are kept in the save.
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
| 110 | **Seeping** | Uncommon | effects deal **+8% per status** the nightmare carries (up to +40%; data) | potency, reaction | any 2 status families | Grove |
| 111 | **Venom Bloom** | Uncommon, **Bittersweet** | all Wardens +30% Potency. **Cost:** hits do −15% damage | potency, bittersweet | — | Grove |
| 112 | **Nightshade** | Legendary | effects deal **double damage to nightmares carrying 4+ statuses** (2026-10-05; multiplies with Potency and Seeping) | potency | — | Grove |

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
| 47 | **Patient Aim** | Uncommon | +15% crit chance per second a Warden hasn't fired (up to +45%; 2026-10-05) | crit, stone | Standing Stone | Grove |
| 48 | **Ring Dance** | Rare, **Entwined** (Fairy Ring + Driftspore) | a Fairy Ring burst sets off any ring within 2 tiles | spore, trap | — | Grove |
| 49 | **Deep Frost** | Uncommon | frozen nightmares take +20% damage | water, crit | Frostfern | Grove |
| 50 | **Carried on the Wind** | Rare, **Entwined** (Gust + any status branch) | Gust and Zephyr copy **full** stacks | wind | — | Grove |
| 51 | **Sweet Scent** | Uncommon | Honeysuckle Drowsy also applies to nightmares 2 tiles away | wall, sleep | Honeysuckle | Grove |
| 52 | **Shiny Things** | Uncommon | each buff a Magpie steals gives that Magpie **+15% damage for 10 s** (stacks 3, +45%). *(Reworked 2026-09-30: Magpies became buff thieves in the status-jobs review; was "Magpie Dew caps +10")* | wing | Magpie Perch | Grove |
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
| 97 | **Heavy Seed** | Uncommon | the seed's **return pass** hits for double (changed 2026-09-29: pulling back is Rootling's job) | wind | Samara | hidden node |
| 98 | **Windborne Rain** | Rare, **Entwined** (Samara + Rain Lily) | Samara's seeds apply **Soaked** to every nightmare they pass, out and back (card text never names the combo it sets up: "???" rule) | wind, water, reaction | — | hidden node |
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

**Make the unlock obvious** (2026-09-29, user: "it's not clear that you unlock clearing when you get
it"). While clearing is still locked, **every clearing card leads with the unlock**, before its own
effect:
- A highlighted first line with the Clear tool icon: **"Unlocks clearing"**, and under it one plain
  line: *"Tend Withered Trees and move Mossy Boulders for Dew (Clear tool, C)."* Then a thin divider
  and the card's own effect ("…and your clears cost 2 less").
- A small gold **"Opens clearing"** tag in the corner of the card (like Entwined / Half-dreamed).
- Once clearing is unlocked, these lines disappear from later clearing cards (they then show only
  their own effect).
- The change is **on the card only** (user clarification); nothing new happens elsewhere when you
  take it (the existing whisper stays as it was).

**One opener, the rest follow** (2026-09-30, user: "what's the point of Cleared Ground if you haven't
unlocked clearing? The point of the card is reducing the cost"). This replaces "every clearing card
unlocks clearing":
- A new Common opener, **Tend the Forest** (card 172, Start pool): *"Unlocks clearing: tend Withered
  Trees and move Mossy Boulders for Dew (Clear tool, C). Your first 2 clears are free."* Tags
  clearing, opener. It's the only card that unlocks clearing; it keeps the 2× weight while clearing
  is locked (maps with 8+ obstacles), and the "Unlocks clearing" layout above.
- **Every other clearing card** (Cleared Ground, Heartwood's Reach, Reclaimed Earth, Tended Forest,
  Wildwood Reclaimed, …) becomes a **follow-up: it needs clearing unlocked** (a hard Need, like the
  Nurture follow-ups), so it's never offered before the opener. **Burn Back** stays as it is (a
  Grove Bittersweet that clears trees outright, so it also unlocks clearing).
- The Codex and "Dreams this run" still note which card unlocked clearing.

| # | Card | Rarity | Effect | Tags | Pool |
|---|---|---|---|---|---|
| 54 | **Cleared Ground** | Common | clearing obstacles costs **25% less** Dew (stacks, **max −50%**) | clearing, economy | Start |
| 55 | **Heartwood's Reach** | Common | *(2026-09-30: now absorbs Cleared Ground: clearing −25% (−50% at 2 stacks) and 3 half-price clears per stack, see "Finalized" under Clearing follow-ups.)* Was: gain **4 half-price clears**; use them any time (a charge counter on the HUD; unused charges last all run). Deepened II: 7 | clearing | Start |
| 56 | **Reclaimed Earth** | Common | each clear **refunds 40% of the Dew you paid for it**, and the cell is left **fertile**: the first Warden planted there costs 50% less | clearing, economy | Start |
| 57 | **Tended Forest** | Common | **+1% damage for every obstacle cleared this run** (max +25%; clears from before the card count) | clearing, maze | Start |
| 58 | **Burn Back the Dead Wood** | Rare, **Bittersweet** | clear **every Withered Tree** on the map right now for **5 Dew each** (paid when taken; only offered if you can pay). **Cost:** nightmares +10% speed for the rest of the run | clearing, bittersweet | Grove |

**Clearing follow-ups need a payoff on the map** (2026-09-30, user: *"the obstacle clearing cards become useless once you unlock it first; only good with the Legendary"*). After Tend the Forest, the follow-ups are mostly discounts (Cleared Ground, Heartwood's Reach) on something you do a few times a run; only Wildwood Reclaimed (Wardens on cleared cells) pays off. Direction for the redesign (Roguelite Mechanic Discussion owns the cards):
- **The cleared spot itself becomes worth something**, as a smaller version of Wildwood: a **tended stump** (a cleared Withered Tree) gives the Wardens touching it **+10% damage**; a **moved hollow** (a cleared boulder) gives a Warden planted in it **+1 range**. These come from Uncommon cards (one each), and stack up to Wildwood at the top.
- **Merge the two discount cards into one Common** (cheaper clears and a few free ones), so the clearing line has room for payoffs.
- **Tended Forest** stays (global % per clear) and **Reclaimed Earth** stays (fertile cells).
- Goal: a clearing build that reshapes the map and is rewarded for **where** it clears, with Wildwood as its Legendary peak, not its only card.
- **Finalized (Roguelite design chat, 2026-09-30):**

  | # | Card | Rarity | Effect | Diagram | Where |
  |---|---|---|---|---|---|
  | (55) | **Heartwood's Reach** (absorbs Cleared Ground) | Common, stacks (max 2) | clearing costs **25% less** (−50% at 2 stacks, still above the floor), and gain **3 half-price clears** per stack | — | **Start pool** (the clearing opener: any clearing card unlocks clearing) |
  | 246 | **Tended Stumps** | Uncommon | each **tended stump** (a Withered Tree you cleared) gives the Wardens **touching it +25% damage** (a Warden counts its best stump once; stumps don't stack) | `".......\n..WWW..\n..WUW..\n..www..\n......."` with `U` = stump; caption *"Touching a tended stump: +25%."* (the dimmed `w` row shows Wardens one cell too far) | Grove · **Reclaiming node 1** |
  | 247 | **Hollow Ground** | Uncommon | a Warden **planted in a moved hollow** (where you cleared a Mossy Boulder or Thorn-Sapling) gets **+1 range** | `".......\n.PPPPP.\n...Q...\n.....w.\n......."` with `Q` = Warden in a hollow; caption *"Planted in a moved hollow: +1 range."* | Grove · **Reclaiming node 1** |

  - **Why +25%, not +10%:** the `dream_audit.md` budget for an Uncommon conditional card is +45%;
    +10% would be "too small to change a choice". +25% because one stump can reach several Wardens.
  - **Why half-price, not free:** "clearing always costs Dew" (user rule): the merged card gives
    half-price charges, never free clears. Merged, it also frees a Common slot.
  - **Reclaiming branch** (`meta_design.md`, Meta owns the final call): node 1 (50) = **Reclaimed
    Earth, Tended Stumps, Hollow Ground** (the "where you clear" payoffs come first, so buying the
    branch fixes the user's complaint at once); node 2 (70) = **Tended Forest, Thorn Snare, Bramble
    Oath**; tip **Wildwood Reclaimed** (120).
  - **Starting pool:** Cleared Ground leaves (merged); Commons go 25 → **24**. Heartwood's Reach stays
    the one start-pool clearing card (the taster).
  - **Deepened:** Tended Stumps II (+40%, and diagonal-only Wardens count too: it already counts the
    8 cells, so II is the number only), Hollow Ground II (+1.5 range).
  - **Tower hooks:** Tended Stumps and Hollow Ground read the cleared cells' marks
    (`ObstacleData.cleared_source_id`: tended stump / moved hollow) per Warden cell, live (a new clear
    updates neighbours). Tower Code adds them to the Warden's stat breakdown.
**Clear prices, raised** (2026-09-30, user: "clearing obstacles seems too cheap"). At 5 / 8 Dew a
clear cost less than a Sprout, so by act 2 the map was free to reshape and each clear was a cheap
+1 Seed. Now:
- **Base:** Withered Tree **12 Dew**, Mossy Boulder and Thorn-Sapling **18 Dew** (was 5 / 8 / 8).
- **Each clear this run adds +1 Dew** to every later clear (`RunState.obstacles_tended`, like the
  Sprout price rule), so the first few are affordable in act 1 and clearing half the map is a real
  investment. The hover tag and the Clear tool show the current price.
- Floor stays half the **base** (tree 6, boulder 9), before the per-clear rise; Blight 9 ×2 on top.
- Burn Back's price becomes **5 Dew per tree** (was 2).

**Clearing always costs Dew** (user rule, 2026-09-28). No card, perk or combination makes a clear
free or profitable:
- **Floor:** a clear never costs less than **half its base cost** (tree 6, boulder 9),
  whatever stacks: Cleared Ground, Heartwood's Reach charges, Grove perks. Blight Level 9's ×2 is
  applied on top.
- **Dew back** from a clear (Reclaimed Earth) is a share of what you **paid**, so it's always less
  than the cost.
- Changed from the first version: Cleared Ground was −40% per stack down to 1 Dew; Heartwood's Reach
  gave free clears; Reclaimed Earth gave a flat +8 Dew (a 5-Dew tree made +3 profit); Burn Back was
  free.

- **Offered only when it matters:** clearing cards need at least **8 obstacles** left on the map
  (Burn Back needs 8 Withered Trees). They lean toward early Dreams, when the map is still full.
- **Seeds:** half-price clears (Heartwood's Reach) still give +1 Seed each. **Burn Back doesn't**: clearing
  dozens of trees at once would otherwise flood the meta with Seeds.
- **Burn Back and the other cards:** its clears **don't trigger Reclaimed Earth** (no +8 Dew, no
  fertile cells), for the same reason. They **do count for Tended Forest** (it's capped at +25%, so
  that combo is a fair payoff).
- **Heartwood's Reach II** brings the total to **7 charges** (+3 when taken), not +7: Deepened
  replaces the base effect.
- **Settled in implementation:** Cleared Ground stacks add (−40%, −80%, then the 1 Dew minimum);
  half-price charges are used first; Burn Back's speed cost applies to bosses too; Burn Back is act 2+
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
| 60 | **Tender Care** | Common | **Every Warden's first Nurture rank is free.** Deepened II: rank I free, and ranks II–V cost **20% less**. *(Reworked 2026-09-30, user: "doesn't seem like it fits anymore". The trim had glued Warm Hands' "+3% damage per rank" onto a −15% discount, and its `economy` tag showed an economy tag-resonance bonus on a Nurture card. Now one clear rule that makes starting to nurture worth it, sized to the Common all-Wardens budget: rank I ≈ +14% DPS)* | nurture (archetype `tall`) | — (an opener) | Start |
| 61 | **Warm Hands** | Common | each Nurture rank gives **+3% more damage** (10% → 13%; stacks) | nurture | *opener:* 30+ Dew spent on ranks | Start |
| 62 | **Kindred Roots** | Uncommon | each Warden gets **+2% damage per rank of the Wardens touching it** (max +30%) | nurture, maze | any `nurture` card (soft) + **1** ranked Warden (was 2; trim round 2) | Start |
| 63 | **Remembered Care** | Uncommon | selling a ranked Warden leaves a **memory seed** on the HUD; the next Warden you plant starts at that rank (one seed at a time, the highest one is kept) | nurture | any `nurture` card + a rank III+ Warden | Start |
| 64 | **Sunlit Rest** | Uncommon | **At every rest, the attacking Warden nearest the Heartwood gains a free Nurture rank.** *(Simplified 2026-10-03, user: "confusing"; was a two-branch rule: ranked Warden first, else rank I)* | nurture | — (an opener) | Grove |
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
- **Sunlit Rest** (simplified 2026-10-03): the **attacking Warden nearest the Heartwood** (path
  distance, the same order as group Nurture) gains a free rank, ranked or not. If it's already at its
  max rank (V, or VII for the Eldest with Deeper Rings), the **next-nearest** gets it. The **rank
  choice** (Power / Swift / Reach / Deep, or a support Warden's Wide / Strong / Kindred) **repeats
  that Warden's latest choice**, or **Power** (support: Strong) if it has none yet, so no pop-up at the
  rest. The tooltip says so; the face doesn't. **Live line:** *"Next rest: your Sporeling by the
  Heartwood"* (the Warden it will hit), and the rank shows with the bloom at the rest. The
  impact preview counts **1 Warden**, not all attackers. Sunlit Rest II: the two nearest.
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
| 69 | **Seedfall** | Common | Sprouts cost **6** Dew **and their price never rises** (opens the Sprout swarm build; the base price rises +3 per 5 Sprouts; tested ×1.05 of Balanced, 2026-09-29) | sprout, wide | — | Start |
| 70 | **Many Hands** | Uncommon | all Wardens **+1% damage per 4 attacking Wardens** you have (max +25%) | wide | 15+ attacking Wardens | Start |
| 71 | **Sprout Chorus** | Uncommon | Sprouts **+5% attack speed per other Sprout within 2 cells** (max +40%) | sprout, wide | 6+ Sprouts | Start |
| 72 | **Canopy** | Rare | when you reach **20, 30 and 40** attacking Wardens (planted this run), every Warden gets **+8% damage** permanently, each time | wide | 15+ attacking Wardens | Grove |
| 73 | **Overgrowth** | Rare, **Bittersweet** | planting any Warden costs **30% less**. **Cost:** Wardens can't be nurtured past rank I | wide, bittersweet | — | Grove |

**Narrow: the Lone Lantern** (a few Wardens, very strong)

| # | Card | Rarity | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|---|
| 74 | **Solitude** | Uncommon | a Warden with **no other attacking Warden within 2 cells** gets **+30% damage and +0.5 range** | narrow, maze | — | Start |
| 75 | **Few and Mighty** | Rare | card text (2026-09-30, clearer): *"The fewer attackers, the stronger: all Wardens +8% damage for each attacking Warden you have under 12 (max +80%)."* plus a live line on the card: *"You have 7 · +40%"* | narrow | 12 or fewer attacking Wardens when offered (**bug 2026-09-30: offered at drift 70 with 139**) | Start |
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
| Cozy Corners | +15% soothe beside a bend | +25%, and bends up to 2 tiles away count (the 5×5 square around the Warden) |
| Hedge Maze | +1% per 5 Thornwalls (max 20%) | +1% per 4 Thornwalls (max 30%) |
| Evergreen | evolving −25% Dew | evolving −40% Dew |
| Lingering Spores | Spored +3 s | Spored +5 s, and max stacks +2 |
| Soaked Through | Damp lasts ×2 | Damp lasts ×3, and water hits on Damp nightmares +30% instead of +20% |
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

- The card UI shows what the ingredients add up to (statuses, or families; never an unowned Warden's name: see *How Needs are shown on a card*) so players can plan toward a combo.
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
| **Deep Sleep** | Rare | all Wardens +60% damage (2026-10-05) | no rest bonus for the rest of the run |
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

### Build packages: do the cards come? (2026-09-30)

Since Dreamlight, a build's **Wardens** are a choice (only the family picks are luck: with a full
Grove, both families of a two-family build by drift 25 / 50 / 75 in ~22% / 50% / 73% of runs; with
3 families, always). This measures the other half: **the cards that make the build sing**. Each
build has a **package** of enhancer cards (Legendaries aren't in packages: they start builds).

| Build | Families | Package (ids) |
|---|---|---|
| **Storm Grid** | Firefly Jar + Dewdrop | Rolling Thunder, Rain on Glass, Soaked Through, Heavy Dew, Brighter Jars, Charged Field (`static_field`), Conductive Soil |
| **Spore Bomb** | Sporeling (+ Dewdrop for Mistveil) | Soft Spores, Lingering Spores, Spore Cascade, Chain Bloom, Soaked Rot (was Sparking Spores, which needs Firefly Jar: a package mistake), Twin Puff |
| **Eldest (tall)** | any | Tender Care, Warm Hands, Kindred Roots, Deeper Rings, Sunlit Rest, Chosen Few |
| **Wide Sprouts** | any | Seedfall, Sprout Surge, Sprout Chorus, Root Network, Seedling Gift, Many Hands |
| **Kinship** | one family, both branches | Quick Bonds, Family Ties, Sweet Harmony, Close Kin, Old Friends, Rooted Bond, Extended Family |

**Measurement** (offer simulation, no combat; `DreamState.sim_rest` / `DreamSimPolicy`):
- Profile: **full Grove, everything discovered** (so Grove and discovery gates don't hide cards).
- The bot owns the build's families and board (e.g. Storm Grid: Stormcap + Rain Lily from drift
  25; Eldest: a rank V Warden from drift 20), and **takes a package card whenever one is offered**,
  else its style's best card. Stacking cards count once.
- Report per build, 1000 seeded runs: **% of runs with 3+ and 5+ package cards by drift 25 / 50 /
  75 / 100**, the average count, and the share of offers with at least one package card.
- **Targets** (the "Adapt, don't get handed" balance: a build should come together, not be handed):
  - **3+ package cards by drift 50** in **~50–70%** of runs.
  - **5+ by drift 100** in **~50–70%** of runs.
  - **5+ never above ~90%** at any checkpoint (that's being handed the build). 3+ late in the run
    may go higher (revised after the first measurement: 3 of 7 by drift 100 is normal, not handed).
  - A package card in **~30–45%** of offers.
- **If a build is short:** check its Needs and discovery gates first (a card that's rarely eligible),
  then its rarity (a Rare-heavy package lands late), before touching tag weighting, which moves every
  build at once.

**First measurement (tools/build_packages.gd, 1000 runs each, 2026-09-30):** Storm Grid on target
(3+ by 50: 73%, 5+ by 100: 51%, 30% of offers). Short: Spore Bomb (package mistake, fixed above),
Kinship (43% / 33% / 25%), Wide Sprouts (32% / 18% / 19%), Eldest (6% / 5% / 12%). Causes: Eldest's
follow-ups wait for an opener card *and* ranked Wardens; card-built directions (wide, nurture, sprout)
only get the build weighting after their first card, while families get it at the family pick.

**Your Dreams steer your Dreams, not your family picks** (user, 2026-09-30, restating *Adapt, don't
get handed*: *"I want you to be able to adapt to the cards you get, not have the cards given to you
because you chose that family."*). This replaces the fixes first proposed after the measurement
(one of them, "directions read the board", was the game recognising your build: withdrawn).
1. **Families no longer boost weighting.** Owning a family only makes its cards **eligible** (their
   Needs are met); they're drawn at **×1**, like any other eligible card. **Only tags of cards you've
   taken** (and taken Legendaries' archetypes) get `tag_weight`. So a build grows from the Dreams you
   choose, and a strong card from somewhere else can always pull you a new way.
2. **Lower `tag_weight` to ~1.6** (from 2.4, which was raised only to hold the family share): enough
   that a direction you've started keeps turning up, not enough to feed it.
3. **Nurture follow-ups:** "any `nurture` card" becomes a **soft** Need (×0.4 until met); their board
   Needs stay hard. This makes Nurture cards *tempt* players who never nurtured, not feed those who did.
4. **Bridge cards** (below) are the main tool for adapting: they sit between two builds, so the card
   you're offered can lead from what you have into its neighbour.
5. **The Stray slot and half-dreamed cards stay** as they are.

**New measurement targets** (replace the package targets above; the package table stays as the
list of what belongs to each build):
- **Adapt:** in **~70%+ of offers**, at least one card is **usable now** (hard Needs met) and **not
  yet part of your build** (no shared tag with cards you've taken).
- **Builds emerge from cards:** a bot with **no plan** (takes the best card for the board it has)
  ends drift 50 with **3+ cards of some package** in **~70%+** of runs, and **no single build is
  more than ~15%** of those runs (variety: the cards choose, not the family).
- **Chasing still works, but isn't handed:** a bot **chasing** one build gets 3+ of its package by
  drift 50 in **~35–55%** of runs, and 5+ by drift 100 in **~30–50%**. Above that, the build is being
  handed out; below, it's out of reach.
- **Own-family share of offered cards:** no target any more (it was the handed-out measure). Report it
  for reference only.
- Measure **every build in the catalogue** below.

### The build catalogue (2026-09-30)

User: *"look at all the builds possible, not just 5."* Every build in `tower_design.md` "Build
archetypes" plus the builds the card directions and Legendaries create. **Package** = its enhancers
(Legendaries are capstones, not package cards). A build needs **5+ enhancers** (with at least 2 it
can take early) and its **key card must exist**.

| # | Build | Wardens / source | Capstone | Package (existing enhancers) | Status |
|---|---|---|---|---|---|
| B1 | Storm Grid | Rain Lily + Stormcap | — | Rolling Thunder, Rain on Glass, Soaked Through, Heavy Dew, Brighter Jars, Charged Field, Conductive Soil | ✓ 7 |
| B2 | The Long Walk | Thornwalls + long maze | The Long Walk, Crossroads | Cozy Corners, Hedge Maze, Straightaway, Winding Path, Bitter Hedges, Echoing Steps, Heart of the Maze | ✓ 7 |
| B3 | Spore Bomb | Puffball + Mistveil | — | Soft Spores, Lingering Spores, Spore Cascade, Chain Bloom, Soaked Rot, Twin Puff, Mushroom Rain | ✓ 7 |
| B4 | Sniper's Rest | Beacon + Moonstone | — | Long Shadows, Patient Aim, Starlit Aim, Called Shot, Sharpened Light, Solitude, Watchful Rest, Hunter's Patience | ✓ 8 |
| B5 | Full Moon | Moonstone + Hoarfrost + Magpie's Hoard | Full Moon | Glinting Dew, Sharpened Light, Still Target, Shattering Blow, Deep Frost, Shiny Things, Reckless Bloom | ✓ 7 |
| B6 | Gale | Gust / Zephyr + a status family | — | Carried on the Wind, Lasting Dreams | ❌ 2 → new: **Ill Wind**, **Eddy** |
| B7 | Fairy Mines | Elf Circle + Honeysuckle + Tangleroot | — | Ring Dance, Sweet Scent, Scented Hedge, Deep Grip, Root Web, Lingering Spores | ✓ 6 |
| B8 | Hairpin Mill | Windmill + Thornwalls | Rootbound | Hairpin Winds, Cozy Corners, Hedge Maze, Crowded Path | ⚠ 4 → new: **Spinning Corners** |
| B9 | Sleepy Hollow | Bellflower + Dreamcatcher + Dreamshroom | — | Heavy Eyelids, Hush, Bad Dreams, Many Threads, Lullaby, Clear Tones, Chorus, Heavy Air | ✓ 8 |
| B10 | Storm Corridor | Rain Lily + Samara + Stormcap | — | Windborne Rain, Straightaway, Longer Flight, Rolling Thunder, Rain on Glass, Heavy Dew | ✓ 6 |
| B11 | Thousand Cuts | Jewelwing Court + Firefly / Rain Lily + Beacon | — | Charged Feathers, Thousand Cuts, Sharp Beaks, Needle Point, Called Shot, Bright Marks | ✓ 6 |
| B12 | Encore | Whispering Hollow + Reactions | Dawnbreak | Encore, Quick Reactions, Seeping, Kin and Kindling + the Reaction cards | ✓ |
| B13 | Rockfall | Rockslide + Snugroot + Bloomcap | — | Loose Stones, Shattering Blow, Heavy Stones, Crowded Path | ⚠ 4 → new: **Falling Weight** |
| B14 | Deep Poison | Puffball + Mistveil + Echo Hollow | Nightshade | Seeping, Bitter Sap, Venom Bloom, Soft Spores, Lingering Spores, Soaked Rot, Lasting Dreams | ✓ 7 |
| B15 | Thunder Chimes | Stormcap + Chime Stone | — | Clear Tones, Charged Field, Brighter Jars, Chorus | ❌ key card *Resonance* missing → new: **Resonance** |
| B16 | Bramble Maze | Thornwalls / Brambles + Snugroot | Briar Crown | Hedge Maze, Bitter Hedges, Weathered Walls, Living Walls, Thorn Snare, Bramble Oath, Cheap Hedges | ⚠ key card *Thornheart* missing → new: **Thornheart** |
| B17 | The Grove | Grove Heart + a tight cluster | Rootbound | Grandfather Stump, Kind Canopy, Shared Light, Hedgerow Roots | ⚠ 4 → new: **Warm Hearth** |
| B18 | Greedy Gardener | Dewcatcher → Wellspring | Golden Harvest | Dew Bowl, Harvest Moon, Deep Well, Wide Bowl, Still Waters, Overflowing Well, Dew Trail, Gathered Dew | ✓ 8 |
| B19 | Eldest (tall) | any, ranks | Endless Rings, The Old Ones, Court of the Eldest | Tender Care, Warm Hands, Kindred Roots, Remembered Care, Sunlit Rest, Deeper Rings, Chosen Few, Nursery | ✓ 8 (weighting fix) |
| B20 | Wide Sprouts | Sprouts everywhere | Rootbound | Seedfall, Sprout Surge, Sprout Chorus, Root Network, Seedling Gift, Many Hands, Canopy, Nursery | ✓ 8 (weighting fix) |
| B21 | Lone Lantern (narrow) | ≤ 8 attackers | The Last Light | Solitude, Few and Mighty, Heart of the Maze, Watchful Rest, Chosen Few | ✓ 5 |
| B22 | Kinship | one family, both branches | Grove of Kin | Quick Bonds, Family Ties, Sweet Harmony, Close Kin, Old Friends, Rooted Bond, Extended Family, Blood Is Thicker | ✓ 8 (weighting fix) |
| B23 | Clearing | tend the forest | Wildwood Reclaimed | Cleared Ground, Heartwood's Reach, Reclaimed Earth, Tended Forest | ⚠ 4 → new: **Fresh Soil** |
| B24 | Tempo | call every drift early | Restless Night | Call of the Wild, Fresh Growth, Echoing Steps | ❌ 3 → new: **Quick Step**, **Hurried Harvest** |
| B25 | Last Leaf | play near losing | Last Leaf | Last Stand | ❌ 1 → new: **Heartwood's Fury**, **Thin Bark** |
| B26 | Menagerie | one of everything | Menagerie | — | ❌ 0 → new: **Patchwork**, **Mixed Grove** |
| B27 | Hunter's Moon | Marked | Hunter's Moon | Bright Marks, Lingering Mark, Called Shot, Guiding Light, Starlit Aim | ✓ 5 |
| B28 | Eternal Charge | Charged | Eternal Charge | Charged Field, Charged Bloom, Brighter Jars | ⚠ 3 → new: **Live Wire**, + Resonance |
| B29 | Rooted Nightmares | Held | Rooted Nightmares | Deep Grip, Tangled Release, Long Light, Root Web, Patient Roots, Still Target | ✓ 6 |
| B30 | The Quiet Ones | support Wardens | The Quiet Ones | Kind Canopy, Shared Light, Hedgerow Roots, Grandfather Stump, Many Threads, Dew Trail | ✓ 6 |
| B31 | Crit (any) | crit-heavy Wardens | Full Moon | Glinting Dew, Sharpened Light, Still Target, Shattering Blow, First Light, Called Shot | ✓ 6 |
| B32 | Swarm clearing | area Wardens | — | Crowded Path, Last Breath, Thinning the Herd, Shattering Blow | ⚠ 4 (bridges below add) |
| B33 | First strike | many single hits | — | First Light, Called Shot, Lone Hunter | ⚠ 3 (small on purpose: it's a side-direction of Crit and Hunter's Moon) |

### New cards for the catalogue (2026-09-30)

User: *"there should be cards that can fit in multiple builds and double dip."* **Bridge cards** carry
**two build tags**: they're weighted up if you own either, and they count in **both** builds'
packages. Enhancers only (never Legendary); each half does something alone. Most also fill a thin
build from the catalogue. Needs follow *How Needs are shown* (families, statuses). All Start pool
unless noted; family cards join through discovery as usual.

| # | Card | Rarity | Builds (tags) | Effect | Needs |
|---|---|---|---|---|---|
| 204 | **Elder Kin** | Uncommon | Eldest + Kinship (nurture, kinship) | ranked Wardens in a Kinship share **25% of their rank bonuses** with their kin | a ranked Warden (soft) |
| 205 | **Many Rings** | Uncommon | Eldest + Wide (nurture, sprout) | each rank on any Warden gives all Sprouts **+1% damage** (max +25%) | — |
| 206 | **Big Family** | Uncommon | Wide + Kinship (sprout, kinship) | Sprouts within 2 cells of a Kinship pair **+10% attack speed** | — |
| 207 | **Mycelium** | Uncommon | Spore + Wide (spore, sprout) | Sprouts touching a Sporeling-line Warden apply **1 Poisoned** on hit | Sporeling |
| 208 | **Fireflies in the Grass** | Uncommon | Storm + Wide (storm, sprout) | Sprouts touching a Firefly-line Warden add **1 Charged** every 3rd hit | Firefly Jar |
| 209 | **Seasoned Eye** | Uncommon | Eldest + Crit (nurture, crit) | **+1% crit chance per rank** (max +7%, reachable only by the Eldest) | — |
| 210 | **Hedgerow** | Common | Walls + Wide (wall, sprout) | Sprouts touching a Thornwall **+10% damage** | — |
| 211 | **Spore Kin** | Uncommon | Spore + Kinship (spore, kinship) | Harmony strikes by Sporeling-line kin apply **2 Poisoned** | Sporeling |
| 212 | **Resonance** | Rare | Thunder Chimes + Eternal Charge (song, storm) | Chime Stone pulses **count as lightning**: each nightmare hit gains **1 Charged** | Bellflower + Firefly Jar (half-dreamed rules apply) |
| 213 | **Thornheart** | Rare | Bramble Maze + Long Walk (wall, maze) | Brambles' thorns deal **+5% per Bramble you own** (max +100%) | Bramble unlocked |
| 214 | **Ill Wind** | Uncommon | Gale + Deep Poison (wind, potency) | statuses **copied by Gust / Zephyr** deal **+25% effect damage** | Whirligig |
| 215 | **Eddy** | Uncommon | Gale + maze (wind, maze) | Gust copies also reach nightmares **on the path tiles beside** the target (bends count double) | Whirligig |
| 216 | **Spinning Corners** | Uncommon | Hairpin Mill + Long Walk (wind, maze) | Pinwheel / Windmill **beside a bend spin 20% faster** | Whirligig |
| 217 | **Falling Weight** | Uncommon | Rockfall + Rooted / Sleepy (stone, held) | Pebbling-line lobs and shots **+40% against Held or Asleep** nightmares | Pebbling |
| 218 | **Warm Hearth** | Uncommon | The Grove + Wide (support, sprout) | aura Wardens' bonuses are **+50% on Sprouts** | an aura Warden (Acorn family) |
| 219 | **Fresh Soil** | Common | Clearing + Wide (clearing, sprout) | a Sprout planted on a **cleared cell** gets **+20% damage** and costs 7 | a clearing card (counts as one: unlocks clearing) |
| 220 | **Quick Step** | Common, stacks (max 3) | Tempo (tempo) | calling a drift early gives all Wardens **+10% attack speed for 10 s** | — |
| 221 | **Hurried Harvest** | Uncommon | Tempo + economy (tempo, economy) | nightmares of a drift you **called early** give **+1 Dew** (cap 20 per drift) | — |
| 222 | **Heartwood's Fury** | Uncommon | Last Leaf + Long Walk (leaves, maze) | Wardens within 4 cells of the Heartwood **+3% damage per missing leaf** (max +30%) | — |
| 223 | **Thin Bark** | Uncommon, **Bittersweet** | Last Leaf (leaves) | all Wardens **deal 35% more damage** (data; power pass). **Cost:** −3 max leaves (and lose them now) | act 2+ |
| 224 | **Patchwork** | Common | Menagerie (variety) | **+3% damage per family you own** (max +12%) | — |
| 225 | **Mixed Grove** | Uncommon | Menagerie + maze (variety, maze) | a Warden touching a Warden of **another family** **+8% damage** (max +24%, one per neighbouring family) | 2 families |
| 226 | **Live Wire** | Common, stacks (max 3) | Eternal Charge + Storm Grid (storm) | Charged bolts **+15%** | a Warden that applies Charged |

- **Build tags:** `sprout` joins the direction tags (fix 2); the new archetype tags are `tempo`,
  `leaves`, `variety`, `support`, used by weighting like the others.
- **Packages** in the catalogue gain each bridge under both builds (e.g. Elder Kin counts for Eldest
  and Kinship). After this, no build has fewer than 5 enhancers except *First strike* (by design).
- **Pool size:** +23 cards (≈226). Most are gated by family or direction, so a given run sees far
  fewer; the measurement's "share of offers with a package card" is the check that dilution isn't
  winning. If it is, the lever is the Stray / generic weight, not removing bridges.
- **Numbers to check** with the tower design chat: Resonance with the Static bolt rate (Thunder
  Chimes could chain bolts constantly), Eddy's reach on hairpin mazes, Thin Bark vs Leaf Fall.

### After the catalogue measurement (2026-09-30)

Measured (a6b41172): **Adapt 97%** of offers hold a usable card outside your build (target 70%+);
own-family share 8%. Chasing is in band for Long Walk, Spore Bomb, Encore, Bramble Maze, Kinship
(Sleepy Hollow, Greedy Gardener just under); Storm Grid and Wide Sprouts are above (left as they are
for now: one easy hub and one flagship). Many builds were short because **11 designed cards were
never built** (Glinting Dew, Sharpened Light, Heavy Stones, Long Shadows, Patient Aim, Deep Frost,
Shiny Things, Carried on the Wind, Ring Dance, Sweet Scent, Hairpin Winds; now being built) and
because the power pass (`dream_audit.md`) cut or merged Echoing Steps, Still Waters, Fair Trade,
Cheap Hedges, Quick Bonds and Wide Bowl. The Emergence number (38%, Long Walk 63%) is skewed by the
Balanced bot; re-run with a random picker.

**Cards for the builds still under 5** (sized to the `dream_audit.md` power budget; no card rewards
changing the maze mid-drift, the reason Echoing Steps was cut). User-approved.

| # | Card | Rarity | Build (tags) | Effect | Needs |
|---|---|---|---|---|---|
| 227 | **Head Start** | Uncommon | Tempo (tempo) | a drift you **called early**: its nightmares take **+40% damage** for the first 10 s after they arrive | — |
| 228 | **Second Wind** | Rare | Tempo (tempo, dreams) | call **every drift of a block** early: the next Dream offers **4 cards, one Rare+** | — |
| 229 | **Scarred Bark** | Uncommon | Last Leaf (leaves) | **+3% damage per leaf lost this run** (max +45%; regrowing doesn't lower it) | — |
| 230 | **Desperate Bloom** | Rare | Last Leaf (leaves) | while below **half your max leaves**, all Wardens **+50% attack speed** | act 2+ |
| 231 | **Odd One Out** | Uncommon | Menagerie (variety) | a Warden that's the **only one of its kind** on the map **+45% damage** | — |
| 232 | **Grand Tour** | Rare | Menagerie (variety) | **+10% damage per different status** your Wardens can apply (max +70%) | 2 statuses |
| 233 | **Crush** | Common | Swarm (swarm) | area attacks deal **+30%** to a nightmare **touching 2+ other nightmares** | — |
| 234 | **Crowd Breaker** | Uncommon | Swarm (swarm) | an area attack deals **+5% per nightmare it hits** (max +45%) | — |

- **Swarm tag:** add `swarm` to Crowded Path, Last Breath, Thinning the Herd and Shattering Blow so the
  build's weighting works (a tag only; their effects are unchanged).
- **Scarred Bark vs Last Leaf:** Last Leaf pays for leaves missing *now*; Scarred Bark for leaves lost
  *ever*. So a player can leak, regrow and keep the Scarred Bark bonus: the two pull differently.
- **Odd One Out vs Monoculture:** the opposites of each other, which is the point.
- **Deepened:** Head Start II (+60%), Scarred Bark II (+4% per leaf, max +60%), Odd One Out II (+65%),
  Crush II (+45%).
- After these (and the 11 cards being built), every catalogue build has **5+ real enhancers** except
  First strike (by design).

## Pool trim (2026-09-30, user: option 2 "shrink the pool")

**Why:** a run sees **57 cards** (19 Dreams × 3). Slay the Spire's builds come together with no
synergy weighting because a character's pool (~75) is about what a run sees (~80 + shops). Ours was
**223 base cards**, 145 of them generic (always in play), so a typical run drew from ~180 and saw
under a third of it; small builds never came together (catalogue measurement a6b41172: Emergence
15–52%, most card builds 0–25% when chased). Weighting can't fix that ratio without handing builds
out, so the pool shrinks instead, in two layers. Merged cards take the **stronger** number (per the
`dream_audit.md` budget), not the sum.

### Layer 1: redundant, too small, or breaking a rule (~29 cards)

| Area | Merged into | Cut |
|---|---|---|
| Bittersweet (14 was too many) | — | Borrowed Dew, Hungry Roots, Overgrown, Wild Growth, Reckless Bloom, Overgrowth, Borrowed Memory |
| Economy | **Gathered Dew → Morning Dew** (+20 now, +10 each rest, nightmares +10% Dew) | — |
| Clearing | **Fresh Soil → Reclaimed Earth** (fertile cells also give Sprouts +20%); **Tend the Forest → Heartwood's Reach** (it gave 2 *free* clears, which breaks "clearing always costs Dew") | — |
| Leaves | **Mending Bark → Thick Bark** (saves the first leak each block; a perfect block regrows 1); **Heartwood's Fury → Last Stand** (+35% near the Heartwood, +3% more per missing leaf) | — |
| Tall | **Warm Hands → Tender Care** (−15% nurture cost and +3% damage per rank, stacks); **Court of the Eldest → Endless Rings** (taking it also names the Eldest and gives touching Wardens 25% of its rank bonuses) | Remembered Care (exploit-prone), Seasoned Eye, Many Rings |
| Wide | **Sprout Surge → Seedfall** (Sprouts cost 6 and +30% soothe) | Big Family |
| Kinship | **Close Kin → Extended Family** (reach 3 and two Kinships per Warden) | — |
| Generic | **Skyward Gaze → Hunter's Patience** (+ flyers: +40% and +1 range) | Sudden Bloom, Underdog, Cliffside |
| Status | — | **Tangled** (it slowed; slowing belongs to Drowsy, `tower_design.md` "Status jobs") |
| Swarm / Tempo / Variety / Walls | **Crush → Crowd Breaker**; **Hurried Harvest → Call of the Wild** | Patchwork, Hedgerow |

### Layer 2: fewer, broader card builds

Slay the Spire's characters have ~4–6 archetypes in 75 cards; we had ~15 card-driven builds. Neighbours
merge into **10 card builds**, each with one **archetype tag** that weighting reads (taking one card
of it boosts the whole build, so chasing works with a smaller pool). The 18 **Warden-combo builds**
(Storm Grid, Spore Bomb, Sleepy Hollow…) are family-gated, don't dilute, and stay as they are.

| Card build (tag) | Was | Enhancers | Legendaries |
|---|---|---|---|
| **Tall** (`tall`) | Eldest + Lone Lantern | Tender Care, Kindred Roots, Sunlit Rest, Deeper Rings, Chosen Few, Nursery, Elder Kin, Solitude, Few and Mighty | Endless Rings, The Old Ones, The Last Light, Monoculture |
| **Overgrowth** (`overgrowth`) | Wide Sprouts + Menagerie | Seedfall, Sprout Chorus, Root Network, Seedling Gift, Canopy, Many Hands, Mixed Grove, Odd One Out, Grand Tour | Menagerie, Rootbound |
| **Daring** (`daring`) | Tempo + Last Leaf | Call of the Wild, Fresh Growth, Head Start, Quick Step, Second Wind, Scarred Bark, Desperate Bloom, Thin Bark, Last Stand | Restless Night, Last Leaf |
| **Precision** (`precision`) | Crit + First strike + Sniper's cards | Glinting Dew, Sharpened Light, Shattering Blow, Still Target, First Light, Lone Hunter, Hunter's Patience, Watchful Rest | Full Moon |
| **Affliction** (`affliction`) | Potency + status cards | Bitter Sap, Seeping, Venom Bloom, Lasting Dreams, Heavy Air | Nightshade |
| **Maze** (`maze`) | Long Walk + walls + Hairpin | Cozy Corners, Straightaway, Winding Path, Heart of the Maze, Forest's Edge, Hedge Maze, Bitter Hedges, Thornheart, Weathered Walls | The Long Walk, Crossroads, Briar Crown |
| **Tending** (`tending`) | Clearing + economy | Cleared Ground, Heartwood's Reach, Reclaimed Earth, Tended Forest, Burn Back, Morning Dew, Evergreen | Wildwood Reclaimed |
| **Kinship** (`kinship`) | Kinship | Family Ties, Sweet Harmony, Old Friends, Rooted Bond, Extended Family, Kin and Kindling, Blood Is Thicker, Elder Kin | Grove of Kin |
| **Swarm** (`swarm`) | Swarm | Crowd Breaker, Crowded Path, Last Breath, Thinning the Herd, Shattering Blow | — |
| **Support** (`support`) | The Quiet Ones | Living Walls, Scented Hedge, Thorn Snare, Warm Hearth (+ the Acorn family's cards) | The Quiet Ones |

- **Layer 2 cuts:** Shelter of Stones, Short Roots (their builds are covered by broader cards).
- **Always-useful basics stay untagged:** Quickened Sap, Deeper Calm, Longer Roots, Deep Roots,
  Thick Bark; and the Dreams / Dreamlight cards (Lucid Dreaming, Wandering Mind, Sudden Insight,
  Glimmering Hunt), Deep Sleep, Restless Dreams.
- **Weighting:** the archetype tags replace `nurture` / `narrow` / `wide` / `sprout` / `tempo` /
  `leaves` / `variety` / `crit` / `potency` / `status` / `wall` / `clearing` / `economy` as build tags
  (cards keep the old tags for rules). Opposition: **Tall ↔ Overgrowth ×0.5** (was narrow ↔ wide). A
  card can carry two archetype tags (bridges: Elder Kin is `tall` + `kinship`; Shattering Blow
  `precision` + `swarm`).
- **Result:** ~223 → **~192 base cards**; a typical 4-family run can be offered **~120** (was ~180), and
  each card build is one tag of 5–9 enhancers, so one taken card lifts the whole build.
- **Measure again** (Emergence with the random and mixed pickers, Chasing for all 10 card builds and
  the Warden-combo builds, Adapt) and tune **only `tag_weight`** (1.6 → at most 2.2) if chasing is
  still short; Adapt must stay ≥ 70%.

**Trim measured (a1535394):** Emergence rose a lot: **mixed picker 74%** (was 52%; target 70% ✓),
random 25% (was 15%); Adapt 94–95% ✓. Chasing in band for Overgrowth, Daring, Maze, Tending (Kinship,
Precision just under). **`tag_weight` has run out:** 1.6 → 2.2 gains weak builds only +3–6 points and
pushes Maze / Tending / Support over the top, so it **stays at 1.6**. What limits the rest is the
packages. Round 2 (my call, within the user's "solve and balance" brief):

1. **Swarm merges into Affliction** ("wear the crowd down": effect damage and area damage). Affliction's
   enhancers: Bitter Sap, Seeping, Venom Bloom, Lasting Dreams, Heavy Air, Crowd Breaker, Crowded Path,
   Last Breath, Thinning the Herd (9). Shattering Blow stays in Precision. The `swarm` tag becomes
   `affliction`. **9 card builds.**
2. **Tall gets an early door:** **Sunlit Rest** works with no ranked Warden (it gives rank I to your
   attacking Warden nearest the Heartwood), and it drops its "any `nurture` card" Need, so it's an
   opener like Tender Care. **Kindred Roots** needs **1** ranked Warden (was 2). Deeper Rings / Chosen
   Few keep their rank V Needs (they're the late half).
3. **Support's package** is its own 5 cards (Living Walls, Scented Hedge, Thorn Snare, Warm Hearth,
   Kind Canopy), not "+ the Acorn family's cards": those belong to The Grove / Greedy Gardener.
4. **Families count after you choose their cards:** a family line tag (spore, water, storm, …) joins
   your build tags **once you've taken a card with that tag**, never from the family pick. This is
   what the Warden-combo builds (Full Moon, Fairy Mines, Thunder Chimes, The Grove…) were missing:
   their cards are family cards, and with only archetype tags weighting, a family you'd started
   dreaming toward never came back. Same `tag_weight` (1.6).
5. **Maze may be the most common build.** It sits at ~38% of emerging runs (with The Long Walk's
   overlap), over the 15% cap, because maze cards help every board. In a maze tower defense that's
   the right default; the cap applies to every **other** build.

**Round 2 measured (3e4482f0):** the Swarm → Affliction merge worked (Affliction 7% → 35%). **Family
line tags backfired:** once you took one family card, the whole family's many cards weighed ×1.6, so
strong Warden-combo builds rose (Storm Grid 85 → 89, Spore Bomb 65 → 73) while every card build fell
2–7 points and Emergence (mixed) dropped 74% → 70%; the weak combo builds didn't move. The Tall
opener didn't move Tall (14 → 16); Support at 5 cards collapsed to 1%. Round 3:

1. **Revert the family line tags** (round 2, point 4). Weighting reads the **archetype tags only**
   again. Warden-combo builds are driven by the family picks; their chasing numbers are for reference.
2. **Support merges into Tending** ("tend the forest and the quiet Wardens": clearing, economy, walls
   and auras that don't attack). Tending's enhancers: Cleared Ground, Heartwood's Reach, Reclaimed
   Earth, Tended Forest, Burn Back, Morning Dew, Evergreen, Living Walls, Scented Hedge, Thorn Snare,
   Warm Hearth, Kind Canopy (12); Legendaries Wildwood Reclaimed and The Quiet Ones. `support` →
   `tending`. **8 card builds.**
3. **Tall is a late build:** ranks cost Dew and grow over time, so Tall is measured at **3+ by drift
   75** (target 35–55%) instead of drift 50. Its package also drops **Nursery** (Entwined with
   Seedling Gift, a Sprout card: it belongs to Overgrowth), and **Tender Care loses its opener gate**
   (30 Dew spent on ranks): a nurture discount is useful the moment you think about nurturing.
4. **Measurement fix:** the Gale bot's board must include a status-applying family (Gale copies
   statuses; with none it measured 0%).

**Round 3 measured (8662fba0):** Emergence (mixed) **76%** ✓, random 28%, Adapt 93–94% ✓. In band:
Daring 44, Affliction 37, Maze 47, and Tall **48 at drift 75** ✓. Tending jumped to **87** (12 cards,
too many, like Support before); Overgrowth fell 32 → 23 because Tender Care is now an early opener
and a single Tall card halved Overgrowth's weight; Precision and Kinship sit at 26. Round 4:

1. **Tending back to 9:** Evergreen becomes an untagged basic (cheaper evolving helps everyone);
   **Kind Canopy** leaves (a Seed card: it belongs to The Grove / Greedy Gardener); **Warm Hearth**
   moves to **Overgrowth** (its aura boost is for Sprouts), so Overgrowth gets 10.
2. **Opposition needs commitment:** Tall ↔ Overgrowth halves the other side only once you own **2+
   cards** of one of them (one early discount card shouldn't close a direction).
3. **Precision picks up its family crit cards:** Heavy Stones and Called Shot also carry `precision`
   (family-gated, so they only count when you have Pebbling / Lanternmoth).
4. Kinship (26) is left as it is: it needs a Kinship on the map, which the Dreamlight change (free
   branches) now makes much earlier. Re-measure it with the free-branch grant in the bots.
5. **`tag_weight` is 1.3** (user playtest 2026-09-30, relayed by the story chat and in
   `run_design.md`'s difficulty pass: a first run reached drift 60 at full leaves with 1,746 Dew and
   *"felt like cards were handed to me"*). This overrides the 1.6 this trim was measured at; the
   package targets are checked again at 1.3.

**Round 4 measured (97eab598, 6b5e2a87):** with free branches and early finals every card build lost
5–16 points at drift 50: unlocking forms met the Needs of all their cards, so the pool grew by the
family cards (own-family share 10% → 12%). Tag weight 1.3 cost another 3–8. At drift **75** most
card builds sit at **40–66%**; Emergence (mixed) 66%, Adapt 93–94%. Round 5 (final for this pass):

1. **A Warden Need means one on the map, this run** (fixes Needs under free branches). A card whose
   Needs name a Warden is offered only once **you have built or grown one this run** (selling it later
   doesn't remove a taken card or block offers again). Owning the family, or having the form
   unlocked, is no longer enough. This is the old rule's meaning ("never offered until it can do
   something"); free branches had quietly broken it. Discovery (profile) still applies on top.
2. **Card builds are judged at drift 75**, not 50: in a 100-drift run where you should adapt, a build
   coming together by the middle of act 3 is right, and the user's playtest said builds came too
   easily. Chasing target: **3+ by drift 75 in 35–65%**, 5+ by 100 in 25–50%. Emergence stays
   judged at drift 50 (≥ 60% mixed).
3. `tag_weight` stays **1.3**. **Superseded 2026-09-30:** the user turned build tag steering off: `tag_weight` = **1.0** and the Tall ↔ Overgrowth ×0.5 opposition is removed. Offers are shaped only by rarity, the fade, the run's random pool, Needs and the Stray slot; archetype tags stay for tag resonance, the Legendary rules and measurement.

**Round 5 measured (a399d702) — the pass ends here.** At 1.3, all 8 card builds reach their target on
at least one measure:

| Card build | 3+ by 75 (35–65) | 5+ by 100 (25–50) |
|---|---|---|
| Tall | 40 ✓ | 10 ✗ |
| Overgrowth | 58 ✓ | 29 ✓ |
| Daring | 61 ✓ | 26 ✓ |
| Precision | 66 (edge) | 32 ✓ |
| Affliction | 73 (a bit high) | 30 ✓ |
| Maze | 70 (a bit high) | 31 ✓ |
| Tending | 73 (a bit high) | 38 ✓ |
| Kinship | 51 ✓ | 13 ✗ |

Emergence (mixed) **69%** ✓, random 21%; Adapt **94%** ✓; own-family 12%. **Open:** Tall and Kinship
are short at 5+ by 100 (both board-heavy, no stacking card: a card change if wanted, not weighting);
the three-family Warden builds (Full Moon, Gale, Hairpin Mill, Rockfall, Thunder Chimes, The Grove)
stay rare by nature; overall power after the free-branch change belongs to the balance sim
(`balance_simulation.md`), not to Dream weighting.

## The starting Dream pool (2026-09-30, user-approved)

**Status: approved by the user via the design hub ("implement"). Final Grove node list, costs and old-save rule: `meta_design.md` Section 3 (Meta Game Discussion, 2026-09-30); the "suggested homes" table below is superseded there (Kinship cards stay discovery, not a node; Lucid Dreaming is the Bittersweet tip).**
Why: a new account's first run can be offered most of the pool (123 base cards in the start pool:
32 C / 50 U / 31 R / **10 Legendary**), so builds come together too easily. Target **~25 C / 30 U /
10 R / 0 L**. Rules:
- **Starting pool** = the basics, the three starting families' cards, and **one or two "taster"
  cards per build direction**, so a new player meets every build without being handed one.
- **Build-defining cards** (a direction's payoffs and Rares, and **all Legendaries**) move to **Grove
  Card nodes, one direction per node** (Meta owns the nodes).
- **Not counted / unchanged:** family cards of **Grove families** (Pebbling, Rootling, Bellflower,
  Acorn, Nestling, Whirligig) stay "start pool" but can't be offered until that family is unlocked;
  **combo cards** stay start pool but are discovery-gated (a new account hasn't found the combo).
  So a brand-new account's first run really sees **~55** cards.

**The starting pool (65):**

| Rarity | Cards |
|---|---|
| **Common (25)** | *Basics:* Quickened Sap, Deeper Calm, Longer Roots, Deep Roots, Thick Bark · *Starting families:* Soft Spores, Brighter Jars, Heavy Dew, Bright Marks, Live Wire · *Combo (discovery):* Soaked Rot, Rain on Glass, Sparking Spores · *Economy:* Morning Dew, Call of the Wild · *Tasters, one per direction:* Tender Care (Tall), Seedfall (Overgrowth), Quick Step (Daring), Glinting Dew (Precision), Bitter Sap (Affliction), Winding Path (Maze), Cleared Ground + Heartwood's Reach (Tending / clearing), Family Ties (Kinship) · Lasting Dreams |
| **Uncommon (30)** | *Starting families:* Lingering Spores, Soaked Through, Lingering Mark, Twin Puff · *Bridges with them:* Mycelium, Fireflies in the Grass, Spore Kin · *Combo (discovery):* Rolling Thunder, Wildfire Spores, Mushroom Rain, Deep Water · *Maze basics:* Cozy Corners, Straightaway, Hedge Maze, Weathered Walls · *General:* Evergreen, Sudden Insight, Glimmering Hunt, Heavy Air · *Second tasters:* Crowded Path, Last Breath (Affliction), Lone Hunter, Watchful Rest (Precision), Sprout Chorus, Many Hands (Overgrowth), Kindred Roots (Tall), Sweet Harmony, Old Friends (Kinship), Fresh Growth, Head Start (Daring) |
| **Rare (10)** | *Starting families:* Charged Field, Guiding Light, Called Shot · *Combo:* Conductive Soil, Spore Cascade (Entwined) · *General:* Heart of the Maze, First Light, Root Network, Thinning the Herd, Steadfast |
| **Legendary (0)** | all Legendaries are Grove tips (or discovery, for Dawnbreak and Grove of Kin) |

**Moving to Grove nodes (suggested homes; Meta owns the final node list):**

| Direction node | Cards that move there | Tip (Legendary) suggestions |
|---|---|---|
| Tall | Solitude, Elder Kin, Few and Mighty (+ its existing Sunlit Rest, Deeper Rings, Nursery, Chosen Few) | The Old Ones + Endless Rings; The Last Light; Monoculture |
| Overgrowth | Mixed Grove, Odd One Out, Grand Tour (+ Seedling Gift, Canopy) | Menagerie; Rootbound |
| Daring | Scarred Bark, Thin Bark, Desperate Bloom, Second Wind, Last Stand | Restless Night; Last Leaf |
| Precision | Hunter's Patience (+ Still Target, Shattering Blow) | Full Moon; Hunter's Moon |
| Affliction | Crowd Breaker (+ Seeping, Venom Bloom) | Nightshade; Eternal Charge |
| Maze | Forest's Edge, Bitter Hedges (+ Burn Back) | The Long Walk; Crossroads; Briar Crown; Rooted Nightmares |
| Tending | Reclaimed Earth, Tended Forest, Thorn Snare, Bramble Oath | Wildwood Reclaimed; The Quiet Ones |
| Kinship | Rooted Bond, Extended Family, Blood Is Thicker | (Grove of Kin is discovery) |
| Swift / Wide Reach | their new cards (235–245) | Whirlwind Heart; Great Ripple |
| Dreams | Lucid Dreaming (a small node, or with Bittersweet) | — |

- **Counts after the move:** start pool 65 (+ Grove-family cards and discovery cards that a new
  account can't see yet). Each Grove direction node adds 2–5 cards, so buying one deliberately
  widens one build.
- **Interaction with the trim's measurements:** tasters keep every card build discoverable on run
  one (Emergence), while the payoffs need the Grove (a build you choose to grow into, across runs).
  Re-measure with a fresh-profile preset (`MetaRun.load_preset(&"fresh")`) after the move.

## Overlaps and names (2026-10-05, from the Dreams and Omens audit)

The design hub's read-only audit (`text_pass.md` "Dreams and Omens audit", 797758fe; user: *"no
overlap; clear on what they do"*) found overlapping cards and name clashes. Decided here:

**Overlaps resolved** (each card keeps its id):

| Card | Was | Now | Why |
|---|---|---|---|
| **Nightshade** (L) | effects +20% per status the nightmare carries | effects deal **double damage to nightmares carrying 4 or more statuses** | was a bigger Seeping; a Legendary starts a build (load 4 statuses) instead of enlarging an enhancer |
| **Deep Sleep** (Bittersweet) | +40% damage; −4 max leaves | **+60%** damage; **cost: no rest bonus for the rest of the run** | same trade as Thin Bark; now an economy cost |
| **Kind Canopy** | Wardens touching 3+ Wardens +20% | Wardens **touching an aura Warden** deal **35%** more damage | same trigger as Rootbound; it's a support card |
| **Last Stand** | +35% near the Heartwood **and** +3% per missing leaf | **+60%** near the Heartwood **only** (the merged Heartwood's Fury part is removed) | Last Leaf and Scarred Bark already scale with missing leaves |
| **Patient Aim** | +15% damage per second not fired | **+15% crit chance per second not fired** (up to +45%) | overlapped Watchful Rest; crit suits its snipers |

**Renames** (display names only; ids stay, so saves and code don't change):

| Id | Old name | New name | Clash |
|---|---|---|---|
| `crowded_path` | Crowded Path | **In the Thick** | the Omen Crowded Paths |
| `resonance` | Resonance | **Thunder Chimes** | the Resonance word on a Warden; also the removed "tag resonance" |
| `restless_night` | Restless Night | **Impatient Night** | Restless Wind, the Restless nightmares |
| `restless_dreams` | Restless Dreams | **Waking Dreams** | same |
| `restless_roots` | Restless Roots | **Stirring Roots** | same |
| `lucid_dream` | Remembered Path | **Borrowed Branch** | the Remember screen |
| `kind_canopy` | Kind Canopy | **Sheltering Boughs** | Canopy |
| `sprout_chorus` | Sprout Chorus | **Thicket** | Chorus |
| `lullaby` | Lullaby | **Slow Waking** | the Lullaby Bell Warden |
| `nursery` | Nursery | **Cradle** | the Spore Nursery Kinship |
| `eye_of_the_tempest` | Eye of the Tempest | **Tempest's Reach** | Eye of the Storm |
| `thorn_snare` | Thorn Snare | **Briar Trap** | the Snare Kinship |
| `thick_bark` | Thick Bark | **Hardened Bark** | the Omen Thick Blight |
| `quickening` | Quickening | **Hunt's Rush** | Quickened Sap |

- Older sections of this doc keep the old names where they record history; this table is the
  authority. Text that mentions a renamed card (e.g. a Deepened "II", an Entwined ingredient list)
  follows the new name.
- **Docs fixed:** Seeping (8% / up to 40%) and Thin Bark (35%) rows match the data. "Resonance" is no
  longer ambiguous: tag Resonance was removed (2026-10-02), and the card is now Thunder Chimes.
- Balancing Discussion checked the reworked Nightshade, Deep Sleep, Kind Canopy and Patient Aim
  against their budgets (balance_simulation.md 738088c3): the numbers above are theirs.
- **Built** in a4be7e06 (Roguelite Code): all 14 renames and their II cards (In the Thick II, Slow
  Waking II, Briar Trap II, Hardened Bark II); the Grove node texts are updated by Meta in 0d22495f.
  As built:
  - Deep Sleep zeroes the base and perfect-block rest bonus; Dreams that add to the rest bonus still add.
  - "Aura Warden" = `aura_radius` > 0 or the support role.
  - Patient Aim crits use the Warden's `crit_multiplier`; every Warden has one (default ×2).

## Fewer family boosters, more build shapes (2026-10-05)

User (via Meta Game Discussion): *"I feel like I am being given family cards most of the time; the
cards feel more like damage boosters instead of build enhancers or definers."*

**What the data shows** (start pool, base cards):
- 99 cards; about half need a Warden.
- Sporeling alone gates 9 Commons/Uncommons.
- 7 of the family cards are plain numbers: attack speed, crit, or a longer status.
- The pool isn't seeded by family; it's sampled at 60% from everything. Family cards only crowd the
  offers because every family card you could use stays eligible, and the lean pool sent most
  family-free build cards to the Grove.

**Decided:**
1. **At most 1 family card per offer.** A family card is one with a Warden in `requires` /
   `requires_any`. The other slots draw from cards
   that need no Warden, so every offer shows at least two non-family choices.
2. **At most 1 plain stat card per offer:** Deeper Calm, Quickened Sap, Longer Roots, Bitter Sap,
   Glinting Dew. The core keeps them in the pool, but they no longer fill offers in pairs.
3. **Cut the plain family stat cards** (and their II cards) from the game:
   - Brighter Jars, Clear Tones, Heavy Stones, Soft Spores: "the X line +N%". The Family Blessing
     is the one family stat card.
   - Lingering Mark, Lingering Spores, Soaked Through: Lasting Dreams already lengthens every status.
   - Spore Cascade loses its Lingering Spores need (Driftspore only).
4. **Six build shapes move from the Grove into the start pool as Uncommons.** Each says how to
   build, not how much damage to add:

   | Card | Shape | Grove node that loses it |
   |---|---|---|
   | Solitude | spread out | `elders` |
   | Drumbeat | pack tight | `light_feet` |
   | Momentum | single target | `quickening` |
   | Crowd Breaker | area | `seeping` |
   | Odd One Out | one of each | `mixed_company` |
   | Overlap | overlapping areas | `broad_strokes` |

   Meta Game Discussion rebalances those nodes.

Family cards that change how a family plays stay (Root Web, Eddy, Twin Puff, Chorus, Deep Water,
the combo cards). Balancing Code re-measures family cards per offer and plain stat cards per offer
after the build.

**Built** in e3826bff (offer caps, 10 cards removed, Spore Cascade needs only Driftspore) and 99d0217e (the six cards in the start pool, Momentum II and Odd One Out II with them; the Grove nodes land in the same merge). There is no Entwined guaranteed slot any more, so the cap has no exception.

**Measured** (Balancing Code, before c6fefe1b → after edbbbe1b, bot to drift 50, 20 seeds per group):
- Family cards per offer: 0.28–0.53 → 0.16–0.44. Plain stat cards per offer: 0.32–0.47 → 0.20–0.45.
- No offer had 2+ of either kind (0 of 579; it was up to 7% before).
- The six shapes now reach fresh profiles; before, fresh runs never saw them.
- Survival is 0.7–2.6 drifts lower, but other gameplay commits landed in between, so it isn't pinned on this change.
- Reading: even before, only about 1 card in 6–9 needed a family. The "damage booster" feel comes more from the many generic cards worded "deal X% more damage" than from family cards. That is the next lever.

## Fewer, bigger cards (2026-10-06; user-approved)

User: Dream cards should feel more impactful. Many are small stat bumps (+8% damage, +10% speed) that
can't be felt in play. The Dream screen shows no hover previews of how much a card adds
(screens_ui.md "Dream", ecbea61a), so **the card text must carry the meaning**. The user approved
the plan below on 2026-10-06 ("Yes, no juggling").

### Rules (all cards, from now on)

1. **Nothing stacks.** A card is taken once, at a number you can feel. Its second step is its
   Deepened **II** card. `max_stacks` is 1 everywhere, and "(stacks…)" leaves every text.
2. **Prefer a rule you can see over a number.** "Every 4th attack is a crit" beats "+8% crit chance".
3. **No trample triggers** (user: *"don't make cards that do stuff on trample, since the boss is the
   only trample unit"*). Also no trigger that only one rare nightmare kind sets off. Triggers must
   fire in most drifts.
4. **Build-defining cards** (tag `defining`, below): from act 2, every offer shows one.
5. **Bittersweet is dramatic on both sides** (below).

### A. The changes, card by card

| Id | Was | Now | Kind |
|---|---|---|---|
| `deeper_calm` | +15% damage (stacks) | all Wardens deal **30%** more damage; **II** +30% more | one copy + II |
| `quickened_sap` | +15% attack speed (stacks) | all Wardens attack **30%** faster; **II** +30% more | one copy + II |
| `longer_roots` | +0.5 range (stacks) | all Wardens reach **1 cell** further; **II** +1 more | one copy + II |
| `glinting_dew` | +8% crit chance (stacks, up to +24%) | **every 4th attack from each Warden is a crit** | rule |
| `bitter_sap` | +20% Potency (stacks) | **statuses your Wardens apply start with 1 extra stack** | rule |
| `live_wire` | Static bolts +15% (stacks, up to +45%) | **{static} bolts jump to a second nightmare** | rule |
| `lasting_dreams` | statuses +2 s (stacks, up to +6 s) | **statuses your Wardens apply last twice as long** | rule |
| `quick_step` | calling early: +15% speed for 10 s (stacks) | calling a {drift} early makes all Wardens attack **50% faster until it has fully arrived** | rule |
| `damp_rot` | +50% (stacks, up to +150%) | one copy at **+150%** | one copy |
| `sparking_spores` | +50% (stacks, up to +150%) | one copy at **+150%** | one copy |
| `rain_on_glass` | +35% (stacks, up to +105%) | one copy at **+105%** | one copy |
| `heavy_dew` | +50% wider, +2 s (stacks) | one copy: splashes **twice as wide**, {damp} **+4 s** | one copy |
| `heartwoods_reach` | 25% off (stacks, up to 50%) + 3 half-price clears | one copy: clearing costs **half**, + 3 half-price clears | one copy |
| `hush` | +25% pulse reach (stacks, up to +75%) | one copy at **+75%** | one copy |
| `longer_flight` | +1 cell (stacks, up to +3) | one copy at **+3 cells** | one copy |
| `sharp_beaks` | +1 hit (stacks, up to +3) | one copy at **+2 hits** | one copy |
| `dew_bowl` | +25 Dew now (stacks, up to +75) | one copy: **+60 Dew now** | one copy |
| `sudden_insight` | +1 Dreamlight now (stacks) | one copy: **+2 Dreamlight now** | one copy |
| `bright_marks` | Marked +20% | {marked} nightmares take **40%** more | bigger |
| `family_ties` | Kinship +20% (stacks) | **cut** (Blood Is Thicker and Kindred cover Kinship damage) | cut |
| `broad_splash` | +0.25 cells (stacks) | **cut**, folded into `far_reach`: area Wardens get +0.75 range **and splash 0.5 cells wider** | fold |
| `acorn_cache` | Acorns 12 Dew, aura +10% | **cut**, folded into `warm_hearth`: aura bonuses are 50% stronger on Sprouts, **and Acorns cost 12 Dew** | fold |
| `weathered_walls` | can't be trampled + cost 1 Dew | **Thornwalls cost 1 Dew** (only; no trample, no resell rule: "no juggling") | trample rule |
| `thorn_snare` (Briar Trap) | Phantoms / Gravecrawlers through a wall are held 0.5 s | **each Thornwall holds the first nightmare that passes beside it each {drift} for 0.5 s**; II: 1 s | trample-like rule |
| `flurry` | Grove (node `quickening`) | **start pool**, Common: every 5th attack from a Warden fires twice | moved |

**New Commons** you can see (cards 257–261, start pool, no needs):

| # | Card | Effect | Tags |
|---|---|---|---|
| 257 | **Thorny Walls** | Thornwalls lash one nightmare beside them every second (a Sprout's damage) | wall, maze, defining |
| 258 | **Passing Dream** | A dispelled nightmare's statuses jump to the nearest nightmare | status, affliction |
| 259 | **Lantern Glow** | The path tiles in each Warden's reach glow; nightmares on glowing tiles can't hide in fog and take 15% more | light, reach |
| 260 | **First Frost** | The first nightmare of each {drift} is {held} 2 s at the first Warden it meets | held, tempo |
| 261 | **Dew Line** | Every 10th nightmare dispelled in a {drift} drops its Dew share twice | economy |

Net count: −3 cuts, +5 new Commons, Flurry moves. Each stacking card collapses from up to 3 copies
to 1. Deepened II files: new ones only for Deeper Calm, Quickened Sap and Longer Roots. The
Deepened ones that exist stay.

### B. Build-defining cards: tag `defining`

- **What counts:** the card adds a rule that rewards building around it (where you plant, how
  Wardens attack, timing, maze shape), works with any families, and changes what you plant next.
- **What doesn't:** flat stats, economy, single-family payoffs, leaves.
- **Start-pool set** (Roguelite Code adds the tag):
  - Solitude, Drumbeat, Momentum, Crowd Breaker, Odd One Out, Overlap, Twig Walls
  - Cozy Corners, Straightaway, Lone Hunter, In the Thick, Thicket, Root Network, Heart of the Maze
  - Watchful Rest, First Light, Old Growth, Fresh Growth, Head Start, Last Breath, Thinning the Herd
  - Hedge Maze, Seedfall, Tender Care, Extended Family, Quick Reactions, Thorny Walls
  - **Every Legendary** counts as defining.
  - Grove cards that fit get the tag too (Bramble Oath, Forest's Edge, Last Stand, Mixed Grove,
    Drumbeat-style placement cards); Roguelite Code tags them by this definition and lists them back.
- **Offer rule:** from act 2 (drift 26+), every offer holds **at least 1 `defining` card you don't
  own**.
  - If the draw has none, the lowest-rarity non-family slot is swapped for a random unowned defining
    card of that rarity, or an Uncommon if there is none.
  - It works with "1 family / 1 plain stat per offer".
  - Which defining card appears is random, so the player still adapts, never handed a build.
  - Once every defining card is owned, the rule stops.
- **On screen:** a small "build" mark on defining cards (Main / UI Code; the look is UI's).

### C. Bittersweet: both sides dramatic

The spike is about **double a normal Rare**. The price is felt every drift or rest, never a quiet
−15%. Numbers below are targets; Balancing Discussion sets them.

| Card | Spike | Price |
|---|---|---|
| **Thin Bark** | all Wardens deal **75%** more damage | the Heartwood's max leaves are **halved**, and you lose them now (never offered if it'd end the run) |
| **Venom Bloom** | Potency **×2** | direct hits deal **40% less** |
| **Blood Is Thicker** | Wardens in a {kinship} deal **double** damage | Wardens outside one deal **half** |
| **Chosen Few** | rank V+ Wardens deal **double** damage | Wardens below rank III deal **half** |
| **Deep Sleep** | all Wardens deal **80%** more damage | no rest bonus, **and Omens can't be faced**, for the rest of the run |
| **Burn Back** | every Withered Tree is cleared **free, now** (no Seeds for them) | nightmares move **20% faster** for the rest of the run |
| **Waking Dreams** (`restless_dreams`) | the next Dream offers **3 Legendaries** | Dreams can't be let pass, and **every offer shows 2 cards** for the rest of the run |

### Who does what

- **Balancing Discussion:** numbers for A (one-copy values, the 5 new Commons), B (nothing) and C.
- **Roguelite Code:** all card data, `max_stacks` 1, the `defining` tag + offer rule, the new II
  cards, Deep Sleep's Omen lock and Waking Dreams' 2-card offers.
- **Tower Code:** Thorny Walls (Thornwall attack), Briar Trap's new hold, Glinting Dew's 4th-attack
  crit, Live Wire's jump, Lantern Glow, First Frost, Flurry if its hook moves.
- **Main / UI:** the "build" mark.
- **Meta Game Discussion:** Flurry leaves node `quickening`; Broad Splash and Acorn Cache are cut
  (check which nodes list them).

## Twig Walls: one-half Thornwalls (2026-10-05; card 256)

User (typed in Environment Discussion): *"make a card that makes walls 1x1 cell instead of the
standard 4x4"*.

On the half grid (`half_cells.md`), a Warden's footprint is 2×2 half cells, and nightmares fit
through one-half gaps. So this card makes the **Thornwall** take a **single half cell (32 px)**.
The player builds finer, twistier mazes in the same space.

| # | Card | Rarity | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|---|
| 256 | **Twig Walls** | Rare | Thornwalls you plant take **one half cell** and cost **half** (rounded up, at least 1 Dew) | maze | — | Start |

- **Text:** "Thornwalls you plant take a quarter of the space and cost half as much."
- **New walls only.** Thornwalls already planted keep their 2×2 footprint; sell and replant to
  change them. No reshaping of the map when the card is taken.
- **Why half price:** a wall line two halves long has two small walls per big wall's length, so
  half price keeps the cost per length of wall the same. The gain is finer turns, not cheaper
  mazes.
- **Same rules as any wall:** the route can't be closed; walls can't go on an occupied half; selling
  and refunds go by Dew paid; it's saved with the run.
- **With other Thornwall cards:**
  - Weathered Walls: a twig wall costs 1 and can't be trampled.
  - Hedge Maze counts a twig wall as half a Thornwall.
  - Bitter Hedges and Hedgerow Roots work by touch as usual.
  - Living Walls skips twig walls: a Bramble needs a full footprint.
  - Thorn Snare / Briar Trap hold as usual.
- **Balance** (Balancing Discussion, balance_simulation.md fd7e1b0e): **`min_act` 2**, because act 1
  was tuned on full walls.
  - Price: half is right.
  - Cap: none yet. Twig corridors give about ×1.5 the route (73-cell mazes become ~100–110), worth
    about +40–50% damage, the Rare budget.
  - If `longest_path` on human runs with the card passes ~120 cells, it gets a cap (e.g. up to 30
    twig walls).
  - **Route probe** (balance_simulation.md f75724fe, 20 maps): the whole route is only ~10–15%
    longer, not ×1.5. Twigs add +40 / +55 / +59 cells vs Thornwall +29 / +43 / +51 at 10 / 20 / 30
    walls' worth. That's under the Rare budget: no cap, `min_act` 2 stays.
- **Who builds it:**
  - Roguelite Code: the card.
  - Tower Code: a one-half footprint for the Thornwall under the card, covering the ghost snap,
    blocking and refusal, sell and save.
  - Tower Assets: a 32 px Thornwall sprite.
  - Environment: no change; the path art already handles one-half pinches.
- **Built:** the card in 817e2146 (Roguelite Code; `DreamState.twig_walls()`, Hedge Maze counts a twig wall as half) and the wall in 527ac43d (Tower Code; Thornwall with `Tower.twig`, one half, saved per wall, 32×40 art).
- **Stacks with Bramble Verge** (the Heartwood's Gift that halves Thornwall prices): the twig half only keeps cost per length even, so other wall discounts apply on top (3 Dew → 2 with Verge → 1 as a twig; min 1).

## Strange Dreams: gamble cards (2026-10-05; cards 252–255)

For the Grove node **Strange Dreams** (Cards limb, 50 Seeds; user decision, `meta_design.md`
952b986e). Odd, swingy cards: **options, not raw power** (their average is near or under their
rarity's budget, the swing is the point), **generic** (no family, no combo). Each is a different
kind of gamble. Tag `strange` (not an archetype). Grove pool, one copy each.

| # | Card (id) | Rarity | Effect | The gamble |
|---|---|---|---|---|
| 252 | **Mystery Dream** (`mystery_dream`) | Uncommon | Shown face-down. When taken, it becomes a **random Uncommon or Rare card** you could be offered now, revealed at once. | quality and fit: it may not suit your build |
| 253 | **Moonflip** (`moonflip`) | Uncommon | At every rest a coin flips: for the next block all Wardens **deal 25% more damage**, or **15% less**. | a coin each block (average +5%); the HUD shows the side |
| 254 | **Double or Nothing** (`double_or_nothing`) | Rare | Every Omen you face pays **double** if you lose **no leaf** in its block, and **nothing** if you lose any (instead of −25% per leaf). | a bet on your own maze |
| 255 | **Wild Dew** (`wild_dew`) | Common | Every drift's Dew pot is rolled between **×0.6 and ×1.6** (average ×1.1), shown before the drift starts. | swingy income |

- **Mystery Dream:** draws by the usual weights from eligible Uncommons and Rares (not Legendaries,
  not Bittersweet), never a card you hold at max stacks. If nothing qualifies, it becomes a random
  eligible Common. Its face shows a moth and *"?"*; the impact preview says *"Unknown until taken"*.
- **Moonflip:** flips at the rest after each block, from the run's seeded rng (the same map flips the
  same way). The DriftPanel shows *"Moonflip · +25%"* or *"−15%"* for the block.
- **Double or Nothing:** needs Omens (offered from drift 10). Dew, Seeds and Dream rewards all
  follow it; a double-edged Omen (whose reward is its twist) is unaffected. Omens still never give
  leaves or Dreamlight. **As built** (116d52bc): Dream rewards double (a Rare+ card in the next 2
  Dreams; extra cards doubled, up to 5), but a **Legendary reward stays one**.
- **Built:** 116d52bc (`tests/test_strange_dreams.gd`). Mystery Dream shows what it became over the
  map for ~2.4 s; Moonflip shows as a damage row on every Warden and in the DriftPanel.
- **Wild Dew:** multiplies with the pot's other modifiers; the DriftPanel's next-drift pot shows
  the rolled number. Seeded, like Moonflip.
- **Numbers:** Balancing Discussion checks the averages (Moonflip +5%, Wild Dew +10% Dew) against
  the budget.
- **Ids for Meta's node:** `mystery_dream`, `moonflip`, `double_or_nothing`, `wild_dew`.

## Grove build branches: Swift and Wide Reach (2026-09-30)

For `meta_design.md` Section 3 (Meta Game Discussion, after the user's "no combo cards in the
Grove"). Two **generic** build branches: no combo payoffs, no single-family cards; each works with
any Warden. Grove pool (they join once the node is bought). Two new archetype tags, so taking one
lifts its branch: **`swift`** and **`reach`** (card builds C9 and C10). Numbers sized to the
`dream_audit.md` budget.

**Swift (attack speed)**

| Node | # | Card | Rarity | Effect |
|---|---|---|---|---|
| 1 *Quickening* (50) | 235 | **Momentum** | Uncommon | a Warden attacking the **same nightmare** again gains **+6% attack speed per hit** (max +45%); resets on a new target |
| | 236 | **Quickening** | Common | when a nightmare is dispelled in a Warden's range, that Warden gets **+30% attack speed for 4 s** |
| | 237 | **Flurry** | Uncommon | every **5th attack** from a Warden **fires twice** |
| 2 *Light Feet* (70) | 238 | **Restless Roots** | Uncommon | Wardens with **under 1 attack per second** (before bonuses) get **+45% attack speed** |
| | 239 | **Hummingheart** | Rare | every **+10% bonus attack speed** a Warden has also gives it **+3% damage** (max +60%) |
| | 248 | **Drumbeat** | Uncommon | a Warden **touching 2+ other attacking Wardens** gets **+30% attack speed**. Diagram `".......\n..www..\n..wWw..\n.......\n...W..."` (the lone `W` below is dimmed: ✗ alone), caption *"Touching 2+ Wardens: +30% attack speed."* *(added 2026-09-30 so Swift's dream build is possible)* |
| Tip (120) | 240 | **Whirlwind Heart** | Legendary | **all attack-speed bonuses count double**; every hit deals **−20% damage**. You build around stacking attack speed |

**Wide Reach (area, splash)**: "area attacks" = splashes, pulses, clouds, lobs, chains, sweeps
(anything `Tower.hit(..., is_area = true)`).

| Node | # | Card | Rarity | Effect |
|---|---|---|---|---|
| 1 *Broad Strokes* (50) | 241 | **Broad Splash** | Common, stacks (max 3) | **splashes and clouds** reach **0.25 cells wider** per stack (pulses use their range: not affected) |
| | 242 | **Lingering Splash** | Uncommon | every **3rd area attack** leaves a patch (1 cell, 2 s) that deals **25% of that hit per second** to nightmares inside (effect damage) |
| | 249 | **Overlap** | Uncommon | a nightmare hit by **two different Wardens' area attacks within 1 s** takes **+40%** from the second. Diagram `".......\n.PPPPP.\n.W.*.W.\n.......\n......."` (`*` = where both splashes land), caption *"Two area Wardens covering the same spot: +40%."* *(added 2026-09-30 so Wide Reach's dream build is possible)* |
| 2 *Far Reach* (70) | 243 | **Far Reach** | Uncommon | Wardens with an **area attack** get **+0.75 range** |
| | 244 | **Spillover** | Rare | when an area attack **dispels** a nightmare, the **leftover damage** splashes to nightmares within 1 cell |
| Tip (120) | 245 | **Great Ripple** | Legendary | every area attack **hits again 1 s later** in a ring **1 cell wider**, at **50%** (an aftershock). You build around big area Wardens |

- **Generic by design:** every family has attackers with both normal and area attacks, so neither
  branch needs a family. Swift helps single-target and fast Wardens; Wide Reach helps splash, pulse
  and cloud Wardens: the two pull a board different ways.
- **Archetypes:** `swift` and `reach` join the build tags (two more card builds, C9 Swift and C10
  Wide Reach, measured like the others). They're Grove-only, so a fresh profile never sees them.
  `reach` and `affliction` overlap a little (area and effect damage both hit crowds); that's fine,
  as a bridge.
- **Limits:** Flurry's extra shot and Great Ripple's aftershock never trigger themselves (no chains).
  Spillover doesn't trigger off its own splash. Whirlwind Heart's doubling applies to bonuses only,
  not base speed, and attack speed is capped where the attack animation can't go faster (Tower
  Code's existing cap).
- **Deepened:** Momentum II (+8% per hit, max +60%), Broad Splash II not needed (it stacks), Lingering
  Splash II (every 2nd area attack), Far Reach II (+1.25 range).
- **Bridges, not more cards** (2026-09-30, after Drumbeat and Overlap still left their dream build at
  0–1%: with only 5–6 Grove cards, a 60% run pool rarely holds a full set). Every other card build has
  bridges; these two had none. Existing cards that already do the job get the second tag (no new
  cards, no pool growth, the 60% stays):
  - **`swift`** also on **Quick Step**
    (attack speed after calling early; Daring). Swift's package: 6 → **7**. (Quickened Sap was tagged first, but as a core basic it sits in every run's pool and pushed Swift's dream build to 9%: untagged again.)
  - **`reach`** also on **Crowd Breaker** (area attacks +5% per nightmare hit) and **Last Breath** (a
    dispel burst on nearby nightmares; Affliction), and **Shattering Blow** (crits splash; Precision).
    Wide Reach's package: 5 → **8** (at 7 it measured 2%, short).
  - Their effects don't change; the tag only counts them in the package (tag Resonance was removed 2026-10-02).
    Target: 5+ by 100 at **~3–5%** with a full Grove, like the other card builds.
  - **Measured (61f25e69, Full, 300 runs):** Wide Reach (8) **5%** ✓; Swift (7) **2%** (accepted:
    within noise of the band; a core basic as a bridge pushed it to 9%). Precision unchanged (8%).
    Pass closed.

## Status effect numbers

Status strength **scales with the Warden that applies it** (a % of its soothe), so statuses keep
up with creature health and benefit from stat Dreams and evolutions.

| Status | Effect | Duration | Stacks | Notes |
|---|---|---|---|---|
| **Damp** | **Soaked**: no slow (changed 2026-09-29). Hits from the Dewdrop family deal **+20%**; the conductor for Reactions | 4 s, refreshed on reapply | no | Rain Lily 6 s; Mistveil fog keeps it on |
| **Drowsy** | −8% speed per stack (**the** slowing status) | 3 s, refreshed | up to 5 (−40%) | Dreamshroom: at 5 stacks, sleep **3 s**, once per nightmare |
| **Spored** | soothe per second per stack = 25% of the applier's soothe | 5 s, refreshed | up to 8 (Driftspore 12) | Puffball pops at 10+ |
| **Marked** | +25% soothe taken from all sources | 5 s | no | Beacon +35% |
| **Static** | a charge; at 5 stacks, a free bolt worth 3× the applier's soothe, then reset | loses 1 stack per 2 s | up to 5 | |
| **Held** | can't move; **firm** (nothing breaks it) | 1 s | no | Rootling line, Frostfern (Frozen) |
| **Asleep** | can't move; **fragile**: breaks when a single hit deals **≥10% of its max health** (effect ticks never break it) | 3 s (Dreamshroom), 2 s (Fever Dream) | no | bosses never sleep; Nightbloom's cloud stops it breaking |
| **Caught** | its statuses **stop wearing off** (Spored keeps ticking, Static doesn't decay, Damp / Marked / Held timers pause) | while asleep or at max Drowsy in a Dreamcatcher's range | no | Great Dreamcatcher: Caught statuses tick +25%; bosses are Caught at 3 Drowsy |

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
| **Thunderclap** | Damp + 3 Static | 4× applier damage to the target; arcs to every Damp nightmare within **2.5 cells** for 2× (**at most the 8 nearest per clap**, 2026-09-28, performance), each arc adds **1 Static** | all Static | Static threshold 5 |
| **Ignite** | 3+ Spored + any Static | the spores **burn** for **3 s**: Spored ticks 3× as fast, and each second 1 stack spreads to every nightmare within 1 cell (which may start burning). Changed 2026-09-29: Puffball's pop is the burst | all Static | same |
| **Mushrooming** | 3+ Spored + Damp | the target's Spored ticks +50% for 4 s; a spore cloud (radius 0.6, 4 s) on its tile gives 1 Spored per second | Damp | same |
| **Shatter** | Held (incl. frozen) + Damp, then a crit or a hit from the Pebbling line or a sniper | that hit ×2.5; shards deal 50% of it to nightmares within 1 cell | Held | same (Held is already halved) |
| **Drown** | Damp + 5 Drowsy | **pulled under** for **3 s**, once per nightmare: −60% speed and drowning damage of 0.5× / 1× / 1.5× the applier's damage in seconds 1 / 2 / 3 (3× total, effect damage). Changed 2026-09-29: no sleep, Dreamshroom owns sleep | all Drowsy | −30% speed; same damage |
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
| 80 | **Wildfire Spores** | Uncommon | Ignite spreads 2 stacks, within 1.5 cells | spore, storm, reaction | Sporeling + Firefly Jar | **Start** (moved from Grove 2026-09-28: every pair of starting families needs a combo card) |
| 134 | **Mushroom Rain** | Uncommon | Mushrooming's spore cloud lasts **twice as long** and covers the **8 tiles around** it too | spore, water, reaction | Sporeling + Dewdrop | Start (added 2026-09-28, same reason) |
| 81 | **Deep Water** | Uncommon | Drown lasts 4 s and its damage grows 50% faster; bosses −40% speed | water, sleep, reaction | Dewdrop | Grove |
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
| **Tempest** | Thunderclap as normal; each arc also sets Spored targets **burning** (normal Ignite numbers); stacks spread by burning carry **1 Static** each. A nightmare hit by a Tempest can't start another Tempest for **2 s** | arcs don't Ignite bosses; they still take the Thunderclap |
| **Still Pool** | Drown + a pool on its tile, **5 s**: each walker entering it the first time is **pulled under for 1 s** (−60% speed, drowning 0.5×) | −30% speed while in the pool |
| **Fever Dream** | the nightmare **falls asleep for 2 s** (changed 2026-09-29: no detonation, Puffball owns bursts); adjacent nightmares get **3 Spored + 2 Drowsy** | no sleep; neighbours as normal (Drowsy capped at 3) |
| **Starfall** | the Pinned ×3 crit; Static bolts from nightmares within **3 cells** fire at once into it (each ×2 and a crit); uses up their Static | same, bolts count as crits at ×1.5 |
| **Avalanche** | the lob's Shatter (×2.5) also Shatters every Damp + Held nightmare within the lob's splash | bosses take the ×2.5 hit, no spread from them |
| **Prismstorm** | Shatter as normal; each nightmare hit by shards gains **2 Static** | same |
| **Nightbloom** | Mushrooming's cloud (4 s) also keeps nightmares inside **unable to wake**: sleep and max Drowsy don't end while inside, **sleep doesn't break from hits** there, and the Watcher's wake-up does nothing | bosses don't sleep; they keep max Drowsy while inside |
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
| 101 | **Deep Stillness** | Rain Lily + Tangleroot + Bellflower | Still Pools last 8 s and pull walkers under for 1.5 s |
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

## Kinship cards: going deep

Added 2026-09-28 (user decision) for Kinships (`tower_design.md` "Kinships"). Reactions and
Crowned Reactions reward going wide; these make **going deep in one family** a full build. They
change decisions (placement, time, depth), not just numbers. Tag `kinship`; like other family
cards they get the family weight (**1.4×**, per the "Adapt, don't get handed" change) once you have a
Kinship on the map.

| # | Card | Rarity | Effect | Changes what you decide | Needs | Pool |
|---|---|---|---|---|---|---|
| 124 | **Quick Bonds** | Common, stacks (max 3) | bonds grow **1 drift faster** (Blooming at 4, Old Kin at 9; at III: 2 and 7) | time | — | Start |
| 125 | **Family Ties** | Common, stacks | Wardens in a Kinship **+8% damage** | payoff | — | Start |
| 126 | **Sweet Harmony** | Uncommon | Harmony strikes **+50% damage**, cooldown 2 s → **1.5 s** | payoff | a Kinship on the map | Start |
| 127 | **Close Kin** | Uncommon | Kinship reach **2 → 3 cells** | placement | — | Grove |
| 128 | **Old Friends** | Uncommon | new bonds **start at Blooming** | time | — | Grove |
| 129 | **Rooted Bond** | Uncommon | if you **sell a bonded Warden and plant a new kin** of its partner (another branch of that family) within reach **during the same rest**, the bond **keeps its stage** | the maze: rebuild without losing progress | — | Grove |
| 130 | **Extended Family** | Rare | each Warden can be in **2 Kinships** (with two different kin) | placement | a Kinship on the map | Grove |
| 131 | **Kin and Kindling** | Rare, **Entwined** (any Kinship on the map + any Reaction card) | Harmony strikes also apply **both Wardens' statuses** (1 stack each) to the nightmare | the bridge to Reactions | — | Grove |
| 132 | **Grove of Kin** | Legendary | every Kinship on the map gives **all Wardens +3% damage** (max +30%) | the capstone | 2 Kinships on the map | Grove |
| 133 | **Blood Is Thicker** | Uncommon, **Bittersweet** | Wardens in a Kinship **+30% damage**. **Cost:** Wardens not in a Kinship −15% damage | commitment | a Kinship on the map | Grove |

- **Deepened:** **Sweet Harmony II** +100% and 1 s cooldown; **Close Kin II** reach 4 cells;
  **Old Friends II** new bonds start at Old Kin.
- "A Kinship on the map" counts at offer time (like other prerequisites). Kin and Kindling's
  statuses from Harmony strikes can complete Reactions, but the Harmony strike itself still never
  counts as a chain link.
- **Rooted Bond as built:** the partner remembers the bond's drift count until the rest ends; only
  the **first kin planted after the sale** within reach inherits it (a kin already standing nearby
  doesn't). With Extended Family each partner remembers its own. `tests/test_kinships.gd`.
- **In the demo:** the Start-pool three (Quick Bonds, Family Ties, Sweet Harmony).
- **Watch in playtests:** Extended Family + Grove of Kin + Whole Tree + Monoculture could make an
  all-kin maze far ahead. The +30% cap on Grove of Kin is the first knob.


## Seed cards: plant now, grow later

Added 2026-09-29 (user request). Cards for the Wardens whose value isn't damage (catchers, auras,
walls, control) that **don't need those Wardens to be offered**. Taking one early is a bet on
getting the family later. Two rules keep the bet fair:

1. **Never dead:** every Seed card has a small effect **on its own** ("Now"), and a bigger one once
   you have the Wardens it names ("Grows with"). The one exception is *Golden Harvest*, the
   Legendary gamble.
2. ~~It calls its family~~ **Removed 2026-10-03** (user, from a Dream screenshot of Dew Bowl's
   "Seed · calls Acorn to your next family pick": *"I don't think Seed should be a thing; make it
   predictable."*). **No card adds or calls a family into a family pick**; family picks follow only
   their own rules (the first pick: 3 random unlocked families; boss picks: families you lack). These
   cards keep their "Now" and "Grows with" effects, and lose the "Seed ·" line and the sprout.

Tag `seed` plus the family's tag; normal weight (1×) until you own the family, then the family
weight (1.4×). Legendary and Bittersweet rules as usual.

| # | Card | Rarity | Now (on its own) | Grows with | Pool |
|---|---|---|---|---|---|
| 169 | **Dew Bowl** | Common, stacks (max 3) | +10 Dew now | **Dewcatcher, Wellspring:** catch +15% (per stack) | Grove |
| 170 | **Harvest Moon** | Uncommon | +5 Dew at every rest | **catchers:** the Harvest pays **+50%** | Grove |
| 171 | **Deep Well** | Rare | at every rest, **3% interest** on banked Dew (max 20) | **Wellspring:** its interest cap +30 each (90) | Grove |
| 172 | **Kind Canopy** | Uncommon | Sheltering Boughs (2026-10-05): Wardens touching an aura Warden +35% damage | **Acorn, Elder Stump, Grove Heart:** aura radius **+1** | Grove |
| 173 | **Shared Light** | Rare | every Warden gives the Wardens touching it **+2% damage** (max +10% on one Warden) | **aura Wardens:** their bonuses **+50%** | Grove |
| 174 | **Bramble Oath** | Common | +2% damage for every 10 path tiles your walls add (max +15%) | **Bramble, Honeysuckle:** 50% stronger | Start |
| 175 | **Patient Roots** | Uncommon | Held lasts **+0.25 s** from any source (Frostfern, Snugroot, World Root…) | **Rootling line:** pulls go 0.5 tiles further, holds another +0.25 s | Grove |
| 176 | **Golden Harvest** | Legendary | nothing: the gamble | **catchers:** every **100 Dew** harvested or earned as interest this run gives **all Wardens +2% damage** (max +30%) | Grove |

- ~~Calls~~ (removed 2026-10-03): Dew Bowl, Harvest Moon, Deep Well, Kind Canopy, Shared Light and
  Golden Harvest used to call Acorn, and Patient Roots called Rootling.
- **Golden Harvest needs a "Now"** without the call (a Legendary must work on its own): **every 500
  Dew you earn this run gives all Wardens +2% damage (up to +30%); Dew from catchers and interest
  counts double.** It still grows with Acorn's catchers, but it's never dead without them.
- **In the demo:** only Bramble Oath (Acorn and Rootling are Grove families).
- **Watch in playtests:** whether Seed cards get picked at all before the family (the call rule is
  the lever), and whether Golden Harvest turns economy into a must-have damage build.


## Support Warden cards: the quiet Wardens

Added 2026-09-29 (user request). Cards for the specific Wardens whose value isn't damage:
catchers, auras, walls, Dreamcatchers. Unlike Seed cards, these **need their Warden** (normal
prerequisites). Each one changes **how that Warden is used**, mostly where you put it, not just a
bigger number. Tag `support` plus the family tag.

| # | Card | Rarity | Effect | Changes | Needs | Pool |
|---|---|---|---|---|---|---|
| 177 | **Wide Bowl** | Common, stacks (max 2) | catch radius **+0.5 cells** | placement: one catcher covers a whole bend | Dewcatcher | Grove |
| 178 | **Dew Trail** | Uncommon | nightmares that are **Damp** when caught drop **+20% more** Dew | a reason to soak your kill zone (Dewdrop + Acorn) | Dewcatcher | Grove |
| 179 | **Still Waters** | Uncommon | Wellspring interest **+4%** at a rest if you **spent no Dew** during that block | the saving decision | Wellspring | Grove |
| 180 | **Overflowing Well** | Rare | interest above the cap isn't lost: every **50 Dew over** becomes a **Dreamlight shard** | the Greedy Gardener payoff (`tower_design.md` archetypes) | Wellspring | Grove |
| 181 | **Acorn Cache** | Common | Acorns cost **15 Dew** (was 25) and their aura is **+8%** (was +5%) | cheap aura seeding across the maze | Acorn | Grove |
| 182 | **Hedgerow Roots** | Rare | auras **flow through Thornwalls**: a Warden touching a Thornwall that touches an aura Warden also gets that aura (one wall hop) | maze-building: walls carry support | Acorn, Elder Stump or Grove Heart | Grove |
| 183 | **Grandfather Stump** | Uncommon | Grove Heart's bonus per nearby Warden **+4%** (was +3%), max **+45%** (was +30%) | pack the cluster tighter | Grove Heart | Grove |
| 184 | **Thorn Snare** | Uncommon | Phantoms passing **through** a Thornwall and Gravecrawlers passing **under** one are **Held 0.5 s** | walls answer the wall-ignoring nightmares | — (Thornwall is always yours) | Start |
| 185 | **Scented Hedge** | Uncommon | every Thornwall **touching a Honeysuckle** also gives off its scent at half strength | long scented corridors from one Honeysuckle | Honeysuckle | Start |
| 186 | **Living Walls** | Rare | a Thornwall that stands **5 drifts** grows into a **Bramble** for free (a wall that never moved) | patience; pairs with Steadfast | Bramble unlocked | Grove |
| 187 | **Many Threads** | Uncommon | Dreamcatchers Catch nightmares at **4 Drowsy** (not only full) | Caught comes sooner and lasts longer | Dreamcatcher | Grove |
| 188 | **The Quiet Ones** | Legendary | all non-attacking Wardens (catchers, auras, walls, Dreamcatchers, Memory auras) are **50% stronger**: catch, interest, aura bonuses and wall effects | the support capstone | 3+ non-attacking Wardens | Grove |

- **Deepened:** **Dew Trail II** +35%; **Thorn Snare II** 1 s, and
  Night Hounds sprinting past a Thornwall are Held too.
- **In the demo:** Thorn Snare and Scented Hedge (walls are in the demo; Acorn isn't).
- **Pairs with:** the Seed cards above (*Dew Bowl*, *Kind Canopy*, *Golden Harvest*) and the
  Kinship Old Growth.

## Generic Rares (2026-09-28: filling the Rare tier)

Why: many boards qualify for 0–1 Rares through act 2 (the Few and Mighty simulation, c64183a), because
most Rares are Entwined, Bittersweet or need a specific family. These seven work with **any family**
and have loose or no Needs. Each rewards a way of building, not a family; all only **amplify**
(they never gate a combo). All **Start** pool, so the demo has them.

| # | Card | Rarity | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|---|
| 135 | **Root Network** | Rare | Sprouts that **touch each other** (side by side, not diagonal) form a network: each Sprout gets **+6% damage per Sprout in its network** (a line of 8 = +48% each; max +60%). The networks glow faintly along their shared edges | sprout, wide | 4+ Sprouts (soft) | Start |
| 136 | **First Light** | Rare | each Warden's **first hit on a nightmare** deals **×3** damage | — | — | Start |
| 137 | **Last Stand** | Rare | nightmares within **4 cells of the Heartwood** take **+60% damage** from every Warden (2026-10-05) | maze | — | Start |
| 138 | **Steadfast** (id `old_growth`; "Deep Roots" and "Old Growth" were taken) | Rare | Wardens that have stood **5 drifts** (never sold; growing keeps the count) deal **+15% damage**; **15 drifts: +30%** | — | — | Start |
| 139 | **Hunter's Patience** | Rare | Wardens deal **+50% damage to Deeply Blighted** nightmares and **+20% to bosses** | — | act 2+ | Start |
| 140 | **Thinning the Herd** | Rare | each nightmare dispelled within a Warden's range gives that Warden **+1% damage for the rest of the drift** (max +25%) | — | — | Start |
| 141 | **Bitter Hedges** | Rare | nightmares walking past a **Thornwall** (next to the path) take **+3% damage** from every Warden for 2 s, **+3% more per extra Thornwall** they pass in that time (max +15%) | wall, maze | 6+ Thornwalls (soft) | Start |

- **Root Network** is the user's idea ("for each Sprout that's connected, increase damage"): it
  makes a Sprout build a real choice beside Sprout Chorus (attack speed, within 2 cells), Seedfall
  and Sprout Surge. A Sprout that grows leaves the network (it's no longer a Sprout), so the build
  asks *when* to grow. Deepened (**Root Network II**): +8% per Sprout, max +80%, and diagonals count.
- The Warden panel's "Dreams on this Warden" lists each of these with its current value (e.g. "Root
  Network · +36% (network of 6)"); the build ghost shows the network it would join.
- After these, an act 1 board with any family has **~5–7 eligible Rares** instead of 0–1.

## Generic Commons and Uncommons (2026-09-28: filling the lower tiers)

Why: only ~14 Commons/Uncommons work with any family (the stat cards, Cozy Corners, Hedge Maze,
Evergreen, Glinting Dew, Bitter Sap, Seedfall, Solitude…), so over 19 Dreams the same few repeat.
These are **enhancers** for any build: small rules and trade-offs rather than more flat stats.
All **Start** pool, no family Needs (a few have a soft run-state Need so they're never dead).

| # | Card | Rarity | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|---|
| 142 | **Gathered Dew** | Common | nightmares give **+10% Dew** (stacks, max +30%) | economy | — | Start |
| 143 | **Fair Trade** | Common | selling refunds **+10%** more (rest 85%, drift 60%; stacks to 100% / 75%) | economy | — | Start |
| 144 | **Call of the Wild** | Common | calling a drift early gives **double Dew** (cap 20 per drift) | tempo, economy | — | Start |
| 145 | **Mending Bark** | Common | card text (plain words, 2026-09-30): *"**5 drifts in a row without losing a leaf** regrow 1 leaf."* (a "perfect block") | leaves | — | Start |
| 146 | **Lasting Dreams** | Common | every status your Wardens apply lasts **+1 s** (stacks, max +3 s) | status | a Warden that applies a status (soft) | Start |
| 147 | **Short Roots** | Common | Wardens with **range 2 or less** deal **+25% damage** | — | a Warden with range ≤ 2 (soft) | Start |
| 148 | **Forest's Edge** | Common | Wardens within **3 cells of the start** deal **+20% damage** | maze | — | Start |
| 149 | **Crowded Path** | Uncommon | Wardens get **+3% damage per nightmare in their range** (max +30%) | — | — | Start |
| 150 | **Lone Hunter** | Uncommon | **+30% damage** to a nightmare with **no other nightmare within 2 cells** | — | — | Start |
| 151 | **Skyward Gaze** | Uncommon | **+40% damage and +1 range** against **flying** nightmares | — | act 2+ (flyers exist) | Start |
| 152 | **Fresh Growth** | Uncommon | a Warden planted or grown during a drift deals **+30% damage until the next rest** | tempo | — | Start |
| 153 | **Underdog** | Uncommon | at each rest, your **3 Wardens that soothed least** in that block get **+20% damage** for the next block | — | 6+ attacking Wardens (soft) | Start |
| 154 | **Weathered Walls** | Uncommon | Thornwalls **can't be trampled**, and every 10th Thornwall is free | wall | — | Start |
| 155 | **Heavy Air** | Uncommon | every slow your Wardens apply (Soaked, Drowsy, frost…) is **20% stronger** | status | a Warden that slows (soft) | Start |
| 156 | **Wandering Mind** | Uncommon | gain **1 Dream reroll** (was 2, 2026-09-30) (reroll one offer's cards) | dreams | — | Grove |

- **Pairs of opposites:** Crowded Path (swarms) vs Lone Hunter (spread-out nightmares, bosses);
  Forest's Edge (fight early) vs Last Stand (fight at the Heartwood); Short Roots vs Long Shadows.
  An offer showing both halves of a pair is a real choice about your maze.
- **Economy check:** Gathered Dew ×3 = +30% creature Dew, which is only part of income (rest
  bonuses don't change). Fair Trade makes rebuilding cheap but never profitable (max 100%, and
  Remembered Care still keeps rank Dew in the seed).
- **Underdog** uses the rest report's per-Warden totals (`DamageLog`), and its glow shows on the
  3 chosen Wardens. Thornwalls don't count.
- **Wandering Mind** stacks with the Grove perk Second Thoughts (rerolls add).
- **Deepened:** Crowded Path II (+4%, max +40%), Lone Hunter II (+45%), Fresh Growth II (+45%),
  Underdog II (4 Wardens, +25%).
- **Name clash fixed (2026-09-28):** Commons #10 and Rares #138 were both called **Deep Roots**; #138 is now
  **Steadfast** (id `old_growth`). Wandering Mind is a **Grove** card (rerolls stay a Grove thing).

### Generic cards, second batch (2026-09-28)

User-approved. Mostly about parts of the map no card used yet (obstacles, the island's edge, path
length, straights) and the moment a nightmare is dispelled. All **Start** pool, no family Needs.
"Touching" = the 8 cells around a Warden.

| # | Card | Rarity | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|---|
| 157 | **Winding Path** | Common | at each rest, **+1 Dew per 10 path tiles** | maze, economy | — | Start |
| 158 | **Shelter of Stones** | Common | Wardens touching an **obstacle** (Withered Tree, Mossy Boulder…) deal **+15% damage** | maze | 4+ obstacles left (soft) | Start |
| 159 | **Cliffside** | Common | Wardens touching the **island's edge** get **+1 range** | maze | — | Start |
| 160 | **Thick Bark** | Common | the **first leaf you'd lose** each block (between two rests) is saved | leaves | — | Start |
| 161 | **Sudden Bloom** | Common | growing (evolving) a Warden makes its **next 3 attacks deal ×2** | — | — | Start |
| 162 | **Last Breath** | Uncommon | a dispelled nightmare **bursts for 10% of its max health** on nightmares within **1 cell** (never chains) | — | — | Start |
| 163 | **Tangled** | Uncommon | nightmares carrying **2+ statuses** move **10% slower** | status | a Warden that applies a status (soft) | Start |
| 164 | **Watchful Rest** | Uncommon | a Warden with **nothing in range for 5 s** stores a charge; its **next attack deals ×2** (one charge at a time) | — | — | Start |
| 165 | **Glimmering Hunt** | Uncommon | elites (Deeply Blighted) have a **30% chance to drop a Dreamlight shard** (10 shards = 1 Dreamlight; **its own cap of 3 Dreamlight per run**, separate from the Great Dreamcatcher's) | dreamlight | act 2+ (elites appear) | Start |
| 166 | **Straightaway** | Uncommon | Wardens beside a **straight stretch of 5+ path tiles** get **+15% damage and +0.5 range** | maze | — | Start |
| 167 | **Heart of the Maze** | Rare | the attacking Warden **furthest (along the path) from any other attacking Warden** gets **+50% damage** | maze | 4+ attacking Wardens (soft) | Start |
| 168 | **Echoing Steps** | Rare | each time **the route changes during a drift**, all Wardens get **+5% damage** until the drift ends (max +25%) | maze, tempo | — | Start |

- **Opposites:** Straightaway vs Cozy Corners (stretch the maze or fold it); Shelter of Stones vs
  Wildwood Reclaimed / clearing cards (keep obstacles or clear them); Watchful Rest vs Crowded Path.
- **Winding Path** counts the route's length at the rest (the `%PathLabel` number). With a 23×18
  map, a strong maze is ~100–150 tiles = +10–15 Dew per rest.
- **Shelter of Stones:** a cleared obstacle no longer counts. Obstacle tiles only, not the border.
- **Cliffside:** "edge" = the `island_edge` rim cells. Range only, so it's for snipers and pulses.
- **Thick Bark:** once per block; resets at each rest. Bosses' 5-leaf hits are saved whole (it's
  "the first leak", not "one leaf"). Shown as a small bark shield on the leaves counter while ready.
- **Last Breath:** the burst counts as effect damage (Potency, Seeping, Nightshade apply); it
  doesn't trigger another Last Breath. Bosses' bursts are capped at 5% of the boss's max health.
- **Tangled:** a slow like Soaked; stacks with other slows (Heavy Air doesn't boost it).
- **Heart of the Maze:** "furthest" = the largest path distance to the nearest other attacking
  Warden's closest path tile; recomputed on `path_changed` and on build/sell; ties go to the one
  nearer the Heartwood. The chosen Warden gets a small heart mark.
- **Echoing Steps:** only real route changes count (building, selling or clearing while nightmares
  walk, or Rooted Nightmares' blocking), max 1 per second.
- **Deepened:** Last Breath II (15%), Watchful Rest II (charge after 3 s), Straightaway II (+25%,
  +0.5 range), Thick Bark II (first 2 leaks each block).

## Thin-family cards (2026-09-30)

Why: the pool is ~191 cards (well past the ~70 target), so new cards only go where a family is
thin. The starting three have 12+ each; **Rootling had ~1, Bellflower ~3, Lanternmoth / Marked ~2,
Nestling ~5** (target 6–8). These are enhancers: they need their family (shown as the family, per
*How Needs are shown*), join the pool through **discovery** (the first build of the Warden they
name), and follow the status jobs (`tower_design.md`, "Status jobs": only Drowsy slows, Rootling
pulls back, Marked belongs to Firefly Jar, Rootlight is the Held specialist). User-approved.

| # | Card | Rarity | Effect | Tags | Needs | Pool |
|---|---|---|---|---|---|---|
| 192 | **Deep Grip** | Common, stacks (max 3) | Rootling line **+15% damage to Held** nightmares | root, held | Rootling | Start |
| 193 | **Tangled Release** | Uncommon | a nightmare **freed from a hold is pulled back 0.5 tiles** along its route | root, held | Rootling | Start |
| 194 | **Long Light** | Uncommon | Rootlight's lit tiles **stay lit 3 s** after its light moves on (they still hold once per nightmare) | root, held | Rootlight | Start |
| 195 | **Root Web** | Rare | when a nightmare is Held, the nightmares **touching it are Held for half as long** (never chains) | root, held | Rootling | Start |
| 196 | **Clear Tones** | Common, stacks | Bellflower line **+15% attack speed** | song | Bellflower | Start |
| 197 | **Lullaby** | Uncommon | a Caught nightmare **stays Caught 1 s** after leaving a Dreamcatcher's range | song | Dreamcatcher | Start |
| 198 | **Chorus** | Rare | Bellflower-line Wardens within **3 cells** of each other pulse **in sync**; a synced pulse deals **+30%** | song | 2 Bellflower-line Wardens (soft) | Start |
| 199 | **Bright Marks** | Common, stacks (max 3) | Marked **+5%** (25% → 30%; max 40%; Beacon keeps its own +35% base, +5% per stack on top) | light, mark | Lanternmoth | Start |
| 200 | **Lingering Mark** | Uncommon | Marked lasts **2 s longer** | light, mark | Lanternmoth | Start |
| 201 | **Called Shot** | Rare | each Warden's **first hit on a Marked nightmare is a guaranteed crit** | light, mark, crit | Lanternmoth | Start |
| 202 | **Homing Instinct** | Uncommon | birds **return from a swoop 30% faster** (Nestling line: more swoops per second) | wing | Nestling | Start |
| 203 | **Murmur** | Rare | a bird's hit on a nightmare **another bird hit within 1 s** deals **+15%** | wing | Nestling | Start |

- **Root Web:** the spread hold is Held (firm), halved again on bosses; a nightmare can't be held
  by Root Web more than once per second. Pairs with Rooted Nightmares (every Held nightmare blocks).
- **Tangled Release** moves the nightmare back along its route (never off the path, never through a
  Warden); it counts as a Rootling pull for Snare and the Held Reactions. **Loop guard** (ruling
  2026-09-30): a release pull may set off Snare's hold, but a hold that came from a release pull
  never triggers another release pull. So one hold gives at most: hold → release pull → Snare hold
  → done.
- **Chorus:** "in sync" = when one fires, the others within 3 cells whose attack is ready within
  0.3 s fire with it. Show a soft ring linking them. Needs a second Bellflower-line Warden to do
  anything (soft Need).
- **Called Shot** and First Light (136) both boost first hits; they add (a first hit on a Marked
  nightmare with both = ×3 and a crit).
- **Homing Instinct** is attack speed for swoop Wardens only (Wren's Nest, Magpie line,
  Hummingbird swoops); pecks aren't affected.
- **Deepened:** Tangled Release II (1 tile), Lullaby II (2 s), Lingering Mark II (+4 s),
  Homing Instinct II (50% faster).
- **Numbers to check** with the tower design chat (status jobs are recent): Bright Marks' cap, Root
  Web's half duration on Frozen (Frostfern) holds.

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

**Offers are random within the run's pool (2026-09-30, user):** the build tag weight ("Dreams steer your Dreams", 1.6 → 1.3) is **turned off (1.0)**. The player adapts their build to the random cards they get; nothing steers them down a path. Tag resonance (+10% per owned card of a tag, up to +50%) stays: committing is still rewarded, by choice.

**No "Needs" line on cards (2026-10-01, user: "can remove the Needs Water"):** the Dream card face no longer shows a "Needs …" line (families, statuses or forms). The card text already names what it works with; a card for a family you don't have yet stays a quiet lure for the family pick. In "Dreams this run", a card that isn't doing anything yet is shown dimmed with a hover line "Not active yet: needs a Water Warden", so the information is there when asked.
