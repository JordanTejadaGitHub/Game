# Dream Card Audit (2026-09-30)

User: *"cards aren't impactful enough to a run; I can play and beat it without choosing optimal
cards."* Targets are in `dream_design.md` "Dreams must matter": **always skipping never passes act
1**; random cards die in act 3; sensible picks reach act 3–4; a build that comes together wins.
This page is the pass over every card. **Owner:** the design chat writes it; Roguelite Code applies it;
Tower Code tests it and tunes nightmare health to match.

**The pool:** 301 files = **74 form unlocks** (`dream_*`, bought with Dreamlight at Remember, not
offered as Dreams: not audited here) + **227 Dream cards** (40 of them Deepened "II" versions).
Numbers below are **proposals**. The Dream-value batch (skip / random / Balanced) gives the "before".
Tower Code checks the "after", and the numbers move with it.

## Power budget

"Scope" is how much of the board a card touches. A narrow or conditional card gets a bigger number
for the same rarity.

| Rarity | All Wardens | One family / line | Conditional (position, status, target) | Or a rule |
|---|---|---|---|---|
| **Common** | +15% | +35% | +30% | a clear, simple rule |
| **Uncommon** | +25% | +50% | +45% | changes how one family or tactic plays |
| **Rare** | +40% | ×1.8 | +70% | changes how you build |
| **Legendary** | ×2-class | — | — | defines the run |

- **Deepened (II):** +60–100% of the base card's effect. Taking both must feel like a step up.
- **Bittersweet:** about **1.5× the budget** of its rarity (its cost pays for it).
- Stat numbers under 10% on a Common are gone; a card whose effect is a rounding error gets
  raised, merged or cut.

## Commons (48 cards)

| Card | Now | Proposed |
|---|---|---|
| Acorn Cache | Acorns 15 Dew, aura +8% | Acorns 12 Dew, aura **+10%** |
| Bitter Sap | +8% Potency (stacks) | **+20%** Potency (stacks) |
| Bramble Oath | +2% per 10 wall path tiles, max 15% | **+3% per 5**, max **+30%** |
| Bright Marks | Marked +5% more, max 40% | Marked nightmares take **+20%** more |
| Brighter Jars | Firefly line +15% speed | **+35%** |
| Call of the Wild | call early = double Dew, max 20 | max **40** per drift |
| Cheap Hedges | Thornwalls 2 Dew | **Merge into Weathered Walls** |
| Clear Tones | Bellflower line +15% speed | **+35%** |
| Cleared Ground | clears −25% (stacks to −50%) | **−30%** (floor unchanged) |
| Cliffside | edge Wardens +1 range | +1 range **and +20% damage** |
| Damp Rot | Spored on Soaked +20% | **+50%** |
| Deep Grip | Rootling line +15% vs Rooted | **+50%** |
| Deep Roots | +2 max leaves, regrow 2 | **+3**, regrow 3 |
| Deeper Calm | all +10% damage | **+15%** |
| Dew Bowl | +10 Dew now (seeding) | **+25** now; seeding part unchanged |
| Fair Trade | sell refunds +10% | **Cut** (too small to change a choice) |
| Family Ties | Kinship +8% | **+20%** |
| Forest's Edge | near start +20% | **+35%** |
| Gathered Dew | +10% Dew | **+20%** |
| Heartwood's Reach / II | 4 / 7 half-price clears | keep |
| Heavy Dew | Dewdrop splash +25%, Soaked +1 s | splash **+50%**, Soaked **+2 s** |
| Hush | Bellflower pulses +15% reach (to 45) | **+25%** (to **+75%**) |
| Lasting Dreams | all statuses +1 s | **+2 s** |
| Longer Flight | Samara +1 cell (to +3) | keep |
| Longer Roots | all +0.25 range | **+0.5** |
| Mending Bark | 5 clean drifts regrow 1 leaf | keep |
| Morning Dew | +20 now, +5 per drift | **+30** now, **+8** per drift |
| Quick Bonds | Kinships 1 drift faster | **Merge into Old Friends** (its first level) |
| Quickened Sap | all +10% speed | **+15%** |
| Rain on Glass | Light +12% vs Soaked | **+35%** |
| Reclaimed Earth | refund 40% + fertile cell | keep |
| Seedfall | Sprouts 6 Dew, no price rise | keep (the swarm's door) |
| Sharp Beaks | multi-hit +1 hit (to +3) | keep |
| Shelter of Stones | touching an obstacle +15% | **+30%** |
| Short Roots | range ≤ 2: +25% | **+35%** |
| Soft Spores | Spored +25% | **+50%** |
| Sparking Spores | Ignite +20% | **+50%** |
| Sprout Surge | Sprouts +30%, +0.5 range | **+50%**, +0.5 range |
| Sudden Bloom | grow → next 3 attacks ×2 | **next 10 s ×2 damage** |
| Tend the Forest | first 2 clears free | keep (the clearing opener) |
| Tended Forest | +1% per clear, max 25% | **+2% per clear, max 40%** |
| Tender Care | Nurture −15% (to −45%) | **−25%** (to −50%) |
| Thick Bark / II | first 1 / 2 leaks per block free | keep |
| Warm Hands | +3% damage per rank | **+6%** per rank |
| Wide Bowl | Dewcatcher radius +0.5 | **Merge into Dew Trail** |
| Winding Path | +1 Dew per 10 path tiles at rests | **+1 per 5** |

## Uncommons (≈ 67 cards, base + II)

| Card | Now | Proposed |
|---|---|---|
| Backspin | return pass +25% crit | **+40%** |
| Bad Dreams / II | Caught take Drowsy | keep |
| Blood Is Thicker *(bittersweet)* | Kinship +30% | **+50%** |
| Borrowed Dew *(bittersweet)* | +150 Dew | keep |
| Close Kin / II | reach 3 / 4 | keep |
| Cozy Corners / II | bend +15% / +25% | **+30% / +50%** |
| Crowded Path / II | +3% / +4% per nightmare in range (to 30 / 40) | **+5% / +7%** (to **50 / 70**) |
| Deep Water / II | Drown rules | keep |
| Dew Trail / II | Soaked catches +20% / +35% Dew | **+30% / +50%**, and Wide Bowl's +0.5 radius |
| Evergreen / II | growing −25% / −40% | keep |
| Fresh Growth / II | +30% / +45% till the rest | **+50% / +75%** |
| Glimmering Hunt | Dreamlight shards | keep |
| Grandfather Stump | Grove Heart to +45% | keep |
| Harvest Moon | +5 Dew per rest (seeding) | **+15** per rest |
| Heavy Air | slows +20% | **+40%** |
| Heavy Eyelids / II | Drowsy cap +2 / +3 | keep |
| Heavy Seed | return pass ×2 | keep |
| Hedge Maze / II | +1% per 5 / 4 Thornwalls (to 20 / 30) | **per 3 / per 2** (to **30 / 45**) |
| Homing Instinct / II | birds return 30% / 50% faster | **50% / 90%** |
| Hungry Roots *(bittersweet)* | all +25% speed | **+40%** |
| Kind Canopy | touching 3+: +5% (seeding) | **+20%** |
| Kindred Roots / II | +2% / +3% per neighbour rank | keep |
| Last Breath / II | burst 10% / 15% max health | keep |
| Lingering Mark / II | Marked +2 s / +4 s | **+3 s / +6 s** |
| Lingering Spores / II | Spored longer / higher | keep |
| Lone Hunter / II | lone target +30% / +45% | **+45% / +70%** |
| Long Light, Loose Stones, Lullaby / II, Many Threads, Mushroom Rain, Needle Point | rules | keep |
| Many Hands | +1% per 4 attackers (to 25) | **+1% per 2** (to **+40%**) |
| Old Friends / II | Kinships start Blooming / Old Kin | keep, and **absorbs Quick Bonds** (they also grow 1 drift faster) |
| Patient Roots | Rooted +0.25 s (seeding) | **+0.5 s** |
| Reckless Bloom *(bittersweet)* | all +20% crit | **+30%** |
| Remembered Care / II, Ricochet / II, Rolling Thunder / II, Rooted Bond, Scented Hedge | rules | keep |
| Seeping / II | +5% / +7% per status (to 30 / 42) | **+8% / +12%** (to **40 / 60**) |
| Skyward Gaze | vs flyers +40%, +1 range | **+60%**, +1 range |
| Soaked Through / II | Soaked longer | keep |
| Solitude | +30%, +0.5 range | **+45%**, +0.5 range |
| Sprout Chorus | +5% speed per Sprout near (to 40) | **+8%** (to **+60%**) |
| Still Target / II | crit +15% / +25% on still targets | **+25% / +40%** |
| Still Waters | Wellspring +4% interest | **Cut** (too small, too narrow) |
| Straightaway / II | +15% / +25%, +0.5 range | **+30% / +50%**, +0.5 range |
| Sudden Insight | +1 Dreamlight | keep |
| Sunlit Rest / II, Sweet Harmony / II, Tangled Release / II, Thorn Snare / II, Twin Puff / II, Watchful Rest / II | rules | keep |
| Tangled | 2+ statuses: 10% slower | **20%** |
| Underdog / II | 3 / 4 weakest +20% / +25% | **+40% / +60%** |
| Venom Bloom *(bittersweet)* | +30% Potency | **+50%** |
| Wandering Mind | 1 reroll | **2 rerolls** |
| Weathered Walls | no trample, every 10th free | no trample, and **Thornwalls cost 1 Dew** (absorbs Cheap Hedges) |
| Wild Growth *(bittersweet)* | growing −40% (same as Evergreen II) | **−60%** |
| Wildfire Spores | Ignite spreads Spored | keep |

## Rares (≈ 61 cards)

| Card | Now | Proposed |
|---|---|---|
| Bitter Hedges | +3% per wall passed (to 15%) | **+8%** per wall (to **+40%**) |
| Canopy | +8% at 20 / 30 / 40 planted | **+12%** each time |
| Chosen Few *(bittersweet)*, Deep Sleep *(bittersweet)*, Overgrown *(bittersweet)* | +50% rank V+ / +40% all / +1 range | keep |
| Deep Well | 3% interest (to 20) | **5%** (to **40**) |
| Echoing Steps | +5% per route change in a drift | **Cut**: it rewards changing the maze mid-drift, which run_design.md rules out |
| Heart of the Maze | furthest Warden +50% | **×2 damage** |
| Hunter's Patience | Deeply Blighted +50%, bosses +20% | **+60% / +35%** |
| Last Stand | near the Heartwood +35% | **+50%** |
| Murmur | bird re-hit +15% | **+30%** |
| Old Growth | 5 drifts +15%, 15 drifts +30% | **+20% / +40%** |
| Overgrowth *(bittersweet)* | planting −30% | **−40%** |
| Shared Light | +2% per neighbour (to 10%) | **+4%** (to **+20%**) |
| Thinning the Herd | +1% per dispel in range (to 25) | **+2%** (to **+50%**) |
| All Entwined cards (Chain Bloom, Charged Feathers, Conductive Soil, Deep Stillness, Encore, Endless Night, Eye of the Tempest, Falling Stars, Fever Pitch, Kin and Kindling, Mountains Fall, Nursery, Pollen Beaks, Prism Heart, Ring of Rings, Spore Cascade, Starlit Aim, Static Bloom, Windborne Rain) | combo rules | keep; checked in the sim for being *used*, not their number |
| Borrowed Memory, Burn Back, Called Shot, Chorus, Deeper Rings, Extended Family, Few and Mighty, First Light, Guiding Light / II, Hedgerow Roots, Living Walls, Overflowing Well, Quick Reactions, Restless Dreams, Root Network / II, Root Web, Seed Storm, Seedling Gift, Shattering Blow / II, Static Field / II, Thousand Cuts | rules or already at budget | keep |

## Legendaries (32 cards)

| Card | Now | Proposed |
|---|---|---|
| The Long Walk | +1% per 4 path tiles | **+1% per 2** (a long maze ≈ +50%) |
| Monoculture | one line only: +60% | **+100%** |
| Grove of Kin | +3% per Kinship (to 30) | **+5%** (to **+50%**) |
| Golden Harvest | nothing, seeds with catchers | keep (the gamble) |
| All the others (the Ascended forms, Briar Crown, Court of the Eldest, Crossroads, Dawnbreak, Endless Rings, Eternal Static, Full Moon, Hunter's Moon, Last Leaf, Lucid Dreaming, Menagerie, Nightshade, Restless Night, Rootbound, Rooted Nightmares, The Last Light, The Old Ones, The Quiet Ones, Wildwood Reclaimed) | run-defining | keep |

## Pool after the pass

- **Cut:** Fair Trade, Still Waters, Echoing Steps.
- **Merged away:** Cheap Hedges (→ Weathered Walls), Quick Bonds (→ Old Friends), Wide Bowl (→ Dew Trail).
- **Raised:** ~85 cards. **Kept:** the rest (mostly rules, Entwined, Legendaries).
- **227 → 221 Dream cards.** Smaller than I first guessed (~200): most small cards carry a distinct
  idea, so raising them beats cutting them.

## New rules that come with it

1. **Builds pay off (tag resonance):** each card you own with a tag makes the **next** cards of that
   tag **+10% stronger** (their numbers, not their rules), up to +50%. Shown on the card: *"+20% from
   2 spore cards"*. Committing beats grabbing the biggest number. Generic cards (no tag) don't resonate.
2. ~~The first Dream is a keystone~~ **Rejected** (user: "too forgiving and too narrow of a path"):
   the drift-5 offer stays a normal offer. Finding a direction is the player's job.
3. **Nightmares rise with the cards:** once the pass is in, Tower Code raises nightmare health until
   the targets hold (always skipping falls by the drift-25 boss). Never before the cards are in.

## Order

1. **Approved by the user (2026-09-30).** Balance direction: **raise nightmare health, never cut Warden damage** (only outliers get their own trims); if drifts drag, part of the rise becomes more nightmares instead.
2. Roguelite Code applies it (data + the two rules above; card text through `text_style.md`).
3. Tower Code reruns skip / random / Balanced and tunes health; the numbers here move with it.

**Applied (cc38d56e, Roguelite Code):** all Proposed lines, the cuts, merges (old ids migrate in run saves; the Grove Catchers node dropped them) and tag resonance (counted on the card's best-represented tag, locked when taken, never from a Deepened card's own base; `DreamState.rule_power(rule_id)` for rule numbers). Calls made there: **Deep Grip and Bright Marks no longer stack** (at +50% / +20%, three stacks would be too much); Cliffside's +20% shows in its Dream row. Numbers that live in Tower Code's files (Acorn aura, Hush, Sudden Bloom, Backspin, Kinship, catches) follow from them.

## New cards 204–226 (raised to budget in 46287b83)

| # | Card | Rarity | Now |
|---|---|---|---|
| 204 | Elder Kin | Uncommon | kin share 25% of rank bonuses (rule) |
| 205 | Many Rings | Uncommon | +2% per rank to all Sprouts, max +50% (was 1% / 25%) |
| 206 | Big Family | Uncommon | Sprouts near a Kinship pair +45% attack speed (was 10%) |
| 207 | Mycelium | Uncommon | 1 Poisoned on hit (rule) |
| 208 | Fireflies in the Grass | Uncommon | 1 Charged every 3rd hit (rule) |
| 209 | Seasoned Eye | Uncommon | +3% crit per rank, max +21% (was 1% / 7%) |
| 210 | Hedgerow | Common | +30% (was 10%) |
| 211 | Spore Kin | Uncommon | Harmony applies 2 Poisoned (rule) |
| 212 | Resonance | Rare | Chime pulses add 1 Charged (rule) |
| 213 | Thornheart | Rare | +5% per Bramble, max +100% |
| 214 | Ill Wind | Uncommon | +45% (was 25%) |
| 215 | Eddy | Uncommon | rule |
| 216 | Spinning Corners | Uncommon | +45% spin (was 20%) |
| 217 | Falling Weight | Uncommon | +45% (was 40%) |
| 218 | Warm Hearth | Uncommon | auras +50% on Sprouts |
| 219 | Fresh Soil | Common | 7 Dew and +30% (was 20%) |
| 220 | Quick Step | Common, ×3 | +15% speed for 10 s per stack (was 10%) |
| 221 | Hurried Harvest | Uncommon | +2 Dew, cap 40 per drift (was 1 / 20) |
| 222 | Heartwood's Fury | Uncommon | +5% per missing leaf, max +45% (was 3% / 30%) |
| 223 | Thin Bark | Uncommon, bittersweet | all +35% (was 15%), −3 max leaves |
| 224 | Patchwork | Common | +5% per family, max +15% (was 3% / 12%) |
| 225 | Mixed Grove | Uncommon | +15% per other family touching, max +45% (was 8% / 24%) |
| 226 | Live Wire | Common, ×3 | bolts +15% per stack (max +45%) |

## The 11 late-built cards (raised to budget in 34a713c0)

Designed in 2026-09 but never built until the catalogue measurement found them missing.

| # | Card | Rarity | Now |
|---|---|---|---|
| 37 | Glinting Dew | Common, ×3 | +8% crit chance per stack, max +24% (was 4%) |
| 38 | Heavy Stones | Common, ×3 | Pebbling line +15% crit chance per stack, max +45% (was 8%) |
| 49 | Deep Frost | Uncommon | Frozen nightmares (Held by a water Warden) take +45% (was 20%) |

The other eight (Sharpened Light / II, Long Shadows, Patient Aim, Ring Dance, Carried on the Wind,
Sweet Scent, Shiny Things, Hairpin Winds) were already at budget. Grove homes (Meta): Long Shadows
on the Pebbling node, Sweet Scent on the Bellflower node.

## Pool trim (2026-09-30)

User-approved shrink of the pool (the full rationale and the 10 card builds are in `dream_design.md`,
"Pool trim"). Merged cards take the stronger number within budget, not the sum:

- **Cut:** Borrowed Dew, Hungry Roots, Overgrown, Wild Growth, Reckless Bloom, Overgrowth, Borrowed
  Memory, Remembered Care, Seasoned Eye, Many Rings, Big Family, Sudden Bloom, Underdog, Cliffside,
  Tangled (broke the status jobs), Patchwork, Hedgerow, Shelter of Stones, Short Roots.
- **Merged away:** Gathered Dew (→ Morning Dew), Fresh Soil (→ Reclaimed Earth), Tend the Forest (→
  Heartwood's Reach; it gave free clears), Mending Bark (→ Thick Bark), Heartwood's Fury (→ Last
  Stand), Warm Hands (→ Tender Care), Court of the Eldest (→ Endless Rings), Sprout Surge (→
  Seedfall), Close Kin (→ Extended Family), Skyward Gaze (→ Hunter's Patience), Crush (→ Crowd
  Breaker), Hurried Harvest (→ Call of the Wild).
- Their Deepened versions go with them (a merged card's II follows the absorbing card's II).

## Tender Care rework (2026-09-30)

User: "Tender Care doesn't seem like it fits anymore." The trim merged Warm Hands into it (−15% nurture
cost and +3% damage per rank, stacking) and it kept its `economy` tag, so it showed an economy
tag-resonance bonus. **Now:** every Warden's first Nurture rank is free (rank I ≈ +14% DPS on every
attacking Warden, the Common all-Wardens budget); **II:** rank I free and ranks II–V cost 20% less.
Tags: `nurture` + archetype `tall` only (no `economy`, no stacking). As a Tall opener it also meets the
"a ranked Warden" Needs of the Tall follow-ups.
