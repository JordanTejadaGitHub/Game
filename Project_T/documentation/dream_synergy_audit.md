# Dream card synergy and build diversity audit (2026-10-08)

Analysis and design planning only. No card, script or `.tres` file was changed, and nothing is
committed. Every proposal below waits for the user's approval.

**How to read this report.** Each claim is marked:
- **[Code]** confirmed in the implementation (file and function named).
- **[Data]** read from the card resources (`resource/dream/*.tres`).
- **[Docs]** documented design intent (`dream_design.md` and others), not re-checked in code.
- **[Inference]** reasoning or arithmetic from the above, not measured.
- **[Rec]** a recommendation.

**Sources:** all 411 files in `resource/dream/`, `scripts/run/dream_state.gd` (offer, pool, Needs),
`scripts/run/dream_effects.gd`, `scripts/tower/tower.gd`, `scripts/combat/reactions.gd`,
`scripts/combat/kinships.gd`, `resource/reaction/`, `resource/tower/`, `resource/meta/grove/`, and
`dream_design.md`. Four read-only passes classified the 249 offerable base cards against the
code; I re-checked every code/text mismatch listed in section 6 that is marked "verified".

---

## 1. Executive summary

**What exists [Data]:**
- 411 card files:
  - **249 offerable base cards** (150 in the start pool, 99 unlocked in the Memory Grove);
  - **46 Deepened "II" cards**;
  - 116 Warden-unlock cards, which are bought with Dreamlight on the Remember screen and are never
    Dream offers.
- By rarity:

  | Pool | Common | Uncommon | Rare | Legendary |
  |---|---|---|---|---|
  | Start | 59 | 54 | 33 | 4 |
  | Grove | 10 | 35 | 34 | 20 |

- 40 cards carry `defining`; 22 are Entwined or Woven; 7 are Bittersweet; 7 are Seed cards.
- Roles (classification passes):

  | Role | Cards |
  |---|---|
  | Payoff | 83 |
  | Support | 62 |
  | Utility | 52 |
  | Enabler | 30 |
  | Bridge | 22 |

- Useful on their own: 62 Yes, 78 Partial, 109 No.

**The speculation loop already exists in pieces:**
- **Half-dreamed combo cards** [Code, `half_dreamed_missing`]: a two-family combo card can be
  offered when you own one family and a family pick is ≤ 20 drifts away. You can take it "dormant",
  hoping the next pick offers the other family. That is exactly the Slay-the-Spire bet the user
  describes, and it can fail.
- **Seed cards** [Data, `grows_with` / `grows_text`]: a small effect now, a bigger one if you later
  own a named Warden.
- **Passed-over fading** [Code, `get_passed_weight`]: passing a card has a real cost. It can't
  return in the next offer, and it fades ×0.6 per pass after that (floor ×0.1).
- **Trade-off combo cards** [Data]: most combo cards now carry a price, so they're choices rather
  than automatic picks.

**The biggest findings:**

1. **The Stray Dream now pushes away from your build** [Code, `make_offer` / `_weighted_pick`].
   - It was designed to counter build steering. Steering is off now (`tag_weight` = 1.0), but the
     Stray slot still weights every card that shares an archetype tag you own at ×0.25, from the
     drift-10 rest on.
   - [Inference] Once you own two or three archetypes, most tagged cards count as "in build". The
     one Stray slot then mostly draws untagged cards: plain stats, economy, family cards.
   - So the system quietly makes *finding the enabler you speculated on* less likely than chance,
     and it feeds generic Utility.
2. **Fresh profiles have almost no payoffs to speculate toward** [Data].
   - Start-pool Rares by archetype: tall 0, daring 0, tending 0, swift 0, reach 0, overgrowth 1,
     maze 2, precision 2, affliction 2, kinship 4.
   - Only 4 start-pool Legendaries: Hunter's Moon, The Long Walk, Grove of Kin, Dawnbreak.
   - On a first profile, a Swift or Tending support pick has no rare jackpot to find. The jackpots
     live in the Grove.
   - Of the 43 start-pool cards with a Warden Need, 18 name a Grove-only family: Rootling, Pebbling,
     Whirligig, Nestling or Acorn lines, or Tangleroot in the three-family Woven cards. On a fresh
     profile they can never be offered. Most of the rest need a *branch* of a starting family.
3. **Half the Reactions sit behind a branch on a fresh profile** [Code + Data].
   - The four starting families' base Wardens apply Spored, Charged, Soaked and Drowsy.
   - Marked comes only from Lanternmoth (a Firefly Jar branch), and Held only from Frostfern (a
     Dewdrop branch) or the Grove's Rootling line.
   - So Pinned, Shatter, Smother and Lightning Rod each need a specific branch: it has to be drawn in
     a 2-of-5 branch offer, then bought with Dreamlight.
   - The one card that makes Held with walls, Briar Trap (`thorn_snare`), is Grove-only.
   - [Inference] That's a healthy "maybe" for a speculative build, but no card makes Marked or Held
     from a generic source, so there's no second route.
4. **The "use-now" hard Needs block speculation** [Code, `board_can_use`, 2026-10-06].
   - Specialist, Many Talents, Small Hands, Lingering Ground, Sap Rising, Seasoned, Edge of Sight,
     Wide Swing, Scatter and others can't be offered until the board already uses them.
   - That fixed act 1 dilution (measured: bot act 1 survival 63% → 40% before the fix), but it
     removes exactly the early "build toward it" picks the user wants.
5. **Seed cards, the best speculative pattern, are all Grove-only** [Data]: Bramble Oath, Deep
   Well, Dew Bowl, Harvest Moon, Sheltering Boughs (`kind_canopy`), Patient Roots, Shared Light.
   None is in the start pool.
6. **Entwined cards are not guaranteed** [Code, comment in `make_offer`; Docs, "Combo cards are
   choices, not musts", user-approved 2026-10-02]. `CLAUDE.md` and the comment in
   `upgrade_data.gd` still say they're guaranteed. Section 5 covers this.
7. **Redundancy clusters** [Data + classification]:
   - Sprout clusters: Thicket (`sprout_chorus`), Root Network, Undergrowth.
   - Leaf-loss damage: Scarred Bark, Last Leaf, Stung.
   - Bend bonuses: Cozy Corners (II outclasses the Legendary Crossroads), Switchback, Spinning
     Corners.
   - Cleared-cell damage: Mulch, Reclaimed Earth, Wildwood Reclaimed, Tended Forest.
   - Spread on dispel: Spore Cascade vs Passing Dream.
   - Sprout discounts: Seedfall vs Cheap Seeds vs Bountiful.
   - Lone-Warden damage: Solitude vs Heart of the Maze.
   - Variety count: Menagerie vs Grand Tour.
8. **Confirmed bugs and text mismatches** (section 6):
   - Grandfather Stump does nothing as worded.
   - Few and Mighty has no cap.
   - Monoculture is broken by any Sprout.
   - Deeper Rings' text promises rank VII to every Warden.
   - First Frost's text doesn't match its hook.
   - Old Growth lost all its tags.

**Recommended direction, in one line [Rec]:** keep the random three-card offer. Remove the forces
that work against speculation (the reversed Stray slot, hard Needs after act 1), put the Seed
pattern and a few Rare payoffs into the start pool, add Held and Marked bridges, and add 20
bridges and enablers that connect mechanics rather than stack numbers.

---

## 2. Complete Dream classification catalogue

Every offerable base card (249), grouped by its first archetype.
- **R / pool:** C/U/R/L rarity, S = start pool, G = Grove.
- **Role:** primary / secondary (Support, Enabler, Payoff, Bridge, Utility).
- **Needs:** the hard and soft prerequisites from the data. `requires` lists Warden or card ids;
  "any of" = `requires_any`; `discovered_by` = discovery gate.
- **Alone?:** Yes / Partial / No, whether it's useful with no other card.
- **Deepened (II) cards:** listed in `base.tsv` beside their base. They compete in the same draw
  once the base is owned.
- **Sources:** classification by the four read-only passes against the data and code. Rows marked
  "code differs" were re-checked in section 6.
- **Machine-readable copies:** `D:\Projects\logs\dream_audit\class_all.tsv` (classification) and
  `base.tsv` (card data, Needs, rule ids, descriptions, costs, Deepened).

#### maze

| Card | R / pool | Role | Needs | Archetypes | Alone? | Key synergies | Overlaps | Issues |
|---|---|---|---|---|---|---|---|---|
| `bitter_hedges` Bitter Hedges | R G | Payoff | count_warden=thornwall min_warden_count=6 | maze | No | weathered_walls, twig_walls, hedge_maze, thorny_walls, briar_crown | hedge_maze (wall-count damage) | Need 6 Thornwalls |
| `bramble_oath` Bramble Oath | C G | Payoff / Support | — | maze | No | weathered_walls, twig_walls, the_long_walk, weary_feet, thornheart | the_long_walk (path-length damage) | Seed card: the Bramble/Honeysuckle +50% is its grows_text (not a bug); UI reason text says <10 tiles but 5 pay |
| `briar_crown` Briar Crown | L G | Enabler / Payoff | — | maze | No | thorny_walls, hedge_maze, twig_walls, weathered_walls, bitter_hedges | thorny_walls (walls deal damage) | no wall Need on a Legendary; dead without walls |
| `cozy_corners` Cozy Corners | U S | Payoff / Enabler | **defining** | maze | Partial | switchback, spinning_corners, hedge_maze, twig_walls, crossroads | switchback (bend bonus), crossroads | II outclasses Legendary crossroads |
| `crossroads` Crossroads | L G | Payoff | — | maze | Partial | cozy_corners, twig_walls, weathered_walls, the_long_walk, heart_of_the_maze | cozy_corners (positional maze bonus) | weak for a Legendary vs cozy_corners_ii |
| `first_frost` First Frost | C S | Utility | — | maze | Partial | deep_grip, falling_weight, still_target, patient_roots, root_web | thorn_snare (once-per-drift hold) | code differs: bosses never held (not in text); each Warden holds its first one, not only the drift's first nightmare |
| `forests_edge` Forest's Edge | C G | Utility | — | maze | Partial | head_of_the_line, weary_feet, solitude, heart_of_the_maze, lantern_glow | last_stand (zone dmg) | few cells; value varies by layout |
| `hairpin_winds` Hairpin Winds | U G | Support | pinwheel | maze, family:pinwheel | No | spinning_corners, cozy_corners, the_long_walk, switchback | - | family-narrow |
| `heart_of_the_maze` Heart of the Maze | R S | Enabler / Payoff | min_attackers=4; **defining** | maze, precision | Partial | solitude, first_among_equals, sunlit_rest, the_long_walk, specialist | solitude (isolated Warden dmg) | - |
| `hedge_maze` Hedge Maze | U S | Payoff | — | maze | Partial | twig_walls, weathered_walls, bramble_oath, thorny_walls, hedgerow_roots | bramble_oath (wall-count dmg) | - |
| `hedgerow_roots` Hedgerow Roots | R G | Bridge | any of: acorn, elder_stump, grove_heart | maze, tending, family:acorn | No | kind_canopy, grandfather_stump, hedge_maze, twig_walls, warm_hearth | - | - |
| `last_stand` Last Stand | R G | Utility | — | maze, daring | Yes | head_of_the_line, the_long_walk, weary_feet, close_guard | forests_edge (zone dmg) | - |
| `living_walls` Living Walls | R G | Bridge | bramble | maze, tending | No | thornheart, twig_walls, weathered_walls, thorny_walls, hedge_maze | - | needs Bramble unlocked |
| `longer_flight` Longer Flight | C G | Support | samara | maze, family:samara | No | heavy_seed, ricochet, windborne_rain, seed_storm | - | family-narrow |
| `narrow_way` Narrow Way | C S | Payoff | — | maze | Partial | cozy_corners, switchback, straightaway, twig_walls, hedge_maze | cozy_corners / straightaway (path-shape dmg) | Depends on half-cell walls (twig_walls); map-dependent |
| `rooted_nightmares` Rooted Nightmares | L G | Enabler | — | maze | Yes | patient_roots, root_web, falling_weight, still_target, deep_grip | - | - |
| `scented_hedge` Scented Hedge | U G | Bridge | honeysuckle | maze, family:honeysuckle | No | sweet_scent, thorn_snare, hedge_maze, weathered_walls, twig_walls | - | Family-locked |
| `straightaway` Straightaway | U S | Enabler | **defining** | maze | Partial | the_long_walk, weary_feet, forests_edge, last_stand, solitude | - | opposes cozy_corners/switchback (bends) by design |
| `switchback` Switchback | C S | Utility / Support | — | maze | Yes | cozy_corners, spinning_corners, hairpin_winds, momentum, eddy | cozy_corners (bend bonus) | - |
| `tangled_release` Tangled Release | U S | Support | rootling | maze, family:root | Partial | root_web, patient_roots, deep_grip, rooted_nightmares, thorn_snare | - | small effect (0.5 tile) |
| `the_long_walk` The Long Walk | L S | Payoff | — | maze | Yes | weary_feet, bramble_oath, twig_walls, straightaway, hedge_maze | weary_feet (path length) | uncapped in code (1% per 2 tiles) |
| `thornheart` Thornheart | R G | Payoff | bramble | maze, family:wall | No | living_walls, hedge_maze, bitter_hedges, briar_crown | - | needs many Brambles |
| `thorny_walls` Thorny Walls | C S | Enabler | **defining** | maze, tending | Yes | twig_walls, weathered_walls, hedge_maze, bitter_hedges, living_walls | briar_crown (wall damage) | - |
| `twig_walls` Twig Walls | R S | Enabler | **defining** | maze | Yes | thorny_walls, hedge_maze, the_long_walk, bramble_oath, narrow_way | weathered_walls (cheap Thornwalls) | - |
| `weary_feet` Weary Feet | C S | Support | — | maze | Yes | the_long_walk, bramble_oath, last_stand, twig_walls, straightaway | the_long_walk (path length) | - |
| `weathered_walls` Weathered Walls | U S | Utility / Support | — | maze | Yes | thorny_walls, twig_walls, hedge_maze, bramble_oath, the_long_walk | twig_walls (cheap Thornwalls) | - |
| `winding_path` Winding Path | C S | Utility | — | maze | Yes | the_long_walk, cozy_corners, harvest_moon, deep_well, weary_feet | - | - |

#### affliction

| Card | R / pool | Role | Needs | Archetypes | Alone? | Key synergies | Overlaps | Issues |
|---|---|---|---|---|---|---|---|---|
| `bad_dreams` Bad Dreams | U G | Support | dreamcatcher | affliction, family:dreamcatcher | No | many_threads, lullaby, heavy_eyelids, still_target, falling_weight | lullaby (both extend Caught) | narrow family; II only +1 stack/s |
| `bitter_sap` Bitter Sap | C S | Utility / Support | — | affliction | Partial | brimming, lasting_dreams, seeping, nightshade, grand_tour | - | plain stat card (PLAIN_STAT_CARDS); dead without status Wardens |
| `brimming` Brimming | R S | Enabler / Support | requires_any_status=spored, static, drowsy; **defining** | affliction | No | bitter_sap, lasting_dreams, nightshade, seeping, eternal_static | heavy_eyelids (Drowsy cap up) | broke stack pips (fixed 226522f1) |
| `carried_on_the_wind` Carried on the Wind | R G | Support | gust; min_owned_statuses=1; Entwined | affliction, family:gust | No | brimming, ill_wind, bitter_sap, lasting_dreams, nightshade | - | cost cancels eddy (code caps copies to 1 even with Eddy) |
| `chain_bloom` Chain Bloom | R S | Payoff | puffball, mistveil; discovered_by=event:puff_in_fog; Entwined | affliction, family:sporeling | No | wide_petals, lingering_ground, far_reach, crowd_breaker, overlap | - | two-Warden Need + discovery gate; very narrow |
| `charged_feathers` Charged Feathers | R G | Bridge | hummingbird_bower, firefly_jar; excludes=pollen_beaks; Entwined | affliction, family:hummingbird | No | live_wire, static_field, sharp_beaks, eternal_static, thousand_cuts | pollen_beaks (peck applies status) | excludes pollen_beaks (by design) |
| `conductive_soil` Conductive Soil | R S | Bridge | stormcap, rain_lily; discovered_by=reaction:thunderclap; Entwined | affliction, family:stormcap, family:rain_lily | No | rolling_thunder, rain_on_glass, live_wire, static_field, lasting_dreams | - | Entwined; discovery-gated (thunderclap) |
| `damp_rot` Soaked Rot | C S | Bridge | sporeling, dewdrop; discovered_by=reaction:mushrooming | affliction, family:sporeling, family:dewdrop | No | mushroom_rain, heavy_dew, lasting_dreams, bitter_sap, brimming | - | cost: Damp loses water-hit bonus |
| `dawnbreak` Dawnbreak | L S | Payoff | discovered_by=chain:10 | affliction | No | quick_reactions, brimming, kin_and_kindling, lasting_dreams, grand_tour | - | dead early; discovery-gated (chain:10) |
| `deep_stillness` Deep Stillness | R S | Payoff | rain_lily, tangleroot, bellflower; discovered_by=crowned:still_pool; Woven | affliction, family:rain_lily | No | lingering_ground, quick_reactions, brimming, falling_weight, still_target | - | 3-family Need + crowned discovery; tiny audience |
| `deep_water` Deep Water | U S | Payoff | dewdrop; discovered_by=reaction:drown | affliction, family:dewdrop | No | last_stand, heavy_dew, quick_reactions, lasting_dreams, bad_dreams | - | cost: only near the Heartwood (pairs with last_stand) |
| `eddy` Eddy | U S | Support | whirligig | affliction, maze, family:gust | No | ill_wind, spinning_corners, cozy_corners, lasting_dreams, bitter_sap | - | nullified by carried_on_the_wind (1 target) |
| `encore` Encore | R G | Payoff | echo_hollow; requires_tag=reaction; Entwined | affliction, family:echo_hollow | No | quick_reactions, brimming, dawnbreak, seeping, kin_and_kindling | - | narrow (Echo Hollow + Reactions) |
| `endless_night` Endless Night | R S | Payoff | bloomcap, rain_lily, bellflower; discovered_by=crowned:nightbloom; Woven | affliction, family:bloomcap | No | lingering_ground, quick_reactions, brimming, heavy_eyelids, lasting_dreams | - | 3-family Need + crowned discovery; halves fire rate |
| `eternal_static` Eternal Charge | L G | Enabler / Bridge | — | affliction | Yes | live_wire, static_field, brimming, flurry, seeping | charged_feathers (Static on hit) | - |
| `eye_of_the_tempest` Tempest's Reach | R S | Payoff | stormcap, rain_lily, driftspore; discovered_by=crowned:tempest; Woven | affliction, family:stormcap | No | wildfire_spores, sparking_spores, conductive_soil, quick_reactions, brimming | - | 3-family Need + crowned discovery; halves fire rate |
| `falling_stars` Falling Stars | R S | Payoff | firefly_jar, tangleroot; any of: chime_stone, bellflower; discovered_by=crowned:starfall; Woven | affliction, family:firefly_jar | No | static_field, live_wire, eternal_static, quick_reactions, patient_roots | - | 3-family Need + crowned discovery; halves fire rate |
| `fever_pitch` Fever Pitch | R S | Payoff | driftspore, tangleroot, bellflower; discovered_by=crowned:fever_dream; Woven | affliction, family:driftspore | No | quick_reactions, brimming, lasting_dreams, bitter_sap, seeping | - | 3-family Need + crowned discovery; halves fire rate |
| `grand_tour` Grand Tour | R G | Payoff | min_owned_statuses=2 | affliction | Partial | seeping, nightshade, menagerie, mixed_grove, brimming | menagerie (variety dmg) | - |
| `heavy_air` Heavy Air | U S | Support | requires_any_status=drowsy | affliction | Partial | scatter, hobble, still_target, heavy_eyelids, sweet_scent | - | Need is drowsy but effect is all slows; stale code comment says 20% |
| `heavy_eyelids` Heavy Eyelids | U G | Support | requires_status=drowsy | affliction, family:sleep | No | many_threads, bad_dreams, brimming, still_target, lullaby | brimming (raises status caps) | - |
| `ill_wind` Ill Wind | U S | Support | whirligig | affliction, family:whirligig | No | carried_on_the_wind, eddy, seeping, nightshade, venom_bloom | - | - |
| `last_breath` Last Breath | U S | Enabler / Bridge | **defining** | affliction | Yes | passing_dream, spore_cascade, spillover, venom_bloom, crowd_breaker | spillover (on-death splash) | - |
| `lasting_dreams` Lasting Dreams | C S | Support | min_owned_statuses=1 | affliction | Partial | bitter_sap, brimming, seeping, grand_tour, passing_dream | - | - |
| `lingering_ground` Lingering Ground | U S | Support | **defining** | affliction | No | lingering_splash, ring_of_rings, long_light, deep_stillness, endless_night | long_light (lit-tile linger) | - |
| `live_wire` Live Wire | C S | Support | requires_status=static | affliction, family:storm | No | static_field, eternal_static, brimming, conductive_soil, fireflies_in_the_grass | static_field (Static bolt spread) | - |
| `lullaby` Slow Waking | U S | Support | dreamcatcher | affliction, family:dreamcatcher | No | many_threads, bad_dreams, heavy_eyelids, still_target | - | - |
| `many_threads` Many Threads | U G | Support | dreamcatcher | affliction, family:dreamcatcher | No | heavy_eyelids, lullaby, bad_dreams, heavy_air, sweet_scent | - | - |
| `mountains_fall` Mountain's Fall | R S | Payoff | cairn, frostfern, tangleroot; discovered_by=crowned:avalanche; Woven | affliction, family:cairn | No | quick_reactions, lingering_ground, seeping, falling_weight, loose_stones | - | 3-family Need + crowned discovery: very narrow; Bittersweet halves Avalanche |
| `mushroom_rain` Mushroom Rain | U S | Payoff | sporeling, dewdrop; discovered_by=reaction:mushrooming | affliction, family:sporeling | No | quick_reactions, lingering_ground, damp_rot, seeping, nightshade | - | Two-family Need + discovery; Bittersweet halves duration (net gain unclear) |
| `nightshade` Nightshade | L G | Payoff | — | affliction | No | seeping, grand_tour, bitter_sap, lasting_dreams, venom_bloom | seeping (per-status effect dmg; additive) | 4 statuses on one target: high bar |
| `passing_dream` Passing Dream | C S | Support | — | affliction | Partial | brimming, lasting_dreams, spore_cascade, seeping, nightshade | spore_cascade (status spread on dispel) | Makes spore_cascade nearly a subset |
| `pollen_beaks` Pollen Beaks | R G | Bridge | hummingbird_bower, sporeling; excludes=charged_feathers; Entwined | affliction, family:hummingbird | No | sharp_beaks, damp_rot, seeping, brimming, needle_point | charged_feathers (same, Static; exclusive) | Two-family Need; excludes charged_feathers by design |
| `prism_heart` Prism Heart | R S | Payoff | frostfern, tangleroot, stormcap; discovered_by=crowned:prismstorm; Woven | affliction | No | quick_reactions, live_wire, static_field, eternal_static, seeping | - | 3-family Need + crowned discovery: very narrow |
| `quick_reactions` Quick Reactions | R S | Payoff | min_reaction_pairs=2 discovered_by=reactions:2 | affliction | Partial | dawnbreak, seeping, kin_and_kindling, nightshade, lasting_dreams | - | Bittersweet -35% Reaction dmg may net-lose |
| `rain_on_glass` Rain on Glass | C S | Payoff / Bridge | dewdrop, firefly_jar; discovered_by=reaction:thunderclap | affliction, family:firefly_jar | No | heavy_dew, conductive_soil, rolling_thunder, live_wire, static_field | - | Bittersweet (hits dry Damp) undercuts Thunderclap / conductive_soil |
| `resonance` Thunder Chimes | R S | Bridge | bellflower, firefly_jar | affliction, family:bellflower | No | live_wire, static_field, eternal_static, chorus, static_bloom | - | Only the Chime Stone form; two-family Need |
| `ring_dance` Ring Dance | R G | Payoff | fairy_ring, driftspore; Entwined | affliction, family:fairy_ring | No | ring_of_rings, lingering_ground, damp_rot, seeping, mushroom_rain | - | Two-family Need (Entwined) |
| `ring_of_rings` Ring of Rings | R S | Payoff | fairy_ring, rain_lily, tangleroot; discovered_by=crowned:fairy_circle; Woven | affliction | No | ring_dance, quick_reactions, lingering_ground, seeping | - | 3-family Need + crowned discovery: very narrow |
| `rolling_thunder` Rolling Thunder | U S | Payoff | stormcap, dewdrop; discovered_by=reaction:thunderclap | affliction | No | conductive_soil, rain_on_glass, live_wire, quick_reactions, static_field | - | Bittersweet 3-target cap hurts vs swarms |
| `seeping` Seeping | U G | Payoff / Support | min_owned_statuses=2; **defining** | affliction | No | nightshade, bitter_sap, grand_tour, brimming, venom_bloom | nightshade (per-status effect dmg) | - |
| `sparking_spores` Sparking Spores | C S | Payoff | sporeling, firefly_jar; discovered_by=reaction:ignite | affliction, family:spore+storm | No | wildfire_spores, brimming, bitter_sap, damp_rot, lasting_dreams | - | text "burns twice as hot" = code doubles burn rate (faster Spored ticks); condition in cost column though not bittersweet |
| `spore_cascade` Spore Cascade | R S | Support | driftspore; Entwined | affliction, family:spore | Partial | passing_dream, brimming, bitter_sap, wildfire_spores, damp_rot | passing_dream (status jump on dispel) | Rare Entwined needing only driftspore |
| `static_bloom` Charged Bloom | R S | Bridge | stormcap, bloomcap; discovered_by=event:charged_drowsy; Entwined | affliction, family:storm+sleep | No | many_threads, bad_dreams, still_target, heavy_eyelids, live_wire | - | needs stormcap + bloomcap; costs 1 chain jump |
| `static_field` Charged Field | R S | Support | firefly_jar | affliction, reach | Partial | live_wire, eternal_static, brimming, resonance, charged_feathers | live_wire (bolt extra target) | - |
| `sweet_scent` Sweet Scent | U G | Support | honeysuckle | affliction, family:wall+sleep | No | scented_hedge, many_threads, still_target, heavy_eyelids, bad_dreams | - | single Warden range buff |
| `thinning_the_herd` Thinning the Herd | R S | Support | — | affliction | Partial | quickening, crowd_breaker, spillover, last_breath, crowded_path | quickening (kill-in-range buff) | tagged affliction but is kill-count, not status |
| `twin_puff` Twin Puff | U S | Support | sporeling; count_warden=sporeling min_warden_count=1 | affliction, family:spore | No | bitter_sap, damp_rot, sparking_spores, spore_cascade, mycelium | flurry (extra fire) | count_warden sporeling min 1 redundant with requires |
| `venom_bloom` Venom Bloom | U G | Enabler / Payoff | Bittersweet | affliction | Partial | nightshade, seeping, brimming, bitter_sap, lasting_dreams | nightshade (effect dmg) | bittersweet; stacks hit penalty with whirlwind_heart |
| `wildfire_spores` Wildfire Spores | U S | Payoff / Bridge | sporeling, firefly_jar; discovered_by=reaction:ignite | affliction, family:spore+storm | No | sparking_spores, spore_cascade, brimming, damp_rot, mushroom_rain | spore_cascade (spore spread) | cost (burner loses its Spored) cuts against sparking_spores' 5-stack check |
| `windborne_rain` Windborne Rain | R G | Bridge | samara, rain_lily; Entwined | affliction, family:wind+water | No | conductive_soil, rain_on_glass, damp_rot, rolling_thunder, heavy_seed | - | needs samara + rain_lily |

#### precision

| Card | R / pool | Role | Needs | Archetypes | Alone? | Key synergies | Overlaps | Issues |
|---|---|---|---|---|---|---|---|---|
| `backspin` Backspin | U G | Payoff | samara | precision, family:samara | Partial | heavy_seed, seed_storm, sharpened_light, full_moon, shattering_blow | - | narrow (one Warden line); return pass only |
| `bright_marks` Bright Marks | C S | Payoff | lanternmoth | precision, family:lanternmoth | No | called_shot, guiding_light, starlit_aim, hunters_moon, bitter_sap | - | - |
| `called_shot` Called Shot | R S | Payoff / Bridge | lanternmoth | precision, family:lanternmoth | No | bright_marks, sharpened_light, guiding_light, steady_aim, shattering_blow | first_light (first-hit burst) | needs Lanternmoth Marked source |
| `deep_frost` Deep Frost | U G | Payoff | frostfern | precision, family:frostfern | No | still_target, patient_roots, sharpened_light, root_web, full_moon | falling_weight (amp vs CC) | only one freeze source |
| `edge_of_sight` Edge of Sight | C S | Utility / Payoff | — | precision | Partial | long_shadows, longer_roots, far_reach, growth_rings, head_of_the_line | - | hidden Need: an attacker with range 4+ (board_can_use) |
| `first_light` First Light | R S | Payoff / Utility | — | precision | Yes | quick_draw, hunters_moon, called_shot, small_hands, sharp_beaks | called_shot (first-hit bonus) | strong vs swarms, weak vs bosses |
| `full_moon` Full Moon | L G | Payoff | — | precision | Partial | glinting_dew, starlit_aim, still_target, patient_aim, sharpened_light | - | overflow needs ~100% crit, rarely reached |
| `glinting_dew` Glinting Dew | U S | Utility / Support | — | precision | Yes | sharpened_light, hobble, shattering_blow, flurry, steady_aim | - | flat stat (plain-stat list) |
| `guiding_light` Guiding Light | R S | Support / Bridge | lanternmoth, cozy_corners; Entwined | precision | No | bright_marks, called_shot, starlit_aim, hunters_moon, cozy_corners | - | odd Entwined recipe: cozy_corners (maze) unrelated to the effect |
| `head_of_the_line` Head of the Line | C S | Utility | — | precision | Yes | last_stand, lone_hunter, first_light, forests_edge | - | flat stat |
| `hobble` Hobble | C S | Support | — | precision | No | glinting_dew, full_moon, heavy_air, still_target, sharpened_light | scatter (slow proc) | needs a crit source |
| `hunters_moon` Hunter's Moon | L S | Enabler / Payoff | — | precision | Yes | bright_marks, called_shot, starlit_aim, guiding_light, first_light | - | - (Exposes = player name of Marked) |
| `hunters_patience` Hunter's Patience | R G | Utility / Payoff | **defining** | precision | Yes | glimmering_hunt, long_shadows, first_light, lone_hunter | - | 3 effects bundled (absorbed Skyward Gaze) |
| `lone_hunter` Lone Hunter | U S | Payoff | **defining** | precision | Yes | scatter, head_of_the_line, hunters_patience, first_light | - | weak vs packs |
| `patient_aim` Patient Aim | U G | Payoff | standing_stone | precision, family:standing_stone | No | restless_roots, watchful_rest, full_moon, sharpened_light, shattering_blow | - | Anti-synergy with speed cards; family-locked |
| `sharpened_light` Sharpened Light | U G | Support | — | precision | Partial | full_moon, glinting_dew, still_target, called_shot, shattering_blow | steady_aim (crit dmg) | flat stat; dead with 0 base crit (original roster crit 0) |
| `shattering_blow` Shattering Blow | R G | Bridge / Payoff | — | precision, reach | Partial | glinting_dew, full_moon, sharpened_light, called_shot, spillover | spillover (overkill splash) | needs a crit source first |
| `solitude` Solitude | U S | Enabler / Payoff | **defining** | precision, maze | Yes | heart_of_the_maze, the_last_light, few_and_mighty, twig_walls, watchful_rest | heart_of_the_maze (lonely Warden bonus) | anti-synergy with rootbound/drumbeat/shared_light (intended) |
| `starlit_aim` Starlit Aim | R S | Bridge | standing_stone, lanternmoth; discovered_by=event:crit_marked; Entwined | precision, affliction | No | called_shot, sharpened_light, bright_marks, guiding_light, full_moon | called_shot (Marked -> crit) | consuming Marked works against hunters_moon / Marked dmg bonus |
| `steady_aim` Steady Aim | C S | Support | — | precision | Partial | glinting_dew, full_moon, first_light, sharpened_light, patient_aim | sharpened_light (crit dmg) | dead without crit chance |
| `still_target` Still Target | U G | Bridge | any of: bloomcap, honeysuckle, frostfern, rootling, tangleroot, snugroot | precision, affliction | No | sharpened_light, root_web, patient_roots, heavy_eyelids, static_bloom | - | "frozen" = Held from a water Warden (code checks Drowsy or Held: consistent) |
| `thousand_cuts` Thousand Cuts | R G | Payoff / Support | hummingbird_bower | precision | Partial | sharp_beaks, flurry, needle_point, whirlwind_heart, momentum | - | global effect but gated on hummingbird_bower |
| `watchful_rest` Watchful Rest | U S | Support | **defining** | precision | Partial | patient_aim, first_light, edge_of_sight, long_shadows, solitude | first_light (opening burst) | - |

#### reach

| Card | R / pool | Role | Needs | Archetypes | Alone? | Key synergies | Overlaps | Issues |
|---|---|---|---|---|---|---|---|---|
| `close_guard` Close Guard | C S | Utility | — | reach | Yes | crowded_path, far_reach, longer_roots, edge_of_sight, solitude | longer_roots (range up) | flat stat |
| `crowd_breaker` Crowd Breaker | U S | Payoff / Support | **defining** | reach | Partial | wide_petals, far_reach, great_ripple, overlap, scatter | crowded_path (crowd damage) | needs area Wardens |
| `crowded_path` In the Thick | U S | Utility / Payoff | — | reach | Yes | crowd_breaker, close_guard, longer_roots, far_reach, rush | crowd_breaker (crowd damage) | tagged affliction but nothing status-related |
| `far_reach` Far Reach | U G | Utility / Support | — | reach | Partial | crowd_breaker, wide_petals, great_ripple, overlap, lingering_splash | wide_petals (splash wider) | splash part duplicates wide_petals |
| `great_ripple` Great Ripple | L G | Payoff / Support | — | reach | Partial | wide_petals, far_reach, crowd_breaker, ripples, overlap | lingering_splash (area follow-up) | - |
| `heavy_dew` Heavy Dew | C S | Support | dewdrop | reach, family:dewdrop | No | rain_on_glass, damp_rot, rolling_thunder, conductive_soil, wide_petals | - | - |
| `hush` Hush | C G | Support | bellflower | reach, family:bellflower | No | chorus, resonance, heavy_eyelids, wide_petals | - | - |
| `lantern_glow` Lantern Glow | C S | Utility | — | reach | Yes | longer_roots, long_shadows, far_reach, overlap | - | - |
| `lingering_splash` Lingering Splash | U G | Enabler / Payoff | **defining** | reach | Partial | lingering_ground, venom_bloom, wide_petals, great_ripple, seeping | great_ripple (area follow-up) | - |
| `long_shadows` Long Shadows | U G | Support | any of: standing_stone, lanternmoth | reach | No | lantern_glow, edge_of_sight, patient_aim, hunters_patience | close_guard (range by bracket) | needs a range-5 Warden |
| `longer_roots` Longer Roots | U S | Utility | — | reach | Yes | lantern_glow, edge_of_sight, crowded_path, winding_path | long_shadows (range up) | flat stat |
| `loose_stones` Loose Stones | U G | Support | cairn | reach, family:cairn | No | mountains_fall, small_hands, falling_weight, lingering_ground | - | - |
| `overlap` Overlap | U S | Payoff / Support | **defining** | reach | Partial | great_ripple, ripples, crowd_breaker, lingering_splash, far_reach | - | Needs 2+ overlapping area Wardens |
| `ripples` Ripples | C S | Support | — | reach | Yes | crowd_breaker, overlap, great_ripple, wide_petals, far_reach | - | - |
| `scatter` Scatter | C S | Support | — | reach | Yes | crowd_breaker, heavy_air, overlap, ripples, wide_petals | - | - |
| `spillover` Spillover | R G | Payoff | **defining** | reach | Partial | crowd_breaker, last_breath, wide_petals, far_reach, great_ripple | last_breath / shattering_blow (death splash) | weak vs bosses / lone tough targets |
| `wide_petals` Wide Petals | C S | Utility / Support | — | reach | Partial | far_reach, spillover, crowd_breaker, lingering_ground, ripples | far_reach (splash wider) | flat stat |
| `wide_swing` Wide Swing | C S | Support | — | reach | Partial | wide_petals, crowd_breaker, overlap, great_ripple, spillover | wide_petals (area radius) | weak / fiddly |

#### swift

| Card | R / pool | Role | Needs | Archetypes | Alone? | Key synergies | Overlaps | Issues |
|---|---|---|---|---|---|---|---|---|
| `drumbeat` Drumbeat | U S | Enabler / Payoff | **defining** | swift, overgrowth | Partial | rootbound, hummingheart, shared_light, close_quarters, many_hands | rootbound (touching cluster speed) | anti-synergy with solitude / heart_of_the_maze |
| `flurry` Flurry | U S | Utility | — | swift | Yes | glinting_dew, momentum, rhythm, sharp_beaks, thousand_cuts | - | - |
| `hummingheart` Hummingheart | R G | Bridge / Payoff | **defining** | swift | Partial | quickened_sap, drumbeat, momentum, rootbound, whirlwind_heart | - | - |
| `light_steps` Light Steps | C S | Utility | — | swift | Yes | hummingheart, whirlwind_heart, quick_step | - | short window |
| `momentum` Momentum | U S | Support / Payoff | **defining** | swift | Yes | rhythm, hummingheart, whirlwind_heart, thousand_cuts, lone_hunter | rhythm (same-target speed ramp) | Weak vs swarms; rhythm is a weaker copy |
| `nimble_twigs` Nimble Twigs | C S | Support | — | swift | Partial | flurry, sharp_beaks, hummingheart, momentum, rhythm | - | Code checks BASE attacks/sec only (speed buffs never qualify); text implies effective |
| `quick_draw` Quick Draw | C S | Support | — | swift, precision | Yes | first_light, edge_of_sight, restless_roots, watchful_rest, called_shot | - | Small on fast Wardens; strong with first_light |
| `quickened_sap` Quickened Sap | U S | Utility | — | swift | Yes | hummingheart, whirlwind_heart, momentum, flurry, nimble_twigs | deeper_calm (flat global stat) | flat stat; untagged |
| `quickening` Hunt's Rush | C G | Support | — | swift | Yes | thinning_the_herd, crowd_breaker, rush, hummingheart, last_breath | thinning_the_herd (kill-in-range ramp) | - |
| `restless_roots` Stirring Roots | U G | Enabler | **defining** | swift | Partial | patient_aim, watchful_rest, hummingheart, first_light, heavy_seed | - | Defining tag but just a conditional stat |
| `rhythm` Rhythm | C S | Support | — | swift | Yes | momentum, flurry, hummingheart, lone_hunter, thousand_cuts | momentum (same-target speed ramp) | Weaker momentum |
| `rush` Rush | C S | Support | — | swift | Partial | crowd_breaker, crowded_path, quickening, hummingheart | - | Mostly late / swarm drifts |
| `whirlwind_heart` Whirlwind Heart | L G | Payoff | — | swift | Partial | quickened_sap, hummingheart, rootbound, drumbeat, thousand_cuts | - | penalty stacks multiplicatively with venom_bloom |

#### overgrowth

| Card | R / pool | Role | Needs | Archetypes | Alone? | Key synergies | Overlaps | Issues |
|---|---|---|---|---|---|---|---|---|
| `bountiful` Bountiful | C S | Utility / Support | — | overgrowth | Partial | cheap_seeds, seedfall, seedling_gift, root_network, sprout_chorus | cheap_seeds (Sprout discount) | weak: ~20% Sprout discount |
| `canopy` Canopy | R G | Payoff | min_attackers=15 | overgrowth | Partial | cheap_seeds, seedfall, bountiful, seedling_gift, many_hands | many_hands (wide count damage) | counts plantings (sell/replant inflates); slow to pay |
| `cheap_seeds` Cheap Seeds | C S | Utility / Support | — | overgrowth | Partial | bountiful, seedfall, root_network, sprout_chorus, canopy | bountiful, seedfall (Sprout discounts) | flat stat; seedfall strictly broader |
| `fireflies_in_the_grass` Fireflies in the Grass | U S | Bridge / Support | firefly_jar | overgrowth, affliction, family:firefly_jar | No | mycelium, live_wire, static_field, root_network, eternal_static | mycelium (Sprout status sibling) | - |
| `homing_instinct` Homing Instinct | U S | Support | nestling | overgrowth, family:nestling | No | murmur, small_hands, momentum | - | family-narrow |
| `many_hands` Many Hands | U S | Payoff | min_attackers=15 | overgrowth | No | canopy, cheap_seeds, seedfall, root_network, bountiful | canopy (count dmg) | weak: 15 attackers = +7% |
| `menagerie` Menagerie | L G | Payoff / Bridge | — | overgrowth | Partial | odd_one_out, mixed_grove, grand_tour, lucid_dream, solitude | grand_tour (variety-count global dmg); mixed_grove (adjacent-family variant) | Fights monoculture; Sprouts count as a kind (cheap +8%) |
| `mixed_grove` Mixed Grove | U G | Bridge / Payoff | min_families=2 | overgrowth, maze | Partial | menagerie, odd_one_out, rootbound, drumbeat, shared_light | menagerie (variety dmg) | Tag "maze" doubtful (pure adjacency) |
| `mycelium` Mycelium | U S | Bridge | sporeling | overgrowth, affliction | No | root_network, sprout_chorus, seedfall, damp_rot, seeping | fireflies_in_the_grass (Sprout status mirror) | Positional; needs Sprout cluster beside Sporeling |
| `odd_one_out` Odd One Out | U S | Payoff / Bridge | — | overgrowth | Partial | menagerie, mixed_grove, solitude, lucid_dream, heart_of_the_maze | menagerie (variety reward) | Tag overgrowth odd (anti-spam card) |
| `root_network` Root Network | R S | Payoff | count_warden=sprout min_warden_count=4; **defining** | overgrowth | No | seedfall, sprout_chorus, seedling_gift, mycelium, undergrowth | sprout_chorus (Sprout cluster bonus) | Need 4 Sprouts; same shape as sprout_chorus |
| `rootbound` Rootbound | L G | Enabler / Payoff | — | overgrowth | Partial | drumbeat, shared_light, weathered_walls, twig_walls, mixed_grove | drumbeat (adjacency speed) | Thornwalls count as touching (board.touching): trivially triggered with cheap walls |
| `seedfall` Seedfall | C S | Enabler / Utility | — | overgrowth | Yes | root_network, sprout_chorus, seedling_gift, mycelium, undergrowth | cheap_seeds (cheaper Sprouts); bountiful (free Sprouts) | Strictly better than cheap_seeds |
| `seedling_gift` Seedling Gift | R G | Enabler | **defining** | overgrowth | Partial | nursery, root_network, sprout_chorus, seedfall, bountiful | bountiful (free Sprouts); cheap_seeds | Defining tag for a small economy perk |
| `shared_light` Shared Light | R G | Bridge / Support | — | overgrowth, maze | Partial | rootbound, drumbeat, kind_canopy, hedge_maze, the_old_ones | kindred_roots (touching-based dmg) | tags seed/acorn/support misleading: any touching Warden (incl. Thornwalls) counts |
| `small_hands` Small Hands | U S | Enabler / Support | **defining** | overgrowth | Partial | sharp_beaks, seed_storm, heavy_seed, murmur, homing_instinct | - | "defining" but value depends on owning send-out Wardens; overgrowth tag odd |
| `sprout_chorus` Thicket | U S | Payoff | count_warden=sprout min_warden_count=6; **defining** | overgrowth | No | root_network, undergrowth, seedfall, seedling_gift, cheap_seeds | root_network (Sprout cluster bonus) | Need 6 Sprouts; same layout as root_network |
| `undergrowth` Undergrowth | C S | Support | — | overgrowth | No | root_network, sprout_chorus, seedfall, cheap_seeds, seedling_gift | - | - |
| `warm_hearth` Warm Hearth | U S | Bridge / Utility | acorn | overgrowth | Partial | kind_canopy, grandfather_stump, root_network, seedfall, hedgerow_roots | - | two loosely related effects on one card |

#### tall

| Card | R / pool | Role | Needs | Archetypes | Alone? | Key synergies | Overlaps | Issues |
|---|---|---|---|---|---|---|---|---|
| `chosen_few` Chosen Few | R G | Payoff | min_rank_count=1 min_rank_owned=5; Bittersweet | tall | No | sunlit_rest, steady_roots, tender_care, specialist, deeper_rings | blood_is_thicker (bittersweet x2) | harsh on Sprout/wide boards |
| `deeper_rings` Deeper Rings | R G | Enabler | requires_tag=nurture min_rank_count=1 min_rank_owned=5; **defining** | tall | No | endless_rings, sunlit_rest, steady_roots, specialist, the_old_ones | - | code differs from text: only the Eldest (first Warden bought to VI) passes V, others stay at V (get_max_rank_for) |
| `elder_kin` Elder Kin | U S | Bridge | min_rank_count=1; **defining** | tall, kinship | No | extended_family, blood_is_thicker, sunlit_rest, specialist, kindred_roots | kindred_roots (neighbour rank share) | - |
| `endless_rings` Endless Rings | L G | Payoff / Enabler | — | tall | No | deeper_rings, sunlit_rest, steady_roots, first_among_equals, the_old_ones | elder_kin (rank share) | no deeper_rings Need in data; late Dew sink only |
| `evergreen` Evergreen | U S | Utility / Support | — | tall | Yes | steady_roots, tender_care, golden_harvest, deep_well, harvest_moon | steady_roots (cheaper Nurture) | flat economy; tagged economy only |
| `few_and_mighty` Few and Mighty | R G | Payoff | max_attackers=12 | tall | Partial | the_last_light, monoculture, first_among_equals, deeper_rings, solitude | the_last_light (narrow count payoff) | code has no +80% cap (1 attacker = +88%); Need lets it show at exactly 12 attackers = +0% |
| `first_among_equals` First Among Equals | C S | Utility / Support | — | tall | Yes | tender_care, sunlit_rest, deeper_rings, endless_rings, specialist | - | flat stat; one Warden only |
| `growth_rings` Growth Rings | C S | Support | — | tall | Partial | tender_care, steady_roots, sunlit_rest, deeper_rings, specialist | - | flat stat, small |
| `kindred_roots` Kindred Roots | U S | Payoff | requires_tag=nurture min_rank_count=1 | tall | Partial | the_old_ones, tender_care, sunlit_rest, drumbeat, rootbound | - | - |
| `many_talents` Many Talents | U S | Payoff | **defining** | tall | Partial | tender_care, sunlit_rest, steady_roots, kindred_roots | - | anti-synergy with specialist |
| `monoculture` Monoculture | L G | Payoff | — | tall, narrow | No | few_and_mighty, the_last_light, specialist, chosen_few, first_among_equals | - | Any Sprout (line "sprout") breaks it; family picks push multi-line; anti-synergy with most family cards |
| `nursery` Cradle | R G | Payoff | tender_care, seedling_gift; Entwined | tall, overgrowth | No | seedling_gift, tender_care, root_network, sprout_chorus, seasoned | - | Needs two specific cards (tender_care + seedling_gift): very narrow |
| `seasoned` Seasoned | C S | Support | — | tall | Partial | tender_care, steady_roots, evergreen, sunlit_rest, deeper_rings | - | flat stat once ranked |
| `specialist` Specialist | U S | Payoff | **defining** | tall | Partial | tender_care, steady_roots, sunlit_rest, shared_training, deeper_rings | - | anti-synergy with many_talents (intended) |
| `steady_roots` Steady Roots | C S | Utility | — | tall | Yes | tender_care, specialist, sunlit_rest, deeper_rings, chosen_few | tender_care (Nurture discount) | flat economy stat |
| `sunlit_rest` Sunlit Rest | U S | Enabler / Utility | **defining** | tall | Yes | specialist, chosen_few, first_among_equals, the_old_ones, deeper_rings | tender_care (free ranks) | strong standalone; Heartwood-nearest rule dictates placement |
| `tender_care` Tender Care | C S | Utility / Support | — | tall | Yes | steady_roots, specialist, nursery, sunlit_rest, seasoned | steady_roots (Nurture cost) | - |
| `the_last_light` The Last Light | L G | Payoff | — | tall | Partial | solitude, few_and_mighty, chosen_few, monoculture, first_among_equals | few_and_mighty (few attackers) | tag "narrow" not an archetype; hard cliff at 6 attackers |
| `the_old_ones` The Old Ones | L G | Payoff / Bridge | — | tall | No | sunlit_rest, kindred_roots, elder_kin, endless_rings, shared_light | endless_rings (court rank share) | dead until a rank V Warden |

#### daring

| Card | R / pool | Role | Needs | Archetypes | Alone? | Key synergies | Overlaps | Issues |
|---|---|---|---|---|---|---|---|---|
| `bold_opening` Bold Opening | C S | Utility / Support | — | daring | Yes | call_of_the_wild, early_bird, head_start, restless_night, second_wind | call_of_the_wild (early-call pot) | small; 1 drift per block |
| `call_of_the_wild` Call of the Wild | C S | Utility / Support | — | daring | Yes | bold_opening, early_bird, head_start, quick_step, restless_night | early_bird, bold_opening | code differs from text: extra rule hurried_harvest (+1 Dew per dispel in an early-called drift, cap 40) not described |
| `close_shave` Close Shave | C S | Support | — | daring | Partial | thick_bark, desperate_bloom, hummingheart, stung, scarred_bark | stung (leak -> damage) | reactive; also fires when Thick Bark saves the leak |
| `deep_roots` Deep Roots | C S | Utility | — | daring | Yes | thick_bark, double_or_nothing, last_stand, deep_sleep, thin_bark | thick_bark (leaf safety) | anti-synergy with last_leaf / desperate_bloom; data only (no rule_id) |
| `desperate_bloom` Desperate Bloom | R G | Payoff | **defining** | daring | No | last_leaf, scarred_bark, thin_bark, stung, hummingheart | close_shave (leak -> speed) | anti-synergy with deep_roots / thick_bark |
| `double_or_nothing` Double or Nothing | R G | Utility | min_drift=10 | daring | Partial | deep_roots, thick_bark, last_stand, hunters_patience, golden_harvest | - | dead with deep_sleep (no Omens); tag "strange" only |
| `early_bird` Early Bird | C S | Utility | — | daring | Yes | call_of_the_wild, bold_opening, quick_step, head_start, restless_night | call_of_the_wild (early-call Dew) | small flat economy |
| `fresh_growth` Fresh Growth | U S | Enabler / Payoff | **defining** | daring | Partial | evergreen, quick_step, head_start, seedling_gift, cheap_seeds | - | - |
| `head_start` Head Start | U S | Payoff | **defining** | daring | Partial | call_of_the_wild, quick_step, restless_night, fresh_growth, second_wind | - | - |
| `last_leaf` Last Leaf | L G | Payoff | — | daring | No | thin_bark, scarred_bark, desperate_bloom, stung, deep_roots | scarred_bark (leaf-loss dmg) | - |
| `quick_step` Quick Step | C S | Payoff | — | daring, swift | Partial | call_of_the_wild, head_start, restless_night, second_wind, hummingheart | - | - |
| `restless_night` Impatient Night | L G | Payoff | — | daring | No | quick_step, head_start, call_of_the_wild, second_wind, bold_opening | - | Legendary for +40% capped: weak for rarity |
| `scarred_bark` Scarred Bark | U G | Payoff | **defining** | daring | No | last_leaf, deep_roots, stung, desperate_bloom, close_shave | last_leaf (leaves-lost dmg); stung | Anti-synergy with thick_bark |
| `second_wind` Second Wind | R G | Payoff | — | daring | No | quick_step, call_of_the_wild, restless_night, head_start, early_bird | - | Meta payoff (cards); risky |
| `stung` Stung | C S | Utility | — | daring | Partial | scarred_bark, desperate_bloom, thin_bark, last_leaf, early_bird | scarred_bark (leaf-loss dmg) | reactive; only helps after leaking |
| `thin_bark` Thin Bark | R G | Utility / Payoff | Bittersweet | daring | Yes | stung, scarred_bark, desperate_bloom, last_leaf, deep_roots | - | very strong flat stat (bittersweet) |
| `wild_dew` Wild Dew | C G | Utility | — | daring | Yes | double_or_nothing, moonflip, morning_dew | moonflip (random swing) | EV only ~x1.1; tag "strange" |

#### tending

| Card | R / pool | Role | Needs | Archetypes | Alone? | Key synergies | Overlaps | Issues |
|---|---|---|---|---|---|---|---|---|
| `burn_back` Burn Back the Dead Wood | R G | Enabler | min_obstacles=8; Bittersweet | tending | Yes | tended_forest, tended_stumps, wildwood_reclaimed, mulch, reclaimed_earth | - | cost: +20% nightmare speed for run; hurts forest_floor, no Seeds |
| `deep_well` Deep Well | R G | Utility | — | tending | Yes | harvest_moon, dew_bowl, morning_dew, golden_harvest, overflowing_well | harvest_moon (rest Dew) | rewards hoarding over spending |
| `dew_bowl` Dew Bowl | C G | Utility | — | tending | Yes | deep_well, golden_harvest, evergreen, morning_dew, harvest_moon | morning_dew (Dew now) | one-shot; weak late |
| `dew_trail` Dew Trail | U G | Support / Bridge | dewcatcher | tending, family:dewcatcher | No | heavy_dew, golden_harvest, overflowing_well, the_quiet_ones, deep_well | - | needs a Damp source to pay |
| `forest_floor` Forest Floor | C S | Support | — | tending | Partial | tended_stumps, hollow_ground, mulch, wildwood_reclaimed, heartwoods_reach | tended_stumps (touch-obstacle dmg) | anti-synergy with clearing cards (clears remove obstacles) |
| `golden_harvest` Golden Harvest | L G | Payoff / Bridge | — | tending | Yes | harvest_moon, deep_well, morning_dew, call_of_the_wild, overflowing_well | - | slow ramp (+2%/500 Dew), cap 30% |
| `groundskeeper` Groundskeeper | C S | Utility | — | tending | Partial | heartwoods_reach, reclaimed_earth, weed_puller, tended_forest, golden_harvest | weed_puller (clear refund) | small numbers |
| `harvest_moon` Harvest Moon | U G | Utility / Support | — | tending, family:acorn | Yes | deep_well, golden_harvest, dew_trail, overflowing_well, evergreen | morning_dew (Dew per rest) | Seed card: catcher bonus is its grows_text (not a bug) |
| `heartwoods_reach` Heartwood's Reach | C S | Enabler / Utility | min_obstacles=8 | tending | Yes | tended_forest, wildwood_reclaimed, groundskeeper, reclaimed_earth, hollow_ground | reclaimed_earth (cheaper clearing) | - |
| `hollow_ground` Hollow Ground | U G | Enabler / Bridge | min_obstacles=8; **defining** | tending | No | heartwoods_reach, mulch, reclaimed_earth, long_shadows, close_guard | - | only Mossy Boulder / Thorn-Sapling cells |
| `kind_canopy` Sheltering Boughs | U G | Payoff / Support | — | tending, family:acorn | Partial | hedgerow_roots, grandfather_stump, warm_hearth, shared_light, the_quiet_ones | - | - |
| `morning_dew` Morning Dew | C S | Utility | — | tending | Yes | call_of_the_wild, harvest_moon, deep_well, golden_harvest, evergreen | harvest_moon (+Dew each rest) | flat economy; tending tag loose |
| `mulch` Mulch | C S | Payoff | — | tending | Partial | heartwoods_reach, reclaimed_earth, wildwood_reclaimed, hollow_ground, tended_stumps | wildwood_reclaimed (cleared-cell dmg); reclaimed_earth (Fresh Soil part) | Overlaps L/C cleared-cell cards; needs clearing unlocked |
| `overflowing_well` Overflowing Well | R G | Payoff | wellspring | tending, family:acorn | No | deep_well, golden_harvest, harvest_moon, morning_dew, dew_bowl | - | Needs Wellspring past cap; very narrow, one payoff |
| `reclaimed_earth` Reclaimed Earth | C G | Utility / Enabler | min_obstacles=8 | tending | Partial | heartwoods_reach, mulch, wildwood_reclaimed, tended_forest, groundskeeper | mulch / wildwood_reclaimed (cleared-cell dmg); weed_puller (clear refund) | Three effects in one Common; crowded |
| `sap_rising` Sap Rising | U S | Enabler | **defining** | tending | Partial | the_quiet_ones, hedgerow_roots, kind_canopy, grandfather_stump, shared_light | - | Code excludes walls ("walls aside"); text doesn't say |
| `tended_forest` Tended Forest | C G | Payoff | min_obstacles=8 | tending | Partial | groundskeeper, weed_puller, reclaimed_earth, wildwood_reclaimed, heartwoods_reach | wildwood_reclaimed (clears -> dmg) | maze tag questionable; min_obstacles 8 |
| `tended_stumps` Tended Stumps | U G | Enabler / Payoff | min_obstacles=8; **defining** | tending, maze | Partial | mulch, hollow_ground, forest_floor, reclaimed_earth, wildwood_reclaimed | mulch / hollow_ground (cleared-cell) | - |
| `the_quiet_ones` The Quiet Ones | L G | Payoff | min_non_attackers=3 | tending | No | grandfather_stump, kind_canopy, many_threads, dew_trail, hedgerow_roots | - | Need (3 non-attackers) met by Thornwalls, which gain ~nothing from it |
| `thorn_snare` Briar Trap | U G | Support | — | tending, maze | Partial | root_web, still_target, patient_roots, tangled_release, deep_grip | - | tiny (0.5 s once/drift per wall) |
| `weed_puller` Weed Puller | C S | Utility | — | tending | Yes | groundskeeper, reclaimed_earth, tended_forest, hollow_ground, mulch | reclaimed_earth (clear refund) | small; boulders only |
| `wildwood_reclaimed` Wildwood Reclaimed | L G | Payoff | — | tending | No | mulch, hollow_ground, tended_stumps, reclaimed_earth, tended_forest | mulch (cleared-cell dmg) | Legendary close to mulch + tended_forest combined |

#### kinship

| Card | R / pool | Role | Needs | Archetypes | Alone? | Key synergies | Overlaps | Issues |
|---|---|---|---|---|---|---|---|---|
| `blood_is_thicker` Blood Is Thicker | R S | Payoff | min_kinships=1 discovered_by=kinship:any; Bittersweet | kinship | No | extended_family, close_kin, old_friends, grove_of_kin, elder_kin | chosen_few (bittersweet x2/half) | punishes Sprouts/odd Wardens (only attackers penalised) |
| `close_kin` Close Kin | C S | Support | discovered_by=kinship:any | kinship | No | extended_family, blood_is_thicker, grove_of_kin, close_quarters, twin_strike | - | code has a close_kin II (reach 4) but no II card exists |
| `close_quarters` Close Quarters | C S | Support | — | kinship, swift | No | drumbeat, rootbound, blood_is_thicker, twin_strike, elder_kin | - | hidden Need: kinship_possible |
| `extended_family` Extended Family | R S | Enabler | min_kinships=1 discovered_by=kinship:any; **defining** | kinship | No | blood_is_thicker, grove_of_kin, elder_kin, close_kin, sweet_harmony | - | - |
| `grove_of_kin` Grove of Kin | L S | Payoff | min_kinships=2 discovered_by=kinship:any | kinship | No | extended_family, close_kin, old_friends, elder_kin, blood_is_thicker | - | needs 2 Kinships; Legendary in start pool |
| `kin_and_kindling` Kin and Kindling | R S | Bridge | requires_tag=reaction min_kinships=1 discovered_by=kinship:any; Entwined | kinship, affliction | No | sweet_harmony, spore_kin, quick_reactions, seeping, extended_family | spore_kin (harmony statuses) | has a cost line but no bittersweet tag |
| `old_friends` Old Friends | C S | Support | discovered_by=kinship:any | kinship | No | blood_is_thicker, grove_of_kin, sweet_harmony, elder_kin, twin_strike | rooted_bond (keeps bond stage) | Needs a Kinship first (discovery gate) |
| `rooted_bond` Rooted Bond | U S | Support | min_kinships=1 discovered_by=kinship:any | kinship | No | old_friends, extended_family, blood_is_thicker, grove_of_kin | old_friends (bond stage) | Tag "maze" odd; niche rest-only swap |
| `shared_training` Shared Training | R S | Payoff | discovered_by=kinship:any, event:signature; **defining** | kinship, tall | No | specialist, elder_kin, old_friends, extended_family, close_kin | - | needs kin + matching rank choices: narrow, dead early |
| `spore_kin` Spore Kin | U S | Bridge | sporeling | kinship, affliction | No | sweet_harmony, kin_and_kindling, damp_rot, sparking_spores, old_friends | kin_and_kindling (harmony applies statuses) | needs a Sporeling-branch Kinship |
| `sweet_harmony` Sweet Harmony | U S | Payoff | min_kinships=1 discovered_by=kinship:any; **defining** | kinship | No | spore_kin, kin_and_kindling, old_friends, extended_family, grove_of_kin | - | Need 1 Kinship |
| `twin_strike` Twin Strike | C S | Support | — | kinship | No | close_quarters, sweet_harmony, extended_family, old_friends, blood_is_thicker | - | - |

#### family-specific

| Card | R / pool | Role | Needs | Archetypes | Alone? | Key synergies | Overlaps | Issues |
|---|---|---|---|---|---|---|---|---|
| `chorus` Chorus | R S | Payoff | bellflower; count_line=song min_warden_count=2 | family:bellflower | No | hush, heavy_eyelids, resonance, drumbeat, crowd_breaker | - | needs 2 song Wardens within 3 cells |
| `deep_grip` Deep Grip | C S | Payoff | rootling | family:rootling | No | root_web, patient_roots, tangled_release, first_frost, rooted_nightmares | falling_weight (line vs Held) | narrow family-only |
| `falling_weight` Falling Weight | U S | Payoff | pebbling | family:pebbling | No | root_web, patient_roots, bad_dreams, first_frost, rooted_nightmares | deep_grip (line vs Held) | narrow family-only |
| `glimmering_hunt` Glimmering Hunt | U S | Utility | — | family:dreamlight | Yes | hunters_patience, sudden_insight, overflowing_well | - | capped 3 Dreamlight/run; random |
| `grandfather_stump` Grandfather Stump | U G | Support | grove_heart | family:acorn | No | hedgerow_roots, kind_canopy, warm_hearth, rootbound, shared_light | - | code differs from text: buffs Elder Stump, text + requires say Grove Heart |
| `heavy_seed` Heavy Seed | U G | Support | samara | family:samara | No | backspin, ricochet, longer_flight, seed_storm, small_hands | - | family-narrow |
| `long_light` Long Light | U S | Support | rootlight | family:rootlight | No | lingering_ground, deep_grip, patient_roots | lingering_ground (ground linger) | - |
| `lucid_dream` Borrowed Branch | R S | Enabler | — | family:dreams | Yes | mixed_grove, menagerie, odd_one_out | - | - |
| `lucid_dreaming` Lucid Dreaming | L G | Utility | — | family:dreams | Yes | wandering_mind, second_wind, restless_dreams | - | removes Commons (some builds need them) |
| `murmur` Murmur | R S | Payoff | nestling | family:nestling | No | small_hands, homing_instinct, thousand_cuts, sharp_beaks, momentum | twin_strike (recent co-hit dmg) | One family; needs 2+ birds |
| `needle_point` Needle Point | U G | Support | hummingbird_bower | family:hummingbird | No | sharp_beaks, thousand_cuts, pollen_beaks, charged_feathers, flurry | - | Only vs shelled nightmares; niche counter |
| `patient_roots` Patient Roots | U G | Support | — | family:rootling | Partial | root_web, deep_grip, tangled_release, rooted_nightmares, thorn_snare | - | Seed card: Rootling pull/Held part is its grows_text (not a bug) |
| `ricochet` Ricochet | U G | Support | samara | family:samara | No | heavy_seed, backspin, seed_storm, longer_flight, windborne_rain | - | - |
| `root_web` Root Web | R S | Support | rootling | family:rootling | No | patient_roots, deep_grip, rooted_nightmares, tangled_release, falling_weight | - | - |
| `seed_storm` Seed Storm | R G | Payoff | samara | family:samara | No | heavy_seed, small_hands, ricochet, windborne_rain, longer_flight | - | - |
| `sharp_beaks` Sharp Beaks | C G | Support | any of: hummingbird_bower, wrens_nest | family:wing | Partial | thousand_cuts, needle_point, pollen_beaks, charged_feathers, small_hands | - | Common gated on Grove Wardens; +2 hits is a large swing on Hummingbird |
| `shiny_things` Shiny Things | U G | Support | magpie_perch | family:wing | No | kind_canopy, grandfather_stump, warm_hearth, hedgerow_roots, the_quiet_ones | - | single Warden; needs buffs nearby to steal |
| `spinning_corners` Spinning Corners | U S | Support | whirligig | family:wind, maze | No | hairpin_winds, cozy_corners, switchback, eddy, the_long_walk | switchback (bend speed) | narrow (one Warden line) |

#### none

| Card | R / pool | Role | Needs | Archetypes | Alone? | Key synergies | Overlaps | Issues |
|---|---|---|---|---|---|---|---|---|
| `deep_sleep` Deep Sleep | R G | Utility | Bittersweet | - | Yes | deeper_calm, harvest_moon, deep_well, golden_harvest, venom_bloom | thin_bark (bittersweet flat damage) | flat stat; cost kills double_or_nothing and Omen economy |
| `deeper_calm` Deeper Calm | U S | Utility | — | - | Yes | - | deep_sleep, thin_bark (flat damage) | flat stat; no tags |
| `dew_line` Dew Line | C S | Utility | — | - | Yes | morning_dew, call_of_the_wild, golden_harvest, wild_dew, deep_well | - | ~10% Dew; no tags |
| `moonflip` Moonflip | U G | Utility | — | - | Yes | - | deeper_calm (global dmg, weaker EV) | EV only ~+5%; no archetype; random not strategic |
| `mystery_dream` Mystery Dream | U G | Utility | — | - | Partial | - | - | Can roll an unneeded card; value = average U/R |
| `old_growth` Steadfast | R S | Utility / Payoff | — | - | Yes | evergreen, specialist, seasoned, sunlit_rest, rooted_bond | - | Untagged; punishes selling/repositioning |
| `restless_dreams` Waking Dreams | R G | Enabler | Bittersweet | - | Partial | wandering_mind, lucid_dream | - | Permanent offer penalty; clashes with lucid_dreaming |
| `sudden_insight` Sudden Insight | U S | Utility | — | - | Yes | glimmering_hunt, overflowing_well, lucid_dream | glimmering_hunt (Dreamlight gain) | one-shot; no archetype tag |
| `thick_bark` Hardened Bark | C S | Utility | — | - | Yes | deep_roots, last_leaf, double_or_nothing, early_bird | deep_roots (leaf safety) | no archetype tag |
| `wandering_mind` Wandering Mind | U G | Utility | — | - | Yes | lucid_dreaming, mystery_dream | - | no archetype tag |

---

## 3. Archetype and synergy map

**Statuses and their routes on a fresh profile** [Code + Data]:

| Status (player name) | Base source | Other sources |
|---|---|---|
| Spored (Poisoned) | Sporeling | Mycelium (Sprouts), Pollen Beaks (Hummingbird), Spore Kin |
| Charged (static) | Firefly Jar | Eternal Static (G, any Warden), Fireflies in the Grass (Sprouts), Charged Feathers, Resonance (Chime Stone) |
| Soaked (damp) | Dewdrop | Windborne Rain (Samara) |
| Drowsy | Bellflower | Static Bloom (Stormcap chains), Fever Dream |
| Marked (Exposed) | Lanternmoth (a Firefly Jar branch) | Hunter's Moon (L, every Warden's first hit), Guiding Light (spread) |
| Held (Rooted) | Frostfern (a Dewdrop branch), Rootling line (G) | Briar Trap (G, walls), First Frost (first nightmares each drift), Rooted Nightmares (L, G) |

### 3.1 Mechanic → the builds it feeds

Cards in *italics* are Grove-only.

- **Spored (damage over time)** has four routes, the best-branching mechanic in the game:
  - **Stack depth:** Bitter Sap (+1 stack to every status), Brimming (caps ×2), *Venom Bloom*,
    Lasting Dreams.
  - **Spread:** Passing Dream, Spore Cascade, Wildfire Spores.
  - **Reactions:**
    - Soaked Rot (`damp_rot`) and Mushroom Rain lead to Mushrooming.
    - Sparking Spores and Wildfire Spores lead to Ignite.
    - Smother needs Held.
  - **Bridges:**
    - to overgrowth: Mycelium (Sprouts touching a Sporeling poison);
    - to kinship: Spore Kin;
    - to multi-status: *Seeping* and *Nightshade*;
    - to ground effects: Lingering Ground.
- **Charged:**
  - Live Wire (bolts jump) and Static Field (bolts splash).
  - Reactions: Conductive Soil and Rain on Glass lead to Thunderclap; Ignite; Lightning Rod needs
    Marked.
  - Bridges: Fireflies in the Grass (Sprouts), Resonance (song), Static Bloom (sleep), *Charged
    Feathers* (Hummingbird).
  - Anti-synergy by design: Brimming halves bolts.
- **Soaked:**
  - Heavy Dew, Deep Water (Drown near the Heartwood).
  - Thunderclap, Mushrooming, Drown, Shatter.
  - *Dew Trail* (economy). *Windborne Rain* (Samara).
  - **Internal tension:** Rain on Glass dries Soaked and Conductive Soil uses it up, which fights
    Thunderclap and Soaked Rot. That's intended as a trade.
- **Drowsy and sleep:**
  - *Heavy Eyelids*, Slow Waking (`lullaby`), *Bad Dreams*, *Many Threads* (Dreamcatcher catching).
  - Heavy Air (every slow +40%).
  - *Still Target* (crits): a bridge to precision.
  - Falling Weight (Pebbling), Chorus and *Hush* (Bellflower), *Sweet Scent* (Honeysuckle walls).
- **Marked:** Bright Marks, Called Shot, Guiding Light, Starlit Aim (crit bridge; the crit uses up
  the Mark), Hunter's Moon (L), Lightning Rod.
- **Held:**
  - Deep Grip, Root Web, Tangled Release (Rootling, G family).
  - *Patient Roots*, Falling Weight, *Still Target*, *Deep Frost*.
  - First Frost, *Briar Trap*, *Rooted Nightmares*.
  - Shatter and Smother.
- **Crit:**
  - Sources: Glinting Dew (every 5th attack) and many Wardens' own `crit_chance` (Bellflower among
    the starting four; 56 Warden files have crit > 0).
  - Payoffs: *Sharpened Light*, Steady Aim, Hobble, *Still Target*, Starlit Aim, Called Shot,
    *Shattering Blow* (crits → area), *Full Moon*, *Patient Aim*, *Backspin*, *Deep Frost*.
- **Nurture (tall):**
  - Openers: Tender Care, Steady Roots, Sunlit Rest.
  - Per-rank: Seasoned, Growth Rings, First Among Equals.
  - Shape: Specialist vs Many Talents (deliberate opposites).
  - Bridges: Kindred Roots, Elder Kin, Shared Training (tall ↔ kinship).
  - Grove peaks: *Chosen Few*, *Deeper Rings*, *Endless Rings*, *The Old Ones*, *Monoculture*,
    *The Last Light*, *Few and Mighty*.
- **Wide (overgrowth):**
  - Sprout economy: Seedfall, Cheap Seeds, Bountiful.
  - Clusters: Undergrowth, Thicket, Root Network.
  - Counts: Many Hands, *Canopy*, *Menagerie*.
  - Variety: Odd One Out, *Mixed Grove*.
  - Adjacency: Drumbeat, *Shared Light*, *Rootbound*.
  - Bridges: Small Hands (summoners), Mycelium, Fireflies in the Grass.
- **Maze:**
  - Path length: Winding Path, Weary Feet, The Long Walk, *Bramble Oath*.
  - Path shape: Straightaway (straights) vs Cozy Corners and Switchback (bends); Narrow Way.
  - Walls: Hedge Maze, *Bitter Hedges*, Twig Walls, Thorny Walls, Weathered Walls, *Briar Crown*.
  - Position: Heart of the Maze, *Forest's Edge*, *Last Stand*, *Crossroads*.
- **Tending:**
  - Clearing: Heartwood's Reach, *Reclaimed Earth*, *Tended Forest*, Mulch, Weed Puller,
    Groundskeeper, *Hollow Ground*, *Tended Stumps*, *Burn Back*, *Wildwood Reclaimed*.
  - Keeping obstacles: Forest Floor, a deliberate pull against clearing.
  - Economy: Morning Dew, *Harvest Moon*, *Deep Well*, *Dew Bowl*, Dew Line, *Golden Harvest*.
  - Support Wardens: Sap Rising, *The Quiet Ones*, *Sheltering Boughs*, *Hedgerow Roots*,
    *Grandfather Stump* (broken, see section 6).
- **Daring:**
  - Calling early: Call of the Wild, Quick Step, Head Start, Early Bird, Bold Opening, *Restless
    Night*, *Second Wind*.
  - Leaves: Stung, Close Shave, *Scarred Bark*, *Desperate Bloom*, *Last Leaf*, *Thin Bark*.
  - Gambles: *Double or Nothing*, *Wild Dew*, *Moonflip*.
  - Timing: Fresh Growth.
- **Swift:**
  - Quickened Sap, Flurry, Light Steps, Nimble Twigs, Rhythm, Rush, Quick Draw.
  - Momentum, Drumbeat, *Stirring Roots* (`restless_roots`), *Quickening*.
  - Speed into damage: *Hummingheart* (bridge), *Whirlwind Heart* (L).
- **Reach:**
  - Range: Longer Roots, Close Guard, *Long Shadows*.
  - Area: Wide Petals, *Far Reach*, Ripples, Scatter, Wide Swing, Overlap, Crowd Breaker, *Lingering
    Splash*, *Spillover*, *Great Ripple*.
  - In the Thick (`crowded_path`), Lantern Glow.
- **Kinship:**
  - Close Kin, Old Friends, Rooted Bond, Twin Strike, Close Quarters, Sweet Harmony.
  - Elder Kin, Extended Family, Shared Training, Blood Is Thicker, Kin and Kindling, Spore Kin.
  - Grove of Kin (L).

### 3.2 What the map shows

**Supports with several payoffs (the good speculative picks):**
- **Bitter Sap:** every status, every Reaction.
- **Lasting Dreams:** statuses, Reactions, crowd control.
- **Brimming:** Spored up, Charged down; a real fork.
- **Passing Dream:** spread for any status.
- **Glinting Dew:** opens every crit payoff.
- **Last Breath:** kills feed area and effect damage.
- **Lingering Ground:** clouds, rings, rubble, lit tiles.
- **Small Hands:** birds, sprites, seeds, stones.
- **Weary Feet:** any long maze, and it multiplies everything.
- **Seasoned / Growth Rings:** any ranked board.
- **Twig Walls:** maze, plus wall-count cards and Thorny Walls.

**Supports with one payoff only (the narrow bets):**
- Grandfather Stump, *Overflowing Well*, *Needle Point* (shelled nightmares), *Shiny Things*.
- *Hairpin Winds*, *Homing Instinct*, *Heavy Seed*, *Longer Flight*, Spinning Corners, *Bad Dreams*.

**Enablers with too little support:**
- **Sap Rising** (tending support): its helpers are Grove-only (*The Quiet Ones*, *Sheltering
  Boughs*, *Hedgerow Roots*) or broken (Grandfather Stump).
- **Rooted Nightmares** (L, G): the only wall/path Held enabler, with few Held payoffs in the start
  pool.
- **Hunter's Moon** (L, S): its Marked payoffs all need Lanternmoth.

**Payoffs too hard to activate:**
- The **8 Woven / Crowned cards**: Deep Stillness, Endless Night, Eye of the Tempest, Falling Stars,
  Fever Pitch, Mountains Fall, Prism Heart, Ring of Rings. Each needs three named Wardens across
  families plus a Crowned discovery, and halves the Reaction's rate.
- **Nightshade:** 4 statuses on one nightmare.
- **Full Moon:** its overflow needs about 100% crit.
- **Monoculture:** any Sprout breaks it.
- **Dawnbreak:** needs a ×10 chain discovery.
- **Grove of Kin:** 2 Kinships.

**Mechanics with little interaction:**
- **Dew economy:** only *Golden Harvest* (G, L) and Deep Well's Seed turn Dew into power.
- **Leaves:** pay off only through the daring trio.
- **The rest timing:** only Sunlit Rest, Seedling Gift and Groundskeeper use it.

**Unexpected synergies already in the data [Inference from data and code]:**
- **Rootbound + Twig Walls / Weathered Walls:** Rootbound counts Thornwalls as "touching Wardens".
  1-Dew half-cell walls switch on a Legendary ×2 attack speed almost for free. Worth a balance look.
- **Shared Light + walls:** same pattern.
- **Deep Water + Last Stand + Forest's Edge:** a "kill zone at the Heartwood" build.
- **Sunlit Rest + First Among Equals:** the Warden nearest the Heartwood keeps ranking and is your
  top Warden.
- **Quick Draw + First Light:** two first-hit spikes.
- **Brimming + Sparking Spores:** Brimming makes Sparking Spores' 5-stack condition reachable.
- **Solitude + Heart of the Maze + Edge of Sight:** a lone sniper.

**Archetypes that lean on one card:**
- Tending-support on Sap Rising.
- Kinship on having a Kinship at all (structural: it needs both branches of a pair).
- Daring's leaf payoffs on three near-identical cards.

---

## 4. Speculative picks and pivots

The ~19 Dream offers in a full run [Code: rests after drifts 5…95; ~10 by drift 50] give a player
about 14–19 cards (the bot let ~13–26% of offers pass in recent sims). That's enough for one or two
builds plus utility, so a speculative pick costs a real slot.

Each archetype below lists:
- **Early bet:** what you can take early (start pool, Commons and Uncommons).
- **Now:** its immediate value.
- **Hope:** the enabler or payoff you're hoping for.
- **If it never comes:** the fail case.
- **Pivot:** where else the cards point.
- **Risk:** whether the gamble is interesting.

1. **Affliction (Spored / Charged / Soaked / Drowsy):**
   - **Early bet:** Bitter Sap, Lasting Dreams, Passing Dream.
   - **Now:** all three work with any status Warden.
   - **Hope:** Brimming (R), Seeping (U, G), Nightshade (L, G), the Reaction cards.
   - **If it never comes:** the supports still help any status board.
   - **Pivot:** to reach (Last Breath, Lingering Ground) or precision (Still Target).
   - **Risk:** the healthiest archetype. The risk is low but real (Reaction cards need the right
     second family, through half-dreamed picks).
2. **Maze:**
   - **Early bet:** Winding Path, Weary Feet, Switchback, Narrow Way, Weathered Walls.
   - **Now:** always (every map has a path).
   - **Hope:** Twig Walls (R), Heart of the Maze (R), The Long Walk (L), Thorny Walls.
   - **If it never comes:** still decent.
   - **Pivot:** to tending (walls into Sap Rising, Briar Trap) or reach.
   - **Risk:** **too safe.** Maze cards help every run, and it's still the most common build.
3. **Precision:**
   - **Early bet:** Glinting Dew, Head of the Line, Quick Draw, Edge of Sight (once range 4+).
   - **Now:** yes.
   - **Hope:** Solitude, Lone Hunter, Watchful Rest, Hunter's Moon (L), Called Shot or Starlit Aim
     (need Lanternmoth).
   - **If it never comes:** generic damage.
   - **Pivot:** to swift (Quick Draw), maze (Heart of the Maze).
   - **Risk:** good. The Marked half is a real "find Lanternmoth" bet.
4. **Reach:**
   - **Early bet:** Wide Petals, Close Guard, Ripples, Scatter, Lantern Glow.
   - **Now:** needs area Wardens (Dewdrop, Bellflower pulse; Sporeling clouds via branches).
   - **Hope:** Overlap and Crowd Breaker (U). **No start-pool Rare or Legendary;** Lingering Splash,
     Spillover and Great Ripple are Grove.
   - **Fail case:** common on a fresh profile.
   - **Pivot:** to affliction (Lingering Ground).
   - **Risk:** **the jackpot is missing on fresh profiles.**
5. **Swift:**
   - **Early bet:** Quickened Sap, Light Steps, Nimble Twigs, Rhythm, Rush, Flurry.
   - **Now:** yes.
   - **Hope:** Momentum and Drumbeat (U). **No start-pool Rare;** Hummingheart, Stirring Roots and
     Whirlwind Heart are Grove.
   - **Pivot:** to precision (Quick Draw), overgrowth (Drumbeat).
   - **Risk:** **flat:** swift is mostly stacking speed with no turn.
6. **Overgrowth:**
   - **Early bet:** Seedfall, Cheap Seeds, Bountiful, Undergrowth.
   - **Now:** yes (Sprouts are always available).
   - **Hope:** Root Network (R), Thicket, Small Hands, Rootbound / Menagerie (L, G).
   - **Pivot:** to affliction (Mycelium, Fireflies in the Grass), kinship (no).
   - **Risk:** good, but the three Sprout-cluster cards are near-duplicates, which makes the path
     linear.
7. **Tall (Nurture):**
   - **Early bet:** Tender Care, Steady Roots, Sunlit Rest. Seasoned and Growth Rings come later,
     gated on a rank.
   - **Hope:** Specialist / Many Talents (gated: a rank III Warden), Elder Kin, Shared Training.
     Chosen Few, Deeper Rings, The Old Ones and the Endless / Last Light Legendaries are all Grove.
   - **If it never comes:** ranks are still stats.
   - **Pivot:** to kinship (Elder Kin).
   - **Risk:** the **hard rank Needs stop you betting on Specialist before you've ranked.**
8. **Daring:**
   - **Early bet:** Call of the Wild, Quick Step, Early Bird, Bold Opening, Head Start, Fresh Growth.
   - **Now:** yes.
   - **Hope:** **no start-pool Rare or Legendary.** Scarred Bark, Desperate Bloom, Last Leaf,
     Restless Night, Second Wind and Thin Bark are all Grove.
   - **Pivot:** to swift (Quick Step).
   - **Risk:** missing on fresh profiles. Leaf-loss payoffs are three versions of the same card.
9. **Tending:**
   - **Early bet:** Heartwood's Reach (core), Morning Dew (core), Weed Puller, Groundskeeper, Mulch,
     Forest Floor, Thorny Walls.
   - **Now:** yes once clearing is open.
   - **Hope:** Sap Rising (U), then Grove: Tended Stumps, Hollow Ground, Wildwood Reclaimed, The
     Quiet Ones, Golden Harvest.
   - **Pivot:** to maze (walls).
   - **Risk:** the economy cards have **no payoff that turns Dew into power** in the start pool.
10. **Kinship:**
    - **Early bet:** Close Kin, Old Friends (Commons, but Close Kin needs a possible pair).
    - **Hope:** Sweet Harmony, Elder Kin, Extended Family, Blood Is Thicker, Grove of Kin.
    - **If it never comes:** if no Kinship pair appears, every Kinship card is dead.
    - **Pivot:** to tall (Elder Kin), affliction (Spore Kin, Kin and Kindling).
    - **Risk:** **genuinely risky**, as the user wants, and its pivots exist.

**Combo cards across families (half-dreamed):** the purest speculative bet in the game. You take
Soaked Rot or Rain on Glass dormant with one family, and it only wakes if the next family pick
offers the other family, which is random (3 of the unlocked families).
- [Code] `HALF_DREAMED_WITHIN` = 20 drifts; ×0.3 weight after you decline its family at a pick.
- [Rec] Keep it exactly as is. This is the model the user is describing.

---

## 5. Dream offer algorithm

**Confirmed behaviour** [Code, `scripts/run/dream_state.gd`]:

1. **Offer size:** 3 cards (`cards_per_offer`).
   - Lucid Dreaming: 4 cards, take 2, no Commons.
   - Thick Blight, Second Wind, Wider Dreams: up to 5 cards.
   - Waking Dreams: 2 cards afterwards.
2. **Rarity weights** by act: `[65,28,7,0]`, `[50,32,15,3]`, `[38,34,22,6]`.
   - A boss rest counts as the next act; all its slots are Rare+.
   - Pity: 3 Dreams without a Rare+ force one (`pity_after`).
   - At most one Legendary from the draw; at most one Bittersweet per offer.
3. **Run pool** (`build_run_pool`, `_sample_family`), drawn once from the map seed:
   - **Core (always in):** Quickened Sap, Deeper Calm, Longer Roots, Deep Roots, Thick Bark,
     Evergreen, Morning Dew, their II cards, plus Heartwood's Reach on maps with enough obstacles.
   - **Everything else:** 60% per rarity (`run_pool_share`), with floors of 12 / 12 / 6 / 3.
   - **Family cards:** a seeded 60% of each held family's cards, never the whole family when it has
     5 or more.
   - **Discovery-gated cards:** wait until discovered.
4. **Per-offer caps:** at most 1 family card (one that names a Warden) and 1 plain stat card
   (Deeper Calm, Quickened Sap, Longer Roots, Bitter Sap, Glinting Dew).
5. **Weighting** (`_weighted_pick`):
   - `tag_weight` = **1.0**, so no build steering.
   - Unmet soft Needs ×0.4.
   - Clearing openers ×2 until clearing is unlocked.
   - Half-dreamed combo cards ×1, or ×0.3 after declining their family.
   - Passed-over fading: 0 in the very next offer, then 0.6^passes, floor 0.1.
6. **The Stray Dream:** from the drift-10 rest (never at boss rests), one slot draws with in-build
   cards ×0.25. "In build" means it shares any archetype tag of a card you took.
7. **Boss rest:** one guaranteed unowned **defining** card (rolled Rare+, so sometimes a
   Legendary); the other slots Rare+.
8. **Hard Needs** gate the draw (`can_offer`):
   - Warden `requires`, Grove ownership, rarity and act.
   - Deepened only after the base is owned.
   - Clearing cards only once clearing is open.
   - Bittersweet only with the Grove node (`allow_bittersweet`).
   - `board_can_use` (use-now Needs).
   - Discovery gates (30 start-pool cards).
   - The "grown Needs": a named Warden must have been built this run.
9. **Entwined:** **no guaranteed slot** (comment in `make_offer`; user-approved 2026-10-02). An
   Entwined card is drawn at normal odds once its ingredients are owned, and only if the run pool
   sampled it.

**Answers to the brief's questions:**
- **Do generic upgrades dominate specialised choices?** Partly.
  - [Code] The 7 core basics (and their IIs) are in every run's pool, and the plain-stat cap is one
    per offer.
  - [Inference] The bigger effect is the Stray slot. With steering off, it lowers in-build cards to
    ×0.25 in one slot out of three.
    - With an in-build share *f* of eligible cards, that slot shows an in-build card with
      probability 0.25f / (0.25f + 1 − f). At f = 0.5 that's 20% instead of 50%.
    - Expected in-build cards per offer drop from 1.5 to 1.2.
    - What fills the gap is mostly untagged cards: the 93 base cards with no archetype tag, i.e.
      plain stats, economy and family cards.
  - [Rec] Remove the Stray reversal, or make it ×1 (a normal slot). It was a counterweight to
    `tag_weight` 1.6, which is gone.
- **Are enablers too common or too rare?**
  - [Data] The start pool has 28 defining cards out of 150 (1 Common, 21 Uncommon, 6 Rare).
  - [Inference] After the 60% sample, about 17 per run, so roughly every other normal offer shows
    one, plus one guaranteed at each boss rest. That's about right. The issue is *which*: on fresh
    profiles, the boss slot's Rare+ defining cards are only Brimming, Heart of the Maze, Root
    Network, Twig Walls, Extended Family and Shared Training (both gated), plus 4 Legendaries.
    Expect repeats there.
- **Do prerequisites prevent interesting speculative picks?** Yes, in three places:
  - `board_can_use` (Specialist, Many Talents, Small Hands, Lingering Ground, Sap Rising, Seasoned,
    Edge of Sight, Wide Swing, Scatter, Growth Rings, First Among Equals);
  - the 30 discovery gates;
  - the 18 start-pool cards that need Grove-only families.

  The first is the one that hurts speculation. The second is fine (discovery is part of the meta).
  The third is a labelling problem: those cards are effectively Grove cards.
- **Does family weighting create bias?** No weighting exists. The 1-family-card cap and the 60%
  family sample make family cards about 0.16–0.44 per offer (Balancing Code, 2026-10-05). A
  family's cards are *less* reliable than generic ones, which supports adapting.
- **Do Entwined guarantees make builds predictable?** They're not guaranteed any more, and the run
  pool can sample them out.
  - [Rec] Keep it. The brief says Entwined *may* stay guaranteed as deliberate synergy rewards.
    That's the user's call, but the 2026-10-02 decision ("combo cards are choices, not musts") went
    the other way.
  - Fix the stale comment in `upgrade_data.gd` and the line in `CLAUDE.md` either way.
- **Do Deepened cards compete well with new options?**
  - [Code] IIs are in the same draw at their own rarity, only after the base.
  - [Inference] The core basics' IIs are always in the pool, so Deeper Calm II, Quickened Sap II and
    Longer Roots II turn up whenever the base was taken. With the plain-stat cap they rarely crowd
    out, but they're the most frequent "safe" pick.
- **Does the pool change through a run?** Yes:
  - rarity shifts by act;
  - families picked later add their sampled cards;
  - discoveries join;
  - board Needs open as you build;
  - Bittersweet from act 2 (Grove only).

  [Inference] The weakest phase is act 1 on a fresh profile: mostly Commons, no Rares to speculate
  toward, and many supports gated until the board uses them.

---

## 6. Cards to fix, merge or rework

"Verified" = I re-read the code. "Reported" = flagged by a classification pass and consistent with
the code I read, but not traced end to end. No card is recommended for **removal**: the redundancy
is better solved by giving near-twins different shapes, which keeps the catalogue's breadth and
avoids touching saves and Grove nodes.

### 6.1 Bugs and text mismatches (fix first)

| Card | Current effect (text) | Problem | Action | Loses | Touches |
|---|---|---|---|---|---|
| `grandfather_stump` Grandfather Stump (U, G) | "Grove Heart gives +4% per nearby Warden, up to +45%." Needs `grove_heart`. | **Verified:** `Tower.get_aura_extra()` (`tower.gd` ~1904) applies it only to `elder_stump`. Grove Heart already scales per Warden, so as worded the card does nothing. | Decide which Warden it's for. Either change the hook to Grove Heart, or change the text and Need to Elder Stump (simpler: the code was written for Elder Stump). | — | `tower.gd`, card `.tres`, `test_family_finals` |
| `few_and_mighty` Few and Mighty (R, G) | "+8% per attacker under 12 (up to +80%)" | **Verified:** no cap in `dream_effects._few_and_mighty` (1 attacker gives +88%). `max_attackers` = 12 lets it be offered at exactly 12 attackers for +0%. | Add the 0.80 cap; make the Need `max_attackers` 11. | — | `dream_effects.gd`, `.tres` |
| `monoculture` Monoculture (L, G) | "If all your attacking Wardens are one line, +100%." | **Verified:** `is_monoculture()` counts every attacking line, and Sprouts are line `sprout`. A single Sprout breaks it, so the Legendary is nearly dead. | Ignore the `sprout` line (and Thornwalls) in the check, or rewrite the text as "…one family besides Sprouts". | — | `dream_state.gd` `is_monoculture`, text |
| `deeper_rings` Deeper Rings (R, G) | "Wardens can be Nurtured to rank VII…" | **Verified by design:** only the Eldest passes V (`get_max_rank_for`; user decision "only one tower can have them"). The text promises it for every Warden. | Text: "One Warden (the Eldest) can be Nurtured to rank VII…". | — | `.tres` text |
| `first_frost` First Frost (C, S) | "The first nightmare of each {drift} is {held} for 2 s at the first Warden it meets." (Balancing set 5 nightmares, 1.5 s.) | **Reported, partly verified:** `tower.gd` ~177–192 counts per Warden (`_frost_left`) and skips bosses. The text says per drift and doesn't mention bosses; its numbers are older than Balancing's. | Make the text match the hook: "Each Warden holds the first N nightmares it meets each drift (not bosses)". Or change the hook to a drift-wide count. Agree with Balancing. | — | `tower.gd`, `.tres` |
| `old_growth` Old Growth (R, S) | "Wardens that have stood 5 drifts +20%; 15 drifts +40%." | **Verified:** it has **no tags at all**. It lost `defining` in the narrowing and never had an archetype, so it's invisible to build tracking and the sims' archetype counts. | Tag it `tall` (patience, standing still), or `maze` if you see it as "the maze doesn't change". | — | `.tres` tags |
| `call_of_the_wild` Call of the Wild (C, S) | "Calling a drift early gives double Dew (up to 40 per drift), and that drift holds 10% more Dew." | **Reported:** it also carries the extra rule `hurried_harvest` (`extra_rules`). Check that the text covers it. | Check the text, or remove the leftover rule. | — | `.tres` |
| `few_and_mighty`, `edge_of_sight`, `close_quarters`, `twin_strike`, `seasoned`, `mulch`, … | — | **Verified:** `board_can_use` Needs aren't shown in the card's Needs line (they live in code, not data). | Show use-now Needs on the card and in the Codex (Main / UI). | — | `DreamScreen`, `board_can_use` |
| Entwined docs | `upgrade_data.gd` comment and `CLAUDE.md`: "guaranteed in the next offer" | **Verified:** no guarantee since 2026-10-02. | Update both comments. | — | docs only |

Not bugs, though a pass flagged them:
- Bramble Oath, Harvest Moon and Patient Roots have extra effects; these are their **Seed
  `grows_text`**, not hidden code.
- "Exposes" is the player name of Marked.

### 6.2 Overlaps: give near-twins different shapes

| Cluster | Current effects | Problem | Recommendation | What's lost |
|---|---|---|---|---|
| Sprout discounts: `seedfall` (C) / `cheap_seeds` (C) / `bountiful` (C) | Seedfall: Sprouts start at 8 Dew, rise half as fast, +30% damage. Cheap Seeds: Sprouts −3 Dew. Bountiful: every 5th Sprout free. | Seedfall is strictly broader; the other two are smaller versions of it. | **Rework Cheap Seeds** into a speculative Seed card (§7.1, "Sprout Seeds"). **Keep Bountiful** (a rhythm, not a price). | Nothing a player would miss: Cheap Seeds is a dominated choice. |
| Sprout clusters: `sprout_chorus` Thicket (U) / `root_network` (R) / `undergrowth` (C) | Thicket: +8% speed per Sprout within 2 (up to +60%). Root Network: +6% damage per Sprout in the side-by-side network (up to +60%). Undergrowth: Sprouts touching 2+ Sprouts +0.5 range. | Three cards with the same placement ("pack Sprouts"), so the overgrowth path is linear. | Keep Root Network as the payoff. **Rework Thicket** to reward Sprouts in a *line along the path* ("a hedge of Sprouts": each Sprout beside 2+ path tiles that also touches another Sprout attacks faster). That's a maze ↔ overgrowth bridge. Keep Undergrowth as the small helper. | One duplicate. |
| Leaf loss: `stung` (C) / `scarred_bark` (U, G) / `last_leaf` (L, G) | Block / run / current leaves → damage. | Three versions of "leaves lost = damage". | Keep Last Leaf (L) and Stung (C, per block). **Rework Scarred Bark** to pay in something other than damage: "each leaf lost this run makes your Dew pots 2% bigger (up to +30%)". That's a daring ↔ economy bridge. | One duplicate damage card. |
| Bends: `cozy_corners` (U) / `switchback` (C) / `spinning_corners` (U) / `crossroads` (L, G) | +30% / +50% (II) damage near bends; +20% speed beside bends; Pinwheels +45% beside bends; Crossroads +40% touching two far-apart path tiles. | **Crossroads (L) is outclassed by Cozy Corners II (U).** | **Rework Crossroads** into a real Legendary shape: "A Warden touching two stretches of path at least 6 steps apart attacks both stretches: every attack also fires at a nightmare on the other stretch." It changes how you route the maze. | Its current +40%. |
| Cleared cells: `mulch` (C) / `reclaimed_earth` (C, G) / `tended_forest` (C, G) / `wildwood_reclaimed` (L, G) | +20% on cleared cells; a three-part economy card; +2% per clear (up to +40%); a Legendary +30% on cleared cells +2% per clear (up to +60%). | The Legendary is about two Commons added together. | **Rework Wildwood Reclaimed:** "Cleared cells become fertile: a Warden planted on one counts as touching every other Warden on a cleared cell" (for adjacency cards such as Rootbound, Drumbeat, Shared Light and Kinships). A tending ↔ overgrowth / kinship enabler. | A flat Legendary. |
| Spread on dispel: `spore_cascade` (R, S, needs Driftspore) / `passing_dream` (C) | Spored to the 2 nearest; every status to the nearest within 2 cells. | The Common nearly covers the Rare. | **Rework Spore Cascade:** "A dispelled nightmare's Spored stacks *double* onto the nearest nightmare (up to the cap)". Depth, not breadth. | — |
| Lone Warden: `solitude` (U) / `heart_of_the_maze` (R) | +45% when no attacker within 2; ×2 for the single loneliest attacker. | Similar shape at different scales, which is fine as a ladder. | **Keep both** (a ladder within one archetype), but give Heart of the Maze the `maze` tag only (it already has it) and make sure the sims treat it as maze. | — |
| Variety: `menagerie` (L, G) / `grand_tour` (R, G) / `odd_one_out` (U) / `mixed_grove` (U, G) | Kinds on the map / statuses owned / only one of its kind / touching other families. | Healthy: each counts something different. | Keep. | — |
| Near-twins kept on purpose | Rhythm (C) vs Momentum (U); Tender Care vs Steady Roots; Wide Petals vs Far Reach's splash; Weathered Walls vs Twig Walls | Small overlaps: Common helper vs Uncommon shape. | Keep. Optionally drop Far Reach's splash half so Wide Petals owns splash. | — |

### 6.3 Too narrow or too weak

| Card | Current effect | Problem | Recommendation |
|---|---|---|---|
| 8 Woven / Crowned cards (`deep_stillness`, `endless_night`, `eye_of_the_tempest`, `falling_stars`, `fever_pitch`, `mountains_fall`, `prism_heart`, `ring_of_rings`) | Each makes its Crowned Reaction bigger, but it fires half as often. | 3 named Wardens across families + a Crowned discovery + the 60% sample: an audience of near zero. | Keep them as deliberate jackpots, but **cut the Need to the Crowned discovery + any 2 of the 3 Wardens**. They stay rare and become possible. |
| `restless_night` Restless Night (L, G) | +8% per drift called early this block (up to +40%). | A Legendary below an Uncommon's budget. | Rework into a daring Legendary shape: "Calling a drift early also calls the *next* one: two drifts arrive together, and Wardens deal +60% while both are on the field." |
| `the_quiet_ones` The Quiet Ones (L, G) | Non-attacking Wardens 50% stronger; Need: 3 non-attackers. | Thornwalls alone meet the Need and gain nothing. | Need 3 non-attackers **other than walls**. |
| `full_moon` Full Moon (L, G) | +10% crit chance; crit chance above 100% becomes crit damage. | The overflow needs ~100% crit. | Overflow from 60%. |
| `thorn_snare` Briar Trap (U, G) | Each Thornwall holds the first nightmare beside it each drift for 0.5 s. | Tiny, and it's the only wall-made Held. | **Move to the start pool**, the cheapest fix for "Held behind a branch" (§1, finding 3). Raise to 1 s; the II gives 1.5 s. |
| `many_hands` Many Hands (U, S) | +1% per 2 attackers (up to +40%); soft Need 15 attackers. | ~+7% at its own Need. | +1% per attacker, up to +40%. |
| `moonflip` (U, G), `wild_dew` (C, G) | ±25% / −15% per block; Dew pot ×0.6–1.6. | Gamble cards with low expected value and no build. | Keep: they're the "strange" set, and taste cards are allowed. |
| `guiding_light` Guiding Light (R, S) | Marked spreads 1 cell; Entwined ingredients: Lanternmoth + **Cozy Corners**. | Cozy Corners has nothing to do with spreading Marked. | Make the second ingredient a Marked or crit card (Bright Marks or Called Shot). |
| `kin_and_kindling` Kin and Kindling (R, S) | Harmonies apply both statuses; cost: they deal no damage. | It has a cost line but no `bittersweet` tag; that's by design (a combo trade, §5). | Keep. Note it in the Codex as a trade, not Bittersweet. |
| 18 start-pool cards that name Grove-only families (§1, finding 2) | — | Listed as start pool but never offerable on a fresh profile. | No data change needed (they gate correctly). In the Codex and docs, count them as Grove content so "fresh pool size" is honest. |
| `rootbound` (L, G) / `shared_light` (R, G) | Adjacency counts Thornwalls (verified: `Board.touching` = every Warden in the 8 cells). | With Weathered Walls (1 Dew) and Twig Walls (half-cell walls), Rootbound's ×2 speed is almost free. | Decide: "walls count" is a cute maze bridge, so keep it but have Balancing measure it. If too strong, count walls at half (like Hedge Maze's twig rule). |

### 6.4 Offer-system changes (no card changes)

| Item | Current (verified) | Problem | Recommendation | Touches |
|---|---|---|---|---|
| Stray Dream | One slot from drift 10: in-build cards ×0.25 | With steering off, this pushes away from your speculation and toward untagged Utility. | **Turn the Stray reversal off** (in-build ×1.0 in that slot), or remove the Stray slot. | `_weighted_pick`, `make_offer` |
| Use-now Needs | `board_can_use` is a hard gate for 19 cards | Blocks speculative picks (Specialist before a rank III Warden, Small Hands before a summoner). | **Hard in act 1, soft (×0.4) from act 2.** That keeps the act 1 fix (measured dilution) but lets later offers tempt a speculative bet. A card taken early stays dormant-in-effect until the board uses it, which is its own risk. | `can_offer`, `soft_needs_met` |
| Seed cards | All 7 Seed cards are Grove-only | The best speculative pattern is unavailable to new players. | Move 2 Seed cards to the start pool (**Harvest Moon**, **Sheltering Boughs**), and add Seed versions of starting-family cards (§7.1). | `.tres` `in_start_pool`; Meta Game Discussion for the Grove nodes |
| Fresh-profile jackpots | Start-pool Rares: 0 for tall, daring, tending, swift, reach | No payoff to speculate toward. | Add one start-pool Rare or Legendary payoff for each of those five, from §7. Or move one Grove Rare each (Meta's call). | Grove nodes |

---

## 7. Proposed new Dreams (20)

**Design rules for this set:**
- Each card connects mechanics or opens a path; none is a bigger number for something that exists.
- No new statuses or currencies.
- Each card carries one archetype tag and a use-now Need where it would otherwise be dead.
- The numbers are starting points for Balancing Discussion.

**Complexity:**
- **Low:** a `DreamEffects` row or an existing stat hook.
- **Medium:** a new hook inside an existing system.
- **High:** new UI or a new rest-time choice.

None of the names exists in `resource/`, `scripts/` or `documentation/` (checked).

### 7.1 Seed cards for the start pool (speculative supports)

They use the existing Seed fields (`grows_with`, `grows_text`, already rendered by the Dream
screen). They're useful now and become a bridge if the named family turns up later. That is the
user's "take it early, hope the enabler comes" in its purest form, and it can fail (the family may
never be offered).

| # | Card | R | Now (always) | Grows (with the named Wardens) | Role · archetype | Synergies (existing) | Why it's new | Risk | Cx |
|---|---|---|---|---|---|---|---|---|---|
| 1 | **Rain Barrel** | C | +10 Dew at every rest | with the Dewdrop line: Dewdrop splashes leave the tile wet, and the next nightmare to cross it gains 1 Soaked | Support/Seed · tending → affliction | `heavy_dew`, `damp_rot`, `conductive_soil`, `deep_water`, `rain_on_glass` | The first card that makes Soaked on the path rather than on a hit, so the maze route feeds the Soaked Reactions | Soaked everywhere means more Thunderclap; cap one stack per tile per second | Medium |
| 2 | **Tinder Box** | C | Wardens deal 10% more damage to nightmares carrying any status | with Firefly Jar: Ignite needs 2 Poisoned instead of 3 | Support/Seed · affliction | `sparking_spores`, `wildfire_spores`, `bitter_sap`, `brimming` | Only Seed card for a Reaction threshold; useful alone with any status Warden | Ignite uptime; Balancing checks the 2-stack | Medium |
| 3 | **Sprout Seeds** (rework of `cheap_seeds`, §6.2) | C | Sprouts cost 3 Dew less | with Acorn, Elder Stump or Grove Heart: Sprouts inside an aura get it at double strength | Support/Seed · overgrowth → tending | `seedfall`, `bountiful`, `root_network`, `warm_hearth`, `sap_rising` | Turns a dominated discount into a bet on the support family | A Sprout carpet in a double aura; Balancing | Low |

### 7.2 Bridges (connect two mechanics)

| # | Card | R | Effect (starting numbers) | Needs | Role · archetypes | Synergies (existing) | Why it's not redundant | Balance risk | Cx |
|---|---|---|---|---|---|---|---|---|---|
| 4 | **Witch Thorns** | U | Each Thornwall Marks the first nightmare that passes beside it each second, for 2 s | own a Thornwall | Bridge · maze → precision / affliction | `bright_marks`, `called_shot`, `starlit_aim`, `hunters_moon`, `twig_walls`, `weathered_walls` | The only Marked source besides Lanternmoth and Hunter's Moon (L). It opens Lightning Rod and Pinned on fresh profiles | Wall-heavy mazes Mark everything; the per-wall 1 s cooldown is the brake | Medium (the wall-proximity check Briar Crown uses, `_briar_strike`) |
| 5 | **Busy Road** | U | Wardens attack 2% faster for every path tile in their range (up to +40%) | — | Bridge · maze → swift | `winding_path`, `the_long_walk`, `straightaway`, `weary_feet`, `nimble_twigs` | Straightaway is a fixed bonus beside straights, and Winding Path pays Dew. This rewards *coverage* | Long-range Wardens hit the cap fast; tune the cap | Low (`covered_path_tiles` exists) |
| 6 | **Saplings' Lesson** | U | Sprouts touching a Warden at rank III+ count as rank II | a rank III Warden | Bridge · tall → overgrowth | `seasoned`, `growth_rings`, `first_among_equals`, `root_network`, `undergrowth` | Elder Kin shares ranks between kin; this teaches Sprouts. The first tall + wide card | A Sprout ring around one tall Warden; low | Medium (`get_effective_rank`) |
| 7 | **Fever Pace** | U | A Warden attacks 5% faster for each status on its target (up to +25%) | a status Warden | Bridge · swift → affliction | `bitter_sap`, `lasting_dreams`, `brimming`, `momentum`, `rhythm` | Seeping scales effect *damage* per status; this scales *speed*, so it helps every Warden of a status board, including non-status ones | Low | Low–Medium |
| 8 | **Rich Rot** | C | A nightmare dispelled while carrying 2+ statuses pays 25% more of its Dew share | 2 status kinds owned | Bridge · affliction → tending (economy) | `bitter_sap`, `passing_dream`, `dew_line`, `morning_dew` | Dew Trail (G) is Soaked + caught only; this is any two statuses | Dew pot inflation is small (shares are fixed per drift) | Low |
| 9 | **Steeped** | U | Each Deep rank a Warden has makes its status hits add 1 more stack (up to +2) | a Warden with a Deep rank | Bridge · tall → affliction | `specialist`, `brimming`, `bitter_sap`, `lasting_dreams`, `seeping` | The Deep choice already lengthens statuses; this makes Deep a status-build choice. Bitter Sap is +1 for all | Stacks with Bitter Sap and Brimming; caps limit it | Low–Medium |
| 10 | **Hasty Clearing** | C | Clearing while a drift is on costs 40% less | clearing open | Bridge · daring → tending | `heartwoods_reach`, `mulch`, `weed_puller`, `call_of_the_wild`, `forest_floor` (anti) | Every other clearing discount is always-on; this rewards mid-drift action | Low (clearing is one-way, so no juggling) | Low |
| 11 | **Pathfinder's Toll** | U | Path tiles beside an obstacle count twice for cards that count path tiles (Winding Path, The Long Walk, Weary Feet, Busy Road) | an obstacle left | Bridge · maze → tending | `winding_path`, `the_long_walk`, `weary_feet`, `forest_floor`, `bramble_oath` | The first card that makes *keeping* obstacles part of maze value; a fork against clearing | Moderate: a multiplier for several cards; cap per card | Medium |
| 12 | **Shared Burden** | U | When a Warden in a Kinship crits, its kin's next attack is a crit | a Kinship possible | Bridge · kinship → precision | `glinting_dew`, `still_target`, `called_shot`, `sharpened_light`, `twin_strike` | No kin card touches crits | Two high-crit kin loop; one hand-off per crit limits it | Low–Medium |
| 13 | **Grounding Roots** | U | A Held nightmare gains 1 Charged every 0.5 s while Held | a Held source | Bridge · affliction (Held → Charged) | `first_frost`, `thorn_snare`, `root_web`, `live_wire`, `static_field` | No card turns Held into another status; it opens Starfall and Prismstorm without a third family | Low (Held is short) | Low |
| 14 | **Ward Stones** | C | Area attacks deal 20% more to nightmares within 1 cell of a Thornwall | a Thornwall and an area Warden | Bridge · maze → reach | `twig_walls`, `hedge_maze`, `narrow_way`, `wide_petals`, `ripples` | Bitter Hedges (G) amps *all* damage after passing walls; this is area-only, Common, start pool | Low | Low |

### 7.3 Enablers and payoffs (new strategies; fills the fresh-profile jackpot gap)

| # | Card | R | Effect (starting numbers) | Needs | Role · archetype | Synergies (existing) | Why it's not redundant | Balance risk | Cx |
|---|---|---|---|---|---|---|---|---|---|
| 15 | **Pollen Burst** | R | When an area attack hits a nightmare carrying a status, every other nightmare it hits gains 1 stack of that status | an area Warden and a status Warden | Enabler / Bridge · reach → affliction | `crowd_breaker`, `overlap`, `lingering_splash`, `bitter_sap`, `brimming` | Gust (a Warden) copies statuses and Passing Dream spreads on death; this is a *card* that turns any area Warden into a spreader. It's the start-pool Rare that reach lacks | Saturation means Reactions everywhere (Reaction cooldowns cap it) | Medium (`Tower.hit` area path) |
| 16 | **Gale Force** | R | Each +60% attack speed a Warden has beyond its base makes every attack pierce one more nightmare behind its target | — | Payoff · swift | `quickened_sap`, `light_steps`, `nimble_twigs`, `drumbeat`, `momentum` | Hummingheart (G) turns speed into damage; this turns it into *coverage*. It's swift's start-pool Rare | Piercing on fast area Wardens; exclude area attacks | Medium |
| 17 | **Rooted Lineage** | R | Growing a ranked Warden costs nothing extra for its ranks, and a Warden at rank III+ gains a free rank when it grows | a rank II Warden | Payoff / Bridge · tall → evolution | `tender_care`, `steady_roots`, `sunlit_rest`, `specialist`, `evergreen` | Evergreen discounts growing by 25%; this removes the rank surcharge (`get_grow_cost`). It's tall's start-pool Rare and the first card linking Nurture to branches | "Rank early, grow late" may dominate; free ranks capped at VII (`FREE_RANK_MAX`) | Medium |
| 18 | **Wager of Leaves** | R | At each rest you may stake 2 leaves: a perfect next block regrows them and gives 1 Dreamlight; otherwise they're lost | 4+ leaves | Enabler · daring | `last_leaf`, `stung`, `close_shave`, `desperate_bloom`, `call_of_the_wild` | Double or Nothing wagers Omen rewards. This wagers leaves, by choice, every block, and feeds the leaf-loss payoffs either way. It's daring's start-pool Rare | Dreamlight inflation (max 1 a block), which is tested by Balancing | High (rest-time toggle) |
| 19 | **Heavy Purse** | R | All Wardens deal 1% more damage for every 10 Dew you hold above 100 (up to +30%) | — | Payoff / Bridge · tending (economy → damage) | `morning_dew`, `harvest_moon`, `deep_well`, `dew_line`, `early_bird` | Golden Harvest (L, G) counts Dew *earned*; this rewards *holding*, a real tension with planting. It's tending's start-pool Rare | Late Dew pots are large; the cap may need to scale by act | Low |
| 20 | **Bridge of Boughs** | R | Two kin on opposite sides of the path bond at up to 4 cells, and their Harmony strike also hits every nightmare on the path tiles between them | a Kinship possible | Enabler · kinship → maze | `close_kin`, `sweet_harmony`, `kin_and_kindling`, `narrow_way`, `twig_walls` | Close Kin is reach 3 everywhere; this is a *placement shape* that makes the maze decide your kin | Line-of-tiles detection; the strike damage stays the existing Harmony number | High |

**Short Fuse** (daring → affliction: statuses from a drift you called early tick twice as fast but
last half as long) was considered and left out. It overlaps Head Start, and its value depends on
too many other cards.

---

## 8. Prioritised improvement plan

**Priority 1: fix what quietly reduces build diversity** (small, mostly data and constants)
1. Grandfather Stump: make the hook and text agree (§6.1).
2. Monoculture: ignore Sprouts and walls.
3. Few and Mighty: add the cap and fix the Need.
4. Deeper Rings, First Frost and Call of the Wild: make the texts match the code.
5. Tag Old Growth.
6. **Turn the Stray Dream's reversal off** (`_weighted_pick`: in-build ×1.0 in the Stray slot), or
   remove the slot. One line, and the biggest offer-side effect on speculation.
7. **Use-now Needs soft from act 2** (`can_offer` / `soft_needs_met`: `board_can_use` stays hard in
   act 1, ×0.4 after).
8. Show the use-now Needs on cards (Main / UI).
9. Update the Entwined comments (`upgrade_data.gd`, `CLAUDE.md`).

**Priority 2: rework near-twins into branching shapes** (data and small hooks)
1. Cheap Seeds → Sprout Seeds (a Seed card).
2. Thicket → hedge of Sprouts along the path.
3. Scarred Bark → leaves feed the Dew pot.
4. Crossroads → fire at both stretches.
5. Wildwood Reclaimed → fertile cleared cells count as touching.
6. Spore Cascade → depth.
7. Restless Night → paired drifts.
8. The Quiet Ones → walls excluded.
9. Full Moon → overflow from 60%.
10. Guiding Light's ingredient.
11. Many Hands' numbers.
12. The Woven cards' Needs → any 2 of 3 Wardens.
13. **Briar Trap and two Seed cards (Harvest Moon, Sheltering Boughs) to the start pool.** Meta Game
    Discussion rebalances their Grove nodes.

**Priority 3: a small set of new cards** (start with 8, not 20). In order of value per effort:
1. Witch Thorns
2. Busy Road
3. Rich Rot
4. Grounding Roots
5. Heavy Purse
6. Pollen Burst
7. Rooted Lineage
8. Tinder Box

Together these fill the fresh-profile jackpot gap for reach, tall and tending, add a Marked source
and a Held bridge, and give two Seed bets. Add the rest after playtests.

**Priority 4: testing and telemetry** (§9). Run history already records Dreams taken and passed.
Add:
- whether each taken card's **condition was ever met** (dormant / never used);
- for half-dreamed cards, whether they **woke**;
- the run's **archetype at drift 25 vs drift 75**, to measure pivots: the user's goal sentence, made
  measurable.

**Owners:**

| Who | What |
|---|---|
| Roguelite Code | card data and `dream_state.gd` |
| Tower Code | combat hooks: Witch Thorns, Pollen Burst, Gale Force, Grounding Roots, Fever Pace, Steeped, Shared Burden, Ward Stones, Grandfather Stump |
| Main | Needs display and run-history fields |
| Meta Game Discussion | Grove node changes |
| Balancing Discussion | numbers |

---

## 9. Balance risks and suggested tests

**Risks:**
- **Turning the Stray reversal off** raises in-build card frequency by about +25% (inference, §5).
  It could make the chase ceiling (≤ 30% of chased builds complete by drift 50, ≤ 50% by 75)
  tighter. Re-measure the chase.
- **Soft use-now Needs from act 2** bring back some dead slots. The act 1 fix stays, but measure act
  2 survival and pass rates.
- **Rootbound and Shared Light with cheap walls** may already be too strong (walls count as touching).
- **Status saturation** (Pollen Burst + Bitter Sap + Brimming + Witch Thorns) could make Reactions
  constant. The Reaction cooldowns are the brake, and Quick Reactions halves them, so watch that pair.
- **Dreamlight from Wager of Leaves** and **Dew holding from Heavy Purse** touch the economy;
  Balancing should check them against the Dew pot and Dreamlight budgets.
- **Rooted Lineage** could make "rank everything early" the default Nurture plan.

**Suggested tests.** Sims are paused by the user as of 2026-10-08, so these are for when they
resume, and only on request:
1. **Speculation outcome:** for each archetype, the bot takes its first support card by drift 15.
   Then measure:
   - the share of runs that see a matching Rare+ payoff by drift 50 (fresh vs half Grove);
   - the share that pivot to another archetype;
   - survival in each case.

   Target: "found it" is common but not certain (roughly 30–60%), and pivots aren't fatal.
2. **Stray off vs on:** in-build cards per offer, chase ceiling, no-build share at 50.
3. **Use-now soft from act 2:** act 1 survival unchanged, act 2 pass rate, how often a speculative
   use-now card later activates.
4. **Wall adjacency:** Rootbound with and without Weathered Walls / Twig Walls.
5. **Unit tests** (headless, existing patterns):
   - Grandfather Stump on its intended Warden;
   - Monoculture with a Sprout on the map;
   - Few and Mighty at 1 and 12 attackers;
   - First Frost's count and boss rule;
   - the Stray slot's weights;
   - `board_can_use` soft from act 2;
   - Seed cards' `grows_text` switching on.

**What this audit did not do:** it ran no game, test or sim, and it didn't trace every one of the
244 rule hooks end to end. All 244 rule ids appear as string literals in `scripts/` (checked), and
the mismatches in §6.1 are the ones found and re-read.
