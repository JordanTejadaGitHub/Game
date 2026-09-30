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
   - **Coverage:** every pair of starting families has at least one combo card in the start pool:
     Firefly Jar + Dewdrop (Rolling Thunder, Conductive Soil), Sporeling + Firefly Jar (Wildfire
     Spores), Sporeling + Dewdrop (Mushroom Rain, 134). New families should bring one per pair.
   - **Common combo cards** (added 2026-09-28: after cards 142–168 and `tag_weight` 2.4, Sporeling
     and Dewdrop starts fell to ~0.35 half-dreamed offers before drift 25, because each pair's combos
     were Uncommon or Rare and lost the Common-heavy rarity roll). One small, stackable **Common** per
     starting pair, Start pool; they only amplify:

     | # | Card | Rarity | Effect | Tags | Needs |
     |---|---|---|---|---|---|
     | 189 | **Damp Rot** | Common, stacks (max 3) | Poisoned ticks on **Soaked** nightmares deal **+20%** | spore, water, reaction | Sporeling + Dewdrop |
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
  Wildfire Spores, Sparking Spores), *"Poisoned + Soaked"* (Mushrooming: Mushroom Rain, Damp Rot),
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
| **A Reaction** | the first time that Reaction fires, ever (profile `reactions_seen`) | cards that name that Reaction: Thunderclap → Rolling Thunder, Rain on Glass, Conductive Soil; Ignite → Wildfire Spores, Sparking Spores; Mushrooming → Mushroom Rain, Damp Rot; Drown → Deep Water. **Any 2 Reactions** → Quick Reactions |
| **A Crowned Reaction** | the first time it fires | its Woven card (Tempest → Eye of the Tempest, Still Pool → Deep Stillness, …) |
| ~~**A chain**~~ | — | (Dawnbreak is a Legendary: not discovery-gated, it stays a Grove tip; resolved 2026-09-29) |
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
| 55 | **Heartwood's Reach** | Common | gain **4 half-price clears**; use them any time (a charge counter on the HUD; unused charges last all run). Deepened II: 7 | clearing | Start |
| 56 | **Reclaimed Earth** | Common | each clear **refunds 40% of the Dew you paid for it**, and the cell is left **fertile**: the first Warden planted there costs 50% less | clearing, economy | Start |
| 57 | **Tended Forest** | Common | **+1% damage for every obstacle cleared this run** (max +25%; clears from before the card count) | clearing, maze | Start |
| 58 | **Burn Back the Dead Wood** | Rare, **Bittersweet** | clear **every Withered Tree** on the map right now for **5 Dew each** (paid when taken; only offered if you can pay). **Cost:** nightmares +10% speed for the rest of the run | clearing, bittersweet | Grove |

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
2. **It calls its family:** while you hold a Seed card, the **next family pick is guaranteed to
   offer** the family it grows with (if that family is unlocked in the Grove and not owned yet). The
   card shows a small sprout and *"Grows with: Dewcatcher, Wellspring · calls Acorn"*.

Tag `seed` plus the family's tag; normal weight (1×) until you own the family, then the family
weight (1.4×). Legendary and Bittersweet rules as usual.

| # | Card | Rarity | Now (on its own) | Grows with | Pool |
|---|---|---|---|---|---|
| 169 | **Dew Bowl** | Common, stacks (max 3) | +10 Dew now | **Dewcatcher, Wellspring:** catch +15% (per stack) | Grove |
| 170 | **Harvest Moon** | Uncommon | +5 Dew at every rest | **catchers:** the Harvest pays **+50%** | Grove |
| 171 | **Deep Well** | Rare | at every rest, **3% interest** on banked Dew (max 20) | **Wellspring:** its interest cap +30 each (90) | Grove |
| 172 | **Kind Canopy** | Uncommon | Wardens touching 3+ other Wardens +5% damage | **Acorn, Elder Stump, Grove Heart:** aura radius **+1** | Grove |
| 173 | **Shared Light** | Rare | every Warden gives the Wardens touching it **+2% damage** (max +10% on one Warden) | **aura Wardens:** their bonuses **+50%** | Grove |
| 174 | **Bramble Oath** | Common | +2% damage for every 10 path tiles your walls add (max +15%) | **Bramble, Honeysuckle:** 50% stronger | Start |
| 175 | **Patient Roots** | Uncommon | Held lasts **+0.25 s** from any source (Frostfern, Snugroot, World Root…) | **Rootling line:** pulls go 0.5 tiles further, holds another +0.25 s | Grove |
| 176 | **Golden Harvest** | Legendary | nothing: the gamble | **catchers:** every **100 Dew** harvested or earned as interest this run gives **all Wardens +2% damage** (max +30%) | Grove |

- **Calls:** Dew Bowl, Harvest Moon, Deep Well, Kind Canopy, Shared Light and Golden Harvest call
  **Acorn**; Patient Roots calls **Rootling**; Bramble Oath calls nothing (walls are always yours).
  If two held cards call different families, the next pick offers both.
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
| 137 | **Last Stand** | Rare | nightmares within **4 cells of the Heartwood** take **+35% damage** from every Warden | maze | — | Start |
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
